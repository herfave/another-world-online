--[[
    CharacterController.lua
    Author: Aaron (se_yai)

    Description: Manage character state
]]
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local FSM = require(Shared.FSM)
local AnimationPlayer = require(Shared.AnimationPlayer)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local WaitFor = require(Packages.WaitFor)
local Janitor = require(Packages.Janitor)

local CharacterController = Knit.CreateController { Name = "CharacterController" }


function CharacterController:InitStateMachine(cm: ControllerManager)
    self.JumpCounter = 0
    self.AttackCounter = 0
    local primaryPart = cm.RootPart
    -- find all sensors
    local groundSensor: ControllerPartSensor = cm.GroundSensor :: ControllerPartSensor
    local climbSensor: ControllerPartSensor = cm.ClimbSensor :: ControllerPartSensor
    
    -- Returns true if the controller is assigned, in world, and being simulated
    local function isControllerActive(controller : ControllerBase)
        return cm.ActiveController == controller and controller.Active
    end
    
    local function setController(name: string)
        cm.ActiveController = cm:FindFirstChild(name)
    end

    local stateMachine: FSM.StateMachineType = FSM.new({
        initial = "idle",
        events = {
            {
                name = "walk",
                to = "walking" ,
                from = {"idle", "running", "falling", "attack_end", "jumping"},
            },
            {
                name = "run",
                to = "running",
                from = {"walking", "falling", "dashing"},
            },
            {
                name = "jump",
                to = "jumping",
                from = {"idle", "walking", "running", "falling", "attack_end"},
            },
            {
                name = "fall",
                to = "falling",
                from = "*",
            },
            {
                name = "attack",
                to = "attacking",
                from = {"idle", "walking", "running", "jumping", "falling", "attack_end"},
            },
            {
                name = "attack_end",
                to = "attack_end",
                from = "attacking",
            },
            {
                name = "stop",
                to = "idle",
                from = {"walking", "running", "falling", "attack_end", "jumping"},
            },
            {
                name = "climb",
                to = "climbing",
                from = {"idle", "walking", "running", "jumping", "falling", "attack_end"},
            },
            {
                name = "dash",
                to = "dashing",
                from = {"idle", "walking", "running", "jumping", "falling", "attack_end"},
            }
        },
        callbacks = {
            on_stop = function(sm, event, from, to)
                setController("GroundController")
                self:PlayAnimation("Idle")
            end,
            on_walk = function(sm, event, from, to)
                setController("GroundController")
                self:PlayAnimation("Walk")
            end,
            on_enter_jumping = function(sm, event, from, to)
                self.JumpCounter += 1
                primaryPart.AssemblyLinearVelocity = Vector3.new(
                    primaryPart.AssemblyLinearVelocity.X,
                    0.001,
                    primaryPart.AssemblyLinearVelocity.Z
                )

                local height = 10
                if self.JumpCounter == 2 then
                    height = 7.5
                end
                local jumpForce = math.sqrt(2 * workspace.Gravity * height) * primaryPart.AssemblyMass
                -- if self.JumpCounter == 2 then
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
                self:PlayAnimation("Jump")
            end,
            on_fall = function(sm, event, from, to)
                if from ~= "jumping" then
                    self.JumpCounter = 1
                end
                setController("AirController")
                self:PlayAnimation("Fall")
            end,
            on_attack = function(sm, event, from, to)
                -- setup attack name
                self.AttackCounter += 1
                local state = "Ground"
                if from == "jumping" or from == "falling" then
                   state = "Air"
                end
                local animName: string = state .. "Attack" .. tostring(self.AttackCounter)

                -- get attack animation track
                local track: AnimationTrack = self.Animations:GetTrack(animName)
                -- allow for next attack earlier than the animation finishing
                task.delay(track.Length - self.FrameTime * 15, function()
                    self.AttackCancel = true
                    sm.attack_end()
                end)

                -- allow other states to transition out of the attack_end state
                if self._inAttack then
                    task.cancel(self._inAttack)
                end
                self._inAttack = task.delay(track.Length, function()
                    self.AttackEnded = true
                end)

                -- play animation
                self:PlayAnimation(animName)
                self.AttackEnded = false

                -- reset attacks, put on cooldown after combo
                if self.AttackCounter == 5 then
                    self.AttackCounter = 0 -- reset
                    self.AttackOnCooldown = true
                    task.delay(1.1, function()
                        self.AttackOnCooldown = false
                    end)
                end
            end
        }
    })
    self.StateMachine = stateMachine
    self._janitor:Add(stateMachine, "Destroy")


    -- Returns true if neither the GroundSensor or ClimbSensor found a Part and, we don't have the AirController active.
    local function checkFreefallState()
        return groundSensor.SensedPart == nil and climbSensor.SensedPart == nil
            and primaryPart.AssemblyLinearVelocity.Y <= 0
            and stateMachine.current ~= "falling"
            and stateMachine.can("fall")
    end

    -- Returns true if the GroundSensor found a Part, we don't have the GroundController active, and we didn't just Jump
    local function checkWalkingState()
        return groundSensor.SensedPart ~= nil
            and cm.MovingDirection.Magnitude > 0
            and stateMachine.current ~= "jumping"
            and stateMachine.current ~= "walking"
            and stateMachine.can("walk")
    end

    -- Returns true of the ClimbSensor found a Part and we don't have the ClimbController active.
    local function checkClimbingState()
        return climbSensor.SensedPart ~= nil
            and stateMachine.current ~= "climbing"
            and stateMachine.can("climb")
    end

    -- Returns true if the GroundSensor found a part, the GroundController is active,
    -- we have no movement, and the state machine isn't idle
    local function checkIdleState()
        return groundSensor.SensedPart ~= nil
            and cm.MovingDirection.Magnitude == 0
            and not (primaryPart.AssemblyLinearVelocity.Y > 0)
            and stateMachine.current ~= "idle"
            and stateMachine.can("stop")
    end

    -- The Controller determines the type of locomotion and physics behavior
    local function updateStateAndActiveController()
       
        if not self.AttackEnded then return end

        if checkClimbingState() then
            stateMachine.climb()
        elseif checkWalkingState() then
            stateMachine.walk()
        elseif checkFreefallState() then
            stateMachine.fall()
        elseif checkIdleState() then
            stateMachine.stop()
        end
    end

    local validMovementStates = {
        "walking",
        "running",
        "idle",
        "jumping",
        "falling",
        "climbing"
    }
    local function updateMovementDirection()
        local humanoid = primaryPart.Parent:FindFirstChild("Humanoid")
        if not humanoid then return end
        if not table.find(validMovementStates, stateMachine.current) then return end
        local dir = humanoid.MoveDirection
        cm.MovingDirection = dir
        if dir.Magnitude > 0 then
            cm.FacingDirection = dir
        else
            cm.FacingDirection = cm.RootPart.CFrame.LookVector
        end
    end

    cm:GetPropertyChangedSignal("ActiveController"):Connect(function()
        if cm.ActiveController:IsA("GroundController") then
            self.JumpCounter = 0
        end
    end)

    self.LastState = stateMachine.current
    return RunService.PreAnimation:Connect(function()
        updateMovementDirection()
        updateStateAndActiveController()
        if stateMachine.current ~= self.LastState then
            self.LastState = stateMachine.current
            print(self.LastState)
        end
    end)
