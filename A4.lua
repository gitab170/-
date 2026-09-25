-- ==========================================
-- なべHub v1.0
-- Unified HVH Script for The Survival Game (物人)
-- Base: Orion Lib (jadpy/suki)
-- ==========================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

-- ==========================================
-- サービス
-- ==========================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = Workspace.CurrentCamera

-- ==========================================
-- リモート
-- ==========================================
local RS = ReplicatedStorage

local MenuToys        = RS:WaitForChild("MenuToys")
local GrabEvents      = RS:WaitForChild("GrabEvents")
local CharacterEvents = RS:WaitForChild("CharacterEvents")
local PlayerEvents    = RS:WaitForChild("PlayerEvents")
local BombEvents      = RS:WaitForChild("BombEvents")
local CreatureEvents  = RS:WaitForChild("CreatureEvents")

local SpawnToyRemoteFunction = MenuToys:WaitForChild("SpawnToyRemoteFunction")
local DestroyToy             = MenuToys:WaitForChild("DestroyToy")
local BuyToyRemoteFunction   = MenuToys:WaitForChild("BuyToyRemoteFunction")

local CreateGrabLine   = GrabEvents:WaitForChild("CreateGrabLine")
local DestroyGrabLine  = GrabEvents:WaitForChild("DestroyGrabLine")
local SetNetworkOwner  = GrabEvents:WaitForChild("SetNetworkOwner")

local RagdollRemote    = CharacterEvents:WaitForChild("RagdollRemote")
local Struggle         = CharacterEvents:WaitForChild("Struggle")

local StickyPartEvent  = PlayerEvents:WaitForChild("StickyPartEvent")
local BombExplode      = BombEvents:WaitForChild("BombExplode")
local CreatureToss     = CreatureEvents:WaitForChild("CreatureToss")

-- ==========================================
-- 状態管理
-- ==========================================
local NabeHub = {
    Connections = {},
    State = {
        -- 攻撃
        DriftKick = false,
        UpDownKick = false,
        SpinKick = false,
        FastKick = false,
        BlobKickRLU = false,
        OwnershipKick = false,
        KickAll = false,
        AuraGrab = false,
        KillGrab = false,
        Fling = false,
        -- 防御
        AntiGrab = false,
        AntiRagdoll = false,
        AntiExplosion = false,
        AntiBurn = false,
        AntiVoid = false,
        AntiKick = false,
        AntiBlobman = false,
        AntiSticky = false,
        AntiPaint = false,
        AntiInputLag = false,
        AntiLag = false,
        Counter = false,
        GodMode = false,
        -- 掴み
        GrabPower = 750,
        MasslessGrab = false,
        FurtherReach = false,
        TriggerBot = false,
        SilentAim = false,
        Aimbot = false,
        -- 移動
        Speed = 16,
        SpeedEnabled = false,
        Jump = 50,
        JumpEnabled = false,
        InfJump = false,
        Fly = false,
        FlySpeed = 50,
        Noclip = false,
        BlobFly = false,
        WaterWalk = false,
        -- 視覚
        RainbowESP = false,
        NameESP = false,
        PCLDESP = false,
        ThirdPerson = false,
        CharSpin = false,
        FOV = 70,
        -- 便利
        AutoBlobman = false,
        AutoSpinSlot = false,
        PreserveHouse = false,
    },
    Blob = nil,
    BlobThread = nil,
    KickedPlayer = nil,
    Connections2 = {},
}

-- ==========================================
-- ユーティリティ
-- ==========================================
local function track(conn)
    table.insert(NabeHub.Connections, conn)
    return conn
end

local function notif(name, content)
    OrionLib:MakeNotification({
        Name = name,
        Content = content,
        Time = 4,
        Image = "rbxassetid://4384403532"
    })
end

local function getHRP(plr)
    plr = plr or LocalPlayer
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum(plr)
    plr = plr or LocalPlayer
    local char = plr.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getMyToys()
    return Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
end

local function getSeatedBlobman()
    local hum = getHum()
    if not hum then return nil end
    local seat = hum.SeatPart
    if seat and seat.Parent and seat.Parent.Name == "CreatureBlobman" then
        return seat.Parent
    end
    return nil
end

local function getMyBlobman()
    local toys = getMyToys()
    return toys and toys:FindFirstChild("CreatureBlobman")
end

local function isGrabbed()
    local char = LocalPlayer.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    if head and head:FindFirstChild("PartOwner") then return true end
    if LocalPlayer.IsHeld and LocalPlayer.IsHeld.Value then return true end
    return false
end

local function getClosestPlayer(range)
    range = range or 50
    local myHRP = getHRP()
    if not myHRP then return nil end
    local closest, dist = nil, range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local hrp = getHRP(plr)
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < dist then
                    closest, dist = plr, d
                end
            end
        end
    end
    return closest
end

local function getPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.DisplayName .. " (@" .. plr.Name .. ")")
        end
    end
    return list
end

local function getPlayerFromSelection(sel)
    if not sel then return nil end
    local name = sel:match("@(.-)%)")
    return name and Players:FindFirstChild(name) or nil
end

local function spawnToy(toyName, cf)
    if not LocalPlayer.CanSpawnToy or not LocalPlayer.CanSpawnToy.Value then
        notif("なべHub", "スポーン不可")
        return nil
    end
    local myHRP = getHRP()
    cf = cf or (myHRP and myHRP.CFrame) or CFrame.new(0, 0, 0)
    pcall(function()
        SpawnToyRemoteFunction:InvokeServer(toyName, cf, Vector3.new(0, 0, 0))
    end)
    task.wait(0.35)
    return getMyToys() and getMyToys():FindFirstChild(toyName)
end

-- ブロブマン自動スポーン
local function ensureBlobman()
    local existing = getSeatedBlobman()
    if existing then
        NabeHub.Blob = existing
        return existing
    end

    local myBlob = getMyBlobman()
    if myBlob then
        local hum = getHum()
        if hum then
            local seat = myBlob:FindFirstChild("VehicleSeat")
            if seat then
                pcall(function() seat:Sit(hum) end)
                task.wait(0.2)
            end
        end
        NabeHub.Blob = myBlob
        return myBlob
    end

    local myHRP = getHRP()
    if not myHRP then return nil end

    pcall(function()
        SpawnToyRemoteFunction:InvokeServer("CreatureBlobman", myHRP.CFrame * CFrame.new(0, 0, -5), Vector3.new(0, 127, 0))
    end)
    task.wait(0.5)

    local blob = getMyBlobman()
    if blob then
        local hum = getHum()
        if hum then
            local seat = blob:FindFirstChild("VehicleSeat")
            if seat then
                pcall(function() seat:Sit(hum) end)
                task.wait(0.2)
            end
        end
        NabeHub.Blob = blob
        return blob
    end
    return nil
end

-- ブロブマンキックの共通プリミティブ
local function blobKickPattern(patternFn)
    local target = NabeHub.KickedPlayer
    if not target then
        notif("なべHub", "ターゲット未選択")
        return
    end
    local blob = ensureBlobman()
    if not blob then
        notif("なべHub", "ブロブマン取得失敗")
        return
    end

    local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
    if not blobRoot then return end

    local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
    local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
    local R_Det = blob:FindFirstChild("RightDetector")
    local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
    local SavedPos = blobRoot.CFrame

    local tChar = target.Character
    local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end

    -- 掴みフェーズ
    local bringStart = tick()
    while tick() - bringStart < 0.3 do
        blobRoot.CFrame = tRoot.CFrame
        blobRoot.Velocity = Vector3.zero
        pcall(function()
            if CG and R_Det then CG:FireServer(R_Det, tRoot, R_Weld) end
            CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
            SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame)
        end)
        RunService.Heartbeat:Wait()
    end
    blobRoot.CFrame = SavedPos
    blobRoot.Velocity = Vector3.zero
    task.wait(0.05)

    -- キックフェーズ（patternFnがCFrameを返す）
    local t = 0
    local packetTimer = 0
    while true do
        if not target.Parent or not target.Character then break end
        local curBlob = getSeatedBlobman()
        if not curBlob or curBlob ~= blob then break end

        tChar = target.Character
        tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local tHum = tChar and tChar:FindFirstChild("Humanoid")
        if not tRoot or not tHum or tHum.Health <= 0 then break end

        local dt = RunService.Heartbeat:Wait()
        t = t + dt

        blobRoot.CFrame = SavedPos
        blobRoot.Velocity = Vector3.zero

        local lockPos = patternFn(SavedPos, t, tRoot)
        if lockPos then
            tRoot.CFrame = lockPos
            tRoot.Velocity = Vector3.zero
            tRoot.RotVelocity = Vector3.zero

            if tick() - packetTimer > 0.05 then
                packetTimer = tick()
                pcall(function()
                    tHum.PlatformStand = true
                    tHum.Sit = true
                    SetNetworkOwner:FireServer(tRoot, lockPos)
                    if R_Det then
                        local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                        if weld and CD then CD:FireServer(weld) end
                    end
                    DestroyGrabLine:FireServer(tRoot)
                    if CG and R_Det then CG:FireServer(R_Det, tRoot, R_Weld) end
                    CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false)
                end)
            end
        end
    end

    blobRoot.CFrame = SavedPos
    blobRoot.Velocity = Vector3.zero
end

-- ==========================================
-- ウィンドウ
-- ==========================================
OrionLib:Init()

local Window = OrionLib:MakeWindow({
    Name = "なべHub | hvhスクリプト",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "なべHub 起動中...",
    ConfigFolder = "NabeHub",
    ShowIcon = false,
})

-- ==========================================
-- 攻撃タブ
-- ==========================================
local AttackTab = Window:MakeTab({
    Name = "攻撃",
    Icon = "rbxassetid://4483362458",
})

-- ターゲット選択
AttackTab:AddSection({ Name = "ターゲット" })

local targetDropdown = AttackTab:AddDropdown({
    Name = "ターゲット選択",
    Default = "",
    Options = getPlayerList(),
    Callback = function(v)
        NabeHub.KickedPlayer = getPlayerFromSelection(v)
    end
})

AttackTab:AddButton({
    Name = "リスト更新",
    Callback = function()
        targetDropdown:Refresh(getPlayerList(), true)
    end
})

-- キック系
AttackTab:AddSection({ Name = "キック" })

