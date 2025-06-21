local picker = require("floaterm.picker")
local hide_open = require("floaterm.utils").hide_open
local M = {
    _initialized = false,
    opts = {},
    state = {
        index = nil,
        terminals = {},
        counter = 1,
    },
}

local terminal = {}

M.opts = {
    width = 0.9,
    height = 0.9,
    style = "minimal", -- No borders or extra UI elements
    border = "rounded",
    autoclose = false,
    -- picker = "fzf-lua",
    picker = "fzf-lua",
}

function terminal:new(opts, cmd)
    return setmetatable({
        buf = nil,
        win = nil,
        id = nil,
        opts = opts,
        cmd = cmd,
    }, { __index = self })
end

function terminal:open()
    local width = math.floor(vim.o.columns * self.opts.width)
    local height = math.floor(vim.o.lines * self.opts.height)

    -- Calculate the position to center the window
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    -- Create a buffer
    if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
        self.buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
    end

    -- Define window configuration
    local win_config = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = self.opts.style,
        border = self.opts.border,
    }

    -- Create the floating window
    self.win = vim.api.nvim_open_win(self.buf, true, win_config)
    -- These are needed for resizing (maybe the window only tells the app
    -- when using this after if window was created earlier?)
    vim.api.nvim_win_set_width(self.win, width)
    vim.api.nvim_win_set_height(self.win, height)

    if vim.bo[self.buf].buftype ~= "terminal" then
        vim.api.nvim_buf_call(self.buf, function()
            vim.fn.jobstart(self.cmd or vim.o.shell, {
                on_exit = function()
                    if self.opts.autoclose then
                        if vim.api.nvim_win_is_valid(self.win) then
                            vim.api.nvim_win_close(self.win, false)
                        end
                        vim.api.nvim_buf_delete(self.buf, { force = true })
                    end
                end,
                term = true,
            })
        end)
        vim.cmd.startinsert()
    end
end

function terminal:toggle()
    print(self.win)
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_hide(self.win)
    else
        self:open()
    end
end

function terminal:hide()
    if vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_hide(self.win)
    end
end

function terminal:show()
    if not vim.api.nvim_win_is_valid(self.win) then
        self:open()
    end
end

local function on_close(ev)
    local term = M.state.terminals[M.state.index]
    if not term or term.buf ~= ev.buf then
        return
    end
    M.state.index = nil
    for k, _ in pairs(M.state.terminals) do
        if k ~= term.id then
            M.state.index = k
            break
        end
    end
    M.state.terminals[term.id] = nil
end

local function on_buf_enter()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype == "terminal" then
        local term = M.state.terminals[M.state.index]
        if term ~= nil then
            vim.fn.timer_start(50, function()
                vim.cmd.startinsert()
            end)
        end
    end
end

function M.open(opts, cmd)
    hide_open(M.state)
    local term = M.new(opts, cmd)
    term:open()
end

function M.new(opts, cmd)
    opts = vim.tbl_deep_extend("force", M.opts, opts or {})
    local term = terminal:new(opts, cmd)
    if not opts.hide then
        term.id = M.state.counter
        M.state.counter = M.state.counter + 1
        M.state.terminals[term.id] = term
        M.state.index = term.id
    end
    return term
end

function M.next()
    if not M.state.index then
        return
    end
    hide_open(M.state)
    local next = false
    for k, v in pairs(M.state.terminals) do
        if next then
            M.state.index = k
            v:show()
            return
        end
        if k == M.state.index then
            next = true
        end
    end
    M.state.terminals[M.state.index]:show()
end

function M.prev()
    if not M.state.index then
        return
    end
    hide_open(M.state)
    local index = -1
    for k, v in pairs(M.state.terminals) do
        if k == M.state.index then
            if index >= 0 then
                M.state.index = index
                M.state.terminals[index]:show()
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
    -- print(vim.inspect(M.state))
    if not M.state.index then
        return
    end
    local term = M.state.terminals[M.state.index]
    if term ~= nil then
        term:toggle()
    else
        M.open(M.opts, nil)
    end
end

function M.resize(delta)
    if not M.state.index then
        return
    end
    local term = M.state.terminals[M.state.index]
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
    hide_open(M.state)
    term:toggle()
end

function M.pick()
    if not M._initialized then
        M.setup({})
        M._initialized = true
    end

    if M.opts.picker == "fzf-lua" then
        local has_fzf_lua, _ = pcall(require, "fzf-lua")
        if not has_fzf_lua then
            vim.notify("fzf-lua not installed")
        else
            picker.fzflua_picker(M.state)
        end
    elseif M.opts.picker == "builtin" then
        picker.builtin_picker(M.state)
    else
        local picker_options = {
            "fzf-lua",
            "builtin",
            -- ["snacker"] = true,
        }
        vim.notify(
            string.format(
                "%s is not in the [%s] options",
                M.opts.picker,
                table.concat(picker_options, ",")
            ),
            vim.log.levels.ERROR
        )
    end
end

function M.count()
    return #M.state.terminals
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
