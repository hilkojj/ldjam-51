
collisionMasks = include("scripts/entities/level_room/_masks")
loadModels("assets/models/banana.glb", false)

function create(banana)

    local rot = quat:new():setIdentity()
    rot.y = math.random() * 360

    setComponents(banana, {
        Transform {
            rotation = rot
        },
        RigidBody {
            mass = 0.1,
            angularAxisFactor = vec3(0.7),
            collider = Collider {
                bounciness = .1,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.DYNAMIC_PROPS,
                collideWithMaskBits = collisionMasks.STATIC_TERRAIN | collisionMasks.STATIC_WALLS |collisionMasks.STATIC_FLOORS | collisionMasks.DYNAMIC_PROPS | collisionMasks.SENSOR,
            }
        },
        BoxColliderShape {
            halfExtents = vec3(0.5, 0.17, 0.25)
        },
        GravityFieldAffected {
            defaultGravity = vec3(0, -10, 0)
        }
    })

end
