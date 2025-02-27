local task = {}

local SUCCESS,FAIL,RUNNING = 1,2,3

-- Any arguments passed into Tree:run(obj) can be received after the first parameter, obj
-- Example: Tree:run(obj,deltaTime) - > task.start(obj, deltaTime), task.run(obj, deltaTime), task.finish(obj, status, deltaTime)

-- Blackboards
    -- objects attached to the tree have tables injected into them called Blackboards.
    -- these can be read from and written to by the tree using the Blackboard node, and can be accessed in tasks via object.Blackboard
--
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POSITION")
local STEnemyCommands = SharedTableRegistry:GetSharedTable("ENEMY_COMMANDS")
local STEnemyRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("ENEMY_REGISTRY")

local AVOID_RADIUS = 6
local PLAYER_RADIUS = 7
local ATTACK_RADIUS = 4

local RNG = Random.new()

function task.start(obj)
    -- print(`[{obj.EntityId}] MoveToTarget`)

    repeat
        obj.StrafeDirection = RNG:NextInteger(-1, 1)
    until obj.StrafeDirection ~= 0
    obj._lastStrafe = RNG:NextNumber(3, 10)
end

function task.finish(obj, status)
    if status == SUCCESS then
        obj._waitTime = 1
    
        local targetPosition = STMobPosition[obj.TargetEntityId]
        STEnemyCommands[obj.EntityId] = {
            x = 0,
            y = 0,
            z = 0,
            fa = targetPosition or Vector3.zero
        }
    end
end

function task.run(obj)
    if obj._lastStrafe > 0 then
        obj._lastStrafe -= obj._deltaTime
    else
        obj._lastStrafe = RNG:NextInteger(3, 10)
        obj.StrafeDirection = -obj.StrafeDirection
    end

    local entityId = obj.EntityId
    -- print(obj)
    if not obj.TargetEntityId then return FAIL end

    local targetPosition = STMobPosition[obj.TargetEntityId]
    local currentPosition = STMobPosition[entityId]

    targetPosition = Vector3.new(targetPosition.X, 0, targetPosition.Z)
    currentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)

    local command = {
        x = 0,
        y = 0,
        z = 0,
        fa = targetPosition
    }

    local direction = (targetPosition - currentPosition)
    local distanceFromTarget = direction.Magnitude

    local cf = CFrame.lookAt(currentPosition, targetPosition)

    -- avoid other enemies
    local moveVec = direction.Unit
    local closest = math.huge
    for _, otherEntityId in STEnemyRegistry do
        if otherEntityId == entityId then continue end
        local otherPosition = STMobPosition[otherEntityId]
        if not otherPosition then continue end
        local distanceToNext = math.abs((otherPosition - currentPosition).Magnitude)
        if distanceToNext < closest then
            closest = distanceToNext
        end

        if distanceToNext < AVOID_RADIUS then
            local avoid = -(otherPosition - currentPosition).Unit + (cf.RightVector * obj.StrafeDirection)
            moveVec = moveVec + avoid
        end
    end

    local radius = obj._hasAttackToken and ATTACK_RADIUS or PLAYER_RADIUS
    -- print(radius, distanceFromTarget)
    -- path towards target
    local targetFromOrigin = (targetPosition - obj.Origin).Magnitude
    if targetFromOrigin > obj.Range then
        obj.TargetEntityId = nil
        return FAIL
    elseif math.abs(distanceFromTarget - radius) < 0.5 then
        command.x = 0
        command.z = 0
        STEnemyCommands[entityId] = command
        return SUCCESS
    elseif distanceFromTarget >= radius then
        local unit = moveVec.Unit
        command.x = unit.X
        command.z = unit.Z
        -- path back if too close
    elseif distanceFromTarget < radius - 0.5 then
        -- moveVec += -direction.Unit
        local unit = -direction.Unit
        command.x = unit.X
        command.z = unit.Z
        return SUCCESS
    end

    obj.state = "Moving"

    if obj.RequestAttackCooldown > 0 then
        obj.RequestAttackCooldown -= obj._deltaTime
    end
    STEnemyCommands[entityId] = command

    return RUNNING
end
return task
