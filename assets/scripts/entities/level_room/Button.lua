
persistenceMode(TEMPLATE | ARGS, {"Transform"})

collisionMasks = include("scripts/entities/level_room/_masks")

defaultArgs({
    name = "Button",
    activateFunction = "_",
    deactivateFunction = "_",
    stayPressed = false
})

function create(e, args)

    setName(e, args.name)

    setComponents(e, {
        RenderModel {
            modelName = "ButtonBase"
        },
        RigidBody {
            mass = 0,
            collider = Collider {
                bounciness = 1,
                frictionCoefficent = 1,
                collisionCategoryBits = collisionMasks.STATIC_TERRAIN,
                collideWithMaskBits = collisionMasks.DYNAMIC_PROPS | collisionMasks.DYNAMIC_CHARACTER,
                registerCollisions = true
            },
        },
        BoxColliderShape {
            halfExtents = vec3(0.5, 0.05, 0.5)
        },
        ShadowReceiver(),

    })
    component.Transform.getFor(e)

    local light = createChild(e, "Light")
    setComponents(light, {
        Transform(),
        TransformChild {
            parentEntity = e,
            offset = Transform {
                position = vec3(0, 1, 0)
            }
        },
        PointLight {
            color = vec3(0)
        },
    })

    local movingPart = createChild(e, "MovingPart")
    setComponents(movingPart, {
        Transform(),
        TransformChild {
            parentEntity = e
        },
        RenderModel {
            modelName = "ButtonMovingPart"
        }
    })

    local buttonPosition = vec3(0)

    onEntityEvent(e, "Collision", function (col)

        if component.TransformChild.has(movingPart) then

            component.TransformChild.remove(movingPart)
            local transform = component.Transform.getFor(movingPart)
            buttonPosition = vec3(transform.position)
        end

        component.Transform.animate(movingPart, "position", buttonPosition + vec3(0, -0.1, 0), 0.1, "pow2Out")
        component.PointLight.animate(light, "color", vec3(35, 5, 38), 0.1, "pow2Out")

        if args.activateFunction ~= nil and currentEngine[args.activateFunction] ~= nil then
            currentEngine[args.activateFunction](col)
        end
    end)

    if not args.stayPressed then

        onEntityEvent(e, "CollisionEnded", function (col)

            component.Transform.animate(movingPart, "position", buttonPosition, 0.1, "pow2In")
            component.PointLight.animate(light, "color", vec3(0), 0.1, "pow2Out")

            if args.deactivateFunction ~= nil and currentEngine[args.deactivateFunction] ~= nil then
                currentEngine[args.deactivateFunction](col)
            end
        end)
    end

end
