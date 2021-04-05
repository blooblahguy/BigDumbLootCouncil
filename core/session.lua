local bdlc, c, l = unpack(select(2, ...))

--==========================================
-- Sessions
--==========================================
function bdlc:startSession(itemLink, lootedBy, forced)
	if (not itemLink) then return end
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)
	
	if (GetItemInfo(itemLink)) then
		local itemUID = bdlc:GetItemUID(itemLink, lootedBy)
		bdlc.itemMap[itemUID] = itemLink

		if (bdlc:itemValidForSession(itemLink, lootedBy) or tonumber(forced) == 1) then
			bdlc:debug("Starting session for "..itemLink)
			bdlc.loot_sessions[itemUID] = lootedBy
			bdlc.loot_want[itemUID] = {}

			if (bdlc:inLC()) then
				bdlc.loot_council_votes[itemUID] = {} 
				bdlc:createVoteWindow(itemUID, lootedBy)
				bdlc:updateVotesRemaining(itemUID, bdlc.localPlayer)
			end

			bdlc:createRollWindow(itemUID, lootedBy)
		end
	else
		bdlc.items_waiting_for_session[itemID] = {itemLink, lootedBy, forced}
		local name = GetItemInfo(itemLink)
	end
end

----------------------------------------
-- EndSession
----------------------------------------
function bdlc:endSession(itemUID)
	local itemLink = bdlc.itemMap[itemUID]

	if not itemLink then return end

	local tab = bdlc:getTab(itemUID)
	tab.itemUID = nil
	tab.entries:ReleaseAll()
	bdlc.tabs:Release(tab)

	local roll = bdlc:getRoll(itemUID)
	bdlc.rolls:Release(roll)

	bdlc.item_drops[itemLink] = nil
	bdlc.loot_sessions[itemUID] = nil
	bdlc.loot_council_votes[itemUID] = nil
	bdlc.loot_want[itemUID] = nil
	
	bdlc:repositionFrames()

	-- just to kill fringe cases
	C_Timer.After(1, function()
		bdlc:repositionFrames()
	end)
end

function bdlc:createVoteWindow(itemUID, lootedBy)
	local itemLink = bdlc.itemMap[itemUID]
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	
	bdlc.window:Show()
	local name, color = bdlc:prettyName(lootedBy)
	
	-- Set Up tab and item info
	local tab = bdlc:getTab(itemUID)
	tab:Show()
	tab.itemUID = itemUID
	tab.icon:SetTexture(texture)
	tab.table.item.itemtext:SetText(itemLink)
	tab.table.item.num_items:SetText("Looted by "..name)
	tab.table.item.num_items:SetTextColor(1, 1, 1)
	tab.table.item.icon.tex:SetTexture(texture)

	local ilvl, wf_tf, socket, infostr = bdlc:GetItemValue(itemLink)
	tab.wfsock:SetText(infostr)
	tab.table.item.wfsock:SetText(infostr)

	local slotname = string.lower(string.gsub(equipSlot, "INVTYPE_", ""));
	slotname = slotname:gsub("^%l", string.utf8upper)
	tab.table.item.itemdetail:SetText("ilvl: "..iLevel.."    "..subclass..", "..slotname);
	tab.table.item:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end)
	tab.table.item:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	
	bdlc:repositionFrames()
end

function bdlc:createRollWindow(itemUID, lootedBy)
	local roll = bdlc.rolls:Acquire()
	local itemLink = bdlc.itemMap[itemUID]
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)

	local name, color = bdlc:prettyName(lootedBy)

	roll:Show()
	roll.itemUID = itemUID
	roll.item.icon.tex:SetTexture(texture)
	roll.item.item_text:SetText(itemLink)

	-- for tooltips
	roll.item.icon.itemLink = itemLink
	roll.item.num_items:SetText("Looted by "..name)
	
	-- custom quick notes
	for i = 1, 10 do
		roll.buttons.note.quicknotes[i]:SetText("")
		roll.buttons.note.quicknotes[i]:Hide()
		roll.buttons.note.quicknotes[i]:SetAlpha(0.6)
		roll.buttons.note.quicknotes[i].selected = false
	end

	local ml_qn = {}
	if (bdlc.master_looter_qn) then
		for k, v in pairs(bdlc.master_looter_qn) do
			table.insert(ml_qn, k)
		end
		table.sort(ml_qn)
		for k, v in pairs(ml_qn) do
			local qn
			for i = 1, 10 do
				local rqn = roll.buttons.note.quicknotes[i]
				if (not rqn:IsShown()) then
					qn = rqn
					break
				end
			end
			qn:Show()
			qn:SetText(v)
			bdlc:skinButton(qn,false)
		end
	end

	local ilvl, wf_tf, socket, infostr = bdlc:GetItemValue(itemLink)
	roll.item.icon.wfsock:SetText(infostr)
	
	if bdlc:itemEquippable(itemUID) then
		bdlc:debug("I can use", itemLink)
		bdlc:sendAction("addUserConsidering", itemUID, bdlc.localPlayer);
	else
		bdlc:debug("I can't use", itemLink, "so I pass.")
		local itemLink1, itemLink2 = bdlc:fetchUserGear("player", itemLink)
		bdlc.rolls:Release(roll)
	end

	bdlc:repositionFrames()
