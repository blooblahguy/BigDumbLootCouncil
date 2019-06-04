--[[======================================================




	curse.com/
	bdConfigLib Main Usage

	bdConfigLib:RegisterModule(settings, configuration, "savedVariable")

	settings
		name : name of the module in the configuration window
		command : /command that opens configuration to your module
		init : function callback for when configuration is initialized
		callback : function callback for when a configuration changes
		returnType : By default it retuns your direct save table, but you can return the persistent and profile versions or "both" if needed
	configuration : table of the configuration options for this module
		tab
		text
		list
		dropdown
	savedVariable : Per character SavedVariable as a STRING ie SavedVariableName = "SavedVariableName"




========================================================]]

local addonName, addon = ...
local _G = _G
local version = 11

if _G.bdConfigLib and _G.bdConfigLib.version >= version then
	bdConfigLib = _G.bdConfigLib
	return -- a newer or same version has already been created, ignore this file
end

--[[======================================================
	Create Library
========================================================]]
_G.bdConfigLib = {}
_G.bdConfigLibProfiles = {}
_G.bdConfigLibSave = {}

bdConfigLib = _G.bdConfigLib
bdConfigLibSave = _G.bdConfigLibSave
bdConfigLibProfiles = _G.bdConfigLibProfiles
bdConfigLibProfiles.Selected = "default"
bdConfigLibProfiles.Profiles = {}
bdConfigLibProfiles.SavedVariables = {}
bdConfigLib.version = version

--[[======================================================
	Helper functions & variables
========================================================]]
bdConfigLib.dimensions = {
	left_column = 150
	, right_column = 600
	, height = 450
	, header = 30
	, padding = 10
}
local dimensions = bdConfigLib.dimensions

