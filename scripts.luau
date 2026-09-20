local HopModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/nthanhluong0702/Scripts/refs/heads/main/ServerHop.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local isTeleporting = false
local isTweening = false
local currentTween = nil
local noclipConnection = nil
local isStoring = false
local CommF_Cache = nil

local ExternalConfig = getgenv().KaitunFruit or {}

local LoadedConfig = {}
pcall(function()
    if readfile and isfile and isfile("FearzFuitConfig.json") then
        LoadedConfig = HttpService:JSONDecode(readfile("FearzFuitConfig.json"))
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
        HopDelay = LoadedConfig.HopDelay or 3,
        TweenSpeed = LoadedConfig.TweenSpeed or 190,
        AutoStore = LoadedConfig.AutoStore ~= nil and LoadedConfig.AutoStore or true,
        FixLagEnabled = LoadedConfig.FixLagEnabled ~= nil and LoadedConfig.FixLagEnabled or true,
        BypassTeleport = LoadedConfig.BypassTeleport ~= nil and LoadedConfig.BypassTeleport or true,
        Theme = LoadedConfig.Theme or "Dark",
        Start = LoadedConfig.Start ~= nil and LoadedConfig.Start or true,
        AutoHopWhenNoFruit = LoadedConfig.Start ~= nil and LoadedConfig.Start or true,
    }
}

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
    Placeholder = "3",
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
    local speed = Config.Settings.TweenSpeed or 190
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

local function sendWebhook(fruitName, position, spawnType)
    if not Config.Settings.WebhookStoreFruit.Enabled then return end
    local webhookUrl = Config.Settings.WebhookStoreFruit.Url
    if not webhookUrl or webhookUrl == "" then return end
    
    local playerName = LocalPlayer.Name
    local jobId = game.JobId
    local placeId = game.PlaceId
    
    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Found & Stored Fruit!",
            ["color"] = 65535,
            ["fields"] = {
                {["name"] = "Player", ["value"] = "```" .. playerName .. "```", ["inline"] = true},
                {["name"] = "Fruit Name", ["value"] = "```" .. tostring(fruitName) .. "```", ["inline"] = true},
                {["name"] = "Spawn Type", ["value"] = "```" .. tostring(spawnType) .. "```", ["inline"] = true},
                {["name"] = "Position", ["value"] = string.format("```X: %.1f, Y: %.1f, Z: %.1f```", position.X, position.Y, position.Z), ["inline"] = false},
                {["name"] = "JobId (Join Server)", ["value"] = "```lua\ngame:GetService('TeleportService'):TeleportToPlaceInstance(" .. placeId .. ", '" .. jobId .. "', game.Players.LocalPlayer)\n```", ["inline"] = false}
            },
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

