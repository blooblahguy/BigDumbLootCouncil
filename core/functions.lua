local bdlc, c, l = unpack(select(2, ...))

-- Debug
function bdlc:print(...)
	print("|cffA02C2FBDLC:|r", ...)
end
function bdlc:debug(...)
	if (bdlc.config.debug or bdlc.enabledebug) then
		bdlc:print(...)
	end
end

-- Pixel Perfect
function bdlc:calculate_scale()
	bdlc.scale = 768 / select(2, GetPhysicalScreenSize())
	bdlc.pixel = bdlc.scale / GetCVar("uiScale") or 1
	bdlc.border = bdlc.pixel * 2
end
bdlc:calculate_scale()

function bdlc:get_border(frame)
	local screenheight = select(2, GetPhysicalScreenSize())
	local scale = 768 / screenheight
	local frame_scale = frame:GetEffectiveScale()
	local pixel = scale / frame_scale
	local border = pixel * 2

	return border
end

-- UID hash string
function bdlc:GetItemUID(itemLink, lootedBy)
	lootedBy = lootedBy or ""
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	return itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue..":"..lootedBy
end

-- sort pairs
function bdlc:spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

--=====================================
-- Messages
--=====================================
function bdlc:sendAction(action, ...)
	local delim = bdlc.deliminator
	local paramString = strjoin(delim, ...)

	-- allow the user to whisper through this function
	local recipient = bdlc.overrideRecipient or bdlc:FetchUnitName('player')
	local priority = bdlc.overridePriority or "NORMAL"
	local channel = "WHISPER"
	if (IsInRaid() or IsInGroup() or UnitInRaid("player")) then 
		channel = "RAID"
	end
	channel = bdlc.overrideChannel or channel

	-- merge then send
	local data = action..delim..paramString
	-- bdlc:debug(bdlc.message_prefix, data, channel, recipient, priority)
	bdlc.comm:SendCommMessage(bdlc.messagePrefix, data, channel, recipient, priority)

	-- unset these, probably shouldn't have them in the first place but it works
	bdlc.overrideChannel = nil
	bdlc.overrideRecipient = nil
end

--======================================
-- Media functions
--======================================
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

local function RGBPercToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function bdlc:setBackdrop(frame, r, g, b, a)
	local backdrop = r and {r, g, b, a} or bdlc.media.backdrop
	local r, g, b, a = unpack(backdrop)
	a = a or 1

	local border = bdlc:get_border(frame)

	frame:SetBackdrop({bgFile = bdlc.media.flat, edgeFile = bdlc.media.flat, edgeSize = border})
	frame:SetBackdropColor(r, g, b, a)
	frame:SetBackdropBorderColor(unpack(bdlc.media.border))
end

function bdlc:skinButton(f, small, color)
	local colors = bdlc.media.backdrop
	local hovercolors = bdlc.media.hover
	if (color == "red") then
		colors = {.6, .1, .1, 0.6}
		hovercolors = {.6, .1, .1, 1}
	elseif (color == "blue") then
		colors = {0, 0.55, .85, 0.6}
		hovercolors = {0, 0.55, .85, 1}
	elseif (color == "dark") then
		colors = {.28, .29, .31, 1}
		hovercolors = {0, 0.55, .85, 1}
	end

	f:SetBackdrop({bgFile = bdlc.media.flat, edgeFile = bdlc.media.flat, edgeSize = bdlc.border})
	f:SetBackdropColor(unpack(colors)) 
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f:SetNormalFontObject(bdlc:get_font(14))
	f:SetHighlightFontObject(bdlc:get_font(14))
	f:SetPushedTextOffset(0,-1)
	
	f:SetSize(f:GetTextWidth()+16, 24)
	
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

