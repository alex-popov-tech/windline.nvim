local M = {}

local mode_map = {
    ['n'] = { 'NORMAL', 'Normal' },
    ['no'] = { 'O-PENDING', 'Visual' },
    ['nov'] = { 'O-PENDING', 'Visual' },
    ['noV'] = { 'O-PENDING', 'Visual' },
    ['no'] = { 'O-PENDING', 'Visual' },
    ['niI'] = { 'NORMAL', 'Normal' },
    ['niR'] = { 'NORMAL', 'Normal' },
    ['niV'] = { 'NORMAL', 'Normal' },
    ['v'] = { 'VISUAL', 'Visual' },
    ['V'] = { 'V-LINE', 'Visual' },
    [''] = { 'V-BLOCK', 'Visual' },
    ['s'] = { 'SELECT', 'Visual' },
    ['S'] = { 'S-LINE', 'Visual' },
    [''] = { 'S-BLOCK', 'Visual' },
    ['i'] = { 'INSERT', 'Insert' },
    ['ic'] = { 'INSERT', 'Insert' },
    ['ix'] = { 'INSERT', 'Insert' },
    ['R'] = { 'REPLACE', 'Replace' },
    ['Rc'] = { 'REPLACE', 'Replace' },
    ['Rv'] = { 'V-REPLACE', 'Normal' },
    ['Rx'] = { 'REPLACE', 'Normal' },
    ['c'] = { 'COMMAND', 'Command' },
    ['cv'] = { 'EX', 'Command' },
    ['ce'] = { 'EX', 'Command' },
    ['r'] = { 'REPLACE', 'Replace' },
    ['rm'] = { 'MORE', 'Normal' },
    ['r?'] = { 'CONFIRM', 'Normal' },
    ['!'] = { 'SHELL', 'Normal' },
    ['t'] = { 'TERMINAL', 'Command' },
}

M.mode = function()
    local mode_code = vim.api.nvim_get_mode().mode
    if mode_map[mode_code] == nil then
        return mode_code
    end
    return mode_map[mode_code]
end

M.change_mode_name = function(new_mode)
    mode_map = new_mode
end

M.is_in_table = function(tbl, val)
    if tbl == nil then
        return false
    end
    for _, value in pairs(tbl) do
        if val == value then
            return true
        end
    end
    return false
end

M.hl_text = function(text, highlight)
    if text == nil then
        text = ''
    end
    return string.format('%%#%s#%s', highlight, text)
end

M.highlight = function(group, color)
    local gui = color.gui and 'gui=' .. color.gui or 'gui=NONE'
    local fg = color.guifg and 'guifg=' .. color.guifg or 'guifg=NONE'
    local bg = color.guibg and 'guibg=' .. color.guibg or 'guibg=NONE'
    local sp = color.guisp and 'guisp=' .. color.guisp or ''
    vim.api.nvim_command(string.format('highlight %s %s %s %s %s', group, gui, fg, bg, sp))
end

M.hl = function(guifg, guibg, gui, name)
    if _G.WindLine.hl_data == nil then
        _G.WindLine.hl_data = {}
    end
    local hl_data = _G.WindLine.hl_data
    local hl = {
        guifg = guifg,
        guibg = guibg,
        gui = gui,
    }
    if gui == 'bold' then
        name = name .. 'b'
    end
    hl.name = name
    for _, value in pairs(hl_data) do
        if hl.name == value.name then
            return value.name
        end
    end
    table.insert(hl_data, hl)
    return hl.name
end

M.hl_clear = function()
    _G.WindLine.hl_data = {}
end

M.hl_create = function()
    local hl_data = _G.WindLine.hl_data
    for _, value in pairs(hl_data) do
        M.highlight(value.name, {
            guifg = value.guifg,
            guibg = value.guibg,
            gui = value.gui,
        })
    end
end

M.get_unique_bufname = function(bufnr)
    local bufname = vim.fn.bufname(bufnr)
    local all_bufers = vim.tbl_filter(function(buffer)
        return buffer.listed == 1 and buffer.name ~= bufname
    end, vim.fn.getbufinfo())
    local all_name = vim.tbl_map(function(buffer)
        return string.reverse(buffer.name)
    end, all_bufers)
    local tmp_name = string.reverse(bufname)
    local position = 1
    if #all_name > 1 then
        for _, other_name in pairs(all_name) do
            for i = 1, #tmp_name do
                if tmp_name:sub(i, i) ~= other_name:sub(i, i) then
                    if i > position then
                        position = i
                    end
                    break
                end
            end
        end
    end
    while position <= #tmp_name do
        if tmp_name:sub(position, position) == '/' then
            position = position - 1
            break
        end
        position = position + 1
    end
    return string.reverse(string.sub(tmp_name, 1, position))
end

_G.WindLine.cache_actions = _G.WindLine.cache_actions or {}

local cache_actions = _G.WindLine.cache_actions

--- It will help reduce call function too many time on buffer. it save data on
--- buffer and only update when event happen
---@param auto_event string event when buffer value change
---@param buf_variable_name string buf_variable_name then
---@param action function action to do on buffer
M.cache_on_buffer = function(auto_event, buf_variable_name, action)
    return function(bufnr, winnr)
        local id = buf_variable_name .. bufnr
        local cache_action = cache_actions[id]
        if cache_action == nil then
            cache_action = {
                id = id,
                name = buf_variable_name,
                bufnr = bufnr,
                winnr = winnr,
                action = action,
            }
            vim.api.nvim_exec(
                string.format(
                    [[
                    augroup WL%s
                        au!
                        au %s * call v:lua.WindLine.cache_buffer_cb('%s')
                    augroup END
                    ]],
                    cache_action.id,
                    auto_event,
                    cache_action.id
                ),
                false
            )
            cache_actions[cache_action.id] = cache_action
        end
        local value = vim.b[buf_variable_name]
        if value then
             return value
        end
        value = action(bufnr, winnr)
        vim.b[buf_variable_name] = value
        return value
    end
end

M.cache_buffer_cb = function(identifer)
    local action = _G.WindLine.cache_actions[identifer]
    if action then
        print('call action' .. identifer)
       local value = action.action(action.bufnr, action.winnr)
       vim.b[action.name] = value
    end
end

_G.WindLine.cache_buffer_cb = M.cache_buffer_cb
return M
