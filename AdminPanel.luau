--[[
	Universal Script - Roblox Admin Panel
	Place this script in StarterPlayerScripts (or StarterGui as a LocalScript).
	Default toggle key: RightShift
	Features:
		- Fly (WASD + Q/E or Space/Shift) with speed slider
		- Walk Speed slider
		- Infinite Jump
		- Jump Power slider (fixed for JumpHeight games)
		- NoClip
		- Click Teleport
		- Player Teleport
		- Name ESP (name + health)
		- Box ESP (Highlight outline)
		- Full Bright
		- Low Gravity
		- FOV slider
		- Hitbox Expander with size slider
		- Aimbot with range and speed sliders
		- Panic Button (disable all)
		- Reset Character
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
	flyUpKey = Enum.KeyCode.E,
	flyDownKey = Enum.KeyCode.Q,
	walkSpeed = 32,
	jumpPower = 100,
	jumpHeight = 14.4,
	lowGravity = 20,
	defaultGravity = workspace.Gravity,
	defaultFov = 70,
	boostedFov = 120,
	hitboxSize = 10,
	aimbotRange = 200,
	aimbotSpeed = 50,
	aimbotPart = "Head",
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
	infiniteJump = false,
	noClip = false,
	clickTeleport = false,
	nameEsp = false,
	boxEsp = false,
	fullBright = false,
	lowGravity = false,
	hitboxExpander = false,
	aimbot = false,
}

local liveValues = {
	walkSpeed = 16,
	jumpPower = 50,
	jumpHeight = 7.2,
	flySpeed = 50,
	fov = 70,
	hitboxSize = 10,
	aimbotRange = 200,
	aimbotSpeed = 50,
}

local sliderSetters: { [string]: (number) -> () } = {}

local connections = {}
local sliderConnections: { RBXScriptConnection } = {}
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

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, config.uiTheme.background),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 55)),
})
mainGradient.Rotation = 90
mainGradient.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.5
mainStroke.Color = Color3.fromRGB(70, 70, 85)
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

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
titleBar.Size = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = config.uiTheme.accent
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, config.uiTheme.accent),
	ColorSequenceKeypoint.new(1, config.uiTheme.accentDark),
})
titleGradient.Rotation = 135
titleGradient.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, -90, 0, 28)
titleText.Position = UDim2.new(0, 16, 0, 6)
titleText.BackgroundTransparency = 1
titleText.Text = "Universal Script"
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 20
titleText.TextColor3 = config.uiTheme.text
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local creditsText = Instance.new("TextLabel")
creditsText.Name = "Credits"
creditsText.Size = UDim2.new(1, -90, 0, 16)
creditsText.Position = UDim2.new(0, 16, 0, 32)
creditsText.BackgroundTransparency = 1
creditsText.Text = "by @katowice00 on Telegram"
creditsText.Font = Enum.Font.Gotham
creditsText.TextSize = 11
creditsText.TextColor3 = Color3.fromRGB(230, 230, 255)
creditsText.TextXAlignment = Enum.TextXAlignment.Left
creditsText.Parent = titleBar

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
contentFrame.Size = UDim2.new(1, -24, 1, -66)
contentFrame.Position = UDim2.new(0, 12, 0, 60)
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

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 1
	rowStroke.Color = Color3.fromRGB(55, 55, 60)
	rowStroke.Transparency = 0.7
	rowStroke.Parent = row

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

