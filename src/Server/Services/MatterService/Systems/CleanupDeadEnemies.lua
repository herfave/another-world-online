--[[
    CleanupDeadEnemies.lua
    Author: Aaron Jay

    Despawn enemies that have died (health <= 0)

]]

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Matter = require(game.ReplicatedStorage.Packages.Matter)

local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Enemy = Components.Enemy
local Health = Components.Health

return function(world)
    for _id, enemy, health in world:query(Enemy, Health) do
        if health.value <= 0 then
            Knit.GetService("EnemyService"):DespawnEnemy(_id, true)
            -- print("Killed enemy")
        end
    end
end