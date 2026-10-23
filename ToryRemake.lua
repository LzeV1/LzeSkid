if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(0.1)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer

local currentMode = "VOID"
local isProcessing = false
local originalPos = nil
local allowTeleportBack = false
local selectedToolName = nil
local switchedToR6 = false

local OrgDestroyHeight = workspace.FallenPartsDestroyHeight or -500
local EXTREME_VOID_CFRAME = CFrame.new(9e9, 9999999, 9e9)
local ANTI_VOID_HEIGHT = -9e9

local function FireServerCmd(...)
    return ReplicatedStorage:WaitForChild("01_server"):FireServer(...)
end

local function ForceServerReset() FireServerCmd("cmd", "-re") end
local function RemoveHats() FireServerCmd("cmd", "-ch") end
local function ChangeToR6() FireServerCmd("cmd", "-r6") end
local function ChangeToR15() FireServerCmd("cmd", "-r15") end

local function GetPlr(name)
    if not name or name == "" then return end
    name = name:lower():gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
    for _, a in Players:GetPlayers() do
        if a ~= lp then
            local char = a.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local n, d = a.Name:lower(), a.DisplayName:lower()
                    if n:find("^" .. name) or d:find("^" .. name) then
                        return a
                    end
                end
            end
        end
    end
end

local function mainRun(targetName)
    local target = GetPlr(targetName)
    if not target then return false end

    local targetchar = target.Character
    if not targetchar then return false end

    local targethrp = targetchar:FindFirstChild("HumanoidRootPart") or targetchar:WaitForChild("HumanoidRootPart", 5)
    if not targethrp then return false end

    local char = lp.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local backpack = lp:FindFirstChild("Backpack")
    if not backpack then return false end

    local Tool = selectedToolName and (char:FindFirstChild(selectedToolName) or backpack:FindFirstChild(selectedToolName)) or (char:FindFirstChildOfClass("Tool") or backpack:FindFirstChildOfClass("Tool"))
    if not Tool then return "NO TOOL" end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        ChangeToR6()
        switchedToR6 = true
        task.wait(0.35)
        char = lp.Character
        if not char then return false end
        hrp = char:FindFirstChild("HumanoidRootPart")
        backpack = lp:FindFirstChild("Backpack")
        if not backpack then return false end
        Tool = selectedToolName and (char:FindFirstChild(selectedToolName) or backpack:FindFirstChild(selectedToolName)) or (char:FindFirstChildOfClass("Tool") or backpack:FindFirstChildOfClass("Tool"))
        if not Tool then return "NO TOOL" end
    end

    task.wait(0.2)
    RemoveHats()

    local originalDestroyHeight = workspace.FallenPartsDestroyHeight

    if currentMode == "GIVE" then
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        if char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):Destroy()
        end
        task.wait(0.05)
        Instance.new("Humanoid").Parent = char
        Tool.Parent = char
        local handle = Tool:FindFirstChild("Handle")
        local giveStart = os.clock()
        while Tool.Parent == char and (os.clock() - giveStart) < 3 do
            task.wait()
            pcall(function()
                if hrp then hrp.CFrame = targethrp.CFrame end
                if handle then handle.CFrame = targethrp.CFrame end
            end)
        end
        workspace.FallenPartsDestroyHeight = originalDestroyHeight
        lp.Character = nil
        FireServerCmd("cmd", "-rs")
        ForceServerReset()
        return true
    end

    char.Archivable = true
    local Clone = char:Clone()
    task.wait(0.05)
    lp.Character = Clone
    task.wait(0.1)
    lp.Character = char
    task.wait(0.1)
    if Clone and Clone.Parent then Clone:Destroy() end

    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
    if char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):Destroy()
    end
    task.wait(0.05)

    Instance.new("Humanoid").Parent = char
    task.wait(0.05)

    Tool.Grip = CFrame.new(0, 0, 0)
    Tool.Parent = char
    local handle = Tool:FindFirstChild("Handle")

    local noclipConn = RunService.Stepped:Connect(function()
        if char and char.Parent then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end)

    local hasInteracted = false
    local interactTime = 0
    local startTime = os.clock()

    repeat
        RunService.Stepped:Wait()
        if not Tool or not Tool:IsDescendantOf(game) then break end
        if Tool.Parent ~= char and Tool.Parent ~= targetchar and Tool.Parent ~= workspace then break end
        if not hasInteracted and (os.clock() - startTime > 5.0) then break end

        if targetchar and targethrp and hrp then
            if Tool.Parent == targetchar and not hasInteracted then
                hasInteracted = true
                interactTime = os.clock()
                if currentMode == "BRING" then
                    task.wait(0.15)
                    break
                else
                    task.wait(0.02)
                end
            end

            if hasInteracted then
                if currentMode == "VOID" then
                    workspace.FallenPartsDestroyHeight = ANTI_VOID_HEIGHT
                    local voidCFrame = CFrame.new(hrp.Position.X, (OrgDestroyHeight or originalDestroyHeight or -500) - 25, hrp.Position.Z)
                    hrp.CFrame = voidCFrame
                    pcall(function()
                        targethrp.CFrame = voidCFrame
                        targethrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end)
                    if os.clock() - interactTime > 1.5 then break end
                elseif currentMode == "EXTREME" then
                    workspace.FallenPartsDestroyHeight = ANTI_VOID_HEIGHT
                    hrp.CFrame = EXTREME_VOID_CFRAME
                    pcall(function()
                        targethrp.CFrame = EXTREME_VOID_CFRAME
                        targethrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end)
                    if os.clock() - interactTime > 2.0 then break end
                elseif currentMode == "BRING" then
                    if originalPos then
                        hrp.CFrame = originalPos
                        pcall(function()
                            targethrp.CFrame = originalPos
                            targethrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end)
                    end
                    if os.clock() - interactTime > 1.8 then break end
                end
            else
                if currentMode == "EXTREME" then
                    pcall(function() hrp.CFrame = targethrp.CFrame end)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                elseif currentMode == "VOID" then
                    workspace.FallenPartsDestroyHeight = ANTI_VOID_HEIGHT
                    if originalPos then
                        local preVoid = CFrame.new(originalPos.Position.X, (OrgDestroyHeight or originalDestroyHeight or -500) - 25, originalPos.Position.Z)
                        hrp.CFrame = preVoid
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                    pcall(function()
                        if handle then
                            targethrp.CFrame = handle.CFrame
                            targethrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end
                    end)
                else
                    pcall(function()
                        if handle then
                            targethrp.CFrame = handle.CFrame
                            targethrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        end
                    end)
                    if originalPos then
                        hrp.CFrame = originalPos
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        else
            break
        end
    until Tool.Parent == workspace

    workspace.FallenPartsDestroyHeight = originalDestroyHeight
    if noclipConn then noclipConn:Disconnect() end

    if currentMode == "BRING" then
        if hrp and originalPos then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.CFrame = originalPos
            pcall(function()
                targethrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                targethrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                targethrp.CFrame = originalPos
            end)
            task.wait(0.4)
        end
    else
        if hrp and originalPos then
            hrp.CFrame = originalPos
            RunService.Heartbeat:Wait()
        end
    end
    lp.Character = nil
    return true
