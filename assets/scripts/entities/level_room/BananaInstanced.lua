
collisionMasks = include("scripts/entities/level_room/_masks")
loadModels("assets/models/banana.glb", false)

function create(banana)

    setComponents(banana, {
        RigidBody {
            mass = 10,
            collider = Collider {
                bounciness = .3,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.DYNAMIC_PROPS,
                collideWithMaskBits = collisionMasks.STATIC_TERRAIN | collisionMasks.DYNAMIC_PROPS | collisionMasks.SENSOR,
            }
        },
        BoxColliderShape {
            halfExtents = vec3(0.5, 0.17, 0.25)
        },
    })

    print(collisionMasks.DYNAMIC_PROPS)

end
