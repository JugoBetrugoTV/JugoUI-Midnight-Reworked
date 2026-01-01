--[[
    JugoUI - UnitFrames/Units/PetTarget.lua
    Pet Target unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreatePetTargetFrame()
    local db = self.db.pettarget or {
        enabled = false,
        width = 80,
        height = 20,
        point = {"LEFT", "JugoUI_Pet", "RIGHT", 5, 0},
    }

    if not db.enabled then return end

    local frame = self:CreateUnitFrame("pettarget", "JugoUI_PetTarget", db)

    if not frame then return end

    -- Register for pet target changes
    frame:RegisterEvent("UNIT_TARGET")

    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "UNIT_TARGET" and unit == "pet" then
            UF:UpdateFrame(frame)
        else
            oldHandler(self, event, unit, ...)
        end
    end)

    return frame
end
