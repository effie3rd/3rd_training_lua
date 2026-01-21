local opponents = {"ken", "yang"}
local opponents_menu_names = {}
local defense_data = {}

local function get_menu_setup_names(char_str) return defense_data[char_str].menu_setup_names end

local function get_menu_followup_names(char_str) return defense_data[char_str].menu_followup_names end

local function get_followup_data(char_str) return defense_data[char_str].followups end

local function get_menu_followup_followup_names(char_str, i) return defense_data[char_str].menu_followup_followup_names[i] end

local function reset_followups(settings, char_str)
   local setups_object = settings.modules.defense.characters[char_str].setups
   local all_selected = true
   for i, setup in ipairs(setups_object) do
      if not setup then all_selected = false end
      setups_object[i] = true
   end
   local followups_object = settings.modules.defense.characters[char_str].followups
   for i, followups in ipairs(followups_object) do
      for j, followup in ipairs(followups) do
         if not followup then all_selected = false end
         followups[j] = true
      end
   end
   if all_selected then
      for i, setup in ipairs(setups_object) do setups_object[i] = false end
      for i, followups in ipairs(followups_object) do
         for j, followup in ipairs(followups) do followups[j] = false end
      end
   end
end

local function reset_weights(char_str)
   for _, setup in ipairs(defense_data[char_str].setups) do setup.weight = setup.default_weight end
   for _, followup_list in ipairs(defense_data[char_str].followups) do
      for _, followup in ipairs(followup_list.list) do followup.weight = followup.default_weight end
   end
end

local function get_defense_data(char_str)
   defense_data[char_str].init()
   return defense_data[char_str]
end

local function create_reference_map(data)
   local followup_index_map = {}
   local followup_map = {}

   for i, followup_list in ipairs(data.followups) do
      followup_index_map[followup_list.list] = i
      followup_map[i] = {setups = {}, followups = {}}
   end
   for i, setup in ipairs(data.setups) do
      if setup.action:followups() then
         local followup_index = followup_index_map[setup.action:followups()]
         table.insert(followup_map[followup_index].setups, i)
      end
   end

   for i, followup_list in ipairs(data.followups) do
      for j, followup in ipairs(followup_list.list) do
         if followup.action:followups() then
            local followup_index = followup_index_map[followup.action:followups()]
            table.insert(followup_map[followup_index].followups, {i, j})
         end
      end
   end
   return followup_map
end

local function get_reference_map(char_str)
   return defense_data[char_str].reference_map
end

local function create_character_settings(char_str)
   local char_settings = {setups = {}, followups = {}, learning = true, next_attack_delay = 20, score = 0}
   if defense_data[char_str] then
      for _, setup in ipairs(defense_data[char_str].setups) do
         char_settings.setups[#char_settings.setups + 1] = true
      end
      for _, followup_list in ipairs(defense_data[char_str].followups) do
         char_settings.followups[#char_settings.followups + 1] = {}
         local current_followup_list = char_settings.followups[#char_settings.followups]
         for _, followup in ipairs(followup_list.list) do
            current_followup_list[#current_followup_list + 1] = true
         end
      end
   end
   return char_settings
end

for _, char in pairs(opponents) do
   local data = require("src.training.defense.defense_" .. char)
   if data then
      defense_data[char] = data
      defense_data[char].reference_map = create_reference_map(data)
   end
end

for _, char in ipairs(opponents) do opponents_menu_names[#opponents_menu_names + 1] = "menu_" .. char end

return {
   opponents = opponents,
   opponents_menu_names = opponents_menu_names,
   get_menu_setup_names = get_menu_setup_names,
   get_menu_followup_names = get_menu_followup_names,
   get_followup_data = get_followup_data,
   get_menu_followup_followup_names = get_menu_followup_followup_names,
   reset_followups = reset_followups,
   reset_weights = reset_weights,
   get_defense_data = get_defense_data,
   get_reference_map = get_reference_map,
   create_character_settings = create_character_settings
}
