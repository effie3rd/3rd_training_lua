local gamestate = require("src.gamestate")
local move_data = require("src.modules.move_data")
local recording = require("src.control.recording")
local training = require("src.training")
local character_select = require("src.control.character_select")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local settings = require("src.settings")
local debug_settings = require("src.debug_settings")
local menu_tables = require("src.ui.menu_tables")
local menu_items = require("src.ui.menu_items")


local is_initialized = false
local is_open = false

local save_recording_settings = {
  save_file_name = "",
  load_file_list = {},
  load_file_index = 1
}

local save_recording_slot_popup, load_recording_slot_popup, controller_style_menu_item,
life_reset_delay_item, p1_life_reset_value_gauge_item, p2_life_reset_value_gauge_item,
p1_stun_reset_value_gauge_item, p2_stun_reset_value_gauge_item, stun_reset_delay_item, load_file_name_item,
p1_meter_reset_value_gauge_item, p2_meter_reset_value_gauge_item, meter_reset_delay_item, slot_weight_item,
counter_attack_delay_item, recording_delay_item, recording_random_deviation_item, charge_overcharge_on_item, charge_follow_player_item,
parry_follow_player_item, display_parry_compact_item, blocking_item, hits_before_red_parry_item, parry_every_n_item, prefer_down_parry_item, 
counter_attack_motion_item, counter_attack_normal_button_item, counter_attack_special_item, counter_attack_special_button_item, counter_attack_type_item,
counter_attack_input_display_item, counter_attack_option_select_item, hits_before_counter_attack, change_characters_item,
p1_distances_reference_point_item, p2_distances_reference_point_item, mid_distance_height_item, air_time_player_coloring_item,
attack_range_display_max_item, attack_bars_show_decimal_item, display_hitboxes_opacity_item, language_item, play_challenge_item, select_char_challenge_item


local main_menu

