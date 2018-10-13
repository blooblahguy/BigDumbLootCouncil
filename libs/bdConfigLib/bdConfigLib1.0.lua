--[[======================================================




	curse.com/
	bdConfigLib Main Usage

	bdConfigLib:RegisterModule(settings, configuration, savedVariable[, savedVariableAcct])

	settings
		name : name of the module in the configuration window
		command : /command that opens configuration to your module
		init : function callback for when configuration is initialized
		callback : function callback for when a configuration changes
	configuration : table of the configuration options for this module
		tab
		text
		list
		dropdown
	savedVariable : Per character SavedVariable




========================================================]]

local addonName, addon = ...
local _G = _G
local version = 10

if _G.bdConfigLib and _G.bdConfigLib.version >= version then
	bdConfigLib = _G.bdConfigLib
	return -- a newer or same version has already been created, ignore this file
end

_G.bdConfigLib = {}
bdConfigLib = _G.bdConfigLib
bdConfigLib.version = version
local config = _G.bdConfigLib

--[[======================================================
	Create Library
========================================================]]
local function debug(...)
	print("|cffA02C2FbdConfigLib|r:", ...)
end
--[[======================================================
	Helper functions & variables
========================================================]]
config.dimensions = {
	left_column = 150
	, right_column = 600
	, height = 450
	, header = 30
}
config.media = {
	flat = "Interface\\Buttons\\WHITE8x8"
	, arrow = "Interface\\Buttons\\Arrow-Down-Down.PNG"
	, font = "fonts\\ARIALN.ttf"
	, fontSize = 14
	, fontHeaderScale = 1.1
	, border = {0.06, 0.08, 0.09, 1}
	, borderSize = 1
	, background = {0.11, 0.15, 0.18, 1}
	, red = {0.62, 0.17, 0.18, 1}
	, blue = {0.2, 0.4, 0.8, 1}
	, green = {0.1, 0.7, 0.3, 1}
}

-- main font object
config.font = CreateFont("bdConfig_font")
config.font:SetFont(config.media.font, config.media.fontSize)
config.font:SetShadowColor(0, 0, 0)
config.font:SetShadowOffset(1, -1)
config.foundBetterFont = false

config.arrow = UIParent:CreateTexture(nil, "OVERLAY")
config.arrow:SetTexture(config.media.arrow)
config.arrow:SetTexCoord(0.9, 0.9, 0.9, 0.6)
config.arrow:SetVertexColor(1,1,1,0.5)

-- dirty create shadow (no external textures)
local function CreateShadow(frame, size)
	if (frame.shadow) then return end

	frame.shadow = {}
	local start = 0.088
	for s = 1, size do
		local shadow = frame:CreateTexture(nil, "BACKGROUND")
		shadow:SetTexture(config.media.flat)
		shadow:SetVertexColor(0,0,0,1)
		shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -s, s)
		shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", s, -s)
		shadow:SetAlpha(start - ((s / size) * start))
		frame.shadow[s] = shadow
	end
end

-- create consistent with border
local function CreateBackdrop(frame)
	if (frame.bd_background) then return end

	local background = frame:CreateTexture(nil, "BORDER", -1)
	background:SetTexture(config.media.flat)
	background:SetVertexColor(unpack(config.media.background))
	background:SetAllPoints()
	
	local border = frame:CreateTexture(nil, "BACKGROUND", -8)
	border:SetTexture(config.media.flat)
	border:SetVertexColor(unpack(config.media.border))
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -config.media.borderSize, config.media.borderSize)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", config.media.borderSize, -config.media.borderSize)

	frame.bd_background = background
	frame.bd_border = border

	return frame
end

-- creates basic button template
local function CreateButton(parent)
	if (not parent) then parent = config.window end
	local button = CreateFrame("Button", nil, parent)

	button.inactiveColor = config.media.blue
	button.activeColor = config.media.blue
	button:SetBackdrop({bgFile = config.media.flat})

	function button:BackdropColor(r, g, b, a)
		button.inactiveColor = self.inactiveColor or config.media.blue
		button.activeColor = self.activeColor or config.media.blue

		if (r and b and g) then
			self:SetBackdropColorOld(r, g, b, a)
		end
	end

	button.SetBackdropColorOld = button.SetBackdropColor
	button.SetBackdropColor = button.BackdropColor
	button.SetVertexColor = button.BackdropColor

	button:SetBackdropColor(unpack(config.media.blue))
	button:SetAlpha(0.6)
	button:SetHeight(config.dimensions.header)
	button:EnableMouse(true)

	button.text = button:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	button.text:SetPoint("CENTER")
	button.text:SetJustifyH("CENTER")
	button.text:SetJustifyV("MIDDLE")

	function button:Select()
		button.SetVertexColor(unpack(self.activeColor))
	end
	function button:Deselect()
		button.SetVertexColor(unpack(self.inactiveColor))
	end
	function button:OnEnter()
		if (self.active) then
			button:SetBackdropColor(unpack(self.activeColor))
		else
			if (self.hoverColor) then
				button:SetBackdropColor(unpack(self.hoverColor))
			else
				button:SetBackdropColor(unpack(self.inactiveColor))
			end
		end
		button:SetAlpha(1)
	end

	function button:OnLeave()
		if (self.active) then
			button:SetBackdropColor(unpack(self.activeColor))
			button:SetAlpha(1)
		else
			button:SetBackdropColor(unpack(self.inactiveColor))
			button:SetAlpha(0.6)
		end
	end
	function button:OnClickDefault()
		if (self.OnClick) then self.OnClick(self) end
		if (self.autoToggle) then
			if (self.active) then
				self.active = false
			else
				self.active = true
			end
		end

		button:OnLeave()
	end
	function button:GetText()
		return button.text:GetText()
	end
	function button:SetText(text)
		button.text:SetText(text)
		button:SetWidth(button.text:GetStringWidth() + config.dimensions.header)
	end

	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)
	button:SetScript("OnClick", button.OnClickDefault)
	-- button.text.SetText = button.SetText
	-- button.text.GetText = button.GetText

	return button