function bdlc:createScrollFrame(parent)
	local frameHolder;
	
	-- create the frame that will hold all other frames/objects:
	local self = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate") -- re-size this to whatever size you wish your ScrollFrame to be, at this point
	
	-- now create the template Scroll Frame (this frame must be given a name so that it can be looked up via the _G function (you'll see why later on in the code)
	self.scrollframe = self.scrollframe or CreateFrame("ScrollFrame", "BDLC_Scroll", self, "UIPanelScrollFrameTemplate")
	self.scrollchild = self.scrollchild or CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")

	self.position_scroll = function()
		-- all of these objects will need to be re-anchored (if not, they appear outside the frame and about 30 pixels too high)
		self.scrollupbutton:ClearAllPoints();
		self.scrollupbutton:SetPoint("TOPRIGHT", self.scrollframe, "TOPRIGHT", 20, -2);
		self.scrolldownbutton:ClearAllPoints();
		self.scrolldownbutton:SetPoint("BOTTOMRIGHT", self.scrollframe, "BOTTOMRIGHT", 20, 2);
		self.scrollbar:ClearAllPoints();
		self.scrollbar:SetPoint("TOP", self.scrollupbutton, "BOTTOM", 0, -2);
		self.scrollbar:SetPoint("BOTTOM", self.scrolldownbutton, "TOP", 0, 2);
		
		-- now officially set the scrollchild as your Scroll Frame's scrollchild (this also parents self.scrollchild to self.scrollframe)
		-- IT IS IMPORTANT TO ENSURE THAT YOU SET THE SCROLLCHILD'S SIZE AFTER REGISTERING IT AS A SCROLLCHILD:
		self.scrollframe:SetScrollChild(self.scrollchild);
		self.scrollframe:SetAllPoints(self);
	end
	
	-- define the scrollframe's objects/elements:
	local scrollbarName = self.scrollframe:GetName()
	self.scrollbar = _G[scrollbarName.."ScrollBar"];
	self.scrollupbutton = _G[scrollbarName.."ScrollBarScrollUpButton"];
	self.scrolldownbutton = _G[scrollbarName.."ScrollBarScrollDownButton"];

	-- position
	self.position_scroll()
	
	-- now that SetScrollChild has been defined, you are safe to define your scrollchild's size. Would make sense to make it's height > scrollframe's height,
	-- otherwise there's no point having a scrollframe!
	-- note: you may need to define your scrollchild's height later on by calculating the combined height of the content that the scrollchild's child holds.
	-- (see the bit below about showing content).
	self.scrollchild:SetSize(self.scrollframe:GetWidth(), ( self.scrollframe:GetHeight() * 2 ));
	
	-- you need yet another frame which will be used to parent your widgets etc to.  This is the frame which will actually be seen within the Scroll Frame
	-- It is parented to the scrollchild.  I like to think of scrollchild as a sort of 'pin-board' that you can 'pin' a piece of paper to (or take it back off)
	self.content = self.moduleoptions or CreateFrame("Frame", nil, self.scrollchild);
	self.content:SetAllPoints(self.scrollchild);

	-- a good way to immediately demonstrate the new scrollframe in action is to do the following...
	
	-- create a fontstring or a texture or something like that, then place it at the bottom of the frame that holds your info (in this case self.moduleoptions)
	-- self.moduleoptions.fontstring:SetText("This is a test.");
	-- self.moduleoptions.fontstring:SetPoint("BOTTOMLEFT", self.moduleoptions, "BOTTOMLEFT", 20, 60);
	
	-- you should now need to scroll down to see the text "This is a test."
	return self
end

--==============================================
-- Session Functions
--==============================================
local function find_compare(a, b)
	return strfind(a:utf8lower(), b:utf8lower())
end

-- return item ID(s) for gear comparison
function bdlc:fetchUserGear(unit, itemLink)
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local isRelic = bdlc:IsRelic(itemLink)
	local isTier, tierType, usable = bdlc:isTier(itemLink)
	
	if (isTier) then
		if (find_compare(name, l["tierHelm"])) then
			equipSlot = "INVTYPE_HEAD"
		elseif (find_compare(name, l["tierShoulders"])) then
			equipSlot = "INVTYPE_SHOULDER"
		elseif (find_compare(name, l["tierLegs"])) then
			equipSlot = "INVTYPE_LEGS"
		elseif (find_compare(name, l["tierCloak"])) then
			equipSlot = "INVTYPE_BACK"
		elseif (find_compare(name, l["tierChest"])) then
			equipSlot = "INVTYPE_CHEST"
		elseif (find_compare(name, l["tierGloves"])) then
			equipSlot = "INVTYPE_HAND"
		end
	end

	if (tierType == "weapon") then
		equipSlot = "INVTYPE_WEAPONMAINHAND"
	end
	if (tierType == "offhand") then
		equipSlot = "INVTYPE_WEAPONMAINHAND"
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
	if (equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_2HWEAPON" or equipSlot == "INVTYPE_SHIELD" or equipSlot == "INVTYPE_HOLDABLE" or equipSlot == "INVTYPE_RANGEDRIGHT" or equipSlot == "INVTYPE_RANGED" or equipSlot == "INVTYPE_WEAPONMAINHAND" or equipSlot == "INVTYPE_OFFHAND") then
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

function bdlc:GetItemValue(itemLink)
	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")

	local gem1 = select(4, string.split(":", itemString))
	local ilvl = select(4, GetItemInfo(itemLink))
	local wf_tf = false;
	local socket = tonumber(gem1) and true or false
	local infostr = "";
	
	-- Get Wf/TF
	for i = 1, 4 do
		local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() and _G['BDLC:TooltipScanTextLeft'..i]:GetText():utf8lower() or nil;
		if text then
			wf_tf = wf_tf or text:find(l["itemWarforged"]:utf8lower()) and true or false
			wf_tf = wf_tf or text:find(l["itemTitanforged"]:utf8lower()) and true or false			
		end
	end
	bdlc.tt:Hide()
	
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

function bdlc:itemValidForSession(itemLink, lootedBy, test)
	local valid = false

	local itemUID = bdlc:GetItemUID(itemLink, lootedBy)

	-- this session already exists, don't create again
	if (bdlc.loot_sessions[itemUID] == lootedBy and not test) then
		return false
	end

	local isRelic = bdlc:IsRelic(itemLink)
	local isTier, tierType, usable = bdlc:isTier(itemLink)
	local equipSlot = select(9, GetItemInfo(itemLink))

	if (test) then
		bdlc:print(itemLink, "is: ")
		bdlc:print("Tier: ", isTier and "Yes" or "No")
		if (isTier) then
			bdlc:print("Tier Type: ", tierType)
			bdlc:print("Tier Usable: ", usable)
		end
		bdlc:print("Relic: ", isRelic and "Yes" or "No")
		bdlc:print("Equipable: ", (equipSlot and string.len(equipSlot) > 0) and "Yes" or "No")
		bdlc:print("Tradable: ", bdlc:verifyTradability(itemLink) and "Yes" or "No")
	end
	
	if (equipSlot and string.len(equipSlot) > 0) then
		return true
	end
	if (isTier or isRelic) then
		return true
	end
	if (bdlc.forceSession) then
		value = true
		bdlc.forceSession = false
	end

	return valid
end

function bdlc:itemEquippable(itemUID)
	local itemLink = bdlc.itemMap[itemUID]
	-- local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, equipSlot, itemTexture, itemSellPrice = GetItemInfo(itemLink)
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, equipSlot, _, _, itemClassID, itemSubClassID, bindType = GetItemInfo(itemLink)
	
	if (bindType ~= 1) or (equipSlot == 'INVTYPE_FINGER') or (equipSlot == 'INVTYPE_CLOAK') or (equipSlot == 'INVTYPE_NECK') or (equipSlot == 'INVTYPE_TRINKET') then 
		-- LQE, necks, rings, trinkets and cloaks are always 'usable'
		return true
	end

	local isTier, tierType, usable = bdlc:isTier(itemLink)

	if (isTier) then 
		if (usable) then
			return true
		end
	elseif (equipSlot == "") then
		return true
	end
	
	local playerClass = select(2, UnitClass("player"))
	local classes = {}
		
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
	
	bdlc:debug("Experimental: You automatically passed on ", itemLink)
	return false
end

function bdlc:isTier(itemLink)
	local isTier = false
	local tierType = false
	local usable = false

	-- store class names
	local classes = {}
	local myClass = select(1, UnitClass("player"))

	for i = 1, 12 do
		local name, global, index = GetClassInfo(i)
		classes[name] = name
	end

	local tier_classes = {
		-- older
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Paladin"], classes["Rogue"], classes["Shaman"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Warrior"], classes["Priest"], classes["Druid"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Hunter"], classes["Mage"], classes["Warlock"]}, ", ")),
		-- old
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Paladin"], classes["Priest"], classes["Warlock"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Warrior"], classes["Hunter"], classes["Shaman"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Rogue"], classes["Mage"], classes["Druid"]}, ", ")),
		-- newer
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Monk"], classes["Warrior"], classes["Hunter"], classes["Shaman"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Death Knight"], classes["Rogue"], classes["Mage"], classes["Druid"]}, ", ")),
	}

	local weapon_classes = {
		-- main hands
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Death Knight"], classes["Warlock"], classes["Demon Hunter"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Hunter"], classes["Mage"], classes["Druid"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Paladin"], classes["Priest"], classes["Shaman"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Monk"], classes["Warrior"], classes["Rogue"]}, ", ")),
	}
	local offhand_classes = {
		-- offhands
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Paladin"], classes["Monk"], classes["Warrior"], classes["Priest"]}, ", ")),
		string.format(ITEM_CLASSES_ALLOWED, table.concat({classes["Shaman"], classes["Mage"], classes["Warlock"], classes["Druid"]}, ", ")),
	}

	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(itemLink)
	local name = select(1, GetItemInfo(itemLink))

	-- scan for class requirements
	for i = 1, bdlc.tt:NumLines() do
		local line = _G['BDLC:TooltipScanTextLeft'..i]
		local text = line:GetText();

		for k, v in pairs(weapon_classes) do
			if (strfind(text, v) ~= nil) then
				if (strfind(text, myClass) ~= nil) then
					usable = true
				end
				isTier = true
				tierType = "weapon"
				break
			end
		end

		for k, v in pairs(offhand_classes) do
			if (strfind(text, v) ~= nil) then
				if (strfind(text, myClass) ~= nil) then
					usable = true
				end
				isTier = true
				tierType = "offhand"
				break
			end
		end

		for k, v in pairs(tier_classes) do
			if (strfind(text, v) ~= nil) then
				if (strfind(text, myClass) ~= nil) then
					usable = true
				end
				isTier = true
				tierType = "armor"
				break
			end
		end
	end
	
	return isTier, tierType, usable