bdConfigLib.media = {
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
bdConfigLib.font = CreateFont("bdConfig_font")
bdConfigLib.font:SetFont(bdConfigLib.media.font, bdConfigLib.media.fontSize)
bdConfigLib.font:SetShadowColor(0, 0, 0)
bdConfigLib.font:SetShadowOffset(1, -1)
bdConfigLib.foundBetterFont = false

bdConfigLib.arrow = UIParent:CreateTexture(nil, "OVERLAY")
bdConfigLib.arrow:SetTexture(bdConfigLib.media.arrow)
bdConfigLib.arrow:SetTexCoord(0.9, 0.9, 0.9, 0.6)
bdConfigLib.arrow:SetVertexColor(1,1,1,0.5)

-- event system
-- custom events/hooks
bdConfigLib.events = {}
function bd_add_action(event, func)
	local events = strsplit(",", event) or {event}
	events = type(events) == "table" and events or {event}

	for i = 1, #events do
		e = events[i]
		if (not bdConfigLib.events[e]) then
			bdConfigLib.events[e] = {}
		end
		bdConfigLib.events[e][#bdConfigLib.events[e]+1] = func
	end
end

function bd_do_action(event,...)
	if (bdConfigLib.events[event]) then
		for k, v in pairs(bdConfigLib.events[event]) do
			v(...)
		end
	end
end

-- debug
local function debug(...)
	print("|cffA02C2FbdConfigLib|r:", ...)
end

-- dirty create shadow (no external textures)
local function CreateShadow(frame, size)
	if (frame.shadow) then return end

	frame.shadow = {}
	local start = 0.088
	for s = 1, size do
		local shadow = frame:CreateTexture(nil, "BACKGROUND")
		shadow:SetTexture(bdConfigLib.media.flat)
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
	background:SetTexture(bdConfigLib.media.flat)
	background:SetVertexColor(unpack(bdConfigLib.media.background))
	background:SetAllPoints()
	
	local border = frame:CreateTexture(nil, "BACKGROUND", -8)
	border:SetTexture(bdConfigLib.media.flat)
	border:SetVertexColor(unpack(bdConfigLib.media.border))
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -bdConfigLib.media.borderSize, bdConfigLib.media.borderSize)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", bdConfigLib.media.borderSize, -bdConfigLib.media.borderSize)

	frame.bd_background = background
	frame.bd_border = border

	return frame
end

-- creates basic button template
local function CreateButton(parent)
	if (not parent) then parent = bdConfigLib.window end
	local button = CreateFrame("Button", nil, parent)

	button.inactiveColor = bdConfigLib.media.blue
	button.activeColor = bdConfigLib.media.blue
	button:SetBackdrop({bgFile = bdConfigLib.media.flat})

	function button:BackdropColor(r, g, b, a)
		button.inactiveColor = self.inactiveColor or bdConfigLib.media.blue
		button.activeColor = self.activeColor or bdConfigLib.media.blue

		if (r and b and g) then
			self:SetBackdropColorOld(r, g, b, a)
		end
	end

	button.SetBackdropColorOld = button.SetBackdropColor
	button.SetBackdropColor = button.BackdropColor
	button.SetVertexColor = button.BackdropColor

	button:SetBackdropColor(unpack(bdConfigLib.media.blue))
	button:SetAlpha(0.6)
	button:SetHeight(bdConfigLib.dimensions.header)
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
		button:SetWidth(button.text:GetStringWidth() + bdConfigLib.dimensions.header)
	end

	button:SetScript("OnEnter", button.OnEnter)
	button:SetScript("OnLeave", button.OnLeave)
	button:SetScript("OnClick", button.OnClickDefault)

	return button
end

-- creates scroll frame and returns its content
function CreateScrollFrame(parent, width, height)
	width = width or parent:GetWidth()
	height = height or parent:GetHeight()

	-- scrollframe
	local scrollParent = CreateFrame("ScrollFrame", nil, parent) 
	scrollParent:SetPoint("TOPLEFT", parent) 
	scrollParent:SetSize(width - dimensions.padding, height) 
	--scrollbar 
	local scrollbar = CreateFrame("Slider", nil, scrollParent, "UIPanelScrollBarTemplate") 
	scrollbar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -18) 
	scrollbar:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", -18, 18) 
	scrollbar:SetMinMaxValues(1, 600)
	scrollbar:SetValueStep(1)
	scrollbar.scrollStep = 1
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	CreateBackdrop(scrollbar)
	parent.scrollbar = scrollbar
	--content frame 
	local content = CreateFrame("Frame", nil, scrollParent) 
	content:SetPoint("TOPLEFT", parent, "TOPLEFT") 
	content:SetSize(scrollParent:GetWidth() - (dimensions.padding * 2), scrollParent:GetHeight())
	scrollParent.content = content
	scrollParent:SetScrollChild(content)

	-- scripts
	scrollbar:SetScript("OnValueChanged", function (self, value) 
		self:GetParent():SetVerticalScroll(value) 
	end)
	scrollParent:SetScript("OnMouseWheel", function(self, delta)
		scrollbar:SetValue(scrollbar:GetValue() - (delta*20))
	end)
	-- auto resizing
	-- content.Update = function()
	-- 	local height = content:GetHeight()
	-- 	scrollbar:SetMinMaxValues(1, height)
	-- end
	-- content.SetSize = content.SetHeight
	-- content.Update = content.Update
	-- hooksecurefunc(content, "SetHeight", content.Update)
	-- hooksecurefunc(content, "SetSize", content.Update)

	-- store
	parent.scrollParent = scrollParent
	parent.scrollbar = scrollbar
	parent.content = content

	content.scrollParent = scrollParent
	content.scrollbar = scrollbar
	content.parent = parent

	return content
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
		window:SetSize(bdConfigLib.dimensions.left_column + bdConfigLib.dimensions.right_column, bdConfigLib.dimensions.height + bdConfigLib.dimensions.header)
		window:SetMovable(true)
		window:SetUserPlaced(true)
		window:SetFrameStrata("DIALOG")
		window:SetClampedToScreen(true)
		CreateShadow(window, 10)
	end

	-- Header
	do
		window.header = CreateFrame("frame", nil, window)
		window.header:SetPoint("TOPLEFT")
		window.header:SetPoint("TOPRIGHT")
		window.header:SetHeight(bdConfigLib.dimensions.header)
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
		window.header.text:SetScale(bdConfigLib.media.fontHeaderScale)

		window.header.close = CreateButton(window.header)
		window.header.close:SetPoint("TOPRIGHT", window.header)
		window.header.close:SetText("x")
		window.header.close.inactiveColor = bdConfigLib.media.red
		window.header.close:OnLeave()
		window.header.close.OnClick = function()
			window:Hide()
		end

		window.header.reload = CreateButton(window.header)
		window.header.reload:SetPoint("TOPRIGHT", window.header.close, "TOPLEFT", -bdConfigLib.media.borderSize, 0)
		window.header.reload:SetText("Reload UI")
		window.header.reload.inactiveColor = bdConfigLib.media.green
		window.header.reload:OnLeave()
		window.header.reload.OnClick = function()
			ReloadUI();
		end

		window.header.lock = CreateButton(window.header)
		window.header.lock:SetPoint("TOPRIGHT", window.header.reload, "TOPLEFT", -bdConfigLib.media.borderSize, 0)
		window.header.lock:SetText("Unlock")
		window.header.lock.autoToggle = true
		window.header.lock.OnClick = function(self)
			bdCore:toggleLock()
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
		window.left:SetPoint("TOPLEFT", window, "TOPLEFT", 0, -bdConfigLib.dimensions.header-bdConfigLib.media.borderSize)
		window.left:SetSize(bdConfigLib.dimensions.left_column, bdConfigLib.dimensions.height)
		CreateBackdrop(window.left)
	end

	-- Right Column
	do
		window.right = CreateFrame( "Frame", nil, window)
		window.right:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, -bdConfigLib.dimensions.header-bdConfigLib.media.borderSize)
		window.right:SetSize(bdConfigLib.dimensions.right_column-bdConfigLib.media.borderSize, bdConfigLib.dimensions.height)
		CreateBackdrop(window.right)
		window.right.bd_background:SetVertexColor(unpack(bdConfigLib.media.border))
	end

	return window
