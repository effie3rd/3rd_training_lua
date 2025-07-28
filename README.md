# 3rd_training_lua
Training mode for Street Fighter III: 3rd Strike on Fightcade

No Brain Update

New Features
Prediction system rework
subpixel position 
velocity based movement
Complete frame data rerecording
Menu redesign
counterattack move list
Option select on counterattack
guard jump variations, crouch tech, late tech, down forward, forward down
Attack Bars
fractional stun values
stun that the opponent recovers during an attack is now removed from the final stun value
Blocking Direction Display
ambiguous cross up option
Red Parry Miss Indicator

Load time improvements
Frame data now loads asyncronously once game starts
effectively, game pops up .5s faster
reformatted json data to improve load times

Random Character Select

Training modes
Defense
  Genei Jin
Whiff Punish
Jump In
Unblockables

Challenge

New fields
name, velocity, acceleration, pushback on block, advantage on block, next animation, optional animation, looping

Added memory addresses
velocity
acceleration
fractional stun
graphics mode
360 charge (P1+P2)
denjin charge P1


Bug Fixes
blocking multi hit attacks
blocking supers
same move performed in frame perfect succession not blocked
jumping attacks from behind/offscreen not blocked
