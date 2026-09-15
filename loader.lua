-- ZYRO HUB LOADER
if not game:IsLoaded() then game.Loaded:Wait() end

local BASE = "https://raw.githubusercontent.com/yLordzy/zyrohub/refs/heads/main/"
local Players = game:GetService("Players")

local function fetch(path)
    local ok, src = pcall(function()
        return game:HttpGet(BASE .. path, true)
    end)
    if not ok then error("[ZyroHub Loader] Falha ao baixar "..path..": "..tostring(src)) end
    local fn, err = loadstring(src)
    if not fn then error("[ZyroHub Loader] Erro compilando "..path..": "..tostring(err)) end
    return fn()
end

local UI = fetch("core/ui.lua")
getgenv().ZyroUI = UI

local routes = {
    [124216119978534] = "games/ride-a-pet.lua",
    [122245938604556] = "games/tongue-escape.lua",
}

local STOP_TIMER_HINTS = {"SecondsToSet","GameUI","PracticeUI"}

local function looksLikeStopTimer()
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then return false end
    local gui = pg:FindFirstChild("GameUI") or pg:FindFirstChild("PracticeUI")
    return gui and gui:FindFirstChild("SecondsToSet", true) ~= nil
end

local module = routes[game.PlaceId]
if not module and looksLikeStopTimer() then
    module = "games/stop-the-timer.lua"
end

if not module then
    UI:Notify("ZyroHub", "Jogo ainda não suportado.", "warn")
    warn("[ZyroHub Loader] Unsupported PlaceId:", game.PlaceId, "GameId:", game.GameId)
    return
end

print("[ZyroHub Loader] Loading:", module)
fetch(module)
