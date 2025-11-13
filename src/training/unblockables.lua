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

local module_name = "unblockables"

local is_active = false
local states = {SETUP_MATCH_START = 1, INIT = 2, SETUP = 3, WAIT_FOR_SETUP = 4, RUNNING = 5, END = 6}
local state = states.INIT

local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/unblockables_match_start.fs")
local followup_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/unblockables_followup.fs")

local unblockable_data

local player = gamestate.P1
local dummy = gamestate.P2

local end_delay = 20
local end_frame = 0

local old_settings = {
   life_mode = settings.training.life_mode,
   stun_mode = settings.training.stun_mode,
   meter_mode = settings.training.meter_mode,
   infinite_time = settings.training.infinite_time
}

local function ensure_training_settings()
   old_settings = {
      life_mode = settings.training.life_mode,
      stun_mode = settings.training.stun_mode,
      meter_mode = settings.training.meter_mode,
      infinite_time = settings.training.infinite_time
   }
   settings.training.life_mode = 4
   settings.training.stun_mode = 3
   settings.training.meter_mode = 5
   settings.training.infinite_time = true
   training.disable_dummy = {false, true}
end

local function restore_training_settings()
   settings.training.life_mode = old_settings.life_mode
   settings.training.stun_mode = old_settings.stun_mode
   settings.training.meter_mode = old_settings.meter_mode
   settings.training.infinite_time = old_settings.infinite_time
   training.disable_dummy = {false, false}
end

local function continue_from_savestate()
   Register_After_Load_State(function()
      is_active = true
      player = gamestate.P1
      dummy = gamestate.P2
      local active_followups = {}
      for i = 1, #unblockable_data.followups do
         if settings.special_training.unblockables.followups[i] then
            table.insert(active_followups, unblockable_data.followups[i])
         end
      end
      local followup = active_followups[math.random(1, #active_followups)]
      advanced_control.queue_programmed_movement(dummy, followup.commands(dummy))
   end)
   savestate.load(followup_state)
end

local function start()
   Register_After_Load_State(function() is_active = true end)
   if settings.special_training.unblockables.savestate_player ==
       settings.special_training.unblockables.match_savestate_player and
       settings.special_training.unblockables.savestate_dummy ==
       settings.special_training.unblockables.match_savestate_dummy and
       settings.special_training.unblockables.savestate_type == settings.special_training.unblockables.type then
      continue_from_savestate()
   elseif settings.special_training.unblockables.match_savestate_dummy ==
       settings.special_training.unblockables.match_savestate_dummy then
      inputs.block_input(1, "all")
      inputs.block_input(2, "all")
      Register_After_Load_State(function()
         is_active = true
         player = gamestate.P1
         dummy = gamestate.P2
         ensure_training_settings()
         state = states.SETUP
      end)
      savestate.load(match_start_state)
   end
end

local function start_character_select()
   state = states.SETUP_MATCH_START
   ensure_training_settings()
   Register_After_Load_State(function()
      is_active = true
      player = gamestate.P1
      dummy = gamestate.P2
   end)
   unblockable_data = unblockables_tables.get_unblockables_data(settings.special_training.unblockables.character,
                                                                settings.special_training.unblockables.type)
   local char = unblockable_data.character
   local sa = 3
   if char == "oro" then sa = 2 end
   Register_After_Load_State(character_select.force_select_character, {2, char, sa, "random"})
   character_select.start_character_select_sequence()
end

local function stop()
   if is_active then
      is_active = false
      restore_training_settings()
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      advanced_control.clear_all()
   end
end

local function reset() is_active = false end

local function update()
   if is_active then
      if gamestate.is_in_match then
         if state == states.SETUP_MATCH_START or state == states.SETUP or state == states.WAIT_FOR_SETUP then
            inputs.block_input(1, "all")
            inputs.block_input(2, "all")
         end
         if state == states.SETUP or state == states.WAIT_FOR_SETUP then hud.show_please_wait_display(true) end
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
            savestate.save(match_start_state)
            settings.special_training.unblockables.character = player.char_str
            settings.special_training.unblockables.type = unblockables_tables.get_selected_unblockable_type(
                                                              player.char_str, dummy.char_str)
            settings.special_training.unblockables.match_savestate_player = gamestate.P1.char_str
            settings.special_training.unblockables.match_savestate_dummy = gamestate.P2.char_str
            settings.special_training.unblockables.savestate_player = ""
            settings.special_training.unblockables.savestate_dummy = ""
            is_active = false
         elseif state == states.SETUP then
            player = gamestate.P1
            dummy = gamestate.P2
            training.disable_dummy = {true, true}
            unblockable_data = unblockables_tables.get_unblockables_data(player.char_str,
                                                                         settings.special_training.unblockables.type)
            local player_offset = (frame_data.character_specific[player.char_str].pushbox_width +
                                      frame_data.character_specific[dummy.char_str].pushbox_width) / 2 + 6
            local stage_left = stage_data.stages[gamestate.stage].left
            local dummy_reset_x = stage_left + unblockable_data.reset_offset_x
            local player_reset_x = dummy_reset_x - player_offset

            if player.pos_x ~= player_reset_x or dummy.pos_x ~= dummy_reset_x then
               mem.write_pos_x(player, player_reset_x)
               mem.write_pos_x(dummy, dummy_reset_x)
            end

            local current_screen_x = memory.readword(memory_addresses.global.screen_pos_x)
            local desired_screen_x, desired_screen_y = write_memory.get_fix_screen_pos(player, dummy, gamestate.stage)

            if current_screen_x ~= desired_screen_x then
               write_memory.set_screen_pos(desired_screen_x, desired_screen_y)
            elseif player.pos_x == player_reset_x and dummy.pos_x == dummy_reset_x then
               advanced_control.queue_programmed_movement(dummy, unblockable_data.setup(dummy))
               state = states.WAIT_FOR_SETUP
            end
         elseif state == states.WAIT_FOR_SETUP then
            if advanced_control.all_commands_queued(dummy) and not inputs.is_playing_input_sequence(dummy) then
               Queue_Command(gamestate.frame_number + 1, function()
                  savestate.save(followup_state)
                  settings.special_training.unblockables.savestate_player = gamestate.P1.char_str
                  settings.special_training.unblockables.savestate_dummy = gamestate.P2.char_str
                  settings.special_training.unblockables.savestate_type = settings.special_training.unblockables.type
                  inputs.unblock_input(1)
                  inputs.unblock_input(2)
                  hud.show_please_wait_display(false)
                  continue_from_savestate()
               end)
               state = states.RUNNING
            end
         elseif state == states.RUNNING then
            if player.is_airborne or player.has_just_hit_ground or dummy.has_just_hit_ground then
               state = states.END
               end_frame = gamestate.frame_number + end_delay
            end
         elseif state == states.END then
            if gamestate.frame_number >= end_frame then
               -- freeze
               -- show retry menu
            end
         end
      end
   end
end

local function process_gesture(gesture) if is_active then if gesture == "single_tap" then start() end end end

local unblockables = {
   module_name = module_name,
   start_character_select = start_character_select,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture
}

setmetatable(unblockables, {
   __index = function(_, key) if key == "is_active" then return is_active end end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      else
         rawset(unblockables, key, value)
      end
   end
})

return unblockables
