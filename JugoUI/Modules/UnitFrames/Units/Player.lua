--[[
    JugoUI - UnitFrames/Units/Player.lua
    Player unit frame
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

function UF:CreatePlayerFrame()
    local db = self.db.player
    local frame = self:CreateUnitFrame("player", "JugoUI_Player", db)

    if not frame then return end

    -- Add resting indicator
    frame.RestingIndicator = self:CreateRestingIndicator(frame)

    -- Add combat indicator
    frame.CombatIndicator = self:CreateCombatIndicator(frame)

    -- Register additional player-specific events
    frame:RegisterEvent("PLAYER_UPDATE_RESTING")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Override event handler for player-specific events
    local oldHandler = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_UPDATE_RESTING" then
            UF:UpdateRestingIndicator(frame)
        elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            UF:UpdateCombatIndicator(frame)
        else
            oldHandler(self, event, ...)
        end
    end)

    -- Initial state updates
    self:UpdateRestingIndicator(frame)
    self:UpdateCombatIndicator(frame)

    return frame
end
