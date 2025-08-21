require("src/startup")

print("-----------------------------")
print("  3rd_training.lua - "..script_version.."")
print("  Training mode for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/effie3rd/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Enter training menu by pressing \"Start\" while in game")
print("- Enter/exit recording mode by double tapping \"Coin\"")
print("- In recording mode, press \"Coin\" again to start/stop recording")
print("- In normal mode, press \"Coin\" to start/stop replay")
print("- Lua Hotkey 1 (alt+1) to return to character select screen")
print("")


-- Kudos to indirect contributors:
-- *esn3s* for his work on 3s frame data : http://baston.esn3s.com/
-- *dammit* for his work on 3s hitbox display script : https://dammit.typepad.com/blog/2011/10/improved-3rd-strike-hitboxes.html
-- *furitiem* for his prior work on 3s C# training program : https://www.youtube.com/watch?v=vE27xe0QM64
-- *crytal_cube99* for his prior work on 3s training & trial scripts : https://ameblo.jp/3fv/

-- Thanks to *speedmccool25* for recording all the 4rd strike frame data
-- Thanks to *ProfessorAnon* for the Charge and Hyakuretsu Kyaku special training mode
-- Thanks to *sammygutierrez* for the damage info display

-- FBA-RR Scripting reference:
-- http://tasvideos.org/EmulatorResources/VBA/LuaScriptingFunctions.html
-- https://github.com/TASVideos/mame-rr/wiki/Lua-scripting-functions

-- Resources
-- https://github.com/Jesuszilla/mame-rr-scripts/blob/master/framedata.lua
-- https://imgur.com/gallery/0Tsl7di

-- Lua-GD Scripting reference:
-- https://www.ittner.com.br/lua-gd/manual.html


-- Includes
require("src/tools")
local timer = perf_timer:new()
require("src/memory_addresses")
require("src/write_memory")
require("src/recording")
require("src/settings")
local fd = require("src/framedata")
local fdm = require("src/framedata_meta")
local text = require("src/text")
local gamestate = require("src/gamestate")
local loading = require("src/loading")
local training = require("src/training")
require("src/dummy_control")
require("src/draw")
require("src/display")
require("src/hud")
require("src/input")
require("src/prediction")
require("src/menu_tables")
require("src/menu_items")
require("src/menu")
require("src/input_history")
require("src/attack_data")
require("src/frame_advantage")
local character_select = require("src/character_select")
-- require("src/training/jumpins")
require("src/record_framedata")
local debug = require("src/debug")

--aliases
local frame_data, character_specific = fd.frame_data, fd.character_specific
local frame_data_meta = fdm.frame_data_meta
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text, text.render_text_multiple, text.get_text_dimensions, text.get_text_dimensions_multiple

local disable_display = false

local command_queue = {}

local loading_bar_loaded = 0
local loading_bar_total = loading.get_total_files()

local after_load_state_callback = {}
function Register_After_Load_State(command, args)
  table.insert(after_load_state_callback, {command = command, args = args})
end

local function on_load_state()
  gamestate.reset_player_objects()
  attack_data_reset()
  frame_advantage_reset()

  gamestate.gamestate_read()

  restore_recordings()

  -- reset recording states in a useful way
  if current_recording_state == 3 then
    set_recording_state({}, 2)
  elseif current_recording_state == 4 and (training_settings.replay_mode == 4 or training_settings.replay_mode == 5 or training_settings.replay_mode == 6) then
    set_recording_state({}, 1)
    set_recording_state({}, 4)
  end

  clear_input_history()
  clear_printed_geometry()
  emu.speedmode("normal")

  for key, com in ipairs(after_load_state_callback) do
    Queue_Command(gamestate.frame_number+1, {command = com.command, args = com.args})
    after_load_state_callback[key] = nil
  end
end

local function on_start()
  load_training_data()

  emu.speedmode("normal")

  character_select.start_character_select_sequence()
  print("load time:", timer:elapsed())
end

local function hotkey1()
  -- is_in_challenge = false
  set_recording_state({}, 1)
  character_select.start_character_select_sequence()
end

local function hotkey2()
  character_select.select_gill()
end

local function hotkey3()
  character_select.select_shingouki()
end

local function hotkey4() --debug
  queue_input_from_json(gamestate.P1, "Debug.json")
end

local function hotkey5() --debug
  debug.debug_things()
end

local function hotkey6() --debug
end

local function hotkey7() --debug
  debug.start_debug = true
end


input.registerhotkey(1, hotkey1)
if rom_name == "sfiii3nr1" then
  input.registerhotkey(2, hotkey2)
  input.registerhotkey(3, hotkey3)
  input.registerhotkey(4, hotkey4)
  input.registerhotkey(5, hotkey5)
  input.registerhotkey(6, hotkey6)
  input.registerhotkey(7, hotkey7)
