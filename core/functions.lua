local bdlc, c, l = unpack(select(2, ...))

local _GetContainerNumSlots = GetContainerNumSlots or C_Container.GetContainerNumSlots
local _GetContainerItemInfo = GetContainerItemInfo or C_Container.GetContainerItemInfo
local _GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container.GetContainerNumFreeSlots

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
function bdlc:GetItemID(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	return itemID
end

function bdlc:GetItemUID(itemLink, lootedBy, rollID)
	lootedBy = lootedBy and bdlc:FetchUnitName(lootedBy) or ""
	local itemString = string.match(itemLink, "item[%-?%d:]+")

	if (not itemString) then 
		bdlc:debug(itemLink.." isn't actually an item. Please report this to the developer")
		return false -- this never ever happens?
	end

	local itemType, itemID, enchant, gem1, gem2, gem3, gem4, suffixID, uniqueID, level, specializationID, upgradeId, instanceDifficultyID, numBonusIDs, bonusID1, bonusID2, upgradeValue = strsplit(":", itemString)

	return itemID..":"..gem1..":"..bonusID1..":"..bonusID2..":"..upgradeValue..":"..lootedBy..":"..rollID
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
	bdlc.overridePriority = nil
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

function bdlc:RGBPercToHex(r, g, b)
	if (type(r) == "table") then
		g = r.g
		b = r.b
		r = r.r
	end
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
    f:SetNormalFontObject(bdlc:get_font(14, "OUTLINE"))
	f:SetHighlightFontObject(bdlc:get_font(14, "OUTLINE"))
	f:SetPushedTextOffset(0,-1)
	
	f:SetSize(f:GetTextWidth()+16, 24)

	if (small) then
		f:SetNormalFontObject(bdlc:get_font(11, "OUTLINE"))
		f:SetHighlightFontObject(bdlc:get_font(11, "OUTLINE"))
	end
	
	--if (f:GetWidth() < 24) then
	if (small and f:GetWidth() <= 24 ) then
		f:SetWidth(20)
	end
	
	if (small) then
		f:SetHeight(18)
	end
	
	function f:select()
		if (f.selected) then return end
		f.selected = true
		f.tcolor = {f:GetRegions():GetTextColor()}
		
		f:SetBackdropColor(unpack(f.tcolor))
		f:GetRegions():SetTextColor(1, 1, 1)
		f:GetRegions():SetShadowColor(1, 1, 1)
	end
	function f:unselect()
		f.selected = false
		f.tcolor = f.tcolor or {f:GetRegions():GetTextColor()}
		
		f:SetBackdropColor(unpack(colors))
		f:GetRegions():SetTextColor(unpack(f.tcolor))
		f:GetRegions():SetShadowColor(0, 0, 0)
	end
	
	if (not f.bdlchooked) then
		f:HookScript("OnEnter", function(f)
			if (f.selected) then return end
			f:SetBackdropColor(unpack(hovercolors)) 
		end)
		f:HookScript("OnLeave", function(f)
			if (f.selected) then return end
			f:SetBackdropColor(unpack(colors)) 
		end)

		f.bdlchooked = true
	end
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
local function find_compare(itemLink, search)
	search = search:utf8lower() -- match these cases

	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")
	
	local num_lines = bdlc.tt:NumLines(true)
	for i = 1, num_lines do
		local line = _G['BDLC:TooltipScanTextLeft'..i] and _G['BDLC:TooltipScanTextLeft'..i]:GetText() and _G['BDLC:TooltipScanTextLeft'..i]:GetText():utf8lower() or nil;
		if not line then break end

		-- found it
		if (strfind(line, search) ~= nil) then return true end
	end

	bdlc.tt:Hide()

	return false
end

-- return item ID(s) for gear comparison
function bdlc:fetchUserGear(unit, itemLink)
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	-- local isRelic = bdlc:IsRelic(itemLink)
	local isTier, tierType, usable = bdlc:isTier(itemLink)

	if (isTier) then
		if (find_compare(itemLink, l["tierHelm"])) then
			equipSlot = "INVTYPE_HEAD"
		elseif (find_compare(itemLink, l["tierShoulders"]) or find_compare(itemLink, l["tierShoulders2"])) then
			equipSlot = "INVTYPE_SHOULDER"
		elseif (find_compare(itemLink, l["tierLegs"]) or find_compare(itemLink, l["tierLegs2"])) then
			equipSlot = "INVTYPE_LEGS"
		elseif (find_compare(itemLink, l["tierCloak"])) then
			equipSlot = "INVTYPE_BACK"
		elseif (find_compare(itemLink, l["tierChest"])) then
			equipSlot = "INVTYPE_CHEST"
		elseif (find_compare(itemLink, l["tierGloves"]) or find_compare(itemLink, l["tierGloves2"])) then
			equipSlot = "INVTYPE_HAND"
		elseif (find_compare(itemLink, l["tierBelt"])) then
			equipSlot = "INVTYPE_WAIST"
		end
	end

	if (isTier and tierType == "weapon") then
		equipSlot = "INVTYPE_WEAPONMAINHAND"
	end
	if (isTier and tierType == "offhand") then
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
	-- if (isRelic) then
	-- 	local relicType = bdlc:GetRelicType(itemLink)
	-- 	local relic1, relic2 = bdlc:GetRelics(relicType)
		
	-- 	if (relic1) then
	-- 		itemLink1 = relic1
	-- 	end
	-- 	if (relic2) then
	-- 		itemLink2 = relic2
	-- 	end
	-- end
	if (not itemLink1) then
		itemLink1 = 0
	end
	if (not itemLink2) then
		itemLink2 = 0
	end
	
	-- if (slotID == 0 and not isRelic) then
	if (slotID == 0) then
		bdlc:print("Can't find compare for "..itemLink..". Let the developer know");
	end
	
	return itemLink1, itemLink2
end

function bdlc:GetItemValue(itemLink)
	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(itemLink)
	local itemString = string.match(itemLink, "item[%-?%d:]+")

	local gem1 = select(4, string.split(":", itemString))
	local ilvl = GetDetailedItemLevelInfo(itemLink) --select(4, GetItemInfo(itemLink))
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

function bdlc:itemValidForSession(itemLink, lootedBy, test, rollID)
	lootedBy = lootedBy and bdlc:FetchUnitName(lootedBy) or ""
	local valid = false

	local itemUID = bdlc:GetItemUID(itemLink, lootedBy, rollID)

	-- this session already exists, don't create again
	if (bdlc.loot_sessions[itemUID] == lootedBy and not test) then
		bdlc:debug("Session already exists for this item")
		return false
	end

	-- local isRelic = bdlc:IsRelic(itemLink)
	local isTier, tierType, usable = bdlc:isTier(itemLink)
	local equipSlot = select(9, GetItemInfo(itemLink))

	-- send back some debug information
	if (test) then
		bdlc:print(itemLink, "is: ")
		bdlc:print("Tier: ", isTier and "Yes" or "No")
		if (isTier) then
			bdlc:print("Tier Type: ", tierType)
			bdlc:print("Tier Usable: ", usable)
		end
		-- bdlc:print("Relic: ", isRelic and "Yes" or "No")
		bdlc:print("Equipable: ", ((equipSlot or usable) and string.len(equipSlot or usable) > 0) and "Yes" or "No")
		bdlc:print("Equip Slot: ", ((equipSlot or usable) and string.len(equipSlot or usable) > 0) and equipSlot or tierType)
		bdlc:print("Tradable: ", bdlc:verifyTradability(itemLink) and "Yes" or "No")
	end
	
	if (equipSlot and string.len(equipSlot) > 0) then
		return true
	end
	if (isTier) then
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
	classes["EVOKER"] = { [2]={0,1,4,5,7,8,10,13,14,15,20}, [4]={0,1,2,3,5}, }
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
	
	bdlc:print("Experimental: You automatically passed on ", itemLink)
	return false
end

function bdlc:isTier(itemLink)
	local isTier = false
	local tierType = false
	local usable = false

	-- store class names
	local classes = {}
	local myClass = select(1, UnitClass("player")):lower()
	local myClassGlobal = select(2, UnitClass("player")):lower()

	-- check demon hunter before hunter
	local order = {1, 2, 12, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13}

	-- global to local map
	for i = 1, 13 do
		local name, global, index = GetClassInfo(i)
		classes[global:lower()] = name:lower()
	end

	-- ensure globals for us at least
	ITEM_CLASSES_ALLOWED = ITEM_CLASSES_ALLOWED or "Classes: %s"
	WEAPON = WEAPON or "Weapon"
	SHIELDSLOT = SHIELDSLOT or "Shield"
	INVTYPE_WEAPONOFFHAND = INVTYPE_WEAPONOFFHAND or "Off hand"
	
	local tier_string = string.utf8sub(ITEM_CLASSES_ALLOWED, 0, -3):lower()
	bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
	bdlc.tt:SetHyperlink(itemLink)
	local name = select(1, GetItemInfo(itemLink))

	-- check tier type first
	for i = 1, 150 do
		local line = _G['BDLC:TooltipScanTextLeft'..i]
		local text = line and line:GetText() and line:GetText():lower()

		if (not text) then break end

		-- is a weapon
		if (strfind(text, WEAPON:lower()) ~= nil) then
			tierType = "weapon"
		end

		-- is an offhand/shield
		local offhand_str = gsub(INVTYPE_WEAPONOFFHAND:lower(), " ", "")
		if (strfind(text, SHIELDSLOT:lower()) ~= nil or strfind(text, offhand_str) ~= nil) then
			tierType = "offhand"
		end
	end

	-- next check for class so we can break and not double match
	for i = 1, 150 do
		local line = _G['BDLC:TooltipScanTextLeft'..i]
		local text = line and line:GetText() and line:GetText():lower()

		if (not text) then break end

		-- check if it's "Classes: "
		if (strfind(text, tier_string) ~= nil) then
			-- hutner / demon hunter weirdness
			if (myClassGlobal == "hunter") then
				-- found "hunter"
				if (strfind(text, myClass) ~= nil) then
					-- did not find "demon hunter"
					if (strfind(text, classes["demonhunter"]) == nil) then
						usable = true
					end
				end
			else
				-- for everyone else
				if (strfind(text, myClass) ~= nil) then
					usable = true
				end
			end

			isTier = true

			break
		end
	end

	if (isTier and tierType == false) then
		tierType = "armor"
	end

	tierType = isTier and tierType or false
	
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

--================================================
-- Trading
--================================================
function bdlc:populate_trade_window(itemLink1)
	local itemLink1 = bdlc:GetItemUID(itemLink1, false, -1)
	if (not _G.TradeFrame:IsShown()) then return end

	-- find in bags
	for bag = 0, 4 do
		for slot = 1, _GetContainerNumSlots(bag) do
			local bagItemLink = select(7, GetContainerItemInfo(bag, slot))

			-- local bagUID = bagItemLink and bdlc:GetItemUID(bagItemLink, false, -1) or false
			-- local itemUID = bdlc:GetItemUID(itemLink, false, -1)
			if (bagItemLink) then
				local itemLink2 = bdlc:GetItemUID(bagItemLink, false, -1)
				
				if (itemLink2 and itemLink1 == itemLink2) then
					-- we've matched our tradeable item, put it in the trade window
					-- ClearCursor()
					-- C_Container.PickupContainerItem(bag, slot)
					UseContainerItem(bag, slot)
				end
			end
		end
	end

	-- move to trade window
end

-- Tradability
function bdlc:tradableTooltip(itemLink)
	local isTradable = false
	local tradableString = BIND_TRADE_TIME_REMAINING:utf8sub(0, 24):lower()
	local sellableString = REFUND_TIME_REMAINING:utf8sub(0, 24):lower() -- for testing

	-- the tooltip for trading actually only shows up on bag tooltips, so we have to do this
	for bag = 0, 4 do
		for slot = 1, _GetContainerNumSlots(bag) do
			local bagItemLink = select(7, GetContainerItemInfo(bag, slot))

			local bagUID = bagItemLink and bdlc:GetItemUID(bagItemLink, false, -1) or false
			local itemUID = bdlc:GetItemUID(itemLink, false, -1)
			
			if (bagUID and bagUID == itemUID) then
				bdlc.tt:SetOwner(UIParent, 'ANCHOR_NONE')
				bdlc.tt:SetBagItem(bag, slot)

				for i = 1, 150 do
					local line = _G['BDLC:TooltipScanTextLeft'..i]
					local text = line and line:GetText() and line:GetText():lower()

					if (not text) then break end

					if (string.find(text, tradableString) ~= nil or (bdlc.enableTests and string.find(text, sellableString) ~= nil)) then
						isTradable = true
						break
					end
				end

			end
		end
	end

	return isTradable
end

function bdlc:verifyTradability(itemLink)
	if (GetItemInfo(itemLink)) then
		bdlc:debug("checking if item is tradable", itemLink)
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
	return (IsInRaid() and UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME)) or not IsInGroup()
