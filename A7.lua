--================================================================================
--  Pozer S HUB / Complete Edition
--================================================================================

local OrionLib = nil
local ok1, res1 = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
end)
if ok1 and res1 then
    OrionLib = res1
else
    local ok2, res2 = pcall(function()
        return loadstring(game:HttpGet('https://pastefy.app/H3pBfBVT/raw'))()
    end)
    if ok2 and res2 then OrionLib = res2 else error("[HUB] Failed to load OrionLib.") end
end

local Window = OrionLib:MakeWindow({
    Name = "Pozer S HUB | Complete Edition",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "PozerSHubConfig",
    IntroEnabled = true,
    IntroText = "Pozer S HUB Loading..."
})

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    Camera = workspace.CurrentCamera
}
local LocalPlayer = Services.Players.LocalPlayer

local Events = {
    GrabEvents = Services.ReplicatedStorage:WaitForChild("GrabEvents", 5),
    DataEvents = Services.ReplicatedStorage:WaitForChild("DataEvents", 5)
}
local SetNetworkOwnerEvent = Events.GrabEvents and Events.GrabEvents:WaitForChild("SetNetworkOwner", 5)
local UpdateLineColorsEvent = Events.DataEvents and Events.DataEvents:WaitForChild("UpdateLineColorsEvent", 5)

local COLORS = {
    DEFAULT = Color3.fromRGB(255, 255, 255),
    RED     = Color3.fromRGB(255, 0, 0),
    BLUE    = Color3.fromRGB(0, 0, 255),
    PURPLE  = Color3.fromRGB(128, 0, 128),
    BLACK   = Color3.fromRGB(0, 0, 0)
}

local HUB_STATE = {
    IsEnabled = true,
    IsAnimating = false,
    AnimationTimeAccumulator = 0,
    MaxDiceLimit = 150,
    SphereRadiusNormal = 3.5,
    SphereHeightOffset = 0,
    DiceRotationSpeed = 2.0,
    ThirdPersonEnabled = false,
    ThirdPersonDistance = 15.0,
    NetSyncInterval = 0.5,
    SendNetworkOwner = false,
}

local DiceStorage = {
    All = {},
    RightSphere = {},
    LeftSphere = {},
    HoveringMap = {},
    ColorMap = {},
    OriginalProperties = {}
}

local SpecialAnim = {
    Type = "NONE",
    Timer = 0,
    FlyDir = Vector3.zero,
    StartPos = Vector3.zero,
    BurstDirections = {}
}

--================================================================================
-- 🎨 カラーパレット（動的）
--================================================================================
local PALETTE = {
    DEFAULT = COLORS.DEFAULT,
    RED     = COLORS.RED,
    BLUE    = COLORS.BLUE,
    PURPLE  = COLORS.PURPLE,
    BLACK   = COLORS.BLACK,
}

local PRESETS = {
    ["クラシック"] = { DEFAULT = Color3.fromRGB(255,255,255), RED = Color3.fromRGB(255,0,0),   BLUE = Color3.fromRGB(0,0,255),   PURPLE = Color3.fromRGB(128,0,128), BLACK = Color3.fromRGB(0,0,0) },
    ["全黒"]       = { DEFAULT = Color3.fromRGB(0,0,0),       RED = Color3.fromRGB(0,0,0),     BLUE = Color3.fromRGB(0,0,0),     PURPLE = Color3.fromRGB(0,0,0),     BLACK = Color3.fromRGB(0,0,0) },
    ["ネオン"]     = { DEFAULT = Color3.fromRGB(255,255,255), RED = Color3.fromRGB(255,50,100), BLUE = Color3.fromRGB(50,200,255), PURPLE = Color3.fromRGB(180,80,255), BLACK = Color3.fromRGB(20,20,30) },
    ["パステル"]   = { DEFAULT = Color3.fromRGB(255,240,245), RED = Color3.fromRGB(255,150,180), BLUE = Color3.fromRGB(150,200,255), PURPLE = Color3.fromRGB(200,160,255), BLACK = Color3.fromRGB(80,80,100) },
    ["ゴールド"]   = { DEFAULT = Color3.fromRGB(255,215,0),   RED = Color3.fromRGB(255,140,0),  BLUE = Color3.fromRGB(255,200,80), PURPLE = Color3.fromRGB(200,150,0), BLACK = Color3.fromRGB(50,40,0) },
    ["レインボー"] = { DEFAULT = Color3.fromRGB(255,0,0),     RED = Color3.fromRGB(255,100,0),  BLUE = Color3.fromRGB(0,200,255), PURPLE = Color3.fromRGB(150,0,255), BLACK = Color3.fromRGB(0,0,0) },
}
local PRESET_ORDER = { "クラシック", "全黒", "ネオン", "パステル", "ゴールド", "レインボー" }

