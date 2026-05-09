---
description: "Use when modifying Root.gd or any Root-level scene management behavior. Covers menu/world switching, mouse mode, audio, and global input ownership."
applyTo: "Root/Root.gd"
---

# Root Node Conventions

`Root.gd` is the top-level coordinator for the game. It owns scene visibility, mouse mode, ESC handling, and global audio that should continue across menu and gameplay.

## Responsibilities

- Show the menu on startup.
- Switch between menu and world states through `_show_menu()` and `_show_world()`.
- Keep background music alive across scene changes.
- Decide whether the World subtree should be enabled or disabled.

## Input and Mouse State

- ESC should always return to the menu and release the mouse.
- Menu state should leave the mouse visible.
- World state should capture the mouse.
- Prefer toggling `process_mode` on the World subtree instead of intercepting every input event.

## Keep It Small

- Do not move player movement or world generation logic into Root.
- Do not duplicate gameplay state here unless it is genuinely global.
- Treat this file as a coordinator, not a dumping ground for scene-specific code.

## Open to Change

These rules are intentionally basic. If the Root layer grows, prefer adding a focused helper method here before pushing the behavior down into child scenes.
