--[[
    MoveTypewallride.lua
    Initiate a wall run when colliding with a wall at/past a velocity threshold
    Author: seyai
]]
local CollectionService = game:GetService("CollectionService")
local module = {}

local path = game.ReplicatedFirst.Chickynoid.Shared
local CollisionModule = require(path.Simulation.CollisionModule)
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)

local TURN_FACTOR = 20
local CONTINUE_FRAMES = 6
local JUMPLOCK = 0.15
local _cooldown = 0.05

function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Wallride",
        self.ActiveThink,
        self.AlwaysThink,
        self.StartState,
        self.EndState
    )

    -- define wall run constants here
    simulation.state.wallrideCooldown = 0
    simulation.state.flowDirection = 0
    simulation.state.flowOffset = 0
    simulation.state.positionOffset = Vector2.new()

    simulation.constants.wallrideSpeed = 45
    simulation.constants.speedThreshold = 0.4
    simulation.constants.walljumpXPunch = 17
    simulation.constants.walljumpYPunch = 35
end

-- use to check if wallride is available
function module.AlwaysThink(simulation, cmd)
    -- local state = simulation:GetMoveState()
    -- if state then
    --     if state.name == "Railgrind" or state.name == "Wallride" or state.name == "Splinegrind" then
    --         return
    --     end
    -- else
    --     return
    -- end

    if simulation.state.wallrideCooldown > 0 then
        simulation.state.wallrideCooldown = math.max(simulation.state.wallrideCooldown - cmd.deltaTime, 0)
    end

    local onGround = nil
    onGround = simulation:DoGroundCheck(simulation.state.position)
    local offCooldown = simulation.state.wallrideCooldown == 0
    -- local speedCheck = (simulation.state.vel).Magnitude >= simulation.constants.wallrideSpeed * simulation.constants.speedThreshold

    local function wallSweep(timeToProject)
        -- check for available wallride
        local endPos = simulation.state.position + (simulation.state.vel * timeToProject)
        local result = CollisionModule:Sweep(simulation.state.position, endPos)
        if result.hullRecord then
            local instance = result.hullRecord.instance
            if instance then
                if CollectionService:HasTag(instance, "Wallride") then
                    local flowPart = instance
                    local offset = flowPart.CFrame:PointToObjectSpace(simulation.state.position)

                    -- TODO: final check is to make sure that they are actually
                    -- able to slide along wall, change offset check
                    if math.abs(offset.X) > flowPart.Size.X/2 then
                        if offset.Y <= 0 and math.abs(offset.Y) < (flowPart.Size.Y/2 - 1)
                        or offset.Y > 0 and math.abs(offset.Y) < (flowPart.Size.Y/2)  then
                            local lookOffset = flowPart.CFrame:VectorToObjectSpace(simulation.state.vel)
                            local flowDirection = lookOffset.Z <= 0 and -1 or 1
                            simulation.state.flowDirection = flowDirection
                            simulation.state.flowOffset = offset.Z
                            simulation.state.positionOffset = Vector2.new(
                                math.sign(offset.X) * (instance.Size.X/2 + 2.5),
                                offset.Y
                            )
                            simulation.state.flowPart = {
                                active = 1,
                                Position = flowPart.Position,
                                Orientation = flowPart.Orientation,
                                CFrame = flowPart.CFrame,
                                Size = flowPart.Size
                            }

                            local offsetSign = math.sign(offset.X)
                            if flowDirection == 1 then
                                if offsetSign == 1 then
                                    simulation.state.wallside = 1 -- R
                                elseif offsetSign == -1 then
                                    simulation.state.wallside = -1 -- L
                                end
                            elseif flowDirection == -1 then
                                if offsetSign == -1 then
                                    simulation.state.wallside = 1 -- R
                                elseif offsetSign == 1 then
                                    simulation.state.wallside = -1 -- L
                                end
                            end

                            return true
                        end
                    end
                end
                return false, instance
            end
        end
        return false
    end

    if offCooldown and onGround == nil then
        if simulation:GetMoveState().name == "Wallride" then
            -- check additional walls
            -- local result, hit = wallSweep(cmd.deltaTime * 5)

            local result, hit = wallSweep(cmd.deltaTime * CONTINUE_FRAMES)

            if not result and hit then
                simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, false)
                simulation:SetMoveState("Base")
            end
        else
            local result = wallSweep(cmd.deltaTime)
            if result then
                simulation:SetMoveState("Wallride")
            end
        end
    end
