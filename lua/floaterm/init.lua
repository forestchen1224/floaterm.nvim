local config = require("floaterm.config")
local picker = require("floaterm.picker")
local terminal = require("floaterm.terminal")

local M = {}
--- Tracks all active terminals and the currently selected terminal
---@class State
---@field id string|nil ID of the latest pickable terminal
---@field terminals table<string, Terminal> Table of terminals indexed by ID
local state = {
    id = nil,
    terminals = {},
}

local function hide_open()
    local term = state.terminals[state.id]
    if term ~= nil then
        term:hide()
    end
end

--- Creates a new terminal instance with the specified options and command
--- The terminal is registered in the state unless the 'hide' option is set
---@param opts Opts|nil
---@param id string|nil
---@return Terminal
function M.new(id, opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, config.opts)
    local term = terminal:new(id, opts)
    if term.id == nil then
        term.id = config.IDGenerator()
    end
    state.terminals[term.id] = term
    return term
end

---create a new terminal and open it
---@param id string|nil
---@param opts Opts|nil
function M.open(id, opts)
    local term = M.new(id, opts)
    hide_open()
    if term.opts.pick then
        state.id = term.id
    end
    term:open()
end

--- Toggles the visibility of the current terminal
--- If no terminal exists, opens a new one with default options
---@param id string|nil
---@param opts Opts|nil
function M.toggle(id, opts)
    id = id or state.id
    local term = state.terminals[id]
    if term == nil then
        term = M.new(id, opts)
    end
    if term.opts.pick then
        state.id = term.id
    end
    term:toggle()
end

function M.close(id)
    id = id or state.id
    local term = state.terminals[id]
    if term then
        if not term.opts.pick then
            state.terminals[term.id] = nil
        else
            state.id = nil
            for k, _ in pairs(state.terminals) do
                if k ~= term.id and term.opts.pick then
                    state.id = k
                    break
                end
            end
            state.terminals[term.id] = nil
        end
        term:close()
    end
end

--- Resizes the current terminal by the specified delta
--- Adjusts both width and height, clamping values between 0.10 and 0.99
--- Automatically reopens the terminal to apply the new size
--- TODO: changed
---@param delta number
function M.resize(delta)
    if not state.id then
        return
    end
    local term = state.terminals[state.id]
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

--- Opens a picker interface to select from available terminals
--- Uses the configured picker (fzf-lua or builtin) to display terminal list
--- Shows an error if the configured picker is not available
function M.pick()
    local picker_options = {
        ["fzf-lua"] = picker.fzflua_picker,
        ["builtin"] = picker.builtin_picker,
    }
    M.picker = picker_options[config.picker]
    if M.picker then
        hide_open()
        M.picker(state)
    else
        vim.schedule(function()
            vim.notify(
                string.format(
                    "%s is not in the [%s] options",
                    config.picker,
                    table.concat(vim.tbl_keys(picker_options), ",")
                ),
                vim.log.levels.ERROR
            )
        end)
    end
end

--- Handles terminal close events
--- Removes the closed terminal from state and updates the current index
---@param ev table
local function on_close(ev)
    local term = state.terminals[state.id]
    if not term or term.buf ~= ev.buf then
        return
    end
    state.id = nil
    for k, _ in pairs(state.terminals) do
        if k ~= term.id and term.pick then
            state.id = k
            break
        end
    end
    state.terminals[term.id] = nil
end

--- Sets up autocommands for terminal management and merges user options
---@param opts FloatermConfig|nil
function M.setup(opts)
    config:setup(opts)

    for _, term in ipairs(config.start_cmds) do
        M.new(term.id, term.opts)
    end
    vim.api.nvim_create_autocmd("TermClose", {
        callback = on_close,
    })
end

return M
