local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local MUSIC_ID = "rbxassetid://104181508980428"
local DECAL_ID = "rbxassetid://94778603870318"
local SOUND_VOLUME = 1.0
local SOUND_SPEED = 0.2

local HUB_BGM_ID = "rbxassetid://104181508980428"
local HUB_BGM_VOLUME = 0.5
local HUB_BGM_SPEED = 1.0

local GROUP_ID = 659882425
local ADMIN_ID = 8576582385
local currentKey = "TeamS00shi"

local vs = Camera.ViewportSize
local sf = math.clamp(math.min(vs.X/800, vs.Y/600), 0.55, 1.3)

local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "S00shiNotifications"
NotificationGui.ResetOnSpawn = false
NotificationGui.DisplayOrder = 999999
NotificationGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local currentNotificationFrame = nil
local notificationTimer = nil

local function destroyCurrentNotification()
    if currentNotificationFrame then
        pcall(function() currentNotificationFrame:Destroy() end)
        currentNotificationFrame = nil
    end
    if notificationTimer then
        coroutine.close(notificationTimer)
        notificationTimer = nil
    end
end

local function createNotificationFrame(title, text)
    local scale = sf or 1
    destroyCurrentNotification()

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320 * scale, 0, 80 * scale)
    frame.Position = UDim2.new(0.5, -160 * scale, 0, 15 * scale)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    frame.Parent = NotificationGui

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6 * scale)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30 * scale)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(0, 85, 255)
    header.BorderSizePixel = 0
    header.Parent = frame
    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 6 * scale)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10 * scale, 1, 0)
    titleLabel.Position = UDim2.new(0, 5 * scale, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14 * scale
    titleLabel.Font = Enum.Font.ArialBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -10 * scale, 1, -35 * scale)
    textLabel.Position = UDim2.new(0, 5 * scale, 0, 33 * scale)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 12 * scale
    textLabel.Font = Enum.Font.Arial
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame

    local originalTitle = title
    local originalText = text
    local function protectNotification()
        if titleLabel and titleLabel.Parent then
            if titleLabel.Text ~= originalTitle then titleLabel.Text = originalTitle end
            if titleLabel.TextColor3 ~= Color3.fromRGB(255,255,255) then titleLabel.TextColor3 = Color3.fromRGB(255,255,255) end
        end
        if textLabel and textLabel.Parent then
            if textLabel.Text ~= originalText then textLabel.Text = originalText end
            if textLabel.TextColor3 ~= Color3.fromRGB(255,255,255) then textLabel.TextColor3 = Color3.fromRGB(255,255,255) end
        end
        if header and header.Parent then
            if header.BackgroundColor3 ~= Color3.fromRGB(0,85,255) then header.BackgroundColor3 = Color3.fromRGB(0,85,255) end
        end
        if frame and frame.Parent then
            if frame.BackgroundColor3 ~= Color3.fromRGB(25,25,25) then frame.BackgroundColor3 = Color3.fromRGB(25,25,25) end
        end
    end
    titleLabel:GetPropertyChangedSignal("Text"):Connect(protectNotification)
    titleLabel:GetPropertyChangedSignal("TextColor3"):Connect(protectNotification)
    textLabel:GetPropertyChangedSignal("Text"):Connect(protectNotification)
    textLabel:GetPropertyChangedSignal("TextColor3"):Connect(protectNotification)
    header:GetPropertyChangedSignal("BackgroundColor3"):Connect(protectNotification)
    frame:GetPropertyChangedSignal("BackgroundColor3"):Connect(protectNotification)

    local fadeIn = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    fadeIn:Play()

    notificationTimer = task.spawn(function()
        task.wait(3)
        if currentNotificationFrame == frame then
            local fadeOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            })
            fadeOut:Play()
            fadeOut.Completed:Wait()
            if frame and frame.Parent then
                frame:Destroy()
            end
            if currentNotificationFrame == frame then
                currentNotificationFrame = nil
            end
            notificationTimer = nil
        end
    end)

    currentNotificationFrame = frame
    return frame
end

local function sendNotification(title, text, duration)
    createNotificationFrame(title, text)
end

local function checkGroupMembership()
    for _ = 1, 6 do
        if LocalPlayer:GetRankInGroup(GROUP_ID) ~= 0 then return true end
        task.wait(0.5)
    end
    return false
end

if not checkGroupMembership() then
    sendNotification("Your SPY", "Join my community!!", 10)
    task.wait(2)
    LocalPlayer:Kick("Join my community!!")
    return
end

