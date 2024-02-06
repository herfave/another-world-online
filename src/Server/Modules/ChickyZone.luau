--[=[
    @class ChickyZone

    Create a player zone compatible with Chickynoid that listens to player movement
]=]

local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Utils = require(Shared.Utils)
local Chickynoid = require(Shared.Chickynoid)
local ChickyServer = Chickynoid.ChickynoidServer

local Packages = game.ReplicatedStorage.Packages
local Signal = require(Packages.Signal)
local Janitor = require(Packages.Janitor)

local RunService = game:GetService("RunService")
local ChickyZone = {}
ChickyZone.__index = ChickyZone

--- Constructor object
--- @param zonePart BasePart Part containing the position and size for the zone
function ChickyZone.new(zonePart)
    local self = setmetatable({}, ChickyZone)
    self._janitor = Janitor.new()
    self.PlayerEntered = Signal.new()
    self.PlayerLeft = Signal.new()    
    self.PlayersInside = {}
    self._zonePart = zonePart

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
                    local position = simulation.state.pos
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
function ChickyZone:GetPlayersInside()
    return self.PlayersInside
end

--- Destroys the zone
function ChickyZone:Destroy()
    self._janitor:Destroy()
end


return ChickyZone