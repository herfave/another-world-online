--[=[
@class 	CameraController
    Author: Aaron Jay (seyai_one)

]=]
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")
local OTSCamera = require(Modules.OTSCamera)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local ChickyClient = require(game:GetService("ReplicatedFirst").Chickynoid.Client.ClientModule)

local CameraController = Knit.CreateController({ Name = "CameraController" })


function CameraController:KnitStart()
    LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 3)
        if humanoid then
            OTSCamera:Enable()
        end
    end)
    -- ChickyClient.OnCharacterModelCreated:Connect(function(characterModel)
    --     if characterModel.userId == LocalPlayer.UserId then
    --         OTSCamera:Enable()
    --     end
    -- end)
end


function CameraController:KnitInit()
    
end


return CameraController