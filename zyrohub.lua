-- LocalScript en StarterPlayerScripts o StarterGui
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

print("[ZYRO HUB v12.17 TONGUE ESCAPE] STARTING...")

local LocalPlayer = Players.LocalPlayer

-- UI Parent
local TargetParent = CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Folder objetivo
local RenderedEggsFolder = Workspace:WaitForChild("RenderedEggs", 10) or Workspace:FindFirstChild("RenderedEggs")

local RIDE_A_PET_PLACE_ID = 124216119978534
local TONGUE_ESCAPE_PLACE_ID = 122245938604556

local function isRideAPetGame()
    return game.PlaceId == RIDE_A_PET_PLACE_ID
end

local function isTongueEscapeGame()
    return game.PlaceId == TONGUE_ESCAPE_PLACE_ID
end

local IS_RIDE_A_PET = isRideAPetGame()
local IS_TONGUE_ESCAPE = isTongueEscapeGame()


-- Almacenamiento de Highlights y ESTADOS
local mainESPActive = false
local mainESPColor = Color3.fromRGB(255, 255, 0) -- Color predeterminado menú global (Amarillo)
local defaultCustomColor = Color3.fromRGB(0, 255, 0) -- Verde para selecciones individuales
local highlights = {} -- [Instancia] = { Highlight = Highlight, CustomColor = Color3|nil, CustomActive = boolean }
local currentSearchQuery = ""

-- Configuración de Keybind para TP Inicio
local tpKeybind = Enum.KeyCode.T -- Keybind por defecto (T)
local listeningForKey = false

-- Estado para Auto Best Egg
local autoBestEggActive = false
local autoBestEggThread = nil

--------------------------------------------------------------------------------
-- SISTEMA DE ESP
--------------------------------------------------------------------------------
local function updateEggESP(inst)
    if not inst or (not inst:IsA("Model") and not inst:IsA("BasePart")) then return end
    
    local data = highlights[inst]
    if not data then
        data = { Highlight = nil, CustomColor = nil, CustomActive = false }
        highlights[inst] = data
    end
    
    local shouldShow = false
    local colorToUse = mainESPColor
    
    if data.CustomActive then
        shouldShow = true
        colorToUse = data.CustomColor or defaultCustomColor
    elseif mainESPActive then
        shouldShow = true
        colorToUse = mainESPColor
    end
    
    if shouldShow then
        if not data.Highlight or not data.Highlight.Parent then
            local hl = Instance.new("Highlight")
            hl.Name = "EggESP_Highlight"
            hl.Adornee = inst
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.Parent = inst
            data.Highlight = hl
        end
        data.Highlight.FillColor = colorToUse
        data.Highlight.OutlineColor = colorToUse
        data.Highlight.Enabled = true
    else
        if data.Highlight then
            data.Highlight.Enabled = false
        end
    end
end

local function applyGlobalESP(state)
    mainESPActive = state
    if RenderedEggsFolder then
        for _, child in ipairs(RenderedEggsFolder:GetChildren()) do
            updateEggESP(child)
        end
    end
end

-- Conexiones dinámicas para nuevos objetos
if RenderedEggsFolder then
    RenderedEggsFolder.ChildAdded:Connect(function(child)
        task.wait(0.1)
        updateEggESP(child)
    end)

    RenderedEggsFolder.ChildRemoved:Connect(function(child)
        if highlights[child] then
            if highlights[child].Highlight then
                highlights[child].Highlight:Destroy()
            end
            highlights[child] = nil
        end
    end)
end

--------------------------------------------------------------------------------
-- FUNCIÓN DE TELEPORT
--------------------------------------------------------------------------------
local function teleportToModel(targetInst)
    if not targetInst then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetCFrame = nil
    
    if targetInst:IsA("Model") then
        targetCFrame = targetInst:GetPivot()
    elseif targetInst:IsA("BasePart") then
        targetCFrame = targetInst.CFrame
    end
    
    if targetCFrame then
        hrp.CFrame = targetCFrame * CFrame.new(0, 3, 0)
    end
end

-- Lógica para buscar y teleportar a la Parcela (Plot Owner)
local function teleportToHomePlot()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local dataFolder = plot:FindFirstChild("Data")
        if dataFolder then
            local ownerVal = dataFolder:FindFirstChild("Owner")
            if ownerVal then
                local isOwner = false
                if ownerVal:IsA("StringValue") and ownerVal.Value == LocalPlayer.Name then
                    isOwner = true
                elseif ownerVal:IsA("ObjectValue") and ownerVal.Value == LocalPlayer then
                    isOwner = true
                elseif tostring(ownerVal.Value) == LocalPlayer.Name then
                    isOwner = true
                end

                if isOwner then
                    teleportToModel(plot)
                    break
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- LÓGICA AUTO BEST EGG (CHERUB)
--------------------------------------------------------------------------------
local function holdEKey(duration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- INSTA INTERACT
-- Torna ProximityPrompts instantâneos enquanto ativado.
local instaInteractEnabled = true
local instaPromptConnections = setmetatable({}, {__mode = "k"})

local function applyInstaPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return
    end

    if instaInteractEnabled then
        pcall(function()
            prompt.HoldDuration = 0
        end)
    end

    if not instaPromptConnections[prompt] then
        instaPromptConnections[prompt] = prompt:GetPropertyChangedSignal("HoldDuration"):Connect(function()
            if instaInteractEnabled and prompt.Parent and prompt.HoldDuration ~= 0 then
                pcall(function()
                    prompt.HoldDuration = 0
                end)
            end
        end)
    end
end

local function refreshInstaInteract()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            applyInstaPrompt(obj)
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then
        task.defer(function()
            applyInstaPrompt(obj)
        end)
    end
end)

local function instantInteractTarget(target)
    if not target then
        return false
    end

    local env = (getgenv and getgenv()) or _G
    local firePrompt =
        (type(fireproximityprompt) == "function" and fireproximityprompt)
        or env.fireproximityprompt

    local fired = false

    for _, obj in ipairs(target:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            applyInstaPrompt(obj)

            if type(firePrompt) == "function" then
                local ok = pcall(function()
                    firePrompt(obj, 0)
                end)
                fired = fired or ok
            end
        end
    end

    return fired
end

task.defer(refreshInstaInteract)

local function startAutoBestEgg()
    if autoBestEggThread then task.cancel(autoBestEggThread) end

    autoBestEggThread = task.spawn(function()
        while autoBestEggActive do
            if RenderedEggsFolder then
                local targetCherubEgg = nil

                for _, egg in ipairs(RenderedEggsFolder:GetChildren()) do
                    if string.find(egg.Name:lower(), "cherub", 1, true) then
                        targetCherubEgg = egg
                        break
                    end
                end

                if targetCherubEgg and targetCherubEgg.Parent then
                    teleportToModel(targetCherubEgg)
                    task.wait(0.3)
                    
                    holdEKey(3)
                    task.wait(0.2)
                    
                    teleportToHomePlot()
                    task.wait(1)
                end
            end
            task.wait(0.5)
        end
    end)
end

--------------------------------------------------------------------------------
-- LORDZY HUB - MASTER HUB
-- Módulos atuais:
--   • Home
--   • Ride A Pet
--   • Chat Global
--   • Settings
--------------------------------------------------------------------------------

local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local HUB_NAME = "LordzyRideHub"

-- Atalhos globais do hub
local hubToggleKey = Enum.KeyCode.RightShift
local chatOpenKey = Enum.KeyCode.Slash
local listeningHubKey = false
local listeningChatKey = false

pcall(function()
    local old = TargetParent:FindFirstChild(HUB_NAME)
    if old then old:Destroy() end

    local oldController = TargetParent:FindFirstChild(HUB_NAME .. "_Controller")
    if oldController then oldController:Destroy() end
end)

--------------------------------------------------------------------------------
-- CHAT CORE
--------------------------------------------------------------------------------

local chatConnections = {}
local chatMessages = {}
local nativeChatDisabled = false

local function disconnectChatListeners()
    for _, connection in ipairs(chatConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(chatConnections)
end

local function setNativeChatVisible(visible)
    nativeChatDisabled = not visible
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, visible)
    end)
end

local function sendChatMessage(text)
    if typeof(text) ~= "string" or text == "" then
        return false
    end

    -- Chat legado
    local legacyFolder = ReplicatedStorage and ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local sayRequest = legacyFolder and legacyFolder:FindFirstChild("SayMessageRequest")

    if sayRequest and sayRequest:IsA("RemoteEvent") then
        local ok = pcall(function()
            sayRequest:FireServer(text, "All")
        end)

        if ok then
            return true
        end
    end

    -- TextChatService moderno
    local targetChannel = nil

    pcall(function()
        if TextChatService and TextChatService.ChatInputBarConfiguration then
            targetChannel = TextChatService.ChatInputBarConfiguration.TargetTextChannel
        end
    end)

    if not targetChannel then
        pcall(function()
            local channels = TextChatService and TextChatService:FindFirstChild("TextChannels")
            if channels then
                targetChannel = channels:FindFirstChild("RBXGeneral")
            end
        end)
    end

    if targetChannel then
        local ok = pcall(function()
            targetChannel:SendAsync(text)
        end)

        if ok then
            return true
        end
    end

    return false
end

local function getPlayerNameColor(player)
    if not player then
        return Color3.fromRGB(255, 211, 88)
    end

    if player.TeamColor then
        return player.TeamColor.Color
    end

    return Color3.fromRGB(235, 238, 255)
end

--------------------------------------------------------------------------------
-- GUI BASE
--------------------------------------------------------------------------------

local Theme = {
    -- Visual inspirado no HTML 2097 POP + TimerMo:
    -- carvão fosco, vidro escuro e vermelho carmesim.
    Bg = Color3.fromRGB(10, 8, 12),
    Surface = Color3.fromRGB(19, 15, 22),
    Surface2 = Color3.fromRGB(28, 20, 31),
    Surface3 = Color3.fromRGB(39, 25, 42),
    Stroke = Color3.fromRGB(91, 43, 58),

    Accent = Color3.fromRGB(220, 20, 60),
    Accent2 = Color3.fromRGB(255, 72, 96),
    AccentSoft = Color3.fromRGB(94, 24, 43),

    Text = Color3.fromRGB(239, 241, 239),
    Muted = Color3.fromRGB(163, 167, 164),
    Dim = Color3.fromRGB(112, 117, 113),

    Success = Color3.fromRGB(255, 66, 92),
    Warning = Color3.fromRGB(214, 188, 121),
    Danger = Color3.fromRGB(218, 111, 117)
}

local UIState = {
    animations = true,
    blur = true,
    compact = false,
    toasts = true,
}

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local requestHideHub = nil

local function tw(object, duration, props, style, direction)
    if not UIState.animations then
        for property, value in pairs(props) do
            pcall(function()
                object[property] = value
            end)
        end
        return nil
    end

    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local animation = TweenService:Create(object, tweenInfo, props)
    animation:Play()
    return animation
end

local function uiCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function uiStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function uiPadding(parent, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = parent
    return p
end

local function label(parent, text, size, color, font, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size or 12
    l.TextColor3 = color or Theme.Text
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeHover(button, normal, hover, pressed)
    button.MouseEnter:Connect(function()
        tw(button, 0.14, {BackgroundColor3 = hover or Theme.Surface3})
    end)

    button.MouseLeave:Connect(function()
        tw(button, 0.14, {BackgroundColor3 = normal})
    end)

    button.MouseButton1Down:Connect(function()
        tw(button, 0.08, {BackgroundColor3 = pressed or Theme.AccentSoft})
    end)

    button.MouseButton1Up:Connect(function()
        tw(button, 0.1, {BackgroundColor3 = hover or Theme.Surface3})
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HUB_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999998
ScreenGui.Parent = TargetParent

local ControllerGui = Instance.new("ScreenGui")
ControllerGui.Name = HUB_NAME .. "_Controller"
ControllerGui.ResetOnSpawn = false
ControllerGui.IgnoreGuiInset = true
ControllerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ControllerGui.DisplayOrder = 999999
ControllerGui.Parent = TargetParent


local HubBlur = Lighting:FindFirstChild("LordzyHubBlur")
if not HubBlur then
    HubBlur = Instance.new("BlurEffect")
    HubBlur.Name = "LordzyHubBlur"
    HubBlur.Size = 5
    HubBlur.Enabled = true
    HubBlur.Parent = Lighting
end

local ToastHolder = Instance.new("Frame")
ToastHolder.Name = "ToastHolder"
ToastHolder.AnchorPoint = Vector2.new(1, 0)
ToastHolder.Position = UDim2.new(1, -18, 0, 18)
ToastHolder.Size = UDim2.new(0, 270, 1, -36)
ToastHolder.BackgroundTransparency = 1
ToastHolder.Parent = ControllerGui

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ToastLayout.Padding = UDim.new(0, 8)
ToastLayout.Parent = ToastHolder

local function notify(titleText, bodyText, kind)
    if not UIState.toasts then return end

    local color = Theme.Accent
    if kind == "success" then color = Theme.Success end
    if kind == "warning" then color = Theme.Warning end
    if kind == "danger" then color = Theme.Danger end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 260, 0, 64)
    toast.BackgroundColor3 = Theme.Surface
    toast.BackgroundTransparency = 0.04
    toast.BorderSizePixel = 0
    toast.Parent = ToastHolder
    uiCorner(toast, 12)
    uiStroke(toast, color, 1, 0.35)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -16)
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Parent = toast
    uiCorner(bar, 99)

    local t = label(toast, titleText or "Lordzy Hub", 10, Theme.Text, Enum.Font.GothamBold)
    t.Position = UDim2.new(0, 22, 0, 10)
    t.Size = UDim2.new(1, -32, 0, 16)

    local b = label(toast, bodyText or "", 8, Theme.Muted, Enum.Font.Gotham)
    b.Position = UDim2.new(0, 22, 0, 31)
    b.Size = UDim2.new(1, -32, 0, 24)
    b.TextWrapped = true
    b.TextYAlignment = Enum.TextYAlignment.Top

    toast.Position = UDim2.new(0, 30, 0, 0)
    toast.BackgroundTransparency = 1
    tw(toast, 0.25, {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.04
    }, Enum.EasingStyle.Back)

    task.delay(3.2, function()
        if toast and toast.Parent then
            tw(toast, 0.2, {
                Position = UDim2.new(0, 30, 0, 0),
                BackgroundTransparency = 1
            })
            task.delay(0.22, function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end
    end)
end

local Shadow = Instance.new("Frame")
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.fromScale(0.5, 0.5)
Shadow.Size = UDim2.new(0, 884, 0, 594)
Shadow.BackgroundColor3 = Color3.new(0, 0, 0)
Shadow.BackgroundTransparency = 0.48
Shadow.BorderSizePixel = 0
Shadow.Parent = ScreenGui
uiCorner(Shadow, 22)

local Main = Instance.new("Frame")
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.new(0, 860, 0, 570)
Main.BackgroundColor3 = Color3.fromRGB(18, 19, 19)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.BackgroundTransparency = 0.04
Main.Parent = ScreenGui
uiCorner(Main, 22)
uiStroke(Main, Theme.Accent, 1.15, 0.24)

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(31, 16, 25)),
    ColorSequenceKeypoint.new(0.42, Color3.fromRGB(18, 13, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 9, 14))
})
MainGradient.Rotation = 18
MainGradient.Parent = Main

-- Ambient lighting inspired by the HTML/screenshot.
do
    local GlowLeft = Instance.new("Frame")
    GlowLeft.Name = "AmbientGlowLeft"
    GlowLeft.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowLeft.Position = UDim2.new(0.20, 0, 0.32, 0)
    GlowLeft.Size = UDim2.new(0, 420, 0, 420)
    GlowLeft.BackgroundColor3 = Color3.fromRGB(160, 18, 50)
    GlowLeft.BackgroundTransparency = 0.88
    GlowLeft.BorderSizePixel = 0
    GlowLeft.ZIndex = 0
    GlowLeft.Parent = Main
    uiCorner(GlowLeft, 999)

    local GlowRight = Instance.new("Frame")
    GlowRight.Name = "AmbientGlowRight"
    GlowRight.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowRight.Position = UDim2.new(0.82, 0, 0.76, 0)
    GlowRight.Size = UDim2.new(0, 360, 0, 360)
    GlowRight.BackgroundColor3 = Color3.fromRGB(115, 12, 34)
    GlowRight.BackgroundTransparency = 0.91
    GlowRight.BorderSizePixel = 0
    GlowRight.ZIndex = 0
    GlowRight.Parent = Main
    uiCorner(GlowRight, 999)
end

--------------------------------------------------------------------------------
-- SIDEBAR
--------------------------------------------------------------------------------

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 205, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 24, 30)
Sidebar.BackgroundTransparency = 0.10
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SideDivider = Instance.new("Frame")
SideDivider.Size = UDim2.new(0, 1, 1, 0)
SideDivider.Position = UDim2.new(1, -1, 0, 0)
SideDivider.BackgroundColor3 = Theme.Stroke
SideDivider.BackgroundTransparency = 0.45
SideDivider.BorderSizePixel = 0
SideDivider.Parent = Sidebar

local Logo = Instance.new("Frame")
Logo.Size = UDim2.new(0, 38, 0, 38)
Logo.Position = UDim2.new(0, 16, 0, 16)
Logo.BackgroundColor3 = Theme.AccentSoft
Logo.BorderSizePixel = 0
Logo.Parent = Sidebar
uiCorner(Logo, 11)

