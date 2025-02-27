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
    for id, entity, origin, maxHealth in world:query(Components.Mob, Components.Origin, Components.MaxHealth):without(Model) do
        local baseModel = models:FindFirstChild("MobBase")
        if not baseModel then continue end
        local model = baseModel:Clone()
        model.Name = tostring(id)

        local idLabel = model:FindFirstChild("IdLabel", true)
        if idLabel then
            idLabel.Text = tostring(id)
        end

        -- clone manager
        local cm: ControllerManager = game.ReplicatedStorage.Assets:FindFirstChild("DefaultManager"):Clone()
        cm.BaseMoveSpeed = 6
        cm.GroundSensor = model:FindFirstChild("GroundSensor", true)
        cm.ClimbSensor = model:FindFirstChild("ClimbSensor", true)
        cm.RootPart = model.PrimaryPart
        cm.GroundController.GroundOffset = 2
        cm.Parent = model

        model:SetAttribute("Jump", false)
        model:SetAttribute("MoveDirection", Vector3.zero)
        model:SetAttribute("LookDirection", Vector3.zero)
        model:SetAttribute("EntityId", id)

        model.Parent = workspace:FindFirstChild("Mobs")
        model:PivotTo(CFrame.new(origin.position))
        world:insert(id,
            Model({ value = model}),
            Components.Health({ value = maxHealth.value })
        )
    end
end