_addon.name     = 'ctimers'
_addon.author   = 'ainais'
_addon.version  = '0.0.1'
_addon.commands = {'ctimers', 'ct'}

chars = require('chat.chars')
require('logger')
require('tables')
require('sets')
require('lists')

config = require('config')

do
    local now  = os.time()
    local h, m = math.modf(os.difftime(now, os.time(os.date('!*t', now))) / 3600)

    tz = '%+.4d':format(100 * h + 60 * m)
    tz_sep = '%+.2d:%.2d':format(h, 60 * m)
end

constants = {
    ['year']         = '%Y',
    ['y']            = '%Y',
    ['year_short']   = '%y',
    ['month']        = '%m',
    ['m']            = '%m',
    ['month_short']  = '%b',
    ['month_long']   = '%B',
    ['day']          = '%d',
    ['d']            = '%d',
    ['day_short']    = '%a',
    ['day_long']     = '%A',
    ['hour']         = '%H',
    ['h']            = '%H',
    ['hour24']       = '%H',
    ['hour12']       = '%I',
    ['minute']       = '%M',
    ['min']          = '%M',
    ['second']       = '%S',
    ['s']            = '%S',
    ['sec']          = '%S',
    ['ampm']         = '%p',
    ['timezone']     = tz,
    ['tz']           = tz,
    ['timezone_sep'] = tz_sep,
    ['tz_sep']       = tz_sep,
    ['time']         = '%H:%M:%S',
    ['date']         = '%Y-%m-%d',
    ['datetime']     = '%Y:%m:%d %H:%M:%S',
    ['iso8601']      = '%Y-%m-%dT%H:%M:%S' .. tz_sep,
    ['rfc2822']      = '%a, %d %b %Y %H:%M:%S ' .. tz,
    ['rfc822']       = '%a, %d %b %y %H:%M:%S ' .. tz,
    ['rfc1036']      = '%a, %d %b %y %H:%M:%S ' .. tz,
    ['rfc1123']      = '%a, %d %b %Y %H:%M:%S ' .. tz,
    ['rfc3339']      = '%Y-%m-%dT%H:%M:%S' .. tz_sep,
}

lead_bytes = S{0x1E, 0x1F, 0xF7, 0xEF, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x7F}
newline_pattern = '[' .. string.char(0x07, 0x0A) .. ']'

local timers = T{}

local last_update = 0

defaults = {}
defaults.color  = 201
defaults.format = '[${time}]'
defaults.tickrate = 1

settings = config.load(defaults)

function make_timestamp(format)
    return os.date((format:gsub('%${([%l%d_]+)}', constants)))
end

windower.register_event('postrender', function(new,old)
	local current_time = os.time()
	if(current_time - last_update < settings.tickrate) then
		return
	end
	last_update = current_time

	for name,timer in pairs(timers) do
		if ( timer <= current_time ) then
			log(name .. " alarm")
			timers[name] = nil
		else

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
	    if(timers[name]) then
		error('Timer with name "'..name..'" already exists')
	    else
	      timers[name] = new_time
	      log('Added timer ' .. name)
	    end
        end

    elseif cmd == 'del' then
        if not args[1] then
            error('Please specify')
        elseif args[1] == 'help' then
            log('Deletes a timer.')
            log('Usage: del <name>')
        else
	    --delete a timer
	    name = args[1]
	    if(timers[name]) then
	    	timers[name] = nil
		log('Deleted timer '..name)
	    else
		error('no timer named '..name)
	    end
        end

    elseif cmd == 'save' then
        settings:save('all')
    else
	--//ctimers add NAME H M S
	--//ctimers del NAME
        log('//ct [<command>] help -- shows the help text.')
        log('//ct add <name> <hour> <minute> <second> -- adds a timer')
        log('//ct del <name> -- deletes a timer')
    end
end)
