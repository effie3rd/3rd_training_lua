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
local jumpins_tables = require("src.training.jumpins_tables")
local jumpins = require("src.training.jumpins")
local geneijin = require("src.training.geneijin")
local geneijin_tables = require("src.training.geneijin_tables")
local footsies = require("src.training.footsies")
local footsies_tables = require("src.training.footsies_tables")
local special_modes = require("src.special_modes")

local is_initialized = false
local is_open = false
local disable_opening = false
local open_after_match_start = false
local allow_update_while_open = false

local save_recording_settings = {save_file_name = "", load_file_list = {}, load_file_index = 1}

local save_recording_slot_popup, load_recording_slot_popup, controller_style_menu_item, life_reset_delay_item,
      p1_life_reset_value_gauge_item, p2_life_reset_value_gauge_item, p1_stun_reset_value_gauge_item,
      p2_stun_reset_value_gauge_item, stun_reset_delay_item, load_file_name_item, p1_meter_reset_value_gauge_item,
      p2_meter_reset_value_gauge_item, meter_reset_delay_item, slot_weight_item, counter_attack_delay_item,
      recording_delay_item, recording_random_deviation_item, charge_overcharge_on_item, charge_follow_player_item,
      parry_follow_player_item, display_parry_compact_item, blocking_item, hits_before_red_parry_item,
      parry_every_n_item, prefer_down_parry_item, hits_before_counter_attack, character_select_item,
      p1_distances_reference_point_item, p2_distances_reference_point_item, mid_distance_height_item,
      air_time_player_coloring_item, attack_range_display_max_item, attack_range_display_numbers_item,
      attack_bars_show_decimal_item, display_hitboxes_opacity_item, language_item, unblockables_start_item,
      unblockables_type_item, unblockables_followup_item

local main_menu, training_sub_menus, training_mode_item
local defense_opponent_item, start_defense_item, defense_score_item, defense_setup_item, defense_character_select_item,
      defense_learning_item, defense_reset_item
local jumpins_edit, jumpins_training_tab, jumpins_edit_menu, jumpins_edit_settings, current_jump_settings
local footsies_training_tab, geneijin_training_tab
local challenge_tab
local jumpins_edit_jump_index = 1

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

local jumpins_edit_move_selection_items = tools.deepcopy(counter_attack_move_selection_items)
local jumpins_edit_move_selection_data = tools.deepcopy(counter_attack_move_selection_data)

local close_menu

