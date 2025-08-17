-- Example configuration for floaterm.nvim
-- Place this in your Neovim configuration (init.lua or equivalent)

local floaterm = require("floaterm")

-- Setup with custom configuration
floaterm.setup({
    picker = "fzf-lua", -- Use fzf-lua for picker (requires fzf-lua plugin)

    -- Default options for all terminals
    opts = {
        width = 0.8, -- 80% of screen width
        height = 0.8, -- 80% of screen height
        style = "minimal", -- Clean minimal style
        border = "rounded", -- Rounded borders
        autoclose = false, -- Keep terminal open when command exits
        cmd = nil, -- Use default shell
        pick = true, -- Show in picker by default
    },

    -- Auto-start terminals (optional)
    start_cmds = {
        -- Main terminal that's always available
        {
            id = "main",
            opts = {
                cmd = vim.o.shell,
                pick = true,
            },
        },
        -- Git terminal (hidden from picker)
        {
            id = "git",
            opts = {
                cmd = "lazygit",
                pick = false, -- Don't show in picker
                width = 0.9,
                height = 0.9,
            },
        },
    },
})

-- Keymaps
local keymap = vim.keymap.set
local opts = { silent = true }

-- Basic terminal operations
keymap({ "n", "t" }, "<leader>tf", function()
    floaterm.new()
end, vim.tbl_extend("force", opts, { desc = "New floating terminal" }))
keymap({ "n", "t" }, "<leader>tt", function()
    floaterm.toggle()
end, vim.tbl_extend("force", opts, { desc = "Toggle floating terminal" }))
keymap({ "n", "t" }, "<leader>tc", function()
    floaterm.close()
end, vim.tbl_extend("force", opts, { desc = "Close floating terminal" }))

-- Terminal navigation
keymap({ "n", "t" }, "<leader>tl", function()
    floaterm.pick()
end, vim.tbl_extend("force", opts, { desc = "List/pick terminals" }))

-- Terminal resizing
keymap({ "n", "t" }, "<leader>t+", function()
    floaterm.resize(0.05)
end, vim.tbl_extend("force", opts, { desc = "Increase terminal size" }))
keymap({ "n", "t" }, "<leader>t-", function()
    floaterm.resize(-0.05)
end, vim.tbl_extend("force", opts, { desc = "Decrease terminal size" }))

-- Specialized terminals
keymap("n", "<leader>tg", function()
    floaterm.new("lazygit", { cmd = "lazygit", width = 0.9, height = 0.9 })
end, vim.tbl_extend("force", opts, { desc = "Open lazygit" }))

keymap("n", "<leader>th", function()
    floaterm.new("htop", { cmd = "htop", width = 0.7, height = 0.8 })
end, vim.tbl_extend("force", opts, { desc = "Open htop" }))

keymap("n", "<leader>tp", function()
    floaterm.new("python", { cmd = "python", width = 0.6, height = 0.8 })
end, vim.tbl_extend("force", opts, { desc = "Open Python REPL" }))

-- File manager that opens at current file location
keymap("n", "<leader>tr", function()
    local file = vim.fn.expand("%:p")
    local cmd = "ranger"
    if file and file ~= "" then
        cmd = cmd .. " --selectfile=" .. vim.fn.shellescape(file)
    end
    floaterm.new("ranger", { cmd = cmd, width = 0.8, height = 0.8 })
end, vim.tbl_extend("force", opts, { desc = "Open ranger at current file" }))

-- Quick access to specific terminals
keymap("n", "<leader>tm", function()
    floaterm.open("main")
end, vim.tbl_extend("force", opts, { desc = "Open main terminal" }))
keymap("n", "<leader>tG", function()
    floaterm.toggle("git")
end, vim.tbl_extend("force", opts, { desc = "Toggle git terminal" }))

-- Terminal mode escape
keymap("t", "<C-\\><C-n>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Example of creating a terminal with custom border
keymap("n", "<leader>tb", function()
    floaterm.new("custom", {
        border = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
        width = 0.6,
        height = 0.6,
    })
end, vim.tbl_extend("force", opts, { desc = "Terminal with custom border" }))

-- Print terminal count
keymap("n", "<leader>tn", function()
    local count = floaterm.count()
    vim.notify("Active terminals: " .. count)
end, vim.tbl_extend("force", opts, { desc = "Show terminal count" }))

