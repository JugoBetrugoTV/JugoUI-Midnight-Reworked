--[[
    JugoUI - UnitFrames/Elements/CombatIndicator.lua
    Combat indicator element (player only)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateCombatIndicator(frame)
    local combat = frame:CreateTexture(nil, "OVERLAY")
    combat:SetSize(20, 20)
    combat:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
    combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    combat:SetTexCoord(0.5, 1, 0, 0.5)
    combat:Hide()

    return combat
end

function UF:UpdateCombatIndicator(frame)
    if not frame or not frame.CombatIndicator then return end

    if frame.unit ~= "player" then
        frame.CombatIndicator:Hide()
        return
    end

    if UnitAffectingCombat("player") then
        frame.CombatIndicator:Show()
    else
        frame.CombatIndicator:Hide()
    end
end

UF:RegisterElement("CombatIndicator", UF.CreateCombatIndicator)
