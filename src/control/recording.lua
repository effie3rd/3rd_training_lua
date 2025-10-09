local settings = require("src.settings")
local gamestate = require("src.gamestate")
local game_data = require("src.modules.game_data")
local training = require("src.training")
local inputs = require("src.control.inputs")
local memory_addresses = require("src.control.memory_addresses")

local recording_slot_count = 16

local mode = 1

-- 1: Default Mode, 2: Wait for recording, 3: Recording, 4: Replaying
local current_recording_state = 1
local last_ordered_recording_slot = 0
local current_recording_last_idle_frame = -1
local override_replay_slot = -1
local current_recording_slot_frames = {frames = 0}
local replay_slot = -1

local recording_slots = {}

local recording_slots_names = {}

local superfreeze_begin_frame = -1

local continuous_recording_state = {RUNNING = 1, STOPPED = 2, PLAYING = 3}

local function make_recording_slot() return {inputs = {}, superfreeze = {}, delay = 0, random_deviation = 0, weight = 1} end

local function initialize_slots()
   for i = 1, recording_slot_count do table.insert(recording_slots, make_recording_slot()) end

   for i = 1, #recording_slots do table.insert(recording_slots_names, "slot " .. i) end
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

local function backup_recordings()
   -- Init base table
   if settings.recordings == nil then settings.recordings = {} end
   for _, value in ipairs(game_data.characters) do
      if settings.recordings[value] == nil then
         settings.recordings[value] = {}
         for i = 1, #recording_slots do table.insert(settings.recordings[value], make_recording_slot()) end
      end
   end

   if training.dummy.char_str ~= "" then settings.recordings[training.dummy.char_str] = recording_slots end
end

local function update_current_recording_slot_frames()
   current_recording_slot_frames.frames = #recording_slots[settings.training.current_recording_slot].inputs
end

local function restore_recordings()
   local char = gamestate.P2.char_str
   if char and char ~= "" then
      local recording_count = #recording_slots
      if settings.recordings then recording_slots = settings.recordings[char] or {} end
      local missing_slots = recording_count - #recording_slots
      for i = 1, missing_slots do table.insert(recording_slots, make_recording_slot()) end
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
      if value.inputs and #value.inputs > 0 then table.insert(recorded_slots, i) end
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
      -- print(slot_index)
      if recording_slots[slot_index].inputs ~= nil and #recording_slots[slot_index].inputs > 0 then
         slot = slot_index
         last_ordered_recording_slot = slot
         break
      end
   end
   return slot
end

local function set_recording_state(input, state)
   if (state == current_recording_state) then return end
   local current_recording_slot = recording_slots[settings.training.current_recording_slot]
   -- exit states
   if current_recording_state == 1 then
   elseif current_recording_state == 2 then
      training.swap_characters = false
   elseif current_recording_state == 3 then
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
      for i = first_input, last_input do table.insert(cropped_sequence, current_recording_slot.inputs[i]) end
      current_recording_slot.inputs = cropped_sequence

      if current_recording_slot.superfreeze then
         for i, freeze_data in ipairs(current_recording_slot.superfreeze) do
            local adjusted_frame = freeze_data[1] - (first_input - 1)
            current_recording_slot.superfreeze[i] = {adjusted_frame, freeze_data[2]}
         end
      end

      settings.save_training_data()

      training.swap_characters = false
   elseif current_recording_state == 4 then
      inputs.clear_input_sequence(training.dummy)
   end

   current_recording_state = state

   -- enter states
   if current_recording_state == 1 then
   elseif current_recording_state == 2 then
      training.swap_characters = true
      inputs.make_input_empty(input)
   elseif current_recording_state == 3 then
      current_recording_last_idle_frame = -1
      training.swap_characters = true
      inputs.make_input_empty(input)
      current_recording_slot.inputs = {}
      current_recording_slot.superfreeze = {}
   elseif current_recording_state == 4 then
      replay_slot = -1
      if override_replay_slot > 0 then
         replay_slot = override_replay_slot
      else
         if settings.training.replay_mode == 2 or settings.training.replay_mode == 5 then
            replay_slot = find_random_recording_slot()
         elseif settings.training.replay_mode == 3 or settings.training.replay_mode == 6 then
            replay_slot = go_to_next_ordered_slot()
         else
            replay_slot = settings.training.current_recording_slot
         end
      end

      if replay_slot > 0 then inputs.queue_input_sequence(training.dummy, recording_slots[replay_slot].inputs) end
   end
