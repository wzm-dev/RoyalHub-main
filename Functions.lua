
local S = {
    Players = game:GetService("Players"),
    Tween   = game:GetService("TweenService"),
    RS      = game:GetService("ReplicatedStorage"),
    WS      = game:GetService("Workspace"),
    Run     = game:GetService("RunService"),
    UI      = game:GetService("UserInputService"),
    Sound   = game:GetService("SoundService"),
}

local LP  = S.Players.LocalPlayer
local TS  = game:GetService("TeleportService")
local HTTP = game:GetService("HttpService")

-- Notify DIRETO do Rayfield (a UI registra _G.RH_Window no CreateWindow).
-- Zero indireção WindUI: title/content/duration são as props nativas do Gen2.
local function notify(title, msg, dur, icon)
    pcall(function()
        local win = _G.RH_Window
        if win and not win.unloaded then
            win:Notify({ title = title, content = msg, duration = dur or 3 })
        end
    end)
end

print("[RoyalHub] Functions.lua iniciando...")

------------------------------------------------------------------------
-- ESTADO GLOBAL (acessível pelo Source.lua via _G)
------------------------------------------------------------------------
_G.RH = _G.RH or {}
local G = _G.RH

-- Personagem
G.SpeedValue        = 16
G.JumpValue         = 50
G.GravityValue      = 196.2
G.NoClipEnabled     = false; G.NoClipConn = nil
G.FlyEnabled        = false; G.FlySpeed = 50
G.FlyConn = nil; G.FlyBV = nil; G.FlyBG = nil

-- Aimbot / FOV
G.AimbotEnabled     = { normal = false, rage = false }
G.FOVEnabled        = true     -- aimbot só pega alvo dentro do círculo
G.FOVRadius         = 120      -- raio em PIXELS
G.FOVShowCircle     = false    -- OFF no boot: a UI liga junto com o painel
G.FOVColor          = Color3.fromRGB(255, 255, 255)
G.FOVThickness      = 1
G.AimbotConns       = {}
G.TargetPart        = "Head"
G.MaxDistance       = 1500
G.UseTeamCheck      = true
G.UseWallCheck      = true
G.AimbotSmoothFactor = 0.15

-- Silent Aim / Prediction
G.SilentAimEnabled  = false
G.SilentAimPart     = "HumanoidRootPart"
G.HitPredEnabled    = false
G.PredictionAmount  = 1.0

-- Hitbox
G.HitboxEnabled     = false
G.HitboxSize        = 8
G.HitboxOriginals   = {}
G.HitboxConn        = nil
G.HitboxESPEnabled  = false

-- Anti-Ragdoll / Auto Parry
G.AntiRagEnabled    = false; G.AntiRagConn = nil
G.AutoParryEnabled  = false; G.AutoParryKey = Enum.KeyCode.Q
G.AutoParryDist     = 12;    G.AutoParryCooldown = false; G.AutoParryConn = nil

-- ESP
G.EspEnabled        = false
G.EspObjects        = {}
G.EspListeners      = {}
G.EspLinesEnabled   = false
G.EspLinesConn      = nil
G.EspLineDrawings   = {}

-- Loop TP / Fake TP
G.LoopTPEnabled     = false; G.LoopTPTarget = nil; G.LoopTPDelay = 1; G.LoopTPConn = nil
G.FakeTPEnabled     = false; G.FakeTPConn = nil; G.FakeTPDelay = 0.2; G.FakeTPDist = 3

-- Orbit
G.OrbitEnabled      = false; G.OrbitTarget = nil; G.OrbitSpeed = 1; G.OrbitRadius = 10; G.OrbitConn = nil

-- Spin
G.SpinEnabled       = false; G.SpinConn = nil

-- Emotes
G.LoopEmote         = false; G.CurrentEmoteTrack = nil; G.EmoteLoopConn = nil

-- Radar
G.RadarEnabled      = false; G.RadarRange = 150; G.RadarDots = {}; G.RadarConn = nil

-- IY features
G.GodEnabled        = false
G.InvisEnabled      = false
G.InfJumpEnabled    = false; G.InfJumpConn = nil
G.FullbrightEnabled = false; G.OrigLighting = {}
G.XrayEnabled       = false; G.XrayOriginals = {}
G.FreezeEnabled     = false
G.HoverNameEnabled  = false; G.HoverNameConns = {}; G.HoverNameBBs = {}
G.HeadSize          = 1
G.AntiAFKEnabled    = false; G.AntiAFKConn = nil
G.FreecamEnabled    = false; G.FreecamPart = nil; G.FreecamSpeed = 1; G.FreecamConns = {}
G.NoFogEnabled      = false; G.OrigFog = {}
G.ReachEnabled      = false; G.ReachSize = 10; G.ReachConn = nil
G.KillAuraEnabled   = false; G.KillAuraRange = 15; G.KillAuraConn = nil
G.ClickTPEnabled    = false; G.ClickTPConn = nil

-- Spectate
G.SpectateConn      = nil; G.SpectateOrigSubject = nil; G.SpectateOrigType = nil

-- Misc
G.AntiKickEnabled   = false
G.RemoteSpyEnabled  = false; G.RemoteLogs = {}
G.CopyTarget        = nil
G.AlreadyJoined     = {}

------------------------------------------------------------------------
-- TARGET PART (setters usados pela UI)
------------------------------------------------------------------------
function G.setTargetPart(partName)
    G.TargetPart = partName
end

function G.setSilentAimPart(partName)
    G.SilentAimPart = partName
end

------------------------------------------------------------------------
-- SPEED / JUMP / GRAVITY
------------------------------------------------------------------------
function G.setSpeed(v)
    G.SpeedValue = v
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end

function G.setJumpPower(v)
    G.JumpValue = v
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v end
end

function G.setGravity(v)
    workspace.Gravity = v
end

------------------------------------------------------------------------
-- TELEPORTE
------------------------------------------------------------------------
function G.tpToPlayerName(name)
    local t = S.Players:FindFirstChild(name)
    if not t or not t.Character then notify("TP", "Jogador não encontrado.", 3, "x") return end
    local r  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    if r and tr then r.CFrame = tr.CFrame * CFrame.new(0,0,-3) end
end

function G.bringPlayer(name)
    local t = S.Players:FindFirstChild(name)
    if not t or not t.Character then notify("Bring","Jogador não encontrado.",3,"x") return end
    local r  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    if r and tr then tr.CFrame = r.CFrame * CFrame.new(0,0,-3) end
end

------------------------------------------------------------------------
-- LOOP TP
------------------------------------------------------------------------
local function _doLoopTP()
    if G.LoopTPConn then G.LoopTPConn:Disconnect() end
    G.LoopTPConn = S.Run.Heartbeat:Connect(function()
        if not G.LoopTPEnabled or not G.LoopTPTarget then return end
        local t = S.Players:FindFirstChild(G.LoopTPTarget)
        if not t or not t.Character then
            notify("Loop TP","Alvo sumiu. Loop parado.",4,"alert-circle")
            G.LoopTPEnabled = false
            G.LoopTPConn:Disconnect(); G.LoopTPConn = nil
            return
        end
        G.tpToPlayerName(G.LoopTPTarget)
    end)
end

function G.toggleLoopTP(enabled)
    G.LoopTPEnabled = enabled
    if enabled then
        if not G.LoopTPTarget then
            notify("Loop TP","Selecione um jogador primeiro!",4,"alert-circle")
            G.LoopTPEnabled = false return
        end
        _doLoopTP()
    else
        if G.LoopTPConn then G.LoopTPConn:Disconnect() G.LoopTPConn = nil end
    end
end

------------------------------------------------------------------------
-- FAKE TP
------------------------------------------------------------------------
function G.toggleFakeTP(enabled)
    G.FakeTPEnabled = enabled
    if G.FakeTPConn then G.FakeTPConn:Disconnect() G.FakeTPConn = nil end
    if enabled then
        G.FakeTPConn = S.Run.Heartbeat:Connect(function()
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local orig = root.CFrame
            local off  = Vector3.new(math.random(-G.FakeTPDist,G.FakeTPDist),math.random(1,G.FakeTPDist),math.random(-G.FakeTPDist,G.FakeTPDist))
            root.CFrame = orig + off
            task.wait(G.FakeTPDelay)
            if root and root.Parent then root.CFrame = orig end
        end)
    else
    end
end

------------------------------------------------------------------------
-- SPECTATE
------------------------------------------------------------------------
function G.startSpectate(targetPlayer)
    if not targetPlayer or targetPlayer == LP then return end
    local cam = workspace.CurrentCamera
    G.SpectateOrigSubject = cam.CameraSubject
    G.SpectateOrigType    = cam.CameraType
    cam.CameraType = Enum.CameraType.Custom
    local function applyChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then cam.CameraSubject = hum end
    end
    if targetPlayer.Character then applyChar(targetPlayer.Character) end
    G.SpectateConn = targetPlayer.CharacterAdded:Connect(applyChar)
end

function G.stopSpectate()
    if G.SpectateConn then G.SpectateConn:Disconnect() G.SpectateConn = nil end
    local cam = workspace.CurrentCamera
    if G.SpectateOrigSubject then cam.CameraSubject = G.SpectateOrigSubject end
    if G.SpectateOrigType    then cam.CameraType    = G.SpectateOrigType    end
end

------------------------------------------------------------------------
-- ESP
------------------------------------------------------------------------
local function removeESP(p)
    if G.EspObjects[p] then
        for _, o in pairs(G.EspObjects[p]) do pcall(function() o:Destroy() end) end
        G.EspObjects[p] = nil
    end
end

function G.removeAllESP()
    for p in pairs(G.EspObjects) do removeESP(p) end
    G.EspObjects = {}
end

local function createESP(p)
    if p == LP or G.EspObjects[p] then return end
    local char = p.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    G.EspObjects[p] = {}
    local hl = Instance.new("Highlight")
    hl.Adornee = char; hl.FillColor = Color3.fromRGB(255,80,80)
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    table.insert(G.EspObjects[p], hl)
    local bb = Instance.new("BillboardGui")
    bb.Adornee = hrp; bb.Size = UDim2.new(0,150,0,30)
    bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true; bb.Parent = hrp
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = p.Name; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0; lbl.TextSize = 16; lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb
    table.insert(G.EspObjects[p], bb)
end

local function setupESPListeners(p)
    if G.EspListeners[p] then return end
    local c1 = p.CharacterAdded:Connect(function()
        task.wait(0.5); if G.EspEnabled then createESP(p) end
    end)
    local c2 = p.CharacterRemoving:Connect(function() removeESP(p) end)
    G.EspListeners[p] = {c1,c2}
end

for _, p in ipairs(S.Players:GetPlayers()) do setupESPListeners(p) end
S.Players.PlayerAdded:Connect(setupESPListeners)
S.Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    if G.EspListeners[p] then
        for _, c in pairs(G.EspListeners[p]) do c:Disconnect() end
        G.EspListeners[p] = nil
    end
end)

function G.toggleESP(enabled)
    G.EspEnabled = enabled
    if enabled then
        for _, p in ipairs(S.Players:GetPlayers()) do createESP(p) end
    else
        G.removeAllESP()
    end
end

------------------------------------------------------------------------
-- ESP LINES (Drawing API)
------------------------------------------------------------------------
local function _clearLines()
    for _, d in pairs(G.EspLineDrawings) do pcall(function() d:Remove() end) end
    G.EspLineDrawings = {}
    if G._EspLinesByPlayer then
        for _, d in pairs(G._EspLinesByPlayer) do pcall(function() d:Remove() end) end
        G._EspLinesByPlayer = nil
    end
    if G._EspLinesRemoveConn then
        G._EspLinesRemoveConn:Disconnect()
        G._EspLinesRemoveConn = nil
    end
end

function G.toggleEspLines(enabled)
    G.EspLinesEnabled = enabled
    if G.EspLinesConn then G.EspLinesConn:Disconnect() G.EspLinesConn = nil end
    _clearLines()
    if not enabled then return end

    -- UMA linha por jogador, criada 1x e só ATUALIZADA por frame.
    -- IMPORTANTE: Drawing NÃO tem .Parent (não é Instance) — nunca usar isso
    -- como teste de validade; se está no cache, a linha é válida.
    local perPlayer = {}
    G._EspLinesByPlayer = perPlayer

    local function removeLine(p)
        if perPlayer[p] then
            pcall(function() perPlayer[p]:Remove() end)
            perPlayer[p] = nil
        end
    end

    -- player saiu do jogo? remove a linha dele na hora
    G._EspLinesRemoveConn = S.Players.PlayerRemoving:Connect(removeLine)

    local function getLineFor(p)
        if perPlayer[p] then return perPlayer[p] end
        local ok, line = pcall(Drawing.new, "Line")
        if not ok then return nil end
        line.Visible = false
        line.Color = Color3.fromRGB(255,55,55)
        line.Thickness = 1
        perPlayer[p] = line
        return line
    end

    G.EspLinesConn = S.Run.RenderStepped:Connect(function()
        if not G.EspLinesEnabled then return end
        local cam = workspace.CurrentCamera
        local vp  = cam.ViewportSize
        local bot = Vector2.new(vp.X / 2, vp.Y)
        local seen = {}
        for _, player in ipairs(S.Players:GetPlayers()) do
            local line = getLineFor(player)
            if line then
                seen[player] = true
                local show = false
                if player ~= LP and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local hum = player.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local sp, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            show = true
                            line.From = bot
                            line.To = Vector2.new(sp.X, sp.Y)
                        end
                    end
                end
                line.Visible = show
            end
        end
        -- sobrou linha de player que saiu sem disparar PlayerRemoving? esconde
        for p, line in pairs(perPlayer) do
            if not seen[p] then line.Visible = false end
        end
    end)
end

