--[[
    PhoneController.lua
    Author: Aaron (se_yai)

    Description: Manages the Phone UI menu, mounting and feeding state
]]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local PhoneController = Knit.CreateController { Name = "PhoneController" }


function PhoneController:KnitStart()
    
end


function PhoneController:KnitInit()
    
end


return PhoneController