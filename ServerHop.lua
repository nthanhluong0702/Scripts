local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function HopModule.Hop()
    if not Config.UsingHopApi then return end
    local PlaceId = game.PlaceId
    local Servers = {}
    local Cursor = ""
    
    local success = pcall(function()
        repeat
            local Url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100" .. (Cursor ~= "" and "&cursor="..Cursor or "")
            local Response = HttpService:JSONDecode(game:HttpGet(Url))
            Cursor = Response.nextPageCursor
            for _, v in ipairs(Response.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(Servers, v.id)
                end
            end
        until #Servers > 0 or not Cursor
    end)
    
    if success and #Servers > 0 then
        local targetServer = Servers[math.random(1, #Servers)]
        print("[Kaitun Fruit]: Hopping to a new server...")
        TeleportService:TeleportToPlaceInstance(PlaceId, targetServer, LocalPlayer)
    end
end

return HopModule
