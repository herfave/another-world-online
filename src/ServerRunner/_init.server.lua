-- create collision groups here
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

PhysicsService:RegisterCollisionGroup("Mobs")
PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)

PhysicsService:RegisterCollisionGroup("MobCapsule")
PhysicsService:CollisionGroupSetCollidable("MobCapsule", "Default", false)
PhysicsService:CollisionGroupSetCollidable("MobCapsule", "Mobs", false)

local ServerStorage = game:GetService("ServerStorage")
local Knit = require(game.ReplicatedStorage.Packages.Knit)


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