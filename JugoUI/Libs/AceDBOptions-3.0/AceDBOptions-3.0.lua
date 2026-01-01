--[[ AceDBOptions-3.0 - A library for auto-generating options tables for AceDB databases
     https://www.wowace.com/projects/ace3 ]]

local MAJOR, MINOR = "AceDBOptions-3.0", 15
local AceDBOptions = LibStub:NewLibrary(MAJOR, MINOR)
if not AceDBOptions then return end

local type = type
local pairs = pairs

local defaultProfiles = {
    ["Default"] = "Default",
    ["class"] = "Class",
    ["char"] = "Character",
    ["realm"] = "Realm",
}

function AceDBOptions:GetOptionsTable(db, noDefaultProfiles)
    if not db or not db.SetProfile or not db.GetProfiles then
        error("Usage: AceDBOptions:GetOptionsTable(db): 'db' - AceDB database object expected", 2)
    end

    local options = {
        type = "group",
        name = "Profiles",
        desc = "Manage profiles for this addon.",
        childGroups = "tab",
        args = {
            profile = {
                order = 1,
                type = "group",
                name = "Profile",
                desc = "Manage current profile settings.",
                args = {
                    desc = {
                        order = 1,
                        type = "description",
                        name = "You can change the active database profile.",
                    },
                    current = {
                        order = 2,
                        type = "select",
                        name = "Current Profile",
                        desc = "Select a profile to use.",
                        get = function()
                            return db:GetCurrentProfile()
                        end,
                        set = function(info, value)
                            db:SetProfile(value)
                        end,
                        values = function()
                            local profiles = db:GetProfiles()
                            local list = {}
                            for _, v in pairs(profiles) do
                                list[v] = v
                            end
                            return list
                        end,
                    },
                    new = {
                        order = 3,
                        type = "input",
                        name = "New Profile",
                        desc = "Create a new profile.",
                        get = false,
                        set = function(info, value)
                            db:SetProfile(value)
                        end,
                    },
                    copy = {
                        order = 4,
                        type = "select",
                        name = "Copy From",
                        desc = "Copy settings from another profile.",
                        get = false,
                        set = function(info, value)
                            db:CopyProfile(value)
                        end,
                        values = function()
                            local profiles = db:GetProfiles()
                            local current = db:GetCurrentProfile()
                            local list = {}
                            for _, v in pairs(profiles) do
                                if v ~= current then
                                    list[v] = v
                                end
                            end
                            return list
                        end,
                    },
                    delete = {
                        order = 5,
                        type = "select",
                        name = "Delete Profile",
                        desc = "Delete a profile.",
                        confirm = true,
                        confirmText = "Are you sure you want to delete this profile?",
                        get = false,
                        set = function(info, value)
                            db:DeleteProfile(value)
                        end,
                        values = function()
                            local profiles = db:GetProfiles()
                            local current = db:GetCurrentProfile()
                            local list = {}
                            for _, v in pairs(profiles) do
                                if v ~= current then
                                    list[v] = v
                                end
                            end
                            return list
                        end,
                    },
                    reset = {
                        order = 6,
                        type = "execute",
                        name = "Reset Profile",
                        desc = "Reset the current profile to defaults.",
                        confirm = true,
                        confirmText = "Are you sure you want to reset this profile?",
                        func = function()
                            db:ResetProfile()
                        end,
                    },
                },
            },
        },
    }

    return options
end
