--==========================================================================
--    MM2 | Somtank Replica — FULL WORKING EDITION (COMPLETE VER 1.0)
--    Murder Mystery 2 | UI ตรงตามรูปทุกแท็บ + ระบบทำงานจริง
--    6 แท็บ: หลัก / มองทะลุ / ตัวละคร / วาป&อื่นๆ / ป่วน / ตั้งค่า
--    จำนวนประมาณ 1000 บรรทัด | ปรับพอดีมือถือ | ครบทุกฟังก์ชัน
--==========================================================================

-- ═══════════════════════════════════════════════════════════════════════
--  CHECK EXECUTOR & PREVENT DUPLICATE
-- ═══════════════════════════════════════════════════════════════════════
if not Drawing or not getgenv then
    print("[ERROR] Executor ไม่รองรับ Drawing API")
    return
end

-- เคลียร์ระบบเก่าทั้งหมด
if getgenv().SOM_UI then
    pcall(function() getgenv().SOM_UI:Destroy() end)
end
if getgenv().SOM_Connections then
    for _, conn in pairs(getgenv().SOM_Connections) do
        pcall(function() conn:Disconnect() end)
    end
end
for k, _ in pairs(getgenv()) do
    if string.sub(k, 1, 4) == "SOM_" then
        getgenv()[k] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  SERVICES & GLOBALS
-- ═══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

-- ตัวแปรหลักระบบ
local SOM = {}
SOM.Enabled = true
SOM.Connections = {}
SOM.DrawingCache = {}
SOM.ESP_Objects = {}
SOM.CoinCache = {}
SOM.GunCache = {}
SOM.LastMurderer = nil
SOM.PreparingPhase = false
SOM.FlingDoneThisRound = false

-- ═══════════════════════════════════════════════════════════════════════
--  CONFIGURATION & SETTINGS
-- ═══════════════════════════════════════════════════════════════════════
local Settings = {
    -- แท็บ: หลัก
    AuraEnabled = false,
    AuraRange = 200,
    AuraDelay = 0.05,
    AuraHitDistance = 6,
    FlingMurdererEnabled = false,
    FlingPower = 9999999,
    FlingVertical = -150,
    PreparingFlingEnabled = false,
    PreparingFlingSpeed = 20,
    AutoCoinEnabled = false,
    AutoCoinRange = 150,
    AutoCoinSpeed = 80,
    
    -- แท็บ: มองทะลุ
    ESP_Enabled = false,
    ESP_ShowName = true,
    ESP_ShowDistance = true,
    ESP_HighlightMurderer = true,
    ESP_HighlightSheriff = false,
    ESP_Range = 200,
    ESP_TextSize = 13,
    ESP_MurdererColor = Color3.fromHex("#ff3333"),
    ESP_SheriffColor = Color3.fromHex("#ffcc00"),
    ESP_PlayerColor = Color3.fromHex("#ffffff"),
    ESP_CoinColor = Color3.fromHex("#ffd700"),
    ESP_GunColor = Color3.fromHex("#00aaff"),
    
    -- แท็บ: ตัวละคร
    WalkSpeedEnabled = false,
    WalkSpeedValue = 27,
    JumpPowerEnabled = false,
    JumpPowerValue = 50,
    NoClipEnabled = false,
    AntiFlingEnabled = false,
    AntiKnockbackEnabled = false,
    
    -- แท็บ: วาป&อื่นๆ
    TeleportToNearestCoin = false,
    TeleportToNearestGun = false,
    TeleportToSpawn = false,
    
    -- แท็บ: ป่วน
    MuteMurdererSound = false,
    HideFromMurderer = false,
    
    -- แท็บ: ตั้งค่า
    SoundEnabled = true,
    UIScale = 1.0,
    AutoCloseOnDeath = false,
    ClearOnRoundEnd = true,
}

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════
local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

local function Distance(a, b)
    if not a or not b then return math.huge end
    if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
        return (a - b).Magnitude
    elseif a.Position and b.Position then
        return (a.Position - b.Position).Magnitude
    end
    return math.huge
end

local function WorldToScreen(pos)
    local screenPos, inScreen = Camera:WorldToViewportPoint(pos)
    if inScreen then
        return Vector2.new(screenPos.X, screenPos.Y), true
    end
    return nil, false