local counter_attack_settings =
{
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



local function update_menu()
  slot_weight_item.object = recording.recording_slots[settings.training.current_recording_slot]
  recording_delay_item.object = recording.recording_slots[settings.training.current_recording_slot]
  recording_random_deviation_item.object = recording.recording_slots[settings.training.current_recording_slot]
  recording.update_current_recording_slot_frames()
end

local function update_gauge_items()
  if is_initialized then
    settings.training.p1_meter_reset_value = math.min(settings.training.p1_meter_reset_value, gamestate.P1.max_meter_count * gamestate.P1.max_meter_gauge)
    settings.training.p2_meter_reset_value = math.min(settings.training.p2_meter_reset_value, gamestate.P2.max_meter_count * gamestate.P2.max_meter_gauge)
    p1_meter_reset_value_gauge_item.gauge_max = gamestate.P1.max_meter_gauge * gamestate.P1.max_meter_count
    p1_meter_reset_value_gauge_item.subdivision_count = gamestate.P1.max_meter_count
    p2_meter_reset_value_gauge_item.gauge_max = gamestate.P2.max_meter_gauge * gamestate.P2.max_meter_count
    p2_meter_reset_value_gauge_item.subdivision_count = gamestate.P2.max_meter_count
    settings.training.p1_stun_reset_value = math.min(settings.training.p1_stun_reset_value, gamestate.P1.stun_bar_max)
    settings.training.p2_stun_reset_value = math.min(settings.training.p2_stun_reset_value, gamestate.P2.stun_bar_max)
    p1_stun_reset_value_gauge_item.gauge_max = gamestate.P1.stun_bar_max
    p2_stun_reset_value_gauge_item.gauge_max = gamestate.P2.stun_bar_max

    if gamestate.frame_number % 20 == 0 then
      -- counter_attack_type_item:right()
      -- fake_menu_update(fm)
      -- for i = 1 , #main_menu.content[1].entries do
      --   if main_menu.content[1].entries[i].name == "counter_attack_type" and main_menu.content[1].entries[i].right then
      --     print(main_menu.content[1].entries[i] == counter_attack_type_item)
      --     main_menu.content[1].entries[i]:right()
      --   end
      -- end
    end
  end
end

local function update_counter_attack_data()
  local char_str = training.dummy.char_str
  local ca_type = counter_attack_settings.ca_type
  local ca_data =  {
    char_str = char_str,
    ca_type = ca_type,
    name = "normal",
    button = nil,
  }
  if ca_type == 2 then
    ca_data.motion = counter_attack_motion[counter_attack_settings.motion]
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
    counter_attack_normal_buttons = input_to_text(counter_attack_button_inputs)
  end
  counter_attack_normal_button_item.list = counter_attack_normal_buttons

  counter_attack_settings.normal_button = bound_index(counter_attack_settings.normal_button, counter_attack_normal_buttons)
end

local function update_counter_attack_special_names()
  counter_attack_special_names = move_data.get_special_and_sa_names(training.dummy.char_str, training.dummy.selected_sa)
  counter_attack_special_item.list = counter_attack_special_names
end

local function update_counter_attack_special_button()
  local name = counter_attack_special_names[counter_attack_settings.special]
  counter_attack_special_buttons = move_data.get_buttons_by_move_name(training.dummy.char_str, name)
  counter_attack_special_button_item.list = counter_attack_special_buttons

  counter_attack_settings.special_button = bound_index(counter_attack_settings.special_button, counter_attack_special_buttons)
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

local function play_challenge()
end

local function save_recording_slot_to_file()
  if save_recording_settings.save_file_name == "" then
    print(string.format("Error: Can't save to empty file name"))
    return
  end

  local path = string.format("%s%s.json", settings.recordings_path, save_recording_settings.save_file_name)
  if not write_object_to_json_file(recording.recording_slots[settings.training.current_recording_slot].inputs, path) then
    print(string.format("Error: Failed to save recording to \"%s\"", path))
  else
    print(string.format("Saved slot %d to \"%s\"", settings.training.current_recording_slot, path))
  end

  main_menu:menu_stack_pop(save_recording_slot_popup)
end

local function load_recording_slot_from_file()
  if #save_recording_settings.load_file_list == 0 or save_recording_settings.load_file_list[save_recording_settings.load_file_index] == nil then
    print(string.format("Error: Can't load from empty file name"))
    return
  end

  local path = string.format("%s%s",settings.recordings_path, save_recording_settings.load_file_list[save_recording_settings.load_file_index])
  local recording_inputs = read_object_from_json_file(path)
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
  save_recording_settings.save_file_name = string.gsub(training.dummy.char_str, "(.*)", string.upper).."_"
end


local function open_load_popup()
  load_recording_slot_popup.selected_index = 1

  save_recording_settings.load_file_index = 1

  local is_windows = package.config:sub(1,1) == "\\"

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
  for line in string.gmatch(str, '([^\r\n]+)') do -- Split all lines that have ".json" in them
    if string.find(line, ".json") ~= nil then
      local file = line
      table.insert(save_recording_settings.load_file_list, file)
    end
  end

  load_file_name_item.list = save_recording_settings.load_file_list

  main_menu:menu_stack_push(load_recording_slot_popup)
end


local function create_recording_popup()

  load_file_name_item = menu_items.List_Menu_Item:new("file_name", save_recording_settings, "load_file_index", save_recording_settings.load_file_list)
  
  save_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
  {
  menu_items.Textfield_Menu_Item:new("file_name", save_recording_settings, "save_file_name", ""),
  menu_items.Button_Menu_Item:new("file_save", save_recording_slot_to_file),
  menu_items.Button_Menu_Item:new("file_cancel", function() main_menu:menu_stack_pop(save_recording_slot_popup) end)
  })

  load_recording_slot_popup = menu_items.Menu:new(71, 61, 312, 122, -- screen size 383,223
  {
    load_file_name_item,
    menu_items.Button_Menu_Item:new("file_load", load_recording_slot_from_file),
    menu_items.Button_Menu_Item:new("file_cancel", function() main_menu:menu_stack_pop(load_recording_slot_popup) end),
  })
end

