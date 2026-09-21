local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().IsCurrentlyHopping = getgenv().IsCurrentlyHopping or false

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        task.wait(2)
        getgenv().IsCurrentlyHopping = false
    end
end)

function HopModule.Hop()
    if getgenv().IsCurrentlyHopping then 
        return 
    end
    getgenv().IsCurrentlyHopping = true

    local currentPlaceId = game.PlaceId
    
    local teleSuccess = false
    
    local successOptions, options = pcall(function()
        local tpOps = Instance.new("TeleportOptions")
        tpOps.ShouldReserveServer = false
        return tpOps
    end)

    if successOptions and options then
        pcall(function()
            TeleportService:TeleportAsync(currentPlaceId, {LocalPlayer}, options)
            teleSuccess = true
        end)
    end

    if not teleSuccess then
        pcall(function()
            TeleportService:Teleport(currentPlaceId, LocalPlayer)
        end)
    end

    task.wait(15)
    getgenv().IsCurrentlyHopping = false
end

return HopModule
