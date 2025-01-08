VERSIONMIGRATION_DEBUG = "0000000000"

local WATM = _G["WATM"]

WATM.CURRENT_DATA_FORMAT = "1.0.8"
WATM.FORCE_MIGRATION = false

function WATM:RunVersionMigration()
    local savedVersion = WATMCharacterSettings.version or "0.0"
    
    if savedVersion ~= WATM.CURRENT_DATA_FORMAT and not WATM.FORCE_MIGRATION then
        self:DebugPrint("Migration skipped. Saved version is already up-to-date: " .. savedVersion)
        VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 1) .. "1" .. VERSIONMIGRATION_DEBUG:sub(3)  -- Mark migration skip success
        return
    end

    self:DebugPrint("Starting migration from version " .. savedVersion .. " to " .. WATM.CURRENT_DATA_FORMAT .. "...")

    WATMProfiles = WATMProfiles or {}
    WATMCharacterSettings = WATMCharacterSettings or {}

    local DEFAULT_PROFILE = {
        ["withdrawState"] = true,
        ["depositState"] = true,
        ["debugState"] = false,
        ["goldTarget"] = 100000000, -- 10,000g
        ["profileName"] = "Default",
    }

    for profileName, profileData in pairs(WATMProfiles) do
        self:DebugPrint("Migrating profile: " .. profileName)

        profileData.withdrawGold = nil
        profileData.depositGold = nil
        profileData.targetGold = nil

        for key, defaultValue in pairs(DEFAULT_PROFILE) do
            if profileData[key] == nil then
                profileData[key] = defaultValue
                self:DebugPrint("Added missing key '" .. key .. "' to profile '" .. profileName .. "' with default value.")
            end
        end

        profileData.profileName = profileName
    end

    for characterKey, characterData in pairs(WATMCharacterSettings) do
        if characterData.debugMode ~= nil then
            characterData.debugMode = nil
            self:DebugPrint("Removed 'debugMode' from character settings for: " .. characterKey)
        end
    end

    WATMCharacterSettings.version = WATM.CURRENT_DATA_FORMAT
    WATM.FORCE_MIGRATION = false
    self:DebugPrint("Migration complete! Updated to version " .. WATM.CURRENT_DATA_FORMAT)

    VERSIONMIGRATION_DEBUG = VERSIONMIGRATION_DEBUG:sub(1, 2) .. "1" .. VERSIONMIGRATION_DEBUG:sub(4)  -- Mark migration success
end