------------------------------------------------------------------------
-- HITBOX VISUAL (SelectionBox)
------------------------------------------------------------------------
function G.toggleHitboxESP(enabled)
    G.HitboxESPEnabled = enabled
    local function applyToChar(char)
        if not char then return end
        -- Adornee = MODEL: o SelectionBox desenha o bounding box do
        -- personagem COMPLETO (não só a HRP/chest)
        local existing = char:FindFirstChild("RH_HitboxBox")
        if enabled and not existing then
            local sel = Instance.new("SelectionBox")
            sel.Name = "RH_HitboxBox"; sel.Adornee = char
            sel.Color3 = Color3.fromRGB(255,60,60); sel.LineThickness = 0.04
            sel.SurfaceTransparency = 0.75; sel.SurfaceColor3 = Color3.fromRGB(255,60,60)
            sel.Parent = char
        elseif not enabled and existing then
            existing:Destroy()
        end
    end
    -- aplica em TODOS os players agora (não só quem está na lista do expander)
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP then
            applyToChar(p.Character)
        end
    end
    -- e nos que spawnarem depois
    if G.HitboxESPConn then G.HitboxESPConn:Disconnect() G.HitboxESPConn = nil end
    if enabled then
        G.HitboxESPConn = S.Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(c)
                task.wait(0.5)
                if G.HitboxESPEnabled then applyToChar(c) end
            end)
        end)
        for _, p in ipairs(S.Players:GetPlayers()) do
            if p ~= LP then
                p.CharacterAdded:Connect(function(c)
                    task.wait(0.5)
                    if G.HitboxESPEnabled then applyToChar(c) end
                end)
            end
        end
    end
end

------------------------------------------------------------------------
-- NOCLIP
------------------------------------------------------------------------
function G.toggleNoClip(enabled)
    G.NoClipEnabled = enabled
    if enabled then
        if G.NoClipConn then G.NoClipConn:Disconnect() end
        G.NoClipConn = S.Run.Stepped:Connect(function()
            if not G.NoClipEnabled then return end
            local char = LP.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if G.NoClipConn then G.NoClipConn:Disconnect() G.NoClipConn = nil end
        local char = LP.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

------------------------------------------------------------------------
-- FLY
------------------------------------------------------------------------
function G.toggleFly(enabled)
    G.FlyEnabled = enabled
    local char = LP.Character
    if not char then notify("Fly","Personagem não carregado.",2,"x") return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if enabled then
        hum.PlatformStand = true
        G.FlyBV = Instance.new("BodyVelocity")
        G.FlyBV.MaxForce = Vector3.new(1e9,1e9,1e9); G.FlyBV.Velocity = Vector3.zero; G.FlyBV.Parent = root
        G.FlyBG = Instance.new("BodyGyro")
        G.FlyBG.MaxTorque = Vector3.new(1e9,1e9,1e9); G.FlyBG.P = 10000; G.FlyBG.Parent = root
        G.FlyConn = S.Run.RenderStepped:Connect(function()
            if not G.FlyEnabled then return end
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            if S.UI:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if S.UI:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if S.UI:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if S.UI:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if S.UI:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if S.UI:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            G.FlyBV.Velocity = (dir.Magnitude > 0) and dir.Unit * G.FlySpeed or Vector3.zero
            G.FlyBG.CFrame   = cam.CFrame
        end)
    else
        if G.FlyConn then G.FlyConn:Disconnect() G.FlyConn = nil end
        hum.PlatformStand = false
        if G.FlyBV then G.FlyBV:Destroy() G.FlyBV = nil end
        if G.FlyBG then G.FlyBG:Destroy() G.FlyBG = nil end
    end
end

------------------------------------------------------------------------
-- SPIN
------------------------------------------------------------------------
function G.toggleSpin(enabled)
    G.SpinEnabled = enabled
    if enabled then
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then notify("Spin","Personagem não carregado.",2,"x") G.SpinEnabled=false return end
        if G.SpinConn then G.SpinConn:Disconnect() end
        G.SpinConn = S.Run.Heartbeat:Connect(function(dt)
            if not G.SpinEnabled then return end
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(360*dt), 0) end
        end)
    else
        if G.SpinConn then G.SpinConn:Disconnect() G.SpinConn = nil end
    end
end

------------------------------------------------------------------------
-- FLING SPIN (método clássico: BAV eixo Y + BodyPosition segura no lugar;
-- colisão NORMAL — encostou num jogador, a física o arremessa.
-- sem noclip = sem cair no void, sem atravessar o alvo)
------------------------------------------------------------------------
G.FlingSpinEnabled  = false
G.FlingSpinConn     = nil
G.FlingSpinSpeed    = 5000

function G.toggleFlingSpin(enabled)
    G.FlingSpinEnabled = enabled
    if G.FlingSpinConn then
        G.FlingSpinConn:Disconnect()
        G.FlingSpinConn = nil
    end

    local char = LP.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))

    -- limpa restos de sessão anterior
    if root then
        local oldBav = root:FindFirstChild("RH_FlingBAV")
        if oldBav then oldBav:Destroy() end
        local oldBp  = root:FindFirstChild("RH_FlingBP")
        if oldBp then oldBp:Destroy() end
    end

    if not enabled then return end
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then
        notify("Fling Spin", "Personagem não carregado.", 2, "x")
        G.FlingSpinEnabled = false
        return
    end

    -- colisão LIGADA (sessões antigas podiam ter desligado)
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = true
        end
    end
    hum.AutoRotate = false

    local spd = G.FlingSpinSpeed or 5000

    -- BodyPosition: trava VOCÊ no lugar (não cai, não sai voando)
    local bp = Instance.new("BodyPosition")
    bp.Name       = "RH_FlingBP"
    bp.MaxForce   = Vector3.new(1e9, 1e9, 1e9)
    bp.P          = 10000
    bp.D          = 100
    bp.Position    = root.Position
    bp.Parent     = root

    -- BAV: giro MASSIVO no eixo Y (a "vibração" que arremessa na colisão)
    local bav = Instance.new("BodyAngularVelocity")
    bav.Name            = "RH_FlingBAV"
    bav.MaxTorque       = Vector3.new(0, math.huge, 0)
    bav.AngularVelocity = Vector3.new(0, spd, 0)
    bav.P               = math.huge
    bav.Parent          = root

    -- respawn re-aplica
    G.FlingSpinConn = S.Run.Heartbeat:Connect(function()
        if not G.FlingSpinEnabled then return end
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r and not r:FindFirstChild("RH_FlingBAV") and not r:FindFirstChild("RH_FlingBP") then
            G.toggleFlingSpin(true)
        end
    end)
end

------------------------------------------------------------------------
-- FLING PLAYER (one-shot: gira VOCÊ sobre o alvo, colisão faz o resto)
------------------------------------------------------------------------
function G.flingPlayer(target, power)
    if not target or not target.Character then
        notify("Fling", "Alvo inválido.", 2, "x")
        return
    end
    local myChar = LP.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local tRoot  = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
    local tHum   = target.Character:FindFirstChildOfClass("Humanoid")
    if not myRoot or not tRoot or not tHum or tHum.Health <= 0 then return end

    local vel = power or G.FlingSpinSpeed or 9000

    for _, v in ipairs(myChar:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = true
        end
    end
    myHum.AutoRotate = false

    local bp = Instance.new("BodyPosition")
    bp.Name     = "RH_FlingBP"
    bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bp.P        = 10000
    bp.D        = 100
    bp.Position = tRoot.Position + Vector3.new(0, 2, 0)
    bp.Parent   = myRoot

    local bav = Instance.new("BodyAngularVelocity")
    bav.Name            = "RH_FlingBAV"
    bav.MaxTorque       = Vector3.new(0, math.huge, 0)
    bav.AngularVelocity = Vector3.new(0, vel, 0)
    bav.P               = math.huge
    bav.Parent          = myRoot

    task.delay(0.6, function()
        if bp and bp.Parent then bp:Destroy() end
        if bav and bav.Parent then bav:Destroy() end
        if myHum and myHum.Parent then myHum.AutoRotate = true end
    end)
end

------------------------------------------------------------------------
-- ORBIT
------------------------------------------------------------------------
function G.toggleOrbit(enabled)
    G.OrbitEnabled = enabled
    if enabled then
        if not G.OrbitTarget then
            notify("Orbit","Selecione um jogador primeiro!",4,"alert-circle")
            G.OrbitEnabled = false return
        end
        if G.OrbitConn then G.OrbitConn:Disconnect() end
        G.OrbitConn = S.Run.Heartbeat:Connect(function()
            if not G.OrbitEnabled then return end
            local t = S.Players:FindFirstChild(G.OrbitTarget)
            if not t or not t.Character then
                notify("Orbit","Alvo sumiu.",3,"alert-circle")
                G.OrbitEnabled = false; G.OrbitConn:Disconnect(); G.OrbitConn = nil return
            end
            local tr   = t.Character:FindFirstChild("HumanoidRootPart")
            local char = LP.Character
            local r    = char and char:FindFirstChild("HumanoidRootPart")
            if not tr or not r then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
            local a   = tick() * G.OrbitSpeed
            local off = Vector3.new(math.cos(a)*G.OrbitRadius, 0, math.sin(a)*G.OrbitRadius)
            r.CFrame  = CFrame.lookAt(tr.Position + off, tr.Position)
        end)
    else
        if G.OrbitConn then G.OrbitConn:Disconnect() G.OrbitConn = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

------------------------------------------------------------------------
-- FOV CIRCLE (círculo de mira na tela)
------------------------------------------------------------------------
G.FovCircle = nil
G.FovCircleVisible = false

local function _ensureFovCircle()
    if G.FovCircle then return G.FovCircle end
    local ok, circle = pcall(Drawing.new, "Circle")
    if not ok then return nil end
    circle.Thickness     = 1
    circle.Filled       = false
    circle.NumSides      = 64
    circle.Radius        = G.FOVRadius
    circle.Visible       = false
    circle.Color         = Color3.fromRGB(255, 255, 255)
    G.FovCircle = circle
    return circle
end

local function _updateFovCircle()
    -- desligado? esconde (se existir) e NEM CRIA o Drawing
    -- -> círculo nunca existe antes da UI carregar
    if not G.FOVShowCircle then
        if G.FovCircle then G.FovCircle.Visible = false end
        return
    end
    local circle = _ensureFovCircle()
    if not circle then return end
    local cam = workspace.CurrentCamera
    local vp  = cam.ViewportSize
    circle.Position  = Vector2.new(vp.X / 2, vp.Y / 2)
    circle.Radius    = G.FOVRadius
    circle.Color     = G.FOVColor
    circle.Thickness = G.FOVThickness
    circle.Visible   = true
end

-- desenha o círculo junto do aimbot (RenderStepped, 1 conn só)
if not G._FovRenderConn then
    G._FovRenderConn = S.Run.RenderStepped:Connect(function() pcall(_updateFovCircle) end)
end

function G.setFovColor(c)     G.FOVColor = c end
function G.setFovThickness(v) G.FOVThickness = v end

------------------------------------------------------------------------
-- AIMBOT (com FOV: só pega alvo dentro do círculo)
------------------------------------------------------------------------
-- pega o ponto 2D (pixels) de uma posição 3D no mundo
local function worldToScreen(pos)
    local cam = workspace.CurrentCamera
    local sp, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen
end

-- distância em pixels do centro da tela
local function screenDistFromCenter(screenPos)
    local cam = workspace.CurrentCamera
    local vp  = cam.ViewportSize
    local dx  = screenPos.X - vp.X / 2
    local dy  = screenPos.Y - vp.Y / 2
    return math.sqrt(dx * dx + dy * dy)
end

-- alvo dentro do círculo de FOV?
local function isTargetInFOV(part)
    if not G.FOVEnabled then return true end -- FOV desligado = sem limite
    local sp, onScreen = worldToScreen(part.Position)
    if not onScreen then return false end
    return screenDistFromCenter(sp) <= G.FOVRadius
end

local function getClosestTarget()
    local cam = workspace.CurrentCamera
    -- com FOV: procuramos o mais próximo do CROSSHAIR (px), não do mundo (studs)
    local closest, bestDist = nil, math.huge
    local maxWorldDist      = G.MaxDistance
    local myTeam = LP.Team
    local myChar = LP.Character
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum  = p.Character:FindFirstChildOfClass("Humanoid")
            local part = p.Character:FindFirstChild(G.TargetPart)
            if hum and hum.Health > 0 and part then
                if not G.UseTeamCheck or not myTeam or p.Team ~= myTeam then
                    local worldDist = (cam.CFrame.Position - part.Position).Magnitude
                    if worldDist <= maxWorldDist then
                        if isTargetInFOV(part) then
                            local blocked = false
                            if G.UseWallCheck then
                                local rp = RaycastParams.new()
                                rp.FilterType = Enum.RaycastFilterType.Exclude
                                rp.FilterDescendantsInstances = {myChar}
                                local hit = workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position), rp)
                                blocked = hit ~= nil and not hit.Instance:IsDescendantOf(p.Character)
                            end
                            if not blocked then
                                local sp, _ = cam:WorldToViewportPoint(part.Position)
                                local d = screenDistFromCenter(sp)
                                if d < bestDist then bestDist = d; closest = p end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function G.toggleAimbot(mode)
    local enabled = G.AimbotEnabled[mode]
    if G.AimbotConns[mode] then G.AimbotConns[mode]:Disconnect() G.AimbotConns[mode] = nil end
    if enabled then
        G.AimbotConns[mode] = S.Run.Heartbeat:Connect(function()
            local t = getClosestTarget()
            G.CurrentAimTarget = t -- indicador lê daqui
            if not t then return end
            local cam  = workspace.CurrentCamera
            local part = t.Character and t.Character:FindFirstChild(G.TargetPart)
            if not part then return end
            local goal = G.getPredictedPos and G.getPredictedPos(part) or part.Position
            if mode == "normal" then
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, goal), G.AimbotSmoothFactor)
            else
                cam.CFrame = CFrame.new(cam.CFrame.Position, goal)
            end
        end)
    end
end

------------------------------------------------------------------------
-- SILENT AIM / HIT PREDICTION
------------------------------------------------------------------------
function G.getSilentTarget()
    local cam    = workspace.CurrentCamera
    local closest, bestDist = nil, math.huge
    local myTeam = LP.Team
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local isAlly = G.UseTeamCheck and myTeam and (p.Team == myTeam)
                if not isAlly then
                    local part = p.Character:FindFirstChild(G.SilentAimPart) or p.Character:FindFirstChild("HumanoidRootPart")
                    if part and isTargetInFOV(part) then
                        local _, onScreen = cam:WorldToViewportPoint(part.Position)
                        if onScreen then
                            -- mais próximo do crosshair (px), igual ao aimbot
                            local sp, _ = cam:WorldToViewportPoint(part.Position)
                            local d = screenDistFromCenter(sp)
                            if d < bestDist then bestDist = d; closest = part end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function G.getPredictedPos(part)
    if not part or not part.Parent then return part and part.Position end
    if not G.HitPredEnabled then return part.Position end
    local hrp = part.Parent:FindFirstChild("HumanoidRootPart")
    if not hrp then return part.Position end
    local ping = 0.1
    pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000 end)
    return part.Position + hrp.AssemblyLinearVelocity * (ping * G.PredictionAmount)
end

