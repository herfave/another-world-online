local module = {}
local actor = script.Parent

function module:Presync()
end

function module:Desync()
    task.desynchronize()
end

function module:Sync()

end

return module