local function create_dummy_tab()
  blocking_item = menu_items.List_Menu_Item:new("blocking", settings.training, "blocking_mode", menu_tables.blocking_mode)
  blocking_item.indent = true

  hits_before_red_parry_item = menu_items.Hits_Before_Menu_Item:new("hits_before_rp_prefix", "hits_before_rp_suffix", settings.training, "red_parry_hit_count", 0, 20, true, 1)
  hits_before_red_parry_item.indent = true
  hits_before_red_parry_item.is_disabled = function()
    return settings.training.blocking_style ~= 3
  end

  parry_every_n_item = menu_items.Hits_Before_Menu_Item:new("parry_every_prefix", "parry_every_suffix", settings.training, "parry_every_n_count", 0, 10, true, 1)
  parry_every_n_item.indent = true
  parry_every_n_item.is_disabled = function()
    return settings.training.blocking_style ~= 3
  end

  prefer_down_parry_item = menu_items.On_Off_Menu_Item:new("prefer_down_parry", settings.training, "prefer_down_parry")
  prefer_down_parry_item.indent = true
  prefer_down_parry_item.is_disabled = function()
    return not (settings.training.blocking_style == 2 or settings.training.blocking_style == 3)
  end

  counter_attack_type_item = menu_items.List_Menu_Item:new("counter_attack_type", counter_attack_settings, "ca_type", counter_attack_type, 1, update_counter_attack_items)


  counter_attack_motion_item = menu_items.Motion_list_Menu_Item:new("counter_attack_motion", counter_attack_settings, "motion", counter_attack_motion_input, 1, update_counter_attack_items)
  counter_attack_motion_item.indent = true
  counter_attack_motion_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 2
  end

  counter_attack_normal_button_item = menu_items.List_Menu_Item:new("counter_attack_button", counter_attack_settings, "normal_button", counter_attack_normal_buttons, 1, update_counter_attack_items)
  counter_attack_normal_button_item.indent = true
  counter_attack_normal_button_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 2 or #counter_attack_normal_button_item.list == 0
  end

  counter_attack_special_item = menu_items.List_Menu_Item:new("counter_attack_special", counter_attack_settings, "special", counter_attack_special_names, 1, update_counter_attack_items)
  counter_attack_special_item.indent = true
  counter_attack_special_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 3
  end

  counter_attack_special_button_item = menu_items.List_Menu_Item:new("counter_attack_button", counter_attack_settings, "special_button", counter_attack_special_buttons, 1, update_counter_attack_items)
  counter_attack_special_button_item.indent = true
  counter_attack_special_button_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 3 or #counter_attack_special_button_item.list == 0
  end

  counter_attack_input_display_item = menu_items.Move_Input_Display_Menu_Item:new("move_input", counter_attack_move_input_data)
  counter_attack_input_display_item.inline = true
  counter_attack_input_display_item.is_disabled = function()
    return not (counter_attack_settings.ca_type == 3 or counter_attack_settings.ca_type == 4)
  end

  counter_attack_option_select_item = menu_items.List_Menu_Item:new("counter_attack_option_select_names", counter_attack_settings, "option_select", counter_attack_option_select_names, 1, update_counter_attack_items)
  counter_attack_option_select_item.indent = true
  counter_attack_option_select_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 4
  end

  hits_before_counter_attack = menu_items.Hits_Before_Menu_Item:new("hits_before_ca_prefix", "hits_before_ca_suffix", settings.training, "hits_before_counter_attack_count", 0, 20, true)
  hits_before_counter_attack.indent = true
  hits_before_counter_attack.is_disabled = function()
    return counter_attack_settings.ca_type == 1
  end

  counter_attack_delay_item = menu_items.Integer_Menu_Item:new("counter_attack_delay", settings.training, "counter_attack_delay", -40, 40, false, 0)
  counter_attack_delay_item.indent = true
  counter_attack_delay_item.is_disabled = function()
    return counter_attack_settings.ca_type == 1
  end

  return {
    header = menu_items.Header_Menu_Item:new("menu_title_dummy"),
    entries = {
      menu_items.List_Menu_Item:new("pose", settings.training, "pose", menu_tables.pose),
      menu_items.List_Menu_Item:new("blocking_style", settings.training, "blocking_style", menu_tables.blocking_style),
      blocking_item,
      hits_before_red_parry_item,
      parry_every_n_item,
      prefer_down_parry_item,
      counter_attack_type_item,
      counter_attack_motion_item,
      counter_attack_normal_button_item,
      counter_attack_special_item, counter_attack_input_display_item,
      counter_attack_special_button_item,
      counter_attack_option_select_item,
      hits_before_counter_attack,
      counter_attack_delay_item,
      menu_items.List_Menu_Item:new("tech_throws", settings.training, "tech_throws_mode", menu_tables.tech_throws_mode, 1),
      menu_items.List_Menu_Item:new("mash_inputs", settings.training, "mash_inputs_mode", menu_tables.mash_inputs_mode, 1),
      menu_items.List_Menu_Item:new("quick_stand", settings.training, "fast_wakeup_mode", menu_tables.quick_stand_mode, 1),
    }
  }
