--[=[
@class 	MobService
    Author: Aaron Jay (seyai_one)

]=]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local MobService = Knit.CreateService({
    Name = "MobService";
    Client = {};
})

function MobService:CreateMob(): number
    local entityId = Knit.GetService("MatterService"):CreateEntity({
        Components.Mob { value = "TestMob" },
    })

    return entityId
end

function MobService:KnitStart()
    task.wait()
    self:CreateMob()
end


function MobService:KnitInit()
    
end


return MobService