local Packages = game:GetService("ReplicatedStorage").Packages
local Timer = require(Packages.Timer)

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage.Modules
local BTreeCreator = require(Modules.BehaviorTreeCreator)

local tree = BTreeCreator:Create(ServerStorage.EnemyTrees.BasicEnemy)

local userId = script.Parent:GetAttribute("UserId")
local entityId = script.Parent:GetAttribute("EntityId")

local dt = 1/20
local obj = {
    UserId = userId,
    EntityId = entityId,
    _deltaTime = dt,
}

local function fixedUpdate()
    task.desynchronize()
    tree:run(obj)
    task.synchronize()
end

Timer.Simple(dt, fixedUpdate) -- 20hz update schedule