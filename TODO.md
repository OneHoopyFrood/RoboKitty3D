# TODO

## Gameplay

### Base features

- [x] Dialogue
  - [x] Generate blurbs to get on inspect
  - [x] Show blurb on bumping a symbol
  - [x] Bump animation + sound
- [x] Add kitten
  - [x] Win condition (found kitten)
  - [ ] Win sequence (Ideas: fireworks, pop-up ascii animation of robot finding kitten and a heart)

### Enhancements

**General**

- [x] Prevent symbols colliding on generation
- [x] Mouse control of view
- [x] Should player only be able to move in the cardinal
      directions? Like the original game? W would be forward, S back, A to turn
      left 90°, D to turn right 90°
- [x] Strafe (hold shift to strafe instead of turn)
- [ ] Sprint (hold ctrl to move faster)
- [ ] Save and load settings and options
- [ ] Configurable controls
- [x] Dim visited symbols
- [ ] Something to fill the void? Starfield? Slightly shiny floor texture? It'd
      be nice to see my reflection.

**Optional**

- [ ] Leaderboard
  - [ ] Time to find kitten
  - [ ] Number of interactions (bump + interact) before finding kitten (golf score)
- [ ] Multiplayer mode (local or online)
- Alternate Game Modes?
- [ ] Memory game (NKIs in pairs, symbols hide inside cubes and are revealed when interacted with. The object is to find the most pairs before the kitten is found! (single or multiplayer)
- [ ] Timed mode (non-zen)
- [ ] Multiplayer competative mode (multiple rounds, keeps score of who finds
      the kitten first each round, first to 3 wins)

### Pause menu

- [x] BG Music Controls
- [x] Shows on ESC
- [x] Resume
- [x] Restart - randomizes the symbols and puts the player back at the start
- [x] Quit to desktop
- [ ] Keyboard/Controller navigation (is only mouse right now)
- Options
  - [x] Dim visited symbols
  - [x] Number of symbols
  - [x] Board size
- Settings
  - [ ] Control customization
  - [ ] Music and SFX volumes
  - [ ] Fullscreen
  - [ ] Camera mode (FP, 3rd person, top down)
- [ ] Credits
  - [ ] Music credits
  - [ ] SFX credits
  - [ ] Art credits
  - [ ] Code credits
  - [ ] Special thanks
  - [ ] Godot credits

#### Cheat Codes

- [x] "rfk" - Win the game immediately. (Testing purposes)
- [ ] "pspsps" - Kitten starts mewing. (Spacial audio hint)
- [x] "herekittykitty" - All symbols go gray except the kitten symbol, which glows brighter.
- [ ] "nyan" - God Mode. Doesn't actually do anything. You just get a UI HUD
      label that says "GOD MODE ENABLED" and the nyan cat music plays. Maybe you can jump.
- [ ] "duckit" - Summons a duck that wanders around and quacks.

---

## Assets

**Sounds**

- Music
  - [x] Nostalgium 2023
  - [x] I Found A Pretty Stone
  - [x] Jonbeck Bonobo
  - [ ] Cuban Pete (Secret)
- SFX
  - [x] Wahmp
  - [x] Kitten Noises
  - [x] Interact
  - [x] Wall bump noise
  - [x] Robot movement
    - [x] Whirrr on move/turn
    - [x] Ooof when hitting a symbol at speed
    - [ ] Back-up beep?
    - [x] Error noise when backing into a wall
    - [x] Error noise when backing into a symbol
  - [ ] Kitten noises (for "pspsps" cheat code)
  - [ ] Menu sounds

**Art**

- [ ] Kitten (paper cut-out)
- [ ] Robot kitten heart (for win sequence)
- [ ] Splash screen/title card
- [ ] Credits screen background
