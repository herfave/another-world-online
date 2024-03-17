--[=[
@class 	GameStateService
    Author: Aaron Jay (seyai_one)

    Track objectives based on config in ReplicatedStorage. Objectives can be loaded in via a module
    that fires ObjectiveModule.ObjectiveMet when conditions are met for this objective.

    Modules can contain logic to progress an objective, such as the caravan escort moving
    instantiating the caravan tween(s) internally and reporting values as such
]=]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

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

function GameStateService:KnitStart()
    print(self.GameConfig)
    local module = Modules.Objectives:FindFirstChild(self.GameConfig.ObjectiveType)
    if module then
        self.ObjectiveModule = require(module).new(self.GameConfig)
        self.ObjectiveModule.ObjectiveMet:Connect(function(status)
            if status then
                print("Completed the quota, clean up and teleport...")
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

    local gameConfig = ReplicatedStorage:WaitForChild("GameConfig")
    local config = {}
    for _, value in gameConfig:GetChildren() do
        config[value.Name] = value.Value
    end
    self.GameConfig = config
end


return GameStateService