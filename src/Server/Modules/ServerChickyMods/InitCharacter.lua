local Packages = game.ReplicatedStorage.Packages
local ServerComm = require(Packages.Comm).ServerComm
local ChickynoidComm = ServerComm.new(game.ReplicatedStorage:WaitForChild("Comms"), "ChickynoidComm")

local module = {}

function module:Setup(_server)
	local initialized = {}

	local function initPlayerRecord(serv, playerRecord)
		if initialized[playerRecord.userId] == nil then
			initialized[playerRecord.userId] = playerRecord
		end
		print("init playerRecord")
	end

	_server.OnPlayerConnected:Connect(initPlayerRecord)

	-- init already connected players
	for _, playerRecord in _server:GetPlayers() do
		initPlayerRecord(_server, playerRecord)
	end
end

return module