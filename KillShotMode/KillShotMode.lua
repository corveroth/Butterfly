local addonName, Butterfly = ...;
--[[============
	The KillShotElements frame is a container parented to the WorldFrame, so that it remains visible
	when the interface is hidden. It contains a set of visual elements describing the last raid boss kill
	*this session*. There is no need to persist that data between sessions, because the SocialUI does not
	support retrieving screenshots from prior sessions. However, we do use SavedVariables to manage that
	data, because of the possibility that it would otherwise be lost to an interface reload.
	
	Kill shot elements are currently:
		The combined difficulty and encounter name
		The player's guild name
		The player's guild crest
		The date
	The contents of these elements are *not* editable by the player.
	Scale, position, and font can be edited via the Mover attached to each element.
	
	A prompt will be shown in the chat window when an encounter is successfully completed.
	Additionally, previous screenshots can be converted to kill shots via a fullscreen editing interface.
	When a previous screenshot is edited this way, the elements will be given the values for the most
	recently cleared encounter prior to that screenshot.
--============]]

-- why you do this blizz
local UI_FONTSIZE_MAX = 36
local function GetScaledMaxFontSize()
	return UI_FONTSIZE_MAX*UIParent:GetScale()
end

-- SavedVariables
KillShotSV = {}

-- DEBUGGY SHIT
-- DEBUGGY SHIT
SLASH_KILLSHOTMODE1 = "/ks"
SlashCmdList["KILLSHOTMODE"] = function()
	-- print("ksm")
	if Butterfly.KillShotElements:IsShown() then
		Butterfly:ExitKillShotMode()
	else
		Butterfly.KillShotElements:EncounterSuccess("Dummy Boss", 16)
		Butterfly.KillShotElements:EncounterSuccess("Dummy2 Boss", 16)
		Butterfly.KillShotElements:EncounterSuccess("Dummy3 Boss", 16)
		Butterfly.KillShotElements:SetToEventIndex(Butterfly.KillShotElements:GetLastEventIndex("kill"))
		Butterfly:EnterKillShotMode()
	end
end
-- DEBUGGY SHIT
-- DEBUGGY SHIT

local BOSS_DOWN_TEXT = "%s%s down!"
local KILL_SHOT_PROMPT = "|cff71d5ff|HButterfly:%d|h[Take a kill shot]|h|r"
local DIFFICULTY_TEXT = {
	"", -- Normal
	PLAYER_DIFFICULTY2 .. " ",
	PLAYER_DIFFICULTY6 .. " ",
	}
	
