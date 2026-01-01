--[[
    JugoUI - Castbars/Core.lua
    Standalone castbar module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local CB = E:NewModule("Castbars", "AceEvent-3.0")
E.Castbars = CB

CB.bars = {}

function CB:OnInitialize()
    self.db = E.db.castbars
end

function CB:OnEnable()
    if self.db.player.enabled then
        self:CreateCastbar("player")
    end

    if self.db.target.enabled then
        self:CreateCastbar("target")
    end

    if self.db.focus.enabled then
        self:CreateCastbar("focus")
    end

    -- Hide Blizzard castbars
    self:HideBlizzardCastbars()
end

function CB:OnDisable()
    for unit, bar in pairs(self.bars) do
        bar:Hide()
    end
end

function CB:CreateCastbar(unit)
    local db = self.db[unit]
    local name = "JugoUI_Castbar_" .. unit:gsub("^%l", string.upper)

    local bar = CreateFrame("StatusBar", name, UIParent)
    bar:SetSize(db.width, db.height)
    bar:SetStatusBarTexture(E.media.textures.flat)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    -- Position
    local point = db.point
    bar:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)

    -- Background
    bar.backdrop = E:CreateBackdrop(bar, "Transparent")

    bar.bg = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(E.media.textures.flat)
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Spark
    if db.spark ~= false then
        bar.spark = bar:CreateTexture(nil, "OVERLAY")
        bar.spark:SetTexture(E.media.textures.spark)
        bar.spark:SetBlendMode("ADD")
        bar.spark:SetSize(10, db.height * 2)
    end

    -- Icon
    if db.icon then
        bar.icon = bar:CreateTexture(nil, "ARTWORK")
        bar.icon:SetSize(db.height, db.height)
        bar.icon:SetPoint("RIGHT", bar, "LEFT", -3, 0)
        bar.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        bar.iconBorder = E:CreateBackdrop(bar.icon, "Default")
    end

    -- Text
    bar.text = E:CreateFontString(bar, 11, "OUTLINE", "LEFT")
    bar.text:SetPoint("LEFT", bar, "LEFT", 5, 0)

    bar.time = E:CreateFontString(bar, 11, "OUTLINE", "RIGHT")
    bar.time:SetPoint("RIGHT", bar, "RIGHT", -5, 0)

    -- Latency (player only)
    if unit == "player" and db.latency then
        bar.latency = bar:CreateTexture(nil, "OVERLAY")
        bar.latency:SetTexture(E.media.textures.flat)
        bar.latency:SetVertexColor(0.8, 0.2, 0.2, 0.6)
        bar.latency:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
        bar.latency:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
    end

    -- Shield (uninterruptible)
    bar.shield = bar:CreateTexture(nil, "OVERLAY")
    bar.shield:SetSize(20, 20)
    bar.shield:SetPoint("LEFT", bar, "RIGHT", 5, 0)
    bar.shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
    bar.shield:Hide()

    -- Interrupt highlight
    if db.interruptHighlight then
        bar.interrupt = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        bar.interrupt:SetPoint("TOPLEFT", bar, "TOPLEFT", -3, 3)
        bar.interrupt:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 3, -3)
        bar.interrupt:SetBackdrop({edgeFile = E.media.textures.glowBorder, edgeSize = 4})
        bar.interrupt:Hide()
    end

    bar.unit = unit
    bar.config = db
    bar:Hide()

    -- Events
    self:RegisterCastbarEvents(bar)

    self.bars[unit] = bar
    return bar
end

function CB:RegisterCastbarEvents(bar)
    bar:RegisterEvent("UNIT_SPELLCAST_START")
    bar:RegisterEvent("UNIT_SPELLCAST_STOP")
    bar:RegisterEvent("UNIT_SPELLCAST_FAILED")
    bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    bar:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    bar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    bar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
    bar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
    bar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")
    bar:RegisterEvent("PLAYER_TARGET_CHANGED")
    bar:RegisterEvent("PLAYER_FOCUS_CHANGED")

    bar:SetScript("OnEvent", function(self, event, unit, ...)
        CB:OnCastbarEvent(self, event, unit, ...)
    end)

    bar:SetScript("OnUpdate", function(self, elapsed)
        CB:OnCastbarUpdate(self, elapsed)
    end)
end

