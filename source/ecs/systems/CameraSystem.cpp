#include "CharacterMovementSystem.h"
#include "../../generated/Physics.hpp"
#include "../../generated/Transform.hpp"
#include "../../generated/Character.hpp"
#include "../../generated/Camera.hpp"
#include "../../game/Game.h"
#include "PhysicsSystem.h"
#include <generated/PlayerControlled.hpp>

#include "CameraSystem.h"

void CameraSystem::init(EntityEngine *engine)
{
    room = dynamic_cast<Room3D *>(engine);
    if (!room) throw gu_err("engine is not a room");
}

void CameraSystem::update(double deltaTime, EntityEngine *)
{
    assert(room);
    float dT(deltaTime);

    room->entities.view<Transform, ThirdPersonFollowing>().each([&](auto e, Transform &t, ThirdPersonFollowing &following) {

        if (!room->entities.valid(following.target) || !room->entities.has<Transform>(following.target))
            return;

        auto &targetTrans = room->entities.get<Transform>(following.target);

        // target's space:
        {
            auto targetToWorld = Room3D::transformFromComponent(targetTrans);   // todo remove scale, if scale is used for animations?
            auto worldToTarget = inverse(targetToWorld);

            vec3 targetForwardWorldSpace = targetToWorld * vec4(-mu::Z, 0);
            vec3 targetUpWorldSpace = targetToWorld * vec4(mu::Y, 0);
            vec3 camOffsetDir = vec3(-targetForwardWorldSpace.x, 0, -targetForwardWorldSpace.z);
            auto camOffsetLen = length(camOffsetDir);
            if (camOffsetLen > 0)
            {
                static const float MIN_OFFSET_LEN = .9;

                if (camOffsetLen < MIN_OFFSET_LEN)
                {
                    camOffsetDir += targetUpWorldSpace * 2.f * (1.f - (camOffsetLen / MIN_OFFSET_LEN));
                    camOffsetLen = length(camOffsetDir);
                }

                camOffsetDir /= camOffsetLen;

                //vec3 camOffsetDirTargetSpace = worldToTarget * vec4(camOffsetDir, 0.f);

                vec3 currentPos = t.position;//worldToTarget * vec4(t.position, 1);
                vec3 newPos = targetTrans.position + camOffsetDir * following.backwardsDistance + targetUpWorldSpace * following.upwardsDistance;

                auto currCamTargetDiff = targetTrans.position - t.position;
                auto currCamTargetDist = length(currCamTargetDiff);

                static const float SMOOTH_MIN_MAX = 4;

                float changeSpeedMultiplier = 1.f - min(1.f, max(0.f, (currCamTargetDist - following.minDistance) / SMOOTH_MIN_MAX));

                changeSpeedMultiplier += Interpolation::powIn(min(1.f, max(0.f, (currCamTargetDist - (following.maxDistance - SMOOTH_MIN_MAX)) / SMOOTH_MIN_MAX)), 2);
                changeSpeedMultiplier = min(1.f, changeSpeedMultiplier);

                /*
                auto &physics = room->getPhysics();
                physics.rayTest(targetTrans.position, t.position, [&](auto, const vec3 &hitPoint, const vec3 &normal) {


                }, true, following.visibilityRayMask);
                */

                vec3 interpolatedPos = mix(currentPos, newPos, min(1.f, dT * 3.f * changeSpeedMultiplier));
                t.position = interpolatedPos;//targetToWorld * vec4(interpolatedPos, 1);
            }



        }

        auto camTargetDiff = targetTrans.position - t.position;
        auto camTargetDist = length(camTargetDiff);

        if (camTargetDist != 0)
        {
            auto camTargetDir = camTargetDiff / camTargetDist;
            t.rotation = slerp(t.rotation, quatLookAt(camTargetDir, mu::Y), dT * 20.f);
        }
    });

    if (Game::settings.unlockCamera)
    {
        return;
    }

    room->entities.view<TransformChild, FirstPersonCamera>().each([&](auto e, TransformChild &t, FirstPersonCamera &firstPerson) {

        if (!room->entities.valid(firstPerson.target))
        {
            return;
        }

        if (!Game::settings.unlockCamera)
        {
            MouseInput::setLockedMode(true);
            firstPerson.lockedCamera = true;
        }

        Transform *playerTransform = room->entities.try_get<Transform>(firstPerson.target);
        if (playerTransform == nullptr)
        {
            return;
        }

        /*
        mat4 playerTransformMat = room->transformFromComponent(*playerTransform);
        vec3 right = playerTransformMat * vec4(1, 0, 0, 0);
         */

        if (gu::width <= 0 || gu::height <= 0)
        {
            return;
        }

        t.offset.rotation = rotate(t.offset.rotation,
                                   float(MouseInput::deltaMouseY * mu::DEGREES_TO_RAD) * -Game::settings.firstPersonMouseSensitivity * 0.1f,
                                   mu::X);
        playerTransform->rotation = rotate(playerTransform->rotation,
                                           float(MouseInput::deltaMouseX * mu::DEGREES_TO_RAD) * -Game::settings.firstPersonMouseSensitivity * 0.1f,
                                           mu::Y);
    });
}

