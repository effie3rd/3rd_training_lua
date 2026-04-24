local game_data = require("src.data.game_data")
local modules = require("src.modules")
local tools = require("src.tools")

local saved_path = "saved/"
local data_path = "data/"
local training_path = "src/training/"
local modules_path = "src/modules/"
local training_require_path = "src.training"
local modules_require_path = "src.modules"
local modules_settings_file = "settings.json"
local modules_default_settings_file = "settings_default.json"
local spectator_settings_file = "spectator_settings.json"
local spectator_settings_default_file = "spectator_settings_default.json"
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

local training_settings = {}
local modules_settings = {}
local recordings_settings = {}
local spectator_settings = {}

local lang_code = {"en", "jp"}

local function save_recordings_data()
   if not tools.write_object_to_json_file(recordings_settings, saved_path .. recordings_file, true) then
      print(string.format("Error: Failed to save training settings to \"%s\"", saved_path .. recordings_file))
   end
   for _, module_name in ipairs(modules.extra_module_names) do
      if not tools.write_object_to_json_file(modules_settings[module_name],
                                             modules_path .. module_name .. "/" .. modules_settings_file, true) then
         print(string.format("Error: Failed to save training settings to \"%s\"",
                             modules_path .. module_name .. "/" .. modules_settings_file))
      end
   end
end

local function save_training_data()
   if not tools.write_object_to_json_file(training_settings, saved_path .. training_settings_file, true) then
      print(string.format("Error: Failed to save training settings to \"%s\"", saved_path .. training_settings_file))
   end
   for _, module_name in ipairs(modules.training_mode_names) do
      if not tools.write_object_to_json_file(modules_settings[module_name],
                                             training_path .. module_name .. "/" .. modules_settings_file, true) then
         print(string.format("Error: Failed to save training settings to \"%s\"",
                             training_path .. module_name .. "/" .. modules_settings_file))
      end
   end
   for _, module_name in ipairs(modules.extra_module_names) do
      if not tools.write_object_to_json_file(modules_settings[module_name],
                                             modules_path .. module_name .. "/" .. modules_settings_file, true) then
         print(string.format("Error: Failed to save training settings to \"%s\"",
                             modules_path .. module_name .. "/" .. modules_settings_file))
      end
   end
   save_recordings_data()
end

