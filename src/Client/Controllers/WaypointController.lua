--[[
    WaypointController.lua
    Author: Aaron (se_yai)

    Description: Manage and display waypoints throughout the world
]]
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local WaypointController = Knit.CreateController { Name = "WaypointController" }

function WaypointController:AddWaypoint(positionOrInstance : Vector3 | BasePart, name: string)
    if self.Waypoints[name] then
        -- clear out old one
        self.Waypoints[name]:Destroy()
        self.Waypoints[name] = nil
    end
    
    local waypoint = typeof(positionOrInstance) == "Instance" and positionOrInstance or nil
    if not waypoint and typeof(positionOrInstance) == "Vector3" then -- create a new waypoint if just a position
        waypoint = Instance.new("Part")
        waypoint.Anchored = true
        waypoint.Position = positionOrInstance
        waypoint.Size = Vector3.new(1,1,1)
        waypoint.Transparency = 1
        waypoint.CanCollide = false
        waypoint.Parent = self.WaypointBox
    end
    
    CollectionService:AddTag(waypoint, "Waypoint")
    self.Waypoints[name] = waypoint
end

function WaypointController:KnitStart()
    
end


function WaypointController:KnitInit()
    self.Waypoints = {}
    self.WaypointBox = Instance.new("Folder")
    self.WaypointBox.Parent = workspace
    self.WaypointBox.Name = "Waypoints"
end


return WaypointController