  local module = {}

local path = game.ReplicatedStorage.Shared.Chickynoid
local Enums = require(path.Enums)
local RANDOM = Random.new(os.time())
local RunService = game:GetService("RunService")


-- Check if the player has enough boost meter to boost
function module.CanBoost(simulation)
    return simulation.state.boostMeter > 0
end

-- Increase max speeds to boost speecs
function module.Boost(simulation, delta)
    simulation.state.boostMeter = math.max(simulation.state.boostMeter - delta, 0)

    simulation.state.groundSpeed = math.min(
        simulation.state.groundSpeed + (delta * simulation.constants.boostAcceleration),
        simulation.constants.boostSpeed
    )

    simulation.state.airSpeed = math.min(
        simulation.state.airSpeed + (delta * simulation.constants.boostAcceleration),
        simulation.constants.boostSpeed
    )

    simulation.characterData:ToggleParticles(Enums.Particles.Boost, Enums.ParticleChannel.Channel0)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Boost, Enums.SoundChannel.Channel2, false, 0.5)
end

-- Revert max speeds to unboosted levels
function module.Unboost(simulation, delta)
    simulation.state.groundSpeed = math.max(
        simulation.state.groundSpeed - (delta * simulation.constants.boostAcceleration * 0.2),
        simulation.constants.maxSpeed
    )

    if simulation:DoGroundCheck(simulation.state.pos) then
        simulation.state.airSpeed = math.max(
            simulation.state.airSpeed - (delta * simulation.constants.boostAcceleration * 0.2),
            simulation.constants.maxAirSpeed
        )
    end
    simulation.characterData:ToggleParticles(Enums.Particles.Boost, Enums.ParticleChannel.Channel0, false)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Stop, Enums.SoundChannel.Channel2, false)

    -- if RunService:IsClient() then
    --     local camera = workspace.CurrentCamera
    --     if camera.FieldOfView > MIN_FOV then
    --         camera.FieldOfView = math.clamp(
    --             camera.FieldOfView - FOV_INC * 0.5,
    --             MIN_FOV,
    --             MAX_FOV
    --         )
    --     elseif camera.FieldOfView < MIN_FOV then
    --         camera.FieldOfView = MIN_FOV
    --     end
    -- end
end

-- Perform a trick and increase boost meter by % of trick cooldown
function module.Trick(simulation, trickNum)
    -- set cooldown
    -- TODO: pull cooldown from serialized trick info list later

    -- select next trick based on sim state
    local moveState = simulation:GetMoveState().name
    
    if moveState == "Base" then
        simulation.state.trickCooldown = 1.2

        if simulation.lastGround then
            simulation.state.nextTrick = Enums.Anims["GroundTrick" .. trickNum]
        else
            simulation.state.nextTrick = Enums.Anims["AirTrick" .. trickNum]
        end
    elseif moveState == "Railgrind" or moveState == "Splinegrind" then
        simulation.state.trickCooldown = 1
        simulation.state.nextTrick = Enums.Anims["RailTrick" .. trickNum]
    end

    simulation.state.trick = simulation.state.trickCooldown

    -- play animation
    simulation.state.lastTrick = simulation.state.nextTrick


    simulation.characterData:PlayAnimation(simulation.state.nextTrick, Enums.AnimChannel.Channel3, true)
    simulation.state.boostMeter = math.min(
        simulation.state.boostMeter + (simulation.state.trickCooldown * 0.3),
        simulation.constants.maxBoostMeter)
end


return module