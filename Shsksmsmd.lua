--==========================================================================
--  MM2 | Somtank — ICON TOGGLE UI VERSION
--  ✅ ไอคอนลอยเปิด-ปิดเมนู | ✅ ปุ่มกากบาทปิดทั้งระบบ
--==========================================================================

if not Drawing or not getgenv then
    print("❌ ไม่รองรับ Drawing API")
    return
end

-- เคลียร์ของเก่า
if getgenv().SOM then
    pcall(function()
        if getgenv().SOM.Icon then getgenv().SOM.Icon:Remove() end
        if getgenv().SOM.CloseBtn then getgenv().SOM.CloseBtn:Remove() end
        if getgenv().SOM.MenuBg then getgenv().SOM.MenuBg:Remove() end
    end)
end
getgenv().SOM = nil

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ========== SETTINGS ==========
local SOM = {
    MenuOpen = false,
    AuraEnabled = false, AuraRange = 200,
    FlingMurderer = false, FlingPower = 9999999,
    PreparingFling = false, FlingSpeed = 20, FlingDone = false,
    AutoCoin = false, CoinRange = 150,
    WalkSpeed = false, WalkSpeedVal = 27,
    NoClip = false,
    Conns = {},
    Buttons = {},
}

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
    local Near, MinD = nil, SOM.CoinRange
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

-- ========== DIMENSIONS ==========
local Screen = Camera.ViewportSize
local IconSize = 50
local IconPos = Vector2.new(15, Screen.Y/2 - IconSize/2)
local MenuW, MenuH = 240, 360
local MenuX, MenuY = 80, Screen.Y/2 - MenuH/2
local BH = 34
local Pad = 10

-- ========== ICON TOGGLE ==========
local IconBg = Drawing.new("Square")
IconBg.Size = Vector2.new(IconSize, IconSize)
IconBg.Position = IconPos
IconBg.Filled = true
IconBg.Color = Color3.fromHex("#4a2a8e")
IconBg.Visible = true

local IconText = Drawing.new("Text")
IconText.Text = "⚙️"
IconText.Size = 28
IconText.Center = true
IconText.Position = Vector2.new(IconPos.X + IconSize/2, IconPos.Y + 10)
IconText.Visible = true

local IconClick = Drawing.new("Button")
IconClick.Size = Vector2.new(IconSize, IconSize)
IconClick.Position = IconPos
IconClick.BackgroundTransparency = 1
IconClick.Visible = true
IconClick.Click = function()
    SOM.MenuOpen = not SOM.MenuOpen
    SOM.MenuBg.Visible = SOM.MenuOpen
    SOM.CloseBtn.Visible = SOM.MenuOpen
    for _, Btn in pairs(SOM.Buttons) do
        Btn.Visible = SOM.MenuOpen
    end
end

getgenv().SOM_Ico = IconBg

-- ========== MENU BACKGROUND ==========
local MenuBg = Drawing.new("Square")
MenuBg.Size = Vector2.new(MenuW, MenuH)
MenuBg.Position = Vector2.new(MenuX, MenuY)
MenuBg.Filled = true
MenuBg.Color = Color3.fromHex("#1a1a2e")
MenuBg.Visible = false
SOM.MenuBg = MenuBg

local MenuBorder = Drawing.new("SquareOutline")
MenuBorder.Size = Vector2.new(MenuW, MenuH)
MenuBorder.Position = Vector2.new(MenuX, MenuY)
MenuBorder.Thickness = 2
MenuBorder.Color = Color3.fromHex("#4a4a6a")
MenuBorder.Visible = false
SOM.MenuBorder = MenuBorder

local MenuTitle = Drawing.new("Text")
MenuTitle.Text = "  MM2 | Somtank"
MenuTitle.Size = 15
MenuTitle.Position = Vector2.new(MenuX + 10, MenuY + 8)
MenuTitle.Color = Color3.fromHex("#ffffff")
MenuTitle.Visible = false
SOM.MenuTitle = MenuTitle

-- ========== CLOSE BUTTON (X) ==========
local CloseBg = Drawing.new("Square")
CloseBg.Size = Vector2.new(26, 26)
CloseBg.Position = Vector2.new(MenuX + MenuW - 32, MenuY + 6)
CloseBg.Filled = true
CloseBg.Color = Color3.fromHex("#c02040")
CloseBg.Visible = false
SOM.CloseBg = CloseBg

local CloseText = Drawing.new("Text")
CloseText.Text = "✕"
CloseText.Size = 16
CloseText.Center = true
CloseText.Position = Vector2.new(MenuX + MenuW - 19, MenuY + 9)
CloseText.Color = Color3.fromHex("#ffffff")
CloseText.Visible = false
SOM.CloseText = CloseText

