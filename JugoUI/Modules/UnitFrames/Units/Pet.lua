--[[
    JugoUI - UnitFrames/Units/Pet.lua
    Pet unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreatePetFrame()
    local db = self.db.pet
    local frame = self:CreateUnitFrame("pet", "JugoUI_Pet", db)

    if not frame then return end

    -- Register pet-specific events
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("PET_UI_UPDATE")

    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "UNIT_PET" and unit == "player" then
            UF:UpdateFrame(frame)
        elseif event == "PET_UI_UPDATE" then
            UF:UpdateFrame(frame)
        else
            oldHandler(self, event, unit, ...)
        end
    end)

    return frame
end