AttackTab:AddButton({
    Name = "ドリフトキック (開始/停止)",
    Callback = function()
        NabeHub.State.DriftKick = not NabeHub.State.DriftKick
        if not NabeHub.State.DriftKick then
            notif("なべHub", "ドリフトキック停止")
            return
        end
        notif("なべHub", "ドリフトキック開始")
        task.spawn(function()
            local angle = 0
            local radius = 19
            local speed = 8.5
            blobKickPattern(function(saved, t, tRoot)
                if not NabeHub.State.DriftKick then return nil end
                angle = angle + 0.016 * speed
                local center = saved * CFrame.new(0, 23, 0)
                local pos = center.Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                return CFrame.new(pos, center.Position)
            end)
        end)
    end
})

AttackTab:AddButton({
    Name = "上下キック (開始/停止)",
    Callback = function()
        NabeHub.State.UpDownKick = not NabeHub.State.UpDownKick
        if not NabeHub.State.UpDownKick then
            notif("なべHub", "上下キック停止")
            return
        end
        task.spawn(function()
            blobKickPattern(function(saved, t, tRoot)
                if not NabeHub.State.UpDownKick then return nil end
                local phase = math.floor(t / 0.05) % 2
                local y = (phase == 0) and 12 or -5
                return saved * CFrame.new(0, y, -5)
            end)
        end)
    end
})

AttackTab:AddButton({
    Name = "スピンキック (開始/停止)",
    Callback = function()
        NabeHub.State.SpinKick = not NabeHub.State.SpinKick
        if not NabeHub.State.SpinKick then
            notif("なべHub", "スピンキック停止")
            return
        end
        task.spawn(function()
            local angle = 0
            blobKickPattern(function(saved, t, tRoot)
                if not NabeHub.State.SpinKick then return nil end
                angle = angle + 0.3
                local dist = 8
                local pos = saved.Position + Vector3.new(math.sin(angle) * dist, 0, math.cos(angle) * dist)
                return CFrame.new(pos)
            end)
        end)
    end
})

AttackTab:AddButton({
    Name = "高速キック (開始/停止)",
    Callback = function()
        NabeHub.State.FastKick = not NabeHub.State.FastKick
        if not NabeHub.State.FastKick then
            notif("なべHub", "高速キック停止")
            return
        end
        task.spawn(function()
            local idx = 0
            blobKickPattern(function(saved, t, tRoot)
                if not NabeHub.State.FastKick then return nil end
                idx = 1 - idx
                if idx == 0 then
                    return saved * CFrame.new(5, 18, -3)
                else
                    return saved * CFrame.new(-5, 18, -3)
                end
            end)
        end)
    end
})

AttackTab:AddButton({
    Name = "ブロブキック 右→左→上 (開始/停止)",
    Callback = function()
        NabeHub.State.BlobKickRLU = not NabeHub.State.BlobKickRLU
        if not NabeHub.State.BlobKickRLU then
            notif("なべHub", "ブロブキック停止")
            return
        end
        task.spawn(function()
            local blob = getSeatedBlobman()
            local idx = 0
            blobKickPattern(function(saved, t, tRoot)
                if not NabeHub.State.BlobKickRLU then return nil end
                idx = math.floor(t / 0.08) % 3
                if idx == 0 then
                    local rh = blob and blob:FindFirstChild("RightHand")
                    if rh then return CFrame.new(rh.Position + Vector3.new(0, 2, 0)) end
                elseif idx == 1 then
                    local lh = blob and blob:FindFirstChild("LeftHand")
                    if lh then return CFrame.new(lh.Position + Vector3.new(0, 2, 0)) end
                else
                    return CFrame.new(saved.X + math.random(-2, 2), 50 + math.random(0, 20), saved.Z + math.random(-2, 2))
                end
                return saved * CFrame.new(0, 20, 0)
            end)
        end)
    end
})

-- Ownership Kick
AttackTab:AddButton({
    Name = "Ownership Kick (開始/停止)",
    Callback = function()
        NabeHub.State.OwnershipKick = not NabeHub.State.OwnershipKick
        if not NabeHub.State.OwnershipKick then
            notif("なべHub", "Ownership Kick 停止")
            return
        end
        local target = NabeHub.KickedPlayer
        if not target then
            notif("なべHub", "ターゲット未選択")
            NabeHub.State.OwnershipKick = false
            return
        end
        notif("なべHub", "Ownership Kick 開始")
        task.spawn(function()
            local myHRP = getHRP()
            if not myHRP then NabeHub.State.OwnershipKick = false return end
            local savedPos = myHRP.CFrame
            local dragging = false
            local grabStart = 0

            while NabeHub.State.OwnershipKick do
                if not target.Parent or not target.Character then break end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local tHum = target.Character:FindFirstChild("Humanoid")
                if not tRoot or not tHum or tHum.Health <= 0 then break end

                if not dragging then
                    myHRP.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
                    myHRP.Velocity = Vector3.zero
                    pcall(function()
                        tHum.PlatformStand = true
                        tHum.Sit = true
                        SetNetworkOwner:FireServer(tRoot, tRoot.CFrame)
                        SetNetworkOwner:FireServer(tRoot, tRoot.CFrame)
                        DestroyGrabLine:FireServer(tRoot)
                    end)
                    if grabStart == 0 then grabStart = tick() end
                    if tick() - grabStart > 0.15 then
                        dragging = true
                        grabStart = 0
                    end
                else
                    myHRP.CFrame = savedPos
                    local lockPos = savedPos * CFrame.new(5, 20, 4)
                    myHRP.Velocity = Vector3.zero
                    tRoot.CFrame = lockPos
                    tRoot.Velocity = Vector3.zero
                    tHum.PlatformStand = true
                    pcall(function()
                        SetNetworkOwner:FireServer(tRoot, lockPos)
                        SetNetworkOwner:FireServer(tRoot, lockPos)
                        DestroyGrabLine:FireServer(tRoot)
                    end)
                end
                RunService.Heartbeat:Wait()
            end
            if myHRP then myHRP.CFrame = savedPos end
        end)
    end
})

-- キックオール
AttackTab:AddSection({ Name = "キックオール" })

AttackTab:AddDropdown({
    Name = "高さモード",
    Default = "Spawn (地上)",
    Options = {"Spawn (地上)", "Heaven (天国)"},
    Callback = function(v)
        NabeHub.KickAllHeight = (v == "Heaven (天国)") and 1e9 or 35
    end
})
NabeHub.KickAllHeight = 35

local kickAllLagEnabled = false
local kickAllLagThread = nil

local function startKickAllLag()
    if kickAllLagEnabled then return end
    kickAllLagEnabled = true
    kickAllLagThread = task.spawn(function()
        while kickAllLagEnabled do
            local spawnLoc = Workspace:FindFirstChild("SpawnLocation") or getHRP()
            if spawnLoc then
                local rx = math.random(-1e9, 1e9)
                local rz = math.random(-1e9, 1e9)
                pcall(function()
                    CreateGrabLine:FireServer(spawnLoc, CFrame.new(rx, 0, rz))
                end)
            end
            task.wait()
        end
    end)
end

local function stopKickAllLag()
    kickAllLagEnabled = false
    if kickAllLagThread then
        task.cancel(kickAllLagThread)
        kickAllLagThread = nil
    end
end

AttackTab:AddButton({
    Name = "キックオール実行",
    Callback = function()
        task.spawn(function()
            local height = NabeHub.KickAllHeight
            startKickAllLag()
            task.wait(1)

            local myHRP = getHRP()
            if not myHRP then stopKickAllLag() return end

            local players = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local hrp = getHRP(plr)
                    if hrp then table.insert(players, {player = plr, hrp = hrp}) end
                end
            end

            if #players == 0 then
                stopKickAllLag()
                notif("なべHub", "対象なし")
                return
            end

            -- 全員TP
            for _, data in ipairs(players) do
                myHRP.CFrame = data.hrp.CFrame * CFrame.new(0, 5, 5)
                myHRP.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.15)
                for i = 1, 5 do
                    pcall(function() SetNetworkOwner:FireServer(data.hrp, data.hrp.CFrame) end)
                end
                task.wait(0.05)
            end

            -- 円形配置
            local radius = 40
            local angleStep = (math.pi * 2) / #players
            for idx, data in ipairs(players) do
                local angle = (idx - 1) * angleStep
                local x = math.cos(angle) * radius
                local z = math.sin(angle) * radius
                pcall(function()
                    data.hrp.CFrame = CFrame.new(x, height, z)
                    data.hrp.AssemblyLinearVelocity = Vector3.zero
                end)
                local bp = Instance.new("BodyPosition")
                bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bp.P = 40000000
                bp.Position = Vector3.new(x, height, z)
                bp.Parent = data.hrp
                task.delay(2, function() pcall(function() bp:Destroy() end) end)
                task.wait()
            end

            -- GrabLine破壊
            for i = 1, 8 do
                for _, data in ipairs(players) do
                    pcall(function()
                        CreateGrabLine:FireServer(data.hrp, CFrame.new(0, 1e9, 0))
                        task.wait()
                        DestroyGrabLine:FireServer(data.hrp)
                    end)
                end
                task.wait(0.3)
            end

            notif("なべHub", "キックオール完了（ラグ継続中）")
        end)
    end
})

AttackTab:AddButton({
    Name = "キックオール ラグ停止",
    Callback = function()
        stopKickAllLag()
        notif("なべHub", "ラグ停止")
    end
})

-- オーラで掴む
AttackTab:AddSection({ Name = "オーラ" })

local auraGrabbed = {}
local MAX_AURA = 5
local AURA_RADIUS = 8
local AURA_SEARCH = 15
local auraThread = nil

local function updateAuraPositions()
    local myHRP = getHRP()
    if not myHRP then return end
    local count = #auraGrabbed
    for i, info in ipairs(auraGrabbed) do
        if info.active then
            local angle = (i - 1) / math.max(count, 1) * math.pi * 2
            local pos = myHRP.Position + Vector3.new(math.cos(angle) * AURA_RADIUS, 5, math.sin(angle) * AURA_RADIUS)
            info.grabPos = CFrame.new(pos)
        end
    end
end