local function ApplyPaletteToAll()
    for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.DEFAULT end
end
local function ApplyPaletteToRight()
    for _, d in ipairs(DiceStorage.RightSphere) do DiceStorage.ColorMap[d] = PALETTE.RED end
end
local function ApplyPaletteToLeft()
    for _, d in ipairs(DiceStorage.LeftSphere) do DiceStorage.ColorMap[d] = PALETTE.BLUE end
end
local function ApplyPreset(name)
    local p = PRESETS[name]
    if not p then return end
    for k, v in pairs(p) do PALETTE[k] = v end
end

--================================================================================
-- 🛡️ 所有判定
--================================================================================
local function IsOwnedByOtherPlayer(part)
    if not part or not part:IsA("BasePart") then return true end
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar and part:IsDescendantOf(pChar) then return true end
            local pBackpack = player:FindFirstChild("Backpack")
            if pBackpack and part:IsDescendantOf(pBackpack) then return true end
        end
    end
    local ok, owner = pcall(function() return part:GetNetworkOwner() end)
    if ok then
        if owner == nil then return true end
        if owner ~= LocalPlayer then return true end
    end
    return false
end

local function IsMyOnlyToyPart(part)
    if not part or not part:IsA("BasePart") or part.Anchored then return false end
    local myChar = LocalPlayer.Character
    if myChar and part:IsDescendantOf(myChar) then return false end
    if IsOwnedByOtherPlayer(part) then return false end
    local pName = part.Name
    local parentName = part.Parent and part.Parent.Name or ""
    if pName:find("Dice") or parentName:find("Dice") or pName:find("Toy") or parentName:find("Toy") then
        return true
    end
    return false
end

--================================================================================
-- 🧲 物理制御
--================================================================================
local function SetupDicePhysics(part)
    if not part or not part:IsA("BasePart") then return end
    if not DiceStorage.OriginalProperties[part] then
        DiceStorage.OriginalProperties[part] = {
            Color = part.Color,
            CFrame = part.CFrame,
            CanCollide = part.CanCollide
        }
    end
    part.CanCollide = false
    local bv = part:FindFirstChild("DiceForce") or Instance.new("BodyVelocity")
    bv.Name = "DiceForce" bv.MaxForce = Vector3.new(1,1,1) * 1e7 bv.P = 12500 bv.Parent = part
    local bg = part:FindFirstChild("DiceGyro") or Instance.new("BodyGyro")
    bg.Name = "DiceGyro" bg.MaxTorque = Vector3.new(1,1,1) * 1e7 bg.P = 12500 bg.Parent = part
end

local function RemoveDicePhysics(part, restore)
    if not part then return end
    local bv = part:FindFirstChild("DiceForce")
    local bg = part:FindFirstChild("DiceGyro")
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    local orig = DiceStorage.OriginalProperties[part]
    if orig then
        if restore then
            pcall(function() part.Color = orig.Color end)
            pcall(function() part.CanCollide = orig.CanCollide end)
        else
            part.CanCollide = true
        end
        DiceStorage.OriginalProperties[part] = nil
    else
        part.CanCollide = true
    end
end

local function CleanupDiceDatabase(restore)
    for i = #DiceStorage.All, 1, -1 do
        local part = DiceStorage.All[i]
        if not part or not part.Parent or not part:IsDescendantOf(Services.Workspace) or IsOwnedByOtherPlayer(part) then
            DiceStorage.HoveringMap[part] = nil
            DiceStorage.ColorMap[part] = nil
            RemoveDicePhysics(part, restore)
            table.remove(DiceStorage.All, i)
        end
    end
end

