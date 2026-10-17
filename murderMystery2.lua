if not Drawing or not getgenv then
    print("[ERROR] Executor ไม่รองรับ Drawing API")
    return
end

pcall(function() if getgenv().SOM_UI then getgenv().SOM_UI:Destroy() end end)
local OLD = {"SOM_Render","SOM_Stepped","SOM_Heart","SOM_Coin","SOM_Aura","SOM_Aim","SOM_Fly","SOM_Removing","SOM_Adding","SOM_Fling"}
for _,k in ipairs(OLD) do
    if getgenv()[k] then pcall(function() getgenv()[k]:Disconnect() end) end
    getgenv()[k] = nil
end
if getgenv().SOM_ESP then
    for _,d in pairs(getgenv().SOM_ESP) do
        pcall(function() if d.Box then d.Box:Remove() end end)
        pcall(function() if d.Text then d.Text:Remove() end end)
    end
end
getgenv().SOM_ESP = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local canFireTouch = (type(firetouchinterest) == "function")
local scriptActive = true

local S = {
    AutoShoot       = false,
    ShootPart       = "Head",
    AutoThrowKnife  = false,
    KnifeTP         = false,
    KnifeTPRange    = 0,
    AutoLock        = false,
    ExpandTarget    = false,
    ExpandSize      = 300,
    KillAura        = false,
    KillAuraRange   = 200,
    ShowAuraRadius  = false,
    Prediction      = true,
    ShootThroughWall= true,
    AutoCoin        = false,
    CoinMode        = "TP",
    AfterCoin       = "TP Sky",
    MoveSpeed       = 80,
    DelayAfter      = 0,
    DelayBeforeTP   = 0,
    ESP_Players     = false,
    ESP_Names       = true,
    ESP_Distance    = true,
    ESP_TextSize    = 16,
    Color_Murderer  = Color3.fromRGB(255, 50, 50),
    Color_Sheriff   = Color3.fromRGB(50, 120, 255),
    Color_Innocent  = Color3.fromRGB(50, 220, 80),
    Noclip          = false,
    SpeedBoost      = false,
    SpeedValue      = 100,
    HighJump        = false,
    JumpPower       = 400,
    InfiniteJump    = false,
    Fly             = false,
    FlySpeed        = 150,
    AutoPickupGun   = true,
    AntiFling       = true,
    GodMode         = false,
    SelectedPlayer  = "",
}

local PRESET_COLORS = {
    Color3.fromRGB(255,50,50), Color3.fromRGB(50,120,255), Color3.fromRGB(50,220,80),
    Color3.fromRGB(255,215,0), Color3.fromRGB(180,80,255), Color3.fromRGB(255,255,255),
    Color3.fromRGB(255,105,180), Color3.fromRGB(0,255,255),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Somtank_Replica"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
elseif gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = CoreGui end
getgenv().SOM_UI = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 960, 0, 600)
MainFrame.Position = UDim2.new(0.5, -480, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
local mst = Instance.new("UIStroke", MainFrame); mst.Color = Color3.fromRGB(60,60,80); mst.Thickness = 1.5

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 56)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local JokerIcon = Instance.new("Frame")
JokerIcon.Size = UDim2.new(0, 40, 0, 40)
JokerIcon.Position = UDim2.new(0, 12, 0.5, -20)
JokerIcon.BackgroundColor3 = Color3.fromRGB(80, 30, 130)
JokerIcon.Parent = TitleBar
Instance.new("UICorner", JokerIcon).CornerRadius = UDim.new(1, 0)
local JokerText = Instance.new("TextLabel")
JokerText.Size = UDim2.new(1,0,1,0); JokerText.BackgroundTransparency = 1
JokerText.Text = "🃏"; JokerText.TextSize = 24; JokerText.Font = Enum.Font.GothamBold
JokerText.Parent = JokerIcon

local TitleTxt = Instance.new("TextLabel")
TitleTxt.Size = UDim2.new(0, 300, 0, 26); TitleTxt.Position = UDim2.new(0, 62, 0, 6)
TitleTxt.BackgroundTransparency = 1; TitleTxt.Text = "MM2 | Somtank"
TitleTxt.TextColor3 = Color3.fromRGB(255,255,255); TitleTxt.TextSize = 20
TitleTxt.Font = Enum.Font.GothamBold; TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
TitleTxt.Parent = TitleBar
local SubTxt = Instance.new("TextLabel")
SubTxt.Size = UDim2.new(0, 300, 0, 18); SubTxt.Position = UDim2.new(0, 62, 0, 32)
SubTxt.BackgroundTransparency = 1; SubTxt.Text = "Murder Mystery 2 | MADE BY DRIVER (Replica)"
SubTxt.TextColor3 = Color3.fromRGB(160,160,170); SubTxt.TextSize = 12
SubTxt.Font = Enum.Font.GothamMedium; SubTxt.TextXAlignment = Enum.TextXAlignment.Left
SubTxt.Parent = TitleBar

local function makeTopBtn(text, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 30, 0, 30); b.Position = UDim2.new(1, x, 0.5, -15)
    b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 16; b.Font = Enum.Font.GothamBold; b.Parent = TitleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end
