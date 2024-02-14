--[[
    MoveTypeRailgrind.lua
    Initiate a rail ride when landing on a rail

    Basically the same thing as a wallride but with tweaks
]]
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local module = {}

local path = game.ReplicatedFirst.Chickynoid.Shared
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)
local MoveActions = require(script.Parent.MoveActions)

local TURN_FACTOR = 10
local JUMPLOCK = 0.15
local _cooldown = 1

local MIN_RAIDUS = 1.5
local MAX_RAIDUS = 5
local RADIUS_DIFF = MAX_RAIDUS - MIN_RAIDUS

local RADIUS_DEBUG = false and RunService:IsClient() and RunService:IsStudio()

local RAIL_PARAMS = OverlapParams.new()
    RAIL_PARAMS.FilterDescendantsInstances = CollectionService:GetTagged("Rail")
    RAIL_PARAMS.FilterType = Enum.RaycastFilterType.Include
    RAIL_PARAMS.MaxParts = 3

local _debugPart = nil
-- TODO: attempt to refind flow part, else kick off back to floor and

function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Railgrind",
        self.ActiveThink,
        self.AlwaysThink,
        self.StartState,
        self.EndState
    )

    simulation.state.railgrindCooldown = 0
    simulation.state.flowDirection = 1
    simulation.state.flowOffset = 0
    simulation.state.railgrindTime = 0

    -- constants
    simulation.constants.posOffset = 2.5
    simulation.constants.railgrindSpeed = 30
    simulation.constants.speedThreshold = 0.5
    simulation.constants.railjumpXPunch = 24
    simulation.constants.railjumpYPunch = 24

    if RADIUS_DEBUG then
        _debugPart = Instance.new("Part")
        _debugPart.Anchored = true
        _debugPart.Transparency = 1
        _debugPart.Color = Color3.fromHSV(0.603070, 0.596078, 1)
        _debugPart.CastShadow = false
        _debugPart.Material = Enum.Material.Neon
        _debugPart.Parent = workspace
    end
    --TODO: pregenerate all connected rails in both directions.
end

local function _generateRailData(simulation, flowPart, flowDirection)
    local offset = flowPart.CFrame:PointToObjectSpace(simulation.state.position)

    local lookcf = CFrame.lookAt(simulation.state.position, simulation.state.position +  (simulation.state.vel - Vector3.new(0, simulation.state.vel.Y, 0)))
    local lookOffset = flowPart.CFrame:VectorToObjectSpace(lookcf.LookVector)
    -- get flow direction based on current movement
    flowDirection = flowDirection or lookOffset.Z < 0 and -1 or 1
    if lookOffset.Z == 0 then -- use previous move direction if coming in at a parallel/perpendicular angle
        flowDirection = simulation.state.flowDirection
    end

    -- set state
    simulation.state.flowDirection = flowDirection
    simulation.state.flowOffset = offset.Z
    
    -- build from instance
    simulation.state.flowPart = {
        active = 1,
        Position = flowPart.Position,
        Orientation = flowPart.Orientation,
        CFrame = flowPart.CFrame,
        Size = flowPart.Size
    }

    -- check for future rail
    local player = game.Players:GetPlayerByUserId(simulation.userId)
    local nextRailObject = player:FindFirstChild("NextRail")
    nextRailObject.Value = nil
    local attach = flowPart:FindFirstChild(tostring(flowDirection))
    if attach then
        -- get touching rails
        local parts = workspace:GetPartBoundsInRadius(attach.WorldCFrame.Position, 2.5, RAIL_PARAMS)
        -- remove invalid rails for safety
        for i = #parts, 1, -1 do
            local v = parts[i]
            if v:FindFirstChild("-1") == nil or v:FindFirstChild("1") == nil
            or not CollectionService:HasTag(v, "Rail") or v == attach.Parent then
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
            if flowA <= 5 then
                nextRailObject.Value = nextRail
            else
                print(flowA)
            end
        end
    end
    return true
end

local function _findRailPart(simulation)
    local onGround = nil
    local dir =  Vector3.new(0, 3, 0)

    local flowPart

    local speed = simulation.state.currentSpeed
    local radPerc = math.clamp(speed / simulation.constants.boostSpeed, 0, 1)
    local radius = MIN_RAIDUS + (RADIUS_DIFF * radPerc)
    

    local baseCF = CFrame.new(simulation.state.position - (dir * 0.75))
    * CFrame.fromOrientation(0, simulation.state.angle, 0)
    
    local size = Vector3.new(radius, dir.Y, radius)

    local hits = workspace:GetPartBoundsInBox(
        baseCF, -- raise up a little bit to hit torso radius
        size,
        RAIL_PARAMS
    )

    if RADIUS_DEBUG and _debugPart then
        _debugPart.CFrame = baseCF
        _debugPart.Size = size
        _debugPart.Transparency = 0.5
    end
    
    if hits[1] ~= nil and hits[1] ~= flowPart then
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
        flowPart = onGround
        return flowPart
    end
    return nil
end

function module.AlwaysThink(simulation, cmd)

    local state = simulation:GetMoveState()
    if state then
        if state.name == "Railgrind" then
            return
        end
    else
        return
    end


    if simulation.state.railgrindCooldown > 0 then
        simulation.state.railgrindCooldown = math.max(simulation.state.railgrindCooldown - cmd.deltaTime, 0)
    else
        local flowPart = _findRailPart(simulation)
        if flowPart and simulation:GetMoveState().name ~= "Railgrind" then
            local result = _generateRailData(simulation, flowPart)
            if result then
                simulation:SetMoveState("Railgrind")
            end
        end
    end
