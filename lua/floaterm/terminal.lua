local M = {}
--- Creates a new terminal instance with the specified options and command
--- Returns a terminal object with methods for opening, toggling, hiding, and showing
 function M:new(opts, cmd)
    return setmetatable({
        buf = nil,
        win = nil,
        id = nil,
        opts = opts,
        cmd = cmd,
    }, { __index = self })
end

--- Opens the terminal in a floating window
--- Creates a new buffer if needed and starts the terminal job
--- Centers the window on screen based on configured width/height ratios
function M:open()
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
    -- vim.api.nvim_set_option_value('colorcolumn', '', {win = self.win})

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
    end
    vim.cmd.startinsert()
end

--- Toggles the terminal window visibility
--- If window is open, hides it; if closed, opens it
function M:toggle()
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_hide(self.win)
    else
        self:open()
    end
end

--- Hides the terminal window if it's currently visible
--- Does not destroy the buffer, allowing the terminal to be shown again
function M:hide()
    if vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_hide(self.win)
    end
end

--- Shows the terminal window
--- If the window is not valid, opens a new one
function M:show()
    if not vim.api.nvim_win_is_valid(self.win) then
        self:open()
    end
end
return M
