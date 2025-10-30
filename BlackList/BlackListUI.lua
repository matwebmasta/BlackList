--[[
	BlackList UI - pfUI Integration
	
	This addon now supports visual integration with pfUI when it's active.
	When pfUI is detected, BlackList uses the same styling approach as pfUI:
	hooking into frame creation and applying consistent styling patterns.
	
	Integration features:
	- Hooks into BlackList frame initialization like pfUI does for Blizzard frames
	- Uses pfUI's SkinTab, CreateBackdrop, and SkinButton functions
	- Maintains full compatibility without pfUI
--]]

local SelectedIndex = 1;
BLACKLISTS_TO_DISPLAY = 18;
FRIENDS_FRAME_BLACKLIST_HEIGHT = 16;

Classes = {"", "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior"};
Races = {"", "Human", "Dwarf", "Night Elf", "Gnome", "Draenei", "Orc", "Undead", "Tauren", "Troll", "Blood Elf"};

-- pfUI Integration - Modern approach using hooks like pfUI does
local function IsPfUIActive()
	return pfUI and pfUI.api and pfUI.api.CreateBackdrop
end

local function StyleBlackListFrames()
	if not IsPfUIActive() then return end
	
	-- Style the main options frame
	if BlackListOptionsFrame and not BlackListOptionsFrame.pfuiStyled then
		pfUI.api.CreateBackdrop(BlackListOptionsFrame, nil, true)
		pfUI.api.CreateBackdropShadow(BlackListOptionsFrame)
		BlackListOptionsFrame.pfuiStyled = true
	end
	
	-- Style the details frame  
	if BlackListDetailsFrame and not BlackListDetailsFrame.pfuiStyled then
		pfUI.api.CreateBackdrop(BlackListDetailsFrame, nil, true)
		pfUI.api.CreateBackdropShadow(BlackListDetailsFrame)
		BlackListDetailsFrame.pfuiStyled = true
	end
	
	-- Style the BlackList tab to match other tabs
	if BlackListFrameToggleTab3 and not BlackListFrameToggleTab3.pfuiStyled then
		pfUI.api.SkinTab(BlackListFrameToggleTab3)
		BlackListFrameToggleTab3.pfuiStyled = true
	end
end

-- SuperIgnore-style Options System
local BlackListOptionsFrame_New = nil

local function CreateBlackListFrame(name, width, parent, x, y)
	local f = CreateFrame("Frame", name, parent)
	f:SetWidth(width)
	f:SetHeight(400)  -- Set a reasonable height
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		tile = true, tileSize = 32,
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	f:SetPoint("CENTER", UIParent, "CENTER", x or 0, y or 0)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function() this:StartMoving() end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	f:Hide()
	
	-- Apply pfUI styling if available
	if IsPfUIActive() then
		pfUI.api.CreateBackdrop(f, nil, true)
		if pfUI.api.CreateBackdropShadow then
			pfUI.api.CreateBackdropShadow(f)
		end
	end
	
	return f
end

local function CreateBlackListHeader(frame, text, fontSize, pad)
	local t = frame:CreateFontString(nil, "OVERLAY", frame)
	t:SetPoint("TOP", frame, "TOP", 0, pad)
	t:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
	t:SetTextColor(1, 0.82, 0)  -- Gold color like SuperIgnore
	t:SetText(text)
	return t
end

local function CreateBlackListOption(frame, name, desc, pad, onclick)
	local c = CreateFrame("CheckButton", name, frame, "UICheckButtonTemplate")
	c:SetHeight(20)
	c:SetWidth(20)
	c:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, pad)
	c:SetScript("OnClick", function()
		onclick(c:GetChecked())
	end)
	
	-- Apply pfUI styling if available
	if IsPfUIActive() and pfUI.api.SkinCheckbox then
		pfUI.api.SkinCheckbox(c)
	end
	
	local ct = frame:CreateFontString(nil, "OVERLAY", frame)
	ct:SetPoint("LEFT", c, "RIGHT", 5, 0)
	ct:SetFont("Fonts\\FRIZQT__.TTF", 11)
	ct:SetTextColor(1, 1, 1)  -- White text
	ct:SetText(desc)
	
	return c, ct
