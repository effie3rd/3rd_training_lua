--interacts with settings file
local saved_path = "saved/"
local training_settings_file = "training_settings.json"

local training = {}

local function save_training_data()
  if not write_object_to_json_file(training, saved_path..training_settings_file) then
    print(string.format("Error: Failed to save training settings to \"%s\"", training_settings_file))
  end
end

local function load_training_data()
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
    training[key] = value
  end

--   update_counter_attack_settings()
end


load_training_data()

local settings_module = {
  load_training_data = load_training_data,
  save_training_data = save_training_data
}

setmetatable(settings_module, {
  __index = function(_, key)
    if key == "training" then
      return training
    end
  end,

  __newindex = function(_, key, value)
    if key == "training" then
      training = value
    else
      rawset(settings_module, key, value)
    end
  end
})

return settings_module