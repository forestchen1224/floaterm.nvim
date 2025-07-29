--- Global state management for Floaterm plugin
--- Tracks all active terminals and the currently selected terminal
---@class State
---@field id string|nil ID of the currently active terminal
---@field terminals table<string, any> Table of all active terminals indexed by ID
---@field hidden_terminals table<string, any> Table of hidden terminals
local M = {
    id = nil,
    terminals = {},
}

return M
