local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HubHop = {}
HubHop.__index = HubHop

function HubHop:Hop()
    local success, err = pcall(function()
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        local req = game:HttpGet(url)
        local body = HttpService:JSONDecode(req)
        
        if body and body.data then
            local servers = {}
            for _, serv in ipairs(body.data) do
                if type(serv) == "table" and serv.id and serv.id ~= game.JobId then
                    if serv.playing < serv.maxPlayers and serv.playing >= 1 then
                        table.insert(servers, serv.id)
                    end
                end
            end
            
            if #servers > 0 then
                local targetServer = servers[math.random(1, #servers)]
                
                local options = Instance.new("TeleportOptions")
                options.ServerInstanceID = targetServer
                
                TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}, options)
            else
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)

    if not success then
        task.wait(2)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

return HubHop