AttackTab:AddToggle({
    Name = "オーラで掴む（最大5人）",
    Default = false,
    Callback = function(v)
        NabeHub.State.AuraGrab = v
        if v then
            auraGrabbed = {}
            auraThread = task.spawn(function()
                while NabeHub.State.AuraGrab do
                    local myHRP = getHRP()
                    if myHRP then
                        -- 追加
                        if #auraGrabbed < MAX_AURA then
                            local grabbedNames = {}
                            for _, info in ipairs(auraGrabbed) do
                                if info.player then grabbedNames[info.player.Name] = true end
                            end
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and not grabbedNames[plr.Name] then
                                    local hrp = getHRP(plr)
                                    if hrp and (hrp.Position - myHRP.Position).Magnitude < AURA_SEARCH then
                                        table.insert(auraGrabbed, {
                                            player = plr,
                                            root = hrp,
                                            hum = getHum(plr),
                                            active = true,
                                            grabPos = hrp.CFrame,
                                        })
                                        if #auraGrabbed >= MAX_AURA then break end
                                    end
                                end
                            end
                        end

                        -- 位置更新
                        updateAuraPositions()

                        for _, info in ipairs(auraGrabbed) do
                            if info.active and info.root and info.root.Parent and info.hum and info.hum.Health > 0 then
                                info.root.CFrame = info.grabPos
                                info.root.Velocity = Vector3.zero
                                info.root.RotVelocity = Vector3.zero
                                pcall(function()
                                    info.hum.PlatformStand = true
                                    info.hum.Sit = true
                                    SetNetworkOwner:FireServer(info.root, info.grabPos)
                                end)
                            else
                                info.active = false
                            end
                        end

                        -- クリーンアップ
                        local newList = {}
                        for _, info in ipairs(auraGrabbed) do
                            if info.active and info.root and info.root.Parent then
                                table.insert(newList, info)
                            end
                        end
                        auraGrabbed = newList
                    end
                    RunService.Heartbeat:Wait()
                end
                -- 解放
                for _, info in ipairs(auraGrabbed) do
                    if info.hum then
                        pcall(function()
                            info.hum.PlatformStand = false
                            info.hum.Sit = false
                        end)
                    end
                end
                auraGrabbed = {}
            end)
            notif("なべHub", "オーラ掴み開始")
        else
            notif("なべHub", "オーラ掴み停止")
        end
    end
})

-- キル掴み
AttackTab:AddSection({ Name = "掴み攻撃" })

AttackTab:AddToggle({
    Name = "キル掴み",
    Default = false,
    Callback = function(v)
        NabeHub.State.KillGrab = v
        if v then
            notif("なべHub", "キル掴み ON")
        else
            notif("なべHub", "キル掴み OFF")
        end
    end
})

track(Workspace.ChildAdded:Connect(function(v)
    if v.Name == "GrabParts" and NabeHub.State.KillGrab then
        task.wait(0.05)
        local grabPart = v:FindFirstChild("GrabPart")
        if grabPart and grabPart:FindFirstChild("WeldConstraint") then
            local part1 = grabPart.WeldConstraint.Part1
            if part1 and part1.Parent and part1.Parent ~= LocalPlayer.Character then
                local targetChar = part1.Parent
                local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                if targetHum then
                    pcall(function()
                        targetHum.Health = 0
                        targetChar:BreakJoints()
                    end)
                end
            end
        end
    end
end))

-- フリング
AttackTab:AddSection({ Name = "フリング" })

AttackTab:AddButton({
    Name = "フリング (開始/停止)",
    Callback = function()
        NabeHub.State.Fling = not NabeHub.State.Fling
        local target = NabeHub.KickedPlayer
        if NabeHub.State.Fling and not target then
            notif("なべHub", "ターゲット未選択")
            NabeHub.State.Fling = false
            return
        end
        if not NabeHub.State.Fling then
            notif("なべHub", "フリング停止")
            return
        end
        notif("なべHub", "フリング開始")
        task.spawn(function()
            local myHRP = getHRP()
            if not myHRP then NabeHub.State.Fling = false return end
            local bav = Instance.new("BodyAngularVelocity")
            bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bav.AngularVelocity = Vector3.new(0, 10000, 0)
            bav.P = 10000
            bav.Parent = myHRP

            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end

            while NabeHub.State.Fling do
                if not target.Parent or not target.Character then break end
                local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if not tRoot then break end
                myHRP.CFrame = tRoot.CFrame
                myHRP.Velocity = Vector3.zero
                RunService.Heartbeat:Wait()
            end

            bav:Destroy()
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end)
    end
})

-- プロット破壊
AttackTab:AddSection({ Name = "プロット破壊" })

local plotShurikens = {}
local plotBreakEnabled = false
local selectedPlots = {}

AttackTab:AddDropdown({
    Name = "プロット選択",
    Default = {},
    Options = {"Plot1", "Plot2", "Plot3", "Plot4", "Plot5"},
    Multi = true,
    Callback = function(opts)
        selectedPlots = {}
        for _, o in pairs(opts) do
            table.insert(selectedPlots, o)
        end
    end
})

local function cleanupPlotShurikens()
    for _, s in pairs(plotShurikens) do
        if s and s.Parent then
            pcall(function() DestroyToy:FireServer(s) end)
        end
    end
    plotShurikens = {}
end

AttackTab:AddToggle({
    Name = "プロット破壊実行",
    Default = false,
    Callback = function(v)
        plotBreakEnabled = v
        if not v then
            cleanupPlotShurikens()
            notif("なべHub", "プロット破壊停止")
            return
        end
        notif("なべHub", "プロット破壊開始")
        task.spawn(function()
            while plotBreakEnabled do
                if #selectedPlots == 0 then task.wait(1) continue end

                local validPlots = {}
                for _, name in ipairs(selectedPlots) do
                    local plot = Workspace.Plots:FindFirstChild(name)
                    local area = plot and plot:FindFirstChild("PlotArea")
                    if area then
                        table.insert(validPlots, area)
                    end
                end

                if #validPlots == 0 then task.wait(1) continue end

                -- 自分の所有プロット判定
                local inOwned = false
                for _, plot in ipairs(Workspace.Plots:GetChildren()) do
                    local sign = plot:FindFirstChild("PlotSign")
                    local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                    if owners then
                        for _, o in ipairs(owners:GetChildren()) do
                            if o.Value == LocalPlayer.Name then
                                inOwned = true
                                break
                            end
                        end
                    end
                end

                local container
                if inOwned then
                    container = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                else
                    container = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                end

                if not container then task.wait(0.5) continue end

                -- 手裏剣を必要数スポーン
                local needed = #validPlots
                local current = 0
                for _, s in pairs(plotShurikens) do
                    if s and s.Parent then current = current + 1 end
                end

                if current < needed then
                    local myHRP = getHRP()
                    if myHRP then
                        pcall(function()
                            SpawnToyRemoteFunction:InvokeServer("NinjaShuriken", myHRP.CFrame * CFrame.new(0, 2, 8), Vector3.zero)
                        end)
                        task.wait(0.3)
                        local newShuriken = container:FindFirstChild("NinjaShuriken")
                        if newShuriken and not table.find(plotShurikens, newShuriken) then
                            table.insert(plotShurikens, newShuriken)
                            local soundPart = newShuriken:FindFirstChild("SoundPart")
                            if soundPart then
                                pcall(function() SetNetworkOwner:FireServer(soundPart, soundPart.CFrame) end)
                            end
                            local targetArea = validPlots[#plotShurikens]
                            local sticky = newShuriken:FindFirstChild("StickyPart")
                            if sticky and targetArea then
                                pcall(function()
                                    StickyPartEvent:FireServer(sticky, targetArea, CFrame.new(1e12, 1e12, 1e12))
                                end)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
            cleanupPlotShurikens()
        end)
    end
})
-- ==========================================
-- 防御タブ
-- ==========================================
local DefenseTab = Window:MakeTab({
    Name = "防御",
    Icon = "rbxassetid://4483362458",
})

-- ==========================================
-- アンチ掴み
-- ==========================================
DefenseTab:AddSection({ Name = "基本防御" })

local antiGrabThread = nil
DefenseTab:AddToggle({
    Name = "アンチ掴み",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiGrab = v
        if v then
            if antiGrabThread then task.cancel(antiGrabThread) end
            antiGrabThread = task.spawn(function()
                while NabeHub.State.AntiGrab do
                    local char = LocalPlayer.Character
                    if char then
                        local head = char:FindFirstChild("Head")
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if head and head:FindFirstChild("PartOwner") and hrp and hum then
                            task.spawn(function()
                                for i = 1, 15 do
                                    pcall(function() Struggle:FireServer() end)
                                end
                                pcall(function() RagdollRemote:FireServer(hrp, 0) end)
                                local savedPos = hrp.CFrame
                                hrp.Anchored = true
                                local isHeld = LocalPlayer:FindFirstChild("IsHeld")
                                while isHeld and isHeld.Value and NabeHub.State.AntiGrab do
                                    hrp.CFrame = savedPos
                                    pcall(function() Struggle:FireServer() end)
                                    task.wait()
                                end
                                hrp.Anchored = false
                            end)
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
            notif("なべHub", "アンチ掴み ON")
        else
            notif("なべHub", "アンチ掴み OFF")
        end
    end
})

-- アンチラグドール
DefenseTab:AddToggle({
    Name = "アンチラグドール",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiRagdoll = v
        if v then
            notif("なべHub", "アンチラグドール ON")
        else
            notif("なべHub", "アンチラグドール OFF")
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.AntiRagdoll then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local rag = hum:FindFirstChild("Ragdolled")
    if rag and rag.Value then
        pcall(function() RagdollRemote:FireServer(char:FindFirstChild("HumanoidRootPart"), 0) end)
        hum.PlatformStand = false
    end
end))

-- アンチ爆発
DefenseTab:AddToggle({
    Name = "アンチ爆発",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiExplosion = v
        if v then
            notif("なべHub", "アンチ爆発 ON")
        else
            notif("なべHub", "アンチ爆発 OFF")
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.AntiExplosion then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local rag = hum:FindFirstChild("Ragdolled")
    if rag and rag.Value then
        hrp.Anchored = true
        task.wait(0.01)
        hrp.Anchored = false
        pcall(function() RagdollRemote:FireServer(hrp, 0) end)
    end
end))

-- アンチ炎上
local ExtinguishPart = Workspace:FindFirstChild("Map")
    and Workspace.Map:FindFirstChild("Hole")
    and Workspace.Map.Hole:FindFirstChild("PoisonBigHole")
    and Workspace.Map.Hole.PoisonBigHole:FindFirstChild("ExtinguishPart")
local extinguishOriginal = ExtinguishPart and ExtinguishPart.CFrame

DefenseTab:AddToggle({
    Name = "アンチ炎上",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiBurn = v
        if v then
            notif("なべHub", "アンチ炎上 ON")
        else
            if ExtinguishPart and extinguishOriginal then
                ExtinguishPart.CFrame = extinguishOriginal
            end
            notif("なべHub", "アンチ炎上 OFF")
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.AntiBurn then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local firePart = hrp:FindFirstChild("FirePlayerPart")
    local isBurning = firePart and firePart:FindFirstChild("CanBurn") and firePart.CanBurn.Value
    if isBurning and ExtinguishPart then
        ExtinguishPart.CFrame = hrp.CFrame
    elseif ExtinguishPart and extinguishOriginal and not isBurning then
        ExtinguishPart.CFrame = extinguishOriginal
    end
end))

-- アンチ落下
DefenseTab:AddToggle({
    Name = "アンチ落下",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiVoid = v
        if v then
            Workspace.FallenPartsDestroyHeight = -99999
            notif("なべHub", "アンチ落下 ON")
        else
            Workspace.FallenPartsDestroyHeight = -100
            notif("なべHub", "アンチ落下 OFF")
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.AntiVoid then return end
    local hrp = getHRP()
    if hrp and hrp.Position.Y < -80 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end))

-- ==========================================
-- アンチキック系
-- ==========================================
DefenseTab:AddSection({ Name = "アンチキック" })

-- アンチキック（手裏剣）
local antiKickThread = nil
local function clearAntiKickKunai()
    local inv = getMyToys()
    if inv then
        for _, v in ipairs(inv:GetChildren()) do
            if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then
                pcall(function() DestroyToy:FireServer(v) end)
            end
        end
    end
end

DefenseTab:AddToggle({
    Name = "アンチキック（手裏剣）",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiKick = v
        if v then
            antiKickThread = task.spawn(function()
                while NabeHub.State.AntiKick do
                    task.wait(0.05)
                    local char = LocalPlayer.Character
                    if not char then task.wait(0.5) continue end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hum or not hrp then task.wait(0.5) continue end

                    local inv = getMyToys()
                    if not inv then task.wait(0.5) continue end

                    local kunai = inv:FindFirstChild("AntiKick") or inv:FindFirstChild("NinjaShuriken")

                    -- 家の中なら一旦スキップ
                    local inPlot = LocalPlayer:FindFirstChild("InPlot")
                    if inPlot and inPlot.Value then
                        if kunai then
                            pcall(function() DestroyToy:FireServer(kunai) end)
                        end
                        task.wait(0.5)
                        continue
                    end

                    if not kunai then
                        local canSpawn = LocalPlayer:FindFirstChild("CanSpawnToy")
                        if canSpawn and canSpawn.Value then
                            pcall(function()
                                SpawnToyRemoteFunction:InvokeServer("NinjaShuriken", hrp.CFrame * CFrame.new(0, 12, 20), Vector3.zero)
                            end)
                            task.wait(0.4)
                            kunai = inv:FindFirstChild("NinjaShuriken")
                            if kunai then
                                kunai.Name = "AntiKick"
                            end
                        end
                    end

                    if kunai then
                        local sticky = kunai:FindFirstChild("StickyPart")
                        local soundPart = kunai:FindFirstChild("SoundPart")
                        if sticky and soundPart then
                            -- 所有権
                            if not soundPart:FindFirstChild("PartOwner") or soundPart.PartOwner.Value ~= LocalPlayer.Name then
                                pcall(function() SetNetworkOwner:FireServer(soundPart, soundPart.CFrame) end)
                            end

                            -- 装着
                            local firePart = hrp:FindFirstChild("FirePlayerPart")
                            if firePart then
                                local weld = sticky:FindFirstChild("StickyWeld")
                                if not weld or not weld.Part1 then
                                    pcall(function()
                                        StickyPartEvent:FireServer(sticky, firePart, CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)))
                                    end)
                                elseif weld.Part1 ~= firePart then
                                    pcall(function()
                                        StickyPartEvent:FireServer(sticky, firePart, CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), math.rad(90)))
                                    end)
                                end
                            end

                            -- 見た目隠し
                            for _, obj in ipairs(kunai:GetChildren()) do
                                if obj:IsA("BasePart") then
                                    obj.CanTouch = false
                                    obj.CanCollide = false
                                    obj.CanQuery = false
                                    obj.Transparency = 1
                                end
                            end
                        end
                    end
                    task.wait(0.3)
                end
                clearAntiKickKunai()
            end)
            notif("なべHub", "アンチキック ON")
        else
            if antiKickThread then
                task.cancel(antiKickThread)
                antiKickThread = nil
            end
            clearAntiKickKunai()
            notif("なべHub", "アンチキック OFF")
        end
    end
})

