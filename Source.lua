local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
_G.RH_WindUI = WindUI

local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()

local functionsLoaded = false
task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BadOctop4s/Functions/refs/heads/main/Functions.lua"))()
    functionsLoaded = true
end)

while not functionsLoaded do task.wait() end
task.wait(0.5)

local G = _G.RH
assert(G, "[RoyalHub] _G.RH nao foi definido! Verifique o Functions.lua")

-- =====================================================================
-- Carrega o banco de ilhas ANTES de criar qualquer UI (síncrono)
-- =====================================================================
do
    local ok, err = pcall(function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/BadOctop4s/Source/refs/heads/main/Islands.lua"
        ))()
    end)
    if not ok then
        warn("[RoyalHub] Falha ao carregar Islands.lua: " .. tostring(err))
    end
end

------------------------------*REQUEST*---------------------------

local request = syn and syn.request or http_request or request
local HttpService = game:GetService("HttpService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1497006875890155644/LzxlG6TEGrzHC8dWW8ZM-n0amJDMQrN22GF_W0u_8_mg5RppBSCIRbjrkKnQop6GLPOK"

local function sendLog(data)
    if not request then
        warn("Executor não suporta request")
        return
    end

    local payload = {
        username = "Royal Hub Logs",
        avatar_url = "https://i.imgur.com/7YV9F8k.png", -- pode trocar pela sua logo
        embeds = {
            {
                title = data.title or "Log",
                description = data.description or "",
                color = data.color or 65280, -- verde padrão

                fields = data.fields or {},

                footer = {
                    text = "Royal Hub • " .. os.date("%d/%m/%Y %H:%M:%S")
                }
            }
        }
    }

    request({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(payload)
    })
end


WindUI:SetNotificationLower(true)


--------------------------*Animações de Camera*-------------------------
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

repeat task.wait() until camera and player.Character
local hrp = player.Character:WaitForChild("HumanoidRootPart")

local function IntroCutscene()
    camera.CameraType = Enum.CameraType.Scriptable

    local originalFOV = camera.FieldOfView
    camera.FieldOfView = 60

    -- direção que o player olha
    local look = hrp.CFrame.LookVector

    -- posições (AGORA NA FRENTE)
    local startPos = hrp.Position + look * 15 + Vector3.new(0, 6, 0)
    local midPos   = hrp.Position + look * 10 + Vector3.new(6, 5, 0)
    local endPos   = hrp.Position + look * 6  + Vector3.new(0, 4, 0)

    local cf1 = CFrame.new(startPos, hrp.Position)
    local cf2 = CFrame.new(midPos, hrp.Position)
    local cf3 = CFrame.new(endPos, hrp.Position)

    -- movimento 1
    local t1 = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Sine), {
        CFrame = cf1
    })
    t1:Play()
    t1.Completed:Wait()

    -- movimento 2 (lateral)
    local t2 = TweenService:Create(camera, TweenInfo.new(2.5, Enum.EasingStyle.Quad), {
        CFrame = cf2
    })
    t2:Play()

    -- zoom
    for i = 1, 15 do
        camera.FieldOfView -= 0.5
        task.wait(0.05)
    end

    t2.Completed:Wait()

    -- movimento final
    local t3 = TweenService:Create(camera, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
        CFrame = cf3
    })
    t3:Play()
    t3.Completed:Wait()

    task.wait(0.5)

    camera.FieldOfView = originalFOV
    camera.CameraType = Enum.CameraType.Custom
end

local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

repeat task.wait() until camera and player.Character
local char = player.Character
local hrp = char:WaitForChild("HumanoidRootPart")

local function BossEntryInvalid()
    camera.CameraType = Enum.CameraType.Scriptable

    local originalFOV = camera.FieldOfView
    camera.FieldOfView = 70

    local look = hrp.CFrame.LookVector

    -- posições (na frente)
    local farPos  = hrp.Position + look * 20 + Vector3.new(0, 8, 0)
    local midPos  = hrp.Position + look * 12 + Vector3.new(6, 6, 0)
    local closePos= hrp.Position + look * 6  + Vector3.new(0, 4, 0)

    local cf1 = CFrame.new(farPos, hrp.Position)
    local cf2 = CFrame.new(midPos, hrp.Position)
    local cf3 = CFrame.new(closePos, hrp.Position)

    -- 🎥 entrada lenta (tipo boss chegando)
    local t1 = TweenService:Create(camera, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        CFrame = cf1
    })
    t1:Play()
    t1.Completed:Wait()

    -- 🕺 emote começa aqui
    task.spawn(PlayEmote)

    -- 🎬 movimento lateral dramático
    local t2 = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        CFrame = cf2
    })
    t2:Play()

    -- zoom progressivo
    for i = 1, 20 do
        camera.FieldOfView -= 0.7
        task.wait(0.04)
    end

    t2.Completed:Wait()

    -- 💥 aproximação rápida (impacto)
    local t3 = TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        CFrame = cf3
    })
    t3:Play()
    t3.Completed:Wait()

    -- 💥 camera shake simples
    for i = 1, 8 do
        camera.CFrame = camera.CFrame * CFrame.new(
            math.random(-2,2)/10,
            math.random(-2,2)/10,
            0
        )
        task.wait(0.03)
    end

    task.wait(0.5)

    camera.FieldOfView = originalFOV
    camera.CameraType = Enum.CameraType.Custom
end
--------------------------*Blur*---------------------------
local Lighting = game:GetService("Lighting")

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

local function ativarBlur()
    
    local tween = game:GetService("TweenService"):Create(
        blur,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = 20 }
    )
    tween:Play()
end

local function desativarBlur()
    local tween = game:GetService("TweenService"):Create(
        blur,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = 0 }
    )
    tween:Play()
    tween.Completed:Connect(function()
        blur.Size = 0
    end)
end

-------------------------------* Cores *--------------------------
local Purple  = Color3.fromHex("#7775F2")
local Yellow  = Color3.fromHex("#ECA201")
local Green   = Color3.fromHex("#10C550")
local Grey    = Color3.fromHex("#83889E")
local Blue    = Color3.fromHex("#257AF7")
local Red     = Color3.fromHex("#ea0909")
local Gray    = Color3.fromHex("#2C2F38")
local DarkGray = Color3.fromHex("#1B1C20")

-------------------------------* Ícones *-------------------------------
local Key    = "geist:key"
local box    = "geist:box"
local bug    = "geist:bug"
local star   = "geist:star"
local cloud  = "geist:cloud"
local shield = "geist:shield-check"

-------------------------------* Serviços *-------------------------------
local S = {
    Players = game:GetService("Players"),
    Tween   = game:GetService("TweenService"),
    RS      = game:GetService("ReplicatedStorage"),
    WS      = game:GetService("Workspace"),
    Run     = game:GetService("RunService"),
    UI      = game:GetService("UserInputService"),
    Sound   = game:GetService("SoundService"),
}
local LP = S.Players.LocalPlayer

-------------------------------* Som de notificação *-------------------------------
local NotifySound = Instance.new("Sound")
NotifySound.SoundId = "rbxassetid://6518811702"
NotifySound.Volume  = 1.0
NotifySound.Parent  = game:GetService("SoundService")

-------------------------------* Variáveis auxiliares de UI *-------------------------------
local SelectedEmote         = nil
local SelectedPlayerToView  = nil
local FlingTargetPlayer     = nil
local FlingPower            = 1000
local LoopFlingEnabled      = false
local LoopFlingConnection   = nil
local CopyTargetPlayer      = nil
local currentAudioId        = nil
local currentVolume         = 5
local trollAudios           = {} -- placeholder (em desenvolvimento)