end

-- state init
function module.StartState(simulation, prevState)
    -- set animations
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel1)
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)

    if simulation.state.wallside == 1 then -- right anim
        simulation.characterData:PlayAnimation(Enums.Anims.WallrideR, Enums.AnimChannel.Channel1, false)
    elseif simulation.state.wallside == -1 then -- left anim
        simulation.characterData:PlayAnimation(Enums.Anims.WallrideL, Enums.AnimChannel.Channel1, false)
    end
    simulation.state.inAir = 0.7

    -- award boost
    simulation.state.boostMeter = math.min(simulation.state.boostMeter + 0.2, simulation.constants.maxBoostMeter)

    simulation.characterData:PlayRootSound(Enums.RootSounds.Land, Enums.SoundChannel.Channel1, true)
end

function module.EndState(simulation, nextState)
    -- reset shared flow state
    simulation.state.flowOffset = 0

    -- go on cooldown
    simulation.state.wallrideCooldown = _cooldown
    simulation.state.wallrideTime = 0
    simulation.state.baseLockout = 0.2
    simulation.state.lastGround = nil
    simulation.state.usedAirBoost = false

    -- reset flowpart
    simulation.state.flowPart.active = -1


    simulation.characterData:PlayRootSound(Enums.RootSounds.Jump, Enums.SoundChannel.Channel1, true)
end

function module.ActiveThink(simulation, cmd)
    if not simulation.state.flowPart then simulation:SetMoveState("Base") return end
    
    -- Do walljump?
    simulation.state.wallrideTime += cmd.deltaTime 
    if cmd.y > 0 and simulation.state.wallrideTime > JUMPLOCK then

        local cf = CFrame.lookAt(simulation.state.position, simulation.state.position + simulation.state.vel)
        local rightVector = cf.RightVector.Unit * -simulation.state.wallside
        simulation.state.vel = (simulation.state.vel)
         + (rightVector * simulation.constants.walljumpXPunch)
         + Vector3.new(0, simulation.constants.walljumpYPunch, 0)

        -- Decide animation to play
        if simulation.state.wallside == 1 then
           simulation.characterData:PlayAnimation(Enums.Anims.WalljumpR, Enums.AnimChannel.Channel2, true, 0.2)
        else
           simulation.characterData:PlayAnimation(Enums.Anims.WalljumpL, Enums.AnimChannel.Channel2, true, 0.2)
        end

        -- Get angle
        local x, y, z = CFrame.lookAt(simulation.state.position, simulation.state.position + rightVector):ToOrientation()
        simulation.state.angle = MathUtils:LerpAngle(
            simulation.state.angle,
            y,
            0.6
        )

        simulation:SetMoveState("Base")
        simulation.characterData:PlayRootSound(Enums.RootSounds.Jump, Enums.SoundChannel.Channel1, true)

        return
    end
    
    local wallrideCf = CFrame.new(simulation.state.positionOffset.X, simulation.state.positionOffset.Y, simulation.state.flowOffset)
    -- local angleCf = CFrame.Angles(0, (simulation.state.flowDirection == 1 and math.rad(180) or 0), 0)

    local flowPart = simulation.state.flowPart
    -- calculate things
    local finalCF = flowPart.CFrame * wallrideCf -- * angleCf
    simulation.state.vel = flowPart.CFrame.LookVector * simulation.constants.wallrideSpeed * (-simulation.state.flowDirection)

    -- calculate more things
    simulation.state.flowOffset = simulation.state.flowOffset + (simulation.state.flowDirection * simulation.constants.wallrideSpeed) * cmd.deltaTime
    simulation:SetPosition(finalCF.Position)

    local newAngle = math.rad(flowPart.Orientation.Y)
    if simulation.state.flowDirection == 1 then
        newAngle += math.rad(180)
    end
    simulation.state.targetAngle = newAngle
    simulation.state.angle = MathUtils:LerpAngle(
        simulation.state.angle,
        simulation.state.targetAngle,
        TURN_FACTOR * cmd.deltaTime
    )

    -- check for wall end
    local finished = false
    if simulation.state.flowDirection == -1 then
        finished	= simulation.state.flowOffset < -(flowPart.Size.Z / 2)
    elseif simulation.state.flowDirection == 1 then
        finished	= simulation.state.flowOffset > flowPart.Size.Z / 2
    end

    if finished then
        simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, false)
        simulation:SetMoveState("Base")
    end
end

return module