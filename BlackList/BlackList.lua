BlackList = {};

BlackList_Blocked_Channels = {"SAY", "YELL", "WHISPER", "PARTY", "RAID", "RAID_WARNING", "GUILD", "OFFICER", "EMOTE", "TEXT_EMOTE", "CHANNEL", "CHANNEL_JOIN", "CHANNEL_LEAVE"};

Already_Warned_For = {};
Already_Warned_For["WHISPER"] = {};
Already_Warned_For["TARGET"] = {};
Already_Warned_For["PARTY_INVITE"] = {};
Already_Warned_For["PARTY"] = {};

BlackListedPlayers = {};

local SLASH_TYPE_ADD = 1;
local SLASH_TYPE_REMOVE = 2;

-- Function to handle onload event
function BlackList:OnLoad()

	-- constructions
	self:InsertUI();
	self:RegisterEvents();
	self:HookFunctions();
	self:RegisterSlashCmds();

	-- Disable share list button if it exists
	if FriendsFrameShareListButton then
		FriendsFrameShareListButton:Disable();
	end
	
	-- Initialize pfUI integration if available
	if InitializePfUIIntegration then
		InitializePfUIIntegration();
	end
	
	-- Create minimap button
	self:CreateMinimapButton();

end

-- Registers events to be recieved
function BlackList:RegisterEvents()

	local frame = getglobal("BlackListTopFrame");

	-- register events
	frame:RegisterEvent("VARIABLES_LOADED");
	frame:RegisterEvent("PLAYER_TARGET_CHANGED");
	frame:RegisterEvent("PARTY_INVITE_REQUEST");
	frame:RegisterEvent("PARTY_MEMBERS_CHANGED");

end

local Orig_ChatFrame_OnEvent;
local Orig_InviteByName;

-- Hooks onto the functions needed
function BlackList:HookFunctions()

	Orig_ChatFrame_OnEvent = ChatFrame_OnEvent;
	ChatFrame_OnEvent = BlackList_ChatFrame_OnEvent;

	Orig_InviteByName = InviteByName;
	InviteByName = BlackList_InviteByName;
	
	DEFAULT_CHAT_FRAME:AddMessage("BlackList: Hooks installed", 0, 1, 0);

end

-- Hooked ChatFrame_OnEvent function (like SuperIgnore does)
function BlackList_ChatFrame_OnEvent(event)
	
	-- Handle whisper blocking/warning
	if event == "CHAT_MSG_WHISPER" then
		local name = arg2;
		
		if (BlackList:GetIndexByName(name) > 0) then
			local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name));
			
			-- Always warn about whispers from blacklisted players (if enabled)
			if (BlackList:GetOption("warnWhispers", true)) then
				local alreadywarned = false;
				
				for key, warnedname in pairs(Already_Warned_For["WHISPER"]) do
					if (name == warnedname) then
						alreadywarned = true;
					end
				end
				
				if (not alreadywarned) then
					table.insert(Already_Warned_For["WHISPER"], name);
					BlackList:AddMessage("BlackList: " .. name .. " is blacklisted and whispered you.", "yellow");
				end
			end
			
			-- Check if we should block whispers
			if (BlackList:GetOption("preventWhispers", true)) then
				-- Block the whisper by not calling the original handler (no auto-reply)
				return;
			end
			
			-- If not blocking, call the original handler to display the whisper
			Orig_ChatFrame_OnEvent(event);
			return;
		end
	end
	
	-- Call the original handler for non-blacklisted messages
	Orig_ChatFrame_OnEvent(event);
end

