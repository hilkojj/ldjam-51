
#include <generated/Children.hpp>
#include <generated/PlayerControlled.hpp>
#include "PortalSystem.h"
#include "PhysicsSystem.h"

#include "../../generated/Physics.hpp"
#include "../../generated/Portal.hpp"
#include "../../game/Game.h"

#include <generated/LuaScripted.hpp>

void PortalSystem::init(EntityEngine *engine)
{
    EntitySystem::init(engine);
    room = dynamic_cast<Room3D *>(engine);
    if (!room) throw gu_err("engine is not a room");
}

void PortalSystem::update(double deltaTime, EntityEngine *)
{
    bool playerTeleported = false;
    entt::entity playerE = entt::null;

    room->entities.view<Transform, GhostBody, Portal>().each([&](auto portalAE, const Transform &transformPortalA, const GhostBody &body, Portal &portalA) {

        portalA.playerTouching = false;
        portalA.time += deltaTime;

        if (body.collider.collisions.empty())
        {
            return;
        }

        entt::entity portalBE = room->getByName(portalA.linkedPortalName.c_str());

        if (!room->entities.valid(portalBE))
        {
            return;
        }
        if (!room->entities.has<Transform>(portalBE) || !room->entities.has<Portal>(portalBE))
        {
            return;
        }

        const Transform &transformPortalB = room->entities.get<Transform>(portalBE);
        const Portal &portalB = room->entities.get<Portal>(portalBE);

        const vec4 planePortalA = getPortalPlane(transformPortalA);

        for (auto &[victim, collision] : body.collider.collisions)
        {
            if (!room->entities.valid(victim))
            {
                continue;
            }
            Transform *transformVictim = room->entities.try_get<Transform>(victim);
            if (transformVictim == nullptr)
            {
                continue;
            }
            RigidBody *rigidBodyVictim = room->entities.try_get<RigidBody>(victim);
            if (rigidBodyVictim == nullptr)
            {
                continue;
            }

            float planeDot = dot(vec4(transformVictim->position, 1.0f), planePortalA);

            if (planePortalA.y < 0.5f)
            {
                if (transformVictim->position.y - transformPortalA.position.y < -0.9f)
                {
                    // prevent fall through floor when going through portal
                    continue;
                }
            }

            bool anyContactPointInFront = false;
            for (vec3 &contactPoint : collision->contactPoints)
            {
                if (dot(vec4(contactPoint, 1.0f), planePortalA) < 0.0f)
                {
                    anyContactPointInFront = true;
                }
            }
            if (!anyContactPointInFront)
            {
                continue;
            }

            TouchingPortal &tp = room->entities.get_or_assign<TouchingPortal>(victim);
            tp.timeSinceTouch = 0.0f;
            if (dot(vec3(planePortalA), mu::Y) > 0.5f)
            {
                rigidBodyVictim->collider.collideWithMaskBits &= ~portalA.letBodyIgnoreMaskWhenOnFloor;
                tp.ignoredMask |= portalA.letBodyIgnoreMaskWhenOnFloor;
            }
            else
            {
                rigidBodyVictim->collider.collideWithMaskBits &= ~portalA.letBodyIgnoreMaskWhenOnWall;
                tp.ignoredMask |= portalA.letBodyIgnoreMaskWhenOnWall;
            }
            rigidBodyVictim->collider.bedirt<&Collider::collideWithMaskBits>();

            if (room->entities.has<LocalPlayer>(victim))
            {
                portalA.playerTouching = true;
            }

            if (planeDot > 0.0f)
            {
                TeleportedByPortal *alreadyTeleported = room->entities.try_get<TeleportedByPortal>(victim);
                if (alreadyTeleported != nullptr && alreadyTeleported->timeSinceTeleport < collision->duration)
                {
                    // this collision already caused a teleport.
                    continue;
                }

                mat4 transformVictimMat = Room3D::transformFromComponent(*transformVictim);
                Room3D::decomposeMtx(teleportThroughPortals(
                    Room3D::transformFromComponent(transformPortalA),
                    Room3D::transformFromComponent(transformPortalB),
                    transformVictimMat
                ), transformVictim->position, transformVictim->rotation, transformVictim->scale);
                std::cout << "Teleporting " << (room->getName(victim) ? room->getName(victim) : std::to_string(int(victim))) << " from " << (room->getName(portalAE) ? room->getName(portalAE) : std::to_string(int(portalAE))) << " to " << (room->getName(portalBE) ? room->getName(portalBE) : std::to_string(int(portalBE))) << std::endl;
                room->entities.assign_or_replace<TeleportedByPortal>(victim).timeSinceTeleport = 0.0f;

                room->getPhysics().setLinearVelocity(
                    *rigidBodyVictim,
                    transformDirectionByTeleport(
                        Room3D::transformFromComponent(transformPortalA),
                        Room3D::transformFromComponent(transformPortalB),
                        room->getPhysics().getLinearVelocity(*rigidBodyVictim)
                    )
                    + vec3(getPortalPlane(transformPortalB)) * -3.0f
                );

                if (room->entities.has<LocalPlayer>(victim))
                {
                    playerTeleported = true;
                    playerE = victim;
                }
                //room->emitEntityEvent(victim, portalA, "TeleportedByPortal");
            }
        }
    });

    room->entities.view<TeleportedByPortal>().each([&](TeleportedByPortal &teleportedByPortal) {
        teleportedByPortal.timeSinceTeleport += deltaTime;
    });

    room->entities.view<TouchingPortal, RigidBody>().each([&](TouchingPortal &tp, RigidBody &body) {

        if (tp.timeSinceTouch > 0.0f)
        {
            body.collider.collideWithMaskBits |= tp.ignoredMask;
            body.collider.bedirt<&Collider::collideWithMaskBits>();
            tp.ignoredMask = 0;
        }
        tp.timeSinceTouch += deltaTime;
    });

    room->entities.view<Transform, PortalGun>().each([&](auto e, const Transform &t, PortalGun &gun) {

        bool canShoot = false;

        if (const Child *child = room->entities.try_get<Child>(e))
        {
            if (!room->entities.has<LocalPlayer>(child->parent))
            {
                return;
            }

            if (room->camera != nullptr)
            {
                const vec3 direction = room->camera->direction;

                room->getPhysics().rayTest(t.position, t.position + direction * 500.0f, [&](entt::entity wallEntity, const vec3 &hitPoint, const vec3 &normal) {

                    gun.canShootSince += deltaTime;
                    canShoot = true;

                    if (MouseInput::justPressed(gun.leftMB ? GLFW_MOUSE_BUTTON_LEFT : GLFW_MOUSE_BUTTON_RIGHT) && !Game::settings.unlockCamera)
                    {

                        bool oppositePortalHit = false;

                        room->getPhysics().rayTest(t.position, t.position + direction * 500.0f, [&](entt::entity oppositePortalEntity, const vec3 &hitPoint, const vec3 &normal) {

                            oppositePortalHit = true;

                        }, false, gun.oppositePortalMaskBits);

                        if (oppositePortalHit)
                        {
                            room->entities.destroy(room->getByName(gun.oppositePortalName.c_str()));
                        }

                        entt::entity oldPortal = room->getByName(gun.portalName.c_str());
                        if (room->entities.valid(oldPortal))
                        {
                            room->entities.destroy(oldPortal);
                        }

                        auto *portalTemplate = dynamic_cast<LuaEntityTemplate *>(&room->getTemplate("Portal"));
                        if (portalTemplate == nullptr)
                        {
                            return;
                        }
                        entt::entity portal = room->entities.create();
                        portalTemplate->createComponentsWithJsonArguments(portal, json{{"gunE", int(e)}}, false);
                        Transform &portalTransform = room->entities.get_or_assign<Transform>(portal);
                        portalTransform.position = hitPoint + normal * 0.05f;
                        portalTransform.rotation = quatLookAt(-normal, mu::Y);

                        room->emitEntityEvent(e, portal);
                    }
                }, true, gun.collideWithMaskBits);
            }
        }

        if (!canShoot)
        {
            gun.canShootSince = 0.0f;
        }
    });

    timePastSinceReplay += deltaTime;
    room->luaEnvironment["timePastSinceReplay"] = timePastSinceReplay;
    if (playerTeleported)
    {
        InputHistory &playerHistory = room->entities.get_or_assign<InputHistory>(playerE);

        if (playerHistory.timelineSize > 0)
        {
            histories.push_back(playerHistory);
        }
        playerHistory.timelineSize = 0;
        playerHistory.timeline.clear();

        replay();
    }
    else if (timePastSinceReplay >= 10.0f)
    {
        replay();
    }
}

