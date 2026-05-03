local addon_name, addon_data = ...
local L = addon_data.localization_table

--- define addon structure from the above local variable
addon_data.hunter = {}
--- declare array for ranks of all abilities, cast times, cooldown, based on spell ID
addon_data.hunter.shot_spell_ids = {
    [75] = {spell_name = L["Auto Shot"], rank = nil, cast_time = 0.5, cooldown = nil},
	[5384] = {spell_name = L["Feign Death"], rank = nil, cast_time = nil, cooldown = nil},
	[19506] = {spell_name = L["Trueshot Aura"], rank = 1, cast_time = nil, cooldown = nil},
	[20905] = {spell_name = L["Trueshot Aura"], rank = 2, cast_time = nil, cooldown = nil},
	[20906] = {spell_name = L["Trueshot Aura"], rank = 3, cast_time = nil, cooldown = nil},
    [2643] =  {spell_name = L["Multi-Shot"], rank = 1, cast_time = 0.5, cooldown = 10},
    [14288] = {spell_name = L["Multi-Shot"], rank = 2, cast_time = 0.5, cooldown = 10},
    [14289] = {spell_name = L["Multi-Shot"], rank = 3, cast_time = 0.5, cooldown = 10},
    [14290] = {spell_name = L["Multi-Shot"], rank = 4, cast_time = 0.5, cooldown = 10},
    [25294] = {spell_name = L["Multi-Shot"], rank = 5, cast_time = 0.5, cooldown = 10},
    [19434] = {spell_name = L["Aimed Shot"], rank = 1, cast_time = 3.5, cooldown = 6},
    [20900] = {spell_name = L["Aimed Shot"], rank = 2, cast_time = 3.5, cooldown = 6},
    [20901] = {spell_name = L["Aimed Shot"], rank = 3, cast_time = 3.5, cooldown = 6},
    [20902] = {spell_name = L["Aimed Shot"], rank = 4, cast_time = 3.5, cooldown = 6},
    [20903] = {spell_name = L["Aimed Shot"], rank = 5, cast_time = 3.5, cooldown = 6},
    [20904] = {spell_name = L["Aimed Shot"], rank = 6, cast_time = 3.5, cooldown = 6},
    [5019] = {spell_name = L["Shoot"], rank = nil, cast_time = nil, cooldown = nil}
}
--- is spell multi-shot defined by spell_id
addon_data.hunter.is_spell_multi_shot = function(spell_id)
    if (spell_id == 2643) or (spell_id == 14288) or (spell_id == 14289) or 
       (spell_id == 14290) or (spell_id == 25294) then
            return true
    else
            return false
    end
end
--- is spell aimed shot defined by spell_id
addon_data.hunter.is_spell_aimed_shot = function(spell_id)
    if (spell_id == 19434) or (spell_id == 20900) or (spell_id == 20901) or 
       (spell_id == 20902) or (spell_id == 20903) or (spell_id == 20904) then
            return true
    else
            return false
    end
end
--- is spell auto shot defined by spell_id
addon_data.hunter.is_spell_auto_shot = function(spell_id)
    return (spell_id == 75)
end
--- is spell shoot defined by spell_id
addon_data.hunter.is_spell_shoot = function(spell_id)
    return (spell_id == 5019)
end
--- default settings to be loaded on initial load and reset to default
addon_data.hunter.default_settings = {
	enabled = true,
	width = 300,
	height = 12,
	fontsize = 12,
    point = "CENTER",
	rel_point = "CENTER",
	x_offset = 0,
	y_offset = -260,
	in_combat_alpha = 1.0,
	ooc_alpha = 0.0,
	backplane_alpha = 0.5,
	is_locked = false,
    show_text = true,
    show_multishot_clip_bar = true,
	show_autoshot_delay_timer = true,
    show_border = false,
    classic_bars = true,
    one_bar = false,
    cooldown_r = 0.95, cooldown_g = 0.95, cooldown_b = 0.95, cooldown_a = 1.0,
    auto_cast_r = 0.8, auto_cast_g = 0.0, auto_cast_b = 0.0, auto_cast_a = 1.0,
    range_r = 0.85, range_g = 0.1, range_b = 0.1, range_a = 1.0,
    latency_r = 1.0, latency_g = 0.82, latency_b = 0.0, latency_a = 0.5,
    latency_buffer_ms = 30,
    clip_r = 1.0, clip_g = 0.0, clip_b = 0.0, clip_a = 0.7
}
--- Initializing variables for calculations and function calls
addon_data.hunter.shooting = false
-- added check below for range speed to default 3 on initialize 
addon_data.hunter.range_speed = 3
addon_data.hunter.auto_cast_time = 0.52
addon_data.hunter.shot_timer = 0.52
addon_data.hunter.last_shot_time = GetTime()
addon_data.hunter.auto_shot_ready = true
addon_data.hunter.FeignStatus = false
addon_data.hunter.FeignFullReset = false
addon_data.hunter.range_auto_speed_modified = 1
addon_data.hunter.base_speed = 1
addon_data.hunter.spell_GCD = 0
addon_data.hunter.spell_GCD_Time = 0

addon_data.hunter.casting = false
addon_data.hunter.casting_auto = false
addon_data.hunter.range_cast_speed_modifer = 1

addon_data.hunter.has_moved = false