end

----------------------------------------
-- UpdateUserItem
----------------------------------------
function bdlc:updateUserItem(itemLink, frame)
	local texture = select(10, GetItemInfo(itemLink))
	frame:Show()
	frame.tex:SetTexture(texture)
	frame:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

----------------------------------------
-- AddUserConsidering
----------------------------------------
function bdlc:addUserConsidering(itemUID, playerName)
	local playerName = bdlc:FetchUnitName(playerName)
	local itemLink = bdlc.itemMap[itemUID]
	
	if not bdlc:inLC() then return false end
	if (not bdlc.loot_sessions[itemUID]) then return false end

	local entry = bdlc:getEntry(itemUID, playerName)
	if (not entry) then return end
	
	bdlc:debug("User considering:", playerName, itemLink)

	local guildName, guildRankName, guildRankIndex = GetGuildInfo(bdlc:FetchUnitName(playerName));
	entry.rankIndex = guildRankName and guildRankIndex or 10

	entry.wantLevel = 15
	entry.notes = ""

	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local name, color = bdlc:prettyName(playerName)
	
	entry:Show()
	entry.name.text:SetText(name)
	entry.name.text:SetTextColor(color.r, color.g, color.b);
	entry.interest.text:SetText(l["frameConsidering"]);
	entry.interest.text:SetTextColor(.5,.5,.5);
	entry.gear1:Hide()
	entry.gear2:Hide()
	entry.ilvl:SetText("")
	entry.rank:SetText("")
	entry.itemUID = itemUID
	entry.playerName = playerName
	
	if (bdlc:IsRaidLeader()) then
		entry.removeUser:Show()
	else
		entry.removeUser:Hide()
	end

	bdlc:repositionFrames()
end

function bdlc:addUserWant(itemUID, playerName, want, itemLink1, itemLink2, roll, ilvl, guildRank, notes)
	playerName = bdlc:FetchUnitName(playerName)

	if (not notes or strlen(notes) == 0) then notes = false end
	local itemLink = bdlc.itemMap[itemUID]

	if (not bdlc.loot_sessions[itemUID]) then return end
	if (not bdlc:inLC()) then return false end
	
	-- -- actual want text
	local entry = bdlc:getEntry(itemUID, playerName)
	if (not entry) then return end

	bdlc.loot_want[itemUID][playerName] = {itemUID, playerName, want, itemLink1, itemLink2, notes}
	
	local wantText, wantColor = unpack(bdlc.config.buttons[want])

	bdlc:debug("User want:", playerName, itemLink, wantText)
	
	entry:Show()
	entry.interest.text:SetText(wantText)
	entry.interest.text:SetTextColor(unpack(wantColor))
	entry.voteUser:Show()
	entry.roll = roll
	entry.myilvl = tonumber(ilvl)
	entry.wantLevel = want
	entry.itemUID = itemUID
	entry.playerName = playerName
	entry.rank:SetText(guildRank)
	entry.ilvl:SetText(ilvl)

	-- player items
	if (GetItemInfo(itemLink1)) then
		local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture1, vendorPrice = GetItemInfo(itemLink1)
		entry.gear1:Show()
		entry.gear1.tex:SetTexture(texture1)
		entry.gear1:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link1)
			GameTooltip:Show()
		end)
		entry.gear1:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		local itemID = select(2, strsplit(":", itemLink1))
		if (itemID) then
			bdlc.player_items_waiting[itemID] = {itemLink1, entry.gear1}
		end
	end

	if (GetItemInfo(itemLink2)) then
		local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture1, vendorPrice = GetItemInfo(itemLink2)
		entry.gear2:Show()
		entry.gear2.tex:SetTexture(texture1)
		entry.gear2:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link1)
			GameTooltip:Show()
		end)
		entry.gear2:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		local itemID = select(2, strsplit(":", itemLink2))
		if (itemID) then
			bdlc.player_items_waiting[itemID] = {itemLink2, entry.gear2}
		end
	end
	
	bdlc:repositionFrames()

	-- add notes
	if (notes and tostring(notes) ~= "0" and string.len(notes) > 1) then
		entry.notes = notes
		entry.user_notes:Show()
	end
