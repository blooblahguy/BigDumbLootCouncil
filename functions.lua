local bdlc, l, f = select(2, ...):unpack()
local libc = LibStub:GetLibrary("LibCompress")

local tts = CreateFrame('GameTooltip', 'BDLC:TooltipScan', UIParent, 'GameTooltipTemplate')
tts:SetOwner(UIParent, 'ANCHOR_NONE')

function bdlc:sendAction(action, ...)
	local parameters = {...}
	local paramString = ""
	local delim = "\t"

	print("predata:", ...)
	for k, v in pairs(parameters) do
		paramString = paramString..delim..v
	end
	print("postdata:",paramString)

	-- allow the user to whisper through this function
	local channel = bdlc.sendTo
	local sender = UnitName("player")
	if (bdlc.overrideChannel) then channel = bdlc.overrideChannel end
	if (bdlc.overrideSender) then sender = bdlc.overrideSender end

	-- compress then send
	local data = libc:Compress(action..delim..paramString)
	SendAddonMessage(bdlc.message_prefix, data, channel, sender;

	-- unset these, probably shouldn't have them in the first place but it works
	bdlc.overrideChannel = nil
	bdlc.overrideSender = nil
end

local function searchArray(arr, val)
	for k, v in pairs(arr) do
		if (v == val) then 
			return true
		end
	end
	return false
end

function bdlc:itemEquippable(itemUID)
	return true
end
function bdlc:itemEquippable2(itemUID)
	-- this feature isn't localized
	if (GetLocale() ~= "enUS" and GetLocale() ~= "enGB") then return true end

	local itemLink = bdlc.itemUID_Map[itemUID]
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local playerClass = select(2, UnitClass("player"))
	local armorType = nil
	local classes = {}
	
	classes["WARRIOR"] = {}
	classes["WARRIOR"].armor = "Plate"
	classes["WARRIOR"].tier = l["tierProtector"]
	classes["WARRIOR"].relics = {"Iron", "Blood", "Shadow", "Fire", "Storm"}
	
	classes["PALADIN"] = {}
	classes["PALADIN"].armor = "Plate"
	classes["PALADIN"].tier = l["tierConqueror"]
	classes["PALADIN"].relics = {"Life", "Holy", "Iron", "Fire", "Arcane"}
	
	classes["HUNTER"] = {}
	classes["HUNTER"].armor = "Mail"
	classes["HUNTER"].tier = l["tierProtector"]
	classes["HUNTER"].relics = {"Storm", "Arcane", "Blood", "Iron", "Life"}
	
	classes["ROGUE"] = {}
	classes["ROGUE"].armor = "Leather"
	classes["ROGUE"].tier = l["tierVanquisher"]
	classes["ROGUE"].relics = {"Shadow", "Blood", "Fel", "Iron", "Storm", "Fel"}
	
	classes["PRIEST"] = {}
	classes["PRIEST"].armor = "Cloth"
	classes["PRIEST"].tier =l["tierConqueror"]
	classes["PRIEST"].relics = {"Holy", "Shadow", "Blood", "Life"}
	
	classes["DEATHKNIGHT"] = {}
	classes["DEATHKNIGHT"].armor = "Plate"
	classes["DEATHKNIGHT"].tier = l["tierVanquisher"]
	classes["DEATHKNIGHT"].relics = {"Blood", "Frost", "Fire", "Shadow", "Iron"}
	
	classes["SHAMAN"] = {}
	classes["SHAMAN"].armor = "Mail"
	classes["SHAMAN"].tier = l["tierProtector"]
	classes["SHAMAN"].relics = {"Storm", "Fire", "Life", "Frost", "Iron"}
	
	classes["MAGE"] = {}
	classes["MAGE"].armor = "Cloth"
	classes["MAGE"].tier = l["tierVanquisher"]
	classes["MAGE"].relics = {"Arcane", "Fire", "Frost"}
	
	classes["WARLOCK"] = {}
	classes["WARLOCK"].armor = "Cloth"
	classes["WARLOCK"].tier = l["tierConqueror"]
	classes["WARLOCK"].relics = {"Shadow", "Fel", "Blood", "Fire"}
	
	classes["MONK"] = {}
	classes["MONK"].armor = "Leather"
	classes["MONK"].tier = l["tierProtector"]
	classes["MONK"].relics = {"Life", "Frost", "Storm", "Iron"}
	
	classes["DRUID"] = {}
	classes["DRUID"].armor = "Leather"
	classes["DRUID"].tier = l["tierVanquisher"]
	classes["DRUID"].relics = {"Arcane", "Frost", "Fire", "Life", "Blood"}
	
	classes["DEMONHUNTER"] = {}
	classes["DEMONHUNTER"].armor = "Leather"
	classes["DEMONHUNTER"].tier = l["tierConqueror"]
	classes["DEMONHUNTER"].relics = {"Fel", "Iron", "Shadow", "Arcane"}
	
	local myClass = classes[playerClass]
	
	if (class == "Armor" and subclass ~= "Miscellaneous" and subclass ~= "Cosmetic" and equipSlot ~= "INVTYPE_CLOAK") then
		armorType = subclass
	elseif (bdlc:IsRelic(itemLink)) then
		local relicType = bdlc:GetRelicType(itemLink)
		
		if (searchArray(myClass.relics, relicType)) then
			bdlc:debug("This item is "..relicType..". I am a "..playerClass.." I can use this!")
			return true
		else
			return false
		end
	elseif (bdlc:IsTier(itemLink)) then
			bdlc:debug("This item is tier. I am tier "..myClass.tier.." I can use this!")
		if (string.find(itemLink, myClass.tier)) then
			return true
		else
			return false
		end
	else
		bdlc:debug("This is not armor")
		return true
	end
	
	if (armorType ~= myClass.armor) then
		bdlc:debug("This item is "..armorType..". I am a "..playerClass.." I can't use this!!")
		return false
	end
	
	bdlc:debug("This item is "..armorType..". I am a "..playerClass.." I can totally use this!!")
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

	local gem1 = select(4, string.split(":", itemString))
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
	return libc:Compress(itemLink)

	--[[local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return false end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue, wf_tf  = string.split(":", itemString)
	
	gem1 = string.len(gem1) > 0 and gem1 or 0
	bonusID1 = string.len(bonusID1) > 0 and bonusID1 or 0
	bonusID2 = string.len(bonusID2) > 0 and bonusID2 or 0
	upgradeValue = string.len(upgradeValue) > 0 and upgradeValue or 0
	
	return itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue--]]
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
