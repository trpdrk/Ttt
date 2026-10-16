-- ==============================================================================
-- MM2 DELTA HUB v2.2.2 — FINAL ULTIMATE EDITION (Fixed Anti-Fall & Smooth)
-- ✅ แก้ไข: Fling แรงสะใจ | ล็อกเงื่อนไข 40 เหรียญ | ฟาร์มลื่น + ลอยตัวไม่ตกแมพ
-- ==============================================================================

if not Drawing or not getgenv then
    print("❌ Executor ไม่รองรับ Drawing API")
    return
end

-- ทำความสะอาดระบบเก่า
if getgenv().MM2_LoadedUI then pcall(function() getgenv().MM2_LoadedUI:Destroy() end) end
for _, conn in ipairs({"MM2_Connection","MM2_NoclipConnection","MM2_CoinConnection","MM2_SpeedConnection","MM2_AuraConnection","MM2_FlingConnection","MM2_AimConnection","MM2_AFKConnection","MM2_PlayerRemoving"}) do
    if getgenv()[conn] then getgenv()[conn]:Disconnect() end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ⚙️ การตั้งค่าระบบ
local Settings = {
    Noclip = false,
    AutoCoin = false,
    WalkSpeed = false,
    AuraKill = false,
    AFKMasterMode = false,
    FlingMurderer = false,
    SheriffAimbot = false,
    SpeedValue = 27,
    CoinSpeed = 16,
    AuraRange = 200,
    AimRange = 150,
    MinCoinsForFling = 40,
    SheriffSafeDistance = 10,
    -- 🚀 ปรับแรง Fling ให้สะใจ
    FlingVelocityY = 800,
    FlingVelocityXZ = 2500,
    FlingRotVelocity = 5000,
    MoveToTimeout = 3,
    CoinContainerRefresh = 5
}

local Cache = {
    CoinContainer = nil,
    LastCoinContainerSearch = 0,
    LastCoinCheck = 0,
    SheriffTargetPos = nil,
    SheriffMoveStartTime = 0,
    CoinTargetPos = nil,
    CoinMoveStartTime = 0,
    FireTouchSupported = type(firetouchinterest) == "function"
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_ESP_Gui"
ScreenGui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
elseif gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
getgenv().MM2_LoadedUI = ScreenGui

-- ปุ่มลอย
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 52, 0, 52)
FloatingBtn.Position = UDim2.new(0, 30, 0.4, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
FloatingBtn.Text = "🔪"
FloatingBtn.TextColor3 = Color3.fromRGB(231, 76, 60)
FloatingBtn.TextSize = 24
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Active = true
FloatingBtn.Draggable = true
FloatingBtn.Parent = ScreenGui
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
FloatStroke.Color = Color3.fromRGB(231, 76, 60)
FloatStroke.Thickness = 2.5

-- หน้าต่างหลัก
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 520)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "MM2 AFK HUB v2.2.2"
Title.TextColor3 = Color3.fromRGB(231, 76, 60)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 35)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
StatusLabel.Text = "บทบาท: กำลังตรวจสอบ..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)

local CoinStatusLabel = Instance.new("TextLabel")
CoinStatusLabel.Size = UDim2.new(1, -20, 0, 30)
CoinStatusLabel.Position = UDim2.new(0, 10, 0, 80)
CoinStatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
CoinStatusLabel.Text = "เหรียญ: กำลังโหลด..."
CoinStatusLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
CoinStatusLabel.TextSize = 12
CoinStatusLabel.Font = Enum.Font.GothamMedium
CoinStatusLabel.Parent = MainFrame
Instance.new("UICorner", CoinStatusLabel).CornerRadius = UDim.new(0, 8)

local SystemStatusLabel = Instance.new("TextLabel")
SystemStatusLabel.Size = UDim2.new(1, -20, 0, 28)
SystemStatusLabel.Position = UDim2.new(0, 10, 0, 115)
SystemStatusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
SystemStatusLabel.Text = "ระบบ: ปกติ"
SystemStatusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
SystemStatusLabel.TextSize = 10
SystemStatusLabel.Font = Enum.Font.GothamMedium
SystemStatusLabel.Parent = MainFrame
Instance.new("UICorner", SystemStatusLabel).CornerRadius = UDim.new(0, 8)

