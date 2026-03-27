local settings = require("src.settings")
local menu_items = require("src.ui.menu_items")
local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local hud = require("src.ui.hud")
local menu = require("src.ui.menu")
local training = require("src.training")
local modes = require("src.modes")
local framedata = require("src.data.framedata")
local utils = require("src.data.utils")
local tools = require("src.tools")
local memory_addresses = require("src.control.memory_addresses")
local Pools = tools.Pools

local distances
local module_name = "distances"

local is_enabled = false
local is_mode_active = false
local should_draw_distances = false
local draw_distances_setting = tools.create_dynamic_value(settings.training, "display_distances")

local previous_settings = { is_enabled = is_enabled, should_draw_distances = should_draw_distances }
local should_disable_positioning = false

local distances_menu = {}
local distances_menu_tables = {
   reference_point = { "distances_origin", "distances_hurtbox", "distances_throwbox", "distances_pushbox" },
}
local distances_line_groups = {}
local display_line_text = {
   en = {},
   jp = {},
}
local line_settings_keys = {}
local REFERENCE_POINT = { ORIGIN = 1, HURTBOX = 2, THROWBOX = 3, PUSHBOX = 4 }

local MODE = { POSITION = 1, SUBPIXEL = 2 }
local edit_position = {
   player = gamestate.P1,
   mode = MODE.POSITION,
   move_speed = 1,
   max_move_speed = 3,
   autofire_delay = 5,
   autofire_rate = 1,
   move_speed_increase_delay = 20,
   moved_left_last_frame = false,
   moved_right_last_frame = false,
   move_left_frame = 0,
   move_right_frame = 0,
   move_start_frame = 0,
}
local num_lines = 3

for i = 1, num_lines do
   display_line_text.en[i] = { "menu_display", " ", "distances_line", " ", tostring(i) }
   display_line_text.jp[i] = { "distances_line", "", tostring(i), "", "menu_display" }
   line_settings_keys[i] = {
      enabled = "line_" .. i .. "_enabled",
      height = "line_" .. i .. "_height",
      p1_reference_point = "line_" .. i .. "_p1_reference_point",
      p2_reference_point = "line_" .. i .. "_p2_reference_point",
   }
end

local default_height = { -5, 60, 120 }

local init

local function get_subpixel_text(n)
   local char = tools.trunc(n)
   local mantissa = n - char
   return char, math.floor(mantissa * 256 + 0.5)
end

