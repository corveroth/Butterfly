local addonName, Butterfly = ...;

-- Don't wait for Social for kill shot stuff, it stands alone.
Butterfly:InitializeKillShotElements()

local Watcher = CreateFrame("Frame")
Watcher:RegisterEvent("ADDON_LOADED")
Watcher:SetScript("OnEvent", function(self, event, addon, ...)
	if event == "ADDON_LOADED" and addon == "Blizzard_SocialUI" then
		Butterfly:ApplyTextHooks()
		
		Butterfly:InitializeFauxFrame()
		Butterfly:InitializeGalleryFrame()
		-- TODO
		-- Really, what do I want to do there?
		-- The Blizzard screenshot button is now redundant, but.
		-- Butterfly:InitializeSPFButtons()
	end
end)

_G["Butterfly"] = Butterfly
