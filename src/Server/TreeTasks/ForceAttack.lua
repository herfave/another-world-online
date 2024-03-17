local leaf = {}

local SUCCESS,FAIL,RUNNING = 1,2,3

local Promise = require(game.ReplicatedStorage.Packages.Promise)
local HttpService = game:GetService("HttpService")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POSITION")
local STEnemyCommands = SharedTableRegistry:GetSharedTable("ENEMY_COMMANDS")
local STPlayerRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("PLAYER_REGISTRY")

function leaf.start(obj)
    -- print(`[{obj.EntityId}] Started RequestAttack`)
    local userId: number = STPlayerRegistry[obj.TargetEntityId]
    local player = game.Players:GetPlayerByUserId(userId)
    obj.TargetPlayer = player
    -- promise request a token from target player
    obj._hasAttackToken = false
    if obj.RequestAttackCooldown <= 0 then
        obj._hasAttackToken = true
    end
end

function leaf.finish(obj, status)
    if status == SUCCESS and obj._hasAttackToken then
        obj.state = "Attack"
        obj.RequestAttackCooldown = 3
        task.delay(2, function()
            obj._hasAttackToken = false
        end)
    end
end

function leaf.run(obj)
    if obj.RequestAttackCooldown > 0 then
        obj.RequestAttackCooldown -= obj._deltaTime
        return FAIL
    end

    local player = obj.TargetPlayer
    -- TODO: check position, fail to get closer magnitude
    local targetPosition = STMobPosition[obj.TargetEntityId]
    local currentPosition = STMobPosition[obj.EntityId]

    targetPosition = Vector3.new(targetPosition.X, 0, targetPosition.Z)
    currentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)

    local direction = (targetPosition - currentPosition)
    local distanceFromTarget = direction.Magnitude

    local targetPosition = STMobPosition[obj.TargetEntityId]
    if not targetPosition then return FAIL end

    if distanceFromTarget > 8 then
        obj._hasAttackToken = false
        local bindable = player:FindFirstChild("InvokeAttackToken")
        bindable:Fire(obj.EntityId, true, 2)
        return FAIL -- should send back to MoveToTarget
    end

    STEnemyCommands[obj.EntityId] = {
        x = 0,
        y = 0,
        z = 0,
        fa = targetPosition
    }
    return SUCCESS
end

return leaf