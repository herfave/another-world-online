--[=[
@class 	EnemyService
    Author: Aaron Jay (seyai_one)

]=]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local ChickyServer = require(Modules.Chickynoid.Server.ServerModule)
local path = game.ReplicatedFirst.Chickynoid
local CommandLayout = require(path.Shared.Simulation.CommandLayout)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local EnemyService = Knit.CreateService({
    Name = "EnemyService";
    Client = {};
})

local userId = -26000
function EnemyService:SpawnEnemy(enemyType : string)
    local thisUserId = userId
    local playerRecord = ChickyServer:AddConnection(thisUserId, nil, "Enemy")

    if (playerRecord == nil) then
        return
    end

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
        playerRecord.chickynoid:SetPosition(Vector3.new(-5.2, 0.5, 21.2))
    end)

    playerRecord.BotThink = function(deltaTime)


        if (playerRecord.waitTime > 0) then
            playerRecord.waitTime -= deltaTime
        end

        local event = {}

        local command = {}
        command.localFrame = playerRecord.frame
        command.playerStateFrame = 0
        command.x = 0
        command.y = 0
        command.z = 0
        command.serverTime = tick()
        command.deltaTime = deltaTime


        if (playerRecord.waitTime <=0) and (playerRecord.chickynoid) then
            local world = Knit.GetService("MatterService"):GetWorld()
            for id, player, position in world:query(Components.Player, Components.Position) do
                local direction = (position.value - playerRecord.chickynoid.simulation.state.position)
                local unit = direction.Unit
                command.x = unit.X
                command.y = unit.Y
                command.z = unit.Z
            end
        end

        if (math.random() < 0.01) then
            playerRecord.waitTime = math.random() * 5
        end 
        event[1] = CommandLayout:EncodeCommand(command)
        playerRecord.frame += 1
        if (playerRecord.chickynoid) then
            playerRecord.chickynoid:HandleEvent(ChickyServer, event)
        end
    end
    userId -= 1
    Knit.GetService("MatterService"):CreateEntity({
        Components.Enemy({ name = "Debug" })
    })
end

function EnemyService:KnitStart()
    task.wait(5)
    for i = 1, 1 do
        self:SpawnEnemy()
    end
end


function EnemyService:KnitInit()
    
end


return EnemyService