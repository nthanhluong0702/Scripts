local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local ServerHop = {}

local function GetServers()
    local Servers = {}
    local Cursor = ""
    
    repeat
        local Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if Cursor ~= "" then
            Url = Url .. "&cursor=" .. Cursor
        end
        
        local Success, Response = pcall(function()
            return game:HttpGet(Url)
        end)
        
        if Success and Response then
            local Data = HttpService:JSONDecode(Response)
            if Data and Data.data then
                for _, Server in ipairs(Data.data) do
                    if type(Server) == "table" and Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
                        table.insert(Servers, Server.id)
                    end
                end
                Cursor = Data.nextPageCursor
            else
                break
            end
        else
            break
        end
    until not Cursor or #Servers >= 50
    
    return Servers
end

function ServerHop:Hop()
    print("Đang tìm server mới cho Blox Fruits...")
    
    local Servers = GetServers()
    
    if #Servers > 0 then
        local RandomServerId = Servers[math.random(1, #Servers)]
        print("Đang chuyển đến server: " .. RandomServerId)
        
        local Success, Err = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, RandomServerId, LocalPlayer)
        end)
        
        if not Success then
            warn("Lỗi khi teleport, đang thử lại... Chi tiết: " .. tostring(Err))
            task.wait(1)
            self:Hop()
        end
    else
        warn("Không tìm thấy server phù hợp, đang thử lại sau 3 giây...")
        task.wait(3)
        self:Hop()
    end
end

return ServerHop
