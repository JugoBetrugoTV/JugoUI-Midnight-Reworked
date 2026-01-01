--[[
    JugoUI - Profiles/Core.lua
    Profile management module
    Compatible with WoW: Midnight (Patch 12.0)
]]

local ADDON_NAME, Engine = ...
local E, L, V, P, G = unpack(Engine)

local PR = E:NewModule("Profiles")
E.Profiles = PR

function PR:OnInitialize()
    -- Profile management is handled by AceDB
end

function PR:OnEnable()
    -- Register profile-related callbacks
    E.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    E.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    E.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
end

function PR:OnProfileChanged()
    -- Notify all modules of profile change
    for name, module in E:IterateModules() do
        if module.ProfileChanged then
            module:ProfileChanged()
        end
    end

    E.callbacks:Fire("JugoUI_ProfileChanged")
    E:Print("Profile changed.")
end

function PR:ExportProfile()
    local profile = E.db
    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)

    if not LibSerialize or not LibDeflate then
        E:Error("Missing required libraries for export")
        return nil
    end

    local serialized = LibSerialize:Serialize(profile)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    return encoded
end

function PR:ImportProfile(data)
    local LibSerialize = LibStub("LibSerialize", true)
    local LibDeflate = LibStub("LibDeflate", true)

    if not LibSerialize or not LibDeflate then
        E:Error("Missing required libraries for import")
        return false
    end

    local decoded = LibDeflate:DecodeForPrint(data)
    if not decoded then
        E:Error("Failed to decode profile data")
        return false
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        E:Error("Failed to decompress profile data")
        return false
    end

    local success, profile = LibSerialize:Deserialize(decompressed)
    if not success then
        E:Error("Failed to deserialize profile data")
        return false
    end

    -- Apply imported profile
    E:CopyTable(profile, E.db)
    self:OnProfileChanged()

    E:Print("Profile imported successfully!")
    return true
end

function PR:GetProfileList()
    local profiles = E.db:GetProfiles()
    local list = {}
    for i, name in ipairs(profiles) do
        list[name] = name
    end
    return list
end

function PR:GetCurrentProfile()
    return E.db:GetCurrentProfile()
end

function PR:SetProfile(name)
    E.db:SetProfile(name)
end

function PR:CopyProfile(name)
    E.db:CopyProfile(name)
end

function PR:DeleteProfile(name)
    E.db:DeleteProfile(name)
end

function PR:ResetProfile()
    E.db:ResetProfile()
end

function PR:GetOptions()
    local options = LibStub("AceDBOptions-3.0"):GetOptionsTable(E.db)

    -- Add import/export options
    options.args.importexport = {
        type = "group",
        name = "Import/Export",
        order = 100,
        args = {
            export = {
                type = "execute",
                name = "Export Profile",
                desc = "Export your current profile to a string",
                func = function()
                    local data = PR:ExportProfile()
                    if data then
                        -- Open dialog with export string
                        E:Print("Profile exported! Copy the string from the edit box.")
                    end
                end,
            },
            import = {
                type = "input",
                name = "Import Profile",
                desc = "Paste a profile string to import",
                multiline = 5,
                width = "full",
                set = function(_, value)
                    PR:ImportProfile(value)
                end,
            },
        },
    }

    return options
end
