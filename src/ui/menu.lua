local gamestate = require("src.gamestate")
local move_data = require("src.data.move_data")
local recording = require("src.control.recording")
local training = require("src.training")
local character_select = require("src.control.character_select")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local settings = require("src.settings")
local tools = require("src.tools")
local debug_settings = require("src.debug_settings")
local menu_tables = require("src.ui.menu_tables")
local menu_items = require("src.ui.menu_items")
local modules = require("src.modules")
local modes = require("src.modes")
local hud

local is_initialized = false
local is_open = false
local disable_opening = false
local open_after_match_start = false
local allow_update_while_open = false
local disable_freeze = false

local save_recording_settings = {save_file_name = "", load_file_list = {}, load_file_index = 1}

local save_recording_slot_popup, load_recording_slot_popup, controller_style_menu_item, life_reset_delay_item,
      p1_life_reset_value_gauge_item, p2_life_reset_value_gauge_item, p1_stun_reset_value_gauge_item,
      p2_stun_reset_value_gauge_item, stun_reset_delay_item, load_file_name_item, p1_meter_reset_value_gauge_item,
      p2_meter_reset_value_gauge_item, meter_reset_delay_item, slot_weight_item, counter_attack_delay_item,
      recording_delay_item, recording_random_deviation_item, charge_overcharge_on_item, charge_follow_player_item,
      parry_follow_player_item, display_parry_compact_item, blocking_item, blocking_direction_item,
      hits_before_red_parry_item, parry_every_n_item, prefer_down_parry_item, hits_before_counter_attack,
      character_select_item, p1_distances_reference_point_item, p2_distances_reference_point_item,
      mid_distance_height_item, air_time_player_coloring_item, attack_range_display_max_item,
      attack_range_display_numbers_item, attack_bars_show_decimal_item, display_hitboxes_opacity_item,
      display_hitboxes_ab_item, language_item

local main_menu, training_tab_page, training_pages, modules_tab_page, training_mode_item, modules_pages, modules_item
local training_mode_names = {}
local modules_names = {}

local counter_attack_settings
local counter_attack_move_selection_items = {
   type_item = nil,
   motion_item = nil,
   normal_button_item = nil,
   special_item = nil,
   special_button_item = nil,
   option_select_item = nil,
   input_display_item = nil
}
local counter_attack_move_selection_data = {
   type = menu_tables.move_selection_type,
   motion_input = menu_tables.move_selection_motion_input,
   normal_buttons = menu_tables.move_selection_normal_button_default,
   special_names = {},
   special_buttons = {},
   option_select_names = move_data.get_option_select_names(),
   move_input_data = {},
   button_inputs = {}
}

local close_menu, update_menu_items

local function reset_background_cache() main_menu:reset_background_cache() end

local function update_recording_items()
   recording.load_recordings(training.recordings_player.char_str)
   slot_weight_item.object = recording.recording_slots[settings.training.current_recording_slot]
   recording_delay_item.object = recording.recording_slots[settings.training.current_recording_slot]
   recording_random_deviation_item.object = recording.recording_slots[settings.training.current_recording_slot]
   recording.update_current_recording_slot_frames()
end

local function update_gauge_items()
   if is_initialized then
      settings.training.p1_meter_reset_value = math.min(settings.training.p1_meter_reset_value,
                                                        gamestate.P1.max_meter_count * gamestate.P1.max_meter_gauge)
      settings.training.p2_meter_reset_value = math.min(settings.training.p2_meter_reset_value,
                                                        gamestate.P2.max_meter_count * gamestate.P2.max_meter_gauge)
      p1_meter_reset_value_gauge_item.gauge_max = gamestate.P1.max_meter_gauge * gamestate.P1.max_meter_count
      p1_meter_reset_value_gauge_item.subdivision_count = gamestate.P1.max_meter_count
      p2_meter_reset_value_gauge_item.gauge_max = gamestate.P2.max_meter_gauge * gamestate.P2.max_meter_count
      p2_meter_reset_value_gauge_item.subdivision_count = gamestate.P2.max_meter_count
      settings.training.p1_stun_reset_value = math.min(settings.training.p1_stun_reset_value, gamestate.P1.stun_bar_max)
      settings.training.p2_stun_reset_value = math.min(settings.training.p2_stun_reset_value, gamestate.P2.stun_bar_max)
      p1_stun_reset_value_gauge_item.gauge_max = gamestate.P1.stun_bar_max
      p2_stun_reset_value_gauge_item.gauge_max = gamestate.P2.stun_bar_max
   end
end

local function update_move_selection_data(move_selection_items, move_selection_data, move_selection_settings, dummy)
   local char_str = dummy.char_str
   local type = move_selection_settings.type
   local data = {char_str = char_str, type = type, name = "normal", button = nil}
   if type == 2 then
      data.motion = menu_tables.move_selection_motion[move_selection_settings.motion]
      data.button = move_selection_data.normal_buttons[move_selection_settings.normal_button]
      if move_selection_settings.motion == 15 then
         data.inputs = move_selection_data.button_inputs[move_selection_settings.normal_button]
      end
   elseif type == 3 then
      data.name = move_selection_data.special_names[move_selection_settings.special]
      data.button = move_selection_data.special_buttons[move_selection_settings.special_button]
      data.move_type = move_data.get_type_by_move_name(char_str, data.name)
      data.inputs = move_data.get_move_inputs_by_name(char_str, data.name, data.button)
   elseif type == 4 then
      data.name = move_selection_data.option_select_names[move_selection_settings.option_select]
   end

   move_selection_data.move_input_data = data
   move_selection_items.input_display_item.object = data
