
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
                component.CharacterMovement.remove(otherEntity)
            end)
        end
    end)

end
