text_default_color = 0xF7FFF7FF
text_default_border_color = 0x000000FF--0x101008FF
text_selected_color = 0xFF0000FF
text_disabled_color = 0x999999FF



gui_box_bg_color = 0x1F1F1FF0 --0x293139FF
gui_box_outline_color = 0xBBBBBBF0 --0x840000FF

function gauge_menu_item(name, object, _property_name, _unit, fill_color, _gauge_max, _subdivision_count)
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.player_id = player_id
  o.autofire_rate = 1
  o.unit = _unit or 2
  o.gauge_max = _gauge_max or 0
  o.subdivision_count = _subdivision_count or 1
  o.fill_color = fill_color or 0x0000FFFF
  o.width = 0
  o.height = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end
    local offset = 0

    render_text_multiple(x, y, {self.name, ":  "}, nil, nil, color)
    local offset, h = get_text_dimensions_multiple({self.name, ":  "})

    local box_width = self.gauge_max / self.unit
    local box_top = y + (h - 4) / 2
    if lang_code[training_settings.language] == "jp" then
      box_top = box_top + 1
    end
    local box_left = x + offset
    local box_right = box_left + box_width
    local box_bottom = box_top + 4
    gui.box(box_left, box_top, box_right, box_bottom, text_default_color, text_default_border_color)
    local content_width = self.object[self.property_name] / self.unit
    gui.box(box_left, box_top, box_left + content_width, box_bottom, self.fill_color, 0x00000000)
    for _i = 1, self.subdivision_count - 1 do
      local line_x = box_left + _i * self.gauge_max / (self.subdivision_count * self.unit)
      gui.line(line_x, box_top, line_x, box_bottom, text_default_border_color)
    end

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
    self.width = self.width + self.gauge_max / self.unit
  end

  function o:left()
    self.object[self.property_name] = math.max(self.object[self.property_name] - self.unit, 0)
  end

  function o:right()
    self.object[self.property_name] = math.min(self.object[self.property_name] + self.unit, self.gauge_max)
  end

  function o:reset()
    self.object[self.property_name] = 0
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