-- アンチブロブマン（検出器破壊）
local antiBlobmanConn = nil
DefenseTab:AddToggle({
    Name = "アンチブロブマン",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiBlobman = v
        if v then
            if antiBlobmanConn then antiBlobmanConn:Disconnect() end
            antiBlobmanConn = Workspace.DescendantAdded:Connect(function(obj)
                if not NabeHub.State.AntiBlobman then return end
                if obj.Name == "CreatureBlobman" then
                    task.wait(0.1)
                    local l = obj:FindFirstChild("LeftDetector")
                    local r = obj:FindFirstChild("RightDetector")
                    if l then l:Destroy() end
                    if r then r:Destroy() end
                end
            end)
            notif("なべHub", "アンチブロブマン ON")
        else
            if antiBlobmanConn then
                antiBlobmanConn:Disconnect()
                antiBlobmanConn = nil
            end
            notif("なべHub", "アンチブロブマン OFF")
        end
    end
})

-- アンチスティッキー
DefenseTab:AddToggle({
    Name = "アンチスティッキー",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiSticky = v
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if ps then
            local script = ps:FindFirstChild("StickyPartsTouchDetection")
            if script then
                script.Disabled = v
            end
        end
        notif("なべHub", "アンチスティッキー " .. (v and "ON" or "OFF"))
    end
})

-- アンチペイント
local paintBackup = {}
local paintWatchers = {}

local function deleteAllPaint()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then
            local clone = obj:Clone()
            clone.Archivable = true
            paintBackup[obj:GetDebugId()] = { clone = clone, parent = obj.Parent }
            obj:Destroy()
        end
    end
end

local function restorePaint()
    for _, data in pairs(paintBackup) do
        if data.clone and data.parent then
            data.clone.Parent = data.parent
        end
    end
    paintBackup = {}
end

local function watchPaint()
    table.insert(paintWatchers, Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name == "PaintPlayerPart" then
            task.defer(function()
                if obj and obj.Parent then
                    local clone = obj:Clone()
                    clone.Archivable = true
                    paintBackup[obj:GetDebugId()] = { clone = clone, parent = obj.Parent }
                    obj:Destroy()
                end
            end)
        end
    end))
end

local function disconnectPaintWatchers()
    for _, c in ipairs(paintWatchers) do
        pcall(function() c:Disconnect() end)
    end
    paintWatchers = {}
end

DefenseTab:AddToggle({
    Name = "アンチペイント",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiPaint = v
        if v then
            deleteAllPaint()
            watchPaint()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanTouch = false
                        p.CanQuery = false
                    end
                end
            end
            notif("なべHub", "アンチペイント ON")
        else
            restorePaint()
            disconnectPaintWatchers()
            notif("なべHub", "アンチペイント OFF")
        end
    end
})

-- アンチ入力ラグ
local antiInputLagThread = nil
DefenseTab:AddToggle({
    Name = "アンチ入力ラグ",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiInputLag = v
        if not v then
            if antiInputLagThread then
                task.cancel(antiInputLagThread)
                antiInputLagThread = nil
            end
            notif("なべHub", "アンチ入力ラグ OFF")
            return
        end
        notif("なべHub", "アンチ入力ラグ ON")
        antiInputLagThread = task.spawn(function()
            while NabeHub.State.AntiInputLag do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- 掴まれているアイテムを探す
                    for _, obj in ipairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj:FindFirstChild("HoldPart") then
                            local holdPart = obj.HoldPart
                            local holding = holdPart:FindFirstChild("HoldingPlayer")
                            if holding and holding.Value and holding.Value ~= LocalPlayer then
                                pcall(function()
                                    local dropFunc = holdPart:FindFirstChild("DropItemRemoteFunction")
                                    if dropFunc then
                                        dropFunc:InvokeServer(obj, CFrame.new(0, 2000, 0), Vector3.zero)
                                    end
                                end)
                                task.wait(0.05)
                                pcall(function() DestroyToy:FireServer(obj) end)
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
})

-- アンチラグ
local grabBackup = {}
DefenseTab:AddToggle({
    Name = "アンチラグ",
    Default = false,
    Callback = function(v)
        NabeHub.State.AntiLag = v
        if v then
            -- CreateGrabLine / ExtendGrabLine を退避して破壊
            local create = GrabEvents:FindFirstChild("CreateGrabLine")
            local extend = GrabEvents:FindFirstChild("ExtendGrabLine")
            if create then grabBackup.create = create:Clone() create:Destroy() end
            if extend then grabBackup.extend = extend:Clone() extend:Destroy() end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Beam") then obj:Destroy() end
            end
            notif("なべHub", "アンチラグ ON")
        else
            if grabBackup.create and not GrabEvents:FindFirstChild("CreateGrabLine") then
                grabBackup.create:Clone().Parent = GrabEvents
            end
            if grabBackup.extend and not GrabEvents:FindFirstChild("ExtendGrabLine") then
                grabBackup.extend:Clone().Parent = GrabEvents
            end
            grabBackup = {}
            notif("なべHub", "アンチラグ OFF")
        end
    end
})

-- ==========================================
-- カウンター
-- ==========================================
DefenseTab:AddSection({ Name = "カウンター" })

NabeHub.State.CounterMode = "Fling"
NabeHub.State.Counter = false

DefenseTab:AddDropdown({
    Name = "カウンターモード",
    Default = "Fling",
    Options = {"Fling", "Kill", "Heaven", "Ragdoll"},
    Callback = function(v)
        NabeHub.State.CounterMode = v
    end
})

local function performCounter(attacker)
    if not attacker or not attacker.Character then return end
    local tRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    pcall(function()
        SetNetworkOwner:FireServer(tRoot, tRoot.CFrame)
        DestroyGrabLine:FireServer(tRoot)

        local mode = NabeHub.State.CounterMode
        if mode == "Fling" then
            local away = (tRoot.Position - (getHRP() and getHRP().Position or tRoot.Position)).Unit
            away = Vector3.new(away.X, 0.5, away.Z) * 90000
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Velocity = away
            bv.Parent = tRoot
            game:GetService("Debris"):AddItem(bv, 0.05)
        elseif mode == "Kill" then
            local hum = attacker.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.BreakJointsOnDeath = false
                hum:ChangeState(Enum.HumanoidStateType.Dead)
            end
        elseif mode == "Heaven" then
            tRoot.CFrame = CFrame.new(0, 999999, 0)
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, 1e6, 0)
            bv.Parent = tRoot
            game:GetService("Debris"):AddItem(bv, 0.1)
        elseif mode == "Ragdoll" then
            pcall(function() RagdollRemote:FireServer(tRoot, 5) end)
        end
    end)
