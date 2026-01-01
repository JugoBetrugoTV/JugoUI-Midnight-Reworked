--[[ LibCustomGlow-1.0 - A library for creating custom glows on frames
     Simplified implementation for JugoUI ]]

local MAJOR, MINOR = "LibCustomGlow-1.0", 17
local LibCustomGlow = LibStub:NewLibrary(MAJOR, MINOR)
if not LibCustomGlow then return end

local pairs = pairs
local type = type
local CreateFrame = CreateFrame

LibCustomGlow.glowList = LibCustomGlow.glowList or {}
LibCustomGlow.framePool = LibCustomGlow.framePool or {}

local glowList = LibCustomGlow.glowList
local framePool = LibCustomGlow.framePool

local function acquireFrame()
    local frame = next(framePool)
    if frame then
        framePool[frame] = nil
        return frame
    end
    return CreateFrame("Frame")
end

local function releaseFrame(frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(nil)
    framePool[frame] = true
end

local function createGlowTexture(parent, color)
    local texture = parent:CreateTexture(nil, "OVERLAY")
    texture:SetBlendMode("ADD")
    texture:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)

    local r, g, b, a = 1, 1, 1, 1
    if color then
        r, g, b = color[1] or 1, color[2] or 1, color[3] or 1
        a = color[4] or 1
    end
    texture:SetVertexColor(r, g, b, a)

    return texture
end

function LibCustomGlow.PixelGlow_Start(frame, color, N, freq, length, th, xOffset, yOffset, border, key, frameLevel)
    if not frame then return end

    key = key or ""
    local glowKey = frame:GetName() or tostring(frame) .. key

    if glowList[glowKey] then
        LibCustomGlow.PixelGlow_Stop(frame, key)
    end

    local glowFrame = acquireFrame()
    glowFrame:SetParent(frame)
    glowFrame:SetFrameLevel((frameLevel or frame:GetFrameLevel()) + 1)
    glowFrame:SetAllPoints()
    glowFrame:Show()

    N = N or 8
    freq = freq or 0.25
    length = length or 2
    th = th or 2
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    border = border or false

    glowFrame.textures = glowFrame.textures or {}

    local r, g, b, a = 1, 1, 0, 1
    if color then
        r, g, b = color[1] or 1, color[2] or 1, color[3] or 0
        a = color[4] or 1
    end

    for i = 1, N do
        local tex = glowFrame.textures[i] or glowFrame:CreateTexture(nil, "OVERLAY")
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(r, g, b, a)
        tex:SetSize(length, th)
        tex:Show()
        glowFrame.textures[i] = tex
    end

    for i = N + 1, #glowFrame.textures do
        glowFrame.textures[i]:Hide()
    end

    local w, h = frame:GetWidth(), frame:GetHeight()

    if N >= 1 then glowFrame.textures[1]:SetPoint("TOPLEFT", xOffset, yOffset) end
    if N >= 2 then glowFrame.textures[2]:SetPoint("TOPRIGHT", xOffset, yOffset) end
    if N >= 3 then glowFrame.textures[3]:SetPoint("BOTTOMLEFT", xOffset, -yOffset) end
    if N >= 4 then glowFrame.textures[4]:SetPoint("BOTTOMRIGHT", xOffset, -yOffset) end

    local animGroup = glowFrame:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")

    local anim = animGroup:CreateAnimation("Alpha")
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0.3)
    anim:SetDuration(freq)
    anim:SetOrder(1)

    local anim2 = animGroup:CreateAnimation("Alpha")
    anim2:SetFromAlpha(0.3)
    anim2:SetToAlpha(1)
    anim2:SetDuration(freq)
    anim2:SetOrder(2)

    animGroup:Play()
    glowFrame.animGroup = animGroup

    glowList[glowKey] = glowFrame
end

function LibCustomGlow.PixelGlow_Stop(frame, key)
    if not frame then return end

    key = key or ""
    local glowKey = frame:GetName() or tostring(frame) .. key

    local glowFrame = glowList[glowKey]
    if glowFrame then
        if glowFrame.animGroup then
            glowFrame.animGroup:Stop()
        end
        for _, tex in pairs(glowFrame.textures or {}) do
            tex:Hide()
        end
        releaseFrame(glowFrame)
        glowList[glowKey] = nil
    end