function G.toggleSilentAim(enabled)
    G.SilentAimEnabled = enabled
end

function G.toggleHitPred(enabled)
    G.HitPredEnabled = enabled
end

------------------------------------------------------------------------
-- HITBOX
------------------------------------------------------------------------
function G.applyHitboxes()
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and not G.HitboxOriginals[p] then
                G.HitboxOriginals[p] = hrp.Size
                hrp.Size = Vector3.new(G.HitboxSize,G.HitboxSize,G.HitboxSize)
                hrp.Transparency = 0.5; hrp.CanCollide = false
            end
        end
    end
end

function G.removeHitboxes()
    for p, sz in pairs(G.HitboxOriginals) do
        if p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Size = sz; hrp.Transparency = 1 end
        end
    end
    G.HitboxOriginals = {}
end

function G.toggleHitbox(enabled)
    G.HitboxEnabled = enabled
    if enabled then
        G.applyHitboxes()
        G.HitboxConn = S.Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function()
                task.wait(0.5); if G.HitboxEnabled then G.applyHitboxes() end
            end)
        end)
        for _, p in ipairs(S.Players:GetPlayers()) do
            if p ~= LP then
                p.CharacterAdded:Connect(function()
                    task.wait(0.5); if G.HitboxEnabled then G.applyHitboxes() end
                end)
            end
        end
    else
        G.removeHitboxes()
        if G.HitboxConn then G.HitboxConn:Disconnect() G.HitboxConn = nil end
    end
end

------------------------------------------------------------------------
-- ANTI-RAGDOLL
------------------------------------------------------------------------
function G.toggleAntiRagdoll(enabled)
    G.AntiRagEnabled = enabled
    if G.AntiRagConn then G.AntiRagConn:Disconnect() G.AntiRagConn = nil end
    if enabled then
        G.AntiRagConn = S.Run.Heartbeat:Connect(function()
            local char = LP.Character; if not char then return end
            local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local st   = hum:GetState()
            if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = false end
            end
        end)
    else
        local char = LP.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = true end
            end
        end
    end
end

