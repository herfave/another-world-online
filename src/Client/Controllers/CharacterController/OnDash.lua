local Janitor = require(game.ReplicatedStorage.Packages.Janitor)
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local DashTime = 0.5
local DashSpeed = 22
return function(sm, event, from, to)
    local CharacterController = Knit.GetController("CharacterController")
    local cm: ControllerManager = CharacterController.ControllerManager
    local primaryPart: BasePart = CharacterController.Character.PrimaryPart
    local groundSensor: ControllerPartSensor = cm.GroundSensor :: ControllerPartSensor

    -- calculate directions
    local newLook = cm.FacingDirection
    if groundSensor.SensedPart then
        local newUp = groundSensor.HitNormal
        local newRight = newUp:Cross(cm.FacingDirection).Unit
        newLook = newRight:Cross(newUp).Unit
    end

    -- create movement forces
    local linearVel: LinearVelocity = Instance.new("LinearVelocity")
    linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVel.VectorVelocity = newLook * DashSpeed
    linearVel.MaxForce = math.huge
    linearVel.Attachment0 = primaryPart:FindFirstChild("RootAttachment")
    linearVel.Parent = primaryPart

    game:GetService("Debris"):AddItem(linearVel, DashTime)
    local castParams = RaycastParams.new()
    castParams.FilterDescendantsInstances = {primaryPart.Parent}
    castParams.FilterType = Enum.RaycastFilterType.Exclude


    local _janitor = Janitor.new()
    _janitor:Add(linearVel)
    _janitor:Add(function()
        if cm.FacingDirection.Magnitude > 0 then
            sm.run()
        else
            sm.idle()
        end
    end)

    _janitor:Add(game:GetService("RunService").PostSimulation:Connect(function()
        -- calculate directions
        local calcLook = cm.FacingDirection
        if groundSensor.SensedPart then
            local newUp = groundSensor.HitNormal
            local newRight = newUp:Cross(cm.FacingDirection).Unit
            calcLook = newRight:Cross(newUp).Unit
        end
        if linearVel then
            local currentDirection = linearVel.VectorVelocity.Unit
            local lerpDirection = currentDirection:Lerp(calcLook, 0.05).Unit
            linearVel.VectorVelocity = lerpDirection * DashSpeed
        end

        -- calculate if hitting something
        local cast = workspace:Raycast(primaryPart.Position, linearVel.VectorVelocity.Unit, castParams)
        if cast then
            if cast.Instance then
                -- linearVel.VectorVelocity = Vector3.zero
                print("hit")
                _janitor:Cleanup()
            end
        end
    end))

    task.delay(DashTime, function()
        _janitor:Destroy()
    end)
end