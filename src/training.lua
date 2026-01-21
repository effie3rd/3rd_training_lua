-- manages training mode state. who is the player/dummy, gauges, dummy response settings
local fd = require("src.data.framedata")
local gamestate = require("src.gamestate")
local settings = require("src.settings")
local write_memory = require("src.control.write_memory")
local utils = require("src.data.utils")
local tools = require("src.tools")
local dummy_control, modes, recording, character_select

local character_specific = fd.character_specific

local training_player = gamestate.P1
local training_dummy = gamestate.P2
local recordings_player = gamestate.P2

local PLAYER_CONTROLLER = {name = "player"}
local P1_controller = PLAYER_CONTROLLER
local P2_controller

local controllers
local VALID_CONTROL_SCHEMES_DEFAULT = {{"player", "dummy_control"}, {"dummy_control", "player"}}
local valid_control_schemes = VALID_CONTROL_SCHEMES_DEFAULT

local should_freeze_game = false

local disable_dummy = {false, false}

local counter_attack_data

local life_recovery_rate_default = 4
local stun_recovery_rate_default = 1.5
local meter_recovery_rate_default = 4

local max_life = 160

local gauge_state

local function init()
   dummy_control = require("src.control.dummy_control")
   modes = require("src.modes")
   recording = require("src.control.recording")
   character_select = require("src.control.character_select")
   controllers = {player = PLAYER_CONTROLLER, dummy_control = dummy_control}
   for _, mode in ipairs(modes.modes) do controllers[mode.name] = mode end
   P2_controller = dummy_control
end

local function reset_gauge_state()
   gauge_state = {
      {
         should_refill_life = false,
         life_refill_start_frame = 0,
         should_refill_meter = false,
         meter_refill_start_frame = 0,
         expected_meter = 0,
         should_refill_stun = false,
         stun_refill_start_frame = 0,
         start_stun = 0
      }, {
         should_refill_life = false,
         life_refill_start_frame = 0,
         should_refill_meter = false,
         meter_refill_start_frame = 0,
         expected_meter = 0,
         should_refill_stun = false,
         stun_refill_start_frame = 0,
         start_stun = 0
      }
   }
end

