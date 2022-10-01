
persistenceMode(TEMPLATE | ARGS, {"Transform", "Portal"})

collisionMasks = include("scripts/entities/level_room/_masks")

defaultArgs({
    name = "TestPortal"
})

function create(portal, args)

    setName(portal, args.name)

    component.Transform.getFor(portal)
    component.Portal.getFor(portal)
    setComponents(portal, {
        GhostBody {
            collider = Collider {
                collisionCategoryBits = collisionMasks.SENSOR,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER | collisionMasks.DYNAMIC_PROPS,
                registerCollisions = true
            }
        },
        SphereColliderShape {
            radius = 1
        }
    })

    setComponents(createChild(portal, "Camera"), {
        Transform()
    })

    onEntityEvent(portal, "Collision", function (col)
        print("Portal touch: "..(getName(col.otherEntity) or col.otherEntity))
    end)

    onEntityEvent(portal, "CollisionEnded", function (col)
        print("Portal UNtouch: "..(getName(col.otherEntity) or col.otherEntity))
    end)

end
