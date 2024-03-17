local Packages = game:GetService("ReplicatedStorage").Packages
local Timer = require(Packages.Timer)

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage.Modules
local BTreeCreator = require(Modules.BehaviorTreeCreator)

local tree = BTreeCreator:Create(ServerStorage.EnemyTrees.BasicEnemy)

local userId = script.Parent:GetAttribute("UserId")
local entityId = script.Parent:GetAttribute("EntityId")
local origin = script.Parent:GetAttribute("Origin")
local range = script.Parent:GetAttribute("Range")

local dt = 1/4
local obj = {
    Range = range,
    Origin = origin,
    UserId = userId,
    EntityId = entityId,
    _deltaTime = dt,
    _actor = script.Parent,
    RequestAttackCooldown = 0,
}
local thread
local function fixedUpdate()
    task.desynchronize()
    tree:run(obj)
    task.synchronize()

    -- update state
    if obj.state == "Attack" and not script.Parent:GetAttribute("Attack") and obj._hasAttackToken then
        obj._hasAttackToken = false
        script.Parent:SetAttribute("Attack", true)
        thread = task.delay(0.7, function()
            if script.Parent == nil then return end
            script.Parent:SetAttribute("Attack", false)
        end)
    elseif obj.state ~= "Attack" and script.Parent:GetAttribute("Attack") then
        script.Parent:SetAttribute("Attack", false)
        if thread then
            task.cancel(thread)
            thread = nil
        end
    end
end


Timer.Simple(dt, fixedUpdate, true, RunService.PreAnimation) -- 20hz update schedule