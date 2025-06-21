local M = {}
M.hide_open = function(state)
	if not state.index then
		return
	end
	local term = state.terminals[state.index]
	if term ~= nil then
		term:hide()
	end
end

return M
