local game_data = require("src.data.game_data")
local settings, gamestate, training, inputs, managers, framedata, utils, tools, write_memory

local recording_slot_count = 16

local mode = 1

-- 1: Default Mode, 2: Wait for recording, 3: Recording, 4: Replaying
local RECORDING_STATE = {
   STOPPED = 1,
   WAIT_FOR_RECORDING = 2,
   RECORDING = 3,
   QUEUE_REPLAY = 4,
   POSITIONING = 5,
   REPLAYING = 6
}

local current_recording_state = RECORDING_STATE.STOPPED
local last_ordered_recording_slot = 0
local current_recording_last_idle_frame = -1
local current_recording_slot_frames = {frames = 0}
local replay_slot = -1
local replay_data = {}
local replay_options = {}

local recording_slots = {}
local recording_slots_names = {}

local superfreeze_begin_frame = -1

local continuous_recording_state = {RUNNING = 1, STOPPED = 2, PLAYING = 3}

local function get_current_recording_slot() return recording_slots[settings.training.current_recording_slot] end

local function make_recording_slot()
   return {
      inputs = {},
      superfreeze = {},
      player_position = {430, 0},
      dummy_offset = {170, 0},
      screen_position = {512, 0},
      delay = 0,
      random_deviation = 0,
      weight = 1
   }
end

local function clear_slot()
   recording_slots[settings.training.current_recording_slot] = make_recording_slot()
   settings.save_training_data()
end

local function clear_all_slots()
   for i = 1, recording_slot_count do recording_slots[i] = make_recording_slot() end
   settings.training.current_recording_slot = 1
   settings.save_training_data()
end

local function clear_all_recordings()
   for _, char in pairs(game_data.characters) do
      settings.recordings[char] = {}
      recording_slots = settings.recordings[char]
      clear_all_slots()
   end
end

local function create_default_settings()
   local rec = {}
   for _, char in pairs(game_data.characters) do
      rec[char] = {}
      for i = 1, recording_slot_count do rec[char][i] = make_recording_slot() end
   end
   return rec
end

