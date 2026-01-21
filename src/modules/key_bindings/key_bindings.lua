local settings = require("src.settings")
local menu_items = require("src.ui.menu_items")
local menu = require("src.ui.menu")
local draw = require("src.ui.draw")
local training = require("src.training")
local character_select = require("src.control.character_select")
local inputs = require("src.control.inputs")
local utils = require("src.data.utils")

local key_bindings
local module_name = "key_bindings"

local is_enabled = settings.modules.key_bindings.is_enabled

local max_hotkeys = 9
local command_names = {
   "none", "character_select", "swap_controls", "play_player_recording", "play_dummy_recording",
   "use_player_counterattack", "use_dummy_counterattack"
}
local command_menu_names = {}
for _, name in ipairs(command_names) do command_menu_names[#command_menu_names + 1] = "key_bindings_" .. name end

local lua_hotkey_items = {}

local function use_counterattack(player)
   local counterattack_data = utils.create_move_data_from_selection(settings.training.counter_attack[player.char_str], player)
   local sequence = inputs.create_input_sequence(counterattack_data)
   inputs.queue_input_sequence(player, sequence, 0, true)
end

local function play_recording(player)
   local recording_slots = settings.recordings[player.char_str] or {}
   local slot = recording_slots[settings.training.current_recording_slot]
   if slot then
      inputs.queue_input_sequence(player, slot.inputs, 0, true)
   end
end

local commands = {
   none = nil,
   character_select = character_select.start_character_select_sequence,
   swap_controls = menu.swap_controls,
   play_player_recording = function() play_recording(training.player) end,
   play_dummy_recording = function() play_recording(training.dummy) end,
   use_player_counterattack = function() use_counterattack(training.player) end,
   use_dummy_counterattack = function() use_counterattack(training.dummy) end,
}

local function use_hotkey(n)
   if is_enabled then
      local command_key = command_names[settings.modules.key_bindings.hotkeys[n]]
      local command = commands[command_key]
      if command then command() end
   end
end

local function init() end

local function after_menu_created() for i, item in ipairs(lua_hotkey_items) do item.parent_menu = menu.main_menu end end

local function update() end

local function update_menu()
   local max_width = 0
   for i, item in ipairs(lua_hotkey_items) do
      local w, h = draw.get_text_dimensions_multiple(item.name)
      if w > max_width then max_width = w end
   end
   for i, item in ipairs(lua_hotkey_items) do item.column_width = max_width + 10 end
end

local function create_menu()
   local function default_is_enabled() return menu.is_initialized and is_enabled end
   local function default_is_unselectable() return not (menu.is_initialized or is_enabled) end
   for i = 1, max_hotkeys do
      local button_text = {"key_bindings_lua_hotkey", tostring(i), ": "}
      local button = menu_items.Popup_Selection_Menu_Item:new(button_text, menu.main_menu,
                                                              settings.modules.key_bindings.hotkeys, i,
                                                              command_menu_names, 1)
      button.is_enabled = default_is_enabled
      button.is_unselectable = default_is_unselectable

      lua_hotkey_items[#lua_hotkey_items + 1] = button
   end
   return {name = "key_bindings_key_bindings", entries = lua_hotkey_items}
end

local function toggle()
   is_enabled = not is_enabled
   settings.modules.key_bindings.is_enabled = is_enabled
end

key_bindings = {
   name = module_name,
   init = init,
   after_menu_created = after_menu_created,
   update = update,
   toggle = toggle,
   update_menu = update_menu,
   create_menu = create_menu,
   use_hotkey = use_hotkey
}

setmetatable(key_bindings, {
   __index = function(_, key) if key == "is_enabled" then return is_enabled end end,

   __newindex = function(_, key, value)
      if key == "is_enabled" then
         is_enabled = value
      else
         rawset(key_bindings, key, value)
      end
   end
})

return key_bindings
