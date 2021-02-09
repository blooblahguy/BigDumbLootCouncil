local bdlc, c, l = unpack(select(2, ...))

bdlc.demo_samples = {
	classes = {"HUNTER","WARLOCK","PRIEST","PALADIN","MAGE","ROGUE","DRUID","WARRIOR","DEATHKNIGHT","MONK","DEMONHUNTER"},
	ranks = {},
	names = {"OReilly", "Billy", "Tìncan", "Mango", "Ugh", "Onebutton", "Thor", "Deadpool", "Edgelord", "Yeah", "Arranum", "Witts", "Darkfurion", "Fox", "Cherry"}
}

local ranks = 0
local guildranks = CreateFrame("frame")
guildranks:RegisterEvent("GUILD_ROSTER_UPDATE")
guildranks:RegisterEvent("PLAYER_GUILD_UPDATE")
local function get_ranks()
	guildranks:UnregisterEvent("GUILD_ROSTER_UPDATE")
	guildranks:UnregisterEvent("PLAYER_GUILD_UPDATE")
	
	for i = 1, 100 do
		local name, rank, rankIndex, level = GetGuildRosterInfo(i);
		
		bdlc.demo_samples.ranks[rankIndex] = rank
	end
end
C_GuildInfo.GuildRoster()
guildranks:SetScript("OnEvent", get_ranks)
C_Timer.After(2, function()
	get_ranks()
end)

local function rando_name()
	return bdlc.demo_samples.names[math.random(#bdlc.demo_samples.names)]
end
local function rando_ilvl()
	local ilvl = GetAverageItemLevel()

	return math.random(ilvl * 0.7, ilvl * 1.3)
end
local function rando_rank()
	return bdlc.demo_samples.ranks[math.random(#bdlc.demo_samples.ranks)]
end
local function rando_class()
	return bdlc.demo_samples.classes[math.random(#bdlc.demo_samples.classes)]
end

function bdlc:startMockSession()
	if (IsInRaid() or IsInGroup() or UnitInRaid("player")) then
		if (not bdlc:inLC()) then
			bdlc:print("You cannot run a test while inside of a raid group unless you are on the Loot Council.")
		end
	end

	bdlc:print("Starting mock session")
	
	-- add random people, up to a whole raid worth of fakers
	local demo_players = {}
	for i = 5, math.random(6, 30) do
		demo_players[rando_name()] = {rando_ilvl(), rando_rank(), rando_class()}
	end
	
	-- fake build an LC
	local itemslots = {1, 2, 3, 5, 8, 9, 10, 11, 12, 13, 14, 15}
	bdlc.item_drops = {}
	for i = 1, 4 do
		local index = itemslots[math.random(#itemslots)]
		bdlc.item_drops[GetInventoryItemLink("player", index)] = rando_name()
		table.remove(itemslots,index)
	end

	-- now lets start fake sessions
	for k, v in pairs(bdlc.item_drops) do
		local itemUID = bdlc:GetItemUID(k, bdlc.localPlayer)
		bdlc:sendAction("startSession", k, bdlc.localPlayer);

		-- add our demo players in 
		for name, data in pairs(demo_players) do
			bdlc:sendAction("addUserConsidering", itemUID, name, unpack(data));
		end

		-- send a random "want" after 2-5s, something like a real person
		C_Timer.After(math.random(2, 5), function()
			for name, data in pairs(demo_players) do
				bdlc:sendAction("addUserWant", itemUID, name, math.random(1, 4), 0, 0, math.random(1, 100));
			end
		end)
	end
end