local gamestate = require("src/gamestate")
local training = require("src/training")



training_settings_file = "training_settings.json"


training_settings = {
  pose = 1,
  blocking_style = 1,
  blocking_mode = 1,
  prefer_down_parry = false,
  tech_throws_mode = 1,
  red_parry_hit_count = 1,
  counter_attack_type_index = 1,
  counter_attack_stick = 1,
  counter_attack_button = 1,
  fast_wakeup_mode = 1,
  infinite_time = true,
  life_mode = 1,
  meter_mode = 1,
  p1_meter = 0,
  p2_meter = 0,
  infinite_sa_time = false,
  stun_mode = 1,
  p1_stun_reset_value = 0,
  p2_stun_reset_value = 0,
  stun_reset_delay = 20,
  display_input = true,
  display_gauges = false,
  display_input_history = 4,
  display_attack_data = false,
  display_attack_bars = 3,
  display_frame_advantage = false,
  display_hitboxes = false,
  display_distances = false,
  mid_distance_height = 70,
  p1_distances_reference_point = 1,
  p2_distances_reference_point = 2,
  display_red_parry_miss = true,
  auto_crop_recording_start = true,
  auto_crop_recording_end = true,
  current_recording_slot = 1,
  replay_mode = 1,
  music_volume = 10,
  life_refill_delay = 20,
  meter_refill_delay = 20,
  challenge_current_mode = 1,
  fast_forward_intro = true,
  universal_cancel = false,
  infinite_projectiles = false,
  infinite_juggle = false,
  controller_style = 2,
  language = 1,
  force_stage = 1,

  -- special training
  special_training_current_mode = 1,
  charge_follow_character = true,
  special_training_parry_forward_on = true,
  special_training_parry_down_on = true,
  special_training_parry_air_on = true,
  special_training_parry_antiair_on = true,
  special_training_charge_overcharge_on = false,
}



debug_settings = {
  show_predicted_hitbox = false,
  record_framedata = false,
  record_idle_framedata = false,
  record_wakeupdata = false,
  debug_character = "",
  debug_move = "",
}


function save_training_data()
  backup_recordings(training.dummy)
  if not write_object_to_json_file(training_settings, saved_path..training_settings_file) then
    print(string.format("Error: Failed to save training settings to \"%s\"", training_settings_file))
  end
end

function load_training_data()
  local settings = read_object_from_json_file(saved_path..training_settings_file)

  if settings == nil then
    settings = {}
  end
  -- update old versions data
  if settings.recordings then
    for _, value in pairs(settings.recordings) do
      for i, slot in ipairs(value) do
        if value[i].inputs == nil then
          value[i] = make_recording_slot()
        else
          slot.delay = slot.delay or 0
          slot.random_deviation = slot.random_deviation or 0
          slot.weight = slot.weight or 1
        end
      end
    end
  end

  for key, value in pairs(settings) do
    training_settings[key] = value
  end

  restore_recordings()

--   update_counter_attack_settings()
end

function backup_recordings(dummy)
  -- Init base table
  if training_settings.recordings == nil then
    training_settings.recordings = {}
  end
  for _, value in ipairs(Characters) do
    if training_settings.recordings[value] == nil then
      training_settings.recordings[value] = {}
      for i = 1, #recording_slots do
        table.insert(training_settings.recordings[value], make_recording_slot())
      end
    end
  end

  if dummy.char_str ~= "" then
    training_settings.recordings[dummy.char_str] = recording_slots
  end
end

function restore_recordings()
  local char = gamestate.P2.char_str
  if char and char ~= "" then
    local recording_count = #recording_slots
    if training_settings.recordings then
      recording_slots = training_settings.recordings[char] or {}
    end
      local missing_slots = recording_count - #recording_slots
    for i = 1, missing_slots do
        table.insert(recording_slots, make_recording_slot())
    end
  end
  update_current_recording_slot_frames()
end