end

function CharacterController:InitActionListener(humanoid: Humanoid)
    if not self.StateMachine then return end
    local stateMachine = self.StateMachine

    -- listen for jumps
    self._janitor:Add(humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if humanoid.Jump and stateMachine.current ~= "jumping" and stateMachine.can("jump")
            and self.JumpCounter < 2 then
            stateMachine.jump()
        end
    end))

    -- listen for attacks
    self._janitor:Add(self.AttackEvent:Connect(function()
        if stateMachine.can("attack") and self.AttackCancel and not self.AttackOnCooldown then
            self.AttackCancel = false
            stateMachine.attack()
        end
    end))
end

function CharacterController:PlayAnimation(trackName: string)
    assert(self.Animations:GetTrack(trackName), "Could not find animation: " .. trackName)
    self.Animations:StopAllTracks()
    task.wait()
    self.Animations:PlayTrack(trackName)
end

function CharacterController:LoadAnimations(character: Model)
    local animator = character:FindFirstChild("Animator", true)
    self.Animations = AnimationPlayer.new(animator)
    -- load animations here
    local animations = ReplicatedStorage.Assets.Animations:GetChildren()
    for _, anim in animations do
        self.Animations:WithAnimation(anim)
    end
end

function CharacterController:KnitStart()
    LocalPlayer.CharacterAdded:Connect(function(character)
        self._janitor:Cleanup()
        local humanoid = character:WaitForChild("Humanoid")
        local controllerManager = character:WaitForChild("CharacterController")

        self:LoadAnimations(character)
        -- TODO: setup FSM so movedirection is only updated in moving states, not attacking states
        self:InitStateMachine(controllerManager)
        self:InitActionListener(humanoid)
        self.CharacterAddedEvent:Fire(character) -- // fire when loading the character is complete

        self.FrameTime = 1/60
        RunService.PostSimulation:Connect(function(dt)
            self.FrameTime = dt
        end)
    end)
end


function CharacterController:KnitInit()
    self.AttackCancel = true
    self.AttackOnCooldown = false
    self.AttackEnded = true

    self._janitor = Janitor.new()
    self.CharacterAddedEvent = Signal.new() -- // Knit Controllers should connect to this event if the character is needed
    self.AttackEvent = Signal.new()
end


return CharacterController