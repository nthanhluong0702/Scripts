local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local AdvancedHop = {}

function AdvancedHop.Hop()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    repeat
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and response and response.data then
            for _, server in ipairs(response.data) do
                if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    if server.playing >= 1 then
                        table.insert(servers, server.id)
                    end
                end
            end
            cursor = response.nextPageCursor
        else
            break
        end
    until cursor == nil or #servers >= 30

    if #servers == 0 then
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and response and response.data then
            for _, server in ipairs(response.data) do
                if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
    end

    if #servers > 0 then
        local targetServer = servers[math.random(1, #servers)]
        
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions.ServerInstanceId = targetServer

        local success, err = pcall(function()
            TeleportService:TeleportAsync(placeId, {LocalPlayer}, teleportOptions)
        end)

        if not success then
            warn("Lỗi chuyển hướng, đang ép thực hiện lại lần 2...", err)
            task.wait(1)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
            end)
        end
    else
        warn("Không tìm thấy server phù hợp, đang quét lại...")
        task.wait(2)
        AdvancedHop.Hop()
    end
end

return AdvancedHop
