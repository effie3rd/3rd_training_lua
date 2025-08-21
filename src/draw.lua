require "gd"
local gamestate = require("src/gamestate")
local text = require("src/text")

local render_text, get_text_dimensions = text.render_text, text.get_text_dimensions
local character_select = require("src/character_select")

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
  local name = controller_styles[i]
  img_button_small[name] = {}
  table.insert(img_button_small[name], gd.createFromPng("images/controller/LP_s_" .. name  .. ".png"):gdStr())
  table.insert(img_button_small[name], gd.createFromPng("images/controller/MP_s_" .. name  .. ".png"):gdStr())
  table.insert(img_button_small[name], gd.createFromPng("images/controller/HP_s_" .. name  .. ".png"):gdStr())
  table.insert(img_button_small[name], gd.createFromPng("images/controller/LK_s_" .. name  .. ".png"):gdStr())
  table.insert(img_button_small[name], gd.createFromPng("images/controller/MK_s_" .. name  .. ".png"):gdStr())
  table.insert(img_button_small[name], gd.createFromPng("images/controller/HK_s_" .. name  .. ".png"):gdStr())
  img_button_big[name] = {}
  table.insert(img_button_big[name], gd.createFromPng("images/controller/LP_b_" .. name  .. ".png"):gdStr())
  table.insert(img_button_big[name], gd.createFromPng("images/controller/MP_b_" .. name  .. ".png"):gdStr())
  table.insert(img_button_big[name], gd.createFromPng("images/controller/HP_b_" .. name  .. ".png"):gdStr())
  table.insert(img_button_big[name], gd.createFromPng("images/controller/LK_b_" .. name  .. ".png"):gdStr())
  table.insert(img_button_big[name], gd.createFromPng("images/controller/MK_b_" .. name  .. ".png"):gdStr())
  table.insert(img_button_big[name], gd.createFromPng("images/controller/HK_b_" .. name  .. ".png"):gdStr())
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

for _,char in pairs(characters) do
  chibi_characters[char] = {}
  chibi_characters[char].image = gd.createFromPng("images/characters/chibi_" .. char ..".png")
  chibi_characters[char].width = chibi_characters[char].image:sizeX()
  chibi_characters[char].height = chibi_characters[char].image:sizeY()
  chibi_characters[char].image = chibi_characters[char].image:gdStr()
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
function game_to_screen_space_x(x)
  return x - screen_x + emu.screenwidth()/2
end
function game_to_screen_space_y(y)
  return emu.screenheight() - (y - screen_y) - ground_offset
end
function game_to_screen_space(x, y)
  return game_to_screen_space_x(x), game_to_screen_space_y(y)
end


function get_text_width(text)
  if #text == 0 then
    return 0
  end

  return #text * 4
end

-- # Draw functions

-- draws a set of hitboxes

local color_vuln = 0x0000FFFF
local color_attack = 0xFF0000FF
local color_throwable = 0x00FF00FF
local color_throw = 0xFFFF00FF
local color_push = 0xFF00FFFF
local color_extvuln = 0x00FFFFFF

function draw_hitboxes(pos_x, pos_y, flip_x, boxes, filter, dilation, color, opacity)
  dilation = dilation or 0
  local px, py = game_to_screen_space(pos_x, pos_y)

  for __, box in pairs(boxes) do
    box = format_box(box)
    if filter == nil or filter[box.type] == true then
      --vulnerability
      local c = color_vuln
      if (box.type == "attack") then
        c = color_attack
      elseif (box.type == "throwable") then
        c = color_throwable
      elseif (box.type == "throw") then
        c = color_throw
      elseif (box.type == "push") then
        c = color_push
      elseif (box.type == "ext. vulnerability") then
        c = color_extvuln
      end

      c = color or c

      if opacity then
        c = bit.band(c, 0xFFFFFF00) + opacity
      end

      local l, r
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

