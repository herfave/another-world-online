local Workspace = game:GetService("Workspace")
local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Components = require(game.ReplicatedStorage.Shared.ECS.Components)

local Model = Components.Model
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POSITION")
return function(world)
    for id, model in world:query(Model) do
        local pivot = model.value:GetPivot()
        STMobPosition[id] = pivot.Position
    end
end