local function AutoDistributeToysSymmetrically()
    CleanupDiceDatabase(false)
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not root then return end

    for _, part in ipairs(Services.Workspace:GetPartBoundsInRadius(root.Position, 120)) do
        if #DiceStorage.All >= HUB_STATE.MaxDiceLimit then break end
        if IsMyOnlyToyPart(part) and not DiceStorage.HoveringMap[part] then
            DiceStorage.HoveringMap[part] = true
            SetupDicePhysics(part)
            table.insert(DiceStorage.All, part)
            if not DiceStorage.ColorMap[part] then DiceStorage.ColorMap[part] = PALETTE.DEFAULT end
        end
    end

    DiceStorage.RightSphere = {}
    DiceStorage.LeftSphere = {}
    for index, part in ipairs(DiceStorage.All) do
        if index % 2 == 1 then
            table.insert(DiceStorage.RightSphere, part)
        else
            table.insert(DiceStorage.LeftSphere, part)
        end
    end
end

local function CalculateSpherePointOffset(index, totalPoints, radius, timeOffset, speedMult)
    if totalPoints <= 0 then return Vector3.zero end
    local goldenRatio = (1 + math.sqrt(5)) / 2
    local theta = 2 * math.pi * index / goldenRatio
    local phi = math.acos(1 - (2 * (index - 0.5) / totalPoints))
    local x = radius * math.sin(phi) * math.cos(theta)
    local y = radius * math.sin(phi) * math.sin(theta)
    local z = radius * math.cos(phi)
    local spd = speedMult or HUB_STATE.DiceRotationSpeed
    local rotCF = CFrame.Angles(timeOffset * spd * 0.75, timeOffset * spd, timeOffset * spd * 0.5)
    return rotCF:VectorToWorldSpace(Vector3.new(x, y, z))
end

--================================================================================
-- GUI 構築
--================================================================================
local TabMain = Window:MakeTab({ Name = "🎮 メイン演出", Icon = "rbxassetid://4483345998" })
local TabColor = Window:MakeTab({ Name = "🎨 カラー選択", Icon = "rbxassetid://4483345998" })
local TabCamera = Window:MakeTab({ Name = "🎥 3人称視点", Icon = "rbxassetid://4483345998" })
local TabSettings = Window:MakeTab({ Name = "⚙️ 設定 & 調整", Icon = "rbxassetid://4483345998" })

--========= メイン演出 =========
TabMain:AddSection({ Name = "✨ 演出ボタンリスト" })

TabMain:AddButton({
    Name = "🔴🔵 [1] 右赤 & 左青 カラー適用",
    Callback = function()
        SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false
        ApplyPaletteToRight(); ApplyPaletteToLeft()
    end
})

TabMain:AddButton({
    Name = "🟣💥 [2] 紫色巨大球体に合体 ➔ 一気に撃ち出す！",
    Callback = function()
        local char = LocalPlayer.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root then return end
        HUB_STATE.IsAnimating = true
        SpecialAnim.Type = "MERGE_AND_SHOOT"
        SpecialAnim.Timer = 0
        SpecialAnim.FlyDir = root.CFrame.LookVector
    end
})

TabMain:AddButton({
    Name = "🟣 [3] 紫色合体 & 正面巨大化（維持）",
    Callback = function()
        HUB_STATE.IsAnimating = true
        SpecialAnim.Type = "PURPLE_MERGE"
        SpecialAnim.Timer = 0
    end
})

TabMain:AddButton({
    Name = "🔵 [4] 青色 周回1周回転 ＆ 砕け散りバースト",
    Callback = function()
        HUB_STATE.IsAnimating = true
        SpecialAnim.Type = "BLUE_BURST"
        SpecialAnim.Timer = 0
        for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.BLUE end
        SpecialAnim.BurstDirections = {}
        for _, d in ipairs(DiceStorage.All) do
            local rnd = Vector3.new(math.random(-100,100), math.random(-20,100), math.random(-100,100))
            if rnd.Magnitude < 0.001 then rnd = Vector3.new(0,1,0) end
            SpecialAnim.BurstDirections[d] = rnd.Unit
        end
    end
})

