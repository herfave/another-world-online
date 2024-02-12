--[=[
@class 	EnemyService
    Author: Aaron Jay (seyai_one)

]=]
local SharedTableRegistry = game:GetService("SharedTableRegistry")

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local ChickyServer = require(Modules.Chickynoid.Server.ServerModule)
local path = game.ReplicatedFirst.Chickynoid
local CommandLayout = require(path.Shared.Simulation.CommandLayout)

local SharedTableUtil = require(Modules.SharedTableUtil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local EnemyService = Knit.CreateService({
    Name = "EnemyService";
    Client = {};
})

local STEnemyRegistry = SharedTable.new({})
SharedTableRegistry:SetSharedTable("ENEMY_REGISTRY", STEnemyRegistry)

local STEnemyCommands = SharedTable.new()
SharedTableRegistry:SetSharedTable("ENEMY_COMMANDS", STEnemyCommands)

function EnemyService:CreateActor(actorName: string, userId: number, template: string)
    local actor = Instance.new("Actor")
    actor.Name = actorName
    actor:SetAttribute("UserId", userId)
    local scriptTemplate = Modules.ActorTemplates:FindFirstChild(template)
    local newScript = scriptTemplate:Clone()
    newScript.Enabled = false
    newScript.Name = "Script"
    newScript.Parent = actor
    actor.Parent = self.ActorsFolder

    return actor
end

local userId = -26000
function EnemyService:SpawnEnemy(enemyType : string)
    local thisUserId = userId
    local playerRecord = ChickyServer:AddConnection(thisUserId, nil, "Enemy")
    userId -= 1
    local entityId = Knit.GetService("MatterService"):CreateEntity({
        Components.Enemy({ name = "Debug" }),
        Components.Position { value = Vector3.zero }
    })

    if (playerRecord == nil) then
        return
    end

    -- map to chickynoid
    Knit.GetService("MatterService"):MapEntityToRecord(thisUserId, entityId, playerRecord)

    playerRecord.name = "RandomBot"
    playerRecord.respawnTime = tick() + 1 * 0.1
    playerRecord:HandlePlayerLoaded()


    playerRecord.waitTime = 0 --Bot AI
    playerRecord.leftOrRight = 1 

    if (math.random()>0.5) then
        playerRecord.leftOrRight = -1
    end

    --Spawn them in someplace
    playerRecord.OnBeforePlayerSpawn:Connect(function()
        -- playerRecord:SetCharacterMod("Enemy")
        playerRecord.chickynoid:SetPosition(Vector3.new(-5.2, 10, 21.2))
    end)

    -- get next command based on sharedtable output

    local STEnemyRegistry = SharedTableRegistry:GetSharedTable("ENEMY_REGISTRY")
    SharedTableUtil.insert(STEnemyRegistry, entityId)

    -- setup actor for enemy ai
    local actor = self:CreateActor(`{entityId}_TreeThink`, thisUserId, "EnemyAI")
    actor:SetAttribute("EntityId", entityId)
    actor:FindFirstChild("Script").Enabled = true

    playerRecord.BotThink = function(deltaTime)
        if (playerRecord.waitTime > 0) then
            playerRecord.waitTime -= deltaTime
        end

        local event = {}

        local command = {}

        local stCommand = STEnemyCommands[entityId]
        if not stCommand then return end

        command.localFrame = playerRecord.frame
        command.playerStateFrame = 0
        command.serverTime = tick()
        command.deltaTime = deltaTime
        command.shiftLock = 1

        command.x = stCommand.x
        command.y = stCommand.y
        command.z = stCommand.z
        command.fa = stCommand.fa

        

        if (math.random() < 0.01) then
            playerRecord.waitTime = math.random() * 5
        end 
        event[1] = CommandLayout:EncodeCommand(command)
        playerRecord.frame += 1
        if (playerRecord.chickynoid) then
            playerRecord.chickynoid:HandleEvent(ChickyServer, event)
        end
    end
    
end

function EnemyService:KnitStart()

    -- create battle circle ai for each player
    local function playerAdded(player)
        self:CreateActor(`{player.UserId}_EnemyCircle`, player.UserId, "EnemyCircle")
    end

    for _, player in game.Players:GetPlayers() do
        playerAdded(player)
    end

    game.Players.PlayerAdded:Connect(playerAdded)
    game.Players.PlayerRemoving:Connect(function(player)
        -- destroy actor
        local actor = self.ActorsFolder:FindFirstChild(`{player.UserId}_EnemyCircle`)
        local runningScript = actor:GetChildren()[1]
        runningScript.Enabled = false
        task.wait()
        actor:Destroy()
    end)

    task.wait(5)
    for i = 1, 30 do
        self:SpawnEnemy()
        task.wait(0.1)
    end
end


function EnemyService:KnitInit()
    local actorsFolder = Instance.new("Folder")
    actorsFolder.Name = "EnemyServiceActors"
    actorsFolder.Parent = game:GetService("ServerScriptService")
    self.ActorsFolder = actorsFolder
end


return EnemyService