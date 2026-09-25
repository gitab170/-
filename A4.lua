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
