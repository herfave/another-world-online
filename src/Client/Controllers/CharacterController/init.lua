--[[
    CharacterController.lua
    Author: Aaron (se_yai)

    Description: Manage character state
]]
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local PlayerScripts = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
local Modules = PlayerScripts:WaitForChild("Modules")
local OTSCamera = require(Modules.OTSCamera)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local FSM = require(Shared.FSM)
local AnimationPlayer = require(Shared.AnimationPlayer)
local HitboxModule = require(Shared.HitboxModule)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local WaitFor = require(Packages.WaitFor)
local Janitor = require(Packages.Janitor)

-- Comm setup
local ClientComm = require(Packages.Comm).ClientComm
local CombatComm = ClientComm.new(ReplicatedStorage:WaitForChild("Comms"), true, "CombatComm")
local SendHitRequest = CombatComm:GetSignal("SendHitRequest")

-- FSM callbacks
local OnAttack = require(script.OnAttack)
local OnEnterJumping = require(script.OnEnterJumping)
local OnDash = require(script.OnDash)

local DEBUG_FSM = true

local CharacterController = Knit.CreateController { Name = "CharacterController" }

function CharacterController:ToggleTrails(state: boolean?)
    for _, part in self.Weapons do
        for _, trail in part:GetChildren() do
            if trail:IsA("Trail") then
                if state then
                    trail.Enabled = state
                else
                    trail.Enabled = not trail.Enabled
                end
            end
        end
    end
end

