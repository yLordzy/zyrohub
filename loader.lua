-- ZYRO HUB LOADER v1.5 • GAME FIRST, SHARED CHAT LAST
if not game:IsLoaded() then game.Loaded:Wait() end

local BASE="https://raw.githubusercontent.com/yLordzy/zyrohub/refs/heads/main/"
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")

print("[ZYRO HUB LOADER v1.5] STARTING...")

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

-- 1. Cria a UI.
local UI=fetch("core/ui.lua")
getgenv().ZyroUI=UI

local routes={
    [124216119978534]={module="games/ride-a-pet.lua", defaultTab="Principal"},
    [122245938604556]={module="games/tongue-escape.lua", defaultTab="Farm"},
    [139988436996662]={module="games/stop-the-timer.lua", defaultTab="Auto Press"},
}

local function looksLikeStopTimer()
    local pg=Players.LocalPlayer:WaitForChild("PlayerGui",10)
    if not pg then return false end
    local g=pg:FindFirstChild("GameUI") or pg:FindFirstChild("PracticeUI")
    return g and g:FindFirstChild("SecondsToSet",true)~=nil
end

local route=routes[game.PlaceId]
if not route and looksLikeStopTimer() then
    route={module="games/stop-the-timer.lua", defaultTab="Auto Press"}
end

if not route then
    UI:Notify("ZyroHub","Jogo ainda não suportado. PlaceId: "..tostring(game.PlaceId),"warn")
    return
end

-- 2. O módulo do jogo vem ANTES.
-- SetGame() limpa/recria as tabs, então ele não pode rodar depois do Chat.
print("[ZyroHub Loader] Game module:",route.module)
fetch(route.module)

-- Preserve legacy/default content using the CORRECT name for each game.
-- Modules that already created real tabs are left untouched.
if UI.PromoteDefaultToTab then
    UI:PromoteDefaultToTab(route.defaultTab)
end

-- 3. Chat compartilhado vem POR ÚLTIMO.
fetch("core/chat.lua")

print("[ZYRO HUB LOADER v1.5] READY")
