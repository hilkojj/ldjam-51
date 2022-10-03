
persistenceMode(TEMPLATE | ARGS, {"Transform"})

collisionMasks = include("scripts/entities/level_room/_masks")

function create(e)

    setName(e, "Finish")

    setComponents(e, {
        RenderModel {
            modelName = "Finish"
        },
        RigidBody {
            mass = 0,
            collider = Collider {
                bounciness = 1,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.STATIC_TERRAIN,
                collideWithMaskBits = collisionMasks.DYNAMIC_PROPS | collisionMasks.DYNAMIC_CHARACTER,
                registerCollisions = true
            }
        },
        BoxColliderShape {
            halfExtents = vec3(0.8, 0.1, 0.8)
        },
        ShadowCaster(),
        ShadowReceiver(),

    })
    component.Transform.getFor(e)

    setComponents(createChild(e, "light"), {
        PointLight {
            color = vec3(30, 1, 1)
        },
        Transform(),
        TransformChild {
            parentEntity = e,
            offset = Transform {
                position = vec3(0, 1.5, 0)
            }
        }
    })

    onEntityEvent(e, "Collision", function (col)

        local otherEntity = col.otherEntity

        if component.LocalPlayer.has(otherEntity) then
            print("Player finished!")

            setTimeout(otherEntity, 0.2, function()

                currentEngine.hudText = "Level completed! Click to continue..."

                component.CharacterMovement.remove(otherEntity)
                component.RigidBody.remove(otherEntity)

                local newCam = createEntity()
                applyTemplate(newCam, "Camera", {
                    name = "finishCam",
                    setAsMain = true
                })

                local animDuration = 4

                component.CameraPerspective.animate(newCam, "fieldOfView", 40, animDuration, "pow2")

                local oldTransform = component.Transform.getFor(getByName("1st_person_camera"))
                local newTransform = component.Transform.getFor(newCam)
                newTransform.position = oldTransform.position
                newTransform.rotation = oldTransform.rotation

                component.Transform.animate(newCam, "position", component.Transform.getFor(e).position + vec3(0, 20, 0), animDuration)
                currentEngine["levelFinished"] = true

                component.CameraLookAt.getFor(newCam).targetName = "portie_0"

                setTimeout(newCam, 10 - timePastSinceReplay, function()

                    local replayI = 1

                    local nextReplayFollow = function()

                        if getByName("portie_"..replayI) == nil then
                            replayI = 0
                        end

                        component.CameraLookAt.getFor(newCam).targetName = "portie_"..replayI

                        replayI = replayI + 1
                    end

                    setUpdateFunction(newCam, 10, nextReplayFollow, false)
                    nextReplayFollow()
                end)
            end)
        end
    end)

end
