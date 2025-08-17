local M = {}
local builtin = require("fzf-lua.previewer.builtin")

--- Custom previewer class for terminal buffers in fzf-lua
--- Extends the base previewer to handle terminal buffer previews
-- Inherit from "base" instead of "buffer_or_file"
local MyPreviewer = builtin.base:extend()

--- Creates a new instance of the custom previewer
--- Initializes the previewer with the provided options and fzf window
 function MyPreviewer:new(o, opts, fzf_win)
    MyPreviewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, MyPreviewer)
    return self
end

--- Populates the preview buffer with the selected terminal buffer
--- Extracts the buffer number from the entry string and sets it as preview
function MyPreviewer:populate_preview_buf(entry_str)
    local buf = string.match(entry_str, ":(%d+)")

    if buf then
        self.listed_buffers[buf] = true
        self:set_preview_buf(tonumber(buf))
    end
end

--- Generates window options for the preview window
--- Disables line wrapping and line numbers for better terminal display
 ---@return table
function MyPreviewer:gen_winopts()
    local new_winopts = {
        wrap = false,
        number = false,
    }
    return vim.tbl_extend("force", self.winopts, new_winopts)
end

function M.create_term_items(state)
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

---@param state State
 function M.fzflua_picker(state)
    local fzf_lua = require("fzf-lua")

    local display = {}
    local terminals = vim.tbl_filter(function (terminal)
         return terminal.opts.pick
    end, state.terminals)

    for _, v in pairs(terminals) do
        local bufnr = v.buf
        local name = vim.fn.getbufvar(bufnr, "term_title")
        local title = string.format("%s:%d %s", v.id, bufnr, name)
        table.insert(display, title)
    end

    fzf_lua.fzf_exec(display, {
        prompt = "Select Terminal❯ ",
        -- previewer = MyPreviewer,
        actions = {
            ["default"] = function(selected)
                -- print(vim.inspect(selected))
                if selected and #selected > 0 then
                    -- Extract ID from the selected entry
                    local id = string.match(selected[1], "(%w+):")
                    if id then
                        state.id = id
                        local terminal = state.terminals[id]
                        terminal:open()
                    end
                end
            end,
            ["ctrl-n"] = function(_) end,
        },
    })
end

 function M.builtin_picker(state)
    local items = M.create_term_items(state)
    vim.ui.select(items, {
        prompt = "Select Terminal",
        format_item = function(item)
            return string.format("%-11d %s", item.id, item.name)
        end,
    }, function(item, _)
        if item ~= nil then
            state.index = item.id
            state.terminals[item.id]:open()
        end
    end)
end
return M
