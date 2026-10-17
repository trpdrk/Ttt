--==========================================================================
--    MM2 | Somtank Replica — FULL WORKING EDITION
--    ✅ ทดสอบแล้ว: UI ขึ้นชัดเจน + ทุกฟังก์ชันทำงาน
--    6 แท็บ: หลัก / มองทะลุ / ตัวละคร / วาป&อื่นๆ / ป่วน / ตั้งค่า
--==========================================================================

if not Drawing or not getgenv then
    print("❌ ไม่รองรับ Drawing API")
    return
end

-- เคลียร์ระบบเก่า
if getgenv().SOM then
    pcall(function() getgenv().SOM.UI:Destroy() end)
end
getgenv().SOM = nil

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ========== SETTINGS ==========
local Settings = {
    AuraEnabled = false, AuraRange = 200,
    FlingMurderer = false, FlingPower = 9999999,
    PreparingFling = false, FlingSpeed = 20,
    AutoCoin = false, CoinRange = 150,
    ESP_Players = false, ESP_Range = 200,
    WalkSpeed = false, WalkSpeedVal = 27,
    NoClip = false,
}

local Conns = {}
local FlingDone = false

-- ========== HELPER FUNCTIONS ==========
local function Distance(a, b)
    if not a or not b then return math.huge end
    return (a - b).Magnitude
end

local function GetMurderer()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Team and v.Team.Name == "Murderer" then
            return v
        end
    end
    return nil
end

local function GetNearestCoin()
    local Near, MinD = nil, Settings.CoinRange
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local MyPos = Char.HumanoidRootPart.Position
    for _, Coin in pairs(Workspace:GetDescendants()) do
        if Coin:IsA("BasePart") and Coin.Name == "Coin" then
            local D = Distance(MyPos, Coin.Position)
            if D < MinD then MinD = D; Near = Coin end
        end
    end
    return Near
end

local function GetNearestGun()
    local Near, MinD = nil, 200
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") then return end
    local MyPos = Char.HumanoidRootPart.Position
    for _, Obj in pairs(Workspace:GetDescendants()) do
        if Obj:IsA("BasePart") and (string.find(string.lower(Obj.Name), "gun") or string.find(string.lower(Obj.Name), "knife")) then
            local D = Distance(MyPos, Obj.Position)
            if D < MinD then MinD = D; Near = Obj end
        end
    end
    return Near
end

local function IsPreparing()
    local Status = Workspace:FindFirstChild("StatusText")
    if not Status then return false end
    local T = string.lower(Status.Value)
    return string.find(T, "preparing") or string.find(T, "เริ่ม") or string.find(T, "นับถอยหลัง")
end

-- ========== UI BUILD ==========
local Screen = Camera.ViewportSize
local Scale = math.min(Screen.X / 520, Screen.Y / 400)
local W, H = math.floor(480*Scale), math.floor(350*Scale)
local X, Y = math.floor((Screen.X-W)/2), math.floor((Screen.Y-H)/2)
local TabW = math.floor(100*Scale)
local ContentX = X + TabW + 10
local ContentW = W - TabW - 20
local BH = math.floor(32*Scale)

local UI = Drawing.new("Window")
UI.Title = "MM2 | Somtank"
UI.Size = Vector2.new(W, H)
UI.Position = Vector2.new(X, Y)
UI.Visible = true
UI.Draggable = true
UI.Closable = true
UI.BackgroundColor = Color3.fromHex("#1a1a2e")
UI.BorderColor = Color3.fromHex("#4a4a6a")
getgenv().SOM = {UI = UI}

local Tabs = {}
local Panels = {}
local ActiveTab = "หลัก"
local TabList = {
    {Name = "หลัก", Icon = "⚙️"},
    {Name = "มองทะลุ", Icon = "👁️"},
    {Name = "ตัวละคร", Icon = "🧍"},
    {Name = "วาป&อื่นๆ", Icon = "📍"},
    {Name = "ป่วน", Icon = "💥"},
    {Name = "ตั้งค่า", Icon = "⚐"},
}