-- handling of stopping auto timer from starting
addon_data.hunter.StartCastingSpell = function(spell_id)
    
    if not addon_data.hunter.casting and UnitCanAttack('player', 'target') then
        local spell_name, _, _, cast_time, _, _, _ = GetSpellInfo(spell_id)
        if cast_time == nil then
			
            return 
        end
        if not addon_data.hunter.is_spell_auto_shot(spell_id) and 
			not addon_data.hunter.is_spell_shoot(spell_id) and cast_time > 0 then
               addon_data.hunter.casting = true
        end
	end
end

addon_data.hunter.LoadSettings = function()
    -- Ensure the alias is pointing at the current profile table
    character_hunter_settings = addon_data.db.profile.hunter

    for setting, value in pairs(addon_data.hunter.default_settings) do
        if character_hunter_settings[setting] == nil then
            character_hunter_settings[setting] = value
        end
    end
        if character_hunter_settings.enabled == nil then
        local _, class = UnitClass("player")
        character_hunter_settings.enabled = (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK")
    end
    
    -- One-time tooltip initialize
    if not addon_data.hunter.scan_tip then
        addon_data.hunter.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
        addon_data.hunter.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--
-- Replaced update info with this instead, checking weapon id every time inventory is changed for simplicity
addon_data.hunter.OnInventoryChange = function()
	local _, class, _ = UnitClass("player")
	if (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK") then
		addon_data.hunter.base_speed = addon_data.GetRangedBaseSpeed()
	end
end	

--- Reset Swing Timer unhasted separately due to feign and other spells
addon_data.hunter.FeignDeath = function()
    addon_data.hunter.last_shot_time = GetTime()
	if not addon_data.hunter.FeignFullReset then
		addon_data.hunter.range_speed = addon_data.GetRangedBaseSpeed() + 0.15
		addon_data.hunter.FeignFullReset = true
	end
    addon_data.hunter.ResetShotTimer()
end

-- Modified to use base speed and current ranged speed, to get the haste modifiers. This is used in multi-shot cast bar to provide an accurate bar, as well as multi clip
addon_data.hunter.UpdateRangeCastSpeedModifier = function()
	local _, class, _ = UnitClass("player")
	
	if addon_data.hunter.base_speed == 1 and (class == "HUNTER" or class == "MAGE" or class == "PRIEST" or class == "WARLOCK") then 
		addon_data.hunter.base_speed = addon_data.GetRangedBaseSpeed()
	else
		local range_speed, _, _, _, _, _ = UnitRangedDamage("player")
		-- added case for if range speed returns nil or 0
		if range_speed == nil or range_speed == 0 then
			range_speed = 1
            addon_data.hunter.range_cast_speed_modifer = 1
		else
			addon_data.hunter.range_cast_speed_modifer = range_speed / addon_data.hunter.base_speed
		end
	end
end


--- Update timer for auto shot based on various conditions
addon_data.hunter.ResetShotTimer = function()
    -- The timer is reset to either the auto cast time or the difference between the time since the last shot and the current time depending on which is larger
    local curr_time = GetTime()
    local range_speed = addon_data.hunter.range_speed
	
    if (curr_time + 0.05 - addon_data.hunter.last_shot_time) > (range_speed - addon_data.hunter.auto_cast_time) then
		addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
		addon_data.hunter.auto_shot_ready = true
		
    elseif curr_time ~= addon_data.hunter.last_shot_time and not addon_data.hunter.casting then
        addon_data.hunter.shot_timer = curr_time - addon_data.hunter.last_shot_time
        addon_data.hunter.auto_shot_ready = false
		
	elseif addon_data.hunter.casting then
		if (curr_time - addon_data.hunter.last_shot_time) > (3 * addon_data.hunter.range_cast_speed_modifer) then
			addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
		end
    else
        addon_data.hunter.shot_timer = range_speed
        addon_data.hunter.auto_shot_ready = false
    end
end

addon_data.hunter.UpdateAutoShotTimer = function(elapsed)
    local curr_time = GetTime()
	local shot_timer = addon_data.hunter.shot_timer
	local _, class, _ = UnitClass("player")
    if addon_data.hunter.shot_timer < 0 then
		addon_data.hunter.shot_timer = 0
	else
		addon_data.hunter.shot_timer = shot_timer - elapsed
	end
	if class == "WARLOCK" or class == "MAGE" or class == "PRIEST" then
		addon_data.hunter.auto_cast_time = 0.52
	else
		addon_data.hunter.UpdateRangeCastSpeedModifier()
		addon_data.hunter.auto_cast_time = 0.52 * addon_data.hunter.range_cast_speed_modifer
	end
	
    -- If the player moved then the timer resets
    if addon_data.hunter.has_moved or addon_data.hunter.casting then
        if addon_data.hunter.shot_timer <= addon_data.hunter.auto_cast_time then
            addon_data.hunter.ResetShotTimer()			
        end
    end
    -- If the shot timer is less than the auto cast time then the auto shot is ready
    if addon_data.hunter.shot_timer <= addon_data.hunter.auto_cast_time then
        addon_data.hunter.auto_shot_ready = true
        -- If we are not shooting then the timer should be reset
        if not addon_data.hunter.shooting then
            addon_data.hunter.ResetShotTimer()
        end
    else
         addon_data.hunter.auto_shot_ready = false
    end
	if addon_data.hunter.spell_GCD_Time + 1.5 > curr_time then
		addon_data.hunter.spell_GCD = 1.5 - (curr_time - addon_data.hunter.spell_GCD_Time)
	end
end

addon_data.hunter.OnUpdate = function(elapsed)
    local settings = character_hunter_settings
    if settings.enabled then
        -- Check to see if we have moved
        addon_data.hunter.has_moved = (GetUnitSpeed("player") > 0)
		
		-- Check for feign death movement that causes swing reset
		if addon_data.hunter.FeignStatus and addon_data.hunter.has_moved then
			addon_data.hunter.FeignDeath()
			addon_data.hunter.FeignStatus = false
		end

        -- Update the Auto Shot timer based on the updated settings
        addon_data.hunter.UpdateAutoShotTimer(elapsed)
        -- Update the visuals
        addon_data.hunter.UpdateVisualsOnUpdate()
    end
end

addon_data.hunter.GetLatencySeconds = function()
    local _, _, _, latency = GetNetStats()
    return math.max((latency or 0) / 1000, 0)
end

addon_data.hunter.GetRangeCheckSpellName = function()
    local _, class = UnitClass("player")
    if class == "HUNTER" then
        return GetSpellInfo(75)
    end

    return GetSpellInfo(5019)
end

addon_data.hunter.IsTargetOutOfRange = function()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
        return false
    end

    local range_check_spell = addon_data.hunter.GetRangeCheckSpellName()
    if not range_check_spell then
        return false
    end

    local success, in_range = pcall(IsSpellInRange, range_check_spell, "target")
    if not success then
        success, in_range = pcall(IsSpellInRange, range_check_spell, "spell", "target")
    end

    return success and in_range == 0
end

-- detecting jumps out of a feign death to trigger a reset 
hooksecurefunc("JumpOrAscendStart", function()
	if  addon_data.hunter.FeignStatus then  
			addon_data.hunter.FeignDeath()
			addon_data.hunter.FeignStatus = false
	end	  
end)


--- spell functions to determine the state of the spell being casted.
--- -----------------------------------------------------------------
--- Determines the state of shooting on or off
addon_data.hunter.OnStartAutorepeatSpell = function()
    addon_data.hunter.shooting = true
	
    if addon_data.hunter.shot_timer <= addon_data.hunter.auto_cast_time then
        --addon_data.hunter.ResetShotTimer()
    end
end

addon_data.hunter.OnStopAutorepeatSpell = function()
    addon_data.hunter.shooting = false
end
-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
addon_data.hunter.OnCombatLogUnfiltered = function(combat_info)
    local _, event, _, casterID, _, _, _, targetID, targetName, _, _, spellID, name, _ = unpack(combat_info)
	local _, rank, icon, castTime = GetSpellInfo(spellID)
	local icon, castTime = select(3, GetSpellInfo(spellID))

	if casterID == UnitGUID("player") then
	
		if event == "SPELL_CAST_START" then
		
				addon_data.hunter.FeignStatus = false
				addon_data.hunter.StartCastingSpell(spellID)
				
				if addon_data.hunter.is_spell_auto_shot(spellID) then
					addon_data.hunter.casting_auto = true
				end
				if spellID == 34120 or addon_data.hunter.is_spell_multi_shot(spellID) then
					addon_data.hunter.spell_GCD = 1.5
					addon_data.hunter.spell_GCD_Time = GetTime()
				end
				
		return end

	end		
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
addon_data.hunter.OnUnitSpellCastSucceeded = function(unit, spell_id)

	if unit == 'player' then
	
	    addon_data.hunter.casting = false
        -- If the spell is Auto Shot then reset the shot timer
        if addon_data.hunter.shot_spell_ids[spell_id] then
            local spell_name = addon_data.hunter.shot_spell_ids[spell_id].spell_name
			if spell_name == L["Feign Death"] or spell_name == L["Trueshot Aura"] then
				if spell_name == L["Feign Death"] then
					addon_data.hunter.FeignStatus = true
				end
				addon_data.hunter.FeignDeath()
				return
			end
			if addon_data.castbar.is_spell_aimed_shot(spell_id) then

				addon_data.hunter.ResetShotTimer()
				addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
                
			end
            if addon_data.hunter.is_spell_auto_shot(spell_id) or addon_data.hunter.is_spell_shoot(spell_id) then
				addon_data.hunter.FeignFullReset = false
                addon_data.hunter.last_shot_time = GetTime()
                addon_data.hunter.ResetShotTimer()
				addon_data.hunter.casting_auto = false
			--else 
                --addon_data.hunter.casting_auto = false
            end
			if addon_data.hunter.is_spell_shoot(spell_id) then
				local new_range_speed, _, _, _, _, _ = UnitRangedDamage("player")
				addon_data.hunter.range_speed = new_range_speed
			end
        end

		if addon_data.hunter.is_spell_auto_shot(spell_id) then	-- Update the ranged attack speed
			local new_range_speed, _, _, _, _, _ = UnitRangedDamage("player")

			-- Handling for getting haste buffs in combat, don't need to update auto shot cast time until the next shot is ready
			if new_range_speed ~= addon_data.hunter.range_speed then
				if not addon_data.hunter.auto_shot_ready then
					addon_data.hunter.shot_timer = addon_data.hunter.shot_timer * 
											(new_range_speed / addon_data.hunter.range_speed)
				end
                
				if not new_range_speed or new_range_speed == 0 then
                    new_range_speed = addon_data.hunter.range_speed or 1
                end
                addon_data.hunter.range_speed = new_range_speed
				addon_data.hunter.range_auto_speed_modified = addon_data.hunter.range_cast_speed_modifer
			end
		end
    end
end

addon_data.hunter.OnUnitSpellCastInterrupted = function(unit, spell_id)
	
	addon_data.hunter.casting = false
	if unit == 'player' and addon_data.hunter.is_spell_auto_shot(spell_id) then
		addon_data.hunter.casting_auto = false
		--addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time
		--addon_data.hunter.ResetShotTimer()
	end
	
end

--- triggered when auto shot is toggled on and attempts to begin casting, but can't
--- This causes 0.5 seconds of delay before it can try casting again
addon_data.hunter.OnUnitSpellCastFailedQuiet = function(unit, spell_id)
    local settings = character_hunter_settings
	local curr_time = GetTime()
    if settings.show_autoshot_delay_timer and unit == "player" and addon_data.hunter.is_spell_auto_shot(spell_id) then
        
		if not addon_data.hunter.casting and addon_data.hunter.shooting 
		   and (curr_time - addon_data.hunter.last_shot_time) > (addon_data.hunter.range_speed - addon_data.hunter.auto_cast_time) then
			
			addon_data.hunter.shot_timer = addon_data.hunter.auto_cast_time + 0.5
		end
    end
end

--- Updating and initializing visuals
--- ---------------------------------
addon_data.hunter.UpdateVisualsOnUpdate = function()
    local settings = character_hunter_settings
    local frame = addon_data.hunter.frame
    local range_speed = addon_data.hunter.range_speed
    local shot_timer = addon_data.hunter.shot_timer
    local auto_cast_time = addon_data.hunter.auto_cast_time
	local mult_cast_time = 0.5 * addon_data.hunter.range_cast_speed_modifer
    local latency_seconds = addon_data.hunter.GetLatencySeconds()
    local out_of_range = addon_data.hunter.IsTargetOutOfRange()
	
	if settings.enabled then
        if out_of_range then
            frame.shot_bar_text:ClearAllPoints()
            frame.shot_bar_text:SetPoint("CENTER", 0, (settings.fontsize / 10))
            frame.shot_bar_text:SetJustifyH("CENTER")
            frame.shot_bar_text:SetText(L["Out of range"])
        else
            frame.shot_bar_text:ClearAllPoints()
            frame.shot_bar_text:SetPoint("BOTTOMRIGHT", -5, (settings.height / 2) - (settings.fontsize / 2))
            frame.shot_bar_text:SetJustifyH("RIGHT")
            frame.shot_bar_text:SetText(tostring(addon_data.utils.SimpleRound(shot_timer, 0.1)))
        end
        if addon_data.core.in_combat or addon_data.hunter.shooting or addon_data.hunter.casting_shot then
            frame:SetAlpha(settings.in_combat_alpha)
        else
            frame:SetAlpha(settings.ooc_alpha)
        end
        if out_of_range then
            frame.shot_bar:Show()
            frame.shot_bar:SetVertexColor(settings.range_r, settings.range_g, settings.range_b, settings.range_a)
            frame.shot_bar:SetWidth(settings.width)
            frame.multishot_clip_bar:Hide()
            frame.latency_bar:Hide()
            frame.auto_shot_cast_bar:Hide()
            frame:SetSize(settings.width, settings.height)
            return
        elseif settings.one_bar then
            frame.auto_shot_cast_bar:Show()
        end
        if not settings.one_bar then
            frame.shot_bar:Show()
            if addon_data.hunter.auto_shot_ready then
                frame.shot_bar:SetVertexColor(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
                new_width = settings.width * (auto_cast_time - shot_timer) / auto_cast_time
                frame.multishot_clip_bar:Hide()
            else
                if addon_data.hunter.spell_GCD > 0.5 then
					frame.shot_bar:SetVertexColor(0.8, 0.64, 0, 1)
				else
					frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
				end
                new_width = settings.width * ((shot_timer - auto_cast_time) / (range_speed - auto_cast_time))
                if settings.show_multishot_clip_bar then
                    frame.multishot_clip_bar:Show()
                    multishot_clip_width = math.min((settings.width * 2) * (mult_cast_time / (addon_data.hunter.range_speed)), settings.width)
                    frame.multishot_clip_bar:SetWidth(multishot_clip_width)
                end
            end
            if new_width < 2 then
                new_width = 2
            end
            frame.shot_bar:SetWidth(math.min(new_width, settings.width))
        else
		    if addon_data.hunter.spell_GCD > 0.2 then
				frame.shot_bar:SetVertexColor(0.8, 0.64, 0, 1)
			else
				frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
			end
            local latency_guard_seconds = latency_seconds + (math.max(settings.latency_buffer_ms or 0, 0) / 1000)
            local fixed_auto_shot_cast_width = settings.width * (addon_data.hunter.auto_cast_time / addon_data.hunter.range_speed)
            local latency_width = math.min(
                settings.width * (latency_guard_seconds / range_speed),
                math.max(settings.width - fixed_auto_shot_cast_width, 0)
            )
            local shot_window_seconds = math.min(auto_cast_time + latency_guard_seconds, range_speed)
            local shot_window_width = fixed_auto_shot_cast_width + latency_width
            local ready_width = math.max(settings.width - shot_window_width, 0)
            local cooldown_duration = math.max(range_speed - shot_window_seconds, 0.001)
            local cooldown_progress = math.min(math.max((range_speed - shot_timer) / cooldown_duration, 0), 1)
            local timer_width = ready_width * cooldown_progress
            local auto_shot_cast_width
            if shot_timer <= shot_window_seconds and addon_data.hunter.shooting then
                local shot_window_progress = math.min(math.max((shot_window_seconds - shot_timer) / math.max(shot_window_seconds, 0.001), 0), 1)
                timer_width = math.min(
                    math.max(ready_width + (shot_window_width * shot_window_progress), 0),
                    settings.width
                )
                auto_shot_cast_width = math.max((settings.width - latency_width) - timer_width, 0)
            else
                auto_shot_cast_width = fixed_auto_shot_cast_width
            end
            if settings.show_multishot_clip_bar then
                frame.multishot_clip_bar:Show()
                local multishot_clip_width = math.min(settings.width * (mult_cast_time / range_speed ), settings.width)
                frame.multishot_clip_bar:SetWidth(5)
                local multi_offset = math.min(shot_window_width + multishot_clip_width, settings.width)
                frame.multishot_clip_bar:SetPoint('BOTTOMRIGHT', -multi_offset, 0)
            end
            if latency_width > 0 then
                frame.latency_bar:SetWidth(latency_width)
                frame.latency_bar:ClearAllPoints()
                frame.latency_bar:SetPoint('BOTTOMRIGHT', 0, 0)
                frame.latency_bar:Show()
            else
                frame.latency_bar:Hide()
            end
            if timer_width > 0 then
                frame.shot_bar:Show()
                frame.shot_bar:SetWidth(math.min(timer_width, settings.width))
            else
                frame.shot_bar:Hide()
            end
            frame.auto_shot_cast_bar:ClearAllPoints()
            frame.auto_shot_cast_bar:SetPoint('BOTTOMRIGHT', -latency_width, 0)
            frame.auto_shot_cast_bar:SetWidth(math.max(auto_shot_cast_width, 0.001))
        end
		frame:SetSize(settings.width, settings.height)
    end
end

addon_data.hunter.UpdateVisualsOnSettingsChange = function()
    local settings = character_hunter_settings
    local frame = addon_data.hunter.frame
	if settings.enabled then
        frame:EnableMouse(not settings.is_locked)
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
        if settings.show_border then
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = "Interface/AddOns/WeaponSwingTimer/Images/Border", 
                tile = true, tileSize = 16, edgeSize = 12, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        else
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = nil, 
                tile = true, tileSize = 16, edgeSize = 16, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        end
        frame.backplane:SetBackdropColor(0,0,0,settings.backplane_alpha)
        frame.shot_bar:ClearAllPoints()
        if not settings.one_bar then
            frame.shot_bar:SetPoint("BOTTOM", 0, 0)
            frame.auto_shot_cast_bar:Hide()
            frame.latency_bar:Hide()
        else
            frame.shot_bar:SetPoint("BOTTOMLEFT", 0, 0)
            frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
            frame.auto_shot_cast_bar:Show()
            frame.auto_shot_cast_bar:SetPoint('BOTTOMRIGHT', 0, 0)
            frame.auto_shot_cast_bar:SetHeight(settings.height)
            frame.auto_shot_cast_bar:SetVertexColor(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
            frame.latency_bar:SetHeight(settings.height)
            frame.latency_bar:SetColorTexture(settings.latency_r, settings.latency_g, settings.latency_b, settings.latency_a)
        end
        frame.shot_bar_text:SetTextColor(1.0, 1.0, 1.0, 1.0)
		frame.shot_bar_text:SetFont(STANDARD_TEXT_FONT, settings.fontsize)
		
        frame.shot_bar:SetHeight(settings.height)
        frame.shot_bar:SetTexture(addon_data.utils.GetBarTexture())
        frame.auto_shot_cast_bar:SetTexture(addon_data.utils.GetBarTexture())
        frame.multishot_clip_bar:ClearAllPoints()
        if not settings.one_bar then
            frame.multishot_clip_bar:SetPoint("BOTTOM", 0, 0)
        else
            frame.multishot_clip_bar:SetPoint("BOTTOMRIGHT", 0, 0)
        end
        frame.multishot_clip_bar:SetHeight(settings.height)
        frame.multishot_clip_bar:SetColorTexture(settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)
		
        if settings.show_multishot_clip_bar then
            frame.multishot_clip_bar:Show()
        else
            frame.multishot_clip_bar:Hide()
        end
        if settings.show_text then
            frame.shot_bar_text:Show()
        else
            frame.shot_bar_text:Hide()
        end
    else
        frame:Hide()
    end
end

addon_data.hunter.OnFrameDragStart = function()
    if not character_hunter_settings.is_locked then
        addon_data.hunter.frame:StartMoving()
    end
end

addon_data.hunter.OnFrameDragStop = function()
    local frame = addon_data.hunter.frame
    local settings = character_hunter_settings
    frame:StopMovingOrSizing()
    local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = addon_data.utils.SimpleRound(x_offset, 1)
    settings.y_offset = addon_data.utils.SimpleRound(y_offset, 1)
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateConfigPanelValues()
end

addon_data.hunter.InitializeVisuals = function()
    local settings = character_hunter_settings
    -- Create the frame
    addon_data.hunter.frame = CreateFrame("Frame", addon_name .. "HunterAutoshotFrame", UIParent)
    local frame = addon_data.hunter.frame
	
    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", addon_data.hunter.OnFrameDragStart)
    frame:SetScript("OnDragStop", addon_data.hunter.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "HunterBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint('TOPLEFT', -9, 9)
    frame.backplane:SetPoint('BOTTOMRIGHT', 9, -9)
    frame.backplane:SetFrameStrata('BACKGROUND')
    -- Create the shot bar
    frame.shot_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the shot bar text
    frame.shot_bar_text = frame:CreateFontString(nil,"OVERLAY")
    frame.shot_bar_text:SetFont(STANDARD_TEXT_FONT, settings.fontsize)
    frame.shot_bar_text:SetJustifyV("MIDDLE")
    frame.shot_bar_text:SetJustifyH("CENTER")
    -- Create the multishot clip bar
    frame.multishot_clip_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Create the auto shot cast bar indicator
    frame.auto_shot_cast_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Create the latency indicator that sits to the right of the fixed auto shot window in one-bar mode
    frame.latency_bar = frame:CreateTexture(nil,"BACKGROUND")
    -- Show it off
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnUpdate()
    frame:Show()
end



--- Everything below is designated as part of the UI settings menu. Checkboxes, adjustments, sliders
--- ------------------------------------------------------------------------------------------------
--- Adjusts the values of everything based on the settings selected with UpdateConfigPanelValues
--- 10 boxes that can be checked, all exact same just with different names
--- Bar height, width, and offset values set with numerical value
--- Color picker selection for 3 visual displays of the bars
--- Alpha adjustments for 3 visual displays of the bars
addon_data.hunter.UpdateConfigPanelValues = function()
    local panel = addon_data.hunter.config_frame
    local settings = character_hunter_settings
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_multishot_clip_bar_checkbox:SetChecked(settings.show_multishot_clip_bar)
	panel.show_autoshot_delay_checkbox:SetChecked(settings.show_autoshot_delay_timer)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.one_bar_checkbox:SetChecked(settings.one_bar)
    panel.show_text_checkbox:SetChecked(settings.show_text)
    panel.width_editbox:SetText(tostring(settings.width))
    panel.width_editbox:SetCursorPosition(0)
    panel.height_editbox:SetText(tostring(settings.height))
    panel.height_editbox:SetCursorPosition(0)
	panel.fontsize_editbox:SetText(tostring(settings.fontsize))
    panel.fontsize_editbox:SetCursorPosition(0)
    panel.x_offset_editbox:SetText(tostring(settings.x_offset))
    panel.x_offset_editbox:SetCursorPosition(0)
    panel.y_offset_editbox:SetText(tostring(settings.y_offset))
    panel.y_offset_editbox:SetCursorPosition(0)
    panel.latency_buffer_editbox:SetText(tostring(settings.latency_buffer_ms))
    panel.latency_buffer_editbox:SetCursorPosition(0)
    panel.cooldown_color_picker.foreground:SetColorTexture(
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
    panel.autoshot_cast_color_picker.foreground:SetColorTexture(
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
    panel.range_color_picker.foreground:SetColorTexture(
        settings.range_r, settings.range_g, settings.range_b, settings.range_a)
    panel.latency_color_picker.foreground:SetColorTexture(
        settings.latency_r, settings.latency_g, settings.latency_b, settings.latency_a)
    panel.multi_clip_color_picker.foreground:SetColorTexture(
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)
        
    if settings.one_bar then
        panel.explaination:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/HunterOneBarExplainedAlpha')
        panel.explaination:SetSize(350, 175)
        panel.explaination:SetPoint('TOPLEFT', 16, -470)
    else
        panel.explaination:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/HunterBarExplainedFullAlpha')
        panel.explaination:SetSize(620, 155)
        panel.explaination:SetPoint('TOPLEFT', 16, -470)
    end
    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

addon_data.hunter.EnabledCheckBoxOnClick = function(self)
    character_hunter_settings.enabled = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ShowMultiShotClipBarCheckBoxOnClick = function(self)
   character_hunter_settings.show_multishot_clip_bar = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ShowAutoShotDelayCheckBoxOnClick = function(self)
   character_hunter_settings.show_autoshot_delay_timer = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ShowBorderCheckBoxOnClick = function(self)
    character_hunter_settings.show_border = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.ClassicBarsCheckBoxOnClick = function(self)
    character_hunter_settings.classic_bars = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.OneBarCheckBoxOnClick = function(self)
    character_hunter_settings.one_bar = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateConfigPanelValues()
end

addon_data.hunter.ShowTextCheckBoxOnClick = function(self)
    character_hunter_settings.show_text = self:GetChecked()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.WidthEditBoxOnEnter = function(self)
    character_hunter_settings.width = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.HeightEditBoxOnEnter = function(self)
    character_hunter_settings.height = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.FontSizeEditBoxOnEnter = function(self)
    character_hunter_settings.fontsize = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.XOffsetEditBoxOnEnter = function(self)
    character_hunter_settings.x_offset = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.YOffsetEditBoxOnEnter = function(self)
    character_hunter_settings.y_offset = tonumber(self:GetText())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.LatencyBufferEditBoxOnEnter = function(self)
    local buffer_ms = tonumber(self:GetText())
    if buffer_ms then
        character_hunter_settings.latency_buffer_ms = math.max(buffer_ms, 0)
        addon_data.hunter.UpdateVisualsOnSettingsChange()
    end
end

addon_data.hunter.CooldownColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "cooldown",
        addon_data.hunter.config_frame.cooldown_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.AutoShotCastColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "auto_cast",
        addon_data.hunter.config_frame.autoshot_cast_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.RangeColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "range",
        addon_data.hunter.config_frame.range_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.MultiClipColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "clip",
        addon_data.hunter.config_frame.multi_clip_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.LatencyColorPickerOnClick = function()
    addon_data.config.ShowColorPicker(
        character_hunter_settings,
        "latency",
        addon_data.hunter.config_frame.latency_color_picker.foreground,
        addon_data.hunter.UpdateVisualsOnSettingsChange
    )
end

addon_data.hunter.CombatAlphaOnValChange = function(self)
    character_hunter_settings.in_combat_alpha = tonumber(self:GetValue())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.OOCAlphaOnValChange = function(self)
    character_hunter_settings.ooc_alpha = tonumber(self:GetValue())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.hunter.BackplaneAlphaOnValChange = function(self)
    character_hunter_settings.backplane_alpha = tonumber(self:GetValue())
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end
--- Initializes the main setting panel including layout, alignment, and design
addon_data.hunter.CreateConfigPanel = function(parent_panel)
    addon_data.hunter.config_frame = CreateFrame("Frame", addon_name .. "HunterConfigPanel", parent_panel)
    local panel = addon_data.hunter.config_frame
    local settings = character_hunter_settings
    panel:SetSize(700, 660)
    -- Title Text
    panel.title_text = addon_data.config.TextFactory(panel, L["Hunter & Wand Shot Bar Settings"], 20)
    panel.title_text:SetPoint("TOPLEFT", 10 , -10)
    panel.title_text:SetTextColor(unpack(addon_data.config.theme.title))

    panel.general_section = addon_data.config.SectionFactory(panel, L["General Settings"], 150, 150)
    panel.general_section:SetPoint("TOPLEFT", 0, -34)
    panel.layout_section = addon_data.config.SectionFactory(panel, L["Layout"], 226, 286)
    panel.layout_section:SetPoint("TOPLEFT", 162, -34)
    panel.opacity_section = addon_data.config.SectionFactory(panel, L["Opacity"], 244, 202)
    panel.opacity_section:SetPoint("TOPLEFT", 400, -34)
    panel.hunter_section = addon_data.config.SectionFactory(panel, L["Hunter Specific Settings"], 388, 92)
    panel.hunter_section:SetPoint("TOPLEFT", 0, -334)
    panel.explaination_section = addon_data.config.SectionFactory(panel, L["Bar Explanation"], 640, 204)
    panel.explaination_section:SetPoint("TOPLEFT", 0, -438)
    
    -- General Settings Text
    panel.general_text = addon_data.config.TextFactory(panel, L["General Settings"], 16)
    panel.general_text:SetPoint("TOPLEFT", 10 , -50)
    panel.general_text:SetTextColor(unpack(addon_data.config.theme.subtitle))
    panel.general_text:Hide()
    
    -- Enabled Checkbox
    panel.enabled_checkbox = addon_data.config.CheckBoxFactory(
        "HunterEnabledCheckBox",
        panel,
        L["Enable"],
        L["Enables the Autoshot/Shoot bars."],
        addon_data.hunter.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -66)
    
    -- Show Border Checkbox
    panel.show_border_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowBorderCheckBox",
        panel,
        L["Show border"],
        L["Enables the shot bar's border."],
        addon_data.hunter.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -88)
    
    -- One bar Checkbox
    panel.one_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterOneBarCheckBox",
        panel,
        L["YaHT / One bar"],
        L["Changes the Auto Shot bar to a single bar that fills from left to right"],
        addon_data.hunter.OneBarCheckBoxOnClick)
    panel.one_bar_checkbox:SetPoint("TOPLEFT", 10, -110)
    
    -- Show Text Checkbox
    panel.show_text_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowTextCheckBox",
        panel,
        L["Show Text"],
        L["Enables the shot bar text."],
        addon_data.hunter.ShowTextCheckBoxOnClick)
    panel.show_text_checkbox:SetPoint("TOPLEFT", 10, -132)
    
    -- Width EditBox
    panel.width_editbox = addon_data.config.EditBoxFactory(
        "HunterWidthEditBox",
        panel,
        L["Bar Width"],
        75,
        25,
        addon_data.hunter.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 260, -78)
    -- Height EditBox
    panel.height_editbox = addon_data.config.EditBoxFactory(
        "HunterHeightEditBox",
        panel,
        L["Bar Height"],
        75,
        25,
        addon_data.hunter.HeightEditBoxOnEnter)
	panel.height_editbox:SetPoint("TOPLEFT", 340, -78)
	-- Font Size EditBox
	panel.fontsize_editbox = addon_data.config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        L["Font Size"],
        75,
        25,
        addon_data.hunter.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 180, -78)
    -- X Offset EditBox
    panel.x_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterXOffsetEditBox",
        panel,
        L["X Offset"],
        75,
        25,
        addon_data.hunter.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 220, -128)
    -- Y Offset EditBox
    panel.y_offset_editbox = addon_data.config.EditBoxFactory(
        "HunterYOffsetEditBox",
        panel,
        L["Y Offset"],
        75,
        25,
        addon_data.hunter.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 300, -128)
    
    -- Cooldown color picker
    panel.cooldown_color_picker = addon_data.config.color_picker_factory(
        'HunterCooldownColorPicker',
        panel,
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a,
        L["Auto Shot Cooldown Color"],
        addon_data.hunter.CooldownColorPickerOnClick)
    panel.cooldown_color_picker:SetPoint('TOPLEFT', 182, -174)
    
    -- Autoshot cast color picker
    panel.autoshot_cast_color_picker = addon_data.config.color_picker_factory(
        'HunterAutoShotCastColorPicker',
        panel,
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a,
        L["Auto Shot Cast Color"],
        addon_data.hunter.AutoShotCastColorPickerOnClick)
    panel.autoshot_cast_color_picker:SetPoint('TOPLEFT', 182, -196)

    -- Out of range color picker
    panel.range_color_picker = addon_data.config.color_picker_factory(
        'HunterOutOfRangeColorPicker',
        panel,
        settings.range_r, settings.range_g, settings.range_b, settings.range_a,
        L["Out of Range Color"],
        addon_data.hunter.RangeColorPickerOnClick)
    panel.range_color_picker:SetPoint('TOPLEFT', 182, -220)

    -- Network latency color picker
    panel.latency_color_picker = addon_data.config.color_picker_factory(
        'HunterLatencyColorPicker',
        panel,
        settings.latency_r, settings.latency_g, settings.latency_b, settings.latency_a,
        L["Network Latency Color"],
        addon_data.hunter.LatencyColorPickerOnClick)
    panel.latency_color_picker:SetPoint('TOPLEFT', 182, -244)

    -- Latency safety buffer EditBox
    panel.latency_buffer_editbox = addon_data.config.EditBoxFactory(
        "HunterLatencyBufferEditBox",
        panel,
        L["Safety Buffer (ms)"],
        80,
        25,
        addon_data.hunter.LatencyBufferEditBoxOnEnter)
    panel.latency_buffer_editbox:SetPoint("TOPLEFT", 270, -292)
    
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = addon_data.config.SliderFactory(
        "HunterInCombatAlphaSlider",
        panel,
        L["In Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 425, -78)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = addon_data.config.SliderFactory(
        "HunterOOCAlphaSlider",
        panel,
        L["Out of Combat Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 425, -128)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = addon_data.config.SliderFactory(
        "HunterBackplaneAlphaSlider",
        panel,
        L["Backplane Alpha"],
        0,
        1,
        0.05,
        addon_data.hunter.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 425, -178)
    
    -- Hunter Specific Settings Text
    panel.hunter_text = addon_data.config.TextFactory(panel, L["Hunter Specific Settings"], 16)
    panel.hunter_text:SetPoint("TOPLEFT", 12 , -344)
    panel.hunter_text:SetTextColor(unpack(addon_data.config.theme.subtitle))
    panel.hunter_text:Hide()

    -- Show Multi-Shot Clip Bar Checkbox
    panel.show_multishot_clip_bar_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowMultiShotClipBarCheckBox",
        panel,
        L["Multi-Shot clip bar"],
        L["Shows a bar that represents when a Multi-Shot would clip an Auto Shot."],
        addon_data.hunter.ShowMultiShotClipBarCheckBoxOnClick)
    panel.show_multishot_clip_bar_checkbox:SetPoint("TOPLEFT", 10, -366)
    
    -- Show Autoshot delay timer Checkbox
    panel.show_autoshot_delay_checkbox = addon_data.config.CheckBoxFactory(
        "HunterShowAutoShotDelayCheckBox",
        panel,
        L["Auto Shot delay timer"],
        L["Shows a timer that represents when Auto shot is delayed."],
        addon_data.hunter.ShowAutoShotDelayCheckBoxOnClick)
    panel.show_autoshot_delay_checkbox:SetPoint("TOPLEFT", 10, -388)
    
    -- Multi-shot clip color picker
    panel.multi_clip_color_picker = addon_data.config.color_picker_factory(
        'HunterMultiClipColorPicker',
        panel,
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a,
        L["Multi-Shot Clip Color"],
        addon_data.hunter.MultiClipColorPickerOnClick)
    panel.multi_clip_color_picker:SetPoint('TOPLEFT', 205, -378)
    
    -- Add the explaination text
    panel.explaination_text = addon_data.config.TextFactory(panel, L["Bar Explanation"], 16)
    panel.explaination_text:SetPoint("TOPLEFT", 16 , -448)
    panel.explaination_text:SetTextColor(unpack(addon_data.config.theme.title))
    panel.explaination_text:Hide()
    
    -- Add the explaination
    panel.explaination = panel:CreateTexture(nil, 'ARTWORK')
    
    -- Return the final panel
    addon_data.hunter.UpdateConfigPanelValues()
    return panel
end
