--[[
	LocalScript Admin Panel for Roblox
	Place this script in StarterPlayerScripts (or StarterGui as a LocalScript).
	Default toggle key: RightShift
	Features:
		- Fly
		- Speed Boost
		- Infinite Jump
		- NoClip
		- Click Teleport
		- ESP (player name tags)
		- Full Bright
		- Low Gravity
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local config = {
	toggleKey = Enum.KeyCode.RightShift,
	openOnStart = true,
	flySpeed = 50,
	walkSpeedMultiplier = 2,
	lowGravity = 20,
	defaultGravity = workspace.Gravity,
	uiTheme = {
		background = Color3.fromRGB(30, 30, 35),
		accent = Color3.fromRGB(88, 101, 242),
		accentDark = Color3.fromRGB(60, 70, 200),
		text = Color3.fromRGB(255, 255, 255),
		subText = Color3.fromRGB(180, 180, 180),
		toggleOff = Color3.fromRGB(60, 60, 65),
		toggleOn = Color3.fromRGB(88, 101, 242),
	},
}

local state = {
	fly = false,
	speed = false,
	infiniteJump = false,
	noClip = false,
	clickTeleport = false,
	esp = false,
	fullBright = false,
	lowGravity = false,
}

local connections = {}
local espObjects = {}

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanel"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
mainFrame.BackgroundColor3 = config.uiTheme.background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
mainFrame.Visible = config.openOnStart

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
shadow.Size = UDim2.new(1, 24, 1, 24)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1
shadow.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = config.uiTheme.accent
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Admin Panel"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextColor3 = config.uiTheme.text
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "Minimize"
minimizeButton.Size = UDim2.new(0, 28, 0, 28)
minimizeButton.Position = UDim2.new(1, -60, 0, 8)
minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.BackgroundTransparency = 0.9
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.TextColor3 = config.uiTheme.text
minimizeButton.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeButton

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -32, 0, 8)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.TextColor3 = config.uiTheme.text
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -24, 1, -56)
contentFrame.Position = UDim2.new(0, 12, 0, 50)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = config.uiTheme.accent
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = contentFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = contentFrame

-- Helpers
local function makeToggle(name: string, description: string, callback: (boolean) -> ()): Frame
	local row = Instance.new("Frame")
	row.Name = name .. "Row"
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	row.BorderSizePixel = 0
	row.LayoutOrder = #contentFrame:GetChildren() + 1

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -80, 0, 22)
	label.Position = UDim2.new(0, 12, 0, 8)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 15
	label.TextColor3 = config.uiTheme.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Size = UDim2.new(1, -80, 0, 16)
	desc.Position = UDim2.new(0, 12, 0, 30)
	desc.BackgroundTransparency = 1
	desc.Text = description
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextColor3 = config.uiTheme.subText
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "Toggle"
	button.Size = UDim2.new(0, 52, 0, 28)
	button.Position = UDim2.new(1, -64, 0, 14)
	button.BackgroundColor3 = config.uiTheme.toggleOff
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(1, 0)
	buttonCorner.Parent = button

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 22, 0, 22)
	knob.Position = UDim2.new(0, 3, 0.5, -11)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = button

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local enabled = false

	local function update()
		local targetColor = enabled and config.uiTheme.toggleOn or config.uiTheme.toggleOff
		local targetPos = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
		TweenService:Create(button, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
		TweenService:Create(knob, TweenInfo.new(0.2), { Position = targetPos }):Play()
		callback(enabled)
	end

	button.MouseButton1Click:Connect(function()
		enabled = not enabled
		update()
	end)

	row.Parent = contentFrame
	return row
end

local function notify(text: string)
	task.spawn(function()
		local notice = Instance.new("TextLabel")
		notice.Name = "Notification"
		notice.Size = UDim2.new(0, 300, 0, 48)
		notice.Position = UDim2.new(0.5, -150, 0, -60)
		notice.BackgroundColor3 = config.uiTheme.accent
		notice.Text = text
		notice.Font = Enum.Font.GothamSemibold
		notice.TextSize = 14
		notice.TextColor3 = config.uiTheme.text
		notice.TextStrokeTransparency = 0.8
		notice.TextScaled = true
		notice.TextWrapped = true
		notice.TextXAlignment = Enum.TextXAlignment.Center
		notice.TextYAlignment = Enum.TextYAlignment.Center
		notice.Parent = screenGui

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.PaddingTop = UDim.new(0, 8)
		padding.PaddingBottom = UDim.new(0, 8)
		padding.Parent = notice

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = notice

		TweenService:Create(notice, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, -150, 0, 20) }):Play()
		task.wait(2.5)
		local out = TweenService:Create(notice, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, -150, 0, -60) })
		out:Play()
		out.Completed:Wait()
		notice:Destroy()
	end)
