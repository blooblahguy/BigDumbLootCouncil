local addon, engine = ...
engine[1] = CreateFrame("Frame", nil, UIParent)
engine[2] = {}
engine[3] = {}

engine[1]:RegisterEvent("ADDON_LOADED")

function engine:unpack()
	return self[1], self[2], self[3]
end

bdlc = engine[1]
l = engine[2]
f = engine[3]

bdlc.player_realm = GetRealmName()
bdlc.local_player = UnitName("player").."-"..bdlc.player_realm

bdlc.message_prefix = "BDLC";
bdlc.item_drops = {}
bdlc.enchanters = {}
bdlc.award_slot = nil
bdlc.sendTo = "RAID"
bdlc.loot_sessions = { --[[[	itemLink] = itemUID	--]]}
bdlc.loot_council_votes = { --[[	itemLink[playerName] = {councilNames}	--]]}
bdlc.loot_council = {}
bdlc.loot_slots = {}
bdlc.loot_considering = {}
bdlc.loot_want = {}
bdlc.items_waiting = {}
bdlc.player_items_waiting = {}
bdlc.master_looter_qn = {}

bdlc.itemUID_Map = {}

-- Config
bdlc.config = {
	flat = "Interface\\Buttons\\WHITE8x8",
	height = 400,
	width = 600,
	debug = false,
	version = "2.01"
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