local LogoGradient = Instance.new("UIGradient")
LogoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 24, 52)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(76, 16, 31))
})
LogoGradient.Rotation = 35
LogoGradient.Parent = Logo

local LogoText = label(Logo, "L", 18, Theme.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
LogoText.Size = UDim2.fromScale(1, 1)

local HubTitle = label(Sidebar, "ZYRO HUB", 13, Theme.Text, Enum.Font.GothamBold)
HubTitle.Position = UDim2.new(0, 62, 0, 16)
HubTitle.Size = UDim2.new(1, -70, 0, 17)

local HubSub = label(Sidebar, "Automation Suite", 9, Theme.Muted, Enum.Font.Gotham)
HubSub.Position = UDim2.new(0, 62, 0, 37)
HubSub.Size = UDim2.new(1, -70, 0, 14)

local NavHolder = Instance.new("Frame")
NavHolder.BackgroundTransparency = 1
NavHolder.Position = UDim2.new(0, 14, 0, 88)
NavHolder.Size = UDim2.new(1, -28, 0, 280)
NavHolder.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 9)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavHolder

local BottomInfo = Instance.new("Frame")
BottomInfo.Size = UDim2.new(1, -20, 0, 72)
BottomInfo.Position = UDim2.new(0, 10, 1, -84)
BottomInfo.BackgroundColor3 = Theme.Surface
BottomInfo.BorderSizePixel = 0
BottomInfo.Parent = Sidebar
uiCorner(BottomInfo, 12)
uiStroke(BottomInfo, Theme.Stroke, 1, 0.5)

local InfoDot = Instance.new("Frame")
InfoDot.Size = UDim2.new(0, 8, 0, 8)
InfoDot.Position = UDim2.new(0, 10, 0, 13)
InfoDot.BackgroundColor3 = RenderedEggsFolder and Theme.Success or Theme.Warning
InfoDot.BorderSizePixel = 0
InfoDot.Parent = BottomInfo
uiCorner(InfoDot, 99)

local InfoTitle = label(
    BottomInfo,
    RenderedEggsFolder and "Ride A Pet detectado" or "Aguardando jogo",
    9,
    Theme.Text,
    Enum.Font.GothamMedium
)
InfoTitle.Position = UDim2.new(0, 25, 0, 9)
InfoTitle.Size = UDim2.new(1, -32, 0, 15)

local InfoUser = label(
    BottomInfo,
    LocalPlayer.Name .. " • " .. tostring(LocalPlayer.AccountAge) .. " dias",
    8,
    Theme.Muted,
    Enum.Font.Gotham
)
InfoUser.Position = UDim2.new(0, 10, 0, 33)
InfoUser.Size = UDim2.new(1, -20, 0, 14)

local InfoModules = label(BottomInfo, "ULTRA v8 • 3 módulos", 8, Theme.Dim, Enum.Font.Gotham)
InfoModules.Position = UDim2.new(0, 10, 0, 49)
InfoModules.Size = UDim2.new(1, -20, 0, 13)

--------------------------------------------------------------------------------
-- TOP CONTENT
--------------------------------------------------------------------------------

local TopBar = Instance.new("Frame")
TopBar.Position = UDim2.new(0, 205, 0, 0)
TopBar.Size = UDim2.new(1, -205, 0, 72)
TopBar.BackgroundTransparency = 1
TopBar.Active = true
TopBar.Parent = Main

local PageTitle = label(TopBar, "Home", 19, Theme.Text, Enum.Font.GothamBold)
PageTitle.Position = UDim2.new(0, 24, 0, 16)
PageTitle.Size = UDim2.new(1, -110, 0, 20)

local PageSub = label(TopBar, "Visão geral do hub", 9, Theme.Muted, Enum.Font.Gotham)
PageSub.Position = UDim2.new(0, 24, 0, 43)
PageSub.Size = UDim2.new(1, -110, 0, 14)

local DragHint = label(TopBar, "⋮⋮  ARRASTE AQUI", 8, Theme.Dim, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
DragHint.AnchorPoint = Vector2.new(0.5, 0.5)
DragHint.Position = UDim2.new(0.56, 0, 0.5, 0)
DragHint.Size = UDim2.new(0, 110, 0, 18)
DragHint.ZIndex = 21

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 34, 0, 34)
MinimizeBtn.Position = UDim2.new(1, -48, 0, 14)
MinimizeBtn.BackgroundColor3 = Theme.Surface2
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Theme.Text
MinimizeBtn.TextSize = 16
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = TopBar
uiCorner(MinimizeBtn, 10)
makeHover(MinimizeBtn, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)

MinimizeBtn.Position = UDim2.new(1, -90, 0, 19)

do
local HideBtn = Instance.new("TextButton")
HideBtn.Name = "HideBtn"
HideBtn.Size = UDim2.new(0, 34, 0, 34)
HideBtn.Position = UDim2.new(1, -48, 0, 19)
HideBtn.BackgroundColor3 = Theme.Surface2
HideBtn.BorderSizePixel = 0
HideBtn.Text = "×"
HideBtn.TextColor3 = Theme.Danger
HideBtn.TextSize = 17
HideBtn.Font = Enum.Font.GothamBold
HideBtn.AutoButtonColor = false
HideBtn.Parent = TopBar
uiCorner(HideBtn, 10)
makeHover(HideBtn, Theme.Surface2, Color3.fromRGB(54, 28, 36), Color3.fromRGB(74, 30, 42))

HideBtn.MouseButton1Click:Connect(function()
    if requestHideHub then
        requestHideHub()
    else
        Main.Visible = false
        Shadow.Visible = false
    end
end)

local StatusPill = Instance.new("Frame")
StatusPill.Name = "StatusPill"
StatusPill.AnchorPoint = Vector2.new(1, 0.5)
StatusPill.Position = UDim2.new(1, -130, 0.5, 0)
StatusPill.Size = UDim2.new(0, 88, 0, 24)
StatusPill.BackgroundColor3 = Color3.fromRGB(18, 38, 31)
StatusPill.BorderSizePixel = 0
StatusPill.Parent = TopBar
uiCorner(StatusPill, 99)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 7, 0, 7)
StatusDot.Position = UDim2.new(0, 9, 0.5, -3)
StatusDot.BackgroundColor3 = Theme.Success
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusPill
uiCorner(StatusDot, 99)

local StatusText = label(StatusPill, "ONLINE", 8, Theme.Success, Enum.Font.GothamBold)
StatusText.Position = UDim2.new(0, 22, 0, 0)
StatusText.Size = UDim2.new(1, -26, 1, 0)

end

local TopLine = Instance.new("Frame")
TopLine.Position = UDim2.new(0, 166, 0, 61)
TopLine.Size = UDim2.new(1, -166, 0, 1)
TopLine.BackgroundColor3 = Theme.Stroke
TopLine.BackgroundTransparency = 0.45
TopLine.BorderSizePixel = 0
TopLine.Parent = Main

--------------------------------------------------------------------------------
-- PAGES
--------------------------------------------------------------------------------

local ContentRoot = Instance.new("Frame")
ContentRoot.Position = UDim2.new(0, 205, 0, 72)
ContentRoot.Size = UDim2.new(1, -205, 1, -72)
ContentRoot.BackgroundTransparency = 1
ContentRoot.Parent = Main

local Pages = {}
local navButtons = {}
local activePage = nil

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentRoot
    uiPadding(page, 22, 22, 18, 22)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 14)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    Pages[name] = page
    return page
end

local HomePage = createPage("Home")
local RidePage = createPage("Ride")
local TonguePage = createPage("Tongue")
local ChatPage = createPage("Chat")
local SettingsPage = createPage("Settings")

local function makeNavButton(key, text, symbol, order)
    local button = Instance.new("TextButton")
    button.Name = key .. "Nav"
    button.Size = UDim2.new(1, 0, 0, 46)
    button.BackgroundColor3 = Color3.fromRGB(31, 31, 35)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.LayoutOrder = order
    button.Parent = NavHolder
    uiCorner(button, 14)

    local icon = label(button, symbol, 13, Theme.Muted, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
    icon.Size = UDim2.new(0, 34, 1, 0)
    icon.Position = UDim2.new(0, 8, 0, 0)

    local txt = label(button, text, 10, Theme.Muted, Enum.Font.GothamMedium)
    txt.Size = UDim2.new(1, -50, 1, 0)
    txt.Position = UDim2.new(0, 46, 0, 0)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 18)
    accent.Position = UDim2.new(0, 0, 0.5, -10)
    accent.BackgroundColor3 = Theme.Accent
    accent.BackgroundTransparency = 1
    accent.BorderSizePixel = 0
    accent.Parent = button
    uiCorner(accent, 99)

    navButtons[key] = {
        Button = button,
        Text = txt,
        Icon = icon,
        Accent = accent
    }

    return button
end

local HomeNav = makeNavButton("Home", "Home", "⌂", 1)
local RideNav = makeNavButton("Ride", "Ride A Pet", "◆", 2)
local TongueNav = makeNavButton("Tongue", "Tongue Escape", "◉", 3)
local ChatNav = makeNavButton("Chat", "Chat Global", "◈", 4)
local SettingsNav = makeNavButton("Settings", "Settings", "⚙", 5)

RideNav.Visible = IS_RIDE_A_PET
TongueNav.Visible = IS_TONGUE_ESCAPE

local function setPage(name, titleText, subtitleText)
    if activePage == name then return end
    activePage = name

    for pageName, page in pairs(Pages) do
        page.Visible = pageName == name
        page.CanvasPosition = Vector2.new(0, 0)
    end

    for key, data in pairs(navButtons) do
        local selected = key == name
        tw(data.Button, 0.16, {
            BackgroundColor3 = selected and Theme.Surface2 or Color3.fromRGB(31, 31, 35)
        })
        tw(data.Text, 0.16, {
            TextColor3 = selected and Theme.Text or Theme.Muted
        })
        tw(data.Icon, 0.16, {
            TextColor3 = selected and Theme.Accent2 or Theme.Muted
        })
        tw(data.Accent, 0.16, {
            BackgroundTransparency = selected and 0 or 1
        })
    end

    PageTitle.Text = titleText
    PageSub.Text = subtitleText
end

HomeNav.MouseButton1Click:Connect(function()
    setPage("Home", "Home", "Visão geral do hub")
end)

RideNav.MouseButton1Click:Connect(function()
    setPage("Ride", "Ride A Pet", "ESP, teleport e automações")
end)

TongueNav.MouseButton1Click:Connect(function()
    setPage("Tongue", "Tongue Escape", "Farm, Auto Tongue e Auto Rebirth")
end)

ChatNav.MouseButton1Click:Connect(function()
    setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
end)

SettingsNav.MouseButton1Click:Connect(function()
    setPage("Settings", "Settings", "Preferências do hub")
end)

for _, data in pairs(navButtons) do
    data.Button.MouseEnter:Connect(function()
        if activePage ~= data.Button.Name:gsub("Nav", "") then
            tw(data.Button, 0.14, {BackgroundColor3 = Theme.Surface})
        end
    end)

    data.Button.MouseLeave:Connect(function()
        local key = data.Button.Name:gsub("Nav", "")
        if activePage ~= key then
            tw(data.Button, 0.14, {BackgroundColor3 = Color3.fromRGB(14, 15, 22)})
        end
    end)
end

--------------------------------------------------------------------------------
-- UI HELPERS
--------------------------------------------------------------------------------

local function section(parent, titleText, subtitleText)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Theme.Surface
    card.BorderSizePixel = 0
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = parent
    uiCorner(card, 18)
    uiStroke(card, Theme.Stroke, 1, 0.72)
    uiPadding(card, 16, 16, 15, 16)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = card

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, subtitleText and 38 or 20)
    header.Parent = card

    local h1 = label(header, titleText, 12, Theme.Text, Enum.Font.GothamBold)
    h1.Size = UDim2.new(1, 0, 0, 17)

    if subtitleText then
        local h2 = label(header, subtitleText, 9, Theme.Muted, Enum.Font.Gotham)
        h2.Position = UDim2.new(0, 0, 0, 21)
        h2.Size = UDim2.new(1, 0, 0, 13)
    end

    return card
end

local function actionButton(parent, titleText, subtitleText, accentColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 54)
    btn.BackgroundColor3 = Theme.Surface2
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    uiCorner(btn, 14)
    uiStroke(btn, Theme.Stroke, 1, 0.55)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0, 26)
    bar.Position = UDim2.new(0, 10, 0.5, -13)
    bar.BackgroundColor3 = accentColor or Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = btn
    uiCorner(bar, 99)

    local title = label(btn, titleText, 11, Theme.Text, Enum.Font.GothamSemibold)
    title.Position = UDim2.new(0, 23, 0, 8)
    title.Size = UDim2.new(1, -34, 0, 16)

    local sub = label(btn, subtitleText or "", 8, Theme.Muted, Enum.Font.Gotham)
    sub.Position = UDim2.new(0, 23, 0, 27)
    sub.Size = UDim2.new(1, -34, 0, 13)

    makeHover(btn, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)
    return btn
end

local function toggleRow(parent, titleText, subtitleText, initial, callback)
    local state = initial and true or false

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 60)
    row.BackgroundColor3 = Theme.Surface2
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = parent
    uiCorner(row, 14)
    uiStroke(row, Theme.Stroke, 1, 0.55)

    local title = label(row, titleText, 11, Theme.Text, Enum.Font.GothamSemibold)
    title.Position = UDim2.new(0, 12, 0, 9)
    title.Size = UDim2.new(1, -72, 0, 16)

    local sub = label(row, subtitleText or "", 8, Theme.Muted, Enum.Font.Gotham)
    sub.Position = UDim2.new(0, 12, 0, 29)
    sub.Size = UDim2.new(1, -72, 0, 13)

    local switch = Instance.new("Frame")
    switch.Size = UDim2.new(0, 42, 0, 24)
    switch.Position = UDim2.new(1, -54, 0.5, -12)
    switch.BackgroundColor3 = Theme.Surface3
    switch.BorderSizePixel = 0
    switch.Parent = row
    uiCorner(switch, 99)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Theme.Muted
    knob.BorderSizePixel = 0
    knob.Parent = switch
    uiCorner(knob, 99)

    local function render(animated)
        local switchColor = state and Theme.Accent or Theme.Surface3
        local knobColor = state and Theme.Text or Theme.Muted
        local knobPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

        if animated then
            tw(switch, 0.18, {BackgroundColor3 = switchColor})
            tw(knob, 0.2, {
                Position = knobPos,
                BackgroundColor3 = knobColor
            }, Enum.EasingStyle.Back)
        else
            switch.BackgroundColor3 = switchColor
            knob.Position = knobPos
            knob.BackgroundColor3 = knobColor
        end
    end

    row.MouseEnter:Connect(function()
        tw(row, 0.14, {BackgroundColor3 = Theme.Surface3})
    end)

    row.MouseLeave:Connect(function()
        tw(row, 0.14, {BackgroundColor3 = Theme.Surface2})
    end)

    row.MouseButton1Click:Connect(function()
        state = not state
        render(true)
        if callback then callback(state) end
    end)

    render(false)

    return {
        Row = row,
        Set = function(value)
            state = value and true or false
            render(true)
        end,
        Get = function()
            return state
        end
    }
end

--------------------------------------------------------------------------------
-- HOME
--------------------------------------------------------------------------------

local Welcome = Instance.new("Frame")
Welcome.Size = UDim2.new(1, 0, 0, 112)
Welcome.BackgroundColor3 = Theme.Surface
Welcome.BorderSizePixel = 0
Welcome.Parent = HomePage
uiCorner(Welcome, 15)
uiStroke(Welcome, Theme.Stroke, 1, 0.45)

local WelcomeAccent = Instance.new("Frame")
WelcomeAccent.Size = UDim2.new(0, 5, 0, 62)
WelcomeAccent.Position = UDim2.new(0, 14, 0.5, -31)
WelcomeAccent.BackgroundColor3 = Theme.Accent
WelcomeAccent.BorderSizePixel = 0
WelcomeAccent.Parent = Welcome
uiCorner(WelcomeAccent, 99)

local WelcomeTitle = label(Welcome, "Bem-vindo ao Lordzy Hub", 16, Theme.Text, Enum.Font.GothamBold)
WelcomeTitle.Position = UDim2.new(0, 30, 0, 20)
WelcomeTitle.Size = UDim2.new(1, -45, 0, 21)

local WelcomeSub = label(
    Welcome,
    "Um único hub para juntar os scripts do Ride A Pet e os próximos módulos.",
    9,
    Theme.Muted,
    Enum.Font.Gotham
)
WelcomeSub.Position = UDim2.new(0, 30, 0, 46)
WelcomeSub.Size = UDim2.new(1, -45, 0, 30)
WelcomeSub.TextWrapped = true
WelcomeSub.TextYAlignment = Enum.TextYAlignment.Top

local WelcomeInfo = label(
    Welcome,
    "Conta: " .. tostring(LocalPlayer.AccountAge) .. " dias   •   Player: " .. LocalPlayer.Name,
    9,
    Theme.Accent2,
    Enum.Font.GothamMedium
)
WelcomeInfo.Position = UDim2.new(0, 30, 0, 82)
WelcomeInfo.Size = UDim2.new(1, -45, 0, 15)


do
local LiveStats = Instance.new("Frame")
LiveStats.Size = UDim2.new(1, 0, 0, 82)
LiveStats.BackgroundTransparency = 1
LiveStats.Parent = HomePage

