local bdlc, l, f = select(2, ...):unpack()
bdlc.versions = {}

function bdlc:sendVersion(version, player)
	bdlc.versions[version] = bdlc.versions[version] or {}
	bdlc.versions[version][player] = true
end

function bdlc:versionCheck(checker)
	local version = bdlc.config.version
	SendAddonMessage(bdlc.message_prefix, "sendVersion><"..version.."><"..bdlc.local_player, "WHISPER", checker);
end

function bdlc:checkVersions()
	bdlc.versions = {}
	SendAddonMessage(bdlc.message_prefix, "versionCheck><"..bdlc.local_player, bdlc.sendTo, UnitName("player"));
	
	local noaddon = {}
	for i = 1, GetNumGroupMembers() do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		noaddon[name] = true
	end
	
	local total = 0
	bdlc:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed
		if (total > 1) then
			total = 0;
			
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
			
			bdlc.versions = {}
			bdlc:SetScript("OnUpdate", function() return end)
		end
	end)
end