function CharacterController:InitStateMachine(cm: ControllerManager)
    self.JumpCounter = 0
    self.AttackCounter = 0
    local primaryPart = cm.RootPart
    -- find all sensors
    local groundSensor: ControllerPartSensor = cm.GroundSensor :: ControllerPartSensor
    local climbSensor: ControllerPartSensor = cm.ClimbSensor :: ControllerPartSensor

    local function setController(name: string)
        cm.ActiveController = cm:FindFirstChild(name)
    end

    local stateMachine: FSM.StateMachineType = FSM.new({
        initial = "idle",
        events = {
            {
                name = "walk",
                to = "walking" ,
                from = {"idle", "running", "falling", "attack_end", "jumping", "railgrinding"},
            },
            {
                name = "run",
                to = "running",
                from = {"walking", "falling", "dashing", "railgrinding"},
            },
            {
                name = "jump",
                to = "jumping",
                from = {"idle", "walking", "running", "falling", "attack_end", "railgrinding"},
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
                from = {"attacking", "falling"},
            },

            {
                name = "railgrind",
                to = "railgrinding",
                from = {"walking", "running", "jumping", "falling", "attack_end"}
            },

            {
                name = "rail_attack",
                to = "rail_attacking",
                from = {"railgrind", "attack_end"}
            },

            {
                name = "stop",
                to = "idle",
                from = {"walking", "running", "falling", "attack_end", "jumping", "railgrinding"},
            },
            {
                name = "climb",
                to = "climbing",
                from = {"idle", "walking", "running", "jumping", "falling", "attack_end", "railgrinding"},
            },
            {
                name = "dash",
                to = "dashing",
                from = {"idle", "walking", "running", "jumping", "falling", "attack_end", "railgrinding"},
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
            on_run = function(sm, event, from, to)
                setController("GroundController")
                self:PlayAnimation("Walk")
            end,

            -- jump state transition
            on_enter_jumping = OnEnterJumping,
            on_fall = function(sm, event, from, to)
                if from ~= "jumping" then
                    self.JumpCounter = 1
                end
                setController("AirController")
                
                self:PlayAnimation("Fall")
            end,

            -- Attack state transition
            on_attack = OnAttack, 

            -- Dash state transition
            on_dash = OnDash,

            on_enter_state = function(sm, event, from, to)
                if DEBUG_FSM then
                    print("new state:", to)
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
        local vel = cm.RootPart.AssemblyLinearVelocity
        local flatVel = vel - Vector3.new(0, vel.Y, 0)
        return groundSensor.SensedPart ~= nil
            and flatVel.Magnitude > 5
            and stateMachine.current ~= "jumping"
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
        local vel = cm.RootPart.AssemblyLinearVelocity
        local flatVel = vel - Vector3.new(0, vel.Y, 0)

        -- print(groundSensor.SensedPart ~= nil
        -- ,flatVel.Magnitude < 5
        -- ,not (primaryPart.AssemblyLinearVelocity.Y > 0)
        -- ,stateMachine.current ~= "idle"
        -- ,stateMachine.can("stop"))

        return groundSensor.SensedPart ~= nil
            and flatVel.Magnitude < 5
            and not (primaryPart.AssemblyLinearVelocity.Y > 0)
            and stateMachine.current ~= "idle"
            and stateMachine.can("stop")
    end

    -- The Controller determines the type of locomotion and physics behavior
    local function updateStateAndActiveController()
        if not self.AttackEnded then return end

        -- if checkClimbingState() then
        --     stateMachine.climb()
        if checkWalkingState() then
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

        local dir = humanoid.MoveDirection
        if dir.Magnitude > 0 then
            cm.FacingDirection = dir
        else
            cm.FacingDirection = cm.RootPart.CFrame.LookVector
        end

        if not table.find(validMovementStates, stateMachine.current) then
            cm.MovingDirection = Vector3.zero

            -- check nearest target
            return
        end
        cm.MovingDirection = dir
    end

    cm:GetPropertyChangedSignal("ActiveController"):Connect(function()
        if cm.ActiveController:IsA("GroundController") then
            self.JumpCounter = 0
        end
        self.AttackCounter = 0
    end)

    self.LastState = stateMachine.current
    self._janitor:Add(RunService.PreAnimation:Connect(function()
        updateMovementDirection()
        updateStateAndActiveController()
        if stateMachine.current ~= self.LastState then
            self.LastState = stateMachine.current
            -- print(`new state: {self.LastState}`)
        end
    end))
end
--[=[
    Starts listening to certain events that act on the state machine or ControllerManager
    @param humanoid Humanoid -- the player's Humanoid object
]=]
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
            self.AttackEnded = false
            stateMachine.attack()
        end
    end))

    -- listen for dashes
    self._janitor:Add(self.DashEvent:Connect(function()
        if stateMachine.can("dash") and not self.DashOnCooldown then
            stateMachine.dash()
        end
    end))
end
--[=[
    Plays an animation with a given name if it exists
    @param trackName string -- Name of animation track to play
]=]
function CharacterController:PlayAnimation(trackName: string)
    assert(self.Animations:GetTrack(trackName), "Could not find animation: " .. trackName)
    self.Animations:PlayTrack(trackName)
end

--[=[
    Loads all player animations from a template in Assets
    @param character Model -- Character model to load animations onto
]=]
function CharacterController:LoadAnimations(character: Model)
    local animator = character:FindFirstChild("Animator", true)
    self.Animations = AnimationPlayer.new(animator)
    -- load animations here
    local animations = ReplicatedStorage.Assets.Animations.Player:GetChildren()
    for _, anim in animations do
        self.Animations:WithAnimation(anim)
    end
end

function CharacterController:KnitStart()
    Knit.GetService("PlayerService").CharacterLoaded:Connect(function(character)
        self._janitor:Cleanup()
        local humanoid = character:WaitForChild("Humanoid")
        local controllerManager = character:FindFirstChildOfClass("ControllerManager")

        character.Destroying:Connect(function()
            print("DIED")
            OTSCamera:Disable()
            self._janitor:Cleanup()
        end)

        -- setup basic attack hitbox
        local hitbox = HitboxModule.new(character, {
            OriginPart = character:WaitForChild("Default"),
        })
        self._janitor:Add(hitbox.ObjectHit:Connect(function(hit: Model)
            if hit.Parent == Knit.GetController("MobController").ServerMobs then
                -- send hit request
                SendHitRequest:Fire(tonumber(hit.Name), "Basic")
                Knit.GetController("MobController"):PlayAttackedShake(tonumber(hit.Name))
            end
        end))
        self.Hitbox = hitbox

        self:LoadAnimations(character)
        self:InitStateMachine(controllerManager)
        self:InitActionListener(humanoid)
        
        self.Character = character
        self.ControllerManager = controllerManager
        self.CharacterAddedEvent:Fire(character) -- // fire when loading the character is complete

        self.FrameTime = 1/60
        RunService.PostSimulation:Connect(function(dt)
            self.FrameTime = dt
        end)

        self.Weapons = {}
        for _, v in character:GetChildren() do
            if v:HasTag("PlayerWeapon") then
                table.insert(self.Weapons, v)
            end
        end

        OTSCamera:Enable()
    end)
end


function CharacterController:KnitInit()
    self.AttackCancel = true
    self.AttackOnCooldown = false
    self.AttackEnded = true

    self._janitor = Janitor.new()
    self.CharacterAddedEvent = Signal.new() -- // Knit Controllers should connect to this event if the character is needed
    self.AttackEvent = Signal.new()
    self.DashEvent = Signal.new()
end


return CharacterController