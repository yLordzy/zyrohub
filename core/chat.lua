-- ZYRO HUB • SHARED CHAT
-- Recuperado do chat original do ZyroHub e adaptado ao core modular.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local UI = getgenv().ZyroUI
if not UI then error("[ZyroHub Chat] UI não carregada") end

local old = getgenv().ZyroChat
if old and old.Destroy then pcall(old.Destroy) end

local Chat = {}
local connections = {}
local messages = {}

local function disconnectAll()
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
end

local function setNativeChatVisible(v)
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, v)
    end)
end

local function sendMessage(text)
    if typeof(text)~="string" or text=="" then return false end

    local legacy = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local say = legacy and legacy:FindFirstChild("SayMessageRequest")
    if say and say:IsA("RemoteEvent") then
        local ok=pcall(function() say:FireServer(text,"All") end)
        if ok then return true end
    end

    local channel
    pcall(function()
        if TextChatService.ChatInputBarConfiguration then
            channel=TextChatService.ChatInputBarConfiguration.TargetTextChannel
        end
    end)
    if not channel then
        pcall(function()
            local channels=TextChatService:FindFirstChild("TextChannels")
            channel=channels and channels:FindFirstChild("RBXGeneral")
        end)
    end
    if channel then
        return pcall(function() channel:SendAsync(text) end)
    end
    return false
end

local function nameColor(plr)
    if plr and plr.TeamColor then return plr.TeamColor.Color end
    return Color3.fromRGB(235,238,255)
end

UI:Tab("Chat")
local page=UI:GetTabPage("Chat")
if not page then error("[ZyroHub Chat] página Chat não criada") end

local card=Instance.new("Frame",page)
card.Size=UDim2.new(1,0,0,345)
card.BackgroundColor3=Color3.fromRGB(18,19,27)
card.BorderSizePixel=0
Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)

local header=Instance.new("Frame",card)
header.Size=UDim2.new(1,0,0,48)
header.BackgroundColor3=Color3.fromRGB(22,23,32)
header.BorderSizePixel=0
Instance.new("UICorner",header).CornerRadius=UDim.new(0,14)

local title=Instance.new("TextLabel",header)
title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(12,6)
title.Size=UDim2.new(1,-24,0,18)
title.Text="Chat Global"
title.TextXAlignment=Enum.TextXAlignment.Left
title.Font=Enum.Font.GothamBold
title.TextSize=13
title.TextColor3=Color3.new(1,1,1)

local sub=Instance.new("TextLabel",header)
sub.BackgroundTransparency=1
sub.Position=UDim2.fromOffset(12,25)
sub.Size=UDim2.new(1,-24,0,15)
sub.Text="Chat do ZyroHub • mostra idade da conta"
sub.TextXAlignment=Enum.TextXAlignment.Left
sub.Font=Enum.Font.Gotham
sub.TextSize=9
sub.TextColor3=Color3.fromRGB(120,124,140)

local scroll=Instance.new("ScrollingFrame",card)
scroll.Position=UDim2.new(0,10,0,58)
scroll.Size=UDim2.new(1,-20,1,-112)
scroll.BackgroundColor3=Color3.fromRGB(13,15,22)
scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3
scroll.ScrollBarImageColor3=Color3.fromRGB(82,96,255)
scroll.CanvasSize=UDim2.new()
Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,11)

local pad=Instance.new("UIPadding",scroll)
pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8)
pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)

local layout=Instance.new("UIListLayout",scroll)
layout.Padding=UDim.new(0,6)
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
    task.defer(function()
        scroll.CanvasPosition=Vector2.new(0,math.max(0,layout.AbsoluteContentSize.Y-scroll.AbsoluteWindowSize.Y+18))
    end)
end)

local input=Instance.new("TextBox",card)
input.Position=UDim2.new(0,10,1,-44)
input.Size=UDim2.new(1,-64,0,34)
input.BackgroundColor3=Color3.fromRGB(22,23,32)
input.BorderSizePixel=0
input.PlaceholderText="Digite sua mensagem..."
input.PlaceholderColor3=Color3.fromRGB(90,94,110)
input.Text=""
input.TextColor3=Color3.new(1,1,1)
input.TextSize=11
input.Font=Enum.Font.Gotham
input.TextXAlignment=Enum.TextXAlignment.Left
input.ClearTextOnFocus=false
Instance.new("UICorner",input).CornerRadius=UDim.new(0,10)
local ip=Instance.new("UIPadding",input); ip.PaddingLeft=UDim.new(0,10)

local send=Instance.new("TextButton",card)
send.Position=UDim2.new(1,-46,1,-44)
send.Size=UDim2.fromOffset(36,34)
send.BackgroundColor3=Color3.fromRGB(82,96,255)
send.BorderSizePixel=0
send.Text="➤"
send.TextColor3=Color3.new(1,1,1)
send.TextSize=13
send.Font=Enum.Font.GothamBold
Instance.new("UICorner",send).CornerRadius=UDim.new(0,10)

