local settings = require("src.settings")
local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local text = require("src.ui.text")
local draw = require("src.ui.draw")
local images = require("src.ui.image_tables")
local move_data = require("src.modules.move_data")

local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text, text.render_text_multiple, text.get_text_dimensions, text.get_text_dimensions_multiple


local localization = read_object_from_json_file("data/localization.json")

local gauge_background_color = colors.menu.gauge_background
local gauge_border_color = colors.menu.gauge_border

local button_activated_color = text.button_activated_color

local menu_background_color = colors.menu.background
local menu_outline_color = colors.menu.outline

local lang_code = {"en", "jp"}


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
  local color = text.default_color
  if selected then
    color = text.selected_color
  end

  local offset = 0
  if self.indent then
    offset = 8
  end

  render_text_multiple(x + offset, y, {self.name, ":  "}, nil, nil, color)
  local w, h = get_text_dimensions_multiple({self.name, ":  "})

  offset = offset + w
  
  local box_width = self.gauge_max / self.unit
  local box_top = y + (h - 4) / 2
  if lang_code[settings.training.language] == "jp" then
    box_top = box_top + 1
  end
  local box_left = x + offset
  local box_right = box_left + box_width
  local box_bottom = box_top + 4
  gui.box(box_left, box_top, box_right, box_bottom, gauge_background_color, gauge_border_color)
  local content_width = self.object[self.property_name] / self.unit
  gui.box(box_left, box_top, box_left + content_width, box_bottom, self.fill_color, 0x00000000)
  for i = 1, self.subdivision_count - 1 do
    local line_x = box_left + i * self.gauge_max / (self.subdivision_count * self.unit)
    gui.line(line_x, box_top, line_x, box_bottom, gauge_border_color)
  end

end

function Gauge_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
  self.width = self.width + self.gauge_max / self.unit
end

function Gauge_Menu_Item:left()
  self.object[self.property_name] = math.max(self.object[self.property_name] - self.unit, 0)
end

function Gauge_Menu_Item:right()
  self.object[self.property_name] = math.min(self.object[self.property_name] + self.unit, self.gauge_max)
end

function Gauge_Menu_Item:reset()
  self.object[self.property_name] = 0
end

function Gauge_Menu_Item:legend()
  return "legend_mp_reset"
end



local available_characters = {
  " ",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "X",
  "Y",
  "Z",
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "-",
  "_",
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
  for i = 1, #self.content do
    str = str..available_characters[self.content[i]]
  end
  self.object[self.property_name] = str
end

function Textfield_Menu_Item:sync_from_var()
  self.content = {}
  for i = 1, #self.object[self.property_name] do
    local c = self.object[self.property_name]:sub(i,i)
    for j = 1, #available_characters do
      if available_characters[j] == c then
        table.insert(self.content, j)
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
    for i = last_empty_index, #self.content do
      table.remove(self.content, last_empty_index)
    end
  end
end

function Textfield_Menu_Item:draw(x, y, selected)
  local color = text.default_color
  local prefix = ""
  local suffix = ""
  if self.is_in_edition then
    color =  button_activated_color
  elseif selected then
    color = text.selected_color
  end

  local value = self.object[self.property_name]

  if self.is_in_edition then
    local frequency = 0.05
    color = colors.colorscale(color, (math.sin(gamestate.frame_number * frequency) + 1) / 2 * .5 + 0.5)
    self:calc_dimensions()
    local u_w = get_text_dimensions("_")
    render_text(x + self.width - u_w, y + 2, "_", nil, nil, color)
  end

  render_text_multiple(x, y, {self.name, ":  ", value}, nil, nil, color)

end

function Textfield_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
end

function Textfield_Menu_Item:left()
  if self.is_in_edition then
    self:reset()
  end
end

function Textfield_Menu_Item:right()
  if self.is_in_edition then
    self:validate()
  end
end

function Textfield_Menu_Item:up()
  if self.is_in_edition then
    self.content[self.edition_index] = self.content[self.edition_index] + 1
    if self.content[self.edition_index] > #available_characters then
      self.content[self.edition_index] = 1
    end
    self:sync_to_var()
    return true
  else
    return false
  end
end

function Textfield_Menu_Item:down()
  if self.is_in_edition then
    self.content[self.edition_index] = self.content[self.edition_index] - 1
    if self.content[self.edition_index] == 0 then
      self.content[self.edition_index] = #available_characters
    end
    self:sync_to_var()
    return true
  else
    return false
  end
end

function Textfield_Menu_Item:validate()
  if not self.is_in_edition then
    self:sync_from_var()
    if #self.content < self.max_length then
      table.insert(self.content, 1)
    end
    self.edition_index = #self.content
    self.is_in_edition = true
  else
    if self.content[self.edition_index] ~= 1 then
      if #self.content < self.max_length then
        table.insert(self.content, 1)
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

function On_Off_Menu_Item:new(name, object, property_name, default_value)
  local obj = {
    name = name,
    object = object,
    property_name = property_name,
    default_value = default_value or false,
    indent = false,
    width = 0,
    height = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function On_Off_Menu_Item:draw(x, y, selected)
  local color = text.default_color
  if selected then
    color = text.selected_color
  end

  local value = ""
  if self.object[self.property_name] then
    value = "menu_on"
  else
    value = "menu_off"
  end
  local offset = 0
  if self.indent then
    offset = 8
  end

  render_text_multiple(x + offset, y, {self.name, ":  ", value}, nil, nil, color)
end

function On_Off_Menu_Item:calc_dimensions()
  local value = ""
  if self.object[self.property_name] then
    value = "menu_on"
  else
    value = "menu_off"
  end
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", value})
end

function On_Off_Menu_Item:left()
  self.object[self.property_name] = not self.object[self.property_name]
end

function On_Off_Menu_Item:right()
  self.object[self.property_name] = not self.object[self.property_name]
end

function On_Off_Menu_Item:reset()
  self.object[self.property_name] = self.default_value
end

function On_Off_Menu_Item:legend()
  return "legend_mp_reset"
end


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
    height = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function List_Menu_Item:draw(x, y, selected)
  local color = text.default_color
  if selected then
    color = text.selected_color
  end
  local offset = 0
  if self.indent then
    offset = 8
  end

  render_text_multiple(x + offset, y, {self.name, ":  ", self.list[self.object[self.property_name]]}, nil, nil, color)
end


function List_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.list[self.object[self.property_name]]})
end

