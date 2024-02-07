--[[
    RaceEvent.luau
    Author: seyai_one (Aaron)

    Create an BaseEvent object with RaceEvent specifics
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Shared.Utils)
local Knit = require(ReplicatedStorage.Packages.Knit)
local ChickynoidService = Knit.GetService("ChickynoidService")

local Modules = game:GetService("ServerStorage").Modules
local BaseEvent = require(Modules.BaseEvent)
local RaceEvent = {}
RaceEvent.__index = RaceEvent

function RaceEvent.new(params, zone)
    local self = setmetatable(BaseEvent.new(params, zone), RaceEvent)
    self._janitor:Add(function()
        self = nil
    end)

    self.FinishingPlaces = {}

    --// select from a destination
    local dests: {BasePart} = params.Destinations
    local endPoint: BasePart = dests[math.random(1, #dests)]
    self.EndPoint = endPoint --// TODO: get zone information using this? idk
    self.DestPos = endPoint.Position


    CollectionService:AddTag(zone._zonePart, "RaceEvent")
    self._janitor:Add(function()
        CollectionService:RemoveTag(zone._zonePart, "RaceEvent")
    end)

    return self
end

function RaceEvent:Reward()
    
end

function RaceEvent:Update(dt)
    self._update(dt)
    --// check required players vs players inside
    if self.Active then
        for _, player in self.OptedIn do
            if not table.find(self.FinishingPlaces, player) then
                local simulation = ChickynoidService:GetPlayerSimulation(player)
                local currentDistance = (simulation.state.position - self.DestPos).Magnitude
                
                if Utils.isInsideBox(simulation.state.position, self.EndPoint) then
                    table.insert(self.FinishingPlaces, player)
                    local place = #self.FinishingPlaces
                    warn(player.Name .. " finished #" .. tostring(place))
                end
            end
        end
    end

end


return RaceEvent