end

local function create_recording_tab()
  create_recording_popup()

  slot_weight_item = menu_items.Integer_Menu_Item:new("slot_weight", recording.recording_slots[settings.training.current_recording_slot], "weight", 0, 100, false, 1)
  recording_delay_item = menu_items.Integer_Menu_Item:new("replay_delay", recording.recording_slots[settings.training.current_recording_slot], "delay", -40, 40, false, 0)
  recording_random_deviation_item = menu_items.Integer_Menu_Item:new("replay_max_random_deviation", recording.recording_slots[settings.training.current_recording_slot], "random_deviation", -600, 600, false, 0, 1, 1)

  return {
    header = menu_items.Header_Menu_Item:new("menu_title_recording"),
    entries = {
      menu_items.On_Off_Menu_Item:new("auto_crop_first_frames", settings.training, "auto_crop_recording_start"),
      menu_items.On_Off_Menu_Item:new("auto_crop_last_frames", settings.training, "auto_crop_recording_end"),
      menu_items.List_Menu_Item:new("replay_mode", settings.training, "replay_mode", menu_tables.slot_replay_mode),
      menu_items.Integer_Menu_Item:new("menu_slot", settings.training, "current_recording_slot", 1, recording.recording_slot_count, true, 1, 1, 10, recording.update_current_recording_slot_frames),
      menu_items.Frame_Number_Item:new("recording_slot_frames", recording.current_recording_slot_frames, true),
      slot_weight_item,
      recording_delay_item,
      recording_random_deviation_item,
      menu_items.Button_Menu_Item:new("clear_slot", function () recording.clear_slot() recording.update_current_recording_slot_frames() end),
      menu_items.Button_Menu_Item:new("clear_all_slots", function () recording.clear_all_slots() recording.update_current_recording_slot_frames() end),
      menu_items.Button_Menu_Item:new("save_slot_to_file", open_save_popup),
      menu_items.Button_Menu_Item:new("load_slot_from_file", open_load_popup),
    }
  }
end

