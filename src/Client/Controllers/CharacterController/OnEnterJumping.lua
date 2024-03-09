local Knit = require(game.ReplicatedStorage.Packages.Knit)

function(sm, event, from, to)
    local CharacterController = Knit.GetController("CharacterController")
    local cm: ControllerManager = CharacterController.ControllerManager
    local primaryPart: BasePart = CharacterController.Character.PrimaryPart
    local groundSensor: ControllerPartSensor = cm.GroundSensor :: ControllerPartSensor

    local function setController(name: string)
        cm.ActiveController = cm:FindFirstChild(name)
    end

    CharacterController.JumpCounter += 1
    primaryPart.AssemblyLinearVelocity = Vector3.new(
        primaryPart.AssemblyLinearVelocity.X,
        0.001,
        primaryPart.AssemblyLinearVelocity.Z
    )

    local height = 10
    if CharacterController.JumpCounter == 2 then
        height = 7.5
    end
    local jumpForce = math.sqrt(2 * workspace.Gravity * height) * primaryPart.AssemblyMass
    -- if CharacterController.JumpCounter == 2 then
    --     jumpForce = 500
    -- end

    local jumpImpulse = Vector3.new(0, jumpForce, 0)
    primaryPart:ApplyImpulse(jumpImpulse)
    setController("AirController")

    -- floor receives equal and opposite force
    local floor = groundSensor.SensedPart
    if floor then
        floor:ApplyImpulseAtPosition(-jumpImpulse, groundSensor.HitFrame.Position)
    end
    CharacterController:PlayAnimation("Jump")
end