local function display_draw_distances(
   p1_object,
   p2_object,
   reference_height,
   p1_reference_point,
   p2_reference_point,
   show_subpixel
)
   local function find_box_x_bounds_at_height(player, height, box_types)
      local px, py = player.pos_x, player.pos_y
      local far_left, far_right = px, px
      local left, right = px, px

      if not box_types or not next(box_types) then
         return px, px
      end
      for _, box in ipairs(player.boxes) do
         box = tools.format_box(box, nil, Pools.draw:alloc())
         if box_types[box.type] then
            local l, r, b, t
            if player.flip_x == 0 then
               l = px + box.left
            else
               l = px - box.left - box.width
            end
            r = l + box.width
            b = py + box.bottom
            t = b + box.height

            if player.flip_x == 0 then
               if l < far_left then
                  far_left = l
                  far_right = r
               end
            else
               if r > far_right then
                  far_left = l
                  far_right = r
               end
            end

            if height >= b and height <= t then
               left = math.min(left, l)
               right = math.max(right, r)
            end
         end
      end

      if left == px or right == px then
         return far_left, far_right
      end

      return left, right
   end

   local function get_line_between_boxes(box1_l, box1_r, box2_l, box2_r)
      if not ((box1_l >= box2_r) or (box1_r <= box2_l)) then
         return false
      end

      if box1_l < box2_l then
         return true, box1_r, box2_l
      else
         return true, box2_r, box1_l
      end
   end

   local function display_distance(p1, p2, height, p1_boxes, p2_boxes, color)
      local y = math.min(p1.pos_y + height, p2.pos_y + height)
      local p1_l, p1_r, p2_l, p2_r = p1.pos_x, p1.pos_x, p2.pos_x, p2.pos_x

      p1_l, p1_r = find_box_x_bounds_at_height(p1, y, p1_boxes)
      p2_l, p2_r = find_box_x_bounds_at_height(p2, y, p2_boxes)

      local line_result, line_l, line_r = get_line_between_boxes(p1_l, p1_r, p2_l, p2_r)

      if line_result then
         local screen_l = draw.game_to_screen_space_x(line_l)
         local screen_r = draw.game_to_screen_space_x(line_r)
         local screen_y = draw.game_to_screen_space_y(y)
         local str = string.format("%d", math.abs(screen_r - screen_l))
         if show_subpixel then
            local char, mantissa = get_subpixel_text(line_r - line_l)
            local str_table = Pools.draw:alloc()
            str_table[1], str_table[2], str_table[3] = char, ".", mantissa
            str = table.concat(str_table)
         else
            str = string.format("%d", tools.trunc(line_r) - tools.trunc(line_l))
         end
         local edges_style = y <= 0 and "up" or y >= 100 and "down" or "both"
         draw.draw_horizontal_text_segment(screen_l, screen_r, screen_y, str, color, 2, edges_style)
      end
   end

   local function get_reference_boxes(reference_point)
      local res = Pools.draw:alloc()
      if reference_point == REFERENCE_POINT.HURTBOX then
         res.vulnerability = true
         res.ext_vulnerability = true
      elseif reference_point == REFERENCE_POINT.THROWBOX then
         res.throwable = true
      elseif reference_point == REFERENCE_POINT.PUSHBOX then
         res.push = true
      end
      return res
   end
   local p1_box_types = get_reference_boxes(p1_reference_point)
   local p2_box_types = get_reference_boxes(p2_reference_point)

   display_distance(p1_object, p2_object, reference_height, p1_box_types, p2_box_types, colors.distances.line)
end

local function draw_distance_lines()
   for i = 1, num_lines do
      if settings.modules.distances[line_settings_keys[i].enabled] then
         display_draw_distances(
            gamestate.P1,
            gamestate.P2,
            settings.modules.distances[line_settings_keys[i].height],
            settings.modules.distances[line_settings_keys[i].p1_reference_point],
            settings.modules.distances[line_settings_keys[i].p2_reference_point],
            settings.modules.distances.show_subpixel
         )
      end
   end
end

local function draw_coordinates()
   if not settings.modules.distances.display_coordinates and not is_mode_active then
      return
   end
   local p1_screen_x, p1_screen_y = draw.game_to_screen_space(gamestate.P1.pos_x, gamestate.P1.pos_y)
   local p2_screen_x, p2_screen_y = draw.game_to_screen_space(gamestate.P2.pos_x, gamestate.P2.pos_y)
   draw.draw_cross(p1_screen_x, p1_screen_y, colors.distances.coord_line)
   draw.draw_cross(p2_screen_x, p2_screen_y, colors.distances.coord_line)
   local text = Pools.draw:alloc()
   local text_colors = Pools.draw:alloc()
   text[1] = Pools.draw:alloc()
   text[2] = Pools.draw:alloc()
   text_colors[1] = Pools.draw:alloc()
   text_colors[2] = Pools.draw:alloc()
   if settings.modules.distances.show_subpixel or (is_mode_active and edit_position.mode == MODE.SUBPIXEL) then
      local x_char, x_mantissa = get_subpixel_text(gamestate.P1.pos_x)
      local y_char, y_mantissa = get_subpixel_text(gamestate.P1.pos_y)
      text[1][1], text[1][2], text[1][3], text[1][4], text[1][5], text[1][6], text[1][7] =
         x_char, ".", x_mantissa, " , ", y_char, ".", y_mantissa
      x_char, x_mantissa = get_subpixel_text(gamestate.P2.pos_x)
      y_char, y_mantissa = get_subpixel_text(gamestate.P2.pos_y)
      text[2][1], text[2][2], text[2][3], text[2][4], text[2][5], text[2][6], text[2][7] =
         x_char, ".", x_mantissa, " , ", y_char, ".", y_mantissa
      for i = 1, #text[1] do
         text_colors[1][i] = colors.text.default
         text_colors[2][i] = colors.text.default
      end
   else
      text[1][1], text[1][2], text[1][3] = tools.trunc(gamestate.P1.pos_x), " , ", tools.trunc(gamestate.P1.pos_y)
      text[2][1], text[2][2], text[2][3] = tools.trunc(gamestate.P2.pos_x), " , ", tools.trunc(gamestate.P2.pos_y)
      for i = 1, #text[1] do
         text_colors[1][i] = colors.text.default
         text_colors[2][i] = colors.text.default
      end
   end
   if is_mode_active then
      if edit_position.mode == MODE.POSITION then
         text_colors[edit_position.player.id][1] = colors.text.selected
      elseif edit_position.mode == MODE.SUBPIXEL then
         text_colors[edit_position.player.id][3] = colors.text.selected
      end
   end
   draw.render_images_inline(p1_screen_x + 3, p1_screen_y + 2, text[1], "tiny", text_colors[1])
   draw.render_images_inline(p2_screen_x + 3, p2_screen_y + 2, text[2], "tiny", text_colors[2])
