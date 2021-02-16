local bdlc, c, l = unpack(select(2, ...))

function bdlc:inLC()
	-- if i'm in lc, raid leader, or not in a group
	return bdlc.loot_council[FetchUnitName('player')] or IsRaidLeader() or not IsInGroup()
end

function bdlc:customButtons(buttons)
	bdlc.buttons = {}

	local btns = {strsplit("//", buttons)}
	for k, v in pairs(btns) do
		local index, name, r, g, b, enabled, require_note = strsplit(",", v)
		index, r, g, b = tonumber(index), tonumber(r), tonumber(g), tonumber(b)
		enabled = tonumber(enabled) == 1 and true or false
		require_note = tonumber(require_note) == 1 and true or false

		if (index) then
			bdlc.buttons[index] = {name, {r, g, b}, enabled, require_note}
		end
	end

	-- display to debug
	local buttons = ""
	for k, v in pairs(bdlc.buttons) do
		local hex = RGBPercToHex(unpack(v[2]))
		local name, enabled, require_note = v[1], v[3], v[4]
		if (enabled) then
			enabled = enabled and "Enabled" or "Disabled"
			require_note = require_note and "Requires Note" or "No Required Note"
			buttons = buttons.."|cff"..hex..v[1].."|r : "..enabled.." : "..require_note.."\n"
		end
	end

	bdlc:debug("Current Buttons:\n", buttons)
end

function bdlc:councilVotes(votes)
	bdlc:debug("Current Council Votes: ", votes)
	bdlc.council_votes = tonumber(votes)
end

function bdlc:customQN(...)
	bdlc.master_looter_qn = {}

	local notes = {...}
	for k, v in pairs(notes) do
		bdlc.master_looter_qn[v] = true
	end

	bdlc:debug("Current Quicknotes: ", unpack(bdlc.master_looter_qn))
end

----------------------------------------
-- BULK ADD TO LC
-- Takes a table of players and adds all at once
----------------------------------------
function bdlc:addToLC(...)
	bdlc.loot_council = {}
	
	local council = {...}
	bdlc:debug("Current Council: ", unpack(council))

	for k, v in pairs(council) do
		local name = FetchUnitName(v)

		bdlc.loot_council[name] = true
	end
end

-----------------------------------------------
-- ADD SINGLE PLAYER TO LC
-- this will add/remove the player from your custom council. 
-- If you're group leader it'll then rebuild the council list and redistribute it to the raid
-----------------------------------------------
function bdlc:addremoveLC(msg, name)
	if (not name) then bdlc:print("Please provide a name to add to the loot council") return false end
	
	name = FetchUnitName(name)
	
	if (msg == "addtolc") then -- add
		bdlc.config.custom_council[name] = true
		bdlc:print("Adding "..name.." to loot council.")
	else -- remove
		bdlc.config.custom_council[name] = nil
		bdlc:print("Removing "..name.." from your loot council.")
	end

	-- rebuild and redistribute your list if you're LM or leader
	bdlc:sendLC()

	return true
end


-------------------------------------------
-- Returns min rank or default for LC
-------------------------------------------
function bdlc:GetLCMinRank()
	local min_rank = bdlc.config.council_min_rank
	min_rank = tonumber(min_rank)

	bdlc:debug("Minimum LC Rank: ", min_rank)

	if (not min_rank) then
		bdlc.config.council_min_rank = bdlc.configDefaults.council_min_rank
		min_rank = bdlc.configDefaults.council_min_rank
		bdlc:print("Major error: min_rank didn't return a value! Using default value of ", min_rank)
	end

	return min_rank
end

function bdlc:GetRaidMembers()
	local inraid = {}
	inraid[FetchUnitName('player')] = true

	local numRaid = 40
	for i = 1, numRaid do
		local name = FetchUnitName("raid"..i) or FetchUnitName("party"..i)
		if (name) then
			inraid[name] = true
		end
	end

	return inraid
end

----------------------------------------
-- BuildLC
-- Wipes default loot council, quick notes, and enchanters. Then rebuilds in bulk
----------------------------------------
function bdlc:requestLC()
	if (IsRaidLeader()) then
		bdlc:sendLC()
	end
end

