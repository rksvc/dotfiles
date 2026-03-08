local utils = require('mp.utils')

local function format_item(title, value)
    local item = { title = title, keep_open = true }
    if type(value) == 'table' then
        item.items = {}
        for i, v in ipairs(value) do
            table.insert(item.items, format_item('#' .. (i - 1), v))
        end
        if #item.items == 0 then
            for k, v in pairs(value) do
                table.insert(item.items, format_item(k, v))
            end
        end
        item.title = item.title .. ' [' .. #item.items .. ']'
    else
        item.hint = utils.format_json(value)
        if type(value) ~= 'string' then
            value = item.hint
        end
        item.value = { 'set', 'clipboard/text', value }
    end
    return item
end

local logs = {}
mp.enable_messages('warn')
mp.register_event('log-message', function(event)
    table.insert(logs, event)
end)

mp.register_script_message('show', function()
    local menu = {
        title = 'Debug',
        items = {}
    }
    for title, property in pairs({ Options = 'options', Properties = 'property-list' }) do
        local items = {}
        for _, name in ipairs(mp.get_property_native(property)) do
            local value = mp.get_property_native(name)
            table.insert(items, format_item(name, value))
        end
        table.insert(menu.items, {
            title = title .. ' [' .. #items .. ']',
            items = items
        })
    end

    local items = {}
    for _, log in ipairs(logs) do
        table.insert(items, {
            title = '[' .. log.prefix .. '] ' .. log.text,
            hint = log.level,
            value = { 'set', 'clipboard/text', log.text },
            keep_open = true
        })
    end
    table.insert(menu.items, {
        title = 'Logs [' .. #items .. ']',
        items = items
    })
    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu))
end)
