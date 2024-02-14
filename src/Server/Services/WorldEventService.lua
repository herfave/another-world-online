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
local Timer = require(Packages.Timer)

local RANDOM = Random.new(os.time())

local WorldEventService = Knit.CreateService {
    Name = "WorldEventService";
    Client = {};
}

-- // things to get at runtime
local Locations = workspace:WaitForChild("Zones") -- should be a folder of "zones"
local EVENT_COOLDOWN = 5

function WorldEventService:KnitStart()
    
    -- get all possible locations
    for _, zonePart in Locations:GetChildren() do
        -- // create zones and stuff here
        local newZone = ChickyZone.new(zonePart)
        self.Zones[zonePart] = newZone
    end

    --// create an event object that updates with the main loop
    local INTERVAL = 1/20
    local currentTime = tick()
    Timer.Simple(INTERVAL, function() --// only need to updated 20hz
        local t = tick()
        local dt = t - currentTime
        currentTime = t
        for zonePart, zone in self.Zones do
            -- // if no event running, select an active event
            local events = zone:GetEvents()
            if #events > 0 and zone.ActiveEvent == nil then
                if zone.EventCooldown > 0 then
                    zone.EventCooldown -= dt
                    -- print(zone.DisplayName .. " event cooldown: " .. tostring(zone.EventCooldown))
                else
                    -- // pick a random event and instantiate the object
                    local nextEvent = events[RANDOM:NextInteger(1, #events)]
                    local eventClass = Modules.Events:FindFirstChild(nextEvent .. "Event")
                    local eventParams = zone:GetEventParams(nextEvent)
                    if eventClass and eventParams then
                        local newEvent = require(eventClass).new(eventParams, zone)
                        zone.ActiveEvent = newEvent
                        warn(zone.DisplayName .. " started a " .. nextEvent .. " event!")
                    end
                end
            elseif zone.ActiveEvent then
                if zone.ActiveEvent.Finished then
                    zone.ActiveEvent._janitor:Destroy()
                    zone.ActiveEvent = nil
                    zone.EventCooldown = EVENT_COOLDOWN
                    print("Event finished!")
                else
                    zone.ActiveEvent:Update(dt)
                end
            end
        end
    end)
end


function WorldEventService:KnitInit()
    self.Zones = {}
    self.ActiveEvents = {}
end


return WorldEventService