function draw_hitboxes_opacity(pos_x, pos_y, flip_x, boxes, filter, dilation, color, opacity)
  dilation = dilation or 0
  local px, py = game_to_screen_space(pos_x, pos_y)
  opacity = opacity or 0xFF
  for __, box in pairs(boxes) do
    box = format_box(box)
    if filter == nil or filter[box.type] == true then
      --vulnerability
      local c = tonumber(string.format("0x%06X%02X", 0x0000FF, opacity))
      if (box.type == "attack") then
        c = tonumber(string.format("0x%06X%02X", 0xFF0000, opacity))
      elseif (box.type == "throwable") then
        c = tonumber(string.format("0x%06X%02X", 0x00FF00, opacity))
      elseif (box.type == "throw") then
        c = tonumber(string.format("0x%06X%02X", 0xFFFF00, opacity))
      elseif (box.type == "push") then
        c = tonumber(string.format("0x%06X%02X", 0xFF00FF, opacity))
      elseif (box.type == "ext. vulnerability") then
        c = tonumber(string.format("0x%06X%02X", 0x00FFFF, opacity))
      end

      c = color or c

      local l, r
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

-- draws a point
function draw_point(x, y, color)
  local cross_half_size = 4
  local l = x - cross_half_size
  local r = x + cross_half_size
  local t = y - cross_half_size
  local b = y + cross_half_size

  gui.box(l, y, r, y, 0x00000000, color)
  gui.box(x, t, x, b, 0x00000000, color)
end

-- draws a controller representation
function draw_controller_big(entry, x, y, style)
  gui.image(x, y, img_dir_big[entry.direction])

  local img_LP = img_no_button_big
  local img_MP = img_no_button_big
  local img_HP = img_no_button_big
  local img_LK = img_no_button_big
  local img_MK = img_no_button_big
  local img_HK = img_no_button_big
  if entry.buttons[1] then img_LP = img_button_big[style][1] end
  if entry.buttons[2] then img_MP = img_button_big[style][2] end
  if entry.buttons[3] then img_HP = img_button_big[style][3] end
  if entry.buttons[4] then img_LK = img_button_big[style][4] end
  if entry.buttons[5] then img_MK = img_button_big[style][5] end
  if entry.buttons[6] then img_HK = img_button_big[style][6] end

  gui.image(x + 13, y, img_LP)
  gui.image(x + 18, y, img_MP)
  gui.image(x + 23, y, img_HP)
  gui.image(x + 13, y + 5, img_LK)
  gui.image(x + 18, y + 5, img_MK)
  gui.image(x + 23, y + 5, img_HK)
end

function draw_buttons_preview_big(x, y, style)

  local img_LP = img_button_big[style][1]
  local img_MP = img_button_big[style][2]
  local img_HP = img_button_big[style][3]
  local img_LK = img_button_big[style][4]
  local img_MK = img_button_big[style][5]
  local img_HK = img_button_big[style][6]

  gui.image(x, y, img_LP)
  gui.image(x + 5, y, img_MP)
  gui.image(x + 10, y, img_HP)
  gui.image(x, y + 5, img_LK)
  gui.image(x + 5, y + 5, img_MK)
  gui.image(x + 10, y + 5, img_HK)
end

-- draws a controller representation
function draw_controller_small(entry, x, y, is_right, style)
  local x_offset = 0
  local sign = 1
  if is_right then
    x_offset = x_offset - 9
    sign = -1
  end

  gui.image(x + x_offset, y, img_dir_small[entry.direction])
  x_offset = x_offset + sign * 2


  local interval = 8
  x_offset = x_offset + sign * interval

  if entry.buttons[1] then
    gui.image(x + x_offset, y, img_button_small[style][1])
    x_offset = x_offset + sign * interval
  end

  if entry.buttons[2] then
    gui.image(x + x_offset, y, img_button_small[style][2])
    x_offset = x_offset + sign * interval
  end

  if entry.buttons[3] then
    gui.image(x + x_offset, y, img_button_small[style][3])
    x_offset = x_offset + sign * interval
  end

  if entry.buttons[4] then
    gui.image(x + x_offset, y, img_button_small[style][4])
    x_offset = x_offset + sign * interval
  end

  if entry.buttons[5] then
    gui.image(x + x_offset, y, img_button_small[style][5])
    x_offset = x_offset + sign * interval
  end

  if entry.buttons[6] then
    gui.image(x + x_offset, y, img_button_small[style][6])
    x_offset = x_offset + sign * interval
  end