-- ปุ่มสร้าง UI
local function CreateButton(text, posY, settingKey)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 38)
    Btn.Position = UDim2.new(0, 10, 0, posY)
    Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    Btn.Text = text .. ": ปิด ❌"
    Btn.TextColor3 = Color3.fromRGB(231, 76, 60)
    Btn.TextSize = 13
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = MainFrame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    Btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        Btn.Text = Settings[settingKey] and (text .. ": เปิด ✅") or (text .. ": ปิด ❌")
        Btn.TextColor3 = Settings[settingKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    end)
    return Btn
end

CreateButton("Noclip", 150, "Noclip")
CreateButton("WalkSpeed", 195, "WalkSpeed")
CreateButton("Auto Coin", 240, "AutoCoin")
CreateButton("Aura Kill (200m)", 285, "AuraKill")
CreateButton("Fling Murderer", 330, "FlingMurderer")
CreateButton("Sheriff Aim+Shoot", 375, "SheriffAimbot")
CreateButton("FULL AFK MODE", 420, "AFKMasterMode")

local uiVisible = true
FloatingBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
end)

local RoleCache, ESPCache, GunCache, processedCoins = {}, {}, {}, {}

local function RemoveESP(player)
    if ESPCache[player] then
        if ESPCache[player].Box then ESPCache[player].Box:Remove() end
        if ESPCache[player].NameText then ESPCache[player].NameText:Remove() end
        ESPCache[player] = nil
    end
    RoleCache[player] = nil
end

local function UpdatePlayerRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("StringValue") or child:IsA("ObjectValue") then
            local val = tostring(child.Value):lower()
            if val:find("murder") then return "Murderer"
            elseif val:find("sheriff") then return "Sheriff" end
        end
    end

    local roleValue = player:FindFirstChild("Role") or char:FindFirstChild("Role")
    if roleValue and roleValue:IsA("StringValue") then
        local val = roleValue.Value:lower()
        if val:find("murder") then return "Murderer"
        elseif val:find("sheriff") then return "Sheriff" end
    end

    local function checkContainer(container)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local name = item.Name:lower()
                if name:find("knife") or name:find("blade") or name:find("murderer") then return "Murderer"
                elseif name:find("gun") or name:find("revolver") or name:find("sheriff") then return "Sheriff" end
            end
        end
        return nil
    end

    local role = checkContainer(char)
    if role then return role end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then role = checkContainer(backpack) if role then return role end end
    return "Innocent"
end

local function GetCurrentCoins()
    local paths = {
        function() return LocalPlayer:FindFirstChild("PlayerData") and LocalPlayer.PlayerData:FindFirstChild("Coins") and LocalPlayer.PlayerData.Coins.Value end,
        function() return LocalPlayer:FindFirstChild("Coins") and LocalPlayer.Coins.Value end,
        function() return LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Coins") and LocalPlayer.leaderstats.Coins.Value end,
    }
    
    for _, getValue in ipairs(paths) do
        local success, val = pcall(getValue)
        if success and val ~= nil then
            local num = tonumber(val)
            if num ~= nil then return num end
        end
    end
    return nil
end

local function GetCoinContainer()
    local now = os.time()
    if Cache.CoinContainer and now - Cache.LastCoinContainerSearch < Settings.CoinContainerRefresh then
        return Cache.CoinContainer
    end
    
    local container = Workspace:FindFirstChild("Normal") or Workspace:FindFirstChild("CoinContainer")
    if not container then
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:FindFirstChild("CoinContainer") then
                container = v.CoinContainer
                break
            end
        end
    end
    
    Cache.CoinContainer = container
    Cache.LastCoinContainerSearch = now
    return container
end

local function SetupPlayerTracking(player)
    player.CharacterAdded:Connect(function(char) task.wait(0.1) RoleCache[player] = UpdatePlayerRole(player) end)
    if player.Character then RoleCache[player] = UpdatePlayerRole(player) end
end
for _, p in ipairs(Players:GetPlayers()) do SetupPlayerTracking(p) end
Players.PlayerAdded:Connect(SetupPlayerTracking)
getgenv().MM2_PlayerRemoving = Players.PlayerRemoving:Connect(RemoveESP)

