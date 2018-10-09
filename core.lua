local bdlc, l, f = select(2, ...):unpack()

local AceComm = LibStub:GetLibrary("AceComm-3.0")

----------------------------------------
-- StartSession
----------------------------------------
function bdlc:itemValidForSession(itemLink, lootedBy)
	local valid = false

	local itemUID = bdlc:GetItemUID(itemLink, lootedBy)
	local isTier = bdlc:IsTier(itemLink)
	local equipSlot = select(9, GetItemInfo(itemLink))
	local isRelic = bdlc:IsRelic(itemLink)

	-- if (not bdlc.loot_sessions[itemUID]) then
	-- 	value = true
	-- end
	-- 	if (bdlc:searchTable(bdlc.loot_sessions, lootedBy) == false) then
	-- 		valid = true
	-- 	end
	-- end

	if (equipSlot and string.len(equipSlot) > 0) then
		valid = true
	end
	if (isTier or isRelic) then
		valid = true
	end
	if (bdlc.forceSession) then
		value = true
		bdlc.forceSession = false
	end

	return valid
end
function bdlc:startSession(itemLink, lootedBy)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)
	
	if (GetItemInfo(itemLink)) then
		local itemUID = bdlc:GetItemUID(itemLink, lootedBy)
		bdlc.itemMap[itemUID] = itemLink
	
		if (bdlc:itemValidForSession(itemLink, lootedBy)) then
			bdlc:debug("Starting session for "..itemLink)
			bdlc.loot_sessions[itemUID] = lootedBy 
			bdlc.loot_want[itemUID] = {} -- will be used to track loot log and also refresh sessions if someone relogs

			if (bdlc:inLC()) then
				bdlc.loot_council_votes[itemUID] = {} 
				bdlc:createVoteWindow(itemUID, lootedBy)
			end

			bdlc:createRollWindow(itemUID, lootedBy)
		end
	else
		bdlc.items_waiting_for_session[itemID] = {itemLink, lootedBy}
		local name = GetItemInfo(itemLink)
	end
end
----------------------------------------
-- EndSession
----------------------------------------
function bdlc:endSession(itemUID)
	local itemLink = bdlc.itemMap[itemUID]

	if not itemLink then return end

	bdlc:endTab(itemUID)
	bdlc:endRoll(itemUID)

	bdlc.item_drops[itemLink] = nil
	bdlc.loot_sessions[itemUID] = nil
	bdlc.loot_council_votes[itemUID] = nil
	bdlc.loot_want[itemUID] = nil
	
	bdlc:repositionFrames()
end

