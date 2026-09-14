local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HopModule = {}

function HopModule.Hop()
    local PlaceID = game.PlaceId
    local AllIDs = {}
    
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and result and result.data then
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(AllIDs, server.id)
            end
        end
    end
    
    if #AllIDs > 0 then
        local randomServerId = AllIDs[math.random(1, #AllIDs)]
        local tpSuccess, tpError = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceID, randomServerId, LocalPlayer)
        end)
        
        if not tpSuccess then
            warn("Teleport failed: " .. tostring(tpError))
        end
    else
        warn("No available servers found to hop into.")
    end
end

return HopModule
