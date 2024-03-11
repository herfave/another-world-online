--[=[
@class 	MobController
    Author: Aaron Jay (seyai_one)

]=]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(ReplicatedStorage.Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Comm setup
local ClientComm = require(Packages.Comm).ClientComm
local CombatComm = ClientComm.new(ReplicatedStorage:WaitForChild("Comms"), true, "CombatComm")
local SendMobAttack = CombatComm:GetSignal("SendMobAttack")

local MobController = Knit.CreateController({ Name = "MobController" })


function MobController:KnitStart()
    SendMobAttack:Connect(function(entityId: number, attackType: string)
        print("hello")
        local clientEntityId = Knit.GetController("MatterController"):GetClientEntityId(entityId)
        local mob = self.VisualsFolder:FindFirstChild(tostring(clientEntityId))
        print(mob)
        if mob then
            local world = Knit.GetController("MatterController"):GetWorld()
            if world:contains(clientEntityId) then
                local player = world:get(clientEntityId, Components.MobAnimations)
                player.player:PlayTrack("TestMob" .. attackType)
            end
        end
    end)
end


function MobController:KnitInit()
    self.VisualsFolder = Instance.new("Folder", workspace)
    self.VisualsFolder.Name = "MobVisuals"
    self.ServerMobs = workspace:WaitForChild("Mobs")
end


return MobController