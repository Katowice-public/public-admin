-- Utils (ModuleScript)
-- Shared helpers used by every feature module.
-- Pure functions + lightweight wrappers so feature modules stay small.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

local Utils = {}

-- Character accessors ------------------------------------------------------

function Utils.getPlayer(): Player
	return player
end

function Utils.getCharacter(): Model?
	return player.Character
end

function Utils.getHumanoid(): Humanoid?
	local char = Utils.getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

function Utils.getHrp(): BasePart?
	local char = Utils.getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Utils.getHead(): BasePart?
	local char = Utils.getCharacter()
	return char and char:FindFirstChild("Head") :: BasePart?
end

function Utils.isAlive(): boolean
	local h = Utils.getHumanoid()
	return h ~= nil and h.Health > 0
end

-- Waits for a fresh character to spawn and returns its HRP.
function Utils.waitForCharacter(timeout: number?): BasePart?
	local t = task.wait
	local start = os.clock()
	while true do
		local hrp = Utils.getHrp()
		if hrp and Utils.isAlive() then
			return hrp
		end
		if timeout and os.clock() - start > timeout then
			return nil
		end
		task.wait(0.1)
	end
end

-- Math / geometry ----------------------------------------------------------

function Utils.distanceTo(part: BasePart): number
	local hrp = Utils.getHrp()
	if not hrp then return math.huge end
	return (hrp.Position - part.Position).Magnitude
end

function Utils.closestPartFrom(collection: { Instance }): BasePart?
	local hrp = Utils.getHrp()
	if not hrp then return nil end
	local best, bestDist = nil, math.huge
	for _, item in ipairs(collection) do
		if item:IsA("BasePart") then
			local d = (hrp.Position - item.Position).Magnitude
			if d < bestDist then
				best, bestDist = item, d
			end
		end
	end
	return best
end

-- Teleports the player's HRP to a CFrame, preserving orientation.
function Utils.teleportTo(cframe: CFrame)
	local hrp = Utils.getHrp()
	if not hrp then return end
	hrp.CFrame = cframe
end

-- Moves the HRP directly above/below a target position by `height` studs.
function Utils.hoverAbove(position: Vector3, height: number)
	local hrp = Utils.getHrp()
	if not hrp then return end
	hrp.CFrame = CFrame.new(position + Vector3.new(0, height, 0))
end

-- Input simulation ----------------------------------------------------------

-- Fires a virtual click at the centre of the screen (used for auto-swing).
function Utils.virtualClick()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:Button1Down(Vector2.new())
		task.wait()
		VirtualUser:Button1Up(Vector2.new())
	end)
end

-- Presses and releases a key briefly.
function Utils.tapKey(keyCode: Enum.KeyCode)
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, keyCode, false)
		task.wait()
		VirtualInputManager:SendKeyEvent(false, keyCode, false)
	end)
end

-- Blox Fruits remotes -------------------------------------------------------

-- Best-effort lookup of the main combat remote. Blox Fruits restructures its
-- remotes frequently, so this scans the common locations and returns the first
-- usable RemoteEvent. Feature modules should treat `nil` as "not available".
function Utils.getCombatRemote(): RemoteEvent?
	local searchRoots = {
		ReplicatedStorage:FindFirstChild("Remotes"),
		ReplicatedStorage:FindFirstChild("Modules"),
		ReplicatedStorage,
	}
	for _, root in ipairs(searchRoots) do
		if not root then continue end
		for _, candidate in ipairs(root:GetDescendants()) do
			if candidate:IsA("RemoteEvent") and (candidate.Name == "Comm" or candidate.Name == "Combat" or candidate.Name == "Attack") then
				return candidate :: RemoteEvent
			end
		end
	end
	return nil
end

-- Notification --------------------------------------------------------------
-- The UI module injects a real notifier after it loads; until then we no-op.
Utils._notifier = nil

function Utils.setNotifier(fn: (string, Color3?) -> ())
	Utils._notifier = fn
end

function Utils.notify(text: string, color: Color3?)
	if Utils._notifier then
		Utils._notifier(text, color)
	else
		print("[BloxAutoFarm] " .. text)
	end
end

-- Loop helpers --------------------------------------------------------------

-- Runs `fn` in a tight loop that auto-cancels when `shouldStop()` returns true.
-- Returns the thread so callers can kill it if needed.
function Utils.runLoop(interval: number, fn: () -> (), shouldStop: () -> boolean): thread
	return task.spawn(function()
		while not shouldStop() do
			local ok, err = pcall(fn)
			if not ok then
				warn("[BloxAutoFarm] loop error: " .. tostring(err))
			end
			if interval and interval > 0 then
				task.wait(interval)
			else
				RunService.Heartbeat:Wait()
			end
		end
	end)
end

return Utils
