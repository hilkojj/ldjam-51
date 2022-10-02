
function create(player)

    if not _G.titleScreen then
        applyTemplate(player, "Portie", {
            isLocalPlayer = true
        })
    else
        applyTemplate(player, "Title")
    end

end
