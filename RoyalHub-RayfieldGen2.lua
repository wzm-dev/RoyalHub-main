--[[
    RoyalHub — Port WindUI -> Rayfield Gen2
    Autores: Eodraxkk & Einzbern
    Lib: loadstring(game:HttpGet("https://sirius.menu/gen2"))()

    Notas do port:
    - WindUI Sections viram tab:CreateSection + elementos no tab (Gen2 nao tem
      sections colapsaveis em arvore); pares de toggles ficam em grupos row.
    - Icones WindUI (solar:/geist:) nao portam: no Gen2 string = URL de imagem,
      numero = asset ID. Uso so os icones internos do Rayfield onde faz sentido.
    - Temas custom WindUI viram tabelas de tema Gen2 (overlay parcial).
    - Key system Junkie + animacoes de camera foram removidos a pedido.
]]

--============================================================================--
--  BOOT
--============================================================================--

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- Functions.lua (mesma dependência do Source original)
local functionsLoaded = false
task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BadOctop4s/Functions/refs/heads/main/Functions.lua"))()
    functionsLoaded = true
end)
while not functionsLoaded do task.wait() end
task.wait(0.5)

local G = _G.RH
assert(G, "[RoyalHub] _G.RH nao foi definido! Verifique o Functions.lua")

-- Ilhas (banco de TP por PlaceId, carregado antes da UI)
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

--============================================================================--
--  SERVIÇOS / UTIL
--============================================================================--

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LP          = Players.LocalPlayer

-- Ícones internos do Rayfield (strings viram URL, números são asset IDs)
local ICON = {
    settings   = 129180860773723,
    check      = 125626312718314,
    search     = 100604009889706,
    chevron    = 88479147175134,
    config     = 125823673784681,
    rayfield   = 80387863064905,
}

-- Nomes de players como array de strings (dropdown Gen2 usa strings, o
-- G.playerValues do Functions é {Title=..., Player=...})
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(names, p.Name)
    end
    table.sort(names)
    return names
end

-- Som de notificação (mesmo do original)
local NotifySound = Instance.new("Sound")
NotifySound.SoundId = "rbxassetid://6518811702"
NotifySound.Volume  = 1.0
NotifySound.Parent  = game:GetService("SoundService")

--============================================================================--
--  VARIÁVEIS DE ESTADO (do Source original)
--============================================================================--

local SelectedEmote        = nil
local SelectedPlayerToView = nil
local FlingTargetPlayer    = nil
local FlingPower           = 9000
local LoopFlingEnabled     = false
local CopyTargetPlayer     = nil
local _currentAudioId      = nil -- (placeholder troll audio, em desenvolvimento)
local _currentVolume        = 5   -- (placeholder troll audio, em desenvolvimento)
local _trollAudios         = {}  -- (placeholder troll audio, em desenvolvimento)

--============================================================================--
--  TEMAS CUSTOM (port dos ~24 temas WindUI -> chaves de tema Gen2)
--  Cada tema define só o que muda; o resto overlay em cima do default.
--============================================================================--

local Themes = {
    ["Main Theme"] = {
        WindowColor   = Color3.fromRGB(0, 0, 0),
        ContentColor  = Color3.fromRGB(255, 244, 244),
        AccentColor   = Color3.fromRGB(219, 0, 0),
        ElementGradient = Color3.fromRGB(34, 33, 33),
    },
    ["Hutao By Einzbern"] = {
        WindowColor   = Color3.fromRGB(0, 0, 0),
        ContentColor  = Color3.fromRGB(153, 27, 27),
        AccentColor   = Color3.fromRGB(220, 38, 38),
        ElementGradient = Color3.fromRGB(24, 24, 27),
        ElementStroke   = Color3.fromRGB(153, 27, 27),
    },
    ["Midnight"] = {
        WindowColor   = Color3.fromRGB(12, 30, 66),
        ContentColor  = Color3.fromRGB(219, 234, 254),
        AccentColor   = Color3.fromRGB(37, 99, 235),
        ElementGradient = Color3.fromRGB(30, 58, 138),
        ElementStroke   = Color3.fromRGB(191, 219, 255),
    },
    ["Crimson"] = {
        WindowColor   = Color3.fromRGB(12, 4, 4),
        ContentColor  = Color3.fromRGB(254, 242, 242),
        AccentColor   = Color3.fromRGB(153, 27, 27),
        ElementGradient = Color3.fromRGB(185, 28, 28),
        ElementStroke   = Color3.fromRGB(22, 22, 22),
    },
    ["Snow"] = {
        WindowColor   = Color3.fromRGB(54, 52, 52),
        ContentColor  = Color3.fromRGB(172, 161, 161),
        AccentColor   = Color3.fromRGB(82, 82, 91),
        ElementGradient = Color3.fromRGB(24, 24, 27),
        ElementStroke   = Color3.fromRGB(83, 81, 81),
    },
    ["Tundra"] = {
        WindowColor   = Color3.fromRGB(28, 16, 2),
        ContentColor  = Color3.fromRGB(245, 235, 221),
        AccentColor   = Color3.fromRGB(52, 42, 30),
        ElementGradient = Color3.fromRGB(52, 42, 30),
        ElementStroke   = Color3.fromRGB(107, 90, 69),
    },
    ["Samurai Dark"] = {
        WindowColor   = Color3.fromRGB(0, 0, 0),
        ContentColor  = Color3.fromRGB(172, 161, 161),
        AccentColor   = Color3.fromRGB(82, 82, 91),
        ElementGradient = Color3.fromRGB(24, 24, 27),
        ElementStroke   = Color3.fromRGB(155, 155, 155),
    },
    ["Monokai"] = {
        WindowColor   = Color3.fromRGB(25, 22, 34),
        ContentColor  = Color3.fromRGB(252, 252, 250),
        AccentColor   = Color3.fromRGB(171, 157, 242),
        ElementGradient = Color3.fromRGB(252, 152, 103),
        ElementStroke   = Color3.fromRGB(120, 220, 232),
    },
    ["Moonlight"] = {
        WindowColor   = Color3.fromRGB(0, 0, 0),
        ContentColor  = Color3.fromRGB(212, 212, 212),
        AccentColor   = Color3.fromRGB(82, 91, 91),
        ElementGradient = Color3.fromRGB(24, 14, 27),
        ElementStroke   = Color3.fromRGB(152, 152, 152),
    },
    ["Lunar"] = {
        WindowColor   = Color3.fromRGB(16, 23, 34),
        ContentColor  = Color3.fromRGB(255, 255, 255),
        AccentColor   = Color3.fromRGB(37, 99, 235),
        ElementGradient = Color3.fromRGB(10, 15, 30),
        ElementStroke   = Color3.fromRGB(35, 145, 255),
    },
    ["Startorch"] = {
        WindowColor   = Color3.fromRGB(28, 16, 3),
        ContentColor  = Color3.fromRGB(255, 251, 235),
        AccentColor   = Color3.fromRGB(217, 119, 6),
        ElementGradient = Color3.fromRGB(180, 83, 9),
        ElementStroke   = Color3.fromRGB(252, 211, 77),
    },
    ["Nod Krai"] = {
        WindowColor   = Color3.fromRGB(10, 15, 30),
        ContentColor  = Color3.fromRGB(219, 234, 254),
        AccentColor   = Color3.fromRGB(37, 99, 235),
        ElementGradient = Color3.fromRGB(30, 58, 138),
        ElementStroke   = Color3.fromRGB(191, 219, 254),
    },
    ["Hoshimi"] = {
        WindowColor   = Color3.fromRGB(10, 27, 15),
        ContentColor  = Color3.fromRGB(240, 253, 244),
        AccentColor   = Color3.fromRGB(22, 163, 74),
        ElementGradient = Color3.fromRGB(22, 101, 52),
        ElementStroke   = Color3.fromRGB(16, 16, 16),
    },
    ["Kumokiri"] = {
        WindowColor  = Color3.fromRGB(0, 0, 0),
        ContentColor = Color3.fromRGB(87, 86, 86),
        AccentColor  = Color3.fromRGB(153, 27, 27),
        ElementGradient = Color3.fromRGB(153, 27, 27),
        ElementStroke   = Color3.fromRGB(10, 15, 30),
    },
    ["Emerald"] = {
        WindowColor   = Color3.fromRGB(1, 20, 17),
        ContentColor  = Color3.fromRGB(236, 253, 245),
        AccentColor   = Color3.fromRGB(5, 150, 105),
        ElementGradient = Color3.fromRGB(4, 120, 87),
        ElementStroke   = Color3.fromRGB(167, 243, 208),
    },
    ["Lost At Sea"] = {
        WindowColor   = Color3.fromRGB(12, 30, 66),
        ContentColor  = Color3.fromRGB(255, 255, 255),
        AccentColor   = Color3.fromRGB(82, 82, 91),
        ElementGradient = Color3.fromRGB(0, 0, 0),
        ElementStroke   = Color3.fromRGB(19, 31, 85),
    },
    ["Night Fall"] = {
        WindowColor   = Color3.fromRGB(10, 15, 30),
        ContentColor  = Color3.fromRGB(255, 255, 255),
        AccentColor   = Color3.fromRGB(1, 0, 21),
        ElementGradient = Color3.fromRGB(30, 58, 138),
        ElementStroke   = Color3.fromRGB(20, 20, 40),
    },
    ["Obsidian"] = {
        WindowColor   = Color3.fromRGB(15, 10, 46),
        ContentColor  = Color3.fromRGB(241, 245, 249),
        AccentColor   = Color3.fromRGB(79, 70, 229),
        ElementGradient = Color3.fromRGB(55, 48, 163),
        ElementStroke   = Color3.fromRGB(199, 210, 254),
    },
    ["Deep Dreams"] = {
        WindowColor   = Color3.fromRGB(0, 0, 0),
        ContentColor  = Color3.fromRGB(255, 255, 255),
        AccentColor   = Color3.fromRGB(153, 17, 27),
        ElementGradient = Color3.fromRGB(82, 82, 91),
        ElementStroke   = Color3.fromRGB(153, 17, 27),
    },
    ["White"] = {
        WindowColor   = Color3.fromRGB(187, 167, 167),
        ContentColor  = Color3.fromRGB(0, 0, 0),
        AccentColor   = Color3.fromRGB(0, 0, 0),
        ElementGradient = Color3.fromRGB(100, 100, 102),
        ElementStroke   = Color3.fromRGB(2, 1, 1),
    },
    ["Dark Amoled"] = {
        WindowColor   = Color3.fromRGB(0, 0, 0),
        ContentColor  = Color3.fromRGB(200, 200, 200),
        AccentColor   = Color3.fromRGB(40, 40, 40),
        ElementGradient = Color3.fromRGB(10, 10, 10),
        ElementStroke   = Color3.fromRGB(30, 30, 30),
    },
    ["CyberPunk"] = {
        WindowColor   = Color3.fromRGB(10, 10, 10),
        ContentColor  = Color3.fromRGB(238, 255, 0),
        AccentColor   = Color3.fromRGB(209, 178, 1),
        ElementGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(209, 178, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(238, 255, 0)),
        }),
        ElementStroke   = Color3.fromRGB(120, 110, 0),
    },
    ["Solar"] = {
        WindowColor   = Color3.fromRGB(20, 10, 4),
        ContentColor  = Color3.fromRGB(255, 231, 47),
        AccentColor   = Color3.fromRGB(255, 106, 48),
        ElementGradient = ColorSequence.new(Color3.fromRGB(255, 106, 48), Color3.fromRGB(255, 231, 47)),
        ElementStroke   = Color3.fromRGB(120, 60, 20),
    },
    ["RedX Hub"] = {
        WindowColor   = Color3.fromRGB(5, 5, 8),
        ContentColor  = Color3.fromRGB(200, 210, 255),
        AccentColor   = Color3.fromRGB(1, 82, 195),
        ElementGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(1, 82, 195)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(179, 3, 3)),
        }),
        ElementStroke   = Color3.fromRGB(80, 20, 20),
    },
    ["Neon Lights"] = {
        WindowColor   = Color3.fromRGB(8, 4, 12),
        ContentColor  = Color3.fromRGB(0, 255, 255),
        AccentColor   = Color3.fromRGB(255, 0, 255),
        ElementGradient = ColorSequence.new(Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255)),
        ElementStroke   = Color3.fromRGB(255, 0, 255),
    },
}

