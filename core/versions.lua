local bdlc, c, l = unpack(select(2, ...))

--------------------------------------------------
-- VERSION TEST THE RAID
-- Also alerts which players don't have it installed
--------------------------------------------------
function bdlc:checkRaidVersions()
	bdlc.versions = {}

	bdlc:print("Your Version:", bdlc.version)
	if (not IsInRaid() ) then
		bdlc:print("You can only do a version check while in raid.")
		return
	end

	-- store a list of users who may not have bdlc
	local noAddon = {}
	for i = 1, GetNumGroupMembers() do
		local name = select(1, GetRaidRosterInfo(i))
		noAddon[name] = true
	end

	-- request raid versions
	bdlc:print("Building version list, waiting 5 seconds for responses.");
	bdlc:sendAction("requestVersions", bdlc.localPlayer);

	-- wait, since we can't really know when all of them are returned
	C_Timer.After(5, function()

		for version, players in pairs(bdlc.versions) do
			local version = tonumber(version)
			if (version) then
				local printString = version..": " 

				-- these players have returned their versions
				for name, v in pairs (players) do
					-- remove from no addon list
					noAddon[name] = nil
					printString = printString..bdlc:prettyName(name)..", "
				end

				-- remove trailing comma
				print(string.sub(printString, 0, -2))
			end
		end
		
		-- these are leftover from the returns
		-- if (#noAddon > 0) then
			local printString = "BDLC not installed: "
			for name, v in pairs(noAddon) do
				printString = printString..bdlc:prettyName(name)..", "
			end

			-- no trailing comma
			print(string.sub(printString, 0, -2))
		-- end
	end)
end

function bdlc:requestVersions(sendBackTo)
	bdlc.overrideChannel = "WHISPER"
	bdlc.overrideRecipient = sendBackTo
	bdlc:sendAction("returnVersion", bdlc.version, bdlc.localPlayer);
end

function bdlc:returnVersion(version, player)
	if (not tonumber(version)) then return end

	bdlc.versions[version] = bdlc.versions[version] or {}
	bdlc.versions[version][player] = true
end

-- @@ exit
--- not doing update checks anymore


-- store various versions in here
-- bdlc.versions = CreateFrame("frame", nil, UIParent)
-- bdlc.versions:RegisterEvent("PLAYER_LOGIN")
-- bdlc.versions:SetScript("OnEvent", function(self)
-- 	-- let's not alert for now
-- 	-- bdlc:checkForUpdates()
-- end)
--------------------------------------------------
-- ASK FOR GUILD VERSIONS
-- When a user logs in, check if they should update by using the guild
--------------------------------------------------
-- function bdlc:guildTopVersion(versionToBeat, sendBackTo)
-- 	-- don't count developer
-- 	if (bdlc.version == "@project-version@") then return end

-- 	-- We have a more recent version than them
-- 	if (bdlc.version > versionToBeat) then
-- 		bdlc.overrideChannel = "WHISPER"
-- 		bdlc.overrideRecipient = sendBackTo
-- 		bdlc:sendAction("newerVersion", bdlc.version);
-- 	end

-- 	-- Wait a second, they are more up to date than us
-- 	if (versionToBeat > bdlc.version) then
-- 		bdlc:alertOutOfDate()
-- 	end
-- end

-- function bdlc:newerVersion(version)
-- 	bdlc.newestVersion = math.max(bdlc.newestVersion, version)
-- end

-- --------------------------------------------------
-- -- GET UPDATE ALERT
-- -- When a user logs in, check if they should update by using the guild
-- --------------------------------------------------
-- function bdlc:checkForUpdates()
-- 	-- Only ask if you're not a developer
-- 	if (bdlc.version == "@project-version@") then return end
	
-- 	bdlc.newestVersion = 0

-- 	-- ask the guild
-- 	bdlc.overrideChannel = "GUILD"
-- 	bdlc:sendAction("guildTopVersion", bdlc.version, bdlc.localPlayer);

-- 	-- wait x seconds for all responses to come back
-- 	C_Timer.After(5, function()
-- 		if (bdlc.newestVersion > bdlc.version) then
-- 			bdlc:alertOutOfDate()
-- 		else
-- 			bdlc.print("You're up to date. Version: "..bdlc.version)
-- 		end
-- 	end)
-- end

-- function bdlc:alertRecent(newestVersion)
-- 	local myVersion = bdlc.version
-- 	bdlc.newestVersion = newestVersion

-- 	if (tonumber(myVersion) and myVersion < newestVersion) then
-- 		bdlc:alertOutOfDate()
-- 	end
-- end

-- function bdlc:alertOutOfDate()
-- 	if (not bdlc.alertedOutOfDate) then
-- 		bdlc.print("You're out of date! Please update as soon as possible, old versions will break and send lua errors to other players.")
-- 		bdlc.print("Your version: "..bdlc.version)
-- 		bdlc.print("Most recent version: "..bdlc.newestVersion)
-- 		bdlc.alertedOutOfDate = true
-- 	end
-- end