-- Old MessageEventHandler function - DEPRECATED, keeping for reference
function BlackList_MessageEventHandler(event)

	local warnplayer, warnname = false, nil;

	if (strsub(event, 1, 8) == "CHAT_MSG") then
		local type = strsub(event, 10);

		for key, channel in pairs(BlackList_Blocked_Channels) do
			if (type == channel) then
				-- search for player name
				local name = arg2;
				
				if (BlackList:GetIndexByName(name) > 0) then
					local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name));
					
					-- Check if we should block whispers
					if (type == "WHISPER" and BlackList:GetOption("preventWhispers", true)) then
						-- respond to whisper
						if (name ~= UnitName("player")) then
							SendChatMessage(PLAYER_IGNORING, "WHISPER", nil, name);
						end
						-- block communication
						return;
					end
					
					-- Check if we should warn about whispers (independent of blocking)
					if (type == "WHISPER" and BlackList:GetOption("warnWhispers", true)) then
						local alreadywarned = false;

						for key, warnedname in pairs(Already_Warned_For["WHISPER"]) do
							if (name == warnedname) then
								alreadywarned = true;
							end
						end

						if (not alreadywarned) then
							table.insert(Already_Warned_For["WHISPER"], name);
							warnplayer = true;
							warnname = name;
							DEFAULT_CHAT_FRAME:AddMessage("BlackList DEBUG: Setting up warning for " .. name, 0.5, 0.5, 0.5);
						end
					end
				end
			end
		end
	end

	local returnvalue = Orig_ChatFrame_MessageEventHandler(event);

	if (warnplayer) then
		BlackList:AddMessage("BlackList: " .. warnname .. " is blacklisted and whispered you.", "yellow");
	end

	return returnvalue;

end

-- Hooked InviteByName function
function BlackList_InviteByName(name)

	if (BlackList:GetOption("preventMyInvites", true)) then
		if (BlackList:GetIndexByName(name) > 0) then
			BlackList:AddMessage("BlackList: " .. name .. " is blacklisted, preventing you from inviting them.", "yellow");
			return;
		end
	end

	Orig_InviteByName(name);

end

-- Registers slash cmds
function BlackList:RegisterSlashCmds()

	SlashCmdList["BlackList"]   = function(args)
							BlackList:HandleSlashCmd(SLASH_TYPE_ADD, args)
						end;
	SLASH_BlackList1 = "/blacklist";
	SLASH_BlackList2 = "/bl";

	SlashCmdList["RemoveBlackList"]   = function(args)
								BlackList:HandleSlashCmd(SLASH_TYPE_REMOVE, args)
							end;
	SLASH_RemoveBlackList1 = "/removeblacklist";
	SLASH_RemoveBlackList2 = "/removebl";

end

-- Handles the slash cmds
function BlackList:HandleSlashCmd(type, args)

	if (type == SLASH_TYPE_ADD) then
		if (args == "") then
			self:AddPlayer("target");
		else
			local name = args;
			local reason = "";
			local index = string.find(args, " ", 1, true);
			if (index) then
				-- space found, have reason in args
				name = string.sub(args, 1, index - 1);
				reason = string.sub(args, index + 1);
			end

			self:AddPlayer(name, nil, nil, reason);
		end
	elseif (type == SLASH_TYPE_REMOVE) then
		if (args == "") then
			self:RemovePlayer("target");
		else
			self:RemovePlayer(args);
		end
	end

end

