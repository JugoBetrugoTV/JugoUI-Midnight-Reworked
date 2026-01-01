--[[
    JugoUI - Nameplates/Castbar.lua
    Nameplate castbar functionality
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)
local NP = E.Nameplates

function NP:CreateCastbar(parent)
    local db = self.db.castbar
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(self.db.width, db.height)
    bar:SetPoint("TOP", parent.Health, "BOTTOM", 0, -3)
    bar:SetStatusBarTexture(E.media.textures.flat)
    bar:SetStatusBarColor(unpack(E.media.colors.castbar.casting))
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:Hide()

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(E.media.textures.flat)
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Spark
    bar.spark = bar:CreateTexture(nil, "OVERLAY")
    bar.spark:SetTexture(E.media.textures.spark)
    bar.spark:SetBlendMode("ADD")
    bar.spark:SetSize(10, db.height * 2)

    -- Icon
    if db.icon then
        bar.icon = bar:CreateTexture(nil, "ARTWORK")
        bar.icon:SetSize(db.height + 4, db.height + 4)
        bar.icon:SetPoint("RIGHT", bar, "LEFT", -3, 0)
        bar.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

        bar.iconBorder = E:CreateBackdrop(bar.icon, "Default")
    end

    -- Text
    bar.text = E:CreateFontString(bar, 9, "OUTLINE", "LEFT")
    bar.text:SetPoint("LEFT", bar, "LEFT", 3, 0)

    bar.time = E:CreateFontString(bar, 9, "OUTLINE", "RIGHT")
    bar.time:SetPoint("RIGHT", bar, "RIGHT", -3, 0)

    -- Shield (for uninterruptible)
    bar.shield = bar:CreateTexture(nil, "OVERLAY")
    bar.shield:SetSize(16, 16)
    bar.shield:SetPoint("LEFT", bar, "RIGHT", 3, 0)
    bar.shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
    bar.shield:Hide()

    -- OnUpdate for cast progress
    bar:SetScript("OnUpdate", function(self, elapsed)
        NP:CastbarOnUpdate(self, elapsed)
    end)

    -- Events
    bar:RegisterEvent("UNIT_SPELLCAST_START")
    bar:RegisterEvent("UNIT_SPELLCAST_STOP")
    bar:RegisterEvent("UNIT_SPELLCAST_FAILED")
    bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    bar:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    bar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    bar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
    bar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")
    bar:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")

    bar:SetScript("OnEvent", function(self, event, unit, ...)
        if unit ~= parent.unit then return end
        NP:CastbarOnEvent(self, event, unit, ...)
    end)

    return bar
end

function NP:CastbarOnEvent(bar, event, unit, ...)
    if event == "UNIT_SPELLCAST_START" then
        local castID, spellID = ...
        self:StartCast(bar, unit, false, spellID)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local castID, spellID = ...
        self:StartCast(bar, unit, true, spellID)
    elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
        local castID, spellID = ...
        self:StartCast(bar, unit, true, spellID, true)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        bar:Hide()
        bar.casting = nil
        bar.channeling = nil
        bar.empowering = nil
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.failed))
        bar.text:SetText(event == "UNIT_SPELLCAST_INTERRUPTED" and "Interrupted" or "Failed")
        bar:SetValue(1)
        C_Timer.After(0.5, function()
            bar:Hide()
        end)
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.interruptible))
        bar.shield:Hide()
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.notInterruptible))
        bar.shield:Show()
    end
end

function NP:StartCast(bar, unit, isChannel, spellID, isEmpower)
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellId

    if isEmpower then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
    elseif isChannel then
        name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellId = UnitChannelInfo(unit)
    else
        name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
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

    if notInterruptible then
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.notInterruptible))
        bar.shield:Show()
    else
        if isEmpower then
            bar:SetStatusBarColor(unpack(E.media.colors.castbar.empowering))
        elseif isChannel then
            bar:SetStatusBarColor(unpack(E.media.colors.castbar.channeling))
        else
            bar:SetStatusBarColor(unpack(E.media.colors.castbar.casting))
        end
        bar.shield:Hide()
    end

    bar:Show()
end

function NP:CastbarOnUpdate(bar, elapsed)
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

    -- Update spark position
    local width = bar:GetWidth()
    bar.spark:SetPoint("CENTER", bar, "LEFT", width * progress, 0)

    -- Update time text
    local remaining = bar.channeling and (bar.endTime - currentTime) or (bar.endTime - currentTime)
    bar.time:SetFormattedText("%.1f", max(0, remaining))

    -- Check for completion
    if currentTime >= bar.endTime then
        bar:SetValue(1)
        bar:SetStatusBarColor(unpack(E.media.colors.castbar.success))
        bar.casting = nil
        bar.channeling = nil
        bar.empowering = nil
        C_Timer.After(0.3, function()
            bar:Hide()
        end)
    end
end

function NP:UpdateCastbar(frame)
    if not frame.Castbar then return end

    local unit = frame.unit
    if not unit then return end

    -- Check for active cast
    local name = UnitCastingInfo(unit)
    if name then
        self:StartCast(frame.Castbar, unit, false)
        return
    end

    name = UnitChannelInfo(unit)
    if name then
        self:StartCast(frame.Castbar, unit, true)
        return
    end

    frame.Castbar:Hide()
end
