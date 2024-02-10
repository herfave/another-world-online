local module = {}

local path = game.ReplicatedFirst.Chickynoid
local Profiler = require(path.Shared.Vendor.Profiler)

function module:Setup(_server) end

module.gridSize = 64
module.radius = 200
module.angleThreshold = 95

function module:UpdateVisibility(server, debugBotBandwidth)
	
 
	Profiler:BeginSample("Vis")
	
	--Write all players to a vis grid
	local grid = {}
	
	local radius = module.radius
	local gridSize = module.gridSize	
	local steps = math.floor(radius / gridSize)

	for key,playerRecord in server.playerRecords do

		if (playerRecord.chickynoid == nil) then
			continue
		end
		local posA = playerRecord.chickynoid.simulation.state.position
		
		local gridKey = Vector3.new(posA.X,0, posA.Z) // gridSize
		
		local tab = grid[gridKey]
		if (tab == nil) then
			tab = {}
			grid[gridKey] = tab
		end
		table.insert(tab, playerRecord) 
		
		playerRecord.gridKey = gridKey
	end
	
	--build the list
	for key,playerRecord in server.playerRecords do
		if (playerRecord.chickynoid == nil) then
			continue
		end
		
		if (playerRecord.dummy == true and debugBotBandwidth == false) then
			continue
		end
	
		
		playerRecord.visibilityList = {}
		local gridKey = playerRecord.gridKey
		for x= -steps, steps do
			for z =-steps,steps do
				local cell = gridKey + Vector3.new(x,0,z)
				
				local list = grid[cell]
				if (list ~= nil) then
					for _,otherPlayerRecord in list do
						if (otherPlayerRecord ~= playerRecord) then
							playerRecord.visibilityList[otherPlayerRecord.userId] = otherPlayerRecord
							-- local cameraPosition = playerRecord.chickynoid.simulation.state.camera
							-- -- check their position to cull
							-- local otherPosition = otherPlayerRecord.chickynoid.simulation.state.position
							-- local controlVector = playerRecord.chickynoid.simulation.state.look
							-- local directionVector = (otherPosition - cameraPosition)

							-- local angle = math.floor(math.deg(directionVector.Unit:Angle(controlVector)))
							-- if angle <= module.angleThreshold then
							-- end
						end
					end
				end
			end
		end
		
	end
	
	Profiler:EndSample()
end
 
return module