TabMain:AddButton({
    Name = "🔴 [5] 赤色 目の前回転 ＆ パンッと放つ",
    Callback = function()
        local char = LocalPlayer.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root then return end
        HUB_STATE.IsAnimating = true
        SpecialAnim.Type = "RED_SHOOT"
        SpecialAnim.Timer = 0
        SpecialAnim.FlyDir = root.CFrame.LookVector
        for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.RED end
    end
})

TabMain:AddButton({
    Name = "⚫ [6] 頭上に黒色ブラックホール作成・維持",
    Callback = function()
        HUB_STATE.IsAnimating = true
        SpecialAnim.Type = "BLACK_HOLE"
        for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.BLACK end
    end
})

TabMain:AddButton({
    Name = "🟢 [7] 通常状態に戻す（全停止）",
    Callback = function()
        SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false
        for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.DEFAULT end
    end
})

--========= カラー選択 =========
TabColor:AddSection({ Name = "🎯 役割別カラーピッカー" })

local roleDefs = {
    { key = "DEFAULT", label = "DEFAULT（通常時の全体色）" },
    { key = "RED",     label = "RED（右球 / 赤演出）" },
    { key = "BLUE",    label = "BLUE（左球 / 青演出）" },
    { key = "PURPLE",  label = "PURPLE（紫合体）" },
    { key = "BLACK",   label = "BLACK（ブラックホール）" },
}

for _, def in ipairs(roleDefs) do
    TabColor:AddColorPicker({
        Name = def.label,
        Default = PALETTE[def.key],
        Callback = function(Color)
            PALETTE[def.key] = Color
            if def.key == "DEFAULT" then
                for _, d in ipairs(DiceStorage.All) do
                    if DiceStorage.ColorMap[d] == nil then DiceStorage.ColorMap[d] = Color end
                end
            elseif def.key == "RED" then
                for _, d in ipairs(DiceStorage.RightSphere) do DiceStorage.ColorMap[d] = Color end
            elseif def.key == "BLUE" then
                for _, d in ipairs(DiceStorage.LeftSphere) do DiceStorage.ColorMap[d] = Color end
            end
        end
    })
end

TabColor:AddSection({ Name = "🌈 プリセット（全色一括）" })
for _, name in ipairs(PRESET_ORDER) do
    TabColor:AddButton({
        Name = "🎨 " .. name,
        Callback = function()
            ApplyPreset(name)
            ApplyPaletteToAll()
            ApplyPaletteToRight()
            ApplyPaletteToLeft()
        end
    })
end

TabColor:AddSection({ Name = "⚡ クイック適用" })
TabColor:AddButton({ Name = "⚪ 全ダイスを DEFAULT 色に", Callback = function()
    SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false; ApplyPaletteToAll()
end })
TabColor:AddButton({ Name = "🔴 右球を RED に", Callback = function()
    SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false; ApplyPaletteToRight()
end })
TabColor:AddButton({ Name = "🔵 左球を BLUE に", Callback = function()
    SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false; ApplyPaletteToLeft()
end })
TabColor:AddButton({ Name = "⚫ 全ダイスを BLACK に", Callback = function()
    SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false
    for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.BLACK end
end })
TabColor:AddButton({ Name = "💜 全ダイスを PURPLE に", Callback = function()
    SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false
    for _, d in ipairs(DiceStorage.All) do DiceStorage.ColorMap[d] = PALETTE.PURPLE end
end })

--========= 3人称視点 =========
TabCamera:AddSection({ Name = "🎥 3人称視点コントロール" })
TabCamera:AddToggle({
    Name = "3人称視点（TPS）有効化",
    Default = false,
    Callback = function(Value)
        HUB_STATE.ThirdPersonEnabled = Value
        if not Value then Services.Camera.CameraType = Enum.CameraType.Custom end
    end
})
TabCamera:AddSlider({
    Name = "カメラ距離", Min = 5, Max = 50, Default = 15,
    Color = Color3.fromRGB(255,255,255), Increment = 1, ValueName = "m",
    Callback = function(Value) HUB_STATE.ThirdPersonDistance = Value end
})