end

local function CreateBlackListCloseButton(frame)
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
	closeBtn:SetScript("OnClick", function() frame:Hide() end)
	
	-- Apply pfUI styling if available
	if IsPfUIActive() and pfUI.api.SkinCloseButton then
		pfUI.api.SkinCloseButton(closeBtn, frame)
	end
	
	return closeBtn
end

local function CreateNewOptionsFrame()
	if BlackListOptionsFrame_New then
		return BlackListOptionsFrame_New
	end
	
	-- Create the main frame
	BlackListOptionsFrame_New = CreateBlackListFrame("BlackListOptionsFrame_New", 300, UIParent, 0, 0)
	local f = BlackListOptionsFrame_New
	
	-- Add close button
	CreateBlackListCloseButton(f)
	
	local pad = -20
	
	-- Title
	CreateBlackListHeader(f, "BlackList Options", 14, pad)
	pad = pad - 30
	
	-- General Settings Section
	CreateBlackListHeader(f, "General Settings", 12, pad)
	pad = pad - 25
	
	local playSounds, playSoundsText = CreateBlackListOption(f, "BL_PlaySounds", "Play warning sounds", pad, function(checked)
		BlackList:ToggleOption("playSounds", checked)
	end)
	pad = pad - 25
	
	local warnTarget, warnTargetText = CreateBlackListOption(f, "BL_WarnTarget", "Warn when targeting blacklisted players", pad, function(checked)
		BlackList:ToggleOption("warnTarget", checked)
	end)
	pad = pad - 35
	
	-- Communication Section
	CreateBlackListHeader(f, "Communication", 12, pad)
	pad = pad - 25
	
	local preventWhispers, preventWhispersText = CreateBlackListOption(f, "BL_PreventWhispers", "Prevent whispers from blacklisted players", pad, function(checked)
		BlackList:ToggleOption("preventWhispers", checked)
	end)
	pad = pad - 25
	
	local warnWhispers, warnWhispersText = CreateBlackListOption(f, "BL_WarnWhispers", "Warn when blacklisted players whisper you", pad, function(checked)
		BlackList:ToggleOption("warnWhispers", checked)
	end)
	pad = pad - 35
	
	-- Group Management Section
	CreateBlackListHeader(f, "Group Management", 12, pad)
	pad = pad - 25
	
	local preventInvites, preventInvitesText = CreateBlackListOption(f, "BL_PreventInvites", "Prevent blacklisted players from inviting you", pad, function(checked)
		BlackList:ToggleOption("preventInvites", checked)
	end)
	pad = pad - 25
	
	local preventMyInvites, preventMyInvitesText = CreateBlackListOption(f, "BL_PreventMyInvites", "Prevent yourself from inviting blacklisted players", pad, function(checked)
		BlackList:ToggleOption("preventMyInvites", checked)
	end)
	pad = pad - 25
	
	local warnPartyJoin, warnPartyJoinText = CreateBlackListOption(f, "BL_WarnPartyJoin", "Warn when blacklisted players join your party", pad, function(checked)
		BlackList:ToggleOption("warnPartyJoin", checked)
	end)
	
	-- Store references for updating
	f.checkboxes = {
		{checkbox = playSounds, option = "playSounds", default = true},
		{checkbox = warnTarget, option = "warnTarget", default = true},
		{checkbox = preventWhispers, option = "preventWhispers", default = true},
		{checkbox = warnWhispers, option = "warnWhispers", default = true},
		{checkbox = preventInvites, option = "preventInvites", default = true},
		{checkbox = preventMyInvites, option = "preventMyInvites", default = false},
		{checkbox = warnPartyJoin, option = "warnPartyJoin", default = true}
	}
	
	return f
end

