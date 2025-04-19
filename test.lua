-- Universal Silent Aim for Roblox

-- Settings (configurable via getgenv())
getgenv().FOV = getgenv().FOV or true -- Whether to show the FOV circle
getgenv().fov = getgenv().fov or 180 -- FOV size in pixels (radius)
getgenv().VisibleCheck = getgenv().VisibleCheck or false -- Whether to perform visibility check
getgenv().TargetHitbox = getgenv().TargetHitbox or "Head" -- "Head" or "Torso"

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local variables
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local Silent_Aim_Target = nil

-- FOV circle setup
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Radius = getgenv().fov
fovCircle.Filled = false
fovCircle.Transparency = 0.6
fovCircle.Visible = getgenv().FOV
fovCircle.Color = Color3.fromRGB(255, 255, 255)

-- Utility functions
local function getCharacter(player)
    return player.Character
end

local function getHitbox(character)
    if character then
        local hitboxName = getgenv().TargetHitbox == "Torso" and "HumanoidRootPart" or "Head"
        return character:FindFirstChild(hitboxName) or character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function isAlive(character)
    local humanoid = character and character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isEnemy(player)
    if player == localPlayer then return false end
    if player.Team == localPlayer.Team and localPlayer.Team ~= nil then
        return false
    else
        return true
    end
end

-- Hook Raycast
local oldRaycast
oldRaycast = hookfunction(Workspace.Raycast, function(self, origin, direction, raycastParams)
    if Silent_Aim_Target then
        local character = getCharacter(Silent_Aim_Target)
        local hitbox = getHitbox(character)
        if hitbox then
            local cameraDirection = camera.CFrame.LookVector
            local rayDirection = direction.Unit
            if (cameraDirection - rayDirection).Magnitude < 0.1 then
                local hitPosition = hitbox.Position
                local distance = (hitPosition - origin).Magnitude
                return {
                    Position = hitPosition,
                    Normal = (hitPosition - origin).Unit,
                    Distance = distance,
                    Material = Enum.Material.Plastic,
                    Instance = hitbox
                }
            end
        end
    end
    return oldRaycast(self, origin, direction, raycastParams)
end)

-- Visibility check using original Raycast
local function isVisible(targetCharacter, position)
    if not getgenv().VisibleCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character or {}}
    local origin = camera.CFrame.Position
    local direction = (position - origin).Unit * 1000
    local result = oldRaycast(Workspace, origin, direction, raycastParams)
    if result and result.Instance then
        local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
        if hitCharacter and hitCharacter == targetCharacter then
            return true
        end
    end
    return false
end

-- Target selection
RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = getgenv().fov

    local choices = {}
    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = getCharacter(player)
            if character and isAlive(character) then
                local hitbox = getHitbox(character)
                if hitbox then
                    local screenPos, onScreen = camera:WorldToViewportPoint(hitbox.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                        if distance < getgenv().fov and (not getgenv().VisibleCheck or isVisible(character, hitbox.Position)) then
                            table.insert(choices, {player = player, distance = distance})
                        end
                    end
                end
            end
        end
    end

    table.sort(choices, function(a, b) return a.distance < b.distance end)
    Silent_Aim_Target = choices[1] and choices[1].player or nil
end)
