local bdlc, c, l = unpack(select(2, ...))

--==========================================
-- Sessions
--==========================================
function bdlc:startSession(itemLink, lootedBy, forced, rollID)
	if (not itemLink) then return end
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	lootedBy = lootedBy and bdlc:FetchUnitName(lootedBy) or ""

	-- convert these from "1" or "0" to true or false booleans
	if (type(forced) == "string") then
		forced = tonumber(forced) == 1 and true or false
	end
	-- roll needs to be something for uid
	if (rollID == nil or rollID == false) then rollID = -1 end
	if (type(rollID) == "string") then
		rollID = tonumber(rollID)
	end

	-- check if item is cached in wow
	if (GetItemInfo(itemLink)) then
		local itemUID = bdlc:GetItemUID(itemLink, lootedBy, rollID)
		bdlc.itemMap[itemUID] = itemLink

		if (bdlc:itemValidForSession(itemLink, lootedBy, false, rollID) or forced) then
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
		-- need to await server async info
		bdlc.items_waiting_for_session[itemID] = {itemLink, lootedBy, forced, rollID}
		GetItemInfo(itemLink) -- queue the server
	end
end

----------------------------------------
-- Fired when an item is received via chat (trade or loot)
----------------------------------------
function bdlc:StartSessionFromTradable(itemLink, arg1, arg2, forced)
	if (not IsInRaid() and not bdlc.enableTests) then return end

	local delay = 1

	if (not itemLink and (arg1 or arg2)) then -- coming from chat
		local myItem = LOOT_ITEM_PUSHED_SELF:gsub('%%s', '(.+)');
		local myLoot = LOOT_ITEM_SELF:gsub('%%s', '(.+)');
		itemLink = arg1:match(myLoot) or arg1:match(myItem)
	else -- being manually called
		delay = 0 -- this means we have the itemLink and don't need to play safe
	end

	if (itemLink) then -- if this doesn't exist then this should be an item at all?
		GetItemInfo(itemLink)

		C_Timer.After(delay, function()
			local itemUID = bdlc:GetItemUID(itemLink, false, -1)

			-- this was traded to me, ignore it
			if (bdlc.tradedItems[itemUID]) then
				bdlc:debug('Experimental: Item received via trading, will not be announced again.')
				return
			end

			-- can we trade this item? scan the tooltip
			if (bdlc:verifyTradability(itemLink)) then
				bdlc:debug(itemLink, "is tradable")
				bdlc:sendAction("startSession", itemLink, bdlc:FetchUnitName('player'), 0, 0)
			end
		end)
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
	lootedBy = lootedBy and bdlc:FetchUnitName(lootedBy) or ""

	local itemLink = bdlc.itemMap[itemUID]
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	
	bdlc.window:Show()
	local name, color = bdlc:prettyName(lootedBy)
	
	-- Set Up tab and item info
	local tab = bdlc:getTab(itemUID)
	tab:Show()
	tab.itemUID = itemUID
	tab.itemLink = itemLink
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
	tab.table.item.itemdetail:SetText("ilvl: "..ilvl.."    "..subclass..", "..slotname);

	tab.table.item.itemLink = itemLink
	
	bdlc:repositionFrames()
end

function bdlc:createRollWindow(itemUID, lootedBy)
	lootedBy = lootedBy and bdlc:FetchUnitName(lootedBy) or ""

	local roll = bdlc:getRoll(itemUID)
	local itemLink = bdlc.itemMap[itemUID]
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)

	local name, color = bdlc:prettyName(lootedBy)

	-- reroll button for tier
	if (bdlc:isTier(itemLink)) then
		roll.buttons["Reroll"]:Show()
	else
		roll.buttons["Reroll"]:Hide()
	end

	roll:Show()
	roll.itemUID = itemUID
	roll.item.icon.tex:SetTexture(texture)
	roll.item.item_text:SetText(itemLink)

	-- for tooltips
	roll.item.icon.itemLink = itemLink
	roll.item.num_items:SetText("Looted by "..name)

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
			bdlc:skinButton(qn, true)
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
-- UpdateUserNote
----------------------------------------
function bdlc:updateUserNote(itemUID, playerName, notes)
	local playerName = bdlc:FetchUnitName(playerName)
	local itemLink = bdlc.itemMap[itemUID]
	
	if not bdlc:inLC() then return false end
	if (not bdlc.loot_sessions[itemUID]) then return false end

	local entry = bdlc:getEntry(itemUID, playerName)
	if (not entry) then return end
	
	-- add notes
	entry.notes = notes
	if (notes and tostring(notes) and strlen(notes) > 1) then
		entry.user_notes:Show()
	else
		entry.user_notes:Hide()
	end

	entry:updated()
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

