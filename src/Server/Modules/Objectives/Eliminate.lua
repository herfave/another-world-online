--[=[
    Elimination objective

    The objective is cleared when the group meets an enemies killed quota.
    The most simple of objectives
]=]

local Signal = require(game.ReplicatedStorage.Packages.Signal)
local Knit = require(game.ReplicatedStorage.Packages.Knit)

local module = {}
module.__index = module

function module.new(gameConfig: {[string]: any})
    local self = {
        Quota = gameConfig.Quota,
        Current = 0,
        ObjectiveMet = Signal.new(),
        Completed = false,
    }

    local enemyKilledSignal =  Knit.GetService("GameStateService").EnemyKilled
    enemyKilledSignal:Connect(function(entityId: number, mobType: string, killedBy: number)
        self.Current += 1

        if self.Current >= self.Quota and not self.Completed then
            self.Completed = true
            self.ObjectiveMet:Fire(true)
            print("Completed?!")
        end
        print(`Objective updated: {self.Current}/{self.Quota}`)
    end)

    return setmetatable(self, module)
end

function module:GetObjective()
    return self.Quota
end

function module:GetCurrent()
    return self.Current
end

return module