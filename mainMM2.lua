-- =====================================================
--  🎮 Murder Mystery 2 - Full Helper
--  เวอร์ชัน: 1.3.0
--  ✅ ESP + ปลิวฆาตกร + 🚀 บินเข้าหา+ทะลุจักรวาล
--  หน้าจอ: 2340×1080 | Ninja Android มือถือ
-- =====================================================

-- ========== บริการ ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ========== ⚙️ การตั้งค่าทั้งหมด ==========
local Settings = {
    -- ===== ESP =====
    ESP_Enabled = true,
    ESP_ShowRoles = true,
    ESP_ShowDistance = true,
    
    -- ===== ปลิวฆาตกร =====
    FlyMurderer_Enabled = true,
    FlyForce = 85,
    FlyUpForce = 35,
    MaxFlyDistance = 250,
    
    -- ===== 🚀 บินเข้าหา + ทะลุจักรวาล =====
    AutoFly_Enabled = false,
    AutoFly_TriggerDistance = 5,      -- ระยะเมื่อถึงแล้วจะดีด (เมตร)
    AutoFly_Speed = 17,               -- ความเร็วบินเข้าหา
    AutoFly_LaunchForce = 9999999,        -- 💥 แรงดีดพุ่งออกไป
    AutoFly_LaunchUp = 400,           -- 💥 แรงยกขึ้น
    
    -- ===== ธีมสี =====
    Theme = {
        Primary = Color3.fromRGB(45, 45, 55),
        Secondary = Color3.fromRGB(58, 58, 70),
        Accent = Color3.fromRGB(78, 185, 255),
        Text = Color3.fromRGB(240, 240, 240),
        ToggleOn = Color3.fromRGB(72, 217, 255),
        ToggleOff = Color3.fromRGB(90, 90, 105),
        CloseBtn = Color3.fromRGB(255, 85, 85),
        Murderer = Color3.fromRGB(255, 60, 60),
        Sheriff = Color3.fromRGB(60, 120, 255),
        Innocent = Color3.fromRGB(255, 255, 255)
    }
}

-- ========== ตัวแปรระบบ ==========
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local UIObjects = {}
local ESPObjects = {}
local Dragging, DragStart, StartPos = false, Vector2.new(), Vector2.new()

-- ========== 🎯 ระบบบินเข้าหา + ดีดอัตโนมัติ ==========
local AutoFly = {
    Enabled = false,
    Target = nil,
    State = "Idle" -- Idle / Flying / Preparing / Launching
}

-- ========== ฟังก์ชันช่วย ==========
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    return obj
end

local function Tween(obj, info, props)
    TweenService:Create(obj, TweenInfo.new(info or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function FindMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = "Innocent"
            pcall(function()
                local tag = p.Character:FindFirstChild("Role")
                if tag then role = tag.Value end
            end)
            if role == "Murderer" then return p end
        end
    end
    return nil
end

local function FlyTarget(target, force, upForce)
    if not target or not target.Character or not LocalPlayer.Character then return end
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local tHum = target.Character:FindFirstChild("Humanoid")
    local mRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot or not tHum or not mRoot or tHum.Health <= 0 then return end
    
    local dir = (tRoot.Position - mRoot.Position).Unit
    pcall(function()
        tRoot.Velocity = dir * force + Vector3.new(0, upForce, 0)
    end)
end

-- ========== 🚀 ฟังก์ชันระบบบินเข้าหา ==========
function AutoFly:Start()
    self.Target = FindMurderer()
    if not self.Target or not self.Target.Character then
        print("[ℹ️] ไม่พบฆาตกร")
        return false
    end
    if not LocalPlayer.Character then return false end
    
    self.Enabled = true
    self.State = "Flying"
    print("[🚀] กำลังเข้าหาฆาตกร...")
    return true
end

function AutoFly:Stop()
    self.Enabled = false
    self.State = "Idle"
    self.Target = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
        end)
    end
    print("[⏹️] หยุดทำงาน")
end

-- ลูปทำงานอัตโนมัติ
RunService.Heartbeat:Connect(function()
    if not AutoFly.Enabled or AutoFly.State == "Idle" then return end
    if not AutoFly.Target or not AutoFly.Target.Character then
        AutoFly:Stop()
        return
    end
    if not LocalPlayer.Character then return end
    
    local tRoot = AutoFly.Target.Character:FindFirstChild("HumanoidRootPart")
    local mRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot or not mRoot then return end
    
    local distance = (mRoot.Position - tRoot.Position).Magnitude
    
    if AutoFly.State == "Flying" then
        -- บินเข้าหา
        local dir = (tRoot.Position - mRoot.Position).Unit
        pcall(function()
            mRoot.Velocity = dir * Settings.AutoFly_Speed
        end)
        
        -- ถึงระยะ 3 เมตร → ดีดทะลุจักรวาล!
        if distance <= Settings.AutoFly_TriggerDistance then
            AutoFly.State = "Preparing"
            task.wait(0.1)
            FlyTarget(AutoFly.Target, Settings.AutoFly_LaunchForce, Settings.AutoFly_LaunchUp)
            print("[💥] ทะลุจักรวาล! แรง: "..Settings.AutoFly_LaunchForce)
            AutoFly:Stop()
        end
    end
end)

-- =====================================================
-- 🎨 สร้าง UI ทั้งหมด
-- =====================================================
local ScreenGui = Create("ScreenGui", {
    Name = "MM2_Helper_UI",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999
})
if LocalPlayer.PlayerGui then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- ========== 🔘 ปุ่มลอยเปิด/ปิด UI (ย้ายได้) ==========
local FloatingBtn = Create("Frame", {
    Name = "FloatingButton",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0.03, 0, 0.5, 0),
    BackgroundColor3 = Settings.Theme.Accent,
    BorderSizePixel = 0
})
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatingBtn })
Create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(255,255,255,0.25), Parent = FloatingBtn })

