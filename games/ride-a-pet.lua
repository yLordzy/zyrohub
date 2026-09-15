-- ZYRO HUB • RIDE A PET v3.0
-- Organizado a partir das funções do hub antigo.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local UI = getgenv().ZyroUI
if not UI then error("ZyroUI não carregada") end

local Eggs = Workspace:WaitForChild("RenderedEggs",10) or Workspace:FindFirstChild("RenderedEggs")
local highlights = {}
local globalESP = false
local insta = true
local autoBest = false
local autoBestToken = 0
local selectedEggName = nil
local trackESP = true
local continuousHop = false

local function root()
    local c=LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tp(inst)
    local r=root()
    if not r or not inst then return false end
    local cf
    if inst:IsA("Model") then cf=inst:GetPivot()
    elseif inst:IsA("BasePart") then cf=inst.CFrame end
    if cf then r.CFrame=cf*CFrame.new(0,3,0); return true end
    return false
end

local function home()
    local plots=Workspace:FindFirstChild("Plots")
    if not plots then return end
    for _,plot in ipairs(plots:GetChildren()) do
        local d=plot:FindFirstChild("Data")
        local o=d and d:FindFirstChild("Owner")
        if o and ((o:IsA("StringValue") and o.Value==LP.Name) or
            (o:IsA("ObjectValue") and o.Value==LP) or tostring(o.Value)==LP.Name) then
            tp(plot); return
        end
    end
end

local function updateHL(inst, force, color)
    if not inst or not (inst:IsA("Model") or inst:IsA("BasePart")) then return end
    local h=highlights[inst]
    local show = force or globalESP
    if show then
        if not h or not h.Parent then
            h=Instance.new("Highlight")
            h.Name="ZyroEggESP"
            h.Adornee=inst
            h.FillTransparency=.55
            h.OutlineTransparency=0
            h.Parent=inst
            highlights[inst]=h
        end
        h.FillColor=color or Color3.fromRGB(139,92,246)
        h.OutlineColor=color or Color3.fromRGB(196,181,253)
        h.Enabled=true
    elseif h then h.Enabled=false end
end

local function refreshESP()
    if not Eggs then return end
    for _,egg in ipairs(Eggs:GetChildren()) do
        updateHL(egg, selectedEggName and egg.Name==selectedEggName and trackESP,
            Color3.fromRGB(196,181,253))
    end
end

if Eggs then
    Eggs.ChildAdded:Connect(function(x) task.wait(.08); updateHL(x, selectedEggName==x.Name and trackESP) end)
    Eggs.ChildRemoved:Connect(function(x)
        if highlights[x] then pcall(function() highlights[x]:Destroy() end); highlights[x]=nil end
    end)
end

local promptConnections=setmetatable({}, {__mode="k"})
local function applyPrompt(p)
    if not p:IsA("ProximityPrompt") then return end
    if insta then pcall(function() p.HoldDuration=0 end) end
    if not promptConnections[p] then
        promptConnections[p]=p:GetPropertyChangedSignal("HoldDuration"):Connect(function()
            if insta and p.Parent and p.HoldDuration~=0 then pcall(function() p.HoldDuration=0 end) end
        end)
    end
end
for _,x in ipairs(Workspace:GetDescendants()) do if x:IsA("ProximityPrompt") then applyPrompt(x) end end
Workspace.DescendantAdded:Connect(function(x) if x:IsA("ProximityPrompt") then task.defer(applyPrompt,x) end end)

local function interact(target)
    if not target then return false end
    local env=(getgenv and getgenv()) or _G
    local fp=(type(fireproximityprompt)=="function" and fireproximityprompt) or env.fireproximityprompt
    local fired=false
    for _,x in ipairs(target:GetDescendants()) do
        if x:IsA("ProximityPrompt") and x.Enabled then
            applyPrompt(x)
            if type(fp)=="function" then fired=pcall(function() fp(x,0) end) or fired end
        end
    end
    return fired
end

local function holdE(t)
    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
    task.wait(t or .15)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end

local function findByName(name)
    if not Eggs then return nil end
    for _,e in ipairs(Eggs:GetChildren()) do if e.Name==name then return e end end
end

local function bestEgg()
    if not Eggs then return nil end
    for _,e in ipairs(Eggs:GetChildren()) do
        if e.Name:lower():find("cherub",1,true) then return e end
    end
end

local function startAutoBest()
    autoBestToken+=1
    local token=autoBestToken
    task.spawn(function()
        while autoBest and token==autoBestToken do
            local e=bestEgg()
            if e and e.Parent then
                tp(e); task.wait(.25)
                if not interact(e) then holdE(.25) end
                task.wait(.2); home(); task.wait(.8)
            else task.wait(.4) end
        end
    end)