end


--[[========================================================
	Create Frames
	For anyone curious, I use `do` statements just to 
		keep the code dileniated and easy to read
==========================================================]]
local function CreateFrames()
	local window = CreateFrame("Frame", "bdConfig Lib", UIParent)

	-- Parent
	do
		window:SetPoint("RIGHT", UIParent, "RIGHT", -20, 0)
		window:SetSize(config.dimensions.left_column + config.dimensions.right_column, config.dimensions.height + config.dimensions.header)
		window:SetMovable(true)
		window:SetUserPlaced(true)
		window:SetFrameStrata("DIALOG")
		window:SetClampedToScreen(true)
		-- window:Hide()
		-- CreateBackdrop(window)
		CreateShadow(window, 10)
	end

	-- Header
	do
		window.header = CreateFrame("frame", nil, window)
		window.header:SetPoint("TOPLEFT")
		window.header:SetPoint("TOPRIGHT")
		window.header:SetHeight(config.dimensions.header)
		window.header:RegisterForDrag("LeftButton", "RightButton")
		window.header:EnableMouse(true)
		window.header:SetScript("OnDragStart", function(self) window:StartMoving() end)
		window.header:SetScript("OnDragStop", function(self) window:StopMovingOrSizing() end)
		window.header:SetScript("OnMouseUp", function(self) window:StopMovingOrSizing() end)
		CreateBackdrop(window.header)

		window.header.text = window.header:CreateFontString(nil, "OVERLAY", "bdConfig_font")
		window.header.text:SetPoint("LEFT", 10, 0)
		window.header.text:SetJustifyH("LEFT")
		window.header.text:SetText("Addon Configuration")
		window.header.text:SetJustifyV("MIDDLE")
		window.header.text:SetScale(config.media.fontHeaderScale)

		window.header.close = CreateButton(window.header)
		window.header.close:SetPoint("TOPRIGHT", window.header)
		window.header.close:SetText("x")
		window.header.close.inactiveColor = config.media.red
		window.header.close:OnLeave()
		window.header.close.OnClick = function()
			window:Hide()
		end

		window.header.reload = CreateButton(window.header)
		window.header.reload:SetPoint("TOPRIGHT", window.header.close, "TOPLEFT", -config.media.borderSize, 0)
		window.header.reload:SetText("Reload UI")
		window.header.reload.inactiveColor = config.media.green
		window.header.reload:OnLeave()
		window.header.reload.OnClick = function()
			ReloadUI();
		end

		window.header.lock = CreateButton(window.header)
		window.header.lock:SetPoint("TOPRIGHT", window.header.reload, "TOPLEFT", -config.media.borderSize, 0)
		window.header.lock:SetText("Unlock")
		window.header.lock.autoToggle = true
		window.header.lock.OnClick = function(self)
			if (self:GetText() == "Lock") then
				self:SetText("Unlock")
			else
				self:SetText("Lock")
			end
		end
	end

	-- Left Column
	do
		window.left = CreateFrame( "Frame", nil, window)
		window.left:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -config.dimensions.header-config.media.borderSize)
		window.left:SetSize(config.dimensions.left_column, config.dimensions.height)
		CreateBackdrop(window.left)
	end

	-- Right Column
	do
		window.right = CreateFrame( "Frame", nil, window)
		window.right:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, -config.dimensions.header-config.media.borderSize)
		window.right:SetSize(config.dimensions.right_column-config.media.borderSize, config.dimensions.height)
		CreateBackdrop(window.right)
		window.right.bd_background:SetVertexColor(unpack(config.media.border))
	end

	return window
end