available_characters = {
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

function textfield_menu_item(name, object, _property_name, default_value, max_length)
  default_value = default_value or ""
  max_length = max_length or 16
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.default_value = default_value
  o.max_length = max_length
  o.edition_index = 0
  o.is_in_edition = false
  o.content = {}
  o.width = 0
  o.height = 0

  function o:sync_to_var()
    local _str = ""
    for i = 1, #self.content do
      _str = _str..available_characters[self.content[i]]
    end
    self.object[self.property_name] = _str
  end

  function o:sync_from_var()
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

  function o:crop_char_table()
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

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    local _prefix = ""
    local _suffix = ""
    if self.is_in_edition then
      color =  button_activated_color
    elseif _selected then
      color = text_image_selected_color
    end

    local _value = self.object[self.property_name]

    if self.is_in_edition then
      local cycle = 100
      if ((frame_number % cycle) / cycle) < 0.5 then
        render_text(x + (#self.name + 3 + #self.content - 1) * 4, y + 2, "_", "en", nil, color)
      end
    end

    render_text_multiple(x, y, {self.name, ":  ", _value}, nil, nil, color)

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", _value})
  end

  function o:left()
    if self.is_in_edition then
      self:reset()
    end
  end

  function o:right()
    if self.is_in_edition then
      self:validate()
    end
  end

  function o:up()
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

  function o:down()
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

  function o:validate()
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

  function o:reset()
    if not self.is_in_edition then
      o.content = {}
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

  function o:cancel()
    if self.is_in_edition then
      self:crop_char_table()
      self:sync_to_var()
      self.is_in_edition = false
    end
  end

  function o:legend()
    if self.is_in_edition then
      return "legend_textfield_edit"
    else
      return "legend_textfield_edit2"
    end
  end

  o:calc_dimensions()
  o:sync_from_var()

  return o
end

function checkbox_menu_item(name, object, _property_name, default_value)
  if default_value == nil then default_value = false end
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.default_value = default_value
  o.indent = false
  o.width = 0
  o.height = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end

    local _value = ""
    if self.object[self.property_name] then
      _value = "on"
    else
      _value = "off"
    end
    local offset = 0
    if self.indent then
      offset = 8
    end

    render_text_multiple(x + offset, y, {self.name, ":  ", _value}, nil, nil, color)
  end

  function o:calc_dimensions()
    local _value = ""
    if self.object[self.property_name] then
      _value = "on"
    else
      _value = "off"
    end
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", _value})
  end

  function o:left()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function o:right()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function o:reset()
    self.object[self.property_name] = self.default_value
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

function list_menu_item(name, object, _property_name, list, default_value, on_change)
  if default_value == nil then default_value = 1 end
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.list = list
  o.default_value = default_value
  o.indent = false
  o.on_change = on_change or nil
  o.width = 0
  o.height = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end
    local offset = 0
    if self.indent then
      offset = 8
    end

    render_text_multiple(x + offset, y, {self.name, ":  ", self.list[self.object[self.property_name]]}, nil, nil, color)

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.list[self.object[self.property_name]]})
  end

  function o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

function motion_list_menu_item(name, object, _property_name, list, default_value, on_change)
  if default_value == nil then default_value = 1 end
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.list = list
  o.default_value = default_value
  o.indent = false
  o.on_change = on_change or nil
  o.width = 0
  o.height = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end
    local offset_x = 0
    local offset_y = -1
    if self.indent then
      offset_x = 8
    end

    render_text_multiple(x + _offset_x, y, {self.name, ":  "}, nil, nil, color)
    local _w, _ = get_text_dimensions_multiple({self.name, ":  "})
    offset_x = offset_x + _w

    if lang_code[training_settings.language] == "jp" then
      offset_y = 2
    end

    local _img_list = {}
    local _style = controller_styles[training_settings.controller_style]
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
          table.insert(_img_list, img_button_small[_style][1])
        elseif self.list[id][i][j] == "MP" then
          added = added + 1
          table.insert(_img_list, img_button_small[_style][2])
        elseif self.list[id][i][j] == "HP" then
          added = added + 1
          table.insert(_img_list, img_button_small[_style][3])
        elseif self.list[id][i][j] == "LK" then
          added = added + 1
          table.insert(_img_list, img_button_small[_style][4])
        elseif self.list[id][i][j] == "MK" then
          added = added + 1
          table.insert(_img_list, img_button_small[_style][5])
        elseif self.list[id][i][j] == "HK" then
          added = added + 1
          table.insert(_img_list, img_button_small[_style][6])
        elseif self.list[id][i][j] == "EXP" then
          added = added + 2
          table.insert(_img_list, img_button_small[_style][1])
          table.insert(_img_list, img_button_small[_style][2])
        elseif self.list[id][i][j] == "EXK" then
          added = added + 2
          table.insert(_img_list, img_button_small[_style][4])
          table.insert(_img_list, img_button_small[_style][5])
        elseif self.list[id][i][j] == "PPP" then
          added = added + 3
          table.insert(_img_list, img_button_small[_style][1])
          table.insert(_img_list, img_button_small[_style][2])
          table.insert(_img_list, img_button_small[_style][3])
        elseif self.list[id][i][j] == "KKK" then
          added = added + 3
          table.insert(_img_list, img_button_small[_style][4])
          table.insert(_img_list, img_button_small[_style][5])
          table.insert(_img_list, img_button_small[_style][6])
        elseif self.list[id][i][j] == "h_charge" then
          added = added + 1
          table.insert(_img_list, img_hold)
        elseif self.list[id][i][j] == "v_charge" then
          added = added + 1
          table.insert(_img_list, img_hold)
        elseif self.list[id][i][j] == "neutral" then
          added = added + 1
          table.insert(_img_list, img_5_dir_small)
        elseif self.list[id][i][j] == "maru" then
          added = added + 1
          table.insert(_img_list, img_maru)
        elseif self.list[id][i][j] == "tilda" then
          added = added + 1
          table.insert(_img_list, img_tilda)
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
          table.insert(_img_list, #_img_list - added + 1, img_dir_small[dir])
        else
          table.insert(_img_list, img_dir_small[dir])
        end
      end
    end
    for i = 1, #_img_list do
      gui.image(x + offset_x, y + offset_y, _img_list[i])
      offset_x = offset_x + 9
    end

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
    self.width = self.width + 7
  end

  function o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

function move_input_menu_item(name, object)
  if default_value == nil then default_value = 1 end
  local o = {}
  o.name = name
  o.object = object
  o.indent = false
  o.width = 0
  o.height = 0
  o.inline = false
  o.unselectable = true

  function o:draw(x, y, _selected)

    local offset_x = 6
    local offset_y = -1
    if lang_code[training_settings.language] == "jp" then
      offset_y = 2
    end
    if self.indent then
      offset_x = 8
    end

    local _img_list = {}
    local _style = controller_styles[training_settings.controller_style]
    if counter_attack_type[self.object.ca_type] == "special_sa" then

      for i = 1, #counter_attack_special_inputs[self.object.special] do
      local dirs = {forward = false, down = false, back = false, up = false}
      local added = 0
        for j = 1, #counter_attack_special_inputs[self.object.special][i] do
          if counter_attack_special_inputs[self.object.special][i][j] == "forward" then
            dirs.forward = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "down" then
            dirs.down = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "back" then
            dirs.back = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "up" then
            dirs.up = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "LP" then
            added = added + 1
            table.insert(_img_list, img_button_small[_style][1])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "MP" then
            added = added + 1
            table.insert(_img_list, img_button_small[_style][2])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "HP" then
            added = added + 1
            table.insert(_img_list, img_button_small[_style][3])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "LK" then
            added = added + 1
            table.insert(_img_list, img_button_small[_style][4])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "MK" then
            added = added + 1
            table.insert(_img_list, img_button_small[_style][5])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "HK" then
            added = added + 1
            table.insert(_img_list, img_button_small[_style][6])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "EXP" then
            added = added + 2
            table.insert(_img_list, img_button_small[_style][1])
            table.insert(_img_list, img_button_small[_style][2])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "EXK" then
            added = added + 2
            table.insert(_img_list, img_button_small[_style][4])
            table.insert(_img_list, img_button_small[_style][5])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "PPP" then
            added = added + 3
            table.insert(_img_list, img_button_small[_style][1])
            table.insert(_img_list, img_button_small[_style][2])
            table.insert(_img_list, img_button_small[_style][3])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "KKK" then
            added = added + 3
            table.insert(_img_list, img_button_small[_style][4])
            table.insert(_img_list, img_button_small[_style][5])
            table.insert(_img_list, img_button_small[_style][6])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "h_charge" then
            added = added + 1
            table.insert(_img_list, img_hold)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "v_charge" then
            added = added + 1
            table.insert(_img_list, img_hold)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "neutral" then
            added = added + 1
            table.insert(_img_list, img_5_dir_small)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "maru" then
            added = added + 1
            table.insert(_img_list, img_maru)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "tilda" then
            added = added + 1
            table.insert(_img_list, img_tilda)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "button" then
            added = added + 1
            table.insert(_img_list, "button")
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
            table.insert(_img_list, #_img_list - added + 1, img_dir_small[dir])
          else
            table.insert(_img_list, img_dir_small[dir])
          end
        end
      end

      if #counter_attack_special_button > 0 then
        local j = 1
        while j <= #_img_list do
          if _img_list[j] == "button" then
            table.remove(_img_list, j)
            if counter_attack_special_button[self.object.special_button] == "LP" then
                table.insert(_img_list, j, img_button_small[_style][1])
              elseif counter_attack_special_button[self.object.special_button] == "MP" then
                table.insert(_img_list, j, img_button_small[_style][2])
              elseif counter_attack_special_button[self.object.special_button] == "HP" then
                table.insert(_img_list, j, img_button_small[_style][3])
              elseif counter_attack_special_button[self.object.special_button] == "LK" then
                table.insert(_img_list, j, img_button_small[_style][4])
              elseif counter_attack_special_button[self.object.special_button] == "MK" then
                table.insert(_img_list, j, img_button_small[_style][5])
              elseif counter_attack_special_button[self.object.special_button] == "HK" then
                table.insert(_img_list, j, img_button_small[_style][6])
              elseif counter_attack_special_button[self.object.special_button] == "EXP" then
                table.insert(_img_list, j, img_button_small[_style][1])
                table.insert(_img_list, j, img_button_small[_style][2])
              elseif counter_attack_special_button[self.object.special_button] == "EXK" then
                table.insert(_img_list, j, img_button_small[_style][4])
                table.insert(_img_list, j, img_button_small[_style][5])
              elseif counter_attack_special_button[self.object.special_button] == "PPP" then
                table.insert(_img_list, j, img_button_small[_style][1])
                table.insert(_img_list, j, img_button_small[_style][2])
                table.insert(_img_list, j, img_button_small[_style][3])
              elseif counter_attack_special_button[self.object.special_button] == "KKK" then
                table.insert(_img_list, j, img_button_small[_style][4])
                table.insert(_img_list, j, img_button_small[_style][5])
                table.insert(_img_list, j, img_button_small[_style][6])
              end
            end
            j = j + 1
          end
        end

      local _start = 0
      local length = 1
      local matching = false
      local i = 2
      while i <= #_img_list do
        if _img_list[i] == _img_list[i-1] then
          if not matching then
            _start = i
            matching = true
          else
            length = length + 1
          end
        else
          if matching then
            if length > 1 then
              for j = 1, length do
                table.remove(_img_list, _start)
              end
              table.insert(_img_list, _start, img_hold)
              i = 2
            end
            _start = 0
            length = 1
            matching = false
          end
        end
        i = i + 1
      end

      _start = #_img_list
      matching = false
      i = #_img_list

      while i >= 2 do
        if matching then
          if _img_list[i - 1] == _img_list[_start] then
            table.remove(_img_list, i - 1)
            i = i + 1
          else
            matching = false
          end
        end
        if _img_list[i] == img_hold then
          if not matching then
            _start = i - 1
            matching = true
          end
        end
        i = i - 1
      end

      for i = 1, #_img_list do
        gui.image(x + offset_x, y + offset_y, _img_list[i])
        offset_x = offset_x + 9
      end


    elseif counter_attack_type[self.object.ca_type] == "option_select" then
    end
  end

  function o:calc_dimensions()
    local _w1, _h1 = get_text_dimensions(self.name)
    local _w2, _h2 = get_text_dimensions(":  ")
    local _w3, _h3 = 7 , 7 --probably

    self.width, self.height = (_w1+_w2+_w3) , math.max(_h1, _h2, _h3)
  end

  o:calc_dimensions()

  return o
end

function controller_style_item(name, object, _property_name, list, default_value, on_change)
  if default_value == nil then default_value = 1 end
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.list = list
  o.default_value = default_value
  o.indent = false
  o.on_change = on_change or nil
  o.width = 0
  o.height = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end
    local offset_x = 0
    if self.indent then
      offset_x = 8
    end

    render_text_multiple(x + _offset_x, y, {self.name, ":  "}, nil, nil, color)
    local _w, _ = get_text_dimensions_multiple({self.name, ":  "})

    offset_x = offset_x + _w
    local c_offset_y = -2
    if lang_code[training_settings.language] == "jp" then
      c_offset_y = 2
    end
    local _style = controller_styles[self.object[self.property_name]]
    draw_buttons_preview_big(x + offset_x, y + c_offset_y, _style)
    offset_x = offset_x + 21
    render_text(x + offset_x, y, tostring(self.list[self.object[self.property_name]]), nil, nil, color)
  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
    local _w, _ = get_text_dimensions(self.list[self.object[self.property_name]])
    self.width = self.width + _w
  end

  function o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o

end

function integer_menu_item(name, object, _property_name, min, max, loop, default_value, autofire_rate, on_change)
  if default_value == nil then default_value = min end
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.min = min
  o.max = max
  o.loop = loop
  o.default_value = default_value
  o.autofire_rate = autofire_rate
  o.on_change = on_change or nil
  o.width = 0
  o.height = 0
  o.indent = false

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end
    local offset_x = 0
    local _w, h = 0
    if self.indent then
      offset_x = 8
    end

    render_text_multiple(x + _offset_x, y, {self.name, ":  ", self.object[self.property_name]}, nil, nil, color)

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
  end

  function o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
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

  function o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
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

  function o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

function hits_before_menu_item(name, _suffix, object, _property_name, min, max, loop, default_value, autofire_rate)
  if default_value == nil then default_value = min end
  local o = {}
  o.name = name
  o.suffix = _suffix
  o.object = object
  o.property_name = _property_name
  o.min = min
  o.max = max
  o.loop = loop
  o.default_value = default_value
  o.autofire_rate = autofire_rate
  o.width = 0
  o.height = 0
  o.indent = false

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end

    local offset_x = 0
    if self.indent then
      offset_x = 8
    end
    local _w, h = 0

    if loc[self.name][lang_code[training_settings.language]] ~= "" then
      render_text(x + offset_x, y, self.name, nil, nil, color)
      _w, h = get_text_dimensions(self.name)
      offset_x = offset_x + _w + 1
    end
    render_text(x + offset_x, y, self.object[self.property_name], nil, nil, color)
    _w, h = get_text_dimensions(self.object[self.property_name])
    offset_x = offset_x + _w + 1

    local _hits_text = "hits"
    if lang_code[training_settings.language] == "en" then
      if self.object[self.property_name] == 1 then
        _hits_text = "hit"
      end
      render_text(x + offset_x, y, _hits_text, nil, nil, color)
      _w, h = get_text_dimensions(_hits_text)
      offset_x = offset_x + _w + 1
    end
    if self.suffix ~= "" then
      render_text(x + offset_x, y, self.suffix, nil, nil, color)
    end

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
  end

  function o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] < self.min then
      if self.loop then
        self.object[self.property_name] = self.max
      else
        self.object[self.property_name] = self.min
      end
    end
  end

  function o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > self.max then
      if self.loop then
        self.object[self.property_name] = self.min
      else
        self.object[self.property_name] = self.max
      end
    end
  end

  function o:reset()
    self.object[self.property_name] = self.default_value
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

function map_menu_item(name, object, _property_name, map_object, map_property)
  local o = {}
  o.name = name
  o.object = object
  o.property_name = _property_name
  o.map_object = map_object
  o.map_property = map_property
  o.width = 0
  o.height = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color
    end

    local offset_x = 0

    render_text_multiple(x + _offset_x, y, {self.name, ":  ", self.object[self.property_name]}, nil, nil, color)

  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
  end

  function o:left()
    if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
      return
    end

    if self.object[self.property_name] == "" then
      for _key, _value in pairs(self.map_object[self.map_property]) do
        self.object[self.property_name] = _key
      end
    else
      local _previous_key = ""
      for _key, _value in pairs(self.map_object[self.map_property]) do
        if _key == self.object[self.property_name] then
          self.object[self.property_name] = _previous_key
          return
        end
        _previous_key = _key
      end
      self.object[self.property_name] = ""
    end
  end

  function o:right()
    if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
      return
    end

    if self.object[self.property_name] == "" then
      for _key, _value in pairs(self.map_object[self.map_property]) do
        self.object[self.property_name] = _key
        return
      end
    else
      local _previous_key = ""
      for _key, _value in pairs(self.map_object[self.map_property]) do
        if _previous_key == self.object[self.property_name] then
          self.object[self.property_name] = _key
          return
        end
        _previous_key = _key
      end
      self.object[self.property_name] = ""
    end
  end

  function o:reset()
    self.object[self.property_name] = ""
  end

  function o:legend()
    return "legend_mp_reset"
  end

  o:calc_dimensions()

  return o
end

function button_menu_item(name, _validate_function)
  local o = {}
  o.name = name
  o.width = 0
  o.height = 0
  o.validate_function = _validate_function
  o.last_frame_validated = 0

  function o:draw(x, y, _selected)
    local color = text_image_default_color
    if _selected then
      color = text_image_selected_color

      if self.last_frame_validated > frame_number then
        self.last_frame_validated = 0
      end

      if (frame_number - self.last_frame_validated < 5 ) then
        color = button_activated_color
      end
    end

    render_text(x, y, self.name, nil, nil, color)
  end

  function o:calc_dimensions()
    self.width, self.height = get_text_dimensions(self.name)
  end

  function o:validate()
    self.last_frame_validated = frame_number
    if self.validate_function then
      self.validate_function()
    end
  end

  function o:legend()
    return "legend_lp_select"
  end

  o:calc_dimensions()

  return o
end

-- # Menus
menu_stack = {}

function menu_stack_push(menu)
  table.insert(menu_stack, menu)
end

function menu_stack_pop(menu)
  for _i, m in ipairs(menu_stack) do
    if m == menu then
      table.remove(menu_stack, _i)
      break
    end
  end
end

function menu_stack_top()
  return menu_stack[#menu_stack]
end

function menu_stack_clear()
  menu_stack = {}
end

function menu_stack_update(_input)
  if #menu_stack == 0 then
    return
  end
  local last_menu = menu_stack[#menu_stack]
  last_menu:update(_input)
end

function menu_stack_draw()
  for _i, menu in ipairs(menu_stack) do
    menu:draw()
  end
end

function update_dimensions()
  for _i, menu in ipairs(menu_stack) do
    menu:calc_dimensions()
  end
end

function make_multitab_menu(left, _top, _right, bottom, content, on_toggle_entry, additional_draw)
  local m = {}
  m.left = left
  m.top = _top
  m.right = _right
  m.bottom = bottom
  m.content = content

  m.is_main_menu_selected = true
  m.main_menu_selected_index = 1
  m.sub_menu_selected_index = 1
  m.max_entries = 15
  if lang_code[training_settings.language] == "jp" then
    m.max_entries = 11
  end

  m.on_toggle_entry = on_toggle_entry
  m.additional_draw = additional_draw

  for i = 1, #m.content do
    m.content[i].topmost_entry = 1
  end


  function m:update(_input)
    multitab_menu_update(self, _input)
  end

  function m:calc_dimensions()
    for i = 1, #self.content do
      self.content[i].header:calc_dimensions()
      for j = 1, #self.content[i].entries do
        self.content[i].entries[j]:calc_dimensions()
      end
    end
  end

  function m:draw()
    multitab_menu_draw(self)
  end

  function m:current_entry()
    if self.is_main_menu_selected then
      return nil
    else
      return self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]
    end
  end

  return m
end

function multitab_menu_update(menu, _input)

  menu.max_entries = 15
  if lang_code[training_settings.language] == "jp" then
    menu.max_entries = 11
  end

  function get_position_in_list(entries, _index)
    local _pos = _index
    for i = 1, _index do
      if entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i].is_disabled())then
        _pos = _pos - 1
      end
    end
    return _pos
  end

  function get_bottom_page_position(entries)
    local _total = 0
    for i = #entries, 1, -1 do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i].is_disabled())) then
        _total = _total + 1
      end
      if _total >= menu.max_entries then
        return i
      end
    end
    return 1
  end

  function last_visible_entry(entries)
    for i = #entries, 1, -1 do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i].is_disabled())) then
        return i
      end
    end
    return 1
  end

  while menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].unselectable or
  (menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].is_disabled and
  menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].is_disabled()) do
    menu.sub_menu_selected_index = menu.sub_menu_selected_index - 1
    if menu.sub_menu_selected_index == 0 then
      menu.is_main_menu_selected = true
      menu.sub_menu_selected_index = 1
    end

    if get_position_in_list(menu.content[menu.main_menu_selected_index].entries, menu.sub_menu_selected_index) < menu.content[menu.main_menu_selected_index].topmost_entry and not menu.is_main_menu_selected then
      menu.content[menu.main_menu_selected_index].topmost_entry = math.min(menu.sub_menu_selected_index, 1)
    end
  end

  if get_position_in_list(menu.content[menu.main_menu_selected_index].entries, menu.sub_menu_selected_index) > menu.content[menu.main_menu_selected_index].topmost_entry + menu.max_entries then
    menu.content[menu.main_menu_selected_index].topmost_entry = math.min(menu.sub_menu_selected_index, get_bottom_page_position(menu.content[menu.main_menu_selected_index].entries))
  end

  if _input.down then
    repeat
      if menu.is_main_menu_selected then
        menu.is_main_menu_selected = false
        menu.sub_menu_selected_index = menu.content[menu.main_menu_selected_index].topmost_entry
