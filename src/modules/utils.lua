local framedata = require("src.modules.framedata")
local stage_data = require("src.modules.stage_data")
local move_data = require("src.modules.move_data")
local tools = require("src.tools")

local character_specific = framedata.character_specific

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

local function is_in_opponent_throw_range(player, tolerance)
   tolerance = tolerance or 0
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local opponent_throw_range = framedata.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral") or 40
   if opponent_throw_range - tolerance >= dist - character_specific[player.char_str].pushbox_width / 2 then
      return true
   end
   return false
end

local function get_box_connection_distance(attacker, attack_boxes, defender, defender_boxes, box_types, get_closest)
   box_types = box_types or {"vulnerability", "ext.vulnerability"}
   local hurt_boxes = tools.get_boxes(defender_boxes, box_types)
   if not hurt_boxes then return nil end

   local furthest = 0
   local relevant_box

   for _, hit_box in ipairs(attack_boxes) do
      local hit_b = tools.format_box(hit_box)
      if math.abs(hit_b.left) > furthest then
         furthest = math.abs(hit_b.left)
         relevant_box = hit_b
      end
   end

   if not relevant_box then return 0 end

   furthest = 0
   local closest = -1
   for __, hurt_box in ipairs(hurt_boxes) do
      local hurt_b = tools.format_box(hurt_box)
      if not get_closest then
         if not (hurt_b.bottom + hurt_b.height < relevant_box.bottom or hurt_b.bottom > relevant_box.bottom +
             relevant_box.height) then
            if math.abs(hurt_b.left) > furthest then furthest = math.abs(hurt_b.left) end
         end
      else
         if closest == -1 then closest = math.abs(hurt_b.left) end
         if not (hurt_b.bottom + hurt_b.height < relevant_box.bottom or hurt_b.bottom > relevant_box.bottom +
             relevant_box.height) then
            if math.abs(hurt_b.left) < closest then closest = math.abs(hurt_b.left) end
         end
      end
   end

   if get_closest then return closest else return furthest end
end

local motion_to_menu_text = {
   dir_5 = "menu_neutral",
   dir_6 = "menu_forward",
   dir_3 = "menu_down_forward",
   dir_2 = "menu_down",
   dir_1 = "menu_down_back",
   dir_4 = "menu_back",
   dir_7 = "menu_jump_back",
   dir_8 = "menu_jump_neutral",
   dir_9 = "menu_jump_forward",
   sjump_back = "menu_sjump_back",
   sjump_neutral = "menu_sjump_neutral",
   sjump_forward = "menu_sjump_forward",
   back_dash = "menu_back_dash",
   forward_dash = "menu_forward_dash",
   kara_throw = "menu_kara_throw"
}
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
      data.name = motion_to_menu_text[data.motion]
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
   elseif type == 5 then
      data.name = "recording"
   end
   return data
end

return {
   has_projectiles = has_projectiles,
   get_stage_limits = get_stage_limits,
   get_stage_screen_limits = get_stage_screen_limits,
   get_forward_walk_distance = get_forward_walk_distance,
   get_backward_walk_distance = get_backward_walk_distance,
   is_in_opponent_throw_range = is_in_opponent_throw_range,
   get_box_connection_distance = get_box_connection_distance,
   create_move_data_from_selection = create_move_data_from_selection
}
