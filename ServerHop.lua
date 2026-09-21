local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

getgenv().IsCurrentlyHopping = getgenv().IsCurrentlyHopping or false

local function fetchServers(placeId)
    local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Desc&limit=100"
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    
    if req then
        local res = req({Url = url, Method = "GET"})
        if res and res.Body then
            return HttpService:JSONDecode(res.Body)
        end
    else
        local res = game:HttpGet(url)
        if res then
            return HttpService:JSONDecode(res)
        end
    end
    return nil
end

function HopModule.Hop()
    if getgenv().IsCurrentlyHopping then 
        return 
    end
    getgenv().IsCurrentlyHopping = true

    local currentPlaceId = game.PlaceId
    local currentJobId = game.JobId

    local serverData = pcall(function() return fetchServers(currentPlaceId) end) and fetchServers(currentPlaceId)

    if serverData and serverData.data then
        local candidates = {}
        for _, server in ipairs(serverData.data) do
            if type(server) == "table" and server.playing and server.playing < (server.maxPlayers or 12) and server.id ~= currentJobId then
                table.insert(candidates, server.id)
            end
        end

        if #candidates > 0 then
            for _ = 1, 3 do
                local targetJobId = candidates[math.random(1, #candidates)]
                local success = pcall(function()
                    TeleportService:TeleportToPlaceInstance(currentPlaceId, targetJobId, LocalPlayer)
                end)
                if success then
                    task.wait(8)
                    getgenv().IsCurrentlyHopping = false
                    return
                end
                task.wait(1)
            end
        end
    end

    pcall(function()
        TeleportService:Teleport(currentPlaceId, LocalPlayer)
    end)
    task.wait(8)
    getgenv().IsCurrentlyHopping = false
end

return HopModule
