bdItemButtonLib = {}

local s = bdItemButtonLib

local methods = {}
-- methods['SetItem'] = function(self, ItemLink)
-- 	self:SetAttribute("item", ItemLink)
-- end

local total = 0
local function compare_items(self, elapsed) 
	if (not self.itemLink) then return end

	total = total + elapsed
	if (total > 0.1) then
		total = 0
	
		if IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not IsEquippedItem(bdlc:GetItemID(self.itemLink))) then
			GameTooltip_ShowCompareItem()
		end

		if (not IsModifiedClick("COMPAREITEMS") and not GetCVarBool("alwaysCompareItems")) then
			GameTooltip_HideShoppingTooltips(GameTooltip)
		end
	end
end

function s:CreateButton(name, parent)
	local button = CreateFrame("Button", name, parent, BackdropTemplateMixin and "BackdropTemplate")

	button:EnableKeyboard(1)
	button:EnableMouse(1)
	button:RegisterForClicks("LeftButtonUp")

	-- item tooltips
	button:SetScript("OnEnter", function(self)
		if (not self.itemLink) then return end
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(self.itemLink)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self:SetScript("OnUpdate", nil)
	end)

	-- item compare
	button:SetScript("OnUpdate", compare_items)

	-- shift click link
	button:SetScript("OnClick", function(self, button)
		-- if (IsShiftKeyDown()) then
		-- 	local eb = LAST_ACTIVE_CHAT_EDIT_BOX or ChatFrame1EditBox
		-- 	if eb then
		-- 		eb:Show()
		-- 		eb:SetFocus(true)
		-- 	end
		-- end

		SetItemRef(self.itemLink, self.itemLink, button)

		if (self.OnClick) then
			self.OnClick(self, button)
		end
	end)

	return button
end