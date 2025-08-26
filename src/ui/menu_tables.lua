local sd = require("src.modules.stagedata")

local stage_list = sd.menu_stages

local pose = {
  "standing",
  "crouching",
  "jumping",
  "highjumping"
}

local stick_gesture = {
  "none",
  "QCF",
  "QCB",
  "HCF",
  "HCB",
  "DPF",
  "DPB",
  "HCharge",
  "VCharge",
  "360",
  "DQCF",
  "720",
  "forward",
  "back",
  "down",
  "jump",
  "super jump",
  "forward jump",
  "forward super jump",
  "back jump",
  "back super jump",
  "back dash",
  "forward dash",
  "guard jump (See Readme)",
  --"guard back jump",
  --"guard forward jump",
  "Shun Goku Satsu", -- Gouki hidden SA1
  "Kongou Kokuretsu Zan" -- Gouki hidden SA2
}
if is_4rd_strike then
  table.insert(stick_gesture, "Demon Armageddon") -- Gouki SA3
end

local button_gesture =
{
  "none",
  "recording",
  "LP",
  "MP",
  "HP",
  "EXP",
  "LK",
  "MK",
  "HK",
  "EXK",
  "LP+LK",
  "MP+MK",
  "HP+HK"
}

local quick_stand_mode =
{
  "menu_off",
  "menu_on",
  "menu_random"
}

local blocking_style =
{
  "block",
  "parry",
  "red_parry"
}

local blocking_mode =
{
  "menu_off",
  "menu_on",
  "menu_first_hit",
  "menu_after_first_hit",
  "menu_random"
}

local counter_attack_type =
{
  "none",
  "normal_attack",
  "special_sa",
  "option_select",
  "recording"
}

local counter_attack_motion_input =
{
  {{"neutral"}},
  {{"forward"}},
  {{"down","forward"}},
  {{"down"}},
  {{"down","back"}},
  {{"back"}},
  {{"up","back"}},
  {{"up"}},
  {{"up","forward"}},
  {{"down"},{"up","back"}},
  {{"down"},{"up"}},
  {{"down"},{"up","forward"}},
  {{"back"},{"back"}},
  {{"forward"},{"forward"}},
  {{"maru"},{"tilda"},{"LP","LK"}}
}

local counter_attack_button_default =
{
  "none",
  "LP",
  "MP",
  "HP",
  "LK",
  "MK",
  "HK",
  "LP+LK",
  "MP+MK",
  "HP+HK"
}
local counter_attack_option_select =
{
  "guard_jump_back",
  "guard_jump_neutral",
  "guard_jump_forward",
  "guard_jump_back_air_parry",
  "guard_jump_neutral_air_parry",
  "guard_jump_forward_air_parry",
  "crouch_tech",
  "block_late_tech",
  "shita_mae",
  "mae_shita",
  "parry_dash"
}


local mash_inputs_mode =
{
  "menu_off",
  "mash_normal",
  "mash_serious",
  "mash_fastest"
}
local tech_throws_mode =
{
  "menu_off",
  "menu_on",
  "menu_random"
}

local hit_type =
{
  "normal",
  "low",
  "overhead"
}

local life_mode =
{
  "menu_off",
  "gauge_reset_value",
  "gauge_reset_zero",
  "gauge_reset_max",
  "gauge_infinite"
}

local stun_mode =
{
  "menu_off",
  "gauge_reset_value",
  "gauge_reset_zero",
  "gauge_reset_max",
  "gauge_always_zero",
  "gauge_always_max"
}

local meter_mode =
{
  "menu_off",
  "gauge_reset_value",
  "gauge_reset_zero",
  "gauge_reset_max",
  "gauge_infinite"
}


local player_options = {"off","P1","P2","P1+P2"}

local display_input_history_mode = {"off","P1","P2","P1+P2","moving"}

local display_attack_bars_mode =
{
  "menu_off",
  "menu_1_line",
  "menu_2_lines"
}

local language = {
  "english",
  "japanese"
}

local special_training_mode = 
{
  "training_defense",
  "training_footsies",
  "training_jumpins",
  "training_geneijin",
  "training_unblockables"
}

local challenge_mode = {
  "hadou_festival"
}

local slot_replay_mode = {
  "replay_normal",
  "replay_random",
  "replay_ordered",
  "replay_repeat",
  "replay_repeat_random",
  "replay_repeat_ordered"
}

local distance_display_reference_point =
{
  "distance_origin",
  "distance_hurtbox"
}

return {
  stage_list = stage_list,
  pose = pose,
  stick_gesture = stick_gesture,
  button_gesture = button_gesture,
  quick_stand_mode = quick_stand_mode,
  blocking_style = blocking_style,
  blocking_mode = blocking_mode,
  counter_attack_type = counter_attack_type,
  counter_attack_motion_input = counter_attack_motion_input,
  counter_attack_button_default = counter_attack_button_default,
  counter_attack_option_select = counter_attack_option_select,
  mash_inputs_mode = mash_inputs_mode,
  tech_throws_mode = tech_throws_mode,
  hit_type = hit_type,
  life_mode = life_mode,
  meter_mode = meter_mode,
  stun_mode = stun_mode,
  player_options = player_options,
  display_input_history_mode = display_input_history_mode,
  display_attack_bars_mode = display_attack_bars_mode,
  language = language,
  special_training_mode = special_training_mode,
  challenge_mode = challenge_mode,
  slot_replay_mode = slot_replay_mode,
  distance_display_reference_point = distance_display_reference_point
}
