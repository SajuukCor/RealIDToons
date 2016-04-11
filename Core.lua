--[[
Author: Starinnia
RealID Toons - Add character information to the BNet alerts your RealID friends generate
$Date: 2016-04-10 15:34:42 -0500 (Sun, 10 Apr 2016) $
$Revision: 170 $
Project Version: @project-version@
contact: codemaster2010 AT gmail DOT com

Copyright (c) 2010-2016 Michael J. Murray aka Lyte of Lothar(US)
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
local BNET_CLIENT_WTCG = _G.BNET_CLIENT_WTCG
local BNET_CLIENT_HEROES = _G.BNET_CLIENT_HEROES
local BNET_CLIENT_APP = "App"
local BN_TOAST_MAX_LINE_WIDTH = 196
local BN_TOAST_TYPE_ONLINE = 1

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
local function constructToonName(bnetID, isChat)
	wipe(fmtTable) -- clear old info from the table
    local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, broadcastText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfoByID(bnetID)
    local hasFocus, characterName, client2, realmName, realmID, faction, race, class, guild, zoneName, level, gameText, broadcastText2, broadcastTime2, canSoR, toonID2, bnetIDAccount, isGameAFK, isGameBusy  = BNGetGameAccountInfo(toonID)
    
	local canCoop = CanCooperateWithGameAccount(toonID)
	
	--sometimes BNGetToonInfo does not return full info
	--when this occurs show a gray colored characterName name only
	if class == "" or realmName == "" then
		return format("(|cff%02x%02x%02x%s|r)", GRAY, GRAY, GRAY, characterName)
	end
	
	--$t - uncolored characterName name
	fmtTable.t = characterName
	
	--$T - class colored characterName name
	local eClass = reverseClassLookup[class]
	local r, g, b
	if _G.CUSTOM_CLASS_COLORS and _G.CUSTOM_CLASS_COLORS[eClass] then
		r, g, b = CUSTOM_CLASS_COLORS[eClass].r*255, CUSTOM_CLASS_COLORS[eClass].g*255, CUSTOM_CLASS_COLORS[eClass].b*255
	else
		r, g, b = RAID_CLASS_COLORS[eClass].r*255, RAID_CLASS_COLORS[eClass].g*255, RAID_CLASS_COLORS[eClass].b*255
	end
	
	if isChat and canCoop then
		--if same server and faction the characterName name should be a playerLink
		fmtTable.T = format("|Hplayer:%s|h|cff%02x%02x%02x%s|r|h", characterName, r, g, b, characterName)
	else
		fmtTable.T = format("|cff%02x%02x%02x%s|r", r, g, b, characterName)
	end
	
	--$c - uncolored class name
	fmtTable.c = class
	
	--$C - class colored class name
	fmtTable.C = format("|cff%02x%02x%02x%s|r", r, g, b, class)
	
	--$s - server only if different from player
	if realmName ~= MYREALM then
		fmtTable.s = realmName
	else
		fmtTable.s = ""
	end
	
	--$S - always show server
	fmtTable.S = realmName
	
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
		fmtTable.n = noteText
	else
		fmtTable.n = ""
	end
	
	--$N - always show the friend's note
	fmtTable.N = noteText
	
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
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
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
    --cache of online friends
    local onlineFriends = {}
    
    --helper function for printing BNet alerts to every frame that has them registered
	local function printToFrames(msg)
		for i, frame in ipairs(savedChatFrames) do
			frame:AddMessage(msg, info.r, info.g, info.b, info.id)
		end
	end
	
	function frame:BN_FRIEND_INFO_CHANGED(friendListIndex)
        -- no index passed by event, skip it
        if not friendListIndex then
            return
        end
        
        --get basic friend info
        local bnetID, presenceName, battleTag, isBattleTagPresence, toonName, gameAccountID, client, isOnline = BNGetFriendInfo(friendListIndex)
        
        --if not online, do not display anything, and clear our online cache
        if not isOnline then
            onlineFriends[bnetID] = nil
            return
        end
        
        local messageBase = BN_INLINE_TOAST_FRIEND_ONLINE
        
        --if the friend was online
        if onlineFriends[bnetID] then
            --and the same client
            if onlineFriends[bnetID] == client then
                --do nothing
                return
            else
                --otherwise, update the cached client
                onlineFriends[bnetID] = client
                
                --suppress messages about the BNet App, if the friend was already online
                --friends are considered in the App when switching WoW characters
                --this gets spammy
                if client == BNET_CLIENT_APP then
                    return
                end
            end
        else
            --if they were not already online, cache the current client
            onlineFriends[bnetID] = client
        end
        
        
		if client == BNET_CLIENT_WOW then
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", bnetID, presenceName, presenceName)
			local prefix = format(messageBase, playerlink)
			--add a message to the passed in chat frame that looks like the regular toast
			printToFrames(format("%s %s", prefix, constructToonName(bnetID, true)))
		elseif client == BNET_CLIENT_SC2 then
			--construct the playerlink and message prefix seperately for easier debugging
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", bnetID, presenceName, presenceName)
			local prefix = format(messageBase, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-SC2:14:14:0:-1|t)", prefix))
		elseif client == BNET_CLIENT_D3 then
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", bnetID, presenceName, presenceName)
			local prefix = format(messageBase, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-D3:14:14:0:-1|t)", prefix))
		elseif client == BNET_CLIENT_WTCG then
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", bnetID, presenceName, presenceName)
			local prefix = format(messageBase, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-WTCG:14:14:0:-1|t)", prefix))
		elseif client == BNET_CLIENT_HEROES then
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", bnetID, presenceName, presenceName)
			local prefix = format(messageBase, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-HotS:14:14:0:-1|t)", prefix))
		else
			local playerlink = format("|HRIDT:%s:%s|h[%s]|h", bnetID, presenceName, presenceName)
			local prefix = format(messageBase, playerlink)
			printToFrames(format("%s (|TInterface\\ChatFrame\\UI-ChatIcon-Battlenet:14:14:0:-1|t)", prefix))
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
		if BNToastFrame.toastType ~= BN_TOAST_TYPE_ONLINE then return end
		
		--hide Blizzard's game/toon info line
		BNToastFrameMiddleLine:Hide()
		BNToastFrameBottomLine:SetPoint("TOPLEFT", BNToastFrameTopLine, "BOTTOMLEFT", 0, -4);
		BNToastFrame:SetHeight(50);
		
		local hasFocus, characterName, client = BNGetGameAccountInfo(BNToastFrame.toastData)
		
		if client == BNET_CLIENT_WOW then
			local originalText = BNToastFrameTopLine:GetText()
			local toonName = constructToonName(BNToastFrame.toastData, false)
			BNToastFrameTopLine:SetFormattedText("%s %s", originalText, toonName)
			--size the popup to match the text
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		elseif client == BNET_CLIENT_SC2 then
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-Sc2icon:17|t", originalText)
			--size the popup to match the text
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		elseif client == BNET_CLIENT_D3 then
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-D3icon:17|t", originalText)
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		elseif client == BNET_CLIENT_WTCG then
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-WTCGicon:17|t", originalText)
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
		elseif client == BNET_CLIENT_HEROES then
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-HotSicon:17|t", originalText)
			if (BNToastFrameTopLine:GetStringWidth()) > (BN_TOAST_MAX_LINE_WIDTH - 10) then
				BNToastFrame:SetWidth(FRAME_PADDING+BNToastFrameTopLine:GetStringWidth())
				--make the animation glow effect fit the resized Toast popup
				BNToastFrameGlowFrame.glow:SetWidth(BNToastFrame:GetWidth()+2)
			end
        else
			local originalText = BNToastFrameTopLine:GetText()
			BNToastFrameTopLine:SetFormattedText("%s - |TInterface\\FriendsFrame\\Battlenet-Battleneticon:17|t", originalText)
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
			
			--Invite
			pMenuInfo.text = INVITE
			pMenuInfo.func = doInvite
			pMenuInfo.arg1 = self.character
			pMenuInfo.arg2 = nil
			pMenuInfo.disabled = (not CanCooperateWithGameAccount(self.characterID)) and 1
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
local function SetItemRefHook(link, text, button, chatFrame)
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
	end
end
hooksecurefunc("SetItemRef", SetItemRefHook)

--Hook the SetHyperlink method too, to squash Invalid Link errors
do
    local SetHyperlink = ItemRefTooltip.SetHyperlink
	function ItemRefTooltip:SetHyperlink(link, ...)
        local linktype, presenceID, name = strsplit(":", link)
        if linktype and linktype == "RIDT" then
            --noop
		else
			SetHyperlink(self, link, ...)
		end
	end
end
