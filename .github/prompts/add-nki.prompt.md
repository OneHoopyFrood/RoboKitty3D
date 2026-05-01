---
description: "Scaffold a new NKI (non-kitten item) — a Symbol subclass with a custom blurb. Use when adding a new interactive object to the world."
argument-hint: "Name and description of the new NKI, e.g. 'A rubber duck that squeaks'"
agent: "agent"
---

Create a new NKI (non-kitten item) for the Robot Finds Kitten 3D game.

The user has provided this description: {{COPILOT_ARGUMENT}}

## What to build

1. **A new GDScript** at `World/<NKIName>/<NKIName>.gd` that extends `Symbol`:

```gdscript
class_name <NKIName>
extends Symbol

func get_blurb() -> String:
    return "<flavor text matching the description>"
```

- Keep the blurb short (1–2 sentences), whimsical, and in the style of the original robotfindskitten item descriptions.
- The class needs no `_ready()` override unless adding new visual behavior — `super._ready()` from `Symbol` handles everything.

2. **No new `.tscn` needed** unless the NKI requires a unique mesh or structure. If it's just flavor text, it can reuse `Symbol.tscn` by setting `get_blurb()` via a subclass or script attachment.

## Conventions

- Implement `get_blurb() -> String` — do not use `set_meta("blurb", ...)`.
- Call `super._ready()` if overriding `_ready()`.
- No signals. Use direct method calls.
- Colors and bobbing are randomized by `world.gd` after instantiation — do not hardcode them.

See [AGENTS.md](../../AGENTS.md) for full project conventions.
