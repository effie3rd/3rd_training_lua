life_color = 0x00cd4cff
stun_color = 0xe60000ff
meter_color = 0x00e6f7ff


gauge_outline_color = 0x000000FF
gauge_background_color = 0x00000044
gauge_valid_fill_color = 0xc200c8FF --0x0073FFFF--0x009fffFF--0x1a4cffFF
gauge_cooldown_fill_color = 0x6800b5FF --0xFFA131FF


function parry_gauge_display(_player)
  local _x = 235 --96
  local _y = 40
  local _flip_gauge = false
  local _gauge_x_scale = 4

  if training_settings.charge_follow_character then
    local _px = _player.pos_x - screen_x + emu.screenwidth()/2
    local _py = emu.screenheight() - (_player.pos_y - screen_y) - ground_offset
    local _half_width = 23 * _gauge_x_scale * 0.5
    _x = _px - _half_width
    _x = math.max(_x, 4)
    _x = math.min(_x, emu.screenwidth() - (_half_width * 2.0 + 14))
    _y = _py - 100
  end

  local _y_offset = 0
  local _group_y_margin = 6

  function draw_parry_gauge_group(_x, _y, _parry_object)
    local _gauge_height = 4
    local _success_color = 0x10FB00FF
    local _miss_color = 0xE70000FF

    local _x_border = 8

    local _validity_gauge_width = _parry_object.max_validity * _gauge_x_scale
    local _cooldown_gauge_width = _parry_object.max_cooldown * _gauge_x_scale

    _x = math.min(math.max(_x, _x_border), screen_width - _x_border - _validity_gauge_width)

    local _validity_gauge_left = math.floor(_x + (_cooldown_gauge_width - _validity_gauge_width) * 0.5)
    local _validity_gauge_right = _validity_gauge_left + _validity_gauge_width + 1
    local _cooldown_gauge_left = _x
    local _cooldown_gauge_right = _cooldown_gauge_left + _cooldown_gauge_width + 1
    local _validity_time_text = string.format("%d", _parry_object.validity_time)
    local _cooldown_time_text = string.format("%d", _parry_object.cooldown_time)
    local _validity_text_color = "white"
    local _validity_outline_color = 0x00000077
    if _parry_object.delta then
      if _parry_object.success then
        _validity_text_color = color_green
        _validity_outline_color = 0x00A200FF
      else
        _validity_text_color = color_red
        _validity_outline_color = 0x840000FF
      end
      if _parry_object.delta >= 0 then
        _validity_time_text = string.format("%d", -_parry_object.delta)
      else
        _validity_time_text = string.format("+%d", -_parry_object.delta)
      end
    end

    local _str = "parry_" .. _parry_object.name

    render_text(_x + 1, _y, _str)
    gui.box(_cooldown_gauge_left + 1, _y + 11, _validity_gauge_left, _y + 11, 0x00000000, gauge_outline_color)
    gui.box(_cooldown_gauge_left, _y + 10, _cooldown_gauge_left, _y + 12, 0x00000000, gauge_outline_color)
    gui.box(_validity_gauge_right, _y + 11, _cooldown_gauge_right - 1, _y + 11, 0x00000000, gauge_outline_color)
    gui.box(_cooldown_gauge_right, _y + 10, _cooldown_gauge_right, _y + 12, 0x00000000, gauge_outline_color)
    draw_gauge(_validity_gauge_left, _y + 8, _validity_gauge_width, _gauge_height + 1, _parry_object.validity_time / _parry_object.max_validity, gauge_valid_fill_color, gauge_background_color, gauge_outline_color, true)
    draw_gauge(_cooldown_gauge_left, _y + 8 + _gauge_height + 2, _cooldown_gauge_width, _gauge_height, _parry_object.cooldown_time / _parry_object.max_cooldown, gauge_cooldown_fill_color, gauge_background_color, gauge_outline_color, true)

    gui.box(_validity_gauge_left + 3 * _gauge_x_scale, _y + 8, _validity_gauge_left + 2 + 3 * _gauge_x_scale,  _y + 8 + _gauge_height + 2, gauge_outline_color, 0x00000000)

    if _parry_object.delta then
      local _marker_x = _validity_gauge_left + _parry_object.delta * _gauge_x_scale
      _marker_x = math.min(math.max(_marker_x, _x), _cooldown_gauge_right)
      gui.box(_marker_x, _y + 7, _marker_x + _gauge_x_scale, _y + 8 + _gauge_height + 2, _validity_text_color, _validity_outline_color)
    end

    render_text(_cooldown_gauge_right + 4, _y + 7, _validity_time_text, "en", nil, _validity_text_color)
    render_text(_cooldown_gauge_right + 4, _y + 13, _cooldown_time_text, "en", nil, "white")

    return 8 + 5 + (_gauge_height * 2)
  end

  local _parry_array = {
    {
      object = _player.parry_forward,
      enabled = training_settings.special_training_parry_forward_on
    },
    {
      object = _player.parry_down,
      enabled = training_settings.special_training_parry_down_on
    },
    {
      object = _player.parry_air,
      enabled = training_settings.special_training_parry_air_on
    },
    {
      object = _player.parry_antiair,
      enabled = training_settings.special_training_parry_antiair_on
    }
  }

  for _i, _parry in ipairs(_parry_array) do

    if _parry.enabled then
      _y_offset = _y_offset + _group_y_margin + draw_parry_gauge_group(_x, _y + _y_offset, _parry.object)
    end
  end
