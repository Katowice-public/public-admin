# public-admin

A Roblox admin panel written in Luau for use as a `LocalScript`.

## Features

- Fly (WASD + Q/E or Space / Shift) with speed slider, full camera orientation, no walk/fall animations, and locked forward pose
- Walk Speed slider
- Infinite Jump
- Jump Power slider (works with both `JumpPower` and `JumpHeight` humanoids)
- NoClip (walk through walls, restores collision on disable)
- Click Teleport
- Player Teleport (teleport to nearest player)
- Name ESP (player names + health through walls)
- Box ESP (Highlight outline around players)
- Full Bright
- Low Gravity
- FOV slider
- Hitbox Expander with size slider (enlarges all character parts and re-applies continuously; client-side effectiveness varies by game)
- Aimbot with range and speed sliders (smoothly locks camera onto the nearest player's head)
- Reset Character
- Panic Button (disable all features instantly)
- Close button fully unloads the panel and cleans up connections
- Minimize button toggles between `-` and `+`

## Installation

1. Place `AdminPanel.luau` in **StarterPlayerScripts** as a `LocalScript`.
2. Join the game and press `RightShift` to open or close the panel.
3. Use the `-` / `+` button to minimize or restore the panel.

## Configuration

Edit the `config` table at the top of `AdminPanel.luau` to change:

- `toggleKey` — key to open / close the panel
- `openOnStart` — show the panel automatically when the game loads
- `flySpeed` — default fly speed
- `flyUpKey` / `flyDownKey` — keys for vertical flight (default Q / E)
- `walkSpeed` — default walk speed
- `jumpPower` — default jump power
- `jumpHeight` — default jump height used for conversion when a game uses `JumpHeight`
- `lowGravity` — gravity value when Low Gravity is enabled
- `defaultFov` / `boostedFov` — normal and boosted camera FOV
- `hitboxSize` — default expanded hitbox size
- `aimbotRange` — default aimbot lock-on range
- `aimbotSpeed` — default aimbot snap speed (1-100)
- `aimbotPart` — target part name for the aimbot (default "Head")
- `uiTheme` — accent colors and background colors

## Notes

- This script only works in a client-side `LocalScript`.
- Some features may be blocked by anti-exploit systems in certain games.
- The Hitbox Expander and Aimbot only affect client-side behavior; they cannot bypass server-side validation.