function List_Menu_Item:left()

  self.object[self.property_name] = self.object[self.property_name] - 1
  if self.object[self.property_name] == 0 then
    self.object[self.property_name] = #self.list
  end
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function List_Menu_Item:right()

  self.object[self.property_name] = self.object[self.property_name] + 1
  if self.object[self.property_name] > #self.list then
    self.object[self.property_name] = 1
  end
  -- print(gamestate.frame_number,debug.getinfo(1, "nSl"))
  -- print(gamestate.frame_number, self.indent, self.object.ca_type, settings.training.counter_attack[gamestate.P2.char_str].ca_type)

  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function List_Menu_Item:reset()
  self.object[self.property_name] = self.default_value
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function List_Menu_Item:legend()
  return "legend_mp_reset"
end

local Motion_list_Menu_Item = {}
Motion_list_Menu_Item.__index = Motion_list_Menu_Item

function Motion_list_Menu_Item:new(name, object, property_name, list, default_value, on_change)
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

function Motion_list_Menu_Item:draw(x, y, selected)
  local color = text.default_color
  if selected then
    color = text.selected_color
  end
  local offset_x = 0
  local offset_y = -1
  if self.indent then
    offset_x = 8
  end

  render_text_multiple(x + offset_x, y, {self.name, ":  "}, nil, nil, color)
  local w, _ = get_text_dimensions_multiple({self.name, ":  "})
  offset_x = offset_x + w

  if lang_code[settings.training.language] == "jp" then
    offset_y = 2
  end

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
        table.insert(img_list, images.img_button_small[style][1])
      elseif self.list[id][i][j] == "MP" then
        added = added + 1
        table.insert(img_list, images.img_button_small[style][2])
      elseif self.list[id][i][j] == "HP" then
        added = added + 1
        table.insert(img_list, images.img_button_small[style][3])
      elseif self.list[id][i][j] == "LK" then
        added = added + 1
        table.insert(img_list, images.img_button_small[style][4])
      elseif self.list[id][i][j] == "MK" then
        added = added + 1
        table.insert(img_list, images.img_button_small[style][5])
      elseif self.list[id][i][j] == "HK" then
        added = added + 1
        table.insert(img_list, images.img_button_small[style][6])
      elseif self.list[id][i][j] == "EXP" then
        added = added + 2
        table.insert(img_list, images.img_button_small[style][1])
        table.insert(img_list, images.img_button_small[style][2])
      elseif self.list[id][i][j] == "EXK" then
        added = added + 2
        table.insert(img_list, images.img_button_small[style][4])
        table.insert(img_list, images.img_button_small[style][5])
      elseif self.list[id][i][j] == "PPP" then
        added = added + 3
        table.insert(img_list, images.img_button_small[style][1])
        table.insert(img_list, images.img_button_small[style][2])
        table.insert(img_list, images.img_button_small[style][3])
      elseif self.list[id][i][j] == "KKK" then
        added = added + 3
        table.insert(img_list, images.img_button_small[style][4])
        table.insert(img_list, images.img_button_small[style][5])
        table.insert(img_list, images.img_button_small[style][6])
      elseif self.list[id][i][j] == "h_charge" then
        added = added + 1
        table.insert(img_list, images.img_hold)
      elseif self.list[id][i][j] == "v_charge" then
        added = added + 1
        table.insert(img_list, images.img_hold)
      elseif self.list[id][i][j] == "neutral" then
        added = added + 1
        table.insert(img_list, images.img_dir_small[5])
      elseif self.list[id][i][j] == "maru" then
        added = added + 1
        table.insert(img_list, images.img_maru)
      elseif self.list[id][i][j] == "tilda" then
        added = added + 1
        table.insert(img_list, images.img_tilda)
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
        table.insert(img_list, #img_list - added + 1, images.img_dir_small[dir])
      else
        table.insert(img_list, images.img_dir_small[dir])
      end
    end
  end
  for i = 1, #img_list do
    gui.image(x + offset_x, y + offset_y, img_list[i])
    offset_x = offset_x + 9
  end

end

function Motion_list_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
  self.width = self.width + 7
end

function Motion_list_Menu_Item:left()
  self.object[self.property_name] = self.object[self.property_name] - 1
  if self.object[self.property_name] == 0 then
    self.object[self.property_name] = #self.list
  end
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Motion_list_Menu_Item:right()
  self.object[self.property_name] = self.object[self.property_name] + 1
  if self.object[self.property_name] > #self.list then
    self.object[self.property_name] = 1
  end
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Motion_list_Menu_Item:reset()
  self.object[self.property_name] = self.default_value
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Motion_list_Menu_Item:legend()
  return "legend_mp_reset"
end


local counter_attack_type =
{
  "none",
  "normal_attack",
  "special_sa",
  "option_select",
  "recording"
}

local Move_Input_Display_Menu_Item = {}
Move_Input_Display_Menu_Item.__index = Move_Input_Display_Menu_Item

function Move_Input_Display_Menu_Item:new(name, object)
  local obj = {
    name = name,
    object = object,
    indent = false,
    width = 0,
    height = 0,
    inline = false,
    unselectable = true
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Move_Input_Display_Menu_Item:draw(x, y)

  local offset_x = 6
  local offset_y = -1
  if lang_code[settings.training.language] == "jp" then
    offset_y = 2
  end
  if self.indent then
    offset_x = 8
  end
  local img_list = {}
  local move_inputs = self.object.inputs
  local style = draw.controller_styles[settings.training.controller_style]

  if counter_attack_type[self.object.ca_type] == "special_sa" then
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
          table.insert(img_list, images.img_button_small[style][1])
        elseif move_inputs[i][j] == "MP" then
          added = added + 1
          table.insert(img_list, images.img_button_small[style][2])
        elseif move_inputs[i][j] == "HP" then
          added = added + 1
          table.insert(img_list, images.img_button_small[style][3])
        elseif move_inputs[i][j] == "LK" then
          added = added + 1
          table.insert(img_list, images.img_button_small[style][4])
        elseif move_inputs[i][j] == "MK" then
          added = added + 1
          table.insert(img_list, images.img_button_small[style][5])
        elseif move_inputs[i][j] == "HK" then
          added = added + 1
          table.insert(img_list, images.img_button_small[style][6])
        elseif move_inputs[i][j] == "EXP" then
          added = added + 2
          table.insert(img_list, images.img_button_small[style][1])
          table.insert(img_list, images.img_button_small[style][2])
        elseif move_inputs[i][j] == "EXK" then
          added = added + 2
          table.insert(img_list, images.img_button_small[style][4])
          table.insert(img_list, images.img_button_small[style][5])
        elseif move_inputs[i][j] == "PPP" then
          added = added + 3
          table.insert(img_list, images.img_button_small[style][1])
          table.insert(img_list, images.img_button_small[style][2])
          table.insert(img_list, images.img_button_small[style][3])
        elseif move_inputs[i][j] == "KKK" then
          added = added + 3
          table.insert(img_list, images.img_button_small[style][4])
          table.insert(img_list, images.img_button_small[style][5])
          table.insert(img_list, images.img_button_small[style][6])
        elseif move_inputs[i][j] == "h_charge" then
          added = added + 1
          table.insert(img_list, images.img_hold)
        elseif move_inputs[i][j] == "v_charge" then
          added = added + 1
          table.insert(img_list, images.img_hold)
        elseif move_inputs[i][j] == "v_charge" then
          added = added + 1
          table.insert(img_list, images.img_hold)
        elseif move_inputs[i][j] == "legs_LK" then
          for k = 1, 4 do
            added = added + 1
            table.insert(img_list, images.img_button_small[style][4])
          end
        elseif move_inputs[i][j] == "legs_MK" then
          for k = 1, 4 do
            added = added + 1
            table.insert(img_list, images.img_button_small[style][5])
          end
        elseif move_inputs[i][j] == "legs_HK" then
          for k = 1, 4 do
            added = added + 1
            table.insert(img_list, images.img_button_small[style][6])
          end
        elseif move_inputs[i][j] == "legs_EXK" then
          for k = 1, 4 do
            added = added + 1
            table.insert(img_list, images.img_button_small[style][4])
            table.insert(img_list, images.img_button_small[style][5])
          end
        elseif move_inputs[i][j] == "maru" then
          added = added + 1
          table.insert(img_list, images.img_maru)
        elseif move_inputs[i][j] == "tilda" then
          added = added + 1
          table.insert(img_list, images.img_tilda)
        elseif move_inputs[i][j] == "button" then
          added = added + 1
          table.insert(img_list, "button")
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
          table.insert(img_list, #img_list - added + 1, images.img_dir_small[dir])
        else
          table.insert(img_list, images.img_dir_small[dir])
        end
      else
        if added == 0 then
          table.insert(img_list, "none")
        end
      end
    end

    local start = 0
    local length = 1
    local matching = false
    local i = 2
    while i <= #img_list do
      if img_list[i] == img_list[i-1] then
        if not matching then
          start = i
          matching = true
        else
          length = length + 1
        end
      else
        if matching then
          if length > 1 then
            for j = 1, length do
              table.remove(img_list, start)
            end
            table.insert(img_list, start, images.img_hold)
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
      if img_list[i] == images.img_hold then
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
      gui.image(x + offset_x, y + offset_y, img_list[j])
      offset_x = offset_x + 9
    end


  elseif counter_attack_type[self.object.ca_type] == "option_select" then
  end
end

function Move_Input_Display_Menu_Item:calc_dimensions()
  local w1, h1 = get_text_dimensions(self.name)
  local w2, h2 = get_text_dimensions(":  ")
  local w3, h3 = 7 , 7 --probably

  self.width, self.height = (w1+w2+w3) , math.max(h1, h2, h3)
end


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
  local color = text.default_color
  if selected then
    color = text.selected_color
  end
  local offset_x = 0
  if self.indent then
    offset_x = 8
  end

  render_text_multiple(x + offset_x, y, {self.name, ":  "}, nil, nil, color)
  local w, _ = get_text_dimensions_multiple({self.name, ":  "})

  offset_x = offset_x + w
  local c_offset_y = -2
  if lang_code[settings.training.language] == "jp" then
    c_offset_y = 2
  end
  local style = draw.controller_styles[self.object[self.property_name]]
  draw.draw_buttons_preview_big(x + offset_x, y + c_offset_y, style)
  offset_x = offset_x + 21
  render_text(x + offset_x, y, tostring(self.list[self.object[self.property_name]]), nil, nil, color)
end

function Controller_Style_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
  local w, _ = get_text_dimensions(self.list[self.object[self.property_name]])
  self.width = self.width + w
end

function Controller_Style_Item:left()
  self.object[self.property_name] = self.object[self.property_name] - 1
  if self.object[self.property_name] == 0 then
    self.object[self.property_name] = #self.list
  end
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Controller_Style_Item:right()
  self.object[self.property_name] = self.object[self.property_name] + 1
  if self.object[self.property_name] > #self.list then
    self.object[self.property_name] = 1
  end
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Controller_Style_Item:reset()
  self.object[self.property_name] = self.default_value
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Controller_Style_Item:legend()
  return "legend_mp_reset"
end


local Integer_Menu_Item = {}
Integer_Menu_Item.__index = Integer_Menu_Item

function Integer_Menu_Item:new(name, object, property_name, min, max, loop, default_value, increment, autofire_rate, on_change)
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
  local color = text.default_color
  if selected then
    color = text.selected_color
  end
  local offset_x = 0
  local w, h = 0, 0
  if self.indent then
    offset_x = 8
  end

  render_text_multiple(x + offset_x, y, {self.name, ":  ", self.object[self.property_name]}, nil, nil, color)

end

function Integer_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
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
  if self.on_change then
    self.on_change()
  end
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
  if self.on_change then
    self.on_change()
  end
end

function Integer_Menu_Item:reset()
  self.object[self.property_name] = self.default_value
  self:calc_dimensions()
  if self.on_change then
    self.on_change()
  end
end

function Integer_Menu_Item:legend()
  return "legend_mp_reset"
end

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
  local color = text.default_color
  if selected then
    color = text.selected_color
  end

  local offset_x = 0
  if self.indent then
    offset_x = 8
  end
  local w, h = 0, 0

  if localization[self.name][lang_code[settings.training.language]] ~= "" then
    render_text(x + offset_x, y, self.name, nil, nil, color)
    w, h = get_text_dimensions(self.name)
    offset_x = offset_x + w + 1
  end
  render_text(x + offset_x, y, self.object[self.property_name], nil, nil, color)
  w, h = get_text_dimensions(self.object[self.property_name])
  offset_x = offset_x + w + 1

  local hits_text = "hits"
  if lang_code[settings.training.language] == "en" then
    if self.object[self.property_name] == 1 then
      hits_text = "hit"
    end
    render_text(x + offset_x, y, hits_text, nil, nil, color)
    w, h = get_text_dimensions(hits_text)
    offset_x = offset_x + w + 1
  end
  if self.suffix ~= "" then
    render_text(x + offset_x, y, self.suffix, nil, nil, color)
  end

end

function Hits_Before_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
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

function Hits_Before_Menu_Item:reset()
  self.object[self.property_name] = self.default_value
end

function Hits_Before_Menu_Item:legend()
  return "legend_mp_reset"
end

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
  local color = text.default_color
  if selected then
    color = text.selected_color
  end

  local offset_x = 0

  render_text_multiple(x + offset_x, y, {self.name, ":  ", self.object[self.property_name]}, nil, nil, color)

end

function Map_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
end

function Map_Menu_Item:left()
  if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
    return
  end

  if self.object[self.property_name] == "" then
    for key, value in pairs(self.map_object[self.map_property]) do
      self.object[self.property_name] = key
    end
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
  if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
    return
  end

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

function Map_Menu_Item:reset()
  self.object[self.property_name] = ""
end

function Map_Menu_Item:legend()
  return "legend_mp_reset"
end


local Button_Menu_Item = {}
Button_Menu_Item.__index = Button_Menu_Item

function Button_Menu_Item:new(name, validate_function)
  local obj = {
    name = name,
    width = 0,
    height = 0,
    validate_function = validate_function,
    last_frame_validated = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Button_Menu_Item:draw(x, y, selected)
  local color = text.default_color
  if selected then
    color = text.selected_color

    if self.last_frame_validated > gamestate.frame_number then
      self.last_frame_validated = 0
    end

    if (gamestate.frame_number - self.last_frame_validated < 5 ) then
      color = button_activated_color
    end
  end

  render_text(x, y, self.name, nil, nil, color)
end

function Button_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions(self.name)
end

function Button_Menu_Item:validate()
  self.last_frame_validated = gamestate.frame_number
  if self.validate_function then
    self.validate_function()
  end
end

function Button_Menu_Item:legend()
  return "legend_lp_select"
end


local Header_Menu_Item = {}
Header_Menu_Item.__index = Header_Menu_Item

function Header_Menu_Item:new(name)
  local obj = {
    name = name,
    width = 0,
    height = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Header_Menu_Item:draw(x, y, state)
  local color = text.default_color
  if state == "active" then
    color = text.default_color
  elseif state == "selected" then
    color = text.selected_color
  elseif state == "disabled" then
    color = text.disabled_color
  end

  render_text(x, y, self.name, nil, nil, color)
end

function Header_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions(self.name)
end


local Footer_Menu_Item = {}
Footer_Menu_Item.__index = Footer_Menu_Item

function Footer_Menu_Item:new(name)
  local obj = {
    name = name,
    width = 0,
    height = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Footer_Menu_Item:draw(x, y, state)
  local color = text.disabled_color
  render_text(x, y, self.name, lang_code[settings.training.language], nil, color)
end

function Footer_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions(self.name)
end


local Label_Menu_Item = {}
Label_Menu_Item.__index = Label_Menu_Item

function Label_Menu_Item:new(name, inline)
  local obj = {
    name = name,
    inline = inline or false,
    unselectable = true,
    width = 0,
    height = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Label_Menu_Item:draw(x, y, state)
  local color = text.disabled_color

  render_text(x, y, self.name, nil, nil, color)

end

function Label_Menu_Item:calc_dimensions()
  self.width, self.height = get_text_dimensions(self.name)
end


local Frame_Number_Item = {}
Frame_Number_Item.__index = Frame_Number_Item

function Frame_Number_Item:new(name, object, inline)
  local obj = {
    name = name,
    object = object,
    inline = inline or false,
    unselectable = true,
    width = 0,
    height = 0
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Frame_Number_Item:draw(x, y)
  local color = text.disabled_color
  if lang_code[settings.training.language] == "en" then
    render_text_multiple(x, y, {self.object.frames, " ", "frames"}, nil, nil, color)
  elseif lang_code[settings.training.language] == "jp" then
    render_text_multiple(x, y + 3, {self.object.frames, " ", "frames"}, "jp", "8", color)
  end
end

function Frame_Number_Item:calc_dimensions()
  if lang_code[settings.training.language] == "en" then
    self.width, self.height = get_text_dimensions_multiple({self.number, " ", "frames"})
  elseif lang_code[settings.training.language] == "jp" then
    self.width, self.height = get_text_dimensions_multiple({self.number, " ", "frames"}, "jp", "8")
  end
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
    is_main_menu_selected = true,
    main_menu_selected_index = 1,
    sub_menu_selected_index = 1,
    max_entries = 15,
    on_toggle_entry = on_toggle_entry
  }
  if lang_code[settings.training.language] == "jp" then
    obj.max_entries = 11
  end

  for i = 1, #obj.content do
    obj.content[i].topmost_entry = 1
  end

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Multitab_Menu:calc_dimensions()
  for i = 1, #self.content do
    self.content[i].header:calc_dimensions()
    for j = 1, #self.content[i].entries do
      if self.content[i].entries[j].calc_dimensions then
        self.content[i].entries[j]:calc_dimensions()
      end
    end
  end
end

function Multitab_Menu:current_entry()
  if self.is_main_menu_selected then
    return nil
  else
    return self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]
  end
end

function Multitab_Menu:menu_stack_push(menu)
  table.insert(self.menu_stack, menu)
end

function Multitab_Menu:menu_stack_pop(menu)
  for i, m in ipairs(self.menu_stack) do
    if m == menu then
      table.remove(self.menu_stack, i)
      break
    end
  end
end

function Multitab_Menu:menu_stack_top()
  return self.menu_stack[#self.menu_stack]
end

function Multitab_Menu:menu_stack_clear()
  self.menu_stack = {}
end

function Multitab_Menu:menu_stack_update(input)
  if #self.menu_stack == 0 then
    return
  end
  local last_menu = self.menu_stack[#self.menu_stack]
  last_menu:update(input)
end

function Multitab_Menu:menu_stack_draw()
  for i, menu in ipairs(self.menu_stack) do
    menu:draw()
  end
end

function Multitab_Menu:update_dimensions()
  for i, menu in ipairs(self.menu_stack) do
    menu:calc_dimensions()
  end
end

function Multitab_Menu:update(input)

  self.max_entries = 15
  if lang_code[settings.training.language] == "jp" then
    self.max_entries = 11
  end

  local function get_position_in_list(entries, index)
    local pos = index
    for i = 1, index do
      if entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i]:is_disabled())then
        pos = pos - 1
      end
    end
    return pos
  end

  local function get_bottom_page_position(entries)
    local total = 0
    for i = #entries, 1, -1 do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i]:is_disabled())) then
        total = total + 1
      end
      if total >= self.max_entries then
        return i
      end
    end
    return 1
  end

  local function last_visible_entry(entries)
    for i = #entries, 1, -1 do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i]:is_disabled())) then
        return i
      end
    end
    return 1
  end

  while self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].unselectable or
  (self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].is_disabled and
  self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]:is_disabled()) do
    self.sub_menu_selected_index = self.sub_menu_selected_index - 1
    if self.sub_menu_selected_index == 0 then
      self.is_main_menu_selected = true
      self.sub_menu_selected_index = 1
    end

    if get_position_in_list(self.content[self.main_menu_selected_index].entries, self.sub_menu_selected_index) < self.content[self.main_menu_selected_index].topmost_entry and not self.is_main_menu_selected then
      self.content[self.main_menu_selected_index].topmost_entry = math.min(self.sub_menu_selected_index, 1)
    end
  end

  if get_position_in_list(self.content[self.main_menu_selected_index].entries, self.sub_menu_selected_index) > self.content[self.main_menu_selected_index].topmost_entry + self.max_entries then
    self.content[self.main_menu_selected_index].topmost_entry = math.min(self.sub_menu_selected_index, get_bottom_page_position(self.content[self.main_menu_selected_index].entries))
  end

  if input.down then
    repeat
      if self.is_main_menu_selected then
        self.is_main_menu_selected = false
        self.sub_menu_selected_index = self.content[self.main_menu_selected_index].topmost_entry
--         self.content[self.main_menu_selected_index].topmost_entry = 1
      else
        self.sub_menu_selected_index = self.sub_menu_selected_index + 1
        if self.sub_menu_selected_index > #self.content[self.main_menu_selected_index].entries then
          self.is_main_menu_selected = true
          self.sub_menu_selected_index = 1
        end
      end
      if get_position_in_list(self.content[self.main_menu_selected_index].entries, self.sub_menu_selected_index) > self.max_entries and not self.is_main_menu_selected then
        self.content[self.main_menu_selected_index].topmost_entry = math.min(self.sub_menu_selected_index, get_bottom_page_position(self.content[self.main_menu_selected_index].entries))
      end
    until (
      self.is_main_menu_selected or not self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].unselectable and
      (self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].is_disabled == nil
      or not self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]:is_disabled())
    )
  end

  if input.up then
    repeat
      if self.is_main_menu_selected then
        self.is_main_menu_selected = false
        self.sub_menu_selected_index = #self.content[self.main_menu_selected_index].entries
        self.content[self.main_menu_selected_index].topmost_entry = get_bottom_page_position(self.content[self.main_menu_selected_index].entries)
      else
        self.sub_menu_selected_index = self.sub_menu_selected_index - 1
        if self.sub_menu_selected_index == 0 then
          self.is_main_menu_selected = true
          self.sub_menu_selected_index = 1
        end
      end
      if get_position_in_list(self.content[self.main_menu_selected_index].entries, self.sub_menu_selected_index) < self.content[self.main_menu_selected_index].topmost_entry and not self.is_main_menu_selected then
        self.content[self.main_menu_selected_index].topmost_entry = math.min(self.sub_menu_selected_index, 1)
      end
    until (
      self.is_main_menu_selected or not self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].unselectable and
      (self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].is_disabled == nil
      or not self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]:is_disabled())
    )
  end

  local current_entry = self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]

  if input.left then
    if self.is_main_menu_selected then
      self.main_menu_selected_index = self.main_menu_selected_index - 1
      if self.main_menu_selected_index == 0 then
        self.main_menu_selected_index = #self.content
      end
    elseif current_entry ~= nil then
      if current_entry.left ~= nil then
        current_entry:left()
        if self.on_toggle_entry ~= nil then
          self:on_toggle_entry()
        end
      end
    end
  end

  if input.right then
    if self.is_main_menu_selected then
      self.main_menu_selected_index = self.main_menu_selected_index + 1
      if self.main_menu_selected_index > #self.content then
        self.main_menu_selected_index = 1
      end
    elseif current_entry ~= nil then
      if current_entry.right ~= nil then
        current_entry:right()
        if self.on_toggle_entry ~= nil then
          self:on_toggle_entry()
        end
      end
    end
  end

  if input.validate then
    if self.is_main_menu_selected then
    elseif current_entry ~= nil then
      if current_entry.validate then
        current_entry:validate()
        if self.on_toggle_entry ~= nil then
          self:on_toggle_entry()
        end
      end
    end
  end

  if input.reset then
    if self.is_main_menu_selected then
    elseif current_entry ~= nil then
      if current_entry.reset then
        current_entry:reset()
        if self.on_toggle_entry ~= nil then
          self:on_toggle_entry()
        end
      end
    end
  end

  if input.cancel then
    if self.is_main_menu_selected then
    elseif current_entry ~= nil then
      if current_entry.cancel then
        current_entry:cancel()
        if self.on_toggle_entry ~= nil then
          self:on_toggle_entry()
        end
      end
    end
  end

  if input.scroll_up then
    local total = 0
    local entries = self.content[self.main_menu_selected_index].entries
    local target = math.max(self.sub_menu_selected_index - self.max_entries, 1)
    for i = target, 1, -1 do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i]:is_disabled())) then
        total = total + 1
      end
      target = i
      if total >= self.max_entries then
        break
      end
    end
    self.content[self.main_menu_selected_index].topmost_entry = target
    if not self.is_main_menu_selected then
      if self.sub_menu_selected_index == 1 then
        self.is_main_menu_selected = true
      else
        self.sub_menu_selected_index = target
      end
    end
  end

  if input.scroll_down then
    local total = 0
    local entries = self.content[self.main_menu_selected_index].entries
    local target = math.min(self.sub_menu_selected_index + self.max_entries, get_bottom_page_position(entries))
    for i = self.main_menu_selected_index, target do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i]:is_disabled())) then
        total = total + 1
      end
      target = i
      if total >= self.max_entries then
        break
      end
    end
    self.content[self.main_menu_selected_index].topmost_entry = target
    if not self.is_main_menu_selected then
      if self.sub_menu_selected_index == last_visible_entry(entries) then
        self.is_main_menu_selected = true
        self.sub_menu_selected_index = 1
      elseif self.sub_menu_selected_index >= get_bottom_page_position(entries) then
        self.sub_menu_selected_index = last_visible_entry(entries)
      else
        self.sub_menu_selected_index = target
      end
    end
  end
