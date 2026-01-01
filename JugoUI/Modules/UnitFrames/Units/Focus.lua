--[[
    JugoUI - UnitFrames/Units/Focus.lua
    Focus unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateFocusFrame()
    local db = self.db.focus
    local frame = self:CreateUnitFrame("focus", "JugoUI_Focus", db)

    if not frame then return end

    return frame
end