end

DefenseTab:AddToggle({
    Name = "カウンター",
    Default = false,
    Callback = function(v)
        NabeHub.State.Counter = v
        if v then
            notif("なべHub", "カウンター ON")
        else
            notif("なべHub", "カウンター OFF")
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.Counter then return end
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local owner = head:FindFirstChild("PartOwner")
    if owner then
        local attacker = Players:FindFirstChild(owner.Value)
        if attacker and attacker ~= LocalPlayer then
            performCounter(attacker)
        end
    end
end))

-- ==========================================
-- 無敵
-- ==========================================
DefenseTab:AddSection({ Name = "無敵" })

DefenseTab:AddToggle({
    Name = "無敵（Godmode）",
    Default = false,
    Callback = function(v)
        NabeHub.State.GodMode = v
        if v then
            task.spawn(function()
                while NabeHub.State.GodMode do
                    local hrp = getHRP()
                    if hrp then
                        pcall(function() RagdollRemote:FireServer(hrp, 0) end)
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
            notif("なべHub", "無敵 ON")
        else
            notif("なべHub", "無敵 OFF")
        end
    end
})
-- ==========================================
-- 掴みタブ
-- ==========================================
local GrabTab = Window:MakeTab({
    Name = "掴み",
    Icon = "rbxassetid://4483362458",
})

GrabTab:AddSection({ Name = "掴み設定" })

GrabTab:AddSlider({
    Name = "掴みパワー",
    Min = 1,
    Max = 20000,
    Default = 750,
    Increment = 1,
    ValueName = "パワー",
    Callback = function(v)
        NabeHub.State.GrabPower = v
    end
})

-- 強度（右クリックで射出）
local strengthConn = nil
GrabTab:AddToggle({
    Name = "掴み強度（右クリックで射出）",
    Default = false,
    Callback = function(v)
        NabeHub.State.GrabStrength = v
        if strengthConn then strengthConn:Disconnect() strengthConn = nil end
        if not v then return end

        strengthConn = Workspace.ChildAdded:Connect(function(model)
            if model.Name ~= "GrabParts" then return end
            local grabPart = model:FindFirstChild("GrabPart")
            local weld = grabPart and grabPart:FindFirstChild("WeldConstraint")
            local target = weld and weld.Part1
            if not target then return end

            local bv = Instance.new("BodyVelocity", target)
            bv.MaxForce = Vector3.zero
            bv.Velocity = Vector3.zero

            model:GetPropertyChangedSignal("Parent"):Connect(function()
                if model.Parent then return end
                if UserInputService:GetLastInputType() == Enum.UserInputType.MouseButton2 then
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Camera.CFrame.LookVector * NabeHub.State.GrabPower
                    game:GetService("Debris"):AddItem(bv, 1)
                else
                    bv:Destroy()
                end
            end)
        end)
    end
})

-- Massless Grab
GrabTab:AddToggle({
    Name = "マスレス掴み",
    Default = false,
    Callback = function(v)
        NabeHub.State.MasslessGrab = v
        if v then
            notif("なべHub", "マスレス掴み ON")
        else
            notif("なべHub", "マスレス掴み OFF")
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.MasslessGrab then return end
    local gp = Workspace:FindFirstChild("GrabParts")
    if not gp then return end
    local dp = gp:FindFirstChild("DragPart")
    if not dp then return end
    local ap = dp:FindFirstChild("AlignPosition")
    local ao = dp:FindFirstChild("AlignOrientation")
    if ap then
        ap.Responsiveness = 200
        ap.MaxForce = math.huge
        ap.MaxVelocity = math.huge
    end
    if ao then
        ao.Responsiveness = 200
        ao.MaxTorque = math.huge
    end
end))

-- Further Reach（距離拡張）
GrabTab:AddToggle({
    Name = "リーチ拡張",
    Default = false,
    Callback = function(v)
        NabeHub.State.FurtherReach = v
        if v then
            pcall(function()
                local dataEvents = RS:FindFirstChild("DataEvents")
                if dataEvents then
                    dataEvents.UpdateLineColorsEvent:FireServer(ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 195)),
                    }))
                end
            end)
            pcall(function()
                local gp = RS:FindFirstChild("GamepassEvents")
                if gp then
                    local notifier = gp:FindFirstChild("FurtherReachBoughtNotifier")
                    if notifier then
                        for _, conn in pairs(getconnections(notifier.OnClientEvent)) do
                            for i in debug.getupvalues(conn.Function) do
                                debug.setupvalue(conn.Function, i, 30)
                            end
                        end
                    end
                end
            end)
            notif("なべHub", "リーチ拡張 ON")
        else
            notif("なべHub", "リーチ拡張 OFF")
        end
    end
})

-- ==========================================
-- トリガーボット
-- ==========================================
GrabTab:AddSection({ Name = "自動攻撃" })

local triggerEnabled = false
local triggerDist = 25
local triggerDelay = 0.05

GrabTab:AddToggle({
    Name = "トリガーボット",
    Default = false,
    Callback = function(v)
        NabeHub.State.TriggerBot = v
        if not v then return end
        task.spawn(function()
            while NabeHub.State.TriggerBot do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local closest = nil
                    local closestDist = math.huge
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer then
                            local tRoot = getHRP(plr)
                            if tRoot then
                                local d = (tRoot.Position - hrp.Position).Magnitude
                                if d <= triggerDist and d < closestDist then
                                    closest = plr
                                    closestDist = d
                                end
                            end
                        end
                    end
                    if closest then
                        local tRoot = getHRP(closest)
                        if tRoot then
                            pcall(function()
                                local mouse = LocalPlayer:GetMouse()
                                if mouse then
                                    mouse.TargetFilter = LocalPlayer.Character
                                end
                            end)
                            pcall(function()
                                if mouse1press then
                                    mouse1press()
                                    task.wait(0.05)
                                    mouse1release()
                                end
                            end)
                        end
                    end
                end
                task.wait(triggerDelay)
            end
        end)
    end
})

GrabTab:AddSlider({
    Name = "トリガー距離",
    Min = 5,
    Max = 50,
    Default = 25,
    Increment = 1,
    ValueName = "studs",
    Callback = function(v) triggerDist = v end
})

GrabTab:AddSlider({
    Name = "トリガー間隔",
    Min = 0.01,
    Max = 0.5,
    Default = 0.05,
    Increment = 0.01,
    ValueName = "秒",
    Callback = function(v) triggerDelay = v end
})

-- ==========================================
-- サイレントエイム
-- ==========================================
GrabTab:AddSection({ Name = "サイレントエイム" })

local silentEnabled = false
local silentMaxStuds = 40
local silentHitbox = "Head"

GrabTab:AddToggle({
    Name = "サイレントエイム",
    Default = false,
    Callback = function(v)
        NabeHub.State.SilentAim = v
        silentEnabled = v
        notif("なべHub", "サイレントエイム " .. (v and "ON" or "OFF"))
    end
})

GrabTab:AddSlider({
    Name = "最大補正距離",
    Min = 0,
    Max = 100,
    Default = 40,
    Increment = 1,
    ValueName = "studs",
    Callback = function(v) silentMaxStuds = v end
})

GrabTab:AddDropdown({
    Name = "ヒットボックス",
    Default = "Head",
    Options = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    Callback = function(v) silentHitbox = v end
})

-- サイレントエイム本体（hookmetamethod）
local function getSilentTarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, closestDist = nil, silentMaxStuds
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tPart = plr.Character:FindFirstChild(silentHitbox)
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if tPart and tRoot then
                local d = (tRoot.Position - hrp.Position).Magnitude
                if d <= closestDist then
                    closest = tPart
                    closestDist = d
                end
            end
        end
    end
    return closest
end

if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(...)
        local method = getnamecallmethod()
        local args = {...}
        if silentEnabled and method == "Raycast" and args[1] == Workspace then
            local target = getSilentTarget()
            if target then
                local origin = args[2]
                args[3] = (target.Position - origin).Unit * silentMaxStuds
                return oldNamecall(unpack(args))
            end
        end
        return oldNamecall(...)
    end)
end

-- ==========================================
-- エイムボット
-- ==========================================
GrabTab:AddSection({ Name = "エイムボット" })

local aimbotEnabled = false
local aimbotDist = 30
local aimbotSmooth = 0.5
local aimbotFOV = 100
local aimbotPart = "Head"
local aimbotKey = Enum.KeyCode.Q
local aimbotHolding = false

GrabTab:AddToggle({
    Name = "エイムボット",
    Default = false,
    Callback = function(v)
        NabeHub.State.Aimbot = v
        aimbotEnabled = v
        if v then
            task.spawn(function()
                while aimbotEnabled do
                    if aimbotHolding then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                            local closest, closestDist = nil, math.huge
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and plr.Character then
                                    local tPart = plr.Character:FindFirstChild(aimbotPart)
                                    local tHum = plr.Character:FindFirstChildOfClass("Humanoid")
                                    if tPart and tHum and tHum.Health > 0 then
                                        local d = (tPart.Position - hrp.Position).Magnitude
                                        if d <= aimbotDist then
                                            local screenPos, onScreen = Camera:WorldToViewportPoint(tPart.Position)
                                            if onScreen then
                                                local sd = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                                if sd <= aimbotFOV and sd < closestDist then
                                                    closest = tPart
                                                    closestDist = sd
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            if closest then
                                local lookAt = CFrame.lookAt(Camera.CFrame.Position, closest.Position)
                                Camera.CFrame = Camera.CFrame:Lerp(lookAt, aimbotSmooth)
                            end
                        end
                    end
                    RunService.RenderStepped:Wait()
                end
            end)
        end
    end
})

