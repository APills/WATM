local WATM = _G["WATM"]

SLASH_WATM1 = "/watm"

SlashCmdList["WATM"] = function(input)
    if input == "debug" then
        -- Toggle debug mode
        WATM.settings.debugState = not WATM.settings.debugState
        local characterKey = UnitName("player") .. "-" .. GetRealmName()
        WATMCharacterSettings[characterKey].debugState = WATM.settings.debugState

        -- Show or hide reset button based on debug mode
        WATM:CheckDebugMode()

        print("Debug Mode: " .. (WATM.settings.debugState and "Enabled" or "Disabled"))

        -- Print the debug string when entering debug mode
        if WATM.settings.debugState then
            print("Current Debug Output: " .. CORE_DEBUG .. PROFILES_DEBUG .. VERSIONMIGRATION_DEBUG)
        end
    elseif input == "107-8m" then
        print("Forcing migration of saved variables...")
        WATM.FORCE_MIGRATION = true
        WATM:RunVersionMigration()
    else
        -- Handle other inputs for config frame
        if not WATM.UIFrame then
            WATM:CreateConfigFrame()
        end
        WATM:UpdateUIWithProfile()
        WATM.UIFrame:Show()
    end
end