end

local function uniqueEggNames()
    local names={}
    local seen={}
    if Eggs then
        for _,e in ipairs(Eggs:GetChildren()) do
            if not seen[e.Name] then seen[e.Name]=true; table.insert(names,e.Name) end
        end
    end
    table.sort(names,function(a,b) return a:lower()<b:lower() end)
    return names
end

local function hopServer()
    local cursor=""
    for _=1,5 do
        local url=("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s")
            :format(game.GameId, cursor~="" and "&cursor="..HttpService:UrlEncode(cursor) or "")
        local ok,body=pcall(function() return game:HttpGet(url) end)
        if not ok then return false end
        local data=HttpService:JSONDecode(body)
        for _,srv in ipairs(data.data or {}) do
            if srv.id~=game.JobId and (srv.playing or 0)<(srv.maxPlayers or 0) then
                TeleportService:TeleportToPlaceInstance(game.PlaceId,srv.id,LP)
                return true
            end
        end
        cursor=data.nextPageCursor or ""
        if cursor=="" then break end
    end
    return false
end

UI:SetGame("Ride A Pet")
UI:Tab("Principal")
UI:Tab("Egg Track")
UI:Tab("Egg Browser")
UI:Tab("Server Hop")

UI:UseTab("Principal")
UI:Section("Automação e utilidades")
UI:Toggle("Egg ESP","Destaca todos os eggs renderizados.",false,function(v)
    globalESP=v; refreshESP()
end)
UI:Toggle("Insta Interact","Deixa ProximityPrompts instantâneos.",true,function(v)
    insta=v
    if v then
        for _,x in ipairs(Workspace:GetDescendants()) do if x:IsA("ProximityPrompt") then applyPrompt(x) end end
    end
end)
UI:Toggle("Auto Best Egg","Procura Cherub, coleta e volta para sua plot.",false,function(v)
    autoBest=v; autoBestToken+=1; if v then startAutoBest() end
end)
UI:Button("TP Home","Voltar para sua plot.",home)

UI:UseTab("Egg Track")
UI:Section("Egg Track • alvo persistente")
UI:Toggle("ESP do alvo","Mantém o egg selecionado destacado.",true,function(v) trackESP=v; refreshESP() end)
UI:Button("Ir para o alvo","Teleporta para o egg selecionado atualmente.",function()
    if selectedEggName then
        local e=findByName(selectedEggName)
        if e then tp(e) else UI:Notify("Egg Track","Alvo não está neste servidor.") end
    else UI:Notify("Egg Track","Selecione um egg no Egg Browser.") end
end)
UI:Button("Coletar alvo","Teleporta e tenta interagir com o alvo.",function()
    local e=selectedEggName and findByName(selectedEggName)
    if e then tp(e); task.wait(.2); if not interact(e) then holdE(.2) end end
end)

UI:UseTab("Egg Browser")
UI:Section("Egg Browser • eggs deste servidor")
local names=uniqueEggNames()
if #names==0 then
    UI:Button("Nenhum egg encontrado","RenderedEggs está vazio no momento.",function() end)
else
    for _,name in ipairs(names) do
        local n=name
        UI:Button(n, selectedEggName==n and "ALVO ATUAL" or "Clique para selecionar e teleportar.",function()
            selectedEggName=n
            refreshESP()
            local e=findByName(n)
            if e then tp(e) end
            UI:Notify("Egg Browser","Alvo: "..n)
        end)
    end
end

UI:UseTab("Server Hop")
UI:Section("Server Hop • procurar novos spawns")
UI:Button("Server Hop","Entra em outro servidor público com vaga.",function()
    UI:Notify("Server Hop","Procurando servidor...")
    if not hopServer() then UI:Notify("Server Hop","Não encontrei servidor disponível.") end
end)
UI:Toggle("Hop contínuo","Quando o alvo não estiver aqui, permite procurar em outro servidor.",false,function(v)
    continuousHop=v
end)
UI:Button("Procurar alvo em outro servidor","Só faz hop se o Egg Track tiver um alvo e ele não estiver aqui.",function()
    if not selectedEggName then UI:Notify("Server Hop","Escolha um alvo no Egg Browser."); return end
    if findByName(selectedEggName) then UI:Notify("Server Hop","O alvo já está neste servidor."); return end
    hopServer()
end)

UI:SelectTab("Principal")
refreshESP()
print("[ZYRO HUB] Ride A Pet v3.0 • 4 TABS carregado")
