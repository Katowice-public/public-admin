--[[
	Loader (LocalScript) — Blox Fruits AutoFarm
	==========================================
	Place this LocalScript in StarterPlayerScripts.
	Put the Modules folder (with Config, Utils, UI, LevelFarm, ChestFarm, Misc)
	next to this script as a child Folder named "Modules".

	The Loader:
	  1. Requires every ModuleScript in order.
	  2. Wires the shared environment (Config / Utils / UI) together.
	  3. Tells each feature module to register its GUI controls.
	  4. Binds the open/close key (default RightShift, set in Config).

	Each feature module exposes `Module.init(env)` and registers its own
	toggles/sliders/buttons into the UI. The Loader never needs to know what
	a feature does — it just loads it.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Require order matters: Config & Utils first, then UI, then features.
local modules = script:WaitForChild("Modules")

local Config  = require(modules:WaitForChild("Config"))
local Utils  = require(modules:WaitForChild("Utils"))
local UI     = require(modules:WaitForChild("UI"))

-- Feature modules (add new ones here — that's the only change needed
-- to plug a new feature into the whole script).
local featureModules = {
	"LevelFarm",
	"ChestFarm",
	"Misc",
}

-- Shared environment handed to every feature module's init().
local env = {
	Config = Config,
	Utils = Utils,
	UI = UI,
	onUnload = nil, -- set below
}

-- Route Utils.notify through the real GUI notifier once UI is loaded.
Utils.setNotifier(function(text, color)
	UI.notify(text, color)
end)

-- Track every background thread / connection we create so unload can clean up.
local cleanup = {}

env.onUnload = function()
	for _, c in ipairs(cleanup) do
		pcall(c)
	end
end

-- Initialise each feature module.
for _, name in ipairs(featureModules) do
	local mod = require(modules:WaitForChild(name))
	if type(mod) == "table" and type(mod.init) == "function" then
		local ok, err = pcall(mod.init, env)
		if not ok then
			warn("[BloxAutoFarm] failed to load " .. name .. ": " .. tostring(err))
		end
	else
		warn("[BloxAutoFarm] " .. name .. " does not export init(env)")
	end
end

-- Toggle key (open / close the window).
local toggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Config.toggleKey then
		UI.toggleWindow()
	end
end)
table.insert(cleanup, function() toggleConn:Disconnect() end)

-- Re-arm fly/hover-style features on respawn is handled per-module; here we
-- just make sure the GUI persists across respawns (ResetOnSpawn is already off).
player.CharacterAdded:Connect(function()
	Utils.notify("AutoFarm ready — press RightShift", Color3.fromRGB(80, 200, 120))
end)

Utils.notify("Blox Fruits AutoFarm loaded", Color3.fromRGB(80, 200, 120))
