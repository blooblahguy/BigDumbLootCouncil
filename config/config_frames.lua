local bdlc, c, l = unpack(select(2, ...))


--- Opts:
---     name (string): Name of the dropdown (lowercase)
---     parent (Frame): Parent frame of the dropdown.
---     items (Table): String table of the dropdown options.
---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.
function bdlc:createDropdown(opts)
	local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
	local items = opts['items'] or {}
	local title = opts['title'] or ''
	local width = opts['width'] or 0
	local default = opts['default'] or ''
	local callback = opts['callback'] or function() end

	local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')
	local dd_title = dropdown:CreateFontString(dropdown, 'OVERLAY')
	dd_title:SetFontObject(bdlc:get_font(14))
	dd_title:SetPoint("TOPLEFT", 20, 10)
	dd_title:SetTextColor(1, 1, 1)

	if (width == 0) then
		for _, item in pairs(items) do -- Sets the dropdown width to the largest item string width.
			dd_title:SetText(item)
			local text_width = dd_title:GetStringWidth() + 20
			if text_width > width then
				width = text_width
			end
		end
	end

	UIDropDownMenu_SetWidth(dropdown, width)
	UIDropDownMenu_SetText(dropdown, default_val)
	dd_title:SetText(title)

	UIDropDownMenu_Initialize(dropdown, function(self, level, _)
		local info = UIDropDownMenu_CreateInfo()
		local selected = 0
		for key, val in pairs(items) do
			info.text = val;
			info.checked = false
			info.menuList= key
			info.hasArrow = false
			info.func = function(b)
				UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
				UIDropDownMenu_SetText(dropdown, b.value)
				b.checked = true
				callback(dropdown, b.value)
			end

			if (val == default) then
				selected = key
			end

			UIDropDownMenu_AddButton(info)
		end

		if (selected and selected ~= 0) then
			UIDropDownMenu_SetSelectedID(dropdown, selected)
		end
	end)

	return dropdown
end

function bdlc:createToggle(opts)
	local parent = opts['parent']
	local name = '$parent_' .. opts['name'] .. '_toggle'
	local title = opts['title'] or ''
	local width = opts['width'] or 0
	local default = opts['default'] or false
	local callback = opts['callback'] or function() end

	local check = CreateFrame("CheckButton", name, parent, "ChatConfigCheckButtonTemplate")
	check:SetChecked(default)
	check:SetScript("OnClick", callback)

	local text = _G[check:GetName().."Text"]
	text:SetText(title)
	text:SetFontObject(bdlc:get_font(14))
	text:ClearAllPoints()
	text:SetPoint("LEFT", check, "RIGHT", 2, -1)

	return check
end

function bdlc:createColor(opts)
	local parent = opts['parent']
	local name = '$parent_' .. opts['name'] .. '_color'
	local title = opts['title'] or ''
	local width = opts['width'] or 0
	local default = opts['default'] or {1, 1, 1}
	local callback = opts['callback'] or function() end

	local picker = CreateFrame("button", name, parent, BackdropTemplateMixin and "BackdropTemplate")
	picker:SetSize(20, 20)
	picker:SetBackdrop({bgFile = bdlc.media.flat, edgeFile = bdlc.media.flat, edgeSize = 2, insets = {top = 2, right = 2, bottom = 2, left = 2}})
	picker:SetBackdropBorderColor(0,0,0,1)
	picker:SetBackdropColor(unpack(default))
	
	picker:SetScript("OnClick", function(self)		
		HideUIPanel(ColorPickerFrame)
		local r, g, b, a = unpack(default)
		a = a or 1

		ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		ColorPickerFrame:SetClampedToScreen(true)
		ColorPickerFrame.hasOpacity = true
		ColorPickerFrame.opacity = 1 - a
		ColorPickerFrame.old = {r, g, b, a}
		
		local function colorChanged()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1 - OpacitySliderFrame:GetValue()
			a = a or 1

			picker:SetBackdropColor(r, g, b, a)
		end

		if (not ColorPickerOkayButton.confirm) then
			ColorPickerOkayButton.confirm = true
			ColorPickerOkayButton:HookScript("OnClick", function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = 1 - OpacitySliderFrame:GetValue()
				a = a or 1

				callback(picker, r, g, b, a)
				picker:SetBackdropColor(r, g, b, a)
			end)
		end

		ColorPickerFrame.func = colorChanged
		ColorPickerFrame.opacityFunc = colorChanged
		ColorPickerFrame.cancelFunc = function()
			local r, g, b, a = unpack(ColorPickerFrame.old) 
			a = a or 1

			callback(picker, r, g, b, a)
			picker:SetBackdropColor(r, g, b, a)
		end

		ColorPickerFrame:SetColorRGB(picker:GetBackdropColor())
		ColorPickerFrame:EnableKeyboard(false)
		ShowUIPanel(ColorPickerFrame)
	end)
	
	picker.text = picker:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	picker.text:SetText(title)
	picker.text:SetPoint("LEFT", picker, "RIGHT", 8, 0)
	picker.text:SetAlpha(0.8)

	return picker
end

