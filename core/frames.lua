local bdlc, c, l = unpack(select(2, ...))

--======================================
-- Fonts
--======================================
bdlc.fonts = {}
-- dynamic font creation/fetching
function bdlc:get_font(size, outline)
	outline = outline or ""
	local name = size.."_"..outline
	
	if (not bdlc.fonts[name]) then
		local font = CreateFont("BDLC_"..name)
		font:SetFont(bdlc.media.font, tonumber(size), outline)
		if (outline == "") then
			font:SetShadowColor(0, 0, 0)
			font:SetShadowOffset(1, -1)
		else
			font:SetShadowColor(0, 0, 0)
			font:SetShadowOffset(0, 0)
		end

		bdlc.fonts[name] = font
	end

	return bdlc.fonts[name]
end

--======================================
-- Reposition Frames
--======================================
function bdlc:repositionFrames()
	-- tabs
	local lasttab = nil
	for tab, v in bdlc.tabs:EnumerateActive() do
		-- order entries and loop through them
		local lastentry = false
		for entry, v in bdlc:spairs(tab.entries.activeObjects, function(a, b)
			a.wantLevel = a.wantLevel or 0
			b.wantLevel = b.wantLevel or 0
			if a.wantLevel ~= b.wantLevel then
				return a.wantLevel < b.wantLevel
			end
			if a.rankIndex ~= b.rankIndex then
				return a.rankIndex < b.rankIndex
			end
			if a.myilvl ~= b.myilvl then
				return a.myilvl > b.myilvl
			end
			
			return a.name.text:GetText() > b.name.text:GetText()
		end) do
			entry:ClearAllPoints()
			if (entry.itemUID and entry:IsShown()) then
				if (lastentry) then
					entry:SetPoint("TOPLEFT", lastentry, "BOTTOMLEFT", 0, 0)
				else
					entry:SetPoint("TOPLEFT", tab.table.content, "TOPLEFT", bdlc.border, 0)
				end
				lastentry = entry
			end
		end

		-- position tabs
		if (tab.itemUID and tab:IsShown()) then
			if (lasttab) then
				tab:SetPoint("TOPRIGHT", lasttab, "BOTTOMRIGHT", 0, bdlc.border)
			else
				tab:SetPoint("TOPRIGHT", bdlc.window.tabs, "TOPRIGHT", bdlc.border, 0)
			end
			lasttab = tab
		end
	end	
	if (not lasttab) then
		bdlc.window:Hide()
	end

	-- rolls
	local lastroll = nil
	for roll, v in bdlc.rolls:EnumerateActive() do
		if (roll.itemUID) then
			if (lastroll) then
				roll:SetPoint("TOPLEFT", lastroll, "BOTTOMLEFT", 0, bdlc.border)
			else
				roll:SetPoint("TOPLEFT", bdlc.rollFrame, "TOPLEFT", 0, 0)
			end
			lastroll = roll
		end
	end
	if (lastroll) then
		bdlc.rollFrame:Show()
	else
		bdlc.rollFrame:Hide()
	end

	-- find out which tab is selected and make it fancy
	local tabselect = nil
	for tab, v in bdlc.tabs:EnumerateActive() do
		if (tab:GetAlpha() == 1) then
			tabselect = true
			tab.selected = true
			tab.icon:SetDesaturated(false)
		else
			tab.selected = false
			tab.icon:SetDesaturated(true)
		end
	end
	
	-- if no tab is selected, select the first tab
	if (not tabselect) then
		for tab, v in bdlc.tabs:EnumerateActive() do
			if (tab.itemUID) then
				tab:SetAlpha(1)
				tab.selected = true
				tab.table:Show()
				tab.icon:SetDesaturated(false)
				
				break
			end
		end
	end
end

function bdlc:getTab(itemUID)
	local current_tab = false

	for tab, v in bdlc.tabs:EnumerateActive() do
		if (tab.itemUID == itemUID) then
			current_tab = tab

			break
		end
	end

	if (not current_tab) then
		current_tab = bdlc.tabs:Acquire()
	end

	return current_tab
end

function bdlc:getEntry(itemUID, playerName)
	local current_entry = false

	for tab, v in bdlc.tabs:EnumerateActive() do
		if (tab.itemUID == itemUID) then
			-- entries
			for entry, k in tab.entries:EnumerateActive() do
				if (entry.playerName == playerName) then
					current_entry = entry
					break
				end
			end

			if (not current_entry) then
				current_entry = tab.entries:Acquire()
			end
		end
	end

	if (not current_entry) then return end

	current_entry.playerName = playerName
	current_entry.itemUID = itemUID

	return current_entry
end


function bdlc:getRoll(itemUID)
	for roll, v in bdlc.rolls:EnumerateActive() do
		if (roll.itemUID == itemUID) then
			return roll
		end
	end
end

--======================================
-- Object Pools
--======================================

