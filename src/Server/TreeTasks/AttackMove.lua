local leaf = {}

local SUCCESS,FAIL,RUNNING = 1,2,3
local STPlayerRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("PLAYER_REGISTRY")

-- TODO: Move into smaller radius then perform attack
function leaf.start(obj)
    
end
function leaf.finish(obj, status)
    if status == SUCCESS and obj._hasAttackToken then
        local userId: number = STPlayerRegistry[obj.TargetEntityId]
        local player = game.Players:GetPlayerByUserId(userId)
        local bindable = player:FindFirstChild("InvokeAttackToken")

        local attackDelay = player:GetAttribute("EnemyAttackDelay") or 2
        obj.RequestAttackCooldown = 3

        task.delay(math.max(1, attackDelay), function()
            bindable:Fire(obj.EntityId, false, 2)
        end)
    end
end	
function leaf.run(obj)
    
    return SUCCESS
end
return leaf
