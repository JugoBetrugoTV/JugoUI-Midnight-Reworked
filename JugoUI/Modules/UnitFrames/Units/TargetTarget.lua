--[[
    JugoUI - UnitFrames/Units/TargetTarget.lua
    Target of Target unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateTargetTargetFrame()
    local db = self.db.targettarget
    local frame = self:CreateUnitFrame("targettarget", "JugoUI_TargetTarget", db)

    if not frame then return end

    -- Register for target of target changes
    frame:RegisterEvent("UNIT_TARGET")

    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "UNIT_TARGET" and unit == "target" then
            UF:UpdateFrame(frame)
        else
            oldHandler(self, event, unit, ...)
        end
    end)

    return frame
end