local function update_recording_items()
   recording.load_recordings(training.dummy.char_str)
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
   move_selection_items.normal_button_item.list = move_selection_data.normal_buttons

   move_selection_settings.normal_button = tools.bound_index(move_selection_settings.normal_button,
                                                             #move_selection_data.normal_buttons)

   move_selection_data.special_names = move_data.get_special_and_sa_names(dummy.char_str, dummy.selected_sa)
   move_selection_items.special_item.list = move_selection_data.special_names

   local name = move_selection_data.special_names[move_selection_settings.special]
   move_selection_data.special_buttons = move_data.get_buttons_by_move_name(dummy.char_str, name)
   move_selection_items.special_button_item.list = move_selection_data.special_buttons

   move_selection_settings.special_button = tools.bound_index(move_selection_settings.special_button,
                                                              #move_selection_data.special_buttons)

   move_selection_data.option_select_names = move_data.get_option_select_names()
   move_selection_items.option_select_item.list = move_selection_data.option_select_names
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
         main_menu:update_dimensions()
      end
   end
end

local function update_jumpins_settings()
   if is_initialized and gamestate.is_in_match then
      jumpins.init()
      jumpins_edit_settings = settings.special_training.jumpins.characters[jumpins.jumpins_dummy.char_str]
      if not jumpins_edit_settings then
         settings.special_training.jumpins.characters[jumpins.jumpins_dummy.char_str] =
             jumpins_tables.create_settings(jumpins.jumpins_dummy)
         jumpins_edit_settings = settings.special_training.jumpins.characters[jumpins.jumpins_dummy.char_str]
      end
      current_jump_settings = jumpins_edit_settings.jumps[jumpins_edit_jump_index]
   end
end

local function update_jumpins_range_items()
   jumpins_edit.player_reset_position_item.points = jumpins.player_position_range
   jumpins_edit.player_reset_position_item.point_index = 1
   jumpins_edit.player_reset_position_item.range = jumpins.player_position_bounds
   jumpins_edit.player_reset_position_item.mode = 1

   jumpins_edit.dummy_reset_offset_item.points = jumpins.dummy_offset_range
   jumpins_edit.dummy_reset_offset_item.point_index = jumpins.dummy_offset_edit_index
   jumpins_edit.dummy_reset_offset_item.range = jumpins.dummy_offset_bounds
   jumpins_edit.dummy_reset_offset_item.mode = jumpins.dummy_offset_edit_mode

   jumpins_edit.attack_delay_item.points = jumpins.attack_delay_range
   jumpins_edit.attack_delay_item.point_index = jumpins.attack_delay_edit_index
   jumpins_edit.attack_delay_item.range = jumpins.attack_delay_bounds
   jumpins_edit.attack_delay_item.mode = jumpins.attack_delay_edit_mode

   jumpins_edit.second_jump_delay_item.points = jumpins.second_jump_delay_range
   jumpins_edit.second_jump_delay_item.point_index = 1
   jumpins_edit.second_jump_delay_item.range = jumpins.second_jump_delay_bounds
   jumpins_edit.second_jump_delay_item.mode = 1
end

local function update_jumpins_edit_items()
   if is_initialized and gamestate.is_in_match then
      update_jumpins_settings()

      update_move_selection_items(jumpins_edit_move_selection_items, jumpins_edit_move_selection_data,
                                  current_jump_settings.followup, jumpins.jumpins_dummy)
      update_move_selection_data(jumpins_edit_move_selection_items, jumpins_edit_move_selection_data,
                                 current_jump_settings.followup, jumpins.jumpins_dummy)
      jumpins.followup_data = jumpins_edit_move_selection_data.move_input_data

      jumpins_tables.update_character(jumpins.jumpins_dummy.char_str)

      jumpins_edit.jump_type_item.object = current_jump_settings
      jumpins_edit.jump_type_item.list = jumpins_tables.get_menu_jump_names()

      update_jumpins_range_items()

      jumpins_edit.second_jump_type_item.object = current_jump_settings
      jumpins_edit.second_jump_type_item.list = jumpins_tables.get_menu_second_jump_names()
      jumpins_edit.second_jump_delay_item.object = current_jump_settings
      jumpins_edit.attack_type_item.object = current_jump_settings
      jumpins_edit.attack_type_item.list = jumpins_tables.get_menu_attack_names()
      jumpins_edit.followup_delay_item.object = current_jump_settings
      jumpins_edit.status_item.object = {jump_index = jumpins_edit_jump_index}

      jumpins_training_tab.jump_replay_mode_item.object = jumpins_edit_settings
      jumpins_training_tab.player_position_mode_item.object = jumpins_edit_settings
      jumpins_training_tab.dummy_offset_mode_item.object = jumpins_edit_settings
      jumpins_training_tab.attack_delay_mode_item.object = jumpins_edit_settings
      jumpins_training_tab.show_jump_arc_item.object = jumpins_edit_settings
      jumpins_training_tab.show_jump_info_item.object = jumpins_edit_settings
      jumpins_training_tab.automatic_replay_item.object = jumpins_edit_settings

      main_menu:update_dimensions()
      jumpins_edit_menu:calc_dimensions()
   end
end

local function change_jump_index(n)
   jumpins_edit_jump_index = tools.wrap_index(jumpins_edit_jump_index + n, jumpins_tables.max_jumps)
   update_jumpins_edit_items()
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
   defense_sub_menu_entries[7 + i] = defense_reset_item
end

local function update_footsies_items()
   if not jumpins.is_active then
      footsies_tables.init(gamestate.P2.char_str)
      footsies_training_tab.score_item.object = settings.special_training.footsies.characters[gamestate.P2.char_str]
      footsies_training_tab.walk_out_item.object = settings.special_training.footsies.characters[gamestate.P2.char_str]
      footsies_training_tab.moves_item.object = settings.special_training.footsies.characters[gamestate.P2.char_str]
                                                    .moves
      footsies_training_tab.moves_item.list = footsies_tables.get_menu_move_names()
      footsies_training_tab.accuracy_item.points = settings.special_training.footsies.characters[gamestate.P2.char_str]
                                                       .accuracy
      footsies_training_tab.distance_judgement_item.points =
          settings.special_training.footsies.characters[gamestate.P2.char_str].dist_judgement
   end
end

local function update_geneijin_items()
   geneijin_training_tab.moves_item.object = settings.special_training.geneijin.moves
   local saved_player = settings.special_training.geneijin.match_savestate_player
   if saved_player ~= "" then
      geneijin_training_tab.start_item.name = {"menu_start", "  (", "menu_" .. saved_player, ")"}
   end
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
      unblockables_start_item.name = {
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

local function update_training_tab_page()
   main_menu.content[5].entries = training_sub_menus[settings.training.special_training_mode].entries
end

local function is_frame_data_loaded() return require("src.loading").frame_data_loaded end

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
         table.insert(save_recording_settings.load_file_list, file)
      end
   end

   load_file_name_item.list = save_recording_settings.load_file_list

   main_menu:menu_open_popup(load_recording_slot_popup)
end

local function create_recording_popup()

   load_file_name_item = menu_items.List_Menu_Item:new("file_name", save_recording_settings, "load_file_index",
                                                       save_recording_settings.load_file_list)

   save_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
   {
      menu_items.Textfield_Menu_Item:new("file_name", save_recording_settings, "save_file_name", ""),
      menu_items.Button_Menu_Item:new("file_save", save_recording_slot_to_file),
      menu_items.Button_Menu_Item:new("file_cancel",
                                      function() main_menu:menu_close_popup(save_recording_slot_popup) end)
   })

   load_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
   {
      load_file_name_item, menu_items.Button_Menu_Item:new("file_load", load_recording_slot_from_file),
      menu_items.Button_Menu_Item:new("file_cancel",
                                      function() main_menu:menu_close_popup(load_recording_slot_popup) end)
   })
end

local function create_jumpins_edit_menu()
   jumpins_edit_settings = settings.special_training.jumpins.characters["alex"]
   current_jump_settings = jumpins_edit_settings.jumps[1]
   local function is_jump_selected() return current_jump_settings.jump_name ~= 1 end
   local function no_jump_selected() return not is_jump_selected() end
   jumpins_edit = {}
   jumpins_edit.jump_type_item = menu_items.List_Menu_Item:new("menu_jump", current_jump_settings, "jump_name",
                                                               jumpins_tables.get_menu_jump_names(), 1)
   jumpins_edit.jump_type_item.on_change = function()
      jumpins.update_selected_jump()
      update_jumpins_edit_items()
   end

   jumpins_edit.player_reset_position_item = menu_items.Slider_Menu_Item:new("menu_player_position", 40, {400, 400},
                                                                             {200, 800})
   jumpins_edit.player_reset_position_item.disable_mode_switch = true
   jumpins_edit.player_reset_position_item.legend_text = ""
   jumpins_edit.player_reset_position_item.left = function()
      jumpins.move_player_left()
      update_jumpins_range_items()
   end
   jumpins_edit.player_reset_position_item.right = function()
      jumpins.move_player_right()
      update_jumpins_range_items()
   end
   jumpins_edit.player_reset_position_item.is_enabled = is_jump_selected
   jumpins_edit.player_reset_position_item.is_unselectable = no_jump_selected

   jumpins_edit.dummy_reset_offset_item =
       menu_items.Slider_Menu_Item:new("menu_dummy_offset", 40, {80, 80}, {-100, 100})
   jumpins_edit.dummy_reset_offset_item.left = function()
      jumpins.move_dummy_left()
      update_jumpins_range_items()
   end
   jumpins_edit.dummy_reset_offset_item.right = function()
      jumpins.move_dummy_right()
      update_jumpins_range_items()
   end
   jumpins_edit.dummy_reset_offset_item.validate_function = function()
      jumpins_edit.dummy_reset_offset_item.mode = jumpins.change_dummy_offset_edit_mode()
      update_jumpins_edit_items()
   end
   jumpins_edit.dummy_reset_offset_item.reset_function = function()
      jumpins_edit.dummy_reset_offset_item.point_index = jumpins.change_dummy_offset_edit_index()
      update_jumpins_edit_items()
   end
   jumpins_edit.dummy_reset_offset_item.is_enabled = is_jump_selected
   jumpins_edit.dummy_reset_offset_item.is_unselectable = no_jump_selected

   jumpins_edit.second_jump_type_item = menu_items.List_Menu_Item:new("menu_second_jump", current_jump_settings,
                                                                      "second_jump_name",
                                                                      jumpins_tables.get_menu_second_jump_names(), 1)
   jumpins_edit.second_jump_type_item.is_visible = function() return #jumpins_edit.second_jump_type_item.list > 0 end
   jumpins_edit.second_jump_type_item.is_enabled = is_jump_selected
   jumpins_edit.second_jump_type_item.is_unselectable = no_jump_selected
   jumpins_edit.second_jump_type_item.on_change = function()
      jumpins.update_selected_jump()
      update_jumpins_edit_items()
   end

   jumpins_edit.second_jump_delay_item = menu_items.Slider_Menu_Item:new("menu_second_jump_delay", 40, {8, 8}, {8, 40})
   jumpins_edit.second_jump_delay_item.disable_mode_switch = true
   jumpins_edit.second_jump_delay_item.legend_text = ""

   jumpins_edit.second_jump_delay_item.is_visible = function()
      return jumpins_edit.second_jump_type_item.is_visible() and current_jump_settings.second_jump_name ~= 1
   end
   jumpins_edit.second_jump_delay_item.is_enabled = is_jump_selected
   jumpins_edit.second_jump_delay_item.is_unselectable = no_jump_selected

   jumpins_edit.attack_type_item = menu_items.List_Menu_Item:new("menu_attack", current_jump_settings, "attack_name",
                                                                 jumpins_tables.get_menu_attack_names(), 1)
   jumpins_edit.attack_type_item.is_enabled = is_jump_selected
   jumpins_edit.attack_type_item.is_unselectable = no_jump_selected
   jumpins_edit.attack_type_item.on_change = update_jumpins_edit_items

   jumpins_edit.attack_delay_item = menu_items.Slider_Menu_Item:new("menu_attack_delay", 40, {5, 5}, {5, 100})
   jumpins_edit.attack_delay_item.validate_function = function()
      jumpins_edit.attack_delay_item.mode = jumpins.change_attack_delay_edit_mode()
      update_jumpins_edit_items()
   end
   jumpins_edit.attack_delay_item.reset_function = function()
      jumpins_edit.attack_delay_item.point_index = jumpins.change_attack_delay_edit_index()
      update_jumpins_edit_items()
   end
   jumpins_edit.attack_delay_item.on_change = update_jumpins_edit_items
   jumpins_edit.attack_delay_item.is_enabled = is_jump_selected
   jumpins_edit.attack_delay_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.type_item = menu_items.List_Menu_Item:new("menu_followup",
                                                                               current_jump_settings.followup, "type",
                                                                               jumpins_edit_move_selection_data.type, 1,
                                                                               update_jumpins_edit_items)
   jumpins_edit_move_selection_items.type_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.type_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.motion_item = menu_items.Motion_List_Menu_Item:new("counter_attack_motion",
                                                                                        current_jump_settings.followup,
                                                                                        "motion",
                                                                                        jumpins_edit_move_selection_data.motion_input,
                                                                                        1, update_jumpins_edit_items)
   jumpins_edit_move_selection_items.motion_item.indent = true
   jumpins_edit_move_selection_items.motion_item.is_visible = function()
      return current_jump_settings.followup.type == 2
   end
   jumpins_edit_move_selection_items.motion_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.motion_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.normal_button_item = menu_items.List_Menu_Item:new("counter_attack_button",
                                                                                        current_jump_settings.followup,
                                                                                        "normal_button",
                                                                                        jumpins_edit_move_selection_data.normal_buttons,
                                                                                        1, update_jumpins_edit_items)
   jumpins_edit_move_selection_items.normal_button_item.indent = true
   jumpins_edit_move_selection_items.normal_button_item.is_visible = function()
      return current_jump_settings.followup.type == 2 and #jumpins_edit_move_selection_items.normal_button_item.list > 0
   end
   jumpins_edit_move_selection_items.normal_button_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.normal_button_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.special_item = menu_items.List_Menu_Item:new("counter_attack_special",
                                                                                  current_jump_settings.followup,
                                                                                  "special",
                                                                                  jumpins_edit_move_selection_data.special_names,
                                                                                  1, update_jumpins_edit_items)
   jumpins_edit_move_selection_items.special_item.indent = true
   jumpins_edit_move_selection_items.special_item.is_visible = function()
      return current_jump_settings.followup.type == 3
   end
   jumpins_edit_move_selection_items.special_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.special_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.special_button_item = menu_items.List_Menu_Item:new("counter_attack_button",
                                                                                         current_jump_settings.followup,
                                                                                         "special_button",
                                                                                         jumpins_edit_move_selection_data.special_buttons,
                                                                                         1, update_jumpins_edit_items)
   jumpins_edit_move_selection_items.special_button_item.indent = true
   jumpins_edit_move_selection_items.special_button_item.is_visible = function()
      return current_jump_settings.followup.type == 3 and #jumpins_edit_move_selection_items.special_button_item.list >
                 0
   end
   jumpins_edit_move_selection_items.special_button_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.special_button_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.input_display_item = menu_items.Move_Input_Display_Menu_Item:new("move_input",
                                                                                                      jumpins_edit_move_selection_data.move_input_data,
                                                                                                      jumpins_edit_move_selection_items.special_item)
   jumpins_edit_move_selection_items.input_display_item.inline = true
   jumpins_edit_move_selection_items.input_display_item.is_visible = function()
      return current_jump_settings.followup.type == 3 or current_jump_settings.followup.type == 4
   end
   jumpins_edit_move_selection_items.input_display_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.input_display_item.is_unselectable = no_jump_selected

   jumpins_edit_move_selection_items.option_select_item = menu_items.List_Menu_Item:new(
                                                              "counter_attack_option_select_names",
                                                              current_jump_settings.followup, "option_select",
                                                              jumpins_edit_move_selection_data.option_select_names, 1,
                                                              update_jumpins_edit_items)
   jumpins_edit_move_selection_items.option_select_item.indent = true
   jumpins_edit_move_selection_items.option_select_item.is_visible = function()
      return current_jump_settings.followup.type == 4
   end
   jumpins_edit_move_selection_items.option_select_item.is_enabled = is_jump_selected
   jumpins_edit_move_selection_items.option_select_item.is_unselectable = no_jump_selected

   jumpins_edit.followup_delay_item = menu_items.Integer_Menu_Item:new("menu_followup_delay", current_jump_settings,
                                                                       "followup_delay", -40, 40, false, 0)
   jumpins_edit.followup_delay_item.is_enabled = is_jump_selected
   jumpins_edit.followup_delay_item.is_unselectable = no_jump_selected

   jumpins_edit.status_item = menu_items.Label_Menu_Item:new("status", {
      "legend_hp_hk", ": ", "status_jump", "(", "value", "/", jumpins_tables.max_jumps, ")"
   }, {jump_index = 1}, "jump_index", true)

   return menu_items.Menu:new(0, 0, 150, 150, {
      jumpins_edit.jump_type_item, jumpins_edit.player_reset_position_item, jumpins_edit.dummy_reset_offset_item,
      jumpins_edit.second_jump_type_item, jumpins_edit.second_jump_delay_item, jumpins_edit.attack_type_item,
      jumpins_edit.attack_delay_item, jumpins_edit_move_selection_items.type_item,
      jumpins_edit_move_selection_items.motion_item, jumpins_edit_move_selection_items.normal_button_item,
      jumpins_edit_move_selection_items.special_item, jumpins_edit_move_selection_items.input_display_item,
      jumpins_edit_move_selection_items.special_button_item, jumpins_edit_move_selection_items.option_select_item,
      jumpins_edit.followup_delay_item
   }, nil, true, jumpins_edit.status_item, true)
end

local function create_dummy_tab()
   counter_attack_settings = settings.training.counter_attack["alex"]
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

   prefer_down_parry_item = menu_items.On_Off_Menu_Item:new("prefer_down_parry", settings.training, "prefer_down_parry",
                                                            false)
   prefer_down_parry_item.indent = true
   prefer_down_parry_item.is_visible = function()
      return settings.training.blocking_style == 2 or settings.training.blocking_style == 3
   end

   counter_attack_move_selection_items.type_item = menu_items.List_Menu_Item:new("counter_attack_type",
                                                                                 counter_attack_settings, "type",
                                                                                 counter_attack_move_selection_data.type,
                                                                                 1, update_counter_attack_items)

   counter_attack_move_selection_items.motion_item = menu_items.Motion_List_Menu_Item:new("counter_attack_motion",
                                                                                          counter_attack_settings,
                                                                                          "motion",
                                                                                          counter_attack_move_selection_data.motion_input,
                                                                                          1, update_counter_attack_items)
   counter_attack_move_selection_items.motion_item.indent = true
   counter_attack_move_selection_items.motion_item.is_visible = function() return counter_attack_settings.type == 2 end

   counter_attack_move_selection_items.normal_button_item = menu_items.List_Menu_Item:new("counter_attack_button",
                                                                                          counter_attack_settings,
                                                                                          "normal_button",
                                                                                          counter_attack_move_selection_data.normal_buttons,
                                                                                          1, update_counter_attack_items)
   counter_attack_move_selection_items.normal_button_item.indent = true
   counter_attack_move_selection_items.normal_button_item.is_visible = function()
      return counter_attack_settings.type == 2 and #counter_attack_move_selection_items.normal_button_item.list > 0
   end

   counter_attack_move_selection_items.special_item = menu_items.List_Menu_Item:new("counter_attack_special",
                                                                                    counter_attack_settings, "special",
                                                                                    counter_attack_move_selection_data.special_names,
                                                                                    1, update_counter_attack_items)
   counter_attack_move_selection_items.special_item.indent = true
   counter_attack_move_selection_items.special_item.is_visible = function() return counter_attack_settings.type == 3 end

   counter_attack_move_selection_items.special_button_item =
       menu_items.List_Menu_Item:new("counter_attack_button", counter_attack_settings, "special_button",
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
                                                                "counter_attack_option_select_names",
                                                                counter_attack_settings, "option_select",
                                                                counter_attack_move_selection_data.option_select_names,
                                                                1, update_counter_attack_items)
   counter_attack_move_selection_items.option_select_item.indent = true
   counter_attack_move_selection_items.option_select_item.is_visible = function()
      return counter_attack_settings.type == 4
   end

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
         counter_attack_move_selection_items.type_item, counter_attack_move_selection_items.motion_item,
         counter_attack_move_selection_items.normal_button_item, counter_attack_move_selection_items.special_item,
         counter_attack_move_selection_items.input_display_item,
         counter_attack_move_selection_items.special_button_item,
         counter_attack_move_selection_items.option_select_item, hits_before_counter_attack, counter_attack_delay_item,
         menu_items.List_Menu_Item:new("tech_throws", settings.training, "tech_throws_mode",
                                       menu_tables.tech_throws_mode, 1),
         menu_items.List_Menu_Item:new("mash_inputs", settings.training, "mash_inputs_mode",
                                       menu_tables.mash_inputs_mode, 1),
         menu_items.List_Menu_Item:new("quick_stand", settings.training, "fast_wakeup_mode",
                                       menu_tables.quick_stand_mode, 1),
         menu_items.Button_Menu_Item:new("swap_dummy", function()
            training.toggle_swap_characters()
            require("src.ui.hud").add_player_label(training.player, "hud_player")
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
         menu_items.On_Off_Menu_Item:new("auto_crop_first_frames", settings.training, "auto_crop_recording_start", false),
         menu_items.On_Off_Menu_Item:new("auto_crop_last_frames", settings.training, "auto_crop_recording_end", false),
         menu_items.List_Menu_Item:new("replay_mode", settings.training, "replay_mode", menu_tables.slot_replay_mode),
         menu_items.Integer_Menu_Item:new("menu_slot", settings.training, "current_recording_slot", 1,
                                          recording.recording_slot_count, true, 1, 1, 10,
                                          recording.update_current_recording_slot_frames),
         menu_items.Label_Menu_Item:new("recording_slot_frames", {"value", " ", "menu_frames"},
                                        recording.current_recording_slot_frames, "frames", false, true),
         slot_weight_item, recording_delay_item, recording_random_deviation_item,
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
                                                                     "controller_style",
                                                                     draw.controller_style_menu_names)
   controller_style_menu_item.is_visible = function()
      return settings.training.display_input or settings.training.display_input_history ~= 1
   end

   attack_bars_show_decimal_item = menu_items.On_Off_Menu_Item:new("show_decimal", settings.training,
                                                                   "attack_bars_show_decimal", false)
   attack_bars_show_decimal_item.indent = true
   attack_bars_show_decimal_item.is_visible = function() return settings.training.display_attack_bars > 1 end

   display_hitboxes_opacity_item = menu_items.Integer_Menu_Item:new("display_hitboxes_opacity", settings.training,
                                                                    "display_hitboxes_opacity", 5, 100, false, 100, 5)
   display_hitboxes_opacity_item.indent = true
   display_hitboxes_opacity_item.is_visible = function() return settings.training.display_hitboxes > 1 end

   mid_distance_height_item = menu_items.Integer_Menu_Item:new("mid_distance_height", settings.training,
                                                               "mid_distance_height", 0, 200, false, 10)
   mid_distance_height_item.indent = true
   mid_distance_height_item.is_visible = function() return settings.training.display_distances end

   p1_distances_reference_point_item = menu_items.List_Menu_Item:new("p1_distance_reference_point", settings.training,
                                                                     "p1_distances_reference_point",
                                                                     menu_tables.distance_display_reference_point)
   p1_distances_reference_point_item.indent = true
   p1_distances_reference_point_item.is_visible = function() return settings.training.display_distances end

   p2_distances_reference_point_item = menu_items.List_Menu_Item:new("p2_distance_reference_point", settings.training,
                                                                     "p2_distances_reference_point",
                                                                     menu_tables.distance_display_reference_point)
   p2_distances_reference_point_item.indent = true
   p2_distances_reference_point_item.is_visible = function() return settings.training.display_distances end

   air_time_player_coloring_item = menu_items.On_Off_Menu_Item:new("display_air_time_player_coloring",
                                                                   settings.training,
                                                                   "display_air_time_player_coloring", false)
   air_time_player_coloring_item.indent = true
   air_time_player_coloring_item.is_visible = function() return settings.training.display_air_time end

   charge_overcharge_on_item = menu_items.On_Off_Menu_Item:new("display_overcharge", settings.training,
                                                               "charge_overcharge_on", false)
   charge_overcharge_on_item.indent = true
   charge_overcharge_on_item.is_visible = function() return settings.training.display_charge end

   charge_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training,
                                                               "charge_follow_player", false)
   charge_follow_player_item.indent = true
   charge_follow_player_item.is_visible = function() return settings.training.display_charge end

   parry_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training,
                                                              "parry_follow_player", false)
   parry_follow_player_item.indent = true
   parry_follow_player_item.is_visible = function() return settings.training.display_parry end

   display_parry_compact_item = menu_items.On_Off_Menu_Item:new("display_parry_compact", settings.training,
                                                                "display_parry_compact", false)
   display_parry_compact_item.indent = true
   display_parry_compact_item.is_visible = function() return settings.training.display_parry end

   attack_range_display_max_item = menu_items.Integer_Menu_Item:new("attack_range_display_max_attacks",
                                                                    settings.training,
                                                                    "attack_range_display_max_attacks", 1, 3, true, 1)
   attack_range_display_max_item.indent = true
   attack_range_display_max_item.is_visible = function() return settings.training.display_attack_range ~= 1 end

   attack_range_display_numbers_item = menu_items.On_Off_Menu_Item:new("attack_range_display_show_numbers",
                                                                       settings.training,
                                                                       "attack_range_display_show_numbers", false)
   attack_range_display_numbers_item.indent = true
   attack_range_display_numbers_item.is_visible = function() return settings.training.display_attack_range ~= 1 end

   language_item = menu_items.List_Menu_Item:new("language", settings.training, "language", menu_tables.language, 1,
                                                 function()
      main_menu:update_dimensions()
      main_menu:update_page_position()
   end)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_display"),
      entries = {
         menu_items.On_Off_Menu_Item:new("display_controllers", settings.training, "display_input", true),
         controller_style_menu_item,
         menu_items.List_Menu_Item:new("display_input_history", settings.training, "display_input_history",
                                       menu_tables.display_input_history_mode, 1),
         menu_items.On_Off_Menu_Item:new("display_gauge_numbers", settings.training, "display_gauges", false),
         menu_items.On_Off_Menu_Item:new("display_bonuses", settings.training, "display_bonuses", true),
         menu_items.List_Menu_Item:new("display_attack_bars", settings.training, "display_attack_bars",
                                       menu_tables.display_attack_bars_mode, 3), attack_bars_show_decimal_item,
         menu_items.List_Menu_Item:new("display_frame_advantage", settings.training, "display_frame_advantage",
                                       menu_tables.display_frame_advantage_mode, 1),
         menu_items.List_Menu_Item:new("display_hitboxes", settings.training, "display_hitboxes",
                                       menu_tables.player_options, 1), display_hitboxes_opacity_item,
         menu_items.On_Off_Menu_Item:new("display_distances", settings.training, "display_distances", false),
         mid_distance_height_item, p1_distances_reference_point_item, p2_distances_reference_point_item,
         menu_items.On_Off_Menu_Item:new("display_stun_timer", settings.training, "display_stun_timer", true),
         menu_items.On_Off_Menu_Item:new("display_air_time", settings.training, "display_air_time", false),
         air_time_player_coloring_item,
         menu_items.On_Off_Menu_Item:new("display_charge", settings.training, "display_charge", false),
         charge_follow_player_item, charge_overcharge_on_item,
         menu_items.On_Off_Menu_Item:new("display_parry", settings.training, "display_parry", false),
         parry_follow_player_item, display_parry_compact_item,
         menu_items.On_Off_Menu_Item:new("display_blocking_direction", settings.training, "display_blocking_direction",
                                         false),
         menu_items.On_Off_Menu_Item:new("display_red_parry_miss", settings.training, "display_red_parry_miss", false),
         menu_items.List_Menu_Item:new("attack_range_display", settings.training, "display_attack_range",
                                       menu_tables.player_options), attack_range_display_max_item,
         attack_range_display_numbers_item,
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
         menu_items.On_Off_Menu_Item:new("infinite_time", settings.training, "infinite_time", true),
         menu_items.List_Menu_Item:new("life_refill_mode", settings.training, "life_mode", menu_tables.life_mode, 4,
                                       update_gauge_items()), p1_life_reset_value_gauge_item,
         p2_life_reset_value_gauge_item, -- life_reset_delay_item,
         menu_items.List_Menu_Item:new("stun_refill_mode", settings.training, "stun_mode", menu_tables.stun_mode, 3,
                                       update_gauge_items()), p1_stun_reset_value_gauge_item,
         p2_stun_reset_value_gauge_item, -- stun_reset_delay_item,
         menu_items.List_Menu_Item:new("meter_refill_mode", settings.training, "meter_mode", menu_tables.meter_mode, 5,
                                       update_gauge_items()), p1_meter_reset_value_gauge_item,
         p2_meter_reset_value_gauge_item, -- meter_reset_delay_item,
         menu_items.On_Off_Menu_Item:new("infinite_super_art_time", settings.training, "infinite_sa_time", false),
         menu_items.List_Menu_Item:new("auto_parrying", settings.training, "auto_parrying", menu_tables.player_options),
         menu_items.On_Off_Menu_Item:new("universal_cancel", settings.training, "universal_cancel", false),
         menu_items.On_Off_Menu_Item:new("infinite_projectiles", settings.training, "infinite_projectiles", false),
         menu_items.On_Off_Menu_Item:new("infinite_juggle", settings.training, "infinite_juggle", false),
         menu_items.On_Off_Menu_Item:new("speed_up_game_intro", settings.training, "fast_forward_intro", true),
         menu_items.Integer_Menu_Item:new("music_volume", settings.training, "music_volume", 0, 10, false, 0)
      }
   }
