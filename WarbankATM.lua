-- Register event for when the player enters the game
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    print("Warbank ATM is loaded.")
end)
