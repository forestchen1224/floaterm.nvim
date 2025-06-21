local M = {}


M.create_term_items = function(state)
	local items = {}
	for _, v in pairs(state.terminals) do
		local bufnr = v.buf
		local name = vim.fn.getbufvar(bufnr, "term_title")
		table.insert(items, { buf = bufnr, name = name, text = string.format("%d %s", bufnr, name), id = v.id })
	end

	table.sort(items, function(a, b)
		return vim.fn.getbufinfo(a.buf)[1].lastused > vim.fn.getbufinfo(b.buf)[1].lastused
	end)

	return items
end

M.fzflua_picker = function(state)
	local fzf_lua = require("fzf-lua")
    require("floaterm.utils").hide_open(state)

	local display = {}

	for _, v in pairs(state.terminals) do
		local bufnr = v.buf
		local name = vim.fn.getbufvar(bufnr, "term_title")
		local title = string.format("%d:%d %s", v.id, bufnr, name)
		table.insert(display, title)
	end

	local builtin = require("fzf-lua.previewer.builtin")

	-- Inherit from "base" instead of "buffer_or_file"
	local MyPreviewer = builtin.base:extend()

	function MyPreviewer:new(o, opts, fzf_win)
		MyPreviewer.super.new(self, o, opts, fzf_win)
		setmetatable(self, MyPreviewer)
		return self
	end

	function MyPreviewer:populate_preview_buf(entry_str)
		local buf = string.match(entry_str, ":(%d+)")

		if buf then
			self.listed_buffers[buf] = true
			self:set_preview_buf(tonumber(buf))
		end
	end

	-- -- Disable line numbering and word wrap
	function MyPreviewer:gen_winopts()
		local new_winopts = {
			wrap = false,
			number = false,
		}
		return vim.tbl_extend("force", self.winopts, new_winopts)
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
		},
	})
end
return M
