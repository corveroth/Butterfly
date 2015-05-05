local addonName, Butterfly = ...;
--[[============
	Movers are overlays on the various widgets of KillShotElements that should be visible in the
	final screenshot. They're how the user should interact with them.
	
	Movers look and control a lot like the CropFrameTemplate, we just want extra handles, and we don't need
	the dark rects (how blizz obscures the area being cropped away).
	
	Guess which template is forbidden?
	Much of this file, and Mover.xml, is just more lightly edited Blizz code as a consequence.
	
	Enable
	Disable
		Sets whether the widget will be visible in the screenshot, or ignored.
		Indicated by a transparent colored overlay
	Lock
	Unlock
		Sets whether the widget is movable
		Indicated by a lock icon in the upper corner of the Mover
	
--============]]

local MOVER_MIN_WIDTH = 100
local MOVER_MIN_HEIGHT = 50

local function ClampMove(self, x, y)
	local myWidth, myHeight = self:GetSize();
	local pWidth, pHeight = self:GetParent():GetSize();
	local maxX = pWidth - myWidth;
	local minY = -(pHeight - myHeight);

	if (x < 0) then
		x = 0;
	elseif (x > maxX) then
		x = maxX;
	end

	if (y > 0) then
		y = 0;
	elseif (y < minY) then
		y = minY;
	end
	return x, y;
end
 
local function ClampResizePosX(x, parent)
	if (x < 0) then
		x = 0;
	elseif (x > parent.currentPosX + parent.currentWidth - MOVER_MIN_WIDTH) then
		x = parent.currentPosX + parent.currentWidth - MOVER_MIN_WIDTH;
	end
	return x;
end
 
local function ClampResizePosY(y, parent)
	if (y > 0) then
		y = 0;
	elseif (y < parent.currentPosY - parent.currentHeight + MOVER_MIN_HEIGHT) then
		y = parent.currentPosY - parent.currentHeight + MOVER_MIN_HEIGHT;
	end
	return y;
end
 
local function ClampResizeWidth(width, x, parent)
	local frameWidth, frameHeight = parent:GetParent():GetSize();
	if (width < MOVER_MIN_WIDTH) then
		width = MOVER_MIN_WIDTH;
	elseif (width > frameWidth - x) then
		width = frameWidth - x;
	end
	return width;
end
 
local function ClampResizeHeight(height, y, parent)
	local frameWidth, frameHeight = parent:GetParent():GetSize();
	if (height < MOVER_MIN_HEIGHT) then
		height = MOVER_MIN_HEIGHT;
	elseif (height > frameHeight + y) then
		height = frameHeight + y;
	end
	return height;
end
 
function ButterflyMover_Move_OnEnter(self)
	if (self.resizeType == nil) then
		SetCursor("UI_MOVE_CURSOR");
	end
end
 
function ButterflyMover_Move_OnLeave(self)
	if (self.resizeType == nil) then
		ResetCursor();
	end
end
 
function ButterflyMover_Move_OnMouseDown(self)
	self.startPosX, self.startPosY = GetScaledCursorPosition();
	self:SetScript("OnUpdate", ButterflyMover_Move_OnUpdate);
end
 
function ButterflyMover_Move_OnMouseUp(self)
	local _;
	_, _, _, self.currentPosX, self.currentPosY = self:GetPoint(0);
	self:SetScript("OnUpdate", nil);

	if (not self:IsMouseOver()) then
		ResetCursor();
	end
end

function ButterflyMover_Move_OnUpdate(self)
	local xPos, yPos = GetScaledCursorPosition();
	local newX = self.currentPosX + (xPos - self.startPosX);
	local newY = self.currentPosY + (yPos - self.startPosY);
	newX, newY = ClampMove(self, newX, newY);
	self:SetPoint("TOPLEFT", newX, newY);
end

function ButterflyMover_Resize_OnEnter(self)
	SetCursor("UI_RESIZE_CURSOR");
end

function ButterflyMover_Resize_OnLeave(self)
	if (self:GetParent().resizeType == nil) then
		ResetCursor();
	end
end



function ButterflyMover_Resize_OnMouseDown(self)
	local parent = self:GetParent();
	parent.startPosX, parent.startPosY = GetScaledCursorPosition();
	parent.resizeType = self.corner;
	self:SetScript("OnUpdate", ButterflyMover_Resize_OnUpdate);
end
 
function ButterflyMover_Resize_OnMouseUp(self)
	local parent = self:GetParent();
	local _;
	_, _, _, parent.currentPosX, parent.currentPosY = parent:GetPoint(0);
	parent.currentWidth, parent.currentHeight = parent:GetSize();
	parent.resizeType = nil;
	self:SetScript("OnUpdate", nil);

	if (not self:IsMouseOver()) then
		ResetCursor();
	end
end
 
function ButterflyMover_Resize_OnUpdate(self)
	local parent = self:GetParent();
	local mouseX, mouseY = GetScaledCursorPosition();
	local xDiff = mouseX - parent.startPosX;
	local yDiff = mouseY - parent.startPosY;

	-- Calculate position of top-left corner of crop box
	local newX = parent.currentPosX;
	local newY = parent.currentPosY;
	if (parent.resizeType == "TOPLEFT" or parent.resizeType == "BOTTOMLEFT") then
		newX = ClampResizePosX(newX + xDiff, parent);
	end
	if (parent.resizeType == "TOPLEFT" or parent.resizeType == "TOPRIGHT") then
		newY = ClampResizePosY(newY + yDiff, parent);
	end

	-- Calculate width and height of crop box
	local newWidth = parent.currentWidth;
	local newHeight = parent.currentHeight;
	if (parent.resizeType == "TOPLEFT" or parent.resizeType == "BOTTOMLEFT") then
		newWidth = ClampResizeWidth(newWidth - (newX - parent.currentPosX), newX, parent);
	else
		newWidth = ClampResizeWidth(newWidth + xDiff, newX, parent);
	end
	if (parent.resizeType == "TOPLEFT" or parent.resizeType == "TOPRIGHT") then
		newHeight = ClampResizeHeight(newHeight + (newY - parent.currentPosY), newY, parent);
	else
		newHeight = ClampResizeHeight(newHeight - yDiff, newY, parent);
	end

	parent:SetSize(newWidth, newHeight);
	parent:SetPoint("TOPLEFT", newX, newY);
end


local Mover = {}
Mover.meta = {
	__index = Mover
}
function Mover:Enable()
	self:SetTexture(0, 1, 0, 0.2)
end

function Mover:Disable()
	self:SetTexture(1, 0, 0, 0.2)
end

function Mover.Reset(newMover)
	local self = newMover
	local contentWidth, contentHeight = self.content:GetSize();
	self.currentWidth = contentWidth
	self.currentHeight = contentHeight
	self.currentPosX = (contentWidth - self.currentWidth) / 2;
	self.currentPosY = -(contentHeight - self.currentHeight) / 2;

	self:SetSize(self.currentWidth, self.currentHeight);
	self:SetPoint("TOPLEFT", self.content, "TOPLEFT", self.currentPosX, self.currentPosY);
end
function Mover:New(widget)
	local newMover = CreateFrame("Frame", "ButterflyMover" .. 1, Butterfly.KillShotElements, "ButterflyMoverTemplate")
	newMover.content = widget
	Mover.Reset(newMover)
	newMover.BG:SetTexture(0, 1, 0, 0.2)
	newMover:Show()
	-- setmetatable(newMover, self.meta)
	-- newMover:Enable()
end


function Butterfly:LockOrDisableMovers()
	
end

Butterfly.Mover = Mover