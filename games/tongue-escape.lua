-- ZYRO HUB • TONGUE ESCAPE
local UI=getgenv().ZyroUI
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local lp=Players.LocalPlayer
UI:SetGame("Tongue Escape","Farm, língua e rebirth")

local state={farm=false,tongue=false,rebirth=false}
local events=RS:FindFirstChild("Events")
local add=events and events:FindFirstChild("AddTongue")
local reb=events and events:FindFirstChild("RequestRebirth")

UI:Toggle("Auto Tongue","Dispara AddTongue continuamente.",false,function(on)
    state.tongue=on
    if on then task.spawn(function()
        while state.tongue do if add then pcall(function() add:FireServer() end) end task.wait(.03) end
    end) end
end)

UI:Toggle("Auto Rebirth","Tenta renascer automaticamente.",false,function(on)
    state.rebirth=on
    if on then task.spawn(function()
        while state.rebirth do if reb then pcall(function() reb:InvokeServer() end) end task.wait(1) end
    end) end
end)

UI:Toggle("Auto Farm","Mantém o personagem na área usada pelo script-base.",false,function(on)
    state.farm=on
    if on then task.spawn(function()
        while state.farm do
            local c=lp.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame=CFrame.new(math.random(-13195,-13190),506,-559) end
            task.wait(.05)
        end
    end) end
end)
