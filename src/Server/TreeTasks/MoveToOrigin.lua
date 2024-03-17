local leaf = {}

local SUCCESS,FAIL,RUNNING = 1,2,3

local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POSITION")
local STEnemyCommands = SharedTableRegistry:GetSharedTable("ENEMY_COMMANDS")

function leaf.run(obj)
    local entityId = obj.EntityId
    local currentPosition = STMobPosition[entityId]
    local origin = obj.Origin
    if not currentPosition then return RUNNING end

    if obj.TargetEntityId == nil then
        if (currentPosition - origin).Magnitude > 5 then
            local direction = (origin - currentPosition).Unit
            STEnemyCommands[entityId] = {
                x = direction.X,
                y = 0,
                z = direction.Z,
                fa = origin
            }
        else
            STEnemyCommands[entityId] = {
                x = 0,
                y = 0,
                z = 0,
                fa = origin
            }
        end
    end
    return SUCCESS
end

return leaf