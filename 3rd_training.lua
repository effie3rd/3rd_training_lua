local game_data = require("src.modules.game_data")
print("-----------------------------")
print("  effie's 3rd_training.lua - " .. game_data.script_version .. "")
print("  Training mode for " .. game_data.game_name .. "")
print("  Project url: https://github.com/effie3rd/3rd_training_lua")
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
local tools = require("src.tools")
local timer = tools.Perf_Timer:new()
local settings = require("src.settings")
local debug_settings = require("src.debug_settings")
local recording = require("src.control.recording")
local gamestate = require("src.gamestate")
local loading = require("src.loading")
local training = require("src.training")
local prediction = require("src.modules.prediction")
local advanced_control = require("src.control.advanced_control")
local defense = require("src.training.defense")
local unblockables = require("src.training.unblockables")
local jumpins = require("src.training.jumpins")
local dummy_control = require("src.control.dummy_control")
local draw = require("src.ui.draw")
local hud = require("src.ui.hud")
local inputs = require("src.control.inputs")
local input_history = require("src.ui.input_history")
local menu = require("src.ui.menu")
local attack_data = require("src.modules.attack_data")
local frame_advantage = require("src.modules.frame_advantage")
local character_select = require("src.control.character_select")
local debug = require("src.debug")

local disable_display = false

local command_queue = {}
local after_load_state_callback = {}

local loading_bar_loaded = 0
local loading_bar_total = loading.get_total_files()

local special_training_modes = {defense, jumpins, unblockables}

Load_State_Caller = ""

local function hotkey1()
   recording.set_recording_state({}, 1)
   character_select.start_character_select_sequence()
end
local function hotkey2() character_select.select_gill() end
local function hotkey3() character_select.select_shingouki() end
local function hotkey4() -- debug
   inputs.queue_input_from_json(gamestate.P1, "Debug.json")
   -- queue_denjin(gamestate.P1, 80)
   -- queue_denjin(gamestate.P2, 80)
end

local function hotkey5() -- debug
   -- memory_view_start = gamestate.P2.addresses.received_connection_marker
   debug.debug_things()
end

local function hotkey6() -- debug
   hud.add_player_label(gamestate.P2, "hud_cpu")
end

local function hotkey7() -- debug
   debug.start_debug = true
   -- memory_view_start = gamestate.P2.base + 0x20E
   jumpins.debug_jump()
end
local function hotkey8() -- debug
   -- memory_view_start = gamestate.P2.base + 0x33E
   -- memory_view_start = 0x020154A7
end
local function hotkey9() -- debug
   require("src.modules.record_framedata").process_framedata_and_save()
   -- jumpins.single_jump()
end

if game_data.rom_name == "sfiii3nr1" then
   input.registerhotkey(1, hotkey1)
   input.registerhotkey(2, hotkey2)
   input.registerhotkey(3, hotkey3)
   input.registerhotkey(4, hotkey4)
   input.registerhotkey(5, hotkey5)
   input.registerhotkey(6, hotkey6)
   input.registerhotkey(7, hotkey7)
   input.registerhotkey(8, hotkey8)
   input.registerhotkey(9, hotkey9)
end

function Register_After_Load_State(command, args, delay)
   table.insert(after_load_state_callback, {command = command, args = args, delay = delay})
end

function Queue_Command(frame, command, args)
   if not command_queue[frame] then command_queue[frame] = {} end
   table.insert(command_queue[frame], {command = command, args = args})
end

local function run_commands()
   for key, commands in pairs(command_queue) do
      if key == gamestate.frame_number then
         for _, com in pairs(commands) do
            if com.args then
               com.command(unpack(com.args))
            else
               com.command()
            end
            command_queue[key] = nil
         end
      elseif key < gamestate.frame_number then
         command_queue[key] = nil
      end
   end
end

local function on_start()
   emu.speedmode("normal")

   math.randomseed(os.time())

   character_select.start_character_select_sequence()
   print("load time:", timer:elapsed())
end

local function on_load_state()
   gamestate.reset_player_objects()
   gamestate.gamestate_read()

   attack_data.reset()
   frame_advantage.reset()

   recording.restore_recordings()

   training.reset_gauge_state()

   if menu.is_initialized then menu.update_menu_items() end

   hud.reset_hud()

   input_history.clear_input_history()

   recording.reset_recording_state()

   for _, mode in ipairs(special_training_modes) do
      if not (Load_State_Caller == mode.module_name) then mode.stop() end
   end

   if Load_State_Caller == "" or Load_State_Caller == "3rd_training" then -- player loaded savestate
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      menu.open_after_match_start = false
   end

   dummy_control.reset()

   advanced_control.clear_all()

   emu.speedmode("normal")

   training.unfreeze_game()

   for key, com in ipairs(after_load_state_callback) do
      local delay = com.delay or 0
      Queue_Command(gamestate.frame_number + 1 + delay, com.command, com.args)
      after_load_state_callback[key] = nil
   end

   Load_State_Caller = ""
end

