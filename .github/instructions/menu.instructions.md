---
description: "Use when modifying Menu.gd or the Root/Menu UI scene. Covers button wiring, presentation, and handoff to Root."
applyTo: "Root/Menu/**/*.gd"
---

# Menu Node Conventions

`Menu.gd` should stay lightweight. It owns button wiring and presentation, but it should not decide global game state directly.

## Responsibilities

- Connect UI controls in `_ready()`.
- Forward Play/Quit actions to `Root.gd`.
- Keep menu presentation code local to the menu scene.

## Button Flow

- `Play` should call `Root.play()`.
- `Quit` should call `Root.quit()`.
- If new menu actions are added later, prefer forwarding them to Root instead of changing world state directly.

## Presentation

- Keep layout and styling inside the menu scene.
- Avoid mixing gameplay logic into the menu script.
- If the menu grows into multiple screens, keep the initial Root handoff intact and let Root remain the coordinator.

## Open to Change

This is intentionally minimal. The menu can evolve into settings or submenus later, but Root should remain the owner of the high-level state transitions.
