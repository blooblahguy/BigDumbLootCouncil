local bdlc, l, c = select(2, ...):unpack()

function bdlc:Config()
	-- Config window
	bdlcconfig = CreateFrame('frame', 'BDLC Config', UIParent)
	bdlcconfig:SetFrameStrata("HIGH")
	bdlcconfig:SetFrameLevel(9)
	bdlcconfig.SetFrameLevel = function() return end
	bdlcconfig:SetSize(320, 550);
	bdlcconfig:SetPoint("CENTER");
	bdlcconfig:EnableMouse(true);
	bdlcconfig:SetMovable(true);
	bdlcconfig:SetUserPlaced(true);
	bdlcconfig:SetClampedToScreen(true);
	bdlcconfig:RegisterForDrag("LeftButton","RightButton")
	bdlcconfig:SetScript("OnDragStart", function(self) bdlcconfig:StartMoving() end)
	bdlcconfig:SetScript("OnDragStop", function(self)  bdlcconfig:StopMovingOrSizing() end)

	bdlc:skinBackdrop(bdlcconfig);
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

	GuildRoster()
	local listOfRanks = {}
	bdlcconfig.init = false
	bdlcconfig:SetScript("OnShow",function()
		if (bdlcconfig.init) then return end
		local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
		
		for i =1, numGuildMembers do
			local name, rank, rankIndex, _, class = GetGuildRosterInfo(i)
			listOfRanks[rankIndex] = rank
		end
		
		-------------------------
		-- Create rank dropdown
		-------------------------
		local info = {
			label = "Minimum LC Guild Rank",
			options = listOfRanks,
			callback = bdlc:buildLC()
		}
		bdlc:createDropdown("lc_rank", info)
		
		
		-------------------------
		-- Create custom council list
		-------------------------
		local info = {
			label = "Custom Council",
			options = bdlc_config.custom_council,
			callback = bdlc:buildLC()
		}
		bdlc:createList("custom_council", info)
		
		-------------------------
		-- Create custom quick-notes
		-------------------------
		local info = {
			label = "Quick Buttons",
			options = bdlc_config.custom_qn,
			callback = bdlc:buildLC()
		}
		bdlc:createList("custom_qn", info)
		
		
		-- make sure this doesn't run twice
		bdlcconfig.init = true
	end)
end

local media = {
	flat = "Interface\\Buttons\\WHITE8x8",
	font = "Interface\\Addons\\BigDumbLootCouncil\\font.ttf",
	arrowup = "Interface\\Addons\\BigDumbLootCouncil\\arrowup.blp",
	arrowdown = "Interface\\Addons\\BigDumbLootCouncil\\arrowdown.blp",
	border = {.06, .08, .09, 1},
	backdrop = {.11,.15,.18, 1},
	red = {.62,.17,.18,1},
	blue = {.2, .4, 0.8, 1},
	green = {.1, .7, 0.3, 1},
}

