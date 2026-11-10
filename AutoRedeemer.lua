-- AutoRedeemer.client.lua
-- LocalScript: StarterPlayer > StarterPlayerScripts
-- For your own Roblox experience. Requires the server bridge included in this package.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RiddleToolsRemotes")
local getPending = remotes:WaitForChild("GetPendingCodes")
local redeemCode = remotes:WaitForChild("RedeemCode")

local gui = Instance.new("ScreenGui")
gui.Name = "SaintCodeRedeemer"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Main"
panel.Size = UDim2.fromOffset(310, 390)
panel.Position = UDim2.new(0, 24, 0.5, -195)
panel.BackgroundColor3 = Color3.fromRGB(17, 15, 23)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(104, 83, 48)
stroke.Thickness = 1

local function label(parent, text, size, pos, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.Position = pos
    l.Size = UDim2.new(1, -24, 0, 24)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = color or Color3.fromRGB(230, 222, 205)
    l.Font = font or Enum.Font.Gotham
    l.Parent = parent
    return l
end

label(panel, "Saint Code-Redeemer", 16, UDim2.fromOffset(12, 10), Color3.fromRGB(218, 184, 83), Enum.Font.GothamBold)
label(panel, "redeem codes in your experience", 10, UDim2.fromOffset(12, 34), Color3.fromRGB(145, 137, 126))

local status = label(panel, "● INACTIVE", 11, UDim2.fromOffset(12, 65), Color3.fromRGB(255, 100, 100), Enum.Font.GothamBold)
local logTitle = label(panel, "LOG", 10, UDim2.fromOffset(14, 274), Color3.fromRGB(218, 184, 83), Enum.Font.GothamBold)

local logBox = Instance.new("TextLabel")
logBox.Position = UDim2.fromOffset(14, 298)
logBox.Size = UDim2.new(1, -28, 0, 78)
logBox.BackgroundTransparency = 1
logBox.TextColor3 = Color3.fromRGB(170, 164, 153)
logBox.TextSize = 10
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.Font = Enum.Font.Code
logBox.Text = "Ready."
logBox.Parent = panel

local function addLog(message)
    logBox.Text = (os.date("%H:%M:%S") .. "  " .. message .. "\n" .. logBox.Text):sub(1, 700)
end

local function makeButton(text, y, color)
    local b = Instance.new("TextButton")
    b.Position = UDim2.fromOffset(14, y)
    b.Size = UDim2.new(1, -28, 0, 30)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local autoEnabled = false
local safeMode = true
local interval = 5
local busy = false

local autoButton = makeButton("AUTO REDEEM  :  OFF", 98, Color3.fromRGB(43, 116, 75))
local safeButton = makeButton("SAFE REDEEM  :  ON", 137, Color3.fromRGB(43, 116, 75))
local manualButton = makeButton("CHECK / REDEEM PENDING CODES", 176, Color3.fromRGB(190, 151, 42))
local stopButton = makeButton("STOP", 215, Color3.fromRGB(168, 57, 57))

local intervalLabel = label(panel, "CHECK INTERVAL: 5 SECONDS", 10, UDim2.fromOffset(14, 251), Color3.fromRGB(190, 183, 169))
local fasterButton = Instance.new("TextButton")
fasterButton.Position = UDim2.fromOffset(205, 246)
fasterButton.Size = UDim2.fromOffset(38, 22)
fasterButton.Text = "-"
fasterButton.BackgroundColor3 = Color3.fromRGB(49, 44, 57)
fasterButton.TextColor3 = Color3.new(1,1,1)
fasterButton.Parent = panel
local slowerButton = fasterButton:Clone()
slowerButton.Position = UDim2.fromOffset(250, 246)
slowerButton.Text = "+"
slowerButton.Parent = panel

local function redeemPending()
    if busy then return end
    busy = true
    local ok, codes = pcall(function()
        return getPending:InvokeServer()
    end)
    if not ok or type(codes) ~= "table" then
        addLog("Could not load pending codes.")
        busy = false
        return
    end
    if #codes == 0 then addLog("No pending codes.") end

    for _, code in ipairs(codes) do
        if not autoEnabled and not manualButton:GetAttribute("ManualRun") then break end
        if type(code) == "string" then
            local success, result = pcall(function()
                return redeemCode:InvokeServer(code, safeMode)
            end)
            if success and result == true then
                addLog("Redeemed: " .. code)
            else
                addLog("Skipped/invalid: " .. code)
            end
            task.wait(0.25)
        end
    end
    manualButton:SetAttribute("ManualRun", false)
    busy = false
end

autoButton.MouseButton1Click:Connect(function()
    autoEnabled = not autoEnabled
    autoButton.Text = "AUTO REDEEM  :  " .. (autoEnabled and "ON" or "OFF")
    status.Text = autoEnabled and "● ACTIVE" or "● INACTIVE"
    status.TextColor3 = autoEnabled and Color3.fromRGB(90, 220, 130) or Color3.fromRGB(255, 100, 100)
    autoButton.BackgroundColor3 = autoEnabled and Color3.fromRGB(43, 116, 75) or Color3.fromRGB(68, 62, 72)
    if autoEnabled then
        task.spawn(function()
            while autoEnabled do
                redeemPending()
                task.wait(interval)
            end
        end)
    end
end)

safeButton.MouseButton1Click:Connect(function()
    safeMode = not safeMode
    safeButton.Text = "SAFE REDEEM  :  " .. (safeMode and "ON" or "OFF")
    safeButton.BackgroundColor3 = safeMode and Color3.fromRGB(43, 116, 75) or Color3.fromRGB(68, 62, 72)
end)

manualButton.MouseButton1Click:Connect(function()
    manualButton:SetAttribute("ManualRun", true)
    task.spawn(redeemPending)
end)

stopButton.MouseButton1Click:Connect(function()
    autoEnabled = false
    status.Text = "● INACTIVE"
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    autoButton.Text = "AUTO REDEEM  :  OFF"
    addLog("Stopped.")
end)

fasterButton.MouseButton1Click:Connect(function()
    interval = math.max(2, interval - 1)
    intervalLabel.Text = "CHECK INTERVAL: " .. interval .. " SECONDS"
end)
slowerButton.MouseButton1Click:Connect(function()
    interval = math.min(30, interval + 1)
    intervalLabel.Text = "CHECK INTERVAL: " .. interval .. " SECONDS"
end)

-- Drag panel on desktop/mobile.
local dragging, dragStart, startPos
panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
