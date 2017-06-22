local bdlc, l, f = select(2, ...):unpack()

local tts = CreateFrame('GameTooltip', 'BDLC:TooltipScan', UIParent, 'GameTooltipTemplate')
tts:SetOwner(UIParent, 'ANCHOR_NONE')

function bdlc:itemEquippable(itemUID)
	local itemLink = bdlc.itemUID_Map[itemUID]
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local playerClass = select (3, UnitClass("player"))
	local ArmorType = nil
	local classes =
		{
			[1] = {"Warrior", "Plate"},
			[2] = {"Paladin", "Plate"},
			[3] = {"Hunter", "Mail"},
			[4] = {"Rogue", "Leather"},
			[5] = {"Priest", "Cloth"},
			[6] = {"Death Knight", "Plate"},
			[7] = {"Shaman", "Mail"},
			[8] = {"Mage", "Cloth"},
			[9] = {"Warlock", "Cloth"},
			[10] = {"Monk", "Leather"},
			[11] = {"Druid", "Leather"},
			[12] = {"Demon Hunter", "Leather"},
		}
	if class == "Armor" and subclass ~= "Miscellaneous" and subclass ~= "Cosmetic" and equipSlot ~= "INVTYPE_CLOAK" then
		ArmorType = subclass
	else
		bdlc:debug("This is not armor")
		return true
	end
	if ArmorType ~= classes[playerClass][2] then
		bdlc:debug("This item is "..ArmorType..". I am a "..classes[playerClass][1].." I can't use this!!")
		return false
	end
	bdlc:debug("This item is "..ArmorType..". I am a "..classes[playerClass][1].." I can totally use this!!")
	return true
end

function bdlc:IsTier(itemLink)
	local tier_names = {
		[l["tierProtector"]] = true,
		[l["tierConqueror"]] = true,
		[l["tierVanquisher"]] = true
	}

	tts:SetOwner(UIParent, 'ANCHOR_NONE')
	tts:SetHyperlink(itemLink)
	local name = select(1, GetItemInfo(itemLink))
	
	local isTier = false
	for k, v in pairs(tier_names) do
		if (strfind(name:lower(), k:lower())) then isTier = true end
	end
	
	return isTier
