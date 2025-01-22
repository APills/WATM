local WATM = _G["WATM"]

SLASH_WATM1 = "/watm"

SlashCmdList["WATM"] = function(input)
    if input == "debug" then
        WATM.settings.debugState = not WATM.settings.debugState
        local characterKey = UnitName("player") .. "-" .. GetRealmName()
        WATMCharacterSettings[characterKey].debugState = WATM.settings.debugState

        WATM:CheckDebugMode()

        print("Debug Mode: " .. (WATM.settings.debugState and "Enabled" or "Disabled"))

        if WATM.settings.debugState then
            print("Current Debug Output: " .. CORE_DEBUG .. PROFILES_DEBUG .. VERSIONMIGRATION_DEBUG)
        end
    elseif input == "107m" then
        print("Forcing migration of saved variables...")
        WATM.FORCE_MIGRATION = true
        WATM:RunVersionMigration()
    else
        if not WATM.UIFrame then
            WATM:CreateConfigFrame()
        end
        WATM:UpdateUIWithProfile()
        WATM.UIFrame:Show()
    end
end
