#!/usr/bin/env bash
# Generates a single self-contained Luau test file that loads every module via
# loadstring + setfenv with a shared Roblox-stub environment, then runs the
# Loader flow end-to-end. Run with: bash test/gen.sh && /tmp/luau test/_combined.luau
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)/src"
OUT="$(dirname "$0")/_combined.luau"

{
cat <<'HEADER'
-- Auto-generated combined harness. Do not edit.
-- Stubs the Roblox API enough to run the Loader flow end-to-end under plain Luau.

local function makeSignal()
	local conns = {}
	local sig = {}
	function sig:Connect(cb) table.insert(conns, cb) return { Disconnect = function() end } end
	function sig:Wait() return nil end
	function sig:Fire(...) for _, cb in ipairs(conns) do pcall(cb, ...) end end
	return sig
end

local function makeInstance(className, name)
	local inst = {}
	inst._props = {}
	inst._children = {}
	inst.ClassName = className
	inst.Name = name or ""
	inst._props.Name = inst.Name
	inst._props.ClassName = className

	local methods = {
		FindFirstChild = function(self, n)
			for _, c in ipairs(self._children) do if c.Name == n then return c end end
			return nil
		end,
		WaitForChild = function(self, n, t)
			for _, c in ipairs(self._children) do if c.Name == n then return c end end
			return nil
		end,
		FindFirstChildOfClass = function(self, c)
			for _, ch in ipairs(self._children) do if ch.ClassName == c then return ch end end
			return nil
		end,
		FindFirstAncestorOfClass = function(self, c) return nil end,
		GetChildren = function(self) return self._children end,
		GetDescendants = function(self)
			local out = {}
			local function walk(p) for _, c in ipairs(p._children) do table.insert(out, c); walk(c) end end
			walk(self); return out
		end,
		IsA = function(self, c) return self.ClassName == c end,
		Destroy = function(self) end,
		SetAttribute = function(self, k, v) self._props["_attr_"..k] = v end,
		GetAttribute = function(self, k) return self._props["_attr_"..k] end,
		Connect = function(self, cb) return { Disconnect = function() end } end,
		EquipTool = function(self, t) end,
		ChangeState = function(self, s) end,
		CaptureController = function(self) end,
		Button1Down = function(self, x) end,
		Button1Up = function(self, x) end,
	}
	for k, v in pairs(methods) do inst[k] = v end
	for _, ev in ipairs({ "MouseButton1Click","MouseButton2Click","InputBegan","InputChanged","InputEnded","RenderStepped","Stepped","Heartbeat","JumpRequest","CharacterAdded","CharacterRemoving","PlayerAdded","PlayerRemoving" }) do
		inst[ev] = makeSignal()
	end
	setmetatable(inst, {
		__index = function(t, k)
			local p = rawget(t, "_props")
			if p and p[k] ~= nil then return p[k] end
			return rawget(t, k)
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then if v and v._children then table.insert(v._children, t) end; t._props[k] = v
			else t._props[k] = v end
		end,
	})
	return inst
end

-- shared environment every module runs in. Falls back to the real standard
-- library so modules keep access to pairs/print/pcall/task/etc.
local env = setmetatable({}, { __index = function(_, k) return _G[k] end })

env.Instance = { new = makeInstance }
env.Enum = setmetatable({}, { __index = function(_, k)
	return setmetatable({}, { __index = function(_, k2) return {} end })
end })
env.Color3 = { fromRGB = function(r, g, b) return { r = r, g = g, b = b } end, new = function() return {} end }
env.UDim2 = { new = function() return {} end }
env.UDim = { new = function() return {} end }
env.Vector2 = { new = function() return {} end }
env.Vector3 = { new = function() return { Magnitude = 0, Unit = { x = 0 } } end }
env.CFrame = { new = function() return { Position = { X = 0, Y = 0, Z = 0 } } end, lookAt = function() return { Position = { X = 0, Y = 0, Z = 0 } } end }
env.TweenInfo = { new = function() return {} end }

-- `task` library stub (this Luau CLI build doesn't expose it).
env.task = {
	spawn = function(f, ...)
		local co = coroutine.create(f)
		local ok, err = coroutine.resume(co, ...)
		if not ok then warn("[task.spawn] " .. tostring(err)) end
		return co
	end,
	wait = function() return 0 end,
	cancel = function(co) end,
}

local Lighting = makeInstance("Lighting", "Lighting")
local Workspace = makeInstance("Workspace", "Workspace")
local ReplicatedStorage = makeInstance("ReplicatedStorage", "ReplicatedStorage")
local UserInputService = makeInstance("UserInputService", "UserInputService")
local RunService = makeInstance("RunService", "RunService")
local VirtualUser = makeInstance("VirtualUser", "VirtualUser")
local VirtualInputManager = makeInstance("VirtualInputManager", "VirtualInputManager")
VirtualInputManager.SendKeyEvent = function() end
local TeleportService = makeInstance("TeleportService", "TeleportService")
TeleportService.Teleport = function() end
TeleportService.TeleportToPlaceInstance = function() end
local Players = makeInstance("Players", "Players")
Players.GetPlayers = function(self) return {} end
local player = makeInstance("Player", "LocalPlayer")
player.PlayerGui = makeInstance("PlayerGui", "PlayerGui")
player.GetMouse = function(self) return makeInstance("Mouse", "Mouse") end
player.Character = nil
Players.LocalPlayer = player

local game = setmetatable({
	JobId = "job-123",
	PlaceId = 12345,
	GetService = function(self, svc)
		if svc == "Players" then return Players
		elseif svc == "UserInputService" then return UserInputService
		elseif svc == "RunService" then return RunService
		elseif svc == "TweenService" then
			return { Create = function(self, obj, info, props)
				local t = { Completed = makeSignal() }; function t:Play() end; return t
			end }
		elseif svc == "Lighting" then return Lighting
		elseif svc == "Workspace" then return Workspace
		elseif svc == "ReplicatedStorage" then return ReplicatedStorage
		elseif svc == "VirtualUser" then return VirtualUser
		elseif svc == "VirtualInputManager" then return VirtualInputManager
		elseif svc == "TeleportService" then return TeleportService
		end
		return makeInstance(svc, svc)
	end,
}, { __index = function(_, k) return makeInstance(k, k) end })
env.game = game
env.workspace = Workspace

local MODS -- forward declaration so loadMod closes over the right variable

local function loadMod(name)
	local fn = loadstring(MODS[name], "@" .. name)
	assert(fn, "failed to compile " .. name)
	setfenv(fn, env)
	return fn()
end

HEADER

# Emit the MODS table containing each module's source.
echo "MODS = {}"
for f in Config Utils UI LevelFarm ChestFarm Misc; do
  echo "MODS[\"$f\"] = [==["
  cat "$SRC/Modules/$f.luau"
  echo "]==]"
done
# Main.luau lives at the repo root (the loadstring entry point).
echo "MODS[\"Main\"] = [==["
cat "$SRC/../Main.luau"
echo "]==]"

cat <<'FOOTER'
-- Run the Loader flow -------------------------------------------------------
local Config = loadMod("Config")
local Utils = loadMod("Utils")
local UI = loadMod("UI")

Utils.setNotifier(function(text, color) print("[notify] " .. text) end)

local ctx = { Config = Config, Utils = Utils, UI = UI, onUnload = nil }
ctx.onUnload = function() end

for _, name in ipairs({ "LevelFarm", "ChestFarm", "Misc" }) do
	local mod = loadMod(name)
	local ok, err = pcall(mod.init, ctx)
	if not ok then error("init " .. name .. " failed: " .. tostring(err)) end
	print("[ok] " .. name .. " initialised")
end

print("ALL MODULES LOADED SUCCESSFULLY (Loader flow)")

-- Now exercise Main.luau (the loadstring entry point) with a stubbed HTTP so
-- the production "loadstring(game:HttpGet(...))()" path is validated too.
do
	local mainEnv = setmetatable({}, { __index = function(_, k) return env[k] or _G[k] end })

	-- Stub game that serves module source over HttpGet and proxies GetService.
	local stubGame = setmetatable({
		HttpGet = function(self, url)
			local name = url:match("Modules/([%w]+)%.luau$")
			assert(name, "unexpected url: " .. url)
			assert(MODS[name], "no source for " .. name)
			return MODS[name]
		end,
		GetService = function(self, svc) return game:GetService(svc) end,
	}, { __index = function(_, k) return game[k] end })
	mainEnv.game = stubGame

	-- loadstring wrapper that binds each compiled module to mainEnv so the
	-- loaded modules see the Roblox stubs (mirrors what an executor does).
	mainEnv.loadstring = function(src, name)
		local fn = loadstring(src, name)
		setfenv(fn, mainEnv)
		return fn
	end

	local fn = loadstring(MODS.Main, "@Main")
	setfenv(fn, mainEnv)
	local ok, err = pcall(fn)
	if not ok then error("Main.luau failed: " .. tostring(err)) end
	print("MAIN.LUAU (loadstring entry) RAN SUCCESSFULLY")
end
FOOTER
} > "$OUT"

echo "wrote $OUT"
