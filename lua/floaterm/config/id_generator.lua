local M = {
    Generator = nil,
}
---singleton mode, return the ID Generator
function M:init()
    if not self.Generator then
        local id = 0
        self.Generator = function()
            id = id + 1
            return tostring(id)
        end
    end
    return self.Generator
end
return M:init()