------------------------------------------------------------------------
-- AUTO PARRY
------------------------------------------------------------------------
function G.toggleAutoParry(enabled)
    G.AutoParryEnabled = enabled
    if G.AutoParryConn then G.AutoParryConn:Disconnect() G.AutoParryConn = nil end
    if enabled then
        G.AutoParryConn = S.Run.Heartbeat:Connect(function()
            if G.AutoParryCooldown then return end
            local char = LP.Character; if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
            for _, p in ipairs(S.Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local er = p.Character:FindFirstChild("HumanoidRootPart")
                    if er and (root.Position - er.Position).Magnitude <= G.AutoParryDist then
                        local anim = p.Character:FindFirstChildOfClass("Humanoid")
                        anim = anim and anim:FindFirstChildOfClass("Animator")
                        if anim and #anim:GetPlayingAnimationTracks() > 0 then
                            G.AutoParryCooldown = true
                            pcall(function()
                                keypress(G.AutoParryKey.Value)
                                task.wait(0.05)
                                keyrelease(G.AutoParryKey.Value)
                            end)
                            task.delay(0.4, function() G.AutoParryCooldown = false end)
                        end
                    end
                end
            end
        end)
    else
    end
end

------------------------------------------------------------------------
-- COPY PLAYER LOOK
------------------------------------------------------------------------
function G.copyPlayerLook(target)
    if not target then notify("Copy Player","Selecione um jogador!",3,"alert-circle") return end
    local ok, desc = pcall(function() return S.Players:GetHumanoidDescriptionFromUserId(target.UserId) end)
    if not ok then notify("Copy Player","Erro ao buscar visual!",3,"x") return end
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local ok2, err = pcall(function() hum:ApplyDescription(desc) end)
    if ok2 then notify("Copy Player","Visual de "..target.Name.." copiado!",3,"solar:check-bold")
    else notify("Copy Player","Falhou: "..tostring(err),4,"x") end
end

------------------------------------------------------------------------
-- REJOIN / SERVER HOP
------------------------------------------------------------------------
function G.rejoinServer()
    local id  = game.PlaceId
    local job = game.JobId
    if job == "" then notify("Rejoin","Falhou: JobId vazio.",3,"x") return end
    pcall(function() TS:TeleportToPlaceInstance(id, job, LP) end)
end

function G.serverHop()
    local id      = game.PlaceId
    local cursor  = ""
    local servers = {}
    repeat
        local ok, res = pcall(function()
            local url = "https://games.roblox.com/v1/games/"..id.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url.."&cursor="..cursor end
            local raw = game:HttpGet(url)
            if not raw or raw == "" then return nil end
            return HTTP:JSONDecode(raw)
        end)
        if not ok or not res then
            notify("Hop","Erro ao buscar servidores.",4,"x")
            return
        end
        if res and res.data then
            for _, sv in ipairs(res.data) do
                if sv.playing < sv.maxPlayers and sv.id ~= game.JobId and not G.AlreadyJoined[sv.id] then
                    table.insert(servers, sv.id)
                end
            end
            cursor = res.nextPageCursor or ""
        else
            cursor = ""
        end
    until cursor == ""
    if #servers == 0 then
        notify("Hop","Nenhum server disponível.",4,"alert-circle")
        return
    end
    local sv = servers[math.random(1,#servers)]
    G.AlreadyJoined[sv] = true
    pcall(function() TS:TeleportToPlaceInstance(id, sv, LP) end)
end

------------------------------------------------------------------------
-- MINIMAP 2D v2 (mapa FIXO: blips nos lugares reais do mundo, norte pra cima;
-- VOCÊ é uma flecha no centro que gira pra onde a câmera olha)
------------------------------------------------------------------------
G.RadarEnabled      = false
G.RadarRange        = 150
G.RadarShowNames    = true
G.RadarShowTeam     = true
G.RadarSize         = 220
G.RadarGui          = nil
G.RadarConn         = nil
G._RadarBlips       = {}
G._RadarRoot        = nil
G._RadarArrow       = nil
G._RadarRangeLbl    = nil

local function _radarDestroy()
    if G._RadarBlips then
        for _, b in pairs(G._RadarBlips) do
            pcall(function() b.frame:Destroy() end)
            if b.label then pcall(function() b.label:Destroy() end) end
        end
    end
    G._RadarBlips = {}
    if G.RadarGui then
        pcall(function() G.RadarGui:Destroy() end)
        G.RadarGui = nil
    end
end

local function _radarBuild()
    _radarDestroy()

    local gui = Instance.new("ScreenGui")
    gui.Name = "RoyalHubMinimap"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 5
    local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
    G.RadarGui = gui

    local S = G.RadarSize

    -- painel: canto INFERIOR direito
    local root = Instance.new("Frame")
    root.Size = UDim2.fromOffset(S, S)
    root.Position = UDim2.new(1, -S - 16, 1, -S - 16)
    root.AnchorPoint = Vector2.new(0, 0)
    root.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    root.BackgroundTransparency = 0.15
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = gui
    Instance.new("UICorner", root).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 90, 140)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = root

    -- grade de fundo
    for i = 1, 3 do
        local ln = Instance.new("Frame")
        ln.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        ln.BackgroundTransparency = 0.75
        ln.BorderSizePixel = 0
        ln.Size = UDim2.new(1, 0, 0, 1)
        ln.Position = UDim2.new(0, 0, i / 4, 0)
        ln.Parent = root
        local ln2 = Instance.new("Frame")
        ln2.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        ln2.BackgroundTransparency = 0.75
        ln2.BorderSizePixel = 0
        ln2.Size = UDim2.new(0, 1, 1, 0)
        ln2.Position = UDim2.new(i / 4, 0, 0, 0)
        ln2.Parent = root
    end

    -- círculos de range
    for _, frac in ipairs({ 0.25, 0.5, 0.75 }) do
        local circ = Instance.new("Frame")
        local d = S * frac * 1.5
        circ.Size = UDim2.fromOffset(d, d)
        circ.Position = UDim2.new(0.5, -d / 2, 0.5, -d / 2)
        circ.BackgroundTransparency = 1
        circ.BorderSizePixel = 0
        circ.Parent = root
        Instance.new("UICorner", circ).CornerRadius = UDim.new(1, 0)
        local cst = Instance.new("UIStroke")
        cst.Color = Color3.fromRGB(70, 70, 110)
        cst.Thickness = 1
        cst.Transparency = 0.8
        cst.Parent = circ
    end

    -- VOCÊ: flecha (ImageLabel) que gira com a câmera
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.fromOffset(22, 22)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
    arrow.BackgroundTransparency = 1
    arrow.Parent = root
    -- tenta o PNG local (flecha branca); fallback = triângulo com UICorner
    local okArrow = pcall(function()
        local p = "royalhub_icons/arrow.png"
        if isfile(p) then
            arrow.Image = getcustomasset(p)
        else
            error("no file")
        end
    end)
    if not okArrow then
        -- fallback: seta feita de Frame (triângulo aprox por retângulo rotacionado)
        arrow.Image = ""
        arrow.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
        arrow.BackgroundTransparency = 0
        arrow.Size = UDim2.fromOffset(4, 16)
        Instance.new("UICorner", arrow).CornerRadius = UDim.new(1, 0)
    else
        -- tinge o PNG de verde
        arrow.ImageColor3 = Color3.fromRGB(0, 230, 118)
    end
    G._RadarArrow = arrow

    -- label N (norte) no topo
    local nLbl = Instance.new("TextLabel")
    nLbl.Size = UDim2.new(0, 20, 0, 14)
    nLbl.Position = UDim2.new(0.5, -10, 0, 2)
    nLbl.BackgroundTransparency = 1
    nLbl.Text = "N"
    nLbl.TextColor3 = Color3.fromRGB(160, 160, 200)
    nLbl.TextSize = 11
    nLbl.Font = Enum.Font.GothamBold
    nLbl.Parent = root

    -- label de range no rodapé
    local rangeLbl = Instance.new("TextLabel")
    rangeLbl.Size = UDim2.new(1, 0, 0, 14)
    rangeLbl.Position = UDim2.new(0, 0, 1, -16)
    rangeLbl.BackgroundTransparency = 1
    rangeLbl.Text = G.RadarRange .. " studs"
    rangeLbl.TextColor3 = Color3.fromRGB(150, 150, 180)
    rangeLbl.TextSize = 11
    rangeLbl.Font = Enum.Font.Gotham
    rangeLbl.Parent = root
    G._RadarRangeLbl = rangeLbl

    G._RadarRoot = root
end

local function _radarGetBlip(p)
    if G._RadarBlips[p] then return G._RadarBlips[p] end
    local root = G._RadarRoot
    if not root then return nil end

    local blip = Instance.new("Frame")
    blip.Size = UDim2.fromOffset(7, 7)
    blip.AnchorPoint = Vector2.new(0.5, 0.5)
    blip.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    blip.BorderSizePixel = 0
    blip.Parent = root
    Instance.new("UICorner", blip).CornerRadius = UDim.new(1, 0)
    local bst = Instance.new("UIStroke")
    bst.Color = Color3.fromRGB(0, 0, 0)
    bst.Thickness = 1
    bst.Transparency = 0.4
    bst.Parent = blip

    local lbl = nil
    if G.RadarShowNames then
        lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 90, 0, 12)
        lbl.AnchorPoint = Vector2.new(0.5, 1)
        lbl.BackgroundTransparency = 1
        lbl.Text = p.Name
        lbl.TextColor3 = Color3.fromRGB(255, 220, 220)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Gotham
        lbl.TextStrokeTransparency = 0.6
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = root
    end

    local data = { frame = blip, label = lbl }
    G._RadarBlips[p] = data
    return data
end

function G.toggleRadar(enabled)
    G.RadarEnabled = enabled
    if G.RadarConn then G.RadarConn:Disconnect() G.RadarConn = nil end
    if not enabled then
        _radarDestroy()
        return
    end
    _radarBuild()

    G.RadarConn = S.Run.Heartbeat:Connect(function()
        if not G._RadarRoot or not G._RadarRoot.Parent then return end
        local char = LP.Character
        local lroot = char and char:FindFirstChild("HumanoidRootPart")
        if not lroot then return end

        -- FLECHA gira pra onde a câmera olha (yaw)
        local camYaw = 0
        pcall(function()
            local _, y = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
            camYaw = y
        end)
        G._RadarArrow.Rotation = -math.deg(camYaw)

        G._RadarRangeLbl.Text = G.RadarRange .. " studs"

        local half = G.RadarSize / 2
        local range = G.RadarRange
        local myTeam = LP.Team
        local seen = {}

        for _, p in ipairs(S.Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local pr  = p.Character:FindFirstChild("HumanoidRootPart")
                if pr and hum and hum.Health > 0 then
                    local diff = pr.Position - lroot.Position
                    local dist = diff.Magnitude
                    if dist <= range then
                        seen[p] = true
                        local blip = _radarGetBlip(p)
                        if blip then
                            -- MODO MAPA FIXO: mundo não gira — norte (Z-) pra cima.
                            -- blips nos lugares reais: X direita, Z baixo.
                            local nx = (diff.X / range) * (half - 14)
                            local ny = (diff.Z / range) * (half - 14)
                            blip.frame.Position = UDim2.new(0.5, nx, 0.5, ny)

                            if G.RadarShowTeam then
                                local isAlly = myTeam and p.Team == myTeam
                                blip.frame.BackgroundColor3 = isAlly
                                    and Color3.fromRGB(60, 130, 255)
                                    or  Color3.fromRGB(255, 60, 60)
                            end

                            if blip.label then
                                blip.label.Position = UDim2.new(0.5, nx, 0.5, ny - 6)
                            end
                        end
                    end
                end
            end
        end

        for p, b in pairs(G._RadarBlips) do
            if not seen[p] then
                pcall(function() b.frame:Destroy() end)
                if b.label then pcall(function() b.label:Destroy() end) end
                G._RadarBlips[p] = nil
            end
        end
    end)
end

function G.setRadarRange(v)
    G.RadarRange = v
end

------------------------------------------------------------------------
-- GOD / INVISIBLE / INF JUMP
------------------------------------------------------------------------
function G.toggleGod(enabled)
    G.GodEnabled = enabled
    local function applyGod(char)
        local hum = char:WaitForChild("Humanoid",5)
        if hum then hum.MaxHealth = enabled and math.huge or 100; hum.Health = enabled and math.huge or 100 end
    end
    if LP.Character then applyGod(LP.Character) end
    if enabled then
        if G.GodConn then G.GodConn:Disconnect() end
        G.GodConn = LP.CharacterAdded:Connect(function(c) if G.GodEnabled then applyGod(c) end end)
    else
        if G.GodConn then G.GodConn:Disconnect() G.GodConn = nil end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 100; if hum.Health > 100 then hum.Health = 100 end end
    end
end

function G.toggleInvisible(enabled)
    G.InvisEnabled = enabled
    if G.InvisConn then G.InvisConn:Disconnect() G.InvisConn = nil end
    local char = LP.Character
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = enabled and 1 or 0 end
        end
    end
    if enabled then
        G.InvisConn = LP.CharacterAdded:Connect(function(c)
            task.wait(0.3)
            if not G.InvisEnabled then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
            end
        end)
    end
end

function G.toggleInfJump(enabled)
    G.InfJumpEnabled = enabled
    if G.InfJumpConn then G.InfJumpConn:Disconnect() G.InfJumpConn = nil end
    if enabled then
        G.InfJumpConn = S.UI.JumpRequest:Connect(function()
            if not G.InfJumpEnabled then return end
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
    end
end

------------------------------------------------------------------------
-- FULLBRIGHT / XRAY / NO FOG
------------------------------------------------------------------------
function G.toggleFullbright(enabled)
    G.FullbrightEnabled = enabled
    local L = game:GetService("Lighting")
    if enabled then
        G.OrigLighting = { Brightness=L.Brightness, ClockTime=L.ClockTime, FogEnd=L.FogEnd, GlobalShadows=L.GlobalShadows, Ambient=L.Ambient }
        L.Brightness=2; L.ClockTime=14; L.FogEnd=100000; L.GlobalShadows=false; L.Ambient=Color3.fromRGB(255,255,255)
    else
        if G.OrigLighting.Brightness then
            L.Brightness=G.OrigLighting.Brightness; L.ClockTime=G.OrigLighting.ClockTime
            L.FogEnd=G.OrigLighting.FogEnd; L.GlobalShadows=G.OrigLighting.GlobalShadows; L.Ambient=G.OrigLighting.Ambient
        end
    end
end

function G.toggleXray(enabled)
    G.XrayEnabled = enabled
    for _, c in pairs(G.XrayConns or {}) do pcall(function() c:Disconnect() end) end
    G.XrayConns = {}
    local function applyChar(char)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if G.XrayEnabled then
                    if part.Material ~= Enum.Material.ForceField then G.XrayOriginals[part] = part.Material end
                    part.Material = Enum.Material.ForceField
                elseif G.XrayOriginals[part] then
                    part.Material = G.XrayOriginals[part]
                    G.XrayOriginals[part] = nil
                end
            end
        end
    end
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP then
            if p.Character then applyChar(p.Character) end
            if enabled then
                table.insert(G.XrayConns, p.CharacterAdded:Connect(function(c)
                    task.wait(0.3)
                    if G.XrayEnabled then applyChar(c) end
                end))
            end
        end
    end
    if not enabled then G.XrayOriginals = {} end
end


function G.toggleNoFog(enabled)
    G.NoFogEnabled = enabled
    local L = game:GetService("Lighting")
    if enabled then
        G.OrigFog = {FogEnd=L.FogEnd, FogStart=L.FogStart}
        L.FogEnd=100000; L.FogStart=99999
    else
        L.FogEnd=G.OrigFog.FogEnd or 100000; L.FogStart=G.OrigFog.FogStart or 0
    end
end

------------------------------------------------------------------------
-- FREEZE / HEAD SIZE
------------------------------------------------------------------------
function G.toggleFreeze(enabled)
    G.FreezeEnabled = enabled
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = enabled end
end

function G.setHeadSize(scale)
    G.HeadSize = scale
    local head = LP.Character and LP.Character:FindFirstChild("Head")
    if head then head.Size = Vector3.new(2*scale, 2*scale, 2*scale) end
end

------------------------------------------------------------------------
-- HOVER NAME
------------------------------------------------------------------------
function G.clearHoverNames()
    for _, c in pairs(G.HoverNameConns) do pcall(function() c:Disconnect() end) end
    G.HoverNameConns = {}
    for _, b in pairs(G.HoverNameBBs) do pcall(function() b:Destroy() end) end
    G.HoverNameBBs = {}
end

local function _attachHoverName(p)
    if not p.Character then return end
    local head = p.Character:FindFirstChild("Head"); if not head then return end
    local bg = Instance.new("BillboardGui"); bg.AlwaysOnTop=true
    bg.Size=UDim2.new(0,120,0,40); bg.StudsOffset=Vector3.new(0,2.5,0); bg.Adornee=head; bg.Parent=head
    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
    lbl.Text=p.DisplayName.."\n["..p.Name.."]"; lbl.TextColor3=Color3.new(1,1,1)
    lbl.TextStrokeTransparency=0; lbl.TextSize=13; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bg
    table.insert(G.HoverNameBBs, bg)
end

function G.toggleHoverName(enabled)
    G.HoverNameEnabled = enabled
    G.clearHoverNames()
    if enabled then
        for _, p in pairs(S.Players:GetPlayers()) do
            if p ~= LP then
                _attachHoverName(p)
                local c = p.CharacterAdded:Connect(function() task.wait(0.5) _attachHoverName(p) end)
                table.insert(G.HoverNameConns, c)
            end
        end
    else
    end
end

------------------------------------------------------------------------
-- ANTI-AFK
------------------------------------------------------------------------
function G.toggleAntiAFK(enabled)
    G.AntiAFKEnabled = enabled
    if G.AntiAFKConn then G.AntiAFKConn:Disconnect() G.AntiAFKConn = nil end
    if enabled then
        G.AntiAFKConn = LP.Idled:Connect(function()
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end)
    else
    end
end

------------------------------------------------------------------------
-- FREECAM
------------------------------------------------------------------------
function G.toggleFreecam(enabled)
    G.FreecamEnabled = enabled
    local cam = workspace.CurrentCamera
    for _, c in pairs(G.FreecamConns) do pcall(function() c:Disconnect() end) end
    G.FreecamConns = {}
    if enabled then
        cam.CameraType = Enum.CameraType.Scriptable
        local fp = Instance.new("Part"); fp.Anchored=true; fp.CanCollide=false
        fp.Transparency=1; fp.Size=Vector3.one; fp.CFrame=cam.CFrame; fp.Parent=workspace
        G.FreecamPart = fp; cam.CFrame = fp.CFrame
        local keys = {}
        local c1 = S.UI.InputBegan:Connect(function(i,gp) if not gp then keys[i.KeyCode]=true end end)
        local c2 = S.UI.InputEnded:Connect(function(i) keys[i.KeyCode]=false end)
        local c3 = S.Run.RenderStepped:Connect(function(dt)
            if not G.FreecamEnabled or not G.FreecamPart then return end
            local sp = G.FreecamSpeed*50*dt; local cf = G.FreecamPart.CFrame
            if keys[Enum.KeyCode.W] then cf=cf*CFrame.new(0,0,-sp) end
            if keys[Enum.KeyCode.S] then cf=cf*CFrame.new(0,0,sp) end
            if keys[Enum.KeyCode.A] then cf=cf*CFrame.new(-sp,0,0) end
            if keys[Enum.KeyCode.D] then cf=cf*CFrame.new(sp,0,0) end
            if keys[Enum.KeyCode.E] then cf=cf*CFrame.new(0,sp,0) end
            if keys[Enum.KeyCode.Q] then cf=cf*CFrame.new(0,-sp,0) end
            G.FreecamPart.CFrame=cf; cam.CFrame=cf
        end)
        local c4 = S.UI.InputChanged:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseMovement and S.UI:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                G.FreecamPart.CFrame = G.FreecamPart.CFrame*CFrame.Angles(0,-i.Delta.X*0.005,0)*CFrame.Angles(-i.Delta.Y*0.005,0,0)
                cam.CFrame = G.FreecamPart.CFrame
            end
        end)
        G.FreecamConns = {c1,c2,c3,c4}
        notify("Freecam","WASD mover | Q/E subir/descer | Btn direito+arrastar = girar",5,"solar:camera-bold")
    else
        cam.CameraType = Enum.CameraType.Custom
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then cam.CameraSubject = hum end
        if G.FreecamPart then G.FreecamPart:Destroy() G.FreecamPart = nil end
    end
end

------------------------------------------------------------------------
-- REACH / KILL AURA / CLICK TP
------------------------------------------------------------------------
function G.toggleReach(enabled, size)
    G.ReachEnabled = enabled
    if G.ReachConn then G.ReachConn:Disconnect() G.ReachConn = nil end
    local sz = size or G.ReachSize
    local function apply(char)
        for _, t in pairs(LP.Backpack:GetChildren()) do
            if t:IsA("Tool") then local h=t:FindFirstChild("Handle"); if h then h.Size=enabled and Vector3.new(sz,sz,sz) or Vector3.one end end
        end
        if char then
            for _, t in pairs(char:GetChildren()) do
                if t:IsA("Tool") then local h=t:FindFirstChild("Handle"); if h then h.Size=enabled and Vector3.new(sz,sz,sz) or Vector3.one end end
            end
        end
    end
    apply(LP.Character)
    if enabled then
        G.ReachConn = LP.CharacterAdded:Connect(apply)
    else
    end
end

function G.toggleKillAura(enabled)
    G.KillAuraEnabled = enabled
    if G.KillAuraConn then G.KillAuraConn:Disconnect() G.KillAuraConn = nil end
    if enabled then
        G.KillAuraConn = S.Run.Heartbeat:Connect(function()
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
            for _, p in pairs(S.Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local er  = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if er and hum and hum.Health > 0 and (root.Position-er.Position).Magnitude <= G.KillAuraRange then
                        hum.Health = 0
                    end
                end
            end
        end)
    else
    end
end

function G.toggleClickTP(enabled)
    G.ClickTPEnabled = enabled
    if G.ClickTPConn then G.ClickTPConn:Disconnect() G.ClickTPConn = nil end
    if enabled then
        local mouse = LP:GetMouse()
        G.ClickTPConn = mouse.Button1Down:Connect(function()
            if not G.ClickTPEnabled then return end
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if root and mouse.Hit then root.CFrame = mouse.Hit * CFrame.new(0,3,0) end
        end)
    else
    end
end

------------------------------------------------------------------------
-- EMOTES
------------------------------------------------------------------------
G.emoteList = {
    RockOut=11753474067, Bow=13823324057, Prayer=114388371896974, WallLean=10714392876,
    Greed=507765000, CryForMeOG=106082149118126, FFPushUp=76988349893259, FFDemonDance=103961097096319,
    NyaDance=106516971471692, BrazilianFunkFootwork=140219184038687, FrenchConfidence=126275747804327,
    AuraPose=133418516499878, VemCaNenem=91032467964520, LegendAuraFly=101420028871528,
    EmperorOfTheAuraverse=119810104205917, GhostFaceEmote=99850116159145, EndlessAuraFloating=123349905320515,
    ZeroTwoDanceV2=82682811348660, Jumpstyledance=112773902133223, MASSIVEPOOP=125329959146841,
    PasinhoJamal=100545872015841, FeelingCute=73161476966723, SpiderJumpingAround=70981302031949,
    RaceCar=72382226286301, Possesed=90708290447388, HalloweenHeadless=121812124134821,
    invisibleMe=126995783634131, GojoFloating=111383986305209, SHAKE=98719422024341,
    IWANNARUNAWAY=104428851742579, TallScaryCreature=130916388086314, FFLOL=98316145061745,
    PainAndSuffering=122319751392556, PossessedGlitcher=80103653497738, Helicopter=71527789940915,
    SummonAFriend=118979452794479, Tank=137814849942324, SadSit=100798804992348,
    FFTheWalker=121448822763616, FFpiopio=131858162905276, HearMeNow=88974065639269,
    PassinhoBolsonaro=96673018720208, SHAKETHATTHANG=103461852463003, StylishFloating=112089880074848,
    Gangnamstyle=131104967711844, sturdy=132104757386824, ObbyHead=125176243437210,
}

function G.getEmoteValues()
    local vals = {}
    local names = {}
    for n in pairs(G.emoteList) do table.insert(names, n) end
    table.sort(names)
    for _, n in ipairs(names) do table.insert(vals, {Title=n}) end
    return vals
end

function G.activateManualLoop(track)
    if G.EmoteLoopConn then G.EmoteLoopConn:Disconnect() end
    G.EmoteLoopConn = track.Stopped:Connect(function()
        if G.LoopEmote and track == G.CurrentEmoteTrack then track:Play()
        else G.EmoteLoopConn:Disconnect(); G.EmoteLoopConn = nil end
    end)
end

------------------------------------------------------------------------
-- WEBHOOK
------------------------------------------------------------------------
G.WebhookURL        = ""
G.InvWebhookEnabled = false
G.InvWebhookConn    = nil
G.InvSnapshot       = {}
G.SelectedIsland    = nil

function G.sendWebhook(message)
    if not G.WebhookURL or G.WebhookURL == "" then
        pcall(function()
            notify("WebHook", "Configure a URL do webhook primeiro!", 3)
        end)
        return
    end
    local ok, err = pcall(function()
        local HTTP = game:GetService("HttpService")
        local body = HTTP:JSONEncode({ content = message })
        HTTP:PostAsync(G.WebhookURL, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if not ok then
        pcall(function()
            notify("WebHook", "Erro ao enviar: " .. tostring(err), 4)
        end)
    end
end

local function getInventorySnapshot()
    local snap = {}
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            snap[item.Name] = true
        end
    end
    local char = LP.Character
    if char then
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Tool") then snap[item.Name] = true end
        end
    end
    return snap
end

function G.toggleInventoryWebhook(enabled)
    G.InvWebhookEnabled = enabled
    if G.InvWebhookConn then G.InvWebhookConn:Disconnect() G.InvWebhookConn = nil end
    if enabled then
        G.InvSnapshot = getInventorySnapshot()
        G.InvWebhookConn = S.Run.Heartbeat:Connect(function()
            if not G.InvWebhookEnabled then return end
            local current = getInventorySnapshot()
            for name in pairs(current) do
                if not G.InvSnapshot[name] then
                    G.InvSnapshot[name] = true
                    local msg = "🎒 **Novo item no inventário!**\n"
                        .. "Jogador: **" .. LP.Name .. "**\n"
                        .. "Item: **" .. name .. "**\n"
                        .. "Jogo: **" .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "**"
                    task.spawn(function() G.sendWebhook(msg) end)
                end
            end
            for name in pairs(G.InvSnapshot) do
                if not current[name] then
                    G.InvSnapshot[name] = nil
                end
            end
        end)
    else
        G.InvSnapshot = {}
    end
end

------------------------------------------------------------------------
-- BROOKHAVEN RP NAME
------------------------------------------------------------------------
function G.checkAndSetRP()
    if game.PlaceId ~= 4924922222 then return end
    local admins = {"DARK_ZIINN","S1wlkrX","thenoctisblack78"}
    local isAdmin = table.find(admins, LP.Name) ~= nil
    local rpName  = isAdmin and " [ DEV ]" or "CLIENTE ROYAL HUB"
    local bio     = isAdmin and "CREATOR OF ROYAL HUB" or ""
    local PB = LP:WaitForChild("PlayersBag",10)
    if PB then
        if PB:FindFirstChild("RPName")  then PB.RPName.Value  = rpName end
        if PB:FindFirstChild("RPBio")   then PB.RPBio.Value   = bio    end
    end
    local RE = game:GetService("ReplicatedStorage"):WaitForChild("RE",5)
    if not RE then return end
    local tr = RE:FindFirstChild("1RPNam1eTex1t")
    if tr then tr:FireServer("RolePlayName",rpName); tr:FireServer("RolePlayBio",bio) end
    local cr = RE:FindFirstChild("1RPNam1eColo1r")
    if cr then
        local r,g,b = isAdmin and 1 or 1, isAdmin and 0 or 1, isAdmin and 0 or 1
        cr:FireServer("PickingRPNamColor",r,g,b)
    end
end

task.spawn(function() task.wait(1); G.checkAndSetRP() end)

------------------------------------------------------------------------
-- CharacterAdded reconexão automática
------------------------------------------------------------------------
G._ReconnectConn = LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if G.FlyEnabled     then G.toggleFly(true)     end
    if G.SpinEnabled    then G.toggleSpin(true)     end
    if G.FakeTPEnabled  then G.toggleFakeTP(true)   end
end)

------------------------------------------------------------------------
-- NOVAS FUNÇÕES CHEAT
------------------------------------------------------------------------

------------------------------------------------------------------------
-- DRAWING OPACITY HELPER
-- Executores divergem no Transparency do Drawing:
--   padrão (sUNC/Synapse): 0 = opaco, 1 = invisível
--   alguns (bug): tratam como opacity -> 0 = INVISÍVEL
-- Solução robusta: NUNCA escrever Transparency (deixa o default do
-- executor, que é sempre "opaco"), e compensar nitidez com Thickness.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- ESP BONES (esqueleto: linhas entre as juntas do rig, R6 e R15)
------------------------------------------------------------------------
G.EspBonesEnabled   = false
G.EspBonesConn     = nil
G.EspBonesColor    = Color3.fromRGB(255, 255, 255)
G.EspBonesWidth    = 1
G._EspBonesByPlayer = {}   -- [player] = {lines...} (1 Drawing por linha, cacheado)

-- pares de juntas por rig type
local BONES_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local BONES_R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function _bonesRemove(p)
    if G._EspBonesByPlayer[p] then
        for _, l in pairs(G._EspBonesByPlayer[p]) do pcall(function() l:Remove() end) end
        G._EspBonesByPlayer[p] = nil
    end
end

function G.toggleEspBones(enabled)
    G.EspBonesEnabled = enabled
    if G.EspBonesConn then G.EspBonesConn:Disconnect() G.EspBonesConn = nil end
    for p in pairs(G._EspBonesByPlayer) do _bonesRemove(p) end
    if not enabled then return end

    G.EspBonesConn = S.Run.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local camPos = cam.CFrame.Position
        for _, p in ipairs(S.Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                -- CULLING: 1 projeção barata decide se o player interessa;
                -- fora da tela/longe demais = esconde tudo (as 14+ linhas nem
                -- rodam as projeções delas) -> recupera o FPS com server cheio
                local sp, onScreen = cam:WorldToViewportPoint(hrp and hrp.Position or p.Character:GetPivot().Position)
                local inRange = hrp and (camPos - hrp.Position).Magnitude <= G.MaxDistance
                if not (hum and hum.Health > 0 and onScreen and inRange) then
                    _bonesRemove(p)
                else
                    local rig = hum.RigType
                    local pairsList = if rig == Enum.HumanoidRigType.R6 then BONES_R6 else BONES_R15
                    -- pega/cacheia as linhas
                    local lines = G._EspBonesByPlayer[p]
                    if not lines then
                        lines = {}
                        G._EspBonesByPlayer[p] = lines
                    end
                    for i, pair in ipairs(pairsList) do
                        local a = p.Character:FindFirstChild(pair[1])
                        local b = p.Character:FindFirstChild(pair[2])
                        local line = lines[i]
                        if a and b then
                            if not line then
                                local ok, l = pcall(Drawing.new, "Line")
                                if ok then line = l; lines[i] = l end
                            end
                            if line then
                                local sa, oa = cam:WorldToViewportPoint(a.Position)
                                local sb, ob = cam:WorldToViewportPoint(b.Position)
                                if oa and ob then
                                    line.Visible   = true
                                    line.From      = Vector2.new(sa.X, sa.Y)
                                    line.To        = Vector2.new(sb.X, sb.Y)
                                    line.Color     = G.EspBonesColor
                                    line.Thickness = G.EspBonesWidth
                                else
                                    line.Visible = false
                                end
                            end
                        elseif line then
                            line.Visible = false
                        end
                    end
                end
            else
                _bonesRemove(p)
            end
        end
    end)

    -- limpeza quando player sai
    if not G._EspBonesRemoveConn then
        G._EspBonesRemoveConn = S.Players.PlayerRemoving:Connect(_bonesRemove)
    end
end

function G.setEspBonesColor(c)  G.EspBonesColor = c end
function G.setEspBonesWidth(v)  G.EspBonesWidth = v end

------------------------------------------------------------------------
-- ESP 2D (o que o "Twilight" prometia, nativo: Box / Health Bar / Info)
-- 1 objeto por jogador por recurso, cacheado — mesmo padrão dos bones
------------------------------------------------------------------------
G.EspBoxEnabled    = false
G.EspHealthEnabled = false
G.EspInfoEnabled   = false
G._Esp2dConn       = nil
G._Esp2dByPlayer   = {}   -- [player] = { box1..8, hpBg, hpFill, nameTxt, distTxt }

local function _esp2dObj(p, key, class, staticProps)
    local data = G._Esp2dByPlayer[p]
    if not data then
        data = {}
        G._Esp2dByPlayer[p] = data
    end
    if data[key] then return data[key] end
    local ok, o = pcall(Drawing.new, class)
    if not ok then return nil end
    -- propriedades ESTÁTICAS (Size/Center/Outline/Thickness) só na CRIAÇÃO:
    -- mudá-las por frame força re-render do Drawing e alguns executores
    -- descartam a Position pendente (bug que fazia o texto "pular" pra
    -- posição errada). Position sempre por último, por frame.
    if staticProps then
        for k, v in pairs(staticProps) do
            pcall(function() o[k] = v end)
        end
    end
    data[key] = o
    return o
end

local function _esp2dRemove(p)
    local data = G._Esp2dByPlayer[p]
    if data then
        for _, o in pairs(data) do pcall(function() o:Remove() end) end
        G._Esp2dByPlayer[p] = nil
    end
end

local function _esp2dHideKeys(p, keys)
    local data = G._Esp2dByPlayer[p]
    if not data then return end
    for _, k in ipairs(keys) do
        if data[k] then data[k].Visible = false end
    end
end

local function _esp2dHealthColor(hp)
    -- hp 0..1: vermelho (vazio) -> amarelo -> verde (cheio)
    local r, g
    if hp >= 0.5 then
        local t = (hp - 0.5) * 2
        r = math.floor(255 * (1 - t)); g = 255
    else
        local t = hp * 2
        r = 255; g = math.floor(255 * t)
    end
    return Color3.fromRGB(r, g, 0)
end

local BOX_KEYS = { "box1","box2","box3","box4","box5","box6","box7","box8" }
local INFO_KEYS = { "nameTxt", "distTxt" }
local HP_KEYS   = { "hpBg", "hpFill" }

local function _esp2dStart()
    if G._Esp2dConn then return end
    G._Esp2dConn = S.Run.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local camPos = cam.CFrame.Position
        local myTeam = LP.Team

        local corners = {
            Vector3.new(-0.5,-0.5,-0.5), Vector3.new(0.5,-0.5,-0.5),
            Vector3.new(-0.5, 0.5,-0.5), Vector3.new(0.5, 0.5,-0.5),
            Vector3.new(-0.5,-0.5, 0.5), Vector3.new(0.5,-0.5, 0.5),
            Vector3.new(-0.5, 0.5, 0.5), Vector3.new(0.5, 0.5, 0.5),
        }

        for _, p in ipairs(S.Players:GetPlayers()) do
            local valid = false
            if p ~= LP and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and hum.MaxHealth > 0 then
                    local isAlly = G.UseTeamCheck and myTeam and (p.Team == myTeam)
                    if not isAlly then valid = true end
                end
            end

            if not valid then
                _esp2dRemove(p)
            else
                local char = p.Character
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local okBB, cf, size = pcall(function() return char:GetBoundingBox() end)
                if not okBB or not root or not cf then
                    _esp2dRemove(p)
                else
                    -- projeta os 8 cantos do bounding box 3D pra tela
                    local minX, minY = math.huge, math.huge
                    local maxX, maxY = -math.huge, -math.huge
                    local anyOnScreen = false
                    for _, half in ipairs(corners) do
                        local sp, onScreen = cam:WorldToViewportPoint(cf * (size * half))
                        if onScreen then
                            anyOnScreen = true
                            if sp.X < minX then minX = sp.X end
                            if sp.Y < minY then minY = sp.Y end
                            if sp.X > maxX then maxX = sp.X end
                            if sp.Y > maxY then maxY = sp.Y end
                        end
                    end

                    if not anyOnScreen or maxX <= minX or maxY <= minY then
                        _esp2dHideKeys(p, BOX_KEYS)
                        _esp2dHideKeys(p, HP_KEYS)
                        _esp2dHideKeys(p, INFO_KEYS)
                    else
                        local w = maxX - minX
                        local h = maxY - minY

                        -- ===== BOX (estilo canto: 4 cantos, 2 linhas cada) =====
                        if G.EspBoxEnabled then
                            local cl = math.min(w, h) * 0.25
                            local segs = {
                                { "box1", minX, minY, minX + cl, minY }, { "box2", minX, minY, minX, minY + cl },
                                { "box3", maxX, minY, maxX - cl, minY }, { "box4", maxX, minY, maxX, minY + cl },
                                { "box5", minX, maxY, minX + cl, maxY }, { "box6", minX, maxY, minX, maxY - cl },
                                { "box7", maxX, maxY, maxX - cl, maxY }, { "box8", maxX, maxY, maxX, maxY - cl },
                            }
                            for _, seg in ipairs(segs) do
                                local line = _esp2dObj(p, seg[1], "Line", { Thickness = 1 })
                                if line then
                                    line.Visible = true
                                    line.From    = Vector2.new(seg[2], seg[3])
                                    line.To      = Vector2.new(seg[4], seg[5])
                                    line.Color   = G.EspBoxColor or Color3.new(1, 1, 1)
                                end
                            end
                        else
                            _esp2dHideKeys(p, BOX_KEYS)
                        end

                        -- ===== HEALTH BAR (esquerda do box) =====
                        if G.EspHealthEnabled then
                            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            local bx = minX - 6
                            local hpBg = _esp2dObj(p, "hpBg", "Line", { Thickness = 3 })
                            if hpBg then
                                hpBg.Visible = true
                                hpBg.From    = Vector2.new(bx, minY)
                                hpBg.To      = Vector2.new(bx, maxY)
                                hpBg.Color   = Color3.fromRGB(30, 30, 30)
                            end
                            local hpFill = _esp2dObj(p, "hpFill", "Line", { Thickness = 3 })
                            if hpFill then
                                hpFill.Visible = true
                                hpFill.From    = Vector2.new(bx, maxY)
                                hpFill.To      = Vector2.new(bx, maxY - h * hp)
                                hpFill.Color   = _esp2dHealthColor(hp)
                            end
                        else
                            _esp2dHideKeys(p, HP_KEYS)
                        end

                        -- ===== INFO (ancorado no TOPO DO BOX projetado — funciona
                        --      com qualquer rig, inclusive chars morfados que não
                        --      têm "Head" visível; usa minX/maxX já calculados) =====
                        if G.EspInfoEnabled then
                            local cx = (minX + maxX) / 2
                            local nameTxt = _esp2dObj(p, "nameTxt", "Text", {
                                Size = 16, Center = true, Outline = true,
                            })
                            if nameTxt then
                                nameTxt.Visible = true
                                -- tag de admin: "Nome [ADMIN]" com cor própria (ou RGB)
                                local adminTag, adminColor = G.getAdminTag(p)
                                if adminTag then
                                    nameTxt.Text  = (p.DisplayName ~= "" and p.DisplayName or p.Name) .. adminTag
                                    nameTxt.Color = adminColor
                                else
                                    nameTxt.Text  = (p.DisplayName ~= "" and p.DisplayName or p.Name)
                                    nameTxt.Color = G.EspInfoColor or Color3.new(1, 1, 1)
                                end
                                nameTxt.Position = Vector2.new(cx, minY - 24)  -- POR ÚLTIMO
                            end
                            local distTxt = _esp2dObj(p, "distTxt", "Text", {
                                Size = 13, Center = true, Outline = true,
                            })
                            if distTxt then
                                local dist = math.floor((camPos - root.Position).Magnitude)
                                distTxt.Visible = true
                                distTxt.Text    = dist .. "m"
                                distTxt.Color   = Color3.fromRGB(200, 200, 200)
                                distTxt.Position = Vector2.new(cx, maxY + 4)  -- POR ÚLTIMO
                            end
                        else
                            _esp2dHideKeys(p, INFO_KEYS)
                        end
                    end
                end
            end
        end
    end)

    if not G._Esp2dRemoveConn then
        G._Esp2dRemoveConn = S.Players.PlayerRemoving:Connect(_esp2dRemove)
    end
end

local function _esp2dStopIfIdle()
    if G.EspBoxEnabled or G.EspHealthEnabled or G.EspInfoEnabled then return end
    if G._Esp2dConn then G._Esp2dConn:Disconnect(); G._Esp2dConn = nil end
    for p in pairs(G._Esp2dByPlayer) do _esp2dRemove(p) end
end

function G.toggleEspBox(enabled)
    G.EspBoxEnabled = enabled
    if enabled then _esp2dStart() else _esp2dStopIfIdle() end
end

function G.toggleEspHealth(enabled)
    G.EspHealthEnabled = enabled
    if enabled then _esp2dStart() else _esp2dStopIfIdle() end
end

function G.toggleEspInfo(enabled)
    G.EspInfoEnabled = enabled
    if enabled then _esp2dStart() else _esp2dStopIfIdle() end
end

function G.setEspBoxColor(c)  G.EspBoxColor = c end
function G.setEspInfoColor(c) G.EspInfoColor = c end

------------------------------------------------------------------------
-- CLIQUE ESQUERDO que funciona: VirtualInputManager > mouse1click > keypress
-- (keypress(1) não funciona pra mouse na maioria dos executores — era o bug)
local function _clickLeftMouse()
    local ok = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local pos = S.UI:GetMouseLocation()
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    if ok then return true end
    if mouse1click then
        local ok2 = pcall(mouse1click)
        if ok2 then return true end
    end
    pcall(function() keypress(1) task.wait(0.01) keyrelease(1) end)
    return false
end

-- TRIGGER BOT: atira automaticamente quando o crosshair está sobre um inimigo
G.TriggerBotEnabled = false; G.TriggerBotDelay = 0.1; G.TriggerBotConn = nil

function G.toggleTriggerBot(enabled)
    G.TriggerBotEnabled = enabled
    if G.TriggerBotConn then G.TriggerBotConn:Disconnect() G.TriggerBotConn = nil end
    if enabled then
        local lastClick = 0
        G.TriggerBotConn = S.Run.Heartbeat:Connect(function()
            -- cooldown real (antes cliqueteava 60x/s sem esperar o delay)
            if tick() - lastClick < (G.TriggerBotDelay or 0.1) then return end
            local cam = workspace.CurrentCamera
            local myChar = LP.Character
            local myTeam = LP.Team
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = {myChar}
            local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * G.MaxDistance, rp)
            if hit and hit.Instance then
                for _, p in ipairs(S.Players:GetPlayers()) do
                    if p ~= LP and p.Character and hit.Instance:IsDescendantOf(p.Character) then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        local isAlly = G.UseTeamCheck and myTeam and (p.Team == myTeam)
                        if hum and hum.Health > 0 and not isAlly then
                            lastClick = tick()
                            _clickLeftMouse()
                        end
                        break
                    end
                end
            end
        end)
    end
end

function G.setTriggerBotDelay(v)
    G.TriggerBotDelay = v
end

-- AUTO CLICKER: clica N vezes por segundo (MouseButton1)
G.AutoClickerEnabled = false; G.AutoClickerCPS = 10; G.AutoClickerConn = nil

function G.toggleAutoClicker(enabled)
    G.AutoClickerEnabled = enabled
    if G.AutoClickerConn then G.AutoClickerConn:Disconnect() G.AutoClickerConn = nil end
    if enabled then
        task.spawn(function()
            while G.AutoClickerEnabled do
                _clickLeftMouse()
                task.wait(1 / math.max(G.AutoClickerCPS or 10, 1))
            end
        end)
    end
end

function G.setAutoClickerCPS(v)
    G.AutoClickerCPS = math.max(1, math.floor(v))
end

-- CROSSHAIR custom (Drawing API)
G.CrosshairEnabled = false; G.CrosshairSize = 6; G.CrosshairGap = 3
G.CrosshairColor = Color3.fromRGB(255, 255, 255)
G.CrosshairDrawings = {}; G.CrosshairConn = nil

function G.toggleCrosshair(enabled)
    G.CrosshairEnabled = enabled
    for _, d in pairs(G.CrosshairDrawings) do pcall(function() d:Remove() end) end
    G.CrosshairDrawings = {}
    if G.CrosshairConn then G.CrosshairConn:Disconnect() G.CrosshairConn = nil end
    if enabled then
        local ok = pcall(Drawing.new, "Line")
        if not ok then
            notify("Crosshair", "Executor sem Drawing API!", 3, "x")
            G.CrosshairEnabled = false
            return
        end
        local lines = {}
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Thickness = 1
            l.Color      = G.CrosshairColor
            l.Visible    = true
            lines[i] = l
            G.CrosshairDrawings[i] = l
        end
        G.CrosshairConn = S.Run.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local vp  = cam.ViewportSize
            local cx, cy = vp.X / 2, vp.Y / 2
            local s, g = G.CrosshairSize, G.CrosshairGap
            -- cima, baixo, esquerda, direita
            lines[1].From, lines[1].To = Vector2.new(cx, cy - g), Vector2.new(cx, cy - g - s)
            lines[2].From, lines[2].To = Vector2.new(cx, cy + g), Vector2.new(cx, cy + g + s)
            lines[3].From, lines[3].To = Vector2.new(cx - g, cy), Vector2.new(cx - g - s, cy)
            lines[4].From, lines[4].To = Vector2.new(cx + g, cy), Vector2.new(cx + g + s, cy)
            for i = 1, 4 do lines[i].Color = G.CrosshairColor end
        end)
    else
    end
end

function G.setCrosshairSize(v)  G.CrosshairSize = v end
function G.setCrosshairGap(v)   G.CrosshairGap = v end
function G.setCrosshairColor(c) G.CrosshairColor = c end

-- SPEED LOCK / JUMP LOCK: re-aplicam mesmo se o jogo resetar
G.SpeedLockEnabled = false; G.JumpLockEnabled = false; G.StatLockConn = nil

function _updateStatLock()
    if G.StatLockConn then G.StatLockConn:Disconnect() G.StatLockConn = nil end
    if not G.SpeedLockEnabled and not G.JumpLockEnabled then return end
    G.StatLockConn = S.Run.Heartbeat:Connect(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if G.SpeedLockEnabled and hum.WalkSpeed ~= G.SpeedValue then hum.WalkSpeed = G.SpeedValue end
        if G.JumpLockEnabled and hum.JumpPower  ~= G.JumpValue  then hum.JumpPower  = G.JumpValue end
    end)
end

function G.toggleSpeedLock(enabled)
    G.SpeedLockEnabled = enabled
    _updateStatLock()
end

function G.toggleJumpLock(enabled)
    G.JumpLockEnabled = enabled
    _updateStatLock()
end

-- AUTO RESPAWN: re-spawna sozinho ao morrer
G.AutoRespawnEnabled = false; G.AutoRespawnConn = nil; G.AutoRespawnDelay = 1

function G.toggleAutoRespawn(enabled)
    G.AutoRespawnEnabled = enabled
    if G.AutoRespawnConn then G.AutoRespawnConn:Disconnect() G.AutoRespawnConn = nil end
    if enabled then
        G.AutoRespawnConn = LP.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if not hum or not G.AutoRespawnEnabled then return end
            hum.Died:Connect(function()
                if not G.AutoRespawnEnabled then return end
                task.wait(G.AutoRespawnDelay or 1)
                pcall(function() LP:LoadCharacter() end)
            end)
        end)
        -- cobre o char atual também
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Died:Connect(function()
                    if not G.AutoRespawnEnabled then return end
                    task.wait(G.AutoRespawnDelay or 1)
                    pcall(function() LP:LoadCharacter() end)
                end)
            end
        end
    else
    end