local function initialize_slots()
   if not next(settings.recordings) then clear_all_recordings() end
   for i = 1, recording_slot_count do recording_slots[#recording_slots + 1] = make_recording_slot() end
   for i = 1, #recording_slots do recording_slots_names[#recording_slots_names + 1] = "slot " .. i end
end

local function init()
   settings = require("src.settings")
   gamestate = require("src.gamestate")
   game_data = require("src.data.game_data")
   training = require("src.training")
   inputs = require("src.control.inputs")
   managers = require("src.control.managers")
   framedata = require("src.data.framedata")
   utils = require("src.data.utils")
   tools = require("src.tools")
   write_memory = require("src.control.write_memory")
   initialize_slots()
end

local function backup_recordings()
   -- Init base table
   if settings.recordings == nil then settings.recordings = {} end
   for _, value in ipairs(game_data.characters) do
      if settings.recordings[value] == nil then
         settings.recordings[value] = {}
         for i = 1, #recording_slots do
            settings.recordings[value][#settings.recordings[value] + 1] = make_recording_slot()
         end
      end
   end

   if training.dummy.char_str ~= "" then settings.recordings[training.dummy.char_str] = recording_slots end
end

local function update_current_recording_slot_frames()
   current_recording_slot_frames.frames = #recording_slots[settings.training.current_recording_slot].inputs
end

local function load_recordings(char_str)
   recording_slots = settings.recordings[char_str] or {}
   update_current_recording_slot_frames()
end

local function get_recordings(char_str) return settings.recordings[char_str] or {} end

local function restore_recordings(char_str)
   if char_str and char_str ~= "" then
      local recording_count = #recording_slots
      if settings.recordings then recording_slots = settings.recordings[char_str] or {} end
      local missing_slots = recording_count - #recording_slots
      for i = 1, missing_slots do recording_slots[#recording_slots + 1] = make_recording_slot() end
   end
   update_current_recording_slot_frames()
end

local function can_play_recording()
   if settings.training.replay_mode == 2 or settings.training.replay_mode == 3 or settings.training.replay_mode == 5 or
       settings.training.replay_mode == 6 then
      for i, value in ipairs(recording_slots) do if #value.inputs > 0 then return true end end
   else
      return recording_slots[settings.training.current_recording_slot].inputs ~= nil and
                 #recording_slots[settings.training.current_recording_slot].inputs > 0
   end
   return false
end

local function find_random_recording_slot()
   -- random slot selection
   local recorded_slots = {}
   for i, value in ipairs(recording_slots) do
      if value.inputs and #value.inputs > 0 then recorded_slots[#recorded_slots + 1] = i end
   end

   if #recorded_slots > 0 then
      local total_weight = 0
      for i, value in pairs(recorded_slots) do total_weight = total_weight + recording_slots[value].weight end

      local random_slot_weight = 0
      if total_weight > 0 then random_slot_weight = math.ceil(math.random(total_weight)) end
      local random_slot = 1
      local weight_i = 0
      for i, value in ipairs(recorded_slots) do
         if weight_i <= random_slot_weight and weight_i + recording_slots[value].weight >= random_slot_weight then
            random_slot = i
            break
         end
         weight_i = weight_i + recording_slots[value].weight
      end
      return recorded_slots[random_slot]
   end
   return -1
end

local function go_to_next_ordered_slot()
   local slot = -1
   for i = 1, recording_slot_count do
      local slot_index = ((last_ordered_recording_slot - 1 + i) % recording_slot_count) + 1
      if recording_slots[slot_index].inputs ~= nil and #recording_slots[slot_index].inputs > 0 then
         slot = slot_index
         last_ordered_recording_slot = slot
         break
      end
   end
   return slot
end

local function select_replay_slot()
   replay_slot = -1
   if replay_options.override_replay_slot then
      replay_slot = replay_options.override_replay_slot
   else
      if settings.training.replay_mode == 2 or settings.training.replay_mode == 5 then
         replay_slot = find_random_recording_slot()
      elseif settings.training.replay_mode == 3 or settings.training.replay_mode == 6 then
         replay_slot = go_to_next_ordered_slot()
      else
         replay_slot = settings.training.current_recording_slot
      end
   end
end

local function set_recording_state(input, state)
   if (state == current_recording_state) then return end
   local current_recording_slot = recording_slots[settings.training.current_recording_slot]
   local should_swap = false
   -- exit states
   if current_recording_state == RECORDING_STATE.STOPPED then
   elseif current_recording_state == RECORDING_STATE.WAIT_FOR_RECORDING then
      should_swap = true
   elseif current_recording_state == RECORDING_STATE.RECORDING then
      local first_input = 1
      local last_input = 1
      for i, value in ipairs(current_recording_slot.inputs) do
         if #value > 0 then
            last_input = i
         elseif first_input == i then
            first_input = first_input + 1
         end
      end

      last_input = math.max(current_recording_last_idle_frame, last_input)

      if not settings.training.auto_crop_recording_start then first_input = 1 end

      if not settings.training.auto_crop_recording_end or last_input ~= current_recording_last_idle_frame then
         last_input = #current_recording_slot.inputs
      end

      local cropped_sequence = {}
      for i = first_input, last_input do cropped_sequence[#cropped_sequence + 1] = current_recording_slot.inputs[i] end
      current_recording_slot.inputs = cropped_sequence

      if current_recording_slot.superfreeze then
         for i, freeze_data in ipairs(current_recording_slot.superfreeze) do
            local adjusted_frame = freeze_data[1] - (first_input - 1)
            current_recording_slot.superfreeze[i] = {adjusted_frame, freeze_data[2]}
         end
      end

      -- emulator cannot save settings on same frame of savestate load, so we have to delay it
      Queue_Command(gamestate.frame_number + 1, settings.save_training_data)
      should_swap = true
   elseif current_recording_state == RECORDING_STATE.POSITIONING then
      managers.Screen_Scroll:stop_scroll()
   elseif current_recording_state == RECORDING_STATE.REPLAYING then
      inputs.clear_input_sequence(training.dummy)
   end

   current_recording_state = state
   if should_swap then training.swap_controls() end

   -- enter states
   if current_recording_state == RECORDING_STATE.STOPPED then
   elseif current_recording_state == RECORDING_STATE.WAIT_FOR_RECORDING then
      training.swap_controls()
      inputs.make_input_empty(input)
   elseif current_recording_state == RECORDING_STATE.RECORDING then
      current_recording_last_idle_frame = -1
      training.swap_controls()
      inputs.make_input_empty(input)
      current_recording_slot.inputs = {}
      current_recording_slot.superfreeze = {}
   elseif current_recording_state == RECORDING_STATE.QUEUE_REPLAY then
   elseif current_recording_state == RECORDING_STATE.POSITIONING then
   elseif current_recording_state == RECORDING_STATE.REPLAYING then
   end
end

local function reset_recording_state()
   -- reset recording states in a useful way
   if current_recording_state == RECORDING_STATE.RECORDING then
      set_recording_state({}, RECORDING_STATE.WAIT_FOR_RECORDING)
   elseif current_recording_state == RECORDING_STATE.REPLAYING and
       (settings.training.replay_mode == 4 or settings.training.replay_mode == 5 or settings.training.replay_mode == 6) then
      set_recording_state({}, RECORDING_STATE.STOPPED)
      replay_options = {}
      select_replay_slot()
      set_recording_state({}, RECORDING_STATE.QUEUE_REPLAY)
   end
end

local function set_replay_options(option, value) replay_options[option] = value end

local function play_recording()
   if can_play_recording() then
      replay_options = {}
      select_replay_slot()
      set_recording_state(input, RECORDING_STATE.QUEUE_REPLAY)
   end
end

local function play_recording_without_positioning()
   set_recording_state({}, RECORDING_STATE.STOPPED)
   replay_options.disable_positioning = true
   select_replay_slot()
   set_recording_state({}, RECORDING_STATE.QUEUE_REPLAY)
end

local function stick_input_to_sequence_input(player, input)
   if input == "Up" then return "up" end
   if input == "Down" then return "down" end
   if input == "Weak Punch" then return "LP" end
   if input == "Medium Punch" then return "MP" end
   if input == "Strong Punch" then return "HP" end
   if input == "Weak Kick" then return "LK" end
   if input == "Medium Kick" then return "MK" end
   if input == "Strong Kick" then return "HK" end

   if input == "Left" then
      if player.flip_input then
         return "back"
      else
         return "forward"
      end
   end

   if input == "Right" then
      if player.flip_input then
         return "forward"
      else
         return "back"
      end
   end
   return ""
end

local function process_gesture(gesture)
   if gesture == "double_tap" then
      if current_recording_state == RECORDING_STATE.WAIT_FOR_RECORDING or current_recording_state ==
          RECORDING_STATE.RECORDING then
         set_recording_state(input, RECORDING_STATE.STOPPED)
      else
         set_recording_state(input, RECORDING_STATE.WAIT_FOR_RECORDING)
      end
   elseif gesture == "single_tap" then
      if current_recording_state == RECORDING_STATE.STOPPED then
         play_recording()
      elseif current_recording_state == RECORDING_STATE.WAIT_FOR_RECORDING then
         set_recording_state(input, RECORDING_STATE.RECORDING)
      elseif current_recording_state == RECORDING_STATE.RECORDING then
         set_recording_state(input, RECORDING_STATE.STOPPED)
      elseif current_recording_state == RECORDING_STATE.QUEUE_REPLAY then
         set_recording_state(input, RECORDING_STATE.STOPPED)
      elseif current_recording_state == RECORDING_STATE.REPLAYING then
         set_recording_state(input, RECORDING_STATE.STOPPED)
      end
   end
end

local continuous_recording_length = 800
local continuous_recording_inputs = {}
local continuous_recording_keyframes = {}
local keyframe_minimum_interval = 100
local current_continuous_recording_state = continuous_recording_state.STOPPED
local previous_is_valid_keyframe = false

local function create_new_keyframe()
   local keyframe = {
      recording_frame = 1,
      frame_mod3 = gamestate.frame_number % 3,
      screen_x = gamestate.screen_x,
      screen_y = gamestate.screen_y,
      players = {}
   }
   for i, player in ipairs(gamestate.player_objects) do
      local meter_count = memory.readbyte(player.addresses.meter_master)
      local gauge = memory.readbyte(player.addresses.gauge)
      local meter = 0
      if player.is_in_timed_sa then
         meter = gauge
      else
         meter = gauge + player.max_meter_gauge * meter_count
      end
      keyframe.players[i] = {
         pos_x = player.pos_x,
         pos_y = player.pos_y,
         posture = player.posture,
         life = player.life,
         meter = meter,
         stun = player.stun_bar
      }
   end
   return keyframe
end

local function add_new_keyframe()
   local keyframe = create_new_keyframe()
   keyframe.recording_frame = #continuous_recording_inputs - 1
   continuous_recording_keyframes[#continuous_recording_keyframes + 1] = keyframe
end

local function is_valid_keyframe()
   for _, player in ipairs(gamestate.player_objects) do
      if not player.is_idle or
          not (player.posture == 0 or player.posture == 32 or player.posture == 6 or player.posture == 8) then
         return false
      end
   end
   return true
end

-- local function update_continuous_recording(input, player, dummy)
--    if gamestate.has_match_just_started then savestate.save(match_start_state) end
--    continuous_recording_inputs[#continuous_recording_inputs + 1] = {}
--    while #continuous_recording_inputs > continuous_recording_length do table.remove(continuous_recording_inputs, 1) end
--    if is_valid_keyframe() then
--       previous_is_valid_keyframe = true
--       if not previous_is_valid_keyframe then end
--    else
--       previous_is_valid_keyframe = false
--    end
-- end

local function update_recording(input, player)
   local dummy = player.other
   if gamestate.is_in_match then
      if mode == 1 then
         if current_recording_state == RECORDING_STATE.STOPPED then
         elseif current_recording_state == RECORDING_STATE.WAIT_FOR_RECORDING then
         elseif current_recording_state == RECORDING_STATE.RECORDING then
            local frame = {}

            for key, value in pairs(input) do
               local prefix = key:sub(1, #player.prefix)
               if (prefix == player.prefix) then
                  local input_name = key:sub(1 + #player.prefix + 1)
                  if (input_name ~= "Coin" and input_name ~= "Start") then
                     if (value) then
                        local sequence_input_name = stick_input_to_sequence_input(player, input_name)
                        frame[#frame + 1] = sequence_input_name
                     end
                  end
               end
            end
            local current_recording_slot = recording_slots[settings.training.current_recording_slot]
            local recording_inputs = current_recording_slot.inputs
            recording_inputs[#recording_inputs + 1] = frame

            if #recording_inputs == 1 then
               -- player is the dummy while recording
               local contact_dist = framedata.get_contact_distance(player)
               local sign = dummy.side == 1 and 1 or -1
               current_recording_slot.player_position = {dummy.pos_x, dummy.pos_y}
               current_recording_slot.dummy_offset = {
                  player.pos_x - dummy.pos_x - sign * contact_dist, player.pos_y - dummy.pos_y
               }
               current_recording_slot.screen_position = {gamestate.screen_x, gamestate.screen_y}
            end

            local recording_frame = #recording_inputs

            if player.superfreeze_just_began then
               if not current_recording_slot.superfreeze then current_recording_slot.superfreeze = {} end
               superfreeze_begin_frame = recording_frame
            end
            if player.superfreeze_decount > 0 and recording_frame - superfreeze_begin_frame < 3 then
               current_recording_slot.superfreeze[#current_recording_slot.superfreeze + 1] = {
                  recording_frame, player.remaining_freeze_frames
               }
            end

            if player.idle_time == 1 then current_recording_last_idle_frame = recording_frame - 1 end

         elseif current_recording_state == RECORDING_STATE.QUEUE_REPLAY then
            if replay_slot > 0 then
               local should_start_replay = false
               if (not settings.training.recording_player_positioning and
                   not settings.training.recording_dummy_positioning) or replay_options.disable_positioning then
                  should_start_replay = true
               else
                  if not recording_slots[replay_slot].player_position then
                     set_recording_state(input, RECORDING_STATE.STOPPED)
                     return
                  end
                  replay_data = {
                     player_reset_x = 0,
                     dummy_reset_x = 0,
                     dummy_offset_x = tools.trunc(recording_slots[replay_slot].dummy_offset[1])
                  }
                  local player_stage_left, player_stage_right = utils.get_stage_limits(gamestate.stage, player.char_str)

                  if settings.training.recording_player_positioning then
                     replay_data.player_reset_x = tools.trunc(recording_slots[replay_slot].player_position[1])
                     replay_data.player_reset_x = tools.clamp(replay_data.player_reset_x, player_stage_left,
                                                              player_stage_right)
                  else
                     replay_data.player_reset_x = training.player.pos_x_char
                  end
                  if settings.training.recording_dummy_positioning then
                     local corner_offset_tolerance = 40
                     local contact_dist = framedata.get_contact_distance(player)
                     local dummy_stage_left, dummy_stage_right = utils.get_stage_limits(gamestate.stage, dummy.char_str)
                     local sign = player.side == 1 and 1 or -1
                     if settings.training.recording_player_positioning then sign = 1 end
                     if math.abs(replay_data.dummy_offset_x + contact_dist) < contact_dist then
                        replay_data.dummy_offset_x = 0
                     end
                     replay_data.dummy_reset_x = tools.trunc(
                                                     replay_data.player_reset_x + sign *
                                                         (contact_dist + replay_data.dummy_offset_x))

                     local outside_stage = false
                     local diff = 0
                     if replay_data.dummy_reset_x < dummy_stage_left then
                        replay_data.dummy_reset_x = dummy_stage_left
                        diff = dummy_stage_left - replay_data.dummy_reset_x
                        outside_stage = true
                     elseif replay_data.dummy_reset_x > dummy_stage_right then
                        replay_data.dummy_reset_x = dummy_stage_right
                        diff = dummy_stage_right - replay_data.dummy_reset_x
                        outside_stage = true
                     end
                     local use_other_side = true
                     if settings.training.recording_player_positioning then
                        if outside_stage and math.abs(diff) <= corner_offset_tolerance then
                           replay_data.player_reset_x = replay_data.player_reset_x + diff
                           use_other_side = false
                        end
                     elseif math.abs(replay_data.dummy_reset_x - replay_data.player_reset_x - sign * contact_dist) ==
                         math.abs(replay_data.dummy_offset_x) then
                        use_other_side = false
                     end
                     if use_other_side then
                        replay_data.dummy_reset_x = tools.trunc(
                                                        replay_data.player_reset_x - sign *
                                                            (contact_dist + replay_data.dummy_offset_x))
                        replay_data.dummy_reset_x = tools.clamp(replay_data.dummy_reset_x, dummy_stage_left,
                                                                dummy_stage_right)
                        sign = sign * -1
                     end
                  else
                     replay_data.dummy_reset_x = training.dummy.pos_x_char
                  end

                  local scroll_context
                  if not settings.training.recording_player_positioning then
                     if settings.training.recording_dummy_positioning then
                        scroll_context = {target_x = replay_data.dummy_reset_x, target_y = 0}
                        -- managers.Screen_Scroll:scroll_to_player_position(player, scroll_context)
                     end
                  else
                     if settings.training.recording_dummy_positioning then
                        scroll_context = {}
                        -- managers.Screen_Scroll:scroll_to_screen_position(
                        --     recording_slots[replay_slot].screen_position[1],
                        --     recording_slots[replay_slot].screen_position[2], scroll_context)
                     else
                        scroll_context = {target_y = 0}
                        -- managers.Screen_Scroll:scroll_to_center(player, replay_data.player_reset_x,
                        --                                         replay_data.dummy_reset_x, scroll_context)
                     end
                  end
                  current_recording_state = RECORDING_STATE.POSITIONING
               end
               if should_start_replay then
                  inputs.queue_input_sequence(training.dummy, recording_slots[replay_slot].inputs, 0, true)
                  current_recording_state = RECORDING_STATE.REPLAYING
               end
            end
         end
         if current_recording_state == RECORDING_STATE.POSITIONING then
            local player_positioned, dummy_positioned = false, false
            if settings.training.recording_player_positioning then
               if training.player.pos_x_char == replay_data.player_reset_x then player_positioned = true end
               write_memory.write_pos_x(training.player, replay_data.player_reset_x)
            else
               player_positioned = true
            end
            if settings.training.recording_dummy_positioning then
               if training.dummy.pos_x_char == replay_data.dummy_reset_x then dummy_positioned = true end
               write_memory.write_pos_x(training.dummy, replay_data.dummy_reset_x)
            else
               dummy_positioned = true
            end
            if player_positioned and dummy_positioned then
               inputs.queue_input_sequence(training.dummy, recording_slots[replay_slot].inputs, 0, true)
               current_recording_state = RECORDING_STATE.REPLAYING
            end
         end
         if current_recording_state == RECORDING_STATE.REPLAYING then
            if dummy.pending_input_sequence then
               if dummy.superfreeze_decount > 0 and recording_slots[replay_slot].superfreeze then
                  local expected_freeze = 0
                  for i, freeze_data in ipairs(recording_slots[replay_slot].superfreeze) do
                     if dummy.pending_input_sequence.current_frame >= freeze_data[1] then
                        expected_freeze = freeze_data[2] - (dummy.pending_input_sequence.current_frame - freeze_data[1])
                     end
                  end
                  if expected_freeze > 0 then
                     local diff = dummy.remaining_freeze_frames - expected_freeze
                     if diff ~= 0 then
                        dummy.pending_input_sequence.current_frame = dummy.pending_input_sequence.current_frame - diff
                     end
                  end
               end
            else
               set_recording_state(input, RECORDING_STATE.STOPPED)
               if can_play_recording() and
                   (settings.training.replay_mode == 4 or settings.training.replay_mode == 5 or
                       settings.training.replay_mode == 6) then
                  replay_options = {}
                  select_replay_slot()
                  set_recording_state(input, RECORDING_STATE.QUEUE_REPLAY)
               end
            end
         end
      elseif mode == 2 then
         -- update_continuous_recording(input, player, dummy)
      end
   end
end

local recording_module = {
   init = init,
   create_default_settings = create_default_settings,
   RECORDING_STATE = RECORDING_STATE,
   recording_slot_count = recording_slot_count,
   load_recordings = load_recordings,
   get_recordings = get_recordings,
   get_current_recording_slot = get_current_recording_slot,
   clear_slot = clear_slot,
   clear_all_slots = clear_all_slots,
   clear_all_recordings = clear_all_recordings,
   backup_recordings = backup_recordings,
   restore_recordings = restore_recordings,
   find_random_recording_slot = find_random_recording_slot,
   go_to_next_ordered_slot = go_to_next_ordered_slot,
   set_replay_options = set_replay_options,
   play_recording = play_recording,
   play_recording_without_positioning = play_recording_without_positioning,
   process_gesture = process_gesture,
   set_recording_state = set_recording_state,
   reset_recording_state = reset_recording_state,
   update_current_recording_slot_frames = update_current_recording_slot_frames,
   update_recording = update_recording
}

setmetatable(recording_module, {
   __index = function(_, key)
      if key == "current_recording_slot_frames" then
         return current_recording_slot_frames
      elseif key == "current_recording_state" then
         return current_recording_state
      elseif key == "recording_slots" then
         return recording_slots
      end
   end,

   __newindex = function(_, key, value)
      if key == "recording_slots" then
         recording_slots = value
      else
         rawset(recording_module, key, value)
      end
   end
})

return recording_module
