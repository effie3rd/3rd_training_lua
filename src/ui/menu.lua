local gamestate = require("src.gamestate")
local move_data = require("src.modules.move_data")
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
local unblockables = require("src.training.unblockables")
local unblockables_tables = require("src.training.unblockables_tables")
local defense_tables = require("src.training.defense_tables")
local defense = require("src.training.defense")

local is_initialized = false
local is_open = false
local disable_opening = false

local save_recording_settings = {save_file_name = "", load_file_list = {}, load_file_index = 1}

local save_recording_slot_popup, load_recording_slot_popup, controller_style_menu_item, life_reset_delay_item,
      p1_life_reset_value_gauge_item, p2_life_reset_value_gauge_item, p1_stun_reset_value_gauge_item,
      p2_stun_reset_value_gauge_item, stun_reset_delay_item, load_file_name_item, p1_meter_reset_value_gauge_item,
      p2_meter_reset_value_gauge_item, meter_reset_delay_item, slot_weight_item, counter_attack_delay_item,
      recording_delay_item, recording_random_deviation_item, charge_overcharge_on_item, charge_follow_player_item,
      parry_follow_player_item, display_parry_compact_item, blocking_item, hits_before_red_parry_item,
      parry_every_n_item, prefer_down_parry_item, counter_attack_motion_item, counter_attack_normal_button_item,
      counter_attack_special_item, counter_attack_special_button_item, counter_attack_type_item,
      counter_attack_input_display_item, counter_attack_option_select_item, hits_before_counter_attack,
      character_select_item, p1_distances_reference_point_item, p2_distances_reference_point_item,
      mid_distance_height_item, air_time_player_coloring_item, attack_range_display_max_item,
      attack_bars_show_decimal_item, display_hitboxes_opacity_item, language_item, play_challenge_item,
      select_char_challenge_item, start_unblockables_item, unblockables_type_item, unblockables_followup_item

local main_menu, training_sub_menus, training_mode_item
local defense_opponent_item, start_defense_item, defense_score_item, defense_setup_item, defense_character_select_item,
      defense_learning_item

local counter_attack_settings = {
   ca_type = 1,
   motion = 1,
   normal_button = 1,
   special = 1,
   special_button = 1,
   option_select = 1
}

local counter_attack_type = menu_tables.counter_attack_type
local counter_attack_motion_input = menu_tables.counter_attack_motion_input
local counter_attack_normal_buttons = menu_tables.counter_attack_normal_button_default
local counter_attack_special_names = {}
local counter_attack_special_buttons = {}
local counter_attack_option_select_names = move_data.get_option_select_names()
local counter_attack_move_input_data
local counter_attack_button_inputs

local special_training_modes = {defense, unblockables}

local function close_menu()
   is_open = false
   main_menu:menu_stack_clear()
end

local function update_menu()
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

local function update_counter_attack_data()
   local char_str = training.dummy.char_str
   local ca_type = counter_attack_settings.type
   local ca_data = {char_str = char_str, type = ca_type, name = "normal", button = nil}
   if ca_type == 2 then
      ca_data.motion = menu_tables.counter_attack_motion[counter_attack_settings.motion]
      ca_data.button = counter_attack_normal_buttons[counter_attack_settings.normal_button]
      if counter_attack_settings.motion == 15 then
         ca_data.inputs = counter_attack_button_inputs[counter_attack_settings.normal_button]
      end
   elseif ca_type == 3 then
      ca_data.name = counter_attack_special_names[counter_attack_settings.special]
      ca_data.button = counter_attack_special_buttons[counter_attack_settings.special_button]
      ca_data.move_type = move_data.get_type_by_move_name(char_str, ca_data.name)
      ca_data.inputs = move_data.get_move_inputs_by_name(char_str, ca_data.name, ca_data.button)
   elseif ca_type == 4 then
      ca_data.name = counter_attack_option_select_names[counter_attack_settings.option_select]
   end

   counter_attack_move_input_data = ca_data
   counter_attack_input_display_item.object = ca_data
   training.counter_attack_data = ca_data
end

local function update_counter_attack_settings()
   if is_initialized then
      counter_attack_settings = settings.training.counter_attack[training.dummy.char_str]
      counter_attack_type_item.object = counter_attack_settings
      counter_attack_motion_item.object = counter_attack_settings
      counter_attack_normal_button_item.object = counter_attack_settings
      counter_attack_special_item.object = counter_attack_settings
      counter_attack_special_button_item.object = counter_attack_settings
      counter_attack_option_select_item.object = counter_attack_settings
   end
end

