local userInputService = game:GetService("UserInputService")

local invisible = false
local seat = nil
local weld = nil
local originalTransparency = {}
local oldPos = nil

local function makeInvisible()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character

    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalTransparency[part] = part.Transparency
            part.Transparency = 0.4
        end
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local oldPos = root.CFrame

    seat = Instance.new("Seat")
    weld = Instance.new("Weld")

    root.CFrame = CFrame.new(9e9, 9e9, 9e9)
    wait(0.1)
    root.Anchored = true

    seat.Parent = workspace
    seat.CFrame = root.CFrame
    seat.Anchored = false
    seat.Size = Vector3.new(2, 1, 0)
    seat.Transparency = 1

    
    weld.Parent = seat
    weld.Part0 = seat
    weld.Part1 = root
    weld.Part1.Transparency = 1

    root.Anchored = false
    seat.CFrame = oldPos

    invisible = true
    root.CFrame = oldPos -- Teleport back to the original position
end

local function makeVisible()
    if not invisible then
        return
    end

    local player = game:GetService("Players").LocalPlayer
    local character = player.Character

    if character then
        for part, transparency in pairs(originalTransparency) do
            part.Transparency = transparency
        end
    end

    if seat and weld then
        weld.Part0 = nil
        weld.Part1 = nil
        seat:Destroy()
        weld:Destroy()
        seat = nil
        weld = nil

        invisible = false
    end
end

local function toggleInvisibility()
    if invisible then
        makeVisible()
        wait(0.1)
    else
        makeInvisible()
        wait(0.1)
    end
end

local function onKeyPress(input)
    if input.KeyCode == Enum.KeyCode.F then
        local textBoxFocused = userInputService:GetFocusedTextBox()
        if not textBoxFocused then
            toggleInvisibility()
            wait(0.2)
        end
    end
end

userInputService.InputBegan:Connect(onKeyPress)
