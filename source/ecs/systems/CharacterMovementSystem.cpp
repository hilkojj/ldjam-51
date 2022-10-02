#include "CharacterMovementSystem.h"
#include "../../generated/Physics.hpp"
#include "../../generated/Transform.hpp"
#include "../../generated/Character.hpp"
#include "../../generated/Camera.hpp"
#include "../../game/Game.h"
#include "PhysicsSystem.h"
#include <generated/PlayerControlled.hpp>

void CharacterMovementSystem::init(EntityEngine *engine)
{
    room = dynamic_cast<Room3D *>(engine);
    if (!room) throw gu_err("engine is not a room");
    updateFrequency = 60;
}

void CharacterMovementSystem::update(double deltaTime, EntityEngine *)
{
    assert(room);
    float dT(deltaTime);

    room->entities.view<MovementInput, LocalPlayer>().each([&](auto e, MovementInput &input, auto) {

        input.walkDirInput.y = KeyInput::pressed(Game::settings.keyInput.walkForwards) - KeyInput::pressed(Game::settings.keyInput.walkBackwards);
        input.walkDirInput.x = KeyInput::pressed(Game::settings.keyInput.walkRight) - KeyInput::pressed(Game::settings.keyInput.walkLeft);

        input.walkDirInput.x += GamepadInput::getAxis(0, Game::settings.gamepadInput.walkX);
        input.walkDirInput.y -= GamepadInput::getAxis(0, Game::settings.gamepadInput.walkY);

        input.jumpInput = KeyInput::pressed(Game::settings.keyInput.jump) || GamepadInput::pressed(0, Game::settings.gamepadInput.jump);
    });

    room->entities.view<Transform, MovementInput, InputHistory>().each([&](auto e, Transform &t, MovementInput &input, InputHistory &history) {

        if (room->entities.has<LocalPlayer>(e))
        {
            // capture:
            history.timeline.push_back(input);
            history.timeline.back().transform = t;
            if (room->entities.valid(room->cameraEntity))
            {
                if (const TransformChild *camT = room->entities.try_get<TransformChild>(room->cameraEntity))
                {
                    history.timeline.back().headTransform = camT->offset;
                }
            }
            history.timelineSize++;
            if (history.timelineSize > history.maxTimelineSize)
            {
                history.timeline.pop_front();
            }
        }
        else
        {
            if (history.timeline.empty())
            {
                room->entities.destroy(e);
                return;
            }
            // playback:
            input = history.timeline.front();
            t.rotation = input.transform.rotation;
            room->entities.get_or_assign<TransformChild>(room->getChildByName(e, "eye")).offset = input.headTransform;
            room->entities.get_or_assign<TransformChild>(room->getChildByName(e, "decoGunA")).offset.rotation = input.headTransform.rotation;
            room->entities.get_or_assign<TransformChild>(room->getChildByName(e, "decoGunB")).offset.rotation = input.headTransform.rotation;

            int missingFrames = history.maxTimelineSize - history.timelineSize;

            if (history.popsSkipped < missingFrames)
            {
                history.popsSkipped++;
                t.copyFieldsFrom(input.transform);// prevent long jump press from actually causing jump
            }
            else
            {
                history.timeline.pop_front();
            }
        }
    });

    room->entities.view<CharacterMovement, MovementInput, Transform, RigidBody>().each([&](auto e, CharacterMovement &cm, const MovementInput &input, Transform &t, RigidBody &rb) {

        vec3 oldForward = rotate(t.rotation, -mu::Z);  // based on camera.cpp // todo: normalize?
        vec3 oldRight = rotate(t.rotation, mu::X);
        vec3 oldUp = normalize(cross(oldRight, oldForward));

        // ----------- new rotation:
        const static float MIN_GRAV = .1;

        float gravLen = length(rb.gravity);
        vec3 gravDir = gravLen < MIN_GRAV ? -oldUp : (rb.gravity / gravLen);

        vec3 up = -gravDir;
        vec3 forward = cross(oldRight, gravDir);
        float forwardLen = length(forward);

        if (forwardLen == 0)
        {
            std::cerr << "forwardLen == 0" << std::endl;
            // TODO
            return;
        }

        forward /= forwardLen;
        t.rotation = slerp(t.rotation, quatLookAt(forward, up), min(dT * 10.f, 1.f));
        vec3 interpolatedForward = rotate(t.rotation, -mu::Z);

        // --------------------

        if (!rb.collider.registerCollisions)
        {
            rb.collider.registerCollisions = true;
            rb.collider.bedirt<&Collider::registerCollisions>();
            return;
        }

        auto localToWorld = Room3D::transformFromComponent(t);
        auto worldToLocal = inverse(localToWorld);

        bool collisionWithGround = false;

        for (auto &[otherE, col] : rb.collider.collisions)
        {
            if (!room->entities.valid(otherE) || !room->entities.has<RigidBody>(otherE))
                continue;

            for (auto &cP : col->contactPoints)
            {
                vec3 local = worldToLocal * vec4(cP, 1);
                // TODO: bullet gives them in local too I think, just store that, saves some calculations.

                if (dot(local, -mu::Y) > .7) // TODO does this number make sense?
                {
                    collisionWithGround = true;
                    break;
                }
            }
            if (collisionWithGround)
                break;
        }

        auto &physics = room->getPhysics();
        vec3 currVelocity = physics.getLinearVelocity(rb);
        vec3 currVelLocal = worldToLocal * vec4(currVelocity, 0);
        bool justLanded = !cm.onGround;

        if (!collisionWithGround)
        {
            justLanded = false;

            if (cm.jumpStarted)
                cm.leftGroundSinceJumpStarted = true;
            cm.coyoteTime += dT;
            if (cm.jumpStarted)
                cm.onGround = false;
            else
                cm.onGround = cm.coyoteTime < .3; // TODO make variable
        }
        else
        {
            cm.coyoteTime = 0;
            cm.onGround = true;

            if (cm.leftGroundSinceJumpStarted && cm.jumpStarted)
            {
                cm.jumpStarted = false;
            }
            if (!cm.jumpStarted)
                physics.applyForce(rb, gravDir * 1000.f * dT);
        }

        //if (cm.onGround)
        {
            if (cm.onGround && input.jumpInput && !cm.jumpStarted)
            {
                physics.applyForce(rb, up * cm.jumpForce);
                cm.jumpStarted = true;
                cm.leftGroundSinceJumpStarted = false;
                cm.holdingJumpEnded = false;
                cm.jumpDescend = false;
            }

            vec3 currVerticalVel = localToWorld * vec4(0, currVelLocal.y, 0, 0);

            vec3 velocity = forward * min(1.f, (input.walkDirInput.y)) * cm.walkSpeed + currVerticalVel;
            velocity += oldRight * min(1.f, (input.walkDirInput.x)) * cm.walkSpeed;

            velocity = mix(currVelocity, velocity, min(1.f, dT * 10.f + justLanded));
            physics.setLinearVelocity(rb, velocity);
        }

        if (cm.jumpStarted)
        {
            if (currVelLocal.y < 0 && cm.leftGroundSinceJumpStarted)
            {
                cm.jumpDescend = true;
            }
            if (!input.jumpInput)
            {
                cm.holdingJumpEnded = true;
            }
            
            if (cm.jumpDescend || cm.holdingJumpEnded)
            {
                physics.applyForce(rb, gravDir * cm.fallingForce * dT);
            }
        }

        /*
        float rotateAmount = min(1.f, abs(cm.walkDirInput.x) * 2.f);
        t.rotation = rotate(t.rotation, cm.walkDirInput.x * dT * -2.f * rotateAmount, mu::Y);
         */
    });
}
