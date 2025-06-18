local M = {}

M.create_term_items = function(terminals)
	local items = {}
	for _, v in pairs(terminals) do
		local bufnr = v.buf
		local name = vim.fn.getbufvar(bufnr, "term_title")
		table.insert(items, { buf = bufnr, name = name, text = string.format("%d %s", bufnr, name), id = v.id })
	end

	table.sort(items, function(a, b)
		return vim.fn.getbufinfo(a.buf)[1].lastused > vim.fn.getbufinfo(b.buf)[1].lastused
	end)

	return items
end
return M
