--[[
    CleanupDeadEnemies.lua
    Author: Aaron Jay

    Despawn enemies that have died (health <= 0)

]]

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Matter = require(game.ReplicatedStorage.Packages.Matter)

local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Mob = Components.Mob
local Health = Components.Health
local Enemy = Components.Enemy

return function(world)
    for _id, mob, health in world:query(Mob, Health, Enemy) do
        if health.value <= 0 then
            Knit.GetService("MobService"):DespawnMob(_id)
            -- print("Killed enemy")
        end
    end
end