end

local function WaitForCharacterAdded(timeout)
    local deadline = os.clock() + (timeout or 5)
    local fired = false
    local conn = lp.CharacterAdded:Connect(function() fired = true end)
    while os.clock() < deadline and not fired do
        task.wait(0.05)
    end
    conn:Disconnect()
    return fired
end

local function TeleportBackAfterRespawn()
    if not allowTeleportBack or not originalPos then return end
    local targetPos = originalPos
    local newChar = lp.Character
    local deadline = os.clock() + 3
    while not newChar and os.clock() < deadline do
        task.wait(0.05)
        newChar = lp.Character
    end
    if not newChar then return end
    task.wait(0.15)
    for _ = 1, 4 do
        local hrp = newChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = targetPos
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        task.wait(0.15)
    end
end

local function ExecuteSequence(targetName)
    if isProcessing then return end
    local char = lp.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") then return "NO CHAR" end

    isProcessing = true
    local hrp = char:FindFirstChild("HumanoidRootPart")
    originalPos = hrp and hrp.CFrame or nil
    allowTeleportBack = true

    local status = mainRun(targetName)
    if not status or status == "NO TOOL" then
        isProcessing = false
        originalPos = nil
        allowTeleportBack = false
        return (status == "NO TOOL") and "NO TOOL" or "NOT FOUND"
    end

    for _ = 1, 3 do
        lp.Character = nil
        ForceServerReset()
        if WaitForCharacterAdded(1.2) then break end
    end

    TeleportBackAfterRespawn()

    if switchedToR6 then
        switchedToR6 = false
        ChangeToR15()
    end

    originalPos = nil
    allowTeleportBack = false
    isProcessing = false
    task.wait(0.15)
    return "SUCCESS"