end

-- Feature implementations
local function getCharacter(): Model?
	return player.Character
end

local function getHumanoid(): Humanoid?
	local char = getCharacter()
	if char then
		return char:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

-- Fly
local flyBodyVelocity: BodyVelocity? = nil
local flyConnection: RBXScriptConnection? = nil

local function setFly(enabled: boolean)
	state.fly = enabled
	local char = getCharacter()
	if not char then return end

	if enabled then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if flyBodyVelocity then flyBodyVelocity:Destroy() end
		flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		flyBodyVelocity.Velocity = Vector3.zero
		flyBodyVelocity.Parent = hrp

		flyConnection = RunService.RenderStepped:Connect(function()
			if not flyBodyVelocity or not flyBodyVelocity.Parent then return end
			local camera = workspace.CurrentCamera
			local direction = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0, 1, 0) end

			if direction.Magnitude > 0 then
				direction = direction.Unit * config.flySpeed
			end
			flyBodyVelocity.Velocity = direction
		end)
	else
		if flyBodyVelocity then flyBodyVelocity:Destroy() end
		flyBodyVelocity = nil
		if flyConnection then flyConnection:Disconnect() end
		flyConnection = nil
	end
end

-- Speed
local speedConnection: RBXScriptConnection? = nil
local function setSpeed(enabled: boolean)
	state.speed = enabled
	if speedConnection then speedConnection:Disconnect() end

	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = enabled and 16 * config.walkSpeedMultiplier or 16
	end

	if enabled then
		speedConnection = RunService.RenderStepped:Connect(function()
			local h = getHumanoid()
			if h and h.WalkSpeed ~= 16 * config.walkSpeedMultiplier then
				h.WalkSpeed = 16 * config.walkSpeedMultiplier
			end
		end)
	end
end

