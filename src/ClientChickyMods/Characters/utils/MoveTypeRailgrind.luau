--[[
    MoveTypeRailgrind.lua
    Initiate a rail ride when landing on a rail

    Basically the same thing as a wallride but with tweaks
]]
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local module = {}

local path = game.ReplicatedStorage.Shared.Chickynoid
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)
local MoveActions = require(script.Parent.MoveActions)

local TURN_FACTOR = 10
local JUMPLOCK = 0.15
local _cooldown = 0.2

local MIN_RAIDUS = 1.5
local MAX_RAIDUS = 5
local RADIUS_DIFF = MAX_RAIDUS - MIN_RAIDUS

local RADIUS_DEBUG = false and RunService:IsClient() and RunService:IsStudio()
local _debugPart = nil
-- TODO: attempt to refind flow part, else kick off back to floor and
function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Railgrind",
        self.ActiveThink,
        self.AlwaysThink,
        self.StartState,
        self.EndState
    )

    simulation.state.flowPart = nil
    simulation.state.railgrindCooldown = 0
    simulation.state.flowDirection = 1
    simulation.state.flowOffset = 0
    simulation.state.railgrindTime = 0

    -- constants
    simulation.constants.posOffset = 2.5
    simulation.constants.railgrindSpeed = 48
    simulation.constants.speedThreshold = 0.5
    simulation.constants.railjumpXPunch = 40
    simulation.constants.railjumpYPunch = 40

    if RADIUS_DEBUG then
        _debugPart = Instance.new("Part")
        _debugPart.Anchored = true
        _debugPart.Transparency = 1
        _debugPart.Color = Color3.fromHSV(0.603070, 0.596078, 1)
        _debugPart.CastShadow = false
        _debugPart.Material = Enum.Material.Neon
        _debugPart.Parent = workspace
    end
end

local function _generateRailData(simulation, flowPart, _forceFlow)
    local offset = flowPart.CFrame:PointToObjectSpace(simulation.state.pos)

    local lookcf = CFrame.lookAt(simulation.state.pos, simulation.state.pos +  (simulation.state.vel - Vector3.new(0, simulation.state.vel.Y, 0)))
    local lookOffset = flowPart.CFrame:VectorToObjectSpace(lookcf.LookVector)
    -- get flow direction based on current movement
    local flowDirection = lookOffset.Z < 0 and -1 or 1
    if lookOffset.Z == 0 then -- use previous move direction if coming in at a parallel/perpendicular angle
        flowDirection = simulation.state.flowDirection
    end

    -- set state
    simulation.state.flowDirection = flowDirection
    simulation.state.flowOffset = offset.Z
    simulation.state.flowPart = flowPart

    -- check for future rail
    simulation.state.nextRail = nil
    local attach = flowPart:FindFirstChild(tostring(flowDirection))
    if attach then
        -- get touching rails
        local parts = flowPart:GetTouchingParts()
        -- remove invalid rails for safety
        for i = #parts, 1, -1 do
            local v = parts[i]
            if v:FindFirstChild("-1") == nil or v:FindFirstChild("1") == nil
            or not CollectionService:HasTag(v, "Rail") then
                table.remove(parts, i)
            end
        end
        
        local attachPos = attach.WorldPosition
        if #parts > 0 then
            if #parts > 1 then
                -- find closest rail with simple math
                table.sort(parts, function(a, b)
                    local posFlowA = (a["1"].WorldPosition - attachPos).Magnitude
                    local negFlowA = (a["-1"].WorldPosition - attachPos).Magnitude
                    local flowA = negFlowA < posFlowA and negFlowA or posFlowA

                    local posFlowB = (b["1"].WorldPosition - attachPos).Magnitude
                    local negFlowB = (b["-1"].WorldPosition - attachPos).Magnitude
                    local flowB = negFlowB < posFlowB and negFlowB or posFlowB
                    return flowA < flowB
                end)
            end

            -- check if either end of the rail is close enough to the current rail
            local nextRail = parts[1]
            local posFlowA = (nextRail["1"].WorldPosition - attachPos).Magnitude
            local negFlowA = (nextRail["-1"].WorldPosition - attachPos).Magnitude
            local flowA = negFlowA < posFlowA and negFlowA or posFlowA
            if flowA <= 1.5 then
                simulation.state.nextRail = nextRail
            end
        end
    end
    return true
end

