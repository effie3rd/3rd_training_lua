local game_data = require("src.data.game_data")
print("-----------------------------")
print("  effie's 3rd_training.lua - " .. game_data.script_version .. "")
print("  Training mode for " .. game_data.game_name .. "")
print("  Project: https://github.com/effie3rd/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Enter training menu by pressing \"Start\" while in game")
print("- Enter/exit recording mode by double tapping \"Coin\"")
print("- In recording mode, press \"Coin\" again to start/stop recording")
print("- In normal mode, press \"Coin\" to start/stop replay")
print("- Lua Hotkey 1 (alt+1) to return to character select screen")
print()

-- Thanks to *Grouflon* for making an amazing training mode

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

local settings = require("src.settings")
local debug_settings = require("src.debug_settings")
local recording = require("src.control.recording")
local gamestate = require("src.gamestate")
local loading = require("src.loading")
local framedata = require("src.data.framedata")
local image_tables = require("src.ui.image_tables")
local training = require("src.training")
local prediction = require("src.data.prediction")
local advanced_control = require("src.control.advanced_control")
local dummy_control = require("src.control.dummy_control")
local modules = require("src.modules")
local modes = require("src.modes")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local hud = require("src.ui.hud")
local inputs = require("src.control.inputs")
local input_history = require("src.ui.input_history")
local menu = require("src.ui.menu")
local attack_data = require("src.data.attack_data")
local frame_advantage = require("src.data.frame_advantage")
local character_select = require("src.control.character_select")
local managers = require("src.control.managers")
local debug = require("src.debug")

local disable_display = false

local command_queue = {}
local load_state_command_queue = {}
local load_state_callbacks = {}

local load_framedata_request, load_text_request, load_images_request
local loading_bar_loaded, loading_bar_total = 0, 0

Load_State_Caller = ""

local function is_default_hotkey(n)
   local keys = input.get()
   if (keys["alt"] and keys[tostring(n)]) then return true end
end

local key_bindings
local max_hotkeys = 9
local function register_hotkeys()
   for i = 1, max_hotkeys do
      input.registerhotkey(i, function()
         if is_default_hotkey(i) then return end
         key_bindings.use_hotkey(i)
      end)
   end
end

