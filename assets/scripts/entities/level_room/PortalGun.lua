
masks = include("scripts/entities/level_room/_masks")

loadModels("assets/models/gun.glb", false)

defaultArgs({
    isA = true
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
        ShadowCaster(),
        PortalGun {
            portalName = args.isA and "PortalA" or "PortalB",
            oppositePortalName = args.isA and "PortalB" or "PortalA",
            leftMB = args.isA,
            collideWithMaskBits = masks.BULLET_WALLS,
            oppositePortalMaskBits = args.isA and masks.PORTAL_B or masks.PORTAL_A,
            portalMaskBits = (args.isA and masks.PORTAL_A or masks.PORTAL_B) | masks.SENSOR,
            color = args.isA and vec3(0.4, 0.6, 0.3) or vec3(0.8, 0.3, 0.4)
        },
        PointLight {
            color = vec3(0) -- to reserve a pointlight in the shaders for the portals. The portal will remove/add this pointlight on its creation/destruction respectively.
        }
    })

    onEntityEvent(gun, "Portal", function(portal)

    end)

end