end

function charge_display(_player)
    local _x = 272 --96
    if training_settings.special_training_charge_overcharge_on then
      _x = 264
    end
    local _y = 46
    local _flip_gauge = false
    local _gauge_x_scale = 2

    if training_settings.charge_follow_character then
      local _offset_x = 8

      _x,_y = game_to_screen_space(_player.pos_x, _player.pos_y + character_specific[_player.char_str].height)
      _x = _x + _offset_x
      if _player.flip_x == 1 then
        _x = _x - (43 * _gauge_x_scale + _offset_x + 16)
      end
      _y = _y
    end

    local _y_offset = 0
    local _x_offset = 0
    local _group_y_margin = 6
    local _group_x_margin = 12
    local _gauge_height = 3
    local _success_color = 0x10FB00FF
    local _miss_color = 0xE70000FF
    local _overcharge_color = 0x4900FF80
    local _x_border = 16

    function draw_charge_gauge_group(_x, _y, _charge_object)

      local _charge_gauge_width = _charge_object.max_charge * _gauge_x_scale
      local _reset_gauge_width = _charge_object.max_reset * _gauge_x_scale

      _x = math.min(math.max(_x, _x_border), screen_width - _x_border - _charge_gauge_width)

      local _charge_gauge_left = math.floor(_x + (_reset_gauge_width - _charge_gauge_width) * 0.5)
      local _charge_gauge_right = _charge_gauge_left + _charge_gauge_width + 1
      local _reset_gauge_left = _x
      local _reset_gauge_right = _reset_gauge_left + _reset_gauge_width + 1
      local _charge_time_text = string.format("%d", _charge_object.charge_time)
      local _reset_time_text = string.format("%d", _charge_object.reset_time)
      local _charge_text_color = text_image_default_color
      if _charge_object.max_charge - _charge_object.charge_time == _charge_object.max_charge then
        _charge_text_color = _success_color
      else
        _charge_text_color = color_red
      end

      _charge_time_text = string.format("%d", _charge_object.max_charge - _charge_object.charge_time)
      _overcharge_time_text = string.format("[%d]", _charge_object.overcharge)
      _last_overcharge_time_text = string.format("[%d]", _charge_object.last_overcharge)
      _reset_time_text = string.format("%d", _charge_object.reset_time)

      local _name_y_offset = 0
      if lang_code[training_settings.language] == "jp" then
        _name_y_offset = -1
      end
      render_text(_x + 1, _y + _name_y_offset, _charge_object.name)