local function save_spectator_data()
   if not tools.write_object_to_json_file(spectator_settings, saved_path .. spectator_settings_file, true) then
      print(string.format("Error: Failed to save training settings to \"%s\"", saved_path .. spectator_settings_file))
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
         local special_training_settings =
             tools.read_object_from_json_file(saved_path .. special_training_settings_file)
         if not special_training_settings then
            special_training_settings = tools.read_object_from_json_file(saved_path ..
                                                                             special_training_default_settings_file)
            if not special_training_settings then special_training_settings = {} end
         end
         settings.special_training = special_training_settings
         settings.training.recording_player_positioning = false
         settings.training.recording_dummy_positioning = false
         settings.special_training.defense.characters["ken"].next_attack_delay = 20
         settings.special_training.unblockables =
             require("src.training.unblockables.unblockables_tables").create_settings()
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
            settings.special_training.footsies.characters[char_str].next_attack_delay = {0, 10}
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
   }, {
      min = "1.1.0",
      max = "1.1.0",
      target = "1.2.0",
      upgrade = function(settings)
         settings.training.version = "1.2.0"
         settings.recordings.version = "1.2.0"
         local special_training_settings =
             tools.read_object_from_json_file(saved_path .. special_training_settings_file)
         settings.special_training = special_training_settings or {}
         local training_mode_names = {"defense", "jumpins", "footsies", "unblockables", "geneijin"}
         for _, module_name in ipairs(training_mode_names) do
            if settings.special_training[module_name] then
               settings.modules[module_name] = settings.special_training[module_name]
               settings.modules[module_name].version = "1.2.0"
            end
         end
         settings.modules.defense.characters.yang =
             require("src.training.defense.defense_tables").create_character_settings("yang")
         settings.training.training_mode_index = settings.training.special_training_mode or 1
         settings.training.special_training_mode = nil
         settings.training.modules_index = 1
         settings.training.blocking_direction = 1
         settings.training.display_guard_jump_input = 1
         settings.training.display_hitboxes_ab = false

         -- remove unused files
         print("Removing unused files:")
         local file_data = {
            {path = "src/", file_names = {"special_modes.lua"}}, {
               path = "src/modules/",
               file_names = {
                  "attack_data.lua", "framedata.lua", "game_data.lua", "prediction.lua", "stage_data.lua",
                  "frame_advantage.lua", "framedata_meta.lua", "move_data.lua", "record_framedata.lua", "utils.lua"
               }
            }, {
               path = "src/training/",
               file_names = {
                  "defense_tables.lua", "denjin_tables.lua", "footsies_tables.lua", "geneijin_tables.lua",
                  "jumpins_tables.lua", "unblockables.lua", "defense.lua", "denjin.lua", "footsies.lua", "geneijin.lua",
                  "jumpins.lua", "training_classes.lua", "unblockables_tables.lua"
               }
            },
            {path = "saved/", file_names = {"special_training_settings.json", "special_training_settings_default.json"}}
         }
         for _, data in ipairs(file_data) do
            for _, file_name in ipairs(data.file_names) do
               local ok, err = os.remove(data.path .. file_name)
               if ok then print("Removed:", data.path .. file_name) end
            end
         end
      end
   }, {
      min = "1.2.0",
      max = "1.3.0",
      target = "1.3.1",
      upgrade = function(settings)
         settings.training.version = "1.3.1"
         settings.recordings.version = "1.3.1"
         settings.training.music_volume = tools.round_to_nearest(settings.training.music_volume * 10, 5)
      end
   }, {
      min = "1.3.1",
      max = "1.3.1",
      target = "1.3.2",
      upgrade = function(settings)
         settings.training.version = "1.3.2"
         settings.recordings.version = "1.3.2"
         if not settings.modules.defense.controllers then
            settings.modules.defense.controllers  = { "player", "defense" }
         end
         if not settings.modules.geneijin.controllers then
            settings.modules.geneijin.controllers  = { "player", "geneijin" }
         end
         if not settings.modules.unblockables.controllers then
            settings.modules.unblockables.controllers  = { "player", "unblockables" }
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
   if start_version ~= settings.training.version then
      print("Upgraded v" .. start_version .. " -> v" .. settings.training.version)
      return true
   end
end

local function load_module_settings(module_name, path)
   local new_module_settings = tools.read_object_from_json_file(path .. module_name .. "/" .. modules_settings_file)
   if not new_module_settings then
      new_module_settings =
          tools.read_object_from_json_file(path .. module_name .. "/" .. modules_default_settings_file)
   end
   modules_settings[module_name] = new_module_settings or {}
end

local function load_training_data()
   local loaded_defaults = false
   local upgraded = false

   local new_training_settings = tools.read_object_from_json_file(saved_path .. training_settings_file)
   -- no file then create defaults
   if new_training_settings and not new_training_settings.version then new_training_settings = nil end
   if not new_training_settings then
      new_training_settings = tools.read_object_from_json_file(saved_path .. training_settings_default_file)
      loaded_defaults = new_training_settings ~= nil
   end
   training_settings = new_training_settings or {}
   for _, module_name in ipairs(modules.training_mode_names) do load_module_settings(module_name, training_path) end
   for _, module_name in ipairs(modules.extra_module_names) do load_module_settings(module_name, modules_path) end

   local new_recordings_settings = tools.read_object_from_json_file(saved_path .. recordings_file)
   if not new_recordings_settings then
      new_recordings_settings = require("src.control.recording").create_default_settings()
   end
   recordings_settings = new_recordings_settings or {}

   if needs_upgrade(training_settings.version, game_data.script_version) then
      local settings = {training = training_settings, modules = modules_settings, recordings = recordings_settings}
      upgraded = upgrade_settings(settings, game_data.script_version)
   end

   if loaded_defaults or upgraded then save_training_data() end
end

local function load_spectator_data()
   local loaded_defaults = false

   local new_spectator_settings = tools.read_object_from_json_file(saved_path .. spectator_settings_file)
   if new_spectator_settings and new_spectator_settings.version and type(new_spectator_settings.version) == "number" then
      new_spectator_settings = nil
   end
   if not new_spectator_settings then
      new_spectator_settings = tools.read_object_from_json_file(saved_path .. spectator_settings_default_file)
      loaded_defaults = new_spectator_settings ~= nil
   end
   spectator_settings = new_spectator_settings or {}
   for _, module_name in ipairs(modules.extra_module_names) do load_module_settings(module_name, modules_path) end

   if loaded_defaults then save_spectator_data() end
end

local settings_module = {
   saved_path = saved_path,
   data_path = data_path,
   training_path = training_path,
   modules_path = modules_path,
   training_require_path = training_require_path,
   modules_require_path = modules_require_path,
   framedata_path = framedata_path,
   framedata_file_ext = framedata_file_ext,
   framedata_bin_file = framedata_bin_file,
   load_first_bin_file = load_first_bin_file,
   text_bin_file = text_bin_file,
   images_bin_file = images_bin_file,
   recordings_path = recordings_path,
   themes_path = themes_path,
   lang_code = lang_code,
   save_recordings_data = save_recordings_data,
   load_training_data = load_training_data,
   save_training_data = save_training_data,
   load_spectator_data = load_spectator_data,
   save_spectator_data = save_spectator_data
}

setmetatable(settings_module, {
   __index = function(_, key)
      if key == "training" then
         return training_settings
      elseif key == "modules" then
         return modules_settings
      elseif key == "recordings" then
         return recordings_settings
      elseif key == "counter_attack" then
         return training_settings.counter_attack
      elseif key == "spectator" then
         return spectator_settings
      elseif key == "controller_style" then
         return training_settings.controller_style and training_settings.controller_style --
         or spectator_settings.controller_style and spectator_settings.controller_style
      elseif key == "theme" then
         return training_settings.theme and training_settings.theme --
         or spectator_settings.theme and spectator_settings.theme
      elseif key == "language" then
         return training_settings.language and training_settings.language --
         or spectator_settings.language and spectator_settings.language
      elseif key == "language_tag" then
         return training_settings.language and lang_code[training_settings.language] --
         or spectator_settings.language and lang_code[spectator_settings.language]
      end
   end,

   __newindex = function(_, key, value)
      if key == "training" then
         training_settings = value
      elseif key == "modules" then
         modules_settings = value
      elseif key == "recordings" then
         recordings_settings = value
      elseif key == "counter_attack" then
         training_settings.counter_attack = value
      elseif key == "spectator" then
         spectator_settings = value
      elseif key == "controller_style" then
         if training_settings.controller_style then
            training_settings.controller_style = value
         else
            spectator_settings.controller_style = value
         end
      elseif key == "theme" then
         if training_settings.theme then
            training_settings.theme = value
         else
            spectator_settings.theme = value
         end
      elseif key == "language" then
         if training_settings.language then
            training_settings.language = value
         else
            spectator_settings.language = value
         end
      else
         rawset(settings_module, key, value)
      end
   end
})

return settings_module
