local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Mob = Components.Mob
local Health = Components.Health
local MaxHealth = Components.MaxHealth
local Model = Components.Model
return function(world)
    for id, healthRecord in world:queryChanged(Health) do
        if healthRecord.new then
            local maxHealth, model = world:get(id, Components.MaxHealth, Components.Model)
            if not model then continue end
            if not model.value then print("no model") continue end
            local healthDisplay = model.value:FindFirstChild("HealthDisplay")
            local frame = healthDisplay:FindFirstChild("HealthFrame")

            frame.Size = UDim2.fromScale(healthRecord.new.value / maxHealth.value, 1)
        end
    end
end