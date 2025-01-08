-- UI.lua

function WATM:UpdateUIWithProfile()
    -- Ensure the UIFrame is initialized
    if not self.UIFrame then
        print("Error: UIFrame not initialized.")
        return
    end

    -- Ensure settings are initialized
    if not self.settings then
        print("Error: Settings for the current profile are not initialized.")
        return
    end

    -- Check if depositCheckbox is initialized
    if not self.UIFrame.depositCheckbox then
        print("Error: depositCheckbox not initialized.")
        return
    end

    -- Update the gold, silver, and copper inputs
    local gold = math.floor(self.settings.goldTarget / 10000)
    local silver = math.floor((self.settings.goldTarget % 10000) / 100)
    local copper = self.settings.goldTarget % 100

    -- Update input fields
    self.UIFrame.goldInput:SetText(gold)
    self.UIFrame.silverInput:SetText(silver)
    self.UIFrame.copperInput:SetText(copper)

    -- Update checkbox states
    self.UIFrame.depositCheckbox:SetChecked(self.settings.depositState)
    self.UIFrame.withdrawCheckbox:SetChecked(self.settings.withdrawState)

    -- If debug mode is enabled, show reset button
    if self.settings.debugState then
        self.UIFrame.resetButton:Show()
    else
        self.UIFrame.resetButton:Hide()
    end
end

