local Packages = game:GetService("ReplicatedStorage").Packages
local Timer = require(Packages.Timer)

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage.Modules
local BTreeCreator = require(Modules.BehaviorTreeCreator)

local tree = BTreeCreator:Create(ServerStorage.EnemyTrees.TestTree)

local dt = 1/20
local function fixedUpdate()
    local thisInfo = {
        result = 0
    }
    task.desynchronize()
    task.synchronize()
end

-- Timer.Simple(dt, fixedUpdate) -- 20hz update schedule