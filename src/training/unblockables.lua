local gamestate = require "src.gamestate"
local inputs = require("src.control.inputs")
local character_select = require("src.control.character_select")
local hud = require("src.ui.hud")
local settings = require("src.settings")
local frame_data = require("src.modules.framedata")
local game_data = require("src.modules.game_data")
local stage_data = require("src.modules.stage_data")
local unblockables_tables = require("src.training.unblockables_tables")
local mem = require("src.control.write_memory")
local advanced_control = require("src.control.advanced_control")
local write_memory = require("src.control.write_memory")
local memory_addresses = require("src.control.memory_addresses")
local training = require("src.training")

local unblockables
local module_name = "unblockables"

local is_active = false
local states = {SETUP_MATCH_START = 1, INIT = 2, SETUP = 3, WAIT_FOR_SETUP = 4, RUNNING = 5, END = 6, IDLE = 7}
local state = states.INIT

local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/unblockables_match_start.fs")
local followup_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/unblockables_followup.fs")

local player = gamestate.P1
local dummy = gamestate.P2

local setup, followups
local end_frame = 0

local function set_players()
   dummy = training.get_controlled_player_by_name(module_name) --
   or training.get_player_controlled_by_active_mode() --
   or (training.get_controlled_player_by_name("player") and training.get_controlled_player_by_name("player").other) --
   or gamestate.P2
   player = dummy.other
end

local old_settings = {
   life_mode = settings.training.life_mode,
   stun_mode = settings.training.stun_mode,
   meter_mode = settings.training.meter_mode,
   infinite_time = settings.training.infinite_time,
   infinite_sa_time = settings.training.infinite_sa_time
}
local old_controller_settings = {"player", "dummy_control"}

local function save_controller_settings()
   old_controller_settings = {training.P1_controller.name, training.P2_controller.name}
end

local function restore_controller_settings()
   training.set_controllers_by_name(old_controller_settings[1], old_controller_settings[2])
end

local function save_old_settings()
   old_settings = {
      life_mode = settings.training.life_mode,
      stun_mode = settings.training.stun_mode,
      meter_mode = settings.training.meter_mode,
      infinite_time = settings.training.infinite_time,
      infinite_sa_time = settings.training.infinite_sa_time
   }
end

local function ensure_training_settings()
   settings.training.life_mode = 4
   settings.training.stun_mode = 3
   settings.training.meter_mode = 5
   settings.training.infinite_time = true
   training.disable_dummy[player.id] = false
   training.disable_dummy[dummy.id] = true
end

local function restore_training_settings()
   for key, value in pairs(old_settings) do settings.training[key] = value end
   training.disable_dummy = {false, false}
end

