-- ZYRO HUB LOADER v1.6 • MULTI-GAME ROUTER
if not game:IsLoaded() then game.Loaded:Wait() end

local BASE="https://raw.githubusercontent.com/yLordzy/zyrohub/refs/heads/main/"
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")

print("[ZYRO HUB LOADER v1.6] STARTING...")

local function fetch(path)
    local sep=path:find("?",1,true) and "&" or "?"
    local url=BASE..path..sep.."_zyro="..HttpService:GenerateGUID(false)
    print("[ZyroHub Loader] Fetch:",path)

    local ok,src=pcall(function()
        return game:HttpGet(url,false)
    end)
    if not ok then
        error("[ZyroHub Loader] Falha ao baixar "..path..": "..tostring(src))
    end

    local fn,err=loadstring(src)
    if not fn then
        error("[ZyroHub Loader] Erro compilando "..path..": "..tostring(err))
    end

    return fn()
end

-- 1. UI compartilhada
local UI=fetch("core/ui.lua")
getgenv().ZyroUI=UI

-- Cada jogo aponta para seu próprio módulo.
-- As tabs são criadas PELO MÓDULO DO JOGO e não pelo loader.
local routes={
    [124216119978534]={
        name="Ride A Pet",
        module="games/ride-a-pet.lua",
        legacyTab="Principal"
    },

    [122245938604556]={
        name="Tongue Escape",
        module="games/tongue-escape.lua",
        legacyTab="Farm"
    },

    [139988436996662]={
        name="Stop The Timer",
        module="games/stop-the-timer.lua",
        legacyTab="Auto Press"
    },

    [109203247742910]={
        name="Swing For An Egg",
        module="games/swing-for-an-egg.lua",
        legacyTab="Teleports"
    },
}

-- Fallback do Stop The Timer caso o PlaceId mude.
local function looksLikeStopTimer()
    local pg=Players.LocalPlayer:WaitForChild("PlayerGui",10)
    if not pg then return false end

    local g=pg:FindFirstChild("GameUI") or pg:FindFirstChild("PracticeUI")
    return g and g:FindFirstChild("SecondsToSet",true)~=nil
end

local route=routes[game.PlaceId]

if not route and looksLikeStopTimer() then
    route={
        name="Stop The Timer",
        module="games/stop-the-timer.lua",
        legacyTab="Auto Press"
    }
end

if not route then
    UI:Notify(
        "ZyroHub",
        "Jogo ainda não suportado. PlaceId: "..tostring(game.PlaceId),
        "warn"
    )
    return
end

print("[ZyroHub Loader] Game:",route.name)
print("[ZyroHub Loader] Game module:",route.module)

-- 2. Módulo específico do jogo.
-- Ele é responsável pelas próprias tabs.
fetch(route.module)

-- Apenas compatibilidade com módulos antigos que ainda colocam
-- controles na página Default. Módulos com tabs próprias não são alterados.
if UI.PromoteDefaultToTab and route.legacyTab then
    UI:PromoteDefaultToTab(route.legacyTab)
end

-- 3. Chat compartilhado por último.
fetch("core/chat.lua")

print("[ZYRO HUB LOADER v1.6] READY • "..route.name)
