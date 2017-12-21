local bdlc, l, f = select(2, ...):unpack()

----------------------------------------
-- Get/add/remove
----------------------------------------

function bdlc:customQN(...)
	local notes = {...}
	for k, v in pairs(notes) do
		bdlc.master_looter_qn[v] = true
	end
end

function bdlc:addToLC(...)
	for k, v in pairs(...) do
		local playerName = FetchUnitName(v)

		bdlc.loot_council[playerName] = true
		bdlc:debug(playerName..' added to lc')
	end
end

-- this will add/remove the player from your custom council. If you're group leader it'll then rebuild the council list and redistribute it to the raid
function bdlc:addremoveLC(msg, name)
	if (not name) then print("bdlc: Please provide a name to add to the loot council") return end
	
	-- always add them by name-server format
	local targetname = FetchUnitName(name)
	if (not targetname) then print("bdlc: Couldn't find any player named "..name..". (they must be in the same group as you) ") return end
	
	if (msg == "addtolc") then -- add
		bdlc_config.custom_council[targetname] = true
		print("bdlc: Adding "..targetname.." to loot council.")
	else -- remove
		bdlc_config.custom_council[targetname] = nil
		print("bdlc: Removing "..targetname.." from your loot council.")
	end

	-- rebuild and redistribute your list if you're LM or leader
	if (IsMasterLooter() or not IsInRaid()) then
		bdlc:sendAction("buildLC", targetname);
	end
end

----------------------------------------
-- Enchanters
----------------------------------------
function bdlc:addEnchanter(playerName, guildRankIndex)
	playerName = FetchUnitName(playerName)
	bdlc.enchanters[playerName] = guildRankIndex
	bdlc:debug("Added "..playerName.." to enchanter quicklist")
end

function bdlc:findEnchanters()
	bdlc:debug("Finding enchanters")
	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
	local prof = prof1 == 8 or prof2
	if (prof == 8) then
		name, rank, maxRank = select(1, GetProfessionInfo(prof)), select(3, GetProfessionInfo(prof)), select(4, GetProfessionInfo(prof))
		--if (rank >= (maxRank-10)) then
			local masterLooter = select(3, GetLootMethod()) or 1
			if (masterLooter) then
				local masterLooter = GetRaidRosterInfo(masterLooter) or UnitName("player")
				local mlguildName = select(1, GetGuildInfo(masterLooter))
				local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
				
				if (mlguildName == guildName or not IsInRaid()) then
					bdlc:sendAction("addEnchanter", bdlc.local_player, guildRankIndex);
					--bdlc:addEnchanter(bdlc.local_player, guildRankIndex)
				else
					bdlc:debug("Since this enchanter isn't from the same guild, we're going to ignore them")
				end
			end
		--end
	end
end

----------------------------------------
-- BuildLC
----------------------------------------
function bdlc:buildLC()
	local playerName = FetchUnitName('player')

	-- clear all the settings since we're rebuilding here
	bdlc.enchanters = {}
	bdlc.loot_council = {}
	bdlc.master_looter_qn = {}

	-- only 1 person needs to make these actions
	if (IsMasterLooter() or not IsInRaid()) then		
		bdlc:debug("building LC")

		-- get the saved min_rank
		local min_rank
		if (bdlc_config.lc_rank) then
			min_rank = strsplit(": ",bdlc_config.lc_rank)
		else
			min_rank = bdlc_config.council_min_rank
		end
		min_rank = tonumber(min_rank)
		
		local autocouncil = {}
		local inraid = {}
		local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		local numRaid = GetNumGroupMembers()
		if (numRaid == 0) then numRaid = 1 end

		-- generate a list of players who are in the raid
		inraid[playerName] = true
		for i = 1, numRaid do
			local name = FetchUnitName("raid"..i) or FetchUnitName("party"..i)
			inraid[name] = true
		end

		-- add players automatically via guild rank
		for i = 1, numGuildMembers do
			local fullName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, reputation = GetGuildRosterInfo(i)

			if (online and rankIndex <= min_rank) then
				local name = FetchUnitName(fullName)
				if (not inraid[name]) then return end
				autocouncil[name] = true
				bdlc.loot_council[name] = name
			end
		end

		-- now send actions all at once to reduce gap
		bdlc:sendAction("findEnchanters");

		-- People who are in your custom loot council
		bdlc.loot_council[playerName] = playerName
		for k, v in pairs (bdlc_config.custom_council) do
			if (inraid[k]) then
				bdlc.loot_council[k] = k
			end
		end
		
		-- People who are added via rank
		for k, v in pairs (autocouncil) do
			bdlc.loot_council[k] = k
		end

		-- send these all at once in 1 string
		print(bdlc.loot_council)
		print(unpack(bdlc.loot_council))
		if (#bdlc.loot_council > 0) then
			bdlc:sendAction("addToLC", unpack(bdlc.loot_council) )
		end
		
		-- Quick notes
		local quicknotes = {}
		for k, v in pairs(bdlc_config.custom_qn) do
			table.insert(quicknotes, k)
		end

		-- send these all at once in 1 string
		if (#quicknotes > 0) then
			bdlc:sendAction("customQN", unpack(quicknotes));
		end
	end
end
