-- create collision groups here
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

PhysicsService:RegisterCollisionGroup("Mobs")
PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)

local ServerStorage = game:GetService("ServerStorage")
local Knit = require(game.ReplicatedStorage.Packages.Knit)

Knit.AddServices(ServerStorage:WaitForChild("Services"))
Knit.Start():catch()
print('loaded knit server')