local function addMessage(plr,msg,system)
    local container=Instance.new("Frame",scroll)
    container.Size=UDim2.new(1,0,0,0)
    container.AutomaticSize=Enum.AutomaticSize.Y
    container.BackgroundTransparency=1

    local bubble=Instance.new("Frame",container)
    bubble.Size=UDim2.new(1,0,0,0)
    bubble.AutomaticSize=Enum.AutomaticSize.Y
    bubble.BackgroundColor3=system and Color3.fromRGB(35,31,55) or Color3.fromRGB(22,23,32)
    bubble.BorderSizePixel=0
    Instance.new("UICorner",bubble).CornerRadius=UDim.new(0,9)
    local bp=Instance.new("UIPadding",bubble)
    bp.PaddingLeft=UDim.new(0,9); bp.PaddingRight=UDim.new(0,9)
    bp.PaddingTop=UDim.new(0,7); bp.PaddingBottom=UDim.new(0,7)
    local bl=Instance.new("UIListLayout",bubble); bl.Padding=UDim.new(0,3)

    local h=Instance.new("TextLabel",bubble)
    h.BackgroundTransparency=1; h.Size=UDim2.new(1,0,0,14)
    h.TextXAlignment=Enum.TextXAlignment.Left; h.Font=Enum.Font.GothamSemibold; h.TextSize=9
    if system then
        h.Text="SISTEMA"; h.TextColor3=Color3.fromRGB(255,211,88)
    else
        h.Text=("["..tostring(plr and plr.AccountAge or 0).."d]  "..tostring(plr and plr.Name or "Desconhecido"))
        h.TextColor3=nameColor(plr)
    end

    local body=Instance.new("TextLabel",bubble)
    body.BackgroundTransparency=1; body.Size=UDim2.new(1,0,0,0); body.AutomaticSize=Enum.AutomaticSize.Y
    body.Text=tostring(msg); body.TextColor3=Color3.fromRGB(235,238,255); body.TextSize=10
    body.Font=Enum.Font.Gotham; body.TextWrapped=true; body.TextXAlignment=Enum.TextXAlignment.Left
    body.TextYAlignment=Enum.TextYAlignment.Top

    table.insert(messages,container)
    while #messages>40 do
        local x=table.remove(messages,1)
        if x then x:Destroy() end
    end
end

local function trySend()
    local text=input.Text
    if text=="" then return end
    if sendMessage(text) then input.Text="" else addMessage(nil,"Não consegui enviar a mensagem pelo sistema de chat atual.",true) end
end
send.MouseButton1Click:Connect(trySend)
input.FocusLost:Connect(function(enter) if enter then trySend() end end)

local function setup()
    disconnectAll()

    local legacy=ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local filtered=legacy and legacy:FindFirstChild("OnMessageDoneFiltering")
    if filtered and filtered:IsA("RemoteEvent") then
        table.insert(connections,filtered.OnClientEvent:Connect(function(data)
            if typeof(data)=="table" and data.Message then
                addMessage(data.FromSpeaker and Players:FindFirstChild(tostring(data.FromSpeaker)),data.Message,false)
            end
        end))
        addMessage(nil,"Chat legado conectado.",true)
        return
    end

    local ok,conn=pcall(function()
        return TextChatService.MessageReceived:Connect(function(m)
            if not m then return end
            local plr
            if m.TextSource then pcall(function() plr=Players:GetPlayerByUserId(m.TextSource.UserId) end) end
            if m.Text then addMessage(plr,m.Text,false) end
        end)
    end)
    if ok and conn then
        table.insert(connections,conn)
        addMessage(nil,"TextChatService conectado.",true)
        return
    end

    local function hook(plr)
        local ok2,c=pcall(function()
            return plr.Chatted:Connect(function(msg) addMessage(plr,msg,false) end)
        end)
        if ok2 and c then table.insert(connections,c) end
    end
    for _,plr in ipairs(Players:GetPlayers()) do hook(plr) end
    table.insert(connections,Players.PlayerAdded:Connect(hook))
    addMessage(nil,"Fallback de chat conectado.",true)
end

function Chat.Destroy()
    disconnectAll()
end
function Chat.Reconnect()
    setup()
end
function Chat.ShowNative(v)
    setNativeChatVisible(v)
end

setup()
setNativeChatVisible(false)
addMessage(nil,"Hub iniciado. Seus dias de conta: "..tostring(LP.AccountAge),true)

getgenv().ZyroChat=Chat
print("[ZYRO HUB] Shared Chat v1.0 carregado")
return Chat