end

function G.setAutoRespawnDelay(v) G.AutoRespawnDelay = v end

-- CAMERA FOV (FieldOfView da câmera)
G.CamFOVEnabled = false; G.CamFOVValue = 90; G.CamFOVConn = nil

function G.toggleCamFOV(enabled)
    G.CamFOVEnabled = enabled
    if G.CamFOVConn then G.CamFOVConn:Disconnect() G.CamFOVConn = nil end
    if enabled then
        local cam = workspace.CurrentCamera
        if cam and not G._OrigFieldOfView then G._OrigFieldOfView = cam.FieldOfView end
        G.CamFOVConn = S.Run.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            if cam and cam.FieldOfView ~= G.CamFOVValue then cam.FieldOfView = G.CamFOVValue end
        end)
    else
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = G._OrigFieldOfView or 70 end
        G._OrigFieldOfView = nil
    end
end

function G.setCamFOV(v)
    G.CamFOVValue = v
    if G.CamFOVEnabled then
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end
end

------------------------------------------------------------------------
-- SPRINT (LeftShift = velocidade turbo enquanto pressionado)
------------------------------------------------------------------------
G.SprintEnabled = false; G.SprintSpeed = 32; G.SprintConn = nil; G.SprintBase = nil

function G.toggleSprint(enabled)
    G.SprintEnabled = enabled
    if G.SprintConn then G.SprintConn:Disconnect() G.SprintConn = nil end
    if enabled then
        G.SprintConn = S.Run.Heartbeat:Connect(function()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            if S.UI:IsKeyDown(Enum.KeyCode.LeftShift) then
                if not G.SprintBase then G.SprintBase = hum.WalkSpeed end
                hum.WalkSpeed = G.SprintSpeed
            else
                if G.SprintBase then hum.WalkSpeed = G.SprintBase end
            end
        end)
    else
        -- restaura
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and G.SprintBase then hum.WalkSpeed = G.SprintBase end
        G.SprintBase = nil
    end