end

local function update_move_selection_items(move_selection_items, move_selection_data, move_selection_settings, dummy)
   move_selection_items.type_item.object = move_selection_settings
   move_selection_items.motion_item.object = move_selection_settings
   move_selection_items.normal_button_item.object = move_selection_settings
   move_selection_items.special_item.object = move_selection_settings
   move_selection_items.special_button_item.object = move_selection_settings
   move_selection_items.option_select_item.object = move_selection_settings

   move_selection_data.normal_buttons = menu_tables.move_selection_normal_button_default
   if move_selection_settings.motion == 15 then
      move_selection_data.button_inputs = move_data.get_buttons_by_move_name(dummy.char_str, "kara_throw")
      move_selection_data.normal_buttons = tools.input_to_text(move_selection_data.button_inputs)
   end
   move_selection_items.normal_button_item.list = tools.get_menu_names(move_selection_data.normal_buttons)

   move_selection_settings.normal_button = tools.bound_index(move_selection_settings.normal_button,
                                                             #move_selection_data.normal_buttons)

   move_selection_data.special_names = move_data.get_special_and_sa_names(dummy.char_str, dummy.selected_sa)
   move_selection_items.special_item.list = tools.get_menu_names(move_selection_data.special_names)

   local name = move_selection_data.special_names[move_selection_settings.special]
   move_selection_data.special_buttons = move_data.get_buttons_by_move_name(dummy.char_str, name)
   move_selection_items.special_button_item.list = tools.get_menu_names(move_selection_data.special_buttons)

   move_selection_settings.special_button = tools.bound_index(move_selection_settings.special_button,
                                                              #move_selection_data.special_buttons)

   move_selection_data.option_select_names = move_data.get_option_select_names()
   move_selection_items.option_select_item.list = tools.get_menu_names(move_selection_data.option_select_names)
end

local function update_counter_attack_items()
   if is_initialized and gamestate.is_in_match then
      counter_attack_settings = settings.training.counter_attack[training.dummy.char_str]
      if counter_attack_settings then
         update_move_selection_items(counter_attack_move_selection_items, counter_attack_move_selection_data,
                                     counter_attack_settings, training.dummy)
         update_move_selection_data(counter_attack_move_selection_items, counter_attack_move_selection_data,
                                    counter_attack_settings, training.dummy)
         training.counter_attack_data = counter_attack_move_selection_data.move_input_data
         for _, item in pairs(counter_attack_move_selection_items) do
            if item.calc_dimensions then item:calc_dimensions() end
         end
      end
   end
end

local function update_active_training_page()
   training_tab_page.page_index = settings.training.training_mode_index
   modules.training_modules[settings.training.training_mode_index].update_menu()
   training_tab_page:calc_dimensions()
end

local function update_active_modules_page()
   modules_tab_page.page_index = settings.training.modules_index
   modules.extra_modules[settings.training.modules_index].update_menu()
   modules_tab_page:calc_dimensions()
end

local function toggle_active_modules_page()
   modules.toggle(modules.extra_modules[settings.training.modules_index])
   modules_tab_page:calc_dimensions()
end

local function swap_controls()
   training.toggle_controls()
   hud.indicate_player_controllers()
   update_menu_items()
   main_menu:reset_background_cache()
end

local function save_recording_slot_to_file()
   if save_recording_settings.save_file_name == "" then
      print(string.format("Error: Can't save to empty file name"))
      return
   end

   local path = string.format("%s%s.json", settings.recordings_path, save_recording_settings.save_file_name)
   if not tools.write_object_to_json_file(recording.recording_slots[settings.training.current_recording_slot].inputs,
                                          path) then
      print(string.format("Error: Failed to save recording to \"%s\"", path))
   else
      print(string.format("Saved slot %d to \"%s\"", settings.training.current_recording_slot, path))
   end

   main_menu:menu_close_popup(save_recording_slot_popup)
end

local function load_recording_slot_from_file()
   if #save_recording_settings.load_file_list == 0 or
       save_recording_settings.load_file_list[save_recording_settings.load_file_index] == nil then
      print(string.format("Error: Can't load from empty file name"))
      return
   end

   local path = string.format("%s%s", settings.recordings_path,
                              save_recording_settings.load_file_list[save_recording_settings.load_file_index])
   local recording_inputs = tools.read_object_from_json_file(path)
   if not recording_inputs then
      print(string.format("Error: Failed to load recording from \"%s\"", path))
   else
      recording.recording_slots[settings.training.current_recording_slot].inputs = recording_inputs
      print(string.format("Loaded \"%s\" to slot %d", path, settings.training.current_recording_slot))
   end
   settings.save_training_data()

   recording.update_current_recording_slot_frames()

   main_menu:menu_close_popup(load_recording_slot_popup)
end

local function open_save_popup()
   save_recording_slot_popup.selected_index = 1
   main_menu:menu_open_popup(save_recording_slot_popup)
   save_recording_settings.save_file_name = string.gsub(training.dummy.char_str, "(.*)", string.upper) .. "_"
end

local function open_load_popup()
   load_recording_slot_popup.selected_index = 1

   save_recording_settings.load_file_index = 1

   local is_windows = package.config:sub(1, 1) == "\\"

   local cmd
   if is_windows then
      cmd = "dir /b " .. string.gsub(settings.recordings_path, "/", "\\")
   else
      cmd = "ls -a " .. settings.recordings_path
   end
   local f = io.popen(cmd)
   if f == nil then
      print(string.format("Error: Failed to execute command \"%s\"", cmd))
      return
   end
   local str = f:read("*all")
   save_recording_settings.load_file_list = {}
   for line in string.gmatch(str, "([^\r\n]+)") do -- Split all lines that have ".json" in them
      if string.find(line, ".json") ~= nil then
         local file = line
         save_recording_settings.load_file_list[#save_recording_settings.load_file_list + 1] = file
      end
   end

   load_file_name_item.list = save_recording_settings.load_file_list

   main_menu:menu_open_popup(load_recording_slot_popup)
end

local function create_recording_popup()

   load_file_name_item = menu_items.List_Menu_Item:new("menu_file_name", save_recording_settings, "load_file_index",
                                                       save_recording_settings.load_file_list)

   save_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
   {
      menu_items.Textfield_Menu_Item:new("menu_file_name", save_recording_settings, "save_file_name", ""),
      menu_items.Button_Menu_Item:new("menu_file_save", save_recording_slot_to_file),
      menu_items.Button_Menu_Item:new("menu_file_cancel",
                                      function() main_menu:menu_close_popup(save_recording_slot_popup) end)
   })

   load_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
   {
      load_file_name_item, menu_items.Button_Menu_Item:new("menu_file_load", load_recording_slot_from_file),
      menu_items.Button_Menu_Item:new("menu_file_cancel",
                                      function() main_menu:menu_close_popup(load_recording_slot_popup) end)
   })
end

local function create_dummy_tab()
   counter_attack_settings = settings.training.counter_attack["alex"]
   blocking_item = menu_items.List_Menu_Item:new("menu_blocking", settings.training, "blocking_mode",
                                                 menu_tables.blocking_mode)
   blocking_item.indent = true
   blocking_direction_item = menu_items.List_Menu_Item:new("menu_blocking_direction", settings.training,
                                                           "blocking_direction", menu_tables.blocking_direction)
   blocking_direction_item.indent = true
   blocking_direction_item.is_visible = function() return settings.training.blocking_style == 1 end

   hits_before_red_parry_item = menu_items.Hits_Before_Menu_Item:new("menu_hits_before_rp_prefix",
                                                                     "menu_hits_before_rp_suffix", settings.training,
                                                                     "red_parry_hit_count", 0, 20, true, 1)
   hits_before_red_parry_item.indent = true
   hits_before_red_parry_item.is_visible = function() return settings.training.blocking_style == 3 end

   parry_every_n_item = menu_items.Hits_Before_Menu_Item:new("menu_parry_every_prefix", "menu_parry_every_suffix",
                                                             settings.training, "parry_every_n_count", 0, 10, true, 1)
   parry_every_n_item.indent = true
   parry_every_n_item.is_visible = function() return settings.training.blocking_style == 3 end

   prefer_down_parry_item = menu_items.On_Off_Menu_Item:new("menu_prefer_down_parry", settings.training,
                                                            "prefer_down_parry", false)
   prefer_down_parry_item.indent = true
   prefer_down_parry_item.is_visible = function()
      return settings.training.blocking_style == 2 or settings.training.blocking_style == 3
   end

   counter_attack_move_selection_items.type_item = menu_items.List_Menu_Item:new("menu_counter_attack_type",
                                                                                 counter_attack_settings, "type",
                                                                                 counter_attack_move_selection_data.type,
                                                                                 1, update_counter_attack_items)

   counter_attack_move_selection_items.motion_item = menu_items.Motion_List_Menu_Item:new("menu_counter_attack_motion",
                                                                                          counter_attack_settings,
                                                                                          "motion",
                                                                                          counter_attack_move_selection_data.motion_input,
                                                                                          1, update_counter_attack_items)
   counter_attack_move_selection_items.motion_item.indent = true
   counter_attack_move_selection_items.motion_item.is_visible = function() return counter_attack_settings.type == 2 end

   counter_attack_move_selection_items.normal_button_item = menu_items.List_Menu_Item:new("menu_counter_attack_button",
                                                                                          counter_attack_settings,
                                                                                          "normal_button",
                                                                                          counter_attack_move_selection_data.normal_buttons,
                                                                                          1, update_counter_attack_items)
   counter_attack_move_selection_items.normal_button_item.indent = true
   counter_attack_move_selection_items.normal_button_item.is_visible = function()
      return counter_attack_settings.type == 2 and #counter_attack_move_selection_items.normal_button_item.list > 0
   end

   counter_attack_move_selection_items.special_item = menu_items.List_Menu_Item:new("menu_counter_attack_special",
                                                                                    counter_attack_settings, "special",
                                                                                    counter_attack_move_selection_data.special_names,
                                                                                    1, update_counter_attack_items)
   counter_attack_move_selection_items.special_item.indent = true
   counter_attack_move_selection_items.special_item.is_visible = function() return counter_attack_settings.type == 3 end

   counter_attack_move_selection_items.special_button_item =
       menu_items.List_Menu_Item:new("menu_counter_attack_button", counter_attack_settings, "special_button",
                                     counter_attack_move_selection_data.special_buttons, 1, update_counter_attack_items)
   counter_attack_move_selection_items.special_button_item.indent = true
   counter_attack_move_selection_items.special_button_item.is_visible = function()
      return counter_attack_settings.type == 3 and #counter_attack_move_selection_items.special_button_item.list > 0
   end

   counter_attack_move_selection_items.input_display_item = menu_items.Move_Input_Display_Menu_Item:new("move_input",
                                                                                                        counter_attack_move_selection_data.move_input_data,
                                                                                                        counter_attack_move_selection_items.special_item)
   counter_attack_move_selection_items.input_display_item.inline = true
   counter_attack_move_selection_items.input_display_item.is_visible = function()
      return counter_attack_settings.type == 3 or counter_attack_settings.type == 4
   end

   counter_attack_move_selection_items.option_select_item = menu_items.List_Menu_Item:new(
                                                                "menu_counter_attack_option_select_names",
                                                                counter_attack_settings, "option_select",
                                                                counter_attack_move_selection_data.option_select_names,
                                                                1, update_counter_attack_items)
   counter_attack_move_selection_items.option_select_item.indent = true
   counter_attack_move_selection_items.option_select_item.is_visible = function()
      return counter_attack_settings.type == 4
   end

   hits_before_counter_attack = menu_items.Hits_Before_Menu_Item:new("menu_hits_before_ca_prefix",
                                                                     "menu_hits_before_ca_suffix", settings.training,
                                                                     "hits_before_counter_attack_count", 0, 20, true)
   hits_before_counter_attack.indent = true
   hits_before_counter_attack.is_visible = function() return counter_attack_settings.type ~= 1 end

   counter_attack_delay_item = menu_items.Integer_Menu_Item:new("menu_counter_attack_delay", settings.training,
                                                                "counter_attack_delay", -40, 40, false, 0)
   counter_attack_delay_item.indent = true
   counter_attack_delay_item.is_visible = function() return counter_attack_settings.type ~= 1 end

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_dummy"),
      entries = {
         menu_items.List_Menu_Item:new("menu_pose", settings.training, "pose", menu_tables.pose),
         menu_items.List_Menu_Item:new("menu_blocking_style", settings.training, "blocking_style",
                                       menu_tables.blocking_style), blocking_item, blocking_direction_item,
         hits_before_red_parry_item, parry_every_n_item, prefer_down_parry_item,
         counter_attack_move_selection_items.type_item, counter_attack_move_selection_items.motion_item,
         counter_attack_move_selection_items.normal_button_item, counter_attack_move_selection_items.special_item,
         counter_attack_move_selection_items.input_display_item,
         counter_attack_move_selection_items.special_button_item,
         counter_attack_move_selection_items.option_select_item, hits_before_counter_attack, counter_attack_delay_item,
         menu_items.List_Menu_Item:new("menu_tech_throws", settings.training, "tech_throws_mode",
                                       menu_tables.tech_throws_mode, 1),
         menu_items.List_Menu_Item:new("menu_mash_inputs", settings.training, "mash_inputs_mode",
                                       menu_tables.mash_inputs_mode, 1),
         menu_items.List_Menu_Item:new("menu_quick_stand", settings.training, "fast_wakeup_mode",
                                       menu_tables.off_on_random, 1),
         menu_items.Button_Menu_Item:new("menu_swap_controls", swap_controls)
      }
   }
