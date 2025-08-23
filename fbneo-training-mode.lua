require("src.startup")

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
require("src.control.write_memory")
local settings = require("src/settings")
local debug_settings = require("src/debug_settings")
local recording = require("src.control.recording")
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local text = require("src.ui.text")
local gamestate = require("src/gamestate")
local loading = require("src/loading")
local training = require("src/training")
require("src.control.dummy_control")
local images = require("src.ui.image_tables")
local draw = require("src.ui.draw")
local hud = require("src.ui.hud")
local inp = require("src.control.input")
local input_history = require("src.ui.input_history")
require("src.modules.prediction")
local menu = require("src.ui.menu")
local attack_data = require("src.modules.attack_data")
require("src.modules.frame_advantage")
local character_select = require("src.control.character_select")
-- require("src/training/jumpins")
require("src.modules.record_framedata")
local debug = require("src/debug")

--aliases
local frame_data, character_specific = fd.frame_data, fd.character_specific
local frame_data_meta = fdm.frame_data_meta
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text, text.render_text_multiple, text.get_text_dimensions, text.get_text_dimensions_multiple
local swap_inputs, interpret_input = inp.swap_inputs, inp.interpret_input

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
  attack_data.reset()
  frame_advantage_reset()

  gamestate.gamestate_read()

  recording.restore_recordings()

  -- reset recording states in a useful way
  if current_recording_state == 3 then
    set_recording_state({}, 2)
  elseif current_recording_state == 4 and (settings.training.replay_mode == 4 or settings.training.replay_mode == 5 or settings.training.replay_mode == 6) then
    set_recording_state({}, 1)
    set_recording_state({}, 4)
  end

  input_history.clear_input_history()
  emu.speedmode("normal")

  for key, com in ipairs(after_load_state_callback) do
    Queue_Command(gamestate.frame_number+1, {command = com.command, args = com.args})
    after_load_state_callback[key] = nil
  end
end

local function on_start()
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
  elseif loading.text_images_loaded and not menu.initialized then
    menu.init_menu()
  end

  draw.update_draw_variables()

  -- gamestate
  local previous_p2_char_str = gamestate.P2.char_str or ""
  local previous_dummy_char_str = training.dummy.char_str or ""
  gamestate.gamestate_read()

  run_commands()

  if debug_settings.developer_mode then
    debug.run_debug()
  end

  if menu.initialized then
    menu.update_menu()
    -- load recordings according to gamestate.P2 character
    if previous_p2_char_str ~= gamestate.P2.char_str then
      recording.restore_recordings()
    end
    --update character specific settings on training.dummy change
    if previous_dummy_char_str ~= training.dummy.char_str then
      menu.update_counter_attack_items()
    end
    if gamestate.has_match_just_started then
      hud.attack_range_display_reset()
      hud.red_parry_miss_display_reset()
    end
    if gamestate.is_in_match then
      menu.update_gauge_items()
      menu.update_counter_attack_items()
    end
  end

  training.freeze_game = menu.is_open
  training.update_training_state()

  -- input
  local input = joypad.get()
  if gamestate.is_in_match and not menu.is_open and training.swap_characters then
    swap_inputs(input)
  end
 
  character_select.update_character_select(input, settings.training.fast_forward_intro)

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

   if not training.swap_characters then
    training.player = gamestate.P1
    training.dummy = gamestate.P2
  else
    training.player = gamestate.P2
    training.dummy = gamestate.P1
  end

  --challenge
--[[   if is_in_challenge then
    if settings.training.challenge_current_mode == 1 then
      hadou_matsuri_run()
      if gamestate.is_in_match then
        input = hm_input --for input display
      end
    end
  end ]]

  if loading.frame_data_loaded and gamestate.is_in_match and not debug_settings.recording_framedata then
    -- attack data
    attack_data.update(training.player, training.dummy)

    -- frame advantage
    frame_advantage_update(training.player, training.dummy)

    -- blocking
    update_blocking(input, training.player, training.dummy, settings.training.blocking_mode, settings.training.blocking_style, settings.training.red_parry_hit_count, settings.training.parry_every_n_count)

    hud.update_blocking_direction(input, training.player, training.dummy)

    -- pose
    update_pose(input, training.player, training.dummy, settings.training.pose)

    -- mash stun
    update_mash_stun(input, training.player, training.dummy, settings.training.mash_stun_mode)

    -- fast wake-up
    update_fast_wake_up(input, training.player, training.dummy, settings.training.fast_wakeup_mode)

    -- tech throws
    update_tech_throws(input, training.player, training.dummy, settings.training.tech_throws_mode)

    -- counter attack
    update_counter_attack(input, training.player, training.dummy, settings.training.counter_attack[training.dummy.char_str], settings.training.hits_before_counter_attack_count)

    -- recording
    if not menu.is_open then
      update_recording(input, training.player, training.dummy)
    end
  end

  if not menu.is_open then
    process_pending_input_sequence(gamestate.P1, input)
    process_pending_input_sequence(gamestate.P2, input)
  end

  if gamestate.is_in_match then
    input_history.input_history_update(gamestate.P1, input)
    input_history.input_history_update(gamestate.P2, input)
  else
    input_history.clear_input_history()
    frame_advantage_reset()
  end

  inp.previous_input = input

  if not (gamestate.is_in_match and is_in_challenge) then
    joypad.set(input)
  end

  record_frames_hotkey()

  if debug_settings.recording_framedata then
    update_framedata_recording(gamestate.P1, gamestate.projectiles)
  end

  log_update(gamestate.P1)
end


local function on_gui()

  draw.draw_character_select()

  draw.loading_bar_display(loading_bar_loaded, loading_bar_total)

  if loading.text_images_loaded then

    if gamestate.is_in_match and not disable_display then
      -- input history
      if settings.training.display_input_history == 5 then --moving
        if gamestate.P1.pos_x < 320 then
          input_history.input_history_draw(gamestate.P1, draw.SCREEN_WIDTH - 4, 49, true, draw.controller_styles[settings.training.controller_style])
        else
          input_history.input_history_draw(gamestate.P1, 4, 49, false, draw.controller_styles[settings.training.controller_style])
        end
      else
        if settings.training.display_input_history == 2 or settings.training.display_input_history == 4 then
          input_history.input_history_draw(gamestate.P1, 4, 49, false, draw.controller_styles[settings.training.controller_style])
        end
        if settings.training.display_input_history == 3 or settings.training.display_input_history == 4 then
          input_history.input_history_draw(gamestate.P2, draw.SCREEN_WIDTH - 4, 49, true, draw.controller_styles[settings.training.controller_style])
        end
      end

      -- controllers
      if settings.training.display_input then
        local input = joypad.get()
        local p1 = input_history.make_input_history_entry("P1", input)
        local p2 = input_history.make_input_history_entry("P2", input)
        draw.draw_controller_big(p1, 44, 34, draw.controller_styles[settings.training.controller_style])
        draw.draw_controller_big(p2, 310, 34, draw.controller_styles[settings.training.controller_style])
      end


      hud.draw_hud(training.player, training.dummy)


      if settings.training.display_frame_advantage then
        frame_advantage_display()
      end
    end

    if debug_settings.log_enabled then
      debug.log_draw()
    end

    if debug_settings.developer_mode then
      debug.draw_debug()
    end

    menu.handle_input()

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
