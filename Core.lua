CORE_DEBUG = "0000000000"
local WATM = CreateFrame("Frame", "WarbankATM") 
local addonName = "WarbankATM"
local characterKey = UnitName("player") .. "-" .. GetRealmName()

WATM.CURRENT_VERSION = "1.0.8"

WATMProfiles = WATMProfiles or {}
WATMCharacterSettings = WATMCharacterSettings or {}

WATM.DEFAULT_PROFILE = {
    profileName = "Default",
    goldTarget = 100000000,
    depositState = true,
    withdrawState = true,
    debugState = false,
}

function WATM:DebugPrint(message)
    local currentProfileName = WATMCharacterSettings[characterKey] and WATMCharacterSettings[characterKey].currentProfile
    local currentProfile = WATMProfiles[currentProfileName]
    if currentProfile and currentProfile.debugState then
        print("|cff00FFFF[WATM|r |cffFF0000Debug|r|cff00FFFF]|r: " .. message)

    end
end

function WATM:InitAddon()
    CORE_DEBUG = CORE_DEBUG:sub(1, 1) .. "1" .. CORE_DEBUG:sub(3)
    self:RunVersionMigration()

    local characterKey = UnitName("player") .. "-" .. GetRealmName()
    WATMCharacterSettings[characterKey] = WATMCharacterSettings[characterKey] or { currentProfile = "Default" }
    WATMProfiles["Default"] = WATMProfiles["Default"] or CopyTable(self.DEFAULT_PROFILE)

    local currentProfileName = WATMCharacterSettings[characterKey].currentProfile
    WATMProfiles[currentProfileName] = WATMProfiles[currentProfileName] or CopyTable(self.DEFAULT_PROFILE)

    self.settings = WATMProfiles[currentProfileName]

    CORE_DEBUG = CORE_DEBUG:sub(1, 2) .. "1" .. CORE_DEBUG:sub(4)

    self:CheckDebugMode()

    CORE_DEBUG = CORE_DEBUG:sub(1, 3) .. "1" .. CORE_DEBUG:sub(5)
end

function WATM:CheckDebugMode()
    local currentProfileName = WATMCharacterSettings[characterKey].currentProfile
    local currentProfile = WATMProfiles[currentProfileName]
    if currentProfile.debugState then
        CORE_DEBUG = CORE_DEBUG:sub(1, 4) .. "1" .. CORE_DEBUG:sub(6)
    else
        CORE_DEBUG = CORE_DEBUG:sub(1, 4) .. "0" .. CORE_DEBUG:sub(6)
    end
end

function WATM:SaveSettings()
    local currentProfile = WATMCharacterSettings[characterKey].currentProfile
    if currentProfile and WATMProfiles[currentProfile] then
        WATMProfiles[currentProfile] = CopyTable(self.settings)
        self:DebugPrint("Settings saved for profile: " .. currentProfile)
        CORE_DEBUG = CORE_DEBUG:sub(1, 5) .. "1" .. CORE_DEBUG:sub(7)
    end
end

function WATM:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:InitAddon()
    elseif event == "PLAYER_LOGOUT" then
        self:SaveSettings()
    elseif event == "BANKFRAME_OPENED" then
        self:NormalizeGold()
    end
end

WATM:RegisterEvent("ADDON_LOADED")
WATM:RegisterEvent("PLAYER_LOGOUT")
WATM:RegisterEvent("BANKFRAME_OPENED")
WATM:SetScript("OnEvent", WATM.OnEvent)

function WATM:NormalizeGold()
    local bagGold = GetMoney()
    local targetGold = self.settings.goldTarget

    if self.settings.depositState and bagGold > targetGold then
        local excessGold = bagGold - targetGold
        C_Bank.DepositMoney(2, excessGold)
        print("|cff33ff99[WATM]|r Depositing " .. GetMoneyString(excessGold, true) .. " into the Warband Bank.")
        CORE_DEBUG = CORE_DEBUG:sub(1, 6) .. "1" .. CORE_DEBUG:sub(8)
    end

    if self.settings.withdrawState and bagGold < targetGold then
        local shortageGold = targetGold - bagGold
        C_Bank.WithdrawMoney(2, shortageGold)
        print("|cff33ff99[WATM]|r Withdrawing " .. GetMoneyString(shortageGold, true) .. " from the Warband Bank.")
        CORE_DEBUG = CORE_DEBUG:sub(1, 7) .. "1" .. CORE_DEBUG:sub(9)
    end
end


_G["WATM"] = WATM