function bdlc:sendLC()
	if (not IsRaidLeader()) then return end
	bdlc:debug("---")
	bdlc:debug("Building LC")

	-- get the saved or default min_rank
	local min_rank = bdlc:GetLCMinRank()

	-------------------------------------------------------
	-- COUNCIL
	-------------------------------------------------------
	local council = {}
	local raid = bdlc:GetRaidMembers()
	council[FetchUnitName('player')] = true

	-- add players automatically via guild rank
	local numGuildMembers = select(1, GetNumGuildMembers())
	for i = 1, numGuildMembers do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
		name = FetchUnitName(name)

		if (rankIndex <= min_rank and raid[name]) then
			council[name] = true
		end
	end

	-- add from the raid
	local myGuild = select(1, GetGuildInfo("player"))
	local numRaid = GetNumGroupMembers() or 1
	for i = 1, numRaid do
		local unit = select(1, GetRaidRosterInfo(i))
		if (unit) then
			local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit);
			local name = FetchUnitName(unit)

			if (guildName == myGuild and guildRankIndex <= min_rank and raid[name]) then
				council[name] = true
			end
		end
	end

	-------------------------------------------------------
	-- CUSTOM COUNCIL
	-- People who are in your custom loot council and in raid
	-------------------------------------------------------
	for k, v in pairs (bdlc.config.custom_council) do
		local name = FetchUnitName(k)
		if (UnitExists(k)) then
			council[name] = true
		end
	end
	
	-------------------------------------------------------
	-- QUICK NOTES
	-------------------------------------------------------
	local quicknotes = {}
	for k, v in pairs(bdlc.config.quick_notes) do
		quicknotes[k] = true
	end

	-------------------------------------------------------
	-- CUSTOM BUTTONS
	-------------------------------------------------------
	local buttons_string = ""
	for i = 1, #bdlc.config.buttons do
		v = bdlc.config.buttons[i]

		local name, color, enable, req = unpack(v)
		local r, g, b = unpack(color)
		local k = tostring(i)
		enable = enable and "1" or "0"
		req = req and "1" or "0"
		local info = {k, name, tostring(r), tostring(g), tostring(b), enable, req}
		buttons_string = buttons_string..table.concat(info, ",").."//"
	end

	-- loot council
	local friendlyCouncil = {}
	for name, v in pairs(council) do
		table.insert(friendlyCouncil, name)
	end

	bdlc:sendAction("addToLC", unpack(friendlyCouncil) )

	-- custom quicknotes
	local friendlyQN = {}
	for note, v in pairs(quicknotes) do
		table.insert(friendlyQN, note)
	end
	bdlc:sendAction("customQN", unpack(friendlyQN) );

	-- number of council votes
	bdlc:sendAction("councilVotes", bdlc.config.council_votes);

	-- buttons
	-- bdlc:sendAction("customButtons", buttons_string);
end


local council_events = CreateFrame("frame")
council_events:RegisterEvent("PLAYER_ENTERING_WORLD")
council_events:RegisterEvent("BOSS_KILL")
council_events:RegisterEvent("GUILD_ROSTER_UPDATE")
council_events:RegisterEvent("PLAYER_GUILD_UPDATE")
council_events:RegisterEvent("CHAT_MSG_SYSTEM")
bdlc.am_leader = IsRaidLeader()
council_events:SetScript("OnEvent", function(self, event, arg1)
	C_GuildInfo.GuildRoster() -- keep this up to date

	-- if i've left a loading screen, gimme the new LC
	if (event == "PLAYER_ENTERING_WORLD") then
		C_Timer.After(1, function()
			bdlc:sendAction("requestLC");
		end)
		
		return
	end

	-- when group lead changes
	if (event == "CHAT_MSG_SYSTEM") then
		C_Timer.After(1, function()
			-- raid leader toggle check
			if (not bdlc.am_leader and IsRaidLeader()) then
				bdlc:sendLC()
			end
			
			bdlc.am_leader = IsRaidLeader()
		end)

		return
	end
	
	-- when a boss dies it's time for more sessions
	if (event == "BOSS_KILL" or event == "GUILD_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") then
		council_events:UnregisterEvent("GUILD_ROSTER_UPDATE")
		bdlc:sendLC()
		
		return
	end
end)