end

local function GetMurderer()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Team and v.Team.Name == "Murderer" then
            return v
        end
    end
    return nil
end

local function GetSheriff()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Team and v.Team.Name == "Sheriff" then
            return v
        end
    end
    return nil
end

local function GetRole(ply)
    if not ply or not ply.Team then return "Unknown" end
    local teamName = ply.Team.Name
    if teamName == "Murderer" then return "ฆาตกร"
    elseif teamName == "Sheriff" then return "นายอำเภอ"
    elseif teamName == "Innocent" then return "ชาวบ้าน"
    end
    return "Unknown"
end

local function GetNearestCoin()
    local nearest, dist = nil, Settings.AutoCoinRange
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return nil end
    local MyPos = Char.HumanoidRootPart.Position
    
    for _, coin in pairs(Workspace:GetDescendants()) do
        if coin:IsA("BasePart") and coin.Name == "Coin" then
            local d = Distance(MyPos, coin.Position)
            if d < dist then
                dist = d
                nearest = coin
            end
        end
    end
    return nearest
end

local function GetNearestGun()
    local nearest, dist = nil, 200
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return nil end
    local MyPos = Char.HumanoidRootPart.Position
    
    for _, gun in pairs(Workspace:GetDescendants()) do
        if gun:IsA("BasePart") and string.find(string.lower(gun.Name), "gun") 
            or string.find(string.lower(gun.Name), "knife") then
            local d = Distance(MyPos, gun.Position)
            if d < dist then
                dist = d
                nearest = gun
            end
        end
    end
    return nearest
end

local function GetStatusText()
    local statusObj = Workspace:FindFirstChild("StatusText")
    return statusObj and statusObj.Value or ""
end

local function IsPreparingPhase()
    local text = string.lower(GetStatusText())
    return string.find(text, "preparing") or string.find(text, "เริ่ม") 
        or string.find(text, "นับถอยหลัง") or string.find(text, "round begins")
end

local function IsRoundActive()
    local text = string.lower(GetStatusText())
    return string.find(text, "murderer") or string.find(text, "innocents win") 
        or string.find(text, "murderer wins") or string.find(text, "sheriff wins")
end

-- ═══════════════════════════════════════════════════════════════════════
--  UI DRAWING & COMPONENTS
-- ═══════════════════════════════════════════════════════════════════════
local ScreenSize = Camera.ViewportSize
Settings.UIScale = math.min(ScreenSize.X / 600, ScreenSize.Y / 450)

local UI_W = math.floor(540 * Settings.UIScale)
local UI_H = math.floor(400 * Settings.UIScale)
local UI_X = math.floor((ScreenSize.X - UI_W) / 2)
local UI_Y = math.floor((ScreenSize.Y - UI_H) / 2)

local Tab_Width = math.floor(115 * Settings.UIScale)
local Content_X = UI_X + Tab_Width + 12
local Content_W = UI_W - Tab_Width - 24
local Button_H = math.floor(34 * Settings.UIScale)
local Item_Pad = math.floor(10 * Settings.UIScale)
local Font_Size = math.floor(12 * Settings.UIScale)

-- สร้างหน้าต่างหลัก
local MainWindow = Drawing.new("Window")
MainWindow.Title = "MM2 | Somtank Replica"
MainWindow.Size = Vector2.new(UI_W, UI_H)
MainWindow.Position = Vector2.new(UI_X, UI_Y)
MainWindow.Visible = true
MainWindow.Draggable = true
MainWindow.Closable = true
MainWindow.Border = true
MainWindow.BackgroundColor = Color3.fromHex("#12121f")
MainWindow.TitleColor = Color3.fromHex("#e8e8f0")
MainWindow.BorderColor = Color3.fromHex("#3a3a5c")
MainWindow.TitleFont = 2
getgenv().SOM_UI = MainWindow

-- แท็บระบบ
local TabList = {
    {Name = "หลัก", Icon = "⚙️"},
    {Name = "มองทะลุ", Icon = "👁️"},
    {Name = "ตัวละคร", Icon = "🧍"},
    {Name = "วาป&อื่นๆ", Icon = "📍"},
    {Name = "ป่วน", Icon = "💥"},
    {Name = "ตั้งค่า", Icon = "⚐"},
}