end

function Multitab_Menu:draw()
  gui.box(self.left, self.top, self.right, self.bottom, menu_background_color, menu_outline_color)

  local base_offset = 0
  local menu_width = self.right - self.left

  self:update_dimensions()

  local total_item_width = 0
  for i=1, #self.content do
    total_item_width = total_item_width + self.content[i].header.width
  end

  local offset = 0
  local x_padding = 15
  local y_padding = 5
  local gap = (menu_width - total_item_width) / (#self.content + 1)
  local menu_x = self.left + x_padding
  local menu_y = 0

  local w, h = get_text_dimensions("legend_hp_scroll")
  local legend_y_padding = 3
  local legend_y = self.bottom - (h + legend_y_padding * 2)

  for i = 1, #self.content do
    local state = "disabled"
    if i == self.main_menu_selected_index then
      state = "active"
      if self.is_main_menu_selected then
        state = "selected"
      end
    end
    self.content[i].header:draw(self.left + gap + offset, self.top + y_padding, state)
    offset = offset + self.content[i].header.width + gap
    menu_y = self.top + y_padding * 2 + self.content[i].header.height
  end
  if lang_code[settings.training.language] == "en" then
    menu_y = menu_y - 1
  end
  for pad = 15, 35 do
    gui.drawline(self.left + pad, menu_y - 1, self.right - pad, menu_y - 1, 0xFFFFFF0F)
  end

  menu_y = menu_y + 4

  local scroll_down = false
  local menu_item_spacing = 1
  if lang_code[settings.training.language] == "jp" then
    menu_item_spacing = 1
  end
  local y_offset = 0
  local is_focused = self == self:menu_stack_top()
  for i = 1, #self.content[self.main_menu_selected_index].entries do
    if i >= self.content[self.main_menu_selected_index].topmost_entry and (self.content[self.main_menu_selected_index].entries[i].is_disabled == nil or not self.content[self.main_menu_selected_index].entries[i]:is_disabled()) then
      if self.content[self.main_menu_selected_index].entries[i].inline and (i - 1) >= 1 then
        local x_offset = self.content[self.main_menu_selected_index].entries[i - 1].width + 8
        if lang_code[settings.training.language] == "jp" then
          x_offset = x_offset + 2
        end
        local y_adj = -1 * (self.content[self.main_menu_selected_index].entries[i - 1].height + menu_item_spacing)
        self.content[self.main_menu_selected_index].entries[i]:draw(menu_x + x_offset, menu_y + y_offset + y_adj, not self.is_main_menu_selected and is_focused and self.sub_menu_selected_index == i)
      else
        if menu_y + y_offset + 5 >= legend_y then
          scroll_down = true
        else
          self.content[self.main_menu_selected_index].entries[i]:draw(menu_x, menu_y + y_offset, not self.is_main_menu_selected and is_focused and self.sub_menu_selected_index == i)
          y_offset = y_offset + self.content[self.main_menu_selected_index].entries[i].height + menu_item_spacing
        end
      end
    end
  end

  if not self.is_main_menu_selected then
    if self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index].legend then
      render_text(menu_x, legend_y + legend_y_padding, self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]:legend(), nil, nil, text.disabled_color)
    end
  end

  local scroll_up = self.content[self.main_menu_selected_index].topmost_entry > 1
  if scroll_down or scroll_up then
    render_text(self.right - w - x_padding, legend_y + legend_y_padding, "legend_hp_scroll", nil, nil, text.disabled_color)

    local scroll_arrow_y_pos =  menu_y + (y_offset - menu_item_spacing - h) + h / 2 - 2
    if lang_code[settings.training.language] == "jp" then
      scroll_arrow_y_pos = menu_y + (y_offset - menu_item_spacing - h) + h / 2 - 1
    end
    if scroll_up then
      gui.image(self.left + x_padding / 2 - 2, menu_y + h / 2 - 2, images.scroll_up_arrow)
    end
    if scroll_down then
      gui.image(self.left + x_padding / 2 - 2, scroll_arrow_y_pos, images.scroll_down_arrow)
    end
  end
