--[[
	Main.luau — executor entry point for the Blox Fruits AutoFarm
	==============================================================
	Run this with a Roblox executor:

	    loadstring(game:HttpGet(
	        "https://raw.githubusercontent.com/Katowice-public/public-admin/main/Main.luau"
	    ))()

	Main.luau fetches every module file from the GitHub repository over HTTP,
	loads each one with loadstring in dependency order, wires the shared
	environment together, and tells each feature module to register its GUI
	controls — exactly what the Studio LocalScript (Loader.luau) does, but
	without needing the files to be present in the game tree.

	All tuning lives in Modules/Config.luau on the repo. To point this loader at
	a different branch/fork, change BASE below.
]]

-- Raw-content base URL for the repo. Change the branch name to test a PR.
local BASE = "https://raw.githubusercontent.com/Katowice-public/public-admin/main/src"

-- HTTP fetch that works across most executors (game:HttpGet, then syn.request /
-- http_request fallbacks). Returns the response body or raises.
local function fetch(path: string): string
	local url = BASE .. "/" .. path

	local ok, body = pcall(function()
		if game and game.HttpGet then
			return game:HttpGet(url)
		end
		local request = (syn and syn.request) or http_request or (fluxus and fluxus.request)
		if request then
			local res = request({ Url = url, Method = "GET" })
			return res and res.Body
		end
		error("no HTTP function available (need game:HttpGet / syn.request / http_request)")
	end)
	if not ok or type(body) ~= "string" or body == "" then
		error("[BloxAutoFarm] failed to fetch " .. url .. ": " .. tostring(body))
	end
	return body
end

-- Load a module source from the repo and return its exported table.
local function loadModule(path: string)
	local src = fetch(path)
	local fn, err = loadstring(src, "@" .. path)
	if not fn then
		error("[BloxAutoFarm] compile error in " .. path .. ": " .. tostring(err))
	end
	local ok, result = pcall(fn)
	if not ok then
		error("[BloxAutoFarm] run error in " .. path .. ": " .. tostring(result))
	end
	return result
end

-- Dependency order matters: Config & Utils first, then UI, then features.
local Config = loadModule("Modules/Config.luau")
local Utils = loadModule("Modules/Utils.luau")
local UI = loadModule("Modules/UI.luau")

-- Route Utils.notify through the real GUI notifier.
Utils.setNotifier(function(text, color)
	UI.notify(text, color)
end)

-- Shared environment handed to every feature module's init().
local cleanup = {}
local env = {
	Config = Config,
	Utils = Utils,
	UI = UI,
	onUnload = nil,
}
env.onUnload = function()
	for _, c in ipairs(cleanup) do pcall(c) end
end

-- Feature modules to load. Add a new module here once it's pushed to the repo.
local featureModules = {
	"LevelFarm",
	"ChestFarm",
	"Misc",
}

for _, name in ipairs(featureModules) do
	local mod = loadModule("Modules/" .. name .. ".luau")
	if type(mod) == "table" and type(mod.init) == "function" then
		local ok, err = pcall(mod.init, env)
		if not ok then
			warn("[BloxAutoFarm] failed to load " .. name .. ": " .. tostring(err))
		end
	else
		warn("[BloxAutoFarm] " .. name .. " does not export init(env)")
	end
end

-- Bind the open / close key from Config (default RightShift).
local UserInputService = game:GetService("UserInputService")
local toggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Config.toggleKey then
		UI.toggleWindow()
	end
end)
table.insert(cleanup, function() toggleConn:Disconnect() end)

Utils.notify("Blox Fruits AutoFarm loaded (loadstring)", Color3.fromRGB(80, 200, 120))
