local WATM = CreateFrame("Frame")
local characterKey = UnitName("player") .. "-" .. GetRealmName()

WATMProfiles = WATMProfiles or {}
WATMCharacterSettings = WATMCharacterSettings or {}
WATMCharacterSettings[characterKey] = WATMCharacterSettings[characterKey] or {currentProfile = "Default"}

local DEFAULT_PROFILE = {
    depositGold = true,
    withdrawGold = true,
    targetGold = 100000000, -- 10,000g
}

local debugMode = WATMCharacterSettings[characterKey].debugMode or false

local function debugPrint(message)
    if debugMode then
        print("|cff33ff99[WATM Debug]:|r " .. message)
    else
        print(message)
    end
end

function WATM:LoadProfile(profileName)
    if WATMProfiles[profileName] then
        WATMCharacterSettings[characterKey].currentProfile = profileName
        WATMSettings = WATMProfiles[profileName]
        WATM:UpdateUIWithProfile()
        debugPrint("Profile '" .. profileName .. "' loaded.")
    else
        debugPrint("Profile '" .. profileName .. "' does not exist.")
    end
end

function WATM:InitProfiles()
    WATMCharacterSettings[characterKey] = WATMCharacterSettings[characterKey] or {}
    local currentProfile = WATMCharacterSettings[characterKey].currentProfile or "Default"
    WATMProfiles[currentProfile] = WATMProfiles[currentProfile] or CopyTable(DEFAULT_PROFILE)
    WATMSettings = WATMProfiles[currentProfile]
end

function WATM:UpdateUIWithProfile()
    local profile = WATMProfiles[WATMCharacterSettings[characterKey].currentProfile] or DEFAULT_PROFILE
    WATM.goldInput:SetText(math.floor(profile.targetGold / 10000))
    WATM.silverInput:SetText(math.floor((profile.targetGold % 10000) / 100))
    WATM.copperInput:SetText(profile.targetGold % 100)
    WATM.depositGoldCheckbox:SetChecked(profile.depositGold)
    WATM.withdrawGoldCheckbox:SetChecked(profile.withdrawGold)
end

function WATM:DeleteProfile(profileName)
    if profileName == "Default" then
        debugPrint("Cannot delete the Default profile.")
        return
    end
    WATMProfiles[profileName] = nil
    if WATMCharacterSettings[characterKey].currentProfile == profileName then
        WATM:LoadProfile("Default")
    end
end

function WATM:InitSettings()
    local currentProfile = WATMCharacterSettings[characterKey].currentProfile
    WATMSettings = WATMProfiles[currentProfile] or CopyTable(DEFAULT_PROFILE)

    WATMSettings.depositGold = WATMSettings.depositGold or DEFAULT_PROFILE.depositGold
    WATMSettings.withdrawGold = WATMSettings.withdrawGold or DEFAULT_PROFILE.withdrawGold
    WATMSettings.targetGold = WATMSettings.targetGold or DEFAULT_PROFILE.targetGold
end

function WATM:NormalizeGold()
    local bag = GetMoney()
    local bank = C_Bank.FetchDepositedMoney(2)
    local target = WATMSettings.targetGold

    if WATMSettings.depositGold and bag > target then
        local excess = bag - target
        debugPrint("Depositing " .. GetMoneyString(excess, true) .. " into the Warband Bank.")
        C_Bank.DepositMoney(2, excess)
    elseif WATMSettings.withdrawGold and bag < target then
        local shortage = math.min(target - bag, bank)
        debugPrint("Withdrawing " .. GetMoneyString(shortage, true) .. " from the Warband Bank.")
        C_Bank.WithdrawMoney(2, shortage)
    end
end

function WATM:CreateProfile(profileName)
    if WATMProfiles[profileName] then
        debugPrint("Profile '" .. profileName .. "' already exists.")
        return
    end
    WATMProfiles[profileName] = CopyTable(DEFAULT_PROFILE)
    WATMCharacterSettings[characterKey].currentProfile = profileName
    WATM:UpdateUIWithProfile()
end

function WATM:GetProfileNames()
    local profileNames = {}
    for profileName in pairs(WATMProfiles) do
        table.insert(profileNames, profileName)
    end
    return profileNames
end

function WATM:UpdateTargetGold(gold, silver, copper)
    local totalCopper = (gold * 10000) + (silver * 100) + copper
    WATMSettings.targetGold = math.min(totalCopper, 99999999999)

    local currentProfile = WATMCharacterSettings[characterKey].currentProfile
    WATMProfiles[currentProfile] = {
        depositGold = WATMSettings.depositGold,
        withdrawGold = WATMSettings.withdrawGold,
        targetGold = WATMSettings.targetGold,
    }
