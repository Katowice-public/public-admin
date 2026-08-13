-- LevelFarm (ModuleScript)
-- Auto-attacks nearby enemies to grind XP/Beli.
-- Strategy: hover above the ground, pull the nearest matching NPC close, then
-- swing / fire the equipped weapon on a short cooldown.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LevelFarm = {}

-- Injected by init() before any farm loop runs.
local Utils

-- Find the nearest living NPC whose name matches `targetName`.
local function findTarget(targetName: string, maxLevel: number): Model?
	local closest, closestDist = nil, math.huge
	local playerPos = nil
	for _, model in ipairs(Workspace:GetDescendants()) do
		if model:IsA("Model") and model.Name == targetName then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local hrp = model:FindFirstChild("HumanoidRootPart")
			if humanoid and hrp and humanoid.Health > 0 then
				if maxLevel > 0 and humanoid:GetAttribute("Level") then
					local lvl = humanoid:GetAttribute("Level") :: number
					if lvl > maxLevel then continue end
				end
				local playerHrp = Utils.getHrp()
				if not playerHrp then return nil end
				playerPos = playerPos or playerHrp.Position
				local d = (hrp.Position - playerPos).Magnitude
				if d < closestDist then
					closest, closestDist = model, d
				end
			end
		end
	end
	return closest
end

function LevelFarm.init(env)
	Utils = env.Utils
	local Config, UI = env.Config, env.UI
	local cfg = Config.levelFarm

	local section = "Level Farm"
	UI.addSection(section)

	local running = false
	local thread: thread? = nil
	local hoverConn: RBXScriptConnection? = nil

	-- Live-tunable settings (updated by UI controls)
	local settings = {
		targetEnemy = cfg.targetEnemy,
		attackMethod = cfg.attackMethod,
		bringDistance = cfg.bringDistance,
		hoverHeight = cfg.hoverHeight,
		maxEnemyLevel = cfg.maxEnemyLevel,
	}

	UI.addDropdown(section, {
		name = "Target Enemy",
		desc = "Which NPC to farm",
		options = { "Bandit", "Monkey", "Gorilla", "Pirate", "Brute", "Galley Captain", "Marine Captain" },
		default = settings.targetEnemy,
		callback = function(v)
			settings.targetEnemy = v
		end,
	})

	UI.addDropdown(section, {
		name = "Attack Method",
		desc = "How to deal damage",
		options = { "Auto", "Melee", "Sword", "Gun", "Fruit" },
		default = settings.attackMethod,
		callback = function(v)
			settings.attackMethod = v
		end,
	})

	UI.addSlider(section, {
		name = "Bring Distance",
		desc = "Studs to pull the enemy to",
		min = 4, max = 40, step = 1,
		default = settings.bringDistance,
		callback = function(v)
			settings.bringDistance = v
		end,
	})

	UI.addSlider(section, {
		name = "Hover Height",
		desc = "Studs above ground while farming",
		min = 0, max = 40, step = 1,
		default = settings.hoverHeight,
		callback = function(v)
			settings.hoverHeight = v
		end,
	})

	UI.addSlider(section, {
		name = "Max Enemy Level",
		desc = "0 = ignore level cap",
		min = 0, max = 3000, step = 50,
		default = settings.maxEnemyLevel,
		callback = function(v)
			settings.maxEnemyLevel = v
		end,
	})

	local function attack(target: Model)
		local hrp = target:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end
		local playerHrp = Utils.getHrp()
		if not playerHrp then return end

		-- Face the enemy
		playerHrp.CFrame = CFrame.lookAt(playerHrp.Position, Vector3.new(hrp.Position.X, playerHrp.Position.Y, hrp.Position.Z))

		local method = settings.attackMethod
		if method == "Auto" or method == "Melee" then
			Utils.virtualClick()
		elseif method == "Sword" or method == "Gun" then
			-- Equip the first matching tool, then click.
			local char = Utils.getCharacter()
			if char then
				local backpack = Utils.getPlayer():FindFirstChildOfClass("Backpack")
				local tool = backpack and backpack:FindFirstChildOfClass("Tool")
				if tool then
					local humanoid = Utils.getHumanoid()
					if humanoid then humanoid:EquipTool(tool) end
				end
			end
			Utils.virtualClick()
		elseif method == "Fruit" then
			local remote = Utils.getCombatRemote()
			if remote then
				pcall(function()
					remote:FireServer("Attack", hrp.Position)
				end)
			else
				Utils.virtualClick()
			end
		end
	end

	local function farmLoop()
		while running do
			if not Utils.isAlive() then
				task.wait(0.5)
				continue
			end

			local target = findTarget(settings.targetEnemy, settings.maxEnemyLevel)
			if target then
				local hrp = target:FindFirstChild("HumanoidRootPart") :: BasePart?
				local playerHrp = Utils.getHrp()
				if hrp and playerHrp then
					-- Pull the enemy to just in front of the player
					local bringPos = playerHrp.Position + playerHrp.CFrame.LookVector * settings.bringDistance
					hrp.CFrame = CFrame.new(bringPos)
					-- Hover above ground
					if settings.hoverHeight > 0 then
						local groundY = playerHrp.Position.Y
						playerHrp.CFrame = CFrame.new(playerHrp.Position.X, groundY + settings.hoverHeight, playerHrp.Position.Z)
					end
					attack(target)
				end
			end
			task.wait(cfg.attackCooldown)
		end
	end

	UI.addToggle(section, {
		name = "Level Farm",
		desc = "Grind the selected enemy for XP",
		default = false,
		callback = function(on)
			running = on
			if on then
				Utils.notify("Level Farm started: " .. settings.targetEnemy)
				thread = task.spawn(farmLoop)
			else
				Utils.notify("Level Farm stopped")
			end
		end,
	})
end

return LevelFarm
