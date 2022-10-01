
#include <generated/Children.hpp>
#include <generated/PlayerControlled.hpp>
#include "PortalSystem.h"
#include "PhysicsSystem.h"

#include "../../generated/Physics.hpp"
#include "../../generated/Portal.hpp"
#include "../../game/Game.h"

void PortalSystem::init(EntityEngine *engine)
{
    EntitySystem::init(engine);
    room = dynamic_cast<Room3D *>(engine);
    if (!room) throw gu_err("engine is not a room");
}

void PortalSystem::update(double deltaTime, EntityEngine *)
{
    room->entities.view<Transform, GhostBody, Portal>().each([&](auto portalAE, const Transform &transformPortalA, const GhostBody &body, const Portal &portalA) {

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

            float planeDot = dot(vec4(transformVictim->position, 1.0f), planePortalA);

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

                if (RigidBody *rigidBodyVictim = room->entities.try_get<RigidBody>(victim))
                {
                    room->getPhysics().setLinearVelocity(
                        *rigidBodyVictim,
                        transformDirectionByTeleport(
                            Room3D::transformFromComponent(transformPortalA),
                            Room3D::transformFromComponent(transformPortalB),
                            room->getPhysics().getLinearVelocity(*rigidBodyVictim)
                        )
                    );
                }
            }
        }
    });

    room->entities.view<TeleportedByPortal>().each([&](TeleportedByPortal &teleportedByPortal) {
        teleportedByPortal.timeSinceTeleport += deltaTime;
    });

    room->entities.view<Transform, PortalGun>().each([&](auto e, const Transform &t, const PortalGun &gun) {

        if (const Child *child = room->entities.try_get<Child>(e))
        {
            if (room->entities.has<PlayerControlled>(child->parent))
            {
                if (MouseInput::justPressed(GLFW_MOUSE_BUTTON_LEFT))// && !Game::settings.unlockCamera)
                {
                    vec3 direction = rotate(t.rotation, -mu::Z);

                    room->getPhysics().rayTest(t.position, t.position + direction * 500.0f, [&](entt::entity wallEntity, const vec3 &hitPoint, const vec3 &normal) {

                        entt::entity portal = room->getTemplate("Portal").create();
                        Transform &portalTransform = room->entities.get_or_assign<Transform>(portal);
                        portalTransform.position = hitPoint - normal * 0.01f;
                        portalTransform.rotation = quatLookAt(-normal, mu::Y);

                    }, true, gun.collideWithMaskBits);
                }
            }
        }
    });
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