--         menu.content[menu.main_menu_selected_index].topmost_entry = 1
      else
        menu.sub_menu_selected_index = menu.sub_menu_selected_index + 1
        if menu.sub_menu_selected_index > #menu.content[menu.main_menu_selected_index].entries then
          menu.is_main_menu_selected = true
          menu.sub_menu_selected_index = 1
        end
      end
      if get_position_in_list(menu.content[menu.main_menu_selected_index].entries, menu.sub_menu_selected_index) > menu.max_entries and not menu.is_main_menu_selected then
        menu.content[menu.main_menu_selected_index].topmost_entry = math.min(menu.sub_menu_selected_index, get_bottom_page_position(menu.content[menu.main_menu_selected_index].entries))
      end
    until (
      menu.is_main_menu_selected or not menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].unselectable and
      (menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].is_disabled == nil
      or not menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].is_disabled())
    )
  end

  if _input.up then
    repeat
      if menu.is_main_menu_selected then
        menu.is_main_menu_selected = false
        menu.sub_menu_selected_index = #menu.content[menu.main_menu_selected_index].entries
        menu.content[menu.main_menu_selected_index].topmost_entry = get_bottom_page_position(menu.content[menu.main_menu_selected_index].entries)
      else
        menu.sub_menu_selected_index = menu.sub_menu_selected_index - 1
        if menu.sub_menu_selected_index == 0 then
          menu.is_main_menu_selected = true
          menu.sub_menu_selected_index = 1
        end
      end
      if get_position_in_list(menu.content[menu.main_menu_selected_index].entries, menu.sub_menu_selected_index) < menu.content[menu.main_menu_selected_index].topmost_entry and not menu.is_main_menu_selected then
        menu.content[menu.main_menu_selected_index].topmost_entry = math.min(menu.sub_menu_selected_index, 1)
      end
    until (
      menu.is_main_menu_selected or not menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].unselectable and
      (menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].is_disabled == nil
      or not menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].is_disabled())
    )
  end

  local current_entry = menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index]

  if _input.left then
    if menu.is_main_menu_selected then
      menu.main_menu_selected_index = menu.main_menu_selected_index - 1
      if menu.main_menu_selected_index == 0 then
        menu.main_menu_selected_index = #menu.content
      end
    elseif current_entry ~= nil then
      if current_entry.left ~= nil then
        current_entry:left()
        if menu.on_toggle_entry ~= nil then
          menu.on_toggle_entry(menu)
        end
      end
    end
  end

  if _input.right then
    if menu.is_main_menu_selected then
      menu.main_menu_selected_index = menu.main_menu_selected_index + 1
      if menu.main_menu_selected_index > #menu.content then
        menu.main_menu_selected_index = 1
      end
    elseif current_entry ~= nil then
      if current_entry.right ~= nil then
        current_entry:right()
        if menu.on_toggle_entry ~= nil then
          menu.on_toggle_entry(menu)
        end
      end
    end
  end

  if _input.validate then
    if is_main_menu_selected then
    elseif current_entry ~= nil then
      if current_entry.validate then
        current_entry:validate()
        if menu.on_toggle_entry ~= nil then
          menu.on_toggle_entry(menu)
        end
      end
    end
  end

  if _input.reset then
    if is_main_menu_selected then
    elseif current_entry ~= nil then
      if current_entry.reset then
        current_entry:reset()
        if menu.on_toggle_entry ~= nil then
          menu.on_toggle_entry(menu)
        end
      end
    end
  end

  if _input.cancel then
    if is_main_menu_selected then
    elseif current_entry ~= nil then
      if current_entry.cancel then
        current_entry:cancel()
        if menu.on_toggle_entry ~= nil then
          menu.on_toggle_entry(menu)
        end
      end
    end
  end

  if _input.scroll_up then
    local _total = 0
    local entries = menu.content[menu.main_menu_selected_index].entries
    local _target = math.max(menu.sub_menu_selected_index - menu.max_entries, 1)
    for i = _target, 1, -1 do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i].is_disabled())) then
        _total = _total + 1
      end
      _target = i
      if _total >= menu.max_entries then
        break
      end
    end
    menu.content[menu.main_menu_selected_index].topmost_entry = _target
    if not menu.is_main_menu_selected then
      if menu.sub_menu_selected_index == 1 then
        menu.is_main_menu_selected = true
      else
        menu.sub_menu_selected_index = _target
      end
    end
  end

  if _input.scroll_down then
    local _total = 0
    local entries = menu.content[menu.main_menu_selected_index].entries
    local _target = math.min(menu.sub_menu_selected_index + menu.max_entries, get_bottom_page_position(entries))
    for i = menu.main_menu_selected_index, _target do
      if not (entries[i].unselectable or entries[i].inline or (entries[i].is_disabled and entries[i].is_disabled())) then
        _total = _total + 1
      end
      _target = i
      if _total >= menu.max_entries then
        break
      end
    end
    menu.content[menu.main_menu_selected_index].topmost_entry = _target
    if not menu.is_main_menu_selected then
      if menu.sub_menu_selected_index == last_visible_entry(entries) then
        menu.is_main_menu_selected = true
        menu.sub_menu_selected_index = 1
      elseif menu.sub_menu_selected_index >= get_bottom_page_position(entries) then
        menu.sub_menu_selected_index = last_visible_entry(entries)
      else
        menu.sub_menu_selected_index = _target
      end
    end
  end
