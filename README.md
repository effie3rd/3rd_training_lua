# 3rd_training_lua_effie
Training mode for Street Fighter III: 3rd Strike

##No Dummy Update / 脳ダミーアップデート 

##Main Features
  -Prediction system completely rewritten
  -Framedata model improved and re-recorded from scratch
  -Several new options and displays
  -UI redesign
  -Read below for details
  
##Prediction
  -Now uses subpixel positions and velocity based movement for everything.
  -Able to parry unblockables, tengu stones, and other nonsense
  
##Menu Redesign
  -Translucent background and readable text!
  -Dummy menu reorganized
    -Select counterattack by move name and button
    -Displays input sequence of special moves
    -Option selects can be chosen as counterattacks (Guard jumps now do not require additional setup)
      -Guard jumps, guard jumps with parry, crouch tech, block and late tech, down forward, forward down, forward forward
  -Controller button themes
  -Japanese language support

##New Options
  -Stun escape - off/realistic/fastest
  -Prefer down parry
  -Red parry every n attacks
  -Counterattack after n attacks
  -Counterattack delay
  -Reset life bar to value
  -Cheat parrying, Universal cancel, Infinite juggle, Infinite projectiles

##New Displays
  -Attack Bars: Compact display for comparing the damage/stun of the last two attacks
  -Attack Range Display: Shows the maximum range of the last 1-3 used attacks
  -Blocking Direction Display: What the dummy input in order to block. Good for ambiguous crossups
  -Red Parry Miss Indicator: If you attempted a red parry and failed, red number pops up showing how many frames you were off by.
  -Air Time Display: Colors the opponent blue when they can no longer be juggled. The coloring is delayed by 2 frames so please use the gauge as the source of truth.
  -Parry/Charge displays
    -Appearance update
    -Tweaked follow player code
    -Compact display for parry display
    -360/720 and Denjin displays added
    -Moved to Display tab



  
##Miscellaneous
  -Load time improvements: Frame data now loads asynchronously once the game starts; the game window pops up half a second faster.
  -Random Character Select
  -Force Stage Select
  -Stun value displayed in attack data now reflects the amount of stun the opponent recovered during the attack. e.g. All versions of Alex's power bomb do 19 stun when the opponent starts with 0 stun. However, when the opponent starts with some stun, the opponent recovers stun during the power bomb animation resulting in LP power bomb doing 16.55 stun and HP power bomb doing 15.91 stun.
  
##Training modes
  -Defense
  -Genei Jin
  -Footsies
  -Anti air
  -Unblockables

##Challenge

##Technical stuff
  -Added memory addresses
    -Velocity
    -Acceleration
    -Fractional stun value
    -Graphics mode
    -360 charge (P1+P2)
    -Denjin charge P1
  -Framedata now uses the following fields: name, velocity, acceleration, pushback, advantage, next_anim, optional_anim, looping
  -Wakeup preiction rewritten. More accurate, should allow dummy to do reversals after save state load.
  -Character Select - Made selection of bosses consistent, option to disable selecting bosses, ability to force character selection

##Bug Fixes
  -blocking multi hit attacks
  -blocking supers
  -the same move performed in frame perfect succession was not blocked
  -jumping attacks from behind/offscreen were not blocked
