local bdlc, l, f = select(2, ...):unpack()
f.rolls = {}
f.tabs = {}
f.entries = {}

function bdlc:fetchUserGear(unit, itemLink)
	
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	
	local isRelic = bdlc:IsRelic(itemLink)
	
	local isTier = bdlc:IsTier(itemLink)
	
	if (isTier) then
		if (strfind(name:lower(), l["tierHelm"]:lower())) then
			equipSlot = "INVTYPE_HEAD"
		elseif (strfind(name:lower(), l["tierShoulders"]:lower())) then
			equipSlot = "INVTYPE_SHOULDER"
		elseif (strfind(name:lower(), l["tierLegs"]:lower())) then
			equipSlot = "INVTYPE_LEGS"
		elseif (strfind(name:lower(), l["tierCloak"]:lower())) then
			equipSlot = "INVTYPE_BACK"
		elseif (strfind(name:lower(), l["tierChest"]:lower())) then
			equipSlot = "INVTYPE_CHEST"
		elseif (strfind(name:lower(), l["tierGloves"]:lower())) then
			equipSlot = "INVTYPE_HAND"
		end
	end
	
	local slotID = 0;
	if (equipSlot == "INVTYPE_HEAD") then slotID = 1 end
	if (equipSlot == "INVTYPE_NECK") then slotID = 2 end
	if (equipSlot == "INVTYPE_SHOULDER") then slotID = 3 end
	if (equipSlot == "INVTYPE_BODY") then slotID = 4 end
	if (equipSlot == "INVTYPE_CHEST" or equipSlot == "INVTYPE_ROBE") then slotID = 5 end
	if (equipSlot == "INVTYPE_WAIST") then slotID = 6 end
	if (equipSlot == "INVTYPE_LEGS") then slotID = 7 end
	if (equipSlot == "INVTYPE_FEET") then slotID = 8 end
	if (equipSlot == "INVTYPE_WRIST") then slotID = 9 end
	if (equipSlot == "INVTYPE_HAND") then slotID = 10 end
	if (equipSlot == "INVTYPE_BACK") then slotID = 15 end
	if (equipSlot == "INVTYPE_CLOAK") then slotID = 15 end
	if (equipSlot == "INVTYPE_OFFHAND") then slotID = 17 end
	if (equipSlot == "INVTYPE_RANGED") then slotID = 18 end
	
	
	local itemLink1 = GetInventoryItemLink(unit, slotID)
	local itemLink2 = 0

	if (equipSlot == "INVTYPE_FINGER") then 
		itemLink1 = GetInventoryItemLink(unit, 11)
		itemLink2 = GetInventoryItemLink(unit, 12)
		slotID = 11
	end
	if (equipSlot == "INVTYPE_TRINKET") then
		itemLink1 = GetInventoryItemLink(unit, 13)
		itemLink2 = GetInventoryItemLink(unit, 14)
		slotID = 13
	end
	if (equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_2HWEAPON" or equipSlot == "INVTYPE_SHIELD" or equipSlot == "INVTYPE_HOLDABLE" or equipSlot == "INVTYPE_RANGEDRIGHT" or equipSlot == "INVTYPE_RANGED" or equipSlot == "INVTYPE_WEAPONMAINHAND") then
		itemLink1 = GetInventoryItemLink(unit, 16)
		itemLink2 = GetInventoryItemLink(unit, 17)
		slotID = 16
	end
	if (isRelic) then
		local relicType = bdlc:GetRelicType(itemLink)
		local relic1, relic2 = bdlc:GetRelics(relicType)
		
		if (relic1) then
			itemLink1 = relic1
		end
		if (relic2) then
			itemLink2 = relic2
		end
	end
	if (not itemLink1) then
		itemLink1 = 0
	end
	if (not itemLink2) then
		itemLink2 = 0
	end
	
	if (slotID == 0 and not isRelic) then
		print("bdlc can't find compare for slot: "..equipSlot..". Let the developer know");
	end
	
	return itemLink1, itemLink2
end

function bdlc:repositionFrames()
	-- Loop through tabs and entries, sort by want level
	local lasttab = nil
	for t = 1, #f.tabs do
		local currenttab = f.tabs[t]
		local lastentry = nil
		local newtable = {}

		table.sort(f.entries[t], function(a, b)
			a.wantLevel = a.wantLevel or 0
			b.wantLevel = b.wantLevel or 0
			if a.rankIndex ~= b.rankIndex then
				return a.rankIndex > b.rankIndex
			end
			if a.wantLevel ~= b.wantLevel then
				return a.wantLevel < b.wantLevel
			end
			return a.name:GetText() > b.name:GetText()
		end)
		
		for e = 1, #f.entries[t] do
			local currententry = f.entries[t][e]
			if (currententry.active) then
				if (lastentry) then
					currententry:SetPoint("TOPLEFT", lastentry, "BOTTOMLEFT", 0, 1)
				else
					currententry:SetPoint("TOPLEFT", currenttab.table.content, "TOPLEFT", 0, 1)
				end
				lastentry = currententry
			end
		end
		
		if (currenttab.active) then
			if (lasttab) then
				currenttab:SetPoint("TOPRIGHT", lasttab, "BOTTOMRIGHT", 0, 2)
			else
				currenttab:SetPoint("TOPRIGHT", f.voteFrame.tabs, "TOPRIGHT", 2, 0)
			end
			lasttab = currenttab
		end
	end
	-- Loop through rolls
	local lastroll = nil
	for r = 1, #f.rolls do
		local currentroll = f.rolls[r]
		
		if (currentroll.active) then
			if (lastroll) then
				currentroll:SetPoint("TOPLEFT", lastroll, "BOTTOMLEFT", 0, 1)
			else
				currentroll:SetPoint("TOPLEFT", rollFrame, "TOPLEFT", 0, 0)
			end
			lastroll = currentroll
		end
	end
	if (not lastroll) then
		rollFrame:Hide()
	end
	if (not lasttab) then
		f.voteFrame:Hide()
	end
	
	-- if no tab is selected, select the first tab
	local tabselect = nil
	for tabs = 1, #f.tabs do
		if (f.tabs[tabs]:GetAlpha() == 1) then
			tabselect = true
			f.tabs[tabs].selected = true
			f.tabs[tabs].icon:SetDesaturated(false)
		else
			f.tabs[tabs].selected = false
			f.tabs[tabs].icon:SetDesaturated(true)
		end
	end
	
	if (not tabselect) then
		local currenttab = nil
		for i = 1, #f.tabs do
			if (not currenttab and f.tabs[i].active) then
				currenttab = f.tabs[i]
				currenttab:SetAlpha(1)
				currenttab.selected = true
				currenttab.table:Show()
				currenttab.icon:SetDesaturated(false)
				
				break
			end
		end
	end
end

local function awardLoot(...)
	local name, dropdown, itemUID, enchanter = ...
	if (not enchanter) then enchanter = false end
	bdlc.award_slot = nil
	local name = FetchUnitName(name)
	name, server = strsplit("-",name)
	server = server or bdlc.player_realm;

	if (not itemUID) then
		for t = 1, #f.tabs do
			if (f.tabs[t].active) then
				itemUID = f.tabs[t].itemUID
				break
			end
		end
	end
	local itemLink = bdlc.itemUID_Map[itemUID]
	bdlc:debug("Award "..itemLink.." to "..name)
	
	for slot = 1, GetNumLootItems() do
		local slot_itemLink = GetLootSlotLink(slot)
		
		if (slot_itemLink == itemLink) then
			bdlc.award_slot = slot
			break
		end
	end
	
	if (bdlc.award_slot) then
		for i = 1, 40 do
			local candidate = GetMasterLootCandidate(bdlc.award_slot,i)
			
			if (candidate == name or candidate == name.."-"..server) then
				GiveMasterLoot(bdlc.award_slot, i)
				local name = UnitName("raid"..i)
				local datetimestamp = time().."."..GetTime()
				
				local wantInfo = bdlc.wantTable[want]

				print("|cff3399FFBDLC|r Awarding "..itemLink.." to "..playerName..": "..wantInfo[1])
				
				--[[local itemUID, playerName, want, itemLink1, itemLink2 = unpack(bdlc.loot_want[itemUID][name])
				
				
				
				if (playerName) then					
					bdlc:sendAction("addLootHistory", itemUID, playerName, enchanter)
				end--]]
				break
			end
		end
	end
	dropdown:Hide()
end

-------------------------------------------------------
--	Create all the necessary frames now, use them forever. 
-------------------------------------------------------
bdlc.font_small = CreateFont("BDLC_FONT_SMALL")
bdlc.font_small:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 12)
bdlc.font_small:SetShadowColor(0, 0, 0)
bdlc.font_small:SetShadowOffset(1, -1)
bdlc.font = CreateFont("BDLC_FONT")
bdlc.font:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 13)
bdlc.font:SetShadowColor(0, 0, 0)
bdlc.font:SetShadowOffset(1, -1)
bdlc.font_large = CreateFont("BDLC_FONT_LARGE")
bdlc.font_large:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 14)
bdlc.font_large:SetShadowColor(0, 0, 0)
bdlc.font_large:SetShadowOffset(1, -1)
bdlc.normal_text = CreateFont("bdlc_button")
bdlc.normal_text:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 13)
bdlc.normal_text:SetTextColor(1,1,1,1)
bdlc.normal_text:SetShadowColor(0, 0, 0)
bdlc.normal_text:SetShadowOffset(1, -1)
bdlc.normal_text:SetJustifyH("CENTER")

