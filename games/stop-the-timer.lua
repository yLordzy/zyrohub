local function fetch(path)
    local separator = path:find("?", 1, true) and "&" or "?"
    local url = BASE .. path .. separator .. "_zyro=" .. tostring(math.floor(os.clock() * 1000000))

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
