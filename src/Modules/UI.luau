-- UI (ModuleScript)
-- Builds the main GUI and exposes a small API the Loader passes to each
-- feature module so they can register their own controls.
--
-- Returned API:
--   UI.addSection(name)            -> sectionName
--   UI.addToggle(section, opts)    -> row   (opts: name, desc, default, callback)
--   UI.addSlider(section, opts)    -> row   (opts: name, desc, min, max, default, step, callback)
--   UI.addDropdown(section, opts)  -> row   (opts: name, desc, options, default, callback)
--   UI.addButton(section, opts)    -> row   (opts: name, label, color, callback)
--   UI.notify(text, color?)        -> nil
--   UI.setToggleState(row, on)     -> nil

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI = {}

local function new(className: string, props: { [string]: any }): Instance
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local theme = {
	background = Color3.fromRGB(28, 28, 34),
	panel = Color3.fromRGB(40, 40, 48),
	accent = Color3.fromRGB(88, 101, 242),
	accentDark = Color3.fromRGB(60, 70, 200),
	text = Color3.fromRGB(255, 255, 255),
	subText = Color3.fromRGB(170, 170, 180),
	toggleOff = Color3.fromRGB(60, 60, 68),
	toggleOn = Color3.fromRGB(88, 101, 242),
	danger = Color3.fromRGB(235, 80, 80),
}

local screenGui = new("ScreenGui", {
	Name = "BloxAutoFarmGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

local mainFrame = new("Frame", {
	Name = "MainFrame",
	Size = UDim2.new(0, 460, 0, 360),
	Position = UDim2.new(0.5, -230, 0.5, -180),
	BackgroundColor3 = theme.background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = screenGui,
})
corner(mainFrame, 12)

local titleBar = new("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = theme.accent,
	BorderSizePixel = 0,
	Parent = mainFrame,
})
corner(titleBar, 12)

new("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -120, 1, 0),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "Blox Fruits AutoFarm",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = theme.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBar,
})

local minimizeBtn = new("TextButton", {
	Name = "Minimize",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -68, 0, 6),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.85,
	Text = "-",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = theme.text,
	AutoButtonColor = false,
	Parent = titleBar,
})
corner(minimizeBtn, 6)

local closeBtn = new("TextButton", {
	Name = "Close",
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -36, 0, 6),
	BackgroundColor3 = theme.danger,
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = theme.text,
	AutoButtonColor = false,
	Parent = titleBar,
})
corner(closeBtn, 6)

local sidebar = new("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 120, 1, -40),
	Position = UDim2.new(0, 0, 0, 40),
	BackgroundColor3 = theme.background,
	BorderSizePixel = 0,
	Parent = mainFrame,
})

local sidebarLayout = new("UIListLayout", {
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = sidebar,
})

new("UIPadding", {
	PaddingTop = UDim.new(0, 10),
	Parent = sidebar,
})

local contentArea = new("Frame", {
	Name = "ContentArea",
	Size = UDim2.new(1, -120, 1, -40),
	Position = UDim2.new(0, 120, 0, 40),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = mainFrame,
})

local sections = {}
local activeSection = nil

local function showSection(name: string)
	local target = sections[name]
	if not target then return end
	for n, data in pairs(sections) do
		data.scroll.Visible = (n == name)
		data.button.BackgroundColor3 = (n == name) and theme.accent or theme.panel
	end
	activeSection = name
end

function UI.addSection(name: string): string
	local btn = new("TextButton", {
		Name = name .. "Btn",
		Size = UDim2.new(1, -16, 0, 32),
		BackgroundColor3 = theme.panel,
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = theme.text,
		AutoButtonColor = false,
		Parent = sidebar,
	})
	corner(btn, 6)

	local scroll = new("ScrollingFrame", {
		Name = name .. "Content",
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = contentArea,
	})

	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})

	sections[name] = { button = btn, scroll = scroll }
	btn.MouseButton1Click:Connect(function()
		showSection(name)
	end)

	if activeSection == nil then
		showSection(name)
	end
	return name
end

local function makeRow(parent: Instance, height: number): Frame
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = theme.panel,
		BorderSizePixel = 0,
		Parent = parent,
	})
	corner(row, 8)
	return row
end