GrabTab:AddSlider({
    Name = "エイム距離",
    Min = 5,
    Max = 150,
    Default = 30,
    Increment = 5,
    ValueName = "studs",
    Callback = function(v) aimbotDist = v end
})

GrabTab:AddSlider({
    Name = "エイム滑らかさ",
    Min = 0.05,
    Max = 1,
    Default = 0.5,
    Increment = 0.05,
    ValueName = "x",
    Callback = function(v) aimbotSmooth = v end
})

GrabTab:AddSlider({
    Name = "エイムFOV",
    Min = 10,
    Max = 360,
    Default = 100,
    Increment = 5,
    ValueName = "px",
    Callback = function(v) aimbotFOV = v end
})

GrabTab:AddDropdown({
    Name = "エイム部位",
    Default = "Head",
    Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    Callback = function(v) aimbotPart = v end
})

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == aimbotKey then
        aimbotHolding = true
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == aimbotKey then
        aimbotHolding = false
    end
end))

-- ==========================================
-- 移動タブ
-- ==========================================
local MoveTab = Window:MakeTab({
    Name = "移動",
    Icon = "rbxassetid://4483362458",
})

MoveTab:AddSection({ Name = "基本" })

-- スピード
MoveTab:AddToggle({
    Name = "スピード変更",
    Default = false,
    Callback = function(v)
        NabeHub.State.SpeedEnabled = v
    end
})

MoveTab:AddSlider({
    Name = "スピード値",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    ValueName = "studs/s",
    Callback = function(v) NabeHub.State.Speed = v end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.SpeedEnabled then return end
    local hum = getHum()
    if hum then hum.WalkSpeed = NabeHub.State.Speed end
end))

-- ジャンプ
MoveTab:AddToggle({
    Name = "ジャンプ力変更",
    Default = false,
    Callback = function(v)
        NabeHub.State.JumpEnabled = v
    end
})

MoveTab:AddSlider({
    Name = "ジャンプ値",
    Min = 50,
    Max = 500,
    Default = 50,
    Increment = 1,
    ValueName = "",
    Callback = function(v) NabeHub.State.Jump = v end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.JumpEnabled then return end
    local hum = getHum()
    if hum then hum.JumpPower = NabeHub.State.Jump end
end))

-- 無限ジャンプ
MoveTab:AddToggle({
    Name = "無限ジャンプ",
    Default = false,
    Callback = function(v)
        NabeHub.State.InfJump = v
    end
})

track(UserInputService.JumpRequest:Connect(function()
    if not NabeHub.State.InfJump then return end
    local hum = getHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- ノークリップ
local noclipConn = nil
MoveTab:AddToggle({
    Name = "ノークリップ",
    Default = false,
    Callback = function(v)
        NabeHub.State.Noclip = v
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        if v then
            noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
            notif("なべHub", "ノークリップ ON")
        else
            notif("なべHub", "ノークリップ OFF")
        end
    end
})

-- ==========================================
-- フライ
-- ==========================================
MoveTab:AddSection({ Name = "フライ" })

local flyBV = Instance.new("BodyVelocity")
flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
flyBV.Velocity = Vector3.zero
local flyBG = Instance.new("BodyGyro")
flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
flyBG.P = 10000

local flyConn = nil
MoveTab:AddToggle({
    Name = "フライ",
    Default = false,
    Callback = function(v)
        NabeHub.State.Fly = v
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if not v then
            flyBV.Parent = nil
            flyBG.Parent = nil
            local hum = getHum()
            if hum then hum.PlatformStand = false end
            return
        end
        notif("なべHub", "フライ ON")
        flyConn = RunService.Heartbeat:Connect(function()
            if not NabeHub.State.Fly then return end
            local hrp = getHRP()
            local hum = getHum()
            if not hrp or not hum then return end
            flyBV.Parent = hrp
            flyBG.Parent = hrp
            flyBG.CFrame = Camera.CFrame

            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

            flyBV.Velocity = dir * NabeHub.State.FlySpeed
            hum.PlatformStand = true
        end)
    end
})

MoveTab:AddSlider({
    Name = "フライ速度",
    Min = 10,
    Max = 500,
    Default = 50,
    Increment = 5,
    ValueName = "studs/s",
    Callback = function(v) NabeHub.State.FlySpeed = v end
})

-- ブロブフライ
local blobFlyBV, blobFlyBG
MoveTab:AddToggle({
    Name = "ブロブフライ（R）",
    Default = false,
    Callback = function(v)
        NabeHub.State.BlobFly = v
        if not v then
            if blobFlyBV then blobFlyBV:Destroy() blobFlyBV = nil end
            if blobFlyBG then blobFlyBG:Destroy() blobFlyBG = nil end
        end
    end
})

track(RunService.Heartbeat:Connect(function()
    if not NabeHub.State.BlobFly then
        if blobFlyBV then blobFlyBV:Destroy() blobFlyBV = nil end
        if blobFlyBG then blobFlyBG:Destroy() blobFlyBG = nil end
        return
    end
    local blob = getSeatedBlobman() or getMyBlobman()
    if not blob then return end
    local root = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
    if not root then return end

    if not blobFlyBV or blobFlyBV.Parent ~= root then
        if blobFlyBV then blobFlyBV:Destroy() end
        blobFlyBV = Instance.new("BodyVelocity")
        blobFlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        blobFlyBV.P = 10000
        blobFlyBV.Parent = root
    end
    if not blobFlyBG or blobFlyBG.Parent ~= root then
        if blobFlyBG then blobFlyBG:Destroy() end
        blobFlyBG = Instance.new("BodyGyro")
        blobFlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        blobFlyBG.P = 20000
        blobFlyBG.D = 100
        blobFlyBG.Parent = root
    end

    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end

    blobFlyBV.Velocity = dir * 60
    blobFlyBG.CFrame = Camera.CFrame
end))

-- ==========================================
-- テレポート
-- ==========================================
MoveTab:AddSection({ Name = "テレポート" })

local teleportSpots = {
    ["スポーン"] = Vector3.new(0, -7, 0),
    ["紫の家（魔女）"] = Vector3.new(255, -8, 449),
    ["緑の家（木）"] = Vector3.new(-534, -8, 93),
    ["青の家（アメリカ）"] = Vector3.new(512, 82, -343),
    ["オレンジの家（中華）"] = Vector3.new(548, 122, -73),
    ["赤の家（普通）"] = Vector3.new(-493, -8, -165),
    ["毒井戸"] = Vector3.new(106, -25, 279),
    ["雪山"] = Vector3.new(-414, 231, 480),
    ["秘密大洞窟"] = Vector3.new(17, -7, 539),
    ["秘密列車洞窟"] = Vector3.new(500, 62, -307),
    ["Slot1"] = Vector3.new(54, -7, -115),
    ["Slot2"] = Vector3.new(170, -8, 527),
    ["Slot3"] = Vector3.new(-213, 83, 421),
    ["Slot4"] = Vector3.new(-540, -6, -40),
}

MoveTab:AddDropdown({
    Name = "テレポート先",
    Default = "スポーン",
    Options = (function()
        local list = {}
        for name in pairs(teleportSpots) do table.insert(list, name) end
        table.sort(list)
        return list
    end)(),
    Callback = function(v)
        NabeHub.TeleportSpot = v
    end
})

MoveTab:AddButton({
    Name = "テレポート実行",
    Callback = function()
        local spot = NabeHub.TeleportSpot or "スポーン"
        local pos = teleportSpots[spot]
        local hrp = getHRP()
        if pos and hrp then
            hrp.CFrame = CFrame.new(pos)
            notif("なべHub", spot .. " へテレポート")
        end
    end
})

-- プレイヤーTP
MoveTab:AddDropdown({
    Name = "プレイヤーTP対象",
    Default = "",
    Options = getPlayerList(),
    Callback = function(v)
        NabeHub.TPPlayer = getPlayerFromSelection(v)
    end
})

MoveTab:AddButton({
    Name = "プレイヤーリスト更新",
    Callback = function()
        -- targetDropdown と同じリスト
    end
})

MoveTab:AddButton({
    Name = "プレイヤーの所へ",
    Callback = function()
        local target = NabeHub.TPPlayer
        local tRoot = target and getHRP(target)
        local hrp = getHRP()
        if tRoot and hrp then
            hrp.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
            notif("なべHub", target.Name .. " へTP")
        end
    end
})

-- TPツール（T）
MoveTab:AddToggle({
    Name = "TPツール（T）",
    Default = false,
    Callback = function(v)
        NabeHub.State.TPTool = v
    end
})

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T and NabeHub.State.TPTool then
        local mouse = LocalPlayer:GetMouse()
        local hrp = getHRP()
        if mouse and mouse.Hit and hrp then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

-- 水上歩行
MoveTab:AddToggle({
    Name = "水上歩行",
    Default = false,
    Callback = function(v)
        NabeHub.State.WaterWalk = v
        local ocean = Workspace:FindFirstChild("Map")
            and Workspace.Map:FindFirstChild("AlwaysHereTweenedObjects")
            and Workspace.Map.AlwaysHereTweenedObjects:FindFirstChild("Ocean")
        if ocean then
            local model = ocean:FindFirstChild("Object")
                and ocean.Object:FindFirstChild("ObjectModel")
            if model then
                for _, p in ipairs(model:GetChildren()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = v
                    end
                end
            end
        end
        notif("なべHub", "水上歩行 " .. (v and "ON" or "OFF"))
    end
})
-- ==========================================
-- 視覚タブ
-- ==========================================
local VisualTab = Window:MakeTab({
    Name = "視覚",
    Icon = "rbxassetid://4483362458",
})

VisualTab:AddSection({ Name = "ESP" })

-- レインボーESP
local rainbowESP = {
    Enabled = false,
    Boxes = {},
    Hue = 0,
    Conn = nil,
}
local espTargets = {"partesp", "playercharacterlocationdetector"}

local function isESPTarget(obj)
    if not obj:IsA("BasePart") then return false end
    for _, n in ipairs(espTargets) do
        if string.lower(obj.Name) == n then return true end
    end
    return false
end

local function clearRainbowESP()
    for _, box in pairs(rainbowESP.Boxes) do
        if box then pcall(function() box:Destroy() end) end
    end
    rainbowESP.Boxes = {}
end

VisualTab:AddToggle({
    Name = "レインボーESP",
    Default = false,
    Callback = function(v)
        NabeHub.State.RainbowESP = v
        rainbowESP.Enabled = v
        if not v then
            clearRainbowESP()
            if rainbowESP.Conn then rainbowESP.Conn:Disconnect() rainbowESP.Conn = nil end
            return
        end
        -- 既存スキャン
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isESPTarget(obj) and not rainbowESP.Boxes[obj] then
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = obj
                box.AlwaysOnTop = true
                box.ZIndex = 5
                box.Color3 = Color3.fromHSV(rainbowESP.Hue, 1, 1)
                box.Transparency = 0.3
                box.Size = obj.Size
                box.Parent = game:GetService("CoreGui")
                rainbowESP.Boxes[obj] = box
            end
        end
        -- 新規監視
        rainbowESP.Conn = Workspace.DescendantAdded:Connect(function(obj)
            if rainbowESP.Enabled and isESPTarget(obj) and not rainbowESP.Boxes[obj] then
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = obj
                box.AlwaysOnTop = true
                box.ZIndex = 5
                box.Color3 = Color3.fromHSV(rainbowESP.Hue, 1, 1)
                box.Transparency = 0.3
                box.Size = obj.Size
                box.Parent = game:GetService("CoreGui")
                rainbowESP.Boxes[obj] = box
            end
        end)
        -- 色更新ループ
        task.spawn(function()
            while rainbowESP.Enabled do
                rainbowESP.Hue = (rainbowESP.Hue + 0.005) % 1
                local c = Color3.fromHSV(rainbowESP.Hue, 1, 1)
                for _, box in pairs(rainbowESP.Boxes) do
                    if box and box.Parent then
                        pcall(function() box.Color3 = c end)
                    end
                end
                task.wait(0.05)
            end
        end)
        notif("なべHub", "レインボーESP ON")
    end
})

-- ニックネームESP
local nameESPTags = {}
VisualTab:AddToggle({
    Name = "ニックネームESP",
    Default = false,
    Callback = function(v)
        NabeHub.State.NameESP = v
        if not v then
            for _, g in pairs(nameESPTags) do
                if g and g.Parent then pcall(function() g:Destroy() end) end
            end
            nameESPTags = {}
            return
        end
        local function addTag(plr)
            if plr == LocalPlayer then return end
            local hrp = getHRP(plr)
            if not hrp then return end
            if hrp:FindFirstChild("NabeNameESP") then return end
            local bb = Instance.new("BillboardGui")
            bb.Name = "NabeNameESP"
            bb.Adornee = hrp
            bb.Size = UDim2.new(0, 150, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3.5, 0)
            bb.AlwaysOnTop = true
            bb.Parent = hrp
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = plr.DisplayName
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = bb
            table.insert(nameESPTags, bb)
        end
        for _, plr in ipairs(Players:GetPlayers()) do addTag(plr) end
        track(Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function() if NabeHub.State.NameESP then task.wait(0.5) addTag(plr) end end)
        end))
        notif("なべHub", "ニックネームESP ON")
    end
})

-- ==========================================
-- 視覚効果
-- ==========================================
VisualTab:AddSection({ Name = "視覚効果" })

VisualTab:AddToggle({
    Name = "三人称視点",
    Default = false,
    Callback = function(v)
        NabeHub.State.ThirdPerson = v
        if v then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.CameraMaxZoomDistance = 1000
            LocalPlayer.CameraMinZoomDistance = 0.5
        else
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            LocalPlayer.CameraMaxZoomDistance = 0.5
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end
})

-- キャラ回転
VisualTab:AddToggle({
    Name = "キャラ回転",
    Default = false,
    Callback = function(v)
        NabeHub.State.CharSpin = v
        if v then
            task.spawn(function()
                while NabeHub.State.CharSpin do
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(5), 0)
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end
})

VisualTab:AddSlider({
    Name = "FOV",
    Min = 40,
    Max = 120,
    Default = 70,
    Increment = 1,
    ValueName = "°",
    Callback = function(v)
        NabeHub.State.FOV = v
        Camera.FieldOfView = v
    end
})

-- ==========================================
-- カスタムエフェクト
-- ==========================================
VisualTab:AddSection({ Name = "カスタムエフェクト" })

local customEffect = {
    Active = "None",
    Enabled = false,
    Parts = {},
    Conns = {},
}

local function clearCustomEffect()
    for _, c in ipairs(customEffect.Conns) do
        pcall(function() c:Disconnect() end)
    end
    customEffect.Conns = {}
    for _, p in ipairs(customEffect.Parts) do
        pcall(function() p:Destroy() end)
    end
    customEffect.Parts = {}
end

local customEffects = {}

-- Orbit Rings
customEffects["Orbit Rings"] = function()
    local hrp = getHRP()
    if not hrp then return end
    local rings = {}
    for i = 1, 3 do
        local ring = Instance.new("Part")
        ring.Size = Vector3.new(7, 0.18, 0.18)
        ring.Material = Enum.Material.Neon
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.Massless = true
        ring.Anchored = true
        ring.Parent = LocalPlayer.Character
        table.insert(customEffect.Parts, ring)
        table.insert(rings, { part = ring, offset = (i - 1) * (math.pi * 2 / 3), tilt = (i - 1) * (math.pi / 3) })
    end
    local t = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        t = t + dt * 2.2
        local h = getHRP()
        if not h then return end
        for _, d in ipairs(rings) do
            local ang = t + d.offset
            d.part.Color = Color3.fromHSV(((t * 0.08 + d.offset) % (math.pi * 2)) / (math.pi * 2), 1, 1)
            d.part.CFrame = h.CFrame * CFrame.Angles(d.tilt, 0, 0) * CFrame.Angles(0, ang, 0) * CFrame.new(3.6, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
        end
    end)
    table.insert(customEffect.Conns, conn)
end

-- Fire Aura
customEffects["Fire Aura"] = function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, name in ipairs({"HumanoidRootPart", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
        local p = char:FindFirstChild(name)
        if p then
            local fire = Instance.new("Fire")
            fire.Size = 4
            fire.Heat = 6
            fire.Color = Color3.fromRGB(255, 80, 0)
            fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
            fire.Parent = p
            table.insert(customEffect.Parts, fire)
        end
    end
end

-- Lightning Body
customEffects["Lightning Body"] = function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, name in ipairs({"HumanoidRootPart", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            local a0 = Instance.new("Attachment")
            a0.Position = Vector3.new(0, p.Size.Y / 2, 0)
            a0.Parent = p
            local a1 = Instance.new("Attachment")
            a1.Position = Vector3.new(0, -p.Size.Y / 2, 0)
            a1.Parent = p
            local bolt = Instance.new("Beam")
            bolt.Attachment0 = a0
            bolt.Attachment1 = a1
            bolt.FaceCamera = true
            bolt.Width0 = 0.06
            bolt.Width1 = 0.06
            bolt.Segments = 12
            bolt.LightEmission = 1
            bolt.LightInfluence = 0
            bolt.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 160, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 60, 255)),
            })
            bolt.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.2),
            })
            bolt.Parent = p
            table.insert(customEffect.Parts, a0)
            table.insert(customEffect.Parts, a1)
            table.insert(customEffect.Parts, bolt)
            task.spawn(function()
                while bolt.Parent do
                    bolt.Segments = math.random(6, 18)
                    bolt.Width0 = math.random(3, 9) / 100
                    bolt.Width1 = bolt.Width0
                    task.wait(math.random(2, 8) / 100)
                end
            end)
        end
    end
