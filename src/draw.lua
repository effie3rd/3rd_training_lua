require "gd"

-- # Constants
screen_width = 383
screen_height = 223
ground_offset = 23

-- # Global variables
screen_x = 0
screen_y = 0
scale = 1

-- # Images

scroll_up_arrow = gd.createFromPng("images/menu/scroll_up.png"):gdStr()
scroll_down_arrow = gd.createFromPng("images/menu/scroll_down.png"):gdStr()

img_1_dir_big = gd.createFromPng("images/controller/1_dir_b.png"):gdStr()
img_2_dir_big = gd.createFromPng("images/controller/2_dir_b.png"):gdStr()
img_3_dir_big = gd.createFromPng("images/controller/3_dir_b.png"):gdStr()
img_4_dir_big = gd.createFromPng("images/controller/4_dir_b.png"):gdStr()
img_5_dir_big = gd.createFromPng("images/controller/5_dir_b.png"):gdStr()
img_6_dir_big = gd.createFromPng("images/controller/6_dir_b.png"):gdStr()
img_7_dir_big = gd.createFromPng("images/controller/7_dir_b.png"):gdStr()
img_8_dir_big = gd.createFromPng("images/controller/8_dir_b.png"):gdStr()
img_9_dir_big = gd.createFromPng("images/controller/9_dir_b.png"):gdStr()
img_no_button_big = gd.createFromPng("images/controller/no_button_b.png"):gdStr()


img_dir_big = {
  img_1_dir_big,
  img_2_dir_big,
  img_3_dir_big,
  img_4_dir_big,
  img_5_dir_big,
  img_6_dir_big,
  img_7_dir_big,
  img_8_dir_big,
  img_9_dir_big
}

img_1_dir_small = gd.createFromPng("images/controller/1_dir_s.png"):gdStr()
img_2_dir_small = gd.createFromPng("images/controller/2_dir_s.png"):gdStr()
img_3_dir_small = gd.createFromPng("images/controller/3_dir_s.png"):gdStr()
img_4_dir_small = gd.createFromPng("images/controller/4_dir_s.png"):gdStr()
img_5_dir_small = gd.createFromPng("images/controller/5_dir_s.png"):gdStr()
img_6_dir_small = gd.createFromPng("images/controller/6_dir_s.png"):gdStr()
img_7_dir_small = gd.createFromPng("images/controller/7_dir_s.png"):gdStr()
img_8_dir_small = gd.createFromPng("images/controller/8_dir_s.png"):gdStr()
img_9_dir_small = gd.createFromPng("images/controller/9_dir_s.png"):gdStr()

