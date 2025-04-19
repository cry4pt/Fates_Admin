if getgenv().con then getgenv().con:Disconnect() end
if getgenv().fovCircle then getgenv().fovCircle:Remove() end

local globals = getrenv()._G.globals
local enums = getrenv()._G.enums
local utils = getrenv()._G.utils
local fpv_sol_instances = globals.fpv_sol_instances
local exe_set = getrenv()._G.exe_set
local exe_set_t = getrenv()._G.exe_set_t

local Hitbox_Parts = {
    ["Head"] = "TPVBodyVanillaHead",
    ["Torso"] = "HumanoidRootPart",
}

local Target_Hitbox = getgenv().TargetHitbox or "Head"
local VisibleCheck = getgenv().VisibleCheck or false
local fov = getgenv().fov or 180

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

local createFOVCircle = function() local circle = Drawing.new("Circle"); circle.Thickness = 2; circle.NumSides = 999; circle.Filled = false; circle.Transparency = 0.6; circle.Radius = fov; return circle end
local getSolidierId = function(_Player) for i, v in pairs(globals.cli_names) do if _Player and _Player.Name == v then return i end end end
local getHealth = function(_Player) local id = getSolidierId(_Player) if not id then return 0 end local health = globals.gbl_sol_healths[id] if not health then return 0 end return health end
local getTeam = function(_Player) local id = getSolidierId(_Player) if not id then return end return globals.cli_teams[id] end
local isAlive = function(_Player) local id = getSolidierId(_Player) if not id then return false end if globals.soldiers_alive[id] == true and getHealth(_Player) ~= 0 then return true end return false end
local getPlayerFromCharacter = function(_Character) for id, model in pairs(globals.soldier_models) do if model == _Character then local name = globals.cli_names[id] if name then return Players:FindFirstChild(name) end end end end
local getCharacter = function(_Player) local id = getSolidierId(_Player) if not id then return end return globals.soldier_models[id] end
local getHumanoid = function() return fpv_sol_instances.humanoid end
local getRootPart = function() return fpv_sol_instances.root end
local isVisible = function(Position, Ignore) local soldiers = {} for i,v in pairs(workspace:GetChildren()) do if v.Name == "soldier_model" then table.insert(soldiers, v) end end Ignore = Ignore or { Camera, workspace.Terrain, getCharacter(Player), workspace:FindFirstChild("workspace") and workspace.workspace:FindFirstChild("glass"), workspace.workspace:FindFirstChild("boundary"), unpack(soldiers) } return #Camera:GetPartsObscuringTarget({ Position }, Ignore) == 0 end
local getHitboxes = function() local hitboxes = {} for _,v in pairs(workspace:GetChildren()) do if v:IsA("BasePart") and v.Color == Color3.new(1,0,0) then table.insert(hitboxes, v) end end return hitboxes end

local old_exe_set = nil
local Silent_Aim_Target = nil

getgenv().fovCircle = createFOVCircle()
getgenv().fovCircle.Visible = getgenv().FOV or true
getgenv().fovCircle.Color = Color3.fromRGB(255,255,255)
getgenv().con = game:GetService("RunService").RenderStepped:Connect(function()
    getgenv().fovCircle.Position = UserInputService:GetMouseLocation()

    local center = workspace.CurrentCamera.ViewportSize / 2

    local clientCharacter = getCharacter(Player)
    local clientHealth = getHealth(Player)
    local clientTeam = getTeam(Player)

    if not clientCharacter then return end
    if clientHealth <= 0 then return end
    local Choices = {}
    for _, plr in next, Players:GetPlayers() do
        if plr ~= Player then
            local character = getCharacter(plr)
            local health = getHealth(plr)
            local team = getTeam(plr)
            local bone = character and character:FindFirstChild(Hitbox_Parts[Target_Hitbox])
            if health > 0 and character and team ~= clientTeam and bone then
                local pos, vis = workspace.CurrentCamera:WorldToViewportPoint(bone.Position)
                local p1, p2 = Vector2.new(Mouse.X, Mouse.Y), Vector2.new(pos.X, pos.Y)
                local screenPos = Vector2.new(pos.X, pos.Y)

                local magnitude = (p2 - p1).Magnitude
                if (magnitude < fov) and not (VisibleCheck and not isVisible(bone.Position) and not vis) then
                    local distance = math.floor((screenPos - center).Magnitude)
                    table.insert(Choices, {
                        Player = plr,
                        Distance = distance,
                        Character = character,
                    })
                end
            end
        end
    end

    table.sort(Choices, function(a, b)
        return a.Distance < b.Distance
    end)

    local choice = Choices[1]
    if choice then
        local plr = choice.Player;
        Silent_Aim_Target = plr
    else
        Silent_Aim_Target = nil
    end
end)

local exe_set_proxy = function(event, ...)
    local args = { ... }

    if event == exe_set_t.FPV_SOL_BULLET_SPAWN then
        local stack = debug.getstack(3)
        local discharge_params = nil
        for idx, obj in next, stack do
            if type(obj) == 'table' and type(rawget(obj, 'fire_params')) == 'table' then
                discharge_params = obj
                break
            end
        end

        if Silent_Aim_Target and discharge_params then
            local character = getCharacter(Silent_Aim_Target)
            local bone = character and character:FindFirstChild(Hitbox_Parts[Target_Hitbox])

            if bone then
                local fire_params = discharge_params.fire_params
                local fire_multipliers = discharge_params.fire_multipliers

                args[4] = CFrame.lookAt(args[3], bone.CFrame.p).LookVector * (fire_params.muzzle_velocity * 1000)
            end
        end
    end

    return old_exe_set(event, table.unpack(args))
end