local function create_display_tab()
  controller_style_menu_item = menu_items.Controller_Style_Item:new("controller_style", settings.training, "controller_style", draw.controller_styles)
  controller_style_menu_item.is_disabled = function()
    return not settings.training.display_input and settings.training.display_input_history == 1
  end

  attack_bars_show_decimal_item = menu_items.On_Off_Menu_Item:new("show_decimal", settings.training, "attack_bars_show_decimal")
  attack_bars_show_decimal_item.indent = true
  attack_bars_show_decimal_item.is_disabled = function()
  return not (settings.training.display_attack_bars > 1)
  end

  display_hitboxes_opacity_item = menu_items.Integer_Menu_Item:new("display_hitboxes_opacity", settings.training, "display_hitboxes_opacity", 5, 100, false, 100, 5)
  display_hitboxes_opacity_item.indent = true
  display_hitboxes_opacity_item.is_disabled = function()
    return settings.training.display_hitboxes == 1
  end

  mid_distance_height_item = menu_items.Integer_Menu_Item:new("mid_distance_height", settings.training, "mid_distance_height", 0, 200, false, 10)
  mid_distance_height_item.is_disabled = function()
    return not settings.training.display_distances
  end

  p1_distances_reference_point_item = menu_items.List_Menu_Item:new("p1_distance_reference_point", settings.training, "p1_distances_reference_point", menu_tables.distance_display_reference_point)
  p1_distances_reference_point_item.is_disabled = function()
    return not settings.training.display_distances
  end

  p2_distances_reference_point_item = menu_items.List_Menu_Item:new("p2_distance_reference_point", settings.training, "p2_distances_reference_point", menu_tables.distance_display_reference_point)
  p2_distances_reference_point_item.is_disabled = function()
    return not settings.training.display_distances
  end

  air_time_player_coloring_item = menu_items.On_Off_Menu_Item:new("display_air_time_player_coloring", settings.training, "display_air_time_player_coloring")
  air_time_player_coloring_item.indent = true
  air_time_player_coloring_item.is_disabled = function()
  return not settings.training.display_air_time
  end

  charge_overcharge_on_item = menu_items.On_Off_Menu_Item:new("display_overcharge", settings.training, "charge_overcharge_on")
  charge_overcharge_on_item.indent = true
  charge_overcharge_on_item.is_disabled = function()
  return not settings.training.display_charge
  end

  charge_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training, "charge_follow_player")
  charge_follow_player_item.indent = true
  charge_follow_player_item.is_disabled = function()
  return not settings.training.display_charge
  end

  parry_follow_player_item = menu_items.On_Off_Menu_Item:new("menu_follow_player", settings.training, "parry_follow_player")
  parry_follow_player_item.indent = true
  parry_follow_player_item.is_disabled = function()
  return not settings.training.display_parry
  end

  display_parry_compact_item = menu_items.On_Off_Menu_Item:new("display_parry_compact", settings.training, "display_parry_compact")
  display_parry_compact_item.indent = true
  display_parry_compact_item.is_disabled = function()
  return not settings.training.display_parry
  end

  attack_range_display_max_item = menu_items.Integer_Menu_Item:new("attack_range_max_attacks", settings.training, "attack_range_display_max_attacks", 1, 3, true, 1)
  attack_range_display_max_item.indent = true
  attack_range_display_max_item.is_disabled = function()
    return settings.training.display_attack_range == 1
  end

  language_item = menu_items.List_Menu_Item:new("language", settings.training, "language", menu_tables.language, 1, update_dimensions)

  return {
    header = menu_items.Header_Menu_Item:new("menu_title_display"),
    entries = {
      menu_items.On_Off_Menu_Item:new("display_controllers", settings.training, "display_input"),
      controller_style_menu_item,
      menu_items.List_Menu_Item:new("display_input_history", settings.training, "display_input_history", menu_tables.display_input_history_mode, 1),
      menu_items.On_Off_Menu_Item:new("display_gauge_numbers", settings.training, "display_gauges", false),
      menu_items.On_Off_Menu_Item:new("display_bonuses", settings.training, "display_bonuses", true),
      menu_items.On_Off_Menu_Item:new("display_attack_info", settings.training, "display_attack_data"),
      menu_items.List_Menu_Item:new("display_attack_bars", settings.training, "display_attack_bars", menu_tables.display_attack_bars_mode, 3),
      attack_bars_show_decimal_item,
      menu_items.On_Off_Menu_Item:new("display_frame_advantage", settings.training, "display_frame_advantage"),
      menu_items.On_Off_Menu_Item:new("display_hitboxes", settings.training, "display_hitboxes"),
      display_hitboxes_opacity_item,
      menu_items.On_Off_Menu_Item:new("display_distances", settings.training, "display_distances"),
      mid_distance_height_item,
      p1_distances_reference_point_item,
      p2_distances_reference_point_item,
      menu_items.On_Off_Menu_Item:new("display_stun_timer", settings.training, "display_stun_timer", 2),
      menu_items.On_Off_Menu_Item:new("display_air_time", settings.training, "display_air_time"),
      air_time_player_coloring_item,
      menu_items.On_Off_Menu_Item:new("display_charge", settings.training, "display_charge"),
      charge_follow_player_item,
      charge_overcharge_on_item,
      menu_items.On_Off_Menu_Item:new("display_parry", settings.training, "display_parry"),
      parry_follow_player_item,
      display_parry_compact_item,
      menu_items.On_Off_Menu_Item:new("display_red_parry_miss", settings.training, "display_red_parry_miss"),
      menu_items.List_Menu_Item:new("attack_range_display", settings.training, "display_attack_range", menu_tables.player_options),
      attack_range_display_max_item,
      language_item
    }
  }