local BtnIcon = Create("TextLabel", {
    Parent = FloatingBtn,
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Text = "⚙️",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 26,
    Font = Enum.Font.GothamBold
})

-- ลากปุ่มลอย
FloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = FloatingBtn.Position
    end
end)
FloatingBtn.InputChanged:Connect(function(input)
    if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - DragStart
        FloatingBtn.Position = UDim2.new(
            StartPos.X.Scale, StartPos.X.Offset + delta.X,
            StartPos.Y.Scale, StartPos.Y.Offset + delta.Y
        )
    end
end)
FloatingBtn.InputEnded:Connect(function() Dragging = false end)

-- ========== 📦 หน้าต่างหลัก UI ==========
local MainWindow = Create("Frame", {
    Name = "MainWindow",
    Parent = ScreenGui,
    Size = UDim2.fromOffset(280, 410),
    Position = UDim2.new(0.5, -140, 0.5, -205),
    BackgroundColor3 = Settings.Theme.Primary,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true
})
Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = MainWindow })
Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(90,90,105), Parent = MainWindow })

-- แถบหัว
local TitleBar = Create("Frame", {
    Parent = MainWindow,
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Settings.Theme.Secondary
})
Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = TitleBar })
local TitleText = Create("TextLabel", {
    Parent = TitleBar,
    Position = UDim2.new(0, 16, 0, 0),
    Size = UDim2.new(1, -56, 1, 0),
    BackgroundTransparency = 1,
    Text = "🎮 MM2 Helper v1.3",
    TextColor3 = Settings.Theme.Text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
})

-- ปุ่มปิด ✕
local CloseBtn = Create("TextButton", {
    Parent = TitleBar,
    Position = UDim2.new(1, -36, 0, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Settings.Theme.CloseBtn,
    Text = "✕",
    TextColor3 = Color3.new(1,1,1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoLocalize = false
})
Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = CloseBtn })

-- พื้นที่เนื้อหา
local Content = Create("ScrollingFrame", {
    Parent = MainWindow,
    Position = UDim2.new(0, 0, 0, 50),
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarColor3 = Color3.fromRGB(100,100,120),
    CanvasSize = UDim2.new(0,0,0,360)
})
local ListLayout = Create("UIListLayout", {
    Parent = Content,
    Padding = UDim.new(0, 12),
    HorizontalAlignment = Enum.HorizontalAlignment.Center
})
Create("UIPadding", { Parent = Content, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0,16) })

-- ========== 🧩 ฟังก์ชันสร้างสวิตช์ ==========
local function CreateToggle(name, settingKey, callback)
    local Container = Create("Frame", {
        Parent = Content,
        Size = UDim2.new(1, -24, 0, 46),
        BackgroundColor3 = Settings.Theme.Secondary
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Container })

    Create("TextLabel", {
        Parent = Container,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Settings.Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local isOn = Settings[settingKey]
    local ToggleBg = Create("Frame", {
        Parent = Container,
        Position = UDim2.new(1, -50, 0.5, -11),
        Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = isOn and Settings.Theme.ToggleOn or Settings.Theme.ToggleOff
    })
    Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = ToggleBg })

    local Knob = Create("Frame", {
        Parent = ToggleBg,
        Position = isOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
        Size = UDim2.fromOffset(16,16),
        BackgroundColor3 = Color3.new(1,1,1)
    })
    Create("UICorner", { CornerRadius = UDim.new(1,0), Parent = Knob })

    local Btn = Create("TextButton", {
        Parent = Container,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        AutoLocalize = false
    })

    Btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        Settings[settingKey] = isOn
        Tween(ToggleBg, 0.12, {BackgroundColor3 = isOn and Settings.Theme.ToggleOn or Settings.Theme.ToggleOff})
        Tween(Knob, 0.12, {Position = isOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)})
        if callback then callback(isOn) end
    end)
end

