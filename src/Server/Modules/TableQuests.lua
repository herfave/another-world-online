local QuestsPerDifficulty = {
    ["E"] = 2,
    ["D"] = 2,
    ["C"] = 2,
    ["B"] = 1,
    ["A"] = 1,
    ["S"] = 1,
    ["SS"] = 1,
    ["SS+"] = 1
}

local QuestTypesPerMap = {
    ["TestMap1"] = {"Eliminate"},
    -- ["TestMap2"] = {"Eliminate", "Retrieve"},
    -- ["TestMap3"] = {"Retrieve", "Escort"},
}

local MapPlaceIds = {
    ["TestMap1"] = 16648857942,
    -- ["TestMap2"] = 2,
    -- ["TestMap3"] = 3,
}

return {
    QuestsPerDifficulty = QuestsPerDifficulty,
    QuestTypesPerMap = QuestTypesPerMap,
    MapPlaceIds = MapPlaceIds
}