local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Mob = Components.Mob
local Health = Components.Health
local MaxHealth = Components.MaxHealth
local Model = Components.Model
return function(world)
    for id, health, maxHealth, model in world:query(Health, MaxHealth, Model, Mob) do
        if not model.value then print("no model") continue end
        local healthDisplay = model.value:FindFirstChild("HealthDisplay")
        local frame = healthDisplay:FindFirstChild("HealthFrame")

        frame.Size = UDim2.fromScale(health.value / maxHealth.value, 1)
    end
end