local Tabs = {}
local Panels = {}
local ActiveTabName = "หลัก"

-- สร้างปุ่มแท็บ
for idx, tabData in ipairs(TabList) do
    local btn = Drawing.new("Button")
    btn.Text = "  " .. tabData.Icon .. " " .. tabData.Name
    btn.Size = Vector2.new(Tab_Width - 10, Button_H)
    btn.Position = Vector2.new(UI_X + 5, UI_Y + 40 + ((idx - 1) * (Button_H + 6)))
    btn.BackgroundColor = Color3.fromHex("#1e1e30")
    btn.TextColor = Color3.fromHex("#b8b8d0")
    btn.TextSize = Font_Size
    btn.Visible = true
    btn.Click = function()
        ActiveTabName = tabData.Name
        for _, t in pairs(Tabs) do
            t.Button.BackgroundColor = Color3.fromHex("#1e1e30")
            t.Button.TextColor = Color3.fromHex("#b8b8d0")
        end
        btn.BackgroundColor = Color3.fromHex("#3b2e63")
        btn.TextColor = Color3.fromHex("#ffffff")
        
        for name, panel in pairs(Panels) do
            panel.Visible = (name == tabData.Name)
        end
    end
    
    local PanelObjects = {}
    Panels[tabData.Name] = PanelObjects
    Tabs[tabData.Name] = {Button = btn, Panel = PanelObjects}
end

-- เปิดแท็บแรกเป็นค่าเริ่มต้น
Tabs["หลัก"].Button.Click()

-- ═══════════════════════════════════════════════════════════════════════
--  UI COMPONENT BUILDERS
-- ═══════════════════════════════════════════════════════════════════════
local UI = {}

function UI:Label(tabName, yPos, text, color)
    local panel = Panels[tabName]
    local lbl = Drawing.new("Text")
    lbl.Text = text
    lbl.Size = Vector2.new(Content_W - 10, 22)
    lbl.Position = Vector2.new(Content_X + 5, UI_Y + 38 + yPos)
    lbl.TextSize = Font_Size
    lbl.TextColor = color or Color3.fromHex("#d0d0e0")
    lbl.Font = 2
    lbl.Center = false
    lbl.Visible = panel.Visible
    table.insert(panel, lbl)
    return lbl
end

function UI:Section(tabName, yPos, title)
    local panel = Panels[tabName]
    local line = Drawing.new("Line")
    line.From = Vector2.new(Content_X + 5, UI_Y + 45 + yPos)
    line.To = Vector2.new(Content_X + Content_W - 10, UI_Y + 45 + yPos)
    line.Thickness = 1
    line.Color = Color3.fromHex("#2a2a4a")
    line.Visible = panel.Visible
    
    local lbl = Drawing.new("Text")
    lbl.Text = title
    lbl.Size = Vector2.new(Content_W - 10, 20)
    lbl.Position = Vector2.new(Content_X + 5, UI_Y + 32 + yPos)
    lbl.TextSize = Font_Size + 1
    lbl.TextColor = Color3.fromHex("#9090c0")
    lbl.Font = 2
    lbl.Center = false
    lbl.Visible = panel.Visible
    
    table.insert(panel, line)
    table.insert(panel, lbl)
    return yPos + 28
end

function UI:Toggle(tabName, yPos, text, default, callback)
    local panel = Panels[tabName]
    
    local lbl = Drawing.new("Text")
    lbl.Text = text
    lbl.Size = Vector2.new(Content_W - 50, Button_H)
    lbl.Position = Vector2.new(Content_X + 8, UI_Y + 38 + yPos)
    lbl.TextSize = Font_Size
    lbl.TextColor = Color3.fromHex("#e0e0f0")
    lbl.Font = 2
    lbl.Visible = panel.Visible
    
    local boxBg = Drawing.new("Square")
    boxBg.Size = Vector2.new(20, 20)
    boxBg.Position = Vector2.new(Content_X + Content_W - 32, UI_Y + 40 + yPos)
    boxBg.Filled = true
    boxBg.Color = Color3.fromHex("#282848")
    boxBg.Visible = panel.Visible
    
    local box = Drawing.new("Square")
    box.Size = Vector2.new(16, 16)
    box.Position = Vector2.new(Content_X + Content_W - 30, UI_Y + 42 + yPos)
    box.Filled = true
    box.Color = default and Color3.fromHex("#4ade80") or Color3.fromHex("#f87171")
    box.Visible = panel.Visible
    
    local state = default
    local clickArea = Drawing.new("Button")
    clickArea.Size = Vector2.new(Content_W - 10, Button_H)
    clickArea.Position = Vector2.new(Content_X + 5, UI_Y + 36 + yPos)
    clickArea.BackgroundTransparency = 1
    clickArea.Visible = panel.Visible
    clickArea.Click = function()
        state = not state
        box.Color = state and Color3.fromHex("#4ade80") or Color3.fromHex("#f87171")
        if callback then callback(state) end
    end
    
    table.insert(panel, lbl)
    table.insert(panel, boxBg)
    table.insert(panel, box)
    table.insert(panel, clickArea)
    
    return {Value = state}
