-- ZyroHub • Swing For An Egg v1.3 • TP BURST
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local UI = getgenv().ZyroUI
assert(UI, "[ZYRO HUB] ZyroUI não encontrada")

UI:SetGame("Swing For An Egg", "Teleports, detecção e Auto Steal")
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

-- Reforço de TP para conexões com atraso:
-- reaplica o MESMO destino algumas vezes e depois para.
local function tpBurst(cf, repeats, interval)
    repeats = repeats or 3
    interval = interval or 0.12

    if not cf then return false end

    local ok = false
    for i = 1, repeats do
        if tpCF(cf) then
            ok = true
        end
        if i < repeats then
            task.wait(interval)
        end
    end

    return ok
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


-- ============================================================
-- AUTO STEAL BEST EGG
-- Detecta especiais pelo Outline criado dentro do SpawnedEgg.
-- Colossal e Secret = alvo.
-- Legendary = ignorado de propósito.
-- ============================================================

local autoStealBestEgg = false
local lastTarget = nil
local lastTeleportAt = 0
local SPECIAL_COOLDOWN = 2.0

local function spawnedEggCF(egg)
    if not egg or not egg.Parent then return nil end

    -- O PromptAnchor fica no próprio SpawnedEgg e é o melhor ponto
    -- para chegar perto do prompt "Collect Egg".
    local anchor = egg:FindFirstChild("PromptAnchor", true)
    if anchor and anchor:IsA("BasePart") then
        return anchor.CFrame * CFrame.new(0, 3, 2)
    end

    if egg:IsA("Model") then
        return egg:GetPivot() * CFrame.new(0, 3, 2)
    elseif egg:IsA("BasePart") then
        return egg.CFrame * CFrame.new(0, 3, 2)
    end
end

local function specialType(egg)
    if not egg or egg.Name ~= "SpawnedEgg" then return nil end

    -- Confirmado no Colossal pelo Dex:
    -- SpawnedEgg > ColossalOutline
    if egg:FindFirstChild("ColossalOutline", true) then
        return "Colossal", 3
    end

    -- Preparado para a estrutura equivalente do Secret.
    if egg:FindFirstChild("SecretOutline", true) then
        return "Secret", 2
    end

    -- Legendary NÃO é roubado.
    if egg:FindFirstChild("LegendaryOutline", true) then
        return "Legendary", 1
    end

    -- Fallback por nome de descendants caso o jogo use outro sufixo.
    for _,d in ipairs(egg:GetDescendants()) do
        local n = d.Name:lower()
        if n:find("colossal", 1, true) then
            return "Colossal", 3
        elseif n:find("secret", 1, true) then
            return "Secret", 2
        elseif n:find("legendary", 1, true) then
            return "Legendary", 1
        end
    end

    return nil
end

local function findBestSpecialEgg()
    local eggsFolder = Workspace:FindFirstChild("Eggs")
    if not eggsFolder then return nil end

    local bestEgg, bestType, bestPriority

    for _,obj in ipairs(eggsFolder:GetDescendants()) do
        if obj.Name == "SpawnedEgg" then
            local kind, priority = specialType(obj)

            -- Legendary é detectável, mas fica fora do Auto Steal.
            if kind and kind ~= "Legendary" then
                if not bestPriority or priority > bestPriority then
                    bestEgg = obj
                    bestType = kind
                    bestPriority = priority
                end
            end
        end
    end

    return bestEgg, bestType
end

local function stealBestEggOnce()
    if not autoStealBestEgg then return false end

    local egg, kind = findBestSpecialEgg()
    if not egg then return false end

    local now = os.clock()

    -- Evita ficar teleportando sem parar para o mesmo egg.
    if egg == lastTarget and (now - lastTeleportAt) < SPECIAL_COOLDOWN then
        return false
    end

    local cf = spawnedEggCF(egg)
    if not cf then return false end

    if tpBurst(cf, 3, 0.12) then
        lastTarget = egg
        lastTeleportAt = now

        local eggName = egg:GetAttribute("EggName")
        local zone = egg.Parent and egg.Parent.Parent
        local zoneName = zone and zone.Name or "?"

        UI:Notify(
            "Auto Steal Best Egg",
            tostring(kind).." detectado • "..tostring(eggName or "Egg").." • "..zoneName,
            "success"
        )

        print(
            "[ZYRO HUB] AUTO STEAL:",
            kind,
            "|",
            tostring(eggName),
            "|",
            egg:GetFullName()
        )

        return true
    end

    return false
end

-- Scanner contínuo. Também cobre eggs que já estavam spawnados
-- antes do toggle ser ligado.
task.spawn(function()
    while task.wait(0.20) do
        if autoStealBestEgg then
            pcall(stealBestEggOnce)
        end
    end
end)


UI:Section("Teleports")

UI:Button("TP ÚLTIMA ZONA", "Detecta automaticamente a maior ZoneN e vai até um EggNest.", function()
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

    if tpBurst(cf, 3, 0.12) then
        UI:Notify("Swing For An Egg", "Teleportado x3 para Zone"..tostring(number)..".")
    end
end)

UI:Button("TP MINHA BASE", "Volta para o Spawn da sua Plot automaticamente.", function()
    local cf, plot = homeDestination()
    if not cf then
        UI:Notify("Swing For An Egg", "Não encontrei Plot_"..LP.Name..".")
        return
    end

    if tpBurst(cf, 3, 0.12) then
        UI:Notify("Swing For An Egg", "Teleportado x3 para "..plot.Name..".")
    end
end)

UI:Section("Detecção")

UI:Button("VERIFICAR ÚLTIMA ZONA", "Mostra qual é a maior zona disponível no momento.", function()
    local zone, number = latestZone()
    if zone then
        UI:Notify("Swing For An Egg", "Última zona detectada: Zone"..tostring(number))
    else
        UI:Notify("Swing For An Egg", "Nenhuma ZoneN encontrada.")
    end
end)


-- Aba separada para automações deste jogo.
UI:Tab("Auto Steal")
UI:UseTab("Auto Steal")

UI:Section("Best Egg")

UI:Toggle(
    "AUTO STEAL BEST EGG",
    "TP automático em Colossal e Secret. Legendary é ignorado.",
    false,
    function(state)
        autoStealBestEgg = state

        if state then
            lastTarget = nil
            lastTeleportAt = 0
            UI:Notify("Auto Steal Best Egg", "Ativado • procurando Colossal/Secret.", "success")
            task.spawn(stealBestEggOnce)
        else
            UI:Notify("Auto Steal Best Egg", "Desativado.", "warn")
        end
    end
)

UI:Button(
    "PROCURAR ESPECIAL AGORA",
    "Procura Colossal/Secret já spawnado e teleporta se encontrar.",
    function()
        local old = autoStealBestEgg
        autoStealBestEgg = true
        local found = stealBestEggOnce()
        autoStealBestEgg = old

        if not found then
            UI:Notify("Auto Steal Best Egg", "Nenhum Colossal/Secret detectado agora.", "warn")
        end
    end
)

UI:Section("Prioridade")
UI:Button(
    "COLOSSAL > SECRET",
    "Legendary não entra no Auto Steal.",
    function()
        UI:Notify("Auto Steal Best Egg", "Prioridade atual: Colossal > Secret • Legendary ignorado.")
    end
)


UI:SelectTab("Teleports")

print("[ZYRO HUB] Swing For An Egg v1.3 TP BURST + AUTO STEAL carregado")
