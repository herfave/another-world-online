local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Model = Components.Model
local Mob = Components.Mob
local MobVisual = Components.MobVisual


return function(world)
    for id, mob, serverModel in world:query(Mob, Model) do
        local model: Model = serverModel.value
        local cm: ControllerManager = model:FindFirstChildOfClass("ControllerManager")
        local moveDirection: Vector3 = model:GetAttribute("MoveDirection")
        local lookDirection: Vector3 = model:GetAttribute("LookDirection")
        cm.MovingDirection = moveDirection
        cm.FacingDirection = lookDirection
    end
end