end

-- draws a gauge
function draw_gauge(x, y, width, height, fill_ratio, fill_color, bg_color, border_color, reverse_fill)
  bg_color = bg_color or 0x00000000
  border_color = border_color or 0xFFFFFFFF
  reverse_fill = reverse_fill or false

  width = width + 1
  height = height + 1

  gui.box(x, y, x + width, y + height, bg_color, border_color)
  if reverse_fill then
    gui.box(x + width, y, x + width - width * clamp(fill_ratio, 0, 1), y + height, fill_color, 0x00000000)
  else
    gui.box(x, y, x + width * clamp(fill_ratio, 0, 1), y + height, fill_color, 0x00000000)
  end
end

-- draws an horizontal line
function draw_horizontal_line(x_start, x_end, y, color, thickness)
  thickness = thickness or 1.0
  local l = x_start - 1
  local b =  y + math.ceil(thickness * 0.5)
  local r = x_end + 1
  local t = y - math.floor(thickness * 0.5) - 1
  gui.box(l, b, r, t, color, 0x00000000)
end

-- draws a vertical line
function draw_vertical_line(x, y_start, y_end, color, thickness)
  thickness = thickness or 1.0
  local l = x - math.floor(thickness * 0.5) - 1
  local b =  y_end + 1
  local r = x + math.ceil(thickness * 0.5)
  local t = y_start - 1
  gui.box(l, b, r, t, color, 0x00000000)
end

local load_frame_data_bar_fade_time = 40
local load_frame_data_bar_fade_start = 0
local load_frame_data_bar_elapsed = 0
local load_frame_data_bar_fading = false

function loading_bar_display(loaded, total)
  if load_frame_data_bar_fading then
    load_frame_data_bar_elapsed = gamestate.frame_number - load_frame_data_bar_fade_start
    if load_frame_data_bar_fading and load_frame_data_bar_elapsed > load_frame_data_bar_fade_time then
      return
    end
  end

  local width = 60
  local height = 1
  local padding = 1
  local x = screen_width - width - padding
  local y = screen_height - height - padding
  local fill_color = 0xFFFFFFDD
  local opacity = 0xDD
  if load_frame_data_bar_fading then
    opacity = 0xDD * (1 - load_frame_data_bar_elapsed / load_frame_data_bar_fade_time)
    fill_color = tonumber(string.format("0xFFFFFF%02x", opacity))
  end
  draw_gauge(x, y, width, height, loaded / total, fill_color, 0x00000000, 0x00000000, false)
  if loaded >= total and not load_frame_data_bar_fading then
    load_frame_data_bar_fade_start = gamestate.frame_number
    load_frame_data_bar_fading = true
  end
end

local character_select_text_display_time = 120
local character_select_text_fade_time = 30
function draw_character_select()
  if character_select.p1_character_select_state <= 2 or character_select.p2_character_select_state <= 2 then
    local elapsed = gamestate.frame_number - character_select.character_select_start_frame
    if elapsed <= character_select_text_display_time + character_select_text_fade_time then
      local opacity = 1
      if elapsed > character_select_text_display_time then
        opacity = 1 - ((elapsed - character_select_text_display_time) / character_select_text_fade_time)
      end
      local w,h = get_text_dimensions("character_select_line_1")
      local padding_x = 0
      local padding_y = 0
      render_text(padding_x, padding_y, "character_select_line_1", nil, nil, nil, opacity)
      render_text(padding_x, padding_y + h, "character_select_line_2", nil, nil, nil, opacity)
      render_text(padding_x, padding_y + h + h, "character_select_line_3", nil, nil, nil, opacity)
    end
  end
end