local bdlc, l, f = select(2, ...):unpack()
local demo_samples = {
	classes = {"HUNTER","WARLOCK","PRIEST","PALADIN","MAGE","ROGUE","DRUID","WARRIOR","DEATHKNIGHT","MONK","DEMONHUNTER"},
	ranks = {"Officer","Raider","Trial","Social","Alt","Officer Alt","Guild Idiot"},
	names = {"OReilly","Billy","Tìncan","Mango","Ugh","Onebutton","Thor","Deadpool","Atlas","Edgelord","Yeah"}
}

----------------------------------------
-- StartSession
----------------------------------------
function bdlc:startSession(itemLink,num)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue, wf_tf  = string.split(":", itemString)
	
	if (GetItemInfo(itemLink)) then
	
		local itemUID = bdlc:GetItemUID(itemLink)
		bdlc.itemUID_Map[itemUID] = itemLink
		bdlc.item_drops[itemLink] = bdlc.item_drops[itemLink] or num
		if (not num) then num = bdlc.item_drops[itemLink] or 1 end
	
		local isTier = bdlc:IsTier(itemLink)
		local equipSlot = select(9, GetItemInfo(itemLink))
		local isRelic = bdlc:IsRelic(itemLink)
		
		if (not bdlc.loot_sessions[itemUID] and ((equipSlot and string.len(equipSlot) > 0) or isTier or isRelic)) then
			bdlc:debug("Starting session for "..itemLink)
			bdlc.loot_sessions[itemUID] = itemUID
			if (bdlc:inLC()) then
				bdlc:createVoteWindow(itemUID,num)
				
				bdlc.loot_council_votes[itemUID] = {}
				bdlc.loot_considering[itemUID] = {}
				bdlc.loot_want[itemUID] = {}
			end
			C_Timer.After(1, function()
				bdlc:createRollWindow(itemUID,num)
			end)
		end
	else
		bdlc.items_waiting[itemID] = {itemLink,num}
		local name = GetItemInfo(itemLink)
	end
end
----------------------------------------
-- EndSession
----------------------------------------
function bdlc:endSession(itemUID)
	if not itemUID then return end
	local itemLink = bdlc.itemUID_Map[itemUID]
	if not itemLink then return end
	bdlc.item_drops[itemLink] = nil
	local currententry = nil
	local currenttab = nil
	--if bdlc:inLC() then 
		for i = 1, #f.tabs do
			if (f.tabs[i].itemUID == itemUID) then
				for e = 1, #f.entries[i] do
					if (f.entries[i][e].itemUID == itemUID) then
						currententry = f.entries[i][e]
						currententry:Hide()
						currententry.user_notes:Hide()
						currententry.active = false
						currententry.itemUID = 0
						currententry.votes.text:SetText("0")
						currententry.playerName = ""
						currententry.voteUser:Hide()
						currententry.wantLevel = 0
						currententry.notes = ""
					end
				end
				currenttab = f.tabs[i]
				currenttab:Hide()
				currenttab:SetAlpha(0.3)
				currenttab.table:Hide()
				currenttab.active = false
				currenttab.selected = false
				currenttab.itemUID = 0
				currenttab.table.item.num_items:SetText("x1")
				
				break
			end
		end
		bdlc.loot_considering[itemUID] = nil
		bdlc.loot_want[itemUID] = nil
	--end
	local currentroll = nil
	for i = 1, #f.rolls do
		if (f.rolls[i].itemUID == itemUID) then
			currentroll = f.rolls[i]
			currentroll.active = false
			currentroll.itemUID = 0
			currentroll.notes = ""
			currentroll:Hide()
			
			break
		end
	end
	
	bdlc.loot_sessions[itemUID] = nil
	bdlc.loot_council_votes[itemUID] = nil
	
	--bdlc.itemUID_Map[itemUID] = nil
	
	bdlc:repositionFrames()
end

