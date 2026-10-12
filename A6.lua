if _G.a then
    for _, v in pairs(_G.a) do
        v:Disconnect()
    end
    _G.a = nil
end

repeat task.wait() until game.Players.LocalPlayer

local player = game.Players.LocalPlayer
local character, humanoid, rootPart
local invisible = false
local parts = {}

local function initCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    parts = {}
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency == 0 then
            table.insert(parts, descendant)
        end
    end
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 50)
    button.Position = UDim2.new(0.5, -50, 0.1, 0)
    button.Text = "Invisible"
    button.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    button.Parent = screenGui
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local dragging = false
    local dragStart, startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    button.MouseButton1Click:Connect(function()
        invisible = not invisible
        for _, part in pairs(parts) do
            part.Transparency = part.Transparency == 0 and 0.5 or 0
        end
    end)
end

initCharacter()
createUI()

local connections = {}

connections[1] = player:GetMouse().KeyDown:Connect(function(key)
    if key == "g" then
        invisible = not invisible
        for _, part in pairs(parts) do
            part.Transparency = part.Transparency == 0 and 0.5 or 0
        end
    end
end)

connections[2] = game:GetService("RunService").Heartbeat:Connect(function()
    if invisible then
        local originalCFrame = rootPart.CFrame
        local originalOffset = humanoid.CameraOffset
        local hiddenCFrame = originalCFrame * CFrame.new(0, -200, 0)
        local offsetPos = hiddenCFrame:ToObjectSpace(CFrame.new(originalCFrame.Position)).Position
        rootPart.CFrame = hiddenCFrame
        humanoid.CameraOffset = offsetPos
        game:GetService("RunService").RenderStepped:Wait()
        rootPart.CFrame = originalCFrame
        humanoid.CameraOffset = originalOffset
    end
end)

player.CharacterAdded:Connect(function()
    invisible = false
    initCharacter()
    createUI()
end)

_G.a = connections