-- Parent to WorldFrame so we can easily hide everything else.
-- This *does* mean we want to manually scale it though.
local KillShotElements = CreateFrame("Frame", "ButterflyKillShotElements", WorldFrame)
KillShotElements:SetAllPoints()
KillShotElements:Hide()
KillShotElements.elements = {}
Butterfly.KillShotElements = KillShotElements
do
	-- Finds the largest font size that keeps a string smaller than the widget's size
	local function ResizeFontString(widget, targetWidth, targetHeight)
		local widgetWidth = widget:GetStringWidth()
		assert(widgetWidth and widgetWidth ~= 0)
		assert(targetWidth and targetWidth ~= 0)
		local filename, fontHeight, flags = widget:GetFont()
		
		-- If we can, prefer to scale based on the point size
		if fontHeight+1 < GetScaledMaxFontSize() then
			if widgetWidth < targetWidth then
				while widgetWidth < targetWidth do
					fontHeight = fontHeight + 1
					widget:SetFont(filename, fontHeight, flags)
					widgetWidth = widget:GetStringWidth()
					
				end
				-- Overshot the size, shrink it back down by one
				widget:SetFont(filename, fontHeight - 1, flags)
			else
				while widgetWidth > targetWidth do
					fontHeight = fontHeight - 1
					widget:SetFont(filename, fontHeight, flags)
					widgetWidth = widget:GetStringWidth()
				end
			end
		else
		-- However, if we need to scale beyond 36pt, use SetTextHeight.
		-- Sucks , but that's what Blizz forces us to do.
			if widgetWidth < targetWidth then
				while widgetWidth < targetWidth do
					fontHeight = fontHeight + 1
					widget:SetTextHeight(fontHeight)
					widgetWidth = widget:GetStringWidth()
				end
				-- Overshot the size, shrink it back down by one
				widget:SetFont(filename, fontHeight - 1, flags)
			else
				while widgetWidth > targetWidth do
					fontHeight = fontHeight - 1
					widget:SetTextHeight(fontHeight)
					widgetWidth = widget:GetStringWidth()
				end
			end
		end
	end
	
	
	local BossDownText = KillShotElements:CreateFontString()
	BossDownText:SetFontObject("GameFontNormal")
	BossDownText:SetPoint("CENTER", 0, 200)
	function BossDownText:Update(bossDownString)
		self:SetText(bossDownString)
	end
	function BossDownText:Resize(newWidth, newHeight)
		ResizeFontString(self, newWidth)
	end
	table.insert(KillShotElements.elements, BossDownText)
	KillShotElements.BossDownText = BossDownText
	
	
	local GuildNameText = KillShotElements:CreateFontString()
	GuildNameText:SetFontObject("GameFontNormal")
	GuildNameText:SetPoint("CENTER", 0, -200)
	function GuildNameText:Update(guildNameText)
		self:SetText(guildNameText)
	end
	function GuildNameText:Resize(newWidth, newHeight)
		ResizeFontString(self, newWidth)
	end
	table.insert(KillShotElements.elements, GuildNameText)
	KillShotElements.GuildNameText = GuildNameText
	
	
	local DateText = KillShotElements:CreateFontString()
	DateText:SetFontObject("GameFontNormal")
	DateText:SetPoint("CENTER", 0, -250)
	function DateText:Update(dateString)
		self:SetText(dateString)
	end
	function DateText:Resize(newWidth, newHeight)
		ResizeFontString(self, newWidth)
	end
	table.insert(KillShotElements.elements, DateText)
	KillShotElements.DateText = DateText
	
	
	-- 48638, just in case
	local GuildCrest = CreateFrame("Frame", KillShotElements)
	function GuildCrest:Update()
		-- TabardModel:GetUpperEmblemTexture(TabardFrameEmblemTopLeft);
		-- TabardModel:GetUpperEmblemTexture(TabardFrameEmblemTopRight);
		-- TabardModel:GetLowerEmblemTexture(TabardFrameEmblemBottomLeft);
		-- TabardModel:GetLowerEmblemTexture(TabardFrameEmblemBottomRight);
	end
	function GuildCrest:Resize(newWidth, newHeight)
		self:SetSize(newWidth, newHeight)
	end
end

function KillShotElements:CreateMovers()
	for _, element in pairs(self.elements) do
		if not element.mover then
			Butterfly.Mover:NewMover(element, KillShotElements)
		end
	end
end

--[[============
	We've got a few insecure prehooks to do.
	
	PREHOOK_TakeScreenshot
		So that we can :Hide etc on Movers before the screenshot is taken
	PREHOOK_ItemRefTooltipSetHyperlink
		To parse our custom hyperlinks
	PREHOOK_ReloadFunctions
		To write a SavedVar on reload *only* to distinguish from a fresh load
--============]]
local function PREHOOK_TakeScreenshot()
	local Blizz_TakeScreenshot = TakeScreenshot
	TakeScreenshot = function()
		Butterfly:LockOrDisableMovers()
		Blizz_TakeScreenshot()
	end
end

local function PREHOOK_ItemRefTooltipSetHyperlink()
	local Blizz_SetHyperlink = ItemRefTooltip.SetHyperlink;
	function ItemRefTooltip:SetHyperlink(link)
		if link:find("^Butterfly") then
			local eventIndex = tonumber(link:match("^Butterfly:(%d+)$"))
			Butterfly.KillShotElements:SetToEventIndex(eventIndex)
			Butterfly:EnterKillShotMode()
		else
			Blizz_SetHyperlink(self, link)
		end
	end
end

local function PREHOOK_ReloadFunctions()
	local Blizz_ReloadUI = ReloadUI
	function ReloadUI()
		KillShotElements:SaveEventLog()
		Blizz_ReloadUI()
	end

	local Blizz_ConsoleExec = ConsoleExec
	function ConsoleExec(msg)
		if msg:lower() == "reloadui" then
			KillShotElements:SaveEventLog()
		end
		Blizz_ConsoleExec(msg)
	end
end

function KillShotElements:WipeEventLog()
	table.wipe(self.eventLog)
end

function KillShotElements:SaveEventLog()
	KillShotSV.eventLog = self.eventLog
	KillShotSV.reloaded = true
end

function KillShotElements:RestoreEventLog()
	self.eventLog = KillShotSV.eventLog
end

KillShotElements.eventLog = {}
function KillShotElements:LogEvent(eventData)
	local timestamp = time()
	eventData.time = timestamp
	
	tinsert(self.eventLog, eventData)
