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

--============================================================================--
--  SINGLE INSTANCE: se já tem um RoyalHub vivo nesta sessão, não abre outro.
--  (persistent + re-execução manual podem duplicar; o lock global impede)
--============================================================================--
if _G.RoyalHubLoaded and _G.RoyalHubUnload then
    -- já existe um: destrói o ANTIGO e o novo assume (comportamento "takeover":
    -- o painel fresco sempre vence, sem janela dupla na tela)
    pcall(_G.RoyalHubUnload)
    _G.RoyalHubLoaded = nil
    _G.RoyalHubUnload = nil
    task.wait(0.3)
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- Functions.lua (mesma dependência do Source original)
local functionsLoaded = false
task.spawn(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/wzm-dev/RoyalHub-main/refs/heads/main/Functions.lua"))()
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

-- URL deste script no repo (reload do dev tab + queue_on_teleport)
local REPO_URL = "https://raw.githubusercontent.com/wzm-dev/RoyalHub-main/main/RoyalHub-RayfieldGen2.lua"

-- Ícones: PNGs brancos (Tabler recoloridos) no repo.
-- ESTRATÉGIA: HttpGet -> writefile -> getcustomasset (rbxasset://)
-- URL crua em ImageLabel não carrega no client em vários executores;
-- getcustomasset registra o arquivo local e SEMPRE renderiza.
-- Cache em disco: baixa só na 1ª vez; executor sem writefile -> URL fallback.
local ICON_BASE = "https://raw.githubusercontent.com/wzm-dev/RoyalHub-main/main/assets/icons/"
local ICON_DIR  = "royalhub_icons"

pcall(function()
    if not isfolder(ICON_DIR) then makefolder(ICON_DIR) end
end)

local ICON = {}

local function getIcon(name)
    local webPath = ICON_BASE .. name .. ".png"
    -- tenta registrar localmente
    local okFile = pcall(function()
        local localPath = ICON_DIR .. "/" .. name .. ".png"
        if not isfile(localPath) then
            writefile(localPath, game:HttpGet(webPath))
        end
        if getcustomasset then
            ICON[name] = getcustomasset(localPath)
        end
    end)
    -- fallback: URL crua
    if not ICON[name] then
        ICON[name] = webPath
    end
    return ICON[name]
end
for _, iconName in ipairs({
    "crosshair", "target", "eye", "flare", "skull", "sun", "video",
    "user", "run", "rocket", "shield", "heart", "plant", "cart",
    "map", "cloud", "dice", "tools", "terminal", "box", "bolt",
    "settings", "palette", "info", "keyboard", "crown", "arrow",
}) do
    getIcon(iconName)
end

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
    ["Aurora"] = {
        WindowColor   = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(8, 12, 40)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 45, 90)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 30, 60)),
        }),
        ContentColor  = Color3.fromRGB(200, 230, 255),
        AccentColor   = Color3.fromRGB(64, 255, 200),
        ElementGradient = ColorSequence.new(Color3.fromRGB(30, 200, 160), Color3.fromRGB(50, 120, 220)),
        ElementStroke   = Color3.fromRGB(80, 220, 180),
    },
    ["Sakura Night"] = {
        WindowColor   = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(24, 10, 30)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(45, 15, 45)),
        }),
        ContentColor  = Color3.fromRGB(255, 220, 235),
        AccentColor   = Color3.fromRGB(255, 105, 180),
        ElementGradient = ColorSequence.new(Color3.fromRGB(120, 30, 80), Color3.fromRGB(200, 60, 120)),
        ElementStroke   = Color3.fromRGB(255, 150, 190),
    },
    ["Deep Ocean"] = {
        WindowColor   = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(2, 20, 40)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5, 40, 70)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0, 15, 35)),
        }),
        ContentColor  = Color3.fromRGB(190, 230, 255),
        AccentColor   = Color3.fromRGB(0, 200, 255),
        ElementGradient = ColorSequence.new(Color3.fromRGB(10, 80, 140), Color3.fromRGB(0, 140, 180)),
        ElementStroke   = Color3.fromRGB(80, 200, 255),
    },
    ["Royal Gold"] = {
        WindowColor   = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 16, 8)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(40, 32, 12)),
        }),
        ContentColor  = Color3.fromRGB(255, 240, 200),
        AccentColor   = Color3.fromRGB(255, 200, 40),
        ElementGradient = ColorSequence.new(Color3.fromRGB(120, 90, 20), Color3.fromRGB(200, 160, 40)),
        ElementStroke   = Color3.fromRGB(255, 215, 100),
    },
    ["Vaporwave"] = {
        WindowColor   = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(25, 10, 45)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 15, 65)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(20, 30, 70)),
        }),
        ContentColor  = Color3.fromRGB(255, 200, 255),
        AccentColor   = Color3.fromRGB(255, 100, 200),
        ElementGradient = ColorSequence.new(Color3.fromRGB(255, 80, 180), Color3.fromRGB(100, 80, 255)),
        ElementStroke   = Color3.fromRGB(180, 120, 255),
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
    icon      = ICON.crown,
    theme     = "default",
    sidebarLayout = true,       -- 9 tabs -> rail lateral como no WindUI
    showName  = "Royal Hub",    -- pill quando a janela está escondida
    configuration = {
        autoSave     = true,
        autoLoad     = true,
        fileName     = "RoyalHub_Config",
        customFolder = "RoyalHub",
    },
    -- locale: SEM prop = auto-detecta o idioma do Roblox do jogador
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

        -- English
        ["en-us"] = {
            ["0.05 = muito suave (lento), 0.5 = direto ao alvo."] = "0.05 = very smooth (slow), 0.5 = snaps to target.", ["70 = padrão do Roblox."] = "70 = Roblox default.",
            ["A gravidade foi resetada para o valor padrão (196.2)"] = "Gravity was reset to the default value (196.2)", ["Acerta o alvo sem mover a câmera (respeita o FOV)."] = "Hits the target without moving the camera (respects FOV).",
            ["Aimbot"] = "Aimbot", ["Aimbot & Combat"] = "Aimbot & Combat",
            ["Aimbot Comum"] = "Common Aimbot", ["Aimbot Rage"] = "Rage Aimbot",
            ["Aimbot comum"] = "Common Aimbot", ["Aimbot e Silent Aim só pegam alvos dentro do círculo."] = "Aimbot and Silent Aim only lock targets inside the circle.",
            ["Aimbot rage"] = "Rage Aimbot", ["Ajuste a velocidade do voo."] = "Adjust flight speed.",
            ["Alcance do radar (em studs)."] = "Radar range (in studs).", ["Altera a gravidade do jogo"] = "Changes game gravity",
            ["Altera o campo de visão da câmera."] = "Changes the camera field of view.", ["Altera o tema visual do Royal Hub (25 temas)."] = "Changes the Royal Hub visual theme (25 themes).",
            ["Altera velocidade do jogador"] = "Changes player speed", ["Anti-AFK"] = "Anti-AFK",
            ["Anti-Kick"] = "Anti-Kick", ["Anti-Ragdoll"] = "Anti-Ragdoll",
            ["Aperta a tecla de parry automaticamente quando inimigo está próximo."] = "Presses the parry key automatically when an enemy is close.", ["Atira automaticamente quando o crosshair está sobre um inimigo."] = "Fires automatically when the crosshair is over an enemy.",
            ["Ativa a compra automática do item selecionado acima."] = "Enables auto-buy of the item selected above.", ["Ativa câmera na perspectiva do player selecionado."] = "Camera from the selected player's perspective.",
            ["Ativa o farm automático de level."] = "Enables automatic level farming.", ["Ativa o farm automático de materiais."] = "Enables automatic material farming.",
            ["Ativa o modo voo"] = "Enables flight mode", ["Ativar Auto Buy"] = "Enable Auto Buy",
            ["Ativar Auto Farm Level"] = "Enable Auto Farm Level", ["Ativar Auto Farm Materials"] = "Enable Auto Farm Materials",
            ["Ativar Orbit"] = "Enable Orbit", ["Aumenta a força do pulo"] = "Increases jump power",
            ["Aumenta o alcance das ferramentas/armas."] = "Increases tool/weapon range.", ["Auto Buy"] = "Auto Buy",
            ["Auto Clicker"] = "Auto Clicker", ["Auto Clicker CPS"] = "Auto Clicker CPS",
            ["Auto Farm Level"] = "Auto Farm Level", ["Auto Farm Materials"] = "Auto Farm Materials",
            ["Auto Parry"] = "Auto Parry", ["Auto Respawn"] = "Auto Respawn",
            ["Auto Respawn Delay"] = "Auto Respawn Delay", ["Backdoor scanner"] = "Backdoor scanner",
            ["Bloqueia tentativas de kick do servidor."] = "Blocks server kick attempts.", ["BrookHaven"] = "BrookHaven",
            ["Bypass Anti-Cheat"] = "Bypass Anti-Cheat", ["Camera FOV"] = "Camera FOV",
            ["Camera FOV Valor"] = "Camera FOV Value", ["Cancelar"] = "Cancel",
            ["Carregar config"] = "Load Config", ["Clica automaticamente N vezes por segundo."] = "Clicks N times per second.",
            ["Click TP"] = "Click TP", ["Clipboard"] = "Clipboard",
            ["Clique no chão para se teleportar até o ponto."] = "Click the ground to teleport there.", ["Clique para copiar o link do Discord"] = "Click to copy the Discord link",
            ["Cliques por segundo."] = "Clicks per second.", ["Cole a URL do seu webhook do Discord."] = "Paste your Discord webhook URL.",
            ["Coleta recompensas diárias automaticamente."] = "Collects daily rewards automatically.", ["Collect Rewards"] = "Collect Rewards",
            ["Combat"] = "Combat", ["Compensa o lag prevendo a posição do alvo."] = "Compensates lag by predicting target position.",
            ["Configuration"] = "Configuration", ["Configuration Name"] = "Configuration Name",
            ["Configurations"] = "Configurations", ["Configurações"] = "Settings",
            ["Configurações de funções"] = "Function Settings", ["Confirmar Ejeção"] = "Confirm Eject",
            ["Congela o personagem no lugar."] = "Freezes your character in place.", ["Copia o outfit do jogador selecionado."] = "Copies the selected player's outfit.",
            ["Copia todos os remotes capturados para a área de transferência."] = "Copies all captured remotes to clipboard.", ["Copiar Logs"] = "Copy Logs",
            ["Copiar Visual"] = "Copy Look", ["Copy Player — Selecionar"] = "Copy Player — Select",
            ["Couldn't delete configuration"] = "Couldn't delete configuration", ["Couldn't load configuration"] = "Couldn't load configuration",
            ["Couldn't save configuration"] = "Couldn't save configuration", ["Crosshair"] = "Crosshair",
            ["Crosshair Cor"] = "Crosshair Color", ["Crosshair Gap"] = "Crosshair Gap",
            ["Crosshair Tamanho"] = "Crosshair Size", ["Crosshair customizado no centro da tela (Drawing API)."] = "Custom crosshair at screen center (Drawing API).",
            ["Câmera livre para explorar o mapa. WASD + Q/E + arrastar botão direito."] = "Free camera to explore. WASD + Q/E + right-drag.", ["Delay Fake TP"] = "Fake TP Delay",
            ["Delay entre TPs"] = "Delay Between TPs", ["Deleted configuration"] = "Deleted configuration",
            ["Desenha linhas do centro da tela até cada inimigo (usa Drawing API)."] = "Draws lines from screen center to each enemy (Drawing API).", ["Desenha o círculo de FOV na tela (precisa de Drawing API)."] = "Draws the FOV circle on screen (needs Drawing API).",
            ["Desliga todas as funções, reverte alterações e remove a UI."] = "Turns everything off, reverts changes, removes the UI.", ["Discord WebHook"] = "Discord WebHook",
            ["Distância Fake TP"] = "Fake TP Distance", ["Distância do Auto Parry"] = "Auto Parry Distance",
            ["Distância máxima (studs) para ativar o parry."] = "Max distance (studs) to trigger parry.", ["ESP"] = "ESP",
            ["ESP (E)"] = "ESP (E)", ["ESP com health bar, box e nome — powered by Twilight."] = "ESP with health bar, box and name — powered by Twilight.",
            ["ESP — Hitbox Visual"] = "ESP — Hitbox Visual", ["ESP — Linhas"] = "ESP — Lines",
            ["Ejetar"] = "Eject", ["Ejetar script"] = "Eject Script",
            ["Em breve - customização de fonte e textos."] = "Coming soon — font and text customization.", ["Em studs. Padrão = 4."] = "In studs. Default = 4.",
            ["Emote"] = "Emote", ["Emotes disponíveis (mesmo sem ter na conta)."] = "Available emotes (even if you don't own them).",
            ["Entra em outro servidor da partida atual."] = "Joins another server of the current game.", ["Envia uma mensagem de teste."] = "Sends a test message.",
            ["Envia webhook quando pegar um item novo."] = "Sends a webhook when you pick up a new item.", ["Erro"] = "Error",
            ["Escaneia o jogo em busca de backdoors conhecidos."] = "Scans the game for known backdoors.", ["Esp 2.0 (Twilight)"] = "ESP 2.0 (Twilight)",
            ["Espaço entre o centro e as linhas."] = "Gap between center and lines.", ["Espessura da linha do círculo."] = "Circle line thickness.",
            ["Espiona TODOS chats privados/DMs."] = "Spies on ALL private chats/DMs.", ["Este é o link do nosso Discord, entre para ficar por dentro das novidades e atualizações do Royal Hub!"] = "This is our Discord link — join to stay on top of Royal Hub news and updates!",
            ["Executa o emote selecionado."] = "Plays the selected emote.", ["Expande a hitbox dos jogadores para facilitar acertos."] = "Expands player hitboxes for easier hits.",
            ["Exploits"] = "Exploits", ["Extras"] = "Extras",
            ["FOV"] = "FOV", ["FOV Ativado"] = "FOV Enabled",
            ["FOV Cor"] = "FOV Color", ["FOV Espessura"] = "FOV Thickness",
            ["Fake TP (Dodge)"] = "Fake TP (Dodge)", ["Farm"] = "Farm",
            ["Fator de Predição"] = "Prediction Factor", ["Faz o emote repetir automaticamente."] = "Loops the emote automatically.",
            ["Faz o jogador selecionado voar pelo mapa."] = "Sends the selected player flying.", ["Faz o personagem girar infinitamente."] = "Spins your character endlessly.",
            ["Fling"] = "Fling", ["Fling Spin"] = "Fling Spin",
            ["Fling Spin Speed"] = "Fling Spin Speed", ["Fly"] = "Fly",
            ["Fly (F)"] = "Fly (F)", ["Fontes"] = "Fonts",
            ["Freecam"] = "Freecam", ["Freeze"] = "Freeze",
            ["Fullbright"] = "Fullbright", ["Fun"] = "Fun",
            ["General Settings"] = "General Settings", ["Gira o personagem em alta velocidade."] = "Spins your character at high speed.",
            ["God Mode"] = "God Mode", ["Gravidade"] = "Gravity",
            ["Gravidade resetada!"] = "Gravity reset!", ["Gravity"] = "Gravity",
            ["HP Infinito."] = "Infinite HP.", ["Hit Prediction"] = "Hit Prediction",
            ["Hitbox Expander"] = "Hitbox Expander", ["Hover Name"] = "Hover Name",
            ["Hub"] = "Hub", ["IDs Troll Prontos"] = "Ready Troll IDs",
            ["Ignorar Aliados (Team Check)"] = "Ignore Allies (Team Check)", ["Ilha TP"] = "Island TP",
            ["Ilhas do sea atual."] = "Islands of the current sea.", ["Impede o personagem de cair/ragdoll."] = "Prevents your character from ragdolling.",
            ["Impede ser kickado por inatividade."] = "Prevents AFK kicks.", ["Infinite Jump"] = "Infinite Jump",
            ["Info"] = "Info", ["Informações"] = "Information",
            ["Interrompe o emote atual."] = "Stops the current emote.", ["Invisível"] = "Invisible",
            ["Jogo detectado"] = "Game detected", ["Jogo não suportado"] = "Game not supported",
            ["Jump"] = "Jump", ["Jump Lock"] = "Jump Lock",
            ["KeyBinds"] = "Keybinds", ["Keybind unavailable"] = "Keybind unavailable",
            ["Kill Aura"] = "Kill Aura", ["Kill Aura Range"] = "Kill Aura Range",
            ["King-Legacy"] = "King-Legacy", ["Limpar Logs"] = "Clear Logs",
            ["Link do Discord"] = "Discord Link", ["Link do Discord copiado para a área de transferência!"] = "Discord link copied to clipboard!",
            ["Loaded configuration"] = "Loaded configuration", ["Loga todos os RemoteEvents disparados no console."] = "Logs all fired RemoteEvents to console.",
            ["Logando remotes no console..."] = "Logging remotes to console...", ["Loja"] = "Shop",
            ["Loop Emote"] = "Loop Emote", ["Loop Fling"] = "Loop Fling",
            ["Loop TP"] = "Loop TP", ["Loop TP (T)"] = "Loop TP (T)",
            ["Mata automaticamente inimigos próximos."] = "Automatically kills nearby enemies.", ["Miscellaneous"] = "Miscellaneous",
            ["Modo anonymous / perfil"] = "Anonymous mode / profile", ["Mostra caixas vermelhas ao redor da hitbox expandida (requer Hitbox Expander ativo)."] = "Shows red boxes around the expanded hitbox (needs Hitbox Expander on).",
            ["Mostra nome e DisplayName dos jogadores acima da cabeça."] = "Shows player names above their heads.", ["Mostrar Círculo"] = "Show Circle",
            ["Movimento"] = "Movement", ["Name your configuration first"] = "Name your configuration first",
            ["Nenhum log capturado ainda."] = "No logs captured yet.", ["No Fog"] = "No Fog",
            ["NoClip"] = "Noclip", ["Notif de Inventário"] = "Inventory Notification",
            ["Orbit — Selecione Jogador"] = "Orbit — Select Player", ["Parar Emote"] = "Stop Emote",
            ["Parte do Aimbot"] = "Aimbot Part", ["Parte do Silent Aim"] = "Silent Aim Part",
            ["Permite atravessar paredes e objetos."] = "Walk through walls and objects.", ["Permite pular infinitamente no ar."] = "Jump infinitely in the air.",
            ["Personagem"] = "Character", ["Personalização"] = "Customization",
            ["Pick a configuration to delete"] = "Pick a configuration to delete", ["Pick a configuration to load"] = "Pick a configuration to load",
            ["Players ficam visíveis atrás de paredes e marcados."] = "Players visible through walls and highlighted.", ["Proteção"] = "Protection",
            ["Qual parte do corpo mira."] = "Which body part to aim at.", ["Qual parte do corpo o aimbot mira."] = "Which body part the aimbot targets.",
            ["Quanto maior, mais à frente mira (1.0 = 100% do ping)."] = "Higher = aims further ahead (1.0 = 100% of ping).", ["Quão longe o fake TP vai (em studs)"] = "How far the fake TP goes (in studs)",
            ["Radar"] = "Radar", ["Radar 2D mostrando posição dos inimigos."] = "2D radar showing enemy positions.",
            ["Radar Range"] = "Radar Range", ["Raio do círculo em pixels."] = "Circle radius in pixels.",
            ["Rayfield Settings"] = "Rayfield Settings", ["Re-aplica a velocidade mesmo se o jogo tentar resetar."] = "Re-applies speed even if the game resets it.",
            ["Re-aplica o pulo mesmo se o jogo tentar resetar."] = "Re-applies jump even if the game resets it.", ["Reach"] = "Reach",
            ["Reach Size"] = "Reach Size", ["Recording"] = "Recording",
            ["Redeem Codes"] = "Redeem Codes", ["Redetectar Sea"] = "Redetect Sea",
            ["Reentra na partida atual."] = "Rejoins the current game.", ["Rejoin"] = "Rejoin",
            ["Remote Logs"] = "Remote Logs", ["Remote Spy"] = "Remote Spy",
            ["Remove névoa do jogo."] = "Removes game fog.", ["Remove sombras e escuridão do mapa."] = "Removes shadows and darkness.",
            ["Renasce sozinho ao morrer."] = "Auto-respawns when you die.", ["Reset Gravity"] = "Reset Gravity",
            ["Reset Window Position"] = "Reset Window Position", ["Reseta a gravidade para o valor padrão (196.2)"] = "Resets gravity to default (196.2)",
            ["Resgata códigos automaticamente."] = "Redeems codes automatically.", ["Royal Hub é um script feito para o Roblox, criado apenas por dois desenvolvedores e focado em entregar uma experiência completa e segura para os jogadores. Com uma variedade de funcionalidades, desde melhorias no personagem até opções de farm automatizado, o Royal Hub visa facilitar a jogabilidade e proporcionar vantagens estratégicas dentro do jogo. Desenvolvido com atenção à segurança, o script busca garantir que os usuários possam aproveitar suas funcionalidades sem comprometer a integridade de suas contas."] = "Royal Hub is a Roblox script built by two developers, focused on a complete and safe player experience. With features ranging from character upgrades to automated farming, Royal Hub makes gameplay easier and gives you a strategic edge. Developed with security in mind, so you can enjoy every feature without putting your account at risk.",
            ["Salvar Config"] = "Save Config", ["Saved Configurations"] = "Saved Configurations",
            ["Saved configuration"] = "Saved configuration", ["Search"] = "Search",
            ["Search all pages"] = "Search all pages", ["Secure mode"] = "Secure mode",
            ["Seleciona o item que deseja comprar automaticamente."] = "Selects the item to auto-buy.", ["Seleciona o material que deseja farmar automaticamente."] = "Selects the material to auto-farm.",
            ["Seleciona o player para spectate."] = "Selects the player to spectate.", ["Selecionar Ilha"] = "Select Island",
            ["Selecionar Item"] = "Select Item", ["Selecionar Material"] = "Select Material",
            ["Selecione Emote"] = "Select Emote", ["Selecione Jogador (Fling)"] = "Select Player (Fling)",
            ["Selecione o Player"] = "Select Player", ["Selecione o jogador para copiar o visual."] = "Select the player to copy the look from.",
            ["Selecione um alvo primeiro!"] = "Select a target first!", ["Selecione um alvo!"] = "Select a target!",
            ["Selecione um emote primeiro!"] = "Select an emote first!", ["Selecione uma ilha primeiro!"] = "Select an island first!",
            ["Selecione..."] = "Select...", ["Server Hop"] = "Server Hop",
            ["Settings"] = "Settings", ["Show profile"] = "Show profile",
            ["Signed in as"] = "Signed in as", ["Silent Aim"] = "Silent Aim",
            ["Smooth do Aimbot"] = "Aimbot Smoothing", ["Sobre o Royal Hub"] = "About Royal Hub",
            ["Spectate Player"] = "Spectate Player", ["Speed"] = "Speed",
            ["Speed Lock"] = "Speed Lock", ["Spin"] = "Spin",
            ["Spin (G)"] = "Spin (G)", ["SpyChat"] = "SpyChat",
            ["Tamanho da Hitbox"] = "Hitbox Size", ["Tamanho do FOV"] = "FOV Size",
            ["Tecla de Parry"] = "Parry Key", ["Tecla que o jogo usa para parry."] = "Key the game uses for parry.",
            ["Teleport"] = "Teleport", ["Teleport to Islands"] = "Teleport to Islands",
            ["Teleporta até o jogador selecionado"] = "Teleports to the selected player", ["Teleporta infinitamente no jogador que foi selecionado acima."] = "Endlessly teleports to the player selected above.",
            ["Teleportar até jogador"] = "Teleport to Player", ["Teleportar para Ilha"] = "Teleport to Island",
            ["Teleporte"] = "Teleport", ["Tema do Hub"] = "Hub Theme",
            ["Temas"] = "Themes", ["Tempo (s) entre morrer e nascer."] = "Time (s) between death and respawn.",
            ["Tempo em segundos entre cada teleporte (menor = mais rápido)"] = "Seconds between each teleport (lower = faster)", ["Tempo entre cliques (segundos)."] = "Time between clicks (seconds).",
            ["Tempo entre fakes (menor = mais rápido)"] = "Time between fakes (lower = faster)", ["Tenta burlar o sistema anti-cheat do jogo."] = "Tries to bypass the game's anti-cheat.",
            ["Testar WebHook"] = "Test WebHook", ["Tocar Global"] = "Play Global",
            ["Todas as funções serão desligadas e as alterações revertidas. Esta ação não pode ser desfeita."] = "All features will be turned off and changes reverted. This action cannot be undone.", ["Toggle Keybind"] = "Toggle Keybind",
            ["Torna o personagem invisível localmente."] = "Makes your character locally invisible.", ["Torna os personagens inimigos em ForceField para fácil visualização."] = "Turns enemies into ForceField for easy spotting.",
            ["Trigger Bot"] = "Trigger Bot", ["Trigger Bot Delay"] = "Trigger Bot Delay",
            ["UI carregada com sucesso!"] = "UI loaded successfully!", ["URL do WebHook"] = "WebHook URL",
            ["URL salva!"] = "URL saved!", ["Universais"] = "Universal",
            ["Usar Emote"] = "Use Emote", ["Use após trocar de sea."] = "Use after switching seas.",
            ["Utilidades"] = "Utilities", ["Various"] = "Various",
            ["Velocidade Rotação"] = "Rotation Speed", ["Velocidade de rotação do fling spin."] = "Fling spin rotation speed.",
            ["Velocidade do Fly"] = "Fly Speed", ["Visual"] = "Visual",
            ["Volume"] = "Volume", ["Wall Check (Ignorar Paredes)"] = "Wall Check (Ignore Walls)",
            ["WebHook"] = "WebHook", ["Welcome toast"] = "Welcome toast",
            ["Xray"] = "Xray",
            ["Altera o idioma da interface na hora."] = "Changes the interface language instantly.", ["Arremessado: "] = "Launched: ",
            ["Falha ao carregar "] = "Failed to load ", ["Fling Player"] = "Fling Player",
            ["Fling Power"] = "Fling Power", ["Idioma"] = "Language",
            ["RoyalHub"] = "RoyalHub", ["Secure"] = "Secure",
            ["Teleportado para "] = "Teleported to ",
            ["O modo anonymous (esconder nome e avatar) agora fica na aba Settings nativa do Rayfield: opção \"Show profile\". Lá também ficam a tecla de abrir/fechar o menu (Toggle Keybind) e as configurações salvas (Configurations)."] = "The anonymous mode (hiding name and avatar) now lives in Rayfield's native Settings tab: the \"Show profile\" option. The menu toggle key (Toggle Keybind) and saved configurations (Configurations) are there too.",
            ["Royal Hub"] = "Royal Hub",
            ["ESP Box"] = "ESP Box",
            ["Caixa de cantos ao redor do jogador (estilo corner box)."] = "Corner box around the player.",
            ["Barra de vida à esquerda do box (verde -> amarelo -> vermelho)."] = "Health bar left of the box (green -> yellow -> red).",
            ["Nome acima e distância embaixo do jogador."] = "Name above, distance below the player.",
            ["Box Cor"] = "Box Color",
            ["Info Cor (Nome)"] = "Info Color (Name)",
            ["ESP Health Bar"] = "ESP Health Bar",
            ["ESP Info"] = "ESP Info",
            ["Minimap"] = "Minimap",
            ["Radar 2D no canto da tela: você no centro, seta = visão da câmera."] = "2D radar on screen: you at the center, arrow = camera facing.",
            ["Minimap Alcance"] = "Minimap Range",
            ["Raio de detecção em studs."] = "Detection radius in studs.",
            ["Minimap Nomes"] = "Minimap Names",
            ["Mostra o nome acima de cada blip."] = "Shows the name above each blip.",
            ["Minimap Cores de Time"] = "Minimap Team Colors",
            ["Aliados azuis, inimigos vermelhos."] = "Allies blue, enemies red.",
        },
        -- Español
        ["es"] = {
            ["0.05 = muito suave (lento), 0.5 = direto ao alvo."] = "0.05 = very smooth (slow), 0.5 = snaps to target.", ["70 = padrão do Roblox."] = "70 = Roblox default.",
            ["A gravidade foi resetada para o valor padrão (196.2)"] = "La gravedad fue restablecida al valor predeterminado (196.2)", ["Acerta o alvo sem mover a câmera (respeita o FOV)."] = "Hits the target without moving the camera (respects FOV).",
            ["Aimbot"] = "Aimbot", ["Aimbot & Combat"] = "Aimbot & Combat",
            ["Aimbot Comum"] = "Aimbot común", ["Aimbot Rage"] = "Aimbot rage",
            ["Aimbot comum"] = "Aimbot común", ["Aimbot e Silent Aim só pegam alvos dentro do círculo."] = "Aimbot and Silent Aim only lock targets inside the circle.",
            ["Aimbot rage"] = "Aimbot rage", ["Ajuste a velocidade do voo."] = "Adjust flight speed.",
            ["Alcance do radar (em studs)."] = "Radar range (in studs).", ["Altera a gravidade do jogo"] = "Changes game gravity",
            ["Altera o campo de visão da câmera."] = "Changes the camera field of view.", ["Altera o tema visual do Royal Hub (25 temas)."] = "Changes the Royal Hub visual theme (25 themes).",
            ["Altera velocidade do jogador"] = "Changes player speed", ["Anti-AFK"] = "Anti-AFK",
            ["Anti-Kick"] = "Anti-Kick", ["Anti-Ragdoll"] = "Anti-Ragdoll",
            ["Aperta a tecla de parry automaticamente quando inimigo está próximo."] = "Presses the parry key automatically when an enemy is close.", ["Atira automaticamente quando o crosshair está sobre um inimigo."] = "Fires automatically when the crosshair is over an enemy.",
            ["Ativa a compra automática do item selecionado acima."] = "Enables auto-buy of the item selected above.", ["Ativa câmera na perspectiva do player selecionado."] = "Camera from the selected player's perspective.",
            ["Ativa o farm automático de level."] = "Enables automatic level farming.", ["Ativa o farm automático de materiais."] = "Enables automatic material farming.",
            ["Ativa o modo voo"] = "Enables flight mode", ["Ativar Auto Buy"] = "Activar Auto Buy",
            ["Ativar Auto Farm Level"] = "Activar Auto Farm Level", ["Ativar Auto Farm Materials"] = "Activar Auto Farm Materials",
            ["Ativar Orbit"] = "Activar órbita", ["Aumenta a força do pulo"] = "Increases jump power",
            ["Aumenta o alcance das ferramentas/armas."] = "Increases tool/weapon range.", ["Auto Buy"] = "Auto Buy",
            ["Auto Clicker"] = "Auto clicker", ["Auto Clicker CPS"] = "CPS del Auto Clicker",
            ["Auto Farm Level"] = "Auto Farm Level", ["Auto Farm Materials"] = "Auto Farm Materials",
            ["Auto Parry"] = "Auto Parry", ["Auto Respawn"] = "Auto respawn",
            ["Auto Respawn Delay"] = "Delay de auto respawn", ["Backdoor scanner"] = "Backdoor scanner",
            ["Bloqueia tentativas de kick do servidor."] = "Blocks server kick attempts.", ["BrookHaven"] = "BrookHaven",
            ["Bypass Anti-Cheat"] = "Bypass Anti-Cheat", ["Camera FOV"] = "FOV de cámara",
            ["Camera FOV Valor"] = "Valor FOV de cámara", ["Cancelar"] = "Cancelar",
            ["Carregar config"] = "Cargar config", ["Clica automaticamente N vezes por segundo."] = "Clicks N times per second.",
            ["Click TP"] = "Click TP", ["Clipboard"] = "Portapapeles",
            ["Clique no chão para se teleportar até o ponto."] = "Click the ground to teleport there.", ["Clique para copiar o link do Discord"] = "Clic para copiar el link de Discord",
            ["Cliques por segundo."] = "Clicks per second.", ["Cole a URL do seu webhook do Discord."] = "Paste your Discord webhook URL.",
            ["Coleta recompensas diárias automaticamente."] = "Collects daily rewards automatically.", ["Collect Rewards"] = "Recolectar recompensas",
            ["Combat"] = "Combat", ["Compensa o lag prevendo a posição do alvo."] = "Compensates lag by predicting target position.",
            ["Configuration"] = "Configuración", ["Configuration Name"] = "Nombre de configuración",
            ["Configurations"] = "Configuraciones", ["Configurações"] = "Ajustes",
            ["Configurações de funções"] = "Ajustes de funciones", ["Confirmar Ejeção"] = "Confirmar eyección",
            ["Congela o personagem no lugar."] = "Freezes your character in place.", ["Copia o outfit do jogador selecionado."] = "Copies the selected player's outfit.",
            ["Copia todos os remotes capturados para a área de transferência."] = "Copies all captured remotes to clipboard.", ["Copiar Logs"] = "Copiar logs",
            ["Copiar Visual"] = "Copiar visual", ["Copy Player — Selecionar"] = "Copy Player — Seleccionar",
            ["Couldn't delete configuration"] = "No se pudo eliminar la configuración", ["Couldn't load configuration"] = "No se pudo cargar la configuración",
            ["Couldn't save configuration"] = "No se pudo guardar la configuración", ["Crosshair"] = "Crosshair",
            ["Crosshair Cor"] = "Color del crosshair", ["Crosshair Gap"] = "Gap del crosshair",
            ["Crosshair Tamanho"] = "Tamaño del crosshair", ["Crosshair customizado no centro da tela (Drawing API)."] = "Custom crosshair at screen center (Drawing API).",
            ["Câmera livre para explorar o mapa. WASD + Q/E + arrastar botão direito."] = "Free camera to explore. WASD + Q/E + right-drag.", ["Delay Fake TP"] = "Delay del Fake TP",
            ["Delay entre TPs"] = "Delay entre TPs", ["Delay entre TPs."] = "Delay entre TPs",
            ["Deleted configuration"] = "Configuración eliminada", ["Desenha linhas do centro da tela até cada inimigo (usa Drawing API)."] = "Draws lines from screen center to each enemy (Drawing API).",
            ["Desenha o círculo de FOV na tela (precisa de Drawing API)."] = "Draws the FOV circle on screen (needs Drawing API).", ["Desliga todas as funções, reverte alterações e remove a UI."] = "Turns everything off, reverts changes, removes the UI.",
            ["Discord WebHook"] = "WebHook de Discord", ["Distância Fake TP"] = "Distancia del Fake TP",
            ["Distância do Auto Parry"] = "Distancia del Auto Parry", ["Distância máxima (studs) para ativar o parry."] = "Max distance (studs) to trigger parry.",
            ["ESP"] = "ESP", ["ESP (E)"] = "ESP (E)",
            ["ESP — Hitbox Visual"] = "ESP — Hitbox Visual",
            ["ESP — Linhas"] = "ESP — Lines", ["Ejetar"] = "Eyectar",
            ["Ejetar script"] = "Eyectar script", ["Em breve - customização de fonte e textos."] = "Pronto — personalización de fuente y textos.",
            ["Em studs. Padrão = 4."] = "In studs. Default = 4.", ["Emote"] = "Emote",
            ["Emotes disponíveis (mesmo sem ter na conta)."] = "Available emotes (even if you don't own them).", ["Entra em outro servidor da partida atual."] = "Joins another server of the current game.",
            ["Envia uma mensagem de teste."] = "Sends a test message.", ["Envia webhook quando pegar um item novo."] = "Sends a webhook when you pick up a new item.",
            ["Erro"] = "Error", ["Escaneia o jogo em busca de backdoors conhecidos."] = "Scans the game for known backdoors.",
            ["Espaço entre o centro e as linhas."] = "Gap between center and lines.",
            ["Espessura da linha do círculo."] = "Circle line thickness.", ["Espiona TODOS chats privados/DMs."] = "Spies on ALL private chats/DMs.",
            ["Este é o link do nosso Discord, entre para ficar por dentro das novidades e atualizações do Royal Hub!"] = "This is our Discord link — join to stay on top of Royal Hub news and updates!", ["Executa o emote selecionado."] = "Plays the selected emote.",
            ["Expande a hitbox dos jogadores para facilitar acertos."] = "Expands player hitboxes for easier hits.", ["Exploits"] = "Exploits",
            ["Extras"] = "Extras", ["FOV"] = "FOV",
            ["FOV Ativado"] = "FOV activado", ["FOV Cor"] = "Color del FOV",
            ["FOV Espessura"] = "Grosor del FOV", ["Fake TP (Dodge)"] = "Fake TP (Dodge)",
            ["Farm"] = "Farm", ["Fator de Predição"] = "Factor de predicción",
            ["Faz o emote repetir automaticamente."] = "Loops the emote automatically.", ["Faz o jogador selecionado voar pelo mapa."] = "Sends the selected player flying.",
            ["Faz o personagem girar infinitamente."] = "Spins your character endlessly.", ["Fling"] = "Fling",
            ["Fling Spin"] = "Fling Spin", ["Fling Spin Speed"] = "Velocidad del Fling Spin",
            ["Fly"] = "Fly", ["Fly (F)"] = "Fly (F)",
            ["Fontes"] = "Fuentes", ["Freecam"] = "Freecam",
            ["Freeze"] = "Congelar", ["Fullbright"] = "Fullbright",
            ["Fun"] = "Diversión", ["General Settings"] = "General Settings",
            ["Gira o personagem em alta velocidade."] = "Spins your character at high speed.", ["God Mode"] = "God Mode",
            ["Gravidade"] = "Gravedad", ["Gravidade resetada!"] = "¡Gravedad restablecida!",
            ["Gravity"] = "Gravity", ["HP Infinito."] = "Infinite HP.",
            ["Hit Prediction"] = "Hit Prediction", ["Hitbox Expander"] = "Hitbox Expander",
            ["Hover Name"] = "Nombre flotante", ["Hub"] = "Hub",
            ["IDs Troll Prontos"] = "IDs troll listas", ["Ignorar Aliados (Team Check)"] = "Ignorar aliados (Team Check)",
            ["Ilha TP"] = "TP de isla", ["Ilhas do sea atual."] = "Islands of the current sea.",
            ["Impede o personagem de cair/ragdoll."] = "Prevents your character from ragdolling.", ["Impede ser kickado por inatividade."] = "Prevents AFK kicks.",
            ["Infinite Jump"] = "Salto infinito", ["Info"] = "Info",
            ["Informações"] = "Información", ["Interrompe o emote atual."] = "Stops the current emote.",
            ["Invisível"] = "Invisible", ["Jogo detectado"] = "Juego detectado",
            ["Jogo não suportado"] = "Juego no soportado", ["Jump"] = "Jump",
            ["Jump Lock"] = "Jump Lock", ["KeyBinds"] = "Keybinds",
            ["Keybind unavailable"] = "Tecla no disponible", ["Kill Aura"] = "Kill Aura",
            ["Kill Aura Range"] = "Alcance del Kill Aura", ["King-Legacy"] = "King-Legacy",
            ["Limpar Logs"] = "Limpiar logs", ["Link do Discord"] = "Link de Discord",
            ["Link do Discord copiado para a área de transferência!"] = "¡Link de Discord copiado al portapapeles!", ["Loaded configuration"] = "Configuración cargada",
            ["Loga todos os RemoteEvents disparados no console."] = "Logs all fired RemoteEvents to console.", ["Logando remotes no console..."] = "Registrando remotes en consola...",
            ["Loja"] = "Tienda", ["Loop Emote"] = "Emote en loop",
            ["Loop Fling"] = "Fling en loop", ["Loop TP"] = "Loop TP",
            ["Loop TP (T)"] = "Loop TP (T)", ["Mata automaticamente inimigos próximos."] = "Automatically kills nearby enemies.",
            ["Miscellaneous"] = "Miscellaneous", ["Modo anonymous / perfil"] = "Anonymous mode / profile",
            ["Mostra caixas vermelhas ao redor da hitbox expandida (requer Hitbox Expander ativo)."] = "Shows red boxes around the expanded hitbox (needs Hitbox Expander on).", ["Mostra nome e DisplayName dos jogadores acima da cabeça."] = "Shows player names above their heads.",
            ["Mostrar Círculo"] = "Mostrar círculo", ["Movimento"] = "Movimiento",
            ["Name your configuration first"] = "Primero nombra tu configuración", ["Nenhum log capturado ainda."] = "Aún no hay logs capturados.",
            ["No Fog"] = "Sin niebla", ["NoClip"] = "Noclip",
            ["Notif de Inventário"] = "Notif. de inventario", ["Orbit — Selecione Jogador"] = "Órbita — Seleccionar jugador",
            ["Parar Emote"] = "Detener emote", ["Parte do Aimbot"] = "Parte del aimbot",
            ["Parte do Silent Aim"] = "Parte del Silent Aim", ["Permite atravessar paredes e objetos."] = "Walk through walls and objects.",
            ["Permite pular infinitamente no ar."] = "Jump infinitely in the air.", ["Personagem"] = "Personaje",
            ["Personalização"] = "Personalización", ["Pick a configuration to delete"] = "Elige una configuración para eliminar",
            ["Pick a configuration to load"] = "Elige una configuración para cargar", ["Players ficam visíveis atrás de paredes e marcados."] = "Players visible through walls and highlighted.",
            ["Proteção"] = "Protección", ["Qual parte do corpo mira."] = "Which body part to aim at.",
            ["Qual parte do corpo o aimbot mira."] = "Which body part the aimbot targets.", ["Quanto maior, mais à frente mira (1.0 = 100% do ping)."] = "Higher = aims further ahead (1.0 = 100% of ping).",
            ["Quão longe o fake TP vai (em studs)"] = "How far the fake TP goes (in studs)", ["Radar"] = "Radar",
            ["Radar 2D mostrando posição dos inimigos."] = "2D radar showing enemy positions.", ["Radar Range"] = "Alcance del radar",
            ["Raio do círculo em pixels."] = "Circle radius in pixels.", ["Rayfield Settings"] = "Ajustes de Rayfield",
            ["Re-aplica a velocidade mesmo se o jogo tentar resetar."] = "Re-applies speed even if the game resets it.", ["Re-aplica o pulo mesmo se o jogo tentar resetar."] = "Re-applies jump even if the game resets it.",
            ["Reach"] = "Reach", ["Reach Size"] = "Tamaño del reach",
            ["Recording"] = "Grabando", ["Redeem Codes"] = "Canjear códigos",
            ["Redetectar Sea"] = "Redetectar mar", ["Reentra na partida atual."] = "Rejoins the current game.",
            ["Rejoin"] = "Reentrar", ["Remote Logs"] = "Logs de remotes",
            ["Remote Spy"] = "Remote Spy", ["Remove névoa do jogo."] = "Removes game fog.",
            ["Remove sombras e escuridão do mapa."] = "Removes shadows and darkness.", ["Renasce sozinho ao morrer."] = "Auto-respawns when you die.",
            ["Reset Gravity"] = "Restablecer gravedad", ["Reset Window Position"] = "Restablecer posición",
            ["Reseta a gravidade para o valor padrão (196.2)"] = "Resets gravity to default (196.2)", ["Resgata códigos automaticamente."] = "Redeems codes automatically.",
            ["Royal Hub é um script feito para o Roblox, criado apenas por dois desenvolvedores e focado em entregar uma experiência completa e segura para os jogadores. Com uma variedade de funcionalidades, desde melhorias no personagem até opções de farm automatizado, o Royal Hub visa facilitar a jogabilidade e proporcionar vantagens estratégicas dentro do jogo. Desenvolvido com atenção à segurança, o script busca garantir que os usuários possam aproveitar suas funcionalidades sem comprometer a integridade de suas contas."] = "Royal Hub is a Roblox script built by two developers, focused on a complete and safe player experience. With features ranging from character upgrades to automated farming, Royal Hub makes gameplay easier and gives you a strategic edge. Developed with security in mind, so you can enjoy every feature without putting your account at risk.", ["Salvar Config"] = "Guardar config",
            ["Saved Configurations"] = "Configuraciones guardadas", ["Saved configuration"] = "Configuración guardada",
            ["Search"] = "Buscar", ["Search all pages"] = "Buscar en todas las páginas",
            ["Secure mode"] = "Modo seguro", ["Seleciona o item que deseja comprar automaticamente."] = "Selects the item to auto-buy.",
            ["Seleciona o material que deseja farmar automaticamente."] = "Selects the material to auto-farm.", ["Seleciona o player para spectate."] = "Selects the player to spectate.",
            ["Selecionar Ilha"] = "Seleccionar isla", ["Selecionar Item"] = "Seleccionar artículo",
            ["Selecionar Material"] = "Seleccionar material", ["Selecione Emote"] = "Seleccionar emote",
            ["Selecione Jogador (Fling)"] = "Seleccionar jugador (Fling)", ["Selecione o Player"] = "Seleccionar player",
            ["Selecione o jogador para copiar o visual."] = "Select the player to copy the look from.", ["Selecione um alvo primeiro!"] = "¡Selecciona un objetivo primero!",
            ["Selecione um alvo!"] = "¡Selecciona un objetivo!", ["Selecione um emote primeiro!"] = "¡Selecciona un emote primero!",
            ["Selecione uma ilha primeiro!"] = "¡Selecciona una isla primero!", ["Selecione..."] = "Seleccionar...",
            ["Server Hop"] = "Server Hop", ["Settings"] = "Ajustes",
            ["Show profile"] = "Mostrar perfil", ["Signed in as"] = "Sesión como",
            ["Silent Aim"] = "Silent Aim", ["Smooth do Aimbot"] = "Suavidad del aimbot",
            ["Sobre o Royal Hub"] = "Sobre Royal Hub", ["Spectate Player"] = "Espectar jugador",
            ["Speed"] = "Speed", ["Speed Lock"] = "Speed Lock",
            ["Spin"] = "Spin", ["Spin (G)"] = "Spin (G)",
            ["SpyChat"] = "SpyChat", ["Tamanho da Hitbox"] = "Tamaño de hitbox",
            ["Tamanho do FOV"] = "Tamaño del FOV", ["Tecla de Parry"] = "Tecla de parry",
            ["Tecla que o jogo usa para parry."] = "Key the game uses for parry.", ["Teleport"] = "Teleport",
            ["Teleport to Islands"] = "Teleport to Islands", ["Teleporta até o jogador selecionado"] = "Teleports to the selected player",
            ["Teleporta infinitamente no jogador que foi selecionado acima."] = "Endlessly teleports to the player selected above.", ["Teleportar até jogador"] = "Teletransportar al jugador",
            ["Teleportar para Ilha"] = "Teletransportar a isla", ["Teleporte"] = "Teletransporte",
            ["Tema do Hub"] = "Tema del hub", ["Temas"] = "Temas",
            ["Tempo (s) entre morrer e nascer."] = "Time (s) between death and respawn.", ["Tempo em segundos entre cada teleporte (menor = mais rápido)"] = "Seconds between each teleport (lower = faster)",
            ["Tempo entre cliques (segundos)."] = "Time between clicks (seconds).", ["Tempo entre fakes (menor = mais rápido)"] = "Time between fakes (lower = faster)",
            ["Tenta burlar o sistema anti-cheat do jogo."] = "Tries to bypass the game's anti-cheat.", ["Testar WebHook"] = "Probar WebHook",
            ["Tocar Global"] = "Reproducir global", ["Todas as funções serão desligadas e as alterações revertidas. Esta ação não pode ser desfeita."] = "Todas las funciones se apagarán y los cambios se revertirán. Esta acción no se puede deshacer.",
            ["Toggle Keybind"] = "Tecla del menú", ["Torna o personagem invisível localmente."] = "Makes your character locally invisible.",
            ["Torna os personagens inimigos em ForceField para fácil visualização."] = "Turns enemies into ForceField for easy spotting.", ["Trigger Bot"] = "Trigger Bot",
            ["Trigger Bot Delay"] = "Delay del Trigger Bot", ["UI carregada com sucesso!"] = "¡UI cargada con éxito!",
            ["URL do WebHook"] = "URL del WebHook", ["URL salva!"] = "¡URL guardada!",
            ["Universais"] = "Universal", ["Usar Emote"] = "Usar emote",
            ["Use após trocar de sea."] = "Use after switching seas.", ["Utilidades"] = "Utilidades",
            ["Various"] = "Varios", ["Velocidade Rotação"] = "Velocidad de rotación",
            ["Velocidade de rotação do fling spin."] = "Fling spin rotation speed.", ["Velocidade do Fly"] = "Velocidad del vuelo",
            ["Visual"] = "Visual", ["Volume"] = "Volumen",
            ["Wall Check (Ignorar Paredes)"] = "Wall Check (ignorar paredes)", ["WebHook"] = "WebHook",
            ["Welcome toast"] = "Toast de bienvenida", ["Xray"] = "Xray",
            ["Altera o idioma da interface na hora."] = "Cambia el idioma de la interfaz al instante.", ["Arremessado: "] = "Lanzado: ",
            ["Falha ao carregar "] = "Error al cargar ", ["Fling Player"] = "Fling Player",
            ["Fling Power"] = "Fling Power", ["Idioma"] = "Idioma",
            ["Teleportado para "] = "Teletransportado a ",
            ["O modo anonymous (esconder nome e avatar) agora fica na aba Settings nativa do Rayfield: opção \"Show profile\". Lá também ficam a tecla de abrir/fechar o menu (Toggle Keybind) e as configurações salvas (Configurations)."] = "El modo anónimo (ocultar nombre y avatar) ahora está en la pestaña nativa de Settings de Rayfield: la opción \"Show profile\". Allí también están la tecla del menú (Toggle Keybind) y las configuraciones guardadas (Configurations).",
            ["Royal Hub"] = "Royal Hub",
            ["ESP Box"] = "ESP Box",
            ["Caixa de cantos ao redor do jogador (estilo corner box)."] = "Caja de esquinas alrededor del jugador.",
            ["Barra de vida à esquerda do box (verde -> amarelo -> vermelho)."] = "Barra de vida a la izquierda (verde -> amarillo -> rojo).",
            ["Nome acima e distância embaixo do jogador."] = "Nombre arriba, distancia abajo.",
            ["Box Cor"] = "Box Color",
            ["Info Cor (Nome)"] = "Info Color (Nombre)",
            ["ESP Health Bar"] = "ESP Health Bar",
            ["ESP Info"] = "ESP Info",
            ["Minimap"] = "Minimapa",
            ["Radar 2D no canto da tela: você no centro, seta = visão da câmera."] = "Radar 2D: tú en el centro, flecha = visión de cámara.",
            ["Minimap Alcance"] = "Alcance del Minimapa",
            ["Raio de detecção em studs."] = "Radio de detección en studs.",
            ["Minimap Nomes"] = "Nombres en Minimapa",
            ["Mostra o nome acima de cada blip."] = "Muestra el nombre sobre cada blip.",
            ["Minimap Cores de Time"] = "Colores de Equipo",
            ["Aliados azuis, inimigos vermelhos."] = "Aliados azules, enemigos rojos.",
        },
    },
})