end

function WATM:CreateConfigFrame()
    local frame = CreateFrame("Frame", "WATMConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 400)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    table.insert(UISpecialFrames, "WATMConfigFrame")

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 5, 0)
    frame.title:SetText("WATM Config")

    -- Create Section: Select Profile
    local function createSectionHeader(parent, text, offsetY)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        header:SetPoint("TOPLEFT", 20, offsetY)
        header:SetText(text)
        return header
    end

    createSectionHeader(frame, "Select Profile", -40)

    -- Dropdown for profile selection
    local profileDropdown = CreateFrame("Frame", "WATMProfileDropdown", frame, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", 20, -60)

    UIDropDownMenu_SetWidth(profileDropdown, 150)
    UIDropDownMenu_SetText(profileDropdown, "Select Profile")

    -- Populate the dropdown with saved profiles
    UIDropDownMenu_Initialize(profileDropdown, function(self, level, menuList)
        local profiles = WATM:GetProfileNames()
        for _, profileName in ipairs(profiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = profileName
            info.func = function()
                UIDropDownMenu_SetSelectedName(profileDropdown, profileName)
                WATM:LoadProfile(profileName)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
-- Create Section: Create New Profile
createSectionHeader(frame, "Create New Profile", -100)

-- Input box for profile name
local newProfileInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
newProfileInput:SetSize(150, 30)
newProfileInput:SetPoint("TOPLEFT", 45, -120)
newProfileInput:SetAutoFocus(false)
newProfileInput:SetMaxLetters(20)
newProfileInput:SetText("")

-- Button to create new profile
local createProfileButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
createProfileButton:SetSize(140, 30)
createProfileButton:SetPoint("LEFT", newProfileInput, "RIGHT", 35, 0)
createProfileButton:SetText("Create Profile")
createProfileButton:SetNormalFontObject("GameFontNormalLarge")
createProfileButton:SetHighlightFontObject("GameFontHighlightLarge")
createProfileButton:SetScript("OnClick", function()
    local profileName = newProfileInput:GetText()

    if profileName and profileName ~= "" then
        WATM:CreateProfile(profileName)
    else
        debugPrint("Please enter a valid profile name.")
    end
end)

    createSectionHeader(frame, "Delete Profile", -160)

    local deleteProfileDropdown = CreateFrame("Frame", "WATMDeleteProfileDropdown", frame, "UIDropDownMenuTemplate")
    deleteProfileDropdown:SetPoint("TOPLEFT", 20, -180)

    UIDropDownMenu_SetWidth(deleteProfileDropdown, 150)
    UIDropDownMenu_SetText(deleteProfileDropdown, "Select Profile")

    UIDropDownMenu_Initialize(deleteProfileDropdown, function(self, level, menuList)
        local profiles = WATM:GetProfileNames()
        for _, profileName in ipairs(profiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = profileName
            info.func = function()
                UIDropDownMenu_SetSelectedName(deleteProfileDropdown, profileName)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local deleteProfileButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    deleteProfileButton:SetSize(140, 30)
    deleteProfileButton:SetPoint("LEFT", deleteProfileDropdown, "RIGHT", 10, 0)
    deleteProfileButton:SetText("Delete Profile")
    deleteProfileButton:SetNormalFontObject("GameFontNormalLarge")
    deleteProfileButton:SetHighlightFontObject("GameFontHighlightLarge")
    deleteProfileButton:SetScript("OnClick", function()
        local selectedProfile = UIDropDownMenu_GetSelectedName(deleteProfileDropdown)
        if selectedProfile then
            if selectedProfile == "Default" then
                debugPrint("Cannot delete the Default profile.")
                return
            end
            WATM:DeleteProfile(selectedProfile)
            UIDropDownMenu_Refresh(WATMProfileDropdown)
            UIDropDownMenu_Refresh(WATMDeleteProfileDropdown)
        else
            debugPrint("Please select a profile to delete.")
        end
    end)

    createSectionHeader(frame, "Gold Target", -220)

    WATM.goldInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    WATM.goldInput:SetSize(60, 30)
    WATM.goldInput:SetPoint("TOPLEFT", 20, -250)
    WATM.goldInput:SetAutoFocus(false)
    WATM.goldInput:SetMaxLetters(7)
    WATM.goldInput:SetNumeric(true)
    WATM.goldInput:SetText(math.floor(WATMSettings.targetGold / 10000))

    local goldLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    goldLabel:SetPoint("LEFT", WATM.goldInput, "RIGHT", 10, 0)
    goldLabel:SetText("Gold")

    WATM.silverInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    WATM.silverInput:SetSize(40, 30)
    WATM.silverInput:SetPoint("LEFT", goldLabel, "RIGHT", 20, 0)
    WATM.silverInput:SetAutoFocus(false)
    WATM.silverInput:SetMaxLetters(2)
    WATM.silverInput:SetNumeric(true)
    WATM.silverInput:SetText(math.floor((WATMSettings.targetGold % 10000) / 100))

    local silverLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    silverLabel:SetPoint("LEFT", WATM.silverInput, "RIGHT", 10, 0)
    silverLabel:SetText("Silver")

    WATM.copperInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    WATM.copperInput:SetSize(40, 30)
    WATM.copperInput:SetPoint("LEFT", silverLabel, "RIGHT", 20, 0)
    WATM.copperInput:SetAutoFocus(false)
    WATM.copperInput:SetMaxLetters(2)
    WATM.copperInput:SetNumeric(true)
    WATM.copperInput:SetText(WATMSettings.targetGold % 100)

    local copperLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    copperLabel:SetPoint("LEFT", WATM.copperInput, "RIGHT", 10, 0)
    copperLabel:SetText("Copper")

    local function updateTarget()
        local gold = tonumber(WATM.goldInput:GetText()) or 0
        local silver = tonumber(WATM.silverInput:GetText()) or 0
        local copper = tonumber(WATM.copperInput:GetText()) or 0
        WATM:UpdateTargetGold(gold, silver, copper)
    end

    WATM.goldInput:SetScript("OnEditFocusLost", updateTarget)
    WATM.silverInput:SetScript("OnEditFocusLost", updateTarget)
    WATM.copperInput:SetScript("OnEditFocusLost", updateTarget)

    WATM.goldInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        updateTarget()
    end)
    WATM.silverInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        updateTarget()
    end)
    WATM.copperInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        updateTarget()
    end)

    WATM.depositGoldCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    WATM.depositGoldCheckbox:SetPoint("TOPLEFT", 20, -300)
    WATM.depositGoldCheckbox.text:SetText("Auto Deposit Gold")
    WATM.depositGoldCheckbox:SetChecked(WATMSettings.depositGold)
    WATM.depositGoldCheckbox:SetScript("OnClick", function(self)
        WATMSettings.depositGold = self:GetChecked()
        local currentProfile = WATMCharacterSettings[characterKey].currentProfile
        WATMProfiles[currentProfile].depositGold = WATMSettings.depositGold
    end)

    WATM.withdrawGoldCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    WATM.withdrawGoldCheckbox:SetPoint("TOPLEFT", 20, -330)
    WATM.withdrawGoldCheckbox.text:SetText("Auto Withdraw Gold")
    WATM.withdrawGoldCheckbox:SetChecked(WATMSettings.withdrawGold)
    WATM.withdrawGoldCheckbox:SetScript("OnClick", function(self)
        WATMSettings.withdrawGold = self:GetChecked()
        local currentProfile = WATMCharacterSettings[characterKey].currentProfile
        WATMProfiles[currentProfile].withdrawGold = WATMSettings.withdrawGold
    end)

    local resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    resetButton:SetSize(150, 30)
    resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    resetButton:SetText("Reset Settings")
    resetButton:SetNormalFontObject("GameFontNormalLarge")
    resetButton:SetHighlightFontObject("GameFontHighlightLarge")
    resetButton:Hide()
    resetButton:SetScript("OnClick", function()
        WATMProfiles = {}
        WATMCharacterSettings = {}
        WATM:LoadProfile("Default")
        debugPrint("Profiles reset and default loaded.")
    end)

    WATM.resetButton = resetButton
    WATM.UIFrame = frame
end

SLASH_WATM1 = "/watm"
SlashCmdList["WATM"] = function(input)
    if input == "debug" then
        debugMode = not debugMode
        WATMCharacterSettings[characterKey].debugMode = debugMode
        WATM.resetButton:SetShown(debugMode)
    else
        if not WATM.UIFrame then
            WATM:CreateConfigFrame()
        end
        WATM:UpdateUIWithProfile()
        WATM.UIFrame:Show()
    end
end

WATM:RegisterEvent("ADDON_LOADED")
WATM:RegisterEvent("BANKFRAME_OPENED")
WATM:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" and addon == "WarbankATM" then
        WATM:InitProfiles()
        WATM:InitSettings()
    elseif event == "BANKFRAME_OPENED" then
        WATM:NormalizeGold()
    end
end)