-- Noclip
local OriginalCanCollide = {}
getgenv().MM2_NoclipConnection = RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character if not char then return end
    local shouldNoclip = Settings.Noclip or Settings.AutoCoin or Settings.FlingMurderer
    if shouldNoclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if OriginalCanCollide[part] == nil then OriginalCanCollide[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    else
        for part, val in pairs(OriginalCanCollide) do if part:IsDescendantOf(Workspace) then part.CanCollide = val end end
        table.clear(OriginalCanCollide)
    end
end)

-- WalkSpeed
getgenv().MM2_SpeedConnection = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum and hum.Health > 0 then hum.WalkSpeed = Settings.WalkSpeed and Settings.SpeedValue or 16 end
end)

-- 🚀 AUTO COIN (ลื่นปรื๊ด + ล็อกต้านแรงโน้มถ่วงไม่ตกแมพ)
getgenv().MM2_CoinConnection = RunService.Heartbeat:Connect(function()
    if not Settings.AutoCoin then return end
    local char = LocalPlayer.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    if os.time() - Cache.LastCoinCheck >= 1 then
        Cache.LastCoinCheck = os.time()
        local coins = GetCurrentCoins()
        if coins ~= nil then
            CoinStatusLabel.Text = "เหรียญ: " .. coins .. "/" .. Settings.MinCoinsForFling
            CoinStatusLabel.TextColor3 = coins >= Settings.MinCoinsForFling 
                and Color3.fromRGB(46, 204, 113) 
                or Color3.fromRGB(241, 196, 15)
        else
            CoinStatusLabel.Text = "เหรียญ: กำลังฟาร์ม..."
            CoinStatusLabel.TextColor3 = Color3.fromRGB(230, 126, 34)
        end
    end

    local myRole = UpdatePlayerRole(LocalPlayer)
    local coins = GetCurrentCoins()
    if myRole == "Innocent" and coins and coins >= Settings.MinCoinsForFling then return end

    local coinContainer = GetCoinContainer()
    if not coinContainer then return end

    local closestCoin, minDist = nil, math.huge
    pcall(function()
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if (coin.Name == "Coin" or coin:FindFirstChild("CoinVisual")) and not processedCoins[coin] then
                local part = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (hrp.Position - part.Position).Magnitude
                    if dist < minDist then minDist = dist; closestCoin = coin end
                end
            end
        end
    end)

    if closestCoin then
        local part = closestCoin:IsA("BasePart") and closestCoin or closestCoin:FindFirstChildWhichIsA("BasePart")
        if not part then return end
        local targetPos = part.Position
        
        -- 🛡️ ป้องกันตกแมพ: พยุงตัวลอยกลางอากาศชิลๆ เวลาเก็บเหรียญบนที่สูง
        hrp.Velocity = Vector3.new(0, 2, 0)
        hum:MoveTo(targetPos)
        
        if (hrp.Position - targetPos).Magnitude < 3.5 then
            processedCoins[closestCoin] = true
        end
    else
        if next(processedCoins) ~= nil then table.clear(processedCoins) end
        Cache.CoinTargetPos = nil
    end
end)

-- Aura Kill — ฆาตกร
getgenv().MM2_AuraConnection = RunService.Heartbeat:Connect(function()
    if not Settings.AuraKill then return end
    local char = LocalPlayer.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    SystemStatusLabel.Text = Cache.FireTouchSupported 
        and "✅ firetouchinterest พร้อมใช้งาน" 
        or "⚠️ ใช้โหมดสำรอง (หัน+เดินเข้าหา)"
    SystemStatusLabel.TextColor3 = Cache.FireTouchSupported 
        and Color3.fromRGB(100, 200, 100) 
        or Color3.fromRGB(230, 126, 34)

    local myRole = UpdatePlayerRole(LocalPlayer)
    local tool = char:FindFirstChildOfClass("Tool")
    local isMurderer = myRole == "Murderer" or (tool and (tool.Name:lower():find("knife") or tool.Name:lower():find("blade")))

    if isMurderer and not tool then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("knife") or t.Name:lower():find("blade")) then
                    hum:EquipTool(t); tool = t; break
                end
            end
        end
    end

    if isMurderer and tool and tool:FindFirstChild("Handle") then
        local handle = tool.Handle
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            pcall(function()
                local pChar = p.Character
                if not pChar then return end
                local pHrp = pChar:FindFirstChild("HumanoidRootPart")
                local pHum = pChar:FindFirstChild("Humanoid")
                if not pHrp or not pHum or pHum.Health <= 0 then return end
                
                local dist = (hrp.Position - pHrp.Position).Magnitude
                if dist <= Settings.AuraRange then
                    if Cache.FireTouchSupported then
                        firetouchinterest(handle, pHrp, 0)
                        firetouchinterest(handle, pHrp, 1)
                    else
                        hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(pHrp.Position.X, pHrp.Position.Y, pHrp.Position.Z))
                        hum:MoveTo(pHrp.Position)
                    end
                end
            end)
        end
    end
