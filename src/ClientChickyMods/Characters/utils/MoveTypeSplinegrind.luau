-- TODO: Railgrind but using splines instead of parts!

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local module = {}

local Knit = require(ReplicatedStorage.Packages.Knit)
local KnitSplineHandle
if RunService:IsClient() then
    KnitSplineHandle = Knit.GetController("SplineController")
elseif RunService:IsServer() then
    KnitSplineHandle = Knit.GetService("ChickynoidService")
end

local path = game.ReplicatedStorage.Shared.Chickynoid
local MathUtils = require(path.Simulation.MathUtils)
local Enums = require(path.Enums)
local MoveActions = require(script.Parent.MoveActions)

local TURN_FACTOR = 100
local JUMPLOCK = 0.15
local _cooldown = 0.3

local MIN_RAIDUS = 1.5
local MAX_RAIDUS = 5
local RADIUS_DIFF = MAX_RAIDUS - MIN_RAIDUS

local RADIUS_DEBUG = false and RunService:IsClient() and RunService:IsStudio()
local _debugPart = nil

local WorldDown = Vector3.new(0, -1, 0)
local MinRailAngle = 10
local MaxRailAngle = 90
local MultiRatioBase = 90

function module:ModifySimulation(simulation)
    simulation:RegisterMoveState("Splinegrind",
        self.ActiveThink,
        self.AlwaysThink,
        self.StartState,
        self.EndState
    )

    simulation.state.splinegrindCooldown = 0
    simulation.state.splinegrindTime = 0

    if RADIUS_DEBUG then
        _debugPart = Instance.new("Part")
        _debugPart.Anchored = true
        _debugPart.Transparency = 1
        _debugPart.Color = Color3.fromHSV(0.603070, 0.596078, 1)
        _debugPart.CastShadow = false
        _debugPart.Material = Enum.Material.Neon
        _debugPart.Parent = workspace
    end

    simulation.state.lastSplineCFrame = CFrame.new(0, 0, 0)
    simulation.state.speedMultiplier = 1
end

function module.AlwaysThink(simulation, cmd)
    if simulation:GetMoveState().name == "Splinegrind" then return end -- don't cast if already spline
    if simulation.state.splinegrindCooldown > 0 then
        simulation.state.splinegrindCooldown = math.max(simulation.state.splinegrindCooldown - cmd.deltaTime, 0)
        return
    end

    if simulation.state.currentSpeed < 1 then return end

    local onGround = nil
    -- detect a spline rail and get t of spline and going direction
    local dir =  Vector3.new(0, 3, 0)
    local speed = simulation.state.currentSpeed
    local radPerc = math.clamp(speed / simulation.constants.boostSpeed, 0, 1)
    local radius = MIN_RAIDUS + (RADIUS_DIFF * radPerc)
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = CollectionService:GetTagged("SplineRail")
    params.FilterType = Enum.RaycastFilterType.Whitelist
    params.MaxParts = 5

    local baseCF = CFrame.new(simulation.state.pos - (dir * 0.75))
    * CFrame.fromOrientation(0, simulation.state.angle, 0)

    local size = Vector3.new(radius, dir.Y, radius)
    -- cast for spline parts
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

    -- sort and select closest spline part
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

    -- if spline part exists, get spline data from relative source
    if onGround then
        if onGround:FindFirstAncestor("Splines") then
            local splineFolder = onGround.Parent.Parent
            -- get spline from Knit somehow as well
            -- generate the same spline on both client and server, only build the visuals on the server for collision
            local knitSpline = KnitSplineHandle:GetSplineRail(splineFolder.Name)

            if knitSpline then
                if knitSpline.Spline then
                    -- compute direction
                    local lookcf = CFrame.lookAt(simulation.state.pos, simulation.state.pos +  (simulation.state.vel - Vector3.new(0, simulation.state.vel.Y, 0)))
                    local lookOffset = onGround.CFrame:VectorToObjectSpace(lookcf.LookVector)
                    local flowDirection = lookOffset.Z < 0 and -1 or 1

                    simulation.state.flowDirection = flowDirection
                    simulation.state.splinerail = knitSpline
                    simulation.state.splinepart = onGround
                    -- print("got spline!!", knitSpline.Spline.Length)
                    simulation:SetMoveState("Splinegrind")
                end
            end
        end
    end