end

--[[ Use fonts from bdCore if possible, can extend this ]]
local function FindBetterFont()
	if (bdConfigLib.foundBetterFont) then return end
	local font = false

	if (bdCore) then
		font = bdCore.media.font
	elseif (bdlc) then
		font = bdlc.font
	end

	if (font) then
		bdConfigLib.foundBetterFont = true
		bdConfigLib.font:SetFont(font, bdConfigLib.media.fontSize)
	end
end


-- Primary function
local function RegisterModule(self, settings, configuration, savedVariable)
	local enabled, loaded = IsAddOnLoaded(addonName)
	if (not loaded and not bdConfigLib.ProfileSetup) then
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
	if (bdConfigLib.modules[settings.name]) then
		debug("There is already a module loaded with the name "..settings.name..". Please choose a unique name for the module")
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
	-- module.configuration = configuration
	-- module.savedVariable = savedVariable
	do
		module.tabs = {}
		module.tabContainer = false
		module.pageContainer = false
		module.link = false
		module.lastTab = false
		module.active = false

		function module:Select()
			if (module.active) then return end

			-- Unselect all modules
			for name, otherModule in pairs(bdConfigLib.modules) do
				otherModule:Unselect()

				for k, t in pairs(otherModule.tabs) do
					t:Unselect()
				end
			end

			-- Show this module
			module.active = true
			module.link.active = true
			module.link:OnLeave()
			module.tabContainer:Show()

			-- Select first tab
			module.tabs[1]:Select()

			-- If there aren't additional tabs, act like non exist and fill up space
			local current_tab = module.tabs[#module.tabs]
			if (current_tab.text:GetText() == "General") then
				module.tabContainer:Hide()
				current_tab.page.scrollParent:SetHeight(bdConfigLib.dimensions.height - bdConfigLib.media.borderSize)
			end
		end

		-- for when hiding
		function module:Unselect()
			module.tabContainer:Hide()
			module.active = false
			module.link.active = false
			module.link:OnLeave()
		end

		-- Create page and tabs container
		do
			local tabContainer = CreateFrame("frame", nil, bdConfigLib.window.right)
			tabContainer:SetPoint("TOPLEFT")
			tabContainer:SetPoint("TOPRIGHT")
			tabContainer:Hide()
			tabContainer:SetHeight(bdConfigLib.dimensions.header)
			CreateBackdrop(tabContainer)
			local r, g, b, a = unpack(bdConfigLib.media.background)
			tabContainer.bd_border:Hide()
			tabContainer.bd_background:SetVertexColor(r, g, b, 0.5)

			module.tabContainer = tabContainer
		end
		
		-- Create page / tab
		function module:CreateTab(name)
			local index = #module.tabs + 1

			-- create scrollable page container to display tab's configuration options
			local page = CreateScrollFrame(bdConfigLib.window.right)
			page:Hide()

			-- create tab to link to this page
			local tab = CreateButton(module.tabContainer)
			tab.inactiveColor = {1,1,1,0}
			tab.hoverColor = {1,1,1,0.1}
			tab:OnLeave()

			function tab:Select()
				-- tab:Show()
				tab.page:Show()
				if (not tab.page.noScrollbar) then
					tab.page.scrollbar:Show()
				end

				tab.active = true
				tab.page.active = true
				tab:OnLeave()
				module.activePage = page
			end

			function tab:Unselect()
				-- tab:Hide()
				tab.page.scrollbar:Hide()
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
			local link = CreateButton(bdConfigLib.window.left)
			link.inactiveColor = {0, 0, 0, 0}
			link.hoverColor = {1, 1, 1, .2}
			link:OnLeave()
			link.OnClick = module.Select
			link:SetText(settings.name)
			link:SetWidth(bdConfigLib.dimensions.left_column)
			link.text:SetPoint("LEFT", link, "LEFT", 6, 0)
			if (not bdConfigLib.lastLink) then
				link:SetPoint("TOPLEFT", bdConfigLib.window.left, "TOPLEFT")
				bdConfigLib.firstLink = link
			else
				link:SetPoint("TOPLEFT", bdConfigLib.lastLink, "BOTTOMLEFT")
			end

			bdConfigLib.lastLink = link
			module.link = link
		end
	end

	-- Caps/hide the scrollbar as necessary
	-- also resize the page
	function module:SetPageScroll()
		-- now that all configs have been created, loop through the tabs
		for index, tab in pairs(module.tabs) do
			local page = tab.page
		
			local height = 0
			if (page.rows) then
				for k, container in pairs(page.rows) do
					height = height + container:GetHeight() + 10
				end
			end

			-- size based on if there are tabs or scrollbars
			local scrollHeight = 0
			if (#module.tabs > 1) then
				scrollHeight = math.max(dimensions.height, height + dimensions.header) - dimensions.height + 1			
				page.scrollParent:SetPoint("TOPLEFT", page.parent, "TOPLEFT", 0, - dimensions.header)
				page.scrollParent:SetHeight(page.scrollParent:GetParent():GetHeight() - dimensions.header)
			else
				scrollHeight = math.max(dimensions.height, height) - dimensions.height + 1
			end

			-- make the scrollbar only scroll the height of the page
			page.scrollbar:SetMinMaxValues(1, scrollHeight)

			if (scrollHeight <= 1) then
				page.noScrollbar = true
				page.scrollbar:Hide()
			else
				page.noScrollbar = false
				page.scrollbar:Show()
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
	_G[savedVariable] = _G[savedVariable] or {}
	_G[savedVariable][settings.name] = _G[savedVariable][settings.name] or {}
	local c = _G[savedVariable][settings.name]

	-- user
	c.users = c.users or {}
	c.users[UnitName("player")] = c.users[UnitName("player")] or {}
	c.user = c.users[UnitName("player")] or {}
	c.user.name = UnitName("player")
	c.user.profile = c.user.profile or "default"
	c.user.spec_profile = c.user.spec_profile or {}
	c.user.spec_profile[1] = c.user.spec_profile[1] or {}
	c.user.spec_profile[2] = c.user.spec_profile[2] or {}
	c.user.spec_profile[3] = c.user.spec_profile[3] or {}
	c.user.spec_profile[4] = c.user.spec_profile[4] or {}

	-- persistent
	c.persistent = c.persistent or {}

	-- profile
	c.profiles = c.profiles or {}
	c.profiles[c.user.profile] = c.profiles[c.user.profile] or {}
	c.profile = c.profiles[c.user.profile]
	c.profile.positions = c.profile.positions or {}

	-- shortcut to corrent save table
	if (settings.persistent) then
		c.save = c.persistent
	else
		c.save = c.profile
	end

	-- persistent configuration
	-- module.save.persistent.bd_config = module.save.persistent.bd_config or {} -- todo : let the user decide how the library looks and behaves

	-- let's us access module inforomation quickly and easily
	function module:Save(option, value)
		if (settings.persistent) then
			c.persistent[option] = value
		else
			c.profile[option] = value
		end
	end
	function module:Get(option)
		if (settings.persistent) then
			return c.persistent[option]
		else
			return c.profile[option]
		end
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
			if (settings.persistent) then
				-- if variable is `persistent` its not associate with a profile
				
				if (c.persistent[option] == nil) then
					if (info.value == nil) then
						info.value = {}
					end

					c.persistent[option] = info.value
				end
			else
				-- this is a per-character configuration
				if (c.profile[option] == nil) then
					if (info.value == nil) then
						info.value = {}
					end

					c.profile[option] = info.value
				end
			end

			-- force blank callbacks if not set
			info.callback = info.callback or function() return false end
			
			-- If the very first entry is not a tab, then create a general tab/page container
			if (info.type ~= "tab" and #module.tabs == 0) then
				module:CreateTab("General")
			end

			-- Master Call (slider = bdConfigLib.SliderElement(config, module, option, info))
			local method = string.lower(info.type):gsub("^%l", string.upper).."Element"
			if (bdConfigLib[method]) then
				bdConfigLib[method](bdConfigLib, module, option, info)
			else
				debug("No module defined for "..method.." in "..settings.name)
			end
		end
	end
	

	--[[======================================================
		3: SETUP DISPLAY AND STORE MODULE
			If we only made 1 tab, hide the tabContianer an
			make the page take up the extra space
	========================================================]]
	module:SetPageScroll()

	-- store in config
	bdConfigLib.modulesIndex[#bdConfigLib.modulesIndex + 1] = module
	bdConfigLib.modules[settings.name] = module

	if (settings.init) then
		setting.init(module)
	end
	
	-- profile stuff
	if (not bdConfigLib.ProfileSetup) then
		bdConfigLibProfiles.SavedVariables[savedVariable] = true
		bdConfigLib.saves[settings.name] = c
		bd_do_action("update_profiles");
	end

	-- return config
	if (not settings.returnType) then
		return c.save
	elseif (settings.returnType == "both") then
		return c
	elseif (settings.returnType == "profile") then
		return c.profile
	elseif (settings.returnType == "persistent") then
		return c.persistent
	end
end

--[[========================================================
	Load the Library Up
	For anyone curious, I use `do` statements just to 
	keep the code dileniated and easy to read.
==========================================================]]
do
	-- returns a list of modules currently loaded
	function bdConfigLib:GetSave(name)
		-- print(name)
		-- print(name.save)
		if (self.saves[name]) then
			return self.saves[name].save
		else
			return false
		end
	end
	function bdConfigLib:Toggle()
		if (not bdConfigLib.toggled) then
			bdConfigLib.window:Show()
		else
			bdConfigLib.window:Hide()
		end
		bdConfigLib.toggled = not bdConfigLib.toggled
	end

	-- create tables
	bdConfigLib.modules = {}
	bdConfigLib.modulesIndex = {}
	bdConfigLib.saves = {}
	bdConfigLib.lastLink = false
	bdConfigLib.firstLink = false

	-- create frame objects
	bdConfigLib.window = CreateFrames()
	-- Selects first module, hides column if only 1
	bdConfigLib.window:SetScript("OnShow", function()
		bdConfigLib.modulesIndex[1]:Select()
	end)

	-- associate RegisterModule function
	bdConfigLib.RegisterModule = RegisterModule
end

--[[========================================================
	CONFIGURATION INPUT ELEMENT METHODS
	This is all of the methods that create user interaction 
	elements. When adding support for new modules, start here
==========================================================]]

--[[========================================================
	ELEMENT CONTAINER WITH `COLUMN` SUPPORT
==========================================================]]
function bdConfigLib:ElementContainer(module, info)
	local page = module.tabs[#module.tabs].page
	local element = info.type
	local container = CreateFrame("frame", nil, page)
	local padding = 10
	local sizing = {
		text = 1.0
		, table = 1.0
		, slider = 0.5
		, checkbox = 0.5
		, color = 0.33
		, dropdown = 0.5
		, clear = 1.0
		, button = 0.5
		, list = 1.0
		, textbox = 1.0
	}

	local size = sizing[string.lower(element)]
	if (not size) then
		print("size not found for "..element)
		size = 1
	end

	-- sizing[element] = 1

	-- size the container ((pageWidth / %) - padding left)
	container:SetSize((page:GetWidth() * size) - padding, 30)

	-- TESTING : shows a background around each container for debugging
	-- container:SetBackdrop({bgFile = bdConfigLib.media.flat})
	-- container:SetBackdropColor(.1, .8, .2, 0.1)

	-- place the container
	page.rows = page.rows or {}
	page.row_width = page.row_width or 0
	page.row_width = page.row_width + size

	if (page.row_width > 1.0 or not page.lastContainer) then
		page.row_width = size	
		if (not page.lastContainer) then
			container:SetPoint("TOPLEFT", page, "TOPLEFT", padding, -padding)
		else
			container:SetPoint("TOPLEFT", page.lastRow, "BOTTOMLEFT", 0, -padding)
		end

		-- used to count / measure rows
		page.lastRow = container
		page.rows[#page.rows + 1] = container
	else
		container:SetPoint("LEFT", page.lastContainer, "RIGHT", padding, 0)
	end
	
	page.lastContainer = container
	return container
end

--[[========================================================
	ADDING NEW TABS / SETTING SCROLLFRAME
==========================================================]]
function bdConfigLib:TabElement(module, option, info)
	-- We're done with the current page contianer, cap it's slider/height and start a new tab / height
	-- module:SetPageScroll()

	-- add new tab
	module:CreateTab(info.value)
end

--[[========================================================
	TEXT ELEMENT FOR USER INFO
==========================================================]]
function bdConfigLib:TextElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	local text = container:CreateFontString(nil, "OVERLAY", "bdConfig_font")

	text:SetText(info.value)
	text:SetAlpha(0.8)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetAllPoints(container)

	local lines = math.ceil(text:GetStringWidth() / (container:GetWidth() - 4))

	container:SetHeight( (lines * 14) + 10)

	return container
end

--[[========================================================
	CLEAR (clears the columns and starts a new row)
==========================================================]]
function bdConfigLib:ClearElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	container:SetHeight(5)

	return container
end

--[[========================================================
	TABLE ELEMENT
	lets you define a group of configs into a row, and allow for rows to be added
==========================================================]]
function bdConfigLib:ListElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)
	container:SetHeight(200)


	local title = container:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	title:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	title:SetText(info.label)

	local insertbox = CreateFrame("EditBox", nil, container)
	insertbox:SetFontObject("bdConfig_font")
	insertbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	insertbox:SetSize(container:GetWidth() - 66, 24)
	insertbox:SetTextInsets(6, 2, 2, 2)
	insertbox:SetMaxLetters(200)
	insertbox:SetHistoryLines(1000)
	insertbox:SetAutoFocus(false) 
	insertbox:SetScript("OnEnterPressed", function(self, key) button:Click() end)
	insertbox:SetScript("OnEscapePressed", function(self, key) self:ClearFocus() end)
	CreateBackdrop(insertbox)

	insertbox.alert = insertbox:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	insertbox.alert:SetPoint("TOPRIGHT",container,"TOPRIGHT", -2, 0)
	insertbox.startFade = function()
		local total = 0
		self.alert:Show()
		self:SetScript("OnUpdate",function(self, elapsed)
			total = total + elapsed
			if (total > 2.5) then
				self.alert:SetAlpha(self.alert:GetAlpha()-0.02)
				
				if (self.alert:GetAlpha() <= 0.05) then
					self:SetScript("OnUpdate", function() return end)
					self.alert:Hide()
				end
			end
		end)
	end

	local button = CreateButton(container)
	button:SetPoint("TOPLEFT", insertbox, "TOPRIGHT", 0, 2)
	button:SetText("Add/Remove")
	insertbox:SetSize(container:GetWidth() - button:GetWidth() + 2, 24)
	button.OnClick = function()
		local value = insertbox:GetText()

		if (strlen(value) > 0) then
			list:addRemove(insertbox:GetText())
		end

		insertbox:SetText("")
		insertbox:ClearFocus()
	end

	local list = CreateFrame("frame", nil, container)
	list:SetPoint("TOPLEFT", insertbox, "BOTTOMLEFT", 0, -2)
	list:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT")
	CreateBackdrop(list)

	local content = CreateScrollFrame(list)

	list.text = content:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	list.text:SetPoint("TOPLEFT", content, "TOPLEFT", 5, 0)
	list.text:SetHeight(600)
	list.text:SetWidth(list:GetWidth() - 10)
	list.text:SetJustifyH("LEFT")
	list.text:SetJustifyV("TOP")
	list.text:SetText("test")
	

	-- show all config entries in this list
	function list:populate()
		local string = "";
		local height = 0;

		for k, v in pairs(module:Get(option)) do
			string = string..k.."\n";
			height = height + 14
		end

		local scrollheight = (height - 200) 
		scrollheight = scrollheight > 1 and scrollheight or 1

		list.scrollbar:SetMinMaxValues(1, scrollheight)
		if (scrollheight == 1) then 
			list.scrollbar:Hide()
		else
			list.scrollbar:Show()
		end

		list.text:SetHeight(height)
		list.text:SetText(string)
	end

	-- remove or add something, then redraw the text
	function list:addRemove(value)
		if (module:Get(option)) then
			insertbox.alert:SetText(value.." removed")
		else
			insertbox.alert:SetText(value.." added")
		end
		module:Save(option, value)
		insertbox:startFade()
		
		self:populate()
		info:callback()

		-- clear aura cache
		bdCore.caches.auras = {}
	end

	list:populate()

	return container
end
--[[========================================================
	BUTTON ELEMENT
	lets you define a group of configs into a row, and allow for rows to be added
==========================================================]]
function bdConfigLib:ButtonElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	local create = CreateButton(container)
	create:SetPoint("TOPLEFT", container, "TOPLEFT")
	create:SetText(info.value)

	create:SetScript("OnClick", function()
		info.callback()
	end)

	return container
end

--[[========================================================
	TEXTBOX ELEMENT
==========================================================]]
function bdConfigLib:TextboxElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	local create = CreateFrame("EditBox", nil, container)
	create:SetSize(200,24)
	create:SetFontObject("bdConfig_font")
	create:SetText(info.value)
	create:SetTextInsets(6, 2, 2, 2)
	create:SetMaxLetters(200)
	create:SetHistoryLines(1000)
	create:SetAutoFocus(false) 
	create:SetScript("OnEnterPressed", function(self, key) create.button:Click() end)
	create:SetScript("OnEscapePressed", function(self, key) self:ClearFocus() end)
	create:SetPoint("TOPLEFT", container, "TOPLEFT", 5, 0)
	CreateBackdrop(create)

	create.label = create:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	create.label:SetText(info.description)
	create.label:SetPoint("BOTTOMLEFT", create, "TOPLEFT", 0, 4)

	create.button = CreateButton(create)
	create.button:SetPoint("LEFT", create, "RIGHT", 4, 0)
	create.button:SetText(info.button)
	create.button.OnClick = function()
		local text = create:GetText()
		info:callback(text)
		create:SetText("")
	end

	return container
end

--[[========================================================
	SLIDER ELEMENT
==========================================================]]
function bdConfigLib:SliderElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	local slider = CreateFrame("Slider", module.name.."_"..option, container, "OptionsSliderTemplate")
	slider:SetWidth(container:GetWidth())
	slider:SetHeight(14)
	slider:SetPoint("TOPLEFT", container ,"TOPLEFT", 0, -16)
	slider:SetOrientation('HORIZONTAL')
	slider:SetMinMaxValues(info.min, info.max)
	slider:SetObeyStepOnDrag(true)
	slider:SetValueStep(info.step)
	slider:SetValue(info.value)
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
	slider.value:SetText(module:Get(option))

	slider:Show()
	slider.lastValue = 0
	slider:SetScript("OnValueChanged", function(self)
		local newval = math.floor(slider:GetValue())

		if (slider.lastValue == newval) then return end
		slider.lastValue = newval

		if (module:Get(option) == newval) then -- throttle it changing on the same pixel
			return false
		end

		module:Save(option, newval)

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
function bdConfigLib:CheckboxElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)
	container:SetHeight(25)

	local check = CreateFrame("CheckButton", module.name.."_"..option, container, "ChatConfigCheckButtonTemplate")
	check:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	local text = _G[check:GetName().."Text"]
	text:SetText(info.label)
	text:SetFontObject("bdConfig_font")
	text:ClearAllPoints()
	text:SetPoint("LEFT", check, "RIGHT", 2, 1)
	check.tooltip = info.tooltip;
	check:SetChecked(module:Get(option))

	check:SetScript("OnClick", function(self)
		module:Save(option, self:GetChecked())

		info:callback(check)
	end)

	return container
end

--[[========================================================
	COLORPICKER ELEMENT
==========================================================]]
function bdConfigLib:ColorElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	local picker = CreateFrame("button", nil, container)
	picker:SetSize(20, 20)
	picker:SetBackdrop({bgFile = bdCore.media.flat, edgeFile = bdCore.media.flat, edgeSize = 2, insets = {top = 2, right = 2, bottom = 2, left = 2}})
	picker:SetBackdropColor(unpack(module:Get(option)))
	picker:SetBackdropBorderColor(0,0,0,1)
	picker:SetPoint("LEFT", container, "LEFT", 0, 0)
	
	picker.callback = function(self, r, g, b, a)
		module:Save(option, {r,g,b,a})
		picker:SetBackdropColor(r,g,b,a)

		info:callback()
		
		return r, g, b, a
	end
	
	picker:SetScript("OnClick",function()		
		HideUIPanel(ColorPickerFrame)
		local r, g, b, a = unpack(module:Get(option))

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
function bdConfigLib:DropdownElement(module, option, info)
	local container = bdConfigLib:ElementContainer(module, info)

	-- revert to blizzard dropdown for the time being
	local label = container:CreateFontString(nil, "OVERLAY", "bdConfig_font")
	label:SetPoint("TOPLEFT", container, "TOPLEFT")
	label:SetText(info.label)
	container:SetHeight(45)

	local dropdown = CreateFrame("Button", module.name.."_"..option, container, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -15, -2)
	
	-- recreate dropdown each time
	function dropdown:populate(options)
		UIDropDownMenu_SetWidth(dropdown, container:GetWidth() - 20)
		UIDropDownMenu_JustifyText(dropdown, "LEFT")

		UIDropDownMenu_Initialize(dropdown, function(self, level)
			local selected = 1
			for i, item in pairs(options) do
				if (type(item) == "string") then
					opt = UIDropDownMenu_CreateInfo()
					opt.text = item:gsub("^%l", string.upper)
					opt.value = item
					if (info.value == nil) then
						info.value = item
					end
					opt.func = function(self)
						UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
						CloseDropDownMenus()

						module:Save(option, options[i])
						info.value = options[i]

						info:callback(options[i])
					end

					if (item == module:Get(option)) then selected = i end
					if (info.override) then
						if item == info.value then
							selected = i
						end
					end

					UIDropDownMenu_AddButton(opt, level)
				end
			end

			UIDropDownMenu_SetSelectedID(dropdown, selected)
		end)
	end

	if (info.update_action and info.update) then
		bd_add_action(info.update_action, function(updateTable)
			info:update(dropdown)
		end)
	end

	dropdown:populate(info.options)

	return container
end

--[[========================================================
	PROFILES
	Modules that are added that aren't persistent are 
	automatically stored inside of a profile, and those
	profiles are common between SavedVariables
==========================================================]]
do
	-- add a profile to every saved variable inside of bdConfigLib
	function bdConfigLib:AddProfile(value)
		for savedVariable, v in pairs(bdConfigLibProfiles.SavedVariables) do
			for module, save in pairs(_G[savedVariable]) do
				if (save.user.profile == value) then
					print("Profile named "..value.." already exists. Profile names must be unique.")
					return 
				else
					save.profiles[value] = save.profile
					bdConfigLibProfiles.Selected = value
					bd_do_action("update_profiles")
				end
			end
		end
	end

	-- the trick here is changing profiles for all saved variables stored inside bdConfigLib
	function bdConfigLib:ChangeProfile(value)
		for savedVariable, v in pairs(bdConfigLibProfiles.SavedVariables) do
			for module, save in pairs(_G[savedVariable]) do
				save.user.profile = value
				save.profile = save.profiles[value]
				bdConfigLibProfiles.Selected = value
			end
		end
	end

	-- delete a profile inside of every saved variable in bdConfigLib
	function bdConfigLib:DeleteProfile()
		for savedVariable, v in pairs(bdConfigLibProfiles.SavedVariables) do
			for module, save in pairs(_G[savedVariable]) do
				if (save.user.profile == "default") then
					print("You cannot delete the default profile, but you're free to modify it.")
					return 
				else
					save.profile = nil
					bdConfigLibProfiles.Selected = nil
					bd_do_action("update_profiles")
				end
			end
		end
	end

	-- return a table of profile names
	function bdConfigLib:UpdateProfiles(dropdown)
		bdConfigLibProfiles.Profiles = {}
		local profile_table = {}
		--_G[savedVariable][settings.name].user.profile
		for savedVariable, v in pairs(bdConfigLibProfiles.SavedVariables) do
			for module, c in pairs(_G[savedVariable]) do
				if (not bdConfigLibProfiles.Selected) then
					bdConfigLibProfiles.Selected = c.user.profile
				end
				for profile, config in pairs(c.profiles) do
					profile_table[profile] = true
				end
			end
		end

		for k, v in pairs(profile_table) do
			table.insert(bdConfigLibProfiles.Profiles, k)
		end

		dropdown:populate(bdConfigLibProfiles.Profiles)
	end

	-- make new profile form
	local name, realm = UnitName("player")
	realm = GetRealmName()
	local placeholder = name.."-"..realm

	-- how many specs does this class have
	local class = select(2, UnitClass("player"));
	local specs = 3
	if (class == "DRUID") then
		specs = 4
	elseif (class == "DEMONHUNTER") then
		specs = 2
	end

	local profile_settings = {}
	profile_settings[#profile_settings+1] = {intro = {
		type = "text",
		value = "You can use profiles to store configuration per character and spec automatically, or save templates to use when needed."
	}}
	-- create new profile
	profile_settings[#profile_settings+1] = {createprofile = {
		type = "textbox",
		value = placeholder,
		button = "Create & Copy",
		description = "Create New Profile: ",
		tooltip = "Your currently selected profile.",
		callback = function(self, value) bdConfigLib:AddProfile(value) end
	}}

	-- select / delete profiles
	profile_settings[#profile_settings+1] = {currentprofile = {
		type = "dropdown",
		label = "Current Profile",
		value = bdConfigLibProfiles.Selected,
		options = bdConfigLibProfiles.Profiles,
		update = function(self, dropdown) bdConfigLib:UpdateProfiles(dropdown) end,
		update_action = "update_profiles",
		tooltip = "Your currently selected profile.",
		callback = function(self, value) bdConfigLib:ChangeProfile(value) end
	}}
	profile_settings[#profile_settings+1] = {deleteprofile = {
		type = "button",
		value = "Delete Current Profile",
		callback = bdConfigLib.DeleteProfile
	}}
	profile_settings[#profile_settings+1] = {clear = {
		type = "clear"
	}}
	-- loop through and display spec dropdowns (@todo)
	for i = 1, specs do
		-- profile_settings[#profile_settings+1] = {["spec"..i] = {
		-- 	type = "dropdown",
		-- 	label = "Spec "..i.." Profile"
		-- 	value = bdConfigLibProfiles.Selected,
		-- 	override = true,
		-- 	options = bdConfigLibProfiles.Profiles,
		-- 	update = function(self, dropdown) bdConfigLib:UpdateProfiles(dropdown) end,
		-- 	update_action = "update_profiles",
		-- 	tooltip = "Your currently selected profile.",
		-- 	callback = function(self, value) bdConfigLib:ChangeProfile(value) end
		-- }}
	end


	bdConfigLib.ProfileSetup = true
	bdConfigLib:RegisterModule({
		name = "Profiles"
		, persistent = true
	}, profile_settings, "bdConfigLibProfiles")
	bdConfigLib.ProfileSetup = nil
end


-- for testing, pops up config on reload for easy access :)
-- bdConfigLib:Toggle()
