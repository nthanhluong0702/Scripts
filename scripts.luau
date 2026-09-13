local ExternalConfig = getgenv().KaitunFruit or {}

local LoadedConfig = {}
pcall(function()
    if readfile and isfile and isfile(FileName) then
        LoadedConfig = HttpService:JSONDecode(readfile(FileName))
    end
end)

local Config = {
    Team = ExternalConfig.Team or "Pirates",
    Settings = {
        BlacklistFruits = ExternalConfig.BlacklistFruits or {"Rocket Fruit", "Blade Fruit", "Smoke Fruit"},
        WebhookStoreFruit = ExternalConfig.WebhookStoreFruit or {
            Enabled = LoadedConfig.WebhookStoreFruit and LoadedConfig.WebhookStoreFruit.Enabled or false,
            Url = LoadedConfig.WebhookStoreFruit and LoadedConfig.WebhookStoreFruit.Url or ""
        },
        UsingHopApi = ExternalConfig.UsingHopApi ~= nil and ExternalConfig.UsingHopApi or true,
        HopDelay = LoadedConfig.HopDelay or 5,
        TweenSpeed = LoadedConfig.TweenSpeed or 180,
        AutoStore = LoadedConfig.AutoStore ~= nil and LoadedConfig.AutoStore or true,
        FixLagEnabled = LoadedConfig.FixLagEnabled ~= nil and LoadedConfig.FixLagEnabled or true,
        BypassTeleport = LoadedConfig.BypassTeleport ~= nil and LoadedConfig.BypassTeleport or true,
        Theme = LoadedConfig.Theme or "Dark",
        Start = LoadedConfig.Start ~= nil and LoadedConfig.Start or true,
        AutoHopWhenNoFruit = LoadedConfig.Start ~= nil and LoadedConfig.Start or true,
    }
}


local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local isTeleporting = false
local isTweening = false
local currentTween = nil
local noclipConnection = nil
local isStoring = false
local CommF_Cache = nil

local successLoad, ServerHopLib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/nthanhluong0702/Scripts/refs/heads/main/ServerHop.lua"))()
end)

if not successLoad or not ServerHopLib then
    warn("[Kaitun System]: Không thể tải ServerHopLib từ GitHub, đang dùng cơ chế dự phòng...")
    ServerHopLib = {
        Hop = function(self, maxPlayers)
            pcall(function()
                TeleportService:Teleport(PlaceID, LocalPlayer)
            end)
        end,
        FindCleanServer = function(self, maxPlayers)
            return nil
        end
    }
end

local function triggerServerHop()
    if isTeleporting then return end
    isTeleporting = true
    
    if ScriptStatusBox then ScriptStatusBox:SetDesc("Đang tạo server mới...") end
    
    pcall(function()
        local success, err = pcall(function()
            local serverCode = TeleportService:ReserveServer(PlaceID)
            TeleportService:TeleportToPrivateServer(PlaceID, serverCode, {LocalPlayer})
        end)
        
        if not success then
            warn("[Hop Error]: Không thể tạo server riêng:", err)
            TeleportService:Teleport(PlaceID, LocalPlayer)
        end
    end)
    
    task.spawn(function()
        task.wait(6)
        isTeleporting = false
    end)
end

local successUI, Library = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not successUI or not Library then
    warn("[Kaitun System]: Không thể tải UI Fluent, script sẽ chạy ngầm không giao diện.")
end

