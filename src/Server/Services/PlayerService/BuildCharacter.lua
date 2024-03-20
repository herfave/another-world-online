local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Components = require(Shared.ECS.Components)

return function(character, entityId)
    -- ignore camera
    character:AddTag("_CameraIgnore")
    -- insert model component for player
    local world = Knit.GetService("MatterService"):GetWorld()
    local modelComp = world:get(entityId, Components.Model)
    if modelComp then
        world:insert(
            entityId,
            modelComp:patch({ value = character })
        )
    else
        world:insert(
            entityId,
            Components.Model { value = character }
        )
    end

    -- create mob capsule
    local capsule = ReplicatedStorage.Assets.Models.Capsule:Clone()
    capsule.Transparency = 1
    local rigid = Instance.new("RigidConstraint")
    rigid.Attachment0 = character:FindFirstChild("RootRigAttachment", true)
    rigid.Attachment1 = capsule:FindFirstChildOfClass("Attachment")
    rigid.Parent = capsule
    capsule.Parent = character
    capsule.CollisionGroup = "MobCapsule"

    -- setup character physics controller
    local playerHumanoid = character:WaitForChild("Humanoid", 3)

    local animate = character:FindFirstChild("Animate")
    local health = character:FindFirstChild("Health")
    animate.Enabled = false
    health.Enabled = false

    task.wait()
    animate:Destroy()
    health:Destroy()

    playerHumanoid.EvaluateStateMachine = false
    -- modify controllers as needed
    local controller: ControllerManager = ReplicatedStorage.Assets:FindFirstChild("DefaultManager"):Clone()
    local groundController: GroundController = controller:FindFirstChild("GroundController")
    local airController: AirController = controller:FindFirstChild("AirController")
    groundController.GroundOffset = playerHumanoid.HipHeight
    groundController.FrictionWeight = 0.75
    airController.BalanceRigidityEnabled = true

    -- create sensors
    local groundSensor: ControllerPartSensor = Instance.new("ControllerPartSensor")
    groundSensor.SearchDistance = 4
    groundSensor.SensorMode = Enum.SensorMode.Floor
    groundSensor.Parent = character.PrimaryPart

    local climbSensor: ControllerPartSensor = Instance.new("ControllerPartSensor")
    climbSensor.SearchDistance = 1
    climbSensor.SensorMode = Enum.SensorMode.Ladder
    climbSensor.Parent = character.PrimaryPart

    local waterSensor = Instance.new("BuoyancySensor")
    waterSensor.Parent = character.PrimaryPart

    controller.GroundSensor = groundSensor
    controller.ClimbSensor = climbSensor
    controller.RootPart = character.PrimaryPart

    controller.Parent = character

    playerHumanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if playerHumanoid.Health <= 0 then
            playerHumanoid:ChangeState(Enum.HumanoidStateType.Dead)
        end
    end)
end