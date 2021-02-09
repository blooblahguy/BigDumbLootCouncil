local bdlc, c, l = unpack(select(2, ...))

local config = CreateFrame('frame', 'BDLC Config', UIParent, BackdropTemplateMixin and "BackdropTemplate")
config:SetFrameStrata("HIGH")
config:SetFrameLevel(9)
config:SetSize(500, 400)
config:SetPoint("CENTER")
config:EnableMouse(true)
config:SetMovable(true)
config:SetUserPlaced(true)
config:SetClampedToScreen(true)
config:RegisterForDrag("LeftButton","RightButton")
config:SetScript("OnDragStart", function(self) config:StartMoving() end)
config:SetScript("OnDragStop", function(self)  config:StopMovingOrSizing() end)
config:Hide()
bdlc:setBackdrop(config)

-- Config Title
config.title = config:CreateFontString('nil', "OVERLAY")
config.title:SetFontObject(bdlc:get_font(15, "OUTLINE"))
config.title:SetText("Big Dumb Loot Council Config")
config.title:SetTextColor(1,1,1)
config.title:SetPoint("TOP", config, "TOP", 0,-6)

-- Close Button
config.close = CreateFrame("Button", nil, config, BackdropTemplateMixin and "BackdropTemplate")
config.close:SetPoint("TOPRIGHT", config, "TOPRIGHT", -4, -4)
config.close:SetText("x")
bdlc:skinButton(config.close, true, "red")
config.close:SetBackdropColor(.5,.1,.1,.5)
config.close:SetScript("OnClick", function()
	config:Hide()
	bdlc.config_toggle = false
end)

bdlc.config_window = config

--==========================================
-- Council minimum rank
--==========================================
local guild_ranks = {}
local function store_ranks()
	guild_ranks = {}

	local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
	for i =1, numGuildMembers do
		local name, rank, rankIndex, _, class = GetGuildRosterInfo(i)
		guild_ranks[rankIndex] = rank
	end
end

config:RegisterEvent("GUILD_ROSTER_UPDATE")
config:SetScript("OnEvent", function(self, event)
	store_ranks()
end)
C_GuildInfo.GuildRoster()

config:SetScript("OnShow", function(self)
	if (self.init) then return end
	self.init = true
	store_ranks()

	--======================
	-- min rank
	--======================
	local default = bdlc.config and bdlc.config.council_min_rank or bdlc.configDefaults.council_min_rank
	local options = {
		['name'] = 'lc_rank',
		['parent'] = self,
		['title'] = 'Minimum LC Guild Rank',
		['items'] = guild_ranks,
		['width'] = 200,
		['default'] = guild_ranks[default],
		['callback'] = function(dropdown_frame, dropdown_val)
			bdlc:sendLC()
		end
	}

	local minrank = bdlc:createDropdown(options)
	minrank:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -50)

	--======================
	-- allowed votes
	--======================
	local options = {
		['name'] = 'votes',
		['parent'] = self,
		['title'] = 'Loot Council Number of Votes',
		['width'] = 140,
		['default'] = bdlc.config.council_votes,
		['callback'] = function(value, key)
			bdlc.config.council_votes = tonumber(value)
			bdlc.council_votes = bdlc.config.council_votes
			bdlc:sendLC()
		end
	}

	local votes = bdlc:createEdit(options)
	votes:SetNumeric(true)
	votes:SetPoint("LEFT", minrank, "RIGHT", 10)

	--======================
	-- custom council
	--======================
	local options = {
		['name'] = 'custom_council',
		['parent'] = self,
		['title'] = 'Custom Council',
		['items'] = bdlc.config.custom_council,
		['width'] = 400,
		['lower'] = true,
		['callback'] = function(container, value)
			value = FetchUnitName(value)

			if(bdlc.config.custom_council[value]) then
				container.insert.alert:SetText(value.." removed")
				container.insert.alert:SetTextColor(1, .3, .3)
				container:startfade()

				bdlc.config.custom_council[value] = nil
			else
				container.insert.alert:SetText(value.." added")
				container.insert.alert:SetTextColor(.3, 1, .3)
				container:startfade()

				bdlc.config.custom_council[value] = true
			end

			container:populate(bdlc.config.custom_council)
			bdlc:sendLC()
		end
	}

	local custom_council = bdlc:createList(options)
	custom_council:SetPoint("TOPLEFT", minrank, "BOTTOMLEFT", 20, -50)

	--======================
	-- quick notes
	--======================
	local options = {
		['name'] = 'quick_notes',
		['parent'] = self,
		['title'] = 'Quick Notes',
		['items'] = bdlc.config.quick_notes,
		['width'] = 400,
		['callback'] = function(container, value)
			if(bdlc.config.quick_notes[value]) then
				container.insert.alert:SetText(value.." removed")
				container.insert.alert:SetTextColor(1, .3, .3)
				container:startfade()
				
				bdlc.config.quick_notes[value] = nil
			else
				container.insert.alert:SetText(value.." added")
				container.insert.alert:SetTextColor(.3, 1, .3)
				container:startfade()

				bdlc.config.quick_notes[value] = true
			end

			container:populate(bdlc.config.quick_notes)
			bdlc:sendLC()
		end
	}

	local quick_notes = bdlc:createList(options)
	quick_notes:SetPoint("TOPLEFT", custom_council, "BOTTOMLEFT", 0, -50)

	--======================
	-- custom buttons
	--======================
	if (false == true) then
		local last = false
		for i = 1, 5 do
			-- enable
			local options = {
				['name'] = 'use_button_'..i,
				['parent'] = self,
				['title'] = 'Enable',
				['default'] = bdlc.config.buttons[i][3],
				['callback'] = function(toggle, button)
					bdlc.config.buttons[i][3] = toggle:GetChecked()
					bdlc:sendLC()
				end
			}
			local enable = bdlc:createToggle(options)

			-- text
			local options = {
				['name'] = 'button_text'..i,
				['parent'] = self,
				['title'] = '',
				['width'] = 130,
				['default'] = bdlc.config.buttons[i][1],
				['callback'] = function(value, key)
					bdlc.config.buttons[i][1] = value
					bdlc:sendLC()
				end
			}
		
			local text = bdlc:createEdit(options)
			text:SetPoint("LEFT", enable, "RIGHT", 60, 0)

			-- color
			local options = {
				['name'] = 'button_color'..i,
				['parent'] = self,
				['title'] = 'Color',
				['width'] = 100,
				['default'] = bdlc.config.buttons[i][2],
				['callback'] = function(picker, r, g, b, a)
					local value = table.concat({r, g, b})
					local current = table.concat(bdlc.config.buttons[i][2])
					if (current ~= value) then
						bdlc.config.buttons[i][2] = {r, g, b}
						bdlc:sendLC()
					end
				end
			}
		
			local picker = bdlc:createColor(options)
			picker:SetPoint("LEFT", text, "RIGHT", 20, 0)

			-- require
			local options = {
				['name'] = 'req_note_'..i,
				['parent'] = self,
				['title'] = 'Require Note',
				['default'] = bdlc.config.buttons[i][4],
				['callback'] = function(toggle, button)
					bdlc.config.buttons[i][4] = toggle:GetChecked()
					bdlc:sendLC()
				end
			}
			local req = bdlc:createToggle(options)
			req:SetPoint("LEFT", picker, "RIGHT", 45, 0)

			-- position
			if (not last) then
				enable:SetPoint("TOPLEFT", quick_notes, "BOTTOMLEFT", 0, -10)
			else
				enable:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -10)
			end

			last = enable
		end
	end
