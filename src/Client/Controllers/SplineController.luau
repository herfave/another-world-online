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

local GameArea = workspace:WaitForChild("GameArea")

local SplineController = Knit.CreateController { Name = "SplineController" }


function SplineController:GetSplineRail(name)
    local spline = self._splineRails[name]
    if spline then
        return spline
    end
end

function SplineController:GetSplinePosition(name, t)
    local spline = self:GetSplineRail(name)
    if spline then
        return spline.Spline:CalculatePositionRelativeToLength(t)
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

            local p1 = spline.Spline:CalculatePositionRelativeToLength(t1)
            local p2 = spline.Spline:CalculatePositionRelativeToLength(t2)
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
    
end


function SplineController:KnitInit()
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

    print("Loaded SplineController")
end


return SplineController