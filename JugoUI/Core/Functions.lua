--[[
    JugoUI - Functions.lua
    Utility functions and helpers
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

--[[
    Number Formatting
]]
function E:ShortValue(value)
    if E:IsSecretValue(value) then return value end

    if value >= 1e12 then
        return format("%.2fT", value / 1e12)
    elseif value >= 1e9 then
        return format("%.2fB", value / 1e9)
    elseif value >= 1e6 then
        return format("%.2fM", value / 1e6)
    elseif value >= 1e3 then
        return format("%.1fK", value / 1e3)
    else
        return format("%d", value)
    end
end

function E:CommaValue(value)
    if E:IsSecretValue(value) then return value end

    local formatted = tostring(floor(value + 0.5))
    local k
    while true do
        formatted, k = gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end

function E:Round(value, decimals)
    if E:IsSecretValue(value) then return value end

    local mult = 10 ^ (decimals or 0)
    return floor(value * mult + 0.5) / mult
end

function E:Clamp(value, min, max)
    if E:IsSecretValue(value) then return value end

    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

--[[
    Time Formatting
]]
function E:FormatTime(seconds)
    if E:IsSecretValue(seconds) then return seconds end

    if seconds >= 86400 then
        return format("%dd", ceil(seconds / 86400))
    elseif seconds >= 3600 then
        return format("%dh", ceil(seconds / 3600))
    elseif seconds >= 60 then
        return format("%dm", ceil(seconds / 60))
    elseif seconds >= 1 then
        return format("%d", seconds)
    else
        return format("%.1f", seconds)
    end
end

function E:FormatTimeLong(seconds)
    if E:IsSecretValue(seconds) then return seconds end

    local days = floor(seconds / 86400)
    local hours = floor((seconds % 86400) / 3600)
    local minutes = floor((seconds % 3600) / 60)
    local secs = floor(seconds % 60)

    if days > 0 then
        return format("%d:%02d:%02d:%02d", days, hours, minutes, secs)
    elseif hours > 0 then
        return format("%d:%02d:%02d", hours, minutes, secs)
    else
        return format("%d:%02d", minutes, secs)
    end
end

--[[
    String Utilities
]]
function E:Trim(str)
    if not str then return "" end
    return str:match("^%s*(.-)%s*$") or ""
end

function E:Split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

function E:Truncate(str, maxLength, suffix)
    if not str or #str <= maxLength then return str end
    suffix = suffix or "..."
    return str:sub(1, maxLength - #suffix) .. suffix
end

function E:StripColors(str)
    if not str then return "" end
    return str:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
end

function E:UnitNameWithColor(unit)
    local name = UnitName(unit)
    if not name then return "" end

    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class then
            local color = E:GetClassColor(class, true)
            return color .. name .. "|r"
        end
    end

    return name
end

--[[
    Table Utilities
]]
function E:CopyTable(source, destination)
    destination = destination or {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            destination[k] = E:CopyTable(v, destination[k])
        else
            destination[k] = v
        end
    end
    return destination
end

function E:MergeTable(source, destination)
    for k, v in pairs(source) do
        if type(v) == "table" then
            if not destination[k] then destination[k] = {} end
            E:MergeTable(v, destination[k])
        elseif destination[k] == nil then
            destination[k] = v
        end
    end
    return destination
end

function E:TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function E:Contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

function E:WipeTable(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
    return tbl
end

--[[
    Frame Utilities
]]
function E:SetTemplate(frame, template, glossTexture, ignoreUpdates)
    template = template or "Default"

    if template == "Transparent" then
        frame:SetBackdrop({
            bgFile = E.media.textures.blank,
            edgeFile = E.media.textures.blank,
            edgeSize = 1,
        })
        frame:SetBackdropColor(unpack(E.media.colors.ui.background))
        frame:SetBackdropBorderColor(unpack(E.media.colors.ui.border))
    elseif template == "Default" then
        frame:SetBackdrop({
            bgFile = E.media.textures.blank,
            edgeFile = E.media.textures.blank,
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2)
    elseif template == "NoBackdrop" then
        frame:SetBackdrop(nil)
    end

    if not ignoreUpdates then
        frame.template = template
    end
end

function E:CreateBackdrop(frame, template, glossTexture, ignoreUpdates, forcePixelPerfect)
    local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    backdrop:SetPoint("TOPLEFT", frame, -2, 2)
    backdrop:SetPoint("BOTTOMRIGHT", frame, 2, -2)
    backdrop:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))

    E:SetTemplate(backdrop, template, glossTexture, ignoreUpdates)

    frame.backdrop = backdrop
    return backdrop
end

function E:CreateShadow(frame, size, r, g, b, a)
    if frame.shadow then return frame.shadow end

    size = size or 4
    r = r or 0
    g = g or 0
    b = b or 0
    a = a or 0.5

    local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    shadow:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
    shadow:SetPoint("TOPLEFT", frame, -size, size)
    shadow:SetPoint("BOTTOMRIGHT", frame, size, -size)
    shadow:SetBackdrop({
        bgFile = nil,
        edgeFile = E.media.textures.glowBorder,
        edgeSize = size,
        insets = {left = size, right = size, top = size, bottom = size},
    })
    shadow:SetBackdropBorderColor(r, g, b, a)

    frame.shadow = shadow
    return shadow
end

function E:Kill(object)
    if object.UnregisterAllEvents then
        object:UnregisterAllEvents()
        object:SetParent(E.hiddenFrame)
    else
        object.Show = object.Hide
    end
    object:Hide()
end

function E:CreateHiddenFrame()
    if not E.hiddenFrame then
        E.hiddenFrame = CreateFrame("Frame", "JugoUIHiddenFrame")
        E.hiddenFrame:Hide()
    end
    return E.hiddenFrame
end
E:CreateHiddenFrame()

--[[
    Position and Sizing
]]
function E:Scale(value)
    return value * E.uiscale
end

function E:PixelPerfect(value)
    local scale = E.uiscale
    return floor(value / scale + 0.5) * scale
end

function E:SetSize(frame, width, height)
    frame:SetSize(E:PixelPerfect(width), E:PixelPerfect(height or width))
end

function E:Point(frame, point, relativeTo, relativePoint, xOffset, yOffset)
    if type(relativeTo) == "number" then
        -- Simple point (point, x, y)
        frame:SetPoint(point, E:PixelPerfect(relativeTo), E:PixelPerfect(relativePoint or 0))
    else
        -- Full point
        xOffset = xOffset or 0
        yOffset = yOffset or 0
        frame:SetPoint(point, relativeTo, relativePoint, E:PixelPerfect(xOffset), E:PixelPerfect(yOffset))
    end
end

--[[
    Status Bar Helpers
]]
function E:CreateStatusBar(parent, name, showSpark)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetStatusBarTexture(E.media.textures.flat)
    bar:GetStatusBarTexture():SetHorizTile(false)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(E.media.textures.flat)
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    if showSpark then
        bar.spark = bar:CreateTexture(nil, "OVERLAY")
        bar.spark:SetTexture(E.media.textures.spark)
        bar.spark:SetBlendMode("ADD")
        bar.spark:SetSize(16, bar:GetHeight() * 2)
    end

    return bar
end

function E:SetStatusBarGradient(bar, r1, g1, b1, r2, g2, b2)
    bar:GetStatusBarTexture():SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, 1), CreateColor(r2, g2, b2, 1))
end

--[[
    Font String Helpers
]]
function E:CreateFontString(parent, size, style, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(E.media.fonts.normal, size or 12, style or "")
    fs:SetJustifyH(justify or "CENTER")
    fs:SetWordWrap(false)

    return fs
end

--[[
    Texture Helpers
]]
function E:CreateTexture(parent, layer, texture, sublayer)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK", nil, sublayer or 0)
    if texture then
        tex:SetTexture(texture)
    end
    return tex
end

--[[
    Unit Helpers
]]
function E:GetUnitPowerType(unit)
    unit = unit or "player"
    local powerType, powerToken = UnitPowerType(unit)
    return powerToken, powerType
end

function E:IsUnitDead(unit)
    return UnitIsDeadOrGhost(unit) or UnitIsDead(unit) or not UnitIsConnected(unit)
end

function E:UnitThreatLevel(unit)
    local _, _, scaledPercent, _, _ = UnitDetailedThreatSituation("player", unit)
    if scaledPercent and scaledPercent > 0 then
        if scaledPercent >= 100 then
            return 3 -- Have aggro
        elseif scaledPercent >= 75 then
            return 2 -- Will pull soon
        elseif scaledPercent >= 50 then
            return 1 -- Warning
        end
    end
    return 0 -- No threat
end

--[[
    Combat Check
]]
function E:InCombatLockdown()
    return InCombatLockdown()
end

--[[
    Debounce/Throttle
]]
function E:Debounce(func, delay)
    local timer = nil
    return function(...)
        local args = {...}
        if timer then
            timer:Cancel()
        end
        timer = C_Timer.NewTimer(delay, function()
            func(unpack(args))
            timer = nil
        end)
    end
end

function E:Throttle(func, delay)
    local lastCall = 0
    return function(...)
        local now = GetTime()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

--[[
    Animation Helpers
]]
function E:CreateAnimationGroup(frame)
    local ag = frame:CreateAnimationGroup()
    return ag
end

function E:CreateFadeIn(frame, duration, startAlpha, endAlpha)
    duration = duration or 0.3
    startAlpha = startAlpha or 0
    endAlpha = endAlpha or 1

    local ag = frame:CreateAnimationGroup()
    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(startAlpha)
    alpha:SetToAlpha(endAlpha)
    alpha:SetDuration(duration)

    ag:SetScript("OnPlay", function()
        frame:Show()
    end)

    ag:SetScript("OnFinished", function()
        frame:SetAlpha(endAlpha)
    end)

    frame.FadeIn = ag
    return ag
end

function E:CreateFadeOut(frame, duration, startAlpha, endAlpha)
    duration = duration or 0.3
    startAlpha = startAlpha or 1
    endAlpha = endAlpha or 0

    local ag = frame:CreateAnimationGroup()
    local alpha = ag:CreateAnimation("Alpha")
    alpha:SetFromAlpha(startAlpha)
    alpha:SetToAlpha(endAlpha)
    alpha:SetDuration(duration)

    ag:SetScript("OnFinished", function()
        frame:SetAlpha(endAlpha)
        if endAlpha == 0 then
            frame:Hide()
        end
    end)

    frame.FadeOut = ag
    return ag
end

--[[
    Class/Spec Utilities
]]
E.classInfo = {
    WARRIOR = {name = "Warrior", specs = {"Arms", "Fury", "Protection"}},
    PALADIN = {name = "Paladin", specs = {"Holy", "Protection", "Retribution"}},
    HUNTER = {name = "Hunter", specs = {"Beast Mastery", "Marksmanship", "Survival"}},
    ROGUE = {name = "Rogue", specs = {"Assassination", "Outlaw", "Subtlety"}},
    PRIEST = {name = "Priest", specs = {"Discipline", "Holy", "Shadow"}},
    DEATHKNIGHT = {name = "Death Knight", specs = {"Blood", "Frost", "Unholy"}},
    SHAMAN = {name = "Shaman", specs = {"Elemental", "Enhancement", "Restoration"}},
    MAGE = {name = "Mage", specs = {"Arcane", "Fire", "Frost"}},
    WARLOCK = {name = "Warlock", specs = {"Affliction", "Demonology", "Destruction"}},
    MONK = {name = "Monk", specs = {"Brewmaster", "Mistweaver", "Windwalker"}},
    DRUID = {name = "Druid", specs = {"Balance", "Feral", "Guardian", "Restoration"}},
    DEMONHUNTER = {name = "Demon Hunter", specs = {"Havoc", "Vengeance"}},
    EVOKER = {name = "Evoker", specs = {"Devastation", "Preservation", "Augmentation"}},
}

function E:GetSpecInfo()
    local specIndex = GetSpecialization()
    if specIndex then
        local id, name, description, icon, role = GetSpecializationInfo(specIndex)
        return {
            index = specIndex,
            id = id,
            name = name,
            description = description,
            icon = icon,
            role = role,
        }
    end
    return nil
end

function E:GetPlayerRole()
    local spec = E:GetSpecInfo()
    if spec then
        return spec.role
    end
    return "DAMAGER"
end

--[[
    Tooltip Helpers
]]
function E:ShowTooltip(owner, anchor, ...)
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    for i = 1, select("#", ...) do
        local line = select(i, ...)
        if type(line) == "table" then
            GameTooltip:AddLine(unpack(line))
        else
            GameTooltip:AddLine(line, 1, 1, 1)
        end
    end
    GameTooltip:Show()
end

function E:HideTooltip()
    GameTooltip:Hide()
end
