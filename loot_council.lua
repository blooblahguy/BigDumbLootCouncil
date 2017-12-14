local bdlc, l, f = select(2, ...):unpack()

----------------------------------------
-- Get/add/remove
----------------------------------------
function FetchUnitName(name)
	local name, server = strsplit("-", name)
	-- local n, blank = strsplit("-", name)
	-- local realname, server = UnitFullName(n)
	
	-- if (not server or string.len(server) == 0) then
		-- server = GetRealmName()
	-- end
	
	-- if (not realname) then
		-- --print("Error! can't find any player named either:")
		-- --print(name)
		-- --print(realname)
		
		-- return n.."-"..server;
	-- end
	
	-- return realname.."-"..server
	
	server_name = GetUnitName(name,true)
	if (server_name) then
		name = server_name
	end
	name, server = strsplit("-", name)
	if (not server) then
		server = GetRealmName()
	end
	
	if (name) then
		return name.."-"..server
	else
		return nil
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
	bdlc.enchanters = {}
	bdlc.loot_council = {}
	local min_rank
	if (bdlc_config.lc_rank) then
		min_rank = strsplit(": ",bdlc_config.lc_rank)
	else
		min_rank = bdlc_config.council_min_rank
	end
	min_rank = tonumber(min_rank)

	if (IsMasterLooter() or not IsInRaid()) then
		playerName = FetchUnitName('player')
		bdlc.loot_council[playerName] = true
		bdlc:debug(playerName..' added to lc')
		
		bdlc:sendAction("findEnchanters");
		bdlc:debug("building LC")
		
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

		-- People who are in your custom loot council
		for k, v in pairs (bdlc_config.custom_council) do
			if (inraid[k]) then
				bdlc.loot_council[k] = true
				bdlc:sendAction("addToLC");
			end
		end
		
		-- People who are added via rank
		for k, v in pairs (autocouncil) do
			bdlc:sendAction("addToLC", k);
		end
		
		-- Quick notes
		bdlc:sendAction("wipeQN");
		for k, v in pairs(bdlc_config.custom_qn) do
			bdlc:sendAction("customQN", k);
		end
	end
end