end

function multitab_menu_draw(menu)
  gui.box(menu.left, menu.top, menu.right, menu.bottom, gui_box_bg_color, gui_box_outline_color)

  local base_offset = 0
  local menu_width = menu.right - menu.left

  update_dimensions()

  local _total_item_width = 0
  for i=1, #menu.content do
    _total_item_width = _total_item_width + menu.content[i].header.width
  end

  local offset = 0
  local x_padding = 15
  local y_padding = 5
  local _gap = (menu_width - _total_item_width) / (#menu.content + 1)
  local menu_x = menu.left + x_padding
  local menu_y = 0

  local _w, h = get_text_dimensions("legend_hp_scroll")
  local legend_y_padding = 3
  local legend_y = menu.bottom - (h + legend_y_padding * 2)

  for i = 1, #menu.content do
    local _state = "disabled"
    if i == menu.main_menu_selected_index then
      _state = "active"
      if menu.is_main_menu_selected then
        _state = "selected"
      end
    end
    menu.content[i].header:draw(menu.left + _gap + offset, menu.top + y_padding, _state)
    offset = offset + menu.content[i].header.width + _gap
    menu_y = menu.top + y_padding * 2 + menu.content[i].header.height
  end
  for _pad = 15, 35 do
    gui.drawline(menu.left + _pad, menu_y - 1, menu.right - _pad, menu_y - 1, 0xFFFFFF0F)
  end


  menu_y = menu_y + 4

  local scroll_down = false
  local menu_item_spacing = 2
  if lang_code[training_settings.language] == "jp" then
    menu_item_spacing = 1
  end
  local y_offset = 0
  local _is_focused = menu == menu_stack_top()
  for i = 1, #menu.content[menu.main_menu_selected_index].entries do
--   print(menu.content[menu.main_menu_selected_index].entries[i].name)
    if i >= menu.content[menu.main_menu_selected_index].topmost_entry and (menu.content[menu.main_menu_selected_index].entries[i].is_disabled == nil or not menu.content[menu.main_menu_selected_index].entries[i].is_disabled()) then
      if menu.content[menu.main_menu_selected_index].entries[i].inline and (i - 1) >= 1 then
        local x_offset = menu.content[menu.main_menu_selected_index].entries[i - 1].width + 8
        if lang_code[training_settings.language] == "jp" then
          x_offset = x_offset + 2
        end
        local y_adj = -1 * (menu.content[menu.main_menu_selected_index].entries[i - 1].height + menu_item_spacing)
        menu.content[menu.main_menu_selected_index].entries[i]:draw(menu_x + x_offset, menu_y + y_offset + y_adj, not menu.is_main_menu_selected and _is_focused and menu.sub_menu_selected_index == i)
      else
        if menu_y + y_offset + 5 >= legend_y then
          scroll_down = true
        else
          menu.content[menu.main_menu_selected_index].entries[i]:draw(menu_x, menu_y + y_offset, not menu.is_main_menu_selected and _is_focused and menu.sub_menu_selected_index == i)
          y_offset = y_offset + menu.content[menu.main_menu_selected_index].entries[i].height + menu_item_spacing
        end
      end
    end
  end

  if not menu.is_main_menu_selected then
    if menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index].legend then
      local color = text_image_disabled_color
      render_text(menu_x, legend_y + legend_y_padding, menu.content[menu.main_menu_selected_index].entries[menu.sub_menu_selected_index]:legend(), nil, nil, text_image_disabled_color)
    end
  end

  local scroll_up = menu.content[menu.main_menu_selected_index].topmost_entry > 1
  if scroll_down or scroll_up then
    render_text(_menu.right - _w - x_padding, _legend_y + _legend_y_padding, "legend_hp_scroll", nil, nil, text_image_disabled_color)

    local _scroll_arrow_y_pos =  menu_y + (y_offset - menu_item_spacing - h) + h / 2 - 2
    if lang_code[training_settings.language] == "jp" then
      _scroll_arrow_y_pos = menu_y + (y_offset - menu_item_spacing - h) + h / 2 - 1
    end
    if scroll_up then
      gui.image(menu.left + x_padding / 2 - 2, menu_y + h / 2 - 2, scroll_up_arrow)
    end
    if scroll_down then
      gui.image(menu.left + x_padding / 2 - 2, _scroll_arrow_y_pos, scroll_down_arrow)
    end
  end

  if menu.additional_draw ~= nil then
    menu.additional_draw(menu)
  end

