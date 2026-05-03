local addon_name, addon_data = ...
local L = addon_data.localization_table

addon_data.config = {}

addon_data.config.theme = {
    panel_width = 660,
    title = { 1.0, 0.86, 0.35, 1 },
    subtitle = { 0.86, 0.88, 0.92, 1 },
    text = { 0.98, 0.96, 0.90, 1 },
    muted = { 0.66, 0.68, 0.74, 1 },
    card = { 0.055, 0.065, 0.085, 0.88 },
    card_border = { 0.28, 0.24, 0.16, 0.72 },
    input = { 0.025, 0.030, 0.040, 0.92 },
}

addon_data.config.ApplyBackdrop = function(frame, bg, border)
    if not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
end

addon_data.config.SectionFactory = function(parent, title, width, height)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetSize(width or 620, height or 120)
    addon_data.config.ApplyBackdrop(section, addon_data.config.theme.card, addon_data.config.theme.card_border)

    section.title = section:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section.title:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    section.title:SetJustifyH("LEFT")
    section.title:SetTextColor(unpack(addon_data.config.theme.title))
    section.title:SetPoint("TOPLEFT", 14, -10)
    section.title:SetText(title)

    return section
end

addon_data.config.HeaderFactory = function(parent, title, subtitle)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetSize(addon_data.config.theme.panel_width, 64)
    addon_data.config.ApplyBackdrop(header, { 0.035, 0.042, 0.055, 0.72 }, { 0.38, 0.32, 0.18, 0.55 })

    header.title = header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header.title:SetFont(STANDARD_TEXT_FONT, 21, "OUTLINE")
    header.title:SetJustifyH("LEFT")
    header.title:SetTextColor(unpack(addon_data.config.theme.title))
    header.title:SetPoint("TOPLEFT", 16, -12)
    header.title:SetText(title)

    if subtitle then
        header.subtitle = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        header.subtitle:SetJustifyH("LEFT")
        header.subtitle:SetTextColor(unpack(addon_data.config.theme.subtitle))
        header.subtitle:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -6)
        header.subtitle:SetText(subtitle)
    end

    return header
end

addon_data.config.OnDefault = function()
    addon_data.core.RestoreAllDefaults()
    addon_data.config.UpdateConfigValues()
end

