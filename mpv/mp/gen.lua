function Pandoc(doc)
    local files = {}

    for _, blk in ipairs(doc.blocks) do
        if blk.tag == 'DefinitionList' then
            for _, v in ipairs(blk.content) do
                for _, fn in ipairs(v[1]:filter(function(el) return el.tag == 'Code' end)) do
                    fn = fn.text
                    local mod = 'mp'
                    if not fn:match('^mp%.') then
                        local t = {}
                        for comp in fn:gmatch('[^%.]+') do
                            table.insert(t, comp)
                        end
                        if #t > 1 then
                            mod = t[1]
                        end
                    end

                    local file = files[mod]
                    if not file then
                        local f, err = io.open(mod .. '.lua', 'w')
                        if err then
                            error(err)
                        end
                        f:write('--- generated from https://github.com/mpv-player/mpv/blob/master/DOCS/man/lua.rst\n')
                        f:write(mod == 'mp'
                            and '--- @meta mp\n\nmp = {}\nmp.msg = require "mp.msg"\n\n'
                            or '--- @meta mp.' .. mod .. '\n\nlocal ' .. mod .. ' = {}\n\n')
                        files[mod] = f
                        file = f
                    end

                    local doc = pandoc.Pandoc(v[2][1]):walk {
                        Link = function(el)
                            if #el.target == 0 then
                                el.target = pandoc.utils.stringify(el.content):gsub('%s', '-'):lower()
                                el.target = 'https://mpv.io/manual/stable/#' .. el.target
                            elseif el.target:match('^#') then
                                el.target = 'https://mpv.io/manual/stable/' .. el.target
                            end
                            return el
                        end,
                        CodeBlock = function(el)
                            local lang = el.text:match('\n') and '' or 'text'
                            return pandoc.RawBlock('markdown', '```' .. lang .. '\n' .. el.text .. '\n```')
                        end,
                        DefinitionList = function(el)
                            local items = {}
                            for _, item in ipairs(el.content) do
                                local inlines = item[1]:clone()
                                inlines:insert(pandoc.Str(':'))
                                inlines:insert(pandoc.Space())
                                local blocks = pandoc.List()
                                for i, blks in ipairs(item[2]) do
                                    for j, blk in ipairs(blks) do
                                        if i == 1 and j == 1 and blk.tag == 'Para' then
                                            inlines:extend(blk.content)
                                        else
                                            blocks:insert(blk)
                                        end
                                    end
                                end
                                blocks:insert(1, pandoc.Para(inlines))
                                table.insert(items, pandoc.Blocks(blocks))
                            end
                            return pandoc.BulletList(items)
                        end,
                        BlockQuote = function(el)
                            return el.content
                        end,
                        Div = function(el)
                            local inlines = el.content[1].content:clone()
                            inlines:insert(pandoc.Str(':'))
                            inlines:insert(pandoc.Space())
                            inlines:extend(el.content[2].content)
                            return pandoc.Para(inlines)
                        end
                    }
                    doc = pandoc.write(doc, 'commonmark', { columns = 80 })

                    for line in doc:gmatch('([^\n]*)\n?') do
                        file:write('---')
                        if #line > 0 then
                            file:write(' ')
                            file:write(line)
                        end
                        file:write('\n')
                    end
                    local m = fn:match('%[.+%]')
                    if m then
                        for opt_param in m:gmatch('[%w_]+') do
                            file:write('---@param ' .. opt_param .. '?\n')
                        end
                    end
                    fn = fn:gsub('[%[%]]', ''):gsub('%|%w+', ''):gsub('%s*,%s*', ', ')
                    file:write('function ' .. fn .. ' end\n\n')
                end
            end
        end
    end

    for mod, file in pairs(files) do
        file:write('return ' .. mod .. '\n')
        ok, _, code = file:close()
        if not ok then
            error('exit code ' .. code)
        end
    end

    return pandoc.Pandoc({})
end