end

local function AddGradient(inst, c1, c2, rot)
    local g = Instance.new("UIGradient", inst)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    g.Rotation = rot or 90
    return g
end

local function HookHover(btn)
    local base = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = base:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = base
        }):Play()
    end)
end

local function BuildGui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ToolVoidByTory"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "ToolVoid"
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundColor3 = Color3.fromRGB(121, 109, 159)
    MainFrame.Size = UDim2.new(0.24862, 0, 0.08609, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = false

    local MainCorner = Instance.new("UICorner", MainFrame)
    MainCorner.CornerRadius = UDim.new(0, 8)

    AddGradient(MainFrame, Color3.fromRGB(138, 125, 178), Color3.fromRGB(100, 90, 140), 90)

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Color3.fromRGB(140, 255, 191)
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.25

    -- Shadow Tipis Frame Utama
    local shadow = Instance.new("ImageLabel", MainFrame)
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 90, 90)
    shadow.ZIndex = 0

    local AspectRatio = Instance.new("UIAspectRatioConstraint", MainFrame)
    AspectRatio.AspectRatio = 6.92308

    local CloseBtn = Instance.new("TextButton", MainFrame)
    CloseBtn.Name = "Close"
    CloseBtn.BorderSizePixel = 0
    CloseBtn.TextSize = 22
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 61, 136)
    CloseBtn.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    CloseBtn.Size = UDim2.new(0.14444, 0, 1, 0)
    CloseBtn.Position = UDim2.new(0.85556, 0, 0, 0)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    AddGradient(CloseBtn, Color3.fromRGB(255, 100, 165), Color3.fromRGB(220, 40, 115), 90)
    HookHover(CloseBtn)

    local MinimizeBtn = Instance.new("TextButton", MainFrame)
    MinimizeBtn.Name = "Minimize"
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.TextSize = 22
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(219, 255, 191)
    MinimizeBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinimizeBtn.Size = UDim2.new(0.14444, 0, 1, 0)
    MinimizeBtn.Position = UDim2.new(0.71111, 0, 0, 0)
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Color3.fromRGB(50, 80, 40)
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)
    AddGradient(MinimizeBtn, Color3.fromRGB(230, 255, 205), Color3.fromRGB(180, 235, 155), 90)
    HookHover(MinimizeBtn)

    local ToolToggleBtn = Instance.new("TextButton", MainFrame)
    ToolToggleBtn.Name = "ToolToggle"
    ToolToggleBtn.BorderSizePixel = 0
    ToolToggleBtn.TextSize = 22
    ToolToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 252, 255)
    ToolToggleBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ToolToggleBtn.Size = UDim2.new(0.14444, 0, 1, 0)
    ToolToggleBtn.Position = UDim2.new(0.56667, 0, 0, 0)
    ToolToggleBtn.Text = "+"
    ToolToggleBtn.TextColor3 = Color3.fromRGB(40, 80, 80)
    Instance.new("UICorner", ToolToggleBtn).CornerRadius = UDim.new(0, 6)
    AddGradient(ToolToggleBtn, Color3.fromRGB(150, 255, 255), Color3.fromRGB(85, 225, 235), 90)
    HookHover(ToolToggleBtn)

    local TitleLabel = Instance.new("TextLabel", MainFrame)
    TitleLabel.Name = "title"
    TitleLabel.TextWrapped = true
    TitleLabel.BorderSizePixel = 0
    TitleLabel.TextSize = 13
    TitleLabel.BackgroundColor3 = Color3.fromRGB(121, 109, 159)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0.05, 0, 0, 0)
    TitleLabel.Text = "By Tory"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    AddGradient(TitleLabel, Color3.fromRGB(255, 200, 255), Color3.fromRGB(140, 255, 191), 45)

    local MainGui = Instance.new("Frame", MainFrame)
    MainGui.Name = "MainGui"
    MainGui.BorderSizePixel = 0
    MainGui.BackgroundColor3 = Color3.fromRGB(168, 151, 221)
    MainGui.Size = UDim2.new(0.98889, 0, 5.69231, 0)
    MainGui.Position = UDim2.new(0.00344, 0, 1.07539, 0)
    MainGui.BackgroundTransparency = 0.15
    MainGui.ClipsDescendants = true
    Instance.new("UICorner", MainGui).CornerRadius = UDim.new(0, 8)
    AddGradient(MainGui, Color3.fromRGB(185, 168, 235), Color3.fromRGB(150, 135, 205), 90)
    local MainGuiStroke = Instance.new("UIStroke", MainGui)
    MainGuiStroke.Color = Color3.fromRGB(200, 185, 245)
    MainGuiStroke.Thickness = 1
    MainGuiStroke.Transparency = 0.4

    local ShowMode = Instance.new("TextLabel", MainGui)
    ShowMode.Name = "ShowMode"
    ShowMode.BorderSizePixel = 0
    ShowMode.TextSize = 15
    ShowMode.BackgroundTransparency = 1
    ShowMode.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
    ShowMode.Size = UDim2.new(0.49438, 0, 0.24324, 0)
    ShowMode.Position = UDim2.new(0.02222, 0, 0.41892, 0)
    ShowMode.Text = "Current Mode:"
    ShowMode.TextColor3 = Color3.fromRGB(245, 240, 255)

    local ModeLabel = Instance.new("TextLabel", ShowMode)
    ModeLabel.Name = "Mode"
    ModeLabel.BorderSizePixel = 0
    ModeLabel.TextSize = 15
    ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
    ModeLabel.BackgroundTransparency = 1
    ModeLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
    ModeLabel.Size = UDim2.new(0.61364, 0, 0.77778, 0)
    ModeLabel.Position = UDim2.new(0.90909, 0, 0.11111, 0)
    ModeLabel.Text = "VOID"
    ModeLabel.TextColor3 = Color3.fromRGB(190, 210, 255)

    local ChoosePlayer = Instance.new("TextBox", MainGui)
    ChoosePlayer.Name = "ChoosePlayer"
    ChoosePlayer.BorderSizePixel = 0
    ChoosePlayer.TextWrapped = true
    ChoosePlayer.TextScaled = true
    ChoosePlayer.BackgroundColor3 = Color3.fromRGB(210, 205, 230)
    ChoosePlayer.Size = UDim2.new(0.89888, 0, 0.24324, 0)
    ChoosePlayer.Position = UDim2.new(0.05556, 0, 0.24324, 0)
    ChoosePlayer.Text = ""
    ChoosePlayer.PlaceholderText = "Type user/display Name"
    ChoosePlayer.PlaceholderColor3 = Color3.fromRGB(120, 115, 150)
    ChoosePlayer.TextColor3 = Color3.fromRGB(40, 35, 60)
    ChoosePlayer.ClearTextOnFocus = false
    Instance.new("UICorner", ChoosePlayer).CornerRadius = UDim.new(0, 6)
    local InputStroke = Instance.new("UIStroke", ChoosePlayer)
    InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InputStroke.Color = Color3.fromRGB(245, 255, 135)
    InputStroke.Thickness = 1.5
    InputStroke.Transparency = 0.2

    ChoosePlayer.Focused:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.15), {Transparency = 0, Thickness = 2}):Play()
    end)
    ChoosePlayer.FocusLost:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.2), {Transparency = 0.2, Thickness = 1.5}):Play()
    end)

    local SwitchBtn = Instance.new("TextButton", MainGui)
    SwitchBtn.BorderSizePixel = 0
    SwitchBtn.BackgroundColor3 = Color3.fromRGB(234, 210, 255)
    SwitchBtn.Size = UDim2.new(0.33708, 0, 0.22973, 0)
    SwitchBtn.Position = UDim2.new(0.07778, 0, 0.62162, 0)
    SwitchBtn.Text = "Switch"
    SwitchBtn.TextColor3 = Color3.fromRGB(60, 40, 90)
    SwitchBtn.TextSize = 15
    SwitchBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(0, 6)
    AddGradient(SwitchBtn, Color3.fromRGB(245, 225, 255), Color3.fromRGB(215, 190, 245), 90)
    local SwitchStroke = Instance.new("UIStroke", SwitchBtn)
    SwitchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    SwitchStroke.Color = Color3.fromRGB(180, 160, 220)
    SwitchStroke.Transparency = 0.4
    HookHover(SwitchBtn)

    local StartBtn = Instance.new("TextButton", MainGui)
    StartBtn.Name = "Start"
    StartBtn.BorderSizePixel = 0
    StartBtn.BackgroundColor3 = Color3.fromRGB(234, 210, 255)
    StartBtn.Size = UDim2.new(0.33708, 0, 0.22973, 0)
    StartBtn.Position = UDim2.new(0.44444, 0, 0.62162, 0)
    StartBtn.Text = "Start"
    StartBtn.TextColor3 = Color3.fromRGB(60, 40, 90)
    StartBtn.TextSize = 15
    StartBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 6)
    AddGradient(StartBtn, Color3.fromRGB(245, 225, 255), Color3.fromRGB(215, 190, 245), 90)
    local StartStroke = Instance.new("UIStroke", StartBtn)
    StartStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    StartStroke.Color = Color3.fromRGB(180, 160, 220)
    StartStroke.Transparency = 0.4
    HookHover(StartBtn)

    -- FIX POSISI PANEL TOOL BIAR DEKETAN
    local ChooseTool = Instance.new("ScrollingFrame", MainFrame)
    ChooseTool.Name = "ChooseTool"
    ChooseTool.BorderSizePixel = 0
    ChooseTool.BackgroundColor3 = Color3.fromRGB(168, 151, 221)
    ChooseTool.Size = UDim2.new(0, 140, 0, 200) 
    ChooseTool.Position = UDim2.new(0, -160, 0, 0) -- Posisi sembunyi (kiri)
    ChooseTool.BackgroundTransparency = 0.1
    ChooseTool.Visible = false
    ChooseTool.ClipsDescendants = true
    ChooseTool.ScrollBarThickness = 2
    ChooseTool.ScrollBarImageColor3 = Color3.fromRGB(200, 185, 245)
    ChooseTool.CanvasSize = UDim2.new(0, 0, 0, 0)
    Instance.new("UICorner", ChooseTool).CornerRadius = UDim.new(0, 8)
    AddGradient(ChooseTool, Color3.fromRGB(185, 168, 235), Color3.fromRGB(150, 135, 205), 90)
    local ToolStroke = Instance.new("UIStroke", ChooseTool)
    ToolStroke.Color = Color3.fromRGB(200, 185, 245)
    ToolStroke.Transparency = 0.35

    local ToolLayout = Instance.new("UIListLayout", ChooseTool)
    ToolLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ToolLayout.Padding = UDim.new(0, 4)

    local ToolPadding = Instance.new("UIPadding", ChooseTool)
    ToolPadding.PaddingTop = UDim.new(0, 6)
    ToolPadding.PaddingBottom = UDim.new(0, 6)
    ToolPadding.PaddingLeft = UDim.new(0, 6)
    ToolPadding.PaddingRight = UDim.new(0, 6)

    ScreenGui.Parent = CoreGui
    return ScreenGui, MainFrame, MainGui, ChooseTool, CloseBtn, MinimizeBtn, ToolToggleBtn, ModeLabel, ChoosePlayer, SwitchBtn, StartBtn