end

function G.setSprintSpeed(v) G.SprintSpeed = v end

------------------------------------------------------------------------
-- THIRD PERSON FORÇADO (trava a câmera em 3ª pessoa)
------------------------------------------------------------------------
G.ThirdPersonEnabled = false; G.ThirdPersonOffset = 12

function G.toggleThirdPerson(enabled)
    G.ThirdPersonEnabled = enabled
    local ok = pcall(function()
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMaxZoomDistance = 400
        LP.CameraMinZoomDistance = enabled and G.ThirdPersonOffset or 0.5
        if enabled then
            LP.CameraMaxZoomDistance = math.max(G.ThirdPersonOffset, 12)
        else
            LP.CameraMaxZoomDistance = 400
            LP.CameraMinZoomDistance = 0.5
        end
    end)
    if not ok then
        notify("Third Person", "Não suportado neste jogo.", 3, "x")
    end
end

function G.setThirdPersonOffset(v)
    G.ThirdPersonOffset = v
    if G.ThirdPersonEnabled then
        pcall(function()
            LP.CameraMinZoomDistance = v
            LP.CameraMaxZoomDistance = math.max(v, 12)
        end)
    end
end

------------------------------------------------------------------------
-- HIGHLIGHT NO ALVO (Highlight custom no jogador selecionado)
------------------------------------------------------------------------
G.TargetHighlightEnabled = false; G.TargetHighlight = nil
G.TargetHighlightColor = Color3.fromRGB(255, 80, 80)

function G.toggleTargetHighlight(enabled)
    G.TargetHighlightEnabled = enabled
    if G.TargetHighlight then G.TargetHighlight:Destroy() G.TargetHighlight = nil end
    if enabled then
        if not G.SpectateTargetName then
            notify("Highlight", "Selecione um player primeiro (aba Visual)!", 3, "alert-circle")
            G.TargetHighlightEnabled = false
            return
        end
        local t = S.Players:FindFirstChild(G.SpectateTargetName)
        if t and t.Character then
            local hl = Instance.new("Highlight")
            hl.Adornee = t.Character
            hl.FillColor = G.TargetHighlightColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.new(1, 1, 1)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = t.Character
            G.TargetHighlight = hl
        end
    end
end

function G.setTargetHighlightColor(c)
    G.TargetHighlightColor = c
    if G.TargetHighlight then G.TargetHighlight.FillColor = c end
end

------------------------------------------------------------------------
-- SPYCHAT (funcional: suporta TextChatService novo E o Chatted legacy)
------------------------------------------------------------------------
G.SpyChatEnabled = false
G.SpyChatConns   = {}
G.SpyChatLog     = {}      -- {player, message, time}
G.SpyChatCallback = nil    -- UI registra aqui pra receber as msgs

local function _spychatPush(playerName, message)
    table.insert(G.SpyChatLog, {
        player = playerName,
        message = message,
        time = os.clock(),
    })
    if #G.SpyChatLog > 300 then table.remove(G.SpyChatLog, 1) end
    if G.SpyChatCallback then
        pcall(function() G.SpyChatCallback(playerName, message) end)
    end
end

local function _hookLegacyChat(p)
    if G.SpyChatConns[p] then return end
    G.SpyChatConns[p] = p.Chatted:Connect(function(msg)
        if G.SpyChatEnabled then _spychatPush(p.Name, msg) end
    end)
end

function G.toggleSpyChat(enabled)
    G.SpyChatEnabled = enabled
    -- limpa conns antigos
    for _, c in pairs(G.SpyChatConns) do pcall(function() c:Disconnect() end) end
    G.SpyChatConns = {}
    if not enabled then return end

    -- 1) PLAYER.CHATTED (legacy — ainda dispara pra TODA mensagem em 99% dos jogos)
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP then _hookLegacyChat(p) end
    end
    G.SpyChatConns["_playerAdded"] = S.Players.PlayerAdded:Connect(function(p)
        _hookLegacyChat(p)
    end)
    G.SpyChatConns["_playerRemoving"] = S.Players.PlayerRemoving:Connect(function(p)
        if G.SpyChatConns[p] then
            G.SpyChatConns[p]:Disconnect()
            G.SpyChatConns[p] = nil
        end
    end)

    -- 2) TEXTCHATSERVICE (novo sistema — pega as mensagens que o legacy não vê)
    local ok = pcall(function()
        local TCS = game:GetService("TextChatService")
        if TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
        -- MessageReceived dispara pra TODAS mensagens (inclui as dos outros)
        G.SpyChatConns["_tcs"] = TCS.MessageReceived:Connect(function(message)
            if not G.SpyChatEnabled then return end
            local status = message.Status
            if status ~= nil and status ~= Enum.TextChatMessageStatus.Success then return end
            local src = message.TextSource
            if not src or src.UserId == LP.UserId then return end
            local plr = S.Players:GetPlayerByUserId(src.UserId)
            _spychatPush(plr and plr.Name or ("User:" .. src.UserId), message.Text)
        end)
        -- gambiarra historica: onPlayerChatted não existe no TCS client-side,
        -- MessageReceived cobre. DisplaySystemMessageInChannel = /commands
        G.SpyChatConns["_tcsChannels"] = TCS.MessageReceived:Connect(function(message)
            if not G.SpyChatEnabled then return end
            if message.TextSource == nil and message.Metadata == nil and message.PrefixText ~= nil then
                -- system message com prefixo (ex: "PlayerName: " de chat tags custom)
            end
        end)
    end)
    if not ok then
        -- jogo antigo sem TCS: o legacy Chatted já cobre
    end
