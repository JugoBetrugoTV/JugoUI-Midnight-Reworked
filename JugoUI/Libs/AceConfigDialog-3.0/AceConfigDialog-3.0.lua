--[[ AceConfigDialog-3.0 - A dialog frame for AceConfig options
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceConfigDialog-3.0", 87
local AceConfigDialog = LibStub:NewLibrary(MAJOR, MINOR)
if not AceConfigDialog then return end

local AceGUI = LibStub("AceGUI-3.0", true)
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

AceConfigDialog.OpenFrames = AceConfigDialog.OpenFrames or {}
AceConfigDialog.Status = AceConfigDialog.Status or {}
AceConfigDialog.frame = AceConfigDialog.frame or CreateFrame("Frame")

local type = type
local pairs = pairs
local next = next
local tostring = tostring
local tinsert = table.insert
local tremove = table.remove
local format = string.format

local OpenFrames = AceConfigDialog.OpenFrames
local Status = AceConfigDialog.Status

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function safecall(func, ...)
    if func then
        return xpcall(func, errorhandler, ...)
    end
end

local function GetOptionsMember(options, member, appName, ...)
    local handler = options.handler
    local value = options[member]

    if type(value) == "function" then
        return value(handler or options, ...)
    elseif type(value) == "string" and handler and type(handler[value]) == "function" then
        return handler[value](handler, ...)
    else
        return value
    end
end

local function OptionPath(path, key)
    if path then
        return path .. "\001" .. key
    else
        return key
    end
end

local function del(t)
    if t then
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

local function copy(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = v
    end
    return c
end

local function FeedOptions(appName, options, container, path, group)
    local name = GetOptionsMember(options, "name", appName)

    if options.type == "group" then
        local args = options.args
        if not args then return end

        local order = {}
        for key, opt in pairs(args) do
            tinsert(order, {key = key, order = opt.order or 100})
        end
        table.sort(order, function(a, b)
            if a.order == b.order then
                return a.key < b.key
            end
            return a.order < b.order
        end)

        for _, info in pairs(order) do
            local key = info.key
            local opt = args[key]
            FeedOptions(appName, opt, container, OptionPath(path, key))
        end
    end
end

function AceConfigDialog:Open(appName, container, ...)
    if type(appName) ~= "string" then
        error("Usage: AceConfigDialog:Open(appName): 'appName' - string expected", 2)
    end

    local options = AceConfigRegistry:GetOptionsTable(appName)
    if not options then
        error(("AceConfigDialog:Open(appName): No options table registered for '%s'"):format(appName), 2)
    end

    local path = ...

    if OpenFrames[appName] then
        return
    end

    local f
    if container then
        f = container
    else
        f = AceGUI:Create("Frame")
        f:SetTitle(options.name or appName)
        f:SetCallback("OnClose", function(widget)
            AceConfigDialog:Close(appName)
        end)
    end

    OpenFrames[appName] = f

    f:SetLayout("Fill")
    FeedOptions(appName, options, f, nil, options)

    if not container then
        f:Show()
    end

    return f
end

function AceConfigDialog:Close(appName)
    if type(appName) ~= "string" then
        error("Usage: AceConfigDialog:Close(appName): 'appName' - string expected", 2)
    end

    if OpenFrames[appName] then
        OpenFrames[appName]:Release()
        OpenFrames[appName] = nil
    end
end

function AceConfigDialog:CloseAll()
    for appName in pairs(OpenFrames) do
        self:Close(appName)
    end
end

function AceConfigDialog:AddToBlizOptions(appName, name, parent, ...)
    local options = AceConfigRegistry:GetOptionsTable(appName)
    if not options then
        error(("AceConfigDialog:AddToBlizOptions(appName, name, parent): No options table registered for '%s'"):format(appName), 2)
    end

    local key = appName
    if ... then
        for i = 1, select("#", ...) do
            key = key .. "\001" .. select(i, ...)
        end
    end

    local frame = CreateFrame("Frame")
    frame.name = name or appName

    if parent then
        frame.parent = parent
    end

    frame:SetScript("OnShow", function(frame)
        if not frame.container then
            frame.container = AceGUI:Create("SimpleGroup")
            frame.container:SetLayout("Fill")
            frame.container.frame:SetParent(frame)
            frame.container.frame:SetAllPoints(frame)
            frame.container.frame:Show()

            FeedOptions(appName, options, frame.container, ...)
        end
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category
        if parent then
            local parentCategory = Settings.GetCategory(parent)
            if parentCategory then
                category = Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, name or appName)
            end
        else
            category = Settings.RegisterCanvasLayoutCategory(frame, name or appName)
        end
        if category then
            category.ID = name or appName
            Settings.RegisterAddOnCategory(category)
        end
    else
        InterfaceOptions_AddCategory(frame)
    end

    return frame
end

function AceConfigDialog:SetDefaultSize(appName, width, height)
    if type(appName) ~= "string" then
        error("Usage: AceConfigDialog:SetDefaultSize(appName, width, height): 'appName' - string expected", 2)
    end
    Status[appName] = Status[appName] or {}
    Status[appName].width = width
    Status[appName].height = height
end
