--[[
    ChickynoidService.lua
    Author: Aaron Jay (se_yai)

    Description: 
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Chickynoid = require(Shared.Chickynoid)
local ChickyServer = Chickynoid.ChickynoidServer
local ServerMods = Chickynoid.ServerMods

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local GameArea = workspace:WaitForChild("GameArea")

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

function ChickynoidService:GetSplinePosition(name, t)
	local spline = self:GetSplineRail(name)
	if spline then
		return spline.Spline:CalculatePositionRelativeToLength(t)
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

			local p1 = spline.Spline:CalculatePositionRelativeToLength(t1)
			local p2 = spline.Spline:CalculatePositionRelativeToLength(t2)
			length += (p1 - p2).Magnitude
		end

		return length
	end
	return 100
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
end

function ChickynoidService:KnitInit()
	-- setup events to connect to Chickynoid
	self.ChangeMoveset = Signal.new()
	self.PrintDebug = Signal.new()
	self._simulations = {}

	self._splineRails = {}
	-- build spline things before calculating collisions
	local GenerateSpline = require(ReplicatedStorage.Shared.GenerateSpline)
	local splineRails = workspace:WaitForChild("SplineRails", 3)
	if splineRails then
		for _, pointsFolder in splineRails:GetChildren() do
			local points = {}

			-- order the points properly
			for i = 1, #pointsFolder:GetChildren() do
				local p = pointsFolder:FindFirstChild("P" .. i)
				if p then
					table.insert(points, p)
				else
					warn("Could not find P" .. tostring(i) .. "for " .. pointsFolder.Name)
					break
				end
			end

			-- do not generate spline if the spline is broken
			if #points < #pointsFolder:GetChildren() then
				continue
			end

			local newSpline = GenerateSpline(
				pointsFolder.Name,
				points,
				GameArea.FlowParts.Splines,
				pointsFolder:GetAttribute("Tension")
			)
			self._splineRails[pointsFolder.Name] = newSpline
		end
	end

	ChickyServer:RecreateCollisions(GameArea)

	ServerMods:RegisterMods("servermods", Modules:WaitForChild("ServerChickyMods"))
	ServerMods:RegisterMods("characters", ReplicatedFirst.ClientChickyMods.Characters)
	ServerMods:RegisterMods("weapons", ReplicatedFirst.ClientChickyMods.Weapons)

	task.wait()
    ChickyServer:Setup()
end


return ChickynoidService