local bdlc, f, c = select(2, ...):unpack()

function bdlc:Config()
	-- Config window
	bdlcconfig = CreateFrame('frame', 'BDLC Config', UIParent)
	bdlcconfig:SetFrameStrata("HIGH")
	bdlcconfig:SetFrameLevel(50)
	bdlcconfig:SetSize(400, 100);
	bdlcconfig:SetPoint("CENTER");
	bdlcconfig:EnableMouse(true);
	bdlcconfig:SetMovable(true);
	bdlcconfig:SetUserPlaced(true);
	bdlcconfig:SetClampedToScreen(true);
	bdlcconfig:RegisterForDrag("LeftButton","RightButton")
	bdlcconfig:SetScript("OnDragStart", function(self) bdlcconfig:StartMoving() end)
	bdlcconfig:SetScript("OnDragStop", function(self)  bdlcconfig:StopMovingOrSizing() end)

	bdlc:skinBackdrop(bdlcconfig, .1,.1,.1,.9);
	bdlcconfig:Hide();
	
	bdlcconfig.title = bdlcconfig:CreateFontString('nil', "OVERLAY", "BDLC_FONT")
	bdlcconfig.title:SetText("Big Dumb Config")
	bdlcconfig.title:SetTextColor(1,1,1)
	bdlcconfig.title:SetPoint("TOP", bdlcconfig, "TOP", 0,-6)
	
	bdlcconfig.close = CreateFrame("Button", nil, bdlcconfig)
	bdlcconfig.close:SetPoint("TOPRIGHT", bdlcconfig, "TOPRIGHT", -4, -4)
	bdlcconfig.close:SetText("x")
	bdlc:skinButton(bdlcconfig.close,true,"red")
	bdlcconfig.close:SetBackdropColor(.5,.1,.1,.5)
	bdlcconfig.close:SetScript("OnClick", function()
		bdlcconfig:Hide()
		bdlc_config_toggle = false
	end)

	
	-- Min Rank
	bdlcconfig.guildranks = CreateFrame("Button", "GuildRankDropdown", bdlcconfig, "UIDropDownMenuTemplate")
	bdlcconfig.guildranks:ClearAllPoints()
	bdlcconfig.guildranks:SetPoint("TOP", bdlcconfig, "TOP", 0, -50)
	bdlcconfig.guildranks:Show()
	bdlc:skinBackdrop(bdlcconfig.guildranks)
	bdlcconfig.guildranks.text = bdlcconfig.guildranks:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bdlcconfig.guildranks.text:SetTextColor(1,1,1)
	bdlcconfig.guildranks.text:SetPoint("BOTTOM", bdlcconfig.guildranks, "TOP", 0, 4)
	bdlcconfig.guildranks.text:SetText("Minimum rank to be included in Loot Council")
	
	GuildRoster()
	local listOfRanks = {}
	bdlcconfig:RegisterEvent("GUILD_ROSTER_UPDATE")
	bdlcconfig:SetScript("OnEvent", function(self,event,arg1)
		local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		for i =1, numGuildMembers do
			local name, rank, rankIndex, _, class = GetGuildRosterInfo(i)
			listOfRanks[rankIndex] = rank
		end
		
		local function OnClick(self)
			UIDropDownMenu_SetSelectedID(bdlcconfig.guildranks, self:GetID())
			bdlc_config.council_min_rank = self:GetID()
			SendAddonMessage(bdlc.message_prefix, "fetchLC", "RAID");
		end

		local function initialize(self, level)
			local info = UIDropDownMenu_CreateInfo()
			for i = 1, #listOfRanks do
				if (listOfRanks[i]) then 
					local v = listOfRanks[i]
					info = UIDropDownMenu_CreateInfo()
					info.text = v
					info.value = v
					info.func = OnClick

					UIDropDownMenu_AddButton(info, level)
				end
			end
			UIDropDownMenu_SetSelectedValue(self, bdlc_config.council_min_rank)
		end


		UIDropDownMenu_Initialize(bdlcconfig.guildranks, initialize, "MENU")
		UIDropDownMenu_SetWidth(bdlcconfig.guildranks,200);
		UIDropDownMenu_SetButtonWidth(bdlcconfig.guildranks, 224)
		UIDropDownMenu_SetSelectedValue(bdlcconfig.guildranks, bdlc_config.council_min_rank)
		UIDropDownMenu_SetSelectedID(bdlcconfig.guildranks, bdlc_config.council_min_rank)
		UIDropDownMenu_JustifyText(bdlcconfig.guildranks, "LEFT")
		
		bdlcconfig:UnregisterEvent("GUILD_ROSTER_UPDATE")
	end)
	
	-- Custom Council
	-- bdlcconfig.council = CreateFrame("EditBox", nil, bdlcconfig)
	-- bdlcconfig.council:SetSize(240, 48)
	-- bdlcconfig.council:IsMultiLine(1)
	-- bdlcconfig.council:SetPoint("TOPLEFT", bdlcconfig.guildranks, "BOTTOMLEFT", 8, 8)
	-- bdlcconfig.council:SetMaxLetters(200)
	-- bdlcconfig.council:SetTextInsets(6, 2, 2, 2)
	-- bdlcconfig.council:SetFontObject("BDLC_FONT")
	-- bdlcconfig.council:SetScript("OnEnterPressed", function(self, key) bdlcconfig.council:ClearFocus() end)
	-- bdlcconfig.council:SetScript("OnEscapePressed", function(self, key) bdlcconfig.council:ClearFocus() end)
	-- skinBackdrop(bdlcconfig.council, .1,.1,.1,.9);
	
	local councilstring = ''
	for k, v in pairs(bdlc_config.custom_council) do
		councilstring = councilstring..k..' '
	end
	--bdlcconfig.council:SetText(councilstring)


end