local LiveStatsLayout = Instance.new("UIListLayout")
LiveStatsLayout.FillDirection = Enum.FillDirection.Horizontal
LiveStatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
LiveStatsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
LiveStatsLayout.Padding = UDim.new(0, 8)
LiveStatsLayout.Parent = LiveStats

local function makeStatCard(titleText, initialValue, accent)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.333, -6, 1, 0)
    card.BackgroundColor3 = Theme.Surface
    card.BorderSizePixel = 0
    card.Parent = LiveStats
    uiCorner(card, 13)
    uiStroke(card, Theme.Stroke, 1, 0.55)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 12, 0, 13)
    dot.BackgroundColor3 = accent
    dot.BorderSizePixel = 0
    dot.Parent = card
    uiCorner(dot, 99)

    local title = label(card, titleText, 8, Theme.Muted, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 27, 0, 9)
    title.Size = UDim2.new(1, -37, 0, 16)

    local value = label(card, initialValue, 16, Theme.Text, Enum.Font.GothamBold)
    value.Position = UDim2.new(0, 12, 0, 34)
    value.Size = UDim2.new(1, -24, 0, 24)

    return value
end

local EggCountValue = makeStatCard("EGGS", "0", Theme.Accent)
local SessionValue = makeStatCard("SESSÃO", "00:00", Theme.Accent2)
local FPSValue = makeStatCard("FPS", "--", Theme.Success)

local sessionStarted = os.clock()
local fpsCounter = 0
local fpsLast = os.clock()
local fpsValue = 0

RunService.RenderStepped:Connect(function()
    fpsCounter += 1
    local now = os.clock()
    if now - fpsLast >= 0.75 then
        fpsValue = math.floor(fpsCounter / (now - fpsLast) + 0.5)
        fpsCounter = 0
        fpsLast = now
        FPSValue.Text = tostring(fpsValue)

        local elapsed = math.floor(now - sessionStarted)
        SessionValue.Text = string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60)

        if RenderedEggsFolder then
            EggCountValue.Text = tostring(#RenderedEggsFolder:GetChildren())
        else
            EggCountValue.Text = "0"
        end
    end
end)

local QuickActions = section(HomePage, "Ações rápidas", "As funções que você mais usa")

local QuickGrid = Instance.new("Frame")
QuickGrid.Size = UDim2.new(1, 0, 0, 102)
QuickGrid.BackgroundTransparency = 1
QuickGrid.Parent = QuickActions

local QuickGridLayout = Instance.new("UIGridLayout")
QuickGridLayout.CellSize = UDim2.new(0.5, -4, 0, 47)
QuickGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
QuickGridLayout.Parent = QuickGrid

local QuickHome = actionButton(QuickGrid, "TP HOME", "Voltar para sua plot", Theme.Accent2)
QuickHome.Size = UDim2.new(0, 0, 0, 47)
QuickHome.MouseButton1Click:Connect(function()
    teleportToHomePlot()
    notify("Teleport", "Tentando voltar para sua plot.", "success")
end)

local QuickRide = actionButton(QuickGrid, "RIDE A PET", "Abrir automações", Theme.Accent)
QuickRide.Size = UDim2.new(0, 0, 0, 47)
QuickRide.MouseButton1Click:Connect(function()
    setPage("Ride", "Ride A Pet", "ESP, teleport e automações")
end)

local QuickChat = actionButton(QuickGrid, "CHAT", "Abrir e digitar", Theme.Success)
QuickChat.Size = UDim2.new(0, 0, 0, 47)
QuickChat.MouseButton1Click:Connect(function()
    setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
    task.delay(0.05, function()
        if ChatInput and ChatInput.Parent then ChatInput:CaptureFocus() end
    end)
end)

local QuickSettings = actionButton(QuickGrid, "SETTINGS", "Personalizar hub", Theme.Warning)
QuickSettings.Size = UDim2.new(0, 0, 0, 47)
QuickSettings.MouseButton1Click:Connect(function()
    setPage("Settings", "Settings", "Preferências do hub")
end)


end

local Modules = section(HomePage, "Módulos", "Tudo que já está dentro desse hub")

local ModuleRide = actionButton(
    Modules,
    "Ride A Pet",
    "ESP, Auto Best Egg, teleports e navegador de eggs.",
    Theme.Accent
)
ModuleRide.MouseButton1Click:Connect(function()
    setPage("Ride", "Ride A Pet", "ESP, teleport e automações")
end)

local ModuleChat = actionButton(
    Modules,
    "Chat Global",
    "Chat corrigido com dias da conta e envio pelo chat original.",
    Theme.Accent2
)
ModuleChat.MouseButton1Click:Connect(function()
    setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
end)


if not IS_RIDE_A_PET then
    ModuleRide.Visible = false
end


--------------------------------------------------------------------------------
-- POP STYLE HOME / LAUNCHER
--------------------------------------------------------------------------------

