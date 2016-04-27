local bdlc, f, c = select(2, ...):unpack()


----------------------------------------
-- StartSession
----------------------------------------
function bdlc:startSession(itemLink,num)

	local itemString = string.match(itemLink, "item[%-?%d:]+")
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2  = string.split(":", itemString)
	bonusID1 = bonusID1 or 0
	bonusID2 = bonusID2 or 0
	local itemUID = itemID..":"..numBonusIDs..":"..bonusID1..":"..bonusID2
	
	bdlc.item_drops[itemLink] = bdlc.item_drops[itemLink] or num
	if (not num) then num = bdlc.item_drops[itemLink] end
	
	if (GetItemInfo(itemLink)) then
		local equipSlot = select(9, GetItemInfo(itemLink))
		local name = select(1, GetItemInfo(itemLink))
		
		local found_tier = false
		for k, v in pairs(bdlc.tier_names) do
			if (strfind(name, k)) then found_tier = true end
		end
		
		if (not bdlc.loot_sessions[itemLink] and (string.len(equipSlot) > 0 or found_tier)) then
			bdlc:debug("Starting session for "..itemLink)
			bdlc.loot_sessions[itemLink] = itemUID
			if (bdlc:inLC()) then
				bdlc:createVoteWindow(itemLink,num)
				
				bdlc.loot_council_votes[itemLink] = {}
				bdlc.loot_considering[itemLink] = {}
				bdlc.loot_want[itemLink] = {}
			end
			bdlc:createRollWindow(itemLink,num)
		end
	else
		bdlc.items_waiting[itemID] = itemLink
	end
end
----------------------------------------
-- EndSession
----------------------------------------
function bdlc:endSession(itemLink)
	bdlc.item_drops[itemLink] = nil
	local currententry = nil
	local currenttab = nil
	if bdlc:inLC() then 
		for i = 1, #f.tabs do
			if (f.tabs[i].itemLink == itemLink) then
				for e = 1, #f.entries[i] do
					if (f.entries[i][e].itemLink == itemLink) then
						currententry = f.entries[i][e]
						currententry:Hide()
						currententry.user_notes:Hide()
						currententry.active = false
						currententry.itemLink = 0
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
				currenttab.itemLink = 0
				currenttab.table.item.num_items:SetText("x1")
				
				break
			end
		end
		bdlc.loot_considering[itemLink] = nil
		bdlc.loot_want[itemLink] = nil
	end
	local currentroll = nil
	for i = 1, #f.rolls do
		if (f.rolls[i].itemLink == itemLink) then
			currentroll = f.rolls[i]
			currentroll.active = false
			currentroll.itemLink = 0
			currentroll.notes = ""
			currentroll:Hide()
			
			break
		end
	end
	
	bdlc.loot_sessions[itemLink] = nil
	bdlc.loot_council_votes[itemLink] = nil
	
	bdlc:repositionFrames()
end