end

function G.setSpyChatCallback(fn)
    G.SpyChatCallback = fn
end

function G.clearSpyChatLog()
    G.SpyChatLog = {}
end

------------------------------------------------------------------------
-- TROLL AUDIOS (IDs públicos pós-2022 — os antigos morreram no audio update)
------------------------------------------------------------------------
G.TrollAudios = {
    { Title = "Vine Boom",              id = 6823153536 },
    { Title = "Vine Boom (LOUD)",       id = 9068519840 },
    { Title = "Miss the Rage",          id = 9124780123 },
    { Title = "Crab Rave",              id = 5410086218 },
    { Title = "Rick Roll (Phonk)",      id = 7363412529 },
    { Title = "HEHEHE HA",              id = 8406005582 },
    { Title = "Bing Chillin",           id = 7280017311 },
    { Title = "Goofy Ahh Laugh",        id = 8418482985 },
    { Title = "I Love Tacos Guy",       id = 9245561450 },
    { Title = "Clash Royale Cry",       id = 8264520060 },
    { Title = "Emotional DAMAGE!",      id = 8362816791 },
    { Title = "FBI Open Up",            id = 1759712659 },
    { Title = "Popcat",                 id = 6107957968 },
    { Title = "Earrape",                id = 6953866301 },
    { Title = "Phonk",                  id = 6911766512 },
    { Title = "Henry Distraction",      id = 5616761718 },
    { Title = "Mario Theme",            id = 6753817247 },
    { Title = "Doomshop",               id = 6770303644 },
    { Title = "Elevator Music",         id = 9119119619 },
    { Title = "Sigma Phonk",            id = 7601924770 },
}
G.TrollVolume = 5
G.TrollAudioPlaying = nil

-- Toca só pra você (funciona em QUALQUER jogo — Sound no SoundService)
function G.playTrollLocal(id, volume)
    if not id then return end
    if G.TrollAudioPlaying then
        pcall(function() G.TrollAudioPlaying:Stop() end)
        pcall(function() G.TrollAudioPlaying:Destroy() end)
        G.TrollAudioPlaying = nil
    end
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = volume or G.TrollVolume or 5
    s.Parent = game:GetService("SoundService")
    s:Play()
    G.TrollAudioPlaying = s
    s.Ended:Connect(function()
        pcall(function() s:Destroy() end)
        if G.TrollAudioPlaying == s then G.TrollAudioPlaying = nil end
    end)
    return s
end

function G.stopTrollAudio()
    if G.TrollAudioPlaying then
        pcall(function() G.TrollAudioPlaying:Stop() end)
        pcall(function() G.TrollAudioPlaying:Destroy() end)
        G.TrollAudioPlaying = nil
    end
end

-- Toca na boombox EQUIPADA (client-side: o som sai do Tool, alguns jogos replicam)
function G.playTrollBoombox(id, volume)
    local char = LP.Character
    if not char then return false end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local sound = t:FindFirstChildWhichIsA("Sound", true)
            if sound then
                sound.SoundId = "rbxassetid://" .. id
                sound.Volume = volume or G.TrollVolume or 5
                sound.Looped = true
                sound:Play()
                return true
            end
        end
    end
    return false
end

------------------------------------------------------------------------
-- CHAMS SIMPLES (materiais ForceField coloridos em todos os inimigos)
------------------------------------------------------------------------
G.ChamsEnabled = false; G.ChamsColor = Color3.fromRGB(0, 255, 170)
G._ChamsOrig = {}

function G.toggleChams(enabled)
    G.ChamsEnabled = enabled
    local function applyChar(char)
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if enabled then
                    if not G._ChamsOrig[part] then G._ChamsOrig[part] = part.Material end
                    part.Material = Enum.Material.ForceField
                    if part:FindFirstChild("RH_ChamsTint") == nil then
                        local t = part:FindFirstChildOfClass("Texture") or part
                        part.Color = G.ChamsColor
                    end
                else
                    part.Material = G._ChamsOrig[part] or part.Material
                    G._ChamsOrig[part] = nil
                end
            end
        end
    end
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP and p.Character then applyChar(p.Character) end
    end
    if not enabled then G._ChamsOrig = {} end
end

------------------------------------------------------------------------
-- EXPLOITS LOCAIS (Bring All, Fling All, BTools, Mapa Invisível, Reset)
------------------------------------------------------------------------

-- BRING ALL: teleporta todos os jogadores até você
function G.bringAll()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr  = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and hum and hum.Health > 0 then
                pcall(function()
                    tr.CFrame = myRoot.CFrame * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3))
                end)
            end
        end
    end
end

-- FLING ALL: arremessa todos os jogadores
G.FlingAllPower = 9000
function G.flingAll(power)
    local vel = power or G.FlingAllPower
    for _, p in ipairs(S.Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr  = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and hum and hum.Health > 0 then
                pcall(function()
                    tr.AssemblyLinearVelocity =
                        Vector3.new(math.random(-10, 10), 10, math.random(-10, 10)).Unit * vel
                end)
            end
        end
    end
end

-- BTOOLS (client-side, HopperBins na Backpack)
G.BToolsEnabled = false; G.BToolsBins = {}
function G.toggleBTools(enabled)
    G.BToolsEnabled = enabled
    for _, b in pairs(G.BToolsBins) do pcall(function() b:Destroy() end) end
    G.BToolsBins = {}
    if not enabled then return end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    for _, binType in ipairs({ Enum.BinType.Tool, Enum.BinType.Clone, Enum.BinType.Delete, Enum.BinType.Grab }) do
        local ok, bin = pcall(function()
            local b = Instance.new("HopperBin")
            b.BinType = binType
            b.Parent = backpack
            return b
        end)
        if ok and bin then table.insert(G.BToolsBins, bin) end
    end
end

-- MAPA INVISÍVEL (client-side, com restore)
G.MapInvisibleEnabled = false; G.MapInvisibleParts = {}
function G.toggleMapInvisible(enabled)
    G.MapInvisibleEnabled = enabled
    if enabled then
        local myChar = LP.Character
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 1 then
                if not (myChar and obj:IsDescendantOf(myChar)) then
                    obj.LocalTransparencyModifier = 1
                    table.insert(G.MapInvisibleParts, obj)
                end
            end
        end
    else
        for _, obj in ipairs(G.MapInvisibleParts) do
            pcall(function() obj.LocalTransparencyModifier = 0 end)
        end
        G.MapInvisibleParts = {}
    end
end

-- RESET RÁPIDO (morte instantânea)
function G.quickReset()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    pcall(function() char:BreakJoints() end)
end

------------------------------------------------------------------------
-- ANTI-VOID (cai do mapa -> volta pra última posição no chão)
------------------------------------------------------------------------
G.AntiVoidEnabled = false; G.AntiVoidY = -50; G.AntiVoidConn = nil
G._LastGroundPos = nil; G._VoidCooldown = 0

function G.toggleAntiVoid(enabled)
    G.AntiVoidEnabled = enabled
    if G.AntiVoidConn then G.AntiVoidConn:Disconnect() G.AntiVoidConn = nil end
    if not enabled then return end
    G.AntiVoidConn = S.Run.Heartbeat:Connect(function()
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        -- registra posição no chão (não durante fly/pulo)
        if hum.FloorMaterial ~= Enum.Material.Air and not G.FlyEnabled then
            G._LastGroundPos = root.Position
        end
        -- caiu pro void?
        if root.Position.Y < G.AntiVoidY and G._LastGroundPos then
            if tick() - G._VoidCooldown < 2 then return end -- anti-loop
            G._VoidCooldown = tick()
            root.CFrame = CFrame.new(G._LastGroundPos + Vector3.new(0, 3, 0))
            notify("Anti-Void", "Você caiu do mapa — reposicionado!", 3, "solar:shield-bold")
        end
    end)
end

function G.setAntiVoidY(v) G.AntiVoidY = v end

------------------------------------------------------------------------
-- FPS BOOSTER (texturas/partículas/decals/shadows OFF, com restore total)
------------------------------------------------------------------------
G.FpsBoostEnabled = false; G._FpsRestore = {}; G._FpsParts = 0

function G.toggleFpsBoost(enabled)
    G.FpsBoostEnabled = enabled
    -- restore se desligando
    if not enabled then
        local L = game:GetService("Lighting")
        for k, v in pairs(G._FpsRestore) do
            pcall(function() L[k] = v end)
        end
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 0
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = true
                elseif obj:IsA("BasePart") and obj:IsA("MeshPart") then
                    -- material já tratado abaixo
                end
            end
        end)
        -- restaura materiais
        pcall(function()
            for part, mat in pairs(G._FpsRestore._mats or {}) do
                part.Material = mat
            end
        end)
        G._FpsRestore = {}
        notify("FPS Boost", "Restaurado.", 2, "x")
        return
    end

    -- ligando: salva e stripa
    local L = game:GetService("Lighting")
    G._FpsRestore = {
        GlobalShadows = L.GlobalShadows,
        FogEnd       = L.FogEnd,
        FogStart     = L.FogStart,
        Brightness   = L.Brightness,
        Technology   = L.Technology,
    }
    pcall(function() L.GlobalShadows = false end)
    pcall(function() L.FogEnd = 9e9; L.FogStart = 9e9 end)
    pcall(function() L.Brightness = 1 end)
    pcall(function() L.Technology = Enum.Technology.Compatibility end)

    local mats = {}
    G._FpsRestore._mats = mats
    local myChar = LP.Character
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("Decal") then
            obj.Transparency = 1
            count += 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            obj.Enabled = false
            count += 1
        elseif obj:IsA("BasePart") and obj:IsA("MeshPart") and obj.TextureID ~= "" then
            if not (myChar and obj:IsDescendantOf(myChar)) then
                mats[obj] = obj.Material
                obj.Material = Enum.Material.SmoothPlastic
                count += 1
            end
        end
        if count > 20000 then break end -- segurança pra mapas gigantes
    end
    G._FpsParts = count
    -- qualidade gráfica mínima
    pcall(function() settings().Rendering.QualityLevel = 1 end)
    notify("FPS Boost", "Ativado! " .. count .. " objetos otimizados.", 3, "solar:rocket-bold")
end

------------------------------------------------------------------------
-- WAYPOINTS (salva posições nomeadas -> TP de volta)
------------------------------------------------------------------------
G.Waypoints = {}

function G.addWaypoint(name, pos)
    if not name or name == "" then return false end
    G.Waypoints[name] = pos
    return true
end

function G.removeWaypoint(name)
    G.Waypoints[name] = nil
end

function G.getWaypointNames()
    local names = {}
    for name in pairs(G.Waypoints) do table.insert(names, name) end
    table.sort(names)
    return names
end

function G.tpToWaypoint(name)
    local pos = G.Waypoints[name]
    if not pos then return false end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

function G.tpBehindTarget(name)
    local t = S.Players:FindFirstChild(name)
    if not t or not t.Character then return false end
    local tr = t.Character:FindFirstChild("HumanoidRootPart")
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not tr or not root then return false end
    -- 3 studs ATRÁS do alvo (na direção contrária ao olhar dele)
    root.CFrame = tr.CFrame * CFrame.new(0, 0, 3)
    return true
end

------------------------------------------------------------------------
-- AIM LOCK INDICATOR (mostra em quem o aimbot travou)
------------------------------------------------------------------------
G.AimLockIndicatorEnabled = false; G._AimIndText = nil; G._AimIndConn = nil

function G.toggleAimLockIndicator(enabled)
    G.AimLockIndicatorEnabled = enabled
    if G._AimIndConn then G._AimIndConn:Disconnect() G._AimIndConn = nil end
    if G._AimIndText then pcall(function() G._AimIndText:Remove() end) G._AimIndText = nil end
    if not enabled then
        -- expõe pro aimbot parar de reportar
        G.CurrentAimTarget = nil
        return
    end
    local ok, txt = pcall(Drawing.new, "Text")
    if not ok then return end
    txt.Size = 15
    txt.Center = false
    txt.Outline = true
    txt.Color = Color3.fromRGB(255, 80, 80)
    txt.Position = Vector2.new(16, 60)
    txt.Visible = false
    G._AimIndText = txt
    G._AimIndConn = S.Run.RenderStepped:Connect(function()
        local t = G.CurrentAimTarget
        if t and t.Parent and t.Character then
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            local root = t.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local dist = math.floor((workspace.CurrentCamera.CFrame.Position - root.Position).Magnitude)
                local adminTag = G.getAdminTag(t)
                txt.Text = "🎯 " .. t.Name .. (adminTag or "") .. " (" .. dist .. "m)"
                if adminTag and G.AdminTagRGB then
                    txt.Color = Color3.fromHSV(G._AdminTagHue, 1, 1)  -- sincronizado com o hue global
                elseif adminTag then
                    txt.Color = G.AdminTagColor
                else
                    txt.Color = Color3.fromRGB(255, 80, 80)
                end
                txt.Visible = true
                return
            end
        end
        txt.Visible = false
    end)
end

------------------------------------------------------------------------
-- JOIN/LEAVE LOGGER
------------------------------------------------------------------------
G.JoinLeaveLogEnabled = false; G._JoinLeaveConns = {}

function G.toggleJoinLeaveLog(enabled)
    G.JoinLeaveLogEnabled = enabled
    for _, c in pairs(G._JoinLeaveConns) do pcall(function() c:Disconnect() end) end
    G._JoinLeaveConns = {}
    if not enabled then return end
    table.insert(G._JoinLeaveConns, S.Players.PlayerAdded:Connect(function(p)
        if G.JoinLeaveLogEnabled then
            notify("Entrou", p.Name .. " entrou no servidor.", 3, "solar:user-plus-bold")
        end
    end))
    table.insert(G._JoinLeaveConns, S.Players.PlayerRemoving:Connect(function(p)
        if G.JoinLeaveLogEnabled then
            notify("Saiu", p.Name .. " saiu do servidor.", 3, "solar:user-minus-bold")
        end
    end))
end

------------------------------------------------------------------------
-- CHAT SPAMMER (com guard anti-flood: delay mínimo 0.4s)
------------------------------------------------------------------------
G.ChatSpamEnabled = false; G.ChatSpamMessage = ""; G.ChatSpamDelay = 1; G._ChatSpamThread = nil

