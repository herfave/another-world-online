local Knit = require(game.ReplicatedStorage.Packages.Knit)
return function(sm, event, from, to)

    local CharacterController = Knit.GetController("CharacterController")
    local cm: ControllerManager = CharacterController.ControllerManager
    local primaryPart: BasePart = CharacterController.Character.PrimaryPart

    if CharacterController._delayFall then task.cancel(CharacterController._delayFall) end
    primaryPart.AssemblyLinearVelocity = Vector3.zero
    cm.MovingDirection = Vector3.zero
    -- setup attack name
    CharacterController.AttackCounter += 1
    local state = "Ground"
    local airController = cm:FindFirstChild("AirController")
    if cm.ActiveController == airController and airController.Active then
       state = "Air"
    end

    local MaxCounter = state == "Air" and 3 or 5

    local animName: string = state .. "Attack" .. tostring(CharacterController.AttackCounter)
    -- get attack animation track
    local track: AnimationTrack = CharacterController.Animations:GetTrack(animName)
    
    -- get attack trigger
    local connection = track:GetMarkerReachedSignal("Attack"):Connect(function()
        CharacterController.Hitbox:Start()
    end)
    
    -- play animation
    CharacterController:PlayAnimation(animName)
    CharacterController.AttackEnded = false

    -- create movement forces
    local linearVel: LinearVelocity = Instance.new("LinearVelocity")
    linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVel.VectorVelocity = cm.FacingDirection * 10
    linearVel.MaxForce = primaryPart.AssemblyMass * workspace.Gravity * 2
    linearVel.Attachment0 = primaryPart:FindFirstChild("RootAttachment")
    linearVel.Parent = primaryPart

    game:GetService("Debris"):AddItem(linearVel, track.Length * 0.7)
    -- allow for next attack earlier than the animation finishing
    local frameTime = CharacterController.FrameTime * 15
    -- print(track.Length - frameTime)
    if track.Length <= frameTime then
        frameTime = 0
    end
    task.delay(track.Length - frameTime, function()
        CharacterController.AttackCancel = true
        sm.attack_end()
        CharacterController.Hitbox:Stop()
    end)

    -- allow other states to transition out of the attack_end state
    if CharacterController._inAttack then
        task.cancel(CharacterController._inAttack)
    end
    CharacterController._inAttack = task.delay(track.Length, function()
        CharacterController.AttackEnded = true
        connection:Disconnect()
    end)

    -- reset attacks, put on cooldown after combo
    if CharacterController.AttackCounter == MaxCounter then
        CharacterController.AttackCounter = 0 -- reset
        CharacterController.AttackOnCooldown = true
        task.delay(1.1, function()
            CharacterController.AttackOnCooldown = false
        end)
    end
end