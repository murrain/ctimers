-- Meta class
timers = {
    x_res = windower.get_windower_settings().ui_x_res,
    y_res = windower.get_windower_settings().ui_y_res
}

-- Base class method new

function timers.new(timer_settings)
    o = {}
    o.font = timer_settings.font
    o.font_size = timer_settings.font_size
    o.display_text = timer_settings.display_text
    timers.initialize(o)
    timers.move(o, timer_settings.pos.x, timer_settings.pos.y)
    return o
end

function timers.destroy(o)
    if not o then return end
    o.display_text:destroy()
end

function timers.initialize(o)
    o.display_text = texts.new('${name|(timer_name)}: ${time_string|(---)}', {
        pos = {x = 0, y = 0},
        text = {
            size = o.font_size,
            font = o.font,
            stroke = {width = 2, alpha = 180, red = 50, green = 50, blue = 50}
        },
        flags = {bold = true, draggable = false, italic = true},
        bg = {visible = false}
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
end

function timers.update_timer(o, name, time)
    if not o then return end

    local current_time = os.time()
    local remaining_time = time - current_time
    local hours = math.floor(remaining_time / 3600)
    local minutes = math.floor((remaining_time % 3600) / 60)
    local seconds = remaining_time % 60
    local time_string = string.format("%s%s%s", hours > 0 and
                                          string.format("%dhr ", hours) or "",
                                      minutes > 0 and
                                          string.format("%dmin ", minutes) or "",
                                      string.format("%dsec", seconds))

    o.name = name
    o.time_string = time_string
end
