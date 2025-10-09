local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local text = require("src.ui.text")
local images = require("src.ui.image_tables")
local tools = require("src.tools")

local render_text, get_text_dimensions = text.render_text, text.get_text_dimensions
local character_select = require("src.control.character_select")

local SCREEN_WIDTH = 383
local SCREEN_HEIGHT = 223
local GROUND_OFFSET = 23

local screen_x = 0
local screen_y = 0
local screen_scale = 1

local controller_styles = images.controller_styles

local function update_draw_variables()
   screen_x = memory.readwordsigned(0x02026CB0)
   screen_y = memory.readwordsigned(0x02026CB4)
   screen_scale = memory.readwordsigned(0x0200DCBA) -- FBA can't read from 04xxxxxx
   screen_scale = 0x40 / (screen_scale > 0 and screen_scale or 1)
end

local function game_to_screen_space_x(x) return x - screen_x + emu.screenwidth() / 2 end

local function game_to_screen_space_y(y) return emu.screenheight() - (y - screen_y) - GROUND_OFFSET end

local function game_to_screen_space(x, y) return game_to_screen_space_x(x), game_to_screen_space_y(y) end

local function get_text_width(text)
   if #text == 0 then return 0 end

   return #text * 4
end

local function draw_hitboxes(pos_x, pos_y, flip_x, boxes, filter, dilation, color, opacity)
   dilation = dilation or 0
   local px, py = game_to_screen_space(pos_x, pos_y)
   local opacity_byte = 0xFF
   if opacity and opacity < 100 then opacity_byte = tools.float_to_byte(opacity / 100) end
   for __, box in pairs(boxes) do
      box = tools.format_box(box)
      if filter == nil or filter[box.type] == true then
         -- vulnerability
         local c = colors.hitboxes.vulnerability
         if (box.type == "attack") then
            c = colors.hitboxes.attack
         elseif (box.type == "throwable") then
            c = colors.hitboxes.throwable
         elseif (box.type == "throw") then
            c = colors.hitboxes.throw
         elseif (box.type == "push") then
            c = colors.hitboxes.push
         elseif (box.type == "ext. vulnerability") then
            c = colors.hitboxes.extvulnerability
         end

         c = color or c

         if opacity then c = bit.band(c, 0xFFFFFF00) + opacity_byte end

         local l
         if flip_x == 0 then
            l = px + box.left
         else
            l = px - box.left - box.width
         end
         local r = l + box.width
         local b = py - box.bottom
         local t = b - box.height

         l = l - dilation
         r = r + dilation
         b = b + dilation
         t = t - dilation

         gui.box(l, b, r, t, 0x00000000, c)
      end
   end
end

local function print_dims(pos_x, pos_y, flip_x, boxes)
   local px, py = game_to_screen_space(pos_x, pos_y)
   px, py = tools.round(px), tools.round(py)
   for __, box in pairs(boxes) do
      box = tools.format_box(box)
      local l
      if flip_x == 0 then
         l = px + box.left
      else
         l = px - box.left - box.width
      end
      local r = l + box.width
      local b = py - box.bottom
      local t = b - box.height

      return l, r, t, b
   end
end

-- draws a point
local function draw_point(x, y, color)
   local cross_half_size = 4
   local l = x - cross_half_size
   local r = x + cross_half_size
   local t = y - cross_half_size
   local b = y + cross_half_size

   gui.box(l, y, r, y, 0x00000000, color)
   gui.box(x, t, x, b, 0x00000000, color)
end

-- draws a controller representation
local function draw_controller_big(entry, x, y, style)
   gui.image(x, y, images.img_dir_big[entry.direction])

   local img_LP = images.img_no_button_big
   local img_MP = images.img_no_button_big
   local img_HP = images.img_no_button_big
   local img_LK = images.img_no_button_big
   local img_MK = images.img_no_button_big
   local img_HK = images.img_no_button_big
   if entry.buttons[1] then img_LP = images.img_button_big[style][1] end
   if entry.buttons[2] then img_MP = images.img_button_big[style][2] end
   if entry.buttons[3] then img_HP = images.img_button_big[style][3] end
   if entry.buttons[4] then img_LK = images.img_button_big[style][4] end
   if entry.buttons[5] then img_MK = images.img_button_big[style][5] end
   if entry.buttons[6] then img_HK = images.img_button_big[style][6] end

   gui.image(x + 13, y, img_LP)
   gui.image(x + 18, y, img_MP)
   gui.image(x + 23, y, img_HP)
   gui.image(x + 13, y + 5, img_LK)
   gui.image(x + 18, y + 5, img_MK)
   gui.image(x + 23, y + 5, img_HK)
