--[[
    DataController.lua
    Author: Aaron Jay (seyai)
    17 June 2021
    
    Stores and manages PlayerData Replica, listening to changes that can then be
    relayed to other controllers on the client
]]
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local Modules = PlayerScripts:WaitForChild("Modules")

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildDataProducer = require(Shared.BuildDataProducer)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Reflex = require(Packages.Reflex)

local DataController = Knit.CreateController { Name = "DataController" }

-- // Knit Singletons

function DataController:GetData(key: string)
    local state = self.Producer:getState()
    local stringId = tostring(LocalPlayer.UserId)
    
    return state[key].entities[stringId]
end

function DataController:KnitStart()
    local _producer, _slices = BuildDataProducer()
    local receiver = Reflex.createBroadcastReceiver({
        start = function()
            Knit.GetService("PlayerService").ReceiveReady:Fire()
        end
    })

    Knit.GetService("PlayerService").TransmitData:Connect(function(actions)
        receiver:dispatch(actions)
    end)

    _producer:applyMiddleware(receiver.middleware)
    self.Producer = _producer

    task.wait(2)
end


function DataController:KnitInit()
    self.Events = {}
    self.ReplicaFoundSignal = Signal.new()
    self._listeningToReplica = false
end


return DataController