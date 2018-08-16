local bdlc, l, f = select(2, ...):unpack()

function bdlc:inLC()
	return bdlc.loot_council[FetchUnitName("player")] or IsRaidLeader() or not IsInRaid()
end


function bdlc:customQN(...)
	bdlc.master_looter_qn = {}

	local notes = {...}
	bdlc:debug("Current Quicknotes: ")
	bdlc:debug(unpack(notes));

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
	bdlc:debug("Current Council: ")
	bdlc:debug(unpack(council));

	for k, v in pairs(council) do
		local playerName = FetchUnitName(v)

		bdlc.loot_council[playerName] = true
		bdlc:debug(playerName..' added to lc')
	end
end

-----------------------------------------------
-- ADD SINGLE PLAYER TO LC
-- this will add/remove the player from your custom council. 
-- If you're group leader it'll then rebuild the council list and redistribute it to the raid
-----------------------------------------------
function bdlc:addremoveLC(msg, name)
	if (not name) then bdlc.print("Please provide a name to add to the loot council") return end
	if (not FetchUnitName(name)) then bdlc.print("Couldn't find any player named "..name..". (they must be in the same group as you) ") return end
	
	-- always add them by name-server format
	name = FetchUnitName(name)
	
	if (msg == "addtolc") then -- add
		bdlc_config.custom_council[name] = true
		bdlc.print("Adding "..name.." to loot council.")
	else -- remove
		bdlc_config.custom_council[name] = nil
		bdlc.print("Removing "..name.." from your loot council.")
	end

	-- rebuild and redistribute your list if you're LM or leader
	if (IsRaidLeader() or not IsInRaid()) then
		bdlc:sendAction("buildLC");
	end
end


-------------------------------------------
-- Returns min rank or default for LC
-------------------------------------------
function bdlc:GetLCMinRank()
	local min_rank
	if (bdlc_config.lc_rank) then
		min_rank = strsplit(": ",bdlc_config.lc_rank)
	else
		min_rank = bdlc_config.council_min_rank
	end

	min_rank = tonumber(min_rank)

	bdlc:debug("Minimum LC Rank: "..min_rank)

	if (not min_rank) then
		min_rank = bdlc.defaults.council_min_rank
		print("BDLC major error: min_rank didn't return a value! Using default value of "..min_rank..".")
	end

	return min_rank
end

function bdlc:GetRaidMembers()
	local inraid = {}
	inraid[FetchUnitName('player')] = true
	local numRaid = GetNumGroupMembers()
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
function bdlc:buildLC()
	if (not bdlc:CanStartSession()) then return end
	bdlc:debug("Building LC")

	-- clear all the settings since we're rebuilding here
	bdlc.enchanters = {}
	local council = {FetchUnitName("player")}
	local quicknotes = {}

	-------------------------------------------------------
	-- MINIMUM LC RANK
	-- gets the saved or default min_rank
	-------------------------------------------------------
	local min_rank = bdlc:GetLCMinRank()
	
	-------------------------------------------------------
	-- RAID MEMBERS
	-- generates a list of players who are in the raid
	-------------------------------------------------------
	local inraid = bdlc:GetRaidMembers()

	-------------------------------------------------------
	-- GUILD-RANK COUNCIL
	-- add players automatically via guild rank
	-------------------------------------------------------
	local numGuildMembers = select(1, GetNumGuildMembers())
	for i = 1, numGuildMembers do
		local fullName, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i)
		local name = FetchUnitName(fullName)

		if (rankIndex <= min_rank and inraid[name]) then
			table.insert(council, name)
		end
	end

	-------------------------------------------------------
	-- CUSTOM COUNCIL
	-- People who are in your custom loot council and in raid
	-------------------------------------------------------
	for k, v in pairs (bdlc_config.custom_council) do
		local name = FetchUnitName(k)
		if (inraid[name]) then
			table.insert(council, name)
		end
	end

	-- send these all at once in 1 call
	if (council and #council > 0) then
		bdlc:sendAction("addToLC", unpack(council))
	end
	
	-------------------------------------------------------
	-- QUICK NOTES
	-- Add to table from saved variables or defaults
	-------------------------------------------------------
	for k, v in pairs(bdlc_config.custom_qn) do
		table.insert(quicknotes, k)
	end

	-- send these all at once in 1 call
	if (quicknotes and #quicknotes > 0) then
		bdlc:sendAction("customQN", unpack(quicknotes) );
	end

	-------------------------------------------------------
	-- ENCHANTERS
	-- feature currently disabled for addon channel load, need to rewrite to be in bulk
	-------------------------------------------------------
	--bdlc:sendAction("findEnchanters");
end