end

function module.StartState(simulation, prevState)
    -- do the other things in MoveTypeRailgrind here
    simulation.state.startT = tonumber(simulation.state.splinepart.Name) / 200 -- convert to [0, 1] position
    simulation.state.splineT = simulation.state.startT

    -- set parameters
    simulation.state.startSpeed = math.min(simulation.state.currentSpeed, simulation.constants.railgrindSpeed)
    simulation.state.inAir = 0.5
    simulation.state.splineDistance = KnitSplineHandle:GetStraightDistance(simulation.state.splinerail.Name)

    -- award boost
    simulation.state.boostMeter = math.min(simulation.state.boostMeter + 0.2, simulation.constants.maxBoostMeter)

    -- play animations
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel1)
    simulation.characterData:StopAnimation(Enums.AnimChannel.Channel3)
    simulation.characterData:PlayAnimation(Enums.Anims.Railgrind, Enums.AnimChannel.Channel1, false)

    simulation.characterData:PlayRootSound(Enums.RootSounds.Railgrind, Enums.SoundChannel.Channel0, true)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Land, Enums.SoundChannel.Channel1, true)
end

function module.EndState(simulation, nextState)
    -- " " but for EndState
    simulation.state.angleX = 0
    simulation.state.angleZ = 0
    simulation.state.splinegrindCooldown = _cooldown
    simulation.state.baseLockout = 0.2

    simulation.characterData:StopRootSound(Enums.SoundChannel.Channel0)
    simulation.characterData:PlayRootSound(Enums.RootSounds.Jump, Enums.SoundChannel.Channel1, true)
end