local function update_counter_attack_normal_button()
   counter_attack_normal_buttons = menu_tables.counter_attack_normal_button_default
   if counter_attack_settings.motion == 15 then
      counter_attack_button_inputs = move_data.get_buttons_by_move_name(training.dummy.char_str, "kara_throw")
      counter_attack_normal_buttons = tools.input_to_text(counter_attack_button_inputs)
   end
   counter_attack_normal_button_item.list = counter_attack_normal_buttons

   counter_attack_settings.normal_button = tools.bound_index(counter_attack_settings.normal_button,
                                                             #counter_attack_normal_buttons)
end

local function update_counter_attack_special_names()
   counter_attack_special_names =
       move_data.get_special_and_sa_names(training.dummy.char_str, training.dummy.selected_sa)
   counter_attack_special_item.list = counter_attack_special_names
end

local function update_counter_attack_special_button()
   local name = counter_attack_special_names[counter_attack_settings.special]
   counter_attack_special_buttons = move_data.get_buttons_by_move_name(training.dummy.char_str, name)
   counter_attack_special_button_item.list = counter_attack_special_buttons

   counter_attack_settings.special_button = tools.bound_index(counter_attack_settings.special_button,
                                                              #counter_attack_special_buttons)
end

local function update_option_select_names()
   counter_attack_option_select_names = move_data.get_option_select_names()
   counter_attack_option_select_item.list = counter_attack_option_select_names
end

local function update_counter_attack_items()
   if is_initialized then
      update_counter_attack_settings()
      update_counter_attack_normal_button()
      update_counter_attack_special_names()
      update_counter_attack_special_button()
      update_option_select_names()

      update_counter_attack_data()
      main_menu:update_dimensions()
   end
end

local function defense_at_least_one_selected()
   local opponent = defense_tables.opponents[settings.special_training.defense.opponent]
   for _, setup in ipairs(settings.special_training.defense.characters[opponent].setups) do
      if setup then return true end
   end
   return false
end

local defense_followup_check_box_grids = {}

local function update_defense_items()
   local opponent = defense_tables.opponents[settings.special_training.defense.opponent]
   local setup_names = defense_tables.get_setup_names(opponent)
   local setups_object = settings.special_training.defense.characters[opponent].setups
   if tools.deep_equal(setups_object, {}) then for i = 1, #setup_names do table.insert(setups_object, true) end end

   local followups_object = settings.special_training.defense.characters[opponent].followups
   if tools.deep_equal(followups_object, {}) then for i = 1, #setup_names do table.insert(followups_object, {}) end end

   defense_setup_item = menu_items.Check_Box_Grid_Item:new("menu_setup",
                                                           settings.special_training.defense.characters[opponent].setups,
                                                           setup_names, 4)

   local defense_sub_menu_entries = training_sub_menus[1].entries
   tools.clear_table(defense_sub_menu_entries)

   defense_followup_check_box_grids = {}
   local followup_names = defense_tables.get_followup_names(opponent)
   for i, name in ipairs(followup_names) do
      local followup_object = settings.special_training.defense.characters[opponent].followups[i]
      if not followup_object then
         settings.special_training.defense.characters[opponent].followups[i] = {}
         followup_object = settings.special_training.defense.characters[opponent].followups[i]
      end
      if tools.deep_equal(followup_object, {}) then
         for j = 1, #defense_tables.get_followup_data(opponent)[i].list do table.insert(followup_object, true) end
      end
      local followup_followup_names = defense_tables.get_followup_followup_names(opponent, i)
      local check_box_grid = menu_items.Check_Box_Grid_Item:new("menu_" .. name, followup_object,
                                                                followup_followup_names, 4)
      defense_followup_check_box_grids[i] = check_box_grid
   end

   start_defense_item.name = "menu_start"

   local saved_player = settings.special_training.defense.match_savestate_player
   if opponent == settings.special_training.defense.match_savestate_dummy then
      if saved_player ~= "" then start_defense_item.name = {"menu_start", "  (", "menu_" .. saved_player, ")"} end
   end

   defense_score_item.object = settings.special_training.defense.characters[opponent]
   defense_setup_item.object = settings.special_training.defense.characters[opponent].setups
   defense_learning_item.object = settings.special_training.defense.characters[opponent]

   defense_sub_menu_entries[1] = training_mode_item
   defense_sub_menu_entries[2] = start_defense_item
   defense_sub_menu_entries[3] = defense_score_item
   defense_sub_menu_entries[4] = defense_character_select_item
   defense_sub_menu_entries[5] = defense_opponent_item
   defense_sub_menu_entries[6] = defense_setup_item
   local i = 1
   while i <= #defense_followup_check_box_grids do
      defense_sub_menu_entries[6 + i] = defense_followup_check_box_grids[i]
      defense_sub_menu_entries[6 + i].is_visible = function() return true end
      i = i + 1
   end
   defense_sub_menu_entries[6 + i] = defense_learning_item
end

local function reset_unblockables_followup()
   local followup_obj = {}
   for k, v in pairs(unblockables_followup_item.list) do table.insert(followup_obj, false) end
   settings.special_training.unblockables.followups = followup_obj
   unblockables_followup_item.object = followup_obj
   if #followup_obj == 1 then followup_obj[1] = true end
end

local function update_unblockables_items()
   local should_reset_followup = false
   if settings.special_training.unblockables.character ~= "default" then
      start_unblockables_item.name = {
         "menu_start", "  (", "menu_" .. settings.special_training.unblockables.character, ")"
      }
   end
   local new_type_list = menu_tables.unblockables_types[settings.special_training.unblockables.character]
   if unblockables_type_item.list ~= new_type_list then
      should_reset_followup = true
      unblockables_type_item.list = new_type_list
   end
   local sel_unblockable = unblockables_type_item.list[settings.special_training.unblockables.type]
   local new_followup_list = menu_tables.unblockables_followup_names[sel_unblockable]
   if unblockables_followup_item.list ~= new_followup_list then
      should_reset_followup = true
      unblockables_followup_item.list = new_followup_list
      unblockables_followup_item:calc_dimensions()
   end
   if should_reset_followup then reset_unblockables_followup() end
end

local function play_challenge() end

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

   main_menu:menu_stack_pop(save_recording_slot_popup)
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

   main_menu:menu_stack_pop(load_recording_slot_popup)
end

local function open_save_popup()
   save_recording_slot_popup.selected_index = 1
   main_menu:menu_stack_push(save_recording_slot_popup)
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
         table.insert(save_recording_settings.load_file_list, file)
      end
   end

   load_file_name_item.list = save_recording_settings.load_file_list

   main_menu:menu_stack_push(load_recording_slot_popup)
end

local function create_recording_popup()

   load_file_name_item = menu_items.List_Menu_Item:new("file_name", save_recording_settings, "load_file_index",
                                                       save_recording_settings.load_file_list)

   save_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
   {
      menu_items.Textfield_Menu_Item:new("file_name", save_recording_settings, "save_file_name", ""),
      menu_items.Button_Menu_Item:new("file_save", save_recording_slot_to_file),
      menu_items.Button_Menu_Item:new("file_cancel", function() main_menu:menu_stack_pop(save_recording_slot_popup) end)
   })

   load_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
   {
      load_file_name_item, menu_items.Button_Menu_Item:new("file_load", load_recording_slot_from_file),
      menu_items.Button_Menu_Item:new("file_cancel", function() main_menu:menu_stack_pop(load_recording_slot_popup) end)
   })