--Vote Window
f.voteFrame = CreateFrame('frame', 'BDLC', UIParent)
bdlc:skinBackdrop(f.voteFrame, .1,.1,.1,.8);
f.voteFrame:EnableMouse(true);
f.voteFrame:SetMovable(true);
f.voteFrame:SetUserPlaced(true);
f.voteFrame:SetFrameStrata("DIALOG");
f.voteFrame:SetFrameLevel(1);
f.voteFrame:SetClampedToScreen(true);
f.voteFrame:SetSize(600, 400);
f.voteFrame:SetPoint("CENTER");
f.voteFrame:Hide()

-- Header
f.voteFrame.header = CreateFrame("frame", nil, f.voteFrame);
f.voteFrame.header:EnableMouse(true);
f.voteFrame.header:RegisterForDrag("LeftButton","RightButton")
f.voteFrame.header:SetScript("OnDragStart", function(self) f.voteFrame:StartMoving() end)
f.voteFrame.header:SetScript("OnDragStop", function(self)  f.voteFrame:StopMovingOrSizing() end)
f.voteFrame.header:SetPoint("TOPLEFT", f.voteFrame, "TOPLEFT")
f.voteFrame.header:SetPoint("BOTTOMRIGHT", f.voteFrame, "TOPRIGHT", 0, -24)
bdlc:skinBackdrop(f.voteFrame.header,.1,.1,.1,1)

	f.voteFrame.header.close = CreateFrame("Button", nil, f.voteFrame.header)
	f.voteFrame.header.close:SetPoint("RIGHT", f.voteFrame.header, "RIGHT", -4, 0)
	f.voteFrame.header.close:SetText("x")
	bdlc:skinButton(f.voteFrame.header.close,true,"red")
	f.voteFrame.header.close:SetScript("OnClick", function()
		f.voteFrame:Hide()
	end)

	f.voteFrame.header.text = f.voteFrame.header:CreateFontString(nil, "OVERLAY", "BDLC_FONT_LARGE")
	f.voteFrame.header.text:SetText("|cff3399FFBig Dumb Loot Council|r")
	f.voteFrame.header.text:SetPoint("CENTER", f.voteFrame.header, "CENTER")