vec4 PortalSystem::getPortalPlane(const Transform &transform)
{
    const mat4 transMat = Room3D::transformFromComponent(transform);

    const vec3 portalNormal = transMat * vec4(0, 0, -1, 0);

    return {portalNormal.x, portalNormal.y, portalNormal.z, dot(transform.position, -portalNormal)};
}

mat4 PortalSystem::teleportThroughPortals(const mat4 &transformPortalAMat, mat4 transformPortalBMat,
                                          const mat4 &toTeleport)
{
    // rotate portal B, yolo
    {
        vec3 upPortalB = transformPortalBMat * vec4(0, 1, 0, 0);
        transformPortalBMat = rotate(transformPortalBMat, mu::PI, upPortalB);
    }

    mat4 deltaPortalAToPortalB = transformPortalBMat * inverse(transformPortalAMat);

    return deltaPortalAToPortalB * toTeleport;
}

vec3 PortalSystem::transformDirectionByTeleport(const mat4 &transformPortalAMat, mat4 transformPortalBMat,
                                                const vec3 &toTeleport)
{
    // rotate portal B, yolo
    {
        vec3 upPortalB = transformPortalBMat * vec4(0, 1, 0, 0);
        transformPortalBMat = rotate(transformPortalBMat, mu::PI, upPortalB);
    }

    mat4 deltaPortalAToPortalB = transformPortalBMat * inverse(transformPortalAMat);

    return deltaPortalAToPortalB * vec4(toTeleport, 0.0f);
}

void PortalSystem::replay()
{
    timePastSinceReplay = 0.0f;

    room->entities.view<Portal>().each([&](auto e, auto &) {
        room->entities.destroy(e);
    });

    room->entities.view<LuaScripted>(entt::exclude<LocalPlayer>).each([&](auto e, const LuaScripted &luaScripted) {
        if (luaScripted.usedTemplate != nullptr && luaScripted.usedTemplate->name == "Portie")
        {
            room->entities.destroy(e);
        }
    });

    room->entities.view<LocalPlayer, Transform, InputHistory>().each([&](auto playerE, Transform &t, InputHistory &history) {

        if (history.timelineSize > 0)
        {
            t.copyFieldsFrom(history.timeline.front().transform);

            history.timelineSize = 0;
            history.timeline.clear();
        }

    });

    for (const InputHistory &history : histories)
    {
        entt::entity clone = room->getTemplate("Portie").create();
        room->entities.assign_or_replace<InputHistory>(clone, history);
        room->entities.assign_or_replace<Transform>(clone, history.timeline.front().transform);
    }
}

