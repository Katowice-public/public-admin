-- ChestFarm (ModuleScript)
-- Sweeps the workspace for chests, Beli/Fragment pickups, and dropped fruit,
-- teleporting each one to the player so the client collects it instantly.

local Workspace = game:GetService("Workspace")

local ChestFarm = {}

-- Names Blox Fruits uses for grabbable objects.
local GRAB_NAMES = {
	["Chest"] = true,
	["Chest1"] = true,
	["Chest2"] = true,
	["Beli"] = true,
	["Fragments"] = true,
	["Drop"] = true,
	["Fruit"] = true,
	["Devil Fruit"] = true,
	["Treasure"] = true,
}

local function isGrabbable(part: BasePart, grabDrops: boolean): boolean
	if not part:IsA("BasePart") then return false end
	if part.Name and GRAB_NAMES[part.Name] then
		-- Devil Fruit meshes are usually named "Fruit" or "Devil Fruit"; skip player parts.
		if not grabDrops and (part.Name == "Fruit" or part.Name == "Devil Fruit" or part.Name == "Drop") then
			return false
		end
		return true
	end
	-- Many chests are stored as Models containing a "Chest" part.
	local model = part:FindFirstAncestorOfClass("Model")
	if model and (model.Name == "Chest" or model.Name:match("Chest")) then
		return true
	end
	return false
end

function ChestFarm.init(env)
	local Config, Utils, UI = env.Config, env.Utils, env.UI
	local cfg = Config.chestFarm

	local section = "Chest / Coin Farm"
	UI.addSection(section)

	local running = false
	local thread: thread? = nil

	local settings = {
		collectInterval = cfg.collectInterval,
		maxGrabRadius = cfg.maxGrabRadius,
		autoStore = cfg.autoStore,
		grabDrops = cfg.grabDrops,
	}

	UI.addSlider(section, {
		name = "Collect Interval",
		desc = "Seconds between sweeps",
		min = 0.1, max = 5, step = 0.1,
		default = settings.collectInterval,
		callback = function(v) settings.collectInterval = v end,
	})

	UI.addSlider(section, {
		name = "Grab Radius",
		desc = "Max studs to reach",
		min = 100, max = 10000, step = 100,
		default = settings.maxGrabRadius,
		callback = function(v) settings.maxGrabRadius = v end,
	})

	UI.addToggle(section, {
		name = "Grab Drops",
		desc = "Also pick up dropped fruit",
		default = settings.grabDrops,
		callback = function(v) settings.grabDrops = v end,
	})

	UI.addToggle(section, {
		name = "Auto Store",
		desc = "Store collected items in inventory",
		default = settings.autoStore,
		callback = function(v) settings.autoStore = v end,
	})

	local function sweep()
		local playerHrp = Utils.getHrp()
		if not playerHrp then return end
		local grabbed = 0
		for _, part in ipairs(Workspace:GetDescendants()) do
			if isGrabbable(part, settings.grabDrops) then
				local d = (part.Position - playerHrp.Position).Magnitude
				if d <= settings.maxGrabRadius then
					-- Teleport the object onto the player so the client auto-collects it.
					pcall(function()
						part.CFrame = CFrame.new(playerHrp.Position + Vector3.new(0, 2, 0))
					end)
					grabbed += 1
				end
			end
		end
		if grabbed > 0 and settings.autoStore then
			-- Best-effort: trigger the inventory store remote if present.
			pcall(function()
				local rs = game:GetService("ReplicatedStorage")
				local remote = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Store") or nil
				if remote and remote:IsA("RemoteEvent") then
					remote:FireServer("All")
				end
			end)
		end
	end

	local function loop()
		while running do
			if Utils.isAlive() then
				pcall(sweep)
			end
			task.wait(settings.collectInterval)
		end
	end

	UI.addToggle(section, {
		name = "Chest Farm",
		desc = "Auto-collect chests, coins & drops",
		default = false,
		callback = function(on)
			running = on
			if on then
				Utils.notify("Chest Farm started")
				thread = task.spawn(loop)
			else
				Utils.notify("Chest Farm stopped")
			end
		end,
	})
end

return ChestFarm
