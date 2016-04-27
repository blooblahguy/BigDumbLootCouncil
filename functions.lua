local bdlc, f, c = select(2, ...):unpack()

function bdlc:inLC()
	return bdlc.loot_council[FetchUnitName("player")] or not IsInRaid()
end

function IsRaidLeader()
	local rl = nil
	local num = GetNumGroupMembers()
	local player = UnitName("player")
	for i = 1, num do
		local rank = select(2, GetRaidRosterInfo(i))
		local name = select(1, GetRaidRosterInfo(i))
		if (rank == 2 and name == player) then
			rl = true
			break
		end
	end
	return rl
end

function bdlc:returnEntry(itemLink, playerName)
	playerName = FetchUnitName(playerName)
	local current = nil
	local tab = nil

	for i = 1, #f.tabs do
		if (f.tabs[i].itemLink and f.tabs[i].itemLink == itemLink) then
			tab = i
			
			break
		end
	end
	
	if (tab) then
		for i = 1, #f.entries[tab] do
			if (f.entries[tab][i].playerName == playerName) then
				current = f.entries[tab][i]
				
				break
			end
		end
	end
	
	return current
end

function bdlc:debug(msg)
	if (bdlc.config.debug) then print("|cff3399FFBCLC:|r "..msg) end
end

function bdlc:skinBackdrop(frame, ...)
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
    frame:SetBackdropColor(...)
    frame:SetBackdropBorderColor(0,0,0,1)
	
	return true
end

function bdlc:skinButton(f,small,color)
	local colors = {.1,.1,.1,1}
	local hovercolors = {0,0.55,.85,1}
	if (color == "red") then
		colors = {.6,.1,.1,0.6}
		hovercolors = {.6,.1,.1,1}
	elseif (color == "blue") then
		colors = {0,0.55,.85,0.6}
		hovercolors = {0,0.55,.85,1}
	elseif (color == "dark") then
		colors = {.1,.1,.1,1}
		hovercolors = {.1,.1,.1,1}
	end
	f:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1, insets = {left=1,top=1,right=1,bottom=1}})
	f:SetBackdropColor(unpack(colors)) 
    f:SetBackdropBorderColor(0,0,0,1)
    f:SetNormalFontObject("bdlc_button")
	f:SetHighlightFontObject("bdlc_button")
	f:SetPushedTextOffset(0,-1)
	
	f:SetSize(f:GetTextWidth()+16,24)
	
	--if (f:GetWidth() < 24) then
	if (small and f:GetWidth() <= 24 ) then
		f:SetWidth(20)
	end
	
	if (small) then
		f:SetHeight(18)
	end
	
	f:HookScript("OnEnter", function(f) 
		f:SetBackdropColor(unpack(hovercolors)) 
	end)
	f:HookScript("OnLeave", function(f) 
		f:SetBackdropColor(unpack(colors)) 
	end)
	
	return true
end

function bdlc:split(str, del)
	local t = {}
	local index = 0;
	while (string.find(str, del)) do
		local s, e = string.find(str, del)
		t[index] = string.sub(str, 1, s-1)
		str = string.sub(str, s+#del)
		index = index + 1;
	end
	table.insert(t, str)
	return t;
end