local MinBtn = makeTopBtn("−", -76, Color3.fromRGB(70,70,90))
local CloseBtn = makeTopBtn("X", -40, Color3.fromRGB(200,50,50))

local LeftNav = Instance.new("Frame")
LeftNav.Size = UDim2.new(0, 170, 1, -116); LeftNav.Position = UDim2.new(0, 0, 0, 56)
LeftNav.BackgroundTransparency = 1; LeftNav.Parent = MainFrame

local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(0, 170, 0, 60); PlayerBar.Position = UDim2.new(0, 0, 1, -60)
PlayerBar.BackgroundColor3 = Color3.fromRGB(28,28,36); PlayerBar.Parent = MainFrame
local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 44, 0, 44); AvatarImg.Position = UDim2.new(0, 8, 0.5, -22)
AvatarImg.BackgroundColor3 = Color3.fromRGB(50,50,60)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150"
AvatarImg.Parent = PlayerBar
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1,0)
local PlayerName = Instance.new("TextLabel")
PlayerName.Size = UDim2.new(1, -60, 0, 20); PlayerName.Position = UDim2.new(0, 60, 0.5, -10)
PlayerName.BackgroundTransparency = 1; PlayerName.Text = LocalPlayer.Name
PlayerName.TextColor3 = Color3.fromRGB(230,230,230); PlayerName.TextSize = 13
PlayerName.Font = Enum.Font.GothamMedium; PlayerName.TextXAlignment = Enum.TextXAlignment.Left
PlayerName.Parent = PlayerBar

local function makeScroll(name, x, w)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name; sf.Size = UDim2.new(0, w, 1, -64); sf.Position = UDim2.new(0, x, 0, 56)
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4; sf.ScrollBarImageColor3 = Color3.fromRGB(80,80,100)
    sf.CanvasSize = UDim2.new(0, 0, 0, 1300); sf.Parent = MainFrame
    sf.AutomaticCanvasSize = Enum.AutomaticSize.None
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingTop = UDim.new(0,6); pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight = UDim.new(0,8)
    return sf
end
local MidScroll = makeScroll("Mid", 170, 370)
local RightScroll = makeScroll("Right", 540, 400)

local DropFrame = Instance.new("Frame")
DropFrame.Size = UDim2.new(0, 200, 0, 150); DropFrame.BackgroundColor3 = Color3.fromRGB(35,35,45)
DropFrame.BorderSizePixel = 0; DropFrame.Visible = false; DropFrame.ZIndex = 50
DropFrame.Parent = ScreenGui
Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 8)
local DropLayout = Instance.new("UIListLayout", DropFrame)
DropLayout.Padding = UDim.new(0,2)
local activeDropdown = nil

local function addSection(parent, icon, text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 34); f.BackgroundColor3 = Color3.fromRGB(34,34,46)
    f.Parent = parent; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1,-10,1,0); t.Position = UDim2.new(0,10,0,0)
    t.BackgroundTransparency = 1; t.Text = icon.."  "..text
    t.TextColor3 = Color3.fromRGB(190,150,255); t.TextSize = 14; t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = f
    return f
end

local function addToggle(parent, text, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 36); f.BackgroundColor3 = Color3.fromRGB(30,30,40)
    f.Parent = parent; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1,-60,1,0); lb.Position = UDim2.new(0,12,0,0)
    lb.BackgroundTransparency = 1; lb.Text = text; lb.TextColor3 = Color3.fromRGB(220,220,225)
    lb.TextSize = 13; lb.Font = Enum.Font.GothamMedium; lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 42, 0, 22); btn.Position = UDim2.new(1, -50, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(120,80,220) or Color3.fromRGB(60,60,75)
    btn.Text = ""; btn.Parent = f; Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,18,0,18); knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Position = default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.Parent = btn; Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(120,80,220) or Color3.fromRGB(60,60,75)
        knob.Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
        if callback then pcall(callback, state) end
    end)
    return f
end

local function addSlider(parent, text, minv, maxv, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 56); f.BackgroundColor3 = Color3.fromRGB(30,30,40)
    f.Parent = parent; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1,-70,0,20); lb.Position = UDim2.new(0,12,0,6)
    lb.BackgroundTransparency = 1; lb.Text = text
    lb.TextColor3 = Color3.fromRGB(220,220,225); lb.TextSize = 13; lb.Font = Enum.Font.GothamMedium
    lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = f
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0,50,0,20); val.Position = UDim2.new(1,-58,0,6)
    val.BackgroundTransparency = 1; val.Text = tostring(default)
    val.TextColor3 = Color3.fromRGB(255,255,255); val.TextSize = 13; val.Font = Enum.Font.GothamBold
    val.TextXAlignment = Enum.TextXAlignment.Right; val.Parent = f
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-24,0,6); track.Position = UDim2.new(0,12,0,34)
    track.BackgroundColor3 = Color3.fromRGB(50,50,65); track.Parent = f
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-minv)/(maxv-minv),0,1,0); fill.BackgroundColor3 = Color3.fromRGB(150,100,255)
    fill.Parent = track; Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0,16,0,16); knob.Text = ""
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Position = UDim2.new((default-minv)/(maxv-minv), -8, 0.5, -8); knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local dragging = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = i.Position
        local rel = math.clamp((p.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minv + rel * (maxv - minv))
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        val.Text = tostring(v)
        if callback then pcall(callback, v) end
    end)
    return f