--       gui.box(_reset_gauge_left + 1, _y + 11, _charge_gauge_left, _y + 11, 0x00000000, 0x00000077)
--       gui.box(_reset_gauge_left, _y + 10, _reset_gauge_left, _y + 12, 0x00000000, 0x00000077)
--       gui.box(_charge_gauge_right, _y + 11, _reset_gauge_right - 1, _y + 11, 0x00000000, 0x00000077)
--       gui.box(_reset_gauge_right, _y + 10, _reset_gauge_right, _y + 12, 0x00000000, 0x00000077)
      draw_gauge(_charge_gauge_left, _y + 8, _charge_gauge_width, _gauge_height + 1, _charge_object.charge_time / _charge_object.max_charge, gauge_valid_fill_color, gauge_background_color, gauge_outline_color, true)
      draw_gauge(_reset_gauge_left, _y + 8 + _gauge_height + 2, _reset_gauge_width, _gauge_height, _charge_object.reset_time / _charge_object.max_reset, gauge_cooldown_fill_color, gauge_background_color, gauge_outline_color, true)
      if training_settings.special_training_charge_overcharge_on and _charge_object.overcharge ~= 0 and _charge_object.overcharge < 42 then
        draw_gauge(_charge_gauge_left, _y + 8, _charge_gauge_width, _gauge_height + 1, _charge_object.overcharge / _charge_object.max_charge, _overcharge_color, gauge_background_color, gauge_outline_color, true)
        local _w = get_text_dimensions(_charge_time_text, "en")
        render_text(_reset_gauge_right + 4 + _w, _y + 7, _overcharge_time_text, "en", nil, _charge_text_color)
      end
      if training_settings.special_training_charge_overcharge_on and _charge_object.overcharge == 0 and _charge_object.last_overcharge > 0 and _charge_object.last_overcharge < 42 then
        local _w = get_text_dimensions(_charge_time_text, "en")
        render_text(_reset_gauge_right + 4 + _w, _y + 7, _last_overcharge_time_text, "en", nil, _charge_text_color)
      end

      render_text(_reset_gauge_right + 4, _y + 7, _charge_time_text, "en", nil, _charge_text_color)
      render_text(_reset_gauge_right + 4, _y + 13, _reset_time_text, "en", nil, "white")

      return 8 + 5 + (_gauge_height * 2)
    end

    function draw_kaiten_gauge_group(_x, _y, _kaiten_object)

      local _charge_gauge_width = 43 * _gauge_x_scale
      local _reset_gauge_width = 43 * _gauge_x_scale

      _x = math.min(math.max(_x, _x_border), screen_width - _x_border - _charge_gauge_width)

      local _charge_gauge_left = math.floor(_x + (_reset_gauge_width - _charge_gauge_width) * 0.5)
      local _charge_gauge_right = _charge_gauge_left + _charge_gauge_width + 1
      local _reset_gauge_left = _x
      local _reset_gauge_right = _reset_gauge_left + _reset_gauge_width + 1
      local _validity_time_text = ""
      if _kaiten_object.validity_time > 0 then
        _validity_time_text = string.format("%d", _kaiten_object.validity_time)
      end
      local _reset_time_text = string.format("%d", _kaiten_object.reset_time)
      local _charge_text_color = text_image_default_color

      local _name_y_offset = 0
      if lang_code[training_settings.language] == "jp" then
        _name_y_offset = -1
      end
      render_text(_x + 1, _y + _name_y_offset, _kaiten_object.name)

      draw_kaiten(_x, _y + 8, _kaiten_object.directions, not _player.flip_input)

      draw_gauge(_reset_gauge_left, _y + 8 + 9, _reset_gauge_width, _gauge_height, _kaiten_object.reset_time / _kaiten_object.max_reset, gauge_cooldown_fill_color, gauge_background_color, gauge_outline_color, true)

      render_text(_reset_gauge_right + 4, _y + 10, _validity_time_text, "en", nil, "white")
      render_text(_reset_gauge_right + 4, _y + 17, _reset_time_text, "en", nil, "white")

      return 8 + 5 + 9 + _gauge_height
    end


    function draw_legs_gauge_group(_x, _y, _legs_object)
      local _gauge_height = 3
      local _width = 43 * _gauge_x_scale
      local _style = controller_styles[training_settings.controller_style]
      local _tw, _th = get_text_dimensions("hyakuretsu_MK")
      local _margin = _tw + 1
      local _x_offset = _margin
      render_text(_x, _y, "hyakuretsu_LK")
      for _i = 1, _legs_object.l_legs_count do
        gui.image(_x + _x_offset, _y, img_button_small[_style][4])
        _x_offset = _x_offset + 8
      end
      _x_offset = _margin
      render_text(_x, _y + 8, "hyakuretsu_MK")
      for _i = 1, _legs_object.m_legs_count do
        gui.image(_x + _x_offset, _y + 8, img_button_small[_style][5])
        _x_offset = _x_offset + 8
      end
      _x_offset = _margin
      render_text(_x, _y + 16, "hyakuretsu_HK")
      for _i = 1, _legs_object.h_legs_count do
        gui.image(_x + _x_offset, _y + 16, img_button_small[_style][6])
        _x_offset = _x_offset + 8
      end
      _x_offset = _margin

      if _legs_object.active ~= 0xFF then
        draw_gauge(_x, _y + 24, _width, _gauge_height + 1, _legs_object.reset_time / 99, gauge_valid_fill_color, gauge_background_color, gauge_outline_color, true)
      end

      return 8 + 5 + (_gauge_height * 2)
    end

    local _charge_array = {
      {
        object = _player.charge_1,
        enabled = _player.charge_1.enabled
      },
      {
        object = _player.charge_2,
        enabled = _player.charge_2.enabled
      },
      {
        object = _player.charge_3,
        enabled = _player.charge_3.enabled
      }
    }

    for _i, _charge in ipairs(_charge_array) do
      if _charge.enabled then
        _y_offset = _y_offset + _group_y_margin + draw_charge_gauge_group(_x, _y + _y_offset, _charge.object)
      end
    end

    if _player.char_str == "hugo"
    or (_player.char_str == "alex" and _player.selected_sa == 1) then
      for _, _kaiten in ipairs(_player.kaiten) do
        if _kaiten.enabled then
          _y_offset = _y_offset + _group_y_margin + draw_kaiten_gauge_group(_x, _y + _y_offset, _kaiten)
        end
      end
    end

    if _player.legs_state.enabled then
      draw_legs_gauge_group(_x, _y + _y_offset, _player.legs_state)
    end


end

local player_default_color = 0x4200
function color_player(_player, _color)
  if _color == "default" then
    memory.writeword(_player.base + 616, player_default_color)
  else
    memory.writeword(_player.base + 616, _color)
  end
end

local _air_combo_expired_color = 0x2013
local _air_time_bar_max_width = 121
function air_time_display(_player, _dummy)
  local _player = P1
  local _dummy = P2
  local _offset_x = 225
  local _offset_y = 50
  local _juggle_count = memory.readbyte(0x020694C9)
  local _air_time = math.floor((memory.readbyte(0x020694C7) + 1) / 2)
  local _air_time_bar_width = math.round((_air_time / 121) * _air_time_bar_max_width)
  local _x, _y = get_text_dimensions(tostring(_juggle_count), "en")
  render_text(_offset_x - _x, _offset_y - 2, _juggle_count, "en", nil, "white")
  _offset_x = _offset_x + 4
  gui.drawbox(_offset_x, _offset_y, _offset_x + _air_time_bar_max_width, _offset_y + 3, gauge_background_color, 0x000000FF)
  if _air_time ~= 128 then --0x00C080FF
    gui.drawbox(_offset_x, _offset_y, _offset_x + _air_time_bar_width, _offset_y + 3, gauge_valid_fill_color, 0x00000000)
    if _air_time > 0 then
      _x, _y = get_text_dimensions(tostring(_air_time), "en")
      _offset_x = _offset_x - _x / 2
      render_text(_offset_x + _air_time_bar_width, _offset_y + 6, _air_time, "en", nil, "white")
    end
  end
  if _dummy.pos_y > 0 and _air_time == 128 then
    color_player(_dummy, _air_combo_expired_color)
  else
    color_player(_dummy, "default")
  end