end

local playerGui = lp:WaitForChild("PlayerGui")
for _, name in ipairs({ "ToolVoidByTory", "ToolVoid" }) do
    local a = CoreGui:FindFirstChild(name)
    if a then a:Destroy() end
    local b = playerGui:FindFirstChild(name)
    if b then b:Destroy() end
end

local ScreenGui, MainFrame, MainGui, ChooseTool, CloseBtn, MinimizeBtn, ToolToggleBtn, ModeLabel, ChoosePlayer, SwitchBtn, StartBtn = BuildGui()

local MODE_COLORS = {
    VOID = Color3.fromRGB(190, 210, 255),
    EXTREME = Color3.fromRGB(255, 150, 190),
    BRING = Color3.fromRGB(150, 255, 190),
    GIVE = Color3.fromRGB(255, 210, 130),
}

local function UpdateModeUI()
    ModeLabel.Text = currentMode
    local target = MODE_COLORS[currentMode] or Color3.new(1, 1, 1)
    TweenService:Create(ModeLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextColor3 = target
    }):Play()
end

UpdateModeUI()

local toolListOpen = false

local function RefreshToolList()
    for _, child in ipairs(ChooseTool:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end

    local found = {}
    local function scan(parent)
        if not parent then return end
        for _, obj in ipairs(parent:GetChildren()) do
            if obj:IsA("Tool") and not found[obj.Name] then
                found[obj.Name] = true
            end
        end
    end
    
    scan(lp:FindFirstChild("Backpack"))
    scan(lp.Character)
    scan(lp:FindFirstChild("StarterGear"))

    local count = 0
    for tName, _ in pairs(found) do
        count = count + 1
        local tBtn = Instance.new("TextButton", ChooseTool)
        tBtn.Size = UDim2.new(1, 0, 0, 28)
        tBtn.BorderSizePixel = 0
        tBtn.TextSize = 14
        tBtn.TextScaled = false -- Biar gak gede sendiri kalau cuma 1 tool
        tBtn.Text = tName
        tBtn.TextColor3 = Color3.new(1, 1, 1)
        tBtn.BackgroundColor3 = (selectedToolName == tName) and Color3.fromRGB(84, 168, 120) or Color3.fromRGB(121, 109, 159)
        tBtn.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 4)
        AddGradient(tBtn, tBtn.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.15), tBtn.BackgroundColor3, 90)
        
        tBtn.MouseEnter:Connect(function()
            TweenService:Create(tBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = tBtn.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.2)
            }):Play()
        end)
        tBtn.MouseLeave:Connect(function()
            local base = (selectedToolName == tName) and Color3.fromRGB(84, 168, 120) or Color3.fromRGB(121, 109, 159)
            TweenService:Create(tBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = base
            }):Play()
        end)

        tBtn.MouseButton1Click:Connect(function()
            selectedToolName = (selectedToolName == tName) and nil or tName
            RefreshToolList()
            -- Text "✓" udah gw ilangin, sekarang cuma milih doang tanpa ngubah text tombol +
        end)
    end
    
    if count == 0 then
        local tLabel = Instance.new("TextLabel", ChooseTool)
        tLabel.Size = UDim2.new(1, 0, 0, 28)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = "No tools found"
        tLabel.TextColor3 = Color3.fromRGB(150, 140, 170)
        tLabel.TextSize = 13
        tLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end