end)

-- Sheriff: เดินหา + ล็อคเป้า + ยิง
getgenv().MM2_AimConnection = RunService.Heartbeat:Connect(function()
    if not Settings.SheriffAimbot then return end
    local char = LocalPlayer.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local myRole = UpdatePlayerRole(LocalPlayer)
    local tool = char:FindFirstChildOfClass("Tool")
    local isSheriff = myRole == "Sheriff" or (tool and (tool.Name:lower():find("gun") or tool.Name:lower():find("revolver")))

    if isSheriff and not tool then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name:lower():find("gun") or t.Name:lower():find("revolver")) then
                    hum:EquipTool(t); tool = t; break
                end
            end
        end
    end

    if not isSheriff or not tool then return end

    local targetHrp = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        pcall(function()
            if UpdatePlayerRole(p) ~= "Murderer" then return end
            local pChar = p.Character
            if not pChar then return end
            local ph = pChar:FindFirstChild("HumanoidRootPart")
            local phum = pChar:FindFirstChild("Humanoid")
            if ph and phum and phum.Health > 0 then
                local dist = (hrp.Position - ph.Position).Magnitude
                if dist <= Settings.AimRange then targetHrp = ph end
            end
        end)
    end

    if targetHrp then
        local dirAway = (hrp.Position - targetHrp.Position).Unit
        dirAway = Vector3.new(dirAway.X, 0, dirAway.Z).Unit
        local safePos = targetHrp.Position + dirAway * Settings.SheriffSafeDistance
        safePos = Vector3.new(safePos.X, hrp.Position.Y, safePos.Z)
        
        if Cache.SheriffTargetPos ~= safePos then
            Cache.SheriffTargetPos = safePos
            Cache.SheriffMoveStartTime = os.time()
            hum:MoveTo(safePos)
        elseif os.time() - Cache.SheriffMoveStartTime > Settings.MoveToTimeout then
            hum:MoveTo(hrp.Position)
            Cache.SheriffTargetPos = nil
        end

        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHrp.Position + Vector3.new(0, 1.5, 0))
        end)

        local dist = (hrp.Position - targetHrp.Position).Magnitude
        if dist <= Settings.SheriffSafeDistance + 2 then
            pcall(function()
                local evt = tool:FindFirstChild("Shoot") or tool:FindFirstChild("Remote") or tool:FindFirstChild("GunEvent")
                if evt and evt:IsA("RemoteEvent") then
                    evt:FireServer(targetHrp.Position, targetHrp)
                else
                    for _, d in ipairs(tool:GetDescendants()) do
                        if d:IsA("RemoteEvent") then d:FireServer(targetHrp.Position, targetHrp) end
                    end
                end
            end)
        end
    else
        Cache.SheriffTargetPos = nil
    end
end)

-- 🚀 FLING MURDERER (ล็อกเงื่อนไข 40 เหรียญเป๊ะ + แรงดีดสะใจ)
local spinAngle = 0
getgenv().MM2_FlingConnection = RunService.Heartbeat:Connect(function()
    if not Settings.FlingMurderer then spinAngle = 0; return end
    local char = LocalPlayer.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then spinAngle = 0; return end

    local myRole = UpdatePlayerRole(LocalPlayer)
    if myRole ~= "Innocent" then spinAngle = 0; return end

    local coins = GetCurrentCoins()
    if coins == nil or coins < Settings.MinCoinsForFling then
        spinAngle = 0
        return
    end

    local murdererHrp = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        pcall(function()
            if UpdatePlayerRole(p) ~= "Murderer" then return end
            local pChar = p.Character
            if not pChar then return end
            local ph = pChar:FindFirstChild("HumanoidRootPart")
            local phum = pChar:FindFirstChild("Humanoid")
            if ph and phum and phum.Health > 0 then
                murdererHrp = ph
            end
        end)
    end

    if murdererHrp then
        spinAngle = spinAngle + 180
        pcall(function()
            local offset = Vector3.new(
                math.cos(math.rad(spinAngle)) * 1.2, 0.5,
                math.sin(math.rad(spinAngle)) * 1.2
            )
            hrp.CFrame = murdererHrp.CFrame + offset
            hrp.Velocity = Vector3.new(0, 300, 0)
            hrp.RotVelocity = Vector3.new(0, 5000, 0)
            
            murdererHrp.Velocity = Vector3.new(
                math.random(-Settings.FlingVelocityXZ, Settings.FlingVelocityXZ),
                Settings.FlingVelocityY,
                math.random(-Settings.FlingVelocityXZ, Settings.FlingVelocityXZ)
            )
            murdererHrp.RotVelocity = Vector3.new(
                math.random(-Settings.FlingRotVelocity, Settings.FlingRotVelocity),
                Settings.FlingRotVelocity,
                math.random(-Settings.FlingRotVelocity, Settings.FlingRotVelocity)
            )
        end)
    end
end)

