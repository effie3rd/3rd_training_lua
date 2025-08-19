text_default_color = 0xF7FFF7FF
text_default_border_color = 0x000000FF--0x101008FF
text_selected_color = 0xFF0000FF
text_disabled_color = 0x999999FF



gui_box_bg_color = 0x1F1F1FF0 --0x293139FF
gui_box_outline_color = 0xBBBBBBF0 --0x840000FF

function gauge_menu_item(_name, _object, _property_name, _unit, _fill_color, _gauge_max, _subdivision_count)
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.player_id = _player_id
  _o.autofire_rate = 1
  _o.unit = _unit or 2
  _o.gauge_max = _gauge_max or 0
  _o.subdivision_count = _subdivision_count or 1
  _o.fill_color = _fill_color or 0x0000FFFF
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end
    local _offset = 0

    render_text_multiple(_x, _y, {self.name, ":  "}, nil, nil, _color)
    local _offset, _h = get_text_dimensions_multiple({self.name, ":  "})

    local _box_width = self.gauge_max / self.unit
    local _box_top = _y + (_h - 4) / 2
    if lang_code[training_settings.language] == "jp" then
      _box_top = _box_top + 1
    end
    local _box_left = _x + _offset
    local _box_right = _box_left + _box_width
    local _box_bottom = _box_top + 4
    gui.box(_box_left, _box_top, _box_right, _box_bottom, text_default_color, text_default_border_color)
    local _content_width = self.object[self.property_name] / self.unit
    gui.box(_box_left, _box_top, _box_left + _content_width, _box_bottom, self.fill_color, 0x00000000)
    for _i = 1, self.subdivision_count - 1 do
      local _line_x = _box_left + _i * self.gauge_max / (self.subdivision_count * self.unit)
      gui.line(_line_x, _box_top, _line_x, _box_bottom, text_default_border_color)
    end

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
    self.width = self.width + self.gauge_max / self.unit
  end

  function _o:left()
    self.object[self.property_name] = math.max(self.object[self.property_name] - self.unit, 0)
  end

  function _o:right()
    self.object[self.property_name] = math.min(self.object[self.property_name] + self.unit, self.gauge_max)
  end

  function _o:reset()
    self.object[self.property_name] = 0
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
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

function textfield_menu_item(_name, _object, _property_name, _default_value, _max_length)
  _default_value = _default_value or ""
  _max_length = _max_length or 16
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value
  _o.max_length = _max_length
  _o.edition_index = 0
  _o.is_in_edition = false
  _o.content = {}
  _o.width = 0
  _o.height = 0

  function _o:sync_to_var()
    local _str = ""
    for i = 1, #self.content do
      _str = _str..available_characters[self.content[i]]
    end
    self.object[self.property_name] = _str
  end

  function _o:sync_from_var()
    self.content = {}
    for i = 1, #self.object[self.property_name] do
      local _c = self.object[self.property_name]:sub(i,i)
      for j = 1, #available_characters do
        if available_characters[j] == _c then
          table.insert(self.content, j)
          break
        end
      end
    end
  end

  function _o:crop_char_table()
    local _last_empty_index = 0
    for i = 1, #self.content do
      if self.content[i] == 1 then
        _last_empty_index = i
      else
        _last_empty_index = 0
      end
    end

    if _last_empty_index > 0 then
      for i = _last_empty_index, #self.content do
        table.remove(self.content, _last_empty_index)
      end
    end
  end

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    local _prefix = ""
    local _suffix = ""
    if self.is_in_edition then
      _color =  button_activated_color
    elseif _selected then
      _color = text_image_selected_color
    end

    local _value = self.object[self.property_name]

    if self.is_in_edition then
      local _cycle = 100
      if ((frame_number % _cycle) / _cycle) < 0.5 then
        render_text(_x + (#self.name + 3 + #self.content - 1) * 4, _y + 2, "_", "en", nil, _color)
      end
    end

    render_text_multiple(_x, _y, {self.name, ":  ", _value}, nil, nil, _color)

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", _value})
  end

  function _o:left()
    if self.is_in_edition then
      self:reset()
    end
  end

  function _o:right()
    if self.is_in_edition then
      self:validate()
    end
  end

  function _o:up()
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

  function _o:down()
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

  function _o:validate()
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

  function _o:reset()
    if not self.is_in_edition then
      _o.content = {}
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

  function _o:cancel()
    if self.is_in_edition then
      self:crop_char_table()
      self:sync_to_var()
      self.is_in_edition = false
    end
  end

  function _o:legend()
    if self.is_in_edition then
      return "legend_textfield_edit"
    else
      return "legend_textfield_edit2"
    end
  end

  _o:calc_dimensions()
  _o:sync_from_var()

  return _o
end

function checkbox_menu_item(_name, _object, _property_name, _default_value)
  if _default_value == nil then _default_value = false end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value
  _o.indent = false
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end

    local _value = ""
    if self.object[self.property_name] then
      _value = "on"
    else
      _value = "off"
    end
    local _offset = 0
    if self.indent then
      _offset = 8
    end

    render_text_multiple(_x + _offset, _y, {self.name, ":  ", _value}, nil, nil, _color)
  end

  function _o:calc_dimensions()
    local _value = ""
    if self.object[self.property_name] then
      _value = "on"
    else
      _value = "off"
    end
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", _value})
  end

  function _o:left()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:right()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
end

function list_menu_item(_name, _object, _property_name, _list, _default_value, _on_change)
  if _default_value == nil then _default_value = 1 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.list = _list
  _o.default_value = _default_value
  _o.indent = false
  _o.on_change = _on_change or nil
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end
    local _offset = 0
    if self.indent then
      _offset = 8
    end

    render_text_multiple(_x + _offset, _y, {self.name, ":  ", self.list[self.object[self.property_name]]}, nil, nil, _color)

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.list[self.object[self.property_name]]})
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
end