do
    -- Hide the old Home widgets; keep the page itself as the launcher canvas.
    for _, child in ipairs(HomePage:GetChildren()) do
        if child:IsA("GuiObject") then
            child.Visible = false
        end
    end

    HomePage.BackgroundTransparency = 1
    HomePage.CanvasSize = UDim2.new(0, 0, 0, 0)
    HomePage.ScrollBarThickness = 0

    local PopRoot = Instance.new("Frame")
    PopRoot.Name = "PopLauncher"
    PopRoot.Size = UDim2.fromScale(1, 1)
    PopRoot.BackgroundColor3 = Color3.fromRGB(8, 9, 13)
    PopRoot.BackgroundTransparency = 1
    PopRoot.Visible = true
    PopRoot.Parent = HomePage

    -- Ambient background blocks, inspired by the POP template without external assets.
    local GlowA = Instance.new("Frame")
    GlowA.Visible = false
    GlowA.Size = UDim2.new(0, 290, 0, 290)
    GlowA.Position = UDim2.new(0, -80, 0, -90)
    GlowA.BackgroundColor3 = Color3.fromRGB(53, 38, 86)
    GlowA.BackgroundTransparency = 0.58
    GlowA.BorderSizePixel = 0
    GlowA.Rotation = 24
    GlowA.Parent = PopRoot
    uiCorner(GlowA, 90)

    local GlowAGradient = Instance.new("UIGradient")
    GlowAGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1)
    })
    GlowAGradient.Rotation = 45
    GlowAGradient.Parent = GlowA

    local GlowB = Instance.new("Frame")
    GlowB.Visible = false
    GlowB.Size = UDim2.new(0, 360, 0, 260)
    GlowB.Position = UDim2.new(1, -250, 1, -160)
    GlowB.BackgroundColor3 = Color3.fromRGB(20, 91, 116)
    GlowB.BackgroundTransparency = 0.72
    GlowB.BorderSizePixel = 0
    GlowB.Rotation = -18
    GlowB.Parent = PopRoot
    uiCorner(GlowB, 90)

    local GlowBGradient = Instance.new("UIGradient")
    GlowBGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.28),
        NumberSequenceKeypoint.new(1, 1)
    })
    GlowBGradient.Rotation = 120
    GlowBGradient.Parent = GlowB

    local Brand = Instance.new("Frame")
    Brand.Name = "Brand"
    Brand.Size = UDim2.new(0.43, -10, 1, -28)
    Brand.Position = UDim2.new(0, 10, 0, 14)
    Brand.BackgroundTransparency = 1
    Brand.Parent = PopRoot

    local BrandTag = label(Brand, "LORDZY // HUB", 9, Theme.Accent2, Enum.Font.GothamBold)
    BrandTag.Position = UDim2.new(0, 4, 0.22, 0)
    BrandTag.Size = UDim2.new(1, -8, 0, 18)

    local BrandTitle = label(Brand, "RIDE\nHUB", 31, Theme.Text, Enum.Font.GothamBold)
    BrandTitle.Position = UDim2.new(0, 4, 0.29, 0)
    BrandTitle.Size = UDim2.new(1, -8, 0, 82)
    BrandTitle.TextWrapped = false
    BrandTitle.TextYAlignment = Enum.TextYAlignment.Top

    local Underline = Instance.new("Frame")
    Underline.Size = UDim2.new(0, 130, 0, 2)
    Underline.Position = UDim2.new(0, 4, 0.55, 0)
    Underline.BackgroundColor3 = Theme.Text
    Underline.BackgroundTransparency = 0.14
    Underline.BorderSizePixel = 0
    Underline.Parent = Brand

    local UnderlineAccent = Instance.new("Frame")
    UnderlineAccent.Size = UDim2.new(0, 42, 1, 0)
    UnderlineAccent.BackgroundColor3 = Theme.Accent2
    UnderlineAccent.BorderSizePixel = 0
    UnderlineAccent.Parent = Underline

    local BrandSub = label(
        Brand,
        "Um launcher compacto para automações, chat e ferramentas do Ride A Pet.",
        10,
        Theme.Muted,
        Enum.Font.Gotham
    )
    BrandSub.Position = UDim2.new(0, 4, 0.59, 0)
    BrandSub.Size = UDim2.new(0.9, 0, 0, 56)
    BrandSub.TextWrapped = true
    BrandSub.TextYAlignment = Enum.TextYAlignment.Top

    local BrandMeta = label(
        Brand,
        LocalPlayer.Name .. "  •  " .. tostring(LocalPlayer.AccountAge) .. " dias",
        8,
        Theme.Dim,
        Enum.Font.GothamMedium
    )
    BrandMeta.Position = UDim2.new(0, 4, 0.82, 0)
    BrandMeta.Size = UDim2.new(0.9, 0, 0, 18)

    local Tiles = Instance.new("Frame")
    Tiles.Name = "Tiles"
    Tiles.Size = UDim2.new(0.57, -18, 0, 334)
    Tiles.AnchorPoint = Vector2.new(1, 0.5)
    Tiles.Position = UDim2.new(1, -10, 0.5, 0)
    Tiles.BackgroundTransparency = 1
    Tiles.Parent = PopRoot

    local TileGrid = Instance.new("UIGridLayout")
    TileGrid.CellSize = UDim2.new(0.5, -7, 0.5, -7)
    TileGrid.CellPadding = UDim2.new(0, 14, 0, 14)
    TileGrid.FillDirectionMaxCells = 2
    TileGrid.SortOrder = Enum.SortOrder.LayoutOrder
    TileGrid.Parent = Tiles

    local function makePopTile(order, symbol, titleText, subText, accent, callback)
        local tile = Instance.new("TextButton")
        tile.Name = titleText:gsub("%s+", "") .. "Tile"
        tile:SetAttribute("ModuleTitle", titleText)
        tile.LayoutOrder = order
        tile.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
        tile.BackgroundTransparency = 0.06
        tile.BorderSizePixel = 0
        tile.Text = ""
        tile.AutoButtonColor = false
        tile.ClipsDescendants = true
        tile.Parent = Tiles
        uiCorner(tile, 2)

        local border = uiStroke(tile, Color3.fromRGB(228, 231, 240), 1, 0.22)

        local hoverFill = Instance.new("Frame")
        hoverFill.Size = UDim2.fromScale(1, 1)
        hoverFill.BackgroundColor3 = accent
        hoverFill.BackgroundTransparency = 1
        hoverFill.BorderSizePixel = 0
        hoverFill.ZIndex = 0
        hoverFill.Parent = tile

        local icon = label(tile, symbol, 28, Theme.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        icon.Position = UDim2.new(0, 0, 0.17, 0)
        icon.Size = UDim2.new(1, 0, 0, 42)
        icon.ZIndex = 2

        local title = label(tile, titleText, 11, Theme.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
        title.Position = UDim2.new(0, 8, 0.61, 0)
        title.Size = UDim2.new(1, -16, 0, 18)
        title.ZIndex = 2

        local sub = label(tile, subText, 7, Theme.Muted, Enum.Font.Gotham, Enum.TextXAlignment.Center)
        sub.Position = UDim2.new(0, 8, 0.76, 0)
        sub.Size = UDim2.new(1, -16, 0, 25)
        sub.TextWrapped = true
        sub.ZIndex = 2

        tile.MouseEnter:Connect(function()
            tw(tile, 0.18, {BackgroundTransparency = 0.02})
            tw(hoverFill, 0.18, {BackgroundTransparency = 0.86})
            tw(icon, 0.18, {TextColor3 = accent})
            tw(border, 0.18, {Transparency = 0.02})
        end)

        tile.MouseLeave:Connect(function()
            tw(tile, 0.18, {BackgroundTransparency = 0.16})
            tw(hoverFill, 0.18, {BackgroundTransparency = 1})
            tw(icon, 0.18, {TextColor3 = Theme.Text})
            tw(border, 0.18, {Transparency = 0.22})
        end)

        tile.MouseButton1Click:Connect(function()
            tw(tile, 0.08, {Size = UDim2.new(0.98, 0, 0.98, 0)})
            task.delay(0.08, function()
                if tile and tile.Parent then
                    tw(tile, 0.12, {Size = UDim2.new(1, 0, 1, 0)})
                end
            end)
            callback()
        end)

        return tile
    end

    makePopTile(
        1,
        "◆",
        "RIDE A PET",
        "ESP, Auto Best Egg e teleportes",
        Theme.Accent,
        function()
            setPage("Ride", "Ride A Pet", "ESP, teleport e automações")
        end
    )

    makePopTile(
        2,
        "◈",
        "CHAT",
        "Chat global customizado",
        Theme.Accent2,
        function()
            setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
        end
    )

    makePopTile(
        3,
        "⌂",
        "HOME TP",
        "Voltar rapidamente para sua plot",
        Theme.Success,
        function()
            teleportToHomePlot()
            notify("Teleport", "Tentando voltar para sua plot.", "success")
        end
    )

    makePopTile(
        4,
        "⚙",
        "SETTINGS",
        "Visual, atalhos e preferências",
        Theme.Warning,
        function()
            setPage("Settings", "Settings", "Preferências do hub")
        end
    )


    -- UNIVERSAL MODE:
    -- Outside Ride A Pet, keep only the universal modules.
    if not IS_RIDE_A_PET then
        for _, tile in ipairs(Tiles:GetChildren()) do
            if tile:IsA("TextButton") then
                local moduleTitle = tile:GetAttribute("ModuleTitle")

                if moduleTitle == "RIDE A PET" or moduleTitle == "HOME TP" then
                    tile.Visible = false
                end
            end
        end

        local grid = Tiles:FindFirstChildOfClass("UIGridLayout")
        if grid then
            -- Two clean universal cards: Chat + Settings.
            grid.CellSize = UDim2.new(0.5, -7, 1, 0)
            grid.CellPadding = UDim2.new(0, 14, 0, 0)
        end

        BrandTitle.Text = "UNIVERSAL\nHUB"
        BrandSub.Text = "Chat universal e ferramentas do Lordzy Hub."
    end

    -- Decorative corner text, like a designed landing page.
    local FooterMark = label(
        PopRoot,
        "POP MODE  /  v12.3.1",
        7,
        Theme.Dim,
        Enum.Font.GothamBold,
        Enum.TextXAlignment.Right
    )
    FooterMark.Name = "FooterMark"
    FooterMark.Visible = false
    FooterMark.AnchorPoint = Vector2.new(1, 1)
    FooterMark.Position = UDim2.new(1, -12, 1, -8)
    FooterMark.Size = UDim2.new(0, 180, 0, 14)
end


--------------------------------------------------------------------------------
-- TONGUE ESCAPE PAGE
--------------------------------------------------------------------------------

do
    local TongueMain = section(
        TonguePage,
        "Tongue Escape",
        "Funções integradas ao ZyroHub para o PlaceId 122245938604556."
    )

    local TongueStatus = section(
        TonguePage,
        "Status",
        "Monitor das automações do Tongue Escape."
    )

    local statusLine = label(
        TongueStatus,
        "Aguardando...",
        9,
        Theme.Muted,
        Enum.Font.GothamMedium
    )
    statusLine.Size = UDim2.new(1, 0, 0, 22)

    local autoFarmPosition = false
    local autoTongue = false
    local autoRebirth = false
    local farmToken = 0
    local tongueToken = 0
    local rebirthToken = 0

    local function setTongueStatus(message, color)
        statusLine.Text = tostring(message)
        statusLine.TextColor3 = color or Theme.Muted
    end

    local function getEventsFolder()
        return ReplicatedStorage:FindFirstChild("Events")
    end

    local function startFarmLoop()
        farmToken += 1
        local token = farmToken

        task.spawn(function()
            while autoFarmPosition and token == farmToken do
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")

                if root then
                    pcall(function()
                        root.CFrame = CFrame.new(
                            math.random(-13195, -13190),
                            506,
                            -559
                        )
                    end)
                    setTongueStatus("Auto Farm ativo • mantendo posição", Theme.Success)
                else
                    setTongueStatus("Aguardando personagem...", Theme.Warning)
                end

                task.wait(0.03)
            end
        end)
    end

    local function startTongueLoop()
        tongueToken += 1
        local token = tongueToken

        task.spawn(function()
            while autoTongue and token == tongueToken do
                local events = getEventsFolder()
                local remote = events and events:FindFirstChild("AddTongue")

                if remote and remote:IsA("RemoteEvent") then
                    pcall(function()
                        remote:FireServer()
                    end)
                    setTongueStatus("Auto Tongue ativo", Theme.Success)
                else
                    setTongueStatus("Remote AddTongue não encontrado", Theme.Warning)
                end

                task.wait(0.01)
            end
        end)
    end

    local function startRebirthLoop()
        rebirthToken += 1
        local token = rebirthToken

        task.spawn(function()
            while autoRebirth and token == rebirthToken do
                local events = getEventsFolder()
                local remote = events and events:FindFirstChild("RequestRebirth")

                if remote and remote:IsA("RemoteFunction") then
                    pcall(function()
                        remote:InvokeServer()
                    end)
                    setTongueStatus("Auto Rebirth ativo", Theme.Success)
                else
                    setTongueStatus("Remote RequestRebirth não encontrado", Theme.Warning)
                end

                task.wait(1)
            end
        end)
    end

    toggleRow(
        TongueMain,
        "Auto Farm",
        "Mantém seu personagem na área de farm usada pelo script original.",
        false,
        function(state)
            autoFarmPosition = state

            if state then
                startFarmLoop()
                notify("Tongue Escape", "Auto Farm ativado.", "success")
            else
                farmToken += 1
                setTongueStatus("Auto Farm desativado", Theme.Muted)
            end
        end
    )

    toggleRow(
        TongueMain,
        "Auto Tongue",
        "Dispara AddTongue automaticamente.",
        false,
        function(state)
            autoTongue = state

            if state then
                startTongueLoop()
                notify("Tongue Escape", "Auto Tongue ativado.", "success")
            else
                tongueToken += 1
                setTongueStatus("Auto Tongue desativado", Theme.Muted)
            end
        end
    )

    toggleRow(
        TongueMain,
        "Auto Rebirth",
        "Solicita rebirth automaticamente a cada segundo.",
        false,
        function(state)
            autoRebirth = state

            if state then
                startRebirthLoop()
                notify("Tongue Escape", "Auto Rebirth ativado.", "success")
            else
                rebirthToken += 1
                setTongueStatus("Auto Rebirth desativado", Theme.Muted)
            end
        end
    )

    local AllToggle = actionButton(
        TongueMain,
        "Ativar farm completo",
        "Liga Auto Farm + Auto Tongue + Auto Rebirth.",
        Theme.Accent
    )

    AllToggle.MouseButton1Click:Connect(function()
        autoFarmPosition = true
        autoTongue = true
        autoRebirth = true

        startFarmLoop()
        startTongueLoop()
        startRebirthLoop()

        setTongueStatus("Farm completo ativado", Theme.Success)
        notify("Tongue Escape", "Farm completo iniciado.", "success")
    end)

    if not IS_TONGUE_ESCAPE then
        setTongueStatus("Módulo disponível apenas no Tongue Escape.", Theme.Muted)
    else
        setTongueStatus("Tongue Escape detectado • pronto", Theme.Success)
    end
end

--------------------------------------------------------------------------------
-- RIDE A PET PAGE
--------------------------------------------------------------------------------

local RideMain = section(RidePage, "Automação", "Controles principais do Ride A Pet")

toggleRow(
    RideMain,
    "Insta Interact",
    "Remove o tempo de espera dos ProximityPrompts para interagir instantaneamente.",
    true,
    function(state)
        instaInteractEnabled = state
        if state then
            refreshInstaInteract()
            notify("Insta Interact", "Interações instantâneas ativadas.", "success")
        else
            notify("Insta Interact", "Desativado.", "warning")
        end
    end
)


local GlobalESP = toggleRow(
    RideMain,
    "ESP de todos os Eggs",
    "Destaca todos os ovos renderizados.",
    mainESPActive,
    function(state)
        mainESPActive = state
        applyGlobalESP(state)
    end
)

local AutoBest = toggleRow(
    RideMain,
    "Auto Best Egg",
    "Procura Cherub, interage e retorna para sua plot.",
    autoBestEggActive,
    function(state)
        autoBestEggActive = state

        if state then
            startAutoBestEgg()
        else
            if autoBestEggThread then
                task.cancel(autoBestEggThread)
                autoBestEggThread = nil
            end
        end
    end
)

local TPHome = actionButton(
    RideMain,
    "Teleportar para casa",
    "Retorna imediatamente para sua plot.",
    Theme.Accent2
)
TPHome.MouseButton1Click:Connect(function()
    teleportToHomePlot()
    notify("Teleport", "Tentando voltar para sua plot.", "success")
end)

local RideKey = section(RidePage, "Atalho", "Defina a tecla do TP para casa")

local KeyBtn = Instance.new("TextButton")
KeyBtn.Size = UDim2.new(1, 0, 0, 46)
KeyBtn.BackgroundColor3 = Theme.Surface2
KeyBtn.BorderSizePixel = 0
KeyBtn.Text = ""
KeyBtn.AutoButtonColor = false
KeyBtn.Parent = RideKey
uiCorner(KeyBtn, 11)
uiStroke(KeyBtn, Theme.Stroke, 1, 0.55)

local KeyTitle = label(KeyBtn, "TP para casa", 10, Theme.Text, Enum.Font.GothamSemibold)
KeyTitle.Position = UDim2.new(0, 12, 0, 7)
KeyTitle.Size = UDim2.new(1, -85, 0, 15)

local KeyHint = label(KeyBtn, "Clique para trocar a tecla", 8, Theme.Muted, Enum.Font.Gotham)
KeyHint.Position = UDim2.new(0, 12, 0, 25)
KeyHint.Size = UDim2.new(1, -85, 0, 13)

local KeyBadge = Instance.new("TextLabel")
KeyBadge.Size = UDim2.new(0, 55, 0, 28)
KeyBadge.Position = UDim2.new(1, -67, 0.5, -14)
KeyBadge.BackgroundColor3 = Theme.AccentSoft
KeyBadge.BorderSizePixel = 0
KeyBadge.Text = tpKeybind.Name
KeyBadge.TextColor3 = Theme.Text
KeyBadge.TextSize = 10
KeyBadge.Font = Enum.Font.GothamBold
KeyBadge.Parent = KeyBtn
uiCorner(KeyBadge, 8)

makeHover(KeyBtn, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)

KeyBtn.MouseButton1Click:Connect(function()
    listeningForKey = true
    KeyHint.Text = "Pressione uma tecla..."
    KeyHint.TextColor3 = Theme.Warning
    KeyBadge.Text = "..."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if listeningForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        tpKeybind = input.KeyCode
        listeningForKey = false
        KeyBadge.Text = tpKeybind.Name
        KeyHint.Text = "Clique para trocar a tecla"
        KeyHint.TextColor3 = Theme.Muted
    elseif not gameProcessed and not listeningForKey and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == tpKeybind then
            teleportToHomePlot()
        end
    end
end)

local LordzyHopConfig = {}

local EggBrowser = section(RidePage, "Egg Browser", "Buscar, teleportar e ativar ESP individual")


-- Filtro dinâmico: qualquer egg exibido no Egg Browser pode virar alvo.
do
    local env = (getgenv and getgenv()) or _G
    env.LordzyHopState = env.LordzyHopState or {}
    env.LordzyHopState.targets = env.LordzyHopState.targets or {}
    env.LordzyHopState.eggHopEnabled = env.LordzyHopState.eggHopEnabled == true

    local FilterBox = Instance.new("Frame")
    FilterBox.Name = "EggHopFilterBox"
    FilterBox.Size = UDim2.new(1, 0, 0, 126)
    FilterBox.BackgroundColor3 = Theme.Surface2
    FilterBox.BorderSizePixel = 0
    FilterBox.Parent = EggBrowser
    uiCorner(FilterBox, 11)
    uiStroke(FilterBox, Theme.Accent, 1, 0.25)

    local FilterTitle = label(FilterBox, "SERVER HOP • ESCOLHA QUALQUER EGG", 10, Theme.Accent2, Enum.Font.GothamBold)
    FilterTitle.Position = UDim2.new(0, 12, 0, 9)
    FilterTitle.Size = UDim2.new(1, -24, 0, 18)

    local FilterSub = label(
        FilterBox,
        "Use o botão ALVO ao lado de qualquer egg da lista. Você pode selecionar vários.",
        8,
        Theme.Muted,
        Enum.Font.Gotham
    )
    FilterSub.Position = UDim2.new(0, 12, 0, 30)
    FilterSub.Size = UDim2.new(1, -24, 0, 18)
    FilterSub.TextWrapped = true

    local SelectedCount = label(FilterBox, "Alvos selecionados: 0", 8, Theme.Warning, Enum.Font.GothamSemibold)
    SelectedCount.Position = UDim2.new(0, 12, 0, 56)
    SelectedCount.Size = UDim2.new(1, -24, 0, 14)

    env.LordzyEggFilterUI = env.LordzyEggFilterUI or {}
    env.LordzyEggFilterUI.CountLabel = SelectedCount
    env.LordzyEggFilterUI.RefreshCount = function()
        local count = 0
        for _ in pairs(env.LordzyHopState.targets or {}) do
            count += 1
        end
        if env.LordzyEggFilterUI.CountLabel then
            env.LordzyEggFilterUI.CountLabel.Text = "Alvos selecionados: " .. tostring(count)
            env.LordzyEggFilterUI.CountLabel.TextColor3 = count > 0 and Theme.Success or Theme.Warning
        end
    end

    env.LordzyEggFilterUI.RefreshCount()

    local ClearSaved = Instance.new("TextButton")
    ClearSaved.Name = "ClearSavedEggTargets"
    ClearSaved.Size = UDim2.new(0, 112, 0, 22)
    ClearSaved.Position = UDim2.new(1, -124, 0, 53)
    ClearSaved.BackgroundColor3 = Theme.Surface3
    ClearSaved.BorderSizePixel = 0
    ClearSaved.Text = "LIMPAR ALVOS"
    ClearSaved.TextColor3 = Theme.Muted
    ClearSaved.TextSize = 7
    ClearSaved.Font = Enum.Font.GothamBold
    ClearSaved.AutoButtonColor = false
    ClearSaved.Parent = FilterBox
    uiCorner(ClearSaved, 7)

    ClearSaved.MouseButton1Click:Connect(function()
        if LordzyHopConfig and LordzyHopConfig.Clear then
            pcall(LordzyHopConfig.Clear)
        else
            env.LordzyHopState.targets = {}
        end

        if env.LordzyEggFilterUI and env.LordzyEggFilterUI.RefreshCount then
            pcall(env.LordzyEggFilterUI.RefreshCount)
        end

        notify("Egg Filter", "Alvos salvos foram limpos.", "warning")
    end)

    -- Permite marcar um egg que NÃO existe no servidor atual.
    local ManualTarget = Instance.new("TextBox")
    ManualTarget.Name = "ManualEggTarget"
    ManualTarget.Size = UDim2.new(1, -112, 0, 30)
    ManualTarget.Position = UDim2.new(0, 12, 0, 86)
    ManualTarget.BackgroundColor3 = Theme.Surface3
    ManualTarget.BorderSizePixel = 0
    ManualTarget.PlaceholderText = "Ex.: Cherub Egg, Blackhole Egg..."
    ManualTarget.PlaceholderColor3 = Theme.Dim
    ManualTarget.Text = ""
    ManualTarget.TextColor3 = Theme.Text
    ManualTarget.TextSize = 8
    ManualTarget.Font = Enum.Font.Gotham
    ManualTarget.TextXAlignment = Enum.TextXAlignment.Left
    ManualTarget.ClearTextOnFocus = false
    ManualTarget.Parent = FilterBox
    uiCorner(ManualTarget, 8)
    uiPadding(ManualTarget, 9, 8, 0, 0)

    local AddManual = Instance.new("TextButton")
    AddManual.Name = "AddManualEggTarget"
    AddManual.Size = UDim2.new(0, 88, 0, 30)
    AddManual.Position = UDim2.new(1, -100, 0, 86)
    AddManual.BackgroundColor3 = Theme.AccentSoft
    AddManual.BorderSizePixel = 0
    AddManual.Text = "ADICIONAR"
    AddManual.TextColor3 = Theme.Text
    AddManual.TextSize = 7
    AddManual.Font = Enum.Font.GothamBold
    AddManual.AutoButtonColor = false
    AddManual.Parent = FilterBox
    uiCorner(AddManual, 8)

    local function addManualTarget()
        local rawName = tostring(ManualTarget.Text or "")
        rawName = rawName:gsub("^%s+", ""):gsub("%s+$", "")

        if rawName == "" then
            notify("Egg Filter", "Digite o nome do egg que deseja procurar.", "warning")
            return
        end

        local key = rawName:lower():gsub("[%s_%-]", "")
        env.LordzyHopState.targets = env.LordzyHopState.targets or {}
        env.LordzyHopState.targets[key] = rawName

        if LordzyHopConfig and LordzyHopConfig.Save then
            pcall(LordzyHopConfig.Save)
        end

        if env.LordzyEggFilterUI and env.LordzyEggFilterUI.RefreshCount then
            pcall(env.LordzyEggFilterUI.RefreshCount)
        end

        ManualTarget.Text = ""
        notify("Egg Filter", rawName .. " adicionado como ALVO.", "success")
    end

    AddManual.MouseButton1Click:Connect(addManualTarget)
    ManualTarget.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            addManualTarget()
        end
    end)
end

local SearchRow = Instance.new("Frame")
SearchRow.Size = UDim2.new(1, 0, 0, 38)
SearchRow.BackgroundTransparency = 1
SearchRow.Parent = EggBrowser

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -46, 1, 0)
SearchBox.BackgroundColor3 = Theme.Surface2
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText = "Buscar egg..."
SearchBox.PlaceholderColor3 = Theme.Dim
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.Text
SearchBox.TextSize = 10
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchRow
uiCorner(SearchBox, 10)
uiStroke(SearchBox, Theme.Stroke, 1, 0.55)
uiPadding(SearchBox, 10, 8, 0, 0)

local RefreshEggs = Instance.new("TextButton")
RefreshEggs.Size = UDim2.new(0, 38, 0, 38)
RefreshEggs.Position = UDim2.new(1, -38, 0, 0)
RefreshEggs.BackgroundColor3 = Theme.Surface2
RefreshEggs.BorderSizePixel = 0
RefreshEggs.Text = "↻"
RefreshEggs.TextColor3 = Theme.Text
RefreshEggs.TextSize = 18
RefreshEggs.Font = Enum.Font.GothamBold
RefreshEggs.AutoButtonColor = false
RefreshEggs.Parent = SearchRow
uiCorner(RefreshEggs, 10)
uiStroke(RefreshEggs, Theme.Stroke, 1, 0.55)
makeHover(RefreshEggs, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)

local EggList = Instance.new("ScrollingFrame")
EggList.Size = UDim2.new(1, 0, 0, 190)
EggList.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
EggList.BorderSizePixel = 0
EggList.ScrollBarThickness = 3
EggList.ScrollBarImageColor3 = Theme.Accent
EggList.CanvasSize = UDim2.new(0, 0, 0, 0)
EggList.Parent = EggBrowser
uiCorner(EggList, 11)
uiStroke(EggList, Theme.Stroke, 1, 0.55)
uiPadding(EggList, 7, 7, 7, 7)

local EggLayout = Instance.new("UIListLayout")
EggLayout.Padding = UDim.new(0, 6)
EggLayout.SortOrder = Enum.SortOrder.LayoutOrder
EggLayout.Parent = EggList

EggLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    EggList.CanvasSize = UDim2.new(0, 0, 0, EggLayout.AbsoluteContentSize.Y + 14)
end)

local function clearEggList()
    for _, child in ipairs(EggList:GetChildren()) do
        if child:IsA("Frame") and child.Name == "EggItem" then
            child:Destroy()
        end
    end
end

