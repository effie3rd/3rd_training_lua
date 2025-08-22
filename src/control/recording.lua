local settings = require("src/settings")
local gamestate = require("src/gamestate")
local training = require("src/training")


saved_recordings_path = "saved/recordings/"

recording_slot_count = 16
swap_characters = false
-- 1: Default Mode, 2: Wait for recording, 3: Recording, 4: Replaying
current_recording_state = 1
last_ordered_recording_slot = 0
current_recording_last_idle_frame = -1
last_coin_input_frame = -1
override_replay_slot = -1
current_recording_slot_frames = {}

recording_states =
{
  "none",
  "waiting",
  "recording",
  "playing",
}

function clear_slot()
  recording_slots[settings.training.current_recording_slot] = make_recording_slot()
  settings.save_training_data()
end

function clear_all_slots()
  for i = 1, recording_slot_count do
    recording_slots[i] = make_recording_slot()
  end
  settings.training.current_recording_slot = 1
  settings.save_training_data()
end


function save_recording_slot_to_file()
  if save_file_name == "" then
    print(string.format("Error: Can't save to empty file name"))
    return
  end

  local path = string.format("%s%s.json",saved_recordings_path, save_file_name)
  if not write_object_to_json_file(recording_slots[settings.training.current_recording_slot].inputs, path) then
    print(string.format("Error: Failed to save recording to \"%s\"", path))
  else
    print(string.format("Saved slot %d to \"%s\"", settings.training.current_recording_slot, path))
  end

  menu_stack_pop(save_recording_slot_popup)
end

function load_recording_slot_from_file()
  if #load_file_list == 0 or load_file_list[load_file_index] == nil then
    print(string.format("Error: Can't load from empty file name"))
    return
  end

  local path = string.format("%s%s",saved_recordings_path, load_file_list[load_file_index])
  local recording = read_object_from_json_file(path)
  if not recording then
    print(string.format("Error: Failed to load recording from \"%s\"", path))
  else
    recording_slots[settings.training.current_recording_slot].inputs = recording
    print(string.format("Loaded \"%s\" to slot %d", path, settings.training.current_recording_slot))
  end
  settings.save_training_data()

  menu_stack_pop(load_recording_slot_popup)
end

local function backup_recordings()
  -- Init base table
  if settings.training.recordings == nil then
    settings.training.recordings = {}
  end
  for _, value in ipairs(Characters) do
    if settings.training.recordings[value] == nil then
      settings.training.recordings[value] = {}
      for i = 1, #recording_slots do
        table.insert(settings.training.recordings[value], make_recording_slot())
      end
    end
  end

  if training.dummy.char_str ~= "" then
    settings.training.recordings[training.dummy.char_str] = recording_slots
  end
end

local function restore_recordings()
  local char = gamestate.P2.char_str
  if char and char ~= "" then
    local recording_count = #recording_slots
    if settings.training.recordings then
      recording_slots = settings.training.recordings[char] or {}
    end
      local missing_slots = recording_count - #recording_slots
    for i = 1, missing_slots do
        table.insert(recording_slots, make_recording_slot())
    end
  end
  update_current_recording_slot_frames()
end

function update_current_recording_slot_frames()
  current_recording_slot_frames[1] = #recording_slots[settings.training.current_recording_slot].inputs
end

function can_play_recording()
  if settings.training.replay_mode == 2 or settings.training.replay_mode == 3 or settings.training.replay_mode == 5 or settings.training.replay_mode == 6 then
    for i, value in ipairs(recording_slots) do
      if #value.inputs > 0 then
        return true
      end
    end
  else
    return recording_slots[settings.training.current_recording_slot].inputs ~= nil and #recording_slots[settings.training.current_recording_slot].inputs > 0
  end
  return false
end

function find_random_recording_slot()
  -- random slot selection
  local recorded_slots = {}
  for i, value in ipairs(recording_slots) do
    if value.inputs and #value.inputs > 0 then
      table.insert(recorded_slots, i)
    end
  end

  if #recorded_slots > 0 then
    local total_weight = 0
    for i, value in pairs(recorded_slots) do
      total_weight = total_weight + recording_slots[value].weight
    end

    local random_slot_weight = 0
    if total_weight > 0 then
      random_slot_weight = math.ceil(math.random(total_weight))
    end
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

function go_to_next_ordered_slot()
  local slot = -1
  for i = 1, recording_slot_count do
    local slot_index = ((last_ordered_recording_slot - 1 + i) % recording_slot_count) + 1
    --print(slot_index)
    if recording_slots[slot_index].inputs ~= nil and #recording_slots[slot_index].inputs > 0 then
      slot = slot_index
      last_ordered_recording_slot = slot
      break
    end
  end
  return slot
end

