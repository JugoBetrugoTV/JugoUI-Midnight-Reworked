--[[
    JugoUI - Tooltip/Core.lua
    Tooltip enhancement module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local TT = E:NewModule("Tooltip", "AceHook-3.0")
E.Tooltip = TT

function TT:OnInitialize()
    self.db = E.db.tooltip
end

function TT:OnEnable()
    self:StyleTooltip()
    self:HookTooltips()
end

function TT:StyleTooltip()
    local db = self.db

    -- Style GameTooltip
    GameTooltip:SetBackdrop({
        bgFile = E.media.textures.flat,
        edgeFile = E.media.textures.flat,
        edgeSize = 1,
    })
    GameTooltip:SetBackdropColor(0.03, 0.03, 0.03, 0.9)
    GameTooltip:SetBackdropBorderColor(0.2, 0.2, 0.2)

    -- Health bar
    if GameTooltipStatusBar then
        GameTooltipStatusBar:SetStatusBarTexture(E.media.textures.flat)
        GameTooltipStatusBar:SetHeight(6)
        GameTooltipStatusBar:ClearAllPoints()
        GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 1, 2)
        GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -1, 2)
    end
end

function TT:HookTooltips()
    self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "OnTooltipSetUnit")
    self:SecureHook(GameTooltip, "SetUnitAura", "OnSetUnitAura")
    self:SecureHook(GameTooltip, "SetUnitBuff", "OnSetUnitAura")
    self:SecureHook(GameTooltip, "SetUnitDebuff", "OnSetUnitAura")

    -- Position hook
    if not self.db.cursorAnchor then
        hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
            TT:SetTooltipPosition(tooltip)
        end)
    end
end

function TT:SetTooltipPosition(tooltip)
    local db = self.db
    tooltip:ClearAllPoints()
    local point = db.point
    tooltip:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)
end

function TT:OnTooltipSetUnit(tooltip)
    local db = self.db
    local unit = select(2, tooltip:GetUnit())
    if not unit then return end

    -- Class-colored border
    if db.classColoredBorder and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local r, g, b = E:GetClassColor(class)
            tooltip:SetBackdropBorderColor(r, g, b)
        end
    else
        tooltip:SetBackdropBorderColor(0.2, 0.2, 0.2)
    end

    -- Add guild
    if db.showGuild then
        local guildName, guildRankName = GetGuildInfo(unit)
        if guildName then
            local color = db.guildColor
            tooltip:AddLine(format("<%s> %s", guildName, guildRankName or ""), color[1], color[2], color[3])
        end
    end

    -- Add target
    if db.showTarget then
        local target = unit .. "target"
        if UnitExists(target) then
            local targetName = UnitName(target)
            local _, targetClass = UnitClass(target)
            if targetName then
                local color = {1, 1, 1}
                if targetClass then
                    color = {E:GetClassColor(targetClass)}
                end
                tooltip:AddLine("Target: " .. targetName, color[1], color[2], color[3])
            end
        end
    end

    -- Add item level
    if db.showItemLevel and UnitIsPlayer(unit) then
        local ilvl = self:GetUnitItemLevel(unit)
        if ilvl then
            tooltip:AddLine("Item Level: " .. floor(ilvl), 1, 1, 0)
        end
    end

    -- Add role
    if db.showRole then
        local role = UnitGroupRolesAssigned(unit)
        if role and role ~= "NONE" then
            local roleText = role == "TANK" and "Tank" or (role == "HEALER" and "Healer" or "DPS")
            tooltip:AddLine("Role: " .. roleText, 0.7, 0.7, 0.7)
        end
    end
end

function TT:GetUnitItemLevel(unit)
    if not UnitIsPlayer(unit) then return nil end

    local total = 0
    local count = 0

    for i = 1, 17 do
        if i ~= 4 then -- Skip shirt slot
            local link = GetInventoryItemLink(unit, i)
            if link then
                local ilvl = C_Item.GetCurrentItemLevel(link)
                if ilvl then
                    total = total + ilvl
                    count = count + 1
                end
            end
        end
    end

    if count > 0 then
        return total / count
    end
    return nil
end

function TT:OnSetUnitAura(tooltip, unit, index, filter)
    -- Could add spell ID display or other aura info
end

function TT:ProfileChanged()
    self.db = E.db.tooltip
    self:StyleTooltip()
end