end

function Queue_Command(frame, command)
  if not command_queue[frame] then
    command_queue[frame] = {}
  end
  table.insert(command_queue[frame], command)
end

local function run_commands()
  for key, commands in pairs(command_queue) do
    if key == gamestate.frame_number then
      for _,com in pairs(commands) do
        if com.args then
          com.command(unpack(com.args))
        else
          com.command()
        end
        command_queue[key] = nil
      end
    end
  end
end


local function before_frame()

  if not loading.text_images_loaded or not loading.frame_data_loaded then
    local number_loaded = loading.load_all()
    loading_bar_loaded = loading_bar_loaded + number_loaded
  elseif loading.text_images_loaded and not initialized then
    init_menu()
  end

  draw_read()

  -- gamestate
  local previous_p2_char_str = gamestate.P2.char_str or ""
  local previous_dummy_char_str = training.dummy.char_str or ""
  gamestate.gamestate_read()

  run_commands()

  debug.run_debug()

  if initialized then --menu.initialized
    slot_weight_item.object = recording_slots[training_settings.current_recording_slot]
    counter_attack_delay_item.object = recording_slots[training_settings.current_recording_slot]
    counter_attack_random_deviation_item.object = recording_slots[training_settings.current_recording_slot]
    -- load recordings according to gamestate.P2 character
    if previous_p2_char_str ~= gamestate.P2.char_str then
      restore_recordings()
    end
    --update character specific settings on training.dummy change
    if previous_dummy_char_str ~= training.dummy.char_str then
      update_counter_attack_settings()
    end

    if gamestate.has_match_just_started then
      attack_range_display_reset()
      red_parry_miss_display_reset()
      update_counter_attack_settings()
      update_counter_attack_button()
      update_counter_attack_special()
    end
    if gamestate.is_in_match then
      update_gauge_items()
    end
  end

  training.update_training_state()

  -- input
  local input = joypad.get()
  if gamestate.is_in_match and not IsMenuOpen and swap_characters then
    swap_inputs(input)
  end

  character_select.update_character_select(input, training_settings.fast_forward_intro)

  if not gamestate.is_in_match then
    if gamestate.P1.input.pressed.start then
      character_select.start_select_random_character()
    elseif gamestate.P1.input.released.start then
      character_select.stop_select_random_character()
    end
    if gamestate.P1.input.down.start then
      character_select.select_random_character()
    end
  end

  if not swap_characters then
    training.player = gamestate.P1
    training.dummy = gamestate.P2
  else
    training.player = gamestate.P2
    training.dummy = gamestate.P1
  end

  --challenge
--[[   if is_in_challenge then
    if training_settings.challenge_current_mode == 1 then
      hadou_matsuri_run()
      if gamestate.is_in_match then
        input = hm_input --for input display
      end
    end
  end ]]

  if loading.frame_data_loaded and gamestate.is_in_match and not debug_settings.record_framedata then
    -- attack data
    attack_data_update(training.player, training.dummy)

    -- frame advantage
    frame_advantage_update(training.player, training.dummy)

    -- blocking
    update_blocking(input, training.player, training.dummy, training_settings.blocking_mode, training_settings.blocking_style, training_settings.red_parry_hit_count, training_settings.parry_every_n_count)

    update_blocking_direction(input, training.player, training.dummy)

    -- pose
    update_pose(input, training.player, training.dummy, training_settings.pose)

    -- mash stun
    update_mash_stun(input, training.player, training.dummy, training_settings.mash_stun_mode)

    -- fast wake-up
    update_fast_wake_up(input, training.player, training.dummy, training_settings.fast_wakeup_mode)

    -- tech throws
    update_tech_throws(input, training.player, training.dummy, training_settings.tech_throws_mode)

    -- counter attack
    update_counter_attack(input, training.player, training.dummy, counter_attack_settings, training_settings.hits_before_counter_attack_count)

    -- recording
    update_recording(input, training.player, training.dummy)
  end

  process_pending_input_sequence(gamestate.P1, input)
  process_pending_input_sequence(gamestate.P2, input)

  if gamestate.is_in_match then
    input_history_update(input_history[1], "P1", input)
    input_history_update(input_history[2], "P2", input)
  else
    clear_input_history()
    frame_advantage_reset()
  end

  -- log_input(gamestate.player_objects)

  previous_input = input


  if not (gamestate.is_in_match and is_in_challenge) then
    joypad.set(input)
  end

  record_frames_hotkey()

  update_framedata_recording(gamestate.P1, gamestate.projectiles)

  debugframedatagui(gamestate.P1, gamestate.projectiles)

  log_update(gamestate.P1)
