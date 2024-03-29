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

function DataController:GetProducer()
    return self.Producer
end

function DataController:GetData(key: string)
    local state = self.Producer:getState()
    local stringId = tostring(LocalPlayer.UserId)
    
    return state[key][stringId]
end

function DataController:KnitStart()
    print("Keep loaded")
    local _producer, _slices = BuildDataProducer()
    local receiver = Reflex.createBroadcastReceiver({
        start = function()
            print("Started receiver")
            Knit.GetService("PlayerService").ReceiveReady:Fire()
        end
    })

    local first = true
    Knit.GetService("PlayerService").TransmitData:Connect(function(actions)
        receiver:dispatch(actions)
        if first then
            first = false
            self.ProducerLoaded:Fire()
            print("Received first dispatch")
        end
    end)

    Knit.GetService("PlayerService").LoadedKeep:Connect(function()
        print("Keep loaded locally, starting receiver")
        _producer:applyMiddleware(receiver.middleware)
        self.Producer = _producer
    end)
end


function DataController:KnitInit()
    self.Events = {}
    self.ReplicaFoundSignal = Signal.new()
    self._listeningToReplica = false
    self.ProducerLoaded = Signal.new()
end


return DataController