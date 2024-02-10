--[=[
@class 	MatterService
    Author: Aaron Jay (seyai_one)

    Contain and manage the game world, systems and entities.
    Allows for the rest of the Knit ecosystem to interface and interact with the
    game's existing Matter world, such as spawning new entities and setting
    component values.
]=]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local startWorld = require(Shared.ECS.startWorld)
local Components = require(Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Matter = require(Packages.Matter)


local MatterService = Knit.CreateService({
    Name = "MatterService";
    Client = {
        ClientModelReady = Knit.CreateSignal()
    };
})

function MatterService.Client:GetEntityComponent(player, id, componentName)
    local world = self.Server._world
    if world:contains(id) then
        return world:get(id, Components[componentName])
    end
    return nil
end

function MatterService:GetEntityByName(name : string) : number
    if self._namedEntities[name] then
        return self._namedEntities[name]
    end

    return -1 -- no entity
end

function MatterService:CreateEntity(defaultComponents, name : string?) : number
    local newEntity = self._world:spawn(table.unpack(defaultComponents))
    if name then
        self._namedEntities[name] = newEntity
    end

    print("Created new entity", newEntity, defaultComponents)
    return newEntity
end

function MatterService:RemoveEntity(entityId : number)
    if self._world:contains(entityId) then
        self._world:despawn(entityId)
    end
end

function MatterService:AddComponent(id, componentName, defaultValues)
    self._world:insert(id, Components[componentName](defaultValues))
end

function MatterService:ResetWorld()
    for towerId in self._world:query(Components.Tower) do
        self._world:despawn(towerId)
    end

    for enemyId in self._world:query(Components.Enemy) do
        self._world:despawn(enemyId)
    end
end

function MatterService:GetWorld()
    return self._world
end

function MatterService:KnitStart()
    local world, state = startWorld({
        script.Systems,
        Shared.ECS.Systems
    })
    self._world = world

    -- set ready status for entities
    self.Client.ClientModelReady:Connect(function(player, entityId)
        if world:contains(entityId) then
            world:insert(entityId, Components.ClientReady { value = true })
        end
    end)

    -- create entity for player joins, then wait for a corresponding player record to appear
    -- then map the two
    local function playerAdded(player)
        local playerEntityId = self:CreateEntity({
            Components.Owner { userid = player.UserId },
            Components.Player { name = player.DisplayName, user = player.Name },
            Components.Position { value = Vector3.zero }
        })

        -- wait for chickynoid playerrecord
        Knit.GetService("ChickynoidService"):GetPlayerRecord(player, true):andThen(function(record)
            self._entityIdChickynoidMap[player.UserId] = {
                EntityId = playerEntityId,
                Record = record
            }
        end):catch(warn)
    end

    for _, player in game.Players:GetPlayers() do
        playerAdded(player)
    end
    game.Players.PlayerAdded:Connect(playerAdded)

    game.Players.PlayerRemoving:Connect(function(player)
        self._entityIdChickynoidMap[player.UserId] = nil
    end)

    -- update player positions

    game:GetService("RunService").PostSimulation:Connect(function()
        for userId, map in self._entityIdChickynoidMap do
            if not world:contains(map.EntityId) then continue end -- deal with this later
            local position = world:get(map.EntityId, Components.Position)
            if position then
                -- print(map.Record)
                if map.Record.chickynoid then
                    local recordPos = map.Record.chickynoid.simulation.state.position
                    world:insert(map.EntityId, position:patch({
                        value = recordPos
                    }))
                end
            end
        end
    end)
end


function MatterService:KnitInit()
    self._namedEntities = {}

    self._entityIdChickynoidMap = {}
end


return MatterService