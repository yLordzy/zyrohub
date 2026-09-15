-- ZyroHub • Swing For An Egg v1.0
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local UI = getgenv().ZyroUI
assert(UI, "[ZYRO HUB] ZyroUI não encontrada")

UI:SetGame("Swing For An Egg", "Teleports e utilidades")
UI:Tab("Teleports")
UI:UseTab("Teleports")

local function root()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c:FindFirstChild("HumanoidRootPart")
end

local function cfOf(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        return obj:GetPivot()
    end
end

local function tpCF(cf)
    local r = root()
    if not r or not cf then return false end
    r.CFrame = cf
    return true
end

local function latestZone()
    local eggs = Workspace:FindFirstChild("Eggs")
    if not eggs then return nil end

    local best, bestN
    for _,z in ipairs(eggs:GetChildren()) do
        local n = tonumber(z.Name:match("^Zone(%d+)$"))
        if n and (not bestN or n > bestN) then
            bestN = n
            best = z
        end
    end
    return best, bestN
end

local function zoneDestination(zone)
    if not zone then return nil end

    -- Preferimos EggNest porque é onde o prompt/egg aparece.
    for _,obj in ipairs(zone:GetChildren()) do
        if obj.Name == "EggNest" then
            local cf = cfOf(obj)
            if cf then return cf * CFrame.new(0,4,5), obj end
        end
    end

    -- Fallback: EggSpawn.
    for _,obj in ipairs(zone:GetChildren()) do
        if obj.Name == "EggSpawn" then
            local cf = cfOf(obj)
            if cf then return cf * CFrame.new(0,4,0), obj end
        end
    end

    -- Último fallback: qualquer Model/BasePart utilizável.
    for _,obj in ipairs(zone:GetChildren()) do
        local cf = cfOf(obj)
        if cf then return cf * CFrame.new(0,4,0), obj end
    end
end

local function homeDestination()
    local plot = Workspace:FindFirstChild("Plot_" .. LP.Name)
    if not plot then return nil, nil end

    local spawn = plot:FindFirstChild("Spawn", true)
    if spawn and spawn:IsA("BasePart") then
        return spawn.CFrame * CFrame.new(0,4,0), plot
    end

    if plot:IsA("Model") then
        if plot.PrimaryPart then
            return plot.PrimaryPart.CFrame * CFrame.new(0,4,0), plot
        end
        return plot:GetPivot() * CFrame.new(0,4,0), plot
    end

    return cfOf(plot), plot
end

UI:Section("Teleports")

UI:Button("TP ÚLTIMA ZONA", function()
    local zone, number = latestZone()
    if not zone then
        UI:Notify("Swing For An Egg", "Não encontrei workspace.Eggs.ZoneN.")
        return
    end

    local cf = zoneDestination(zone)
    if not cf then
        UI:Notify("Swing For An Egg", "Não achei EggNest/EggSpawn em "..zone.Name..".")
        return
    end

    if tpCF(cf) then
        UI:Notify("Swing For An Egg", "Teleportado para Zone"..tostring(number)..".")
    end
end)

UI:Button("TP MINHA BASE", function()
    local cf, plot = homeDestination()
    if not cf then
        UI:Notify("Swing For An Egg", "Não encontrei Plot_"..LP.Name..".")
        return
    end

    if tpCF(cf) then
        UI:Notify("Swing For An Egg", "Teleportado para "..plot.Name..".")
    end
end)

UI:Section("Detecção")

UI:Button("VERIFICAR ÚLTIMA ZONA", function()
    local zone, number = latestZone()
    if zone then
        UI:Notify("Swing For An Egg", "Última zona detectada: Zone"..tostring(number))
    else
        UI:Notify("Swing For An Egg", "Nenhuma ZoneN encontrada.")
    end
end)

UI:SelectTab("Teleports")

print("[ZYRO HUB] Swing For An Egg v1.0 carregado")
