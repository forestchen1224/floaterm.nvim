local picker = require("floaterm.picker")
local M = {
	_initialized = false,
	opts = {},
	counter = 1,
	index = nil,
	terminals = {},
}

local terminal = {}

local defaults = {
	width = 0.9,
	height = 0.9,
	style = "minimal", -- No borders or extra UI elements
	border = "rounded",
	autoclose = false,
}


function terminal:new(opts, cmd)
	return setmetatable({
		buf = nil,
		win = nil,
		id = nil,
		opts = opts,
        cmd = cmd
	}, { __index = self })
end

function terminal:open()

	local width = math.floor(vim.o.columns * self.opts.width)
	local height = math.floor(vim.o.lines * self.opts.height)

	-- Calculate the position to center the window
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Create a buffer
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
		self.buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
	end

	-- Define window configuration
	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = self.opts.style,
		border = self.opts.border,
	}

	-- Create the floating window
	self.win = vim.api.nvim_open_win(self.buf, true, win_config)
	-- These are needed for resizing (maybe the window only tells the app
	-- when using this after if window was created earlier?)
	vim.api.nvim_win_set_width(self.win, width)
	vim.api.nvim_win_set_height(self.win, height)

	if vim.bo[self.buf].buftype ~= "terminal" then
		vim.api.nvim_buf_call(self.buf, function()
			vim.fn.jobstart(self.cmd or vim.o.shell, {
				on_exit = function()
					if self.opts.autoclose then
						if vim.api.nvim_win_is_valid(self.win) then
							vim.api.nvim_win_close(self.win, false)
						end
						vim.api.nvim_buf_delete(self.buf, { force = true })
					end
				end,
				term = true,
			})
		end)
		vim.cmd.startinsert()
	end
end

function terminal:toggle()
	if self.win and  vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_hide(self.win)
	else
		self:open()
	end
end

function terminal:hide()
	if vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_hide(self.win)
	end
end

function terminal:show()
	if not vim.api.nvim_win_is_valid(self.win) then
		self:open()
	end
end

-- TERM
local hide_open = function()
	if not M.index then
		return
	end
	local term = M.terminals[M.index]
	if term ~= nil then
		term:hide()
	end
end

local function on_close(ev)
	local term = M.terminals[M.index]
	if not term or term.buf ~= ev.buf then
		return
	end
	M.index = nil
	for k, _ in pairs(M.terminals) do
		if k ~= term.id then
			M.index = k
			break
		end
	end
	M.terminals[term.id] = nil
end

local function on_buf_enter()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype == "terminal" then
		local term = M.terminals[M.index]
		if term ~= nil then
			vim.fn.timer_start(50, function()
				vim.cmd.startinsert()
			end)
		end
	end
end

function M.open(opts, cmd)
	hide_open()
	-- opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	-- local term = terminal:new(opts, cmd)
	-- term.id = M.counter
	-- M.counter = M.counter + 1
	-- M.terminals[term.id] = term
	-- M.index = term.id
    local term = M.new(opts, cmd)
	term:open()
end

function M.new(opts, cmd)
	opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	local term = terminal:new(opts, cmd)
	term.id = M.counter
	M.counter = M.counter + 1
	M.terminals[term.id] = term
	M.index = term.id
    return term
end


function M.next()
	if not M.index then
		return
	end
	hide_open()
	local next = false
	for k, v in pairs(M.terminals) do
		if next then
			M.index = k
			v:show()
			return
		end
		if k == M.index then
			next = true
		end
	end
	M.terminals[M.index]:show()
end

function M.prev()
	if not M.index then
		return
	end
	hide_open()
	local index = -1
	for k, v in pairs(M.terminals) do
		if k == M.index then
			if index >= 0 then
				M.index = index
				M.terminals[index]:show()
				return
			else
				v:show()
				return
			end
		end
		index = k
	end
end

function M.toggle()
	if not M.index then
		return
	end
	local term = M.terminals[M.index]
	if term ~= nil then
		term:toggle()
	else
		M.open(M.opts, nil)
	end
end

function M.resize(delta)
	if not M.index then
		return
	end
	local term = M.terminals[M.index]
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

local function fzflua_picker()
	local fzf_lua = require("fzf-lua")
	local items = picker.create_term_items(M.terminals)

	if #items == 0 then
		print("No terminals available")
		return
	end

	-- Store current terminal state
	local term = M.terminals[M.index]
	local term_was_open = false
	if term and vim.api.nvim_win_is_valid(term.win) then
		term_was_open = true
	end

	local display = {}

	for _, v in pairs(M.terminals) do
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
						hide_open()
						M.index = id
						M.toggle()
					end
				end
			end,
			["ctrl-c"] = function()
				-- On cancel, restore terminal state if it was open
				if term_was_open then
					hide_open()
					M.toggle()
				end
			end,
		},
	})
end

function M.pick()
	if not M._initialized then
		M.setup({})
		M._initialized = true
	end

	if not M.snacks_picker then
		local items = picker.create_term_items(M.terminals)
		if #items == 0 then
			return
		end
		if M.fzf_lua_picker then
			fzflua_picker()
		else
			vim.ui.select(items, {
				prompt = "Select Terminal",
				format_item = function(item)
					return string.format("%-11d %s", item.id, item.name)
				end,
			}, function(item, _)
				if item ~= nil then
					hide_open()
					M.index = item.id
					M.toggle()
				end
			end)
		end
		-- return
	else
		M.snacks_picker.floaterm()
	end
end

function M.count()
    return #M.terminals
end

function M.setup(opts)
	local has_snacks_picker, snacks_picker = pcall(require, "snacks.picker")
	local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")

	if has_snacks_picker then
		M.snacks_picker = snacks_picker
		snacks_picker.sources.floaterm = snack_picker(snacks_picker)
	elseif has_fzf_lua then
		M.fzf_lua_picker = fzf_lua
	end

	M.opts = vim.tbl_deep_extend("force", defaults, opts or {})

	vim.api.nvim_create_autocmd("TermClose", {
		callback = on_close,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = on_buf_enter,
	})
end

return M
