local Settings = {
    MenuKey = Enum.KeyCode.RightShift,
    CorrectKey = "alofra",
    ESP = {
        Enabled = true,
        Boxes = true,
        Names = true,
        Health = true,
        Tracers = true,
        Color = Color3.fromRGB(255, 255, 255)
    },
    Aimbot = {
        Enabled = true,
        Mode = "Legit", 
        FOV = 120,
        Smoothness = 0.2, 
        ShowFOV = true,
        TargetPart = "Head", 
        WallCheck = true
    },
    Triggerbot = {
        Enabled = false,
        Delay = 0.01 -- Микрозадержка перед автовыстрелом (в секундах)
    }
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = Settings.Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(120, 120, 120)

local ESP_Cache = {}
local Connections = {}
local PanicMode = false
local FirstKeyVerified = false
local SecondKeyVerified = false
local GeneratedDynamicKey = ""

local WordBank = {"phantom", "tactical", "ghost", "bullet", "shadow", "trigger", "reflex", "vector", "strike", "omega", "matrix", "nexus", "void", "hvh", "legit", "alofra", "external", "aim", "esp", "radar", "bypass", "glitch", "carbon", "static"}

local function GenerateRandomKey()
    math.randomseed(os.time())
    local w1 = WordBank[math.random(1, #WordBank)]
    local w2 = WordBank[math.random(1, #WordBank)]
    local w3 = WordBank[math.random(1, #WordBank)]
    return w1 .. "-" .. w2 .. "-" .. w3
end

local function IsPlayerVisible(targetPart)
    if not Settings.Aimbot.WallCheck then return true end
    local character = targetPart.Parent
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera}
    raycastParams.IgnoreWater = true
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult == nil
end

local function GetClosestPlayer(maxFov)
    local ClosestPart = nil
    local ShortestDistance = maxFov
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local targetPart = char:FindFirstChild(Settings.Aimbot.TargetPart)
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 then
                local tPos, tOnScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if tOnScreen and IsPlayerVisible(targetPart) then
                    local distance = (Vector2.new(tPos.X, tPos.Y) - centerScreen).Magnitude
                    if distance < ShortestDistance then
                        ShortestDistance = distance
                        ClosestPart = targetPart
                    end
                end
            end
        end
    end
    return ClosestPart
end

local function CreateESP(player)
    if ESP_Cache[player] or PanicMode or not SecondKeyVerified then return end
    local Box = Drawing.new("Square")
    Box.Thickness = 1
    Box.Filled = false
    local Name = Drawing.new("Text")
    Name.Size = 13
    Name.Center = true
    Name.Outline = true
    local Tracer = Drawing.new("Line")
    Tracer.Thickness = 1
    local HealthBar = Drawing.new("Line")
    HealthBar.Thickness = 2
    ESP_Cache[player] = {Box = Box, Name = Name, Tracer = Tracer, HealthBar = HealthBar}
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        for _, obj in pairs(ESP_Cache[player]) do obj:Remove() end
        ESP_Cache[player] = nil
    end
end

local function StartCheatLogic()
    table.insert(Connections, Players.PlayerAdded:Connect(CreateESP))
    table.insert(Connections, Players.PlayerRemoving:Connect(RemoveESP))
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then CreateESP(p) end
    end
end

local function HidePlayerESP(drawings)
    drawings.Box.Visible = false
    drawings.Name.Visible = false
    drawings.Tracer.Visible = false
    drawings.HealthBar.Visible = false
end

-- Логика ультра-быстрого Триггербота
local function RunTriggerbot()
    if Settings.Triggerbot.Enabled and KeyVerified and not PanicMode then
        local mouseTarget = LocalPlayer:GetMouse().Target
        if mouseTarget and mouseTarget.Parent then
            local hitCharacter = mouseTarget.Parent
            local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
            -- Если это часть тела игрока и он не мы сами, то стреляем
            if hitPlayer and hitPlayer ~= LocalPlayer then
                local humanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    task.wait(Settings.Triggerbot.Delay)
                    mouse1click() -- Эмуляция полноценного нажатия выстрела
                end
            end
        end
    end
end

local MainLoop = RunService.RenderStepped:Connect(function()
    if PanicMode or not SecondKeyVerified then return end
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Position = screenCenter
    FOVCircle.Visible = Settings.Aimbot.ShowFOV and Settings.Aimbot.Enabled
    -- Авто-синхронизация цвета круга FOV под состояние аима
    FOVCircle.Color = Settings.Aimbot.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)

    -- Потоковый вызов триггербота
    RunTriggerbot()

    for player, drawings in pairs(ESP_Cache) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local hrp = character.HumanoidRootPart
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local top, _ = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
            local bottom, _ = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
            local boxHeight = math.abs(top.Y - bottom.Y)
            local boxWidth = boxHeight / 1.8

            if onScreen and Settings.ESP.Enabled then
                if Settings.ESP.Boxes then
                    drawings.Box.Visible = true
                    drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                    drawings.Box.Position = Vector2.new(pos.X - boxWidth / 2, pos.Y - boxHeight / 2)
                    drawings.Box.Color = Settings.ESP.Color
                else drawings.Box.Visible = false end

                if Settings.ESP.Names then
                    drawings.Name.Visible = true
                    drawings.Name.Position = Vector2.new(pos.X, pos.Y - (boxHeight / 2) - 15)
                    drawings.Name.Text = player.Name
                    drawings.Name.Color = Color3.fromRGB(230, 230, 230)
                else drawings.Name.Visible = false end

                if Settings.ESP.Tracers then
                    drawings.Tracer.Visible = true
                    drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Tracer.To = Vector2.new(pos.X, pos.Y + (boxHeight / 2))
                    drawings.Tracer.Color = Settings.ESP.Color
                else drawings.Tracer.Visible = false end

                if Settings.ESP.Health then
                    drawings.HealthBar.Visible = true
                    local healthPct = humanoid.Health / humanoid.MaxHealth
                    local barHeight = boxHeight * healthPct
                    drawings.HealthBar.From = Vector2.new(pos.X - (boxWidth / 2) - 5, pos.Y + (boxHeight / 2))
                    drawings.HealthBar.To = Vector2.new(pos.X - (boxWidth / 2) - 5, pos.Y + (boxHeight / 2) - barHeight)
                    drawings.HealthBar.Color = Color3.fromRGB(healthPct < 0.5 and 255 or 255 * (1 - healthPct) * 2, healthPct >= 0.5 and 255 or 255 * healthPct * 2, 255)
                else drawings.HealthBar.Visible = false end
            else
                HidePlayerESP(drawings)
            end
        else
            HidePlayerESP(drawings)
        end
    end

    if Settings.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local Target = GetClosestPlayer(Settings.Aimbot.FOV)
        if Target then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
            if Settings.Aimbot.Mode == "HvH" then
                Camera.CFrame = targetCFrame
            else
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Aimbot.Smoothness)
            end
        end
    end
end)
table.insert(Connections, MainLoop)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")

local KeyFrame = Instance.new("Frame", ScreenGui)
KeyFrame.Size = UDim2.new(0, 260, 0, 160)
KeyFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
KeyFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 2)

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.Size = UDim2.new(1, 0, 0, 35)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "SECURITY STAGE 1"
KeyTitle.TextColor3 = Color3.fromRGB(140, 140, 140)
KeyTitle.Font = Enum.Font.Roboto
KeyTitle.TextSize = 11
local KeyInput = Instance.new("TextBox", KeyFrame)
KeyInput.Size = UDim2.new(0.85, 0, 0, 32)
KeyInput.Position = UDim2.new(0.075, 0, 0.35, 0)
KeyInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
KeyInput.Text = ""
KeyInput.PlaceholderText = "Master Key..."
KeyInput.TextColor3 = Color3.fromRGB(220, 220, 220)
KeyInput.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
KeyInput.Font = Enum.Font.Roboto
KeyInput.TextSize = 12
KeyInput.BorderSizePixel = 0
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 2)
local CheckBtn = Instance.new("TextButton", KeyFrame)
CheckBtn.Size = UDim2.new(0.85, 0, 0, 32)
CheckBtn.Position = UDim2.new(0.075, 0, 0.65, 0)
CheckBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
CheckBtn.Text = "PROCEED"
CheckBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CheckBtn.Font = Enum.Font.Roboto
CheckBtn.TextSize = 12
CheckBtn.BorderSizePixel = 0
Instance.new("UICorner", CheckBtn).CornerRadius = UDim.new(0, 2)
local KeyFrame2 = Instance.new("Frame", ScreenGui)
KeyFrame2.Size = UDim2.new(0, 280, 0, 190)
KeyFrame2.Position = UDim2.new(0.4, 0, 0.4, 0)
KeyFrame2.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
KeyFrame2.BorderSizePixel = 0
KeyFrame2.Active = true
KeyFrame2.Draggable = true
KeyFrame2.Visible = false
KeyFrame2.BackgroundTransparency = 1
Instance.new("UICorner", KeyFrame2).CornerRadius = UDim.new(0, 2)
local KeyTitle2 = Instance.new("TextLabel", KeyFrame2)
KeyTitle2.Size = UDim2.new(1, 0, 0, 30)
KeyTitle2.BackgroundTransparency = 1
KeyTitle2.Text = "DYNAMIC VERIFICATION"
KeyTitle2.TextColor3 = Color3.fromRGB(140, 140, 140)
KeyTitle2.Font = Enum.Font.Roboto
KeyTitle2.TextSize = 11
local GeneratorLabel = Instance.new("TextBox", KeyFrame2)
GeneratorLabel.Size = UDim2.new(0.85, 0, 0, 30)
GeneratorLabel.Position = UDim2.new(0.075, 0, 0.2, 0)
GeneratorLabel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
GeneratorLabel.Text = ""
GeneratorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
GeneratorLabel.Font = Enum.Font.Roboto
GeneratorLabel.TextSize = 12
GeneratorLabel.ClearTextOnFocus = false
GeneratorLabel.TextEditable = false
Instance.new("UICorner", GeneratorLabel).CornerRadius = UDim.new(0, 2)
local KeyInput2 = Instance.new("TextBox", KeyFrame2)
KeyInput2.Size = UDim2.new(0.85, 0, 0, 32)
KeyInput2.Position = UDim2.new(0.075, 0, 0.45, 0)
KeyInput2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
KeyInput2.Text = ""
KeyInput2.PlaceholderText = "Retype the dynamic phrase above..."
KeyInput2.TextColor3 = Color3.fromRGB(220, 220, 220)
KeyInput2.PlaceholderColor3 = Color3.fromRGB(70, 70, 70)
KeyInput2.Font = Enum.Font.Roboto
KeyInput2.TextSize = 12
KeyInput2.BorderSizePixel = 0
Instance.new("UICorner", KeyInput2).CornerRadius = UDim.new(0, 2)
local CheckBtn2 = Instance.new("TextButton", KeyFrame2)
CheckBtn2.Size = UDim2.new(0.85, 0, 0, 32)
CheckBtn2.Position = UDim2.new(0.075, 0, 0.72, 0)
CheckBtn2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CheckBtn2.Text = "UNLOCK INTERFACE"
CheckBtn2.TextColor3 = Color3.fromRGB(0, 0, 0)
CheckBtn2.Font = Enum.Font.Roboto
CheckBtn2.TextSize = 12
CheckBtn2.BorderSizePixel = 0
Instance.new("UICorner", CheckBtn2).CornerRadius = UDim.new(0, 2)
-- ОБНОВЛЕННЫЙ HUD ALOFRA EXPENSIVE
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 580)
MainFrame.Position = UDim2.new(-0.3, 0, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.BackgroundTransparency = 1
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 2)
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0.06, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "alofra expensive" -- Новое название
Title.TextColor3 = Color3.fromRGB(160, 160, 160)
Title.Font = Enum.Font.Roboto
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
local AuthorLabel = Instance.new("TextLabel", Header)
AuthorLabel.Size = UDim2.new(0.2, 0, 1, 0)
AuthorLabel.Position = UDim2.new(0.74, 0, 0, 0)
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Text = "by alofra"
AuthorLabel.TextColor3 = Color3.fromRGB(90, 90, 90)
AuthorLabel.Font = Enum.Font.Roboto
AuthorLabel.TextSize = 11
AuthorLabel.TextXAlignment = Enum.TextXAlignment.Right
local function CreateCategoryLabel(text, y)
local Lbl = Instance.new("TextLabel", MainFrame)
Lbl.Size = UDim2.new(0.88, 0, 0, 20)
Lbl.Position = UDim2.new(0.06, 0, 0, y)
Lbl.BackgroundTransparency = 1
Lbl.Text = "[ " .. string.upper(text) .. " ]"
Lbl.TextColor3 = Color3.fromRGB(70, 70, 70)
Lbl.Font = Enum.Font.Roboto
Lbl.TextSize = 10
Lbl.TextXAlignment = Enum.TextXAlignment.Left
end
local function CreateiOSToggle(text, y, cfg, key)
local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(0.88, 0, 0, 32)
Container.Position = UDim2.new(0.06, 0, 0, y)
Container.BackgroundTransparency = 1
local Label = Instance.new("TextLabel", Container)
Label.Size = UDim2.new(0.7, 0, 1, 0)
Label.BackgroundTransparency = 1
Label.Text = text
Label.TextColor3 = Color3.fromRGB(150, 150, 150)
Label.Font = Enum.Font.Roboto
Label.TextSize = 13
Label.TextXAlignment = Enum.TextXAlignment.Left
local Switch = Instance.new("TextButton", Container)
Switch.Size = UDim2.new(0, 36, 0, 20)
Switch.Position = UDim2.new(1, -36, 0.5, -10)
Switch.BackgroundColor3 = cfg[key] and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(35, 35, 35)
Switch.Text = ""
Switch.BorderSizePixel = 0
Instance.new("UICorner", Switch).CornerRadius = UDim.new(0, 10)
local SliderCircle = Instance.new("Frame", Switch)
SliderCircle.Size = UDim2.new(0, 14, 0, 14)
SliderCircle.Position = cfg[key] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
SliderCircle.BackgroundColor3 = cfg[key] and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(180, 180, 180)
SliderCircle.BorderSizePixel = 0
Instance.new("UICorner", SliderCircle).CornerRadius = UDim.new(0, 7)
Switch.MouseButton1Click:Connect(function()
if PanicMode or not SecondKeyVerified then return end
cfg[key] = not cfg[key]
local targetSwitchBg = cfg[key] and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(35, 35, 35)
local targetCircleBg = cfg[key] and Color3.fromRGB(15, 15, 15) or Color3.fromRGB(180, 180, 180)
local targetCirclePos = cfg[key] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
local targetLabelColor = cfg[key] and Color3.fromRGB(245, 245, 245) or Color3.fromRGB(150, 150, 150)
TweenService:Create(Switch, TweenInfo.new(0.25, Enum.EasingStyle.Cubic), {BackgroundColor3 = targetSwitchBg}):Play()
TweenService:Create(SliderCircle, TweenInfo.new(0.25, Enum.EasingStyle.Cubic), {BackgroundColor3 = targetCircleBg, Position = targetCirclePos}):Play()
TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = targetLabelColor}):Play()
end)
end
CreateCategoryLabel("Visuals", 42)
CreateiOSToggle("Enable ESP Master", 65, Settings.ESP, "Enabled")
CreateiOSToggle("2D Boxes", 95, Settings.ESP, "Boxes")
CreateiOSToggle("Player Names", 125, Settings.ESP, "Names")
CreateiOSToggle("Health Tracking", 155, Settings.ESP, "Health")
CreateiOSToggle("Snaplines", 185, Settings.ESP, "Tracers")
CreateCategoryLabel("Base Aimbot", 225)
CreateiOSToggle("Aimbot Assist (RMB)", 245, Settings.Aimbot, "Enabled")
CreateiOSToggle("Show Legit FOV Circle", 275, Settings.Aimbot, "ShowFOV")
CreateiOSToggle("Wall Check (Visibility)", 305, Settings.Aimbot, "WallCheck")
-- СЕКЦИЯ МОДЕРНИЗАЦИИ: TRIGGERBOT
CreateCategoryLabel("Combat Mechanics", 340)
CreateiOSToggle("Auto Triggerbot", 360, Settings.Triggerbot, "Enabled")
local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0.88, 0, 0, 30)
ModeBtn.Position = UDim2.new(0.06, 0, 0, 400)
ModeBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
ModeBtn.Text = "Aimbot Mode: LEGIT"
ModeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
ModeBtn.Font = Enum.Font.Roboto
ModeBtn.TextSize = 12
ModeBtn.BorderSizePixel = 0
Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 2)
ModeBtn.MouseButton1Click:Connect(function()
if Settings.Aimbot.Mode == "Legit" then
Settings.Aimbot.Mode = "HvH"
ModeBtn.Text = "Aimbot Mode: HVH (RAGE)"
else
Settings.Aimbot.Mode = "Legit"
ModeBtn.Text = "Aimbot Mode: LEGIT"
end
end)
local BoneBtn = Instance.new("TextButton", MainFrame)
BoneBtn.Size = UDim2.new(0.88, 0, 0, 30)
BoneBtn.Position = UDim2.new(0.06, 0, 0, 435)
BoneBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
BoneBtn.Text = "Target Bone: HEAD"
BoneBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
BoneBtn.Font = Enum.Font.Roboto
BoneBtn.TextSize = 12
BoneBtn.BorderSizePixel = 0
Instance.new("UICorner", BoneBtn).CornerRadius = UDim.new(0, 2)
BoneBtn.MouseButton1Click:Connect(function()
if Settings.Aimbot.TargetPart == "Head" then
Settings.Aimbot.TargetPart = "HumanoidRootPart"
BoneBtn.Text = "Target Bone: TORSO"
else
Settings.Aimbot.TargetPart = "Head"
BoneBtn.Text = "Target Bone: HEAD"
end
end)
local LegitFovLabel = Instance.new("TextLabel", MainFrame)
LegitFovLabel.Size = UDim2.new(0.88, 0, 0, 20)
LegitFovLabel.Position = UDim2.new(0.06, 0, 0, 470)
LegitFovLabel.BackgroundTransparency = 1
LegitFovLabel.Text = "Base FOV Size: " .. Settings.Aimbot.FOV
LegitFovLabel.TextColor3 = Color3.fromRGB(110, 110, 110)
LegitFovLabel.Font = Enum.Font.Roboto
LegitFovLabel.TextSize = 11
LegitFovLabel.TextXAlignment = Enum.TextXAlignment.Left
local LMBtn = Instance.new("TextButton", MainFrame)
LMBtn.Size = UDim2.new(0.42, 0, 0, 24)
LMBtn.Position = UDim2.new(0.06, 0, 0, 490)
LMBtn.Text = "-50 FOV"
LMBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
LMBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
LMBtn.Font = Enum.Font.SourceSans
LMBtn.BorderSizePixel = 0
Instance.new("UICorner", LMBtn).CornerRadius = UDim.new(0, 2)
LMBtn.MouseButton1Click:Connect(function()
Settings.Aimbot.FOV = math.max(10, Settings.Aimbot.FOV - 50)
LegitFovLabel.Text = "Base FOV Size: " .. Settings.Aimbot.FOV
end)
local LPBtn = Instance.new("TextButton", MainFrame)
LPBtn.Size = UDim2.new(0.42, 0, 0, 24)
LPBtn.Position = UDim2.new(0.52, 0, 0, 490)
LPBtn.Text = "+50 FOV"
LPBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
LPBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
LPBtn.Font = Enum.Font.SourceSans
LPBtn.BorderSizePixel = 0
Instance.new("UICorner", LPBtn).CornerRadius = UDim.new(0, 2)
LPBtn.MouseButton1Click:Connect(function()
Settings.Aimbot.FOV = math.min(800, Settings.Aimbot.FOV + 50)
LegitFovLabel.Text = "Base FOV Size: " .. Settings.Aimbot.FOV
end)
local PanicBtn = Instance.new("TextButton", MainFrame)
PanicBtn.Size = UDim2.new(0.88, 0, 0, 30)
PanicBtn.Position = UDim2.new(0.06, 0, 0, 525)
PanicBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
PanicBtn.Text = "TERMINATE SCRIPTS"
PanicBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
PanicBtn.Font = Enum.Font.Roboto
PanicBtn.TextSize = 11
PanicBtn.BorderSizePixel = 0
Instance.new("UICorner", PanicBtn).CornerRadius = UDim.new(0, 2)
-- ЦИФРОВОЕ ТАКТИЧЕСКОЕ КЛЕЙМО «454» В САМОМ КОНЦЕ МЕНЮ
local StampLabel = Instance.new("TextLabel", MainFrame)
StampLabel.Size = UDim2.new(0.88, 0, 0, 15)
StampLabel.Position = UDim2.new(0.06, 0, 1, -20)
StampLabel.BackgroundTransparency = 1
StampLabel.Text = "454"
StampLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
StampLabel.Font = Enum.Font.Roboto
StampLabel.TextSize = 10
StampLabel.TextXAlignment = Enum.TextXAlignment.Center
local PanicConfirm = false
local ConfirmTimer = 0
PanicBtn.MouseButton1Click:Connect(function()
if not PanicConfirm then
PanicConfirm = true
PanicBtn.Text = "Confirm Destruction?"
TweenService:Create(PanicBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 220, 220), TextColor3 = Color3.fromRGB(0, 0, 0)}):Play()
local currentTimer = tick()
ConfirmTimer = currentTimer
task.delay(3, function()
if ConfirmTimer == currentTimer and not PanicMode then
PanicConfirm = false
PanicBtn.Text = "TERMINATE SCRIPTS"
TweenService:Create(PanicBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 22), TextColor3 = Color3.fromRGB(130, 130, 130)}):Play()
end
end)
else
PanicMode = true
for _, conn in pairs(Connections) do if conn then conn:Disconnect() end end
for player, drawings in pairs(ESP_Cache) do
for _, obj in pairs(drawings) do obj:Remove() end
end
FOVCircle:Remove()
ScreenGui:Destroy()
end
end)
CheckBtn.MouseButton1Click:Connect(function()
if KeyInput.Text == Settings.CorrectKey then
FirstKeyVerified = true
GeneratedDynamicKey = GenerateRandomKey()
GeneratorLabel.Text = GeneratedDynamicKey
TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
task.delay(0.3, function()
KeyFrame:Destroy()
KeyFrame2.Visible = true
TweenService:Create(KeyFrame2, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
end)
else
KeyInput.Text = ""
KeyInput.PlaceholderText = "Access Denied."
end
end)
CheckBtn2.MouseButton1Click:Connect(function()
if KeyInput2.Text == GeneratedDynamicKey and FirstKeyVerified then
SecondKeyVerified = true
KeyVerified = true
TweenService:Create(KeyFrame2, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
task.delay(0.3, function()
KeyFrame2:Destroy()
MainFrame.Visible = true
TweenService:Create(MainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
Position = UDim2.new(0.05, 0, 0.15, 0)
}):Play()
StartCheatLogic()
end)
else
KeyInput2.Text = ""
KeyInput2.PlaceholderText = "Invalid Token Phrase."
end
end)
local ToggleFrameConnection = UserInputService.InputBegan:Connect(function(input, gp)
if not gp and input.KeyCode == Settings.MenuKey and not PanicMode and SecondKeyVerified then
MainFrame.Visible = not MainFrame.Visible
end
end)
table.insert(Connections, ToggleFrameConnection)
