local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().IsCurrentlyHopping = getgenv().IsCurrentlyHopping or false

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        getgenv().IsCurrentlyHopping = false
    end
end)

function HopModule.Hop()
    if getgenv().IsCurrentlyHopping then 
        return 
    end
    getgenv().IsCurrentlyHopping = true

    local currentPlaceId = game.PlaceId

    local success = pcall(function()
        TeleportService:Teleport(currentPlaceId, LocalPlayer)
    end)

    if not success then
        task.wait(3)
        pcall(function()
            TeleportService:Teleport(currentPlaceId, LocalPlayer)
        end)
    end

    task.wait(10)
    getgenv().IsCurrentlyHopping = false
end

return HopModule