end

local function create_recording_tab()
   create_recording_popup()

   slot_weight_item = menu_items.Integer_Menu_Item:new("menu_slot_weight", recording.recording_slots[settings.training
                                                           .current_recording_slot], "weight", 0, 100, false, 1)
   recording_delay_item = menu_items.Integer_Menu_Item:new("menu_replay_delay",
                                                           recording.recording_slots[settings.training
                                                               .current_recording_slot], "delay", -40, 40, false, 0)
   recording_random_deviation_item = menu_items.Integer_Menu_Item:new("menu_replay_max_random_deviation",
                                                                      recording.recording_slots[settings.training
                                                                          .current_recording_slot], "random_deviation",
                                                                      0, 600, false, 0, 1, 1)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_recording"),
      entries = {
         menu_items.On_Off_Menu_Item:new("menu_player_positioning", settings.training, "recording_player_positioning",
                                         false),
         menu_items.On_Off_Menu_Item:new("menu_dummy_positioning", settings.training, "recording_dummy_positioning",
                                         false),
         menu_items.On_Off_Menu_Item:new("menu_auto_crop_first_frames", settings.training, "auto_crop_recording_start",
                                         false),
         menu_items.On_Off_Menu_Item:new("menu_auto_crop_last_frames", settings.training, "auto_crop_recording_end",
                                         false),
         menu_items.List_Menu_Item:new("menu_replay_mode", settings.training, "replay_mode",
                                       menu_tables.slot_replay_mode),
         menu_items.Integer_Menu_Item:new("menu_slot", settings.training, "current_recording_slot", 1,
                                          recording.recording_slot_count, true, 1, 1, 10,
                                          recording.update_current_recording_slot_frames),
         menu_items.Label_Menu_Item:new("recording_slot_frames", {"value", " ", "menu_frames"},
                                        recording.current_recording_slot_frames, "frames", false, true),
         slot_weight_item, recording_delay_item, recording_random_deviation_item,
         menu_items.Button_Menu_Item:new("menu_clear_slot", function()
            recording.clear_slot()
            recording.update_current_recording_slot_frames()
         end), menu_items.Button_Menu_Item:new("menu_clear_all_slots", function()
            recording.clear_all_slots()
            recording.update_current_recording_slot_frames()
         end), menu_items.Button_Menu_Item:new("menu_save_slot_to_file", open_save_popup),
         menu_items.Button_Menu_Item:new("menu_load_slot_from_file", open_load_popup)
      }
   }
