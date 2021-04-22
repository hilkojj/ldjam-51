
#include "ArmatureAnimationSystem.h"
#include "../../level/room/Room3D.h"
#include "../../generated/Model.hpp"

void ArmatureAnimationSystem::update(double deltaTime, EntityEngine *engine)
{
    auto room = dynamic_cast<Room3D *>(engine);
    if (!room) return;

    room->entities.view<Transform, RenderModel, Rigged>().each([&](Transform &t, RenderModel &rm, Rigged &rig) {

        rig.bonePoseTransform.clear();

        auto &model = room->models[rm.modelName];
        if (!model) return;

        SharedArmature arm;
        for (auto &part : model->parts)
        {
            if (!part.armature || !part.armature->root) continue;
            arm = part.armature;
            break;
        }
        if (!arm) return;

        for (auto &play : rig.playingAnimations)
        {
            if (arm->animations.find(play.name) == arm->animations.end())
                continue;

            auto &anim = arm->animations[play.name];
            play.timer += deltaTime * play.timeMultiplier;

            std::function<void(SharedBone &, const mat4 &, const mat4 &)> calcBone;
            calcBone = [&] (SharedBone &bone, const mat4 &originalParent, const mat4 &poseParent) {

                mat4 boneTransform = bone->getBoneSpaceTransform(); // boneTransform = BONE SPACE in relation to parent bone!

                mat4 ori = originalParent * boneTransform; // ori = MODEL SPACE

                mat4 pose = poseParent * boneTransform;  // pose = MODEL SPACE

                auto &keyframes = anim.keyFramesPerBone[bone];
                if (keyframes.size() >= 2)
                {
                    int kfI;
                    for (kfI = 0; kfI < keyframes.size() - 2; kfI++)
                        if (keyframes[kfI + 1].keyTime >= play.timer)
                            break;

                    auto &kf0 = keyframes.at(kfI);
                    auto &kf1 = keyframes.at(kfI + 1);

                    float progress = (play.timer - kf0.keyTime) / (kf1.keyTime - kf0.keyTime);
                    progress = min(1.f, progress);

                    mat4 interpolatedBoneTransform = glm::translate(mat4(1), mix(kf0.translation, kf1.translation, progress));
                    interpolatedBoneTransform *= glm::toMat4(slerp(kf0.rotation, kf1.rotation, progress));
                    interpolatedBoneTransform = glm::scale(interpolatedBoneTransform, mix(kf0.scale, kf1.scale, progress));
                    // interpolatedBoneTransform = BONE SPACE in relation to parent bone!

                    pose = poseParent * interpolatedBoneTransform;  // pose = MODEL SPACE
                }

                rig.bonePoseTransform[bone] = pose * inverse(ori);     // NOT IN MODEL SPACE! "Vertex space"?

                for (auto &child : bone->children)
                    calcBone(child, ori, pose);
            };
            calcBone(arm->root, mat4(1.), mat4(1.));
        }

    });
}