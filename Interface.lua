--!optimize 2.0
-- PARTE 1: Interface GUI e Configurações

-- Verificar se o jogador está em um mapa permitido
local allowedPlaceIds = {17367230431, 3203685552}
local currentPlaceId = game.PlaceId
local placeAllowed = false

for _, id in ipairs(allowedPlaceIds) do
    if currentPlaceId == id then
        placeAllowed = true
        break
    end
end

if not placeAllowed then return end

-- Carregar Parte 2 (Lógica dos Puzzles)
local OmicronPuzzles = loadstring(game:HttpGet("https://raw.githubusercontent.com/seuusuario/scripts/main/omicron_puzzles.lua"))()

-- Serviços
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Teams = game:GetService("Teams"),
    CoreGui = game:GetService("CoreGui"),
    VirtualUser = game:GetService("VirtualUser"),
    TweenService = game:GetService("TweenService"),
    StarterGui = game:GetService("StarterGui")
}

local Player = Services.Players.LocalPlayer

-- Sistema de dimensionamento independente de DPI
local function GetDPIScale()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local scale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080)
    return math.max(scale * 1.26, 1.05)
end

local function Scale(value)
    return value * GetDPIScale()
end

-- Função para obter o local correto para a interface
local function getInterfaceParent()
    if gethui then
        return gethui()
    elseif syn and syn.protect_gui then
        local screenGui = Instance.new("ScreenGui")
        syn.protect_gui(screenGui)
        screenGui.Parent = Services.CoreGui
        return screenGui
    elseif Services.CoreGui:FindFirstChild("RobloxGui") then
        return Services.CoreGui:FindFirstChild("RobloxGui")
    else
        return Services.CoreGui
    end
end

-- Função para criar uma ScreenGui protegida
local function createProtectedScreenGui(name)
    local parent = getInterfaceParent()
    
    for _, existingGui in ipairs(parent:GetChildren()) do
        if existingGui:IsA("ScreenGui") and existingGui.Name == name then
            existingGui:Destroy()
        end
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name
    screenGui.DisplayOrder = 100
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.Parent = parent
    
    return screenGui
end

-- Sistema de salvamento de idioma
local config = {
    folder = "Omicron Hub",
    fileName = "omicron_bearalpha_language.txt",
    hasFileFunctions = (writefile ~= nil and readfile ~= nil and isfile ~= nil and makefolder ~= nil)
}
config.path = config.folder .. "/" .. config.fileName

local function ensureFolderExists()
    if config.hasFileFunctions and not isfile(config.folder) then
        pcall(makefolder, config.folder)
    end
end

local function saveLanguageConfig(language)
    if config.hasFileFunctions then
        ensureFolderExists()
        pcall(writefile, config.path, language)
    end
end

local function loadLanguageConfig()
    if config.hasFileFunctions then
        if isfile(config.path) then
            local success, data = pcall(readfile, config.path)
            if success then return data end
        end
        
        if isfile(config.fileName) then
            local success, data = pcall(readfile, config.fileName)
            if success then
                saveLanguageConfig(data)
                pcall(delfile, config.fileName)
                return data
            end
        end
        
        local oldConfigFile = "omicron_hub_language.txt"
        if isfile(oldConfigFile) then
            local success, data = pcall(readfile, oldConfigFile)
            if success then
                saveLanguageConfig(data)
                pcall(delfile, oldConfigFile)
                return data
            end
        end
    end
    return nil
end

-- Sistema de idiomas
local translations = {
    english = {
        credits = "Credits", puzzle = "Puzzle", status = "Status", language = "Language",
        omicronHub = "OMICRON HUB", creditsText = "Credits:\n\nDeveloped by Omicron",
        joinDiscord = "Join Discord Server", enablePuzzle = "Auto Wire Puzzle:",
        enableColorCode = "Auto Color Code Puzzle:", enableVHSMemory = "Auto Memory TV Puzzle:",
        enableCheeseAltar = "Auto Cheese Altar:", notificationTitle = "OMICRON HUB",
        notificationText = "Made by Omicron", notificationButton = "Thanks",
        englishBtn = "English", portugueseBtn = "Portuguese", selectLanguage = "Select Language:",
        discordCopied = "Discord link copied to clipboard!", languageChanged = "Language changed to English"
    },
    portuguese = {
        credits = "Créditos", puzzle = "Puzzle", status = "Status", language = "Idioma",
        omicronHub = "OMICRON HUB", creditsText = "Créditos:\n\nDesenvolvido por Omicron",
        joinDiscord = "Entrar no servidor do Discord", enablePuzzle = "Auto Wire Puzzle:",
        enableColorCode = "Auto Color Code Puzzle:", enableVHSMemory = "Auto Memory TV Puzzle:",
        enableCheeseAltar = "Auto Cheese Altar:", notificationTitle = "OMICRON HUB",
        notificationText = "Feito por Omicron", notificationButton = "Obrigado",
        englishBtn = "Inglês", portugueseBtn = "Português", selectLanguage = "Selecionar Idioma:",
        discordCopied = "Link do Discord copiado para a área de transferência!", languageChanged = "Idioma alterado para Português"
    }
}

