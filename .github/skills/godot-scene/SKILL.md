---
name: godot-scene
description: "Create a new Godot scene (.tscn) and companion GDScript (.gd) following project conventions. Use when adding a new scene, node type, or interactive object to the game."
argument-hint: "Scene name and purpose, e.g. 'KittenNode — the kitten the player is searching for'"
---

# Godot Scene Creation

Creates a paired `.tscn` + `.gd` following this project's conventions.

## When to Use

- Adding a new interactive object (NKI variant, kitten, prop)
- Adding a new UI scene
- Adding a new player or world component

## Procedure

1. **Determine the base class** from the table below:

   | Purpose                     | Extends                    | Location             |
   | --------------------------- | -------------------------- | -------------------- |
   | Interactive world object    | `Node3D`                   | `Root/World/<Name>/` |
   | Player-controlled character | `CharacterBody3D`          | `Root/World/Player/` |
   | UI overlay                  | `Control` or `CanvasLayer` | `Root/<Name>/`       |
   | World/level root            | `Node3D`                   | `Root/World/`        |

2. **Create the GDScript** at `<Folder>/<Name>.gd`:
   - `class_name` matching the folder name
   - `extends` the appropriate base
   - `_ready()` initializes its own mesh/material state if needed
   - Private members prefixed with `_`
   - No signals — use direct method calls

3. **Create the `.tscn`** at `<Folder>/<Name>.tscn`:
   - Root node type matches the `extends` class
   - For interactive world objects, include a child `MeshInstance3D` named exactly `Mesh`
   - Attach the `.gd` script to the root node

4. **Register with `world.gd`** if it's a world object:
   - Add a `preload('res://Root/World/<Name>/<Name>.tscn')` line
   - `world.gd` calls `randomize_bobbing(rng)` and `randomize_color(rng)` after instantiation — no need to set those in `_ready()`

## Scene Template (interactive object)

```
<Name>.tscn
└── <Name> (Node3D, script = <Name>.gd)
    └── Mesh (MeshInstance3D)
```

## Key Conventions

- Tween-based animation only — never use `_process` counters for animation
- Colors: `Color.from_hsv(h, 0.8, 1.0)` — saturation fixed at `0.8`
- Grid snapping: 1 unit = 1 cell; positions are integers

See [AGENTS.md](../../AGENTS.md) and [interaction-nodes.instructions.md](../instructions/interaction-nodes.instructions.md) for full details.
