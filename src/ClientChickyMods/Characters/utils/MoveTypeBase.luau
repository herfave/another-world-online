--[[
    MoveTypeBase.lua
    Ported MovetypeBase from Chickynoid/Simulation to a standalone mod
]]

local module = {}
local path = game.ReplicatedStorage.Shared.Chickynoid
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local MoveActions = require(script.Parent.MoveActions)

function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Base", self.ActiveThink, nil, self.StartState, nil)
    simulation:SetMoveState("Base")
    simulation.constants.landCooldown = 0.2

    simulation.state.baseLockout = 0
    simulation.state.trick = 0
    simulation.state.lastTrick = Enums.Anims.Trick2
    simulation.state.airBoostTime = 0
    simulation.state.unboostTime = 0.7
    simulation.state.speedMultiplier = 1

    simulation.state.up = Vector3.yAxis
end

function module.StartState(simulation, prevState)
    if (prevState == "Wallride" or prevState == "Railgrind" or prevState == "Splinegrind") and simulation.state.vel.Y > 0 then
        -- print("jumping from flow state")
        simulation.state.flowJump = 0
        simulation.state.usedAirBoost = false
    end

    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)
end

function module.ActiveThink(simulation, cmd)

    if simulation.state.trick > 0 then
        simulation.state.trick = math.max(simulation.state.trick - cmd.deltaTime, 0)
    elseif simulation.state.didTrick == 1 then
        simulation.state.didTrick = 0
    end

    if simulation.state.baseLockout > 0 then
        simulation.state.baseLockout = math.max(simulation.state.baseLockout - cmd.deltaTime, 0)
    end
    --Check ground
    local onGround = nil
    onGround = simulation.state.baseLockout <= 0 and simulation:DoGroundCheck(simulation.state.pos) or nil
    local isBoosting = cmd.boost > 0 and MoveActions.CanBoost(simulation)

    --If the player is on too steep a slope, its not ground
	if (onGround ~= nil) then 
        -- print(onGround.normal.Y)
        if (onGround.normal.Y < simulation.constants.maxGroundSlope) then
            --See if we can move downwards?
            -- if simulation.state.vel.Y <= 0 then
            local newvel = MathUtils:ProjectOnPlane(
                simulation.state.vel + Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0),
                onGround.normal
            )

            simulation.state.vel = newvel

            if simulation.state.vel.Y < -0.2 then
                local angle = math.deg(onGround.normal.Y)
                -- print(angle)
                simulation.state.speedMultiplier = MathUtils:CalculateMultiplier(angle, 100)
            end
            -- local stuck = simulation:CheckGroundSlopes(simulation.state.pos)
            
            -- if (stuck == false) then
            --     --we moved, that means the player is on a slope and can free fall
            --     onGround = nil
            -- else
            --     --we didn't move, it means the ground we're on is sloped, but we can't fall any further
            --     --treat it like flat ground
            --     onGround.normal = Vector3.new(0,1,0)
            -- end
            --     onGround = nil
            -- else

            -- end
        elseif not isBoosting then
            simulation.state.speedMultiplier = math.max(simulation.state.speedMultiplier - cmd.deltaTime*0.5, 1)
        end
    elseif not isBoosting then
        simulation.state.speedMultiplier = math.max(simulation.state.speedMultiplier - cmd.deltaTime*0.5, 1)
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

    -- main thing to do is convert world velocity to local velocity, then back

    --Create flat velocity to operate our input command on
    --In theory this should be relative to the ground plane instead
    local flatVel = MathUtils:FlatVec(simulation.state.vel)

    --Does the player have an input?
    if wishDir ~= nil then
        if onGround then
            --Moving along the ground under player input
            -- print(math.floor(simulation.state.currentSpeed), simulation.state.speedMultiplier)
            flatVel = MathUtils:GroundAccelerate(
                wishDir,
                simulation.state.groundSpeed * simulation.state.speedMultiplier,
                simulation.constants.accel,
                flatVel,
                cmd.deltaTime
            )

            if isBoosting then
                MoveActions.Boost(simulation, cmd.deltaTime)
                simulation.characterData:PlayAnimation(Enums.Anims.GroundBoost, Enums.AnimChannel.Channel1, false)
            end

            -- only decelerate boost speeds when on the ground, allowing for boost air dashes
            if cmd.boost == 0 or not MoveActions.CanBoost(simulation) then
                simulation.state.unboostTime -= cmd.deltaTime
                if simulation.state.unboostTime <= 0 then
                    MoveActions.Unboost(simulation, cmd.deltaTime)
                end
            end

            if cmd.boost <= 0 then
                --Good time to trigger our walk anim
                if simulation.state.pushing > 0 then
                    simulation.characterData:PlayAnimation(Enums.Anims.Push, Enums.AnimChannel.Channel1, false)
                else
                    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel0)
                    simulation.characterData:PlayAnimation(Enums.Anims.Walk, Enums.AnimChannel.Channel1, false)
                end
            end
        else
            --Moving through the air under player control
            if simulation.state.baseLockout <= 0 then -- assume in air if coming out of a flow
                flatVel = MathUtils:Accelerate(wishDir, simulation.state.airSpeed, simulation.constants.airAccel, flatVel, cmd.deltaTime)
            end
        end
    else
        if simulation.state.baseLockout > 0 then -- assume in air if coming out of a flow
            simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, false)
        elseif onGround ~= nil then
            --Just standing around
            flatVel = MathUtils:VelocityFriction(flatVel, simulation.constants.brakeFriction, cmd.deltaTime)
            -- only decelerate boost speeds when on the ground, allowing for boost air dashes
            if cmd.boost == 0 or not MoveActions.CanBoost(simulation) then
                MoveActions.Unboost(simulation, cmd.deltaTime)
            end

            --Enter idle (stop movement on channel 1)
            simulation.characterData:StopAnimation(Enums.AnimChannel.Channel1)
            simulation.characterData:PlayAnimation(Enums.Anims.Idle, Enums.AnimChannel.Channel0, false)
            -- else
            --moving through the air with no input
        end
    end

    --Turn out flatvel back into our vel
    if simulation.state.baseLockout <= 0 then
        simulation.state.vel = Vector3.new(flatVel.x, simulation.state.vel.y, flatVel.z)
    end
    simulation.state.currentSpeed = flatVel.Magnitude or 0

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
            simulation.state.vel = Vector3.new(simulation.state.vel.x, 0, simulation.state.vel.z) + (simulation.state.up * simulation.constants.jumpPunch)
            simulation.state.jump = simulation.constants.landCooldown --jumping has a cooldown (think jumping up a staircase)
            simulation.state.jumpThrust = simulation.constants.jumpThrustPower
            simulation.characterData:StopAnimation(Enums.AnimChannel.Channel0)
            simulation.characterData:PlayAnimation(Enums.Anims.Jump, Enums.AnimChannel.Channel1, true, 0.2)
            simulation.characterData:PlayRootSound(Enums.RootSounds.Jump, Enums.SoundChannel.Channel1, true)
        end

        --Check jumpPads
        if onGround.hullRecord then
            local instance = onGround.hullRecord.instance

            if instance then
                local vec3 = instance:GetAttribute("launch")
                if vec3 then
                    local dir = instance.CFrame:VectorToWorldSpace(vec3)
                    simulation.state.vel = dir
                    simulation.state.jump = 0.2
                    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel0)
                    simulation.characterData:PlayAnimation(Enums.Anims.Jump, Enums.AnimChannel.Channel1, true, 0.2)
                end
            end
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
            if simulation.state.flowJump == 0 then
                simulation.state.flowJump = 1
                simulation.state.jumpThrust = simulation.constants.jumpThrustPower
            end

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

        --gravity and nograv air boosting
        if simulation.state.boostMeter >= simulation.constants.airBoostCost
        and cmd.boost > 0
        and not simulation.state.usedAirBoost
        and simulation.state.inAir > simulation.constants.boostLockout
        and simulation.state.trick <= 0.5 then
            -- cancel trick anims
            simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)
            -- use up boost resources
            simulation.state.boostMeter = math.max(simulation.state.boostMeter - simulation.constants.airBoostCost, 0)
            simulation.state.usedAirBoost = true

            -- determine initial direction
            local vec = simulation.state.vel.Unit
            if wishDir then
                vec = wishDir
            end
            vec = vec - Vector3.new(0, vec.Y, 0)
            simulation.state.airBoostVector = vec
            simulation.state.targetAngle = MathUtils:PlayerVecToAngle(vec)
            simulation.state.angle = simulation.state.targetAngle

            -- play effects
            simulation.characterData:PlayAnimation(Enums.Anims.GroundBoost, Enums.AnimChannel.Channel1, false)
            simulation.characterData:PlayRootSound(Enums.RootSounds.AirBoost, Enums.SoundChannel.Channel2, false)
        
        -- continue air boost after initiated
        elseif simulation.state.usedAirBoost and simulation.state.airBoostTime < 0.4 then
			simulation.state.airBoostTime += cmd.deltaTime

			local vec = simulation.state.airBoostVector
			if simulation.state.airBoostTime < 0.2 then
				vec = simulation.state.vel.Unit
				if wishDir then
					vec = wishDir
				end
				vec = vec - Vector3.new(0, vec.Y, 0)
				simulation.state.airBoostVector = vec
			end

			-- local target = simulation.state.angleZ + math.rad((360 * (cmd.deltaTime / 0.4)))
			-- simulation.state.angleZ = target

			simulation.state.vel = vec * math.min(simulation.constants.airBoostSpeed, simulation.state.airSpeed)
			simulation.state.airSpeed = simulation.constants.airBoostSpeed
			simulation.state.currentSpeed = simulation.constants.airBoostSpeed

        -- perform an aerial trick instead!
        elseif cmd.trick > 0 and simulation.state.trick <= 0 then
			MoveActions.Trick(simulation, cmd.trick)
			if simulation.state.vel.Y then
				simulation.state.vel = Vector3.new(
					simulation.state.vel.X,
					25, -- trick boost
					simulation.state.vel.Z
				)
			end

        else
            simulation.state.vel += Vector3.new(0, simulation.constants.gravity * cmd.deltaTime, 0)

            --Switch to falling if we've been off the ground for a bit
            if simulation.state.vel.Y <= 0.01 and simulation.state.inAir > 0.2 then
                simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, false)
            end
            -- simulation.state.angleZ = 0
        end
    else
        if simulation.state.inAir > 0.2 then
            simulation.state.jump = simulation.constants.landCooldown
            
            if simulation.state.baseLockout <= 0 then
                simulation.characterData:PlayRootSound(Enums.RootSounds.Land, Enums.SoundChannel.Channel1, true)
            end
            if simulation.state.inAir > 1.2 then
                simulation.characterData:PlayAnimation(Enums.Anims.Land, Enums.AnimChannel.Channel2, true, 0.3)
                simulation.state.jump = 1.2
            end
        end

        simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)
        simulation.state.inAir = 0
        simulation.state.airBoostTime = 0
        simulation.state.usedAirBoost = false
    end

    --Sweep the player through the world, once flat along the ground, and once "step up'd"
    local stepUpResult = nil
    local walkNewPos, walkNewVel, hitSomething = simulation:ProjectVelocity(simulation.state.pos, simulation.state.vel, cmd.deltaTime)

    --Did we crashland
    if onGround == nil and hitSomething == true and simulation.state.baseLockout <= 0 then
        --Land after jump
        local groundCheck = simulation:DoGroundCheck(walkNewPos)
        if groundCheck ~= nil then
            --Crashland
            walkNewVel = simulation:CrashLand(walkNewVel, cmd, groundCheck)
        end
    end

    -- Do we attempt a stepup?                              (not jumping!)
    if onGround ~= nil and hitSomething == true and simulation.state.jump == 0 then
        stepUpResult = simulation:DoStepUp(simulation.state.pos, simulation.state.vel, cmd.deltaTime)
        -- print("stepped up!")
    end


    --Choose which one to use, either the original move or the stepup
    if stepUpResult ~= nil then
        simulation.state.stepUp += stepUpResult.stepUp
        simulation:SetPosition(stepUpResult.pos)
        simulation.state.vel = stepUpResult.vel
    else
        simulation:SetPosition(walkNewPos)
        simulation.state.vel = walkNewVel
    end

    --Do stepDown
    if startedOnGround ~= nil and simulation.state.jump == 0 then
        local stepDownResult = simulation:DoStepDown(simulation.state.pos)
        if stepDownResult ~= nil then
            simulation.state.stepUp += stepDownResult.stepDown
            simulation:SetPosition(stepDownResult.pos)
        end
    end


    --Do angles
    if (simulation.constants.aimlock == 1) then

        if (cmd.fa) then
            local vec = cmd.fa - simulation.state.pos

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
        elseif simulation.state.vel.Magnitude > 10 then
            -- turn in the direction you're moving
            -- simulation.state.targetAngle = MathUtils:PlayerVecToAngle(simulation.state.vel.Unit)
        end

        local targetX = simulation.state.angleX
        local targetY = simulation.state.targetAngle
        local targetZ = simulation.state.angleZ

        -- get normals
        if onGround then
            local constructedCf = CFrame.new(simulation.state.pos)
            * CFrame.fromOrientation(
                simulation.state.angleX,
                simulation.state.targetAngle,
                simulation.state.angleZ
            )

            simulation.state.up = constructedCf.UpVector

            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {workspace:WaitForChild("GameArea")}
            params.FilterType = Enum.RaycastFilterType.Whitelist
            local rayResult = workspace:Raycast(simulation.state.pos, -5*constructedCf.UpVector, params)

            
            if rayResult then
                local rotateToFloorCFrame = Utils.getRotationBetween(
                    constructedCf.UpVector,
                    rayResult.Normal,
                    Vector3.yAxis
                --     Vector3.xAxis
                )

                local goalCF = rotateToFloorCFrame*constructedCf
                local x, y, z = goalCF:ToOrientation()

                simulation.state.baseNormal = goalCF.UpVector

                targetX = x -- * -flowDirection
                targetY = y -- * -flowDirection
                targetZ = z -- * -flowDirection
            end

            
        end

        simulation.state.angle = MathUtils:LerpAngle(
            simulation.state.angle,
            targetY,
            simulation.constants.turnSpeedFrac * cmd.deltaTime
        )

        simulation.state.angleX = MathUtils:LerpAngle(
                simulation.state.angleX,
                targetX,
                simulation.constants.turnSpeedFrac * cmd.deltaTime
            )

            simulation.state.angleZ = MathUtils:LerpAngle(
                simulation.state.angleZ,
                targetZ,
                simulation.constants.turnSpeedFrac * cmd.deltaTime
            )
    end
end

return module