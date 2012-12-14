--[[
Author: Starinnia
RealID Toons - Add character information to the BNet alerts your RealID friends generate
$Date: 2012-09-23 10:19:57 -0500 (Sun, 23 Sep 2012) $
$Revision: 141 $
Project Version: @project-version@
contact: codemaster2010 AT gmail DOT com

Copyright (c) 2010-2012 Michael J. Murray aka Lyte of Lothar(US)
All rights reserved unless otherwise explicitly stated.
]]

--Upvalues
local format = string.format
local gsub = string.gsub
local strsplit = strsplit
local ipairs = ipairs
local select = select
local BNET_CLIENT_SC2 = _G.BNET_CLIENT_SC2
local BNET_CLIENT_WOW = _G.BNET_CLIENT_WOW
local BNET_CLIENT_D3 = _G.BNET_CLIENT_D3

--constants
local GRAY = 0.63*255
local MYREALM = GetRealmName()

--create a reverse lookup from localized classes to english names
--we need the english names to get the class colors
local reverseClassLookup = {}
for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
	reverseClassLookup[v] = k
end
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	reverseClassLookup[v] = k
end

--pass in the toonID of the friend
--from this we can obtain the character name, realm, class, and faction
--[[
Substitutions for the format string are as follows:
$t - Character Name, uncolored
$T - Class Colored Character Name
$c - Class name
$C - Class Colored class name
$s - Realm (server) Name (only if different than the player's)
$S - Realm (server) Name (Always)
$f - Faction symbol (only if different from player, or on another server)
$F - Faction symbol (Always)
$l - Character level
$L - Character level (difficulty colored)
$r - Character race
$n - Friend note (only shown in Chat alerts)
$N - Friend note (always shown)
--]]
local fmtTable = {}
local function constructToonName(toonID, presenceID, isChat)
	wipe(fmtTable) -- clear old info from the table
	local _, toon, _, realm, _, faction, race, class, _, _, level = BNGetToonInfo(toonID)
	local note = select(13, BNGetFriendInfoByID(presenceID))
	local canCoop = CanCooperateWithToon(toonID)
	
	--sometimes BNGetToonInfo does not return full info
	--when this occurs show a gray colored toon name only
	if class == "" or realm == "" then
		return format("(|cff%02x%02x%02x%s|r)", GRAY, GRAY, GRAY, toon)
	end
	
	--$t - uncolored toon name
	fmtTable.t = toon
	
	--$T - class colored toon name
	local eClass = reverseClassLookup[class]
	local r, g, b
	if _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[eClass] then
		r, g, b = CUSTOM_CLASS_COLORS[eClass].r*255, CUSTOM_CLASS_COLORS[eClass].g*255, CUSTOM_CLASS_COLORS[eClass].b*255
	else
		r, g, b = RAID_CLASS_COLORS[eClass].r*255, RAID_CLASS_COLORS[eClass].g*255, RAID_CLASS_COLORS[eClass].b*255
	end
	
	if isChat and canCoop then
		--if same server and faction the toon name should be a playerLink
		fmtTable.T = format("|Hplayer:%s|h|cff%02x%02x%02x%s|r|h", toon, r, g, b, toon)
	else
		fmtTable.T = format("|cff%02x%02x%02x%s|r", r, g, b, toon)
	end
	
	--$c - uncolored class name
	fmtTable.c = class
	
	--$C - class colored class name
	fmtTable.C = format("|cff%02x%02x%02x%s|r", r, g, b, class)
	
	--$s - server only if different from player
	if realm ~= MYREALM then
		fmtTable.s = realm
	else
		fmtTable.s = ""
	end
	
	--$S - always show server
	fmtTable.S = realm
	
	--$F - always show faction icon
	if faction == "Horde" then
		fmtTable.F = "|TInterface\\TargetingFrame\\UI-PVP-Horde:12:12:0:0:64:64:4:37:4:36|t"
	elseif faction == "Alliance" then
		fmtTable.F = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:10:0:0:64:64:10:31:3:37|t"
	elseif faction == "Neutral" then
		fmtTable.F = "|TInterface\\TargetingFrame\\UI-PVP-FFA:14:10:0:0:64:64:10:31:0:37|t" --Pandaren on the Wandering Isle
	else
		--edge case, sometimes we have no faction info
		fmtTable.F = ""
	end
	
	--$f - faction icon only if different or different server
	if not canCoop then
		fmtTable.f = fmtTable.F
	else
		fmtTable.f = ""
	end
	
	--$l - uncolored level
	fmtTable.l = level
	
	--$L - level colored by "difficulty"
	local color = GetQuestDifficultyColor(level)
	fmtTable.L = format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, level)
	
	--$r - friend's race
	fmtTable.r = race
	
	--$n - friend's note, only if alert is in chat
	if isChat then
		fmtTable.n = note
	else
		fmtTable.n = ""
	end
	
	--$N - always show the friend's note
	fmtTable.N = note
	
	if canCoop then
		return gsub(RID_TOONS_LOCALFORMAT, "%$([A-Za-z])", fmtTable)
	else
		return gsub(RID_TOONS_FORMAT, "%$([A-Za-z])", fmtTable)
	end
