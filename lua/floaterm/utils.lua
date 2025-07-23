local M = {}
--- Hides the currently open terminal if one exists
--- Used to ensure only one terminal is visible at a time
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