end

local function create_jumpins_edit_menu(jumpins_edit_settings)
   jumpins_edit = {}
   jumpins_edit.jump_type_item = menu_items.List_Menu_Item:new("menu_jump_type", jumpins_edit_settings, "type",
                                                               counter_attack_type, 1, update_counter_attack_items)

   jumpins_edit.player_reset_position_item = nil
   jumpins_edit.dummy_reset_offset_item = nil

   jumpins_edit.second_jump_type_item = menu_items.List_Menu_Item:new("menu_second_jump_type", jumpins_edit_settings,
                                                                      "type", counter_attack_type, 1,
                                                                      update_counter_attack_items)

   jumpins_edit.second_jump_delay_item = menu_items.Integer_Menu_Item:new("counter_attack_delay", settings.training,
                                                                          "counter_attack_delay", 0, 40, false, 0)

   jumpins_edit.attack_type_item = menu_items.List_Menu_Item:new("menu_second_jump_type", jumpins_edit_settings, "type",
                                                                 counter_attack_type, 1, update_counter_attack_items)
   jumpins_edit.attack_delay_item = menu_items.Integer_Menu_Item:new("counter_attack_delay", settings.training,
                                                                     "counter_attack_delay", 0, 40, false, 0)

   jumpins_edit.type_item = menu_items.List_Menu_Item:new("menu_followup", jumpins_edit_settings, "type",
                                                          counter_attack_type, 1, update_counter_attack_items)

   jumpins_edit.motion_item = menu_items.Motion_list_Menu_Item:new("counter_attack_motion", jumpins_edit_settings,
                                                                   "motion", counter_attack_motion_input, 1,
                                                                   update_counter_attack_items)
   jumpins_edit.motion_item.indent = true
   jumpins_edit.motion_item.is_visible = function() return jumpins_edit_settings.type == 2 end

   jumpins_edit.normal_button_item = menu_items.List_Menu_Item:new("counter_attack_button", jumpins_edit_settings,
                                                                   "normal_button", counter_attack_normal_buttons, 1,
                                                                   update_counter_attack_items)
   jumpins_edit.normal_button_item.indent = true
   jumpins_edit.normal_button_item.is_visible = function()
      return jumpins_edit_settings.type == 2 and #counter_attack_normal_button_item.list > 0
   end

   jumpins_edit.special_item = menu_items.List_Menu_Item:new("counter_attack_special", jumpins_edit_settings, "special",
                                                             counter_attack_special_names, 1,
                                                             update_counter_attack_items)
   jumpins_edit.special_item.indent = true
   jumpins_edit.special_item.is_visible = function() return jumpins_edit_settings.type == 3 end

   jumpins_edit.special_button_item = menu_items.List_Menu_Item:new("counter_attack_button", jumpins_edit_settings,
                                                                    "special_button", counter_attack_special_buttons, 1,
                                                                    update_counter_attack_items)
   jumpins_edit.special_button_item.indent = true
   jumpins_edit.special_button_item.is_visible = function()
      return jumpins_edit_settings.type == 3 and #counter_attack_special_button_item.list > 0
   end

   jumpins_edit.input_display_item = menu_items.Move_Input_Display_Menu_Item:new("move_input",
                                                                                 counter_attack_move_input_data)
   jumpins_edit.input_display_item.inline = true
   jumpins_edit.input_display_item.is_visible = function()
      return jumpins_edit_settings.type == 3 or jumpins_edit_settings.type == 4
   end

   jumpins_edit.option_select_item = menu_items.List_Menu_Item:new("counter_attack_option_select_names",
                                                                   jumpins_edit_settings, "option_select",
                                                                   counter_attack_option_select_names, 1,
                                                                   update_counter_attack_items)
   jumpins_edit.option_select_item.indent = true
   jumpins_edit.option_select_item.is_visible = function() return jumpins_edit_settings.type == 4 end
   jumpins_edit.followup_delay_item = menu_items.Integer_Menu_Item:new("counter_attack_delay", settings.training,
                                                                       "counter_attack_delay", -40, 40, false, 0)

   jumpins_edit_menu = menu_items.Menu:new(0, 0, 150, 122, {
      jumpins_edit.player_reset_position_item, jumpins_edit.dummy_reset_offset_item
   })
end

