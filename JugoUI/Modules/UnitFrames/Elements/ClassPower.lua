--[[
    JugoUI - UnitFrames/Elements/ClassPower.lua
    Class-specific resource display (combo points, runes, chi, etc.)
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local UF = E.UnitFrames

-- Class power types
local classPowerTypes = {
    ROGUE = Enum.PowerType.ComboPoints,
    DRUID = Enum.PowerType.ComboPoints,
    PALADIN = Enum.PowerType.HolyPower,
    WARLOCK = Enum.PowerType.SoulShards,
    MONK = Enum.PowerType.Chi,
    MAGE = Enum.PowerType.ArcaneCharges,
    DEATHKNIGHT = Enum.PowerType.Runes,
    EVOKER = Enum.PowerType.Essence,
}

-- Class power colors
local classPowerColors = {
    COMBO_POINTS = {1.00, 0.96, 0.41},
    HOLY_POWER = {0.95, 0.90, 0.60},
    SOUL_SHARDS = {0.50, 0.32, 0.55},
    CHI = {0.71, 1.00, 0.92},
    ARCANE_CHARGES = {0.10, 0.10, 0.98},
    RUNES = {0.50, 0.50, 0.50},
    ESSENCE = {0.00, 0.80, 0.80},
}

-- Rune colors
local runeColors = {
    [1] = {0.77, 0.12, 0.23}, -- Blood
    [2] = {0.77, 0.12, 0.23}, -- Blood
    [3] = {0.00, 1.00, 0.60}, -- Unholy
    [4] = {0.00, 1.00, 0.60}, -- Unholy
    [5] = {0.40, 0.80, 1.00}, -- Frost
    [6] = {0.40, 0.80, 1.00}, -- Frost
}

--[[
    Create Class Power
]]
function UF:CreateClassPower(frame, config)
    local classPower = CreateFrame("Frame", nil, frame)
    classPower:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
    classPower:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
    classPower:SetHeight(config.height or 8)

    classPower.bars = {}
    classPower.config = config

    -- Create individual bars (max 10 for combo points with certain talents)
    for i = 1, 10 do
        local bar = CreateFrame("StatusBar", nil, classPower)
        bar:SetStatusBarTexture(E.media.textures.flat)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)

        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints()
        bar.bg:SetTexture(E.media.textures.flat)
        bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

        bar:Hide()
        classPower.bars[i] = bar
    end

    -- Register for power updates
    classPower:RegisterEvent("UNIT_POWER_UPDATE")
    classPower:RegisterEvent("UNIT_MAXPOWER")
    classPower:RegisterEvent("RUNE_POWER_UPDATE")
    classPower:RegisterEvent("PLAYER_ENTERING_WORLD")
    classPower:RegisterEvent("PLAYER_TALENT_UPDATE")

    classPower:SetScript("OnEvent", function(self, event, unit)
        if event == "RUNE_POWER_UPDATE" or unit == "player" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TALENT_UPDATE" then
            UF:UpdateClassPower(frame)
        end
    end)

    return classPower
end

--[[
    Update Class Power
]]
function UF:UpdateClassPower(frame)
    if not frame or not frame.ClassPower then return end

    local classPower = frame.ClassPower
    local class = E.myclass
    local spec = GetSpecialization()

    -- Only show for player frame
    if frame.unit ~= "player" then
        classPower:Hide()
        return
    end

    -- Special handling for druids (only in cat form)
    if class == "DRUID" then
        local form = GetShapeshiftFormID()
        if form ~= 1 then -- Not cat form
            classPower:Hide()
            return
        end
    end

    local powerType = classPowerTypes[class]
    if not powerType then
        classPower:Hide()
        return
    end

    -- Death Knight runes
    if class == "DEATHKNIGHT" then
        self:UpdateRunes(frame)
        return
    end

    local current = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)

    if max == 0 then
        classPower:Hide()
        return
    end

    classPower:Show()

    -- Update bar sizes
    local width = classPower:GetWidth()
    local barWidth = (width - (max - 1) * 2) / max

    for i = 1, max do
        local bar = classPower.bars[i]
        bar:Show()
        bar:ClearAllPoints()
        bar:SetSize(barWidth, classPower:GetHeight())

        if i == 1 then
            bar:SetPoint("LEFT", classPower, "LEFT", 0, 0)
        else
            bar:SetPoint("LEFT", classPower.bars[i - 1], "RIGHT", 2, 0)
        end

        -- Set color
        local powerToken = select(2, UnitPowerType("player"))
        local color = classPowerColors[powerToken] or {1, 1, 1}
        bar:SetStatusBarColor(color[1], color[2], color[3])
        bar.bg:SetVertexColor(color[1] * 0.2, color[2] * 0.2, color[3] * 0.2)

        -- Set value
        if i <= current then
            bar:SetValue(1)
            bar:SetAlpha(1)
        else
            bar:SetValue(0)
            bar:SetAlpha(0.3)
        end
    end

    -- Hide extra bars
    for i = max + 1, 10 do
        classPower.bars[i]:Hide()
    end
end

--[[
    Update Runes (Death Knight specific)
]]
function UF:UpdateRunes(frame)
    local classPower = frame.ClassPower

    classPower:Show()

    local numRunes = UnitPowerMax("player", Enum.PowerType.Runes)
    local width = classPower:GetWidth()
    local barWidth = (width - (numRunes - 1) * 2) / numRunes

    for i = 1, numRunes do
        local bar = classPower.bars[i]
        bar:Show()
        bar:ClearAllPoints()
        bar:SetSize(barWidth, classPower:GetHeight())

        if i == 1 then
            bar:SetPoint("LEFT", classPower, "LEFT", 0, 0)
        else
            bar:SetPoint("LEFT", classPower.bars[i - 1], "RIGHT", 2, 0)
        end

        -- Get rune info
        local start, duration, ready = GetRuneCooldown(i)
        local color = runeColors[i] or {0.5, 0.5, 0.5}

        bar:SetStatusBarColor(color[1], color[2], color[3])
        bar.bg:SetVertexColor(color[1] * 0.2, color[2] * 0.2, color[3] * 0.2)

        if ready then
            bar:SetValue(1)
            bar:SetAlpha(1)
        else
            -- Show recharge progress
            if duration and duration > 0 then
                local progress = (GetTime() - start) / duration
                bar:SetValue(progress)
            else
                bar:SetValue(0)
            end
            bar:SetAlpha(0.5)
        end
    end

    for i = numRunes + 1, 10 do
        classPower.bars[i]:Hide()
    end
end

-- Register element
UF:RegisterElement("ClassPower", UF.CreateClassPower)
