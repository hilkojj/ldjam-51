
collisionMasks = include("scripts/entities/level_room/_masks")

function create(portal, args)

    local gun = component.PortalGun.getFor(args.gunE)

    print(gun.portalName)

    setName(portal, gun.portalName)

    component.PointLight.remove(args.gunE)
    setComponents(portal, {
        Transform(),
        Portal {
            linkedPortalName = gun.oppositePortalName,

            letBodyIgnoreMaskWhenOnWall = collisionMasks.STATIC_WALLS,
            letBodyIgnoreMaskWhenOnFloor = collisionMasks.STATIC_FLOORS,

            color = gun.color,

            retiredMask = gun.retiredMask
        },
        GhostBody {
            collider = Collider {
                collisionCategoryBits = gun.portalMaskBits,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER | collisionMasks.DYNAMIC_PROPS,
                registerCollisions = true
            }
        },
        SphereColliderShape {
            radius = 0.7
        },
        PointLight {
            color = vec3(0)
        }
    })

    component.PointLight.animate(portal, "color", gun.color * vec3(10), 0.3, "circle")

    setComponents(createChild(portal, "Camera"), {
        Transform(),
        --[[
        RenderModel {
            modelName = "ButtonMovingPart"
        }
        ]]--
    })

    onEntityEvent(portal, "Collision", function (col)
        print("Portal touch: "..(getName(col.otherEntity) or col.otherEntity))
    end)

    onEntityEvent(portal, "CollisionEnded", function (col)
        print("Portal UNtouch: "..(getName(col.otherEntity) or col.otherEntity))
    end)

    setOnDestroyCallback(portal, function()
        if valid(args.gunE) then
            component.PointLight.getFor(args.gunE).color = vec3(0)
        end
    end)

end
