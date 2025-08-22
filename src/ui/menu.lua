local gamestate = require("src/gamestate")
local movedata = require("src.modules.movedata")
local recording = require("src.control.recording")
local move_list = movedata.move_list
local training = require("src/training")
local character_select = require("src.control.character_select")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local settings = require("src/settings")
local debug_settings = require("src/debug_settings")


initialized = false
is_open = false


save_file_name = ""

local load_file_list = {}
local load_file_index = 1
local save_recording_slot_popup, load_recording_slot_popup, controller_style_menu_item,
life_refill_delay_item, p1_life_reset_value_gauge_item, p2_life_reset_value_gauge_item,
p1_stun_reset_value_gauge_item, p2_stun_reset_value_gauge_item, stun_reset_delay_item,
p1_meter_gauge_item, p2_meter_gauge_item, meter_refill_delay_item, slot_weight_item,
counter_attack_delay_item, counter_attack_random_deviation_item, charge_overcharge_on_item, charge_follow_character_item,
blocking_item, hits_before_red_parry_item, parry_every_n_item, prefer_down_parry_item, counter_attack_item,
counter_attack_motion_item, counter_attack_button_item, counter_attack_special_item, counter_attack_special_button_item,
counter_attack_input_display_item, counter_attack_option_select_item, hits_before_counter_attack, change_characters_item,
p1_distances_reference_point_item, p2_distances_reference_point_item, mid_distance_height_item, air_time_player_coloring_item,
attack_range_display_max_item, attack_bars_show_decimal_item, language_item, play_challenge_item, select_char_challenge_item

local main_menu