local function create_dummy_tab()
   blocking_item = menu_items.List_Menu_Item:new("blocking", settings.training, "blocking_mode",
                                                 menu_tables.blocking_mode)
   blocking_item.indent = true

   hits_before_red_parry_item = menu_items.Hits_Before_Menu_Item:new("hits_before_rp_prefix", "hits_before_rp_suffix",
                                                                     settings.training, "red_parry_hit_count", 0, 20,
                                                                     true, 1)
   hits_before_red_parry_item.indent = true
   hits_before_red_parry_item.is_visible = function() return settings.training.blocking_style == 3 end

   parry_every_n_item = menu_items.Hits_Before_Menu_Item:new("parry_every_prefix", "parry_every_suffix",
                                                             settings.training, "parry_every_n_count", 0, 10, true, 1)
   parry_every_n_item.indent = true
   parry_every_n_item.is_visible = function() return settings.training.blocking_style == 3 end

   prefer_down_parry_item = menu_items.On_Off_Menu_Item:new("prefer_down_parry", settings.training, "prefer_down_parry")
   prefer_down_parry_item.indent = true
   prefer_down_parry_item.is_visible = function()
      return settings.training.blocking_style == 2 or settings.training.blocking_style == 3
   end

   counter_attack_type_item = menu_items.List_Menu_Item:new("counter_attack_type", counter_attack_settings, "type",
                                                            counter_attack_type, 1, update_counter_attack_items)

   counter_attack_motion_item = menu_items.Motion_list_Menu_Item:new("counter_attack_motion", counter_attack_settings,
                                                                     "motion", counter_attack_motion_input, 1,
                                                                     update_counter_attack_items)
   counter_attack_motion_item.indent = true
   counter_attack_motion_item.is_visible = function() return counter_attack_settings.type == 2 end

   counter_attack_normal_button_item = menu_items.List_Menu_Item:new("counter_attack_button", counter_attack_settings,
                                                                     "normal_button", counter_attack_normal_buttons, 1,
                                                                     update_counter_attack_items)
   counter_attack_normal_button_item.indent = true
   counter_attack_normal_button_item.is_visible = function()
      return counter_attack_settings.type == 2 and #counter_attack_normal_button_item.list > 0
   end

   counter_attack_special_item = menu_items.List_Menu_Item:new("counter_attack_special", counter_attack_settings,
                                                               "special", counter_attack_special_names, 1,
                                                               update_counter_attack_items)
   counter_attack_special_item.indent = true
   counter_attack_special_item.is_visible = function() return counter_attack_settings.type == 3 end

   counter_attack_special_button_item = menu_items.List_Menu_Item:new("counter_attack_button", counter_attack_settings,
                                                                      "special_button", counter_attack_special_buttons,
                                                                      1, update_counter_attack_items)
   counter_attack_special_button_item.indent = true
   counter_attack_special_button_item.is_visible = function()
      return counter_attack_settings.type == 3 and #counter_attack_special_button_item.list > 0
   end

   counter_attack_input_display_item = menu_items.Move_Input_Display_Menu_Item:new("move_input",
                                                                                   counter_attack_move_input_data)
   counter_attack_input_display_item.inline = true
   counter_attack_input_display_item.is_visible = function()
      return counter_attack_settings.type == 3 or counter_attack_settings.type == 4
   end

   counter_attack_option_select_item = menu_items.List_Menu_Item:new("counter_attack_option_select_names",
                                                                     counter_attack_settings, "option_select",
                                                                     counter_attack_option_select_names, 1,
                                                                     update_counter_attack_items)
   counter_attack_option_select_item.indent = true
   counter_attack_option_select_item.is_visible = function() return counter_attack_settings.type == 4 end

   hits_before_counter_attack = menu_items.Hits_Before_Menu_Item:new("hits_before_ca_prefix", "hits_before_ca_suffix",
                                                                     settings.training,
                                                                     "hits_before_counter_attack_count", 0, 20, true)
   hits_before_counter_attack.indent = true
   hits_before_counter_attack.is_visible = function() return counter_attack_settings.type ~= 1 end

   counter_attack_delay_item = menu_items.Integer_Menu_Item:new("counter_attack_delay", settings.training,
                                                                "counter_attack_delay", -40, 40, false, 0)
   counter_attack_delay_item.indent = true
   counter_attack_delay_item.is_visible = function() return counter_attack_settings.type ~= 1 end

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_dummy"),
      entries = {
         menu_items.List_Menu_Item:new("pose", settings.training, "pose", menu_tables.pose),
         menu_items.List_Menu_Item:new("blocking_style", settings.training, "blocking_style", menu_tables.blocking_style),
         blocking_item, hits_before_red_parry_item, parry_every_n_item, prefer_down_parry_item,
         counter_attack_type_item, counter_attack_motion_item, counter_attack_normal_button_item,
         counter_attack_special_item, counter_attack_input_display_item, counter_attack_special_button_item,
         counter_attack_option_select_item, hits_before_counter_attack, counter_attack_delay_item,
         menu_items.List_Menu_Item:new("tech_throws", settings.training, "tech_throws_mode",
                                       menu_tables.tech_throws_mode, 1),
         menu_items.List_Menu_Item:new("mash_inputs", settings.training, "mash_inputs_mode",
                                       menu_tables.mash_inputs_mode, 1),
         menu_items.List_Menu_Item:new("quick_stand", settings.training, "fast_wakeup_mode",
                                       menu_tables.quick_stand_mode, 1),
         menu_items.Button_Menu_Item:new("swap_dummy", function()
            training.toggle_swap_characters()
            require("src.ui.hud").add_player_label(training.dummy, "hud_dummy")
            update_counter_attack_items()
         end)
      }
   }
