local picker = require("floaterm.picker")
local terminal = require("floaterm.terminal")
local hide_open = require("floaterm.utils").hide_open

local M = {}

local config = require("floaterm.config")
local state = require("floaterm.state")

--- Opens a new floating terminal with the specified options and command
--- If a terminal is already open, it will be hidden before opening the new one
---@param opts table|nil
---@param cmd string|nil Command to run in the terminal (defaults to shell)
function M.open(opts, cmd)
    hide_open()
    local term = M.new(opts, cmd)
    term:open()
end

function M.find(key)
    if key and type(key) == "string" then
        local term = state.hidden_terminals[key]
        if term then
            return term
        else
            return nil
        end
    else
        if state.index and state.terminals[state.index] then
            return state.terminals[state.index]
        else
            return nil
        end
    end
end
--- Creates a new terminal instance with the specified options and command
--- The terminal is registered in the state unless the 'hide' option is set
---@param opts table|nil
---@param cmd string|nil
---@return table
function M.new(opts, cmd)
    opts = vim.tbl_deep_extend("force", config, opts or {})
    local term = terminal:new(opts, cmd)
    -- if the terminal is hidden, the cmd should be the key to find it
    if  opts.hide and cmd then
        term.id = cmd
        state.hidden_terminals[cmd] = term
    else
        term.id = state.counter
        state.counter = state.counter + 1
        state.terminals[term.id] = term
        state.index = term.id
    end
    return term
end

--- Switches to the next terminal in the list
--- If already at the last terminal, wraps around to the current terminal
--- Hides any currently open terminal before showing the next one
function M.next()
    if not state.index then
        return
    end
    hide_open()
    local next = false
    for k, v in pairs(state.terminals) do
        if next then
            state.index = k
            v:show()
            return
        end
        if k == state.index then
            next = true
        end
    end
    state.terminals[state.index]:show()
end

--- Switches to the previous terminal in the list
--- If already at the first terminal, shows the current terminal
--- Hides any currently open terminal before showing the previous one
function M.prev()
    if not state.index then
        return
    end
    hide_open()
    local index = -1
    for k, v in pairs(state.terminals) do
        if k == state.index then
            if index >= 0 then
                state.index = index
                state.terminals[index]:show()
                return
            else
                v:show()
                return
            end
        end
        index = k
    end
end

--- Toggles the visibility of the current terminal
--- If no terminal exists, opens a new one with default options
function M.toggle(key)
    -- print(vim.inspect(state))
    local term = M.find(key)
    if term ~= nil then
        term:toggle()
        return
    -- end
    -- if not state.index then
    --     return
    -- end
    -- term = state.terminals[state.index]
    -- if term ~= nil then
    --     term:toggle()
    else
        M.open(config, nil)
    end
end

--- Resizes the current terminal by the specified delta
--- Adjusts both width and height, clamping values between 0.10 and 0.99
--- Automatically reopens the terminal to apply the new size
---@param delta number
function M.resize(delta)
    if not state.index then
        return
    end
    local term = state.terminals[state.index]
    term.config.width = term.config.width + delta
    if term.config.width > 0.99 then
        term.config.width = 0.99
    elseif term.config.width < 0.10 then
        term.config.width = 0.10
    end
    term.config.height = term.config.height + delta
    if term.config.height > 0.99 then
        term.config.height = 0.99
    elseif term.config.height < 0.10 then
        term.config.height = 0.10
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

--- Returns the total number of active terminals
---@return number
function M.count()
    return #state.terminals
end

--- Handles terminal close events
--- Removes the closed terminal from state and updates the current index
---@param ev table
local function on_close(ev)
    local term = state.terminals[state.index]
    if not term or term.buf ~= ev.buf then
        return
    end
    state.index = nil
    for k, _ in pairs(state.terminals) do
        if k ~= term.id then
            state.index = k
            break
        end
    end
    state.terminals[term.id] = nil
end

--- Handles buffer enter events for terminal buffers
--- Automatically enters insert mode when entering a terminal buffer
local function on_buf_enter()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype == "terminal" then
        local term = state.terminals[state.index]
        if term ~= nil then
            vim.fn.timer_start(50, function()
                vim.cmd.startinsert()
            end)
        end
    end
end

--- Initializes the Floaterm plugin with the provided configuration
--- Sets up autocommands for terminal management and merges user options
---@param opts table|nil
function M.setup(opts)
    config:setup(opts)

    for _, term in ipairs(config.start_cmds) do
        M.new({hide = term.hide}, term.cmd)
    end
    vim.api.nvim_create_autocmd("TermClose", {
        callback = on_close,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = on_buf_enter,
    })
end

return M
