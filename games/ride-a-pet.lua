-- ZYRO HUB • RIDE A PET v4.0 • RICH GUI
-- Visual inspirado no hub antigo, reorganizado para o sistema modular atual.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LP = Players.LocalPlayer
local UI = getgenv().ZyroUI
if not UI then error("ZyroUI não carregada") end

local Eggs = Workspace:WaitForChild("RenderedEggs", 10) or Workspace:FindFirstChild("RenderedEggs")

local Theme = {
    Surface = Color3.fromRGB(18, 12, 31),
    Surface2 = Color3.fromRGB(27, 18, 45),
    Surface3 = Color3.fromRGB(38, 25, 61),
    Accent = Color3.fromRGB(139, 92, 246),
    Accent2 = Color3.fromRGB(196, 181, 253),
    Text = Color3.fromRGB(245, 240, 255),
    Muted = Color3.fromRGB(157, 145, 177),
    Dim = Color3.fromRGB(110, 98, 131),
    Success = Color3.fromRGB(119, 230, 170),
    Warning = Color3.fromRGB(241, 196, 91),
    Danger = Color3.fromRGB(255, 105, 135),
}

local env = (getgenv and getgenv()) or _G
env.ZyroRideState = env.ZyroRideState or {
    targets = {},
    globalESP = false,
    insta = true,
    autoBest = false,
    autoHop = false,
    antiGameplayPaused = true,
}

local State = env.ZyroRideState

-- =========================================================
-- EGG TRACK • PERSISTÊNCIA ENTRE SERVER HOPS
-- =========================================================
local CONFIG_FOLDER = "ZyroHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/ride_a_pet_targets.json"

local writeFileFn = (type(writefile)=="function" and writefile) or env.writefile
local readFileFn = (type(readfile)=="function" and readfile) or env.readfile
local isFileFn = (type(isfile)=="function" and isfile) or env.isfile
local makeFolderFn = (type(makefolder)=="function" and makefolder) or env.makefolder
local isFolderFn = (type(isfolder)=="function" and isfolder) or env.isfolder

local function ensureConfigFolder()
    if type(makeFolderFn)~="function" then return end
    local exists=false
    pcall(function()
        if type(isFolderFn)=="function" then exists=isFolderFn(CONFIG_FOLDER) end
    end)
    if not exists then pcall(function() makeFolderFn(CONFIG_FOLDER) end) end
end

local function saveTrackConfig()
    if type(writeFileFn)~="function" then return false end
    ensureConfigFolder()
    local payload={
        version=1,
        targets=State.targets or {},
        autoHop=State.autoHop==true,
    }
    local ok,encoded=pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then return false end
    return pcall(function() writeFileFn(CONFIG_FILE,encoded) end)
end

local function loadTrackConfig()
    if type(readFileFn)~="function" or type(isFileFn)~="function" then return false end
    local exists=false
    pcall(function() exists=isFileFn(CONFIG_FILE) end)
    if not exists then return false end
    local ok,raw=pcall(function() return readFileFn(CONFIG_FILE) end)
    if not ok or type(raw)~="string" or raw=="" then return false end
    local decodedOk,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if not decodedOk or type(data)~="table" then return false end
    if type(data.targets)=="table" then State.targets=data.targets end
    State.autoHop=data.autoHop==true
    return true
end

loadTrackConfig()

local highlights = setmetatable({}, {__mode="k"})
local promptConnections = setmetatable({}, {__mode="k"})
local autoBestToken = 0
local autoHopToken = 0

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Accent
    s.Transparency = transparency or .55
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function padding(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0,l or 0)
    p.PaddingRight = UDim.new(0,r or 0)
    p.PaddingTop = UDim.new(0,t or 0)
    p.PaddingBottom = UDim.new(0,b or 0)
    p.Parent = parent
    return p
end

local function text(parent, str, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = str or ""
    l.TextColor3 = color or Theme.Text
    l.TextSize = size or 12
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or .16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function card(parent, titleText, subtitleText)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Theme.Surface
    f.BorderSizePixel = 0
    f.Size = UDim2.new(1,0,0,0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = parent
    corner(f,14)
    stroke(f, Theme.Accent, .78, 1)
    padding(f,14,14,13,14)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,9)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = f

    local head = Instance.new("Frame")
    head.BackgroundTransparency = 1
    head.Size = UDim2.new(1,0,0,subtitleText and 38 or 20)
    head.Parent = f

    local t = text(head,titleText,13,Theme.Text,Enum.Font.GothamBold)
    t.Size = UDim2.new(1,0,0,18)

    if subtitleText then
        local s = text(head,subtitleText,9,Theme.Muted,Enum.Font.Gotham)
        s.Position = UDim2.new(0,0,0,21)
        s.Size = UDim2.new(1,0,0,14)
        s.TextWrapped = true
    end
    return f
end

local function action(parent, titleText, subtitleText, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,54)
    b.BackgroundColor3 = Theme.Surface2
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b,12)
    stroke(b, Theme.Accent, .88, 1)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,3,0,26)
    bar.Position = UDim2.new(0,10,.5,-13)
    bar.BackgroundColor3 = Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = b
    corner(bar,99)

    local a = text(b,titleText,11,Theme.Text,Enum.Font.GothamSemibold)
    a.Position = UDim2.new(0,22,0,7)
    a.Size = UDim2.new(1,-34,0,17)

    local s = text(b,subtitleText or "",8,Theme.Muted,Enum.Font.Gotham)
    s.Position = UDim2.new(0,22,0,28)
    s.Size = UDim2.new(1,-34,0,13)

    b.MouseEnter:Connect(function() tween(b,{BackgroundColor3=Theme.Surface3}) end)
    b.MouseLeave:Connect(function() tween(b,{BackgroundColor3=Theme.Surface2}) end)
    b.MouseButton1Click:Connect(function() if cb then task.spawn(cb) end end)
    return b