----------------------------------------
-- StartMockSession
----------------------------------------
function bdlc:startMockSession()
	bdlc:debug("Starting mock session")
	
	local demo_samples = {
		classes = {"HUNTER","WARLOCK","PRIEST","PALADIN","MAGE","ROGUE","DRUID","WARRIOR","DEATHKNIGHT","MONK"},
		ranks = {"Officer","Raider","Trial","Social","Alt","Officer Alt","Guild Idiot"},
		names = {"OReilly","Billy","Tìncan","Mango","Ugh","Onebutton","Thor","Deadpool","Atlas"}
	}
	local demo_players = {
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
		[demo_samples.names[math.random(#demo_samples.names)]] = {math.random(695,740), demo_samples.ranks[math.random(#demo_samples.ranks)], demo_samples.classes[math.random(#demo_samples.classes)]},
	}
	
	bdlc:buildLC()
	bdlc.item_drops = {
		[GetInventoryItemLink("player", 14)] = 1,
		[GetInventoryItemLink("player", 1)] = 3,
		[GetInventoryItemLink("player", 16)] = 1,
		[GetInventoryItemLink("player", 15)] = 2
	}
	for k, v in pairs(bdlc.item_drops) do
		SendAddonMessage(bdlc.message_prefix, "startSession><"..k.."><"..v, bdlc.sendTo, UnitName("player"));
	end

	for k, v in pairs(bdlc.item_drops) do
		for k2, v2 in pairs(demo_players) do
			SendAddonMessage(bdlc.message_prefix, "addUserConsidering><"..k.."><"..k2.."><"..v2[1].."><"..v2[2].."><"..v2[3], bdlc.sendTo, UnitName("player"));
		end
	end
end

----------------------------------------
-- CreateVoteWindow
----------------------------------------
function bdlc:createVoteWindow(itemLink,num)
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	f.voteFrame:Show()
	local itemUID = bdlc.loot_sessions[itemLink]
	itemUID = bdlc:split(itemUID,":")
	
	local currenttab = nil
	for i = 1, #f.tabs do
		if (not currenttab and not f.tabs[i].active) then
			currenttab = f.tabs[i]
			currenttab.active = true
			currenttab.itemLink = itemLink
			
			break
		end
	end
	
	if (not currenttab) then bdlc:debug("couldn't find currenttab") return false end
	-- Set Up tab and item info
	currenttab:Show()
	currenttab.icon:SetTexture(texture)
	currenttab.table.item.itemtext:SetText(link)
	currenttab.table.item.num_items:SetText("x"..num)
	currenttab.table.item.icon.tex:SetTexture(texture)
	if (tonumber(itemUID[2]) >= 2) then
		currenttab:SetBackdropBorderColor(0,.7,0,1)
		currenttab.table.item.icon:SetBackdropBorderColor(0,.7,0,1)
	else
		currenttab:SetBackdropBorderColor(0,0,0,1)
		currenttab.table.item.icon:SetBackdropBorderColor(0,0,0,1)
	end
	local slotname = string.lower(string.gsub(equipSlot, "INVTYPE_", ""));
	slotname = slotname:gsub("^%l", string.upper)
	currenttab.table.item.itemdetail:SetText("ilvl: "..iLevel.."    "..subclass..", "..slotname);
	currenttab.table.item:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
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
function bdlc:createRollWindow(itemLink,num)
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	rollFrame:Show()
	local itemUID = bdlc.loot_sessions[itemLink]
	itemUID = bdlc:split(itemUID,":")
	
	local currentroll = nil
	for i = 1, #f.rolls do
		if (not currentroll and not f.rolls[i].active) then
			currentroll = f.rolls[i]
			currentroll.active = true
			currentroll.itemLink = itemLink
			
			break
		end
	end
	
	if (not currentroll) then bdlc:debug("couldn't find currentroll") return false end
	
	currentroll:Show()
	currentroll.item.icon.tex:SetTexture(texture)
	currentroll.item.item_text:SetText(link)
	currentroll.item.num_items:SetText("x"..num)
	currentroll.item.item_ilvl:SetText("ilvl: "..iLevel)
	if (tonumber(itemUID[2]) >= 2) then
		currentroll.item.icon:SetBackdropBorderColor(0,.7,0,1)
	else
		currentroll.item.icon:SetBackdropBorderColor(0,0,0,1)
	end

	currentroll.item:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)
	currentroll.item:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	local guildRank = select(2,GetGuildInfo("player"))
	local player_itemlvl = math.floor(select(2, GetAverageItemLevel()))
	SendAddonMessage(bdlc.message_prefix, "addUserConsidering><"..itemLink.."><"..bdlc.local_player.."><"..player_itemlvl.."><"..guildRank, bdlc.sendTo, UnitName("player"));
	
	bdlc:repositionFrames()
end

----------------------------------------
-- RemoveUserRoll
----------------------------------------
function bdlc:removeUserRoll(itemLink)
	local currentroll = nil
	for i = 1, #f.rolls do
		if (f.rolls[i].itemLink == itemLink) then
			currentroll = f.rolls[i]
			currentroll.active = false
			currentroll.itemLink = 0
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
function bdlc:addUserConsidering(itemLink, playerName, iLvL, guildRank, playerClass)
	playerName = FetchUnitName(playerName)
	
	bdlc:debug(playerName.." considering "..itemLink)
	if not bdlc:inLC() then return false end
	if (not bdlc.loot_sessions[itemLink]) then return false end

	local currententry = nil
	for i = 1, #f.tabs do
		if (f.tabs[i].itemLink == itemLink) then
			for e = 1, #f.entries[i] do
				if (f.entries[i][e].active == false) then
					currententry = f.entries[i][e]
					currententry.active = true
					currententry.itemLink = itemLink
					currententry.wantLevel = 15
					currententry.notes = ""
					currententry.playerName = playerName
					
					break
				end
			end
		end
	end
	
	if (not currententry) then return false end
	
	local itemName, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	--local guildName, guildRankName, guildRankIndex = GetGuildInfo(name)
	local name, server = strsplit("-", playerName)

	local classFileName = select(2, UnitClass(name)) or select(2, UnitClass(playerName)) or playerClass
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
	
	bdlc.loot_considering[itemLink][playerName] = {itemLink, playerName, iLvL, guildRank}
	
	bdlc:repositionFrames()
end

----------------------------------------
-- RemoveUserConsidering
----------------------------------------
function bdlc:removeUserConsidering(itemLink, playerName)
	playerName = FetchUnitName(playerName)
	
	if bdlc:inLC() then 
		local currententry = bdlc:returnEntry(itemLink, playerName)

		if (currententry) then
			currententry:Hide()
			currententry.user_notes:Hide()
			currententry.active = false
			currententry.itemLink = 0
			currententry.notes = ""
			currententry.playerName = ""
			currententry.wantLevel = 0
			currententry.voteUser:Hide()
			currententry.votes.text:SetText("0")
		end
	
		if (bdlc.loot_council_votes[itemLink]) then
			bdlc.loot_council_votes[itemLink][playerName] = nil
		end
		if (bdlc.loot_considering[itemLink]) then
			bdlc.loot_considering[itemLink][playerName] = nil
		end
		if (bdlc.loot_want[itemLink]) then
			bdlc.loot_want[itemLink][playerName] = nil
		end
		if (UnitExists(playerName)) then
			SendAddonMessage(bdlc.message_prefix, "removeUserRoll><"..itemLink, "WHISPER", playerName);
		end
	end
	
	bdlc:repositionFrames()
end

----------------------------------------
-- AddUserWant
----------------------------------------
function bdlc:addUserWant(itemUID, playerName, want, itemLink1, itemLink2)
	playerName = FetchUnitName(playerName)
	
	local itemLink = nil
	for link, id in pairs(bdlc.loot_sessions) do
		if (itemUID == id) then
			itemLink = link
		end
	end

	if (not bdlc.loot_sessions[itemLink]) then return false end
	if not bdlc:inLC() then return false end
	
	local currententry = bdlc:returnEntry(itemLink, playerName)
	
	if (not currententry) then 
		bdlc:debug("didn't find frame for player: "..playerName) 
		return false 
	end
	
	local wantTable = {
		[1] = {"Mainspec", {.2, 1, .2}},
		[2] = {"Minor Up", {.6, 1, .6}},
		[3] = {"Offspec", {.8, .6, .6}},
		[4] = {"Reroll", {.1, .6, .6}},
		[5] = {"Transmog", {.8, .4, 1}}
	}
	
	local wantText = wantTable[want][1]
	local wantColor = wantTable[want][2]
	
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
	
	bdlc.loot_want[itemLink][playerName] = {itemLink, playerName, want, itemLink1, itemLink2}
	
	bdlc:repositionFrames()
end

----------------------------------------
-- AddUserNotes
----------------------------------------
function bdlc:addUserNotes(itemUID, playerName, notes)
	playerName = FetchUnitName(playerName)
	local itemLink = nil
	for link, id in pairs(bdlc.loot_sessions) do
		if (itemUID == id) then
			itemLink = link
		end
	end

	bdlc:debug("Add "..playerName.." notes")
	if (not bdlc.loot_sessions[itemLink]) then return false end
	if not bdlc:inLC() then return false end
	
	local currententry = bdlc:returnEntry(itemLink,playerName)
	
	if (not currententry) then return false end
	
	currententry.notes = notes
	currententry.user_notes:Show()
end

----------------------------------------
-- UpdateUserItem
----------------------------------------
function bdlc:updateUserItem(itemLink, frame)
	local link = select(2, GetItemInfo(itemLink))
	local texture = select(10, GetItemInfo(itemLink))
	frame:Show()
	frame.tex:SetTexture(texture)
	frame:SetScript("OnEnter", function()
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(link)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
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
function bdlc:voteForUser(councilName, itemLink, playerName)
	playerName = FetchUnitName(playerName)
	
	if (not bdlc.loot_sessions[itemLink]) then return false end
	if not bdlc:inLC() then return false end
	
	-- make sure theres an array to represent this user in the raid
	bdlc.loot_council_votes[itemLink][playerName] = bdlc.loot_council_votes[itemLink][playerName] or {}
	-- first, unset this council member on any other user for this item
	for playerName, v in pairs(bdlc.loot_council_votes[itemLink]) do
		v[councilName] = nil
	end
	
	-- now add this council member as a vote for this raid member and this itemLink
	bdlc.loot_council_votes[itemLink][playerName][councilName] = true
	
	-- now lets loop through open sessions, and their entries while tallying votes for said item>entry
	for itemLink, _ in pairs(bdlc.loot_sessions) do
		for i = 1, #f.tabs do
			if (f.tabs[i].itemLink == itemLink) then
				for e = 1, #f.entries[i] do
					local currententry = f.entries[i][e]
					if (currententry.active and bdlc.loot_council_votes[itemLink][currententry.playerName]) then
						local votes = 0
						for k, v in pairs(bdlc.loot_council_votes[itemLink][currententry.playerName]) do
							votes = votes + 1
						end
						currententry.votes.text:SetText(votes)
					end
				end
			end
		end
	end
	
end

bdlc:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
	if (event == "ADDON_LOADED" and arg1 == "BDLC") then
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
		
		--------------------------------------------------------------------------------
		-- Load configuration or set bdlc.defaults
		--------------------------------------------------------------------------------
		print("|cff3399FFBig Dumb Loot Council|r loaded. /bdlc for options")
		RegisterAddonMessagePrefix(bdlc.message_prefix);
		if (not bdlc_config) then
			bdlc_config = bdlc.defaults
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
				print("|cff3399FFBCLC|r Options:")
				print("  /bdlc test - Tests the addon (must be in raid)")
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
				
				if (IsMasterLooter() or IsRaidLeader() or not IsInRaid()) then
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
	
	if (event == "PLAYER_ENTERING_WORLD") then
		SendAddonMessage(bdlc.message_prefix, "fetchLC", bdlc.sendTo, UnitName("player"));
		if (IsInRaid()) then
			bdlc.sendTo = "RAID"
		else
			bdlc.sendTo = "WHISPER"
		end
	end
	
	if (event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LOOT_METHOD_CHANGED") then
		bdlc:buildLC()
		if (IsInRaid()) then
			bdlc.sendTo = "RAID"
		else
			bdlc.sendTo = "WHISPER"
		end
		--SendAddonMessage(bdlc.message_prefix, "fetchLC", bdlc.sendTo, UnitName("player"));
		--SendAddonMessage(bdlc.message_prefix, "fetchSessions:"..bdlc.local_player, bdlc.sendTo, UnitName("player"))
		--bdlc:UnregisterEvent("GROUP_ROSTER_UPDATE")
	end
	
	if (IsMasterLooter() and event == "LOOT_CLOSED") then
		f.voteFrame.enchanters:Hide()
	end
	if (IsMasterLooter() and event == "LOOT_OPENED") then
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
	
	
	if (event == "CHAT_MSG_WHISPER") then
		if (IsMasterLooter()) then
			bdlc:takeWhisperEntry(arg1, arg2)
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
			SendAddonMessage(bdlc.message_prefix, "endSession><"..itemLink, bdlc.sendTo, UnitName("player"));
			bdlc:endSession(itemLink)
		end
		
		bdlc.award_slot = {}
		bdlc.loot_slots[arg1] = nil
	end
	
	
	if (event == "CHAT_MSG_ADDON" and arg1 == bdlc.message_prefix) then
		local method, partyMaster, raidMaster = GetLootMethod()
		if (method == "master" or not IsInRaid()) then
			local param = bdlc:split(arg2, "><")
			local action = param[0] or arg2;
			
			--bdlc:debug(action..": "..unpack(param))
			
			-- the numbers were made strings by the chat_msg_addon, lets find our numbers and convert them tonumbers
			for p = 0, #param do
				local test = param[p]
				if (tonumber(test)) then
					param[p] = tonumber(param[p])
				end
			end
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
				fetchSessions(param[1])
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
			else
				
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
				bdlc:startSession(v)
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