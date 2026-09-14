local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BloxFruitsPlaceIds = {
    [2753915549] = "First Sea",
    [4442272183] = "Second Sea",
    [7449423635] = "Third Sea"
}

local HopModule = {}

function HopModule.IsBloxFruits()
    return BloxFruitsPlaceIds[game.PlaceId] ~= nil
end

function HopModule.Hop()
    if not HopModule.IsBloxFruits() then return end
    
    local servers = {}
    local success = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing and server.maxPlayers and server.playing < server.maxPlayers - 1 and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
    end)
    
    if success and #servers > 0 then
        local targetServerId = servers[math.random(1, #servers)]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServerId, LocalPlayer)
        end)
    else
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
end

return HopModule
