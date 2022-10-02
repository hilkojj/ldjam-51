
_G.titleScreen = true
startupArgs = getGameStartupArgs()

saveGamePath = startupArgs["--single-player"] or "saves/default_save.dibdab"
startSinglePlayerSession(saveGamePath)

username = startupArgs["--username"] or "poopoo"
joinSession(username, function(declineReason)

    tryCloseGame()
    error("couldn't join session: "..declineReason)
end)

onEvent("BeforeDelete", function()
    print("startup screen done..")
end)

loadOrCreateLevel("assets/levels/title_screen.lvl")

function startLevel()
    closeActiveScreen()
    _G.levelToLoad = startupArgs["--level"] or "assets/levels/default_level.lvl"
    openScreen("scripts/ui_screens/LevelScreen")
end
currentEngine.onClick = startLevel

