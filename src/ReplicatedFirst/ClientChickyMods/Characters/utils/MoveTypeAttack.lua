local module = {}
local path = game.ReplicatedFirst.Chickynoid.Shared
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)

function module:ModifySimulation(simulation)
    simulation:RegisterMoveState(
        "Attacking",
        self.ActiveThink,
        self.AlwaysThink,
        self.StartState,
        self.EndState
    )

    -- attack physics constants
    simulation.constants.attackVelocity = 12
    simulation.constants.attackFriction = 0.3
    
    -- attack state variables
    simulation.state.attackTime = 0
    simulation.state.timeSinceLastAttack = 0
    simulation.state.attackCombo = 0
end

local function resetAttack(simulation)
    -- increment combo and play attack anim
    if simulation.state.attackCombo < 5 then
        simulation.state.attackCombo += 1
        simulation.characterData:PlayAnimation(
            `GroundAttack{simulation.state.attackCombo}`,
            Enums.AnimChannel.Channel0, true
        )
        local playerRotation = CFrame.fromOrientation(0, simulation.state.angle, 0)
        simulation.state.vel = playerRotation.LookVector * simulation.constants.attackVelocity
        simulation.state.attackTime = 0
        simulation.state.timeSinceLastAttack = 0
    else
        simulation.state.vel = Vector3.zero
        simulation.state.attackCombo = 0
    end
end

function module.StartState(simulation, prevState)
    -- max out velocity to attack velocity
    resetAttack(simulation)
end

function module.EndState(simulation, nextState)
    simulation.state.attackTime = 0
end

function module.AlwaysThink(simulation, cmd)
    local dt = cmd.deltaTime
    local moveState = simulation:GetMoveState()
    simulation.state.timeSinceLastAttack += dt

    if simulation.state.timeSinceLastAttack > 0.7 then
        simulation.state.attackCombo = 0
    end

    -- listen for attack input
    if cmd.a > 0 and moveState.name ~= "Attacking" then
        simulation:SetMoveState("Attacking")
        return
    end
end

function module.ActiveThink(simulation, cmd)
    local dt = cmd.deltaTime
    -- exit state after attack
    simulation.state.attackTime += dt
    -- TODO: update this to an animation time or something
    if simulation.state.attackTime >= 0.7 then
        simulation:SetMoveState("Base")
        return
    elseif cmd.a > 0 and simulation.state.attackTime > 0.4 then
        resetAttack(simulation)
    end
    
    local onGround = nil
    onGround = simulation:DoGroundCheck(simulation.state.position)
    --If the player is on too steep a slope, its not ground
	if (onGround ~= nil and onGround.normal.Y < simulation.constants.maxGroundSlope) then
		
		--See if we can move downwards?
		if (simulation.state.vel.y < 0.1) then
			local stuck = simulation:CheckGroundSlopes(simulation.state.position)
			
			if (stuck == false) then
				--we moved, that means the player is on a slope and can free fall
				onGround = nil
			else
				--we didn't move, it means the ground we're on is sloped, but we can't fall any further
				--treat it like flat ground
				onGround.normal = Vector3.new(0,1,0)
			end
		else
			onGround = nil
		end
	end

    --Mark if we were onground at the start of the frame
    local startedOnGround = onGround
	
	--Simplify - whatever we are at the start of the frame goes.
	simulation.lastGround = onGround

    --Create flat velocity to operate our input command on
    --In theory this should be relative to the ground plane instead...
    local flatVel = MathUtils:FlatVec(simulation.state.vel)
    flatVel = MathUtils:VelocityFriction(flatVel, simulation.constants.attackFriction, dt)
    simulation.state.vel = Vector3.new(flatVel.X, 0, flatVel.Z)

    local stepUpResult = nil
    local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.position, simulation.state.vel, cmd.deltaTime)

    -- Do we attempt a stepup?                              (not jumping!)
    if onGround ~= nil and hitSomething == true and simulation.state.jump == 0 then
        stepUpResult = simulation:DoStepUp(simulation.state.position, simulation.state.vel, cmd.deltaTime)
    end

    --Choose which one to use, either the original move or the stepup
    if stepUpResult ~= nil then
        simulation.state.stepUp += stepUpResult.stepUp
        simulation.state.position = stepUpResult.position
        simulation.state.vel = stepUpResult.vel
    else
        simulation.state.position = walkNewPos
        simulation.state.vel = walkNewVel
    end

    --Do stepDown
    if true then
        if startedOnGround ~= nil and simulation.state.jump == 0 and simulation.state.vel.y <= 0 then
            local stepDownResult = simulation:DoStepDown(simulation.state.position)
            if stepDownResult ~= nil then
                simulation.state.stepUp += stepDownResult.stepDown
                simulation.state.position = stepDownResult.position
            end
        end
    end
end

return module