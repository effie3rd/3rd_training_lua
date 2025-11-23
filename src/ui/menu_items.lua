local settings = require("src.settings")
local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local tools = require("src.tools")
local menu_tables = require("src.ui.menu_tables")
local image_tables = require("src.ui.image_tables")

local localization = tools.read_object_from_json_file("data/localization.json") or {}

local indent_width = 8

local Gauge_Menu_Item = {}
Gauge_Menu_Item.__index = Gauge_Menu_Item

function Gauge_Menu_Item:new(name, object, property_name, unit, fill_color, gauge_max, subdivision_count)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      autofire_rate = 1,
      unit = unit or 2,
      gauge_max = gauge_max or 0,
      subdivision_count = subdivision_count or 1,
      fill_color = fill_color or 0x0000FFFF,
      width = 0,
      height = 0,
      indent = false
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Gauge_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then color = colors.text.selected end

   local offset = 0
   if self.indent then offset = indent_width end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset, y, {self.name, ":  "}, nil, nil, color)
   local w, h = draw.get_text_dimensions_multiple({self.name, ":  "})

   offset = offset + w

   local box_width = self.gauge_max / self.unit
   local box_top = y + (h - 4) / 2
   if settings.language == "jp" then box_top = box_top + 1 end
   local box_left = x + offset
   local box_right = box_left + box_width
   local box_bottom = box_top + 4
   gui.box(box_left, box_top, box_right, box_bottom, colors.menu.gauge_background, colors.menu.gauge_border)
   local content_width = self.object[self.property_name] / self.unit
   gui.box(box_left, box_top, box_left + content_width, box_bottom, self.fill_color, 0x00000000)
   for i = 1, self.subdivision_count - 1 do
      local line_x = box_left + i * self.gauge_max / (self.subdivision_count * self.unit)
      gui.line(line_x, box_top, line_x, box_bottom, colors.menu.gauge_border)
   end

end

function Gauge_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  "})
   self.width = self.width + self.gauge_max / self.unit
end

function Gauge_Menu_Item:left()
   self.object[self.property_name] = math.max(self.object[self.property_name] - self.unit, 0)
end

function Gauge_Menu_Item:right()
   self.object[self.property_name] = math.min(self.object[self.property_name] + self.unit, self.gauge_max)
end

function Gauge_Menu_Item:reset() self.object[self.property_name] = 0 end

function Gauge_Menu_Item:legend() return "legend_mp_reset" end

local available_characters = {
   " ", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V",
   "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "_"
}

local Textfield_Menu_Item = {}
Textfield_Menu_Item.__index = Textfield_Menu_Item

function Textfield_Menu_Item:new(name, object, property_name, default_value, max_length)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      default_value = default_value or "",
      max_length = max_length or 16,
      edition_index = 0,
      is_in_edition = false,
      content = {},
      width = 0,
      height = 0
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   obj:sync_to_var()
   return obj
end

function Textfield_Menu_Item:sync_to_var()
   local str = ""
   for i = 1, #self.content do str = str .. available_characters[self.content[i]] end
   self.object[self.property_name] = str
end

function Textfield_Menu_Item:sync_from_var()
   self.content = {}
   for i = 1, #self.object[self.property_name] do
      local c = self.object[self.property_name]:sub(i, i)
      for j = 1, #available_characters do
         if available_characters[j] == c then
            self.content[#self.content + 1] = j
            break
         end
      end
   end
end

function Textfield_Menu_Item:crop_char_table()
   local last_empty_index = 0
   for i = 1, #self.content do
      if self.content[i] == 1 then
         last_empty_index = i
      else
         last_empty_index = 0
      end
   end

   if last_empty_index > 0 then
      for i = last_empty_index, #self.content do table.remove(self.content, last_empty_index) end
   end
end

function Textfield_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if self.is_in_edition then
      color = colors.text.button_activated
   elseif selected then
      color = colors.text.selected
   end

   local value = self.object[self.property_name]

   if self.is_in_edition then
      local frequency = 0.05
      color = colors.colorscale(color, (math.sin(gamestate.frame_number * frequency) + 1) / 2 * .5 + 0.5)
      self:calc_dimensions()
      local u_w = draw.get_text_dimensions("_")
      draw.render_text_to_canvas(draw.menu_canvas, x + self.width - u_w, y + 2, "_", nil, nil, color)
   end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x, y, {self.name, ":  ", value}, nil, nil, color)

end

function Textfield_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
end

function Textfield_Menu_Item:left() if self.is_in_edition then self:reset() end end

function Textfield_Menu_Item:right() if self.is_in_edition then self:validate() end end

function Textfield_Menu_Item:up()
   if self.is_in_edition then
      self.content[self.edition_index] = self.content[self.edition_index] + 1
      if self.content[self.edition_index] > #available_characters then self.content[self.edition_index] = 1 end
      self:sync_to_var()
      return false
   else
      return true
   end
end

function Textfield_Menu_Item:down()
   if self.is_in_edition then
      self.content[self.edition_index] = self.content[self.edition_index] - 1
      if self.content[self.edition_index] == 0 then self.content[self.edition_index] = #available_characters end
      self:sync_to_var()
      return false
   else
      return true
   end
end

function Textfield_Menu_Item:validate()
   if not self.is_in_edition then
      self:sync_from_var()
      if #self.content < self.max_length then self.content[#self.content + 1] = 1 end
      self.edition_index = #self.content
      self.is_in_edition = true
   else
      if self.content[self.edition_index] ~= 1 then
         if #self.content < self.max_length then
            self.content[#self.content + 1] = 1
            self.edition_index = #self.content
         end
      end
   end
   self:sync_to_var()
end

function Textfield_Menu_Item:reset()
   if not self.is_in_edition then
      self.content = {}
      self.edition_index = 0
   else
      if #self.content > 1 then
         table.remove(self.content, #self.content)
         self.edition_index = #self.content
      else
         self.content[1] = 1
      end
   end
   self:sync_to_var()
end

function Textfield_Menu_Item:cancel()
   if self.is_in_edition then
      self:crop_char_table()
      self:sync_to_var()
      self.is_in_edition = false
   end
end

function Textfield_Menu_Item:legend()
   if self.is_in_edition then
      return "legend_textfield_edit"
   else
      return "legend_textfield_edit2"
   end
end

local On_Off_Menu_Item = {}
On_Off_Menu_Item.__index = On_Off_Menu_Item

function On_Off_Menu_Item:new(name, object, property_name, default_value, on_change)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      default_value = default_value or false,
      indent = false,
      width = 0,
      height = 0,
      on_change = on_change
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function On_Off_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end

   local value = ""
   if self.object[self.property_name] then
      value = "menu_on"
   else
      value = "menu_off"
   end
   local offset = 0
   if self.indent then offset = indent_width end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset, y, {self.name, ":  ", value}, nil, nil, color)
end

function On_Off_Menu_Item:calc_dimensions()
   local value = ""
   if self.object[self.property_name] then
      value = "menu_on"
   else
      value = "menu_off"
   end
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  ", value})
end
function On_Off_Menu_Item:left()
   self.object[self.property_name] = not self.object[self.property_name]
   if self.on_change then self.on_change() end
end

function On_Off_Menu_Item:right()
   self.object[self.property_name] = not self.object[self.property_name]
   if self.on_change then self.on_change() end
end

function On_Off_Menu_Item:reset()
   self.object[self.property_name] = self.default_value
   if self.on_change then self.on_change() end
end

function On_Off_Menu_Item:legend() return "legend_mp_reset" end

local List_Menu_Item = {}
List_Menu_Item.__index = List_Menu_Item

function List_Menu_Item:new(name, object, property_name, list, default_value, on_change)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      list = list,
      default_value = default_value or 1,
      indent = false,
      on_change = on_change,
      width = 0,
      height = 0,
      is_selected = false
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function List_Menu_Item:draw(x, y, selected)
   self.is_selected = selected
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end
   local offset = 0
   if self.indent then offset = indent_width end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset, y,
                                       {self.name, ":  ", self.list[self.object[self.property_name]]}, nil, nil, color)
end

function List_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({
      self.name, ":  ", self.list[self.object[self.property_name]]
   })
end

function List_Menu_Item:left()

   self.object[self.property_name] = self.object[self.property_name] - 1
   if self.object[self.property_name] == 0 then self.object[self.property_name] = #self.list end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function List_Menu_Item:right()

   self.object[self.property_name] = self.object[self.property_name] + 1
   if self.object[self.property_name] > #self.list then self.object[self.property_name] = 1 end

   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function List_Menu_Item:reset()
   self.object[self.property_name] = self.default_value
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function List_Menu_Item:legend() return "legend_mp_reset" end

local Check_Box_Grid_Item = {}
Check_Box_Grid_Item.__index = Check_Box_Grid_Item
Check_Box_Grid_Item.__name = "Check_Box_Grid_Item"

