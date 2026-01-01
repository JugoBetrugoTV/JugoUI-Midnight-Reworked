--[[
    JugoUI - SecureHandler.lua
    Secure handling for combat lockdown and 12.0 Secret Values
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Secure handler namespace
E.Secure = {}

--[[
    Secure Frame Creation
    Creates frames that work properly during combat lockdown
]]
function E.Secure:CreateSecureFrame(frameType, name, parent, template)
    local frame = CreateFrame(frameType, name, parent, template)
    return frame
end

function E.Secure:CreateSecureButton(name, parent, template)
    template = template or "SecureActionButtonTemplate"
    local button = CreateFrame("Button", name, parent, template)
    return button
end

--[[
    Secure State Handler
    Manages visibility and attributes based on conditions
]]
function E.Secure:RegisterStateDriver(frame, state, values)
    if not InCombatLockdown() then
        RegisterStateDriver(frame, state, values)
    else
        E:DelayUntilOutOfCombat(function()
            RegisterStateDriver(frame, state, values)
        end)
    end
end

function E.Secure:UnregisterStateDriver(frame, state)
    if not InCombatLockdown() then
        UnregisterStateDriver(frame, state)
    else
        E:DelayUntilOutOfCombat(function()
            UnregisterStateDriver(frame, state)
        end)
    end
end

--[[
    Secure Attribute Setting
    Sets attributes safely, deferring to out of combat if necessary
]]
function E.Secure:SetAttribute(frame, name, value)
    if not InCombatLockdown() then
        frame:SetAttribute(name, value)
        return true
    else
        E:DelayUntilOutOfCombat(function()
            frame:SetAttribute(name, value)
        end)
        return false
    end
end

function E.Secure:SetAttributes(frame, attributes)
    if not InCombatLockdown() then
        for name, value in pairs(attributes) do
            frame:SetAttribute(name, value)
        end
        return true
    else
        E:DelayUntilOutOfCombat(function()
            for name, value in pairs(attributes) do
                frame:SetAttribute(name, value)
            end
        end)
        return false
    end
end

--[[
    Secure Show/Hide
    Shows or hides frames safely during combat
]]
function E.Secure:Show(frame)
    if not InCombatLockdown() then
        frame:Show()
        return true
    else
        E:DelayUntilOutOfCombat(function()
            frame:Show()
        end)
        return false
    end
end

function E.Secure:Hide(frame)
    if not InCombatLockdown() then
        frame:Hide()
        return true
    else
        E:DelayUntilOutOfCombat(function()
            frame:Hide()
        end)
        return false
    end
end

--[[
    Secure Parent Setting
]]
function E.Secure:SetParent(frame, parent)
    if not InCombatLockdown() then
        frame:SetParent(parent)
        return true
    else
        E:DelayUntilOutOfCombat(function()
            frame:SetParent(parent)
        end)
        return false
    end
end

--[[
    12.0 Secret Value Handlers
    These functions help display secret values safely
]]

-- Create a health bar that handles secret values using curves
function E.Secure:CreateSecretAwareHealthBar(parent, name)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetStatusBarTexture(E.media.textures.flat)

    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(E.media.textures.flat)
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    -- Setup for secret value handling
    bar.unit = nil
    bar.isSecret = false

    -- Create color curve for 12.0
    if CreateColorCurve then
        bar.healthCurve = CreateColorCurve()
        bar.healthCurve:AddPoint(0, 1, 0, 0)    -- 0%: Red
        bar.healthCurve:AddPoint(0.5, 1, 1, 0)  -- 50%: Yellow
        bar.healthCurve:AddPoint(1, 0, 1, 0)    -- 100%: Green
    end

    bar.SetUnit = function(self, unit)
        self.unit = unit
        self:Update()
    end

    bar.Update = function(self)
        if not self.unit then return end

        local health, healthMax, isSecret = E.API:GetUnitHealth(self.unit)

        if isSecret and self.healthCurve then
            -- Use curve-based display for secret values
            self.isSecret = true
            self:SetMinMaxValues(0, 1)

            -- Use SetFillFromValue if available (12.0)
            if self.SetFillFromValue then
                self:SetFillFromValue(health, healthMax)
            else
                -- Fallback
                local percent = E.API:GetUnitHealthPercent(self.unit)
                if not E:IsSecretValue(percent) then
                    self:SetValue(percent / 100)
                end
            end

            -- Apply color from curve
            if self.SetVertexColorFromCurve then
                self:SetVertexColorFromCurve(self.healthCurve, health, healthMax)
            end
        else
            -- Normal handling
            self.isSecret = false
            self:SetMinMaxValues(0, healthMax)
            self:SetValue(health)
        end
    end

    return bar
end

-- Create a power bar that handles secret values
function E.Secure:CreateSecretAwarePowerBar(parent, name)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetStatusBarTexture(E.media.textures.flat)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(E.media.textures.flat)
    bar.bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)

    bar.unit = nil
    bar.powerType = nil

    bar.SetUnit = function(self, unit, powerType)
        self.unit = unit
        self.powerType = powerType
        self:Update()
    end

    bar.Update = function(self)
        if not self.unit then return end

        local power, powerMax, isSecret = E.API:GetUnitPower(self.unit, self.powerType)

        if isSecret then
            self:SetMinMaxValues(0, 1)
            local percent = E.API:GetUnitPowerPercent(self.unit, self.powerType)
            if not E:IsSecretValue(percent) then
                self:SetValue(percent / 100)
            end
        else
            self:SetMinMaxValues(0, powerMax)
            self:SetValue(power)
        end
    end

    return bar
end

--[[
    Secret-Aware Cooldown Display
    Uses 12.0 DurationObject and SetCooldownFromExpirationTime
]]
function E.Secure:CreateSecretAwareCooldown(parent, name)
    local cooldown = CreateFrame("Cooldown", name, parent, "CooldownFrameTemplate")
    cooldown:SetHideCountdownNumbers(false)

    cooldown.SetCooldownSafe = function(self, start, duration, enable, modRate)
        if E:IsSecretValue(start) or E:IsSecretValue(duration) then
            -- Use 12.0 method if available
            if self.SetCooldownFromDurationObject then
                E.API:SetCooldownFromDuration(self, start, duration, enable, modRate)
            end
        else
            self:SetCooldown(start, duration, modRate)
        end
    end

    return cooldown
end

--[[
    Secure Aura Handling
    Handles aura display with secret value consideration
]]
function E.Secure:GetAuraSafe(unit, index, filter)
    local auraData = E.API:GetAuraDataByIndex(unit, index, filter)

    if auraData then
        -- Check for secret aspects
        if auraData.name and E:IsSecretValue(auraData.name) then
            auraData.isSecret = true
        end

        return auraData
    end

    return nil
end

--[[
    Secure Handler Scripts
    Pre-built secure handler snippets for common operations
]]
E.Secure.Snippets = {
    -- Visibility based on combat state
    CombatVisibility = [[
        if newstate == "combat" then
            self:Hide()
        else
            self:Show()
        end
    ]],

    -- Target visibility
    TargetVisibility = [[
        if UnitExists("target") then
            self:Show()
        else
            self:Hide()
        end
    ]],

    -- Focus visibility
    FocusVisibility = [[
        if UnitExists("focus") then
            self:Show()
        else
            self:Hide()
        end
    ]],

    -- Pet visibility
    PetVisibility = [[
        if UnitExists("pet") then
            self:Show()
        else
            self:Hide()
        end
    ]],

    -- Vehicle visibility
    VehicleVisibility = [[
        if UnitInVehicle("player") then
            self:Show()
        else
            self:Hide()
        end
    ]],
}

--[[
    Apply Secure Handler Script
]]
function E.Secure:ApplyHandler(frame, attribute, snippet)
    if not InCombatLockdown() then
        frame:SetAttribute(attribute, snippet)
        return true
    else
        E:DelayUntilOutOfCombat(function()
            frame:SetAttribute(attribute, snippet)
        end)
        return false
    end
end

--[[
    Combat Lockdown Check Wrapper
    Wraps a function to only execute outside combat
]]
function E.Secure:WrapSecure(func)
    return function(...)
        if InCombatLockdown() then
            local args = {...}
            E:DelayUntilOutOfCombat(function()
                func(unpack(args))
            end)
            return false
        else
            return func(...)
        end
    end
end

--[[
    Secure Frame Pool
    Manages a pool of secure frames for reuse
]]
E.Secure.FramePools = {}

function E.Secure:AcquireSecureFrame(poolName, frameType, template)
    if not E.Secure.FramePools[poolName] then
        E.Secure.FramePools[poolName] = CreateFramePool(frameType or "Frame", UIParent, template)
    end

    if InCombatLockdown() then
        return nil, "In combat lockdown"
    end

    return E.Secure.FramePools[poolName]:Acquire()
end

function E.Secure:ReleaseSecureFrame(poolName, frame)
    if E.Secure.FramePools[poolName] then
        if InCombatLockdown() then
            E:DelayUntilOutOfCombat(function()
                E.Secure.FramePools[poolName]:Release(frame)
            end)
        else
            E.Secure.FramePools[poolName]:Release(frame)
        end
    end
end
