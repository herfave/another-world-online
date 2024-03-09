local Net = require(game.ReplicatedStorage.Packages.Net)
local RemotePacketSizeCounter = require(game.ReplicatedStorage.Packages.RemotePacketSizeCounter)

local Components = require(game.ReplicatedStorage.Shared.ECS.Components)


local Route = Net.Route
type Route<U...> = Net.Route<U...>

local defaultConfig = {
    Channel = "Reliable",
    Event = "default",
}

local mainConfig = {
    Channel = "Unreliable",
    Event = "default",
}

type EntityPayload = {
    [string]: {
        [string]: {
            data: ComponentInstance<T>
        }
    }
}

local InitialPayloadReplication: Route<EntityPayload> = Route.new(defaultConfig)
local MatterReplication: Route<EntityPayload> = Route.new(mainConfig)

-- local payloadLayout = CrunchTable:CreateLayout()
-- pay

local function serializePayload(payload)
    -- serialize component names
    local serializedPayload = {}
    for entityId, entityPayload in payload do
        serializedPayload[entityId] = {}
        for componentName, componentData in entityPayload do
            local componentIndex = table.find(Components._componentNames, componentName)
            if not componentIndex then warn("bad component!! " .. componentName) continue end
            
            if not componentData.data then
                serializedPayload[entityId][tostring(componentIndex)] = componentData
            else
                local serializedData = {}
                -- TODO: compact this
                for valueName, value in componentData.data do
                    local valueIndex = table.find(Components._commonValues, valueName)
                    if not valueIndex then warn("bad value!! " .. valueName) continue end

                    serializedData[tostring(valueIndex)] = value
                end

                serializedPayload[entityId][tostring(componentIndex)] = { ["1"] = serializedData }
            end
        end
    end

    -- debug byte sizes
    -- local rawSize = RemotePacketSizeCounter.GetDataByteSize(payload)
    -- local serialSize = RemotePacketSizeCounter.GetDataByteSize(serializedPayload)
    -- print("Raw: " .. rawSize .. " bytes")
    -- print(payload)
    -- print("Serialized: " .. serialSize .. " bytes")
    -- print(serializedPayload)
    return serializedPayload
end

local function deserializePayload(payload)
    -- deserialize component names
    local deserializedPayload = {}
    for entityId, entityPayload in payload do
        deserializedPayload[entityId] = {}
        for serializedComponent, componentData in entityPayload do
            local componentIndex = tonumber(serializedComponent)
            local componentName = Components._componentNames[componentIndex]
            if not componentName then warn("couldn't deserialize index: " .. serializedComponent) end

            if not componentData["1"] then
                deserializedPayload[entityId][componentName] = componentData
            else
                local deserializedData = {}
                for serializedValue, value in componentData["1"] do
                    -- print(valueName, value)
                    local valueIndex = tonumber(serializedValue)
                    if not valueIndex then warn("couldn't deserialize value: " .. serializedValue) continue end

                    local valueName = Components._commonValues[valueIndex]
                    deserializedData[valueName] = value
                end

                deserializedPayload[entityId][componentName] = { data = deserializedData }
            end
        end
    end
    return deserializedPayload
end

MatterReplication:addOutgoingMiddleware(serializePayload)
MatterReplication:addIncomingMiddleware(deserializePayload)

InitialPayloadReplication:addOutgoingMiddleware(serializePayload)
InitialPayloadReplication:addIncomingMiddleware(deserializePayload)

return {
    MatterReplication = MatterReplication,
    InitialPayloadReplication = InitialPayloadReplication,
}