end

function make_menu(left, _top, _right, bottom, content, on_toggle_entry, draw_legend)
  local m = {}
  m.left = left
  m.top = _top
  m.right = _right
  m.bottom = bottom
  m.content = content

  m.selected_index = 1
  m.on_toggle_entry = on_toggle_entry
  if draw_legend ~= nil then
    m.draw_legend = draw_legend
  else
    m.draw_legend = true
  end

  function m:update(_input)
    menu_update(self, _input)
  end

  function m:draw()
    menu_draw(self)
  end

  function m:current_entry()
    return self.content[self.selected_index]
  end

  function m:calc_dimensions()
    for i = 1, #self.content do
      self.content[i]:calc_dimensions()
    end
  end

  return m
end

function menu_update(menu, _input)

  if _input.up then
    if menu.content[menu.selected_index].is_in_edition then
      menu.content[menu.selected_index]:up()
    else
      repeat
      menu.selected_index = menu.selected_index - 1
      if menu.selected_index == 0 then
        menu.selected_index = #menu.content
      end
      until menu.content[menu.selected_index].is_disabled == nil or not menu.content[menu.selected_index].is_disabled()
    end
  end

  if _input.down then
    if menu.content[menu.selected_index].is_in_edition then
      menu.content[menu.selected_index]:down()
    else
      repeat
        menu.selected_index = menu.selected_index + 1
        if menu.selected_index == #menu.content + 1 then
          menu.selected_index = 1
        end
      until menu.content[menu.selected_index].is_disabled == nil or not menu.content[menu.selected_index].is_disabled()
    end
  end

  current_entry = menu.content[menu.selected_index]

  if _input.left then
    if current_entry.left then
      current_entry:left()
      if menu.on_toggle_entry ~= nil then
        menu.on_toggle_entry(menu)
      end
    end
  end

  if _input.right then
    if current_entry.right then
      current_entry:right()
      if menu.on_toggle_entry ~= nil then
        menu.on_toggle_entry(menu)
      end
    end
  end

  if _input.validate then
    if current_entry.validate then
      current_entry:validate()
      if menu.on_toggle_entry ~= nil then
        menu.on_toggle_entry(menu)
      end
    end
  end

  if _input.reset then
    if current_entry.reset then
      current_entry:reset()
      if menu.on_toggle_entry ~= nil then
        menu.on_toggle_entry(menu)
      end
    end
  end

  if _input.cancel then
    if current_entry.cancel then
      current_entry:cancel()
      if menu.on_toggle_entry ~= nil then
        menu.on_toggle_entry(menu)
      end
    end
  end
end

function menu_draw(menu)
  gui.box(menu.left, menu.top, menu.right, menu.bottom, gui_box_bg_color, gui_box_outline_color)

  local menu_x = menu.left + 10
  local menu_y = menu.top + 9
  local draw_index = 0

  menu_item_spacing = 1

  for i = 1, #menu.content do
    if menu.content[i].is_disabled == nil or not menu.content[i].is_disabled() then
      menu.content[i]:draw(menu_x, menu_y + menu_item_spacing * draw_index, menu.selected_index == i)
      draw_index = draw_index + 1
    end
  end

  if menu.draw_legend then
    if menu.content[menu.selected_index].legend then
      render_text(menu_x, menu.bottom - 12, menu.content[menu.selected_index]:legend(), nil, nil, text_image_disabled_color)
    end
  end
end