function init_menu()
  
  save_recording_slot_popup = make_menu(71, 61, 312, 122, -- screen size 383,223
  {
    textfield_menu_item("file_name", _G, "save_file_name", ""),
    button_menu_item("save", save_recording_slot_to_file),
    button_menu_item("cancel", function() menu_stack_pop(save_recording_slot_popup) end)
  })


  load_recording_slot_popup = make_menu(71, 61, 312, 122, -- screen size 383,223
  {
    list_menu_item("file", _G, "load_file_index", load_file_list),
    button_menu_item("load", load_recording_slot_from_file),
    button_menu_item("cancel", function() menu_stack_pop(load_recording_slot_popup) end),
  })

  controller_style_menu_item = controller_style_item("controller_style", settings.training, "controller_style", draw.controller_styles)
  controller_style_menu_item.is_disabled = function()
    return not settings.training.display_input and settings.training.display_input_history == 1
  end


  life_refill_delay_item = integer_menu_item("life_refill_delay", settings.training, "life_refill_delay", 1, 100, false, 20)
  life_refill_delay_item.is_disabled = function()
    return settings.training.life_mode ~= 2
  end

  p1_life_reset_value_gauge_item = gauge_menu_item("p1_life_reset_value", settings.training, "p1_life_reset_value", 160, colors.gauges.life)
  p2_life_reset_value_gauge_item = gauge_menu_item("p2_life_reset_value", settings.training, "p2_life_reset_value", 160, colors.gauges.life)

  p1_stun_reset_value_gauge_item = gauge_menu_item("p1_stun_reset_value", settings.training, "p1_stun_reset_value", 64, colors.gauges.stun)
  p2_stun_reset_value_gauge_item = gauge_menu_item("p2_stun_reset_value", settings.training, "p2_stun_reset_value", 64, colors.gauges.stun)
  p1_stun_reset_value_gauge_item.unit = 1
  p2_stun_reset_value_gauge_item.unit = 1
  stun_reset_delay_item = integer_menu_item("stun_reset_delay", settings.training, "stun_reset_delay", 1, 100, false, 20)
  p1_stun_reset_value_gauge_item.is_disabled = function()
    return settings.training.stun_mode ~= 3
  end
  p2_stun_reset_value_gauge_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled
  stun_reset_delay_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled

  p1_meter_gauge_item = gauge_menu_item("p1_meter_reset_value", settings.training, "p1_meter_reset_value", 2, colors.gauges.meter)
  p2_meter_gauge_item = gauge_menu_item("p2_meter_reset_value", settings.training, "p2_meter_reset_value", 2, colors.gauges.meter)
  meter_refill_delay_item = integer_menu_item("meter_refill_delay", settings.training, "meter_refill_delay", 1, 100, false, 20)

  p1_meter_gauge_item.is_disabled = function()
    return settings.training.meter_mode ~= 2
  end
  p2_meter_gauge_item.is_disabled = p1_meter_gauge_item.is_disabled
  meter_refill_delay_item.is_disabled = p1_meter_gauge_item.is_disabled


  slot_weight_item = integer_menu_item("weight", recording_slots[settings.training.current_recording_slot], "weight", 0, 100, false, 1)
  counter_attack_delay_item = integer_menu_item("counter_attack_delay", recording_slots[settings.training.current_recording_slot], "delay", -40, 40, false, 0)
  counter_attack_random_deviation_item = integer_menu_item("counter_attack_max_random_deviation", recording_slots[settings.training.current_recording_slot], "random_deviation", -600, 600, false, 0, 1)

  charge_overcharge_on_item = checkbox_menu_item("display_overcharge", settings.training, "charge_overcharge_on")
  charge_overcharge_on_item.indent = true
  charge_overcharge_on_item.is_disabled = function()
  return not settings.training.display_charge
  end

  charge_follow_character_item = checkbox_menu_item("follow_character", settings.training, "charge_follow_character")
  charge_follow_character_item.indent = true
  charge_follow_character_item.is_disabled = function()
  return not settings.training.display_charge
  end

  blocking_item = list_menu_item("blocking", settings.training, "blocking_mode", blocking_mode)
  blocking_item.indent = true

  hits_before_red_parry_item = hits_before_menu_item("hits_before_rp_prefix", "hits_before_rp_suffix", settings.training, "red_parry_hit_count", 0, 20, true, 1)
  hits_before_red_parry_item.indent = true
  hits_before_red_parry_item.is_disabled = function()
    return settings.training.blocking_style ~= 3
  end

  parry_every_n_item = hits_before_menu_item("parry_every_prefix", "parry_every_suffix", settings.training, "parry_every_n_count", 0, 10, true, 1)
  parry_every_n_item.indent = true
  parry_every_n_item.is_disabled = function()
    return settings.training.blocking_style ~= 3
  end

  prefer_down_parry_item = checkbox_menu_item("prefer_down_parry", settings.training, "prefer_down_parry")
  prefer_down_parry_item.indent = true
  prefer_down_parry_item.is_disabled = function()
    return not (settings.training.blocking_style == 2 or settings.training.blocking_style == 3)
  end
  counter_attack_item = list_menu_item("counterattack", counter_attack_settings, "ca_type", counter_attack_type, 1, update_counter_attack_special)

  counter_attack_motion_item = motion_list_menu_item("counter_attack_motion", counter_attack_settings, "motion", counter_attack_motion_input, 1, update_counter_attack_button)
  counter_attack_motion_item.indent = true
  counter_attack_motion_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 2
  end

  counter_attack_button_item = list_menu_item("counter_attack_button", counter_attack_settings, "button", counter_attack_button)
  counter_attack_button_item.indent = true
  counter_attack_button_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 2
  end

  counter_attack_special_item = list_menu_item("counter_attack_special", counter_attack_settings, "special", counter_attack_special, 1, update_counter_attack_special)
  counter_attack_special_item.indent = true
  counter_attack_special_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 3
  end

  counter_attack_special_button_item = list_menu_item("counter_attack_button", counter_attack_settings, "special_button", counter_attack_special_button)
  counter_attack_special_button_item.indent = true
  counter_attack_special_button_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 3 or #counter_attack_special_button == 0
  end

  counter_attack_input_display_item = move_input_menu_item("hello", counter_attack_settings)
  counter_attack_input_display_item.inline = true
  counter_attack_input_display_item.is_disabled = function()
    return not (counter_attack_settings.ca_type == 3 or counter_attack_settings.ca_type == 4)
  end

  counter_attack_option_select_item = list_menu_item("counter_attack_option_select", counter_attack_settings, "option_select", counter_attack_option_select)
  counter_attack_option_select_item.indent = true
  counter_attack_option_select_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 4
  end

  hits_before_counter_attack = hits_before_menu_item("hits_before_ca_prefix", "hits_before_ca_suffix", settings.training, "hits_before_counter_attack_count", 0, 20, true)
  hits_before_counter_attack.indent = true
  hits_before_counter_attack.is_disabled = function()
    return counter_attack_settings.ca_type == 1
  end

  change_characters_item = button_menu_item("character_select", character_select.start_character_select_sequence)
  change_characters_item.is_disabled = function()
    -- not implemented for 4rd strike yet
    return rom_name ~= "sfiii3nr1"
  end

  p1_distances_reference_point_item = list_menu_item("p1_distance_reference_point", settings.training, "p1_distances_reference_point", distance_display_reference_point)
  p1_distances_reference_point_item.is_disabled = function()
    return not settings.training.display_distances
  end

  p2_distances_reference_point_item = list_menu_item("p2_distance_reference_point", settings.training, "p2_distances_reference_point", distance_display_reference_point)
  p2_distances_reference_point_item.is_disabled = function()
    return not settings.training.display_distances
  end
  mid_distance_height_item = integer_menu_item("mid_distance_height", settings.training, "mid_distance_height", 0, 200, false, 10)
  mid_distance_height_item.is_disabled = function()
    return not settings.training.display_distances
  end

  air_time_player_coloring_item = checkbox_menu_item("display_air_time_player_coloring", settings.training, "display_air_time_player_coloring")
  air_time_player_coloring_item.indent = true
  air_time_player_coloring_item.is_disabled = function()
  return not settings.training.display_air_time
  end

  attack_range_display_max_item = integer_menu_item("attack_range_max_attacks", settings.training, "attack_range_display_max_attacks", 1, 3, true, 1)
  attack_range_display_max_item.indent = true
  attack_range_display_max_item.is_disabled = function()
    return settings.training.display_attack_range == 1
  end
  attack_bars_show_decimal_item = checkbox_menu_item("show_decimal", settings.training, "attack_bars_show_decimal")
  attack_bars_show_decimal_item.indent = true
  attack_bars_show_decimal_item.is_disabled = function()
  return not (settings.training.display_attack_bars > 1)
  end


  language_item = list_menu_item("language", settings.training, "language", language, 1, update_dimensions)

  play_challenge_item = button_menu_item("play", play_challenge)
  select_char_challenge_item = button_menu_item("Select Character (Current: Gill)", select_character_hadou_matsuri)


  main_menu = make_multitab_menu(
    23, 14, 360, 197, -- screen size 383,223
    {
      {
        header = header_menu_item("dummy"),
        entries = {
          list_menu_item("pose", settings.training, "pose", pose),
          list_menu_item("blocking_style", settings.training, "blocking_style", blocking_style),
          blocking_item,
          hits_before_red_parry_item,
          parry_every_n_item,
          prefer_down_parry_item,
          counter_attack_item,
          counter_attack_motion_item,
          counter_attack_button_item,
          counter_attack_special_item, counter_attack_input_display_item,
          counter_attack_special_button_item,
          counter_attack_option_select_item,
          hits_before_counter_attack,
          list_menu_item("mash_stun", settings.training, "mash_stun_mode", mash_stun_mode, 1),
          list_menu_item("tech_throws", settings.training, "tech_throws_mode", tech_throws_mode),
          list_menu_item("quick_stand", settings.training, "fast_wakeup_mode", quick_stand),
        }
      },
      {
        header = header_menu_item("recording"),
        entries = {
          checkbox_menu_item("auto_crop_first_frames", settings.training, "auto_crop_recording_start"),
          checkbox_menu_item("auto_crop_last_frames", settings.training, "auto_crop_recording_end"),
          list_menu_item("replay_mode", settings.training, "replay_mode", slot_replay_mode),
          integer_menu_item("menu_slot", settings.training, "current_recording_slot", 1, recording_slot_count, true, 1, 10, update_current_recording_slot_frames),
                                frame_number_item(current_recording_slot_frames, true),
          slot_weight_item,
          counter_attack_delay_item,
          counter_attack_random_deviation_item,
          button_menu_item("clear_slot", clear_slot),
          button_menu_item("clear_all_slots", clear_all_slots),
          button_menu_item("save_slot_to_file", open_save_popup),
          button_menu_item("load_slot_from_file", open_load_popup),
        }
      },
      {
        header = header_menu_item("display"),
        entries = {
          checkbox_menu_item("display_controllers", settings.training, "display_input"),
          controller_style_menu_item,
          list_menu_item("display_input_history", settings.training, "display_input_history", display_input_history_mode, 1),
          checkbox_menu_item("display_gauge_numbers", settings.training, "display_gauges", false),
          checkbox_menu_item("display_bonuses", settings.training, "display_bonuses", true),
          checkbox_menu_item("display_attack_info", settings.training, "display_attack_data"),
          list_menu_item("display_attack_bars", settings.training, "display_attack_bars", display_attack_bars_mode, 3),
          attack_bars_show_decimal_item,
          checkbox_menu_item("display_frame_advantage", settings.training, "display_frame_advantage"),
          checkbox_menu_item("display_hitboxes", settings.training, "display_hitboxes"),
          checkbox_menu_item("display_distances", settings.training, "display_distances"),
          mid_distance_height_item,
          p1_distances_reference_point_item,
          p2_distances_reference_point_item,
          checkbox_menu_item("display_air_time", settings.training, "display_air_time"),
          air_time_player_coloring_item,
          checkbox_menu_item("display_charge", settings.training, "display_charge"),
          charge_follow_character_item,
          charge_overcharge_on_item,
          checkbox_menu_item("display_parry", settings.training, "display_parry"),
          checkbox_menu_item("display_red_parry_miss", settings.training, "display_red_parry_miss"),
          list_menu_item("attack_range_display", settings.training, "display_attack_range", player_options_list),
          attack_range_display_max_item,
          language_item
        }
      },
      {
        header = header_menu_item("rules"),
        entries = {
          change_characters_item,
          list_menu_item("force_stage", settings.training, "force_stage", stage_list, 1),
          checkbox_menu_item("infinite_time", settings.training, "infinite_time"),
          list_menu_item("life_refill_mode", settings.training, "life_mode", gauge_refill_mode),
          p1_life_reset_value_gauge_item,
          p2_life_reset_value_gauge_item,
          life_refill_delay_item,
          list_menu_item("stun_mode", settings.training, "stun_mode", gauge_refill_mode),
          p1_stun_reset_value_gauge_item,
          p2_stun_reset_value_gauge_item,
          stun_reset_delay_item,
          list_menu_item("meter_refill_mode", settings.training, "meter_mode", gauge_refill_mode),
          p1_meter_gauge_item,
          p2_meter_gauge_item,
          meter_refill_delay_item,
          checkbox_menu_item("infinite_super_art_time", settings.training, "infinite_sa_time"),
          integer_menu_item("music_volume", settings.training, "music_volume", 0, 10, false, 10),
          checkbox_menu_item("speed_up_game_intro", settings.training, "fast_forward_intro"),
          list_menu_item("cheat_parrying", settings.training, "cheat_parrying", player_options_list),
          checkbox_menu_item("universal_cancel", settings.training, "universal_cancel"),
          checkbox_menu_item("infinite_projectiles", settings.training, "infinite_projectiles"),
          checkbox_menu_item("infinite_juggle", settings.training, "infinite_juggle")
        }
      },
      {
        header = header_menu_item("training"),
        entries = {
          list_menu_item("mode", settings.training, "special_training_mode", special_training_mode),

        }
      },
        {
          header = header_menu_item("challenge"),
          entries = {
            list_menu_item("challenge", settings.training, "challenge_current_mode", challenge_mode),
                                play_challenge_item,
                                select_char_challenge_item
          }
        }
    },
    function ()
      recording.backup_recordings()
      settings.save_training_data()
    end
  )

  -- debug_move_menu_item = map_menu_item("debug_move", debug_settings, "debug_move", frame_data, nil)
  if debug_settings.developer_mode then
    local debug_settings_menu = {
      header = header_menu_item("debug"),
      entries = {
        checkbox_menu_item("show_predicted_hitboxes", debug_settings, "show_predicted_hitbox"),
        checkbox_menu_item("record_frame_data", debug_settings, "record_framedata"),
        button_menu_item("save_frame_data", save_frame_data),
        map_menu_item("debug_character", debug_settings, "debug_character", _G, "frame_data")
        -- debug_move_menu_item
      },
      topmost_entry = 1
    }
    table.insert(main_menu.content, debug_settings_menu)
  end

  initialized = true
