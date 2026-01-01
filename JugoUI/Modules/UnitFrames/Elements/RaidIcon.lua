--[[
    JugoUI - UnitFrames/Elements/RaidIcon.lua
    Raid target icon element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateRaidIcon(frame)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16, 16)
    icon:SetPoint("TOP", frame, "TOP", 0, 8)
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    icon:Hide()

    return icon
end

function UF:UpdateRaidIcon(frame)
    if not frame or not frame.RaidTargetIndicator then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.RaidTargetIndicator:Hide()
        return
    end

    local index = GetRaidTargetIndex(unit)
    if index then
        SetRaidTargetIconTexture(frame.RaidTargetIndicator, index)
        frame.RaidTargetIndicator:Show()
    else
        frame.RaidTargetIndicator:Hide()
    end
end

UF:RegisterElement("RaidIcon", UF.CreateRaidIcon)