end

local function toggle(parent, titleText, subtitleText, initial, cb)
    local value = initial == true
    local row = action(parent,titleText,subtitleText,function()
        value = not value
        render()
        if cb then cb(value) end
    end)

    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(38,22)
    sw.Position = UDim2.new(1,-50,.5,-11)
    sw.BorderSizePixel = 0
    sw.Parent = row
    corner(sw,99)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16,16)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    corner(knob,99)

    function render()
        tween(sw,{BackgroundColor3=value and Theme.Accent or Theme.Surface3})
        tween(knob,{
            Position=value and UDim2.fromOffset(19,3) or UDim2.fromOffset(3,3),
            BackgroundColor3=value and Theme.Text or Theme.Muted
        })
    end
    render()
    return {Get=function() return value end, Set=function(v) value=v==true; render(); if cb then cb(value) end end}
end

local function root()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(inst)
    local r = root()
    if not r or not inst then return false end
    local cf
    if inst:IsA("Model") then cf = inst:GetPivot()
    elseif inst:IsA("BasePart") then cf = inst.CFrame end
    if cf then r.CFrame = cf * CFrame.new(0,3,0); return true end
    return false
end

local function teleportHome()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return false end
    for _,plot in ipairs(plots:GetChildren()) do
        local d = plot:FindFirstChild("Data")
        local o = d and d:FindFirstChild("Owner")
        if o and (
            (o:IsA("StringValue") and o.Value == LP.Name)
            or (o:IsA("ObjectValue") and o.Value == LP)
            or tostring(o.Value) == LP.Name
        ) then
            return teleportTo(plot)
        end
    end
    return false
end

local function normalize(name)
    return tostring(name or "")
        :lower()
        :gsub("<.->","")
        :gsub("[^%w]","")
end

local function eggMatchesTarget(eggName, targetKey)
    local eggKey=normalize(eggName)
    local wanted=normalize(targetKey)
    if eggKey=="" or wanted=="" then return false end
    return eggKey==wanted
        or eggKey:find(wanted,1,true)~=nil
        or wanted:find(eggKey,1,true)~=nil
end

local function refreshEggFolder()
    Eggs = Workspace:FindFirstChild("RenderedEggs") or Eggs
    return Eggs
end

local function eggList()
    refreshEggFolder()
    local out = {}
    if Eggs then
        for _,e in ipairs(Eggs:GetChildren()) do
            if e:IsA("Model") or e:IsA("BasePart") then
                out[#out+1] = e
            end
        end
    end
    table.sort(out,function(a,b) return a.Name:lower() < b.Name:lower() end)
    return out
end

local function targetIsSelected(name)
    return State.targets[normalize(name)] ~= nil
end

local function setTarget(name, enabled)
    local k = normalize(name)
    if k=="" then return end
    if enabled then State.targets[k] = tostring(name) else State.targets[k] = nil end
    saveTrackConfig()
end

local function updateHighlight(egg, custom)
    if not egg then return end
    local h = highlights[egg]
    local show = State.globalESP or custom or targetIsSelected(egg.Name)
    if show then
        if not h or not h.Parent then
            h = Instance.new("Highlight")
            h.Name = "ZyroEggESP"
            h.Adornee = egg
            h.FillTransparency = .52
            h.OutlineTransparency = 0
            h.Parent = egg
            highlights[egg] = h
        end
        local target = targetIsSelected(egg.Name)
        h.FillColor = target and Theme.Accent2 or Theme.Accent
        h.OutlineColor = target and Theme.Success or Theme.Accent2
        h.Enabled = true
    elseif h then
        h.Enabled = false
    end
end

local function refreshHighlights()
    for _,e in ipairs(eggList()) do updateHighlight(e,false) end
end

local function applyPrompt(p)
    if not p or not p:IsA("ProximityPrompt") then return end
    if State.insta then pcall(function() p.HoldDuration = 0 end) end
    if not promptConnections[p] then
        promptConnections[p] = p:GetPropertyChangedSignal("HoldDuration"):Connect(function()
            if State.insta and p.Parent and p.HoldDuration ~= 0 then
                pcall(function() p.HoldDuration = 0 end)
            end
        end)
    end
end

for _,d in ipairs(Workspace:GetDescendants()) do if d:IsA("ProximityPrompt") then applyPrompt(d) end end
Workspace.DescendantAdded:Connect(function(d)
    if d:IsA("ProximityPrompt") then task.defer(applyPrompt,d) end
end)

local function getPrompt(target)
    if not target then return nil end

    if target:IsA("ProximityPrompt") and target.Enabled then
        return target
    end

    for _,obj in ipairs(target:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            return obj
        end
    end

    return nil
end

local function promptWorldPosition(prompt)
    if not prompt then return nil end

    local parent = prompt.Parent
    if not parent then return nil end

    if parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent:IsA("BasePart") then
        return parent.Position
    end

    local part = parent:FindFirstAncestorWhichIsA("BasePart")
    if part then return part.Position end

    return nil
end

local function targetPosition(target)
    -- PRIORIDADE: posição REAL do ProximityPrompt.
    -- O pivot do Model pode ficar longe do ponto de interação.
    local prompt = getPrompt(target)
    local promptPos = promptWorldPosition(prompt)
    if promptPos then
        return promptPos
    end

    if not target then return nil end
    if target:IsA("Model") then
        return target:GetPivot().Position
    elseif target:IsA("BasePart") then
        return target.Position
    end
    return nil
end

local function requestStreamAtTarget(target)
    local pos = targetPosition(target)
    if not pos then return end
    pcall(function()
        LP:RequestStreamAroundAsync(pos, 2)
    end)
end

local function distanceTo(target)
    local r = root()
    local pos = targetPosition(target)
    if not r or not pos then return math.huge end
    return (r.Position - pos).Magnitude
end

local function safeWalkTo(target)
    local r = root()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local pos = targetPosition(target)
    local prompt = getPrompt(target)

    if not r or not hum or not pos then
        return false, "NO_CHARACTER"
    end

    -- Fica realmente dentro da distância válida do prompt.
    local maxDist = prompt and tonumber(prompt.MaxActivationDistance) or 10
    local stopDistance = math.max(2.5, math.min(maxDist - 1, 6))

    if (r.Position - pos).Magnitude <= stopDistance then
        return true
    end

    requestStreamAtTarget(target)

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 3,
    })

    local ok = pcall(function()
        path:ComputeAsync(r.Position, pos)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        return false, "PATH_FAILED"
    end

    for _,waypoint in ipairs(path:GetWaypoints()) do
        if not target.Parent then
            return false, "TARGET_GONE"
        end

        if distanceTo(target) <= stopDistance then
            hum:Move(Vector3.zero)
            return true
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            hum.Jump = true
        end

        hum:MoveTo(waypoint.Position)

        local finished = false
        local reached = false
        local conn
        conn = hum.MoveToFinished:Connect(function(okReached)
            reached = okReached
            finished = true
        end)

        local started = os.clock()
        while not finished and os.clock() - started < 4 do
            if distanceTo(target) <= stopDistance then
                reached = true
                break
            end
            task.wait(.05)
        end

        if conn then conn:Disconnect() end

        if not reached and distanceTo(target) > stopDistance then
            return false, "MOVE_FAILED"
        end
    end

    return distanceTo(target) <= stopDistance
end

local function normalPromptInteract(target)
    local prompt = getPrompt(target)
    if not prompt then
        return false, "NO_PROMPT"
    end

    local pos = promptWorldPosition(prompt)
    local r = root()
    if not pos or not r then
        return false, "NO_PROMPT_POSITION"
    end

    local maxDist = tonumber(prompt.MaxActivationDistance) or 10
    local dist = (r.Position - pos).Magnitude

    if dist > maxDist then
        return false, ("TOO_FAR_%.1f"):format(dist)
    end

    -- NÃO usa fireproximityprompt aqui.
    -- O jogo estava tocando o som local, mas o servidor rejeitava a coleta.
    -- Em vez disso, envia a tecla E como uma interação normal.
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
    end)

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(math.max(.08, tonumber(prompt.HoldDuration) or 0) + .08)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

    return true
