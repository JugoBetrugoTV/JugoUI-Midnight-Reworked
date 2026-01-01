--[[
    JugoUI - UnitFrames/Units/Target.lua
    Target unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateTargetFrame()
    local db = self.db.target
    local frame = self:CreateUnitFrame("target", "JugoUI_Target", db)

    if not frame then return end

    -- Add PvP indicator
    frame.PvPIndicator = self:CreatePvPIndicator(frame)

    -- Add combo points for target (for rogues/druids)
    if db.comboPoints and db.comboPoints.enabled then
        frame.ComboPoints = self:CreateComboPoints(frame, db.comboPoints)
    end

    -- Override event handler for target-specific updates
    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, ...)
        oldHandler(self, event, ...)

        if event == "UNIT_FACTION" then
            UF:UpdatePvPIndicator(frame)
        end
    end)

    -- Initial updates
    self:UpdatePvPIndicator(frame)

    return frame
end

-- Combo points display on target
function UF:CreateComboPoints(frame, config)
    local cp = CreateFrame("Frame", nil, frame)
    cp:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
    cp:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
    cp:SetHeight(config.height or 8)

    cp.points = {}

    for i = 1, 8 do -- Max 8 with certain talents
        local point = CreateFrame("StatusBar", nil, cp)
        point:SetStatusBarTexture(E.media.textures.flat)
        point:SetStatusBarColor(1, 0.96, 0.41)
        point:SetMinMaxValues(0, 1)
        point:SetValue(1)

        point.bg = point:CreateTexture(nil, "BACKGROUND")
        point.bg:SetAllPoints()
        point.bg:SetTexture(E.media.textures.flat)
        point.bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)

        point:Hide()
        cp.points[i] = point
    end

    cp:RegisterEvent("UNIT_POWER_UPDATE")
    cp:RegisterEvent("UNIT_MAXPOWER")
    cp:RegisterEvent("PLAYER_TARGET_CHANGED")

    cp:SetScript("OnEvent", function()
        UF:UpdateComboPoints(frame)
    end)

    return cp
end

function UF:UpdateComboPoints(frame)
    if not frame or not frame.ComboPoints then return end

    local cp = frame.ComboPoints
    local points = UnitPower("player", Enum.PowerType.ComboPoints)
    local maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)

    if maxPoints == 0 then
        cp:Hide()
        return
    end

    cp:Show()

    local width = cp:GetWidth()
    local pointWidth = (width - (maxPoints - 1) * 2) / maxPoints

    for i = 1, maxPoints do
        local bar = cp.points[i]
        bar:Show()
        bar:ClearAllPoints()
        bar:SetSize(pointWidth, cp:GetHeight())

        if i == 1 then
            bar:SetPoint("LEFT", cp, "LEFT", 0, 0)
        else
            bar:SetPoint("LEFT", cp.points[i - 1], "RIGHT", 2, 0)
        end

        -- Color based on combo point count
        local r, g, b
        if points >= maxPoints then
            r, g, b = 1, 0, 0 -- Max points: red
        elseif points >= maxPoints - 1 then
            r, g, b = 1, 0.5, 0 -- Almost max: orange
        else
            r, g, b = 1, 0.96, 0.41 -- Normal: yellow
        end

        if i <= points then
            bar:SetStatusBarColor(r, g, b)
            bar:SetValue(1)
            bar:SetAlpha(1)
        else
            bar:SetValue(0)
            bar:SetAlpha(0.3)
        end
    end

    for i = maxPoints + 1, 8 do
        cp.points[i]:Hide()
    end
end
