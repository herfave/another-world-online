-- https://github.com/YetAnotherClown/Net/blob/main/example/matter/src/server/systems/replication.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.Shared.ECS.Components)
local routes = require(ReplicatedStorage.Shared.ECS.Routes)
local useEvent = require(ReplicatedStorage.Packages.Matter).useEvent

local RemotePacketSizeCounter = require(game.ReplicatedStorage.Packages.RemotePacketSizeCounter)

local REPLICATED_COMPONENTS = {
	"Owner",
	"Enemy",
	"Health",
	"Model",
	"Mob"
}

local replicatedComponents = {}

for _, name in REPLICATED_COMPONENTS do
	replicatedComponents[components[name]] = true
end

local function replication(world, _state, _ui)
	for _, player in useEvent(Players, "PlayerAdded") do
		local payload = {}

		for entityId, entityData in world do
			local entityPayload = {}
			payload[tostring(entityId)] = entityPayload

			for component, componentData in entityData do
				if replicatedComponents[component] then
					entityPayload[tostring(component)] = { data = componentData }
				end
			end
		end

		print("Sending initial payload to", player)
		routes.InitialPayloadReplication:send(payload):to(player)
	end

	local changes = {}

	for component in replicatedComponents do
		for entityId, record in world:queryChanged(component) do
			local key = tostring(entityId)
			local name = tostring(component)

			if changes[key] == nil then
				changes[key] = {}
			end

			if world:contains(entityId) then
				changes[key][name] = { data = record.new }
			end
		end
	end

	if next(changes) then -- next() returns an iterator if there are new changes, nil if none
		local allPayloads = {}
		local nextPayload = {}
		for entityId, record in changes do
			nextPayload[entityId] = record

			-- check payload size after each entity added
			local nextSize = RemotePacketSizeCounter.GetDataByteSize(nextPayload)
			if nextSize > 700 then
				-- start a new payload
				table.insert(allPayloads, nextPayload)
				nextPayload = {}
				-- print("Packet size: " .. payloadSize .. " bytes")
			end
		end

		table.insert(allPayloads, nextPayload)

		local fullSize = RemotePacketSizeCounter.GetDataByteSize(allPayloads)
		-- print("Total size (" .. #allPayloads .. "): " .. fullSize .. " bytes")
		task.spawn(function()
			for _, packet in allPayloads do
				routes.MatterReplication:send(packet)
				-- print("sent")
			end
		end)
	end
end

return {
	system = replication,
	priority = math.huge,
}