end

local function create_rules_tab()
  change_characters_item = menu_items.Button_Menu_Item:new("character_select", character_select.start_character_select_sequence)
  change_characters_item.is_disabled = function()
    -- not implemented for 4rd strike yet
    return rom_name ~= "sfiii3nr1"
  end

  p1_life_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p1_life_reset_value", settings.training, "p1_life_reset_value", 1, colors.gauges.life, 160)
  p2_life_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p2_life_reset_value", settings.training, "p2_life_reset_value", 1, colors.gauges.life, 160)
  life_reset_delay_item = menu_items.Integer_Menu_Item:new("reset_delay", settings.training, "life_reset_delay", 1, 100, false, 20)
  
  p1_life_reset_value_gauge_item.indent = true
  p2_life_reset_value_gauge_item.indent = true
  life_reset_delay_item.indent = true

  p1_life_reset_value_gauge_item.is_disabled = function()
    return settings.training.life_mode ~= 2
  end
  p2_life_reset_value_gauge_item.is_disabled = p1_life_reset_value_gauge_item.is_disabled
  life_reset_delay_item.is_disabled = function()
    return settings.training.life_mode == 1 or settings.training.life_mode == 5
  end

  p1_stun_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p1_stun_reset_value", settings.training, "p1_stun_reset_value", 1, colors.gauges.stun, 64)
  p2_stun_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p2_stun_reset_value", settings.training, "p2_stun_reset_value", 1, colors.gauges.stun, 64)
  stun_reset_delay_item = menu_items.Integer_Menu_Item:new("reset_delay", settings.training, "stun_reset_delay", 1, 100, false, 20)
    
  p1_stun_reset_value_gauge_item.indent = true
  p2_stun_reset_value_gauge_item.indent = true
  stun_reset_delay_item.indent = true

  p1_stun_reset_value_gauge_item.is_disabled = function()
    return settings.training.stun_mode ~= 2
  end
  p2_stun_reset_value_gauge_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled
  stun_reset_delay_item.is_disabled = function()
    return settings.training.stun_mode == 1 or settings.training.stun_mode == 5
  end


  p1_meter_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p1_meter_reset_value", settings.training, "p1_meter_reset_value", 2, colors.gauges.meter)
  p2_meter_reset_value_gauge_item = menu_items.Gauge_Menu_Item:new("p2_meter_reset_value", settings.training, "p2_meter_reset_value", 2, colors.gauges.meter)
  meter_reset_delay_item = menu_items.Integer_Menu_Item:new("reset_delay", settings.training, "meter_reset_delay", 1, 100, false, 20)

  p1_meter_reset_value_gauge_item.indent = true
  p2_meter_reset_value_gauge_item.indent = true
  meter_reset_delay_item.indent = true

  p1_meter_reset_value_gauge_item.is_disabled = function()
    return settings.training.meter_mode ~= 2
  end
  p2_meter_reset_value_gauge_item.is_disabled = p1_meter_reset_value_gauge_item.is_disabled
  meter_reset_delay_item.is_disabled = function()
    return settings.training.meter_mode == 1 or settings.training.meter_mode == 5
  end

  return {
    header = menu_items.Header_Menu_Item:new("menu_title_rules"),
    entries = {
      change_characters_item,
      menu_items.List_Menu_Item:new("force_stage", settings.training, "force_stage", menu_tables.stage_list, 1),
      menu_items.On_Off_Menu_Item:new("infinite_time", settings.training, "infinite_time"),
      menu_items.List_Menu_Item:new("life_refill_mode", settings.training, "life_mode", menu_tables.life_mode, 4, update_gauge_items()),
      p1_life_reset_value_gauge_item,
      p2_life_reset_value_gauge_item,
      -- life_reset_delay_item,
      menu_items.List_Menu_Item:new("stun_refill_mode", settings.training, "stun_mode", menu_tables.stun_mode, 3, update_gauge_items()),
      p1_stun_reset_value_gauge_item,
      p2_stun_reset_value_gauge_item,
      -- stun_reset_delay_item,
      menu_items.List_Menu_Item:new("meter_refill_mode", settings.training, "meter_mode", menu_tables.meter_mode, 5, update_gauge_items()),
      p1_meter_reset_value_gauge_item,
      p2_meter_reset_value_gauge_item,
      -- meter_reset_delay_item,
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
  return {
    header = menu_items.Header_Menu_Item:new("menu_title_training"),
    entries = {
      menu_items.List_Menu_Item:new("mode", settings.training, "special_training_mode", menu_tables.special_training_mode),

    }
  }
end

local function create_challenge_tab()
  play_challenge_item = menu_items.Button_Menu_Item:new("play", play_challenge)
  select_char_challenge_item = menu_items.Button_Menu_Item:new("Select Character (Current: Gill)", select_character_hadou_matsuri)
        
  return {
    header = menu_items.Header_Menu_Item:new("menu_title_challenge"),
    entries = {
      menu_items.List_Menu_Item:new("challenge", settings.training, "challenge_current_mode", menu_tables.challenge_mode),
                          play_challenge_item,
                          select_char_challenge_item
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
      menu_items.On_Off_Menu_Item:new("record_frame_data", debug_settings, "record_framedata"),
      menu_items.Button_Menu_Item:new("save_frame_data", save_frame_data),
    },
    topmost_entry = 1
  }
end

local function create_menu()
  local menu_tabs = {
    create_dummy_tab(),
    create_recording_tab(),
    create_display_tab(),
    create_rules_tab(),
    create_training_tab(),
    create_challenge_tab()
  }
  if debug_settings.developer_mode then
    table.insert(menu_tabs, create_debug_tab())
  end

  main_menu = menu_items.Multitab_Menu:new(
    23, 14, 360, 197, -- screen size 383,223

    menu_tabs,

    function ()
      recording.backup_recordings()
      settings.save_training_data()
    end
  )

  is_initialized = true
end

local function open_menu()
  update_counter_attack_items()
  update_gauge_items()
  update_menu()
  main_menu:menu_stack_push(main_menu)
end

local horizontal_autofire_rate = 4
local vertical_autofire_rate = 4
local function handle_input()
  if is_initialized then
    if gamestate.is_in_match then
      local should_toggle = gamestate.P1.input.pressed.start
      if debug_settings.log_enabled then
        should_toggle = gamestate.P1.input.released.start
      end
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
      is_open = false
      main_menu:menu_stack_clear()
    end

    if is_open then
      local current_entry = main_menu:menu_stack_top():current_entry()
      if current_entry ~= nil and current_entry.autofire_rate ~= nil then
        horizontal_autofire_rate = current_entry.autofire_rate
      end

      local input =
      {
        down = check_input_down_autofire(gamestate.P1, "down", vertical_autofire_rate),
        up = check_input_down_autofire(gamestate.P1, "up", vertical_autofire_rate),
        left = check_input_down_autofire(gamestate.P1, "left", horizontal_autofire_rate),
        right = check_input_down_autofire(gamestate.P1, "right", horizontal_autofire_rate),
        validate = gamestate.P1.input.pressed.LP,
        reset = gamestate.P1.input.pressed.MP,
        cancel = gamestate.P1.input.pressed.LK,
        scroll_up = gamestate.P1.input.pressed.HP,
        scroll_down = gamestate.P1.input.pressed.HK
      }

      --prevent scrolling across all menus and changing settings
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
  handle_input = handle_input
}

setmetatable(menu_module, {
  __index = function(_, key)
    if key == "is_initialized" then
      return is_initialized
    elseif key == "is_open" then
      return is_open
    end
  end,

  __newindex = function(_, key, value)
    if key == "is_initialized" then
      is_initialized = value
    elseif key == "is_open" then
      is_open = value
    else
      rawset(menu_module, key, value)
    end
  end
})

return menu_module