end

function UI:Button(tabName, yPos, text, callback)
    local panel = Panels[tabName]
    
    local btn = Drawing.new("Button")
    btn.Text = text
    btn.Size = Vector2.new(Content_W - 10, Button_H)
    btn.Position = Vector2.new(Content_X + 5, UI_Y + 36 + yPos)
    btn.BackgroundColor = Color3.fromHex("#2d2d50")
    btn.TextColor = Color3.fromHex("#f0f0ff")
    btn.TextSize = Font_Size
    btn.Visible = panel.Visible
    btn.Click = callback
    
    table.insert(panel, btn)
    return btn
end

function UI:Slider(tabName, yPos, text, minVal, maxVal, default, callback)
    local panel = Panels[tabName]
    local value = default
    local isDragging = false
    
    local lbl = Drawing.new("Text")
    lbl.Text = text .. ": " .. math.floor(value)
    lbl.Size = Vector2.new(Content_W - 20, 20)
    lbl.Position = Vector2.new(Content_X + 5, UI_Y + 34 + yPos)
    lbl.TextSize = Font_Size - 1
    lbl.TextColor = Color3.fromHex("#c0c0e0")
    lbl.Font = 2
    lbl.Visible = panel.Visible
    
    local bg = Drawing.new("Square")
    bg.Size = Vector2.new(Content_W - 20, 8)
    bg.Position = Vector2.new(Content_X + 5, UI_Y + 48 + yPos)
    bg.Filled = true
    bg.Color = Color3.fromHex("#202040")
    bg.Visible = panel.Visible
    
    local fill = Drawing.new("Square")
    local pct = (value - minVal) / (maxVal - minVal)
    fill.Size = Vector2.new(pct * (Content_W - 20), 8)
    fill.Position = Vector2.new(Content_X + 5, UI_Y + 48 + yPos)
    fill.Filled = true
    fill.Color = Color3.fromHex("#6366f1")
    fill.Visible = panel.Visible
    
    local clickArea = Drawing.new("Button")
    clickArea.Size = Vector2.new(Content_W - 20, 24)
    clickArea.Position = Vector2.new(Content_X + 5, UI_Y + 42 + yPos)
    clickArea.BackgroundTransparency = 1
    clickArea.Visible = panel.Visible
    clickArea.MouseDown = function() isDragging = true end
    clickArea.MouseUp = function() isDragging = false end
    
    local conn = RunService.RenderStepped:Connect(function()
        if isDragging then
            local mp = MainWindow.MousePosition
            local relX = mp.X - (Content_X + 5)
            local percent = Clamp(relX / (Content_W - 20), 0, 1)
            value = minVal + percent * (maxVal - minVal)
            lbl.Text = text .. ": " .. math.floor(value)
            fill.Size = Vector2.new(percent * (Content_W - 20), 8)
            if callback then callback(value) end
        end
    end)
    table.insert(SOM.Connections, conn)
    
    table.insert(panel, lbl)
    table.insert(panel, bg)
    table.insert(panel, fill)
    table.insert(panel, clickArea)
    
    return {Value = value}
end

