local config = require("floaterm.config")
local picker = require("floaterm.picker")
local terminal = require("floaterm.terminal")

local M = {}
--- Tracks all active terminals and the currently selected terminal
---@class State
---@field id string|nil ID of the currently active terminal
---@field terminals table<string, any> Table of all active terminals indexed by ID
local state = {
    id = nil,
    terminals = {},
}

function M.hide_open()
    if not state.id then
        return
    end
    local term = state.terminals[state.id]
    if term ~= nil then
        term:hide()
    end
end

--- Opens a new floating terminal with the specified options and command
--- If a terminal is already open, it will be hidden before opening the new one
---@param opts table|nil
---@param cmd string|nil Command to run in the terminal (defaults to shell)
function M.open(cmd, opts)
    M.hide_open()
    local term = M.new(cmd, opts)
    term:open()
end

--find hidden terminal if key, else return the previous opened terminal
---@param id string|nil
---@return Terminal|nil
function M.find(id)
    id = id or state.id
    return state.terminals[id]
end
--- Creates a new terminal instance with the specified options and command
--- The terminal is registered in the state unless the 'hide' option is set
---@param opts TerminalOpts|nil
---@param cmd string|nil
---@return table
function M.new(cmd, opts)
    opts = vim.tbl_deep_extend("force", opts or {}, config)
    local term = terminal:new(cmd, opts)
    -- if the terminal is hidden, the cmd should be the key to find it
    term.id = opts.id or config.IDGenerator()
    if term.pick then
        state.id = term.id
    end
    state.terminals[term.id] = term
    return term
end

function M.close(id)
    local term = M.find(id)
    if term then
        if not term.pick then
            state.terminals[term.id] = nil
        else
            state.id = nil
            for k, _ in pairs(state.terminals) do
                if k ~= term.id and term.pick then
                    state.id = k
                    break
                end
            end
            state.terminals[term.id] = nil
        end
        term:close()
    end
end

--- Toggles the visibility of the current terminal
--- If no terminal exists, opens a new one with default options
---@param id string|nil
function M.toggle(id)
    local term = M.find(id)
    if term then
        term:toggle()
    else
        M.open()
    end
end

--- Resizes the current terminal by the specified delta
--- Adjusts both width and height, clamping values between 0.10 and 0.99
--- Automatically reopens the terminal to apply the new size
---@param delta number
function M.resize(delta)
    if not state.id then
        return
    end
    local term = state.terminals[state.id]
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
    M.hide_open()
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
        M.hide_open()
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
    local count = vim.tbl_count(vim.tbl_filter(function(term)
        return term.pick
    end, state.terminals))
    return count
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

--- Initializes the Floaterm plugin with the provided configuration
--- and sets up user commands
local function setup_user_commands()
    vim.api.nvim_create_user_command("Floaterm", function(opts)
        local args = opts.args or ""
        local cmd_parts = vim.split(args, " ", { plain = true })
        local subcmd = cmd_parts[1] or "toggle"
        local arg1 = cmd_parts[2]
        local arg2 = cmd_parts[3]

        if subcmd == "new" then
            if arg1 and arg1 == "hidden" and arg2 then
                M.new(args, { pick = true })
            else
                M.new()
            end
        elseif subcmd == "toggle" then
            M.toggle(arg1)
        elseif subcmd == "kill" then
            M.close(arg1)
        else
            M.toggle(arg1)
        end
    end, {
        nargs = "*",
        desc = "Floaterm terminal management",
        complete = function(arg_lead, cmd_line, _)
            local args =
                vim.split(cmd_line, " ", { plain = true, trimempty = true })
            print(vim.inspect(args))
            -- Remove the command name
            table.remove(args, 1)
            print(vim.inspect(args))

            -- Get current argument position (accounting for partial input)
            local arg_count = #args
            print(arg_count)
            if arg_lead == "" and cmd_line:sub(-1) == " " then
                arg_count = arg_count + 1
            end
            print(arg_count)
            if arg_count == 1 then
                local options = { "new", "toggle", "kill" }
                return vim.tbl_filter(function(option)
                    return vim.startswith(option, arg_lead)
                end, options)
            elseif arg_count == 2 then
                local arg1 = args[1]
                if arg1 == "toggle" or arg1 == "kill" then
                    local options = vim.tbl_keys(state.terminals)
                    return vim.tbl_filter(function(option)
                        return vim.startswith(option, arg_lead)
                    end, options)
                elseif arg1 == "new" then
                    local options = { "hidden", "nohidden" }
                    return vim.tbl_filter(function(option)
                        return vim.startswith(option, arg_lead)
                    end, options)
                else
                    return {}
                end
            end

            -- For other arguments, return empty (no completion)
            return {}
        end,
    })
end
--- Sets up autocommands for terminal management and merges user options
---@param opts FloatermConfig|nil
function M.setup(opts)
    config:setup(opts)

    for _, term in ipairs(config.start_cmds) do
        M.new(term.cmd, { pick = term.pick, id = term.id })
        -- M.new({ pick = true }, term.cmd)
        -- hide_open()
    end
    setup_user_commands()
    vim.api.nvim_create_autocmd("TermClose", {
        callback = on_close,
    })
end

return M
