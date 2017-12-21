local bdlc, l, f = select(2, ...):unpack()
bdlc.versions = {}

function bdlc:alertRecent(recent)
	local version = bdlc.config.version
	local number = tonumber(version)
	if (number and number < recent) then
		bdlc.print("Your bdlc is out of date! Please update asap. Old BDLC versions will often break for you while sending lua errors to other players.");
	end
end

function bdlc:sendVersion(version, player)
	bdlc.versions[version] = bdlc.versions[version] or {}
	bdlc.versions[version][player] = true
end

function bdlc:versionCheck(sendBackTo)
	local version = bdlc.config.version
	bdlc.overrideChannel = "WHISPER"
	bdlc.overrideSender = sendBackTo
	bdlc:sendAction("sendVersion", version, bdlc.local_player);
end

function bdlc:checkVersions()
	bdlc.versions = {}
	bdlc:sendAction("versionCheck", bdlc.local_player);
	
	local noaddon = {}
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		noaddon[name] = true
	end

	bdlc.print("Building version list, waiting 4 seconds for responses");

	C_Timer.After(4, function()
		local recent = 0
		for version, players in pairs(bdlc.versions) do
			local printString = version..": " 
			local number = tonumber(version)
			if (number and number > recent) then recent = number end

			for name, _ in pairs (players) do
				noaddon[name] = nil
				printString = printString..name..", "
			end
			print(string.sub(printString,0,-2))
		end

		bdlc:sendAction("alertRecent", recent)
		
		if (#noaddon > 0) then
			local printString = "BDLC not installed: "
			for name, v in pairs(noaddon) do
				printString = printString..name..", "
			end
			print(printString)
		end
	end)
end