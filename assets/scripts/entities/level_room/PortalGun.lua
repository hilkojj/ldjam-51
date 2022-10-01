
masks = include("scripts/entities/level_room/_masks")

loadModels("assets/models/gun.glb", false)

function create(gun)
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
            collideWithMaskBits = masks.BULLET_WALLS
        }
    })
end