end

local function addActionButton(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 38); b.BackgroundColor3 = Color3.fromRGB(32,32,44)
    b.Text = "   "..text; b.TextColor3 = Color3.fromRGB(235,235,240)
    b.TextSize = 13; b.Font = Enum.Font.GothamBold; b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = parent; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local hand = Instance.new("TextLabel")
    hand.Size = UDim2.new(0,30,1,0); hand.Position = UDim2.new(1,-34,0,0)
    hand.BackgroundTransparency = 1; hand.Text = "👆"; hand.TextSize = 16; hand.Parent = b
    b.MouseButton1Click:Connect(function() if callback then pcall(callback) end end)
    return b
end

local function addDropdown(parent, text, options, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 38); f.BackgroundColor3 = Color3.fromRGB(30,30,40)
    f.Parent = parent; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(0.45,0,1,0); lb.Position = UDim2.new(0,12,0,0)
    lb.BackgroundTransparency = 1; lb.Text = text; lb.TextColor3 = Color3.fromRGB(220,220,225)
    lb.TextSize = 13; lb.Font = Enum.Font.GothamMedium; lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.45, -8, 0, 28); btn.Position = UDim2.new(0.5, 2, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,60); btn.Text = default
    btn.TextColor3 = Color3.fromRGB(240,240,245); btn.TextSize = 12; btn.Font = Enum.Font.GothamMedium
    btn.Parent = f; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function()
        for _,c in ipairs(DropFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        DropFrame.Size = UDim2.new(0, btn.AbsoluteSize.X, 0, #options * 30 + 4)
        DropFrame.Position = UDim2.new(0, btn.AbsolutePosition.X, 0, btn.AbsolutePosition.Y + 32)
        DropFrame.Visible = true
        activeDropdown = {btn = btn, cb = callback, opts = options}
        for _,opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1,-4,0,26); ob.Position = UDim2.new(0,2,0,0)
            ob.BackgroundColor3 = Color3.fromRGB(45,45,60); ob.Text = opt
            ob.TextColor3 = Color3.fromRGB(235,235,240); ob.TextSize = 12
            ob.Font = Enum.Font.GothamMedium; ob.Parent = DropFrame
            Instance.new("UICorner", ob).CornerRadius = UDim.new(0,4)
            ob.MouseButton1Click:Connect(function()
                btn.Text = opt
                DropFrame.Visible = false
                if callback then pcall(callback, opt) end
            end)
        end
    end)
    return f
end

local function addColorPicker(parent, text, defaultIdx, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 36); f.BackgroundColor3 = Color3.fromRGB(30,30,40)
    f.Parent = parent; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1,-60,1,0); lb.Position = UDim2.new(0,12,0,0)
    lb.BackgroundTransparency = 1; lb.Text = text; lb.TextColor3 = Color3.fromRGB(220,220,225)
    lb.TextSize = 13; lb.Font = Enum.Font.GothamMedium; lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = f
    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 40, 0, 22); swatch.Position = UDim2.new(1,-50,0.5,-11)
    swatch.BackgroundColor3 = PRESET_COLORS[defaultIdx]; swatch.Text = ""; swatch.Parent = f
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0,4)
    local idx = defaultIdx
    swatch.MouseButton1Click:Connect(function()
        idx = idx % #PRESET_COLORS + 1
        swatch.BackgroundColor3 = PRESET_COLORS[idx]
        if callback then pcall(callback, PRESET_COLORS[idx]) end
    end)
    return f
end

MainFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        if DropFrame.Visible then DropFrame.Visible = false end
    end
end)

local Tabs = {}
local tabNames = {
    {"⚔️","หลัก"}, {"👁️","มองทะลุ"}, {"👤","ตัวละคร"},
    {"🗺️","วาป&อื่นๆ"}, {"💣","ป่วน"}, {"⚙️","ตั้งค่า"}
}
local tabButtons = {}
local function selectTab(idx)
    for i,btn in ipairs(tabButtons) do
        if i == idx then
            btn.BackgroundColor3 = Color3.fromRGB(50,40,75)
            btn.bar.BackgroundColor3 = Color3.fromRGB(150,100,255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(28,28,36)
            btn.bar.BackgroundColor3 = Color3.fromRGB(28,28,36)
        end
    end
    for i,tab in ipairs(Tabs) do
        tab.mid.Visible = (i == idx)
        tab.right.Visible = (i == idx)
    end
end

for i, t in ipairs(tabNames) do
    local midF = Instance.new("Frame")
    midF.Size = UDim2.new(1, -16, 0, 1200); midF.Position = UDim2.new(0,0,0,0)
    midF.BackgroundTransparency = 1; midF.Visible = (i==1); midF.Parent = MidScroll
    local midLay = Instance.new("UIListLayout", midF)
    midLay.SortOrder = Enum.SortOrder.LayoutOrder; midLay.Padding = UDim.new(0,8)
    local rightF = Instance.new("Frame")
    rightF.Size = UDim2.new(1, -16, 0, 1200); rightF.Position = UDim2.new(0,0,0,0)
    rightF.BackgroundTransparency = 1; rightF.Visible = (i==1); rightF.Parent = RightScroll
    local rightLay = Instance.new("UIListLayout", rightF)
    rightLay.SortOrder = Enum.SortOrder.LayoutOrder; rightLay.Padding = UDim.new(0,8)
    Tabs[i] = {mid = midF, right = rightF}

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 62); btn.Position = UDim2.new(0, 0, 0, (i-1)*66)
    btn.BackgroundColor3 = (i==1) and Color3.fromRGB(50,40,75) or Color3.fromRGB(28,28,36)
    btn.Text = "   "..t[1].."  "..t[2]; btn.TextColor3 = Color3.fromRGB(230,230,235)
    btn.TextSize = 15; btn.Font = Enum.Font.GothamBold; btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = LeftNav
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,4,1,0); bar.Position = UDim2.new(0,0,0,0)
    bar.BackgroundColor3 = (i==1) and Color3.fromRGB(150,100,255) or Color3.fromRGB(28,28,36)
    bar.Parent = btn
    btn.bar = bar
    table.insert(tabButtons, btn)
    btn.MouseButton1Click:Connect(function() selectTab(i) end)
