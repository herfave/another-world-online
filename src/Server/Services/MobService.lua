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
local MobData = require(Shared.MobData)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Matter = require(Packages.Matter)
local Signal = require(Packages.Signal)

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

function MobService:CreateMob(mobType: string, originPart: BasePart): number
    local mobInfo = MobData[mobType]
    local entityId = Knit.GetService("MatterService"):CreateEntity({
        Components.Mob { value = mobType },
        Components.MaxHealth { value = mobInfo.MaxHealth },
        Components.Enemy { value = true },

        Components.ATK { value = mobInfo.ATK },
        Components.Origin { position = originPart.Position }
    })

    SharedTableUtil.insert(STEnemyRegistry, entityId)
    -- setup actor for enemy ai
    local actor = self:CreateActor(`{entityId}_TreeThink`, "EnemyAI")
    actor:SetAttribute("EntityId", entityId)
    actor:FindFirstChild("Script").Enabled = true
    actor:SetAttribute("AttackCounter", 0)
    actor:SetAttribute("Origin", originPart.Position)
    actor:SetAttribute("Range", 30)
    self._mobThinks[entityId] = actor

    -- setup listeners for state changes via attributes
    actor:GetAttributeChangedSignal("Attack"):Connect(function()
        local didAttack = actor:GetAttribute("Attack")
        local counter = actor:GetAttribute("AttackCounter")
        if didAttack then
            counter += 1

            Knit.GetService("CombatService"):MobAttack(entityId, "M1-" .. tostring(counter))

            if counter == 5 then
                counter = 0
            end
            actor:SetAttribute("AttackCounter", counter)
        end
    end)

    return entityId
end

function MobService:DespawnMob(entityId: number)
    local world: Matter.World = Knit.GetService("MatterService"):GetWorld()
    if world:contains(entityId) then
        local isEnemy, mobType, lastAttacker = world:get(entityId, Components.Enemy, Components.Mob, Components.LastAttacker)
        if self._mobThinks[entityId] then
            self._mobThinks[entityId]:FindFirstChild("Script").Enabled = false
            task.delay(0.1, function()
                self._mobThinks[entityId]:Destroy()
                self._mobThinks[entityId] = nil
            end)
        end

        world:despawn(entityId)
        if isEnemy.value == true then
            Knit.GetService("GameStateService").EnemyKilled:Fire(entityId, mobType.value, lastAttacker.userId)
        end
        self.MobDied:Fire(entityId)
    end
end

function MobService:KnitStart()
    -- setup mob spawners
    local spawnsPer = 1
    local spawners = workspace:WaitForChild("MobSpawners")
    for _, spawner in spawners:GetChildren() do
        if spawner:HasTag("_MobSpawner") then
            for i = 1, spawnsPer do
                task.wait(0.2)
                local mobType = spawner:GetAttribute("MobType")
                local entityId: number = self:CreateMob(mobType, spawner)
                local currentIdFromSpawner = entityId
                
                -- setup respawn for this spawner
                self.MobDied:Connect(function(deadId: number)
                    if
                        deadId == currentIdFromSpawner
                    then
                        task.delay(spawner:GetAttribute("RespawnTime") or 15, function()
                            if Knit.GetService("GameStateService"):ShouldSpawnMobs() then
                                local newId: number = self:CreateMob(mobType, spawner)
                                currentIdFromSpawner = newId
                            end
                        end)
                    end
                end)
            end
        end
    end
end

function MobService:KnitInit()
    self.MobDied = Signal.new()
    self._mobThinks = {}

    local actorsFolder = Instance.new("Folder")
    actorsFolder.Name = "EnemyServiceActors"
    actorsFolder.Parent = game:GetService("ServerScriptService")
    self.ActorsFolder = actorsFolder
end


return MobService