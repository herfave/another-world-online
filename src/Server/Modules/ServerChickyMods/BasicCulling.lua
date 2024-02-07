local module = {}

function module:Setup(_server) end


--Basic example of visibility culling, 350 unit radius
function module:CanPlayerSee(sourcePlayer, otherPlayer)
    
    if (sourcePlayer.chickynoid == nil) then
        return true
    end
    if (otherPlayer.chickynoid == nil) then
        return true
    end

    local posA = sourcePlayer.chickynoid.simulation.state.position
    local posB = otherPlayer.chickynoid.simulation.state.position

    if ((posA-posB).Magnitude > 450) then
        return false
    end
    return true
end

return module