local currentLanguage = "english"
local savedLanguage = loadLanguageConfig()
if savedLanguage and (savedLanguage == "english" or savedLanguage == "portuguese") then
    currentLanguage = savedLanguage
end

-- Função para gerar nomes aleatórios
local function generateRandomName()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local randomString = ""
    for i = 1, 10 do
        randomString = randomString .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
    end
    return randomString
end

-- Gerar nomes aleatórios
local randomNames = {}
local elementNames = {
    "screenGui", "mainFrame", "frameAura", "frameAura2", "frameAura3", "titleLabel", 
    "gameNameLabel", "minimizeButton", "closeButton", "tabContainer", "contentContainer",
    "creditosFrame", "creditosLabel", "discordButton", "puzzleFrame", "toggleContainer",
    "toggleLabel", "toggleSwitch", "toggleKnob", "toggleButton", "colorCodeToggleContainer",
    "colorCodeToggleLabel", "colorCodeToggleSwitch", "colorCodeToggleKnob", "colorCodeToggleButton",
    "vhsMemoryToggleContainer", "vhsMemoryToggleLabel", "vhsMemoryToggleSwitch", "vhsMemoryToggleKnob",
    "vhsMemoryToggleButton", "cheeseAltarToggleContainer", "cheeseAltarToggleLabel", 
    "cheeseAltarToggleSwitch", "cheeseAltarToggleKnob", "cheeseAltarToggleButton",
    "statusFrame", "languageFrame", "languageLabel", "englishButton", "portugueseButton",
    "restoreButton", "restoreAura", "restoreImage"
}

for _, name in ipairs(elementNames) do
    randomNames[name] = generateRandomName()
end

-- Criar a interface
local ScreenGui = createProtectedScreenGui(randomNames.screenGui)

-- Tamanhos e posições dimensionáveis
local FRAME_WIDTH = Scale(370)
local FRAME_HEIGHT = Scale(336)
local FRAME_X = Scale(126)
local FRAME_Y = Scale(6)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = randomNames.mainFrame
MainFrame.Size = UDim2.new(0, FRAME_WIDTH, 0, FRAME_HEIGHT)
MainFrame.Position = UDim2.new(0, FRAME_X, 0, FRAME_Y)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, Scale(8))

-- Auras
local auras = {}
for i = 1, 3 do
    local aura = Instance.new("Frame", ScreenGui)
    aura.Name = randomNames["frameAura" .. (i == 1 and "" or tostring(i))]
    local size = i * 8
    aura.Size = UDim2.new(0, FRAME_WIDTH + Scale(size), 0, FRAME_HEIGHT + Scale(size))
    aura.Position = UDim2.new(0, FRAME_X - Scale(size/2), 0, FRAME_Y - Scale(size/2))
    aura.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    aura.BackgroundTransparency = 0.3 + (i-1)*0.2
    aura.BorderSizePixel = 0
    aura.ZIndex = -i
    Instance.new("UICorner", aura).CornerRadius = UDim.new(0, Scale(8 + i*2))
    auras[i] = aura
end

-- Efeito de brilho pulsante
local function createStrongGlowEffect(frame, intensity)
    local pulseInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0)
    local glowOut = Services.TweenService:Create(frame, pulseInfo, {BackgroundTransparency = intensity + 0.2})
    glowOut:Play()
end

for i, aura in ipairs(auras) do
    task.spawn(function()
        task.wait((i-1)*0.3)
        createStrongGlowEffect(aura, 0.3 + (i-1)*0.2)
    end)
end

