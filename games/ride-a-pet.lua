-- ZYRO HUB • RIDE A PET v4.0 • RICH GUI
-- Visual inspirado no hub antigo, reorganizado para o sistema modular atual.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

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
}

local State = env.ZyroRideState
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
    return tostring(name or ""):lower():gsub("[%s_%-]","")
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
    if enabled then State.targets[k] = name else State.targets[k] = nil end
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

local function interactTarget(target)
    if not target then return false end
    local fp = (type(fireproximityprompt)=="function" and fireproximityprompt)
        or env.fireproximityprompt
    local fired = false
    for _,d in ipairs(target:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            applyPrompt(d)
            if type(fp)=="function" then
                local ok = pcall(function() fp(d,0) end)
                fired = fired or ok
            end
        end
    end
    return fired
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
                teleportTo(e)
                task.wait(.25)
                if not interactTarget(e) then holdE(.3) end
                task.wait(.2)
                teleportHome()
                task.wait(.8)
            else
                task.wait(.4)
            end
        end
    end)
end

local function hopServer()
    local cursor = ""
    for _=1,5 do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s")
            :format(game.GameId, cursor ~= "" and "&cursor="..HttpService:UrlEncode(cursor) or "")
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok then return false end

        local data = HttpService:JSONDecode(body)
        for _,srv in ipairs(data.data or {}) do
            if srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 0) then
                TeleportService:TeleportToPlaceInstance(game.PlaceId,srv.id,LP)
                return true
            end
        end
        cursor = data.nextPageCursor or ""
        if cursor == "" then break end
    end
    return false
end

local function wantedEgg()
    for _,e in ipairs(eggList()) do
        for k in pairs(State.targets) do
            local n = normalize(e.Name)
            if n == k or n:find(k,1,true) then return e end
        end
    end
end

local function startAutoHop()
    autoHopToken += 1
    local token = autoHopToken
    task.spawn(function()
        while State.autoHop and token == autoHopToken do
            if next(State.targets) == nil then
                UI:Notify("Server Hop","Selecione ao menos um ALVO.")
                State.autoHop = false
                break
            end

            local found = wantedEgg()
            if found then
                UI:Notify("Egg Track","Alvo encontrado: "..found.Name)
                teleportTo(found)
                State.autoHop = false
                break
            end

            UI:Notify("Server Hop","Alvo não encontrado. Mudando de servidor...")
            if hopServer() then break end
            task.wait(10)
        end
    end)
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
    toggle(automation,"Auto Best Egg","Procura Cherub, coleta e volta para sua plot.",State.autoBest,function(v)
        State.autoBest=v
        autoBestToken+=1
        if v then startAutoBest() end
    end)

    local quick = card(Dashboard,"Ações rápidas","Atalhos úteis.")
    action(quick,"TP HOME","Voltar para sua plot.",function()
        if not teleportHome() then UI:Notify("Teleport","Sua plot não foi encontrada.") end
    end)
    action(quick,"IR PARA CHERUB","Teleporta para o primeiro Cherub encontrado.",function()
        local e=findCherub()
        if e then teleportTo(e) else UI:Notify("Ride A Pet","Nenhum Cherub encontrado.") end
    end)
end

-- EGG BROWSER
local refreshBrowser
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

    local function refreshTargets()
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
                refreshTargets()
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
        end
    end

    local function addManual()
        local raw=tostring(Manual.Text or ""):gsub("^%s+",""):gsub("%s+$","")
        if raw=="" then return end
        setTarget(raw,true)
        Manual.Text=""
        refreshTargets()
        refreshHighlights()
        if refreshBrowser then refreshBrowser() end
    end
    Add.MouseButton1Click:Connect(addManual)
    Manual.FocusLost:Connect(function(enter) if enter then addManual() end end)

    action(targetsCard,"IR PARA ALVO DISPONÍVEL","Procura um dos alvos selecionados neste servidor.",function()
        local e=wantedEgg()
        if e then teleportTo(e) else UI:Notify("Egg Track","Nenhum alvo selecionado está neste servidor.") end
    end)
    action(targetsCard,"LIMPAR ALVOS","Remove todos os targets selecionados.",function()
        table.clear(State.targets)
        refreshTargets()
        refreshHighlights()
        if refreshBrowser then refreshBrowser() end
    end)

    refreshTargets()
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
        autoHopToken+=1
        if v then startAutoHop() end
    end)

    action(serverCard,"VERIFICAR ALVO AGORA","Se encontrar um alvo neste servidor, teleporta até ele.",function()
        local e=wantedEgg()
        if e then
            UI:Notify("Egg Track","Encontrado: "..e.Name)
            teleportTo(e)
        else
            UI:Notify("Egg Track","Nenhum alvo neste servidor.")
        end
    end)

    local note=card(Servers,"Como usar","1. Abra Egg Browser • 2. Marque ALVO • 3. Venha em Server Hop • 4. Ative Auto Hop por alvo.")
    local info=text(note,"Os alvos ficam salvos enquanto o ambiente do executor continuar ativo.",9,Theme.Muted,Enum.Font.Gotham)
    info.Size=UDim2.new(1,0,0,30)
    info.TextWrapped=true
end

UI:SelectTab("Dashboard")
refreshHighlights()

if Eggs then
    Eggs.ChildAdded:Connect(function(e)
        task.wait(.08)
        updateHighlight(e,false)
        if refreshBrowser then refreshBrowser() end
    end)
    Eggs.ChildRemoved:Connect(function(e)
        if highlights[e] then pcall(function() highlights[e]:Destroy() end); highlights[e]=nil end
        if refreshBrowser then refreshBrowser() end
    end)
end

print("[ZYRO HUB] Ride A Pet v4.0 RICH GUI carregado")
