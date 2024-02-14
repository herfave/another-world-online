--[[
    CharacterController.lua
    Author: Aaron (se_yai)

    Description: Manage character state
]]
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local SpeedLines = Assets:WaitForChild("SpeedLines")

local ChickyClient = require(ReplicatedFirst.Chickynoid.Client.ClientModule)
local ClientMods = require(ReplicatedFirst.Chickynoid.Client.ClientMods)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local WaitFor = require(Packages.WaitFor)
local Keyboard = require(Packages.Input).Keyboard
local Janitor = require(Packages.Janitor)

local ClientComm = require(Packages.Comm).ClientComm
local ChickynoidComm = ClientComm.new(ReplicatedStorage:WaitForChild("Comms"), true, "ChickynoidComm")

local CharacterController = Knit.CreateController { Name = "CharacterController" }

function CharacterController:GetSimulation()
    if not self.localChickynoid then
        -- warn("Could not get localChickynoid simulation")
        return nil
    end

    return self.localChickynoid.simulation
end

function CharacterController:GetDummyCharacters()
    if not ChickyClient.characters then return end
    local dummies = {}
    for id, character in ChickyClient.characters do
        if id < 0 then
            table.insert(dummies, character)
        end
    end

    return dummies
end

function CharacterController:KnitStart()
    -- --// register mods
    ClientMods:RegisterMods("clientmods", ReplicatedFirst.ClientChickyMods.ClientMods)
    ClientMods:RegisterMods("characters", ReplicatedFirst.ClientChickyMods.Characters)
    ClientMods:RegisterMods("weapons", ReplicatedFirst.ClientChickyMods.Weapons)

    --// setup the client
    ChickyClient:Setup()
    

    -- // TODO: change to when chickynoid character is initialized
    repeat
        task.wait()
        -- print("waiting for client")
    until ChickyClient.localChickynoid ~= nil

    self.localChickynoid = ChickyClient.localChickynoid

    self.ChickynoidAddedEvent:Fire(self.localChickynoid)

    self.Keyboard = Keyboard.new()
    -- self.Keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
    --     if key == Enum.KeyCode.Y then
    --     end
    -- end)
end

function CharacterController:KnitInit()
    self.speedJanitor = Janitor.new()
    self.ChickynoidAddedEvent = Signal.new() -- // Knit Controllers should connect to this event if the character is needed
end


return CharacterController