function bdlc:addUserWant(itemUID, playerName, want, itemLink1, itemLink2, roll, ilvl, guildRank, notes, quicknotes)
	playerName = bdlc:FetchUnitName(playerName)

	if (not notes or strlen(notes) == 0) then notes = false end
	local itemLink = bdlc.itemMap[itemUID]

	if (not bdlc.loot_sessions[itemUID]) then return end
	if (not bdlc:inLC()) then return false end
	
	-- -- actual want text
	local entry = bdlc:getEntry(itemUID, playerName)
	if (not entry) then return end

	bdlc.loot_want[itemUID][playerName] = {itemUID, playerName, want, itemLink1, itemLink2, notes}
	
	local wantText, wantColor = unpack(bdlc.buttons[want])

	bdlc:debug("User want:", playerName, itemLink, wantText)

	local name, color = bdlc:prettyName(playerName)
	entry.name.text:SetText(name)
	entry:Show()
	entry.interest.text:SetText(wantText)
	entry.interest.text:SetTextColor(unpack(wantColor))
	entry.voteUser:Show()
	entry.roll = roll
	entry.myilvl = tonumber(ilvl) or 0
	entry.wantLevel = want
	entry.itemUID = itemUID
	entry.playerName = playerName
	entry.rank:SetText(guildRank)
	entry.ilvl:SetText(ilvl)

	entry.updated()

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
	bdlc:updateUserNote(itemUID, playerName, notes)
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

		bdlc:updateVotesRemaining(itemUID, bdlc.localPlayer)
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

	-- bdlc:sendAction("addLootHistory", itemUID, playerName)

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

-- function bdlc:addLootHistory(itemUID, playerName)
-- 	local today = date("%m-%d-%Y")
-- 	local month, day, year = strsplit("-", today)
-- 	local today = tostring(strtotime(month, day, year))

-- 	if (not bdlc.loot_sessions[itemUID]) then return end
-- 	if (not bdlc:inLC()) then return false end
-- 	if (not bdlc.loot_want[itemUID] or bdlc.loot_want[itemUID][playerName]) then
-- 		return
-- 	end
	
-- 	-- loot info
-- 	local lootedBy = bdlc.loot_sessions[itemUID]
-- 	local itemLink = bdlc.itemMap[itemUID]

-- 	bdlc:debug("add loot history", playerName, today, itemLink)

-- 	-- store player entries by day
-- 	BDLC_HISTORY[playerName] = BDLC_HISTORY[playerName] or {}
-- 	BDLC_HISTORY[playerName][today] = BDLC_HISTORY[playerName][today] or {}

-- 	-- data table
-- 	local itemID, gem1, bonusID1, bonusID2, upgradeValue, lootedBy = strsplit(":", itemUID)
	
-- 	-- information about why they were in on the item
-- 	local itemUID, playerName, want, itemLink1, itemLink2, notes = unpack(bdlc.loot_want[itemUID][playerName])
-- 	local want, wantColor = unpack(bdlc.buttons[want])
-- 	wantColor = bdlc:RGBPercToHex(unpack(wantColor))

-- 	-- info on items
-- 	local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture, vendorPrice = GetItemInfo(itemLink)
-- 	local itemName1, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture1, vendorPrice = GetItemInfo(itemLink1)
-- 	local itemName2, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemTexture2, vendorPrice = GetItemInfo(itemLink2)

-- 	-- now store it
-- 	local entry = {}
-- 	entry['itemName'] = itemName
-- 	entry['itemTexture'] = itemTexture
-- 	entry['date'] = date("%m-%d-%y")
-- 	entry['itemLink'] = itemLink
-- 	entry['lootedBy'] = lootedBy
-- 	entry['entry'] = {
-- 		['want'] = want,
-- 		['wantString'] = "|cff"..wantColor..want.."|r",
-- 		['itemLink1'] = itemLink1,
-- 		['itemTexture1'] = itemTexture1,
-- 		['itemLink2'] = itemLink2,
-- 		['itemTexture2'] = itemTexture2,
-- 		['notes'] = notes,
-- 	}

-- 	local num = getn(BDLC_HISTORY[playerName][today])

-- 	BDLC_HISTORY[playerName][today][num + 1] = entry
-- end

-- return loot history by player
-- function bdlc:getLootHistory(playerName)
-- 	local today = date("%m-%d-%Y")
-- 	local month, day, year = strsplit("-", today)
-- 	local today = strtotime(month, day, year)

-- 	local last_month = days_ago(today, 45)

-- 	local history = {}
-- 	local remove = {}

-- 	if (not BDLC_HISTORY[playerName]) then return {} end

