local gamestate = require("src.gamestate")
local frame_data = require("src.modules.framedata")
local move_data = require("src.modules.move_data")
local stage_data = require("src.modules.stage_data")
local inputs = require("src.control.inputs")
local advanced_control = require("src.control.advanced_control")

local Delay = advanced_control.Delay
local is_idle_timing, is_wakeup_timing, is_landing_timing = advanced_control.is_idle_timing,
                                                            advanced_control.is_wakeup_timing,
                                                            advanced_control.is_landing_timing
local queue_input_sequence_and_wait, all_commands_queued = advanced_control.queue_input_sequence_and_wait,
                                                           advanced_control.all_commands_queued
local character_specific = frame_data.character_specific

local opponents = {"ken"}
local opponents_menu = {}
local defense_data = {}

for _, char in pairs(opponents) do
   local data = require("src.training.defense.defense_" .. char)
   if data then defense_data[char] = data end
end

for char, _ in pairs(defense_data) do opponents_menu[#opponents_menu + 1] = "menu_" .. char end

local function get_setup_names(char_str) return defense_data[char_str].setup_names end

local function get_followup_names(char_str) return defense_data[char_str].followup_names end

local function get_followup_data(char_str) return defense_data[char_str].followups end

local function get_followup_followup_names(char_str, i) return defense_data[char_str].followup_followup_names[i] end

local function reset_followups(settings, char_str)
   local setups_object = settings.special_training.defense.characters[char_str].setups
   local all_selected = true
   for i, setup in ipairs(setups_object) do
      if not setup then all_selected = false end
      setups_object[i] = true
   end
   local followups_object = settings.special_training.defense.characters[char_str].followups
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
   reset_weights(char_str)
   return defense_data[char_str]
end

return {
   opponents = opponents,
   opponents_menu = opponents_menu,
   get_setup_names = get_setup_names,
   get_followup_names = get_followup_names,
   get_followup_data = get_followup_data,
   get_followup_followup_names = get_followup_followup_names,
   reset_followups = reset_followups,
   reset_weights = reset_weights,
   get_defense_data = get_defense_data
}
