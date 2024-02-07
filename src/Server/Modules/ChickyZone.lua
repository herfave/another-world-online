--[=[
    @class ChickyZone

    Create a player zone compatible with Chickynoid that listens to player movement
]=]

local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Utils = require(Shared.Utils)
local Chickynoid = require(script.Parent.Chickynoid.Server.ServerModule)
local ChickyServer = Chickynoid.ChickynoidServer

local Packages = game.ReplicatedStorage.Packages
local Signal = require(Packages.Signal)
local Janitor = require(Packages.Janitor)

local ServerTypes = require(game.ServerStorage.Modules.ServerTypes)

local RunService = game:GetService("RunService")
local ChickyZone = {}
ChickyZone.__index = ChickyZone

--- Constructor object
--- @param zonePart BasePart Part containing the position and size for the zone
function ChickyZone.new(zonePart) : ServerTypes.ChickyZone
    local self = setmetatable({
        PlayerEntered = Signal.new();
        PlayerLeft = Signal.new();
        PlayersInside = {};
        DisplayName = zonePart:GetAttribute("DisplayName") or zonePart.Name;
        ActiveEvent = nil;
        EventCooldown = 5;

        _janitor = Janitor.new();
        _zonePart = zonePart;
    }, ChickyZone)

    self._boundCheck = RunService.PostSimulation:Connect(function()
        --// check player records against
        if ChickyServer then
            if ChickyServer.playerRecords then
                for userId, playerRecord in ChickyServer.playerRecords do
                    local player = Players:GetPlayerByUserId(userId)
                    if not player then continue end

                    local chickynoid = playerRecord.chickynoid
                    if not chickynoid then continue end
                    local simulation = playerRecord.chickynoid.simulation

                    if not simulation then continue end
                    local position = simulation.state.position
                    -- // check if player is inside
                    local playerIsInZone = Utils.isInsideBox(position, zonePart)
                    if playerIsInZone and not table.find(self.PlayersInside, player) then
                        -- player entered
                        table.insert(self.PlayersInside, player)
                        self.PlayerEntered:Fire(player, position)
                        print(player.Name .. " entered " .. zonePart.Name)
                    elseif not playerIsInZone and table.find(self.PlayersInside, player) then
                        -- player left
                        local pos = table.find(self.PlayersInside, player)
                        table.remove(self.PlayersInside, pos)
                        self.PlayerLeft:Fire(player)
                        print(player.Name .. " left " .. zonePart.Name)
                    end
                end
            end
        end
    end)
    self._janitor:Add(self._boundCheck)
    self._janitor:Add(self.PlayerEntered)
    self._janitor:Add(self.PlayerLeft)
    self._janitor:Add(function()
        table.clear(self.PlayersInside)
        self.PlayersInside = nil
    end)
    self._janitor:LinkToInstance(zonePart, false)

    return self
end

--- @return {Player} -- An array of Players currently inside the zone
function ChickyZone:GetPlayersInside(): {Player}
    return self.PlayersInside
end

--- @return string -- name of the zone
function ChickyZone:GetName(): string
    return self.DisplayName
end

--- @return {string | nil} -- 
function ChickyZone:GetEvents(): {string}
    local allParams = self._zonePart:GetChildren()
    local t = {}
    for _, p in allParams do
        table.insert(t, p.Name)
    end

    return t
end

--- @return {[string]: any} | nil -- Get event parameters stored in the zone part
function ChickyZone:GetEventParams(eventType: string): {[string]: any} | nil
    local params = self._zonePart:FindFirstChild(eventType)
    if params then
        return require(params)
    end
    warn("No params found for ".. self.DisplayName .. "/" .. eventType)
    return nil
end

function ChickyZone:StartEvent(eventType: string)

end

--- Destroys the zone
function ChickyZone:Destroy()
    self._janitor:Destroy()
end


return ChickyZone