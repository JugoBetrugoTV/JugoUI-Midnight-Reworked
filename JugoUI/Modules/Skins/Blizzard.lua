--[[
    JugoUI - Skins/Blizzard.lua
    Blizzard frame skinning
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local SK = E.Skins

function SK:SkinBlizzardFrames()
    local db = self.db.blizzard

    -- Character frame
    if db.character and CharacterFrame then
        self:SkinFrame(CharacterFrame)
    end

    -- Spellbook
    if db.spellbook and SpellBookFrame then
        self:SkinFrame(SpellBookFrame)
    end

    -- Quest log
    if db.quest and QuestLogFrame then
        self:SkinFrame(QuestLogFrame)
    end

    -- More Blizzard frame skinning can be added here
end
