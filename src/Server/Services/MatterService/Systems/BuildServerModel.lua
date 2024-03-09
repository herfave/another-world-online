--[[
    BuildModel.lua
    Author: Aaron Jay

    Creates model instances for entities with specific components, using the
    defined component's value for the basis of the asset

    for example, entities with a "Tower" component that has the value "Gunner" should
    have a "Gunner" model created for them if it doesn't exist

]]

local Workspace = game:GetService("Workspace")
local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Components = require(game.ReplicatedStorage.Shared.ECS.Components)

local Model = Components.Model

local models = game.ReplicatedStorage.Assets.Models

return function(world, state)
    for id, entity in world:query(Components.Mob):without(Model) do
        local baseModel = models:FindFirstChild("MobBase")
        if not baseModel then continue end
        local model = baseModel:Clone()

        model:SetAttribute("Jump", false)
        model:SetAttribute("MoveDirection", Vector3.zero)
        model:SetAttribute("LookDirection", Vector3.zero)
        model:SetAttribute("EntityId", id)

        model.Parent = workspace:FindFirstChild("Mobs")
        world:insert(id, Model({
            value = model
        }))
    end
end