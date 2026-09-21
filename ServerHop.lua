local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local fileName = "HopCache_" .. game.PlaceId .. ".json"
local visitedServers = {}

if isfile and isfile(fileName) then
    pcall(function()
        visitedServers = HttpService:JSONDecode(readfile(fileName))
    end)
end

local function saveVisited(jobId)
    visitedServers[jobId] = true
    if writefile then
        pcall(function()
            writefile(fileName, HttpService:JSONEncode(visitedServers))
        end)
    end
end

function HopModule.Hop()
    pcall(function()
        if queue_on_teleport then
            queue_on_teleport("repeat task.wait() until game:IsLoaded()")
        end
    end)

    local cursor = ""
    local foundServer = nil
    
    for page = 1, 3 do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=Desc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end

        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                local jobId = tostring(server.id)
                local playing = tonumber(server.playing)
                local maxPlayers = tonumber(server.maxPlayers)

                if jobId ~= game.JobId
                   and not visitedServers[jobId] 
                   and playing < maxPlayers 
                   and server.ping 
                   and server.ping < 300 then

                    foundServer = jobId
                    break
                end
            end

            if foundServer then break end
            cursor = result.nextPageToken or ""
            if not cursor or cursor == "" then break end
        else
            break
        end
        task.wait(0.2)
    end

    if foundServer then
        saveVisited(foundServer)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, foundServer, LocalPlayer)
    else
        visitedServers = {}
        if writefile then pcall(function() writefile(fileName, "{}") end) end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

return HopModule
