-- === SECRETMECRET AUTOLOADER (WICHTIG: Funktioniert nach Teleport!) ===
local url = "https://raw.githubusercontent.com/ljashub/bloxstrike-beta/main/secretmecret.lua"
if queue_on_teleport then
    queue_on_teleport("loadstring(game:HttpGet('" .. url .. "'))()")
end
loadstring(game:HttpGet(url))()

-- === REST DES CHEATS (Linoria, Services, UI, Configs etc.) ===
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")

local Window = Library:CreateWindow({
    Title = 'EzyCheat | Rivals',
    Center = true,
    AutoShow = true,
})

local TabAim = Window:AddTab('Aim')
local TabVisuals = Window:AddTab('Visuals')
local TabMisc = Window:AddTab('Misc')
local TabConfig = Window:AddTab('Config')

-- === AIM TAB ===
local AimGroup = TabAim:AddLeftGroupbox('Aimbot')
local aimToggle = AimGroup:AddToggle('aim_enabled', { Text = 'Enable Aimbot', Default = false })
AimGroup:AddDropdown('aim_mode', { Values = {'Hold', 'Toggle'}, Default = 1, Text = 'Aimbot Mode' })
aimToggle:AddKeyPicker('aim_key', { Text = "Aimbot Key", Default = 'MB2', Mode = 'Hold' })
AimGroup:AddDropdown('aim_hitbox', { Values = { 'Head', 'Torso', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso' }, Default = 1, Text = 'Aim at' })
AimGroup:AddSlider('aim_fov', { Text = 'Aimbot FOV', Default = 120, Min = 10, Max = 360, Rounding = 0 })
AimGroup:AddSlider('aim_smoothing', { Text = 'Aimbot Smoothing', Default = 7, Min = 1, Max = 50, Rounding = 0 })
AimGroup:AddToggle('aim_showfov', { Text = 'Show FOV Circle', Default = true })

local TriggerGroup = TabAim:AddRightGroupbox('Triggerbot')
local trigToggle = TriggerGroup:AddToggle('trigger_enabled', { Text = 'Enable Triggerbot', Default = false })
TriggerGroup:AddDropdown('trigger_mode', { Values = {'Hold', 'Toggle'}, Default = 1, Text = 'Trigger Mode' })
trigToggle:AddKeyPicker('trigger_key', { Text = "Triggerbot Key", Default = 'MB2', Mode = 'Hold' })
local teamCheckToggle = TriggerGroup:AddToggle('trigger_teamcheck', { Text = 'Team Check', Default = true, Tooltip = 'Don\'t shoot at teammates' })

-- === VISUALS TAB ===
local VisualsGroup = TabVisuals:AddLeftGroupbox('ESP')
VisualsGroup:AddToggle('esp_nametag', { Text = 'Name Tags', Default = true })
VisualsGroup:AddToggle('esp_2dbox', { Text = '2D Boxes', Default = true })
VisualsGroup:AddToggle('esp_distance', { Text = 'Distance', Default = false })
VisualsGroup:AddToggle('esp_healthbar', { Text = 'Healthbar', Default = false })
VisualsGroup:AddSlider('esp_maxdist', {
    Text = 'Visuals Distance',
    Default = 750,
    Min = 350,
    Max = 10000,
    Rounding = 0
})

-- === MISC TAB ===
local MiscGroup = TabMisc:AddLeftGroupbox('Movement')
MiscGroup:AddToggle('bunnyhop', { Text = 'Auto Bunnyhop', Default = false })
MiscGroup:AddToggle('autostrafe', { Text = 'Auto Strafe', Default = false })

-- === CONFIG TAB (Links: Controls, Rechts: Liste) ===
local ConfigGroup = TabConfig:AddLeftGroupbox('Config System')
ConfigGroup:AddLabel('Save and load your cheat configs here!')
ConfigGroup:AddInput('configname', {Text = 'Config Name', Default = 'default'})

local function GetConfigs()
    local files = {}
    pcall(function()
        for _,v in ipairs(listfiles and listfiles("LinoriaConfigs") or {}) do
            if v:sub(-6) == ".json" then
                local name = v:match("([^\\/]*)%.json$")
                if name then table.insert(files, name) end
            end
        end
    end)
    table.sort(files)
    return files
end

local ConfigListBox = TabConfig:AddRightGroupbox('Config List')
local ConfigListObj = ConfigListBox:AddDropdown('config_list', { Values = {}, Text = 'Your Configs', Multi = false })

local function RefreshConfigList()
    local configs = GetConfigs()
    Options.config_list:SetValues(configs)
end
RefreshConfigList()

ConfigGroup:AddButton('Save Config', function()
    local name = Options.configname.Value
    Library:SaveConfig(name)
    Library:Notify('Saved config: '..name)
    RefreshConfigList()
end)
ConfigGroup:AddButton('Load Config', function()
    local name = Options.configname.Value
    Library:LoadConfig(name)
    Library:Notify('Loaded config: '..name)
end)
ConfigGroup:AddButton('Set Default', function()
    local name = Options.configname.Value
    Library:SetDefaultConfig(name)
    Library:Notify('Default config set: '..name)
end)
ConfigGroup:AddButton('Refresh Config List', function()
    RefreshConfigList()
    Library:Notify('Config list refreshed!')
end)
ConfigGroup:AddButton('Unload Cheat', function()
    Library:Unload()
end)

Options.config_list:OnChanged(function()
    local selected = Options.config_list.Value
    if selected and selected ~= "" then
        Library:LoadConfig(selected)
        Library:Notify('Loaded config: '..selected)
    end
end)

-- === FOV Drawing ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = Toggles.aim_showfov.Value
FOVCircle.Transparency = 0.7
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(84,255,196)
FOVCircle.Filled = false
FOVCircle.Radius = Options.aim_fov.Value

Options.aim_fov:OnChanged(function() FOVCircle.Radius = Options.aim_fov.Value end)
Toggles.aim_showfov:OnChanged(function() FOVCircle.Visible = Toggles.aim_showfov.Value end)

-- === Aimbot/Triggerbot Logic ===
local aimLock = false
local triggerLock = false

local function getClosestTarget(partName, fov)
    local mousePos = UserInputService:GetMouseLocation()
    local closestPart, closestDist = nil, fov or 9999
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local part = player.Character:FindFirstChild(partName)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPart = part
                    end
                end
            end
        end
    end
    return closestPart
end

RunService.RenderStepped:Connect(function()
    -- FOV Circle position
    FOVCircle.Position = UserInputService:GetMouseLocation()

    -- Aimbot Mode Handler (Hold/Toggle)
    if Toggles.aim_enabled.Value then
        local aimkey = Options.aim_key
        if Options.aim_mode.Value == "Hold" then
            aimLock = aimkey:GetState()
        else
            if aimkey:GetState() and not aimLock then
                aimLock = true
            elseif not aimkey:GetState() and aimLock then
                aimLock = false
            end
        end
    else
        aimLock = false
    end

    -- Aimbot logic
    if aimLock then
        local partName = Options.aim_hitbox.Value
        local targetPart = getClosestTarget(partName, Options.aim_fov.Value)
        if targetPart then
            local pos = Camera:WorldToViewportPoint(targetPart.Position)
            local mouse = UserInputService:GetMouseLocation()
            local delta = (Vector2.new(pos.X, pos.Y) - mouse) / Options.aim_smoothing.Value
            mousemoverel(delta.X, delta.Y)
        end
    end

    -- Triggerbot Mode Handler (Hold/Toggle)
    if Toggles.trigger_enabled.Value then
        local trigkey = Options.trigger_key
        if Options.trigger_mode.Value == "Hold" then
            triggerLock = trigkey:GetState()
        else
            if trigkey:GetState() and not triggerLock then
                triggerLock = true
            elseif not trigkey:GetState() and triggerLock then
                triggerLock = false
            end
        end
    else
        triggerLock = false
    end

    -- Triggerbot logic: Only trigger if mouse is on a player and (if enabled) not on teammate
    if triggerLock then
        local mousePos = UserInputService:GetMouseLocation()
        local unitRay = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 9999, rayParams)
        if rayResult and rayResult.Instance and rayResult.Instance.Parent then
            local plr = Players:GetPlayerFromCharacter(rayResult.Instance.Parent)
            if plr and plr ~= LocalPlayer then
                if Toggles.trigger_teamcheck.Value then
                    if plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then
                        return
                    end
                end
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end

    -- Autobunnyhop
    if Toggles.bunnyhop.Value then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                keypress(0x20)
                task.wait()
                keyrelease(0x20)
            end
        end
    end

    -- Autostrafe
    if Toggles.autostrafe.Value then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                keypress(0x44)
                keyrelease(0x41)
            elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
                keypress(0x41)
                keyrelease(0x44)
            else
                if tick() % 1 > 0.5 then
                    keypress(0x41)
                    keyrelease(0x44)
                else
                    keypress(0x44)
                    keyrelease(0x41)
                end
            end
        end
    end
end)

-- === ESP mit dynamischer Spielergröße ===
local ESPObjects = {}

local function getBoundingBox(char)
    local parts = {}
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then return end

    -- Finde min/max X/Y/Z
    local minVec, maxVec = parts[1].Position, parts[1].Position
    for _, part in ipairs(parts) do
        local pos = part.Position
        minVec = Vector3.new(
            math.min(minVec.X, pos.X),
            math.min(minVec.Y, pos.Y),
            math.min(minVec.Z, pos.Z)
        )
        maxVec = Vector3.new(
            math.max(maxVec.X, pos.X),
            math.max(maxVec.Y, pos.Y),
            math.max(maxVec.Z, pos.Z)
        )
    end

    -- 8 Eckpunkte der Boundingbox
    local corners = {
        Vector3.new(minVec.X, minVec.Y, minVec.Z),
        Vector3.new(minVec.X, minVec.Y, maxVec.Z),
        Vector3.new(minVec.X, maxVec.Y, minVec.Z),
        Vector3.new(minVec.X, maxVec.Y, maxVec.Z),
        Vector3.new(maxVec.X, minVec.Y, minVec.Z),
        Vector3.new(maxVec.X, minVec.Y, maxVec.Z),
        Vector3.new(maxVec.X, maxVec.Y, minVec.Z),
        Vector3.new(maxVec.X, maxVec.Y, maxVec.Z)
    }

    -- Projektieren und min/max 2D finden
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyOnScreen = false
    for _, corner in ipairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
        if onScreen then
            anyOnScreen = true
            minX = math.min(minX, screenPos.X)
            minY = math.min(minY, screenPos.Y)
            maxX = math.max(maxX, screenPos.X)
            maxY = math.max(maxY, screenPos.Y)
        end
    end

    if not anyOnScreen then return end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function createESPForPlayer(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    ESPObjects[player] = {}

    RunService.RenderStepped:Connect(function()
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local char = player.Character
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChild("Humanoid")
        local distToPlayer = (Camera.CFrame.Position - hrp.Position).Magnitude

        if distToPlayer > Options.esp_maxdist.Value then
            for _,obj in pairs(ESPObjects[player]) do
                if typeof(obj) == "Instance" or typeof(obj) == "table" then
                    pcall(function() obj.Visible = false end)
                end
            end
            return
        end

        local boxPos, boxSize = getBoundingBox(char)
        -- 2D Box: exakt so groß wie Spieler
        if Toggles.esp_2dbox.Value and boxPos and boxSize then
            if not ESPObjects[player].Box then
                ESPObjects[player].Box = Drawing.new("Square")
                ESPObjects[player].Box.Thickness = 2
                ESPObjects[player].Box.Color = Color3.fromRGB(0,255,0)
                ESPObjects[player].Box.Filled = false
            end
            ESPObjects[player].Box.Position = boxPos
            ESPObjects[player].Box.Size = boxSize
            ESPObjects[player].Box.Visible = true
        elseif ESPObjects[player].Box then
            ESPObjects[player].Box.Visible = false
        end
        -- Nametag
        if Toggles.esp_nametag.Value and boxPos and boxSize then
            if not ESPObjects[player].Name then
                ESPObjects[player].Name = Drawing.new("Text")
                ESPObjects[player].Name.Size = 14
                ESPObjects[player].Name.Center = true
                ESPObjects[player].Name.Outline = true
                ESPObjects[player].Name.Color = Color3.fromRGB(255,255,255)
            end
            ESPObjects[player].Name.Text = player.Name
            ESPObjects[player].Name.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y - 16)
            ESPObjects[player].Name.Visible = true
        elseif ESPObjects[player].Name then
            ESPObjects[player].Name.Visible = false
        end
        -- Distance
        if Toggles.esp_distance.Value and boxPos and boxSize then
            if not ESPObjects[player].Distance then
                ESPObjects[player].Distance = Drawing.new("Text")
                ESPObjects[player].Distance.Size = 13
                ESPObjects[player].Distance.Center = true
                ESPObjects[player].Distance.Outline = true
                ESPObjects[player].Distance.Color = Color3.fromRGB(84,255,196)
            end
            ESPObjects[player].Distance.Text = tostring(math.floor(distToPlayer)) .. "m"
            ESPObjects[player].Distance.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + 2)
            ESPObjects[player].Distance.Visible = true
        elseif ESPObjects[player].Distance then
            ESPObjects[player].Distance.Visible = false
        end
        -- Healthbar (links neben Box)
        if Toggles.esp_healthbar.Value and hum and boxPos and boxSize then
            if not ESPObjects[player].Health then
                ESPObjects[player].Health = Drawing.new("Line")
                ESPObjects[player].Health.Thickness = 4
                ESPObjects[player].Health.Color = Color3.fromRGB(0,255,0)
            end
            local healthPercent = hum.Health / hum.MaxHealth
            ESPObjects[player].Health.From = Vector2.new(boxPos.X - 6, boxPos.Y + boxSize.Y)
            ESPObjects[player].Health.To = Vector2.new(boxPos.X - 6, boxPos.Y + boxSize.Y - boxSize.Y * healthPercent)
            ESPObjects[player].Health.Visible = true
        elseif ESPObjects[player].Health then
            ESPObjects[player].Health.Visible = false
        end
    end)
end

Players.PlayerAdded:Connect(createESPForPlayer)
Players.PlayerRemoving:Connect(function(plr)
    if ESPObjects[plr] then
        for _, obj in pairs(ESPObjects[plr]) do
            if typeof(obj) == "Instance" or typeof(obj) == "table" then
                pcall(function() obj.Visible = false end)
            end
        end
        ESPObjects[plr]=nil
    end
end)
for _, player in ipairs(Players:GetPlayers()) do createESPForPlayer(player) end

Library:OnUnload(function()
    for _, v in pairs(ESPObjects) do
        for _, obj in pairs(v) do
            if typeof(obj) == "Instance" or typeof(obj) == "table" then
                pcall(function() obj.Visible = false end)
            end
        end
    end
end)