-- DEV CHECK: tab exclusiva quando um dev entra (username OU UserId)
local DEV_IDS = {
    ["dark_ziinn"]       = "DARK_ZIINN",
    ["s1wlkrx"]          = "Beakoo",
    ["thenoctisblack78"] = "Stelle",
}
local function getDevName()
    local lname = string.lower(LP.Name or "")
    if DEV_IDS[lname] then return DEV_IDS[lname] end
    if DEV_IDS[LP.UserId] then return DEV_IDS[LP.UserId] end
    return nil
end
local IS_DEV = getDevName()

-- Adapter de notify: o Functions.lua usa notify() estilo WindUI
-- (getUI() -> _G.RH_WindUI or _G.RH_UI2). Sem isso TODOS os notifies do
-- Functions eram silenciosos (join/leave, anti-void, etc).
_G.RH_UI2 = {
    Notify = function(props)
        if not Window or Window.unloaded then return end
        pcall(function()
            Window:Notify({
                title    = props and props.Title or "Royal Hub",
                content  = props and props.Content or "",
                duration = props and props.Duration or 3,
            })
        end)
    end,
}

-- Snapshot do tema ativo no boot: restaura as cores quando o RGB é desligado
local LastAppliedTheme = {
    WindowColor     = Window.theme.WindowColor,
    AccentColor     = Window.theme.AccentColor,
    ElementGradient = Window.theme.ElementGradient,
    ElementStroke   = Window.theme.ElementStroke,
}

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



