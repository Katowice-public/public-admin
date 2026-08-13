-- Misc (ModuleScript)
-- "Other features": quality-of-life and utility toggles that don't fit neatly
-- into the farm modules. Each toggle is independent and self-cleaning.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Misc = {}

function Misc.init(env)
	local Config, Utils, UI = env.Config, env.Utils, env.UI
	local cfg = Config.misc

	local section = "Misc"
	UI.addSection(section)

	local threads = {}

	local function stop(name: string)
		if threads[name] then
			task.cancel(threads[name])
			threads[name] = nil
		end
	end

	-- Auto Haki: re-activate Observation/Aura on an interval -----------------
	UI.addToggle(section, {
		name = "Auto Haki",
		desc = "Re-activate Observation/Aura",
		default = cfg.autoHaki,
		callback = function(on)
			if on then
				Utils.notify("Auto Haki on")
				threads.haki = task.spawn(function()
					while true do
						-- The exact keybind varies; tapping the common Haki keys covers most setups.
						Utils.tapKey(Enum.KeyCode.E)
						Utils.tapKey(Enum.KeyCode.T)
						task.wait(cfg.hakiInterval)
					end
				end)
			else
				stop("haki")
			end
		end,
	})

	-- Auto Click: hold to swing the equipped weapon --------------------------
	UI.addToggle(section, {
		name = "Auto Click",
		desc = "Spam left-click while held",
		default = cfg.autoClick,
		callback = function(on)
			if on then
				Utils.notify("Auto Click on")
				threads.click = task.spawn(function()
					while true do
						Utils.virtualClick()
						task.wait(cfg.autoClickDelay)
					end
				end)
			else
				stop("click")
			end
		end,
	})

	-- FPS Boost: strip heavy client-side effects ----------------------------
	local originalFog = Lighting.FogEnd
	UI.addToggle(section, {
		name = "FPS Boost",
		desc = "Disable heavy effects",
		default = cfg.fpsBoost,
		callback = function(on)
			if on then
				Utils.notify("FPS Boost on")
				originalFog = Lighting.FogEnd
				Lighting.FogEnd = 9e9
				-- Remove particle emitters and trails from the workspace.
				for _, d in ipairs(Workspace:GetDescendants()) do
					if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
						d.Enabled = false
					end
				end
			else
				Lighting.FogEnd = originalFog
				for _, d in ipairs(Workspace:GetDescendants()) do
					if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
						d.Enabled = true
					end
				end
			end
		end,
	})

	-- Auto Rejoin: hop back into the same server on disconnect --------------
	UI.addToggle(section, {
		name = "Auto Rejoin",
		desc = "Rejoin on kick / disconnect",
		default = cfg.autoRejoin,
		callback = function(on)
			if on then
				Utils.notify("Auto Rejoin armed")
				threads.rejoin = task.spawn(function()
					while true do
						if not Utils.isAlive() and not Utils.getCharacter() then
							local jobId = game.JobId
							pcall(function()
								TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Utils.getPlayer())
							end)
						end
						task.wait(5)
					end
				end)
			else
				stop("rejoin")
			end
		end,
	})

	-- Aura Bring: pull nearby players to you (trolling) ---------------------
	UI.addToggle(section, {
		name = "Player Bring",
		desc = "Teleport nearby players to you",
		default = cfg.auraBring,
		callback = function(on)
			if on then
				Utils.notify("Player Bring on")
				threads.bring = task.spawn(function()
					while true do
						local playerHrp = Utils.getHrp()
						if playerHrp then
							for _, p in ipairs(Players:GetPlayers()) do
								if p ~= Utils.getPlayer() and p.Character then
									local h = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
									if h then
										pcall(function()
											h.CFrame = CFrame.new(playerHrp.Position + Vector3.new(0, 3, 0))
										end)
									end
								end
							end
						end
						task.wait(0.5)
					end
				end)
			else
				stop("bring")
			end
		end,
	})

	-- Utility buttons --------------------------------------------------------
	UI.addButton(section, {
		name = "Rejoin Server",
		label = "Rejoin",
		color = Color3.fromRGB(60, 70, 200),
		callback = function()
			local jobId = game.JobId
			pcall(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Utils.getPlayer())
			end)
		end,
	})

	UI.addButton(section, {
		name = "Hop Server",
		label = "Hop",
		color = Color3.fromRGB(60, 70, 200),
		callback = function()
			pcall(function()
				TeleportService:Teleport(game.PlaceId, Utils.getPlayer())
			end)
		end,
	})

	UI.addButton(section, {
		name = "Unload Script",
		label = "Unload",
		color = Color3.fromRGB(235, 80, 80),
		callback = function()
			Utils.notify("Unloading...")
			if env.onUnload then env.onUnload() end
			local gui = UI.getWindow()
			if gui then gui:Destroy() end
		end,
	})
end

return Misc