end

local function draw_buttons_preview_big(x, y, style)

   local img_LP = images.img_button_big[style][1]
   local img_MP = images.img_button_big[style][2]
   local img_HP = images.img_button_big[style][3]
   local img_LK = images.img_button_big[style][4]
   local img_MK = images.img_button_big[style][5]
   local img_HK = images.img_button_big[style][6]

   gui.image(x, y, img_LP)
   gui.image(x + 5, y, img_MP)
   gui.image(x + 10, y, img_HP)
   gui.image(x, y + 5, img_LK)
   gui.image(x + 5, y + 5, img_MK)
   gui.image(x + 10, y + 5, img_HK)
end

-- draws a controller representation
local function draw_controller_small(entry, x, y, is_right, style)
   local x_offset = 0
   local sign = 1
   if is_right then
      x_offset = x_offset - 9
      sign = -1
   end

   gui.image(x + x_offset, y, images.img_dir_small[entry.direction])
   x_offset = x_offset + sign * 2

   local interval = 8
   x_offset = x_offset + sign * interval

   if entry.buttons[1] then
      gui.image(x + x_offset, y, images.img_button_small[style][1])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[2] then
      gui.image(x + x_offset, y, images.img_button_small[style][2])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[3] then
      gui.image(x + x_offset, y, images.img_button_small[style][3])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[4] then
      gui.image(x + x_offset, y, images.img_button_small[style][4])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[5] then
      gui.image(x + x_offset, y, images.img_button_small[style][5])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[6] then
      gui.image(x + x_offset, y, images.img_button_small[style][6])
      x_offset = x_offset + sign * interval
   end

end

-- draws a gauge
local function draw_gauge(x, y, width, height, fill_ratio, fill_color, bg_color, border_color, reverse_fill)
   bg_color = bg_color or 0x00000000
   border_color = border_color or 0xFFFFFFFF
   reverse_fill = reverse_fill or false

   width = width + 1
   height = height + 1

   gui.box(x, y, x + width, y + height, bg_color, border_color)
   if reverse_fill then
      gui.box(x + width, y, x + width - width * tools.clamp(fill_ratio, 0, 1), y + height, fill_color, 0x00000000)
   else
      gui.box(x, y, x + width * tools.clamp(fill_ratio, 0, 1), y + height, fill_color, 0x00000000)
   end
end

local function draw_horizontal_line(x_start, x_end, y, color, thickness)
   thickness = thickness or 1.0
   local l = x_start - 1
   local b = y + math.ceil(thickness * 0.5)
   local r = x_end + 1
   local t = y - math.floor(thickness * 0.5) - 1
   gui.box(l, b, r, t, color, 0x00000000)
end

local function draw_vertical_line(x, y_start, y_end, color, thickness)
   thickness = thickness or 1.0
   local l = x - math.floor(thickness * 0.5) - 1
   local b = y_end + 1
   local r = x + math.ceil(thickness * 0.5)
   local t = y_start - 1
   gui.box(l, b, r, t, color, 0x00000000)
end

local function draw_horizontal_text_segment(p1_x, p2_x, y, text, line_color, edges_height)

   edges_height = edges_height or 3
   local half_distance_str_width = get_text_width(text) * 0.5

   local center_x = (p1_x + p2_x) * 0.5
   draw_horizontal_line(math.min(p1_x, p2_x), center_x - half_distance_str_width - 3, y, line_color, 1)
   draw_horizontal_line(center_x + half_distance_str_width + 3, math.max(p1_x, p2_x), y, line_color, 1)
   gui.text(center_x - half_distance_str_width, y - 3, text, colors.gui_text.default, colors.gui_text.default_border)

   if edges_height > 0 then
      draw_vertical_line(p1_x, y - edges_height, y + edges_height, line_color, 1)
      draw_vertical_line(p2_x, y - edges_height, y + edges_height, line_color, 1)
   end