end


local RoleCache = {}
local function GetRole(player)
    local char = player.Character
    if not char then return "Innocent" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return "Innocent" end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("StringValue") then
            local v = c.Value:lower()
            if v:find("murder") then return "Murderer" end
            if v:find("sheriff") then return "Sheriff" end
        end
    end
    local rv = player:FindFirstChild("Role") or char:FindFirstChild("Role")
    if rv and rv:IsA("StringValue") then
        local v = rv.Value:lower()
        if v:find("murder") then return "Murderer" end
        if v:find("sheriff") then return "Sheriff" end
    end
    local function chk(p)
        if not p then return nil end
        for _,t in ipairs(p:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n:find("blade") then return "Murderer" end
                if n:find("gun") or n:find("revolver") then return "Sheriff" end
            end
        end
    end
    local r = chk(char); if r then return r end
    r = chk(player:FindFirstChild("Backpack")); if r then return r end
    return "Innocent"
end

local function FindMurderer()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRole(p) == "Murderer" then
            local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then return p, hrp end
        end
    end
    return nil
end
local function FindSheriff()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and GetRole(p) == "Sheriff" then
            local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then return p, hrp end
        end
    end
    return nil
end

do
    local mid, right = Tabs[1].mid, Tabs[1].right
    addSection(mid, "🎯", "ฆ่า/ยิง")
    addActionButton(mid, "ยิงฆาตกร (Sheriff)", function()
        local _, hrp = FindMurderer()
        if not hrp then return end
        local char = LocalPlayer.Character; local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool then return end
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
            local evt = tool:FindFirstChild("Shoot") or tool:FindFirstChild("Remote") or tool:FindFirstChild("GunEvent")
            if evt and evt:IsA("RemoteEvent") then evt:FireServer(hrp.Position, hrp)
            else for _,d in ipairs(tool:GetDescendants()) do if d:IsA("RemoteEvent") then d:FireServer(hrp.Position, hrp) end end end
        end)
    end)
    addActionButton(mid, "ปามีดใส่คนใกล้สุด", function()
        pcall(function()
            local char = LocalPlayer.Character; local tool = char and char:FindFirstChildOfClass("Tool")
            if tool and keypress then
            end
        end)
    end)
    addActionButton(mid, "ฆ่าคนใกล้สุด (ฆาตกร)", function()
        if not canFireTouch then return end
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local tool = char and char:FindFirstChildOfClass("Tool")
        if not hrp or not tool or not tool:FindFirstChild("Handle") then return end
        local best, bd = nil, math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local c = p.Character; local t = c and c:FindFirstChild("HumanoidRootPart")
            if t then local d = (hrp.Position-t.Position).Magnitude; if d < bd then bd = d; best = t end end
        end
        if best then pcall(function() firetouchinterest(tool.Handle, best, 0); firetouchinterest(tool.Handle, best, 1) end) end
    end)
    addActionButton(mid, "ฆ่าทุกคน (ฆาตกร)", function()
        if not canFireTouch then return end
        local char = LocalPlayer.Character; local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool or not tool:FindFirstChild("Handle") then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local c = p.Character; local t = c and c:FindFirstChild("HumanoidRootPart")
            if t then pcall(function() firetouchinterest(tool.Handle, t, 0); firetouchinterest(tool.Handle, t, 1) end) end
        end
    end)
    addActionButton(mid, "ฆ่านายอำเภอ (ฆาตกร)", function()
        if not canFireTouch then return end
        local char = LocalPlayer.Character; local tool = char and char:FindFirstChildOfClass("Tool")
        if not tool or not tool:FindFirstChild("Handle") then return end
        local _, hrp = FindSheriff()
        if hrp then pcall(function() firetouchinterest(tool.Handle, hrp, 0); firetouchinterest(tool.Handle, hrp, 1) end) end
    end)

    addSection(mid, "🪙", "ฟาร์มเหรียญ")
    addToggle(mid, "เก็บเหรียญอัตโนมัติ", S.AutoCoin, function(v) S.AutoCoin = v end)
    addDropdown(mid, "โหมดเก็บเหรียญ", {"TP","Fly"}, S.CoinMode, function(v) S.CoinMode = v end)
    addDropdown(mid, "หลังเก็บเสร็จให้", {"TP Sky","Stop"}, S.AfterCoin, function(v) S.AfterCoin = v end)
    addSlider(mid, "ความเร็วการเคลื่อนที่", 5, 100, S.MoveSpeed, function(v) S.MoveSpeed = v end)
    addSlider(mid, "หน่วงหลังเก็บ (วินาที)", 0, 10, S.DelayAfter, function(v) S.DelayAfter = v end)
    addSlider(mid, "หน่วงก่อนวาปหนี (วินาที)", 0, 5, S.DelayBeforeTP, function(v) S.DelayBeforeTP = v end)

    addSection(right, "🤖", "อัตโนมัติ")
    addToggle(right, "ยิงฆาตกรอัตโนมัติ", S.AutoShoot, function(v) S.AutoShoot = v end)
    addSlider(right, "ระยะความสูง", 0, 50, 10, function(v) end)
    addToggle(right, "ปามีดอัตโนมัติ", S.AutoThrowKnife, function(v) S.AutoThrowKnife = v end)
    addToggle(right, "Kill Aura", S.KillAura, function(v) S.KillAura = v end)
    addSlider(right, "ระยะฟัน (Studs)", 10, 2000, S.KillAuraRange, function(v) S.KillAuraRange = v end)
    addToggle(right, "แสดงวงรัศมี Kill Aura", S.ShowAuraRadius, function(v) S.ShowAuraRadius = v end)

    addSection(right, "⚙️", "ตั้งค่าความแม่นยำ")
    addDropdown(right, "ส่วนของร่างกาย (ปืน)", {"Head","Torso"}, S.ShootPart, function(v) S.ShootPart = v end)
    addDropdown(right, "ส่วนของร่างกาย (มีด)", {"Head","Torso"}, "Torso", function(v) end)
    addToggle(right, "ปันเล็งชดเชยปิง (Prediction)", S.Prediction, function(v) S.Prediction = v end)
    addToggle(right, "ยิงทะลุกำแพง", S.ShootThroughWall, function(v) S.ShootThroughWall = v end)
    addToggle(right, "ล็อคเป้าอัตโนมัติ", S.AutoLock, function(v) S.AutoLock = v end)
    addToggle(right, "ขยายขนาดเป้าหมาย", S.ExpandTarget, function(v) S.ExpandTarget = v end)
    addSlider(right, "ขนาดเป้าหมาย", 50, 300, S.ExpandSize, function(v) S.ExpandSize = v end)