----------------------------------------
-- StartMockSession
----------------------------------------
function bdlc:startMockSession()
	bdlc:debug("Starting mock session")
	
	
	local demo_players = {
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(795,880), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
	}
	
	bdlc:buildLC()
	local itemslots = {1,2,3,5,8,9,10,11,12,13,14,15}
	bdlc.item_drops = {}
	for i = 1, 4 do
		local index = itemslots[math.random(#itemslots)]
		bdlc.item_drops[GetInventoryItemLink("player", index)] = math.random(1,3)
		table.remove(itemslots,index)
	end

	for k, v in pairs(bdlc.item_drops) do
		local itemUID = bdlc:GetItemUID(k)
		SendAddonMessage(bdlc.message_prefix, "startSession><"..k.."><"..v, bdlc.sendTo, UnitName("player"));
		
		for k2, v2 in pairs(demo_players) do
			SendAddonMessage(bdlc.message_prefix, "addUserConsidering><"..itemUID.."><"..k2.."><"..v2[1].."><"..v2[2].."><"..v2[3], bdlc.sendTo, UnitName("player"));
		end
	end
end

----------------------------------------
-- CreateVoteWindow
----------------------------------------
function bdlc:createVoteWindow(itemUID,num)
	local itemLink = bdlc.itemUID_Map[itemUID]
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	
	f.voteFrame:Show()
	
	local itemID, gem, bonus1, bonus2 = string.split(":", itemUID)
	
	local currenttab = nil
	for i = 1, #f.tabs do
		if (not currenttab and not f.tabs[i].active) then
			currenttab = f.tabs[i]
			currenttab.active = true
			currenttab.itemUID = itemUID
			
			break
		end
	end
	
	if (not currenttab) then bdlc:debug("couldn't find currenttab") return false end
	-- Set Up tab and item info
	currenttab:Show()
	currenttab.icon:SetTexture(texture)
	currenttab.table.item.itemtext:SetText(itemLink)
	if (num > 1) then
		currenttab.table.item.num_items:SetText("x"..num)
		currenttab.table.item.num_items:SetTextColor(0,1,0)
	else
		currenttab.table.item.num_items:SetText("")
		currenttab.table.item.num_items:SetTextColor(1,1,1)
	end
	currenttab.table.item.icon.tex:SetTexture(texture)

	local ilvl, wf_tf, socket, infostr = bdlc:GetItemValue(itemLink)
	currenttab.wfsock:SetText(infostr)
	currenttab.table.item.wfsock:SetText(infostr)
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
function bdlc:createRollWindow(itemUID,num)
	local itemLink = bdlc.itemUID_Map[itemUID]
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	rollFrame:Show()
	
	local itemID, gem, bonus1, bonus2 = string.split(":", itemUID)
	
	local currentroll = nil
	for i = 1, #f.rolls do
		if (not currentroll and not f.rolls[i].active) then
			currentroll = f.rolls[i]
			currentroll.active = true
			currentroll.itemUID = itemUID
			
			break
		end
	end
	
	if (not currentroll) then bdlc:debug("couldn't find currentroll") return false end
	currentroll:Show()
	currentroll.item.icon.tex:SetTexture(texture)
	currentroll.item.item_text:SetText(itemLink)
	if (num > 1) then
		currentroll.item.num_items:SetText("x"..num)
		currentroll.item.num_items:SetTextColor(0,1,0)
	else
		currentroll.item.num_items:SetText("")
		currentroll.item.num_items:SetTextColor(1,1,1)
	end
	--currentroll.item.item_ilvl:SetText("ilvl: "..iLevel)
	
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
		SendAddonMessage(bdlc.message_prefix, "addUserConsidering><"..itemUID.."><"..bdlc.local_player.."><"..player_itemlvl.."><"..guildRank, bdlc.sendTo, UnitName("player"));
	else
		bdlc:debug("I guess I can't use this, autopassing")
		local itemLink1, itemLink2 = bdlc:fetchUserGear("player", itemLink)
		
		SendAddonMessage(bdlc.message_prefix, "removeUserConsidering><"..itemUID.."><"..bdlc.local_player, bdlc.sendTo, UnitName("player"));
		local currentroll = nil
		for i = 1, #f.rolls do
			if (f.rolls[i].itemUID == itemUID) then
				currentroll = f.rolls[i]
				currentroll.active = false
				currentroll.itemUID = 0
				currentroll.notes = ""
				currentroll:Hide()
				
				break
			end
		end
	end
	bdlc:repositionFrames()
	
end

----------------------------------------
-- RemoveUserRoll
----------------------------------------
function bdlc:removeUserRoll(itemUID)
	local currentroll = nil
	for i = 1, #f.rolls do
		if (f.rolls[i].itemUID == itemUID) then
			currentroll = f.rolls[i]
			currentroll.active = false
			currentroll.itemUID = 0
			currentroll.notes = ""
			currentroll:Hide()
			
			break
		end
	end
	
	bdlc:repositionFrames()
end

----------------------------------------
-- AddUserConsidering
----------------------------------------
function bdlc:addUserConsidering(itemUID, playerName, iLvL, guildRank, playerClass)
	playerName = FetchUnitName(playerName) or playerName
	local itemLink = bdlc.itemUID_Map[itemUID]
	
	if not bdlc:inLC() then return false end
	if (not bdlc.loot_sessions[itemUID]) then return false end

	local currententry = nil
	local found = nil
	for i = 1, #f.tabs do
		if (f.tabs[i].itemUID == itemUID) then
			for e = 1, #f.entries[i] do
				if (f.entries[i][e].playerName == playerName) then
					currententry = f.entries[i][e]
					currententry.active = true
					currententry.itemUID = itemUID
					currententry.wantLevel = 15
					currententry.notes = ""
					currententry.playerName = playerName
					
					found = true
					
					break
				end
			end
			
			if (not found) then
				for e = 1, #f.entries[i] do
					if (not f.entries[i][e].active) then
						currententry = f.entries[i][e]
						currententry.active = true
						currententry.itemUID = itemUID
						currententry.wantLevel = 15
						currententry.notes = ""
						currententry.playerName = playerName
						
						break
					end
				end
			end
		end
	end
	
	if (not currententry) then return false end
	
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	--local guildName, guildRankName, guildRankIndex = GetGuildInfo(name)
	local name, server = strsplit("-", playerName)

	local classFileName = select(2, UnitClass(name)) or select(2, UnitClass(playerName)) or playerClass or demo_samples.classes[math.random(#demo_samples.classes)]
	local color = RAID_CLASS_COLORS[classFileName]
	if (not color) then print(playerName.." not found") return false end
	name = GetUnitName(name,true) or name
	
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
	
	bdlc.loot_considering[itemUID][playerName] = {}
	bdlc.loot_considering[itemUID][playerName].itemUID = itemUID
	bdlc.loot_considering[itemUID][playerName].playerName = playerName
	bdlc.loot_considering[itemUID][playerName].iLvL = iLvL
	bdlc.loot_considering[itemUID][playerName].guildRank = guildRank
	bdlc.loot_considering[itemUID][playerName].frame = currententry

	bdlc:repositionFrames()
end

----------------------------------------
-- RemoveUserConsidering
----------------------------------------
function bdlc:removeUserConsidering(itemUID, playerName)
	if (not bdlc:inLC()) then return end

	local itemLink = bdlc.itemUID_Map[itemUID]
	if (not itemLink) then return end
	playerName = FetchUnitName(playerName) or playerName
	
	bdlc:debug("removed "..playerName.." considering "..itemLink)
	
	local currententry = bdlc.loot_considering[itemUID][playerName].frame

	if (currententry) then
		currententry:Hide()
		currententry.user_notes:Hide()
		currententry.active = false
		currententry.itemUID = 0
		currententry.notes = ""
		currententry.playerName = ""
		currententry.wantLevel = 0
		currententry.voteUser:Hide()
		currententry.votes.text:SetText("0")
	end

	if (bdlc.loot_council_votes[itemUID]) then
		bdlc.loot_council_votes[itemUID][playerName] = nil
	end
	if (bdlc.loot_considering[itemUID]) then
		bdlc.loot_considering[itemUID][playerName] = nil
	end
	if (bdlc.loot_want[itemUID]) then
		bdlc.loot_want[itemUID][playerName] = nil
	end
	if (UnitExists(playerName)) then
		SendAddonMessage(bdlc.message_prefix, "removeUserRoll><"..itemUID, "WHISPER", playerName);
	end
	
	bdlc:repositionFrames()
end

----------------------------------------
-- AddUserWant
----------------------------------------
function bdlc:addUserWant(itemUID, playerName, want, itemLink1, itemLink2)
	playerName = FetchUnitName(playerName)
	
	local itemLink = bdlc.itemUID_Map[itemUID]
	if (not bdlc.loot_sessions[itemUID]) then bdlc:debug(playername.." rolled on an item with no session") return false end
	if (not bdlc:inLC()) then return false end
	
	local currententry = bdlc.loot_considering[itemUID][playerName].frame
	
	if (not currententry) then 
		print("BDLC: "..playerName.."rolled on item, but BDLC couldn't find the vote window entry")
		return false 
	end
	
	local wantText = bdlc.wantTable[want][1]
	local wantColor = bdlc.wantTable[want][2]
	
	bdlc:debug(playerName.." needs "..itemLink.." "..wantText)
	
	currententry.interest:SetText(wantText);
	currententry.interest:SetTextColor(unpack(wantColor));
	currententry.voteUser:Show()
	currententry.wantLevel = want
	
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
	if (itemLink2 ~= 0) then
		if (GetItemInfo(itemLink2)) then
			local itemName, link2, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture2, vendorPrice = GetItemInfo(itemLink2)
			currententry.gear2:Show()
			currententry.gear2.tex:SetTexture(texture2)
			currententry.gear2:SetScript("OnEnter", function()
				ShowUIPanel(GameTooltip)
				GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
				GameTooltip:SetHyperlink(link2)
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
	end
	
	bdlc.loot_want[itemUID][playerName] = {itemUID, playerName, want, itemLink1, itemLink2}
	
	bdlc:repositionFrames()
end

----------------------------------------
-- AddUserNotes
----------------------------------------
function bdlc:addUserNotes(itemUID, playerName, notes)
	playerName = FetchUnitName(playerName)

	bdlc:debug("Add "..playerName.." notes")
	if (not bdlc.loot_sessions[itemUID]) then return false end
	if not bdlc:inLC() then return false end
	
	local currententry = bdlc:returnEntry(itemUID,playerName)
	
	if (not currententry) then return false end
	
	currententry.notes = notes
	currententry.user_notes:Show()
end

----------------------------------------
-- UpdateUserItem
----------------------------------------
function bdlc:updateUserItem(itemLink, frame)
	--local itemLink = bdlc.itemUID_Map[itemUID]

	--local link = select(2, GetItemInfo(itemLink))
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

function bdlc:wipeQN(note)
	bdlc.master_looter_qn = {}
end
function bdlc:customQN(note)
	bdlc.master_looter_qn[note] = true
end

----------------------------------------
-- TakeWhisperEntry
----------------------------------------

function bdlc:takeWhisperEntry(msg, sender)
	--[[msg = string.lower(msg)
	if (string.find(msg, "!bdlc")) then
		local itemLink = string.match(msg,"(\124c%x+\124Hitem:.-\124h\124r)")
		local s2, e2 = string.find(msg,"(\124c%x+\124Hitem:.-\124h\124r)")
		local wantlevel = strtrim(string.sub(msg, e2+2))
		local raidIndex = 0
		local name, server = strsplit("-", sender)
		--local findserver = select(1, string.find(sender, "-"))
		--sender = string.sub(sender, 0, findserver-1)
	
		if (bdlc.loot_sessions[itemLink]) then
			for r = 1, GetNumGroupMembers() do
				local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(r)
				if (name == sender) then
					raidIndex = r
				end
			end
			
			local wantTable = {
				["need"] = 1,
				["bis"] = 1,
				["mainspec"] = 1,
				["main"] = 1,
				["minor"] = 2,
				["sidegrade"] = 2,
				["off"] = 3,
				["offspec"] = 3,
				["rr"] = 4,
				["reroll"] = 4,
				["transmog"] = 5,
				["xmog"] = 5,
				["mog"] = 5,
			}
			local want = wantTable[wantLevel]
		
			local itemID = select(2, strsplit(":", itemLink))
			
			NotifyInspect("raid"..raidIndex)
			InspectUnit("raid"..raidIndex)
			local itemLink1, itemLink2 = bdlc:fetchUserGear("raid"..raidIndex, itemLink)
			local guildRank = select(2, GetGuildInfo("raid"..raidIndex))
			local ilvl = getUnitItemLevel("raid"..raidIndex)
			local inspectwait = CreateFrame("frame", nil)
			local total = 0
			inspectwait:SetScript("OnUpdate", function(self, elapsed)
				total = total + elapsed
				if (total > 1) then
					total = 0
					inspectwait:SetScript("OnUpdate", function() return end)
					guildRank = select(2, GetGuildInfo(sender)) or ""
					itemLink1, itemLink2 = bdlc:fetchUserGear("raid"..raidIndex, itemLink)
					ilvl = getUnitItemLevel("raid"..raidIndex)
					
					print(itemLink1)
					print(itemLink2)
					
					SendAddonMessage(bdlc.message_prefix, "addUserConsidering><"..itemLink.."><"..raidIndex.."><"..ilvl.."><"..guildRank, bdlc.sendTo, UnitName("player"));
					SendAddonMessage(bdlc.message_prefix, "addUserWant><"..itemID.."><"..raidIndex.."><1><"..itemLink1.."><"..itemLink2, bdlc.sendTo, UnitName("player"));
					
					ClearInspectPlayer()
				end
			end)
			
			
		end
	end--]]
end

----------------------------------------
-- VoteForUser
----------------------------------------
function bdlc:voteForUser(councilName, itemUID, playerName)
	playerName = FetchUnitName(playerName)
	
	if (not bdlc.loot_sessions[itemUID]) then return false end
	if not bdlc:inLC() then return false end
	
	-- make sure theres an array to represent this user in the raid
	bdlc.loot_council_votes[itemUID][playerName] = bdlc.loot_council_votes[itemUID][playerName] or {}
	-- first, unset this council member on any other user for this item
	for playerName, v in pairs(bdlc.loot_council_votes[itemUID]) do
		v[councilName] = nil
	end
	
	-- now add this council member as a vote for this raid member and this itemLink
	bdlc.loot_council_votes[itemUID][playerName][councilName] = true
	
	-- now lets loop through open sessions, and their entries while tallying votes for said item>entry
	for itemUID, un in pairs(bdlc.loot_sessions) do
		for i = 1, #f.tabs do
			if (f.tabs[i].itemUID == itemUID) then
				for e = 1, #f.entries[i] do
					local currententry = f.entries[i][e]
					if (currententry.active and bdlc.loot_council_votes[itemUID][currententry.playerName]) then
						local votes = 0
						for k, v in pairs(bdlc.loot_council_votes[itemUID][currententry.playerName]) do
							votes = votes + 1
						end
						currententry.votes.text:SetText(votes)
					end
				end
			end
		end
	end
	
end

function bdlc:fetchSessions()
	if (IsMasterLooter()) then
		if (GetNumLootItems() > 0) then
			bdlc:parseLoot()
		else
			for itemUID, v in pairs(bdlc.loot_sessions) do
				local itemLink = bdlc.itemUID_Map[itemUID]
				local num = bdlc.item_drops[itemLink]
				
				if (not num) then return end
				
				SendAddonMessage(bdlc.message_prefix, "startSession><"..itemLink.."><"..num, bdlc.sendTo, UnitName("player"));
				
				for playerName, data in pairs(bdlc.loot_want[itemUID]) do
					SendAddonMessage(bdlc.message_prefix, "addUserWant><"..data[1].."><"..data[2].."><"..data[3].."><"..data[4].."><"..data[5], bdlc.sendTo, UnitName("player"));
				end
				
				for playerName, data in pairs(bdlc.loot_considering[itemUID]) do
					SendAddonMessage(bdlc.message_prefix, "addUserConsidering><"..data[1].."><"..data[2].."><"..data[3].."><"..data[4], bdlc.sendTo, UnitName("player"));
				end
			end
		end
	end
end

function bdlc:parseLoot()
	f.voteFrame.enchanters:Show()
	bdlc.loot_slots = {}
	bdlc.item_drops = {}
	for slot = 1, GetNumLootItems() do
		local texture, item, quantity, quality, locked = GetLootSlotInfo(slot)

		if (quality and quality > 3) then
			local itemLink = GetLootSlotLink(slot)
			bdlc.loot_slots[slot] = itemLink

			bdlc.item_drops[itemLink] = bdlc.item_drops[itemLink] or 0
			bdlc.item_drops[itemLink] = bdlc.item_drops[itemLink] + 1
		end
	end
	for k, v in pairs(bdlc.item_drops) do
		SendAddonMessage(bdlc.message_prefix, "startSession><"..k.."><"..v, bdlc.sendTo, UnitName("player"));
	end
end

function bdlc:addLootHistory(itemUID, playerName, enchanter)
	local datetimestamp = time().."."..GetTime()
	local itemUID, playerName, want, itemLink1, itemLink2 = unpack(bdlc.loot_want[itemUID][playerName])
	
	local today = date("%m/%d/%Y")
	bdlc_history[today] = bdlc_history[today] or {}
	
	if (playerName) then
		-- log the history
		local index = #bdlc_history[today] + 1
		local entry = bdlc_history[today][index] = {}
		entry.stamp = time()
		entry.playerName = playerName
		entry.itemLink = itemLink
		entry.disenchanter = enchanter
		entry.want = want
		entry.itemLink1 = itemLink1
		entry.itemLink2 = itemLink2
	end
end

function determineLC()

end
function determineScope()
	if (IsInRaid() or IsInGroup() or UnitInRaid("player")) then
		bdlc.sendTo = "RAID"
	else
		bdlc.sendTo = "WHISPER"
	end
end

bdlc:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
	if (event == "ADDON_LOADED" and (arg1 == "BigDumbLootCouncil" or arg1 == "bigdumblootcouncil")) then
		bdlc:UnregisterEvent("ADDON_LOADED")
		-------------------------------------------------------
		--- Register necessary events
		-------------------------------------------------------
		bdlc:RegisterEvent("LOOT_SLOT_CLEARED");
		bdlc:RegisterEvent("LOOT_OPENED");
		bdlc:RegisterEvent("LOOT_CLOSED");
		bdlc:RegisterEvent('GET_ITEM_INFO_RECEIVED')
		bdlc:RegisterEvent('CHAT_MSG_ADDON')
		bdlc:RegisterEvent('GROUP_ROSTER_UPDATE')
		bdlc:RegisterEvent('CHAT_MSG_WHISPER')
		bdlc:RegisterEvent('PARTY_LOOT_METHOD_CHANGED')
		bdlc:RegisterEvent('PLAYER_ENTERING_WORLD')
		bdlc:RegisterEvent('LOADING_SCREEN_DISABLED')
		
		LoadAddOn("Blizzard_ArtifactUI")
		
		-- force load player items
		for i = 1, 19 do
			local link = GetInventoryItemLink("player", i)
		end
		SocketInventoryItem(17)
		SocketInventoryItem(16)
		HideUIPanel(ArtifactFrame)
		
		--------------------------------------------------------------------------------
		-- Load configuration or set bdlc.defaults
		--------------------------------------------------------------------------------
		print("|cff3399FFBig Dumb Loot Council|r loaded. /bdlc for options")
		RegisterAddonMessagePrefix(bdlc.message_prefix);
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
		SLASH_BDLC1 = "/bdlc"
		bdlc_config_toggle = false
		SlashCmdList["BDLC"] = function(origmsg, editbox)
			origmsg = strtrim(origmsg)
			local param = bdlc:split(origmsg," ")
			local msg = param[0] or origmsg;
			if (msg == "" or msg == " ") then
				print("|cff3399FFBDLC|r Options:")
				print("  /bdlc test - Tests the addon (must be in raid)")
				print("  /bdlc config - Shows the configuration window")
				print("  /bdlc show - Shows the vote window (if you're in the LC)")
				print("  /bdlc hide - Hides the vote window (if you're in the LC)")
				print("  /bdlc version - Check the bdlc versions that the raid is using")
				print("  /bdlc addtolc playername - Adds a player to the loot council (if you're the Masterlooter)")
				print("  /bdlc removefromlc playername - Adds a player to the loot council (if you're the Masterlooter)")
			elseif (msg == "version") then
				bdlc:checkVersions()
			elseif (msg == "reset") then
				bdlc_config = bdlc.defaults
				ReloadUI()
			elseif (msg == "start") then
				local s, e = string.find(origmsg, msg)
				local newmsg = strtrim(string.sub(origmsg, e+1))
				
				if (IsMasterLooter() or IsRaidLeader() or not IsInRaid() and strlen(newmsg) > 1) then
					bdlc:debug(newmsg)
					SendAddonMessage(bdlc.message_prefix, "startSession><"..newmsg.."><"..1, bdlc.sendTo, UnitName("player"));
				else
					print("bdlc: You must be in the loot council and be either the loot master or the raid leader to do that");
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
	
	if (event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED") then
		determineScope()
		SendAddonMessage(bdlc.message_prefix, "fetchLC", bdlc.sendTo, UnitName("player"));
	end
	
	if (event == "ENCOUNTER_END") then
		determineScope()
		--bdlc:buildLC() -- don't think we need to do this here
	end
	if (event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LOOT_METHOD_CHANGED") then
		determineScope()
		bdlc:buildLC()
	end
	
	if (IsMasterLooter() and event == "LOOT_OPENED") then
		bdlc:parseLoot()
	end
	
	
	if (event == "CHAT_MSG_WHISPER") then
		if (IsMasterLooter()) then
			--bdlc:takeWhisperEntry(arg1, arg2)
		end
	end
	
	-- Auto close sessions when loot is awarded from the body
	if (event == "LOOT_SLOT_CLEARED" and arg1 == bdlc.award_slot) then
		local itemlink = bdlc.loot_slots[arg1]
		if not itemLink then return false end
		
		bdlc.item_drops[itemLink] = bdlc.item_drops[itemLink] - 1
		
		for i = 1, #f.tabs do
			if (f.tabs[i].itemLink == itemLink) then
				f.tabs[i].table.item.num_items:SetText("x"..bdlc.item_drops[itemLink])
			end
		end
		if (bdlc.item_drops[itemLink] == 0) then
			local itemUID = bdlc:GetItemUID(itemLink)
		
			SendAddonMessage(bdlc.message_prefix, "endSession><"..itemUID, bdlc.sendTo, UnitName("player"));
			bdlc:endSession(itemUID)
		end
		
		bdlc.award_slot = {}
		bdlc.loot_slots[arg1] = nil
	end
	
	
	if (event == "CHAT_MSG_ADDON" and arg1 == bdlc.message_prefix) then
		local method, partyMaster, raidMaster = GetLootMethod()
		if (method == "master" or not IsInRaid()) then
			local param = bdlc:split(arg2, "><")
			local action = param[0] or arg2;
			
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
			
			bdlc:debug(arg2)
			
			if (action == "startSession") then
				bdlc:startSession(param[1],param[2])
			elseif (action == "fetchLC") then
				bdlc:fetchLC()
			elseif (action == "sendVersion") then
				bdlc:sendVersion(param[1], param[2])
			elseif (action == "versionCheck") then
				bdlc:versionCheck(param[1])
			elseif (action == "addToLC") then
				bdlc:addToLC(param[1])
			elseif (action == "removeFromLC") then
				bdlc:removeFromLC(param[1])
			elseif (action == "removeUserConsidering") then
				bdlc:removeUserConsidering(param[1], param[2])
			elseif (action == "addUserConsidering") then
				bdlc:addUserConsidering(param[1], param[2], param[3], param[4], param[5])
			elseif (action == "addUserWant") then
				bdlc:addUserWant(param[1], param[2], param[3], param[4], param[5])
			elseif (action == "addUserNotes") then
				bdlc:addUserNotes(param[1], param[2], param[3])
			elseif (action == "fetchSessions") then
				bdlc:fetchSessions()
			elseif (action == "voteForUser") then
				bdlc:voteForUser(param[1], param[2], param[3])
			elseif (action == "removeUserRoll") then
				bdlc:removeUserRoll(param[1])
			elseif (action == "addEnchanter") then
				bdlc:addEnchanter(param[1], param[2])
			elseif (action == "findEnchanters") then
				bdlc:findEnchanters()
			elseif (action == "endSession") then
				bdlc:endSession(param[1])
			elseif (action == "customQN") then
				bdlc:customQN(param[1])
			elseif (action == "wipeQN") then
				bdlc:wipeQN()
			elseif (action == "addLootHistory") then
				bdlc:addLootHistory(param[1], param[2], param[3])
			else
				print("BDLC: Failed to find action for "..action..". Please post this on Curse or Wowinterface addon thread. info: "..arg2);
			end
		end
	end
		
	
	-- THIS IS FINISHED DONT TOUCH
	if (event == "GET_ITEM_INFO_RECEIVED") then	
		-- Queue items that are starting sessions
		for k, v in pairs(bdlc.items_waiting) do
			local num1 = tonumber(arg1)
			local num2 = tonumber(k)
			if (num1 == num2) then
				bdlc:startSession(v[1],v[2])
				bdlc.items_waiting[k] = nil
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