end

local function draw_player_arrows()
   local x, y = draw.get_above_character_position(edit_position.player)
   y = y - 2
   draw.draw_image(x - 4, y, "img_tri_arrow_down", nil, colors.text.selected)
end

local function swap_player()
   edit_position.player = edit_position.player.other
   edit_position.mode = MODE.POSITION
end

local function swap_edit_mode()
   if edit_position.mode == MODE.POSITION then
      edit_position.mode = MODE.SUBPIXEL
   else
      edit_position.mode = MODE.POSITION
   end
end

local function move_left(selected_player, selected_player_x, other_player_x, dist)
   edit_position.move_left_frame = gamestate.frame_number
   local switched_sides = false
   local other_player_right = other_player_x + edit_position.contact_dist
   local other_player_left = other_player_x - edit_position.contact_dist
   local stage_left, _ = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local selected_player_new_x = selected_player_x - dist
   if selected_player_new_x > other_player_left and selected_player_new_x < other_player_right then
      if tools.trunc(selected_player_x) == tools.trunc(other_player_right) then
         selected_player_new_x = other_player_left
         switched_sides = true
      else
         selected_player_new_x = other_player_right
      end
   else
      selected_player_new_x = math.max(selected_player_new_x, stage_left)
   end
   return selected_player_new_x, switched_sides
end

local function move_right(selected_player, selected_player_x, other_player_x, dist)
   edit_position.move_right_frame = gamestate.frame_number
   local switched_sides = false
   local other_player_right = other_player_x + edit_position.contact_dist
   local other_player_left = other_player_x - edit_position.contact_dist
   local _, stage_right = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local selected_player_new_x = selected_player_x + dist
   if selected_player_new_x > other_player_left and selected_player_new_x < other_player_right then
      if tools.trunc(selected_player_x) == tools.trunc(other_player_left) then
         selected_player_new_x = other_player_right
         switched_sides = true
      else
         selected_player_new_x = other_player_left
      end
   else
      selected_player_new_x = math.min(selected_player_new_x, stage_right)
   end
   return selected_player_new_x, switched_sides
end

local function move_player_left()
   local dist = edit_position.move_speed
   edit_position.moved_left_last_frame = gamestate.frame_number - edit_position.move_left_frame == 1
   if not edit_position.moved_left_last_frame then
      edit_position.move_start_frame = gamestate.frame_number
   end
   if
      edit_position.moved_left_last_frame
      and gamestate.frame_number - edit_position.move_start_frame > edit_position.autofire_delay
   then
      dist = edit_position.move_speed
         + math.ceil(
            (gamestate.frame_number - edit_position.move_start_frame - edit_position.autofire_delay)
               / edit_position.move_speed_increase_delay
         )
      dist = math.min(dist, edit_position.max_move_speed)
   end
   local new_x, switched_sides =
      move_left(edit_position.player, edit_position.player.pos_x, edit_position.player.other.pos_x, dist)
   memory.writeword(edit_position.player.base + memory_addresses.offsets.pos_x_char, tools.trunc(new_x))
