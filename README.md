# Robot Finds Kitten 3D

A 3D Godot 4 port of the classic zen simulation [robotfindskitten (circa 1997)](http://www.robotfindskitten.org/).

_In this game, you are robot. Your job is to find kitten. This task is
complicated by the existence of various things which are not kitten. Robot
must touch items to determine if they are kitten or not. The game ends when
robotfindskitten._

RoboKitty3D reimagines the original 2D ASCII experience of robotfindskitten as a
3D world filled with glowing, bobbing symbols — each one a quirky Non-Kitten
Item (NKI) with its own description. Wander the board, bump into things, and
find kitten.

This remake bears little resemblance to the original. It was primarily executed
as a learning exercise in Godot 4 and 3D game development, and as a sandbox for
experimenting with procedural generation, animation, and visual effects. The
original's simple ASCII presentation is reimagined as a vibrant 3D world filled
with bobbing, glowing symbols.

---

## Features

- **Win condition** — One symbol is kitten. Find it and the game ends with a message; press any key to restart.
- **Procedural board** — NKI count and board size are configurable in the Options menu. Symbols are placed at random grid-aligned positions.
- **Visited symbol dimming** — Optionally dim symbols you've already inspected, to help track what you've seen (toggle in Options).
- **Background music** — A playlist of tracks plays on loop. Skip forward/back and toggle playback from the menu.
- **Cheat console** — Press `` ` `` at any time to open a text prompt and enter cheat codes.
- **Sound effects** — Interaction, error, brake, and motor sounds give tactile feedback for movement and collisions.
- **Smooth camera** — First-person camera with eased mouse-look (hold `Ctrl`). Toggle with `F1`.

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

- [Godot Engine 4.6](https://godotengine.org/download/)

_Or, try out `scoop` if you're on windows!_

### Contributing

1. Clone this repository
2. Open Godot and choose **Import** → select the project folder
3. Press **Play (F5)** or click the Play button in the toolbar

No compilation step is needed — GDScript is interpreted by the engine.

Make whatever changes you like on a fork and submit a pull request when you're ready!

---

## Controls

| Action                  | Key                      |
| ----------------------- | ------------------------ |
| Move forward / back     | `W` / `S`                |
| Turn left / right (90°) | `A` / `D`                |
| Strafe left / right     | `Shift+A` / `Shift+D`    |
| Look around freely      | Hold `Ctrl` + move mouse |
| First-person view       | `F1`                     |
| Interact / inspect      | Walk into a symbol       |
| Pause / resume          | `Esc`                    |
| Cheat console           | `` ` `` (backtick)       |

> **Note:** `A` and `D` rotate the player in 90° increments. Hold `Shift` with `A`/`D` to strafe instead. Hold `Ctrl` to look around without changing your orientation.

> **Tip:** You interact with a symbol by walking into it from right in front of it.

---

## Project Structure

```
RoboKitty3D/
├── Root/
│   ├── Root.tscn / Root.gd         # Scene root; scene switching, mouse mode, win detection
│   ├── BackgroundMusic.tscn/.gd    # Background music playlist management
│   ├── CheatConsole.tscn/.gd       # Cheat console overlay (backtick to open)
│   ├── GameOptions.gd              # Autoloaded global game options
│   ├── Dialog/
│   │   └── Dialog.tscn/.gd         # Global dialog overlay (NKI blurbs, win message)
│   ├── Menu/
│   │   └── Menu.tscn/.gd           # Pause/title menu with music controls and options panel
│   └── World/
│       ├── World.tscn / world.gd   # Gameplay root; spawns NKI symbols procedurally
│       ├── Player/
│       │   └── Player.tscn/.gd     # CharacterBody3D; input, grid movement, animations
│       └── Symbol/
│           └── Symbol.tscn/.gd     # NKI implementation (random ASCII char + blurb)
├── Assets/
│   ├── NKIs.txt                    # Source text for all non-kitten item blurbs
│   ├── music/                      # Background music tracks (.ogg)
│   └── sfx/                        # Sound effects (.wav/.ogg)
└── project.godot
```

---

## About the Original

[robotfindskitten](http://www.robotfindskitten.org/) was created by **Leonard Richardson** in 1997 and has been ported to dozens of platforms. It is described as a "Zen simulation" — there is no score, no fail state, just exploration and discovery.

This project is a fan remake. All NKI text is derived from the original game's
community-contributed item list, except for one.

---

## Contributing

Pull requests are welcome! Check [TODO.md](TODO.md) for planned features and known gaps before starting work.
