function create(levelRestarter)
    listenToKey(levelRestarter, gameSettings.keyInput.retryLevel, "retry_key")
    local restartLevel = function()
        closeActiveScreen()
        openScreen("scripts/ui_screens/LevelScreen")
    end
    setUpdateFunction(levelRestarter, 0.1, function()
        if _G.queueRestartLevel then
            restartLevel()
            _G.queueRestartLevel = false
        end
    end)
    onEntityEvent(levelRestarter, "retry_key_pressed", restartLevel)

end