local function before_frame()
   local previous_p2_char_str = gamestate.P2.char_str or ""
   local previous_dummy_char_str = training.dummy.char_str or ""
   gamestate.gamestate_read()

   run_commands()

   if debug_settings.developer_mode then debug.run_debug() end

   if menu.is_initialized then
      -- load recordings according to gamestate.P2 character
      if previous_p2_char_str ~= gamestate.P2.char_str then recording.restore_recordings(training.dummy.char_str) end
      -- update character specific settings on training.dummy change
      if previous_dummy_char_str ~= training.dummy.char_str then menu.update_menu_items() end
   end

   training.update_training_state()

   inputs.input = joypad.get()
   if gamestate.is_in_match and not menu.is_open and training.swap_characters then inputs.swap_inputs() end
   inputs.update_input()
   joypad.set(inputs.input)

   if gamestate.is_in_character_select then character_select.update_character_select(inputs.input) end
   if settings.training.fast_forward_intro then training.update_fast_forward() end

   local gesture = inputs.interpret_gesture(gamestate.P1)

   if gamestate.is_in_character_select then
      if gamestate.P1.input.pressed.start then
         character_select.start_select_random_character()
      elseif gamestate.P1.input.released.start then
         character_select.stop_select_random_character()
      end
      if gamestate.P1.input.down.start then character_select.select_random_character() end
   end

   if loading.frame_data_loaded and gamestate.is_in_match and not debug_settings.recording_framedata then
      attack_data.update(training.player, training.dummy)

      frame_advantage.frame_advantage_update(training.player, training.dummy)

      prediction.update_before(inputs.input, training.player, training.dummy)

      if not training.disable_dummy[training.dummy.id] and not menu.is_open or jumpins.is_active then
         dummy_control.update_blocking(inputs.input, training.player, training.dummy, settings.training.blocking_mode,
                                       settings.training.blocking_style, settings.training.red_parry_hit_count,
                                       settings.training.parry_every_n_count)

         dummy_control.update_pose(inputs.input, training.player, training.dummy, settings.training.pose)

         dummy_control.update_mash_inputs(inputs.input, training.player, training.dummy,
                                          settings.training.mash_inputs_mode)

         dummy_control.update_fast_wake_up(inputs.input, training.player, training.dummy,
                                           settings.training.fast_wakeup_mode)

         dummy_control.update_tech_throws(inputs.input, training.player, training.dummy,
                                          settings.training.tech_throws_mode)

         dummy_control.update_counter_attack(inputs.input, training.player, training.dummy,
                                             training.counter_attack_data,
                                             settings.training.hits_before_counter_attack_count)

         hud.update_blocking_direction(inputs.input, training.player, training.dummy)
      end

      local is_special_training_active = false
      for _, mode in ipairs(special_training_modes) do
         mode.update()
         mode.process_gesture(gesture)
         if mode.is_active then is_special_training_active = true end
      end

      if not is_special_training_active then recording.process_gesture(gesture) end

      advanced_control.update(inputs.input, training.player, training.dummy)

      if not menu.is_open or jumpins.is_active then recording.update_recording(inputs.input, training.player, training.dummy) end
   end

   if not menu.is_open or jumpins.is_active then
      inputs.process_pending_input_sequence(gamestate.P1, inputs.input)
      inputs.process_pending_input_sequence(gamestate.P2, inputs.input)
   end

   if gamestate.is_in_match or jumpins.is_active then
      input_history.input_history_update(gamestate.P1, inputs.input)
      input_history.input_history_update(gamestate.P2, inputs.input)
   else
      input_history.clear_input_history()
   end

   inputs.previous_input = inputs.input

   if not (gamestate.is_in_match and is_in_challenge) then joypad.set(inputs.input) end

   if loading.frame_data_loaded and gamestate.is_in_match and not debug_settings.recording_framedata then
      prediction.update_after(inputs.input, training.player, training.dummy)
   end

   if menu.is_initialized and gamestate.has_match_just_started then
      if menu.open_after_match_start then menu.open_menu() end
      menu.update_menu_items()
      hud.reset_hud()
   end

   if debug_settings.recording_framedata then
      require("src.modules.record_framedata").update_framedata_recording(gamestate.P1, gamestate.projectiles)
   end

   debug.log_update(gamestate.P1)
end

local function on_gui()
   -- loading done here to decouple it from game execution
   if not loading.text_images_loaded or not loading.frame_data_loaded then
      local number_loaded = loading.load_all()
      loading_bar_loaded = loading_bar_loaded + number_loaded
   end
   if loading.text_images_loaded and not menu.is_initialized then menu.create_menu() end

   if gamestate.is_in_character_select then draw.draw_character_select() end

   if not loading.text_images_loaded or not loading.frame_data_loaded then
      draw.loading_bar_display(loading_bar_loaded, loading_bar_total)
   end

   if loading.text_images_loaded then
      if gamestate.is_in_match and not disable_display then
         -- input history
         input_history.input_history_display(settings.training.display_input_history,
                                             draw.controller_styles[settings.training.controller_style])
         -- controllers
         if settings.training.display_input then
            local p1 = input_history.make_input_history_entry("P1", inputs.input)
            local p2 = input_history.make_input_history_entry("P2", inputs.input)
            draw.draw_controller_big(p1, 44, 34, draw.controller_styles[settings.training.controller_style])
            draw.draw_controller_big(p2, 310, 34, draw.controller_styles[settings.training.controller_style])
         end

         if debug_settings.log_enabled then debug.log_draw() end

         hud.draw_hud(training.player, training.dummy)

         if settings.training.display_frame_advantage then frame_advantage.frame_advantage_display() end
      end
      if debug_settings.developer_mode then debug.draw_debug() end

      menu.update()

      gui.box(0, 0, 0, 0, 0, 0) -- if we don't draw something, what we drawed from last frame won't be cleared
   end
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)