end


local function on_gui()

  character_select.draw_character_select()

  loading_bar_display(loading_bar_loaded, loading_bar_total)

  if loading.text_images_loaded then

    if gamestate.P1.input.pressed.start then
      clear_printed_geometry()
    end

    if gamestate.is_in_match and not disable_display then

      display_draw_printed_geometry()

      -- distances
      if training_settings.display_distances then
        display_draw_distances(gamestate.P1, gamestate.P2, training_settings.mid_distance_height, training_settings.p1_distances_reference_point, training_settings.p2_distances_reference_point)
      end

      -- input history
      if training_settings.display_input_history == 5 then --moving
        if gamestate.P1.pos_x < 320 then
          input_history_draw(input_history[1], screen_width - 4, 49, true, controller_styles[training_settings.controller_style])
        else
          input_history_draw(input_history[1], 4, 49, false, controller_styles[training_settings.controller_style])
        end
      else
        if training_settings.display_input_history == 2 or training_settings.display_input_history == 4 then
          input_history_draw(input_history[1], 4, 49, false, controller_styles[training_settings.controller_style])
        end
        if training_settings.display_input_history == 3 or training_settings.display_input_history == 4 then
          input_history_draw(input_history[2], screen_width - 4, 49, true, controller_styles[training_settings.controller_style])
        end
      end

      -- controllers
      if training_settings.display_input then
        local i = joypad.get()
        local p1 = make_input_history_entry("P1", i)
        local p2 = make_input_history_entry("P2", i)
        draw_controller_big(p1, 44, 34, controller_styles[training_settings.controller_style])
        draw_controller_big(p2, 310, 34, controller_styles[training_settings.controller_style])
      end




      draw_hud(training.player, training.dummy)


  
      --debug
      for i=1,#to_draw_collision do
        local x1, y1 = game_to_screen_space(to_draw_collision[i][1], to_draw_collision[i][3])
        local x2, y2 = game_to_screen_space(to_draw_collision[i][2], to_draw_collision[i][4])
        gui.drawline(x1,y1,x2,y2,0x000000FF)
      end

      -- attack data
      -- do not show if special training not following character is on, otherwise it will overlap
      if training_settings.display_attack_data and (training_settings.special_training_current_mode == 1 or training_settings.charge_follow_character) then
        attack_data_display()
      end

      -- move advantage
      if training_settings.display_frame_advantage then
        frame_advantage_display()
      end
    end

    if log_enabled then
      log_draw()
    end

    handle_input() -- main_menu.handle_input()

    if not IsMenuOpen then
      -- draw_debug_gui()
    end

    debug.memory_display()

    -- debug.memory_view_display()
    -- debug.dump_state_display()

    --debug
    if gamestate.frame_number % 2000 == 0 then
      collectgarbage()
      print("GC memory:", collectgarbage("count"))
    end

    if gamestate.projectiles then
      for _,obj in pairs(gamestate.projectiles) do
        table.insert(to_draw, {obj.pos_x, obj.pos_y})
      end
    end
    local x, y = 0, 0
    for i=1,#to_draw do
      x, y = game_to_screen_space(to_draw[i][1], to_draw[i][2])
      gui.image(x - 4, y,img_8_dir_small, i/#to_draw)
    end

    to_draw = {}

--[[     for k, data in pairs(debug_prediction) do
      if gamestate.frame_number == k then
        local x = 72
        local y = 60
        render_text(x,y, string.format("Pos: %f,%f", data[gamestate.P1].pos_x, data[gamestate.P1].pos_y), "en", nil, "white")
        render_text(x,y+10, string.format("Vel: %f,%f", data[gamestate.P1].velocity_x, data[gamestate.P1].velocity_y), "en", nil, "white")
        render_text(x,y+20, string.format("Acc: %f,%f", data[gamestate.P1].acceleration_x, data[gamestate.P1].acceleration_y), "en", nil, "white")
        render_text(x,y+30, string.format("Pos: %f,%f", data[gamestate.P2].pos_x, data[gamestate.P2].pos_y), "en", nil, "white")
        render_text(x,y+40, string.format("Vel: %f,%f", data[gamestate.P2].velocity_x, data[gamestate.P2].velocity_y), "en", nil, "white")
        render_text(x,y+50, string.format("Acc: %f,%f", data[gamestate.P2].acceleration_x, data[gamestate.P2].acceleration_y), "en", nil, "white")

      elseif k < gamestate.frame_number then
        debug_prediction[k] = nil
      end
    end ]]

    gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared
  end
end

to_draw_hitboxes = {}
to_draw_collision = {}
debug_prediction = {}

-- registers
emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)
