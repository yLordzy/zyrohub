-- ZYRO HUB • RIDE A PET
local UI=getgenv().ZyroUI
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local lp=Players.LocalPlayer
UI:SetGame("Ride A Pet","ESP, interação, eggs e utilidades")
if UI.PromoteDefaultToTab then UI:PromoteDefaultToTab("Principal") end

local state={esp=false,insta=false}
local function rendered() return WS:FindFirstChild("RenderedEggs") end
local function root() local c=lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function tp(obj)
    local r=root(); if not r or not obj then return end
    local cf=obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
    if cf then r.CFrame=cf*CFrame.new(0,3,0) end
end

UI:Toggle("Egg ESP","Destaca os eggs renderizados.",false,function(on)
    state.esp=on
    local f=rendered(); if not f then return end
    for _,e in ipairs(f:GetChildren()) do
        local h=e:FindFirstChild("ZyroEggESP")
        if on and not h then h=Instance.new("Highlight"); h.Name="ZyroEggESP"; h.FillTransparency=.55; h.OutlineTransparency=0; h.Parent=e
        elseif not on and h then h:Destroy() end
    end
end)

UI:Toggle("Insta Interact","Reduz HoldDuration de ProximityPrompts.",false,function(on)
    state.insta=on
    for _,v in ipairs(WS:GetDescendants()) do if v:IsA("ProximityPrompt") then v.HoldDuration=on and 0 or v.HoldDuration end end
end)

UI:Button("TP Home","Volta para o seu plot.",function()
    local plots=WS:FindFirstChild("Plots"); if not plots then return end
    for _,p in ipairs(plots:GetChildren()) do
        local owner=p:FindFirstChild("Data") and p.Data:FindFirstChild("Owner")
        if owner and tostring(owner.Value)==lp.Name then tp(p); break end
    end
end)

UI:Section("Egg Browser")
local f=rendered()
if f then
    for _,egg in ipairs(f:GetChildren()) do
        UI:Button(egg.Name,"Teleportar para este egg.",function() tp(egg) end)
    end
else
    UI:Button("Nenhum egg encontrado","RenderedEggs ainda não apareceu.",function() end)
end
