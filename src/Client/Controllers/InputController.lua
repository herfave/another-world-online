--[=[
@class 	InputController
    Author: Aaron Jay (seyai_one)

]=]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local PreferredInput = require(Packages.Input).PreferredInput
local Mouse = require(Packages.Input).Mouse

local InputController = Knit.CreateController({ Name = "InputController" })


function InputController:KnitStart()
    self.Mouse = Mouse.new()

    -- listen to and handle changes to preferred input type, ui state updates etc.
    self.CurrentType = PreferredInput.Current
    local disconnect = PreferredInput.Observe(function(pref)
        self.CurrentType = pref
    end)

    self.Mouse.LeftDown:Connect(function()
        Knit.GetController("CharacterController").AttackEvent:Fire()
    end)
end


function InputController:KnitInit()
    
end


return InputController