end

local function create_recording_tab()
   create_recording_popup()

   slot_weight_item = menu_items.Integer_Menu_Item:new("slot_weight", recording.recording_slots[settings.training
                                                           .current_recording_slot], "weight", 0, 100, false, 1)
   recording_delay_item = menu_items.Integer_Menu_Item:new("replay_delay", recording.recording_slots[settings.training
                                                               .current_recording_slot], "delay", -40, 40, false, 0)
   recording_random_deviation_item = menu_items.Integer_Menu_Item:new("replay_max_random_deviation",
                                                                      recording.recording_slots[settings.training
                                                                          .current_recording_slot], "random_deviation",
                                                                      -600, 600, false, 0, 1, 1)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_recording"),
      entries = {
         menu_items.On_Off_Menu_Item:new("auto_crop_first_frames", settings.training, "auto_crop_recording_start"),
         menu_items.On_Off_Menu_Item:new("auto_crop_last_frames", settings.training, "auto_crop_recording_end"),
         menu_items.List_Menu_Item:new("replay_mode", settings.training, "replay_mode", menu_tables.slot_replay_mode),
         menu_items.Integer_Menu_Item:new("menu_slot", settings.training, "current_recording_slot", 1,
                                          recording.recording_slot_count, true, 1, 1, 10,
                                          recording.update_current_recording_slot_frames),
         menu_items.Label_Menu_Item:new("recording_slot_frames", {"value", " ", "menu_frames"},
                                        recording.current_recording_slot_frames, "frames", true), slot_weight_item,
         recording_delay_item, recording_random_deviation_item,
         menu_items.Button_Menu_Item:new("clear_slot", function()
            recording.clear_slot()
            recording.update_current_recording_slot_frames()
         end), menu_items.Button_Menu_Item:new("clear_all_slots", function()
            recording.clear_all_slots()
            recording.update_current_recording_slot_frames()
         end), menu_items.Button_Menu_Item:new("save_slot_to_file", open_save_popup),
         menu_items.Button_Menu_Item:new("load_slot_from_file", open_load_popup)
      }
   }
end

local function create_display_tab()
   controller_style_menu_item = menu_items.Controller_Style_Item:new("controller_style", settings.training,
                                                                     "controller_style", draw.controller_styles)
   controller_style_menu_item.is_visible = function()
      return settings.training.display_input or settings.training.display_input_history ~= 1
   end

   attack_bars_show_decimal_item = menu_items.On_Off_Menu_Item:new("show_decimal", settings.training,
                                                                   "attack_bars_show_decimal")
   attack_bars_show_decimal_item.indent = true
   attack_bars_show_decimal_item.is_visible = function() return settings.training.display_attack_bars > 1 end

   display_hitboxes_opacity_item = menu_items.Integer_Menu_Item:new("display_hitboxes_opacity", settings.training,
                                                                    "display_hitboxes_opacity", 5, 100, false, 100, 5)
   display_hitboxes_opacity_item.indent = true
   display_hitboxes_opacity_item.is_visible = function() return settings.training.display_hitboxes end

   mid_distance_height_item = menu_items.Integer_Menu_Item:new("mid_distance_height", settings.training,
                                                               "mid_distance_height", 0, 200, false, 10)
   mid_distance_height_item.is_visible = function() return settings.training.display_distances end

   p1_distances_reference_point_item = menu_items.List_Menu_Item:new("p1_distance_reference_point", settings.training,
                                                                     "p1_distances_reference_point",
                                                                     menu_tables.distance_display_reference_point)
   p1_distances_reference_point_item.is_visible = function() return settings.training.display_distances end

   p2_distances_reference_point_item = menu_items.List_Menu_Item:new("p2_distance_reference_point", settings.training,
                                                                     "p2_distances_reference_point",
                                                                     menu_tables.distance_display_reference_point)
   p2_distances_reference_point_item.is_visible = function() return settings.training.display_distances end

   air_time_player_coloring_item = menu_items.On_Off_Menu_Item:new("display_air_time_player_coloring",
                                                                   settings.training, "display_air_time_player_coloring")
   air_time_player_coloring_item.indent = true
   air_time_player_coloring_item.is_visible = function() return settings.training.display_air_time end

   charge_overcharge_on_item = menu_items.On_Off_Menu_Item:new("display_overcharge", settings.training,
                                                               "charge_overcharge_on")
   charge_overcharge_on_item.indent = true
   charge_overcharge_on_item.is_visible = function() return settings.training.display_charge end

   charge_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training,
                                                               "charge_follow_player")
   charge_follow_player_item.indent = true
   charge_follow_player_item.is_visible = function() return settings.training.display_charge end

   parry_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training,
                                                              "parry_follow_player")
   parry_follow_player_item.indent = true
   parry_follow_player_item.is_visible = function() return settings.training.display_parry end

   display_parry_compact_item = menu_items.On_Off_Menu_Item:new("display_parry_compact", settings.training,
                                                                "display_parry_compact")
   display_parry_compact_item.indent = true
   display_parry_compact_item.is_visible = function() return settings.training.display_parry end

   attack_range_display_max_item = menu_items.Integer_Menu_Item:new("attack_range_max_attacks", settings.training,
                                                                    "attack_range_display_max_attacks", 1, 3, true, 1)
   attack_range_display_max_item.indent = true
   attack_range_display_max_item.is_visible = function() return settings.training.display_attack_range ~= 1 end

   language_item = menu_items.List_Menu_Item:new("language", settings.training, "language", menu_tables.language, 1,
                                                 function() main_menu:update_dimensions() end)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_display"),
      entries = {
         menu_items.On_Off_Menu_Item:new("display_controllers", settings.training, "display_input"),
         controller_style_menu_item,
         menu_items.List_Menu_Item:new("display_input_history", settings.training, "display_input_history",
                                       menu_tables.display_input_history_mode, 1),
         menu_items.On_Off_Menu_Item:new("display_gauge_numbers", settings.training, "display_gauges", false),
         menu_items.On_Off_Menu_Item:new("display_bonuses", settings.training, "display_bonuses", true),
         menu_items.List_Menu_Item:new("display_attack_bars", settings.training, "display_attack_bars",
                                       menu_tables.display_attack_bars_mode, 3), attack_bars_show_decimal_item,
         menu_items.On_Off_Menu_Item:new("display_frame_advantage", settings.training, "display_frame_advantage"),
         menu_items.On_Off_Menu_Item:new("display_hitboxes", settings.training, "display_hitboxes"),
         display_hitboxes_opacity_item,
         menu_items.On_Off_Menu_Item:new("display_distances", settings.training, "display_distances"),
         mid_distance_height_item, p1_distances_reference_point_item, p2_distances_reference_point_item,
         menu_items.On_Off_Menu_Item:new("display_stun_timer", settings.training, "display_stun_timer", 2),
         menu_items.On_Off_Menu_Item:new("display_air_time", settings.training, "display_air_time"),
         air_time_player_coloring_item,
         menu_items.On_Off_Menu_Item:new("display_charge", settings.training, "display_charge"),
         charge_follow_player_item, charge_overcharge_on_item,
         menu_items.On_Off_Menu_Item:new("display_parry", settings.training, "display_parry"), parry_follow_player_item,
         display_parry_compact_item,
         menu_items.On_Off_Menu_Item:new("display_blocking_direction", settings.training, "display_blocking_direction"),
         menu_items.On_Off_Menu_Item:new("display_red_parry_miss", settings.training, "display_red_parry_miss"),
         menu_items.List_Menu_Item:new("attack_range_display", settings.training, "display_attack_range",
                                       menu_tables.player_options), attack_range_display_max_item,
         menu_items.List_Menu_Item:new("menu_theme", settings.training, "theme", menu_tables.theme_names, 1, function()
            colors.set_theme(settings.training.theme)
            require("src.loading").reload_text_images()
         end), language_item
      }
   }
