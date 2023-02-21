local addonName, engine = ...
engine[1] = CreateFrame("Frame", nil, UIParent)
engine[2] = {}
engine[3] = {}

bdlc = engine[1]
bdlc.addonName = addonName
bdlc.messagePrefix = "BDLC";
bdlc.deliminator = "><";
bdlc.colorString = "|cffA02C2FBig|r Dumb Loot Council "
bdlc.localPlayer = Ambiguate(UnitName("player").."-"..GetRealmName(), "mail"):utf8lower()
bdlc.comm = LibStub:GetLibrary("AceComm-3.0")
bdlc.config = {}
bdlc.enabledebug = false
bdlc.enableTests = false

-- tooltip scanner
bdlc.tt = CreateFrame('GameTooltip', 'BDLC:TooltipScan', UIParent, 'GameTooltipTemplate')
bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')

-- basic media options
bdlc.media = {
	flat = "Interface\\Buttons\\WHITE8x8",
	smooth = "Interface\\Addons\\bigdumblootcouncil\\media\\smooth.tga",
	font = "Interface\\Addons\\bigdumblootcouncil\\media\\font.ttf",
	arrow = "Interface\\Addons\\bigdumblootcouncil\\media\\arrow.blp",
	border = {.03, .04, .05, 1},
	backdrop = {.08, .09, .11, 0.9},
	hover = {.28, .29, .31, 0.9},
	red = {.62, .17, .18, 1},
	blue = {.2, .4, 0.8, 1},
	green = {.1, .7, 0.3, 1},
}

-- main font object
bdlc.font = CreateFont("bdlc_font")
bdlc.font:SetFont(bdlc.media.font, 14, "THINOUTLINE")
bdlc.font:SetShadowColor(0, 0, 0)
bdlc.font:SetShadowOffset(1, -1)

-- defaults
bdlc.configDefaults = {
	council_min_rank = 2,
	debug = false,
	custom_council = {},
	council_votes = 1,
	quick_notes = {
		["BiS"] = true, 
		["20%"] = true,
		["10%"] = true,
	},
	-- text, color, enable, require note
	buttons = {
		[1] = {"Mainspec", {.2, 1, .2}, true, true},
		[2] = {"Minor Up", {.6, 1, .6}, true, false},
		[3] = {"Offspec", {.8, .6, .6}, true, false},
		[4] = {"Reroll", {.1, .6, .6}, true, false},
		[5] = {"Transmog", {.8, .4, 1}, true, false},
	}
}

-- info holders
bdlc.loot_council = {}
bdlc.loot_council_votes = {}
bdlc.loot_council_index_history = {}
bdlc.items_waiting_for_verify = {}
bdlc.items_waiting_for_session = {}
bdlc.player_items_waiting = {}
bdlc.tradedItems = {}
bdlc.itemMap = {}
bdlc.loot_sessions = {}
bdlc.loot_want = {}
bdlc.item_drops = {}

-- Commands
SLASH_bdlc1 = "/bdlc"
SlashCmdList["bdlc"] = function(original_msg, editbox)
	local msg, msg2, msg3 = strsplit(" ", strtrim(original_msg), 2)

	-- list of commands
	if (msg == "" or msg == " ") then
		print("|cffA02C2FBDLC|r commands:")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAtest|r - Tests the addon outside of raid")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAconfig|r - Shows the configuration window")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAshow|r - Shows the vote window (if you're in the LC)")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAhide|r - Hides the vote window (if you're in the LC)")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAversion|r - Check the bdlc versions that the raid is using")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAaddtolc|r |cffAAEEFFplayername|r - Adds a player to the loot council (if you're the Masterlooter)")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAremovefromlc|r |cffAAEEFFplayername|r - Adds a player to the loot council (if you're the Masterlooter)")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAreset|r - Resets configuration to defaults")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAArequestlc|r - Requests LC information to be resent, use if LC is innacurate")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAdebug|r - Toggles debug mode")
		print("  /|cffA02C2Fbdlc|r |cffEEFFAAvalid|r |cffAAEEFF[itemlink]|r - Checks item information and if its valid for an automatic session.")

		return
	end

	-- debug
	if (msg == "debug") then
		bdlc.config.debug = not bdlc.config.debug
		bdlc:print("Debug mode:", bdlc.config.debug and "On" or "Off")

		return
	end

	-- test
	if (msg == "test") then
		bdlc:startMockSession()

		return
	end

	-- show
	if (msg == "show") then
		if (bdlc:inLC()) then
			bdlc.window:Show()
		else
			bdlc:print("Can't show window - you are not in the loot council.")
		end

		return
	end

	-- start
	if (msg == "start") then
		if (not msg2) then
			bdlc:print("3rd parameter needs to be an itemLink")
			return
		end
		bdlc:sendAction("startSession", msg2, bdlc.localPlayer);
		
		return
	end

	-- start
	if (msg == "requestlc") then
		bdlc:requestLC()

		bdlc:print("Requested LC")

		return
	end

	-- start
	if (msg == "valid") then
		if (not msg2) then
			bdlc:print("3rd parameter needs to be an itemLink")
		end
		if (bdlc:itemValidForSession(msg2, bdlc.localPlayer, true, -1)) then
			bdlc:print(msg2, "valid for session.")
		else
			bdlc:print(msg2, "not valid for session.")
		end
		
		return
	end

	-- hide
	if (msg == "hide") then
		bdlc.window:Hide()
		
		return
	end

	-- version
	if (msg == "version") then
		bdlc:checkRaidVersions()

		return
	end

	-- edit lc
	if (msg == "addtolc" or msg == "removefromlc") then
		bdlc:addremoveLC(msg, msg2)

		return
	end

	-- config
	if (msg == "config") then
		bdlc.config_window:SetShown(not bdlc.config_window:IsShown())
		
		return
	end

	-- reset
	if (msg == "reset") then
		BDLC_CONFIG = bdlc.configDefaults
		bdlc.config = BDLC_CONFIG

		ReloadUI();

		return
	end

	bdlc:print("Command "..original_msg.. "not recognized.")
end

-- bdlc.looters = {}

-- bdlc.tradedItems = {}

-- bdlc.item_drops = {}
-- bdlc.enchanters = {}
-- bdlc.award_slot = nil

-- bdlc.loot_slots = {}
-- bdlc.loot_sessions = {}

-- bdlc.loot_want = {}

-- bdlc.loot_council = {}
-- bdlc.loot_council_votes = {}
-- bdlc.loot_council_votes.indexhistory = {}

-- bdlc.items_waiting_for_verify = {}
-- bdlc.items_waiting_for_session = {}
-- bdlc.player_items_waiting = {}
-- bdlc.master_looter_qn = {}

-- bdlc.itemMap = {}

-- -- Config
-- bdlc.config = {
-- 	flat = "Interface\\Buttons\\WHITE8x8"
-- 	, height = 400
-- 	, width = 600
-- 	-- , debug = true
-- 	-- , version = "@project-version@"
-- 	, version = "2.50"
-- }
-- bdlc.defaults = {
-- 	council_min_rank = 2,
-- 	custom_council = {},
-- 	custom_qn = {
-- 		["BiS"] = true,
-- 		["2p"] = true,
-- 		["4p"] = true,
-- 	}
-- }