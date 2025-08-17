---@alias Style "minimal"
---@alias Border "none"|"rounded"|"single"|"double"|"solid"|"shodow"
---@alias Picker "fzf-lua"|"snack"|"builtin"
---@class Opts
---@field width number|nil Terminal width as a fraction of screen width (0.1-0.99)
---@field height number|nil Terminal height as a fraction of screen height (0.1-0.99)
---@field style Style|nil Window style: "minimal" for no borders or extra UI elements
---@field border Border|nil Border style
---@field autoclose boolean|nil Whether to automatically close terminal when job exits
---@field cmd string|nil the command the terminal starts to run
---@field pick boolean|nil whether the terminal is picked by the picker

---@class TerminalOpts_new
---@field id string|nil
---@field opts Opts
--- Default configuration options for Floaterm
--- These settings control the appearance and behavior of floating terminals
---@class FloatermConfig
---@field picker Picker
---@field opts Opts
---@field start_cmds TerminalOpts_new[]
local M = {
    picker = "fzf-lua", -- Terminal picker to use: "fzf-lua" or "builtin"
    opts = {
        width = 0.9,
        height = 0.9,
        style = "minimal",
        border = "rounded",
        autoclose = false,
        cmd = nil,
        pick = true,
    },
    start_cmds = {
        -- {
        --     id = "lazygit",
        --     opts = {
        --         pick = false,
        --         cmd = "lazyit",
        --     },
        -- },
    },
}

---@param opts FloatermConfig|nil
function M:setup(opts)
    local new_config = vim.tbl_deep_extend("force", M, opts)
    for k, v in pairs(new_config) do
        M[k] = v
    end
    M.IDGenerator = require("floaterm.config.id_generator")
end

return M
