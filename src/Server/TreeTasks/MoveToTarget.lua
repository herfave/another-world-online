local task = {}

local SUCCESS,FAIL,RUNNING = 1,2,3

-- Any arguments passed into Tree:run(obj) can be received after the first parameter, obj
-- Example: Tree:run(obj,deltaTime) - > task.start(obj, deltaTime), task.run(obj, deltaTime), task.finish(obj, status, deltaTime)

-- Blackboards
    -- objects attached to the tree have tables injected into them called Blackboards.
    -- these can be read from and written to by the tree using the Blackboard node, and can be accessed in tasks via object.Blackboard
--
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POS")
local STEnemyCommands = SharedTableRegistry:GetSharedTable("ENEMY_COMMANDS")
local STEnemyRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("ENEMY_REGISTRY")

function task.start(obj)
    
end

function task.finish(obj, status)

end

function task.run(obj)
    local entityId = obj.EntityId
    -- print(obj)
    if not obj.TargetEntityId then return RUNNING end

    local targetPosition = STMobPosition[obj.TargetEntityId]
    local currentPosition = STMobPosition[entityId]

    local command = {
        x = 0,
        y = 0,
        z = 0,
        fa = targetPosition
    }

    local direction = (targetPosition - currentPosition)
    local distanceFromTarget = direction.Magnitude

    -- avoid other enemies
    local isAvoiding = false
    if distanceFromTarget < 20 and distanceFromTarget > 10 then
        for _, otherEntityId in STEnemyRegistry do
            if otherEntityId == entityId then continue end
            local otherPosition = STMobPosition[otherEntityId]
            if not otherPosition then continue end
            if (otherPosition - currentPosition).Magnitude < 6 then
                -- avoid
                isAvoiding = true
                local avoid = -(otherPosition - currentPosition).Unit
                command.x = avoid.X
                -- command.y = avoid.Y
                command.z = avoid.Z
            end
        end
    end

    -- path towards target
    if not isAvoiding then
        local unit = direction.Unit
        if distanceFromTarget < 10 then
            unit = -unit
        end

        command.x = unit.X
        -- command.y = unit.Y
        command.z = unit.Z
    end

    STEnemyCommands[entityId] = command

    return SUCCESS
end
return task
