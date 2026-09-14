local HopModule = {}
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BLOX_FRUITS_ID = 2753915549

function HopModule.Hop()
    pcall(function()
        if queue_on_teleport then
            queue_on_teleport([[
                task.spawn(function()
                    repeat task.wait() until game:IsLoaded()
                end)
            ]])
        end
    end)

    local success = pcall(function()
        TeleportService:Teleport(BLOX_FRUITS_ID, LocalPlayer)
    end)

    if not success then
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(BLOX_FRUITS_ID, LocalPlayer)
        end)
    end
end

return HopModule
