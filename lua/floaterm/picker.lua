local Picker = {}
local hide_open = require("floaterm.utils").hide_open
local builtin = require("fzf-lua.previewer.builtin")

--- Custom previewer class for terminal buffers in fzf-lua
--- Extends the base previewer to handle terminal buffer previews
-- Inherit from "base" instead of "buffer_or_file"
local MyPreviewer = builtin.base:extend()

--- Creates a new instance of the custom previewer
--- Initializes the previewer with the provided options and fzf window
---@param o table
---@param opts table
---@param fzf_win table
---@return table
MyPreviewer.new = function(self, o, opts, fzf_win)
    MyPreviewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, MyPreviewer)
    return self
end

--- Populates the preview buffer with the selected terminal buffer
--- Extracts the buffer number from the entry string and sets it as preview
 MyPreviewer.populate_preview_buf = function(self, entry_str)
    local buf = string.match(entry_str, ":(%d+)")

    if buf then
        self.listed_buffers[buf] = true
        self:set_preview_buf(tonumber(buf))
    end
end

--- Generates window options for the preview window
--- Disables line wrapping and line numbers for better terminal display
 ---@return table
MyPreviewer.gen_winopts = function(self)
    local new_winopts = {
        wrap = false,
        number = false,
    }
    return vim.tbl_extend("force", self.winopts, new_winopts)
end

--- Creates a list of terminal items from the current state
--- Sorts terminals by last used time for better user experience
---@param state table
---@return table
Picker.create_term_items = function(state)
    local items = {}
    for _, v in pairs(state.terminals) do
        local bufnr = v.buf
        local name = vim.fn.getbufvar(bufnr, "term_title")
        table.insert(items, {
            buf = bufnr,
            name = name,
            text = string.format("%d %s", bufnr, name),
            id = v.id,
        })
    end

    table.sort(items, function(a, b)
        return vim.fn.getbufinfo(a.buf)[1].lastused
            > vim.fn.getbufinfo(b.buf)[1].lastused
    end)

    return items
end

--- Shows the fzf-lua picker for terminal selection
--- Displays terminals with preview and allows selection with Enter
--- Hides any open terminal before showing the picker
---@param state table
Picker.fzflua_picker = function(state)
    local fzf_lua = require("fzf-lua")
    hide_open()

    local display = {}

    for _, v in pairs(state.terminals) do
        local bufnr = v.buf
        local name = vim.fn.getbufvar(bufnr, "term_title")
        local title = string.format("%d:%d %s", v.id, bufnr, name)
        table.insert(display, title)
    end

    fzf_lua.fzf_exec(display, {
        prompt = "Select Terminal❯ ",
        previewer = MyPreviewer,
        actions = {
            ["default"] = function(selected)
                if selected and #selected > 0 then
                    -- Extract ID from the selected entry
                    local id = tonumber(string.match(selected[1], "(%d+):"))
                    if id then
                        state.index = id
                        local terminal = state.terminals[id]
                        terminal:open()
                    end
                end
            end,
            ["ctrl-n"] = function(_) end,
        },
    })
end

--- Shows the builtin vim.ui.select picker for terminal selection
--- Provides a simpler fallback when fzf-lua is not available
--- Formats terminal items with ID and name for easy identification
---@param state table
Picker.builtin_picker = function(state)
    local items = Picker.create_term_items(state)
    vim.ui.select(items, {
        prompt = "Select Terminal",
        format_item = function(item)
            return string.format("%-11d %s", item.id, item.name)
        end,
    }, function(item, _)
        if item ~= nil then
            hide_open()
            state.index = item.id
            state.terminals[item.id]:open()
        end
    end)
end
return Picker
