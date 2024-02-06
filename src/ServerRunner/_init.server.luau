local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Shared.Ragdoll.RagdollHandler)

-- create collision groups here
game:GetService("PhysicsService"):RegisterCollisionGroup("Players")
game:GetService("PhysicsService"):CollisionGroupSetCollidable("Players", "Players", false)

local Comms = Instance.new("Folder")
Comms.Name = "Comms"
Comms.Parent = ReplicatedStorage

local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(ServerStorage:WaitForChild("Services"))
Knit.Start():catch()
print('loaded knit server')