local CloseClick = Drawing.new("Button")
CloseClick.Size = Vector2.new(26, 26)
CloseClick.Position = Vector2.new(MenuX + MenuW - 32, MenuY + 6)
CloseClick.BackgroundTransparency = 1
CloseClick.Visible = false
CloseClick.Click = function()
    -- ปิดเมนูอย่างเดียว
    SOM.MenuOpen = false
    MenuBg.Visible = false
    MenuBorder.Visible = false
    MenuTitle.Visible = false
    CloseBg.Visible = false
    CloseText.Visible = false
    CloseClick.Visible = false
    for _, Btn in pairs(SOM.Buttons) do
        Btn.Visible = false
    end
end
SOM.CloseBtn = CloseClick

-- ========== FULL SYSTEM SHUTDOWN BUTTON ==========
local function CreateToggle(yPos, text, default, callback)
    local Bg = Drawing.new("Square")
    Bg.Size = Vector2.new(MenuW - 20, BH)
    Bg.Position = Vector2.new(MenuX + 10, MenuY + 38 + yPos)
    Bg.Filled = true
    Bg.Color = default and Color3.fromHex("#2e4a3a") or Color3.fromHex("#2a2a4e")
    Bg.Visible = false
    table.insert(SOM.Buttons, Bg)
    
    local Txt = Drawing.new("Text")
    Txt.Text = text
    Txt.Size = 12
    Txt.Position = Vector2.new(MenuX + 15, MenuY + 43 + yPos)
    Txt.Color = Color3.fromHex("#ffffff")
    Txt.Visible = false
    table.insert(SOM.Buttons, Txt)
    
    local Box = Drawing.new("Square")
    Box.Size = Vector2.new(16, 16)
    Box.Position = Vector2.new(MenuX + MenuW - 30, MenuY + 43 + yPos)
    Box.Filled = true
    Box.Color = default and Color3.fromHex("#4ade80") or Color3.fromHex("#f87171")
    Box.Visible = false
    table.insert(SOM.Buttons, Box)
    
    local State = default
    local Click = Drawing.new("Button")
    Click.Size = Vector2.new(MenuW - 20, BH)
    Click.Position = Vector2.new(MenuX + 10, MenuY + 38 + yPos)
    Click.BackgroundTransparency = 1
    Click.Visible = false
    Click.Click = function()
        State = not State
        Bg.Color = State and Color3.fromHex("#2e4a3a") or Color3.fromHex("#2a2a4e")
        Box.Color = State and Color3.fromHex("#4ade80") or Color3.fromHex("#f87171")
        callback(State)
    end
    table.insert(SOM.Buttons, Click)
end

local function CreateActionBtn(yPos, text, color, callback)
    local Bg = Drawing.new("Square")
    Bg.Size = Vector2.new(MenuW - 20, BH)
    Bg.Position = Vector2.new(MenuX + 10, MenuY + 38 + yPos)
    Bg.Filled = true
    Bg.Color = color
    Bg.Visible = false
    table.insert(SOM.Buttons, Bg)
    
    local Txt = Drawing.new("Text")
    Txt.Text = text
    Txt.Size = 12
    Txt.Center = true
    Txt.Position = Vector2.new(MenuX + MenuW/2, MenuY + 43 + yPos)
    Txt.Color = Color3.fromHex("#ffffff")
    Txt.Visible = false
    table.insert(SOM.Buttons, Txt)
    
    local Click = Drawing.new("Button")
    Click.Size = Vector2.new(MenuW - 20, BH)
    Click.Position = Vector2.new(MenuX + 10, MenuY + 38 + yPos)
    Click.BackgroundTransparency = 1
    Click.Visible = false
    Click.Click = callback
    table.insert(SOM.Buttons, Click)
end

-- ========== BUILD MENU CONTENT ==========
local y = 0
CreateToggle(y, "⚔️ Aura Kill", SOM.AuraEnabled, function(v) SOM.AuraEnabled = v end)
y = y + BH + Pad

CreateToggle(y, "💥 Fling ฆาตกร", SOM.FlingMurderer, function(v) SOM.FlingMurderer = v end)
y = y + BH + Pad

CreateToggle(y, "⏰ บินชนก่อนเริ่ม", SOM.PreparingFling, function(v) SOM.PreparingFling = v; SOM.FlingDone = false end)
y = y + BH + Pad

CreateToggle(y, "🪙 Auto Coin", SOM.AutoCoin, function(v) SOM.AutoCoin = v end)
y = y + BH + Pad

CreateToggle(y, "🏃 WalkSpeed", SOM.WalkSpeed, function(v) SOM.WalkSpeed = v end)
y = y + BH + Pad

CreateToggle(y, "👻 Noclip", SOM.NoClip, function(v) SOM.NoClip = v end)
y = y + BH + Pad + 5

