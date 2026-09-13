local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId

local function HopServer()
    local success, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        return HttpService:JSONDecode(response)
    end)

    if success and result and result.data then
        local servers = {}
        for _, server in ipairs(result.data) do
            if type(server) == "table" and server.id ~= CurrentJobId then
                local maxPlayers = server.maxPlayers or 0
                local playing = server.playing or 0
                if playing < maxPlayers then
                    table.insert(servers, server.id)
                end
            end
        end

        if #servers > 0 then
            local targetServer = servers[math.random(1, #servers)]
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, targetServer, LocalPlayer)
            end)
        else
            warn("Không tìm thấy server phù hợp, đang thử lại...")
            task.wait(2)
            HopServer()
        end
    else
        warn("Lỗi kết nối tới API Roblox, đang thử lại...")
        task.wait(2)
        HopServer()
    end
end

HopServer()