local function createPasswordGUI(onSuccess)
    local sg = Instance.new("ScreenGui")
    sg.Name = "S00shiPassword"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 999999
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 380*sf, 0, 520*sf)
    frame.Position = UDim2.new(0.5, -190*sf, 0.5, -260*sf)
    frame.BackgroundColor3 = Color3.fromRGB(199,199,199)
    frame.BorderSizePixel = 2
    frame.Active = true
    frame.Draggable = true

    local titleBar = Instance.new("Frame", frame)
    titleBar.Size = UDim2.new(1, 0, 0, 28*sf)
    titleBar.BackgroundColor3 = Color3.fromRGB(0,51,255)

    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(1, -80*sf, 1, 0)
    title.Position = UDim2.new(0, 4*sf, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🦈 S00shi Hub"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextSize = 14*sf
    title.Font = Enum.Font.ArialBold

    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 24*sf, 0, 22*sf)
    closeBtn.Position = UDim2.new(1, -28*sf, 0.5, -11*sf)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.TextSize = 12*sf

    local content = Instance.new("Frame", frame)
    content.Size = UDim2.new(1, -16, 1, -80)
    content.Position = UDim2.new(0, 8, 0, 40)
    content.BackgroundColor3 = Color3.fromRGB(179,179,179)

    local lblTitle = Instance.new("TextLabel", content)
    lblTitle.Size = UDim2.new(1,0,0,40*sf)
    lblTitle.Position = UDim2.new(0,0,0,20)
    lblTitle.BackgroundTransparency = 1
    lblTitle.Text = "🔑 Enter Key"
    lblTitle.TextColor3 = Color3.fromRGB(0,0,0)
    lblTitle.TextSize = 18*sf
    lblTitle.Font = Enum.Font.ArialBold

    local lblKey = Instance.new("TextLabel", content)
    lblKey.Size = UDim2.new(1,-20,0,20*sf)
    lblKey.Position = UDim2.new(0,10,0,80)
    lblKey.BackgroundTransparency = 1
    lblKey.Text = "Key"
    lblKey.TextColor3 = Color3.fromRGB(0,0,0)
    lblKey.TextSize = 12*sf

    local boxKey = Instance.new("TextBox", content)
    boxKey.Size = UDim2.new(1,-20,0,32*sf)
    boxKey.Position = UDim2.new(0,10,0,105)
    boxKey.BackgroundColor3 = Color3.fromRGB(255,255,255)
    boxKey.PlaceholderText = "Enter key"
    boxKey.Text = ""

    local authBtn = Instance.new("TextButton", content)
    authBtn.Size = UDim2.new(1,-20,0,45*sf)
    authBtn.Position = UDim2.new(0,10,0,180)
    authBtn.BackgroundColor3 = Color3.fromRGB(0,51,255)
    authBtn.Text = "🔓 Authenticate"
    authBtn.TextColor3 = Color3.fromRGB(255,255,255)
    authBtn.TextSize = 16*sf
    authBtn.Font = Enum.Font.ArialBold

    local function onAuth()
        local enteredKey = boxKey.Text:match("^%s*(.-)%s*$")
        if enteredKey == currentKey or (LocalPlayer.UserId == ADMIN_ID and enteredKey == "") then
            sg:Destroy()
            sendNotification("✅ Success", "Hub started", 5)
            onSuccess()
        else
            sendNotification("❌ Failed", "Invalid key", 4)
            boxKey.Text = ""
        end
    end

    authBtn.MouseButton1Click:Connect(onAuth)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    if LocalPlayer.UserId == ADMIN_ID then
        local skipBtn = Instance.new("TextButton", content)
        skipBtn.Size = UDim2.new(1,-20,0,40*sf)
        skipBtn.Position = UDim2.new(0,10,0,250*sf)
        skipBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
        skipBtn.Text = "🔓 Skip (Dev)"
        skipBtn.TextColor3 = Color3.fromRGB(255,255,255)
        skipBtn.TextSize = 14*sf
        skipBtn.Font = Enum.Font.ArialBold
        skipBtn.MouseButton1Click:Connect(function()
            sg:Destroy()
            sendNotification("✅ Dev Skip", "Hub started", 5)
            onSuccess()
        end)
    end
end

