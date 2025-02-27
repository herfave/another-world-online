-- create collision groups here
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:RegisterCollisionGroup("Players")
PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

PhysicsService:RegisterCollisionGroup("Mobs")
PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)
PhysicsService:CollisionGroupSetCollidable("Players", "Mobs", false)


PhysicsService:RegisterCollisionGroup("MobCapsule")
PhysicsService:CollisionGroupSetCollidable("MobCapsule", "Default", false)
PhysicsService:CollisionGroupSetCollidable("MobCapsule", "Mobs", false)
PhysicsService:CollisionGroupSetCollidable("MobCapsule", "Players", false)


PhysicsService:RegisterCollisionGroup("MobWalls")
PhysicsService:CollisionGroupSetCollidable("MobWalls", "Players", false)
PhysicsService:CollisionGroupSetCollidable("MobWalls", "Mobs", true)
PhysicsService:CollisionGroupSetCollidable("MobWalls", "MobCapsule", false)

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

local STPlayerRegistry = SharedTable.new()
SharedTableRegistry:SetSharedTable("PLAYER_REGISTRY", STPlayerRegistry)

Knit.AddServices(ServerStorage:WaitForChild("Services"))
Knit.Start():catch()
print('loaded knit server')