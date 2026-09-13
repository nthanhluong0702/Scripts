local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DirectHop = {}
DirectHop.__index = DirectHop

function DirectHop:Hop()
    local pcallSuccess = pcall(function()
        local servers = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local body = HttpService:JSONDecode(req)
        
        if body and body.data then
            for _, serv in ipairs(body.data) do
                if type(serv) == "table" and serv.id ~= game.JobId and serv.playing < serv.maxPlayers then
                    table.insert(servers, serv.id)
                end
            end
        end
        
        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)

    if not pcallSuccess then
        task.wait(2)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

return DirectHop
