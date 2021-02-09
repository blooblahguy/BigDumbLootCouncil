local bdlc, c, l = unpack(select(2, ...))
local loader = CreateFrame("frame", nil, bdlc)
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
	if (addon ~= bdlc.addonName) then return end
	loader:UnregisterEvent("ADDON_LOADED")

	bdlc.version = GetAddOnMetadata(bdlc.addonName, "Version") 

	-- Register Messages
	bdlc.comm:RegisterComm(bdlc.messagePrefix, function(...)
		bdlc:messageCallback(...)
	end)

	-- config initialize
	-- BDLC_CONFIG = BDLC_CONFIG or bdlc.defaults
	BDLC_CONFIG = bdlc.configDefaults
	BDLC_HISTORY = BDLC_HISTORY or {}
	bdlc.config = BDLC_CONFIG

	bdlc:print("loaded, enjoy!")

	-- bdlc.config_window:RegisterEvent("GUILD_ROSTER_UPDATE")
	-- C_GuildInfo.GuildRoster()

	C_Timer.After(2, function()
		-- require initialize function
		-- if (not bdlc.module.initialize) then
		-- 	bdlc:print(bdlc.module._name, "does not have an initialize() function and can't be loaded")
		-- 	return
		-- end

		-- bdlc:startMockSession()
	end)
end)