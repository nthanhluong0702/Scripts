local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SafeServerHop = {}
SafeServerHop.__index = SafeServerHop

function SafeServerHop:Hop()
    local success = pcall(function()
        local currentPlaceId = game.PlaceId
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", currentPlaceId)
        
        local req = game:HttpGet(url)
        local body = HttpService:JSONDecode(req)
        
        if body and body.data then
            local validServers = {}
            for _, serv in ipairs(body.data) do
                if type(serv) == "table" and serv.id and serv.id ~= game.JobId then
                    if serv.playing and serv.maxPlayers and serv.playing < serv.maxPlayers and serv.playing > 0 then
                        table.insert(validServers, serv.id)
                    end
                end
            end
            
            if #validServers > 0 then
                local randomServer = validServers[math.random(1, #validServers)]
                TeleportService:TeleportToPlaceInstance(currentPlaceId, randomServer, LocalPlayer)
            else
                TeleportService:Teleport(currentPlaceId, LocalPlayer)
            end
        else
            TeleportService:Teleport(currentPlaceId, LocalPlayer)
        end
    end)

    if not success then
        task.wait(1.5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

return SafeServerHop