function BlackList:ShowNewOptions()
	local frame = CreateNewOptionsFrame()
	
	-- Update checkbox states
	for _, data in ipairs(frame.checkboxes) do
		data.checkbox:SetChecked(self:GetOption(data.option, data.default))
	end
	
	frame:Show()
end

-- Hook into BlackList UI functions like pfUI hooks into Blizzard functions
local originalShowOptions = nil
local originalUpdateUI = nil

local function InitializePfUIIntegration()
	if not IsPfUIActive() then return end
	
	-- Hook the ShowOptions function to apply styling when frames are shown
	if BlackList and BlackList.ShowOptions and not originalShowOptions then
		originalShowOptions = BlackList.ShowOptions
		BlackList.ShowOptions = function(self)
			originalShowOptions(self)
			StyleBlackListFrames()
		end
	end
	
	-- Hook the UpdateUI function to ensure styling is maintained
	if BlackList and BlackList.UpdateUI and not originalUpdateUI then
		originalUpdateUI = BlackList.UpdateUI  
		BlackList.UpdateUI = function(self)
			originalUpdateUI(self)
			StyleBlackListFrames()
		end
	end
end

-- Make the function globally accessible for XML OnLoad scripts
_G.InitializePfUIIntegration = InitializePfUIIntegration

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

	-- Add tab buttons to Friends tab (create programmatically instead of using XML templates)
	local friendsTab = CreateFrame("Button", "FriendFrameToggleTab3", FriendsListFrame, "TabButtonTemplate")
	friendsTab:SetText("BLACK")
	friendsTab:SetID(3)
	-- Position after the Ignore tab with minimal spacing
	friendsTab:SetPoint("LEFT", FriendsFrameToggleTab2, "RIGHT", -5, 0)
	friendsTab:SetScript("OnClick", function()
		FriendsFrame_ShowSubFrame("BlackListFrame")
	end)
	
	local ignoreTab = CreateFrame("Button", "IgnoreFrameToggleTab3", IgnoreListFrame, "TabButtonTemplate")
	ignoreTab:SetText("BLACK")
	ignoreTab:SetID(3)
	-- Position after the Friends tab with minimal spacing
	ignoreTab:SetPoint("LEFT", IgnoreFrameToggleTab2, "RIGHT", -5, 0)
	ignoreTab:SetScript("OnClick", function()
		FriendsFrame_ShowSubFrame("BlackListFrame")
	end)
	
	-- Add the tab itself
	table.insert(FRIENDSFRAME_SUBFRAMES, "BlackListFrame")
	local blackListFrame = CreateFrame("Frame", "BlackListFrame", FriendsFrame)
	blackListFrame:SetAllPoints(FriendsFrame)
	blackListFrame:Hide()
	
	-- Add basic content to the BlackList frame
	local titleText = blackListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titleText:SetPoint("TOPLEFT", 20, -20)
	titleText:SetText("BlackList")
	
	-- Options button
	local optionsBtn = CreateFrame("Button", "BlackListOptionsButton", blackListFrame, "UIPanelButtonTemplate")
	optionsBtn:SetWidth(80)
	optionsBtn:SetHeight(22)
	optionsBtn:SetPoint("TOPRIGHT", -20, -20)
	optionsBtn:SetText("Options")
	optionsBtn:SetScript("OnClick", function()
		BlackList:ShowOptions()
	end)
	
	-- Add Player button  
	local addBtn = CreateFrame("Button", "BlackListAddButton", blackListFrame, "UIPanelButtonTemplate")
	addBtn:SetWidth(100)
	addBtn:SetHeight(22)
	addBtn:SetPoint("TOPRIGHT", optionsBtn, "TOPLEFT", -5, 0)
	addBtn:SetText("BlackList Player")
	addBtn:SetScript("OnClick", function()
		StaticPopup_Show("BLACKLIST_PLAYER")
	end)

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
	-- Use the new SuperIgnore-style options instead of the old XML frame
	self:ShowNewOptions()
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
end