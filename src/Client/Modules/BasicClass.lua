local BasicClass = {}
BasicClass.__index = BasicClass


function BasicClass.new()
    local self = setmetatable({}, BasicClass)
    return self
end


function BasicClass:Destroy()
    
end


return BasicClass