local function update_gauges(player)
   if not (gamestate.is_before_curtain or gamestate.is_in_match) or should_freeze_game then return end
   -- infinite
   if settings.training.life_mode == 5 then
      memory.writebyte(player.addresses.life, max_life)
      -- not off 
   elseif settings.training.life_mode > 1 then
      local id = player.id
      local life = player.life
      local wanted_life = max_life
      if settings.training.life_mode == 2 then
         if id == 1 then
            wanted_life = settings.training.p1_life_reset_value
         elseif id == 2 then
            wanted_life = settings.training.p2_life_reset_value
         end
      elseif settings.training.life_mode == 3 then
         wanted_life = 0
      elseif settings.training.life_mode == 4 then
         wanted_life = max_life
      end

      if (player.idle_time == 1 and not gauge_state[id].should_refill_life) or player.has_just_been_hit or
          player.is_being_thrown or player.is_stunned or player.has_just_hit_ground then
         gauge_state[id].life_refill_start_frame = gamestate.frame_number
         gauge_state[id].should_refill_life = false
      end

      if gamestate.frame_number - gauge_state[id].life_refill_start_frame >= settings.training.life_reset_delay and
          (player.is_idle or (player.remaining_wakeup_time > 0 and player.remaining_wakeup_time <= 20)) and life ~=
          wanted_life then gauge_state[id].should_refill_life = true end

      if gauge_state[id].should_refill_life then
         if life > wanted_life then
            life = life - life_recovery_rate_default
            life = math.max(life, wanted_life)
         elseif life < wanted_life then
            life = life + life_recovery_rate_default
            life = math.min(life, wanted_life)
         end
         life = math.min(life, max_life)
         memory.writebyte(player.addresses.life, life)
         if player.life == life then gauge_state[id].should_refill_life = false end
         player.life = life
      end
   end

   -- METER
   if not player.is_in_timed_sa then
      -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max. We have to make special cases for it
      local is_timed_sa = character_specific[player.char_str].timed_sa[player.selected_sa]
      if settings.training.meter_mode == 5 then
         local meter_count = memory.readbyte(player.addresses.meter_master)
         local meter_count_slave = memory.readbyte(player.addresses.meter)
         if meter_count ~= player.max_meter_count and meter_count_slave ~= player.max_meter_count then
            local gauge_value = 0
            if is_timed_sa then gauge_value = player.max_meter_gauge end
            memory.writebyte(player.addresses.gauge, gauge_value)
            memory.writebyte(player.addresses.meter_master, player.max_meter_count)
            memory.writebyte(player.addresses.meter_update_flag, 0x01)
         end
      elseif settings.training.meter_mode > 1 then
         local id = player.id
         local wanted_meter = 0
         if settings.training.meter_mode == 2 then
            if id == 1 then
               wanted_meter = settings.training.p1_meter_reset_value
            elseif id == 2 then
               wanted_meter = settings.training.p2_meter_reset_value
            end
         elseif settings.training.meter_mode == 3 then
            wanted_meter = 0
         elseif settings.training.meter_mode == 4 then
            wanted_meter = player.max_meter_gauge * player.max_meter_count
         end
         local meter_count = memory.readbyte(player.addresses.meter_master)
         local meter_count_slave = memory.readbyte(player.addresses.meter)

         local gauge = memory.readbyte(player.addresses.gauge)

         local meter = 0
         -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max
         if is_timed_sa then
            meter = gauge
         else
            meter = gauge + player.max_meter_gauge * meter_count
         end

         if meter > wanted_meter then
            meter = meter - meter_recovery_rate_default
            meter = math.max(meter, wanted_meter)
         elseif meter < wanted_meter then
            meter = meter + meter_recovery_rate_default
            meter = math.min(meter, wanted_meter)
         end

         local wanted_gauge = meter % player.max_meter_gauge
         local wanted_meter_count = math.floor(meter / player.max_meter_gauge)

         if character_specific[player.char_str].timed_sa[player.selected_sa] and wanted_meter_count == 1 and
             wanted_gauge == 0 then wanted_gauge = player.max_meter_gauge end

         if gauge ~= gauge_state[id].expected_meter or player.is_attacking or player.other.is_being_thrown then
            gauge_state[id].meter_refill_start_frame = gamestate.frame_number
            gauge_state[id].should_refill_meter = false
         end
         if gamestate.frame_number - gauge_state[id].meter_refill_start_frame >= settings.training.meter_reset_delay and
             (gauge ~= wanted_gauge or meter_count ~= wanted_meter_count) then
            gauge_state[id].should_refill_meter = true
         end
         -- there is a bug where if you open the menu during super flash, the gauges get messed up

         if gauge_state[id].should_refill_meter and meter_count == meter_count_slave then
            if wanted_gauge ~= gauge then
               memory.writebyte(player.addresses.gauge, wanted_gauge)
               gauge_state[id].expected_meter = wanted_gauge
            end
            if meter_count ~= wanted_meter_count then
               memory.writebyte(player.addresses.meter_master, wanted_meter_count)
               memory.writebyte(player.addresses.meter_update_flag, 0x01)
            end
            if wanted_gauge == gauge then gauge_state[id].should_meter_life = false end
         else
            gauge_state[id].expected_meter = gauge
         end
      end
   end

   if settings.training.infinite_sa_time and player.is_in_timed_sa then
      memory.writebyte(player.addresses.gauge, player.max_meter_gauge)
   end

   -- STUN
   -- always 0
   if settings.training.stun_mode == 5 then
      memory.writebyte(player.addresses.stun_bar_char, 0)
      memory.writebyte(player.addresses.stun_bar_mantissa, 0)
      memory.writebyte(player.addresses.stun_bar_decrease_timer, 0)
      -- always max
   elseif settings.training.stun_mode == 6 then
      memory.writebyte(player.addresses.stun_bar_char, player.stun_bar_max)
      memory.writebyte(player.addresses.stun_bar_mantissa, 0xFF)
      memory.writebyte(player.addresses.stun_bar_decrease_timer, 0)
      -- not off 
   elseif settings.training.stun_mode > 1 then
      local id = player.id
      local stun = player.stun_bar
      local wanted_stun = 0
      local stun_recovery_rate = stun_recovery_rate_default
      if settings.training.stun_mode == 2 then
         if id == 1 then
            wanted_stun = settings.training.p1_stun_reset_value
         elseif id == 2 then
            wanted_stun = settings.training.p2_stun_reset_value
         end
      elseif settings.training.stun_mode == 3 then
         wanted_stun = 0
      elseif settings.training.stun_mode == 4 then
         wanted_stun = player.stun_bar_max
      end

      local diff = math.abs(wanted_stun - gauge_state[id].start_stun)
      if diff >= player.stun_bar_max * .5 then stun_recovery_rate = stun_recovery_rate_default * 2 end
      if diff >= player.stun_bar_max * .7 then stun_recovery_rate = stun_recovery_rate_default * 3 end
      if diff >= player.stun_bar_max * .9 then stun_recovery_rate = stun_recovery_rate_default * 6 end

      if player.stun_just_ended then
         gauge_state[id].start_stun = 0
         gauge_state[id].stun_refill_start_frame = 0
         gauge_state[id].should_refill_stun = true
      end
      if (player.idle_time == 1 and not gauge_state[id].should_refill_stun) or player.has_just_been_hit or
          player.is_being_thrown or player.is_stunned or player.has_just_hit_ground then
         gauge_state[id].start_stun = stun
         gauge_state[id].stun_refill_start_frame = gamestate.frame_number
         gauge_state[id].should_refill_stun = false
      end

      if gamestate.frame_number - gauge_state[id].stun_refill_start_frame >= settings.training.stun_reset_delay and
          (player.is_idle or (player.remaining_wakeup_time > 0 and player.remaining_wakeup_time <= 20)) and stun ~=
          wanted_stun then gauge_state[id].should_refill_stun = true end

      if gauge_state[id].should_refill_stun then
         if stun > wanted_stun then
            stun = stun - stun_recovery_rate
            stun = math.max(stun, wanted_stun)
         elseif stun < wanted_stun then
            stun = stun + stun_recovery_rate
            stun = math.min(stun, wanted_stun)
         end
         local stun_mantissa = tools.float_to_byte(stun)
         if stun == wanted_stun then stun_mantissa = 0xFF end
         if stun == player.stun_bar_max then
            stun = player.stun_bar_max - 1
            stun_mantissa = 0xFF
         end
         if player.stun_bar ~= wanted_stun then
            memory.writebyte(player.addresses.stun_bar_char, math.floor(stun))
            memory.writebyte(player.addresses.stun_bar_mantissa, stun_mantissa)
         end
      end
      memory.writebyte(player.addresses.stun_bar_decrease_timer, 0)
   end
