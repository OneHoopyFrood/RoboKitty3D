---
description: "Use when modifying Player.gd or adding features to the Player node. Covers movement, input routing, collision, animation flags, and SFX conventions."
applyTo: "Player/**/*.gd"
---

# Player Node Conventions

The Player is a `CharacterBody3D` in [Player/Player.gd](../../Player/Player.gd). All input, grid movement, raycast interaction, and feedback animations live here.

## Movement Model

- **Grid-based**: one step = `step_size` units (default `1.0`). Always snap after a successful move via `_snap_to_grid()`.
- `start_move(direction)` sets `is_moving = true`, records `start_position` and `target_position`, then `_physics_process` drives the move with `move_and_slide()`.
- Movement completes when `move_dir.dot(target_position - global_transform.origin) <= 0` — snap and clear `is_moving`.
- **Mid-move stuck recovery**: if `move_and_slide()` makes no progress (`distance < 0.001`), snap back to `start_position`, clear `is_moving`, play error sfx, and set `_block_cooldown`.

## Input Routing (tap vs. hold)

This distinction is intentional — do not collapse the two branches:

| Input                    | Ahead clear  | Ahead blocked (wall/border) | Ahead is symbol |
| ------------------------ | ------------ | --------------------------- | --------------- |
| `just_pressed` forward   | `start_move` | error sound                 | interact        |
| `pressed` (held) forward | `start_move` | stop silently               | brake animation |
| `just_pressed` back      | `start_move` | error sound                 | —               |
| `pressed` (held) back    | `start_move` | stop silently               | —               |

## Collision Detection

**Always use raycasts, not physics callbacks.** Never use `is_on_wall()`, `velocity == Vector3.ZERO`, or distance-delta checks to detect NKI collisions.

- `_try_bump_interact()` — casts a ray one cell ahead; returns the `Symbol` node if hit, else `null`.
- `_is_path_blocked(direction)` — same ray, returns `bool`. Use before calling `start_move` in held-walk branches.

## State Flags

- **`is_moving`**: set by `start_move()`, cleared when target reached or mid-move stuck. All movement input is gated on `not is_moving`.
- **`is_animating`**: set at the start of `_do_bump_bounce()` and `_do_brake_animation()`, cleared via `tween.finished` callback. Blocks all movement input while true. Always pair a `tween.finished.connect(func(): is_animating = false)` when adding new blocking animations.
- **`_block_cooldown`**: timer (seconds) preventing held movement retry after hitting a border mid-move. Decremented in `_process`. Reset to zero on any turn.

## Animations

- `_do_bump_bounce()` — player body lurches forward and back with camera shake. Used for intentional symbol interaction.
- `_do_brake_animation()` — camera lurches forward/down then snaps back. Used when auto-walking crashes into a symbol.
- Both set `is_animating = true` and clear it on `tween.finished`.
- All animation uses `Tween`. Never use `_process` counters for animation.

## SFX

Two exported audio stream slots on the Player node:

- `select_sfx_stream` → `_sfx` — plays on successful symbol interaction.
- `error_sfx_stream` → `_error_sfx` — plays on blocked movement (tap into wall, mid-move stuck).

Always guard playback: `if _sfx and _sfx.stream: _sfx.play()`.

## No Signals

Interaction uses direct method calls. Do not add signals to Player.