-- Loot Council Display
f.voteFrame.loot_council = CreateFrame("frame", nil, f.voteFrame)
f.voteFrame.loot_council:SetPoint("BOTTOMLEFT", f.voteFrame, "BOTTOMLEFT", 10, 6)
f.voteFrame.loot_council:SetSize(84, 18)
bdlc:skinBackdrop(f.voteFrame.loot_council, .1,.1,.1,.8);
f.voteFrame.loot_council.text = f.voteFrame.loot_council:CreateFontString(nil, "OVERLAY", "BDLC_FONT_LARGE")
f.voteFrame.loot_council.text:SetPoint("LEFT", f.voteFrame.loot_council, "LEFT", 4, 0)
f.voteFrame.loot_council.text:SetText(l["frameLC"])
f.voteFrame.loot_council.text:SetJustifyH("LEFT")
f.voteFrame.loot_council.image = f.voteFrame.loot_council:CreateTexture(nil, "OVERLAY")
f.voteFrame.loot_council.image:SetTexture("Interface\\FriendsFrame\\InformationIcon")
f.voteFrame.loot_council.image:SetSize(10, 10)
f.voteFrame.loot_council.image:SetPoint("RIGHT", f.voteFrame.loot_council, "RIGHT", -4, 0)
f.voteFrame.loot_council.image:SetVertexColor(.8,.8,.8)

f.voteFrame.loot_council.add = CreateFrame("BUTTON", nil, f.voteFrame.loot_council)
f.voteFrame.loot_council.add:SetText(" + ")
bdlc:skinButton(f.voteFrame.loot_council.add,true,"blue")
f.voteFrame.loot_council.add:SetPoint("LEFT", f.voteFrame.loot_council, "RIGHT", 2, 0)
f.voteFrame.loot_council.add:SetWidth(18)
StaticPopupDialogs["ADD_TO_LC_BOX"] = {
	text = "Type the player name to add to Loot Council",
	button1 = "Add",
	button2 = "Cancel",
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(self)
		local text = self.editBox:GetText()
		bdlc:addremoveLC("addtolc", text)
		StaticPopup_Hide("ADD_TO_LC_BOX")
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText()
		bdlc:addremoveLC("addtolc", text)
		StaticPopup_Hide("ADD_TO_LC_BOX")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
f.voteFrame.loot_council.add:SetScript("OnClick", function()
	StaticPopup_Show("ADD_TO_LC_BOX")
end)

f.voteFrame:HookScript("OnShow", function()
	if (IsMasterLooter() or UnitIsGroupLeader("player") or not IsInRaid()) then
		f.voteFrame.loot_council.add:Show()
	else
		f.voteFrame.loot_council.add:Hide()
	end
end)

f.voteFrame.loot_council:SetScript("OnEnter", function()
	ShowUIPanel(GameTooltip)
	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	
	for councilName, v in pairs(bdlc.loot_council) do
		local name, server = strsplit("-", councilName)
		if (server == player_realm) then
			councilName = name
		end
		local classFileName = select(2, UnitClass(councilName))
		local color = RAID_CLASS_COLORS[classFileName] or {["r"] = 1, ["b"] = 1, ["g"] = 1}
		GameTooltip:AddLine(councilName, color.r, color.g, color.b)
	end

	GameTooltip:Show()
end)
f.voteFrame.loot_council:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

-- Loot Disenchanters
f.voteFrame.enchanters = CreateFrame("Button", nil, f.voteFrame)
f.voteFrame.enchanters:SetText("Disenchant")
f.voteFrame.enchanters:Hide()
f.voteFrame.enchanters:SetPoint("BOTTOMRIGHT", f.voteFrame, "BOTTOMRIGHT", -8, 6)
bdlc:skinButton(f.voteFrame.enchanters, true, "blue")
f.voteFrame.enchanters:SetScript("OnEnter", function()
	ShowUIPanel(GameTooltip)
	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	if (GetNumLootItems() > 0) then
		GameTooltip:AddLine("Click to Disenchant")
	else
		GameTooltip:AddLine("Loot the boss to choose a Disenchanter")
	end
	GameTooltip:Show()
end)
f.voteFrame.enchanters:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)
f.voteFrame.enchanters:SetScript("OnClick", function()
	if (GetNumLootItems() > 0) then
		if (f.voteFrame.enchanters.dropdown:IsShown()) then
			f.voteFrame.enchanters.dropdown:Hide()
		else
			local itemUID = nil
			for i = 1, #f.tabs do
				if (f.tabs[i].selected) then
					itemUID = f.tabs[i].itemUID
				end
			end
			
			for i = 1, 4 do
				f.voteFrame.enchanters.dropdown[i]:Hide()
			end
			f.voteFrame.enchanters.dropdown:Show()
			table.sort(bdlc.enchanters, function(a, b)
				return a < b
			end)
			local index = 1
			for name, gRank in pairs(bdlc.enchanters) do
				--if index <= 4 then
					--local vname, server = strsplit("-", name)
					f.voteFrame.enchanters.dropdown[index]:Show()
					f.voteFrame.enchanters.dropdown[index]:SetText(name)
					f.voteFrame.enchanters.dropdown[index].itemUID = itemUID
					f.voteFrame.enchanters.dropdown[index].playerName = name

					index = index + 1
				--end
			end
		end
	end
end)
f.voteFrame.enchanters.dropdown = CreateFrame("frame", nil, f.voteFrame.enchanters)
f.voteFrame.enchanters.dropdown:SetSize(100, (22*4)-2)
f.voteFrame.enchanters.dropdown:Hide()
f.voteFrame.enchanters.dropdown:SetPoint("TOP", f.voteFrame.enchanters, "BOTTOM", 0, 1)
bdlc:skinBackdrop(f.voteFrame.enchanters.dropdown, .1,.1,.1,1)
for i = 1, 4 do
	f.voteFrame.enchanters.dropdown[i] = CreateFrame("Button", nil, f.voteFrame.enchanters.dropdown)
	local enchanter = f.voteFrame.enchanters.dropdown[i]
	enchanter:Hide()
	enchanter:SetSize(100, 22)
	enchanter:SetPoint("TOP", f.voteFrame.enchanters.dropdown, "TOP", 0, -22*(i-1))
	enchanter:SetNormalFontObject("bdlc_button")
	enchanter:SetHighlightFontObject("bdlc_button")
	enchanter:SetPushedTextOffset(0,-1)
	enchanter:SetScript("OnClick", function(self)
		awardLoot(self.playerName, f.voteFrame.enchanters.dropdown, self.itemUID, true)
	end)
