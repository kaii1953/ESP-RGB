-- ESP RGB AUTOMÁTICO (BRILHO + BOX)
-- Simples, leve e robusto

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPs = {}
local hue = 0

local function createESP(player, character)
	if player == LocalPlayer then return end
	if not character then return end
	if not character:FindFirstChild("HumanoidRootPart") then return end

	-- Limpa ESP antigo
	if ESPs[player] then
		for _, obj in ipairs(ESPs[player]) do
			obj:Destroy()
		end
	end

	local espObjects = {}

	-- Highlight (corpo brilhante)
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = character
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	table.insert(espObjects, highlight)

	-- Box em volta do corpo
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "ESP_Box"
	box.Adornee = character.HumanoidRootPart
	box.AlwaysOnTop = true
	box.ZIndex = 10
	box.Size = Vector3.new(4, 6, 2)
	box.Transparency = 0.4
	box.Parent = character
	table.insert(espObjects, box)

	ESPs[player] = espObjects
end

local function setupPlayer(player)
	if player.Character then
		task.wait(0.2)
		createESP(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		createESP(player, character)
	end)
end

local function removePlayer(player)
	if ESPs[player] then
		for _, obj in ipairs(ESPs[player]) do
			obj:Destroy()
		end
		ESPs[player] = nil
	end
end

-- Jogadores atuais
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- Novos jogadores
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removePlayer)

-- RGB animado
RunService.RenderStepped:Connect(function(dt)
	hue = (hue + dt * 0.3) % 1
	local color = Color3.fromHSV(hue, 1, 1)

	for _, objects in pairs(ESPs) do
		for _, obj in ipairs(objects) do
			if obj:IsA("Highlight") then
				obj.FillColor = color
			elseif obj:IsA("BoxHandleAdornment") then
				obj.Color3 = color
			end
		end
	end
end)