function set_recording_state(input, state)
  if (state == current_recording_state) then
    return
  end

  -- exit states
  if current_recording_state == 1 then
  elseif current_recording_state == 2 then
    swap_characters = false
  elseif current_recording_state == 3 then
    local first_input = 1
    local last_input = 1
    for i, value in ipairs(recording_slots[settings.training.current_recording_slot].inputs) do
      if #value > 0 then
        last_input = i
      elseif first_input == i then
        first_input = first_input + 1
      end
    end

    last_input = math.max(current_recording_last_idle_frame, last_input)

    if not settings.training.auto_crop_recording_start then
      first_input = 1
    end

    if not settings.training.auto_crop_recording_end or last_input ~= current_recording_last_idle_frame then
      last_input = #recording_slots[settings.training.current_recording_slot].inputs
    end

    local cropped_sequence = {}
    for i = first_input, last_input do
      table.insert(cropped_sequence, recording_slots[settings.training.current_recording_slot].inputs[i])
    end
    recording_slots[settings.training.current_recording_slot].inputs = cropped_sequence

    settings.save_training_data()

    swap_characters = false
  elseif current_recording_state == 4 then
    clear_input_sequence(training.dummy)
  end

  current_recording_state = state

  -- enter states
  if current_recording_state == 1 then
  elseif current_recording_state == 2 then
    swap_characters = true
    make_input_empty(input)
  elseif current_recording_state == 3 then
    current_recording_last_idle_frame = -1
    swap_characters = true
    make_input_empty(input)
    recording_slots[settings.training.current_recording_slot].inputs = {}
  elseif current_recording_state == 4 then
    local replay_slot = -1
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

    if replay_slot > 0 then
      queue_input_sequence(training.dummy, recording_slots[replay_slot].inputs)
    end
  end
end

function update_recording(input, player, dummy)

  local input_buffer_length = 11
  if gamestate.is_in_match then

    -- manage input
    local input_pressed = (not swap_characters and player.input.pressed.coin) or (swap_characters and dummy.input.pressed.coin)
    if input_pressed then
      if gamestate.frame_number < (last_coin_input_frame + input_buffer_length) then
        last_coin_input_frame = -1

        -- double tap
        if current_recording_state == 2 or current_recording_state == 3 then
          set_recording_state(input, 1)
        else
          set_recording_state(input, 2)
        end

      else
        last_coin_input_frame = gamestate.frame_number
      end
    end

    if last_coin_input_frame > 0 and gamestate.frame_number >= last_coin_input_frame + input_buffer_length then
      last_coin_input_frame = -1

      -- single tap
      if current_recording_state == 1 then
        if can_play_recording() then
          set_recording_state(input, 4)
        end
      elseif current_recording_state == 2 then
        set_recording_state(input, 3)
      elseif current_recording_state == 3 then
        set_recording_state(input, 1)
      elseif current_recording_state == 4 then
        set_recording_state(input, 1)
      end

    end

    -- tick states
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
              --print(input_name.." "..sequence_input_name)
              table.insert(frame, sequence_input_name)
            end
          end
        end
      end

      table.insert(recording_slots[settings.training.current_recording_slot].inputs, frame)

      if player.idle_time == 1 then
        current_recording_last_idle_frame = #recording_slots[settings.training.current_recording_slot].inputs - 1
      end

    elseif current_recording_state == 4 then
      if training.dummy.pending_input_sequence == nil then
        set_recording_state(input, 1)
        if can_play_recording() and (settings.training.replay_mode == 4 or settings.training.replay_mode == 5 or settings.training.replay_mode == 6) then
          set_recording_state(input, 4)
        end
      end
    end
  end

  previous_recording_state = current_recording_state
end

function stick_input_to_sequence_input(player_obj, input)
  if input == "Up" then return "up" end
  if input == "Down" then return "down" end
  if input == "Weak Punch" then return "LP" end
  if input == "Medium Punch" then return "MP" end
  if input == "Strong Punch" then return "HP" end
  if input == "Weak Kick" then return "LK" end
  if input == "Medium Kick" then return "MK" end
  if input == "Strong Kick" then return "HK" end

  if input == "Left" then
    if player_obj.flip_input then
      return "back"
    else
      return "forward"
    end
  end

  if input == "Right" then
    if player_obj.flip_input then
      return "forward"
    else
      return "back"
    end
  end
  return ""
end

function make_recording_slot()
  return {
    inputs = {},
    delay = 0,
    random_deviation = 0,
    weight = 1,
  }
end

recording_slots = {}
for i = 1, recording_slot_count do
  table.insert(recording_slots, make_recording_slot())
end

recording_slots_names = {}
for i = 1, #recording_slots do
  table.insert(recording_slots_names, "slot "..i)
end

local recording = {
  backup_recordings = backup_recordings,
  restore_recordings = restore_recordings
}

setmetatable(recording, {
  __index = function(_, key)
    if key == "training" then
      return settings.training
    elseif key == "screen_y" then
      return screen_y
    elseif key == "screen_scale" then
      return screen_scale
    end
  end,

  __newindex = function(_, key, value)
    if key == "settings" then
      settings = value
    elseif key == "frame_data_loaded" then
      frame_data_loaded = value
    else
      rawset(recording, key, value)
    end
  end
})

return recording