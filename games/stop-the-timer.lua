-- ZYRO HUB • STOP THE TIMER
-- Módulo separado para ser carregado pelo loader.lua.
-- Sem a antiga StopTimerHelper GUI: usa a UI do ZyroHub.

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Normal = Workspace:WaitForChild("GameStations"):WaitForChild("Normal")
local UI = getgenv().ZyroUI

if not UI then
    error("[ZyroHub StopTimer] core/ui.lua não foi carregado.")
end

UI:SetGame("Stop The Timer", "Auto Press")

local station = nil
local button = nil
local activeTimer = nil
local target = nil

local autoPress = false
local pressedThisRound = false

-- Pequena antecipação para compensar atraso entre leitura -> input.
-- Ajuste depois se o executor/latência estiver apertando tarde ou cedo.
local PRESS_OFFSET = 0.02

local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        return obj:GetPivot().Position
    end
end

local function parseTime(text)
    if not text then return nil end
    local n = tostring(text):match("(%d+%.%d+)")
        or tostring(text):match("(%d+,%d+)")
        or tostring(text):match("(%d+)")
    if not n then return nil end
    return tonumber((n:gsub(",", ".")))
end

-- =========================================================
-- ALVO RANDOMIZADO
-- =========================================================

local targetLabel = PlayerGui
    :WaitForChild("GameUI")
    :WaitForChild("SecondsToSet")

local function readTarget()
    local newTarget = parseTime(targetLabel.Text)
    if newTarget then
        if target ~= newTarget then
            target = newTarget
            pressedThisRound = false
            activeTimer = nil
            button = nil

            print(
                "[ZyroHub StopTimer] Novo alvo:",
                string.format("%.2f", target)
            )
        end
    end
end

readTarget()
targetLabel:GetPropertyChangedSignal("Text"):Connect(readTarget)

-- =========================================================
-- MESA MAIS PRÓXIMA
-- =========================================================

local function findStation()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local bestStation
    local bestDistance = math.huge

    for _, s in ipairs(Normal:GetChildren()) do
        local timer = s:FindFirstChild("Timer")
        if timer then
            local pos = getPos(timer)
            if pos then
                local distance = (root.Position - pos).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    bestStation = s
                end
            end
        end
    end

    return bestStation
end

local function getTimers(s)
    local result = {}
    if not s then return result end

    local timerFolder = s:FindFirstChild("Timer")
    if not timerFolder then return result end

    for _, sideName in ipairs({"Player1", "Player2"}) do
        local side = timerFolder:FindFirstChild(sideName)
        local surface = side and side:FindFirstChild("SurfaceGui")
        local timerText = surface and surface:FindFirstChild("TimerText")

        if timerText then
            result[sideName] = timerText
        end
    end

    return result
end

local lastValues = {
    Player1 = nil,
    Player2 = nil
}

local activeSide = nil

local function detectActiveTimer()
    if not station then return end

    local timers = getTimers(station)

    for sideName, timerText in pairs(timers) do
        local value = parseTime(timerText.Text)

        if value then
            local previous = lastValues[sideName]

            -- Se voltou para zero, começou uma nova tentativa.
            if previous and value < previous and value <= 0.05 then
                pressedThisRound = false
            end

            -- O lado cujo contador está subindo é o lado ativo.
            if previous and value > previous then
                activeTimer = timerText
                activeSide = sideName

                local buttons = station:FindFirstChild("Buttons")
                local side = buttons and buttons:FindFirstChild(sideName)
                button = side and side:FindFirstChild("Button")
            end

            lastValues[sideName] = value
        end
    end
end

-- =========================================================
-- CLIQUE NO BOTÃO 3D
-- =========================================================

local function clickButton()
    if not button then
        warn("[ZyroHub StopTimer] Botão ainda não identificado.")
        return false
    end

    local camera = Workspace.CurrentCamera
    local pos = getPos(button)
    if not camera or not pos then return false end

    local screenPos, visible = camera:WorldToViewportPoint(pos)
    if not visible then
        warn("[ZyroHub StopTimer] Botão está fora da tela.")
        return false
    end

    VIM:SendMouseButtonEvent(
        screenPos.X,
        screenPos.Y,
        0,
        true,
        game,
        0
    )

    task.wait(0.008)

    VIM:SendMouseButtonEvent(
        screenPos.X,
        screenPos.Y,
        0,
        false,
        game,
        0
    )

    return true
end

-- =========================================================
-- UI DO ZYROHUB
-- =========================================================

UI:Toggle(
    "Auto Press",
    "Lê o alvo randomizado e aperta automaticamente quando o timer chegar nele.",
    false,
    function(on)
        autoPress = on

        if on then
            pressedThisRound = false
            readTarget()
            print("[ZyroHub StopTimer] Auto Press: ON")
        else
            print("[ZyroHub StopTimer] Auto Press: OFF")
        end
    end
)

UI:Button(
    "Testar botão",
    "Aperta uma vez o botão 3D detectado da sua mesa.",
    function()
        station = findStation()
        detectActiveTimer()
        clickButton()
    end
)

-- =========================================================
-- LOOP
-- =========================================================

task.spawn(function()
    local lastStationCheck = 0

    while task.wait(0.005) do
        if os.clock() - lastStationCheck > 0.5 then
            local newStation = findStation()

            if newStation ~= station then
                station = newStation
                activeTimer = nil
                activeSide = nil
                button = nil
                lastValues.Player1 = nil
                lastValues.Player2 = nil
                pressedThisRound = false

                if station then
                    print("[ZyroHub StopTimer] Mesa:", station.Name)
                end
            end

            lastStationCheck = os.clock()
        end

        detectActiveTimer()

        if autoPress and target and activeTimer and not pressedThisRound then
            local current = parseTime(activeTimer.Text)

            if current then
                local triggerAt = math.max(0, target - PRESS_OFFSET)

                if current > 0 and current >= triggerAt then
                    -- Marca antes para impedir dois cliques no mesmo frame/rodada.
                    pressedThisRound = true

                    print(
                        "[ZyroHub StopTimer] AUTO PRESS",
                        "alvo=" .. string.format("%.2f", target),
                        "timer=" .. string.format("%.2f", current),
                        "lado=" .. tostring(activeSide)
                    )

                    if not clickButton() then
                        -- Se o botão ainda não estava disponível, permite nova tentativa.
                        pressedThisRound = false
                    end
                end
            end
        end
    end
end)

print("========================================")
print("ZYRO HUB • STOP THE TIMER")
print("Alvo randomizado: automático")
print("Mesa: automática")
print("Timer ativo: automático")
print("Auto Press: disponível no ZyroHub")
print("Press offset:", PRESS_OFFSET)
print("========================================")
