local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local BLOX_FRUITS_ID = 2753915549

local VisitedServers = {}

if game.JobId and game.JobId ~= "" then
    table.insert(VisitedServers, game.JobId)
end

local function isVisited(jobId)
    for _, visitedId in ipairs(VisitedServers) do
        if visitedId == jobId then
            return true
        end
    end
    return false
end

function HopModule.Hop()
    local successAPI, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. BLOX_FRUITS_ID .. "/servers/Public?sortOrder=Asc&limit=100")
    end)

    if successAPI and response then
        local decoded, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if decoded and data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing and server.playing < 8 and not isVisited(server.id) then
                    table.insert(VisitedServers, server.id)
                    
                    local teleSuccess = pcall(function()
                        TeleportService:TeleportToPlaceInstance(BLOX_FRUITS_ID, server.id, LocalPlayer)
                    end)
                    if teleSuccess then return end
                end
            end

            for _, server in ipairs(data.data) do
                if server.playing and server.playing < (server.maxPlayers or 12) and not isVisited(server.id) then
                    table.insert(VisitedServers, server.id)
                    
                    local teleSuccess = pcall(function()
                        TeleportService:TeleportToPlaceInstance(BLOX_FRUITS_ID, server.id, LocalPlayer)
                    end)
                    if teleSuccess then return end
                end
            end
        end
    end

    local success = pcall(function()
        TeleportService:Teleport(BLOX_FRUITS_ID, LocalPlayer)
    end)

    if not success then
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(BLOX_FRUITS_ID, LocalPlayer)
        end)
    end
end

return HopModule
