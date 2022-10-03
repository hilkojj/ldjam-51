
persistenceMode(TEMPLATE | ARGS, {"Transform"})

collisionMasks = include("scripts/entities/level_room/_masks")

defaultArgs({
    name = "Bridge",
})

function getDefaultRot()
    local defaultRot = quat:new():setIdentity()
    defaultRot.z = 70
    return defaultRot
end

function create(e, args)

    setName(e, args.name)

    setComponents(e, {
        RenderModel {
            modelName = "Bridge"
        },
        ShadowReceiver(),
        ShadowCaster()
    })

    component.Transform.getFor(e).rotation = getDefaultRot()

    local body = createChild(e, "Body")
    setComponents(body, {
        Transform(),
        TransformChild {
            parentEntity = e,
            offset = Transform {
                position = vec3(2, 0, 0)
            }
        },
        RigidBody {
            mass = 0,
            collider = Collider {
                bounciness = 1,
                frictionCoefficent = 4,
                collisionCategoryBits = collisionMasks.STATIC_TERRAIN,
                collideWithMaskBits = collisionMasks.DYNAMIC_PROPS | collisionMasks.DYNAMIC_CHARACTER,
            },
        },
        BoxColliderShape {
            halfExtents = vec3(2, 0.2, 2)
        },
    })

    currentEngine[args.name.."_activate"] = function()
        component.Transform.animate(e, "rotation", quat:new():setIdentity(), .5, "pow2Out")

        setComponents(createChild(e), {
            Transform(),
            TransformChild {
                parentEntity = e
            },
            SoundSpeaker {
                sound = "sounds/bridge_open",
                volume = .3
            },
            PositionedAudio(),
            DespawnAfter {
                time = 4
            }
        })

    end
    currentEngine[args.name.."_deactivate"] = function()
        component.Transform.animate(e, "rotation", getDefaultRot(), .5, "pow2")


        setComponents(createChild(e), {
            Transform(),
            TransformChild {
                parentEntity = e
            },
            SoundSpeaker {
                sound = "sounds/bridge_close",
                volume = .1
            },
            PositionedAudio(),
            DespawnAfter {
                time = 4
            }
        })
    end
end