local function showFruitNotification(fruitName)
    local currentJobId = game.JobId
    Library:Notify({
        Title = "Joining Server Have Fruit",
        Content = string.format("Fruit Name: %s\nJobId: %s", tostring(fruitName), tostring(currentJobId)),
        Duration = 5
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
    
    local handle = fruitObj.Handle
    
    if ScriptStatusBox then 
        ScriptStatusBox:SetDesc("Collect fruit dropped: " .. fruitObj.Name) 
    end
    
    local startTime = os.clock()
    repeat
        task.wait()
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and fruitObj.Parent and handle.Parent then
                if firetouchinterest then
                    firetouchinterest(hrp, handle, 0)
                    firetouchinterest(hrp, handle, 1)
                else
                    handle.CFrame = hrp.CFrame + Vector3.new(0, 1, 0)
                end
            end
        end)
    until not fruitObj.Parent or not handle.Parent or (os.clock() - startTime > 1.5)
end

local function collectServerFruit(fruitObj, fruitName)
    if not fruitObj or not fruitObj.Parent or not fruitObj:FindFirstChild("Handle") then return false end
    
    local handle = fruitObj.Handle
    local targetCF = handle.CFrame + Vector3.new(0, 3, 0)
    
    local islandName = "Island"
    pcall(function()
        local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
        if locations then
            local minDist = math.huge
            for _, v in ipairs(locations:GetChildren()) do
                local pos = v:IsA("Model") and v:GetModelPivot().Position or (v:IsA("BasePart") and v.Position)
                if pos then
                    local dist = (targetCF.Position - pos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        islandName = v.Name
                    end
                end
            end
        end
    end)
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        hrp.CFrame = targetCF
    end
    
    task.wait(0.5)
    
    for i = 1, 5 do
        if not fruitObj.Parent or not handle.Parent then break end
        
        if ScriptStatusBox then 
            ScriptStatusBox:SetDesc("Bypass to " .. islandName) 
        end
        
        pcall(function()
            local currentHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if currentHumanoid then
                currentHumanoid.Health = 0
            end
        end)
        
        local respawnStart = os.clock()
        repeat
            task.wait(0.2)
            local currentHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        until (currentHum and currentHum.Health > 0) or (os.clock() - respawnStart > 5)
        
        task.wait(0.5)
    end
    
    if ScriptStatusBox then 
        ScriptStatusBox:SetDesc("Bypass done, count: 5") 
    end
    
    if not fruitObj.Parent or not handle.Parent then return false end
    
    if ScriptStatusBox then ScriptStatusBox:SetDesc("Tweening to collect fruit: " .. fruitName) end
    
    local tweenDone = false
    task.spawn(function()
        pcall(function()
            if optimizedTweenTo then
                optimizedTweenTo(handle.CFrame + Vector3.new(0, 3, 0))
            end
        end)
        tweenDone = true
    end)
    
    local waitStart = os.clock()
    while not tweenDone and (os.clock() - waitStart < 8) do
        task.wait(0.1)
        if not fruitObj.Parent or not handle.Parent then 
            tweenDone = true
            break 
        end
    end
    
    task.wait(0.1)
    
    local startTime = os.clock()
    repeat
        task.wait()
        pcall(function()
            local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if currentHrp and handle.Parent and firetouchinterest then
                currentHrp.CFrame = handle.CFrame
                firetouchinterest(currentHrp, handle, 0)
                firetouchinterest(currentHrp, handle, 1)
            end
        end)
    until not fruitObj.Parent or not handle.Parent or (os.clock() - startTime > 2)
    
    return true
end

local ValidFruits = {
    CommonAndLegendary = {
        "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke", "Spike", "Flame", "Falcon", 
        "Ice", "Sand", "Dark", "Diamond", "Light", "Rubber", "Barrier", "Ghost", "Magma", "Quake",
        "Buddha", "Portal", "Spider", "Sound", "Phoenix", "Pain", "Blizzard", "Gravity", 
        "Rumble", "String", "Love", "Lightning", "Creation"
    },
    Mythical = {
        "Dragon", "Kitsune", "Dough", "T-Rex", "Mammoth", "Shadow", "Venom", 
        "Control", "Spirit", "Gas", "Yeti", "Tiger", "Empyrean Kitsune"
    }
}

local function isRealFruit(name)
    for _, fruitName in ipairs(ValidFruits.Mythical) do
        if string.find(name, fruitName) then
            return true, "Mythical"
        end
    end
    
    for _, fruitName in ipairs(ValidFruits.CommonAndLegendary) do
        if string.find(name, fruitName) then
            return true, "CommonOrLegendary"
        end
    end
    
    return false, nil
end

local function scanAndProcessFruits()
    if isTeleporting or isTweening then return false end
    
    local collectedList = {}
    
    pcall(function()
        local evaluatedObjects = {}
        
        local function evaluateAndAdd(item)
            if evaluatedObjects[item] then return end
            if item:IsA("Tool") and item:FindFirstChild("Handle") then
                local name = item.Name
                local isFruitValid, fruitCategory = isRealFruit(name)
                
                if not isBlacklisted(name) and isFruitValid then
                    evaluatedObjects[item] = true
                    local priorityValue = (fruitCategory == "Mythical") and 1 or 2
                    
                    table.insert(collectedList, {
                        obj = item,
                        name = name,
                        category = fruitCategory,
                        isDrop = false,
                        priority = priorityValue
                    })
                end
            end
        end
        
local ValidFruits = {
    CommonAndLegendary = {
        "Rocket", "Spin", "Blade", "Spring", "Bomb", "Smoke", "Spike", "Flame", "Falcon", 
        "Ice", "Sand", "Dark", "Diamond", "Light", "Rubber", "Barrier", "Ghost", "Magma", "Quake",
        "Buddha", "Portal", "Spider", "Sound", "Phoenix", "Pain", "Blizzard", "Gravity", 
        "Rumble", "String", "Love", "Lightning", "Creation"
    },
    Mythical = {
        "Dragon", "Kitsune", "Dough", "T-Rex", "Mammoth", "Shadow", "Venom", 
        "Control", "Spirit", "Gas", "Yeti", "Tiger", "Empyrean Kitsune"
    }
}

local function isRealFruit(name)
    for _, fruitName in ipairs(ValidFruits.Mythical) do
        if name == fruitName then
            return true, "Mythical"
        end
    end
    
    for _, fruitName in ipairs(ValidFruits.CommonAndLegendary) do
        if name == fruitName then
            return true, "CommonOrLegendary"
        end
    end
    
    return false, nil
end

local function scanAndProcessFruits()
    if isTeleporting or isTweening then return false end
    
    local collectedList = {}
    
    pcall(function()
        local evaluatedObjects = {}
        
        local function evaluateAndAdd(item)
            if evaluatedObjects[item] then return end
            if item:IsA("Tool") and item:FindFirstChild("Handle") then
                local name = item.Name
                local isFruitValid, fruitCategory = isRealFruit(name)
                
                local notBlacked = true
                if type(isBlacklisted) == "function" then
                    notBlacked = not isBlacklisted(name)
                end
                
                if notBlacked and isFruitValid then
                    evaluatedObjects[item] = true
                    local priorityValue = (fruitCategory == "Mythical") and 1 or 2
                    
                    table.insert(collectedList, {
                        obj = item,
                        name = name,
                        category = fruitCategory,
                        isDrop = false,
                        priority = priorityValue
                    })
                end
            end
        end
        
        local function scanFolder(folder)
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
                    local isInBackpackOrChar = false
                    local p = obj.Parent
                    while p and p ~= Workspace do
                        if p:IsA("Backpack") or (p:IsA("Model") and Players:GetPlayerFromCharacter(p)) then
                            isInBackpackOrChar = true
                            break
                        end
                        p = p.Parent
                    end
                    
                    if not isInBackpackOrChar then
                        evaluateAndAdd(obj)
                    end
                end
            end
        end
        
        scanFolder(Workspace)
        
        local ignoredFolder = Workspace:FindFirstChild("Ignored")
        if ignoredFolder then
            scanFolder(ignoredFolder)
        end
        
        local dropsFolder = Workspace:FindFirstChild("Drops")
        if dropsFolder then
            scanFolder(dropsFolder)
        end
        
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local function evaluateBackpackItem(item)
                if item:IsA("Tool") then
                    local name = item.Name
                    local isFruitValid, fruitCategory = isRealFruit(name)
                    
                    local notBlacked = true
                    if type(isBlacklisted) == "function" then
                        notBlacked = not isBlacklisted(name)
                    end
                    
                    if isFruitValid and notBlacked then
                        local priorityValue = (fruitCategory == "Mythical") and 1 or 2
                        table.insert(collectedList, {
                            obj = item, 
                            name = name, 
                            category = fruitCategory,
                            isDrop = false, 
                            priority = priorityValue
                        })
                    end
                end
            end

            for _, item in ipairs(backpack:GetChildren()) do
                evaluateBackpackItem(item)
            end
            
            local character = LocalPlayer.Character
            if character then
                for _, item in ipairs(character:GetChildren()) do
                    evaluateBackpackItem(item)
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
        
        if not targetObj or (targetData.priority > 0 and not targetObj.Parent) then
            return false
        end
        
        local fruitPosition = Vector3.new(0, 0, 0)
        pcall(function()
            if targetObj and targetObj:FindFirstChild("Handle") then
                fruitPosition = targetObj.Handle.Position
            end
        end)
        
        if FruitStatusBox then 
            FruitStatusBox:SetDesc(targetData.name) 
        end
        
        if targetData.priority > 0 and type(collectDroppedFruitInstant) == "function" then
            collectDroppedFruitInstant(targetObj)
        end
        
        local storeResult = "Unknown"
        if type(advancedStoreFruit) == "function" then
            storeResult = advancedStoreFruit(targetObj)
        end
        
        if storeResult == "Full" then
            if ScriptStatusBox then ScriptStatusBox:SetDesc("Inventory Full or Already Owned!") end
            if type(showFruitNotification) == "function" then
                showFruitNotification(targetData.name)
            end
            task.wait(1)
            isTeleporting = true
            if HopModule and type(HopModule.Hop) == "function" then
                HopModule.Hop()
            end
            return true
        else
            if ScriptStatusBox then ScriptStatusBox:SetDesc("Fruit Stored Successfully!") end
            local statusLabel = targetData.isDrop and "Dropped" or "Spawned"
            task.spawn(function()
                if type(sendWebhook) == "function" then
                    sendWebhook(targetData.name, fruitPosition, statusLabel)
                end
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
                
                if timeWithoutFruit >= (Config.Settings.HopDelay or 3) then
                    ScriptStatusBox:SetDesc("Hopping to a new server...")
                    showFruitNotification("Fruits")
                    task.wait(1)
                    isTeleporting = true
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