function _findRailPart(simulation)
    local onGround = nil
    local dir =  Vector3.new(0, 3, 0)
    -- local result = CollisionModule:Sweep(simulation.state.pos, simulation.state.pos - dir)
    -- local resultUp = CollisionModule:Sweep(simulation.state.pos, simulation.state.pos + dir)
    
    -- -- prioritize jumping up into a rail
    -- if resultUp.hullRecord and simulation.state.vel.Y > 0 then
    --     result = resultUp
    -- end

    -- if result.hullRecord then
    --     local instance = result.hullRecord.instance
    --     if instance and instance ~= simulation.state.flowPart then
    --         onGround = instance
    --     end
    -- else -- attempt wider check based on speed (faster = more lenient rail snap)
    local speed = simulation.state.currentSpeed
    local radPerc = math.clamp(speed / simulation.constants.boostSpeed, 0, 1)
    local radius = MIN_RAIDUS + (RADIUS_DIFF * radPerc)
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = CollectionService:GetTagged("Rail")
    params.FilterType = Enum.RaycastFilterType.Whitelist
    params.MaxParts = 5

    local baseCF = CFrame.new(simulation.state.pos - (dir * 0.75))
    * CFrame.fromOrientation(0, simulation.state.angle, 0)
    
    local size = Vector3.new(radius, dir.Y, radius)

    local hits = workspace:GetPartBoundsInBox(
        baseCF, -- raise up a little bit to hit torso radius
        size,
        params
    )

    if RADIUS_DEBUG and _debugPart then
        _debugPart.CFrame = baseCF
        _debugPart.Size = size
        _debugPart.Transparency = 0.5
    end

    if hits[1] ~= nil and hits[1] ~= simulation.state.flowPart then
        if #hits > 1 then
            -- sort by closest to baseCF
            table.sort(hits, function(a, b)
                local apos = (baseCF.Position - a.Position).Magnitude
                local bpos = (baseCF.Position - b.Position).Magnitude
                return apos < bpos
            end)
        end
        -- got a rail!
        -- print("got expanded hitbox rail")
        onGround = hits[1]
    end

    if onGround ~= nil and CollectionService:HasTag(onGround, "Rail") then
        local flowPart = onGround
        if simulation:GetMoveState().name ~= "Railgrind" then
            local result = _generateRailData(simulation, flowPart)
            if result then
                simulation:SetMoveState("Railgrind")
            end
        end
    end
end

function module.AlwaysThink(simulation, cmd)
    if simulation.state.railgrindCooldown > 0 then
        simulation.state.railgrindCooldown = math.max(simulation.state.railgrindCooldown - cmd.deltaTime, 0)
    else
        _findRailPart(simulation)
    end
end

function module.StartState(simulation, prevState)
    -- set parameters
    simulation.state.lastFlowPart = simulation.state.flowPart
    simulation.state.startSpeed = math.min(simulation.state.currentSpeed, simulation.constants.railgrindSpeed)
    simulation.state.inAir = 0.5

    -- award boost
    simulation.state.boostMeter = math.min(simulation.state.boostMeter + 0.2, simulation.constants.maxBoostMeter)
    
    -- play animations
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel1)
    simulation.characterData:PlayAnimation(Enums.Anims.Railgrind, Enums.AnimChannel.Channel1, false)

    simulation.characterData:PlayRootSound(Enums.RootSounds.Railgrind, Enums.SoundChannel.Channel0, true)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Land, Enums.SoundChannel.Channel1, true)
end

function module.EndState(simulation, nextState)
    simulation.state.flowPart = nil
    simulation.state.railgrindCooldown = _cooldown
    simulation.state.railgrindTime = 0
    simulation.state.angleX = 0
    simulation.state.angleZ = 0
    simulation.state.baseLockout = 0.1
    simulation.state.lastGround = nil
    simulation.state.usedAirBoost = false


    simulation.characterData:StopRootSound(Enums.SoundChannel.Channel0)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Jump, Enums.SoundChannel.Channel1, true)
end