function bdlc:createEdit(opts)
	local parent = opts['parent']
	local name = '$parent_' .. opts['name'] .. '_input'
	local title = opts['title'] or ''
	local width = opts['width'] or 0
	local default = opts['default'] or ''
	local callback = opts['callback'] or function() end

	local input = CreateFrame("EditBox", name, parent, BackdropTemplateMixin and "BackdropTemplate")
	input:SetSize(width, 24)
	input:SetFontObject(bdlc:get_font(14))
	input:SetText(default)
	input:SetTextInsets(6, 2, 2, 2)
	input:SetMaxLetters(200)
	input:SetHistoryLines(1000)
	input:SetAutoFocus(false) 
	input:SetScript("OnEditFocusLost", function(self, key) callback(self:GetText(), key) end)
	input:SetScript("OnEnterPressed", function(self, key) callback(self:GetText(), key); self:ClearFocus(); end)
	input:SetScript("OnEscapePressed", function(self, key) callback(self:GetText(), key); self:ClearFocus(); end)
	bdlc:setBackdrop(input)
	input:SetBackdropColor(.18,.22,.25,1)

	local label = input:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	label:SetText(title)
	label:SetPoint("BOTTOMLEFT", input, "TOPLEFT", 0, 0)

	return input
end


function bdlc:createList(opts)
	local parent = opts['parent']
	local name = '$parent_' .. opts['name'] .. '_list'
	local items = opts['items']
	local title = opts['title'] or ''
	local width = opts['width'] or 0
	local default = opts['default'] or ''
	local lower = opts['lower'] or false
	local callback = opts['callback'] or function() end
	
	local container = CreateFrame("frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	container:SetSize(width, 100)
	bdlc:setBackdrop(container)
	container:SetBackdropColor(.18,.22,.25,1)

	--scrollframe 
	local content = bdlc:createScrollFrame(container)
	content.scrollframe:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -4);
	content.scrollframe:SetSize(width, 120)
	content.scrollchild:SetSize(content.scrollframe:GetWidth(), (content.scrollframe:GetHeight() * 1.5 ));
	container.content = content.content
	bdlc:setBackdrop(content, .1,.2,.1,.8);
	
	container.content.text = container.content:CreateFontString(nil)
	container.content.text:SetFontObject(bdlc:get_font(12))
	container.content.text:SetPoint("TOPLEFT", container.content, "TOPLEFT", 5, 0)
	container.content.text:SetHeight(600)
	container.content.text:SetWidth(width)
	container.content.text:SetText("asdasdasdasd")
	container.content.text:SetWidth(container:GetWidth()-10)
	container.content.text:SetJustifyH("LEFT")
	container.content.text:SetJustifyV("TOP")
	
	container.insert = CreateFrame("EditBox", nil, container, BackdropTemplateMixin and "BackdropTemplate")
	container.insert:SetPoint("BOTTOMLEFT", container, "TOPLEFT",0,2)
	container.insert:SetSize(width - 68, 24)
	bdlc:setBackdrop(container.insert)
	container.insert:SetBackdropColor(.10,.14,.17,1)
	container.insert:SetFontObject(bdlc:get_font(12))
	container.insert:SetTextInsets(6, 2, 2, 2)
	container.insert:SetMaxLetters(200)
	container.insert:SetHistoryLines(1000)
	container.insert:SetAutoFocus(false) 
	container.insert:SetScript("OnEnterPressed", function(self, key) container.button:Click() end)
	container.insert:SetScript("OnEscapePressed", function(self, key) self:ClearFocus() end)
	
	-- submit
	container.button = CreateFrame("Button", nil, container, BackdropTemplateMixin and "BackdropTemplate")
	container.button:SetPoint("TOPLEFT", container.insert, "TOPRIGHT", -1 ,0)
	container.button:SetSize(68, 24)
	container.button:SetBackdrop({
		bgFile = bdlc.media.flat, 
		edgeFile = bdlc.media.flat, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	container.button:SetBackdropColor(unpack(bdlc.media.blue))
	container.button:SetBackdropBorderColor(unpack(bdlc.media.border))
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
		if (lower) then
			value = value:lower()
		end

		if (strlen(value) > 0) then
			callback(container, value)
		end
		container.insert:SetText("")
		container.insert:ClearFocus()
	end)

	container.button.x = container.button:CreateFontString(nil)
	container.button.x:SetFont(bdlc.media.font, 12)
	container.button.x:SetText("Add/Remove")
	container.button.x:SetPoint("CENTER", container.button, "CENTER", 1, 0)
	
	container.insert.alert = container.insert:CreateFontString(nil)
	container.insert.alert:SetFontObject(bdlc:get_font(13))
	container.insert.alert:SetPoint("TOPLEFT", container,"BOTTOMLEFT", 2, -2)
	
	container.label = container:CreateFontString(nil)
	container.label:SetFontObject(bdlc:get_font(14))
	container.label:SetPoint("BOTTOMLEFT", container.insert, "TOPLEFT", 0, 4)
	container.label:SetText(title)
	
	function container:populate(list)
		local str = "";
		local height = 0;
		
		for k, v in pairs(list) do
			local add = ""
			if (lower) then
				add = type(k) == "string" and k:lower() or v:lower()
			else
				add = type(k) == "string" and k or v
			end
			str = str..add.."\n";
			height = height + 14
			container.insert:AddHistoryLine(k)
		end

		container.content.text:SetHeight(height)
		container.content.text:SetText(str)
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
	
	container:populate(items)

	return container
end