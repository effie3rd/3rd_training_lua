local sd = require("src.modules.stage_data")

local stage_list = sd.menu_stages

local pose = {"menu_standing", "menu_crouching", "menu_jump_forward", "menu_jump_neutral", "menu_jump_back", "menu_sjump_forward", "menu_sjump_neutral", "menu_sjump_back"}

local button_gesture = {
   "none", "recording", "LP", "MP", "HP", "EXP", "LK", "MK", "HK", "EXK", "LP+LK", "MP+MK", "HP+HK"
}

local quick_stand_mode = {"menu_off", "menu_on", "menu_random"}

local blocking_style = {"block", "parry", "red_parry"}

local blocking_mode = {"menu_off", "menu_on", "menu_first_hit", "menu_after_first_hit", "menu_random"}

local move_selection_type = {"none", "normal_attack", "special_sa", "option_select", "recording"}

local move_selection_motion_input = {
   {{"neutral"}}, {{"forward"}}, {{"down", "forward"}}, {{"down"}}, {{"down", "back"}}, {{"back"}}, {{"up", "back"}},
   {{"up"}}, {{"up", "forward"}}, {{"down"}, {"up", "back"}}, {{"down"}, {"up"}}, {{"down"}, {"up", "forward"}},
   {{"back"}, {"back"}}, {{"forward"}, {"forward"}}, {{"maru"}, {"tilda"}, {"LP", "LK"}}
}

local move_selection_motion = {
   "dir_5", "dir_6", "dir_3", "dir_2", "dir_1", "dir_4", "dir_7", "dir_8", "dir_9", "sjump_back", "sjump_neutral",
   "sjump_forward", "back_dash", "forward_dash", "kara_throw"
}

local move_selection_normal_button_default = {"none", "LP", "MP", "HP", "LK", "MK", "HK", "LP+LK", "MP+MK", "HP+HK"}

local mash_inputs_mode = {"menu_off", "mash_normal", "mash_serious", "mash_fastest"}
local tech_throws_mode = {"menu_off", "menu_on", "menu_random"}

local hit_type = {"normal", "low", "overhead"}

local life_mode = {"menu_off", "gauge_reset_value", "gauge_reset_zero", "gauge_reset_max", "gauge_infinite"}

local stun_mode = {
   "menu_off", "gauge_reset_value", "gauge_reset_zero", "gauge_reset_max", "gauge_always_zero", "gauge_always_max"
}

local meter_mode = {"menu_off", "gauge_reset_value", "gauge_reset_zero", "gauge_reset_max", "gauge_infinite"}

local player_options = {"off", "P1", "P2", "P1+P2"}

local display_input_history_mode = {"off", "P1", "P2", "P1+P2", "moving"}

local display_attack_bars_mode = {"menu_off", "menu_1_line", "menu_2_lines"}

local language = {"english", "japanese"}

local special_training_mode = {
   "training_defense", "training_jumpins", "training_footsies", "training_unblockables", "training_geneijin",
   "training_denjin"
}

local challenge_mode = {"hadou_festival"}

local slot_replay_mode = {
   "replay_normal", "replay_random", "replay_ordered", "replay_repeat", "replay_repeat_random", "replay_repeat_ordered"
}

local distance_display_reference_point = {"distance_origin", "distance_hurtbox"}

local jumpins_position_mode = {"menu_point", "menu_dynamic"}
local jumpins_replay_mode = {"replay_random", "replay_ordered"}
local jumpins_offset_mode = {"menu_point", "menu_range_random", "menu_range_ordered", "menu_range_endpoints"}

local unblockables_types = {}
local unblockables_followup_names = {}

local theme_names = {"default"}

local menu_tables = {
   stage_list = stage_list,
   pose = pose,
   button_gesture = button_gesture,
   quick_stand_mode = quick_stand_mode,
   blocking_style = blocking_style,
   blocking_mode = blocking_mode,
   move_selection_type = move_selection_type,
   move_selection_motion_input = move_selection_motion_input,
   move_selection_motion = move_selection_motion,
   move_selection_normal_button_default = move_selection_normal_button_default,
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
   distance_display_reference_point = distance_display_reference_point,
   jumpins_position_mode = jumpins_position_mode,
   jumpins_replay_mode = jumpins_replay_mode,
   jumpins_offset_mode = jumpins_offset_mode
}

setmetatable(menu_tables, {
   __index = function(_, key)
      if key == "theme_names" then
         return theme_names
      elseif key == "unblockables_types" then
         return unblockables_types
      elseif key == "unblockables_followup_names" then
         return unblockables_followup_names
      end
   end,

   __newindex = function(_, key, value)
      if key == "theme_names" then
         theme_names = value
      elseif key == "unblockables_types" then
         unblockables_types = value
      elseif key == "unblockables_followup_names" then
         unblockables_followup_names = value
      else
         rawset(menu_tables, key, value)
      end
   end
})

return menu_tables
