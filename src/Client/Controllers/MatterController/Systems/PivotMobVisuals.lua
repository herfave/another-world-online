local Workspace = game:GetService("Workspace")
local Matter = require(game.ReplicatedStorage.Packages.Matter)
local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Knit = require(game.ReplicatedStorage.Packages.Knit)

local Model = Components.Model
local Mob = Components.Mob
local MobVisual = Components.MobVisual

return function(world)
    local instances, cframes = {}, {}
    for id, entity, mobVisual, serverModel in world:query(Mob, MobVisual, Model) do
        local cf = serverModel.value:GetPivot()
        local instance = mobVisual.value.PrimaryPart
        table.insert(instances, instance)
        table.insert(cframes, cf)
    end

    workspace:BulkMoveTo(instances, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end