function Check_Box_Grid_Item:new(name, object, list, max_cols, on_change)
   local obj = {
      name = name,
      object = object or {},
      list = list,
      indent = false,
      default_value = false,
      on_change = on_change,
      width = 360 - 23 - 15 * 2,
      height = 0,
      max_cols = max_cols,
      cols = 1,
      rows = 1,
      col_width = 100,
      row_height = 10,
      selected_col = 1,
      selected_row = 1,
      spacing = 14,
      checkbox_padding_x = 11,
      is_enabled = function() return true end,
      is_unselectable = function() return false end,
      last_frame_validated = 0
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Check_Box_Grid_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end
   local offset_x, offset_y = 0, 0
   if self.indent then offset_x = indent_width end
   if self.last_frame_validated > gamestate.frame_number then self.last_frame_validated = 0 end
   local max_width = 0
   for _, name in ipairs(self.list) do
      local w, h = draw.get_text_dimensions(name)
      if w > max_width then max_width = w end
   end
   self.col_width = math.max(max_width + 20, 50)
   local checkbox_offset_y = -1
   if settings.language == "jp" then checkbox_offset_y = 2 end

   local text_table = {}
   if type(self.name) == "table" then
      text_table = {unpack(self.name)}
      text_table[#text_table + 1] = ":  "
   else
      text_table = {self.name, ":  "}
   end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset_x, y + offset_y, text_table, nil, nil, color)

   local tx, ty = draw.get_text_dimensions_multiple(text_table)
   offset_x = offset_x + tx

   self.row_height = ty + 2

   local sel_index = (self.selected_row - 1) * self.cols + self.selected_col
   local base_color = colors.text.default
   if not self:is_enabled() then base_color = colors.text.disabled end

   for row = 1, self.rows do
      local col_offset = 0
      for col = 1, self.cols do
         local index = (row - 1) * self.cols + col
         if self.list[index] then
            local row_offset = self.row_height * (row - 1)
            local item_color = base_color
            local checkbox_image = image_tables.images.img_kaku -- unchecked
            if self.object[index] then checkbox_image = image_tables.images.img_maru end -- checked
            if index == sel_index and selected then
               item_color = colors.text.selected
               if (gamestate.frame_number - self.last_frame_validated < 5) then
                  item_color = colors.text.button_activated
               end
            end
            local checkbox = draw.get_image(checkbox_image, item_color)
            draw.add_image_to_canvas(draw.menu_canvas, x + offset_x + col_offset,
                                     y + offset_y + row_offset + checkbox_offset_y, image_tables.check_box_width,
                                     image_tables.check_box_height, checkbox)
            draw.render_text_to_canvas(draw.menu_canvas, x + offset_x + col_offset + self.checkbox_padding_x,
                                       y + offset_y + row_offset, self.list[index], nil, nil, item_color)

            local w, h = draw.get_text_dimensions(self.list[index])
            col_offset = col_offset + self.checkbox_padding_x + w + self.spacing
         end
      end
   end
end

function Check_Box_Grid_Item:calc_dimensions()
   local text_table = {}
   if type(self.name) == "table" then
      text_table = {unpack(self.name)}
      text_table[#text_table + 1] = ":  "
   else
      text_table = {self.name, ":  "}
   end
   local w, h = draw.get_text_dimensions_multiple(text_table)
   self.row_height = h + 2

   local total_space = self.width - w
   local total_width = 0
   self.cols = self.max_cols
   local shrunk = false
   local j = 1
   while j <= #self.list do
      total_width = 0
      for i = 1, self.cols do
         local tw, th = draw.get_text_dimensions(self.list[j + i - 1])
         total_width = total_width + self.checkbox_padding_x + tw

         if total_width > total_space then
            if i - 1 < self.cols then
               self.cols = i - 1
               shrunk = true
            end
            break
         end
         total_width = total_width + self.spacing
      end
      if shrunk then
         j = 1
         shrunk = false
      else
         j = j + self.cols
      end
   end
   self.rows = math.max(math.floor((#self.list - 1) / self.cols) + 1, 1)
   self.height = self.rows * self.row_height - 1
end

function Check_Box_Grid_Item:at_least_one_selected()
   for i = 1, #self.object do if self.object[i] then return true end end
   return false
end

function Check_Box_Grid_Item:up()
   local should_exit_grid = false
   self.selected_row = self.selected_row - 1
   if self.selected_row < 1 then
      self.selected_row = 1
      self.selected_col = 1
      should_exit_grid = true
   end
   if self.selected_row == self.rows then
      local last_col = (#self.object - 1) % self.cols + 1
      if self.selected_col > last_col then self.selected_col = last_col end
   end
   if self.on_change then self.on_change() end
   return should_exit_grid
end

function Check_Box_Grid_Item:down()
   local should_exit_grid = false
   self.selected_row = self.selected_row + 1
   if self.selected_row > self.rows then
      self.selected_row = 1
      self.selected_col = 1
      should_exit_grid = true
   end
   if self.selected_row == self.rows then
      local last_col = (#self.object - 1) % self.cols + 1
      if self.selected_col > last_col then self.selected_col = last_col end
   end
   if self.on_change then self.on_change() end
   return should_exit_grid
end

function Check_Box_Grid_Item:left()
   self.selected_col = tools.wrap_index(self.selected_col - 1, self.cols)
   if self.selected_row == self.rows then
      local last_col = (#self.object - 1) % self.cols + 1
      if self.selected_col > last_col then self.selected_col = last_col end
   end
   if self.on_change then self.on_change() end
end

function Check_Box_Grid_Item:right()
   self.selected_col = tools.wrap_index(self.selected_col + 1, self.cols)
   if self.selected_row == self.rows then
      local last_col = (#self.object - 1) % self.cols + 1
      if self.selected_col > last_col then self.selected_col = last_col end
   end
   if self.on_change then self.on_change() end
end

function Check_Box_Grid_Item:validate(input)
   if self:is_enabled() then
      if input.press or input.down then self.last_frame_validated = gamestate.frame_number end
      if input.release then
         local index = (self.selected_row - 1) * self.cols + self.selected_col
         self.object[index] = not self.object[index]
      end
   end
end

function Check_Box_Grid_Item:reset(input)
   if self:is_enabled() then
      if input.press or input.down then self.last_frame_validated = gamestate.frame_number end
      if input.release then
         local index = (self.selected_row - 1) * self.cols + self.selected_col
         self.object[index] = self.default_value
      end
   end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Check_Box_Grid_Item:legend() return "legend_lp_mp_select_reset" end

local Slider_Menu_Item = {}
Slider_Menu_Item.__index = Slider_Menu_Item
Slider_Menu_Item.__name = "Slider_Menu_Item"

function Slider_Menu_Item:new(name, line_width, points, range)
   local obj = {
      name = name,
      indent = false,
      line_width = line_width or 100,
      mode = 1,
      points = points,
      range = range,
      point_index = 1,
      width = 0,
      height = 0,
      max_points = 2,
      last_frame_validated = 0,
      disable_mode_switch = false,
      autofire_rate = 1,
      autofire_time = 5,
      legend_text = "legend_lp_mode",
      is_enabled = function() return true end,
      is_unselectable = function() return false end
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Slider_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end
   if self.last_frame_validated > gamestate.frame_number then self.last_frame_validated = 0 end
   if (gamestate.frame_number - self.last_frame_validated < 5) then color = colors.text.button_activated end

   local offset_x = 0
   if self.indent then offset_x = indent_width end

   local text_table = {self.name, ":  "}
   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset_x, y, text_table, nil, nil, color)

   local w, h = draw.get_text_dimensions_multiple(text_table)
   offset_x = offset_x + w

   local box_width = self.line_width + 2
   local box_top = y + (h - 4) / 2
   if settings.language == "jp" then box_top = box_top + 1 end
   local box_left = x + offset_x
   local box_right = box_left + box_width
   local box_bottom = box_top + 2
   local arrow_offset = -3
   gui.box(box_left, box_top, box_right, box_bottom, color, colors.menu.gauge_border)

   local arrow_color, arrow_position
   if self.mode == 2 then
      local num_points = 2
      for i = 1, num_points do
         arrow_color = color == colors.text.disabled and colors.text.disabled or colors.text.inactive
         if i ~= self.point_index then
            arrow_position = math.floor((self.points[i] - self.range[1]) / (self.range[2] - self.range[1]) *
                                            self.line_width)
            draw.add_image_to_canvas(draw.menu_canvas, box_left + arrow_offset + arrow_position + 1, box_bottom + 1,
                                     image_tables.scroll_arrow_width, image_tables.scroll_arrow_height,
                                     draw.get_image(image_tables.images.img_scroll_up, arrow_color))
         end
      end
   end
   arrow_color = color
   arrow_position = math.floor((self.points[self.point_index] - self.range[1]) / (self.range[2] - self.range[1]) *
                                   self.line_width)
   draw.add_image_to_canvas(draw.menu_canvas, box_left + arrow_offset + arrow_position + 1, box_bottom + 1,
                            image_tables.scroll_arrow_width, image_tables.scroll_arrow_height,
                            draw.get_image(image_tables.images.img_scroll_up, arrow_color))

   local num_text
   if self.mode == 1 then
      num_text = {"  ", self.points[1]}
   else
      num_text = {"  ", self.points[1], "—", self.points[2]}
   end
   draw.render_text_multiple_to_canvas(draw.menu_canvas, box_right, y, num_text, nil, nil, color)
end

function Slider_Menu_Item:calc_dimensions()
   local w, h = draw.get_text_dimensions_multiple({self.name, ":  "})
   local num_text
   if self.mode == 1 then
      num_text = {"  ", self.points[1]}
   else
      num_text = {"  ", self.points[1], "—", self.points[2]}
   end
   local nw, nh = draw.get_text_dimensions_multiple(num_text)
   self.width, self.height = w + nw + self.line_width, h
end

function Slider_Menu_Item:left()
   if self.left_function then
      self.left_function()
   else
      local value
      if self.mode == 1 then
         value = self.points[1]
         value = tools.clamp(value - 1, self.range[1], self.range[2])
         self.points[1] = value
      else
         value = self.points[self.point_index] - 1
         while value >= self.range[1] do
            if not tools.table_contains(self.points, value) then break end
            value = value - 1
         end
         value = tools.clamp(value, self.range[1], self.range[2])
         self.points[self.point_index] = value
      end
   end
   local val = self.points[self.point_index]
   table.sort(self.points)
   self.point_index = tools.table_indexof(self.points, val) or 1
   if self.on_change then self.on_change() end
end

function Slider_Menu_Item:right()
   if self.right_function then
      self.right_function()
   else
      local value
      if self.mode == 1 then
         value = self.points[1]
         value = tools.clamp(value + 1, self.range[1], self.range[2])
         self.points[1] = value
      else
         value = self.points[self.point_index] + 1
         while value <= self.range[2] do
            if not tools.table_contains(self.points, value) then break end
            value = value + 1
         end
         value = tools.clamp(value, self.range[1], self.range[2])
         self.points[self.point_index] = value
      end
   end
   local val = self.points[self.point_index]
   table.sort(self.points)
   self.point_index = tools.table_indexof(self.points, val) or 1
   if self.on_change then self.on_change() end
end

function Slider_Menu_Item:validate(input)
   if input.press or input.down then self.last_frame_validated = gamestate.frame_number end
   if not self.disable_mode_switch and input.release then
      self.mode = self.mode % 2 + 1
      if self.validate_function then self.validate_function() end
      if self.mode == 1 then
         self.legend_text = "legend_lp_mode"
         self.point_index = 1
      elseif self.mode == 2 then
         self.legend_text = "legend_mp_point"
      end
   end
end

function Slider_Menu_Item:reset(input)
   if self.mode == 2 and input.release then
      self.point_index = self.point_index % self.max_points + 1
      if self.reset_function then self.reset_function() end
   end
end

function Slider_Menu_Item:legend() return self.legend_text end

local Motion_List_Menu_Item = {}
Motion_List_Menu_Item.__index = Motion_List_Menu_Item

function Motion_List_Menu_Item:new(name, object, property_name, list, default_value, on_change)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      list = list,
      default_value = default_value or 1,
      indent = false,
      on_change = on_change or nil,
      width = 0,
      height = 0
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Motion_List_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end
   local offset_x = 0
   local offset_y = -1
   if self.indent then offset_x = indent_width end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset_x, y, {self.name, ":  "}, nil, nil, color)
   local w, _ = draw.get_text_dimensions_multiple({self.name, ":  "})
   offset_x = offset_x + w

   if settings.language == "jp" then offset_y = 2 end

   local img_list = {}
   local style = draw.controller_styles[settings.training.controller_style]
   local id = self.object[self.property_name]
   for i = 1, #self.list[id] do
      local dirs = {forward = false, down = false, back = false, up = false}
      local added = 0
      for j = 1, #self.list[id][i] do
         if self.list[id][i][j] == "forward" then
            dirs.forward = true
         elseif self.list[id][i][j] == "down" then
            dirs.down = true
         elseif self.list[id][i][j] == "back" then
            dirs.back = true
         elseif self.list[id][i][j] == "up" then
            dirs.up = true
         elseif self.list[id][i][j] == "LP" then
            added = added + 1
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][1]
         elseif self.list[id][i][j] == "MP" then
            added = added + 1
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][2]
         elseif self.list[id][i][j] == "HP" then
            added = added + 1
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][3]
         elseif self.list[id][i][j] == "LK" then
            added = added + 1
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
         elseif self.list[id][i][j] == "MK" then
            added = added + 1
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
         elseif self.list[id][i][j] == "HK" then
            added = added + 1
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][6]
         elseif self.list[id][i][j] == "EXP" then
            added = added + 2
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][1]
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][2]
         elseif self.list[id][i][j] == "EXK" then
            added = added + 2
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
         elseif self.list[id][i][j] == "PPP" then
            added = added + 3
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][1]
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][2]
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][3]
         elseif self.list[id][i][j] == "KKK" then
            added = added + 3
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
            img_list[#img_list + 1] = image_tables.images.img_button_small[style][6]
         elseif self.list[id][i][j] == "h_charge" then
            added = added + 1
            img_list[#img_list + 1] = draw.get_image(image_tables.images.img_hold, color)
         elseif self.list[id][i][j] == "v_charge" then
            added = added + 1
            img_list[#img_list + 1] = draw.get_image(image_tables.images.img_hold, color)
         elseif self.list[id][i][j] == "neutral" then
            added = added + 1
            img_list[#img_list + 1] = draw.get_image(image_tables.images.img_dir_small[5], color)
         elseif self.list[id][i][j] == "maru" then
            added = added + 1
            img_list[#img_list + 1] = draw.get_image(image_tables.images.img_maru, color)
         elseif self.list[id][i][j] == "tilda" then
            added = added + 1
            img_list[#img_list + 1] = draw.get_image(image_tables.images.img_tilda, color)
         end
      end
      local dir = 0
      if dirs.forward then
         dir = 6
         if dirs.down then
            dir = 3
         elseif dirs.up then
            dir = 9
         end
      elseif dirs.back then
         dir = 4
         if dirs.down then
            dir = 1
         elseif dirs.up then
            dir = 7
         end
      elseif dirs.down then
         dir = 2
      elseif dirs.up then
         dir = 8
      end

      if dir > 0 then
         if added > 0 then
            table.insert(img_list, #img_list - added + 1, draw.get_image(image_tables.images.img_dir_small[dir], color))
         else
            img_list[#img_list + 1] = draw.get_image(image_tables.images.img_dir_small[dir], color)
         end
      end
   end
   for i = 1, #img_list do
      draw.add_image_to_canvas(draw.menu_canvas, x + offset_x, y + offset_y, image_tables.dir_small_width,
                               image_tables.dir_small_height, img_list[i])
      offset_x = offset_x + image_tables.dir_small_width
   end

end

function Motion_List_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  "})
   self.width = self.width + 7
end

function Motion_List_Menu_Item:left()
   self.object[self.property_name] = self.object[self.property_name] - 1
   if self.object[self.property_name] == 0 then self.object[self.property_name] = #self.list end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Motion_List_Menu_Item:right()
   self.object[self.property_name] = self.object[self.property_name] + 1
   if self.object[self.property_name] > #self.list then self.object[self.property_name] = 1 end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Motion_List_Menu_Item:reset()
   self.object[self.property_name] = self.default_value
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Motion_List_Menu_Item:legend() return "legend_mp_reset" end

local Move_Input_Display_Menu_Item = {}
Move_Input_Display_Menu_Item.__index = Move_Input_Display_Menu_Item

function Move_Input_Display_Menu_Item:new(name, object, select_special_item)
   local obj = {
      name = name,
      object = object,
      indent = false,
      width = 0,
      height = 0,
      inline = false,
      img_list = {},
      select_special_item = select_special_item,
      is_unselectable = function() return true end
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Move_Input_Display_Menu_Item:draw(x, y)

   local offset_x = 6
   local offset_y = -1
   if settings.language == "jp" then offset_y = 2 end
   if self.indent then offset_x = indent_width end
   local img_list = {}
   local move_inputs = self.object.inputs
   local style = draw.controller_styles[settings.training.controller_style]
   local color = colors.text.default
   if self.select_special_item.is_enabled and not self.select_special_item:is_enabled() then
      color = colors.text.disabled
   elseif self.select_special_item.is_selected then
      color = colors.text.selected
   end

   if menu_tables.move_selection_type[self.object.type] == "menu_special_sa" then
      for i = 1, #move_inputs do
         local dirs = {forward = false, down = false, back = false, up = false}
         local added = 0
         for j = 1, #move_inputs[i] do
            if move_inputs[i][j] == "forward" then
               dirs.forward = true
            elseif move_inputs[i][j] == "down" then
               dirs.down = true
            elseif move_inputs[i][j] == "back" then
               dirs.back = true
            elseif move_inputs[i][j] == "up" then
               dirs.up = true
            elseif move_inputs[i][j] == "LP" then
               added = added + 1
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][1]
            elseif move_inputs[i][j] == "MP" then
               added = added + 1
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][2]
            elseif move_inputs[i][j] == "HP" then
               added = added + 1
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][3]
            elseif move_inputs[i][j] == "LK" then
               added = added + 1
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
            elseif move_inputs[i][j] == "MK" then
               added = added + 1
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
            elseif move_inputs[i][j] == "HK" then
               added = added + 1
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][6]
            elseif move_inputs[i][j] == "EXP" then
               added = added + 2
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][1]
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][2]
            elseif move_inputs[i][j] == "EXK" then
               added = added + 2
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
            elseif move_inputs[i][j] == "PPP" then
               added = added + 3
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][1]
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][2]
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][3]
            elseif move_inputs[i][j] == "KKK" then
               added = added + 3
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
               img_list[#img_list + 1] = image_tables.images.img_button_small[style][6]
            elseif move_inputs[i][j] == "h_charge" then
               added = added + 1
               img_list[#img_list + 1] = draw.get_image(image_tables.images.img_hold, color)
            elseif move_inputs[i][j] == "v_charge" then
               added = added + 1
               img_list[#img_list + 1] = draw.get_image(image_tables.images.img_hold, color)
            elseif move_inputs[i][j] == "v_charge" then
               added = added + 1
               img_list[#img_list + 1] = draw.get_image(image_tables.images.img_hold, color)
            elseif move_inputs[i][j] == "legs_LK" then
               for k = 1, 4 do
                  added = added + 1
                  img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
               end
            elseif move_inputs[i][j] == "legs_MK" then
               for k = 1, 4 do
                  added = added + 1
                  img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
               end
            elseif move_inputs[i][j] == "legs_HK" then
               for k = 1, 4 do
                  added = added + 1
                  img_list[#img_list + 1] = image_tables.images.img_button_small[style][6]
               end
            elseif move_inputs[i][j] == "legs_EXK" then
               for k = 1, 4 do
                  added = added + 1
                  img_list[#img_list + 1] = image_tables.images.img_button_small[style][4]
                  img_list[#img_list + 1] = image_tables.images.img_button_small[style][5]
               end
            elseif move_inputs[i][j] == "maru" then
               added = added + 1
               img_list[#img_list + 1] = draw.get_image(image_tables.images.img_maru, color)
            elseif move_inputs[i][j] == "tilda" then
               added = added + 1
               img_list[#img_list + 1] = draw.get_image(image_tables.images.img_tilda, color)
            elseif move_inputs[i][j] == "button" then
               added = added + 1
               img_list[#img_list + 1] = "button"
            end
         end
         local dir = 0
         if dirs.forward then
            dir = 6
            if dirs.down then
               dir = 3
            elseif dirs.up then
               dir = 9
            end
         elseif dirs.back then
            dir = 4
            if dirs.down then
               dir = 1
            elseif dirs.up then
               dir = 7
            end
         elseif dirs.down then
            dir = 2
         elseif dirs.up then
            dir = 8
         end

         if dir > 0 then
            if added > 0 then
               table.insert(img_list, #img_list - added + 1,
                            draw.get_image(image_tables.images.img_dir_small[dir], color))
            else
               img_list[#img_list + 1] = draw.get_image(image_tables.images.img_dir_small[dir], color)
            end
         else
            if added == 0 then img_list[#img_list + 1] = "none" end
         end
      end

      local start = 0
      local length = 1
      local matching = false
      local i = 2
      while i <= #img_list do
         if img_list[i] == img_list[i - 1] then
            if not matching then
               start = i
               matching = true
            else
               length = length + 1
            end
         else
            if matching then
               if length > 1 then
                  for j = 1, length do table.remove(img_list, start) end
                  table.insert(img_list, start, draw.get_image(image_tables.images.img_hold, color))
                  i = 2
               end
               start = 0
               length = 1
               matching = false
            end
         end
         i = i + 1
      end

      start = #img_list
      matching = false
      i = #img_list

      while i >= 2 do
         if matching then
            if img_list[i - 1] == img_list[start] then
               table.remove(img_list, i - 1)
               i = i + 1
            else
               matching = false
            end
         end
         if img_list[i] == draw.get_image(image_tables.images.img_hold, color) then
            if not matching then
               start = i - 1
               matching = true
            end
         end
         i = i - 1
      end

      i = 1
      while i <= #img_list do
         if img_list[i] == "none" then
            table.remove(img_list, i)
         else
            i = i + 1
         end
      end

      for j = 1, #img_list do
         draw.add_image_to_canvas(draw.menu_canvas, x + offset_x, y + offset_y, image_tables.dir_small_width,
                                  image_tables.dir_small_height, img_list[j])
         offset_x = offset_x + image_tables.dir_small_width
      end
      self.img_list = img_list
   elseif menu_tables.move_selection_type[self.object.type] == "menu_option_select" then
   end
   self:calc_dimensions()
end

function Move_Input_Display_Menu_Item:calc_dimensions() self.width, self.height = #self.img_list * 9, 9 end

local Controller_Style_Item = {}
Controller_Style_Item.__index = Controller_Style_Item

function Controller_Style_Item:new(name, object, property_name, list, default_value, on_change)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      list = list,
      default_value = default_value or 1,
      indent = false,
      on_change = on_change or nil,
      width = 0,
      height = 0
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Controller_Style_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then color = colors.text.selected end
   local offset_x = 0
   if self.indent then offset_x = indent_width end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset_x, y, {self.name, ":  "}, nil, nil, color)
   local w, _ = draw.get_text_dimensions_multiple({self.name, ":  "})

   offset_x = offset_x + w
   local c_offset_y = -2
   if settings.language == "jp" then c_offset_y = 2 end
   local style = draw.controller_styles[self.object[self.property_name]]
   draw.draw_buttons_preview_big(x + offset_x, y + c_offset_y, style)
   offset_x = offset_x + 21
   draw.render_text_to_canvas(draw.menu_canvas, x + offset_x, y, tostring(self.list[self.object[self.property_name]]),
                              nil, nil, color)
end

function Controller_Style_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  "})
   local w, _ = draw.get_text_dimensions(self.list[self.object[self.property_name]])
   self.width = self.width + w
end

function Controller_Style_Item:left()
   self.object[self.property_name] = self.object[self.property_name] - 1
   if self.object[self.property_name] == 0 then self.object[self.property_name] = #self.list end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Controller_Style_Item:right()
   self.object[self.property_name] = self.object[self.property_name] + 1
   if self.object[self.property_name] > #self.list then self.object[self.property_name] = 1 end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Controller_Style_Item:reset()
   self.object[self.property_name] = self.default_value
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Controller_Style_Item:legend() return "legend_mp_reset" end

local Integer_Menu_Item = {}
Integer_Menu_Item.__index = Integer_Menu_Item

function Integer_Menu_Item:new(name, object, property_name, min, max, loop, default_value, increment, autofire_rate,
                               on_change)
   if default_value == nil then default_value = min end
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      min = min,
      max = max,
      loop = loop,
      default_value = default_value,
      increment = increment or 1,
      autofire_rate = autofire_rate,
      on_change = on_change or nil,
      width = 0,
      height = 0,
      indent = false
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Integer_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end
   local offset_x = 0
   local w, h = 0, 0
   if self.indent then offset_x = indent_width end

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset_x, y,
                                       {self.name, ":  ", self.object[self.property_name]}, nil, nil, color)

end

function Integer_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
end

function Integer_Menu_Item:left()
   self.object[self.property_name] = self.object[self.property_name] - self.increment
   if self.object[self.property_name] < self.min then
      if self.loop then
         self.object[self.property_name] = self.max
      else
         self.object[self.property_name] = self.min
      end
   end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Integer_Menu_Item:right()
   self.object[self.property_name] = self.object[self.property_name] + self.increment
   if self.object[self.property_name] > self.max then
      if self.loop then
         self.object[self.property_name] = self.min
      else
         self.object[self.property_name] = self.max
      end
   end
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Integer_Menu_Item:reset()
   self.object[self.property_name] = self.default_value
   self:calc_dimensions()
   if self.on_change then self.on_change() end
end

function Integer_Menu_Item:legend() return "legend_mp_reset" end

local Hits_Before_Menu_Item = {}
Hits_Before_Menu_Item.__index = Hits_Before_Menu_Item

function Hits_Before_Menu_Item:new(name, suffix, object, property_name, min, max, loop, default_value, autofire_rate)
   if default_value == nil then default_value = min end
   local obj = {
      name = name,
      suffix = suffix,
      object = object,
      property_name = property_name,
      min = min,
      max = max,
      loop = loop,
      default_value = default_value,
      autofire_rate = autofire_rate,
      width = 0,
      height = 0,
      indent = false
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Hits_Before_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end

   local offset_x = 0
   if self.indent then offset_x = indent_width end
   local w, h = 0, 0

   if localization[self.name][settings.language] ~= "" then
      draw.render_text_to_canvas(draw.menu_canvas, x + offset_x, y, self.name, nil, nil, color)
      w, h = draw.get_text_dimensions(self.name)
      offset_x = offset_x + w + 1
   end
   draw.render_text_to_canvas(draw.menu_canvas, x + offset_x, y, self.object[self.property_name], nil, nil, color)
   w, h = draw.get_text_dimensions(self.object[self.property_name])
   offset_x = offset_x + w + 1

   local hits_text = "menu_hits"
   if settings.language == "en" then
      if self.object[self.property_name] == 1 then hits_text = "menu_hit" end
      draw.render_text_to_canvas(draw.menu_canvas, x + offset_x, y, hits_text, nil, nil, color)
      w, h = draw.get_text_dimensions(hits_text)
      offset_x = offset_x + w + 1
   end
   if self.suffix ~= "" then
      draw.render_text_to_canvas(draw.menu_canvas, x + offset_x, y, self.suffix, nil, nil, color)
   end

end

function Hits_Before_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
end

function Hits_Before_Menu_Item:left()
   self.object[self.property_name] = self.object[self.property_name] - 1
   if self.object[self.property_name] < self.min then
      if self.loop then
         self.object[self.property_name] = self.max
      else
         self.object[self.property_name] = self.min
      end
   end
end

function Hits_Before_Menu_Item:right()
   self.object[self.property_name] = self.object[self.property_name] + 1
   if self.object[self.property_name] > self.max then
      if self.loop then
         self.object[self.property_name] = self.min
      else
         self.object[self.property_name] = self.max
      end
   end
end

function Hits_Before_Menu_Item:reset() self.object[self.property_name] = self.default_value end

function Hits_Before_Menu_Item:legend() return "legend_mp_reset" end

local Map_Menu_Item = {}
Map_Menu_Item.__index = Map_Menu_Item

function Map_Menu_Item:new(name, object, property_name, map_object, map_property)
   local obj = {
      name = name,
      object = object,
      property_name = property_name,
      map_object = map_object,
      map_property = map_property,
      width = 0,
      height = 0
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Map_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected
   elseif self.is_enabled and not self:is_enabled() then
      color = colors.text.disabled
   end

   local offset_x = 0

   draw.render_text_multiple_to_canvas(draw.menu_canvas, x + offset_x, y,
                                       {self.name, ":  ", self.object[self.property_name]}, nil, nil, color)

end

function Map_Menu_Item:calc_dimensions()
   self.width, self.height = draw.get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
end

function Map_Menu_Item:left()
   if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then return end

   if self.object[self.property_name] == "" then
      for key, value in pairs(self.map_object[self.map_property]) do self.object[self.property_name] = key end
   else
      local previous_key = ""
      for key, value in pairs(self.map_object[self.map_property]) do
         if key == self.object[self.property_name] then
            self.object[self.property_name] = previous_key
            return
         end
         previous_key = key
      end
      self.object[self.property_name] = ""
   end
end

function Map_Menu_Item:right()
   if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then return end

   if self.object[self.property_name] == "" then
      for key, value in pairs(self.map_object[self.map_property]) do
         self.object[self.property_name] = key
         return
      end
   else
      local previous_key = ""
      for key, value in pairs(self.map_object[self.map_property]) do
         if previous_key == self.object[self.property_name] then
            self.object[self.property_name] = key
            return
         end
         previous_key = key
      end
      self.object[self.property_name] = ""
   end
end

function Map_Menu_Item:reset() self.object[self.property_name] = "" end

function Map_Menu_Item:legend() return "legend_mp_reset" end

local Button_Menu_Item = {}
Button_Menu_Item.__index = Button_Menu_Item

function Button_Menu_Item:new(name, validate_function)
   local obj = {
      name = name,
      width = 0,
      height = 0,
      validate_function = validate_function,
      last_frame_validated = 0,
      legend_text = "legend_lp_select",
      is_enabled = function() return true end
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Button_Menu_Item:draw(x, y, selected)
   local color = colors.text.default
   if selected then
      color = colors.text.selected

      if self.last_frame_validated > gamestate.frame_number then self.last_frame_validated = 0 end
      if (gamestate.frame_number - self.last_frame_validated < 5) then color = colors.text.button_activated end
   end
   if self.is_enabled and not self:is_enabled() then color = colors.text.disabled end

   if type(self.name) == "table" then
      draw.render_text_multiple_to_canvas(draw.menu_canvas, x, y, self.name, nil, nil, color)
   else
      draw.render_text_to_canvas(draw.menu_canvas, x, y, self.name, nil, nil, color)
   end
end

function Button_Menu_Item:calc_dimensions()
   if type(self.name) == "table" then
      self.width, self.height = draw.get_text_dimensions_multiple(self.name)
   else
      self.width, self.height = draw.get_text_dimensions(self.name)
   end
end

function Button_Menu_Item:validate(input)
   if self:is_enabled() then
      if input.press or input.down then self.last_frame_validated = gamestate.frame_number end
      if input.release and self.validate_function then self.validate_function() end
   end
end

function Button_Menu_Item:legend() return self.legend_text end

local Header_Menu_Item = {}
Header_Menu_Item.__index = Header_Menu_Item

function Header_Menu_Item:new(name)
   local obj = {name = name, width = 0, height = 0}

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Header_Menu_Item:draw(x, y, state)
   local color = colors.text.default
   if state == "active" then
      color = colors.text.default
   elseif state == "selected" then
      color = colors.text.selected
   elseif state == "inactive" then
      color = colors.text.inactive
   end

   draw.render_text_to_canvas(draw.menu_canvas, x, y, self.name, nil, nil, color)
end

function Header_Menu_Item:calc_dimensions() self.width, self.height = draw.get_text_dimensions(self.name) end

local Footer_Menu_Item = {}
Footer_Menu_Item.__index = Footer_Menu_Item

function Footer_Menu_Item:new(name)
   local obj = {name = name, width = 0, height = 0}

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Footer_Menu_Item:draw(x, y, state)
   local color = colors.text.inactive
   draw.render_text_to_canvas(draw.menu_canvas, x, y, self.name, settings.language, nil, color)
end

function Footer_Menu_Item:calc_dimensions() self.width, self.height = draw.get_text_dimensions(self.name) end

local Label_Menu_Item = {}
Label_Menu_Item.__index = Label_Menu_Item

function Label_Menu_Item:new(name, text_list, object, property, small, inline)
   local index = 0
   for i, str in ipairs(text_list) do
      if str == "value" then
         index = i
         break
      end
   end
   local obj = {
      name = name,
      text_list = text_list,
      index = index,
      object = object,
      property = property,
      small = small or false,
      inline = inline or false,
      is_unselectable = function() return true end,
      width = 0,
      height = 0
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Label_Menu_Item:draw(x, y)
   local color = colors.text.inactive
   local size
   if self.index > 0 then self.text_list[self.index] = self.object[self.property] end
   if self.small and settings.language == "jp" then size = 8 end
   draw.render_text_multiple_to_canvas(draw.menu_canvas, x, y, self.text_list, nil, size, color)
end

function Label_Menu_Item:calc_dimensions()
   local size
   if self.small and settings.language == "jp" then size = 8 end
   if self.index > 0 then self.text_list[self.index] = self.object[self.property] end
   self.width, self.height = draw.get_text_dimensions_multiple(self.text_list, nil, size)
end

local Multitab_Menu = {}
Multitab_Menu.__index = Multitab_Menu

function Multitab_Menu:new(left, top, right, bottom, content, on_toggle_entry)
   local obj = {
      menu_stack = {},
      left = left,
      top = top,
      right = right,
      bottom = bottom,
      content = content,
      x_padding = 15,
      y_padding = 5,
      menu_item_spacing = 1,
      content_area_height = 120,
      is_main_menu_selected = true,
      main_menu_selected_index = 1,
      sub_menu_selected_index = 1,
      max_entries = 16,
      on_toggle_entry = on_toggle_entry,
      has_popup = false,
      should_cache = true,
      on_open = Multitab_Menu.reset_background_cache,
      background_cache_index = 1,
      background_cache = {},
      previous_frame_number = 0,
      discard_first_frames = 1
   }
   if settings.language == "jp" then obj.max_entries = 11 end

   for i = 1, #obj.content do
      obj.content[i].top_entry_index = 1
      obj.content[i].bottom_entry_index = obj.max_entries
   end

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Multitab_Menu:reset_background_cache()
   self.should_cache = true
   self.background_cache = {}
   self.background_cache_index = 1
   self.discard_first_frames = 1
end

local min_loop, max_loop, max_cache = 8, 10, 16
function Multitab_Menu:cache_background()
   gui.box(self.left, self.top, self.right, self.bottom, colors.menu.background, colors.menu.outline)
   local menu_y = self.top + self.y_padding * 2 + self.content[1].header.height
   if settings.language == "en" then menu_y = menu_y - 1 end
   for i = 15, 35 do gui.drawline(self.left + i, menu_y - 1, self.right - i, menu_y - 1, colors.menu.divider) end

   local menu_width = self.right - self.left + 1
   local menu_height = self.bottom - self.top + 1
   local w1, w2 = bit.band(bit.rshift(menu_width, 8), 0xff), bit.band(menu_width, 0xff)
   local h1, h2 = bit.band(bit.rshift(menu_height, 8), 0xff), bit.band(menu_height, 0xff)
   local result = {string.char(0xff, 0xfe, w1, w2, h1, h2, 0x01, 0xff, 0xff, 0xff, 0xff)}
   local screen = gui.gdscreenshot()
   local screen_width = 1 + string.byte(screen, 3) * 255 + string.byte(screen, 4)
   local row_size = menu_width * draw.GD_BYTES_PER_PIXEL
   for source_row = self.top, self.bottom do
      local source_offset = draw.GD_HEADER_SIZE + 1 + (source_row * screen_width + self.left) * draw.GD_BYTES_PER_PIXEL
      local source_end = source_offset + row_size - 1
      result[#result + 1] = string.sub(screen, source_offset, source_end)
   end
   self.background_cache[#self.background_cache + 1] = table.concat(result)
   if self.discard_first_frames > 0 and #self.background_cache > 1 then
      table.remove(self.background_cache, 1)
      self.discard_first_frames = self.discard_first_frames - 1
   end
   if #self.background_cache > min_loop then
      local loop_start = 0
      for i = math.min(#self.background_cache, #self.background_cache - max_loop + 1), #self.background_cache - min_loop do
         if self.background_cache[i] == self.background_cache[#self.background_cache] then loop_start = i end
      end
      if loop_start > 0 then
         for i = 1, loop_start do table.remove(self.background_cache, 1) end
         self.should_cache = false
      elseif #self.background_cache >= max_cache then
         table.remove(self.background_cache, 1)
      end
   end
end

function Multitab_Menu:update_page_position()
   local entries = self:current_tab().entries
   local total_height = 0
   local i = self:current_tab().top_entry_index
   while i <= #entries do
      if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
          (entries[i].is_visible and not entries[i]:is_visible())) then
         if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
            total_height = total_height + entries[i].height + self.menu_item_spacing
         else
            break
         end
      end
      i = i + 1
   end
   self:current_tab().bottom_entry_index = i - 1
end

function Multitab_Menu:calc_dimensions()
   for _, item in ipairs(self.content[self.main_menu_selected_index].entries) do
      if item.calc_dimensions then item:calc_dimensions() end
   end
end

function Multitab_Menu:calc_dimensions_of_page(tab_index, page_index)
   if not self.content[tab_index].pages or not self.content[tab_index].pages[page_index] then return end
   for _, item in ipairs(self.content[tab_index].pages[page_index].entries) do
      if item.calc_dimensions then item:calc_dimensions() end
   end
end

function Multitab_Menu:current_tab() return self.content[self.main_menu_selected_index] end

function Multitab_Menu:current_entry()
   return self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]
end

function Multitab_Menu:select_item(item)
   for i, entry in ipairs(self.content[self.main_menu_selected_index].entries) do
      if entry == item then self.sub_menu_selected_index = i end
   end
end

function Multitab_Menu:menu_stack_push(menu)
   self.menu_stack[#self.menu_stack + 1] = menu
   if menu.on_open then menu:on_open() end
end

function Multitab_Menu:menu_stack_pop(menu)
   for i, m in ipairs(self.menu_stack) do
      if m == menu then
         table.remove(self.menu_stack, i)
         if m.on_close then m:on_close() end
         break
      end
   end
end

function Multitab_Menu:menu_open_popup(menu, hide_menu)
   if hide_menu then self.menu_stack = {} end
   self.menu_stack[#self.menu_stack + 1] = menu
   self.has_popup = true
end

function Multitab_Menu:menu_close_popup(menu)
   menu = menu or self.menu_stack[#self.menu_stack]
   self:menu_stack_pop(menu)
   if #self.menu_stack == 0 then
      self.menu_stack[#self.menu_stack + 1] = self
      if self.on_open then self:on_open() end
   end
   if self.menu_stack[#self.menu_stack] == self then self.has_popup = false end
end

function Multitab_Menu:menu_stack_top() return self.menu_stack[#self.menu_stack] end

function Multitab_Menu:menu_stack_clear()
   for _, menu in ipairs(self.menu_stack) do if menu.on_close then menu:on_close() end end
   self.menu_stack = {}
   self.has_popup = false
end

function Multitab_Menu:menu_stack_update(input)
   if #self.menu_stack == 0 then return end
   local last_menu = self.menu_stack[#self.menu_stack]
   last_menu:update(input)
end

function Multitab_Menu:menu_stack_draw() for i, menu in ipairs(self.menu_stack) do menu:draw() end end

function Multitab_Menu:update_dimensions_of_all_items()
   for _, menu in ipairs(self.menu_stack) do
      if menu == self then
         for i = 1, #self.content do
            self.content[i].header:calc_dimensions()
            if self.content[i].pages then
               for _, page in ipairs(self.content[i].pages) do
                  for _, item in ipairs(page.entries) do
                     if item.calc_dimensions then item:calc_dimensions() end
                  end
               end
            else
               for _, item in ipairs(self.content[i].entries) do
                  if item.calc_dimensions then item:calc_dimensions() end
               end
            end
         end
      else
         menu:calc_dimensions()
      end
   end
   self:reset_background_cache()
end

function Multitab_Menu:update(input)

   self.max_entries = 16
   if settings.language == "jp" then self.max_entries = 11 end

   local function first_visible_entry()
      local entries = self:current_tab().entries
      for i = 1, #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then return i end
      end
      return 1
   end

   local function last_visible_entry()
      local entries = self:current_tab().entries
      for i = #entries, 1, -1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then return i end
      end
      return #entries
   end

   local function next_selectable_entry(index)
      local entries = self:current_tab().entries
      local i = index or self.sub_menu_selected_index
      i = i + 1
      while i <= #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then break end
         i = i + 1
      end
      return math.min(i, #entries)
   end

   local function previous_selectable_entry(index)
      local entries = self:current_tab().entries
      local i = index or self.sub_menu_selected_index
      i = i - 1
      while i >= 1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then break end
         i = i - 1
      end
      return math.max(i, 1)
   end

   local function get_bottom_page_position()
      local entries = self:current_tab().entries
      local total_height = 0
      local i = #entries
      while i >= 1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then
            if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
               total_height = total_height + entries[i].height + self.menu_item_spacing
            else
               break
            end
         end
         i = i - 1
      end
      return i + 1
   end

   local function get_bottom_entry_index()
      local entries = self:current_tab().entries
      local total_height = 0
      local i = self:current_tab().top_entry_index
      while i <= #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then
            if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
               total_height = total_height + entries[i].height + self.menu_item_spacing
            else
               break
            end
         end
         i = i + 1
      end
      return i - 1
   end

   local function get_next_page_top_entry_index()
      local entries = self:current_tab().entries
      local i = self.sub_menu_selected_index
      while i <= #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then break end
         i = i + 1
      end
      return math.min(i, get_bottom_page_position())
   end

   local function get_previous_page_top_entry_index()
      local entries = self:current_tab().entries
      local total_height = 0
      local i = self.sub_menu_selected_index
      while i >= 1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then
            if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
               total_height = total_height + entries[i].height + self.menu_item_spacing
            else
               break
            end
         end
         i = i - 1
      end
      return math.max(i + 1, 1)
   end

   while (self:current_entry().is_unselectable and self:current_entry():is_unselectable()) or
       (self:current_entry().is_visible and not self:current_entry():is_visible()) do
      local previous_selected_index = self.sub_menu_selected_index
      self.sub_menu_selected_index = previous_selectable_entry()
      if self.sub_menu_selected_index == previous_selected_index then
         self.is_main_menu_selected = true
         self.sub_menu_selected_index = 1
         break
      end

      if self.sub_menu_selected_index < self:current_tab().top_entry_index and not self.is_main_menu_selected then
         self:current_tab().top_entry_index = math.max(self.sub_menu_selected_index, 1)
      end
   end

   if self.sub_menu_selected_index > self:current_tab().bottom_entry_index then
      local next_page_start = get_next_page_top_entry_index()
      if next_page_start > 0 then self:current_tab().top_entry_index = next_page_start end
   end

   if input.down then
      local should_process_input = true
      if not self.is_main_menu_selected and self:current_entry().down then
         should_process_input = self:current_entry():down()
      end
      if should_process_input then
         self:current_tab().bottom_entry_index = get_bottom_entry_index()
         repeat
            if self.is_main_menu_selected then
               self.is_main_menu_selected = false
               self.sub_menu_selected_index = self:current_tab().top_entry_index

            else
               if self.sub_menu_selected_index == #self:current_tab().entries then
                  self.is_main_menu_selected = true
                  self.sub_menu_selected_index = 1
               else
                  self.sub_menu_selected_index = next_selectable_entry()
               end
            end
            if not self.is_main_menu_selected and self.sub_menu_selected_index > self:current_tab().bottom_entry_index then
               self:current_tab().top_entry_index = get_next_page_top_entry_index()
               self:current_tab().bottom_entry_index = get_bottom_entry_index()
            end
         until (self.is_main_menu_selected or
             not (self:current_entry().is_unselectable and self:current_entry():is_unselectable()) and
             (self:current_entry().is_visible == nil or self:current_entry():is_visible()))
      end
   end

   if input.up then
      local should_process_input = true
      if not self.is_main_menu_selected and self:current_entry().up then
         should_process_input = self:current_entry():up()
      end
      if should_process_input then
         repeat
            if self.is_main_menu_selected then
               self.is_main_menu_selected = false
               self.sub_menu_selected_index = #self:current_tab().entries
               self:current_tab().top_entry_index = get_bottom_page_position()
               self:current_tab().bottom_entry_index = get_bottom_entry_index()
            else
               if self.sub_menu_selected_index == 1 then
                  self.is_main_menu_selected = true
                  self.sub_menu_selected_index = 1
               else
                  self.sub_menu_selected_index = previous_selectable_entry()
               end
            end
            if not self.is_main_menu_selected and self.sub_menu_selected_index < self:current_tab().top_entry_index then
               self:current_tab().top_entry_index = get_previous_page_top_entry_index()
               self:current_tab().bottom_entry_index = get_bottom_entry_index()
            end
         until (self.is_main_menu_selected or
             not (self:current_entry().is_unselectable and self:current_entry():is_unselectable()) and
             (self:current_entry().is_visible == nil or self:current_entry():is_visible()))
      end
   end

   if input.left then
      if self.is_main_menu_selected then
         self.main_menu_selected_index = self.main_menu_selected_index - 1
         self.sub_menu_selected_index = 1
         if self.main_menu_selected_index == 0 then self.main_menu_selected_index = #self.content end
      elseif self:current_entry() ~= nil then
         if self:current_entry().left ~= nil then
            self:current_entry():left()
            if self.on_toggle_entry ~= nil and
                not (self:current_entry().__name and self:current_entry().__name == "Check_Box_Grid_Item") then
               self:on_toggle_entry()
            end
         end
      end
   end

   if input.right then
      if self.is_main_menu_selected then
         self.main_menu_selected_index = self.main_menu_selected_index + 1
         self.sub_menu_selected_index = 1
         if self.main_menu_selected_index > #self.content then self.main_menu_selected_index = 1 end
      elseif self:current_entry() ~= nil then
         if self:current_entry().right ~= nil then
            self:current_entry():right()
            if self.on_toggle_entry ~= nil and
                not (self:current_entry().__name and self:current_entry().__name == "Check_Box_Grid_Item") then
               self:on_toggle_entry()
            end
         end
      end
   end

   if input.validate.down or input.validate.press or input.validate.release then
      if self.is_main_menu_selected then
      elseif self:current_entry() ~= nil then
         if self:current_entry().validate then
            self:current_entry():validate(input.validate)
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.reset.down or input.reset.press or input.reset.release then
      if self.is_main_menu_selected then
      elseif self:current_entry() ~= nil then
         if self:current_entry().reset then
            self:current_entry():reset(input.reset)
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.cancel then
      if self.is_main_menu_selected then
      elseif self:current_entry() ~= nil then
         if self:current_entry().cancel then
            self:current_entry():cancel()
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.scroll_up.press then
      if not self.is_main_menu_selected then
         if self.sub_menu_selected_index == first_visible_entry() then
            self.is_main_menu_selected = true
            self.sub_menu_selected_index = 1
         end
      end
      self.sub_menu_selected_index = previous_selectable_entry(self:current_tab().top_entry_index)
      self:current_tab().top_entry_index = get_previous_page_top_entry_index()
      self:current_tab().bottom_entry_index = get_bottom_entry_index()
   end

   if input.scroll_down.press then
      if not self.is_main_menu_selected then
         if self.sub_menu_selected_index == last_visible_entry() then
            self.is_main_menu_selected = true
            self.sub_menu_selected_index = 1
         end
      end
      self.sub_menu_selected_index = next_selectable_entry(self:current_tab().bottom_entry_index)
      self:current_tab().top_entry_index = get_next_page_top_entry_index()
      self:current_tab().bottom_entry_index = get_bottom_entry_index()
   end
end

function Multitab_Menu:draw()
   if self.should_cache then
      self:cache_background()
      self.background_cache_index = #self.background_cache
   elseif gamestate.frame_number > self.previous_frame_number then
      self.background_cache_index = tools.wrap_index(self.background_cache_index + 1, #self.background_cache)
   end
   self.previous_frame_number = gamestate.frame_number
   gui.image(self.left, self.top, self.background_cache[self.background_cache_index])

   local total_item_width = 0
   for i = 1, #self.content do total_item_width = total_item_width + self.content[i].header.width end

   local offset = 0
   local menu_width = self.right - self.left + 1
   local gap = math.floor((menu_width - total_item_width) / (#self.content + 1))
   local menu_x = self.left + self.x_padding
   local menu_y = 0

   local w, h = draw.get_text_dimensions("legend_hp_scroll")
   local legend_y_padding = 3
   local legend_y = self.bottom - (h + legend_y_padding)
   if settings.language == "en" then legend_y = legend_y + 1 end

   for i = 1, #self.content do
      local state = "inactive"
      if i == self.main_menu_selected_index then
         state = "active"
         if self.is_main_menu_selected then state = "selected" end
      end
      self.content[i].header:draw(self.left + gap + offset, self.top + self.y_padding, state)
      offset = offset + self.content[i].header.width + gap
   end
   menu_y = self.top + self.y_padding * 2 + self.content[1].header.height

   menu_y = menu_y + 4

   self.content_area_height = legend_y - menu_y

   local scroll_down = false

   local y_offset = 0
   local is_focused = self == self:menu_stack_top()
   for i = 1, #self.content[self.main_menu_selected_index].entries do
      if i >= self.content[self.main_menu_selected_index].top_entry_index and
          (self.content[self.main_menu_selected_index].entries[i].is_visible == nil or
              self.content[self.main_menu_selected_index].entries[i]:is_visible()) then
         if self.content[self.main_menu_selected_index].entries[i].inline and (i - 1) >= 1 then
            local x_offset = self.content[self.main_menu_selected_index].entries[i - 1].width + 8
            if settings.language == "jp" then x_offset = x_offset + 2 end
            local y_adj = -1 *
                              (self.content[self.main_menu_selected_index].entries[i - 1].height +
                                  self.menu_item_spacing)
            self.content[self.main_menu_selected_index].entries[i]:draw(menu_x + x_offset, menu_y + y_offset + y_adj,
                                                                        not self.is_main_menu_selected and is_focused and
                                                                            self.sub_menu_selected_index == i)
         else
            if menu_y + y_offset + self.content[self.main_menu_selected_index].entries[i].height <= legend_y then
               self.content[self.main_menu_selected_index].entries[i]:draw(menu_x, menu_y + y_offset,
                                                                           not self.is_main_menu_selected and is_focused and
                                                                               self.sub_menu_selected_index == i)
               y_offset = y_offset + self.content[self.main_menu_selected_index].entries[i].height +
                              self.menu_item_spacing
            else
               scroll_down = true
               break
            end
         end
      end
   end

   if not self.is_main_menu_selected then
      if self:current_entry().legend then
         draw.render_text_to_canvas(draw.menu_canvas, menu_x, legend_y, self:current_entry():legend(), nil, nil,
                                    colors.text.inactive)
      end
   end

   local scroll_up = self.content[self.main_menu_selected_index].top_entry_index > 1
   if scroll_down or scroll_up then
      draw.render_text_to_canvas(draw.menu_canvas, self.right - w - self.x_padding, legend_y, "legend_hp_scroll", nil,
                                 nil, colors.text.inactive)

      local scroll_up_y_pos = math.floor(menu_y + h / 2 - 3)
      local scroll_down_y_pos = math.floor(menu_y + (y_offset - self.menu_item_spacing - h) + h / 2 - 2)
      if settings.language == "jp" then
         scroll_up_y_pos = math.floor(menu_y + h / 2 - 2)
         scroll_down_y_pos = math.floor(menu_y + (y_offset - self.menu_item_spacing - h) + h / 2)
      end

      local scroll_up_color, scroll_down_color = colors.text.default, colors.text.default
      if self.sub_menu_selected_index == self:current_tab().top_entry_index then
         scroll_up_color = colors.text.selected
      elseif self.sub_menu_selected_index == self:current_tab().bottom_entry_index then
         scroll_down_color = colors.text.selected
      end
      if scroll_up then
         draw.add_image_to_canvas(draw.menu_canvas, math.floor(self.left + self.x_padding / 2 - 2), scroll_up_y_pos,
                                  image_tables.scroll_arrow_width, image_tables.scroll_arrow_height,
                                  draw.get_image(image_tables.images.img_scroll_up, scroll_up_color))
      end
      if scroll_down then
         draw.add_image_to_canvas(draw.menu_canvas, math.floor(self.left + self.x_padding / 2 - 2), scroll_down_y_pos,
                                  image_tables.scroll_arrow_width, image_tables.scroll_arrow_height,
                                  draw.get_image(image_tables.images.img_scroll_down, scroll_down_color))
      end
   end
end

local Menu = {}
Menu.__index = Menu

function Menu:new(left, top, right, bottom, content, on_toggle_entry, draw_legend, status_item, resize)
   local obj = {
      left = left,
      top = top,
      right = right,
      bottom = bottom,
      content = content,
      selected_index = 1,
      on_toggle_entry = on_toggle_entry,
      draw_legend = draw_legend or true,
      status_item = status_item,
      resize = resize or false,
      menu_item_spacing = 1,
      x_padding = 8,
      y_padding = 5,
      legend_y_padding = 3,
      content_area_height = 0,
      top_entry_index = 1,
      bottom_entry_index = 1,
      background_color = colors.menu.background
   }

   setmetatable(obj, self)
   obj:calc_dimensions()
   return obj
end

function Menu:current_entry() return self.content[self.selected_index] end

function Menu:calc_dimensions()
   for i = 1, #self.content do self.content[i]:calc_dimensions() end
   if self.status_item then self.status_item:calc_dimensions() end
   if self.resize then
      local legend_w, legend_h = draw.get_text_dimensions("legend_hp_scroll")
      local max_width, total_height, current_width = 0, 0, 0
      local i = 1
      while i <= #self.content do
         if (self.content[i].is_visible == nil or self.content[i]:is_visible()) then
            current_width = current_width + self.content[i].width
            if self.content[i].indent then current_width = current_width + indent_width end
            if not (self.content[i + 1] and self.content[i + 1].inline) then
               if current_width > max_width then max_width = current_width end
               current_width = 0
            else
               current_width = current_width + indent_width
            end
            if not self.content[i].inline then
               total_height = total_height + self.content[i].height + self.menu_item_spacing
            end
         end
         i = i + 1
      end
      max_width = max_width + 2 * self.x_padding
      self.content_area_height = total_height + legend_h + self.legend_y_padding
      total_height = self.content_area_height + 2 * self.y_padding
      self.right = self.left + max_width
      self.bottom = self.top + total_height
   else
      self.content_area_height = self.bottom - self.top - 2 * self.y_padding
   end
end

function Menu:update(input)
   self.max_entries = 100

   local function first_visible_entry()
      local entries = self.content
      for i = 1, #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then return i end
      end
      return 1
   end

   local function last_visible_entry()
      local entries = self.content
      for i = #entries, 1, -1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then return i end
      end
      return #entries
   end

   local function next_selectable_entry(index)
      local entries = self.content
      local i = index or self.selected_index
      i = i + 1
      while i <= #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then break end
         i = i + 1
      end
      return math.min(i, #entries)
   end

   local function previous_selectable_entry(index)
      local entries = self.content
      local i = index or self.selected_index
      i = i - 1
      while i >= 1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then break end
         i = i - 1
      end
      return math.max(i, 1)
   end

   local function get_bottom_page_position()
      local entries = self.content
      local total_height = 0
      local i = #entries
      while i >= 1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then
            if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
               total_height = total_height + entries[i].height + self.menu_item_spacing
            else
               break
            end
         end
         i = i - 1
      end
      return i + 1
   end

   local function get_bottom_entry_index()
      local entries = self.content
      local total_height = 0
      local i = self.top_entry_index
      while i <= #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then
            if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
               total_height = total_height + entries[i].height + self.menu_item_spacing
            else
               break
            end
         end
         i = i + 1
      end
      return i - 1
   end

   local function get_next_page_top_entry_index()
      local entries = self.content
      local i = self.selected_index
      while i <= #entries do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then break end
         i = i + 1
      end
      return math.min(i, get_bottom_page_position())
   end

   local function get_previous_page_top_entry_index()
      local entries = self.content
      local total_height = 0
      local i = self.selected_index
      while i >= 1 do
         if not ((entries[i].is_unselectable and entries[i]:is_unselectable()) or entries[i].inline or
             (entries[i].is_visible and not entries[i]:is_visible())) then
            if total_height + entries[i].height + self.menu_item_spacing <= self.content_area_height then
               total_height = total_height + entries[i].height + self.menu_item_spacing
            else
               break
            end
         end
         i = i - 1
      end
      return math.max(i + 1, 1)
   end

   while (self:current_entry().is_unselectable and self:current_entry():is_unselectable()) or
       (self:current_entry().is_visible and not self:current_entry():is_visible()) do
      self.selected_index = previous_selectable_entry()
      if self.selected_index == 0 then self.selected_index = 1 end

      if self.selected_index < self.top_entry_index then self.top_entry_index = math.max(self.selected_index, 1) end
   end

   if self.selected_index > self.bottom_entry_index then
      local next_page_start = get_next_page_top_entry_index()
      if next_page_start > 0 then self.top_entry_index = next_page_start end
   end

   if input.down then
      local should_process_input = true
      if not self.is_main_menu_selected and self:current_entry().down then
         should_process_input = self:current_entry():down()
      end
      if should_process_input then
         self.bottom_entry_index = get_bottom_entry_index()
         repeat
            if self.selected_index == #self.content then
               self.selected_index = 1
            else
               self.selected_index = next_selectable_entry()
            end
            if self.selected_index > self.bottom_entry_index then
               self.top_entry_index = get_next_page_top_entry_index()
               self.bottom_entry_index = get_bottom_entry_index()
            end
         until (not (self:current_entry().is_unselectable and self:current_entry():is_unselectable()) and
             (self:current_entry().is_visible == nil or self:current_entry():is_visible()))
      end
   end

   if input.up then
      local should_process_input = true
      if self:current_entry().up then should_process_input = self:current_entry():up() end
      if should_process_input then
         repeat
            if self.selected_index == 1 then
               self.selected_index = #self.content
            else
               self.selected_index = previous_selectable_entry()
            end
            if self.selected_index < self.top_entry_index then
               self.top_entry_index = get_previous_page_top_entry_index()
               self.bottom_entry_index = get_bottom_entry_index()
            end
         until (not (self:current_entry().is_unselectable and self:current_entry():is_unselectable()) and
             (self:current_entry().is_visible == nil or self:current_entry():is_visible()))
      end
   end

   if input.left then
      if self:current_entry() ~= nil then
         if self:current_entry().left ~= nil then
            self:current_entry():left()
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.right then
      if self:current_entry() ~= nil then
         if self:current_entry().right ~= nil then
            self:current_entry():right()
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.validate.down or input.validate.press or input.validate.release then
      if self:current_entry() ~= nil then
         if self:current_entry().validate then
            self:current_entry():validate(input.validate)
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.reset.down or input.reset.press or input.reset.release then
      if self:current_entry() ~= nil then
         if self:current_entry().reset then
            self:current_entry():reset(input.reset)
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.cancel then
      if self:current_entry() ~= nil then
         if self:current_entry().cancel then
            self:current_entry():cancel()
            if self.on_toggle_entry ~= nil then self:on_toggle_entry() end
         end
      end
   end

   if input.scroll_up.press then
      if self.scroll_up_function then
         self:scroll_up_function()
      else
         self.selected_index = previous_selectable_entry(self.top_entry_index)
         self.top_entry_index = get_previous_page_top_entry_index()
         self.bottom_entry_index = get_bottom_entry_index()
      end
   end

   if input.scroll_down.press then
      if self.scroll_down_function then
         self:scroll_down_function()
      else
         self.selected_index = next_selectable_entry(self.bottom_entry_index)
         self.top_entry_index = get_next_page_top_entry_index()
         self.bottom_entry_index = get_bottom_entry_index()
      end
   end
end

function Menu:draw()
   local legend_w, legend_h = draw.get_text_dimensions("legend_hp_scroll")

   self:calc_dimensions()

   gui.box(self.left, self.top, self.right, self.bottom, self.background_color, colors.menu.outline)

   local menu_x = self.left + self.x_padding
   local menu_y = self.top + self.y_padding

   local legend_y = self.bottom - legend_h - self.y_padding - 1
   if settings.language == "en" then legend_y = legend_y + 1 end

   local menu_item_spacing = 1

   local y_offset = 0
   for i = 1, #self.content do
      if (self.content[i].is_visible == nil or self.content[i]:is_visible()) then
         if self.content[i].inline and (i - 1) >= 1 then
            local x_offset = self.content[i - 1].width + indent_width
            if settings.language == "jp" then x_offset = x_offset + 2 end
            local y_adj = -1 * (self.content[i - 1].height + menu_item_spacing)
            self.content[i]:draw(menu_x + x_offset, menu_y + y_offset + y_adj, self.selected_index == i)
         else
            if not (menu_y + y_offset + 5 >= legend_y) then
               self.content[i]:draw(menu_x, menu_y + y_offset, self.selected_index == i)
               y_offset = y_offset + self.content[i].height + menu_item_spacing
            end
         end
      end
   end

   if self.draw_legend and self.content[self.selected_index].legend then
      draw.render_text_to_canvas(draw.menu_canvas, menu_x, legend_y + self.legend_y_padding,
                                 self.content[self.selected_index]:legend(), nil, nil, colors.text.inactive)
   end
   if self.status_item then
      self.status_item:calc_dimensions()
      self.status_item:draw(self.right - self.x_padding - self.status_item.width, legend_y + self.legend_y_padding)
   end
end

return {
   Gauge_Menu_Item = Gauge_Menu_Item,
   Textfield_Menu_Item = Textfield_Menu_Item,
   On_Off_Menu_Item = On_Off_Menu_Item,
   List_Menu_Item = List_Menu_Item,
   Check_Box_Grid_Item = Check_Box_Grid_Item,
   Slider_Menu_Item = Slider_Menu_Item,
   Motion_List_Menu_Item = Motion_List_Menu_Item,
   Move_Input_Display_Menu_Item = Move_Input_Display_Menu_Item,
   Controller_Style_Item = Controller_Style_Item,
   Integer_Menu_Item = Integer_Menu_Item,
   Hits_Before_Menu_Item = Hits_Before_Menu_Item,
   Map_Menu_Item = Map_Menu_Item,
   Button_Menu_Item = Button_Menu_Item,
   Header_Menu_Item = Header_Menu_Item,
   Footer_Menu_Item = Footer_Menu_Item,
   Label_Menu_Item = Label_Menu_Item,
   Multitab_Menu = Multitab_Menu,
   Menu = Menu
}