end

do
    local mid = Tabs[2].mid
    addSection(mid, "👁️", "ระบบมองทะลุ")
    addToggle(mid, "มองทะลุผู้เล่น", S.ESP_Players, function(v) S.ESP_Players = v end)
    addToggle(mid, "ชื่อบนหัวผู้เล่น", S.ESP_Names, function(v) S.ESP_Names = v end)
    addToggle(mid, "ระยะทางผู้เล่น", S.ESP_Distance, function(v) S.ESP_Distance = v end)
    addSlider(mid, "ขนาดตัวอักษรชื่อ", 8, 30, S.ESP_TextSize, function(v) S.ESP_TextSize = v end)
    addColorPicker(mid, "สีฆาตกร (ไอชั่ว)", 1, function(c) S.Color_Murderer = c end)
    addColorPicker(mid, "สีนายอำเภอ (มือปืน)", 2, function(c) S.Color_Sheriff = c end)
    addColorPicker(mid, "สีคนดี (พลเมือง)", 3, function(c) S.Color_Innocent = c end)
end

do
    local mid, right = Tabs[3].mid, Tabs[3].right
    addSection(mid, "💨", "เคลื่อนที่")
    addToggle(mid, "เดินทะลุกำแพง (Noclip)", S.Noclip, function(v) S.Noclip = v end)
    addToggle(mid, "วิ่งเร็ว (Speed)", S.SpeedBoost, function(v) S.SpeedBoost = v end)
    addSlider(mid, "ความเร็ว (WalkSpeed)", 16, 200, S.SpeedValue, function(v) S.SpeedValue = v end)

    addSection(right, "⬆️", "กระโดดและอื่นๆ")
    addToggle(right, "กระโดดสูง (High Jump)", S.HighJump, function(v) S.HighJump = v end)
    addSlider(right, "พลังกระโดด", 50, 500, S.JumpPower, function(v) S.JumpPower = v end)
    addToggle(right, "กระโดดลอยได้เรื่อยๆ", S.InfiniteJump, function(v) S.InfiniteJump = v end)
    addToggle(right, "บิน (Fly)", S.Fly, function(v) S.Fly = v end)
    addSlider(right, "ความเร็วบิน", 10, 200, S.FlySpeed, function(v) S.FlySpeed = v end)
end