end


----------------------------------------
-- RemoveUserConsidering
----------------------------------------
function bdlc:removeUserConsidering(itemUID, playerName)
	if (not bdlc:inLC()) then return end

	playerName = bdlc:FetchUnitName(playerName)

	-- reset frame
	local tab = bdlc:getTab(itemUID)
	local entry = bdlc:getEntry(itemUID, playerName)
	local itemLink = bdlc.itemMap[itemUID]

	tab.entries:Release(entry)

	-- stop if no session exists
	if (not bdlc.loot_sessions[itemUID]) then return false end

	-- reset votes
	if (bdlc.loot_council_votes[itemUID]) then
		for council, tab in pairs(bdlc.loot_council_votes[itemUID]) do
			for v = 1, #bdlc.loot_council_votes[itemUID][council] do
				if (bdlc.loot_council_votes[itemUID][council][v] == playerName) then
					bdlc.loot_council_votes[itemUID][council][v] = false
				end
			end
		end

		bdlc:updateVotesRemaining(itemUID, bdlc:FetchUnitName("player"))
	end

	-- tell that user to kill their roll window
	bdlc.overrideChannel = "WHISPER"
	bdlc.overrideRecipient = playerName
	bdlc:sendAction("removeUserRoll", itemUID, playerName);
	bdlc.loot_want[itemUID][playerName] = nil
	
	bdlc:repositionFrames()
	
	-- bdlc:debug("Removed", playerName, "considering", itemLink)
end

----------------------------------------
-- removeUserRoll
----------------------------------------
function bdlc:removeUserRoll(itemUID, playerName)
	playerName = bdlc:FetchUnitName(playerName)

	if (bdlc.localPlayer == playerName) then
		local roll = bdlc:getRoll(itemUID)
		bdlc.rolls:Release(roll)
		bdlc:repositionFrames()
	end
end

----------------------------------------
-- awardLoot
-- This function alerts awarding and then sends a raid message
----------------------------------------
function bdlc:awardLoot(playerName, itemUID)
	if (not bdlc:IsRaidLeader()) then return end
	
	if (not itemUID) then return end
	local lootedBy = bdlc.loot_sessions[itemUID]
	local itemLink = bdlc.itemMap[itemUID]
	if (not itemLink) then return end

	playerName = bdlc:FetchUnitName(playerName)
	local unit = bdlc:unitName(playerName)

	SendChatMessage("BDLC: Please trade "..itemLink.." to "..unit, "WHISPER", nil, lootedBy)
	SendChatMessage("BDLC: "..lootedBy.."'s "..itemLink.." awarded to "..unit, "RAID")

	bdlc:sendAction("addLootHistory", itemUID, playerName)

	bdlc:repositionFrames()
end

----------------------------------------
-- addLootHistory
-- store log of when / what user was awarded in the past
----------------------------------------
-- idk a shity one, return days since 1-1-2020
local function days_ago(strtime, days)
	return strtime - days
end

local function strtotime(month, day, year)
	local today = date("%m-%d-%Y")
	local d_month, d_day, d_year = strsplit("-", today)
	month = month and tonumber(month) or tonumber(d_month)
	day = month and tonumber(day) or tonumber(d_day)
	year = month and tonumber(year) or tonumber(d_year)

	-- use this for days in each month
	local days_in_month = {
		[1] = 31,
		[2] = 28,
		[3] = 31,
		[4] = 30,
		[5] = 31,
		[6] = 30,
		[7] = 31,
		[8] = 31,
		[9] = 30,
		[10] = 31,
		[11] = 30,
		[12] = 31,
	}

	-- how many days have passed in before this month
	local days_months = 0
	local prev_months = (month - 1)
	if (prev_months > 0) then
		for i = 1, (month - 1) do
			days_months = days_months + (days_in_month[i])
		end
	end

	-- years since 2020 * 365 days a year
	local days_year = (year - 2020) * 365

	return day + days_months + days_year
end