-- Brilho interno
local innerGlow = Instance.new("Frame", MainFrame)
innerGlow.Size = UDim2.new(1, 0, 1, 0)
innerGlow.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
innerGlow.BackgroundTransparency = 0.95
innerGlow.BorderSizePixel = 0
innerGlow.ZIndex = -1
Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, Scale(8))

local minimized = false

-- Título
local Title = Instance.new("TextLabel", MainFrame)
Title.Name = randomNames.titleLabel
Title.Size = UDim2.new(1, -Scale(68), 0, Scale(23))
Title.Position = UDim2.new(0, Scale(8), 0, Scale(8))
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = Scale(19)
Title.Text = translations[currentLanguage].omicronHub
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Nome do jogo
local GameNameLabel = Instance.new("TextLabel", MainFrame)
GameNameLabel.Name = randomNames.gameNameLabel
GameNameLabel.Size = UDim2.new(0, Scale(92), 0, Scale(13))
GameNameLabel.Position = UDim2.new(1, -230, 0, Scale(17))
GameNameLabel.BackgroundTransparency = 1
GameNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
GameNameLabel.TextTransparency = 0.8
GameNameLabel.Font = Enum.Font.GothamBold
GameNameLabel.TextSize = Scale(11)
GameNameLabel.Text = "BEAR (Alpha)"
GameNameLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Botões de controle
local controlButtons = {}
local buttonData = {
    {name = "minimizeButton", text = "-", xOffset = -50},
    {name = "closeButton", text = "X", xOffset = -25}
}

for _, btn in ipairs(buttonData) do
    local button = Instance.new("TextButton", MainFrame)
    button.Name = randomNames[btn.name]
    button.Size = UDim2.new(0, Scale(19), 0, Scale(19))
    button.Position = UDim2.new(1, Scale(btn.xOffset), 0, Scale(8))
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = Scale(13)
    button.Text = btn.text
    button.AutoButtonColor = false
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, Scale(4))
    controlButtons[btn.name] = button
end

-- Sistema de abas
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Name = randomNames.tabContainer
TabContainer.Size = UDim2.new(0, Scale(67), 1, -Scale(34))
TabContainer.Position = UDim2.new(0, 0, 0, Scale(34))
TabContainer.BackgroundTransparency = 1

local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Name = randomNames.contentContainer
ContentContainer.Size = UDim2.new(1, -Scale(67), 1, -Scale(34))
ContentContainer.Position = UDim2.new(0, Scale(67), 0, Scale(34))
ContentContainer.BackgroundTransparency = 1

local tabButtons, contentFrames = {}, {}
local currentTab = "creditos"

local function switchTab(tabName)
    for _, contentFrame in pairs(contentFrames) do
        if contentFrame then contentFrame.Visible = false end
    end
    
    if contentFrames[tabName] then
        contentFrames[tabName].Visible = true
    end
    
    for content, tabButton in pairs(tabButtons) do
        if tabButton then
            if content == tabName then
                tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                
                local highlight = tabButton:FindFirstChild("TabHighlight")
                if not highlight then
                    highlight = Instance.new("Frame", tabButton)
                    highlight.Name = "TabHighlight"
                    highlight.Size = UDim2.new(0, Scale(3), 1, -Scale(8))
                    highlight.Position = UDim2.new(1, -Scale(3), 0, Scale(4))
                    highlight.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
                    highlight.BorderSizePixel = 0
                    Instance.new("UICorner", highlight).CornerRadius = UDim.new(0, Scale(2))
                end
                highlight.Visible = true
            else
                tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                
                local highlight = tabButton:FindFirstChild("TabHighlight")
                if highlight then highlight.Visible = false end
            end
        end
    end
    
    currentTab = tabName
end

-- Criar abas
local tabs = {
    {name = translations[currentLanguage].credits, icon = "ℹ️", content = "creditos"},
    {name = translations[currentLanguage].puzzle, icon = "🧩", content = "puzzle"},
    {name = translations[currentLanguage].status, icon = "📊", content = "status"},
    {name = translations[currentLanguage].language, icon = "🌐", content = "language"}
}

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new("TextButton", TabContainer)
    tabButton.Size = UDim2.new(1, -Scale(8), 0, Scale(47))
    tabButton.Position = UDim2.new(0, Scale(4), 0, (i-1) * Scale(50))
    tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabButton.Text = tab.icon .. "\n" .. tab.name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.Font = Enum.Font.Gotham
    tabButton.TextSize = Scale(11)
    tabButton.TextWrapped = true
    tabButton.AutoButtonColor = false
    Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, Scale(6))
    
    tabButtons[tab.content] = tabButton
    
    tabButton.MouseButton1Click:Connect(function()
        switchTab(tab.content)
    end)
