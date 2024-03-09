--[[
    PlayerService.lua
    Author: Aaron Jay (se_yai)
    23 July 2022

    Description: Manage player spawning and interactions with the server involving data
]]
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local PlayerContainer = require(Modules.PlayerContainer)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Promise = require(Packages.Promise)

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

function PlayerService:KnitStart()
    -- instantiate player function
    local function initPlayer(player)
        local newContainer = PlayerContainer.new(player)
        self._players[player] = newContainer
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
        player.CharacterAdded:Connect(function(character)
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


            playerHumanoid.Died:Connect(function()
                task.delay(Players.RespawnTime, function()
                    player:LoadCharacter()
                end)
            end)

            task.wait()
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CollisionGroup = "Players" -- // useful for disabling player-player collisions
                end
            end
            
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

        self._players[player] = nil
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

    self.CharacterLoadedEvent = Signal.new()
    self.ContainerCreated = Signal.new()
end


return PlayerService