addon_data.config.InitializeVisuals = function()

    -- Add the parent panel
    addon_data.config.config_parent_panel = CreateFrame("Frame", "MyFrame", UIParent)
    local panel = addon_data.config.config_parent_panel
    panel:SetSize(720, 640)

    panel.logo = panel:CreateTexture(nil, 'BACKGROUND')
    panel.logo:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/LandingPage')	
    panel.logo:SetSize(620, 260)
    panel.logo:SetPoint('TOPLEFT', 18, -18)
    panel.logo:SetAlpha(0.08)

    panel.scroll_frame = CreateFrame("ScrollFrame", addon_name .. "ConfigScrollFrame", panel, "UIPanelScrollFrameTemplate")
    panel.scroll_frame:SetPoint("TOPLEFT", 12, -12)
    panel.scroll_frame:SetPoint("BOTTOMRIGHT", -30, 12)

    panel.scroll_child = CreateFrame("Frame", addon_name .. "ConfigScrollChild", panel.scroll_frame)
    panel.scroll_child:SetSize(700, 2220)
    panel.scroll_frame:SetScrollChild(panel.scroll_child)
    panel.scroll_frame:EnableMouseWheel(true)
    panel.scroll_frame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max_scroll = self:GetVerticalScrollRange()
        local next_scroll = current - (delta * 48)
        if next_scroll < 0 then
            next_scroll = 0
        elseif next_scroll > max_scroll then
            next_scroll = max_scroll
        end
        self:SetVerticalScroll(next_scroll)
    end)

    local content = panel.scroll_child
    local next_y = -6

    local function AddTitle(text, y)
        local title = addon_data.config.TextFactory(content, text, 22)
        title:SetPoint("TOPLEFT", 4, y)
        title:SetTextColor(unpack(addon_data.config.theme.title))
        return title
    end

    panel.global_panel = addon_data.config.CreateConfigPanel(content)
    panel.global_panel:SetPoint("TOPLEFT", 0, next_y)
    next_y = next_y - 304

    panel.melee_title = AddTitle(L["Melee Settings"], next_y)
    next_y = next_y - 34

    panel.config_melee_panel = CreateFrame("Frame", addon_name .. "CombinedMeleePanel", content)
    panel.config_melee_panel:SetSize(680, 554)
    panel.config_melee_panel:SetPoint("TOPLEFT", 0, next_y)
    panel.config_melee_panel.player_panel = addon_data.player.CreateConfigPanel(panel.config_melee_panel)
    panel.config_melee_panel.player_panel:SetPoint("TOPLEFT", 0, 0)
    panel.config_melee_panel.target_panel = addon_data.target.CreateConfigPanel(panel.config_melee_panel)
    panel.config_melee_panel.target_panel:SetPoint("TOPLEFT", 0, -286)
    next_y = next_y - 580

    panel.ranged_title = AddTitle(L["Ranged Settings"], next_y)
    next_y = next_y - 34

    panel.config_hunter_panel = CreateFrame("Frame", addon_name .. "CombinedRangedPanel", content)
    panel.config_hunter_panel:SetSize(700, 928)
    panel.config_hunter_panel:SetPoint("TOPLEFT", 0, next_y)
    panel.config_hunter_panel.hunter_panel = addon_data.hunter.CreateConfigPanel(panel.config_hunter_panel)
    panel.config_hunter_panel.hunter_panel:SetPoint("TOPLEFT", 0, 0)
    panel.config_hunter_panel.castbar_panel = addon_data.castbar.CreateConfigPanel(panel.config_hunter_panel)
    panel.config_hunter_panel.castbar_panel:SetPoint("TOPLEFT", 0, -684)
    next_y = next_y - 954

    panel.config_profiles_panel = CreateFrame("Frame", addon_name .. "CombinedProfilesPanel", content)
    panel.config_profiles_panel:SetSize(680, 240)
    panel.config_profiles_panel:SetPoint("TOPLEFT", 0, next_y)
    panel.config_profiles_panel.config_profiles_panel = addon_data.config.CreateProfilesPanel(panel.config_profiles_panel)

    panel.name = "WeaponSwingTimer"
    panel.default = addon_data.config.OnDefault
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    category.ID = panel.name
    Settings.RegisterAddOnCategory(category)

end

addon_data.config.TextFactory = function(parent, text, size)
    local text_obj = parent:CreateFontString(nil, "ARTWORK")
    local flags = size and size >= 18 and "OUTLINE" or nil
    text_obj:SetFont(STANDARD_TEXT_FONT, size, flags)
    text_obj:SetJustifyV("MIDDLE")
    text_obj:SetJustifyH("LEFT")
    text_obj:SetTextColor(unpack(addon_data.config.theme.text))
    text_obj:SetText(text)
    return text_obj
end

addon_data.config.HelpTextFactory = function(parent, text, width)
    local text_obj = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text_obj:SetJustifyV("TOP")
    text_obj:SetJustifyH("LEFT")
    text_obj:SetWidth(width or 300)
    text_obj:SetTextColor(unpack(addon_data.config.theme.muted))
    text_obj:SetText(text)
    return text_obj
end

addon_data.config.CheckBoxFactory = function(g_name, parent, checkbtn_text, tooltip_text, on_click_func)
    local checkbox = CreateFrame("CheckButton", addon_name .. g_name, parent, "ChatConfigCheckButtonTemplate")
    local label = getglobal(checkbox:GetName() .. 'Text')
    label:SetText(checkbtn_text)
    label:SetTextColor(unpack(addon_data.config.theme.text))
    label:SetFont(STANDARD_TEXT_FONT, 12)
    checkbox.tooltip = tooltip_text
    checkbox:SetScript("OnClick", function(self)
        on_click_func(self)
    end)
    checkbox:SetScale(1.0)
    return checkbox
end

