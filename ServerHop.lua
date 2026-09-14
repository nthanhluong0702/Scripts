local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HopModule = {}

local BloxFruitsPlaces = {
    [2753915549] = "Sea 1",
    [4442272183] = "Sea 2",
    [7449423635] = "Sea 3"
}

function HopModule.Hop()
    local currentPlaceId = game.PlaceId
    
    if not BloxFruitsPlaces[currentPlaceId] then
        warn("Không đúng bản đồ Blox Fruits! Đang hủy Server Hop.")
        return
    end
    
    local servers = {}
    local cursor = ""

    local success = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. currentPlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = HttpService:JSONDecode(game:HttpGet(url))
        
        if response and response.data then
            for _, server in ipairs(response.data) do
                if server.playing and server.maxPlayers and server.playing < (server.maxPlayers - 2) and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
    end)
    
    if success and #servers > 0 then 
        local targetServerId = servers[math.random(1, #servers)]
        
        local tpSuccess, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(currentPlaceId, targetServerId, LocalPlayer)
        end)
        
        if not tpSuccess then
            TeleportService:Teleport(currentPlaceId, LocalPlayer)
        end
    else
        TeleportService:Teleport(currentPlaceId, LocalPlayer)
    end
end

return HopModule
