
collisionMasks = include("scripts/entities/level_room/_masks")

function create(portal, args)

    local gun = component.PortalGun.getFor(args.gunE)

    print(gun.portalName)

    setName(portal, gun.portalName)

    setComponents(portal, {
        Transform(),
        Portal {
            linkedPortalName = gun.oppositePortalName,

            letBodyIgnoreMaskWhenOnWall = collisionMasks.STATIC_WALLS,
            letBodyIgnoreMaskWhenOnFloor = collisionMasks.STATIC_FLOORS,

            color = gun.color
        },
        GhostBody {
            collider = Collider {
                collisionCategoryBits = gun.portalMaskBits,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER | collisionMasks.DYNAMIC_PROPS,
                registerCollisions = true
            }
        },
        SphereColliderShape {
            radius = 1
        },
        PointLight {
            color = vec3(0)
        }
    })

    component.PointLight.animate(portal, "color", gun.color * vec3(10), 0.3, "circle")

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