end

-- Função auxiliar para criar botões
local function createButton(parent, name, text, position, size)
    local button = Instance.new("TextButton", parent)
    button.Name = name
    button.Size = size or UDim2.new(0, Scale(126), 0, Scale(27))
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = Scale(13)
    button.Text = text
    button.AutoButtonColor = false
    
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, Scale(6))
    return button
end

-- ABA DE CRÉDITOS
local CreditosFrame = Instance.new("Frame", ContentContainer)
CreditosFrame.Name = randomNames.creditosFrame
CreditosFrame.Size = UDim2.new(1, 0, 1, 0)
CreditosFrame.BackgroundTransparency = 1
CreditosFrame.Visible = true
contentFrames.creditos = CreditosFrame

local CreditosLabel = Instance.new("TextLabel", CreditosFrame)
CreditosLabel.Name = randomNames.creditosLabel
CreditosLabel.Size = UDim2.new(1, -Scale(17), 0, Scale(50))
CreditosLabel.Position = UDim2.new(0, Scale(8), 0, Scale(8))
CreditosLabel.BackgroundTransparency = 1
CreditosLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CreditosLabel.Font = Enum.Font.Gotham
CreditosLabel.TextSize = Scale(13)
CreditosLabel.Text = translations[currentLanguage].creditsText
CreditosLabel.TextWrapped = true
CreditosLabel.TextYAlignment = Enum.TextYAlignment.Top

local DiscordButton = createButton(
    CreditosFrame,
    randomNames.discordButton,
    translations[currentLanguage].joinDiscord,
    UDim2.new(0, Scale(8), 0, Scale(67)),
    UDim2.new(1, -Scale(17), 0, Scale(27))
)

-- ABA DE PUZZLE
local PuzzleFrame = Instance.new("Frame", ContentContainer)
PuzzleFrame.Name = randomNames.puzzleFrame
PuzzleFrame.Size = UDim2.new(1, 0, 1, 0)
PuzzleFrame.BackgroundTransparency = 1
PuzzleFrame.Visible = false
contentFrames.puzzle = PuzzleFrame