function module.ActiveThink(simulation, cmd)
    local flowPart = simulation.state.flowPart
    if flowPart == nil then
        if simulation.state.lastFlowPart ~= nil then
            simulation.state.flowPart = simulation.state.flowPart
            flowPart = simulation.state.lastFlowPart
            print("force reset")
            simulation.characterData:PlayAnimation(Enums.Anims.Railgrind, Enums.AnimChannel.Channel1, false)
        else
            return
        end
    end

    local currentSpeed = simulation.state.startSpeed
    if cmd.boost > 0
     and currentSpeed <= simulation.constants.boostSpeed
     and MoveActions.CanBoost(simulation) then

            MoveActions.Boost(simulation, cmd.deltaTime)
            -- custom boost movement
            simulation.state.startSpeed = math.min(
                currentSpeed + (cmd.deltaTime * simulation.constants.boostAcceleration),
                simulation.constants.boostSpeed
            )

            simulation.characterData:PlayAnimation(Enums.Anims.RailBoost, Enums.AnimChannel.Channel1, false)
    elseif cmd.boost <= 0 or not MoveActions.CanBoost(simulation) then
        if currentSpeed > simulation.constants.railgrindSpeed then
            simulation.state.startSpeed = math.max(
                currentSpeed - (cmd.deltaTime * simulation.constants.boostAcceleration * 0.5),
                simulation.constants.railgrindSpeed
            )
        end

        simulation.characterData:PlayAnimation(Enums.Anims.Railgrind, Enums.AnimChannel.Channel1, false)
        MoveActions.Unboost(simulation, cmd.deltaTime)
    end

    simulation.state.airSpeed = currentSpeed
    simulation.state.currentSpeed = currentSpeed

    -- Do trick:?
    if cmd.trick > 0 and simulation.state.trick <= 0 then
        MoveActions.Trick(simulation, cmd.trick)
    else
        if simulation.state.trick > 0 then
			simulation.state.trick = math.max(simulation.state.trick - cmd.deltaTime, 0)
        elseif simulation.state.didTrick == 1 then
			simulation.state.didTrick = 0
        end
    end

    -- Do railjump?
    -- simulation.characterData:PlayAnimation(Enums.Anims.Railgrind, Enums.AnimChannel.Channel1, false)
    simulation.state.railgrindTime += cmd.deltaTime
    if cmd.y > 0 and simulation.state.railgrindTime > JUMPLOCK then
        -- Play jump anim
        local vec = (simulation.state.vel)
         + Vector3.new(
            cmd.x * simulation.constants.railjumpXPunch,
            0,
            cmd.z * simulation.constants.railjumpXPunch)

        local unitVec = vec.Unit
        unitVec = Vector3.new(unitVec.X, 0, unitVec.Z)
        unitVec *= simulation.state.currentSpeed
        simulation.state.vel = unitVec + Vector3.new(0, simulation.constants.railjumpYPunch, 0)
        -- simulation.state.currentSpeed = (simulation.state.vel - Vector3.new(0, simulation.state.vel.Y, 0)).Magnitude
        simulation:SetMoveState("Base")
        simulation.characterData:StopAllAnimation()
        simulation.characterData:PlayAnimation(Enums.Anims.Jump, Enums.AnimChannel.Channel2, true, 0.2)
        return
    end


    local flowDirection = simulation.state.flowDirection
    local railgrindVector = Vector3.new(0, simulation.constants.posOffset, simulation.state.flowOffset)

    -- local finalCF = flowPart.CFrame * railgrindCF
    simulation.state.vel = flowPart.CFrame.LookVector * currentSpeed * (-simulation.state.flowDirection)

    simulation.state.flowOffset +=  (flowDirection * currentSpeed) * cmd.deltaTime
    simulation:SetPosition(flowPart.CFrame:PointToWorldSpace(railgrindVector))

    local targetX = math.rad(flowPart.Orientation.X) * -flowDirection
    local targetY = math.rad(flowPart.Orientation.Y) + (flowDirection == 1 and math.rad(180) or 0)
    local targetZ = math.rad(flowPart.Orientation.Z) * -flowDirection

    simulation.state.targetAngle = targetY
    simulation.state.angle = MathUtils:LerpAngle(
        simulation.state.angle,
        simulation.state.targetAngle,
        TURN_FACTOR * cmd.deltaTime
    )

    simulation.state.angleX = MathUtils:LerpAngle(
        simulation.state.angleX,
        targetX,
        TURN_FACTOR * cmd.deltaTime
    )

    simulation.state.angleZ = MathUtils:LerpAngle(
        simulation.state.angleZ,
        targetZ,
        TURN_FACTOR * cmd.deltaTime
    )

    -- check for rail end
    local finished = false
    local bonus = 0
    if simulation.state.nextRail == nil then
        bonus = 1
    end
    if simulation.state.flowDirection == -1 then
        finished	= simulation.state.flowOffset < -((flowPart.Size.Z * 0.5) + bonus)
    elseif simulation.state.flowDirection == 1 then
        finished	= simulation.state.flowOffset > (flowPart.Size.Z * 0.5) + bonus
    end

    if finished then
        if simulation.state.nextRail then
            _generateRailData(simulation, simulation.state.nextRail)
        else
            -- simulation.characterData:StopAnimation(1)
            simulation:SetMoveState("Base")
            simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, true, 0.2)
            -- simulation:SetPosition(flowPart.CFrame:PointToWorldSpace(railgrindVector))

        end
    end
end



return module