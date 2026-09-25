local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


local Window = Fluent:CreateWindow({
    Title = "RoyalHub ",
    SubTitle = "By Eodraxkk & Einzbern",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

local Tabs = {
    TabInicio = Window:AddTab({ Title = "Inicio", Icon = "home" }),
    TabPersonagem = Window:AddTab({ Title = "Personagem", Icon = "user" }),
    TabFarm = Window:AddTab({ Title = "Farm", Icon = "feather" }),
    TabLoja = Window:AddTab({ Title = "Loja", Icon = "dollar-sign" }),
    TabTP = Window:AddTab({ Title = "TP", Icon = "navigation-2" }),
    TabMisc = Window:AddTab({ Title = "Misc", Icon = "flame" }),
    TabExploits = Window:AddTab({ Title = "Exploits", Icon = "code" }),
    TabConfig = Window:AddTab({ Title = "Config", Icon = "settings" }),
    TabInfo = Window:AddTab({ Title = "Info", Icon = "info" })
}

local toggleAimbotC = Tabs.TabInicio:AddToggle("AimbotC", {Title = "Aimbot comum", Default = false })
local toggleAimbotR = Tabs.TabInicio:AddToggle("AimbotR", {Title = "Aimbot Rage", Default = false })
local toggleIGALLY = Tabs.TabInicio:AddToggle("IgnorarTeam", {Title = "Ignorar Aliados", Default = false })
local toggleWallCheck = Tabs.TabInicio:AddToggle("WallCheck", {Title = "WallCheck", Default = false })

local sliderSmooth = Tabs.TabInicio:AddSlider("Slider", {
    Title = "Smooth",
    Description = "Suavização do aimbot",
    Default = 1000,
    Min = 0.0,
    Max = 1000,
    Rounding = 1
})

local toggleEsp = Tabs.TabInicio:AddToggle("Esp", {Title = "Esp", Default = false })
local toggleEspLines = Tabs.TabInicio:AddToggle("Esp lines", {Title = "Linhas do Esp", Default = false })
local toggleEspHitbox = Tabs.TabInicio:AddToggle("EspHitbox", {Title = "Esp Hitbox", Default = false })
local toggleFakeTp = Tabs.TabInicio:AddToggle("FakeTp", {Title = "Fake Tp", Default = false })

local sliderDelayFakeTp = Tabs.TabInicio:AddSlider("Slider", {
    Title = "Delay fake TP",
    Description = "Delay do fake TP",
    Default = 0.2,
    Min = 0.0,
    Max = 1,
    Rounding = 1
})

local sliderDFakeTP = Tabs.TabInicio:AddSlider("Slider", {
    Title = "Distancia fake TP",
    Description = "Distancia do fake TP",
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 1
})

local toggleSilentAim = Tabs.TabInicio:AddToggle("SilentAim", {Title = "Silent Aim", Default = false })

local Dropdown = Tabs.TabInicio:AddDropdown("Dropdown", {
    Title = "Parte do corpo",
    Values = {"Head", "Chest", "Stomach", "Legs", "Feet"},
    Multi = false,
    Default = nil,
})

local togglePrediction = Tabs.TabInicio:AddToggle("HPrediction", {Title = "Hit Prediction", Default = false })

local sliderFatorPrediction = Tabs.TabInicio:AddSlider("Slider", {
    Title = "Fator de predição",
    Description = "Fator de predição",
    Default = 1,
    Min = 0.1,
    Max = 3,
    Rounding = 1
})

local toggleHitboxExpander = Tabs.TabInicio:AddToggle("HitboxExpander", {Title = "Hitbox Expander", Default = false })

local sliderHitbox = Tabs.TabInicio:AddSlider("Slider", {
    Title = "Tamanho da hitbox",
    Description = "Tamanho da hitbox",
    Default = 8,
    Min = 1,
    Max = 30,
    Rounding = 1
})

local toggleAutoparry = Tabs.TabInicio:AddToggle("Autoparry", {Title = "Auto Parry", Default = false })

local dropdownTeclaParry = Tabs.TabInicio:AddDropdown("Dropdown", {
    Title = "Tecla Parry",
    Values = {"Q", "E", "F", "R", "LeftClick", "RightClick"},
    Multi = false,
    Default = nil,
})

local sliderDistanceParry = Tabs.TabInicio:AddSlider("Slider", {
    Title = "Distancia parry",
    Description = "Distancia parry",
    Default = 12,
    Min = 5,
    Max = 30,
    Rounding = 1
})


local dropdownViewPlayers = Tabs.TabInicio:AddDropdown("Dropdown", {
    Title = "Ver Jogadores",
    Values = {},
    Multi = false,
    Default = nil,
})

local toggleSpectate = Tabs.TabInicio:AddToggle("Spectate", {Title = "Spectate player", Default = false })


local toggleNoclip = Tabs.TabInicio:AddToggle("Noclip", {Title = "No clip", Default = false })


local toggleAntiragdoll = Tabs.TabPersonagem:AddToggle("Antiragdoll", {Title = "Anti Ragdoll", Default = false })

local toggleGod = Tabs.TabPersonagem:AddToggle("God", {Title = "God", Default = false })

local toggleInvis = Tabs.TabPersonagem:AddToggle("Invis", {Title = "Invis", Default = false })

local toggleInfJump = Tabs.TabPersonagem:AddToggle("InfJump", {Title = "Inf Jump", Default = false })

local toggleFullbright = Tabs.TabPersonagem:AddToggle("Fullbright", {Title = "Fullbright", Default = false })

local toggleXray = Tabs.TabPersonagem:AddToggle("Xray", {Title = "X-Ray", Default = false })

local toggleFreeze = Tabs.TabPersonagem:AddToggle("Freeze", {Title = "Freeze", Default = false })

local toggleHovername = Tabs.TabPersonagem:AddToggle("Hovername", {Title = "Hovername", Default = false })

local toggleHeadSize = Tabs.TabPersonagem:AddToggle("HeadSize", {Title = "Head Size", Default = false })

local toggleAntiAFK = Tabs.TabPersonagem:AddToggle("AntiAFK", {Title = "Anti AFK", Default = false })

local toggleFreecam = Tabs.TabPersonagem:AddToggle("Freecam", {Title = "Freecam", Default = false })

local toggleNoFog = Tabs.TabPersonagem:AddToggle("NoFog", {Title = "No Fog", Default = false })

local toggleReach = Tabs.TabPersonagem:AddToggle("Reach", {Title = "Reach", Default = false })

local toggleKillAura = Tabs.TabPersonagem:AddToggle("KillAura", {Title = "Kill Aura", Default = false })

local toggleClickTP = Tabs.TabPersonagem:AddToggle("ClickTP", {Title = "Click TP", Default = false })