function G.toggleChatSpam(enabled)
    G.ChatSpamEnabled = enabled
    if G._ChatSpamThread then
        pcall(function() coroutine.close(G._ChatSpamThread) end)
        G._ChatSpamThread = nil
    end
    if not enabled then return end
    if not G.ChatSpamMessage or G.ChatSpamMessage == "" then
        notify("Chat Spammer", "Defina uma mensagem primeiro!", 3, "alert-circle")
        G.ChatSpamEnabled = false
        return
    end
    task.spawn(function()
        while G.ChatSpamEnabled do
            pcall(function()
                -- TextChatService (novo): manda de verdade pro server
                local TCS = game:GetService("TextChatService")
                local channel = TCS.TextChannels and TCS.TextChannels:FindFirstChild("RBXGeneral")
                if TCS.ChatVersion == Enum.ChatVersion.TextChatService and channel then
                    local ok = pcall(function()
                        channel:SendAsync(G.ChatSpamMessage)
                    end)
                    if ok then return end -- enviado, não tenta legacy
                end
                -- legacy SayMessageRequest (jogos antigos)
                local RS = game:GetService("ReplicatedStorage")
                local ev = RS:FindFirstChild("DefaultChatSystemChatEvents")
                if ev then
                    local say = ev:FindFirstChild("SayMessageRequest")
                    if say then say:FireServer(G.ChatSpamMessage, "All") end
                end
            end)
            task.wait(math.max(G.ChatSpamDelay or 1, 0.4)) -- anti-flood guard
        end
    end)
end

function G.setChatSpamMessage(msg) G.ChatSpamMessage = msg end
function G.setChatSpamDelay(v) G.ChatSpamDelay = math.max(v, 0.4) end

------------------------------------------------------------------------
-- ANTI-STAFF (detecção: team suspeita, lista manual, grupo com rank)
------------------------------------------------------------------------
G.StaffList       = {}   -- usernames manuais (lowercase) -> display
G.StaffTeamNames  = { ["staff"]=true, ["admin"]=true, ["mod"]=true, ["moderator"]=true,
                      ["owner"]=true, ["dev"]=true, ["developer"]=true, ["moderador"]=true }
G.StaffMinGroupRank = 200  -- rank mínimo no grupo pra contar como staff
G.StaffDetected   = {}   -- [player] = true (cache)

function G.isStaff(p)
    if not p then return false end
    if G.StaffDetected[p] ~= nil then return G.StaffDetected[p] end
    -- 1) lista manual
    if G.StaffList[string.lower(p.Name)] then
        G.StaffDetected[p] = true
        return true
    end
    -- 2) team suspeita
    local team = p.Team
    if team and G.StaffTeamNames[string.lower(team.Name)] then
        G.StaffDetected[p] = true
        return true
    end
    -- 3) grupo (async: checa 1x, cacheia)
    task.spawn(function()
        local ok, rank = pcall(function()
            if p.GetRankInGroup then
                return p:GetRankInGroup(game.CreatorId)
            end
            return 0
        end)
        if ok and rank and rank >= G.StaffMinGroupRank then
            G.StaffDetected[p] = true
            if G.JoinLeaveLogEnabled then
                notify("⚠️ STAFF", p.Name .. " é staff (grupo rank " .. rank .. ")!", 5)
            end
        else
            if G.StaffDetected[p] == nil then G.StaffDetected[p] = false end
        end
    end)
    -- resposta sincrona otimista (os outros 2 checks)
    return G.StaffDetected[p] == true
end

function G.addStaff(name)
    if name and name ~= "" then
        G.StaffList[string.lower(name)] = name
        G.StaffDetected = {}
    end
end

function G.removeStaff(name)
    if name then
        G.StaffList[string.lower(name)] = nil
        G.StaffDetected = {}
    end
end

function G.getStaffNames()
    local names = {}
    for _, display in pairs(G.StaffList) do table.insert(names, display) end
    table.sort(names)
    return names
end

------------------------------------------------------------------------
-- ESP INFO: tag de admin (cor fixa ou RGB animado)
------------------------------------------------------------------------
G.AdminTagEnabled   = true
G.AdminTagColor     = Color3.fromRGB(255, 40, 40)   -- vermelho default
G.AdminTagRGB       = false                          -- RGB animado
G._AdminTagHue      = 0

function G.setAdminTagColor(c)     G.AdminTagColor = c end
function G.setAdminTagRGB(on)      G.AdminTagRGB = on and true or false end
function G.setAdminTagEnabled(on)  G.AdminTagEnabled = on and true or false end

-- chamado pelo loop do ESP Info pra cada player: retorna texto extra e cor
function G.getAdminTag(p)
    if not G.AdminTagEnabled then return nil, nil end
    if not G.isStaff(p) then return nil, nil end
    local color = G.AdminTagColor
    if G.AdminTagRGB then
        -- RGB animado: hue gira ~0.25 ciclos/s (mesma vibe dos RGB themes)
        G._AdminTagHue = (G._AdminTagHue + 0.004) % 1
        color = Color3.fromHSV(G._AdminTagHue, 1, 1)
    end
    return " [ADMIN]", color
end

------------------------------------------------------------------------
-- AUDIO PLAYER CUSTOM (qualquer ID de som, local)
------------------------------------------------------------------------
G.CustomAudioId = nil

function G.playCustomAudio(idText, volume)
    local id = tonumber(idText)
    if not id then
        notify("Audio", "ID inválido — use só números (ex: 142376088).", 3)
        return
    end
    G.stopTrollAudio()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = volume or G.TrollVolume or 5
    s.Parent = game:GetService("SoundService")
    s:Play()
    G.TrollAudioPlaying = s
    s.Ended:Connect(function()
        pcall(function() s:Destroy() end)
        if G.TrollAudioPlaying == s then G.TrollAudioPlaying = nil end
    end)
    notify("Audio", "Tocando ID " .. id, 2)
end

------------------------------------------------------------------------
-- AUTO RECONNECT (desconectou/crashou -> rejoin no mesmo server)
------------------------------------------------------------------------
G.AutoReconnectEnabled = false
G._AutoReconnectConn = nil

function G.toggleAutoReconnect(enabled)
    G.AutoReconnectEnabled = enabled
    if G._AutoReconnectConn then G._AutoReconnectConn:Disconnect() G._AutoReconnectConn = nil end
    if not enabled then return end
    -- catch no erro de conexão: quando o client perde o server, entra aqui
    G._AutoReconnectConn = LP.OnTeleport:Connect(function(teleportState, placeId, _, errMsg)
        if not G.AutoReconnectEnabled then return end
        -- Failed/Erro de rede no teleport pra um jogo (não kick manual)
        if teleportState == Enum.TeleportState.Failed then
            task.wait(2)
            pcall(function()
                game:GetService("TeleportService"):Teleport(placeId, LP)
            end)
        end
    end)
end

------------------------------------------------------------------------
-- PANIC BUTTON (para 100% das funções com 1 clique, sem eject)
------------------------------------------------------------------------
function G.panic()
    G.unloadAll()
    notify("PANIC", "Todas as funções desligadas.", 3)
end

------------------------------------------------------------------------
-- UNLOAD ALL — usado ao ejetar o script: desliga tudo e reverte
------------------------------------------------------------------------
function G.unloadAll()
    -- 1) features com conns de loop (desligar primeiro: param o efeito)
    G.AimbotEnabled.normal = false; G.AimbotEnabled.rage = false
    pcall(function() if G.AimbotConns.normal then G.AimbotConns.normal:Disconnect() end end)
    pcall(function() if G.AimbotConns.rage  then G.AimbotConns.rage:Disconnect()  end end)

    pcall(function() G.toggleESP(false) end)
    pcall(function() G.toggleEspLines(false) end)
    pcall(function() G.toggleHitboxESP(false) end)
    pcall(function() G.toggleHitbox(false) end)          -- restaura hitboxes originais
    pcall(function() G.toggleSilentAim(false) end)
    pcall(function() G.toggleHitPred(false) end)
    pcall(function() G.toggleNoClip(false) end)
    pcall(function() G.toggleFly(false) end)             -- destrói BV/BG, PlatformStand off
    pcall(function() G.toggleSpin(false) end)
    pcall(function() G.toggleFlingSpin(false) end)       -- remove BAV, restaura colisão
    pcall(function() G.toggleFakeTP(false) end)
    pcall(function() G.toggleLoopTP(false) end)
    pcall(function() G.toggleOrbit(false) end)
    pcall(function() G.toggleAntiRagdoll(false) end)
    pcall(function() G.toggleAutoParry(false) end)
    pcall(function() G.toggleGod(false) end)             -- reseta HP
    pcall(function() G.toggleInvisible(false) end)
    pcall(function() G.toggleInfJump(false) end)
    pcall(function() G.toggleAntiAFK(false) end)
    pcall(function() G.toggleFullbright(false) end)      -- restaura Lighting
    pcall(function() G.toggleNoFog(false) end)           -- restaura Fog
    pcall(function() G.toggleXray(false) end)            -- restaura materiais
    pcall(function() G.toggleFreecam(false) end)         -- câmera volta ao normal
    pcall(function() G.toggleHoverName(false) end)
    pcall(function() G.toggleRadar(false) end)
    pcall(function() G.toggleReach(false) end)
    pcall(function() G.toggleKillAura(false) end)
    pcall(function() G.toggleClickTP(false) end)
    pcall(function() G.stopSpectate() end)
    pcall(function() G.toggleTriggerBot(false) end)
    pcall(function() G.toggleAutoClicker(false) end)
    pcall(function() G.toggleCrosshair(false) end)
    pcall(function() G.toggleCamFOV(false) end)          -- FOV da câmera volta a 70
    pcall(function() G.toggleSpeedLock(false) end)
    pcall(function() G.toggleJumpLock(false) end)
    pcall(function() G.toggleAutoRespawn(false) end)
    pcall(function() G.toggleInventoryWebhook(false) end)
    pcall(function() G.toggleSprint(false) end)
    pcall(function() G.toggleThirdPerson(false) end)
    pcall(function() G.toggleTargetHighlight(false) end)
    pcall(function() G.toggleChams(false) end)
    pcall(function() G.toggleBTools(false) end)
    pcall(function() G.toggleEspBones(false) end)
    pcall(function() G.toggleEspBox(false) end)
    pcall(function() G.toggleEspHealth(false) end)
    pcall(function() G.toggleEspInfo(false) end)
    pcall(function() G.toggleAntiVoid(false) end)
    pcall(function() G.toggleFpsBoost(false) end)
    pcall(function() G.toggleAimLockIndicator(false) end)
    pcall(function() G.toggleJoinLeaveLog(false) end)
    pcall(function() G.toggleChatSpam(false) end)
    pcall(function() G.toggleAutoReconnect(false) end)
    pcall(function() G.toggleSpyChat(false) end)
    pcall(function() G.stopTrollAudio() end)
    pcall(function() G.toggleMapInvisible(false) end)

    -- 2) estado que não tem toggle off dedicado
    G.SpinEnabled = false
    G.FreezeEnabled = false
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if myRoot then myRoot.Anchored = false end
    G.AntiKickEnabled = false
    G.RemoteSpyEnabled = false
    G.TriggerBotEnabled = false; G.AutoClickerEnabled = false

    -- 3) sprites do Drawing API (FOV circle, crosshair, esp lines)
    pcall(function() if G.FovCircle then G.FovCircle:Remove() end end)
    G.FovCircle = nil
    pcall(function() if G._FovRenderConn then G._FovRenderConn:Disconnect() end end)
    G._FovRenderConn = nil
    for _, d in pairs(G.CrosshairDrawings or {}) do pcall(function() d:Remove() end) end
    G.CrosshairDrawings = {}
    pcall(function()
        for _, d in pairs(G.EspLineDrawings or {}) do pcall(function() d:Remove() end) end
        G.EspLineDrawings = {}
        if G._EspLinesByPlayer then
            for _, d in pairs(G._EspLinesByPlayer) do pcall(function() d:Remove() end) end
            G._EspLinesByPlayer = nil
        end
    end)

    -- 4) conns persistentes internos
    pcall(function() if G._ReconnectConn  then G._ReconnectConn:Disconnect()  end end)
    pcall(function() if G.HitboxESPConn   then G.HitboxESPConn:Disconnect()   end end)
    pcall(function() if G._EspLinesRemoveConn then G._EspLinesRemoveConn:Disconnect() end end)
    pcall(function() if G.InvWebhookConn  then G.InvWebhookConn:Disconnect()  end end)
    pcall(function() if G.SpectateConn     then G.SpectateConn:Disconnect()   end end)
    pcall(function() if G.StatLockConn     then G.StatLockConn:Disconnect()  end end)
    pcall(function() if G.CamFOVConn       then G.CamFOVConn:Disconnect()     end end)
    pcall(function() if G.GodConn          then G.GodConn:Disconnect()       end end)
    pcall(function() if G.InvisConn        then G.InvisConn:Disconnect()     end end)
    for _, c in pairs(G.XrayConns or {}) do pcall(function() c:Disconnect() end) end
    G.XrayConns = {}
    for p in pairs(G.EspListeners or {}) do
        for _, c in pairs(G.EspListeners[p]) do pcall(function() c:Disconnect() end) end
    end
    G.EspListeners = {}
    for _, c in pairs(G.FreecamConns or {}) do pcall(function() c:Disconnect() end) end
    G.FreecamConns = {}

    -- 5) listeners do ESP (Highlight/Billboard) — removeAllESP cuida dos objetos
    pcall(function() G.removeAllESP() end)

    -- 6) gravidade padrão + GUI do radar
    pcall(function() workspace.Gravity = 196.2 end)
    pcall(function() if G._RadarGui then G._RadarGui:Destroy() end end)

    -- 7) reconectores de player (ESP/hitbox CharacterAdded)
    pcall(function()
        for _, c in pairs(G._CharConns or {}) do c:Disconnect() end
        G._CharConns = {}
    end)

    notify("RoyalHub", "Todas as funções desligadas.", 3, "solar:check-bold")
end

------------------------------------------------------------------------
-- playerValues (lista de jogadores para dropdowns)
------------------------------------------------------------------------
G.playerValues = {}
for _, p in ipairs(S.Players:GetPlayers()) do
    table.insert(G.playerValues, { Title = p.Name, Player = p })
end
S.Players.PlayerAdded:Connect(function(p)
    table.insert(G.playerValues, { Title = p.Name, Player = p })
end)
S.Players.PlayerRemoving:Connect(function(p)
    for i, v in ipairs(G.playerValues) do
        if v.Title == p.Name then table.remove(G.playerValues, i) break end
    end
end)

------------------------------------------------------------------------
G.emoteValues = G.getEmoteValues()

print("[RoyalHub] Functions.lua carregado! "..#G.playerValues.." jogadores na lista.")