end


local function flyToCFrame(destinationCFrame, duration)
    local r = root()
    if not r or not destinationCFrame then return false end

    duration = duration or 0.85

    local startCF = r.CFrame
    local startPos = startCF.Position
    local endPos = destinationCFrame.Position

    -- Faz um arco simples: sobe, cruza e desce.
    local apexY = math.max(startPos.Y, endPos.Y) + 24
    local started = os.clock()

    while r.Parent and os.clock() - started < duration do
        local a = math.clamp((os.clock() - started) / duration, 0, 1)

        local pos
        if a < 0.25 then
            local t = a / 0.25
            pos = startPos:Lerp(Vector3.new(startPos.X, apexY, startPos.Z), t)
        elseif a < 0.75 then
            local t = (a - 0.25) / 0.50
            pos = Vector3.new(startPos.X, apexY, startPos.Z):Lerp(
                Vector3.new(endPos.X, apexY, endPos.Z),
                t
            )
        else
            local t = (a - 0.75) / 0.25
            pos = Vector3.new(endPos.X, apexY, endPos.Z):Lerp(endPos, t)
        end

        r.CFrame = CFrame.new(pos) * (startCF - startCF.Position)
        RunService.Heartbeat:Wait()
    end

    if r and r.Parent then
        r.CFrame = destinationCFrame
        return true
    end

    return false
end

local function teleportNearTarget(target)
    local r = root()
    local pos = targetPosition(target)
    if not r or not pos then return false end

    -- Teleporta para uma posição curta do prompt, mas não em cima dele.
    local offset = Vector3.new(0, 2.5, 4)
    r.CFrame = CFrame.new(pos + offset, pos)
    return true
end

local function safeCollect(target)
    if not target or not target.Parent then
        return false, "TARGET_GONE"
    end

    local r = root()
    if not r then
        return false, "NO_CHARACTER"
    end

    local returnCF = r.CFrame

    -- 1) TP rápido PARA o egg.
    local teleported = teleportNearTarget(target)
    if not teleported then
        return false, "TP_FAILED"
    end

    -- 2) Espera o cliente/servidor reconhecer a nova posição.
    requestStreamAtTarget(target)
    task.wait(.22)

    -- 3) Usa o prompt normalmente, já estando perto.
    local fired, why = normalPromptInteract(target)
    if not fired then
        -- Mesmo se falhar, volta voando para onde estava.
        flyToCFrame(returnCF, 1.55)
        return false, why
    end

    -- 4) Dá uma pequena janela para o servidor confirmar a coleta.
    task.wait(1.10)

    -- 5) Volta VOANDO, não por teleport instantâneo.
    flyToCFrame(returnCF, 1.65)

    return true
end

local function holdE(duration)
    VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.E,false,game)
    task.wait(duration or .25)
    VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.E,false,game)
end

local function findCherub()
    for _,e in ipairs(eggList()) do
        if e.Name:lower():find("cherub",1,true) then return e end
    end
end

local function startAutoBest()
    autoBestToken += 1
    local token = autoBestToken
    task.spawn(function()
        while State.autoBest and token == autoBestToken do
            local e = findCherub()
            if e and e.Parent then
                local worked, reason = safeCollect(e)
                if worked then
                    UI:Notify("Auto Best Egg","Coleta segura enviada para "..e.Name)
                else
                    warn("[ZYRO SafeCollect] Falhou:",reason)
                    if reason=="MOVE_FAILED" or reason=="PATH_FAILED" then
                        UI:Notify("Auto Best Egg","Não consegui chegar andando até o egg.")
                    end
                end
                task.wait(.8)
            else
                task.wait(.4)
            end
        end
    end)
