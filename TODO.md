# TODO

### Gameplay

- [x] Dialogue
  - [x] Generate blurbs to get on inspect
  - [x] Show blurb on bumping a symbol
  - [x] Bump animation + sound
- [ ] Add kitten
  - [ ] Win condition (found kitten)
  - [ ] Win sequence (Ideas: fireworks, pop-up ascii animation of robot finding kitten and a heart)

**Optional Gameplay Enhancements**

- [ ] Leaderboard
  - [ ] Time to find kitten
  - [ ] Number of interactions (bump + interact) before finding kitten (golf score)
- [ ] Multiplayer mode (local or online)
  - [ ] Cooperative: base mode. Whenever one of the players finds the kitten,
        both win! Yay teamwork!
  - [ ] Competitive: who can find the kitten first?
    - [ ] Maybe you can "zap" the other player to paralyze them temporarily?
  - [ ] Memory game (NKIs in pairs, symbols hide inside cubes and are revealed when interacted with. The object is to find the most pairs before the kitten is found! (single or multiplayer)
- [ ] Hint mode (kitten mews and you get spacial audio)
- [ ] Timed mode (non-zen)

---

### QOL Enhancements

**General**

- [x] Prevent symbols colliding on generation
- [x] Mouse control of view
- [x] Should player only be able to move in the cardinal
      directions? Like the original game? W would be forward, S back, A to turn
      left 90°, D to turn right 90°
- [x] Strafe (hold shift to strafe instead of turn)
- [ ] Sprint (hold ctrl to move faster)
- [ ] Configurable controls
- [ ] Dim visited symbols
- [ ] Something to fill the void? Starfield? Slightly shiny floor texture? It'd
      be nice to see my reflection.

**Pause menu** (as features are added)

- [x] Shows on ESC
- [x] Resume
- [ ] Restart - randomizes the symbols and puts the player back at the start
- [x] Quit to desktop
- [ ] Keyboard/Controller navigation (is only mouse right now)
- Options
  - [ ] Dim visited symbols
  - [ ] Number of symbols
  - [ ] Board size
  - [ ] Change background track
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

---

### Assets

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
  - [ ] Kitten noises
    - [ ] For when you find the kitten, or in "hint" mode (you can hear the kitten when you call)
    - [ ] Call noise (Wall-E style whistle)
  - [ ] Menu sounds

**Art**

- [ ] Kitten (paper cut-out)
- [ ] Robot kitten heart (for win sequence)
- [ ] Splash screen/title card
- [ ] Credits screen background

---

### Chrome

** Symbol Enhancements**

- [x] Glow
- [x] Float and bob, but not all together. Kinda ethereal like.
- [ ] Additional Player Movements
  - [x] Run (speed boost?)
- Camera Modes
  - [x] FP
  - [ ] 3rd person (F3)
  - [ ] Top Down (F2)
    - [ ] Might affect controls? WASD would be relative to the camera instead of
          the player, so W would always move towards the top of the screen
          regardless of player orientation and turns happen automatically when
          changing direction.

---

**Cheat Codes**

- [ ] "mrrow" - Teleports player to right in front of kitten.
- [ ] "i<3kitten" - Win the game immediately.
- [ ] "nyan" - God Mode. Doesn't actually do anything. You just get a UI HUD
      label that says "GOD MODE ENABLED" and the nyan cat music plays. Maybe you can jump.
- [ ] "duckit" - Summons a duck that wanders around and quacks.
