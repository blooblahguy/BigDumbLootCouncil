local addon, engine = ...
engine[1] = CreateFrame("Frame", nil, UIParent)
engine[2] = {}
engine[3] = {}

local bdlc = engine[1]
local l = engine[2]
local f = engine[3]

function engine:unpack()
	return self[1], self[2], self[3]
end

bdlc:RegisterEvent("ADDON_LOADED")

bdlc.testMode = false

bdlc.player_realm = GetRealmName()
bdlc.local_player = UnitName("player").."-"..bdlc.player_realm

bdlc.message_prefix = "BDLC";
bdlc.colorName = "|cff3399FFBDLC|r: "
function bdlc.print(msg)
	print(bdlc.colorName..msg)
end

bdlc.font = "Interface\\Addons\\BigDumbLootCouncil\\media\\font.ttf"

bdlc.looters = {}

bdlc.tradedItems = {}

bdlc.item_drops = {}
bdlc.enchanters = {}
bdlc.award_slot = nil

bdlc.loot_slots = {}
bdlc.loot_sessions = {}

bdlc.loot_want = {}

bdlc.loot_council = {}
bdlc.loot_council_votes = {}
bdlc.loot_council_votes.indexhistory = {}

bdlc.items_waiting_for_verify = {}
bdlc.items_waiting_for_session = {}
bdlc.player_items_waiting = {}
bdlc.master_looter_qn = {}

bdlc.itemMap = {}

bdlc.wantTable = {
	[1] = {"Mainspec", {.2, 1, .2}},
	[2] = {"Minor Up", {.6, 1, .6}},
	[3] = {"Offspec", {.8, .6, .6}},
	[4] = {"Reroll", {.1, .6, .6}},
	[5] = {"Transmog", {.8, .4, 1}}
}

-- Config
bdlc.config = {
	flat = "Interface\\Buttons\\WHITE8x8"
	, height = 400
	, width = 600
	-- , debug = true
	, version = "@project-version@"
	-- , version = "2.45"
}
bdlc.defaults = {
	council_min_rank = 2,
	custom_council = {},
	custom_qn = {
		["BiS"] = true,
		["2p"] = true,
		["4p"] = true,
	}
}
