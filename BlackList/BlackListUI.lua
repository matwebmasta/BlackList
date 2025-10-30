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
	
	-- Get pfUI's border size for consistent tab spacing (using pfUI's GetBorderSize function)
	local rawborder, border = 1, 1
	if pfUI.api.GetBorderSize then
		rawborder, border = pfUI.api.GetBorderSize()
	end
	local tabSpacing = border * 2 + 1
	
	-- If spacing is too small, use a minimum value that looks good
	if tabSpacing < 5 then
		tabSpacing = 6  -- Reasonable default that matches pfUI's visual style
	end
	
	-- Style ALL the BlackList tabs to match pfUI tabs
	if FriendFrameToggleTab3 and not FriendFrameToggleTab3.pfuiStyled then
		pfUI.api.SkinTab(FriendFrameToggleTab3)
		-- Reposition with pfUI's spacing calculation
		FriendFrameToggleTab3:ClearAllPoints()
		FriendFrameToggleTab3:SetPoint("LEFT", FriendsFrameToggleTab2, "RIGHT", tabSpacing, 0)
		FriendFrameToggleTab3.pfuiStyled = true
		DEFAULT_CHAT_FRAME:AddMessage("BlackList: Styled FriendFrameToggleTab3 with spacing=" .. tabSpacing)
	end
	
	if IgnoreFrameToggleTab3 and not IgnoreFrameToggleTab3.pfuiStyled then
		pfUI.api.SkinTab(IgnoreFrameToggleTab3)
		-- Reposition with pfUI's spacing calculation
		IgnoreFrameToggleTab3:ClearAllPoints()
		IgnoreFrameToggleTab3:SetPoint("LEFT", IgnoreFrameToggleTab2, "RIGHT", tabSpacing, 0)
		IgnoreFrameToggleTab3.pfuiStyled = true
		DEFAULT_CHAT_FRAME:AddMessage("BlackList: Styled IgnoreFrameToggleTab3 with spacing=" .. tabSpacing)
	end
	
	if BlackListFrameToggleTab3 and not BlackListFrameToggleTab3.pfuiStyled then
		pfUI.api.SkinTab(BlackListFrameToggleTab3)
		BlackListFrameToggleTab3.pfuiStyled = true
		DEFAULT_CHAT_FRAME:AddMessage("BlackList: Styled BlackListFrameToggleTab3")
	end
	
	-- Style the BlackListFrame's own tabs (when viewing the BlackList tab)
	-- These are: BlackListFrameToggleTab1 (Friends), BlackListFrameToggleTab2 (Ignore), BlackListFrameToggleTab3 (BlackList)
	local blTab1 = getglobal("BlackListFrameToggleTab1")
	if blTab1 and not blTab1.pfuiStyledInternal then
		pfUI.api.SkinTab(blTab1)
		-- Position it like pfUI does: anchor to scroll frame
		blTab1:ClearAllPoints()
		blTab1:SetPoint("BOTTOMLEFT", FriendsFrameBlackListScrollFrame, "TOPLEFT", 0, tabSpacing)
		blTab1.pfuiStyledInternal = true
		DEFAULT_CHAT_FRAME:AddMessage("BlackList: Styled BlackListFrameToggleTab1 with spacing=" .. tabSpacing)
	end
	
	local blTab2 = getglobal("BlackListFrameToggleTab2")
	if blTab2 and not blTab2.pfuiStyledInternal then
		pfUI.api.SkinTab(blTab2)
		-- Reposition with pfUI's spacing calculation
		blTab2:ClearAllPoints()
		blTab2:SetPoint("LEFT", blTab1, "RIGHT", tabSpacing, 0)
		blTab2.pfuiStyledInternal = true
		DEFAULT_CHAT_FRAME:AddMessage("BlackList: Styled BlackListFrameToggleTab2 with spacing=" .. tabSpacing)
	end
	
	local blTab3 = getglobal("BlackListFrameToggleTab3")
	if blTab3 and not blTab3.pfuiStyledInternal then
		pfUI.api.SkinTab(blTab3)
		-- Reposition with pfUI's spacing calculation
		blTab3:ClearAllPoints()
		blTab3:SetPoint("LEFT", blTab2, "RIGHT", tabSpacing, 0)
		blTab3.pfuiStyledInternal = true
		DEFAULT_CHAT_FRAME:AddMessage("BlackList: Styled BlackListFrameToggleTab3 with spacing=" .. tabSpacing)
	end
end

-- Delayed styling function to ensure pfUI and tabs are ready
local function DelayedStyleTabs()
	local attempts = 0
	local maxAttempts = 10
	
	local styler = CreateFrame("Frame")
	styler:SetScript("OnUpdate", function()
		attempts = attempts + 1
		
		if IsPfUIActive() and (FriendFrameToggleTab3 or IgnoreFrameToggleTab3 or BlackListFrameToggleTab3) then
			StyleBlackListFrames()
			this:SetScript("OnUpdate", nil) -- Stop trying once successful
			DEFAULT_CHAT_FRAME:AddMessage("BlackList: pfUI integration complete")
		elseif attempts >= maxAttempts then
			this:SetScript("OnUpdate", nil) -- Give up after max attempts
			if not IsPfUIActive() then
				DEFAULT_CHAT_FRAME:AddMessage("BlackList: pfUI not detected, using standard styling")
			else
				DEFAULT_CHAT_FRAME:AddMessage("BlackList: Could not find tabs to style")
			end
		end
	end)
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
	f:EnableMouse(true)
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
	ct:SetWidth(240)  -- Set max width for text wrapping
	ct:SetJustifyH("LEFT")
	-- Note: SetWordWrap doesn't exist in Classic WoW 1.12
	
	return c, ct
