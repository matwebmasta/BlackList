--[[
	BlackList UI - pfUI Integration
	
	This addon now supports visual integration with pfUI when it's active.
	When pfUI is detected, the BlackList frames will use pfUI's modern styling
	for consistency with the enhanced UI. When pfUI is not present, the addon
	falls back to standard Classic WoW styling.
	
	Integration features:
	- Automatic pfUI backdrop styling for main frames
	- pfUI checkbox styling for options
	- pfUI button styling where applicable
	- Maintains full compatibility without pfUI
--]]

local SelectedIndex = 1;
BLACKLISTS_TO_DISPLAY = 18;
FRIENDS_FRAME_BLACKLIST_HEIGHT = 16;

Classes = {"", "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"};
Races = {"", "Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Orc", "Undead", "Tauren", "Troll", "Blood Elf"};

-- pfUI Integration
local function IsPfUIActive()
	return pfUI and pfUI.api and pfUI.api.CreateBackdrop
end

function BlackList:ApplyPfUIStyle(frame)
	if IsPfUIActive() then
		-- Apply pfUI styling when available
		pfUI.api.CreateBackdrop(frame, nil, true)
		if frame.backdrop then
			frame.backdrop:SetFrameLevel(frame:GetFrameLevel())
		end
		
		-- Style buttons if pfUI has button styling
		if pfUI.api.SkinButton then
			local children = {frame:GetChildren()}
			for _, child in ipairs(children) do
				if child:GetObjectType() == "Button" and not child.pfuiStyled then
					pfUI.api.SkinButton(child)
					child.pfuiStyled = true
				end
			end
		end
	else
		-- Fallback to standard Classic styling
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
		frame:SetBackdropColor(0, 0, 0, 1)
	end
end

-- Phrase variables
PLAYER_IGNORING 			= "Player is ignoring you.";

PLAYER_NOT_FOUND			= "Player not found.";
ALREADY_BLACKLISTED		= "is already blacklisted.";
ADDED_TO_BLACKLIST		= "added to blacklist."
REMOVED_FROM_BLACKLIST		= "removed from blacklist."

BLACKLIST				= "BlackList";
BLACKLIST_PLAYER 			= "BlackList Player";
REMOVE_PLAYER 			= "Remove Player";
OPTIONS 				= "Options";
SHARE_LIST				= "Share List";

BLACK_LIST_DETAILS_OF		= "BlackList Details of";
LEVEL					= "Level";
BLACK_LISTED			= "BlackListed:";
REASON				= "Reason:";
IS_BLACKLISTED			= "is on your blacklist.";

BINDING_HEADER_BLACKLIST	= "BlackList";
BINDING_NAME_TOGGLE_BLACKLIST	= "Toggle BlackList";

-- Inserts all of the UI elements
function BlackList:InsertUI()

	-- Add tab buttons to Friends tab
	CreateFrame("Button", "FriendFrameToggleTab3", getglobal("FriendsListFrame"), "FriendsFrameToggleTab3");
	CreateFrame("Button", "IgnoreFrameToggleTab3", getglobal("IgnoreListFrame"), "IgnoreFrameToggleTab3");
	
	-- Add the tab itself
	table.insert(FRIENDSFRAME_SUBFRAMES, "BlackListFrame");
	CreateFrame("Frame", "BlackListFrame", getglobal("FriendsFrame"), "BlackListFrame");

	-- Create name prompt
	StaticPopupDialogs["BLACKLIST_PLAYER"] = {
		text = "Enter name of player to blacklist:",
		button1 = "Accept",
		button2 = "Cancel",
		OnShow = function()
			getglobal(this:GetName().."EditBox"):SetText("");
		end,
		OnAccept = function()
			BlackListPlayer(getglobal(this:GetParent():GetName().."EditBox"):GetText());
		end,
		hasEditBox = 1,
		timeout = 0,
		whileDead = 1,
		exclusive = 1,
		hideOnEscape = 1
		};

end

function BlackList:ClickBlackList()

	index = this:GetID();

	self:SetSelectedBlackList(index);

	self:UpdateUI();

	self:ShowDetails();

end

function BlackList:SetSelectedBlackList(index)

	SelectedIndex = index;

end

function BlackList:GetSelectedBlackList()

	return SelectedIndex;

end

function BlackList:ShowTab()

	FriendsFrameTopLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft");
	FriendsFrameTopRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight");
	FriendsFrameBottomLeft:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-BotLeft");
	FriendsFrameBottomRight:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-BotRight");
	FriendsFrameTitleText:SetText("Black List");
	FriendsFrame_ShowSubFrame("BlackListFrame");
	self:UpdateUI();

end

function BlackList:ToggleTab()

	ToggleFriendsFrame();

	if (BlackListFrame:IsVisible()) then
		BlackListFrame:Hide();
	else
		BlackList:ShowTab();
	end

end

