# Blox Fruits AutoFarm

A modular Roblox auto-farm for **Blox Fruits**, written in Luau and shipped as a
client-side `LocalScript`. It ships a loader that pulls in every feature module,
a shared GUI, and separate modules for **level farming**, **chest / coin
farming**, and a set of **misc utilities**.

## Features

- **Level Farm** — pick a target NPC, hover above the ground, pull the enemy
  close, and swing / fire on a short cooldown. Choose attack method (Melee /
  Sword / Gun / Fruit / Auto) and a max enemy level.
- **Chest / Coin Farm** — sweeps the workspace for chests, Beli, Fragments and
  dropped fruit and teleports them onto the player for instant collection.
- **Misc**
  - Auto Haki (re-activates Observation / Aura)
  - Auto Click (spam-swing the equipped weapon)
  - FPS Boost (strips particles, trails and fog)
  - Auto Rejoin (hops back into the same server on disconnect)
  - Player Bring (teleport nearby players to you)
  - Rejoin / Hop / Unload buttons
- **GUI** — draggable window with a sidebar of sections, toggles, sliders,
  dropdowns and buttons. Open / close with `RightShift` (configurable).

## Project structure

```
src/
  Loader.luau            LocalScript — entry point. Requires & boots everything.
  Modules/
    Config.luau          Shared settings + UI theme (edit this to tune behaviour)
    Utils.luau           Helpers: character accessors, teleport, virtual input,
                         notify, loop runner, Blox Fruits remote lookup
    UI.luau              GUI framework (sections, toggles, sliders, dropdowns,
                         buttons, notifications, draggable window)
    LevelFarm.luau       XP / Beli grinding module
    ChestFarm.luau       Chest / coin / drop collection module
    Misc.luau            Auto Haki, Auto Click, FPS Boost, Auto Rejoin, etc.
test/
  gen.sh                 Builds a combined harness that loads every module
  run.sh                 Downloads the Luau CLI (if needed) and runs the harness
```

## How the loader works

`Loader.luau` is the only `LocalScript`. On run it:

1. Requires `Config`, `Utils`, then `UI` from the `Modules` folder.
2. Wires `Utils.notify` through the real GUI notifier.
3. Builds a shared `env = { Config, Utils, UI, onUnload }`.
4. Calls `Module.init(env)` for each feature module in `featureModules`.
5. Binds the open/close key from `Config.toggleKey`.

Each feature module exposes `init(env)` and registers its own controls into the
UI via `env.UI.addSection / addToggle / addSlider / addDropdown / addButton`.
**To add a new feature, drop a module in `Modules/` and add its name to
`featureModules` in `Loader.luau`** — that's the only wiring change needed.

## Installation (Roblox Studio)

1. Put the `Modules` folder inside `StarterPlayerScripts`.
2. Put `Loader.luau` next to it (also in `StarterPlayerScripts`) and set its
   class to `LocalScript`.
3. Join the game and press `RightShift` to open the panel.

> The modules must be `ModuleScript` instances and the loader must be a
> `LocalScript`. The `Modules` folder must be a direct child of the loader
> (named exactly `Modules`).

## Configuration

Edit `src/Modules/Config.luau` to change defaults without touching feature
code: the toggle key, UI theme, target enemy, attack method, hover height, grab
radius, auto-store, auto-haki interval, etc. Most of these are also live-tunable
from the GUI at runtime.

## Testing

The repo includes a stub harness that loads every module under the plain Luau
CLI (no Roblox required) to catch UI-construction and init bugs:

```bash
bash test/run.sh
```

Expected output:

```
[ok] LevelFarm initialised
[ok] ChestFarm initialised
[ok] Misc initialised
ALL MODULES LOADED SUCCESSFULLY
```

## Notes

- This is a client-side `LocalScript`; some actions (teleporting other players,
  remote-firing combat) only work in places where the server trusts the client,
  which is the case for Blox Fruits-style grinding but not every game.
- Blox Fruits frequently restructures its remotes and enemy hierarchy. The
  combat remote lookup in `Utils.getCombatRemote` and the enemy name list in
  `LevelFarm` are best-effort and may need updating when the game updates.
- Some features may be blocked by anti-exploit systems.
