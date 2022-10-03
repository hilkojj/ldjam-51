
_G.titleScreen = false
_G.hudScreen = currentEngine

onEvent("BeforeDelete", function()
    loadOrCreateLevel(nil)
    if _G.hudScreen == currentEngine then
        _G.hudScreen = nil
    end
end)

if _G.levelToLoad == nil then
    error("_G.levelToLoad is nil")
end

applyTemplate(createEntity(), "LevelRestarter")
loadOrCreateLevel(_G.levelToLoad)

--[[
setComponents(createEntity(), {
    UIElement(),
    TextView {
        text = "LDJam 50 - Theme ???",
        fontSprite = "sprites/ui/default_font"
    }
})
]]--

function nextLevel()

    print("click")

    if _G.currentRoom.levelFinished == nil then
        return
    end

    print("Go to next level")

    if _G.levelI == 3 then
        closeActiveScreen()
        openScreen("scripts/ui_screens/StartupScreen")
        return
    end

    _G.levelI = _G.levelI + 1

    closeActiveScreen()
    _G.levelToLoad = "assets/levels/level".._G.levelI..".lvl"
    openScreen("scripts/ui_screens/LevelScreen")

end
currentEngine.onClick = nextLevel
