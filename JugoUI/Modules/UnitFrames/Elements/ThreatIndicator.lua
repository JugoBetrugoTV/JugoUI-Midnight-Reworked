--[[
    JugoUI - UnitFrames/Elements/ThreatIndicator.lua
    Threat border indicator element
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateThreatIndicator(frame)
    local threat = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    threat:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3)
    threat:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
    threat:SetBackdrop({
        edgeFile = E.media.textures.glowBorder,
        edgeSize = 4,
    })
    threat:SetBackdropBorderColor(0, 0, 0, 0)
    threat:Hide()

    return threat
end

function UF:UpdateThreatIndicator(frame)
    if not frame or not frame.ThreatIndicator then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        frame.ThreatIndicator:Hide()
        return
    end

    -- Get threat situation
    local status = UnitThreatSituation(unit)
    if status and status > 0 then
        local color = E.media.colors.threat[status]
        if color then
            frame.ThreatIndicator:SetBackdropBorderColor(color[1], color[2], color[3], 0.8)
            frame.ThreatIndicator:Show()
        else
            frame.ThreatIndicator:Hide()
        end
    else
        frame.ThreatIndicator:Hide()
    end
end

UF:RegisterElement("ThreatIndicator", UF.CreateThreatIndicator)
