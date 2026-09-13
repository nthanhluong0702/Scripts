local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UltimateHop = {}
UltimateHop.__index = UltimateHop

UltimateHop.Settings = {
    MinPlayers = 2,
    MaxPlayers = 10,
    SaveHistory = true,
    FileName = "BloxFruits_UltimateHopHistory.json",
    DelayBetweenTries = 1.5
}

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer and teleportResult ~= Enum.TeleportResult.Success then
        task.wait(1)
        UltimateHop:Hop()
    end
end)

local function GetHistory()
    if not (readfile and writefile) then return {} end
    local success, result = pcall(function()
        if not isfile(UltimateHop.Settings.FileName) then
            writefile(UltimateHop.Settings.FileName, HttpService:JSONEncode({}))
            return {}
        end
        return HttpService:JSONDecode(readfile(UltimateHop.Settings.FileName))
    end)
    return success and result or {}
end

local function SaveHistory(historyTable)
    if not writefile then return end
    pcall(function()
        writefile(UltimateHop.Settings.FileName, HttpService:JSONEncode(historyTable))
    end)
end

function UltimateHop:FindBestServer()
    local placeId = game.PlaceId
    local cursor = ""
    local history = GetHistory()
    
    if #history > 200 then history = {} end

    for i = 1, 3 do
        local url = string.format(
            "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s", 
            placeId, 
            (cursor ~= "" and "&cursor=" .. cursor or "")
        )
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if type(server) == "table" and server.id and server.playing and server.maxPlayers then
                    local serverId = tostring(server.id)
                    local playerCount = server.playing
                    local maxPlayers = server.maxPlayers

                    local isCurrent = (serverId == game.JobId)
                    local isVisited = history[serverId] ~= nil
                    local isValidCount = (playerCount >= self.Settings.MinPlayers and playerCount <= self.Settings.MaxPlayers)
                    local hasSpace = (playerCount < maxPlayers)

                    if hasSpace and isValidCount and not isCurrent and not isVisited then
                        return serverId, history
                    end
                end
            end
            
            if result.nextPageCursor then
                cursor = result.nextPageCursor
            else
                break
            end
        else
            break
        end
        
        task.wait(0.5)
    end

    return nil, history
end

function UltimateHop:Hop()
    local targetServerId, history = self:FindBestServer()

    if targetServerId then
        if self.Settings.SaveHistory then
            history[targetServerId] = true
            SaveHistory(history)
        end

        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServerId, LocalPlayer)
        end)

        if not success then
            task.wait(self.Settings.DelayBetweenTries)
            self:Hop()
        end
    else
        if writefile then
            pcall(function() writefile(self.Settings.FileName, HttpService:JSONEncode({})) end)
        end
        task.wait(2)
        self:Hop()
    end
end

return UltimateHop