end

-- AUTO UPDATE LIST TOOL
lp.ChildAdded:Connect(function(c)
    if c.Name == "Backpack" then
        c.ChildAdded:Connect(function() if toolListOpen then RefreshToolList() end end)
        c.ChildRemoved:Connect(function() if toolListOpen then RefreshToolList() end end)
    end
end)
if lp:FindFirstChild("Backpack") then
    lp.Backpack.ChildAdded:Connect(function() if toolListOpen then RefreshToolList() end end)
    lp.Backpack.ChildRemoved:Connect(function() if toolListOpen then RefreshToolList() end end)
end
lp.CharacterAdded:Connect(function(c)
    c.ChildAdded:Connect(function() if toolListOpen then RefreshToolList() end end)
    c.ChildRemoved:Connect(function() if toolListOpen then RefreshToolList() end end)
end)

ToolToggleBtn.MouseButton1Click:Connect(function()
    toolListOpen = not toolListOpen
    if toolListOpen then
        RefreshToolList()
        ChooseTool.Visible = true
        ChooseTool.Position = UDim2.new(0, -160, 0, 0) 
        -- Animasi geser dikit ke kanan biar deket sama gui utama
        TweenService:Create(ChooseTool, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, -145, 0, 0) 
        }):Play()
    else
        local tw = TweenService:Create(ChooseTool, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -160, 0, 0)
        })
        tw:Play()
        tw.Completed:Connect(function()
            if not toolListOpen then
                ChooseTool.Visible = false
            end
        end)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    local tw = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    tw:Play()
    for _, d in ipairs(MainFrame:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            TweenService:Create(d, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        elseif d:IsA("Frame") or d:IsA("ScrollingFrame") then
            TweenService:Create(d, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        elseif d:IsA("UIStroke") then
            TweenService:Create(d, TweenInfo.new(0.2), {Transparency = 1}):Play()
        elseif d:IsA("ImageLabel") then
            TweenService:Create(d, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
        end
    end
    task.wait(0.2)
    ScreenGui:Destroy()
end)

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        local tw = TweenService:Create(MainGui, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0.98889, 0, 0, 0)
        })
        tw:Play()
        tw.Completed:Connect(function()
            if minimized then
                MainGui.Visible = false
                MainGui.Size = UDim2.new(0.98889, 0, 5.69231, 0)
            end
        end)
        if toolListOpen then
            toolListOpen = false
            ChooseTool.Visible = false
        end
    else
        MainGui.Size = UDim2.new(0.98889, 0, 0, 0)
        MainGui.Visible = true
        TweenService:Create(MainGui, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.98889, 0, 5.69231, 0)
        }):Play()
    end
