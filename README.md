# effie's 3rd training lua

[日本語](https://github.com/effie3rd/3rd_training_lua/blob/main/README.jp.md)
[Installation](#Installation)\
\
![Static Badge](https://img.shields.io/badge/https%3A%2F%2Fyoutu.be%2Fk8VYlQ2uFLI?logo=YouTube&label=Trailer)

### Main Features
  - Blocking system completely rewritten
  - Framedata model improved and re-recorded from scratch
  - Special training modes
  - Several new options and displays
  - UI redesign
   
### Prediction
  - Now uses subpixel positions and velocity based movement for everything.
  - Able to parry unblockables, tengu stones, seiei enbu, and other nonsense
  - Wakeup prediction - Dummy can now do reversals after loading a savestate.
  
### Menu Redesign
  - Translucent background and readable text!
  - Dummy menu reorganized
    - Select counterattack by move name and button
    - Displays input sequence of special moves
    - Option selects can be chosen as counterattacks (Guard jumps now do not require additional setup)
      - Guard jumps, guard jumps with parry, crouch tech, block and late tech, down forward, forward down, forward forward
  - Button and menu themes
  - Japanese language support

### New Options
  - Block after first hit
  - Prefer down parry
  - Red parry every n attacks
  - Counterattack after n attacks
  - Counterattack delay
  - Mash inputs - get out of stuns and holds
  - Auto parry, Universal cancel, Infinite juggle, Infinite projectiles

### New Displays
  - Attack Bars: Compact display for comparing the damage/stun of the last two attacks
  - Attack Range: Shows the maximum range of the last 1-3 attacks
  - Blocking Direction: Shows the input the dummy used to block. Good for ambiguous crossups
  - Red Parry Miss Indicator: If you attempted a red parry and failed, red number pops up showing how many frames you were off by.
  - Stun Timer: Shows remaining stun time.
  - Air Time: Colors the opponent blue when they can no longer be juggled. The coloring is delayed by 2 frames so please use the gauge as the source of truth.
  - Parry/Charge
    - Appearance tweak
    - Tweaked follow player code
    - Compact display for parry display
    - 360/720 and Denjin displays added
  - Animated frame advantage numbers
  
### Special Training Modes
  - Defense
  - Jump Ins
  - Footsies
  - Unblockables
  - Geneijin
  
### Miscellaneous
  - Load time improvements: Frame data now loads asynchronously once the game starts; the game window now pops up half a second faster.
  - Random Character Select
  - Force Stage Select
  - Tweaked life/meter/stun refill
  - Fixed an issue regarding recording replay consistency. (Screen darkening sometimes occurs 1 frame later, desynchronizing the playback)
  - Stun value displayed in attack data now reflects the amount of stun the opponent recovered during the attack.
  - Frame advantage calculation now accounts for player movement. (Accurate frame advantage after setups)
  
### Technical Stuff
  - Refactored
  - Added memory addresses
    - velocity, acceleration, stun state, fractional stun value, graphics mode, 360 charge, air timer, timed sa state, denjin state, tengu state, hit with move type, received hit type/strength, parry state, etc.
  - Framedata now uses the following fields:
    - animation level: name, frames, hit_frames, idle_frames, loops, pushback, advantage, uses_velocity, air, infinite_loop, max_hits, cooldown, self_chain, exceptions, landing_height
    - frame level: hash, boxes, movement, velocity, acceleration, loop, next_anim, optional_anim, wakeup, bypass_freeze, projectile, ignore_motion
  - Character Select - Made selection of bosses consistent. Added option to disable selecting bosses and ability to force character selection
  - Updated debug menu

### Bug Fixes
  - Fixed detection of connected hits/projectiles
  - Blocking of various attacks and supers
  - The same move performed in frame perfect succession was not blocked
  - Jumping attacks that hit behind a cornered opponent were not blocked
  - Improved the consistency of reversals for charge/360 moves.

### Installation
<table><tr><td>Paste files into 'fbneo-training-mode' directory, overwriting all files.<br>Click "Training" from fightcade menu to run.</td></tr></table>
Note: Having 'Auto Frameskip' enabled will break things.