--============================================================================--
--  JANELA
--============================================================================--

local Window = Rayfield:CreateWindow({
    name      = "RoyalHub",
    subtitle  = "Eodraxkk & Einzbern",
    icon      = ICON.rayfield,
    theme     = "default",
    sidebarLayout = true,       -- 9 tabs -> rail lateral como no WindUI
    showName  = "Royal Hub",    -- pill quando a janela está escondida
    configuration = {
        autoSave     = true,
        autoLoad     = true,
        fileName     = "RoyalHub_Config",
        customFolder = "RoyalHub",
    },
    locale = "pt-br",
    translations = {
        ["pt-br"] = {
            -- Strings internas do Rayfield (Settings/Configurations)
            ["Settings"]            = "Configurações",
            ["Rayfield Settings"]   = "Configurações do Rayfield",
            ["Configuration"]       = "Configuração",
            ["Configurations"]      = "Configurações",
            ["Configuration Name"]  = "Nome da Configuração",
            ["Saved Configurations"] = "Configurações Salvas",
            ["Search"]              = "Buscar",
            ["Search all pages"]    = "Buscar em todas as páginas",
            ["Toggle Keybind"]      = "Tecla do Menu",
            ["Show profile"]        = "Mostrar perfil",
            ["Welcome toast"]       = "Toast de boas-vindas",
            ["Reset Window Position"] = "Resetar Posição da Janela",
            ["Signed in as"]        = "Logado como",
            ["Pick a configuration to load"]   = "Escolha uma configuração para carregar",
            ["Pick a configuration to delete"] = "Escolha uma configuração para deletar",
            ["Name your configuration first"]  = "Dê um nome à configuração primeiro",
            ["Saved configuration"]   = "Configuração salva",
            ["Loaded configuration"]  = "Configuração carregada",
            ["Deleted configuration"] = "Configuração deletada",
            ["Couldn't save configuration"]   = "Não foi possível salvar a configuração",
            ["Couldn't load configuration"]   = "Não foi possível carregar a configuração",
            ["Couldn't delete configuration"] = "Não foi possível deletar a configuração",
            ["Recording"]           = "Gravando",
            ["Keybind unavailable"] = "Keybind indisponível",
            ["Various"]             = "Diversos",
            ["Secure mode"]         = "Modo seguro",
        },
    },
})


print("========================= Royal Hub (Rayfield Gen2) carregado com sucesso! =========================")

--============================================================================--
--  TAGS (v1.4.4 + Secure + FPS/Ping dinâmicos, como no original)
--============================================================================--

Window:CreateTag({ text = "v1.4.8", color = Color3.fromRGB(240, 208, 26), order = 1 })
Window:CreateTag({ text = "Secure", color = Color3.fromRGB(48, 255, 106), order = 2 })
local FPSTag  = Window:CreateTag({ text = "FPS: 0",    color = Color3.fromRGB(100, 150, 255), order = 3 })
local PingTag = Window:CreateTag({ text = "Ping: 0ms", color = Color3.fromRGB(100, 200, 255), order = 4 })

