
function create(player)

    if not _G.titleScreen then
        applyTemplate(player, "Portie")
    else
        applyTemplate(player, "Title")
    end

end