-- tabs
local tab_i = 0
local function create_tab(self)
	tab_i = tab_i + 1

	local tab = CreateFrame('button', nil, bdlc.window.tabs, BackdropTemplateMixin and "BackdropTemplate")

	tab.selected = false
	tab:Hide()
	tab:SetSize(40, 40)
	tab:SetPoint("TOPRIGHT", tabs, "TOPRIGHT", 2, 0)
	tab:SetAlpha(0.3)
	tab:EnableMouse(1)
	bdlc:setBackdrop(tab, .1,.1,.1,.8);
	tab:SetScript("OnClick", function(self, b)
		if (b == "LeftButton") then
			for other_tab, v in bdlc.tabs:EnumerateActive() do
				other_tab:SetAlpha(0.3)
				other_tab.table:Hide()
				other_tab.table.info_pane:Hide()
				other_tab.icon:SetDesaturated(true)
				other_tab.selected = false
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
	tab.icon:SetPoint("TOPLEFT", tab, "TOPLEFT", bdlc.border, -bdlc.border)
	tab.icon:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -bdlc.border, bdlc.border)
	
	tab.wfsock = tab:CreateFontString(nil, "ARTWORK")
	tab.wfsock:SetFontObject(bdlc:get_font(15, "OUTLINE"))
	tab.wfsock:SetText("")
	tab.wfsock:SetTextColor(1, 1, 1)
	tab.wfsock:SetPoint("CENTER", tab, "CENTER", 0, 0)
	tab.wfsock:SetJustifyH("CENTER")
	
	--parent frame 
	local vote_table = CreateFrame("Frame", nil, tab, BackdropTemplateMixin and "BackdropTemplate") 
	vote_table:SetPoint("TOPLEFT", bdlc.window, "TOPLEFT", 10, -100)
	vote_table:SetPoint("BOTTOMRIGHT", bdlc.window, "BOTTOMRIGHT", -30, 30)
	vote_table:Hide()
	bdlc:setBackdrop(vote_table, .1, .1, .1, .8);
	tab.table = vote_table

	local content = bdlc:createScrollFrame(vote_table)
	content.scrollframe:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 0, -4);
	content.scrollframe:SetPoint("BOTTOMRIGHT", vote_table, "BOTTOMRIGHT", 0, 4);
	content.scrollchild:SetSize(content.scrollframe:GetWidth(), (content.scrollframe:GetHeight() * 1.5 ));
	vote_table.content = content.content
	bdlc:setBackdrop(content, .1, .2, .1, .8);
	
	-- Headers
	vote_table.name_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.name_text:SetFontObject(bdlc:get_font(14))
	vote_table.name_text:SetText(l["frameName"]);
	vote_table.name_text:SetTextColor(1, 1, 1);
	vote_table.name_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 10, 16)
	
	vote_table.rank_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.rank_text:SetFontObject(bdlc:get_font(14))
	vote_table.rank_text:SetText(l["frameRank"]);
	vote_table.rank_text:SetTextColor(1, 1, 1);
	vote_table.rank_text:SetPoint("LEFT", vote_table.name_text, "RIGHT", 40, 0)
	
	vote_table.ilvl_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.ilvl_text:SetFontObject(bdlc:get_font(14))
	vote_table.ilvl_text:SetText(l["frameIlvl"]);
	vote_table.ilvl_text:SetTextColor(1, 1, 1);
	vote_table.ilvl_text:SetPoint("LEFT", vote_table.rank_text, "RIGHT", 60, 0)
	
	vote_table.interest = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.interest:SetFontObject(bdlc:get_font(14))
	vote_table.interest:SetText(l["frameInterest"]);
	vote_table.interest:SetTextColor(1, 1, 1);
	vote_table.interest:SetPoint("LEFT", vote_table.ilvl_text, "RIGHT", 26, 0)
	
	vote_table.notes_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.notes_text:SetFontObject(bdlc:get_font(14))
	vote_table.notes_text:SetText(l["frameNotes"]);
	vote_table.notes_text:SetTextColor(1, 1, 1);
	vote_table.notes_text:SetPoint("LEFT", vote_table.interest, "RIGHT", 30, 0)
	
	vote_table.current_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.current_text:SetFontObject(bdlc:get_font(14))
	vote_table.current_text:SetText(l["frameCurrentGear"]);
	vote_table.current_text:SetTextColor(1, 1, 1);
	vote_table.current_text:SetPoint("LEFT", vote_table.notes_text, "RIGHT", 26, 0)
	
	vote_table.votes_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.votes_text:SetFontObject(bdlc:get_font(14))
	vote_table.votes_text:SetText(l["frameVotes"]);
	vote_table.votes_text:SetTextColor(1, 1, 1);
	vote_table.votes_text:SetPoint("LEFT", vote_table.current_text, "RIGHT", 30, 0)
	
	vote_table.actions_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.actions_text:SetFontObject(bdlc:get_font(14))
	vote_table.actions_text:SetText("Vote   Remove");
	vote_table.actions_text:SetTextColor(1, 1, 1);
	vote_table.actions_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", 0, 16)
	
	-- Item icon and such
	-- vote_table.item = CreateFrame("frame", nil, vote_table)
	vote_table.item = bdItemButtonLib:CreateButton("bdVoteTableItem"..tab_i, vote_table)
	vote_table.item:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 10, 64)
	vote_table.item:SetAlpha(1)
	vote_table.item:SetSize(340, 40)

	vote_table.item.itemtext = vote_table.item:CreateFontString(nil, "OVERLAY")
	vote_table.item.itemtext:SetFontObject(bdlc:get_font(15, "THINOUTLINE"))
	vote_table.item.itemtext:SetText(l["frameItem"])
	vote_table.item.itemtext:SetPoint("TOPLEFT", vote_table.item, "TOPLEFT", 50, -6)
	
	vote_table.item.num_items = vote_table.item:CreateFontString(nil, "OVERLAY")
	vote_table.item.num_items:SetFontObject(bdlc:get_font(14, "THINOUTLINE"))
	vote_table.item.num_items:SetTextColor(1,1,1,1);
	vote_table.item.num_items:SetText("x1");
	vote_table.item.num_items:SetPoint("LEFT", vote_table.item.itemtext, "RIGHT", 6, 0)

	vote_table.item.itemdetail = vote_table.item:CreateFontString(nil, "OVERLAY")
	vote_table.item.itemdetail:SetFontObject(bdlc:get_font(14, "THINOUTLINE"))
	vote_table.item.itemdetail:SetText(l["frameIlvl"]..": ");
	vote_table.item.itemdetail:SetTextColor(1,1,1,.7);
	vote_table.item.itemdetail:SetPoint("BOTTOMLEFT", vote_table.item, "BOTTOMLEFT", 50, 6)

	vote_table.item.icon = CreateFrame("frame", nil, vote_table.item, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.item.icon:SetSize(40, 40)
	vote_table.item.icon:SetPoint("TOPLEFT", vote_table.item, "TOPLEFT", 0, 0)
	bdlc:setBackdrop(vote_table.item.icon, 0,0,0,.8);
	
	vote_table.item.wfsock = vote_table.item.icon:CreateFontString(nil, "ARTWORK")
	vote_table.item.wfsock:SetFontObject(bdlc:get_font(15, "OUTLINE"))
	vote_table.item.wfsock:SetText("")
	vote_table.item.wfsock:SetTextColor(1, 1, 1)
	vote_table.item.wfsock:SetPoint("CENTER", vote_table.item.icon, "CENTER", 0, 0)
	vote_table.item.wfsock:SetJustifyH("CENTER")

	vote_table.item.icon.tex = vote_table.item.icon:CreateTexture(nil, "OVERLAY")
	vote_table.item.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	vote_table.item.icon.tex:SetDrawLayer('ARTWORK')
	vote_table.item.icon.tex:SetTexture(nil)
	vote_table.item.icon.tex:SetPoint("TOPLEFT", vote_table.item.icon, "TOPLEFT", bdlc.border, -bdlc.border)
	vote_table.item.icon.tex:SetPoint("BOTTOMRIGHT", vote_table.item.icon, "BOTTOMRIGHT", -bdlc.border, bdlc.border)
	
	-- num votes left
	vote_table.numvotes = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.numvotes:SetFontObject(bdlc:get_font(12))
	vote_table.numvotes:SetText("Votes Remaining: ")
	vote_table.numvotes:SetJustifyH("RIGHT")
	vote_table.numvotes:SetTextColor(.8,.8,.8)
	vote_table.numvotes:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", 0, 40)

	vote_table.endSession = CreateFrame("Button", nil, vote_table, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.endSession:SetSize(100, 25)
	vote_table.endSession:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", 0, 70)
	vote_table.endSession:SetText(l["frameEndSession"])
	bdlc:skinButton(vote_table.endSession,false,"red")
	vote_table.endSession:SetScript("OnClick", function()
		bdlc:sendAction("endSession", tab.itemUID);
		
		local itemLink = bdlc.itemMap[tab.itemUID]
		bdlc:print("Ending session:", itemLink)

		bdlc:endSession(tab.itemUID)
	end)


	--==============
	-- display player info for awarding and viewing history
	--==============
	vote_table.info_pane = CreateFrame("Frame", nil, tab, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.info_pane:SetSize(220, 24)
	vote_table.info_pane:Hide()
	bdlc:setBackdrop(vote_table.info_pane, .1, .1, .1, 1)

	-- don't let them roll if they don't want
	C_Timer.NewTicker(.5, function()
		if (not vote_table.info_pane:IsShown()) then return end

		vote_table.info_pane.award:SetEnabled(true)
		vote_table.info_pane.award:SetAlpha(1)
		if (vote_table.info_pane.entry.wantLevel == 15) then
			vote_table.info_pane.award:SetEnabled(false)
			vote_table.info_pane.award:SetAlpha(0.5)
		end

		vote_table.info_pane:ClearAllPoints()
		local str, vert, horz = GetQuadrant(vote_table)
		-- print(vert, horz)
		if (horz == "RIGHT") then
			vote_table.info_pane:SetPoint("TOPRIGHT", vote_table.info_pane.entry, "TOPLEFT", -8, 0)
		else
			vote_table.info_pane:SetPoint("TOPLEFT", vote_table.info_pane.entry, "TOPRIGHT", 8, 0)
		end
	end)
	

	-- name
	vote_table.info_pane.name = vote_table.info_pane:CreateFontString(nil, "OVERLAY")
	vote_table.info_pane.name:SetFontObject(bdlc:get_font(14))
	vote_table.info_pane.name:SetText("Player Name");
	vote_table.info_pane.name:SetPoint("TOPLEFT", vote_table.info_pane, "TOPLEFT", 8, -5)

	-- reward loot button
	vote_table.info_pane.award = CreateFrame("Button", nil, vote_table.info_pane, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.info_pane.award:SetText(l["frameAward"])
	vote_table.info_pane.award:SetPoint("TOPRIGHT", vote_table.info_pane, "TOPRIGHT", 0, 0)
	bdlc:skinButton(vote_table.info_pane.award, false, "blue")
	vote_table.info_pane.award:SetScript("OnClick", function(self)
		bdlc:awardLoot(vote_table.info_pane.playerName, vote_table.info_pane.itemUID)
		vote_table.info_pane:Hide()
	end)

	-- loot history
	vote_table.info_pane.history = CreateFrame("frame", nil, vote_table.info_pane, BackdropTemplateMixin and "BackdropTemplate")
	local history = vote_table.info_pane.history
	history:SetPoint("TOPLEFT", vote_table.info_pane, "BOTTOMLEFT", 0, bdlc.border)
	history:SetPoint("TOPRIGHT", vote_table.info_pane, "BOTTOMRIGHT", 0, bdlc.border)
	bdlc:setBackdrop(history)
	history:SetHeight(100)

	history.text = history:CreateFontString(nil, "OVERLAY")
	history.text:SetFontObject(bdlc:get_font(14))
	history.text:SetText("No loot history...");
	history.text:SetPoint("TOPLEFT", history, "TOPLEFT", 8, -6)

	local function create_history()
		local line = CreateFrame("frame", nil, vote_table.info_pane.history)
		line:SetSize(vote_table.info_pane.history:GetWidth(), 20)

		-- item
		line.item = CreateFrame("frame", nil, line, BackdropTemplateMixin and "BackdropTemplate")
		line.item:SetSize(20, 20)
		line.item:SetPoint("LEFT", line, "LEFT", 6, 0);
		bdlc:setBackdrop(line.item)
		line.item:SetBackdropBorderColor(.0, .3, .1, 1)
		line.item:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(line.data.item)
			GameTooltip:Show()
		end)
		line.item:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		line.item.tex = line.item:CreateTexture(nil, "OVERLAY")
		line.item.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		line.item.tex:SetDrawLayer('ARTWORK')
		line.item.tex:SetTexture(nil)
		line.item.tex:SetPoint("TOPLEFT", line.item, "TOPLEFT", bdlc.border, -bdlc.border)
		line.item.tex:SetPoint("BOTTOMRIGHT", line.item, "BOTTOMRIGHT", -bdlc.border, bdlc.border)

		-- want
		line.want = line:CreateFontString(nil, "OVERLAY")
		line.want:SetPoint("LEFT", line.item, "RIGHT", 6, 0)
		line.want:SetWidth(50)
		line.want:SetFontObject(bdlc:get_font(13))
		line.want:SetJustifyH("LEFT")

		-- gear 1
		line.gear1 = CreateFrame("frame", nil, line, BackdropTemplateMixin and "BackdropTemplate")
		line.gear1:SetSize(20, 20)
		line.gear1:SetPoint("LEFT", line.want, "RIGHT", 18, 0);
		bdlc:setBackdrop(line.gear1)
		line.gear1:SetScript("OnEnter", function()
			if (line.data.gear2 == 1) then 
				return
			end
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(line.data.gear1)
			GameTooltip:Show()
		end)
		line.gear1:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		line.gear1.tex = line.gear1:CreateTexture(nil, "OVERLAY")
		line.gear1.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		line.gear1.tex:SetDrawLayer('ARTWORK')
		line.gear1.tex:SetTexture(nil)
		line.gear1.tex:SetPoint("TOPLEFT", line.gear1, "TOPLEFT", bdlc.border, -bdlc.border)
		line.gear1.tex:SetPoint("BOTTOMRIGHT", line.gear1, "BOTTOMRIGHT", -bdlc.border, bdlc.border)
		
		-- gear 2
		line.gear2 = CreateFrame("frame", nil, line, BackdropTemplateMixin and "BackdropTemplate")
		line.gear2:SetSize(20, 20)
		line.gear2:SetPoint("LEFT", line.gear1, "RIGHT", 4, 0);
		bdlc:setBackdrop(line.gear2)
		line.gear2:SetScript("OnEnter", function()
			if (line.data.gear2 == 0) then 
				return
			end
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:SetHyperlink(line.data.gear2)
			GameTooltip:Show()
		end)
		line.gear2:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		
		line.gear2.tex = line.gear2:CreateTexture(nil, "OVERLAY")
		line.gear2.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		line.gear2.tex:SetDrawLayer('ARTWORK')
		line.gear2.tex:SetTexture(nil)
		line.gear2.tex:SetPoint("TOPLEFT", line.gear2, "TOPLEFT", bdlc.border, -bdlc.border)
		line.gear2.tex:SetPoint("BOTTOMRIGHT", line.gear2, "BOTTOMRIGHT", -bdlc.border, bdlc.border)

		-- notes
		line.notes = CreateFrame("frame", nil, line)
		line.notes:SetPoint("LEFT", line.gear2, "RIGHT", 6, 0)
		line.notes:SetSize(16,16)
		line.notes:SetScript("OnEnter", function()
			ShowUIPanel(GameTooltip)
			GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
			GameTooltip:AddLine(line.data.notes, 1, 1, 1)
			GameTooltip:Show()
		end)
		line.notes:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		line.notes.tex = line.notes:CreateTexture(nil, "OVERLAY")
		line.notes.tex:SetAllPoints(line.notes)
		line.notes.tex:SetTexture("Interface\\FriendsFrame\\BroadcastIcon")

		-- date
		line.date = line:CreateFontString(nil, "OVERLAY")
		line.date:SetPoint("RIGHT", line, "RIGHT", -6, 0)
		line.date:SetFontObject(bdlc:get_font(13))
		line.date:SetTextColor(.5, .5, .5);
		line.date:SetJustifyH("RIGHT")

		return line
	end
	local function reset_history(self, line)
		line.data = {}
		line:ClearAllPoints()
		line:Hide()
		line.gear1:Show()
		line.gear2:Show()
		line.notes:Show()
	end

	if (not history.lines) then
		history.lines = CreateObjectPool(create_history, reset_history)
	end

	vote_table.info_pane:SetScript("OnShow", function(self)
		self.history.lines:ReleaseAll() 
	end)
	vote_table.info_pane:SetScript("OnHide", function(self)
		self.entry:SetBackdropColor(0, 0, 0, 0)
		self.history.lines:ReleaseAll() 
	end)

	-- entries
	local function create_entry(self)
		-- Create entry in table
		local entry = CreateFrame("Button", nil, vote_table.content, BackdropTemplateMixin and "BackdropTemplate")
		entry.wantLevel = 0
		entry.rankIndex = 0
		entry.notes = ""
		entry.roll = 0
		entry.myilvl = 0
		entry:SetSize(vote_table.content:GetWidth() -4, 22)
		entry:SetBackdrop({bgFile = bdlc.media.flat})
		entry:SetBackdropColor(0, 0, 0, 0)

		entry.update = entry:CreateTexture("nil", "ARTWORK")
		entry.update:SetTexture(bdlc.media.flat)
		entry.update:SetVertexColor(1, 1, 1, 1)
		entry.update:SetAllPoints()
		entry.update:SetAlpha(0)

		function entry:updated()
			entry.update:SetAlpha(.1)
			UIFrameFadeOut(entry.update, 1, .1, 0)
		end

		entry.name = CreateFrame("frame", nil, entry)
		entry.name:SetSize(68, 25)
		entry.name:SetPoint("LEFT", entry, "LEFT", 10, 0)

		entry.name.text = entry.name:CreateFontString(nil, "OVERLAY")
		entry.name.text:SetFontObject(bdlc:get_font(14))
		entry.name.text:SetText("test")
		entry.name.text:SetTextColor(1, 1, 1);
		entry.name.text:SetAllPoints()
		entry.name.text:SetJustifyH("LEFT")
		entry:SetScript("OnClick", function(self)	
			
			if (vote_table.info_pane:IsShown()) then
				vote_table.info_pane:Hide()
			else
				vote_table.info_pane:Show()
				vote_table.info_pane:SetFrameLevel(self:GetFrameLevel() + 1)
				vote_table.info_pane:ClearAllPoints()
				local str, vert, horz = GetQuadrant(vote_table)
				-- print(vert, horz)
				if (horz == "RIGHT") then
					vote_table.info_pane:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 0)
				else
					vote_table.info_pane:SetPoint("TOPLEFT", self, "TOPRIGHT", 8, 0)
				end

				vote_table.info_pane.entry = entry
				vote_table.info_pane.entry:SetBackdropColor(1, 1, 1, .07)
				if (bdlc:IsRaidLeader()) then
					vote_table.info_pane.award:Show()
					vote_table.info_pane.award:SetEnabled(true)
					vote_table.info_pane.award:SetAlpha(1)
					if (entry.wantLevel == 15) then
						vote_table.info_pane.award:SetEnabled(false)
						vote_table.info_pane.award:SetAlpha(0.5)
					end
				else
					vote_table.info_pane.award:Hide()
				end

				-- set name
				vote_table.info_pane.name:SetText(bdlc:capitalize(self.playerName))
				vote_table.info_pane.name:SetTextColor(self.name.text:GetTextColor())

				-- data
				vote_table.info_pane.playerName = self.playerName
				vote_table.info_pane.itemUID = self.itemUID

				vote_table.info_pane.history.text:SetText("No loot history last 45 days...");

				-- populate history
				local history = bdlc:getLootHistory(self.playerName)
				if (#history > 0) then vote_table.info_pane.history.text:SetText("") end -- reset text

				local lastline = nil
				local height = 0
				for k, entry in pairs(history) do
					local line = vote_table.info_pane.history.lines:Acquire()
					line:Show()

					local info = entry['entry']

					-- set data for tooltips
					line.data = {}
					line.data.item = entry['itemLink']
					line.data.gear1 = info['itemLink1']
					line.data.gear2 = info['itemLink2']
					line.data.notes = info['notes']

					-- textures
					line.item.tex:SetTexture(entry['itemTexture'])
					line.gear1.tex:SetTexture(info['itemTexture1'])
					line.gear2.tex:SetTexture(info['itemTexture2'])

					-- hide things that aren't populated
					if (line.data.gear1 == 0) then
						line.gear1:Hide()
					end
					if (line.data.gear2 == 0) then
						line.gear2:Hide()
					end
					if (not line.data.notes) then
						line.notes:Hide()
					end

					-- date, remove leading zeroes
					local month, day, year = strsplit("-", entry['date'])
					line.date:SetText(tonumber(month).."-"..tonumber(day).."-"..string.sub(year, -2))

					-- want string
					line.want:SetText(info['wantString'])

					-- position
					if (not lastline) then
						line:SetPoint("TOPLEFT", vote_table.info_pane.history, 0, -4)
					else
						line:SetPoint("TOPLEFT", lastline, "BOTTOMLEFT", 0, -3)
					end

					lastline = line

					height = height + line:GetHeight() + 3
				end

				if (height == 0) then
					height = vote_table.info_pane.history.text:GetStringHeight() + 10
				end
				vote_table.info_pane.history:SetHeight(height + 4)
			end
		end)
		
		entry.rank = entry:CreateFontString(nil, "OVERLAY")
		entry.rank:SetFontObject(bdlc:get_font(14))
		entry.rank:SetText(l["frameRank"]);
		entry.rank:SetTextColor(1,1,1);
		entry.rank:SetPoint("LEFT", entry, "LEFT", 80, 0)
		
		entry.ilvl = entry:CreateFontString(nil, "OVERLAY")
		entry.ilvl:SetFontObject(bdlc:get_font(14))
		entry.ilvl:SetText(0);
		entry.ilvl:SetTextColor(1,1,1);
		entry.ilvl:SetPoint("LEFT", entry, "LEFT", 166, 0)
		
		entry.interest = CreateFrame('frame', nil, entry)
		entry.interest:SetPoint("LEFT", entry, "LEFT", 198, 0)
		entry.interest:SetSize(64,16)
		entry.interest.text = entry.interest:CreateFontString(nil, "OVERLAY")
		entry.interest.text:SetFontObject(bdlc:get_font(14))
		entry.interest:SetScript("OnEnter", function()
			if (entry.roll > 0) then
				ShowUIPanel(GameTooltip)
				GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
				GameTooltip:AddLine(entry.roll, 1, 1, 1)
				GameTooltip:Show()
			end
		end)
		entry.interest:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		entry.interest.text:SetText(l["frameConsidering"])
		entry.interest.text:SetTextColor(.5,.5,.5)
		entry.interest.text:SetAllPoints(entry.interest)
		
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
		
		entry.voteUser = CreateFrame("Button", nil, entry, BackdropTemplateMixin and "BackdropTemplate")
		entry.voteUser:SetSize(45, 20)
		entry.voteUser:SetPoint("RIGHT", entry, "RIGHT", -38, 0)
		entry.voteUser:SetText(l["frameVote"])
		bdlc:skinButton(entry.voteUser, true, "blue")
		entry.voteUser:Hide()
		entry.voteUser:SetScript("OnClick", function()
			vote_table.info_pane:Hide()
			bdlc:voteForUser(bdlc.localPlayer, entry.itemUID, entry.playerName, true)
			bdlc:sendAction("voteForUser", bdlc.localPlayer, entry.itemUID, entry.playerName);
		end)
		
		entry.removeUser = CreateFrame("Button", nil, entry, BackdropTemplateMixin and "BackdropTemplate")
		entry.removeUser:SetSize(25, 20)
		entry.removeUser:SetPoint("RIGHT", entry, "RIGHT", -7, 0)
		entry.removeUser:SetText("x")
		entry.removeUser:GetRegions():SetPoint("TOPLEFT", entry.removeUser, 7, -1)
		entry.removeUser:Hide()
		bdlc:skinButton(entry.removeUser,true,"red")
		entry.removeUser:SetScript("OnClick", function()
			vote_table.info_pane:Hide()
			bdlc:sendAction("removeUserConsidering", entry.itemUID, entry.playerName);
			bdlc:removeUserConsidering(entry.itemUID, entry.playerName)
		end)
		
		entry.gear1 = CreateFrame("frame", nil, entry, BackdropTemplateMixin and "BackdropTemplate")
		entry.gear1:SetSize(20,20);
		entry.gear1:Hide();
		entry.gear1:SetPoint("RIGHT", entry, "RIGHT", -200, 0);
		bdlc:setBackdrop(entry.gear1, 0, 0, 0, 1)
		
		entry.gear1.tex = entry.gear1:CreateTexture(nil, "OVERLAY")
		entry.gear1.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		entry.gear1.tex:SetDrawLayer('ARTWORK')
		entry.gear1.tex:SetTexture(nil)
		entry.gear1.tex:SetPoint("TOPLEFT", entry.gear1, "TOPLEFT", bdlc.border, -bdlc.border)
		entry.gear1.tex:SetPoint("BOTTOMRIGHT", entry.gear1, "BOTTOMRIGHT", -bdlc.border, bdlc.border)
	
		entry.gear2 = CreateFrame("frame", nil, entry, BackdropTemplateMixin and "BackdropTemplate")
		entry.gear2:Hide();
		entry.gear2:SetSize(20,20);
		entry.gear2:SetPoint("RIGHT", entry, "RIGHT", -170, 0);
		bdlc:setBackdrop(entry.gear2, 0, 0, 0, 1)
		
		entry.gear2.tex = entry.gear2:CreateTexture(nil, "OVERLAY")
		entry.gear2.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		entry.gear2.tex:SetDrawLayer('ARTWORK')
		entry.gear2.tex:SetTexture(nil)
		entry.gear2.tex:SetPoint("TOPLEFT", entry.gear2, "TOPLEFT", bdlc.border, -bdlc.border)
		entry.gear2.tex:SetPoint("BOTTOMRIGHT", entry.gear2, "BOTTOMRIGHT", -bdlc.border, bdlc.border)
		
		entry.votes = CreateFrame('frame', nil, entry)
		entry.votes:SetPoint("RIGHT", entry, "RIGHT", -106, 0);
		entry.votes:SetSize(18, 20)
		entry.votes.text = entry.votes:CreateFontString(nil, "OVERLAY")
		entry.votes.text:SetFontObject(bdlc:get_font(14))
		entry.votes.text:SetText("0");
		entry.votes.text:SetTextColor(1, 1, 1);
		entry.votes.text:SetPoint("CENTER", entry.votes, "CENTER", 0, 0)
		entry.votes:SetScript("OnEnter", function()
			if (tonumber(entry.votes.text:GetText()) > 0) then
				ShowUIPanel(GameTooltip)
				GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
				
				for council, ot in pairs(bdlc.loot_council_votes[entry.itemUID]) do
					for v = 1, #bdlc.loot_council_votes[entry.itemUID][council] do
						if (bdlc.loot_council_votes[entry.itemUID][council][v] == entry.playerName) then
							local name, server = strsplit("-", council)
							GameTooltip:AddLine(bdlc:prettyName(name), 1, 1, 1)
						end
					end
				end	
				
				GameTooltip:Show()
			end

		end)
		entry.votes:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		return entry
	end
	local function reset_entry(self, entry)
		entry.user_notes:Hide()
		entry.itemUID = nil
		entry.playerName = ""
		entry.notes = ""
		entry.wantLevel = 0
		entry.myilvl = 0
		entry.voteUser:Hide()
		entry.votes.text:SetText("0")
		entry:Hide()

		entry.voteUser:SetText(l["frameVote"])
		bdlc:skinButton(entry.voteUser, true, "blue")
	end

	if (not tab.entries) then
		tab.entries = CreateObjectPool(create_entry, reset_entry)
	end

	return tab
end
local function reset_tab(self, tab)
	tab.itemUID = nil
	tab:SetAlpha(0.3)
	tab.table:Hide()
	tab.icon:SetDesaturated(true)
	tab.selected = false

	tab:Hide()
end
bdlc.tabs = CreateObjectPool(create_tab, reset_tab)

-- rolls
local i = 0
local function create_roll(self)
	i = i + 1
	local roll = CreateFrame("frame", nil, bdlc.rollFrame, BackdropTemplateMixin and "BackdropTemplate");

	roll:SetPoint("TOPLEFT", bdlc.rollFrame, "TOPLEFT", 0, 0)
	roll:SetSize(bdlc.rollFrame:GetWidth(), 60);
	roll:EnableMouse(true)
	roll:RegisterForDrag("LeftButton", "RightButton")
	roll:SetScript("OnDragStart", function(self) bdlc.rollFrame:StartMoving() end)
	roll:SetScript("OnDragStop", function(self) bdlc.rollFrame:StopMovingOrSizing() end)
	bdlc:setBackdrop(roll, .1, .1, .1, .8)
	
	-- info variable
	roll.notes = "";

	-- Loot item info/hover
	roll.item = CreateFrame("frame", nil, roll);
	roll.item:SetAllPoints(roll)

	local template = ""
	template = template..(BackdropTemplateMixin and ", BackdropTemplate" or "")

	-- bdItemButtonLib
	roll.item.icon = bdItemButtonLib:CreateButton("bdRollItem"..i, roll.item)
	roll.item.icon:SetSize(50, 50)
	roll.item.icon:SetPoint("TOPLEFT", roll, "TOPLEFT", 5, -5)
	bdlc:setBackdrop(roll.item.icon, 0,0,0,.8);
	
	roll.item.icon.wfsock = roll.item.icon:CreateFontString(nil, "ARTWORK")
	roll.item.icon.wfsock:SetFontObject(bdlc:get_font(15, "OUTLINE"))
	roll.item.icon.wfsock:SetText("")
	roll.item.icon.wfsock:SetTextColor(1, 1, 1)
	roll.item.icon.wfsock:SetPoint("CENTER", roll.item.icon, "CENTER", 0, 0)
	roll.item.icon.wfsock:SetJustifyH("CENTER")
	
	roll.item.icon.tex = roll.item.icon:CreateTexture(nil, "ARTWORK")
	roll.item.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	roll.item.icon.tex:SetDrawLayer('ARTWORK')
	roll.item.icon.tex:SetTexture(nil)
	roll.item.icon.tex:SetPoint("TOPLEFT", roll.item.icon, "TOPLEFT", bdlc.border, -bdlc.border)
	roll.item.icon.tex:SetPoint("BOTTOMRIGHT", roll.item.icon, "BOTTOMRIGHT", -bdlc.border, bdlc.border)

	roll.item.item_text = roll.item:CreateFontString(nil, "ARTWORK")
	roll.item.item_text:SetFontObject(bdlc:get_font(15, "OUTLINE"))
	roll.item.item_text:SetText(l["frameItem"])
	roll.item.item_text:SetPoint("TOPLEFT", roll, "TOPLEFT", 60, -8)
	roll.item.item_text:SetJustifyH("LEFT")
	
	roll.item.num_items = roll:CreateFontString(nil, "OVERLAY")
	roll.item.num_items:SetFontObject(bdlc:get_font(12))
	roll.item.num_items:SetText("x1")
	roll.item.num_items:SetTextColor(1, 1, 1)
	roll.item.num_items:SetAlpha(.6)
	roll.item.num_items:SetPoint("TOPRIGHT", roll, "TOPRIGHT", -10, -9)
	roll.item.num_items:SetJustifyH("LEFT")
	
	-- Loot Buttons
	roll.buttons = CreateFrame("frame", nil, roll)
	roll.buttons:SetPoint("BOTTOMLEFT", roll, "BOTTOMLEFT", 50, 0)
	roll.buttons:SetPoint("TOPRIGHT", roll, "BOTTOMRIGHT", 0, 40)

	local get_notes = function()
		local notes = strtrim(roll.stored_notes)
		local quicknotes = roll.stored_quicknotes
		local qn_table = {}
		for k, v in pairs(quicknotes) do
			tinsert(qn_table, v)
		end
		quicknotes = table.concat(qn_table, ", ")

		-- check valid strings
		notes = notes and tostring(notes) and strlen(notes) > 1 and notes or false
		quicknotes = quicknotes and tostring(quicknotes) and strlen(quicknotes) > 1 and quicknotes or false

		-- build little table for text
		local text = {}
		if (notes) then
			tinsert(text, notes)
		end
		if (quicknotes) then
			tinsert(text, quicknotes)
		end

		-- auto concatenate
		text = table.concat(text, ", ")
		text = strtrim(text)

		return text
	end
	
	local submit_roll = function(button, wantLevel)
		local itemLink = bdlc.itemMap[roll.itemUID]
		local itemLink1, itemLink2 = bdlc:fetchUserGear("player", itemLink)

		local notes = get_notes()

		-- check if note was required
		local name, colors, enable, req = unpack(bdlc.buttons[wantLevel])
		if (req and strlen(notes) < 2) then
			roll.buttons.note:Click()
			roll.buttons.notes.note_required:SetAlpha(1)
			roll.buttons.notes.note_required:Show()
			C_Timer.After(1, function()
				UIFrameFadeOut(roll.buttons.notes.note_required, 1, 1, 0)
			end)

			roll.pendingclick = button

			return false
		end

		if (not roll.active or not roll.lootRoll) then
			roll.lootRoll = math.random(1, 100)
		end

		local guildRank = select(2, GetGuildInfo("player")) or ""
		local player_itemlvl = math.floor(select(2, GetAverageItemLevel()))

		bdlc:sendAction("addUserWant", roll.itemUID, bdlc.localPlayer, wantLevel, itemLink1, itemLink2, roll.lootRoll, player_itemlvl, guildRank, notes)

		roll.active = true
		roll.pendingclick = false

		bdlc:repositionFrames()

		return true
	end

	local function update_notes(roll)
		if (roll.active) then
			local notes = get_notes()
			if (notes ~= roll.last_note) then
				roll.last_note = notes
				bdlc:sendAction("updateUserNote", roll.itemUID, bdlc.localPlayer, notes)
			end
		end
	end

	local lastBtn = false
	local firstBtn = false
	roll.btns = {}
	for i = 1, 5 do
		local name, colors, enable, req = unpack(bdlc.buttons[i])

		if (enable) then
			local button = CreateFrame("Button", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
			button:SetText(name)
			button:GetRegions():SetTextColor(unpack(colors))
			button:SetScript("OnClick", function() 
				if (submit_roll(button, i)) then
					for k, v in pairs(roll.btns) do
						v:unselect()
					end
					button:select()
				end
			end)
			bdlc:skinButton(button)

			if (not lastBtn) then
				button:SetPoint("LEFT", roll.buttons, "LEFT", 8, -1)
			else
				button:SetPoint("LEFT", lastBtn, "RIGHT", 4, 0)
			end

			roll.buttons[name] = button
			roll.btns[name] = button
			lastBtn = button
			firstBtn = firstBtn or button
		end
	end
	
	roll.buttons.note = CreateFrame("Button", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.note:SetSize(40, 25)
	roll.buttons.note:SetPoint("LEFT", lastBtn, "RIGHT", 4, 0)
	roll.buttons.note:SetText(l["frameNote"])
	bdlc:skinButton(roll.buttons.note,false,"blue")
	roll.buttons.note:SetScript("OnClick", function()
		roll.buttons.notes.note_required:Hide()
		roll.buttons.notes:Show()
		roll.buttons.notes:SetFocus()
		roll.buttons.note.quicknotes:Show()
	end)
	
	-- quick note buttons
	roll.buttons.note.quicknotes = CreateFrame("frame",nil,roll.buttons)
	roll.buttons.note.quicknotes:SetPoint("TOPRIGHT", roll.buttons, "TOPRIGHT", -2, 16)
	roll.buttons.note.quicknotes:SetPoint("BOTTOMLEFT", roll.buttons, "TOPLEFT", 0, -8)
	roll.buttons.note.quicknotes:Hide()

	local lastqn = nil
	for i = 1, 10 do
		local qn = CreateFrame("button", nil, roll.buttons.note.quicknotes, BackdropTemplateMixin and "BackdropTemplate")
		if (not lastqn) then
			qn:SetPoint("BOTTOMRIGHT", roll.buttons.note.quicknotes, "BOTTOMRIGHT", -4, 4)
		else
			qn:SetPoint("RIGHT", lastqn, "LEFT", bdlc.border, 0)
		end
		lastqn = qn
		qn.i = i

		-- when click store button value in table
		qn:SetScript("OnClick", function(self)
			local text = self:GetText()
			
			if (not self.selected) then
				roll.stored_quicknotes[self.i] = text
				bdlc:skinButton(self, true, "blue")
				self.selected = true
			else
				roll.stored_quicknotes[self.i] = nil
				bdlc:skinButton(self, true)
				self.selected = false
			end
		end)

		roll.buttons.note.quicknotes[i] = qn
	end
	
	roll.buttons.pass = CreateFrame("Button", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.pass:SetSize(42, 25)
	roll.buttons.pass:SetPoint("LEFT", roll.buttons.note, "RIGHT", 4, 0)
	roll.buttons.pass:SetText(l["framePass"])
	bdlc:skinButton(roll.buttons.pass, false, "red")

	roll.buttons.pass:SetScript("OnClick", function()
		bdlc:sendAction("removeUserConsidering", roll.itemUID, bdlc.localPlayer);
		bdlc.rolls:Release(roll)
		bdlc:repositionFrames()
	end)
	
	roll.buttons.notes = CreateFrame("EditBox", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.notes:SetPoint("BOTTOMLEFT", firstBtn, "BOTTOMLEFT")
	roll.buttons.notes:SetPoint("TOPRIGHT", roll.buttons.note, "TOPLEFT", 0, 0)
	roll.buttons.notes:SetMaxLetters(100)
	roll.buttons.notes:IsMultiLine(1)
	roll.buttons.notes:SetTextInsets(6, 2, 2, 2)
	roll.buttons.notes:SetFontObject(bdlc:get_font(14))
	roll.buttons.notes:SetFrameLevel(27)
	roll.buttons.notes:SetBackdrop({bgFile = bdlc.media.flat, edgeFile = bdlc.media.flat, edgeSize = bdlc.border})
	roll.buttons.notes:SetBackdropColor(.1, .1, .1, 1)
	roll.buttons.notes:SetBackdropBorderColor(0, 0, 0, 1)
	roll.buttons.notes:Hide()

	roll.buttons.notes.okay = CreateFrame("Button", nil, roll.buttons.notes, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.notes.okay:SetSize(37, 25)
	roll.buttons.notes.okay:SetPoint("LEFT", roll.buttons.notes, "RIGHT")
	roll.buttons.notes.okay:SetText(l["frameOkay"])
	bdlc:skinButton(roll.buttons.notes.okay, false, "dark")

	-- store notes when submitting field
	local notes_submit = function(self)
		-- print(self, test)
		self:Hide()
		roll.stored_notes = self:GetText()
		roll.buttons.note.quicknotes:Hide()

		if (roll.pendingclick) then
			roll.pendingclick:Click()
		end

		update_notes(roll)
	end
	roll.buttons.notes:SetScript("OnEnterPressed", notes_submit)
	roll.buttons.notes:SetScript("OnEscapePressed", notes_submit)
	roll.buttons.notes.okay:SetScript("OnClick", function(self) notes_submit(self:GetParent()) end)

	-- tell the user that the note is required
	roll.buttons.notes.note_required = roll.buttons.notes:CreateFontString(nil, "OVERLAY")
	roll.buttons.notes.note_required:SetFontObject(bdlc.font)
	roll.buttons.notes.note_required:SetText("Note is required")
	roll.buttons.notes.note_required:SetJustifyH("LEFT")
	roll.buttons.notes.note_required:SetTextColor(0.8, 0.5, 0.5)
	roll.buttons.notes.note_required:SetPoint("LEFT", roll.buttons.notes, 10, 0)

	return roll
end
local function reset_roll(self, roll)
	roll.notes = ""
	roll.itemUID = nil
	roll.qn = ""
	roll.lootRoll = 0
	roll.active = false
	roll.stored_notes = ""
	roll.stored_quicknotes = {}
	roll.last_note = ""
	roll.pendingclick = false
	roll:Hide()

	for k, v in pairs(roll.btns) do
		v:unselect()
	end

	for i = 1, 10 do
		local qn = roll.buttons.note.quicknotes[i]
		-- qn.select = false
		qn:SetText("")
		qn:Hide()
		qn.selected = false
	end

	roll.buttons.notes:SetText("")
end
bdlc.rolls = CreateObjectPool(create_roll, reset_roll)

--=====================================================
-- Create Main Window
--=====================================================
bdlc.window = CreateFrame("frame", "BDLC Window", UIParent, BackdropTemplateMixin and "BackdropTemplate")
bdlc.window:EnableMouse(true);
bdlc.window:SetMovable(true);
bdlc.window:SetUserPlaced(true);
bdlc.window:SetFrameStrata("DIALOG");
bdlc.window:SetFrameLevel(27);
bdlc.window:SetSize(600, 400);
bdlc.window:SetPoint("CENTER");
bdlc.window:Hide();
bdlc:setBackdrop(bdlc.window, .1, .1, .1, .9);

bdlc.window.tabs = CreateFrame("frame", nil, bdlc.window);
bdlc.window.tabs:SetPoint("TOPLEFT", bdlc.window, "TOPLEFT", -40, 0)
bdlc.window.tabs:SetPoint("BOTTOMRIGHT", bdlc.window, "BOTTOMLEFT", 0, 0)
-- bdlc.window:Hide()

bdlc.window.header = CreateFrame("frame", nil, bdlc.window, BackdropTemplateMixin and "BackdropTemplate");
bdlc.window.header:EnableMouse(true);
bdlc.window.header:RegisterForDrag("LeftButton","RightButton")
bdlc.window.header:SetScript("OnDragStart", function(self) bdlc.window:StartMoving() end)
bdlc.window.header:SetScript("OnDragStop", function(self)  bdlc.window:StopMovingOrSizing() end)
bdlc.window.header:SetPoint("TOPLEFT", bdlc.window, "TOPLEFT")
bdlc.window.header:SetPoint("BOTTOMRIGHT", bdlc.window, "TOPRIGHT", 0, -24)
bdlc:setBackdrop(bdlc.window.header, .1, .1, .1, 1)

bdlc.window.header.close = CreateFrame("Button", nil, bdlc.window.header, BackdropTemplateMixin and "BackdropTemplate")
bdlc.window.header.close:SetPoint("RIGHT", bdlc.window.header, "RIGHT", -4, 0)
bdlc.window.header.close:SetText("x")
bdlc:skinButton(bdlc.window.header.close, true, "red")
bdlc.window.header.close:SetScript("OnClick", function()
	bdlc.window:Hide()
end)

bdlc.window.header.text = bdlc.window.header:CreateFontString(nil, "OVERLAY")
bdlc.window.header.text:SetFontObject(bdlc:get_font(15))
bdlc.window.header.text:SetText(bdlc.colorString)
bdlc.window.header.text:SetPoint("CENTER", bdlc.window.header, "CENTER")

--==============================================
-- Loot Council Display
--==============================================
bdlc.window.loot_council = CreateFrame("frame", nil, bdlc.window, BackdropTemplateMixin and "BackdropTemplate")
bdlc.window.loot_council:SetPoint("BOTTOMLEFT", bdlc.window, "BOTTOMLEFT", 10, 6)
bdlc.window.loot_council:SetSize(84, 18)
bdlc:setBackdrop(bdlc.window.loot_council, .1,.1,.1,.8);
bdlc.window.loot_council.text = bdlc.window.loot_council:CreateFontString(nil, "OVERLAY")
bdlc.window.loot_council.text:SetFontObject(bdlc:get_font(14))
bdlc.window.loot_council.text:SetPoint("LEFT", bdlc.window.loot_council, "LEFT", 4, 0)
bdlc.window.loot_council.text:SetText(l["frameLC"])
bdlc.window.loot_council.text:SetJustifyH("LEFT")
bdlc.window.loot_council.image = bdlc.window.loot_council:CreateTexture(nil, "OVERLAY")
bdlc.window.loot_council.image:SetTexture("Interface\\FriendsFrame\\InformationIcon")
bdlc.window.loot_council.image:SetSize(10, 10)
bdlc.window.loot_council.image:SetPoint("RIGHT", bdlc.window.loot_council, "RIGHT", -4, 0)
bdlc.window.loot_council.image:SetVertexColor(.8,.8,.8)

bdlc.window.loot_council.add = CreateFrame("BUTTON", nil, bdlc.window.loot_council, BackdropTemplateMixin and "BackdropTemplate")
bdlc.window.loot_council.add:SetText(" + ")
bdlc:skinButton(bdlc.window.loot_council.add,true,"blue")
bdlc.window.loot_council.add:SetPoint("LEFT", bdlc.window.loot_council, "RIGHT", 2, 0)
bdlc.window.loot_council.add:SetWidth(18)
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
bdlc.window.loot_council.add:SetScript("OnClick", function()
	StaticPopup_Show("ADD_TO_LC_BOX")
end)

bdlc.window:HookScript("OnShow", function()
	if (bdlc:IsRaidLeader() or not IsInRaid()) then
		bdlc.window.loot_council.add:Show()
	else
		bdlc.window.loot_council.add:Hide()
	end
end)

bdlc.window.loot_council:SetScript("OnEnter", function()
	ShowUIPanel(GameTooltip)
	GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
	
	for councilName, v in pairs(bdlc.loot_council) do
		-- local name, server = strsplit("-", councilName)
		-- if (server == player_realm) then
		-- 	councilName = name
		-- end
		local name, color = bdlc:prettyName(councilName)
		GameTooltip:AddLine(name, color.r, color.g, color.b)
	end

	GameTooltip:Show()
end)
bdlc.window.loot_council:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

--==========================================
-- Rolls
--==========================================
bdlc.rollFrame = CreateFrame('frame', "BDLC Roll Window", UIParent)
bdlc.rollFrame:SetSize(420, 1)
bdlc.rollFrame:SetPoint("CENTER", UIParent, "CENTER", 600, 0)
bdlc.rollFrame:EnableMouse(true)
bdlc.rollFrame:SetMovable(true);
bdlc.rollFrame:SetUserPlaced(true);
bdlc.rollFrame:SetFrameStrata("FULLSCREEN");
bdlc.rollFrame:SetFrameLevel(10)
bdlc.rollFrame:SetClampedToScreen(true);
bdlc.rollFrame:RegisterForDrag("LeftButton","RightButton")
bdlc.rollFrame:SetScript("OnDragStart", function(self) bdlc.rollFrame:StartMoving() end)
bdlc.rollFrame:SetScript("OnDragStop", function(self) bdlc.rollFrame:StopMovingOrSizing() end)
bdlc.rollFrame:Hide()

bdlc.rollFrame.title = bdlc.rollFrame:CreateFontString(nil, "OVERLAY")
bdlc.rollFrame.title:SetFontObject(bdlc:get_font(15, "OUTLINE"))
bdlc.rollFrame.title:SetText(bdlc.colorString)
bdlc.rollFrame.title:SetPoint("BOTTOM", bdlc.rollFrame, "TOP", 0, 2)