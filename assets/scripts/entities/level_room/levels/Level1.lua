
persistenceMode(TEMPLATE | ARGS, {"Transform"})

collisionMasks = include("scripts/entities/level_room/_masks")

defaultArgs({
    name = "Level0"
})

loadModels("assets/models/levels/level1.glb", false)
loadColliderMeshes("assets/models/levels/level1.obj", false)

function create(levelEntity, args)
    setName(levelEntity, args.name)

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
            meshName = args.name.."Floor"
        },
        RenderModel {
            modelName = args.name.."Floor"
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
            meshName = args.name.."Wall"
        },
        RenderModel {
            modelName = args.name.."Wall"
        },
        ShadowCaster(),
        ShadowReceiver()
    })

    setComponents(createChild(levelEntity, "Cables"), {
        Transform(),
        RenderModel {
            modelName = args.name.."Cables"
        },
        ShadowCaster(),
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
            meshName = args.name.."PortalWall"
        }
    })

end
