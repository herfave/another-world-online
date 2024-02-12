local task = {}

local SUCCESS,FAIL,RUNNING = 1,2,3

-- Any arguments passed into Tree:run(obj) can be received after the first parameter, obj
-- Example: Tree:run(obj,deltaTime) - > task.start(obj, deltaTime), task.run(obj, deltaTime), task.finish(obj, status, deltaTime)

-- Blackboards
    -- objects attached to the tree have tables injected into them called Blackboards.
    -- these can be read from and written to by the tree using the Blackboard node, and can be accessed in tasks via object.Blackboard
--
local ServerStorage = game:GetService("ServerStorage")
local SharedTableUtil = require(ServerStorage.Modules.SharedTableUtil)

local STMobPosition = game:GetService("SharedTableRegistry"):GetSharedTable("MOB_POS")
local STEnemyRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("ENEMY_REGISTRY")
local userId = script.Parent:GetAttribute("UserId")


function task.start(obj)
end

function task.finish(obj, status)
end

function task.run(obj)
    -- iterate through all player positions and find the closest
    local distanceToBeat = math.huge
    local currentPosition = STMobPosition[obj.EntityId]
    if not currentPosition then return RUNNING end
    for mobEntityId, position in STMobPosition do
        if obj.EntityId == mobEntityId then continue end -- skip self
        if SharedTableUtil.find(STEnemyRegistry, mobEntityId) then continue end -- skip fellow enemies

        local distance = (currentPosition - position).Magnitude
        if distance < distanceToBeat then
            distanceToBeat = distance
            obj.TargetEntityId = mobEntityId
        end
    end

    return SUCCESS
end
return task
