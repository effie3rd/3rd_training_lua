--in-match drawing
local settings = require("src/settings")
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local gamestate = require("src/gamestate")
local attack_data = require("src.modules.attack_data")
local text = require("src.ui.text")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local images = require("src.ui.image_tables")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local frame_data_meta = fdm.frame_data_meta
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text, text.render_text_multiple, text.get_text_dimensions, text.get_text_dimensions_multiple

local gauge_outline_color = colors.gauges.outline
local gauge_background_color = colors.gauges.background
local gauge_valid_fill_color = colors.gauges.valid_fill
local gauge_cooldown_fill_color = colors.gauges.cooldown_fill
local red_parry_miss_color =  colors.red_parry_miss
local stun_color = colors.last_hit_bars.stun
local life_color = colors.last_hit_bars.life

local lang_code = {"en", "jp"}

local draw_kaiten_first_run = true
local dir_2_inactive, dir_4_inactive, dir_6_inactive, dir_8_inactive
local kaiten_images =
{
  active = {images.img_dir_small[6], images.img_dir_small[2], images.img_dir_small[4], images.img_dir_small[8]},
  inactive = {dir_6_inactive, dir_2_inactive, dir_4_inactive, dir_8_inactive}
}
local function draw_kaiten(x, y, dirs, flip)
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
  local dirs_ordered = deepcopy(dirs)
  for i = 1, #dirs_ordered do
    if i % 4 == 3 then
      local d = table.remove(dirs_ordered, i)
      table.insert(dirs_ordered, i - 2, d)
    end
  end
  --input       6 2 4 8 6 2 4 8
  --reorder to  4 2 6 8 4 2 6 8
  if flip then
    for i = 1, #dirs_ordered do
      if i % 4 == 3 then
        local d1 = dirs_ordered[i]
        local d2 = dirs_ordered[i - 2]
        dirs_ordered[i] = d2
        dirs_ordered[i - 2] = d1
      end
    end
  end

  local offset_x = 0
  for i = 1, #dirs_ordered do
    if dirs_ordered[i] then
      gui.image(x + offset_x, y, kaiten_images.active[(i - 1) % 4 + 1])
    else
      gui.image(x + offset_x, y, kaiten_images.inactive[(i - 1) % 4 + 1])
    end
    offset_x = offset_x + 10
  end
end

local function parry_gauge_display(player)
  local pos_x = 235 --96
  local pos_y = 40
  local flip_gauge = false
  local gauge_x_scale = 4

  if settings.training.charge_follow_character then
    local px = player.pos_x - draw.screen_x + emu.screenwidth()/2
    local py = emu.screenheight() - (player.pos_y - draw.screen_y) - draw.GROUND_OFFSET
    local half_width = 23 * gauge_x_scale * 0.5
    pos_x = px - half_width
    pos_x = math.max(pos_x, 4)
    pos_x = math.min(pos_x, emu.screenwidth() - (half_width * 2.0 + 14))
    pos_x = py - 100
  end

  local y_offset = 0
  local group_y_margin = 6

  local function draw_parry_gauge_group(x, y, parry_object)
    local gauge_height = 4

    local x_border = 8

    local validity_gauge_width = parry_object.max_validity * gauge_x_scale
    local cooldown_gauge_width = parry_object.max_cooldown * gauge_x_scale

    x = math.min(math.max(x, x_border), draw.SCREEN_WIDTH - x_border - validity_gauge_width)

    local validity_gauge_left = math.floor(x + (cooldown_gauge_width - validity_gauge_width) * 0.5)
    local validity_gauge_right = validity_gauge_left + validity_gauge_width + 1
    local cooldown_gauge_left = x
    local cooldown_gauge_right = cooldown_gauge_left + cooldown_gauge_width + 1
    local validity_time_text = string.format("%d", parry_object.validity_time)
    local cooldown_time_text = string.format("%d", parry_object.cooldown_time)
    local validity_text_color = colors.parry.text_validity
    local validity_outline_color = 0x00000077
    if parry_object.delta then
      if parry_object.success then
        validity_text_color = colors.parry.text_success
        validity_outline_color = 0x00A200FF
      else
        validity_text_color = colors.parry.text_failure
        validity_outline_color = 0x840000FF
      end
      if parry_object.delta >= 0 then
        validity_time_text = string.format("%d", -parry_object.delta)
      else
        validity_time_text = string.format("+%d", -parry_object.delta)
      end
    end

    local str = "parry_" .. parry_object.name

    render_text(x + 1, y, str)
    gui.box(cooldown_gauge_left + 1, y + 11, validity_gauge_left, y + 11, 0x00000000, gauge_outline_color)
    gui.box(cooldown_gauge_left, y + 10, cooldown_gauge_left, y + 12, 0x00000000, gauge_outline_color)
    gui.box(validity_gauge_right, y + 11, cooldown_gauge_right - 1, y + 11, 0x00000000, gauge_outline_color)
    gui.box(cooldown_gauge_right, y + 10, cooldown_gauge_right, y + 12, 0x00000000, gauge_outline_color)
    draw.draw_gauge(validity_gauge_left, y + 8, validity_gauge_width, gauge_height + 1, parry_object.validity_time / parry_object.max_validity, gauge_valid_fill_color, gauge_background_color, gauge_outline_color, true)
    draw.draw_gauge(cooldown_gauge_left, y + 8 + gauge_height + 2, cooldown_gauge_width, gauge_height, parry_object.cooldown_time / parry_object.max_cooldown, gauge_cooldown_fill_color, gauge_background_color, gauge_outline_color, true)

    gui.box(validity_gauge_left + 3 * gauge_x_scale, y + 8, validity_gauge_left + 2 + 3 * gauge_x_scale,  y + 8 + gauge_height + 2, gauge_outline_color, 0x00000000)

    if parry_object.delta then
      local marker_x = validity_gauge_left + parry_object.delta * gauge_x_scale
      marker_x = math.min(math.max(marker_x, x), cooldown_gauge_right)
      gui.box(marker_x, y + 7, marker_x + gauge_x_scale, y + 8 + gauge_height + 2, validity_text_color, validity_outline_color)
    end

    render_text(cooldown_gauge_right + 4, y + 7, validity_time_text, "en", nil, validity_text_color)
    render_text(cooldown_gauge_right + 4, y + 13, cooldown_time_text, "en", nil, validity_text_color)

    return 8 + 5 + (gauge_height * 2)
  end

  local parry_array = {
    {
      object = player.parry_forward,
      enabled = settings.training.special_training_parry_forward_on
    },
    {
      object = player.parry_down,
      enabled = settings.training.special_training_parry_down_on
    },
    {
      object = player.parry_air,
      enabled = settings.training.special_training_parry_air_on
    },
    {
      object = player.parry_antiair,
      enabled = settings.training.special_training_parry_antiair_on
    }
  }

  for _, parry in ipairs(parry_array) do

    if parry.enabled then
      y_offset = y_offset + group_y_margin + draw_parry_gauge_group(pos_x, pos_y + y_offset, parry.object)
    end
  end
