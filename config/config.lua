local bdlc, c, l = unpack(select(2, ...))

local config = CreateFrame('frame', 'BDLC Config', UIParent, BackdropTemplateMixin and "BackdropTemplate")
config:SetFrameStrata("HIGH")
config:SetFrameLevel(9)
config:SetSize(500, 430)
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

-- main font object
bdlc.font = CreateFont("bdlc_font")
bdlc.font:SetFont(bdlc.media.font, 14, "THINOUTLINE")
bdlc.font:SetShadowColor(0, 0, 0)
bdlc.font:SetShadowOffset(1, -1)

-- Config Title
config.title = config:CreateFontString('nil', "OVERLAY")
config.title:SetFontObject(bdlc:get_font(16, "OUTLINE"))
config.title:SetText("|cffA02C2FBig|r Dumb Loot Council Config")
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
		['callback'] = function(dropdown, value, id)
			bdlc.config.council_min_rank = id
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
			value = bdlc:FetchUnitName(value)

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
	quick_notes:SetPoint("TOPLEFT", custom_council, "BOTTOMLEFT", 0, -70)

	--======================
	-- custom buttons
	--======================
	if (true == false) then
		config:SetHeight(config:GetHeight() + 170)
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