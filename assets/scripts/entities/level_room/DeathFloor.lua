
persistenceMode(TEMPLATE | ARGS, {"Transform"})

collisionMasks = include("scripts/entities/level_room/_masks")

function create(floor)

    setName(floor, "Death floor")
	
	setComponents(floor, {
		Transform {
            position = vec3(0, -50, 0),
            scale = vec3(500, 1, 500)
        },
        GhostBody {
            collider = Collider {
                collisionCategoryBits = collisionMasks.SENSOR,
                collideWithMaskBits = collisionMasks.DYNAMIC_CHARACTER,
                registerCollisions = true
            }
        },
        BoxColliderShape {
            halfExtents = vec3(500, 1, 500)
        }
	})

    onEntityEvent(floor, "Collision", function (col)
        print("Death floor touch: "..(getName(col.otherEntity) or col.otherEntity))

        if component.LocalPlayer.has(col.otherEntity) then
            _G.queueRestartLevel = true
        end
    end)

end