end

local function charge_display(player)
  local pos_x = 272 --96
  if settings.training.charge_overcharge_on then
    pos_x = 264
  end
  local pos_y = 46
  local flip_gauge = false
  local gauge_x_scale = 2

  if settings.training.charge_follow_character then
    local offset_x = 8

    pos_x,pos_y = draw.game_to_screen_space(player.pos_x, player.pos_y + character_specific[player.char_str].height)
    pos_x = pos_x + offset_x
    if player.flip_x == 1 then
      pos_x = pos_x - (43 * gauge_x_scale + offset_x + 16)
    end
    pos_y = pos_y
  end

  local y_offset = 0
  local x_offset = 0
  local group_y_margin = 6
  local group_x_margin = 12
  local gauge_height = 3
  local overcharge_color = colors.charge.overcharge
  local x_border = 16

  local function draw_charge_gauge_group(x, y, charge_object)
    local charge_gauge_width = charge_object.max_charge * gauge_x_scale
    local reset_gauge_width = charge_object.max_reset * gauge_x_scale

    x = math.min(math.max(x, x_border), draw.SCREEN_WIDTH - x_border - charge_gauge_width)

    local charge_gauge_left = math.floor(x + (reset_gauge_width - charge_gauge_width) * 0.5)
    local charge_gauge_right = charge_gauge_left + charge_gauge_width + 1
    local reset_gauge_left = x
    local reset_gauge_right = reset_gauge_left + reset_gauge_width + 1
    local charge_time_text = string.format("%d", charge_object.charge_time)
    local reset_time_text = string.format("%d", charge_object.reset_time)
    local charge_text_color = colors.charge.text_validity
    if charge_object.max_charge - charge_object.charge_time == charge_object.max_charge then
      charge_text_color = colors.charge.text_success
    else
      charge_text_color = colors.charge.text_failure
    end

    charge_time_text = string.format("%d", charge_object.max_charge - charge_object.charge_time)
    local overcharge_time_text = string.format("[%d]", charge_object.overcharge)
    local last_overcharge_time_text = string.format("[%d]", charge_object.last_overcharge)
    reset_time_text = string.format("%d", charge_object.reset_time)

    local name_y_offset = 0
    if lang_code[settings.training.language] == "jp" then
      name_y_offset = -1
    end
    render_text(x + 1, y + name_y_offset, charge_object.name)
--       gui.box(reset_gauge_left + 1, y + 11, charge_gauge_left, y + 11, 0x00000000, 0x00000077)
--       gui.box(reset_gauge_left, y + 10, reset_gauge_left, y + 12, 0x00000000, 0x00000077)
--       gui.box(charge_gauge_right, y + 11, reset_gauge_right - 1, y + 11, 0x00000000, 0x00000077)
--       gui.box(reset_gauge_right, y + 10, reset_gauge_right, y + 12, 0x00000000, 0x00000077)
    draw.draw_gauge(charge_gauge_left, y + 8, charge_gauge_width, gauge_height + 1, charge_object.charge_time / charge_object.max_charge, gauge_valid_fill_color, gauge_background_color, gauge_outline_color, true)
    draw.draw_gauge(reset_gauge_left, y + 8 + gauge_height + 2, reset_gauge_width, gauge_height, charge_object.reset_time / charge_object.max_reset, gauge_cooldown_fill_color, gauge_background_color, gauge_outline_color, true)
    if settings.training.charge_overcharge_on and charge_object.overcharge ~= 0 and charge_object.overcharge < 42 then
      draw.draw_gauge(charge_gauge_left, y + 8, charge_gauge_width, gauge_height + 1, charge_object.overcharge / charge_object.max_charge, overcharge_color, gauge_background_color, gauge_outline_color, true)
      local w = get_text_dimensions(charge_time_text, "en")
      render_text(reset_gauge_right + 4 + w, y + 7, overcharge_time_text, "en", nil, charge_text_color)
    end
    if settings.training.charge_overcharge_on and charge_object.overcharge == 0 and charge_object.last_overcharge > 0 and charge_object.last_overcharge < 42 then
      local w = get_text_dimensions(charge_time_text, "en")
      render_text(reset_gauge_right + 4 + w, y + 7, last_overcharge_time_text, "en", nil, charge_text_color)
    end

    render_text(reset_gauge_right + 4, y + 7, charge_time_text, "en", nil, charge_text_color)
    render_text(reset_gauge_right + 4, y + 13, reset_time_text, "en", nil)

    return 8 + 5 + (gauge_height * 2)
  end

  local function draw_kaiten_gauge_group(x, y, kaiten_object)
    local charge_gauge_width = 43 * gauge_x_scale
    local reset_gauge_width = 43 * gauge_x_scale

    x = math.min(math.max(x, x_border), draw.SCREEN_WIDTH - x_border - charge_gauge_width)

    local charge_gauge_left = math.floor(x + (reset_gauge_width - charge_gauge_width) * 0.5)
    local charge_gauge_right = charge_gauge_left + charge_gauge_width + 1
    local reset_gauge_left = x
    local reset_gauge_right = reset_gauge_left + reset_gauge_width + 1
    local validity_time_text = ""
    if kaiten_object.validity_time > 0 then
      validity_time_text = string.format("%d", kaiten_object.validity_time)
    end
    local reset_time_text = string.format("%d", kaiten_object.reset_time)
    local charge_text_color = text.default_color

    local name_y_offset = 0
    if lang_code[settings.training.language] == "jp" then
      name_y_offset = -1
    end
    render_text(x + 1, y + name_y_offset, kaiten_object.name)

    draw_kaiten(x, y + 8, kaiten_object.directions, not player.flip_input)

    draw.draw_gauge(reset_gauge_left, y + 8 + 9, reset_gauge_width, gauge_height, kaiten_object.reset_time / kaiten_object.max_reset, gauge_cooldown_fill_color, gauge_background_color, gauge_outline_color, true)

    render_text(reset_gauge_right + 4, y + 10, validity_time_text, "en", nil)
    render_text(reset_gauge_right + 4, y + 17, reset_time_text, "en", nil)

    return 8 + 5 + 9 + gauge_height
  end


  local function draw_legs_gauge_group(x, y, legs_object)
    local gauge_height = 3
    local width = 43 * gauge_x_scale
    local style = draw.controller_styles[settings.training.controller_style]
    local tw, th = get_text_dimensions("hyakuretsu_MK")
    local margin = tw + 1
    local x_offset = margin
    render_text(x, y, "hyakuretsu_LK")
    for i = 1, legs_object.l_legs_count do
      gui.image(x + x_offset, y, images.img_button_small[style][4])
      x_offset = x_offset + 8
    end
    x_offset = margin
    render_text(x, y + 8, "hyakuretsu_MK")
    for i = 1, legs_object.m_legs_count do
      gui.image(x + x_offset, y + 8, images.img_button_small[style][5])
      x_offset = x_offset + 8
    end
    x_offset = margin
    render_text(x, y + 16, "hyakuretsu_HK")
    for i = 1, legs_object.h_legs_count do
      gui.image(x + x_offset, y + 16, images.img_button_small[style][6])
      x_offset = x_offset + 8
    end
    x_offset = margin

    if legs_object.active ~= 0xFF then
      draw.draw_gauge(x, y + 24, width, gauge_height + 1, legs_object.reset_time / 99, gauge_valid_fill_color, gauge_background_color, gauge_outline_color, true)
    end

    return 8 + 5 + (gauge_height * 2)
  end

  local charge_array = {
    {
      object = player.charge_1,
      enabled = player.charge_1.enabled
    },
    {
      object = player.charge_2,
      enabled = player.charge_2.enabled
    },
    {
      object = player.charge_3,
      enabled = player.charge_3.enabled
    }
  }

  for _, charge in ipairs(charge_array) do
    if charge.enabled then
      y_offset = y_offset + group_y_margin + draw_charge_gauge_group(pos_x, pos_y + y_offset, charge.object)
    end
  end

  if player.char_str == "hugo"
  or (player.char_str == "alex" and player.selected_sa == 1) then
    for _, kaiten in ipairs(player.kaiten) do
      if kaiten.enabled then
        y_offset = y_offset + group_y_margin + draw_kaiten_gauge_group(pos_x, pos_y + y_offset, kaiten)
      end
    end
  end

  if player.legs_state.enabled then
    draw_legs_gauge_group(pos_x, pos_y + y_offset, player.legs_state)
  end