end

local fuzz = 0x0000
thes = true
function player_coloring_display()
--   _player = player
--   if thes then
--   memory.writeword(_player.base + 616, 0x2011)
--   end
--   if _player.posture == 20 or _player.posture == 22 or _player.posture == 24 then
-- --     memory.writeword(_player.base + 616, 0x2013)
-- if thes then
--     queue_command(frame_number + 1, {command = function(n) memory.writeword(_player.base + 616, n) end, args={0x0015}})
--     thes = false
--     end
-- --     memory.writeword(_player.base + 608, 0x0000)
-- --     memory.writeword(_player.base + 618, 0x0000)
-- --     memory.writeword(_player.base + 622, 0x0001)
--     memory.writeword(dummy.base + 616, 0x0013)
--
-- --     if frame_number % 2 == 0 then
-- --       fuzz = fuzz + 0x0001
-- --     end
--   else
--     memory.writeword(_player.base + 616, 0x2000) --p1
--     memory.writeword(dummy.base + 616, 0x2010) --p2
--   end
end


local red_parry_display_start_frame = 0
local watch_parry_object = {false, false}
local last_blocked_frame = 0
local red_parry_miss_display_x = 0
local red_parry_miss_display_y = 0
local red_parry_miss_display_text = ""
local red_parry_miss_display_time = 60
local red_parry_miss_fade_time = 20

function red_parry_miss_display_reset()
  last_blocked_frame = 0
  red_parry_display_start_frame = 0
  watch_parry_object = {false, false}
end

function red_parry_miss_display(_player)
  if _player.has_just_blocked then
      last_blocked_frame = frame_number
  end
  local _elapsed = frame_number - red_parry_display_start_frame

  if frame_number - last_blocked_frame <= 30 then
    local _parry_objects = {_player.parry_forward, _player.parry_down}
    for i = 1, #_parry_objects do
      if _parry_objects[i].validity_time > 0 and _elapsed >= 15 then
        watch_parry_object[i] = true
      end
      if watch_parry_object[i] then
        if _player.has_just_been_hit or _parry_objects[i].validity_time <= 0 then
          watch_parry_object[i] = false
          if _parry_objects[i].delta then
            if not _parry_objects[i].success then
              if _parry_objects[i].delta >= 0 then
                red_parry_miss_display_text = string.format("%d", - _parry_objects[i].delta)
              else
                red_parry_miss_display_text = string.format("+%d", - _parry_objects[i].delta)
              end
              local _sign = 1
              if _player.flip_x == 1 then _sign = -1 end

              red_parry_miss_display_x = _player.pos_x - _sign * character_specific[_player.char_str].half_width * 3 / 4
              red_parry_miss_display_y = _player.pos_y + character_specific[_player.char_str].height * 3 / 4
              red_parry_display_start_frame = frame_number
            end
          end
        end
      end
    end
  end
  if _elapsed <= red_parry_miss_display_time + red_parry_miss_fade_time then
    local _opacity = 1
    if _elapsed > red_parry_miss_display_time then
      _opacity = 1 - ((_elapsed - red_parry_miss_display_time) / red_parry_miss_fade_time)
    end
    local _x, _y = game_to_screen_space(red_parry_miss_display_x, red_parry_miss_display_y)
    render_text(_x, _y, red_parry_miss_display_text, "en", nil, stun_color, _opacity)
  end
end

local draw_kaiten_first_run = true
local dir_2_inactive, dir_4_inactive, dir_6_inactive, dir_8_inactive
local kaiten_images =
{
  active = {img_6_dir_small, img_2_dir_small, img_4_dir_small, img_8_dir_small},
  inactive = {dir_6_inactive, dir_2_inactive, dir_4_inactive, dir_8_inactive}
}
function draw_kaiten(_x,_y, _dirs, _flip)
  if draw_kaiten_first_run then
    dir_2_inactive = gd.createFromPng("images/controller/2_dir_s_inactive.png"):gdStr()
    dir_4_inactive = gd.createFromPng("images/controller/4_dir_s_inactive.png"):gdStr()
    dir_6_inactive = gd.createFromPng("images/controller/6_dir_s_inactive.png"):gdStr()
    dir_8_inactive = gd.createFromPng("images/controller/8_dir_s_inactive.png"):gdStr()
    kaiten_images.inactive = {dir_6_inactive, dir_2_inactive, dir_4_inactive, dir_8_inactive}
    draw_kaiten_first_run = false
  end
  --input       2 4 6 8 2 4 6 8
  --reorder to  6 2 4 8 6 2 4 8
  local _dirs_ordered = deepcopy(_dirs)
  for i = 1, #_dirs_ordered do
    if i % 4 == 3 then
      local _d = table.remove(_dirs_ordered, i)
      table.insert(_dirs_ordered, i - 2, _d)
    end
  end
  --input       6 2 4 8 6 2 4 8
  --reorder to  4 2 6 8 4 2 6 8
  if _flip then
    for i = 1, #_dirs_ordered do
      if i % 4 == 3 then
        local _d1 = _dirs_ordered[i]
        local _d2 = _dirs_ordered[i - 2]
        _dirs_ordered[i] = _d2
        _dirs_ordered[i - 2] = _d1
      end
    end
  end

  local _offset_x = 0
  for i = 1, #_dirs_ordered do
    if _dirs_ordered[i] then
      gui.image(_x + _offset_x, _y, kaiten_images.active[(i - 1) % 4 + 1])
    else
      gui.image(_x + _offset_x, _y, kaiten_images.inactive[(i - 1) % 4 + 1])
    end
    _offset_x = _offset_x + 10
  end
