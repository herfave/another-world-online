local task = {}

local SUCCESS,FAIL,RUNNING = 1,2,3


local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POSITION")
local STEnemyCommands = SharedTableRegistry:GetSharedTable("ENEMY_COMMANDS")
local STEnemyRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("ENEMY_REGISTRY")

function task.start(obj)
end

function task.finish(obj, status)
    if status == SUCCESS then
        obj.state = "Attack"
    end
end

-- TODO: request attack
function task.run(obj)
    local targetPosition = STMobPosition[obj.TargetEntityId]
    if not targetPosition then return FAIL end
    STEnemyCommands[obj.EntityId] = {
        x = 0,
        y = 0,
        z = 0,
        fa = targetPosition
    }
    return SUCCESS
end

return task