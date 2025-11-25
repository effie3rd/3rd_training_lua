require("gd")
local utf8 = require("src.libs.utf8")
local settings = require("src.settings")
local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local image_tables = require("src.ui.image_tables")
local tools = require("src.tools")

local character_select = require("src.control.character_select")

local SCREEN_WIDTH = 383
local SCREEN_HEIGHT = 223
local GROUND_OFFSET = 23
local CANVAS_WIDTH = SCREEN_WIDTH + 1
local CANVAS_HEIGHT = SCREEN_HEIGHT + 1
local BLANK_CANVAS = {}
local BLANK_ROW = ""
local GD_HEADER_SIZE = 11
local GD_BYTES_PER_PIXEL = 4

local menu_canvas = {canvas = BLANK_CANVAS, width = CANVAS_WIDTH, height = SCREEN_HEIGHT, draw_queue = {}}

local screen_scale = 1

local controller_styles = image_tables.controller_styles

local image_cache = {}

local function create_blank_canvas(width, height)
   local row = {}
   for i = 1, width do row[#row + 1] = string.char(127, 0, 0, 0) end
   local row_str = table.concat(row)

   local rows = {}
   for i = 1, height do rows[i] = row_str end
   return rows
end

local function new_canvas(width, height)
   local w1, w2 = bit.band(bit.rshift(width, 8), 0xff), bit.band(width, 0xff)
   local h1, h2 = bit.band(bit.rshift(height, 8), 0xff), bit.band(height, 0xff)

   return {
      header = string.char(0xff, 0xfe, w1, w2, h1, h2, 0x01, 0xff, 0xff, 0xff, 0xff),
      rows = copytable(BLANK_CANVAS),
      row_size = width * GD_BYTES_PER_PIXEL,
      width = CANVAS_WIDTH,
      height = CANVAS_HEIGHT,
      draw_queue = {}
   }
end

local function clear_canvas(canvas)
   canvas.rows_cache = copytable(canvas.rows)
   canvas.draw_queue_cache = canvas.draw_queue
   canvas.rows = copytable(BLANK_CANVAS)
   canvas.draw_queue = {}
end

local function get_differences(canvas)
   if #canvas.draw_queue_cache == 0 or #canvas.draw_queue ~= #canvas.draw_queue_cache then return end
   local diff = {}
   for i, image in ipairs(canvas.draw_queue) do
      if image.image ~= canvas.draw_queue_cache[i].image or image.x ~= canvas.draw_queue_cache[i].x or image.y ~=
          canvas.draw_queue_cache[i].y then
         image.old_x = canvas.draw_queue_cache[i].x
         image.old_y = canvas.draw_queue_cache[i].y
         image.old_width = canvas.draw_queue_cache[i].width
         image.old_height = canvas.draw_queue_cache[i].height
         diff[#diff + 1] = image
      end
   end
   return diff
end

local function draw_canvas(canvas)
   local diff = get_differences(canvas)
   local draw_queue = canvas.draw_queue
   if diff then
      if #diff == 0 then
         if canvas.image then
            canvas.rows = canvas.rows_cache
            gui.image(0, 0, canvas.image)
            return
         end
      else
         canvas.rows = canvas.rows_cache
         draw_queue = diff
         for i, image in ipairs(draw_queue) do
            local old_img_row_size = image.old_width * GD_BYTES_PER_PIXEL
            for img_row = 0, image.old_height - 1 do
               local canvas_row = image.old_y + img_row + 1
               if canvas_row >= 1 and canvas_row <= canvas.height then
                  local img_row_str = string.sub(BLANK_ROW, 1, old_img_row_size)
                  local row = canvas.rows[canvas_row]
                  local offset = image.old_x * GD_BYTES_PER_PIXEL
                  canvas.rows[canvas_row] = string.sub(row, 1, offset) .. img_row_str ..
                                                string.sub(row, offset + old_img_row_size + 1)
               end
            end
         end
      end
   end
   for i, image in ipairs(draw_queue) do
      local img_row_size = image.width * GD_BYTES_PER_PIXEL
      for img_row = 0, image.height - 1 do
         local canvas_row = image.y + img_row + 1
         if canvas_row >= 1 and canvas_row <= canvas.height then
            local image_start = GD_HEADER_SIZE + 1 + img_row * img_row_size
            local row = canvas.rows[canvas_row]
            local offset = image.x * GD_BYTES_PER_PIXEL
            local row_tbl = {string.sub(row, 1, offset)}
            for img_col = 0, image.width - 1 do
               local col_start = image_start + img_col * GD_BYTES_PER_PIXEL
               local alpha = string.byte(string.sub(image.image, col_start, col_start))
               if alpha == 0 then
                  row_tbl[#row_tbl + 1] = string.sub(image.image, col_start, col_start + GD_BYTES_PER_PIXEL - 1)
               else
                  row_tbl[#row_tbl + 1] = string.sub(row, offset + img_col * GD_BYTES_PER_PIXEL + 1, offset + img_col * GD_BYTES_PER_PIXEL +  GD_BYTES_PER_PIXEL)
               end
            end
            row_tbl[#row_tbl + 1] = string.sub(row, offset + img_row_size + 1)
            canvas.rows[canvas_row] = table.concat(row_tbl)
         end
      end
   end
   canvas.image = canvas.header .. table.concat(canvas.rows)
   if canvas.image then gui.image(0, 0, canvas.image) end
end

local function add_image_to_canvas(canvas, x, y, w, h, image)
   canvas.draw_queue[#canvas.draw_queue + 1] = {
      x = math.floor(x),
      y = math.floor(y),
      width = w,
      height = h,
      image = image
   }
end

local function update_draw_variables()
   screen_scale = memory.readwordsigned(0x0200DCBA) -- FBA can't read from 04xxxxxx
   screen_scale = 0x40 / (screen_scale > 0 and screen_scale or 1)
end

local function game_to_screen_space_x(x) return x - gamestate.screen_x + emu.screenwidth() / 2 end

local function game_to_screen_space_y(y) return emu.screenheight() - (y - gamestate.screen_y) - GROUND_OFFSET end

local function game_to_screen_space(x, y) return game_to_screen_space_x(x), game_to_screen_space_y(y) end

local function get_text_width(str) -- for gui_text
   if #str == 0 then return 0 end
   return #str * 4
end

local function get_image(image, color)
   if not image_cache[image] then image_cache[image] = {} end
   if not color then color = colors.text.default end
   if not image_cache[image][color] then
      if color == colors.text.default then
         image_cache[image][color] = image
      else
         image_cache[image][color] = colors.substitute_color_gdstr(image, colors.white, color)
      end
   end
   return image_cache[image][color]
end

local function draw_text(x, y, str, lang, size, color, opacity)
   if size and string.sub(str, 1, 3) == "utf" then lang = lang .. "_" .. size end
   if image_tables.text[str][lang][color] then
      gui.image(x, y, image_tables.text[str][lang][color], opacity)
   else
      image_tables.text[str][lang][color] = colors.substitute_color_gdstr(image_tables.text[str][lang][colors.white],
                                                                          colors.white, color)
      gui.image(x, y, image_tables.text[str][lang][color], opacity)
   end
end

local function render_text_jp(x, y, str, lang, size, color, opacity)
   local offset = 0
   lang = lang or "jp"
   color = color or colors.text.default
   opacity = opacity or 1
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. tostring(code)
         draw_text(x + offset, y, code, lang, size, color, opacity)
         offset = offset + image_tables.text[code][lang].width - 1
      else
         offset = offset + 2
      end
   end
end

local function render_text(x, y, str, lang, size, color, opacity)
   local offset = 0
   str = tostring(str)
   lang = lang or settings.language
   color = color or colors.text.default
   opacity = opacity or 1

   -- draw block of text if it exists
   if image_tables.text[str] then
      draw_text(x + offset, y, str, lang, size, color, opacity)
      return
   end

   -- render individual characters
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      -- char is jp
      if code >= 12288 and code <= 40879 then
         -- render individual jp characters
         render_text_jp(x, y, str, lang, size, color, opacity)
         return
      end
   end

   local lang_ext = lang
   if size then lang_ext = lang_ext .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. tostring(code)
         draw_text(x + offset, y, code, lang, size, color, opacity)
         offset = offset + image_tables.text[code][lang_ext].width - 1
      else
         offset = offset + 2
      end
   end
end

local function draw_text_to_canvas(canvas, x, y, str, lang, size, color, opacity)
   if size and string.sub(str, 1, 3) == "utf" then lang = lang .. "_" .. size end
   if image_tables.text[str][lang][color] then
      add_image_to_canvas(canvas, x, y, image_tables.text[str][lang].width, image_tables.text[str][lang].height,
                          image_tables.text[str][lang][color])
   else
      image_tables.text[str][lang][color] = colors.substitute_color_gdstr(image_tables.text[str][lang][colors.white],
                                                                          colors.white, color)
      add_image_to_canvas(canvas, x, y, image_tables.text[str][lang].width, image_tables.text[str][lang].height,
                          image_tables.text[str][lang][color])
   end
end

local function render_text_jp_to_canvas(canvas, x, y, str, lang, size, color, opacity)
   local offset = 0
   lang = lang or "jp"
   color = color or colors.text.default
   opacity = opacity or 1
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. tostring(code)
         draw_text_to_canvas(canvas, x + offset, y, code, lang, size, color, opacity)
         offset = offset + image_tables.text[code][lang].width - 1
      else
         offset = offset + 2
      end
   end
end

local function render_text_to_canvas(canvas, x, y, str, lang, size, color, opacity)
   local offset = 0
   str = tostring(str)
   lang = lang or settings.language
   color = color or colors.text.default
   opacity = opacity or 1

   -- draw block of text if it exists
   if image_tables.text[str] then
      draw_text_to_canvas(canvas, x + offset, y, str, lang, size, color, opacity)
      return
   end

   -- render individual characters
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      -- char is jp
      if code >= 12288 and code <= 40879 then
         -- render individual jp characters
         render_text_jp_to_canvas(canvas, x, y, str, lang, size, color, opacity)
         return
      end
   end

   local lang_ext = lang
   if size then lang_ext = lang_ext .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. tostring(code)
         draw_text_to_canvas(canvas, x + offset, y, code, lang, size, color, opacity)
         offset = offset + image_tables.text[code][lang_ext].width - 1
      else
         offset = offset + 2
      end
   end
end

local function get_text_dimensions_jp(str, lang, size)
   local w, h = 0, 0
   lang = lang or "jp"
   if size then lang = lang .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = "utf_" .. utf8.codepoint(v)
      if code ~= 32 then
         w = w + image_tables.text[code][lang].width
         h = image_tables.text[code][lang].height
      else
         w = w + 3
      end
   end
   w = w - utf8.len(str) + 1
   return w, h
end

local function get_text_dimensions(str, lang, size)
   local w, h = 0, 0
   str = tostring(str)
   lang = lang or settings.language
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      -- char is jp
      if code >= 12288 and code <= 40879 then
         w, h = get_text_dimensions_jp(str, lang, size)
         return w, h
      end
   end
   -- str is not jp, get size of block of text
   if image_tables.text[str] then return image_tables.text[str][lang].width, image_tables.text[str][lang].height end
   if size then lang = lang .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then
         code = "utf_" .. tostring(code)
         w = w + image_tables.text[code][lang].width
         h = image_tables.text[code][lang].height
      else
         w = w + 3
      end
   end
   if str ~= "" then w = w - utf8.len(str) + 1 end
   return w, h
end

local function render_text_multiple(x, y, list_str, lang, size, color, opacity)
   local offset_x = 0
   for _, str in pairs(list_str) do
      render_text(x + offset_x, y, str, lang, size, color, opacity)
      local tw, th = get_text_dimensions(str, lang, size)
      offset_x = offset_x + tw
   end
end

local function render_text_multiple_to_canvas(canvas, x, y, list_str, lang, size, color, opacity)
   local offset_x = 0
   for _, str in pairs(list_str) do
      render_text_to_canvas(canvas, x + offset_x, y, str, lang, size, color, opacity)
      local tw, th = get_text_dimensions(str, lang, size)
      offset_x = offset_x + tw
   end
end

local function get_text_dimensions_multiple(list_str, lang, size)
   local w = 0
   local h = 0
   for _, str in pairs(list_str) do
      local tw, th = get_text_dimensions(str, lang, size)
      w = w + tw
      h = math.max(h, th)
   end
   return w, h
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
   if not entry then return end
   gui.image(x, y, image_tables.images.img_dir_big[entry.direction])

   local img_LP = image_tables.images.img_no_button_big
   local img_MP = image_tables.images.img_no_button_big
   local img_HP = image_tables.images.img_no_button_big
   local img_LK = image_tables.images.img_no_button_big
   local img_MK = image_tables.images.img_no_button_big
   local img_HK = image_tables.images.img_no_button_big
   if entry.buttons[1] then img_LP = image_tables.images.img_button_big[style][1] end
   if entry.buttons[2] then img_MP = image_tables.images.img_button_big[style][2] end
   if entry.buttons[3] then img_HP = image_tables.images.img_button_big[style][3] end
   if entry.buttons[4] then img_LK = image_tables.images.img_button_big[style][4] end
   if entry.buttons[5] then img_MK = image_tables.images.img_button_big[style][5] end
   if entry.buttons[6] then img_HK = image_tables.images.img_button_big[style][6] end

   gui.image(x + 13, y, img_LP)
   gui.image(x + 18, y, img_MP)
   gui.image(x + 23, y, img_HP)
   gui.image(x + 13, y + 5, img_LK)
   gui.image(x + 18, y + 5, img_MK)
   gui.image(x + 23, y + 5, img_HK)
end

local function draw_buttons_preview_big(x, y, style)

   local img_LP = image_tables.images.img_button_big[style][1]
   local img_MP = image_tables.images.img_button_big[style][2]
   local img_HP = image_tables.images.img_button_big[style][3]
   local img_LK = image_tables.images.img_button_big[style][4]
   local img_MK = image_tables.images.img_button_big[style][5]
   local img_HK = image_tables.images.img_button_big[style][6]

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

   gui.image(x + x_offset, y, image_tables.images.img_dir_small[entry.direction])
   x_offset = x_offset + sign * 2

   local interval = 8
   x_offset = x_offset + sign * interval

   if entry.buttons[1] then
      gui.image(x + x_offset, y, image_tables.images.img_button_small[style][1])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[2] then
      gui.image(x + x_offset, y, image_tables.images.img_button_small[style][2])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[3] then
      gui.image(x + x_offset, y, image_tables.images.img_button_small[style][3])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[4] then
      gui.image(x + x_offset, y, image_tables.images.img_button_small[style][4])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[5] then
      gui.image(x + x_offset, y, image_tables.images.img_button_small[style][5])
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[6] then
      gui.image(x + x_offset, y, image_tables.images.img_button_small[style][6])
      x_offset = x_offset + sign * interval
   end

end

-- draws a gauge
local function draw_gauge(x, y, width, height, fill_ratio, fill_color, bg_color, border_color, reverse_fill)
   bg_color = bg_color or 0x00000000
   border_color = border_color or 0xFFFFFFFF
   reverse_fill = reverse_fill or false

   gui.box(x, y, x + width + 1, y + height + 1, bg_color, border_color)
   if reverse_fill then
      gui.box(x + width + 1, y , x + width - width * tools.clamp(fill_ratio, 0, 1), y + height + 1, fill_color, 0x00000000)
   else
      gui.box(x, y , x + 1 + width * tools.clamp(fill_ratio, 0, 1), y + height + 1, fill_color, 0x00000000)
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

local function draw_horizontal_text_segment(p1_x, p2_x, y, str, line_color, edges_height, edges_style, lang)

   local center_x = (p1_x + p2_x) * 0.5
   edges_height = edges_height or 3
   local half_distance_str_width
   if lang then
      local h
      half_distance_str_width, h = get_text_dimensions(str, lang)
      half_distance_str_width = half_distance_str_width * 0.5
      render_text(center_x - half_distance_str_width, y - h / 2 + 1, str, lang, nil, colors.gui_text.default)
   else
      half_distance_str_width = get_text_width(str) * 0.5
      gui.text(center_x - half_distance_str_width, y - 3, str, colors.gui_text.default, colors.gui_text.default_border)
   end
   draw_horizontal_line(math.min(p1_x, p2_x), center_x - half_distance_str_width - 3, y, line_color, 1)
   draw_horizontal_line(center_x + half_distance_str_width + 3, math.max(p1_x, p2_x), y, line_color, 1)

   if edges_style == "up" then
      draw_vertical_line(p1_x, y - edges_height, y, line_color, 1)
      draw_vertical_line(p2_x, y - edges_height, y, line_color, 1)
   elseif edges_style == "down" then
      draw_vertical_line(p1_x, y, y + edges_height, line_color, 1)
      draw_vertical_line(p2_x, y, y + edges_height, line_color, 1)
   else
      draw_vertical_line(p1_x, y - edges_height, y + edges_height, line_color, 1)
      draw_vertical_line(p2_x, y - edges_height, y + edges_height, line_color, 1)
   end
end

local function get_above_character_position(player)
   local char_height = 0
   if gamestate.is_standing_state(player, player.standing_state) or
       gamestate.is_crouching_state(player, player.standing_state)
       or (player.standing_state == 0 and player.character_state_byte == 4)
       then
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

local result = {}
for i = 1, CANVAS_WIDTH do result[#result + 1] = string.char(127, 0, 0, 0) end
BLANK_ROW = table.concat(result)
BLANK_CANVAS = create_blank_canvas(CANVAS_WIDTH, CANVAS_HEIGHT)
menu_canvas = new_canvas(CANVAS_WIDTH, SCREEN_HEIGHT)

local draw = {
   SCREEN_WIDTH = SCREEN_WIDTH,
   SCREEN_HEIGHT = SCREEN_HEIGHT,
   GROUND_OFFSET = GROUND_OFFSET,
   GD_HEADER_SIZE = GD_HEADER_SIZE,
   GD_BYTES_PER_PIXEL = GD_BYTES_PER_PIXEL,
   get_image = get_image,
   render_text = render_text,
   get_text_dimensions = get_text_dimensions,
   render_text_multiple = render_text_multiple,
   get_text_dimensions_multiple = get_text_dimensions_multiple,
   render_text_to_canvas = render_text_to_canvas,
   render_text_multiple_to_canvas = render_text_multiple_to_canvas,
   add_image_to_canvas = add_image_to_canvas,
   new_canvas = new_canvas,
   clear_canvas = clear_canvas,
   draw_canvas = draw_canvas,
   controller_styles = controller_styles,
   controller_style_menu_names = image_tables.controller_style_menu_names,
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
      if colors[key] then
         return colors[key]
      elseif key == "menu_canvas" then
         return menu_canvas
      end
   end
})

return draw
