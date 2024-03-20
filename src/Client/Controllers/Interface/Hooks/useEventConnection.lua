--https://discord.com/channels/385151591524597761/440326611863339009/1196597474295545990
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Signal = require(ReplicatedStorage.Packages.Signal)

local function useEventConnection<T...>(
    event: RBXScriptSignal | Signal.Signal<T...>,
    callback: (T...) -> (),
    dependencies: { any }?
)
    local cachedCallback = React.useMemo(function()
        return callback
    end, dependencies)

    React.useEffect(function()
        local connection = (event :: any):Connect(cachedCallback)

        
        return function()
            connection:Disconnect()
        end
    end, { event, cachedCallback } :: { unknown })
end

return useEventConnection