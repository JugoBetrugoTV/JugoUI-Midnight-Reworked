--[[
    JugoUI - Animation.lua
    Animation system and helpers
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

-- Animation namespace
E.Animation = {}

--[[
    Smooth Bar Updates
    Smoothly animates status bar value changes
]]
function E.Animation:CreateSmoothBar(bar, smoothTime)
    smoothTime = smoothTime or 0.3

    bar.smoothValue = 0
    bar.smoothTime = smoothTime
    bar.smoothing = false

    bar.SmoothSetValue = function(self, value)
        if not self.smoothing then
            self.smoothValue = self:GetValue()
        end

        self.targetValue = value
        self.smoothing = true
        self:SetScript("OnUpdate", self.SmoothUpdate)
    end

    bar.SmoothUpdate = function(self, elapsed)
        if not self.smoothing then
            self:SetScript("OnUpdate", nil)
            return
        end

        local diff = self.targetValue - self.smoothValue
        local step = diff * min(1, elapsed / self.smoothTime)

        if abs(diff) < 0.1 then
            self:SetValue(self.targetValue)
            self.smoothValue = self.targetValue
            self.smoothing = false
            self:SetScript("OnUpdate", nil)
        else
            self.smoothValue = self.smoothValue + step
            self:SetValue(self.smoothValue)
        end
    end

    return bar
end

--[[
    Fade Animations
]]
function E.Animation:CreateFadeIn(frame, duration, startAlpha, endAlpha, callback)
    duration = duration or 0.2
    startAlpha = startAlpha or 0
    endAlpha = endAlpha or 1

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Alpha")

    anim:SetFromAlpha(startAlpha)
    anim:SetToAlpha(endAlpha)
    anim:SetDuration(duration)
    anim:SetSmoothing("OUT")

    ag:SetScript("OnPlay", function()
        frame:SetAlpha(startAlpha)
        frame:Show()
    end)

    ag:SetScript("OnFinished", function()
        frame:SetAlpha(endAlpha)
        if callback then callback() end
    end)

    frame.fadeIn = ag
    return ag
end

function E.Animation:CreateFadeOut(frame, duration, startAlpha, endAlpha, callback, hideOnFinish)
    duration = duration or 0.2
    startAlpha = startAlpha or 1
    endAlpha = endAlpha or 0
    hideOnFinish = hideOnFinish ~= false

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Alpha")

    anim:SetFromAlpha(startAlpha)
    anim:SetToAlpha(endAlpha)
    anim:SetDuration(duration)
    anim:SetSmoothing("IN")

    ag:SetScript("OnPlay", function()
        frame:SetAlpha(startAlpha)
    end)

    ag:SetScript("OnFinished", function()
        frame:SetAlpha(endAlpha)
        if hideOnFinish then
            frame:Hide()
        end
        if callback then callback() end
    end)

    frame.fadeOut = ag
    return ag
end

--[[
    Slide Animations
]]
function E.Animation:CreateSlideIn(frame, direction, distance, duration, callback)
    direction = direction or "LEFT"
    distance = distance or 50
    duration = duration or 0.3

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Translation")

    local xOffset, yOffset = 0, 0
    if direction == "LEFT" then
        xOffset = -distance
    elseif direction == "RIGHT" then
        xOffset = distance
    elseif direction == "UP" then
        yOffset = distance
    elseif direction == "DOWN" then
        yOffset = -distance
    end

    anim:SetOffset(-xOffset, -yOffset)
    anim:SetDuration(duration)
    anim:SetSmoothing("OUT")

    ag:SetScript("OnPlay", function()
        frame:Show()
    end)

    ag:SetScript("OnFinished", function()
        if callback then callback() end
    end)

    frame.slideIn = ag
    return ag
end

function E.Animation:CreateSlideOut(frame, direction, distance, duration, callback, hideOnFinish)
    direction = direction or "LEFT"
    distance = distance or 50
    duration = duration or 0.3
    hideOnFinish = hideOnFinish ~= false

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Translation")

    local xOffset, yOffset = 0, 0
    if direction == "LEFT" then
        xOffset = -distance
    elseif direction == "RIGHT" then
        xOffset = distance
    elseif direction == "UP" then
        yOffset = distance
    elseif direction == "DOWN" then
        yOffset = -distance
    end

    anim:SetOffset(xOffset, yOffset)
    anim:SetDuration(duration)
    anim:SetSmoothing("IN")

    ag:SetScript("OnFinished", function()
        if hideOnFinish then
            frame:Hide()
        end
        if callback then callback() end
    end)

    frame.slideOut = ag
    return ag
end

--[[
    Scale Animations
]]
function E.Animation:CreateScaleIn(frame, startScale, endScale, duration, callback)
    startScale = startScale or 0.5
    endScale = endScale or 1
    duration = duration or 0.2

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Scale")

    anim:SetScaleFrom(startScale, startScale)
    anim:SetScaleTo(endScale, endScale)
    anim:SetDuration(duration)
    anim:SetSmoothing("OUT")

    ag:SetScript("OnPlay", function()
        frame:Show()
    end)

    ag:SetScript("OnFinished", function()
        frame:SetScale(endScale)
        if callback then callback() end
    end)

    frame.scaleIn = ag
    return ag
end

function E.Animation:CreateScaleOut(frame, startScale, endScale, duration, callback, hideOnFinish)
    startScale = startScale or 1
    endScale = endScale or 0.5
    duration = duration or 0.2
    hideOnFinish = hideOnFinish ~= false

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Scale")

    anim:SetScaleFrom(startScale, startScale)
    anim:SetScaleTo(endScale, endScale)
    anim:SetDuration(duration)
    anim:SetSmoothing("IN")

    ag:SetScript("OnFinished", function()
        if hideOnFinish then
            frame:Hide()
        end
        frame:SetScale(startScale)
        if callback then callback() end
    end)

    frame.scaleOut = ag
    return ag
end

--[[
    Pulse Animation
]]
function E.Animation:CreatePulse(frame, minAlpha, maxAlpha, duration, loops)
    minAlpha = minAlpha or 0.5
    maxAlpha = maxAlpha or 1
    duration = duration or 0.5
    loops = loops or 0 -- 0 = infinite

    local ag = frame:CreateAnimationGroup()

    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(maxAlpha)
    fadeOut:SetToAlpha(minAlpha)
    fadeOut:SetDuration(duration / 2)
    fadeOut:SetOrder(1)

    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(minAlpha)
    fadeIn:SetToAlpha(maxAlpha)
    fadeIn:SetDuration(duration / 2)
    fadeIn:SetOrder(2)

    ag:SetLooping(loops == 0 and "REPEAT" or "NONE")

    if loops > 0 then
        local currentLoop = 0
        ag:SetScript("OnLoop", function()
            currentLoop = currentLoop + 1
            if currentLoop >= loops then
                ag:Stop()
            end
        end)
    end

    frame.pulse = ag
    return ag
end

--[[
    Glow Animation (border pulse)
]]
function E.Animation:CreateGlow(frame, r, g, b, duration)
    r = r or 1
    g = g or 1
    b = b or 0
    duration = duration or 0.5

    if not frame.glowBorder then
        frame.glowBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.glowBorder:SetPoint("TOPLEFT", frame, -3, 3)
        frame.glowBorder:SetPoint("BOTTOMRIGHT", frame, 3, -3)
        frame.glowBorder:SetBackdrop({
            edgeFile = E.media.textures.glowBorder,
            edgeSize = 4,
        })
        frame.glowBorder:SetBackdropBorderColor(r, g, b)
        frame.glowBorder:Hide()
    end

    E.Animation:CreatePulse(frame.glowBorder, 0.3, 1, duration, 0)

    frame.StartGlow = function(self, customR, customG, customB)
        self.glowBorder:SetBackdropBorderColor(customR or r, customG or g, customB or b)
        self.glowBorder:Show()
        self.glowBorder.pulse:Play()
    end

    frame.StopGlow = function(self)
        self.glowBorder.pulse:Stop()
        self.glowBorder:Hide()
    end

    return frame.glowBorder
end

--[[
    Flash Animation
]]
function E.Animation:CreateFlash(frame, duration, numFlashes)
    duration = duration or 0.2
    numFlashes = numFlashes or 3

    local ag = frame:CreateAnimationGroup()

    for i = 1, numFlashes do
        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(duration / 2)
        fadeOut:SetOrder(i * 2 - 1)

        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(duration / 2)
        fadeIn:SetOrder(i * 2)
    end

    ag:SetScript("OnFinished", function()
        frame:SetAlpha(1)
    end)

    frame.flash = ag
    return ag
end

--[[
    Spin Animation
]]
function E.Animation:CreateSpin(frame, duration, direction, loops)
    duration = duration or 2
    direction = direction or 1 -- 1 = clockwise, -1 = counter-clockwise
    loops = loops or 0

    local ag = frame:CreateAnimationGroup()
    local anim = ag:CreateAnimation("Rotation")

    anim:SetDegrees(360 * direction)
    anim:SetDuration(duration)

    ag:SetLooping(loops == 0 and "REPEAT" or "NONE")

    frame.spin = ag
    return ag
end

--[[
    Shake Animation
]]
function E.Animation:CreateShake(frame, intensity, duration, numShakes)
    intensity = intensity or 5
    duration = duration or 0.5
    numShakes = numShakes or 4

    local ag = frame:CreateAnimationGroup()
    local shakeTime = duration / (numShakes * 2)

    for i = 1, numShakes do
        local left = ag:CreateAnimation("Translation")
        left:SetOffset(-intensity, 0)
        left:SetDuration(shakeTime / 2)
        left:SetOrder(i * 2 - 1)
        left:SetSmoothing("NONE")

        local right = ag:CreateAnimation("Translation")
        right:SetOffset(intensity * 2, 0)
        right:SetDuration(shakeTime)
        right:SetOrder(i * 2 - 1)
        right:SetStartDelay(shakeTime / 2)
        right:SetSmoothing("NONE")

        local center = ag:CreateAnimation("Translation")
        center:SetOffset(-intensity, 0)
        center:SetDuration(shakeTime / 2)
        center:SetOrder(i * 2)
        center:SetSmoothing("NONE")
    end

    frame.shake = ag
    return ag
end

--[[
    Bounce Animation
]]
function E.Animation:CreateBounce(frame, height, duration, numBounces)
    height = height or 10
    duration = duration or 0.5
    numBounces = numBounces or 2

    local ag = frame:CreateAnimationGroup()
    local bounceTime = duration / numBounces

    for i = 1, numBounces do
        local up = ag:CreateAnimation("Translation")
        up:SetOffset(0, height / i)
        up:SetDuration(bounceTime / 2)
        up:SetOrder(i)
        up:SetSmoothing("OUT")

        local down = ag:CreateAnimation("Translation")
        down:SetOffset(0, -height / i)
        down:SetDuration(bounceTime / 2)
        down:SetOrder(i)
        down:SetStartDelay(bounceTime / 2)
        down:SetSmoothing("IN")
    end

    frame.bounce = ag
    return ag
end

--[[
    Helper: Play animation with callback
]]
function E.Animation:Play(frame, animName, callback)
    local anim = frame[animName]
    if anim then
        if callback then
            local oldScript = anim:GetScript("OnFinished")
            anim:SetScript("OnFinished", function()
                if oldScript then oldScript() end
                callback()
            end)
        end
        anim:Play()
    end
end

--[[
    Helper: Stop all animations on a frame
]]
function E.Animation:StopAll(frame)
    local animations = {
        "fadeIn", "fadeOut", "slideIn", "slideOut",
        "scaleIn", "scaleOut", "pulse", "flash",
        "spin", "shake", "bounce"
    }

    for _, name in ipairs(animations) do
        if frame[name] then
            frame[name]:Stop()
        end
    end

    if frame.glowBorder and frame.glowBorder.pulse then
        frame.glowBorder.pulse:Stop()
        frame.glowBorder:Hide()
    end
end
