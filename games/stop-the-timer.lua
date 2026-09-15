-- ZYRO HUB • STOP THE TIMER v2
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Normal = Workspace:WaitForChild("GameStations"):WaitForChild("Normal")
local UI = getgenv().ZyroUI
if not UI then error("[ZyroHub StopTimer] UI não carregada") end

UI:SetGame("Stop The Timer", "Auto Press")

local autoPress = false
local station, activeTimer, activeSide, button
local target
local pressedThisRound = false
local PRESS_OFFSET = 0.000
-- Ajuste configurável:
-- positivo = aperta ANTES do alvo (ex.: 0.01 => alvo 7.00, dispara em 6.99)
-- zero     = dispara no alvo
-- negativo = aperta DEPOIS (ex.: -0.01 => alvo 7.00, dispara em 7.01)
local lastValues = {Player1=nil, Player2=nil}

local function parseTime(text)
    local s = tostring(text or ""):gsub(",", ".")
    local n = s:match("(%d+%.%d+)") or s:match("(%d+)")
    return n and tonumber(n) or nil
end

local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then return obj:GetPivot().Position end
end

local targetLabel = PlayerGui:WaitForChild("GameUI"):WaitForChild("SecondsToSet")

local function readTarget()
    local n = parseTime(targetLabel.Text)
    if n and n ~= target then
        target = n
        pressedThisRound = false
        print(("[STOP TIMER] NOVO ALVO: %.2f"):format(target))
    end
end
readTarget()
targetLabel:GetPropertyChangedSignal("Text"):Connect(readTarget)

local function findStation()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local best, dist = nil, math.huge
    for _,s in ipairs(Normal:GetChildren()) do
        local t = s:FindFirstChild("Timer")
        local pos = getPos(t)
        if pos then
            local d = (root.Position-pos).Magnitude
            if d < dist then best,dist=s,d end
        end
    end
    return best
end

local function getTimer(s, sideName)
    local timerFolder=s and s:FindFirstChild("Timer")
    local side=timerFolder and timerFolder:FindFirstChild(sideName)
    local surface=side and side:FindFirstChild("SurfaceGui")
    return surface and surface:FindFirstChild("TimerText")
end

local function bindButton(sideName)
    local buttons=station and station:FindFirstChild("Buttons")
    local side=buttons and buttons:FindFirstChild(sideName)
    button=side and side:FindFirstChild("Button")
end

local function getLocalSide()
    if not station then return nil end

    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local buttons = station:FindFirstChild("Buttons")
    if not root or not buttons then return nil end

    local bestSide, bestDistance = nil, math.huge

    for _, sideName in ipairs({"Player1","Player2"}) do
        local side = buttons:FindFirstChild(sideName)
        local btn = side and side:FindFirstChild("Button")
        local pos = getPos(btn)

        if pos then
            local distance = (root.Position - pos).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                bestSide = sideName
            end
        end
    end

    return bestSide
end

local function detectActiveTimer()
    if not station then return end

    -- Não assume mais Player1. Descobre de qual lado o jogador local está
    -- pela posição física do botão da mesa.
    local localSide = getLocalSide()

    if localSide then
        local txt = getTimer(station, localSide)
        local value = txt and parseTime(txt.Text)

        if value then
            local prev = lastValues[localSide]

            if prev and value < prev and value <= 0.05 then
                pressedThisRound = false
            end

            activeTimer = txt
            activeSide = localSide
            bindButton(localSide)
            lastValues[localSide] = value
            return
        end
    end

    -- Fallback: se a posição ainda não estiver disponível, usa o contador
    -- que realmente estiver aumentando.
    for _, sideName in ipairs({"Player1","Player2"}) do
        local txt = getTimer(station, sideName)
        local value = txt and parseTime(txt.Text)

        if value then
            local prev = lastValues[sideName]

            if prev and value < prev and value <= 0.05 then
                pressedThisRound = false
            end

            if prev and value > prev then
                activeTimer = txt
                activeSide = sideName
                bindButton(sideName)
            end

            lastValues[sideName] = value
        end
    end
end