end

function open_save_popup()
  save_recording_slot_popup.selected_index = 1
  menu_stack_push(save_recording_slot_popup)
  save_file_name = string.gsub(training.dummy.char_str, "(.*)", string.upper).."_"
end

function open_load_popup()
  load_recording_slot_popup.selected_index = 1
  menu_stack_push(load_recording_slot_popup)

  load_file_index = 1

  local cmd = "dir /b "..string.gsub(saved_recordings_path, "/", "\\")
  local f = io.popen(cmd)
  if f == nil then
    print(string.format("Error: Failed to execute command \"%s\"", cmd))
    return
  end
  local str = f:read("*all")
  load_file_list = {}
  for line in string.gmatch(str, '([^\r\n]+)') do -- Split all lines that have ".json" in them
    if string.find(line, ".json") ~= nil then
      local file = line
      table.insert(load_file_list, file)
    end
  end
  load_recording_slot_popup.content[1].list = load_file_list
end

function is_guard_jump(str)
  for i = 1, #guard_jumps do
    if str == guard_jumps[i] then
      return true
    end
  end
  return false
end


function input_to_text(t)
  local result = {}
  for i = 1, #t do
    local text = ""
    for j = 1, #t[i] do
      if t[i][j] == "down" then
        text = text .. "Dummy"
      elseif t[i][j] == "up" then
        text = text .. "U"
      elseif t[i][j] == "forward" then
        text = text .. "F"
      elseif t[i][j] == "back" then
        text = text .. "B"
      end
    end
    if text ~= "" then
      text = text .. "+"
    end
    for j = 1, #t[i] do
      if t[i][j] == "LP" or t[i][j] == "MP" or t[i][j] == "HP"
      or t[i][j] == "LK" or t[i][j] == "MK" or t[i][j] == "HK" then
         text = text .. t[i][j]
        if j + 1 <= #t[i] then
          text = text .. "+"
        end
      end
    end
    table.insert(result, text)
  end
  return result
