local ReplicatedStorage = game:GetService("ReplicatedStorage")
local components = require(ReplicatedStorage.Shared.ECS.Components)
local routes = require(ReplicatedStorage.Shared.ECS.Routes)

local Knit = require(game.ReplicatedStorage.Packages.Knit)
local MatterController = Knit.GetController("MatterController")
local routeNames = {"MatterReplication", "InitialPayloadReplication"}

local function receiveReplication(world, state, _ui)
	local function debugPrint(...)
		if state.debugEnabled then
			print("Replication>", ...)
		end
	end

	for _, routeName in routeNames do
		for _, _, entities in routes[routeName]:query() do
			for serverEntityId, componentMap in entities do
				local clientEntityId = MatterController._entityIdMap[serverEntityId]

				if clientEntityId and next(componentMap) == nil then

					if world:get(clientEntityId, components.Enemy) then
						-- was an enemy, remove from the list
						local index = table.find(MatterController._enemies, serverEntityId)
						table.remove(MatterController._enemies, index)
					end

					world:despawn(clientEntityId)
					MatterController._entityIdMap[serverEntityId] = nil
					debugPrint(string.format("Despawn %ds%d", clientEntityId, serverEntityId))
					continue
				end

				local componentsToInsert = {}
				local componentsToRemove = {}

				local insertNames = {}
				local removeNames = {}

				for name, container in componentMap do
					if container.data then
						table.insert(componentsToInsert, components[name](container.data))
						table.insert(insertNames, name)

						if name == "Enemy" then
							-- print("Inserting an enemy")
							table.insert(MatterController._enemies, serverEntityId)
						end
					else
						table.insert(componentsToRemove, components[name])
						table.insert(removeNames, name)
					end
				end

				if clientEntityId == nil then
					clientEntityId = world:spawn(unpack(componentsToInsert))

					MatterController._entityIdMap[serverEntityId] = clientEntityId

					debugPrint(
						string.format("Spawn %ds%d with %s", clientEntityId, serverEntityId, table.concat(insertNames, ","))
					)
				else
					if #componentsToInsert > 0 then
						world:insert(clientEntityId, unpack(componentsToInsert))
					end

					if #componentsToRemove > 0 then
						world:remove(clientEntityId, unpack(componentsToRemove))
					end


					debugPrint(
						string.format(
							"Modify %ds%d adding %s, removing %s",
							clientEntityId,
							serverEntityId,
							if #insertNames > 0 then table.concat(insertNames, ", ") else "nothing",
							if #removeNames > 0 then table.concat(removeNames, ", ") else "nothing"
						)
					)
				end
			end
		end
	end
end

return {
	system = receiveReplication,
	priority = 1,
}