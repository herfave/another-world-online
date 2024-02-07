--[[
    UIController.lua
    Author: Aaron (se_yai)

    Description: Manage UI states and display
]]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local UIController = Knit.CreateController { Name = "UIController" }

function UIController:ToggleScreenState(screen: string, state: boolean)
    -- if screen hasn't been mounted/created yet, do that first
    -- set visbility by toggling now
end

function UIController:KnitStart()
    -- mount initial screens
    
end


function UIController:KnitInit()
    
end


return UIController