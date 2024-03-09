local Components = require(game.ReplicatedStorage.Shared.ECS.Components)
local Model = Components.Model
local Mob = Components.Mob
local MobVisual = Components.MobVisual

local STEnemyCommands = game:GetService("SharedTableRegistry"):GetSharedTable("ENEMY_COMMANDS")
return function(world)
    for id, mob, serverModel in world:query(Mob, Model) do
        local command = STEnemyCommands[id]
        if not command then continue end

        local model: Model = serverModel.value
        local cm: ControllerManager = model:FindFirstChildOfClass("ControllerManager")
        local moveDirection: Vector3 = Vector3.new(command.x, command.y, command.z)
        local lookDirection: Vector3 = CFrame.lookAt(model:GetPivot().Position, command.fa).LookVector
        cm.MovingDirection = moveDirection
        cm.FacingDirection = lookDirection

        model:SetAttribute("MoveDirection", moveDirection)
        model:SetAttribute("LookDirection", lookDirection)
    end
end