end

local function update_cheats()
   if settings.training.universal_cancel then
      memory.writebyte(gamestate.P1.addresses.universal_cancel, 0x6F)
      memory.writebyte(gamestate.P2.addresses.universal_cancel, 0x6F)
   end
   if settings.training.infinite_projectiles then
      memory.writebyte(gamestate.P1.addresses.infinite_projectiles, 0xFF)
      memory.writebyte(gamestate.P2.addresses.infinite_projectiles, 0xFF)
   end
   if settings.training.infinite_juggle then
      memory.writebyte(gamestate.P1.addresses.juggle_count, 0x0)
      memory.writebyte(gamestate.P1.addresses.infinite_juggle, 0x0)
      memory.writebyte(gamestate.P2.addresses.juggle_count, 0x0)
      memory.writebyte(gamestate.P2.addresses.infinite_juggle, 0x0)
   end

   if settings.training.auto_parrying == 2 or settings.training.auto_parrying == 4 then
      write_memory.max_parry_validity(gamestate.P1)
   end
   if settings.training.auto_parrying == 3 or settings.training.auto_parrying == 4 then
      write_memory.max_parry_validity(gamestate.P2)
   end
end

local function update_counter_attack_data(player)
   counter_attack_data =
       utils.create_move_data_from_selection(settings.training.counter_attack[player.char_str], player)