end

function module.StartState(simulation, prevState)
    -- set parameters
    local flowPart = simulation.state.flowPart
    -- flowPart.CFrame = CFrame.new(flowPart.Position) * CFrame.fromOrientation(
    --     flowPart.Orientation.X, flowPart.Orientation.Y, flowPart.Orientation.Z
    -- )
    simulation.state.startSpeed = math.min(simulation.state.currentSpeed, simulation.constants.railgrindSpeed)
    simulation.state.inAir = 0.7

    -- award boost
    simulation.state.boostMeter = math.min(simulation.state.boostMeter + 0.2, simulation.constants.maxBoostMeter)
    
    -- play animations
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel1)
    simulation.characterData:PlayAnimation(Enums.Anims.Railgrind, Enums.AnimChannel.Channel1, false)

    simulation.characterData:PlayRootSound(Enums.RootSounds.Railgrind, Enums.SoundChannel.Channel0, true)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Land, Enums.SoundChannel.Channel1, true)
    simulation.state.vel = flowPart.CFrame.LookVector * simulation.state.startSpeed * (-simulation.state.flowDirection)
end

function module.EndState(simulation, nextState)
    simulation.state.railgrindCooldown = _cooldown
    simulation.state.railgrindTime = 0
    simulation.state.angleX = 0
    simulation.state.angleZ = 0
    simulation.state.baseLockout = 0.2
    simulation.state.lastGround = nil
    simulation.state.usedAirBoost = false

    -- reset flowparts
    simulation.state.flowPart.active = -1

    simulation.characterData:StopRootSound(Enums.SoundChannel.Channel0)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Jump, Enums.SoundChannel.Channel1, true)
end

function module.ActiveThink(simulation, cmd)
    local flowPart = simulation.state.flowPart
    if flowPart == nil then
        flowPart = _findRailPart(simulation)
        if flowPart then
            _generateRailData(simulation, flowPart, simulation.state.flowDirection)
        end
    end

    local player = game.Players:GetPlayerByUserId(simulation.userId)
    local nextRailObject = player:FindFirstChild("NextRail")

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
        local boostedJump = 1
        -- if not isDownhill and newRailAngle >= MinRailAngle then
        --     boostedJump = 1.5
        -- end
        local vec = simulation.state.vel
         + Vector3.new(
            cmd.x * simulation.constants.railjumpXPunch,
            0,
            cmd.z * simulation.constants.railjumpXPunch)
        
        local unitVec = vec.Unit -- Vector3.new(vec.X, 0, vec.Z).Unit
        unitVec *= simulation.state.currentSpeed
        

        -- simulation.state.vel = unitVec + Vector3.new(0, simulation.constants.railjumpYPunch * boostedJump, 0)
        local constructedCf = CFrame.new(simulation.state.position)
        * CFrame.fromOrientation(
            simulation.state.angleX,
            simulation.state.targetAngle,
            simulation.state.angleZ
        )
        simulation.state.up = constructedCf.UpVector

        -- experimental vector math!
        local d = -constructedCf.UpVector
        local n = Vector3.new(0, -1, 0) -- world down normal
        local r = d - 2 * d:Dot(n) * n
    

        -- simulation:SetPosition(simulation.state.position + (simulation.state.vel * cmd.deltaTime))
        simulation.state.vel = unitVec + simulation.state.up * simulation.constants.railjumpYPunch * boostedJump-- Vector3.new(0, simulation.constants.railjumpYPunch * boostedJump, 0)
        
        -- print(simulation.state.vel)
        simulation:SetMoveState("Base")
        simulation.characterData:StopAllAnimation()
        simulation.characterData:PlayAnimation(Enums.Anims.Jump, Enums.AnimChannel.Channel2, true, 0.2)
        simulation.state.jumpThrust = simulation.constants.jumpThrustPower
        return
    end


    local flowDirection = simulation.state.flowDirection
    local railgrindVector = Vector3.new(0, simulation.constants.posOffset, simulation.state.flowOffset)

    -- local finalCF = flowPart.CFrame * railgrindCF

    simulation.state.flowOffset +=  (flowDirection * currentSpeed) * cmd.deltaTime
    simulation.state.vel = (flowPart.CFrame:PointToWorldSpace(railgrindVector) - simulation.state.position).Unit * currentSpeed
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
    if nextRailObject then
        if nextRailObject.Value == nil then
            bonus = 1
        end
    end
    if simulation.state.flowDirection == -1 then
        finished	= simulation.state.flowOffset < -(flowPart.Size.Z * 0.5)
    elseif simulation.state.flowDirection == 1 then
        finished	= simulation.state.flowOffset > (flowPart.Size.Z * 0.5)
    end

    if finished then
        if nextRailObject then
            if nextRailObject.Value ~= nil then
                _generateRailData(simulation, nextRailObject.Value, simulation.state.flowDirection)
                return
            end
        end

        simulation.state.vel += Vector3.new(0, simulation.state.railjumpYPunch, 0)
        simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, true, 0.2)
        simulation:SetPosition(simulation.state.position + Vector3.new(0, 1, 0))

        simulation:SetMoveState("Base")
    end
end



return module