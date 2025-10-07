local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local humanoid
local rootPart
local jumping = false
local highestSpeed = 0

local BOX_COLOR = Color3.fromRGB(120,180,255)
local BOX_THICKNESS = 2
local BOX_Y_OFFSET = -3
local BOX_PIXEL_PER_STUD = 32
local BOX_MIN_SCALE = 0.3
local BOX_MAX_SCALE = 1.2
local BOX_MIN_DIST = 14

local HEAD_CIRCLE_COLOR = Color3.fromRGB(120,180,255)
local HEAD_CIRCLE_THICKNESS = 3
local HEAD_CIRCLE_RADIUS = 18

local function removeOldSpeedGui()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local old = playerGui:FindFirstChild("SpeedDisplay")
        if old then old:Destroy() end
    end
end

local function createSpeedGui()
    removeOldSpeedGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpeedDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local maxLabel = Instance.new("TextLabel")
    maxLabel.Name = "MaxSpeedLabel"
    maxLabel.AnchorPoint = Vector2.new(0.5, 1)
    maxLabel.Position = UDim2.new(0.5, 0, 0.89, 0)
    maxLabel.Size = UDim2.new(0, 220, 0, 32)
    maxLabel.BackgroundTransparency = 1
    maxLabel.TextColor3 = Color3.new(0, 0, 0)
    maxLabel.TextStrokeTransparency = 1
    maxLabel.TextScaled = true
    maxLabel.Font = Enum.Font.SourceSansBold
    maxLabel.Text = "(0.0u/s)"
    maxLabel.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Name = "SpeedLabel"
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.new(0.5, 0, 0.93, 0)
    label.Size = UDim2.new(0, 220, 0, 40)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = "0.0u/s"
    label.Parent = screenGui

    return label, maxLabel
end

local speedLabel, maxLabel = createSpeedGui()

local function getHumanoidAndRoot()
    local character = player.Character or player.CharacterAdded:Wait()
    local hum = character:FindFirstChildOfClass("Humanoid")
    while not hum do
        character.ChildAdded:Wait()
        hum = character:FindFirstChildOfClass("Humanoid")
    end
    local rp = character:FindFirstChild("HumanoidRootPart")
    while not rp do
        character.ChildAdded:Wait()
        rp = character:FindFirstChild("HumanoidRootPart")
    end
    return hum, rp
end

RunService.RenderStepped:Connect(function()
    if not humanoid or not rootPart then return end
    local speed = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
    speedLabel.Text = string.format("%.1fu/s", speed)
    if speed > highestSpeed then
        highestSpeed = speed
        maxLabel.Text = string.format("(%.1fu/s)", highestSpeed)
    end
    if jumping then
        local vel = rootPart.AssemblyLinearVelocity
        local xzVel = Vector3.new(vel.X, 0, vel.Z)
        humanoid.Jump = true
        task.defer(function()
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                local curVel = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(xzVel.X, curVel.Y, xzVel.Z)
            end
        end)
    end
end)

userInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Space then
        humanoid, rootPart = getHumanoidAndRoot()
        jumping = true
    end
end)
userInputService.InputEnded:Connect(function(input, processed)
    if input.KeyCode == Enum.KeyCode.Space then
        jumping = false
        if humanoid then humanoid.Jump = false end
    end
end)
player.CharacterAdded:Connect(function()
    humanoid, rootPart = getHumanoidAndRoot()
end)

local function removeOldTag(character)
    local old = character:FindFirstChild("NameTag")
    if old then old:Destroy() end
end

local function removeOldHeadESP(character)
    local head = character:FindFirstChild("Head")
    if head then
        local old = head:FindFirstChild("HeadESP")
        if old then old:Destroy() end
    end
end

local function createHeadESP(character)
    local head = character:FindFirstChild("Head")
    if not head then return end
    removeOldHeadESP(character)

    local bb = Instance.new("BillboardGui")
    bb.Name = "HeadESP"
    bb.Adornee = head
    bb.Size = UDim2.new(0, HEAD_CIRCLE_RADIUS*2, 0, HEAD_CIRCLE_RADIUS*2)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Parent = head

    local circle = Instance.new("Frame")
    circle.AnchorPoint = Vector2.new(0.5,0.5)
    circle.Position = UDim2.new(0.5,0,0.5,0)
    circle.Size = UDim2.new(1,0,1,0)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = HEAD_CIRCLE_THICKNESS
    circle.BorderColor3 = HEAD_CIRCLE_COLOR
    circle.BackgroundColor3 = Color3.new(1,1,1)
    circle.ZIndex = 10
    circle.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1,0)
    corner.Parent = circle

    local updateConn
    updateConn = RunService.RenderStepped:Connect(function()
        if not bb.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            if updateConn then updateConn:Disconnect() end
            return
        end
        local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local dist = (myRoot.Position - head.Position).Magnitude
        local scale = BOX_MAX_SCALE
        if dist > BOX_MIN_DIST then
            scale = math.max(BOX_MIN_SCALE, BOX_MAX_SCALE * (BOX_MIN_DIST/dist))
        end
        bb.Size = UDim2.new(0, math.floor(HEAD_CIRCLE_RADIUS*2*scale), 0, math.floor(HEAD_CIRCLE_RADIUS*2*scale))
    end)

    head.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if bb and bb.Parent then bb:Destroy() end
            if updateConn then updateConn:Disconnect() end
        end
    end)