end

local player_default_color = 0x4200
local function color_player(player, color)
  if color == "default" then
    memory.writeword(player.base + 616, player_default_color)
  else
    memory.writeword(player.base + 616, color)
  end
end

local air_combo_expired_color = 0x2013
local air_time_bar_max_width = 121
local function air_time_display(player, dummy)
  local player = gamestate.P1
  local dummy = gamestate.P2
  local offset_x = 225
  local offset_y = 50
  local juggle_count = memory.readbyte(0x020694C9)
  local air_time = math.floor((memory.readbyte(0x020694C7) + 1) / 2)
  local air_time_bar_width = math.round((air_time / 121) * air_time_bar_max_width)
  local x, y = get_text_dimensions(tostring(juggle_count), "en")
  render_text(offset_x - x, offset_y - 2, juggle_count, "en", nil)
  offset_x = offset_x + 4
  gui.drawbox(offset_x, offset_y, offset_x + air_time_bar_max_width, offset_y + 3, gauge_background_color, 0x000000FF)
  if air_time ~= 128 then --0x00C080FF
    gui.drawbox(offset_x, offset_y, offset_x + air_time_bar_width, offset_y + 3, gauge_valid_fill_color, 0x00000000)
    if air_time > 0 then
      x, y = get_text_dimensions(tostring(air_time), "en")
      offset_x = offset_x - x / 2
      render_text(offset_x + air_time_bar_width, offset_y + 6, air_time, "en", nil)
    end
  end
  if dummy.pos_y > 0 and air_time == 128 then
    color_player(dummy, air_combo_expired_color)
  else
    color_player(dummy, "default")
  end
end

-- local function player_coloring_display()
--   player = player
--   if thes then
--   memory.writeword(player.base + 616, 0x2011)
--   end
--   if player.posture == 20 or player.posture == 22 or player.posture == 24 then
-- --     memory.writeword(player.base + 616, 0x2013)
-- if thes then
--     Queue_Command(gamestate.frame_number + 1, {command = function(n) memory.writeword(player.base + 616, n) end, args={0x0015}})
--     thes = false
--     end
-- --     memory.writeword(player.base + 608, 0x0000)
-- --     memory.writeword(player.base + 618, 0x0000)
-- --     memory.writeword(player.base + 622, 0x0001)
--     memory.writeword(dummy.base + 616, 0x0013)
--
-- --     if gamestate.frame_number % 2 == 0 then
-- --       fuzz = fuzz + 0x0001
-- --     end
--   else
--     memory.writeword(player.base + 616, 0x2000) --p1
--     memory.writeword(dummy.base + 616, 0x2010) --p2
--   end
-- end


local red_parry_display_start_frame = 0
local watch_parry_object = {false, false}
local last_blocked_frame = 0
local red_parry_miss_display_x = 0
local red_parry_miss_display_y = 0
local red_parry_miss_display_text = ""
local red_parry_miss_display_time = 60
local red_parry_miss_fade_time = 20

local function red_parry_miss_display_reset()
  last_blocked_frame = 0
  red_parry_display_start_frame = 0
  watch_parry_object = {false, false}
end

