-- interacts with settings files
local game_data = require("src.modules.game_data")
local tools = require("src.tools")

local saved_path = "saved/"
local data_path = "data/"
local framedata_path = data_path .. game_data.rom_name .. "/framedata/"
local framedata_file_ext = "_framedata.json"
local framedata_bin_file = "framedata.msgpack"
local load_first_bin_file = "load_first.msgpack"
local text_bin_file = "text.msgpack"
local images_bin_file = "images.msgpack"
local recordings_path = "saved/recordings/"
local training_settings_file = "training_settings.json"
local special_training_settings_file = "special_training_settings.json"
local training_settings_default_file = "training_settings_default.json"
local special_training_default_settings_file = "special_training_settings_default.json"
local themes_path = "data/themes.json"
local recordings_file = "recordings.json"

local training = {}
local special_training = {}
local recordings = {}

local lang_code = {"en", "jp"}

local function save_training_data()
   if not tools.write_object_to_json_file(training, saved_path .. training_settings_file, true) then
      print(string.format("Error: Failed to save training settings to \"%s\"", training_settings_file))
   end
   if not tools.write_object_to_json_file(special_training, saved_path .. special_training_settings_file, true) then
      print(string.format("Error: Failed to save training settings to \"%s\"", special_training_settings_file))
   end
   if not tools.write_object_to_json_file(recordings, saved_path .. recordings_file, true) then
      print(string.format("Error: Failed to save training settings to \"%s\"", recordings_file))
   end
end


local function upgrade_version()
end
local function cmp(a, b)
    local a1,a2,a3 = a:match("(%d+)%.(%d+)%.(%d+)")
    local b1,b2,b3 = b:match("(%d+)%.(%d+)%.(%d+)")
    a1,a2,a3 = tonumber(a1), tonumber(a2), tonumber(a3)
    b1,b2,b3 = tonumber(b1), tonumber(b2), tonumber(b3)
    if a1 ~= b1 then return a1 < b1 end
    if a2 ~= b2 then return a2 < b2 end
    return a3 < b3
end

local function load_training_data()
   local training_settings = tools.read_object_from_json_file(saved_path .. training_settings_file)
   -- no file then create defaults
   if training_settings and training_settings.version then
      training = training_settings
   end
   if not training_settings or not training_settings.version then
      training_settings = tools.read_object_from_json_file(saved_path .. training_settings_default_file)
      if not training_settings then training_settings = {} end
   end
   training = training_settings

   local special_training_settings = tools.read_object_from_json_file(saved_path .. special_training_settings_file)
   if not special_training_settings then
      special_training_settings = tools.read_object_from_json_file(saved_path .. special_training_default_settings_file)
      if not special_training_settings then special_training_settings = {} end
   end
   special_training = special_training_settings

   local recordings_settings = tools.read_object_from_json_file(saved_path .. recordings_file)
   if recordings_settings then recordings = recordings_settings end
end

load_training_data()

local settings_module = {
   saved_path = saved_path,
   data_path = data_path,
   framedata_path = framedata_path,
   framedata_file_ext = framedata_file_ext,
   framedata_bin_file = framedata_bin_file,
   load_first_bin_file = load_first_bin_file,
   text_bin_file = text_bin_file,
   images_bin_file = images_bin_file,
   recordings_path = recordings_path,
   themes_path = themes_path,
   load_training_data = load_training_data,
   save_training_data = save_training_data
}

setmetatable(settings_module, {
   __index = function(_, key)
      if key == "training" then
         return training
      elseif key == "special_training" then
         return special_training
      elseif key == "recordings" then
         return recordings
      elseif key == "counter_attack" then
         return training.counter_attack
      elseif key == "language" then
         return lang_code[training.language]
      end
   end,

   __newindex = function(_, key, value)
      if key == "training" then
         training = value
      elseif key == "special_training" then
         special_training = value
      elseif key == "recordings" then
         recordings = value
      elseif key == "counter_attack" then
         training.counter_attack = value
      else
         rawset(settings_module, key, value)
      end
   end
})

return settings_module