end

--Hide the Blizzard alert completely
--We can't hijack this alert since they have escaped the real name information
--due to security concerns
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_INLINE_TOAST_ALERT", function(self, event, msg, author, ...)
	--the only toast we care about is FRIEND_ONLINE
	if msg == "FRIEND_ONLINE" then
		return true, msg, author, ...
	else
		return false, msg, author, ...
	end	
end)

local info = ChatTypeInfo["BN_INLINE_TOAST_ALERT"]
local savedChatFrames = {} --chat frames that register the BN Alerts
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
frame:RegisterEvent("UPDATE_CHAT_WINDOWS")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end	
end)

function frame:ADDON_LOADED(addon)
	--make sure the format strings are given their defaults before any BN alerts get through
	if addon == "RealIDToons" then
		if not RID_TOONS_FORMAT then
			RID_TOONS_FORMAT = "($F $t - $S)"
		end
		
		if not RID_TOONS_LOCALFORMAT then
			RID_TOONS_LOCALFORMAT = "($T)"
		end
	end
end

do
	local function printToFrames(msg)
		for i, frame in ipairs(savedChatFrames) do
			frame:AddMessage(msg, info.r, info.g, info.b, info.id)
		end
	end
	
	function frame:BN_FRIEND_ACCOUNT_ONLINE(presenceID)
		local _, presenceName, battleTag, isTagID, toon, toonID, client = BNGetFriendInfoByID(presenceID)
		
		if client == BNET_CLIENT_WOW then
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", presenceID, presenceName, presenceName)
			local prefix = format(BN_INLINE_TOAST_FRIEND_ONLINE, playerlink)
			--add a message to the passed in chat frame that looks like the regular toast
			printToFrames(format("%s %s", prefix, constructToonName(toonID, presenceID, true)))
		elseif client == BNET_CLIENT_SC2 then
			--construct the playerlink and message prefix seperately for easier debugging
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", presenceID, presenceName, presenceName)
			local prefix = format(BN_INLINE_TOAST_FRIEND_ONLINE, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-SC2:14:14:0:-1|t %s)", prefix, toon))
		elseif client == BNET_CLIENT_D3 then
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", presenceID, presenceName, presenceName)
			local prefix = format(BN_INLINE_TOAST_FRIEND_ONLINE, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-D3:14:14:0:-1|t %s)", prefix, toon))
		end
	end
end