end

-- Rolls
rollFrame = CreateFrame('frame', "BDLC Roll Window", bdlc)
rollFrame:SetSize(458, 1)
rollFrame:SetPoint("CENTER", UIParent, "CENTER", 600, 0)
rollFrame:EnableMouse(true)
rollFrame:SetMovable(true);
rollFrame:SetUserPlaced(true);
rollFrame:SetFrameStrata("FULLSCREEN");
rollFrame:SetFrameLevel(10)
rollFrame:SetClampedToScreen(true);
rollFrame:RegisterForDrag("LeftButton","RightButton")
rollFrame:SetScript("OnDragStart", function(self) rollFrame:StartMoving() end)
rollFrame:SetScript("OnDragStop", function(self) rollFrame:StopMovingOrSizing() end)

rollFrame.title = rollFrame:CreateFontString(nil, "OVERLAY", "BDLC_FONT_LARGE")
rollFrame.title:SetText("Big Dumb Loot Council")
rollFrame.title:SetPoint("BOTTOM", rollFrame, "TOP", 0, 2)

rollFrame:Hide()

-- Create roll children
for i = 1, 10 do
	local roll = CreateFrame("frame", nil, rollFrame);
	roll:SetPoint("TOPLEFT", rollFrame, "TOPLEFT", 0, -(59*(i-1)))
	roll:SetSize(rollFrame:GetWidth(), 60);
	roll.itemUID = 0
	roll.active = false
	roll.notes = "";
	roll:Hide()
	roll:EnableMouse(true)
	roll:RegisterForDrag("LeftButton","RightButton")
	roll:SetScript("OnDragStart", function(self) rollFrame:StartMoving() end)
	roll:SetScript("OnDragStop", function(self) rollFrame:StopMovingOrSizing() end)
	bdlc:skinBackdrop(roll, .2, .2, .2, .9)
	
	-- Loot item info/hover
	roll.item = CreateFrame("frame", nil, roll);
	roll.item:SetAllPoints(roll)

	roll.item.icon = CreateFrame("frame", nil, roll.item)
	roll.item.icon:SetSize(50, 50)
	roll.item.icon:SetPoint("TOPLEFT", roll, "TOPLEFT", 5, -5)
	bdlc:skinBackdrop(roll.item.icon, 0,0,0,.8);
	
	roll.item.icon.wfsock = roll.item.icon:CreateFontString(nil, "ARTWORK")
	roll.item.icon.wfsock:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 14,"OUTLINE")
	roll.item.icon.wfsock:SetText("")
	roll.item.icon.wfsock:SetTextColor(0.7,0.7,0.7)
	roll.item.icon.wfsock:SetPoint("CENTER", roll.item.icon, "CENTER", 0, 0)
	roll.item.icon.wfsock:SetJustifyH("CENTER")
	
	roll.item.icon.tex = roll.item.icon:CreateTexture(nil, "ARTWORK")
	roll.item.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	roll.item.icon.tex:SetDrawLayer('ARTWORK')
	roll.item.icon.tex:SetTexture(nil)
	roll.item.icon.tex:SetPoint("TOPLEFT", roll.item.icon, "TOPLEFT", 2, -2)
	roll.item.icon.tex:SetPoint("BOTTOMRIGHT", roll.item.icon, "BOTTOMRIGHT", -2, 2)
	
	roll.item.item_text = roll.item:CreateFontString(nil, "ARTWORK","BDLC_FONT_LARGE")
	roll.item.item_text:SetText(l["frameItem"])
	roll.item.item_text:SetPoint("TOPLEFT", roll, "TOPLEFT", 60, -8)
	roll.item.item_text:SetJustifyH("LEFT")
	
	roll.item.num_items = roll:CreateFontString(nil, "OVERLAY","BDLC_FONT")
	roll.item.num_items:SetText("x1")
	roll.item.num_items:SetPoint("LEFT", roll.item.item_text, "RIGHT", 6, 0)
	roll.item.num_items:SetJustifyH("LEFT")
	
	--[[roll.item.item_ilvl = roll:CreateFontString(nil, "OVERLAY", "BDLC_FONT_SMALL")
	roll.item.item_ilvl:SetText("ilvl: ")
	roll.item.item_ilvl:SetPoint("TOPRIGHT", roll, "TOPRIGHT", -5, -10)
	roll.item.item_ilvl:SetJustifyH("RIGHT")--]]
	
	-- Loot Buttons
	roll.buttons = CreateFrame("frame", nil, roll);
	roll.buttons:SetPoint("BOTTOMLEFT", roll, "BOTTOMLEFT", 50, 0);
	roll.buttons:SetPoint("TOPRIGHT", roll, "BOTTOMRIGHT", 0, 40);
	
	roll.buttons.submit = function(wantLevel)
		local itemLink = bdlc.itemUID_Map[roll.itemUID]
		local itemLink1, itemLink2 = bdlc:fetchUserGear("player", itemLink)
		
		determineScope()

		SendAddonMessage(bdlc.message_prefix, "addUserWant><"..roll.itemUID.."><"..bdlc.local_player.."><"..wantLevel.."><"..itemLink1.."><"..itemLink2, bdlc.sendTo, UnitName("player"));
		
		local notes = roll.notes
		if (string.len(roll.qn) > 0) then
			roll.qn = string.sub(roll.qn, 0, -3)
			if (string.len(notes) > 0) then
				notes = notes..", "..roll.qn
			else
				notes = roll.qn
			end
		end
		if (string.len(notes) > 0) then
			SendAddonMessage(bdlc.message_prefix, "addUserNotes><"..roll.itemUID.."><"..bdlc.local_player.."><"..notes, bdlc.sendTo, UnitName("player"));
		end

		roll.itemUID = 0
		roll.active = false
		roll.notes = ""
		roll.qn = ""
		roll.buttons.notes:SetText("")
		roll.buttons.notes:Hide()
		roll:Hide()
		bdlc:repositionFrames()
	end
	
	roll.buttons.main = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.main:SetPoint("LEFT", roll.buttons, "LEFT", 8, -1)
	roll.buttons.main:SetText(l["frameMain"])
	bdlc:skinButton(roll.buttons.main)
	roll.buttons.main:SetScript("OnClick", function() roll.buttons.submit(1) end)
	
	roll.buttons.minor = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.minor:SetPoint("LEFT", roll.buttons.main, "RIGHT", 4, 0)
	roll.buttons.minor:SetText(l["frameMinorUp"])
	bdlc:skinButton(roll.buttons.minor)
	roll.buttons.minor:SetScript("OnClick", function() roll.buttons.submit(2) end)
	
	roll.buttons.off = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.off:SetPoint("LEFT", roll.buttons.minor, "RIGHT", 4, 0)
	roll.buttons.off:SetText(l["frameOffspec"])
	bdlc:skinButton(roll.buttons.off)
	roll.buttons.off:SetScript("OnClick", function() roll.buttons.submit(3) end)
	
	roll.buttons.reroll = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.reroll:SetPoint("LEFT", roll.buttons.off, "RIGHT", 4, 0)
	roll.buttons.reroll:SetText(l["frameReroll"])
	bdlc:skinButton(roll.buttons.reroll)
	roll.buttons.reroll:SetScript("OnClick", function() roll.buttons.submit(4) end)
	
	roll.buttons.xmog = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.xmog:SetPoint("LEFT", roll.buttons.reroll, "RIGHT", 4, 0)
	roll.buttons.xmog:SetText(l["frameTransmog"])
	bdlc:skinButton(roll.buttons.xmog)
	roll.buttons.xmog:SetScript("OnClick", function() roll.buttons.submit(5) end)
	
	roll.buttons.note = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.note:SetSize(40, 25)
	roll.buttons.note:SetPoint("LEFT", roll.buttons.xmog, "RIGHT", 4, 0)
	roll.buttons.note:SetText(l["frameNote"])
	bdlc:skinButton(roll.buttons.note,false,"blue")
	roll.buttons.note:SetScript("OnClick", function()
		roll.buttons.notes:Show()
		roll.buttons.notes:SetFocus()
		
	end)
	
	roll.qn = "";
	roll.buttons.note.quicknotes = CreateFrame("frame",nil,roll.buttons)
	roll.buttons.note.quicknotes:SetPoint("TOPRIGHT", roll.buttons, "TOPRIGHT", -2, 16)
	roll.buttons.note.quicknotes:SetPoint("BOTTOMLEFT", roll.buttons, "TOPLEFT", 0, -8)
	roll.buttons.note.quicknotes:EnableMouse(true)
	roll.buttons.note.quicknotes:RegisterForDrag("LeftButton","RightButton")
	roll.buttons.note.quicknotes:SetScript("OnDragStart", function(self) rollFrame:StartMoving() end)
	roll.buttons.note.quicknotes:SetScript("OnDragStop", function(self) rollFrame:StopMovingOrSizing() end)
	
	roll.buttons.note.quicknotes.append = function(text)
		if (string.len(text) > 0 and not strfind(roll.qn, text)) then
			roll.qn = roll.qn..text..", "
		end
	end
	local lastqn = nil
	for i = 1, 10 do
		roll.buttons.note.quicknotes[i] = CreateFrame("button",nil,roll.buttons.note.quicknotes)
		local qn = roll.buttons.note.quicknotes[i]
		qn:SetAlpha(0.6)
		qn:SetText("")
		if (not lastqn) then
			qn:SetPoint("BOTTOMRIGHT", roll.buttons.note.quicknotes, "BOTTOMRIGHT", -4, 4)
		else
			qn:SetPoint("RIGHT", lastqn, "LEFT", 1, 0)
		end
		lastqn = qn
		qn:SetScript("OnClick", function() 
			roll.buttons.note.quicknotes.append(qn:GetText()) 
			if (not qn.selected) then
				bdlc:skinButton(qn,false,"blue")
				qn:SetAlpha(1)
				qn.selected = true
			else
				bdlc:skinButton(qn,false)
				qn:SetAlpha(0.6)
				qn.selected = false
			end
		end)
	end
	
	roll.buttons.pass = CreateFrame("Button", nil, roll.buttons)
	roll.buttons.pass:SetSize(42, 25)
	roll.buttons.pass:SetPoint("LEFT", roll.buttons.note, "RIGHT", 4, 0)
	roll.buttons.pass:SetText(l["framePass"])
	bdlc:skinButton(roll.buttons.pass,false,"red")
	roll.buttons.pass:SetScript("OnClick", function()
		SendAddonMessage(bdlc.message_prefix, "removeUserConsidering><"..roll.itemUID.."><"..bdlc.local_player, bdlc.sendTo, UnitName("player"));
		roll.itemUID = 0
		roll.active = false
		roll.notes = ""
		roll.buttons.notes:SetText("")
		roll.buttons.notes:Hide()
		roll:Hide()
		bdlc:repositionFrames()
	end)
	
	roll.buttons.notes = CreateFrame("EditBox", nil, roll.buttons)
	roll.buttons.notes:SetSize(310, 24)
	roll.buttons.notes:SetPoint("BOTTOMLEFT", roll.buttons, "BOTTOMLEFT", 8, 7)
	roll.buttons.notes:SetMaxLetters(100)
	roll.buttons.notes:IsMultiLine(1)
	roll.buttons.notes:SetTextInsets(6, 2, 2, 2)
	roll.buttons.notes:SetFontObject("BDLC_FONT")
	roll.buttons.notes:SetFrameLevel(27)
	roll.buttons.notes:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
	roll.buttons.notes:SetBackdropColor(.1,.1,.1,1)
	roll.buttons.notes:SetBackdropBorderColor(0,0,0,1)
	roll.buttons.notes:Hide()
	roll.buttons.notes.okay = CreateFrame("Button", nil, roll.buttons.notes)
	roll.buttons.notes.okay:SetSize(37, 25)
	roll.buttons.notes.okay:SetPoint("LEFT", roll.buttons.notes, "RIGHT", -1, 0)
	roll.buttons.notes.okay:SetText(l["frameOkay"])
	bdlc:skinButton(roll.buttons.notes.okay)
	roll.buttons.notes.okay:SetScript("OnClick", function(self)
		self:GetParent():Hide()
		roll.notes = self:GetParent():GetText()
	end)
	roll.buttons.notes:SetScript("OnEnterPressed", function(self, key) roll.buttons.notes.okay:Click() end)
	roll.buttons.notes:SetScript("OnEscapePressed", function(self, key) roll.buttons.notes.okay:Click() end)
	
	f.rolls[i] = roll
