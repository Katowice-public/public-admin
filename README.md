# public-admin

A Roblox admin panel written in Luau for use as a `LocalScript`.

## Features

- Fly (WASD + Q/E or Space / Shift while airborne)
- Speed Boost (2x walk speed)
- Infinite Jump
- Jump Power Boost (2x jump power)
- NoClip (walk through walls, restores collision on disable)
- Click Teleport
- Player Teleport (teleport to nearest player)
- Name ESP (player name tags through walls)
- Box ESP (Highlight outline around players)
- Full Bright
- Low Gravity
- FOV Boost (wider field of view)
- Reset Character
- Panic Button (disable all features instantly)

## Installation

1. Place `AdminPanel.luau` in **StarterPlayerScripts** as a `LocalScript`.
2. Join the game and press `RightShift` to open or close the panel.

## Configuration

Edit the `config` table at the top of `AdminPanel.luau` to change:

- `toggleKey` — key to open / close the panel
- `openOnStart` — show the panel automatically when the game loads
- `flySpeed` — fly movement speed
- `flyUpKey` / `flyDownKey` — keys for vertical flight (default Q / E)
- `walkSpeedMultiplier` — speed boost multiplier
- `jumpPowerMultiplier` — jump power multiplier
- `lowGravity` — gravity value when Low Gravity is enabled
- `defaultFov` / `boostedFov` — normal and boosted camera FOV
- `uiTheme` — accent colors and background colors

## Notes

- This script only works in a client-side `LocalScript`.
- Some features may be blocked by anti-exploit systems in certain games.