end

local function move_player_right()
   local dist = edit_position.move_speed
   edit_position.moved_right_last_frame = gamestate.frame_number - edit_position.move_right_frame == 1
   if not edit_position.moved_right_last_frame then
      edit_position.move_start_frame = gamestate.frame_number
   end
   if
      edit_position.moved_right_last_frame
      and gamestate.frame_number - edit_position.move_start_frame > edit_position.autofire_delay
   then
      dist = edit_position.move_speed
         + math.ceil(
            (gamestate.frame_number - edit_position.move_start_frame - edit_position.autofire_delay)
               / edit_position.move_speed_increase_delay
         )
      dist = math.min(dist, edit_position.max_move_speed)
   end
   local new_x, switched_sides =
      move_right(edit_position.player, edit_position.player.pos_x, edit_position.player.other.pos_x, dist)
   memory.writeword(edit_position.player.base + memory_addresses.offsets.pos_x_char, tools.trunc(new_x))
end

local function reset_subpixel()
   if edit_position.player.pos_x_mantissa == 0 then
      memory.writebyte(edit_position.player.base + memory_addresses.offsets.pos_x_mantissa, 0xFF)
   else
      memory.writebyte(edit_position.player.base + memory_addresses.offsets.pos_x_mantissa, 0x00)
   end
end

local function change_subpixel(increment)
   local new_value = edit_position.player.pos_x_mantissa + increment
   memory.writebyte(edit_position.player.base + memory_addresses.offsets.pos_x_mantissa, new_value)
end

local function update()
   if is_mode_active and not menu.is_open then
      if
         tools.check_input_down_autofire(
            gamestate.P1,
            "left",
            edit_position.autofire_rate,
            edit_position.autofire_delay
         )
      then
         if edit_position.mode == MODE.POSITION then
            move_player_left()
         elseif edit_position.mode == MODE.SUBPIXEL then
            change_subpixel(-1)
         end
      end
      if
         tools.check_input_down_autofire(
            gamestate.P1,
            "right",
            edit_position.autofire_rate,
            edit_position.autofire_delay
         )
      then
         if edit_position.mode == MODE.POSITION then
            move_player_right()
         elseif edit_position.mode == MODE.SUBPIXEL then
            change_subpixel(1)
         end
      end
      if gamestate.P1.input.pressed.coin then
         swap_player()
      end
      if gamestate.P1.input.pressed.LP then
         swap_edit_mode()
      end
      if gamestate.P1.input.pressed.MP then
         reset_subpixel()
      end
   end
end

local function update_menu()
   if is_mode_active then
      distances_menu.edit_position_item:update_name("menu_stop")
   else
      distances_menu.edit_position_item:update_name("distances_position_players")
   end
end

