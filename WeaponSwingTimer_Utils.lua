local addon_name, addon_data = ...

addon_data.utils = {}

local default_statusbar_texture_name = "Solid"
local fallback_statusbar_texture = "Interface\\Buttons\\WHITE8X8"
local texture_dropdown_page_size = 10

-- Sends the given message to the chat frame with the addon name in front.
addon_data.utils.PrintMsg = function(msg)
	chat_msg = "|cFF00FFB0" .. addon_name .. ": |r" .. msg
	DEFAULT_CHAT_FRAME:AddMessage(chat_msg)
end

-- Resolves a named status bar texture from LibSharedMedia when available.
-- Falls back to Blizzard's built-in solid texture so the bars still render.
addon_data.utils.GetStatusBarTexture = function(texture_name)
    local requested_name = texture_name or default_statusbar_texture_name

    if LibStub then
        local media = LibStub("LibSharedMedia-3.0", true)
        if media then
            local shared_texture = media:Fetch("statusbar", requested_name, true)
            if shared_texture then
                return shared_texture
            end
        end
    end

    return fallback_statusbar_texture
end

addon_data.utils.GetSelectedBarTextureName = function()
    if character_core_settings and character_core_settings.bar_texture and character_core_settings.bar_texture ~= "" then
        return character_core_settings.bar_texture
    end

    return default_statusbar_texture_name
end

addon_data.utils.SetSelectedBarTextureName = function(texture_name)
    if not character_core_settings then
        character_core_settings = {}
    end

    if texture_name and texture_name ~= "" then
        character_core_settings.bar_texture = texture_name
    else
        character_core_settings.bar_texture = default_statusbar_texture_name
    end
end

addon_data.utils.GetStatusBarTextureNames = function()
    local texture_names = {}
    local seen = {}

    local function AddTextureName(texture_name)
        if texture_name and texture_name ~= "" and not seen[texture_name] then
            seen[texture_name] = true
            table.insert(texture_names, texture_name)
        end
    end

    AddTextureName(default_statusbar_texture_name)
    AddTextureName(addon_data.utils.GetSelectedBarTextureName())

    if LibStub then
        local media = LibStub("LibSharedMedia-3.0", true)
        if media then
            local shared_textures = media:List("statusbar")
            if type(shared_textures) == "table" then
                for _, texture_name in ipairs(shared_textures) do
                    AddTextureName(texture_name)
                end
            end
        end
    end

    table.sort(texture_names, function(left, right)
        return string.lower(left) < string.lower(right)
    end)

    return texture_names
end

addon_data.utils.GetStatusBarTexturePageSize = function()
    return texture_dropdown_page_size
end

addon_data.utils.GetBarTexture = function()
    return addon_data.utils.GetStatusBarTexture(addon_data.utils.GetSelectedBarTextureName())
end

-- Rounds the given number to the given step.
-- If num was 1.17 and step was 0.1 then this would return 1.1
addon_data.utils.SimpleRound = function(num, step)
    return floor(num / step) * step
end

-- used for searching through nested tables
addon_data.utils.DeepCopy = function(src, dst)
    if type(src) ~= "table" then return src end
    dst = dst or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = DeepCopy(v, {})
        else
            dst[k] = v
        end
    end
    return dst
end
