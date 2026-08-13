-- Config (ModuleScript)
-- Central configuration shared by every feature module.
-- Edit values here to change behaviour without touching the feature code.

local Config = {}

-- Global / UI
Config.toggleKey = Enum.KeyCode.RightShift
Config.openOnStart = false
Config.windowTitle = "Blox Fruits AutoFarm"

Config.uiTheme = {
	background = Color3.fromRGB(28, 28, 34),
	backgroundPanel = Color3.fromRGB(40, 40, 48),
	accent = Color3.fromRGB(88, 101, 242),
	accentDark = Color3.fromRGB(60, 70, 200),
	text = Color3.fromRGB(255, 255, 255),
	subText = Color3.fromRGB(170, 170, 180),
	toggleOff = Color3.fromRGB(60, 60, 68),
	toggleOn = Color3.fromRGB(88, 101, 242),
	danger = Color3.fromRGB(235, 80, 80),
	success = Color3.fromRGB(80, 200, 120),
}

-- Level Farm
Config.levelFarm = {
	-- Name of the enemy/NPC to farm. Use the exact in-game name (e.g. "Bandit", "Monkey", "Galley Captain").
	targetEnemy = "Bandit",
	-- How the bot attacks: "Melee", "Sword", "Gun", "Fruit", or "Auto" (uses whatever is equipped).
	attackMethod = "Auto",
	-- Bring enemies within this many studs of the player before attacking.
	bringDistance = 14,
	-- Keep the player this many studs above the ground while farming (avoids most melee hits).
	hoverHeight = 8,
	-- Re-target a new enemy if the current one has not died within this many seconds.
	targetTimeout = 12,
	-- Only attack enemies whose level is <= this value (0 = unlimited).
	maxEnemyLevel = 0,
	-- Loop delay between attack attempts (seconds).
	attackCooldown = 0.15,
}

-- Chest / Coin Farm
Config.chestFarm = {
	-- Seconds between collection sweeps.
	collectInterval = 0.75,
	-- Maximum distance (studs) to teleport a chest/coin from the player.
	maxGrabRadius = 4000,
	-- Store collected Beli/Fragments in the in-game inventory automatically.
	autoStore = false,
	-- Also pick up dropped fruit / drops on the ground.
	grabDrops = true,
}

-- Misc / Other features
Config.misc = {
	-- Re-activate Observation Haki / Aura periodically.
	autoHaki = false,
	hakiInterval = 5,
	-- Hold to auto-swing the equipped weapon (good for grinding).
	autoClick = false,
	autoClickDelay = 0.05,
	-- Rejoin the same server if kicked / disconnected.
	autoRejoin = false,
	-- Strip heavy client-side effects to raise FPS.
	fpsBoost = false,
	-- Bring all nearby players to you (trolling). Off by default.
	auraBring = false,
}

return Config
