--[[
    PlayerService.lua
    Author: Aaron Jay (se_yai)
    23 July 2022

    Description: Manage player spawning and interactions with the server involving data
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local PlayerContainer = require(Modules.PlayerContainer)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Promise = require(Packages.Promise)

local STPlayerRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("PLAYER_REGISTRY")

local PlayerService = Knit.CreateService {
    Name = "PlayerService";
    Client = {
        SendFirstTime = Knit.CreateSignal(),
        CharacterLoaded = Knit.CreateSignal()
    };
}

-- Get the player's container to interact with it
function PlayerService:GetContainer(player)
    -- ensure player exists
    if not player then
        warn("Cannot get container of nonexistent player")
        return
    end

    local container = self._players[player]
    if container then
        return container
    else
        warn("Could not get container for " .. tostring(player))
    end
end

-- Useful if other things need to be done before/after a character is loaded
function PlayerService:CustomLoadCharacter(player)
    player:LoadCharacter()
end

-- Called when player loads their data replica for the first time, then "yields" until character loads
function PlayerService.Client:DidLoadReplica(player: Player)
    local thisContainer = self.Server._players[player]
    if not player.Character then
        self.Server:CustomLoadCharacter(player, thisContainer.Profile.Data.Kit)
    end

    self.SendFirstTime:Fire(player)
    return true
end

function PlayerService:LoadWeapon(player: Player)
    local container = self:GetContainer(player)
    local weaponTemplate = ReplicatedStorage.Assets.Weapons:FindFirstChild("Default")
    local newWeapon = weaponTemplate:Clone()

    -- use RigidConstraints
    local rigid = Instance.new("RigidConstraint")
    rigid.Attachment1 = newWeapon:FindFirstChild("RightGripAttachment", true)
    rigid.Attachment0 = player.Character:FindFirstChild("RightGripAttachment", true)
    rigid.Parent = newWeapon
    
    newWeapon.Parent = player.Character
end

--[=[
    Change how long between when an attack token is returned by enemy actors
    for use in another attack
]=]
function PlayerService:AdjustEnemyAttackDelay(player: Player, freq: number)
    player:SetAttribute("EnemyAttackDelay", freq)
end

--[=[
    Change how many attackers can attack the player at once i.e. how many tokens are available
    Useful for moves that use up a lot of tokens
]=]
function PlayerService:AdjustAttackTokens(player: Player, attackers: number)
    player:SetAttribute("AttackTokens", attackers)
end

function PlayerService:CheckoutAttackTokens(player: Player, enemyId: number, isCheckingOut: boolean, amount: number | nil)
    local checkedOutTokens = self._attackTokens[player]
    amount = amount or 1
    local attackTokens = player:GetAttribute("AttackTokens")
    -- consume 1 token for this call
    if isCheckingOut then
        if #checkedOutTokens < attackTokens and attackTokens - #checkedOutTokens >= amount then
            for i = 1, amount do
                table.insert(checkedOutTokens, enemyId)
            end
            task.delay(player:GetAttribute("EnemyAttackDelay"), function()
                self:CheckoutAttackTokens(player, enemyId, false, amount)
            end)
        end
    -- return a token for future use
    else
        for i = 1, amount do
            local index = table.find(checkedOutTokens, enemyId)
            if index then
                table.remove(checkedOutTokens, index)
            end
        end
    end

    -- encode state to player attributes so actors can read it
    local t = HttpService:JSONEncode(checkedOutTokens)
    player:SetAttribute("HasAttackToken", t)
end

function PlayerService:KnitStart()
    -- instantiate player function
    local function initPlayer(player)
        local newContainer = PlayerContainer.new(player)
        self._players[player] = newContainer
        self._attackTokens[player] = {}
        self.ContainerCreated:Fire(player, newContainer)

        -- create leader stats
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player

        -- // create individual leaderstat values!
        
        --[[ // example:
        local sos = Instance.new("IntValue")
        sos.Name = "H/Rs"
        sos.Value = 0
        sos.Parent = leaderstats
        --]]

        -- initialize data
        -- spawn player

        local entityId = Knit.GetService("MatterService"):CreateEntity({
            Components.Player { userid = player.UserId }
        })

        print(`Created player: {player.UserId} [{entityId}]`)
        newContainer.EntityId = entityId

        -- create battle circle invocation
        self:AdjustAttackTokens(player, 4)
        self:AdjustEnemyAttackDelay(player, 4)
        local attackToken = Instance.new("BindableEvent")
        attackToken.Name = "InvokeAttackToken"
        attackToken.Event:Connect(function(...)
            self:CheckoutAttackTokens(player, table.unpack({...}))
        end)
        attackToken.Parent = player

        STPlayerRegistry[entityId] = player.UserId

        player.CharacterAdded:Connect(function(character)
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
            local rigid = Instance.new("RigidConstraint")
            rigid.Attachment0 = character:FindFirstChild("RootRigAttachment", true)
            rigid.Attachment1 = capsule:FindFirstChildOfClass("Attachment")
            rigid.Parent = capsule
            capsule.Parent = character

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
            playerHumanoid.Died:Connect(function()
                player.Character = nil
                character:Destroy()
                task.delay(Players.RespawnTime, function()
                    player:LoadCharacter()
                end)

                self.PlayerDied:Fire(player)
            end)

            task.wait()
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CollisionGroup = "Players" -- // useful for disabling player-player collisions
                end
            end
            capsule.CollisionGroup = "MobCapsule"
            
            -- load weapon
            self:LoadWeapon(player)

            self.CharacterLoadedEvent:Fire(player, character)
            self.Client.CharacterLoaded:Fire(player, character)
        end)
    end

    -- cleanup player function
    local function cleanupPlayer(player)
        -- remove player object
        assert(self._players[player], "Could not find player object for " .. player.Name)
        local playerContainer = self._players[player]
        playerContainer:Destroy()

        -- clean up container tables
        self._players[player] = nil
        self._attackTokens[player] = nil
    end

    -- load players that joined before 
    for _, player in Players:GetPlayers() do
        if not self._players[player] then
            initPlayer(player)
        end
    end

    Players.PlayerAdded:Connect(initPlayer)
    Players.PlayerRemoving:Connect(cleanupPlayer)

    
end


function PlayerService:KnitInit()
    self._players = {}
    self._attackTokens = {}

    self.CharacterLoadedEvent = Signal.new()
    self.ContainerCreated = Signal.new()
    self.PlayerDied = Signal.new()
end


return PlayerService