require("gd")
local utf8 = require("src.libs.utf8")
local settings = require("src.settings")
local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local image_tables = require("src.ui.image_tables")
local tools = require("src.tools")

local Pools = tools.Pools
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
local DRAW_TYPE = { IMAGE = 1, BOX = 2, LINE = 3 }

local menu_canvas = { canvas = BLANK_CANVAS, width = CANVAS_WIDTH, height = SCREEN_HEIGHT, draw_queue = {} }
local canvas_stack = {}
local draw_depth = 1

local screen_scale = 1

local controller_styles = image_tables.controller_styles

local function create_blank_canvas(width, height)
   local row = {}
   for i = 1, width do
      row[#row + 1] = string.char(127, 0, 0, 0)
   end
   local row_str = table.concat(row)

   local rows = {}
   for i = 1, height do
      rows[i] = row_str
   end
   return rows
end

local function new_canvas(width, height)
   local w1, w2 = bit.band(bit.rshift(width, 8), 0xff), bit.band(width, 0xff)
   local h1, h2 = bit.band(bit.rshift(height, 8), 0xff), bit.band(height, 0xff)

   return {
      header = string.char(0xff, 0xfe, w1, w2, h1, h2, 0x01, 0xff, 0xff, 0xff, 0xff),
      rows = copytable(BLANK_CANVAS),
      rows_cache = copytable(BLANK_CANVAS),
      row_size = width * GD_BYTES_PER_PIXEL,
      width = CANVAS_WIDTH,
      height = CANVAS_HEIGHT,
      draw_queue = {},
      draw_queue_cache = {},
   }
end

local function clear_canvas(canvas)
   tools.clear_table(canvas.rows_cache)
   tools.copy_fields(canvas.rows_cache, canvas.rows)
   tools.clear_table(canvas.draw_queue_cache)
   tools.copy_fields(canvas.draw_queue_cache, canvas.draw_queue)
   tools.clear_table(canvas.rows)
   tools.copy_fields(canvas.rows, BLANK_CANVAS)
   tools.clear_table(canvas.draw_queue)
end

local max_depth = 10
local function get_differences(canvas)
   if #canvas.draw_queue_cache == 0 or #canvas.draw_queue ~= #canvas.draw_queue_cache then
      return
   end
   local diff = Pools.draw:alloc()
   local existing = Pools.draw:alloc()
   local other_calls = Pools.draw:alloc()
   for i, draw_call in ipairs(canvas.draw_queue) do
      if draw_call.type ~= canvas.draw_queue_cache[i].type then
         return
      end
      if draw_call.type == DRAW_TYPE.IMAGE then
         if
            draw_call.image ~= canvas.draw_queue_cache[i].image --
            or draw_call.x ~= canvas.draw_queue_cache[i].x --
            or draw_call.y ~= canvas.draw_queue_cache[i].y
         then --
            draw_call.old_x = canvas.draw_queue_cache[i].x
            draw_call.old_y = canvas.draw_queue_cache[i].y
            draw_call.old_width = canvas.draw_queue_cache[i].width
            draw_call.old_height = canvas.draw_queue_cache[i].height
            diff[#diff + 1] = draw_call
         else
            existing[#existing + 1] = canvas.draw_queue_cache[i]
         end
      elseif draw_call.type == DRAW_TYPE.BOX or draw_call.type == DRAW_TYPE.LINE then
         other_calls[#other_calls + 1] = draw_call
      end
   end
   local depth = 0
   local to_check = diff
   repeat
      local results = Pools.draw:alloc()
      local new_existing = Pools.draw:alloc()
      for _, diff_image in ipairs(to_check) do
         local diff_image_left = diff_image.old_x
         local diff_image_right = diff_image.old_x + diff_image.old_width - 1
         local diff_image_top = diff_image.old_y
         local diff_image_bottom = diff_image.old_y + diff_image.old_height - 1
         for i, image in ipairs(existing) do
            local image_left = image.x
            local image_right = image.x + image.width - 1
            local image_top = image.y
            local image_bottom = image.y + image.height - 1
            if
               (image_left <= diff_image_right)
               and (image_right >= diff_image_left)
               and (image_bottom >= diff_image_top)
               and (image_top <= diff_image_bottom)
            then
               image.old_x = image.x
               image.old_y = image.y
               image.old_width = image.width
               image.old_height = image.height
               if not tools.table_contains(diff, image) then
                  results[#results + 1] = image
                  diff[#diff + 1] = image
               end
            else
               new_existing[#new_existing + 1] = image
            end
         end
      end
      depth = depth + 1
      to_check = results
      existing = new_existing
   until depth >= max_depth or (#results == 0)
   for i, draw_call in ipairs(other_calls) do
      diff[#diff + 1] = draw_call
   end
   table.sort(diff, function(a, b)
      return a.order < b.order
   end)
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
         for i, draw_call in ipairs(draw_queue) do
            if draw_call.type == DRAW_TYPE.IMAGE then
               local old_img_row_size = draw_call.old_width * GD_BYTES_PER_PIXEL
               for img_row = 0, draw_call.old_height - 1 do
                  local canvas_row = draw_call.old_y + img_row + 1
                  if canvas_row >= 1 and canvas_row <= canvas.height then
                     local img_row_str = string.sub(BLANK_ROW, 1, old_img_row_size)
                     local row = canvas.rows[canvas_row]
                     local offset = draw_call.old_x * GD_BYTES_PER_PIXEL
                     canvas.rows[canvas_row] = string.sub(row, 1, offset)
                        .. img_row_str
                        .. string.sub(row, offset + old_img_row_size + 1)
                  end
               end
            end
         end
      end
   end
   for i, draw_call in ipairs(draw_queue) do
      if draw_call.type == DRAW_TYPE.IMAGE then
         local img_row_size = draw_call.width * GD_BYTES_PER_PIXEL
         for img_row = 0, draw_call.height - 1 do
            local canvas_row = draw_call.y + img_row + 1
            if canvas_row >= 1 and canvas_row <= canvas.height then
               local image_start = GD_HEADER_SIZE + 1 + img_row * img_row_size
               local row = canvas.rows[canvas_row]
               local offset = draw_call.x * GD_BYTES_PER_PIXEL
               local row_tbl = Pools.draw:alloc()
               row_tbl[1] = string.sub(row, 1, offset)
               for img_col = 0, draw_call.width - 1 do
                  local col_start = image_start + img_col * GD_BYTES_PER_PIXEL
                  local alpha = string.byte(string.sub(draw_call.image, col_start, col_start))
                  if alpha == 0 then
                     row_tbl[#row_tbl + 1] = string.sub(draw_call.image, col_start, col_start + GD_BYTES_PER_PIXEL - 1)
                  else
                     row_tbl[#row_tbl + 1] = string.sub(
                        row,
                        offset + img_col * GD_BYTES_PER_PIXEL + 1,
                        offset + img_col * GD_BYTES_PER_PIXEL + GD_BYTES_PER_PIXEL
                     )
                  end
               end
               row_tbl[#row_tbl + 1] = string.sub(row, offset + img_row_size + 1)
               canvas.rows[canvas_row] = table.concat(row_tbl)
            end
         end
      elseif draw_call.type == DRAW_TYPE.BOX then
         gui.box(
            draw_call.x,
            draw_call.y,
            draw_call.right,
            draw_call.bottom,
            draw_call.background_color,
            draw_call.outline_color
         )
      elseif draw_call.type == DRAW_TYPE.LINE then
         gui.line(draw_call.x, draw_call.y, draw_call.right, draw_call.bottom, draw_call.color)
      end
   end
   canvas.image = canvas.header .. table.concat(canvas.rows)
   if canvas.image then
      gui.image(0, 0, canvas.image)
   end
end

local function clear_canvases()
   draw_depth = 1
   for i, canvas in ipairs(canvas_stack) do
      clear_canvas(canvas)
   end
end

local function draw_canvases()
   local compacted = tools.compact_table(canvas_stack)
   tools.clear_table(canvas_stack)
   tools.copy_fields(canvas_stack, compacted)
   for i, canvas in ipairs(canvas_stack) do
      if i <= draw_depth then
         draw_canvas(canvas)
      else
         canvas_stack[i] = nil
      end
   end
end

local function add_image_to_canvas(depth, x, y, w, h, image)
   if not canvas_stack[depth] then
      canvas_stack[depth] = new_canvas(CANVAS_WIDTH, SCREEN_HEIGHT)
   end
   if depth > draw_depth then
      draw_depth = depth
   end
   local canvas = canvas_stack[depth]
   local data = Pools.draw:alloc()
   data.x = math.floor(x)
   data.y = math.floor(y)
   data.width = w
   data.height = h
   data.image = image
   data.type = DRAW_TYPE.IMAGE
   data.order = #canvas.draw_queue + 1
   canvas.draw_queue[#canvas.draw_queue + 1] = data
end

local function add_box_to_canvas(depth, x, y, r, b, background_color, outline_color)
   if not canvas_stack[depth] then
      canvas_stack[depth] = new_canvas(CANVAS_WIDTH, SCREEN_HEIGHT)
   end
   if depth > draw_depth then
      draw_depth = depth
   end
   local canvas = canvas_stack[depth]
   local data = Pools.draw:alloc()
   data.x = math.floor(x)
   data.y = math.floor(y)
   data.right = math.floor(r)
   data.bottom = math.floor(b)
   data.background_color = background_color
   data.outline_color = outline_color
   data.type = DRAW_TYPE.BOX
   data.order = #canvas.draw_queue + 1
   canvas.draw_queue[#canvas.draw_queue + 1] = data
end

local function add_line_to_canvas(depth, x, y, r, b, color)
   if not canvas_stack[depth] then
      canvas_stack[depth] = new_canvas(CANVAS_WIDTH, SCREEN_HEIGHT)
   end
   if depth > draw_depth then
      draw_depth = depth
   end
   local canvas = canvas_stack[depth]
   local data = Pools.draw:alloc()
   data.x = math.floor(x)
   data.y = math.floor(y)
   data.right = math.floor(r)
   data.bottom = math.floor(b)
   data.color = color
   data.type = DRAW_TYPE.LINE
   data.order = #canvas.draw_queue + 1
   canvas.draw_queue[#canvas.draw_queue + 1] = data
end

local function update_draw_variables()
   screen_scale = memory.readwordsigned(0x0200DCBA) -- FBA can't read from 04xxxxxx
   screen_scale = 0x40 / (screen_scale > 0 and screen_scale or 1)
end

local function game_to_screen_space_x(x)
   return x - gamestate.screen_x + emu.screenwidth() / 2
end

local function game_to_screen_space_y(y)
   return emu.screenheight() - (y - gamestate.screen_y) - GROUND_OFFSET
end

local function game_to_screen_space(x, y)
   return game_to_screen_space_x(x), game_to_screen_space_y(y)
end

local function get_text_width(str) -- for gui.text
   if #str == 0 then
      return 0
   end
   return #str * 4 + 1
end

local function get_image(image_str, color)
   color = color or colors.text.default
   if not image_tables.images[image_str][color] then
      image_tables.images[image_str][color] =
         colors.substitute_color_gdstr(image_tables.images[image_str][colors.white], colors.white, color)
   end
   return image_tables.images[image_str][color]
end

local function draw_image(x, y, str, font, color, opacity)
   color = color or colors.white
   if image_tables.images[str][color] then
      gui.image(x, y, image_tables.images[str][color], opacity)
   else
      image_tables.images[str][color] =
         colors.substitute_color_gdstr(image_tables.images[str][colors.white], colors.white, color)
      gui.image(x, y, image_tables.images[str][color], opacity)
   end
end

local function draw_image_to_canvas(depth, x, y, str, font, color, opacity)
   color = color or colors.white
   if image_tables.images[str][color] then
      add_image_to_canvas(
         depth,
         x,
         y,
         image_tables.images[str].width,
         image_tables.images[str].height,
         image_tables.images[str][color]
      )
   else
      image_tables.images[str][color] =
         colors.substitute_color_gdstr(image_tables.images[str][colors.white], colors.white, color)
      add_image_to_canvas(
         depth,
         x,
         y,
         image_tables.images[str].width,
         image_tables.images[str].height,
         image_tables.images[str][color]
      )
   end
end

local function draw_text(x, y, str, font, color, opacity)
   if image_tables.text[str][font][color] then
      gui.image(x, y, image_tables.text[str][font][color], opacity)
   else
      image_tables.text[str][font][color] =
         colors.substitute_color_gdstr(image_tables.text[str][font][colors.white], colors.white, color)
      gui.image(x, y, image_tables.text[str][font][color], opacity)
   end
end

local function render_text(x, y, str, font, color, opacity)
   local offset = 0
   str = tostring(str)
   font = font or settings.language_tag
   color = color or colors.text.default
   opacity = opacity or 1

   -- draw block of text if it exists
   if image_tables.text[str] then
      draw_text(x + offset, y, str, font, color, opacity)
      return
   end

   -- check for jp text
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code >= 12288 and code <= 40879 then
         font = "jp"
         break
      end
   end

   -- render individual characters
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. code
         draw_text(x + offset, y, code, font, color, opacity)
         offset = offset + image_tables.text[code][font].width - 1
      else
         offset = offset + 2
      end
   end
end

local function draw_text_to_canvas(depth, x, y, str, font, color, opacity)
   if image_tables.text[str][font][color] then
      add_image_to_canvas(
         depth,
         x,
         y,
         image_tables.text[str][font].width,
         image_tables.text[str][font].height,
         image_tables.text[str][font][color]
      )
   else
      image_tables.text[str][font][color] =
         colors.substitute_color_gdstr(image_tables.text[str][font][colors.white], colors.white, color)
      add_image_to_canvas(
         depth,
         x,
         y,
         image_tables.text[str][font].width,
         image_tables.text[str][font].height,
         image_tables.text[str][font][color]
      )
   end
end

local function render_text_to_canvas(depth, x, y, str, font, color, opacity)
   local offset = 0
   str = tostring(str)
   font = font or settings.language_tag
   color = color or colors.text.default
   opacity = opacity or 1

   if image_tables.text[str] then
      draw_text_to_canvas(depth, x + offset, y, str, font, color, opacity)
      return
   end

   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      -- char is jp
      if code >= 12288 and code <= 40879 then
         font = "jp"
         break
      end
   end

   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. code
         draw_text_to_canvas(depth, x + offset, y, code, font, color, opacity)
         offset = offset + image_tables.text[code][font].width - 1
      else
         offset = offset + 2
      end
   end
end

local function get_text_dimensions(str, font)
   local w, h = 0, 0
   str = tostring(str)
   font = font or settings.language_tag

   if image_tables.text[str] then
      return image_tables.text[str][font].width, image_tables.text[str][font].height
   end

   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code >= 12288 and code <= 40879 then
         font = "jp"
         break
      end
   end

   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then
         code = "utf_" .. code
         w = w + image_tables.text[code][font].width
         h = image_tables.text[code][font].height
      else
         w = w + 3
      end
   end
   if str == "" then
      w = 2
   else
      w = w - utf8.len(str) + 1
   end
   return w, h
end

local function render_text_multiple(x, y, list_str, font, color, opacity)
   local offset_x, w = 0, 0
   for _, str in ipairs(list_str) do
      if image_tables.images[str] then
         draw_image(x + offset_x, y, str, font, color, opacity)
         w = image_tables.images[str].width
      else
         render_text(x + offset_x, y, str, font, color, opacity)
         w = get_text_dimensions(str, font)
      end
      offset_x = offset_x + w - 1
   end
end

local function render_text_multiple_to_canvas(depth, x, y, list_str, font, color, opacity)
   local offset_x, w = 0, 0
   for _, str in ipairs(list_str) do
      if image_tables.images[str] then
         draw_image_to_canvas(depth, x + offset_x, y, str, font, color, opacity)
         w = image_tables.images[str].width
      else
         render_text_to_canvas(depth, x + offset_x, y, str, font, color, opacity)
         w = get_text_dimensions(str, font)
      end
      offset_x = offset_x + w - 1
   end
end

local function get_text_dimensions_multiple(list_str, font)
   local total_w, total_h, w, h = 0, 0, 0, 0
   for _, str in ipairs(list_str) do
      if image_tables.images[str] then
         w, h = image_tables.images[str].width, image_tables.images[str].height
      else
         w, h = get_text_dimensions(str, font)
      end
      total_w = total_w + w - 1
      total_h = math.max(total_h, h)
   end
   return total_w, total_h
end

local function render_images_inline(x, y, list_str, font, list_color, opacity)
   local offset_x, offset_y, w, h, max_h = 0, 0, 0, 0, 0
   for _, str in ipairs(list_str) do
      if image_tables.images[str] then
         h = image_tables.images[str].height
      else
         w, h = get_text_dimensions(str, font)
      end
      if h > max_h then
         max_h = h
      end
   end
   for i, str in ipairs(list_str) do
      offset_y = 0
      local color = type(list_color) == "table" and list_color[i] or list_color
      if image_tables.images[str] then
         w, h = image_tables.images[str].width, image_tables.images[str].height
         if h < max_h then
            offset_y = (max_h - h) / 2
         end
         draw_image(x + offset_x, y + offset_y, str, font, color, opacity)
      else
         w, h = get_text_dimensions(str, font)
         if font == "en" then
            h = h - 2
         end
         if h < max_h then
            offset_y = (max_h - h) / 2
         end
         render_text(x + offset_x, y + offset_y, str, font, color, opacity)
      end
      offset_x = offset_x + w - 1
   end
end

local function draw_hitboxes(pos_x, pos_y, flip_x, boxes, extended, filter, dilation, color, opacity)
   dilation = dilation or 0
   local px, py = game_to_screen_space(pos_x, pos_y)
   local opacity_byte = 0xFF
   if opacity and opacity < 100 then
      opacity_byte = tools.float_to_byte(opacity / 100)
   end
   for __, box in pairs(boxes) do
      box = tools.format_box(box, extended, Pools.draw:alloc())
      if filter == nil or filter[box.type] == true then
         -- vulnerability
         local c = colors.hitboxes.vulnerability
         if box.type == "attack" then
            c = colors.hitboxes.attack
         elseif box.type == "throwable" then
            c = colors.hitboxes.throwable
         elseif box.type == "throw" then
            c = colors.hitboxes.throw
         elseif box.type == "push" then
            c = colors.hitboxes.push
         elseif box.type == "ext_vulnerability" then
            c = colors.hitboxes.ext_vulnerability
         elseif box.type == "attack_a" then
            c = colors.hitboxes.attack_a
         elseif box.type == "attack_b" then
            c = colors.hitboxes.attack_b
         end

         c = color or c

         if opacity then
            c = bit.band(c, 0xFFFFFF00) + opacity_byte
         end

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

local function draw_cross(x, y, color)
   local cross_half_size = 2
   local l = x - cross_half_size
   local r = x + cross_half_size
   local t = y - cross_half_size
   local b = y + cross_half_size

   gui.box(l, y, r, y, 0x00000000, color)
   gui.box(x, t, x, b, 0x00000000, color)
end

local function draw_controller_big(entry, x, y, style)
   if not entry then
      return
   end
   draw_image(x, y, image_tables.img_str_dir_big[entry.direction_raw], nil, colors.text.default)

   local img_str_LP = entry.buttons[1] and "img_LP_b" or "img_no_button_b"
   local img_str_MP = entry.buttons[2] and "img_MP_b" or "img_no_button_b"
   local img_str_HP = entry.buttons[3] and "img_HP_b" or "img_no_button_b"
   local img_str_LK = entry.buttons[4] and "img_LK_b" or "img_no_button_b"
   local img_str_MK = entry.buttons[5] and "img_MK_b" or "img_no_button_b"
   local img_str_HK = entry.buttons[6] and "img_HK_b" or "img_no_button_b"

   draw_image(x + 13, y, img_str_LP, nil, style)
   draw_image(x + 18, y, img_str_MP, nil, style)
   draw_image(x + 23, y, img_str_HP, nil, style)
   draw_image(x + 13, y + 5, img_str_LK, nil, style)
   draw_image(x + 18, y + 5, img_str_MK, nil, style)
   draw_image(x + 23, y + 5, img_str_HK, nil, style)
end

local function draw_buttons_preview_to_canvas(depth, x, y, style)
   draw_image_to_canvas(depth, x, y, "img_LP_b", nil, style)
   draw_image_to_canvas(depth, x + 5, y, "img_MP_b", nil, style)
   draw_image_to_canvas(depth, x + 10, y, "img_HP_b", nil, style)
   draw_image_to_canvas(depth, x, y + 5, "img_LK_b", nil, style)
   draw_image_to_canvas(depth, x + 5, y + 5, "img_MK_b", nil, style)
   draw_image_to_canvas(depth, x + 10, y + 5, "img_HK_b", nil, style)
end

local function draw_controller_small(entry, x, y, is_right, style)
   local x_offset = 0
   local sign = 1
   if is_right then
      x_offset = x_offset - 9
      sign = -1
   end

   draw_image(x + x_offset, y, image_tables.img_str_dir_small[entry.direction_raw], nil, colors.text.default)
   x_offset = x_offset + sign * 2

   local interval = 8
   x_offset = x_offset + sign * interval

   if entry.buttons[1] then
      draw_image(x + x_offset, y, "img_LP_s", nil, style)
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[2] then
      draw_image(x + x_offset, y, "img_MP_s", nil, style)
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[3] then
      draw_image(x + x_offset, y, "img_HP_s", nil, style)
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[4] then
      draw_image(x + x_offset, y, "img_LK_s", nil, style)
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[5] then
      draw_image(x + x_offset, y, "img_MK_s", nil, style)
      x_offset = x_offset + sign * interval
   end

   if entry.buttons[6] then
      draw_image(x + x_offset, y, "img_HK_s", nil, style)
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
      gui.box(
         x + width + 1,
         y,
         x + width - width * tools.clamp(fill_ratio, 0, 1),
         y + height + 1,
         fill_color,
         0x00000000
      )
   else
      gui.box(x, y, x + 1 + width * tools.clamp(fill_ratio, 0, 1), y + height + 1, fill_color, 0x00000000)
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

local function draw_horizontal_text_segment(p1_x, p2_x, y, str, line_color, edges_height, edges_style, font)
   local center_x = (p1_x + p2_x) * 0.5
   edges_height = edges_height or 3
   font = font or "tiny"
   local half_distance_str_width
   draw_horizontal_line(math.min(p1_x, p2_x), math.max(p1_x, p2_x), y, line_color, 1)
   local h
   half_distance_str_width, h = get_text_dimensions(str, font)
   half_distance_str_width = half_distance_str_width * 0.5
   render_text(center_x - half_distance_str_width, y - h / 2 + 1, str, font, colors.gui_text.default)

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

local function get_above_character_position(player, ignore_crouching)
   ignore_crouching = ignore_crouching or ignore_crouching == nil and true
   local char_height = 0
   local character_specific = require("src.data.framedata").character_specific
   if player.is_grounded then
      if player.is_crouching and not ignore_crouching then
         char_height = character_specific[player.char_str].height.crouching.max + 10
      else
         char_height = character_specific[player.char_str].height.standing.max + 10
      end
   else
      char_height = tools.get_boxes_average_position(player.boxes, tools.BOXES.VULN_AND_PUSH)
         or character_specific[player.char_str].height.standing.max
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
      if load_frame_data_bar_fading and load_frame_data_bar_elapsed > load_frame_data_bar_fade_time then
         return
      end
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
         local padding_x = 0
         local padding_y = 0
         local font = settings.language_tag
         if font == "jp" then
            font = "jp_8"
         end
         local w, h = get_text_dimensions("character_select_line_1", font)
         render_text(padding_x, padding_y, "character_select_line_1", font, nil, opacity)
         render_text(padding_x, padding_y + h, "character_select_line_2", font, nil, opacity)
         render_text(padding_x, padding_y + h + h, "character_select_line_3", font, nil, opacity)
      end
   end
end

local result = {}
for i = 1, CANVAS_WIDTH do
   result[#result + 1] = string.char(127, 0, 0, 0)
end
BLANK_ROW = table.concat(result)
BLANK_CANVAS = create_blank_canvas(CANVAS_WIDTH, CANVAS_HEIGHT)
menu_canvas = new_canvas(CANVAS_WIDTH, SCREEN_HEIGHT)
canvas_stack = { menu_canvas }

local draw = {
   SCREEN_WIDTH = SCREEN_WIDTH,
   SCREEN_HEIGHT = SCREEN_HEIGHT,
   CANVAS_WIDTH = CANVAS_WIDTH,
   CANVAS_HEIGHT = CANVAS_HEIGHT,
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
   render_images_inline = render_images_inline,
   add_image_to_canvas = add_image_to_canvas,
   add_box_to_canvas = add_box_to_canvas,
   add_line_to_canvas = add_line_to_canvas,
   new_canvas = new_canvas,
   clear_canvas = clear_canvas,
   draw_canvas = draw_canvas,
   clear_canvases = clear_canvases,
   draw_canvases = draw_canvases,
   controller_styles = controller_styles,
   controller_style_menu_names = image_tables.controller_style_menu_names,
   game_to_screen_space_x = game_to_screen_space_x,
   game_to_screen_space_y = game_to_screen_space_y,
   game_to_screen_space = game_to_screen_space,
   update_draw_variables = update_draw_variables,
   get_text_width = get_text_width,
   draw_image = draw_image,
   draw_image_to_canvas = draw_image_to_canvas,
   draw_hitboxes = draw_hitboxes,
   draw_cross = draw_cross,
   draw_controller_big = draw_controller_big,
   draw_buttons_preview_to_canvas = draw_buttons_preview_to_canvas,
   draw_controller_small = draw_controller_small,
   draw_gauge = draw_gauge,
   draw_horizontal_text_segment = draw_horizontal_text_segment,
   get_above_character_position = get_above_character_position,
   loading_bar_display = loading_bar_display,
   draw_character_select = draw_character_select,
}

setmetatable(draw, {
   __index = function(_, key)
      if colors[key] then
         return colors[key]
      elseif key == "menu_canvas" then
         return menu_canvas
      end
   end,
})

return draw
