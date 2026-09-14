local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local HopModule = {}

local function getServers(cursor)
    local PlaceID = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    
    if success and type(result) == "table" then
        return result
    end
    return nil
end

function HopModule.Hop()
    local PlaceID = game.PlaceId
    local AllIDs = {}
    local cursor = nil
    
    repeat
        local data = getServers(cursor)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    if server.playing > 0 then 
                        table.insert(AllIDs, server.id)
                    end
                end
            end
            cursor = data.nextPageCursor
        else
            break
        end
    until not cursor or #AllIDs >= 20

    if #AllIDs == 0 then
        local data = getServers()
        if data and data.data then
            for _, server in ipairs(data.data) do
                if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(AllIDs, server.id)
                end
            end
        end
    end

    if #AllIDs > 0 then
        local targetServerId = AllIDs[math.random(1, #AllIDs)]
        local tpSuccess, tpError = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceID, targetServerId, LocalPlayer)
        end)
        
        if not tpSuccess then
            warn("Lỗi dịch chuyển, đang thử lại...", tpError)
            task.wait(1)
            HopModule.Hop()
        end
    else
        warn("Không tìm thấy server phù hợp, thử lại sau 3 giây.")
        task.wait(3)
        HopModule.Hop()
    end
end

return HopModule