function bdlc:createDropdown(option, info)
	local panel = bdlcconfig
	--local items = {strsplit(",",info.options)}
	local items = info.options
	local container = CreateFrame("Button",nil, panel)
	local dropdown = CreateFrame("Frame", "BDLC_"..option, panel)
	container:SetWidth(300)
	container:SetHeight(20)
	bdlc:skinBackdrop(container)
	if (not panel.lastFrame) then
		container:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -50)
	else
		container:SetPoint("TOP", panel.lastFrame, "BOTTOM", 0, -50)
	end
	panel.lastFrame = container
	panel.lastFrame.type = "dropdown"
	
	container.arrow = container:CreateTexture(nil,"OVERLAY")
	container.arrow:SetTexture(media.arrowdown)
	container.arrow:SetSize(8, 6)
	container.arrow:SetVertexColor(1,1,1,.4)
	container.arrow:SetPoint("RIGHT", container, "RIGHT", -6, 1)
	container.arrow:Show()
	
	container.label = container:CreateFontString(nil)
	container.label:SetFont(media.font, 14)
	container.label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 4)
	container.label:SetText(info.label)
	
	container.selected = container:CreateFontString(nil)
	container.selected:SetFont(media.font, 13)
	container.selected:SetPoint("LEFT", container, "LEFT", 6, 0)
	container.selected:SetText(bdlc_config[option])
	
	function container:click()
		if (dropdown.dropped) then
			dropdown:Hide()
			dropdown.dropped = false
			container:SetBackdropColor(.11,.15,.18, 1)
			container.arrow:SetTexture(media.arrowdown)
		else
			dropdown:Show()
			dropdown.dropped = true
			container:SetBackdropColor(1,1,1,.05)
			container.arrow:SetTexture(media.arrowup)
		end
	end
	
	container:SetScript("OnClick", function() container:click()end)

	dropdown:Hide()
	dropdown:SetFrameLevel(55)
	dropdown:SetBackdrop({
		bgFile = media.flat, 
		edgeFile = media.flat, edgeSize = 2,
		insets = { left = 2, right = 2, top = 2, bottom = 2 }
	})
	dropdown:SetBackdropColor(.18,.22,.25,1)
	dropdown:SetBackdropBorderColor(.06, .08, .09, 1)
	dropdown.dropped = false
	dropdown.lastframe = false
	dropdown:SetSize(container:GetWidth()+4, 22*#items)

	for i = 1, #items do
		local item = CreateFrame("Button", nil, dropdown)
		item:SetSize(dropdown:GetWidth()-4, 20)
		item:SetBackdrop({bgFile = media.flat, })
		item:SetBackdropColor(0,0,0,0)
		item:SetScript("OnEnter",function() item:SetBackdropColor(.21,.25,.29,1) end)
		item:SetScript("OnLeave",function() item:SetBackdropColor(0,0,0,0) end)
		item.label = item:CreateFontString(nil)
		item.label:SetFont(media.font, 13)
		item.label:SetPoint("LEFT", item, "LEFT", 6, 0)
		item.label:SetText(i..": "..items[i])
		item.id = i
		if (not dropdown.lastFrame) then
			item:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 2, -2)
		else
			item:SetPoint("TOPLEFT", dropdown.lastFrame, "BOTTOMLEFT", 0, 0)
		end
		
		item:SetScript("OnClick", function(self)
			bdlc_config[option] = self.label:GetText()
			
			if (info.callback) then
				info:callback()
			end
		
			container.selected:SetText(bdlc_config[option])
			container:click()
		end)
		
		dropdown.lastFrame = item
	end

	dropdown:SetPoint("TOPLEFT", container, "BOTTOMLEFT", -2, 1)
	return dropdown
end

