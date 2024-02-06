local module = {}
local RunService = game:GetService("RunService")
local Utils = require(game.ReplicatedStorage.Shared.Utils)
local MathUtils = require(game.ReplicatedStorage.Shared.Chickynoid.Simulation.MathUtils)
local Spring = require(game.ReplicatedStorage.Shared.Spring)

-- update FOV
local MAX_FOV = 105
local MIN_FOV = 70
local FOV_DIFF = MAX_FOV - MIN_FOV
local BUFFER = 3

function module:Setup()
    self.spring = Spring.new(MIN_FOV)
    self.spring.Speed = 6
    self.spring.Damper = 1
end

function module:Step(_client, delta)
    local chickynoid = _client:GetClientChickynoid()
    local characterModel = _client.characterModel
    if chickynoid and characterModel then
        if characterModel.modelReady then

            self.spring:TimeSkip(delta)

            local simulation = chickynoid.simulation
            if not RunService:IsClient() then return end
            local camera = workspace.CurrentCamera
            local speed = simulation.state.currentSpeed

            if speed > simulation.constants.maxSpeed + BUFFER then
                local speedDiff = speed - simulation.constants.maxSpeed
                local maxDiff = simulation.constants.boostSpeed - simulation.constants.maxSpeed
                local fovPerc = Utils.roundNumber(math.clamp(speedDiff / maxDiff, 0, 1), 5)--math.floor(math.clamp(MIN_FOV + (FOV_DIFF * fovPerc), MIN_FOV, MAX_FOV))
                -- print(targetFov)
                -- if math.abs(simulation.state.targetFov - targetFov) > 5 then
                    simulation.state.targetFov = fovPerc
                -- end
            else
                simulation.state.targetFov = 0
            end

            -- local fov = MathUtils:SmoothLerp(MIN_FOV, MAX_FOV, simulation.state.targetFov, delta)
            -- camera.FieldOfView = fov
            -- print(math.floor(fov), simulation.state.targetFov)
            local targetFov = MIN_FOV + (simulation.state.targetFov * FOV_DIFF)
            self.spring.Target = targetFov
            camera.FieldOfView = self.spring.Position
                            -- end
            -- print(currDiff)
        end
    end
end

return module