end

local function create_rules_tab()
   character_select_item = menu_items.Button_Menu_Item:new("character_select",
                                                           character_select.start_character_select_sequence)

   p1_life_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p1_life_reset_value", settings.training,
                                                                   "p1_life_reset_value", 1, colors.gauges.life, 160)
   p2_life_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p2_life_reset_value", settings.training,
                                                                   "p2_life_reset_value", 1, colors.gauges.life, 160)
   life_reset_delay_item = menu_items.Integer_Menu_Item:new("reset_delay", settings.training, "life_reset_delay", 1,
                                                            100, false, 20)

   p1_life_reset_value_gauge_item.indent = true
   p2_life_reset_value_gauge_item.indent = true
   life_reset_delay_item.indent = true

   p1_life_reset_value_gauge_item.is_visible = function() return settings.training.life_mode == 2 end
   p2_life_reset_value_gauge_item.is_visible = p1_life_reset_value_gauge_item.is_visible
   life_reset_delay_item.is_visible = function()
      return not (settings.training.life_mode == 1 or settings.training.life_mode == 5)
   end

   p1_stun_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p1_stun_reset_value", settings.training,
                                                                   "p1_stun_reset_value", 1, colors.gauges.stun, 64)
   p2_stun_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p2_stun_reset_value", settings.training,
                                                                   "p2_stun_reset_value", 1, colors.gauges.stun, 64)
   stun_reset_delay_item = menu_items.Integer_Menu_Item:new("reset_delay", settings.training, "stun_reset_delay", 1,
                                                            100, false, 20)

   p1_stun_reset_value_gauge_item.indent = true
   p2_stun_reset_value_gauge_item.indent = true
   stun_reset_delay_item.indent = true

   p1_stun_reset_value_gauge_item.is_visible = function() return settings.training.stun_mode == 2 end
   p2_stun_reset_value_gauge_item.is_visible = p1_stun_reset_value_gauge_item.is_visible
   stun_reset_delay_item.is_visible = function()
      return not (settings.training.stun_mode == 1 or settings.training.stun_mode == 5)
   end

   p1_meter_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p1_meter_reset_value", settings.training,
                                                                    "p1_meter_reset_value", 2, colors.gauges.meter)
   p2_meter_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p2_meter_reset_value", settings.training,
                                                                    "p2_meter_reset_value", 2, colors.gauges.meter)
   meter_reset_delay_item = menu_items.Integer_Menu_Item:new("reset_delay", settings.training, "meter_reset_delay", 1,
                                                             100, false, 20)

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
         menu_items.List_Menu_Item:new("force_stage", settings.training, "force_stage", menu_tables.stage_list, 1),
         menu_items.On_Off_Menu_Item:new("infinite_time", settings.training, "infinite_time"),
         menu_items.List_Menu_Item:new("life_refill_mode", settings.training, "life_mode", menu_tables.life_mode, 4,
                                       update_gauge_items()), p1_life_reset_value_gauge_item,
         p2_life_reset_value_gauge_item, -- life_reset_delay_item,
         menu_items.List_Menu_Item:new("stun_refill_mode", settings.training, "stun_mode", menu_tables.stun_mode, 3,
                                       update_gauge_items()), p1_stun_reset_value_gauge_item,
         p2_stun_reset_value_gauge_item, -- stun_reset_delay_item,
         menu_items.List_Menu_Item:new("meter_refill_mode", settings.training, "meter_mode", menu_tables.meter_mode, 5,
                                       update_gauge_items()), p1_meter_reset_value_gauge_item,
         p2_meter_reset_value_gauge_item, -- meter_reset_delay_item,
         menu_items.On_Off_Menu_Item:new("infinite_super_art_time", settings.training, "infinite_sa_time"),
         menu_items.Integer_Menu_Item:new("music_volume", settings.training, "music_volume", 0, 10, false, 0),
         menu_items.On_Off_Menu_Item:new("speed_up_game_intro", settings.training, "fast_forward_intro"),
         menu_items.List_Menu_Item:new("auto_parrying", settings.training, "auto_parrying", menu_tables.player_options),
         menu_items.On_Off_Menu_Item:new("universal_cancel", settings.training, "universal_cancel"),
         menu_items.On_Off_Menu_Item:new("infinite_projectiles", settings.training, "infinite_projectiles"),
         menu_items.On_Off_Menu_Item:new("infinite_juggle", settings.training, "infinite_juggle")
      }
   }