local function red_parry_miss_display(player)
  if player.has_just_blocked then
      last_blocked_frame = gamestate.frame_number
  end
  local elapsed = gamestate.frame_number - red_parry_display_start_frame

  if gamestate.frame_number - last_blocked_frame <= 30 then
    local parry_objects = {player.parry_forward, player.parry_down}
    for i = 1, #parry_objects do
      if parry_objects[i].validity_time > 0 and elapsed >= 15 then
        watch_parry_object[i] = true
      end
      if watch_parry_object[i] then
        if player.has_just_been_hit or parry_objects[i].validity_time <= 0 then
          watch_parry_object[i] = false
          if parry_objects[i].delta then
            if not parry_objects[i].success then
              if parry_objects[i].delta >= 0 then
                red_parry_miss_display_text = string.format("%d", - parry_objects[i].delta)
              else
                red_parry_miss_display_text = string.format("+%d", - parry_objects[i].delta)
              end
              local sign = 1
              if player.flip_x == 1 then sign = -1 end

              red_parry_miss_display_x = player.pos_x - sign * character_specific[player.char_str].half_width * 3 / 4
              red_parry_miss_display_y = player.pos_y + character_specific[player.char_str].height * 3 / 4
              red_parry_display_start_frame = gamestate.frame_number
            end
          end
        end
      end
    end
  end
  if elapsed <= red_parry_miss_display_time + red_parry_miss_fade_time then
    local opacity = 1
    if elapsed > red_parry_miss_display_time then
      opacity = 1 - ((elapsed - red_parry_miss_display_time) / red_parry_miss_fade_time)
    end
    local x, y = draw.game_to_screen_space(red_parry_miss_display_x, red_parry_miss_display_y)
    render_text(x, y, red_parry_miss_display_text, "en", nil, red_parry_miss_color, opacity)
  end
end

local function draw_denjin(offsetX, offsetY)
  local denjinTimer = memory.readbyte(0x02068D27)
  local denjin = memory.readbyte(0x02068D2D)
  local barColor = 0x00000000
  local denjinLv = 0
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


local attack_range_display_attacks = {{},{}}
local attack_range_display_data = {}

local function attack_range_display_reset()
  attack_range_display_attacks = {{},{}}
  attack_range_display_data = {}
end

--needs to be rewritten due to framedata changes
local function attack_range_display()
  local function already_in_list(table, item)
    for k,v in pairs(table) do
      if v == item then
        return true
      end
    end
    return false
  end
  local players = {}
  if settings.training.display_attack_range == 2 then
    players = {gamestate.P1}
  elseif settings.training.display_attack_range == 3 then
    players = {gamestate.P2}
  elseif settings.training.display_attack_range == 4 then
    players = {gamestate.P1, gamestate.P2}
  end


  for _, player in pairs(players) do
    local fdata = nil
    local id = player.id
    if player.has_just_attacked then
      fdata = frame_data[player.char_str][player.animation]
      if fdata and fdata.hit_frames then
        if not already_in_list(attack_range_display_attacks[id], player.animation) then
          table.insert(attack_range_display_attacks[id], player.animation)
        end
      end
    end
    while #attack_range_display_attacks[id] > settings.training.attack_range_display_max_attacks do
      table.remove(attack_range_display_attacks[id], 1)
    end


    local sign = 1
    if player.flip_x ~= 0 then sign = -1 end
    for i = 1, #attack_range_display_attacks[id] do
      if player.animation == attack_range_display_attacks[id][i] then
        local last_hit_frame = 0
        local offset_x = 0
        local offset_y = 0
        fdata = frame_data[player.char_str][attack_range_display_attacks[id][i]]
        if fdata then
          for _, hit_frame in ipairs(fdata.hit_frames) do
            if type(hit_frame) == "number" then
                last_hit_frame = math.max(hit_frame, last_hit_frame)
            else
              last_hit_frame = math.max(hit_frame.max, last_hit_frame)
            end
          end
          last_hit_frame = last_hit_frame + 1

          local movement_type = 1
          local fdata_meta = frame_data_meta[player.char_str][attack_range_display_attacks[id][i]]
          attack_range_display_data[attack_range_display_attacks[id][i]] = {}
          for j = 1, last_hit_frame do
              if fdata_meta and fdata_meta.movement_type then
                movement_type = fdata_meta.movement_type
              end
              if movement_type == 1 then
                offset_x = offset_x + fdata.frames[j].movement[1]
                offset_y = offset_y + fdata.frames[j].movement[2]
              else -- velocity based movement
        --         next_attacker_pos = predict_object_position(player_obj, frame_delta)
              end

            if fdata.frames[j].boxes then
              for _, box in pairs(fdata.frames[j].boxes) do
                box = format_box(box)
                if box.type == "attack" or box.type == "throw" then
                  local data = {}
                  local dist = 0
                  if player.flip_x == 0 then
                    dist = math.abs(offset_x + box.left)
                  else
                    dist = math.abs(-offset_x - box.left)
                  end
                  data.distance = dist
                  data.box = box
                  data.offset_x = offset_x
                  data.offset_y = offset_y
                  table.insert(attack_range_display_data[attack_range_display_attacks[id][i]], data)
                end
              end
            end
          end
        end
      end
      for _,data in pairs(attack_range_display_data[attack_range_display_attacks[id][i]]) do
        if player.animation == attack_range_display_attacks[id][i] then
          draw.draw_hitboxes(player.pos_x, player.pos_y, player.flip_x, {data.box}, {["attack"]=true}, nil, 0x880000FF)
          draw.draw_hitboxes(player.pos_x, player.pos_y, player.flip_x, {data.box}, {["throw"]=true}, nil, 0x888800FF)
        else
          draw.draw_hitboxes(player.pos_x + sign * data.offset_x, player.pos_y + data.offset_y, player.flip_x, {data.box}, {["attack"]=true}, nil, 0x880000FF)
          draw.draw_hitboxes(player.pos_x + sign * data.offset_x, player.pos_y + data.offset_y, player.flip_x, {data.box}, {["throw"]=true}, nil, 0x888800FF)
        end
      end
    end
    if settings.training.attack_range_display_show_numbers then
      for i = 1, #attack_range_display_attacks[id] do
        if attack_range_display_data[attack_range_display_attacks[id][i]] then
