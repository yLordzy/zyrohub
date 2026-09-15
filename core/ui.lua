-- ZYRO HUB CORE UI v1.2 • REAL TABS + SLIDER
local UI = {}
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

local parent = CoreGui
pcall(function() if gethui then parent = gethui() end end)
for _,n in ipairs({"ZyroHubLoaderUI","ZyroHubMobileDock"}) do
    local old=parent:FindFirstChild(n); if old then old:Destroy() end
end

local sg=Instance.new("ScreenGui")
sg.Name="ZyroHubLoaderUI"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=parent
local main=Instance.new("Frame",sg)
main.Size=UDim2.fromOffset(720,470); main.Position=UDim2.new(.5,-360,.5,-235); main.BackgroundColor3=Color3.fromRGB(8,9,13); main.BorderSizePixel=0
Instance.new("UICorner",main).CornerRadius=UDim.new(0,18)
local stroke=Instance.new("UIStroke",main); stroke.Color=Color3.fromRGB(90,105,255); stroke.Thickness=1

local top=Instance.new("Frame",main); top.Size=UDim2.new(1,0,0,62); top.BackgroundTransparency=1
local title=Instance.new("TextLabel",top); title.Size=UDim2.new(1,-120,1,0); title.Position=UDim2.fromOffset(22,0); title.BackgroundTransparency=1
title.Text="ZYRO HUB"; title.TextXAlignment=Enum.TextXAlignment.Left; title.Font=Enum.Font.GothamBold; title.TextSize=20; title.TextColor3=Color3.new(1,1,1)
local close=Instance.new("TextButton",top); close.Size=UDim2.fromOffset(38,38); close.Position=UDim2.new(1,-50,.5,-19); close.Text="×"; close.Font=Enum.Font.GothamBold; close.TextSize=20
close.TextColor3=Color3.fromRGB(255,90,110); close.BackgroundColor3=Color3.fromRGB(22,23,31); close.BorderSizePixel=0; Instance.new("UICorner",close).CornerRadius=UDim.new(0,10)
close.MouseButton1Click:Connect(function() main.Visible=false end)

local side=Instance.new("Frame",main); side.Position=UDim2.fromOffset(14,72); side.Size=UDim2.fromOffset(165,382); side.BackgroundColor3=Color3.fromRGB(13,14,20); side.BorderSizePixel=0
Instance.new("UICorner",side).CornerRadius=UDim.new(0,14)
local sl=Instance.new("UIListLayout",side); sl.Padding=UDim.new(0,8); sl.HorizontalAlignment=Enum.HorizontalAlignment.Center
local sp=Instance.new("UIPadding",side); sp.PaddingTop=UDim.new(0,12); sp.PaddingLeft=UDim.new(0,10); sp.PaddingRight=UDim.new(0,10)

local host=Instance.new("Frame",main); host.Position=UDim2.fromOffset(193,72); host.Size=UDim2.new(1,-207,1,-86); host.BackgroundTransparency=1
local tabs={}; local current=nil; local defaultPage=nil; local hasRealTabs=false

local function makePage(name)
    local page=Instance.new("ScrollingFrame",host); page.Name=name; page.Size=UDim2.fromScale(1,1); page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=3; page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(); page.Visible=false
    local l=Instance.new("UIListLayout",page); l.Padding=UDim.new(0,10)
    local p=Instance.new("UIPadding",page); p.PaddingRight=UDim.new(0,8); p.PaddingBottom=UDim.new(0,10)
    return page
end
local function ensureDefault()
    if not defaultPage then defaultPage=makePage("Default"); defaultPage.Visible=true end
    if not current then current=defaultPage end
    return current
end
local function switchTab(tab)
    for _,t in pairs(tabs) do
        t.page.Visible=false
        t.button.BackgroundColor3=Color3.fromRGB(18,19,27)
        t.button.TextColor3=Color3.fromRGB(155,158,175)
    end
    if defaultPage then defaultPage.Visible=false end
    tab.page.Visible=true; tab.button.BackgroundColor3=Color3.fromRGB(31,34,54); tab.button.TextColor3=Color3.new(1,1,1); current=tab.page
end

function UI:SetGame(name, subtitle)
    title.Text=tostring(name):upper(); self:Clear()
    if subtitle and subtitle~="" then self:Section(subtitle) end
