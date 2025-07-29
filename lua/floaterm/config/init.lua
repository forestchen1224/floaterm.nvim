---@alias Style "minimal"
---@alias Border "none"|"rounded"|"single"|"double"|"solid"|"shodow"
---@alias Picker "fzf-lua"|"snack"|"builtin"
--- Default configuration options for Floaterm
--- These settings control the appearance and behavior of floating terminals
---@class FloatermConfig
---@field width number
---@field height number
---@field style Style
---@field border Border
---@field autoclose boolean
---@field picker Picker
---@field start_cmds {hide: boolean, cmd: string}[]
local M = {
    width = 0.9, -- Terminal width as a fraction of screen width (0.1-0.99)
    height = 0.9, -- Terminal height as a fraction of screen height (0.1-0.99)
    style = "minimal", -- Window style: "minimal" for no borders or extra UI elements
    border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
    autoclose = false, -- Whether to automatically close terminal when job exits
    picker = "fzf-lua", -- Terminal picker to use: "fzf-lua" or "builtin"
    start_cmds = {
        -- {
        --     -- hide = false,
        --     -- cmd = "lazyit"
        -- },
    },
}

function M:setup(opts)
    local new_config = vim.tbl_deep_extend("force", M, opts)
    for k, v in pairs(new_config) do
        M[k] = v
    end
    M.IDGenerator = require("floaterm.config.id_generator")
end

return M
