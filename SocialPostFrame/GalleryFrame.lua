local addonName, Butterfly = ...;
--[[============

--============]]
local FauxFrame = Butterfly.FauxFrame

local GALLERY_PADDING = 2

local GalleryFrame = CreateFrame("Frame", "ButterflyGalleryFrame", FauxFrame, "BasicFrameTemplateWithInset")
local ButterflyGalleryScrollFrame = CreateFrame("ScrollFrame", "ButterflyGalleryScrollFrame", GalleryFrame)
GalleryFrame.ScrollFrame = ButterflyGalleryScrollFrame

--[[============
Boring verbose layout building code inside.
--============]]
do
	-- We don't want the title bar and such, but rather than play with textures...
	-- Since we're doing such sketchy stuff to attach the frame anyways, just sweep it under the rug
	-- Hide the CloseButton though, just in case?
	GalleryFrame:SetPoint("TOP", FauxFrame, "BOTTOM", 0, 26)
	GalleryFrame.CloseButton:Hide()
	-- Bump up the size of the inset a bit
	GalleryFrame.InsetBg:ClearAllPoints()
	GalleryFrame.InsetBg:SetPoint("TOPLEFT", 6, -24) -- (4, -24)
	GalleryFrame.InsetBg:SetPoint("BOTTOMRIGHT", -8, 6) -- (-6, 4)
	

	ButterflyGalleryScrollFrame:SetPoint("TOPLEFT", 10, -30)
	ButterflyGalleryScrollFrame:SetPoint("BOTTOMRIGHT", -12, 36)
	
	-- The bar itself.
	local scrollBar = CreateFrame("Slider", "ButterflyGalleryScrollFrameScrollBar", ButterflyGalleryScrollFrame)
	local scrollThumb = scrollBar:CreateTexture("ButterflyGalleryScrollFrameScrollBarThumbTexture", "ARTWORK", "UIPanelScrollBarButton")
	scrollThumb:SetSize(18, 24)
	scrollThumb:SetTexCoord(0.20, 0.80, 0.125, 0.875)
	scrollThumb:SetTexture([[Interface\Buttons\UI-ScrollBar-Knob]])
	scrollThumb:SetPoint("LEFT", 0, 2)
	scrollBar:SetThumbTexture(scrollThumb)
	scrollBar:SetOrientation("HORIZONTAL")
	scrollBar:SetPoint("BOTTOMLEFT", GalleryFrame, "BOTTOMLEFT", 30, 14)
	scrollBar:SetPoint("BOTTOMRIGHT", GalleryFrame, "BOTTOMRIGHT", -31, 14)
	scrollBar:SetHeight(16)
	scrollBar:SetScript("OnValueChanged", function(self, value)
		self:GetParent():SetHorizontalScroll(value);
	end)
	local scrollBarLeftTexture = scrollBar:CreateTexture("BST")
	scrollBarLeftTexture:SetTexture([[Interface\ClassTrainerFrame\UI-ClassTrainer-ScrollBar]])
	scrollBarLeftTexture:SetTexCoord(0.53125, 1.0,   1.0, 1.0,   0.53125, 0.03125,   1.0, 0.03125)
	scrollBarLeftTexture:SetSize(123, 29)
	scrollBarLeftTexture:SetPoint("BOTTOMLEFT", -21, -5)
	
	local scrollBarRightTexture = scrollBar:CreateTexture("BSR")
	scrollBarRightTexture:SetTexture([[Interface\ClassTrainerFrame\UI-ClassTrainer-ScrollBar]])
	scrollBarRightTexture:SetTexCoord(0.0, 0.9609375,   0.46875, 0.9609375,   0.0, 0.0234375,   0.46875, 0.0234375)
	scrollBarRightTexture:SetSize(120, 29)
	scrollBarRightTexture:SetPoint("BOTTOMRIGHT", 19, -5)

	local scrollBarMiddleTexture = scrollBar:CreateTexture("BSM")
	scrollBarMiddleTexture:SetTexture([[Interface\ClassTrainerFrame\UI-ClassTrainer-ScrollBar]])
	scrollBarMiddleTexture:SetTexCoord(0.0, 0.9609375,   0.46875, 0.9609375,   0.0, 0.4,   0.46875, 0.4)
	scrollBarMiddleTexture:SetHeight(29)
	scrollBarMiddleTexture:SetPoint("LEFT", scrollBarLeftTexture, "RIGHT")
	scrollBarMiddleTexture:SetPoint("RIGHT", scrollBarRightTexture, "LEFT")
	
	-- The right née Down button
	local scrollBarRightButton = CreateFrame("Button", "ButterflyGalleryScrollFrameScrollBarScrollDownButton", scrollBar, "UIPanelScrollDownButtonTemplate")
	scrollBarRightButton:SetScript("OnClick", function(self)
		local parent = self:GetParent();
		local scrollStep = self:GetParent().scrollStep or (parent:GetHeight() / 2);
		parent:SetValue(parent:GetValue() + scrollStep);
		PlaySound("UChatScrollButton");
	end)
	scrollBarRightButton:SetPoint("LEFT", scrollBar, "RIGHT", 1, 0)
	local rightAnim = scrollBarRightButton:CreateAnimationGroup()
	local rightAnimRot = rightAnim:CreateAnimation("Rotation")
	rightAnimRot:SetDegrees(90)
	rightAnimRot:SetEndDelay(math.huge)
	rightAnim:Play()
	
	-- The left née Up button
	local scrollBarLeftButton = CreateFrame("Button", "ButterflyGalleryScrollFrameScrollBarScrollUpButton", scrollBar, "UIPanelScrollUpButtonTemplate")
	scrollBarLeftButton:SetScript("OnClick", function(self)
		local parent = self:GetParent();
		local scrollStep = self:GetParent().scrollStep or (parent:GetHeight() / 2);
		parent:SetValue(parent:GetValue() - scrollStep);
		PlaySound("UChatScrollButton");
	end)
	scrollBarLeftButton:SetPoint("RIGHT", scrollBar, "LEFT", -1, 0)
	local leftAnim = scrollBarLeftButton:CreateAnimationGroup()
	local leftAnimRot = leftAnim:CreateAnimation("Rotation")
	leftAnimRot:SetDegrees(90)
	leftAnimRot:SetEndDelay(math.huge)
	leftAnim:Play()
	
	-- The actual "content" of the scroll frame.
	local scrollChild = CreateFrame("Frame", "ButterflyGalleryScrollFrameContent", ButterflyGalleryScrollFrame)
	ButterflyGalleryScrollFrame:SetScrollChild(scrollChild)
	GalleryFrame.ScrollFrame.Content = scrollChild
	
	--[[============
		The rest of this is scripts lifted from Blizz's normal ScrollFrame stuff, just modified for horizontal scrolling.
	--============]]
	ScrollFrame_OnLoad(ButterflyGalleryScrollFrame)
	ButterflyGalleryScrollFrame:SetScript("OnScrollRangeChanged", function(self, xrange, yrange)
		local scrollbar = self.ScrollBar or _G[self:GetName().."ScrollBar"];
		if ( not xrange ) then
			xrange = self:GetHorizontalScrollRange();
		end
		local value = scrollbar:GetValue();
		if ( value > xrange ) then
			value = xrange;
		end
		scrollbar:SetMinMaxValues(0, xrange);
		scrollbar:SetValue(value);
		if ( floor(xrange) == 0 ) then
			if ( self.scrollBarHideable ) then
				_G[self:GetName().."ScrollBar"]:Hide();
				_G[scrollbar:GetName().."ScrollDownButton"]:Hide();
				_G[scrollbar:GetName().."ScrollUpButton"]:Hide();
				_G[scrollbar:GetName().."ThumbTexture"]:Hide();
			else
				_G[scrollbar:GetName().."ScrollDownButton"]:Disable();
				_G[scrollbar:GetName().."ScrollUpButton"]:Disable();
				_G[scrollbar:GetName().."ScrollDownButton"]:Show();
				_G[scrollbar:GetName().."ScrollUpButton"]:Show();
				if ( not self.noScrollThumb ) then
					_G[scrollbar:GetName().."ThumbTexture"]:Show();
				end
			end
		else
			_G[scrollbar:GetName().."ScrollDownButton"]:Show();
			_G[scrollbar:GetName().."ScrollUpButton"]:Show();
			_G[self:GetName().."ScrollBar"]:Show();
			if ( not self.noScrollThumb ) then
				_G[scrollbar:GetName().."ThumbTexture"]:Show();
			end
			-- The 0.005 is to account for precision errors
			if ( xrange - value > 0.005 ) then
				_G[scrollbar:GetName().."ScrollDownButton"]:Enable();
			else
				_G[scrollbar:GetName().."ScrollDownButton"]:Disable();
			end
		end

		-- Hide/show ButterflyGalleryScrollFrame borders
		local top = _G[self:GetName().."Top"];
		local bottom = _G[self:GetName().."Bottom"];
		local middle = _G[self:GetName().."Middle"];
		if ( top and bottom and self.scrollBarHideable ) then
			if ( self:GetHorizontalScrollRange() == 0 ) then
				top:Hide();
				bottom:Hide();
			else
				top:Show();
				bottom:Show();
			end
		end
		if ( middle and self.scrollBarHideable ) then
			if ( self:GetHorizontalScrollRange() == 0 ) then
				middle:Hide();
			else
				middle:Show();
			end
		end
	end)
	ButterflyGalleryScrollFrame:SetScript("OnHorizontalScroll", function(self, offset)
		local scrollbar = _G[self:GetName().."ScrollBar"];
		scrollbar:SetValue(offset);
		local min;
		local max;
		min, max = scrollbar:GetMinMaxValues();
		if ( offset == 0 ) then
			_G[scrollbar:GetName().."ScrollUpButton"]:Disable();
		else
			_G[scrollbar:GetName().."ScrollUpButton"]:Enable();
		end
		if ((scrollbar:GetValue() - max) == 0) then
			_G[scrollbar:GetName().."ScrollDownButton"]:Disable();
		else
			_G[scrollbar:GetName().."ScrollDownButton"]:Enable();
		end
	end)
	ButterflyGalleryScrollFrame:SetScript("OnMouseWheel", function(self, value, scrollBar)
		scrollBar = scrollBar or _G[self:GetName() .. "ScrollBar"];
		local scrollStep = scrollBar.scrollStep or scrollBar:GetWidth() / 2
		if ( value > 0 ) then
			scrollBar:SetValue(scrollBar:GetValue() - scrollStep);
		else
			scrollBar:SetValue(scrollBar:GetValue() + scrollStep);
		end
	end)