end


counter_attack_settings =
{
    ca_type = 1,
    motion = 1,
    button = 1,
    special = 1,
    special_button = 1,
    option_select = 1
}

counter_attack_type_index = 1

counter_attack_button = counter_attack_button_default

counter_attack_special = {}
counter_attack_special_button = {}


function update_counter_attack_settings()
  if initialized then
    counter_attack_settings = settings.training.counter_attack[training.dummy.char_str]
    counter_attack_item.object = counter_attack_settings
    counter_attack_motion_item.object = counter_attack_settings
    counter_attack_button_item.object = counter_attack_settings
    counter_attack_special_item.object = counter_attack_settings
    counter_attack_special_button_item.object = counter_attack_settings
    counter_attack_option_select_item.object = counter_attack_settings
    counter_attack_input_display_item.object = counter_attack_settings
  end
end

counter_attack_button_input = {}
function update_counter_attack_button()
  --kara throw if initialized then
  if counter_attack_settings.motion == 15 then
    for i = 1, #move_list[training.dummy.char_str] do
      if move_list[training.dummy.char_str][i].move_type == "kara" then
          counter_attack_button_input = move_list[training.dummy.char_str][i].buttons
          counter_attack_button = input_to_text(counter_attack_button_input)
          break
      end
    end
  else
    counter_attack_button = counter_attack_button_default
  end
  counter_attack_button_item.list = counter_attack_button
  if counter_attack_settings.button > #counter_attack_button then
    counter_attack_settings.button = #counter_attack_button
    if #counter_attack_button == 0 then
      counter_attack_settings.button = 1
    end
  end
