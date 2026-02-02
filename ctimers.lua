--[[
CTimers - Custom Timer Addon for Windower (FFXI)

Author: ainais
Version: 0.1.0

Description:
    A flexible timer system for tracking HNM spawns and other timed events in FFXI.
    Supports multiple alarms per timer with preset configurations for common use cases.

Architecture:
    - timer_table: Array of active timers, each containing:
      - name: Display name for the timer
      - alarms: Sorted array of {time = unix_timestamp} alarm objects
      - text_object: Display object from timers module

    - Timers are automatically sorted by next alarm time for visual clarity
    - The prerender event checks for expired alarms every tickrate seconds
    - When an alarm expires, it's removed; when all alarms expire, the timer is deleted
    - Timer state persists to settings.xml between addon loads

Commands:
    //ct add <name> <H:M:S> [preset]          - Add timer at specific clock time
    //ct add <name> <hours> <minutes> <seconds> [preset] - Add timer with duration
    //ct del <name>                            - Delete a timer
    //ct list                                  - List all active timers
    //ct show                                  - Toggle timer visibility

Presets:
    hnm      - 7 alarms at 10-minute intervals (for HNM spawns)
    wyrm     - 96 alarms at 30-minute intervals (for Wyrm spawns)
    tonberry - 130 alarms at 26-second intervals (for Tonberry adds)
--]]

_addon.name = 'ctimers'
_addon.author = 'ainais'
_addon.version = '0.1.0'
_addon.commands = { 'ctimers', 'ct' }

require('logger')
require('tables')
require('sets')
require('lists')

config = require('config')
texts = require('texts')

require('timers')

-- regex to match a valid date
local time_pattern = "^%s*(%d%d?):([0-5]%d):([0-5]%d)%s*$"
local last_update = 0

defaults = {}
defaults.timers = {}
defaults.tickrate = 1 -- time in seconds
defaults.sound = "long_pop.wav"
defaults.visible = 1
defaults.text = {}
defaults.text.position = { x = 50, y = 300 }
defaults.text.font = { family = "Arial", size = 10, color = {} }
defaults.text.font.color = { alpha = 255, red = 200, green = 200, blue = 200 }
defaults.text.bg = { alpha = 128, red = 30, green = 30, blue = 30 }

settings = config.load(defaults)

-- Constants
local SECONDS_PER_DAY = 86400
local TIMER_VERTICAL_SPACING = 2

-- Timer presets for different HNM types
local TIMER_PRESETS = {
    hnm = { count = 7, delta = 600 },      -- 7 alarms, 10-minute intervals
    wyrm = { count = 96, delta = 1800 },   -- 96 alarms, 30-minute intervals
    tonberry = { count = 130, delta = 26 } -- 130 alarms, 26-second intervals
}

local timer_table = {}

-- Format remaining time as a human-readable string
local function format_remaining_time(remaining_seconds)
    local hours = math.floor(remaining_seconds / 3600)
    local minutes = math.floor((remaining_seconds % 3600) / 60)
    local seconds = remaining_seconds % 60

    return string.format("%s%s%s",
        hours > 0 and string.format("%dhr ", hours) or "",
        minutes > 0 and string.format("%dmin ", minutes) or "",
        string.format("%dsec", seconds))
end

-- Build a table of timer alarms based on a base time and optional preset
local function build_timer_alarms(base_time, preset_name)
    local preset = TIMER_PRESETS[preset_name] or { count = 1, delta = 0 }
    local alarm_table = {}

    for i = 1, preset.count do
        table.insert(alarm_table, {
            time = base_time + ((i - 1) * preset.delta)
        })
    end

    table.sort(alarm_table, function(a, b) return a.time < b.time end)
    return alarm_table
end

-- function that takes a time string as input and returns the next Unix timestamp for that time
function get_next_timestamp(timeString)
    -- parse the input time string into hour, minute, and second components
    local hour, minute, second = string.match(timeString, "(%d+):(%d+):(%d+)")
    local now = os.date("*t")

    now.hour = tonumber(hour)
    now.min = tonumber(minute)
    now.sec = tonumber(second)

    local timestamp = os.time(now)

    -- if the resulting timestamp is less than the current time, add 24 hours to it
    if timestamp < os.time() then timestamp = timestamp + SECONDS_PER_DAY end

    return timestamp
end

function create_timer(name, alarms)
    local o = timers.new(settings.text)
    local y_offset = (settings.text.font.size + TIMER_VERTICAL_SPACING) * #timer_table
    timers.move(o, settings.text.position.x, settings.text.position.y + y_offset)
    table.insert(timer_table, { name = name, alarms = alarms, text_object = o })
    log('Added timer ' .. name)
    save_timers();
    sort_timers();
end

function load_timers()
    if not settings.timers then return end
    for _, timer in pairs(settings.timers) do
        local o = timers.new(settings.text)
        local y_offset = (settings.text.font.size + TIMER_VERTICAL_SPACING) * #timer_table
        timers.move(o, settings.text.position.x,
            settings.text.position.y + y_offset)
        table.insert(timer_table, {
            name = timer.name,
            alarms = timer.alarms,
            text_object = o
        })
    end
    sort_timers()
end