end

local hopBusy = false

local function executorRequest(url)
    local function validBody(body)
        return type(body)=="string" and #body>2
    end

    -- Primeiro tenta o HttpGet do executor.
    local ok, body = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and validBody(body) then
        return body, nil
    end

    -- Fallback para executores que expõem request/http_request/syn.request/etc.
    local req = nil
    if type(env.request)=="function" then
        req=env.request
    elseif type(env.http_request)=="function" then
        req=env.http_request
    elseif env.syn and type(env.syn.request)=="function" then
        req=env.syn.request
    elseif env.http and type(env.http.request)=="function" then
        req=env.http.request
    elseif env.fluxus and type(env.fluxus.request)=="function" then
        req=env.fluxus.request
    end

    if type(req)=="function" then
        local reqOk, response = pcall(req,{
            Url=url,
            Method="GET",
            Headers={
                ["Accept"]="application/json",
                ["Cache-Control"]="no-cache"
            }
        })
        if reqOk and type(response)=="table" then
            local status=tonumber(response.StatusCode or response.Status or response.status_code)
            local rb=response.Body or response.body
            if status and (status<200 or status>=300) then
                return nil,"HTTP_STATUS_"..tostring(status)
            end
            if validBody(rb) then return rb,nil end
        end
    end
    return nil,"HTTP_REQUEST_FAILED"
end

local function fetchPublicServers(cursor)
    -- IMPORTANTE: este endpoint usa PlaceId, não GameId/UniverseId.
    local url="https://games.roblox.com/v1/games/"..
        tostring(game.PlaceId)..
        "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"

    if cursor and cursor~="" then
        url=url.."&cursor="..HttpService:UrlEncode(cursor)
    end

    local body,err=executorRequest(url)
    if not body then return nil,err end

    local ok,data=pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not ok or type(data)~="table" then
        warn("[ZYRO ServerHop] JSON inválido:",tostring(body):sub(1,180))
        return nil,"JSON_DECODE_FAILED"
    end

    if type(data.errors)=="table" and #data.errors>0 then
        warn("[ZYRO ServerHop] API Roblox retornou erro:",tostring(data.errors[1] and data.errors[1].message))
        return nil,"ROBLOX_API_ERROR"
    end

    if type(data.data)~="table" then
        return nil,"INVALID_SERVER_RESPONSE"
    end

    return data,nil
end

local function findHopServer()
    local cursor=nil
    local pages=0
    local candidates={}
    local lastError=nil

    repeat
        pages+=1
        local page,err=fetchPublicServers(cursor)
        if not page then
            lastError=err
            break
        end

        for _,srv in ipairs(page.data or {}) do
            local id=tostring(srv.id or "")
            local playing=tonumber(srv.playing) or 0
            local maxPlayers=tonumber(srv.maxPlayers) or 0
            if id~="" and id~=game.JobId and maxPlayers>0 and playing<maxPlayers then
                candidates[#candidates+1]={
                    id=id,
                    playing=playing,
                    maxPlayers=maxPlayers
                }
            end
        end

        cursor=page.nextPageCursor
    until not cursor or cursor=="" or pages>=5 or #candidates>=20

    if #candidates==0 then
        return nil,lastError or "NO_SERVERS"
    end

    table.sort(candidates,function(a,b)
        if a.playing==b.playing then return a.id<b.id end
        return a.playing<b.playing
    end)

    -- Não cai sempre no mesmo servidor.
    local pool=math.min(8,#candidates)
    return candidates[math.random(1,pool)],nil
end

local function hopServer()
    if hopBusy then
        UI:Notify("Server Hop","Já estou procurando um servidor.")
        return false
    end

    hopBusy=true
    UI:Notify("Server Hop","Procurando outro servidor...")

    local server,reason=findHopServer()
    if not server then
        hopBusy=false
        warn("[ZYRO ServerHop] Falhou:",reason)
        UI:Notify("Server Hop","Falha: "..tostring(reason))
        return false
    end

    print(
        "[ZYRO ServerHop] Indo para:",
        server.id,
        "Players:",
        tostring(server.playing).."/"..tostring(server.maxPlayers)
    )

    UI:Notify(
        "Server Hop",
        "Entrando em outro servidor ("..
        tostring(server.playing).."/"..tostring(server.maxPlayers)..")..."
    )

    local ok,err=pcall(function()
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            server.id,
            LP
        )
    end)

    if not ok then
        hopBusy=false
        warn("[ZYRO ServerHop] Teleport falhou:",err)
        UI:Notify("Server Hop","Servidor encontrado, mas o teleport falhou.")
        return false
    end

    task.delay(8,function()
        hopBusy=false
    end)

    return true
end

local function wantedEgg()
    local eggs=eggList()
    for _,e in ipairs(eggs) do
        for k,display in pairs(State.targets) do
            if eggMatchesTarget(e.Name,k) or eggMatchesTarget(e.Name,display) then
                return e,k
            end
        end
    end
    return nil,nil
end

local function startAutoHop()
    autoHopToken += 1
    local token = autoHopToken
    task.spawn(function()
        while State.autoHop and token == autoHopToken do
            if next(State.targets) == nil then
                UI:Notify("Server Hop","Selecione ao menos um ALVO.")
                State.autoHop = false
                saveTrackConfig()
                break
            end

            local found = wantedEgg()
            if found then
                UI:Notify("Egg Track","Alvo encontrado: "..found.Name)
                local worked, reason = safeCollect(found)
                if worked then
                    UI:Notify("Egg Track","Coleta segura concluída.")
                else
                    warn("[ZYRO EggTrack] SafeCollect falhou:",reason)
                    UI:Notify("Egg Track","Não consegui coletar com segurança: "..tostring(reason))
                end
                State.autoHop = false
                saveTrackConfig()
                break
            end

            UI:Notify("Server Hop","Alvo não encontrado. Mudando de servidor...")
            if hopServer() then break end
            task.wait(10)
        end
    end)