----------------------------------------
-- StartMockSession
----------------------------------------
bdlc.demo_samples = {
	classes = {"HUNTER","WARLOCK","PRIEST","PALADIN","MAGE","ROGUE","DRUID","WARRIOR","DEATHKNIGHT","MONK","DEMONHUNTER"},
	ranks = {"Officer","Raider","Trial","Social","Alt","Officer Alt","Guild Idiot", "King"},
	names = {"OReilly", "Billy", "Tìncan", "Mango", "Ugh", "Onebutton", "Thor", "Deadpool", "Atlas", "Edgelord", "Yeah", "Arranum", "Witts"}
}
function bdlc:startMockSession()
	if (IsInRaid() or IsInGroup() or UnitInRaid("player")) then
		if (not bdlc:inLC()) then
			bdlc.print("You cannot run a test while inside of a raid group unless you are on the Loot Council.")
		end
	end

	local demo_samples = bdlc.demo_samples

	bdlc.print("Starting mock session")
	
	local function rando_name()
		return demo_samples.names[math.random(#demo_samples.names)]
	end
	local function rando_ilvl()
		return math.random(900, 980)
	end
	local function rando_rank()
		return demo_samples.ranks[math.random(#demo_samples.ranks)]
	end
	local function rando_class()
		return demo_samples.classes[math.random(#demo_samples.classes)]
	end
	
	-- add random people, up to a whole raid worth of fakers
	local demo_players = {}
	for i = 5, math.random(6, 30) do
		demo_players[rando_name()] = {rando_ilvl(), rando_rank(), rando_class()}
	end
	
	-- fake build an LC
	bdlc:buildLC()
	local itemslots = {1,2,3,5,8,9,10,11,12,13,14,15}
	bdlc.item_drops = {}
	for i = 1, 4 do
		local index = itemslots[math.random(#itemslots)]
		bdlc.item_drops[GetInventoryItemLink("player", index)] = rando_name()
		table.remove(itemslots,index)
	end

	-- now lets start fake sessions
	for k, v in pairs(bdlc.item_drops) do
		local itemUID = bdlc:GetItemUID(k, v)
		bdlc:sendAction("startSession", k, v);

		-- add our demo players in 
		for name, data in pairs(demo_players) do
			bdlc:sendAction("addUserConsidering", itemUID, name, unpack(data));
		end

		-- send a random "want" after 2-5s, something like a real person
		C_Timer.After(math.random(2, 5), function()
			for name, data in pairs(demo_players) do
				bdlc:sendAction("addUserWant", itemUID, name, math.random(1, 4), 0, 0);
			end
		end)
	end
end

----------------------------------------
-- CreateVoteWindow
----------------------------------------
function bdlc:createVoteWindow(itemUID, lootedBy)
	local itemLink = bdlc.itemMap[itemUID]
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	
	f.voteFrame:Show()
	
	local currenttab = bdlc:getTab(itemUID)
	
	-- Set Up tab and item info
	currenttab:Show()
	currenttab.icon:SetTexture(texture)
	currenttab.table.item.itemtext:SetText(itemLink)

		currenttab.table.item.num_items:SetText("Looted by "..bdlc:prettyName(lootedBy, true))
		currenttab.table.item.num_items:SetTextColor(1,1,1)

	currenttab.table.item.icon.tex:SetTexture(texture)

	local ilvl, wf_tf, socket, infostr = bdlc:GetItemValue(itemLink)
	currenttab.wfsock:SetText(infostr)
	currenttab.table.item.wfsock:SetText(infostr)

	bdlc:updateVotesRemaining(itemUID, FetchUnitName('player'))
	--[[if (wf_tf or socket) then
		currenttab.wfsock:SetText(infostr)
		currenttab:SetBackdropBorderColor(0,.7,0,1)
		currenttab.table.item.wfsock:SetText(infostr)
		currenttab.table.item.icon:SetBackdropBorderColor(0,.7,0,1)
	else
		currenttab.wfsock:SetText("")
		currenttab:SetBackdropBorderColor(0,0,0,1)
		currenttab.table.item.wfsock:SetText("")
		currenttab.table.item.icon:SetBackdropBorderColor(0,0,0,1)
	end--]]
	local slotname = string.lower(string.gsub(equipSlot, "INVTYPE_", ""));
	slotname = slotname:gsub("^%l", string.upper)
	currenttab.table.item.itemdetail:SetText("ilvl: "..iLevel.."    "..subclass..", "..slotname);
	currenttab.table.item:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end)
	currenttab.table.item:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	
	bdlc:repositionFrames()
end

----------------------------------------
-- CreateRollWindow
----------------------------------------
function bdlc:createRollWindow(itemUID, lootedBy)
	local itemLink = bdlc.itemMap[itemUID]
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	rollFrame:Show()
	
	local currentroll = bdlc:getRoll(itemUID)

	currentroll:Show()
	currentroll.item.icon.tex:SetTexture(texture)
	currentroll.item.item_text:SetText(itemLink)

	currentroll.item.num_items:SetText("Looted by "..bdlc:prettyName(lootedBy, true))
	currentroll.item.num_items:SetTextColor(1,1,1)
	
	-- custom quick notes
	for i = 1, 10 do
		currentroll.buttons.note.quicknotes[i]:SetText("")
		currentroll.buttons.note.quicknotes[i]:Hide()
		currentroll.buttons.note.quicknotes[i]:SetAlpha(0.6)
		currentroll.buttons.note.quicknotes[i].selected = false
	end
	local ml_qn = {}
	for k, v in pairs(bdlc.master_looter_qn) do
		table.insert(ml_qn, k)
	end
	table.sort(ml_qn)
	for k, v in pairs(ml_qn) do
		local qn
		for i = 1, 10 do
			local rqn = currentroll.buttons.note.quicknotes[i]
			if (not rqn:IsShown()) then
				qn = rqn
				break
			end
		end
		qn:Show()
		qn:SetText(v)
		bdlc:skinButton(qn,false)
	end

	local ilvl, wf_tf, socket, infostr = bdlc:GetItemValue(itemLink)
	currentroll.item.icon.wfsock:SetText(infostr)

	currentroll.item:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end)
	currentroll.item:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local guildRank = select(2,GetGuildInfo("player")) or ""
	local player_itemlvl = math.floor(select(2, GetAverageItemLevel()))
	
	if bdlc:itemEquippable(itemUID) then
		bdlc:debug("turns out I can use this, doing nothing.")
		bdlc:sendAction("addUserConsidering", itemUID, bdlc.local_player, player_itemlvl, guildRank);
	else
		bdlc:debug("I guess I can't use this, autopassing")
		local itemLink1, itemLink2 = bdlc:fetchUserGear("player", itemLink)
		
		--bdlc:sendAction("removeUserConsidering", itemUID, bdlc.local_player);
		bdlc:endRoll(itemUID)
	end
	bdlc:repositionFrames()
	
end

----------------------------------------
-- RemoveUserRoll
----------------------------------------
function bdlc:removeUserRoll(itemUID, playerName)
	local playerName = FetchUnitName(playerName)
	if (FetchUnitName('player') == playerName) then
		bdlc:endRoll(itemUID)
		bdlc:repositionFrames()
	end
end

----------------------------------------
-- AddUserConsidering
----------------------------------------
function bdlc:addUserConsidering(itemUID, playerName, iLvL, guildRank, playerClass)
	local playerName = FetchUnitName(playerName)
	local itemLink = bdlc.itemMap[itemUID]
	
	if not bdlc:inLC() then return false end
	if (not bdlc.loot_sessions[itemUID]) then return false end

	local currententry = bdlc:getEntry(itemUID, playerName)
	if (not currententry) then return end

	currententry.wantLevel = 15
	currententry.notes = ""
	
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local name, server = strsplit("-", playerName)

	local color = bdlc:prettyName(playerName)
	name = GetUnitName(name, true) or name
	
	currententry:Show()
	currententry.name:SetText(name)
	currententry.server = server
	currententry.name:SetTextColor(color.r,color.g,color.b);
	currententry.interest:SetText("considering...");
	currententry.interest:SetTextColor(.5,.5,.5);
	currententry.rank:SetText(guildRank)
	currententry.ilvl:SetText(iLvL)
	currententry.gear1:Hide()
	currententry.gear2:Hide()
	
	if (IsMasterLooter() or not IsInRaid()) then
		currententry.removeUser:Show()
	else
		currententry.removeUser:Hide()
	end

	bdlc:repositionFrames()
end

----------------------------------------
-- RemoveUserConsidering
----------------------------------------
function bdlc:removeUserConsidering(itemUID, playerName)
	local playerName = FetchUnitName(playerName)

	if (not bdlc:inLC()) then return end
	-- reset frame
	bdlc:endEntry(itemUID, playerName)

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

		bdlc:updateVotesRemaining(itemUID, FetchUnitName("player"))
	end

	-- tell that user to kill their roll window
	bdlc.overrideChannel = "WHISPER"
	bdlc.overrideSemder = playerName
	bdlc:sendAction("removeUserRoll", itemUID, playerName);
	bdlc.loot_want[itemUID][playerName] = nil
	
	bdlc:repositionFrames()

	--local itemLink = bdlc.itemMap[itemUID]
	--if (not itemLink) then return end
	
	bdlc:debug("removed "..playerName.." considering "..itemUID)
end

--[[
function bdlc:addUserItem(itemUID, playerName, itemLink)
	local currententry = bdlc:getEntry(itemUID, playerName)
	if (not currententry) then return end

	
end--]]

----------------------------------------
-- AddUserWant
----------------------------------------
function bdlc:addUserWant(itemUID, playerName, want, itemLink1, itemLink2, notes)
	local playerName = FetchUnitName(playerName)
	if (not notes) then notes = false end
	local itemLink = bdlc.itemMap[itemUID]

	if (not bdlc.loot_sessions[itemUID]) then bdlc:debug(playerName.." rolled on an item with no session") return end
	if (not bdlc:inLC()) then return false end
	
	-- actual want text
	local currententry = bdlc:getEntry(itemUID, playerName)
	if (not currententry) then return end

	bdlc.loot_want[itemUID][playerName] = {itemUID, playerName, want, itemLink1, itemLink2, notes}
	
	local wantText = bdlc.wantTable[want][1]
	local wantColor = bdlc.wantTable[want][2]
	
	bdlc:debug(playerName.." needs "..itemLink.." "..wantText)
	
	currententry.interest:SetText(wantText);
	currententry.interest:SetTextColor(unpack(wantColor));
	currententry.voteUser:Show()
	currententry.wantLevel = want

	-- player items
	if (GetItemInfo(itemLink1)) then
		local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture1, vendorPrice = GetItemInfo(itemLink1)
		currententry.gear1:Show()
		currententry.gear1.tex:SetTexture(texture1)
		currententry.gear1:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link1)
			GameTooltip:Show()
		end)
		currententry.gear1:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		local itemID = select(2, strsplit(":", itemLink1))
		if (itemID) then
			bdlc.player_items_waiting[itemID] = {itemLink1, currententry.gear1}
		end
	end

	if (GetItemInfo(itemLink2)) then
		local itemName, link1, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture1, vendorPrice = GetItemInfo(itemLink2)
		currententry.gear2:Show()
		currententry.gear2.tex:SetTexture(texture1)
		currententry.gear2:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(link1)
			GameTooltip:Show()
		end)
		currententry.gear2:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		local itemID = select(2, strsplit(":", itemLink2))
		if (itemID) then
			bdlc.player_items_waiting[itemID] = {itemLink2, currententry.gear2}
		end
	end
	
	bdlc:repositionFrames()

	-- notes
	bdlc:debug("Add "..playerName.." notes")

	if (notes and string.len(notes) > 0) then
		currententry.notes = notes
		currententry.user_notes:Show()
	end
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
--[[ VoteForUser
	Supports N votes per user. Right now just hard set to 1
--]]
----------------------------------------
function bdlc:updateVotesRemaining(itemUID, councilName)
	if (councilName ~= FetchUnitName('player')) then return end

	local itemLink = bdlc.itemMap[itemUID]
	local numvotes = 1--bdlc.item_drops[itemLink]
	local currentvotes = 0;
	local color = "|cff00FF00"
	local tab = bdlc:getTab(itemUID)

	if (bdlc.loot_council_votes[itemUID][councilName]) then
		for v = 1, numvotes do
			if (bdlc.loot_council_votes[itemUID][councilName][v]) then
				currentvotes = currentvotes + 1
			end
		end
		
		if (numvotes-currentvotes == 0) then
			color = "|cffFF0000"
		end
	end
	tab.table.numvotes:SetText("Your Votes Remaining: "..color..(numvotes-currentvotes).."|r")
	for t = 1, #f.tabs do
		if (f.tabs[t].itemUID == itemUID) then
			local tab = f.tabs[t]

			for e = 1, #f.entries[t] do
				local entry = f.entries[t][e]
				if (numvotes-currentvotes == 0) then
					if (entry.voteUser:GetText() == l['frameVote']) then
						bdlc:skinButton(entry.voteUser,true,'dark')
					else
						bdlc:skinButton(entry.voteUser,true,'blue')
					end
				else
					bdlc:skinButton(entry.voteUser,true,'blue')
				end
			end

			break
		end
	end
end

function bdlc:voteForUser(councilName, itemUID, playerName, lcl)
	if (not bdlc.loot_sessions[itemUID]) then return false end
	if (not bdlc.loot_council_votes[itemUID]) then return false end
	if not bdlc:inLC() then return false end

	local playerName = FetchUnitName(playerName)

	if (not lcl and FetchUnitName('player') == councilName) then return end
	local itemLink = bdlc.itemMap[itemUID]
	local numvotes = 1 --bdlc.item_drops[itemLink]
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
		if (FetchUnitName('player') == councilName) then
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
			if (FetchUnitName('player') == councilName) then
				local entry = bdlc:getEntry(itemUID, votes[councilName][numvotes+1])
				entry.voteUser:SetText(l["frameVote"])
			end
			votes[councilName][numvotes+1] = nil 

			votes[councilName][1] = playerName -- prepend the vote
			if (FetchUnitName('player') == councilName) then
				local entry = bdlc:getEntry(itemUID, playerName)
				entry.voteUser:SetText(l["frameVoted"])
			end
		end

	end
	bdlc:updateVotesRemaining(itemUID, councilName)

	-- now loop through and tally
	for itemUID, un in pairs(bdlc.loot_sessions) do
		for t = 1, #f.tabs do
			if (f.tabs[t].itemUID == itemUID) then
				for e = 1, #f.entries[t] do
					local entry = f.entries[t][e]
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
	end
end


-- logging where loot has gone
function bdlc:addLootHistory(itemUID, playerName)
	local playerName = FetchUnitName(playerName)
	if not(playerName) then return end

	if (not bdlc.loot_want[itemUID] or not bdlc.loot_want[itemUID][playerName]) then return end

	-- fetch some data
	local itemUID, playerName, want, itemLink1, itemLink2, notes = unpack(bdlc.loot_want[itemUID][playerName])
	local itemLink = bdlc.itemMap[itemUID]

	-- compile the entry
	local data = {itemLink, itemUID, playerName, want, itemLink1, itemLink2, notes, time()}
	
	-- get unqiue index of day/time
	local today = date("%m/%d/%Y")
	local hour, minute = GetGameTime()
	local t = hour..":"..minute

	-- setup our tables
	bdlc_history[today] = bdlc_history[today] or {}
	bdlc_history[today][t] = bdlc_history[today][t] or {}
	
	-- log the history
	table.insert(bdlc_history[today][t], data)
end

function bdlc:mainCallback(data)

	local method, partyMaster, raidMaster = GetLootMethod()
	-- if (IsInRaid() ) then
		
		local param = bdlc:split(data,"><")
		local action = param[0] or data
		if (param[0]) then param[0] = nil end

		-- the numbers were made strings by the chat_msg_addon, lets find our numbers and convert them tonumbers
		for p = 0, #param do
			local test = param[p]
			if (tonumber(test)) then
				param[p] = tonumber(param[p])
			end
			if (test == nil or test == "") then
				param[p] = ""
			end
		end

		-- auto methods have to force a self param
		if (bdlc[action]) then
			if (param and unpack(param)) then -- if params arne't blank
				bdlc[action](self, unpack(param))
			else
				bdlc[action](self)
			end
		else
			--bdlc.print("Can't find any function for "..action.." - this usually means someone is out of date");
		end
	-- end
end

-- now that blizzard decided for every single guild on the planet than masterlooting isn't good
-- we have to track which players have looted the boss, and start sessions based on what they got 
-- instead of using a really useful tool that we've all enjoyed since vanilla.

function bdlc:removeLooter(name)
	local name = FetchUnitName(name)
	
	bdlc.looters[name] = nil
	bdlc:drawLooters()
end

function bdlc:startLooterList()
	bdlc.looters = {}
	local p = f.voteFrame.pending
	for r = 1, GetNumGroupMembers() do
		local name = GetRaidRosterInfo(r);
		if (name) then
			name = FetchUnitName(name)
			bdlc.looters[name] = true
		end
	end

	bdlc:drawLooters()

	C_Timer.After(30, function()
		bdlc:alertSlackers()
	end)
end

function bdlc:drawLooters() 
	local text = "";
	for k, v in pairs(bdlc.looters) do
		text = text .. k .. "\n"
	end
	f.voteFrame.pending.text:SetText(text)
end

function bdlc:badGuyLooter(name)

end

-- alert the raid its time to loot the boss
function bdlc:alertRaid()
	SendChatMessage("BDLC: Please loot the boss to start any potential sessions.", "RAID")
end

-- whisper players that haven't yet looted the boss
function bdlc:alertSlackers()
	if (not IsRaidLeader()) then return end
	for k, v in pairs(bdlc.looters) do
		-- these players haven't looted yet
		SendChatMessage("BDLC: You still need to loot the boss in order to start valid sessions.", "WHISPER", nil, k)
	end
end

-- wow needs to query the server for item information and this happens asynchronously. So we should cache it before we need it
function bdlc:cachePlayerItems()
	if (not IsAddOnLoaded('Blizzard_ArtifactUI')) then
		LoadAddOn("Blizzard_ArtifactUI")
	end

	-- inventory
	for i = 1, 19 do
		local link = GetInventoryItemLink("player", i)
	end

	-- relics
	-- SocketInventoryItem(17)
	-- SocketInventoryItem(16)

	-- for relicSlotIndex = 1, C_ArtifactUI.GetNumRelicSlots() do
	-- 	local lockedReason, relicName, relicIcon, relicLink = C_ArtifactUI.GetRelicInfo(relicSlotIndex);
	-- end

	-- -- just safely allow for itemLinks to load
	-- C_Timer.After(1, function() 
	-- 	-- bdlc:GetRelics('nonsense')
	-- 	HideUIPanel(ArtifactFrame)
	-- end)
end

function bdlc:getItemID(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	return itemID
end

function bdlc:verifyTradability(itemLink)
	if (GetItemInfo(itemLink)) then
		if (bdlc:TradableTooltip(itemLink)) then
			if (bdlc.verifyMode) then
				bdlc.print(itemLink.." is tradable!")
			else
				bdlc:sendAction("startSession", itemLink, FetchUnitName('player'))
			end
		else

		end
	else
		local itemID = bdlc:getItemID(itemLink)
		bdlc.items_waiting_for_verify[itemID] = itemLink
		local name = GetItemInfo(itemLink)
	end
end

bdlc:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
	if (event == "ADDON_LOADED" and arg1 == "bdlc") then
		print("|cff3399FFAO Big Dumb Loot Council|r loaded. /bdlc for options")

		-------------------------------------------------------
		-- ADDON CHANNEL
		-------------------------------------------------------
		AceComm:RegisterComm(bdlc.message_prefix, function(prefix, text, channel, sender) bdlc:mainCallback(text) end)

		-------------------------------------------------------
		--- Register necessary events
		-------------------------------------------------------
		bdlc:UnregisterEvent("ADDON_LOADED")
		bdlc:RegisterEvent("BOSS_KILL");
		bdlc:RegisterEvent('GET_ITEM_INFO_RECEIVED')
		bdlc:RegisterEvent("CHAT_MSG_LOOT");
		bdlc:RegisterEvent("LOOT_OPENED");
		bdlc:RegisterEvent('PLAYER_ENTERING_WORLD')
		bdlc:RegisterEvent('TRADE_ACCEPT_UPDATE')
		
		-- bdlc:RegisterEvent('GROUP_ROSTER_UPDATE')
		
		-- force cache player items
		bdlc:cachePlayerItems()
		
		--------------------------------------------------------------------------------
		-- Load configuration or set bdlc.defaults
		--------------------------------------------------------------------------------
		bdlc_config = bdlc_config or bdlc.defaults
		bdlc_history = bdlc_history or {}
		for k, v in pairs(bdlc.defaults) do
			if (bdlc_config[k] == nil) then
				bdlc_config[k] = v
			end
		end
		
		--------------------------------------------------------------------------------
		-- Set up slash commands
		--------------------------------------------------------------------------------
		SLASH_bdlc1 = "/bdlc"
		bdlc_config_toggle = false
		SlashCmdList["bdlc"] = function(origmsg, editbox)
			origmsg = strtrim(origmsg)
			local param = bdlc:split(origmsg," ")
			local msg = param[0] or origmsg;
			if (msg == "" or msg == " ") then
				bdlc.print("Options:")
				print("  /bdlc test - Tests the addon (must be in raid)")
				print("  /bdlc config - Shows the configuration window")
				print("  /bdlc show - Shows the vote window (if you're in the LC)")
				print("  /bdlc hide - Hides the vote window (if you're in the LC)")
				print("  /bdlc version - Check the bdlc versions that the raid is using")
				print("  /bdlc addtolc playername - Adds a player to the loot council (if you're the Masterlooter)")
				print("  /bdlc removefromlc playername - Adds a player to the loot council (if you're the Masterlooter)")
			elseif (msg == "version") then
				bdlc:checkRaidVersions()
			elseif (msg == "reset") then
				bdlc_config = bdlc.defaults
				ReloadUI()
			elseif (msg == "start") then
				local s, e = string.find(origmsg, msg)
				local newmsg = strtrim(string.sub(origmsg, e+1))
				
				if (IsRaidLeader() or not IsInRaid() and strlen(newmsg) > 1) then
					bdlc:debug(newmsg)
					bdlc.forceSession = true
					bdlc:sendAction("startSession", newmsg, FetchUnitName("player"));
				else
					bdlc.print("You must be in the loot council and be either the loot master or the raid leader to do that");
				end
			elseif (msg == "addtolc" or msg == "removefromlc") then
				bdlc:addremoveLC(msg, param[1])
			elseif (msg == "config") then
				if (bdlc_config_toggle) then
					bdlc_config_toggle = false
					bdlcconfig:Hide()
				else
					bdlc_config_toggle = true
					bdlcconfig:Show()
				end
			elseif (msg == "verify") then
				local s, e = string.find(origmsg, msg)
				local newmsg = strtrim(string.sub(origmsg, e+1))
				
				if (IsRaidLeader() or not IsInRaid() and strlen(newmsg) > 1) then
					bdlc.verifyMode = true
					bdlc.print("Verifying Tradability of "..newmsg);
					bdlc:debug(newmsg)
					bdlc:verifyTradability(newmsg);
					bdlc.verifyMode = false
				else
					bdlc.print("You must be in the loot council and be either the loot master or the raid leader to do that");
				end
			elseif (msg == "test") then
				bdlc:startMockSession()
			elseif (msg == "show" and bdlc:inLC()) then
				f.voteFrame:Show()
			elseif (msg == "hide" and bdlc:inLC()) then
				f.voteFrame:Hide()
			else
				print("/bdlc "..msg.." command not recognized")
			end
		end
	
		bdlc:Config()
	end

	------------------------------------------------
	-- MAIN SESSION EVENTS
	-- Event hook when in guild raid settings
	------------------------------------------------
	if (event == "PLAYER_ENTERING_WORLD") then
		-- check guild for updates
		bdlc:checkForUpdates()

		-- rebuild / request the LC if you just logged in
		bdlc:sendAction("buildLC");
	end

	bdlc.testMode = true
	if (bdlc:IsInRaidGroup() or bdlc.testMode) then
		-- On boss kill, prepare BDLC to accept valid sessions
		if (event == "BOSS_KILL" and IsRaidLeader() ) then
			bdlc.item_drops = {}

			bdlc:sendAction("buildLC");
			bdlc:startLooterList()

			bdlc:alertRaid()
			
		elseif (event == "LOOT_OPENED") then
			-- checks that a user has looted all of their eligable items
			local num_free = 0
			local remaining_loot = 0
			-- local looted = false
			
			-- loop through loot items and put them into bags to start sessions
			-- if for some reason you have more than 1 item in the loot window this supports that
			-- this also deletes greys if you have full bags
			for slot = 1, GetNumLootItems() do
				local texture, item, quantity, something, quality, locked = GetLootSlotInfo(slot)

				if (quality and quality > 3) then
					local itemLink = GetLootSlotLink(slot)
					remaining_loot = remaining_loot + 1

					-- get number of open bag slots
					for b = 0, 4 do
						num_free = num_free + GetContainerNumFreeSlots(b);
					end

					if (num_free == 0) then
						bdlc.print("You have full bags! Attempting to delete a grey item so that you can loot this item.")
						for bag = 0,4 do
							for slot = 1,GetContainerNumSlots(bag) do
								local bagItemLink = GetContainerItemLink(bag, slot);
								if bagItemLink and select(3, GetItemInfo(bagItemLink)) == 0 then
									PickupContainerItem(bag, slot)
									DeleteCursorItem()
									num_free = 1
									bdlc.print("Deleted "..bagItemLink.." to loot "..itemLink..".");
									break;
								end
							end
						end
					end

					if (num_free == 0) then
						SendChatMessage("BDLC: I have full bags but I looted "..itemLink..". Once I clear a bag slot we can see if a session can be started.", "RAID")
					else
						remaining_loot = remaining_loot - 1
						-- force pick up this item since it is potentially a loot session item
						LootSlot(slot)
					end
				end
			end

			-- they've looted all their good items
			if (remaining_loot == 0) then
				bdlc:sendAction("removeLooter", FetchUnitName("player"))
			end

		elseif (event == "TRADE_ACCEPT_UPDATE") then
			for i = 1, 6 do
				local chatItemLink = GetTradeTargetItemLink(i);
				local name, _, quantity, quality, isUsable, _ = GetTradeTargetItemInfo(i)
				
				if (quantity == 1) then 
					-- Exists, not stackable
					
					local _, _, _, itemLink = string.find(chatItemLink, "(|H(.+)|h)");
					_, _, itemLink = string.find(itemLink, "(.-|h)");
					
					local itemString = string.match(itemLink, "item[%-?%d:]+")
					local _, itemID, _, gem1, _, _, _, _, _, _, _, _, _, _, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)
					local itemUID = itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue

					-- Registering a filter
					bdlc.tradedItems[itemUID] = time()
				end
			end
		-- When a user loots an item, snag that item link and attempt a session
		elseif (event == "CHAT_MSG_LOOT") then
			C_Timer.After(1, function()
				if (bdlc:IsInRaidGroup()) then
					local myItem = LOOT_ITEM_PUSHED_SELF:gsub('%%s', '(.+)');
					local myLoot = LOOT_ITEM_SELF:gsub('%%s', '(.+)');
					-- You receive loot : %s|Hitem :%d :%d :%d :%d|h[%s]|h%s.
					
					local itemLink = arg1:match(myLoot) or arg1:match(myItem)

					if (itemLink) then
						local itemString = string.match(itemLink, "item[%-?%d:]+")
						local _, itemID, _, gem1, _, _, _, _, _, _, _, _, _, _, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)
						local itemUID = itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue
					
						if not bdlc.tradedItems[itemUID] then
							bdlc:verifyTradability(itemLink)
						else
							print('Experimental: '..itemLink..' received via trading, will not be announced again.')
						end
					end
				end
			end)
		end
	end
	
	--------------------------------------------
	-- ITEM INFO QUEUING
	-- this is finished, don't touch
	--------------------------------------------
	if (event == "GET_ITEM_INFO_RECEIVED") then	
		-- Queue items that need to verify tradability
		for k, v in pairs(bdlc.items_waiting_for_verify) do
			local num1 = tonumber(arg1)
			local num2 = tonumber(k)
			if (num1 == num2) then
				
				if not bdlc.tradedItems[v] then
				-- TODO: This event can't fire after a trade so this test should be removed?
					bdlc:verifyTradability(v)
				else
					print('Experimental: Item received via trading, will not be announced again.')
				end
				
				bdlc.items_waiting_for_verify[k] = nil
			end
		end

		-- Queue items that are starting sessions
		for k, v in pairs(bdlc.items_waiting_for_session) do
			local num1 = tonumber(arg1)
			local num2 = tonumber(k)
			if (num1 == num2) then
				bdlc:startSession(v[1],v[2])
				bdlc.items_waiting_for_session[k] = nil
			end
		end
		
		-- Queue items that are showing user's current gear
		for itemID, v in pairs(bdlc.player_items_waiting) do
			local num1 = tonumber(arg1)
			local num2 = tonumber(itemID)
			if (num1 == num2) then
				bdlc:updateUserItem(v[1], v[2])
				bdlc.player_items_waiting[itemID] = nil
			end
		end
	end
end)