--Borrowed from Rabbit's Broker_GuildMoney
do
	local function hasLoginAlert(...)
		for i = 1, select("#", ...) do
			if (select(i, ...)) == "BN_INLINE_TOAST_ALERT" then return true end
		end
	end
	
	function frame:UPDATE_CHAT_WINDOWS()
		wipe(savedChatFrames)
		for i, name in ipairs(CHAT_FRAMES) do
			if hasLoginAlert(GetChatWindowMessages(i)) then
				savedChatFrames[#savedChatFrames + 1] = _G[name]
			end
		end
	end
end

function frame:PLAYER_REGEN_DISABLED()
	if RID_TOONS_HIDE_IC then
		BNet_DisableToasts()
	end
end

function frame:PLAYER_REGEN_ENABLED()
	if RID_TOONS_HIDE_IC then
		BNet_EnableToasts()
	end
end

do
	local FRAME_PADDING = 65
	hooksecurefunc("BNToastFrame_Show", function()
		BNToastFrame:SetWidth(250) -- Need to reset to original value for popups we are not modifying
		BNToastFrameGlowFrame.glow:SetWidth(252)
		if BNToastFrame.toastType ~= 1 then return end
		
		--hide Blizzard's game/toon info line
		BNToastFrameMiddleLine:Hide()
		BNToastFrameBottomLine:SetPoint("TOPLEFT", BNToastFrameTopLine, "BOTTOMLEFT", 0, -4);
		BNToastFrame:SetHeight(50);
		
		local _, _, _, _, toon, toonID, client = BNGetFriendInfoByID(BNToastFrame.toastData)
		
		if client == BNET_CLIENT_WOW then
			local originalText = BNToastFrameTopLine:GetText()
			local toonName = constructToonName(toonID, BNToastFrame.toastData, false)
			BNToastFrameTopLine:SetFormattedText("%s %s", originalText, toonName)
			--size the popup to match the text
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		elseif client == BNET_CLIENT_SC2 then
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-Sc2icon:17|t %s", originalText, toon)
			--size the popup to match the text
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		elseif client == BNET_CLIENT_D3 then
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-D3icon:17|t %s", originalText, toon)
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		end
	end)
end

--create a custom popup menu for player right clicks on the
--custom links from the logon alerts
--using default was broken by the new privacy features
--and hooking led to taint issues
local popupMenuFrame
do
	local function closeAll() CloseDropDownMenus() end
	
	local function doWhisper(dropdownbutton, name, chatFrame, checked)
		ChatFrame_SendSmartTell(name, chatFrame)
	end
	
	local function doConversation(dropdownbutton, presenceID, arg2, checked)
		BNConversationInvite_NewConversation(presenceID)
	end
	
	local function doInvite(dropdownbutton, name, arg2, checked)
		InviteUnit(name)
	end
	
	local function UncheckHack(dropdownbutton)
		_G[dropdownbutton:GetName().."Check"]:Hide()
	end
	
	local function doBNetReport(dropdownbutton, presenceID, kind, checked)
		BNet_InitiateReport(presenceID, kind)
	end
	
	popupMenuFrame = CreateFrame("FRAME", "RIDToons_PopupMenu")
	popupMenuFrame.displayMode = "MENU"
	local pMenuInfo = {}
	popupMenuFrame.initialize = function(self, level)
		if not level then return end
		wipe(pMenuInfo)
		
		if level == 1 then
			--title
			pMenuInfo.isTitle = 1
			pMenuInfo.text = self.author
			pMenuInfo.notCheckable = 1
			UIDropDownMenu_AddButton(pMenuInfo, level)
			
			pMenuInfo.disabled = nil
			pMenuInfo.isTitle = nil
			
			--whisper
			pMenuInfo.text = WHISPER
			pMenuInfo.func = doWhisper
			pMenuInfo.arg1 = self.author
			pMenuInfo.arg2 = self.chatFrame
			UIDropDownMenu_AddButton(pMenuInfo, level)
			
			--create conversation
			pMenuInfo.text = CREATE_CONVERSATION_WITH
			pMenuInfo.func = doConversation
			pMenuInfo.arg1 = self.presenceID
			pMenuInfo.arg2 = nil
			UIDropDownMenu_AddButton(pMenuInfo, level)
			
			--Invite
			pMenuInfo.text = INVITE
			pMenuInfo.func = doInvite
			pMenuInfo.arg1 = self.character
			pMenuInfo.arg2 = nil
			pMenuInfo.disabled = (not CanCooperateWithToon(self.characterID)) and 1
			UIDropDownMenu_AddButton(pMenuInfo, level)
			
			pMenuInfo.disabled = nil
			pMenuInfo.keepShownOnClick = 1
			
			--Report
			pMenuInfo.text = BNET_REPORT
			pMenuInfo.hasArrow = 1
			pMenuInfo.value = "reportMenu"
			pMenuInfo.func = UncheckHack
			UIDropDownMenu_AddButton(pMenuInfo, level)
			
			pMenuInfo.value = nil
			pMenuInfo.hasArrow = nil
			
			--close the menu
			pMenuInfo.text = CANCEL
			pMenuInfo.func = closeAll
			pMenuInfo.checked = nil
			pMenuInfo.keepShownOnClick = nil
			pMenuInfo.notCheckable = 1
			UIDropDownMenu_AddButton(pMenuInfo, level)
		elseif level == 2 then
			if UIDROPDOWNMENU_MENU_VALUE == "reportMenu" then
				pMenuInfo.notCheckable = nil
				
				--report spam
				pMenuInfo.text = BNET_REPORT_SPAM
				pMenuInfo.func = doBNetReport
				pMenuInfo.arg1 = self.presenceID
				pMenuInfo.arg2 = "SPAM"
				UIDropDownMenu_AddButton(pMenuInfo, level)
				
				--report abuse
				pMenuInfo.text = BNET_REPORT_ABUSE
				pMenuInfo.arg2 = "ABUSE"
				UIDropDownMenu_AddButton(pMenuInfo, level)
				
				--report name
				pMenuInfo.text = BNET_REPORT_NAME
				pMenuInfo.arg2 = "NAME"
				UIDropDownMenu_AddButton(pMenuInfo, level)
			end
		end
	end
end

--we have a custom link type to avoid tainting the dropdown
--this allows the addon to circumvent the issues with the FriendsFrame_ShowBNDropdown
--call that is in ItemRef.lua of the default UI
--|HRIDT:presenceID:name|h[name]|h
local oldSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
	local linktype, presenceID, name = strsplit(":", link)
	if linktype == "RIDT" then
		if button == "RightButton" then
			if not BNIsSelf(presenceID) then
				local _, _, _, _, toon, toonID = BNGetFriendInfoByID(presenceID)
				popupMenuFrame.author = name
				popupMenuFrame.chatFrame = chatFrame
				popupMenuFrame.presenceID = presenceID
				popupMenuFrame.character = toon
				popupMenuFrame.characterID = toonID
				ToggleDropDownMenu(1, nil, RIDToons_PopupMenu, "cursor");
			end
		elseif button == "LeftButton" then
			ChatFrame_SendSmartTell(name, chatFrame)
		end
	else
		return oldSetItemRef(link, text, button, chatFrame)
	end
end
