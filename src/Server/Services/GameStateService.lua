--[=[
@class 	GameStateService
    Author: Aaron Jay (seyai_one)

    Track objectives based on config in ReplicatedStorage. Objectives can be loaded in via a module
    that fires ObjectiveModule.ObjectiveMet when conditions are met for this objective.

    Modules can contain logic to progress an objective, such as the caravan escort moving
    instantiating the caravan tween(s) internally and reporting values as such
]=]
local TeleportService = game:GetService("TeleportService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local GameConfigData = require(Modules.GameConfigData)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Promise = require(Packages.Promise)
local TableUtil = require(Packages.TableUtil)

local MemoryStoreService = game:GetService("MemoryStoreService")
local QuestConfigMap = MemoryStoreService:GetSortedMap("QuestConfigs")

local GameStateService = Knit.CreateService({
    Name = "GameStateService";
    Client = {};
})

function GameStateService:ShouldSpawnMobs(): boolean
    if not self.ObjectiveModule then
        return true
    else
        if self.GameConfig.AllowRespawn ~= nil then
            if self.GameConfig.AllowRespawn == false then
                return false
            end
        end
        return not self.ObjectiveModule.Completed
    end
end

function GameStateService:StartQuest()
    if not self.GameConfig then return end
    local module = Modules.Objectives:FindFirstChild(self.GameConfig.Objective)
    if module then
        self.ObjectiveModule = require(module).new(self.GameConfig)
        self.ObjectiveModule.ObjectiveMet:Connect(function(status)
            if status then
                print("Completed the quota, clean up and teleport...")
                local players = game.Players:GetPlayers()
                TeleportService:TeleportAsync(12848422281, players)
            end
        end)
    end
    self.GameStats = {
        Kills = 0,
        Deaths = 0,
    }

    Knit.GetService("PlayerService").PlayerDied:Connect(function(player: Player)
        self.GameStats.Deaths += 1
    end)

    self.EnemyKilled:Connect(function(entityId: number, mobType: string, killedBy: number)
        self.GameStats.Kills += 1
        print(`[{entityId}] {mobType} killed by {killedBy}`)
    end)
end


function GameStateService:KnitInit()
    self.EnemyKilled = Signal.new()

    local isLobby = ServerStorage:FindFirstChild("IsLobby")
    -- generate config based on quest info from memorystore
    if not isLobby and game.PrivateServerId then
        local getConfigPromise = function()
            return Promise.new(function(resolve, reject)
                local success, result = pcall(function()
                    return QuestConfigMap:GetAsync(game.PrivateServerId)
                end)

                if success and result then
                    resolve(result)
                else
                    reject(result)
                end
            end)
        end

        Promise.retryWithDelay(getConfigPromise, 3, 2):andThen(function(config)
            -- get game config based on objective, map, and difficulty
            for i, v in config do
                print(i, v)
            end
            local newConfig = TableUtil.Copy(GameConfigData[config.Objective][config.Map][config.Difficulty])
            newConfig.Objective = config.Objective
            self.GameConfig = newConfig
            self:StartQuest()
        end)
    elseif not game.PrivateServerId then
        local gameConfig = ReplicatedStorage:FindFirstChild("GameConfig")
        if gameConfig then
            local config = {}
            for _, value in gameConfig:GetChildren() do
                config[value.Name] = value.Value
            end
            self.GameConfig = config
        end
    end
end


return GameStateService