end

-- determines if given string is a relic string
function bdlc:RelicString(str)
	local ss = string.format(RELIC_TOOLTIP_TYPE, "")
	ss = ss:gsub("%W", " ")
	ss = ss:utf8lower()
	str = str:utf8lower()
	
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
	-- don't run unless its legion
	local version, build, date, tocversion = GetBuildInfo()
	if (tocversion >= 80000 or tocversion < 70000) then return false end

	local isRelic = false
	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(relicLink)
	
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
	
	bdlc.tt:Hide()

	return isRelic
end

-- return relic type (life, iron, blood, etc)
function bdlc:GetRelicType(relicLink)
	local relicType
	local ss = substr(RELIC_TOOLTIP_TYPE, 3):utf8lower()
	
	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(relicLink)
	for i = 2, 6 do
		local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() or nil;
		--[[if (text and string.match(text,l["relicType"]) and not relicType) then
			relicType = string.gsub(text,l["relicType"], "%1")
		end--]]
		--if (not relicType) then -- the regex failed, lets search with localization
		if (text and bdlc:RelicString(text)) then
			local search = {strsplit(" ",ss)} or {ss}
			local str = text:utf8lower()
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
	bdlc.tt:Hide()
		
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
		
			if (relicType:utf8lower() == rt:utf8lower()) then
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