end

local function get_above_character_position(player)
   local char_height = 0
   if player.is_standing or player.is_crouching then
      char_height = require("src.modules.framedata").character_specific[player.char_str].height.standing.max + 10
   else
      char_height = tools.get_boxes_highest_position(player.boxes, {"vulnerability", "push"})
      if char_height == 0 then
         char_height = require("src.modules.framedata").character_specific[player.char_str].height.standing.max
      end
   end
   return game_to_screen_space(player.pos_x, player.pos_y + char_height)
end

local load_frame_data_bar_fade_time = 40
local load_frame_data_bar_fade_start = 0
local load_frame_data_bar_elapsed = 0
local load_frame_data_bar_fading = false

local function loading_bar_display(loaded, total)
   if load_frame_data_bar_fading then
      load_frame_data_bar_elapsed = gamestate.frame_number - load_frame_data_bar_fade_start
      if load_frame_data_bar_fading and load_frame_data_bar_elapsed > load_frame_data_bar_fade_time then return end
   end

   local width = 60
   local height = 1
   local padding = 1
   local x = SCREEN_WIDTH - width - padding
   local y = SCREEN_HEIGHT - height - padding
   local fill_color = 0xFFFFFFDD
   local opacity = 0xDD
   if load_frame_data_bar_fading then
      opacity = 0xDD * (1 - load_frame_data_bar_elapsed / load_frame_data_bar_fade_time)
      fill_color = 0xFFFFFF00 + opacity
   end
   draw_gauge(x, y, width, height, loaded / total, fill_color, 0x00000000, 0x00000000, false)
   if loaded >= total and not load_frame_data_bar_fading then
      load_frame_data_bar_fade_start = gamestate.frame_number
      load_frame_data_bar_fading = true
   end
end

local character_select_text_display_time = 120
local character_select_text_fade_time = 30
local function draw_character_select()
   if character_select.p1_character_select_state <= 2 or character_select.p2_character_select_state <= 2 then
      local elapsed = gamestate.frame_number - character_select.character_select_start_frame
      if elapsed <= character_select_text_display_time + character_select_text_fade_time then
         local opacity = 1
         if elapsed > character_select_text_display_time then
            opacity = 1 - ((elapsed - character_select_text_display_time) / character_select_text_fade_time)
         end
         local w, h = get_text_dimensions("character_select_line_1")
         local padding_x = 0
         local padding_y = 0
         render_text(padding_x, padding_y, "character_select_line_1", nil, nil, nil, opacity)
         render_text(padding_x, padding_y + h, "character_select_line_2", nil, nil, nil, opacity)
         render_text(padding_x, padding_y + h + h, "character_select_line_3", nil, nil, nil, opacity)
      end
   end
end

local draw = {
   SCREEN_WIDTH = SCREEN_WIDTH,
   SCREEN_HEIGHT = SCREEN_HEIGHT,
   GROUND_OFFSET = GROUND_OFFSET,
   controller_styles = controller_styles,
   game_to_screen_space_x = game_to_screen_space_x,
   game_to_screen_space_y = game_to_screen_space_y,
   game_to_screen_space = game_to_screen_space,
   update_draw_variables = update_draw_variables,
   get_text_width = get_text_width,
   draw_hitboxes = draw_hitboxes,
   draw_point = draw_point,
   draw_controller_big = draw_controller_big,
   draw_buttons_preview_big = draw_buttons_preview_big,
   draw_controller_small = draw_controller_small,
   draw_gauge = draw_gauge,
   draw_horizontal_text_segment = draw_horizontal_text_segment,
   get_above_character_position = get_above_character_position,
   loading_bar_display = loading_bar_display,
   draw_character_select = draw_character_select
}

setmetatable(draw, {
   __index = function(_, key)
      if key == "screen_x" then
         return screen_x
      elseif key == "screen_y" then
         return screen_y
      elseif key == "screen_scale" then
         return screen_scale
      end
   end
})

return draw