end

local function create_training_tab()
   local character_select_and_open_menu_item = menu_items.Button_Menu_Item:new("character_select", function()
      character_select.start_character_select_sequence()
      open_after_match_start = true
   end)

   training_mode_item = menu_items.List_Menu_Item:new("menu_mode", settings.training, "special_training_mode",
                                                      menu_tables.special_training_mode, 1)

   local opponent = defense_tables.opponents[settings.special_training.defense.opponent]

   start_defense_item = menu_items.Button_Menu_Item:new("menu_start", function()
      local start_opponent = defense_tables.opponents[settings.special_training.defense.opponent]
      special_modes.stop_other_modes(defense)
      close_menu(true)
      defense.start(gamestate.P1.char_str, start_opponent)
   end)
   start_defense_item.is_enabled = function()
      return is_frame_data_loaded() and defense_setup_item:at_least_one_selected()
   end
   start_defense_item.is_unselectable = function() return not start_defense_item.is_enabled end

   defense_score_item = menu_items.Label_Menu_Item:new("menu_score", {"menu_score", ": ", "value"},
                                                       settings.special_training.defense.characters[opponent], "score",
                                                       false, true)

   defense_opponent_item = menu_items.List_Menu_Item:new("menu_opponent", settings.special_training.defense, "opponent",
                                                         defense_tables.opponents_menu, 1, update_defense_items)

   defense_setup_item = menu_items.Check_Box_Grid_Item:new("menu_setup",
                                                           settings.special_training.defense.characters[opponent].setups,
                                                           defense_tables.get_setup_names(opponent), 4)

   defense_character_select_item = menu_items.Button_Menu_Item:new("character_select", defense.start_character_select)

   defense_learning_item = menu_items.On_Off_Menu_Item:new("dummy_learning",
                                                           settings.special_training.defense.characters[opponent],
                                                           "learning", true)
   defense_reset_item = menu_items.Button_Menu_Item:new("menu_reset", function()
      local opp = defense_tables.opponents[settings.special_training.defense.opponent]
      defense_tables.reset_followups(settings, opp)
   end)

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

   unblockables_start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      special_modes.stop_other_modes(unblockables)
      close_menu(true)
      unblockables.start()
   end)
   unblockables_start_item.legend_text = "legend_lp_select_coin_start"
   unblockables_start_item.is_unselectable = function()
      local sel_unblockable = unblockables_type_item.list[settings.special_training.unblockables.type]
      return settings.special_training.unblockables.character == "default" or
                 not unblockables_followup_item:at_least_one_selected() or
                 unblockables_tables.get_unblockables_character(sel_unblockable) ~=
                 settings.special_training.unblockables.match_savestate_dummy or not is_frame_data_loaded()
   end
   unblockables_start_item.is_enabled = function() return not unblockables_start_item.is_unselectable() end

   local function unblockables_character_select()
      special_modes.stop_other_modes(unblockables)
      unblockables.start_character_select()
      unblockables_followup_item.selected_col = 1
      unblockables_followup_item.selected_row = 1
      open_after_match_start = true
      main_menu:select_item(unblockables_followup_item)
   end

   jumpins_edit_menu = create_jumpins_edit_menu()
   jumpins_edit_menu.background_color = bit.band(colors.menu.background, 0xFFFFFF00) + 0x98
   jumpins_edit_menu.scroll_up_function = function()
      change_jump_index(1)
      jumpins.load_jump(current_jump_settings)
      update_jumpins_edit_items()
   end
   jumpins_edit_menu.scroll_down_function = function()
      change_jump_index(-1)
      jumpins.load_jump(current_jump_settings)
      update_jumpins_edit_items()
   end
   jumpins_edit_menu.on_close = function() training.freeze_game() end

   jumpins_training_tab = {}
   jumpins_training_tab.start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      special_modes.stop_other_modes(jumpins)
      close_menu(true)
      jumpins.start(settings.special_training.jumpins)
   end)
   jumpins_training_tab.start_item.legend_text = "legend_lp_select_coin_start"
   jumpins_training_tab.start_item.is_enabled = function() return is_frame_data_loaded() and jumpins_edit_settings end
   jumpins_training_tab.start_item.is_unselectable = function()
      return not jumpins_training_tab.start_item.is_enabled()
   end

   jumpins_training_tab.start_edit_item = menu_items.Button_Menu_Item:new("menu_settings", function()
      special_modes.stop_other_modes(jumpins)
      jumpins_edit_jump_index = 1
      jumpins.init()
      update_jumpins_settings()
      jumpins.begin_edit(settings.special_training.jumpins, current_jump_settings)
      update_jumpins_edit_items()
      update_counter_attack_items()
      main_menu:menu_open_popup(jumpins_edit_menu, true)
      training.unfreeze_game()
      allow_update_while_open = true
      main_menu.on_close = function()
         jumpins.end_edit()
         allow_update_while_open = false
         main_menu.on_close = nil
      end
   end)
   jumpins_training_tab.start_edit_item.is_enabled = is_frame_data_loaded
   jumpins_training_tab.start_edit_item.is_unselectable = function()
      return not jumpins_training_tab.start_edit_item.is_enabled()
   end

   jumpins_training_tab.jump_replay_mode_item = menu_items.List_Menu_Item:new("menu_jump_replay_mode",
                                                                              jumpins_edit_settings, "jump_replay_mode",
                                                                              menu_tables.jumpins_replay_mode)
   jumpins_training_tab.player_position_mode_item = menu_items.List_Menu_Item:new("menu_player_position_mode",
                                                                                  jumpins_edit_settings,
                                                                                  "player_position_mode",
                                                                                  menu_tables.jumpins_position_mode)
   jumpins_training_tab.dummy_offset_mode_item = menu_items.List_Menu_Item:new("menu_dummy_offset_mode",
                                                                               jumpins_edit_settings,
                                                                               "dummy_offset_mode",
                                                                               menu_tables.jumpins_offset_mode)
   jumpins_training_tab.attack_delay_mode_item = menu_items.List_Menu_Item:new("menu_attack_delay_mode",
                                                                               jumpins_edit_settings,
                                                                               "attack_delay_mode",
                                                                               menu_tables.jumpins_offset_mode)
   jumpins_training_tab.show_jump_arc_item = menu_items.On_Off_Menu_Item:new("menu_show_jump_arc",
                                                                             jumpins_edit_settings, "show_jump_arc",
                                                                             false)
   jumpins_training_tab.show_jump_info_item = menu_items.On_Off_Menu_Item:new("menu_show_jump_info",
                                                                              jumpins_edit_settings, "show_jump_info",
                                                                              false)
   jumpins_training_tab.automatic_replay_item = menu_items.On_Off_Menu_Item:new("menu_automatic_replay",
                                                                                jumpins_edit_settings,
                                                                                "automatic_replay", true)

   footsies_training_tab = {}
   footsies_training_tab.start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      special_modes.stop_other_modes(footsies)
      close_menu(true)
      footsies.start()
   end)
   footsies_training_tab.start_item.legend_text = "legend_lp_select"
   footsies_training_tab.start_item.is_enabled = function()
      return is_frame_data_loaded() and footsies_training_tab.moves_item:at_least_one_selected()
   end
   footsies_training_tab.start_item.is_unselectable = function()
      return not footsies_training_tab.start_item.is_enabled()
   end
   footsies_training_tab.score_item = menu_items.Label_Menu_Item:new("menu_score", {"menu_score", ": ", "value"}, {},
                                                                     "score", false, true)
   footsies_training_tab.character_select_item = menu_items.Button_Menu_Item:new("character_select", function()
      close_menu()
      footsies.start_character_select()
   end)
   footsies_training_tab.character_select_item.legend_text = "legend_lp_select"
   footsies_training_tab.character_select_item.is_enabled = function() return is_frame_data_loaded() end
   footsies_training_tab.character_select_item.is_unselectable = function()
      return not footsies_training_tab.character_select_item.is_enabled()
   end
   footsies_training_tab.moves_item = menu_items.Check_Box_Grid_Item:new("menu_moves", {1}, {"1"}, 4)

   footsies_training_tab.walk_out_item = menu_items.On_Off_Menu_Item:new("menu_walk_out", {walk_out = true}, "walk_out",
                                                                         true)
   footsies_training_tab.accuracy_item = menu_items.Slider_Menu_Item:new("menu_accuracy", 100, {80, 80}, {0, 100})
   footsies_training_tab.accuracy_item.disable_mode_switch = true
   footsies_training_tab.accuracy_item.legend_text = ""

   footsies_training_tab.distance_judgement_item = menu_items.Slider_Menu_Item:new("menu_distance_judgement", 100,
                                                                                   {80, 80}, {0, 100})
   footsies_training_tab.distance_judgement_item.disable_mode_switch = true
   footsies_training_tab.distance_judgement_item.legend_text = ""

   geneijin_training_tab = {}
   geneijin_training_tab.start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      special_modes.stop_other_modes(geneijin)
      close_menu(true)
      geneijin.start()
   end)
   geneijin_training_tab.start_item.legend_text = "legend_lp_select"
   geneijin_training_tab.start_item.is_enabled = function()
      return is_frame_data_loaded() and geneijin_training_tab.moves_item:at_least_one_selected()
   end
   geneijin_training_tab.start_item.is_unselectable = function()
      return not geneijin_training_tab.start_item.is_enabled()
   end
   geneijin_training_tab.score_item = menu_items.Label_Menu_Item:new("menu_score", {"menu_score", ": ", "value"},
                                                                     settings.special_training.geneijin, "score", false,
                                                                     true)
   geneijin_training_tab.character_select_item = menu_items.Button_Menu_Item:new("character_select", function()
      close_menu()
      geneijin.start_character_select()
   end)
   geneijin_training_tab.character_select_item.legend_text = "legend_lp_select"
   geneijin_training_tab.character_select_item.is_enabled = function() return is_frame_data_loaded() end
   geneijin_training_tab.character_select_item.is_unselectable = function()
      return not geneijin_training_tab.character_select_item.is_enabled()
   end

   geneijin_training_tab.moves_item = menu_items.Check_Box_Grid_Item:new("menu_moves",
                                                                         settings.special_training.geneijin.moves,
                                                                         geneijin_tables.get_menu_move_names(), 4)

   training_sub_menus = {
      {name = "training_defense", entries = {training_mode_item}}, {
         name = "training_jumpins",
         entries = {
            training_mode_item, jumpins_training_tab.start_item, character_select_and_open_menu_item,
            jumpins_training_tab.start_edit_item, jumpins_training_tab.jump_replay_mode_item,
            jumpins_training_tab.player_position_mode_item, jumpins_training_tab.dummy_offset_mode_item,
            jumpins_training_tab.attack_delay_mode_item, jumpins_training_tab.show_jump_arc_item,
            jumpins_training_tab.show_jump_info_item, jumpins_training_tab.automatic_replay_item
         }
      }, {
         name = "training_footsies",
         entries = {
            training_mode_item, footsies_training_tab.start_item, footsies_training_tab.score_item,
            character_select_and_open_menu_item, footsies_training_tab.moves_item, footsies_training_tab.walk_out_item,
            footsies_training_tab.accuracy_item, footsies_training_tab.distance_judgement_item
         }
      }, {
         name = "training_unblockables",
         entries = {
            training_mode_item, unblockables_start_item, unblockables_type_item, unblockables_followup_item,
            menu_items.Button_Menu_Item:new("character_select", unblockables_character_select)
         }
      }, {
         name = "training_geneijin",
         entries = {
            training_mode_item, geneijin_training_tab.start_item, geneijin_training_tab.score_item,
            geneijin_training_tab.character_select_item, geneijin_training_tab.moves_item
         }
      }
      -- , {
      --    name = "training_denjin",
      --    entries = {
      --       training_mode_item,
      --       character_select_item
      --    }
      -- }
   }

   training_mode_item.on_change = update_training_tab_page

   return {header = menu_items.Header_Menu_Item:new("menu_title_training"), entries = training_sub_menus[1].entries}
