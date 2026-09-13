local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local PlaceId = game.PlaceId

local ServerHopLib = {}
ServerHopLib.__index = ServerHopLib

function ServerHopLib:GetServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", PlaceId)
    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("[ServerHopLib]: Không thể kết nối tới Roblox API server.")
        return nil, nil
    end

    local decodedSuccess, decodedData = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decodedSuccess or not decodedData then
        warn("[ServerHopLib]: Lỗi giải mã dữ liệu JSON từ API.")
        return nil, nil
    end

    return decodedData.data, decodedData.nextPageCursor
end

function ServerHopLib:FindCleanServer(maxPlayers, minPlayers)
    maxPlayers = maxPlayers or 2
    minPlayers = minPlayers or 0
    
    local cursor = nil
    local targetServerId = nil
    local attempts = 0
    local maxAttempts = 5

    repeat
        attempts = attempts + 1
        local servers, nextCursor = self:GetServers(cursor)
        
        if servers then
            for _, server in ipairs(servers) do
                if server.playing and server.playing <= maxPlayers and server.playing >= minPlayers then
                    if server.id ~= game.JobId then
                        targetServerId = server.id
                        break
                    end
                end
            end
        end

        cursor = nextCursor
        task.wait(0.2)
    until targetServerId or not cursor or attempts >= maxAttempts

    return targetServerId
end

function ServerHopLib:Hop(maxPlayers)
    local targetServer = self:FindCleanServer(maxPlayers)

    if targetServer then
        print("[ServerHopLib]: Đã tìm thấy server sạch! Đang tiến hành dịch chuyển...")
        
        local queueTeleport = syn and syn.queue_on_teleport or queue_on_teleport
        if queueTeleport then
            pcall(function()
                queueTeleport([[
                    repeat task.wait() until game:IsLoaded()
                    print("Đã sang server mới thành công!")
                ]])
            end)
        end

        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, targetServer, Players.LocalPlayer)
        end)

        if not success then
            warn("[ServerHopLib]: Lỗi teleport: ", err)
            return false
        end
        return true
    else
        print("[ServerHopLib]: Không tìm thấy server phù hợp, đang thử lại...")
        task.wait(1)
        return self:Hop(maxPlayers)
    end
end

return ServerHopLib