end


-- =========================================================
-- ANTI GAMEPLAY PAUSED
-- =========================================================
-- O Ride A Pet usa streaming. Teleportes longos podem acionar o estado
-- Player.GameplayPaused enquanto a região de destino ainda está carregando.
-- Este modo:
--   1) remove o modal padrão;
--   2) tenta desativar StreamingIntegrityMode no cliente quando o ambiente permite;
--   3) pede streaming ao redor do personagem quando a pausa for detectada.
local antiPauseConnection = nil
local antiPauseHeartbeat = nil
local lastStreamRequest = 0

local function requestStreamHere()
    local r = root()
    if not r then return end
    if os.clock() - lastStreamRequest < 0.35 then return end
    lastStreamRequest = os.clock()

    task.spawn(function()
        pcall(function()
            LP:RequestStreamAroundAsync(r.Position, 2)
        end)
    end)
end

local function tryDisableStreamingPause()
    -- Remove somente a tela/modal oficial.
    pcall(function()
        GuiService:SetGameplayPausedNotificationEnabled(false)
    end)

    -- Em jogos/ambientes onde a propriedade é gravável pelo cliente.
    pcall(function()
        Workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.Disabled
    end)

    -- Fallback para ambientes que expõem sethiddenproperty.
    local shp = rawget(env, "sethiddenproperty")
    if type(shp) ~= "function" and type(sethiddenproperty) == "function" then
        shp = sethiddenproperty
    end

    if type(shp) == "function" then
        pcall(function()
            shp(Workspace, "StreamingIntegrityMode", Enum.StreamingIntegrityMode.Disabled)
        end)
    end
end

local function stopAntiGameplayPaused()
    if antiPauseConnection then
        pcall(function() antiPauseConnection:Disconnect() end)
        antiPauseConnection = nil
    end
    if antiPauseHeartbeat then
        pcall(function() antiPauseHeartbeat:Disconnect() end)
        antiPauseHeartbeat = nil
    end

    -- Reabilita só a notificação padrão. O modo de streaming original
    -- pode ser controlado pelo jogo/servidor e não é forçado aqui.
    pcall(function()
        GuiService:SetGameplayPausedNotificationEnabled(true)
    end)
end

local function startAntiGameplayPaused()
    stopAntiGameplayPaused()
    tryDisableStreamingPause()
    requestStreamHere()

    antiPauseConnection = LP:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
        if not State.antiGameplayPaused then return end

        if LP.GameplayPaused then
            -- Tenta carregar imediatamente a área atual/destino.
            tryDisableStreamingPause()
            requestStreamHere()
        end
    end)

    antiPauseHeartbeat = RunService.Heartbeat:Connect(function()
        if not State.antiGameplayPaused then return end

        -- Reaplica com baixa frequência, porque alguns jogos reconfiguram
        -- StreamingIntegrityMode depois do carregamento.
        if LP.GameplayPaused then
            requestStreamHere()
        end
    end)
end

-- Mantém o hub e o Egg Track vivos depois de Server Hop, se o executor suportar.
do
    local queue = (type(queue_on_teleport)=="function" and queue_on_teleport)
        or env.queue_on_teleport
        or (env.syn and env.syn.queue_on_teleport)

    if type(queue)=="function" then
        pcall(function()
            queue([[
task.wait(2)
local url="https://raw.githubusercontent.com/yLordzy/zyrohub/refs/heads/main/loader.lua?_="..tostring(DateTime.now().UnixTimestampMillis)
loadstring(game:HttpGet(url,false))()
]])
        end)
    end
end

-- =========================================================
-- PÁGINAS
-- =========================================================

UI:SetGame("Ride A Pet")
UI:Tab("Dashboard")
UI:Tab("Egg Browser")
UI:Tab("Egg Track")
UI:Tab("Server Hop")

local Dashboard = UI:GetTabPage("Dashboard")
local Browser = UI:GetTabPage("Egg Browser")
local Tracker = UI:GetTabPage("Egg Track")
local Servers = UI:GetTabPage("Server Hop")