img_dir_small = {
  img_1_dir_small,
  img_2_dir_small,
  img_3_dir_small,
  img_4_dir_small,
  img_5_dir_small,
  img_6_dir_small,
  img_7_dir_small,
  img_8_dir_small,
  img_9_dir_small
}
controller_styles = {'default', 'rose', 'cherry', 'blueberry', 'sky', 'blood_orange', 'salmon', 'grape', 'lavender', 'lemon', 'champagne', 'matcha', 'mint', 'retro_scifi', 'watermelon', 'macaron', 'famicom', 'van_gogh', 'munch', 'hokusai', 'monet', 'dali', 'cyberpunk', '2077', 'aurora', 'ursa_major', 'crab_nebula', 'pillars_of_creation', 'sunset', 'fly_by_night', 'lake', 'airplane', 'warm_rainbow', 'soft_rainbow', 'pearl', 'beach', 'nether', 'blue_planet', 'poison', 'moon', 'blood_moon', 'volcano', 'desert_sun', 'canyon', 'redgreen', 'acid', 'dawn', 'picnic', 'gelato', 'patrick', '01'}
img_button_small = {}
img_button_big = {}
for i = 1, #controller_styles do
  local _name = controller_styles[i]
  img_button_small[_name] = {}
  table.insert(img_button_small[_name], gd.createFromPng("images/controller/LP_s_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_small[_name], gd.createFromPng("images/controller/MP_s_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_small[_name], gd.createFromPng("images/controller/HP_s_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_small[_name], gd.createFromPng("images/controller/LK_s_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_small[_name], gd.createFromPng("images/controller/MK_s_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_small[_name], gd.createFromPng("images/controller/HK_s_" .. _name  .. ".png"):gdStr())
  img_button_big[_name] = {}
  table.insert(img_button_big[_name], gd.createFromPng("images/controller/LP_b_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_big[_name], gd.createFromPng("images/controller/MP_b_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_big[_name], gd.createFromPng("images/controller/HP_b_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_big[_name], gd.createFromPng("images/controller/LK_b_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_big[_name], gd.createFromPng("images/controller/MK_b_" .. _name  .. ".png"):gdStr())
  table.insert(img_button_big[_name], gd.createFromPng("images/controller/HK_b_" .. _name  .. ".png"):gdStr())
end


img_hold = gd.createFromPng("images/controller/hold_s.png"):gdStr()
img_maru = gd.createFromPng("images/controller/maru_s.png"):gdStr()
img_tilda = gd.createFromPng("images/controller/tilda_s.png"):gdStr()

local characters =
{
  "alex",
  "ryu",
  "yun",
  "dudley",
  "necro",
  "hugo",
  "ibuki",
  "elena",
  "oro",
  "yang",
  "ken",
  "sean",
  "urien",
  "gouki",
  "gill",
  "chunli",
  "makoto",
  "q",
  "twelve",
  "remy"
}
chibi_characters = {}

for _,_char in pairs(characters) do
  chibi_characters[_char] = {}
  chibi_characters[_char].image = gd.createFromPng("images/characters/chibi_" .. _char ..".png")
  chibi_characters[_char].width = chibi_characters[_char].image:sizeX()
  chibi_characters[_char].height = chibi_characters[_char].image:sizeY()
  chibi_characters[_char].image = chibi_characters[_char].image:gdStr()
end


-- # System

function draw_read()
  -- screen stuff
  screen_x = memory.readwordsigned(0x02026CB0)
  screen_y = memory.readwordsigned(0x02026CB4)
  scale = memory.readwordsigned(0x0200DCBA) --FBA can't read from 04xxxxxx
  scale = 0x40/(scale > 0 and scale or 1)
end

-- # Tools
function game_to_screen_space_x(_x)
  return _x - screen_x + emu.screenwidth()/2
end
function game_to_screen_space_y(_y)
  return emu.screenheight() - (_y - screen_y) - ground_offset
end
function game_to_screen_space(_x, _y)
  return game_to_screen_space_x(_x), game_to_screen_space_y(_y)
end


function get_text_width(_text)
  if #_text == 0 then
    return 0
  end

  return #_text * 4
end

-- # Draw functions

-- draws a set of hitboxes

local color_vuln = 0x0000FFFF
local color_attack = 0xFF0000FF
local color_throwable = 0x00FF00FF
local color_throw = 0xFFFF00FF
local color_push = 0xFF00FFFF
local color_extvuln = 0x00FFFFFF

function draw_hitboxes(_pos_x, _pos_y, _flip_x, _boxes, _filter, _dilation, _color, _opacity)
  _dilation = _dilation or 0
  local _px, _py = game_to_screen_space(_pos_x, _pos_y)

  for __, _box in pairs(_boxes) do
    _box = format_box(_box)
    if _filter == nil or _filter[_box.type] == true then
      --vulnerability
      local _c = color_vuln
      if (_box.type == "attack") then
        _c = color_attack
      elseif (_box.type == "throwable") then
        _c = color_throwable
      elseif (_box.type == "throw") then
        _c = color_throw
      elseif (_box.type == "push") then
        _c = color_push
      elseif (_box.type == "ext. vulnerability") then
        _c = color_extvuln
      end

      _c = _color or _c

      if _opacity then
        _c = bit.band(_c, 0xFFFFFF00) + _opacity
      end

      local _l, _r
      if _flip_x == 0 then
        _l = _px + _box.left
      else
        _l = _px - _box.left - _box.width
      end
      local _r = _l + _box.width
      local _b = _py - _box.bottom
      local _t = _b - _box.height

      _l = _l - _dilation
      _r = _r + _dilation
      _b = _b + _dilation
      _t = _t - _dilation

      gui.box(_l, _b, _r, _t, 0x00000000, _c)
    end
  end
end

function draw_hitboxes_opacity(_pos_x, _pos_y, _flip_x, _boxes, _filter, _dilation, _color, _opacity)
  _dilation = _dilation or 0
  local _px, _py = game_to_screen_space(_pos_x, _pos_y)
  _opacity = _opacity or 0xFF
  for __, _box in pairs(_boxes) do
    _box = format_box(_box)
    if _filter == nil or _filter[_box.type] == true then
      --vulnerability
      local _c = tonumber(string.format("0x%06X%02X", 0x0000FF, _opacity))
      if (_box.type == "attack") then
        _c = tonumber(string.format("0x%06X%02X", 0xFF0000, _opacity))
      elseif (_box.type == "throwable") then
        _c = tonumber(string.format("0x%06X%02X", 0x00FF00, _opacity))
      elseif (_box.type == "throw") then
        _c = tonumber(string.format("0x%06X%02X", 0xFFFF00, _opacity))
      elseif (_box.type == "push") then
        _c = tonumber(string.format("0x%06X%02X", 0xFF00FF, _opacity))
      elseif (_box.type == "ext. vulnerability") then
        _c = tonumber(string.format("0x%06X%02X", 0x00FFFF, _opacity))
      end

      _c = _color or _c

      local _l, _r
      if _flip_x == 0 then
        _l = _px + _box.left
      else
        _l = _px - _box.left - _box.width
      end
      local _r = _l + _box.width
      local _b = _py - _box.bottom
      local _t = _b - _box.height

      _l = _l - _dilation
      _r = _r + _dilation
      _b = _b + _dilation
      _t = _t - _dilation

      gui.box(_l, _b, _r, _t, 0x00000000, _c)
    end
  end
end

-- draws a point
function draw_point(_x, _y, _color)
  local _cross_half_size = 4
  local _l = _x - _cross_half_size
  local _r = _x + _cross_half_size
  local _t = _y - _cross_half_size
  local _b = _y + _cross_half_size

  gui.box(_l, _y, _r, _y, 0x00000000, _color)
  gui.box(_x, _t, _x, _b, 0x00000000, _color)
end

-- draws a controller representation
function draw_controller_big(_entry, _x, _y, _style)
  gui.image(_x, _y, img_dir_big[_entry.direction])

  local _img_LP = img_no_button_big
  local _img_MP = img_no_button_big
  local _img_HP = img_no_button_big
  local _img_LK = img_no_button_big
  local _img_MK = img_no_button_big
  local _img_HK = img_no_button_big
  if _entry.buttons[1] then _img_LP = img_button_big[_style][1] end
  if _entry.buttons[2] then _img_MP = img_button_big[_style][2] end
  if _entry.buttons[3] then _img_HP = img_button_big[_style][3] end
  if _entry.buttons[4] then _img_LK = img_button_big[_style][4] end
  if _entry.buttons[5] then _img_MK = img_button_big[_style][5] end
  if _entry.buttons[6] then _img_HK = img_button_big[_style][6] end

  gui.image(_x + 13, _y, _img_LP)
  gui.image(_x + 18, _y, _img_MP)
  gui.image(_x + 23, _y, _img_HP)
  gui.image(_x + 13, _y + 5, _img_LK)
  gui.image(_x + 18, _y + 5, _img_MK)
  gui.image(_x + 23, _y + 5, _img_HK)
end

function draw_buttons_preview_big(_x, _y, _style)

  local _img_LP = img_button_big[_style][1]
  local _img_MP = img_button_big[_style][2]
  local _img_HP = img_button_big[_style][3]
  local _img_LK = img_button_big[_style][4]
  local _img_MK = img_button_big[_style][5]
  local _img_HK = img_button_big[_style][6]

  gui.image(_x, _y, _img_LP)
  gui.image(_x + 5, _y, _img_MP)
  gui.image(_x + 10, _y, _img_HP)
  gui.image(_x, _y + 5, _img_LK)
  gui.image(_x + 5, _y + 5, _img_MK)
  gui.image(_x + 10, _y + 5, _img_HK)
end

-- draws a controller representation
function draw_controller_small(_entry, _x, _y, _is_right, _style)
  local _x_offset = 0
  local _sign = 1
  if _is_right then
    _x_offset = _x_offset - 9
    _sign = -1
  end

  gui.image(_x + _x_offset, _y, img_dir_small[_entry.direction])
  _x_offset = _x_offset + _sign * 2


  local _interval = 8
  _x_offset = _x_offset + _sign * _interval

  if _entry.buttons[1] then
    gui.image(_x + _x_offset, _y, img_button_small[_style][1])
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[2] then
    gui.image(_x + _x_offset, _y, img_button_small[_style][2])
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[3] then
    gui.image(_x + _x_offset, _y, img_button_small[_style][3])
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[4] then
    gui.image(_x + _x_offset, _y, img_button_small[_style][4])
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[5] then
    gui.image(_x + _x_offset, _y, img_button_small[_style][5])
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[6] then
    gui.image(_x + _x_offset, _y, img_button_small[_style][6])
    _x_offset = _x_offset + _sign * _interval
  end

end

-- draws a gauge
function draw_gauge(_x, _y, _width, _height, _fill_ratio, _fill_color, _bg_color, _border_color, _reverse_fill)
  _bg_color = _bg_color or 0x00000000
  _border_color = _border_color or 0xFFFFFFFF
  _reverse_fill = _reverse_fill or false

  _width = _width + 1
  _height = _height + 1

  gui.box(_x, _y, _x + _width, _y + _height, _bg_color, _border_color)
  if _reverse_fill then
    gui.box(_x + _width, _y, _x + _width - _width * clamp(_fill_ratio, 0, 1), _y + _height, _fill_color, 0x00000000)
  else
    gui.box(_x, _y, _x + _width * clamp(_fill_ratio, 0, 1), _y + _height, _fill_color, 0x00000000)
  end
end

-- draws an horizontal line
function draw_horizontal_line(_x_start, _x_end, _y, _color, _thickness)
  _thickness = _thickness or 1.0
  local _l = _x_start - 1
  local _b =  _y + math.ceil(_thickness * 0.5)
  local _r = _x_end + 1
  local _t = _y - math.floor(_thickness * 0.5) - 1
  gui.box(_l, _b, _r, _t, _color, 0x00000000)
end

-- draws a vertical line
function draw_vertical_line(_x, _y_start, _y_end, _color, _thickness)
  _thickness = _thickness or 1.0
  local _l = _x - math.floor(_thickness * 0.5) - 1
  local _b =  _y_end + 1
  local _r = _x + math.ceil(_thickness * 0.5)
  local _t = _y_start - 1
  gui.box(_l, _b, _r, _t, _color, 0x00000000)
end