function bdlc:createList(option,info)
	local panel = bdlcconfig
	
	local container = CreateFrame("frame",nil,panel)
	container:SetSize(300,160)
	bdlc:skinBackdrop(container)
	container:SetBackdropColor(.18,.22,.25,1)
	if (not panel.lastFrame) then
		container:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -30)
	else
		container:SetPoint("TOP", panel.lastFrame, "BOTTOM", 0, -70)
	end
	panel.lastFrame = container
	panel.lastFrame.type = "list"
	
	--scrollframe 
	local scrollframe = CreateFrame("ScrollFrame", nil, container) 
	scrollframe:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -6) 
	scrollframe:SetSize(container:GetWidth(), container:GetHeight()-12) 
	container.scrollframe = scrollframe 

	--scrollbar 
	local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPRIGHT", container, "TOPRIGHT", -2, -18) 
	scrollbar:SetPoint("BOTTOMLEFT", container, "BOTTOMRIGHT", -18, 18) 
	scrollbar:SetMinMaxValues(1, 600) 
	scrollbar:SetValueStep(1) 
	scrollbar.scrollStep = 1
	scrollbar:SetValue(0) 
	scrollbar:SetWidth(16) 
	scrollbar:SetScript("OnValueChanged", function (self, value) self:GetParent():SetVerticalScroll(value) self:SetValue(value) end) 
	scrollbar:SetBackdrop({bgFile = media.flat})
	scrollbar:SetBackdropColor(0,0,0,.2)
	container.scrollbar = scrollbar 

	--content frame 
	container.content = CreateFrame("Frame", nil, scrollframe) 
	container.content:SetSize(container:GetWidth(), container:GetHeight()) 
	scrollframe.content = container.content 
	scrollframe:SetScrollChild(container.content)
	
	container.content.text = container.content:CreateFontString(nil)
	container.content.text:SetFont(media.font,12)
	container.content.text:SetPoint("TOPLEFT",container.content,"TOPLEFT",5,0)
	container.content.text:SetHeight(600)
	container.content.text:SetWidth(container:GetWidth()-10)
	container.content.text:SetJustifyH("LEFT")
	container.content.text:SetJustifyV("TOP")
	
	
	container.insert = CreateFrame("EditBox",nil,container)
	container.insert:SetPoint("BOTTOMLEFT", container, "TOPLEFT",0,2)
	container.insert:SetSize(234, 24)
	bdlc:skinBackdrop(container.insert)
	container.insert:SetBackdropColor(.10,.14,.17,1)
	container.insert:SetFont(media.font,12)
	container.insert:SetTextInsets(6, 2, 2, 2)
	container.insert:SetMaxLetters(200)
	container.insert:SetHistoryLines(1000)
	container.insert:SetAutoFocus(false) 
	container.insert:SetScript("OnEnterPressed", function(self, key) container.button:Click() end)
	container.insert:SetScript("OnEscapePressed", function(self, key) self:ClearFocus() end)
	
	-- submit
	container.button = CreateFrame("Button", nil, container)
	container.button:SetPoint("TOPLEFT", container.insert, "TOPRIGHT", -1 ,0)
	container.button:SetSize(68, 24)
	container.button:SetBackdrop({
		bgFile = media.flat, 
		edgeFile = media.flat, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	container.button:SetBackdropColor(unpack(media.blue))
	container.button:SetBackdropBorderColor(unpack(media.border))
	container.button:SetAlpha(0.8)
	container.button:EnableMouse(true)
	container.button:SetScript("OnEnter", function()
		container.button:SetAlpha(1)
	end)
	container.button:SetScript("OnLeave", function()
		container.button:SetAlpha(0.8)
	end)
	container.button:SetScript("OnClick", function()
		local value = container.insert:GetText()
		if (strlen(value) > 0) then
			container.addremove(container.insert:GetText())
		end
		container.insert:SetText("")
		container.insert:ClearFocus()
	end)

	container.button.x = container.button:CreateFontString(nil)
	container.button.x:SetFont(media.font, 12)
	container.button.x:SetText("Add/Remove")
	container.button.x:SetPoint("CENTER", container.button, "CENTER", 1, 0)
	
	container.insert.alert = container.insert:CreateFontString(nil)
	container.insert.alert:SetFont(media.font,13)
	container.insert.alert:SetPoint("TOPLEFT",container,"BOTTOMLEFT", 2, -2)
	
	container.label = container:CreateFontString(nil)
	container.label:SetFont(media.font, 14)
	container.label:SetPoint("BOTTOMLEFT", container.insert, "TOPLEFT", 0, 4)
	container.label:SetText(info.label)
	
	function container.populate()
		local string = "";
		local height = 0;
		
		for k, v in pairs(bdlc_config[option]) do
			string = string..k.."\n";
			height = height + 14
			container.insert:AddHistoryLine(k)
		end
		local scrollheight = height-200
		if (scrollheight < 1) then 
			scrollheight = 1 
			container.scrollbar:Hide()
		else
			container.scrollbar:Show()
			container:SetScript("OnMouseWheel", function(self, delta) self.scrollbar:SetValue(self.scrollbar:GetValue() - (delta*30)) end)
		end
		container.scrollbar:SetMinMaxValues(1,scrollheight)
		container.content.text:SetHeight(height)
		container.content.text:SetText(string)
	end
	function container.startfade(self)
		local total = 0
		local alert = self.insert.alert
		alert:Show()
		container:SetScript("OnUpdate",function(self, elapsed)
			total = total + elapsed
			if (total > 1.5) then
				alert:SetAlpha(alert:GetAlpha()-0.02)
				
				if (alert:GetAlpha() <= 0.05) then
					container:SetScript("OnUpdate", function() return end)
					alert:Hide()
				end
			end
		end)
	end
	function container.addremove(value)
		container.insert:AddHistoryLine(value)
		if(bdlc_config[option][value]) then
			bdlc_config[option][value] = nil
			
			container.insert.alert:SetText(value.." removed")
			container.insert.alert:SetTextColor(1, .3, .3)
			container:startfade()
		else
			bdlc_config[option][value] = true
			container.insert.alert:SetText(value.." added")
			container.insert.alert:SetTextColor(.3, 1, .3)
			container:startfade()
		end
		container.populate()
		
		bdlc:buildLC()
	end
	
	container.populate()
	
	if (info.callback) then
		info:callback()
	end
end