end
function UI:Clear()
    for _,c in ipairs(host:GetChildren()) do c:Destroy() end
    for _,c in ipairs(side:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end
    tabs={}; current=nil; defaultPage=nil; hasRealTabs=false
end
function UI:PromoteDefaultToTab(name)
    if hasRealTabs or not defaultPage then return false end
    hasRealTabs=true
    local b=Instance.new("TextButton",side)
    b.Size=UDim2.new(1,0,0,42)
    b.BackgroundColor3=Color3.fromRGB(18,19,27)
    b.BorderSizePixel=0
    b.Text="  "..name
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.Font=Enum.Font.GothamMedium
    b.TextSize=13
    b.TextColor3=Color3.fromRGB(155,158,175)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
    local tab={page=defaultPage,button=b}
    tabs[name]=tab
    b.MouseButton1Click:Connect(function() switchTab(tab) end)
    defaultPage=nil
    switchTab(tab)
    return true
end
function UI:Tab(name)
    if not hasRealTabs then
        hasRealTabs=true
        if defaultPage then defaultPage:Destroy(); defaultPage=nil; current=nil end
    end
    local page=makePage(name)
    local b=Instance.new("TextButton",side); b.Size=UDim2.new(1,0,0,42); b.BackgroundColor3=Color3.fromRGB(18,19,27); b.BorderSizePixel=0
    b.Text="  "..name; b.TextXAlignment=Enum.TextXAlignment.Left; b.Font=Enum.Font.GothamMedium; b.TextSize=13; b.TextColor3=Color3.fromRGB(155,158,175)
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
    local tab={page=page,button=b}; tabs[name]=tab; b.MouseButton1Click:Connect(function() switchTab(tab) end)
    if not current then switchTab(tab) end
    current=page
    return tab
end
function UI:SelectTab(name) if tabs[name] then switchTab(tabs[name]) end end
function UI:GetTabPage(name) return tabs[name] and tabs[name].page or nil end
function UI:UseTab(name) if tabs[name] then current=tabs[name].page end end
function UI:Section(text)
    local p=ensureDefault(); local l=Instance.new("TextLabel",p); l.Size=UDim2.new(1,0,0,30); l.BackgroundTransparency=1
    l.Text=text; l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.GothamBold; l.TextSize=14; l.TextColor3=Color3.fromRGB(180,190,255); return l
end
function UI:Button(text,desc,cb)
    local p=ensureDefault(); local b=Instance.new("TextButton",p); b.Size=UDim2.new(1,0,0,62); b.BackgroundColor3=Color3.fromRGB(18,19,27); b.BorderSizePixel=0; b.Text=""
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
    local a=Instance.new("TextLabel",b); a.BackgroundTransparency=1; a.Position=UDim2.fromOffset(14,8); a.Size=UDim2.new(1,-28,0,22); a.Text=text; a.TextXAlignment=Enum.TextXAlignment.Left; a.Font=Enum.Font.GothamMedium; a.TextSize=13; a.TextColor3=Color3.new(1,1,1)
    local d=Instance.new("TextLabel",b); d.BackgroundTransparency=1; d.Position=UDim2.fromOffset(14,31); d.Size=UDim2.new(1,-28,0,18); d.Text=desc or ""; d.TextXAlignment=Enum.TextXAlignment.Left; d.Font=Enum.Font.Gotham; d.TextSize=10; d.TextColor3=Color3.fromRGB(120,124,140)
    b.MouseButton1Click:Connect(function() task.spawn(cb) end); return b
end
function UI:Toggle(text,desc,default,cb)
    local state=default==true; local paint
    local b=self:Button(text,desc,function() state=not state; paint(); cb(state) end)
    local dot=Instance.new("Frame",b); dot.Size=UDim2.fromOffset(34,20); dot.Position=UDim2.new(1,-48,.5,-10); dot.BorderSizePixel=0; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",dot); knob.Size=UDim2.fromOffset(16,16); knob.Position=UDim2.fromOffset(2,2); knob.BorderSizePixel=0; knob.BackgroundColor3=Color3.new(1,1,1); Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    paint=function() dot.BackgroundColor3=state and Color3.fromRGB(82,96,255) or Color3.fromRGB(45,47,58); knob.Position=state and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2) end
    paint(); return function(v) state=v; paint(); cb(state) end
end
function UI:Slider(text,desc,minValue,maxValue,defaultValue,step,cb)
    local p=ensureDefault(); minValue=tonumber(minValue) or 0; maxValue=tonumber(maxValue) or 100; step=tonumber(step) or 1
    local value=math.clamp(tonumber(defaultValue) or minValue,minValue,maxValue)
    local holder=Instance.new("Frame",p); holder.Size=UDim2.new(1,0,0,88); holder.BackgroundColor3=Color3.fromRGB(18,19,27); holder.BorderSizePixel=0; Instance.new("UICorner",holder).CornerRadius=UDim.new(0,12)
    local name=Instance.new("TextLabel",holder); name.BackgroundTransparency=1; name.Position=UDim2.fromOffset(14,8); name.Size=UDim2.new(1,-110,0,20); name.Text=text; name.TextXAlignment=Enum.TextXAlignment.Left; name.Font=Enum.Font.GothamMedium; name.TextSize=13; name.TextColor3=Color3.new(1,1,1)
    local val=Instance.new("TextLabel",holder); val.BackgroundTransparency=1; val.Position=UDim2.new(1,-94,0,8); val.Size=UDim2.fromOffset(80,20); val.TextXAlignment=Enum.TextXAlignment.Right; val.Font=Enum.Font.GothamBold; val.TextSize=12; val.TextColor3=Color3.fromRGB(180,190,255)
    local d=Instance.new("TextLabel",holder); d.BackgroundTransparency=1; d.Position=UDim2.fromOffset(14,29); d.Size=UDim2.new(1,-28,0,16); d.Text=desc or ""; d.TextXAlignment=Enum.TextXAlignment.Left; d.Font=Enum.Font.Gotham; d.TextSize=10; d.TextColor3=Color3.fromRGB(120,124,140)
    local bar=Instance.new("Frame",holder); bar.Active=true; bar.Position=UDim2.fromOffset(14,60); bar.Size=UDim2.new(1,-28,0,8); bar.BackgroundColor3=Color3.fromRGB(45,47,58); bar.BorderSizePixel=0; Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame",bar); fill.BackgroundColor3=Color3.fromRGB(82,96,255); fill.BorderSizePixel=0; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",bar); knob.Active=true; knob.AnchorPoint=Vector2.new(.5,.5); knob.Size=UDim2.fromOffset(18,18); knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0; Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    local dragging=false
    local function round(v) return math.clamp(math.floor(((v-minValue)/step)+.5)*step+minValue,minValue,maxValue) end
    local function draw(call) local a=(value-minValue)/(maxValue-minValue); fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,.5,0); val.Text=("%+.0f ms"):format(value); if call and cb then cb(value) end end
    local function fromX(x) local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); value=round(minValue+(maxValue-minValue)*a); draw(true) end
    local function begin(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; fromX(i.Position.X) end end
    bar.InputBegan:Connect(begin); knob.InputBegan:Connect(begin)
    UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromX(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    draw(false); return function(v) value=round(tonumber(v) or value); draw(true) end
end
function UI:Show()
    if sg then sg.Enabled=true end
    if main then main.Visible=true end
end
function UI:Hide()
    if main then main.Visible=false end
end
function UI:SetVisible(v)
    if sg then sg.Enabled=true end
    if main then main.Visible=(v and true or false) end
end
function UI:Notify(t,m,k) print(("[ZyroHub] %s: %s"):format(tostring(t),tostring(m))) end

local dock=Instance.new("ScreenGui")
dock.Name="ZyroHubMobileDock"
dock.ResetOnSpawn=false
dock.IgnoreGuiInset=true
dock.DisplayOrder=999998
dock.Parent=parent

local brand=Instance.new("TextButton",dock)
brand.Name="ZyroHubBrand"
brand.AnchorPoint=Vector2.new(.5,0)
brand.Position=UDim2.new(.5,0,0,4)
brand.Size=UDim2.fromOffset(150,38)
brand.BackgroundColor3=Color3.fromRGB(14,15,22)
brand.BorderSizePixel=0
brand.AutoButtonColor=false
brand.Text=""
Instance.new("UICorner",brand).CornerRadius=UDim.new(0,11)

local bs=Instance.new("UIStroke",brand)
bs.Color=Color3.fromRGB(82,96,255)
bs.Transparency=.35
bs.Thickness=1

local home=Instance.new("TextLabel",brand)
home.BackgroundTransparency=1
home.Position=UDim2.fromOffset(10,0)
home.Size=UDim2.fromOffset(26,38)
home.Text="⌂"
home.Font=Enum.Font.GothamBold
home.TextSize=16
home.TextColor3=Color3.fromRGB(180,190,255)

local logo=Instance.new("TextLabel",brand)
logo.BackgroundTransparency=1
logo.Position=UDim2.fromOffset(39,0)
logo.Size=UDim2.new(1,-47,1,0)
logo.Text="ZYRO HUB"
logo.Font=Enum.Font.GothamBold
logo.TextSize=13
logo.TextXAlignment=Enum.TextXAlignment.Left
logo.TextColor3=Color3.new(1,1,1)

brand.MouseButton1Click:Connect(function()
    main.Visible=not main.Visible
end)

brand.MouseEnter:Connect(function()
    TweenService:Create(brand,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(22,23,32)}):Play()
end)
brand.MouseLeave:Connect(function()
    TweenService:Create(brand,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(14,15,22)}):Play()
end)

local dragging,start,p0
top.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; start=i.Position; p0=main.Position end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-start; main.Position=UDim2.new(p0.X.Scale,p0.X.Offset+d.X,p0.Y.Scale,p0.Y.Offset+d.Y) end end)
print("[ZYRO HUB] UI v1.7 TAB PRESERVE carregada")
return UI