function motion_list_menu_item(_name, _object, _property_name, _list, _default_value, _on_change)
  if _default_value == nil then _default_value = 1 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.list = _list
  _o.default_value = _default_value
  _o.indent = false
  _o.on_change = _on_change or nil
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end
    local _offset_x = 0
    local _offset_y = -1
    if self.indent then
      _offset_x = 8
    end

    render_text_multiple(_x + _offset_x, _y, {self.name, ":  "}, nil, nil, _color)
    local _w, _ = get_text_dimensions_multiple({self.name, ":  "})
    _offset_x = _offset_x + _w

    if lang_code[training_settings.language] == "jp" then
      _offset_y = 2
    end

    local _img_list = {}
    local _style = controller_styles[training_settings.controller_style]
    local id = self.object[self.property_name]
    for i = 1, #self.list[id] do
      local _dirs = {forward = false, down = false, back = false, up = false}
      local _added = 0
      for j = 1, #self.list[id][i] do
        if self.list[id][i][j] == "forward" then
          _dirs.forward = true
        elseif self.list[id][i][j] == "down" then
          _dirs.down = true
        elseif self.list[id][i][j] == "back" then
          _dirs.back = true
        elseif self.list[id][i][j] == "up" then
          _dirs.up = true
        elseif self.list[id][i][j] == "LP" then
          _added = _added + 1
          table.insert(_img_list, img_button_small[_style][1])
        elseif self.list[id][i][j] == "MP" then
          _added = _added + 1
          table.insert(_img_list, img_button_small[_style][2])
        elseif self.list[id][i][j] == "HP" then
          _added = _added + 1
          table.insert(_img_list, img_button_small[_style][3])
        elseif self.list[id][i][j] == "LK" then
          _added = _added + 1
          table.insert(_img_list, img_button_small[_style][4])
        elseif self.list[id][i][j] == "MK" then
          _added = _added + 1
          table.insert(_img_list, img_button_small[_style][5])
        elseif self.list[id][i][j] == "HK" then
          _added = _added + 1
          table.insert(_img_list, img_button_small[_style][6])
        elseif self.list[id][i][j] == "EXP" then
          _added = _added + 2
          table.insert(_img_list, img_button_small[_style][1])
          table.insert(_img_list, img_button_small[_style][2])
        elseif self.list[id][i][j] == "EXK" then
          _added = _added + 2
          table.insert(_img_list, img_button_small[_style][4])
          table.insert(_img_list, img_button_small[_style][5])
        elseif self.list[id][i][j] == "PPP" then
          _added = _added + 3
          table.insert(_img_list, img_button_small[_style][1])
          table.insert(_img_list, img_button_small[_style][2])
          table.insert(_img_list, img_button_small[_style][3])
        elseif self.list[id][i][j] == "KKK" then
          _added = _added + 3
          table.insert(_img_list, img_button_small[_style][4])
          table.insert(_img_list, img_button_small[_style][5])
          table.insert(_img_list, img_button_small[_style][6])
        elseif self.list[id][i][j] == "h_charge" then
          _added = _added + 1
          table.insert(_img_list, img_hold)
        elseif self.list[id][i][j] == "v_charge" then
          _added = _added + 1
          table.insert(_img_list, img_hold)
        elseif self.list[id][i][j] == "neutral" then
          _added = _added + 1
          table.insert(_img_list, img_5_dir_small)
        elseif self.list[id][i][j] == "maru" then
          _added = _added + 1
          table.insert(_img_list, img_maru)
        elseif self.list[id][i][j] == "tilda" then
          _added = _added + 1
          table.insert(_img_list, img_tilda)
        end
      end
      local _dir = 0
      if _dirs.forward then
        _dir = 6
        if _dirs.down then
          _dir = 3
        elseif _dirs.up then
          _dir = 9
        end
      elseif _dirs.back then
        _dir = 4
        if _dirs.down then
          _dir = 1
        elseif _dirs.up then
          _dir = 7
        end
      elseif _dirs.down then
        _dir = 2
      elseif _dirs.up then
        _dir = 8
      end

      if _dir > 0 then
        if _added > 0 then
          table.insert(_img_list, #_img_list - _added + 1, img_dir_small[_dir])
        else
          table.insert(_img_list, img_dir_small[_dir])
        end
      end
    end
    for i = 1, #_img_list do
      gui.image(_x + _offset_x, _y + _offset_y, _img_list[i])
      _offset_x = _offset_x + 9
    end

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
    self.width = self.width + 7
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
end

function move_input_menu_item(_name, _object)
  if _default_value == nil then _default_value = 1 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.indent = false
  _o.width = 0
  _o.height = 0
  _o.inline = false
  _o.unselectable = true

  function _o:draw(_x, _y, _selected)

    local _offset_x = 6
    local _offset_y = -1
    if lang_code[training_settings.language] == "jp" then
      _offset_y = 2
    end
    if self.indent then
      _offset_x = 8
    end

    local _img_list = {}
    local _style = controller_styles[training_settings.controller_style]
    if counter_attack_type[self.object.ca_type] == "special_sa" then

      for i = 1, #counter_attack_special_inputs[self.object.special] do
      local _dirs = {forward = false, down = false, back = false, up = false}
      local _added = 0
        for j = 1, #counter_attack_special_inputs[self.object.special][i] do
          if counter_attack_special_inputs[self.object.special][i][j] == "forward" then
            _dirs.forward = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "down" then
            _dirs.down = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "back" then
            _dirs.back = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "up" then
            _dirs.up = true
          elseif counter_attack_special_inputs[self.object.special][i][j] == "LP" then
            _added = _added + 1
            table.insert(_img_list, img_button_small[_style][1])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "MP" then
            _added = _added + 1
            table.insert(_img_list, img_button_small[_style][2])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "HP" then
            _added = _added + 1
            table.insert(_img_list, img_button_small[_style][3])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "LK" then
            _added = _added + 1
            table.insert(_img_list, img_button_small[_style][4])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "MK" then
            _added = _added + 1
            table.insert(_img_list, img_button_small[_style][5])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "HK" then
            _added = _added + 1
            table.insert(_img_list, img_button_small[_style][6])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "EXP" then
            _added = _added + 2
            table.insert(_img_list, img_button_small[_style][1])
            table.insert(_img_list, img_button_small[_style][2])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "EXK" then
            _added = _added + 2
            table.insert(_img_list, img_button_small[_style][4])
            table.insert(_img_list, img_button_small[_style][5])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "PPP" then
            _added = _added + 3
            table.insert(_img_list, img_button_small[_style][1])
            table.insert(_img_list, img_button_small[_style][2])
            table.insert(_img_list, img_button_small[_style][3])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "KKK" then
            _added = _added + 3
            table.insert(_img_list, img_button_small[_style][4])
            table.insert(_img_list, img_button_small[_style][5])
            table.insert(_img_list, img_button_small[_style][6])
          elseif counter_attack_special_inputs[self.object.special][i][j] == "h_charge" then
            _added = _added + 1
            table.insert(_img_list, img_hold)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "v_charge" then
            _added = _added + 1
            table.insert(_img_list, img_hold)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "neutral" then
            _added = _added + 1
            table.insert(_img_list, img_5_dir_small)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "maru" then
            _added = _added + 1
            table.insert(_img_list, img_maru)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "tilda" then
            _added = _added + 1
            table.insert(_img_list, img_tilda)
          elseif counter_attack_special_inputs[self.object.special][i][j] == "button" then
            _added = _added + 1
            table.insert(_img_list, "button")
          end
        end
        local _dir = 0
        if _dirs.forward then
          _dir = 6
          if _dirs.down then
            _dir = 3
          elseif _dirs.up then
            _dir = 9
          end
        elseif _dirs.back then
          _dir = 4
          if _dirs.down then
            _dir = 1
          elseif _dirs.up then
            _dir = 7
          end
        elseif _dirs.down then
          _dir = 2
        elseif _dirs.up then
          _dir = 8
        end

        if _dir > 0 then
          if _added > 0 then
            table.insert(_img_list, #_img_list - _added + 1, img_dir_small[_dir])
          else
            table.insert(_img_list, img_dir_small[_dir])
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
      local _length = 1
      local _matching = false
      local i = 2
      while i <= #_img_list do
        if _img_list[i] == _img_list[i-1] then
          if not _matching then
            _start = i
            _matching = true
          else
            _length = _length + 1
          end
        else
          if _matching then
            if _length > 1 then
              for j = 1, _length do
                table.remove(_img_list, _start)
              end
              table.insert(_img_list, _start, img_hold)
              i = 2
            end
            _start = 0
            _length = 1
            _matching = false
          end
        end
        i = i + 1
      end

      _start = #_img_list
      _matching = false
      i = #_img_list

      while i >= 2 do
        if _matching then
          if _img_list[i - 1] == _img_list[_start] then
            table.remove(_img_list, i - 1)
            i = i + 1
          else
            _matching = false
          end
        end
        if _img_list[i] == img_hold then
          if not _matching then
            _start = i - 1
            _matching = true
          end
        end
        i = i - 1
      end

      for i = 1, #_img_list do
        gui.image(_x + _offset_x, _y + _offset_y, _img_list[i])
        _offset_x = _offset_x + 9
      end


    elseif counter_attack_type[self.object.ca_type] == "option_select" then
    end
  end

  function _o:calc_dimensions()
    local _w1, _h1 = get_text_dimensions(self.name)
    local _w2, _h2 = get_text_dimensions(":  ")
    local _w3, _h3 = 7 , 7 --probably

    self.width, self.height = (_w1+_w2+_w3) , math.max(_h1, _h2, _h3)
  end

  _o:calc_dimensions()

  return _o
end

function controller_style_item(_name, _object, _property_name, _list, _default_value, _on_change)
  if _default_value == nil then _default_value = 1 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.list = _list
  _o.default_value = _default_value
  _o.indent = false
  _o.on_change = _on_change or nil
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end
    local _offset_x = 0
    if self.indent then
      _offset_x = 8
    end

    render_text_multiple(_x + _offset_x, _y, {self.name, ":  "}, nil, nil, _color)
    local _w, _ = get_text_dimensions_multiple({self.name, ":  "})

    _offset_x = _offset_x + _w
    local _c_offset_y = -2
    if lang_code[training_settings.language] == "jp" then
      _c_offset_y = 2
    end
    local _style = controller_styles[self.object[self.property_name]]
    draw_buttons_preview_big(_x + _offset_x, _y + _c_offset_y, _style)
    _offset_x = _offset_x + 21
    render_text(_x + _offset_x, _y, tostring(self.list[self.object[self.property_name]]), nil, nil, _color)
  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  "})
    local _w, _ = get_text_dimensions(self.list[self.object[self.property_name]])
    self.width = self.width + _w
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o

end

function integer_menu_item(_name, _object, _property_name, _min, _max, _loop, _default_value, _autofire_rate, _on_change)
  if _default_value == nil then _default_value = _min end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.min = _min
  _o.max = _max
  _o.loop = _loop
  _o.default_value = _default_value
  _o.autofire_rate = _autofire_rate
  _o.on_change = _on_change or nil
  _o.width = 0
  _o.height = 0
  _o.indent = false

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end
    local _offset_x = 0
    local _w, _h = 0
    if self.indent then
      _offset_x = 8
    end

    render_text_multiple(_x + _offset_x, _y, {self.name, ":  ", self.object[self.property_name]}, nil, nil, _color)

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
  end

  function _o:left()
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

  function _o:right()
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

  function _o:reset()
    self.object[self.property_name] = self.default_value
    self:calc_dimensions()
    if self.on_change then
      self.on_change()
    end
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
end

function hits_before_menu_item(_name, _suffix, _object, _property_name, _min, _max, _loop, _default_value, _autofire_rate)
  if _default_value == nil then _default_value = _min end
  local _o = {}
  _o.name = _name
  _o.suffix = _suffix
  _o.object = _object
  _o.property_name = _property_name
  _o.min = _min
  _o.max = _max
  _o.loop = _loop
  _o.default_value = _default_value
  _o.autofire_rate = _autofire_rate
  _o.width = 0
  _o.height = 0
  _o.indent = false

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end

    local _offset_x = 0
    if self.indent then
      _offset_x = 8
    end
    local _w, _h = 0

    if loc[self.name][lang_code[training_settings.language]] ~= "" then
      render_text(_x + _offset_x, _y, self.name, nil, nil, _color)
      _w, _h = get_text_dimensions(self.name)
      _offset_x = _offset_x + _w + 1
    end
    render_text(_x + _offset_x, _y, self.object[self.property_name], nil, nil, _color)
    _w, _h = get_text_dimensions(self.object[self.property_name])
    _offset_x = _offset_x + _w + 1

    local _hits_text = "hits"
    if lang_code[training_settings.language] == "en" then
      if self.object[self.property_name] == 1 then
        _hits_text = "hit"
      end
      render_text(_x + _offset_x, _y, _hits_text, nil, nil, _color)
      _w, _h = get_text_dimensions(_hits_text)
      _offset_x = _offset_x + _w + 1
    end
    if self.suffix ~= "" then
      render_text(_x + _offset_x, _y, self.suffix, nil, nil, _color)
    end

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] < self.min then
      if self.loop then
        self.object[self.property_name] = self.max
      else
        self.object[self.property_name] = self.min
      end
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > self.max then
      if self.loop then
        self.object[self.property_name] = self.min
      else
        self.object[self.property_name] = self.max
      end
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
end

function map_menu_item(_name, _object, _property_name, _map_object, _map_property)
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.map_object = _map_object
  _o.map_property = _map_property
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color
    end

    local _offset_x = 0

    render_text_multiple(_x + _offset_x, _y, {self.name, ":  ", self.object[self.property_name]}, nil, nil, _color)

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions_multiple({self.name, ":  ", self.object[self.property_name]})
  end

  function _o:left()
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

  function _o:right()
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

  function _o:reset()
    self.object[self.property_name] = ""
  end

  function _o:legend()
    return "legend_mp_reset"
  end

  _o:calc_dimensions()

  return _o
end

function button_menu_item(_name, _validate_function)
  local _o = {}
  _o.name = _name
  _o.width = 0
  _o.height = 0
  _o.validate_function = _validate_function
  _o.last_frame_validated = 0

  function _o:draw(_x, _y, _selected)
    local _color = text_image_default_color
    if _selected then
      _color = text_image_selected_color

      if self.last_frame_validated > frame_number then
        self.last_frame_validated = 0
      end

      if (frame_number - self.last_frame_validated < 5 ) then
        _color = button_activated_color
      end
    end

    render_text(_x, _y, self.name, nil, nil, _color)
  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions(self.name)
  end

  function _o:validate()
    self.last_frame_validated = frame_number
    if self.validate_function then
      self.validate_function()
    end
  end

  function _o:legend()
    return "legend_lp_select"
  end

  _o:calc_dimensions()

  return _o
end

-- # Menus
menu_stack = {}

function menu_stack_push(_menu)
  table.insert(menu_stack, _menu)
end

function menu_stack_pop(_menu)
  for _i, _m in ipairs(menu_stack) do
    if _m == _menu then
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
  local _last_menu = menu_stack[#menu_stack]
  _last_menu:update(_input)
end

function menu_stack_draw()
  for _i, _menu in ipairs(menu_stack) do
    _menu:draw()
  end
end

function update_dimensions()
  for _i, _menu in ipairs(menu_stack) do
    _menu:calc_dimensions()
  end
end

function make_multitab_menu(_left, _top, _right, _bottom, _content, _on_toggle_entry, _additional_draw)
  local _m = {}
  _m.left = _left
  _m.top = _top
  _m.right = _right
  _m.bottom = _bottom
  _m.content = _content

  _m.is_main_menu_selected = true
  _m.main_menu_selected_index = 1
  _m.sub_menu_selected_index = 1
  _m.max_entries = 15
  if lang_code[training_settings.language] == "jp" then
    _m.max_entries = 11
  end

  _m.on_toggle_entry = _on_toggle_entry
  _m.additional_draw = _additional_draw

  for i = 1, #_m.content do
    _m.content[i].topmost_entry = 1
  end


  function _m:update(_input)
    multitab_menu_update(self, _input)
  end

  function _m:calc_dimensions()
    for i = 1, #self.content do
      self.content[i].header:calc_dimensions()
      for j = 1, #self.content[i].entries do
        self.content[i].entries[j]:calc_dimensions()
      end
    end
  end

  function _m:draw()
    multitab_menu_draw(self)
  end

  function _m:current_entry()
    if self.is_main_menu_selected then
      return nil
    else
      return self.content[self.main_menu_selected_index].entries[self.sub_menu_selected_index]
    end
  end

  return _m
end

function multitab_menu_update(_menu, _input)

  _menu.max_entries = 15
  if lang_code[training_settings.language] == "jp" then
    _menu.max_entries = 11
  end

  function get_position_in_list(_entries, _index)
    local _pos = _index
    for i = 1, _index do
      if _entries[i].unselectable or _entries[i].inline or (_entries[i].is_disabled and _entries[i].is_disabled())then
        _pos = _pos - 1
      end
    end
    return _pos
  end

  function get_bottom_page_position(_entries)
    local _total = 0
    for i = #_entries, 1, -1 do
      if not (_entries[i].unselectable or _entries[i].inline or (_entries[i].is_disabled and _entries[i].is_disabled())) then
        _total = _total + 1
      end
      if _total >= _menu.max_entries then
        return i
      end
    end
    return 1
  end

  function last_visible_entry(_entries)
    for i = #_entries, 1, -1 do
      if not (_entries[i].unselectable or _entries[i].inline or (_entries[i].is_disabled and _entries[i].is_disabled())) then
        return i
      end
    end
    return 1
  end

  while _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].unselectable or
  (_menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled and
  _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled()) do
    _menu.sub_menu_selected_index = _menu.sub_menu_selected_index - 1
    if _menu.sub_menu_selected_index == 0 then
      _menu.is_main_menu_selected = true
      _menu.sub_menu_selected_index = 1
    end

    if get_position_in_list(_menu.content[_menu.main_menu_selected_index].entries, _menu.sub_menu_selected_index) < _menu.content[_menu.main_menu_selected_index].topmost_entry and not _menu.is_main_menu_selected then
      _menu.content[_menu.main_menu_selected_index].topmost_entry = math.min(_menu.sub_menu_selected_index, 1)
    end
  end

  if get_position_in_list(_menu.content[_menu.main_menu_selected_index].entries, _menu.sub_menu_selected_index) > _menu.content[_menu.main_menu_selected_index].topmost_entry + _menu.max_entries then
    _menu.content[_menu.main_menu_selected_index].topmost_entry = math.min(_menu.sub_menu_selected_index, get_bottom_page_position(_menu.content[_menu.main_menu_selected_index].entries))
  end

  if _input.down then
    repeat
      if _menu.is_main_menu_selected then
        _menu.is_main_menu_selected = false
        _menu.sub_menu_selected_index = _menu.content[_menu.main_menu_selected_index].topmost_entry
--         _menu.content[_menu.main_menu_selected_index].topmost_entry = 1
      else
        _menu.sub_menu_selected_index = _menu.sub_menu_selected_index + 1
        if _menu.sub_menu_selected_index > #_menu.content[_menu.main_menu_selected_index].entries then
          _menu.is_main_menu_selected = true
          _menu.sub_menu_selected_index = 1
        end
      end
      if get_position_in_list(_menu.content[_menu.main_menu_selected_index].entries, _menu.sub_menu_selected_index) > _menu.max_entries and not _menu.is_main_menu_selected then
        _menu.content[_menu.main_menu_selected_index].topmost_entry = math.min(_menu.sub_menu_selected_index, get_bottom_page_position(_menu.content[_menu.main_menu_selected_index].entries))
      end
    until (
      _menu.is_main_menu_selected or not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].unselectable and
      (_menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled == nil
      or not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled())
    )
  end

  if _input.up then
    repeat
      if _menu.is_main_menu_selected then
        _menu.is_main_menu_selected = false
        _menu.sub_menu_selected_index = #_menu.content[_menu.main_menu_selected_index].entries
        _menu.content[_menu.main_menu_selected_index].topmost_entry = get_bottom_page_position(_menu.content[_menu.main_menu_selected_index].entries)
      else
        _menu.sub_menu_selected_index = _menu.sub_menu_selected_index - 1
        if _menu.sub_menu_selected_index == 0 then
          _menu.is_main_menu_selected = true
          _menu.sub_menu_selected_index = 1
        end
      end
      if get_position_in_list(_menu.content[_menu.main_menu_selected_index].entries, _menu.sub_menu_selected_index) < _menu.content[_menu.main_menu_selected_index].topmost_entry and not _menu.is_main_menu_selected then
        _menu.content[_menu.main_menu_selected_index].topmost_entry = math.min(_menu.sub_menu_selected_index, 1)
      end
    until (
      _menu.is_main_menu_selected or not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].unselectable and
      (_menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled == nil
      or not _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].is_disabled())
    )
  end

  local _current_entry = _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index]

  if _input.left then
    if _menu.is_main_menu_selected then
      _menu.main_menu_selected_index = _menu.main_menu_selected_index - 1
      if _menu.main_menu_selected_index == 0 then
        _menu.main_menu_selected_index = #_menu.content
      end
    elseif _current_entry ~= nil then
      if _current_entry.left ~= nil then
        _current_entry:left()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.right then
    if _menu.is_main_menu_selected then
      _menu.main_menu_selected_index = _menu.main_menu_selected_index + 1
      if _menu.main_menu_selected_index > #_menu.content then
        _menu.main_menu_selected_index = 1
      end
    elseif _current_entry ~= nil then
      if _current_entry.right ~= nil then
        _current_entry:right()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.validate then
    if is_main_menu_selected then
    elseif _current_entry ~= nil then
      if _current_entry.validate then
        _current_entry:validate()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.reset then
    if is_main_menu_selected then
    elseif _current_entry ~= nil then
      if _current_entry.reset then
        _current_entry:reset()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.cancel then
    if is_main_menu_selected then
    elseif _current_entry ~= nil then
      if _current_entry.cancel then
        _current_entry:cancel()
        if _menu.on_toggle_entry ~= nil then
          _menu.on_toggle_entry(_menu)
        end
      end
    end
  end

  if _input.scroll_up then
    local _total = 0
    local _entries = _menu.content[_menu.main_menu_selected_index].entries
    local _target = math.max(_menu.sub_menu_selected_index - _menu.max_entries, 1)
    for i = _target, 1, -1 do
      if not (_entries[i].unselectable or _entries[i].inline or (_entries[i].is_disabled and _entries[i].is_disabled())) then
        _total = _total + 1
      end
      _target = i
      if _total >= _menu.max_entries then
        break
      end
    end
    _menu.content[_menu.main_menu_selected_index].topmost_entry = _target
    if not _menu.is_main_menu_selected then
      if _menu.sub_menu_selected_index == 1 then
        _menu.is_main_menu_selected = true
      else
        _menu.sub_menu_selected_index = _target
      end
    end
  end

  if _input.scroll_down then
    local _total = 0
    local _entries = _menu.content[_menu.main_menu_selected_index].entries
    local _target = math.min(_menu.sub_menu_selected_index + _menu.max_entries, get_bottom_page_position(_entries))
    for i = _menu.main_menu_selected_index, _target do
      if not (_entries[i].unselectable or _entries[i].inline or (_entries[i].is_disabled and _entries[i].is_disabled())) then
        _total = _total + 1
      end
      _target = i
      if _total >= _menu.max_entries then
        break
      end
    end
    _menu.content[_menu.main_menu_selected_index].topmost_entry = _target
    if not _menu.is_main_menu_selected then
      if _menu.sub_menu_selected_index == last_visible_entry(_entries) then
        _menu.is_main_menu_selected = true
        _menu.sub_menu_selected_index = 1
      elseif _menu.sub_menu_selected_index >= get_bottom_page_position(_entries) then
        _menu.sub_menu_selected_index = last_visible_entry(_entries)
      else
        _menu.sub_menu_selected_index = _target
      end
    end
  end