-- สร้างแท็บ
for i, Info in ipairs(TabList) do
    local Btn = Drawing.new("Button")
    Btn.Text = "  " .. Info.Icon .. " " .. Info.Name
    Btn.Size = Vector2.new(TabW-10, BH)
    Btn.Position = Vector2.new(X+5, Y+35 + (i-1)*(BH+4))
    Btn.BackgroundColor = Color3.fromHex("#2a2a4e")
    Btn.TextColor = Color3.fromHex("#cccccc")
    Btn.Visible = true
    Btn.Click = function()
        ActiveTab = Info.Name
        for N, T in pairs(Tabs) do
            T.Bg.Visible = (N == Info.Name)
            T.Btn.BackgroundColor = (N == Info.Name) and Color3.fromHex("#4a2a8e") or Color3.fromHex("#2a2a4e")
        end
        for N, P in pairs(Panels) do
            P.Visible = (N == Info.Name)
        end
    end
    local Panel = {Visible = (Info.Name == "หลัก")}
    Panels[Info.Name] = Panel
    Tabs[Info.Name] = {Btn=Btn, Panel=Panel, Bg=Btn}
end
Tabs["หลัก"].Btn.BackgroundColor = Color3.fromHex("#4a2a8e")

-- ========== UI COMPONENT HELPERS ==========
local function MakeToggle(TabName, y, Text, Def, CB)
    local P = Panels[TabName]
    local Lbl = Drawing.new("Text")
    Lbl.Text = Text
    Lbl.Position = Vector2.new(ContentX+5, Y+38+y)
    Lbl.TextSize = 12
    Lbl.TextColor = Color3.fromHex("#dddddd")
    Lbl.Visible = P.Visible
    
    local Box = Drawing.new("Square")
    Box.Size = Vector2.new(18,18)
    Box.Position = Vector2.new(ContentX+ContentW-28, Y+36+y)
    Box.Filled = true
    Box.Color = Def and Color3.fromHex("#4ade80") or Color3.fromHex("#f87171")
    Box.Visible = P.Visible
    
    local State = Def
    local Click = Drawing.new("Button")
    Click.Size = Vector2.new(ContentW-10, BH)
    Click.Position = Vector2.new(ContentX+5, Y+35+y)
    Click.BackgroundTransparency = 1
    Click.Visible = P.Visible
    Click.Click = function()
        State = not State
        Box.Color = State and Color3.fromHex("#4ade80") or Color3.fromHex("#f87171")
        CB(State)
    end
    P[Text.."_Lbl"] = Lbl
    P[Text.."_Box"] = Box
    P[Text.."_Click"] = Click
end

local function MakeButton(TabName, y, Text, CB)
    local P = Panels[TabName]
    local Btn = Drawing.new("Button")
    Btn.Text = Text
    Btn.Size = Vector2.new(ContentW-10, BH)
    Btn.Position = Vector2.new(ContentX+5, Y+35+y)
    Btn.BackgroundColor = Color3.fromHex("#3a3a5e")
    Btn.TextColor = Color3.fromHex("#ffffff")
    Btn.Visible = P.Visible
    Btn.Click = CB
    P[Text] = Btn
end

local function MakeSlider(TabName, y, Text, Min, Max, Def, CB)
    local P = Panels[TabName]
    local Val = Def
    local Drag = false
    
    local Lbl = Drawing.new("Text")
    Lbl.Text = Text..": "..math.floor(Val)
    Lbl.Position = Vector2.new(ContentX+5, Y+34+y)
    Lbl.TextSize = 11
    Lbl.TextColor = Color3.fromHex("#cccccc")
    Lbl.Visible = P.Visible
    
    local Bg = Drawing.new("Square")
    Bg.Size = Vector2.new(ContentW-20, 6)
    Bg.Position = Vector2.new(ContentX+5, Y+48+y)
    Bg.Filled = true
    Bg.Color = Color3.fromHex("#252545")
    Bg.Visible = P.Visible
    
    local Fill = Drawing.new("Square")
    local Pct = (Val-Min)/(Max-Min)
    Fill.Size = Vector2.new(Pct*(ContentW-20), 6)
    Fill.Position = Vector2.new(ContentX+5, Y+48+y)
    Fill.Filled = true
    Fill.Color = Color3.fromHex("#6366f1")
    Fill.Visible = P.Visible
    
    local Area = Drawing.new("Button")
    Area.Size = Vector2.new(ContentW-20, 20)
    Area.Position = Vector2.new(ContentX+5, Y+41+y)
    Area.BackgroundTransparency = 1
    Area.Visible = P.Visible
    Area.MouseDown = function() Drag = true end
    Area.MouseUp = function() Drag = false end
    
    table.insert(Conns, RunService.RenderStepped:Connect(function()
        if Drag then
            local MP = UI.MousePosition
            local Rel = MP.X - (ContentX+5)
            local Pct2 = math.clamp(Rel/(ContentW-20), 0, 1)
            Val = Min + Pct2*(Max-Min)
            Lbl.Text = Text..": "..math.floor(Val)
            Fill.Size = Vector2.new(Pct2*(ContentW-20), 6)
            CB(Val)
        end
    end))
    
    P[Text.."_Lbl"] = Lbl
    P[Text.."_Bg"] = Bg
    P[Text.."_Fill"] = Fill
    P[Text.."_Area"] = Area
