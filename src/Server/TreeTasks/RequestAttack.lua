--[=[
    How attacks work:
    1. Actor sends request to Player its targeting for a token
    2. If it gets a token, then proceed with setting to attack state
    3. If it recently received a token, there is a cooldown before the actor
       can request another token
    4. During this time, the token is "checked out" and unable to be taken by any actor
    5. Once reset, the actor can request a token again and act if one is available

    Note: By default, a basic attack (M1) consumes 2 tokens.
]=]
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
        local bindable = player:FindFirstChild("InvokeAttackToken")
        bindable:Fire(obj.EntityId, true, 2)
    end
end

function leaf.finish(obj, status)
    if status == SUCCESS and obj._hasAttackToken then
        obj.state = "Attack"
        local userId: number = STPlayerRegistry[obj.TargetEntityId]
        local player = game.Players:GetPlayerByUserId(userId)
        local bindable = player:FindFirstChild("InvokeAttackToken")

        local attackDelay = player:GetAttribute("EnemyAttackDelay") or 2
        obj.RequestAttackCooldown = 3

        task.delay(math.max(1, attackDelay), function()
            bindable:Fire(obj.EntityId, false, 2)
            obj._hasAttackToken = false
        end)
    end
end

function leaf.run(obj)
    -- check status of promise
    if obj.RequestAttackCooldown > 0 then
        obj.RequestAttackCooldown -= obj._deltaTime
        return FAIL
    end

    local player = obj.TargetPlayer
    local ts = player:GetAttribute("HasAttackToken")
    local hasTokens = false
    if ts then
        local t = HttpService:JSONDecode(ts)
        local tokensNeeded = 2
        local tokensFound = 0
        for i = 1, 2 do
            local index = table.find(t, obj.EntityId)
            if index then
                table.remove(t, index)
                tokensFound += 1
            end
        end

        hasTokens = tokensFound == tokensNeeded
    end

    if hasTokens then
        obj._hasAttackToken = true

        -- TODO: check position, fail to get closer magnitude
        local targetPosition = STMobPosition[obj.TargetEntityId]
        local currentPosition = STMobPosition[obj.EntityId]

        targetPosition = Vector3.new(targetPosition.X, 0, targetPosition.Z)
        currentPosition = Vector3.new(currentPosition.X, 0, currentPosition.Z)

        local direction = (targetPosition - currentPosition)
        local distanceFromTarget = direction.Magnitude

        local targetPosition = STMobPosition[obj.TargetEntityId]
        if not targetPosition then return FAIL end

        if distanceFromTarget > 5 then
            return FAIL -- should send back to MoveToTarget
        end

        STEnemyCommands[obj.EntityId] = {
            x = 0,
            y = 0,
            z = 0,
            fa = targetPosition
        }
        return SUCCESS
    else
        return FAIL
    end
end

return leaf