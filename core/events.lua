local bdlc, c, l = unpack(select(2, ...))

local _GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local _GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container.GetContainerNumFreeSlots

-- Cache player inventory immediately, just makes things easier
if (not IsAddOnLoaded('Blizzard_ArtifactUI')) then
	LoadAddOn("Blizzard_ArtifactUI")
end

-- inventory
for i = 1, 19 do
	local link = GetInventoryItemLink("player", i)
end

local events = CreateFrame("frame", nil, UIParent)
events:RegisterEvent("BOSS_KILL")
events:RegisterEvent("START_LOOT_ROLL")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent('TRADE_ACCEPT_UPDATE')
events:SetScript("OnEvent", function(self, event, arg1, arg2)
	-- when a boss dies it's time for more sessions
	if (event == "BOSS_KILL") then
		bdlc.item_drops = {}
		bdlc.tradedItems = {}

		return
	end

	-- starts sessions even without looting the item
	if (event == "LOOT_OPENED" and IsInRaid()) then
		local num_free = 0
		local remaining_loot = 0
		
		-- loop through loot items and put them into bags to start sessions
		-- if for some reason you have more than 1 item in the loot window this supports that
		-- this also deletes greys if you have full bags
		-- for slot = 1, GetNumLootItems() do
		-- 	local texture, item, quantity, something, quality, locked = GetLootSlotInfo(slot)

		-- 	if (quality and quality > 3) then
		-- 		local itemLink = GetLootSlotLink(slot)
		-- 		remaining_loot = remaining_loot + 1

		-- 		-- get number of open bag slots
		-- 		for b = 0, 4 do
		-- 			num_free = num_free + _GetContainerNumFreeSlots(b);
		-- 		end

		-- 		if (num_free == 0) then
		-- 			bdlc:print("You have full bags! Delete something to loot "..itemLink)
		-- 		end

		-- 		-- alert my raid that this exists
		-- 		if (num_free == 0) then
		-- 			SendChatMessage("BDLC: I have full bags but I looted "..itemLink, "RAID")
		-- 		elseif (bdlc:IsInRaidInstance()) then
		-- 			LootSlot(slot)
		-- 		end
		-- 	end
		-- end

		return
	end

	-- log items being trades
	if (event == "TRADE_ACCEPT_UPDATE") then
		for i = 1, 6 do
			local chatItemLink = GetTradeTargetItemLink(i);
			local name, _, quantity, quality, isUsable, _ = GetTradeTargetItemInfo(i)
			
			if (quantity == 1) then 
				-- Exists, not stackable
				local a1, a2, a3, itemLink = string.find(chatItemLink, "(|H(.+)|h)");
				a1, a2, itemLink = string.find(itemLink, "(.-|h)");
				
				local itemUID = bdlc:GetItemUID(itemLink, false, -1)

				-- Registering a filter
				bdlc.tradedItems[itemUID] = time()
			end
		end
	end

	-- Now in DF we get roll windows for group loot, start off of those
	if (event == "START_LOOT_ROLL" and bdlc:IsRaidLeader()) then
		local itemLink = GetLootRollItemLink(arg1)
		bdlc:sendAction("startSession", itemLink, bdlc:FetchUnitName('player'), 0, arg1)
		return
	end

	-- When a user loots an item, snag that item link and attempt a session
	if (event == "CHAT_MSG_LOOT") then
		bdlc:StartSessionFromTradable(nil, arg1, arg2)
	end
end)