local Window = Library:CreateWindow({
    Title = "Fearz Finder Fruits",
    SubTitle = "Devs by Anymorez",
    TabWidth = 140,
    Size = UDim2.fromOffset(480, 320),
    Acrylic = true,
    Theme = Config.Settings.Theme,
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Status = Window:AddTab({ Title = "Status", Icon = "home" }),
    Configuration = Window:AddTab({ Title = "Configuration", Icon = "settings" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "bell" })
}

local FruitStatusBox = Tabs.Status:AddParagraph({
    Title = "Fruit",
    Content = "No Fruit Found"
})

local TimeElapsedBox = Tabs.Status:AddParagraph({
    Title = "Time Elapsed",
    Content = "0 Hours 0 Minutes 0 Seconds"
})

local ScriptStatusBox = Tabs.Status:AddParagraph({
    Title = "Script Status",
    Content = "None"
})

local FileName = "FearzFuitConfig.json"

local function saveConfigToFile()
    pcall(function()
        if writefile then
            local saveData = {
                Theme = Config.Settings.Theme,
                TweenSpeed = Config.Settings.TweenSpeed,
                FixLagEnabled = Config.Settings.FixLagEnabled,
                BypassTeleport = Config.Settings.BypassTeleport,
                HopDelay = Config.Settings.HopDelay,
                Start = Config.Settings.Start,
                AutoStore = Config.Settings.AutoStore,
                WebhookStoreFruit = Config.Settings.WebhookStoreFruit
            }
            writefile(FileName, HttpService:JSONEncode(saveData))
        end
    end)
end

Tabs.Configuration:AddDropdown("Theme", {
    Title = "Theme",
    Values = {"Dark", "Light", "Darker", "Aqua", "Amethyst", "Rose"},
    Default = Config.Settings.Theme,
    Callback = function(Value)
        Config.Settings.Theme = Value
        Library:SetTheme(Value)
        saveConfigToFile()
    end
})

Tabs.Configuration:AddDropdown("TweenSpeed", {
    Title = "Tween Speed",
    Values = {150, 180, 190, 250, 300},
    Default = Config.Settings.TweenSpeed,
    Callback = function(Value)
        Config.Settings.TweenSpeed = Value
        saveConfigToFile()
    end
})

local FixLagToggle = Tabs.Configuration:AddToggle("FixLag", {
    Title = "Fix lag executing script",
    Default = Config.Settings.FixLagEnabled
})
FixLagToggle:OnChanged(function(Value)
    Config.Settings.FixLagEnabled = Value
    saveConfigToFile()
end)

local BypassTeleportToggle = Tabs.Configuration:AddToggle("BypassTeleport", {
    Title = "Bypass Teleport",
    Default = Config.Settings.BypassTeleport
})
BypassTeleportToggle:OnChanged(function(Value)
    Config.Settings.BypassTeleport = Value
    saveConfigToFile()
end)

Tabs.Configuration:AddInput("HopDelay", {
    Title = "Hop Delay",
    Default = tostring(Config.Settings.HopDelay),
    Placeholder = "5",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then 
            Config.Settings.HopDelay = num 
            saveConfigToFile()
        end
    end
})

Tabs.Configuration:AddToggle("StartAutomation", {
    Title = "Start",
    Default = Config.Settings.AutoHopWhenNoFruit,
    Callback = function(Value)
        Config.Settings.AutoHopWhenNoFruit = Value
        saveConfigToFile()
    end
})

local AutoStoreToggle = Tabs.Configuration:AddToggle("StoreFruit", {
    Title = "Store Fruit",
    Default = Config.Settings.AutoStore
})
AutoStoreToggle:OnChanged(function(Value)
    Config.Settings.AutoStore = Value
    saveConfigToFile()
end)

local WebhookToggle = Tabs.Webhook:AddToggle("WebhookToggle", {
    Title = "Webhook Store Fruit",
    Default = Config.Settings.WebhookStoreFruit.Enabled
})
WebhookToggle:OnChanged(function(Value)
    Config.Settings.WebhookStoreFruit.Enabled = Value
    saveConfigToFile()
end)

Tabs.Webhook:AddInput("WebhookUrlInput", {
    Title = "Discord Webhook URL",
    Default = Config.Settings.WebhookStoreFruit.Url,
    Placeholder = "Paste webhook url here...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        Config.Settings.WebhookStoreFruit.Url = Value
        saveConfigToFile()
    end
})

local function getCommF()
    if CommF_Cache and CommF_Cache.Parent then return CommF_Cache end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("CommF_") then
        CommF_Cache = remotes.CommF_
        return CommF_Cache
    end
    CommF_Cache = ReplicatedStorage:FindFirstChild("CommF_", true)
    return CommF_Cache
end

local function startNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function cancelTween()
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        currentTween = nil
    end
    isTweening = false
    stopNoclip()
end

local function optimizedTweenTo(targetCFrame)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    
    isTweening = true
    
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local speed = Config.Settings.TweenSpeed or 180
    local duration = math.max(distance / speed, 0.1)
    
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    currentTween = tween
    tween:Play()
    
    local success = false
    local connection
    connection = tween.Completed:Connect(function()
        success = true
        if connection then connection:Disconnect() end
    end)
    
    repeat task.wait() until success or not isTweening or not tween or tween.PlaybackState ~= Enum.PlaybackState.Playing
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    isTweening = false
    currentTween = nil
    return success
end

local function optimizePerformance()
    if not Config.Settings.FixLagEnabled then return end
    pcall(function()
        local Lighting = game:GetService("Lighting")
        local Terrain = Workspace:FindFirstChildOfClass("Terrain")
        
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 2
        
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                v.Enabled = false
            end
        end
        
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveTransparency = 1
            Terrain.WaterTransparency = 1
        end
        
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.SmoothPlastic
                part.Reflectance = 0
            elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Fire") or part:IsA("Smoke") then
                part.Enabled = false
            end
        end
        
        settings():GetService("RenderSettings").QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function sendWebhook(fruitName, fruitPos, method)
    if not Config.Settings.WebhookStoreFruit.Enabled then return end
    local webhookUrl = Config.Settings.WebhookStoreFruit.Url
    if not webhookUrl or webhookUrl == "" then return end

    local titleText = "🌟 Fruit Found & Stored"
    local colorHex = 16776960
    
    if method == "Drop" then
        titleText = "🎒 Player Dropped Fruit Found"
        colorHex = 3066993
    else
        titleText = "🌱 Natural Server Spawn Found"
    end

    local data = {
        ["content"] = "",
        ["embeds"] = {
            {
                ["title"] = titleText,
                ["color"] = colorHex,
                ["fields"] = {
                    {
                        ["name"] = "Fruit Name",
                        ["value"] = "`" .. tostring(fruitName) .. "`",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Player",
                        ["value"] = "`" .. game:GetService("Players").LocalPlayer.Name .. "`",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "Method",
                        ["value"] = method,
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = "Fearz Hub • " .. os.date("%H:%M:%S - %d/%m/%Y")
                }
            }
        }
    }

    local success, encodedData = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if success then
        pcall(function()
            if syn and syn.request then
                syn.request({ Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = encodedData })
            elseif request then
                request({ Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = encodedData })
            else
                HttpService:PostAsync(webhookUrl, encodedData)
            end
        end)
    end
end

local function selectTeam()
    pcall(function()
        if LocalPlayer.Team == nil or LocalPlayer.Team.Name ~= Config.Team then
            local commF = getCommF()
            if commF then
                commF:InvokeServer("SetTeam", Config.Team)
            end
        end
    end)
end

local blacklistedLookup = nil
local function getBlacklistLookup()
    if blacklistedLookup then return blacklistedLookup end
    blacklistedLookup = {}
    for _, name in ipairs(Config.Settings.BlacklistFruits) do
        blacklistedLookup[name:lower()] = true
    end
    return blacklistedLookup
end

local function isBlacklisted(fruitName)
    local lookup = getBlacklistLookup()
    return lookup[fruitName:lower()] == true
end

local function advancedStoreFruit(fruitObj)
    if isStoring then return false end
    if not fruitObj or not fruitObj.Parent then return false end
    
    isStoring = true
    local fruitName = fruitObj.Name
    local resultStatus = false
    
    pcall(function()
        if fruitObj:IsA("Tool") and fruitObj.Parent ~= LocalPlayer.Character then
            LocalPlayer.Character.Humanoid:EquipTool(fruitObj)
            task.wait(0.2)
        end
    end)
    
    local commF = getCommF()
    if commF then
        for attempt = 1, 3 do
            if not fruitObj or not fruitObj.Parent then break end
            
            local success, result = pcall(function()
                return commF:InvokeServer("StoreFruit", fruitObj)
            end)
            
            if not success or result == nil then
                pcall(function()
                    result = commF:InvokeServer("StoreFruit", fruitName, fruitObj)
                end)
            end
            
            if success then
                if result == "Success" or result == true then
                    resultStatus = true
                    break
                elseif type(result) == "string" and (string.find(result, "Full") or string.find(result, "already") or string.find(result, "Maximum") or string.find(result, "Capacity")) then
                    resultStatus = "Full"
                    break
                end
            end
            task.wait(0.4)
        end
    end
    
    task.wait(0.3)
    isStoring = false
    return resultStatus
end

local function showFruitNotification(fruitName)
    local currentJobId = game.JobId
    Library:Notify({
        Title = "Joining Server Have Fruit",
        Content = string.format("Fruit Name: %s\nJobId: %s", tostring(fruitName), tostring(currentJobId)),
        Duration = 6
    })
end

local function collectDroppedFruitInstant(fruitObj)
    if not fruitObj or not fruitObj.Parent or not fruitObj:FindFirstChild("Handle") then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not humanoid then return end
    
    local handle = fruitObj.Handle
    
    if ScriptStatusBox then ScriptStatusBox:SetDesc("Pulling dropped fruit: " .. fruitObj.Name) end
    
    local originalCFrame = hrp.CFrame
    
    humanoid.PlatformStand = true
    startNoclip()
    hrp.Anchored = true
    
    local startTime = tick()
    repeat
        task.wait()
        pcall(function()
            if fruitObj.Parent and handle.Parent then
                hrp.CFrame = handle.CFrame
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                if firetouchinterest then
                    firetouchinterest(hrp, handle, 0)
                    firetouchinterest(hrp, handle, 1)
                end
            end
        end)
    until not fruitObj.Parent or not handle.Parent or (tick() - startTime > 3)
    
    hrp.CFrame = originalCFrame
    
    hrp.Anchored = false
    humanoid.PlatformStand = false
    stopNoclip()
end

local function collectServerFruit(fruitObj, fruitName)
    if not fruitObj or not fruitObj.Parent or not fruitObj:FindFirstChild("Handle") then return false end
    
    if ScriptStatusBox then ScriptStatusBox:SetDesc("Tweening to spawn fruit: " .. fruitName) end
    
    local handle = fruitObj.Handle
    local targetCF = handle.CFrame + Vector3.new(0, 3, 0)
    
    local successTween = optimizedTweenTo(targetCF)
    if not successTween then return false end
    
    task.wait(0.2)
    
    local startTime = tick()
    repeat
        task.wait()
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and handle.Parent and firetouchinterest then
                hrp.CFrame = handle.CFrame
                firetouchinterest(hrp, handle, 0)
                firetouchinterest(hrp, handle, 1)
            end
        end)
    until not fruitObj.Parent or not handle.Parent or (tick() - startTime > 2)
    
    return true
end

local function scanAndProcessFruits()
    if isTeleporting or isTweening then return false end
    local found = false
    
    pcall(function()
        for _, obj in ipairs(Workspace:GetChildren()) do
            if isTeleporting or isTweening then break end
            
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                local fruitName = obj.Name
                if not isBlacklisted(fruitName) and string.find(fruitName, "Fruit") then
                    found = true
                    FruitStatusBox:SetDesc("Found: " .. fruitName)
                    
                    local isPlayerDrop = (obj.Parent and obj.Parent.Name == "Drops") or (obj.Parent == Workspace)
                    pcall(function()
                        sendWebhook(fruitName, obj.Handle.Position, isPlayerDrop and "Drop" or "ServerSpawn")
                    end)
                    
                    if isPlayerDrop then
                        collectDroppedFruitInstant(obj)
                    else
                        collectServerFruit(obj, fruitName)
                    end
                    
                    local storeResult = advancedStoreFruit(obj)
                    if storeResult == "Full" or storeResult == false then
                        return true
                    elseif storeResult == true then
                        ScriptStatusBox:SetDesc("Fruit Stored Successfully!")
                    end
                    return true
                end
            elseif obj.Name == "FruitSpawns" or obj.Name == "Drops" then
                for _, fruit in ipairs(obj:GetChildren()) do
                    if fruit:FindFirstChild("Handle") and not isBlacklisted(fruit.Name) then
                        found = true
                        FruitStatusBox:SetDesc("Found: " .. fruit.Name)
                        
                        local isDropFolder = (obj.Name == "Drops")
                        pcall(function()
                            sendWebhook(fruit.Name, fruit.Handle.Position, isDropFolder and "Drop" or "ServerSpawn")
                        end)
                        
                        if isDropFolder then
                            collectDroppedFruitInstant(fruit)
                        else
                            collectServerFruit(fruit, fruit.Name)
                        end
                        
                        local storeResult = advancedStoreFruit(fruit)
                        if storeResult == "Full" or storeResult == false then
                            return true
                        elseif storeResult == true then
                            ScriptStatusBox:SetDesc("Fruit Stored Successfully!")
                        end
                        return true
                    end
                end
            end
        end
        
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name, "Fruit") and not isBlacklisted(item.Name) then
                    found = true
                    FruitStatusBox:SetDesc("Found in backpack: " .. item.Name)
                    local storeResult = advancedStoreFruit(item)
                    if storeResult == "Full" or storeResult == false then
                        return true
                    elseif storeResult == true then
                        ScriptStatusBox:SetDesc("Fruit Stored Successfully!")
                    end
                    return true
                end
            end
        end
    end)
    
    if not found then
        FruitStatusBox:SetDesc("No Fruit Found.") 
    end
    return found
end

Window:SelectTab(1)

Library:Notify({
    Title = "Fearz Hub Loaded",
    Content = "Script is running successfully!",
    Duration = 5
})

task.spawn(function()
    local seconds = 0
    while task.wait(1) do
        seconds = seconds + 1
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = seconds % 60
        TimeElapsedBox:SetDesc(string.format("%d Hours %d Minutes %d Seconds", h, m, s))
    end
end)

task.spawn(function()
    selectTeam()
    optimizePerformance()
    
    local timeWithoutFruit = 0
    while task.wait(2) do
        if isTeleporting or isTweening then continue end
        optimizePerformance()
        
        if Config.Settings.AutoHopWhenNoFruit then
            local fruitFoundInThisCycle = scanAndProcessFruits()
            if not fruitFoundInThisCycle then
                ScriptStatusBox:SetDesc("Waiting to Hop...")
                timeWithoutFruit = timeWithoutFruit + 2
                if timeWithoutFruit >= (Config.Settings.HopDelay or 5) then
                    triggerServerHop()
                end
            else
                timeWithoutFruit = 0
                ScriptStatusBox:SetDesc("Idle / Holding Fruit")
            end
        else
            ScriptStatusBox:SetDesc("Paused (Start is Off)")
            timeWithoutFruit = 0
        end
    end
end)
