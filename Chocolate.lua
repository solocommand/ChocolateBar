﻿local ChocolateBar = LibStub("AceAddon-3.0"):GetAddon("ChocolateBar")
local ChocolatePiece = ChocolateBar.ChocolatePiece
local Drag = ChocolateBar.Drag
local Debug = ChocolateBar.Debug
local tempAutoHide
local db

local function resizeFrame(self)
	local settings = self.settings
	local width = db.gap
	if self.icon and settings.showIcon then
		width = width + self.icon:GetWidth()
	end
	if settings.showText then
		if settings.width == 0 then
			local textWidth = self.text:GetStringWidth()
			width = width + textWidth
		else
			width = width + settings.width
		end
	end
	self:SetWidth(width)
end

local function TextUpdater(frame, value)
	--frame.text:SetText("("..frame.settings.index..") "..value)
	frame.text:SetText(value)
	resizeFrame(frame)
end

local function SettingsUpdater(self, value)
	local settings = self.settings
	if not settings.showText then
		self.text:Hide()
	else
		self.text:Show()
		local c = db.textColor
		if c then
			self.text:SetTextColor(c.r, c.g, c.b,c.a)
		end
	end
	
	self.text:SetPoint("TOP", self, 0, 3)
	self.text:SetPoint("BOTTOMRIGHT", self, 0, 0)
	
	if self.icon then 
		if settings.showIcon then 
			self.icon:SetWidth(db.height-5)
			self.icon:Show()
			self.text:SetPoint("LEFT", self.icon,"RIGHT", 1, 0)
		else -- hide icon
			self.icon:Hide()
			self.text:SetPoint("LEFT", self, 0, 0)
		end
	else -- no icon
		self.text:SetPoint("LEFT", self, 0, 0)
	end
	
	resizeFrame(self)
end

local function IconColorUpdater(frame, value, name)
	if value then
		local obj = frame.obj
		local r = obj.iconR or 1
		local g = obj.iconG or 1
		local b = obj.iconB or 1
		frame.icon:SetVertexColor(r, g, b)
	else
		frame.icon:SetVertexColor(1, 1, 1)
	end
end

local function CreateIcon(self, icon)
	local iconTex = self:CreateTexture()
	local obj = self.obj
	iconTex:SetWidth(db.height - 6)
	iconTex:SetPoint("TOPLEFT", self, 0, -2)
	iconTex:SetPoint("BOTTOM", self, 0, 4)
	iconTex:SetTexture(icon)
	if obj.iconCoords then
		iconTex:SetTexCoord(unpack(obj.iconCoords))
	end
	self.icon = iconTex
end

-- updaters code taken with permission from fortress 
local updaters = {
	text = TextUpdater,
	label  = TextUpdater,
	
	icon = function(frame, value, name)
		--if value and self.db.icon then
		if value then
			if frame.icon then
				frame.icon:SetTexture(value)
			else
				CreateIcon(frame, value)
				SettingsUpdater(frame)
			end
		end
	end,
	
	updatefont = function(self)
		self.text:SetFont(db.fontPath,db.fontSize)
		resizeFrame(self)
	end,
	updateSettings = SettingsUpdater,
	-- tooltiptext is no longer in the data spec, but 
	-- I'll continue to support it, as some plugins seem to use it
	tooltiptext = function(frame, value, name)
		local object = frame.obj
		local tt = object.tooltip or GameTooltip
		if tt:GetOwner() == frame then
			tt:SetText(object.tooltiptext)
		end
	end,
	
	OnClick = function(frame, value, name)
		frame:SetScript("OnClick", value)
	end,
	
	iconCoords = function(frame, value, name)
		if value and frame.icon then
			frame.icon:SetTexCoord(unpack(value))
		end
	end,
	
	iconR = IconColorUpdater,
	iconG = IconColorUpdater,
	iconB = IconColorUpdater,
}

-- GetAnchors code taken with permission from fortress 
local function GetAnchors(frame)
	local x, y = frame:GetCenter()
	local leftRight
	if x < GetScreenWidth() / 2 then
		leftRight = "LEFT"
	else
		leftRight = "RIGHT"
	end
	if y < GetScreenHeight() / 2 then
		return "BOTTOM", "TOP"
	else
		return "TOP", "BOTTOM"
	end
end

-- some code taken with permission from fortress 
local function PrepareTooltip(frame, anchorFrame)
	if frame and frame.SetOwner and anchorFrame then
		frame:SetOwner(anchorFrame, "ANCHOR_NONE")
		frame:ClearAllPoints()
		local a1, a2 = GetAnchors(anchorFrame)
		frame:SetPoint(a1, anchorFrame, a2)
	end
end

