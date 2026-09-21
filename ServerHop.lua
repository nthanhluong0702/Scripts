local HopModule = {}

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local visitedServers = {}
table.insert(visitedServers, game.JobId)

local function prepareForTeleport()
    pcall(function()
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.Velocity = Vector3.zero
                    part.RotVelocity = Vector3.zero
                end
            end
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = true
            end
        end
    end)
end

local function getPublicServers(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%s/servers/0?sortOrder=Asc&limit=100%s",
        tostring(game.PlaceId),
        cursor and ("&cursor=" .. cursor) or ""
    )
    
    local success, response = pcall(function()
        local requestFunc = syn and syn.request or http and http.request or http_request or request
        if requestFunc then
            local res = requestFunc({Url = url, Method = "GET"})
            return HttpService:JSONDecode(res.Body)
        else
            return HttpService:JSONDecode(game:HttpGet(url))
        end
    end)

    if success and response and response.data then
        return response.data, response.nextPageCursor
    end
    return nil, nil
end

function HopModule.Hop()
    prepareForTeleport()
    
    pcall(function()
        if queue_on_teleport then
            queue_on_teleport([[
                repeat task.wait() until game:IsLoaded()
            ]])
        end
    end)

    local targetServerId = nil
    local cursor = ""
    local attempts = 0
    
    while not targetServerId and attempts < 5 do
        attempts = attempts + 1
        local servers, nextCursor = getPublicServers(cursor)
        cursor = nextCursor

        if servers then
            for _, server in ipairs(servers) do
                if type(server) == "table" and server.id then
                    local id = tostring(server.id)
                    local playing = tonumber(server.playing) or 0
                    local maxPlayers = tonumber(server.maxPlayers) or 12
                    
                    if id ~= game.JobId and not visitedServers[id] and playing < maxPlayers then
                        targetServerId = id
                        table.insert(visitedServers, id)
                        break
                    end
                end
            end
        end
        
        if not cursor then break end
        task.wait(0.3)
    end

    if targetServerId then
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServerId, LocalPlayer)
        end)
        
        if not success then
            warn("[HopModule]: Lỗi TeleportDirect, chuyển sang Fallback Mode: " .. tostring(err))
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    else
        warn("[HopModule]: Không tìm thấy JobId phù hợp, dùng Random Teleport...")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

return HopModule
