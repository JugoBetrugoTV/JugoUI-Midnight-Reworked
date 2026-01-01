--[[
    JugoUI - UnitFrames/Elements/Auras.lua
    Buff/Debuff display element for unit frames
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

--[[
    Create Aura Container
]]
function UF:CreateAuras(frame, filter, config)
    local auras = CreateFrame("Frame", nil, frame)
    auras:SetSize(config.size * config.num + config.spacing * (config.num - 1), config.size)

    -- Position based on filter
    if filter == "HELPFUL" then
        auras:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 5)
    else
        auras:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -5)
    end

    auras.filter = filter
    auras.config = config
    auras.icons = {}

    -- Create aura icons
    for i = 1, config.num do
        local icon = self:CreateAuraIcon(auras, i, config)
        auras.icons[i] = icon
    end

    return auras
end

--[[
    Create Single Aura Icon
]]
function UF:CreateAuraIcon(parent, index, config)
    local size = config.size

    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)

    -- Position in row
    local col = (index - 1) % config.num
    icon:SetPoint("TOPLEFT", parent, "TOPLEFT", col * (size + config.spacing), 0)

    -- Background
    icon.backdrop = E:CreateBackdrop(icon, "Default")

    -- Icon texture
    icon.icon = icon:CreateTexture(nil, "ARTWORK")
    icon.icon:SetPoint("TOPLEFT", 1, -1)
    icon.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    -- Cooldown
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon.icon)
    icon.cooldown:SetReverse(true)
    icon.cooldown:SetHideCountdownNumbers(false)

    -- Count text
    icon.count = E:CreateFontString(icon, 10, "OUTLINE")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)

    -- Duration text
    icon.duration = E:CreateFontString(icon, 9, "OUTLINE")
    icon.duration:SetPoint("TOP", icon, "BOTTOM", 0, -2)

    -- Tooltip
    icon:EnableMouse(true)
    icon:SetScript("OnEnter", function(self)
        if self.auraData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetUnitAura(parent:GetParent().unit, self.auraIndex, parent.filter)
            GameTooltip:Show()
        end
    end)
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    icon:Hide()
    return icon
end

--[[
    Update Auras
]]
function UF:UpdateAuras(frame, filter)
    local auras = filter == "HELPFUL" and frame.Buffs or frame.Debuffs
    if not auras then return end

    local unit = frame.unit
    if not UnitExists(unit) then
        for i = 1, #auras.icons do
            auras.icons[i]:Hide()
        end
        return
    end

    local config = auras.config
    local index = 1

    -- Iterate through auras
    for i = 1, 40 do
        local auraData = E.API:GetAuraDataByIndex(unit, i, filter)
        if not auraData then break end

        local icon = auras.icons[index]
        if not icon then break end

        -- Check if this is a secret aura
        local isSecret = auraData.isSecret or E:IsSecretValue(auraData.name)

        -- Show icon
        icon:Show()
        icon.auraData = auraData
        icon.auraIndex = i

        -- Set icon texture
        if auraData.icon then
            if not isSecret then
                icon.icon:SetTexture(auraData.icon)
            else
                icon.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
        end

        -- Set count
        if auraData.applications and auraData.applications > 1 then
            icon.count:SetText(auraData.applications)
        else
            icon.count:SetText("")
        end

        -- Set cooldown
        if auraData.duration and auraData.duration > 0 and auraData.expirationTime then
            if not E:IsSecretValue(auraData.duration) and not E:IsSecretValue(auraData.expirationTime) then
                E.API:SetCooldownFromExpiration(icon.cooldown, auraData.expirationTime, auraData.duration, true)
            else
                icon.cooldown:Clear()
            end
        else
            icon.cooldown:Clear()
        end

        -- Set border color for debuffs
        if filter == "HARMFUL" and auraData.dispelName then
            local color = E.media.colors.debuffType[auraData.dispelName]
            if color then
                icon.backdrop:SetBackdropBorderColor(color[1], color[2], color[3])
            else
                icon.backdrop:SetBackdropBorderColor(0.8, 0, 0)
            end
        else
            icon.backdrop:SetBackdropBorderColor(0.2, 0.2, 0.2)
        end

        index = index + 1
    end

    -- Hide unused icons
    for i = index, #auras.icons do
        auras.icons[i]:Hide()
        auras.icons[i].auraData = nil
    end
end

-- Register element
UF:RegisterElement("Auras", UF.CreateAuras)
