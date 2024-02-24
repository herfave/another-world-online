local LocalPlayer = game.Players.LocalPlayer
local Janitor = require(game.ReplicatedStorage.Packages.Janitor)
local module = {_janitor = Janitor.new()}

function module:Setup(_client: any)
    _client.OnCharacterModelCreated:Connect(function(characterModel: any)
        print("CHARACTER CREATED!")
        if characterModel.userId == LocalPlayer.UserId then
            print("IS LOCAL PLAYER")
            characterModel.onModelCreated:Connect(function(model)
                self._janitor:Cleanup()
                for _, track: AnimationTrack in characterModel.tracks do
                    if track.Animation:HasTag("_AttackAnim") then
                        local signal = track:GetMarkerReachedSignal("Attack")
                        local connection = signal:Connect(function(multiplier)
                            self._attackMultiplier = tonumber(multiplier)
                            print("reached anim", tonumber(multiplier))
                        end)

                        self._janitor:Add(connection)

                        print(`Listening to {track.Animation.Name}`)
                    else
                        print(`Not an attack anim {track.Animation.Name}`)
                    end
                end
            end)
        end
    end)
end

function module:Step()
end

function module:GenerateCommand(command, serverTime: number, deltaTime: number)
    if (command == nil) then
		command = {
            serverTime = serverTime,
            deltaTime = deltaTime
        }
	end

    command.am = 0
    command.serverTime = serverTime
    command.deltaTime = deltaTime
    if self._attackMultiplier ~= 0 then
        command.am = self._attackMultiplier
        self._attackMultiplier = 0
    end

    return command
end

return module