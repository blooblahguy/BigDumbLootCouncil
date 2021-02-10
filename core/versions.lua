local bdlc, c, l = unpack(select(2, ...))

bdlc.guild_versions = {}
bdlc.newestVersion = 0

-- store various versions in here
bdlc.versions = CreateFrame("frame", nil, UIParent)
bdlc.versions:RegisterEvent("PLAYER_LOGIN")
bdlc.versions:SetScript("OnEvent", function(self)
	-- bdlc:checkForUpdates()
end)

--------------------------------------------------
-- ASK FOR GUILD VERSIONS
-- When a user logs in, check if they should update by using the guild
--------------------------------------------------
function bdlc:guildTopVersion(versionToBeat, sendBackTo)
	-- don't count developer
	if (bdlc.version == "@project-version@") then return end

	-- We have a more recent version than them
	if (bdlc.version > versionToBeat) then
		bdlc.overrideChannel = "WHISPER"
		bdlc.overrideRecipient = sendBackTo
		bdlc:sendAction("newerVersion", bdlc.version);
	end

	-- Wait a second, they are more up to date than us
	if (versionToBeat > bdlc.version) then
		bdlc:alertOutOfDate()
	end
end

function bdlc:newerVersion(version)
	bdlc.newestVersion = math.max(bdlc.newestVersion, version)
end

--------------------------------------------------
-- GET UPDATE ALERT
-- When a user logs in, check if they should update by using the guild
--------------------------------------------------
function bdlc:checkForUpdates()
	-- Only ask if you're not a developer
	if (bdlc.version == "@project-version@") then return end
	
	bdlc.newestVersion = 0

	-- ask the guild
	bdlc.overrideChannel = "GUILD"
	bdlc:sendAction("guildTopVersion", bdlc.version, bdlc.localPlayer);

	-- wait x seconds for all responses to come back
	C_Timer.After(5, function()
		if (bdlc.newestVersion > bdlc.version) then
			bdlc:alertOutOfDate()
		else
			bdlc.print("You're up to date. Version: "..bdlc.version)
		end
	end)
end

function bdlc:alertOutOfDate()
	if (not bdlc.alertedOutOfDate) then
		bdlc.print("You're out of date! Please update as soon as possible, old versions will break and send lua errors to other players.")
		bdlc.print("Your version: "..bdlc.version)
		bdlc.print("Most recent version: "..bdlc.newestVersion)
		bdlc.alertedOutOfDate = true
	end
end


--------------------------------------------------
-- VERSION TEST THE RAID
-- Also alerts which players don't have it installed
--------------------------------------------------
function bdlc:checkRaidVersions()
	bdlc.versions = {}

	bdlc:print("Version:", bdlc.version)
	if (not IsInRaid() or not bdlc:inLC() ) then
		bdlc:print("You can only do a version check while in raid and on the loot council")
		return
	end

	bdlc:sendAction("returnVersion", bdlc.localPlayer);

	local noAddon = {}
	for i = 1, GetNumGroupMembers() do
		local name = select(1, GetRaidRosterInfo(i))
		noAddon[name] = true
	end

	bdlc:print("Building version list, waiting 4 seconds for responses.");

	C_Timer.After(4, function()
		local newestVersion = 0

		for version, players in pairs(bdlc.versions) do
			-- print(version, player)
			local version = tonumber(version)
			if (version and version < 10000) then
				local printString = version..": " 

				if (version > newestVersion) then 
					newestVersion = version
				end

				for name, v in pairs (players) do
					noAddon[name] = nil
					printString = printString..name..", "
				end

				print(string.sub(printString,0,-2))
			end
		end
		
		if (#noAddon > 0) then
			local printString = "BDLC not installed: "
			for name, v in pairs(noAddon) do
				printString = printString..name..", "
			end
			print(printString)
		end

		bdlc:sendAction("alertRecent", newestVersion)
	end)

end

function bdlc:returnVersion(sendBackTo)
	bdlc.overrideChannel = "WHISPER"
	bdlc.overrideRecipient = sendBackTo
	bdlc:sendAction("raiderVersion", bdlc.version, bdlc.localPlayer);
end

function bdlc:raiderVersion(version, player)
	-- print(version, player)
	bdlc.versions[version] = bdlc.versions[version] or {}
	bdlc.versions[version][player] = true
end

function bdlc:alertRecent(newestVersion)
	local myVersion = bdlc.version
	bdlc.newestVersion = newestVersion

	if (tonumber(myVersion) and myVersion < newestVersion) then
		bdlc:alertOutOfDate()
	end
end
