
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
            }
        },
        BoxColliderShape {
            halfExtents = vec3(1, 0.2, 1)
        },
        ShadowCaster(),
        ShadowReceiver()
    })
    component.Transform.getFor(e)

end