end

function bdlc:IsInRaidInstance()
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

	return bdlc:capitalize(Ambiguate(name, "short"))
end

-- To colorize lootedBy player
function bdlc:prettyName(playerName)
	local name = bdlc:unitName(playerName)

	local classFileName = select(2, UnitClass(name)) or select(2, UnitClass(playerName)) or playerClass or bdlc.demo_samples.classes[math.random(#bdlc.demo_samples.classes)]
	local color = RAID_CLASS_COLORS[classFileName] or {["r"] = 1, ["g"] = 1, ["b"] = 1}

	return "|cff"..bdlc:RGBToHex(color)..name.."|r", color
end


-- returns name-server for any valid name or unit
function bdlc:FetchUnitName(name_string)
	-- check that this user actually exists
	if (not UnitExists(name_string)) then return name_string:utf8lower() end

	-- handle if "player" or "target" was passed in
	if (name_string == "player" or name_string == "target" or strfind(name_string, "raid") ~= nil or strfind(name_string, "party") ~= nil) then
		local name, realm = strsplit("-", name_string)
		name = UnitName(name_string)
		name_string = realm and name.."-"..realm or name
	end

	-- check if we included a server, trying both
	local name = Ambiguate(name_string, "mail")
	local name2 = GetUnitName(name_string, true)

	-- separate name-server
	local name, realm = strsplit("-", name) -- this should be fine if realm name came in
	local name2, realm2 = name2 and strsplit("-", name2) -- this will populate if user isn't on your same server
	name = name and name or name2
	realm = realm and realm or realm2
	realm = realm and realm or GetRealmName() -- if they're on our server, and didn't include their server, then we use ours
	
	-- we always ensure realm
	name = name.."-"..realm

	-- for consistency juuuust in case
	return Ambiguate(name, "mail"):utf8lower()
end


function GetQuadrant(frame)
	local x,y = frame:GetCenter()
	local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, vhalf, hhalf
end