-- DASHBOARD
do
    local hero = card(Dashboard,"Ride A Pet • Control Center","Automação, ESP, teleporte e ferramentas principais.")

    local stats = Instance.new("Frame")
    stats.Size = UDim2.new(1,0,0,72)
    stats.BackgroundTransparency = 1
    stats.Parent = hero

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(.333,-6,1,0)
    grid.CellPadding = UDim2.fromOffset(8,0)
    grid.Parent = stats

    local function stat(titleText, valueText)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = Theme.Surface2
        f.BorderSizePixel = 0
        f.Parent = stats
        corner(f,11)
        local a = text(f,titleText,8,Theme.Muted,Enum.Font.GothamBold)
        a.Position = UDim2.fromOffset(11,8); a.Size = UDim2.new(1,-22,0,14)
        local v = text(f,valueText,17,Theme.Text,Enum.Font.GothamBold)
        v.Position = UDim2.fromOffset(11,29); v.Size = UDim2.new(1,-22,0,25)
        return v
    end

    local EggCount = stat("EGGS NO SERVIDOR","0")
    local TargetCount = stat("ALVOS","0")
    local Status = stat("STATUS","ONLINE")

    task.spawn(function()
        while EggCount.Parent do
            EggCount.Text = tostring(#eggList())
            local n=0 for _ in pairs(State.targets) do n+=1 end
            TargetCount.Text = tostring(n)
            task.wait(1)
        end
    end)

    local automation = card(Dashboard,"Automação","Funções mais usadas durante o farm.")
    toggle(automation,"Egg ESP","Destacar todos os eggs renderizados.",State.globalESP,function(v)
        State.globalESP=v
        refreshHighlights()
    end)
    toggle(automation,"Insta Interact","Reduz HoldDuration dos ProximityPrompts.",State.insta,function(v)
        State.insta=v
        if v then
            for _,d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then applyPrompt(d) end
            end
        end
    end)
    toggle(automation,"Anti Gameplay Paused","Evita a pausa de streaming durante teleports e esconde o modal.",State.antiGameplayPaused,function(v)
        State.antiGameplayPaused=v
        if v then
            startAntiGameplayPaused()
            UI:Notify("Anti Pause","Anti Gameplay Paused ativado.")
        else
            stopAntiGameplayPaused()
            UI:Notify("Anti Pause","Anti Gameplay Paused desativado.")
        end
    end)
    toggle(automation,"Auto Best Egg","Procura Cherub, coleta e volta para sua plot.",State.autoBest,function(v)
        State.autoBest=v
        autoBestToken+=1
        if v then startAutoBest() end
    end)

    local quick = card(Dashboard,"Ações rápidas","Atalhos úteis.")
    action(quick,"TP HOME","Voltar para sua plot.",function()
        if not teleportHome() then UI:Notify("Teleport","Sua plot não foi encontrada.") end
    end)
    action(quick,"COLETAR CHERUB","Dá TP perto do Cherub, espera confirmar a coleta e volta voando mais devagar.",function()
        local e=findCherub()
        if e then
            local worked, reason=safeCollect(e)
            if worked then
                UI:Notify("Ride A Pet","Coleta segura enviada para "..e.Name)
            else
                UI:Notify("Ride A Pet","Falhou: "..tostring(reason))
            end
        else
            UI:Notify("Ride A Pet","Nenhum Cherub encontrado.")
        end
    end)
end

-- EGG BROWSER
local refreshBrowser
local refreshTrackUI
do
    local box = card(Browser,"Egg Browser","Lista limpa com ALVO, TP e ESP individual.")

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,38)
    row.BackgroundTransparency = 1
    row.Parent = box

    local Search = Instance.new("TextBox")
    Search.Size = UDim2.new(1,-46,1,0)
    Search.BackgroundColor3 = Theme.Surface2
    Search.BorderSizePixel = 0
    Search.PlaceholderText = "Buscar egg..."
    Search.PlaceholderColor3 = Theme.Dim
    Search.Text = ""
    Search.TextColor3 = Theme.Text
    Search.TextSize = 10
    Search.Font = Enum.Font.Gotham
    Search.TextXAlignment = Enum.TextXAlignment.Left
    Search.ClearTextOnFocus = false
    Search.Parent = row
    corner(Search,10)
    padding(Search,10,8,0,0)

    local Refresh = Instance.new("TextButton")
    Refresh.Size = UDim2.fromOffset(38,38)
    Refresh.Position = UDim2.new(1,-38,0,0)
    Refresh.BackgroundColor3 = Theme.Surface2
    Refresh.BorderSizePixel = 0
    Refresh.Text = "↻"
    Refresh.TextColor3 = Theme.Text
    Refresh.TextSize = 18
    Refresh.Font = Enum.Font.GothamBold
    Refresh.Parent = row
    corner(Refresh,10)

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1,0,0,26)
    Header.BackgroundColor3 = Theme.Surface3
    Header.BorderSizePixel = 0
    Header.Parent = box
    corner(Header,8)

    local h1=text(Header,"EGG",8,Theme.Muted,Enum.Font.GothamBold)
    h1.Position=UDim2.fromOffset(10,0); h1.Size=UDim2.new(1,-175,1,0)
    local h2=text(Header,"ALVO",8,Theme.Muted,Enum.Font.GothamBold)
    h2.Position=UDim2.new(1,-154,0,0); h2.Size=UDim2.fromOffset(48,26)
    local h3=text(Header,"TP",8,Theme.Muted,Enum.Font.GothamBold)
    h3.Position=UDim2.new(1,-96,0,0); h3.Size=UDim2.fromOffset(35,26)
    local h4=text(Header,"ESP",8,Theme.Muted,Enum.Font.GothamBold)
    h4.Position=UDim2.new(1,-51,0,0); h4.Size=UDim2.fromOffset(35,26)

    local List = Instance.new("ScrollingFrame")
    List.Size = UDim2.new(1,0,0,235)
    List.BackgroundColor3 = Color3.fromRGB(12,8,22)
    List.BorderSizePixel = 0
    List.ScrollBarThickness = 3
    List.ScrollBarImageColor3 = Theme.Accent
    List.CanvasSize = UDim2.new()
    List.Parent = box
    corner(List,10)
    padding(List,6,6,6,6)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,6)
    layout.Parent = List
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        List.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+12)
    end)

    local customESP = setmetatable({}, {__mode="k"})

    local function clear()
        for _,c in ipairs(List:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function makeSmall(parent,labelText,x,w)
        local b=Instance.new("TextButton")
        b.Size=UDim2.fromOffset(w,26)
        b.Position=UDim2.new(1,x,0.5,-13)
        b.BackgroundColor3=Theme.Surface3
        b.BorderSizePixel=0
        b.Text=labelText
        b.TextColor3=Theme.Muted
        b.TextSize=7
        b.Font=Enum.Font.GothamBold
        b.AutoButtonColor=false
        b.Parent=parent
        corner(b,7)
        return b
    end

    refreshBrowser = function()
        clear()
        local q=Search.Text:lower()
        local count=0
        for _,egg in ipairs(eggList()) do
            if q=="" or egg.Name:lower():find(q,1,true) then
                count+=1
                local item=Instance.new("Frame")
                item.Size=UDim2.new(1,-2,0,44)
                item.BackgroundColor3=Theme.Surface2
                item.BorderSizePixel=0
                item.Parent=List
                corner(item,9)

                local nm=text(item,egg.Name,9,Theme.Text,Enum.Font.GothamMedium)
                nm.Position=UDim2.fromOffset(10,5)
                nm.Size=UDim2.new(1,-175,0,17)
                nm.TextTruncate=Enum.TextTruncate.AtEnd

                local sub=text(item,"RenderedEgg",7,Theme.Dim,Enum.Font.Gotham)
                sub.Position=UDim2.fromOffset(10,23)
                sub.Size=UDim2.new(1,-175,0,12)

                local target=makeSmall(item,"ALVO",-154,48)
                local tpbtn=makeSmall(item,"TP",-96,35)
                local espbtn=makeSmall(item,"◉",-51,35)

                local function paintTarget()
                    local on=targetIsSelected(egg.Name)
                    target.Text=on and "✓" or "ALVO"
                    tween(target,{
                        BackgroundColor3=on and Theme.Accent or Theme.Surface3,
                        TextColor3=on and Theme.Text or Theme.Muted
                    })
                end
                local function paintESP()
                    local on=customESP[egg]==true
                    tween(espbtn,{
                        BackgroundColor3=on and Color3.fromRGB(38,105,77) or Theme.Surface3,
                        TextColor3=on and Theme.Success or Theme.Muted
                    })
                end

                target.MouseButton1Click:Connect(function()
                    setTarget(egg.Name,not targetIsSelected(egg.Name))
                    updateHighlight(egg,customESP[egg])
                    paintTarget()
                    if refreshTrackUI then refreshTrackUI() end
                end)
                tpbtn.MouseButton1Click:Connect(function() teleportTo(egg) end)
                espbtn.MouseButton1Click:Connect(function()
                    customESP[egg]=not customESP[egg]
                    updateHighlight(egg,customESP[egg])
                    paintESP()
                end)

                paintTarget()
                paintESP()
            end
        end

        if count==0 then
            local empty=Instance.new("Frame")
            empty.Size=UDim2.new(1,-2,0,44)
            empty.BackgroundTransparency=1
            empty.Parent=List
            local l=text(empty,"Nenhum egg encontrado.",9,Theme.Muted,Enum.Font.GothamMedium)
            l.Size=UDim2.fromScale(1,1)
            l.TextXAlignment=Enum.TextXAlignment.Center
        end
    end

    Search:GetPropertyChangedSignal("Text"):Connect(refreshBrowser)
    Refresh.MouseButton1Click:Connect(function()
        tween(Refresh,{Rotation=Refresh.Rotation+180},.2)
        refreshBrowser()
    end)
    refreshBrowser()
end

-- EGG TRACK
do
    local targetsCard = card(Tracker,"Egg Track","Selecione ALVO no Egg Browser ou adicione manualmente.")

    local Manual = Instance.new("TextBox")
    Manual.Size = UDim2.new(1,-100,0,34)
    Manual.BackgroundColor3 = Theme.Surface2
    Manual.BorderSizePixel = 0
    Manual.PlaceholderText = "Ex.: Cherub Egg"
    Manual.PlaceholderColor3 = Theme.Dim
    Manual.Text = ""
    Manual.TextColor3 = Theme.Text
    Manual.TextSize = 9
    Manual.Font = Enum.Font.Gotham
    Manual.TextXAlignment = Enum.TextXAlignment.Left
    Manual.ClearTextOnFocus = false
    Manual.Parent = targetsCard
    corner(Manual,9)
    padding(Manual,10,8,0,0)

    local Add = Instance.new("TextButton")
    Add.Size = UDim2.fromOffset(90,34)
    Add.Position = UDim2.new(1,-90,0,0)
    Add.BackgroundColor3 = Theme.Accent
    Add.BorderSizePixel = 0
    Add.Text = "ADICIONAR"
    Add.TextColor3 = Theme.Text
    Add.TextSize = 8
    Add.Font = Enum.Font.GothamBold
    Add.Parent = Manual.Parent
    corner(Add,9)

    local targetList = Instance.new("Frame")
    targetList.Size = UDim2.new(1,0,0,0)
    targetList.AutomaticSize = Enum.AutomaticSize.Y
    targetList.BackgroundTransparency = 1
    targetList.Parent = targetsCard
    local tl = Instance.new("UIListLayout")
    tl.Padding=UDim.new(0,6)
    tl.Parent=targetList

    local status=Instance.new("Frame")
    status.Size=UDim2.new(1,0,0,50)
    status.BackgroundColor3=Theme.Surface2
    status.BorderSizePixel=0
    status.Parent=targetsCard
    corner(status,9)
    local statusTitle=text(status,"TRACK: aguardando alvo",9,Theme.Text,Enum.Font.GothamSemibold)
    statusTitle.Position=UDim2.fromOffset(10,6)
    statusTitle.Size=UDim2.new(1,-20,0,16)
    local statusSub=text(status,"Adicione um alvo ou marque ALVO no Egg Browser.",8,Theme.Muted,Enum.Font.Gotham)
    statusSub.Position=UDim2.fromOffset(10,25)
    statusSub.Size=UDim2.new(1,-20,0,16)

    refreshTrackUI = function()
        for _,c in ipairs(targetList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local n=0
        local names={}
        for _,display in pairs(State.targets) do names[#names+1]=display end
        table.sort(names)
        for _,name in ipairs(names) do
            n+=1
            local r=Instance.new("Frame")
            r.Size=UDim2.new(1,0,0,38)
            r.BackgroundColor3=Theme.Surface2
            r.BorderSizePixel=0
            r.Parent=targetList
            corner(r,9)
            local nm=text(r,name,9,Theme.Text,Enum.Font.GothamMedium)
            nm.Position=UDim2.fromOffset(10,0); nm.Size=UDim2.new(1,-85,1,0)
            local del=Instance.new("TextButton")
            del.Size=UDim2.fromOffset(62,24)
            del.Position=UDim2.new(1,-70,.5,-12)
            del.BackgroundColor3=Theme.Surface3
            del.BorderSizePixel=0
            del.Text="REMOVER"
            del.TextColor3=Theme.Danger
            del.TextSize=7
            del.Font=Enum.Font.GothamBold
            del.Parent=r
            corner(del,7)
            del.MouseButton1Click:Connect(function()
                setTarget(name,false)
                refreshTrackUI()
                refreshHighlights()
                if refreshBrowser then refreshBrowser() end
            end)
        end
        if n==0 then
            local e=Instance.new("Frame")
            e.Size=UDim2.new(1,0,0,38)
            e.BackgroundTransparency=1
            e.Parent=targetList
            local l=text(e,"Nenhum alvo selecionado.",9,Theme.Muted,Enum.Font.Gotham)
            l.Size=UDim2.fromScale(1,1)
            l.TextXAlignment=Enum.TextXAlignment.Center
            statusTitle.Text="TRACK: nenhum alvo"
            statusTitle.TextColor3=Theme.Text
            statusSub.Text="Adicione um alvo ou marque ALVO no Egg Browser."
        else
            local found=wantedEgg()
            if found then
                statusTitle.Text="ENCONTRADO: "..found.Name
                statusTitle.TextColor3=Theme.Success
                statusSub.Text="O alvo está disponível neste servidor."
            else
                statusTitle.Text="PROCURANDO • "..tostring(n).." alvo(s)"
                statusTitle.TextColor3=Theme.Warning
                statusSub.Text="Nenhum alvo selecionado apareceu neste servidor ainda."
            end
        end
    end

    local function addManual()
        local raw=tostring(Manual.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        if raw=="" then return end
        setTarget(raw,true)
        Manual.Text=""
        refreshTrackUI()
        refreshHighlights()
        if refreshBrowser then refreshBrowser() end
    end
    Add.MouseButton1Click:Connect(addManual)
    Manual.FocusLost:Connect(function(enter) if enter then addManual() end end)

    action(targetsCard,"COLETAR ALVO DISPONÍVEL","Dá TP perto do alvo, espera confirmar e volta voando mais devagar.",function()
        local e=wantedEgg()
        if e then
            local worked, reason=safeCollect(e)
            if worked then
                UI:Notify("Egg Track","Coleta segura concluída em "..e.Name)
            else
                UI:Notify("Egg Track","Falhou: "..tostring(reason))
            end
        else
            UI:Notify("Egg Track","Nenhum alvo selecionado está neste servidor.")
        end
    end)
    action(targetsCard,"LIMPAR ALVOS","Remove todos os targets selecionados.",function()
        table.clear(State.targets)
        saveTrackConfig()
        refreshTrackUI()
        refreshHighlights()
        if refreshBrowser then refreshBrowser() end
    end)

    refreshTrackUI()

    task.spawn(function()
        while targetsCard and targetsCard.Parent do
            task.wait(.75)
            if refreshTrackUI then refreshTrackUI() end
        end
    end)
end

-- SERVER HOP
do
    local serverCard = card(Servers,"Server Hop","Troca de servidor manualmente ou procurando seus alvos.")

    action(serverCard,"SERVER HOP","Entrar em outro servidor público com vaga.",function()
        UI:Notify("Server Hop","Procurando servidor...")
        if not hopServer() then UI:Notify("Server Hop","Nenhum servidor encontrado.") end
    end)

    toggle(serverCard,"Auto Hop por alvo","Procura até encontrar um dos eggs marcados como ALVO.",State.autoHop,function(v)
        State.autoHop=v
        saveTrackConfig()
        autoHopToken+=1
        if v then startAutoHop() end
    end)

    action(serverCard,"VERIFICAR / COLETAR ALVO","Se encontrar um alvo, coleta, espera confirmar e volta voando devagar.",function()
        local e=wantedEgg()
        if e then
            UI:Notify("Egg Track","Encontrado: "..e.Name)
            local worked, reason=safeCollect(e)
            if worked then
                UI:Notify("Egg Track","Coleta segura concluída.")
            else
                UI:Notify("Egg Track","Falhou: "..tostring(reason))
            end
        else
            UI:Notify("Egg Track","Nenhum alvo neste servidor.")
        end
    end)

    local note=card(Servers,"Como usar","1. Abra Egg Browser • 2. Marque ALVO • 3. Ative Auto Hop. Quando achar, o hub dá TP perto do egg, espera a coleta confirmar e só então volta voando.")
    local info=text(note,"Os alvos ficam salvos enquanto o ambiente do executor continuar ativo.",9,Theme.Muted,Enum.Font.Gotham)
    info.Size=UDim2.new(1,0,0,30)
    info.TextWrapped=true
end

UI:SelectTab("Dashboard")
refreshHighlights()

if State.antiGameplayPaused then
    startAntiGameplayPaused()
end

if Eggs then
    Eggs.ChildAdded:Connect(function(e)
        task.wait(.08)
        updateHighlight(e,false)
        if refreshBrowser then refreshBrowser() end
        if refreshTrackUI then refreshTrackUI() end
    end)
    Eggs.ChildRemoved:Connect(function(e)
        if highlights[e] then pcall(function() highlights[e]:Destroy() end); highlights[e]=nil end
        if refreshBrowser then refreshBrowser() end
        if refreshTrackUI then refreshTrackUI() end
    end)
end

-- Se o Auto Hop estava salvo antes do teleport, retoma automaticamente.
if State.autoHop and next(State.targets)~=nil then
    task.delay(1.2,function()
        startAutoHop()
    end)
end

print("[ZYRO HUB] Ride A Pet v4.8 SLOW RETURN carregado")
