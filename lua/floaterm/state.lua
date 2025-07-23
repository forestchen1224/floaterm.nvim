--- Global state management for Floaterm plugin
--- Tracks all active terminals and the currently selected terminal
local M = {
    index = nil,        -- ID of the currently active terminal
    terminals = {},     -- Table of all active terminals indexed by ID
    counter = 1,        -- Next available terminal ID counter
}

return M