addon_data.config.EditBoxFactory = function(g_name, parent, title, w, h, enter_func)
    local edit_box_obj = CreateFrame("EditBox", addon_name .. g_name, parent, "BackdropTemplate")
    edit_box_obj.title_text = addon_data.config.TextFactory(edit_box_obj, title, 12)
    edit_box_obj.title_text:SetPoint("TOP", 0, 12)
    edit_box_obj.title_text:SetTextColor(unpack(addon_data.config.theme.subtitle))
    addon_data.config.ApplyBackdrop(edit_box_obj, addon_data.config.theme.input, addon_data.config.theme.card_border)
    edit_box_obj:SetSize(w, h)
    edit_box_obj:SetMultiLine(false)
    edit_box_obj:SetAutoFocus(false)
    edit_box_obj:SetMaxLetters(4)
    edit_box_obj:SetJustifyH("CENTER")
	edit_box_obj:SetJustifyV("MIDDLE")
    edit_box_obj:SetFontObject(GameFontNormal)
    edit_box_obj:SetTextColor(1, 1, 1, 1)
    edit_box_obj:SetScript("OnEnterPressed", function(self)
        enter_func(self)
        self:ClearFocus()
    end)
    edit_box_obj:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= "" then
            enter_func(self)
        end
    end)
    edit_box_obj:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return edit_box_obj
end

addon_data.config.SliderFactory = function(g_name, parent, title, min_val, max_val, val_step, func)
    local slider = CreateFrame("Slider", addon_name .. g_name, parent, "OptionsSliderTemplate")
    local editbox = CreateFrame("EditBox", "$parentEditBox", slider, "InputBoxTemplate")
    -- force slider to be set size, odd cases where it was missing
    slider:SetSize(120, 18)
    slider:SetMinMaxValues(min_val, max_val)
    slider:SetValueStep(val_step)
    slider:SetObeyStepOnDrag(true)
    editbox:SetSize(45,30)
    editbox:ClearAllPoints()
    editbox:SetPoint("LEFT", slider, "RIGHT", 15, 0)
    editbox:SetText(slider:GetValue())
    editbox:SetAutoFocus(false)
    editbox:SetTextColor(1, 1, 1, 1)
    slider:SetScript("OnValueChanged", function(self)
        editbox:SetText(tostring(addon_data.utils.SimpleRound(self:GetValue(), val_step)))
        func(self)
    end)

    -- force slider background to be set, odd cases where it was missing
    local bg = slider:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
    bg:SetPoint("LEFT", slider, "LEFT", 4, 0)
    bg:SetPoint("RIGHT", slider, "RIGHT", -4, 0)
    bg:SetHeight(6)

    -- force slider text to be set, odd cases where they were missing
    local name = slider:GetName()
    _G[name .. "Text"]:SetText(title)
    _G[name .. "Text"]:SetTextColor(unpack(addon_data.config.theme.subtitle))
    _G[name .. "Low"]:SetText(tostring(min_val))
    _G[name .. "High"]:SetText(tostring(max_val))
    _G[name .. "Low"]:SetTextColor(unpack(addon_data.config.theme.muted))
    _G[name .. "High"]:SetTextColor(unpack(addon_data.config.theme.muted))

    editbox:SetScript("OnTextChanged", function(self)
        local val = tonumber(self:GetText())
        if val then
            self:GetParent():SetValue(val)
        end
    end)
        editbox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then
            self:GetParent():SetValue(val)
            self:ClearFocus()
        end
    end)
    slider.editbox = editbox
    return slider
end

addon_data.config.color_picker_factory = function(g_name, parent, r, g, b, a, text, on_click_func)
    local color_picker = CreateFrame('Button', addon_name .. g_name, parent)
    color_picker:SetSize(18, 18)
    color_picker.normal = color_picker:CreateTexture(nil, 'BACKGROUND')
    color_picker.normal:SetColorTexture(1, 1, 1, 1)
    color_picker.normal:SetPoint('TOPLEFT', -1, 1)
    color_picker.normal:SetPoint('BOTTOMRIGHT', 1, -1)
    color_picker.foreground = color_picker:CreateTexture(nil, 'ARTWORK')
    color_picker.foreground:SetColorTexture(r, g, b, a)
    color_picker.foreground:SetAllPoints()
    color_picker:SetNormalTexture(color_picker.foreground)
    color_picker:SetScript('OnClick', on_click_func)
    color_picker.text = addon_data.config.TextFactory(color_picker, text, 12)
    color_picker.text:SetPoint('LEFT', 28, 0)
    color_picker.text:SetTextColor(unpack(addon_data.config.theme.text))
    return color_picker