--========= 設定 =========
TabSettings:AddSection({ Name = "📐 パラメータ調整" })
TabSettings:AddSlider({
    Name = "球体の大きさ (半径)", Min = 1, Max = 15, Default = 3.5,
    Color = Color3.fromRGB(0,255,150), Increment = 0.5, ValueName = "m",
    Callback = function(Value) HUB_STATE.SphereRadiusNormal = Value end
})
TabSettings:AddSlider({
    Name = "高さオフセット (Y軸)", Min = -10, Max = 20, Default = 0,
    Color = Color3.fromRGB(255,200,0), Increment = 0.5, ValueName = "m",
    Callback = function(Value) HUB_STATE.SphereHeightOffset = Value end
})
TabSettings:AddSlider({
    Name = "回転速度", Min = 0, Max = 15, Default = 2,
    Color = Color3.fromRGB(100,150,255), Increment = 0.5, ValueName = "倍",
    Callback = function(Value) HUB_STATE.DiceRotationSpeed = Value end
})

TabSettings:AddSection({ Name = "🌐 ネットワーク" })
TabSettings:AddSlider({
    Name = "色同期間隔", Min = 0.2, Max = 3.0, Default = 0.5,
    Color = Color3.fromRGB(255,120,120), Increment = 0.1, ValueName = "s",
    Callback = function(Value) HUB_STATE.NetSyncInterval = Value end
})
TabSettings:AddToggle({
    Name = "SetNetworkOwner を送信（非推奨）",
    Default = false,
    Callback = function(Value) HUB_STATE.SendNetworkOwner = Value end
})
TabSettings:AddSection({ Name = "🧹 クリーンアップ" })
TabSettings:AddButton({
    Name = "全ダイスの物理・色を元に戻す",
    Callback = function()
        SpecialAnim.Type = "NONE"; HUB_STATE.IsAnimating = false
        CleanupDiceDatabase(true)
        for _, d in ipairs(DiceStorage.All) do RemoveDicePhysics(d, true) end
        DiceStorage.All = {}; DiceStorage.RightSphere = {}; DiceStorage.LeftSphere = {}
        DiceStorage.HoveringMap = {}; DiceStorage.ColorMap = {}
    end
})

