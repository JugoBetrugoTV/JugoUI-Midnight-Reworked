--[[
    JugoUI - Minimap/Core.lua
    Minimap enhancement module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local MM = E:NewModule("Minimap", "AceEvent-3.0")
E.Minimap = MM

function MM:OnInitialize()
    self.db = E.db.minimap
end

function MM:OnEnable()
    self:StyleMinimap()
    self:CreateInfoTexts()
    self:RegisterEvent("ZONE_CHANGED")
    self:RegisterEvent("ZONE_CHANGED_INDOORS")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function MM:OnDisable()
    -- Restore defaults
end

function MM:StyleMinimap()
    local db = self.db

    -- Set size
    Minimap:SetSize(db.size, db.size)

    -- Position
    Minimap:ClearAllPoints()
    local point = db.point
    Minimap:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    -- Make movable
    Minimap:SetMovable(true)
    Minimap:EnableMouse(true)
    Minimap:RegisterForDrag("LeftButton")
    Minimap:SetScript("OnDragStart", function(self) self:StartMoving() end)
    Minimap:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Style based on shape
    if db.style == "SQUARE" then
        Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
    else
        Minimap:SetMaskTexture("Interface\\Masks\\CircleMaskScalable")
    end

    -- Remove Blizzard elements
    local hideFrames = {
        MinimapBorder,
        MinimapBorderTop,
        MinimapZoomIn,
        MinimapZoomOut,
        MiniMapWorldMapButton,
        MinimapZoneTextButton,
        MiniMapTracking,
        MinimapNorthTag,
        GameTimeFrame,
    }

    for _, frame in pairs(hideFrames) do
        if frame then
            frame:Hide()
            frame:UnregisterAllEvents()
        end
    end

    -- Create border
    if not Minimap.border then
        Minimap.border = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
        Minimap.border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -db.borderSize, db.borderSize)
        Minimap.border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", db.borderSize, -db.borderSize)
        Minimap.border:SetBackdrop({
            edgeFile = E.media.textures.flat,
            edgeSize = db.borderSize,
        })
        Minimap.border:SetBackdropBorderColor(0, 0, 0, 1)
    end

    -- Scroll zoom
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)

    -- Right-click menu
    Minimap:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", 0, 0)
        elseif button == "MiddleButton" then
            -- Toggle calendar
            if GameTimeFrame and GameTimeFrame:GetScript("OnClick") then
                GameTimeFrame:GetScript("OnClick")(GameTimeFrame)
            end
        end
    end)

    -- Position mail icon
    if MiniMapMailFrame then
        MiniMapMailFrame:ClearAllPoints()
        MiniMapMailFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -5, -5)
    end

    -- Position LFG icon
    if QueueStatusButton then
        QueueStatusButton:ClearAllPoints()
        QueueStatusButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 5, -5)
    end
end

function MM:CreateInfoTexts()
    local db = self.db

    -- Zone text
    if db.zoneText then
        if not Minimap.zoneText then
            Minimap.zoneText = E:CreateFontString(Minimap, 12, "OUTLINE")
            Minimap.zoneText:SetPoint("TOP", Minimap, "BOTTOM", 0, -5)
        end
        self:UpdateZoneText()
    end

    -- Time
    if db.time then
        if not Minimap.timeText then
            Minimap.timeText = E:CreateFontString(Minimap, 11, "OUTLINE")
            Minimap.timeText:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 5)
        end
        self:ScheduleRepeatingTimer("UpdateTime", 1)
    end

    -- Coordinates
    if db.coordinates then
        if not Minimap.coordText then
            Minimap.coordText = E:CreateFontString(Minimap, 10, "OUTLINE")
            Minimap.coordText:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)
        end
        self:ScheduleRepeatingTimer("UpdateCoords", 0.2)
    end
end

function MM:UpdateZoneText()
    if Minimap.zoneText then
        local zone = GetMinimapZoneText()
        local pvpType = GetZonePVPInfo()

        local color = {1, 1, 1}
        if pvpType == "sanctuary" then
            color = {0.41, 0.80, 0.94}
        elseif pvpType == "arena" or pvpType == "combat" then
            color = {1.0, 0.1, 0.1}
        elseif pvpType == "friendly" then
            color = {0.1, 1.0, 0.1}
        elseif pvpType == "hostile" then
            color = {1.0, 0.1, 0.1}
        elseif pvpType == "contested" then
            color = {1.0, 0.7, 0.0}
        end

        Minimap.zoneText:SetText(zone)
        Minimap.zoneText:SetTextColor(unpack(color))
    end
end

function MM:UpdateTime()
    if Minimap.timeText then
        local format24 = self.db.timeFormat == "24H"
        local hour, minute = GetGameTime()

        if format24 then
            Minimap.timeText:SetFormattedText("%02d:%02d", hour, minute)
        else
            local suffix = hour >= 12 and "PM" or "AM"
            hour = hour % 12
            if hour == 0 then hour = 12 end
            Minimap.timeText:SetFormattedText("%d:%02d %s", hour, minute, suffix)
        end
    end
end

function MM:UpdateCoords()
    if Minimap.coordText then
        local map = C_Map.GetBestMapForUnit("player")
        if map then
            local pos = C_Map.GetPlayerMapPosition(map, "player")
            if pos then
                Minimap.coordText:SetFormattedText("%.1f, %.1f", pos.x * 100, pos.y * 100)
            else
                Minimap.coordText:SetText("")
            end
        else
            Minimap.coordText:SetText("")
        end
    end
end

function MM:ZONE_CHANGED()
    self:UpdateZoneText()
end

function MM:ZONE_CHANGED_INDOORS()
    self:UpdateZoneText()
end

function MM:ZONE_CHANGED_NEW_AREA()
    self:UpdateZoneText()
end

function MM:ProfileChanged()
    self.db = E.db.minimap
    self:StyleMinimap()
end