end

local function create_challenge_tab()
   challenge_tab = {}
   challenge_tab.start_item = menu_items.Button_Menu_Item:new("menu_start", play_challenge)
   challenge_tab.start_item.is_enabled = function() return false end
   challenge_tab.start_item.is_unselectable = function() return not challenge_tab.start_item.is_enabled() end
   challenge_tab.start_item.legend_text = "legend_lp_select"

   challenge_tab.character_select_item = menu_items.Button_Menu_Item:new("character_select", function()
      character_select.start_character_select_sequence()
   end)
   challenge_tab.character_select_item.is_enabled = function() return false end
   challenge_tab.character_select_item.is_unselectable = function() return not challenge_tab.start_item.is_enabled() end

   challenge_tab.character_select_item.legend_text = "legend_lp_select"

   challenge_tab.label_item = menu_items.Label_Menu_Item:new("wip", {"menu_work_in_progress"}, {}, "", false, false)

   return {
      header = menu_items.Header_Menu_Item:new("menu_title_challenge"),
      entries = {
         menu_items.List_Menu_Item:new("menu_challenge", settings.training, "challenge_current_mode",
                                       menu_tables.challenge_mode), challenge_tab.start_item,
         challenge_tab.character_select_item, challenge_tab.label_item
      }
   }
