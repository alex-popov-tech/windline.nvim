local M = {}
local fn = vim.fn
local helper = require('windline.helpers')
local utils = require('windline.utils')

M.divider = '%='
M.line_col = [[ %3l:%-2c ]]
M.progress = [[%3p%%]]
M.full_file_name = '%f'

local function get_buf_name(modify, shorten)
    return function(bufnr)
        local bufname = vim.fn.bufname(bufnr)
        bufname = vim.fn.fnamemodify(bufname, modify)
        if shorten then
            return vim.fn.pathshorten(bufname)
        end
        return bufname
    end
end

M.file_name = function(default, modify)
    default = default or '[No Name]'
    modify = modify or 'name'
    local fnc_name = get_buf_name(':t')
    if modify == 'unique' then
        fnc_name = utils.get_unique_bufname
    elseif modify == 'full' then
        fnc_name = get_buf_name('%:p', true)
    end

    return utils.cache_on_buffer('BufEnter', 'WL_filename', function(bufnr)
        print('get new name')
        local name = fnc_name(bufnr)
        if name == '' then
            name = default
        end
        return name .. ' '
    end)
end

M.file_type = function(opt)
    opt = opt or {}
    local default = opt.default or '  '
    return utils.cache_on_buffer('BufEnter', 'WL_filetype', function(bufnr)
        local file_name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
        local file_ext = vim.fn.fnamemodify(file_name, ':e')
        local icon = opt.icon and helper.get_icon(file_name, file_ext) or ''
        local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
        if filetype == '' then
            return default
        end
        if icon ~= '' then
            return icon .. ' ' .. filetype
        end
        return filetype
    end)
end

M.file_size = function()
    return function()
        local file = vim.fn.expand('%:p')
        if string.len(file) == 0 then
            return ''
        end
        local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
        local index = 1

        local fsize = fn.getfsize(file)

        while fsize > 1024 and index < 7 do
            fsize = fsize / 1024
            index = index + 1
        end

        return string.format('%.2f', fsize) .. suffix[index]
    end
end

local format_icons = {
    unix = '', -- e712
    dos = '', -- e70f
    mac = '', -- e711
}

M.file_format = function(opt)
    opt = opt or {}
    if opt.icon then
        return function()
            return format_icons[vim.bo.fileformat] or vim.bo.fileformat
        end
    end
    return function()
        return vim.bo.fileformat
    end
end

function M.file_encoding()
    return function()
        local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc
        return enc:upper()
    end
end

M.file_icon = function(default)
    default = default or ''
    return function(bufnr)
        local file_name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
        local file_ext = vim.fn.fnamemodify(file_name, ':e')
        return helper.get_icon(file_name, file_ext) or default
    end
end

M.file_modified = function(icon)
    if icon then
        return function()
            if vim.bo.modified or vim.bo.modifiable == false then
                return icon
            end
        end
    end
    return '%m'
end

return M