local function createMainHub()
    sendNotification("Welcome!", "Hallo Team S00shi!! (Lava tower hub)", 6)

    local SG = Instance.new("ScreenGui")
    SG.Name = "S00shiHub"
    SG.ResetOnSpawn = false
    SG.DisplayOrder = 0
    SG.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local Main = Instance.new("Frame", SG)
    Main.Size = UDim2.new(0, 380 * sf, 0, 520 * sf)
    Main.Position = UDim2.new(0.5, -190 * sf, 0.5, -260 * sf)
    Main.BackgroundColor3 = Color3.fromRGB(199,199,199)
    Main.BorderSizePixel = 2
    Main.Active = true
    Main.Draggable = true
    Main.Visible = false

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 28 * sf)
    TitleBar.BackgroundColor3 = Color3.fromRGB(0,51,255)
    TitleBar.BorderSizePixel = 1
    TitleBar.BorderColor3 = Color3.fromRGB(0,0,0)

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -80 * sf, 1, 0)
    Title.Position = UDim2.new(0, 4 * sf, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🦈 S00shi Hub"
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.TextSize = 14 * sf
    Title.Font = Enum.Font.ArialBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local function protectTitle()
        if Title and Title.Parent then
            if Title.Text ~= "🦈 S00shi Hub" then Title.Text = "🦈 S00shi Hub" end
            if Title.TextColor3 ~= Color3.fromRGB(255,255,255) then Title.TextColor3 = Color3.fromRGB(255,255,255) end
        end
    end
    Title:GetPropertyChangedSignal("Text"):Connect(protectTitle)
    Title:GetPropertyChangedSignal("TextColor3"):Connect(protectTitle)
    task.spawn(function()
        while Title and Title.Parent do
            task.wait(0.2)
            protectTitle()
        end
    end)

    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Size = UDim2.new(0, 24 * sf, 0, 22 * sf)
    MinBtn.Position = UDim2.new(1, -56 * sf, 0.5, -11 * sf)
    MinBtn.BackgroundColor3 = Color3.fromRGB(179,179,179)
    MinBtn.BorderSizePixel = 1
    MinBtn.BorderColor3 = Color3.fromRGB(0,0,0)
    MinBtn.Text = "_"
    MinBtn.TextColor3 = Color3.fromRGB(0,0,0)
    MinBtn.TextSize = 12 * sf
    MinBtn.Font = Enum.Font.ArialBold

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 24 * sf, 0, 22 * sf)
    CloseBtn.Position = UDim2.new(1, -28 * sf, 0.5, -11 * sf)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    CloseBtn.BorderSizePixel = 1
    CloseBtn.BorderColor3 = Color3.fromRGB(0,0,0)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn.TextSize = 12 * sf
    CloseBtn.Font = Enum.Font.ArialBold

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Main.Size = minimized and UDim2.new(0, 380 * sf, 0, 28 * sf) or UDim2.new(0, 380 * sf, 0, 520 * sf)
        MinBtn.Text = minimized and "+" or "_"
        for _, c in ipairs(Main:GetChildren()) do
            if c ~= TitleBar then
                c.Visible = not minimized
            end
        end
    end)

    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "S00shiToggle"
    ToggleGui.ResetOnSpawn = false
    ToggleGui.DisplayOrder = 999
    ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local ToggleButton = Instance.new("ImageButton")
    ToggleButton.Size = UDim2.new(0, 60 * sf, 0, 60 * sf)
    ToggleButton.Position = UDim2.new(1, -70 * sf, 0, 10 * sf)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.Image = DECAL_ID
    ToggleButton.ImageTransparency = 0.2
    ToggleButton.Visible = true
    ToggleButton.Parent = ToggleGui

    local function protectToggleButton()
        if not ToggleButton or not ToggleButton.Parent then return end
        if ToggleButton.Image ~= DECAL_ID then ToggleButton.Image = DECAL_ID end
        if ToggleButton.ImageTransparency ~= 0.2 then ToggleButton.ImageTransparency = 0.2 end
        if not Main.Visible and ToggleButton.Visible ~= true then ToggleButton.Visible = true end
        if ToggleButton.BackgroundTransparency ~= 1 then ToggleButton.BackgroundTransparency = 1 end
    end
    ToggleButton:GetPropertyChangedSignal("Image"):Connect(protectToggleButton)
    ToggleButton:GetPropertyChangedSignal("ImageTransparency"):Connect(protectToggleButton)
    ToggleButton:GetPropertyChangedSignal("Visible"):Connect(protectToggleButton)
    ToggleButton:GetPropertyChangedSignal("BackgroundTransparency"):Connect(protectToggleButton)
    task.spawn(function()
        while ToggleButton and ToggleButton.Parent do
            task.wait(0.3)
            protectToggleButton()
        end
    end)

    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(1, 0, 1, 0)
    glowFrame.BackgroundTransparency = 0.5
    glowFrame.BorderSizePixel = 3
    glowFrame.BorderColor3 = Color3.fromRGB(255,255,255)
    glowFrame.BackgroundColor3 = Color3.fromRGB(255,0,0)
    glowFrame.Parent = ToggleButton

    local rotationAngle = 0
    local hue = 0
    task.spawn(function()
        while true do
            if ToggleButton and ToggleButton.Parent then
                rotationAngle = (rotationAngle + 1) % 360
                hue = (hue + 0.005) % 1
                local color = Color3.fromHSV(hue, 1, 1)
                ToggleButton.Rotation = rotationAngle
                glowFrame.BackgroundColor3 = color
                glowFrame.BorderColor3 = Color3.fromHSV((hue + 0.5) % 1, 1, 1)
            end
            task.wait(0.03)
        end
    end)

    local hubBgm = Instance.new("Sound")
    hubBgm.Name = "S00shiHubBGM"
    hubBgm.SoundId = HUB_BGM_ID
    hubBgm.Volume = HUB_BGM_VOLUME
    hubBgm.PlaybackSpeed = HUB_BGM_SPEED
    hubBgm.Looped = true
    hubBgm.Parent = SoundService

    local function updateHubBGM()
        if Main.Visible then
            if hubBgm.IsPlaying then hubBgm:Stop() end
        else
            if not hubBgm.IsPlaying then hubBgm:Play() end
        end
    end

    task.defer(updateHubBGM)

    ToggleButton.MouseButton1Click:Connect(function()
        Main.Visible = not Main.Visible
        if Main.Visible then ToggleButton.Visible = false end
        updateHubBGM()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        ToggleButton.Visible = true
        updateHubBGM()
    end)
    Main:GetPropertyChangedSignal("Visible"):Connect(function()
        if not Main.Visible then ToggleButton.Visible = true end
        updateHubBGM()
    end)

    local TabBar = Instance.new("Frame", Main)
    TabBar.Size = UDim2.new(1, 0, 0, 30 * sf)
    TabBar.Position = UDim2.new(0, 0, 0, 28 * sf)
    TabBar.BackgroundColor3 = Color3.fromRGB(179,179,179)
    TabBar.BorderSizePixel = 1
    TabBar.BorderColor3 = Color3.fromRGB(0,0,0)

    local TabLayout = Instance.new("UIListLayout", TabBar)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 2 * sf)

    local TabContents = {}
    local TabButtons = {}
    local TABS = {
        {name = "⚔️ Main", id = "main"},
        {name = "🛡️ Anti", id = "anti"},
        {name = "🎉 Fun", id = "fun"},
        {name = "👤 Player", id = "player"},
    }

    local Content = Instance.new("ScrollingFrame", Main)
    Content.Size = UDim2.new(1, -8, 1, -(28 + 30) * sf)
    Content.Position = UDim2.new(0, 4, 0, (28 + 30) * sf)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 1
    Content.BorderColor3 = Color3.fromRGB(0,0,0)
    Content.ScrollBarThickness = 6
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.Padding = UDim.new(0, 4 * sf)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local ContentPad = Instance.new("UIPadding", Content)
    ContentPad.PaddingTop = UDim.new(0, 0)
    ContentPad.PaddingBottom = UDim.new(0, 6 * sf)
    ContentPad.PaddingLeft = UDim.new(0, 6 * sf)
    ContentPad.PaddingRight = UDim.new(0, 6 * sf)

    for _, tab in ipairs(TABS) do
        local container = Instance.new("Frame", Content)
        container.Size = UDim2.new(1, 0, 0, 0)
        container.BackgroundTransparency = 1
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.Visible = false
        local layout = Instance.new("UIListLayout", container)
        layout.Padding = UDim.new(0, 4 * sf)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        TabContents[tab.id] = container
    end

    for i, tab in ipairs(TABS) do
        local btn = Instance.new("TextButton", TabBar)
        btn.Size = UDim2.new(0, 80 * sf, 0, 26 * sf)
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(0,51,255) or Color3.fromRGB(160,160,160)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(0,0,0)
        btn.Text = tab.name
        btn.TextColor3 = i == 1 and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
        btn.TextSize = 10 * sf
        btn.Font = Enum.Font.ArialBold
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        TabButtons[tab.id] = btn

        btn.MouseButton1Click:Connect(function()
            for id, container in pairs(TabContents) do
                container.Visible = false
                local btnObj = TabButtons[id]
                btnObj.BackgroundColor3 = Color3.fromRGB(160,160,160)
                btnObj.TextColor3 = Color3.fromRGB(0,0,0)
            end
            TabContents[tab.id].Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(0,51,255)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
        end)
    end
    for _, container in pairs(TabContents) do container.Visible = false end
    for _, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = Color3.fromRGB(160,160,160)
        btn.TextColor3 = Color3.fromRGB(0,0,0)
    end
    TabContents["main"].Visible = true

    local function makeSection(parent, title)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 24 * sf)
        frame.BackgroundColor3 = Color3.fromRGB(179,179,179)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(0,0,0)
        frame.AutomaticSize = Enum.AutomaticSize.None
        frame.ClipsDescendants = true

        local header = Instance.new("TextButton", frame)
        header.Size = UDim2.new(1, 0, 0, 24 * sf)
        header.BackgroundColor3 = Color3.fromRGB(0,51,255)
        header.BorderSizePixel = 1
        header.BorderColor3 = Color3.fromRGB(0,0,0)
        header.Text = "▸ " .. title
        header.TextColor3 = Color3.fromRGB(255,255,255)
        header.TextSize = 11 * sf
        header.Font = Enum.Font.ArialBold
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.AutoButtonColor = false

        local inner = Instance.new("Frame", frame)
        inner.Size = UDim2.new(1, 0, 0, 0)
        inner.Position = UDim2.new(0, 0, 0, 24 * sf)
        inner.BackgroundTransparency = 1
        inner.AutomaticSize = Enum.AutomaticSize.Y
        inner.Visible = false
        local layout = Instance.new("UIListLayout", inner)
        layout.Padding = UDim.new(0, 4 * sf)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        local pad = Instance.new("UIPadding", inner)
        pad.PaddingLeft = UDim.new(0, 6 * sf)
        pad.PaddingRight = UDim.new(0, 6 * sf)
        pad.PaddingTop = UDim.new(0, 4 * sf)
        pad.PaddingBottom = UDim.new(0, 4 * sf)

        local collapsed = true
        header.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            header.Text = collapsed and "▸ " .. title or "▾ " .. title
            inner.Visible = not collapsed
            if collapsed then
                frame.Size = UDim2.new(1, 0, 0, 24 * sf)
                frame.AutomaticSize = Enum.AutomaticSize.None
            else
                frame.Size = UDim2.new(1, 0, 0, 0)
                frame.AutomaticSize = Enum.AutomaticSize.Y
            end
        end)
        return inner
    end

    local function makeBtn(parent, text, cb)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 30 * sf)
        btn.BackgroundColor3 = Color3.fromRGB(0,51,255)
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.fromRGB(0,0,0)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = 11 * sf
        btn.Font = Enum.Font.ArialBold
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    local function makeToggle(parent, text, default, cb, adminOnly)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 30 * sf)
        frame.BackgroundColor3 = Color3.fromRGB(179,179,179)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(0,0,0)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0.05, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(0,0,0)
        lbl.TextSize = 10 * sf
        lbl.Font = Enum.Font.Arial
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local state = default or false
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 56 * sf, 0, 22 * sf)
        btn.Position = UDim2.new(1, -62 * sf, 0.5, -11 * sf)
        btn.BackgroundColor3 = state and Color3.fromRGB(0,51,255) or Color3.fromRGB(150,150,150)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(0,0,0)
        btn.Text = state and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = 10 * sf
        btn.Font = Enum.Font.ArialBold
        btn.AutoButtonColor = false

        local isAdmin = (LocalPlayer.UserId == ADMIN_ID)
        if adminOnly and not isAdmin then
            btn.BackgroundColor3 = Color3.fromRGB(150,150,150)
            btn.TextColor3 = Color3.fromRGB(200,200,200)
            btn.Text = state and "ON" or "OFF"
            btn.MouseButton1Click:Connect(function() end)
        else
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = state and "ON" or "OFF"
                btn.BackgroundColor3 = state and Color3.fromRGB(0,51,255) or Color3.fromRGB(150,150,150)
                if cb then pcall(cb, state) end
            end)
        end
        return frame
    end

    local function makeSlider(parent, text, min, max, default, cb)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 40 * sf)
        frame.BackgroundColor3 = Color3.fromRGB(179,179,179)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(0,0,0)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, 0, 0, 16 * sf)
        lbl.Position = UDim2.new(0, 6 * sf, 0, 2 * sf)
        lbl.BackgroundTransparency = 1
        lbl.Text = text .. ": " .. tostring(default)
        lbl.TextColor3 = Color3.fromRGB(0,0,0)
        lbl.TextSize = 10 * sf
        lbl.Font = Enum.Font.Arial
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local track = Instance.new("Frame", frame)
        track.Size = UDim2.new(0.85, 0, 0, 8 * sf)
        track.Position = UDim2.new(0.05, 0, 0, 22 * sf)
        track.BackgroundColor3 = Color3.fromRGB(150,150,150)
        track.BorderSizePixel = 1
        track.BorderColor3 = Color3.fromRGB(0,0,0)

        local fill = Instance.new("Frame", track)
        fill.BackgroundColor3 = Color3.fromRGB(0,51,255)
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)

        local thumb = Instance.new("Frame", track)
        thumb.Size = UDim2.new(0, 18 * sf, 0, 18 * sf)
        thumb.Position = UDim2.new((default - min) / (max - min), -9 * sf, 0.5, -9 * sf)
        thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
        thumb.BorderSizePixel = 1
        thumb.BorderColor3 = Color3.fromRGB(0,0,0)

        local val = default
        local dragging = false
        local dragConn = nil
        local endConn = nil

        local function update(pos)
            local trackPos, trackSize = track.AbsolutePosition, track.AbsoluteSize
            if trackPos.X == 0 and trackSize.X == 0 then
                task.wait()
                trackPos, trackSize = track.AbsolutePosition, track.AbsoluteSize
            end
            local rel = math.clamp((pos.X - trackPos.X) / trackSize.X, 0, 1)
            val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -9 * sf, 0.5, -9 * sf)
            lbl.Text = text .. ": " .. tostring(val)
            if cb then pcall(cb, val) end
        end

        local function startDrag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position)
                if dragConn then dragConn:Disconnect() end
                if endConn then endConn:Disconnect() end
                dragConn = UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input.Position)
                    end
                end)
                endConn = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        if dragConn then dragConn:Disconnect(); dragConn = nil end
                        if endConn then endConn:Disconnect(); endConn = nil end
                    end
                end)
            end
        end

        track.InputBegan:Connect(startDrag)
        thumb.InputBegan:Connect(startDrag)
        return frame
    end

    local function makeDropdown(parent, text, options, default, cb)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 30 * sf)
        frame.BackgroundColor3 = Color3.fromRGB(179,179,179)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(0,0,0)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0.05, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(0,0,0)
        lbl.TextSize = 10 * sf
        lbl.Font = Enum.Font.Arial
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local idx = 1
        for i, v in ipairs(options) do
            if v == default then idx = i end
        end
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 80 * sf, 0, 22 * sf)
        btn.Position = UDim2.new(1, -86 * sf, 0.5, -11 * sf)
        btn.BackgroundColor3 = Color3.fromRGB(0,51,255)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(0,0,0)
        btn.Text = options[idx]
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = 10 * sf
        btn.Font = Enum.Font.ArialBold
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            btn.Text = options[idx]
            if cb then pcall(cb, options[idx]) end
        end)
        return frame
    end

    local speedBoostEnabled = false
    local originalWalkSpeed = 16

    local function applySpeedBoost(state)
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        if state then
            if originalWalkSpeed == 16 or originalWalkSpeed == 0 then
                originalWalkSpeed = humanoid.WalkSpeed
            end
            humanoid.WalkSpeed = 20
            sendNotification("⚡ Speed Boost", "WalkSpeed set to 20", 3)
        else
            if originalWalkSpeed == 0 then originalWalkSpeed = 16 end
            humanoid.WalkSpeed = originalWalkSpeed
            sendNotification("⚡ Speed Boost", "WalkSpeed restored to " .. tostring(originalWalkSpeed), 3)
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        if speedBoostEnabled then
            task.wait(0.5)
            applySpeedBoost(true)
        end
    end)

    local espEnabled = false
    local espLoopConn = nil
    local espHighlights = {}
    local espHue = 0
    local espEventConnections = {}

    local function addESPForPlayer(player)
        if player == LocalPlayer then return end
        if espHighlights[player] then
            pcall(function() espHighlights[player]:Destroy() end)
            espHighlights[player] = nil
        end
        local char = player.Character
        if not char then return end
        local highlight = Instance.new("Highlight")
        highlight.Adornee = char
        highlight.FillColor = Color3.fromHSV(espHue, 1, 0.8)
        highlight.OutlineColor = Color3.fromHSV(espHue, 1, 0.8)
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.DepthMode.AlwaysOnTop
        highlight.Enabled = true
        highlight.Parent = char
        espHighlights[player] = highlight
    end

    local function removeESPForPlayer(player)
        local highlight = espHighlights[player]
        if highlight then pcall(function() highlight:Destroy() end) end
        espHighlights[player] = nil
    end

    local function updateESPColors()
        espHue = (espHue + 0.005) % 1
        local color = Color3.fromHSV(espHue, 1, 0.8)
        for _, highlight in pairs(espHighlights) do
            if highlight and highlight.Parent then
                highlight.FillColor = color
                highlight.OutlineColor = color
            end
        end
    end

    local function setupPlayerESP(player)
        if player == LocalPlayer then return end
        if espEventConnections[player] then
            pcall(function() espEventConnections[player]:Disconnect() end)
            espEventConnections[player] = nil
        end
        local conn = player.CharacterAdded:Connect(function(char)
            if espEnabled then
                removeESPForPlayer(player)
                addESPForPlayer(player)
            end
        end)
        espEventConnections[player] = conn
        if player.Character then
            addESPForPlayer(player)
        end
    end

    local function startESP()
        if espEnabled then return end
        espEnabled = true
        espHighlights = {}
        espHue = 0

        for _, conn in pairs(espEventConnections) do
            pcall(function() conn:Disconnect() end)
        end
        espEventConnections = {}

        for _, player in ipairs(Players:GetPlayers()) do
            setupPlayerESP(player)
        end

        local playerAddedConn = Players.PlayerAdded:Connect(function(player)
            setupPlayerESP(player)
        end)
        espEventConnections["PlayerAdded"] = playerAddedConn

        local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
            removeESPForPlayer(player)
            if espEventConnections[player] then
                pcall(function() espEventConnections[player]:Disconnect() end)
                espEventConnections[player] = nil
            end
        end)
        espEventConnections["PlayerRemoving"] = playerRemovingConn

        espLoopConn = RunService.Heartbeat:Connect(function()
            if espEnabled then updateESPColors() end
        end)

        sendNotification("🌈 ESP", "Highlight ESP enabled", 3)
    end

    local function stopESP()
        espEnabled = false
        if espLoopConn then
            espLoopConn:Disconnect()
            espLoopConn = nil
        end
        for _, conn in pairs(espEventConnections) do
            pcall(function() conn:Disconnect() end)
        end
        espEventConnections = {}
        for _, highlight in pairs(espHighlights) do
            pcall(function() highlight:Destroy() end)
        end
        espHighlights = {}
        sendNotification("🌈 ESP", "Highlight ESP disabled", 3)
    end

    local teamNotifyEnabled = false
    local teamCache = {}
    local function notifyTeamChange(player, oldTeam, newTeam)
        if not teamNotifyEnabled or player == LocalPlayer then return end
        local oldName = oldTeam and oldTeam.Name or "なし"
        local newName = newTeam and newTeam.Name or "なし"
        if oldTeam ~= newTeam then sendNotification("🔄 Team Change", player.Name .. " " .. oldName .. " → " .. newName) end
    end
    local function notifyPlayerLeave(player)
        if not teamNotifyEnabled or player == LocalPlayer then return end
        sendNotification("👋 Leave", "Player: " .. player.Name .. " left")
    end
    local teamChangedConn, playerRemovingConn = nil, nil
    local function startTeamNotify()
        if teamNotifyEnabled then return end
        teamNotifyEnabled = true
        teamCache = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                teamCache[player] = player.Team
                player:GetPropertyChangedSignal("Team"):Connect(function()
                    local oldTeam = teamCache[player]
                    local newTeam = player.Team
                    notifyTeamChange(player, oldTeam, newTeam)
                    teamCache[player] = newTeam
                end)
            end
        end
        teamChangedConn = Players.PlayerAdded:Connect(function(player)
            if player == LocalPlayer then return end
            teamCache[player] = player.Team
            player:GetPropertyChangedSignal("Team"):Connect(function()
                local oldTeam = teamCache[player]
                local newTeam = player.Team
                notifyTeamChange(player, oldTeam, newTeam)
                teamCache[player] = newTeam
            end)
        end)
        playerRemovingConn = Players.PlayerRemoving:Connect(notifyPlayerLeave)
    end
    local function stopTeamNotify()
        teamNotifyEnabled = false
        if teamChangedConn then teamChangedConn:Disconnect(); teamChangedConn = nil end
        if playerRemovingConn then playerRemovingConn:Disconnect(); playerRemovingConn = nil end
    end

    local slapRemote = ReplicatedStorage:FindFirstChild("lol")
    local slapEnabled = false
    local slapConn = nil
    local slapMode = "auto"
    local slapRadius = 10
    local slapIndex = 1
    local slapIgnoreFriends = true

    local function isFriendWith(p1, p2)
        if p2 and p2.UserId == ADMIN_ID then return true end
        return p1:IsFriendsWith(p2.UserId)
    end

    local function slapPlayer(p)
        if not slapRemote then return end
        local c = p.Character
        if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local args = {"slash", c, r.Position + Vector3.new(0,2.5,0)}
        for _=1,15 do
            pcall(function() slapRemote:FireServer(table.unpack(args)) end)
            task.wait()
        end
    end

    local function getPlayersInRadius(r)
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return {} end
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if slapIgnoreFriends and isFriendWith(LocalPlayer, p) then continue end
                local pr = p.Character:FindFirstChild("HumanoidRootPart")
                if pr and (root.Position - pr.Position).Magnitude <= r then table.insert(list, p) end
            end
        end
        return list
    end

    local function slapLoop()
        if not slapEnabled then return end
        if slapMode == "all" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and not (slapIgnoreFriends and isFriendWith(LocalPlayer, p)) then slapPlayer(p) end
            end
        else
            local players = getPlayersInRadius(slapRadius)
            if #players > 0 then
                if slapIndex > #players then slapIndex = 1 end
                slapPlayer(players[slapIndex])
                slapIndex = slapIndex + 1
            end
        end
    end

    local function startSlap()
        if slapConn then return end
        slapEnabled = true
        slapConn = RunService.Heartbeat:Connect(slapLoop)
    end
    local function stopSlap()
        slapEnabled = false
        if slapConn then slapConn:Disconnect(); slapConn = nil end
    end

    local ringEnabled = false
    local ringConn = nil
    local ringParts = {}
    local ringSpeed = 120
    local ringRadius = 15
    local ringHeight = 20
    local ringScanTime = 0

    local function isLocalPlayerPart(p)
        if not p then return false end
        local c = LocalPlayer.Character
        if c and p:IsDescendantOf(c) then return true end
        return false
    end

    local function getAllMovableParts()
        local parts = {}
        local function scan(obj, d)
            if d > 100 then return end
            for _, c in ipairs(obj:GetChildren()) do
                if c:IsA("BasePart") and not c.Anchored and not isLocalPlayerPart(c) then
                    table.insert(parts, c)
                elseif c:IsA("Model") or c:IsA("Folder") then
                    scan(c, (d or 0)+1)
                end
            end
        end
        scan(Workspace, 0)
        return parts
    end

    local function breakRingWelds()
        for p, data in pairs(ringParts) do
            if p and p.Parent then
                for _, child in ipairs(p:GetChildren()) do
                    if child:IsA("JointInstance") or child:IsA("Constraint") then child:Destroy() end
                end
            end
        end
    end

    local function ringLoop()
        local last = tick()
        while ringEnabled do
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local now = tick()
                local dt = math.min(0.033, now - last)
                last = now
                local step = math.rad(ringSpeed) * dt
                if now - ringScanTime > 2 then
                    ringScanTime = now
                    local current = getAllMovableParts()
                    for _, p in ipairs(current) do
                        if not ringParts[p] then
                            local sound = Instance.new("Sound")
                            sound.SoundId = MUSIC_ID
                            sound.Looped = true
                            sound.Playing = true
                            sound.Volume = SOUND_VOLUME
                            sound.PlaybackSpeed = SOUND_SPEED
                            sound.Parent = p
                            ringParts[p] = { bv = nil, ang = math.random() * 2 * math.pi, off = math.random() * 0.8 + 0.2, sound = sound }
                            p.CanCollide = false
                        end
                    end
                    for p in pairs(ringParts) do
                        if not p.Parent or p.Anchored or isLocalPlayerPart(p) then
                            local data = ringParts[p]
                            if data then
                                if data.bv then pcall(function() data.bv:Destroy() end) end
                                if data.sound then pcall(function() data.sound:Destroy() end) end
                            end
                            ringParts[p] = nil
                        end
                    end
                end
                for p, data in pairs(ringParts) do
                    if not p.Parent then continue end
                    data.ang = data.ang + step * (0.8 + math.random()*0.4)
                    local r = ringRadius * data.off
                    local x = math.cos(data.ang) * r
                    local z = math.sin(data.ang) * r
                    local y = math.sin(data.ang * 0.5) * ringHeight * 0.3 + ringHeight * 0.3 + 1
                    local target = root.Position + Vector3.new(x, y, z)
                    local bv = data.bv
                    if not bv or not bv.Parent then
                        bv = Instance.new("BodyVelocity")
                        bv.MaxForce = Vector3.new(400000, 400000, 400000)
                        bv.P = 5000
                        bv.Parent = p
                        data.bv = bv
                    end
                    bv.Velocity = (target - p.Position) * 4
                end
            end
            task.wait()
        end
        for p, data in pairs(ringParts) do
            if data then
                if data.bv then pcall(function() data.bv:Destroy() end) end
                if data.sound then pcall(function() data.sound:Destroy() end) end
            end
            if p then p.CanCollide = true end
        end
        ringParts = {}
    end
    local function startRing()
        if ringConn then return end
        ringEnabled = true
        ringParts = {}
        ringScanTime = 0
        ringConn = task.spawn(ringLoop)
    end
    local function stopRing()
        ringEnabled = false
        if ringConn then coroutine.close(ringConn); ringConn = nil end
        for p, data in pairs(ringParts) do
            if data then
                if data.bv then pcall(function() data.bv:Destroy() end) end
                if data.sound then pcall(function() data.sound:Destroy() end) end
            end
            if p then p.CanCollide = true end
        end
        ringParts = {}
    end

    local antiLaserEnabled = false
    local antiLaserConn = nil
    local antiLaserDescendantConn = nil
    local antiLaserHeartbeatConn = nil
    local antiLaserCount = 0

    local function isEffectPart(part)
        if not part or not part:IsA("BasePart") then return false end
        return part.Name == "Effect"
    end

    local function handleEffectPart(part)
        if not part or not part.Parent then return false end
        if isEffectPart(part) then
            pcall(function()
                part.Anchored = true
                part.CanCollide = false
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (part.Position - root.Position).Magnitude
                    if dist <= 10 then
                        local angle = math.random() * 2 * math.pi
                        local offset = Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
                        part.CFrame = CFrame.new(root.Position + offset)
                    end
                end
                antiLaserCount = antiLaserCount + 1
            end)
            return true
        end
        return false
    end

    local function scanAndHandleAllEffects()
        local count = 0
        for _, c in ipairs(Workspace:GetDescendants()) do
            if c:IsA("BasePart") and isEffectPart(c) then
                handleEffectPart(c)
                count = count + 1
            end
        end
        antiLaserCount = antiLaserCount + count
        return count
    end

    local function setupAntiLaserWatcher()
        if antiLaserDescendantConn then return end
        antiLaserDescendantConn = Workspace.DescendantAdded:Connect(function(descendant)
            if antiLaserEnabled and isEffectPart(descendant) then handleEffectPart(descendant) end
        end)
    end

    local function antiLaserLoop()
        scanAndHandleAllEffects()
        setupAntiLaserWatcher()
        if not antiLaserHeartbeatConn then
            antiLaserHeartbeatConn = RunService.Heartbeat:Connect(function()
                if antiLaserEnabled then scanAndHandleAllEffects() end
            end)
        end
        while antiLaserEnabled do
            scanAndHandleAllEffects()
            task.wait(0.1)
        end
    end

    local function startAntiLaser()
        if antiLaserConn then return end
        antiLaserEnabled = true
        antiLaserCount = 0
        antiLaserConn = task.spawn(antiLaserLoop)
    end
    local function stopAntiLaser()
        antiLaserEnabled = false
        if antiLaserConn then coroutine.close(antiLaserConn); antiLaserConn = nil end
        if antiLaserDescendantConn then antiLaserDescendantConn:Disconnect(); antiLaserDescendantConn = nil end
        if antiLaserHeartbeatConn then antiLaserHeartbeatConn:Disconnect(); antiLaserHeartbeatConn = nil end
    end

    local antiSlapEnabled = false
    local antiSlapConnection = nil
    local antiSlapCleanupConn = nil
    local antiSlapVelocityConn = nil
    local antiSlapSteppedConn = nil
    local antiSlapRenderConn = nil
    local antiSlapDescendantConn = nil

    local function removeKnockbackForces(char)
        if not char then return end
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("BodyVelocity") or child:IsA("BodyForce") or child:IsA("BodyThrust") or child:IsA("BodyAngularVelocity")
            or child:IsA("RocketPropulsion") or child:IsA("LinearVelocity") or child:IsA("AngularVelocity") then
                child:Destroy()
            end
        end
    end

    local function onCharacterDescendantAdded(desc)
        if desc:IsA("BodyVelocity") or desc:IsA("BodyForce") or desc:IsA("BodyThrust") or desc:IsA("BodyAngularVelocity")
        or desc:IsA("RocketPropulsion") or desc:IsA("LinearVelocity") or desc:IsA("AngularVelocity") then
            desc:Destroy()
        end
    end

    local function enableAntiSlap()
        if antiSlapConnection then return end

        local slapEvent = ReplicatedStorage:FindFirstChild("lol")
        if slapEvent then antiSlapConnection = slapEvent.OnClientEvent:Connect(function() end) end

        antiSlapCleanupConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then removeKnockbackForces(char) end
        end)

        antiSlapSteppedConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude > 12 or math.abs(vel.Y) > 2.5 then
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                root.Anchored = true
                task.spawn(function()
                    task.wait(0.03)
                    if root and root.Parent then root.Anchored = false end
                end)
            end
        end)

        antiSlapVelocityConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude > 12 or math.abs(vel.Y) > 2.5 then
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                root.Anchored = true
                task.spawn(function()
                    task.wait(0.03)
                    if root and root.Parent then root.Anchored = false end
                end)
            end
        end)

        antiSlapRenderConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local vel = root.AssemblyLinearVelocity
            if vel.Magnitude > 12 or math.abs(vel.Y) > 2.5 then
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                root.Anchored = true
                task.spawn(function()
                    task.wait(0.03)
                    if root and root.Parent then root.Anchored = false end
                end)
            end
        end)

        local char = LocalPlayer.Character
        if char then
            antiSlapDescendantConn = char.DescendantAdded:Connect(onCharacterDescendantAdded)
        end

        LocalPlayer.CharacterAdded:Connect(function(newChar)
            if antiSlapEnabled then
                if antiSlapDescendantConn then
                    antiSlapDescendantConn:Disconnect()
                    antiSlapDescendantConn = nil
                end
                antiSlapDescendantConn = newChar.DescendantAdded:Connect(onCharacterDescendantAdded)
                removeKnockbackForces(newChar)
            end
        end)
    end

    local function disableAntiSlap()
        if antiSlapConnection then antiSlapConnection:Disconnect(); antiSlapConnection = nil end
        if antiSlapCleanupConn then antiSlapCleanupConn:Disconnect(); antiSlapCleanupConn = nil end
        if antiSlapVelocityConn then antiSlapVelocityConn:Disconnect(); antiSlapVelocityConn = nil end
        if antiSlapSteppedConn then antiSlapSteppedConn:Disconnect(); antiSlapSteppedConn = nil end
        if antiSlapRenderConn then antiSlapRenderConn:Disconnect(); antiSlapRenderConn = nil end
        if antiSlapDescendantConn then antiSlapDescendantConn:Disconnect(); antiSlapDescendantConn = nil end
    end

    local lavaAuto = false
    local lavaConn = nil
    local function deleteLava()
        local count = 0
        local function rec(obj)
            for _, c in ipairs(obj:GetChildren()) do
                if c:IsA("BasePart") and c.Name:lower() == "lava" then
                    c:Destroy()
                    count = count + 1
                elseif c:IsA("Model") or c:IsA("Folder") then
                    rec(c)
                end
            end
        end
        rec(Workspace)
        return count
    end
    local function lavaLoop()
        while lavaAuto do
            deleteLava()
            task.wait(1)
        end
    end
    local function startAntiLava()
        if lavaConn then return end
        lavaAuto = true
        lavaConn = task.spawn(lavaLoop)
    end
    local function stopAntiLava()
        lavaAuto = false
        if lavaConn then coroutine.close(lavaConn); lavaConn = nil end
    end

    local function getTools()
        local tools = {}
        local function scan(c)
            for _, v in ipairs(c:GetChildren()) do
                if v:IsA("Tool") then
                    table.insert(tools, v)
                else
                    scan(v)
                end
            end
        end
        scan(ReplicatedStorage)
        return tools
    end
    local function giveTool(t)
        local bp = LocalPlayer:FindFirstChild("Backpack") or Instance.new("Folder")
        bp.Name = "Backpack"
        bp.Parent = LocalPlayer
        t.Parent = bp
    end

    local swordEnabled = false
    local swordConn = nil
    local swordRange = 10
    local swordIgnoreFriends = true
    local function swordLoop()
        while swordEnabled do
            local char = LocalPlayer.Character
            if not char then task.wait(0.02); continue end
            local tool = char:FindFirstChildOfClass("Tool")
            if not tool then task.wait(0.02); continue end
            local handle = tool:FindFirstChild("Handle")
            if not handle then task.wait(0.02); continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then task.wait(0.02); continue end
            for _, other in ipairs(Players:GetPlayers()) do
                if other == LocalPlayer then continue end
                if swordIgnoreFriends and isFriendWith(LocalPlayer, other) then continue end
                local otherChar = other.Character
                if not otherChar then continue end
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                if not otherRoot then continue end
                if (root.Position - otherRoot.Position).Magnitude <= swordRange then
                    tool:Activate()
                    for _, part in ipairs(otherChar:GetDescendants()) do
                        if part:IsA("BasePart") then
                            pcall(function()
                                firetouchinterest(handle, part, 0)
                                firetouchinterest(handle, part, 1)
                            end)
                        end
                    end
                    task.wait(0.001)
                end
            end
            task.wait(0.02)
        end
    end
    local function startSword()
        if swordConn then return end
        swordEnabled = true
        swordConn = task.spawn(swordLoop)
    end
    local function stopSword()
        swordEnabled = false
        if swordConn then coroutine.close(swordConn); swordConn = nil end
    end

    local deathNotifyEnabled = false
    local deathNotifyConn = nil
    local lastTouchedPart = nil
    local deathNotifyCharConn = nil
    local function monitorTouches()
        while deathNotifyEnabled do
            local char = LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, part in ipairs(root:GetTouchingParts()) do
                        if not part:IsDescendantOf(char) then
                            lastTouchedPart = part
                            break
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end
    local function onPlayerDied()
        if not deathNotifyEnabled then return end
        local name = lastTouchedPart and lastTouchedPart.Name or "Unknown"
        sendNotification("💀 Death", "Last touched part: " .. name)
    end
    local function setupDeathNotify()
        if deathNotifyCharConn then deathNotifyCharConn:Disconnect() end
        deathNotifyCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
            local humanoid = char:WaitForChild("Humanoid")
            if humanoid then humanoid.Died:Connect(onPlayerDied) end
        end)
    end
    local function startDeathNotify()
        if deathNotifyConn then return end
        deathNotifyEnabled = true
        lastTouchedPart = nil
        setupDeathNotify()
        deathNotifyConn = task.spawn(monitorTouches)
    end
    local function stopDeathNotify()
        deathNotifyEnabled = false
        if deathNotifyConn then coroutine.close(deathNotifyConn); deathNotifyConn = nil end
        if deathNotifyCharConn then deathNotifyCharConn:Disconnect(); deathNotifyCharConn = nil end
    end

    local mainTab = TabContents["main"]
    local antiTab = TabContents["anti"]
    local funTab = TabContents["fun"]
    local playerTab = TabContents["player"]

    local sSpeed = makeSection(playerTab, "⚡ Speed Boost")
    makeToggle(sSpeed, "Speed Boost (WalkSpeed 20)", false, function(v)
        speedBoostEnabled = v
        applySpeedBoost(v)
    end)

    local sESP = makeSection(playerTab, "🌈 ESP (Highlight)")
    makeToggle(sESP, "Enable Player Highlight", false, function(v)
        if v then startESP() else stopESP() end
    end)

    local sSlap = makeSection(mainTab, "⚔️ Slap")
    makeToggle(sSlap, "Auto Slap", false, function(v) if v then startSlap() else stopSlap() end end)
    makeBtn(sSlap, "👊 Slap All", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not (slapIgnoreFriends and isFriendWith(LocalPlayer, p)) then
                slapPlayer(p)
            end
        end
    end)
    makeSlider(sSlap, "Slap Radius", 5, 500, 10, function(v) slapRadius = v end)
    makeDropdown(sSlap, "Mode", {"Auto", "All", "Single"}, "Auto", function(v)
        if v == "Auto" then slapMode = "auto" elseif v == "All" then slapMode = "all" else slapMode = "single" end
    end)
    makeToggle(sSlap, "Ignore Friends", true, function(v) slapIgnoreFriends = v end, true)

    local sSword = makeSection(mainTab, "⚔️ Sword")
    makeToggle(sSword, "Auto Sword", false, function(v) if v then startSword() else stopSword() end end)
    makeSlider(sSword, "Range", 3, 500, 10, function(v) swordRange = v end)
    makeToggle(sSword, "Ignore Friends", true, function(v) swordIgnoreFriends = v end, true)

    local sRing = makeSection(mainTab, "⭕ Ring")
    makeToggle(sRing, "Enable Ring", false, function(v) if v then startRing() else stopRing() end end)
    makeSlider(sRing, "Speed", 30, 5000, 120, function(v) ringSpeed = v end)
    makeSlider(sRing, "Radius", 5, 200, 15, function(v) ringRadius = v end)
    makeSlider(sRing, "Height", 5, 100, 20, function(v) ringHeight = v end)
    makeBtn(sRing, "🔧 Break All Joints", breakRingWelds)

    local sAntiLava = makeSection(antiTab, "🔥 Anti-Lava (Auto Remove)")
    makeToggle(sAntiLava, "Auto Remove Lava", false, function(v) if v then startAntiLava() else stopAntiLava() end end)

    local sAntiLaser = makeSection(antiTab, "🔫 Anti-Laser")
    makeToggle(sAntiLaser, "Disable & Dodge Effect", false, function(v) if v then startAntiLaser() else stopAntiLaser() end end)

    local sAntiSlap = makeSection(antiTab, "🛡️ Anti-KB (最強)")
    makeToggle(sAntiSlap, "Block Slap / Knockback", false, function(v) if v then enableAntiSlap() else disableAntiSlap() end end)

    local sItem = makeSection(funTab, "📦 Item Grabber")
    makeBtn(sItem, "📦 Get Tool", function()
        local tools = getTools()
        if #tools > 0 then giveTool(tools[1]) end
    end)

    local sDeath = makeSection(funTab, "💀 Death Notify")
    makeToggle(sDeath, "Notify on Death", false, function(v) if v then startDeathNotify() else stopDeathNotify() end end)

    local sTeam = makeSection(funTab, "🔔 Team Notify")
    makeToggle(sTeam, "Team Change/Leave Notify", false, function(v) if v then startTeamNotify() else stopTeamNotify() end end)
end

createPasswordGUI(createMainHub)
