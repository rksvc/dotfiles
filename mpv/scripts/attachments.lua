local utils = require('mp.utils')
local script_name = mp.get_script_name()

mp.register_event('file-loaded', function(event)
    mp.del_property('user-data/' .. script_name)

    if event.error then
        return mp.msg.error(event.error)
    end
    local path, error = mp.get_property('path')
    if error then
        return mp.msg.error(error)
    elseif path:sub(- #'.mkv') ~= '.mkv' then
        return
    end
    mp.set_property_bool('user-data/' .. script_name .. '/is_mkv', true)

    local args = {
        'ffprobe',
        '-v',
        'error',
        '-select_streams',
        't',
        '-show_entries',
        'stream',
        '-of',
        'json',
        path,
    }
    local result, error = mp.command_native({
        name = 'subprocess',
        args = args,
        capture_stdout = true,
        capture_stderr = true,
    })
    if error then
        return mp.msg.error(error)
    end
    if result.status < 0 then
        if #result.error_string > 0 then
            return mp.msg.error(result.error_string)
        end
        local stderr = result.stderr:gsub('^%s*(.-)%s*$', '%1')
        return mp.msg.error(#stderr > 0 and stderr or 'unknown error')
    end

    local json, error = utils.parse_json(result.stdout)
    if error then
        return mp.msg.error('fail to parse json')
    end
    local attachments = json.streams
    mp.set_property_number('user-data/' .. script_name .. '/count', #attachments)
    for i, attachment in ipairs(attachments) do
        local prefix = 'user-data/' .. script_name .. '/' .. i
        mp.set_property(prefix .. '/name', attachment.tags.filename)
        mp.set_property(prefix .. '/mime_type', attachment.tags.mimetype)
    end
end)

mp.register_script_message('show-attachments', function()
    local count = mp.get_property_number('user-data/' .. script_name .. '/count', 0)
    local menu = {
        title = 'Matroska attachments',
        items = {}
    }
    for i = 1, count do
        local prefix = 'user-data/' .. script_name .. '/' .. i
        table.insert(menu.items, {
            title = mp.get_property_native(prefix .. '/name'),
            hint = mp.get_property_native(prefix .. '/mime_type'),
        })
    end
    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu))
end)
