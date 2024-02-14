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
    simulation.constants.attackFriction = 0.5
    
    -- attack state variables
    simulation.state.attackTime = 0
    simulation.state.timeSinceLastAttack = 0
    simulation.state.attackCombo = 0
    simulation.state.attackCooldown = 0
    simulation.state.attackTarget = Vector3.zero
end

local MAX_COMBO = 5

local function resetAttack(simulation)
    -- don't attack during cooldown!
    if simulation.state.attackCooldown > 0 then return false end

    local onGround = nil
    onGround = simulation:DoGroundCheck(simulation.state.position)

    if simulation.state.attackCombo < MAX_COMBO then
        -- go on cooldown
        simulation.state.attackCombo += 1
        if simulation.state.attackCombo == MAX_COMBO then
            simulation.state.attackCooldown = 1.5
        end

        local state = onGround ~= nil and "Ground" or "Air"

        simulation.characterData:PlayAnimation(
            `{state}Attack{simulation.state.attackCombo}`,
            Enums.AnimChannel.Channel0, true
        )

        if simulation.state.attackTarget ~= Vector3.zero then
            local vec = simulation.state.attackTarget
            local angle = MathUtils:PlayerVecToAngle(vec)
            simulation.state.targetAngle = angle
            simulation.state.angle = angle
        end

        local playerRotation = CFrame.fromOrientation(0, simulation.state.angle, 0)

        simulation.state.vel = playerRotation.LookVector * simulation.constants.attackVelocity
        simulation.state.attackTime = 0
        simulation.state.timeSinceLastAttack = 0

        return true
    end
end

function module.StartState(simulation, prevState)
    -- max out velocity to attack velocity
    resetAttack(simulation)
    -- print("START ANGLE:", simulation.state.angle)
    print(simulation.state.attackTarget)
end

function module.EndState(simulation, nextState)
    simulation.state.attackTime = 0
end

function module.AlwaysThink(simulation, cmd)
    local dt = cmd.deltaTime
    local moveState = simulation:GetMoveState()
    simulation.state.timeSinceLastAttack += dt

    if simulation.state.attackCooldown > 0 then
        simulation.state.attackCooldown -= dt
    end

    if simulation.state.timeSinceLastAttack > 0.7 then
        simulation.state.attackCombo = 0
    end


    -- listen for attack input
    if cmd.a == 1 and moveState.name ~= "Attacking" and simulation.state.attackCooldown <= 0 then
        -- get target from cmd.t
        simulation.state.attackTarget = cmd.t
        simulation:SetMoveState("Attacking")
        return
    end
end

function module.ActiveThink(simulation, cmd)
    -- print(simulation.state.angle)
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