local function addEggItem(egg)
    local item = Instance.new("Frame")
    item.Name = "EggItem"
    item.Size = UDim2.new(1, -2, 0, 44)
    item.BackgroundColor3 = Theme.Surface2
    item.BorderSizePixel = 0
    item.Parent = EggList
    uiCorner(item, 10)

    local eggName = label(item, egg.Name, 9, Theme.Text, Enum.Font.GothamMedium)
    eggName.Position = UDim2.new(0, 10, 0, 7)
    eggName.Size = UDim2.new(1, -168, 0, 14)
    eggName.TextTruncate = Enum.TextTruncate.AtEnd

    local eggSub = label(item, "RenderedEgg", 8, Theme.Dim, Enum.Font.Gotham)
    eggSub.Position = UDim2.new(0, 10, 0, 23)
    eggSub.Size = UDim2.new(1, -168, 0, 12)

    local target = Instance.new("TextButton")
    target.Size = UDim2.new(0, 47, 0, 26)
    target.Position = UDim2.new(1, -132, 0.5, -13)
    target.BackgroundColor3 = Theme.Surface3
    target.BorderSizePixel = 0
    target.Text = "ALVO"
    target.TextColor3 = Theme.Muted
    target.TextSize = 7
    target.Font = Enum.Font.GothamBold
    target.AutoButtonColor = false
    target.Parent = item
    uiCorner(target, 8)

    local tp = Instance.new("TextButton")
    tp.Size = UDim2.new(0, 36, 0, 26)
    tp.Position = UDim2.new(1, -78, 0.5, -13)
    tp.BackgroundColor3 = Theme.Surface3
    tp.BorderSizePixel = 0
    tp.Text = "TP"
    tp.TextColor3 = Theme.Text
    tp.TextSize = 8
    tp.Font = Enum.Font.GothamBold
    tp.AutoButtonColor = false
    tp.Parent = item
    uiCorner(tp, 8)
    makeHover(tp, Theme.Surface3, Theme.AccentSoft, Theme.Accent)

    local esp = Instance.new("TextButton")
    esp.Size = UDim2.new(0, 32, 0, 26)
    esp.Position = UDim2.new(1, -37, 0.5, -13)
    esp.BackgroundColor3 = Theme.Surface3
    esp.BorderSizePixel = 0
    esp.Text = "◉"
    esp.TextColor3 = Theme.Muted
    esp.TextSize = 11
    esp.Font = Enum.Font.GothamBold
    esp.AutoButtonColor = false
    esp.Parent = item
    uiCorner(esp, 8)

    local function normalizeTargetName(value)
        return tostring(value or ""):lower():gsub("[%s_%-]", "")
    end

    local function renderTarget()
        local env = (getgenv and getgenv()) or _G
        env.LordzyHopState = env.LordzyHopState or {}
        env.LordzyHopState.targets = env.LordzyHopState.targets or {}

        local key = normalizeTargetName(egg.Name)
        local active = env.LordzyHopState.targets[key] ~= nil

        tw(target, 0.14, {
            BackgroundColor3 = active and Color3.fromRGB(63, 48, 115) or Theme.Surface3,
            TextColor3 = active and Theme.Success or Theme.Muted
        })
        target.Text = active and "✓ ALVO" or "ALVO"
    end

    local function renderESP()
        local active = highlights[egg] and highlights[egg].CustomActive
        tw(esp, 0.14, {
            BackgroundColor3 = active and Color3.fromRGB(35, 119, 78) or Theme.Surface3,
            TextColor3 = active and Theme.Success or Theme.Muted
        })
    end

    target.MouseButton1Click:Connect(function()
        local env = (getgenv and getgenv()) or _G
        env.LordzyHopState = env.LordzyHopState or {}
        env.LordzyHopState.targets = env.LordzyHopState.targets or {}

        local key = normalizeTargetName(egg.Name)
        if env.LordzyHopState.targets[key] then
            env.LordzyHopState.targets[key] = nil
        else
            env.LordzyHopState.targets[key] = egg.Name
        end

        if LordzyHopConfig and LordzyHopConfig.Save then
            pcall(LordzyHopConfig.Save)
        end

        renderTarget()

        if env.LordzyEggFilterUI and env.LordzyEggFilterUI.RefreshCount then
            pcall(env.LordzyEggFilterUI.RefreshCount)
        end
    end)

    tp.MouseButton1Click:Connect(function()
        teleportToModel(egg)
    end)

    esp.MouseButton1Click:Connect(function()
        if not highlights[egg] then
            highlights[egg] = {
                Highlight = nil,
                CustomColor = defaultCustomColor,
                CustomActive = false
            }
        end

        highlights[egg].CustomActive = not highlights[egg].CustomActive
        highlights[egg].CustomColor = defaultCustomColor
        updateEggESP(egg)
        renderESP()
    end)

    renderTarget()
    renderESP()
end