end

local function CreateBlackListCloseButton(frame)
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	
	-- Apply pfUI styling if available
	if IsPfUIActive() and pfUI.api.SkinCloseButton then
		-- pfUI uses -6, -6 offset for close buttons
		pfUI.api.SkinCloseButton(closeBtn, frame.backdrop or frame, -6, -6)
	else
		closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
	end
	
	closeBtn:SetScript("OnClick", function() frame:Hide() end)
	
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
	
	local pad = -15
	
	-- Title
	CreateBlackListHeader(f, "BlackList Options", 14, pad)
	pad = pad - 25
	
	-- General Settings Section
	CreateBlackListHeader(f, "General Settings", 11, pad)
	pad = pad - 22
	
	local playSounds, playSoundsText = CreateBlackListOption(f, "BL_PlaySounds", "Play warning sounds", pad, function(checked)
		BlackList:ToggleOption("playSounds", checked)
	end)
	pad = pad - 22
	
	local warnTarget, warnTargetText = CreateBlackListOption(f, "BL_WarnTarget", "Warn when targeting blacklisted players", pad, function(checked)
		BlackList:ToggleOption("warnTarget", checked)
	end)
	pad = pad - 32  -- Extra space for longer text
	
	-- Communication Section
	CreateBlackListHeader(f, "Communication", 11, pad)
	pad = pad - 22
	
	local preventWhispers, preventWhispersText = CreateBlackListOption(f, "BL_PreventWhispers", "Prevent whispers from blacklisted players", pad, function(checked)
		BlackList:ToggleOption("preventWhispers", checked)
	end)
	pad = pad - 32
	
	local warnWhispers, warnWhispersText = CreateBlackListOption(f, "BL_WarnWhispers", "Warn when blacklisted players whisper you", pad, function(checked)
		BlackList:ToggleOption("warnWhispers", checked)
	end)
	pad = pad - 32
	
	-- Group Management Section
	CreateBlackListHeader(f, "Group Management", 11, pad)
	pad = pad - 22
	
	local preventInvites, preventInvitesText = CreateBlackListOption(f, "BL_PreventInvites", "Prevent blacklisted players from inviting you", pad, function(checked)
		BlackList:ToggleOption("preventInvites", checked)
	end)
	pad = pad - 32
	
	local preventMyInvites, preventMyInvitesText = CreateBlackListOption(f, "BL_PreventMyInvites", "Prevent yourself from inviting blacklisted players", pad, function(checked)
		BlackList:ToggleOption("preventMyInvites", checked)
	end)
	pad = pad - 32
	
	local warnPartyJoin, warnPartyJoinText = CreateBlackListOption(f, "BL_WarnPartyJoin", "Warn when blacklisted players join your party", pad, function(checked)
		BlackList:ToggleOption("warnPartyJoin", checked)
	end)
	
	-- Adjust frame height to fit content compactly with bottom padding
	f:SetHeight(math.abs(pad) + 35)
	
	-- Store references for updating
	f.checkboxes = {
		{checkbox = playSounds, option = "playSounds", default = true},
		{checkbox = warnTarget, option = "warnTarget", default = true},
		{checkbox = preventWhispers, option = "preventWhispers", default = true},
		{checkbox = warnWhispers, option = "warnWhispers", default = true},
		{checkbox = preventInvites, option = "preventInvites", default = false},  -- Off by default
		{checkbox = preventMyInvites, option = "preventMyInvites", default = true},  -- On by default
		{checkbox = warnPartyJoin, option = "warnPartyJoin", default = true}
	}
	
	return f
end

function BlackList:ShowNewOptions()
	local frame = CreateNewOptionsFrame()
	
	-- Toggle behavior: if already shown, hide it
	if frame:IsVisible() then
		frame:Hide()
		return
	end
	
	-- Position relative to FriendsFrame (upper right corner with margin)
	frame:ClearAllPoints()
	-- If pfUI is active, position relative to the backdrop, otherwise use FriendsFrame
	if IsPfUIActive() and FriendsFrame.backdrop then
		frame:SetPoint("TOPLEFT", FriendsFrame.backdrop, "TOPRIGHT", 10, 0)
	else
		frame:SetPoint("TOPLEFT", FriendsFrame, "TOPRIGHT", 10, 0)
	end
	
	-- Update checkbox states
	if frame.checkboxes then
		for _, data in ipairs(frame.checkboxes) do
			data.checkbox:SetChecked(self:GetOption(data.option, data.default))
		end
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

	-- Add tab buttons to Friends tab (using XML templates like original)
	CreateFrame("Button", "FriendFrameToggleTab3", getglobal("FriendsListFrame"), "FriendsFrameToggleTab3");
	CreateFrame("Button", "IgnoreFrameToggleTab3", getglobal("IgnoreListFrame"), "IgnoreFrameToggleTab3");
	
	-- Add the tab itself
	table.insert(FRIENDSFRAME_SUBFRAMES, "BlackListFrame");
	CreateFrame("Frame", "BlackListFrame", getglobal("FriendsFrame"), "BlackListFrame");
	
	-- Apply pfUI styling with delay to ensure pfUI and tabs are loaded
	DelayedStyleTabs();

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