end


local Menu = {}
Menu.__index = Menu

function Menu:new(left, top, right, bottom, content, on_toggle_entry, draw_legend)
  local obj = {
    left = left,
    top = top,
    right = right,
    bottom = bottom,
    content = content,
    selected_index = 1,
    on_toggle_entry = on_toggle_entry,
    draw_legend = draw_legend or true
  }

  setmetatable(obj, self)
  obj:calc_dimensions()
  return obj
end

function Menu:current_entry()
  return self.content[self.selected_index]
end

function Menu:calc_dimensions()
  for i = 1, #self.content do
    self.content[i]:calc_dimensions()
  end
end

function Menu:update(input)

  if input.up then
    if self.content[self.selected_index].is_in_edition then
      self.content[self.selected_index]:up()
    else
      repeat
      self.selected_index = self.selected_index - 1
      if self.selected_index == 0 then
        self.selected_index = #self.content
      end
      until self.content[self.selected_index].is_disabled == nil or not self.content[self.selected_index]:is_disabled()
    end
  end

  if input.down then
    if self.content[self.selected_index].is_in_edition then
      self.content[self.selected_index]:down()
    else
      repeat
        self.selected_index = self.selected_index + 1
        if self.selected_index == #self.content + 1 then
          self.selected_index = 1
        end
      until self.content[self.selected_index].is_disabled == nil or not self.content[self.selected_index]:is_disabled()
    end
  end

  local current_entry = self.content[self.selected_index]

  if input.left then
    if current_entry.left then
      current_entry:left()
      if self.on_toggle_entry ~= nil then
        self:on_toggle_entry()
      end
    end
  end

  if input.right then
    if current_entry.right then
      current_entry:right()
      if self.on_toggle_entry ~= nil then
        self:on_toggle_entry()
      end
    end
  end

  if input.validate then
    if current_entry.validate then
      current_entry:validate()
      if self.on_toggle_entry ~= nil then
        self:on_toggle_entry()
      end
    end
  end

  if input.reset then
    if current_entry.reset then
      current_entry:reset()
      if self.on_toggle_entry ~= nil then
        self:on_toggle_entry()
      end
    end
  end

  if input.cancel then
    if current_entry.cancel then
      current_entry:cancel(current_entry)
      if self.on_toggle_entry ~= nil then
        self:on_toggle_entry()
      end
    end
  end