-- Function to handle events
function BlackList:HandleEvent(event)

	if (event == "VARIABLES_LOADED") then
		if (not BlackListedPlayers[GetRealmName()]) then
			BlackListedPlayers[GetRealmName()] = {};
		end
		if (not BlackListOptions) then
			BlackListOptions = {};
		end
	elseif (event == "PLAYER_TARGET_CHANGED") then
		-- search for player name
		local name = UnitName("target");
		local faction, localizedFaction = UnitFactionGroup("target");
		if (BlackList:GetIndexByName(name) > 0) then
			local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name));

			if (BlackList:GetOption("warnTarget", true)) then
				-- warn player
				local alreadywarned = false;

				for warnedname, timepassed in pairs(Already_Warned_For["TARGET"]) do
					if ((name == warnedname) and (GetTime() < timepassed+10)) then
						alreadywarned = true;
					end
				end

				if (not alreadywarned) then
					Already_Warned_For["TARGET"][name]=GetTime();
					if (BlackList:GetOption("playSounds", true)) then
						PlaySound("PVPTHROUGHQUEUE");
					end
					BlackList:AddMessage("BlackList: " .. name .. " is blacklisted - " .. player["reason"], "yellow");
				end
			end
		end
	elseif (event == "PARTY_INVITE_REQUEST") then
		-- search for player name
		local name = arg1;
		if (BlackList:GetIndexByName(name) > 0) then
			local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name));

			if (BlackList:GetOption("preventInvites", false)) then
				-- decline party invite
				DeclineGroup();
				StaticPopup_Hide("PARTY_INVITE");
				BlackList:AddMessage("BlackList: Declined party invite from blacklisted player " .. name .. ".", "yellow");
			else
				-- warn player
				local alreadywarned = false;

				for key, warnedname in pairs(Already_Warned_For["PARTY_INVITE"]) do
					if (name == warnedname) then
						alreadywarned = true;
					end
				end

				if (not alreadywarned) then
					table.insert(Already_Warned_For["PARTY_INVITE"], name);
					BlackList:AddMessage("BlackList: " .. name .. " is blacklisted and invited you to a party.", "yellow");
				end
			end
		end
	elseif (event == "PARTY_MEMBERS_CHANGED") then
		for i = 0, GetNumPartyMembers(), 1 do
			-- search for player name
			local name = UnitName("party" .. i);
			if (BlackList:GetIndexByName(name) > 0) then
				local player = BlackList:GetPlayerByIndex(BlackList:GetIndexByName(name));

				if (BlackList:GetOption("warnPartyJoin", true)) then
					-- warn player
					local alreadywarned = false;

					for key, warnedname in pairs(Already_Warned_For["PARTY"]) do
						if (name == warnedname) then
							alreadywarned = true;
						end
					end

					if (not alreadywarned) then
						table.insert(Already_Warned_For["PARTY"], name);
						
						-- Play warning sound if enabled
						if (BlackList:GetOption("playSounds", true)) then
							PlaySound("RaidWarning");
						end
						
						-- Display prominent multi-line warning
						BlackList:AddMessage("==========================================", "yellow");
						BlackList:AddMessage("WARNING: Blacklisted player in your party!", "yellow");
						BlackList:AddMessage(name .. " is blacklisted!", "yellow");
						if player["reason"] and player["reason"] ~= "" then
							BlackList:AddMessage("Reason: " .. player["reason"], "yellow");
						end
						BlackList:AddMessage("==========================================", "yellow");
					end
				end
			end
		end
	end

end

-- Blacklists the given player, sets the ignore flag to be 'ignore' and enters the given reason
function BlackListPlayer(player, reason)

	BlackList:AddPlayer(player, reason);

end

-- Create minimap button
function BlackList:CreateMinimapButton()
	local button = CreateFrame("Button", "BlackListMinimapButton", Minimap)
	button:SetWidth(31)
	button:SetHeight(31)
	button:SetFrameStrata("MEDIUM")
	button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -10, 10)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	
	-- Icon
	local icon = button:CreateTexture(nil, "BACKGROUND")
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetPoint("CENTER", 0, 1)
	icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
	
	-- Border
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetWidth(53)
	overlay:SetHeight(53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT", -2, 2)
	
	-- Click handler
	button:SetScript("OnClick", function()
		if arg1 == "LeftButton" then
			BlackList:ToggleStandaloneWindow()
		elseif arg1 == "RightButton" then
			BlackList:ShowNewOptions()
		end
	end)
	
	-- Drag handler
	button:SetScript("OnDragStart", function()
		this:StartMoving()
	end)
	
	button:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
	end)
	
	-- Tooltip
	button:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:AddLine("BlackList")
		GameTooltip:AddLine("Left-click: Toggle BlackList", 1, 1, 1)
		GameTooltip:AddLine("Right-click: Options", 1, 1, 1)
		GameTooltip:Show()
	end)
	
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	DEFAULT_CHAT_FRAME:AddMessage("BlackList: Minimap button created", 0, 1, 0)
end