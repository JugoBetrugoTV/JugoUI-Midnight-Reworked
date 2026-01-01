--[[ AceTimer-3.0 - A library for scheduling events
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceTimer-3.0", 17
local AceTimer = LibStub:NewLibrary(MAJOR, MINOR)
if not AceTimer then return end

AceTimer.embeds = AceTimer.embeds or {}
AceTimer.activeTimers = AceTimer.activeTimers or {}

local type = type
local pairs = pairs
local tostring = tostring
local next = next
local floor = math.floor

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function safecall(func, ...)
    if func then
        return xpcall(func, errorhandler, ...)
    end
end

local function new()
    local timer = {}
    return timer
end

local function del(timer)
    timer.callback = nil
    timer.object = nil
    timer.id = nil
    timer.delay = nil
    timer.ends = nil
    timer.argsCount = nil
    timer.cancelled = nil
    timer.looping = nil
end

local activeTimers = AceTimer.activeTimers
local timerFrame = AceTimer.timerFrame

if not timerFrame then
    timerFrame = CreateFrame("Frame")
    AceTimer.timerFrame = timerFrame
end

local lastTimer = 0
local function runTimer(self, elapsed)
    lastTimer = lastTimer + elapsed
    if lastTimer < 0.01 then return end
    lastTimer = 0

    local now = GetTime()
    for timer in pairs(activeTimers) do
        if not timer.cancelled and timer.ends <= now then
            local callback = timer.callback
            local object = timer.object
            local argsCount = timer.argsCount

            if timer.looping then
                timer.ends = now + timer.delay
            else
                activeTimers[timer] = nil
                del(timer)
            end

            if type(callback) == "string" then
                if argsCount > 0 then
                    safecall(object[callback], object, timer.arg1, timer.arg2, timer.arg3, timer.arg4, timer.arg5)
                else
                    safecall(object[callback], object)
                end
            else
                if argsCount > 0 then
                    safecall(callback, timer.arg1, timer.arg2, timer.arg3, timer.arg4, timer.arg5)
                else
                    safecall(callback)
                end
            end
        end
    end
end

timerFrame:SetScript("OnUpdate", runTimer)

function AceTimer:ScheduleTimer(callback, delay, ...)
    if type(callback) ~= "function" and type(callback) ~= "string" then
        error("Usage: AceTimer:ScheduleTimer(callback, delay, [args]): 'callback' - function or method name expected.", 2)
    end
    if type(delay) ~= "number" then
        error("Usage: AceTimer:ScheduleTimer(callback, delay, [args]): 'delay' - number expected.", 2)
    end

    local timer = new()
    timer.object = self
    timer.callback = callback
    timer.delay = delay
    timer.ends = GetTime() + delay
    timer.argsCount = select("#", ...)
    timer.looping = false
    timer.cancelled = false

    if timer.argsCount > 0 then
        timer.arg1, timer.arg2, timer.arg3, timer.arg4, timer.arg5 = ...
    end

    activeTimers[timer] = true
    return timer
end

function AceTimer:ScheduleRepeatingTimer(callback, delay, ...)
    if type(callback) ~= "function" and type(callback) ~= "string" then
        error("Usage: AceTimer:ScheduleRepeatingTimer(callback, delay, [args]): 'callback' - function or method name expected.", 2)
    end
    if type(delay) ~= "number" then
        error("Usage: AceTimer:ScheduleRepeatingTimer(callback, delay, [args]): 'delay' - number expected.", 2)
    end

    local timer = new()
    timer.object = self
    timer.callback = callback
    timer.delay = delay
    timer.ends = GetTime() + delay
    timer.argsCount = select("#", ...)
    timer.looping = true
    timer.cancelled = false

    if timer.argsCount > 0 then
        timer.arg1, timer.arg2, timer.arg3, timer.arg4, timer.arg5 = ...
    end

    activeTimers[timer] = true
    return timer
end

function AceTimer:CancelTimer(timer)
    if not timer then return end
    timer.cancelled = true
    activeTimers[timer] = nil
    del(timer)
end

function AceTimer:CancelAllTimers()
    for timer in pairs(activeTimers) do
        if timer.object == self then
            timer.cancelled = true
            activeTimers[timer] = nil
            del(timer)
        end
    end
end

function AceTimer:TimeLeft(timer)
    if not timer or timer.cancelled then
        return 0
    end
    return timer.ends - GetTime()
end

local mixins = {
    "ScheduleTimer", "ScheduleRepeatingTimer",
    "CancelTimer", "CancelAllTimers", "TimeLeft"
}

function AceTimer:Embed(target)
    for _, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

function AceTimer:OnEmbedDisable(target)
    target:CancelAllTimers()
end

for addon in pairs(AceTimer.embeds) do
    AceTimer:Embed(addon)
end