end

function multitab_menu_draw(_menu)
  gui.box(_menu.left, _menu.top, _menu.right, _menu.bottom, gui_box_bg_color, gui_box_outline_color)

  local _base_offset = 0
  local _menu_width = _menu.right - _menu.left

  update_dimensions()

  local _total_item_width = 0
  for i=1, #_menu.content do
    _total_item_width = _total_item_width + _menu.content[i].header.width
  end

  local _offset = 0
  local _x_padding = 15
  local _y_padding = 5
  local _gap = (_menu_width - _total_item_width) / (#_menu.content + 1)
  local _menu_x = _menu.left + _x_padding
  local _menu_y = 0

  local _w, _h = get_text_dimensions("legend_hp_scroll")
  local _legend_y_padding = 3
  local _legend_y = _menu.bottom - (_h + _legend_y_padding * 2)

  for i = 1, #_menu.content do
    local _state = "disabled"
    if i == _menu.main_menu_selected_index then
      _state = "active"
      if _menu.is_main_menu_selected then
        _state = "selected"
      end
    end
    _menu.content[i].header:draw(_menu.left + _gap + _offset, _menu.top + _y_padding, _state)
    _offset = _offset + _menu.content[i].header.width + _gap
    _menu_y = _menu.top + _y_padding * 2 + _menu.content[i].header.height
  end
  for _pad = 15, 35 do
    gui.drawline(_menu.left + _pad, _menu_y - 1, _menu.right - _pad, _menu_y - 1, 0xFFFFFF0F)
  end


  _menu_y = _menu_y + 4

  local scroll_down = false
  local menu_item_spacing = 2
  if lang_code[training_settings.language] == "jp" then
    menu_item_spacing = 1
  end
  local _y_offset = 0
  local _is_focused = _menu == menu_stack_top()
  for i = 1, #_menu.content[_menu.main_menu_selected_index].entries do
--   print(_menu.content[_menu.main_menu_selected_index].entries[i].name)
    if i >= _menu.content[_menu.main_menu_selected_index].topmost_entry and (_menu.content[_menu.main_menu_selected_index].entries[i].is_disabled == nil or not _menu.content[_menu.main_menu_selected_index].entries[i].is_disabled()) then
      if _menu.content[_menu.main_menu_selected_index].entries[i].inline and (i - 1) >= 1 then
        local _x_offset = _menu.content[_menu.main_menu_selected_index].entries[i - 1].width + 8
        if lang_code[training_settings.language] == "jp" then
          _x_offset = _x_offset + 2
        end
        local _y_adj = -1 * (_menu.content[_menu.main_menu_selected_index].entries[i - 1].height + menu_item_spacing)
        _menu.content[_menu.main_menu_selected_index].entries[i]:draw(_menu_x + _x_offset, _menu_y + _y_offset + _y_adj, not _menu.is_main_menu_selected and _is_focused and _menu.sub_menu_selected_index == i)
      else
        if _menu_y + _y_offset + 5 >= _legend_y then
          scroll_down = true
        else
          _menu.content[_menu.main_menu_selected_index].entries[i]:draw(_menu_x, _menu_y + _y_offset, not _menu.is_main_menu_selected and _is_focused and _menu.sub_menu_selected_index == i)
          _y_offset = _y_offset + _menu.content[_menu.main_menu_selected_index].entries[i].height + menu_item_spacing
        end
      end
    end
  end

  if not _menu.is_main_menu_selected then
    if _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index].legend then
      local _color = text_image_disabled_color
      render_text(_menu_x, _legend_y + _legend_y_padding, _menu.content[_menu.main_menu_selected_index].entries[_menu.sub_menu_selected_index]:legend(), nil, nil, text_image_disabled_color)
    end
  end

  local scroll_up = _menu.content[_menu.main_menu_selected_index].topmost_entry > 1
  if scroll_down or scroll_up then
    render_text(_menu.right - _w - _x_padding, _legend_y + _legend_y_padding, "legend_hp_scroll", nil, nil, text_image_disabled_color)

    local _scroll_arrow_y_pos =  _menu_y + (_y_offset - menu_item_spacing - _h) + _h / 2 - 2
    if lang_code[training_settings.language] == "jp" then
      _scroll_arrow_y_pos = _menu_y + (_y_offset - menu_item_spacing - _h) + _h / 2 - 1
    end
    if scroll_up then
      gui.image(_menu.left + _x_padding / 2 - 2, _menu_y + _h / 2 - 2, scroll_up_arrow)
    end
    if scroll_down then
      gui.image(_menu.left + _x_padding / 2 - 2, _scroll_arrow_y_pos, scroll_down_arrow)
    end
  end

  if _menu.additional_draw ~= nil then
    _menu.additional_draw(_menu)
  end

