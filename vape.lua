local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")
local rightHand = character:WaitForChild("RightHand")

if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
    warn("Требуется R15 персонаж!")
    return
end

-- НАСТРОЙКИ СКОРОСТИ АНИМАЦИИ
local ARM_DURATION = 0.6    -- Time to move arm up or down
local HOLD_DURATION = 0.5   -- Time to hold vape at mouth
local SMOKE_DURATION = 3    -- Duration of smoke emission
local FADE_TIME = 0.8       -- Time to fade smoke in/out
local isAnimating = false
local isScriptActive = true

local upperArm = character:WaitForChild("RightUpperArm")
local lowerArm = character:WaitForChild("RightLowerArm")
local neck = head:FindFirstChildWhichIsA("Motor6D")

local shoulder = upperArm:FindFirstChildWhichIsA("Motor6D")
local elbow = lowerArm:FindFirstChildWhichIsA("Motor6D")

local originalShoulderC0 = shoulder.C0
local originalElbowC0 = elbow.C0
local originalNeckC0 = neck.C0

local function lerp(a, b, t)
    return a + (b - a) * math.clamp(t, 0, 1)
end

-- Создание улучшенного GUI
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "VapeGUI"
    gui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 100)
    frame.Position = UDim2.new(0.5, -90, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Добавляем градиент
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- Тень
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Vape Control"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextStrokeTransparency = 0.8
    title.Parent = frame
    
    local smokeButton = Instance.new("TextButton")
    smokeButton.Size = UDim2.new(0, 140, 0, 45)
    smokeButton.Position = UDim2.new(0.5, -70, 0, 45)
    smokeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    smokeButton.BorderSizePixel = 0
    smokeButton.Text = "Курить"
    smokeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    smokeButton.Font = Enum.Font.GothamBold
    smokeButton.TextSize = 20
    smokeButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = smokeButton
    
    -- Градиент для кнопки
    local buttonGradient = Instance.new("UIGradient")
    buttonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 140, 220))
    })
    buttonGradient.Parent = smokeButton
    
    -- Эффекты при наведении
    smokeButton.MouseEnter:Connect(function()
        smokeButton:TweenSize(
            UDim2.new(0, 145, 0, 48),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
    end)
    
    smokeButton.MouseLeave:Connect(function()
        smokeButton:TweenSize(
            UDim2.new(0, 140, 0, 45),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
    end)
    
    return gui, smokeButton
end

local function createVapeModel()
    -- [Оставляем код создания вейп-модели без изменений]
    local vapeModel = Instance.new("Model")
    vapeModel.Name = "VapeModel"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.4, 1.2, 0.4)
    handle.Material = Enum.Material.Metal
    handle.Color = Color3.fromRGB(60, 60, 60)
    handle.Anchored = false
    handle.CanCollide = false
    handle.Parent = vapeModel

    local handWeld = Instance.new("WeldConstraint")
    handWeld.Part0 = rightHand
    handWeld.Part1 = handle
    handWeld.Parent = handle

    handle.CFrame = rightHand.CFrame * CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(90), math.rad(180), math.rad(180))

    local tank = Instance.new("Part")
    tank.Shape = Enum.PartType.Cylinder
    tank.Size = Vector3.new(0.3, 0.4, 0.3)
    tank.CFrame = handle.CFrame * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))
    tank.Material = Enum.Material.Glass
    tank.Color = Color3.fromRGB(150, 150, 150)
    tank.Transparency = 0.3
    tank.CanCollide = false
    tank.Parent = vapeModel

    local liquid = Instance.new("Part")
    liquid.Shape = Enum.PartType.Cylinder
    liquid.Size = Vector3.new(0.28, 0.2, 0.28)
    liquid.CFrame = handle.CFrame * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90))
    liquid.Material = Enum.Material.Neon
    liquid.Color = Color3.fromRGB(0, 255, 100)
    liquid.Transparency = 0.5
    liquid.CanCollide = false
    liquid.Parent = vapeModel

    local mouthpiece = Instance.new("Part")
    mouthpiece.Shape = Enum.PartType.Cylinder
    mouthpiece.Size = Vector3.new(0.1, 0.2, 0.1)
    mouthpiece.CFrame = handle.CFrame * CFrame.new(0, 1.0, 0) * CFrame.Angles(0, 0, math.rad(90))
    mouthpiece.Material = Enum.Material.Plastic
    mouthpiece.Color = Color3.fromRGB(20, 20, 20)
    mouthpiece.CanCollide = false
    mouthpiece.Parent = vapeModel

    local button = Instance.new("Part")
    button.Size = Vector3.new(0.08, 0.2, 0.03)
    button.CFrame = handle.CFrame * CFrame.new(0, 0.2, 0.22)
    button.Material = Enum.Material.Neon
    button.Color = Color3.fromRGB(0, 255, 255)
    button.CanCollide = false
    button.Parent = vapeModel

    local function weldParts(part0, part1)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part0
        weld.Part1 = part1
        weld.Parent = part0
    end

    weldParts(handle, tank)
    weldParts(handle, liquid)
    weldParts(handle, mouthpiece)
    weldParts(handle, button)

    vapeModel.Parent = character
    return vapeModel