local function continue_from_savestate()
   Register_After_Load_State(function()
      if not is_active and gamestate.is_in_match then hud.indicate_player_controllers() end
      require("src.special_modes").set_active_mode(unblockables)
      set_players()
      setup = unblockables_tables.get_setup(settings.special_training.unblockables.savestate_opponent, --
      settings.special_training.unblockables.savestate_player, settings.special_training.unblockables.savestate_setup)

      followups = unblockables_tables.get_followups(settings.special_training.unblockables.match_savestate_opponent,
                                                    settings.special_training.unblockables.match_savestate_player,
                                                    setup.name)

      local setup_index = settings.special_training.unblockables.setup
      local active_followups = {}
      local opponent = settings.special_training.unblockables.match_savestate_opponent
      local char_str = settings.special_training.unblockables.match_savestate_player
      for i, followup in ipairs(followups) do
         if settings.special_training.unblockables.followups[opponent][char_str][setup_index][i] then
            active_followups[#active_followups + 1] = followup
         end
      end
      local followup = active_followups[math.random(1, #active_followups)]
      advanced_control.queue_programmed_movement(dummy, followup.commands(dummy))
      state = states.RUNNING
   end)
   Load_State_Caller = module_name
   savestate.load(followup_state)
end

local function start()
   if not is_active then
      save_controller_settings()
      save_old_settings()
      ensure_training_settings()
      if settings.special_training.unblockables.controllers then
         training.set_controllers_by_name(settings.special_training.unblockables.controllers[1],
                                          settings.special_training.unblockables.controllers[2])
      else
         training.set_module_control_by_name(module_name)
      end
      set_players()
   end
   setup = unblockables_tables.get_setup(settings.special_training.unblockables.match_savestate_opponent,
                                         settings.special_training.unblockables.match_savestate_player,
                                         settings.special_training.unblockables.setup)

   followups = unblockables_tables.get_followups(settings.special_training.unblockables.match_savestate_opponent,
                                                 settings.special_training.unblockables.match_savestate_player,
                                                 setup.name)
   local setup_index = settings.special_training.unblockables.setup
   local opponent = settings.special_training.unblockables.match_savestate_opponent
   local char_str = settings.special_training.unblockables.match_savestate_player
   local followups_settings = settings.special_training.unblockables.followups[opponent][char_str][setup_index]
   local at_least_one_followup = false
   for i, setting in ipairs(followups_settings) do
      if setting then
         at_least_one_followup = true
         break
      end
   end
   if not at_least_one_followup then return end
   advanced_control.clear_all()
   inputs.clear_input_sequence(dummy)
   if settings.special_training.unblockables.savestate_player ==
       settings.special_training.unblockables.match_savestate_player and
       settings.special_training.unblockables.savestate_opponent ==
       settings.special_training.unblockables.match_savestate_opponent and
       settings.special_training.unblockables.savestate_setup == settings.special_training.unblockables.setup then
      continue_from_savestate()
   else
      inputs.block_input(1, "all")
      inputs.block_input(2, "all")
      Register_After_Load_State(function()
         set_players()
         if not is_active and gamestate.is_in_match then hud.indicate_player_controllers() end
         require("src.special_modes").set_active_mode(unblockables)
      end)
      state = states.SETUP
      Load_State_Caller = module_name
      savestate.load(match_start_state)
   end
end

local function start_character_select()
   require("src.special_modes").set_active_mode(unblockables)
   state = states.SETUP_MATCH_START
   training.set_module_control_by_name(module_name)
   ensure_training_settings()
   local char_str = unblockables_tables.available_opponents[settings.special_training.unblockables.opponent]
   local sa = 3
   if char_str == "oro" then sa = 2 end
   Register_After_Load_State(set_players)
   Register_After_Load_State(character_select.force_select_character, {dummy.id, char_str, sa, "random"})
   character_select.start_character_select_sequence()
end

local function check_for_new_setup()
   if not is_active then return end
   local opponent_name = unblockables_tables.available_opponents[settings.special_training.unblockables.opponent]
   if opponent_name == settings.special_training.unblockables.match_savestate_opponent and
       settings.special_training.unblockables.setup ~= settings.special_training.unblockables.savestate_setup then
      start()
   end
end

local function stop()
   if is_active then
      require("src.special_modes").stop_mode(unblockables)
      restore_controller_settings()
      restore_training_settings()
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      advanced_control.clear_all()
      hud.clear_notification_text()
      if gamestate.is_in_match then hud.indicate_player_controllers() end
   end
end

local function reset() require("src.special_modes").stop_mode(unblockables) end

local function update()
   if is_active then
      if gamestate.is_in_match then
         inputs.block_input(dummy.id, "all")
         if state == states.SETUP_MATCH_START or state == states.SETUP or state == states.WAIT_FOR_SETUP then
            inputs.block_input(1, "all")
            inputs.block_input(2, "all")
         end
         if state == states.SETUP or state == states.WAIT_FOR_SETUP then
            hud.add_notification_text("hud_please_wait", 0, 42, "center_horizontal")
            hud.add_notification_text("hud_coin_restart_hold_start_stop", 0, 208, "center_horizontal")
         end
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
            savestate.save(match_start_state)
            settings.special_training.unblockables.controllers = {
               training.P1_controller.name, training.P2_controller.name
            }
            settings.special_training.unblockables.match_savestate_opponent = dummy.char_str
            settings.special_training.unblockables.match_savestate_player = player.char_str
            settings.special_training.unblockables.savestate_setup = -1
            settings.special_training.unblockables.savestate_player = ""
            settings.special_training.unblockables.savestate_opponent = ""
            state = states.IDLE
         elseif state == states.SETUP then
            set_players()
            training.disable_dummy = {true, true}
            settings.special_training.unblockables.savestate_setup = -1
            settings.special_training.unblockables.savestate_player = ""
            settings.special_training.unblockables.savestate_opponent = ""
            setup = unblockables_tables.get_setup(settings.special_training.unblockables.match_savestate_opponent,
                                                  settings.special_training.unblockables.match_savestate_player,
                                                  settings.special_training.unblockables.setup)

            local player_offset = (frame_data.character_specific[player.char_str].pushbox_width +
                                      frame_data.character_specific[dummy.char_str].pushbox_width) / 2 + 6
            local stage_left = stage_data.stages[gamestate.stage].left
            local stage_right = stage_data.stages[gamestate.stage].right
            local dummy_reset_x = stage_left + setup.reset_offset_x
            local player_reset_x = dummy_reset_x - player_offset
            if dummy.id == 1 then
               dummy_reset_x = stage_right - setup.reset_offset_x
               player_reset_x = dummy_reset_x + player_offset
            end

            if player.pos_x ~= player_reset_x or dummy.pos_x ~= dummy_reset_x then
               mem.write_pos_x(player, player_reset_x)
               mem.write_pos_x(dummy, dummy_reset_x)
            end

            local current_screen_x = memory.readword(memory_addresses.global.screen_pos_x)
            local desired_screen_x, desired_screen_y = write_memory.get_fix_screen_pos(player, dummy, gamestate.stage)

            if current_screen_x ~= desired_screen_x then
               write_memory.set_screen_pos(desired_screen_x, desired_screen_y)
            elseif player.pos_x == player_reset_x and dummy.pos_x == dummy_reset_x then
               advanced_control.queue_programmed_movement(dummy, setup.commands(dummy))
               state = states.WAIT_FOR_SETUP
            end
         elseif state == states.WAIT_FOR_SETUP then
            training.disable_dummy[dummy.id] = true
            if advanced_control.all_commands_queued(dummy) and not inputs.is_playing_input_sequence(dummy) then
               Queue_Command(gamestate.frame_number + 1, function()
                  savestate.save(followup_state)
                  settings.special_training.unblockables.savestate_setup = settings.special_training.unblockables.setup
                  settings.special_training.unblockables.savestate_opponent = dummy.char_str
                  settings.special_training.unblockables.savestate_player = player.char_str
                  inputs.unblock_input(1)
                  inputs.unblock_input(2)
                  continue_from_savestate()
               end)
               state = states.RUNNING
            end
         elseif state == states.RUNNING then
            training.disable_dummy[player.id] = false
            training.disable_dummy[dummy.id] = true
            if advanced_control.all_commands_queued(dummy) and not inputs.is_playing_input_sequence(dummy) then
               if player.is_airborne or player.has_just_hit_ground or dummy.has_just_hit_ground then
                  state = states.END
                  end_frame = gamestate.frame_number
               end
            end
         elseif state == states.END then
            training.disable_dummy[dummy.id] = false
         end
      end
   end
end

local function process_gesture(gesture) if is_active then if gesture == "single_tap" then start() end end end

local function get_valid_control_schemes()
   if dummy.id == 2 then
      return {{"player", module_name}, {"dummy_control", module_name}}
   else
      return {{module_name, "player"}, {module_name, "dummy_control"}}
   end
end

unblockables = {
   name = module_name,
   start_character_select = start_character_select,
   check_for_new_setup = check_for_new_setup,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture,
   get_valid_control_schemes = get_valid_control_schemes,
   set_players = set_players
}

setmetatable(unblockables, {
   __index = function(_, key)
      if key == "is_active" then
         return is_active
      elseif key == "player" then
         return player
      elseif key == "dummy" then
         return dummy
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      else
         rawset(unblockables, key, value)
      end
   end
})

return unblockables