function BlackList:ShowDetails()

	-- get player
	local player = self:GetPlayerByIndex(self:GetSelectedBlackList());

	-- update details
	getglobal("BlackListDetailsName"):SetText(BLACK_LIST_DETAILS_OF .. " " .. player["name"]);

	local level, race = "", "";
	if (player["level"] == "" and player["class"] == "") then
		level = "Unknown Level, Class";
	elseif (player["level"] == "") then
		level = "Unknown Level " .. player["class"];
	elseif (player["class"] == "") then
		level = "Level " .. player["level"] .. " Unknown Class";
	else
		level = "Level " .. player["level"] .. " " .. player["class"];
	end
	if (player["race"] == "") then
		race = "Unknown Race";
	else
		race = player["race"];
	end
	getglobal("BlackListDetailsLevel"):SetText(level);
	getglobal("BlackListDetailsRace"):SetText(race);

	if (GetFaction(player["race"]) == 1) then
		getglobal("BlackListDetailsFactionInsignia"):SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp");
		getglobal("BlackListDetailsFactionInsignia"):SetTexCoord(0, 0.5, 0, 1);
	elseif (GetFaction(player["race"]) == 2) then
		getglobal("BlackListDetailsFactionInsignia"):SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Factions.blp");
		getglobal("BlackListDetailsFactionInsignia"):SetTexCoord(0.5, 1, 0, 1);
	else
		getglobal("BlackListDetailsFactionInsignia"):SetTexture(0, 0, 0, 0);
	end

	local date = date("%I:%M%p on %b %d, 20%y", player["added"]);
	getglobal("BlackListDetailsBlackListedText"):SetText(date);

	-- update reason
	getglobal("BlackListDetailsFrameReasonTextBox"):SetText(player["reason"]);

	getglobal("BlackListDetailsFrame"):Show();

end

function BlackList_Update()

	BlackList:UpdateUI();

end

function BlackList:UpdateUI()

	local numBlackLists = BlackList:GetNumBlackLists();
	local nameText, name;
	local blacklistButton;
	local selectedBlackList = self:GetSelectedBlackList();

	if (numBlackLists > 0) then
		if (selectedBlackList == 0 or selectedBlackList > numBlackLists) then
			self:SetSelectedBlackList(1);
			selectedBlackList = 1;
		end
		FriendsFrameRemovePlayerButton:Enable();
	else
		FriendsFrameRemovePlayerButton:Disable();
	end

	local blacklistOffset = FauxScrollFrame_GetOffset(FriendsFrameBlackListScrollFrame);
	local blacklistIndex;
	for i=1, BLACKLISTS_TO_DISPLAY, 1 do
		blacklistIndex = i + blacklistOffset;
		nameText = getglobal("FriendsFrameBlackListButton" .. i .. "ButtonTextName");
		nameText:SetText(self:GetNameByIndex(blacklistIndex));
		blacklistButton = getglobal("FriendsFrameBlackListButton" .. i);
		blacklistButton:SetID(blacklistIndex);

		-- Update the highlight
		if (blacklistIndex == selectedBlackList) then
			blacklistButton:LockHighlight();
		else
			blacklistButton:UnlockHighlight();
		end

		if (blacklistIndex > numBlackLists) then
			blacklistButton:Hide();
		else
			blacklistButton:Show();
		end
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(FriendsFrameBlackListScrollFrame, numBlackLists, BLACKLISTS_TO_DISPLAY, FRIENDS_FRAME_BLACKLIST_HEIGHT);

end

function BlackList:ShowOptions()
	BlackListOptionsFrame:Show();
	self:UpdateOptionsUI();
end

function BlackList:ToggleOption(optionName, value)
	if (not BlackListOptions) then
		BlackListOptions = {};
	end
	BlackListOptions[optionName] = value;
end

function BlackList:GetOption(optionName, defaultValue)
	if (not BlackListOptions) then
		BlackListOptions = {};
	end
	if (BlackListOptions[optionName] == nil) then
		return defaultValue;
	end
	return BlackListOptions[optionName];
end

function BlackList:UpdateOptionsUI()
	-- Set default values if not set
	getglobal("BlackListOptionsCheckButton1"):SetChecked(self:GetOption("playSounds", true));
	getglobal("BlackListOptionsCheckButton2"):SetChecked(self:GetOption("warnTarget", true));
	getglobal("BlackListOptionsCheckButton3"):SetChecked(self:GetOption("preventWhispers", true));
	getglobal("BlackListOptionsCheckButton4"):SetChecked(self:GetOption("warnWhispers", true));
	getglobal("BlackListOptionsCheckButton5"):SetChecked(self:GetOption("preventInvites", true));
	getglobal("BlackListOptionsCheckButton6"):SetChecked(self:GetOption("preventMyInvites", false));
	getglobal("BlackListOptionsCheckButton7"):SetChecked(self:GetOption("warnPartyJoin", true));
	
	-- Apply pfUI styling to checkboxes if available
	self:StyleOptionsCheckboxes();
end

function BlackList:StyleOptionsCheckboxes()
	if IsPfUIActive() and pfUI.api.SkinCheckBox then
		for i = 1, 7 do
			local checkbox = getglobal("BlackListOptionsCheckButton" .. i);
			if checkbox and not checkbox.pfuiStyled then
				pfUI.api.SkinCheckBox(checkbox);
				checkbox.pfuiStyled = true;
			end
		end
	end
end