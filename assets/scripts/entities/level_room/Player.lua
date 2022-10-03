
function create(player)

    if not _G.titleScreen then
        applyTemplate(player, "Portie", {
            isLocalPlayer = true
        })
        _G.currentRoom = currentEngine

        currentEngine.hudText = "Level "..(_G.levelI + 1)
        setTimeout(player, 5, function()
            currentEngine.hudText = nil
        end)

        setComponents(player, {
            SoundSpeaker {
                sound = "sounds/atmosphere",
                volume = .2,
                looping = true
            },
        })

    else
        applyTemplate(player, "Title")
    end

end
