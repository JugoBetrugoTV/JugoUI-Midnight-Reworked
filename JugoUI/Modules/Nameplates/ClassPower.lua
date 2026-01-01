--[[
    JugoUI - Nameplates/ClassPower.lua
    Class power display on nameplates (combo points on target)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local NP = E.Nameplates

function NP:CreateClassPower(parent)
    local db = self.db.classPower
    if not db or not db.enabled then return nil end

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(self.db.width, 6)
    container:SetPoint("BOTTOM", parent.Health, "TOP", 0, 2)

    container.bars = {}

    for i = 1, 10 do
        local bar = CreateFrame("StatusBar", nil, container)
        bar:SetStatusBarTexture(E.media.textures.flat)
        bar:SetStatusBarColor(1, 0.96, 0.41)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints()
        bar.bg:SetTexture(E.media.textures.flat)
        bar.bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)

        bar:Hide()
        container.bars[i] = bar
    end

    container:RegisterEvent("UNIT_POWER_UPDATE")
    container:RegisterEvent("PLAYER_TARGET_CHANGED")

    container:SetScript("OnEvent", function()
        NP:UpdateClassPower(parent)
    end)

    container:Hide()
    return container
end

function NP:UpdateClassPower(frame)
    if not frame.ClassPower then return end
    if not frame.unit then return end

    local cp = frame.ClassPower

    -- Only show on target
    if not UnitIsUnit(frame.unit, "target") then
        cp:Hide()
        return
    end

    local points = UnitPower("player", Enum.PowerType.ComboPoints)
    local maxPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)

    if maxPoints == 0 or points == 0 then
        cp:Hide()
        return
    end

    cp:Show()

    local width = cp:GetWidth()
    local barWidth = (width - (maxPoints - 1) * 2) / maxPoints

    for i = 1, maxPoints do
        local bar = cp.bars[i]
        bar:Show()
        bar:ClearAllPoints()
        bar:SetSize(barWidth, cp:GetHeight())

        if i == 1 then
            bar:SetPoint("LEFT", cp, "LEFT", 0, 0)
        else
            bar:SetPoint("LEFT", cp.bars[i - 1], "RIGHT", 2, 0)
        end

        if i <= points then
            bar:SetAlpha(1)
        else
            bar:SetAlpha(0.3)
        end
    end

    for i = maxPoints + 1, 10 do
        cp.bars[i]:Hide()
    end
end
