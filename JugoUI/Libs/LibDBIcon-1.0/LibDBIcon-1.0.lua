--[[ LibDBIcon-1.0 - A library for creating minimap icons
     https://www.wowace.com/projects/libdbicon-1-0 ]]

local MAJOR, MINOR = "LibDBIcon-1.0", 46
local LibDBIcon = LibStub:NewLibrary(MAJOR, MINOR)
if not LibDBIcon then return end

local LDB = LibStub("LibDataBroker-1.1")
local CallbackHandler = LibStub("CallbackHandler-1.0")

local type = type
local pairs = pairs
local tinsert = table.insert
local tremove = table.remove
local math_sin = math.sin
local math_cos = math.cos
local math_pi = math.pi

LibDBIcon.objects = LibDBIcon.objects or {}
LibDBIcon.callbacks = LibDBIcon.callbacks or CallbackHandler:New(LibDBIcon)
LibDBIcon.notCreated = LibDBIcon.notCreated or {}

local objects = LibDBIcon.objects
local callbacks = LibDBIcon.callbacks
local notCreated = LibDBIcon.notCreated

local function GetAngleValue(angle)
    return (math_pi * 2 / 360) * angle
end

local function UpdatePosition(button, db)
    local angle = db and db.minimapPos or 225
    local radius = db and db.radius or 80
    local rounding = 10

    local mapWidth = Minimap:GetWidth() / 2
    local mapHeight = Minimap:GetHeight() / 2

    local x = mapWidth + radius * math_cos(GetAngleValue(angle))
    local y = mapHeight + radius * math_sin(GetAngleValue(angle))

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "BOTTOMLEFT", x, y)
end

local function CreateMinimapButton(name, object, db)
    local button = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetSize(31, 31)
    button:SetHighlightTexture(136477)
    button:RegisterForClicks("anyUp")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture(136430)
    overlay:SetPoint("TOPLEFT")
    button.overlay = overlay

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    button.icon = icon

    if object.icon then
        icon:SetTexture(object.icon)
    end

    button.dataObject = object
    button.db = db

    button:SetScript("OnEnter", function(self)
        if self.dataObject.OnEnter then
            self.dataObject.OnEnter(self)
        elseif self.dataObject.OnTooltipShow then
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMLEFT")
            self.dataObject.OnTooltipShow(GameTooltip)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        if self.dataObject.OnLeave then
            self.dataObject.OnLeave(self)
        elseif GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnClick", function(self, btn)
        if self.dataObject.OnClick then
            self.dataObject.OnClick(self, btn)
        end
    end)

    button:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:LockHighlight()
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            local angle = math.deg(math.atan2(py - my, px - mx))
            if self.db then
                self.db.minimapPos = angle
            end
            UpdatePosition(self, self.db)
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self.dragging = nil
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)

    button:RegisterForDrag("LeftButton")

    UpdatePosition(button, db)

    objects[name] = button
    LDB.callbacks:Fire("LibDBIcon_IconCreated", button, name)

    return button
end

function LibDBIcon:Register(name, object, db)
    if type(name) ~= "string" then
        error("Usage: LibDBIcon:Register(name, object, db): 'name' - string expected", 2)
    end
    if type(object) ~= "table" then
        error("Usage: LibDBIcon:Register(name, object, db): 'object' - LDB object expected", 2)
    end

    if objects[name] or notCreated[name] then
        return
    end

    if db and db.hide then
        notCreated[name] = {object, db}
        return
    end

    CreateMinimapButton(name, object, db)
end

function LibDBIcon:Unregister(name)
    if type(name) ~= "string" then
        error("Usage: LibDBIcon:Unregister(name): 'name' - string expected", 2)
    end

    if objects[name] then
        objects[name]:Hide()
        objects[name] = nil
    elseif notCreated[name] then
        notCreated[name] = nil
    end
end

function LibDBIcon:Show(name)
    if objects[name] then
        objects[name]:Show()
        objects[name]:SetAlpha(1)
    elseif notCreated[name] then
        CreateMinimapButton(name, notCreated[name][1], notCreated[name][2])
        notCreated[name] = nil
    end
end

function LibDBIcon:Hide(name)
    if objects[name] then
        objects[name]:Hide()
    end
end

function LibDBIcon:IsRegistered(name)
    return objects[name] or notCreated[name] and true or false
end

function LibDBIcon:Refresh(name, db)
    if objects[name] then
        UpdatePosition(objects[name], db or objects[name].db)
    end
end

function LibDBIcon:GetMinimapButton(name)
    return objects[name]
end