-------------------------------* Temas *-------------------------------
WindUI:AddTheme({
    Name = "Hutao By Einzbern",
    Accent = Color3.fromHex("#18181b"), Background = Color3.fromHex("#000000"),
    Outline = Color3.fromHex("#991b1b"), Text = Color3.fromHex("#991b1b"),
    Placeholder = Color3.fromHex("#141414"), Button = Color3.fromHex("#dc2626"),
    Icon = Color3.fromHex("#ef4444"),
})
WindUI:AddTheme({
    Name = "White",
    Accent = Color3.fromHex("#646466"), Background = Color3.fromHex("#bba7a7"),
    Outline = Color3.fromHex("#020101"), Text = Color3.fromHex("#000000"),
    Placeholder = Color3.fromHex("#7a7a7a"), Button = Color3.fromHex("#000000"),
    Icon = Color3.fromHex("#000000"),
})
WindUI:AddTheme({
    Name = "Main Theme",
    Accent = Color3.fromHex("#222121"), Background = Color3.fromHex("#000000"),
    Outline = Color3.fromHex("#a79e9e"), Text = Color3.fromHex("#fff4f4"),
    Placeholder = Color3.fromHex("#797777"), Button = Color3.fromHex("#db0000"),
    Icon = Color3.fromHex("#a18e8e"),
})
WindUI:AddTheme({
    Name = "RedX Hub",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#000000"), Transparency = 0 },
        ["60"]  = { Color = Color3.fromHex("#0152c3"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#b30303"), Transparency = 0 },
    }, { Rotation = 80 }),
})
WindUI:AddTheme({
    Name = "Dark Amoled ( Default )",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#000000"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#000000"), Transparency = 0 },
    }, { Rotation = 80 }),
})
WindUI:AddTheme({
    Name = "Midnight",
    Accent = Color3.fromHex("#1e3a8a"),
    Background = Color3.fromHex("#0c1e42"),
    Outline = Color3.fromHex("#bfdbff"),
    Text = Color3.fromHex("#dbeafe"),
    Placeholder = Color3.fromHex("#2f74d1"),
    Button = Color3.fromHex("#2563eb"),
    Icon = Color3.fromHex("#5591f4")
})
WindUI:AddTheme({
    Name = "Crimson",
    Accent = Color3.fromHex("#b91c1c"),
    Background = Color3.fromHex("#0c0404"),
    Outline = Color3.fromHex("#161616"),
    Text = Color3.fromHex("#fef2f2"),
    Placeholder = Color3.fromHex("#6f757b"),
    Button = Color3.fromHex("#991b1b"),
    Icon = Color3.fromHex("#dc2626")
})
WindUI:AddTheme({
    Name = "Snow",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#363434"),
    Outline = Color3.fromHex("#535151"),
    Text = Color3.fromHex("#aca1a1"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#414142")
})
WindUI:AddTheme({
    Name = "Tundra",
    Accent = Color3.fromHex("#342a1e"),
    Background = Color3.fromHex("#1c1002"),
    Outline = Color3.fromHex("#6b5a45"),
    Text = Color3.fromHex("#f5ebdd"),
    Placeholder = Color3.fromHex("#9c8b72"),
    Button = Color3.fromHex("#342a1e"),
    Icon = Color3.fromHex("#c9b79c")
})
WindUI:AddTheme({
    Name = "Samurai Dark",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#000000"),
    Outline = Color3.fromHex("#9b9b9b"),
    Text = Color3.fromHex("#aca1a1"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#414142")
})
WindUI:AddTheme({
    Name = "Monokai",
    Accent = Color3.fromHex("#fc9867"),
    Background = Color3.fromHex("#191622"),
    Outline = Color3.fromHex("#78dce8"),
    Text = Color3.fromHex("#fcfcfa"),
    Placeholder = Color3.fromHex("#6f6f6f"),
    Button = Color3.fromHex("#ab9df2"),
    Icon = Color3.fromHex("#a9dc76")
})
WindUI:AddTheme({
    Name = "Moonlight",
    Accent = Color3.fromHex("#18181B"),
    Background = Color3.fromHex("#000000"),
    Outline = Color3.fromHex("#989898"),
    Text = Color3.fromHex("#D4D4D4"),
    Placeholder = Color3.fromHex("#7A7A7A"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#414142")
})
WindUI:AddTheme({
    Name = "Lunar",
    Accent = Color3.fromHex("#0a0f1e"),
    Background = Color3.fromHex("#101722"),
    Outline = Color3.fromHex("#2391ff"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#2391ff"),
    Button = Color3.fromHex("#2563eb"),
    Icon = Color3.fromHex("#2391ff")
})

WindUI:AddTheme({
    Name = "Startorch",
    Accent = Color3.fromHex("#b45309"),
    Background = Color3.fromHex("#1c1003"),
    Outline = Color3.fromHex("#fcd34d"),
    Text = Color3.fromHex("#fffbeb"),
    Placeholder = Color3.fromHex("#fbbf24"),
    Button = Color3.fromHex("#d97706"),
    Icon = Color3.fromHex("#f59e0b")
})
WindUI:AddTheme({
    Name = "Nod Krai",
    Accent = Color3.fromHex("#1e3a8a"),
    Background = Color3.fromHex("#0a0f1e"),
    Outline = Color3.fromHex("#bfdbfe"),
    Text = Color3.fromHex("#dbeafe"),
    Placeholder = Color3.fromHex("#2f74d1"),
    Button = Color3.fromHex("#2563eb"),
    Icon = Color3.fromHex("#5591f4")
})
WindUI:AddTheme({
    Name = "Hoshimi",
    Accent = Color3.fromHex("#166534"),
    Background = Color3.fromHex("#0a1b0f"),
    Outline = Color3.fromHex("#101010"),
    Text = Color3.fromHex("#f0fdf4"),
    Placeholder = Color3.fromHex("#4fbf7a"),
    Button = Color3.fromHex("#16a34a"),
    Icon = Color3.fromHex("#4ade80")
})
WindUI:AddTheme({
    Name = "Kumokiri",
    Accent = Color3.fromHex("#991b1b"),
    Background = Color3.fromHex("#000000"),
    Outline = Color3.fromHex("#0a0f1e"),
    Text = Color3.fromHex("#575656"),
    Placeholder = Color3.fromHex("#1f1d1d"),
    Button = Color3.fromHex("#991b1b"),
    Icon = Color3.fromHex("#dc2626")
})
WindUI:AddTheme(
    { Name = "Emerald",
    Accent = Color3.fromHex("#047857"),
    Background = Color3.fromHex("#011411"),
    Outline = Color3.fromHex("#a7f3d0"),
    Text = Color3.fromHex("#ecfdf5"),
    Placeholder = Color3.fromHex("#3fbf8f"),
    Button = Color3.fromHex("#059669"),
    Icon = Color3.fromHex("#10b981")
})
WindUI:AddTheme({
    Name = "Lost At Sea",
    Accent = Color3.fromHex("#000000"),
    Background = Color3.fromHex("#0c1e42"),
    Outline = Color3.fromHex("#131f55"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#040661"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#c7d2fe"),
})
WindUI:AddTheme({
    Name = "Night Fall",
    Accent = Color3.fromHex("#1e3a8a"),
    Background = Color3.fromHex("#0a0f1e"),
    Outline = Color3.fromHex("#141414"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#2f74d1"),
    Button = Color3.fromHex("#010015"),
    Icon = Color3.fromHex("#4d95ff")
})
WindUI:AddTheme({
  Name = "Obsidian",
  
  Accent = Color3.fromHex("#3730a3"),
  Background = Color3.fromHex("#0f0a2e"),
  Outline = Color3.fromHex("#c7d2fe"),
  Text = Color3.fromHex("#f1f5f9"),
  Placeholder = Color3.fromHex("#7078d9"),
  Button = Color3.fromHex("#4f46e5"),
  Icon = Color3.fromHex("#6366f1"),
})
WindUI:AddTheme({
  Name = "Deep Dreams",
  
  Accent = Color3.fromHex("#991b1b"),
  Background = Color3.fromHex("#000000"),
  Outline = Color3.fromHex("#52525b"),
  Text = Color3.fromHex("#ffffff"),
  Placeholder = Color3.fromHex("#7a7a7a"),
  Button = Color3.fromHex("#99111b"),
  Icon = Color3.fromHex("#dc2626"),
})

WindUI:AddTheme({
    Name = "Solar Theme",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#ff6a30"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("ffe72f"),  Transparency = 0 },
    }, { Rotation = 80 })
})
WindUI:AddTheme({
    Name = "CyberPunk",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#d1b201"), Transparency = 0 },
        ["50"]  = { Color = Color3.fromHex("#000000"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#eeff00"), Transparency = 0 },
    }, { Rotation = 90 })
})
WindUI:AddTheme({
    Name = "Neon Lights",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#ff00ff"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#00ffff"), Transparency = 0 },
    }, { Rotation = 90 })
})

-------------------------------* Notificações iniciais *-------------------------------

-- WindUI:Notify({ Title = "Royal Hub - Aviso!", Content = "Script em desenvolvimento, funções podem quebrar com o decorrer do tempo.", Duration = 6, Icon = "bug" })

-------------------------------* Janela principal *-------------------------------

Junkie.service    = 'royalhubservice'
Junkie.identifier = '1083214'
Junkie.provider   = 'Mixed'
getgenv().SCRIPT_KEY = nil

WindUI.Services.junkiedevelopment = {
    Name = 'Junkie Development',
    Icon = 'shield-check',
    Args = { 'ServiceId', 'ApiKey', 'Provider' },

    New = function()

        local function Verify(key)
            local result = Junkie.check_key(key)

            if result and result.valid then

                -- salva key
                if result.message == 'KEYLESS' then
                    getgenv().SCRIPT_KEY = 'KEYLESS'
                else
                    getgenv().SCRIPT_KEY = key
                end

                IntroCutscene()
                -- LOG DE SUCESSO
                sendLog({
                    title = "Key Validada",
                    description = "Usuário passou pelo sistema de key",
                    color = 65280,

                    fields = {
                        {
                            name = "Player",
                            value = game.Players.LocalPlayer.Name,
                            inline = true
                        },
                        {
                            name = "Key",
                            value = key:sub(1,5) .. "...",
                            inline = true
                        },
                        {
                            name = "Executor",
                            value = identifyexecutor and identifyexecutor() or "Unknown",
                            inline = true
                        }
                    }
                })

                return true, 'Key valid'
            end

            BossEntryInvalid()
            -- LOG DE ERRO
            sendLog({
                title = " Key Inválida",
                description = "Tentativa de key inválida",
                color = 16711680,

                fields = {
                    {
                        name = " Player",
                        value = game.Players.LocalPlayer.Name,
                        inline = true
                    },
                    {
                        name = "Key",
                        value = tostring(key),
                        inline = true
                    }
                }
            })

            return false, result and (result.error or "Invalid key")
        end

        local function Copy()
            local link = "https://jnkie.com/get-key/royalhub"

            if setclipboard then
                setclipboard(link)
            else
                print("Copie manualmente:", link)
            end

            return link
        end

        return {
            Verify = Verify,
            Copy = Copy
        }
    end
}   

WindUI:Notify({
    Title = "Aviso",
    Content = "Carregando UI, pode ocorrer travamentos até a conclusão..",
    Duration = 2
})

WindUI:Notify({
    Title = "Aviso!",
    Content = "Não feche a UI enquanto está carregando!",
    Duration = 4,
    Icon = "warning"
})

local Window = WindUI:CreateWindow({
    Title  = '<font color="#c8ee1f">RoyalHub</font>',
    Author = "Eodraxkk & Einzbern      ",
    Folder = "RoyalHub",
    Icon   = "solar:crown-minimalistic-bold",
    Theme  = "Dark Amoled ( Default )",
    IconSize = 12*2,
    NewElements = true,
    Size = UDim2.fromOffset(800,500),
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Royal Hub",
        CornerRadius = UDim.new(1,0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = true,
        Scale = 0.5,
        Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f"))
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            local player = LP
            NotifySound:Play()
            Window:Dialog({
                Icon = "user",
                Title = player.Name,
                IconThemed = true,
                Content = "UserID: "..player.UserId..
                          "\nConta criada há "..player.AccountAge.." dias"..
                          "\nTime: "..(player.Team and player.Team.Name or "Nenhum"),
                Buttons = {
                    { Title = "Copiar UserID", Icon = "copy", Variant = "secondary", Callback = function()
                        setclipboard(tostring(player.UserId))
                        WindUI:Notify({ Title = "Copiado!", Content = "UserID copiado para a área de transferência.", Duration = 2, Icon = "copy" })
                    end },
                    { Title = "Fechar", Icon = "x", Variant = "secondary", Callback = function() end },
                }
            })
        end,
    },
    KeySystem = {
        Note = "É necessário uma key para utilizar o Royal Hub.",
        API = {
            { 
                Title = "Junkie Development",
                Desc = "Click para copiar o link",
                Icon = "shield-check",
                Type = 'junkiedevelopment',
            }
        }
    }
})

Window:OnOpen(function()
  ativarBlur()
end)

ativarBlur()

Window:OnClose(function()
  desativarBlur()
  Window:LockAll()
end)

task.spawn(function()
    while not getgenv().SCRIPT_KEY do
    end
end)

local ConfigMenu = Window.ConfigManager:Config("RoyalHub_Config")

-------------------------------* Tags *-------------------------------
WindUI:Notify({ Title = "KeyBind", Content = "Aperte a tecla ( H ) para esconder | Mostrar o menu", Duration = 4, Icon = "user" })

print("========================= Royal Hub carregado com sucesso! =========================")

Window:Tag({ Title = "v1.4.4",  Icon = "github",                  Color = Color3.fromHex("#f0d01a"), Radius = 8 })
Window:Tag({ Title = "Secure",  Icon = "solar:shield-check-bold",  Color = Color3.fromHex("#30ff6a"), Radius = 8 })

local FPSTag  = Window:Tag({ Title = "FPS: 0",    Color = Color3.fromRGB(100,150,255) })
local PingTag = Window:Tag({ Title = "Ping: 0ms", Color = Color3.fromRGB(100,200,255) })

local RunService = game:GetService("RunService")
local lastUpdate, frameCount = tick(), 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSTag:SetTitle("FPS: "..fps)
        FPSTag:SetColor(fps >= 50 and Color3.fromRGB(0,255,0) or fps >= 30 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,0,0))
        frameCount = 0; lastUpdate = now
    end
end)