local lastUpdate, frameCount = tick(), 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSTag:Set({
            text  = "FPS: " .. fps,
            color = if fps >= 50 then Color3.fromRGB(0, 255, 0)
                 elseif fps >= 30 then Color3.fromRGB(255, 200, 0)
                 else Color3.fromRGB(255, 0, 0),
        })
        frameCount = 0
        lastUpdate = now
    end
end)

task.spawn(function()
    while true do
        local ok, ping = pcall(function()
            return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok and ping then
            PingTag:Set({
                text  = "Ping: " .. ping .. "ms",
                color = if ping <= 50 then Color3.fromRGB(0, 255, 0)
                    elseif ping <= 100 then Color3.fromRGB(255, 200, 0)
                    elseif ping <= 200 then Color3.fromRGB(255, 150, 0)
                    else Color3.fromRGB(255, 0, 0),
            })
        end
        task.wait(2)
    end
end)

--============================================================================--
--  TABS - organização nova (12 tabs em 4 grupos no rail)
--  [Combat]      Aimbot & Combat | Visual
--  [Personagem]  Personagem | Farm | Loja | Teleporte
--  [Utilidades]  Exploits | Fun | Utilidades
--  [Hub]         Personalização | Configurações | Info
--============================================================================--

Window:CreateSection({ name = "Combat" })
local TabHome       = Window:CreateTab({ name = "Aimbot & Combat", icon = ICON.config })
local TabVisual     = Window:CreateTab({ name = "Visual",           icon = ICON.rayfield })

Window:CreateSection({ name = "Personagem" })
local TabPersonagem = Window:CreateTab({ name = "Personagem",       icon = ICON.rayfield })
local TabFarm       = Window:CreateTab({ name = "Farm",             icon = ICON.rayfield })
local TabShopping   = Window:CreateTab({ name = "Loja",             icon = ICON.rayfield })
local TabTeleport   = Window:CreateTab({ name = "Teleporte",        icon = ICON.rayfield })

Window:CreateSection({ name = "Utilidades" })
local TabExploits   = Window:CreateTab({ name = "Exploits",         icon = ICON.rayfield })
local TabMisc       = Window:CreateTab({ name = "Fun",             icon = ICON.rayfield })
local TabUtility    = Window:CreateTab({ name = "Utilidades",      icon = ICON.rayfield })

Window:CreateSection({ name = "Hub" })
local TabThemes     = Window:CreateTab({ name = "Personalização",   icon = ICON.settings })
local TabSettings   = Window:CreateTab({ name = "Configurações",    icon = ICON.settings })
local TabInfo       = Window:CreateTab({ name = "Info",             icon = ICON.rayfield })

--============================================================================--
--  TAB: INICIO — Seção Aimbot
--============================================================================--

TabHome:CreateSection({ name = "Aimbot" })

local aimRow = TabHome:CreateGroup()
local ToggleAimbotNormal = aimRow:CreateToggle({
    name = "Aimbot comum",
    flag = "AimbotComum",
    callback = function(enabled)
        G.AimbotEnabled.normal = enabled
        G.toggleAimbot("normal")
    end,
})
local ToggleAimbotRage = aimRow:CreateToggle({
    name = "Aimbot rage",
    flag = "AimbotRage",
    callback = function(enabled)
        G.AimbotEnabled.rage = enabled
        G.toggleAimbot("rage")
    end,
})

TabHome:CreateDropdown({
    name = "Parte do Aimbot",
    description = "Qual parte do corpo o aimbot mira.",
    options = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" },
    value = "Head",
    flag = "AimbotTargetPart",
    callback = function(option) G.setTargetPart(option) end,
})

-- FOV (círculo de mira — aimbot só pega alvo dentro dele)
TabHome:CreateSection({ name = "FOV" })

TabHome:CreateToggle({
    name = "FOV Ativado",
    description = "Aimbot e Silent Aim só pegam alvos dentro do círculo.",
    value = true,
    flag = "FOVEnabled",
    callback = function(state) G.FOVEnabled = state end,
})

TabHome:CreateToggle({
    name = "Mostrar Círculo",
    description = "Desenha o círculo de FOV na tela (precisa de Drawing API).",
    value = true,
    flag = "FOVShowCircle",
    callback = function(state) G.FOVShowCircle = state end,
})

TabHome:CreateSlider({
    name = "Tamanho do FOV",
    description = "Raio do círculo em pixels.",
    range = { 30, 500 },
    increment = 5,
    value = 120,
    flag = "FOVRadius",
    callback = function(value) G.FOVRadius = value end,
})

TabHome:CreateSlider({
    name = "FOV Espessura",
    description = "Espessura da linha do círculo.",
    range = { 1, 5 },
    increment = 1,
    value = 1,
    flag = "FOVThickness",
    callback = function(value) G.setFovThickness(value) end,
})

TabHome:CreateColorPicker({
    name = "FOV Cor",
    color = Color3.fromRGB(255, 255, 255),
    flag = "FOVColor",
    callback = function(color) G.setFovColor(color) end,
})

TabHome:CreateToggle({
    name = "Ignorar Aliados (Team Check)",
    value = true,
    flag = "TeamCheck",
    callback = function(enabled)
        G.UseTeamCheck = enabled
    end,
})

TabHome:CreateToggle({
    name = "Wall Check (Ignorar Paredes)",
    value = true,
    flag = "WallCheck",
    callback = function(enabled)
        G.UseWallCheck = enabled
    end,
})

TabHome:CreateSlider({
    name = "Smooth do Aimbot",
    description = "0.05 = muito suave (lento), 0.5 = direto ao alvo.",
    range = { 0.05, 0.5 },
    increment = 0.01,
    value = 0.15,
    flag = "AimbotSmooth",
    callback = function(value) G.AimbotSmoothFactor = value end,
})

local ToggleESP = TabHome:CreateToggle({
    name = "ESP",
    description = "Players ficam visíveis atrás de paredes e marcados.",
    flag = "ESP",
    callback = function(state) G.toggleESP(state) end,
})

local ToggleESP2 = TabHome:CreateToggle({
    name = "Esp 2.0 (Twilight)",
    description = "ESP com health bar, box e nome — powered by Twilight.",
    flag = "ESP2",
    callback = function(state)
        if state and G.EspEnabled then
            G.toggleESP(false)
            ToggleESP:Set(false, true)
        end
    end,
})
ToggleESP2:Lock("Em desenvolvimento.")

TabHome:CreateToggle({
    name = "ESP — Linhas",
    description = "Desenha linhas do centro da tela até cada inimigo (usa Drawing API).",
    flag = "ESPLines",
    callback = function(state) G.toggleEspLines(state) end,
})

TabHome:CreateToggle({
    name = "ESP — Hitbox Visual",
    description = "Mostra caixas vermelhas ao redor da hitbox expandida (requer Hitbox Expander ativo).",
    flag = "HitboxESP",
    callback = function(state) G.toggleHitboxESP(state) end,
})

TabHome:CreateToggle({
    name = "Fake TP (Dodge)",
    flag = "FakeTP",
    callback = function(enabled) G.toggleFakeTP(enabled) end,
})

TabHome:CreateSlider({
    name = "Delay Fake TP",
    description = "Tempo entre fakes (menor = mais rápido)",
    range = { 0.1, 1 },
    increment = 0.1,
    value = 0.2,
    flag = "FakeTPDelay",
    callback = function(value) G.FakeTPDelay = value end,
})

TabHome:CreateSlider({
    name = "Distância Fake TP",
    description = "Quão longe o fake TP vai (em studs)",
    range = { 1, 10 },
    increment = 1,
    value = 3,
    flag = "FakeTPDist",
    callback = function(value) G.FakeTPDist = value end,
})

--============================================================================--
--  TAB: INICIO — Seção Combat
--============================================================================--

TabHome:CreateSection({ name = "Combat" })

TabHome:CreateToggle({
    name = "Silent Aim",
    description = "Acerta o alvo sem mover a câmera (respeita o FOV).",
    flag = "SilentAim",
    callback = function(state) G.toggleSilentAim(state) end,
})

TabHome:CreateToggle({
    name = "Trigger Bot",
    description = "Atira automaticamente quando o crosshair está sobre um inimigo.",
    flag = "TriggerBot",
    callback = function(state) G.toggleTriggerBot(state) end,
})

TabHome:CreateSlider({
    name = "Trigger Bot Delay",
    description = "Tempo entre cliques (segundos).",
    range = { 0.05, 1 },
    increment = 0.05,
    value = 0.1,
    flag = "TriggerBotDelay",
    callback = function(value) G.setTriggerBotDelay(value) end,
})

TabHome:CreateDropdown({
    name = "Parte do Silent Aim",
    description = "Qual parte do corpo mira.",
    options = { "HumanoidRootPart", "Head", "UpperTorso" },
    value = "HumanoidRootPart",
    flag = "SilentAimPart",
    callback = function(option) G.SilentAimPart = option end,
})

TabHome:CreateToggle({
    name = "Hit Prediction",
    description = "Compensa o lag prevendo a posição do alvo.",
    flag = "HitPred",
    callback = function(state) G.toggleHitPred(state) end,
})

TabHome:CreateSlider({
    name = "Fator de Predição",
    description = "Quanto maior, mais à frente mira (1.0 = 100% do ping).",
    range = { 0.1, 3.0 },
    increment = 0.1,
    value = 1.0,
    flag = "PredictionAmount",
    callback = function(value) G.PredictionAmount = value end,
})

TabHome:CreateToggle({
    name = "Hitbox Expander",
    description = "Expande a hitbox dos jogadores para facilitar acertos.",
    flag = "Hitbox",
    callback = function(state) G.toggleHitbox(state) end,
})

TabHome:CreateSlider({
    name = "Tamanho da Hitbox",
    description = "Em studs. Padrão = 4.",
    range = { 4, 30 },
    increment = 1,
    value = 8,
    flag = "HitboxSize",
    callback = function(value)
        G.HitboxSize = value
        if G.HitboxEnabled then G.removeHitboxes(); G.applyHitboxes() end
    end,
})

TabHome:CreateToggle({
    name = "Auto Parry",
    description = "Aperta a tecla de parry automaticamente quando inimigo está próximo.",
    flag = "AutoParry",
    callback = function(state) G.toggleAutoParry(state) end,
})

TabHome:CreateDropdown({
    name = "Tecla de Parry",
    description = "Tecla que o jogo usa para parry.",
    options = { "Q", "F", "E", "R", "LeftControl" },
    value = "Q",
    flag = "AutoParryKey",
    callback = function(option)
        local ok, key = pcall(function() return Enum.KeyCode[option] end)
        if ok and key then
            G.AutoParryKey = key
            if G.AutoParryEnabled then G.toggleAutoParry(true) end
        end
    end,
})

TabHome:CreateSlider({
    name = "Distância do Auto Parry",
    description = "Distância máxima (studs) para ativar o parry.",
    range = { 5, 30 },
    increment = 1,
    value = 12,
    flag = "AutoParryDist",
    callback = function(value) G.AutoParryDist = value end,
})

--============================================================================--
--  TAB: INICIO — Seção Visual
--============================================================================--

TabVisual:CreateSection({ name = "Visual" })

local SpectateDropdown = TabVisual:CreateDropdown({
    name = "Selecione o Player",
    description = "Seleciona o player para spectate.",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "SpectateTarget",
    callback = function(option)
        SelectedPlayerToView = Players:FindFirstChild(option)
    end,
})

TabVisual:CreateToggle({
    name = "Spectate Player",
    description = "Ativa câmera na perspectiva do player selecionado.",
    flag = "Spectate",
    callback = function(state)
        if state then
            if SelectedPlayerToView then G.startSpectate(SelectedPlayerToView) end
        else
            G.stopSpectate()
        end
    end,
})

TabVisual:CreateToggle({
    name = "NoClip",
    description = "Permite atravessar paredes e objetos.",
    flag = "NoClip",
    callback = function(state) G.toggleNoClip(state) end,
})

-- Crosshair custom
TabVisual:CreateToggle({
    name = "Crosshair",
    description = "Crosshair customizado no centro da tela (Drawing API).",
    flag = "Crosshair",
    callback = function(state) G.toggleCrosshair(state) end,
})

TabVisual:CreateSlider({
    name = "Crosshair Tamanho",
    range = { 2, 20 },
    increment = 1,
    value = 6,
    flag = "CrosshairSize",
    callback = function(value) G.setCrosshairSize(value) end,
})

TabVisual:CreateSlider({
    name = "Crosshair Gap",
    description = "Espaço entre o centro e as linhas.",
    range = { 0, 15 },
    increment = 1,
    value = 3,
    flag = "CrosshairGap",
    callback = function(value) G.setCrosshairGap(value) end,
})

TabVisual:CreateColorPicker({
    name = "Crosshair Cor",
    color = Color3.fromRGB(255, 255, 255),
    flag = "CrosshairColor",
    callback = function(color) G.setCrosshairColor(color) end,
})

-- Camera FOV (FieldOfView real da câmera)
TabVisual:CreateToggle({
    name = "Camera FOV",
    description = "Altera o campo de visão da câmera.",
    flag = "CamFOVEnabled",
    callback = function(state) G.toggleCamFOV(state) end,
})

TabVisual:CreateSlider({
    name = "Camera FOV Valor",
    description = "70 = padrão do Roblox.",
    range = { 30, 120 },
    increment = 1,
    value = 90,
    flag = "CamFOVValue",
    callback = function(value) G.setCamFOV(value) end,
})

--============================================================================--
--  TAB: PERSONAGEM
--============================================================================--

TabPersonagem:CreateSection({ name = "Movimento" })

TabPersonagem:CreateSlider({
    name = "Speed",
    description = "Altera velocidade do jogador",
    range = { 20, 999 }, increment = 1, value = 20,
    flag = "Speed",
    callback = function(value) G.setSpeed(value) end,
})

TabPersonagem:CreateSlider({
    name = "Jump",
    description = "Aumenta a força do pulo",
    range = { 20, 999 }, increment = 1, value = 20,
    flag = "Jump",
    callback = function(value) G.setJumpPower(value) end,
})

local ToggleFly = TabPersonagem:CreateToggle({
    name = "Fly",
    description = "Ativa o modo voo",
    flag = "Fly",
    callback = function(state) G.toggleFly(state) end,
})

TabPersonagem:CreateSlider({
    name = "Velocidade do Fly",
    description = "Ajuste a velocidade do voo.",
    range = { 150, 5000 }, increment = 5, value = 150,
    flag = "FlySpeed",
    callback = function(value)
        G.FlySpeed = value
        if G.FlyEnabled and G.FlyBV and G.FlyBV.Velocity.Magnitude > 0 then
            G.FlyBV.Velocity = G.FlyBV.Velocity.Unit * value
        end
    end,
})

TabPersonagem:CreateSection({ name = "Gravidade" })

TabPersonagem:CreateSlider({
    name = "Gravity",
    description = "Altera a gravidade do jogo",
    range = { 0, 500 }, increment = 1, value = 196.2,
    flag = "Gravity",
    callback = function(value) G.setGravity(value) end,
})

TabPersonagem:CreateButton({
    name = "Reset Gravity",
    description = "Reseta a gravidade para o valor padrão (196.2)",
    callback = function()
        G.setGravity(196.2)
        NotifySound:Play()
        Window:Notify({
            title = "Gravidade resetada!",
            content = "A gravidade foi resetada para o valor padrão (196.2)",
            duration = 3,
        })
    end,
})

TabPersonagem:CreateSection({ name = "Proteção" })

TabPersonagem:CreateToggle({
    name = "Anti-Ragdoll",
    description = "Impede o personagem de cair/ragdoll.",
    flag = "AntiRagdoll",
    callback = function(state) G.toggleAntiRagdoll(state) end,
})

TabPersonagem:CreateToggle({
    name = "God Mode",
    description = "HP Infinito.",
    flag = "God",
    callback = function(state) G.toggleGod(state) end,
})

TabPersonagem:CreateToggle({
    name = "Infinite Jump",
    description = "Permite pular infinitamente no ar.",
    flag = "InfJump",
    callback = function(state) G.toggleInfJump(state) end,
})

TabPersonagem:CreateToggle({
    name = "Anti-AFK",
    description = "Impede ser kickado por inatividade.",
    flag = "AntiAFK",
    callback = function(state) G.toggleAntiAFK(state) end,
})

TabPersonagem:CreateToggle({
    name = "Speed Lock",
    description = "Re-aplica a velocidade mesmo se o jogo tentar resetar.",
    flag = "SpeedLock",
    callback = function(state) G.toggleSpeedLock(state) end,
})

TabPersonagem:CreateToggle({
    name = "Jump Lock",
    description = "Re-aplica o pulo mesmo se o jogo tentar resetar.",
    flag = "JumpLock",
    callback = function(state) G.toggleJumpLock(state) end,
})

TabPersonagem:CreateToggle({
    name = "Auto Respawn",
    description = "Renasce sozinho ao morrer.",
    flag = "AutoRespawn",
    callback = function(state) G.toggleAutoRespawn(state) end,
})

TabPersonagem:CreateSlider({
    name = "Auto Respawn Delay",
    description = "Tempo (s) entre morrer e nascer.",
    range = { 0.5, 10 },
    increment = 0.5,
    value = 1,
    flag = "AutoRespawnDelay",
    callback = function(value) G.setAutoRespawnDelay(value) end,
})

TabPersonagem:CreateSection({ name = "Extras" })

TabPersonagem:CreateToggle({
    name = "Invisível",
    description = "Torna o personagem invisível localmente.",
    flag = "Invisible",
    callback = function(state) G.toggleInvisible(state) end,
})

TabPersonagem:CreateToggle({
    name = "Freeze",
    description = "Congela o personagem no lugar.",
    flag = "Freeze",
    callback = function(state) G.toggleFreeze(state) end,
})

TabPersonagem:CreateToggle({
    name = "Freecam",
    description = "Câmera livre para explorar o mapa. WASD + Q/E + arrastar botão direito.",
    flag = "Freecam",
    callback = function(state) G.toggleFreecam(state) end,
})

TabPersonagem:CreateToggle({
    name = "Fullbright",
    description = "Remove sombras e escuridão do mapa.",
    flag = "Fullbright",
    callback = function(state) G.toggleFullbright(state) end,
})

TabPersonagem:CreateToggle({
    name = "No Fog",
    description = "Remove névoa do jogo.",
    flag = "NoFog",
    callback = function(state) G.toggleNoFog(state) end,
})

TabPersonagem:CreateToggle({
    name = "Xray",
    description = "Torna os personagens inimigos em ForceField para fácil visualização.",
    flag = "Xray",
    callback = function(state) G.toggleXray(state) end,
})

TabPersonagem:CreateToggle({
    name = "Hover Name",
    description = "Mostra nome e DisplayName dos jogadores acima da cabeça.",
    flag = "HoverName",
    callback = function(state) G.toggleHoverName(state) end,
})

TabPersonagem:CreateToggle({
    name = "Radar",
    description = "Radar 2D mostrando posição dos inimigos.",
    flag = "Radar",
    callback = function(state) G.toggleRadar(state) end,
})

TabPersonagem:CreateSlider({
    name = "Radar Range",
    description = "Alcance do radar (em studs).",
    range = { 50, 500 }, increment = 10, value = 150,
    flag = "RadarRange",
    callback = function(value) G.RadarRange = value end,
})

TabPersonagem:CreateToggle({
    name = "Click TP",
    description = "Clique no chão para se teleportar até o ponto.",
    flag = "ClickTP",
    callback = function(state) G.toggleClickTP(state) end,
})

TabPersonagem:CreateToggle({
    name = "Kill Aura",
    description = "Mata automaticamente inimigos próximos.",
    flag = "KillAura",
    callback = function(state) G.toggleKillAura(state) end,
})

TabPersonagem:CreateSlider({
    name = "Kill Aura Range",
    range = { 5, 50 }, increment = 1, value = 15,
    flag = "KillAuraRange",
    callback = function(value) G.KillAuraRange = value end,
})

TabPersonagem:CreateToggle({
    name = "Reach",
    description = "Aumenta o alcance das ferramentas/armas.",
    flag = "Reach",
    callback = function(state) G.toggleReach(state) end,
})

TabPersonagem:CreateSlider({
    name = "Reach Size",
    range = { 1, 50 }, increment = 1, value = 10,
    flag = "ReachSize",
    callback = function(value)
        G.ReachSize = value
        if G.ReachEnabled then G.toggleReach(true, value) end
    end,
})

TabPersonagem:CreateToggle({
    name = "Fling Spin",
    description = "Gira o personagem em alta velocidade.",
    flag = "FlingSpin",
    callback = function(state) G.toggleFlingSpin(state) end,
})

TabPersonagem:CreateSlider({
    name = "Fling Spin Speed",
    description = "Velocidade de rotação do fling spin.",
    range = { 5000, 99999 }, increment = 1, value = 5000,
    flag = "FlingSpinSpeed",
    callback = function(value) G.FlingSpinSpeed = value end,
})

--============================================================================--
--  TAB: FARM
--============================================================================--

TabFarm:CreateSection({ name = "Auto Farm Level" })

local ToggleFarmLevel = TabFarm:CreateToggle({
    name = "Ativar Auto Farm Level",
    description = "Ativa o farm automático de level.",
    flag = "AutoFarmLevel",
    callback = function(state)
    end,
})
ToggleFarmLevel:Lock("Em desenvolvimento.")

TabFarm:CreateSection({ name = "Auto Farm Materials" })

local ToggleFarmMaterials = TabFarm:CreateToggle({
    name = "Ativar Auto Farm Materials",
    description = "Ativa o farm automático de materiais.",
    flag = "AutoFarmMaterials",
    callback = function(state)
    end,
})
ToggleFarmMaterials:Lock("Em desenvolvimento.")

local DropMaterial = TabFarm:CreateDropdown({
    name = "Selecionar Material",
    description = "Seleciona o material que deseja farmar automaticamente.",
    options = { "Material 1", "Material 2", "Material 3" },
    value = "Material 1",
    flag = "FarmMaterial",
    callback = function(option) end,
})
DropMaterial:Lock("Em desenvolvimento.")

--============================================================================--
--  TAB: LOJA
--============================================================================--

TabShopping:CreateSection({ name = "Auto Buy" })

local DropItem = TabShopping:CreateDropdown({
    name = "Selecionar Item",
    description = "Seleciona o item que deseja comprar automaticamente.",
    options = { "Item 1", "Item 2", "Item 3" },
    value = "Item 1",
    flag = "ShopItem",
    callback = function(option) end,
})
DropItem:Lock("Em desenvolvimento.")

local ToggleAutoBuy = TabShopping:CreateToggle({
    name = "Ativar Auto Buy",
    description = "Ativa a compra automática do item selecionado acima.",
    flag = "AutoBuy",
    callback = function(state)
    end,
})
ToggleAutoBuy:Lock("Em desenvolvimento.")

--============================================================================--
--  TAB: TP AND WBHK — Teleport
--============================================================================--

TabTeleport:CreateSection({ name = "Teleport" })

local tpDropdownReady = false
local TPDropdown = TabTeleport:CreateDropdown({
    name = "Teleportar até jogador",
    description = "Teleporta até o jogador selecionado",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "TPTarget",
    callback = function(option)
        G.LoopTPTarget = option
        if tpDropdownReady then
            G.tpToPlayerName(option)
        end
    end,
})
tpDropdownReady = true

local ToggleLoopTP = TabTeleport:CreateToggle({
    name = "Loop TP",
    description = "Teleporta infinitamente no jogador que foi selecionado acima.",
    flag = "LoopTP",
    callback = function(state) G.toggleLoopTP(state) end,
})

TabTeleport:CreateSlider({
    name = "Delay entre TPs",
    description = "Tempo em segundos entre cada teleporte (menor = mais rápido)",
    range = { 0.3, 5 }, increment = 0.1, value = 1,
    flag = "LoopTPDelay",
    callback = function(value)
        G.LoopTPDelay = value
    end,
})

--============================================================================--
--  TAB: TP AND WBHK — Teleport to Islands (Islands.lua)
--============================================================================--

TabTeleport:CreateSection({ name = "Teleport to Islands" })

local IslandDB = (_G.RH and _G.RH.IslandDB) or {}
local currentGameData = IslandDB[game.PlaceId]
local currentSea      = 1
local islandDropdown   = nil

local function getIslandNames(gameData, sea)
    local names = {}
    local seaData = gameData.seas[sea] or gameData.seas[1]
    for _, isl in ipairs(seaData) do
        table.insert(names, isl.Title)
    end
    return names
end

local function refreshIslandDropdown()
    if not currentGameData then return end
    currentSea = currentGameData.detectSea()
    if islandDropdown then
        islandDropdown:Refresh(getIslandNames(currentGameData, currentSea))
    end
    Window:Notify({
        title = "Ilha TP",
        content = currentGameData.name .. " — Sea " .. currentSea .. " detectado!",
        duration = 3,
    })
end

if currentGameData then
    currentSea = currentGameData.detectSea()

    TabTeleport:CreateText({
        name = "Jogo detectado",
        text = currentGameData.name .. "  —  Sea " .. currentSea,
    })

    islandDropdown = TabTeleport:CreateDropdown({
        name = "Selecionar Ilha",
        description = "Ilhas do sea atual.",
        options = getIslandNames(currentGameData, currentSea),
        placeholder = "Selecione...",
        flag = "IslandTP",
        callback = function(option) G.SelectedIsland = option end,
    })

    TabTeleport:CreateButton({
        name = "Teleportar para Ilha",
        callback = function()
            if not G.SelectedIsland then
                Window:Notify({ title = "Ilha TP", content = "Selecione uma ilha primeiro!", duration = 3 })
                return
            end
            local seaData = currentGameData.seas[currentSea] or currentGameData.seas[1]
            for _, isl in ipairs(seaData) do
                if isl.Title == G.SelectedIsland then
                    local root = Players.LocalPlayer.Character
                    root = root and root:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = CFrame.new(isl.pos) * CFrame.new(0, 3, 0)
                        Window:Notify({ title = "Ilha TP", content = "Teleportado para " .. isl.Title, duration = 3 })
                    end
                    return
                end
            end
        end,
    })

    TabTeleport:CreateButton({
        name = "Redetectar Sea",
        description = "Use após trocar de sea.",
        callback = function() refreshIslandDropdown() end,
    })
else
    TabTeleport:CreateText({
        name = "Jogo não suportado",
        text = "PlaceId atual: " .. tostring(game.PlaceId),
    })
end

--============================================================================--
--  TAB: MISC — Miscellaneous
--============================================================================--

TabMisc:CreateSection({ name = "Miscellaneous" })

TabMisc:CreateButton({
    name = "Rejoin",
    description = "Reentra na partida atual.",
    callback = function() G.rejoinServer() end,
})

TabMisc:CreateButton({
    name = "Server Hop",
    description = "Entra em outro servidor da partida atual.",
    callback = function() G.serverHop() end,
})

local BtnRedeem = TabMisc:CreateButton({
    name = "Redeem Codes",
    description = "Resgata códigos automaticamente.",
    callback = function() end,
})
BtnRedeem:Lock("Em desenvolvimento.")

local BtnRewards = TabMisc:CreateButton({
    name = "Collect Rewards",
    description = "Coleta recompensas diárias automaticamente.",
    callback = function() end,
})
BtnRewards:Lock("Em desenvolvimento.")

--============================================================================--
--  TAB: MISC — Fun
--============================================================================--

TabMisc:CreateSection({ name = "Fun" })

local ToggleSpin = TabMisc:CreateToggle({
    name = "Spin",
    description = "Faz o personagem girar infinitamente.",
    flag = "Spin",
    callback = function(state) G.toggleSpin(state) end,
})

local OrbitDropdown = TabMisc:CreateDropdown({
    name = "Orbit — Selecione Jogador",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "OrbitTarget",
    callback = function(option) G.OrbitTarget = option end,
})

TabMisc:CreateToggle({
    name = "Ativar Orbit",
    flag = "Orbit",
    callback = function(state) G.toggleOrbit(state) end,
})

TabMisc:CreateSlider({
    name = "Velocidade Rotação",
    range = { 0.1, 10 }, increment = 1, value = 1,
    flag = "OrbitSpeed",
    callback = function(value)
        G.OrbitSpeed = value
        if G.OrbitEnabled then
        end
    end,
})

local emoteNames = {}
if G.emoteValues then
    for _, v in ipairs(G.emoteValues) do table.insert(emoteNames, v.Title) end
end

TabMisc:CreateDropdown({
    name = "Selecione Emote",
    description = "Emotes disponíveis (mesmo sem ter na conta).",
    options = emoteNames,
    placeholder = "Selecione...",
    flag = "Emote",
    callback = function(option) SelectedEmote = option end,
})

local emoteLoopToggle = TabMisc:CreateToggle({
    name = "Loop Emote",
    description = "Faz o emote repetir automaticamente.",
    flag = "LoopEmote",
    callback = function(state)
        G.LoopEmote = state
        if G.CurrentEmoteTrack and G.CurrentEmoteTrack.IsPlaying then
            if state then
                if not G.EmoteLoopConn then G.activateManualLoop(G.CurrentEmoteTrack) end
            else
                if G.EmoteLoopConn then G.EmoteLoopConn:Disconnect(); G.EmoteLoopConn = nil end
                G.CurrentEmoteTrack:Stop(); G.CurrentEmoteTrack = nil
            end
        end
    end,
})

TabMisc:CreateButton({
    name = "Usar Emote",
    description = "Executa o emote selecionado.",
    callback = function()
        if not SelectedEmote then
            Window:Notify({ title = "Emote", content = "Selecione um emote primeiro!", duration = 4 })
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
            Window:Notify({ title = "Emote", content = "Falha ao carregar "..SelectedEmote.."! ID inválido.", duration = 5 })
            return
        end
        G.CurrentEmoteTrack = track
        if G.LoopEmote then
            G.activateManualLoop(track)
        else
            track.Stopped:Connect(function() if track == G.CurrentEmoteTrack then G.CurrentEmoteTrack = nil end end)
        end
    end,
})

TabMisc:CreateButton({
    name = "Parar Emote",
    description = "Interrompe o emote atual.",
    callback = function()
        if G.CurrentEmoteTrack then G.CurrentEmoteTrack:Stop(); G.CurrentEmoteTrack = nil end
        if G.EmoteLoopConn then G.EmoteLoopConn:Disconnect(); G.EmoteLoopConn = nil end
        G.LoopEmote = false
        emoteLoopToggle:Set(false)
    end,
})

local DropTroll = TabMisc:CreateDropdown({
    name = "IDs Troll Prontos",
    options = {},
    placeholder = "Selecione...",
    flag = "TrollAudio",
    callback = function(selected) end,
})
DropTroll:Lock("Em manutenção")

local SliderVolume = TabMisc:CreateSlider({
    name = "Volume",
    range = { 1, 20 }, increment = 1, value = 5,
    flag = "TrollVolume",
    callback = function(value) _currentVolume = value end,
})
SliderVolume:Lock("Em manutenção.")

local BtnPlayGlobal = TabMisc:CreateButton({
    name = "Tocar Global",
    callback = function()
    end,
})
BtnPlayGlobal:Lock("Em manutenção.")

--============================================================================--
--  TAB: MISC — Utilidades
--============================================================================--

TabUtility:CreateSection({ name = "Utilidades" })

local CopyPlayerDropdown = TabUtility:CreateDropdown({
    name = "Copy Player — Selecionar",
    description = "Selecione o jogador para copiar o visual.",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "CopyTarget",
    callback = function(option) CopyTargetPlayer = Players:FindFirstChild(option) end,
})

TabUtility:CreateButton({
    name = "Copiar Visual",
    description = "Copia o outfit do jogador selecionado.",
    callback = function() G.copyPlayerLook(CopyTargetPlayer) end,
})

TabUtility:CreateToggle({
    name = "Anti-Kick",
    description = "Bloqueia tentativas de kick do servidor.",
    flag = "AntiKick",
    callback = function(state)
        G.AntiKickEnabled = state
    end,
})

TabUtility:CreateToggle({
    name = "Remote Spy",
    description = "Loga todos os RemoteEvents disparados no console.",
    flag = "RemoteSpy",
    callback = function(state)
        G.RemoteSpyEnabled = state
        if state then G.RemoteLogs = {} end
        if state then
            Window:Notify({
                title = "Remote Spy",
                content = "Logando remotes no console...",
                duration = 2,
            })
        end
    end,
})

-- Auto Clicker
TabUtility:CreateToggle({
    name = "Auto Clicker",
    description = "Clica automaticamente N vezes por segundo.",
    flag = "AutoClicker",
    callback = function(state) G.toggleAutoClicker(state) end,
})

TabUtility:CreateSlider({
    name = "Auto Clicker CPS",
    description = "Cliques por segundo.",
    range = { 1, 50 },
    increment = 1,
    value = 10,
    flag = "AutoClickerCPS",
    callback = function(value) G.setAutoClickerCPS(value) end,
})

local remoteConsole = TabUtility:CreateConsole({
    name = "Remote Logs",
    height = 160,
    follow = true,
    maxLines = 200,
})

TabUtility:CreateButton({
    name = "Copiar Logs",
    description = "Copia todos os remotes capturados para a área de transferência.",
    callback = function()
        if not G.RemoteLogs or #G.RemoteLogs == 0 then
            Window:Notify({ title = "Remote Spy", content = "Nenhum log capturado ainda.", duration = 3 })
            return
        end
        local lines = {}
        for _, entry in ipairs(G.RemoteLogs) do
            table.insert(lines, string.format("[%.2fs] %s", entry.t, entry.text))
        end
        local ok = pcall(function() setclipboard(table.concat(lines, "\n")) end)
        remoteConsole:Set(table.concat(lines, "\n"))
        Window:Notify({
            title = "Remote Spy",
            content = #G.RemoteLogs .. " logs copiados" .. (if ok then "!" else " (clipboard indisponível — veja o console)."),
            duration = 3,
        })
    end,
})

TabUtility:CreateButton({
    name = "Limpar Logs",
    callback = function()
        G.RemoteLogs = {}
        remoteConsole:Clear()
    end,
})

-- Espelha os logs do Remote Spy no console da UI
task.spawn(function()
    local lastLogged = 0
    while true do
        if G.RemoteSpyEnabled and G.RemoteLogs and #G.RemoteLogs > lastLogged then
            for i = lastLogged + 1, #G.RemoteLogs do
                remoteConsole:Append(string.format("[%.2fs] %s", G.RemoteLogs[i].t, G.RemoteLogs[i].text))
            end
            lastLogged = #G.RemoteLogs
        end
        task.wait(1)
    end
end)

--============================================================================--
--  TAB: TP AND WBHK — WebHook
--============================================================================--

TabUtility:CreateSection({ name = "Discord WebHook" })

TabUtility:CreateInput({
    name = "URL do WebHook",
    placeholder = "https://discord.com/api/webhooks/...",
    description = "Cole a URL do seu webhook do Discord.",
    flag = "WebhookURL",
    callback = function(value)
        if value and value:find("discord.com/api/webhooks") then
            G.WebhookURL = value
            Window:Notify({ title = "WebHook", content = "URL salva!", duration = 2 })
        end
    end,
})

TabUtility:CreateButton({
    name = "Testar WebHook",
    description = "Envia uma mensagem de teste.",
    callback = function()
        G.sendWebhook("🟢 **RoyalHub** — Teste!\nJogador: **" .. LP.Name .. "**")
    end,
})

TabUtility:CreateToggle({
    name = "Notif de Inventário",
    description = "Envia webhook quando pegar um item novo.",
    flag = "InvWebhook",
    callback = function(state) G.toggleInventoryWebhook(state) end,
})

--============================================================================--
--  TAB: EXPLOITS
--============================================================================--

TabExploits:CreateSection({ name = "Fling" })

local DropFlingTarget = TabExploits:CreateDropdown({
    name = "Selecione Jogador (Fling)",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "FlingTarget",
    callback = function(option) FlingTargetPlayer = Players:FindFirstChild(option) end,
})
DropFlingTarget:Lock("Em Manutenção")

local SliderFlingPower = TabExploits:CreateSlider({
    name = "Fling Power",
    range = { 1000, 50000 }, increment = 1, value = 9000,
    flag = "FlingPower",
    callback = function(value) FlingPower = value end,
})
SliderFlingPower:Lock("Em manutenção.")

local ToggleLoopFling = TabExploits:CreateToggle({
    name = "Loop Fling",
    flag = "LoopFling",
    callback = function(enabled)
        LoopFlingEnabled = enabled
        if enabled then
            if not FlingTargetPlayer then
                Window:Notify({ title = "Erro", content = "Selecione um alvo!", duration = 3 })
                LoopFlingEnabled = false
                return
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
    end,
})
ToggleLoopFling:Lock("Em Manutenção")

local BtnFlingPlayer = TabExploits:CreateButton({
    name = "Fling Player",
    description = "Faz o jogador selecionado voar pelo mapa.",
    callback = function()
        if FlingTargetPlayer then
            G.flingPlayer(FlingTargetPlayer, FlingPower)
            Window:Notify({ title = "Fling", content = "Arremessado: " .. FlingTargetPlayer.Name, duration = 3 })
        else
            Window:Notify({ title = "Erro", content = "Selecione um alvo primeiro!", duration = 3 })
        end
    end,
})
BtnFlingPlayer:Lock("Em manutenção.")

local ToggleSpyChat = TabExploits:CreateToggle({
    name = "SpyChat",
    description = "Espiona TODOS chats privados/DMs.",
    flag = "SpyChat",
    callback = function()
    end,
})
ToggleSpyChat:Lock("Em manutenção.")

--============================================================================--
--  TAB: EXPLOITS — BrookHaven / King-Legacy / Universais
--============================================================================--

TabExploits:CreateSection({ name = "BrookHaven" })

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
    TabExploits:CreateButton({
        name = title,
        callback = function() loadstring(game:HttpGet(url, true))() end,
    })
    if i % 5 == 0 then task.wait(0.1) end -- respira a cada 5 botões
end

TabExploits:CreateSection({ name = "King-Legacy" })

TabExploits:CreateButton({
    name = "ZEE-HUB UPD 9",
    callback = function() loadstring(game:HttpGet("https://zuwz.me/Ls-Zee-Hub-KL"))() end,
})

TabExploits:CreateSection({ name = "Universais" })

TabExploits:CreateButton({
    name = "DEX-EXPLORER",
    callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end,
})

TabExploits:CreateButton({
    name = "TCA GUI",
    callback = function() require(82040251531905):TCA("username") end,
})

TabExploits:CreateButton({
    name = "INFINITE YIELD",
    callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end,
})

--============================================================================--
--  TAB: PERSONALIZAÇÃO - temas (fontes e mais pra vir)
--============================================================================--

TabThemes:CreateSection({ name = "Temas" })

TabThemes:CreateDropdown({
    name = "Tema do Hub",
    description = "Altera o tema visual do Royal Hub (25 temas).",
    options = (function()
        local names = {}
        for name in pairs(Themes) do table.insert(names, name) end
        table.sort(names)
        return names
    end)(),
    placeholder = "Selecione...",
    flag = "tema_selecionado",
    callback = function(option) Window:ChangeTheme(Themes[option]) end,
})

TabThemes:CreateText({
    name = "Fontes",
    text = "Em breve - customização de fonte e textos.",
})


--============================================================================--
--  TAB: CONFIGURAÇÕES
--============================================================================--

TabSettings:CreateSection({ name = "General Settings" })

TabSettings:CreateButton({
    name = "Bypass Anti-Cheat",
    description = "Tenta burlar o sistema anti-cheat do jogo.",
    callback = function()
        task.delay(2, function() NotifySound:Play() end)
    end,
})

TabSettings:CreateButton({
    name = "Backdoor scanner",
    description = "Escaneia o jogo em busca de backdoors conhecidos.",
    callback = function()
        loadstring(game:HttpGet("https://spawnix.github.io/DevTools.rbxm/Loader/index.lua", true))()
    end,
})
TabSettings:CreateButton({
    name = "Ejetar script",
    description = "Desliga todas as funções, reverte alterações e remove a UI.",
    callback = function()
        Window:Popup({
            title = "Confirmar Ejeção",
            content = "Todas as funções serão desligadas e as alterações revertidas. Esta ação não pode ser desfeita.",
            options = {
                { text = "Cancelar" },
                { text = "Ejetar", style = "danger", callback = function()
                    pcall(function() G.unloadAll() end)  -- desliga tudo ANTES de matar a UI
                    Window:Unload()
                end },
            },
        })
    end,
})

--============================================================================--
--  TAB: CONFIGURAÇÕES — KeyBinds
--  (Gen2: keybind é full-width no tab. O menu-toggle fica na aba Settings
--   nativa do Rayfield, editável pelo usuário — não recriamos aqui.)
--============================================================================--

TabSettings:CreateSection({ name = "KeyBinds" })

TabSettings:CreateKeybind({
    name = "Aimbot Comum",
    value = Enum.KeyCode.K,
    flag = "aimbot_comum_keybind",
    callback = function()
        G.AimbotEnabled.normal = not G.AimbotEnabled.normal
        G.toggleAimbot("normal")
        ToggleAimbotNormal:Set(G.AimbotEnabled.normal, true)
    end,
})

TabSettings:CreateKeybind({
    name = "Aimbot Rage",
    value = Enum.KeyCode.L,
    flag = "aimbot_rage_keybind",
    callback = function()
        G.AimbotEnabled.rage = not G.AimbotEnabled.rage
        G.toggleAimbot("rage")
        ToggleAimbotRage:Set(G.AimbotEnabled.rage, true)
    end,
})

TabSettings:CreateKeybind({
    name = "ESP",
    value = Enum.KeyCode.E,
    flag = "esp_keybind",
    callback = function()
        local novo = not G.EspEnabled
        G.toggleESP(novo)
        ToggleESP:Set(novo, true)
    end,
})

TabSettings:CreateKeybind({
    name = "Fly",
    value = Enum.KeyCode.F,
    flag = "fly_keybind",
    callback = function()
        local novo = not G.FlyEnabled
        G.toggleFly(novo)
        ToggleFly:Set(novo, true)
    end,
})

TabSettings:CreateKeybind({
    name = "Spin",
    value = Enum.KeyCode.G,
    flag = "spin_keybind",
    callback = function()
        local novo = not G.SpinEnabled
        G.toggleSpin(novo)
        ToggleSpin:Set(novo, true)
    end,
})

TabSettings:CreateKeybind({
    name = "Loop TP",
    value = Enum.KeyCode.T,
    flag = "looptp_keybind",
    callback = function()
        local novo = not G.LoopTPEnabled
        G.toggleLoopTP(novo)
        ToggleLoopTP:Set(novo, true)
    end,
})

--============================================================================--
--  TAB: CONFIGURAÇÕES — Configurações de funções
--  (o "Modo anonymous" do WindUI não tem API no Gen2; o equivalente é
--   "Show profile" na aba Settings nativa — documentado aqui)
--============================================================================--

TabSettings:CreateSection({ name = "Configurações de funções" })

TabSettings:CreateText({
    name = "Modo anonymous / perfil",
    text = "O modo anonymous (esconder nome e avatar) agora fica na aba Settings nativa do Rayfield: opção \"Show profile\". Lá também ficam a tecla de abrir/fechar o menu (Toggle Keybind) e as configurações salvas (Configurations).",
})

--============================================================================--
--  TAB: INFO
--============================================================================--

TabInfo:CreateSection({ name = "Informações" })

TabInfo:CreateText({
    name = "Link do Discord",
    text = "Este é o link do nosso Discord, entre para ficar por dentro das novidades e atualizações do Royal Hub!",
})

TabInfo:CreateButton({
    name = "Clique para copiar o link do Discord",
    callback = function()
        setclipboard("https://discord.gg/DmdTDgJc")
        Window:Notify({
            title = "Clipboard",
            content = "Link do Discord copiado para a área de transferência!",
            duration = 3,
        })
    end,
})

TabInfo:CreateSection({ name = "Sobre o Royal Hub" })

TabInfo:CreateText({
    name = "Royal Hub",
    text = "Royal Hub é um script feito para o Roblox, criado apenas por dois desenvolvedores e focado em entregar uma experiência completa e segura para os jogadores. Com uma variedade de funcionalidades, desde melhorias no personagem até opções de farm automatizado, o Royal Hub visa facilitar a jogabilidade e proporcionar vantagens estratégicas dentro do jogo. Desenvolvido com atenção à segurança, o script busca garantir que os usuários possam aproveitar suas funcionalidades sem comprometer a integridade de suas contas.",
})


--============================================================================--
--  AUTO-REFRESH DOS DROPDOWNS DE PLAYERS
--  (o original usava G.playerValues vivo; aqui snapshot -> Refresh em
--   PlayerAdded/PlayerRemoving)
--============================================================================--

local playerDropdowns = { SpectateDropdown, TPDropdown, OrbitDropdown, CopyPlayerDropdown }

local function refreshPlayerDropdowns()
    local names = getPlayerNames()
    for _, dd in ipairs(playerDropdowns) do
        if dd then pcall(function() dd:Refresh(names) end) end
    end
end

Players.PlayerAdded:Connect(function() task.defer(refreshPlayerDropdowns) end)
Players.PlayerRemoving:Connect(function() task.defer(refreshPlayerDropdowns) end)

Window:Notify({
    title = "Royal Hub",
    content = "UI carregada com sucesso!",
    duration = 3,
})
