local LocalPlayer = game.Players.LocalPlayer
local Janitor = require(game.ReplicatedStorage.Packages.Janitor)
local module = {_janitor = Janitor.new()}

function module:Setup(_client: any)   
    _client.OnCharacterModelCreated:Connect(function(characterModel: any)
        if characterModel.UserId == LocalPlayer.UserId then
            self._janitor:Cleanup()
            for _, track: AnimationTrack in characterModel.tracks do
                if track:HasTag("AttackAnim") then
                    local signal = track:GetMarkerReachedSignal("Attack")
                    local connection = signal:Connect(function(multiplier)
                        self._attackMultiplier = tonumber(multiplier)
                    end)

                    self._janitor:Add(connection)
                end
            end
        end
    end)
end

function module:Step()

end

function module:GenerateCommand(command, serverTime: number, deltaTime: number)
    if (command == nil) then
		command = {}
	end

    command.am = 0
    if self._attackMultiplier ~= 0 then
        command.am = self._attackMultiplier
        self._attackMultiplier = 0
    end

    return command
end

return module