--[[
    WorldEventService.lua
    Author: Aaron Jay (se_yai)

    Description: Create and manage events that appear throughout the world
]]
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local ChickyZone = require(Modules.ChickyZone)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local WorldEventService = Knit.CreateService {
    Name = "WorldEventService";
    Client = {};
}

-- // things to get at runtime
local Locations = workspace:WaitForChild("Zones") -- should be a folder of "zones"

function WorldEventService:KnitStart()
    
    -- get all possible locations
    for _, zone in Locations:GetChildren() do
        -- // create zones and stuff here
        local newZone = ChickyZone.new(zone)
        self.Zones[zone] = newZone
    end

    RunService.Stepped:Connect(function(t, dt)

    end)
end


function WorldEventService:KnitInit()
    self.Zones = {}
    self.ActiveEvents = {}
end


return WorldEventService