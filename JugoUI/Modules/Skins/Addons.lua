--[[
    JugoUI - Skins/Addons.lua
    Third-party addon skinning
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local SK = E.Skins

function SK:SkinAddon(addon)
    local db = self.db.addons

    if addon == "WeakAuras" and db.weakauras then
        -- Skin WeakAuras frames
    elseif addon == "Details" and db.details then
        -- Skin Details windows
    elseif addon == "DBM-Core" and db.dbm then
        -- Skin DBM
    elseif addon == "BigWigs" and db.bigwigs then
        -- Skin BigWigs
    end
end