-- ========== 🧩 ฟังก์ชันสร้างปุ่มกด ==========
local function CreateButton(name, onClick, color)
    local Container = Create("Frame", {
        Parent = Content,
        Size = UDim2.new(1, -24, 0, 46),
        BackgroundColor3 = color or Settings.Theme.Accent
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Container })

    Create("TextLabel", {
        Parent = Container,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.new(1,1,1),
        TextSize = 14,
        Font = Enum.Font.GothamBold
    })

    local Btn = Create("TextButton", {
        Parent = Container,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = "",
        AutoLocalize = false
    })
    Btn.MouseButton1Click:Connect(onClick)
end

-- ========== 📱 เติมเมนูด้วยฟีเจอร์ทั้งหมด ==========
-- ส่วน ESP
CreateToggle("👁️ แสดงตำแหน่งผู้เล่น (ESP)", "ESP_Enabled")
CreateToggle("🏷️ แสดงบทบาท", "ESP_ShowRoles")
CreateToggle("📏 แสดงระยะห่าง", "ESP_ShowDistance")

-- ส่วน ปลิวฆาตกรปกติ
CreateToggle("🚀 เปิดใช้ ปลิวฆาตกร", "FlyMurderer_Enabled")
CreateButton("💥 ปลิวฆาตกรทันที", function()
    if Settings.FlyMurderer_Enabled then
        local m = FindMurderer()
        if m then FlyTarget(m, Settings.FlyForce, Settings.FlyUpForce) end
    end
end, Color3.fromRGB(76, 175, 80))

-- ส่วน 🚀 บินเข้าหา + ทะลุจักรวาล
CreateButton("🚀 เริ่มบินเข้าหาฆาตกร", function()
    AutoFly:Start()
end, Color3.fromRGB(156, 89, 219))
CreateButton("💥 บิน+ทะลุจักรวาลทันที", function()
    AutoFly:Start()
end, Color3.fromRGB(220, 50, 50))
CreateButton("⏹️ หยุดทำงานทันที", function()
    AutoFly:Stop()
end, Color3.fromRGB(100, 100, 120))

-- ========== 🔗 เปิด-ปิดหน้าต่าง UI ==========
local UI_Open = false
FloatingBtn.MouseButton1Click:Connect(function()
    UI_Open = not UI_Open
    MainWindow.Visible = UI_Open
    Tween(FloatingBtn, 0.2, {BackgroundColor3 = UI_Open and Color3.fromRGB(80, 200, 120) or Settings.Theme.Accent})
end)
CloseBtn.MouseButton1Click:Connect(function()
    UI_Open = false
    MainWindow.Visible = false
    Tween(FloatingBtn, 0.2, {BackgroundColor3 = Settings.Theme.Accent})
end)

-- =====================================================
-- 👁️ ระบบ ESP
-- =====================================================
local function CreateESPObj(ply)
    local txt = Drawing.new("Text")
    txt.Visible = false
    txt.Center = true
    txt.Outline = true
    txt.Font = 2
    txt.Size = 12
    return { Text = txt, Player = ply }
end

RunService.RenderStepped:Connect(function()
    if not Settings.ESP_Enabled then
        for _, v in pairs(ESPObjects) do v.Text.Visible = false end
        return
    end

    for _, ply in ipairs(Players:GetPlayers()) do
        if ply == LocalPlayer then continue end
        if not ply.Character then
            if ESPObjects[ply.UserId] then ESPObjects[ply.UserId].Text.Visible = false end
            continue
        end
        local root = ply.Character:FindFirstChild("HumanoidRootPart")
        local hum = ply.Character:FindFirstChild("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            if ESPObjects[ply.UserId] then ESPObjects[ply.UserId].Text.Visible = false end
            continue
        end

        local esp = ESPObjects[ply.UserId] or CreateESPObj(ply)
        ESPObjects[ply.UserId] = esp

        local pos, onScr = Camera:WorldToViewportPoint(root.Position)
        if onScr then
            local dist = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            local role = "Innocent"
            pcall(function()
                local tag = ply.Character:FindFirstChild("Role")
                if tag then role = tag.Value end
            end)
            
            local color = Settings.Theme.Innocent
            if role == "Murderer" then color = Settings.Theme.Murderer
            elseif role == "Sheriff" then color = Settings.Theme.Sheriff end
            
            local line1 = ply.Name
            local line2 = Settings.ESP_ShowRoles and role or ""
            local line3 = Settings.ESP_ShowDistance and ("📍"..math.floor(dist).."ม.") or ""
            
            esp.Text.Color = color
            esp.Text.Position = Vector2.new(pos.X, pos.Y - 30)
            esp.Text.Text = line1..(line2~="" and "\n"..line2 or "")..(line3~="" and "\n"..line3 or "")
            esp.Text.Visible = true
        else
            esp.Text.Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(ply)
    if ESPObjects[ply.UserId] then ESPObjects[ply.UserId].Text:Remove() ESPObjects[ply.UserId] = nil end
end)

-- ========== เริ่มทำงาน ==========
print("[✅] MM2 Helper v1.3.0 พร้อมใช้งาน!")
print("[📱] แตะ ⚙️ เพื่อเปิดเมนู")
print("[🚀] บินเข้าหา+ทะลุจักรวาล พร้อมใช้งานแล้ว!")

return { Version = "1.3.0" }
