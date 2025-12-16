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

local function parse_version(version_str)
   local major, minor, patch = version_str:match("(%d+)%.(%d+)%.(%d+)")
   if not major then return nil end
   return {major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch)}
end

local function compare_versions(v1_str, v2_str)
   local v1 = parse_version(v1_str)
   local v2 = parse_version(v2_str)

   if not v1 or not v2 then return nil, "Invalid version format" end

   if v1.major > v2.major then return 1 end
   if v1.major < v2.major then return -1 end

   if v1.minor > v2.minor then return 1 end
   if v1.minor < v2.minor then return -1 end

   if v1.patch > v2.patch then return 1 end
   if v1.patch < v2.patch then return -1 end

   return 0
end

local function is_in_range(version, min_version, max_version)
   local compare_min = compare_versions(version, min_version)
   local compare_max = compare_versions(version, max_version)
   return (compare_min == 0 or compare_min == 1) and (compare_max == 0 or compare_max == -1)
end

local function needs_upgrade(current_version, target_version)
   return compare_versions(current_version, target_version) == -1
end

local upgrade_rules = {
   {
      min = "1.0.0",
      max = "1.0.3",
      target = "1.1.0",
      upgrade = function(settings)
         settings.training.version = "1.1.0"
         settings.training.recording_player_positioning = false
         settings.training.recording_dummy_positioning = false
         settings.special_training.defense.characters["ken"].next_attack_delay = 20
         settings.special_training.unblockables = require("src.training.unblockables_tables").create_settings()
         for _, char_str in ipairs(game_data.characters) do
            for __, slot in ipairs(settings.recordings[char_str]) do
               slot.player_position = {430, 0}
               slot.dummy_offset = {170, 0}
               slot.screen_position = {512, 0}
            end
            settings.special_training.jumpins.characters[char_str].next_attack_delay = 30
            for __, jump in ipairs(settings.special_training.jumpins.characters[char_str].jumps) do
               jump.dummy_offset_index = 1
               jump.attack_delay_index = 1
            end
            settings.special_training.footsies.characters[char_str].accuracy_mode = 1
            settings.special_training.footsies.characters[char_str].accuracy_index = 1
            settings.special_training.footsies.characters[char_str].dist_judgement_mode = 1
            settings.special_training.footsies.characters[char_str].dist_judgement_index = 1
            settings.special_training.footsies.characters[char_str].next_attack_delay = {0,10}
            settings.special_training.footsies.characters[char_str].next_attack_delay_mode = 2
            settings.special_training.footsies.characters[char_str].next_attack_delay_index = 1
            settings.special_training.footsies.characters[char_str].sa_after_parry = 1
            for __, foot in ipairs(settings.special_training.footsies.characters[char_str]) do
               foot.accuracy = {
                  tools.round_to_nearest(foot.accuracy[1], 5), tools.round_to_nearest(foot.accuracy[2], 5)
               }
               foot.dist_judgement = {
                  tools.round_to_nearest(foot.dist_judgement[1], 5), tools.round_to_nearest(foot.dist_judgement[2], 5)
               }
            end
         end
      end
   }
}

local function find_upgrade_rule(current_version, target_version)
   for _, rule in ipairs(upgrade_rules) do
      if is_in_range(current_version, rule.min, rule.max) and compare_versions(rule.target, target_version) <= 0 then
         return rule
      end
   end
   return nil
end

local function upgrade_settings(settings, target_version)
   local current_version = settings.training.version or "1.0.0"
   local start_version = current_version

   local sorted_rules = {}
   for _, rule in ipairs(upgrade_rules) do table.insert(sorted_rules, rule) end
   table.sort(sorted_rules, function(a, b) return compare_versions(a.target, b.target) == -1 end)

   local max_iterations = 100
   local iteration = 0

   while needs_upgrade(current_version, target_version) and iteration < max_iterations do
      local rule = find_upgrade_rule(current_version, target_version)
      if not rule then
         print("Warning: No upgrade path found from " .. current_version)
         break
      end
      rule.upgrade(settings)
      current_version = settings.training.version
      iteration = iteration + 1
   end

   print("Upgraded settings v" .. start_version .. " -> v" .. settings.training.version)
   save_training_data()
end

local function load_training_data()
   local training_settings = tools.read_object_from_json_file(saved_path .. training_settings_file)
   -- no file then create defaults
   if training_settings and training_settings.version then training = training_settings end
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
   if recordings_settings then recordings = recordings_settings
   else
      recordings = require("src.control.recording").create_default_settings()
   end

   if needs_upgrade(training.version, game_data.script_version) then
      local settings = {training = training, special_training = special_training, recordings = recordings}
      upgrade_settings(settings, game_data.script_version)
   end
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
