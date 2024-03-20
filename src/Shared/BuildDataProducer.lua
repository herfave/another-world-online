local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local DefaultData = require(ReplicatedStorage.Shared.DefaultData)

export type ValueState = {
    entities: { [string] : PlayerEntity}
}

export type PlayerEntity = {
    [string]: any?
}


return function()
    local slices = {}
    for key, defaultValue in DefaultData do
        local producer = Reflex.createProducer({ entities = {} }, {
            [`addPlayer_{key}`] = function(state: ValueState, userId: number, initialValue: any?)
                local stringId = tostring(userId)
                local nextState = table.clone(state)
                local nextEntities = table.clone(state.entities)
                nextEntities[stringId] = initialValue or defaultValue
                nextState.entities = nextEntities
                return nextState
            end,
            
            [`removePlayer_{key}`] = function(state: ValueState, userId: number)
                local stringId = tostring(userId)
                local nextState = table.clone(state)
                local nextEntities = table.clone(state.entities)
                nextEntities[stringId] = nil
                nextState.entities = nextEntities
                return nextState
            end,
            
            [`set_{key}`] = function(state: ValueState, userId: number, newValue: any?)
                local stringId = tostring(userId)
                local nextState = table.clone(state)
                local nextEntities = table.clone(state.entities)
                nextEntities[stringId] = newValue
                nextState.entities = nextEntities
                return nextState
            end,
        })

        slices[key] = producer
    end

    return Reflex.combineProducers(slices), slices
end
