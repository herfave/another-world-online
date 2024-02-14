--[[
    BaseEvent.luau
    Author: seyai_one (Aaron)

    Create an event object that tracks active players, event duration, and progress
]]
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)

local ServerTypes = require(ServerStorage.Modules.ServerTypes)

local BaseEvent = {}
BaseEvent.__index = BaseEvent

function BaseEvent.new(params, zone) : ServerTypes.EventObject
    local self = setmetatable({
        OptedIn = {},
        OptedOut = {},
        EventParams = params,
        Active = false,
        Finished = false,
        EventStateSignal = Signal.new(),
        Duration = params.Duration,

        _zone = zone,
        _janitor = Janitor.new(),
    }, BaseEvent)

    
    --// prompt all current players, then prompt for new entries
    local function promptPlayer(player: Player)
        --// TODO: prompt stuff
        table.insert(self.OptedIn, player)
        print("oped in " .. player.Name)
    end
    
    for _, player in zone.PlayersInside do
        promptPlayer(player)
    end

    self._janitor:Add(zone.PlayerEntered:Connect(function(player: Player, position: Vector3)
        if not table.find(self.OptedIn, player)
        and not table.find(self.OptedOut, player) then
            promptPlayer(player)
        end
    end))

    self._janitor:Add(function()
        self = nil
    end)

    CollectionService:AddTag(zone._zonePart, "Waypoint")

    function self._update(dt)
        if #self.OptedIn >= self.EventParams.PlayerReq
        and not self.Active
        and not self.Finished then
            -- // set to active
            self.Active = true
            self.EventStateSignal:Fire("Start")       
        elseif self.Active then
            if self.Duration > 0 then
                -- // count down
                self.Duration -= dt
                print(self.Duration)
            else
                -- // event ended, force ending
                self.Active = false
                self.Finished = true
                self.EventStateSignal:Fire("Finished")
            end
        end
    end

    return self
end

return BaseEvent