end

addon_data.config.StyleButton = function(button, is_danger)
    if not button then
        return
    end

    button:SetNormalFontObject(GameFontNormal)
    button:SetHighlightFontObject(GameFontHighlight)
    if is_danger then
        button:GetFontString():SetTextColor(1, 0.58, 0.48, 1)
    else
        button:GetFontString():SetTextColor(1, 0.86, 0.35, 1)
    end
end

addon_data.config.ShowColorPicker = function(settings, name, foreground_texture, on_change)
    local start_r = settings[name .. "_r"]
    local start_g = settings[name .. "_g"]
    local start_b = settings[name .. "_b"]
    local start_a = settings[name .. "_a"]

    local function Apply()
        local new_r, new_g, new_b = ColorPickerFrame:GetColorRGB()
        local new_a = 1 - OpacitySliderFrame:GetValue()

        settings[name .. "_r"] = new_r
        settings[name .. "_g"] = new_g
        settings[name .. "_b"] = new_b
        settings[name .. "_a"] = new_a

        foreground_texture:SetColorTexture(new_r, new_g, new_b, new_a)
        if on_change then on_change(new_r, new_g, new_b, new_a) end
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = start_r,
        g = start_g,
        b = start_b,
        hasOpacity = true,
        opacity = 1 - start_a,
        swatchFunc = Apply,
        opacityFunc = Apply,
        cancelFunc = function()
            settings[name .. "_r"] = start_r
            settings[name .. "_g"] = start_g
            settings[name .. "_b"] = start_b
            settings[name .. "_a"] = start_a

            foreground_texture:SetColorTexture(start_r, start_g, start_b, start_a)
            if on_change then on_change(start_r, start_g, start_b, start_a) end
        end,
    })
end

addon_data.config.UpdateConfigValues = function()
    local panel = addon_data.config.config_frame
    if not panel then
        return
    end

    local settings = character_player_settings
    local settings_core = character_core_settings

    panel.is_locked_checkbox:SetChecked(settings.is_locked)
	panel.welcome_checkbox:SetChecked(settings_core.welcome_message)
    if panel.RefreshTextureControls then
        panel.RefreshTextureControls()
    end
end

addon_data.config.IsLockedCheckBoxOnClick = function(self)
    character_player_settings.is_locked = self:GetChecked()
    character_target_settings.is_locked = self:GetChecked()
    character_hunter_settings.is_locked = self:GetChecked()
    character_castbar_settings.is_locked = self:GetChecked()
    addon_data.player.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.target.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.hunter.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.castbar.frame:EnableMouse(not character_target_settings.is_locked)
    addon_data.core.UpdateAllVisualsOnSettingsChange()
end

addon_data.config.WelcomeCheckBoxOnClick = function(self)
	character_core_settings.welcome_message = self:GetChecked()
    addon_data.core.UpdateAllVisualsOnSettingsChange()
end

