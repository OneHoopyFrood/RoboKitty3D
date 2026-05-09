# Robot Finds Kitten 3D — Agent Guidelines

A Godot 4 GDScript port of [robotfindskitten](http://www.robotfindskitten.org/). See [README.md](README.md) for setup and controls, [TODO.md](TODO.md) for planned features.

## Build & Run

- **Engine**: Godot 4.6 (mobile renderer)
- **Run**: Import project folder in Godot, press Play (F5). No compilation step — GDScript is interpreted.
- **Scene entry point**: `Root/Root.tscn`

## Architecture

```
Root.tscn           — root; owns scene switching, mouse state, and global audio
  Menu.tscn         — title/menu UI
  Dialog.tscn       — global dialog overlay used by Player
  World.tscn        — gameplay root; generates 100 Symbol nodes procedurally
    Player.tscn     — CharacterBody3D; handles movement, interaction, and look while World is active
    Symbol.tscn (×N) — interactive floating objects (the NKIs)
```

**Interactive object model:**
`Symbol` currently owns interaction behavior directly.

- `Symbol` owns bobbing animation, glow color, random ASCII character `TextMesh`, and `get_blurb()`.
- `Cube` is currently not implemented in `Root/World/`.

## Key Conventions

- **Grid movement**: 1 unit = 1 cell. Player always snaps to `round(pos / step_size) * step_size` after physics to prevent drift.
- **Tween-based animation**: All movement and visual transitions use `Tween`. Never animate with `_process` counters.
- **Tap vs. hold distinction**: `Input.is_action_just_pressed()` triggers intentional interaction (symbol bump → interact, wall → error sound). `Input.is_action_pressed()` triggers continuous walking (symbol → brake animation, wall → stop silently). Preserve this semantics.
- **Collision detection is raycast-based, not physics-based**: Do NOT use `is_on_wall()`, `velocity == Vector3.ZERO`, or distance-moved checks to detect collisions with NKIs. Use `_try_bump_interact()` and `_is_path_blocked()` before movement starts. The physics process only handles snapping on successful move completion and unsticking if somehow blocked mid-move.
- **Mid-move sticking**: If `move_and_slide()` makes no progress (`distance < 0.001`), snap back to `start_position`, clear `is_moving`, play error sfx, and start `_block_cooldown`. Turning resets the cooldown.
- **`is_animating` flag**: Set at the start of `_do_bump_bounce()` and `_do_brake_animation()`, cleared via `tween.finished` callback. Blocks all movement input while true.
- **Blurb retrieval order** (in `Player.gd`): `get_blurb()` method → `get_meta("blurb")` → `.blurb` property. New interactive nodes should implement `get_blurb() -> String`.
- **Colors**: Generated in HSV with saturation fixed at `0.8` for visual consistency.
- **Private members**: Prefix with `_` (e.g., `_tween`, `_sfx`, `_block_cooldown`).

## Important Files

| File                                                       | Role                                                   |
| ---------------------------------------------------------- | ------------------------------------------------------ |
| [Root/Root.gd](Root/Root.gd)                               | Scene switching, mouse mode, world input gating, music |
| [Root/Menu/Menu.gd](Root/Menu/Menu.gd)                     | Menu button wiring and presentation                    |
| [Root/World/world.gd](Root/World/world.gd)                 | Procedural board generation                            |
| [Root/World/Player/Player.gd](Root/World/Player/Player.gd) | Input, grid movement, raycast interaction, animations  |
| [Root/World/Symbol/symbol.gd](Root/World/Symbol/symbol.gd) | NKI implementation (ASCII symbol + blurb)              |
| [Assets/NKIs.txt](Assets/NKIs.txt)                         | Source text for non-kitten item blurbs                 |

## What's Not Implemented Yet

- Kitten / win condition
- World bounds
- Pause menu / settings

## Current Ownership

- `Root.gd` owns menu/world visibility, mouse capture, ESC handling, and looping background music.
- `Menu.gd` stays thin and forwards button actions back to `Root.gd`.
- `World.gd` owns procedural generation and gameplay-side instancing.
- `Player.gd` no longer manages global mouse capture; it only reacts while `World` is enabled.

See [root.instructions.md](.github/instructions/root.instructions.md) and [menu.instructions.md](.github/instructions/menu.instructions.md) for focused guidance on the top-level flow.

Refer to [TODO.md](TODO.md) before adding features to avoid duplicate work.
