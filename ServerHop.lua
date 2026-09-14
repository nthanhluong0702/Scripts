local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HopModule = {}

function HopModule.Hop()
    local currentPlaceId = game.PlaceId
    local servers = {}
    local cursor = ""
    
    repeat
        local url = "https://games.roblox.com/v1/games/" .. currentPlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing and server.maxPlayers and server.playing < (server.maxPlayers - 1) and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until #servers >= 30 or cursor == "" 

    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/nthanhluong0702/Scripts/refs/heads/main/scripts.luau"))()')
    elseif queue_on_teleport then
        queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/nthanhluong0702/Scripts/refs/heads/main/scripts.luau"))()')
    end

    if #servers > 0 then
        local targetServerId = servers[math.random(1, #servers)]
        
        task.wait(0.3)
        
        local tpSuccess = pcall(function()
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