-- Função para criar interruptores
local function createToggle(parent, config)
    local container = Instance.new("Frame", parent)
    container.Name = config.containerName
    container.Size = UDim2.new(1, -Scale(17), 0, Scale(34))
    container.Position = config.position
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Name = config.labelName
    label.Size = UDim2.new(0, Scale(150), 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = Scale(15)
    label.Text = config.labelText
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleSwitch = Instance.new("Frame", container)
    toggleSwitch.Name = config.switchName
    toggleSwitch.Size = UDim2.new(0, Scale(42), 0, Scale(21))
    toggleSwitch.Position = UDim2.new(1, -Scale(42), 0, Scale(6))
    toggleSwitch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleSwitch.BorderSizePixel = 0
    Instance.new("UICorner", toggleSwitch).CornerRadius = UDim.new(0, Scale(10))

    local toggleKnob = Instance.new("Frame", toggleSwitch)
    toggleKnob.Name = config.knobName
    toggleKnob.Size = UDim2.new(0, Scale(18), 0, Scale(18))
    toggleKnob.Position = UDim2.new(0, Scale(2), 0, Scale(1.5))
    toggleKnob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    toggleKnob.BorderSizePixel = 0
    Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(0, Scale(8))

    local toggleButton = Instance.new("TextButton", container)
    toggleButton.Name = config.buttonName
    toggleButton.Size = UDim2.new(0, Scale(42), 0, Scale(21))
    toggleButton.Position = UDim2.new(1, -Scale(42), 0, Scale(6))
    toggleButton.BackgroundTransparency = 1
    toggleButton.Text = ""
    toggleButton.AutoButtonColor = false

    return {
        container = container,
        label = label,
        switch = toggleSwitch,
        knob = toggleKnob,
        button = toggleButton
    }
end

-- Criar interruptores
local toggles = {
    puzzle = createToggle(PuzzleFrame, {
        containerName = randomNames.toggleContainer,
        labelName = randomNames.toggleLabel,
        switchName = randomNames.toggleSwitch,
        knobName = randomNames.toggleKnob,
        buttonName = randomNames.toggleButton,
        labelText = translations[currentLanguage].enablePuzzle,
        position = UDim2.new(0, Scale(8), 0, Scale(17))
    }),
    colorCode = createToggle(PuzzleFrame, {
        containerName = randomNames.colorCodeToggleContainer,
        labelName = randomNames.colorCodeToggleLabel,
        switchName = randomNames.colorCodeToggleSwitch,
        knobName = randomNames.colorCodeToggleKnob,
        buttonName = randomNames.colorCodeToggleButton,
        labelText = translations[currentLanguage].enableColorCode,
        position = UDim2.new(0, Scale(8), 0, Scale(67))
    }),
    vhsMemory = createToggle(PuzzleFrame, {
        containerName = randomNames.vhsMemoryToggleContainer,
        labelName = randomNames.vhsMemoryToggleLabel,
        switchName = randomNames.vhsMemoryToggleSwitch,
        knobName = randomNames.vhsMemoryToggleKnob,
        buttonName = randomNames.vhsMemoryToggleButton,
        labelText = translations[currentLanguage].enableVHSMemory,
        position = UDim2.new(0, Scale(8), 0, Scale(117))
    }),
    cheeseAltar = createToggle(PuzzleFrame, {
        containerName = randomNames.cheeseAltarToggleContainer,
        labelName = randomNames.cheeseAltarToggleLabel,
        switchName = randomNames.cheeseAltarToggleSwitch,
        knobName = randomNames.cheeseAltarToggleKnob,
        buttonName = randomNames.cheeseAltarToggleButton,
        labelText = translations[currentLanguage].enableCheeseAltar,
        position = UDim2.new(0, Scale(8), 0, Scale(167))
    })
}

-- ABA DE STATUS
local StatusFrame = Instance.new("Frame", ContentContainer)
StatusFrame.Name = randomNames.statusFrame
StatusFrame.Size = UDim2.new(1, 0, 1, 0)
StatusFrame.BackgroundTransparency = 1
StatusFrame.Visible = false
contentFrames.status = StatusFrame

-- ABA DE IDIOMA
local LanguageFrame = Instance.new("Frame", ContentContainer)
LanguageFrame.Name = randomNames.languageFrame
LanguageFrame.Size = UDim2.new(1, 0, 1, 0)
LanguageFrame.BackgroundTransparency = 1
LanguageFrame.Visible = false
contentFrames.language = LanguageFrame

local LanguageLabel = Instance.new("TextLabel", LanguageFrame)
LanguageLabel.Name = randomNames.languageLabel
LanguageLabel.Size = UDim2.new(1, -Scale(17), 0, Scale(25))
LanguageLabel.Position = UDim2.new(0, Scale(8), 0, Scale(17))
LanguageLabel.BackgroundTransparency = 1
LanguageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
LanguageLabel.Font = Enum.Font.Gotham
LanguageLabel.TextSize = Scale(15)
LanguageLabel.Text = translations[currentLanguage].selectLanguage
LanguageLabel.TextXAlignment = Enum.TextXAlignment.Left

local EnglishButton = createButton(
    LanguageFrame,
    randomNames.englishButton,
    "🇺🇸 " .. translations[currentLanguage].englishBtn,
    UDim2.new(0, Scale(8), 0, Scale(50)),
    UDim2.new(1, -Scale(17), 0, Scale(34))
)

local PortugueseButton = createButton(
    LanguageFrame,
    randomNames.portugueseButton,
    "🇧🇷 " .. translations[currentLanguage].portugueseBtn,
    UDim2.new(0, Scale(8), 0, Scale(92)),
    UDim2.new(1, -Scale(17), 0, Scale(34))
)

-- BOTÃO DE RESTAURAÇÃO
local RestoreButton = Instance.new("TextButton", ScreenGui)
RestoreButton.Name = randomNames.restoreButton
RestoreButton.Size = UDim2.new(0, Scale(34), 0, Scale(34))
RestoreButton.Position = UDim2.new(0, Scale(17), 0, Scale(17))
RestoreButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RestoreButton.Text = ""
RestoreButton.Visible = false
RestoreButton.AutoButtonColor = false
Instance.new("UICorner", RestoreButton).CornerRadius = UDim.new(0, Scale(8))

local RestoreAura = Instance.new("Frame", ScreenGui)
RestoreAura.Name = randomNames.restoreAura
RestoreAura.Size = UDim2.new(0, Scale(42), 0, Scale(42))
RestoreAura.Position = UDim2.new(0, Scale(13), 0, Scale(13))
RestoreAura.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
RestoreAura.BackgroundTransparency = 0.4
RestoreAura.BorderSizePixel = 0
RestoreAura.Visible = false
RestoreAura.ZIndex = -1
Instance.new("UICorner", RestoreAura).CornerRadius = UDim.new(0, Scale(10))

local RestoreImage = Instance.new("ImageLabel", RestoreButton)
RestoreImage.Name = randomNames.restoreImage
RestoreImage.Size = UDim2.new(1, 0, 1, 0)
RestoreImage.BackgroundTransparency = 1
RestoreImage.Image = "rbxassetid://100709507402385"
RestoreImage.ScaleType = Enum.ScaleType.Fit

-- Inicializar com a aba de Créditos
switchTab("creditos")

-- Função para atualizar interface com idioma
local function updateInterfaceLanguage()
    local lang = translations[currentLanguage]
    
    Title.Text = lang.omicronHub
    
    tabButtons.creditos.Text = "ℹ️\n" .. lang.credits
    tabButtons.puzzle.Text = "🧩\n" .. lang.puzzle
    tabButtons.status.Text = "📊\n" .. lang.status
    tabButtons.language.Text = "🌐\n" .. lang.language
    
    CreditosLabel.Text = lang.creditsText
    DiscordButton.Text = lang.joinDiscord
    
    toggles.puzzle.label.Text = lang.enablePuzzle
    toggles.colorCode.label.Text = lang.enableColorCode
    toggles.vhsMemory.label.Text = lang.enableVHSMemory
    toggles.cheeseAltar.label.Text = lang.enableCheeseAltar
    
    LanguageLabel.Text = lang.selectLanguage
    EnglishButton.Text = "🇺🇸 " .. lang.englishBtn
    PortugueseButton.Text = "🇧🇷 " .. lang.portugueseBtn
    
    if currentLanguage == "english" then
        EnglishButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        PortugueseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        EnglishButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        PortugueseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end

-- Função para mudar idioma
local function changeLanguage(lang)
    if currentLanguage == lang then return end
    currentLanguage = lang
    updateInterfaceLanguage()
    saveLanguageConfig(lang)
    
    Services.StarterGui:SetCore("SendNotification", {
        Title = "OMICRON HUB",
        Text = translations[currentLanguage].languageChanged,
        Icon = "rbxassetid://100709507402385",
        Duration = 3
    })
end

-- Função para configurar efeitos de botão
local function setupButtonEffects(button, clickFunction)
    local originalColor = button.BackgroundColor3
    
    button.MouseButton1Down:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end)
    
    button.MouseButton1Click:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        task.wait(0.1)
        button.BackgroundColor3 = originalColor
        if clickFunction then clickFunction() end
    end)
    
    button.MouseButton1Up:Connect(function()
        button.BackgroundColor3 = originalColor
    end)
    
    button.MouseEnter:Connect(function()
        local r = math.min(originalColor.R * 255 + 15, 255)
        local g = math.min(originalColor.G * 255 + 15, 255)
        local b = math.min(originalColor.B * 255 + 15, 255)
        button.BackgroundColor3 = Color3.fromRGB(r, g, b)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = originalColor
    end)