task.spawn(function()
    while true do
        local ok, ping = pcall(function()
            return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and ping then
            PingTag:SetTitle("Ping: "..ping.."ms")
            PingTag:SetColor(ping <= 50 and Color3.fromRGB(0,255,0) or ping <= 100 and Color3.fromRGB(255,200,0) or ping <= 200 and Color3.fromRGB(255,150,0) or Color3.fromRGB(255,0,0))
        end
        task.wait(2)
    end
end)

Window:SetToggleKey(Enum.KeyCode.H)

-------------------------------* TABS (ordem da GUI) *-------------------------------
-- 1. Inicio | 2. Personagem | 3. Farm | 4. Loja | 5. TP and WBHK | 6. Misc | 7. Exploits | 8. Configurações | 9. Info

local TabHome = Window:Tab({
    Title = "Inicio", Icon = "solar:home-2-bold",
    Desc = "Funções principais do Royal Hub.",
    IconColor = DarkGray, IconShape = "Square", Border = true, Locked = false,
})

local TabPersonagem = Window:Tab({
    Title = "Personagem", Icon = "solar:user-bold",
    Desc = "Modificações no personagem.",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabFarm = Window:Tab({
    Title = "Farm", Icon = "solar:black-hole-bold",
    Desc = "Funções de farm automático.",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabShopping = Window:Tab({
    Title = "Loja", Icon = "solar:cart-large-bold",
    Desc = "Compre itens automaticamente.",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabTeleport = Window:Tab({
    Title = "TP and WBHK", Icon = "solar:cloud-bold",
    Desc = "Teleporte e WebHook.",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabMisc = Window:Tab({
    Title = "Misc", Icon = "box",
    Desc = "Funções diversas.",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabExploits = Window:Tab({
    Title = "Exploits", Icon = "solar:bolt-bold",
    Desc = "Scripts que podem ser uteis",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabSettings = Window:Tab({
    Title = "Configurações", Icon = "solar:settings-minimalistic-bold",
    Desc = "Configurações do Royal Hub.",
    IconColor = DarkGray, IconShape = "Square", Locked = false,
})

local TabInfo = Window:Tab({
    Title = "Info", Icon = "solar:info-circle-bold",
    Desc = "Informações sobre o Royal Hub e Desenvolvedores.",
    IconColor = DarkGray, IconShape = "Square", Border = true, Locked = false,
})

TabHome:Select()

--============================================================================
--  TAB: INICIO
--============================================================================

-------------------------------* Seção: Aimbot *-------------------------------
task.wait(0.1)
local SectionAimbot = TabHome:Section({
    Title = "Aimbot", Desc = "Função de aimbot para facilitar seus tiros & Ataques.",
    Icon = "geist:crosshair", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

local GrupoAimbot = SectionAimbot:Group({})
GrupoAimbot:Toggle({ Title = "Aimbot comum", Default = false, Callback = function(enabled) G.AimbotEnabled.normal = enabled; G.toggleAimbot("normal") end })
GrupoAimbot:Space()
GrupoAimbot:Toggle({ Title = "Aimbot rage",  Default = false, Callback = function(enabled) G.AimbotEnabled.rage  = enabled; G.toggleAimbot("rage")   end })

SectionAimbot:Space()

SectionAimbot:Toggle({ Title = "Ignorar Aliados (Team Check)", Default = true, Callback = function(enabled)
    G.UseTeamCheck = enabled
    WindUI:Notify({ Title = "Team Check", Content = enabled and "Ligado" or "Desligado", Duration = 2 })
end })

SectionAimbot:Toggle({ Title = "Wall Check (Ignorar Paredes)", Default = true, Callback = function(enabled)
    G.UseWallCheck = enabled
    WindUI:Notify({ Title = "Wall Check", Content = enabled and "Ligado (só mira visível)" or "Desligado (mira através)", Duration = 2 })
end })

SectionAimbot:Slider({
    Title = "Smooth do Aimbot", Desc = "0.05 = muito suave (lento), 0.5 = direto ao alvo.",
    Step = 0.01, Value = { Min = 0.05, Max = 0.5, Default = 0.15 },
    Callback = function(value) G.AimbotSmoothFactor = value end
})

SectionAimbot:Space({ Columns = 1 })

local ToggleESP = SectionAimbot:Toggle({
    Title = "ESP", Desc = "Players ficam visíveis atrás de paredes e marcados.",
    Icon = "solar:eye-bold", Value = false,
    Callback = function(state) G.toggleESP(state) end
})

SectionAimbot:Space({ Columns = 1 })

SectionAimbot:Toggle({
    Title = "Esp 2.0 (Twilight)", Desc = "ESP com health bar, box e nome — powered by Twilight.",
    Icon = "solar:eye-bold", Locked = true, Value = false,
    Callback = function(state)
        if state and G.EspEnabled then G.toggleESP(false); ToggleESP:Set(false) end
        WindUI:Notify({ Title = "ESP 2.0", Content = state and "Twilight ESP ativado!" or "Desativado.", Duration = 2, Icon = state and "eye" or "x" })
    end
})

SectionAimbot:Space({ Columns = 1 })

SectionAimbot:Toggle({
    Title = "ESP — Linhas", Desc = "Desenha linhas do centro da tela até cada inimigo (usa Drawing API).",
    Icon = "solar:arrow-right-bold", Value = false,
    Callback = function(state) G.toggleEspLines(state) end
})

SectionAimbot:Toggle({
    Title = "ESP — Hitbox Visual", Desc = "Mostra caixas vermelhas ao redor da hitbox expandida (requer Hitbox Expander ativo).",
    Icon = "solar:maximize-square-bold", Value = false,
    Callback = function(state) G.toggleHitboxESP(state) end
})

SectionAimbot:Space({ Columns = 1 })

SectionAimbot:Toggle({
    Title = "Fake TP (Dodge)", Default = false,
    Callback = function(enabled) G.toggleFakeTP(enabled) end
})

SectionAimbot:Slider({
    Title = "Delay Fake TP", Desc = "Tempo entre fakes (menor = mais rápido)",
    Step = 0.1, Value = { Min = 0.1, Max = 1, Default = 0.2 },
    Callback = function(value) G.FakeTPDelay = value end
})

SectionAimbot:Slider({
    Title = "Distância Fake TP", Desc = "Quão longe o fake TP vai (em studs)",
    Step = 1, Value = { Min = 1, Max = 10, Default = 3 },
    Callback = function(value) G.FakeTPDist = value end
})

TabHome:Space({ Columns = 2 })

-------------------------------* Seção: Combat *-------------------------------
task.wait(0.1)
local SectionCombat = TabHome:Section({
    Title = "Combat", Desc = "Silent Aim, Hit Prediction, Hitbox Expander e Auto Parry.",
    Icon = "geist:crosshair", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionCombat:Toggle({
    Title = "Silent Aim", Desc = "Acerta o alvo sem mover a câmera.",
    Icon = "solar:eye-bold", Value = false,
    Callback = function(state) G.toggleSilentAim(state) end
})

SectionCombat:Dropdown({
    Title = "Parte do Silent Aim", Desc = "Qual parte do corpo mira.",
    Values = {{ Title = "HumanoidRootPart" },{ Title = "Head" },{ Title = "UpperTorso" }},
    Value = "HumanoidRootPart",
    Callback = function(option) G.SilentAimPart = option.Title end
})

SectionCombat:Space({ Columns = 1 })

SectionCombat:Toggle({
    Title = "Hit Prediction", Desc = "Compensa o lag prevendo a posição do alvo.",
    Icon = "solar:clock-circle-bold", Value = false,
    Callback = function(state) G.toggleHitPred(state) end
})

SectionCombat:Slider({
    Title = "Fator de Predição", Desc = "Quanto maior, mais à frente mira (1.0 = 100% do ping).",
    Step = 0.1, Value = { Min = 0.1, Max = 3.0, Default = 1.0 },
    Callback = function(value) G.PredictionAmount = value end
})

SectionCombat:Space({ Columns = 1 })

SectionCombat:Toggle({
    Title = "Hitbox Expander", Desc = "Expande a hitbox dos jogadores para facilitar acertos.",
    Icon = "geist:box", Value = false,
    Callback = function(state) G.toggleHitbox(state) end
})

SectionCombat:Slider({
    Title = "Tamanho da Hitbox", Desc = "Em studs. Padrão = 4.",
    Step = 1, Value = { Min = 4, Max = 30, Default = 8 },
    Callback = function(value)
        G.HitboxSize = value
        if G.HitboxEnabled then G.removeHitboxes(); G.applyHitboxes() end
    end
})

SectionCombat:Space({ Columns = 1 })

SectionCombat:Toggle({
    Title = "Auto Parry", Desc = "Aperta a tecla de parry automaticamente quando inimigo está próximo.",
    Icon = "solar:shield-bold", Value = false,
    Callback = function(state) G.toggleAutoParry(state) end
})

SectionCombat:Dropdown({
    Title = "Tecla de Parry", Desc = "Tecla que o jogo usa para parry.",
    Values = {{ Title = "Q" },{ Title = "F" },{ Title = "E" },{ Title = "R" },{ Title = "LeftControl" }},
    Value = "Q",
    Callback = function(option)
    local ok, key = pcall(function() return Enum.KeyCode[option.Title] end)
    if ok and key then
        G.AutoParryKey = key
        if G.AutoParryEnabled then G.toggleAutoParry(true) end
    end
end
})

SectionCombat:Slider({
    Title = "Distância do Auto Parry", Desc = "Distância máxima (studs) para ativar o parry.",
    Step = 1, Value = { Min = 5, Max = 30, Default = 12 },
    Callback = function(value) G.AutoParryDist = value end
})

-------------------------------* Seção: Visual *-------------------------------
task.wait(0.1)
local SectionView = TabHome:Section({
    Title = "Visual", Desc = "Modificações visuais no jogo.",
    Icon = "solar:eye-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionView:Dropdown({
    Title = "Selecione o Player", Desc = "Seleciona o player para spectate.",
    Values = G.playerValues, Value = G.playerValues[1],
    Callback = function(option)
        SelectedPlayerToView = S.Players:FindFirstChild(option.Title)
    end
})

SectionView:Toggle({
    Title = "Spectate Player", Desc = "Ativa câmera na perspectiva do player selecionado.",
    Icon = "solar:eye-bold", Value = false,
    Callback = function(state)
        if state then
            if SelectedPlayerToView then G.startSpectate(SelectedPlayerToView) end
        else
            G.stopSpectate()
        end
    end
})

SectionView:Space({ Columns = 1 })

SectionView:Toggle({
    Title = "NoClip", Desc = "Permite atravessar paredes e objetos.",
    Icon = "solar:ghost-bold", Value = false,
    Callback = function(state) G.toggleNoClip(state) end
})

--============================================================================
--  TAB: PERSONAGEM
--============================================================================

-------------------------------* Seção: Movimento *-------------------------------
task.wait(0.1)
local SectionMovimento = TabPersonagem:Section({
    Title = "Movimento", Box = true, BoxBorder = true, Opened = true,
    TextSize = 20, FontWeight = Enum.FontWeight.SemiBold,
})

SectionMovimento:Slider({
    Title = "Speed", Desc = "Altera velocidade do jogador",
    IsTooltip = true, IsTextbox = false, Width = 200, Step = 1,
    Value = { Min = 20, Max = 999, Default = 20 },
    Callback = function(value) G.setSpeed(value) end
})

SectionMovimento:Slider({
    Title = "Jump", Desc = "Aumenta a força do pulo",
    IsTooltip = true, IsTextbox = false, Width = 200, Step = 1,
    Value = { Min = 20, Max = 999, Default = 20 },
    Callback = function(value) G.setJumpPower(value) end
})

SectionMovimento:Toggle({
    Title = "Fly", Desc = "Ativa o modo voo",
    Icon = "solar:rocket-bold", Value = false,
    Callback = function(state) G.toggleFly(state) end
})

SectionMovimento:Slider({
    Title = "Velocidade do Fly", Desc = "Ajuste a velocidade do voo.",
    IsTooltip = true, IsTextbox = false, Width = 200, Step = 5,
    Value = { Min = 150, Max = 5000, Default = 100 },
    Callback = function(value)
        G.FlySpeed = value
        if G.FlyEnabled and G.FlyBV and G.FlyBV.Velocity.Magnitude > 0 then
            G.FlyBV.Velocity = G.FlyBV.Velocity.Unit * value
        end
    end
})

TabPersonagem:Space({ Columns = 1 })

-------------------------------* Seção: Gravidade *-------------------------------
task.wait(0.1)
local SectionGravity = TabPersonagem:Section({
    Title = "Gravidade", Box = true, BoxBorder = true, Opened = true,
    TextSize = 20, FontWeight = Enum.FontWeight.SemiBold,
})

SectionGravity:Slider({
    Title = "Gravity", Desc = "Altera a gravidade do jogo",
    IsTooltip = true, IsTextbox = false, Width = 200, Step = 1,
    Value = { Min = 0, Max = 500, Default = 196.2 },
    Callback = function(value) G.setGravity(value) end
})

local ResetGravityBtn = SectionGravity:Button({
    Icon = "solar:refresh-bold", Title = "Reset Gravity",
    Desc = "Reseta a gravidade para o valor padrão (196.2)", Locked = false,
    Callback = function()
        G.setGravity(196.2)
        ResetGravityBtn:Highlight()
        WindUI:Notify({ Title = "Gravidade resetada!", Content = "A gravidade foi resetada para o valor padrão (196.2)", Duration = 3, Icon = "shield-check" })
    end
})

SectionGravity:Space({ Columns = 1 })

TabPersonagem:Space({ Columns = 1 })

-------------------------------* Seção: Proteção *-------------------------------
task.wait(0.1)
local SectionProtecao = TabPersonagem:Section({
    Title = "Proteção", TextSize = 20, FontWeight = Enum.FontWeight.SemiBold,
    Box = true, BoxBorder = true, Opened = true,
})

SectionProtecao:Toggle({
    Title = "Anti-Ragdoll", Desc = "Impede o personagem de cair/ragdoll.",
    Icon = "solar:shield-bold", Value = false,
    Callback = function(state) G.toggleAntiRagdoll(state) end
})

SectionProtecao:Toggle({
    Title = "God Mode", Desc = "HP Infinito.",
    Icon = "solar:shield-star-bold", Value = false,
    Callback = function(state) G.toggleGod(state) end
})

SectionProtecao:Toggle({
    Title = "Infinite Jump", Desc = "Permite pular infinitamente no ar.",
    Icon = "solar:arrow-up-bold", Value = false,
    Callback = function(state) G.toggleInfJump(state) end
})

SectionProtecao:Toggle({
    Title = "Anti-AFK", Desc = "Impede ser kickado por inatividade.",
    Icon = "solar:clock-circle-bold", Value = false,
    Callback = function(state) G.toggleAntiAFK(state) end
})

SectionProtecao:Space({ Columns = 1 })

TabPersonagem:Space({ Columns = 1 })

-------------------------------* Seção: Extras Personagem *-------------------------------
task.wait(0.1)
local SectionExtrasChar = TabPersonagem:Section({
    Title = "Extras", TextSize = 20, FontWeight = Enum.FontWeight.SemiBold,
    Box = true, BoxBorder = true, Opened = true,
})

SectionExtrasChar:Toggle({
    Title = "Invisível", Desc = "Torna o personagem invisível localmente.",
    Icon = "solar:eye-closed-bold", Value = false,
    Callback = function(state) G.toggleInvisible(state) end
})

SectionExtrasChar:Toggle({
    Title = "Freeze", Desc = "Congela o personagem no lugar.",
    Icon = "solar:snowflake-bold", Value = false,
    Callback = function(state) G.toggleFreeze(state) end
})

SectionExtrasChar:Toggle({
    Title = "Freecam", Desc = "Câmera livre para explorar o mapa. WASD + Q/E + arrastar botão direito.",
    Icon = "solar:camera-bold", Value = false,
    Callback = function(state) G.toggleFreecam(state) end
})

SectionExtrasChar:Toggle({
    Title = "Fullbright", Desc = "Remove sombras e escuridão do mapa.",
    Icon = "solar:sun-bold", Value = false,
    Callback = function(state) G.toggleFullbright(state) end
})

SectionExtrasChar:Toggle({
    Title = "No Fog", Desc = "Remove névoa do jogo.",
    Icon = "solar:cloud-bold", Value = false,
    Callback = function(state) G.toggleNoFog(state) end
})

SectionExtrasChar:Toggle({
    Title = "Xray", Desc = "Torna os personagens inimigos em ForceField para fácil visualização.",
    Icon = "solar:eye-bold", Value = false,
    Callback = function(state) G.toggleXray(state) end
})

SectionExtrasChar:Toggle({
    Title = "Hover Name", Desc = "Mostra nome e DisplayName dos jogadores acima da cabeça.",
    Icon = "solar:user-id-bold", Value = false,
    Callback = function(state) G.toggleHoverName(state) end
})

SectionExtrasChar:Toggle({
    Title = "Radar", Desc = "Radar 2D mostrando posição dos inimigos.",
    Icon = "solar:map-point-bold", Value = false,
    Callback = function(state) G.toggleRadar(state) end
})

SectionExtrasChar:Slider({
    Title = "Radar Range",
    Desc = "Alcance do radar (em studs).",
    Step = 10, Value = { Min = 50, Max = 500, Default = 150 },
    Callback = function(value)
        G.RadarRange = value
    end
})

SectionExtrasChar:Toggle({
    Title = "Click TP", Desc = "Clique no chão para se teleportar até o ponto.",
    Icon = "solar:cursor-bold", Value = false,
    Callback = function(state)
        G.toggleClickTP(state)
    end
})

SectionExtrasChar:Toggle({
    Title = "Kill Aura", Desc = "Mata automaticamente inimigos próximos.",
    Icon = "solar:danger-bold", Value = false,
    Callback = function(state)
        G.toggleKillAura(state)
    end
})

SectionExtrasChar:Slider({
    Title = "Kill Aura Range", Step = 1, Value = { Min = 5, Max = 50, Default = 15 },
    Callback = function(value)
        G.KillAuraRange = value
    end
})

SectionExtrasChar:Toggle({
    Title = "Reach", Desc = "Aumenta o alcance das ferramentas/armas.",
    Icon = "solar:cursor-bold", Value = false,
    Callback = function(state)
        G.toggleReach(state)
    end
})

SectionExtrasChar:Slider({
    Title = "Reach Size", Step = 1, Value = { Min = 1, Max = 50, Default = 10 },
    Callback = function(value)
        G.ReachSize = value
        if G.ReachEnabled then G.toggleReach(true, value) end
    end
})

SectionExtrasChar:Toggle({
    Title = "Fling Spin", Desc = "Gira o personagem em alta velocidade.",
    Icon = "solar:refresh-bold", Value = false,
    Callback = function(state)
        G.toggleFlingSpin(state)
    end
})

SectionExtrasChar:Slider({
    Title = "Fling Spin Speed", Desc = "Velocidade de rotação do fling spin.",
    Step = 1,
    Value = { Min = 5000, Max = 99999, Default = 5000 },
    Callback = function(value)
        G.FlingSpinSpeed = value
    end
})

--============================================================================
--  TAB: FARM
--============================================================================
task.wait(0.1)
local SectionAutofarmLevel = TabFarm:Section({
    Title = "Auto Farm Level", Desc = "Farma automaticamente seu level (se não estiver no máximo)",
    Icon = "geist:sparkles", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionAutofarmLevel:Toggle({
    Title = "Ativar Auto Farm Level", Desc = "Ativa o farm automático de level.",
    Locked = true, LockedTitle = "Em desenvolvimento.", Value = false,
    Callback = function(state)
        WindUI:Notify({ Title = "Auto Farm Level", Content = state and "Ativado!" or "Desativado!", Duration = 3, Icon = state and "solar:check-circle-bold" or "x" })
    end
})

TabFarm:Space({ Columns = 2 })

task.wait(0.1)
local SectionAutoF = TabFarm:Section({
    Title = "Auto Farm Materials", Desc = "Farma automaticamente materiais do jogo.",
    Icon = "solar:backpack-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionAutoF:Toggle({
    Title = "Ativar Auto Farm Materials", Desc = "Ativa o farm automático de materiais.",
    Locked = true, LockedTitle = "Em desenvolvimento.", Value = false,
    Callback = function(state)
        WindUI:Notify({ Title = "Auto Farm Materials", Content = state and "Ativado!" or "Desativado!", Duration = 3, Icon = state and "solar:check-circle-bold" or "x" })
    end
})

SectionAutoF:Space({ Columns = 1 })

SectionAutoF:Dropdown({
    Title = "Selecionar Material", Desc = "Seleciona o material que deseja farmar automaticamente.",
    Locked = true, LockedTitle = "Em desenvolvimento.",
    Values = {{ Title = "Material 1" },{ Title = "Material 2" },{ Title = "Material 3" }},
    Value = "Material 1",
    Callback = function(option) end
})

--============================================================================
--  TAB: LOJA
--============================================================================
task.wait(0.1)
local SectionLoja = TabShopping:Section({
    Title = "Auto Buy", Desc = "Compra itens automaticamente do blackmarket.",
    Icon = "solar:cart-large-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionLoja:Dropdown({
    Title = "Selecionar Item", Desc = "Seleciona o item que deseja comprar automaticamente.",
    Locked = true, LockedTitle = "Em desenvolvimento.",
    Values = {{ Title = "Item 1" },{ Title = "Item 2" },{ Title = "Item 3" }},
    Value = "Item 1",
    Callback = function(option) end
})

SectionLoja:Toggle({
    Title = "Ativar Auto Buy", Desc = "Ativa a compra automática do item selecionado acima.",
    Icon = "solar:cart-large-bold", Locked = true, LockedTitle = "Em desenvolvimento.", Value = false,
    Callback = function(state)
        WindUI:Notify({ Title = "Auto Buy", Content = state and "Ativado!" or "Desativado!", Duration = 3, Icon = state and "solar:check-circle-bold" or "x" })
    end
})

--============================================================================
--  TAB: TP AND WBHK
--============================================================================
task.wait(0.1)
local SectionTP = TabTeleport:Section({
    Title = "Teleport", Desc = "Permite teleportar até outros jogadores.",
    Icon = "bird", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

local tpDropdownReady = false
SectionTP:Dropdown({
    Title = "Teleportar até jogador", Desc = "Teleporta até o jogador selecionado",
    Values = G.playerValues, Value = G.playerValues[1],
    Callback = function(option)
        G.LoopTPTarget = option.Title
        if tpDropdownReady then
            G.tpToPlayerName(option.Title)
        end
    end
})
tpDropdownReady = true

SectionTP:Space({ Columns = 1 })

SectionTP:Toggle({
    Title = "Loop TP", Desc = "Teleporta infinitamente no jogador que foi selecionado acima.",
    Locked = false, Value = false,
    Callback = function(state) G.toggleLoopTP(state) end
})

SectionTP:Space({ Columns = 1 })

SectionTP:Slider({
    Title = "Delay entre TPs", Desc = "Tempo em segundos entre cada teleporte (menor = mais rápido)",
    IsTooltip = true, IsTextbox = false, Width = 200, Step = 0.1,
    Value = { Min = 0.3, Max = 5, Default = 1 },
    Callback = function(value)
        G.LoopTPDelay = value
        WindUI:Notify({ Title = "Loop TP Delay", Content = "Atualizado para "..value.." segundos", Duration = 2, Icon = "timer" })
    end
})

TabTeleport:Space({ Columns = 2 })

task.wait(0.1)
local SectionTeleportToIsland = TabTeleport:Section({
    Title = "Teleport to Islands", Desc = "Detecta o jogo e Sea automaticamente.",
    Icon = "solar:map-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

-- detecta jogo atual (Islands.lua carregado antes da UI)
local IslandDB = (_G.RH and _G.RH.IslandDB) or {}
local currentGameData = IslandDB[game.PlaceId]
local currentSea      = 1
local islandDropdown  = nil

local function getIslandValues(gameData, sea)
    local vals = {}
    local seaData = gameData.seas[sea] or gameData.seas[1]
    for _, isl in ipairs(seaData) do
        table.insert(vals, { Title = isl.Title })
    end
    return vals
end

local function refreshIslandDropdown()
    if not currentGameData then return end
    currentSea = currentGameData.detectSea()
    if islandDropdown then
        islandDropdown:Refresh(getIslandValues(currentGameData, currentSea))
    end
    WindUI:Notify({
        Title = "Ilha TP",
        Content = currentGameData.name .. " — Sea " .. currentSea .. " detectado!",
        Duration = 3, Icon = "solar:map-bold"
    })
end

if currentGameData then
    currentSea = currentGameData.detectSea()

    SectionTeleportToIsland:Paragraph({
        Title = "Jogo detectado",
        Desc = currentGameData.name .. "  —  Sea " .. currentSea,
    })

    islandDropdown = SectionTeleportToIsland:Dropdown({
        Title = "Selecionar Ilha",
        Desc = "Ilhas do sea atual.",
        Values = getIslandValues(currentGameData, currentSea),
        Callback = function(option) G.SelectedIsland = option.Title end
    })

    SectionTeleportToIsland:Button({
        Title = "Teleportar para Ilha",
        Icon = "solar:map-arrow-right-bold",
        Callback = function()
            if not G.SelectedIsland then
                WindUI:Notify({ Title = "Ilha TP", Content = "Selecione uma ilha primeiro!", Duration = 3, Icon = "alert-circle" })
                return
            end
            local seaData = currentGameData.seas[currentSea] or currentGameData.seas[1]
            for _, isl in ipairs(seaData) do
                if isl.Title == G.SelectedIsland then
                    local root = S.Players.LocalPlayer.Character
                    root = root and root:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = CFrame.new(isl.pos) * CFrame.new(0, 3, 0)
                        WindUI:Notify({ Title = "Ilha TP", Content = "Teleportado para " .. isl.Title, Duration = 3, Icon = "solar:map-bold" })
                    end
                    return
                end
            end
        end
    })

    SectionTeleportToIsland:Button({
        Title = "Redetectar Sea",
        Icon = "solar:refresh-bold",
        Desc = "Use após trocar de sea.",
        Callback = function() refreshIslandDropdown() end
    })
else
    SectionTeleportToIsland:Paragraph({
        Title = "Jogo não suportado",
        Desc = "PlaceId atual: " .. game.PlaceId,
    })
end

TabTeleport:Space({ Columns = 2 })

-------------------------------* Seção: WebHook *-------------------------------
task.wait(0.1)
local SectionWebhook = TabTeleport:Section({
    Title = "Discord WebHook", Desc = "Envia notificações para o seu Discord.",
    Icon = "solar:letter-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionWebhook:Input({
    Title = "URL do WebHook",
    Desc = "Cole a URL do seu webhook do Discord.",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        if value and value:find("discord.com/api/webhooks") then
            G.WebhookURL = value
            WindUI:Notify({ Title = "WebHook", Content = "URL salva!", Duration = 2, Icon = "solar:check-circle-bold" })
        end
    end
})

SectionWebhook:Button({
    Title = "Testar WebHook",
    Icon = "solar:letter-bold",
    Desc = "Envia uma mensagem de teste.",
    Callback = function()
        G.sendWebhook("🟢 **RoyalHub** — Teste!\nJogador: **" .. LP.Name .. "**")
    end
})

SectionWebhook:Space({ Columns = 1 })

SectionWebhook:Toggle({
    Title = "Notif de Inventário",
    Desc = "Envia webhook quando pegar um item novo.",
    Icon = "solar:bag-bold", Value = false,
    Callback = function(state) G.toggleInventoryWebhook(state) end
})

-------------------------------* Seção: Miscellaneous *-------------------------------
task.wait(0.1)
local SectionMisc = TabMisc:Section({
    Title = "Miscellaneous", Desc = "Funções diversas do Royal Hub.",
    Icon = "solar:settings-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionMisc:Button({ Title = "Rejoin",       Desc = "Reentra na partida atual.",                 Callback = function() G.rejoinServer() end })
SectionMisc:Space({ Columns = 1 })
SectionMisc:Button({ Title = "Server Hop",   Desc = "Entra em outro servidor da partida atual.", Callback = function() G.serverHop()   end })
SectionMisc:Space({ Columns = 1 })
SectionMisc:Button({ Title = "Redeem Codes", Desc = "Resgata códigos automaticamente.", Locked = true, LockedTitle = "Em desenvolvimento.", Callback = function() end })
SectionMisc:Space({ Columns = 1 })
SectionMisc:Button({ Title = "Collect Rewards", Desc = "Coleta recompensas diárias automaticamente.", Locked = true, LockedTitle = "Em desenvolvimento.", Callback = function() end })

TabMisc:Space({ Columns = 1 })

-------------------------------* Seção: Fun *-------------------------------
task.wait(0.1)
local SectionFun = TabMisc:Section({
    Title = "Fun", Desc = "Funções divertidas do Royal Hub.",
    Icon = "solar:emoji-funny-circle-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionFun:Toggle({
    Title = "Spin", Desc = "Faz o personagem girar infinitamente.",
    Value = false, Callback = function(state) G.toggleSpin(state) end
})

SectionFun:Space({ Columns = 1 })

SectionFun:Dropdown({
    Title = "Orbit — Selecione Jogador", Values = G.playerValues, Multi = false,
    Callback = function(selected) G.OrbitTarget = selected.Title end
})

SectionFun:Toggle({
    Title = "Ativar Orbit", Default = false,
    Callback = function(state) G.toggleOrbit(state) end
})

SectionFun:Slider({
    Title = "Velocidade Rotação", IsTooltip = true, IsTextbox = false, Width = 200, Step = 1,
    Value = { Min = 0.1, Max = 10, Default = 1 },
    Callback = function(value)
        G.OrbitSpeed = value
        if G.OrbitEnabled then WindUI:Notify({ Title = "Orbit", Content = "Velocidade atualizada para "..value, Duration = 2, Icon = "wind" }) end
    end
})

SectionFun:Space({ Columns = 1 })

task.wait(0.1)
local EmoteDropdown = SectionFun:Dropdown({
    Title = "Selecione Emote", Desc = "Emotes disponíveis (mesmo sem ter na conta).",
    Values = G.emoteValues, Multi = false, Default = nil,
    Callback = function(selected) SelectedEmote = selected.Title end
})

local emoteLoopToggle = SectionFun:Toggle({
    Title = "Loop Emote", Desc = "Faz o emote repetir automaticamente.",
    Icon = "solar:repeat-bold", Value = false,
    Callback = function(state)
        G.LoopEmote = state
        if G.CurrentEmoteTrack and G.CurrentEmoteTrack.IsPlaying then
            if state then
                if not G.EmoteLoopConn then G.activateManualLoop(G.CurrentEmoteTrack) end
            else
                if G.EmoteLoopConn then G.EmoteLoopConn:Disconnect(); G.EmoteLoopConn = nil end
                G.CurrentEmoteTrack:Stop(); G.CurrentEmoteTrack = nil
            end
        end
        WindUI:Notify({ Title = "Emote", Content = "Loop "..(state and "ativado!" or "desativado!"), Duration = 2, Icon = "repeat" })
    end
})

SectionFun:Space({ Columns = 1 })

SectionFun:Button({
    Title = "Usar Emote", Desc = "Executa o emote selecionado.",
    Icon = "solar:emoji-funny-square-bold",
    Callback = function()
        if not SelectedEmote then
            WindUI:Notify({ Title = "Emote", Content = "Selecione um emote primeiro!", Duration = 4, Icon = "alert-circle" })
            return
        end
        local emoteID = G.emoteList[SelectedEmote]
        if not emoteID then return end
        local localChar = LP.Character; if not localChar then return end
        local humanoid  = localChar:FindFirstChildOfClass("Humanoid"); if not humanoid then return end
        local animator  = humanoid:FindFirstChildOfClass("Animator"); if not animator then return end
        if G.CurrentEmoteTrack then G.CurrentEmoteTrack:Stop(); G.CurrentEmoteTrack = nil end
        if G.EmoteLoopConn then G.EmoteLoopConn:Disconnect(); G.EmoteLoopConn = nil end
        local success, track = pcall(function()
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://"..emoteID
            local loadedTrack = animator:LoadAnimation(anim)
            loadedTrack.Priority = Enum.AnimationPriority.Action
            loadedTrack.Looped   = false
            loadedTrack:Play()
            return loadedTrack
        end)
        if not success or not track then
            WindUI:Notify({ Title = "Emote", Content = "Falha ao carregar "..SelectedEmote.."! ID inválido.", Duration = 5, Icon = "alert-circle" })
            return
        end
        G.CurrentEmoteTrack = track
        if G.LoopEmote then
            G.activateManualLoop(track)
        else
            track.Stopped:Connect(function() if track == G.CurrentEmoteTrack then G.CurrentEmoteTrack = nil end end)
        end
        WindUI:Notify({ Title = "Emote", Content = "Tocando "..SelectedEmote..(G.LoopEmote and " em LOOP INFINITO!" or "!"), Duration = 3, Icon = "smile" })
    end
})

SectionFun:Button({
    Title = "Parar Emote", Desc = "Interrompe o emote atual.",
    Icon = "solar:stop-bold",
    Callback = function()
        if G.CurrentEmoteTrack then G.CurrentEmoteTrack:Stop(); G.CurrentEmoteTrack = nil end
        if G.EmoteLoopConn then G.EmoteLoopConn:Disconnect(); G.EmoteLoopConn = nil end
        G.LoopEmote = false; emoteLoopToggle:Set(false)
        WindUI:Notify({ Title = "Emote", Content = "Emote e loop parados!", Duration = 3, Icon = "x" })
    end
})

SectionFun:Space({ Columns = 1 })

SectionFun:Dropdown({
    Title = "IDs Troll Prontos", Locked = true, LockedTitle = "Em manutenção",
    Values = trollAudios, Multi = false, Default = nil,
    Callback = function(selected)
        if selected and selected.id then
            currentAudioId = selected.id
            WindUI:Notify({ Title = "Troll Selecionado", Content = "Carregado: "..selected.Title.." (ID: "..selected.id..")", Duration = 3, Icon = "zap" })
        end
    end
})

SectionFun:Slider({
    Title = "Volume", Locked = true, LockedTitle = "Em manutenção.",
    Value = { Min = 1, Max = 20, Default = 5 },
    Callback = function(value) currentVolume = value end
})

SectionFun:Button({
    Title = "Tocar Global", locked = true, LockedTitle = "Em manutenção.",
    Callback = function()
        WindUI:Notify({ Title = "Audio", Content = "Em desenvolvimento.", Duration = 2, Icon = "music" })
    end
})

TabMisc:Space({ Columns = 1 })

-------------------------------* Seção: Utilidades *-------------------------------
task.wait(0.1)
local SectionUtility = TabMisc:Section({
    Title = "Utilidades", Desc = "Copy Player, Anti-Kick e Remote Spy.",
    Icon = "solar:settings-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionUtility:Dropdown({
    Title = "Copy Player — Selecionar", Desc = "Selecione o jogador para copiar o visual.",
    Values = G.playerValues, Value = G.playerValues[1],
    Callback = function(option) CopyTargetPlayer = S.Players:FindFirstChild(option.Title) end
})

SectionUtility:Button({
    Title = "Copiar Visual", Desc = "Copia o outfit do jogador selecionado.",
    Icon = "solar:user-bold",
    Callback = function() G.copyPlayerLook(CopyTargetPlayer) end
})

SectionUtility:Space({ Columns = 1 })

SectionUtility:Toggle({
    Title = "Anti-Kick", Desc = "Bloqueia tentativas de kick do servidor.",
    Icon = "solar:shield-check-bold", Value = false,
    Callback = function(state)
        G.AntiKickEnabled = state
        WindUI:Notify({ Title = "Anti-Kick", Content = state and "Ativado!" or "Desativado.", Duration = 2, Icon = state and "shield" or "x" })
    end
})

SectionUtility:Space({ Columns = 1 })

SectionUtility:Toggle({
    Title = "Remote Spy", Desc = "Loga todos os RemoteEvents disparados no console.",
    Icon = "solar:eye-bold", Value = false,
    Callback = function(state)
        G.RemoteSpyEnabled = state
        if state then G.RemoteLogs = {} end
        WindUI:Notify({ Title = "Remote Spy", Content = state and "Logando remotes no console..." or "Parado.", Duration = 2, Icon = state and "eye" or "x" })
    end
})

SectionUtility:Button({
    Title = "Copiar Logs", Desc = "Copia todos os remotes capturados para a área de transferência.",
    Icon = "solar:copy-bold",
    Callback = function()
        if #G.RemoteLogs == 0 then
            WindUI:Notify({ Title = "Remote Spy", Content = "Nenhum log capturado ainda.", Duration = 3, Icon = "alert-circle" })
            return
        end
        local lines = {}
        for _, entry in ipairs(G.RemoteLogs) do
            table.insert(lines, string.format("[%.2fs] %s", entry.t, entry.text))
        end
        pcall(function() setclipboard(table.concat(lines, "\n")) end)
        WindUI:Notify({ Title = "Remote Spy", Content = #G.RemoteLogs.." logs copiados!", Duration = 3, Icon = "check" })
    end
})

SectionUtility:Button({
    Title = "Limpar Logs", Icon = "solar:trash-bin-trash-bold",
    Callback = function()
        G.RemoteLogs = {}
        WindUI:Notify({ Title = "Remote Spy", Content = "Logs limpos.", Duration = 2, Icon = "trash" })
    end
})

--============================================================================
--  TAB: EXPLOITS
--============================================================================

-------------------------------* Seção: Fling *-------------------------------
task.wait(0.1)
local SectionFling = TabExploits:Section({
    Title = "Fling", Desc = "Arremessa jogadores pelo mapa.",
    Icon = "solar:flash-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionFling:Dropdown({
    Title = "Selecione Jogador (Fling)",
    Values = G.playerValues,
    Multi = false,
    locked = true, lockedTitle = "Em Manutenção",
    Callback = function(selected)
    if type(selected) == "table" then
        FlingTargetPlayer = selected.Player or S.Players:FindFirstChild(selected.Title)
    else
        FlingTargetPlayer = S.Players:FindFirstChild(tostring(selected))
    end
end
})

SectionFling:Slider({
    Title = "Fling Power", Locked = true, LockedTitle = "Em manutenção.",
    IsTooltip = true, IsTextbox = false, Width = 200, Step = 1,
    Value = { Min = 1000, Max = 50000, Default = 9000 },
    Callback = function(value) FlingPower = value end
})

SectionFling:Toggle({
    Title = "Loop Fling", Locked = true, LockedTitle = "Em Manutenção", Default = false,
    Callback = function(enabled)
        LoopFlingEnabled = enabled  -- <-- essa linha tava faltando
        if enabled then
            if not FlingTargetPlayer then
                WindUI:Notify({ Title = "Erro", Content = "Selecione um alvo!", Duration = 3 })
                LoopFlingEnabled = false
                return false
            end
            task.spawn(function()
                while LoopFlingEnabled do
                    if FlingTargetPlayer then
                        G.flingPlayer(FlingTargetPlayer, FlingPower)
                    end
                    task.wait(0.8)
                end
            end)
        end
    end
})

SectionFling:Button({
    Title = "Fling Player", Desc = "Faz o jogador selecionado voar pelo mapa.",
    Locked = true, LockedTitle = "Em manutenção.",
    Callback = function()
        if FlingTargetPlayer then
            G.flingPlayer(FlingTargetPlayer, FlingPower)
            WindUI:Notify({ Title = "Fling", Content = "Arremessado: "..FlingTargetPlayer.Name, Duration = 3, Icon = "wind" })
        else
            WindUI:Notify({ Title = "Erro", Content = "Selecione um alvo primeiro!", Duration = 3, Icon = "alert-circle" })
        end
    end
})

SectionFling:Toggle({
    Title = "SpyChat", Desc = "Espiona TODOS chats privados/DMs.",
    Locked = true, LockedTitle = "Em manutenção.",
    Icon = "solar:eye-bold", Value = false,
    Callback = function() WindUI:Notify({ Title = "SpyChat", Content = "Em desenvolvimento.", Duration = 2, Icon = "eye" }) end
})

TabExploits:Space({ Columns = 2 })

-------------------------------* Seção: BrookHaven *-------------------------------
task.wait(0.1)
local SectionExploitsTab = TabExploits:Section({
    Title = "BrookHaven", Desc = "",
    Icon = "solar:bolt-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

local brookHavenScripts = {
    { "FAELZIN HUB",     "https://gist.githubusercontent.com/PhantomClientDEV/6d65c2e0f668d998b4be8dcab6d9f969/raw/6d1f08a15d890149f5c033b6f29d51eda3de7149/HalloweenV2.lua" },
    { "BRUTON HUB",      "https://raw.githubusercontent.com/bruton-lua-sources/BRUTON-HUB-/refs/heads/main/BRUTON" },
    { "CARTOLA HUB",     "https://raw.githubusercontent.com/Davi999z/Cartola-Hub/refs/heads/main/Brookhaven" },
    { "PILOT HUB",       "https://pastebin.com/raw/mbm9XDQG" },
    { "SALVATORE",       "https://raw.githubusercontent.com/RFR-R1CH4RD/Loader/main/Salvatore.lua" },
    { "SANDER XY",       "https://raw.githubusercontent.com/kigredns/testUIDK/refs/heads/main/panel.lua" },
    { "HX HEXAGON",      "https://raw.githubusercontent.com/nxvap/hexagon/refs/heads/main/brookhaven" },
    { "COVET HUB",       "https://raw.githubusercontent.com/pl4y80ytt-a11y/VoidHub/refs/heads/main/covet" },
    { "LOBO HUB",        "https://raw.githubusercontent.com/luauhubs666/lobohub/refs/heads/main/lobohub.luau" },
    { "FORBID SPAMMER",  "https://pastefy.app/QjmKIpUW/raw" },
    { "SPECTRA HUB",     "https://raw.githubusercontent.com/assure157tv157157157-boop/Spectra-HUB-V2-/refs/heads/main/URL%20do%20scriptblox" },
    { "CHAD HUB",        "https://raw.githubusercontent.com/bjair5955-wq/Chad-Hub-V2.0/refs/heads/main/obfuscated.lua%20(3).txt" },
    { "MAX HUB",         "https://scriptsneonauth.vercel.app/api/scripts/565a57db-dea3-46cf-b46d-1cfcdcbe7700/raw" },
    { "CHAD HUB V2",     "https://raw.githubusercontent.com/bjair5955-wq/Chad-Hub-V2.0/refs/heads/main/obfuscated.lua%20(3).txt" },
    { "PHANTOM CLIENT",  "https://gist.githubusercontent.com/phantomdevelopers078-star/125196a67d4baa872a569230471dd38b/raw/20eed7bae23eac4fddf8177ca64a3f6323313aca/PhantomClienteasy.lua" },
    { "LYRA HUB",        "https://raw.githubusercontent.com/kayrus999/Lyrapainel/refs/heads/main/Lyrabrookhaven" },
    { "SANT HUB",        "https://rawscripts.net/raw/Brookhaven-RP-Nytherune-Hub-58124" },
}

for i, data in ipairs(brookHavenScripts) do
    local title, url = data[1], data[2]
    SectionExploitsTab:Button({ Title = title, Callback = function() loadstring(game:HttpGet(url, true))() end })
    if i < #brookHavenScripts then SectionExploitsTab:Space({ Columns = 1 }) end
    if i % 5 == 0 then task.wait(0.1) end -- respira a cada 5 botões
end

TabExploits:Space({ Columns = 2 })

-------------------------------* Seção: King-Legacy *-------------------------------
task.wait(0.1)
local SectionExpUniv = TabExploits:Section({
    Title = "King-Legacy", Desc = "",
    Icon = "solar:bolt-bold", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionExpUniv:Button({ Title = "ZEE-HUB UPD 9", Callback = function() loadstring(game:HttpGet("https://zuwz.me/Ls-Zee-Hub-KL"))() end })

TabExploits:Space({ Columns = 1 })

-------------------------------* Seção: Universais *-------------------------------
task.wait(0.1)
local SectionUniversal = TabExploits:Section({
    Title = "Universais", Desc = "",
    Icon = "solar:bolt-bold", Box = true, BoxBorder = true, Opened = true,
})

SectionUniversal:Button({ Title = "DEX-EXPLORER",  Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end })
SectionUniversal:Space({ Columns = 1 })
SectionUniversal:Button({ Title = "TCA GUI",        Callback = function() require(82040251531905):TCA("username") end })
SectionUniversal:Space({ Columns = 1 })
SectionUniversal:Button({ Title = "INFINITE YIELD", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })

--============================================================================
--  TAB: CONFIGURAÇÕES
--============================================================================
task.wait(0.1)
local SectionConfig = TabSettings:Section({
    Title = "General Settings", Desc = "Configurações de tema, keybind e etc.",
    Icon = "settings", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = true,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

local ButtonBypass = SectionConfig:Button({
    Title = "Bypass Anti-Cheat", Desc = "Tenta burlar o sistema anti-cheat do jogo.",
    Callback = function()
        ButtonBypass:Highlight()
        task.delay(2, function() NotifySound:Play() end)
        WindUI:Notify({ Title = "Aviso!", Content = "Bypass ativado com sucesso! (Funcionalidade em desenvolvimento)", Duration = 3, Icon = "shield-check" })
    end
})

SectionConfig:Dropdown({
    Title = "Temas", Desc = "Altera o tema do Royal Hub", Flag = "tema_selecionado",
    Values = {
        { Title = "Hutao By Einzbern" },{ Title = "White" },{ Title = "Main Theme" },
        { Title = "Midnight" },{ Title = "Crimson" },{ Title = "Snow" },{ Title = "Tundra" },
        { Title = "Samurai Dark" },{ Title = "Monokai" },{ Title = "Moonlight" },
        { Title = "Lunar" },{ Title = "Startorch" },{ Title = "Nod Krai" },{ Title = "Hoshimi" },
        { Title = "Kumokiri" },{ Title = "Emerald" },{ Title = "Lost At Sea" },{ Title = "Night Fall" }, { Title = "Obsidian"}

    },
    Value = "Main Theme",
    Callback = function(option) WindUI:SetTheme(option.Title) end
})

SectionConfig:Dropdown({
    Title = "Temas Gradient", Desc = "Altera o tema do Royal Hub para temas gradientes", Flag = "temaGrad_selecionado",
    Values = {{ Title = "CyberPunk" },{ Title = "Solar Theme" },{ Title = "RedX Hub" }},{ Title = "Neon Lights" },
    Value = "null",
    Callback = function(option) WindUI:SetTheme(option.Title) end
})

SectionConfig:Keybind({
    Title = "Toggle UI", Desc = "Altera a tecla que mostra | esconde o menu.",
    Value = "H", Flag = "toggle_ui_key",
    Callback = function(key)
        local ok, k = pcall(function() return Enum.KeyCode[key] end)
        if ok and k then Window:SetToggleKey(k) end
    end
})
SectionConfig:Space({ Columns = 1 })

SectionConfig:Button({
    Title = "Salvar Config", Desc = "Salva tema selecionado e etc.", Icon = "save",
    Callback = function()
        ConfigMenu:Save(); NotifySound:Play()
        WindUI:Notify({ Title = "Configuração salva!", Content = "Sua configuração foi salva com sucesso!", Duration = 3, Icon = "save" })
    end
})

SectionConfig:Button({
    Title = "Carregar config", Desc = "Carrega a configuração salva anteriormente.", Icon = "save",
    Callback = function()
        ConfigMenu:Load(); NotifySound:Play()
        WindUI:Notify({ Title = "Configuração carregada!", Content = "Sua configuração foi carregada com sucesso!", Duration = 3, Icon = "save" })
    end
})

SectionConfig:Space({ Columns = 1 })

SectionConfig:Button({
    Title = "Backdoor scanner", Desc = "Escaneia o jogo em busca de backdoors conhecidos.", Icon = "door-open",
    Callback = function() loadstring(game:HttpGet("https://spawnix.github.io/DevTools.rbxm/Loader/index.lua", true))() end
})

SectionConfig:Space({ Columns = 1 })

SectionConfig:Button({
    Title = "Ejetar script", Desc = "Ejeta a script do jogo.", Icon = "", Color = "Red",
    Callback = function()
        Window:Dialog({
            Icon = "alert-circle", Title = "Confirm Delete", IconThemed = true,
            Content = "Esta ação não pode ser desfeita.",
            Buttons = {
                { Title = "Cancelar", Icon = "x",                     Variant = "secondary",    Callback = function() end },
                { Title = "Ejetar",   Icon = "geist:rotate-clockwise", Variant = "Destructive", Callback = function() Window:Destroy() end },
            }
        })
    end
})

TabSettings:Space({ Columns = 1 })

-------------------------------* Seção: KeyBinds *-------------------------------
task.wait(0.1)
local SectionKeyBinds = TabSettings:Section({
    Title = "KeyBinds", Desc = "Aqui você pode alterar os keybinds das funções.",
    Icon = "keyboard", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = false,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionKeyBinds:Keybind({
    Title = "Aimbot Comum (K)", Flag = "aimbot_comum_keybind", Value = "K",
    Callback = function()
        G.AimbotEnabled.normal = not G.AimbotEnabled.normal; G.toggleAimbot("normal")
        WindUI:Notify({ Title = "Aimbot Comum", Content = G.AimbotEnabled.normal and "Ativado!" or "Desativado!", Duration = 2, Icon = G.AimbotEnabled.normal and "target" or "x" })
    end
})
SectionKeyBinds:Space({ Columns = 1 })

task.wait(0.1)
SectionKeyBinds:Keybind({
    Title = "Aimbot Rage (L)", Flag = "aimbot_rage_keybind", Value = "L",
    Callback = function()
        G.AimbotEnabled.rage = not G.AimbotEnabled.rage; G.toggleAimbot("rage")
        WindUI:Notify({ Title = "Aimbot Rage", Content = G.AimbotEnabled.rage and "Ativado!" or "Desativado!", Duration = 2, Icon = G.AimbotEnabled.rage and "target" or "x" })
    end
})
SectionKeyBinds:Space({ Columns = 1 })

SectionKeyBinds:Keybind({
    Title = "ESP (E)", Flag = "esp_keybind", Value = "E",
    Callback = function() G.toggleESP(not G.EspEnabled) end
})
SectionKeyBinds:Space({ Columns = 1 })

SectionKeyBinds:Keybind({
    Title = "Fly (F)", Flag = "fly_keybind", Value = "F",
    Callback = function() G.toggleFly(not G.FlyEnabled) end
})
SectionKeyBinds:Space({ Columns = 1 })

SectionKeyBinds:Keybind({
    Title = "Spin (G)", Flag = "spin_keybind", Value = "G",
    Callback = function() G.toggleSpin(not G.SpinEnabled) end
})
SectionKeyBinds:Space({ Columns = 1 })

SectionKeyBinds:Keybind({
    Title = "Loop TP (T)", Flag = "looptp_keybind", Value = "T",
    Callback = function() G.toggleLoopTP(not G.LoopTPEnabled) end
})

TabSettings:Space({ Columns = 1 })

-------------------------------* Seção: Config de Funções *-------------------------------
task.wait(0.1)
local SectionConfigFuncs = TabSettings:Section({
    Title = "Configurações de funções", Desc = "Funções para alterar comportamentos da UI.",
    Icon = "settings", TextSize = 19, TextXAlignment = "Left",
    Box = true, BoxBorder = true, Opened = false,
    FontWeight = Enum.FontWeight.SemiBold, DescFontWeight = Enum.FontWeight.Medium,
    TextTransparency = 0.05, DescTextTransparency = 0.4,
})

SectionConfigFuncs:Toggle({
    Title = "Modo anonymous", Desc = "Ativa o modo anonymous, que esconde seu nome e imagem do painel.",
    Icon = "user", Value = false,
    Callback = function(state) Window.User:SetAnonymous(state) end
})

SectionConfigFuncs:Space({ Columns = 1 })

SectionConfigFuncs:Dropdown({
		Title = "Dropdown",
        Locked = true,
        LockedTitle = "Em desenvolvimento",
		Values = {
			{
				Title = "New file",
				Desc = "Create a new file",
				Icon = "file-plus",
				Callback = function()
					print("Clicked 'New File'")
				end,
			},
			{
				Title = "Copy link",
				Desc = "Copy the file link",
				Icon = "copy",
				Callback = function()
					print("Clicked 'Copy link'")
				end,
			},
			{
				Title = "Edit file",
				Desc = "Allows you to edit the file",
				Icon = "file-pen",
				Callback = function()
					print("Clicked 'Edit file'")
				end,
			},
			{
				Type = "Divider",
			},
			{
				Title = "Delete file",
				Desc = "Permanently delete the file",
				Icon = "trash",
				Callback = function()
					print("Clicked 'Delete file'")
				end,
			},
		},
})

--============================================================================
--  TAB: INFO
--============================================================================
task.wait(0.1)
TabInfo:Section({ Title = "Informações", Icon = "solar:info-circle-bold", TextSize = 24, FontWeight = Enum.FontWeight.SemiBold })

TabInfo:Space({ Columns = 2 })

TabInfo:Paragraph({
    Title = "Link do Discord",
    Desc = "Este é o link do nosso Discord, entre para ficar por dentro das novidades e atualizações do Royal Hub!",
    Color = "Grey",
    Image = "geist:logo-discord",
    ImageSize = 40,
    Buttons = {
        {
            Icon = "solar:clipboard-bold", Title = "Clique para copiar o link",
            Callback = function()
                setclipboard("https://discord.gg/DmdTDgJc")
                WindUI:Notify({ Title = "Clipboard", Content = "Link do Discord copiado para a área de transferência!", Duration = 3, Icon = "discord" })
            end,
        }
    }
})

TabInfo:Space({ Columns = 2 })
task.wait(0.1)
local SobreRoyalHub = TabInfo:Section({ Title = "Sobre o Royal Hub", TextSize = 24, FontWeight = Enum.FontWeight.SemiBold })

SobreRoyalHub:Section({
    Title = "Royal Hub é um script feito para o Roblox, Criado apenas por dois desenvolvedores e focado em entregar uma experiência completa e segura para os jogadores. Com uma variedade de funcionalidades, desde melhorias no personagem até opções de farm automatizado, o Royal Hub visa facilitar a jogabilidade e proporcionar vantagens estratégicas dentro do jogo. Desenvolvido com atenção à segurança, o script busca garantir que os usuários possam aproveitar suas funcionalidades sem comprometer a integridade de suas contas. Seja você um jogador casual ou um entusiasta dedicado, o Royal Hub oferece ferramentas que podem aprimorar sua experiência em diversos jogos.",
    TextSize = 18, TextTransparency = .35, FontWeight = Enum.FontWeight.Medium,
})

desativarBlur()