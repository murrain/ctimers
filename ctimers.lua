_addon.name = 'ctimers'
_addon.author = 'ainais'
_addon.version = '0.0.2'
_addon.commands = {'ctimers', 'ct'}

require('logger')
require('tables')
require('sets')
require('lists')

config = require('config')
texts = require('texts')

require('timers')
--[[
timer: {name,time,text_object}
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
defaults.text.font = {family = "Arial", size = 14, color = {}}
defaults.text.font.color = {alpha = 255, red = 200, green = 200, blue = 200}
defaults.text.bg = {alpha = 128, red = 30, green = 30, blue = 30}

settings = config.load(defaults)

local timers = settings.timers

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

-- will neeed to switch to pre-render for ui elements
windower.register_event('postrender', function(new, old)
    local current_time = os.time()

    -- only check if timers have gone off if enough time as elapsed
    -- no sense in checking on every single postrender
    if (current_time - last_update < settings.tickrate) then return end
    last_update = current_time

    for i, timer in pairs(timers) do
        if (timer.time <= current_time) then
            windower.play_sound(windower.addon_path .. 'sounds/' ..
                                    settings.sound)
            log(timer.name .. " alarm")
            timers[i] = nil
            settings.timers = timers
            settings:save('all')
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
			if(not args[3]) then args[3] = 1 end
			timers_count = tonumber(args[3])
			for i=1,timers_count do
				new_time = new_time + (60 * i)
				table.insert(timers,{name=name,time=new_time})
				log('Added timer ' .. name)
			end
			settings.timers = timers
			settings:save('all')
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
			table.insert(timers,{name=name,time=new_time})
			log('Added timer ' .. name)
			settings.timers = timers
			settings:save('all')
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
			for i,timer in pairs(timers) do
				if timers.name == name then timers[i] = nil end
				log('Deleted timer ' .. name)
			end
        end

    elseif cmd == 'save' then
        settings.timers = timers
        settings:save('all')
    elseif cmd == 'list' then
        for i, timer in pairs(timers) do
            local current_time = os.time()
            local remaining_time = timer.time - current_time
            local hours = math.floor(remaining_time / 3600)
            local minutes = math.floor((remaining_time % 3600) / 60)
            local seconds = remaining_time % 60
            local time_string = string.format("%s%s%s", hours > 0 and
                                                  string.format("%dhr ", hours) or
                                                  "", minutes > 0 and
                                                  string.format("%dmin ",
                                                                minutes) or "",
                                              string.format("%dsec", seconds))
            log(timer.name .. ' in ' .. time_string)
        end
    else
        -- //ctimers add NAME H M S
        -- //ctimers del NAME
        log('//ct [<command>] help -- shows the help text.')
        log('//ct add <name> <hour> <minute> <second> -- adds a timer')
        log('//ct del <name> -- deletes a timer')
        log('//ct list -- shows a list of all timers')
    end
end)