end

-- Configurar efeitos dos botões
setupButtonEffects(DiscordButton, function()
    setclipboard("https://discord.gg/SqpSyrZYsb")
    DiscordButton.Text = "Copied!"
    Services.StarterGui:SetCore("SendNotification", {
        Title = "OMICRON HUB",
        Text = translations[currentLanguage].discordCopied,
        Icon = "rbxassetid://100709507402385",
        Duration = 3
    })
    wait(1)
    DiscordButton.Text = translations[currentLanguage].joinDiscord
end)

setupButtonEffects(EnglishButton, function()
    changeLanguage("english")
end)

setupButtonEffects(PortugueseButton, function()
    changeLanguage("portuguese")
end)

-- Configurar botões de controle
local MinimizeButton = controlButtons.minimizeButton
local CloseButton = controlButtons.closeButton

MinimizeButton.MouseButton1Click:Connect(function()
    if not minimized then
        MainFrame.Visible = false
        for _, aura in ipairs(auras) do aura.Visible = false end
        RestoreButton.Visible = true
        RestoreAura.Visible = true
        minimized = true
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    OmicronPuzzles.stopAll()
    ScreenGui:Destroy()
end)

-- Configurar botão de restauração
RestoreButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    for _, aura in ipairs(auras) do aura.Visible = true end
    RestoreButton.Visible = false
    RestoreAura.Visible = false
    minimized = false