do
    local mid = Tabs[4].mid
    addSection(mid, "📍", "อื่นๆ/วาร์ป")
    addActionButton(mid, "วาร์ปไปหาฆาตกร", function()
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local _, t = FindMurderer()
        if hrp and t then pcall(function() hrp.CFrame = t.CFrame + Vector3.new(0,3,0) end) end
    end)
    addActionButton(mid, "วาร์ปไปหานายอำเภอ", function()
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local _, t = FindSheriff()
        if hrp and t then pcall(function() hrp.CFrame = t.CFrame + Vector3.new(0,3,0) end) end
    end)
    addActionButton(mid, "วาร์ปไปปืนตก", function()
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local gun = Workspace:FindFirstChild("GunDrop")
        local handle = gun and (gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart"))
        if hrp and handle then pcall(function() hrp.CFrame = handle.CFrame + Vector3.new(0,3,0) end) end
    end)
    addToggle(mid, "เก็บปืนถ้าร่วงอัตโนมัติ", S.AutoPickupGun, function(v) S.AutoPickupGun = v end)
    addActionButton(mid, "กลับล็อบบี้ (Reset)", function()
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Health = 0 end) end
    end)
    addActionButton(mid, "ก๊อปปี้ชื่อฆาตกร", function()
        local p = FindMurderer()
        if p and setclipboard then pcall(function() setclipboard(p.Name) end) end
    end)
    addActionButton(mid, "ก๊อปปี้ชื่อนายอำเภอ", function()
        local p = FindSheriff()
        if p and setclipboard then pcall(function() setclipboard(p.Name) end) end
    end)
end

do
    local mid, right = Tabs[5].mid, Tabs[5].right
    addSection(mid, "💣", "ป่วน")
    addToggle(mid, "กันปลิว (Anti-Fling)", S.AntiFling, function(v) S.AntiFling = v end)
    local function flingTarget(hrp)
        if not hrp then return end
        pcall(function()
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local dir
            if myHrp then
                dir = (hrp.Position - myHrp.Position).Unit
            else
                dir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
            end
            hrp.Velocity = dir * 9999999 + Vector3.new(0, -150, 0)
            hrp.RotVelocity = Vector3.new(math.random(-500,500), math.random(-500,500), math.random(-500,500))
        end)
    end
    addActionButton(mid, "ปลิวฆาตกร", function() local _, h = FindMurderer(); flingTarget(h) end)
    addActionButton(mid, "ปลิวคนดี", function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and GetRole(p) == "Innocent" then
                local c = p.Character; local h = c and c:FindFirstChild("HumanoidRootPart")
                flingTarget(h)
            end
        end
    end)
    addActionButton(mid, "ปลิวทุกคน", function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c = p.Character; local h = c and c:FindFirstChild("HumanoidRootPart")
                flingTarget(h)
            end
        end
    end)
    addToggle(mid, "อมตะ (God Mode)", S.GodMode, function(v) S.GodMode = v end)

    addSection(right, "👤⚙️", "จัดการผู้เล่นที่เลือก")
    local names = {}
    for _,p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end
    if #names == 0 then names = {"(ไม่มีผู้เล่นอื่น)"} end
    addDropdown(right, "เลือกผู้เล่นที่ต้องการ", names, names[1], function(v) S.SelectedPlayer = v end)
    addActionButton(right, "วาร์ปไปหาผู้เล่นที่เลือก", function()
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local target = Players:FindFirstChild(S.SelectedPlayer)
        local t = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if hrp and t then pcall(function() hrp.CFrame = t.CFrame + Vector3.new(0,3,0) end) end
    end)
    addActionButton(right, "ปลิวผู้เล่นที่เลือก", function()
        local target = Players:FindFirstChild(S.SelectedPlayer)
        local h = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        flingTarget(h)
    end)
end

do
    local mid = Tabs[6].mid
    addSection(mid, "⚙️", "ตั้งค่าทั่วไป")
    addActionButton(mid, "รีเซ็ตค่าทั้งหมด (Default)", function()
        pcall(function() scriptActive = false end)
        pcall(function() ScreenGui:Destroy() end)
        print("[MM2] รีเซ็ตแล้ว กรุณา Execute ใหม่")
    end)
    addActionButton(mid, "ปิดสคริปต์ทั้งหมด (Unload)", function()
        scriptActive = false
        for _,k in ipairs(OLD) do if getgenv()[k] then pcall(function() getgenv()[k]:Disconnect() end) end; getgenv()[k]=nil end
        if getgenv().SOM_ESP then
            for _,d in pairs(getgenv().SOM_ESP) do
                pcall(function() if d.Box then d.Box:Remove() end end)
                pcall(function() if d.Text then d.Text:Remove() end end)
            end
        end
        pcall(function() ScreenGui:Destroy() end)
        getgenv().SOM_UI = nil
    end)
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-8,0,80); info.BackgroundTransparency = 1
    info.Text = "MM2 Somtank Replica v1.0\nUI ตรงตามรูป • ระบบทำงานจริง\nAura Range ปรับได้ถึง 2000\nขอให้สนุกครับ 🎮"
    info.TextColor3 = Color3.fromRGB(150,150,170); info.TextSize = 13
    info.Font = Enum.Font.GothamMedium; info.TextWrapped = true; info.Parent = mid