local function populateEggs()
    clearEggList()

    if not RenderedEggsFolder then
        local empty = Instance.new("Frame")
        empty.Name = "EggItem"
        empty.Size = UDim2.new(1, -2, 0, 44)
        empty.BackgroundTransparency = 1
        empty.Parent = EggList

        local txt = label(empty, "RenderedEggs não encontrado.", 9, Theme.Warning, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
        txt.Size = UDim2.fromScale(1, 1)
        return
    end

    local query = SearchBox.Text:lower()
    local found = 0

    for _, egg in ipairs(RenderedEggsFolder:GetChildren()) do
        if query == "" or string.find(egg.Name:lower(), query, 1, true) then
            found += 1
            addEggItem(egg)
        end
    end

    if found == 0 then
        local empty = Instance.new("Frame")
        empty.Name = "EggItem"
        empty.Size = UDim2.new(1, -2, 0, 44)
        empty.BackgroundTransparency = 1
        empty.Parent = EggList

        local txt = label(empty, "Nenhum egg encontrado.", 9, Theme.Muted, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
        txt.Size = UDim2.fromScale(1, 1)
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(populateEggs)

RefreshEggs.MouseButton1Click:Connect(function()
    tw(RefreshEggs, 0.14, {Rotation = RefreshEggs.Rotation + 180})
    populateEggs()
end)

if RenderedEggsFolder then
    RenderedEggsFolder.ChildAdded:Connect(function()
        task.wait(0.1)
        populateEggs()
    end)

    RenderedEggsFolder.ChildRemoved:Connect(function()
        task.wait(0.05)
        populateEggs()
    end)
end

populateEggs()

local unreadChatCount = 0
local updateChatBadge
local isMinimized = false
local restoreHub



-- Estado do filtro de eggs. getgenv ajuda alguns executores a preservar
-- a seleção enquanto o script é recarregado.
local LordzyHopState
do
    local env = (getgenv and getgenv()) or _G
    env.LordzyHopState = env.LordzyHopState or {}
    env.LordzyHopState.targets = env.LordzyHopState.targets or {}
    env.LordzyHopState.eggHopEnabled = env.LordzyHopState.eggHopEnabled == true
    LordzyHopState = env.LordzyHopState
end


do
    local env = (getgenv and getgenv()) or _G

    local CONFIG_FOLDER = "ZyroHub"
    local CONFIG_FILE = CONFIG_FOLDER .. "/ride_a_pet_egg_targets.json"

    -- Alguns executores expõem as funções de arquivo como globais,
    -- outros dentro de getgenv(). Aceita os dois formatos.
    local writeFileFn = (type(writefile) == "function" and writefile) or env.writefile
    local readFileFn = (type(readfile) == "function" and readfile) or env.readfile
    local isFileFn = (type(isfile) == "function" and isfile) or env.isfile
    local makeFolderFn = (type(makefolder) == "function" and makefolder) or env.makefolder
    local isFolderFn = (type(isfolder) == "function" and isfolder) or env.isfolder

    local function canUseFileSystem()
        return type(writeFileFn) == "function"
            and type(readFileFn) == "function"
            and type(isFileFn) == "function"
    end

    local function ensureFolder()
        if type(makeFolderFn) ~= "function" then
            return
        end

        local okIsFolder, exists = pcall(function()
            if type(isFolderFn) == "function" then
                return isFolderFn(CONFIG_FOLDER)
            end
            return false
        end)

        if not okIsFolder or not exists then
            pcall(function()
                makeFolderFn(CONFIG_FOLDER)
            end)
        end
    end

    local function normalizeTargets(data)
        local out = {}
        if type(data) ~= "table" then
            return out
        end

        for key, displayName in pairs(data) do
            if type(key) == "string" and type(displayName) == "string" and key ~= "" and displayName ~= "" then
                out[key] = displayName
            end
        end

        return out
    end

    function LordzyHopConfig.Load()
        -- Primeiro tenta carregar do arquivo persistente.
        if canUseFileSystem() then
            ensureFolder()

            local okExists, exists = pcall(function()
                return isFileFn(CONFIG_FILE)
            end)

            if okExists and exists then
                local okRead, raw = pcall(function()
                    return readFileFn(CONFIG_FILE)
                end)

                if okRead and type(raw) == "string" and raw ~= "" then
                    local okDecode, decoded = pcall(function()
                        return HttpService:JSONDecode(raw)
                    end)

                    if okDecode and type(decoded) == "table" then
                        LordzyHopState.targets = normalizeTargets(decoded.targets)
                        LordzyHopState.eggHopEnabled = decoded.eggHopEnabled == true

                        local loadedCount = 0
                        for _ in pairs(LordzyHopState.targets) do
                            loadedCount += 1
                        end
                        print("[ZyroHub Config] Loaded targets:", loadedCount, "AutoHop:", LordzyHopState.eggHopEnabled)

                        return true
                    end
                end
            end
        end

        -- Fallback: mantém o estado atual/getgenv durante a sessão.
        LordzyHopState.targets = normalizeTargets(LordzyHopState.targets)
        return false
    end

    function LordzyHopConfig.Save()
        LordzyHopState.targets = normalizeTargets(LordzyHopState.targets)

        if not canUseFileSystem() then
            warn("[ZyroHub Config] Executor sem writefile/readfile/isfile; config não sobreviverá ao teleport.")
            return false
        end

        ensureFolder()

        local payload = {
            version = 2,
            targets = LordzyHopState.targets,
            eggHopEnabled = LordzyHopState.eggHopEnabled == true,
        }

        local okEncode, encoded = pcall(function()
            return HttpService:JSONEncode(payload)
        end)

        if not okEncode then
            return false
        end

        local okWrite, writeErr = pcall(function()
            writeFileFn(CONFIG_FILE, encoded)
        end)

        local savedCount = 0
        for _ in pairs(LordzyHopState.targets) do
            savedCount += 1
        end

        if okWrite then
            print("[ZyroHub Config] Saved targets:", savedCount, "AutoHop:", LordzyHopState.eggHopEnabled)
        else
            warn("[ZyroHub Config] Save failed:", tostring(writeErr))
        end

        return okWrite
    end

    function LordzyHopConfig.Clear()
        LordzyHopState.targets = {}
        LordzyHopState.eggHopEnabled = false
        LordzyHopConfig.Save()
    end

    LordzyHopConfig.Load()

    -- O Egg Browser foi criado antes da leitura da config.
    -- Redesenha a lista para os ALVOS salvos voltarem marcados.
    pcall(function()
        if populateEggs then
            populateEggs()
        end
    end)

    local envUI = (getgenv and getgenv()) or _G
    if envUI.LordzyEggFilterUI and envUI.LordzyEggFilterUI.RefreshCount then
        pcall(envUI.LordzyEggFilterUI.RefreshCount)
    end
end


--------------------------------------------------------------------------------
-- RIDE A PET - SERVER HOP
--------------------------------------------------------------------------------

do
    local ServerHopSection = section(
        RidePage,
        "Server Hop",
        "Troque de servidor manualmente ou deixe o hub procurar outro automaticamente."
    )

    local autoServerHop = false
    local autoServerHopToken = 0
    local HOP_RETRY_SECONDS = 20

    -- Alguns eggs continuam em RenderedEggs mesmo depois de serem pegos.
    -- Mantemos uma lista fraca das instâncias já coletadas para não detectar
    -- o mesmo ovo novamente no servidor atual.
    local collectedEggInstances = setmetatable({}, {__mode = "k"})

    local function markEggAsCollected(egg)
        if egg then
            collectedEggInstances[egg] = true
        end
    end

    local function isEggAlreadyCollected(egg)
        return egg ~= nil and collectedEggInstances[egg] == true
    end

    --------------------------------------------------------------------------
    -- EGG FILTER SERVER HOP
    --------------------------------------------------------------------------

    local EggFilterSection = section(
        RidePage,
        "Egg Filter Hop",
        "Escolha os eggs desejados. O hub troca de servidor até encontrar um deles."
    )

    local function normalizedEggName(name)
        return tostring(name or ""):lower():gsub("[%s_%-]", "")
    end

    local function eggMatchesFilter(eggName, filterKey)
        local normalized = normalizedEggName(eggName)
        local wanted = tostring(filterKey or "")

        -- ALVO escolhido pela lista = normalmente nome completo.
        -- ALVO digitado manualmente também pode ser parcial:
        -- "cherub" encontra "Cherub Egg", por exemplo.
        return normalized == wanted
            or (wanted ~= "" and string.find(normalized, wanted, 1, true) ~= nil)
    end

    local function getSelectedEggFilters()
        local selected = {}
        for filterKey in pairs(LordzyHopState.targets or {}) do
            selected[#selected + 1] = filterKey
        end
        return selected
    end

    local function getSelectedEggFilterNames()
        local names = {}
        for _, displayName in pairs(LordzyHopState.targets or {}) do
            names[#names + 1] = tostring(displayName)
        end
        table.sort(names)
        return names
    end

    local function findWantedEggInCurrentServer()
        if not RenderedEggsFolder then
            return nil, nil
        end

        local selected = getSelectedEggFilters()
        if #selected == 0 then
            return nil, nil
        end

        for _, egg in ipairs(RenderedEggsFolder:GetChildren()) do
            if not isEggAlreadyCollected(egg) then
                for filterKey in pairs(LordzyHopState.targets or {}) do
                    if eggMatchesFilter(egg.Name, filterKey) then
                        return egg, filterKey
                    end
                end
            end
        end

        return nil, nil
    end

    local FilterStatus = Instance.new("Frame")
    FilterStatus.Size = UDim2.new(1, 0, 0, 52)
    FilterStatus.BackgroundColor3 = Theme.Surface2
    FilterStatus.BorderSizePixel = 0
    FilterStatus.Parent = EggFilterSection
    uiCorner(FilterStatus, 11)
    uiStroke(FilterStatus, Theme.Stroke, 1, 0.55)

    local FilterStatusTitle = label(
        FilterStatus,
        "Filtro: nenhum egg selecionado",
        9,
        Theme.Text,
        Enum.Font.GothamSemibold
    )
    FilterStatusTitle.Position = UDim2.new(0, 12, 0, 8)
    FilterStatusTitle.Size = UDim2.new(1, -24, 0, 16)

    local FilterStatusSub = label(
        FilterStatus,
        "Escolha os alvos diretamente no Egg Browser.",
        8,
        Theme.Muted,
        Enum.Font.Gotham
    )
    FilterStatusSub.Position = UDim2.new(0, 12, 0, 28)
    FilterStatusSub.Size = UDim2.new(1, -24, 0, 14)

    local function refreshEggFilterStatus()
        local names = getSelectedEggFilterNames()

        if #names == 0 then
            FilterStatusTitle.Text = "Filtro: nenhum egg selecionado"
            FilterStatusTitle.TextColor3 = Theme.Text
            FilterStatusSub.Text = "Escolha qualquer egg pelo botão ALVO no Egg Browser."
            FilterStatusSub.TextColor3 = Theme.Muted
        else
            local preview = table.concat(names, ", ")
            if #preview > 65 then
                preview = preview:sub(1, 62) .. "..."
            end

            FilterStatusTitle.Text = "Alvos (" .. tostring(#names) .. "): " .. preview
            FilterStatusTitle.TextColor3 = Theme.Warning

            local found = findWantedEggInCurrentServer()
            if found then
                FilterStatusSub.Text = "Encontrado neste servidor: " .. found.Name
                FilterStatusSub.TextColor3 = Theme.Success
            else
                FilterStatusSub.Text = "Nenhum dos alvos selecionados neste servidor."
                FilterStatusSub.TextColor3 = Theme.Muted
            end
        end
    end

    refreshEggFilterStatus()

    local function executorRequest(url)
        -- Não adiciona parâmetros extras à URL da API do Roblox.
        -- Alguns endpoints respondem com JSON de erro quando recebem
        -- parâmetros desconhecidos, o que antes parecia "0 servidores".

        local function validBody(body)
            return type(body) == "string" and #body > 2
        end

        -- Método 1: HttpGet do ambiente/executor.
        local ok, body = pcall(function()
            return game:HttpGet(url, true)
        end)

        if ok and validBody(body) then
            return body, nil
        end

        -- Método 2: request/http_request/syn.request/http.request/fluxus.request.
        local env = (getgenv and getgenv()) or _G
        local req = nil

        if type(env.request) == "function" then
            req = env.request
        elseif type(env.http_request) == "function" then
            req = env.http_request
        elseif env.syn and type(env.syn.request) == "function" then
            req = env.syn.request
        elseif env.http and type(env.http.request) == "function" then
            req = env.http.request
        elseif env.fluxus and type(env.fluxus.request) == "function" then
            req = env.fluxus.request
        end

        if type(req) == "function" then
            local reqOk, response = pcall(req, {
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json",
                    ["Cache-Control"] = "no-cache"
                }
            })

            if reqOk and type(response) == "table" then
                local status = tonumber(response.StatusCode or response.Status or response.status_code)
                local responseBody = response.Body or response.body

                if status and (status < 200 or status >= 300) then
                    return nil, "HTTP_STATUS_" .. tostring(status)
                end

                if validBody(responseBody) then
                    return responseBody, nil
                end
            end
        end

        return nil, "HTTP_REQUEST_FAILED"
    end

    local function fetchPublicServers(cursor)
        local url = "https://games.roblox.com/v1/games/" ..
            tostring(game.PlaceId) ..
            "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"

        if cursor and cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local body, requestError = executorRequest(url)
        if not body then
            return nil, requestError or "HTTP_REQUEST_FAILED"
        end

        local decodeOk, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if not decodeOk or type(decoded) ~= "table" then
            warn("[Lordzy ServerHop] JSON inválido. Body:", tostring(body):sub(1, 180))
            return nil, "JSON_DECODE_FAILED"
        end

        -- A API também devolve erros como JSON. Não tratar isso como lista vazia.
        if type(decoded.errors) == "table" and #decoded.errors > 0 then
            local firstError = decoded.errors[1]
            local message = type(firstError) == "table" and firstError.message or tostring(firstError)
            warn("[Lordzy ServerHop] API retornou erro:", tostring(message))
            return nil, "ROBLOX_API_ERROR"
        end

        if type(decoded.data) ~= "table" then
            warn("[Lordzy ServerHop] Resposta sem campo data. Body:", tostring(body):sub(1, 180))
            return nil, "INVALID_SERVER_RESPONSE"
        end

        return decoded, nil
    end

    local function findHopServer()
        local cursor = nil
        local checkedPages = 0
        local candidates = {}
        local lastError = nil

        repeat
            checkedPages += 1

            local page, fetchError = fetchPublicServers(cursor)
            if not page then
                lastError = fetchError
                break
            end

            if type(page.data) == "table" then
                for _, server in ipairs(page.data) do
                    local serverId = tostring(server.id or "")
                    local playing = tonumber(server.playing) or 0
                    local maxPlayers = tonumber(server.maxPlayers) or 0

                    if serverId ~= ""
                    and serverId ~= game.JobId
                    and maxPlayers > 0
                    and playing < maxPlayers then
                        candidates[#candidates + 1] = {
                            id = serverId,
                            playing = playing,
                            maxPlayers = maxPlayers
                        }
                    end
                end
            end

            cursor = page.nextPageCursor
        until not cursor
            or cursor == ""
            or checkedPages >= 5
            or #candidates >= 20

        if #candidates == 0 then
            return nil, lastError or "NO_SERVERS"
        end

        -- Servidores menos cheios primeiro.
        table.sort(candidates, function(a, b)
            if a.playing == b.playing then
                return a.id < b.id
            end
            return a.playing < b.playing
        end)

        -- Escolhe aleatoriamente entre os primeiros para não cair
        -- sempre no mesmo servidor.
        local poolSize = math.min(8, #candidates)
        return candidates[math.random(1, poolSize)], nil
    end

    local hopBusy = false

    local function hopServerOnce()
        if hopBusy then
            notify("Server Hop", "Já estou procurando um servidor.", "warning")
            return false
        end

        hopBusy = true
        notify("Server Hop", "Procurando outro servidor...", "warning")

        local server, reason = findHopServer()

        if not server then
            hopBusy = false

            if reason == "HTTP_REQUEST_FAILED" or string.find(tostring(reason), "HTTP_STATUS_", 1, true) then
                notify(
                    "Server Hop",
                    "O executor não conseguiu acessar a API de servidores (" .. tostring(reason) .. ").",
                    "danger"
                )
                warn("[Lordzy ServerHop] Falha HTTP:", reason)
            elseif reason == "JSON_DECODE_FAILED" then
                notify(
                    "Server Hop",
                    "A lista de servidores veio em formato inválido.",
                    "danger"
                )
                warn("[Lordzy ServerHop] Falha ao interpretar JSON da API.")
            elseif reason == "ROBLOX_API_ERROR" or reason == "INVALID_SERVER_RESPONSE" then
                notify(
                    "Server Hop",
                    "A API do Roblox respondeu com erro. Veja o console.",
                    "danger"
                )
                warn("[Lordzy ServerHop] Resposta da API inválida:", reason)
            else
                notify(
                    "Server Hop",
                    "Nenhum outro servidor com vaga foi encontrado.",
                    "danger"
                )
                warn("[Lordzy ServerHop] Nenhum candidato. JobId atual:", game.JobId)
            end

            return false
        end

        notify(
            "Server Hop",
            "Entrando em outro servidor (" ..
                tostring(server.playing) .. "/" ..
                tostring(server.maxPlayers) .. ")...",
            "success"
        )

        print(
            "[Lordzy ServerHop] Indo para:",
            server.id,
            "Players:",
            server.playing .. "/" .. server.maxPlayers
        )

        local ok, teleportError = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                server.id,
                LocalPlayer
            )
        end)

        if not ok then
            hopBusy = false
            warn("[Lordzy ServerHop] Teleport falhou:", teleportError)
            notify(
                "Server Hop",
                "O servidor foi encontrado, mas o teleport falhou.",
                "danger"
            )
            return false
        end

        -- Caso o executor/jogo demore para iniciar o teleport,
        -- libera o botão novamente depois de alguns segundos.
        task.delay(8, function()
            hopBusy = false
        end)

        return true
    end


    local eggHopToken = 0
    local eggHopBusy = false

    local autoCollectBusy = false

    local function collectFoundTargetEgg(foundEgg)
        if autoCollectBusy or not foundEgg or not foundEgg.Parent then
            return false
        end

        autoCollectBusy = true
        local eggName = tostring(foundEgg.Name)

        -- Assim que começamos a coletar, a mesma instância deixa de ser
        -- considerada disponível, mesmo que continue em RenderedEggs.
        markEggAsCollected(foundEgg)

        FilterStatusTitle.Text = "ENCONTRADO: " .. eggName
        FilterStatusTitle.TextColor3 = Theme.Success
        FilterStatusSub.Text = "Pegando o egg..."

        notify(
            "Egg encontrado!",
            eggName .. " apareceu. Indo coletar.",
            "success"
        )

        local ok, err = pcall(function()
            teleportToModel(foundEgg)
            task.wait(0.40)

            -- Insta Interact primeiro. Se não houver ProximityPrompt utilizável,
            -- usa E como fallback.
            local instantWorked = false
            if instaInteractEnabled then
                instantWorked = instantInteractTarget(foundEgg)
            end

            if instantWorked then
                task.wait(0.35)
            else
                holdEKey(instaInteractEnabled and 0.12 or 3)
                task.wait(0.20)
            end

            -- Volta para a base SEM depender do egg sumir de RenderedEggs.
            teleportToHomePlot()
            task.wait(0.65)
        end)

        if not ok then
            warn("[ZyroHub AutoCollect] Falha durante coleta:", tostring(err))
            pcall(teleportToHomePlot)
            task.wait(0.5)
        end

        FilterStatusTitle.Text = "COLETADO: " .. eggName
        FilterStatusTitle.TextColor3 = Theme.Success
        FilterStatusSub.Text = "Coletado. Continuando a busca..."
        FilterStatusSub.TextColor3 = Theme.Success

        notify(
            "Egg Filter Hop",
            eggName .. " coletado. Continuando a busca...",
            "success"
        )

        print("[ZyroHub EggHop] Coletado:", eggName, "- continuando loop")

        autoCollectBusy = false
        return true
    end

    local function runEggFilterHop()
        if eggHopBusy then
            return
        end

        local selected = getSelectedEggFilters()
        if #selected == 0 then
            LordzyHopState.eggHopEnabled = false
            if LordzyHopConfig and LordzyHopConfig.Save then
                pcall(LordzyHopConfig.Save)
            end
            notify(
                "Egg Filter Hop",
                "Selecione pelo menos um egg como ALVO no Egg Browser primeiro.",
                "warning"
            )
            return
        end

        eggHopBusy = true
        eggHopToken += 1
        local myToken = eggHopToken

        task.spawn(function()
            local okLoop, loopErr = pcall(function()
                task.wait(2)

                if not LordzyHopState.eggHopEnabled or myToken ~= eggHopToken then
                    return
                end

                local foundEgg = findWantedEggInCurrentServer()

                if foundEgg then
                    print("[ZyroHub EggHop] Alvo encontrado:", foundEgg.Name)

                    -- Coleta e retorna para a base.
                    collectFoundTargetEgg(foundEgg)

                    if not LordzyHopState.eggHopEnabled or myToken ~= eggHopToken then
                        return
                    end

                    -- IMPORTANTE:
                    -- Depois de coletar, NÃO tenta reutilizar RenderedEggs neste servidor.
                    -- O jogo pode manter/recriar uma cópia visual do ovo já pego.
                    -- Faz Server Hop direto para continuar a farm.
                    FilterStatusTitle.Text = "COLETADO: " .. tostring(foundEgg.Name)
                    FilterStatusTitle.TextColor3 = Theme.Success
                    FilterStatusSub.Text = "Coletado. Indo para outro servidor..."
                    FilterStatusSub.TextColor3 = Theme.Warning

                    if LordzyHopConfig and LordzyHopConfig.Save then
                        pcall(LordzyHopConfig.Save)
                    end

                    print("[ZyroHub EggHop] Coleta concluída - forçando Server Hop")

                    task.wait(0.7)

                    local started = hopServerOnce()
                    if not started then
                        -- Se a API falhar, tenta de novo sem desligar o AutoHop.
                        print("[ZyroHub EggHop] Hop falhou; nova tentativa em", HOP_RETRY_SECONDS, "s")
                        task.wait(HOP_RETRY_SECONDS)

                        if LordzyHopState.eggHopEnabled and myToken == eggHopToken then
                            eggHopBusy = false
                            runEggFilterHop()
                            return
                        end
                    end

                    return
                end

                -- Nenhum alvo neste servidor: troca normalmente.
                local names = getSelectedEggFilterNames()
                local preview = table.concat(names, " + ")
                if #preview > 75 then
                    preview = preview:sub(1, 72) .. "..."
                end

                FilterStatusTitle.Text = "PROCURANDO: " .. preview
                FilterStatusTitle.TextColor3 = Theme.Warning
                FilterStatusSub.Text = "Nenhum alvo neste servidor. Fazendo Server Hop..."
                FilterStatusSub.TextColor3 = Theme.Muted

                if LordzyHopConfig and LordzyHopConfig.Save then
                    pcall(LordzyHopConfig.Save)
                end

                print("[ZyroHub EggHop] Nenhum alvo - Server Hop")

                local started = hopServerOnce()
                if not started then
                    task.wait(HOP_RETRY_SECONDS)

                    if LordzyHopState.eggHopEnabled and myToken == eggHopToken then
                        eggHopBusy = false
                        runEggFilterHop()
                        return
                    end
                end
            end)

            if not okLoop then
                warn("[ZyroHub EggHop] ERRO NO LOOP:", tostring(loopErr))
                FilterStatusSub.Text = "Erro no loop. Tentando novamente..."
                FilterStatusSub.TextColor3 = Theme.Warning
            end

            eggHopBusy = false
        end)
    end

    toggleRow(
        EggFilterSection,
        "Auto Server Hop por Egg",
        "Troca de servidor até encontrar qualquer egg marcado acima.",
        LordzyHopState.eggHopEnabled == true,
        function(state)
            LordzyHopState.eggHopEnabled = state

            if LordzyHopConfig and LordzyHopConfig.Save then
                pcall(LordzyHopConfig.Save)
            end

            if state then
                local selected = getSelectedEggFilters()

                if #selected == 0 then
                    LordzyHopState.eggHopEnabled = false
                    if LordzyHopConfig and LordzyHopConfig.Save then
                        pcall(LordzyHopConfig.Save)
                    end
                    notify(
                        "Egg Filter Hop",
                        "Você precisa selecionar pelo menos um egg como ALVO no Egg Browser.",
                        "warning"
                    )
                    return
                end

                -- Sempre inicia o loop principal. Ele mesmo cuida de
                -- coletar qualquer alvo já presente e depois continuar/hopar.
                runEggFilterHop()
            else
                eggHopToken += 1
                eggHopBusy = false
                if LordzyHopConfig and LordzyHopConfig.Save then
                    pcall(LordzyHopConfig.Save)
                end
                refreshEggFilterStatus()
                notify("Egg Filter Hop", "Desativado.", "warning")
            end
        end
    )

    -- Ao entrar em outro servidor, continua a caça automaticamente.
    if LordzyHopState.eggHopEnabled then
        local restoredNames = getSelectedEggFilterNames()
        notify(
            "Egg Filter Hop",
            "Retomando busca por " .. tostring(#restoredNames) .. " alvo(s) salvo(s)...",
            "success"
        )
        task.defer(runEggFilterHop)
    end

    toggleRow(
        ServerHopSection,
        "Auto Server Hop",
        "Enquanto ativo, tenta trocar para outro servidor automaticamente.",
        false,
        function(state)
            autoServerHop = state
            autoServerHopToken += 1
            local myToken = autoServerHopToken

            if state then
                notify("Auto Server Hop", "Ativado.", "success")

                task.spawn(function()
                    task.wait(1)

                    while autoServerHop
                    and myToken == autoServerHopToken do
                        local started = hopServerOnce()

                        if started then
                            break
                        end

                        task.wait(HOP_RETRY_SECONDS)
                    end
                end)
            else
                notify("Auto Server Hop", "Desativado.", "warning")
            end
        end
    )

    local HopNowButton = actionButton(
        ServerHopSection,
        "Server Hop agora",
        "Procura outro servidor com vaga e troca uma única vez.",
        Theme.Accent2
    )

    HopNowButton.MouseButton1Click:Connect(function()
        task.spawn(hopServerOnce)
    end)

    -- A detecção de alvos é centralizada no loop do Egg Hop.
    -- Isso evita duas rotinas tentando coletar/hopar ao mesmo tempo.
end

--------------------------------------------------------------------------------
-- CHAT PAGE
--------------------------------------------------------------------------------

local ChatCard = Instance.new("Frame")
ChatCard.Size = UDim2.new(1, 0, 0, 345)
ChatCard.BackgroundColor3 = Theme.Surface
ChatCard.BorderSizePixel = 0
ChatCard.Parent = ChatPage
uiCorner(ChatCard, 14)
uiStroke(ChatCard, Theme.Stroke, 1, 0.45)

local ChatHeader = Instance.new("Frame")
ChatHeader.Size = UDim2.new(1, 0, 0, 48)
ChatHeader.BackgroundColor3 = Theme.Surface2
ChatHeader.BorderSizePixel = 0
ChatHeader.Parent = ChatCard
uiCorner(ChatHeader, 14)

local HeaderPatch = Instance.new("Frame")
HeaderPatch.Size = UDim2.new(1, 0, 0, 14)
HeaderPatch.Position = UDim2.new(0, 0, 1, -14)
HeaderPatch.BackgroundColor3 = Theme.Surface2
HeaderPatch.BorderSizePixel = 0
HeaderPatch.Parent = ChatHeader

local ChatTitle = label(ChatHeader, "Chat Global", 12, Theme.Text, Enum.Font.GothamBold)
ChatTitle.Position = UDim2.new(0, 12, 0, 8)
ChatTitle.Size = UDim2.new(1, -24, 0, 16)

local ChatSub = label(
    ChatHeader,
    "Mostra os dias da conta e envia pelo sistema de chat do jogo.",
    8,
    Theme.Muted,
    Enum.Font.Gotham
)
ChatSub.Position = UDim2.new(0, 12, 0, 27)
ChatSub.Size = UDim2.new(1, -24, 0, 13)

local MessageScroll = Instance.new("ScrollingFrame")
MessageScroll.Name = "MessageContainer"
MessageScroll.Position = UDim2.new(0, 10, 0, 58)
MessageScroll.Size = UDim2.new(1, -20, 1, -112)
MessageScroll.BackgroundColor3 = Color3.fromRGB(13, 15, 22)
MessageScroll.BorderSizePixel = 0
MessageScroll.ScrollBarThickness = 3
MessageScroll.ScrollBarImageColor3 = Theme.Accent
MessageScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MessageScroll.Parent = ChatCard
uiCorner(MessageScroll, 11)
uiStroke(MessageScroll, Theme.Stroke, 1, 0.6)
uiPadding(MessageScroll, 8, 8, 8, 8)

local MessageLayout = Instance.new("UIListLayout")
MessageLayout.SortOrder = Enum.SortOrder.LayoutOrder
MessageLayout.Padding = UDim.new(0, 6)
MessageLayout.Parent = MessageScroll

MessageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MessageScroll.CanvasSize = UDim2.new(0, 0, 0, MessageLayout.AbsoluteContentSize.Y + 16)
    task.defer(function()
        local maxY = math.max(0, MessageLayout.AbsoluteContentSize.Y - MessageScroll.AbsoluteWindowSize.Y + 18)
        MessageScroll.CanvasPosition = Vector2.new(0, maxY)
    end)
end)

local ChatInput = Instance.new("TextBox")
ChatInput.Position = UDim2.new(0, 10, 1, -44)
ChatInput.Size = UDim2.new(1, -64, 0, 34)
ChatInput.BackgroundColor3 = Theme.Surface2
ChatInput.BorderSizePixel = 0
ChatInput.PlaceholderText = "Digite sua mensagem..."
ChatInput.PlaceholderColor3 = Theme.Dim
ChatInput.Text = ""
ChatInput.TextColor3 = Theme.Text
ChatInput.TextSize = 10
ChatInput.Font = Enum.Font.Gotham
ChatInput.TextXAlignment = Enum.TextXAlignment.Left
ChatInput.ClearTextOnFocus = false
ChatInput.Parent = ChatCard
uiCorner(ChatInput, 10)
uiStroke(ChatInput, Theme.Stroke, 1, 0.55)
uiPadding(ChatInput, 10, 8, 0, 0)

local SendBtn = Instance.new("TextButton")
SendBtn.Position = UDim2.new(1, -46, 1, -44)
SendBtn.Size = UDim2.new(0, 36, 0, 34)
SendBtn.BackgroundColor3 = Theme.Accent
SendBtn.BorderSizePixel = 0
SendBtn.Text = "➤"
SendBtn.TextColor3 = Theme.Text
SendBtn.TextSize = 13
SendBtn.Font = Enum.Font.GothamBold
SendBtn.AutoButtonColor = false
SendBtn.Parent = ChatCard
uiCorner(SendBtn, 10)
makeHover(SendBtn, Theme.Accent, Theme.Accent2, Theme.AccentSoft)

local function createChatMessage(player, message, system)
    local container = Instance.new("Frame")
    container.Name = "ChatMessage"
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.Parent = MessageScroll

    local bubble = Instance.new("Frame")
    bubble.Size = UDim2.new(1, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.BackgroundColor3 = system and Color3.fromRGB(35, 31, 55) or Theme.Surface2
    bubble.BorderSizePixel = 0
    bubble.Parent = container
    uiCorner(bubble, 9)
    uiPadding(bubble, 9, 9, 7, 7)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = bubble

    local header = Instance.new("TextLabel")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 14)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextYAlignment = Enum.TextYAlignment.Center
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 8
    header.RichText = false
    header.Parent = bubble

    if system then
        header.Text = "SISTEMA"
        header.TextColor3 = Theme.Warning
    else
        local days = player and player.AccountAge or 0
        local name = player and player.Name or "Desconhecido"
        header.Text = "[" .. tostring(days) .. "d]  " .. name
        header.TextColor3 = getPlayerNameColor(player)
    end

    local body = Instance.new("TextLabel")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Text = tostring(message)
    body.TextColor3 = Theme.Text
    body.TextSize = 10
    body.Font = Enum.Font.Gotham
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = bubble

    table.insert(chatMessages, container)

    if not system and (activePage ~= "Chat" or isMinimized) then
        unreadChatCount += 1
        if updateChatBadge then
            updateChatBadge()
        end
    end

    while #chatMessages > 40 do
        local oldest = table.remove(chatMessages, 1)
        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end
end

local function trySend()
    local text = ChatInput.Text
    if text == "" then return end

    local sent = sendChatMessage(text)
    if sent then
        ChatInput.Text = ""
    else
        createChatMessage(nil, "Não consegui enviar a mensagem pelo sistema de chat atual.", true)
    end
end

SendBtn.MouseButton1Click:Connect(trySend)

ChatInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        trySend()
    end
end)

local function setupChatListener()
    disconnectChatListeners()

    -- 1. Tenta chat legado
    local legacyFolder = nil
    local filtered = nil

    if ReplicatedStorage then
        legacyFolder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        filtered = legacyFolder and legacyFolder:FindFirstChild("OnMessageDoneFiltering")
    end

    if filtered and filtered:IsA("RemoteEvent") then
        local ok, connection = pcall(function()
            return filtered.OnClientEvent:Connect(function(data)
                if typeof(data) ~= "table" then
                    return
                end

                local speaker = data.FromSpeaker
                local msg = data.Message

                if not msg then
                    return
                end

                local player = nil
                if speaker and Players then
                    player = Players:FindFirstChild(tostring(speaker))
                end

                createChatMessage(player, tostring(msg), false)
            end)
        end)

        if ok and connection then
            table.insert(chatConnections, connection)
            createChatMessage(nil, "Chat legado conectado.", true)
            return
        end
    end

    -- 2. Tenta TextChatService moderno
    if TextChatService then
        local ok, connection = pcall(function()
            return TextChatService.MessageReceived:Connect(function(textChatMessage)
                if not textChatMessage then
                    return
                end

                local source = textChatMessage.TextSource
                local player = nil

                if source and Players then
                    pcall(function()
                        player = Players:GetPlayerByUserId(source.UserId)
                    end)
                end

                local msg = textChatMessage.Text
                if msg then
                    createChatMessage(player, tostring(msg), false)
                end
            end)
        end)

        if ok and connection then
            table.insert(chatConnections, connection)
            createChatMessage(nil, "TextChatService conectado.", true)
            return
        end
    end

    -- 3. Fallback: Player.Chatted
    local function hookPlayer(player)
        if not player then
            return
        end

        local ok, connection = pcall(function()
            return player.Chatted:Connect(function(msg)
                createChatMessage(player, tostring(msg), false)
            end)
        end)

        if ok and connection then
            table.insert(chatConnections, connection)
        end
    end

    if Players then
        for _, player in ipairs(Players:GetPlayers()) do
            hookPlayer(player)
        end

        local ok, connection = pcall(function()
            return Players.PlayerAdded:Connect(hookPlayer)
        end)

        if ok and connection then
            table.insert(chatConnections, connection)
        end
    end

    createChatMessage(nil, "Fallback de chat conectado.", true)
end

setupChatListener()

-- Como este módulo substitui o chat padrão, escondemos o chat nativo ao iniciar.
setNativeChatVisible(false)

createChatMessage(
    nil,
    "Hub iniciado. Seus dias de conta: " .. tostring(LocalPlayer.AccountAge),
    true
)

--------------------------------------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------------------------------------


do
local VisualSettings = section(SettingsPage, "Visual", "Personalize a experiência do hub")

local AnimationToggle = toggleRow(
    VisualSettings,
    "Animações",
    "Desative se quiser o hub mais leve.",
    true,
    function(state)
        UIState.animations = state
        notify("Interface", state and "Animações ativadas." or "Animações desativadas.", "success")
    end
)

local BlurToggle = toggleRow(
    VisualSettings,
    "Blur de fundo",
    "Aplica um leve desfoque enquanto o hub está aberto.",
    true,
    function(state)
        UIState.blur = state
        if HubBlur then
            HubBlur.Enabled = state
        end
    end
)

local ToastToggle = toggleRow(
    VisualSettings,
    "Notificações",
    "Mostra avisos discretos no canto da tela.",
    true,
    function(state)
        UIState.toasts = state
    end
)

end

local InterfaceSettings = section(SettingsPage, "Interface", "Preferências visuais e de chat")

local NativeChatToggle = toggleRow(
    InterfaceSettings,
    "Ocultar chat nativo",
    "Deixa somente o chat do Lordzy Hub na tela.",
    true,
    function(state)
        setNativeChatVisible(not state)
    end
)

local RestoreChatBtn = actionButton(
    InterfaceSettings,
    "Restaurar chat nativo",
    "Reativa o CoreGui de chat do Roblox.",
    Theme.Success
)
RestoreChatBtn.MouseButton1Click:Connect(function()
    setNativeChatVisible(true)
    NativeChatToggle.Set(false)
end)


local KeybindSettings = section(SettingsPage, "Atalhos", "Teclas rápidas do hub")

local HubBindBtn = Instance.new("TextButton")
HubBindBtn.Size = UDim2.new(1, 0, 0, 46)
HubBindBtn.BackgroundColor3 = Theme.Surface2
HubBindBtn.BorderSizePixel = 0
HubBindBtn.Text = ""
HubBindBtn.AutoButtonColor = false
HubBindBtn.Parent = KeybindSettings
uiCorner(HubBindBtn, 11)
uiStroke(HubBindBtn, Theme.Stroke, 1, 0.55)
makeHover(HubBindBtn, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)

local HubBindTitle = label(HubBindBtn, "Esconder / mostrar Hub", 10, Theme.Text, Enum.Font.GothamSemibold)
HubBindTitle.Position = UDim2.new(0, 12, 0, 7)
HubBindTitle.Size = UDim2.new(1, -90, 0, 15)

local HubBindHint = label(HubBindBtn, "Clique para alterar", 8, Theme.Muted, Enum.Font.Gotham)
HubBindHint.Position = UDim2.new(0, 12, 0, 25)
HubBindHint.Size = UDim2.new(1, -90, 0, 13)

local HubBindBadge = Instance.new("TextLabel")
HubBindBadge.Size = UDim2.new(0, 64, 0, 28)
HubBindBadge.Position = UDim2.new(1, -76, 0.5, -14)
HubBindBadge.BackgroundColor3 = Theme.AccentSoft
HubBindBadge.BorderSizePixel = 0
HubBindBadge.Text = hubToggleKey.Name
HubBindBadge.TextColor3 = Theme.Text
HubBindBadge.TextSize = 9
HubBindBadge.Font = Enum.Font.GothamBold
HubBindBadge.Parent = HubBindBtn
uiCorner(HubBindBadge, 8)

HubBindBtn.MouseButton1Click:Connect(function()
    listeningHubKey = true
    listeningChatKey = false
    HubBindHint.Text = "Pressione uma tecla..."
    HubBindHint.TextColor3 = Theme.Warning
    HubBindBadge.Text = "..."
end)

local ChatBindBtn = Instance.new("TextButton")
ChatBindBtn.Size = UDim2.new(1, 0, 0, 46)
ChatBindBtn.BackgroundColor3 = Theme.Surface2
ChatBindBtn.BorderSizePixel = 0
ChatBindBtn.Text = ""
ChatBindBtn.AutoButtonColor = false
ChatBindBtn.Parent = KeybindSettings
uiCorner(ChatBindBtn, 11)
uiStroke(ChatBindBtn, Theme.Stroke, 1, 0.55)
makeHover(ChatBindBtn, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)

local ChatBindTitle = label(ChatBindBtn, "Abrir Chat diretamente", 10, Theme.Text, Enum.Font.GothamSemibold)
ChatBindTitle.Position = UDim2.new(0, 12, 0, 7)
ChatBindTitle.Size = UDim2.new(1, -90, 0, 15)

local ChatBindHint = label(ChatBindBtn, "Abre e foca a caixa de mensagem", 8, Theme.Muted, Enum.Font.Gotham)
ChatBindHint.Position = UDim2.new(0, 12, 0, 25)
ChatBindHint.Size = UDim2.new(1, -90, 0, 13)

local ChatBindBadge = Instance.new("TextLabel")
ChatBindBadge.Size = UDim2.new(0, 64, 0, 28)
ChatBindBadge.Position = UDim2.new(1, -76, 0.5, -14)
ChatBindBadge.BackgroundColor3 = Theme.AccentSoft
ChatBindBadge.BorderSizePixel = 0
ChatBindBadge.Text = chatOpenKey.Name
ChatBindBadge.TextColor3 = Theme.Text
ChatBindBadge.TextSize = 9
ChatBindBadge.Font = Enum.Font.GothamBold
ChatBindBadge.Parent = ChatBindBtn
uiCorner(ChatBindBadge, 8)

ChatBindBtn.MouseButton1Click:Connect(function()
    listeningChatKey = true
    listeningHubKey = false
    ChatBindHint.Text = "Pressione uma tecla..."
    ChatBindHint.TextColor3 = Theme.Warning
    ChatBindBadge.Text = "..."
end)

local UtilitySettings = section(SettingsPage, "Hub", "Controles gerais")

local ReconnectChatBtn = actionButton(
    UtilitySettings,
    "Reconectar listener do chat",
    "Reconstrói os eventos usados para receber mensagens.",
    Theme.Accent2
)
ReconnectChatBtn.MouseButton1Click:Connect(function()
    setupChatListener()
end)


--------------------------------------------------------------------------------
-- ACESSO RÁPIDO AO CHAT
--------------------------------------------------------------------------------

local QuickChatBtn = Instance.new("TextButton")
QuickChatBtn.Name = "QuickChatButton"
QuickChatBtn.Size = UDim2.new(0, 48, 0, 48)
QuickChatBtn.Position = UDim2.new(0, 18, 1, -72)
QuickChatBtn.BackgroundColor3 = Theme.Surface2
QuickChatBtn.BorderSizePixel = 0
QuickChatBtn.Text = "💬"
QuickChatBtn.TextColor3 = Theme.Text
QuickChatBtn.TextSize = 18
QuickChatBtn.Font = Enum.Font.GothamBold
QuickChatBtn.AutoButtonColor = false
QuickChatBtn.Parent = ControllerGui
uiCorner(QuickChatBtn, 14)
uiStroke(QuickChatBtn, Theme.Accent, 1.2, 0.15)
makeHover(QuickChatBtn, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)

local ChatBadge = Instance.new("TextLabel")
ChatBadge.Size = UDim2.new(0, 18, 0, 18)
ChatBadge.Position = UDim2.new(1, -8, 0, -6)
ChatBadge.BackgroundColor3 = Theme.Danger
ChatBadge.BorderSizePixel = 0
ChatBadge.Text = ""
ChatBadge.Visible = false
ChatBadge.Parent = QuickChatBtn
uiCorner(ChatBadge, 99)

updateChatBadge = function()
    ChatBadge.Visible = unreadChatCount > 0
    ChatBadge.Text = unreadChatCount > 9 and "9+" or tostring(unreadChatCount)
    ChatBadge.TextColor3 = Theme.Text
    ChatBadge.TextSize = 8
    ChatBadge.Font = Enum.Font.GothamBold
end

local function openChatDirect(focusInput)
    if isMinimized then
        -- restoreHub é declarado depois; o botão também lida com isso via task.defer.
        task.defer(function()
            if restoreHub then
                restoreHub()
            end
        end)
    end

    setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
    unreadChatCount = 0
    updateChatBadge()

    if focusInput then
        task.delay(0.08, function()
            if ChatInput and ChatInput.Parent then
                ChatInput:CaptureFocus()
            end
        end)
    end
end

QuickChatBtn.MouseButton1Click:Connect(function()
    openChatDirect(true)
end)

--------------------------------------------------------------------------------
-- MINIMIZAR + BOTÃO FLUTUANTE
--------------------------------------------------------------------------------

local Floating = Instance.new("TextButton")
Floating.Name = "FloatingOpenButton"
Floating.Size = UDim2.new(0, 48, 0, 48)
Floating.Position = UDim2.new(0, 18, 0.5, -24)
Floating.BackgroundColor3 = Theme.Accent
Floating.BorderSizePixel = 0
Floating.Text = "L"
Floating.TextColor3 = Theme.Text
Floating.TextSize = 17
Floating.Font = Enum.Font.GothamBold
Floating.AutoButtonColor = false
Floating.Visible = false
Floating.Parent = ControllerGui
uiCorner(Floating, 14)
uiStroke(Floating, Theme.Accent2, 1, 0.25)
makeHover(Floating, Theme.Accent, Theme.Accent2, Theme.AccentSoft)

Floating.Visible = false


local FloatingHint = Instance.new("TextLabel")
FloatingHint.AnchorPoint = Vector2.new(0.5, 1)
FloatingHint.Position = UDim2.new(0.5, 0, 0, -5)
FloatingHint.Size = UDim2.new(0, 110, 0, 18)
FloatingHint.BackgroundColor3 = Theme.Surface
FloatingHint.BackgroundTransparency = 0.08
FloatingHint.BorderSizePixel = 0
FloatingHint.Text = "RightShift = Hub"
FloatingHint.TextColor3 = Theme.Muted
FloatingHint.TextSize = 8
FloatingHint.Font = Enum.Font.GothamMedium
FloatingHint.Visible = false
FloatingHint.Parent = Floating
uiCorner(FloatingHint, 7)

FloatingHint.Visible = false

local function minimizeHub()
    if isMinimized then return end
    isMinimized = true

    Main.Visible = false
    Shadow.Visible = false
    QuickChatBtn.Visible = false
    if HubBlur then HubBlur.Enabled = false end

    Floating.Visible = false
    FloatingHint.Visible = false
end

restoreHub = function()
    if not isMinimized then return end
    isMinimized = false

    Main.Visible = true
    Shadow.Visible = true
    QuickChatBtn.Visible = false
    if HubBlur then HubBlur.Enabled = UIState.blur end

    Floating.Visible = false
    FloatingHint.Visible = false
end

MinimizeBtn.MouseButton1Click:Connect(function()
    if isMinimized then
        restoreHub()
    else
        minimizeHub()
    end
end)

Floating.MouseButton1Click:Connect(restoreHub)

requestHideHub = minimizeHub

-- Atalhos globais ultra-compatíveis
-- RightShift = esconder/mostrar hub
-- Slash = abrir chat

local hubKeyHeld = false
local chatKeyHeld = false

local function toggleHubVisibility()
    if isMinimized then
        restoreHub()
    else
        minimizeHub()
    end
end

local function openChatFromBind()
    if isMinimized then
        restoreHub()
    end

    setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
    unreadChatCount = 0
    updateChatBadge()

    task.delay(0.05, function()
        if ChatInput and ChatInput.Parent then
            pcall(function()
                ChatInput:CaptureFocus()
            end)
        end
    end)
end

-- Método 1: evento normal
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if listeningHubKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            hubToggleKey = input.KeyCode
            listeningHubKey = false
            HubBindBadge.Text = hubToggleKey.Name
            HubBindHint.Text = "Clique para alterar"
            HubBindHint.TextColor3 = Theme.Muted
        end
        return
    end

    if listeningChatKey then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            chatOpenKey = input.KeyCode
            listeningChatKey = false
            ChatBindBadge.Text = chatOpenKey.Name
            ChatBindHint.Text = "Abre e foca a caixa de mensagem"
            ChatBindHint.TextColor3 = Theme.Muted
        end
        return
    end

    if UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == hubToggleKey then
        toggleHubVisibility()
        hubKeyHeld = true
        return
    end

    if input.KeyCode == chatOpenKey then
        openChatFromBind()
        chatKeyHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if input.KeyCode == hubToggleKey then
        hubKeyHeld = false
    elseif input.KeyCode == chatOpenKey then
        chatKeyHeld = false
    end
end)

-- Método 2: polling de backup para executores que não disparam InputBegan corretamente
RunService.RenderStepped:Connect(function()
    if UserInputService:GetFocusedTextBox() then
        return
    end

    local hubDown = UserInputService:IsKeyDown(hubToggleKey)
    if hubDown and not hubKeyHeld then
        hubKeyHeld = true
        toggleHubVisibility()
    elseif not hubDown then
        hubKeyHeld = false
    end

    local chatDown = UserInputService:IsKeyDown(chatOpenKey)
    if chatDown and not chatKeyHeld then
        chatKeyHeld = true
        openChatFromBind()
    elseif not chatDown then
        chatKeyHeld = false
    end
end)


--------------------------------------------------------------------------------
-- QUICK DOCK
--------------------------------------------------------------------------------

do
local QuickDock = Instance.new("Frame")
QuickDock.Name = "QuickDock"
QuickDock.AnchorPoint = Vector2.new(0.5, 0)
QuickDock.Position = UDim2.new(0.5, 0, 0, 2)
QuickDock.Size = UDim2.new(0, 238, 0, 38)
QuickDock.BackgroundColor3 = Theme.Surface
QuickDock.BackgroundTransparency = 0.12
QuickDock.BorderSizePixel = 0
QuickDock.ZIndex = 50
QuickDock.Parent = ControllerGui
uiCorner(QuickDock, 13)
uiStroke(QuickDock, Theme.Stroke, 1, 0.35)

local DockLayout = Instance.new("UIListLayout")
DockLayout.FillDirection = Enum.FillDirection.Horizontal
DockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
DockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
DockLayout.Padding = UDim.new(0, 7)
DockLayout.Parent = QuickDock

local function dockButton(symbol, tooltip)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 47, 0, 26)
    b.BackgroundColor3 = Theme.Surface2
    b.BorderSizePixel = 0
    b.Text = symbol
    b.TextColor3 = Theme.Text
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.ZIndex = 51
    b.Parent = QuickDock
    b:SetAttribute("Tooltip", tooltip)
    uiCorner(b, 10)
    makeHover(b, Theme.Surface2, Theme.Surface3, Theme.AccentSoft)
    return b
