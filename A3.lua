--[[
    Cinder — Snap Attach (Follow + Horizontal Camera Lock)
    executor: Delta
    UI: 右側ドラッグ可能トグルボタン
    発動: ボタン押下 → 画面中心レイ先パーツ中心 +3 studs 上に追従
    特徴: 位置は追従。向きは水平（Y軸）だけカメラに追従、ピッチは無視
    解除: 再押下 or 死亡
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- 設定
-- =========================================================
local Config = {
    OffsetY              = 3.8,     -- パーツ中心から上へのオフセット（studs）
    PositionResponsive   = 40,    -- 位置追従の滑らかさ
    RotationResponsive   = 60,    -- 水平回転の追従速度（高いほどキビキビ）
}

-- =========================================================
-- state
-- =========================================================
local State = {
    locked       = false,
    alignPos     = nil,
    alignOri     = nil,
    attSelf      = nil,
    attTarget    = nil,
    targetPart   = nil,
    rotConn      = nil,
    savedAutoRot = true,
}

-- =========================================================
-- UI 構築
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CinderSnapUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Button = Instance.new("TextButton")
Button.Name = "SnapButton"
Button.Size = UDim2.new(0, 150, 0, 46)
Button.AnchorPoint = Vector2.new(1, 0.5)
Button.Position = UDim2.new(1, -20, 0.5, 0)
Button.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
Button.BorderSizePixel = 0
Button.Text = "SNAP: OFF"
Button.TextColor3 = Color3.fromRGB(200, 200, 210)
Button.Font = Enum.Font.GothamBold
Button.TextSize = 14
Button.AutoButtonColor = false
Button.Active = true
Button.Draggable = true
Button.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = Button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 90, 130)
stroke.Thickness = 1
stroke.Transparency = 0.3
stroke.Parent = Button

-- =========================================================
-- 画面中心レイ先パーツ取得
-- =========================================================
local function getPartUnderCrosshair()
    local cam = Workspace.CurrentCamera
    local viewport = cam.ViewportSize
    local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

    local ray = cam:ViewportPointToRay(center.X, center.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character or LocalPlayer }
    params.IgnoreWater = true

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
    if result and result.Instance then
        return result.Instance
    end
    return nil
end

-- =========================================================
-- カメラの水平向きだけ取り出す
-- =========================================================
local function getHorizontalCamCFrame()
    local cam = Workspace.CurrentCamera
    local camCF = cam.CFrame
    local lookFlat = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)

    -- 真上/真下を向いた時のフォールバック
    if lookFlat.Magnitude < 0.01 then
        lookFlat = Vector3.new(0, 0, -1)
    end
    lookFlat = lookFlat.Unit
    return CFrame.lookAt(Vector3.zero, lookFlat)
end

-- =========================================================
-- 追従開始
-- =========================================================
local function startFollow()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end

    local part = getPartUnderCrosshair()
    if not part then return false end

    -- 歩行物理を切り離し、カメラ方向への自動回転を停止（自分で制御する）
    hum.PlatformStand = true
    State.savedAutoRot = hum.AutoRotate
    hum.AutoRotate = false

    -- 自分側 Attachment
    local attSelf = Instance.new("Attachment")
    attSelf.Name = "Cinder_AttSelf"
    attSelf.Parent = hrp

    -- ターゲット側 Attachment（+OffsetY 上）
    local attTarget = Instance.new("Attachment")
    attTarget.Name = "Cinder_AttTarget"
    attTarget.Position = Vector3.new(0, Config.OffsetY, 0)
    attTarget.Parent = part

    -- AlignPosition：位置追従
    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "Cinder_AlignPos"
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = attSelf
    alignPos.Attachment1 = attTarget
    alignPos.Responsiveness = Config.PositionResponsive
    alignPos.MaxForce = math.huge
    alignPos.RigidityEnabled = false
    alignPos.ApplyAtCenterOfMass = false
    alignPos.Parent = hrp

    -- AlignOrientation：水平回転だけカメラ追従
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Name = "Cinder_AlignOri"
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = attSelf
    alignOri.CFrame = getHorizontalCamCFrame()
    alignOri.Responsiveness = Config.RotationResponsive
    alignOri.MaxTorque = math.huge
    alignOri.RigidityEnabled = false
    alignOri.Parent = hrp

    -- 毎フレーム水平向きを更新
    State.rotConn = RunService.RenderStepped:Connect(function()
        if not State.locked or not State.alignOri then return end
        State.alignOri.CFrame = getHorizontalCamCFrame()
    end)

    State.alignPos   = alignPos
    State.alignOri   = alignOri
    State.attSelf    = attSelf
    State.attTarget  = attTarget
    State.targetPart = part
    State.locked     = true
    return true
end

-- =========================================================
-- 追従解除
-- =========================================================
local function stopFollow()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if State.rotConn  then State.rotConn:Disconnect() State.rotConn = nil end
    if State.alignPos then State.alignPos:Destroy() end
    if State.alignOri then State.alignOri:Destroy() end
    if State.attSelf  then State.attSelf:Destroy()  end
    if State.attTarget then State.attTarget:Destroy() end

    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = State.savedAutoRot
    end

    State.alignPos   = nil
    State.alignOri   = nil
    State.attSelf    = nil
    State.attTarget  = nil
    State.targetPart = nil
    State.locked     = false
end

-- =========================================================
-- UI 更新
-- =========================================================
local function setUI(on)
    if on then
        Button.Text = "SNAP: ON"
        Button.BackgroundColor3 = Color3.fromRGB(40, 90, 60)
        Button.TextColor3 = Color3.fromRGB(180, 255, 200)
        stroke.Color = Color3.fromRGB(120, 220, 160)
    else
        Button.Text = "SNAP: OFF"
        Button.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        Button.TextColor3 = Color3.fromRGB(200, 200, 210)
        stroke.Color = Color3.fromRGB(70, 90, 130)
    end
end

-- =========================================================
-- トグル
-- =========================================================
local function toggle()
    if State.locked then
        stopFollow()
        setUI(false)
    else
        local ok = startFollow()
        if ok then
            setUI(true)
        else
            Button.Text = "SNAP: NO TARGET"
            task.wait(0.7)
            setUI(false)
        end
    end
end

Button.MouseButton1Click:Connect(toggle)

-- =========================================================
-- 死亡時リセット
-- =========================================================
local function hookCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        if State.rotConn then State.rotConn:Disconnect() State.rotConn = nil end
        State.alignPos   = nil
        State.alignOri   = nil
        State.attSelf    = nil
        State.attTarget  = nil
        State.targetPart = nil
        State.locked     = false
        setUI(false)
    end)
end

if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(hookCharacter)