-- forward declare: dropdown de temas usa StopRGBThemes (definido no bloco RGB)
local StopRGBThemes

--============================================================================--
--  TABS - organização nova (12 tabs em 4 grupos no rail)
--  [Combat]      Aimbot & Combat | Visual
--  [Personagem]  Personagem | Farm | Loja | Teleporte
--  [Utilidades]  Exploits | Fun | Utilidades
--  [Hub]         Personalização | Configurações | Info
--============================================================================--

Window:CreateSection({ name = "Combat" })
local TabHome       = Window:CreateTab({ name = "Aimbot & Combat", icon = ICON.crosshair })
local TabVisual     = Window:CreateTab({ name = "Visual",           icon = ICON.eye })

Window:CreateSection({ name = "Personagem" })
local TabPersonagem = Window:CreateTab({ name = "Personagem",       icon = ICON.user })
local TabFarm       = Window:CreateTab({ name = "Farm",             icon = ICON.plant })
local TabShopping   = Window:CreateTab({ name = "Loja",             icon = ICON.cart })
local TabTeleport   = Window:CreateTab({ name = "Teleporte",        icon = ICON.map })

Window:CreateSection({ name = "Utilidades" })
local TabExploits   = Window:CreateTab({ name = "Exploits",         icon = ICON.bolt })
local TabMisc       = Window:CreateTab({ name = "Fun",             icon = ICON.dice })
local TabUtility    = Window:CreateTab({ name = "Utilidades",      icon = ICON.tools })