end

function KillShotElements:EncounterSuccess(encounterName, difficultyID)
	-- 10-man, 25-man, flex
	local isHeroic = (difficultyID == 5) or (difficultyID == 6) or (difficultyID == 15)
	local isMythic = (difficultyID == 16)
	local difficultyIndex = (isMythic and 3) or (isHeroic and 2) or 1
	
	local dateString = string.match(date(), "^.+%s")
	local guildName = GetGuildInfo("player")
	
	self:LogEvent({
		type = "kill",
		difficulty = difficultyIndex,
		encounterName = encounterName,
		guildName = guildName,
		date = dateString,
	})
	
	KillShotElements:PrintKillShotPrompt(self:GetLastEventIndex("kill"))
end

function KillShotElements:ScreenshotSuccess()
	self:LogEvent({
		type = "screenshot",
		index = C_Social.GetLastScreenshot(),
	})
end

function KillShotElements:GetLastEventIndex(eventType)
	if eventType then
		for i = #self.eventLog, 1, -1 do
			if self.eventLog[i].type == eventType then
				return i
			end
		end
		assert(false, "Event of type ".. eventType .. " not found!")
	else
		return #self.eventLog
	end
end

function KillShotElements:SetToEventIndex(index)
	local eventData = self.eventLog[index]
	assert(eventData.type == "kill", "Attempt to set KillShotElements to non-kill data.")
	
	self.BossDownText:Update(self:GetKillMessage(index))
	self.DateText:Update(eventData.date)
	self.GuildNameText:Update(eventData.guildName)
end

function KillShotElements:GetKillMessage(eventIndex)
	local difficultyIndex = self.eventLog[eventIndex].difficulty
	local encounterName = self.eventLog[eventIndex].encounterName
	
	return format(BOSS_DOWN_TEXT, DIFFICULTY_TEXT[difficultyIndex], encounterName)
end

function KillShotElements:PrintKillShotPrompt(eventIndex)
	local killMessage = self:GetKillMessage(eventIndex)
	local promptText = killMessage .. " " .. format(KILL_SHOT_PROMPT, eventIndex)
	DEFAULT_CHAT_FRAME:AddMessage(promptText, YELLOW_FONT_COLOR.r, YELLOW_FONT_COLOR.g, YELLOW_FONT_COLOR.b);
end

--[[============
	Butterfly methods
--============]]

function Butterfly:EnterKillShotMode()
	KillShotElements:SetScale(UIParent:GetScale())
	KillShotElements:CreateMovers()
	KillShotElements:Show()
	
	CloseMenus()
	CloseAllWindows()
	SetUIVisibility(false);
end

function Butterfly:ExitKillShotMode()
	KillShotElements:Hide()

	SetUIVisibility(true);
end

function Butterfly:InitializeKillShotElements()
	-- Prehook TakeScreenshot so that Movers are locked
	PREHOOK_TakeScreenshot()
	-- Prehook ItemRefTooltip.SetHyperlink so that we can use custom links
	PREHOOK_ItemRefTooltipSetHyperlink()
	-- Prehook ReloadUI and ConsoleExec so we can distinguish reload from new sessions
	PREHOOK_ReloadFunctions()
	
	-- KillShotElements:RegisterEvent("PLAYER_GUILD_UPDATE")
	-- KillShotElements:RegisterEvent("GUILDTABARD_UPDATE")
	KillShotElements:RegisterEvent("SCREENSHOT_SUCCEEDED")
	KillShotElements:RegisterEvent("ENCOUNTER_END")
	KillShotElements:RegisterEvent("PLAYER_LOGIN")
	KillShotElements:RegisterEvent("ADDON_LOADED")
	KillShotElements:SetScript("OnEvent", function(self, event, ...)
		if event == "ENCOUNTER_END" then
			local _, encounterName, difficultyID, raidSize, status = ...
			
			if status == 1 and InGuildParty() then
				self:EncounterSuccess(encounterName, difficultyID)
			end
		elseif event == "SCREENSHOT_SUCCEEDED" then
			self:ScreenshotSuccess()
		elseif event == "PLAYER_LOGIN" then
			if not KillShotSV.reloaded then
				self:WipeEventLog()
			end
			KillShotSV.reloaded = false
		elseif event == "ADDON_LOADED" then
			self:RestoreEventLog()
		else
			-- self.GuildNameText:Update()
			-- self.GuildCrest:Update()
		end
	end)
end