function WATM:CreateConfigFrame()
    -- Main frame
    local frame = CreateFrame("Frame", "WATMConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 400)  -- Adjust height for compact layout
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
    frame.title:SetText("WarbankATM Config")

    -- Create Reset Button
    local resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    resetButton:SetSize(120, 30)
    resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    resetButton:SetText("Reset Settings")
    resetButton:SetNormalFontObject("GameFontNormalLarge")
    resetButton:SetHighlightFontObject("GameFontHighlightLarge")
    resetButton:SetScript("OnClick", function()
        WATMProfiles = {}
        WATMCharacterSettings = {}
        WATM:InitAddon()
        WATM:UpdateUIWithProfile()
        print("Settings reset to default.")
    end)
    resetButton:Hide()  -- Hide reset button initially

    -- Save the button reference
    frame.resetButton = resetButton

    -- Section: Profile Selection
    local function createSectionHeader(parent, text, offsetY)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
        header:SetPoint("TOPLEFT", 20, offsetY)
        header:SetText(text)
        return header
    end

    createSectionHeader(frame, "Select Profile", -30)

    -- Dropdown for profile selection
    local profileDropdown = CreateFrame("Frame", "WATMProfileDropdown", frame, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", 20, -60)
    UIDropDownMenu_SetWidth(profileDropdown, 180)

    -- Initialize the dropdown
    UIDropDownMenu_Initialize(profileDropdown, function(self, level, menuList)
        local profiles = WATM:GetProfileNames()
        for _, profileName in ipairs(profiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = profileName
            info.func = function()
                UIDropDownMenu_SetSelectedName(profileDropdown, profileName)
                WATM:SwitchProfile(profileName)
                WATM:UpdateUIWithProfile()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set the dropdown to the currently selected profile
    local characterKey = UnitName("player") .. "-" .. GetRealmName()
    local currentProfileName = WATMCharacterSettings[characterKey] and WATMCharacterSettings[characterKey].currentProfile or "Default"
    UIDropDownMenu_SetText(profileDropdown, currentProfileName)

    -- Create New Profile Section
    createSectionHeader(frame, "Create New Profile", -110)

    local profileInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    profileInput:SetSize(140, 30)
    profileInput:SetPoint("TOPLEFT", 20, -140)
    profileInput:SetAutoFocus(false)
    profileInput:SetMaxLetters(20)

    -- Create profile button
    local createProfileButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    createProfileButton:SetSize(120, 30)
    createProfileButton:SetPoint("LEFT", profileInput, "RIGHT", 10, 0)
    createProfileButton:SetText("Create Profile")
    createProfileButton:SetNormalFontObject("GameFontNormalLarge")
    createProfileButton:SetHighlightFontObject("GameFontHighlightLarge")
    createProfileButton:SetScript("OnClick", function()
        local profileName = profileInput:GetText()
        if not profileName or profileName == "" then
            print("Error: Please enter a valid profile name.")
            return
        end

        if WATMProfiles[profileName] then
            print("Error: Profile '" .. profileName .. "' already exists.")
            return
        end

        WATM:CreateProfile(profileName)
        UIDropDownMenu_Initialize(profileDropdown)
        WATM:UpdateUIWithProfile()
    end)

    -- Delete Profile Section
    createSectionHeader(frame, "Delete Profile", -170)

    local deleteProfileDropdown = CreateFrame("Frame", "WATMDeleteProfileDropdown", frame, "UIDropDownMenuTemplate")
    deleteProfileDropdown:SetPoint("TOPLEFT", 20, -200)
    UIDropDownMenu_SetWidth(deleteProfileDropdown, 180)

    UIDropDownMenu_Initialize(deleteProfileDropdown, function(self, level, menuList)
        local profiles = WATM:GetProfileNames()
        for _, profileName in ipairs(profiles) do
            if profileName ~= "Default" then
                local info = UIDropDownMenu_CreateInfo()
                info.text = profileName
                info.func = function()
                    UIDropDownMenu_SetSelectedName(deleteProfileDropdown, profileName)
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    end)

    -- Delete profile button
    local deleteProfileButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    deleteProfileButton:SetSize(120, 30)
    deleteProfileButton:SetPoint("LEFT", deleteProfileDropdown, "RIGHT", 10, 0)
    deleteProfileButton:SetText("Delete Profile")
    deleteProfileButton:SetNormalFontObject("GameFontNormalLarge")
    deleteProfileButton:SetHighlightFontObject("GameFontHighlightLarge")
    deleteProfileButton:SetScript("OnClick", function()
        local selectedProfile = UIDropDownMenu_GetText(deleteProfileDropdown)
        if not selectedProfile or selectedProfile == "" then
            print("Error: Please select a profile to delete.")
            return
        end

        WATM:DeleteProfile(selectedProfile)
        UIDropDownMenu_Initialize(profileDropdown)
        UIDropDownMenu_Initialize(deleteProfileDropdown)
        local newProfile = WATMCharacterSettings[characterKey].currentProfile or "Default"
        UIDropDownMenu_SetText(profileDropdown, newProfile)
        UIDropDownMenu_SetText(deleteProfileDropdown, "")
    end)

    -- Gold Target Section
    createSectionHeader(frame, "Gold Target", -250)

    local goldInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    goldInput:SetSize(60, 30)
    goldInput:SetPoint("TOPLEFT", 20, -280)
    goldInput:SetAutoFocus(false)
    goldInput:SetMaxLetters(7)
    goldInput:SetNumeric(true)
    goldInput:SetText(math.floor(WATM.settings.goldTarget / 10000) or 0)

    local silverInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    silverInput:SetSize(40, 30)
    silverInput:SetPoint("LEFT", goldInput, "RIGHT", 10, 0)
    silverInput:SetAutoFocus(false)
    silverInput:SetMaxLetters(2)
    silverInput:SetNumeric(true)
    silverInput:SetText(math.floor((WATM.settings.goldTarget % 10000) / 100) or 0)

    local copperInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    copperInput:SetSize(40, 30)
    copperInput:SetPoint("LEFT", silverInput, "RIGHT", 10, 0)
    copperInput:SetAutoFocus(false)
    copperInput:SetMaxLetters(2)
    copperInput:SetNumeric(true)
    copperInput:SetText(WATM.settings.goldTarget % 100 or 0)

    -- Update target gold when inputs change
    local function updateGoldTarget()
        local gold = tonumber(goldInput:GetText()) or 0
        local silver = tonumber(silverInput:GetText()) or 0
        local copper = tonumber(copperInput:GetText()) or 0
        WATM.settings.goldTarget = math.min((gold * 10000) + (silver * 100) + copper, 99999999999)
    end

    goldInput:SetScript("OnEditFocusLost", updateGoldTarget)
    silverInput:SetScript("OnEditFocusLost", updateGoldTarget)
    copperInput:SetScript("OnEditFocusLost", updateGoldTarget)

    -- Save the references to the input fields
    frame.goldInput = goldInput
    frame.silverInput = silverInput
    frame.copperInput = copperInput

    -- Checkboxes Section
    local depositCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    depositCheckbox:SetPoint("TOPLEFT", 20, -310)
    depositCheckbox.text:SetText("Auto Deposit Gold")
    depositCheckbox:SetChecked(WATM.settings.depositState)
    depositCheckbox:SetScript("OnClick", function(self)
        WATM.settings.depositState = self:GetChecked()
    end)

    local withdrawCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    withdrawCheckbox:SetPoint("TOPLEFT", 20, -340)
    withdrawCheckbox.text:SetText("Auto Withdraw Gold")
    withdrawCheckbox:SetChecked(WATM.settings.withdrawState)
    withdrawCheckbox:SetScript("OnClick", function(self)
        WATM.settings.withdrawState = self:GetChecked()
    end)

    -- Reset Button Section (only shown if debug mode is enabled)
    local resetButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    resetButton:SetSize(120, 30)
    resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    resetButton:SetText("Reset Settings")
    resetButton:SetNormalFontObject("GameFontNormalLarge")
    resetButton:SetHighlightFontObject("GameFontHighlightLarge")
    resetButton:SetScript("OnClick", function()
        WATMProfiles = {}
        WATMCharacterSettings = {}
        WATM:InitAddon()
        WATM:UpdateUIWithProfile()
        print("Settings reset to default.")
    end)
    -- Initially hide reset button
    resetButton:Hide()

    -- Save the button reference
    frame.resetButton = resetButton

    -- Save UI elements to the frame for reference
    frame.depositCheckbox = depositCheckbox
    frame.withdrawCheckbox = withdrawCheckbox

    -- Save the frame reference
    WATM.UIFrame = frame

    -- Call CheckDebugMode to ensure the resetButton is shown or hidden based on debug mode
    WATM:CheckDebugMode()
end
