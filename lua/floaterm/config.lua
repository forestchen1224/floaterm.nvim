local M = {}

--- Default configuration options for Floaterm
--- These settings control the appearance and behavior of floating terminals
M.opts = {
    width = 0.9,        -- Terminal width as a fraction of screen width (0.1-0.99)
    height = 0.9,       -- Terminal height as a fraction of screen height (0.1-0.99)
    style = "minimal",  -- Window style: "minimal" for no borders or extra UI elements
    border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    autoclose = false,  -- Whether to automatically close terminal when job exits
    picker = "fzf-lua", -- Terminal picker to use: "fzf-lua" or "builtin"
}
return M