end

-- ブラックホール召喚（ボタン用）
local function spawnBlackHole(pos)
    local core = Instance.new("Part")
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(3, 3, 3)
    core.Position = pos
    core.Anchored = true
    core.CanCollide = false
    core.Material = Enum.Material.Neon
    core.Color = Color3.new(0, 0, 0)
    core.Parent = Workspace

    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Ball
    ring.Size = Vector3.new(6, 6, 6)
    ring.Position = pos
    ring.Anchored = true
    ring.CanCollide = false
    ring.Material = Enum.Material.Neon
    ring.Color = Color3.fromRGB(150, 0, 255)
    ring.Transparency = 0.6
    ring.Parent = Workspace

    local pe = Instance.new("ParticleEmitter")
    pe.Parent = core
    pe.Texture = "rbxassetid://243098098"
    pe.Rate = 100
    pe.Lifetime = NumberRange.new(0.5, 1)
    pe.Speed = NumberRange.new(5, 15)
    pe.SpreadAngle = Vector2.new(360, 360)
    pe.Color = ColorSequence.new(Color3.fromRGB(150, 0, 255), Color3.fromRGB(0, 0, 0))
    pe.Size = NumberSequence.new(0.5, 0.1)

    local sound = Instance.new("Sound")
    sound.Parent = core
    sound.SoundId = "rbxassetid://9116149587"
    sound.Volume = 2
    sound:Play()

    task.spawn(function()
        local tween = TweenService:Create(core, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(8, 8, 8)
        })
        tween:Play()
        local rot = 0
        local conn
        conn = RunService.Heartbeat:Connect(function(dt)
            if not core.Parent then conn:Disconnect() return end
            rot = rot + dt * 360
            core.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rot), 0)
            ring.CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(rot), 0, 0)
        end)
        task.wait(2)
        conn:Disconnect()
        core:Destroy()
        ring:Destroy()
    end)
end

VisualTab:AddDropdown({
    Name = "エフェクト選択",
    Default = "None",
    Options = {"None", "Orbit Rings", "Fire Aura", "Lightning Body"},
    Callback = function(v)
        customEffect.Active = v
        if customEffect.Enabled then
            clearCustomEffect()
            if customEffects[v] then customEffects[v]() end
        end
    end
})

VisualTab:AddToggle({
    Name = "エフェクト有効",
    Default = false,
    Callback = function(v)
        customEffect.Enabled = v
        if v then
            if customEffects[customEffect.Active] then customEffects[customEffect.Active]() end
            notif("なべHub", customEffect.Active .. " ON")
        else
            clearCustomEffect()
            notif("なべHub", "エフェクト OFF")
        end
    end
})

VisualTab:AddButton({
    Name = "ブラックホール召喚",
    Callback = function()
        local hrp = getHRP()
        if hrp then
            spawnBlackHole(hrp.Position + Vector3.new(0, 8, 0))
            notif("なべHub", "ブラックホール召喚")
        end
    end
})

-- ==========================================
-- 便利タブ
-- ==========================================
local UtilityTab = Window:MakeTab({
    Name = "便利",
    Icon = "rbxassetid://4483362458",
})

UtilityTab:AddSection({ Name = "おもちゃ" })

