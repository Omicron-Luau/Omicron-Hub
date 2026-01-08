--!optimize 2.0
-- PARTE 2: Lógica dos Puzzles Omicron Hub

local function init()
    -- Serviços
    local Services = {
        Players = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        UserInputService = game:GetService("UserInputService"),
        Teams = game:GetService("Teams"),
        TweenService = game:GetService("TweenService"),
        StarterGui = game:GetService("StarterGui")
    }
    
    local Player = Services.Players.LocalPlayer
    
    -- Estado dos puzzles
    local puzzleState = {
        puzzleSolverActive = false,
        colorCodeActive = false,
        vhsMemoryActive = false,
        cheeseAltarActive = false,
        scriptStopped = false,
        connections = {}
    }
    
    -- Variáveis do Puzzle Solver
    local active = false
    local originalPosition = nil
    local teleporting = false
    local currentWireIndex = 1
    local wireModels = {}
    local isWaiting = false
    local hasSavedPosition = false
    local lastTeamCheck = nil
    local shouldWaitOnTeamChange = false
    local aguardandoWire = false
    local processoAtivado = false
    local modoSmoke = false
    local smokeLeaks = {}
    local currentSmokeIndex = 1
    
    -- Variáveis do ColorCode
    local colorCodeResolvendo = false
    local colorCodeOriginalPosition = nil
    local colorCodeLastTeamCheck = nil
    local colorCodeShouldWaitOnTeamChange = true
    local colorCodeHasSavedPosition = false
    local colorCodeEsperaIniciada = false
    local colorCodeTempoEsperaInicio = 0
    
    -- Variáveis do VHS Memory
    local vhsMemoryRunning = false
    local vhsMemorySequenceConnection = nil
    local vhsMemorySavedPosition = nil
    local vhsMemoryActiveVar = false
    local vhsMemoryLastTeamCheck = nil
    local vhsMemoryShouldWaitOnTeamChange = false
    local vhsMemoryHasSavedPosition = false
    local vhsMemoryEsperaIniciada = false
    local vhsMemoryTempoEsperaInicio = 0
    
    -- Variáveis do Cheese Altar
    local cheeseAltarRunning = false
    local cheeseAltarOriginalPosition = nil
    local cheeseAltarLastTeamCheck = nil
    local cheeseAltarShouldWaitOnTeamChange = false
    local cheeseAltarIsWaiting = false
    local cheeseAltarHasSavedPosition = false
    local cheeseAltarMonstaState = {
        stage = 0,
        waitUntil = 0,
        attempts = 0,
        maxAttempts = 20
    }
    
    -- CFrames para Monsta
    local monstaCFrame1 = CFrame.new(
        -30.2840576, 50.5820923, 1479.7002,
        0.609807372, 0.316245466, 0.726721346,
        -0.20332019, 0.948677421, -0.242223233,
        -0.76602608, -4.7557056e-05, 0.64280957
    )
    
    local monstaCFrame2 = CFrame.new(
        -94.3619995, 113.103539, 1409.61499,
        0.999371767, 8.81119711e-09, -0.0354406349,
        -8.80597462e-09, 1, 3.0343611e-10,
        0.0354406349, 8.84386227e-12, 0.999371767
    )
    
    -- FUNÇÕES DO PUZZLE SOLVER
    local function wireCompleto(wireModel)
        local wiresFolder = wireModel:FindFirstChild("Wires")
        if not wiresFolder or not wiresFolder:IsA("Folder") then
            return true
        end
        
        for _, part in ipairs(wiresFolder:GetChildren()) do
            if part:IsA("BasePart") and part:FindFirstChild("ClickDetector") then
                return false
            end
        end
        return true
    end
    
    local function completarWire(wireModel)
        local wiresFolder = wireModel:FindFirstChild("Wires")
        if not wiresFolder or not wiresFolder:IsA("Folder") then
            return
        end
        
        local clickDetectors = {}
        for _, part in ipairs(wiresFolder:GetChildren()) do
            if part:IsA("BasePart") then
                local click = part:FindFirstChild("ClickDetector")
                if click then table.insert(clickDetectors, click) end
            end
        end
        
        if #clickDetectors > 0 then
            for i = 1, 50 do
                for _, click in ipairs(clickDetectors) do
                    pcall(function() fireclickdetector(click) end)
                end
                task.wait(0.001)
            end
            
            local tentativas = 0
            while tentativas < 100 do
                local aindaTemClick = false
                for _, part in ipairs(wiresFolder:GetChildren()) do
                    if part:IsA("BasePart") and part:FindFirstChild("ClickDetector") then
                        aindaTemClick = true
                        local click = part:FindFirstChild("ClickDetector")
                        for j = 1, 20 do
                            pcall(function() fireclickdetector(click) end)
                        end
                    end
                end
                
                if not aindaTemClick then break end
                tentativas = tentativas + 1
                task.wait(0.01)
            end
        end
    end
    
    local function teleportarParaWire(wireModel)
        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        
        local posicaoAlvo
        local wiresFolder = wireModel:FindFirstChild("Wires")
        
        if wiresFolder then
            for _, part in ipairs(wiresFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    posicaoAlvo = part.Position + Vector3.new(0, 5, 0)
                    break
                end
            end
        end
        
        if not posicaoAlvo then
            posicaoAlvo = wireModel:GetBoundingBox().Position + Vector3.new(0, 5, 0)
        end
        
        Player.Character.HumanoidRootPart.CFrame = CFrame.new(posicaoAlvo)
        return true
    end
    
    local function encontrarWiresNaoCompletados()
        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return {} end
        
        local wiresNaoCompletados = {}
        for _, wireModel in ipairs(puzzleBin:GetChildren()) do
            if wireModel:IsA("Model") and wireModel.Name == "Wire" and not wireCompleto(wireModel) then
                table.insert(wiresNaoCompletados, wireModel)
            end
        end
        return wiresNaoCompletados
    end
    
    local function encontrarSmokeLeaks()
        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return false, {} end
        
        local smokeModel = puzzleBin:FindFirstChild("Smoke")
        if not smokeModel then return false, {} end
        
        local valvesFolder = smokeModel:FindFirstChild("Valves")
        if not valvesFolder then return false, {} end
        
        local leaks = {}
        for i = 1, 3 do
            local leakName = "SmokeLeak" .. i
            local leakModel = valvesFolder:FindFirstChild(leakName)
            if leakModel and leakModel:IsA("Model") then
                local clickDetector = leakModel:FindFirstChild("ClickDetector")
                if clickDetector then
                    table.insert(leaks, {
                        model = leakModel,
                        clickDetector = clickDetector,
                        nome = leakName
                    })
                end
            end
        end
        
        for _, child in ipairs(valvesFolder:GetChildren()) do
            if child:IsA("Model") and string.find(child.Name, "SmokeLeak") then
                local clickDetector = child:FindFirstChild("ClickDetector")
                if clickDetector then
                    table.insert(leaks, {
                        model = child,
                        clickDetector = clickDetector,
                        nome = child.Name
                    })
                end
            end
        end
        
        return #leaks > 0, leaks
    end
    
    local function smokeLeakExiste(leak)
        return leak and leak.model and leak.model.Parent and leak.model:FindFirstChild("ClickDetector") ~= nil
    end
    
    local function teleportarParaSmokeLeak(leak)
        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        
        if not smokeLeakExiste(leak) then return false end
        
        local primaryPart = leak.model.PrimaryPart
        if primaryPart then
            Player.Character.HumanoidRootPart.CFrame = primaryPart.CFrame + Vector3.new(0, 3, 0)
        else
            local primeiraPart
            for _, child in ipairs(leak.model:GetChildren()) do
                if child:IsA("BasePart") then
                    primeiraPart = child
                    break
                end
            end
            
            if primeiraPart then
                Player.Character.HumanoidRootPart.CFrame = primeiraPart.CFrame + Vector3.new(0, 3, 0)
            else
                local pos = leak.model:GetBoundingBox().Position
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
        end
        return true
    end
    
    local function ativarSmokeLeak(leak)
        if not smokeLeakExiste(leak) then return false end
        
        local clickDetector = leak.model:FindFirstChild("ClickDetector")
        if not clickDetector then return false end
        
        for i = 1, 100 do
            pcall(function() fireclickdetector(clickDetector) end)
            task.wait(0.001)
        end
        
        local tentativas = 0
        while smokeLeakExiste(leak) and tentativas < 50 do
            for i = 1, 50 do
                pcall(function() fireclickdetector(clickDetector) end)
                task.wait(0.001)
            end
            tentativas = tentativas + 1
        end
        return true
    end
    
    local function voltarParaPosicaoOriginal()
        if originalPosition and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                Player.Character.HumanoidRootPart.CFrame = originalPosition
            end)
            originalPosition = nil
            hasSavedPosition = false
        end
    end
    
    local function salvarPosicaoInicial()
        if not hasSavedPosition and processoAtivado then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                originalPosition = hrp.CFrame
                hasSavedPosition = true
            end
        end
    end
    
    local function iniciarProcesso()
        if not processoAtivado then
            processoAtivado = true
            wireModels = encontrarWiresNaoCompletados()
            
            if #wireModels > 0 then
                modoSmoke = false
                salvarPosicaoInicial()
                teleporting = true
                aguardandoWire = false
                currentWireIndex = 1
                return
            end
            
            local temSmoke, leaks = encontrarSmokeLeaks()
            if temSmoke then
                modoSmoke = true
                smokeLeaks = leaks
                currentSmokeIndex = 1
                salvarPosicaoInicial()
                teleporting = true
                aguardandoWire = false
                return
            end
            
            modoSmoke = false
            processoAtivado = false
            teleporting = false
            aguardandoWire = true
        end
    end
    
    -- FUNÇÕES DO COLORCODE
    local function colorCodePuzzleCompleto()
        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return true end
        local colorCode = puzzleBin:FindFirstChild("ColorCode")
        if not colorCode then return true end
        local buttons = colorCode:FindFirstChild("Buttons")
        if not buttons then return true end
        
        for i = 1, 4 do
            local buttonPart = buttons:FindFirstChild(tostring(i))
            if buttonPart and buttonPart:FindFirstChild("ClickDetector") then
                return false
            end
        end
        return true
    end
    
    local function obterAlvosColorCode()
        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return nil end
        local colorCode = puzzleBin:FindFirstChild("ColorCode")
        if not colorCode then return nil end
        local clue = colorCode:FindFirstChild("Clue")
        if not clue then return nil end
        local note = clue:FindFirstChild("Note")
        if not note or not note:IsA("SurfaceGui") then return nil end
        local frameClue = note:FindFirstChild("Frame")
        if not frameClue then return nil end
        
        local targets = {}
        for i = 1, 4 do
            local label = frameClue:FindFirstChild(tostring(i))
            if label and label:IsA("TextLabel") then
                targets[i] = label.Text
            else
                return nil
            end
        end
        return targets
    end
    
    local function obterBotoesAtivosColorCode()
        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return {} end
        local colorCode = puzzleBin:FindFirstChild("ColorCode")
        if not colorCode then return {} end
        local buttons = colorCode:FindFirstChild("Buttons")
        if not buttons then return {} end
        
        local dadosBotoes = {}
        for i = 1, 4 do
            local buttonPart = buttons:FindFirstChild(tostring(i))
            if buttonPart then
                local clickDetector = buttonPart:FindFirstChild("ClickDetector")
                local noteGui = buttonPart:FindFirstChild("Note")
                if clickDetector and clickDetector:IsA("ClickDetector") and noteGui and noteGui:IsA("SurfaceGui") then
                    local label = noteGui:FindFirstChild("Label")
                    if label and label:IsA("TextLabel") then
                        dadosBotoes[i] = {
                            detector = clickDetector,
                            label = label,
                            textoAtual = label.Text
                        }
                    end
                end
            end
        end
        return dadosBotoes
    end
    
    local colorSequence = {"R", "O", "Y", "G", "B", "Pi", "Pu", "Bl"}
    local function getColorIndex(color)
        for i, c in ipairs(colorSequence) do
            if c == color then return i end
        end
        return nil
    end
    
    local function corrigirBotaoColorCode(botaoIndex, botaoData, alvo)
        local textoAtual = botaoData.label.Text
        local targetText = alvo
        if textoAtual == targetText then return false end
        
        local currentIndex = getColorIndex(textoAtual)
        local targetIndex = getColorIndex(targetText)
        if not targetIndex then return false end
        
        local clicks = 0
        if textoAtual == "?" then
            clicks = targetIndex
        elseif currentIndex then
            if currentIndex <= targetIndex then
                clicks = targetIndex - currentIndex
            else
                clicks = (#colorSequence - currentIndex) + targetIndex
            end
        else
            return false
        end
        
        if clicks > 0 then
            for c = 1, clicks do
                pcall(function() fireclickdetector(botaoData.detector) end)
                wait(0.02)
            end
            return true
        end
        return false
    end
    
    local function salvarPosicaoOriginalColorCode()
        if not colorCodeHasSavedPosition then
            if colorCodePuzzleCompleto() then return end
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                colorCodeOriginalPosition = hrp.CFrame
                colorCodeHasSavedPosition = true
            end
        end
    end
    
    local function voltarParaPosicaoOriginalColorCode()
        if colorCodeOriginalPosition and colorCodeHasSavedPosition then
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = colorCodeOriginalPosition
                wait(0.3)
            end
        end
        colorCodeOriginalPosition = nil
        colorCodeHasSavedPosition = false
    end
    
    local function teleportarParaBotao3ColorCode()
        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return false end
        local colorCode = puzzleBin:FindFirstChild("ColorCode")
        if not colorCode then return false end
        local buttons = colorCode:FindFirstChild("Buttons")
        if not buttons then return false end
        local botao3 = buttons:FindFirstChild("3")
        if not botao3 then return false end
        
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.CFrame = botao3.CFrame + Vector3.new(0, 3, 0)
            wait(0.3)
            return true
        end
        return false
    end
    
    local function resolverColorCode()
        if colorCodeResolvendo then return end
        if colorCodePuzzleCompleto() then return end
        colorCodeResolvendo = true
        
        if not teleportarParaBotao3ColorCode() then
            colorCodeResolvendo = false
            return
        end
        
        local targets = obterAlvosColorCode()
        if not targets then
            colorCodeResolvendo = false
            return
        end
        
        local tentativas = 0
        local maxTentativas = 30
        
        while colorCodeResolvendo and tentativas < maxTentativas do
            if colorCodePuzzleCompleto() then break end
            local botoes = obterBotoesAtivosColorCode()
            if not botoes or not next(botoes) then break end
            
            local algumFoiCorrigido = false
            for i, data in pairs(botoes) do
                local textoAtual = data.label.Text
                local targetText = targets[i]
                if textoAtual ~= targetText then
                    if corrigirBotaoColorCode(i, data, targetText) then
                        algumFoiCorrigido = true
                    end
                end
            end
            
            if not algumFoiCorrigido then
                tentativas = tentativas + 1
            else
                tentativas = 0
            end
            wait(0.2)
        end
        
        if colorCodeHasSavedPosition then
            voltarParaPosicaoOriginalColorCode()
        end
        colorCodeResolvendo = false
    end
    
    local function gerenciarEsperaColorCode()
        if not puzzleState.colorCodeActive then return false end
        
        if Player.Team then
            if colorCodeLastTeamCheck ~= Player.Team.Name then
                local previousTeam = colorCodeLastTeamCheck
                colorCodeLastTeamCheck = Player.Team.Name
                
                if previousTeam == "Survivors" and Player.Team.Name ~= "Survivors" then
                    colorCodeOriginalPosition = nil
                    colorCodeHasSavedPosition = false
                    colorCodeResolvendo = false
                    colorCodeEsperaIniciada = false
                    colorCodeShouldWaitOnTeamChange = true
                end
                
                if Player.Team.Name == "Survivors" and colorCodeShouldWaitOnTeamChange then
                    if not colorCodeEsperaIniciada then
                        colorCodeEsperaIniciada = true
                        colorCodeTempoEsperaInicio = tick()
                    end
                end
            end
            
            if colorCodeEsperaIniciada and Player.Team.Name == "Survivors" then
                local tempoDecorrido = tick() - colorCodeTempoEsperaInicio
                local tempoRestante = 12 - tempoDecorrido
                if tempoRestante > 0 then return true end
                salvarPosicaoOriginalColorCode()
                colorCodeEsperaIniciada = false
                colorCodeShouldWaitOnTeamChange = false
            end
            
            if Player.Team.Name == "Survivors" and not colorCodeHasSavedPosition and not colorCodeEsperaIniciada then
                salvarPosicaoOriginalColorCode()
            end
        end
        return false
    end
    
    -- FUNÇÕES DO VHS MEMORY
    local function vhsMemoryFindObject(path)
        local parts = string.split(path, ".")
        local obj = workspace
        for _, part in ipairs(parts) do
            local found = obj:FindFirstChild(part)
            if not found then return nil end
            obj = found
        end
        return obj
    end
    
    local function isPlayerInSurvivors()
        local player = Player
        if player then
            local team = player.Team
            if team and team.Name == "Survivors" then
                return true
            end
        end
        return false
    end
    
    local function vhsMemoryIsPuzzleCompleted()
        local memoryModel = vhsMemoryFindObject("PuzzleBin")
        if not memoryModel then return false end
        memoryModel = memoryModel:FindFirstChild("Memory")
        if not memoryModel then return false end
        memoryModel = memoryModel:FindFirstChild("Memory")
        if not memoryModel then return false end
        local surfaceGui = memoryModel:FindFirstChild("SurfaceGui")
        if not surfaceGui then return false end
        local frame = surfaceGui:FindFirstChild("Frame")
        if not frame then return false end
        local symbol = frame:FindFirstChild("Symbol")
        if not symbol or (not symbol:IsA("ImageLabel") and not symbol:IsA("ImageButton")) then
            return false
        end
        return symbol.Image == "rbxassetid://7002944973"
    end
    
    local function vhsMemorySavePlayerPosition()
        if vhsMemoryIsPuzzleCompleted() then
            vhsMemorySavedPosition = nil
            vhsMemoryHasSavedPosition = false
            return false
        end
        
        local character = Player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            vhsMemorySavedPosition = character.HumanoidRootPart.CFrame
            vhsMemoryHasSavedPosition = true
            return true
        end
        vhsMemoryHasSavedPosition = false
        return false
    end
    
    local function vhsMemoryRestorePlayerPosition()
        if vhsMemorySavedPosition and vhsMemoryHasSavedPosition then
            local character = Player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = vhsMemorySavedPosition
                vhsMemorySavedPosition = nil
                vhsMemoryHasSavedPosition = false
                return true
            end
        end
        return false
    end
    
    local function vhsMemoryHasVHSInInventory()
        local backpack = Player:FindFirstChild("Backpack")
        if backpack and backpack:FindFirstChild("VHS_MEMORY") then return true end
        
        local character = Player.Character
        if character then
            for _, tool in pairs(character:GetChildren()) do
                if tool:IsA("Tool") and tool.Name == "VHS_MEMORY" then
                    return true
                end
            end
        end
        return false
    end
    
    local function vhsMemoryFindMemoryQuestionUI()
        local playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        local memoryQuestion = playerGui:FindFirstChild("MemoryQuestion")
        if memoryQuestion then
            local frame = memoryQuestion:FindFirstChild("Frame")
            if frame then
                local shape = frame:FindFirstChild("Shape")
                if shape then return frame, shape end
            end
        end
        return nil, nil
    end
    
    local function vhsMemoryIdentifyShape(shapeObject)
        if not shapeObject then return nil end
        local uiCorner = shapeObject:FindFirstChildOfClass("UICorner")
        if uiCorner and uiCorner.CornerRadius.Scale == 1 then return 1 end
        
        local rotation = shapeObject.Rotation
        if rotation == 45 or rotation == 135 or rotation == -45 or rotation == -135 then return 2 end
        if rotation == 0 or rotation == 90 or rotation == 180 or rotation == 270 then return 3 end
        
        local absRotation = math.abs(rotation % 360)
        if absRotation == 45 or absRotation == 135 or absRotation == 225 or absRotation == 315 then
            return 2
        else
            return 3
        end
    end
    
    local function vhsMemoryCaptureSequence(shape)
        local sequence = {}
        local capturedCount = 0
        local lastCaptureTime = 0
        
        if vhsMemorySequenceConnection then
            vhsMemorySequenceConnection:Disconnect()
        end
        
        vhsMemorySequenceConnection = shape:GetPropertyChangedSignal("Visible"):Connect(function()
            if shape.Visible then
                local currentTime = tick()
                task.wait(0.02)
                if currentTime - lastCaptureTime > 0.1 then
                    local shapeCode = vhsMemoryIdentifyShape(shape)
                    if shapeCode then
                        table.insert(sequence, shapeCode)
                        capturedCount = capturedCount + 1
                        lastCaptureTime = currentTime
                        if capturedCount >= 4 then
                            if vhsMemorySequenceConnection then
                                vhsMemorySequenceConnection:Disconnect()
                                vhsMemorySequenceConnection = nil
                            end
                        end
                    end
                end
            end
        end)
        
        local startTime = tick()
        while capturedCount < 4 and tick() - startTime < 8 and vhsMemoryRunning do
            task.wait(0.03)
        end
        
        if vhsMemorySequenceConnection then
            vhsMemorySequenceConnection:Disconnect()
            vhsMemorySequenceConnection = nil
        end
        
        return #sequence >= 4 and sequence or nil
    end
    
    local function vhsMemoryCollectVHS()
        local vhsModel = vhsMemoryFindObject("Map._Entities.VHS") or vhsMemoryFindObject("Map._Entities.VHSCollect")
        if not vhsModel then return false end
        
        local detectPart = vhsModel:FindFirstChild("Detect")
        if not detectPart then return false end
        
        local character = Player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = CFrame.new(detectPart.Position)
        end
        
        task.wait(0.5)
        if vhsMemoryHasVHSInInventory() then return true end
        
        local clickDetector = vhsModel:FindFirstChildWhichIsA("ClickDetector")
        if clickDetector then fireclickdetector(clickDetector) end
        task.wait(0.5)
        
        return vhsMemoryHasVHSInInventory()
    end
    
    local function vhsMemoryEquipVHS()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        
        if backpack and humanoid then
            local vhsItem = backpack:FindFirstChild("VHS_MEMORY")
            if vhsItem then
                humanoid:EquipTool(vhsItem)
                return true
            end
        end
        return false
    end
    
    local function vhsMemorySendSequenceToPuzzle(sequence)
        local puzzleBin = vhsMemoryFindObject("PuzzleBin")
        if not puzzleBin then return false end
        local memory = puzzleBin:FindFirstChild("Memory")
        if not memory then return false end
        local puzzleRequest = memory:FindFirstChild("PuzzleRequest")
        if not puzzleRequest then return false end
        
        while #sequence < 4 do table.insert(sequence, 3) end
        for i, value in ipairs(sequence) do
            if value < 1 or value > 3 then sequence[i] = math.clamp(value, 1, 3) end
        end
        
        puzzleRequest:FireServer("Code", sequence)
        local startTime = tick()
        local puzzleCompleted = false
        
        while tick() - startTime < 5 and not puzzleCompleted do
            if vhsMemoryIsPuzzleCompleted() then puzzleCompleted = true break end
            task.wait(0.3)
        end
        
        if puzzleCompleted then
            return true
        else
            return not vhsMemoryHasVHSInInventory()
        end
    end
    
    local function vhsMemoryMonitorMemoryQuestion()
        local startTime = tick()
        local foundUI = false
        local frame, shape
        
        while not foundUI and tick() - startTime < 10 and vhsMemoryRunning do
            frame, shape = vhsMemoryFindMemoryQuestionUI()
            if frame and shape then foundUI = true break end
            task.wait(0.05)
        end
        
        if foundUI and shape then
            local sequence = vhsMemoryCaptureSequence(shape)
            return vhsMemorySendSequenceToPuzzle(sequence or {3, 1, 2, 3})
        else
            return vhsMemorySendSequenceToPuzzle({3, 1, 2, 3})
        end
    end
    
    local function vhsMemoryMakeItemTouchDetect()
        local memoryModel = vhsMemoryFindObject("PuzzleBin")
        if not memoryModel then return false end
        memoryModel = memoryModel:FindFirstChild("Memory")
        if not memoryModel then return false end
        local detectPart = memoryModel:FindFirstChild("Detect")
        if not detectPart then return false end
        
        local character = Player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local lookAtCFrame = CFrame.new(detectPart.Position + Vector3.new(0, 0, -2), detectPart.Position)
            character.HumanoidRootPart.CFrame = lookAtCFrame
        end
        return true
    end
    
    local function vhsMemorySolvePuzzle()
        if not vhsMemoryMakeItemTouchDetect() then return false end
        task.wait(0.5)
        if not vhsMemoryEquipVHS() then return false end
        task.wait(0.3)
        return vhsMemoryMonitorMemoryQuestion()
    end
    
    local function vhsMemoryAutoPuzzleRoutine()
        if vhsMemoryRunning or not isPlayerInSurvivors() then return end
        if vhsMemoryIsPuzzleCompleted() then return end
        
        vhsMemoryRunning = true
        if vhsMemoryCollectVHS() then vhsMemorySolvePuzzle() end
        if vhsMemoryHasSavedPosition then vhsMemoryRestorePlayerPosition() end
        vhsMemoryRunning = false
    end
    
    local function vhsMemoryGerenciarEspera()
        if not vhsMemoryActiveVar then return false end
        
        if Player.Team then
            if vhsMemoryLastTeamCheck ~= Player.Team.Name then
                local previousTeam = vhsMemoryLastTeamCheck
                vhsMemoryLastTeamCheck = Player.Team.Name
                
                if previousTeam == "Survivors" and Player.Team.Name ~= "Survivors" then
                    vhsMemorySavedPosition = nil
                    vhsMemoryHasSavedPosition = false
                    vhsMemoryRunning = false
                    vhsMemoryEsperaIniciada = false
                    vhsMemoryShouldWaitOnTeamChange = true
                end
                
                if Player.Team.Name == "Survivors" and vhsMemoryShouldWaitOnTeamChange then
                    if not vhsMemoryEsperaIniciada then
                        vhsMemoryEsperaIniciada = true
                        vhsMemoryTempoEsperaInicio = tick()
                    end
                end
            end
            
            if vhsMemoryEsperaIniciada and Player.Team.Name == "Survivors" then
                local tempoDecorrido = tick() - vhsMemoryTempoEsperaInicio
                local tempoRestante = 12 - tempoDecorrido
                if tempoRestante > 0 then return true end
                if not vhsMemoryIsPuzzleCompleted() then vhsMemorySavePlayerPosition() end
                vhsMemoryEsperaIniciada = false
                vhsMemoryShouldWaitOnTeamChange = false
            end
            
            if Player.Team.Name == "Survivors" and not vhsMemoryHasSavedPosition and not vhsMemoryEsperaIniciada then
                if not vhsMemoryIsPuzzleCompleted() then vhsMemorySavePlayerPosition() end
            end
        end
        return false
    end
    
    -- FUNÇÕES DO CHEESE ALTAR
    local function findTool(names)
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        for _, container in ipairs({character, backpack}) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        for _, name in ipairs(names) do
                            if item.Name == name then return item end
                        end
                    end
                end
            end
        end
    end
    
    local function waitForCheeseTool()
        for i = 1, 100 do
            local tool = findTool({"PuzzleCheeseTool"})
            if tool and tool.Parent == Player.Backpack then return tool end
            task.wait(0.1)
        end
        return nil
    end
    
    local function teleportToCFrame(cf)
        pcall(function()
            Player.Character.HumanoidRootPart.CFrame = cf
        end)
    end
    
    local function teleportToPositionOnce(cframe)
        if not cframe then return end
        pcall(function()
            if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                Player.Character.HumanoidRootPart.CFrame = cframe
            end
        end)
    end
    
    local function returnToOriginalPosition()
        if cheeseAltarOriginalPosition then
            teleportToPositionOnce(cheeseAltarOriginalPosition)
        end
    end
    
    local function hasToolInBackpack()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        if backpack and backpack:FindFirstChild("PuzzleHotdog") then return true end
        if character and character:FindFirstChild("PuzzleHotdog") then return true end
        return false
    end
    
    local function equipTool()
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild("PuzzleHotdog")
            if tool then
                tool.Parent = Player.Character
                return true
            end
        end
        if Player.Character and Player.Character:FindFirstChild("PuzzleHotdog") then return true end
        return false
    end
    
    local function waitForHotdogTool()
        for i = 1, 30 do
            if hasToolInBackpack() then return true end
            task.wait(0.2)
        end
        return false
    end
    
    local function saveOriginalPositionCheeseAltar()
        if not cheeseAltarHasSavedPosition then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                cheeseAltarOriginalPosition = hrp.CFrame
                cheeseAltarHasSavedPosition = true
            end
        end
    end
    
    local function cheeseAltarRunMission()
        if not puzzleState.cheeseAltarActive then return end
        if cheeseAltarIsWaiting then return end
        
        -- Verificar mudança de time
        if Player.Team then
            if cheeseAltarLastTeamCheck ~= Player.Team.Name then
                local previousTeam = cheeseAltarLastTeamCheck
                cheeseAltarLastTeamCheck = Player.Team.Name
                
                if previousTeam == "Survivors" and Player.Team.Name ~= "Survivors" then
                    cheeseAltarOriginalPosition = nil
                    cheeseAltarHasSavedPosition = false
                    cheeseAltarMonstaState.stage = 0
                    cheeseAltarMonstaState.attempts = 0
                end
                
                if Player.Team.Name == "Survivors" and cheeseAltarShouldWaitOnTeamChange then
                    cheeseAltarIsWaiting = true
                    local waitStart = tick()
                    
                    while cheeseAltarIsWaiting and puzzleState.cheeseAltarActive and Player.Team and Player.Team.Name == "Survivors" do
                        local elapsed = tick() - waitStart
                        if elapsed >= 12 then break end
                        task.wait(0.1)
                    end
                    
                    if cheeseAltarIsWaiting and puzzleState.cheeseAltarActive and Player.Team and Player.Team.Name == "Survivors" then
                        saveOriginalPositionCheeseAltar()
                    end
                    
                    cheeseAltarIsWaiting = false
                end
                
                if Player.Team.Name == "Survivors" then
                    cheeseAltarShouldWaitOnTeamChange = true
                end
            end
            
            if Player.Team.Name == "Survivors" and not cheeseAltarHasSavedPosition and not cheeseAltarShouldWaitOnTeamChange then
                saveOriginalPositionCheeseAltar()
            end
        end

        if not Player.Team or Player.Team.Name ~= "Survivors" then return end

        local puzzleBin = workspace:FindFirstChild("PuzzleBin")
        if not puzzleBin then return end

        -- Fallback 1: CheeseAltar padrão
        do
            local map = workspace:FindFirstChild("Map")
            local entities = map and map:FindFirstChild("_Entities")
            local altarCheese = puzzleBin:FindFirstChild("CheeseAltar")

            if entities and altarCheese then
                local eyes = altarCheese:FindFirstChild("Eyes")
                local detectCheese = altarCheese:FindFirstChild("Detect")
                if eyes and eyes.Transparency ~= 0 and detectCheese then
                    local cheeseTool = findTool({"PuzzleCheese", "Cheese", "PuzzleFish"})
                    if not cheeseTool then
                        local cheeseModel = entities:FindFirstChild("Cheese") or entities:FindFirstChild("CheeseCollect")
                        local cheeseDetect = cheeseModel and cheeseModel:FindFirstChild("Detect")
                        if cheeseDetect then
                            teleportToCFrame(cheeseDetect.CFrame + Vector3.new(0, 3, 0))
                            task.wait(1)
                            cheeseTool = findTool({"PuzzleCheese", "Cheese", "PuzzleFish"})
                            if cheeseTool and cheeseTool.Parent == Player.Backpack then
                                Player.Character.Humanoid:EquipTool(cheeseTool)
                                task.wait(0.5)
                            end
                        end
                    end

                    if cheeseTool then
                        teleportToCFrame(detectCheese.CFrame + Vector3.new(0, 3, 0))
                        repeat task.wait(0.2) until eyes.Transparency == 0
                        returnToOriginalPosition()
                        return
                    end
                end
            end
        end
        
        -- Fallback 4: Monsta (Lone House)
        do
            local monsta = puzzleBin:FindFirstChild("Monsta")
            if not monsta then
                if cheeseAltarMonstaState.stage ~= 0 then
                    cheeseAltarMonstaState.stage = 0
                    cheeseAltarMonstaState.attempts = 0
                    returnToOriginalPosition()
                end
                return
            end

            local block = monsta:FindFirstChild("Block")
            if not block then
                if cheeseAltarMonstaState.stage ~= 0 then
                    returnToOriginalPosition()
                    cheeseAltarMonstaState.stage = 0
                    cheeseAltarMonstaState.attempts = 0
                    return
                end
                return
            end

            if cheeseAltarMonstaState.stage == 0 then
                cheeseAltarMonstaState.stage = 1
                cheeseAltarMonstaState.attempts = 0
            end

            if cheeseAltarMonstaState.stage == 1 then
                if not hasToolInBackpack() then
                    teleportToCFrame(monstaCFrame1)
                    cheeseAltarMonstaState.attempts = cheeseAltarMonstaState.attempts + 1
                    if cheeseAltarMonstaState.attempts > cheeseAltarMonstaState.maxAttempts then
                        cheeseAltarMonstaState.stage = 0
                        cheeseAltarMonstaState.attempts = 0
                        return
                    end
                    task.wait(0.5)
                else
                    cheeseAltarMonstaState.stage = 2
                end
            end

            if cheeseAltarMonstaState.stage == 2 then
                if equipTool() then
                    cheeseAltarMonstaState.stage = 3
                else
                    task.wait(0.2)
                end
            end

            if cheeseAltarMonstaState.stage == 3 then
                teleportToCFrame(monstaCFrame2)
                cheeseAltarMonstaState.stage = 4
                cheeseAltarMonstaState.waitUntil = tick() + 3
            end

            if cheeseAltarMonstaState.stage == 4 then
                if tick() >= cheeseAltarMonstaState.waitUntil then
                    if not hasToolInBackpack() then
                        cheeseAltarMonstaState.stage = 5
                    else
                        teleportToCFrame(monstaCFrame2)
                        task.wait(0.1)
                    end
                end
            end

            if cheeseAltarMonstaState.stage == 5 then
                returnToOriginalPosition()
                cheeseAltarMonstaState.stage = 0
                return
            end
        end
    end
    
    -- LOOPS DOS PUZZLES
    local function iniciarPuzzleSolverLoop()
        if puzzleState.connections.puzzle then
            puzzleState.connections.puzzle:Disconnect()
        end
        
        puzzleState.connections.puzzle = Services.RunService.RenderStepped:Connect(function()
            if not active then return end
            
            if Player.Team then
                if lastTeamCheck ~= Player.Team.Name then
                    local previousTeam = lastTeamCheck
                    lastTeamCheck = Player.Team.Name
                    
                    if previousTeam == "Survivors" and Player.Team.Name ~= "Survivors" then
                        originalPosition = nil
                        hasSavedPosition = false
                        teleporting = false
                        aguardandoWire = false
                        modoSmoke = false
                        processoAtivado = false
                        wireModels = {}
                        smokeLeaks = {}
                        currentWireIndex = 1
                        currentSmokeIndex = 1
                        shouldWaitOnTeamChange = true
                    end
                    
                    if Player.Team.Name == "Survivors" and shouldWaitOnTeamChange then
                        isWaiting = true
                        task.spawn(function()
                            local waitStart = tick()
                            while isWaiting and active and Player.Team and Player.Team.Name == "Survivors" do
                                local elapsed = tick() - waitStart
                                if elapsed >= 12 then break end
                                task.wait(0.1)
                            end
                            
                            if isWaiting and active and Player.Team and Player.Team.Name == "Survivors" then
                                iniciarProcesso()
                            end
                            
                            isWaiting = false
                        end)
                    end
                    
                    if Player.Team.Name == "Survivors" then
                        shouldWaitOnTeamChange = true
                    end
                end
                
                if Player.Team.Name == "Survivors" and not hasSavedPosition and not shouldWaitOnTeamChange then
                    salvarPosicaoInicial()
                end
            end

            if isWaiting then return end
            if not Player.Team or Player.Team.Name ~= "Survivors" then return end
            
            if aguardandoWire then
                if tick() % 2 < 0.1 then
                    wireModels = encontrarWiresNaoCompletados()
                    if #wireModels > 0 then
                        processoAtivado = true
                        modoSmoke = false
                        salvarPosicaoInicial()
                        aguardandoWire = false
                        teleporting = true
                        currentWireIndex = 1
                        return
                    end
                    
                    local temSmoke, leaks = encontrarSmokeLeaks()
                    if temSmoke then
                        processoAtivado = true
                        modoSmoke = true
                        smokeLeaks = leaks
                        currentSmokeIndex = 1
                        salvarPosicaoInicial()
                        aguardandoWire = false
                        teleporting = true
                        return
                    end
                end
                return
            end
            
            if not teleporting then return end
            
            if not modoSmoke then
                if currentWireIndex > #wireModels then
                    wireModels = encontrarWiresNaoCompletados()
                    if #wireModels > 0 then
                        currentWireIndex = 1
                    else
                        local temSmoke, leaks = encontrarSmokeLeaks()
                        if temSmoke then
                            modoSmoke = true
                            smokeLeaks = leaks
                            currentSmokeIndex = 1
                        else
                            voltarParaPosicaoOriginal()
                            teleporting = false
                            aguardandoWire = true
                            processoAtivado = false
                            return
                        end
                    end
                end
                
                local wireModel = wireModels[currentWireIndex]
                if not wireModel or not wireModel.Parent then
                    currentWireIndex = currentWireIndex + 1
                    return
                end
                
                if wireCompleto(wireModel) then
                    currentWireIndex = currentWireIndex + 1
                    return
                end
                
                if teleportarParaWire(wireModel) then
                    completarWire(wireModel)
                end
            else
                if currentSmokeIndex > #smokeLeaks then
                    local temSmoke, leaks = encontrarSmokeLeaks()
                    if #leaks > 0 then
                        smokeLeaks = leaks
                        currentSmokeIndex = 1
                    else
                        voltarParaPosicaoOriginal()
                        teleporting = false
                        aguardandoWire = true
                        processoAtivado = false
                        modoSmoke = false
                        return
                    end
                end
                
                local leak = smokeLeaks[currentSmokeIndex]
                if not smokeLeakExiste(leak) then
                    currentSmokeIndex = currentSmokeIndex + 1
                    return
                end
                
                if teleportarParaSmokeLeak(leak) then
                    ativarSmokeLeak(leak)
                    if not smokeLeakExiste(leak) then
                        currentSmokeIndex = currentSmokeIndex + 1
                    end
                end
            end
        end)
    end
    
    local function iniciarColorCodeLoop()
        if puzzleState.connections.colorCode then
            puzzleState.connections.colorCode:Disconnect()
        end
        
        puzzleState.connections.colorCode = Services.RunService.RenderStepped:Connect(function()
            if not puzzleState.colorCodeActive then return end
            if gerenciarEsperaColorCode() then return end
            if not Player.Team or Player.Team.Name ~= "Survivors" then return end
            if colorCodeResolvendo then return end
            pcall(resolverColorCode)
        end)
    end
    
    local function iniciarVHSMemoryLoop()
        if puzzleState.connections.vhsMemory then
            puzzleState.connections.vhsMemory:Disconnect()
        end
        
        puzzleState.connections.vhsMemory = Services.RunService.RenderStepped:Connect(function()
            if not vhsMemoryActiveVar then return end
            if vhsMemoryGerenciarEspera() then return end
            if not Player.Team or Player.Team.Name ~= "Survivors" then return end
            if vhsMemoryRunning then return end
            task.spawn(vhsMemoryAutoPuzzleRoutine)
        end)
    end
    
    local function iniciarCheeseAltarLoop()
        if puzzleState.connections.cheeseAltar then
            puzzleState.connections.cheeseAltar:Disconnect()
        end
        
        puzzleState.connections.cheeseAltar = Services.RunService.RenderStepped:Connect(function()
            if not puzzleState.cheeseAltarActive then return end
            pcall(cheeseAltarRunMission)
        end)
    end
    
    -- FUNÇÕES DE ATIVAÇÃO/DESATIVAÇÃO
    local function ativarPuzzleSolver()
        puzzleState.puzzleSolverActive = true
        active = true
        
        hasSavedPosition = false
        originalPosition = nil
        teleporting = false
        aguardandoWire = false
        processoAtivado = false
        modoSmoke = false
        wireModels = {}
        smokeLeaks = {}
        currentWireIndex = 1
        currentSmokeIndex = 1
        isWaiting = false
        
        if Player.Team and Player.Team.Name == "Survivors" then
            shouldWaitOnTeamChange = false
            iniciarProcesso()
        else
            shouldWaitOnTeamChange = true
        end
        
        lastTeamCheck = Player.Team and Player.Team.Name
        iniciarPuzzleSolverLoop()
    end
    
    local function desativarPuzzleSolver()
        puzzleState.puzzleSolverActive = false
        active = false
        
        if puzzleState.connections.puzzle then
            puzzleState.connections.puzzle:Disconnect()
            puzzleState.connections.puzzle = nil
        end
        
        teleporting = false
        aguardandoWire = false
        modoSmoke = false
        processoAtivado = false
        isWaiting = false
        hasSavedPosition = false
        
        if originalPosition then
            voltarParaPosicaoOriginal()
            originalPosition = nil
        end
    end
    
    local function ativarColorCode()
        puzzleState.colorCodeActive = true
        colorCodeHasSavedPosition = false
        colorCodeOriginalPosition = nil
        colorCodeResolvendo = false
        colorCodeEsperaIniciada = false
        
        if Player.Team and Player.Team.Name == "Survivors" then
            colorCodeShouldWaitOnTeamChange = false
            if not colorCodePuzzleCompleto() then
                salvarPosicaoOriginalColorCode()
            end
        else
            colorCodeShouldWaitOnTeamChange = true
        end
        
        colorCodeLastTeamCheck = Player.Team and Player.Team.Name
        iniciarColorCodeLoop()
    end
    
    local function desativarColorCode()
        puzzleState.colorCodeActive = false
        colorCodeResolvendo = false
        colorCodeEsperaIniciada = false
        
        if puzzleState.connections.colorCode then
            puzzleState.connections.colorCode:Disconnect()
            puzzleState.connections.colorCode = nil
        end
        
        if colorCodeHasSavedPosition and colorCodeOriginalPosition then
            voltarParaPosicaoOriginalColorCode()
        else
            colorCodeOriginalPosition = nil
            colorCodeHasSavedPosition = false
        end
    end
    
    local function ativarVHSMemory()
        puzzleState.vhsMemoryActive = true
        vhsMemoryActiveVar = true
        vhsMemoryHasSavedPosition = false
        vhsMemorySavedPosition = nil
        vhsMemoryRunning = false
        vhsMemoryEsperaIniciada = false
        
        if Player.Team and Player.Team.Name == "Survivors" then
            vhsMemoryShouldWaitOnTeamChange = false
            if not vhsMemoryIsPuzzleCompleted() then
                vhsMemorySavePlayerPosition()
            end
        else
            vhsMemoryShouldWaitOnTeamChange = true
        end
        
        vhsMemoryLastTeamCheck = Player.Team and Player.Team.Name
        iniciarVHSMemoryLoop()
    end
    
    local function desativarVHSMemory()
        puzzleState.vhsMemoryActive = false
        vhsMemoryActiveVar = false
        vhsMemoryRunning = false
        vhsMemoryEsperaIniciada = false
        
        if puzzleState.connections.vhsMemory then
            puzzleState.connections.vhsMemory:Disconnect()
            puzzleState.connections.vhsMemory = nil
        end
        
        if vhsMemoryHasSavedPosition and vhsMemorySavedPosition and not vhsMemoryIsPuzzleCompleted() then
            vhsMemoryRestorePlayerPosition()
        else
            vhsMemorySavedPosition = nil
            vhsMemoryHasSavedPosition = false
        end
    end
    
    local function ativarCheeseAltar()
        puzzleState.cheeseAltarActive = true
        cheeseAltarHasSavedPosition = false
        cheeseAltarOriginalPosition = nil
        cheeseAltarIsWaiting = false
        
        if Player.Team and Player.Team.Name == "Survivors" then
            cheeseAltarShouldWaitOnTeamChange = false
            saveOriginalPositionCheeseAltar()
        else
            cheeseAltarShouldWaitOnTeamChange = true
        end
        
        cheeseAltarLastTeamCheck = Player.Team and Player.Team.Name
        cheeseAltarMonstaState.stage = 0
        cheeseAltarMonstaState.attempts = 0
        iniciarCheeseAltarLoop()
    end
    
    local function desativarCheeseAltar()
        puzzleState.cheeseAltarActive = false
        cheeseAltarIsWaiting = false
        
        if puzzleState.connections.cheeseAltar then
            puzzleState.connections.cheeseAltar:Disconnect()
            puzzleState.connections.cheeseAltar = nil
        end
        
        cheeseAltarMonstaState.stage = 0
        cheeseAltarMonstaState.attempts = 0
    end
    
    local function stopAll()
        puzzleState.scriptStopped = true
        for name, connection in pairs(puzzleState.connections) do
            if connection then connection:Disconnect() end
            puzzleState.connections[name] = nil
        end
        
        if puzzleState.puzzleSolverActive then desativarPuzzleSolver() end
        if puzzleState.colorCodeActive then desativarColorCode() end
        if puzzleState.vhsMemoryActive then desativarVHSMemory() end
        if puzzleState.cheeseAltarActive then desativarCheeseAltar() end
    end
    
    -- Retornar API pública
    return {
        ativarPuzzleSolver = ativarPuzzleSolver,
        desativarPuzzleSolver = desativarPuzzleSolver,
        ativarColorCode = ativarColorCode,
        desativarColorCode = desativarColorCode,
        ativarVHSMemory = ativarVHSMemory,
        desativarVHSMemory = desativarVHSMemory,
        ativarCheeseAltar = ativarCheeseAltar,
        desativarCheeseAltar = desativarCheeseAltar,
        stopAll = stopAll,
        isPuzzleSolverActive = function() return puzzleState.puzzleSolverActive end,
        isColorCodeActive = function() return puzzleState.colorCodeActive end,
        isVHSMemoryActive = function() return puzzleState.vhsMemoryActive end,
        isCheeseAltarActive = function() return puzzleState.cheeseAltarActive end
    }
end

-- Retornar função de inicialização
return init()