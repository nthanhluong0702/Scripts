local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

getgenv().IsCurrentlyHopping = getgenv().IsCurrentlyHopping or false

TeleportService.TeleportInitFailed:Connect(function(player)
    if player == LocalPlayer then
        task.wait(3)
        getgenv().IsCurrentlyHopping = false
    end
end)

function HopModule.Hop()
    if getgenv().IsCurrentlyHopping then 
        return 
    end
    getgenv().IsCurrentlyHopping = true

    local placeId = game.PlaceId
    local currentJobId = game.JobId

    local requestFunc = syn and syn.request or http and http.request or http_request or request
    local serverList = {}

    if requestFunc then
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
            local res = requestFunc({Url = url, Method = "GET"})
            if res and res.Body then
                local decoded = HttpService:JSONDecode(res.Body)
                if decoded and decoded.data then
                    for _, s in ipairs(decoded.data) do
                        if s.playing and s.playing < (s.maxPlayers or 12) and s.id ~= currentJobId then
                            table.insert(serverList, s.id)
                        end
                    end
                end
            end
        end)
    end

    if #serverList > 0 then
        local randomJobId = serverList[math.random(1, #serverList)]
        local success = pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, randomJobId, LocalPlayer)
        end)
        
        if success then
            task.wait(10)
            getgenv().IsCurrentlyHopping = false
            return
        end
    end

    pcall(function()
        TeleportService:Teleport(placeId, LocalPlayer)
    end)

    task.wait(10)
    getgenv().IsCurrentlyHopping = false
end

return HopModule
