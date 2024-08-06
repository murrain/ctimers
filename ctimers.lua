_addon.name = 'ctimers'
_addon.author = 'ainais'
_addon.version = '0.1.0'
_addon.commands = {'ctimers', 'ct'}

require('logger')
require('tables')
require('sets')
require('lists')

config = require('config')
texts = require('texts')

require('timers')
--[[
timer: {name,{alarms},text_object}
--]]

-- regex to match a valid date
local time_pattern = "^%s*(%d%d?):([0-5]%d):([0-5]%d)%s*$"
local last_update = 0

defaults = {}
defaults.timers = {}
defaults.tickrate = 1 -- time in seconds
defaults.sound = "long_pop.wav"
defaults.visible = 1
defaults.text = {}
defaults.text.position = {x = 50, y = 300}
defaults.text.font = {family = "Arial", size = 10, color = {}}
defaults.text.font.color = {alpha = 255, red = 200, green = 200, blue = 200}
defaults.text.bg = {alpha = 128, red = 30, green = 30, blue = 30}

settings = config.load(defaults)

local timer_table = {}

function make_timestamp(format)
    return os.date((format:gsub('%${([%l%d_]+)}', constants)))
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
    if timestamp < os.time() then timestamp = timestamp + 24 * 60 * 60 end

    return timestamp
end

function create_timer(name, alarms)
    local o = timers.new(defaults.text)
    local y_offset = (defaults.text.font.size + 2) * #timer_table
    timers.move(o, defaults.text.position.x, defaults.text.position.y + y_offset)
    table.insert(timer_table, {name = name, alarms = alarms, text_object = o})
    log('Added timer ' .. name)
    save_timers();
    sort_timers();
end

function load_timers()
    if not settings.timers then return end
    for _, timer in pairs(settings.timers) do
        local o = timers.new(defaults.text)
        local y_offset = (defaults.text.font.size + 2) * #timer_table
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
        table.insert(settings_timers, {name = timer.name, alarms = timer.alarms})
    end
    settings.timers = settings_timers
    settings:save('all')
end

function sort_timers()
    table.sort(timer_table, function(a, b)
        local _, time_a = next(a.alarms)
        local _, time_b = next(b.alarms)
        return time_a.time < time_b.time
    end)
    for i, timer in ipairs(timer_table) do
        local y_offset = (defaults.text.font.size + 2) * i
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
            local y_offset = (defaults.text.font.size + 2) * k
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
            local current_time = os.time()
            local remaining_time = alarm.time - current_time
            local hours = math.floor(remaining_time / 3600)
            local minutes = math.floor((remaining_time % 3600) / 60)
            local seconds = remaining_time % 60
            local time_string = string.format("%s%s%s", hours > 0 and
                                                  string.format("%dhr ", hours) or
                                                  "", minutes > 0 and
                                                  string.format("%dmin ",
                                                                minutes) or "",
                                              string.format("%dsec", seconds))
	    local hms = os.date("%H:%M:%S",alarm.time)
            log(timer.name .. ' in ' .. time_string ..' ['.. hms ..']')
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

    for i, timer in pairs(timer_table) do
        local j, next_alarm = next(timer.alarms)
        if (next_alarm.time <= current_time) then
            alert_timer(i, j)
            save_timers()
        else
            timers.update_timer(timer.text_object, timer.name, next_alarm.time,
                                settings.visible)
        end
    end
end)

windower.register_event('addon command', function(cmd, ...)
    cmd = cmd and cmd:lower() or 'help'
    local args = {...}
    if cmd == 'add' then
        if args[1] == 'help' then
            log('Adds a timer.')
            log('Usage: add format [help|<format>]')
        elseif (string.match(args[2], time_pattern)) then
            local name = args[1]
            local new_time = get_next_timestamp(args[2])
	    local timers_count=1;
	    local timers_delta=600;
	    local timers_list = T{}
	    timers_list['hnm'] = {count = 7, delta=600}
	    timers_list['wyrm'] = {count = 96 ,delta=1800}
	    if (timers_list[args[3]] ~= nil ) then
		timers_count = timers_list[args[3]].count
		timers_delta = timers_list[args[3]].delta
	    end
            local create_timer_table = {}
            for i = 1, timers_count do
                table.insert(create_timer_table,
                             {time = new_time + ((i - 1) * 600)})
            end
            table.sort(create_timer_table,
                       function(a, b) return a.time < b.time end)
            create_timer(name, create_timer_table)
        elseif #args < 4 then
            error('Please specify name hours minutes seconds')
        else
            local current_time = os.time()
            local name = args[1]
            local hours = args[2]
            local minutes = args[3]
            local seconds = args[4]
            local total_seconds = hours * 3600 + minutes * 60 + seconds
            local new_time = current_time + total_seconds
			local create_timer_table = {}
			table.insert(create_timer_table, {time = new_time})
            create_timer(name, create_timer_table)
        end

    elseif cmd == 'del' then
        if not args[1] then
            error('Please specify')
        elseif args[1] == 'help' then
            log('Deletes a timer.')
            log('Usage: del <name>')
        else
            -- delete a timer
            name = args[1]
            for i, timer in pairs(timer_table) do
                if timer.name:lower() == name then
                    timers.destroy(timer.text_object)
                    table.remove(timer_table, i)
                    log('Deleted timer ' .. name)
                    sort_timers()
                end
            end
            save_timers()
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
