local picker = require("floaterm.picker")
local terminal = require("floaterm.terminal")
local hide_open = require("floaterm.utils").hide_open

local M = { }

M.opts = require("floaterm.config").opts
local state = require("floaterm.state")

function M.open(opts, cmd)
    hide_open()
    local term = M.new(opts, cmd)
    term:open()
end

function M.new(opts, cmd)
    opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    local term = terminal:new(opts, cmd)
    if not opts.hide then
        term.id = state.counter
        state.counter = state.counter + 1
        state.terminals[term.id] = term
        state.index = term.id
    end
    return term
end

function M.next()
    if not state.index then
        return
    end
    hide_open()
    local next = false
    for k, v in pairs(state.terminals) do
        if next then
            state.index = k
            v:show()
            return
        end
        if k == state.index then
            next = true
        end
    end
    state.terminals[state.index]:show()
end

function M.prev()
    if not state.index then
        return
    end
    hide_open()
    local index = -1
    for k, v in pairs(state.terminals) do
        if k == state.index then
            if index >= 0 then
                state.index = index
                state.terminals[index]:show()
                return
            else
                v:show()
                return
            end
        end
        index = k
    end
end

function M.toggle()
    -- print(vim.inspect(state))
    if not state.index then
        return
    end
    local term = state.terminals[state.index]
    if term ~= nil then
        term:toggle()
    else
        M.open(M.opts, nil)
    end
end

function M.resize(delta)
    if not state.index then
        return
    end
    local term = state.terminals[state.index]
    term.opts.width = term.opts.width + delta
    if term.opts.width > 0.99 then
        term.opts.width = 0.99
    elseif term.opts.width < 0.10 then
        term.opts.width = 0.10
    end
    term.opts.height = term.opts.height + delta
    if term.opts.height > 0.99 then
        term.opts.height = 0.99
    elseif term.opts.height < 0.10 then
        term.opts.height = 0.10
    end
    hide_open()
    term:toggle()
end

function M.pick()
    local picker_options = {
        ["fzf-lua"] = picker.fzflua_picker,
        ["builtin"] = picker.builtin_picker,
    }
    M.picker = picker_options[M.opts.picker]
    if M.picker then
        M.picker(state)
    else
        vim.schedule(function()
            vim.notify(
                string.format(
                    "%s is not in the [%s] options",
                    M.opts.picker,
                    table.concat(vim.tbl_keys(picker_options), ",")
                ),
                vim.log.levels.ERROR
            )
        end)
    end
end

function M.count()
    return #state.terminals
end

local function on_close(ev)
    local term = state.terminals[state.index]
    if not term or term.buf ~= ev.buf then
        return
    end
    state.index = nil
    for k, _ in pairs(state.terminals) do
        if k ~= term.id then
            state.index = k
            break
        end
    end
    state.terminals[term.id] = nil
end

local function on_buf_enter()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype == "terminal" then
        local term = state.terminals[state.index]
        if term ~= nil then
            vim.fn.timer_start(50, function()
                vim.cmd.startinsert()
            end)
        end
    end
end

function M.setup(opts)
    M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

    vim.api.nvim_create_autocmd("TermClose", {
        callback = on_close,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = on_buf_enter,
    })
end

return M
