# Robot Finds Kitten 3D

A 3D Godot 4 port of the classic zen simulation [robotfindskitten (circa 1997)](http://www.robotfindskitten.org/).

> _In this game, you are robot (#). Your job is to find kitten. This task is complicated by the existence of various things which are not kitten. Robot must touch items to determine if they are kitten or not. The game ends when robotfindskitten._

RoboKitty3D reimagines the original 2D ASCII experience as a 3D world filled with glowing, bobbing symbols — each one a quirky Non-Kitten Item (NKI) with its own description. Wander the board, bump into things, and find kitten.

---

## Screenshots

<!-- TODO: Add screenshots once the game has a more complete visual state. -->
<!-- Suggested shots:
     1. Overview of the board showing glowing NKI symbols
     2. Close-up of a symbol interaction / blurb dialogue
     3. First-person perspective
-->

> 📷 _Screenshots coming soon!_

---

## Getting Started

### Prerequisites

- [Godot Engine 4.6](https://godotengine.org/download/) (Mobile renderer)

### Running for Development

1. Clone this repository
2. Open Godot and choose **Import** → select the project folder
3. Press **Play (F5)** or click the Play button in the toolbar

No compilation step is needed — GDScript is interpreted by the engine.

---

## Controls

| Action | Key |
|---|---|
| Move forward / back / left / right | `W` `S` `A` `D` |
| Turn (rotate player) | `A` / `D` (tap to turn 90°) |
| Look around (free camera) | Hold `Ctrl` + move mouse |
| Run | Hold `Shift` while moving |
| First-person view | `F1` |
| Interact / inspect | Walk into a symbol |

> **Tip:** Walking _into_ a symbol triggers its blurb. Walking while holding a direction into a symbol brakes smoothly instead.

---

## Project Structure

```
RoboKitty3D/
├── World/
│   ├── World.tscn              # Root scene; spawns all NKI symbols procedurally
│   ├── world.gd                # Board generation logic
│   ├── BaseInteractionNode/    # Base class for all interactable objects
│   ├── Symbol/                 # NKI implementation (random ASCII char + blurb)
│   └── Cube/                   # Stub interactable cube object
├── Player/
│   ├── Player.tscn             # Player scene (CharacterBody3D)
│   └── Player.gd               # Input, grid movement, collision, animations
├── UI/                         # (In progress) Dialogue and HUD scenes
├── Assets/
│   ├── NKIs.txt                # Source text for all non-kitten item blurbs
│   ├── music/                  # Background music tracks (.ogg)
│   └── sfx/                    # Sound effects (.ogg)
└── project.godot
```

---

## About the Original

[robotfindskitten](http://www.robotfindskitten.org/) was created by **Leonard Richardson** in 1997 and has been ported to dozens of platforms. It is described as a "Zen simulation" — there is no score, no fail state, just exploration and discovery.

This project is an unofficial fan port. All NKI text is derived from the original game's community-contributed item list.

---

## Contributing

Pull requests are welcome! Check [TODO.md](TODO.md) for planned features and known gaps before starting work.
