--[[
    DamageTargets.lua
    Author: Aaron Jay

    Apply flat damage amount to entity, deducting from its Health value.
    See HandleDeath.lua for managing death states

]]
local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Components = require(game.ReplicatedStorage.Shared.ECS.Components)

local FlatDamage = Components.FlatDamage
local Health = Components.Health
local Enemy = Components.Enemy

return function(world)
    -- query the world for existing tower
    for _id, damage, health in world:query(FlatDamage, Health, Enemy) do
        world:remove(_id, FlatDamage)
        world:insert(_id, health:patch({
            value = health.value - damage.value
        }))

        -- print("Dealt " .. removedDamage.value .. " damage")
    end
end