--         local tx,ty = 0
--         if player.flip_x == 0 then
--           tx = farthest[3][1] + farthest[2].width / 2
--         else
--           tx = farthest[3][1] - farthest[2].width / 2
--         end
--         ty = farthest[3][2] - farthest[2].height / 2
--         local posx, posy = draw.game_to_screen_space(tx, ty)
-- print(#attack_range_display_data[attack_range_display_attacks[id][i]])
          local dist = 0
          local attack_data = attack_range_display_data[attack_range_display_attacks[id][i]]
          local data = attack_range_display_data[attack_range_display_attacks[id][i]][1]
          for j = 1, #attack_data do
            if attack_data[j].distance > dist then
              dist = attack_data[j].distance
              data = attack_data[j]
            end
          end
          if data ~= nil then
            local w,h = get_text_dimensions(tostring(data.distance))
            local tx = 0

            if sign == 1 then
              tx = math.max(player.pos_x + data.offset_x + sign * data.box.left + sign * data.box.width / 2 - w / 2, player.pos_x + data.offset_x + sign * data.box.left + 2)
            else
              tx = math.min(player.pos_x - data.offset_x + sign * data.box.left + sign * data.box.width / 2 - w / 2, player.pos_x - data.offset_x + sign * data.box.left - 2 - w)
            end
            local posx, posy = draw.game_to_screen_space(tx, player.pos_y + data.offset_y + data.box.bottom + data.box.height / 2 + h / 2 - 1)

            render_text(posx, posy, tostring(data.distance) .. " " .. attack_range_display_attacks[id][i], "en")
          end
        end
      end
    end
  end
end
--[[ 
frame_gauge_data = {}
frame_gauge_data.startup = 1
frame_gauge_data.hit = 1
frame_gauge_data.recovery = 1
frame_gauge_data.advantage = 1
function frame_gauge()

  local y = 46
  local unit_width = 4
  local unit_height = 7
  local num_units = 70
  local green = 0x00FF00FF

  local x = (draw.SCREEN_WIDTH - num_units * unit_width) / 2
--   for i = 0, num_units-1 do
--     local color = colorscale(green, .8)
--     gui.drawbox(x+i*unit_width,y,x+i*unit_width+unit_width,y+unit_height,0x00FF00FF,color)
--   end
  for i = 0, 30 do
    local color = colors.colorscale(green, 1-i%5*.1)
    gui.drawbox(x+i*unit_width+1,y,x+i*unit_width+unit_width,y+unit_height,color,color)
  end
  for i = 31, num_units-1 do
    local color = colors.colorscale(0xFF0000FF, 1-i%5*.1)
    gui.drawbox(x+i*unit_width+1,y+1,x+i*unit_width+unit_width,y-1+unit_height,color,color)
  end


  --attack conn hit or boxes
--   if player.has_just_attacked then
    --reset --nope for combos
    --look ahead in frame data
--   end
  --dash
gui.drawbox(x,y,x+num_units*unit_width+1,y+unit_height,0x00000000,0x000000FF)

render_text(x+25*unit_width,y,"10","en")
end ]]

local last_hit_history = nil
local last_hit_history_size = 2

local function last_hit_bars()
  if settings.training.display_attack_bars > 1 then
    if settings.training.display_attack_bars == 2 then
      last_hit_history_size = 1
    elseif settings.training.display_attack_bars == 3 then
      last_hit_history_size = 2
    end
    local life_x = 8
    local life_y = 12
    local life_max_width = 160
    local life_height = 6
    local stun_x = life_x + life_max_width - 1
    local stun_y = 30
    local stun_height = 6

    local sign = 1

    if attack_data.data then
      if last_hit_history then
        if attack_data.data.id == last_hit_history[1].id then

          last_hit_history[1] = deepcopy(attack_data.data)
        else
          table.insert(last_hit_history, 1, deepcopy(attack_data.data))
          while #last_hit_history > last_hit_history_size do
            table.remove(last_hit_history, #last_hit_history)
          end
        end
      else
        last_hit_history = {deepcopy(attack_data.data)}
      end
    end
    if last_hit_history then
      for i = 1, #last_hit_history do
        if last_hit_history[i].total_damage > 0 then
          local life_width = last_hit_history[i].total_damage
          local life_offset = 160 - last_hit_history[i].start_life

          if last_hit_history[i].player_id == 1 then
            life_width = life_width - 2
          end
          if last_hit_history[i].player_id == 1 then
            life_x = draw.SCREEN_WIDTH - 8
            stun_x = life_x - life_max_width + 1
            sign = -1
          end

          gui.drawline(life_x+sign*life_offset, life_y-(i-1)*life_height, life_x+sign*life_offset+sign*life_width - 1,life_y-(i-1)*life_height,life_color)
          gui.drawline(life_x+sign*life_offset, life_y-(i-1)*life_height, life_x+sign*life_offset,life_y-(i-1)*life_height+2,life_color)
          gui.drawline(life_x+sign*life_offset+sign*life_width - 1, life_y-(i-1)*life_height, life_x+sign*life_offset+sign*life_width - 1,life_y-(i-1)*life_height+2,life_color)
          local text_width = get_text_dimensions(tostring(last_hit_history[i].total_damage), "en")
          local text_pos_x = math.round(sign * (life_width - text_width) / 2) + life_x + sign*life_offset
--           if text_width + 4 > life_width then
--             text_pos_x = life_x+sign*life_offset+sign*life_width - 1 + 2 * sign
--           else
          if last_hit_history[i].player_id == 1 then
            text_pos_x = text_pos_x - text_width
          end
          local text_pos_y = 9 - (i - 1) * life_height
          render_text(text_pos_x, text_pos_y, tostring(last_hit_history[i].total_damage), "en", nil, life_color)

          local stun_width = last_hit_history[i].total_stun
          local stun_offset = last_hit_history[i].start_stun

          if stun_width > 0 then
            if last_hit_history[i].player_id == 2 then
              stun_width = stun_width - 2
            end

            gui.drawline(stun_x-sign*stun_offset, stun_y+(i-1)*stun_height, stun_x-sign*stun_offset-sign*stun_width - 1,stun_y+(i-1)*stun_height,stun_color)
            gui.drawline(stun_x-sign*stun_offset, stun_y+(i-1)*stun_height, stun_x-sign*stun_offset,stun_y+(i-1)*stun_height-1,stun_color)
            gui.drawline(stun_x-sign*stun_offset-sign*stun_width - 1, stun_y+(i-1)*stun_height, stun_x-sign*stun_offset-sign*stun_width - 1,stun_y+(i-1)*stun_height-1,stun_color)
            if settings.training.attack_bars_show_decimal then
              text_width = get_text_dimensions(string.format("%.2f", last_hit_history[i].total_stun), "en")
              text_pos_x = stun_x-sign*stun_offset-sign*stun_width - 1 - 2 * sign
              if last_hit_history[i].player_id == 2 then
                text_pos_x = text_pos_x - text_width
              end
              text_pos_y = stun_y + (i - 1) * stun_height - 2
              render_text(text_pos_x, text_pos_y, string.format("%.2f", last_hit_history[i].total_stun), "en", nil, stun_color)
            else
              text_width = get_text_dimensions(tostring(math.round(last_hit_history[i].total_stun)), "en")
              text_pos_x = math.round(-1 * sign * (stun_width - text_width) / 2) + stun_x - sign*stun_offset
              if last_hit_history[i].player_id == 2 then
                text_pos_x = text_pos_x - text_width
              end
              text_pos_y = stun_y + (i - 1) * stun_height - 2
              render_text(text_pos_x, text_pos_y, tostring(math.round(last_hit_history[i].total_stun)), "en", nil, stun_color)
            end
          end
        end
      end
    end
  end
end

local function attack_data_display()
  local text_width1 = draw.get_text_width("damage: ")
  local text_width2 = draw.get_text_width("stun: ")
  local text_width3 = draw.get_text_width("combo: ")
  local text_width4 = draw.get_text_width("total damage: ")
  local text_width5 = draw.get_text_width("total stun: ")
  local text_width6 = draw.get_text_width("max combo: ")

  local x1 = 0
  local x2 = 0
  local x3 = 0
  local x4 = 0
  local x5 = 0
  local x6 = 0
  local y = 49

  local x_spacing = 80

  local data = attack_data.data

  if data.player_id == 1 then
    local base = draw.SCREEN_WIDTH - 138
    x1 = base - text_width1
    x2 = base - text_width2
    x3 = base - text_width3
    local base2 = base + x_spacing
    x4 = base2 - text_width4
    x5 = base2 - text_width5
    x6 = base2 - text_width6
  elseif data.player_id == 2 then
    local base = 82
    x1 = base - text_width1
    x2 = base - text_width2
    x3 = base - text_width3
    local base2 = base + x_spacing
    x4 = base2 - text_width4
    x5 = base2 - text_width5
    x6 = base2 - text_width6
  end

  gui.text(x1, y, string.format("damage: "))
  gui.text(x1 + text_width1, y, string.format("%d", data.damage))

  gui.text(x2, y + 10, string.format("stun: "))
  gui.text(x2 + text_width2, y + 10, string.format("%d", data.stun))

  gui.text(x3, y + 20, string.format("combo: "))
  gui.text(x3 + text_width3, y + 20, string.format("%d", data.combo))

  gui.text(x4, y, string.format("total damage: "))
  gui.text(x4 + text_width4, y, string.format("%d", data.total_damage))

  gui.text(x5, y + 10, string.format("total stun: "))
  gui.text(x5 + text_width5, y + 10, string.format("%d", data.total_stun))

  gui.text(x6, y + 20, string.format("max combo: "))
  gui.text(x6 + text_width6, y + 20, string.format("%d", data.max_combo))
end

local blocking_direction_history = {}
local last_dir = 1
local function update_blocking_direction(input, player, dummy)
  if (player.previous_pos_x - dummy.previous_pos_x) * (player.pos_x - dummy.pos_x) <= 0 then
  end
  if dummy.received_connection and settings.training.blocking_mode > 1 then
    table.insert(blocking_direction_history, {start_frame=gamestate.frame_number, dir=last_dir})
  end
  if dummy.blocking.last_blocked_frame == gamestate.frame_number then
    last_dir = 5
    if input[dummy.prefix.." Up"] == false then
      if input[dummy.prefix.." Down"] == false then
        if input[dummy.prefix.." Left"] == true then
          last_dir = 4
        elseif input[dummy.prefix.." Right"] == true then
          last_dir = 6
        end
      else
        if input[dummy.prefix.." Left"] == true then
          last_dir = 1
        elseif input[dummy.prefix.." Right"] == true then
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
local function blocking_direction_display(player, dummy)
  local offset_y = 10
  local i = 1
  while i <= #blocking_direction_history do
    local elapsed = gamestate.frame_number - blocking_direction_history[i].start_frame
    if elapsed <= blocking_direction_display_time + blocking_direction_fade_time then
      local opacity = 1
      if elapsed > blocking_direction_display_time then
        opacity = 1 - ((elapsed - blocking_direction_display_time) / blocking_direction_fade_time)
      end
      local x, y = draw.game_to_screen_space(dummy.pos_x, dummy.pos_y + character_specific[dummy.char_str].height)
      gui.image(x, y - (#blocking_direction_history - i - 1) * offset_y, images.img_dir_small[blocking_direction_history[i].dir], opacity)
    else
      table.remove(blocking_direction_history, i)
    end
    i = i + 1
  end
end

local function hitboxes_display()
  -- players
  local p1_filter = {["attack"]=true, ["throw"]=true} --debug
  local p2_filter = nil
  -- draw.draw_hitboxes(gamestate.P1.pos_x, gamestate.P1.pos_y, gamestate.P1.flip_x, gamestate.P1.boxes, fff, nil, nil, 0x90)

  draw.draw_hitboxes(gamestate.P1.pos_x, gamestate.P1.pos_y, gamestate.P1.flip_x, gamestate.P1.boxes, nil, nil, nil, 0x90)
  draw.draw_hitboxes(gamestate.P1.pos_x, gamestate.P1.pos_y, gamestate.P1.flip_x, gamestate.P1.boxes, p1_filter, nil, nil)
  draw.draw_hitboxes(gamestate.P2.pos_x, gamestate.P2.pos_y, gamestate.P2.flip_x, gamestate.P2.boxes, p2_filter, nil, nil, 0x90)

  -- projectiles
  for _, obj in pairs(gamestate.projectiles) do
    draw.draw_hitboxes(obj.pos_x, obj.pos_y, obj.flip_x, obj.boxes)
  end
end

local function bonuses_display(player_object)
  local x = 0
  local y = 4
  local padding = 4
  local spacing = 4
  local lang = lang_code[settings.training.language]
  if player_object.id == 1 then
    x = padding
  elseif player_object.id == 2 then
    x = draw.SCREEN_WIDTH - padding
  end
  if player_object.damage_bonus > 0 then
    -- gui.text(x, y, t, 0xFF7184FF, 0x392031FF)
    local text = {"+", player_object.damage_bonus, "bonus_damage"}
    local w, h = 0, 0
    if lang == "en" then
      w, h = get_text_dimensions_multiple(text)
    elseif lang == "jp" then
      w, h = get_text_dimensions_multiple(text, "jp", "8")
    end
    if player_object.id == 2 then
      x = x - w - spacing
    end
    if lang == "en" then
      render_text_multiple(x, y, text, "en", nil, colors.bonuses.damage)
    elseif lang == "jp" then
      render_text_multiple(x, y, text, "jp", "8", colors.bonuses.damage)
    end
    if player_object.id == 1 then
      x = x + w + spacing
    end
  end

  if player_object.defense_bonus > 0 then
    local text = {"+", player_object.defense_bonus, "bonus_defense"}
    local w, h = 0, 0
    if lang == "en" then
      w, h = get_text_dimensions_multiple(text)
    elseif lang == "jp" then
      w, h = get_text_dimensions_multiple(text, "jp", "8")
    end
    if player_object.id == 2 then
      x = x - w - spacing
    end
    if lang == "en" then
      render_text_multiple(x, y, text, "en", nil, colors.bonuses.defense)
    elseif lang == "jp" then
      render_text_multiple(x, y, text, "jp", "8", colors.bonuses.defense)
    end
    if player_object.id == 1 then
      x = x + w + spacing
    end  
  end

  if player_object.stun_bonus > 0 then
    local text = {"+", player_object.stun_bonus, "bonus_stun"}
    local w, h = 0, 0
    if lang == "en" then
      w, h = get_text_dimensions_multiple(text)
    elseif lang == "jp" then
      w, h = get_text_dimensions_multiple(text, "jp", "8")
    end
    if player_object.id == 2 then
      x = x - w - spacing
    end
    if lang == "en" then
      render_text_multiple(x, y, text, "en", nil, colors.bonuses.stun)
    elseif lang == "jp" then
      render_text_multiple(x, y, text, "jp", "8", colors.bonuses.stun)
    end
    if player_object.id == 1 then
      x = x + w + spacing
    end
  end
end

local printed_geometry = {}
-- push a persistent set of hitboxes to be drawn on the screen each frame
local function print_hitboxes(pos_x, pos_y, flip_x, boxes, filter, dilation)
  local g = {
    type = "hitboxes",
    x = pos_x,
    y = pos_y,
    flip_x = flip_x,
    boxes = boxes,
    filter = filter,
    dilation = dilation
  }
  table.insert(printed_geometry, g)
end

-- push a persistent point to be drawn on the screen each frame
local function print_point(pos_x, pos_y, color)
  local g = {
    type = "point",
    x = pos_x,
    y = pos_y,
    color = color
  }
  table.insert(printed_geometry, g)
end

local function clear_printed_geometry()
  printed_geometry = {}
end

local function display_draw_printed_geometry()
  -- printed geometry
  for _, geometry in ipairs(printed_geometry) do
    if geometry.type == "hitboxes" then
      draw.draw_hitboxes(geometry.x, geometry.y, geometry.flip_x, geometry.boxes, geometry.filter, geometry.dilation)
    elseif geometry.type == "point" then
      draw.draw_point(geometry.x, geometry.y, geometry.color)
    end
  end
end

local function life_text_display(player_object)
  local x = 0
  local y = 20

  local t = string.format("%d/160", player_object.life)

  if player_object.id == 1 then
    x = 13
  elseif player_object.id == 2 then
    x = draw.SCREEN_WIDTH - 11 - draw.get_text_width(t)
  end

  gui.text(x, y, t, 0xFFFB63FF)
end

local function meter_text_display(player_object)
  local x = 0
  local y = 214

  local gauge = player_object.meter_gauge

  if player_object.meter_count == player_object.max_meter_count then
    gauge = player_object.max_meter_gauge
  end

  local t = string.format("%d/%d", gauge, player_object.max_meter_gauge)

  if player_object.id == 1 then
    x = 53
  elseif player_object.id == 2 then
    x = draw.SCREEN_WIDTH - 51 - draw.get_text_width(t)
  end

  gui.text(x, y, t, 0x00FFCEFF, 0x001433FF)
end

local function stun_text_display(player_object)
  local x = 0
  local y = 28

  local t = string.format("%d/%d", math.floor(player_object.stun_bar), player_object.stun_max)

  if player_object.id == 1 then
    x = 167 - player_object.stun_max + 3
  elseif player_object.id == 2 then
    x = 216 + player_object.stun_max - draw.get_text_width(t) - 1
  end

  gui.text(x, y, t, 0xe60000FF, 0x001433FF)
end

local function display_draw_distances(p1_object, p2_object, mid_distance_height, p1_reference_point, p2_reference_point)

  local function find_closest_box_at_height(player_obj, height, box_types)

    local px = player_obj.pos_x
    local py = player_obj.pos_y

    local left, right = px, px

    if box_types == nil then
      return false, left, right
    end

    local has_boxes = false
    for __, box in ipairs(player_obj.boxes) do
      box = format_box(box)
      if box_types[box.type] then
        local l, r
        if player_obj.flip_x == 0 then
          l = px + box.left
        else
          l = px - box.left - box.width
        end
        local r = l + box.width
        local b = py + box.bottom
        local t = b + box.height

        if height >= b and height <= t then
          has_boxes = true
          left = math.min(left, l)
          right = math.max(right, r)
        end
      end
    end

    return has_boxes, left, right
  end

  local function get_screen_line_between_boxes(box1_l, box1_r, box2_l, box2_r)
    if not (
      (box1_l >= box2_r) or
      (box1_r <= box2_l)
    ) then
      return false
    end

    if box1_l < box2_l then
      return true, draw.draw.game_to_screen_space_x(box1_r), draw.draw.game_to_screen_space_x(box2_l)
    else
      return true, draw.draw.game_to_screen_space_x(box2_r), draw.draw.game_to_screen_space_x(box1_l)
    end
  end

  local text_default_color = 0xF7FFF7FF
  local text_default_border_color = 0x000000FF
  local function display_distance(p1_object, p2_object, height, box_types, p1_reference_point, p2_reference_point, color)
    local y = math.min(p1_object.pos_y + height, p2_object.pos_y + height)
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

    local line_result, screen_l, screen_r = get_screen_line_between_boxes(p1_l, p1_r, p2_l, p2_r)

    if line_result then
      local screen_y = draw.draw.game_to_screen_space_y(y)
      local str = string.format("%d", math.abs(screen_r - screen_l))
      draw.draw_horizontal_text_segment(screen_l, screen_r, screen_y, str, color)
    end
  end

  -- throw
  display_distance(p1_object, p2_object, 2, { throwable = true }, p1_reference_point, p2_reference_point, 0x08CF00FF)

  -- low and mid
  local hurtbox_types = {}
  hurtbox_types["vulnerability"] = true
  hurtbox_types["ext. vulnerability"] = true
  display_distance(p1_object, p2_object, 10, hurtbox_types, p1_reference_point, p2_reference_point, 0x00E7FFFF)
  display_distance(p1_object, p2_object, mid_distance_height, hurtbox_types, p1_reference_point, p2_reference_point, 0x00E7FFFF)

  -- player positions
  local line_color = 0xFFFF63FF
  local p1_screen_x, p1_screen_y = draw.game_to_screen_space(p1_object.pos_x, p1_object.pos_y)
  local p2_screen_x, p2_screen_y = draw.game_to_screen_space(p2_object.pos_x, p2_object.pos_y)
  draw.draw_point(p1_screen_x, p1_screen_y, line_color)
  draw.draw_point(p2_screen_x, p2_screen_y, line_color)
  gui.text(p1_screen_x + 3, p1_screen_y + 2, string.format("%d:%d", p1_object.pos_x, p1_object.pos_y), text_default_color, text_default_border_color)
  gui.text(p2_screen_x + 3, p2_screen_y + 2, string.format("%d:%d", p2_object.pos_x, p2_object.pos_y), text_default_color, text_default_border_color)
end

local function recording_display(dummy)
  local current_recording_size = 0
  if (recording_slots[settings.training.current_recording_slot].inputs) then
    current_recording_size = #recording_slots[settings.training.current_recording_slot].inputs
  end
  local x = 0
  local y = 4
  local padding = 4
  local lang = lang_code[settings.training.language]
  if current_recording_state == 2 then
    local text = {"hud_slot", " ", settings.training.current_recording_slot, ": ", "hud_wait_for_recording", " ", current_recording_size}
    local w, h = 0, 0
    if lang == "en" then
      w, h = get_text_dimensions_multiple(text)
    elseif lang == "jp" then
      w, h = get_text_dimensions_multiple(text, "jp", "8")
    end
    x = draw.SCREEN_WIDTH - w - padding
    y = padding
    if lang == "en" then
      render_text_multiple(x, y, text)
    elseif lang == "jp" then
      render_text_multiple(x, y, text, "jp", "8")
    end
  elseif current_recording_state == 3 then
    local text = {"hud_slot", " ", settings.training.current_recording_slot, ": ", "hud_recording", "... (", current_recording_size, ")"}
    local w, h = 0, 0
    if lang == "en" then
      w, h = get_text_dimensions_multiple(text)
    elseif lang == "jp" then
      w, h = get_text_dimensions_multiple(text, "jp", "8")
    end
    x = draw.SCREEN_WIDTH - w - padding
    y = padding
    if lang == "en" then
      render_text_multiple(x, y, text)
    elseif lang == "jp" then
      render_text_multiple(x, y, text, "jp", "8")
    end
  elseif current_recording_state == 4 and dummy.pending_input_sequence and dummy.pending_input_sequence.sequence then
    local text = {""}
    if settings.training.replay_mode == 1 or settings.training.replay_mode == 4 then
      text = {"hud_playing", " (", dummy.pending_input_sequence.current_frame, "/", #dummy.pending_input_sequence.sequence, ")"}
    else
      text = {"hud_playing"}
    end
    local w, h = 0, 0
    if lang == "en" then
      w, h = get_text_dimensions_multiple(text)
    elseif lang == "jp" then
      w, h = get_text_dimensions_multiple(text, "jp", "8")
    end
    x = draw.SCREEN_WIDTH - w - padding
    y = padding
    if lang == "en" then
      render_text_multiple(x, y, text)
    elseif lang == "jp" then
      render_text_multiple(x, y, text, "jp", "8")
    end
  end
end

local show_player_position = true
local function player_position_display()
  local x, y = draw.game_to_screen_space(gamestate.P1.pos_x, gamestate.P1.pos_y)
  gui.image(x - 4, y, images.img_dir_small[8])
  x, y = draw.game_to_screen_space(gamestate.P2.pos_x, gamestate.P2.pos_y)
  gui.image(x - 4 , y, images.img_dir_small[8])
end

local function draw_hud(player, dummy)
  if settings.training.display_attack_range ~= 1 then
    attack_range_display()
  end

  for k, boxes in pairs(to_draw_hitboxes) do
    if k >= gamestate.frame_number then
      if k - gamestate.frame_number <= 8 then
        draw.draw_hitboxes(unpack(boxes))
      end
    else
      to_draw_hitboxes[k] = nil
    end
  end

  if settings.training.display_hitboxes then
    hitboxes_display()
  end

  last_hit_bars()

  if settings.training.display_attack_data then
    attack_data_display()
  end
  red_parry_miss_display(player)
  blocking_direction_display(player, dummy)
  if settings.training.display_parry then
    parry_gauge_display(player.other)
  end
  if settings.training.display_charge then
    charge_display(player)
    -- charge_display(gamestate.P2)
  end
  if settings.training.display_air_time then
    air_time_display(player, dummy)
  end
  if show_player_position then
    player_position_display()
  end
  if current_recording_state ~= 1 then
    recording_display(dummy)
  end
  if settings.training.display_gauges then
    life_text_display(player)
    life_text_display(dummy)

    meter_text_display(player)
    meter_text_display(dummy)

    stun_text_display(player)
    stun_text_display(dummy)
  end
  if settings.training.display_bonuses then
    bonuses_display(player)
    bonuses_display(dummy)
  end
  if settings.training.display_distances then
    display_draw_distances(gamestate.P1, gamestate.P2, settings.training.mid_distance_height, settings.training.p1_distances_reference_point, settings.training.p2_distances_reference_point)
  end

  if show_jumpins_display then
    jumpins_display(player)
  end
--   draw_denjin(draw.SCREEN_WIDTH/2 - 40, draw.SCREEN_HEIGHT - 40)

end

return {
  draw_hud = draw_hud,
  attack_range_display_reset = attack_range_display_reset,
  update_blocking_direction = update_blocking_direction,
  red_parry_miss_display_reset = red_parry_miss_display_reset
}