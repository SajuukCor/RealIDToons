--[[
Author: Starinnia
RealID Toons - Add character information to the BNet alerts your RealID friends generate
This file provides the in-game option screen allowing user customization of the alerts
$Date: 2012-08-30 13:01:19 -0500 (Thu, 30 Aug 2012) $
$Revision: 132 $
Project Version: @project-version@
contact: codemaster2010 AT gmail DOT com

Copyright (c) 2010-2012 Michael J. Murray aka Lyte of Lothar(US)
All rights reserved unless otherwise explicitly stated.
]]

do
	--give it a slash command
	_G["SlashCmdList"]["REALIDTOONS_MAIN"] = function() InterfaceOptionsFrame_OpenToCategory("RealID Toons") end
	_G["SLASH_REALIDTOONS_MAIN1"] = "/ridt"
	
	--localization
	local L
	local LOCALE = GetLocale()
	if LOCALE ~= "enUS" and LOCALE ~= "enGB" then L = {} end
	
	if LOCALE == "esES" then
--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "esMX" then
--@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "deDE" then
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "frFR" then
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "koKR" then
--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	elseif LOCALE == "itIT" then
--@localization(locale="itIT", format="lua_additive_table", handle-unlocalized="comment", table-name="L")@
	end
	
	L = setmetatable(L or {}, {__index = function(t, key)
		local value = tostring(key)
		t[key] = value
		return value
	end})
	
	--the actual interface
	local options = CreateFrame("FRAME", nil, InterfaceOptionsFramePanelContainer)
	options:Hide()
	options.name = "RealID Toons"
	InterfaceOptions_AddCategory(options)
	
	local title = options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("RealID Toons")
	
	local checkBoxTitle = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	checkBoxTitle:SetPoint("TOPLEFT", 16, -42)
	checkBoxTitle:SetText(L["Disable Toasts In Combat"])
	
	local checkBox = CreateFrame("CheckButton", nil, options, "OptionsBaseCheckButtonTemplate")
	checkBox:SetPoint("LEFT", checkBoxTitle, "RIGHT")
	checkBox:SetScript("OnClick", function(frame)
		if frame:GetChecked() then
			PlaySound("igMainMenuOptionCheckBoxOn")
			RID_TOONS_HIDE_IC = true
		else
			PlaySound("igMainMenuOptionCheckBoxOff")
			RID_TOONS_HIDE_IC = nil
			BNet_EnableToasts()
		end
	end)
	
	local formatBoxTitle1 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	formatBoxTitle1:SetPoint("TOPLEFT", 16, -68)
	formatBoxTitle1:SetText(L["Normal Format String:"])
	
	local formatBoxTitle2 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	formatBoxTitle2:SetPoint("TOPLEFT", 16, -110)
	formatBoxTitle2:SetText(L["Format String for Local Logins (same realm/faction):"])
	
	local function clearEditFocus(frame)
		frame:ClearFocus()
	end
	
	local formatBox1 = CreateFrame("EditBox", nil, options, "InputBoxTemplate")
	formatBox1:SetWidth(180)
	formatBox1:SetHeight(19)
	formatBox1:SetPoint("TOPLEFT", 16, -83)
	formatBox1:SetScript("OnEscapePressed", clearEditFocus)
	formatBox1:SetAutoFocus(false)
	
	local formatBox2 = CreateFrame("EditBox", nil, options, "InputBoxTemplate")
	formatBox2:SetWidth(180)
	formatBox2:SetHeight(19)
	formatBox2:SetPoint("TOPLEFT", 16, -126)
	formatBox2:SetScript("OnEscapePressed", clearEditFocus)
	formatBox2:SetAutoFocus(false)
	
	local formatBoxConfirm1 = CreateFrame("BUTTON", nil, options, "UIPanelButtonTemplate")
	formatBoxConfirm1:SetHeight(22)
	formatBoxConfirm1:SetWidth(80)
	formatBoxConfirm1:SetPoint("TOPLEFT", 200, -81)
	formatBoxConfirm1:SetText(ACCEPT)
	formatBoxConfirm1:Hide()
	formatBoxConfirm1:SetScript("OnClick", function(self)
		formatBox1:ClearFocus()
		RID_TOONS_FORMAT = formatBox1:GetText():gsub("||", "|")
		self:Hide()
	end)
	
	local formatBoxConfirm2 = CreateFrame("BUTTON", nil, options, "UIPanelButtonTemplate")
	formatBoxConfirm2:SetHeight(22)
	formatBoxConfirm2:SetWidth(80)
	formatBoxConfirm2:SetPoint("TOPLEFT", 200, -124)
	formatBoxConfirm2:SetText(ACCEPT)
	formatBoxConfirm2:Hide()
	formatBoxConfirm2:SetScript("OnClick", function(self)
		formatBox2:ClearFocus()
		RID_TOONS_LOCALFORMAT = formatBox2:GetText():gsub("||", "|")
		self:Hide()
	end)
	
	formatBox1:SetScript("OnShow", function(self)
		self:SetText(RID_TOONS_FORMAT:gsub("|", "||"))
		formatBoxConfirm1:Hide()
	end)
	formatBox1:SetScript("OnTextChanged", function()
		if not formatBoxConfirm1:IsVisible() then
			formatBoxConfirm1:Show()
		end
	end)
	formatBox2:SetScript("OnShow", function(self)
		self:SetText(RID_TOONS_LOCALFORMAT:gsub("|", "||"))
		formatBoxConfirm2:Hide()
	end)
	formatBox2:SetScript("OnTextChanged", function()
		if not formatBoxConfirm2:IsVisible() then
			formatBoxConfirm2:Show()
		end
	end)
	
	options:SetScript("OnShow", function(frame)
		if RID_TOONS_HIDE_IC then checkBox:SetChecked(true) end
	end)
	
	local START_OFFSET = -160
	local OFFSET_INCREMENT = 16
	local optionsHelpHeader = options:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	optionsHelpHeader:SetPoint("TOPLEFT", 16, START_OFFSET)
	optionsHelpHeader:SetText(L["The following substitutions are available for the format string:"])
	
	local optionsHelp1 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp1:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT))
	optionsHelp1:SetText(L["$t - Character Name, uncolored"])
	
	local optionsHelp2 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp2:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*2))
	optionsHelp2:SetText(L["$T - Character Name, class colored"])
	
	local optionsHelp3 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp3:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*3))
	optionsHelp3:SetText(L["$c - Class Name"])
	
	local optionsHelp4 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp4:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*4))
	optionsHelp4:SetText(L["$C - Class Name, class colored"])
	
	local optionsHelp5 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp5:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*5))
	optionsHelp5:SetWidth(400)
	optionsHelp5:SetHeight(30)
	optionsHelp5:SetJustifyH("LEFT")
	optionsHelp5:SetText(L["$s - Realm/Server Name (only displayed when different than the player's)"])
	
	local optionsHelp6 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp6:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*7))
	optionsHelp6:SetText(L["$S - Realm/Server Name (always displayed)"])
	
	local optionsHelp7 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp7:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*8))
	optionsHelp7:SetWidth(400)
	optionsHelp7:SetHeight(30)
	optionsHelp7:SetJustifyH("LEFT")
	optionsHelp7:SetText(L["$f - Faction Symbol (only displayed when different than the player, or from another server)"])
	
	local optionsHelp8 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp8:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*10))
	optionsHelp8:SetText(L["$F - Faction Symbol (always displayed)"])
	
	local optionsHelp9 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp9:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*11))
	optionsHelp9:SetText(L["$l - Character Level"])
	
	local optionsHelp10 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp10:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*12))
	optionsHelp10:SetText(L["$L - Character Level (colored by level difference)"])
	
	local optionsHelp11 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp11:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*13))
	optionsHelp11:SetText(L["$r - Character Race"])
	
	local optionsHelp12 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp12:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*14))
	optionsHelp12:SetText(L["$n - Friend Note (only displayed in Chat Alerts)"])
	
	local optionsHelp13 = options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	optionsHelp13:SetPoint("TOPLEFT", 26, START_OFFSET-(OFFSET_INCREMENT*15))
	optionsHelp13:SetText(L["$N - Friend Note (always displayed)"])
end