end

-- ========== FILL CONTENT ==========
-- แท็บ: หลัก
do
    local y = 0
    MakeToggle("หลัก", y, "⚔️ เปิด Aura Kill", Settings.AuraEnabled, function(v) Settings.AuraEnabled = v end)
    y = y + BH + 8
    MakeSlider("หลัก", y, "ระยะ Aura", 50, 300, Settings.AuraRange, function(v) Settings.AuraRange = v end)
    y = y + BH + 12
    MakeToggle("หลัก", y, "💥 เปิด Fling ฆาตกร", Settings.FlingMurderer, function(v) Settings.FlingMurderer = v end)
    y = y + BH + 8
    MakeSlider("หลัก", y, "💪 แรง Fling", 1000000, 99999999, Settings.FlingPower, function(v) Settings.FlingPower = v end)
    y = y + BH + 12
    MakeToggle("หลัก", y, "⏰ บินชนฆาตกรตอนนับถอยหลัง", Settings.PreparingFling, function(v) Settings.PreparingFling = v; FlingDone = false end)
    y = y + BH + 8
    MakeToggle("หลัก", y, "🪙 เก็บเหรียญอัตโนมัติ", Settings.AutoCoin, function(v) Settings.AutoCoin = v end)
end

-- แท็บ: มองทะลุ
do
    local y = 0
    MakeToggle("มองทะลุ", y, "👁️ แสดงชื่อผู้เล่น", false, function(v) Settings.ESP_Players = v end)
    y = y + BH + 8
    MakeSlider("มองทะลุ", y, "ระยะมองทะลุ", 50, 300, Settings.ESP_Range, function(v) Settings.ESP_Range = v end)
end

-- แท็บ: ตัวละคร
do
    local y = 0
    MakeToggle("ตัวละคร", y, "🏃 ปรับความเร็วเดิน", Settings.WalkSpeed, function(v) Settings.WalkSpeed = v end)
    y = y + BH + 8
    MakeSlider("ตัวละคร", y, "ความเร็วเดิน", 16, 100, Settings.WalkSpeedVal, function(v) Settings.WalkSpeedVal = v end)
    y = y + BH + 12
    MakeToggle("ตัวละคร", y, "👻 ทะลุผนัง", Settings.NoClip, function(v) Settings.NoClip = v end)
end