end

local function createSmokeEffect()
    -- [Оставляем код создания дыма без изменений]
    local attachment = Instance.new("Attachment")
    attachment.Name = "VapeAttachment"
    attachment.Parent = head
    attachment.Position = Vector3.new(0, -0.1, -0.5)

    local smoke = Instance.new("ParticleEmitter")
    smoke.Texture = "rbxassetid://10307543540"
    smoke.LightEmission = 0.8
    smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(0.3, 1.5),
        NumberSequenceKeypoint.new(1, 2.5)
    })
    smoke.Lifetime = NumberRange.new(1.5, 2)
    smoke.Speed = NumberRange.new(5, 7)
    smoke.SpreadAngle = Vector2.new(12, 12)
    smoke.Rotation = NumberRange.new(-15, 15)
    smoke.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.3),
        NumberSequenceKeypoint.new(0.8, 0.7),
        NumberSequenceKeypoint.new(1, 1)
    })
    smoke.VelocityInheritance = 0.1
    smoke.EmissionDirection = Enum.NormalId.Front
    smoke.Drag = 1.5
    smoke.Acceleration = Vector3.new(0, 0.3, -3)
    smoke.Parent = attachment
    
    smoke.Rate = 0
    smoke.Enabled = true
    
    return smoke, attachment
end

local function fadeSmoke(smoke, targetRate, duration)
    -- [Оставляем код затухания дыма без изменений]
    local startRate = smoke.Rate
    local startTime = os.clock()
    
    while os.clock() - startTime < duration do
        local progress = lerp(0, 1, (os.clock() - startTime) / duration)
        smoke.Rate = lerp(startRate, targetRate, progress)
        RunService.Heartbeat:Wait()
    end
    smoke.Rate = targetRate
end

local function animateToMouth(vapeModel)
    -- [Оставляем код анимации без изменений]
    if not isScriptActive or isAnimating or not humanoid or humanoid.Health <= 0 then return end
    isAnimating = true
    
    local targetShoulderAngle = CFrame.Angles(math.rad(60), math.rad(65), 0)
    local targetElbowAngle = CFrame.Angles(math.rad(80), 0, 0)
    
    local startTime = os.clock()
    while os.clock() - startTime < ARM_DURATION and humanoid.Health > 0 do
        local progress = lerp(0, 1, (os.clock() - startTime) / ARM_DURATION)
        shoulder.C0 = originalShoulderC0:Lerp(originalShoulderC0 * targetShoulderAngle, progress)
        elbow.C0 = originalElbowC0:Lerp(originalElbowC0 * targetElbowAngle, progress)
        RunService.Heartbeat:Wait()
    end
    
    local holdEndTime = os.clock() + HOLD_DURATION
    while os.clock() < holdEndTime and humanoid.Health > 0 do
        RunService.Heartbeat:Wait()
    end
    
    startTime = os.clock()
    while os.clock() - startTime < ARM_DURATION and humanoid.Health > 0 do
        local progress = lerp(0, 1, (os.clock() - startTime) / ARM_DURATION)
        shoulder.C0 = (originalShoulderC0 * targetShoulderAngle):Lerp(originalShoulderC0, progress)
        elbow.C0 = (originalElbowC0 * targetElbowAngle):Lerp(originalElbowC0, progress)
        RunService.Heartbeat:Wait()
    end
    
    local smokeEffect, smokeAttachment = createSmokeEffect()
    fadeSmoke(smokeEffect, 25, FADE_TIME)
    
    local smokeStartTime = os.clock()
    local smokeEndTime = smokeStartTime + SMOKE_DURATION
    while os.clock() < smokeEndTime and humanoid.Health > 0 do
        local progress = (os.clock() - smokeStartTime) / SMOKE_DURATION
        local tiltProgress = math.sin(progress * math.pi)
        neck.C0 = originalNeckC0:Lerp(originalNeckC0 * CFrame.Angles(math.rad(15), 0, 0), tiltProgress)
        RunService.Heartbeat:Wait()
    end
    
    fadeSmoke(smokeEffect, 0, FADE_TIME)
    task.wait(FADE_TIME)
    
    smokeEffect:Destroy()
    smokeAttachment:Destroy()
    neck.C0 = originalNeckC0
    
    isAnimating = false
end

local currentVape = createVapeModel()
local gui, smokeButton = createGUI()

-- Подключение кнопки
smokeButton.MouseButton1Click:Connect(function()
    if not isAnimating and isScriptActive then
        animateToMouth(currentVape)
    end
end)

-- Очистка при смерти
humanoid.Died:Connect(function()
    if shoulder then shoulder.C0 = originalShoulderC0 end
    if elbow then elbow.C0 = originalElbowC0 end
    if neck then neck.C0 = originalNeckC0 end
    if currentVape then currentVape:Destroy() end
    if gui then gui:Destroy() end
    isAnimating = false
    isScriptActive = false
end)
