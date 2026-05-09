---
description: "Use when creating, extending, or modifying interactive objects (NKIs, kitten, cubes) under Root/World. Covers required interface, setup pattern, and conventions."
applyTo: "Root/World/**/*.gd"
---

# Interaction Node Conventions

Interactive objects currently own their behavior directly (for example `Symbol`).

## Required Setup in `_ready()`

1. If the scene renders geometry, include a child `MeshInstance3D` named exactly `Mesh`.
2. Initialize mesh/material setup in the node script's `_ready()`.

## Implement `get_blurb() -> String`

`Player.gd` retrieves dialog text in this order:

1. `get_blurb()` method
2. `get_meta("blurb")`
3. `.blurb` property

New interactive nodes should implement `get_blurb() -> String`. Do not rely on metadata or property fallbacks for new code.

## Color & Bobbing

Expose and use helper methods rather than mutating mesh internals from outside:

```gdscript
node.randomize_bobbing(rng)   # randomizes amplitude + speed within clamped ranges
node.randomize_color(rng)     # HSV color, saturation fixed at 0.8
```

Never manually set `_mesh.material_overlay` — use `set_color(color)` instead.

## No Signals

Use direct method calls for interaction. Do not add signals to interaction nodes.

## Current Folder Layout

- World gameplay content lives under `Root/World/`.
- The player scene lives under `Root/World/Player/`.
- Global UI scenes such as menu/dialog live under `Root/Menu/` and `Root/Dialog/` instead of the World subtree.