end

local DockHome = dockButton("⌂", "Home")
local DockRide = dockButton("◆", "Ride A Pet")
local DockChat = dockButton("◈", "Chat")
local DockHide = dockButton("—", "Ocultar")


if not IS_RIDE_A_PET then
    DockRide.Visible = false
end

DockHome.MouseButton1Click:Connect(function()
    if isMinimized then restoreHub() end
    setPage("Home", "Home", "Visão geral do hub")
end)

DockRide.MouseButton1Click:Connect(function()
    if isMinimized then restoreHub() end
    setPage("Ride", "Ride A Pet", "ESP, teleport e automações")
end)

DockChat.MouseButton1Click:Connect(function()
    if isMinimized then restoreHub() end
    setPage("Chat", "Chat Global", "Chat customizado com idade da conta")
    task.delay(0.05, function()
        if ChatInput and ChatInput.Parent then ChatInput:CaptureFocus() end
    end)
end)

DockHide.MouseButton1Click:Connect(function()
    if isMinimized then
        restoreHub()
    else
        minimizeHub()
    end
end)

end

--------------------------------------------------------------------------------
-- DRAG ABSOLUTO
--------------------------------------------------------------------------------





-- O drag não depende mais dos eventos do TopBar.
-- Ele verifica se o clique real do mouse caiu dentro da área superior da janela.
do
local dragging = false
local dragStartMouse = Vector2.zero
local dragStartPos = Main.Position