end

function LibCustomGlow.AutoCastGlow_Start(frame, color, N, freq, scale, xOffset, yOffset, key, frameLevel)
    if not frame then return end

    key = key or ""
    local glowKey = frame:GetName() or tostring(frame) .. key .. "_autocast"

    if glowList[glowKey] then
        LibCustomGlow.AutoCastGlow_Stop(frame, key)
    end

    local glowFrame = acquireFrame()
    glowFrame:SetParent(frame)
    glowFrame:SetFrameLevel((frameLevel or frame:GetFrameLevel()) + 1)
    glowFrame:SetAllPoints()
    glowFrame:Show()

    scale = scale or 1
    xOffset = xOffset or 0
    yOffset = yOffset or 0

    local r, g, b, a = 1, 1, 0, 1
    if color then
        r, g, b = color[1] or 1, color[2] or 1, color[3] or 0
        a = color[4] or 1
    end

    local shine = glowFrame:CreateTexture(nil, "OVERLAY")
    shine:SetTexture("Interface\\Cooldown\\star4")
    shine:SetBlendMode("ADD")
    shine:SetPoint("CENTER", xOffset, yOffset)
    shine:SetSize(frame:GetWidth() * 1.5 * scale, frame:GetHeight() * 1.5 * scale)
    shine:SetVertexColor(r, g, b, a)

    local animGroup = glowFrame:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")

    local rotate = animGroup:CreateAnimation("Rotation")
    rotate:SetDegrees(360)
    rotate:SetDuration(freq or 4)

    animGroup:Play()
    glowFrame.animGroup = animGroup
    glowFrame.shine = shine

    glowList[glowKey] = glowFrame
end

function LibCustomGlow.AutoCastGlow_Stop(frame, key)
    if not frame then return end

    key = key or ""
    local glowKey = frame:GetName() or tostring(frame) .. key .. "_autocast"

    local glowFrame = glowList[glowKey]
    if glowFrame then
        if glowFrame.animGroup then
            glowFrame.animGroup:Stop()
        end
        if glowFrame.shine then
            glowFrame.shine:Hide()
        end
        releaseFrame(glowFrame)
        glowList[glowKey] = nil
    end
end

function LibCustomGlow.ButtonGlow_Start(frame, color, freq)
    if not frame then return end

    local glowKey = frame:GetName() or tostring(frame) .. "_button"

    if glowList[glowKey] then
        return
    end

    local glowFrame = acquireFrame()
    glowFrame:SetParent(frame)
    glowFrame:SetFrameLevel(frame:GetFrameLevel() + 5)
    glowFrame:SetAllPoints()
    glowFrame:Show()

    local r, g, b, a = 1, 1, 0.3, 1
    if color then
        r, g, b = color[1] or 1, color[2] or 1, color[3] or 0.3
        a = color[4] or 1
    end

    local glow = createGlowTexture(glowFrame, {r, g, b, a})
    glow:SetAllPoints()
    glow:Show()
    glowFrame.glow = glow

    local animGroup = glowFrame:CreateAnimationGroup()
    animGroup:SetLooping("REPEAT")

    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.5)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(freq or 0.5)
    fadeIn:SetOrder(1)

    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.5)
    fadeOut:SetDuration(freq or 0.5)
    fadeOut:SetOrder(2)

    animGroup:Play()
    glowFrame.animGroup = animGroup

    glowList[glowKey] = glowFrame
end

function LibCustomGlow.ButtonGlow_Stop(frame)
    if not frame then return end

    local glowKey = frame:GetName() or tostring(frame) .. "_button"

    local glowFrame = glowList[glowKey]
    if glowFrame then
        if glowFrame.animGroup then
            glowFrame.animGroup:Stop()
        end
        if glowFrame.glow then
            glowFrame.glow:Hide()
        end
        releaseFrame(glowFrame)
        glowList[glowKey] = nil
    end
end

function LibCustomGlow.ProcGlow_Start(frame, options)
    LibCustomGlow.ButtonGlow_Start(frame, options and options.color, options and options.frequency)
end

function LibCustomGlow.ProcGlow_Stop(frame)
    LibCustomGlow.ButtonGlow_Stop(frame)
end