-- Tradability
function bdlc:tradableTooltip(itemLink)
	local isTradable = false
	local tradableString = BIND_TRADE_TIME_REMAINING:format(''):utf8sub(0, -2)

	-- the tooltip for trading actually only shows up on bag tooltips, so we have to do this
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local bagItemLink = GetContainerItemLink(bag,slot);
			
			if (bagItemLink and bagItemLink == itemLink) then
				bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
				bdlc.tt:SetBagItem(bag, slot)

				for i = 50, 1, -1 do
					local text = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() or nil;

					if (text and string.find(text, tradableString) ~= nil) then
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

function bdlc:verifyTradability(itemLink)
	if (GetItemInfo(itemLink)) then
		if (bdlc:tradableTooltip(itemLink)) then
			return true
		end
	else
		local itemID = bdlc:getItemID(itemLink)
		bdlc.items_waiting_for_verify[itemID] = itemLink
		local name = GetItemInfo(itemLink)
	end
end


--==============================================
-- User functions
--==============================================
function bdlc:IsRaidLeader()
	local inInstance, instanceType = IsInInstance();
	if (inInstance and instanceType == "raid" and UnitIsGroupLeader("player")) then
		return true
	else
		return UnitIsGroupLeader("player") or not IsInGroup()
	end
end

function bdlc:IsInRaid()
	local inInstance, instanceType = IsInInstance();
	
	if (inInstance and instanceType == "raid") then
		return true;
	end
	return false;
end

function bdlc:capitalize(str)
	return str:gsub("^%l", string.utf8upper)
end

-- returns a nice readable format
function bdlc:unitName(str)
	local name, server = strsplit("-", str)

	return bdlc:capitalize(name)
end

-- To colorize lootedBy player
function bdlc:prettyName(playerName)
	local name = bdlc:unitName(playerName)

	local classFileName = select(2, UnitClass(name)) or select(2, UnitClass(playerName)) or playerClass or bdlc.demo_samples.classes[math.random(#bdlc.demo_samples.classes)]
	local color = RAID_CLASS_COLORS[classFileName] or {["r"] = 1, ["g"] = 1, ["b"] = 1}

	return "|cff"..bdlc:RGBToHex(color)..name.."|r", color
end

-- returns name-server for any valid name or unit
function bdlc:FetchUnitName(name)
	-- remove server
	local splitName, splitRealm = strsplit("-", name)
	
	-- check if we have a unit without the realm, then with the realm
	local fullName, realm = UnitFullName(splitName) or UnitFullName(name)
	realm = realm or GetRealmName()
	
	-- if no unit is found, just return their name
	if (not fullName) then return (splitName.."-"..realm):utf8lower() end
	
	-- we always insure realm
	fullName = (fullName.."-"..realm):utf8lower()

	-- for consistency
	return Ambiguate(fullName, "mail")
end