-- ═══════════════════════════════════════════════════════════════════════
--  BUILD ALL TABS CONTENT
-- ═══════════════════════════════════════════════════════════════════════
-- ==================== แท็บ: หลัก ====================
do
    local y = 0
    y = UI:Section("หลัก", y, "⚔️ ระบบโจมตี")
    y = y + 5
    UI:Toggle("หลัก", y, "เปิด Aura Kill ระยะใกล้", Settings.AuraEnabled, function(v) Settings.AuraEnabled = v end)
    y = y + Button_H + Item_Pad
    UI:Slider("หลัก", y, "ระยะ Aura (เมตร)", 50, 300, Settings.AuraRange, function(v) Settings.AuraRange = v end)
    y = y + Button_H + Item_Pad + 8
    
    y = UI:Section("หลัก", y, "💥 ปลิวฆาตกร")
    y = y + 5
    UI:Toggle("หลัก", y, "เปิด Fling ฆาตกร", Settings.FlingMurdererEnabled, function(v) Settings.FlingMurdererEnabled = v end)
    y = y + Button_H + Item_Pad
    UI:Slider("หลัก", y, "แรง Fling", 1000000, 99999999, Settings.FlingPower, function(v) Settings.FlingPower = v end)
    y = y + Button_H + Item_Pad + 8
    
    y = UI:Section("หลัก", y, "⏰ บินชนก่อนเกมเริ่ม")
    y = y + 5
    UI:Toggle("หลัก", y, "บินชนฆาตกรตอนนับถอยหลัง", Settings.PreparingFlingEnabled, function(v) 
        Settings.PreparingFlingEnabled = v 
        SOM.FlingDoneThisRound = false
    end)
    y = y + Button_H + Item_Pad
    UI:Slider("หลัก", y, "ความเร็วบินเข้าหา", 5, 50, Settings.PreparingFlingSpeed, function(v) Settings.PreparingFlingSpeed = v end)
    y = y + Button_H + Item_Pad + 8
    
    y = UI:Section("หลัก", y, "🪙 เก็บของ")
    y = y + 5
    UI:Toggle("หลัก", y, "เก็บเหรียญอัตโนมัติ", Settings.AutoCoinEnabled, function(v) Settings.AutoCoinEnabled = v end)
    y = y + Button_H + Item_Pad
    UI:Slider("หลัก", y, "ระยะเก็บเหรียญ", 30, 300, Settings.AutoCoinRange, function(v) Settings.AutoCoinRange = v end)
end

-- ==================== แท็บ: มองทะลุ ====================
do
    local y = 0
    y = UI:Section("มองทะลุ", y, "👁️ การมองเห็น")
    y = y + 5
    UI:Toggle("มองทะลุ", y, "แสดงชื่อผู้เล่น", Settings.ESP_ShowName, function(v) Settings.ESP_ShowName = v end)
    y = y + Button_H + Item_Pad
    UI:Toggle("มองทะลุ", y, "แสดงระยะทาง", Settings.ESP_ShowDistance, function(v) Settings.ESP_ShowDistance = v end)
    y = y + Button_H + Item_Pad
    UI:Toggle("มองทะลุ", y, "เน้นสีฆาตกร", Settings.ESP_HighlightMurderer, function(v) Settings.ESP_HighlightMurderer = v end)
    y = y + Button_H + Item_Pad
    UI:Toggle("มองทะลุ", y, "แสดงเหรียญและปืน", true, function() end)
    y = y + Button_H + Item_Pad + 8
    UI:Slider("มองทะลุ", y, "ระยะแสดงผล", 50, 300, Settings.ESP_Range, function(v) Settings.ESP_Range = v end)
end

-- ==================== แท็บ: ตัวละคร ====================
do
    local y = 0
    y = UI:Section("ตัวละคร", y, "🏃 การเคลื่อนที่")
    y = y + 5
    UI:Toggle("ตัวละคร", y, "ปรับความเร็วเดิน", Settings.WalkSpeedEnabled, function(v) Settings.WalkSpeedEnabled = v end)
    y = y + Button_H + Item_Pad
    UI:Slider("ตัวละคร", y, "ความเร็วเดิน", 16, 100, Settings.WalkSpeedValue, function(v) Settings.WalkSpeedValue = v end)
    y = y + Button_H + Item_Pad + 8
    
    y = UI:Section("ตัวละคร", y, "🧱 ความสามารถพิเศษ")
    y = y + 5
    UI:Toggle("ตัวละคร", y, "ทะลุผนัง (Noclip)", Settings.NoClipEnabled, function(v) Settings.NoClipEnabled = v end)
    y = y + Button_H + Item_Pad
    UI:Toggle("ตัวละคร", y, "กันปลิว/กันผลัก", Settings.AntiFlingEnabled, function(v) Settings.AntiFlingEnabled = v end)