end

counter_attack_special_inputs = {}
counter_attack_special_types = {}
function update_counter_attack_special()
  local list = {}
  counter_attack_special_inputs = {}
  counter_attack_special_types = {}
  local sa_str = "sa" .. training.dummy.selected_sa
  for i = 1, #move_list[training.dummy.char_str] do
    if move_list[training.dummy.char_str][i].move_type == "special" or move_list[training.dummy.char_str][i].move_type == "kara_special" or move_list[training.dummy.char_str][i].move_type == sa_str
    or (training.dummy.char_str == "gouki" and (move_list[training.dummy.char_str][i].name == "sgs" or move_list[training.dummy.char_str][i].name== "kkz"))
    or (training.dummy.char_str == "shingouki" and move_list[training.dummy.char_str][i].name == "sgs")
    or (training.dummy.char_str == "gill" and (move_list[training.dummy.char_str][i].name == "meteor_strike" or move_list[training.dummy.char_str][i].name == "seraphic_wing"))
    then
      table.insert(list, move_list[training.dummy.char_str][i].name)
      table.insert(counter_attack_special_inputs, move_list[training.dummy.char_str][i].input)
      table.insert(counter_attack_special_types, move_list[training.dummy.char_str][i].move_type)
    end
  end

  counter_attack_special_item.list = list
  counter_attack_special = list
  update_counter_attack_special_button()