CreateActionBtn(y, "📍 หาเหรียญใกล้สุด", Color3.fromHex("#3a5e4a"), function()
    local C = GetNearestCoin()
    local M = LocalPlayer.Character
    if C and M and M:FindFirstChild("HumanoidRootPart") then
        M.HumanoidRootPart.CFrame = CFrame.new(C.Position + Vector3.new(0, 2, 0))
    end
end)
y = y + BH + Pad

CreateActionBtn(y, "🔫 หาอาวุธใกล้สุด", Color3.fromHex("#3a4a5e"), function()
    local G = GetNearestGun()
    local M = LocalPlayer.Character
    if G and M and M:FindFirstChild("HumanoidRootPart") then
        M.HumanoidRootPart.CFrame = CFrame.new(G.Position + Vector3.new(0, 2, 0))
    end
end)
y = y + BH + Pad + 5

CreateActionBtn(y, "❌ ปิดระบบทั้งหมด", Color3.fromHex("#702030"), function()
    -- หยุดทุกอย่างและลบทั้งหมด
    for _, C in pairs(SOM.Conns) do pcall(function() C:Disconnect() end) end
    IconBg:Remove()
    IconText:Remove()
    IconClick:Remove()
    MenuBg:Remove()
    MenuBorder:Remove()
    MenuTitle:Remove()
    CloseBg:Remove()
    CloseText:Remove()
    CloseClick:Remove()
    for _, B in pairs(SOM.Buttons) do pcall(function() B:Remove() end) end
    getgenv().SOM = nil
    print("✅ ปิดระบบทั้งหมดเรียบร้อย")
end)

-- ========== MAIN LOOP ==========
table.insert(SOM.Conns, RunService.Heartbeat:Connect(function()
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Humanoid") then return end
    local HRP = Char.HumanoidRootPart
    local Hum = Char.Humanoid
    local MyPos = HRP.Position
    
    -- Noclip
    if SOM.NoClip then
        pcall(function()
            for _, P in pairs(Char:GetChildren()) do
                if P:IsA("BasePart") then P.CanCollide = false end
            end
        end)
    end
    
    -- WalkSpeed
    if SOM.WalkSpeed then
        pcall(function() Hum.WalkSpeed = 27 end)
    end
    
    -- Auto Coin
    if SOM.AutoCoin then
        for _, Coin in pairs(Workspace:GetDescendants()) do
            if Coin:IsA("BasePart") and Coin.Name == "Coin" then
                local D = Distance(MyPos, Coin.Position)
                if D < SOM.CoinRange and D > 2 then
                    local Dir = (Coin.Position - MyPos).Unit
                    HRP.Velocity = Dir * 80 + Vector3.new(0, 0.5, 0)
                end
            end
        end
    end
    
    -- Fling Murderer
    if SOM.FlingMurderer then
        local M = GetMurderer()
        if M and M.Character and M.Character:FindFirstChild("HumanoidRootPart") then
            local MPos = M.Character.HumanoidRootPart
            local D = Distance(MyPos, MPos.Position)
            if D < SOM.AuraRange then
                local Push = (MPos.Position - MyPos).Unit
                MPos.Velocity = Push * SOM.FlingPower + Vector3.new(0, -150, 0)
                MPos.RotVelocity = Vector3.new(math.random(-120,120), math.random(-80,80), math.random(-120,120))
            end
        end
    end
    
    -- Preparing Fling
    if SOM.PreparingFling and IsPreparing() and not SOM.FlingDone then
        local M = GetMurderer()
        if M and M.Character and M.Character:FindFirstChild("HumanoidRootPart") then
            local MPos = M.Character.HumanoidRootPart
            local D = Distance(MyPos, MPos.Position)
            if D > 5 then
                local Dir = (MPos.Position - MyPos).Unit
                HRP.Velocity = Dir * SOM.FlingSpeed + Vector3.new(0, 1.5, 0)
            else
                local Push = (MPos.Position - MyPos).Unit
                MPos.Velocity = Push * SOM.FlingPower + Vector3.new(0, -150, 0)
                MPos.RotVelocity = Vector3.new(math.random(-300,300), math.random(-200,200), math.random(-300,300))
                SOM.FlingDone = true
                print("✅ Fling ฆาตกรสำเร็จ!")
            end
        end
    end
    
    -- Reset FlingDone
    if not IsPreparing() and SOM.FlingDone then
        SOM.FlingDone = false
    end
end))

print("========================================")
print("✅ โหลดสำเร็จ! MM2 | Somtank")
print("   📍 ไอคอน ⚙️ ด้านซ้าย กดเพื่อเปิดเมนู")
print("   ✕ กากบาท บนขวาเมนู = ปิดเมนูอย่างเดียว")
print("   ❌ ปิดระบบทั้งหมด = ปิดทุกอย่าง")
print("========================================")