function CB:OnCastbarEvent(bar, event, unit, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        if bar.unit == "target" then
            self:UpdateCastbar(bar)
        end
        return
    end

    if event == "PLAYER_FOCUS_CHANGED" then
        if bar.unit == "focus" then
            self:UpdateCastbar(bar)
        end
        return
    end

    if unit ~= bar.unit then return end

    if event == "UNIT_SPELLCAST_START" then
        self:StartCast(bar, false, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:StartCast(bar, true, false)
    elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
        self:StartCast(bar, true, true)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        self:StopCast(bar, true)
    elseif event == "UNIT_SPELLCAST_FAILED" then
        self:FailCast(bar, "Failed")
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        self:FailCast(bar, "Interrupted")
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        self:SetInterruptible(bar, true)
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        self:SetInterruptible(bar, false)
    elseif event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
        self:UpdateCastTime(bar)
    end
end

function CB:StartCast(bar, isChannel, isEmpower)
    local unit = bar.unit
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible

    if isChannel or isEmpower then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
    else
        name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    end

    if not name then
        bar:Hide()
        return
    end

    bar.casting = not isChannel
    bar.channeling = isChannel and not isEmpower
    bar.empowering = isEmpower
    bar.startTime = startTime / 1000
    bar.endTime = endTime / 1000
    bar.duration = bar.endTime - bar.startTime

    if bar.icon then
        bar.icon:SetTexture(texture)
    end

    bar.text:SetText(name)

    -- Set color
    if isEmpower then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.empowering))
    elseif isChannel then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.channeling))
    else
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.casting))
    end

    self:SetInterruptible(bar, not notInterruptible)

    -- Update latency
    if bar.latency and bar.unit == "player" then
        local _, _, _, lagHome, lagWorld = GetNetStats()
        local lag = (lagHome + lagWorld) / 2 / 1000
        local width = min(lag / bar.duration, 0.5) * bar:GetWidth()
        bar.latency:SetWidth(max(1, width))
    end

    bar:Show()
end

function CB:StopCast(bar, success)
    if success then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.success))
        bar:SetValue(1)
        C_Timer.After(0.2, function()
            bar:Hide()
        end)
    else
        bar:Hide()
    end

    bar.casting = nil
    bar.channeling = nil
    bar.empowering = nil
end

function CB:FailCast(bar, reason)
    bar:SetStatusBarColor(unpack(E.media.colors.castbar.failed))
    bar.text:SetText(reason)
    bar:SetValue(1)

    C_Timer.After(0.5, function()
        bar:Hide()
    end)

    bar.casting = nil
    bar.channeling = nil
    bar.empowering = nil
end

function CB:SetInterruptible(bar, interruptible)
    if interruptible then
        bar.shield:Hide()
        if bar.interrupt then
            bar.interrupt:Hide()
        end
    else
        bar.shield:Show()
        if bar.interrupt then
            bar.interrupt:SetBackdropBorderColor(1, 0.3, 0.3, 0.8)
            bar.interrupt:Show()
        end
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.notInterruptible))
    end
end

function CB:UpdateCastTime(bar)
    local unit = bar.unit
    local name, text, texture, startTime, endTime

    if bar.channeling or bar.empowering then
        name, text, texture, startTime, endTime = UnitChannelInfo(unit)
    else
        name, text, texture, startTime, endTime = UnitCastingInfo(unit)
    end

    if name then
        bar.startTime = startTime / 1000
        bar.endTime = endTime / 1000
        bar.duration = bar.endTime - bar.startTime
    end
end

function CB:OnCastbarUpdate(bar, elapsed)
    if not bar.casting and not bar.channeling and not bar.empowering then return end

    local currentTime = GetTime()
    local progress

    if bar.channeling or bar.empowering then
        progress = (bar.endTime - currentTime) / bar.duration
    else
        progress = (currentTime - bar.startTime) / bar.duration
    end

    progress = max(0, min(1, progress))
    bar:SetValue(progress)

    -- Spark
    if bar.spark then
        local width = bar:GetWidth()
        bar.spark:SetPoint("CENTER", bar, "LEFT", width * progress, 0)
    end

    -- Time
    local remaining = bar.endTime - currentTime
    bar.time:SetFormattedText("%.1f", max(0, remaining))

    -- Check completion
    if currentTime >= bar.endTime then
        self:StopCast(bar, true)
    end
end

function CB:UpdateCastbar(bar)
    local unit = bar.unit

    local name = UnitCastingInfo(unit)
    if name then
        self:StartCast(bar, false, false)
        return
    end

    name = UnitChannelInfo(unit)
    if name then
        self:StartCast(bar, true, false)
        return
    end

    bar:Hide()
end

function CB:HideBlizzardCastbars()
    if CastingBarFrame then
        CastingBarFrame:UnregisterAllEvents()
        CastingBarFrame:Hide()
    end

    if TargetFrameSpellBar then
        TargetFrameSpellBar:UnregisterAllEvents()
        TargetFrameSpellBar:Hide()
    end

    if FocusFrameSpellBar then
        FocusFrameSpellBar:UnregisterAllEvents()
        FocusFrameSpellBar:Hide()
    end
end

function CB:ProfileChanged()
    self.db = E.db.castbars
    for unit, bar in pairs(self.bars) do
        local db = self.db[unit]
        if db then
            bar:SetSize(db.width, db.height)
            bar.config = db
        end
    end
end
