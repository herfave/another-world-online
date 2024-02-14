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

-- register shared tables
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local STMobPosition = SharedTable.new({})
SharedTableRegistry:SetSharedTable("MOB_POSITION", STMobPosition)

local STEnemyRegistry = SharedTable.new({})
SharedTableRegistry:SetSharedTable("ENEMY_REGISTRY", STEnemyRegistry)

local STEnemyCommands = SharedTable.new()
SharedTableRegistry:SetSharedTable("ENEMY_COMMANDS", STEnemyCommands)

Knit.AddServices(ServerStorage:WaitForChild("Services"))
Knit.Start():catch()
print('loaded knit server')