-- 	for loot_date, entries in bdlc:spairs(BDLC_HISTORY[playerName], function(a, b)
-- 		return tonumber(a) > tonumber(b)
-- 	end) do
-- 		loot_date = tonumber(loot_date)
-- 		-- was in the last 30 days
-- 		if (loot_date > last_month) then
-- 			-- return any multiple entries from one day
-- 			for i = 1, #entries do
-- 				table.insert(history, entries[i])
-- 			end
-- 		else
-- 			-- remove this
-- 			table.insert(remove, loot_date)
-- 		end
-- 	end

-- 	-- now loop through remove and remove these items
-- 	-- print(#remove)
-- 	-- for loot_date, entries in pairs(remove) do
-- 	-- 	BDLC_HISTORY[playerName][loot_date] = nil
-- 	-- end

-- 	-- done
-- 	return history
-- end

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
	if (bdlc[action] or not params) then
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
	councilName = bdlc:FetchUnitName(councilName) --councilName:utf8lower()

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

function bdlc:voteForUser(councillorName, itemUID, playerEntryName, lcl)
	if (not bdlc.loot_sessions[itemUID]) then bdlc:debug("Votes failed, no session for itemuid") return false end
	if (not bdlc.loot_council_votes[itemUID]) then bdlc:debug("Vote failed, no votes for itemuid") return false end
	if not bdlc:inLC() then return false end

	councillorName = bdlc:FetchUnitName(councillorName)
	playerEntryName = bdlc:FetchUnitName(playerEntryName)
	
	-- allow local voting
	if (not lcl and bdlc.localPlayer == councillorName) then bdlc:debug("Votes failed, not in lc") return end

	local itemLink = bdlc.itemMap[itemUID]
	local numvotes = tonumber(bdlc.council_votes) --1 --#bdlc.item_drops[itemLink]
	local votes = bdlc.loot_council_votes[itemUID]

	-- if they haven't voted yet, then give them # votes
	if (not votes[councillorName]) then
		votes[councillorName] = {}
		for v = 1, numvotes do
			votes[councillorName][v] = false
		end
	end

	-- only let them vote for each player once
	local hasVotedForPlayer = false
	for v = 1, numvotes do
		if (votes[councillorName][v] == playerEntryName) then hasVotedForPlayer = v break end
	end

	if (hasVotedForPlayer) then
		votes[councillorName][hasVotedForPlayer] = false
		if (bdlc.localPlayer == councillorName) then
			local entry = bdlc:getEntry(itemUID, playerEntryName)
			entry.voteUser:SetText(l["frameVote"])
		end
	else
		-- disable rolling votes? limit at # here
		local currentvotes = 0;
		for v = 1, numvotes do
			if (votes[councillorName][v]) then
				currentvotes = currentvotes + 1
			end
		end

		if (currentvotes < numvotes) then
			-- reset the table
			local new = {}
			new[1] = false -- reserve pos 1
			for v = 1, numvotes do
				if (votes[councillorName][v]) then -- correct any table key gaps
					new[#new+1] = votes[councillorName][v]
				end
			end
			votes[councillorName] = new -- reset the tables keys

			-- remove the least recent vote
			if (bdlc.localPlayer == councillorName) then
				-- local entry = bdlc:getEntry(itemUID, votes[councillorName][numvotes+1])
				local entry = bdlc:getEntry(itemUID, playerEntryName)
				entry.voteUser:SetText(l["frameVote"])
			end
			votes[councillorName][numvotes+1] = nil 

			votes[councillorName][1] = playerEntryName -- prepend the vote
			if (bdlc.localPlayer == councillorName) then
				local entry = bdlc:getEntry(itemUID, playerEntryName)
				entry.voteUser:SetText(l["frameVoted"])
			end
		end

	end
	bdlc:updateVotesRemaining(itemUID, councillorName)

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
		local itemLink = bdlc.items_waiting_for_verify[itemID]

		bdlc:StartSessionFromTradable(itemLink)

		bdlc.items_waiting_for_verify[itemID] = nil
	end

	-- startable in session, but didn't know what it was yet
	if (bdlc.items_waiting_for_session[itemID]) then
		local itemLink, lootedBy, forced, rollID = unpack(bdlc.items_waiting_for_session[itemID])

		bdlc:startSession(itemLink, lootedBy, forced, rollID)

		bdlc.items_waiting_for_session[itemID] = nil
	end

	-- updating users current gear
	if (bdlc.player_items_waiting[itemID]) then
		local itemLink, gear = unpack(bdlc.player_items_waiting[itemID])

		bdlc:updateUserItem(itemLink, gear)

		bdlc.player_items_waiting[itemID] = nil
	end
end)


