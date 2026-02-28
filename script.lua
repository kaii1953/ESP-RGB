-- Script de ESP RGB Profissional
-- Desenvolvido para Roblox Luau

local ESP = {}
ESP.__index = ESP

-- Configurações
local CONFIG = {
    ENABLED = true,
    UPDATE_INTERVAL = 0.1,
    RAINBOW_SPEED = 2,
    BOX_THICKNESS = 2,
    SHOW_HEALTH = true,
    SHOW_DISTANCE = true,
    SHOW_NAMES = true,
    MAX_DISTANCE = 1000,
    USE_TEAM_CHECK = true,
    TEAM_COLORS = {
        Enemy = Color3.new(1, 0, 0),    -- Vermelho
        Friend = Color3.new(0, 1, 0)     -- Verde
    }
}

-- Cache para objetos e jogadores
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Drawing = Drawing or nil

-- Verifica se Drawing está disponível
if not Drawing then
    warn("Drawing library não disponível!")
    return nil
end

-- Tabela para armazenar objetos ESP
local espObjects = {}
local rainbowHue = 0

-- Função para criar elementos ESP
function ESP:createElements(player)
    local elements = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    -- Configurar box
    elements.Box.Thickness = CONFIG.BOX_THICKNESS
    elements.Box.Filled = false
    elements.Box.Visible = false
    
    -- Configurar textos
    for _, element in pairs(elements) do
        if element:IsA("Text") then
            element.Center = true
            element.Outline = true
            element.Size = 14
            element.Font = 2 -- Monospace
        end
    end
    
    return elements
end

-- Função para calcular cor RGB
function ESP:getRainbowColor()
    rainbowHue = (rainbowHue + CONFIG.RAINBOW_SPEED * 0.01) % 1
    return Color3.fromHSV(rainbowHue, 1, 1)
end

-- Função para obter cor do time
function ESP:getTeamColor(player)
    if not CONFIG.USE_TEAM_CHECK then
        return self:getRainbowColor()
    end
    
    if player.Team == LocalPlayer.Team then
        return CONFIG.TEAM_COLORS.Friend
    else
        return CONFIG.TEAM_COLORS.Enemy
    end
end

-- Função para converter Color3 para hexadecimal
function ESP:color3ToHex(color)
    return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

-- Função para calcular distância
function ESP:getDistance(position)
    return math.floor((Camera.CFrame.Position - position).Magnitude)
end

-- Função principal de renderização
function ESP:render()
    if not CONFIG.ENABLED then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local humanoid = character.Humanoid
            local rootPart = character.HumanoidRootPart
            
            -- Verifica distância
            local distance = self:getDistance(rootPart.Position)
            if distance > CONFIG.MAX_DISTANCE then continue end
            
            -- Calcula posição na tela
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                -- Cria elementos se não existirem
                if not espObjects[player] then
                    espObjects[player] = self:createElements(player)
                end
                
                local elements = espObjects[player]
                local boxColor = self:getTeamColor(player)
                
                -- Calcula tamanho da caixa baseado na distância
                local boxHeight = math.clamp(4000 / distance, 50, 300)
                local boxWidth = boxHeight * 0.6
                
                -- Posição da caixa
                local boxPos = Vector2.new(screenPos.X - boxWidth/2, screenPos.Y - boxHeight/2)
                
                -- Atualiza Box
                elements.Box.Visible = true
                elements.Box.Color = boxColor
                elements.Box.Position = boxPos
                elements.Box.Size = Vector2.new(boxWidth, boxHeight)
                
                -- Atualiza Nome
                if CONFIG.SHOW_NAMES then
                    elements.Name.Visible = true
                    elements.Name.Text = player.Name
                    elements.Name.Color = boxColor
                    elements.Name.Position = Vector2.new(screenPos.X, boxPos.Y - 15)
                else
                    elements.Name.Visible = false
                end
                
                -- Atualiza Health Bar
                if CONFIG.SHOW_HEALTH then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local healthBarHeight = boxHeight * healthPercent
                    local healthColor = Color3.new(1 - healthPercent, healthPercent, 0)
                    
                    elements.HealthBar.Visible = true
                    elements.HealthBar.Color = healthColor
                    elements.HealthBar.Filled = true
                    elements.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (boxHeight - healthBarHeight))
                    elements.HealthBar.Size = Vector2.new(3, healthBarHeight)
                    
                    elements.HealthText.Visible = true
                    elements.HealthText.Text = string.format("%.0f/%.0f", humanoid.Health, humanoid.MaxHealth)
                    elements.HealthText.Color = Color3.new(1, 1, 1)
                    elements.HealthText.Position = Vector2.new(screenPos.X, boxPos.Y + boxHeight + 5)
                else
                    elements.HealthBar.Visible = false
                    elements.HealthText.Visible = false
                end
                
                -- Atualiza Distância
                if CONFIG.SHOW_DISTANCE then
                    elements.Distance.Visible = true
                    elements.Distance.Text = string.format("%dm", distance)
                    elements.Distance.Color = Color3.new(0.8, 0.8, 0.8)
                    elements.Distance.Position = Vector2.new(screenPos.X, boxPos.Y - 30)
                else
                    elements.Distance.Visible = false
                end
            else
                -- Esconde elementos se não estiver na tela
                if espObjects[player] then
                    for _, element in pairs(espObjects[player]) do
                        element.Visible = false
                    end
                end
            end
        elseif espObjects[player] then
            -- Esconde elementos se o jogador não é válido
            for _, element in pairs(espObjects[player]) do
                element.Visible = false
            end
        end
    end
end

-- Função para limpar ESP
function ESP:cleanup()
    for _, elements in pairs(espObjects) do
        for _, element in pairs(elements) do
            element:Remove()
        end
    end
    espObjects = {}
end

-- Função para atualizar configurações
function ESP:updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        end
    end
end

-- Inicializa o ESP
function ESP:Start()
    print("ESP Iniciado - Criado por Profissional")
    
    -- Loop principal
    RunService.RenderStepped:Connect(function()
        self:render()
    end)
    
    -- Limpeza quando jogador sair
    Players.PlayerRemoving:Connect(function(player)
        if espObjects[player] then
            for _, element in pairs(espObjects[player]) do
                element:Remove()
            end
            espObjects[player] = nil
        end
    end)
end

-- Retorna o módulo
return ESP
