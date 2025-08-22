local fd = require("src.modules.framedata")
local stages = fd.stages

pose = {
  "standing",
  "crouching",
  "jumping",
  "highjumping",
}

stick_gesture = {
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
  "Kongou Kokuretsu Zan", -- Gouki hidden SA2
}
if is_4rd_strike then
  table.insert(stick_gesture, "Demon Armageddon") -- Gouki SA3
end

button_gesture =
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
  "HP+HK",
}

quick_stand =
{
  "menu_off",
  "menu_on",
  "menu_random",
}

blocking_style =
{
  "block",
  "parry",
  "red_parry",
}

blocking_mode =
{
  "menu_off",
  "menu_on",
  "menu_first_hit",
  "menu_random",
}

counter_attack_type =
{
  "none",
  "normal_attack",
  "special_sa",
  "option_select",
  "recording"
}

counter_attack_motion =
{
  "dir_5",
  "dir_6",
  "dir_3",
  "dir_2",
  "dir_1",
  "dir_4",
  "dir_7",
  "dir_8",
  "dir_9",
  "hjump_back",
  "hjump_neutral",
  "hjump_forward",
  "back_dash",
  "forward_dash",
  "kara_throw"
}

counter_attack_motion_input =
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

counter_attack_button_default =
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
counter_attack_option_select =
{
  "guard_jump_back",
  "guard_jump_neutral",
  "guard_jump_forward",
  "guard_jump_back_air_parry",
  "guard_jump_neutral_air_parry",
  "guard_jump_forward_air_parry",
  "crouch_tech",
  "block_throw",
  "shita_mae",
  "mae_shita"
}

guard_jumps =
{
  "guard_jump_back",
  "guard_jump_neutral",
  "guard_jump_forward",
  "guard_jump_back_air_parry",
  "guard_jump_neutral_air_parry",
  "guard_jump_forward_air_parry"
}

mash_stun_mode =
{
  "menu_off",
  "menu_fastest",
  "menu_realistic",
}
tech_throws_mode =
{
  "menu_on",
  "menu_off",
  "menu_random",
}

hit_type =
{
  "normal",
  "low",
  "overhead",
}

life_mode =
{
  "no_refill",
  "refill",
  "infinite"
}

meter_mode =
{
  "no_refill",
  "refill",
  "infinite"
}

stun_mode =
{
  "normal",
  "no_stun",
  "delayed_reset"
}

standing_state =
{
  "knockeddown",
  "standing",
  "crouched",
  "airborne",
}

players = {
  "Player 1",
  "Player 2",
}

player_options_list = {"off","P1","P2","P1+P2"}

display_input_history_mode = {"off","P1","P2","P1+P2","moving"}

gauge_refill_mode = {"off", "refill_max", "reset_value", "infinite" }

display_attack_bars_mode =
{
  "menu_off",
  "menu_1_line",
  "menu_2_lines"
}

language = {
  "english",
  "japanese"
}

lang_code = {
  "en",
  "jp"
}

special_training_mode = 
{
  "training_defense",
  "training_footsies",
  "training_jumpins",
  "training_geneijin",
  "training_unblockables"
}

challenge_mode = {
  "hadou_festival"
}

stage_map = {}
stage_list = {"menu_off","menu_random"}
for i = 0, 20 do
  local name = "menu_" .. stages[i].name
  if not table_contains_deep(stage_list, name) then
    table.insert(stage_list, name)
    stage_map[#stage_list] = i
  end
end

slot_replay_mode = {
  "replay_normal",
  "replay_random",
  "replay_ordered",
  "replay_repeat",
  "replay_repeat_random",
  "replay_repeat_ordered"
}

distance_display_reference_point =
{
  "origin",
  "hurtbox"
}

