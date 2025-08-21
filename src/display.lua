-- # enums
distance_display_mode =
{
  "none",
  "simple",
  "advanced",
}

distance_display_reference_point =
{
  "origin",
  "hurtbox",
}

-- # api

-- push a persistent set of hitboxes to be drawn on the screen each frame
function print_hitboxes(_pos_x, _pos_y, flip_x, boxes, filter, dilation)
  local _g = {
    type = "hitboxes",
    x = _pos_x,
    y = _pos_y,
    flip_x = flip_x,
    boxes = boxes,
    filter = filter,
    dilation = dilation
  }
  table.insert(printed_geometry, _g)
end

-- push a persistent point to be drawn on the screen each frame
function print_point(_pos_x, _pos_y, color)
  local _g = {
    type = "point",
    x = _pos_x,
    y = _pos_y,
    color = color
  }
  table.insert(printed_geometry, _g)
end

function clear_printed_geometry()
  printed_geometry = {}
end

-- # system
printed_geometry = {}

function display_draw_printed_geometry()
  -- printed geometry
  for _i, _geometry in ipairs(printed_geometry) do
    if _geometry.type == "hitboxes" then
      draw_hitboxes(_geometry.x, _geometry.y, _geometry.flip_x, _geometry.boxes, _geometry.filter, _geometry.dilation)
    elseif _geometry.type == "point" then
      draw_point(_geometry.x, _geometry.y, _geometry.color)
    end
  end
end


function display_draw_life(player_object)
  local x = 0
  local y = 20

  local _t = string.format("%d/160", player_object.life)

  if player_object.id == 1 then
    x = 13
  elseif player_object.id == 2 then
    x = screen_width - 11 - get_text_width(_t)
  end

  gui.text(x, y, _t, 0xFFFB63FF)
end


function display_draw_meter(player_object)
  local x = 0
  local y = 214

  local _gauge = player_object.meter_gauge

  if player_object.meter_count == player_object.max_meter_count then
    _gauge = player_object.max_meter_gauge
  end

  local _t = string.format("%d/%d", _gauge, player_object.max_meter_gauge)

  if player_object.id == 1 then
    x = 53
  elseif player_object.id == 2 then
    x = screen_width - 51 - get_text_width(_t)
  end

  gui.text(x, y, _t, 0x00FFCEFF, 0x001433FF)
end


function display_draw_stun_gauge(player_object)
  local x = 0
  local y = 28

  local _t = string.format("%d/%d", math.floor(player_object.stun_bar), player_object.stun_max)

  if player_object.id == 1 then
    x = 167 - player_object.stun_max + 3
  elseif player_object.id == 2 then
    x = 216 + player_object.stun_max - get_text_width(_t) - 1
  end

  gui.text(x, y, _t, 0xe60000FF, 0x001433FF)
end

function display_draw_bonuses(player_object)
  local x = 0
  local y = 4
  local _padding = 4
  local _spacing = 4
  local lang = lang_code[training_settings.language]
  if player_object.id == 1 then
    x = _padding
  elseif player_object.id == 2 then
    x = screen_width - _padding
  end
  if player_object.damage_bonus > 0 then
    -- gui.text(x, y, _t, 0xFF7184FF, 0x392031FF)
    local _text = {"+", player_object.damage_bonus, "bonus_damage"}
    local _w, h = 0, 0
    if _lang == "en" then
      _w, h = get_text_dimensions_multiple(_text)
    elseif _lang == "jp" then
      _w, h = get_text_dimensions_multiple(_text, "jp", "8")
    end
    if player_object.id == 2 then
      x = x - _w - _spacing
    end
    if _lang == "en" then
      render_text_multiple(x, y, _text, "en", nil, 0xFF7184FF)
    elseif _lang == "jp" then
      render_text_multiple(x, y, _text, "jp", "8", 0xFF7184FF)
    end
    if player_object.id == 1 then
      x = x + _w + _spacing
    end
  end

  if player_object.defense_bonus > 0 then
    local _text = {"+", player_object.defense_bonus, "bonus_defense"}
    local _w, h = 0, 0
    if _lang == "en" then
      _w, h = get_text_dimensions_multiple(_text)
    elseif _lang == "jp" then
      _w, h = get_text_dimensions_multiple(_text, "jp", "8")
    end
    if player_object.id == 2 then
      x = x - _w - _spacing
    end
    if _lang == "en" then
      render_text_multiple(x, y, _text, "en", nil, 0xD6E3EFFF)
    elseif _lang == "jp" then
      render_text_multiple(x, y, _text, "jp", "8", 0xD6E3EFFF)
    end
    if player_object.id == 1 then
      x = x + _w + _spacing
    end  
  end

  if player_object.stun_bonus > 0 then
    local _text = {"+", player_object.stun_bonus, "bonus_stun"}
    local _w, h = 0, 0
    if _lang == "en" then
      _w, h = get_text_dimensions_multiple(_text)
    elseif _lang == "jp" then
      _w, h = get_text_dimensions_multiple(_text, "jp", "8")
    end
    if player_object.id == 2 then
      x = x - _w - _spacing
    end
    if _lang == "en" then
      render_text_multiple(x, y, _text, "en", nil, 0xD6E3EFFF)
    elseif _lang == "jp" then
      render_text_multiple(x, y, _text, "jp", "8", 0xD6E3EFFF)
    end
    if player_object.id == 1 then
      x = x + _w + _spacing
    end
  end