end

function Menu:draw()
  gui.box(self.left, self.top, self.right, self.bottom, menu_background_color, menu_outline_color)

  local x_padding = 15
  local y_padding = 6
  local menu_x = self.left + x_padding
  local menu_y = self.top + y_padding

  local w, h = get_text_dimensions("legend_hp_scroll")
  local legend_y_padding = 3
  local legend_y = self.bottom - (h + legend_y_padding * 2)

  local menu_item_spacing = 1
  if lang_code[settings.training.language] == "jp" then
    menu_item_spacing = 1
  end
  local y_offset = 0
  for i = 1, #self.content do
    if (self.content[i].is_disabled == nil or not self.content[i]:is_disabled()) then
      if self.content[i].inline and (i - 1) >= 1 then
        local x_offset = self.content[i - 1].width + 8
        if lang_code[settings.training.language] == "jp" then
          x_offset = x_offset + 2
        end
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

  if self.content[self.selected_index].legend then
    render_text(menu_x, legend_y + legend_y_padding, self.content[self.selected_index]:legend(), nil, nil, text.disabled_color)
  end
end

return {
  Gauge_Menu_Item = Gauge_Menu_Item,
  Textfield_Menu_Item = Textfield_Menu_Item,
  On_Off_Menu_Item = On_Off_Menu_Item,
  List_Menu_Item = List_Menu_Item,
  Motion_list_Menu_Item = Motion_list_Menu_Item,
  Move_Input_Display_Menu_Item = Move_Input_Display_Menu_Item,
  Controller_Style_Item = Controller_Style_Item,
  Integer_Menu_Item = Integer_Menu_Item,
  Hits_Before_Menu_Item = Hits_Before_Menu_Item,
  Map_Menu_Item = Map_Menu_Item,
  Button_Menu_Item = Button_Menu_Item,
  Header_Menu_Item = Header_Menu_Item,
  Footer_Menu_Item = Footer_Menu_Item,
  Label_Menu_Item = Label_Menu_Item,
  Frame_Number_Item = Frame_Number_Item,
  Multitab_Menu = Multitab_Menu,
  Menu = Menu
}