end

local function create_display_tab()

   controller_style_menu_item = menu_items.Controller_Style_Item:new("menu_controller_style", settings.training,
                                                                     "controller_style",
                                                                     draw.controller_style_menu_names)
   controller_style_menu_item.is_visible = function()
      return settings.training.display_input or settings.training.display_input_history ~= 1
   end

   attack_bars_show_decimal_item = menu_items.On_Off_Menu_Item:new("menu_show_decimal", settings.training,
                                                                   "attack_bars_show_decimal", false,
                                                                   reset_background_cache)
   attack_bars_show_decimal_item.indent = true
   attack_bars_show_decimal_item.is_visible = function() return settings.training.display_attack_bars > 1 end

   display_hitboxes_ab_item = menu_items.On_Off_Menu_Item:new("menu_display_hitboxes_ab", settings.training,
                                                              "display_hitboxes_ab", false)
   display_hitboxes_ab_item.indent = true
   display_hitboxes_ab_item.is_visible = function() return settings.training.display_hitboxes > 1 end
   display_hitboxes_ab_item.on_change = reset_background_cache

   display_hitboxes_opacity_item = menu_items.Integer_Menu_Item:new("menu_display_hitboxes_opacity", settings.training,
                                                                    "display_hitboxes_opacity", 5, 100, false, 100, 5)
   display_hitboxes_opacity_item.indent = true
   display_hitboxes_opacity_item.is_visible = function() return settings.training.display_hitboxes > 1 end
   display_hitboxes_opacity_item.on_change = reset_background_cache

   mid_distance_height_item = menu_items.Integer_Menu_Item:new("menu_mid_distance_height", settings.training,
                                                               "mid_distance_height", 0, 200, false, 10)
   mid_distance_height_item.indent = true
   mid_distance_height_item.is_visible = function() return settings.training.display_distances end
   mid_distance_height_item.on_change = reset_background_cache

   p1_distances_reference_point_item = menu_items.List_Menu_Item:new("menu_p1_distance_reference_point",
                                                                     settings.training, "p1_distances_reference_point",
                                                                     menu_tables.distance_display_reference_point)
   p1_distances_reference_point_item.indent = true
   p1_distances_reference_point_item.is_visible = function() return settings.training.display_distances end
   p1_distances_reference_point_item.on_change = reset_background_cache

   p2_distances_reference_point_item = menu_items.List_Menu_Item:new("menu_p2_distance_reference_point",
                                                                     settings.training, "p2_distances_reference_point",
                                                                     menu_tables.distance_display_reference_point)
   p2_distances_reference_point_item.indent = true
   p2_distances_reference_point_item.is_visible = function() return settings.training.display_distances end
   p2_distances_reference_point_item.on_change = reset_background_cache

   air_time_player_coloring_item = menu_items.On_Off_Menu_Item:new("menu_display_air_time_player_coloring",
                                                                   settings.training,
                                                                   "display_air_time_player_coloring", false,
                                                                   reset_background_cache)
   air_time_player_coloring_item.indent = true
   air_time_player_coloring_item.is_visible = function() return settings.training.display_air_time end

   charge_overcharge_on_item = menu_items.On_Off_Menu_Item:new("menu_display_overcharge", settings.training,
                                                               "charge_overcharge_on", false, reset_background_cache)
   charge_overcharge_on_item.indent = true
   charge_overcharge_on_item.is_visible = function() return settings.training.display_charge end

   charge_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training,
                                                               "charge_follow_player", false, reset_background_cache)
   charge_follow_player_item.indent = true
   charge_follow_player_item.is_visible = function() return settings.training.display_charge end

   parry_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training,
                                                              "parry_follow_player", false, reset_background_cache)
   parry_follow_player_item.indent = true
   parry_follow_player_item.is_visible = function() return settings.training.display_parry end

   display_parry_compact_item = menu_items.On_Off_Menu_Item:new("menu_display_parry_compact", settings.training,
                                                                "display_parry_compact", false, reset_background_cache)
   display_parry_compact_item.indent = true
   display_parry_compact_item.is_visible = function() return settings.training.display_parry end

   attack_range_display_max_item = menu_items.Integer_Menu_Item:new("menu_attack_range_display_max_attacks",
                                                                    settings.training,
                                                                    "attack_range_display_max_attacks", 1, 3, true, 1)
   attack_range_display_max_item.indent = true
   attack_range_display_max_item.is_visible = function() return settings.training.display_attack_range ~= 1 end
   attack_range_display_max_item.on_change = reset_background_cache

   attack_range_display_numbers_item = menu_items.On_Off_Menu_Item:new("menu_attack_range_display_show_numbers",
                                                                       settings.training,
                                                                       "attack_range_display_show_numbers", false,
                                                                       reset_background_cache)
   attack_range_display_numbers_item.indent = true
   attack_range_display_numbers_item.is_visible = function() return settings.training.display_attack_range ~= 1 end

   language_item = menu_items.List_Menu_Item:new("menu_language", settings.training, "language", menu_tables.language,
                                                 1, function()
      main_menu:update_dimensions_of_all_items()
      main_menu:update_page_position()
      update_active_training_page()
      update_active_modules_page()
   end)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_display"),
      entries = {
         menu_items.On_Off_Menu_Item:new("menu_display_controllers", settings.training, "display_input", true),
         controller_style_menu_item,
         menu_items.List_Menu_Item:new("menu_display_input_history", settings.training, "display_input_history",
                                       menu_tables.display_input_history_mode, 1, reset_background_cache),
         menu_items.On_Off_Menu_Item:new("menu_display_gauge_numbers", settings.training, "display_gauges", false,
                                         reset_background_cache),
         menu_items.On_Off_Menu_Item:new("menu_display_bonuses", settings.training, "display_bonuses", true,
                                         reset_background_cache),
         menu_items.List_Menu_Item:new("menu_display_attack_bars", settings.training, "display_attack_bars",
                                       menu_tables.display_attack_bars_mode, 3, reset_background_cache),
         attack_bars_show_decimal_item,
         menu_items.List_Menu_Item:new("menu_display_frame_advantage", settings.training, "display_frame_advantage",
                                       menu_tables.display_frame_advantage_mode, 1, reset_background_cache),
         menu_items.List_Menu_Item:new("menu_display_hitboxes", settings.training, "display_hitboxes",
                                       menu_tables.player_options, 1, reset_background_cache), display_hitboxes_ab_item,
         display_hitboxes_opacity_item,
         menu_items.On_Off_Menu_Item:new("menu_display_distances", settings.training, "display_distances", false,
                                         reset_background_cache), mid_distance_height_item,
         p1_distances_reference_point_item, p2_distances_reference_point_item,
         menu_items.On_Off_Menu_Item:new("menu_display_stun_timer", settings.training, "display_stun_timer", true,
                                         reset_background_cache),
         menu_items.On_Off_Menu_Item:new("menu_display_air_time", settings.training, "display_air_time", false,
                                         reset_background_cache), air_time_player_coloring_item,
         menu_items.On_Off_Menu_Item:new("menu_display_charge", settings.training, "display_charge", false,
                                         reset_background_cache), charge_follow_player_item, charge_overcharge_on_item,
         menu_items.On_Off_Menu_Item:new("menu_display_parry", settings.training, "display_parry", false,
                                         reset_background_cache), parry_follow_player_item, display_parry_compact_item,
         menu_items.On_Off_Menu_Item:new("menu_display_blocking_direction", settings.training,
                                         "display_blocking_direction", false, reset_background_cache),
         menu_items.On_Off_Menu_Item:new("menu_display_red_parry_miss", settings.training, "display_red_parry_miss",
                                         false, reset_background_cache),
         menu_items.List_Menu_Item:new("menu_display_attack_range", settings.training, "display_attack_range",
                                       menu_tables.player_options, 1, reset_background_cache),
         attack_range_display_max_item, attack_range_display_numbers_item,
         menu_items.List_Menu_Item:new("menu_theme", settings.training, "theme", menu_tables.theme_names, 1, function()
            colors.set_theme(settings.training.theme)
            main_menu:reset_background_cache()
         end), language_item
      }
   }
