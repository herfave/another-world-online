--[[
    Name: PopulateEnemy.lua
    Author: Aaron Jay

    Add components to enemy entities that aren't replicated but are used by both client/server setups
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local Enemy = Components.Enemy
local Travel = Components.Travel
local Path = Components.Path
local Position = Components.Position
local Rotation = Components.Rotation
local Animation = Components.Animation

local EnemyData = require(ReplicatedStorage.Shared.EnemyData)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

return function(world)
    for _id, enemy in world:query(Enemy) do
        -- populate?
    end
end