local function makeButton(name: string, description: string, buttonText: string, callback: () -> ()): Frame
	local row = Instance.new("Frame")
	row.Name = name .. "Row"
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	row.BorderSizePixel = 0
	row.LayoutOrder = #contentFrame:GetChildren() + 1

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 1
	rowStroke.Color = Color3.fromRGB(55, 55, 60)
	rowStroke.Transparency = 0.7
	rowStroke.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -96, 0, 22)
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
	desc.Size = UDim2.new(1, -96, 0, 16)
	desc.Position = UDim2.new(0, 12, 0, 30)
	desc.BackgroundTransparency = 1
	desc.Text = description
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextColor3 = config.uiTheme.subText
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "Action"
	button.Size = UDim2.new(0, 80, 0, 32)
	button.Position = UDim2.new(1, -92, 0, 12)
	button.BackgroundColor3 = config.uiTheme.accent
	button.Text = buttonText
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = config.uiTheme.text
	button.AutoButtonColor = true
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, config.uiTheme.accent),
		ColorSequenceKeypoint.new(1, config.uiTheme.accentDark),
	})
	buttonGradient.Rotation = 135
	buttonGradient.Parent = button

	button.MouseButton1Click:Connect(callback)

	row.Parent = contentFrame
	return row
end

local function makeSlider(name: string, description: string, min: number, max: number, default: number, callback: (number) -> ()): (Frame, (number, boolean?) -> ())
	local row = Instance.new("Frame")
	row.Name = name .. "Row"
	row.Size = UDim2.new(1, 0, 0, 72)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	row.BorderSizePixel = 0
	row.LayoutOrder = #contentFrame:GetChildren() + 1

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 1
	rowStroke.Color = Color3.fromRGB(55, 55, 60)
	rowStroke.Transparency = 0.7
	rowStroke.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -70, 0, 22)
	label.Position = UDim2.new(0, 12, 0, 8)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 15
	label.TextColor3 = config.uiTheme.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0, 56, 0, 22)
	valueLabel.Position = UDim2.new(1, -68, 0, 8)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default)
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 14
	valueLabel.TextColor3 = config.uiTheme.accent
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = row

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.Size = UDim2.new(1, -24, 0, 16)
	desc.Position = UDim2.new(0, 12, 0, 48)
	desc.BackgroundTransparency = 1
	desc.Text = description
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextColor3 = config.uiTheme.subText
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = row

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -24, 0, 8)
	track.Position = UDim2.new(0, 12, 0, 36)
	track.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	track.BorderSizePixel = 0
	track.Active = true
	track.Parent = row

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = config.uiTheme.accent
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = UDim2.new(1, -8, 0.5, -8)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = fill

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local function setValue(value: number, silent: boolean?)
		value = math.clamp(value, min, max)
		local alpha = (value - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		valueLabel.Text = tostring(math.floor(value + 0.5))
		if not silent then
			callback(value)
		end
	end

	local function updateFromInput(inputX: number)
		local absPos = track.AbsolutePosition.X
		local absSize = track.AbsoluteSize.X
		local alpha = math.clamp((inputX - absPos) / absSize, 0, 1)
		setValue(min + alpha * (max - min))
	end

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position.X)
		end
	end)

	table.insert(sliderConnections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position.X)
		end
	end))

	table.insert(sliderConnections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	row.Parent = contentFrame
	setValue(default, true)
	return row, setValue
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
local flyBodyGyro: BodyGyro? = nil
local flyConnection: RBXScriptConnection? = nil

local function setFly(enabled: boolean)
	state.fly = enabled
	local char = getCharacter()
	if not char then return end
	local humanoid = getHumanoid()

	if enabled then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Flying)
			humanoid.AutoRotate = false
		end

		if flyBodyVelocity then flyBodyVelocity:Destroy() end
		flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		flyBodyVelocity.Velocity = Vector3.zero
		flyBodyVelocity.Parent = hrp

		if flyBodyGyro then flyBodyGyro:Destroy() end
		flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		flyBodyGyro.P = 10000
		flyBodyGyro.CFrame = hrp.CFrame
		flyBodyGyro.Parent = hrp

		flyConnection = RunService.RenderStepped:Connect(function()
			if not flyBodyVelocity or not flyBodyVelocity.Parent then return end
			local camera = workspace.CurrentCamera
			local h = getHumanoid()
			if h and h:GetState() ~= Enum.HumanoidStateType.Flying then
				h:ChangeState(Enum.HumanoidStateType.Flying)
			end
			local direction = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(config.flyUpKey) then direction += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(config.flyDownKey) then direction -= Vector3.new(0, 1, 0) end

			if direction.Magnitude > 0 then
				direction = direction.Unit * liveValues.flySpeed
			end
			flyBodyVelocity.Velocity = direction

			if flyBodyGyro and flyBodyGyro.Parent then
				flyBodyGyro.CFrame = camera.CFrame
			end
		end)
	else
		if flyBodyVelocity then flyBodyVelocity:Destroy() end
		flyBodyVelocity = nil
		if flyBodyGyro then flyBodyGyro:Destroy() end
		flyBodyGyro = nil
		if flyConnection then flyConnection:Disconnect() end
		flyConnection = nil
		if humanoid then
			humanoid.AutoRotate = true
		end
	end