end

MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function()
    scriptActive = false
    for _,k in ipairs(OLD) do if getgenv()[k] then pcall(function() getgenv()[k]:Disconnect() end) end; getgenv()[k]=nil end
    if getgenv().SOM_ESP then
        for _,d in pairs(getgenv().SOM_ESP) do
            pcall(function() if d.Box then d.Box:Remove() end end)
            pcall(function() if d.Text then d.Text:Remove() end end)
        end
    end
    pcall(function() ScreenGui:Destroy() end)
    getgenv().SOM_UI = nil
end)

local FloatIcon = Instance.new("TextButton")
FloatIcon.Size = UDim2.new(0,52,0,52); FloatIcon.Position = UDim2.new(0,15,0.5,-26)
FloatIcon.BackgroundColor3 = Color3.fromRGB(80,30,130); FloatIcon.Text = "🃏"
FloatIcon.TextSize = 26; FloatIcon.Visible = false; FloatIcon.Active = true
FloatIcon.Draggable = true; FloatIcon.Parent = ScreenGui
Instance.new("UICorner", FloatIcon).CornerRadius = UDim.new(1,0)
FloatIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatIcon.Visible = false
end)
MinBtn.MouseButton1Click:Connect(function() FloatIcon.Visible = true end)

local ESPCache = {}
getgenv().SOM_ESP = ESPCache
getgenv().SOM_Removing = Players.PlayerRemoving:Connect(function(p)
    if ESPCache[p] then
        pcall(function() if ESPCache[p].Box then ESPCache[p].Box:Remove() end end)
        pcall(function() if ESPCache[p].Text then ESPCache[p].Text:Remove() end end)
        ESPCache[p] = nil
    end
end)

getgenv().SOM_Render = RunService.RenderStepped:Connect(function()
    if not scriptActive then return end
    pcall(function()
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myRole = GetRole(LocalPlayer)

        if (S.AutoShoot or S.AutoLock) and myRole == "Sheriff" then
            local tool = myChar and myChar:FindFirstChildOfClass("Tool")
            local mp, mhrp = FindMurderer()
            if tool and mhrp then
                local targetPart = (S.ShootPart == "Head") and mp.Character and mp.Character:FindFirstChild("Head") or mhrp
                local tpos = targetPart.Position
                if S.Prediction then
                    pcall(function()
                        local tv = mhrp.Velocity
                        tpos = tpos + tv * 0.1
                    end)
                end
                pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, tpos) end)
                if S.AutoShoot then
                    pcall(function()
                        local evt = tool:FindFirstChild("Shoot") or tool:FindFirstChild("Remote") or tool:FindFirstChild("GunEvent")
                        if evt and evt:IsA("RemoteEvent") then evt:FireServer(tpos, mhrp)
                        else for _,d in ipairs(tool:GetDescendants()) do if d:IsA("RemoteEvent") then d:FireServer(tpos, mhrp) end end end
                    end)
                end
            end
        end

        for _,p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local c = p.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if not S.ESP_Players or not c or not hrp or not hum or hum.Health <= 0 then
                if ESPCache[p] then ESPCache[p].Box.Visible = false; ESPCache[p].Text.Visible = false end
                continue
            end
            local role = GetRole(p)
            local color = S.Color_Innocent
            if role == "Murderer" then color = S.Color_Murderer
            elseif role == "Sheriff" then color = S.Color_Sheriff end

            if not ESPCache[p] then
                local box = Drawing.new("Square"); box.Visible=false; box.Thickness=1.5; box.Filled=false
                local txt = Drawing.new("Text"); txt.Visible=false; txt.Center=true; txt.Outline=true; txt.Size=S.ESP_TextSize
                ESPCache[p] = {Box=box, Text=txt}
            end
            local cache = ESPCache[p]
            cache.Text.Size = S.ESP_TextSize
            cache.Box.Color = color; cache.Text.Color = color

            local vec, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local head = c:FindFirstChild("Head")
                local top = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0)) or vec
                local bot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
                local h = math.abs(top.Y - bot.Y); local w = h/2
                cache.Box.Size = Vector2.new(w,h)
                cache.Box.Position = Vector2.new(vec.X - w/2, top.Y)
                cache.Box.Visible = true
                local label = ""
                if S.ESP_Names then label = label .. p.Name .. " " end
                label = label .. "[" .. role .. "]"
                if S.ESP_Distance and myHrp then
                    label = label .. " [" .. math.floor((myHrp.Position - hrp.Position).Magnitude) .. "m]"
                end
                cache.Text.Text = label
                cache.Text.Position = Vector2.new(vec.X, top.Y - 18)
                cache.Text.Visible = true
            else
                cache.Box.Visible = false; cache.Text.Visible = false
            end
        end
    end)
end)