addon_data.config.CreateConfigPanel = function(parent_panel)
    addon_data.config.config_frame = CreateFrame("Frame", addon_name .. "GlobalConfigPanel", parent_panel)
    local panel = addon_data.config.config_frame
    panel:SetSize(addon_data.config.theme.panel_width, 280)

    local function RefreshTexturePreview()
        if not panel.texture_preview_fill then
            return
        end

        panel.texture_preview_fill:SetTexture(addon_data.utils.GetBarTexture())
        panel.texture_preview_fill:SetVertexColor(1, 1, 1, 1)
        panel.texture_name_text:SetText(addon_data.utils.GetSelectedBarTextureName())
        UIDropDownMenu_SetText(panel.texture_dropdown, addon_data.utils.GetSelectedBarTextureName())
    end

    local function ApplyTextureSelection(texture_name)
        addon_data.utils.SetSelectedBarTextureName(texture_name)
        RefreshTexturePreview()
        addon_data.core.UpdateAllVisualsOnSettingsChange()
    end

    local function AddTextureSelectionButton(texture_name, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = texture_name
        info.value = texture_name
        info.checked = (texture_name == addon_data.utils.GetSelectedBarTextureName())
        info.func = function(button)
            ApplyTextureSelection(button.value)
        end
        UIDropDownMenu_AddButton(info, level)
    end

    local function InitializeTextureDropDown(self, level, menu_list)
        local texture_names = addon_data.utils.GetStatusBarTextureNames()
        local page_size = addon_data.utils.GetStatusBarTexturePageSize()
        local page_count = math.ceil(#texture_names / page_size)

        if level == 1 then
            local title = UIDropDownMenu_CreateInfo()
            title.text = L["Bar Texture"]
            title.isTitle = true
            title.notCheckable = true
            UIDropDownMenu_AddButton(title, level)

            if #texture_names <= page_size then
                for _, texture_name in ipairs(texture_names) do
                    AddTextureSelectionButton(texture_name, level)
                end
                return
            end

            for page_index = 1, page_count do
                local start_index = ((page_index - 1) * page_size) + 1
                local end_index = math.min(page_index * page_size, #texture_names)
                local first_name = texture_names[start_index]
                local last_name = texture_names[end_index]
                local info = UIDropDownMenu_CreateInfo()
                info.text = first_name == last_name and first_name or (first_name .. " - " .. last_name)
                info.notCheckable = true
                info.hasArrow = true
                info.menuList = page_index
                UIDropDownMenu_AddButton(info, level)
            end
        elseif level == 2 and type(menu_list) == "number" then
            local start_index = ((menu_list - 1) * page_size) + 1
            local end_index = math.min(menu_list * page_size, #texture_names)
            for texture_index = start_index, end_index do
                AddTextureSelectionButton(texture_names[texture_index], level)
            end
        end
    end

    panel.header = addon_data.config.HeaderFactory(
        panel,
        L["Global Bar Settings"],
        L["Global texture used by all swing, shot, and cast bars."])
    panel.header:SetPoint("TOPLEFT", 0, 0)

    panel.texture_section = addon_data.config.SectionFactory(panel, L["Appearance"], 640, 112)
    panel.texture_section:SetPoint("TOPLEFT", 0, -76)

    panel.behavior_section = addon_data.config.SectionFactory(panel, L["Behavior"], 640, 78)
    panel.behavior_section:SetPoint("TOPLEFT", 0, -200)

    panel.texture_title = addon_data.config.TextFactory(panel, L["Bar Texture"], 16)
    panel.texture_title:SetPoint("TOPLEFT", 16, -104)
    panel.texture_title:SetTextColor(unpack(addon_data.config.theme.subtitle))

    panel.texture_dropdown = CreateFrame("Frame", addon_name .. "TextureDropDown", panel, "UIDropDownMenuTemplate")
    panel.texture_dropdown:SetPoint("TOPLEFT", 0, -126)
    UIDropDownMenu_SetWidth(panel.texture_dropdown, 180)
    UIDropDownMenu_Initialize(panel.texture_dropdown, InitializeTextureDropDown)

    panel.texture_preview_title = addon_data.config.TextFactory(panel, L["Texture Preview"], 16)
    panel.texture_preview_title:SetPoint("TOPLEFT", 280, -104)
    panel.texture_preview_title:SetTextColor(unpack(addon_data.config.theme.subtitle))

    panel.texture_preview_frame = CreateFrame("Frame", addon_name .. "TexturePreviewFrame", panel, "BackdropTemplate")
    panel.texture_preview_frame:SetSize(180, 18)
    panel.texture_preview_frame:SetPoint("TOPLEFT", 280, -128)
    addon_data.config.ApplyBackdrop(panel.texture_preview_frame, addon_data.config.theme.input, addon_data.config.theme.card_border)

    panel.texture_preview_fill = panel.texture_preview_frame:CreateTexture(nil, "ARTWORK")
    panel.texture_preview_fill:SetPoint("TOPLEFT", 3, -3)
    panel.texture_preview_fill:SetPoint("BOTTOMRIGHT", -3, 3)

    panel.texture_name_text = addon_data.config.HelpTextFactory(panel, "", 180)
    panel.texture_name_text:SetPoint("TOPLEFT", 280, -154)

    panel.texture_help = addon_data.config.HelpTextFactory(
        panel,
        L["Texture lists are split into pages to keep the menu compact."],
        420)
    panel.texture_help:SetPoint("TOPLEFT", 16, -164)
    
    -- Is Locked Checkbox
    panel.is_locked_checkbox = addon_data.config.CheckBoxFactory(
        "IsLockedCheckBox",
        panel,
        L[" Lock All Bars"],
        L["Locks all of the swing bar frames, preventing them from being dragged."],
        addon_data.config.IsLockedCheckBoxOnClick)
    panel.is_locked_checkbox:SetPoint("TOPLEFT", 16, -232)

    panel.welcome_checkbox = addon_data.config.CheckBoxFactory(
        "WelcomeCheckBox",
        panel,
        L[" Welcome Message"],
        L["Displays the welcome message upon login/reload. Uncheck to disable."],
        addon_data.config.WelcomeCheckBoxOnClick)
    panel.welcome_checkbox:SetPoint("TOPLEFT", 260, -232)

    panel.RefreshTextureControls = RefreshTexturePreview
    
    -- Return the final panel
    addon_data.config.UpdateConfigValues()
    return panel
end

addon_data.config.CreateProfilesPanel = function(parent)
    local panel = parent
    panel:SetSize(addon_data.config.theme.panel_width, 250)

    panel.header = addon_data.config.HeaderFactory(
        panel,
        L["Profiles"],
        L["Profiles let you save multiple layouts and quickly switch between them."])
    panel.header:SetPoint("TOPLEFT", 0, 0)

    panel.profile_section = addon_data.config.SectionFactory(panel, L["Active Profile"], 640, 142)
    panel.profile_section:SetPoint("TOPLEFT", 0, -78)

    -- Dropdown
    panel.profile_dropdown = CreateFrame("Frame", addon_name .. "ProfileDropDown", panel, "UIDropDownMenuTemplate")
    panel.profile_dropdown:SetPoint("TOPLEFT", 0, -112)

    local function GetCurrentProfile()
        return addon_data.db and addon_data.db:GetCurrentProfile() or "Default"
    end

    local function RefreshDropdownText()
        UIDropDownMenu_SetText(panel.profile_dropdown, GetCurrentProfile())
    end

    local function RefreshAllAfterProfileChange()
        -- Rebind aliases from DB (your helper from InitDB)
        if addon_data.core.RefreshFromDB then
            addon_data.core.RefreshFromDB()
        end

        -- Update config panels if you have a global updater
        if addon_data.core.UpdateAllVisualsOnSettingsChange then
            addon_data.core.UpdateAllVisualsOnSettingsChange()
        end
    end

    local function InitializeDropDown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(btn)
            addon_data.db:SetProfile(btn.value)
            RefreshDropdownText()
            RefreshAllAfterProfileChange()
        end

        -- List existing profiles
        local profiles = addon_data.db:GetProfiles()
        table.sort(profiles)
        for _, name in ipairs(profiles) do
            info.text = name
            info.value = name
            info.checked = (name == GetCurrentProfile())
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(panel.profile_dropdown, InitializeDropDown)
    UIDropDownMenu_SetWidth(panel.profile_dropdown, 140)
    RefreshDropdownText()

    -- New profile name box
    panel.new_profile_editbox = addon_data.config.EditBoxFactory(
        "WSTNewProfileEditBox",
        panel,
        L["New profile name"],
        160,
        25,
        function()
            panel.new_profile_editbox:SetMaxLetters(20)
        end
    )
    panel.new_profile_editbox:SetPoint("TOPLEFT", 220, -118)

    -- Create button
    panel.create_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.create_btn:SetSize(90, 22)
    panel.create_btn:SetPoint("LEFT", panel.new_profile_editbox, "RIGHT", 10, 0)
    panel.create_btn:SetText(L["Create"])
    addon_data.config.StyleButton(panel.create_btn)
    panel.create_btn:SetScript("OnClick", function()
        local name = panel.new_profile_editbox:GetText()
        if not name or name == "" then return end
        addon_data.db:SetProfile(name)
        panel.new_profile_editbox:SetText("")
        UIDropDownMenu_Initialize(panel.profile_dropdown, InitializeDropDown)
        RefreshDropdownText()
        RefreshAllAfterProfileChange()
    end)

    -- Copy From (dropdown)
    panel.copy_from_dropdown = CreateFrame("Frame", addon_name .. "CopyFromDropDown", panel, "UIDropDownMenuTemplate")
    panel.copy_from_dropdown:SetPoint("TOPLEFT", 0, -156)
    UIDropDownMenu_SetWidth(panel.copy_from_dropdown, 140)
    UIDropDownMenu_SetText(panel.copy_from_dropdown, L["Copy from..."])

    local function InitializeCopyFrom(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(btn)
            -- copy chosen profile into current
            addon_data.db:CopyProfile(btn.value)
            UIDropDownMenu_SetText(panel.copy_from_dropdown, L["Copy from..."])
            RefreshAllAfterProfileChange()
        end

        local current = GetCurrentProfile()
        local profiles = addon_data.db:GetProfiles()
        table.sort(profiles)
        for _, name in ipairs(profiles) do
            if name ~= current then
                info.text = name
                info.value = name
                info.checked = false
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
    UIDropDownMenu_Initialize(panel.copy_from_dropdown, InitializeCopyFrom)

    StaticPopupDialogs["WST_CONFIRM_DELETE_PROFILE"] = {
        text = L["Delete active profile? This cannot be undone."],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self, profileName)
            if not addon_data or not addon_data.db or not profileName then return end
            if profileName == "Default" then return end

            -- Must switch away before deleting (AceDB requirement)
            addon_data.db:SetProfile("Default")
            addon_data.db:DeleteProfile(profileName)

            -- Refresh bindings/UI
            if addon_data.core and addon_data.core.RefreshFromDB then
                addon_data.core.RefreshFromDB()
            end
            UIDropDownMenu_SetText(panel.profile_dropdown, addon_data.db:GetCurrentProfile())
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["WST_CONFIRM_RESET_PROFILE"] = {
        text = L["Reset profile to defaults?"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self, profileName)
            if not addon_data or not addon_data.db then return end
            addon_data.db:ResetProfile()
            if addon_data.core and addon_data.core.RefreshFromDB then
                addon_data.core.RefreshFromDB()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- Reset profile button
    panel.reset_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.reset_btn:SetSize(150, 22)
    panel.reset_btn:SetPoint("LEFT", panel.copy_from_dropdown, "RIGHT", 10, 0)
    panel.reset_btn:SetText(L["Reset Active Profile"])
    addon_data.config.StyleButton(panel.reset_btn)
    panel.reset_btn:SetScript("OnClick", function()
        StaticPopup_Show("WST_CONFIRM_RESET_PROFILE", addon_data.db:GetCurrentProfile(), nil, addon_data.db:GetCurrentProfile())

        RefreshAllAfterProfileChange()
    end)

    panel.delete_btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.delete_btn:SetSize(150, 22)
    panel.delete_btn:SetPoint("TOPLEFT", 30, -194)
    panel.delete_btn:SetText(L["Delete Active Profile"])
    addon_data.config.StyleButton(panel.delete_btn, true)
    panel.delete_btn:SetScript("OnClick", function()
        local current = addon_data.db:GetCurrentProfile()
        if current == "Default" then return end
        StaticPopup_Show("WST_CONFIRM_DELETE_PROFILE", current, nil, current)

                -- Refresh UI / bindings
        if addon_data.core.RefreshFromDB then
            addon_data.core.RefreshFromDB()
        end

        RefreshAllAfterProfileChange()
        -- Rebuild dropdowns / labels if you do that
        UIDropDownMenu_SetText(panel.profile_dropdown, addon_data.db:GetCurrentProfile())
    end)

    panel:SetHeight(220)
end

