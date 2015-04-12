local addonName, Butterfly = ...;
--[[============
Wouldn't it be nice if we could just reassign Blizz's last-screenshot button for our gallery?
Sadly, it's forbidden. However, not much stopping us from just putting another lookalike *over* it.

Except, y'know, the SocialShareButton template being forbidden too.
So, mimic the relevant bits of that... and the SocialScreenshotTooltip.

Indices for SPFReplacementButtons are internal tracking numbers.
Indices for SPFBlockers and OverrideSocialPostFrameButton refer to positions on the SocialPostFrame
SPFBlockers may be totally unnecessary, but exist to make fully sure no mouse events go through to the original buttons
--============]]

local FauxFrame = Butterfly.FauxFrame
-- These values are from the SocialShareButton template definition in Blizzard_SocialUI.xml
local SOCIAL_BUTTON_WIDTH = 42
local SOCIAL_BUTTON_HEIGHT = 43

-- SOCIAL_BUTTON_OFFSETs are derived from inspection of Blizzard_SocialUI.xml:409 ish, in the definition of SocialPostFrame
local SOCIAL_BUTTON_XOFFSET = -6
local SOCIAL_BUTTON_YOFFSET = -11
local SOCIAL_BUTTON_POINT = "TOPLEFT"
local SOCIAL_BUTTON_RELATIVE_POINT = "BOTTOMLEFT"
local SOCIAL_BUTTON_PADDING = 7

function Butterfly:CreateNewSocialShareButton()
	local num = #self.SPFReplacementButtons + 1
	
	local f = CreateFrame("Button", "ButterflySPFButton"..num, FauxFrame)
	f:SetSize(SOCIAL_BUTTON_WIDTH, SOCIAL_BUTTON_HEIGHT)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(2)
	f.Icon = f:CreateTexture()
	f.Icon:SetDrawLayer("OVERLAY", 0)
	f.Icon:SetAtlas("WoWShare-AchievementIcon", true)
	f.Icon:SetPoint("CENTER")
	
	f.Border = f:CreateTexture()
	f.Border:SetDrawLayer("OVERLAY", 1)
	f.Border:SetAtlas("WoWShare-AddButton-Up", true)
	f.Border:SetPoint("CENTER")
	
	f.QualityBorder = f:CreateTexture()
	f.QualityBorder:SetDrawLayer("OVERLAY", 2)
	f.QualityBorder:SetAtlas("WoWShare-ItemQualityBorder", true)
	f.QualityBorder:SetPoint("CENTER")
	f.QualityBorder:SetVertexColor(0, 0, 1, 1)
	f.QualityBorder:Hide()
	
	f.Highlight = f:CreateTexture()
	f.Highlight:SetDrawLayer("HIGHLIGHT")
	f.Highlight:SetAtlas("WoWShare-Highlight", true)
	f.Highlight:SetPoint("CENTER")
	
	f.Plus = f:CreateTexture()
	f.Plus:SetDrawLayer("HIGHLIGHT")
	f.Plus:SetAtlas("WoWShare-Plus", true)
	f.Plus:SetPoint("CENTER")
	
	f:SetScript("OnMouseDown", SharedButton_OnMouseDown)
	f:SetScript("OnMouseUp", SharedButton_OnMouseUp)
	
	self.SPFReplacementButtons[num] = f
	return f
end

function Butterfly:CreateSPFBlocker(index)
	local underlay = CreateFrame("Frame", "ButterflySPFButtonBlocker"..index, FauxFrame)
	underlay:EnableMouse(true)
	underlay:SetFrameStrata("DIALOG")
	underlay:SetFrameLevel(1)
	underlay:SetSize(SOCIAL_BUTTON_WIDTH, SOCIAL_BUTTON_HEIGHT)
	underlay:SetPoint(SOCIAL_BUTTON_POINT, FauxFrame.MessageFrame, SOCIAL_BUTTON_RELATIVE_POINT,
		SOCIAL_BUTTON_XOFFSET+(SOCIAL_BUTTON_WIDTH+SOCIAL_BUTTON_PADDING)*(index-1),
		SOCIAL_BUTTON_YOFFSET)
	self.SocialPostFrameBlockers[index] = underlay
	return underlay
end

function Butterfly:GetSPFBlocker(index)
	return self.SocialPostFrameBlockers[index]
end

function Butterfly:OverrideSocialPostFrameButton(newButton, index)
	if not self:GetSPFBlocker(index) then
		self:CreateSPFBlocker(index)
	end
		
	newButton:SetPoint(SOCIAL_BUTTON_POINT, FauxFrame.MessageFrame, SOCIAL_BUTTON_RELATIVE_POINT,
		SOCIAL_BUTTON_XOFFSET+(SOCIAL_BUTTON_WIDTH+SOCIAL_BUTTON_PADDING)*(index-1),
		SOCIAL_BUTTON_YOFFSET)
end

function Butterfly:UpdateGalleryButton()
	local self = self.galleryButton
	local index = C_Social.GetLastScreenshot();
	if (index > 0 and C_Social.GetScreenshotByIndex(index)) then
		C_Social.SetTextureToScreenshot(self.Icon, index);
		self:Enable();
	else
		self.Icon:SetAtlas("WoWShare-ScreenshotIcon", true);
		self:Disable();
	end
end

--[[============
We can't check the SPF.ImageFrame, and there's no attribute that'll tell us the current state of the window.
In principle, we should watch SPF.SetAttribute and manually track it's state. However, we've got a FauxFrame.
--============]]
function ButterflyGalleryButton_OnClick(self, button)
	local alreadyShown = (FauxFrame:GetWidth() ~= SOCIAL_DEFAULT_FRAME_WIDTH) or (FauxFrame:GetHeight() ~= SOCIAL_DEFAULT_FRAME_HEIGHT)
	if button == "LeftButton" then
		-- Note that we can't just call SocialPrefillScreenshotText and get the side effects of that due to forbidden references
		SocialPostFrame:SetAttribute("screenshotview", C_Social.GetLastScreenshot())
	else
		Butterfly:InitializeGalleryFrame()
	end
	if (alreadyShown) then
		PlaySound("igMainMenuOption");
	end
end
 
function ButterflyGalleryButton_OnEnter(self)
  -- local index = C_Social.GetLastScreenshot();
  -- local valid, width, height = C_Social.GetScreenshotByIndex(index);
  -- if (valid) then
    -- SocialScreenshotButton_ShowTooltip(self, width, height);
  -- else
    -- GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", -38, -12);
    -- GameTooltip:SetText(SOCIAL_SCREENSHOT_PREFILL_NONE);
  -- end
end
 
function ButterflyGalleryButton_OnLeave(self)
  -- GameTooltip_Hide();
  -- SocialScreenshotTooltip:Hide();
end

function Butterfly:InitializeSPFButtons()
	self.SPFReplacementButtons = {}
	self.SocialPostFrameBlockers = {}
	
	-- self:InitScreenshotTooltip()
	
	local galleryButton = self:CreateNewSocialShareButton()
	galleryButton:RegisterForClicks("AnyUp")
	galleryButton:SetScript("OnClick", ButterflyGalleryButton_OnClick)
	galleryButton:SetScript("OnEnter", ButterflyGalleryButton_OnEnter)
	galleryButton:SetScript("OnLeave", ButterflyGalleryButton_OnLeave)
	self:OverrideSocialPostFrameButton(galleryButton, 1)
	self.galleryButton = galleryButton
	
	hooksecurefunc("SocialScreenshotButton_Update", function()
		Butterfly:UpdateGalleryButton()
	end)
end