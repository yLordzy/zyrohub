-- ZYRO HUB LOADER v1.1 • CACHE FIX
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE = "https://raw.githubusercontent.com/yLordzy/zyrohub/refs/heads/main/"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

print("[ZYRO HUB LOADER v1.1] STARTING...")

-- Baixa sempre uma versão fresca do arquivo.
local function fetch(path)
    local separator = path:find("?", 1, true) and "&" or "?"
    local cacheBuster = HttpService:GenerateGUID(false)
    local url = BASE .. path .. separator .. "_zyro=" .. cacheBuster

    print("[ZyroHub Loader] Fetch:", path)

    local ok, src = pcall(function()
        return game:HttpGet(url, false)
    end)

    if not ok then
        error("[ZyroHub Loader] Falha ao baixar " .. path .. ": " .. tostring(src))
    end

    local fn, err = loadstring(src)

    if not fn then
        error("[ZyroHub Loader] Erro compilando " .. path .. ": " .. tostring(err))
    end

    return fn()
end

-- Core/UI compartilhada por todos os jogos.
local UI = fetch("core/ui.lua")
getgenv().ZyroUI = UI

-- PlaceIds conhecidos.
local routes = {
    [124216119978534] = "games/ride-a-pet.lua",
    [122245938604556] = "games/tongue-escape.lua",
    [139988436996662] = "games/stop-the-timer.lua",
}

-- Fallback do Stop The Timer caso o jogo use outro Place no futuro.
local function looksLikeStopTimer()
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
    if not pg then
        return false
    end

    local gameUI = pg:FindFirstChild("GameUI")
    local practiceUI = pg:FindFirstChild("PracticeUI")
    local gui = gameUI or practiceUI

    return gui and gui:FindFirstChild("SecondsToSet", true) ~= nil
end

local module = routes[game.PlaceId]

if not module and looksLikeStopTimer() then
    module = "games/stop-the-timer.lua"
    print("[ZyroHub Loader] Stop The Timer detectado por fallback.")
end

if not module then
    UI:Notify(
        "ZyroHub",
        "Jogo ainda não suportado. PlaceId: " .. tostring(game.PlaceId),
        "warn"
    )

    warn(
        "[ZyroHub Loader] Unsupported | PlaceId:",
        game.PlaceId,
        "| GameId:",
        game.GameId
    )

    return
end

print(
    "[ZyroHub Loader] PlaceId:",
    game.PlaceId,
    "| Module:",
    module
)

fetch(module)

print("[ZYRO HUB LOADER v1.1] MODULE LOADED:", module)