Window:CreateSection({ name = "Hub" })
if IS_DEV then
    Window:CreateSection({ name = "DEV — " .. (getDevName() or "?") })
end
local TabThemes     = Window:CreateTab({ name = "Personalização",   icon = ICON.palette })
local TabSettings   = Window:CreateTab({ name = "Configurações",    icon = ICON.settings })
local TabInfo       = Window:CreateTab({ name = "Info",             icon = ICON.info })

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

-- (o círculo agora sincroniza com a janela: abre = mostra, fecha = esconde.
--  O toggle abaixo sobrescreve: OFF aqui = nunca mostra, mesmo com painel aberto)
TabHome:CreateToggle({
    name = "Mostrar Círculo",
    description = "Desenha o círculo de FOV na tela (precisa de Drawing API). Fica visível mesmo com o painel fechado.",
    value = false,
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
    name = "Aim Lock Indicator",
    description = "Mostra em quem o aimbot está travado (canto da tela).",
    flag = "AimLockIndicator",
    callback = function(state) G.toggleAimLockIndicator(state) end,
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
        if not option or option == "" then return end
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

--============================================================================--
--  TAB: VISUAL — ESPs primeiro, cores/ajustes junto de cada um, utilidades depois
--============================================================================--

TabVisual:CreateSection({ name = "ESP" })

TabVisual:CreateToggle({
    name = "ESP Bones",
    description = "Desenha o esqueleto dos inimigos (juntas conectadas, R6 e R15).",
    flag = "EspBones",
    callback = function(state) G.toggleEspBones(state) end,
})

TabVisual:CreateColorPicker({
    name = "Bones Cor",
    color = Color3.fromRGB(255, 255, 255),
    flag = "EspBonesColor",
    callback = function(color) G.setEspBonesColor(color) end,
})

TabVisual:CreateSlider({
    name = "Bones Espessura",
    range = { 1, 4 },
    increment = 1,
    value = 1,
    flag = "EspBonesWidth",
    callback = function(value) G.setEspBonesWidth(value) end,
})

TabVisual:CreateToggle({
    name = "Chams",
    description = "Inimigos com material ForceField colorido (atravessa paredes).",
    flag = "Chams",
    callback = function(state) G.toggleChams(state) end,
})

TabVisual:CreateColorPicker({
    name = "Chams Cor",
    color = Color3.fromRGB(0, 255, 170),
    flag = "ChamsColor",
    callback = function(color) G.ChamsColor = color end,
})

local ToggleESP = TabVisual:CreateToggle({
    name = "ESP",
    description = "Players ficam visíveis atrás de paredes e marcados.",
    flag = "ESP",
    callback = function(state) G.toggleESP(state) end,
})
-- ESP 2D (o que o Twilight prometia — nativo, separado)
TabVisual:CreateToggle({
    name = "ESP Box",
    description = "Caixa de cantos ao redor do jogador (estilo corner box).",
    flag = "EspBox",
    callback = function(state) G.toggleEspBox(state) end,
})

TabVisual:CreateColorPicker({
    name = "Box Cor",
    color = Color3.fromRGB(255, 255, 255),
    flag = "EspBoxColor",
    callback = function(color) G.setEspBoxColor(color) end,
})

TabVisual:CreateToggle({
    name = "ESP Health Bar",
    description = "Barra de vida à esquerda do box (verde -> amarelo -> vermelho).",
    flag = "EspHealth",
    callback = function(state) G.toggleEspHealth(state) end,
})

TabVisual:CreateToggle({
    name = "ESP Info",
    description = "Nome acima e distância embaixo do jogador.",
    flag = "EspInfo",
    callback = function(state) G.toggleEspInfo(state) end,
})

TabVisual:CreateColorPicker({
    name = "Info Cor (Nome)",
    color = Color3.fromRGB(255, 255, 255),
    flag = "EspInfoColor",
    callback = function(color) G.setEspInfoColor(color) end,
})



TabVisual:CreateToggle({
    name = "ESP — Linhas",
    description = "Desenha linhas do centro da tela até cada inimigo (usa Drawing API).",
    flag = "ESPLines",
    callback = function(state) G.toggleEspLines(state) end,
})

TabVisual:CreateToggle({
    name = "ESP — Hitbox Visual",
    description = "Mostra caixas vermelhas ao redor da hitbox expandida (requer Hitbox Expander ativo).",
    flag = "HitboxESP",
    callback = function(state) G.toggleHitboxESP(state) end,
})
TabVisual:CreateToggle({
    name = "Highlight no Alvo",
    description = "Highlight no jogador selecionado em 'Selecione o Player' (seção Câmera & Crosshair).",
    flag = "TargetHighlight",
    callback = function(state) G.toggleTargetHighlight(state) end,
})

TabVisual:CreateColorPicker({
    name = "Highlight Cor",
    color = Color3.fromRGB(255, 80, 80),
    flag = "TargetHighlightColor",
    callback = function(color) G.setTargetHighlightColor(color) end,
})

TabVisual:CreateSection({ name = "Câmera & Crosshair" })

local SpectateDropdown = TabVisual:CreateDropdown({
    name = "Selecione o Player",
    description = "Seleciona o player para spectate.",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "SpectateTarget",
    callback = function(option)
        if not option or option == "" then return end -- autoLoad com player que saiu = nil
        SelectedPlayerToView = Players:FindFirstChild(option)
        G.SpectateTargetName = option
        -- se o highlight já estiver ligado, re-aplica no novo alvo
        if G.TargetHighlightEnabled then
            G.toggleTargetHighlight(false)
            G.toggleTargetHighlight(true)
        end
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

TabVisual:CreateSection({ name = "Mundo" })

TabVisual:CreateToggle({
    name = "Minimap",
    description = "Radar fixo no canto inferior direito: você é a flecha no centro, blips nos lugares reais.",
    flag = "Radar",
    callback = function(state) G.toggleRadar(state) end,
})

TabVisual:CreateSlider({
    name = "Minimap Alcance",
    description = "Raio de detecção em studs.",
    range = { 50, 1000 },
    increment = 25,
    value = 150,
    flag = "RadarRange",
    callback = function(value) G.setRadarRange(value) end,
})

TabVisual:CreateToggle({
    name = "Minimap Nomes",
    description = "Mostra o nome acima de cada blip.",
    value = true,
    flag = "RadarShowNames",
    callback = function(state) G.RadarShowNames = state end,
})

TabVisual:CreateToggle({
    name = "Minimap Cores de Time",
    description = "Aliados azuis, inimigos vermelhos.",
    value = true,
    flag = "RadarShowTeam",
    callback = function(state) G.RadarShowTeam = state end,
})

TabVisual:CreateToggle({
    name = "NoClip",
    description = "Permite atravessar paredes e objetos.",
    flag = "NoClip",
    callback = function(state) G.toggleNoClip(state) end,
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
    name = "Anti-Void",
    description = "Caiu do mapa? Volta sozinho pra última posição no chão.",
    flag = "AntiVoid",
    callback = function(state) G.toggleAntiVoid(state) end,
})

TabPersonagem:CreateSlider({
    name = "Anti-Void Y",
    description = "Altura que conta como void (padrão -50).",
    range = { -500, -10 },
    increment = 10,
    value = -50,
    flag = "AntiVoidY",
    callback = function(value) G.setAntiVoidY(value) end,
})

TabPersonagem:CreateToggle({
    name = "FPS Booster",
    description = "Remove texturas, partículas e sombras (com restore total).",
    flag = "FpsBoost",
    callback = function(state) G.toggleFpsBoost(state) end,
})

TabPersonagem:CreateToggle({
    name = "Sprint (LeftShift)",
    description = "Segure LeftShift para correr com velocidade turbo.",
    flag = "Sprint",
    callback = function(state) G.toggleSprint(state) end,
})

TabPersonagem:CreateSlider({
    name = "Velocidade do Sprint",
    range = { 25, 200 },
    increment = 1,
    value = 32,
    flag = "SprintSpeed",
    callback = function(value) G.setSprintSpeed(value) end,
})

TabPersonagem:CreateToggle({
    name = "Third Person",
    description = "Trava a câmera em 3ª pessoa com distância fixa.",
    flag = "ThirdPerson",
    callback = function(state) G.toggleThirdPerson(state) end,
})

TabPersonagem:CreateSlider({
    name = "Distância da Câmera",
    range = { 4, 30 },
    increment = 1,
    value = 12,
    flag = "ThirdPersonOffset",
    callback = function(value) G.setThirdPersonOffset(value) end,
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

-- seleciona o alvo (NÃO teleporta na hora)
local TPSelTarget = nil
local TPDropdown = TabTeleport:CreateDropdown({
    name = "Selecione o Jogador",
    description = "Escolha o alvo do teleporte (não teleporta ao selecionar).",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "TPTarget",
    callback = function(option)
        if not option or option == "" then return end
        TPSelTarget = option
        G.LoopTPTarget = option -- loop TP e fling usam esse alvo
    end,
})

-- botão: AGORA teleporta
TabTeleport:CreateButton({
    name = "Teleportar até Jogador",
    description = "Teleporta até o jogador selecionado acima.",
    callback = function()
        if not TPSelTarget then
            Window:Notify({ title = "Teleporte", content = "Selecione um jogador primeiro!", duration = 3 })
            return
        end
        G.tpToPlayerName(TPSelTarget)
    end,
})

local ToggleLoopTP = TabTeleport:CreateToggle({
    name = "Loop TP",
    description = "Teleporta infinitamente no jogador que foi selecionado acima.",
    flag = "LoopTP",
    callback = function(state) G.toggleLoopTP(state) end,
})

-- ===== WAYPOINTS =====
TabTeleport:CreateSection({ name = "Waypoints" })
local WaypointDropdown = nil -- (forward: o botão de salvar usa Refresh antes da definição)

local waypointNameText = ""
TabTeleport:CreateInput({
    name = "Nome do Waypoint",
    placeholder = "ex: farm spot",
    flag = "WaypointName",
    callback = function(text) waypointNameText = text or "" end,
})

TabTeleport:CreateButton({
    name = "Salvar Posição Atual",
    description = "Salva onde você está com o nome digitado acima.",
    callback = function()
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local wpName = waypointNameText
        if not wpName or wpName == "" then
            Window:Notify({ title = "Waypoints", content = "Digite um nome primeiro!", duration = 3 })
            return
        end
        G.addWaypoint(wpName, root.Position)
        WaypointDropdown:Refresh(G.getWaypointNames())
        Window:Notify({ title = "Waypoints", content = "Salvo: " .. wpName, duration = 3 })
    end,
})

local waypointSel = nil
WaypointDropdown = TabTeleport:CreateDropdown({
    name = "Waypoints Salvos",
    options = G.getWaypointNames(),
    placeholder = "Selecione...",
    flag = "WaypointSel",
    callback = function(option)
        if not option or option == "" then return end
        waypointSel = option
    end,
})

TabTeleport:CreateButton({
    name = "TP até Waypoint",
    description = "Teleporta pro waypoint selecionado.",
    callback = function()
        if waypointSel and G.Waypoints[waypointSel] then
            G.tpToWaypoint(waypointSel)
        else
            Window:Notify({ title = "Waypoints", content = "Selecione um waypoint!", duration = 3 })
        end
    end,
})

TabTeleport:CreateButton({
    name = "Deletar Waypoint",
    callback = function()
        if waypointSel then
            G.removeWaypoint(waypointSel)
            waypointSel = nil
            WaypointDropdown:Refresh(G.getWaypointNames())
            Window:Notify({ title = "Waypoints", content = "Deletado!", duration = 3 })
        end
    end,
})

-- ===== TP ATRÁS DO ALVO =====
TabTeleport:CreateButton({
    name = "TP Atrás do Alvo",
    description = "Se posiciona atrás do jogador selecionado acima (setup de combo).",
    callback = function()
        if TPSelTarget then
            local ok = G.tpBehindTarget(TPSelTarget)
            if not ok then
                Window:Notify({ title = "Teleporte", content = "Jogador não encontrado!", duration = 3 })
            end
        else
            Window:Notify({ title = "Teleporte", content = "Selecione um jogador primeiro!", duration = 3 })
        end
    end,
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

TabMisc:CreateToggle({
    name = "Join/Leave Logger",
    description = "Avisa quando alguém entra ou sai do servidor.",
    flag = "JoinLeaveLog",
    callback = function(state) G.toggleJoinLeaveLog(state) end,
})

-- ===== CHAT SPAMMER =====
TabMisc:CreateSection({ name = "Chat Spammer" })

local SpamInput = TabMisc:CreateInput({
    name = "Mensagem",
    placeholder = "digite a mensagem...",
    flag = "SpamMessage",
    callback = function(text) G.setChatSpamMessage(text) end,
})

TabMisc:CreateSlider({
    name = "Delay do Spam",
    description = "Segundos entre mensagens (mínimo 0.4).",
    range = { 0.4, 5 },
    increment = 0.1,
    value = 1,
    flag = "SpamDelay",
    callback = function(value) G.setChatSpamDelay(value) end,
})

TabMisc:CreateToggle({
    name = "Ativar Spam",
    description = "Envia a mensagem no chat em loop.",
    flag = "ChatSpam",
    callback = function(state) G.toggleChatSpam(state) end,
})

local OrbitDropdown = TabMisc:CreateDropdown({
    name = "Orbit — Selecione Jogador",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "OrbitTarget",
    callback = function(option)
        if not option or option == "" then return end
        G.OrbitTarget = option
    end,
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
    callback = function(option)
        if not option or option == "" then return end
        SelectedEmote = option
    end,
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

-- Troll Audios (IDs públicos pós-2022 — funcionam de verdade)
local trollOptions = {}
for _, audio in ipairs(G.TrollAudios or {}) do
    table.insert(trollOptions, audio.Title)
end

local SelectedTrollAudio = nil
TabMisc:CreateDropdown({
    name = "IDs Troll Prontos",
    description = "20 audios clássicos (vine boom, crab rave, phonk...).",
    options = trollOptions,
    placeholder = "Selecione...",
    flag = "TrollAudio",
    callback = function(option)
        if not option or option == "" then return end
        for _, audio in ipairs(G.TrollAudios or {}) do
            if audio.Title == option then SelectedTrollAudio = audio.id end
        end
    end,
})

TabMisc:CreateSlider({
    name = "Troll Volume",
    range = { 1, 20 }, increment = 1, value = 5,
    flag = "TrollVolume",
    callback = function(value) G.TrollVolume = value end,
})

TabMisc:CreateButton({
    name = "Tocar Áudio (Só Você)",
    description = "Toca localmente — funciona em qualquer jogo.",
    callback = function()
        if SelectedTrollAudio then
            G.playTrollLocal(SelectedTrollAudio, G.TrollVolume)
        else
            Window:Notify({ title = "Audio", content = "Selecione um áudio primeiro!", duration = 3 })
        end
    end,
})

TabMisc:CreateButton({
    name = "Tocar na Boombox",
    description = "Toca no Sound da ferramenta equipada (precisa de boombox/radio).",
    callback = function()
        if SelectedTrollAudio then
            local ok = G.playTrollBoombox(SelectedTrollAudio, G.TrollVolume)
            if not ok then
                Window:Notify({ title = "Audio", content = "Nenhuma ferramenta com Sound equipada!", duration = 3 })
            end
        else
            Window:Notify({ title = "Audio", content = "Selecione um áudio primeiro!", duration = 3 })
        end
    end,
})

TabMisc:CreateButton({
    name = "Parar Áudio",
    callback = function() G.stopTrollAudio() end,
})

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
    callback = function(option)
        if not option or option == "" then return end
        CopyTargetPlayer = Players:FindFirstChild(option)
    end,
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

-- ===== Exploits Locais (novos) =====
TabExploits:CreateSection({ name = "Exploits Locais" })

TabExploits:CreateButton({
    name = "Bring All",
    description = "Teleporta todos os jogadores até você.",
    callback = function() G.bringAll() end,
})

TabExploits:CreateButton({
    name = "Fling All",
    description = "Arremessa todos os jogadores de uma vez.",
    callback = function() G.flingAll() end,
})

TabExploits:CreateSlider({
    name = "Fling All Power",
    range = { 1000, 50000 },
    increment = 500,
    value = 9000,
    flag = "FlingAllPower",
    callback = function(value) G.FlingAllPower = value end,
})

local ToggleBTools = TabExploits:CreateToggle({
    name = "BTools",
    description = "Ferramentas de construção (client-side): Delete, Clone, Grab.",
    flag = "BTools",
    callback = function(state) G.toggleBTools(state) end,
})

local ToggleMapInvis = TabExploits:CreateToggle({
    name = "Mapa Invisível",
    description = "Torna o mapa transparente (só pra você), com restore.",
    flag = "MapInvisible",
    callback = function(state) G.toggleMapInvisible(state) end,
})

TabExploits:CreateButton({
    name = "Reset Rápido",
    description = "Mata seu personagem na hora (respawn).",
    callback = function() G.quickReset() end,
})

TabExploits:CreateSection({ name = "Fling" })

local DropFlingTarget = TabExploits:CreateDropdown({
    name = "Selecione Jogador (Fling)",
    options = getPlayerNames(),
    placeholder = "Selecione...",
    flag = "FlingTarget",
    callback = function(option)
        if not option or option == "" then return end
        FlingTargetPlayer = Players:FindFirstChild(option)
    end,
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
    description = "Loga as mensagens do chat de todos os jogadores (console abaixo).",
    flag = "SpyChat",
    callback = function(state) G.toggleSpyChat(state) end,
})

local spyConsole = TabExploits:CreateConsole({
    name = "Chat Spy",
    height = 150,
    follow = true,
    maxLines = 300,
})

-- canal: o Functions chama esta função pra cada mensagem capturada
G.setSpyChatCallback(function(playerName, message)
    spyConsole:Append("[" .. playerName .. "]: " .. message)
end)

TabExploits:CreateButton({
    name = "Limpar Chat Spy",
    callback = function()
        G.clearSpyChatLog()
        spyConsole:Clear()
    end,
})

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
    callback = function(option)
        StopRGBThemes()
        LastAppliedTheme = Themes[option]
        Window:ChangeTheme(Themes[option])
    end,
})

TabThemes:CreateDropdown({
    name = "Idioma",
    description = "Auto = idioma do Roblox do jogador.",
    options = { "Auto (Roblox)", "pt-br", "en-us", "es" },
    value = "Auto (Roblox)",
    flag = "idioma_selecionado",
    callback = function(locale)
        if locale == "Auto (Roblox)" then
            -- mesmo mecanismo do auto-detect do boot (RobloxLocaleId)
            local ok, detected = pcall(function()
                return game:GetService("LocalizationService").RobloxLocaleId
            end)
            Window:SetLocale(ok and detected or "pt-br")
        else
            Window:SetLocale(locale)
        end
    end,
})

-- ===== RGB THEMES (aplica direto nos themeProperties, 30fps, sem tween) =====
local RGBThemeRunning = false
local RGBThemeGeneration = 0
local RGBThemeTargets = nil

StopRGBThemes = function()
    if not RGBThemeRunning then return end
    RGBThemeRunning = false
    RGBThemeGeneration += 1
    -- restaura o último tema aplicado (sem isso, elementos ficavam presos na última cor)
    Window:ChangeTheme(LastAppliedTheme)
end

local function BuildRGBThemeTargets()
    if RGBThemeTargets then return RGBThemeTargets end
    RGBThemeTargets = {}
    -- ChangeTheme() cria tween de 0.5s por propriedade; pro RGB aplicamos
    -- direto nos instances cacheados (rápido, sem sobreposição de tweens)
    local rgbKeys = {
        AccentColor = true,
        ElementGradient = true,
        ElementStroke = true,
        WindowColor = true,
    }
    for instance, properties in pairs(Window.themeProperties) do
        if instance and instance.Parent then
            for property, source in pairs(properties) do
                local key = if typeof(source) == "table" then source[1] else source
                if rgbKeys[key] then
                    table.insert(RGBThemeTargets, {
                        instance = instance,
                        property = property,
                        source = source,
                    })
                end
            end
        end
    end
    return RGBThemeTargets
end

local function ApplyRGBColor(color)
    local targets = BuildRGBThemeTargets()
    Window.theme.AccentColor = color
    Window.theme.ElementGradient = ColorSequence.new(color)
    Window.theme.ElementStroke = color
    local windowColor = if Window.hidden then ColorSequence.new(color) else ColorSequence.new(Color3.fromRGB(0, 0, 0))
    Window.theme.WindowColor = windowColor
    for i = #targets, 1, -1 do
        local target = targets[i]
        local instance = target.instance
        if not instance or not instance.Parent then
            table.remove(targets, i)
        else
            local source = target.source
            local key = if typeof(source) == "table" then source[1] else source
            local themeValue = Window.theme[key]
            local value = if typeof(source) == "table" then source[2](themeValue) else themeValue
            instance[target.property] = value
        end
    end
end

local function StartRGBTheme(brightness)
    StopRGBThemes()
    RGBThemeRunning = true
    RGBThemeGeneration += 1
    local generation = RGBThemeGeneration
    local hue = 0
    Window:ChangeTheme({
        WindowColor = Color3.fromRGB(0, 0, 0),
        ContentColor = Color3.fromRGB(230, 230, 230),
        AccentColor = Color3.fromHSV(hue, 1, brightness),
        ElementGradient = Color3.fromHSV(hue, 1, brightness),
        ElementStroke = Color3.fromHSV(hue, 1, brightness),
        LiveAnimation = false,
    })
    task.spawn(function()
        local UPDATE_INTERVAL = 1 / 30
        local HUE_SPEED = 0.12
        while RGBThemeRunning and RGBThemeGeneration == generation and not Window.unloaded do
            hue = (hue + HUE_SPEED * UPDATE_INTERVAL) % 1
            ApplyRGBColor(Color3.fromHSV(hue, 1, brightness))
            task.wait(UPDATE_INTERVAL)
        end
    end)
end

TabThemes:CreateSection({ name = "RGB Themes" })

TabThemes:CreateButton({
    name = "RGB Rainbow",
    description = "Ciclo RGB completo com brilho elevado.",
    callback = function() StartRGBTheme(0.85) end,
})

TabThemes:CreateButton({
    name = "RGB Dark Rainbow",
    description = "Ciclo RGB com brilho reduzido, estética escura.",
    callback = function() StartRGBTheme(0.45) end,
})

TabThemes:CreateButton({
    name = "Desativar RGB",
    description = "Interrompe o ciclo RGB e restaura o tema.",
    callback = function()
        StopRGBThemes()
        Window:Notify({
            title = "RGB Themes",
            content = "Ciclo RGB desativado.",
            duration = 2,
        })
    end,
})

-- ===== FONTS =====
local OriginalFont = Window.theme.Font
local OriginalTitleFont = Window.theme.TitleFont

local FontNames = {
    "Gotham", "GothamBold", "GothamBlack", "SourceSans", "SourceSansBold",
    "Code", "SciFi", "Arcade", "Fantasy", "Cartoon", "Antique", "Bangers",
    "Creepster", "FredokaOne", "JosefinSans", "Michroma", "Nunito", "Oswald",
    "Roboto", "RobotoMono", "SpecialElite", "Ubuntu",
}

local function GetAvailableFonts()
    local options = { "Original" }
    for _, fontName in ipairs(FontNames) do
        local ok, enumFont = pcall(function() return Enum.Font[fontName] end)
        if ok and enumFont then table.insert(options, fontName) end
    end
    return options
end

TabThemes:CreateSection({ name = "Fonts" })

TabThemes:CreateDropdown({
    name = "Fonte",
    description = "Altera a fonte global do RoyalHub (títulos e elementos).",
    options = GetAvailableFonts(),
    value = "Original",
    flag = "font_selecionada",
    callback = function(option)
        if option == "Original" then
            Window:ChangeTheme({ Font = OriginalFont, TitleFont = OriginalTitleFont })
            return
        end
        local okEnum, enumFont = pcall(function() return Enum.Font[option] end)
        if not okEnum or not enumFont then
            Window:Notify({
                title = "Fonts",
                content = "A fonte selecionada nao esta disponivel neste ambiente.",
                duration = 3,
            })
            return
        end
        local okFont, selectedFont = pcall(function() return Font.fromEnum(enumFont) end)
        if not okFont or not selectedFont then
            Window:Notify({
                title = "Fonts",
                content = "Nao foi possivel converter a fonte selecionada.",
                duration = 3,
            })
            return
        end
        Window:ChangeTheme({ Font = selectedFont, TitleFont = selectedFont })
    end,
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
                    if _G.RoyalHubUnload then
                        _G.RoyalHubUnload()  -- unloadAll + Window:Unload + limpa o lock
                    else
                        pcall(function() G.unloadAll() end)
                        Window:Unload()
                    end
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
--  TAB: DEV (só criada quando um dev é detectado)
--============================================================================--

if IS_DEV then
    local TabDev = Window:CreateTab({ name = "DEV " .. (getDevName() or ""), icon = ICON.crown })

    TabDev:CreateSection({ name = "Identidade" })

    TabDev:CreateText({
        name = "Modo DEV ativo",
        text = "Olá, " .. (getDevName() or "dev") .. ". Você tem acesso a funções de desenvolvimento do Royal Hub.",
    })

    TabDev:CreateSection({ name = "Ferramentas de Dev" })

    TabDev:CreateButton({
        name = "Recarregar Hub",
        description = "Re-executa o script inteiro (testes rápidos).",
        callback = function()
            G.unloadAll()
            Window:Unload()
            loadstring(game:HttpGet(REPO_URL))()
        end,
    })

    TabDev:CreateButton({
        name = "Limpar Caches",
        description = "Apaga os ícones salvos e recarrega (força re-download).",
        callback = function()
            pcall(function()
                for _, f in ipairs(listfiles(ICON_DIR)) do
                    delfile(f)
                end
            end)
            Window:Notify({ title = "DEV", content = "Caches limpos! Re-carregue o hub.", duration = 4 })
        end,
    })

    TabDev:CreateButton({
        name = "Ver Config Salva",
        description = "Printa a configuração salva no console (F9).",
        callback = function()
            for flag, value in pairs(Window.Flags) do
                print(("[RoyalHub] %s = %s"):format(flag, tostring(value)))
            end
            Window:Notify({ title = "DEV", content = "Flags printadas no console (F9).", duration = 3 })
        end,
    })

    TabDev:CreateToggle({
        name = "Persistente (Auto Re-Join)",
        description = "Hub re-executa sozinho ao trocar de servidor/mapa.",
        value = false,
        flag = "PersistentHub",
        callback = function(state)
            G.RoyalHubPersistent = state
            -- queue_on_teleport recebe CÓDIGO LUA, não URL: por isso não funcionava
            if state and queue_on_teleport then
                queue_on_teleport(([[
                    local ok = pcall(function()
                        loadstring(game:HttpGet("%s"))()
                    end)
                    if not ok then
                        warn("[RoyalHub] Falha ao re-executar após teleport")
                    end
                ]]):format(REPO_URL))
            end
        end,
    })

    TabDev:CreateSection({ name = "Info de Sessão" })

    TabDev:CreateText({
        name = "Sessão",
        text = "User: " .. LP.Name .. "  •  UserId: " .. LP.UserId ..
               "  •  PlaceId: " .. game.PlaceId ..
               "  •  JobId: " .. (game.JobId ~= "" and game.JobId:sub(1, 8) or "estúdio"),
    })
end

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

-- registra a instância ATUAL como a única viva
_G.RoyalHubLoaded = true
_G.RoyalHubUnload = function()
    pcall(function() G.unloadAll() end)
    pcall(function() Window:Unload() end)
    _G.RoyalHubLoaded = nil
    _G.RoyalHubUnload = nil
end

Window:Notify({
    title = "Royal Hub",
    content = "UI carregada com sucesso!",
    duration = 3,
})