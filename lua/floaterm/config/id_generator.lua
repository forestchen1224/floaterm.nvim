local M = {
    initialized = false,
    Generator = nil,
}
function M:init()
    if not self.initialized then
        local id = 0
        self.Generator =  function()
            id = id + 1
            return id
        end
    end
    return self.Generator
end
return M:init()
