local bdlc, c, l = unpack(select(2, ...))

function bdlc:inLC()
	return bdlc.loot_council[FetchUnitName('player'):lower()] or IsRaidLeader() or not IsInGroup()
end

-- function bdlc:buttons(buttons)
-- 	bdlc:debug("Current Council Votes: ", votes)
-- 	bdlc.council_votes = tonumber(votes)
-- end

function bdlc:councilVotes(votes)
	bdlc:debug("Current Council Votes: ", votes)
	bdlc.council_votes = tonumber(votes)
end

function bdlc:customQN(...)
	bdlc.master_looter_qn = {}

	local notes = {...}
	bdlc:debug("Current Quicknotes: ", unpack(notes))

	for k, v in pairs(notes) do
		bdlc.master_looter_qn[v] = true
	end
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
		local playerName = Ambiguate(v, "mail"):lower()

		bdlc.loot_council[playerName] = true
	end
end

-----------------------------------------------
-- ADD SINGLE PLAYER TO LC
-- this will add/remove the player from your custom council. 
-- If you're group leader it'll then rebuild the council list and redistribute it to the raid
-----------------------------------------------
function bdlc:addremoveLC(msg, name)
	if (not name) then bdlc:print("Please provide a name to add to the loot council") return false end

	-- if (not FetchUnitName(name, true)) then 
	-- 	bdlc:print("Warning: couldn't find any player named "..name..". (they must be in the same group as you) ")
	-- end
	
	name = FetchUnitName(name):lower()
	
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
	inraid[UnitName('player')] = true
	local numRaid = 40
	if (numRaid == 0) then numRaid = 1 end

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
	bdlc:debug("Building LC")

	-- clear all the settings since we're rebuilding here
	local council = {FetchUnitName('player'):lower()}
	local quicknotes = {}
	local buttons_string = ""

	-------------------------------------------------------
	-- MINIMUM LC RANK
	-- gets the saved or default min_rank
	-------------------------------------------------------
	local min_rank = bdlc:GetLCMinRank()

	-------------------------------------------------------
	-- GUILD-RANK COUNCIL
	-- add players automatically via guild rank
	-------------------------------------------------------
	-- local numGuildMembers = select(1, GetNumGuildMembers())
	-- for i = 1, numGuildMembers do
	-- 	local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
	-- 	-- local name = FetchUnitName(fullName)

	-- 	if (rankIndex <= min_rank and UnitExists(name) and tIndexOf(council, FetchUnitName(name)) == nil) then
	-- 		table.insert(council, FetchUnitName(name))
	-- 	end
	-- end

	local myGuild = select(1, GetGuildInfo("player"))
	local numRaid = GetNumGroupMembers() or 1
	for i = 1, numRaid do
		local unit = select(1, GetRaidRosterInfo(i))
		if (unit) then
			local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit);
			local name = Ambiguate(unit, "mail"):lower()

			if (guildName == myGuild and guildRankIndex <= min_rank) then
				if (tIndexOf(council, name) == nil) then
					table.insert(council, name)
				end
			end
		end
	end

	-------------------------------------------------------
	-- CUSTOM COUNCIL
	-- People who are in your custom loot council and in raid
	-------------------------------------------------------
	for k, v in pairs (bdlc.config.custom_council) do
		local name = Ambiguate(k, "mail"):lower()
		if (UnitExists(k) and tIndexOf(council, name) == nil) then
			table.insert(council, name)
		end
	end
	
	-------------------------------------------------------
	-- QUICK NOTES
	-------------------------------------------------------
	for k, v in pairs(bdlc.config.quick_notes) do
		table.insert(quicknotes, v)
	end

	-------------------------------------------------------
	-- CUSTOM BUTTONS
	-------------------------------------------------------
	-- for i = 1, #bdlc.config.buttons do
	-- 	v = bdlc.config.buttons[i]

	-- 	table.insert(quicknotes, v)
	-- 	local name, color, enable, req = unpack(v)
	-- 	local r, g, b = unpack(color)
	-- 	local k = tostring(i)
	-- 	enable = enable and "1" or "0"
	-- 	req = req and "1" or "0"
	-- 	local info = {k, name, r, g, b, enable, req}
	-- 	buttons_string = buttons_string..table.concat(info, ",").."//"
	-- end

	-- print(buttons_string)

	-- loot council
	if (council and #council > 0) then
		bdlc:sendAction("addToLC", unpack(council) )
	end

	-- custom quicknotes
	if (quicknotes and #quicknotes > 0) then
		bdlc:sendAction("customQN", unpack(quicknotes) );
	end

	-- council votes
	bdlc:sendAction("councilVotes", bdlc.config.council_votes);

	-- buttons
	-- bdlc:sendAction("buttons", buttons_string);
end


local council_events = CreateFrame("frame")
council_events:RegisterEvent("PLAYER_ENTERING_WORLD")
council_events:RegisterEvent("BOSS_KILL")
council_events:RegisterEvent("GUILD_ROSTER_UPDATE")
council_events:RegisterEvent("CHAT_MSG_SYSTEM")
bdlc.am_leader = IsRaidLeader()
council_events:SetScript("OnEvent", function(self, event, arg1)
	if (event == "PLAYER_ENTERING_WORLD") then
		C_Timer.After(1, function()
			bdlc:sendAction("requestLC");
		end)
		
		return
	end

	-- when group lead changes
	if (event == "CHAT_MSG_SYSTEM") then
		C_Timer.After(1, function()
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