function bdlc:addLootHistory(itemUID, playerName)
	local today = date("%m-%d-%Y")
	local month, day, year = strsplit("-", today)
	local today = tostring(strtotime(month, day, year))
	
	-- loot info
	local lootedBy = bdlc.loot_sessions[itemUID]
	local itemLink = bdlc.itemMap[itemUID]

	bdlc:debug("add loot history", playerName, today, itemLink)

	-- store player entries by day
	BDLC_HISTORY[playerName] = BDLC_HISTORY[playerName] or {}
	BDLC_HISTORY[playerName][today] = BDLC_HISTORY[playerName][today] or {}

	-- data table
	local itemID, gem1, bonusID1, bonusID2, upgradeValue, lootedBy = strsplit(":", itemUID)
	
	-- information about why they were in on the item
	local itemUID, playerName, want, itemLink1, itemLink2, notes = unpack(bdlc.loot_want[itemUID][playerName])
	local want, wantColor = unpack(bdlc.config.buttons[want])
	wantColor = RGBPercToHex(unpack(wantColor))

	-- info on items
	local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture, vendorPrice = GetItemInfo(itemLink)
	local itemName1, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture1, vendorPrice = GetItemInfo(itemLink1)
	local itemName2, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture2, vendorPrice = GetItemInfo(itemLink2)

	-- now store it
	local entry = {}
	entry['itemName'] = itemName
	entry['itemTexture'] = itemTexture
	entry['date'] = date("%m-%d-%y")
	entry['itemLink'] = itemLink
	entry['lootedBy'] = lootedBy
	entry['entry'] = {
		['want'] = want,
		['wantString'] = "|cff"..wantColor..want.."|r",
		['itemLink1'] = itemLink1,
		['itemTexture1'] = itemTexture1,
		['itemLink2'] = itemLink2,
		['itemTexture2'] = itemTexture2,
		['notes'] = notes,
	}

	local num = getn(BDLC_HISTORY[playerName][today])

	BDLC_HISTORY[playerName][today][num + 1] = entry
end