end

local function create_debug_tab()
   return {
      header = menu_items.Header_Menu_Item:new("menu_title_debug"),
      entries = {
         menu_items.On_Off_Menu_Item:new("dump_state_display", debug_settings, "show_dump_state_display", false),
         menu_items.On_Off_Menu_Item:new("debug_variables_display", debug_settings, "show_debug_variables_display",
                                         false),
         menu_items.On_Off_Menu_Item:new("debug_frames_display", debug_settings, "show_debug_frames_display", false),
         menu_items.On_Off_Menu_Item:new("memory_view_display", debug_settings, "show_memory_view_display", false),
         menu_items.On_Off_Menu_Item:new("show_predicted_hitboxes", debug_settings, "show_predicted_hitbox", false),
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

local function update_menu_items()
   if not debug_settings.recording_framedata then
      update_counter_attack_items()
      update_jumpins_edit_items()
      update_gauge_items()
      update_recording_items()
      update_training_tab_page()
      update_defense_items()
      update_footsies_items()
      update_unblockables_items()
      update_geneijin_items()
   end
end

local function open_menu()
   if not disable_opening then
      is_open = true
      open_after_match_start = false
      update_menu_items()
      main_menu:menu_stack_push(main_menu)
      training.freeze_game()
   end
end

close_menu = function(training_stays_active)
   is_open = false
   main_menu:menu_stack_clear()
   settings.save_training_data()
   if not training_stays_active then special_modes.stop_all() end
   training.unfreeze_game()
end

local horizontal_autofire_rate = 4
local horizontal_autofire_time
local vertical_autofire_rate = 4
local function update()
   if is_initialized then
      if gamestate.is_in_match then
         local should_toggle = gamestate.P1.input.pressed.start

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
   update_unblockables_items = update_unblockables_items,
   update_menu_items = update_menu_items,
   update = update,
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
      elseif key == "open_after_match_start" then
         return open_after_match_start
      elseif key == "allow_update_while_open" then
         return allow_update_while_open
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_initialized" then
         is_initialized = value
      elseif key == "is_open" then
         is_open = value
      elseif key == "disable_opening" then
         disable_opening = value
      elseif key == "open_after_match_start" then
         open_after_match_start = value
      elseif key == "allow_update_while_open" then
         allow_update_while_open = value
      else
         rawset(menu_module, key, value)
      end
   end
})

return menu_module