end

local function createNameTagAndBox(character, playerObj)
    removeOldTag(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local function getCharSize()
        local height, width = 5, 2
        local head = character:FindFirstChild("Head")
        if head and rootPart then
            local diff = (head.Position - rootPart.Position).Magnitude
            height = diff*2 + 2
        end
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if torso then width = torso.Size.X + 1 end
        return height, width
    end
    local height, width = getCharSize()

    local bb = Instance.new("BillboardGui")
    bb.Name = "NameTag"
    bb.Adornee = rootPart
    bb.Size = UDim2.new(0, math.floor(width*BOX_PIXEL_PER_STUD), 0, math.floor(height*BOX_PIXEL_PER_STUD))
    bb.StudsOffset = Vector3.new(0, height/2 + BOX_Y_OFFSET, 0)
    bb.AlwaysOnTop = true
    bb.Parent = rootPart

    local frame = Instance.new("Frame")
    frame.Name = "PlayerBox"
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = 1
    frame.Parent = bb

    local function makeLine(pos, size)
        local line = Instance.new("Frame")
        line.BackgroundColor3 = BOX_COLOR
        line.BorderSizePixel = 0
        line.BackgroundTransparency = 0
        line.ZIndex = 2
        line.Position = pos
        line.Size = size
        line.Parent = frame
    end
    makeLine(UDim2.new(0,0,0,0), UDim2.new(1,0,0,BOX_THICKNESS))
    makeLine(UDim2.new(0,0,1,-BOX_THICKNESS), UDim2.new(1,0,0,BOX_THICKNESS))
    makeLine(UDim2.new(0,0,0,0), UDim2.new(0,BOX_THICKNESS,1,0))
    makeLine(UDim2.new(1,-BOX_THICKNESS,0,0), UDim2.new(0,BOX_THICKNESS,1,0))

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ESPName"
    nameLabel.Size = UDim2.new(1,0,0,24)
    nameLabel.Position = UDim2.new(0,0,0,-28)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = BOX_COLOR
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = playerObj.DisplayName or playerObj.Name
    nameLabel.Parent = bb

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "ESPDist"
    distLabel.Size = UDim2.new(1,0,0,22)
    distLabel.Position = UDim2.new(0,0,1,6)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = BOX_COLOR
    distLabel.TextStrokeTransparency = 0.6
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.Text = "..."
    distLabel.Parent = bb

    local updateConn
    updateConn = RunService.RenderStepped:Connect(function()
        if not bb.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            if updateConn then updateConn:Disconnect() end
            return
        end
        local myRoot = player.Character:FindFirstChild("HumanoidRootPart")
        local dist = (myRoot.Position - rootPart.Position).Magnitude
        distLabel.Text = string.format("%.1f studs", dist)
        local scale = BOX_MAX_SCALE
        if dist > BOX_MIN_DIST then
            scale = math.max(BOX_MIN_SCALE, BOX_MAX_SCALE * (BOX_MIN_DIST/dist))
        end
        bb.Size = UDim2.new(0, math.floor(width*BOX_PIXEL_PER_STUD*scale), 0, math.floor(height*BOX_PIXEL_PER_STUD*scale))
        nameLabel.TextScaled = true
        distLabel.TextScaled = true
    end)

    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            if bb and bb.Parent then bb:Destroy() end
            if updateConn then updateConn:Disconnect() end
        end)
    end
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if bb and bb.Parent then bb:Destroy() end
            if updateConn then updateConn:Disconnect() end
        end
    end)
end

local function setupCharacter(playerObj, character)
    removeOldTag(character)
    removeOldHeadESP(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
    if root then
        createNameTagAndBox(character, playerObj)
        createHeadESP(character)
    end
end

local function onPlayerAdded(playerObj)
    playerObj.CharacterAdded:Connect(function(character)
        setupCharacter(playerObj, character)
    end)
    if playerObj.Character then
        setupCharacter(playerObj, playerObj.Character)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then
        onPlayerAdded(plr)
    end
end
Players.PlayerAdded:Connect(function(plr)
    if plr ~= player then
        onPlayerAdded(plr)
    end
end)
