--interacts with settings file
local saved_path = "saved/"
local recordings_path = "saved/recordings/"
local training_settings_file = "training_settings.json"

local training = {}

local function save_training_data()
  if not write_object_to_json_file(training, saved_path..training_settings_file, true) then
    print(string.format("Error: Failed to save training settings to \"%s\"", training_settings_file))
  end
end

local function load_training_data()
  local settings = read_object_from_json_file(saved_path..training_settings_file)

  if settings == nil then
    settings = {}
  end

  for key, value in pairs(settings) do
    training[key] = value
  end
end


load_training_data()

local settings_module = {
  load_training_data = load_training_data,
  save_training_data = save_training_data,
  saved_path = saved_path,
  recordings_path = recordings_path,
}

setmetatable(settings_module, {
  __index = function(_, key)
    if key == "training" then
      return training
    elseif key == "counter_attack" then
      return training.counter_attack
    end
  end,

  __newindex = function(_, key, value)
    if key == "training" then
      training = value
    elseif key == "counter_attack" then
      training.counter_attack = value
    else
      rawset(settings_module, key, value)
    end
  end
})

return settings_module