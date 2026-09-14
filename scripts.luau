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

local HopModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/nthanhluong0702/Scripts/refs/heads/main/ServerHop.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PlaceId = game.PlaceId
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local isTeleporting = false
local isTweening = false
local currentTween = nil
local noclipConnection = nil
local isStoring = false
local CommF_Cache = nil

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

local function sendWebhook(fruitName, spawnType)
    if not Config.Settings.WebhookStoreFruit.Enabled then return end
    local webhookUrl = Config.Settings.WebhookStoreFruit.Url
    if not webhookUrl or webhookUrl == "" then return end
    
    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Fruit Finder",
            ["color"] = 65535,
            ["fields"] = {
                {["name"] = "Player", ["value"] = "```" .. playerName .. "```", ["inline"] = true},
                {["name"] = "Fruit Name", ["value"] = "```" .. tostring(fruitName) .. "```", ["inline"] = true},
                {["name"] = "Spawn Type", ["value"] = "```" .. tostring(spawnType) .. "```", ["inline"] = true},
            ["footer"] = {
                ["text"] = "Fearz Hub • " .. os.date("%H:%M:%S - %d/%m/%Y")
            }
        }}
    }
    
    pcall(function()
        local requestFunc = syn and syn.request or http and http.request or http_request or request
        if requestFunc then
            requestFunc({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
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

local function showGameNotification(titleText, descText, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = titleText,
            Text = descText,
            Duration = duration or 4,
        })
    end)
end

local function showFruitNotification(fruitName)
    local currentJobId = game.JobId
    Library:Notify({
        Title = "Joining Server Have Fruit",
        Content = string.format("Fruit Name: %s\nJobId: %s", tostring(fruitName), tostring(currentJobId)),
        Duration = 6
    })
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
                success, result = pcall(function()
                    return commF:InvokeServer("StoreFruit", fruitName, fruitObj)
                end)
            end
            
            if success and result ~= nil then
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
    if startNoclip then startNoclip() end
    hrp.Anchored = false
    
    local startTime = tick()
    repeat
        task.wait()
        pcall(function()
            if fruitObj.Parent and handle.Parent then
                hrp.CFrame = handle.CFrame + Vector3.new(0, 0.5, 0)
                
                if firetouchinterest then
                    firetouchinterest(hrp, handle, 0)
                    firetouchinterest(hrp, handle, 1)
                end
            end
        end)
    until not fruitObj.Parent or not handle.Parent or (tick() - startTime > 2.5)
    
    hrp.CFrame = originalCFrame
    hrp.Anchored = false
    humanoid.PlatformStand = false
    if stopNoclip then stopNoclip() end
end

local function collectServerFruit(fruitObj, fruitName)
    if not fruitObj or not fruitObj.Parent or not fruitObj:FindFirstChild("Handle") then return false end
    
    if ScriptStatusBox then ScriptStatusBox:SetDesc("Tweening to spawn fruit: " .. fruitName) end
    
    local handle = fruitObj.Handle
    local targetCF = handle.CFrame + Vector3.new(0, 3, 0)
    
    local tweenDone = false
    task.spawn(function()
        pcall(function()
            if optimizedTweenTo then
                optimizedTweenTo(targetCF)
            end
        end)
        tweenDone = true
    end)
    
    local waitStart = tick()
    while not tweenDone and (tick() - waitStart < 8) do
        task.wait(0.1)
        if not fruitObj.Parent or not handle.Parent then 
            tweenDone = true
            break 
        end
    end
    
    task.wait(0.1)
    
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
    
    local collectedList = {}
    
    pcall(function()
        local fruitSpawnsFolder = Workspace:FindFirstChild("FruitSpawns")
        local dropsFolder = Workspace:FindFirstChild("Drops")
        
        local function evaluateAndAdd(item, isDrop)
            if item:IsA("Tool") and item:FindFirstChild("Handle") then
                local name = item.Name
                if not isBlacklisted(name) and string.find(name, "Fruit") then
                    table.insert(collectedList, {
                        obj = item,
                        name = name,
                        isDrop = isDrop,
                        priority = isDrop and 1 or 2 
                    })
                end
            end
        end
        
        if fruitSpawnsFolder then
            for _, fruit in ipairs(fruitSpawnsFolder:GetChildren()) do
                evaluateAndAdd(fruit, false)
            end
        end
        
        if dropsFolder then
            for _, fruit in ipairs(dropsFolder:GetChildren()) do
                evaluateAndAdd(fruit, true)
            end
        end
        
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                evaluateAndAdd(obj, obj.Parent == Workspace)
            end
        end
        
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name, "Fruit") and not isBlacklisted(item.Name) then
                    table.insert(collectedList, {obj = item, name = item.Name, isDrop = false, priority = 0})
                end
            end
        end
    end)
    
    local found = #collectedList > 0
    
    if found then
        table.sort(collectedList, function(a, b)
            return a.priority < b.priority
        end)
        
        local targetData = collectedList[1]
        local targetObj = targetData.obj
        
        if targetData.priority == 0 then
            if FruitStatusBox then FruitStatusBox:SetDesc(targetData.name) end
        else
            if FruitStatusBox then FruitStatusBox:SetDesc(targetData.name) end
            
            if targetData.isDrop then
                collectDroppedFruitInstant(targetObj)
            else
                collectServerFruit(targetObj, targetData.name)
            end
        end
        
        local fruitPosition = Vector3.new(0, 0, 0)
        pcall(function()
            if targetObj and targetObj:FindFirstChild("Handle") then
                fruitPosition = targetObj.Handle.Position
            end
        end)

        local storeResult = advancedStoreFruit(targetObj)
        
        if storeResult == "Full" then
            if ScriptStatusBox then ScriptStatusBox:SetDesc("Inventory Full or Already Owned!") end
            showGameNotification("Blox Fruits", "You already max out this fruit or your inventory is full!", 5)
            return true
        else
            if ScriptStatusBox then ScriptStatusBox:SetDesc("Fruit Stored Successfully!") end
            showGameNotification("Blox Fruits", "Successfully stored " .. targetData.name .. "!", 5)
            
            task.spawn(function()
                sendWebhook(targetData.name, fruitPosition, targetData.isDrop and "Drop" or "ServerSpawn")
            end)
        end
    else
        if FruitStatusBox then
            FruitStatusBox:SetDesc("No Fruit Found.")
        end
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
                    ScriptStatusBox:SetDesc("Hopping to a new server...")
                    isTeleporting = true
                    task.wait(1)
                    
                    showFruitNotification("Joining Server Have Fruit")
                    HopModule.Hop()
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

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    if player == LocalPlayer then
        warn("Teleport failed: " .. tostring(errorMessage) .. " -> Retrying hop...")
        task.wait(2)
        pcall(function()
            HopModule.Hop()
        end)
    end
end)