end)

-- config:Show()

-- 
-- config:RegisterEvent("GUILD_ROSTER_UPDATE")
-- config:SetScript("OnEvent", function(self, event, arg1)
-- 	self:UnregisterEvent("GUILD_ROSTER_UPDATE")
-- 	c = bdlc.config

-- 	local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
-- 	print(numGuildMembers)
-- end)

-- -- store in bdlc



-- function bdlc:Config()

-- 	-- pull guild info ranks
	
-- 	local listOfRanks = {}
-- 	config.init = false
-- 	config:SetScript("OnShow",function()
-- 		if (config.init) then return end
-- 		local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		
-- 		for i =1, numGuildMembers do
-- 			local name, rank, rankIndex, _, class = GetGuildRosterInfo(i)
-- 			listOfRanks[rankIndex] = rank
-- 		end
		
-- 		-------------------------
-- 		-- Create rank dropdown
-- 		-------------------------
-- 		local info = {
-- 			label = "Minimum LC Guild Rank",
-- 			options = listOfRanks,
-- 			callback = bdlc:sendLC()
-- 		}
-- 		bdlc:createDropdown("lc_rank", info)
		
		
-- 		-------------------------
-- 		-- Create custom council list
-- 		-------------------------
-- 		local info = {
-- 			label = "Custom Council",
-- 			options = bdlc.config.custom_council,
-- 			callback = bdlc:sendLC()
-- 		}
-- 		bdlc:createList("custom_council", info)
		
-- 		-------------------------
-- 		-- Create custom quick-notes
-- 		-------------------------
-- 		local info = {
-- 			label = "Quick Buttons",
-- 			options = bdlc.config.quick_notes,
-- 			callback = bdlc:sendLC()
-- 		}
-- 		bdlc:createList("quick_notes", info)
		
		
-- 		-- make sure this doesn't run twice
-- 		config.init = true
-- 	end)

-- 	bdlc.config_window = config
-- end

-- local media = {
-- 	flat = "Interface\\Buttons\\WHITE8x8",
-- 	font = "Interface\\Addons\\BigDumbLootCouncil\\media\\font.ttf",
-- 	arrowup = "Interface\\Addons\\BigDumbLootCouncil\\media\\arrow.blp",
-- 	arrowdown = "Interface\\Addons\\BigDumbLootCouncil\\media\\arrow.blp",
-- 	border = {.06, .08, .09, 1},
-- 	backdrop = {.11,.15,.18, 1},
-- 	red = {.62,.17,.18,1},
-- 	blue = {.2, .4, 0.8, 1},
-- 	green = {.1, .7, 0.3, 1},
-- }



