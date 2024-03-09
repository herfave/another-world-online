--[=[
@class 	MobController
    Author: Aaron Jay (seyai_one)

]=]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local MobController = Knit.CreateController({ Name = "MobController" })


function MobController:KnitStart()
    
end


function MobController:KnitInit()
    self.VisualsFolder = Instance.new("Folder", workspace)
    self.VisualsFolder.Name = "MobVisuals"
    self.ServerMobs = workspace:WaitForChild("Mobs")
end


return MobController