end

local function create_rules_tab()
   character_select_item = menu_items.Button_Menu_Item:new("menu_character_select",
                                                           character_select.start_character_select_sequence)

   p1_life_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("menu_p1_life_reset_value", settings.training,
                                                                   "p1_life_reset_value", 1, colors.gauges.life, 160)
   p2_life_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("menu_p2_life_reset_value", settings.training,
                                                                   "p2_life_reset_value", 1, colors.gauges.life, 160)
   life_reset_delay_item = menu_items.Integer_Menu_Item:new("menu_reset_delay", settings.training, "life_reset_delay",
                                                            1, 100, false, 20)

   p1_life_reset_value_gauge_item.indent = true
   p2_life_reset_value_gauge_item.indent = true
   life_reset_delay_item.indent = true

   p1_life_reset_value_gauge_item.is_visible = function() return settings.training.life_mode == 2 end
   p2_life_reset_value_gauge_item.is_visible = p1_life_reset_value_gauge_item.is_visible
   life_reset_delay_item.is_visible = function()
      return not (settings.training.life_mode == 1 or settings.training.life_mode == 5)
   end

   p1_stun_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("menu_p1_stun_reset_value", settings.training,
                                                                   "p1_stun_reset_value", 1, colors.gauges.stun, 64)
   p2_stun_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("menu_p2_stun_reset_value", settings.training,
                                                                   "p2_stun_reset_value", 1, colors.gauges.stun, 64)
   stun_reset_delay_item = menu_items.Integer_Menu_Item:new("menu_reset_delay", settings.training, "stun_reset_delay",
                                                            1, 100, false, 20)

   p1_stun_reset_value_gauge_item.indent = true
   p2_stun_reset_value_gauge_item.indent = true
   stun_reset_delay_item.indent = true

   p1_stun_reset_value_gauge_item.is_visible = function() return settings.training.stun_mode == 2 end
   p2_stun_reset_value_gauge_item.is_visible = p1_stun_reset_value_gauge_item.is_visible
   stun_reset_delay_item.is_visible = function()
      return not (settings.training.stun_mode == 1 or settings.training.stun_mode == 5)
   end

   p1_meter_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("menu_p1_meter_reset_value", settings.training,
                                                                    "p1_meter_reset_value", 2, colors.gauges.meter)
   p2_meter_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("menu_p2_meter_reset_value", settings.training,
                                                                    "p2_meter_reset_value", 2, colors.gauges.meter)
   meter_reset_delay_item = menu_items.Integer_Menu_Item:new("menu_reset_delay", settings.training, "meter_reset_delay",
                                                             1, 100, false, 20)

   p1_meter_reset_value_gauge_item.indent = true
   p2_meter_reset_value_gauge_item.indent = true
   meter_reset_delay_item.indent = true

   p1_meter_reset_value_gauge_item.is_visible = function() return settings.training.meter_mode == 2 end
   p2_meter_reset_value_gauge_item.is_visible = p1_meter_reset_value_gauge_item.is_visible
   meter_reset_delay_item.is_visible = function()
      return not (settings.training.meter_mode == 1 or settings.training.meter_mode == 5)
   end

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_rules"),
      entries = {
         character_select_item,
         menu_items.List_Menu_Item:new("menu_force_stage", settings.training, "force_stage", menu_tables.stage_list, 1),
         menu_items.On_Off_Menu_Item:new("menu_infinite_time", settings.training, "infinite_time", true),
         menu_items.List_Menu_Item:new("menu_life_refill_mode", settings.training, "life_mode", menu_tables.life_mode,
                                       4, update_gauge_items()), p1_life_reset_value_gauge_item,
         p2_life_reset_value_gauge_item, -- life_reset_delay_item,
         menu_items.List_Menu_Item:new("menu_stun_refill_mode", settings.training, "stun_mode", menu_tables.stun_mode,
                                       3, update_gauge_items()), p1_stun_reset_value_gauge_item,
         p2_stun_reset_value_gauge_item, -- stun_reset_delay_item,
         menu_items.List_Menu_Item:new("menu_meter_refill_mode", settings.training, "meter_mode",
                                       menu_tables.meter_mode, 5, update_gauge_items()),
         p1_meter_reset_value_gauge_item, p2_meter_reset_value_gauge_item, -- meter_reset_delay_item,
         menu_items.On_Off_Menu_Item:new("menu_infinite_super_art_time", settings.training, "infinite_sa_time", false),
         menu_items.List_Menu_Item:new("menu_auto_parrying", settings.training, "auto_parrying",
                                       menu_tables.player_options),
         menu_items.On_Off_Menu_Item:new("menu_universal_cancel", settings.training, "universal_cancel", false),
         menu_items.On_Off_Menu_Item:new("menu_infinite_projectiles", settings.training, "infinite_projectiles", false),
         menu_items.On_Off_Menu_Item:new("menu_infinite_juggle", settings.training, "infinite_juggle", false),
         menu_items.On_Off_Menu_Item:new("menu_speed_up_game_intro", settings.training, "fast_forward_intro", true),
         menu_items.Integer_Menu_Item:new("menu_music_volume", settings.training, "music_volume", 0, 10, false, 0)
      }
   }