end

-- Walk Speed
local walkSpeedConnection: RBXScriptConnection? = nil

local function applyWalkSpeed()
	local humanoid = getHumanoid()
	if humanoid and humanoid.WalkSpeed ~= liveValues.walkSpeed then
		humanoid.WalkSpeed = liveValues.walkSpeed
	end
end

local function setWalkSpeed(value: number)
	liveValues.walkSpeed = value
	if walkSpeedConnection then walkSpeedConnection:Disconnect() end
	applyWalkSpeed()
	if value ~= 16 then
		walkSpeedConnection = RunService.RenderStepped:Connect(applyWalkSpeed)
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

-- Jump Power
local jumpPowerConnection: RBXScriptConnection? = nil

local function applyJumpPower()
	local humanoid = getHumanoid()
	if not humanoid then return end

	if humanoid.UseJumpPower then
		if humanoid.JumpPower ~= liveValues.jumpPower then
			humanoid.JumpPower = liveValues.jumpPower
		end
	else
		local targetHeight = liveValues.jumpHeight * (liveValues.jumpPower / 50)
		if humanoid.JumpHeight ~= targetHeight then
			humanoid.JumpHeight = targetHeight
		end
	end
end

local function setJumpPower(value: number)
	liveValues.jumpPower = value
	if jumpPowerConnection then jumpPowerConnection:Disconnect() end
	applyJumpPower()
	if value ~= 50 then
		jumpPowerConnection = RunService.RenderStepped:Connect(applyJumpPower)
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
local function refreshEspFor(targetPlayer: Player)
	if targetPlayer == player then return end

	local data = espObjects[targetPlayer]
	if not data then
		data = {
			billboard = nil,
			nameLabel = nil,
			healthLabel = nil,
			healthConnection = nil,
			highlight = nil,
			connections = {},
		}
		espObjects[targetPlayer] = data

		local function updateHealth(humanoid: Humanoid)
			if data.healthLabel then
				local health = math.floor(humanoid.Health + 0.5)
				local maxHealth = math.floor(humanoid.MaxHealth + 0.5)
				data.healthLabel.Text = health .. " / " .. maxHealth
				local ratio = health / maxHealth
				local color = Color3.fromRGB(255, 255, 255)
				if ratio > 0.6 then
					color = Color3.fromRGB(100, 255, 100)
				elseif ratio > 0.3 then
					color = Color3.fromRGB(255, 255, 100)
				else
					color = Color3.fromRGB(255, 100, 100)
				end
				data.healthLabel.TextColor3 = color
			end
		end

		local function onCharacterAdded(char: Model)
			local head = char:WaitForChild("Head", 5)
			if head then
				if data.billboard and data.billboard.Parent then
					data.billboard:Destroy()
				end
				if data.healthConnection then
					data.healthConnection:Disconnect()
					data.healthConnection = nil
				end

				local billboard = Instance.new("BillboardGui")
				billboard.Name = "AdminNameEsp"
				billboard.Adornee = head
				billboard.Size = UDim2.new(0, 120, 0, 60)
				billboard.StudsOffset = Vector3.new(0, 2.5, 0)
				billboard.AlwaysOnTop = true

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "NameLabel"
				nameLabel.Size = UDim2.new(1, 0, 0, 22)
				nameLabel.Position = UDim2.new(0, 0, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = targetPlayer.Name
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.TextStrokeTransparency = 0.5
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextSize = 14
				nameLabel.Parent = billboard
				data.nameLabel = nameLabel

				local healthLabel = Instance.new("TextLabel")
				healthLabel.Name = "HealthLabel"
				healthLabel.Size = UDim2.new(1, 0, 0, 18)
				healthLabel.Position = UDim2.new(0, 0, 0, 20)
				healthLabel.BackgroundTransparency = 1
				healthLabel.Text = "? / ?"
				healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				healthLabel.TextStrokeTransparency = 0.5
				healthLabel.Font = Enum.Font.GothamBold
				healthLabel.TextSize = 12
				healthLabel.Parent = billboard
				data.healthLabel = healthLabel

				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					updateHealth(humanoid)
					data.healthConnection = humanoid.HealthChanged:Connect(function()
						updateHealth(humanoid)
					end)
				end

				billboard.Parent = head
				data.billboard = billboard
				if not state.nameEsp then
					billboard.Enabled = false
				end
			end

			if data.highlight and data.highlight.Parent then
				data.highlight:Destroy()
			end

			local highlight = Instance.new("Highlight")
			highlight.Name = "AdminBoxEsp"
			highlight.Adornee = char
			highlight.FillColor = config.uiTheme.accent
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.6
			highlight.OutlineTransparency = 0
			highlight.Parent = char
			data.highlight = highlight
			if not state.boxEsp then
				highlight.Enabled = false
			end
		end

		local function onCharacterRemoving(char: Model)
			if data.billboard and data.billboard.Parent then
				data.billboard:Destroy()
				data.billboard = nil
				data.nameLabel = nil
				data.healthLabel = nil
			end
			if data.healthConnection then
				data.healthConnection:Disconnect()
				data.healthConnection = nil
			end
			if data.highlight and data.highlight.Parent then
				data.highlight:Destroy()
				data.highlight = nil
			end
		end

		if targetPlayer.Character then
			onCharacterAdded(targetPlayer.Character)
		end

		data.connections.added = targetPlayer.CharacterAdded:Connect(onCharacterAdded)
		data.connections.removing = targetPlayer.CharacterRemoving:Connect(onCharacterRemoving)
	else
		if data.billboard then
			data.billboard.Enabled = state.nameEsp
		end
		if data.highlight then
			data.highlight.Enabled = state.boxEsp
		end
	end
end

local function removeEspFor(targetPlayer: Player)
	local data = espObjects[targetPlayer]
	if not data then return end

	if data.billboard and data.billboard.Parent then
		data.billboard:Destroy()
	end
	if data.healthConnection then
		data.healthConnection:Disconnect()
	end
	if data.highlight and data.highlight.Parent then
		data.highlight:Destroy()
	end

	for _, conn in pairs(data.connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end

	espObjects[targetPlayer] = nil
end

local function updateAllEsp()
	for _, target in pairs(Players:GetPlayers()) do
		refreshEspFor(target)
	end
end

local function setNameEsp(enabled: boolean)
	state.nameEsp = enabled
	updateAllEsp()

	if enabled then
		if not connections.espAdded then
			connections.espAdded = Players.PlayerAdded:Connect(refreshEspFor)
		end
		if not connections.espRemoving then
			connections.espRemoving = Players.PlayerRemoving:Connect(removeEspFor)
		end
	else
		local anyEsp = state.boxEsp
		if not anyEsp then
			if connections.espAdded then connections.espAdded:Disconnect() end
			if connections.espRemoving then connections.espRemoving:Disconnect() end
			connections.espAdded = nil
			connections.espRemoving = nil
		end
	end
end

local function setBoxEsp(enabled: boolean)
	state.boxEsp = enabled
	updateAllEsp()

	if enabled then
		if not connections.espAdded then
			connections.espAdded = Players.PlayerAdded:Connect(refreshEspFor)
		end
		if not connections.espRemoving then
			connections.espRemoving = Players.PlayerRemoving:Connect(removeEspFor)
		end
	else
		local anyEsp = state.nameEsp
		if not anyEsp then
			if connections.espAdded then connections.espAdded:Disconnect() end
			if connections.espRemoving then connections.espRemoving:Disconnect() end
			connections.espAdded = nil
			connections.espRemoving = nil
		end
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

-- FOV
local fovConnection: RBXScriptConnection? = nil

local function applyFov()
	local camera = workspace.CurrentCamera
	if camera and camera.FieldOfView ~= liveValues.fov then
		camera.FieldOfView = liveValues.fov
	end
end

local function setFov(value: number)
	liveValues.fov = value
	if fovConnection then fovConnection:Disconnect() end
	applyFov()
	if value ~= 70 then
		fovConnection = RunService.RenderStepped:Connect(applyFov)
	end
end

-- Hitbox Expander
local hitboxObjects: { [Player]: { parts: { BasePart }, originalSizes: { [BasePart]: Vector3 }, expandedSizes: { [BasePart]: Vector3 }, scaleFactor: number, connections: { [string]: RBXScriptConnection } } } = {}

local function applyHitboxToCharacter(char: Model, data)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp or not hrp:IsA("BasePart") then return end

	-- Remove old generated parts if any
	for _, old in ipairs(data.parts) do
		if old and old.Parent then
			old:Destroy()
		end
	end
	data.parts = {}

	-- Create a large sphere around the character (secondary hitbox)
	local sphere = Instance.new("Part")
	sphere.Name = "ExpandedHitbox"
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(liveValues.hitboxSize, liveValues.hitboxSize, liveValues.hitboxSize)
	sphere.Transparency = 0.9
	sphere.CanCollide = false
	sphere.CanQuery = true
	sphere.CanTouch = true
	sphere.Massless = true
	sphere.CollisionGroupId = hrp.CollisionGroupId
	sphere.Parent = char

	local weld = Instance.new("Weld")
	weld.Part0 = sphere
	weld.Part1 = hrp
	weld.C0 = CFrame.new(0, 0, 0)
	weld.Parent = sphere

	table.insert(data.parts, sphere)

	-- Resize every BasePart in the character to make bullets/projectiles much more likely to hit
	data.scaleFactor = math.clamp(liveValues.hitboxSize / 5, 1.5, 5)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if not data.originalSizes[part] then
				data.originalSizes[part] = part.Size
			end
			data.expandedSizes[part] = part.Size * data.scaleFactor
			part.Size = data.expandedSizes[part]
			part.Transparency = math.min(part.Transparency + 0.3, 0.9)
		end
	end

	-- Resize any parts that load in later
	data.connections.descendantAdded = char.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and not data.originalSizes[descendant] then
			data.originalSizes[descendant] = descendant.Size
			data.expandedSizes[descendant] = descendant.Size * data.scaleFactor
			descendant.Size = data.expandedSizes[descendant]
			descendant.Transparency = math.min(descendant.Transparency + 0.3, 0.9)
		end
	end)

	-- Continuously re-apply sizes in case the game tries to revert them
	data.connections.enforce = RunService.Heartbeat:Connect(function()
		for part, target in pairs(data.expandedSizes) do
			if part and part.Parent and part.Size ~= target then
				part.Size = target
			end
		end
	end)
end

local function restoreHitboxFor(data)
	if data.connections.descendantAdded then
		data.connections.descendantAdded:Disconnect()
		data.connections.descendantAdded = nil
	end
	if data.connections.enforce then
		data.connections.enforce:Disconnect()
		data.connections.enforce = nil
	end
	for part, original in pairs(data.originalSizes) do
		if part and part.Parent then
			part.Size = original
		end
	end
	data.originalSizes = {}
	data.expandedSizes = {}
	for _, part in ipairs(data.parts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	data.parts = {}
end

local function createHitboxFor(targetPlayer: Player)
	if targetPlayer == player then return end
	if hitboxObjects[targetPlayer] then return end

	local data = {
		parts = {},
		originalSizes = {},
		expandedSizes = {},
		scaleFactor = 1,
		connections = {},
	}

	local function onCharacterAdded(char: Model)
		restoreHitboxFor(data)
		applyHitboxToCharacter(char, data)
	end

	local function onCharacterRemoving(char: Model)
		restoreHitboxFor(data)
	end

	if targetPlayer.Character then
		onCharacterAdded(targetPlayer.Character)
	end

	data.connections.added = targetPlayer.CharacterAdded:Connect(onCharacterAdded)
	data.connections.removing = targetPlayer.CharacterRemoving:Connect(onCharacterRemoving)
	hitboxObjects[targetPlayer] = data
end

local function removeHitboxFor(targetPlayer: Player)
	local data = hitboxObjects[targetPlayer]
	if not data then return end

	restoreHitboxFor(data)
	for _, conn in pairs(data.connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end

	hitboxObjects[targetPlayer] = nil
end

local function updateAllHitboxes()
	for targetPlayer, data in pairs(hitboxObjects) do
		if targetPlayer.Character then
			restoreHitboxFor(data)
			applyHitboxToCharacter(targetPlayer.Character, data)
		end
	end
end

local function setHitboxExpander(enabled: boolean)
	state.hitboxExpander = enabled
	if enabled then
		for _, target in pairs(Players:GetPlayers()) do
			createHitboxFor(target)
		end
		connections.hitboxAdded = Players.PlayerAdded:Connect(createHitboxFor)
		connections.hitboxRemoving = Players.PlayerRemoving:Connect(removeHitboxFor)
	else
		for _, target in pairs(Players:GetPlayers()) do
			removeHitboxFor(target)
		end
		if connections.hitboxAdded then connections.hitboxAdded:Disconnect() end
		if connections.hitboxRemoving then connections.hitboxRemoving:Disconnect() end
		connections.hitboxAdded = nil
		connections.hitboxRemoving = nil
	end
end

local function setHitboxSize(value: number)
	liveValues.hitboxSize = value
	updateAllHitboxes()
end

-- Player Teleport
local function teleportToNearestPlayer()
	local char = getCharacter()
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		notify("No character found")
		return
	end

	local myPos = hrp.Position
	local nearest: Player? = nil
	local nearestDist = math.huge

	for _, target in pairs(Players:GetPlayers()) do
		if target == player then continue end
		local targetChar = target.Character
		local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		if targetHrp and targetHrp:IsA("BasePart") then
			local dist = (targetHrp.Position - myPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = target
			end
		end
	end

	if nearest and nearest.Character then
		local targetHrp = nearest.Character:FindFirstChild("HumanoidRootPart")
		if targetHrp and targetHrp:IsA("BasePart") then
			hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
			notify("Teleported to " .. nearest.Name)
		end
	else
		notify("No nearby player found")
	end
end

-- Reset Character
local function resetCharacter()
	local char = getCharacter()
	if char then
		char:BreakJoints()
		notify("Character reset")
	end
end

-- Aimbot
local aimbotConnection: RBXScriptConnection? = nil

local function getClosestPlayerForAimbot(): Player?
	local camera = workspace.CurrentCamera
	local closest: Player? = nil
	local closestDist = math.huge

	for _, target in pairs(Players:GetPlayers()) do
		if target == player then continue end
		local targetChar = target.Character
		if not targetChar then continue end

		local targetPart = targetChar:FindFirstChild(config.aimbotPart)
		if not targetPart or not targetPart:IsA("BasePart") then
			targetPart = targetChar:FindFirstChild("Head")
		end
		if not targetPart or not targetPart:IsA("BasePart") then
			targetPart = targetChar:FindFirstChild("HumanoidRootPart")
		end
		if not targetPart or not targetPart:IsA("BasePart") then continue end

		local dist = (targetPart.Position - camera.CFrame.Position).Magnitude
		if dist < closestDist and dist <= liveValues.aimbotRange then
			closestDist = dist
			closest = target
		end
	end

	return closest
end

local function setAimbot(enabled: boolean)
	state.aimbot = enabled
	if aimbotConnection then aimbotConnection:Disconnect() end

	if enabled then
		aimbotConnection = RunService.RenderStepped:Connect(function()
			local camera = workspace.CurrentCamera
			local target = getClosestPlayerForAimbot()
			if target and target.Character then
				local targetPart = target.Character:FindFirstChild(config.aimbotPart)
				if not targetPart or not targetPart:IsA("BasePart") then
					targetPart = target.Character:FindFirstChild("Head")
				end
				if not targetPart or not targetPart:IsA("BasePart") then
					targetPart = target.Character:FindFirstChild("HumanoidRootPart")
				end
				if targetPart and targetPart:IsA("BasePart") then
					local targetCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
					local alpha = math.clamp(liveValues.aimbotSpeed / 100, 0.01, 1)
					camera.CFrame = camera.CFrame:Lerp(targetCFrame, alpha)
				end
			end
		end)
	end
end

local function setAimbotRange(value: number)
	liveValues.aimbotRange = value
end

local function setAimbotSpeed(value: number)
	liveValues.aimbotSpeed = value
end

-- Panic: disable everything
local function panic()
	setFly(false)
	setInfiniteJump(false)
	setNoClip(false)
	setClickTeleport(false)
	setNameEsp(false)
	setBoxEsp(false)
	setFullBright(false)
	setLowGravity(false)
	setHitboxExpander(false)
	setAimbot(false)

	sliderSetters.walkSpeed(16)
	sliderSetters.jumpPower(50)
	sliderSetters.flySpeed(50)
	sliderSetters.fov(70)
	sliderSetters.hitboxSize(10)
	sliderSetters.aimbotRange(200)
	sliderSetters.aimbotSpeed(50)

	notify("All features disabled")
end

-- Build UI toggles
makeToggle("Fly", "WASD + Q/E or Space/Shift", setFly)
local _, setFlySpeedSlider = makeSlider("Fly Speed", "Set your fly speed", 10, 200, 50, function(value)
	liveValues.flySpeed = value
end)
sliderSetters.flySpeed = setFlySpeedSlider
local _, setWalkSpeedSlider = makeSlider("Walk Speed", "Set your walk speed (higher = higher ban risk)", 16, 200, 16, setWalkSpeed)
sliderSetters.walkSpeed = setWalkSpeedSlider
makeToggle("Infinite Jump", "Jump anywhere, anytime", setInfiniteJump)
local _, setJumpPowerSlider = makeSlider("Jump Power", "Set your jump power", 50, 200, 50, setJumpPower)
sliderSetters.jumpPower = setJumpPowerSlider
makeToggle("NoClip", "Walk through walls", setNoClip)
makeToggle("Click Teleport", "Click to teleport", setClickTeleport)
makeButton("Player Teleport", "Teleport to nearest player", "Go", teleportToNearestPlayer)
makeToggle("Name ESP", "See player names and health", setNameEsp)
makeToggle("Box ESP", "Highlight outline around players", setBoxEsp)
makeToggle("Full Bright", "Remove darkness", setFullBright)
makeToggle("Low Gravity", "Moon gravity", setLowGravity)
local _, setFovSlider = makeSlider("FOV", "Set camera field of view", 70, 140, 70, setFov)
sliderSetters.fov = setFovSlider
makeToggle("Hitbox Expander", "Expand player hitboxes", setHitboxExpander)
local _, setHitboxSizeSlider = makeSlider("Hitbox Size", "Set expanded hitbox size", 2, 50, 10, setHitboxSize)
sliderSetters.hitboxSize = setHitboxSizeSlider
makeToggle("Aimbot", "Auto aim at nearest player", setAimbot)
local _, setAimbotRangeSlider = makeSlider("Aimbot Range", "Max lock-on distance", 10, 1000, 200, setAimbotRange)
sliderSetters.aimbotRange = setAimbotRangeSlider
local _, setAimbotSpeedSlider = makeSlider("Aimbot Speed", "Snap speed (1-100)", 1, 100, 50, setAimbotSpeed)
sliderSetters.aimbotSpeed = setAimbotSpeedSlider
makeButton("Reset Character", "Respawn your character", "Reset", resetCharacter)
makeButton("Panic", "Disable all features", "Stop", panic)

local disclaimerFrame = Instance.new("Frame")
disclaimerFrame.Name = "Disclaimer"
disclaimerFrame.Size = UDim2.new(1, 0, 0, 48)
disclaimerFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
disclaimerFrame.BorderSizePixel = 0
disclaimerFrame.LayoutOrder = #contentFrame:GetChildren() + 1
disclaimerFrame.Parent = contentFrame

local disclaimerCorner = Instance.new("UICorner")
disclaimerCorner.CornerRadius = UDim.new(0, 8)
disclaimerCorner.Parent = disclaimerFrame

local disclaimerStroke = Instance.new("UIStroke")
disclaimerStroke.Thickness = 1
disclaimerStroke.Color = Color3.fromRGB(80, 70, 70)
disclaimerStroke.Transparency = 0.6
disclaimerStroke.Parent = disclaimerFrame

local disclaimerLabel = Instance.new("TextLabel")
disclaimerLabel.Name = "DisclaimerText"
disclaimerLabel.Size = UDim2.new(1, -16, 1, -12)
disclaimerLabel.Position = UDim2.new(0, 8, 0, 6)
disclaimerLabel.BackgroundTransparency = 1
disclaimerLabel.Text = "Use at your own risk. Higher speeds and blatant features increase ban chance.\nCredits: @katowice00 on Telegram"
disclaimerLabel.Font = Enum.Font.Gotham
disclaimerLabel.TextSize = 11
disclaimerLabel.TextColor3 = config.uiTheme.subText
disclaimerLabel.TextWrapped = true
disclaimerLabel.TextYAlignment = Enum.TextYAlignment.Center
disclaimerLabel.Parent = disclaimerFrame

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

connections.drag = UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging and startPos then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Open / close keybind
local minimized = false
local function togglePanel()
	if minimized then
		minimized = false
		minimizeButton.Text = "-"
		mainFrame.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 420) }):Play()
	else
		mainFrame.Visible = not mainFrame.Visible
	end
end

connections.toggleKey = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == config.toggleKey then
		togglePanel()
	end
end)

