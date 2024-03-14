--[[
    CleanupDeadEnemies.lua
    Author: Aaron Jay

    Despawn enemies that have died (health <= 0)

]]

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Matter = require(game.ReplicatedStorage.Packages.Matter)

local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Health = Components.Health

return function(world)
    for entityId, healthRecord in world:queryChanged(Health) do
        if healthRecord.new then
            if healthRecord.new.value <= 0 then
                local lastAttacker = world:get(entityId, Components.LastAttacker)
                Knit.GetService("MobService"):DespawnMob(entityId, lastAttacker.player)
                -- print("Killed enemy")
            end
        end
    end
end