-- おもちゃ一覧
local toyList = {
    "FoodHamburger", "FoodCoconut", "FoodBanana", "FoodFrenchFries", "FoodMeatStick",
    "FoodDonut", "FoodCakePink", "FoodPizzaCheese", "FoodHotdog", "FoodMushroomPoison",
    "FoodBread", "FoodDippyEgg", "FoodMayonnaise",
    "InstrumentGuitarBanjo", "InstrumentGuitarViolin", "InstrumentGuitarUkulele",
    "InstrumentWoodwindSaxophone", "InstrumentWoodwindOcarina",
    "InstrumentBrassTrumpet", "InstrumentBrassVuvuzela", "InstrumentDrumBongos",
    "InstrumentDrumSnare", "InstrumentPianoMelodica", "InstrumentVoiceMicrophone",
    "CupMugWhite", "CupMugBrown", "PoopPile", "PoopPileSparkle",
    "BombMissile", "BombDarkMatter", "BombBalloon", "FireworkMissile",
    "PresentBig", "PresentSmall", "NinjaShuriken", "NinjaKunai",
    "PalletLightBrown", "SprayCanWD", "FireExtinguisher", "Campfire",
    "BallSnowball", "JapaneseLantern", "SpookyCandle1", "DiceSmall",
    "TractorGreen", "FireworkSparkler", "OvenDarkGray", "OvenMicrowaveWhite",
    "PlantPottedCactus", "CreatureBlobman",
}

UtilityTab:AddDropdown({
    Name = "おもちゃ選択",
    Default = "FoodHamburger",
    Options = toyList,
    Callback = function(v)
        NabeHub.SelectedToy = v
    end
})

UtilityTab:AddButton({
    Name = "おもちゃスポーン",
    Callback = function()
        local toy = NabeHub.SelectedToy or "FoodHamburger"
        local hrp = getHRP()
        if hrp then
            spawnToy(toy, hrp.CFrame * CFrame.new(0, 5, 5))
            notif("なべHub", toy .. " スポーン")
        end
    end
})

-- バリア破壊
UtilityTab:AddSection({ Name = "バリア破壊" })

UtilityTab:AddButton({
    Name = "バリア破壊実行",
    Callback = function()
        task.spawn(function()
            local hrp = getHRP()
            local hum = getHum()
            if not hrp or not hum then return end

            -- 家の中なら拒否
            if LocalPlayer.InPlot and LocalPlayer.InPlot.Value then
                notif("なべHub", "家の外で実行してください")
                return
            end

            local originalPos = hrp.CFrame
            local originalSpeed = hum.WalkSpeed
            hum.WalkSpeed = 0

            -- オカリナを特定座標にスポーン
            pcall(function()
                SpawnToyRemoteFunction:InvokeServer("InstrumentWoodwindOcarina",
                    CFrame.new(184.148834, -5.54824972, 498.136749), Vector3.new(0, 34, 0))
            end)
            task.wait(0.4)

            local toys = getMyToys()
            local ocarina = toys and toys:FindFirstChild("InstrumentWoodwindOcarina")
            if ocarina and ocarina:FindFirstChild("HoldPart") then
                pcall(function()
                    ocarina.HoldPart.HoldItemRemoteFunction:InvokeServer(ocarina, LocalPlayer.Character)
                end)
                hrp.CFrame = CFrame.new(304.06, 25.77, 488.54)
                task.wait(0.21)
                pcall(function() DestroyToy:FireServer(ocarina) end)
                hrp.CFrame = originalPos
                task.wait(0.7)
                pcall(function()
                    SpawnToyRemoteFunction:InvokeServer("Campfire",
                        CFrame.new(257.638672, -5.57392979, 450.103638), Vector3.new(0, 161.972))
                end)
                hum.WalkSpeed = originalSpeed
                notif("なべHub", "バリア破壊実行")
            end
        end)
    end
})

-- 家の時間維持
local houseTimeThread = nil
UtilityTab:AddToggle({
    Name = "家の時間維持",
    Default = false,
    Callback = function(v)
        NabeHub.State.PreserveHouse = v
        if not v then
            if houseTimeThread then task.cancel(houseTimeThread) houseTimeThread = nil end
            return
        end
        houseTimeThread = task.spawn(function()
            while NabeHub.State.PreserveHouse do
                local plotArea = nil
                for _, plot in ipairs(Workspace.Plots:GetChildren()) do
                    local sign = plot:FindFirstChild("PlotSign")
                    local owners = sign and sign:FindFirstChild("ThisPlotsOwners")
                    if owners then
                        for _, o in ipairs(owners:GetChildren()) do
                            if o.Value == LocalPlayer.Name and o:FindFirstChild("TimeRemainingNum") then
                                if o.TimeRemainingNum.Value < 20 then
                                    local area = plot:FindFirstChild("PlotArea")
                                    local hrp = getHRP()
                                    if area and hrp then
                                        hrp.CFrame = CFrame.new(area.Position)
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(2)
            end
        end)
        notif("なべHub", "家の時間維持 ON")
    end
})

-- スロット自動回転
local slotThread = nil
UtilityTab:AddToggle({
    Name = "スロット自動回転",
    Default = false,
    Callback = function(v)
        NabeHub.State.AutoSpinSlot = v
        if not v then
            if slotThread then task.cancel(slotThread) slotThread = nil end
            return
        end
        slotThread = task.spawn(function()
            while NabeHub.State.AutoSpinSlot do
                local hrp = getHRP()
                if hrp then
                    for _, slot in ipairs(Workspace:FindFirstChild("Slots"):GetChildren()) do
                        local handle = slot:FindFirstChild("SlotHandle") and slot.SlotHandle:FindFirstChild("Handle")
                        if handle then
                            pcall(function() SetNetworkOwner:FireServer(handle, handle.CFrame) end)
                        end
                    end
                end
                task.wait(1)
            end
        end)
        notif("なべHub", "スロット自動回転 ON")
    end
})

-- ==========================================
-- アンカーオブジェクト
-- ==========================================
UtilityTab:AddSection({ Name = "アンカー" })

local anchorConn = nil
UtilityTab:AddToggle({
    Name = "アンカーオブジェクト（G）",
    Default = false,
    Callback = function(v)
        NabeHub.State.Anchor = v
        if anchorConn then anchorConn:Disconnect() anchorConn = nil end
        if v then
            anchorConn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode ~= Enum.KeyCode.G then return end
                local grabParts = Workspace:FindFirstChild("GrabParts")
                if not grabParts then return end
                local grabPart = grabParts:FindFirstChild("GrabPart")
                if not grabPart then return end
                local weld = grabPart:FindFirstChild("WeldConstraint") or grabPart:FindFirstChild("Weld")
                local part1 = weld and weld.Part1
                if not part1 then return end
                local parent = part1.Parent
                if parent and parent:IsA("Model") and not parent:GetAttribute("NabeAnchored") then
                    local bp = Instance.new("BodyPosition")
                    bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                    bp.P = 40000
                    bp.D = 950
                    bp.Position = part1.Position
                    bp.Parent = part1
                    local bg = Instance.new("BodyGyro")
                    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                    bg.P = 40000
                    bg.D = 950
                    bg.CFrame = part1.CFrame
                    bg.Parent = part1
                    parent:SetAttribute("NabeAnchored", true)
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(0, 100, 255)
                    hl.OutlineColor = Color3.fromRGB(0, 200, 255)
                    hl.FillTransparency = 0.7
                    hl.Adornee = parent
                    hl.Parent = parent
                    notif("なべHub", parent.Name .. " をアンカー化")
                elseif parent and parent:GetAttribute("NabeAnchored") then
                    for _, p in ipairs(parent:GetDescendants()) do
                        if p:IsA("BodyPosition") or p:IsA("BodyGyro") then p:Destroy() end
                        if p:IsA("Highlight") then p:Destroy() end
                    end
                    parent:SetAttribute("NabeAnchored", nil)
                    notif("なべHub", "アンカー解除")
                end
            end)
            notif("なべHub", "アンカーオブジェクト ON (G)")
        end
    end
})

-- ブロブマン自動スポーン
UtilityTab:AddSection({ Name = "ブロブマン" })

UtilityTab:AddToggle({
    Name = "ブロブマン自動スポーン",
    Default = false,
    Callback = function(v)
        NabeHub.State.AutoBlobman = v
        if not v then return end
        task.spawn(function()
            while NabeHub.State.AutoBlobman do
                local hum = getHum()
                if hum and not hum.SeatPart then
                    ensureBlobman()
                end
                task.wait(1)
            end
        end)
        notif("なべHub", "ブロブマン自動スポーン ON")
    end
})

-- ==========================================
-- 設定タブ
-- ==========================================
local SettingsTab = Window:MakeTab({
    Name = "設定",
    Icon = "rbxassetid://4483362458",
})

SettingsTab:AddSection({ Name = "情報" })

SettingsTab:AddLabel("なべHub v1.0")
SettingsTab:AddLabel("The Survival Game (物人) 専用")
SettingsTab:AddLabel("Base: Orion Lib (jadpy/suki)")

SettingsTab:AddSection({ Name = "通知" })

local notifyEnabled = true
SettingsTab:AddToggle({
    Name = "通知有効",
    Default = true,
    Callback = function(v)
        notifyEnabled = v
    end
})

SettingsTab:AddSection({ Name = "全停止" })

SettingsTab:AddButton({
    Name = "全機能停止",
    Callback = function()
        for k, _ in pairs(NabeHub.State) do
            if type(NabeHub.State[k]) == "boolean" then
                NabeHub.State[k] = false
            end
        end
        clearRainbowESP()
        clearCustomEffect()
        for _, conn in ipairs(NabeHub.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        NabeHub.Connections = {}
        notif("なべHub", "全機能停止")
    end
})

SettingsTab:AddButton({
    Name = "UI アンロード",
    Callback = function()
        for k, _ in pairs(NabeHub.State) do
            if type(NabeHub.State[k]) == "boolean" then
                NabeHub.State[k] = false
            end
        end
        clearRainbowESP()
        clearCustomEffect()
        for _, conn in ipairs(NabeHub.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        NabeHub.Connections = {}
        OrionLib:Destroy()
    end
})

-- ==========================================
-- 完了通知
-- ==========================================
OrionLib:Init()

notif("なべHub", "起動完了。攻撃・防御・掴み・移動・視覚・便利の6タブ。")

print("[なべHub] loaded")
