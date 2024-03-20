--[[
    PlayerService.lua
    Author: Aaron Jay (se_yai)
    23 July 2022

    Description: Manage player spawning and interactions with the server involving data
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Components = require(Shared.ECS.Components)
local BuildDataProducer = require(Shared.BuildDataProducer)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
local Reflex = require(Packages.Reflex)

-- init functions
local BuildCharacter = require(script.BuildCharacter)
local PlayerContainer = require(script.PlayerContainer)

local STPlayerRegistry = game:GetService("SharedTableRegistry"):GetSharedTable("PLAYER_REGISTRY")

local PlayerService = Knit.CreateService {
    Name = "PlayerService";
    Client = {
        SendFirstTime = Knit.CreateSignal(),
        CharacterLoaded = Knit.CreateSignal(),
        TransmitData = Knit.CreateSignal(),
        ReceiveReady = Knit.CreateSignal()
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

function PlayerService:LoadWeapon(player: Player)
    local container = self:GetContainer(player)
    local weaponTemplate = ReplicatedStorage.Assets.Weapons:FindFirstChild("Default")
    local newWeapon = weaponTemplate:Clone()

    newWeapon:AddTag("PlayerWeapon")

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

function PlayerService:CheckoutAttackTokens(player: Player, enemyId: number, isCheckingOut: boolean, amount: number)
    if not player then return end
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
    local _producer, _slices = BuildDataProducer()
    self.DataProducer = _producer

    local broadcaster = Reflex.createBroadcaster({
        producers = _slices,
        dispatch = function(player, actions)
            self.Client.TransmitData:Fire(player, actions)
        end,
        hydrateRate = -1,
        beforeHydrate = function(player, state)
            local newState = table.clone(state)
            local stringId = tostring(player.UserId)
            for key, entities in newState do
                newState[key].entities = {
                    [stringId] = state[key].entities[stringId]
                }
            end
            return newState
        end
    })

    _producer:applyMiddleware(broadcaster.middleware)

    self._listening = {}
    self.Client.ReceiveReady:Connect(function(player)
        if self._listening[player] then return end
        self._listening[player] = true
        broadcaster:start(player)
    end)

    -- instantiate player function
    local function initPlayer(player)
        local newContainer, loadPromise = PlayerContainer.new(player, self.DataProducer)

        loadPromise:andThen(function()
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
                local playerHumanoid = character:WaitForChild("Humanoid")
                for _, v in ipairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CollisionGroup = "Players" -- // useful for disabling player-player collisions
                    end
                end

                BuildCharacter(character, entityId)
                playerHumanoid.Died:Connect(function()
                    player.Character = nil
                    character:Destroy()
                    task.delay(Players.RespawnTime, function()
                        player:LoadCharacter()
                    end)

                    self.PlayerDied:Fire(player)
                end)

                task.wait()                
                -- load weapon
                self:LoadWeapon(player)

                self.CharacterLoadedEvent:Fire(player, character)
                self.Client.CharacterLoaded:Fire(player, character)
            end)
        end)
        :andThen(function()
            player:LoadCharacter()
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