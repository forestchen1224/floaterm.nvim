local TERM = {
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

function terminal:new()
	return setmetatable({
		buf = nil,
		win = nil,
		id = nil,
		opts = {},
	}, { __index = self })
end

function terminal:open(opts, cmd)
	self.opts = opts

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
		style = opts.style,
		border = opts.border,
	}

	-- Create the floating window
	self.win = vim.api.nvim_open_win(self.buf, true, win_config)
	-- These are needed for resizing (maybe the window only tells the app
	-- when using this after if window was created earlier?)
	vim.api.nvim_win_set_width(self.win, width)
	vim.api.nvim_win_set_height(self.win, height)

	if vim.bo[self.buf].buftype ~= "terminal" then
		vim.api.nvim_buf_call(self.buf, function()
			vim.fn.jobstart(cmd or vim.o.shell, {
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
	if not vim.api.nvim_win_is_valid(self.win) then
		self:open(self.opts)
	else
		vim.api.nvim_win_hide(self.win)
	end
end

function terminal:hide()
	if vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_hide(self.win)
	end
end

function terminal:show()
	if not vim.api.nvim_win_is_valid(self.win) then
		self:open(self.opts)
	end
end

-- TERM
local hide_open = function()
	if not TERM.index then
		return
	end
	local term = TERM.terminals[TERM.index]
	if term ~= nil then
		term:hide()
	end
end

local function on_close(ev)
	local term = TERM.terminals[TERM.index]
	if not term or term.buf ~= ev.buf then
		return
	end
	TERM.index = nil
	for k, _ in pairs(TERM.terminals) do
		if k ~= term.id then
			TERM.index = k
			break
		end
	end
	TERM.terminals[term.id] = nil
end

local function on_buf_enter()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype == "terminal" then
		local term = TERM.terminals[TERM.index]
		if term ~= nil then
			vim.fn.timer_start(100, function()
				vim.cmd.startinsert()
			end)
		end
	end
end

function TERM.open(opts, cmd)
	hide_open()
	local opt = vim.tbl_deep_extend("force", TERM.opts, opts or {})
	local term = terminal:new()
	term.id = TERM.counter
	TERM.counter = TERM.counter + 1
	TERM.terminals[term.id] = term
	TERM.index = term.id
	term:open(opt, cmd)
end

function TERM.next()
	if not TERM.index then
		return
	end
	hide_open()
	local next = false
	for k, v in pairs(TERM.terminals) do
		if next then
			TERM.index = k
			v:show()
			return
		end
		if k == TERM.index then
			next = true
		end
	end
	TERM.terminals[TERM.index]:show()
end

function TERM.prev()
	if not TERM.index then
		return
	end
	hide_open()
	local index = -1
	for k, v in pairs(TERM.terminals) do
		if k == TERM.index then
			if index >= 0 then
				TERM.index = index
				TERM.terminals[index]:show()
				return
			else
				v:show()
				return
			end
		end
		index = k
	end
end

function TERM.toggle()
	if not TERM.index then
		return
	end
	local term = TERM.terminals[TERM.index]
	if term ~= nil then
		term:toggle()
	else
		TERM.open()
	end
end

function TERM.resize(delta)
	if not TERM.index then
		return
	end
	local term = TERM.terminals[TERM.index]
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

local create_term_items = function()
	local items = {}
	for _, v in pairs(TERM.terminals) do
		local bufnr = v.buf
		local name = vim.fn.getbufvar(bufnr, "term_title")
		table.insert(items, { buf = bufnr, name = name, text = string.format("%d %s", bufnr, name), id = v.id })
	end

	table.sort(items, function(a, b)
		return vim.fn.getbufinfo(a.buf)[1].lastused > vim.fn.getbufinfo(b.buf)[1].lastused
	end)

	return items
end

local function snack_picker(picker)
	return {
		win = {
			title = "Select Terminal",
			preview = {
				style = "minimal",
			},
		},
		finder = create_term_items,
		format = function(item)
			local ret = {}
			ret[#ret + 1] = { string.format("%-11d", item.id or 1), "FloatermNumber" }
			ret[#ret + 1] = { " " }
			ret[#ret + 1] = { item.name or "", "FloatermDirectory" }
			return ret
		end,
		term_open = false,
		on_show = function(picker)
			-- If there was a terminal open, if we close the picker, we want to go back,
			-- and snacks.picker takes us to the editor buffer
			local term = TERM.terminals[TERM.index]
			picker.term_open = false
			if term and vim.api.nvim_win_is_valid(term.win) then
				picker.term_open = true
			end
		end,
		confirm = function(picker, item)
			if item ~= nil then
				hide_open()
				TERM.index = item.id
				TERM.toggle()
				picker.term_open = false
			end
			picker:close()
		end,
		on_close = function(picker)
			if picker.term_open then
				hide_open()
				TERM.toggle()
			end
		end,
		preview = picker.preview.file,
	}
end

local function fzflua_picker()
	local fzf_lua = require("fzf-lua")
	local items = create_term_items()

	if #items == 0 then
		print("No terminals available")
		return
	end

	-- Store current terminal state
	local term = TERM.terminals[TERM.index]
	local term_was_open = false
	if term and vim.api.nvim_win_is_valid(term.win) then
		term_was_open = true
	end

	local display = {}

	for _, v in pairs(TERM.terminals) do
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
        print(buf)
        print(type(buf))

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
						TERM.index = id
						TERM.toggle()
					end
				end
			end,
			["ctrl-c"] = function()
				-- On cancel, restore terminal state if it was open
				if term_was_open then
					hide_open()
					TERM.toggle()
				end
			end,
		},
	})
end

function TERM.pick()
	if not TERM._initialized then
		TERM.setup({})
		TERM._initialized = true
	end

	if not TERM.snacks_picker then
		local items = create_term_items()
		if #items == 0 then
			return
		end
		if TERM.fzf_lua_picker then
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
					TERM.index = item.id
					TERM.toggle()
				end
			end)
		end
		-- return
	else
		print(TERM.snacks_picker)
		TERM.snacks_picker.floaterm()
	end
end

function TERM.setup(opts)
	local has_snacks_picker, snacks_picker = pcall(require, "snacks.picker")
	local has_fzf_lua, fzf_lua = pcall(require, "fzf-lua")

	if has_snacks_picker then
		TERM.snacks_picker = snacks_picker
		snacks_picker.sources.floaterm = snack_picker(snacks_picker)
	elseif has_fzf_lua then
		TERM.fzf_lua_picker = fzf_lua
	end

	TERM.opts = vim.tbl_deep_extend("force", defaults, opts or {})

	vim.api.nvim_create_autocmd("TermClose", {
		callback = on_close,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = on_buf_enter,
	})
end

return TERM