end

function draw_denjin(offsetX, offsetY)
  denjinTimer = memory.readbyte(0x02068D27)
  denjin = memory.readbyte(0x02068D2D)
  barColor = 0x00000000
  denjinLv = 0
  if denjin == 3 then
    denjinLv = 1
    barColor = 0x0080FFFF
  elseif denjin == 9 then
    denjinLv = 2
    barColor = 0x00FFFFFF
  elseif denjin == 14 then
    denjinLv = 3
    barColor = 0x80FFFFFF
  elseif denjin == 19 then
    denjinLv = 4
    barColor = 0xFEFEFEFF
    if denjinTimer == 0 then
      denjinLv = 5
    end
  end
gui.text(offsetX-10,offsetY, "  " .. tostring(denjinTimer))
gui.text(offsetX-38,offsetY,"LV_"..denjinLv)
offsetY = offsetY + 1
gui.drawbox(offsetX,offsetY,offsetX+8,offsetY+4,0x00000000,0x000000FF)
gui.drawbox(offsetX,offsetY,offsetX+24,offsetY+4,0x00000000,0x000000FF)
gui.drawbox(offsetX,offsetY,offsetX+48,offsetY+4,0x00000000,0x000000FF)
gui.drawbox(offsetX,offsetY,offsetX+80,offsetY+4,0x00000000,0x000000FF)
gui.drawbox(offsetX,offsetY,offsetX+denjinTimer,offsetY+4,barColor,0x000000FF)

end


attack_range_display_attacks = {{},{}}
attack_range_display_data = {}

function attack_range_display_reset()
  attack_range_display_attacks = {{},{}}
  attack_range_display_data = {}
end

function attack_range_display()
  function already_in_list(_table, _item)
    for k,v in pairs(_table) do
      if v == _item then
        return true
      end
    end
    return false
  end
  local _players = {}
  if training_settings.display_attack_range == 2 then
    _players = {P1}
  elseif training_settings.display_attack_range == 3 then
    _players = {P2}
  elseif training_settings.display_attack_range == 4 then
    _players = {P1, P2}
  end


  for _, _player in pairs(_players) do
    local _frame_data = nil
    local id = _player.id
    if _player.has_just_attacked then
      _frame_data = frame_data[_player.char_str][_player.animation]
      if _frame_data and _frame_data.hit_frames then
        if not already_in_list(attack_range_display_attacks[id], _player.animation) then
          table.insert(attack_range_display_attacks[id], _player.animation)
        end
      end
    end
    while #attack_range_display_attacks[id] > training_settings.attack_range_display_max_attacks do
      table.remove(attack_range_display_attacks[id], 1)
    end


    local _sign = 1
    if _player.flip_x ~= 0 then _sign = -1 end
    for i = 1, #attack_range_display_attacks[id] do
      if _player.animation == attack_range_display_attacks[id][i] then
        local _last_hit_frame = 0
        local _offset_x = 0
        local _offset_y = 0
        _frame_data = frame_data[_player.char_str][attack_range_display_attacks[id][i]]
        if _frame_data then
          for _, _hit_frame in ipairs(_frame_data.hit_frames) do
            if type(_hit_frame) == "number" then
                _last_hit_frame = math.max(_hit_frame, _last_hit_frame)
            else
              _last_hit_frame = math.max(_hit_frame.max, _last_hit_frame)
            end
          end
          _last_hit_frame = _last_hit_frame + 1

          local _movement_type = 1
          local _frame_data_meta = frame_data_meta[_player.char_str][attack_range_display_attacks[id][i]]
          attack_range_display_data[attack_range_display_attacks[id][i]] = {}
          for j = 1, _last_hit_frame do
              if _frame_data_meta and _frame_data_meta.movement_type then
                _movement_type = _frame_data_meta.movement_type
              end
              if _movement_type == 1 then
                _offset_x = _offset_x + _frame_data.frames[j].movement[1]
                _offset_y = _offset_y + _frame_data.frames[j].movement[2]
              else -- velocity based movement
        --         _next_attacker_pos = predict_object_position(_player_obj, _frame_delta)
              end

            if _frame_data.frames[j].boxes then
              for _, _box in pairs(_frame_data.frames[j].boxes) do
                _box = format_box(_box)
                if _box.type == "attack" or _box.type == "throw" then
                  local _data = {}
                  local _dist = 0
                  if _player.flip_x == 0 then
                    _dist = math.abs(_offset_x + _box.left)
                  else
                    _dist = math.abs(-_offset_x - _box.left)
                  end
                  _data.distance = _dist
                  _data.box = _box
                  _data.offset_x = _offset_x
                  _data.offset_y = _offset_y
                  table.insert(attack_range_display_data[attack_range_display_attacks[id][i]], _data)
                end
              end
            end
          end
        end
      end
      for _,_data in pairs(attack_range_display_data[attack_range_display_attacks[id][i]]) do
        if _player.animation == attack_range_display_attacks[id][i] then
          draw_hitboxes(_player.pos_x, _player.pos_y, _player.flip_x, {_data.box}, {["attack"]=true}, nil, 0x880000FF)
          draw_hitboxes(_player.pos_x, _player.pos_y, _player.flip_x, {_data.box}, {["throw"]=true}, nil, 0x888800FF)
        else
          draw_hitboxes(_player.pos_x + _sign * _data.offset_x, _player.pos_y + _data.offset_y, _player.flip_x, {_data.box}, {["attack"]=true}, nil, 0x880000FF)
          draw_hitboxes(_player.pos_x + _sign * _data.offset_x, _player.pos_y + _data.offset_y, _player.flip_x, {_data.box}, {["throw"]=true}, nil, 0x888800FF)
        end
      end
    end
    if training_settings.attack_range_display_show_numbers then
      for i = 1, #attack_range_display_attacks[id] do
        if attack_range_display_data[attack_range_display_attacks[id][i]] then
