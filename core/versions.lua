local bdlc, c, l = unpack(select(2, ...))
bdlc.version = "@project-version@"
bdlc.guild_versions = {}
bdlc.developer = 999999

-- store various versions in here
bdlc.versions = CreateFrame("frame", nil, UIParent)
bdlc.versions:RegisterEvent("LOADING_SCREEN_DISABLED")
bdlc.versions:SetScript("OnEvent", function(self)

end)


--------------------------------------------------
-- BDLC VERSION
-- Returns version or bdlc.developer for developer version
--------------------------------------------------
local function get_version()
	-- this is the developer version
	if (not tonumber(bdlc.config.version) or bdlc.config.version == "@project-version@") then
		bdlc.config.version = bdlc.developer
	end

	return tonumber(bdlc.config.version)
end

--------------------------------------------------
-- ASK FOR GUILD VERSIONS
-- When a user logs in, check if they should update by using the guild
--------------------------------------------------
function bdlc:guildTopVersion(versionToBeat, sendBackTo)
	local myVersion = get_version()

	-- We have a more recent version than them
	if (myVersion < bdlc.developer and myVersion > versionToBeat) then
		bdlc.overrideChannel = "WHISPER"
		bdlc.overrideRecipient = sendBackTo
		bdlc:sendAction("newerVersion", myVersion);
	end

	-- Wait a second, they are more up to date than us
	if (myVersion < bdlc.developer and versionToBeat > myVersion) then
		bdlc:alertOutOfDate()
	end
end

--------------------------------------------------
-- GET UPDATE ALERT
-- When a user logs in, check if they should update by using the guild
--------------------------------------------------
function bdlc:checkForUpdates()
	bdlc.newestVersion = 0
	-- Only ask if you're not a developer
	if (bdlc:version() < bdlc.developer) then
		bdlc.overrideChannel = "GUILD"
		bdlc:sendAction("guildTopVersion", get_version(), bdlc.localPlayer);
	end

	-- wait 4 seconds for all responses to come back
	C_Timer.After(4, function()
		if (bdlc.newestVersion > get_version()) then
			bdlc:alertOutOfDate()
		end
	end)
end



function bdlc:newerVersion(version)
	if (version > bdlc.newestVersion) then
		bdlc.newestVersion = version
	end
end

function bdlc:alertOutOfDate()
	if (not bdlc.alertedOutOfDate) then
		bdlc.print("You're out of date! Please update as soon as possible, old versions will often break and send lua errors to other players.")
		bdlc.print("Your version: "..get_version())
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

	bdlc:sendAction("returnVersion", bdlc.local_player);

	local noAddon = {}
	for i = 1, GetNumGroupMembers() do
		local name = select(1, GetRaidRosterInfo(i))
		noAddon[name] = true
	end

	bdlc.print("Building version list, waiting 4 seconds for responses.");

	C_Timer.After(4, function()
		local newestVersion = 0

		for version, players in pairs(bdlc.versions) do
			-- print(version, player)
			local version = tonumber(version)
			if (version < 10000) then
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
	local myVersion = bdlc:version()

	bdlc.overrideChannel = "WHISPER"
	bdlc.overrideRecipient = sendBackTo
	bdlc:sendAction("raiderVersion", myVersion, bdlc.local_player);
end

function bdlc:raiderVersion(version, player)
	-- print(version, player)
	bdlc.versions[version] = bdlc.versions[version] or {}
	bdlc.versions[version][player] = true
end

function bdlc:alertRecent(newestVersion)
	local myVersion = bdlc:version()
	bdlc.newestVersion = newestVersion

	if (myVersion < newestVersion) then
		bdlc:alertOutOfDate()
	end
end