end)

SwitchBtn.MouseButton1Click:Connect(function()
    if currentMode == "VOID" then currentMode = "EXTREME"
    elseif currentMode == "EXTREME" then currentMode = "BRING"
    elseif currentMode == "BRING" then currentMode = "GIVE"
    else currentMode = "VOID" end
    UpdateModeUI()
    local uiScale = MainGui:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale", MainGui)
    end
    uiScale.Scale = 0.92
    TweenService:Create(uiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = 1
    }):Play()
end)

local function SetStartText(text, hold)
    StartBtn.Text = text
    if hold then
        task.delay(hold, function()
            if StartBtn and StartBtn.Parent then StartBtn.Text = "Start" end
        end)
    end
end

local function Run(targetName)
    if isProcessing then return end
    SetStartText("checking")
    local res = ExecuteSequence(targetName)
    if res == "NOT FOUND" then
        SetStartText("Where?", 1.2)
    elseif res == "NO TOOL" then
        SetStartText("No tool", 1.2)
    elseif res == "NO CHAR" then
        SetStartText("Pls re char", 1.2)
    else
        SetStartText("Done😎", 0.4)
        RefreshToolList()
    end
end

StartBtn.MouseButton1Click:Connect(function()
    if isProcessing then return end
    local name = ChoosePlayer.Text
    if name == "" then
        SetStartText("TYPE NAME!", 1)
        return
    end
    Run(name)
end)

ChoosePlayer.FocusLost:Connect(function(enterPressed)
    if enterPressed and ChoosePlayer.Text ~= "" and not isProcessing then
        Run(ChoosePlayer.Text)
    end
end)