minimizeButton.MouseButton1Click:Connect(function()
	if minimized then
		minimized = false
		minimizeButton.Text = "-"
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 420) }):Play()
	else
		minimized = true
		minimizeButton.Text = "+"
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 320, 0, 44) }):Play()
	end
end)

local function unload()
	panic()

	for _, conn in pairs(connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	for _, conn in ipairs(sliderConnections) do
		conn:Disconnect()
	end

	if flyBodyVelocity and flyBodyVelocity.Parent then
		flyBodyVelocity:Destroy()
	end
	if noClipOriginalStates then
		local char = getCharacter()
		if char then
			for part, original in pairs(noClipOriginalStates) do
				if part and part.Parent then
					part.CanCollide = original
				end
			end
		end
	end

	notify("Universal Script unloaded | @katowice00")
	task.delay(0.5, function()
		screenGui:Destroy()
	end)
end

closeButton.MouseButton1Click:Connect(unload)

-- Reset states on character respawn to avoid stuck physics
connections.characterAdded = player.CharacterAdded:Connect(function()
	task.wait(0.1)
	if state.fly then setFly(true) end
	if liveValues.walkSpeed ~= 16 then setWalkSpeed(liveValues.walkSpeed) end
	if liveValues.jumpPower ~= 50 then setJumpPower(liveValues.jumpPower) end
	if state.noClip then setNoClip(true) end
	if liveValues.fov ~= 70 then setFov(liveValues.fov) end
end)

-- Intro animation when the panel starts visible
if config.openOnStart then
	mainFrame.Size = UDim2.new(0, 320, 0, 0)
	mainFrame.Visible = true
	TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 320, 0, 420) }):Play()
end

notify("Universal Script loaded | @katowice00 on Telegram | RightShift to toggle")
