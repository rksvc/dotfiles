local pip, osd_width

mp.register_script_message('toggle-pip', function()
    if mp.get_property_bool('fullscreen') then
        return
    end
    pip = not pip
    mp.msg.info('pip:', pip)
    if pip then
        osd_width = mp.get_property('osd-width')
        mp.set_property('geometry', '30%-0-0')
        mp.set_property_bool('ontop', true)
    else
        mp.set_property('geometry', osd_width .. '+50%+50%')
        mp.set_property_bool('ontop', false)
    end
    mp.commandv('script-message-to', 'uosc', 'set', 'pip', pip and 'yes' or 'no')
end)

mp.commandv('script-message-to', 'uosc', 'set', 'pip', 'no')
mp.register_script_message('set', function(_, value)
    mp.commandv('script-message-to', 'uosc', 'set', 'pip', value)
    mp.commandv('script-message-to', mp.get_script_name(), 'toggle-pip')
end)
