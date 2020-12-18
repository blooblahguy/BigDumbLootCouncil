local bdlc, l, f = select(2, ...):unpack()

-- tooltip scanning
local tts = CreateFrame('GameTooltip', 'BDLC:TooltipScan', UIParent, 'GameTooltipTemplate')
tts:SetOwner(UIParent, 'ANCHOR_NONE')

local AceComm = LibStub:GetLibrary("AceComm-3.0")

function bdlc:searchTable(tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- xform r, g, b into rrggbbw 
function bdlc:RGBToHex(r, g, b)
	if type(r) ~= 'number' then
		g = r.g
		b = r.b
		r = r.r
	end
	
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

-- To colorize lootedBy player
function bdlc:prettyName(playerName, returnString)
	local name, server = strsplit("-", playerName)
	local demo_samples = bdlc.demo_samples

	local classFileName = select(2, UnitClass(name)) or select(2, UnitClass(playerName)) or playerClass or demo_samples.classes[math.random(#demo_samples.classes)]
	local color = RAID_CLASS_COLORS[classFileName] or {["r"] = 1, ["g"] = 1, ["b"] = 1}

	--print(color, color.r, color.g, color.b, bdlc:RGBToHex(color))

	if (returnString) then
		return "|cff"..bdlc:RGBToHex(color)..playerName.."|r"
	else
		return color
	end
end

-- return item ID(s) for gear comparison
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
		bdlc.print("Can't find compare for slot: "..equipSlot..". Let the developer know");
	end
	
	return itemLink1, itemLink2
end

-- probably don't need this
function bdlc:CanStartSession(extended)
	local can = false

	-- leads the group, they are the best
	if (IsRaidLeader()) then
		can = true
	end

	-- is solo, let them test away
	if (not IsInGroup()) then
		can = true
	end

	-- let them start sessions if they are in LC and we've passed [extended] = true
	if (extended and bdlc.loot_council[FetchUnitName("player")]) then
		can = true
	end

	return can
end

-- returns name-server for any valid unitID
function FetchUnitName(name)
	local name, server = strsplit("-", name)
	local name_server = false

	if (UnitExists(name) and UnitIsConnected(name)) then
		name_server = GetUnitName(name, true)
	end

	if (name_server) then
		name = name_server
	end
	name, server = strsplit("-", name)
	if (not server) then
		server = GetRealmName()
	end
	
	if (not name) then return end

	return name.."-"..server
end

-- send addon message with paramaters automatically deliminated
function bdlc:sendAction(action, ...)
	local delim = "><"
	local paramString = strjoin(delim, ...)

	-- allow the user to whisper through this function
	local recipient = bdlc.overrideRecipient or UnitName("player")
	local priority = bdlc.overridePriority or "NORMAL"
	local channel = "WHISPER"
	if (IsInRaid() or IsInGroup() or UnitInRaid("player")) then channel = "RAID" end
	channel = bdlc.overrideChannel or channel

	-- merge then send
	local data = action..delim..paramString
	bdlc:debug(bdlc.message_prefix, data, channel, recipient, priority)
	AceComm:SendCommMessage(bdlc.message_prefix, data, channel, recipient, priority)

	-- unset these, probably shouldn't have them in the first place but it works
	bdlc.overrideChannel = nil
	bdlc.overrideRecipient = nil
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
	local itemLink = bdlc.itemMap[itemUID]
	local _, _, _, _, _, _, _, _, equipSlot, _, _, itemClassID, itemSubClassID, bindType = GetItemInfo(itemLink)
	
	if (bindType ~= 1) or (equipSlot == 'INVTYPE_FINGER') or (equipSlot == 'INVTYPE_CLOAK') or (equipSlot == 'INVTYPE_NECK') or (equipSlot == 'INVTYPE_TRINKET') then 
		-- LQE, necks, rings, trinkets and cloaks are always 'usable'
		return true
	end
	
	local playerClass = select(2, UnitClass("player"))
	local classes = {}

	--[[
		[4] = Armor
			Miscellaneous=0, (trinkets/necks/rings filtered above, so the only way to get there are caster offhands)
			Cloth=1,
			Leather=2,
			Mail=3,
			Plate=4,
			Cosmetic=5,
			Shields=6
		
		[2] = Weapons
			One-handed Axes=0, Two-handed Axes=1,
			Bows=2, Guns=3,
			One-handed Maces=4, Two-handed Maces=5,
			Polearms=6,
			One-handed Swords=7, Two-handed Swords=8,
			Warglaives=9,
			Staves=10,
			Fist Weapons=13,
			Miscellaneous=14, ??
			Daggers=15,
			Thrown=16,
			Crossbows=18,
			Wands=19,
			Fishing Poles=20
	--]]
	
	classes["WARRIOR"] = { [2]={0,1,4,5,6,7,8,10,13,14,15,20}, [4]={4,5,6}, }
	classes["PALADIN"] = { [2]={0,1,4,5,6,7,8,14,20}, [4]={0,4,5,6}, }
	classes["HUNTER"] = { [2]={0,1,2,3,6,7,8,10,13,14,15,18,20}, [4]={3,5}, }
	classes["ROGUE"] = { [2]={0,4,7,13,14,15,20}, [4]={2,5}, }
	classes["PRIEST"] = { [2]={4,10,14,15,19,20}, [4]={0,1,5}, }
	classes["DEATHKNIGHT"] = { [2]={0,1,4,5,6,7,8,14,20}, [4]={4,5}, }
	classes["SHAMAN"] = { [2]={0,1,4,5,10,13,14,15,20}, [4]={0,3,5,6}, }
	classes["MAGE"] = { [2]={7,10,14,15,19,20}, [4]={0,1,5}, }
	classes["WARLOCK"] = { [2]={7,10,14,15,19,20}, [4]={0,1,5}, }
	classes["MONK"] = { [2]={0,4,6,7,10,13,14,20}, [4]={0,2,5}, }
	classes["DRUID"] = { [2]={4,5,6,10,13,14,15,20}, [4]={0,2,5}, }
	classes["DEMONHUNTER"] = { [2]={0,7,9,13,14,15,20}, [4]={2,5}, }

	if (classes[playerClass][itemClassID]) then
		if tContains(classes[playerClass][itemClassID], itemSubClassID) then
			return true 
		end
	end
	
	-- print("Experimental: You automatically passed on "..itemLink.." (unusable for your class).")
	return false
end

function bdlc:IsTier(itemLink)
	local isTier = false

	-- tier names
	local tier_names = {
		[l["tierProtector"]] = true,
		[l["tierConqueror"]] = true,
		[l["tierVanquisher"]] = true
	}

	-- store class names
	local classes = {}
	for i = 1, 12 do
		local name, global, index = GetClassInfo(i)
		classes[name] = name
	end

	local tier_classes = {
		-- old
		[1] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Paladin"], classes["Priest"], classes["Warlock"]}, ", ")),
		[2] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Warrior"], classes["Hunter"], classes["Shaman"]}, ", ")),
		[3] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Rogue"], classes["Mage"], classes["Druid"]}, ", ")),
		-- newer
		[4] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Monk"], classes["Warrior"], classes["Hunter"], classes["Shaman"]}, ", ")),
		[5] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Death Knight"], classes["Rogue"], classes["Mage"], classes["Druid"]}, ", ")),
	}

	local weapon_classes = {
		[1] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Death Knight"], classes["Warlock"], classes["Demon Hunter"]}, ", ")),
		[2] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Hunter"], classes["Mage"], classes["Druid"]}, ", ")),
		[3] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Paladin"], classes["Priest"], classes["Shaman"]}, ", ")),
		[4] = string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Monk"], classes["Warrior"], classes["Rogue"]}, ", ")),
	}

	tts:SetOwner(UIParent, 'ANCHOR_NONE')
	tts:SetHyperlink(itemLink)
	local name = select(1, GetItemInfo(itemLink))

	-- scan for class requirements
	for i = 1, tts:NumLines() do
		local line = _G['BDLC:TooltipScanTextLeft'..i]
		local text = line:GetText();

		for k, v in pairs(weapon_classes) do
			if (text == v) then
				isTier = true
			end
		end

		for k, v in pairs(tier_classes) do
			if (text == v) then
				isTier = true
			end
		end
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

-- a hash value is fine here, because we don't actually care whats in the UID, we just need something shorter than a full link
function bdlc:GetItemUID(itemLink, lootedBy)
	-- print(itemLink, lootedBy)
	--[[local text = string.match(itemLink, "item[%-?%d:]+")
	local counter = 1
	local len = string.len(text)
	for i = 1, len, 3 do 
	counter = math.fmod(counter*8161, 4294967279) + 
		(string.byte(text,i)*16776193) +
		((string.byte(text,i+1) or (len-i+256))*8372226) +
		((string.byte(text,i+2) or (len-i+256))*3932164)
	end--]]
	--return math.fmod(counter, 4294967291)

	--print((counter, 4294967291))

	local itemString = string.match(itemLink, "item[%-?%d:]+")
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	return itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue..":"..lootedBy


	--return libc:Compress(itemLink)

	--local itemString = string.match(itemLink, "item[%-?%d:]+")
	--

	--[[local itemString = string.match(itemLink, "item[%-?%d:]+")
	if (not itemString) then return false end
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue, wf_tf  = string.split(":", itemString)
	
	gem1 = string.len(gem1) > 0 and gem1 or 0
	bonusID1 = string.len(bonusID1) > 0 and bonusID1 or 0
	bonusID2 = string.len(bonusID2) > 0 and bonusID2 or 0
	upgradeValue = string.len(upgradeValue) > 0 and upgradeValue or 0
	
	return itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue--]]
end


function bdlc:IsInRaidGroup()
	local inInstance, instanceType = IsInInstance();
	
	if (inInstance and instanceType == "raid") then
		return true;
	end
	return false;
end

-- case insensitive search
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

-- cast insensitive strip
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

function bdlc:TradableTooltip(itemLink)
	local isTradable = false
	local tradableString = BIND_TRADE_TIME_REMAINING:gsub('%%s', '(.+)');

	-- the tooltip for trading actually only shows up on bag tooltips, so we have to do this
	for bag = 0,4 do
		for slot = 1,GetContainerNumSlots(bag) do
			local bagItemLink = GetContainerItemLink(bag,slot);
			
			if (bagItemLink ~= nil and bagItemLink == itemLink) then
				tts:SetOwner(UIParent, 'ANCHOR_NONE')
				tts:SetBagItem(bag, slot)


				for i = 50, 1, -1 do
					local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() or nil;

					if (text and text:match(tradableString)) then
						isTradable = true
						break
					end
				end

				break
			end
		end
	end

	return isTradable
end

-- determines if given string is a relic string
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

-- return relic type (life, iron, blood, etc)
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

function IsRaidLeader()
	local inInstance, instanceType = IsInInstance();
	return inInstance and instanceType == "raid" and UnitIsGroupLeader("player")
end

function bdlc:debug(msg)
	if (bdlc.config.debug) then bdlc.print(msg) end
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