end

function make_menu(_left, _top, _right, _bottom, _content, _on_toggle_entry, _draw_legend)
  local _m = {}
  _m.left = _left
  _m.top = _top
  _m.right = _right
  _m.bottom = _bottom
  _m.content = _content

  _m.selected_index = 1
  _m.on_toggle_entry = _on_toggle_entry
  if _draw_legend ~= nil then
    _m.draw_legend = _draw_legend
  else
    _m.draw_legend = true
  end

  function _m:update(_input)
    menu_update(self, _input)
  end

  function _m:draw()
    menu_draw(self)
  end

  function _m:current_entry()
    return self.content[self.selected_index]
  end

  function _m:calc_dimensions()
    for i = 1, #self.content do
      self.content[i]:calc_dimensions()
    end
  end

  return _m
end

function menu_update(_menu, _input)

  if _input.up then
    if _menu.content[_menu.selected_index].is_in_edition then
      _menu.content[_menu.selected_index]:up()
    else
      repeat
      _menu.selected_index = _menu.selected_index - 1
      if _menu.selected_index == 0 then
        _menu.selected_index = #_menu.content
      end
      until _menu.content[_menu.selected_index].is_disabled == nil or not _menu.content[_menu.selected_index].is_disabled()
    end
  end

  if _input.down then
    if _menu.content[_menu.selected_index].is_in_edition then
      _menu.content[_menu.selected_index]:down()
    else
      repeat
        _menu.selected_index = _menu.selected_index + 1
        if _menu.selected_index == #_menu.content + 1 then
          _menu.selected_index = 1
        end
      until _menu.content[_menu.selected_index].is_disabled == nil or not _menu.content[_menu.selected_index].is_disabled()
    end
  end

  _current_entry = _menu.content[_menu.selected_index]

  if _input.left then
    if _current_entry.left then
      _current_entry:left()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.right then
    if _current_entry.right then
      _current_entry:right()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.validate then
    if _current_entry.validate then
      _current_entry:validate()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.reset then
    if _current_entry.reset then
      _current_entry:reset()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end

  if _input.cancel then
    if _current_entry.cancel then
      _current_entry:cancel()
      if _menu.on_toggle_entry ~= nil then
        _menu.on_toggle_entry(_menu)
      end
    end
  end
end

function menu_draw(_menu)
  gui.box(_menu.left, _menu.top, _menu.right, _menu.bottom, gui_box_bg_color, gui_box_outline_color)

  local _menu_x = _menu.left + 10
  local _menu_y = _menu.top + 9
  local _draw_index = 0

  menu_item_spacing = 1

  for i = 1, #_menu.content do
    if _menu.content[i].is_disabled == nil or not _menu.content[i].is_disabled() then
      _menu.content[i]:draw(_menu_x, _menu_y + menu_item_spacing * _draw_index, _menu.selected_index == i)
      _draw_index = _draw_index + 1
    end
  end

  if _menu.draw_legend then
    if _menu.content[_menu.selected_index].legend then
      render_text(_menu_x, _menu.bottom - 12, _menu.content[_menu.selected_index]:legend(), nil, nil, text_image_disabled_color)
    end
  end
end
