# 3rd_training_lua_effie
Training mode for Street Fighter III: 3rd Strike

## No Dummy Update / 脳ダミーアップデート 

### Main Features
  - Prediction system completely rewritten
  - Framedata model improved and re-recorded from scratch
  - Several new options and displays
  - UI redesign
  
### Prediction
  - Now uses subpixel positions and velocity based movement for everything.
  - Able to parry unblockables, tengu stones, and other nonsense
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
  - Prefer down parry
  - Red parry every n attacks
  - Counterattack after n attacks
  - Counterattack delay
  - Mash inputs - get out of stuns and holds
  - Cheat parrying, Universal cancel, Infinite juggle, Infinite projectiles

### New Displays
  - Attack Bars: Compact display for comparing the damage/stun of the last two attacks
  - Attack Range: Shows the maximum range of the last 1-3 used attacks
  - Blocking Direction: What the dummy input in order to block. Good for ambiguous crossups
  - Red Parry Miss Indicator: If you attempted a red parry and failed, red number pops up showing how many frames you were off by.
  - Stun Timer - Shows remaining stun time.
  - Air Time: Colors the opponent blue when they can no longer be juggled. The coloring is delayed by 2 frames so please use the gauge as the source of truth.
  - Parry/Charge
    - Appearance update
    - Tweaked follow player code
    - Compact display for parry display
    - 360/720 and Denjin displays added
  
### Miscellaneous
  - Load time improvements: Frame data now loads asynchronously once the game starts; the game window now pops up half a second faster.
  - Random Character Select
  - Force Stage Select
  - Stun value displayed in attack data now reflects the amount of stun the opponent recovered during the attack. e.g. All versions of Alex's power bomb do 19 stun when the opponent starts with 0 stun. However, when the opponent starts with some stun, the opponent recovers stun during the power bomb animation resulting in LP power bomb effectively doing 16.55 stun and HP power bomb doing 15.91 stun.
  
### Training Modes
  - Tick throws
  - Genei Jin
  - Footsies
  - Anti air
  - Unblockables

### Challenge

### Technical Stuff
  - Added memory addresses
    - Velocity
    - Acceleration
    - Stun state, fractional stun value
    - Graphics mode
    - 360 charge (P1+P2)
    - Air timer P1
    - Denjin charge P1
  - Framedata now uses the following fields:
    - animation level: name, frames, hit_frames, idle_frames, loops, pushback, advantage, uses_velocity, air, infinite_loop, max_hits, cooldown, self_chain, exceptions
    - frame level: hash, boxes, movement, velocity, acceleration, loop, next_anim, optional_anim, wakeup, bypass_freeze
  - Character Select - Made selection of bosses consistent. Added option to disable selecting bosses and ability to force character selection
  - Updated debug menu

### Bug Fixes
  - Blocking of multi-hit attacks and supers
  - The same move performed in frame perfect succession was not blocked
  - Jumping attacks that hit behind a cornered opponent were not blocked

### Notes
  - Dummy blocking is imperfect, so if you absolutely need something parried then enable the cheat parrying option. Be aware that it will parry things that are normally impossible to parry.
