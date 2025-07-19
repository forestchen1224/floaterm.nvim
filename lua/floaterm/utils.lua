local M = {}
function M.hide_open()
    local state = require("floaterm.state")
	if not state.index then
		return
	end
	local term = state.terminals[state.index]
	if term ~= nil then
		term:hide()
	end
end

return M