local function mouseInsideTopBar(mousePos)
    if not Main.Visible then
        return false
    end

    local pos = TopBar.AbsolutePosition
    local size = TopBar.AbsoluteSize

    -- Deixa a área do botão minimizar de fora.
    local rightLimit = pos.X + size.X - 58

    return mousePos.X >= pos.X
        and mousePos.X <= rightLimit
        and mousePos.Y >= pos.Y
        and mousePos.Y <= pos.Y + size.Y
end

local function beginAbsoluteDrag(mousePos)
    if isMinimized then return end
    if not mouseInsideTopBar(mousePos) then return end

    dragging = true
    dragStartMouse = mousePos
    dragStartPos = Main.Position
end

-- Mouse
UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        beginAbsoluteDrag(Vector2.new(mousePos.X, mousePos.Y))
    elseif input.UserInputType == Enum.UserInputType.Touch then
        beginAbsoluteDrag(Vector2.new(input.Position.X, input.Position.Y))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not dragging or isMinimized or not Main.Visible then
        return
    end

    local mousePos = UserInputService:GetMouseLocation()
    local current = Vector2.new(mousePos.X, mousePos.Y)
    local delta = current - dragStartMouse

    local newPos = UDim2.new(
        dragStartPos.X.Scale,
        dragStartPos.X.Offset + delta.X,
        dragStartPos.Y.Scale,
        dragStartPos.Y.Offset + delta.Y
    )

    Main.Position = newPos
    Shadow.Position = newPos
end)

-- Touch
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.Touch then
        local current = Vector2.new(input.Position.X, input.Position.Y)
        local delta = current - dragStartMouse

        local newPos = UDim2.new(
            dragStartPos.X.Scale,
            dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + delta.Y
        )

        Main.Position = newPos
        Shadow.Position = newPos
    end
end)

end


--------------------------------------------------------------------------------
-- POP SHELL
--------------------------------------------------------------------------------

do
    Sidebar.Visible = false
    SideDivider.Visible = false

    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.Size = UDim2.new(1, 0, 0, 62)

    TopLine.Position = UDim2.new(0, 0, 0, 61)
    TopLine.Size = UDim2.new(1, 0, 0, 1)

    ContentRoot.Position = UDim2.new(0, 0, 0, 62)
    ContentRoot.Size = UDim2.new(1, 0, 1, -62)

    PageTitle.Position = UDim2.new(0, 22, 0, 13)
    PageSub.Position = UDim2.new(0, 22, 0, 36)

    -- Keep the top bar minimal on the launcher.
    local function updatePopChrome()
        local onHome = activePage == "Home"

        if DragHint then
            DragHint.Visible = not onHome
        end

        local statusPill = TopBar:FindFirstChild("StatusPill")
        if statusPill then
            statusPill.Visible = not onHome
        end

        if PageTitle then
            PageTitle.Visible = not onHome
        end

        if PageSub then
            PageSub.Visible = not onHome
        end
    end

    local oldSetPage = setPage
    setPage = function(name, titleText, subtitleText)
        oldSetPage(name, titleText, subtitleText)
        updatePopChrome()
    end

    task.defer(updatePopChrome)
end


--------------------------------------------------------------------------------
-- MOBILE MINI MODE
--------------------------------------------------------------------------------

local function applyMobileMiniMode()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize

    UIState.compact = true
    UIState.blur = false

    if HubBlur then
        HubBlur.Enabled = false
    end

    -- Dedicated phone-size window: compact, centered, never desktop-sized.
    local targetW = math.clamp(math.floor(viewport.X * 0.82), 300, 380)
    local targetH = math.clamp(math.floor(viewport.Y * 0.44), 250, 330)

    Main.Size = UDim2.new(0, targetW, 0, targetH)
    Main.Position = UDim2.new(0.5, 0, 0.54, 0)
    Main.BackgroundTransparency = 0.015

    Shadow.Size = UDim2.new(0, targetW + 8, 0, targetH + 8)
    Shadow.Position = Main.Position
    Shadow.BackgroundTransparency = 0.78

    -- Very small header.
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopLine.Position = UDim2.new(0, 0, 0, 37)
    TopLine.Size = UDim2.new(1, 0, 0, 1)

    ContentRoot.Position = UDim2.new(0, 0, 0, 38)
    ContentRoot.Size = UDim2.new(1, 0, 1, -38)

    PageTitle.Position = UDim2.new(0, 12, 0, 4)
    PageTitle.TextSize = 11
    PageTitle.Size = UDim2.new(1, -90, 0, 15)

    PageSub.Position = UDim2.new(0, 12, 0, 19)
    PageSub.TextSize = 6
    PageSub.Size = UDim2.new(1, -90, 0, 10)

    DragHint.Visible = false

    MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
    MinimizeBtn.Position = UDim2.new(1, -56, 0, 7)
    MinimizeBtn.TextSize = 11

    local hideBtn = TopBar:FindFirstChild("HideBtn")
    if hideBtn then
        hideBtn.Size = UDim2.new(0, 24, 0, 24)
        hideBtn.Position = UDim2.new(1, -28, 0, 7)
        hideBtn.TextSize = 12
    end

    local statusPill = TopBar:FindFirstChild("StatusPill")
    if statusPill then
        statusPill.Visible = false
    end

    -- Tight page padding.
    for _, page in pairs(Pages) do
        local padding = page:FindFirstChildOfClass("UIPadding")
        if padding then
            padding.PaddingLeft = UDim.new(0, 7)
            padding.PaddingRight = UDim.new(0, 7)
            padding.PaddingTop = UDim.new(0, 7)
            padding.PaddingBottom = UDim.new(0, 7)
        end
    end

    -- On phone, do not show the large POP launcher at all.
    local launcher = HomePage:FindFirstChild("PopLauncher")
    if launcher then
        launcher.Visible = false
    end

    -- Compact top dock.
    QuickDock.Size = UDim2.new(0, IS_RIDE_A_PET and 178 or 132, 0, 26)
    QuickDock.Position = UDim2.new(0.5, 0, 0, 1)

    local dockLayout = QuickDock:FindFirstChildOfClass("UIListLayout")
    if dockLayout then
        dockLayout.Padding = UDim.new(0, 4)
    end

    for _, item in ipairs(QuickDock:GetChildren()) do
        if item:IsA("TextButton") then
            item.Size = UDim2.new(0, 34, 0, 19)
            item.TextSize = 9
        end
    end

    -- Make chat itself more space efficient on phones.
    if ChatCard then
        ChatCard.Size = UDim2.new(1, 0, 0, math.max(190, targetH - 60))
    end

    if MessageScroll then
        MessageScroll.Position = UDim2.new(0, 7, 0, 45)
        MessageScroll.Size = UDim2.new(1, -14, 1, -91)
        MessageScroll.ScrollBarThickness = 2
    end

    if ChatInput then
        ChatInput.TextSize = 10
    end

    -- Start on the most useful page for phone.
    if IS_RIDE_A_PET then
        setPage("Ride", "Ride A Pet", "Modo mobile")
    else
        setPage("Chat", "Chat Global", "Modo mobile universal")
    end
end

--------------------------------------------------------------------------------
-- RESPONSIVO BÁSICO
--------------------------------------------------------------------------------

do
local function applyResponsive()
    local camera = Workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize

    -- Automatic phone detection comes first.
    if IS_MOBILE or (UserInputService.TouchEnabled and viewport.X <= 900) then
        applyMobileMiniMode()
        return
    end

    if viewport.X < 760 then
        Main.Size = UDim2.new(0, math.min(620, viewport.X - 24), 0, math.min(460, viewport.Y - 40))
        Shadow.Size = UDim2.new(0, Main.Size.X.Offset + 20, 0, Main.Size.Y.Offset + 20)
        Sidebar.Visible = false
        TopBar.Position = UDim2.new(0, 0, 0, 0)
        TopBar.Size = UDim2.new(1, 0, 0, 62)
        TopLine.Position = UDim2.new(0, 0, 0, 61)
        TopLine.Size = UDim2.new(1, 0, 0, 1)
        ContentRoot.Position = UDim2.new(0, 0, 0, 62)
        ContentRoot.Size = UDim2.new(1, 0, 1, -62)
    end
end

applyResponsive()

pcall(function()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
    end
end)

end

--------------------------------------------------------------------------------
-- OPEN ANIMATION
--------------------------------------------------------------------------------

if IS_MOBILE then
    if IS_RIDE_A_PET then
        setPage("Ride", "Ride A Pet", "Modo mobile")
    elseif IS_TONGUE_ESCAPE then
        setPage("Tongue", "Tongue Escape", "Modo mobile")
    else
        setPage("Chat", "Chat Global", "Modo mobile universal")
    end
    notify("ZyroHub", "Modo mobile detectado automaticamente.", "success")
elseif IS_RIDE_A_PET then
    setPage("Home", "Home", "Visão geral do hub")
    notify("ZyroHub", "Ride A Pet detectado.", "success")
elseif IS_TONGUE_ESCAPE then
    setPage("Tongue", "Tongue Escape", "Farm, Auto Tongue e Auto Rebirth")
    notify("ZyroHub", "Tongue Escape detectado. Módulo carregado.", "success")
else
    setPage("Chat", "Chat Global", "Modo universal")
    notify("ZyroHub", "Modo universal: somente módulos compatíveis.", "success")
end

local finalMainSize = Main.Size
local finalShadowSize = Shadow.Size

Main.Size = UDim2.new(
    finalMainSize.X.Scale,
    math.max(300, finalMainSize.X.Offset - 45),
    finalMainSize.Y.Scale,
    math.max(260, finalMainSize.Y.Offset - 45)
)
Main.BackgroundTransparency = 1

Shadow.Size = UDim2.new(
    finalShadowSize.X.Scale,
    math.max(320, finalShadowSize.X.Offset - 45),
    finalShadowSize.Y.Scale,
    math.max(280, finalShadowSize.Y.Offset - 45)
)
Shadow.BackgroundTransparency = 1

tw(Main, 0.38, {
    Size = finalMainSize,
    BackgroundTransparency = 0
}, Enum.EasingStyle.Back)

tw(Shadow, 0.38, {
    Size = finalShadowSize,
    BackgroundTransparency = 0.48
}, Enum.EasingStyle.Back)



--------------------------------------------------------------------------------
-- CHANGELOG v12.7 + ATALHO DIRETO PARA EGG FILTER
--------------------------------------------------------------------------------
do
    local function goToEggFilter()
        setPage("Ride", "Ride A Pet", "Egg Browser • Server Hop por Egg")

        task.defer(function()
            task.wait(0.12)

            local pageTop = RidePage.AbsolutePosition.Y
            local eggTop = EggBrowser.AbsolutePosition.Y
            local currentY = RidePage.CanvasPosition.Y
            local targetY = math.max(0, currentY + (eggTop - pageTop) - 10)

            pcall(function()
                RidePage.CanvasPosition = Vector2.new(0, targetY)
            end)
        end)
    end

    local ChangelogOverlay = Instance.new("Frame")
    ChangelogOverlay.Name = "ChangelogOverlay_v127"
    ChangelogOverlay.Size = UDim2.fromScale(1, 1)
    ChangelogOverlay.BackgroundColor3 = Color3.fromRGB(4, 4, 8)
    ChangelogOverlay.BackgroundTransparency = 0.22
    ChangelogOverlay.BorderSizePixel = 0
    ChangelogOverlay.ZIndex = 200
    ChangelogOverlay.Parent = Main

    local ChangelogCard = Instance.new("Frame")
    ChangelogCard.Name = "ChangelogCard"
    ChangelogCard.AnchorPoint = Vector2.new(0.5, 0.5)
    ChangelogCard.Position = UDim2.fromScale(0.5, 0.5)
    ChangelogCard.Size = UDim2.new(0.78, 0, 0, 300)
    ChangelogCard.BackgroundColor3 = Theme.Surface
    ChangelogCard.BorderSizePixel = 0
    ChangelogCard.ZIndex = 201
    ChangelogCard.Parent = ChangelogOverlay
    uiCorner(ChangelogCard, 16)
    uiStroke(ChangelogCard, Theme.Accent, 1, 0.25)

    local Version = label(ChangelogCard, "NOVIDADES • v12.17", 9, Theme.Accent2, Enum.Font.GothamBold)
    Version.Position = UDim2.new(0, 18, 0, 16)
    Version.Size = UDim2.new(1, -36, 0, 18)
    Version.ZIndex = 202

    local Title = label(ChangelogCard, "Multi-Game • Tongue Escape", 16, Theme.Text, Enum.Font.GothamBold)
    Title.Position = UDim2.new(0, 18, 0, 39)
    Title.Size = UDim2.new(1, -36, 0, 27)
    Title.ZIndex = 202

    local Desc = label(
        ChangelogCard,
        "Novo visual inspirado na HTML 2097 POP e nas referências TimerMo: painel maior, vidro escuro, vermelho carmesim, cartões suaves e navegação mais limpa. Todas as funções da v12.14 foram mantidas.",
        9,
        Theme.Muted,
        Enum.Font.Gotham
    )
    Desc.Position = UDim2.new(0, 18, 0, 72)
    Desc.Size = UDim2.new(1, -36, 0, 40)
    Desc.TextWrapped = true
    Desc.ZIndex = 202

    local Changes = label(
        ChangelogCard,
        "✓ Layout central maior e mais limpo\n✓ Sidebar estilo painel de ferramenta\n✓ Paleta carvão + vermelho carmesim\n✓ Cards translúcidos e arredondados\n✓ Funções da v12.14 preservadas",
        10,
        Theme.Text,
        Enum.Font.GothamMedium
    )
    Changes.Position = UDim2.new(0, 18, 0, 121)
    Changes.Size = UDim2.new(1, -36, 0, 94)
    Changes.TextWrapped = true
    Changes.TextYAlignment = Enum.TextYAlignment.Top
    Changes.ZIndex = 202

    local GoButton = Instance.new("TextButton")
    GoButton.Name = "GoToEggFilter"
    GoButton.Size = UDim2.new(1, -36, 0, 42)
    GoButton.Position = UDim2.new(0, 18, 1, -58)
    GoButton.BackgroundColor3 = Theme.Accent
    GoButton.BorderSizePixel = 0
    GoButton.Text = "IR PARA O EGG FILTER  →"
    GoButton.TextColor3 = Color3.new(1, 1, 1)
    GoButton.TextSize = 10
    GoButton.Font = Enum.Font.GothamBold
    GoButton.AutoButtonColor = false
    GoButton.ZIndex = 202
    GoButton.Parent = ChangelogCard
    uiCorner(GoButton, 11)

    GoButton.MouseEnter:Connect(function()
        tw(GoButton, 0.14, {BackgroundColor3 = Theme.Accent2})
    end)

    GoButton.MouseLeave:Connect(function()
        tw(GoButton, 0.14, {BackgroundColor3 = Theme.Accent})
    end)

    GoButton.MouseButton1Click:Connect(function()
        ChangelogOverlay.Visible = false
        goToEggFilter()
    end)

    -- Abre o changelog já com o hub pronto.
    ChangelogOverlay.Visible = true
end


print("[ZYRO HUB v12.17 TONGUE ESCAPE] LOADED SUCCESSFULLY")