function module.ActiveThink(simulation, cmd)
    -- calculate next speed multiplier
    local railNormal = -simulation.state.lastSplineCFrame.UpVector
    local newRailAngle = math.min(MathUtils:AngleBetweenVectors(railNormal, WorldDown), MaxRailAngle)
    local isBoosting = cmd.boost > 0 and MoveActions.CanBoost(simulation)
    local isDownhill = simulation.state.vel.Y < -1

    if newRailAngle >= MinRailAngle then
        if isDownhill then
            -- traveling downhill, increase speed
            simulation.state.startSpeed -= simulation.constants.gravity * cmd.deltaTime         
            -- if isBoosting then
            --     -- simulation.state.speedMultiplier 
            -- end
            simulation.state.speedMultiplier = MathUtils:CalculateMultiplier(
                newRailAngle, MultiRatioBase
            )
        elseif simulation.state.vel.Y >= -1 and not isBoosting then
            -- cap speed when traveling uphill
            simulation.state.speedMultiplier = math.max(simulation.state.speedMultiplier, 1.1)
        end
    end

    -- make vars of frequently used state
    local flowDirection = simulation.state.flowDirection
    local currentSpeed = simulation.state.startSpeed
    local SpeedMultiplier = simulation.state.speedMultiplier
    local MaxBoostSpeed = simulation.constants.boostSpeed * SpeedMultiplier
    local MaxRailSpeed = simulation.constants.railgrindSpeed * SpeedMultiplier
    -- print(SpeedMultiplier, currentSpeed, MaxRailSpeed)

    simulation.state.splinegrindTime += cmd.deltaTime
    -- listen for other commands while rideing that can affect spline position
    --// bonus actions
    if currentSpeed < 0 then
        simulation.state.flowDirection = -flowDirection
    end

    if isBoosting
     and currentSpeed <= MaxBoostSpeed then

            MoveActions.Boost(simulation, cmd.deltaTime)
            -- custom boost movement
            simulation.state.startSpeed = math.min(
                currentSpeed + (cmd.deltaTime * simulation.constants.boostAcceleration),
                MaxBoostSpeed
            )

            simulation.characterData:PlayAnimation(Enums.Anims.RailBoost, Enums.AnimChannel.Channel1, false)
    else
        if currentSpeed > MaxRailSpeed then
            simulation.state.startSpeed = math.max(
                currentSpeed - (cmd.deltaTime * simulation.constants.boostAcceleration),
                MaxRailSpeed
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
            simulation.state.trick = simulation.state.trick - cmd.deltaTime
        end
    end

    -- Do railjump?
    -- TODO: Jump using UpVector and add X/Z according to that with local spaces
    simulation.state.railgrindTime += cmd.deltaTime
    if cmd.y > 0 and simulation.state.railgrindTime > JUMPLOCK then
        -- Play jump anim
        local boostedJump = 1
        if not isDownhill and newRailAngle >= MinRailAngle then
            boostedJump = 1.5
        end
        local vec = (simulation.state.vel)
         + Vector3.new(
            cmd.x * simulation.constants.railjumpXPunch,
            0,
            cmd.z * simulation.constants.railjumpXPunch)
        
        local unitVec = Vector3.new(vec.X, 0, vec.Z).Unit
        unitVec *= simulation.state.currentSpeed
        

        -- simulation.state.vel = unitVec + Vector3.new(0, simulation.constants.railjumpYPunch * boostedJump, 0)
        local constructedCf = CFrame.new(simulation.state.pos)
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
    

        -- simulation:SetPosition(simulation.state.pos + (simulation.state.vel * cmd.deltaTime))
        simulation.state.vel = unitVec + Vector3.new(0, simulation.constants.railjumpYPunch * boostedJump, 0)
        
        -- print(simulation.state.vel)
        simulation:SetMoveState("Base")
        simulation.characterData:StopAllAnimation()
        simulation.characterData:PlayAnimation(Enums.Anims.Jump, Enums.AnimChannel.Channel2, true, 0.2)
        return
    end

    -- get new spline position
    local splineObj = simulation.state.splinerail
    local v = simulation.state.startSpeed
    -- convert position and length to [0, 1], then get distance
    local totalDistance = simulation.state.splineDistance

    local squashedV = (v / totalDistance) -- * cmd.deltaTime

    local currentPosition = simulation.state.splineT
    local step = squashedV * cmd.deltaTime * -flowDirection
    local t = currentPosition + step-- add new distance based on speed

    local posOnSpline = KnitSplineHandle:GetSplinePosition(splineObj.Name, t)
    local lastPos = KnitSplineHandle:GetSplinePosition(splineObj.Name, currentPosition)
    if posOnSpline then
        -- get new velocity from new cf
        local movingTo = CFrame.lookAt(
            lastPos,
            posOnSpline
        )

        local look = (movingTo.LookVector) -- * flowDirection

        simulation.state.vel = look * v
        simulation:SetPosition(posOnSpline + (movingTo.UpVector * 3))
        simulation.state.lastSplineCFrame = movingTo
        local x, y, z = movingTo:ToOrientation()
        local targetX = x -- * -flowDirection
        local targetY = y -- + (flowDirection == -1 and math.rad(180) or 0)
        local targetZ = z -- * -flowDirection

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

    -- elseif not posOnSpline and (t > 1 or t < 0) then
    --     simulation:SetPosition(simulation.state.pos +
    --         (simulation.state.vel * cmd.deltaTime * -flowDirection)
    --     )
    end

    simulation.state.splineT = t

    if t <= 0 or t >= 1 or not posOnSpline then
        -- end of ride, dismount
        simulation.state.vel += Vector3.new(0, simulation.state.railjumpYPunch, 0)
        simulation.characterData:PlayAnimation(Enums.Anims.Fall, Enums.AnimChannel.Channel1, true, 0.2)
        -- simulation:SetPosition(simulation.state.pos + (simulation.state.vel * cmd.deltaTime * 3 * flowDirection))

        simulation:SetMoveState("Base")
    end
end

return module