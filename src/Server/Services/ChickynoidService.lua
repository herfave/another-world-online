--[[
    ChickynoidService.lua
    Author: Aaron Jay (se_yai)

    Description: Interface with Chickynoid for the rest of the project
]]
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GenerateSpline = require(ReplicatedStorage.Shared.GenerateSpline)
local ChickyServer = require(Modules.Chickynoid.Server.ServerModule)
local ServerMods = require(Modules.Chickynoid.Server.ServerMods)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Promise = require(Packages.Promise)


local ChickynoidService = Knit.CreateService({
	Name = "ChickynoidService",
	Client = {},
})

local DEBUG = true

function ChickynoidService:GetSplineRail(name)
	local spline = self._splineRails[name]
	if spline then
		return spline
	end
end

function ChickynoidService:GetSplineCFrame(name, t)
	local spline = self:GetSplineRail(name)
	if spline then
		return spline.Spline:GetProgress(t)
	end
	return nil
end

function ChickynoidService:GetStraightDistance(name)
	local spline = self:GetSplineRail(name)
	if spline then
		local length = 0
		local numPoints = spline.NumPoints

		for i = 1, numPoints do
			local t1 = (i - 1) / numPoints
			local t2 = i / numPoints

			local p1 = spline.Spline:GetProgress(t1).Position
			local p2 = spline.Spline:GetProgress(t2).Position
			length += (p1 - p2).Magnitude
		end

		return length
	end
	return 100
end

--- Returns a Promise that resolves with a given player's simulation or rejects with an error message
function ChickynoidService:GetPlayerSimulation(player: Player | number)
	return Promise.new(function(resolve, reject)
		local userId = typeof(player) == "number" and player or player.UserId
		local simulation = nil
		-- search for the player sim
		if ChickyServer then
			if ChickyServer.playerRecords then
				local playerRecord = ChickyServer.playerRecords[userId]
				if playerRecord then
					if playerRecord.chickynoid then
						simulation = playerRecord.chickynoid.simulation
					end
				end
			end
		end

		-- if the simulation is found, resolve promise, else reject with nil
		if simulation then
			resolve(simulation)
		else
			reject("Could not get player simulation for " .. tostring(player))
		end
	end)
end

function ChickynoidService:GetPlayerRecord(player: Player | number, retry : boolean | nil)
	return Promise.new(function(resolve, reject)
		local userId = typeof(player) == "number" and player or player.UserId
		-- search for the player sim
		local record = nil
		local function search()
			if ChickyServer then
				if ChickyServer.playerRecords then
					local playerRecord = ChickyServer.playerRecords[userId]
					if playerRecord then
						if playerRecord.chickynoid then
							return playerRecord
						end
					end
				end
			end
		end

		record = search()
		if not record and retry then
			repeat
				task.wait(0.1)
				record = search()
			until record
		end

		if record then
			resolve(record)
			return
		end

		reject("Could not get player record")
	end)
end

--- Damages the player by a given amount, then returns the player's new health and old health, in that order
--  Also useful for healing
function ChickynoidService:DamagePlayer(player: Player | number, damage: number)
	local userId = typeof(player) == "number" and player or player.UserId
	local newHealth, oldHealth = 0, 0
	if ChickyServer then
		if ChickyServer.playerRecords then
			local playerRecord = ChickyServer.playerRecords[userId]
			if playerRecord then
				local HitPoints = ServerMods:GetMod("servermods", "Hitpoints")
				if HitPoints then
					newHealth = HitPoints:GetPlayerHitPoints(playerRecord)
					oldHealth = newHealth
					if playerRecord.chickynoid then
						HitPoints:DamagePlayer(playerRecord, damage)
						newHealth = oldHealth - damage
					end
				end
			end
		end
	end

	return newHealth, oldHealth
end

--- Move players to a target Vector3, will visually see them interpolate there
function ChickynoidService:MovePlayersTo(players: {Player}, location: Vector3)
	for _, player in players do
		local simulation = self:GetPlayerSimulation(player)
		if simulation then
			simulation:SetPosition(location + Vector3.new(0, 3, 0))
		end
	end
end

--- Get current position of player
function ChickynoidService:GetPosition(player: Player | number)
	local position = nil
	self:GetPlayerSimulation(player)
		:andThen(function(simulation)
			position = simulation.state.positionition
		end)
		:catch(warn)

	return position
end

function ChickynoidService:GetChickynoid()
	return ChickyServer
end

function ChickynoidService:KnitStart()
	if not DEBUG then
		local debugs = CollectionService:GetTagged("Debug")
		for _, v in debugs do
			v:Destroy()
		end
	end

	-- listen to changes in simulations here!
	RunService.PostSimulation:Connect(function()
		--- Example from previous project on how to listen for changes to simulation state

		for userId, playerRecord in ChickyServer.playerRecords do
			local simulation = playerRecord.simulation
			if not simulation then continue end
			if not simulation.state.didTrick then
				simulation.state.didTrick = 0
			end

			if simulation.state.trick > 0 and simulation.state.didTrick == 0 then
				simulation.state.didTrick = 1
				print("caught a trick!", simulation.state.lastTrick)
			end
		end

	end)

	game.Players.PlayerAdded:Connect(function(player)
		local nextRail = Instance.new("ObjectValue")
		nextRail.Name = "NextRail"
		nextRail.Parent = player
	end)
end

function ChickynoidService:KnitInit()
	local gameArea = workspace:FindFirstChild("GameArea")
	if not gameArea then
		warn("No 'GameArea' found in workspace. ChickynoidService will not initialise.")
		return
	end
	-- setup events to connect to Chickynoid
	self.ChangeMoveset = Signal.new()
	self.PrintDebug = Signal.new()
	self._simulations = {}

	self._splineRails = {}
	-- build spline things before calculating collisions
	local splineRails = workspace:WaitForChild("SplineRails", 3)
	if splineRails then
		for _, splineModule in splineRails:GetChildren() do
			local newSpline = GenerateSpline(
				splineModule.Name,
				splineModule,
				workspace.RailVis
			)
			self._splineRails[splineModule.Name] = newSpline
		end
	end

	ChickyServer:RecreateCollisions(gameArea)

	ServerMods:RegisterMods("servermods", Modules.ServerChickyMods)
	ServerMods:RegisterMods("characters", ReplicatedFirst.ClientChickyMods.Characters)
	ServerMods:RegisterMods("weapons", ReplicatedFirst.ClientChickyMods.Weapons)

	print("Initialized ChickynoidService. Waiting for ChickyServer...")
	task.wait()
  ChickyServer:Setup()
	print("Done.")
end


return ChickynoidService