--   update_counter_attack_button()
  update_dimensions()
end

function update_counter_attack_special_button()
  local move = counter_attack_special[settings.training.counter_attack[training.dummy.char_str].special]
  for i = 1, #move_list[training.dummy.char_str] do
    if move_list[training.dummy.char_str][i].name == move then
      counter_attack_special_button_item.list = move_list[training.dummy.char_str][i].buttons
      counter_attack_special_button = move_list[training.dummy.char_str][i].buttons
      break
    end
  end
  if counter_attack_settings.special_button > #counter_attack_special_button then
    counter_attack_settings.special_button = #counter_attack_special_button
    if #counter_attack_special_button == 0 then
      counter_attack_settings.special_button = 1
    end
  end
end

function update_menu()
  slot_weight_item.object = recording_slots[settings.training.current_recording_slot]
  counter_attack_delay_item.object = recording_slots[settings.training.current_recording_slot]
  counter_attack_random_deviation_item.object = recording_slots[settings.training.current_recording_slot]
end

function update_gauge_items()
  settings.training.p1_meter_reset_value = math.min(settings.training.p1_meter_reset_value, gamestate.P1.max_meter_count * gamestate.P1.max_meter_gauge)
  settings.training.p2_meter_reset_value = math.min(settings.training.p2_meter_reset_value, gamestate.P2.max_meter_count * gamestate.P2.max_meter_gauge)
  p1_meter_gauge_item.gauge_max = gamestate.P1.max_meter_gauge * gamestate.P1.max_meter_count
  p1_meter_gauge_item.subdivision_count = gamestate.P1.max_meter_count
  p2_meter_gauge_item.gauge_max = gamestate.P2.max_meter_gauge * gamestate.P2.max_meter_count
  p2_meter_gauge_item.subdivision_count = gamestate.P2.max_meter_count
  settings.training.p1_stun_reset_value = math.min(settings.training.p1_stun_reset_value, gamestate.P1.stun_max)
  settings.training.p2_stun_reset_value = math.min(settings.training.p2_stun_reset_value, gamestate.P2.stun_max)
  p1_stun_reset_value_gauge_item.gauge_max = gamestate.P1.stun_max
  p2_stun_reset_value_gauge_item.gauge_max = gamestate.P2.stun_max
end



local horizontal_autofire_rate = 4
local vertical_autofire_rate = 4
function handle_input()
  if initialized then
    if gamestate.is_in_match then
      local should_toggle = gamestate.P1.input.pressed.start
      if debug_settings.log_enabled then
        should_toggle = gamestate.P1.input.released.start
      end
      should_toggle = not debug_settings.log_start_locked and should_toggle

      if should_toggle then
        is_open = (not is_open)
        if is_open then
          update_counter_attack_settings()
          menu_stack_push(main_menu)
        else
          menu_stack_clear()
        end
      end
    else
      is_open = false
      menu_stack_clear()
    end

    if is_open then
      local current_entry = menu_stack_top():current_entry()
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

      menu_stack_update(input)

      menu_stack_draw()
    end
  end
end