local function makeLabels(row: Instance, name: string, desc: string?)
	new("TextLabel", {
		Size = UDim2.new(1, -90, 0, 20),
		Position = UDim2.new(0, 12, 0, 8),
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	if desc then
		new("TextLabel", {
			Size = UDim2.new(1, -90, 0, 16),
			Position = UDim2.new(0, 12, 0, 28),
			BackgroundTransparency = 1,
			Text = desc,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = theme.subText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
	end
end

function UI.addToggle(section: string, opts: { [string]: any }): Frame
	local data = sections[section]
	assert(data, "Unknown section: " .. tostring(section))

	local row = makeRow(data.scroll, 56)
	makeLabels(row, opts.name, opts.desc)

	local toggleBtn = new("TextButton", {
		Size = UDim2.new(0, 52, 0, 28),
		Position = UDim2.new(1, -64, 0, 14),
		BackgroundColor3 = theme.toggleOff,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	corner(toggleBtn, 14)

	local knob = new("Frame", {
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(0, 3, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleBtn,
	})
	corner(knob, 11)

	local state = opts.default == true
	local updating = false

	local function render()
		updating = true
		local color = state and theme.toggleOn or theme.toggleOff
		local pos = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
		TweenService:Create(toggleBtn, TweenInfo.new(0.18), { BackgroundColor3 = color }):Play()
		TweenService:Create(knob, TweenInfo.new(0.18), { Position = pos }):Play()
		updating = false
	end

	toggleBtn.MouseButton1Click:Connect(function()
		if updating then return end
		state = not state
		render()
		if opts.callback then
			task.spawn(opts.callback, state)
		end
	end)

	render()

	row._set = function(on: boolean)
		state = on
		render()
		if opts.callback then
			task.spawn(opts.callback, state)
		end
	end

	return row
end

function UI.setToggleState(row: Frame, on: boolean)
	if row and row._set then
		row._set(on)
	end
end

function UI.addSlider(section: string, opts: { [string]: any }): Frame
	local data = sections[section]
	assert(data, "Unknown section: " .. tostring(section))

	local row = makeRow(data.scroll, 60)
	makeLabels(row, opts.name, opts.desc)

	local track = new("Frame", {
		Size = UDim2.new(1, -24, 0, 8),
		Position = UDim2.new(0, 12, 1, -14),
		BackgroundColor3 = Color3.fromRGB(60, 60, 68),
		BorderSizePixel = 0,
		Parent = row,
	})
	corner(track, 4)

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = theme.accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 4)

	local valueLabel = new("TextLabel", {
		Size = UDim2.new(0, 60, 0, 16),
		Position = UDim2.new(1, -72, 0, 8),
		BackgroundTransparency = 1,
		Text = tostring(opts.default or opts.min or 0),
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	local min = opts.min or 0
	local max = opts.max or 100
	local step = opts.step or 1
	local value = opts.default or min

	local function setValue(v: number)
		v = math.clamp(v, min, max)
		if step and step > 0 then
			v = math.floor((v - min) / step + 0.5) * step + min
		end
		value = v
		local pct = (v - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		valueLabel.Text = tostring(v)
		if opts.callback then
			task.spawn(opts.callback, v)
		end
	end

	local dragging = false
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setValue(min + rel * (max - min))
		end
	end)

	setValue(value)
	return row
end

function UI.addDropdown(section: string, opts: { [string]: any }): Frame
	local data = sections[section]
	assert(data, "Unknown section: " .. tostring(section))

	local row = makeRow(data.scroll, 56)
	makeLabels(row, opts.name, opts.desc)

	local current = opts.default or (opts.options and opts.options[1]) or ""

	local button = new("TextButton", {
		Size = UDim2.new(0, 120, 0, 28),
		Position = UDim2.new(1, -132, 0, 14),
		BackgroundColor3 = theme.panel,
		Text = tostring(current),
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = theme.text,
		AutoButtonColor = false,
		Parent = row,
	})
	corner(button, 6)

	local list = new("Frame", {
		Size = UDim2.new(0, 120, 0, #opts.options * 26),
		Position = UDim2.new(1, -132, 0, 44),
		BackgroundColor3 = theme.panel,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 10,
		Parent = row,
	})
	corner(list, 6)

	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		Parent = list,
	})

	for _, opt in ipairs(opts.options) do
		local item = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = theme.panel,
			Text = tostring(opt),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = theme.text,
			AutoButtonColor = false,
			Parent = list,
		})
		corner(item, 4)
		item.MouseButton1Click:Connect(function()
			current = opt
			button.Text = tostring(opt)
			list.Visible = false
			if opts.callback then
				task.spawn(opts.callback, opt)
			end
		end)
	end

	button.MouseButton1Click:Connect(function()
		list.Visible = not list.Visible
	end)

	return row
end

function UI.addButton(section: string, opts: { [string]: any }): Frame
	local data = sections[section]
	assert(data, "Unknown section: " .. tostring(section))

	local row = makeRow(data.scroll, 44)
	new("TextLabel", {
		Size = UDim2.new(1, -120, 0, 20),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundTransparency = 1,
		Text = opts.name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local btn = new("TextButton", {
		Size = UDim2.new(0, 90, 0, 28),
		Position = UDim2.new(1, -102, 0, 8),
		BackgroundColor3 = opts.color or theme.accent,
		Text = opts.label or "Run",
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = theme.text,
		AutoButtonColor = false,
		Parent = row,
	})
	corner(btn, 6)
	btn.MouseButton1Click:Connect(function()
		if opts.callback then
			task.spawn(opts.callback)
		end
	end)
	return row
end

function UI.notify(text: string, color: Color3?)
	task.spawn(function()
		local notice = new("TextLabel", {
			Size = UDim2.new(0, 240, 0, 36),
			Position = UDim2.new(0.5, -120, 0, -40),
			BackgroundColor3 = color or theme.accent,
			Text = text,
			Font = Enum.Font.GothamSemibold,
			TextSize = 14,
			TextColor3 = theme.text,
			Parent = screenGui,
		})
		corner(notice, 8)
		TweenService:Create(notice, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, -120, 0, 20) }):Play()
		task.wait(2.5)
		local out = TweenService:Create(notice, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, -120, 0, -40) })
		out:Play()
		out.Completed:Wait()
		notice:Destroy()
	end)
end

-- Draggable window
local dragging = false
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

UserInputService.InputChanged:Connect(function(input)
	if dragging and startPos and dragStart then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Minimize / close
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = true
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 460, 0, 40) })
	tween:Play()
	tween.Completed:Connect(function()
		if minimized then
			sidebar.Visible = false
			contentArea.Visible = false
		end
	end)
end)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Restore on title click when minimized
titleBar.MouseButton2Click:Connect(function()
	if minimized then
		minimized = false
		sidebar.Visible = true
		contentArea.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = UDim2.new(0, 460, 0, 360) }):Play()
	end
end)

function UI.toggleWindow()
	mainFrame.Visible = not mainFrame.Visible
end

function UI.getWindow(): ScreenGui
	return screenGui
end

return UI
