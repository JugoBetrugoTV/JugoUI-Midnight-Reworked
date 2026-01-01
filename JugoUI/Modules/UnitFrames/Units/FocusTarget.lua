--[[
    JugoUI - UnitFrames/Units/FocusTarget.lua
    Focus Target unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreateFocusTargetFrame()
    local db = self.db.focustarget
    local frame = self:CreateUnitFrame("focustarget", "JugoUI_FocusTarget", db)

    if not frame then return end

    -- Register for focus target changes
    frame:RegisterEvent("UNIT_TARGET")

    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "UNIT_TARGET" and unit == "focus" then
            UF:UpdateFrame(frame)
        else
            oldHandler(self, event, unit, ...)
        end
    end)

    return frame
end