-- ESP & สถานะ
local lastUpdate = 0
getgenv().MM2_Connection = RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastUpdate >= 0.1 then
        lastUpdate = now
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                pcall(function() RoleCache[p] = UpdatePlayerRole(p) end)
            end
        end
    end

    local myRole = UpdatePlayerRole(LocalPlayer)
    StatusLabel.Text = "บทบาท: " .. myRole

    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        pcall(function()
            local pChar = p.Character
            if not pChar then return end
            local phrp = pChar:FindFirstChild("HumanoidRootPart")
            local phum = pChar:FindFirstChild("Humanoid")
            if not phrp or not phum or phum.Health <= 0 then return end
            
            local targetRole = UpdatePlayerRole(p)
            local show = false
            local color = Color3.fromRGB(231, 76, 60)
            if myRole == "Innocent" then
                if targetRole == "Murderer" then show = true; color = Color3.fromRGB(231, 76, 60)
                elseif targetRole == "Sheriff" then show = true; color = Color3.fromRGB(52, 152, 219) end
            elseif myRole == "Murderer" then
                if targetRole == "Sheriff" then show = true; color = Color3.fromRGB(52, 152, 219)
                elseif targetRole == "Innocent" then show = true; color = Color3.fromRGB(100, 200, 100) end
            elseif myRole == "Sheriff" then
                if targetRole == "Murderer" then show = true; color = Color3.fromRGB(231, 76, 60) end
            end

            if not ESPCache[p] then
                local box = Drawing.new("Square")
                box.Visible = false; box.Thickness = 1.5; box.Filled = false
                local txt = Drawing.new("Text")
                txt.Visible = false; txt.Size = 13; txt.Center = true; txt.Outline = true
                ESPCache[p] = {Box = box, NameText = txt}
            end

            local cache = ESPCache[p]
            if show then
                cache.Box.Color = color; cache.NameText.Color = color
                local vec, onScrn = Camera:WorldToViewportPoint(phrp.Position)
                if onScrn then
                    local head = pChar:FindFirstChild("Head")
                    local top = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0)) or vec
                    local bot = Camera:WorldToViewportPoint(phrp.Position - Vector3.new(0,3,0))
                    local h = math.abs(top.Y - bot.Y)
                    local w = h/2
                    cache.Box.Size = Vector2.new(w, h)
                    cache.Box.Position = Vector2.new(vec.X - w/2, top.Y)
                    cache.Box.Visible = true
                    local dist = myHrp and math.floor((myHrp.Position - phrp.Position).Magnitude) or 0
                    cache.NameText.Text = "[" .. targetRole .. "] " .. dist .. "m"
                    cache.NameText.Position = Vector2.new(vec.X - w/2, top.Y - 16)
                    cache.NameText.Visible = true
                else
                    cache.Box.Visible = false; cache.NameText.Visible = false
                end
            else
                cache.Box.Visible = false; cache.NameText.Visible = false
            end
        end)
    end
end)

print("✅ MM2 AFK Hub v2.2.2 โหลดเสร็จสมบูรณ์เรียบร้อย!")
print("🔥 Fling แรงสะใจ | ฟาร์มเหรียญลื่นปรื๊ด + ป้องกันตกแมพ | ล็อกเงื่อนไข 40 เหรียญเป๊ะ")
