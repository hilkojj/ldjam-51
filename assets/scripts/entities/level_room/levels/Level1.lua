
persistenceMode(TEMPLATE | ARGS, {"Transform"})

collisionMasks = include("scripts/entities/level_room/_masks")

defaultArgs({
})

loadModels("assets/models/levels/level1.glb", false)
loadColliderMeshes("assets/models/levels/level1_collider.obj", false)

function create(levelEntity, args)

    setName(levelEntity, "Level1")

    setComponents(levelEntity, {
        Transform()
    })

    setComponents(createChild(levelEntity, "FloorCollider"), {
        Transform(),
        RigidBody {
            mass = 0,
            collider = Collider {
                bounciness = 1,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.STATIC_FLOORS,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER | collisionMasks.DYNAMIC_PROPS
            }
        },
        ConcaveColliderShape {
            meshName = "Level1Floor"
        },
        RenderModel {
            modelName = "Level1Floor"
        },
        ShadowCaster(),
        ShadowReceiver()
    })

    setComponents(createChild(levelEntity, "WallCollider"), {
        Transform(),
        RigidBody {
            mass = 0,
            collider = Collider {
                bounciness = 1,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.STATIC_WALLS,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER | collisionMasks.DYNAMIC_PROPS
            }
        },
        ConcaveColliderShape {
            meshName = "Level1Wall"
        },
        RenderModel {
            modelName = "Level1Wall"
        },
        ShadowCaster(),
        ShadowReceiver()
    })

    setComponents(createChild(levelEntity, "PortalWallCollider"), {
        Transform(),
        RigidBody {
            mass = 0,
            collider = Collider {
                bounciness = 1,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.BULLET_WALLS,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER | collisionMasks.DYNAMIC_PROPS
            }
        },
        ConcaveColliderShape {
            meshName = "Level1PortalWall"
        }
    })

end