end

local function create_training_tab()

   training_mode_item = menu_items.List_Menu_Item:new("menu_mode", settings.training, "special_training_mode",
                                                      menu_tables.special_training_mode, 1)

   local opponent = defense_tables.opponents[settings.special_training.defense.opponent]

   start_defense_item = menu_items.Button_Menu_Item:new("menu_start", function()
      local start_opponent = defense_tables.opponents[settings.special_training.defense.opponent]
      defense.start(gamestate.P1.char_str, start_opponent)
      close_menu()
   end)

   start_defense_item.is_unselectable = function() return not defense_at_least_one_selected end

   defense_score_item = menu_items.Label_Menu_Item:new("menu_score", {"menu_score", ": ", "value"},
                                                       settings.special_training.defense.characters[opponent], "score",
                                                       true)

   defense_opponent_item = menu_items.List_Menu_Item:new("menu_opponent", settings.special_training.defense, "opponent",
                                                         defense_tables.opponents_menu, 1, update_defense_items)

   defense_setup_item = menu_items.Check_Box_Grid_Item:new("menu_setup",
                                                           settings.special_training.defense.characters[opponent].setups,
                                                           defense_tables.get_setup_names(opponent), 4)

   defense_character_select_item = menu_items.Button_Menu_Item:new("character_select", defense.start_character_select)

   defense_learning_item = menu_items.On_Off_Menu_Item:new("dummy_learning",
                                                           settings.special_training.defense.characters[opponent],
                                                           "learning")

   unblockables_type_item = menu_items.List_Menu_Item:new("menu_setup", settings.special_training.unblockables, "type",
                                                          menu_tables.unblockables_types.alex, 1,
                                                          update_unblockables_items)

   unblockables_followup_item = menu_items.Check_Box_Grid_Item:new("menu_followup",
                                                                   settings.special_training.unblockables.followups,
                                                                   menu_tables.unblockables_followup_names
                                                                       .urien_midscreen_standard, 3)
   unblockables_followup_item.is_unselectable = function()
      local sel_unblockable = unblockables_type_item.list[settings.special_training.unblockables.type]
      return gamestate.P2.char_str ~= unblockables_tables.get_unblockables_character(sel_unblockable)
   end
   unblockables_followup_item.is_enabled = function() return not unblockables_followup_item.is_unselectable() end

   start_unblockables_item = menu_items.Button_Menu_Item:new("menu_start", function()
      unblockables.start()
      close_menu()
   end)
   start_unblockables_item.legend_text = "legend_lp_select_coin_start"
   start_unblockables_item.is_unselectable = function()
      local sel_unblockable = unblockables_type_item.list[settings.special_training.unblockables.type]
      return settings.special_training.unblockables.character == "default" or
                 not unblockables_followup_item:at_least_one_selected() or
                 unblockables_tables.get_unblockables_character(sel_unblockable) ~=
                 settings.special_training.unblockables.match_savestate_dummy
   end
   start_unblockables_item.is_enabled = function() return not start_unblockables_item.is_unselectable() end

   local function unblockables_character_select()
      unblockables.start_character_select()
      unblockables_followup_item.selected_col = 1
      unblockables_followup_item.selected_row = 1
      main_menu:select_item(unblockables_followup_item)
   end

   local start_jumpins_edit_item = menu_items.Button_Menu_Item:new("menu_start", function()
      local start_opponent = defense_tables.opponents[settings.special_training.defense.opponent]
      defense.start(gamestate.P1.char_str, start_opponent)
      close_menu()
   end)
   local start_jumpins_item = menu_items.Button_Menu_Item:new("menu_start", function()
      local start_opponent = defense_tables.opponents[settings.special_training.defense.opponent]
      defense.start(gamestate.P1.char_str, start_opponent)
      close_menu()
   end)

   training_sub_menus = {
      {name = "training_defense", entries = {training_mode_item}}, {
         name = "training_jumpins",
         entries = {training_mode_item, start_jumpins_item, start_jumpins_edit_item, character_select_item}
      }, {name = "training_footsies", entries = {training_mode_item}}, {
         name = "training_unblockables",
         entries = {
            training_mode_item, start_unblockables_item, unblockables_type_item, unblockables_followup_item,
            menu_items.Button_Menu_Item:new("character_select", unblockables_character_select)
         }
      }, {
         name = "training_geneijin",
         entries = {
            training_mode_item,
            menu_items.Button_Menu_Item:new("character_select", require("src.modules.record_framedata").save_frame_data)
         }
      }, {
         name = "training_denjin",
         entries = {
            training_mode_item,
            menu_items.Button_Menu_Item:new("character_select", require("src.modules.record_framedata").save_frame_data)
         }
      }
   }

   training_mode_item.on_change = function()
      main_menu.content[5].entries = training_sub_menus[settings.training.special_training_mode].entries
   end

   return {header = menu_items.Header_Menu_Item:new("menu_title_training"), entries = training_sub_menus[1].entries}
