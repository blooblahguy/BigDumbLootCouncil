local bdlc, c, l = unpack(select(2, ...))
local loader = CreateFrame("frame", nil, bdlc)
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
	if (addon ~= bdlc.addonName) then return end
	loader:UnregisterEvent("ADDON_LOADED")

	-- Register Messages
	bdlc.comm:RegisterComm(bdlc.messagePrefix, function(...)
		bdlc:messageCallback(...)
	end)

	-- config initialize
	-- BDLC_CONFIG = BDLC_CONFIG or bdlc.defaults
	BDLC_CONFIG = bdlc.configDefaults
	BDLC_HISTORY = BDLC_HISTORY or {}
	bdlc.config = BDLC_CONFIG
	-- print(bdlc.config)

	bdlc:print("loaded, enjoy!")

	-- C_Timer.After(2, function()
	-- 	bdlc:startMockSession()
	-- end)
end)