end

function GalleryFrame:GetChromeHeight()
	local yOffsets = 0
	for i = 1, self.ScrollFrame:GetNumPoints() do
		-- Technically, it really SHOULDN'T be a simple absolute value, it should be directional
		-- But y'know what? The points aren't "backwards" and they never should be, bite me
		-- (I fully expect to come back months from now, bitten)
		yOffsets = yOffsets + math.abs(select(5, self.ScrollFrame:GetPoint(i)))
	end
	return yOffsets
end

--[[============
	Note that AddGalleryButton does *not* set the size on anything.
--============]]
function GalleryFrame:AddGalleryButton()
	local ScrollContent = GalleryFrame.ScrollFrame.Content
	local lastIndex = #self.galleryButtons
	
	local valid, width, height = C_Social.GetScreenshotByIndex(lastIndex+1)
	assert(valid, "Failed to load screenshot")
  
	local f = CreateFrame("Button", "ButterflyGalleryContentButton" .. lastIndex+1, ScrollContent, "HelpPlateBox")
	f:SetScript("OnClick", function(self)
		SocialPostFrame:SetAttribute("screenshotview", self.id)
	end)
	-- I don't have a good reason but I need to show the buttons or they don't come up. Parenting issue?
	f:Show()
	f.id = lastIndex+1
	C_Social.SetTextureToScreenshot(f.BG, f.id)
	-- This line feels hackish but the texture doesn't return valid sizes until it's sized > 0 somewhere
	f.BG.width, f.BG.height = width, height
	f.BG:SetNonBlocking(true)
	
	hooksecurefunc(f.BG, "SetDesaturated", function() assert(false, "Desaturated texture!\nPlease forward this crash log to corveroth@gmail.com") end)
	
	f.Plus = f:CreateTexture()
	f.Plus:SetDrawLayer("HIGHLIGHT")
	f.Plus:SetAtlas("WoWShare-Plus", true)
	f.Plus:SetPoint("TOPLEFT")
	
	-- Create the highlight glow
	do
		local bottom = f:CreateTexture()
		bottom:SetDrawLayer("HIGHLIGHT")
		bottom:SetTexture([[Interface\Common\talent-blue-glow]])
		bottom:SetPoint("BOTTOMLEFT")
		bottom:SetPoint("BOTTOMRIGHT")
		
		local top = f:CreateTexture()
		top:SetDrawLayer("HIGHLIGHT")
		top:SetTexture([[Interface\Common\talent-blue-glow]])
		top:SetTexCoord(1.0, 1.0,    1.0, 0.0,   0.0, 1.0,   0.0, 0.0)
		top:SetPoint("TOPLEFT")
		top:SetPoint("TOPRIGHT")
		
		local left = f:CreateTexture()
		left:SetDrawLayer("HIGHLIGHT")
		left:SetTexture([[Interface\Common\talent-blue-glow]])
		left:SetTexCoord(0.0, 1.0,   1.0, 1.0,   0.0, 0.0,   1.0, 0.0)
		left:SetPoint("TOPLEFT")
		left:SetPoint("BOTTOMLEFT")
		
		local right = f:CreateTexture()
		right:SetDrawLayer("HIGHLIGHT")
		right:SetTexture([[Interface\Common\talent-blue-glow]])
		right:SetTexCoord(1.0, 0.0,   0.0, 0.0,   1.0, 1.0,   0.0, 1.0)
		right:SetPoint("TOPRIGHT")
		right:SetPoint("BOTTOMRIGHT")
	end
	
	if lastIndex == 0 then
		f:SetPoint("RIGHT", ScrollContent, "RIGHT", -GALLERY_PADDING, 0)
	else
		f:SetPoint("RIGHT", self.galleryButtons[lastIndex], "LEFT", -GALLERY_PADDING, 0)
	end
	tinsert(self.galleryButtons, f)
