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
	BDLC_CONFIG = BDLC_CONFIG or bdlc.configDefaults
	BDLC_HISTORY = BDLC_HISTORY or {}
	bdlc.config = BDLC_CONFIG
	
	-- do a one time reset
	if (not bdlc.config.shadowlands) then
		BDLC_CONFIG = bdlc.configDefaults
		bdlc.config = BDLC_CONFIG
		bdlc.config.shadowlands = true
	end

	bdlc:print("loaded, enjoy!")

	-- bdlc.config_window:Show()
	bdlc.council_votes = bdlc.config.council_votes
	bdlc.buttons = bdlc.config.buttons
end)