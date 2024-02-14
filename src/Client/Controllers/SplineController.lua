--[[
    SplineController.lua
    Author: Aaron (se_yai)

    Description: Manage replicated data (like splines) for Chickynoid computes
]]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local SplineController = Knit.CreateController { Name = "SplineController" }


function SplineController:GetSplineRail(name)
    local spline = self._splineRails[name]
    if spline then
        return spline
    end
end

function SplineController:GetSplineCFrame(name, t)
    local spline = self:GetSplineRail(name)
    if spline then
        return spline.Spline:GetProgress(t)
    end
    return nil
end

function SplineController:GetStraightDistance(name)
    local spline = self:GetSplineRail(name)
    if spline then
        local length = 0
        local numPoints = spline.NumPoints

        for i = 1, numPoints do
            local t1 = (i - 1) / (numPoints)
            local t2 = i / numPoints

            local p1 = spline.Spline:GetProgress(t1).Position
            local p2 = spline.Spline:GetProgress(t2).Position
            length += (p1 - p2).Magnitude
        end


        return length
    end
    return 100
end

-- function SplineController:GetStraightDistance(name)
--     return (
--         self:GetSplinePosition(name, 0) -
--         self:GetSplinePosition(name, 1)
--     ).Magnitude
-- end

function SplineController:KnitStart()
    local gameArea = workspace:WaitForChild("GameArea")
    self._splineRails = {}
    -- build spline things before calculating collisions
    local GenerateSpline = require(ReplicatedStorage.Shared.GenerateSpline)
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

    print("Loaded SplineController")
end


function SplineController:KnitInit()
end


return SplineController