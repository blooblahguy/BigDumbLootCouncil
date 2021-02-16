local bdlc, c, l = unpack(select(2, ...))

--======================================
-- Fonts
--======================================
bdlc.fonts = {}
-- dynamic font creation/fetching
function bdlc:get_font(size, outline)
	outline = outline or "NONE"
	local name = size.."_"..outline
	
	if (not bdlc.fonts[name]) then
		local font = CreateFont("BDLC_"..name)
		font:SetFont(bdlc.media.font, tonumber(size), outline)
		if (outline == "NONE") then
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
			
			return a.name:GetText() > b.name:GetText()
		end) do
			entry:ClearAllPoints()
			if (entry.itemUID and entry:IsShown()) then
				if (lastentry) then
					entry:SetPoint("TOPLEFT", lastentry, "BOTTOMLEFT", 0, 1)
				else
					entry:SetPoint("TOPLEFT", tab.table.content, "TOPLEFT", 0, 1)
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
	if (lasttab) then
		bdlc.window:Show()
	else
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

	current_tab.itemUID = itemUID

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
local function create_tab(self)
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
				other_tab.table.award:Hide()
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
	vote_table.name_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 10, 16);
	
	vote_table.rank_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.rank_text:SetFontObject(bdlc:get_font(14))
	vote_table.rank_text:SetText(l["frameRank"]);
	vote_table.rank_text:SetTextColor(1, 1, 1);
	vote_table.rank_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 80, 16);
	
	vote_table.ilvl_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.ilvl_text:SetFontObject(bdlc:get_font(14))
	vote_table.ilvl_text:SetText(l["frameIlvl"]);
	vote_table.ilvl_text:SetTextColor(1, 1, 1);
	vote_table.ilvl_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 170, 16);
	
	vote_table.ilvl_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.ilvl_text:SetFontObject(bdlc:get_font(14))
	vote_table.ilvl_text:SetText(l["frameInterest"]);
	vote_table.ilvl_text:SetTextColor(1, 1, 1);
	vote_table.ilvl_text:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 200, 16);
	
	vote_table.notes_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.notes_text:SetFontObject(bdlc:get_font(14))
	vote_table.notes_text:SetText(l["frameNotes"]);
	vote_table.notes_text:SetTextColor(1, 1, 1);
	vote_table.notes_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", -250, 16);
	
	vote_table.current_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.current_text:SetFontObject(bdlc:get_font(14))
	vote_table.current_text:SetText(l["frameCurrentGear"]);
	vote_table.current_text:SetTextColor(1, 1, 1);
	vote_table.current_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", -160, 16);
	
	vote_table.votes_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.votes_text:SetFontObject(bdlc:get_font(14))
	vote_table.votes_text:SetText(l["frameVotes"]);
	vote_table.votes_text:SetTextColor(1, 1, 1);
	vote_table.votes_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", -100, 16);
	
	vote_table.actions_text = vote_table:CreateFontString(nil, "OVERLAY")
	vote_table.actions_text:SetFontObject(bdlc:get_font(14))
	vote_table.actions_text:SetText("Vote   Remove");
	vote_table.actions_text:SetTextColor(1, 1, 1);
	vote_table.actions_text:SetPoint("TOPRIGHT", vote_table, "TOPRIGHT", 0, 16);
	
	-- Item icon and such
	vote_table.item = CreateFrame("frame", nil, vote_table)
	vote_table.item:SetPoint("TOPLEFT", vote_table, "TOPLEFT", 10, 64)
	vote_table.item:SetAlpha(1)
	vote_table.item:SetSize(340, 40)

	vote_table.item.itemtext = vote_table.item:CreateFontString(nil, "OVERLAY")
	vote_table.item.itemtext:SetFontObject(bdlc:get_font(15))
	vote_table.item.itemtext:SetText(l["frameItem"])
	vote_table.item.itemtext:SetPoint("TOPLEFT", vote_table.item, "TOPLEFT", 50, -6)
	
	vote_table.item.num_items = vote_table.item:CreateFontString(nil, "OVERLAY")
	vote_table.item.num_items:SetFontObject(bdlc:get_font(14))
	vote_table.item.num_items:SetTextColor(1,1,1,1);
	vote_table.item.num_items:SetText("x1");
	vote_table.item.num_items:SetPoint("LEFT", vote_table.item.itemtext, "RIGHT", 6, 0)

	vote_table.item.itemdetail = vote_table.item:CreateFontString(nil, "OVERLAY")
	vote_table.item.itemdetail:SetFontObject(bdlc:get_font(14))
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
	vote_table.item.icon.tex:SetPoint("TOPLEFT", vote_table.item.icon, "TOPLEFT", 2, -2)
	vote_table.item.icon.tex:SetPoint("BOTTOMRIGHT", vote_table.item.icon, "BOTTOMRIGHT", -2, 2)
	
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


	vote_table.award = CreateFrame("Frame", nil, tab, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.award:SetSize(100, 42)
	-- vote_table.award:SetFrameStrata()
	vote_table.award:Hide()
	bdlc:setBackdrop(vote_table.award, .1, .1, .1, 1)
	
	vote_table.award.text = vote_table.award:CreateFontString(nil, "OVERLAY")
	vote_table.award.text:SetFontObject(bdlc:get_font(14, "NONE"))
	vote_table.award.text:SetText("Award loot to ?");
	vote_table.award.text:SetPoint("TOP", vote_table.award, "TOP", 0, -2)
	
	vote_table.award.yes = CreateFrame("Button", nil, vote_table.award, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.award.yes:SetText(l["frameYes"])
	vote_table.award.yes:SetPoint("BOTTOMLEFT", vote_table.award, "BOTTOMLEFT", 2, 2)
	bdlc:skinButton(vote_table.award.yes, false, "blue")
	
	vote_table.award.no = CreateFrame("Button", nil, vote_table.award, BackdropTemplateMixin and "BackdropTemplate")
	vote_table.award.no:SetText(l["frameNo"])
	vote_table.award.no:SetPoint("BOTTOMRIGHT", vote_table.award, "BOTTOMRIGHT", -2, 2)
	bdlc:skinButton(vote_table.award.no,false,"red")
	
	vote_table.award.no:SetScript("OnClick", function() vote_table.award:Hide() end)
	vote_table.award.yes:SetScript("OnClick", function(self)
		-- print("clicked?"..nil)
		bdlc:awardLoot(vote_table.award.playerName, vote_table.award.itemUID)
		vote_table.award:Hide()
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
		entry:SetSize(vote_table.content:GetWidth(), 22)

		entry.name = entry:CreateFontString(nil, "OVERLAY")
		entry.name:SetFontObject(bdlc:get_font(14, "NONE"))
		entry.name:SetText("test");
		entry.name:SetTextColor(1, 1, 1);
		entry.name:SetPoint("LEFT", entry, "LEFT", 10, 0)
		
		entry:SetScript("OnClick", function(self)	
			if (IsRaidLeader()) then
				if (vote_table.award:IsShown()) then
					vote_table.award:Hide()
				else
					vote_table.award:Show()
					vote_table.award:SetFrameLevel(self:GetFrameLevel() + 1)
					vote_table.award:SetPoint("TOPLEFT", self.name, "BOTTOMLEFT", 0, -2)
					local r, g, b = self.name:GetTextColor()
					local hex = RGBPercToHex(r, g, b)
					local name = string.gsub(" "..self.playerName, "%W%l", string.upper):sub(2)
					vote_table.award.text:SetText(l["frameAward"].."|cff"..hex..name.."|r?")
					vote_table.award:SetWidth(vote_table.award.text:GetStringWidth() + 12)
					vote_table.award.playerName = self.playerName
					vote_table.award.itemUID = self.itemUID
				end
			else
				vote_table.award:Hide()
			end
		end)
		
		entry.rank = entry:CreateFontString(nil, "OVERLAY")
		entry.rank:SetFontObject(bdlc:get_font(14, "NONE"))
		entry.rank:SetText(l["frameRank"]);
		entry.rank:SetTextColor(1,1,1);
		entry.rank:SetPoint("LEFT", entry, "LEFT", 80, 0)
		
		entry.ilvl = entry:CreateFontString(nil, "OVERLAY")
		entry.ilvl:SetFontObject(bdlc:get_font(14, "NONE"))
		entry.ilvl:SetText(0);
		entry.ilvl:SetTextColor(1,1,1);
		entry.ilvl:SetPoint("LEFT", entry, "LEFT", 166, 0)
		
		entry.interest = CreateFrame('frame', nil, entry)
		entry.interest:SetPoint("LEFT", entry, "LEFT", 198, 0)
		entry.interest:SetSize(64,16)
		entry.interest.text = entry.interest:CreateFontString(nil, "OVERLAY")
		entry.interest.text:SetFontObject(bdlc:get_font(14, "NONE"))
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
			vote_table.award:Hide()
			bdlc:voteForUser(bdlc.localPlayer, entry.itemUID, entry.playerName, true)
			bdlc:sendAction("voteForUser", bdlc.localPlayer, entry.itemUID, entry.playerName);
		end)
		
		entry.removeUser = CreateFrame("Button", nil, entry, BackdropTemplateMixin and "BackdropTemplate")
		entry.removeUser:SetSize(25, 20)
		entry.removeUser:SetPoint("RIGHT", entry, "RIGHT", -7, 0)
		entry.removeUser:SetText("x")
		entry.removeUser:Hide()
		bdlc:skinButton(entry.removeUser,true,"red")
		entry.removeUser:SetScript("OnClick", function()
			vote_table.award:Hide()
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
		entry.gear1.tex:SetPoint("TOPLEFT", entry.gear1, "TOPLEFT", 2, -2)
		entry.gear1.tex:SetPoint("BOTTOMRIGHT", entry.gear1, "BOTTOMRIGHT", -2, 2)
	
		entry.gear2 = CreateFrame("frame", nil, entry, BackdropTemplateMixin and "BackdropTemplate")
		entry.gear2:Hide();
		entry.gear2:SetSize(20,20);
		entry.gear2:SetPoint("RIGHT", entry, "RIGHT", -170, 0);
		bdlc:setBackdrop(entry.gear2, 0, 0, 0, 1)
		
		entry.gear2.tex = entry.gear2:CreateTexture(nil, "OVERLAY")
		entry.gear2.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		entry.gear2.tex:SetDrawLayer('ARTWORK')
		entry.gear2.tex:SetTexture(nil)
		entry.gear2.tex:SetPoint("TOPLEFT", entry.gear2, "TOPLEFT", 2, -2)
		entry.gear2.tex:SetPoint("BOTTOMRIGHT", entry.gear2, "BOTTOMRIGHT", -2, 2)
		
		entry.votes = CreateFrame('frame', nil, entry)
		entry.votes:SetPoint("RIGHT", entry, "RIGHT", -106, 0);
		entry.votes:SetSize(18, 20)
		entry.votes.text = entry.votes:CreateFontString(nil, "OVERLAY")
		entry.votes.text:SetFontObject(bdlc:get_font(14, "NONE"))
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
local function create_roll(self)
	local roll = CreateFrame("frame", nil, bdlc.rollFrame, BackdropTemplateMixin and "BackdropTemplate");

	roll:SetPoint("TOPLEFT", bdlc.rollFrame, "TOPLEFT", 0, 0)
	roll:SetSize(bdlc.rollFrame:GetWidth(), 60);
	roll:EnableMouse(true)
	roll:RegisterForDrag("LeftButton", "RightButton")
	roll:SetScript("OnDragStart", function(self) bdlc.rollFrame:StartMoving() end)
	roll:SetScript("OnDragStop", function(self) bdlc.rollFrame:StopMovingOrSizing() end)
	bdlc:setBackdrop(roll, .2, .2, .2, .9)
	
	-- info variable
	roll.notes = "";

	-- Loot item info/hover
	roll.item = CreateFrame("frame", nil, roll);
	roll.item:SetAllPoints(roll)

	roll.item.icon = CreateFrame("frame", nil, roll.item, BackdropTemplateMixin and "BackdropTemplate")
	roll.item.icon:SetSize(50, 50)
	roll.item.icon:SetPoint("TOPLEFT", roll, "TOPLEFT", 5, -5)
	roll.item.icon:SetScript("OnEnter", function(self)
		ShowUIPanel(GameTooltip)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(self.itemLink)
		GameTooltip:Show()
	end)
	roll.item.icon:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
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
	roll.item.icon.tex:SetPoint("TOPLEFT", roll.item.icon, "TOPLEFT", 2, -2)
	roll.item.icon.tex:SetPoint("BOTTOMRIGHT", roll.item.icon, "BOTTOMRIGHT", -2, 2)

	roll.item.item_text = roll.item:CreateFontString(nil, "ARTWORK")
	roll.item.item_text:SetFontObject(bdlc:get_font(15))
	roll.item.item_text:SetText(l["frameItem"])
	roll.item.item_text:SetPoint("TOPLEFT", roll, "TOPLEFT", 60, -8)
	roll.item.item_text:SetJustifyH("LEFT")
	
	roll.item.num_items = roll:CreateFontString(nil, "OVERLAY")
	roll.item.num_items:SetFontObject(bdlc:get_font(14))
	roll.item.num_items:SetText("x1")
	roll.item.num_items:SetTextColor(1, 1, 1)
	roll.item.num_items:SetAlpha(.8)
	roll.item.num_items:SetPoint("LEFT", roll.item.item_text, "RIGHT", 6, 0)
	roll.item.num_items:SetJustifyH("LEFT")
	
	-- Loot Buttons
	roll.buttons = CreateFrame("frame", nil, roll);
	roll.buttons:SetPoint("BOTTOMLEFT", roll, "BOTTOMLEFT", 50, 0);
	roll.buttons:SetPoint("TOPRIGHT", roll, "BOTTOMRIGHT", 0, 40);
	
	roll.buttons.submit = function(wantLevel)
		local itemLink = bdlc.itemMap[roll.itemUID]
		local itemLink1, itemLink2 = bdlc:fetchUserGear("player", itemLink)

		local notes = roll.notes or ''
		if (string.len(roll.qn) > 0) then
			roll.qn = string.sub(roll.qn, 0, -3)
			if (string.len(notes) > 0) then
				notes = notes..", "..roll.qn
			else
				notes = roll.qn
			end
		end

		local lootRoll = math.random(1, 100)

		local guildRank = select(2, GetGuildInfo("player")) or ""
		local player_itemlvl = math.floor(select(2, GetAverageItemLevel()))

		bdlc:sendAction("addUserWant", roll.itemUID, bdlc.localPlayer, wantLevel, itemLink1, itemLink2, lootRoll, player_itemlvl, guildRank, notes);

		bdlc.rolls:Release(roll)

		bdlc:repositionFrames()
	end

	local lastBtn = false
	local firstBtn = false
	for i = 1, 5 do
		local name, colors, enable, req = unpack(bdlc.config.buttons[i])

		local button = CreateFrame("Button", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
		button:SetText(name)
		button:GetRegions():SetTextColor(unpack(colors))
		button:SetScript("OnClick", function() roll.buttons.submit(i) end)
		bdlc:skinButton(button)

		if (not lastBtn) then
			button:SetPoint("LEFT", roll.buttons, "LEFT", 8, -1)
		else
			button:SetPoint("LEFT", lastBtn, "RIGHT", 4, 0)
		end

		roll.buttons[name] = button
		lastBtn = button
		firstBtn = firstBtn or button
	end
	
	roll.buttons.note = CreateFrame("Button", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.note:SetSize(40, 25)
	roll.buttons.note:SetPoint("LEFT", lastBtn, "RIGHT", 4, 0)
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
	roll.buttons.note.quicknotes:SetScript("OnDragStart", function(self) bdlc.rollFrame:StartMoving() end)
	roll.buttons.note.quicknotes:SetScript("OnDragStop", function(self) bdlc.rollFrame:StopMovingOrSizing() end)
	roll.buttons.note.quicknotes.append = function(text)
		if (string.len(text) > 0 and not strfind(roll.qn, text, 1, true)) then
			roll.qn = roll.qn..text..", "
		end
	end

	local lastqn = nil
	for i = 1, 10 do
		roll.buttons.note.quicknotes[i] = CreateFrame("button", nil, roll.buttons.note.quicknotes, BackdropTemplateMixin and "BackdropTemplate")
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
				bdlc:skinButton(qn, false, "blue")
				qn:SetAlpha(1)
				qn.selected = true
			else
				bdlc:skinButton(qn, false)
				qn:SetAlpha(0.6)
				qn.selected = false
			end
		end)
	end
	
	roll.buttons.pass = CreateFrame("Button", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.pass:SetSize(42, 25)
	roll.buttons.pass:SetPoint("LEFT", roll.buttons.note, "RIGHT", 4, 0)
	roll.buttons.pass:SetText(l["framePass"])
	bdlc:skinButton(roll.buttons.pass, false, "red")

	roll.buttons.pass:SetScript("OnClick", function()
		bdlc:sendAction("removeUserConsidering", roll.itemUID, bdlc.localPlayer);
		bdlc.rolls:Release(roll)
	end)
	
	roll.buttons.notes = CreateFrame("EditBox", nil, roll.buttons, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.notes:SetPoint("BOTTOMLEFT", firstBtn, "BOTTOMLEFT")
	roll.buttons.notes:SetPoint("TOPRIGHT", roll.buttons.pass, "TOPRIGHT")
	roll.buttons.notes:SetMaxLetters(100)
	roll.buttons.notes:IsMultiLine(1)
	roll.buttons.notes:SetTextInsets(6, 2, 2, 2)
	roll.buttons.notes:SetFontObject(bdlc:get_font(14, "NONE"))
	roll.buttons.notes:SetFrameLevel(27)
	roll.buttons.notes:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
	roll.buttons.notes:SetBackdropColor(.1, .1, .1, 1)
	roll.buttons.notes:SetBackdropBorderColor(0, 0, 0, 1)
	roll.buttons.notes:Hide()
	roll.buttons.notes.okay = CreateFrame("Button", nil, roll.buttons.notes, BackdropTemplateMixin and "BackdropTemplate")
	roll.buttons.notes.okay:SetSize(37, 25)
	roll.buttons.notes.okay:SetPoint("LEFT", roll.buttons.notes, "RIGHT")
	roll.buttons.notes.okay:SetText(l["frameOkay"])
	bdlc:skinButton(roll.buttons.notes.okay, false, "dark")
	roll.buttons.notes.okay:SetScript("OnClick", function(self)
		self:GetParent():Hide()
		roll.notes = self:GetParent():GetText()
	end)
	roll.buttons.notes:SetScript("OnEnterPressed", function(self, key) roll.buttons.notes.okay:Click() end)
	roll.buttons.notes:SetScript("OnEscapePressed", function(self, key) roll.buttons.notes.okay:Click() end)
	
	return roll
end
local function reset_roll(self, roll)
	roll.notes = ""
	roll.itemUID = nil
	roll.qn = ""
	roll:Hide()

	for i = 1, 10 do
		local qn = roll.buttons.note.quicknotes[i]
		qn.select = false
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
	if (IsRaidLeader() or not IsInRaid()) then
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
bdlc.rollFrame:SetSize(520, 1)
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