--================================================================================
-- Heartbeat
--================================================================================
Services.RunService.Heartbeat:Connect(function(dt)
    HUB_STATE.AnimationTimeAccumulator = HUB_STATE.AnimationTimeAccumulator + dt
    AutoDistributeToysSymmetrically()

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    if HUB_STATE.ThirdPersonEnabled then
        Services.Camera.CameraType = Enum.CameraType.Scriptable
        local targetCamPos = root.Position - (root.CFrame.LookVector * HUB_STATE.ThirdPersonDistance) + Vector3.new(0, 4, 0)
        Services.Camera.CFrame = CFrame.new(targetCamPos, root.Position + Vector3.new(0, 2, 0))
    end

    local heightOffset = Vector3.new(0, HUB_STATE.SphereHeightOffset, 0)
    local rightCenter = (root.CFrame * CFrame.new(8, 0, 0)).Position + heightOffset
    local leftCenter  = (root.CFrame * CFrame.new(-8, 0, 0)).Position + heightOffset
    local frontCenter = (root.CFrame * CFrame.new(0, 0, -6)).Position + heightOffset
    local headCenter  = (root.CFrame * CFrame.new(0, 8, 0)).Position + heightOffset

    if HUB_STATE.IsAnimating then
        SpecialAnim.Timer = SpecialAnim.Timer + dt

        if SpecialAnim.Type == "MERGE_AND_SHOOT" then
            if SpecialAnim.Timer <= 1.8 then
                local progress = math.clamp(SpecialAnim.Timer / 1.8, 0, 1)
                for _, d in ipairs(DiceStorage.RightSphere) do DiceStorage.ColorMap[d] = PALETTE.RED:Lerp(PALETTE.PURPLE, progress) end
                for _, d in ipairs(DiceStorage.LeftSphere)  do DiceStorage.ColorMap[d] = PALETTE.BLUE:Lerp(PALETTE.PURPLE, progress) end
                local rPos = rightCenter:Lerp(frontCenter, progress)
                local lPos = leftCenter:Lerp(frontCenter, progress)
                for i, d in ipairs(DiceStorage.RightSphere) do
                    local offset = CalculateSpherePointOffset(i, #DiceStorage.RightSphere, 4.0, HUB_STATE.AnimationTimeAccumulator, 6.0)
                    local bv = d:FindFirstChild("DiceForce")
                    if bv then bv.Velocity = ((rPos + offset) - d.Position) * 22 end
                end
                for i, d in ipairs(DiceStorage.LeftSphere) do
                    local offset = CalculateSpherePointOffset(i, #DiceStorage.LeftSphere, 4.0, HUB_STATE.AnimationTimeAccumulator, 6.0)
                    local bv = d:FindFirstChild("DiceForce")
                    if bv then bv.Velocity = ((lPos + offset) - d.Position) * 22 end
                end
            elseif SpecialAnim.Timer <= 3.5 then
                local flyTime = SpecialAnim.Timer - 1.8
                local currentFlyPos = frontCenter + (SpecialAnim.FlyDir * 300 * flyTime)
                for i, d in ipairs(DiceStorage.All) do
                    if d and d.Parent then
                        DiceStorage.ColorMap[d] = PALETTE.PURPLE
                        local offset = CalculateSpherePointOffset(i, #DiceStorage.All, 5.5, HUB_STATE.AnimationTimeAccumulator, 12.0)
                        local bv = d:FindFirstChild("DiceForce")
                        if bv then bv.Velocity = ((currentFlyPos + offset) - d.Position) * 40 end
                    end
                end
            else
                HUB_STATE.IsAnimating = false; SpecialAnim.Type = "NONE"
            end
            return

        elseif SpecialAnim.Type == "PURPLE_MERGE" then
            local progress = math.clamp(SpecialAnim.Timer / 1.5, 0, 1)
            for _, d in ipairs(DiceStorage.RightSphere) do DiceStorage.ColorMap[d] = PALETTE.RED:Lerp(PALETTE.PURPLE, progress) end
            for _, d in ipairs(DiceStorage.LeftSphere)  do DiceStorage.ColorMap[d] = PALETTE.BLUE:Lerp(PALETTE.PURPLE, progress) end
            local rPos = rightCenter:Lerp(frontCenter, progress)
            local lPos = leftCenter:Lerp(frontCenter, progress)
            for i, d in ipairs(DiceStorage.RightSphere) do
                local offset = CalculateSpherePointOffset(i, #DiceStorage.RightSphere, 4.5, HUB_STATE.AnimationTimeAccumulator)
                local bv = d:FindFirstChild("DiceForce")
                if bv then bv.Velocity = ((rPos + offset) - d.Position) * 20 end
            end
            for i, d in ipairs(DiceStorage.LeftSphere) do
                local offset = CalculateSpherePointOffset(i, #DiceStorage.LeftSphere, 4.5, HUB_STATE.AnimationTimeAccumulator)
                local bv = d:FindFirstChild("DiceForce")
                if bv then bv.Velocity = ((lPos + offset) - d.Position) * 20 end
            end
            return

        elseif SpecialAnim.Type == "BLUE_BURST" then
            if SpecialAnim.Timer <= 2.5 then
                local angle = (SpecialAnim.Timer / 2.5) * math.pi * 2
                local orbitPos = root.Position + Vector3.new(math.cos(angle) * 10, 2 + HUB_STATE.SphereHeightOffset, math.sin(angle) * 10)
                for i, d in ipairs(DiceStorage.All) do
                    if d and d.Parent then
                        local offset = CalculateSpherePointOffset(i, #DiceStorage.All, 5.0, HUB_STATE.AnimationTimeAccumulator, 10.0)
                        local bv = d:FindFirstChild("DiceForce")
                        if bv then bv.Velocity = ((orbitPos + offset) - d.Position) * 30 end
                    end
                end
            elseif SpecialAnim.Timer <= 4.5 then
                local burstTime = SpecialAnim.Timer - 2.5
                for _, d in ipairs(DiceStorage.All) do
                    if d and d.Parent then
                        local dir = SpecialAnim.BurstDirections[d] or Vector3.new(0,1,0)
                        local bv = d:FindFirstChild("DiceForce")
                        if bv then bv.Velocity = dir * (200 + (burstTime * 50)) end
                    end
                end
            else
                HUB_STATE.IsAnimating = false; SpecialAnim.Type = "NONE"
            end
            return

        elseif SpecialAnim.Type == "RED_SHOOT" then
            if SpecialAnim.Timer <= 2.0 then
                for i, d in ipairs(DiceStorage.All) do
                    if d and d.Parent then
                        local offset = CalculateSpherePointOffset(i, #DiceStorage.All, 4.0, HUB_STATE.AnimationTimeAccumulator, 8.0)
                        local bv = d:FindFirstChild("DiceForce")
                        if bv then bv.Velocity = ((frontCenter + offset) - d.Position) * 25 end
                    end
                end
            elseif SpecialAnim.Timer <= 3.5 then
                local flyTime = SpecialAnim.Timer - 2.0
                local currentFlyPos = frontCenter + (SpecialAnim.FlyDir * 250 * flyTime)
                for i, d in ipairs(DiceStorage.All) do
                    if d and d.Parent then
                        local offset = CalculateSpherePointOffset(i, #DiceStorage.All, 4.0, HUB_STATE.AnimationTimeAccumulator, 8.0)
                        local bv = d:FindFirstChild("DiceForce")
                        if bv then bv.Velocity = ((currentFlyPos + offset) - d.Position) * 35 end
                    end
                end
            else
                HUB_STATE.IsAnimating = false; SpecialAnim.Type = "NONE"
            end
            return

        elseif SpecialAnim.Type == "BLACK_HOLE" then
            for i, d in ipairs(DiceStorage.All) do
                if d and d.Parent then
                    local offset = CalculateSpherePointOffset(i, #DiceStorage.All, 4.5, HUB_STATE.AnimationTimeAccumulator, 8.0)
                    local bv = d:FindFirstChild("DiceForce")
                    if bv then bv.Velocity = ((headCenter + offset) - d.Position) * 25 end
                end
            end
            return
        end
    end

    local radius = HUB_STATE.SphereRadiusNormal
    for i, d in ipairs(DiceStorage.RightSphere) do
        if d and d.Parent then
            local offset = CalculateSpherePointOffset(i, #DiceStorage.RightSphere, radius, HUB_STATE.AnimationTimeAccumulator)
            local bv = d:FindFirstChild("DiceForce")
            local bg = d:FindFirstChild("DiceGyro")
            if bv then bv.Velocity = ((rightCenter + offset) - d.Position) * 20 end
            if bg then bg.CFrame = CFrame.new(d.Position, rightCenter + offset) * CFrame.Angles(HUB_STATE.AnimationTimeAccumulator * HUB_STATE.DiceRotationSpeed, 0, 0) end
        end
    end
    for i, d in ipairs(DiceStorage.LeftSphere) do
        if d and d.Parent then
            local offset = CalculateSpherePointOffset(i, #DiceStorage.LeftSphere, radius, HUB_STATE.AnimationTimeAccumulator)
            local bv = d:FindFirstChild("DiceForce")
            local bg = d:FindFirstChild("DiceGyro")
            if bv then bv.Velocity = ((leftCenter + offset) - d.Position) * 20 end
            if bg then bg.CFrame = CFrame.new(d.Position, leftCenter + offset) * CFrame.Angles(HUB_STATE.AnimationTimeAccumulator * HUB_STATE.DiceRotationSpeed, 0, 0) end
        end
    end
end)

--================================================================================
-- ネットワーク同期
--================================================================================
task.spawn(function()
    while true do
        CleanupDiceDatabase(false)
        for _, d in ipairs(DiceStorage.All) do
            if d and d.Parent then
                local targetColor = DiceStorage.ColorMap[d] or PALETTE.DEFAULT
                local seq = ColorSequence.new(targetColor)
                if UpdateLineColorsEvent then
                    pcall(function()
                        UpdateLineColorsEvent:FireServer(seq, targetColor, targetColor, targetColor, targetColor, targetColor, targetColor, targetColor, targetColor, targetColor)
                    end)
                end
                if HUB_STATE.SendNetworkOwner and SetNetworkOwnerEvent then
                    pcall(function() SetNetworkOwnerEvent:FireServer(d, d.CFrame) end)
                end
            end
        end
        task.wait(HUB_STATE.NetSyncInterval)
    end
end)

OrionLib:Init()
