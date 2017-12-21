local bdlc, l, f = select(2, ...):unpack()
bdlc.versions = {}

function bdlc:sendVersion(version, player)
	bdlc.versions[version] = bdlc.versions[version] or {}
	bdlc.versions[version][player] = true
end

function bdlc:versionCheck()
	local version = bdlc.config.version
	bdlc:sendAction("sendVersion", version, bdlc.local_player);
end

function bdlc:checkVersions()
	bdlc.versions = {}
	bdlc:sendAction("versionCheck");
	
	local noaddon = {}
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		noaddon[name] = true
	end

	print("BDLC: Building version list, waiting 3s for responses");

	C_Timer.After(3, function()
		for version, players in pairs(bdlc.versions) do
			local printString = version..": " 
			for name, _ in pairs (players) do
				noaddon[name] = nil
				printString = printString..name..", "
			end
			print(string.sub(printString,0,-2))
		end
		
		if (#noaddon > 0) then
			local printString = "BDLC not installed: "
			for name, v in pairs(noaddon) do
				printString = printString..name..", "
			end
			print(printString)
		end
	end)
end