# public-admin

A Roblox admin panel written in Luau for use as a `LocalScript`.

## Features

- Fly (WASD + Q/E or Space / Shift) with a speed slider
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
- Hitbox Expander with size slider (client-side; effectiveness varies by game)
- Reset Character
- Panic Button (disable all features instantly)

## Installation

1. Place `AdminPanel.luau` in **StarterPlayerScripts** as a `LocalScript`.
2. Join the game and press `RightShift` to open or close the panel.

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
- `uiTheme` — accent colors and background colors

## Notes

- This script only works in a client-side `LocalScript`.
- Some features may be blocked by anti-exploit systems in certain games.
- The Hitbox Expander only affects client-side detection; it cannot bypass server-side hit validation.
