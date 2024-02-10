local module = {}
local path = game.ReplicatedFirst.Chickynoid.Shared
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)

--Call this on both the client and server!
function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Base", self.ActiveThink, self.AlwaysThink)
    simulation:SetMoveState("Base")
    
    simulation.state.look = Vector3.new()
    simulation.state.camera = Vector3.new()
end

function module.AlwaysThink(simulation, cmd)
    -- update look
    local lookCF = CFrame.fromOrientation(cmd.la.X, cmd.la.Y, cmd.la.Z)
    simulation.state.look = lookCF.LookVector
    simulation.state.camera = cmd.p
end

function module.ActiveThink(simulation, cmd)

    --Check ground
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
	

    --Did the player have a movement request?
    local wishDir = nil
    if cmd.x ~= 0 or cmd.z ~= 0 then
        wishDir = Vector3.new(cmd.x, 0, cmd.z).Unit
        simulation.state.pushDir = Vector2.new(cmd.x, cmd.z)
    else
        simulation.state.pushDir = Vector2.new(0, 0)
    end

    --Create flat velocity to operate our input command on
    --In theory this should be relative to the ground plane instead...
    local flatVel = MathUtils:FlatVec(simulation.state.vel)

    --Does the player have an input?
    if wishDir ~= nil then
        if onGround then
            --Moving along the ground under player input

            flatVel = MathUtils:GroundAccelerate(
                wishDir,
                simulation.constants.maxSpeed,
                simulation.constants.accel,
                flatVel,
                cmd.deltaTime
            )

            --Good time to trigger our walk anim
            if simulation.state.pushing > 0 then
                simulation.characterData:PlayAnimation("Push", Enums.AnimChannel.Channel0, false)
            else
				simulation.characterData:PlayAnimation("Walk", Enums.AnimChannel.Channel0, false)
            end
        else
            --Moving through the air under player control
            flatVel = MathUtils:Accelerate(wishDir, simulation.constants.airSpeed, simulation.constants.airAccel, flatVel, cmd.deltaTime)
        end
    else
        if onGround ~= nil then
            --Just standing around
            flatVel = MathUtils:VelocityFriction(flatVel, simulation.constants.brakeFriction, cmd.deltaTime)

            --Enter idle
			simulation.characterData:PlayAnimation("Idle", Enums.AnimChannel.Channel0, false)
        -- else
            --moving through the air with no input
        end
    end

    --Turn out flatvel back into our vel
    simulation.state.vel = Vector3.new(flatVel.x, simulation.state.vel.y, flatVel.z)

    --Do jumping?
    if simulation.state.jump > 0 then
        simulation.state.jump -= cmd.deltaTime
        if simulation.state.jump < 0 then
            simulation.state.jump = 0
        end
    end

    if onGround ~= nil then
        --jump!
        if cmd.y > 0 and simulation.state.jump <= 0 then
            simulation.state.vel = Vector3.new(simulation.state.vel.x, simulation.constants.jumpPunch, simulation.state.vel.z)
            simulation.state.jump = 0.2 --jumping has a cooldown (think jumping up a staircase)
            simulation.state.jumpThrust = simulation.constants.jumpThrustPower
			simulation.characterData:PlayAnimation("Jump", Enums.AnimChannel.Channel0, true, 0.2)
        end

    end

    --In air?
    if onGround == nil then
        simulation.state.inAir += cmd.deltaTime
        if simulation.state.inAir > 10 then
            simulation.state.inAir = 10 --Capped just to keep the state var reasonable
        end

        --Jump thrust
        if cmd.y > 0 then
            if simulation.state.jumpThrust > 0 then
                simulation.state.vel += Vector3.new(0, simulation.state.jumpThrust * cmd.deltaTime, 0)
                simulation.state.jumpThrust = MathUtils:Friction(
                    simulation.state.jumpThrust,
                    simulation.constants.jumpThrustDecay,
                    cmd.deltaTime
                )
            end
            if simulation.state.jumpThrust < 0.001 then
                simulation.state.jumpThrust = 0
            end
        else
            simulation.state.jumpThrust = 0
        end

        --gravity
        simulation.state.vel += Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0)

        --Switch to falling if we've been off the ground for a bit
        if simulation.state.vel.y <= 0.01 and simulation.state.inAir > 0.5 then
			simulation.characterData:PlayAnimation("Fall", Enums.AnimChannel.Channel0, false)
        end
    else
        simulation.state.inAir = 0
    end

    --Sweep the player through the world, once flat along the ground, and once "step up'd"
    local stepUpResult = nil
    local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.position, simulation.state.vel, cmd.deltaTime)

    --Did we crashland
    if onGround == nil and hitSomething == true then
        --Land after jump
        local groundCheck = simulation:DoGroundCheck(walkNewPos)

        if groundCheck ~= nil then
            --Crashland
			walkNewVel = simulation:CrashLand(walkNewVel, groundCheck)
        end
    end

	
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

	--Do angles
	if (cmd.shiftLock == 1) then
		
        if (cmd.fa) then
            local vec = cmd.fa - simulation.state.position

			simulation.state.targetAngle  = MathUtils:PlayerVecToAngle(vec)
			simulation.state.angle = MathUtils:LerpAngle(
				simulation.state.angle,
				simulation.state.targetAngle,
				simulation.constants.turnSpeedFrac * cmd.deltaTime
			)
        end
    else    
        if wishDir ~= nil then
            simulation.state.targetAngle = MathUtils:PlayerVecToAngle(wishDir)
            simulation.state.angle = MathUtils:LerpAngle(
                simulation.state.angle,
                simulation.state.targetAngle,
                simulation.constants.turnSpeedFrac * cmd.deltaTime
            )
        end
	end
	
end

return module