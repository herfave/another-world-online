--[=[
@class 	TableService
    Author: Aaron Jay (seyai_one)

    On a loop, instantiate table quests, let players join a table, and teleport
    attached players to the new quest. Create a new server that loads the right map
    and objectives as well.

    Assing quests with and their config to their reserved JobId
]=]

local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")
local TableQuests = require(Modules.TableQuests)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Promise = require(Packages.Promise)
local TableUtil = require(Packages.TableUtil)
local Timer = require(Packages.Timer)
local Janitor = require(Packages.Janitor)

local TableService = Knit.CreateService({
    Name = "TableService";
    Client = {};
})

local RNG = Random.new()

function TableService:ReserveTable(difficulty: string)
    
    -- select quest map
    local maps = TableUtil.Keys(TableQuests.QuestTypesPerMap)
    local mapIndex = RNG:NextInteger(1, #maps)
    local selectedMap = maps[mapIndex]

    -- select objective by map
    local objectives = TableQuests.QuestTypesPerMap[selectedMap]
    local objectiveIndex = RNG:NextInteger(1, #objectives)
    local objective = objectives[objectiveIndex]

    -- create new quest config from pre-made quests
    local newConfig = {
        Difficulty = difficulty,
        Map = selectedMap,
        Objective = objective,
        PlaceId = TableQuests.MapPlaceIds[selectedMap]
    }
    return newConfig
end

function TableService:TeleportToQuest(players: Players, table: Model)
    local gameConfig = self.CurrentQuests[table]
    -- reserve new template server
    local code, serverId = TeleportService:ReserveServer(gameConfig.PlaceId)

    -- create entry in hash map for 1 hour (max time for a quest is 45 min for now)
    local map: MemoryStoreSortedMap = self.QuestConfigMap
    local setConfigPromise = function()
        return Promise.new(function(resolve, reject)
            local success, _ = pcall(function()
                return map:SetAsync(serverId, gameConfig, 60 ^ 2)
            end)

            if success then
                resolve()
            else
                print("set async failed")
                reject(success)
            end
        end)
    end
    
    local teleportOptions: TeleportOptions = Instance.new("TeleportOptions")
    teleportOptions.ReservedServerAccessCode = code
    
    -- TODO: replace warning with proper error handling display to players
    return setConfigPromise():andThen(function()
        return TeleportService:TeleportAsync(gameConfig.PlaceId, players, teleportOptions)
    end):catch(warn)
end

function TableService:KnitStart()
    -- instantiate proximity prompt listeners for tables
    if self.IsLobby then
        self.QuestConfigMap = MemoryStoreService:GetSortedMap("QuestConfigs")
        self._janitor = Janitor.new()
        
        -- create proximity prompts
        for difficulty, numQuests in TableQuests.QuestsPerDifficulty do
            for i = 1, numQuests do
                local num = ""
                if i > 1 then
                    num = tostring(i)
                end
                local table = workspace.QuestTables:FindFirstChild(difficulty .. num)
                local prompt = Instance.new("ProximityPrompt")
                prompt.Parent = table
            end
        end

        -- setup quests for all ranks
        self.CurrentQuests = {}
        self.Parties = {}
        local function generateQuests()
            self._janitor:Cleanup()
            for difficulty, numQuests in TableQuests.QuestsPerDifficulty do
                for i = 1, numQuests do
                    

                    local num = ""
                    if i > 1 then
                        num = tostring(i)
                    end
                    local questTable = workspace.QuestTables:FindFirstChild(difficulty .. num)

                    local newQuest = self:ReserveTable(difficulty)
                    self.CurrentQuests[questTable] = newQuest

                    local display = questTable:FindFirstChild("QuestDisplay")
                    display:FindFirstChild("Difficulty", true).Text = newQuest.Difficulty
                    display:FindFirstChild("Objective", true).Text = newQuest.Objective
                    display:FindFirstChild("Map", true).Text = newQuest.Map

                    -- setup listener for joining a party
                    local prompt = questTable:FindFirstChildOfClass("ProximityPrompt")
                    self._janitor:Add(prompt.Triggered:Connect(function(player: Player)
                        -- remove from other parties
                        for otherTable, otherParty in self.Parties do
                            if questTable == otherTable then continue end
                            local found = table.find(otherParty, player)
                            if found then
                                table.remove(otherParty, found)
                                if #otherParty == 0 then
                                    self.Parties[otherTable] = nil
                                end
                            end
                        end

                        -- create party if none exists already
                        local party = self.Parties[questTable]
                        if not party then
                            self.Parties[questTable] = {}
                            party = self.Parties[questTable]
                        end

                        -- join the party if there is space
                        if #party < 6 then
                            table.insert(self.Parties[questTable], player)
                            print(newQuest)
                        end
                    end))
                end
            end
        end

        -- setup loop for tables
        local countdown = 30
        Timer.Simple(1, function()
            countdown -= 1
            if countdown == 0 then

                -- teleport active parties
                for questTable, party in self.Parties do
                    if #party > 0 then
                        self:TeleportToQuest(party, questTable)
                    end
                end

                table.clear(self.CurrentQuests)
                generateQuests()
                countdown = 30
                table.clear(self.Parties)
            end
        end)

        generateQuests()
    end
end


function TableService:KnitInit()
    local isLobby = ServerStorage:FindFirstChild("IsLobby")
    if isLobby then
        self.IsLobby = isLobby.Value
        self.AvailableQuests = {}
        self.TableParties = {}
    else
        self.IsLobby = false
    end
end


return TableService