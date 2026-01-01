--[[ AceGUI-3.0 - A GUI framework for WoW addons
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceGUI-3.0", 41
local AceGUI = LibStub:NewLibrary(MAJOR, MINOR)
if not AceGUI then return end

local type = type
local pairs = pairs
local tinsert = table.insert
local tremove = table.remove
local CreateFrame = CreateFrame

AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.LayoutRegistry = AceGUI.LayoutRegistry or {}
AceGUI.WidgetPool = AceGUI.WidgetPool or {}
AceGUI.WidgetContainerPool = AceGUI.WidgetContainerPool or {}
AceGUI.WidgetVersions = AceGUI.WidgetVersions or {}

local WidgetRegistry = AceGUI.WidgetRegistry
local LayoutRegistry = AceGUI.LayoutRegistry
local WidgetPool = AceGUI.WidgetPool
local WidgetContainerPool = AceGUI.WidgetContainerPool
local WidgetVersions = AceGUI.WidgetVersions

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function safecall(func, ...)
    if func then
        return xpcall(func, errorhandler, ...)
    end
end

function AceGUI:RegisterWidgetType(name, constructor, version)
    if type(name) ~= "string" then
        error("Usage: AceGUI:RegisterWidgetType(name, constructor, version): 'name' - string expected", 2)
    end
    if type(constructor) ~= "function" then
        error("Usage: AceGUI:RegisterWidgetType(name, constructor, version): 'constructor' - function expected", 2)
    end
    if type(version) ~= "number" then
        error("Usage: AceGUI:RegisterWidgetType(name, constructor, version): 'version' - number expected", 2)
    end

    if WidgetVersions[name] and WidgetVersions[name] >= version then
        return
    end

    WidgetVersions[name] = version
    WidgetRegistry[name] = constructor
    WidgetPool[name] = WidgetPool[name] or {}
end

function AceGUI:RegisterLayout(name, layoutfunc)
    if type(name) ~= "string" then
        error("Usage: AceGUI:RegisterLayout(name, layoutfunc): 'name' - string expected", 2)
    end
    if type(layoutfunc) ~= "function" then
        error("Usage: AceGUI:RegisterLayout(name, layoutfunc): 'layoutfunc' - function expected", 2)
    end

    LayoutRegistry[name] = layoutfunc
end

local WidgetBase = {
    SetParent = function(self, parent)
        self.parent = parent
    end,

    SetCallback = function(self, name, func)
        if type(func) ~= "function" then
            error("Usage: widget:SetCallback(name, func): 'func' - function expected", 2)
        end
        self.callbacks = self.callbacks or {}
        self.callbacks[name] = func
    end,

    Fire = function(self, name, ...)
        if self.callbacks and self.callbacks[name] then
            safecall(self.callbacks[name], self, name, ...)
        end
    end,

    SetWidth = function(self, width)
        self.frame:SetWidth(width)
        self.frame.width = width
    end,

    SetRelativeWidth = function(self, width)
        self.relWidth = width
        self.width = "relative"
    end,

    SetHeight = function(self, height)
        self.frame:SetHeight(height)
        self.frame.height = height
    end,

    SetRelativeHeight = function(self, height)
        self.relHeight = height
        self.height = "relative"
    end,

    SetFullWidth = function(self, isFull)
        if isFull then
            self.width = "fill"
        else
            self.width = nil
        end
    end,

    SetFullHeight = function(self, isFull)
        if isFull then
            self.height = "fill"
        else
            self.height = nil
        end
    end,

    Release = function(self)
        AceGUI:Release(self)
    end,

    IsVisible = function(self)
        return self.frame:IsVisible()
    end,

    IsShown = function(self)
        return self.frame:IsShown()
    end,
}

local ContainerBase = {
    AddChild = function(self, child, beforeWidget)
        if beforeWidget then
            for i, widget in pairs(self.children) do
                if widget == beforeWidget then
                    tinsert(self.children, i, child)
                    child:SetParent(self)
                    self:DoLayout()
                    return
                end
            end
        end
        tinsert(self.children, child)
        child:SetParent(self)
        self:DoLayout()
    end,

    ReleaseChildren = function(self)
        local children = self.children
        for i = 1, #children do
            AceGUI:Release(children[i])
            children[i] = nil
        end
    end,

    SetLayout = function(self, layout)
        self.layout = layout
    end,

    DoLayout = function(self)
        local layout = self.layout
        if not layout then layout = "List" end

        local layoutfunc = LayoutRegistry[layout]
        if layoutfunc then
            layoutfunc(self.content, self.children)
        end
    end,

    PauseLayout = function(self)
        self.paused = true
    end,

    ResumeLayout = function(self)
        self.paused = nil
        self:DoLayout()
    end,
}

function AceGUI:Create(type)
    if not WidgetRegistry[type] then
        error(("Usage: AceGUI:Create(type): 'type' - Widget type '%s' not found"):format(type), 2)
    end

    local pool = WidgetPool[type]
    local widget

    if #pool > 0 then
        widget = tremove(pool)
    else
        widget = WidgetRegistry[type]()

        for k, v in pairs(WidgetBase) do
            widget[k] = widget[k] or v
        end
        if widget.content then
            widget.children = {}
            for k, v in pairs(ContainerBase) do
                widget[k] = widget[k] or v
            end
        end
    end

    widget.callbacks = {}
    widget.userdata = {}
    widget.type = type

    return widget
end

function AceGUI:Release(widget)
    if widget.children then
        widget:ReleaseChildren()
    end

    if widget.OnRelease then
        widget:OnRelease()
    end

    for k in pairs(widget.callbacks) do
        widget.callbacks[k] = nil
    end
    for k in pairs(widget.userdata) do
        widget.userdata[k] = nil
    end

    widget.frame:Hide()
    widget.frame:SetParent(UIParent)
    widget.frame:ClearAllPoints()

    tinsert(WidgetPool[widget.type], widget)
end

function AceGUI:SetFocus(widget)
    self.focus = widget
end

function AceGUI:ClearFocus()
    self.focus = nil
end

AceGUI:RegisterLayout("Fill", function(content, children)
    if #children > 0 then
        local child = children[1]
        child.frame:SetAllPoints(content)
        child.frame:Show()
    end
end)

AceGUI:RegisterLayout("List", function(content, children)
    local height = 0
    local width = content:GetWidth()

    for i, child in pairs(children) do
        local frame = child.frame
        frame:ClearAllPoints()
        frame:Show()

        if i == 1 then
            frame:SetPoint("TOPLEFT", content)
        else
            frame:SetPoint("TOPLEFT", children[i-1].frame, "BOTTOMLEFT")
        end

        if child.width == "fill" then
            frame:SetPoint("RIGHT", content)
        elseif child.width == "relative" then
            frame:SetWidth(width * (child.relWidth or 1))
        end

        height = height + (frame.height or frame:GetHeight())
    end

    content:SetHeight(height)
end)

AceGUI:RegisterLayout("Flow", function(content, children)
    local width = content:GetWidth()
    local rowHeight = 0
    local usedWidth = 0
    local rowStart = 1

    for i, child in pairs(children) do
        local frame = child.frame
        local frameWidth = frame.width or frame:GetWidth()
        local frameHeight = frame.height or frame:GetHeight()

        frame:ClearAllPoints()
        frame:Show()

        if usedWidth + frameWidth > width and i > 1 then
            usedWidth = 0
            rowStart = i

            for j = rowStart, i - 1 do
                local prevFrame = children[j].frame
                local prevY = select(5, prevFrame:GetPoint(1))
                prevFrame:SetPoint("TOPLEFT", content, "TOPLEFT", select(4, prevFrame:GetPoint(1)), (prevY or 0) - rowHeight)
            end

            rowHeight = 0
        end

        if i == 1 then
            frame:SetPoint("TOPLEFT", content)
        elseif usedWidth == 0 then
            frame:SetPoint("TOPLEFT", children[rowStart - 1].frame, "BOTTOMLEFT")
        else
            frame:SetPoint("TOPLEFT", children[i-1].frame, "TOPRIGHT")
        end

        usedWidth = usedWidth + frameWidth
        rowHeight = math.max(rowHeight, frameHeight)
    end
end)
