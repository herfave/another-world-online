--[=[
@class 	MatterController
    Author: Aaron Jay (seyai_one)

]=]

local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local startWorld = require(Shared.ECS.startWorld)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)
local Promise = require(Packages.Promise)

local MatterController = Knit.CreateController({ Name = "MatterController" })  




-- These functions are important because there can be a desync between item ids when replicating entities across the
-- server and client "worlds". Use them to synchronize changes, especially when sending changes to the server
-- Gets the entity id of the client world for a given server entity
function MatterController:GetClientEntityId(serverEntityId: number | string)
    if typeof(serverEntityId) == "number" then
        serverEntityId = tostring(serverEntityId)
    end
    return self._entityIdMap[serverEntityId]
end

-- Inverse of the above
function MatterController:GetServerEntityId(clientEntityId: number)
    for serverEntityId, clientId in self._entityIdMap do
        if clientId == clientEntityId then
            return tonumber(serverEntityId)
        end
    end

    return nil
end


-- Gets the current running world on the client
function MatterController:GetWorld()
    return self._world
end


-- Returns collection of enemy entity ids currently active in the world
function MatterController:GetActiveEnemies()
    return Promise.new(function(resolve)
        resolve(self._enemies)
    end)
end

function MatterController:KnitStart()
    local world, state = startWorld({
        script.Systems,
        Shared.ECS.Systems
    })

    self._world = world
end


function MatterController:KnitInit()
    self._entityIdMap = {}
    self._enemies = {}
end


return MatterController