end
function bdlc:GetItemValue(itemLink)
	tts:SetOwner(UIParent, 'ANCHOR_NONE')
	tts:SetHyperlink(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue, wf_tf  = string.split(":", itemString)
	
	local ilvl = select(4, GetItemInfo(itemLink))
	local wf_tf = false;
	local socket = tonumber(gem1) and true or false
	local infostr = "";
	
	-- Get Wf/TF
	for i = 1, 4 do
		local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() and _G['BDLC:TooltipScanTextLeft'..i]:GetText():lower() or nil;
		if text then
			wf_tf = wf_tf or text:find(l["itemWarforged"]:lower()) and true or false
			wf_tf = wf_tf or text:find(l["itemTitanforged"]:lower()) and true or false			
		end
	end
	tts:Hide()
	
	if (wf_tf) then
		infostr = "|cff00FF00+"..ilvl.."|r"
	else
		infostr = ilvl;
	end
	if (socket) then
		infostr = infostr.." |cff55AAFFS|r"
	end
	return ilvl, wf_tf, socket, infostr
end

function bdlc:GetItemUID(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return false end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue, wf_tf  = string.split(":", itemString)
	
	gem1 = string.len(gem1) > 0 and gem1 or 0
	bonusID1 = string.len(bonusID1) > 0 and bonusID1 or 0
	bonusID2 = string.len(bonusID2) > 0 and bonusID2 or 0
	upgradeValue = string.len(upgradeValue) > 0 and upgradeValue or 0
	
	return itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue
end

function bdlc:SmartSearch(str,ss)
	local search = {strsplit(" ",ss)} or {ss}
	local found = true
	str = str:lower()
	ss = ss:lower()
	for s = 1, #search do
		if (string.find(str,search[s])) then
			found = true
			break
		end
	end
	return found
end

function bdlc:SmartStrip(str,ss)
	local search = {strsplit(" ",ss)} or {ss}
	str = str:lower()
	orig = str:lower()
	ss = ss:lower()
	for s = 1, #search do
		str = str:gsub(search[s],"")
	end
	str = str:gsub(" ","")

	return str
end

function bdlc:RelicString(str)
	local ss = string.format(RELIC_TOOLTIP_TYPE, "")
	ss = ss:gsub("%W", " ")
	ss = ss:lower()
	str = str:lower()
	
	local search = {strsplit(" ",ss)} or {ss}
	local nummatch = #search
	local matched = 0
	local isrelic = false
	for s = 1, #search do
		if (str:find(search[s])) then
			matched = matched + 1
		end
	end
	if (nummatch == matched) then
		return true
	else
		return false
	end
end

function bdlc:IsRelic(relicLink)
	local isRelic = false
	tts:SetOwner(UIParent, 'ANCHOR_NONE')
	tts:SetHyperlink(relicLink)
	
	local subclass = select(7, GetItemInfo(relicLink))
	if (subclass and bdlc:RelicString(subclass)) then
		isRelic = true
	end
	
	for i = 2, 6 do
		local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() or nil;
		if (text and bdlc:RelicString(text)) then
			isRelic = true
			break
		end
	end
	
	tts:Hide()

	return isRelic
end
function bdlc:GetRelicType(relicLink)
	local relicType
	local ss = EJ_LOOT_SLOT_FILTER_ARTIFACT_RELIC:lower()
	
	tts:SetOwner(UIParent, 'ANCHOR_NONE')
	tts:SetHyperlink(relicLink)
	for i = 2, 6 do
		local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() or nil;
		--[[if (text and string.match(text,l["relicType"]) and not relicType) then
			relicType = string.gsub(text,l["relicType"], "%1")
		end--]]
		--if (not relicType) then -- the regex failed, lets search with localization
		if (text and bdlc:RelicString(text)) then
			local search = {strsplit(" ",ss)} or {ss}
			local str = text:lower()
			for s = 1, #search do
				str = str:gsub(search[s],"")
			end
			str = str:gsub(" ","")
			
			if (strlen(str) > 0) then 
				relicType = str
				break
			end
		end
		--end
	end
	tts:Hide()
		
	return relicType
end

function bdlc:GetRelics(rt)
	SocketInventoryItem(17)
	SocketInventoryItem(16)
	LoadAddOn("Blizzard_ArtifactUI")
	
	local relic1, relic2

	for relicSlotIndex = 1, C_ArtifactUI.GetNumRelicSlots() do
		local lockedReason, relicName, relicIcon, relicLink = C_ArtifactUI.GetRelicInfo(relicSlotIndex);
		
		if (relicLink) then
			local relicType = bdlc:GetRelicType(relicLink)
		
			if (relicType:lower() == rt:lower()) then
				if (not relic1) then
					relic1 = relicLink
				else
					relic2 = relicLink
				end
			end
		end
	end

	HideUIPanel(ArtifactFrame)

	return relic1, relic2
end

function bdlc:inLC()
	return bdlc.loot_council[FetchUnitName("player")] or IsMasterLooter() or not IsInRaid()
end

function IsRaidLeader()
	return UnitLeadsAnyGroup("player")
	--[[local rl = nil
	local num = GetNumGroupMembers()
	local player = UnitName("player")
	for i = 1, num do
		local rank = select(2, GetRaidRosterInfo(i))
		local name = select(1, GetRaidRosterInfo(i))
		if (rank == 2 and name == player) then
			rl = true
			break
		end
	end
	return rl--]]
end

function bdlc:returnEntry(itemUID, playerName)
	playerName = FetchUnitName(playerName)
	local current = nil
	local tab = nil

	for i = 1, #f.tabs do
		if (f.tabs[i].itemUID and f.tabs[i].itemUID == itemUID) then
			tab = i
			
			break
		end
	end
	
	if (tab) then
		for i = 1, #f.entries[tab] do
			if (f.entries[tab][i].playerName == playerName) then
				current = f.entries[tab][i]
				
				break
			end
		end
	end
	
	return current
end

function bdlc:debug(msg)
	if (bdlc.config.debug) then print("|cff3399FFBCLC:|r "..msg) end
end

function bdlc:skinBackdrop(frame, ...)
	if (frame.background) then return false end
	
	local border = {0,0,0,1}
	local color = {...}
	if (not ... ) then
		color = {.11,.15,.18, 1}
		border = {.06, .08, .09, 1}
	end

	frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    frame:SetBackdropColor(unpack(color))
    frame:SetBackdropBorderColor(unpack(border))
	
	return true
end

function bdlc:skinButton(f,small,color)
	local colors = {.1,.1,.1,1}
	local hovercolors = {0,0.55,.85,1}
	if (color == "red") then
		colors = {.6,.1,.1,0.6}
		hovercolors = {.6,.1,.1,1}
	elseif (color == "blue") then
		colors = {0,0.55,.85,0.6}
		hovercolors = {0,0.55,.85,1}
	elseif (color == "dark") then
		colors = {.1,.1,.1,1}
		hovercolors = {.1,.1,.1,1}
	end
	f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, insets = {left=1,top=1,right=1,bottom=1}})
	f:SetBackdropColor(unpack(colors)) 
    f:SetBackdropBorderColor(0,0,0,1)
    f:SetNormalFontObject("bdlc_button")
	f:SetHighlightFontObject("bdlc_button")
	f:SetPushedTextOffset(0,-1)
	
	f:SetSize(f:GetTextWidth()+16,24)
	
	--if (f:GetWidth() < 24) then
	if (small and f:GetWidth() <= 24 ) then
		f:SetWidth(20)
	end
	
	if (small) then
		f:SetHeight(18)
	end
	
	f:HookScript("OnEnter", function(f) 
		f:SetBackdropColor(unpack(hovercolors)) 
	end)
	f:HookScript("OnLeave", function(f) 
		f:SetBackdropColor(unpack(colors)) 
	end)
	
	return true
end

function bdlc:split(str, del)
	local t = {}
	local index = 0;
	while (string.find(str, del)) do
		local s, e = string.find(str, del)
		t[index] = string.sub(str, 1, s-1)
		str = string.sub(str, s+#del)
		index = index + 1;
	end
	table.insert(t, str)
	return t;
end