local function pressButton()
    if not button then
        warn("[STOP TIMER] Sem botão detectado")
        return false
    end

    -- Melhor opção: aciona diretamente o ClickDetector, sem a GUI bloquear o clique.
    local cd = button:FindFirstChildWhichIsA("ClickDetector", true)
    if cd and fireclickdetector then
        local ok,err=pcall(function() fireclickdetector(cd) end)
        if ok then
            print("[STOP TIMER] PRESS via ClickDetector")
            return true
        end
        warn("[STOP TIMER] ClickDetector falhou:",err)
    end

    -- Fallback para o mesmo clique de mouse do helper original.
    local camera=Workspace.CurrentCamera
    local pos=getPos(button)
    if not camera or not pos then return false end
    local sp,visible=camera:WorldToViewportPoint(pos)
    if not visible then
        warn("[STOP TIMER] Botão fora da tela")
        return false
    end

    VIM:SendMouseButtonEvent(sp.X,sp.Y,0,true,game,0)
    task.wait(0.008)
    VIM:SendMouseButtonEvent(sp.X,sp.Y,0,false,game,0)
    print("[STOP TIMER] PRESS via mouse")
    return true
end

-- =========================================================
-- SPACE PARA JOGAR MANUALMENTE
-- =========================================================
-- Mantém o comportamento do helper original: SPACE aperta o
-- botão 3D detectado, sem precisar clicar com o mouse.
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        station = findStation()
        detectActiveTimer()

        -- Se a rodada ainda não revelou o lado ativo, tenta localizar
        -- um botão disponível para permitir o teste/manual.
        if not button then
            local sideName = getLocalSide()
            if sideName then
                activeSide = sideName
                bindButton(sideName)
            end
        end

        pressButton()
    end
end)

UI:Section("Controles")
UI:Button("SPACE = Press manual","Jogando legit, basta apertar ESPAÇO em vez de clicar no botão.",function()
    UI:Notify("Stop The Timer","Atalho SPACE está ativo.","info")
end)

UI:Section("Precisão / Legit")

UI:Slider(
    "Ajuste do Press",
    "0 ms = cravar • positivo = antes • negativo = depois",
    -20,
    20,
    0,
    1,
    function(ms)
        PRESS_OFFSET = ms / 1000
        print(("[STOP TIMER] Ajuste: %+.0f ms | offset=%+.3fs"):format(ms, PRESS_OFFSET))
    end
)

UI:Toggle("Auto Press","Lê o alvo e aperta automaticamente no tempo.",false,function(on)
    autoPress=on
    pressedThisRound=false
    readTarget()
    print("[STOP TIMER] Auto Press:",on and "ON" or "OFF")
end)

UI:Button("Testar botão","Testa agora o botão detectado da sua mesa.",function()
    station=findStation()
    for _=1,20 do
        detectActiveTimer()
        if button then break end
        task.wait(.05)
    end
    if not button then
        local sideName=getLocalSide()
        if sideName then
            activeSide=sideName
            bindButton(sideName)
        end
    end
    pressButton()
end)

task.spawn(function()
    local lastStationCheck=0
    while task.wait(0.003) do
        if os.clock()-lastStationCheck >= .25 then
            local s=findStation()
            if s ~= station then
                station=s
                activeTimer=nil
                activeSide=nil
                button=nil
                lastValues.Player1=nil
                lastValues.Player2=nil
                pressedThisRound=false
                if s then print("[STOP TIMER] MESA:",s.Name) end
            end
            lastStationCheck=os.clock()
        end

        detectActiveTimer()

        if autoPress and target and activeTimer and not pressedThisRound then
            local current=parseTime(activeTimer.Text)
            local triggerAt = math.max(0, target - PRESS_OFFSET)
            if current and current > 0 and current >= triggerAt then
                pressedThisRound=true
                print(("[STOP TIMER] DISPARO alvo=%.2f atual=%.2f lado=%s"):format(
                    target,current,tostring(activeSide)
                ))
                if not pressButton() then pressedThisRound=false end
            end
        end
    end
end)

print("[STOP TIMER] SPACE: press manual ativo")
print("[ZYRO HUB] Stop The Timer v2.7 LOCAL SIDE + SLIDER carregado")
