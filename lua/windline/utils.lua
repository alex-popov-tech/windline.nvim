local M = {}

local mode_map = {
    ['n'] = { 'NORMAL', 'Normal' },
    ['no'] = { 'O-PENDING', 'Visual' },
    ['nov'] = { 'O-PENDING', 'Visual' },
    ['noV'] = { 'O-PENDING', 'Visual' },
    ['no'] = { 'O-PENDING', 'Visual' },
    ['nt'] = { 'T-NORMAL', 'Normal' },
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
    ['Rvc'] = { 'V-REPLACE', 'Replace' },
    ['Rvx'] = { 'V-REPLACE', 'Replace' },
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
        return { mode_code, 'Normal' }
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


local rgb2cterm = not vim.go.termguicolors and require('windline.cterm_utils').rgb2cterm

M.highlight = function(group, color)
    if rgb2cterm then
        color.ctermfg = color.guifg and rgb2cterm(color.guifg)
        color.ctermbg = color.guibg and rgb2cterm(color.guibg)
        color.cterm = color.gui and color.gui
    end
    local options = {}
    for k, v in pairs(color) do
        table.insert(options, string.format("%s=%s", k, v))
    end
    vim.api.nvim_command(string.format([[highlight  %s %s]], group, table.concat(options, " ")))
end

M.get_hl_name = function(c1, c2, style)
    local name = string.format('WL%s_%s', c1 or '', c2 or '')
    if style == 'bold' then
        name = name .. 'b'
    end
    return name
end

-- use it on setup
M.hl = function(tbl, colors, is_runtime)
    local name = M.get_hl_name(tbl[1], tbl[2], tbl[3])
    if WindLine.hl_data[name] then
        return name
    end
    colors = colors or WindLine.state.colors
    local fg = colors[tbl[1]]
    local bg = colors[tbl[2]]
    if fg == nil then
        print('WL' .. (tbl[1] or '') .. ' color is not defined ')
    end
    if bg == nil then
        print('WL' .. (tbl[2] or '') .. ' color is not defined ')
    end

    if is_runtime then
        M.highlight(name, {guibg = bg, guifg = fg, gui = tbl[3]})
    end

    WindLine.hl_data[name] = {
        name = name,
        gui = tbl[3],
        guifg = fg,
        guibg = bg,
    }
    return name
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

M.update_check = function(check, message)
    if check then
        vim.notify('WindLine Update: ' .. message)
    end
end

M.find_divider_index = function(status_line)
    for index, comp in pairs(status_line) do
        local text = comp.text(
            vim.api.nvim_get_current_buf(),
            vim.api.nvim_get_current_win(),
            100
        )
        if type(text) == 'string' then
            if text == '%=' then
                return index
            end
        elseif type(text) == 'table' then
            for _, value in ipairs(text) do
                if value[1] == '%=' then
                    return index
                end
            end
        end
    end
end

M.buf_get_var = function(bufnr, key)
    local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, key)
    if ok then
        return value
    end
    return nil
end

return M