-- some code taken with permission from fortress 
local function OnEnter(self)
	if (db.combathidebar and ChocolateBar.InCombat) or ChocolateBar.dragging then return end
	
	local obj  = self.obj
	local name = self.name
		
	if self.bar.autohide then
		local bar = self.bar
		bar:ShowAll()
	end
	
	if db.combathidetip and ChocolateBar.InCombat then return end
	
	if obj.tooltip then
		PrepareTooltip(obj.tooltip, self)
		if obj.tooltiptext then
			obj.tooltip:SetText(obj.tooltiptext)
		end
		obj.tooltip:Show()
	
	elseif obj.OnTooltipShow then
		PrepareTooltip(GameTooltip, self)
		obj.OnTooltipShow(GameTooltip)
		GameTooltip:Show()
	
	elseif obj.tooltiptext then
		PrepareTooltip(GameTooltip, self)
		GameTooltip:SetText(obj.tooltiptext)
		GameTooltip:Show()		
	
	elseif obj.OnEnter then
		obj.OnEnter(self)
	end
end

local function OnLeave(self)
	if db.combathidebar and ChocolateBar.InCombat then return end
	
	local obj  = self.obj
	local name = self.name
	
	local bar = self.bar
	if bar.autohide then
		bar:HideAll()
	end

	if db.combathidetip and ChocolateBar.InCombat then return end
	if obj.OnLeave then
		obj.OnLeave(self)
	else
		GameTooltip:Hide()
	end
end

local function OnClick(self, ...)
	if db.combatdisbar and ChocolateBar.InCombat then return end
	if self.obj.OnClick then
		self.obj.OnClick(self, ...)
	end
end

-- PrepareTooltip code taken with permission from fortress 
local function PrepareTooltip(frame, anchorFrame)
	if frame == GameTooltip then
		frame.fortressOnLeave = frame:GetScript("OnLeave")
		frame.fortressBlock = anchorFrame
		frame.fortressName = anchorFrame.name
		
		frame:EnableMouse(true)
		frame:SetScript("OnLeave", GT_OnLeave)
	end
	frame:SetOwner(anchorFrame, "ANCHOR_NONE")
	frame:ClearAllPoints()
	local a1, a2 = GetAnchors(anchorFrame)
	frame:SetPoint(a1, anchorFrame, a2)	
end

local function Update(self, f,key, value)
	local update = updaters[key]
	--local update = uniqueUpdaters[key]
	if update then
		update(f, value, name)
	end
end

local function OnDragStart(frame)
	if not ChocolateBar.db.profile.locked or IsAltKeyDown() then 
		local bar = frame.bar
		ChocolateBar:TempDisAutohide(true)
		ChocolateBar.dragging = true
		GameTooltip:Hide()
		-- hide libqtip and libtablet tooltips
		local kids = {UIParent:GetChildren()}
		for _, child in ipairs(kids) do
			for i = 1, child:GetNumPoints() do
				local _,relativeTo,_,_,_ = child:GetPoint(i)
				if relativeTo == frame then
					Debug(i,child:GetName())
					child:Hide()
				end
			end
		end
		ChocolateBar:SetDropPoins(frame)
		Drag:Start(bar, frame.name, frame)
		frame:StartMoving()
		frame.isMoving = true
		
	end
end

local function OnDragStop(frame)
	if ChocolateBar.dragging then
		frame:StopMovingOrSizing()
		frame.isMoving = false
		Drag:Stop(frame)
		ChocolateBar.dropFrames:Hide()
		ChocolateBar.dragging = false
		frame:SetParent(frame.bar)
		ChocolateBar:TempDisAutohide()
	end
end

function ChocolatePiece:New(name, obj, settings, database)
	db = database
	local text = obj.text
	local icon = obj.icon
	local chocolate = CreateFrame("Button", "Chocolate" .. name)
	--set update function
	chocolate.Update = Update
	chocolate.obj = obj
	
	chocolate:EnableMouse(true)
	chocolate:RegisterForDrag("LeftButton")
	--chocolate:SetClampedToScreen(true)
	
	chocolate.text = chocolate:CreateFontString(nil, nil, "GameFontHighlight")
    chocolate.text:SetFont(db.fontPath, db.fontSize) --will onl be set when db.fontPath is vald 
	chocolate.text:SetJustifyH("LEFT")
	--chocolate.text:SetJustifyV("CENTER")
	
	if icon then
		CreateIcon(chocolate, icon)
	end
	
	chocolate:SetScript("OnEnter", OnEnter)
	chocolate:SetScript("OnLeave", OnLeave)
	
	chocolate:RegisterForClicks("AnyUp")
	--chocolate:SetScript("OnClick", obj.OnClick)
	chocolate:SetScript("OnClick", OnClick)
	
	chocolate:Show()
	chocolate.settings = settings
	
	if text then
		chocolate.text:SetText(text)
	else
		obj.text = name
		chocolate.text:SetText(name)
	end

	SettingsUpdater(chocolate, settings.showText )
	
	chocolate.name = name
	chocolate:SetMovable(true)
	chocolate:SetScript("OnDragStart", OnDragStart)
	chocolate:SetScript("OnDragStop", OnDragStop)
	
	return chocolate
end

function ChocolatePiece:UpdateGap(val)
	db.gap = val
end