local function FindBetterFont()
	if (config.foundBetterFont) then return end
	local font = false

	if (bdCore) then
		font = bdCore.media.font
	elseif (bdlc) then
		font = bdlc.font
	end

	if (font) then
		config.foundBetterFont = true
		config.font:SetFont(font, config.media.fontSize)
	end
end

local function RegisterModule(self, settings, configuration, savedVariable)
	local enabled, loaded = IsAddOnLoaded(addonName)
	if (not loaded) then
		debug("Addon", addonName, "saved variables not loaded yet, make sure you wrap your addon inside of an ADDON_LOADED event.")
		return
	end

	if (not settings.name) then 
		debug("When addind a module, you must include a name in the settings table.")
		return
	end
	if (not configuration) then 
		debug("When addind a module, you must include a configuration table to outline it's options.")
		return
	end
	if (not savedVariable) then 
		debug("When addind a module, you must include a savedVariable reference so that your settings can be saved.")
		return
	end

	-- see if we can upgrade font object here
	FindBetterFont()

	--[[======================================================
		Create Module Frame and Methods
	========================================================]]
	local module = {}
	module.settings = settings
	module.name = settings.name
	module.configuration = configuration
	module.savedVariable = savedVariable
	do
		module.tabs = {}
		module.tabContainer = false
		module.pageContainer = false
		module.link = false
		module.lastTab = false

		function module:Select()
			if (module.active) then return end

			-- Unselect all modules
			for name, otherModule in pairs(config.modules) do
				otherModule:Unselect()

				for k, t in pairs(otherModule.tabs) do
					t:Unselect()
				end
			end

			-- Show this module
			module.active = true
			module.link.active = true
			module.tabContainer:Show()

			-- Select first tab
			module.tabs[1]:Select()
		end

		-- for when hiding
		function module:Unselect()
			module.tabContainer:Hide()
			module.active = false
			module.link.active = false
		end

		-- Create page and tabs container
		do
			local tabContainer = CreateFrame("frame", nil, config.window.right)
			tabContainer:SetPoint("TOPLEFT")
			tabContainer:SetPoint("TOPRIGHT")
			tabContainer:Hide()
			tabContainer:SetHeight(config.dimensions.header)
			CreateBackdrop(tabContainer)
			local r, g, b, a = unpack(config.media.background)
			tabContainer.bd_border:Hide()
			tabContainer.bd_background:SetVertexColor(r, g, b, 0.5)

			module.tabContainer = tabContainer
		end
		
		-- Create page / tab
		function module:CreateTab(name)
			local index = #module.tabs + 1

			-- create scrollable page container to display tab's configuration options
			local page = CreateFrame("Frame", nil, scrollContainer) 
			do
				--parent frame 
				local scrollFrameParent = CreateFrame("Frame", nil, config.window.right) 
				scrollFrameParent:SetPoint("BOTTOMRIGHT")
				scrollFrameParent:SetPoint("BOTTOMLEFT")
				scrollFrameParent:SetHeight(config.dimensions.height - config.dimensions.header - config.media.borderSize)

				--scrollframe 
				scrollContainer = CreateFrame("ScrollFrame", nil, scrollFrameParent) 
				scrollContainer:SetPoint("TOPRIGHT", scrollFrameParent, "TOPRIGHT", 0, 0) 
				scrollContainer:SetSize(scrollFrameParent:GetWidth(), scrollFrameParent:GetHeight()) 
				scrollFrameParent.scrollframe = scrollContainer 

				--scrollbar 
				scrollbar = CreateFrame("Slider", nil, scrollContainer, "UIPanelScrollBarTemplate") 
				scrollbar:SetPoint("TOPRIGHT", scrollFrameParent, "TOPRIGHT", 0, -16) 
				scrollbar:SetPoint("BOTTOMRIGHT", scrollFrameParent, "BOTTOMRIGHT", 0, 16) 
				scrollbar:SetMinMaxValues(1, math.ceil(scrollFrameParent:GetHeight()+1)) 
				scrollbar:SetValueStep(1) 
				scrollbar.scrollStep = 1 
				scrollbar:SetValue(0) 
				scrollbar:SetWidth(16) 
				scrollbar:SetBackdrop({bgFile = config.media.flat})
				scrollbar:SetBackdropColor(0,0,0,.2)
				scrollFrameParent.scrollbar = scrollbar 

				--content frame 
				page:SetPoint("TOPLEFT", scrollFrameParent, "TOPLEFT")
				page:SetSize(scrollFrameParent:GetWidth() - 32, scrollFrameParent:GetHeight()) 
				scrollContainer.content = page 
				scrollContainer:SetScrollChild(page)

				-- scripts
				scrollbar:SetScript("OnValueChanged", function (self, value) 
					self:GetParent():SetVerticalScroll(value) 
				end)
				scrollFrameParent:SetScript("OnMouseWheel", function(self, delta)
					self.scrollbar:SetValue(self.scrollbar:GetValue() - (delta*20))
				end)

				-- to reference things
				page.scrollbar = scrollbar
				page.parent = scrollFrameParent

				page:Hide()
			end

			-- create tab to link to this page
			local tab = CreateButton(module.tabContainer)
			tab.inactiveColor = {1,1,1,0}
			tab.hoverColor = {1,1,1,0.1}
			tab:OnLeave()

			function tab:Select()
				-- tab:Show()
				tab.page:Show()
				tab.active = true
				tab.page.active = true
				tab:OnLeave()

				module.activePage = page
			end
			function tab:Unselect()
				-- tab:Hide()
				tab.page:Hide()
				tab.active = false
				tab.page.active = false
				tab:OnLeave()

				module.activePage = false
			end
			tab.OnClick = function()
				-- unselect / hide other tabs
				for i, t in pairs(module.tabs) do
					t:Unselect()
				end
				-- select this tab
				tab:Select()
			end
			tab:SetText(name)
			if (index == 1) then
				tab:SetPoint("LEFT", module.tabContainer, "LEFT", 0, 0)
			else
				tab:SetPoint("LEFT", module.tabs[index - 1], "RIGHT", 1, 0)
			end

			-- give data to the objects
			tab.page, tab.name, tab.index = page, name, index
			page.tab, page.name, page.index = tab, name, index

			-- append to tab storage
			module.activePage = page
			module.tabs[index] = tab

			return index
		end

		-- Create module navigation link
		do
			local link = CreateButton(config.window.left)
			link.inactiveColor = {0, 0, 0, 0}
			link.hoverColor = {1, 1, 1, .2}
			link:OnLeave()
			link.OnClick = module.Select
			link:SetText(settings.name)
			link:SetWidth(config.dimensions.left_column)
			link.text:SetPoint("LEFT", link, "LEFT", 6, 0)
			if (not config.lastLink) then
				link:SetPoint("TOPLEFT", config.window.left, "TOPLEFT")
				config.firstLink = link
			else
				link:SetPoint("TOPLEFT", config.lastLink, "BOTTOMLEFT")
			end

			config.lastLink = link
			module.link = link
		end
	end

	-- Caps/hide the scrollbar as necessary
	function module:SetPageScroll()
		if (#module.tabs == 0) then return end
		local page = module.activePage or module.tabs[#module.tabs].page
		local height = 0
		if (page.rows) then
			for k, container in pairs(page.rows) do
				height = height + container:GetHeight()
			end
		end

		if (#module.tabs > 0) then
			-- make the scrollbar only scroll the height of the page
			page.scrollbar:SetMinMaxValues(1, math.max(1, height - config.dimensions.height - config.dimensions.header))

			-- if the size of the page is lesser than it's height. don't show a scrollbar
			if ((height  - config.dimensions.height - config.dimensions.header) < 2) then
				page.scrollbar:Hide()
			end
		end
	end

	--[[======================================================
		Module main frames have been created
		1: CREATE / SET SAVED VARIABLES
			This includes setting up profile support
			Persistent config (non-profile)
			Defaults
	========================================================]]
	savedVariable = savedVariable or {}
	config.save = savedVariable
	local save = config.save

	-- player configuration
	save.user = save.user or {}
	save.user.name = UnitName("player")
	save.user.profile = save.user.profile or "default"
	save.user.spec_profile = save.user.spec_profile or {}
	save.user.spec_profile[1] = save.user.spec_profile[1] or false
	save.user.spec_profile[2] = save.user.spec_profile[2] or false
	save.user.spec_profile[3] = save.user.spec_profile[3] or false
	save.user.spec_profile[4] = save.user.spec_profile[4] or false

	-- profile configuration
	save.profiles = save.profiles or {}
	save.profiles['default'] = save.profiles['default'] or {}
	save.profiles.positions = save.profiles.positions or {}

	-- persistent configuration
	save.persistent = save.persistent or {}
	save.persistent.bd_config = save.persistent.bd_config or {} -- todo : let the user decide how the library looks and behaves

	-- shortcuts
	config.user = save.user
	config.persistent = save.persistent
	config.profile = save.profiles[config.user.profile]

	-- let's us access module inforomation quickly and easily
	function module:ElementInfo(option, info)
		local isPersistent = info.persistent or settings.persistent
		local page = module.tabs[#module.tabs].page
		local container = config:ElementContainer(page, info.type)

		local save
		if (isPersistent) then
			save = config.save.persistent[module.name][option]
		else
			save = config.save.profiles[config.save.user.profile][module.name][option]
		end

		-- print(save, container, isPersistent)
		-- save = save

		return save, container, isPersistent
	end
	
	--[[======================================================
		2: CREATE INPUTS AND DEFAULTS
			This includes setting up profile support
			Persistent config (non-profile)
			Defaults
	========================================================]]
	for k, conf in pairs(configuration) do
		-- loop through the configuration table to setup, tabs, sliders, inputs, etc.
		for option, info in pairs(conf) do
			local isPersistent = info.persistent or settings.persistent
			if (isPersistent) then
				-- if variable is `persistent` its account-wide
				config.persistent[module.name] = config.persistent[module.name] or {}
				if (config.persistent[module.name][option] == nil) then
					if (info.value == nil) then
						info.value = {}
					end

					config.persistent[module.name][option] = info.value
				end
			else
				-- this is a per-character configuration
				config.profile[module.name] = config.profile[module.name] or {}
				if (config.profile[module.name][option] == nil) then
					if (info.value == nil) then
						info.value = {}
					end

					config.profile[module.name][option] = info.value
				end
			end

			-- Store callbacks and call them all togther
			local callbacks = {}
			if (info.callback) then
				callbacks[#callbacks + 1] = info.callback
			end
			if (settings.callback) then
				callbacks[#callbacks + 1] = settings.callback
			end
			info.callback = function()
				for k, fn in pairs(callbacks) do
					fn()
				end
			end
			
			-- If the very first entry is not a tab, then create a general tab/page container
			if (info.type ~= "tab" and #module.tabs == 0) then
				module:CreateTab("General")
			end

			-- Master Call (slider = config.SliderElement(config, module, option, info))
			local method = info.type:gsub("^%l", string.upper).."Element"
			if (config[method]) then
				config[method](config, module, option, info)
			else
				debug("No module defined for "..method)
			end
		end
	end
	

	--[[======================================================
		3: SETUP DISPLAY AND STORE MODULE
			If we only made 1 tab, hide the tabContianer an
			make the page take up the extra space
	========================================================]]
	module:SetPageScroll()
	
	-- If there aren't additional tabs, act like non exist and fill up space
	local current_tab = module.tabs[#module.tabs]
	if (current_tab.text:GetText() == "General") then
		module.tabContainer:Hide()
		current_tab.page.parent:SetHeight(config.dimensions.height - config.media.borderSize)
	end

	-- store in config
	config.modulesIndex[#config.modulesIndex + 1] = module
	config.modules[settings.name] = module

	if (settings.init) then
		setting.init(module)
	end
	local save
	if (settings.persistent) then
		save = config.save.persistent[module.name][option]
	else
		save = config.save.profiles[config.save.user.profile][module.name][option]
	end

	return save
end

--[[========================================================
	Load the Library Up
	For anyone curious, I use `do` statements just to 
	keep the code dileniated and easy to read.
==========================================================]]
do
	-- returns a list of modules currently loaded
	function config:GetModules()

	end

	-- Selects first module, hides column if only 1
	function config:OnShow()

	end

	-- create tables
	config.modules = {}
	config.modulesIndex = {}
	config.lastLink = false
	config.firstLink = false

	-- create frame objects
	config.window = CreateFrames()

	-- associate RegisterModule function
	config.RegisterModule = RegisterModule
end

--[[========================================================
	CONFIGURATION INPUT ELEMENT METHODS
	This is all of the methods that create user interaction 
	elements. When adding support for new modules, start here
==========================================================]]

--[[========================================================
	ELEMENT CONTAINER WITH `COLUMN` SUPPORT
==========================================================]]
function config:ElementContainer(page, element)
	local container = CreateFrame("frame", nil, page)
	local padding = 10
	local sizing = {
		text = 1.0
		, table = 1.0
		, slider = 0.5
		, checkbox = 0.33
		, color = 0.33
		, dropdown = 0.5
		, clear = 1.0
	}

	-- size the container ((pageWidth / %) - padding left)
	container:SetSize((page:GetWidth() * sizing[element]) - padding, 30)

	-- TESTING : shows a background around each container for debugging
	-- container:SetBackdrop({bgFile = config.media.flat})
	-- container:SetBackdropColor(.1, .8, .2, 0.1)

	-- place the container
	page.rows = page.rows or {}
	page.row_width = page.row_width or 0
	page.row_width = page.row_width + sizing[element]

	if (page.row_width > 1.0 or not page.lastContainer) then
		page.row_width = sizing[element]
		if (not page.lastContainer) then
			container:SetPoint("TOPLEFT", page, "TOPLEFT", padding, -padding)
		else
			container:SetPoint("TOPLEFT", page.lastRow, "BOTTOMLEFT", 0, -padding)
		end

		-- used to count / measure rows
		page.lastRow = container
		page.rows[#page.rows + 1] = container
	else
		container:SetPoint("TOPLEFT", page.lastContainer, "TOPRIGHT", padding, 0)
	end
	
	page.lastContainer = container
	return container
end

--[[========================================================
	ADDING NEW TABS / SETTING SCROLLFRAME
==========================================================]]
function config:TabElement(module, option, info)
	-- We're done with the current page contianer, cap it's slider/height and start a new tab / height
	module:SetPageScroll()

	-- add new tab
	module:CreateTab(info.value)
end

--[[========================================================
	TEXT ELEMENT FOR USER INFO
==========================================================]]
function config:TextElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)

	local text = container:CreateFontString(nil, "OVERLAY", "bdConfig_font")

	text:SetText(info.value)
	text:SetAlpha(0.8)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetAllPoints(container)

	local lines = math.ceil(text:GetStringWidth() / container:GetWidth())

	container:SetHeight( (lines * 14) + 10)

	return container
end

--[[========================================================
	CLEAR (clears the columns and starts a new row)
==========================================================]]
function config:ClearElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)

	container:SetHeight(5)

	return container
end

--[[========================================================
	TABLE ELEMENT
==========================================================]]
function config:TableElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)

	return container
end

--[[========================================================
	SLIDER ELEMENT
==========================================================]]
function config:SliderElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)

	local slider = CreateFrame("Slider", module.name.."_"..option, container, "OptionsSliderTemplate")
	slider:SetWidth(container:GetWidth())
	slider:SetHeight(14)
	slider:SetPoint("TOPLEFT", container ,"TOPLEFT", 0, -16)
	slider:SetOrientation('HORIZONTAL')
	slider:SetMinMaxValues(info.min, info.max)
	slider:SetObeyStepOnDrag(true)
	slider:SetValueStep(info.step)
	slider:SetValue(save)
	slider.tooltipText = info.tooltip

	local low = _G[slider:GetName() .. 'Low']
	local high = _G[slider:GetName() .. 'High']
	local label = _G[slider:GetName() .. 'Text']
	low:SetText(info.min);
	low:SetFontObject("bdConfig_font")
	low:ClearAllPoints()
	low:SetPoint("TOPLEFT",slider,"BOTTOMLEFT",0,-1)

	high:SetText(info.max);
	high:SetFontObject("bdConfig_font")
	high:ClearAllPoints()
	high:SetPoint("TOPRIGHT",slider,"BOTTOMRIGHT",0,-1)

	label:SetText(info.label);
	label:SetFontObject("bdConfig_font")
	
	slider.value = slider:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	slider.value:SetPoint("TOP", slider, "BOTTOM", 0, -2)
	slider.value:SetText(save)

	slider:Show()
	slider.lastValue = 0
	slider:SetScript("OnValueChanged", function(self)
		local newval = math.floor(slider:GetValue())

		if (slider.lastValue == newval) then return end
		slider.lastValue = newval

		if (save == newval) then -- throttle it changing on the same pixel
			return false
		end

		save = newval

		slider:SetValue(newval)
		slider.value:SetText(newval)
		
		info:callback()
	end)

	container:SetHeight(46)

	return container
end

--[[========================================================
	CHECKBOX ELEMENT
==========================================================]]
function config:CheckboxElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)
	container:SetHeight(25)

	local check = CreateFrame("CheckButton", module.name.."_"..option, container, "ChatConfigCheckButtonTemplate")
	check:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	local text = _G[check:GetName().."Text"]
	text:SetText(info.label)
	text:SetFontObject("bdConfig_font")
	text:ClearAllPoints()
	text:SetPoint("LEFT", check, "RIGHT", 2, 1)
	check.tooltip = info.tooltip;
	check:SetChecked(save)

	check:SetScript("OnClick", function(self)
		save = self:GetChecked()
		info:callback(check)
	end)

	return container
end

--[[========================================================
	COLORPICKER ELEMENT
==========================================================]]
function config:ColorElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)

	local picker = CreateFrame("button", nil, container)
	picker:SetSize(20, 20)
	picker:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 2, insets = {top = 2, right = 2, bottom = 2, left = 2}})
	picker:SetBackdropColor(unpack(save))
	picker:SetBackdropBorderColor(0,0,0,1)
	picker:SetPoint("LEFT", container, "LEFT", 0, 0)
	
	picker.callback = function(self, r, g, b, a)
		save = {r,g,b,a}
		picker:SetBackdropColor(r,g,b,a)

		info:callback()
		
		return r, g, b, a
	end
	
	picker:SetScript("OnClick",function()		
		HideUIPanel(ColorPickerFrame)
		local r, g, b, a = unpack(save)

		ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
		ColorPickerFrame:SetClampedToScreen(true)
		ColorPickerFrame.hasOpacity = true
		ColorPickerFrame.opacity = 1 - a
		ColorPickerFrame.old = {r, g, b, a}
		
		ColorPickerFrame.colorChanged = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1 - OpacitySliderFrame:GetValue()
			picker:callback(r, g, b, a)
		end

		ColorPickerFrame.func = colorChanged
		ColorPickerFrame.opacityFunc = colorChanged
		ColorPickerFrame.cancelFunc = function()
			local r, g, b, a = unpack(ColorPickerFrame.old) 
			picker:callback(r, g, b, a)
		end

		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame:EnableKeyboard(false)
		ShowUIPanel(ColorPickerFrame)
	end)
	
	picker.text = picker:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	picker.text:SetText(info.name)
	picker.text:SetPoint("LEFT", picker, "RIGHT", 8, 0)

	container:SetHeight(30)

	return container
end

--[[========================================================
	DROPDOWN ELEMENT
==========================================================]]
function config:DropdownElement(module, option, info)
	local save, container, persistent = module:ElementInfo(option, info)

	-- revert to blizzard dropdown for the time being
	local label = container:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	label:SetPoint("TOPLEFT", container, "TOPLEFT")
	label:SetText(info.label)
	container:SetHeight(45)

	local dropdown = CreateFrame("Button", module.name.."_"..option, container, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -15, -2)

	UIDropDownMenu_SetWidth(dropdown, container:GetWidth() - 20)
	UIDropDownMenu_SetText(dropdown, save or "test")
	UIDropDownMenu_JustifyText(dropdown, "LEFT")

	-- initialize options
	UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
		local selected = 0
		for i, item in pairs(info.options) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = item
			info.value = item
			if (item == save) then selected = i end

			info.func = function(self)
				print(self:GetID())
				UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
				CloseDropDownMenus()

				info:callback()
			end

			UIDropDownMenu_AddButton(info, level)
		end

		UIDropDownMenu_SetSelectedID(dropdown, selected)
	end)

	return container


end


-- Reference back just for safety
_G.bdConfigLib = config

--[[

function bdCore:createActionButton(group, option, info, persistent)
	local panel = bdConfig.modules[group].lastFrame

	local container = bdConfig:createContainer(panel)

	local create = CreateFrame("Button", nil, panel)
	create:SetPoint("TOPLEFT", container, "TOPLEFT")
	create:SetText(info.value)
	bdCore:skinButton(create, false, "blue")

	-- create:SetSize(tab.text:GetWidth()+30,26)

	create:SetScript("OnClick", function()
		if (info.callback) then
			info.callback()
		end

		configChange(group, option)
	end)

	return container:GetHeight()
end
function bdCore:createBox(group, option, info, persistent)
	local panel = bdConfig.modules[group].lastFrame
	local create = CreateFrame("EditBox",nil,panel)

	local container = bdConfig:createContainer(panel)


	create:SetSize(200,24)
	bdCore:setBackdrop(create)
	create.background:SetVertexColor(.10,.14,.17,1)
	create:SetFont(bdCore.media.font,12)
	create:SetText(info.value)
	create:SetTextInsets(6, 2, 2, 2)
	create:SetMaxLetters(200)
	create:SetHistoryLines(1000)
	create:SetAutoFocus(false) 
	create:SetScript("OnEnterPressed", function(self, key) create.button:Click() end)
	create:SetScript("OnEscapePressed", function(self, key) self:ClearFocus() end)

	create:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0)

	create.label = create:CreateFontString(nil)
	create.label:SetFont(bdCore.media.font, 12)
	create.label:SetText(info.description)
	create.label:SetPoint("BOTTOMLEFT", create, "TOPLEFT", 0, 4)

	create.button = CreateFrame("Button", nil, create)
	create.button:SetPoint("LEFT", create, "RIGHT", 4, 0)
	create.button:SetText(info.button)
	bdCore:skinButton(create.button, false, "blue")
	create.button:SetScript("OnClick", function()
		if (info.callback) then
			info:callback(create:GetText())
			create:SetText("")
		end

		configChange(group, option)
	end)


	return container:GetHeight()
end

function bdCore:createList(group, option, info, persistent)
	local panel = bdConfig.modules[group].lastFrame
	
	local container = bdConfig:createContainer(panel)
	container:SetHeight(200)

	-- bdCore:setBackdrop(container)

	local title = container:CreateFontString(nil)
	local insertbox = CreateFrame("EditBox",nil, container)
	local button = CreateFrame("Button", nil, container)
	local list = CreateFrame("frame", nil, container)
	
	title:SetFont(media.font, 14)
	title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	title:SetText(info.label)

	insertbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	insertbox:SetSize(container:GetWidth() - 66, 24)
	insertbox:SetFont(media.font,12)
	insertbox:SetTextInsets(6, 2, 2, 2)
	insertbox:SetMaxLetters(200)
	insertbox:SetHistoryLines(1000)
	insertbox:SetAutoFocus(false) 
	insertbox:SetScript("OnEnterPressed", function(self, key) button:Click() end)
	insertbox:SetScript("OnEscapePressed", function(self, key) self:ClearFocus() end)
	bdCore:setBackdrop(insertbox)
	insertbox.background:SetVertexColor(.10,.14,.17,1)

	insertbox.alert = insertbox:CreateFontString(nil)
	insertbox.alert:SetFont(bdCore.media.font,13)
	insertbox.alert:SetPoint("TOPRIGHT",container,"TOPRIGHT", -2, 0)

	function insertbox:startFade()
		local total = 0

		self.alert:Show()
		self:SetScript("OnUpdate",function(self, elapsed)
			total = total + elapsed
			if (total > 1.5) then
				self.alert:SetAlpha(self.alert:GetAlpha()-0.02)
				
				if (self.alert:GetAlpha() <= 0.05) then
					self:SetScript("OnUpdate", function() return end)
					self.alert:Hide()
				end
			end
		end)
	end

	button:SetPoint("TOPLEFT", insertbox, "TOPRIGHT", 0, 2)
	button:SetText("Add/Remove")
	bdCore:skinButton(button, false, "blue")
	insertbox:SetSize(container:GetWidth() - button:GetWidth() + 2, 24)

	button:SetScript("OnClick", function()
		local value = insertbox:GetText()

		if (strlen(value) > 0) then
			list:addRemove(insertbox:GetText())
		end

		insertbox:SetText("")
		insertbox:ClearFocus()
	end)

	list:SetPoint("TOPLEFT", insertbox, "BOTTOMLEFT", 0, -2)
	list:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")

	--scrollframe 
	local scrollframe = CreateFrame("ScrollFrame", nil, list) 
	scrollframe:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -5) 
	scrollframe:SetSize(list:GetWidth(), list:GetHeight() - 10) 
	list.scrollframe = scrollframe 

	--scrollbar 
	local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPRIGHT", list, "TOPRIGHT", -2, -18) 
	scrollbar:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", -18, 18) 
	scrollbar:SetMinMaxValues(1, 600) 
	scrollbar:SetValueStep(1) 
	scrollbar.scrollStep = 1
	scrollbar:SetValue(0) 
	scrollbar:SetWidth(16) 
	scrollbar:SetScript("OnValueChanged", function (self, value) self:GetParent():SetVerticalScroll(value) self:SetValue(value) end) 
	scrollbar:SetBackdrop({bgFile = media.flat})
	scrollbar:SetBackdropColor(0,0,0,.2)
	list.scrollbar = scrollbar 

	--content frame 
	list.content = CreateFrame("Frame", nil, scrollframe) 
	list.content:SetPoint("TOPLEFT", list, "TOPLEFT") 
	list.content:SetSize(list:GetWidth(), list:GetHeight()) 
	scrollframe.content = list.content
	scrollframe:SetScrollChild(list.content)
	
	list.text = list.content:CreateFontString(nil)
	list.text:SetFont(media.font,12)
	list.text:SetPoint("TOPLEFT", list.content, "TOPLEFT", 5, 0)
	list.text:SetHeight(600)
	list.text:SetWidth(list:GetWidth()-10)
	list.text:SetJustifyH("LEFT")
	list.text:SetJustifyV("TOP")

	list.text:SetText("test")


	bdCore:setBackdrop(list)

	-- show all config entries in this list
	function list:populate()
		local string = "";
		local height = 0;

		if (info.persistent or persistent) then
			for k, v in pairs(c.persistent[group][option]) do
				string = string..k.."\n";
				height = height + 13
			end
		else
			for k, v in pairs(c.profile[group][option]) do
				string = string..k.."\n";
				height = height + 13
			end
		end

		local scrollheight = height-200
		if (scrollheight < 1) then 
			scrollheight = 1 
			scrollbar:Hide()
		else
			scrollbar:Show()
			list:SetScript("OnMouseWheel", function(self, delta) self.scrollbar:SetValue(self.scrollbar:GetValue() - (delta*30)) end)
		end

		scrollbar:SetMinMaxValues(1,scrollheight)

		list.text:SetHeight(height)
		list.text:SetText(string)
	end

	-- remove or add something, then redraw the text
	function list:addRemove(value)
		if (info.persistent or persistent) then
			if (c.persistent[group][option][value]) then
				c.persistent[group][option][value] = nil
				insertbox.alert:SetText(value.." removed")
				insertbox.alert:SetTextColor(1, .3, .3)
				insertbox:startFade()
			else
				c.persistent[group][option][value] = true
				insertbox.alert:SetText(value.." added")
				insertbox.alert:SetTextColor(.3, 1, .3)
				insertbox:startFade()
			end
		else
			if (c.profile[group][option][value]) then
				c.profile[group][option][value] = nil
				insertbox.alert:SetText(value.." removed")
				insertbox.alert:SetTextColor(1, .3, .3)
				insertbox:startFade()
			else
				c.profile[group][option][value] = true
				insertbox.alert:SetText(value.." added")
				insertbox.alert:SetTextColor(.3, 1, .3)
				insertbox:startFade()
			end
		end
		self:populate()

		if (info.callback) then
			info:callback()
		end

		configChange(group, option)

		-- clear aura cache
		bdCore.caches.auras = {}
	end

	list:populate()

	return container:GetHeight()
end

--]]