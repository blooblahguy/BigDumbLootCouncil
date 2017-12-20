local bdlc, l, f = select(2, ...):unpack()

----------------------------------------
-- Get/add/remove
----------------------------------------

function bdlc:clearMLSettings()
	bdlc.enchanters = {}
	bdlc.loot_council = {}
	bdlc.master_looter_qn = {}
end

function bdlc:wipeQN(note)
end
function bdlc:customQN(...)
	local notes = {...}
	for k, v in pairs(notes) do
		bdlc.master_looter_qn[v] = true
	end
end

function bdlc:addToLC(playerName)
	playerName = FetchUnitName(playerName)
	bdlc.loot_council[playerName] = true
	bdlc:debug(playerName..' added to lc')
end

function bdlc:removeFromLC(playerName)
	bdlc.loot_council[playerName] = nil
	bdlc:debug(playerName..' removed from lc')
end

function bdlc:addremoveLC(msg, name)
	if (not name) then print("bdlc: Please provide a name to add to the loot council") return false end
	
	local targetname = FetchUnitName(name)
	if (not targetname) then print("bdlc: Couldn't find any player named "..name..". (they must be in the same group as you) ") return false end
	

	if (msg == "addtolc") then
		bdlc_config.custom_council[targetname] = true
		if (IsMasterLooter() or IsRaidLeader() or not IsInRaid()) then
			bdlc.loot_council[targetname] = true
			bdlc:sendAction("addToLC", targetname);
			print("bdlc: Adding "..targetname.." to loot council.")
			SendChatMessage("bdlc: You've been added to loot council for this raid", "WHISPER", nil, targetname)
		else
			print("bdlc: Since you are not group leader or loot master, the player has been added to your own loot council for the next time that you are.")
		end
	else
		bdlc_config.custom_council[targetname] = nil
		if (IsMasterLooter() or IsRaidLeader() or not IsInRaid()) then
			bdlc.loot_council[targetname] = nil
			bdlc:sendAction("removeFromLC", targetname);
			print("bdlc: Removing "..targetname.." from loot council.")
		else
			print("bdlc: Since you are not group leader or loot master, the player has been removed from your own loot council, not the group's as a whole.")
		end
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

	if (IsMasterLooter() or not IsInRaid()) then		
		bdlc:debug("building LC")

		local min_rank
		if (bdlc_config.lc_rank) then
			min_rank = strsplit(": ",bdlc_config.lc_rank)
		else
			min_rank = bdlc_config.council_min_rank
		end
		min_rank = tonumber(min_rank)
		
		local autocouncil = {}
		local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		local numRaid = GetNumGroupMembers()
		if (numRaid == 0) then
			numRaid = 1
		end
		local inraid = {}
		inraid[playerName] = true

		for i = 1, numRaid do
			local name = FetchUnitName("raid"..i) or FetchUnitName("party"..i)
			inraid[name] = true
		end

		for i = 1, numGuildMembers do
			local fullName, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, reputation = GetGuildRosterInfo(i)

			if (online and rankIndex <= min_rank) then
				local name = FetchUnitName(fullName)
				autocouncil[name] = true
				bdlc.loot_council[name] = true
			end
		end


		-- now send actions all at once to reduce gap
		--bdlc:sendAction("clearLC");
		bdlc:sendAction("clearMLSettings");
		bdlc:sendAction("findEnchanters");

		-- People who are in your custom loot council
		for k, v in pairs (bdlc_config.custom_council) do
			if (inraid[k]) then
				bdlc.loot_council[k] = true
				bdlc:sendAction("addToLC", k);
			end
		end
		
		-- People who are added via rank
		for k, v in pairs (autocouncil) do
			bdlc:sendAction("addToLC", k);
		end
		
		-- Quick notes
		local notes = {}
		for k, v in pairs(bdlc_config.custom_qn) do
			--table.insert(notes, k)
			bdlc:sendAction("customQN", k);
		end
	end
end
