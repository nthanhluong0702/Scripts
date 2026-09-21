local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

getgenv().IsCurrentlyHopping = getgenv().IsCurrentlyHopping or false

function HopModule.Hop()
    if getgenv().IsCurrentlyHopping then 
        return 
    end
    getgenv().IsCurrentlyHopping = true

    local currentPlaceId = game.PlaceId
    local currentJobId = game.JobId

    local requestFunc = syn and syn.request or http and http.request or http_request or request
    local responseData = nil

    pcall(function()
        local apiUrl = "https://games.roblox.com/v1/games/" .. tostring(currentPlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        if requestFunc then
            local res = requestFunc({
                Url = apiUrl,
                Method = "GET"
            })
            if res and res.Body then
                responseData = HttpService:JSONDecode(res.Body)
            end
        else
            local res = game:HttpGet(apiUrl)
            if res then
                responseData = HttpService:JSONDecode(res)
            end
        end
    end)

    local teleported = false
    if responseData and responseData.data then
        for _, server in ipairs(responseData.data) do
            if server.playing and server.playing <= 10 and server.id ~= currentJobId then
                local success = pcall(function()
                    TeleportService:TeleportToPlaceInstance(currentPlaceId, server.id, LocalPlayer)
                end)
                
                if success then
                    teleported = true
                    task.wait(12)
                    break
                else
                    task.wait(1)
                end
            end
        end
    end

    if not teleported then
        pcall(function()
            TeleportService:Teleport(currentPlaceId, LocalPlayer)
        end)
        task.wait(12)
    end

    getgenv().IsCurrentlyHopping = false
end

return HopModule