end

-- Tabs
f.voteFrame.tabs = CreateFrame("frame", nil, f.voteFrame);
f.voteFrame.tabs:SetPoint("TOPLEFT", f.voteFrame, "TOPLEFT", -40, 0)
f.voteFrame.tabs:SetPoint("BOTTOMRIGHT", f.voteFrame, "BOTTOMLEFT", 0, 0)
-- Number of Items
for i = 1, 10 do
	local tab = CreateFrame('frame', nil, f.voteFrame.tabs)
	tab.active = false
	tab.itemUID = 0
	tab.selected = false
	tab:Hide()
	tab:SetSize(40, 40)
	tab:SetPoint("TOPRIGHT", tabs, "TOPRIGHT", 2, -38*(i-1))
	tab:SetAlpha(0.3)
	tab:EnableMouse(1)
	bdlc:skinBackdrop(tab, .1,.1,.1,.8);
	tab:SetScript("OnMouseDown", function(self, b)
		if (b == "LeftButton") then
			for tabs = 1, #f.tabs do
				f.tabs[tabs]:SetAlpha(0.3)
				f.tabs[tabs].table:Hide()
				f.tabs[tabs].icon:SetDesaturated(true)
				f.tabs[tabs].selected = false
			end
			
			self:SetAlpha(1)
			self.selected = true
			self.table:Show()
			self.icon:SetDesaturated(false)
		end
	end)
	
	tab.icon = tab:CreateTexture(nil, "OVERLAY")
	tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	tab.icon:SetDrawLayer('ARTWORK')
	tab.icon:SetTexture(nil)
	tab.icon:SetDesaturated(true)
	tab.icon:SetPoint("TOPLEFT", tab, "TOPLEFT", 2, -2)
	tab.icon:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
	
	tab.wfsock = tab:CreateFontString(nil, "ARTWORK")
	tab.wfsock:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 14,"OUTLINE")
	tab.wfsock:SetText("")
	tab.wfsock:SetTextColor(0.7,0.7,0.7)
	tab.wfsock:SetPoint("CENTER", tab, "CENTER", 0, 0)
	tab.wfsock:SetJustifyH("CENTER")
	
	--parent frame 
	local vote_table = CreateFrame("Frame", nil, tab) 
	vote_table:SetPoint("TOPLEFT", f.voteFrame, "TOPLEFT", 10, -100)
	vote_table:SetPoint("BOTTOMRIGHT", f.voteFrame, "BOTTOMRIGHT", -30, 30)
	vote_table:Hide()
	bdlc:skinBackdrop(vote_table, .1,.1,.1,.8);
	tab.table = vote_table
	
	--scrollframe 
	scrollframe = CreateFrame("ScrollFrame", nil, vote_table) 
	scrollframe:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 0, -2) 
	scrollframe:SetPoint("BOTTOMRIGHT", vote_table, "BOTTOMRIGHT", 0, 2) 
	vote_table.scrollframe = scrollframe 
	 
	--scrollbar 
	scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPLEFT", vote_table, "TOPRIGHT", 6, -16) 
	scrollbar:SetPoint("BOTTOMLEFT", vote_table, "BOTTOMRIGHT", 0, 16) 
	scrollbar:SetMinMaxValues(1, 200) 
	scrollbar:SetValueStep(1) 
	scrollbar.scrollStep = 1
	scrollbar:SetValue(0) 
	scrollbar:SetWidth(16) 
	scrollbar:SetScript("OnValueChanged", function (self, value) self:GetParent():SetVerticalScroll(value) end) 
	bdlc:skinBackdrop(scrollbar, .1,.1,.1,.8);
	vote_table.scrollbar = scrollbar 
	 
	--content frame 
	vote_table.content = CreateFrame("Frame", nil, scrollframe) 
	vote_table.content:SetSize(560, 380) 
	scrollframe:SetScrollChild(vote_table.content)
	
	-- Headers
	vote_table.name_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.name_text:SetText(l["frameName"]);
	vote_table.name_text:SetTextColor(1, 1, 1);
	vote_table.name_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 10, 16);
	
	vote_table.rank_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.rank_text:SetText(l["frameRank"]);
	vote_table.rank_text:SetTextColor(1, 1, 1);
	vote_table.rank_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 80, 16);
	
	vote_table.ilvl_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.ilvl_text:SetText(l["frameIlvl"]);
	vote_table.ilvl_text:SetTextColor(1, 1, 1);
	vote_table.ilvl_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 170, 16);
	
	vote_table.ilvl_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.ilvl_text:SetText(l["frameInterest"]);
	vote_table.ilvl_text:SetTextColor(1, 1, 1);
	vote_table.ilvl_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 200, 16);
	
	vote_table.notes_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.notes_text:SetText(l["frameNotes"]);
	vote_table.notes_text:SetTextColor(1, 1, 1);
	vote_table.notes_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", -250, 16);
	
	vote_table.current_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.current_text:SetText(l["frameCurrentGear"]);
	vote_table.current_text:SetTextColor(1, 1, 1);
	vote_table.current_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", -160, 16);
	
	vote_table.votes_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.votes_text:SetText(l["frameVotes"]);
	vote_table.votes_text:SetTextColor(1, 1, 1);
	vote_table.votes_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", -100, 16);
	
	vote_table.actions_text = vote_table:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.actions_text:SetText("Vote   Remove");
	vote_table.actions_text:SetTextColor(1, 1, 1);
	vote_table.actions_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", 0, 16);
	
	-- Item icon and such
	vote_table.item = CreateFrame("frame", nil, vote_table)
	vote_table.item:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 10, 64)
	vote_table.item:SetAlpha(1)
	vote_table.item:SetSize(340, 40)

	vote_table.item.itemtext = vote_table.item:CreateFontString(nil, "OVERLAY", "BDLC_FONT_LARGE")
	vote_table.item.itemtext:SetText(l["frameItem"])
	vote_table.item.itemtext:SetPoint("TOPLEFT", vote_table.item, "TOPLEFT", 50, -6)
	
	vote_table.item.num_items = vote_table.item:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.item.num_items:SetTextColor(1,1,1,1);
	vote_table.item.num_items:SetText("x1");
	vote_table.item.num_items:SetPoint("LEFT", vote_table.item.itemtext, "RIGHT", 6, 0)

	vote_table.item.itemdetail = vote_table.item:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
	vote_table.item.itemdetail:SetText(l["frameIlvl"]..": ");
	vote_table.item.itemdetail:SetTextColor(1,1,1,.7);
	vote_table.item.itemdetail:SetPoint("BOTTOMLEFT", vote_table.item, "BOTTOMLEFT", 50, 6)

	vote_table.item.icon = CreateFrame("frame", nil, vote_table.item)
	vote_table.item.icon:SetSize(40, 40)
	vote_table.item.icon:SetPoint("TOPLEFT", vote_table.item, "TOPLEFT", 0, 0)
	bdlc:skinBackdrop(vote_table.item.icon, 0,0,0,.8);
	
	vote_table.item.wfsock = vote_table.item.icon:CreateFontString(nil, "ARTWORK")
	vote_table.item.wfsock:SetFont("Interface\\Addons\\BigDumbLootCouncil\\font.ttf", 14,"OUTLINE")
	vote_table.item.wfsock:SetText("")
	vote_table.item.wfsock:SetTextColor(0.7,0.7,0.7)
	vote_table.item.wfsock:SetPoint("CENTER", vote_table.item.icon, "CENTER", 0, 0)
	vote_table.item.wfsock:SetJustifyH("CENTER")

	vote_table.item.icon.tex = vote_table.item.icon:CreateTexture(nil, "OVERLAY")
	vote_table.item.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	vote_table.item.icon.tex:SetDrawLayer('ARTWORK')
	vote_table.item.icon.tex:SetTexture(nil)
	vote_table.item.icon.tex:SetPoint("TOPLEFT", vote_table.item.icon, "TOPLEFT", 2, -2)
	vote_table.item.icon.tex:SetPoint("BOTTOMRIGHT", vote_table.item.icon, "BOTTOMRIGHT", -2, 2)
	
	vote_table.endSession = CreateFrame("Button", nil, vote_table)
	vote_table.endSession:SetSize(100, 25)
	vote_table.endSession:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", 0, 60)
	vote_table.endSession:SetText(l["frameEndSession"])
	bdlc:skinButton(vote_table.endSession,false,"red")
	vote_table.endSession:SetScript("OnClick", function()
		SendAddonMessage(bdlc.message_prefix, "endSession><"..f.tabs[i].itemUID, bdlc.sendTo, UnitName("player"));
		bdlc:endSession(f.tabs[i].itemUID)
	end)
	
	
	f.entries[i] = {}
	
	local lastframe = nil
	for e = 1, 40 do
		-- Create entry in table
		local entry = CreateFrame("Button", nil, vote_table.content)
		entry.itemUID = 0
		entry.wantLevel = 0
		entry.rankIndex = 0
		entry.playerName = ""
		entry.notes = ""
		entry.active = false
		entry:SetSize(vote_table.content:GetWidth(), 22)
		if (lastframe) then
			entry:SetPoint("TOPLEFT", lastframe, "BOTTOMLEFT", 0, 2)
		else
			entry:SetPoint("TOPLEFT", vote_table.content, "TOPLEFT", 0, -3)
		end
		bdlc:skinBackdrop(entry, 1,1,1,.1)
		entry:Hide()

		entry.name = entry:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
		entry.name:SetText("test");
		entry.name:SetTextColor(1, 1, 1);
		entry.name:SetPoint("LEFT", entry, "LEFT", 10, 0)
		
		entry.award = CreateFrame("Frame",nil, entry)
		entry.award:SetPoint("TOPLEFT", entry.name, "BOTTOMLEFT", 0, -2)
		entry.award:SetSize(100, 42)
		entry.award:Hide()
		bdlc:skinBackdrop(entry.award, .1,.1,.1,1)
		
		entry.award.text = entry.award:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
		entry.award.text:SetText("Award loot to ?");
		entry.award.text:SetPoint("TOP", entry.award, "TOP", 0, -2)
		
		entry.award.yes = CreateFrame("Button", nil, entry.award)
		entry.award.yes:SetText(l["frameYes"])
		entry.award.yes:SetPoint("BOTTOMLEFT", entry.award, "BOTTOMLEFT", 2, 2)
		bdlc:skinButton(entry.award.yes,false,"blue")
		entry.award.yes:SetScript("OnClick", function(self)
			awardLoot(entry.playerName, entry.award, entry.itemUID)
		end)
		
		entry.award.no = CreateFrame("Button", nil, entry.award)
		entry.award.no:SetText(l["frameNo"])
		entry.award.no:SetPoint("BOTTOMRIGHT", entry.award, "BOTTOMRIGHT", -2, 2)
		entry.award.no:SetScript("OnClick", function() entry.award:Hide() end)
		bdlc:skinButton(entry.award.no,false,"red")
		
		entry:SetScript("OnClick", function() 
			for i = 1, #f.tabs do
				for e = 1, #f.entries[i] do
					f.entries[i][e].award:Hide()
				end
			end
		
			if (IsMasterLooter()) then
				if (entry.award:IsShown()) then
					entry.award:Hide()
				else
					entry.award:Show()
					entry.award.text:SetText(l["frameAward"]..entry.name:GetText().."?")
					entry.award:SetWidth(entry.award.text:GetWidth()+12)
				end
			else
				entry.award:Hide()
			end
		end)
		
		entry.rank = entry:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
		entry.rank:SetText(l["frameRank"]);
		entry.rank:SetTextColor(1,1,1);
		entry.rank:SetPoint("LEFT", entry, "LEFT", 80, 0)
		
		entry.ilvl = entry:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
		entry.ilvl:SetText(0);
		entry.ilvl:SetTextColor(1,1,1);
		entry.ilvl:SetPoint("LEFT", entry, "LEFT", 166, 0)
		
		entry.interest = entry:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
		entry.interest:SetText(l["frameConsidering"]);
		entry.interest:SetTextColor(.5,.5,.5);
		entry.interest:SetPoint("LEFT", entry, "LEFT", 198, 0)
		
		entry.user_notes = CreateFrame('frame', nil, entry)
		entry.user_notes:SetPoint("LEFT", entry, "LEFT", 284, 0)
		entry.user_notes:SetSize(16,16)
		entry.user_notes:Hide()
		entry.user_notes:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:AddLine(entry.notes, 1, 1, 1)
			GameTooltip:Show()
		end)
		entry.user_notes:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		entry.user_notes.tex = entry.user_notes:CreateTexture(nil, "OVERLAY")
		entry.user_notes.tex:SetAllPoints(entry.user_notes)
		entry.user_notes.tex:SetTexture("Interface\\FriendsFrame\\BroadcastIcon")
		
		
		entry.voteUser = CreateFrame("Button", nil, entry)
		entry.voteUser:SetSize(45, 20)
		entry.voteUser:SetPoint("RIGHT", entry, "RIGHT", -38, 0)
		entry.voteUser:SetText(l["frameVote"])
		bdlc:skinButton(entry.voteUser, true, "blue")
		entry.voteUser:Hide()
		entry.voteUser:SetScript("OnClick", function()
			bdlc:voteForUser(bdlc.local_player, entry.itemUID, entry.playerName)
			SendAddonMessage(bdlc.message_prefix, "voteForUser><"..bdlc.local_player.."><"..entry.itemUID.."><"..entry.playerName, bdlc.sendTo, UnitName("player"));
		end)
		
		entry.removeUser = CreateFrame("Button", nil, entry)
		entry.removeUser:SetSize(25, 20)
		entry.removeUser:SetPoint("RIGHT", entry, "RIGHT", -7, 0)
		entry.removeUser:SetText("x")
		entry.removeUser:Hide()
		bdlc:skinButton(entry.removeUser,true,"red")
		entry.removeUser:SetScript("OnClick", function()
			SendAddonMessage(bdlc.message_prefix, "removeUserConsidering><"..entry.itemUID.."><"..entry.playerName, bdlc.sendTo, UnitName("player"));
			bdlc:removeUserConsidering(entry.itemUID, entry.playerName)
		end)
		
		entry.gear1 = CreateFrame("frame", nil, entry)
		entry.gear1:SetSize(20,20);
		entry.gear1:Hide();
		entry.gear1:SetPoint("RIGHT", entry, "RIGHT", -200, 0);
		bdlc:skinBackdrop(entry.gear1, 0, 0, 0, 1)
		
		entry.gear1.tex = entry.gear1:CreateTexture(nil, "OVERLAY")
		entry.gear1.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		entry.gear1.tex:SetDrawLayer('ARTWORK')
		entry.gear1.tex:SetTexture(nil)
		entry.gear1.tex:SetPoint("TOPLEFT", entry.gear1, "TOPLEFT", 2, -2)
		entry.gear1.tex:SetPoint("BOTTOMRIGHT", entry.gear1, "BOTTOMRIGHT", -2, 2)
	
		entry.gear2 = CreateFrame("frame", nil, entry)
		entry.gear2:Hide();
		entry.gear2:SetSize(20,20);
		entry.gear2:SetPoint("RIGHT", entry, "RIGHT", -170, 0);
		bdlc:skinBackdrop(entry.gear2, 0, 0, 0, 1)
		
		entry.gear2.tex = entry.gear2:CreateTexture(nil, "OVERLAY")
		entry.gear2.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		entry.gear2.tex:SetDrawLayer('ARTWORK')
		entry.gear2.tex:SetTexture(nil)
		entry.gear2.tex:SetPoint("TOPLEFT", entry.gear2, "TOPLEFT", 2, -2)
		entry.gear2.tex:SetPoint("BOTTOMRIGHT", entry.gear2, "BOTTOMRIGHT", -2, 2)
		
		entry.votes = CreateFrame('frame', nil, entry)
		entry.votes:SetPoint("RIGHT", entry, "RIGHT", -106, 0);
		entry.votes:SetSize(18, 20)
		entry.votes.text = entry.votes:CreateFontString(nil, "OVERLAY", "BDLC_FONT")
		entry.votes.text:SetText("0");
		entry.votes.text:SetTextColor(1, 1, 1);
		entry.votes.text:SetPoint("CENTER", entry.votes, "CENTER", 0, 0)
		entry.votes:SetScript("OnEnter", function()
			
			if (tonumber(entry.votes.text:GetText()) > 0) then
				ShowUIPanel(GameTooltip)
				GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
				
				
				for k, v in pairs(bdlc.loot_council_votes[entry.itemUID][entry.playerName]) do
					local name, server = strsplit("-", k)
					GameTooltip:AddLine(name, 1, 1, 1)
				end	
				
				GameTooltip:Show()
			end

		end)
		entry.votes:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		--f.voteFrame.tab.entries[e] = entry
		lastframe = entry
		f.entries[i][e] = entry
	end
	
	f.tabs[i] = tab
end
f.tabs[1]:SetAlpha(1)
f.tabs[1].table:Show()