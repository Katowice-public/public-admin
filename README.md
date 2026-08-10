# public-admin

A Roblox admin panel written in Luau for use as a `LocalScript`.

## Features

- Fly (WASD + Space / Shift while airborne)
- Speed Boost (2x walk speed)
- Infinite Jump
- NoClip (walk through walls)
- Click Teleport
- ESP (player name tags through walls)
- Full Bright
- Low Gravity

## Installation

1. Place `AdminPanel.luau` in **StarterPlayerScripts** as a `LocalScript`.
2. Join the game and press `RightShift` to open the panel.

## Configuration

Edit the `config` table at the top of `AdminPanel.luau` to change:

- `toggleKey` — key to open / close the panel
- `flySpeed` — fly movement speed
- `walkSpeedMultiplier` — speed boost multiplier
- `lowGravity` — gravity value when Low Gravity is enabled
- `uiTheme` — accent colors and background colors

## Notes

- This script only works in a client-side `LocalScript`.
- Some features may be blocked by anti-exploit systems in certain games.