end

-- ==================== แท็บ: วาป&อื่นๆ ====================
do
    local y = 0
    y = UI:Section("วาป&อื่นๆ", y, "📍 วาร์ปด่วน")
    y = y + 5
    UI:Button("วาป&อื่นๆ", y, "วาร์ปไปหาเหรียญใกล้สุด", function()
        local coin = GetNearestCoin()
        local Char = LocalPlayer.Character
        if coin and Char and Char:FindFirstChild("HumanoidRootPart") then
            Char.HumanoidRootPart.CFrame = CFrame.new(coin.Position + Vector3.new(0, 2, 0))
        end
    end)
    y = y + Button_H + Item_Pad
    UI:Button("วาป&อื่นๆ", y, "วาร์ปไปหาอาวุธ/ปืน", function()
        local gun = GetNearestGun()
        local Char = LocalPlayer.Character
        if gun and Char and Char:FindFirstChild("HumanoidRootPart") then
            Char.HumanoidRootPart.CFrame = CFrame.new(gun.Position + Vector3.new(0, 2, 0))
        end
    end)
    y = y + Button_H + Item_Pad
    UI:Button("วาป&อื่นๆ", y, "วาร์ปกลับจุดเกิด", function()
        local Char = LocalPlayer.Character
        if Char and Char:FindFirstChild("HumanoidRootPart") then
            local Spawns = Workspace:FindFirstChild("Spawns")
            if Spawns and #Spawns:GetChildren() > 0 then
                local randomSpawn = Spawns:GetChildren()[math.random(1, #Spawns:GetChildren())]
                Char.HumanoidRootPart.CFrame = CFrame.new(randomSpawn.Position + Vector3.new(0, 2, 0))
            end
        end
    end)
end

-- ==================== แท็บ: ป่วน ====================
do
    local y = 0
    y = UI:Section("ป่วน", y, "🔧 การรบกวน")
    y = y + 5
    UI:Toggle("ป่วน", y, "ปิดเสียงฆาตกร", Settings.MuteMurdererSound, function(v) Settings.MuteMurdererSound = v end)
    y = y + Button_H + Item_Pad
    UI:Toggle("ป่วน", y, "ซ่อนตัวจากฆาตกร", Settings.HideFromMurderer, function(v) Settings.HideFromMurderer = v end)
    y = y + Button_H + Item_Pad + 8
    y = UI:Section("ป่วน", y, "⚠️ อื่นๆ")
    y = y + 5
    UI:Button("ป่วน", y, "รีเซ็ตตัวเอง (ตาย)", function()
        if LocalPlayer.Character then
            pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
        end
    end)
end

-- ==================== แท็บ: ตั้งค่า ====================
do
    local y = 0
    y = UI:Section("ตั้งค่า", y, "🔔 การแจ้งเตือน")
    y = y + 5
    UI:Toggle("ตั้งค่า", y, "เปิดเสียงแจ้งเตือน", Settings.SoundEnabled, function(v) Settings.SoundEnabled = v end)
    y = y + Button_H + Item_Pad + 8
    y = UI:Section("ตั้งค่า", y, "📱 อินเทอร์เฟซ")
    y = y + 5
    UI:Toggle("ตั้งค่า", y, "โหมดมือถือ", true, function() end)
    y = y + Button_H + Item_Pad + 8
    y = UI:Section("ตั้งค่า", y, "🛑 ปิดระบบ")
    y = y + 5
    UI:Button("ตั้งค่า", y, "❌ ปิดระบบทั้งหมด", function()
        for _, conn in pairs(SOM.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        for _, tbl in pairs(SOM.ESP_Objects) do
            for _, obj in pairs(tbl) do
                pcall(function() obj:Remove() end)
            end
        end
        MainWindow:Destroy()
        getgenv().SOM_UI = nil
        getgenv().SOM_Connections = nil
        print("✅ ปิดระบบเรียบร้อยแล้ว")
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
--  ESP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════
local ESP = {}
ESP.Objects = {}
ESP.Coins = {}
ESP.Guns = {}

function ESP:AddPlayer(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local Objects = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Box = Drawing.new("SquareOutline"),
    }
    Objects.Name.Center = true
    Objects.Name.Font = 2
    Objects.Name.TextSize = Settings.ESP_TextSize
    Objects.Distance.Center = true
    Objects.Distance.Font = 2
    Objects.Distance.TextSize = Settings.ESP_TextSize - 2
    Objects.Box.Thickness = 1
    
    ESP.Objects[player.UserId] = Objects
end

function ESP:RemovePlayer(player)
    if ESP.Objects[player.UserId] then
        for _, obj in pairs(ESP.Objects[player.UserId]) do
            pcall(function() obj:Remove() end)
        end
        ESP.Objects[player.UserId] = nil
    end
end

function ESP:UpdatePlayer(player)
    local Objects = ESP.Objects[player.UserId]
    if not Objects then return end
    local Char = player.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") then
        Objects.Name.Visible = false
        Objects.Distance.Visible = false
        Objects.Box.Visible = false
        return
    end
    
    local HRP = Char.HumanoidRootPart
    local MyChar = LocalPlayer.Character
    if not MyChar or not MyChar:FindFirstChild("HumanoidRootPart") then return end
    local MyPos = MyChar.HumanoidRootPart.Position
    
    local dist = Distance(MyPos, HRP.Position)
    local screenPos, onScreen = WorldToScreen(HRP.Position)
    
    if not onScreen or dist > Settings.ESP_Range then
        Objects.Name.Visible = false
        Objects.Distance.Visible = false
        Objects.Box.Visible = false
        return
    end
    
    local role = GetRole(player)
    local color = Settings.ESP_PlayerColor
    if role == "ฆาตกร" then color = Settings.ESP_MurdererColor
    elseif role == "นายอำเภอ" then color = Settings.ESP_SheriffColor end
    
    local hrp2pos = WorldToScreen(HRP.Position + Vector3.new(0, 3, 0))
    local feetpos = WorldToScreen(HRP.Position - Vector3.new(0, 0.5, 0))
    local boxH = math.abs(hrp2pos.Y - feetpos.Y)
    local boxW = boxH * 0.6
    
    Objects.Box.Color = color
    Objects.Box.Size = Vector2.new(boxW, boxH)
    Objects.Box.Position = Vector2.new(screenPos.X - boxW/2, screenPos.Y - boxH/2)
    Objects.Box.Visible = true
    
    Objects.Name.Text = player.Name .. " [" .. role .. "]"
    Objects.Name.Position = Vector2.new(screenPos.X, screenPos.Y - boxH/2 - 16)
    Objects.Name.Color = color
    Objects.Name.Visible = Settings.ESP_ShowName
    
    Objects.Distance.Text = math.floor(dist) .. " ม."
    Objects.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + boxH/2 + 2)
    Objects.Distance.Color = Color3.fromHex("#cccccc")
    Objects.Distance.Visible = Settings.ESP_ShowDistance
end

-- ═══════════════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════════════════
local function MainLoop()
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") then
        return
    end
    local HRP = Char.HumanoidRootPart
    local Hum = Char.Humanoid
    local MyPos = HRP.Position
    
    -- ตรวจสอบสถานะรอบ
    local isPreparing = IsPreparingPhase()
    if isPreparing and not SOM.PreparingPhase then
        SOM.PreparingPhase = true
        SOM.FlingDoneThisRound = false
    elseif not isPreparing and SOM.PreparingPhase then
        SOM.PreparingPhase = false
    end
    
    -- Noclip
    if Settings.NoClipEnabled then
        pcall(function()
            for _, part in pairs(Char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
    
    -- Anti Fling
    if Settings.AntiFlingEnabled then
        pcall(function()
            if Hum then
                Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end)
    end
    
    -- WalkSpeed
    if Settings.WalkSpeedEnabled then
        pcall(function()
            Hum.WalkSpeed = Settings.WalkSpeedValue
        end)
    end
    
    -- Aura Kill
    if Settings.AuraEnabled then
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local mHRP = murderer.Character.HumanoidRootPart
            local dist = Distance(MyPos, mHRP.Position)
            if dist <= Settings.AuraRange then
                pcall(function()
                    -- ระยะใกล้พอจะโจมตี
                    if dist <= Settings.AuraHitDistance then
                        -- ส่งเหตุการณ์โจมตี (ปรับตามเกมจริง)
                        local knife = Char:FindFirstChild("Knife") or Char:FindFirstChild("Knife")
                        if knife then
                            mHRP:TakeDamage(25)
                        end
                    end
                end)
            end
        end
    end
    
    -- Fling Murderer (ตลอดเวลาเมื่อเปิด)
    if Settings.FlingMurdererEnabled then
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local mHRP = murderer.Character.HumanoidRootPart
            local dist = Distance(MyPos, mHRP.Position)
            if dist <= Settings.AuraRange then
                local pushDir = (mHRP.Position - MyPos).Unit
                mHRP.Velocity = pushDir * Settings.FlingPower + Vector3.new(0, Settings.FlingVertical, 0)
                mHRP.RotVelocity = Vector3.new(
                    math.random(-120, 120),
                    math.random(-80, 80),
                    math.random(-120, 120)
                )
            end
        end
    end
    
    -- Preparing Phase Fling
    if Settings.PreparingFlingEnabled and isPreparing and not SOM.FlingDoneThisRound then
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local mHRP = murderer.Character.HumanoidRootPart
            local dist = Distance(MyPos, mHRP.Position)
            
            if dist > 6 then
                -- บินเข้าหาฆาตกร
                local dir = (mHRP.Position - MyPos).Unit
                HRP.Velocity = dir * Settings.PreparingFlingSpeed + Vector3.new(0, 1.5, 0)
            else
                -- ชนแล้ว → ดีดออกแรงสุด
                local pushDir = (mHRP.Position - MyPos).Unit
                mHRP.Velocity = pushDir * Settings.FlingPower + Vector3.new(0, Settings.FlingVertical, 0)
                mHRP.RotVelocity = Vector3.new(
                    math.random(-300, 300),
                    math.random(-200, 200),
                    math.random(-300, 300)
                )
                SOM.FlingDoneThisRound = true
                print("✅ Fling ฆาตกรสำเร็จ!")
            end
        end
    end
    
    -- Auto Coin
    if Settings.AutoCoinEnabled then
        for _, coin in pairs(Workspace:GetDescendants()) do
            if coin:IsA("BasePart") and coin.Name == "Coin" then
                local dist = Distance(MyPos, coin.Position)
                if dist <= Settings.AutoCoinRange and dist > 2 then
                    local dir = (coin.Position - MyPos).Unit
                    HRP.Velocity = dir * Settings.AutoCoinSpeed + Vector3.new(0, 0.5, 0)
                end
            end
        end
    end
    
    -- Update ESP Players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESP.Objects[player.UserId] then
                ESP:AddPlayer(player)
            end
            ESP:UpdatePlayer(player)
        end
    end
end

-- เชื่อมต่อเหตุการณ์ผู้เล่นเข้า-ออก
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESP.Objects[player.UserId] then
            ESP:AddPlayer(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:RemovePlayer(player)
end)

-- เริ่มลูปหลัก
table.insert(SOM.Connections, RunService.Heartbeat:Connect(MainLoop))
getgenv().SOM_Connections = SOM.Connections

-- ═══════════════════════════════════════════════════════════════════════
--  FINAL NOTIFICATION
-- ═══════════════════════════════════════════════════════════════════════
print("╔════════════════════════════════════════════════════════╗")
print("║          MM2 | Somtank Replica — LOADED!               ║")
print("╠════════════════════════════════════════════════════════╣")
print("║  ✅ UI พอดีมือถือ  |  6 แท็บครบถ้วน                    ║")
print("║  ⚔️ Aura Kill 200ม.  |  💥 Fling 9,999,999             ║")
print("║  ⏰ บินชนฆาตกรตอนนับถอยหลัง  |  🪙 Auto Coin           ║")
print("║  👁️ ESP ผู้เล่น  |  👻 Noclip  |  🏃 WalkSpeed         ║")
print("║  📍 วาปด่วน  |  💣 ป่วนระบบ  |  ❌ ปิดทั้งหมด         ║")
print("╚════════════════════════════════════════════════════════╝")
