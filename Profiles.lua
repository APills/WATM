PROFILES_DEBUG = "0000000000"

function WATM:GetProfileNames()
    if not WATMProfiles then
        self:DebugPrint("Error: WATMProfiles is nil!")
        return {}
    end

    local profileNames = {}
    for profileName in pairs(WATMProfiles) do
        table.insert(profileNames, profileName)
    end
    table.sort(profileNames)
    PROFILES_DEBUG = PROFILES_DEBUG:sub(1, 1) .. "1" .. PROFILES_DEBUG:sub(3)
    return profileNames
end

function WATM:CreateProfile(profileName)
    self:DebugPrint("CreateProfile called for: " .. profileName)

    if not profileName or profileName == "" then
        print("Error: Profile name cannot be empty.")
        return
    end

    WATMProfiles = WATMProfiles or {}

    if WATMProfiles[profileName] then
        print("Error: Profile '" .. profileName .. "' already exists.")
        return
    end

    WATMProfiles[profileName] = CopyTable(self.DEFAULT_PROFILE)
    WATMProfiles[profileName].profileName = profileName
    print("Profile '" .. profileName .. "' created successfully.")

    self:SwitchProfile(profileName)
    PROFILES_DEBUG = PROFILES_DEBUG:sub(1, 2) .. "1" .. PROFILES_DEBUG:sub(4)
end

function WATM:SwitchProfile(profileName)
    self:DebugPrint("SwitchProfile called for: " .. (profileName or "nil"))

    if not profileName or profileName == "" then
        print("Error: Profile name cannot be empty.")
        return
    end

    WATMProfiles = WATMProfiles or {}

    if not WATMProfiles[profileName] then
        sprint("Error: Profile '" .. profileName .. "' does not exist.")
        return
    end

    local characterKey = UnitName("player") .. "-" .. GetRealmName()
    WATMCharacterSettings[characterKey] = WATMCharacterSettings[characterKey] or {}

    WATMCharacterSettings[characterKey].currentProfile = profileName
    self.settings = WATMProfiles[profileName]

    if WATM.UIFrame and WATM.UIFrame.profileDropdown then
        UIDropDownMenu_SetText(WATM.UIFrame.profileDropdown, profileName)
    end

    print("Switched to profile: " .. profileName)
    PROFILES_DEBUG = PROFILES_DEBUG:sub(1, 3) .. "1" .. PROFILES_DEBUG:sub(5)
end

function WATM:DeleteProfile(profileName)
    if not profileName or profileName == "" then
        print("Error: Profile name cannot be empty.")
        return
    end

    WATMProfiles = WATMProfiles or {}

    if profileName == "Default" then
        print("Error: Cannot delete the 'Default' profile.")
        return
    end

    if not WATMProfiles[profileName] then
        print("Error: Profile '" .. profileName .. "' does not exist.")
        return
    end

    WATMProfiles[profileName] = nil
    print("Profile '" .. profileName .. "' deleted.")

    local characterKey = UnitName("player") .. "-" .. GetRealmName()
    if WATMCharacterSettings[characterKey].currentProfile == profileName then
        self:SwitchProfile("Default")
        print("Switched to 'Default' profile after deletion.")
    end
    PROFILES_DEBUG = PROFILES_DEBUG:sub(1, 4) .. "1" .. PROFILES_DEBUG:sub(6)
end