end

local function create_challenge_tab()
   play_challenge_item = menu_items.Button_Menu_Item:new("play", play_challenge)
   select_char_challenge_item = menu_items.Button_Menu_Item:new("Select Character (Current: Gill)",
                                                                select_character_hadou_matsuri)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_challenge"),
      entries = {
         menu_items.List_Menu_Item:new("challenge", settings.training, "challenge_current_mode",
                                       menu_tables.challenge_mode), play_challenge_item, select_char_challenge_item
      }
   }
end

local function create_debug_tab()
   return {
      header = menu_items.Header_Menu_Item:new("menu_title_debug"),
      entries = {
         menu_items.On_Off_Menu_Item:new("dump_state_display", debug_settings, "show_dump_state_display"),
         menu_items.On_Off_Menu_Item:new("debug_frames_display", debug_settings, "show_debug_frames_display"),
         menu_items.On_Off_Menu_Item:new("memory_view_display", debug_settings, "show_memory_view_display"),
         menu_items.On_Off_Menu_Item:new("show_predicted_hitboxes", debug_settings, "show_predicted_hitbox"),
         menu_items.Button_Menu_Item:new("record_frame_data", function()
            debug_settings.recording_framedata = true
         end),
         menu_items.Button_Menu_Item:new("save_frame_data", require("src.modules.record_framedata").save_frame_data)
      }
   }
end

local function create_menu()
   local menu_tabs = {
      create_dummy_tab(), create_recording_tab(), create_display_tab(), create_rules_tab(), create_training_tab(),
      create_challenge_tab()
   }
   if debug_settings.developer_mode then table.insert(menu_tabs, create_debug_tab()) end

   main_menu = menu_items.Multitab_Menu:new(23, 14, 360, 197, -- screen size 383,223
   menu_tabs, function()
      recording.backup_recordings()
      settings.save_training_data()
   end)

   is_initialized = true
end

local function deactivate_training_modes() for _, mode in ipairs(special_training_modes) do mode.stop() end end

local function open_menu()
   if not disable_opening then
      is_open = true
      update_counter_attack_items()
      update_gauge_items()
      update_menu()
      local special_training_name = training_sub_menus[settings.training.special_training_mode].name
      if special_training_name == "training_defense" then
         update_defense_items()
      elseif special_training_name == "training_unblockables" then
         update_unblockables_items()
      end
      deactivate_training_modes()
      main_menu:menu_stack_push(main_menu)
   end
end

local horizontal_autofire_rate = 4
local vertical_autofire_rate = 4
local function handle_input()
   if is_initialized then
      if gamestate.is_in_match then
         local should_toggle = gamestate.P1.input.pressed.start
         if debug_settings.log_enabled then should_toggle = gamestate.P1.input.released.start end
         should_toggle = not debug_settings.log_start_locked and should_toggle

         if should_toggle then
            is_open = (not is_open)
            if is_open then
               open_menu()
            else
               main_menu:menu_stack_clear()
            end
         end
      else
         close_menu()
      end

      if is_open then
         local current_entry = main_menu:menu_stack_top():current_entry()
         if current_entry ~= nil and current_entry.autofire_rate ~= nil then
            horizontal_autofire_rate = current_entry.autofire_rate
         end

         local input = {
            down = tools.check_input_down_autofire(gamestate.P1, "down", vertical_autofire_rate),
            up = tools.check_input_down_autofire(gamestate.P1, "up", vertical_autofire_rate),
            left = tools.check_input_down_autofire(gamestate.P1, "left", horizontal_autofire_rate),
            right = tools.check_input_down_autofire(gamestate.P1, "right", horizontal_autofire_rate),
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
            scroll_up = gamestate.P1.input.pressed.HP,
            scroll_down = gamestate.P1.input.pressed.HK
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
   update_menu = update_menu,
   update_gauge_items = update_gauge_items,
   update_counter_attack_items = update_counter_attack_items,
   handle_input = handle_input,
   open_menu = open_menu,
   close_menu = close_menu
}

setmetatable(menu_module, {
   __index = function(_, key)
      if key == "is_initialized" then
         return is_initialized
      elseif key == "is_open" then
         return is_open
      elseif key == "disable_opening" then
         return disable_opening
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_initialized" then
         is_initialized = value
      elseif key == "is_open" then
         is_open = value
      elseif key == "disable_opening" then
         disable_opening = value
      else
         rawset(menu_module, key, value)
      end
   end
})

return menu_module