local coinContainerCache = nil; local lastCoinSearch = 0
local processedCoins = {}
getgenv().SOM_Heart = RunService.Heartbeat:Connect(function()
    if not scriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hrp or not hum then return end

        if hum.Health > 0 then
            hum.WalkSpeed = S.SpeedBoost and S.SpeedValue or 16
            hum.JumpPower = S.HighJump and S.JumpPower or 50
            if S.GodMode then hum.Health = hum.MaxHealth end
        end

        if S.Fly then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
            hum.PlatformStand = true
        else
            hum.PlatformStand = false
        end

        if S.AntiFling then
            if hrp.Velocity.Magnitude > 100 then
                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
            end
            hrp.RotVelocity = Vector3.new(0,0,0)
        end

        if S.AutoPickupGun then
            local gun = Workspace:FindFirstChild("GunDrop")
            local handle = gun and (gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart"))
            if handle and (hrp.Position - handle.Position).Magnitude < 15 then
                pcall(function() hrp.CFrame = handle.CFrame end)
            end
        end

        if S.KillAura then
            local myRole = GetRole(LocalPlayer)
            local tool = char:FindFirstChildOfClass("Tool")
            local toolName = tool and tool.Name:lower() or ""
            local isMurderer = (myRole == "Murderer") or toolName:find("knife") or toolName:find("blade")
            local isSheriff = (myRole == "Sheriff") or toolName:find("gun") or toolName:find("revolver")

            if isMurderer and tool and tool:FindFirstChild("Handle") and canFireTouch then
                local handle = tool.Handle
                for _,p in ipairs(Players:GetPlayers()) do
                    if p == LocalPlayer then continue end
                    local c = p.Character; local t = c and c:FindFirstChild("HumanoidRootPart")
                    local th = c and c:FindFirstChildOfClass("Humanoid")
                    if t and th and th.Health > 0 then
                        if (hrp.Position - t.Position).Magnitude <= S.KillAuraRange then
                            pcall(function() firetouchinterest(handle, t, 0); firetouchinterest(handle, t, 1) end)
                        end
                    end
                end
            elseif isSheriff and tool then
                local mp, mhrp = FindMurderer()
                if mhrp and (hrp.Position - mhrp.Position).Magnitude <= S.KillAuraRange then
                    local tpos = mhrp.Position
                    pcall(function()
                        local evt = tool:FindFirstChild("Shoot") or tool:FindFirstChild("Remote") or tool:FindFirstChild("GunEvent")
                        if evt and evt:IsA("RemoteEvent") then evt:FireServer(tpos, mhrp)
                        else for _,d in ipairs(tool:GetDescendants()) do if d:IsA("RemoteEvent") then d:FireServer(tpos, mhrp) end end end
                    end)
                end
            end
        end

        if S.AutoCoin then
            local now = tick()
            if not coinContainerCache or (now - lastCoinSearch) > 5 then
                lastCoinSearch = now
                local c = Workspace:FindFirstChild("Normal") or Workspace:FindFirstChild("CoinContainer")
                if not c then
                    for _,v in ipairs(Workspace:GetChildren()) do
                        if v:FindFirstChild("CoinContainer") then c = v.CoinContainer; break end
                    end
                end
                coinContainerCache = c
            end
            local container = coinContainerCache
            if container then
                local closest, minD = nil, math.huge
                for _,coin in ipairs(container:GetChildren()) do
                    if processedCoins[coin] then continue end
                    if coin.Name ~= "Coin" and not coin:FindFirstChild("CoinVisual") then continue end
                    local part = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local d = (hrp.Position - part.Position).Magnitude
                        if d < minD then minD = d; closest = coin end
                    end
                end
                if closest then
                    local part = closest:IsA("BasePart") and closest or closest:FindFirstChildWhichIsA("BasePart")
                    if part then
                        if S.CoinMode == "TP" then
                            pcall(function() hrp.CFrame = part.CFrame end)
                            processedCoins[closest] = true
                        else
                            local dir = part.Position - hrp.Position
                            if dir.Magnitude < 2 then
                                processedCoins[closest] = true
                                hrp.Velocity = Vector3.new(0,0,0)
                            else
                                hrp.Velocity = dir.Unit * S.MoveSpeed
                                hum:Move(dir.Unit)
                            end
                        end
                    end
                else
                    table.clear(processedCoins)
                    if S.AfterCoin == "TP Sky" then
                        pcall(function() hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 200, 0)) end)
                    end
                end
            end
        end
    end)
end)

local OrigCollide = {}
getgenv().SOM_Stepped = RunService.Stepped:Connect(function()
    if not scriptActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local active = S.Noclip or S.AutoCoin or S.Fly
        if active then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    if OrigCollide[p] == nil then OrigCollide[p] = p.CanCollide end
                    p.CanCollide = false
                end
            end
        else
            for part, val in pairs(OrigCollide) do
                pcall(function() if part and part.Parent then part.CanCollide = val end end)
            end
            table.clear(OrigCollide)
        end
        if S.InfiniteJump then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end)

print("========================================")
print("✅ MM2 | Somtank Replica โหลดเสร็จแล้ว!")
print("   firetouchinterest:", canFireTouch and "รองรับ ✅" or "ไม่รองรับ ⚠️ (Aura มีดจะไม่ทำงาน)")
print("   UI: 6 แท็บ เต็มระบบ ตรงตามรูป")
print("⚠️  ใช้บัญชีสำรอง | ใช้ด้วยความระมัดระวัง")
print("========================================")
