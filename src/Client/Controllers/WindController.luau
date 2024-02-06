--[[
    WindController.lua
    Author: Aaron (se_yai)

    Description: Manage player spawning and interactions with the server involving data
]]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local WindController = Knit.CreateController { Name = "PackagesWindController" }


function WindController:KnitStart()
    -- local wind = require(game.ReplicatedStorage.Shared.WindService).new({
    --     Randomized = true,
    --     Amount = 5,
    --     Lifetime = 3,
    --     Velocity = Vector3.new(-0.45, 0, -0.45),
    --     -- Time = tick(),
    -- })
    -- wind:Start()
end


function WindController:KnitInit()
    
end


return WindController