end

function GalleryFrame:ResizeGalleryButtons()
	local gbWidth, gbHeight
	local sumWidths, maxHeight = 0, 0
	for i, button in pairs (self.galleryButtons) do
		gbWidth, gbHeight = CalculateScreenshotSize(button.BG.width, button.BG.height, SOCIAL_SCREENSHOT_TOOLTIP_MAX_WIDTH, SOCIAL_SCREENSHOT_TOOLTIP_MAX_HEIGHT)
		button:SetSize(gbWidth, gbHeight)
		if gbHeight > maxHeight then
			maxHeight = gbHeight
		end
		sumWidths = sumWidths + gbWidth
	end
	
	return sumWidths, maxHeight
end

function GalleryFrame:ResizeContents()
	local buttonWidths, maxButtonHeight = self:ResizeGalleryButtons()
	local contentHeight = maxButtonHeight + 2*GALLERY_PADDING
	local galleryHeight = contentHeight + self:GetChromeHeight()
	
	local contentWidth = buttonWidths + (#self.galleryButtons+1)*GALLERY_PADDING
	self.ScrollFrame.Content:SetSize(contentWidth, contentHeight)
	self:SetHeight(galleryHeight)
end


--[[============
	C_Social.SetTextureToScreenshot is relatively expensive, but f.BG is non-blocking, which mitigates most of it.
	Might be worth investigating further mitigation options now.
--============]]
function GalleryFrame:RebuildFromReload()
	for i = 1,  C_Social.GetLastScreenshot() do
		GalleryFrame:AddGalleryButton()
	end
	GalleryFrame:ResizeContents()
	if not GalleryFrame:IsShown() then
		GalleryFrame:Show()
	end

end

function Butterfly:InitializeGalleryFrame()
	GalleryFrame.galleryButtons = {}
	if C_Social.GetLastScreenshot() > 0 then
		GalleryFrame:RebuildFromReload()
	end
	
	GalleryFrame:RegisterEvent("SCREENSHOT_SUCCEEDED")
	GalleryFrame:SetScript("OnEvent", function(self, event)
		if event == "SCREENSHOT_SUCCEEDED" then
			self:AddGalleryButton()
			self:ResizeContents()
			if not self:IsShown() then
				self:Show()
			end
		end
	end)
	GalleryFrame:SetScript("OnShow", function(self)
		if #self.galleryButtons < 1 then
			self:Hide()
		end
	end)
	hooksecurefunc(FauxFrame, "Resize", function(frame, width, height)
		GalleryFrame:SetWidth(width - GALLERY_PADDING*4)
	end)
end