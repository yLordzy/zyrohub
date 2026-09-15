-- ZYRO HUB LOADER v1.2 • CORE + CHAT + GAME
if not game:IsLoaded() then game.Loaded:Wait() end

local BASE="https://raw.githubusercontent.com/yLordzy/zyrohub/refs/heads/main/"
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")

print("[ZYRO HUB LOADER v1.2] STARTING...")

local function fetch(path)
    local sep=path:find("?",1,true) and "&" or "?"
    local url=BASE..path..sep.."_zyro="..HttpService:GenerateGUID(false)
    print("[ZyroHub Loader] Fetch:",path)
    local ok,src=pcall(function() return game:HttpGet(url,false) end)
    if not ok then error("[ZyroHub Loader] Falha ao baixar "..path..": "..tostring(src)) end
    local fn,err=loadstring(src)
    if not fn then error("[ZyroHub Loader] Erro compilando "..path..": "..tostring(err)) end
    return fn()
end

-- Compartilhados em todos os jogos
local UI=fetch("core/ui.lua")
getgenv().ZyroUI=UI
fetch("core/chat.lua")

local routes={
    [124216119978534]="games/ride-a-pet.lua",
    [122245938604556]="games/tongue-escape.lua",
    [139988436996662]="games/stop-the-timer.lua",
}

local function looksLikeStopTimer()
    local pg=Players.LocalPlayer:WaitForChild("PlayerGui",10)
    if not pg then return false end
    local g=pg:FindFirstChild("GameUI") or pg:FindFirstChild("PracticeUI")
    return g and g:FindFirstChild("SecondsToSet",true)~=nil
end

local module=routes[game.PlaceId]
if not module and looksLikeStopTimer() then module="games/stop-the-timer.lua" end

if not module then
    UI:Notify("ZyroHub","Jogo ainda não suportado. PlaceId: "..tostring(game.PlaceId),"warn")
    return
end

print("[ZyroHub Loader] Module:",module)
fetch(module)
print("[ZYRO HUB LOADER v1.2] READY")
