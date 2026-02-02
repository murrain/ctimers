--[[
Timers Display Module

This module provides the visual display layer for CTimers addon.
It manages the creation, updating, and rendering of timer text objects on screen.

Timer Object Structure:
    {
        font: string           - Font family name
        font_size: number      - Font size in points
        x, y: number          - Screen position coordinates
        display_text: object   - Windower texts object for rendering
    }

Functions:
    timers.new(settings)              - Create a new timer display object
    timers.destroy(obj)               - Destroy a timer display object
    timers.show(obj)                  - Show a timer on screen
    timers.hide(obj)                  - Hide a timer from screen
    timers.move(obj, x, y)            - Move a timer to new coordinates
    timers.update_timer(obj, name, time, visible) - Update timer display with new data
--]]

-- Meta class
timers = {
    x_res = windower.get_windower_settings().ui_x_res,
    y_res = windower.get_windower_settings().ui_y_res
}

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

-- Base class method new

function timers.new(timer_settings)
    local o = {}
    o.font = timer_settings.font.family
    o.font_size = timer_settings.font.size
    timers.initialize(o)
    timers.move(o, timer_settings.position.x, timer_settings.position.y)
    return o
end

function timers.destroy(o)
    if not o then return end
    o.display_text:destroy()
end

function timers.initialize(o)
    o.display_text = texts.new('${name|(timer_name)}: ${time_string|(---)}', {
        pos = { x = 0, y = 0 },
        text = {
            size = o.font_size,
            font = o.font,
            stroke = { width = 2, alpha = 180, red = 50, green = 50, blue = 50 }
        },
        flags = { bold = true, draggable = false, italic = true },
        bg = { visible = false }
    })
end

function timers.show(o)
    if not o then return end
    o.display_text:show()
end

function timers.hide(o)
    if not o then return end
    o.display_text:hide()
end

function timers.move(o, x, y)
    if not o then return end
    o.x = x
    o.y = y
    o.display_text:pos(x, y)
end

function timers.update_timer(o, name, time, visible)
    if not o then return end

    local remaining_time = time - os.time()
    local time_string = format_remaining_time(remaining_time)

    o.display_text.name = name
    o.display_text.time_string = time_string

    if visible then
        timers.show(o)
    else
        timers.hide(o)
    end
end
