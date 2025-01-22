VERSIONMIGRATION_DEBUG = "0000000000"

WATM.CURRENT_DATA_FORMAT = "1.0.9"
WATM.FORCE_MIGRATION = false

function WATM:RunVersionMigration()
    local savedVersion = WATMCharacterSettings.version or "0.0.0"

    if savedVersion == WATM.CURRENT_DATA_FORMAT and not WATM.FORCE_MIGRATION then
        self:DebugPrint("Migration skipped. Saved version is already up-to-date: " .. savedVersion)
        VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 1) .. "1" .. VERSIONMIGRATION_DEBUG:sub(3)
        return
    end

    print("Starting migration from version " .. savedVersion .. " to " .. WATM.CURRENT_DATA_FORMAT .. "...")
    VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 2) .. "1" .. VERSIONMIGRATION_DEBUG:sub(4)

    WATMProfiles = WATMProfiles or {}
    WATMCharacterSettings = WATMCharacterSettings or {}

    local DEFAULT_PROFILE = {
        ["withdrawState"] = true,
        ["depositState"] = true,
        ["debugState"] = false,
        ["goldTarget"] = 100000000,  -- 100,000g
        ["profileName"] = "Default",
    }

    for profileName, profileData in pairs(WATMProfiles) do
        print("Migrating profile: " .. profileName)

        profileData.withdrawGold = nil
        profileData.depositGold = nil
        profileData.targetGold = nil

        for key, defaultValue in pairs(DEFAULT_PROFILE) do
            if profileData[key] == nil then
                profileData[key] = defaultValue
                self:DebugPrint("Added missing key '" .. key .. "' to profile '" .. profileName .. "' with default value.")
                VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 3) .. "1" .. VERSIONMIGRATION_DEBUG:sub(4)
            end
        end

        profileData.profileName = profileName
    end

    for characterKey, characterData in pairs(WATMCharacterSettings) do
        if type(characterData) == "string" then
            characterData = {}
            WATMCharacterSettings[characterKey] = characterData
        end
        if characterData.debugMode ~= nil then
            characterData.debugMode = nil
            self:DebugPrint("Removed 'debugMode' from character settings for: " .. characterKey)
            VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 4) .. "1" .. VERSIONMIGRATION_DEBUG:sub(5)
        end
        if not characterData.version then
            characterData.version = WATM.CURRENT_DATA_FORMAT
            self:DebugPrint("Set version for character: " .. characterKey)
            VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 6) .. "1" .. VERSIONMIGRATION_DEBUG:sub(7)
        end
    end

    WATMCharacterSettings.version = WATM.CURRENT_DATA_FORMAT
    WATM.FORCE_MIGRATION = false
    print("Migration complete! Updated to data format " .. WATM.CURRENT_DATA_FORMAT)
    VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 5) .. "1" .. VERSIONMIGRATION_DEBUG:sub(6)
end