end

local function create_training_tab()
   training_mode_item = menu_items.List_Menu_Item:new("menu_mode", settings.training, "training_mode_index",
                                                      training_mode_names, 1)
   training_mode_item.on_change = update_active_training_page

   training_pages = {}

   for _, module in ipairs(modules.training_modules) do
      local page = module.create_menu()
      training_pages[#training_pages + 1] = page
      training_mode_names[#training_mode_names + 1] = page.name
   end

   training_tab_page = menu_items.Page_Navigation_Menu_Item:new("menu_title_training", training_pages,
                                                                training_mode_item)

   return training_tab_page
end

local function create_modules_tab()
   modules_item = menu_items.List_Menu_Item:new("menu_module", settings.training, "modules_index", modules_names, 1)
   modules_item.on_change = update_active_modules_page
   modules_item.validate_function = toggle_active_modules_page
   modules_item.legend = function()
      if modules.extra_modules[settings.training.modules_index].is_enabled then return "legend_lp_disable" end
      return "legend_lp_enable"
   end

   modules_pages = {}

   for _, module in ipairs(modules.extra_modules) do
      local page = module.create_menu()
      modules_pages[#modules_pages + 1] = page
      modules_names[#modules_names + 1] = page.name
   end

   modules_tab_page = menu_items.Page_Navigation_Menu_Item:new("menu_title_modules", modules_pages, modules_item)

   return modules_tab_page
end

local function create_debug_tab()
   return {
      header = menu_items.Header_Menu_Item:new("menu_title_debug"),
      entries = {
         menu_items.On_Off_Menu_Item:new("menu_dump_state_display", debug_settings, "show_dump_state_display", false),
         menu_items.On_Off_Menu_Item:new("menu_debug_variables_display", debug_settings, "show_debug_variables_display",
                                         false),
         menu_items.On_Off_Menu_Item:new("menu_debug_frames_display", debug_settings, "show_debug_frames_display", false),
         menu_items.On_Off_Menu_Item:new("menu_memory_view_display", debug_settings, "show_memory_view_display", false),
         menu_items.On_Off_Menu_Item:new("menu_show_predicted_hitboxes", debug_settings, "debug_hitboxes", false),
         menu_items.Button_Menu_Item:new("menu_record_frame_data",
                                         function() debug_settings.recording_framedata = true end),
         menu_items.Button_Menu_Item:new("menu_save_frame_data", require("src.data.record_framedata").save_frame_data)
      }
   }
end

local function create_menu()
   local menu_tabs = {
      create_dummy_tab(), create_recording_tab(), create_display_tab(), create_rules_tab(), create_training_tab(),
      create_modules_tab()
   }
   if debug_settings.developer_mode then menu_tabs[#menu_tabs + 1] = create_debug_tab() end

   main_menu = menu_items.Multitab_Menu:new(23, 14, 360, 197, -- screen size 383,223
   menu_tabs, function()
      recording.backup_recordings()
      settings.save_training_data()
   end)

   hud = require("src.ui.hud")
   is_initialized = true
end

update_menu_items = function()
   if not debug_settings.recording_framedata then
      update_counter_attack_items()
      update_gauge_items()
      update_recording_items()
      update_active_training_page()
      update_active_modules_page()

      main_menu:calc_dimensions()
   end
end

local function open_menu()
   if not disable_opening then
      is_open = true
      open_after_match_start = false
      update_menu_items()
      main_menu:menu_stack_push(main_menu)
      if not disable_freeze then training.freeze_game() end
   end
end

close_menu = function()
   is_open = false
   main_menu:menu_stack_clear()
   settings.save_training_data()
   training.unfreeze_game()
end

local horizontal_autofire_rate = 4
local horizontal_autofire_time
local vertical_autofire_rate = 4
local stop_mode_hold_time = 16
local menu_open_hold_limit = 8

local function update()
   if is_initialized then
      if gamestate.is_in_match then
         local should_toggle = gamestate.P1.input.pressed.start
         if modes.active_mode then
            should_toggle = false
            if gamestate.P1.input.down.start then
               hud.update_active_mode_strikeout(gamestate.P1.input.state_time.start, stop_mode_hold_time)
               if gamestate.P1.input.state_time.start >= stop_mode_hold_time then
                  modes.stop()
                  update_menu_items()
               end
            elseif gamestate.P1.input.released.start then
               hud.reset_active_mode_strikeout()
               if gamestate.P1.input.last_state_time.start <= menu_open_hold_limit then
                  should_toggle = true
               end
            end
         end
         if should_toggle then
            if not is_open then
               open_menu()
            elseif main_menu.has_popup then
               main_menu:menu_close_popup()
               update_menu_items()
               settings.save_training_data()
            else
               close_menu()
            end
         end
      elseif is_open then
         close_menu()
      end

      if is_open then
         local current_entry = main_menu:menu_stack_top():current_entry()
         if current_entry and current_entry.autofire_rate then
            horizontal_autofire_rate = current_entry.autofire_rate
            horizontal_autofire_time = current_entry.autofire_time
         else
            horizontal_autofire_rate = 4
            vertical_autofire_rate = 4
         end

         local input = {
            down = tools.check_input_down_autofire(gamestate.P1, "down", vertical_autofire_rate),
            up = tools.check_input_down_autofire(gamestate.P1, "up", vertical_autofire_rate),
            left = tools.check_input_down_autofire(gamestate.P1, "left", horizontal_autofire_rate,
                                                   horizontal_autofire_time),
            right = tools.check_input_down_autofire(gamestate.P1, "right", horizontal_autofire_rate,
                                                    horizontal_autofire_time),
            validate = {
               down = gamestate.P1.input.down.LP,
               press = gamestate.P1.input.pressed.LP,
               release = gamestate.P1.input.released.LP
            },
            reset = {
               down = gamestate.P1.input.down.MP,
               press = gamestate.P1.input.pressed.MP,
               release = gamestate.P1.input.released.MP
            },
            cancel = gamestate.P1.input.pressed.LK,
            scroll_up = {
               down = gamestate.P1.input.down.HP,
               press = gamestate.P1.input.pressed.HP,
               release = gamestate.P1.input.released.HP
            },
            scroll_down = {
               down = gamestate.P1.input.down.HK,
               press = gamestate.P1.input.pressed.HK,
               release = gamestate.P1.input.released.HK
            }
         }

         -- prevent scrolling across all menus and changing settings
         if gamestate.P1.input.down.up or gamestate.P1.input.down.down then
            input.left = false
            input.right = false
         end

         main_menu:menu_stack_update(input)
         main_menu:menu_stack_draw()
      end
   end
end

local menu_module = {
   create_menu = create_menu,
   update_recording_items = update_recording_items,
   update_gauge_items = update_gauge_items,
   update_counter_attack_items = update_counter_attack_items,
   update_move_selection_data = update_move_selection_data,
   update_move_selection_items = update_move_selection_items,
   update_active_training_page = update_active_training_page,
   update_menu_items = update_menu_items,
   update = update,
   reset_background_cache = reset_background_cache,
   swap_controls = swap_controls,
   open_menu = open_menu,
   close_menu = close_menu
}

setmetatable(menu_module, {
   __index = function(_, key)
      if key == "is_initialized" then
         return is_initialized
      elseif key == "main_menu" then
         return main_menu
      elseif key == "is_open" then
         return is_open
      elseif key == "disable_opening" then
         return disable_opening
      elseif key == "open_after_match_start" then
         return open_after_match_start
      elseif key == "allow_update_while_open" then
         return allow_update_while_open
      elseif key == "disable_freeze" then
         return disable_freeze
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_initialized" then
         is_initialized = value
      elseif key == "main_menu" then
         main_menu = value
      elseif key == "is_open" then
         is_open = value
      elseif key == "disable_opening" then
         disable_opening = value
      elseif key == "open_after_match_start" then
         open_after_match_start = value
      elseif key == "allow_update_while_open" then
         allow_update_while_open = value
      elseif key == "disable_freeze" then
         disable_freeze = value
      else
         rawset(menu_module, key, value)
      end
   end
})

return menu_module