end

function draw_horizontal_text_segment(p1_x, p2_x, y, _text, line_color, edges_height)

  edges_height = edges_height or 3
  local _half_distance_str_width = get_text_width(_text) * 0.5

  local center_x = (p1_x + p2_x) * 0.5
  draw_horizontal_line(math.min(p1_x, p2_x), center_x - _half_distance_str_width - 3, y, line_color, 1)
  draw_horizontal_line(center_x + _half_distance_str_width + 3, math.max(p1_x, p2_x), y, line_color, 1)
  gui.text(center_x - _half_distance_str_width, y - 3, _text, text_default_color, text_default_border_color)

  if edges_height > 0 then
    draw_vertical_line(p1_x, y - edges_height, y + edges_height, line_color, 1)
    draw_vertical_line(p2_x, y - edges_height, y + edges_height, line_color, 1)
  end
end  

function display_draw_distances(p1_object, p2_object, mid_distance_height, p1_reference_point, p2_reference_point)

  function find_closest_box_at_height(player_obj, _height, box_types)

    local _px = player_obj.pos_x
    local _py = player_obj.pos_y

    local left, _right = _px, _px

    if box_types == nil then
      return false, left, _right
    end

    local _has_boxes = false
    for __, box in ipairs(player_obj.boxes) do
      box = format_box(box)
      if box_types[box.type] then
        local l, _r
        if player_obj.flip_x == 0 then
          l = _px + box.left
        else
          l = _px - box.left - box.width
        end
        local _r = l + box.width
        local b = _py + box.bottom
        local _t = b + box.height

        if _height >= b and _height <= _t then
          _has_boxes = true
          left = math.min(left, l)
          _right = math.max(_right, _r)
        end
      end
    end

    return _has_boxes, left, _right
  end

  function _get_screen_line_between_boxes(box1_l, box1_r, box2_l, box2_r)
    if not (
      (box1_l >= box2_r) or
      (box1_r <= box2_l)
    ) then
      return false
    end

    if box1_l < box2_l then
      return true, game_to_screen_space_x(box1_r), game_to_screen_space_x(box2_l)
    else
      return true, game_to_screen_space_x(box2_r), game_to_screen_space_x(box1_l)
    end
  end

  function display_distance(p1_object, p2_object, _height, box_types, p1_reference_point, p2_reference_point, color)
    local y = math.min(p1_object.pos_y + _height, p2_object.pos_y + _height)
    local p1_l, p1_r, p2_l, p2_r
    local p1_result, p2_result = false, false
    if p1_reference_point == 2 then
      p1_result, p1_l, p1_r = find_closest_box_at_height(p1_object, y, box_types)
    end
    if not p1_result then
      p1_l, p1_r = p1_object.pos_x, p1_object.pos_x
    end
    if p2_reference_point == 2 then
      p2_result, p2_l, p2_r = find_closest_box_at_height(p2_object, y, box_types)
    end 
    if not p2_result then
      p2_l, p2_r = p2_object.pos_x, p2_object.pos_x
    end

    local line_result, _screen_l, _screen_r = _get_screen_line_between_boxes(p1_l, p1_r, p2_l, p2_r)

    if line_result then
      local _screen_y = game_to_screen_space_y(y)
      local _str = string.format("%d", math.abs(_screen_r - _screen_l))
      draw_horizontal_text_segment(_screen_l, _screen_r, _screen_y, _str, color)
    end
  end

  -- throw
  display_distance(p1_object, p2_object, 2, { throwable = true }, p1_reference_point, p2_reference_point, 0x08CF00FF)

  -- low and mid
  local _hurtbox_types = {}
  _hurtbox_types["vulnerability"] = true
  _hurtbox_types["ext. vulnerability"] = true
  display_distance(p1_object, p2_object, 10, _hurtbox_types, p1_reference_point, p2_reference_point, 0x00E7FFFF)
  display_distance(p1_object, p2_object, mid_distance_height, _hurtbox_types, p1_reference_point, p2_reference_point, 0x00E7FFFF)

  -- player positions
  local line_color = 0xFFFF63FF
  local p1_screen_x, p1_screen_y = game_to_screen_space(p1_object.pos_x, p1_object.pos_y)
  local p2_screen_x, p2_screen_y = game_to_screen_space(p2_object.pos_x, p2_object.pos_y)
  draw_point(p1_screen_x, p1_screen_y, line_color)
  draw_point(p2_screen_x, p2_screen_y, line_color)
  gui.text(p1_screen_x + 3, p1_screen_y + 2, string.format("%d:%d", p1_object.pos_x, p1_object.pos_y), text_default_color, text_default_border_color)
  gui.text(p2_screen_x + 3, p2_screen_y + 2, string.format("%d:%d", p2_object.pos_x, p2_object.pos_y), text_default_color, text_default_border_color)
end
