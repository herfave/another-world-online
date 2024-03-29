local ServerStorage = game:GetService("ServerStorage")
local ServerPackages = ServerStorage:WaitForChild("Packages")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataKeep = require(ServerPackages.DataKeep)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local DATA_VERSION = 1
local DefaultData = require(ReplicatedStorage.Shared.DefaultData)

local _, keepStore = DataKeep.GetStore("PlayerData" .. tostring(DATA_VERSION), DefaultData):await()
if game:GetService("RunService"):IsStudio() then
    keepStore = keepStore.Mock
end

local PlayerContainer = {}
PlayerContainer.__index = PlayerContainer

type Container = {
    _player: Player,
    _janitor: any,
    _producer: any,
    Keep: DataKeep.Keep
}

function PlayerContainer.new(player: Player, producer)
    local self = {
        _player = player,
        _janitor = Janitor.new(),
        _producer = producer
    }
    local loadPromise = keepStore:LoadKeep("Player_" .. player.UserId)
    :andThen(function(keep)
        if keep == nil then
            player:Kick("Data locked")
            return
        end

        keep:Reconcile()
        keep:AddUserId(player.UserId)
        self.Keep = keep

        self._janitor:Add(function()
            for key, _ in keep.Data do
                -- add entity for this
                producer[`removePlayer_{key}`](player.UserId)
            end
            keep:Release()
            print("releasing..")
        end)

        -- setup Reflex listeners for all data
        for key, initialValue in keep.Data do
            -- add entity for this
            producer[`addPlayer_{key}`](player.UserId, initialValue or DefaultData[key])

            local function selectPlayerEntity(state)
                local stringId = tostring(player.UserId)
                return state[key].entities[stringId]
            end

            self._janitor:Add(producer:subscribe(selectPlayerEntity, function(current, last)
                keep.Data[key] = current
                print(`{player.UserId}.{key} = {current} <- {last}`)
            end))
        end
    end)

    setmetatable(self, PlayerContainer)
    return self, loadPromise
end

function PlayerContainer:SetData(key, value)
    self._producer[`set_{key}`](self._player.UserId, value)
end

function PlayerContainer:GetDataAtPath(originalPath)
    local path = string.split(originalPath, ".")
    local currentPoint = self.Keep.Data
    for i = 1, #path do
       if(currentPoint[path[i]]) then
            currentPoint = currentPoint[path[i]]
       else
            return nil
       end
    end

    if(currentPoint ~= self.Profile.Data) then
        return currentPoint
    end

    return nil
end

function PlayerContainer:Contains(path, id): boolean
    local data = self:GetDataAtPath(path)

    if(data) then
        if(type(data) == "table") then
            for i, v in pairs(data) do
                if(v == id) then
                    return true
                end
            end
        else
            return true
        end
    end

    return false
end

function PlayerContainer:ContainsAtLeast(path, qty): boolean
    local data = self:GetDataAtPath(path)

    if(data and type(data) == "number") then
        return data >= qty
    end

    return false
end

function PlayerContainer.Destroy(self)
    if self._janitor then
        self._janitor:Destroy()
    end
end

return PlayerContainer