end

local function update_players()
   if P1_controller == PLAYER_CONTROLLER then
      training_player = gamestate.P1
   elseif P2_controller == PLAYER_CONTROLLER then
      training_player = gamestate.P2
   else
      training_player = nil
   end

   if P1_controller == dummy_control then
      training_dummy = gamestate.P1
   elseif P2_controller == dummy_control then
      training_dummy = gamestate.P2
   elseif tools.table_contains(modes.modes, P1_controller) then
      training_dummy = gamestate.P1
   elseif tools.table_contains(modes.modes, P2_controller) then
      training_dummy = gamestate.P2
   else
      training_dummy = gamestate.P2
   end

   local recording_state = recording.current_recording_state
   if recording_state == recording.RECORDING_STATE.STOPPED then
      recordings_player = training_dummy
   elseif recording_state == recording.RECORDING_STATE.WAIT_FOR_RECORDING then
      recordings_player = training_player
   elseif recording_state == recording.RECORDING_STATE.RECORDING then
      recordings_player = training_player
   elseif recording_state == recording.RECORDING_STATE.QUEUE_REPLAY then
      recordings_player = training_dummy
   elseif recording_state == recording.RECORDING_STATE.POSITIONING then
      recordings_player = training_dummy
   elseif recording_state == recording.RECORDING_STATE.REPLAYING then
      recordings_player = training_dummy
   else
      recordings_player = training_dummy
   end
   if not training_player then training_player = training_dummy.other end
   update_counter_attack_data(training_dummy)
end

local function reset_controls()
   P1_controller = PLAYER_CONTROLLER
   P2_controller = dummy_control
   update_players()
end

local function swap_controls()
   P1_controller, P2_controller = P2_controller, P1_controller
   update_players()
end

local function control_names_equal(control_names_1, control_names_2)
   if control_names_1[1] == control_names_2[1] and control_names_1[2] == control_names_2[2] then return true end
   return false
end

local function index_of_control_scheme(control_schemes, compare_scheme)
   for i, control_scheme in ipairs(control_schemes) do
      if control_names_equal(control_scheme, compare_scheme) then return i end
   end
end

local function get_controller(player_id)
   if player_id == 1 then return P1_controller end
   return P2_controller
end

local function set_controllers_by_name(P1_controller_name, P2_controller_name)
   P1_controller = controllers[P1_controller_name]
   P2_controller = controllers[P2_controller_name]
   update_players()
end

