local addonName, Butterfly = ...;
--[[============
Since the SocialPostFrame is forbidden, we need OnUpdate shenanigans to "SetPoint" to it.
The FauxFrame is a strata-, size-, position-, and anchor-matched overlay, to which anything else should SetPoint.

EVERY movement must be exact. Any desynchronization is *unrecoverable*.

StartMoving captures init position, and StopMoving calls an extra UpdatePosition, to ensure we don't lose a single frame of movement.

The hairiest bit is that the SocialPostFrame is movable, which means that its :StopMoving may change the attachment point,
from CENTER to the nearest edge or corner. That WOULD be perfectly ignorable, except that when it calls :SetSize,
it uses THAT point as the fixed anchor. So, the FauxFrame has to explicitly reattach itself appropriately (since it isn't itself being dragged).

Not all of the related code is as clean as I'd like, but it works, and hopefully this never needs to change.

TODO:
-	Clean up the UIScale stuff?
-	Fix the hacky detach/reattach
--============]]
		
local function GetScaledCursorPosition()
	local x, y = GetCursorPosition()
	local scale = UIParent:GetScale()
	return x/scale, y/scale
end

local FauxFrame = CreateFrame("Frame", "ButterflyFauxFrame", UIParent)
FauxFrame:SetFrameStrata("HIGH")
FauxFrame.MessageFrame = CreateFrame("Frame", "ButterflyFauxFrameMessageFrame", FauxFrame)
FauxFrame:Hide() -- so that the Gallery's OnShow script can run initially

FauxFrame.sumCursorMovementX = 0
FauxFrame.sumCursorMovementY = 0
function FauxFrame:UpdateSocialPostFrameOffset()
	local newCursorX, newCursorY = GetScaledCursorPosition()
	local deltaX = newCursorX - self.oldCursorX
	local deltaY = newCursorY - self.oldCursorY
	self.oldCursorX = newCursorX
	self.oldCursorY = newCursorY
	self.sumCursorMovementX = self.sumCursorMovementX + deltaX
	self.sumCursorMovementY = self.sumCursorMovementY + deltaY
end

function FauxFrame:StartMoving()
	self.isMoving = true
	self:Detach()
end

function FauxFrame:StopMoving()
	self.isMoving = false
	self:Reattach()
end

function FauxFrame:UpdatePosition()
	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
		self.UIParentWidth/2 + self.sumCursorMovementX - self:GetWidth()/2,
		-self.UIParentHeight/2 + self.sumCursorMovementY + self:GetHeight()/2)
end


function FauxFrame:Detach()
	local distanceFromLeft = self:GetLeft()
	local distanceFromTop = self.UIParentHeight - self:GetTop()
	
	-- This is a hack and a half, but it works (it's because we fuck with attachment in the first place so resizes work properly)
	self.sumCursorMovementX = self:GetLeft() + self:GetWidth()/2 - self.UIParentWidth/2
	self.sumCursorMovementY = self:GetTop() - self:GetHeight()/2 - self.UIParentHeight/2
end

function FauxFrame:Reattach()
	local distances = {}
	distances["LEFT"] = self:GetLeft()
	distances["RIGHT"] = self.UIParentWidth - self:GetRight()
	distances["BOTTOM"] = self:GetBottom()
	distances["TOP"] = self.UIParentHeight - self:GetTop()

	local nearToLeft = distances["LEFT"] < math.abs(self.sumCursorMovementX)
	local nearToRight = distances["RIGHT"] < math.abs(self.sumCursorMovementX)
	local nearToTop = distances["TOP"] < math.abs(self.sumCursorMovementY)
	local nearToBottom = distances["BOTTOM"] < math.abs(self.sumCursorMovementY)
	
	self:ClearAllPoints()
	if nearToLeft then
		if nearToTop then
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", distances["LEFT"], -distances["TOP"])
		elseif nearToBottom then
			self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", distances["LEFT"], distances["BOTTOM"])
		else
			self:SetPoint("LEFT", UIParent, "LEFT", distances["LEFT"], self.sumCursorMovementY)
		end
	elseif nearToRight then
		if nearToTop then
			self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -distances["RIGHT"], -distances["TOP"])
		elseif nearToBottom then
			self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -distances["RIGHT"], distances["BOTTOM"])
		else
			self:SetPoint("RIGHT", UIParent, "RIGHT", -distances["RIGHT"], self.sumCursorMovementY)
		end
	else
		if nearToTop then
			self:SetPoint("TOP", UIParent, "TOP", self.sumCursorMovementX, -distances["TOP"])
		elseif nearToBottom then
			self:SetPoint("BOTTOM", UIParent, "BOTTOM", self.sumCursorMovementX, distances["BOTTOM"])
		else
			self:SetPoint("CENTER", UIParent, "CENTER", self.sumCursorMovementX, self.sumCursorMovementY)
		end
	end
	
end

function FauxFrame:OnUpdate(elapsed)
	if self.isMoving then
		self:UpdateSocialPostFrameOffset()
		self:UpdatePosition()
	end
end


function FauxFrame:Resize(width, height)
	self:SetSize(width, height)
end

Butterfly.FauxFrame = FauxFrame

function Butterfly:InitializeFauxFrame()
	hooksecurefunc(SocialPostFrame, "StartMoving", function()
		self.FauxFrame.oldCursorX, self.FauxFrame.oldCursorY = GetScaledCursorPosition()
		self.FauxFrame:StartMoving()
	end)
	
	hooksecurefunc(SocialPostFrame, "StopMovingOrSizing", function()
		self.FauxFrame:UpdateSocialPostFrameOffset()
		self.FauxFrame:UpdatePosition()
		self.FauxFrame:StopMoving()
	end)
	
	self.FauxFrame:SetSize(SOCIAL_DEFAULT_FRAME_WIDTH, SOCIAL_DEFAULT_FRAME_HEIGHT)
	self.FauxFrame:SetPoint("CENTER")
	FauxFrame.MessageFrame:SetSize(348, 92)
	FauxFrame.MessageFrame:SetPoint("BOTTOM", 0, 62)
	
	-- Can't use HookScript("OnShow") because SocialPostFrame is forbidden
	-- Can't hook SocialPostFrame_OnShow because it's referenced inline in the XML and the new hook won't be called
	hooksecurefunc(SocialPostFrame, "Show", function() self.FauxFrame:Show() end)
	hooksecurefunc(SocialPostFrame, "Hide", function() self.FauxFrame:Hide() end)
	hooksecurefunc(SocialPostFrame, "SetSize", function(SPF, width, height) self.FauxFrame:Resize(width, height) end)
	self.FauxFrame:SetScript("OnUpdate", function(self, elapsed) self:OnUpdate(elapsed) end)
	
	self.FauxFrame.UIScale = UIParent:GetScale()
	self.FauxFrame.UIParentWidth = UIParent:GetWidth()
	self.FauxFrame.UIParentHeight = UIParent:GetHeight()
			
	FauxFrame:RegisterEvent("UI_SCALE_CHANGED")
	FauxFrame:SetScript("OnEvent", function(self, event)
		if event == "UI_SCALE_CHANGED" then
			local newScale = UIParent:GetScale()
			self.sumCursorMovementX = self.sumCursorMovementX*newScale/self.UIScale
			self.sumCursorMovementY = self.sumCursorMovementY*newScale/self.UIScale
			self.UIScale = newScale
			
			self.UIParentWidth = UIParent:GetWidth()
			self.UIParentHeight = UIParent:GetHeight()
		end
	end)
end