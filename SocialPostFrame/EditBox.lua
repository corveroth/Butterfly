local addonName, Butterfly = ...;
--[[============
We can't actually read out the text from the SocialPostFrame, because it's forbidden.
That sucks, because most of what we want to do is just replace the links with Wowhead ones
(and create achievement links in the first place - Blizz doesn't because Armory doesn't have those pages)

So, a lot of this is just a copy/paste from Blizz's SocialPostFrame.lua, with the necessary adaptations.
--============]]

local WOWHEAD_ITEM_LINK = "http://www.wowhead.com/item="
local WOWHEAD_ACHIEVEMENT_LINK = "http://www.wowhead.com/achievement="

local SOCIAL_ACHIEVEMENT_PREFILL_TEXT_EARNED = "I just earned %s!"
local SOCIAL_ACHIEVEMENT_PREFILL_TEXT_GENERIC = "Check out this achievement! %s"
local SOCIAL_ACHIEVEMENT_PREFILL_TEXT_ALL = "%s %s #Warcraft"

function Butterfly.ItemPrefillHook(itemID, earned, creationContext, name, quality)
	if (creationContext == nil) then
		creationContext = "";
	end
	if (name == nil or quality == nil) then
		local ignored;
		name, ignored, quality = GetItemInfo(itemID);
	end

	local prefillText;
	if (earned) then
		prefillText = SOCIAL_ITEM_PREFILL_TEXT_EARNED;
	else
		prefillText = SOCIAL_ITEM_PREFILL_TEXT_GENERIC;
	end
	
	local r, g, b, colorString = GetItemQualityColor(quality);
	local itemNameColored = format("|c%s[%s]|r", colorString, name);
	local linkFormatStr = "|cff3b94d9" .. WOWHEAD_ITEM_LINK .. "%s|r";
	local armoryLink = format(linkFormatStr, itemID);
	local text = format(SOCIAL_ITEM_PREFILL_TEXT_ALL, prefillText, itemNameColored, armoryLink);
	SocialPostFrame:SetAttribute("settext", text);
end

function Butterfly.AchievementPrefillHook(achievementID, earned, name)
	if (name == nil) then
		local ignored;
		ignored, name = GetAchievementInfo(achievementID);
	end

	-- Populate editbox with achievement prefill text
	local achievementNameColored = format("%s[%s]|r", NORMAL_FONT_COLOR_CODE, name);
	local prefillText;
	if (earned) then
		prefillText = format(SOCIAL_ACHIEVEMENT_PREFILL_TEXT_EARNED, achievementNameColored);
	else
		prefillText = format(SOCIAL_ACHIEVEMENT_PREFILL_TEXT_GENERIC, achievementNameColored);
	end

	local linkFormatStr = "|cff3b94d9" .. WOWHEAD_ACHIEVEMENT_LINK .. "%s|r";
	local armoryLink = format(linkFormatStr, achievementID);
	local text = format(SOCIAL_ACHIEVEMENT_PREFILL_TEXT_ALL, prefillText, armoryLink);
	SocialPostFrame:SetAttribute("settext", text);
end

function Butterfly:ApplyTextHooks()
	hooksecurefunc("SocialPrefillItemText", self.ItemPrefillHook)
	hooksecurefunc("SocialPrefillAchievementText", self.AchievementPrefillHook)
end