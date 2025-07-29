---@class Terminal
---@field buf integer|nil
---@field win integer|nil
---@field id string |nil
---@field cmd string|nil
---@field jobid integer|nil
---@field opts table|nil
---@field pick boolean if the terminal is showed in the picker
local M = {}

---@class TerminalOpts
---@field id string|nil
---@field pick boolean|nil
---@field autoclose boolean|nil
-----@field

--- Creates a new terminal instance with the specified options and command
--- Returns a terminal object with methods for opening, toggling, hiding, and showing
---@param opts TerminalOpts
---@param cmd string|nil
---@return Terminal
function M:new(cmd, opts)
    local term = {
        buf = nil,
        win = nil,
        id = opts.id,
        jobid = nil,
        opts = opts,
        cmd = cmd,
        pick = opts.pick or (opts.pick == nil and true),
    }
    term.buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer

    if vim.bo[term.buf].buftype ~= "terminal" then
        vim.api.nvim_buf_call(term.buf, function()
            term.jobid = vim.fn.jobstart(term.cmd or vim.o.shell, {
                on_exit = function()
                    if term.opts.autoclose then
                        if vim.api.nvim_win_is_valid(term.win) then
                            vim.api.nvim_win_close(term.win, false)
                        end
                        vim.api.nvim_buf_delete(term.buf, { force = true })
                    end
                end,
                term = true,
            })
        end)
    end
    return setmetatable(term, { __index = self })
end

--- Opens the terminal in a floating window
--- Creates a new buffer if needed and starts the terminal job
--- Centers the window on screen based on configured width/height ratios
---@param self Terminal
function M:open()
    if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
        vim.notify(
            "buffer: " .. self.buf .. " is not valid",
            vim.log.levels.ERROR
        )
        return
    end

    local width = math.floor(vim.o.columns * self.opts.width)
    local height = math.floor(vim.o.lines * self.opts.height)

    -- Calculate the position to center the window
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)


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

    vim.cmd.startinsert()
end

--- Toggles the terminal window visibility
--- If window is open, hides it; if closed, opens it
---@param self Terminal
function M:toggle()
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_hide(self.win)
    else
        self:open()
    end
end

--- Hides the terminal window if it's currently visible
--- Does not destroy the buffer, allowing the terminal to be shown again
---@param self Terminal
function M:hide()
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_hide(self.win)
    end
end

--- Shows the terminal window
--- If the window is not valid, opens a new one
---@param self Terminal
function M:show()
    if not vim.api.nvim_win_is_valid(self.win) then
        self:open()
    end
end

---@param self Terminal
function M:close()
    if self.jobid then
        vim.fn.jobstop(self.jobid)
    end
end
return M