end

local function reset_recording_state()
   -- reset recording states in a useful way
   if current_recording_state == 3 then
      set_recording_state({}, 2)
   elseif current_recording_state == 4 and
       (settings.training.replay_mode == 4 or settings.training.replay_mode == 5 or settings.training.replay_mode == 6) then
      set_recording_state({}, 1)
      set_recording_state({}, 4)
   end
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
      if current_recording_state == 2 or current_recording_state == 3 then
         set_recording_state(input, 1)
      else
         if training.swap_characters then
            training.toggle_swap_characters()
         else
            set_recording_state(input, 2)
         end
      end
   elseif gesture == "single_tap" then
      if current_recording_state == 1 then
         if can_play_recording() then set_recording_state(input, 4) end
      elseif current_recording_state == 2 then
         set_recording_state(input, 3)
      elseif current_recording_state == 3 then
         set_recording_state(input, 1)
      elseif current_recording_state == 4 then
         set_recording_state(input, 1)
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
      screen_x = memory.readword(memory_addresses.global.screen_pos_x),
      screen_y = memory.readword(memory_addresses.global.screen_pos_y),
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
   table.insert(continuous_recording_keyframes, keyframe)
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
local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/defense_match_start.fs")

local function update_continuous_recording(input, player, dummy)
   if gamestate.has_match_just_started then savestate.save(match_start_state) end
   table.insert(continuous_recording_inputs, {})
   while #continuous_recording_inputs > continuous_recording_length do table.remove(continuous_recording_inputs, 1) end
   if is_valid_keyframe() then
      previous_is_valid_keyframe = true
      if not previous_is_valid_keyframe then end
   else
      previous_is_valid_keyframe = false
   end
end

local function update_recording(input, player, dummy)
   if gamestate.is_in_match then
      if mode == 1 then
         if current_recording_state == 1 then
         elseif current_recording_state == 2 then
         elseif current_recording_state == 3 then
            local frame = {}

            for key, value in pairs(input) do
               local prefix = key:sub(1, #player.prefix)
               if (prefix == player.prefix) then
                  local input_name = key:sub(1 + #player.prefix + 1)
                  if (input_name ~= "Coin" and input_name ~= "Start") then
                     if (value) then
                        local sequence_input_name = stick_input_to_sequence_input(player, input_name)
                        table.insert(frame, sequence_input_name)
                     end
                  end
               end
            end
            local current_recording_slot = recording_slots[settings.training.current_recording_slot]
            local recording_inputs = current_recording_slot.inputs
            table.insert(recording_inputs, frame)

            local recording_frame = #recording_inputs

            if player.superfreeze_just_began then
               if not current_recording_slot.superfreeze then current_recording_slot.superfreeze = {} end
               superfreeze_begin_frame = recording_frame
            end
            if player.superfreeze_decount > 0 and recording_frame - superfreeze_begin_frame < 3 then
               table.insert(current_recording_slot.superfreeze, {recording_frame, player.remaining_freeze_frames})
            end

            if player.idle_time == 1 then current_recording_last_idle_frame = recording_frame - 1 end

         elseif current_recording_state == 4 then
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
               set_recording_state(input, 1)
               if can_play_recording() and
                   (settings.training.replay_mode == 4 or settings.training.replay_mode == 5 or
                       settings.training.replay_mode == 6) then set_recording_state(input, 4) end
            end
         end
      elseif mode == 2 then
         update_continuous_recording(input, player, dummy)
      end
   end
end

initialize_slots()

local recording_module = {
   recording_slot_count = recording_slot_count,
   clear_slot = clear_slot,
   clear_all_slots = clear_all_slots,
   backup_recordings = backup_recordings,
   restore_recordings = restore_recordings,
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
      elseif key == "override_replay_slot" then
         return override_replay_slot
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
