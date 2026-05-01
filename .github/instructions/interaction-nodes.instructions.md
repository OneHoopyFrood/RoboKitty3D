---
description: "Use when creating, extending, or modifying interactive objects (NKIs, kitten, cubes) that extend BaseInteractionNode. Covers required interface, setup pattern, and conventions."
applyTo: "World/**/*.gd"
---

# Interaction Node Conventions

All interactive objects inherit from `BaseInteractionNode` ([base_interaction_node.gd](../../World/BaseInteractionNode/base_interaction_node.gd)).

## Required Setup in `_ready()`

1. Call `super._ready()` first — it locates the `Mesh` child node and creates the glow material overlay.
2. The scene **must** have a child `MeshInstance3D` named exactly `Mesh`.

## Implement `get_blurb() -> String`

`Player.gd` retrieves dialog text in this order:

1. `get_blurb()` method
2. `get_meta("blurb")`
3. `.blurb` property

New interactive nodes should implement `get_blurb() -> String`. Do not rely on metadata or property fallbacks for new code.

## Color & Bobbing

Use the built-in helpers rather than setting properties directly:

```gdscript
node.randomize_bobbing(rng)   # randomizes amplitude + speed within clamped ranges
node.randomize_color(rng)     # HSV color, saturation fixed at 0.8
```

Never manually set `_mesh.material_overlay` — use `set_color(color)` instead.

## No Signals

Use direct method calls for interaction. Do not add signals to interaction nodes.
