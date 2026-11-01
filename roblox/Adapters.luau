-- Integration contract only. No undocumented game remotes or executor APIs.
-- Install in an experience you own, then implement using its approved server API.
local Adapters = {}
function Adapters.game()
    return {
        inventory = function() return nil, "UNAVAILABLE: no verified inventory integration" end,
        place = function(_block) return false, "UNAVAILABLE: no verified placement integration" end,
    }
end
function Adapters.economy()
    return {
        balance = function() return nil, "UNAVAILABLE: no verified balance integration" end,
        earn = function() return false, "UNAVAILABLE: no verified earnings integration" end,
        purchase = function(_item) return false, "UNAVAILABLE: no verified purchase integration" end,
    }
end
return Adapters