function Call_After_Load_State(command, args, delay)
   load_state_command_queue[#load_state_command_queue + 1] = {command = command, args = args, delay = delay}
end

function Register_Load_State_Callback(func) load_state_callbacks[func] = func end

function Unregister_Load_State_Callback(func) load_state_callbacks[func] = nil end

function Queue_Command(frame, command, args)
   if not command_queue[frame] then command_queue[frame] = {} end
   command_queue[frame][#command_queue[frame] + 1] = {command = command, args = args}
end

local function run_commands()
   local used_keys = {}
   for key, commands in pairs(command_queue) do
      if key == gamestate.frame_number then
         for _, com in pairs(commands) do
            if com.args then
               com.command(unpack(com.args))
            else
               com.command()
            end
            used_keys[#used_keys + 1] = key
         end
      elseif key < gamestate.frame_number then
         used_keys[#used_keys + 1] = key
      end
   end
   for _, key in ipairs(used_keys) do command_queue[key] = nil end
end

local function on_start()
   emu.speedmode("normal")

   math.randomseed(os.time())

   recording.init()
   managers.init()
   modules.init()
   modes.init()
   training.init()
   colors.init()
   key_bindings = modules.get_module("key_bindings")
   register_hotkeys()

   -- load character select text first so they it be displayed at run time
   loading.load_binary(image_tables.text, settings.data_path .. settings.load_first_bin_file)

   load_text_request = loading.queue_load(loading.DATA_TYPES.IMAGES, settings.data_path .. settings.text_bin_file)
   load_images_request = loading.queue_load(loading.DATA_TYPES.IMAGES, settings.data_path .. settings.images_bin_file)
   load_framedata_request = loading.queue_load(loading.DATA_TYPES.FRAMEDATA,
                                               settings.framedata_path .. settings.framedata_bin_file)
   loading_bar_total = loading.get_total_file_size()

   character_select.start_character_select_sequence()
end

local function on_load_state()
   gamestate.reset_player_objects()
   gamestate.gamestate_read()

   attack_data.reset()
   frame_advantage.reset()

   training.update_players()
   training.update_training_state()
   training.reset_gauge_state()

   recording.restore_recordings()
   recording.reset_recording_state()

   if menu.is_initialized then
      menu.update_menu_items()
      menu.reset_background_cache()
   end

   hud.reset_hud()

   input_history.clear_input_history()

   if modes.active_mode and not (Load_State_Caller == modes.active_mode.name) then modes.stop() end

   if Load_State_Caller == "" or Load_State_Caller == "3rd_training" then -- player loaded savestate
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      training.disable_dummy[1] = false
      training.disable_dummy[2] = false
      menu.open_after_match_start = false
   end

   dummy_control.reset()

   advanced_control.clear_all()

   emu.speedmode("normal")

   training.unfreeze_game()

   local used_keys = {}
   for key, com in ipairs(load_state_command_queue) do
      local delay = com.delay or 0
      Queue_Command(gamestate.frame_number + 1 + delay, com.command, com.args)
      used_keys[#used_keys + 1] = key
   end
   for _, key in ipairs(used_keys) do load_state_command_queue[key] = nil end
   for _, callback in pairs(load_state_callbacks) do callback() end

   Load_State_Caller = ""
end

local function before_frame()
   gamestate.gamestate_read()

   run_commands()

   if debug_settings.developer_mode then debug.run_debug() end

   training.update_training_state()

   inputs.input = joypad.get()
   if gamestate.is_in_match and not menu.is_open then
      if training.P2_controller == training.PLAYER_CONTROLLER then
         inputs.swap_inputs()
      elseif training.P1_controller ~= training.PLAYER_CONTROLLER then
         inputs.block_input(1, "all")
      end
   end
   inputs.update_input(inputs.input, gamestate.player_objects)
   joypad.set(inputs.input)

   local gesture = inputs.interpret_gesture(gamestate.P1)

   if inputs.keyboard_input["alt"].down then
      if inputs.keyboard_input["1"].press then
         recording.set_recording_state({}, recording.RECORDING_STATE.STOPPED)
         character_select.start_character_select_sequence()
      end
      if inputs.keyboard_input["2"].press then character_select.select_gill() end
      if inputs.keyboard_input["3"].press then character_select.select_shingouki() end
      if debug_settings.developer_mode then
         if inputs.keyboard_input["4"].press then inputs.queue_input_from_json(training.player, "debug.json") end
         if inputs.keyboard_input["5"].press then debug.debug_things3() end
      end
   end

   if gamestate.is_in_character_select or gamestate.is_in_vs_screen then
      character_select.update_character_select(inputs.input)
   end
   if settings.training.fast_forward_intro then training.update_fast_forward() end

   managers.update_before()

   if framedata.is_loaded and gamestate.is_in_match and not debug_settings.recording_framedata then
      attack_data.update(training.player)

      frame_advantage.update()

      prediction.update_before(inputs.previous_input, training.dummy)
      if not training.disable_dummy[training.dummy.id] and (not menu.is_open or menu.allow_update_while_open) then
         local blocking_options = {
            mode = settings.training.blocking_mode,
            style = settings.training.blocking_style,
            red_parry_hit_count = settings.training.red_parry_hit_count,
            parry_every_n_count = settings.training.parry_every_n_count,
            prefer_parry_low = settings.training.prefer_down_parry,
            prefer_block_low = settings.training.pose == 2,
            force_blocking_direction = settings.training.blocking_direction
         }
         dummy_control.update_blocking(inputs.input, training.dummy, blocking_options)

         dummy_control.update_pose(inputs.input, training.dummy, settings.training.pose)

         dummy_control.update_mash_inputs(inputs.input, training.dummy, settings.training.mash_inputs_mode)

         dummy_control.update_fast_wake_up(inputs.input, training.dummy, settings.training.fast_wakeup_mode)

         dummy_control.update_tech_throws(inputs.input, training.dummy, settings.training.tech_throws_mode)

         dummy_control.update_counter_attack(inputs.input, training.dummy, training.counter_attack_data,
                                             settings.training.hits_before_counter_attack_count)
      end

      hud.update_hud(training.player, training.dummy, inputs.input)

      modules.update()
      if modes.active_mode then
         modes.active_mode.process_gesture(gesture)
      else
         recording.process_gesture(gesture)
      end

      advanced_control.update()

      if not menu.is_open or menu.allow_update_while_open then
         recording.update_recording(inputs.input, training.player)
      end
   end

   if not menu.is_open or menu.allow_update_while_open then
      inputs.process_pending_input_sequence(gamestate.P1, inputs.input)
      inputs.process_pending_input_sequence(gamestate.P2, inputs.input)
   end

   if gamestate.is_in_match or menu.allow_update_while_open then
      input_history.input_history_update(gamestate.P1, inputs.input)
      input_history.input_history_update(gamestate.P2, inputs.input)
   else
      input_history.clear_input_history()
   end

   if debug_settings.recording_framedata then
      require("src.data.record_framedata").update_framedata_recording(gamestate.P1, gamestate.projectiles)
   end

   inputs.update_input_info(inputs.input, gamestate.player_objects)
   inputs.previous_input = inputs.input

   joypad.set(inputs.input)

   if framedata.is_loaded and gamestate.is_in_match and not debug_settings.recording_framedata then
      prediction.update_after(inputs.input, training.dummy)
   end

   managers.update_after()

   if menu.is_initialized and gamestate.has_match_just_started then
      if menu.open_after_match_start then menu.open_menu() end
      menu.update_menu_items()
      hud.reset_hud()
   end

   debug.log_update(gamestate.P1)
end

local function on_gui()
   draw.clear_canvases()
   -- loading done here to decouple it from game execution
   if not image_tables.is_loaded or not framedata.is_loaded then
      local number_loaded = loading.load_all()
      loading_bar_loaded = loading_bar_loaded + number_loaded
      draw.loading_bar_display(loading_bar_loaded, loading_bar_total)
      if not image_tables.is_loaded and load_text_request.status == loading.STATUS.LOADED and load_images_request.status ==
          loading.STATUS.LOADED then
         image_tables.is_loaded = true
         for k, v in pairs(image_tables.text) do load_text_request.result[k] = v end
         image_tables.text = load_text_request.result
         image_tables.images = load_images_request.result
         modules.after_images_loaded()
         menu.create_menu()
         modules.after_menu_created()
      end
      if not framedata.is_loaded and load_framedata_request.status == loading.STATUS.LOADED then
         framedata.is_loaded = true
         framedata.frame_data = load_framedata_request.result
         modules.after_framedata_loaded()
      end
   end

   inputs.update_keyboard_input(input.get())

   if gamestate.is_in_character_select then draw.draw_character_select() end

   if image_tables.is_loaded then
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

      end
      if debug_settings.developer_mode then debug.draw_debug() end

      menu.update()

      draw.draw_canvases()
   end

   gui.box(0, 0, 0, 0, 0, 0) -- if we don't draw something, what we drew last frame will not clear
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)
