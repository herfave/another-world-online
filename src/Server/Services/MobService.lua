--[=[
@class 	MobService
    Author: Aaron Jay (seyai_one)

]=]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local SharedTableUtil = require(Modules.SharedTableUtil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local MobService = Knit.CreateService({
    Name = "MobService";
    Client = {};
})

local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTableRegistry:GetSharedTable("MOB_POSITION")
local STEnemyCommands = SharedTableRegistry:GetSharedTable("ENEMY_COMMANDS")
local STEnemyRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("ENEMY_REGISTRY")

-- create an actor unit using a script template
function MobService:CreateActor(actorName: string, template: string)
    local actor = Instance.new("Actor")
    actor.Name = actorName
    local scriptTemplate = Modules.ActorTemplates:FindFirstChild(template)
    local newScript = scriptTemplate:Clone()
    newScript.Enabled = false
    newScript.Name = "Script"
    newScript.Parent = actor
    actor.Parent = self.ActorsFolder

    return actor
end

function MobService:CreateMob(): number
    local entityId = Knit.GetService("MatterService"):CreateEntity({
        Components.Mob { value = "TestMob" },
    })

    SharedTableUtil.insert(STEnemyRegistry, entityId)
    -- setup actor for enemy ai
    local actor = self:CreateActor(`{entityId}_TreeThink`, "EnemyAI")
    actor:SetAttribute("EntityId", entityId)
    actor:FindFirstChild("Script").Enabled = true

    return entityId
end

function MobService:KnitStart()
    for i = 1, 20 do
        self:CreateMob()
        task.wait(1)
    end
end


function MobService:KnitInit()
    self._mobThinks = {}

    local actorsFolder = Instance.new("Folder")
    actorsFolder.Name = "EnemyServiceActors"
    actorsFolder.Parent = game:GetService("ServerScriptService")
    self.ActorsFolder = actorsFolder
end


return MobService