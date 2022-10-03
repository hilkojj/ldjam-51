
masks = include("scripts/entities/level_room/_masks")

loadModels("assets/models/gun.glb", false)

defaultArgs({
    isA = true,
    dummy = false
})

function create(gun, args)
    setComponents(gun, {
        Transform(),
        RenderModel {
            modelName = "PortalGun"
        },
        --[[
        Rigged {
            playingAnimations = {
                PlayAnimation {
                    name = "testanim",
                    influence = 1,
                }
            }
        },
        ]]--
        --ShadowCaster(),
        PortalGun {
            portalName = args.isA and "PortalA" or "PortalB",
            oppositePortalName = args.isA and "PortalB" or "PortalA",
            leftMB = not args.isA,
            collideWithMaskBits = masks.BULLET_WALLS,
            oppositePortalMaskBits = args.isA and masks.PORTAL_B or masks.PORTAL_A,
            portalMaskBits = (args.isA and masks.PORTAL_A or masks.PORTAL_B) | masks.SENSOR,
            retiredMask = masks.OLD_PORTAL,
            color = args.isA and vec3(0.4, 0.6, 0.3) or vec3(0.8, 0.3, 0.4)
        }
    })

    if not args.dummy then
        -- to reserve a pointlight in the shaders for the portals. The portal will remove/add this pointlight on its creation/destruction respectively.
        component.PointLight.getFor(gun).color = vec3(0)
    end

    local timeE = createChild(gun, "time")
    setComponents(timeE, {
        Transform(),
        TransformChild {
            parentEntity = gun
        },
        RenderModel {
            modelName = "PortalGunTime"
        },
        --ShadowCaster(),
        CustomShader {
            vertexShaderPath = "shaders/default.vert",
            fragmentShaderPath = "shaders/default.frag",
            defines = {PORTAL_GUN_TIME = "1"},
            uniformsVec3 = {portalGunColor = component.PortalGun.getFor(gun).color}
        },
    })
    setUpdateFunction(timeE, 0.0, function()
        component.CustomShader.getFor(timeE):dirty().uniformsFloat.gunTimer = currentEngine.timePastSinceReplay and currentEngine.timePastSinceReplay or 0
    end)

    setComponents(createChild(gun, "colored"), {
        Transform(),
        TransformChild {
            parentEntity = gun
        },
        RenderModel {
            modelName = "PortalGunColored"
        },
        --ShadowCaster(),
        CustomShader {
            vertexShaderPath = "shaders/default.vert",
            fragmentShaderPath = "shaders/default.frag",
            defines = {PORTAL_GUN_COLORED = "1"},
            uniformsVec3 = {portalGunColor = component.PortalGun.getFor(gun).color}
        },
    })
    if not args.dummy then
        setComponents(createChild(gun, "light"), {
            Transform(),
            TransformChild {
                parentEntity = gun,
                offset = Transform {
                    position = vec3(args.isA and -0.5 or 0.5, 0, -1)
                }
            },
            PointLight {
                color = component.PortalGun.getFor(gun).color * vec3(20.0)
            }
        })
    end

    onEntityEvent(gun, "Portal", function(portal)

        currentEngine["startPortalTimer"] = true
    end)

end

