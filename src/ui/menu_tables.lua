local sd = require("src.data.stage_data")

local stage_list = sd.menu_stages

local pose = {"menu_standing", "menu_crouching", "menu_jump_forward", "menu_jump_neutral", "menu_jump_back", "menu_sjump_forward", "menu_sjump_neutral", "menu_sjump_back"}

local off_on_random = {"menu_off", "menu_on", "menu_random"}

local blocking_style = {"menu_block", "menu_parry", "menu_red_parry"}
local blocking_mode = {"menu_off", "menu_on", "menu_first_hit", "menu_after_first_hit", "menu_random"}
local blocking_direction = {"menu_off", "menu_always_low", "menu_always_high"}

local move_selection_type = {"menu_none", "menu_normal_attack", "menu_special_sa", "menu_option_select", "menu_recording"}

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

local mash_inputs_mode = {"menu_off", "menu_mash_normal", "menu_mash_serious", "menu_mash_fastest"}
local tech_throws_mode = {"menu_off", "menu_on", "menu_random"}

local life_mode = {"menu_off", "menu_gauge_reset_value", "menu_gauge_reset_zero", "menu_gauge_reset_max", "menu_gauge_infinite"}

local stun_mode = {
   "menu_off", "menu_gauge_reset_value", "menu_gauge_reset_zero", "menu_gauge_reset_max", "menu_gauge_always_zero", "menu_gauge_always_max"
}

local meter_mode = {"menu_off", "menu_gauge_reset_value", "menu_gauge_reset_zero", "menu_gauge_reset_max", "menu_gauge_infinite"}

local player_options = {"menu_off", "menu_P1", "menu_P2", "menu_P1+P2"}

local display_input_history_mode = {"menu_off", "menu_P1", "menu_P2", "menu_P1+P2", "menu_moving"}
local display_frame_advantage_mode = {"menu_off", "menu_number", "menu_table", "menu_both"}

local display_attack_bars_mode = {"menu_off", "menu_1_line", "menu_2_lines"}

local language = {"menu_english", "menu_japanese"}

local slot_replay_mode = {
   "menu_replay_normal", "menu_replay_random", "menu_replay_ordered", "menu_replay_repeat", "menu_replay_repeat_random", "menu_replay_repeat_ordered"
}

local distance_display_reference_point = {"menu_distance_origin", "menu_distance_hurtbox"}

local fixed_point_dynamic = {"menu_fixed_point", "menu_dynamic"}

local theme_names = {"default"}

local menu_tables = {
   stage_list = stage_list,
   pose = pose,
   off_on_random = off_on_random,
   blocking_style = blocking_style,
   blocking_mode = blocking_mode,
   blocking_direction = blocking_direction,
   move_selection_type = move_selection_type,
   move_selection_motion_input = move_selection_motion_input,
   move_selection_motion = move_selection_motion,
   move_selection_normal_button_default = move_selection_normal_button_default,
   mash_inputs_mode = mash_inputs_mode,
   tech_throws_mode = tech_throws_mode,
   life_mode = life_mode,
   meter_mode = meter_mode,
   stun_mode = stun_mode,
   player_options = player_options,
   display_input_history_mode = display_input_history_mode,
   display_frame_advantage_mode = display_frame_advantage_mode,
   display_attack_bars_mode = display_attack_bars_mode,
   language = language,
   slot_replay_mode = slot_replay_mode,
   distance_display_reference_point = distance_display_reference_point,
   fixed_point_dynamic = fixed_point_dynamic,
}

setmetatable(menu_tables, {
   __index = function(_, key)
      if key == "theme_names" then
         return theme_names
      end
   end,

   __newindex = function(_, key, value)
      if key == "theme_names" then
         theme_names = value
      else
         rawset(menu_tables, key, value)
      end
   end
})

return menu_tables