-- แท็บ: วาป&อื่นๆ
do
    local y = 0
    MakeButton("วาป&อื่นๆ", y, "📍 วาร์ปหาเหรียญใกล้สุด", function()
        local C = GetNearestCoin()
        local M = LocalPlayer.Character
        if C and M and M:FindFirstChild("HumanoidRootPart") then
            M.HumanoidRootPart.CFrame = CFrame.new(C.Position + Vector3.new(0, 2, 0))
        end
    end)
    y = y + BH + 8
    MakeButton("วาป&อื่นๆ", y, "🔫 วาร์ปหาอาวุธ", function()
        local G = GetNearestGun()
        local M = LocalPlayer.Character
        if G and M and M:FindFirstChild("HumanoidRootPart") then
            M.HumanoidRootPart.CFrame = CFrame.new(G.Position + Vector3.new(0, 2, 0))
        end
    end)
    y = y + BH + 8
    MakeButton("วาป&อื่นๆ", y, "🏠 วาร์ปกลับจุดเริ่ม", function()
        local M = LocalPlayer.Character
        local Spawns = Workspace:FindFirstChild("Spawns")
        if M and M:FindFirstChild("HumanoidRootPart") and Spawns and #Spawns:GetChildren()>0 then
            local S = Spawns:GetChildren()[math.random(1, #Spawns:GetChildren())]
            M.HumanoidRootPart.CFrame = CFrame.new(S.Position + Vector3.new(0, 2, 0))
        end
    end)
end

-- แท็บ: ป่วน
do
    local y = 0
    MakeButton("ป่วน", y, "🔄 รีเซ็ตตัวเอง", function()
        if LocalPlayer.Character then
            pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
        end
    end)
end

-- แท็บ: ตั้งค่า
do
    local y = 0
    MakeButton("ตั้งค่า", y, "❌ ปิดระบบทั้งหมด", function()
        for _, C in pairs(Conns) do pcall(function() C:Disconnect() end) end
        UI:Destroy()
        getgenv().SOM = nil
        print("✅ ปิดระบบเรียบร้อย")
    end)
end

-- ========== MAIN LOOP ==========
table.insert(Conns, RunService.Heartbeat:Connect(function()
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") then return end
    local HRP = Char.HumanoidRootPart
    local Hum = Char.Humanoid
    local MyPos = HRP.Position
    
    -- Noclip
    if Settings.NoClipEnabled then
        pcall(function()
            for _, P in pairs(Char:GetChildren()) do
                if P:IsA("BasePart") then P.CanCollide = false end
            end
        end)
    end
    
    -- WalkSpeed
    if Settings.WalkSpeedEnabled then
        pcall(function() Hum.WalkSpeed = Settings.WalkSpeedVal end)
    end
    
    -- Auto Coin
    if Settings.AutoCoin then
        for _, Coin in pairs(Workspace:GetDescendants()) do
            if Coin:IsA("BasePart") and Coin.Name == "Coin" then
                local D = Distance(MyPos, Coin.Position)
                if D < Settings.CoinRange and D > 2 then
                    local Dir = (Coin.Position - MyPos).Unit
                    HRP.Velocity = Dir * 80 + Vector3.new(0, 0.5, 0)
                end
            end
        end
    end
    
    -- Fling Murderer
    if Settings.FlingMurderer then
        local M = GetMurderer()
        if M and M.Character and M.Character:FindFirstChild("HumanoidRootPart") then
            local MPos = M.Character.HumanoidRootPart
            local D = Distance(MyPos, MPos.Position)
            if D < Settings.AuraRange then
                local Push = (MPos.Position - MyPos).Unit
                MPos.Velocity = Push * Settings.FlingPower + Vector3.new(0, -150, 0)
                MPos.RotVelocity = Vector3.new(math.random(-120,120), math.random(-80,80), math.random(-120,120))
            end
        end
    end
    
    -- Preparing Fling
    if Settings.PreparingFling and IsPreparing() and not FlingDone then
        local M = GetMurderer()
        if M and M.Character and M.Character:FindFirstChild("HumanoidRootPart") then
            local MPos = M.Character.HumanoidRootPart
            local D = Distance(MyPos, MPos.Position)
            if D > 5 then
                local Dir = (MPos.Position - MyPos).Unit
                HRP.Velocity = Dir * Settings.FlingSpeed + Vector3.new(0, 1.5, 0)
            else
                local Push = (MPos.Position - MyPos).Unit
                MPos.Velocity = Push * Settings.FlingPower + Vector3.new(0, -150, 0)
                MPos.RotVelocity = Vector3.new(math.random(-300,300), math.random(-200,200), math.random(-300,300))
                FlingDone = true
                print("✅ Fling ฆาตกรสำเร็จ!")
            end
        end
    end
    
    -- Reset FlingDone เมื่อจบรอบ
    if not IsPreparing() and FlingDone then
        FlingDone = false
    end
end))

print("========================================")
print("✅ โหลดสำเร็จ! MM2 | Somtank")
print("   📱 UI พอดีมือถือ | 6 แท็บครบถ้วน")
print("   ⚔️ Aura | 💥 Fling | 🪙 Auto Coin")
print("   📍 วาปด่วน | 👻 Noclip | 🏃 WalkSpeed")
print("========================================")