local function create_menu()
   distances_menu = {}
   distances_line_groups = {}
   local entries = {}
   local function is_enabled_default()
      return is_enabled and should_draw_distances
   end
   local function is_unselectable_default()
      return not is_enabled or not should_draw_distances
   end

   distances_menu.edit_position_item = menu_items.Button_Menu_Item:new("distances_position_players", function()
      if not is_mode_active then
         modes.start(distances)
      else
         modes.stop()
         update_menu()
      end
   end)
   distances_menu.edit_position_item.is_enabled = function()
      return is_enabled and not should_disable_positioning
   end
   distances_menu.edit_position_item.is_unselectable = function()
      return not distances_menu.edit_position_item.is_enabled()
   end

   distances_menu.display_distances_item = menu_items.On_Off_Menu_Item:new(
      "menu_display_distances",
      draw_distances_setting,
      "value",
      false,
      function()
         init()
         menu.reset_background_cache()
      end
   )
   distances_menu.display_distances_item.is_enabled = function()
      return is_enabled
   end
   distances_menu.display_distances_item.is_unselectable = function()
      return not distances_menu.display_distances_item.is_enabled()
   end

   distances_menu.display_coordinates_item = menu_items.On_Off_Menu_Item:new(
      "distances_display_coordinates",
      settings.modules.distances,
      "display_coordinates",
      true,
      menu.reset_background_cache
   )
   distances_menu.display_coordinates_item.is_enabled = is_enabled_default
   distances_menu.display_coordinates_item.is_unselectable = is_unselectable_default

   distances_menu.show_subpixel_item = menu_items.On_Off_Menu_Item:new(
      "distances_show_subpixel",
      settings.modules.distances,
      "show_subpixel",
      false,
      menu.reset_background_cache
   )
   distances_menu.show_subpixel_item.is_enabled = is_enabled_default
   distances_menu.show_subpixel_item.is_unselectable = is_unselectable_default

   entries = {
      distances_menu.edit_position_item,
      distances_menu.display_distances_item,
      distances_menu.display_coordinates_item,
      distances_menu.show_subpixel_item,
   }

   for i = 1, num_lines do
      distances_line_groups[i] = {}
      local display_line_item = menu_items.On_Off_Menu_Item:new(
         display_line_text[settings.language_tag][i],
         settings.modules.distances,
         "line_" .. i .. "_enabled",
         false,
         menu.reset_background_cache
      )
      display_line_item.is_enabled = is_enabled_default
      display_line_item.is_unselectable = is_unselectable_default
      distances_menu["display_line_" .. i .. "_item"] = display_line_item
      distances_line_groups[i].display_line_item = display_line_item

      local height_item = menu_items.Integer_Menu_Item:new(
         "distances_height",
         settings.modules.distances,
         "line_" .. i .. "_height",
         -10,
         200,
         false,
         default_height[i]
      )
      height_item.indent = true
      height_item.is_enabled = is_enabled_default
      height_item.is_unselectable = is_unselectable_default
      height_item.is_visible = function()
         return settings.modules.distances["line_" .. i .. "_enabled"]
      end
      height_item.on_change = menu.reset_background_cache
      distances_menu["display_line_" .. i .. "_height_item"] = height_item
      distances_line_groups[i].height_item = height_item

      local p1_reference_point_item = menu_items.List_Menu_Item:new(
         "distances_p1_reference_point",
         settings.modules.distances,
         "line_" .. i .. "_p1_reference_point",
         distances_menu_tables.reference_point
      )
      p1_reference_point_item.indent = true
      p1_reference_point_item.is_enabled = is_enabled_default
      p1_reference_point_item.is_unselectable = is_unselectable_default
      p1_reference_point_item.is_visible = function()
         return settings.modules.distances["line_" .. i .. "_enabled"]
      end
      p1_reference_point_item.on_change = menu.reset_background_cache
      distances_menu["display_line_" .. i .. "_p1_reference_point_item"] = p1_reference_point_item
      distances_line_groups[i].p1_reference_point_item = p1_reference_point_item

      local p2_reference_point_item = menu_items.List_Menu_Item:new(
         "distances_p2_reference_point",
         settings.modules.distances,
         "line_" .. i .. "_p2_reference_point",
         distances_menu_tables.reference_point
      )
      p2_reference_point_item.indent = true
      p2_reference_point_item.is_enabled = is_enabled_default
      p2_reference_point_item.is_unselectable = is_unselectable_default
      p2_reference_point_item.is_visible = function()
         return settings.modules.distances["line_" .. i .. "_enabled"]
      end
      p2_reference_point_item.on_change = menu.reset_background_cache
      distances_menu["display_line_" .. i .. "_p2_reference_point_item"] = p2_reference_point_item
      distances_line_groups[i].p2_reference_point_item = p2_reference_point_item

      entries[#entries + 1] = display_line_item
      entries[#entries + 1] = height_item
      entries[#entries + 1] = p1_reference_point_item
      entries[#entries + 1] = p2_reference_point_item
   end

   return {
      name = "distances_distances",
      entries = entries,
   }
end

local function update_language()
   for i, group in ipairs(distances_line_groups) do
      group.display_line_item:update_name(display_line_text[settings.language_tag][i])
   end
end

local function set_draw_distances_setting(object, property_name)
   draw_distances_setting = tools.create_dynamic_value(object, property_name)
end

init = function()
   should_draw_distances = draw_distances_setting.value
   if should_draw_distances then
      settings.modules.distances.is_enabled = true
   end
   is_enabled = settings.modules.distances.is_enabled
   if is_enabled and should_draw_distances then
      hud.register_draw(draw_distance_lines, 2)
      hud.register_draw(draw_coordinates, 3)
   else
      hud.unregister_draw(draw_distance_lines)
      hud.unregister_draw(draw_coordinates)
   end
   update_language()
end

local function toggle()
   is_enabled = not is_enabled
   settings.modules.distances.is_enabled = is_enabled
   if not is_enabled then
      draw_distances_setting.value = false
   end

   if is_mode_active then
      modes.stop()
      is_enabled = false
      settings.modules.distances.is_enabled = is_enabled
      draw_distances_setting.value = false
   end
   init()
   if menu.is_open then
      menu.reset_background_cache()
   end
   update_menu()
end

local function begin_edit()
   edit_position.player = training.player
   edit_position.mode = MODE.POSITION
   edit_position.moved_left_last_frame = false
   edit_position.moved_right_last_frame = false
   edit_position.move_left_frame = 0
   edit_position.move_right_frame = 0
   edit_position.move_start_frame = 0
   edit_position.contact_dist = framedata.get_contact_distance(training.player)
   hud.register_draw(draw_player_arrows, 1)
   local notification_display_time = settings.modules.distances.is_first_run and 12 * 60 or 2 * 60
   hud.add_notification_text("distances_notification_text", 0, 208, "center_horizontal", notification_display_time)
end

local function start()
   previous_settings.is_enabled = is_enabled
   previous_settings.should_draw_distances = should_draw_distances
   settings.modules.distances.is_enabled = true
   draw_distances_setting.value = true
   training.set_module_control_by_name(module_name, module_name)
   init()
   begin_edit()
   if menu.is_open then
      menu.close_menu()
   end
   settings.modules.distances.is_first_run = false
end

local function restore_settings()
   settings.modules.distances.is_enabled = previous_settings.is_enabled
   draw_distances_setting.value = previous_settings.should_draw_distances
end

local function stop()
   if is_mode_active then
      restore_settings()
      init()
      hud.unregister_draw(draw_player_arrows)
   end
end

local function toggle_edit()
   if is_mode_active then
      modes.stop()
      update_menu()
      menu.update_active_training_page()
   else
      modes.start(distances)
   end
end

local function process_gesture(gesture) end

local valid_control_schemes = { { module_name, module_name } }
local function get_valid_control_schemes()
   return valid_control_schemes
end

distances = {
   name = module_name,
   init = init,
   update = update,
   toggle = toggle,
   update_menu = update_menu,
   create_menu = create_menu,
   update_language = update_language,
   process_gesture = process_gesture,
   start = start,
   stop = stop,
   get_valid_control_schemes = get_valid_control_schemes,
   toggle_edit = toggle_edit,
   set_draw_distances_setting = set_draw_distances_setting,
}

setmetatable(distances, {
   __index = function(_, key)
      if key == "is_enabled" then
         return is_enabled
      elseif key == "is_mode_active" then
         return is_mode_active
      elseif key == "should_disable_positioning" then
         return should_disable_positioning
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_enabled" then
         is_enabled = value
      elseif key == "is_mode_active" then
         is_mode_active = value
      elseif key == "should_disable_positioning" then
         should_disable_positioning = value
      else
         rawset(distances, key, value)
      end
   end,
})

return distances
