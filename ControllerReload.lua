--- STEAMODDED HEADER
--- MOD_NAME: Tag Fishing
--- MOD_ID: ControllerReload
--- MOD_AUTHOR: [rudesyle]
--- MOD_DESCRIPTION: Hold L2 to reload a run. Press L1 to auto-reload until the selected tags appear on both Small and Big blinds.
--- VERSION: 1.6.0

local MOD = SMODS.current_mod

local TRIGGER_AXIS      = MOD.config.trigger_axis        or 'triggerleft'
local TRIGGER_THRESHOLD = MOD.config.trigger_threshold   or 0.5

local l2_active  = false
local hunting    = false
local hunt_armed = false

local function hunt_tag_small() return MOD.config.hunt_tag_1_enabled and MOD.config.hunt_tag_1_id or nil end
local function hunt_tag_big()   return MOD.config.hunt_tag_big   end

local function get_tag_name(tag_key)
    if not tag_key then return 'None' end
    local tag = G.P_TAGS[tag_key]
    return (tag and tag.name) or '?'
end

local function has_required_tags()
    local bt = G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_tags
    if not bt then return false end
    local small_tag = bt.Small
    local big_tag = bt.Big
    local t1 = hunt_tag_small()
    local t2 = hunt_tag_big()

    if not t1 and not t2 then return true end
    if t1 and t2 then
        if t1 == t2 then return small_tag == t1 and big_tag == t1 end
        return (small_tag == t1 and big_tag == t2) or (small_tag == t2 and big_tag == t1)
    end
    if t1 then return small_tag == t1 or big_tag == t1 end
    if t2 then return small_tag == t2 or big_tag == t2 end
    return true
end

local function get_hunt_desc()
    local t1 = get_tag_name(hunt_tag_small())
    local t2 = get_tag_name(hunt_tag_big())
    if t1 == 'None' and t2 == 'None' then return 'No tags selected' end
    if t1 == 'None' then return t2 end
    if t2 == 'None' then return t1 end
    return t1 .. ' + ' .. t2
end

local function hunt_notify(text, colour)
    attention_text({
        text   = text,
        scale  = 0.5,
        hold   = 2.5,
        align  = 'cm',
        major  = G.ROOM_ATTACH,
        offset = {x = 0, y = 2},
        colour = colour or G.C.WHITE,
    })
end

local function arm_r_hold()
    hunt_armed = true
    G.CONTROLLER.held_keys['r']      = true
    G.CONTROLLER.held_key_times['r'] = 0
end

local function disarm_r_hold()
    hunt_armed = false
    G.CONTROLLER.held_keys['r']      = nil
    G.CONTROLLER.held_key_times['r'] = nil
end

--- CONFIG TAB ---
MOD.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = "tm", padding = 0.2, minw = 6 },
        nodes = {
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.15 },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "Tag 1: " .. get_tag_name(hunt_tag_small()),
                            scale = 0.5,
                            colour = G.C.UI.TEXT_LIGHT
                        }
                    },
                    create_toggle({
                        label = "Investment Tag",
                        ref_table = MOD.config,
                        ref_value = 'hunt_tag_1_enabled',
                        col = G.C.GREEN,
                    })
                }
            },
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.15 },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "Tag 2: " .. get_tag_name(hunt_tag_big()),
                            scale = 0.5,
                            colour = G.C.UI.TEXT_LIGHT
                        }
                    },
                    create_toggle({
                        label = "Tag 2",
                        ref_table = MOD.config,
                        ref_value = 'hunt_tag_big',
                        col = G.C.ORANGE
                    })
                }
            },
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.1 },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "Tag 1 is set to Investment Tag (configurable in config.lua)",
                            scale = 0.35,
                            colour = G.C.UI.TEXT_INACTIVE
                        }
                    }
                }
            }
        }
    }
end

--- L2 — MANUAL RELOAD ---
local _orig_gamepadaxis = love.gamepadaxis

function love.gamepadaxis(joystick, axis, value)
    if _orig_gamepadaxis then _orig_gamepadaxis(joystick, axis, value) end
    if axis ~= TRIGGER_AXIS then return end
    if not G or not G.CONTROLLER then return end

    local held = value >= TRIGGER_THRESHOLD
    if held and not l2_active then
        l2_active = true
        G.CONTROLLER:key_press('r')
    elseif not held and l2_active then
        l2_active = false
        G.CONTROLLER:key_release('r')
    end
end

--- L1 — TAG HUNT ---
local _orig_gamepadpressed = love.gamepadpressed

function love.gamepadpressed(joystick, button)
    if _orig_gamepadpressed then _orig_gamepadpressed(joystick, button) end
    if button ~= 'leftshoulder' then return end
    if not G or not G.CONTROLLER then return end

    if hunting then
        hunting = false
        disarm_r_hold()
        hunt_notify('Hunt cancelled', G.C.RED)
    else
        hunting = true
        hunt_notify('Hunting: ' .. get_hunt_desc(), G.C.ORANGE)

        if G.STATE == G.STATES.BLIND_SELECT then
            if has_required_tags() then
                hunting = false
                hunt_notify('Required tags found!', G.C.GREEN)
            else
                arm_r_hold()
            end
        else
            hunt_armed = false
        end
    end
end

--- BLIND SELECT HOOK ---
local _orig_update_blind_select = Game.update_blind_select

Game.update_blind_select = function(self, dt)
    local was_complete = G.STATE_COMPLETE
    _orig_update_blind_select(self, dt)
    if was_complete or not G.STATE_COMPLETE then return end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay   = 0.9,
        func    = function()
            local bt = G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_tags
            if not bt then return true end

            local function tag_name(key)
                return (key and G.P_TAGS and G.P_TAGS[key] and G.P_TAGS[key].name) or '?'
            end

            attention_text({
                text   = 'Small: ' .. tag_name(bt.Small),
                scale  = 0.45, hold = 3.5,
                align  = 'cm', major = G.ROOM_ATTACH,
                offset = {x = 0, y = 3}, colour = G.C.GREEN,
            })
            attention_text({
                text   = 'Big: ' .. tag_name(bt.Big),
                scale  = 0.45, hold = 3.5,
                align  = 'cm', major = G.ROOM_ATTACH,
                offset = {x = 0, y = 2}, colour = G.C.ORANGE,
            })

            hunt_armed = false

            if hunting then
                if has_required_tags() then
                    hunting = false
                    hunt_notify('Required tags found!', G.C.GREEN)
                else
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay   = 0.4,
                        func    = function()
                            if hunting and not hunt_armed then
                                arm_r_hold()
                            end
                            return true
                        end
                    }))
                end
            end

            return true
        end
    }))
end