-- Infinite Jump
local function setInfiniteJump(enabled: boolean)
	state.infiniteJump = enabled
	if enabled then
		connections.infiniteJump = UserInputService.JumpRequest:Connect(function()
			local humanoid = getHumanoid()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	else
		if connections.infiniteJump then
			connections.infiniteJump:Disconnect()
			connections.infiniteJump = nil
		end
	end
end

-- NoClip
local noClipConnection: RBXScriptConnection? = nil
local noClipOriginalStates: { [BasePart]: boolean } = {}

local function setNoClip(enabled: boolean)
	state.noClip = enabled
	if noClipConnection then noClipConnection:Disconnect() end

	if enabled then
		noClipOriginalStates = {}
		noClipConnection = RunService.Stepped:Connect(function()
			local char = getCharacter()
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						if noClipOriginalStates[part] == nil then
							noClipOriginalStates[part] = part.CanCollide
						end
						part.CanCollide = false
					end
				end
			end
		end)
	else
		local char = getCharacter()
		if char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and noClipOriginalStates[part] ~= nil then
					part.CanCollide = noClipOriginalStates[part]
				end
			end
		end
		noClipOriginalStates = {}
	end
end

-- Click Teleport
local function setClickTeleport(enabled: boolean)
	state.clickTeleport = enabled
	if enabled then
		connections.clickTeleport = mouse.Button1Down:Connect(function()
			if not state.clickTeleport then return end
			local target = mouse.Target
			if target then
				local char = getCharacter()
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and hrp:IsA("BasePart") then
					hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				end
			end
		end)
	else
		if connections.clickTeleport then
			connections.clickTeleport:Disconnect()
			connections.clickTeleport = nil
		end
	end
end

-- ESP
local function createEspFor(targetPlayer: Player)
	if targetPlayer == player then return end
	if espObjects[targetPlayer] then return end

	local data = {
		billboard = nil,
		connections = {},
	}

	local function onCharacterAdded(char: Model)
		local head = char:WaitForChild("Head", 5)
		if not head then return end

		if data.billboard and data.billboard.Parent then
			data.billboard:Destroy()
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "AdminEsp"
		billboard.Adornee = head
		billboard.Size = UDim2.new(0, 100, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.AlwaysOnTop = true

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = targetPlayer.Name
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0.5
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Parent = billboard

		billboard.Parent = head
		data.billboard = billboard
	end

	local function onCharacterRemoving(char: Model)
		if data.billboard and data.billboard.Parent then
			data.billboard:Destroy()
			data.billboard = nil
		end
	end

	if targetPlayer.Character then
		onCharacterAdded(targetPlayer.Character)
	end

	data.connections.added = targetPlayer.CharacterAdded:Connect(onCharacterAdded)
	data.connections.removing = targetPlayer.CharacterRemoving:Connect(onCharacterRemoving)

	espObjects[targetPlayer] = data
end

local function removeEspFor(targetPlayer: Player)
	local data = espObjects[targetPlayer]
	if not data then return end

	if data.billboard and data.billboard.Parent then
		data.billboard:Destroy()
	end

	for _, conn in pairs(data.connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end

	espObjects[targetPlayer] = nil
end

local function setEsp(enabled: boolean)
	state.esp = enabled
	if enabled then
		for _, target in pairs(Players:GetPlayers()) do
			createEspFor(target)
		end
		connections.espAdded = Players.PlayerAdded:Connect(createEspFor)
		connections.espRemoving = Players.PlayerRemoving:Connect(removeEspFor)
	else
		for _, target in pairs(Players:GetPlayers()) do
			removeEspFor(target)
		end
		if connections.espAdded then connections.espAdded:Disconnect() end
		if connections.espRemoving then connections.espRemoving:Disconnect() end
		connections.espAdded = nil
		connections.espRemoving = nil
	end
end

-- Full Bright
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient

local function setFullBright(enabled: boolean)
	state.fullBright = enabled
	if enabled then
		Lighting.Brightness = 2
		Lighting.ClockTime = 12
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.FogEnd = 100000
	else
		Lighting.Brightness = originalBrightness
		Lighting.ClockTime = originalClockTime
		Lighting.Ambient = originalAmbient
		Lighting.OutdoorAmbient = originalOutdoorAmbient
	end
end

-- Low Gravity
local function setLowGravity(enabled: boolean)
	state.lowGravity = enabled
	workspace.Gravity = enabled and config.lowGravity or config.defaultGravity
end

-- Build UI toggles
makeToggle("Fly", "WASD + Space/Shift in the air", setFly)
makeToggle("Speed Boost", "2x walk speed", setSpeed)
makeToggle("Infinite Jump", "Jump anywhere, anytime", setInfiniteJump)
makeToggle("NoClip", "Walk through walls", setNoClip)
makeToggle("Click Teleport", "Click to teleport", setClickTeleport)
makeToggle("ESP", "See player names through walls", setEsp)
makeToggle("Full Bright", "Remove darkness", setFullBright)
makeToggle("Low Gravity", "Moon gravity", setLowGravity)

-- Draggable window
local dragging = false
local dragInput: InputObject? = nil
local dragStart: Vector3? = nil
local startPos: UDim2? = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging and startPos then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Open / close keybind
local minimized = false
local function togglePanel()
	if minimized then
		mainFrame.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 420) }):Play()
		minimized = false
	else
		mainFrame.Visible = not mainFrame.Visible
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == config.toggleKey then
		togglePanel()
	end
end)

minimizeButton.MouseButton1Click:Connect(function()
	minimized = true
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 44) })
	tween:Play()
	tween.Completed:Connect(function()
		mainFrame.Visible = false
		minimized = false
	end)
end)

closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Reset states on character respawn to avoid stuck physics
player.CharacterAdded:Connect(function()
	task.wait(0.1)
	if state.fly then setFly(true) end
	if state.speed then setSpeed(true) end
	if state.noClip then setNoClip(true) end
end)

-- Intro animation when the panel starts visible
if config.openOnStart then
	mainFrame.Size = UDim2.new(0, 320, 0, 0)
	mainFrame.Visible = true
	TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 320, 0, 420) }):Play()
end

notify("Admin Panel loaded. Press RightShift to toggle.")