end)

-- Configurar arrastar pelo título
local dragging, dragStart, frameStart = false, Vector2.new(0, 0), UDim2.new(0, 0)
local function startDragging(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        frameStart = MainFrame.Position
    end
end

local function stopDragging(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end

local function updateDragging(input)
    if dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
        
        for i, aura in ipairs(auras) do
            aura.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X - Scale(i*4),
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y - Scale(i*4)
            )
        end
    end
end

Title.InputBegan:Connect(startDragging)
Title.InputEnded:Connect(stopDragging)
Title.InputChanged:Connect(updateDragging)

-- Configurar toggles para ativar/desativar puzzles
toggles.puzzle.button.MouseButton1Click:Connect(function()
    if OmicronPuzzles.isPuzzleSolverActive() then
        OmicronPuzzles.desativarPuzzleSolver()
        toggles.puzzle.switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggles.puzzle.knob.Position = UDim2.new(0, Scale(2), 0, Scale(1.5))
    else
        OmicronPuzzles.ativarPuzzleSolver()
        toggles.puzzle.switch.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        toggles.puzzle.knob.Position = UDim2.new(1, -Scale(20), 0, Scale(1.5))
    end
end)

toggles.colorCode.button.MouseButton1Click:Connect(function()
    if OmicronPuzzles.isColorCodeActive() then
        OmicronPuzzles.desativarColorCode()
        toggles.colorCode.switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggles.colorCode.knob.Position = UDim2.new(0, Scale(2), 0, Scale(1.5))
    else
        OmicronPuzzles.ativarColorCode()
        toggles.colorCode.switch.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        toggles.colorCode.knob.Position = UDim2.new(1, -Scale(20), 0, Scale(1.5))
    end
end)

toggles.vhsMemory.button.MouseButton1Click:Connect(function()
    if OmicronPuzzles.isVHSMemoryActive() then
        OmicronPuzzles.desativarVHSMemory()
        toggles.vhsMemory.switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggles.vhsMemory.knob.Position = UDim2.new(0, Scale(2), 0, Scale(1.5))
    else
        OmicronPuzzles.ativarVHSMemory()
        toggles.vhsMemory.switch.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        toggles.vhsMemory.knob.Position = UDim2.new(1, -Scale(20), 0, Scale(1.5))
    end
end)

toggles.cheeseAltar.button.MouseButton1Click:Connect(function()
    if OmicronPuzzles.isCheeseAltarActive() then
        OmicronPuzzles.desativarCheeseAltar()
        toggles.cheeseAltar.switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        toggles.cheeseAltar.knob.Position = UDim2.new(0, Scale(2), 0, Scale(1.5))
    else
        OmicronPuzzles.ativarCheeseAltar()
        toggles.cheeseAltar.switch.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        toggles.cheeseAltar.knob.Position = UDim2.new(1, -Scale(20), 0, Scale(1.5))
    end
end)

-- Sistema de redimensionamento dinâmico
local function updateUIScale()
    Title.TextSize = Scale(19)
    GameNameLabel.TextSize = Scale(11)
    MinimizeButton.TextSize = Scale(13)
    CloseButton.TextSize = Scale(13)
    CreditosLabel.TextSize = Scale(13)
    DiscordButton.TextSize = Scale(13)
    LanguageLabel.TextSize = Scale(15)
    EnglishButton.TextSize = Scale(13)
    PortugueseButton.TextSize = Scale(13)
    
    for _, toggle in pairs(toggles) do
        toggle.label.TextSize = Scale(15)
    end
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)

-- Mostrar notificação inicial
Services.StarterGui:SetCore("SendNotification", {
    Title = translations[currentLanguage].notificationTitle,
    Text = translations[currentLanguage].notificationText,
    Button1 = translations[currentLanguage].notificationButton,
    Icon = "rbxassetid://100709507402385",
    Duration = 5
})

-- Atualizar escala inicial
updateUIScale()