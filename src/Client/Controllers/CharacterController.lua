--[[
    CharacterController.lua
    Author: Aaron (se_yai)

    Description: Manage character state
]]
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Promisified = require(Shared.Promisified)
local AnimationPlayer = require(Shared.AnimationPlayer)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local WaitFor = require(Packages.WaitFor)
local Janitor = require(Packages.Janitor)

local CharacterController = Knit.CreateController { Name = "CharacterController" }

function CharacterController:PlayAnimation(trackName)
    assert(self._animationPlayer:GetTrack(trackName), "Could not find animation: " .. trackName)
    self._animationPlayer:StopAllTracks()
    task.wait()
    self._animationPlayer:PlayTrack(trackName)
end

function CharacterController:KnitStart()
    LocalPlayer.CharacterAdded:Connect(function(character)
        self._janitor:Cleanup()
        local humanoid = character:WaitForChild("Humanoid")
        local controllerManager = character:WaitForChild("CharacterController")

        -- TODO: setup FSM so movedirection is only updated in moving states, not attacking states

        self._janitor:Add(require(Modules.ControllerStateMachine)(character))

        self.CharacterAddedEvent:Fire(character) -- // fire when loading the character is complete

    end)
end


function CharacterController:KnitInit()
    self._janitor = Janitor.new()
    self.CharacterAddedEvent = Signal.new() -- // Knit Controllers should connect to this event if the character is needed
end


return CharacterController