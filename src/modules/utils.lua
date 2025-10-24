local framedata = require("src.modules.framedata")
local stage_data = require("src.modules.stage_data")
local move_data = require("src.modules.move_data")
local tools = require("src.tools")

local character_specific = framedata.character_specific

local function get_side(player_x, opponent_x, player_previous_x, opponent_previous_x)
   local diff = math.floor(player_x) - math.floor(opponent_x)
   if diff == 0 then diff = math.floor(player_previous_x) - math.floor(opponent_previous_x) end
   return diff > 0 and 2 or 1
end

local function has_projectiles(player)
   for _, projectile in pairs(require("src.gamestate").projectiles) do
      if (projectile.emitter_id == player.id or (projectile.emitter_id == player.other.id and projectile.is_converted)) then
         return true
      end
   end
   return false
end

local function get_stage_limits(stage, char_str)
   local limit_left = stage_data.stages[stage].left + framedata.character_specific[char_str].corner_offset_left
   local limit_right = stage_data.stages[stage].right - framedata.character_specific[char_str].corner_offset_right
   return limit_left, limit_right
end

local function get_stage_screen_limits(stage)
   local limit_left = stage_data.stages[stage].screen_left
   local limit_right = stage_data.stages[stage].screen_right
   return limit_left, limit_right
end

local function get_forward_walk_distance(player, n_frames)
   return character_specific[player.char_str].forward_walk_speed * 0.5 + math.max(n_frames - 1, 0) *
              character_specific[player.char_str].forward_walk_speed
end

local function get_backward_walk_distance(player, n_frames)
   return math.abs(n_frames * character_specific[player.char_str].backward_walk_speed)
end

local function is_in_opponent_throw_range(player)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local opponent_throw_range = framedata.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral") or 40
   if opponent_throw_range >= dist - character_specific[player.char_str].pushbox_width / 2 then return true end
   return false
end

local function create_move_data_from_selection(move_selection_settings, player)
   local type = move_selection_settings.type
   local data = {char_str = player.char_str, type = type, name = "normal", button = nil}
   if type == 2 then
      local menu_tables = require("src.ui.menu_tables")
      data.motion = menu_tables.move_selection_motion[move_selection_settings.motion]
      local normal_buttons = menu_tables.move_selection_normal_button_default
      local button_inputs
      if move_selection_settings.motion == 15 then
         button_inputs = move_data.get_buttons_by_move_name(player.char_str, "kara_throw") or {}
         normal_buttons = tools.input_to_text(button_inputs)
      end
      data.button = normal_buttons[move_selection_settings.normal_button]
      if move_selection_settings.motion == 15 then
         data.inputs = button_inputs[move_selection_settings.normal_button] or {}
      end
   elseif type == 3 then
      local special_names = move_data.get_special_and_sa_names(player.char_str, player.selected_sa)
      data.name = special_names[move_selection_settings.special]
      local special_buttons = move_data.get_buttons_by_move_name(player.char_str, data.name) or {}
      data.button = special_buttons[move_selection_settings.special_button]
      data.move_type = move_data.get_type_by_move_name(player.char_str, data.name)
      data.inputs = move_data.get_move_inputs_by_name(player.char_str, data.name, data.button)
   elseif type == 4 then
      local option_select_names = move_data.get_option_select_names()
      data.name = option_select_names[move_selection_settings.option_select]
   end
   return data
end

return {
   get_side = get_side,
   has_projectiles = has_projectiles,
   get_stage_limits = get_stage_limits,
   get_stage_screen_limits = get_stage_screen_limits,
   get_forward_walk_distance = get_forward_walk_distance,
   get_backward_walk_distance = get_backward_walk_distance,
   is_in_opponent_throw_range = is_in_opponent_throw_range,
   create_move_data_from_selection = create_move_data_from_selection
}