function save_timers()
    local settings_timers = {}
    for _, timer in pairs(timer_table) do
        table.insert(settings_timers, { name = timer.name, alarms = timer.alarms })
    end
    settings.timers = settings_timers
    settings:save('all')
end

function sort_timers()
    table.sort(timer_table, function(a, b)
        local _, time_a = next(a.alarms)
        local _, time_b = next(b.alarms)
        -- Handle nil cases (empty alarm lists)
        if not time_a then return false end
        if not time_b then return true end
        return time_a.time < time_b.time
    end)
    for i, timer in ipairs(timer_table) do
        local y_offset = (settings.text.font.size + TIMER_VERTICAL_SPACING) * i
        timers.move(timer.text_object, settings.text.position.x,
            settings.text.position.y + y_offset)
    end
end

function alert_timer(i, j)
    local timer = timer_table[i]
    windower.play_sound(windower.addon_path .. 'sounds/' .. settings.sound)
    log(timer.name .. " alarm")
    table.remove(timer.alarms, j)
    if (#timer.alarms < 1) then
        timers.destroy(timer.text_object)
        table.remove(timer_table, i)
        for k, t in ipairs(timer_table) do
            local y_offset = (settings.text.font.size + TIMER_VERTICAL_SPACING) * k
            timers.move(t.text_object, settings.text.position.x,
                settings.text.position.y + y_offset)
        end
    end
end

function toggle_timers() settings.visible = not settings.visible end

load_timers()

function list_timers()
    if not timer_table then return end
    for _, timer in pairs(timer_table) do
        table.sort(timer.alarms, function(a, b) return a.time < b.time end)
        for _, alarm in pairs(timer.alarms) do
            local remaining_time = alarm.time - os.time()
            local time_string = format_remaining_time(remaining_time)
            local hms = os.date("%H:%M:%S", alarm.time)
            log(timer.name .. ' in ' .. time_string .. ' [' .. hms .. ']')
        end
    end
end

windower.register_event('prerender', function(new, old)
    if not timer_table then return end
    local current_time = os.time()

    -- only check if timers have gone off if enough time as elapsed
    -- no sense in checking on every single postrender
    if (current_time - last_update < settings.tickrate) then return end
    last_update = current_time

    -- Use reverse iteration to safely modify table during iteration
    for i = #timer_table, 1, -1 do
        local timer = timer_table[i]
        local j, next_alarm = next(timer.alarms)
        if next_alarm then
            if next_alarm.time <= current_time then
                alert_timer(i, j)
                save_timers()
            else
                timers.update_timer(timer.text_object, timer.name, next_alarm.time,
                    settings.visible)
            end
        end
    end
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or 'help'
    local args = { ... }
    if cmd == 'add' then
        if not args[1] then
            log('Error: Please specify timer name')
            return
        elseif args[1] == 'help' then
            log('Adds a timer.')
            log('Usage: add <name> <H:M:S> [preset]')
            log('   or: add <name> <hours> <minutes> <seconds> [preset]')
            log('Presets: hnm, wyrm, tonberry')
            return
        end

        local name = args[1]
        local base_time
        local preset

        -- Check if second argument matches time pattern (H:M:S)
        if args[2] and string.match(args[2], time_pattern) then
            base_time = get_next_timestamp(args[2])
            preset = args[3]
        else
            -- Validate we have enough arguments for H M S format
            if #args < 4 then
                log('Error: Please specify name hours minutes seconds')
                return
            end

            -- Parse and validate numeric inputs
            local hours = tonumber(args[2])
            local minutes = tonumber(args[3])
            local seconds = tonumber(args[4])

            if not hours or not minutes or not seconds then
                log('Error: Hours, minutes, and seconds must be valid numbers')
                return
            end

            if hours < 0 or minutes < 0 or seconds < 0 then
                log('Error: Time values cannot be negative')
                return
            end

            local total_seconds = hours * 3600 + minutes * 60 + seconds
            base_time = os.time() + total_seconds
            preset = args[5]
        end

        local alarm_table = build_timer_alarms(base_time, preset)
        create_timer(name, alarm_table)
    elseif cmd == 'del' then
        if not args[1] then
            log('Error: Please specify timer name')
            return
        elseif args[1] == 'help' then
            log('Deletes a timer.')
            log('Usage: del <name>')
        else
            -- delete a timer
            local name = args[1]:lower()
            local found = false
            -- Use reverse iteration to safely modify table during iteration
            for i = #timer_table, 1, -1 do
                local timer = timer_table[i]
                if timer.name:lower() == name then
                    timers.destroy(timer.text_object)
                    table.remove(timer_table, i)
                    log('Deleted timer ' .. args[1])
                    found = true
                    break
                end
            end
            if not found then
                log('Error: Timer "' .. args[1] .. '" not found')
            else
                sort_timers()
                save_timers()
            end
        end
    elseif cmd == 'save' then
        save_timers()
    elseif cmd == 'list' then
        list_timers()
    elseif cmd == 'show' then
        toggle_timers()
    else
        -- //ctimers add NAME H M S
        -- //ctimers del NAME
        log('//ct [<command>] help -- shows the help text.')
        log('//ct add <name> <hour> <minute> <second> -- adds a timer')
        log('//ct del <name> -- deletes a timer')
        log('//ct list -- shows a list of all timers')
    end
end)
