--[[
    JugoUI - Nameplates/Auras.lua
    Nameplate aura display
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local NP = E.Nameplates

function NP:CreateAuras(parent)
    local db = self.db.auras
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(db.size * db.maxAuras + 2 * (db.maxAuras - 1), db.size)
    container:SetPoint("BOTTOM", parent.Health, "TOP", 0, 20)

    container.icons = {}

    for i = 1, db.maxAuras do
        local icon = self:CreateAuraIcon(container, i)
        container.icons[i] = icon
    end

    return container
end

function NP:CreateAuraIcon(parent, index)
    local db = self.db.auras
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(db.size, db.size)
    icon:SetPoint("LEFT", parent, "LEFT", (index - 1) * (db.size + 2), 0)

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon.texture)
    icon.cooldown:SetReverse(true)

    icon.count = E:CreateFontString(icon, 9, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)

    icon.border = E:CreateBackdrop(icon, "Default")

    icon:Hide()
    return icon
end

function NP:UpdateAuras(frame)
    if not frame.Auras then return end

    local unit = frame.unit
    local db = self.db.auras

    -- Hide all first
    for i = 1, #frame.Auras.icons do
        frame.Auras.icons[i]:Hide()
    end

    local index = 1
    local filter = db.showDebuffs and "HARMFUL" or "HELPFUL"

    for i = 1, 40 do
        if index > db.maxAuras then break end

        local auraData = E.API:GetAuraDataByIndex(unit, i, filter)
        if not auraData then break end

        -- Filter to player debuffs only if enabled
        if not db.onlyPlayer or auraData.isFromPlayerOrPlayerPet then
            local icon = frame.Auras.icons[index]
            if icon then
                icon:Show()
                icon.texture:SetTexture(auraData.icon)

                if auraData.applications and auraData.applications > 1 then
                    icon.count:SetText(auraData.applications)
                else
                    icon.count:SetText("")
                end

                if auraData.duration and auraData.duration > 0 then
                    E.API:SetCooldownFromExpiration(icon.cooldown, auraData.expirationTime, auraData.duration, true)
                else
                    icon.cooldown:Clear()
                end

                -- Debuff type color
                if filter == "HARMFUL" and auraData.dispelName then
                    local color = E.media.colors.debuffType[auraData.dispelName]
                    if color then
                        icon.border:SetBackdropBorderColor(color[1], color[2], color[3])
                    end
                else
                    icon.border:SetBackdropBorderColor(0.2, 0.2, 0.2)
                end

                index = index + 1
            end
        end
    end
end
