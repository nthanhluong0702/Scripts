local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local BLOX_FRUITS_ID = 2753915549

function HopModule.Hop(fruitName, targetJobId)
    showNotification(fruitName or "Unknown", targetJobId or game.JobId)
    task.wait(0.5)

    pcall(function()
        if queue_on_teleport then
            queue_on_teleport([[
                task.spawn(function()
                    repeat task.wait() until game:IsLoaded()
                end)
            ]])
        end
    end)
    
    local successAPI, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. BLOX_FRUITS_ID .. "/servers/Public?sortOrder=Asc&limit=10")
    end)

    if successAPI and response then
        local decoded, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if decoded and data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing and server.playing < (server.maxPlayers or 10) and server.id ~= game.JobId then
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