--         local _tx,_ty = 0
--         if _player.flip_x == 0 then
--           _tx = _farthest[3][1] + _farthest[2].width / 2
--         else
--           _tx = _farthest[3][1] - _farthest[2].width / 2
--         end
--         _ty = _farthest[3][2] - _farthest[2].height / 2
--         local _posx, _posy = game_to_screen_space(_tx, _ty)
-- print(#attack_range_display_data[attack_range_display_attacks[id][i]])
          local _dist = 0
          local _attack_data = attack_range_display_data[attack_range_display_attacks[id][i]]
          local _data = attack_range_display_data[attack_range_display_attacks[id][i]][1]
          for j = 1, #_attack_data do
            if _attack_data[j].distance > _dist then
              _dist = _attack_data[j].distance
              _data = _attack_data[j]
            end
          end
          if _data ~= nil then
            local _w,_h = get_text_dimensions(tostring(_data.distance))
            local _tx = 0

            if _sign == 1 then
              _tx = math.max(_player.pos_x + _data.offset_x + _sign * _data.box.left + _sign * _data.box.width / 2 - _w / 2, _player.pos_x + _data.offset_x + _sign * _data.box.left + 2)
            else
              _tx = math.min(_player.pos_x - _data.offset_x + _sign * _data.box.left + _sign * _data.box.width / 2 - _w / 2, _player.pos_x - _data.offset_x + _sign * _data.box.left - 2 - _w)
            end
            local _posx, _posy = game_to_screen_space(_tx, _player.pos_y + _data.offset_y + _data.box.bottom + _data.box.height / 2 + _h / 2 - 1)

            render_text(_posx, _posy, tostring(_data.distance) .. " " .. attack_range_display_attacks[id][i], "en", nil, "white")
          end
        end
      end
    end
  end
end



function colorscale(hex, scalefactor)

    if scalefactor < 0 then
        return hex
    end

  local r = bit.rshift(bit.band(hex,0xFF000000), 3*8)
  local g = bit.rshift(bit.band(hex,0x00FF0000), 2*8)
  local b = bit.rshift(bit.band(hex,0x0000FF00), 1*8)
  local a = bit.band(hex,0x000000FF)

  r = math.floor(clamp(r * scalefactor, 0, 255))
  g = math.floor(clamp(g * scalefactor, 0, 255))
  b = math.floor(clamp(b * scalefactor, 0, 255))

  return tonumber(string.format("0x%02x%02x%02x%02x", r, g, b, a))
end

frame_gauge_data = {}
frame_gauge_data.startup = 1
frame_gauge_data.hit = 1
frame_gauge_data.recovery = 1
frame_gauge_data.advantage = 1
function frame_gauge()

  local _y = 46
  local _unit_width = 4
  local _unit_height = 7
  local _num_units = 70
  local _green = 0x00FF00FF

  local _x = (screen_width - _num_units * _unit_width) / 2
--   for i = 0, _num_units-1 do
--     local _color = colorscale(_green, .8)
--     gui.drawbox(_x+i*_unit_width,_y,_x+i*_unit_width+_unit_width,_y+_unit_height,0x00FF00FF,_color)
--   end
  for i = 0, 30 do
    local _color = colorscale(_green, 1-i%5*.1)
    gui.drawbox(_x+i*_unit_width+1,_y,_x+i*_unit_width+_unit_width,_y+_unit_height,_color,_color)
  end
  for i = 31, _num_units-1 do
    local _color = colorscale(0xFF0000FF, 1-i%5*.1)
    gui.drawbox(_x+i*_unit_width+1,_y+1,_x+i*_unit_width+_unit_width,_y-1+_unit_height,_color,_color)
  end


  --attack conn hit or boxes
--   if _player.has_just_attacked then
    --reset --nope for combos
    --look ahead in frame data
--   end
  --dash
gui.drawbox(_x,_y,_x+_num_units*_unit_width+1,_y+_unit_height,0x00000000,0x000000FF)

render_text(_x+25*_unit_width,_y,"10","en", nil,"white")
end

local last_hit_history = nil
local last_hit_history_size = 2

function last_hit_bars()
  if training_settings.display_attack_bars > 1 then
    if training_settings.display_attack_bars == 2 then
      last_hit_history_size = 1
    elseif training_settings.display_attack_bars == 3 then
      last_hit_history_size = 2
    end
    local _life_x = 8
    local _life_y = 12
    local _life_max_width = 160
    local _life_height = 6
    local _life_color = 0xFFFFFFFF
    local _stun_x = _life_x + _life_max_width - 1
    local _stun_y = 30
    local _stun_height = 6
    local _stun_color = stun_color

    local _sign = 1

    if attack_data then
      if last_hit_history then
        if attack_data.id == last_hit_history[1].id then

          last_hit_history[1] = deepcopy(attack_data)
        else
          table.insert(last_hit_history, 1, deepcopy(attack_data))
          while #last_hit_history > last_hit_history_size do
            table.remove(last_hit_history, #last_hit_history)
          end
        end
      else
        last_hit_history = {deepcopy(attack_data)}
      end
    end
    if last_hit_history then
      for i = 1, #last_hit_history do
        if last_hit_history[i].total_damage > 0 then
          local _life_width = last_hit_history[i].total_damage
          local _life_offset = 160 - last_hit_history[i].start_life

          if last_hit_history[i].player_id == 1 then
            _life_width = _life_width - 2
          end
          if last_hit_history[i].player_id == 1 then
            _life_x = screen_width - 8
            _stun_x = _life_x - _life_max_width + 1
            _sign = -1
          end

          gui.drawline(_life_x+_sign*_life_offset, _life_y-(i-1)*_life_height, _life_x+_sign*_life_offset+_sign*_life_width - 1,_life_y-(i-1)*_life_height,_life_color)
          gui.drawline(_life_x+_sign*_life_offset, _life_y-(i-1)*_life_height, _life_x+_sign*_life_offset,_life_y-(i-1)*_life_height+2,_life_color)
          gui.drawline(_life_x+_sign*_life_offset+_sign*_life_width - 1, _life_y-(i-1)*_life_height, _life_x+_sign*_life_offset+_sign*_life_width - 1,_life_y-(i-1)*_life_height+2,_life_color)
          local _text_width = get_text_dimensions(tostring(last_hit_history[i].total_damage), "en")
          local _text_pos_x = math.round(_sign * (_life_width - _text_width) / 2) + _life_x + _sign*_life_offset
--           if _text_width + 4 > _life_width then
--             _text_pos_x = _life_x+_sign*_life_offset+_sign*_life_width - 1 + 2 * _sign
--           else
          if last_hit_history[i].player_id == 1 then
            _text_pos_x = _text_pos_x - _text_width
          end
          local _text_pos_y = 9 - (i - 1) * _life_height
          render_text(_text_pos_x, _text_pos_y, tostring(last_hit_history[i].total_damage), "en", nil, "white")

          local _stun_width = last_hit_history[i].total_stun
          local _stun_offset = last_hit_history[i].start_stun

          if _stun_width > 0 then
            if last_hit_history[i].player_id == 2 then
              _stun_width = _stun_width - 2
            end

            gui.drawline(_stun_x-_sign*_stun_offset, _stun_y+(i-1)*_stun_height, _stun_x-_sign*_stun_offset-_sign*_stun_width - 1,_stun_y+(i-1)*_stun_height,_stun_color)
            gui.drawline(_stun_x-_sign*_stun_offset, _stun_y+(i-1)*_stun_height, _stun_x-_sign*_stun_offset,_stun_y+(i-1)*_stun_height-1,_stun_color)
            gui.drawline(_stun_x-_sign*_stun_offset-_sign*_stun_width - 1, _stun_y+(i-1)*_stun_height, _stun_x-_sign*_stun_offset-_sign*_stun_width - 1,_stun_y+(i-1)*_stun_height-1,_stun_color)
            if training_settings.attack_bars_show_decimal then
              _text_width = get_text_dimensions(string.format("%.2f", last_hit_history[i].total_stun), "en")
              _text_pos_x = _stun_x-_sign*_stun_offset-_sign*_stun_width - 1 - 2 * _sign
              if last_hit_history[i].player_id == 2 then
                _text_pos_x = _text_pos_x - _text_width
              end
              _text_pos_y = _stun_y + (i - 1) * _stun_height - 2
              render_text(_text_pos_x, _text_pos_y, string.format("%.2f", last_hit_history[i].total_stun), "en", nil, _stun_color)
            else
              _text_width = get_text_dimensions(tostring(math.round(last_hit_history[i].total_stun)), "en")
              _text_pos_x = math.round(-1 * _sign * (_stun_width - _text_width) / 2) + _stun_x - _sign*_stun_offset
              if last_hit_history[i].player_id == 2 then
                _text_pos_x = _text_pos_x - _text_width
              end
              _text_pos_y = _stun_y + (i - 1) * _stun_height - 2
              render_text(_text_pos_x, _text_pos_y, tostring(math.round(last_hit_history[i].total_stun)), "en", nil, _stun_color)
            end
          end
        end
      end
    end
  end
end

local last_dir = 1
function update_blocking_direction(_input, _player, _dummy)
  if (_player.previous_pos_x - _dummy.previous_pos_x) * (_player.pos_x - _dummy.pos_x) <= 0 then
  end
  if _dummy.received_connection and training_settings.blocking_mode > 1 then
    table.insert(blocking_direction_history, {start_frame=frame_number, dir=last_dir})
  end
  if _dummy.blocking.last_blocked_frame == frame_number then
    last_dir = 5
    if _input[_dummy.prefix.." Up"] == false then
      if _input[_dummy.prefix.." Down"] == false then
        if _input[_dummy.prefix.." Left"] == true then
          last_dir = 4
        elseif _input[_dummy.prefix.." Right"] == true then
          last_dir = 6
        end
      else
        if _input[_dummy.prefix.." Left"] == true then
          last_dir = 1
        elseif _input[_dummy.prefix.." Right"] == true then
          last_dir = 3
        else
          last_dir = 2
        end
      end
    end
  end
end

local blocking_direction_display_time = 90
local blocking_direction_fade_time = 20
blocking_direction_history = {}
function blocking_direction_display(_player, _dummy)
  local _offset_y = 10
  local i = 1
  while i <= #blocking_direction_history do
    local _elapsed = frame_number - blocking_direction_history[i].start_frame
    if _elapsed <= blocking_direction_display_time + blocking_direction_fade_time then
      local _opacity = 1
      if _elapsed > blocking_direction_display_time then
        _opacity = 1 - ((_elapsed - blocking_direction_display_time) / blocking_direction_fade_time)
      end
      local _x, _y = game_to_screen_space(_dummy.pos_x, _dummy.pos_y + character_specific[_dummy.char_str].height)
      gui.image(_x, _y - (#blocking_direction_history - i - 1) * _offset_y, img_dir_small[blocking_direction_history[i].dir], _opacity)
    else
      table.remove(blocking_direction_history, i)
    end
    i = i + 1
  end
end

function hitboxes_display()
  -- players
  local p1_filter = {["attack"]=true, ["throw"]=true}
  local fff = {["push"]=true}
  local p2_filter = nil
  -- draw_hitboxes(P1.pos_x, P1.pos_y, P1.flip_x, P1.boxes, fff, nil, nil, 0x90)

  draw_hitboxes(P1.pos_x, P1.pos_y, P1.flip_x, P1.boxes, nil, nil, nil, 0x90)
  draw_hitboxes(P1.pos_x, P1.pos_y, P1.flip_x, P1.boxes, p1_filter, nil, nil)
  draw_hitboxes(P2.pos_x, P2.pos_y, P2.flip_x, P2.boxes, p2_filter, nil, nil, 0x90)

  -- projectiles
  for _id, _obj in pairs(projectiles) do
    draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
  end
end

show_player_position = true
function player_position_display()
  _x, _y = game_to_screen_space(P1.pos_x, P1.pos_y)
  gui.image(_x - 4, _y,img_8_dir_small)
  _x, _y = game_to_screen_space(P2.pos_x, P2.pos_y)
  gui.image(_x - 4 , _y,img_8_dir_small)
end

function draw_hud(_player, _dummy)
  if training_settings.display_attack_range ~= 1 then
    attack_range_display()
  end

  for k, boxes in pairs(to_draw_hitboxes) do
    if k >= frame_number then
      if k - frame_number <= 8 then
        draw_hitboxes(unpack(boxes))
      end
    else
      to_draw_hitboxes[k] = nil
    end
  end


  if training_settings.display_hitboxes then
    hitboxes_display()
  end
  last_hit_bars()
  red_parry_miss_display(_player)
  blocking_direction_display(_player, _dummy)
  if training_settings.display_parry then
    parry_gauge_display(_player.other)
  end
  if training_settings.display_charge then
    charge_display(_player)
    -- charge_display(P2)

  end
  if training_settings.display_air_time then
    air_time_display(_player, _dummy)
  end
  player_coloring_display()
  if show_player_position then
    player_position_display()
  end
  if show_jumpins_display then
    jumpins_display(_player)
  end

  -- local b = get_pushboxes(_player)
  -- b = format_box(b)
  -- render_text(5,5,b.width,"en")
  -- local b = get_pushboxes(_dummy)
  -- b = format_box(b)
  -- render_text(25,5,b.width,"en")

  -- if P1.pos_y > 0 then
  --   if P1.pos_y > P1.previous_pos_y then
  --     md = 0
  --   end
  --   local _d = P1.pos_x - P1.previous_pos_x
  --   if _d < md then
  --     md = _d
  --   end
  -- end

  -- render_text(45,5,md,"en")


--   draw_denjin(screen_width/2 - 40, screen_height - 40)

end

