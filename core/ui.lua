-- ZYRO HUB CORE UI
local UI = {}
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local parent = CoreGui
pcall(function() if gethui then parent = gethui() end end)

for _,n in ipairs({"ZyroHubLoaderUI","ZyroHubMobileDock"}) do
    local old = parent:FindFirstChild(n)
    if old then old:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name="ZyroHubLoaderUI"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=parent

local main=Instance.new("Frame",sg)
main.Size=UDim2.fromOffset(720,470); main.Position=UDim2.new(.5,-360,.5,-235)
main.BackgroundColor3=Color3.fromRGB(8,9,13); main.BorderSizePixel=0
Instance.new("UICorner",main).CornerRadius=UDim.new(0,18)
local stroke=Instance.new("UIStroke",main); stroke.Color=Color3.fromRGB(90,105,255); stroke.Thickness=1

local top=Instance.new("Frame",main); top.Size=UDim2.new(1,0,0,62); top.BackgroundTransparency=1
local title=Instance.new("TextLabel",top); title.Size=UDim2.new(1,-120,1,0); title.Position=UDim2.fromOffset(22,0)
title.BackgroundTransparency=1; title.Text="ZYRO HUB"; title.TextXAlignment=Enum.TextXAlignment.Left
title.Font=Enum.Font.GothamBold; title.TextSize=20; title.TextColor3=Color3.new(1,1,1)

local close=Instance.new("TextButton",top); close.Size=UDim2.fromOffset(38,38); close.Position=UDim2.new(1,-50,.5,-19)
close.Text="×"; close.Font=Enum.Font.GothamBold; close.TextSize=20; close.TextColor3=Color3.fromRGB(255,90,110)
close.BackgroundColor3=Color3.fromRGB(22,23,31); close.BorderSizePixel=0; Instance.new("UICorner",close).CornerRadius=UDim.new(0,10)
close.MouseButton1Click:Connect(function() sg.Enabled=false end)

local side=Instance.new("Frame",main); side.Position=UDim2.fromOffset(14,72); side.Size=UDim2.fromOffset(165,382)
side.BackgroundColor3=Color3.fromRGB(13,14,20); side.BorderSizePixel=0; Instance.new("UICorner",side).CornerRadius=UDim.new(0,14)
local sl=Instance.new("UIListLayout",side); sl.Padding=UDim.new(0,8); sl.HorizontalAlignment=Enum.HorizontalAlignment.Center
local sp=Instance.new("UIPadding",side); sp.PaddingTop=UDim.new(0,12)

local content=Instance.new("ScrollingFrame",main); content.Position=UDim2.fromOffset(193,72); content.Size=UDim2.new(1,-207,1,-86)
content.BackgroundTransparency=1; content.BorderSizePixel=0; content.ScrollBarThickness=3
content.AutomaticCanvasSize=Enum.AutomaticSize.Y; content.CanvasSize=UDim2.new()
local cl=Instance.new("UIListLayout",content); cl.Padding=UDim.new(0,10)
local cp=Instance.new("UIPadding",content); cp.PaddingRight=UDim.new(0,8)

local pages={}
function UI:SetGame(name, subtitle)
    title.Text=name:upper()
    self:Clear()
    self:Section(subtitle or "Ferramentas")
end
function UI:Clear()
    for _,c in ipairs(content:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end
    for _,c in ipairs(side:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end
end
function UI:Section(text)
    local l=Instance.new("TextLabel",content); l.Size=UDim2.new(1,0,0,34); l.BackgroundTransparency=1
    l.Text=text; l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.GothamBold; l.TextSize=15; l.TextColor3=Color3.fromRGB(180,190,255)
    return l
end
function UI:Button(text, desc, cb)
    local b=Instance.new("TextButton",content); b.Size=UDim2.new(1,0,0,62); b.BackgroundColor3=Color3.fromRGB(18,19,27); b.BorderSizePixel=0
    b.Text=""; Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
    local a=Instance.new("TextLabel",b); a.BackgroundTransparency=1; a.Position=UDim2.fromOffset(14,8); a.Size=UDim2.new(1,-28,0,22)
    a.Text=text; a.TextXAlignment=Enum.TextXAlignment.Left; a.Font=Enum.Font.GothamMedium; a.TextSize=13; a.TextColor3=Color3.new(1,1,1)
    local d=Instance.new("TextLabel",b); d.BackgroundTransparency=1; d.Position=UDim2.fromOffset(14,31); d.Size=UDim2.new(1,-28,0,18)
    d.Text=desc or ""; d.TextXAlignment=Enum.TextXAlignment.Left; d.Font=Enum.Font.Gotham; d.TextSize=10; d.TextColor3=Color3.fromRGB(120,124,140)
    b.MouseButton1Click:Connect(function() task.spawn(cb) end); return b
end
function UI:Toggle(text, desc, default, cb)
    local state=default==true
    local b=self:Button(text,desc,function() state=not state; paint(); cb(state) end)
    local dot=Instance.new("Frame",b); dot.Size=UDim2.fromOffset(34,20); dot.Position=UDim2.new(1,-48,.5,-10); dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",dot); knob.Size=UDim2.fromOffset(16,16); knob.Position=UDim2.fromOffset(2,2); knob.BorderSizePixel=0
    knob.BackgroundColor3=Color3.new(1,1,1); Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
    function paint()
        dot.BackgroundColor3=state and Color3.fromRGB(82,96,255) or Color3.fromRGB(45,47,58)
        knob.Position=state and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2)
    end
    paint(); return function(v) state=v; paint(); cb(state) end
end
function UI:Notify(t,m,k)
    print(("[ZyroHub] %s: %s"):format(tostring(t),tostring(m)))
end

-- apoio mobile/topo
local dock=Instance.new("ScreenGui"); dock.Name="ZyroHubMobileDock"; dock.ResetOnSpawn=false; dock.IgnoreGuiInset=true; dock.Parent=parent
local df=Instance.new("Frame",dock); df.AnchorPoint=Vector2.new(.5,0); df.Position=UDim2.new(.5,0,0,4); df.Size=UDim2.fromOffset(220,38)
df.BackgroundColor3=Color3.fromRGB(14,15,22); df.BorderSizePixel=0; Instance.new("UICorner",df).CornerRadius=UDim.new(0,11)
local dl=Instance.new("UIListLayout",df); dl.FillDirection=Enum.FillDirection.Horizontal; dl.HorizontalAlignment=Enum.HorizontalAlignment.Center; dl.VerticalAlignment=Enum.VerticalAlignment.Center; dl.Padding=UDim.new(0,5)
for _,v in ipairs({{"⌂",function() sg.Enabled=true end},{"◆",function() main.Position=UDim2.new(.5,-360,.5,-235) end},{"T",function() end},{"—",function() sg.Enabled=not sg.Enabled end}}) do
    local b=Instance.new("TextButton",df); b.Size=UDim2.fromOffset(48,28); b.Text=v[1]; b.Font=Enum.Font.GothamBold; b.TextSize=12
    b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Color3.fromRGB(22,23,32); b.BorderSizePixel=0; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    b.MouseButton1Click:Connect(v[2])
end

-- drag
local dragging,start,p0
top.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; start=i.Position; p0=main.Position end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-start; main.Position=UDim2.new(p0.X.Scale,p0.X.Offset+d.X,p0.Y.Scale,p0.Y.Offset+d.Y) end end)

return UI