local function toggle_controls()
   if modes.active_mode then
      valid_control_schemes = modes.active_mode.get_valid_control_schemes()
   else
      valid_control_schemes = VALID_CONTROL_SCHEMES_DEFAULT
   end
   local index = index_of_control_scheme(valid_control_schemes, {P1_controller.name, P2_controller.name})
   local control_scheme
   if index then
      control_scheme = valid_control_schemes[tools.wrap_index(index + 1, #valid_control_schemes)]
   else
      control_scheme = valid_control_schemes[1]
   end
   set_controllers_by_name(control_scheme[1], control_scheme[2])
   update_players()
end

local function set_module_control_by_name(module_name, other_module_name)
   local active_mode = modes.active_mode
   local target_controller = 0
   if active_mode then
      if P1_controller == active_mode then
         P1_controller = controllers[module_name]
         target_controller = 1
      elseif P2_controller == active_mode then
         P2_controller = controllers[module_name]
         target_controller = 2
      end
   end
   if target_controller == 0 then
      if P1_controller == PLAYER_CONTROLLER then
         P2_controller = controllers[module_name]
         target_controller = 2
      else
         P1_controller = controllers[module_name]
         target_controller = 1
      end
   end
   if other_module_name then
      if target_controller == 1 then
         P2_controller = controllers[other_module_name]
      else
         P1_controller = controllers[other_module_name]
      end
   end

   update_players()
end

local function get_controlled_player_by_name(controller_name)
   if P1_controller.name == controller_name then return gamestate.P1 end
   if P2_controller.name == controller_name then return gamestate.P2 end
   return nil
end

local function get_player_controlled_by_active_mode()
   local active_mode = modes.active_mode
   if active_mode then
      if P1_controller == active_mode then return gamestate.P1 end
      if P2_controller == active_mode then return gamestate.P2 end
   end
   return nil
end

local function check_controller_validity()
   if not modes.active_mode then
      if tools.table_contains(modes.modes, P1_controller) then
         P1_controller = PLAYER_CONTROLLER
      elseif tools.table_contains(modes.modes, P2_controller) then
         P2_controller = PLAYER_CONTROLLER
      end
   end
end

local function update_fast_forward()
   if gamestate.has_match_just_started then
      emu.speedmode("normal")
   elseif gamestate.is_in_character_select then
      if character_select.is_selection_complete() then
         emu.speedmode("turbo")
      else
         emu.speedmode("normal")
      end
   elseif gamestate.has_match_just_ended then
      emu.speedmode("turbo")
   end
end
local function freeze_game() should_freeze_game = true end
local function unfreeze_game() should_freeze_game = false end

local function update_game_settings()
   write_memory.set_freeze_game(should_freeze_game)

   write_memory.set_infinite_time(settings.training.infinite_time)

   write_memory.set_music_volume(settings.training.music_volume)
end

local function update_training_state()
   update_game_settings()

   update_gauges(gamestate.P1)
   update_gauges(gamestate.P2)

   update_cheats()
end

reset_gauge_state()

local training = {
   init = init,
   PLAYER_CONTROLLER = PLAYER_CONTROLLER,
   controllers = controllers,
   update_training_state = update_training_state,
   reset_gauge_state = reset_gauge_state,
   reset_controls = reset_controls,
   swap_controls = swap_controls,
   update_players = update_players,
   toggle_controls = toggle_controls,
   get_controller = get_controller,
   set_controllers_by_name = set_controllers_by_name,
   set_module_control_by_name = set_module_control_by_name,
   get_controlled_player_by_name = get_controlled_player_by_name,
   get_player_controlled_by_active_mode = get_player_controlled_by_active_mode,
   update_fast_forward = update_fast_forward,
   freeze_game = freeze_game,
   unfreeze_game = unfreeze_game
}

setmetatable(training, {
   __index = function(_, key)
      if key == "player" then
         return training_player
      elseif key == "dummy" then
         return training_dummy
      elseif key == "recordings_player" then
         return recordings_player
      elseif key == "P1_controller" then
         return P1_controller
      elseif key == "P2_controller" then
         return P2_controller
      elseif key == "disable_dummy" then
         return disable_dummy
      elseif key == "counter_attack_data" then
         return counter_attack_data
      elseif key == "should_freeze_game" then
         return should_freeze_game
      end
   end,

   __newindex = function(_, key, value)
      if key == "player" then
         training_player = value
      elseif key == "dummy" then
         training_dummy = value
      elseif key == "disable_dummy" then
         disable_dummy = value
      elseif key == "counter_attack_data" then
         counter_attack_data = value
      else
         rawset(training, key, value)
      end
   end
})

return training