-- return loot history by player
function bdlc:getLootHistory(playerName)
	local today = date("%m-%d-%Y")
	local month, day, year = strsplit("-", today)
	local today = strtotime(month, day, year)

	local last_month = days_ago(today, 45)

	local history = {}
	local remove = {}

	if (not BDLC_HISTORY[playerName]) then return {} end

	for loot_date, entries in bdlc:spairs(BDLC_HISTORY[playerName], function(a, b)
		return tonumber(a) > tonumber(b)
	end) do
		loot_date = tonumber(loot_date)
		-- was in the last 30 days
		if (loot_date > last_month) then
			-- return any multiple entries from one day
			for i = 1, #entries do
				table.insert(history, entries[i])
			end
		else
			-- remove this
			table.insert(remove, loot_date)
		end
	end

	-- now loop through remove and remove these items
	-- print(#remove)
	-- for loot_date, entries in pairs(remove) do
	-- 	BDLC_HISTORY[playerName][loot_date] = nil
	-- end

	-- done
	return history
end

--==========================================
-- Receive messages
--==========================================
local lc_only = {

}
local ml_only = {

}

function bdlc:messageCallback(prefix, message, channel, sender)
	local method, partyMaster, raidMaster = GetLootMethod()
	local pre_params = {strsplit(bdlc.deliminator, message)}
	local params = {}
	local action = false

	for k, v in pairs(pre_params) do
		if (v and v ~= "") then
			if (not action) then
				action = v
			else
				if (tonumber(v)) then
					tinsert(params, tonumber(v))
				else
					tinsert(params, v)
				end
			end
		end
	end

	-- -- auto methods have to force a self param
	if (bdlc[action]) then
		if (params and unpack(params)) then -- if params arne't blank
			bdlc[action](self, unpack(params))
		else
			bdlc[action](self)
		end
	else
		bdlc:debug(action, "not found from", sender, channel);
	end
end


----------------------------------------
-- Voting for users
-- supports multiple votes per officer
----------------------------------------
function bdlc:updateVotesRemaining(itemUID, councilName)
	councilName = councilName:utf8lower()

	if (not bdlc.loot_sessions[itemUID]) then return false end
	if (bdlc.localPlayer ~= councilName) then return end

	local itemLink = bdlc.itemMap[itemUID]
	local numvotes = tonumber(bdlc.council_votes) --1--bdlc.item_drops[itemLink]
	local currentvotes = 0;
	local color = "|cff00FF00"
	local tab = bdlc:getTab(itemUID)

	if (bdlc.loot_council_votes[itemUID][councilName]) then
		for v = 1, numvotes do
			if (bdlc.loot_council_votes[itemUID][councilName][v]) then
				currentvotes = currentvotes + 1
			end
		end
		
		if (numvotes - currentvotes == 0) then
			color = "|cffFF0000"
		end
	end

	tab.table.numvotes:SetText("Your Votes Remaining: "..color..(numvotes - currentvotes).."|r")

	tab = bdlc:getTab(itemUID)
	for entry, k in tab.entries:EnumerateActive() do
		if (numvotes - currentvotes == 0) then
			if (entry.voteUser:GetText() == l['frameVote']) then
				bdlc:skinButton(entry.voteUser, true, 'dark')
			else
				bdlc:skinButton(entry.voteUser, true, 'blue')
			end
		else
			bdlc:skinButton(entry.voteUser, true, 'blue')
		end
	end
end

function bdlc:voteForUser(councilName, itemUID, playerName, lcl)
	if (not bdlc.loot_sessions[itemUID]) then return false end
	if (not bdlc.loot_council_votes[itemUID]) then return false end
	if not bdlc:inLC() then return false end

	councilName = bdlc:FetchUnitName(councilName)
	playerName = bdlc:FetchUnitName(playerName)
	
	-- allow local voting
	if (not lcl and bdlc.localPlayer == councilName) then return end

	local itemLink = bdlc.itemMap[itemUID]
	local numvotes = tonumber(bdlc.council_votes) --1 --#bdlc.item_drops[itemLink]
	local votes = bdlc.loot_council_votes[itemUID]

	-- if they haven't voted yet, then give them # votes
	if (not votes[councilName]) then
		votes[councilName] = {}
		for v = 1, numvotes do
			votes[councilName][v] = false
		end
	end

	-- only let them vote for each player once
	local hasVotedForPlayer = false
	for v = 1, numvotes do
		if (votes[councilName][v] == playerName) then hasVotedForPlayer = v break end
	end

	if (hasVotedForPlayer) then
		votes[councilName][hasVotedForPlayer] = false
		if (bdlc.localPlayer == councilName) then
			local entry = bdlc:getEntry(itemUID, playerName)
			entry.voteUser:SetText(l["frameVote"])
		end
	else
		-- disable rolling votes? limit at # here
		local currentvotes = 0;
		for v = 1, numvotes do
			if (votes[councilName][v]) then
				currentvotes = currentvotes + 1
			end
		end

		if (currentvotes < numvotes) then
			-- reset the table
			local new = {}
			new[1] = false -- reserve pos 1
			for v = 1, numvotes do
				if (votes[councilName][v]) then -- correct any table key gaps
					new[#new+1] = votes[councilName][v]
				end
			end
			votes[councilName] = new -- reset the tables keys

			-- remove the least recent vote
			if (bdlc.localPlayer == councilName) then
				-- local entry = bdlc:getEntry(itemUID, votes[councilName][numvotes+1])
				local entry = bdlc:getEntry(itemUID, playerName)
				entry.voteUser:SetText(l["frameVote"])
			end
			votes[councilName][numvotes+1] = nil 

			votes[councilName][1] = playerName -- prepend the vote
			if (bdlc.localPlayer == councilName) then
				local entry = bdlc:getEntry(itemUID, playerName)
				entry.voteUser:SetText(l["frameVoted"])
			end
		end

	end
	bdlc:updateVotesRemaining(itemUID, councilName)

	-- now loop through and tally
	for itemUID, un in pairs(bdlc.loot_sessions) do
		local tab = bdlc:getTab(itemUID)
		for entry, k in tab.entries:EnumerateActive() do
			if (entry.itemUID) then
				local votes = 0
				for council, v in pairs(bdlc.loot_council_votes[itemUID]) do
					for v = 1, numvotes do
						if bdlc.loot_council_votes[itemUID][council][v] == entry.playerName then
							votes = votes + 1
						end
					end
				end
				entry.votes.text:SetText(votes)
			end

		end
	end
end

--==========================================
-- Async Item Info
-- update - blizzard broke GET_ITEM_INFO_RECEIVED so using this for now
--==========================================
bdlc.async = CreateFrame("frame", nil, UIParent)
bdlc.async:RegisterEvent("GET_ITEM_INFO_RECEIVED")
bdlc.async:SetScript("OnEvent", function(self, event, itemID, success)
	-- couldn't tell if this item could be traded yet
	if (bdlc.items_waiting_for_verify[itemID]) then
		bdlc.items_waiting_for_verify[itemID] = nil

		local itemLink = bdlc.items_waiting_for_verify[itemID]

		if not bdlc.tradedItems[itemLink] then
			-- TODO: This event can't fire after a trade so this test should be removed?
			if (bdlc:verifyTradability(itemLink)) then
				bdlc:sendAction("startSession", itemLink, bdlc:FetchUnitName('player'))
			end
		else
			bdlc:print('Experimental: Item received via trading, will not be announced again.')
		end
	end

	-- startable in session, but didn't know what it was yet
	if (bdlc.items_waiting_for_session[itemID]) then
		bdlc.items_waiting_for_session[itemID] = nil

		local itemLink, lootedBy, forced = unpack(v)
		bdlc:startSession(itemLink, lootedBy, forced)
	end

	-- updating users current gear
	if (bdlc.player_items_waiting[itemID]) then
		bdlc.player_items_waiting[itemID] = nil

		local itemLink, gear = unpack(bdlc.player_items_waiting[itemID])
		bdlc:updateUserItem(itemLink, gear)
	end
end)


-- C_Timer.NewTicker(0.1, function()

-- 	-- Queue items that need to verify tradability
-- 	for itemID, itemLink in pairs(bdlc.items_waiting_for_verify) do
-- 		if (GetItemInfo(itemLink)) then
			
-- 			if not bdlc.tradedItems[itemLink] then
-- 			-- TODO: This event can't fire after a trade so this test should be removed?
-- 				if (bdlc:verifyTradability(itemLink)) then
-- 					bdlc:sendAction("startSession", itemLink, bdlc:FetchUnitName('player'))
-- 				end
-- 			else
-- 				bdlc:print('Experimental: Item received via trading, will not be announced again.')
-- 			end
			
-- 			bdlc.items_waiting_for_verify[itemID] = nil
-- 		end
-- 	end

-- 	-- Queue items that are starting sessions
-- 	for itemID, v in pairs(bdlc.items_waiting_for_session) do
-- 		local itemLink, lootedBy, forced = unpack(v)
-- 		if (GetItemInfo(itemLink)) then
-- 			bdlc:startSession(itemLink, lootedBy, forced)
-- 			bdlc.items_waiting_for_session[itemID] = nil
-- 		end
-- 	end
	
-- 	-- Queue items that are showing user's current gear
-- 	for itemID, v in pairs(bdlc.player_items_waiting) do
-- 		local itemLink, gear = unpack(v)
-- 		if (GetItemInfo(itemLink)) then
-- 			bdlc:updateUserItem(itemLink, gear)
-- 			bdlc.player_items_waiting[itemID] = nil
-- 		end
-- 	end

-- end)
-- bdlc.async:SetScript("OnEvent", function(event, incomingItemID, success)
-- 	if (not success) then
-- 		bdlc:print("Server failed to return ItemInfo for itemID:", incomingItemID)
-- 	end
-- 	-- Queue items that need to verify tradability
-- 	for itemID, v in pairs(bdlc.items_waiting_for_verify) do
-- 		local num1 = tonumber(incomingItemID)
-- 		local num2 = tonumber(itemID)
-- 		if (num1 == num2) then
			
-- 			if not bdlc.tradedItems[v] then
-- 			-- TODO: This event can't fire after a trade so this test should be removed?
-- 				if (bdlc:verifyTradability(v)) then
-- 					bdlc:sendAction("startSession", v, bdlc:FetchUnitName('player'))
-- 				end
-- 			else
-- 				print('Experimental: Item received via trading, will not be announced again.')
-- 			end
			
-- 			bdlc.items_waiting_for_verify[itemID] = nil
-- 		end
-- 	end

-- 	-- Queue items that are starting sessions
-- 	for itemID, v in pairs(bdlc.items_waiting_for_session) do
-- 		local num1 = tonumber(incomingItemID)
-- 		local num2 = tonumber(itemID)
-- 		if (num1 == num2) then
-- 			bdlc:startSession(v[1], v[2], v[3])
-- 			bdlc.items_waiting_for_session[itemID] = nil
-- 		end
-- 	end
	
-- 	-- Queue items that are showing user's current gear
-- 	for itemID, v in pairs(bdlc.player_items_waiting) do
-- 		local num1 = tonumber(incomingItemID)
-- 		local num2 = tonumber(itemID)
-- 		if (num1 == num2) then
-- 			bdlc:updateUserItem(v[1], v[2])
-- 			bdlc.player_items_waiting[itemID] = nil
-- 		end
-- 	end
-- end)