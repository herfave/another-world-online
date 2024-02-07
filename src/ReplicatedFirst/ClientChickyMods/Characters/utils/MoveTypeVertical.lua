local module = {}

function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Railgrind",
        self.ActiveThink,
        self.AlwaysThink,
        self.StartState,
        self.EndState
    )
end

function module.AlwaysThink(simulation, cmd)
    -- check if colliding with a wall that becomes a halfpipe
    
end

function module.StartState(simulation, prevState)

end

function module.EndState(simulation, nextState)

end

function module.ActiveThink(simulation, cmd)

end

return module