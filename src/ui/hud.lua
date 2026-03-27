-- in-match displays
local settings = require("src.settings")
local fd = require("src.data.framedata")
local gamestate = require("src.gamestate")
local attack_data = require("src.data.attack_data")
local frame_advantage = require("src.data.frame_advantage")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local image_tables = require("src.ui.image_tables")
local recording = require("src.control.recording")
local tools = require("src.tools")
local inputs = require("src.control.inputs")
local prediction = require("src.data.prediction")

local character_specific = fd.character_specific
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple, render_images_inline =
   draw.render_text,
   draw.render_text_multiple,
   draw.get_text_dimensions,
   draw.get_text_dimensions_multiple,
   draw.render_images_inline
local Pools = tools.Pools

local menu

local info_text_display_time = 90
local info_text_fade_time = 30
local info_text_state = { { data = {}, display_start_frame = 0 }, { data = {}, display_start_frame = 0 } }
local function add_info_text(list, id)
   info_text_state[id].data = list
   info_text_state[id].display_start_frame = gamestate.frame_number
end

local function clear_info_text()
   tools.clear_table(info_text_state[1].data)
   tools.clear_table(info_text_state[2].data)
   info_text_state[1].display_start_frame = 0
   info_text_state[2].display_start_frame = 0
end

local function info_text_display()
   for id = 1, 2 do
      local elapsed = gamestate.frame_number - info_text_state[id].display_start_frame
      if elapsed <= info_text_display_time + info_text_fade_time then
         local opacity = 1
         if elapsed > info_text_display_time then
            opacity = 1 - ((elapsed - info_text_display_time) / info_text_fade_time)
         end
         local padding_x = 4
         local input_history_offset = 34
         local text_max_width = 50
         local text_max_height = 0
         local y = 50
         local spacing_y = 1

         for _, data in ipairs(info_text_state[id].data) do
            local width, height = 0, 0
            if type(data) == "table" then
               width, height = get_text_dimensions_multiple(data)
            else
               width, height = get_text_dimensions(data)
            end
            if width > text_max_width then
               text_max_width = width
            end
            if height > text_max_height then
               text_max_height = height
            end
         end

         local x = padding_x

         if id == 2 then
            x = draw.SCREEN_WIDTH - padding_x
            if settings.training.display_input_history == 3 or settings.training.display_input_history == 4 then
               x = x - input_history_offset
            end
         else
            if settings.training.display_input_history == 2 or settings.training.display_input_history == 4 then
               x = x + input_history_offset
            end
         end

         if id == 2 then
            x = x - text_max_width
         end

         for _, data in ipairs(info_text_state[id].data) do
            if type(data) == "table" then
               render_text_multiple(x, y, data, nil, nil, opacity)
            else
               render_text(x, y, data, nil, nil, opacity)
            end
            y = y + text_max_height + spacing_y
         end
      end
   end
end

local score_text = { "", "" }
local function add_score_text(id, str)
   score_text[id] = str
end
local function clear_score_text()
   tools.clear_table(score_text)
   score_text[1], score_text[2] = "", ""
end
local function score_text_display()
   for id, str in pairs(score_text) do
      if str ~= "" then
         local padding_x = 10
         local x, y = padding_x, 50
         local input_history_offset = 34

         if id == 2 then
            local w, h = get_text_dimensions(str, "score")
            x = draw.SCREEN_WIDTH - padding_x - w
            if settings.training.display_input_history == 3 or settings.training.display_input_history == 4 then
               x = x - input_history_offset
            end
         else
            if settings.training.display_input_history == 2 or settings.training.display_input_history == 4 then
               x = x + input_history_offset
            end
         end
         render_text(x, y, str, "score", colors.score.plus)
      end
   end
end

local kaiten_images

local function draw_kaiten(x, y, dirs, flip)
   -- input       2 4 6 8 2 4 6 8
   -- reorder to  6 2 4 8 6 2 4 8
   local dirs_ordered = tools.deepcopy(dirs)
   for i = 1, #dirs_ordered do
      if i % 4 == 3 then
         local d = table.remove(dirs_ordered, i)
         table.insert(dirs_ordered, i - 2, d)
      end
   end
   -- input       6 2 4 8 6 2 4 8
   -- reorder to  4 2 6 8 4 2 6 8
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
         draw.draw_image(x + offset_x, y, kaiten_images.active[(i - 1) % 4 + 1], nil, colors.text.default)
      else
         draw.draw_image(x + offset_x, y, kaiten_images.inactive[(i - 1) % 4 + 1], nil, colors.text.default)
      end
      offset_x = offset_x + 10
   end
end

local function parry_gauge_display(player)
   local pos_x = 235 -- 96
   local pos_y = 40
   local flip_gauge = false
   local gauge_x_scale = 4

   if settings.training.parry_follow_player then
      local offset_x = 8

      pos_x, pos_y =
         draw.game_to_screen_space(player.pos_x, player.pos_y + character_specific[player.char_str].height.standing.min)
      pos_x = pos_x + offset_x
      if player.flip_x == 1 then
         pos_x = pos_x - (22 * gauge_x_scale + offset_x + 16)
      end
      pos_y = pos_y
   end

   local y_offset = 0
   local group_y_margin = 6

   local function draw_parry_gauge_group(x, y, parry_object)
      local gauge_height = 5

      local x_border = 8

      local validity_gauge_width = parry_object.max_validity * gauge_x_scale
      local cooldown_gauge_width = parry_object.max_cooldown * gauge_x_scale

      x = math.min(math.max(x, x_border), draw.SCREEN_WIDTH - 2 * x_border - 22 * gauge_x_scale)

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
            validity_time_text = string.format("+%d", parry_object.delta)
         else
            validity_time_text = string.format("%d", parry_object.delta)
         end
      end

      local str = "parry_parry_" .. parry_object.name

      local font = settings.language_tag
      if font == "jp" then
         font = "jp_8"
      end

      render_text(x + 1, y, str, font)
      gui.box(cooldown_gauge_left + 1, y + 11, validity_gauge_left, y + 11, 0x00000000, colors.gauges.outline)
      gui.box(cooldown_gauge_left, y + 10, cooldown_gauge_left, y + 12, 0x00000000, colors.gauges.outline)
      gui.box(validity_gauge_right, y + 11, cooldown_gauge_right - 1, y + 11, 0x00000000, colors.gauges.outline)
      gui.box(cooldown_gauge_right, y + 10, cooldown_gauge_right, y + 12, 0x00000000, colors.gauges.outline)
      draw.draw_gauge(
         validity_gauge_left,
         y + 8,
         validity_gauge_width,
         gauge_height,
         parry_object.validity_time / parry_object.max_validity,
         colors.gauges.valid_fill,
         colors.gauges.background,
         colors.gauges.outline,
         true
      )
      draw.draw_gauge(
         cooldown_gauge_left,
         y + 8 + gauge_height + 1,
         cooldown_gauge_width,
         gauge_height - 1,
         parry_object.cooldown_time / parry_object.max_cooldown,
         colors.gauges.cooldown_fill,
         colors.gauges.background,
         colors.gauges.outline,
         true
      )

      gui.box(
         validity_gauge_left + 3 * gauge_x_scale,
         y + 8,
         validity_gauge_left + 2 + 3 * gauge_x_scale,
         y + 8 + gauge_height + 1,
         colors.gauges.outline,
         0x00000000
      )

      if parry_object.delta then
         local marker_x = validity_gauge_left + parry_object.delta * gauge_x_scale
         marker_x = math.min(math.max(marker_x, x), cooldown_gauge_right)
         gui.box(
            marker_x,
            y + 7,
            marker_x + gauge_x_scale,
            y + 8 + gauge_height,
            validity_text_color,
            validity_outline_color
         )
      end

      render_text(cooldown_gauge_right + 4, y + 7, validity_time_text, "en", validity_text_color)
      render_text(cooldown_gauge_right + 4, y + 13, cooldown_time_text, "en", validity_text_color)

      return 8 + 5 + (gauge_height * 2)
   end

   local parry_array = Pools.draw:alloc()
   parry_array[1] = Pools.draw:alloc()
   parry_array[1].object = player.parry_forward
   parry_array[1].enabled = true
   parry_array[2] = Pools.draw:alloc()
   parry_array[2].object = player.parry_down
   parry_array[2].enabled = true
   parry_array[3] = Pools.draw:alloc()
   parry_array[3].object = player.parry_air
   parry_array[3].enabled = true
   parry_array[4] = Pools.draw:alloc()
   parry_array[4].object = player.parry_antiair
   parry_array[4].enabled = true

   if settings.training.display_parry_compact then
      local parry_display_timeout = 60
      for _, parry in ipairs(parry_array) do
         parry.enabled = false
         if gamestate.frame_number - parry.object.last_attempt_frame < parry_display_timeout then
            parry.enabled = true
         end
      end
   end

   for _, parry in ipairs(parry_array) do
      if parry.enabled then
         y_offset = y_offset + group_y_margin + draw_parry_gauge_group(pos_x, pos_y + y_offset, parry.object)
      end
   end
end

local function charge_display(player)
   local pos_x = 272 -- 96
   if settings.training.charge_overcharge_on then
      pos_x = 264
   end
   local pos_y = 46
   local flip_gauge = false
   local gauge_x_scale = 2

   if settings.training.charge_follow_player then
      local offset_x = 8

      pos_x, pos_y =
         draw.game_to_screen_space(player.pos_x, player.pos_y + character_specific[player.char_str].height.standing.min)
      pos_x = pos_x + offset_x
      if player.flip_x == 1 then
         pos_x = pos_x - (43 * gauge_x_scale + offset_x + 16)
      end
      pos_y = pos_y
   end

   local y_offset = 0
   local group_y_margin = 6
   local gauge_height = 4
   local overcharge_color = colors.charge.overcharge
   local x_border = 16

   local font = settings.language_tag
   if font == "jp" then
      font = "jp_8"
   end

   local function draw_charge_gauge_group(x, y, charge_object)
      local charge_gauge_width = charge_object.max_charge * gauge_x_scale
      local reset_gauge_width = charge_object.max_reset * gauge_x_scale

      x = math.min(math.max(x, x_border), draw.SCREEN_WIDTH - x_border - charge_gauge_width)

      local charge_gauge_left = math.floor(x + (reset_gauge_width - charge_gauge_width) * 0.5)
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

      if font == "jp_8" then
         name_y_offset = -1
      end
      render_text(x + 1, y + name_y_offset, charge_object.name, font)
      draw.draw_gauge(
         charge_gauge_left,
         y + 8,
         charge_gauge_width,
         gauge_height,
         charge_object.charge_time / charge_object.max_charge,
         colors.gauges.valid_fill,
         colors.gauges.background,
         colors.gauges.outline,
         true
      )
      draw.draw_gauge(
         reset_gauge_left,
         y + 8 + gauge_height + 1,
         reset_gauge_width,
         gauge_height - 1,
         charge_object.reset_time / charge_object.max_reset,
         colors.gauges.cooldown_fill,
         colors.gauges.background,
         colors.gauges.outline,
         true
      )
      if settings.training.charge_overcharge_on and charge_object.overcharge ~= 0 and charge_object.overcharge < 42 then
         draw.draw_gauge(
            charge_gauge_left,
            y + 8,
            charge_gauge_width,
            gauge_height,
            charge_object.overcharge / charge_object.max_charge,
            overcharge_color,
            colors.gauges.background,
            colors.gauges.outline,
            true
         )
         local w = get_text_dimensions(charge_time_text, "en")
         render_text(reset_gauge_right + 4 + w, y + 7, overcharge_time_text, "en", charge_text_color)
      end
      if
         settings.training.charge_overcharge_on
         and charge_object.overcharge == 0
         and charge_object.last_overcharge > 0
         and charge_object.last_overcharge < 42
      then
         local w = get_text_dimensions(charge_time_text, "en")
         render_text(reset_gauge_right + 4 + w, y + 7, last_overcharge_time_text, "en", charge_text_color)
      end

      render_text(reset_gauge_right + 4, y + 7, charge_time_text, "en", charge_text_color)
      render_text(reset_gauge_right + 4, y + 13, reset_time_text, "en")

      return 8 + 5 + (gauge_height * 2)
   end

   local function draw_kaiten_gauge_group(x, y, kaiten_object)
      local charge_gauge_width = 43 * gauge_x_scale
      local reset_gauge_width = 43 * gauge_x_scale

      x = math.min(math.max(x, x_border), draw.SCREEN_WIDTH - x_border - charge_gauge_width)

      local reset_gauge_left = x
      local reset_gauge_right = reset_gauge_left + reset_gauge_width + 1
      local validity_time_text = ""
      if kaiten_object.validity_time > 0 then
         validity_time_text = string.format("%d", kaiten_object.validity_time)
      end
      local reset_time_text = string.format("%d", kaiten_object.reset_time)

      local name_y_offset = 0
      if font == "jp_8" then
         name_y_offset = -1
      end

      render_text(x + 1, y + name_y_offset, "charge_" .. kaiten_object.name, font)

      draw_kaiten(x, y + 8, kaiten_object.directions, not player.flip_input)

      draw.draw_gauge(
         reset_gauge_left,
         y + 8 + 9,
         reset_gauge_width,
         gauge_height,
         kaiten_object.reset_time / kaiten_object.max_reset,
         colors.gauges.cooldown_fill,
         colors.gauges.background,
         colors.gauges.outline,
         true
      )

      render_text(reset_gauge_right + 4, y + 10, validity_time_text, "en")
      render_text(reset_gauge_right + 4, y + 17, reset_time_text, "en")

      return 8 + 5 + 9 + gauge_height
   end

   local function draw_legs_gauge_group(x, y, legs_object)
      local width = 43 * gauge_x_scale
      local style = draw.controller_styles[settings.controller_style]
      local tw, th = get_text_dimensions("hud_hyakuretsu_MK", font)
      local margin = tw + 1
      local x_offset = margin
      render_text(x, y, "hud_hyakuretsu_LK", font)
      for i = 1, legs_object.l_legs_count do
         draw.draw_image(x + x_offset, y, "img_LK_s", nil, style)
         x_offset = x_offset + 8
      end
      x_offset = margin
      render_text(x, y + 8, "hud_hyakuretsu_MK", font)
      for i = 1, legs_object.m_legs_count do
         draw.draw_image(x + x_offset, y + 8, "img_MK_s", nil, style)
         x_offset = x_offset + 8
      end
      x_offset = margin
      render_text(x, y + 16, "hud_hyakuretsu_HK", font)
      for i = 1, legs_object.h_legs_count do
         draw.draw_image(x + x_offset, y + 16, "img_HK_s", nil, style)
         x_offset = x_offset + 8
      end
      x_offset = margin

      if legs_object.active ~= 0xFF then
         draw.draw_gauge(
            x,
            y + 24,
            width,
            gauge_height,
            legs_object.reset_time / 99,
            colors.gauges.cooldown_fill,
            colors.gauges.background,
            colors.gauges.outline,
            true
         )
      end

      return 8 + 5 + (gauge_height * 2)
   end

   local charge_array = Pools.draw:alloc()
   charge_array[1] = Pools.draw:alloc()
   charge_array[1].object = player.charge_1
   charge_array[1].enabled = player.charge_1.enabled
   charge_array[2] = Pools.draw:alloc()
   charge_array[2].object = player.charge_2
   charge_array[2].enabled = player.charge_2.enabled
   charge_array[3] = Pools.draw:alloc()
   charge_array[3].object = player.charge_3
   charge_array[3].enabled = player.charge_3.enabled

   for _, charge in ipairs(charge_array) do
      if charge.enabled then
         y_offset = y_offset + group_y_margin + draw_charge_gauge_group(pos_x, pos_y + y_offset, charge.object)
      end
   end

   if player.char_str == "hugo" or (player.char_str == "alex" and player.selected_sa == 1) then
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
local air_time_bar_max_height = 3
local function air_time_display(player, dummy)
   local offset_x = 226
   local offset_y = 50
   local juggle_count = memory.readbyte(dummy.addresses.juggle_count)
   local air_time = math.floor((memory.readbyte(dummy.addresses.juggle_time) + 1) / 2)
   local air_time_bar_width = tools.round((air_time / 121) * air_time_bar_max_width)
   local x, y = get_text_dimensions(tostring(juggle_count), "en")
   render_text(offset_x - x, offset_y - 1, juggle_count, "en")
   offset_x = offset_x + 3

   if air_time ~= 128 then
      if air_time > 0 then
         x, y = get_text_dimensions(tostring(air_time), "en")
         render_text(offset_x - x / 2 + air_time_bar_width, offset_y + 6, air_time, "en")
      end
   end
   draw.draw_gauge(
      offset_x,
      offset_y,
      air_time_bar_max_width,
      air_time_bar_max_height,
      air_time / 121,
      colors.gauges.cooldown_fill,
      colors.gauges.background,
      colors.gauges.outline,
      false
   )
   if dummy.pos_y > 0 and air_time == 128 then
      color_player(dummy, air_combo_expired_color)
   else
      color_player(dummy, "default")
   end
end

local denjin_display_bar_max_width = 80
local denjin_display_bar_max_height = 2
local denjin_display_text_padding = 4
local denjin_display_is_charging = false
local denjin_time = 8
local denjin_value = 3
local function denjin_display(player)
   if not (player.char_str == "ryu" and player.selected_sa == 3) then
      return
   end
   local x, y =
      draw.game_to_screen_space(player.pos_x, player.pos_y + character_specific[player.char_str].height.standing.max)
   x = x - denjin_display_bar_max_width / 2
   y = y - 6 - denjin_display_bar_max_height

   if player.superfreeze_decount > 0 then
      denjin_time = 8
      denjin_value = 3
      denjin_display_is_charging = true
   end
   if not (player.animation == "774c" or player.animation == "90b4") then
      denjin_display_is_charging = false
   end
   if denjin_display_is_charging and player.superfreeze_decount == 0 then
      denjin_time = memory.readbyte(player.addresses.denjin_time)
      denjin_value = memory.readbyte(player.addresses.denjin_level)
   end

   local barColor = colors.gauges.denjin
   local denjin_level = ""
   local max_timer = 8
   if denjin_value == 3 then
      denjin_level = "I"
      max_timer = 8
      barColor = colors.colorscale(colors.gauges.denjin, 0.8)
   elseif denjin_value == 9 then
      denjin_level = "II"
      max_timer = 24
      barColor = colors.gauges.denjin
   elseif denjin_value == 14 then
      denjin_level = "III"
      max_timer = 48
      barColor = colors.colorscale(colors.gauges.denjin, 1.5)
   elseif denjin_value == 19 then
      denjin_level = "IV"
      max_timer = 80
      barColor = colors.colorscale(colors.gauges.denjin, 2)
      if denjin_time == 0 then
         denjin_level = "V"
         barColor = colors.colorscale(colors.gauges.denjin, 2.5)
      end
   end
   local denjin_display_bar_width = (max_timer - denjin_time) / max_timer * denjin_display_bar_max_width
   local w, h = get_text_dimensions(denjin_level, "en")
   render_text(x - w - denjin_display_text_padding + 1, y, denjin_level, "en")
   render_text(
      x + denjin_display_bar_max_width + denjin_display_text_padding,
      y,
      tostring(max_timer - denjin_time),
      "en"
   )
   y = y + 2
   draw.draw_gauge(
      x,
      y,
      denjin_display_bar_max_width,
      denjin_display_bar_max_height,
      denjin_display_bar_width / denjin_display_bar_max_width,
      barColor,
      colors.gauges.background,
      colors.gauges.outline,
      false
   )
end

local recovery_display_data = {
   recovery_bar_max_width = 80,
   recovery_bar_max_height = 3,
   recovery_bar_max_value = 20,
   throw_invul_bar_max_width = 80,
   throw_invul_bar_max_height = 3,
   throw_invul_bar_max_value = 6,

   color_map = {
      [1] = { default = 0x42002000, freeze = 0x20032003, throw_invul = 0x205A205A },
      [2] = { default = 0x42002010, freeze = 0x20032013, throw_invul = 0x205B205B },
   },
}

local recovery_display_bar = {
   height = 3,
   max_value = 16,
   scale = 4,
   display_time = 30,
   fade_time = 20,
}
recovery_display_bar.width = recovery_display_bar.max_value * recovery_display_bar.scale

local RECOVERY_STATE = {
   ATTACKING = 1,
   ATTACKING_RECOVERY = 2,
   DEFENDING = 3,
   DEFENDING_RECOVERY = 4,
   THROW_INVUL = 5,
   LANDING = 6,
   WAKING_UP = 7,
}
local recovery_state = { { state = RECOVERY_STATE.ATTACKING, bar_value = 0, bar_max_value = 0, start_frame = 0 }, {} }

local function update_recovery_display()
   for _, player in ipairs(gamestate.player_objects) do
      local x, y = draw.get_above_character_position(player, false)
      x = x - recovery_display_bar.max_value * recovery_display_bar.scale / 2
      local bar_ratio = player.recovery_time / recovery_display_bar.max_value
      local bar_color = 0x991111ff
      draw.draw_gauge(
         x,
         y,
         recovery_display_bar.width,
         recovery_display_bar.height,
         bar_ratio,
         bar_color,
         colors.gauges.background,
         colors.gauges.outline,
         false
      )

      if player.character_state_byte == 4 and player.current_hit_id == player.max_hit_id then
      elseif player.has_recovery_just_started then
      elseif player.throw_invulnerability_cooldown == 6 then
      end
      if player.is_airborne and player.is_in_air_recovery and player.previous_pos_y > player.pos_y then
         local frames_until_landing = prediction.predict_frames_before_landing(player)
         if frames_until_landing <= 1 then
            memory.writedword(player.addresses.palette, recovery_display_data.color_map[player.id].throw_invul)
         end
      elseif player.has_just_been_hit or player.has_just_blocked then
         memory.writedword(player.addresses.palette, recovery_display_data.color_map[player.id].freeze)
      elseif player.throw_invulnerability_cooldown == 1 then
         memory.writedword(player.addresses.palette, recovery_display_data.color_map[player.id].default)
      elseif
         player.character_state_byte == 1
         and player.remaining_freeze_frames == 0
         and not player.freeze_just_ended
         and player.recovery_time + player.additional_recovery_time == 0
      then
         memory.writedword(player.addresses.palette, recovery_display_data.color_map[player.id].throw_invul)
      elseif player.is_waking_up and player.posture_ext >= 0x40 and player.remaining_wakeup_time <= 1 then
         memory.writedword(player.addresses.palette, recovery_display_data.color_map[player.id].throw_invul)
      end
   end
end

local function recovery_display(recovery_display_settings)
   for i, player in ipairs(gamestate.player_objects) do
      local x, y = draw.get_above_character_position(player)
      local data = recovery_state[i]
      local elapsed = data.elapsed
      if elapsed <= data.display_time + data.fade_time then
         local opacity = 1
         if elapsed > data.display_time then
            opacity = 1 - ((elapsed - data.display_time) / data.fade_time)
         end

         if group_name ~= "default" then
            local w, h
            if type(data.text) == "table" then
               w, h = get_text_dimensions_multiple(data.text)
            else
               w, h = get_text_dimensions(data.text)
            end
            offset_y = offset_y + h + 1
         end
         data.elapsed = data.elapsed + 1
         if data.animate then
            data.y = data.y - 0.25
         end
      else
         table.remove(group, i)
      end
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
--     Queue_Command(gamestate.frame_number + 1, function(n) memory.writeword(player.base + 616, n) end, {0x0015})
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

local fading_text_display_time_default = 90
local fading_text_fade_time_default = 30
local fading_text_data = {}

local function add_fading_text(x, y, text, lang, color, display_time, fade_time, animate, group)
   local data = {
      x = x,
      y = y,
      text = text,
      lang = lang or settings.language_tag,
      color = color or colors.text.default,
      display_time = display_time or fading_text_display_time_default,
      fade_time = fade_time or fading_text_fade_time_default,
      animate = animate,
      elapsed = 0,
   }
   group = group or "default"
   if not fading_text_data[group] then
      fading_text_data[group] = {}
   end
   table.insert(fading_text_data[group], data)
   return data
end

local function clear_fading_text()
   tools.clear_table(fading_text_data)
end

local function fading_text_display()
   for group_name, group in pairs(fading_text_data) do
      local i = 1
      local offset_y = 0
      while i <= #group do
         local data = group[i]
         local elapsed = data.elapsed
         if elapsed <= data.display_time + data.fade_time then
            local opacity = 1
            if elapsed > data.display_time then
               opacity = 1 - ((elapsed - data.display_time) / data.fade_time)
            end
            if type(data.text) == "table" then
               render_images_inline(data.x, data.y + offset_y, data.text, data.lang, data.color, opacity)
            else
               render_text(data.x, data.y + offset_y, data.text, data.lang, data.color, opacity)
            end
            if group_name ~= "default" then
               local w, h
               if type(data.text) == "table" then
                  w, h = get_text_dimensions_multiple(data.text)
               else
                  w, h = get_text_dimensions(data.text)
               end
               offset_y = offset_y + h + 1
            end
            data.elapsed = data.elapsed + 1
            if data.animate then
               data.y = data.y - 0.25
            end
         else
            table.remove(group, i)
         end
         i = i + 1
      end
   end
end

local red_parry_miss_watch_data = {
   { should_watch = false, last_blocking_frame = 0 },
   { should_watch = false, last_blocking_frame = 0 },
}
local red_parry_miss_display_data = { x = 0, y = 0, text = "", display_time = 60, fade_time = 20 }
local red_parry_miss_max_late_frames = 10

local function red_parry_miss_display_reset(id)
   if id then
      tools.clear_table(red_parry_miss_watch_data[id])
      red_parry_miss_watch_data[id].should_watch = false
      red_parry_miss_watch_data[id].last_blocking_frame = 0
   else
      tools.clear_table(red_parry_miss_watch_data[1])
      red_parry_miss_watch_data[1].should_watch = false
      red_parry_miss_watch_data[1].last_blocking_frame = 0
      tools.clear_table(red_parry_miss_watch_data[2])
      red_parry_miss_watch_data[2].should_watch = false
      red_parry_miss_watch_data[2].last_blocking_frame = 0
   end
end

local function red_parry_miss_display(player)
   if player.has_just_blocked then
      red_parry_miss_watch_data[player.id].should_watch = true
   end
   if player.is_blocking then
      red_parry_miss_watch_data[player.id].last_blocking_frame = gamestate.frame_number
   end
   if
      gamestate.frame_number - red_parry_miss_watch_data[player.id].last_blocking_frame
      > red_parry_miss_max_late_frames
   then
      red_parry_miss_display_reset(player.id)
   end
   if red_parry_miss_watch_data[player.id].should_watch then
      local is_being_hit = not player.is_blocking and player.character_state_byte == 1
      local parry_objects = Pools.draw:alloc()
      parry_objects[1], parry_objects[2] = player.parry_forward, player.parry_down
      for _, parry_object in ipairs(parry_objects) do
         if parry_object.validity_time > 0 then
            red_parry_miss_watch_data[player.id][parry_object.name] = true
         end
         if
            red_parry_miss_watch_data[player.id][parry_object.name]
            and (
               player.has_just_been_hit
               or (parry_object.previous_validity_time > 0 and parry_object.validity_time <= 0)
               or is_being_hit
            )
         then
            if parry_object.delta then
               red_parry_miss_display_reset(player.id)
               if not parry_object.success then
                  local img_str_parry = (parry_object.name == "down" and "img_2_dir_s")
                     or (player.side == 1 and "img_6_dir_s")
                     or "img_4_dir_s"
                  if parry_object.delta >= 0 then
                     red_parry_miss_display_data.text = string.format("+%d", parry_object.delta)
                  else
                     red_parry_miss_display_data.text = string.format("%d", parry_object.delta)
                  end
                  local sign = player.flip_x == 0 and 1 or -1

                  red_parry_miss_display_data.x = player.pos_x
                     - sign * character_specific[player.char_str].half_width * 3 / 4
                  red_parry_miss_display_data.y = player.pos_y
                     + character_specific[player.char_str].height.standing.max * 3 / 4
                  local x, y = draw.game_to_screen_space(red_parry_miss_display_data.x, red_parry_miss_display_data.y)
                  local text = { red_parry_miss_display_data.text, " ", img_str_parry }
                  add_fading_text(
                     x,
                     y,
                     text,
                     "en",
                     colors.input.red_parry,
                     red_parry_miss_display_data.display_time,
                     red_parry_miss_display_data.fade_time
                  )
               end
            end
         end
      end
   end
end

local input_attempt_categories = {
   guard_jumps = {
      [inputs.MOTIONS.GUARD_JUMP] = true,
   },
   option_parries = {
      [inputs.MOTIONS.PARRY_HIGH_THROW] = true,
      [inputs.MOTIONS.PARRY_LOW_THROW] = true,
      [inputs.MOTIONS.FORWARD_DOWN] = true,
      [inputs.MOTIONS.DOWN_FORWARD] = true,
      [inputs.MOTIONS.PARRY_DASH] = true,
      [inputs.MOTIONS.PARRY_LOW_JUMP] = true,
   },
   throws = {
      [inputs.MOTIONS.PARRY_HIGH_THROW] = true,
      [inputs.MOTIONS.PARRY_LOW_THROW] = true,
      [inputs.MOTIONS.CROUCH_TECH] = true,
      [inputs.MOTIONS.LATE_TECH] = true,
      [inputs.MOTIONS.STAND_TECH] = true,
   },
   parries = { [inputs.MOTIONS.PARRY_HIGH] = true, [inputs.MOTIONS.PARRY_LOW] = true },
   red_parries = {
      [inputs.MOTIONS.RED_PARRY_HIGH] = true,
      [inputs.MOTIONS.RED_PARRY_LOW] = true,
   },
   moves = {
      [inputs.MOTIONS.SGS] = true,
      [inputs.MOTIONS["720"]] = true,
      [inputs.MOTIONS.KKZ] = true,
      [inputs.MOTIONS.DQCF] = true,
      [inputs.MOTIONS["360"]] = true,
      [inputs.MOTIONS.VCHARGE] = true,
      [inputs.MOTIONS.HCHARGE] = true,
      [inputs.MOTIONS.HIGH_JUMP_CANCEL] = true,
      [inputs.MOTIONS.HCF] = true,
      [inputs.MOTIONS.HCB] = true,
      [inputs.MOTIONS.SRK] = true,
      [inputs.MOTIONS.QCF] = true,
      [inputs.MOTIONS.SRKB] = true,
      [inputs.MOTIONS.QCB] = true,
      [inputs.MOTIONS.THROW] = true,
      [inputs.MOTIONS.UOH] = true,
      [inputs.MOTIONS.PA] = true,
      [inputs.MOTIONS.DASH_FORWARD] = true,
      [inputs.MOTIONS.DASH_BACK] = true,
      [inputs.MOTIONS.BLOCK_HIGH] = true,
      [inputs.MOTIONS.BLOCK_LOW] = true,
   },
}

local input_attempt_motions = { {}, {} }

local function init_motions()
   for id, player in ipairs(gamestate.player_objects) do
      for order, motion in ipairs(inputs.MOTION_PRIORITY) do
         input_attempt_motions[id][order] = { motion = motion, last_match_frame = 0, matching_inputs = {} }
      end
   end
end

local function reset_motions()
   for id, player in ipairs(gamestate.player_objects) do
      for _, motion_data in ipairs(input_attempt_motions[id]) do
         motion_data.last_match_frame = 0
         tools.clear_table(motion_data.matching_inputs)
      end
   end
end

init_motions()


local input_attempt_cooldowns = {
   guard_jumps = 0,
   option_parries = 10,
   throws = 2,
   parries = 10,
   red_parries = 0,
   moves = 0,
}

local input_attempt_display_data = { display_time = 30, fade_time = 30 }
local input_attempt_state, input_attempt_watch
local function input_attempt_reset()
   input_attempt_state = {
      {
         input_start_frame = 0,
         motion = 0,
         matched_inputs = {},
         draw_data = nil,
         image_ref = nil,
         is_drawn = false,
         is_parrying = false,
         parry_start_frame = 0,
      },
      {
         input_start_frame = 0,
         motion = 0,
         matched_inputs = {},
         draw_data = nil,
         image_ref = nil,
         is_drawn = false,
         is_parrying = false,
         parry_start_frame = 0,
      },
   }
   input_attempt_watch = {
      {
         guard_jumps = {
            should_match = false,
            cooldown = 0,
         },
         option_parries = {
            should_match = false,
            cooldown = 0,
         },
         throws = {
            should_match = false,
            cooldown = 0,
         },
         parries = {
            should_match = false,
            cooldown = 0,
         },
         red_parries = {
            should_match = false,
            cooldown = 0,
         },
         moves = {
            should_match = false,
            cooldown = 0,
         },
      },
      {
         guard_jumps = {
            should_match = false,
            cooldown = 0,
         },
         option_parries = {
            should_match = false,
            cooldown = 0,
         },
         throws = {
            should_match = false,
            cooldown = 0,
         },
         parries = {
            should_match = false,
            cooldown = 0,
         },
         red_parries = {
            should_match = false,
            cooldown = 0,
         },
         moves = {
            should_match = false,
            cooldown = 0,
         },
      },
   }
end

input_attempt_reset()

local function get_input_attempt_draw_data(player, motion, matched_inputs)
   local images, color
   local x, y = draw.get_above_character_position(player)
   y = y - 2
   if motion == inputs.MOTIONS.GUARD_JUMP then
      local dir = matched_inputs[#matched_inputs - 1].inputs[1].direction_raw
      if dir == inputs.DIR.UP then
         dir = matched_inputs[#matched_inputs - 2].inputs[1].direction_raw
      end
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { "img_shield", " ", img_dir_str }
   elseif motion == inputs.MOTIONS.PARRY_LOW_JUMP then
      local dir = matched_inputs[#matched_inputs].inputs[1].direction_raw
      if dir == inputs.DIR.UP then
         dir = matched_inputs[#matched_inputs - 1].inputs[1].direction_raw
      end
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { "img_2_dir_s", " ", img_dir_str }
      color = { colors.input.parry, nil, colors.text.default }
   elseif motion == inputs.MOTIONS.FORWARD_DOWN then
      local dir = matched_inputs[2].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { img_dir_str, " ", "img_2_dir_s" }
      color = { colors.input.parry, nil, colors.input.parry }
   elseif motion == inputs.MOTIONS.DOWN_FORWARD then
      local dir = matched_inputs[4].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { "img_2_dir_s", " ", img_dir_str }
      color = { colors.input.parry, nil, colors.input.parry }
   elseif motion == inputs.MOTIONS.PARRY_DASH then
      local dir = matched_inputs[#matched_inputs].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { img_dir_str, " ", img_dir_str }
      color = { colors.input.parry, nil, colors.text.default }
   elseif motion == inputs.MOTIONS.PARRY_HIGH_THROW then
      local dir = matched_inputs[2].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      local style = draw.controller_styles[settings.controller_style]
      images = { img_dir_str, " ", "img_LP_s", "img_LK_s" }
      color = { colors.input.parry, nil, style, style }
   elseif motion == inputs.MOTIONS.PARRY_LOW_THROW then
      local style = draw.controller_styles[settings.controller_style]
      images = { "img_2_dir_s", " ", "img_LP_s", "img_LK_s" }
      color = { colors.input.parry, nil, style, style }
   elseif motion == inputs.MOTIONS.CROUCH_TECH then
      local dir = matched_inputs[1].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      local style = draw.controller_styles[settings.controller_style]
      images = { img_dir_str, " ", "img_LP_s", "img_LK_s" }
      color = { colors.text.default, nil, style, style }
   elseif motion == inputs.MOTIONS.LATE_TECH then
      local dir = matched_inputs[1].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      dir = matched_inputs[2].inputs[1] and matched_inputs[2].inputs[1].direction_raw
         or matched_inputs[3].inputs[1].direction_raw
      local img_dir_str_2 = image_tables.img_str_dir_small[dir]
      local style = draw.controller_styles[settings.controller_style]
      images = { img_dir_str, " ", img_dir_str_2, " ", "img_LP_s", "img_LK_s" }
      color = { colors.text.default, nil, colors.text.default, nil, style, style }
   elseif motion == inputs.MOTIONS.STAND_TECH then
      local dir = matched_inputs[1].inputs[1].direction_raw
      local style = draw.controller_styles[settings.controller_style]
      images = { "img_LP_s", "img_LK_s" }
      color = { style, style }
      if dir ~= inputs.DIR.NEUTRAL then
         local img_dir_str = image_tables.img_str_dir_small[dir]
         table.insert(images, 1, " ")
         table.insert(color, 1, nil)
         table.insert(images, 1, img_dir_str)
         table.insert(color, 1, colors.text.default)
      end
   elseif motion == inputs.MOTIONS.HIGH_JUMP_CANCEL then
      images = { "hud_HJC" }
   elseif motion == inputs.MOTIONS.PARRY_HIGH then
      local dir = matched_inputs[2].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { img_dir_str }
      color = { colors.input.parry }
   elseif motion == inputs.MOTIONS.PARRY_LOW then
      images = { "img_2_dir_s" }
      color = { colors.input.parry }
   elseif motion == inputs.MOTIONS.RED_PARRY_HIGH then
      local dir = matched_inputs[2].inputs[1].direction_raw
      local img_dir_str = image_tables.img_str_dir_small[dir]
      images = { img_dir_str }
      color = { colors.input.red_parry }
   elseif motion == inputs.MOTIONS.RED_PARRY_LOW then
      images = { "img_2_dir_s" }
      color = { colors.input.red_parry }
   end
   local w, h = get_text_dimensions_multiple(images)
   local group = player.is_grounded and "ground" or "default"
   return { x = x - w / 2, y = y, images = images, color = color, group = group }
end

local function draw_input_attempt(draw_data)
   return add_fading_text(
      draw_data.x,
      draw_data.y,
      draw_data.images,
      "en",
      draw_data.color,
      input_attempt_display_data.display_time,
      input_attempt_display_data.fade_time,
      nil,
      draw_data.group
   )
end

local function update_input_attempt(input_attempt_settings, selected_moves)
   for id, player in ipairs({ gamestate.player_objects[1] }) do
      local motion, matched_inputs
      if
         (
            player.has_just_ended_recovery
            and player.previous_character_state_byte == 1
            and gamestate.is_ground_state(player, player.standing_state)
         )
         or player.has_just_landed
         or player.has_just_woke_up
      then
         input_attempt_watch[id].guard_jumps.should_match = true
      end
      if not player.is_in_air_reel then
         input_attempt_watch[id].throws.should_match = true
      end
      if
         not input_attempt_state[id].is_parrying and gamestate.is_ground_state(player, player.standing_state)
         or (player.is_airborne and not player.is_in_air_reel)
         or (player.is_waking_up and player.remaining_wakeup_time > 0 and player.remaining_wakeup_time <= 10)
      then
         input_attempt_watch[id].parries.should_match = true
      end
      if input_attempt_state[id].is_parrying then
         input_attempt_watch[id].option_parries.should_match = true
      end

      if player.is_blocking and (player.remaining_freeze_frames > 0 or player.recovery_time >= 4) then
         input_attempt_watch[id].red_parries.should_match = true
      end

      for _, watch in pairs(input_attempt_watch[id]) do
         if watch.cooldown > 0 then
            watch.cooldown = watch.cooldown - 1
            if watch.cooldown > 0 then
               watch.should_match = false
            end
         end
      end

      motion, matched_inputs =
         inputs.match_motion_list(player, input_attempt_motions[id])

      if motion and matched_inputs then
         -- print(matched_inputs)
         for category, watch in pairs(input_attempt_watch[id]) do
            if watch.should_match and input_attempt_categories[category][motion] then
               -- print("draw", input_attempt_state[id].input_start_frame)
               for k, v in pairs(inputs.MOTIONS) do
                  if v == motion then
                     print(k)
                     break
                  end
               end

               watch.should_match = false
               watch.cooldown = input_attempt_cooldowns[category]
               input_attempt_state[id].previous_motion = input_attempt_state[id].motion
               input_attempt_state[id].motion = motion
               input_attempt_state[id].matched_inputs = matched_inputs
               input_attempt_state[id].input_start_frame = gamestate.frame_number + 1
               input_attempt_state[id].draw_data = get_input_attempt_draw_data(player, motion, matched_inputs)
               if category == "parries" then
                  input_attempt_state[id].parry_start_frame = matched_inputs[1].inputs[1].start_frame
                     + matched_inputs[1].inputs[1].duration
                     - 1
                  input_attempt_state[id].is_parrying = true
               end
               -- if
               --    not (
               --       input_attempt_categories.option_parries[input_attempt_state[id].motion]
               --       and input_attempt_state[id].is_parrying
               --    )
               -- then
                  input_attempt_state[id].image_ref = draw_input_attempt(input_attempt_state[id].draw_data)
               -- end

               break
            end
         end
      end

      if input_attempt_state[id].is_parrying then
         if input_attempt_categories.option_parries[input_attempt_state[id].motion] then
            input_attempt_state[id].draw_data = get_input_attempt_draw_data(
               player,
               input_attempt_state[id].motion,
               input_attempt_state[id].matched_inputs
            )
            input_attempt_state[id].image_ref.text = input_attempt_state[id].draw_data.images
            input_attempt_state[id].image_ref.color = input_attempt_state[id].draw_data.color
            input_attempt_state[id].image_ref.elapsed = 0
            -- print("redraw")
            input_attempt_state[id].is_parrying = false
            -- print("stop parrying")
         end

         if gamestate.frame_number - input_attempt_state[id].parry_start_frame >= 28 then
            input_attempt_state[id].is_parrying = false
            print(gamestate.frame_number, input_attempt_state[id].parry_start_frame, "stop parrying 2")
         end
      end
   end
end

local function input_attempt_display(player) end

local input_accuracy_invalid_actions = {
   [0] = true,
   [0x6] = true,
   [0x7] = true,
   [0xB] = true,
   [0xE] = true,
   [0xF] = true,
   [0x10] = true,
   [0x14] = true,
   [0x15] = true,
   [0x16] = true,
}
local input_accuracy_data = { action = 0, idle_time = 0 }
local function input_accuracy_update(player)
   if player.idle_time <= 30 then
      local should_display = false
      if not input_accuracy_invalid_actions[player.action] then
         if player.action ~= input_accuracy_data.action then
            should_display = true
         elseif player.animation_frame == 0 then
            should_display = true
         end
      end
      if should_display then
         local x, y = draw.get_above_character_position(player)
         y = y - 2
         local w, h = get_text_dimensions(input_accuracy_data.idle_time)
         h = h + 1
         add_fading_text(
            x - tools.round(w / 2),
            y - h,
            input_accuracy_data.idle_time,
            "en",
            colors.input.red_parry,
            red_parry_miss_display_time,
            red_parry_miss_fade_time,
            true
         )
      end
   end
   input_accuracy_data.action = player.action
   input_accuracy_data.idle_time = player.idle_time
end

local function input_accuracy_display() end

local guard_jump_input_state = { IDLE = 1, RUNNING = 2, END = 3 }
local guard_jump_input_display_state = { SHOW = 1, HIDE = 2, SHOW_LAST = 3 }
local guard_jump_input_data = { { reference_frame = -1, state = guard_jump_input_state.IDLE }, {} }
local guard_jump_input_bar = {
   jump_tolerance = 3,
   window_min = 6,
   window_max = 10,
   bar_end = 16,
   bar_height = 3,
   scale = 4,
}

local function reset_guard_jump_input()
   guard_jump_input_data = { {}, {} }
end
local function update_guard_jump_input(input)
   settings.training.display_guard_jump_input = 1
   if settings.training.display_guard_jump_input == 1 then
      return
   end
   local players = {}
   if settings.training.display_guard_jump_input == 2 then
      players = { gamestate.P1 }
   elseif settings.training.display_guard_jump_input == 3 then
      players = { gamestate.P2 }
   elseif settings.training.display_guard_jump_input == 4 then
      players = { gamestate.P1, gamestate.P2 }
   end
   for _, player in pairs(players) do
      local data = guard_jump_input_data[player.id]
      local is_holding_down_back = tools.is_pressing_down(player, input) and tools.is_pressing_back(player, input)
      local is_holding_up = tools.is_pressing_up(player, input)
      if player.is_idle and is_holding_down_back and data.state == guard_jump_input_state.IDLE then
         data.state = guard_jump_input_state.RUNNING
      end
      if data.state == guard_jump_input_state.RUNNING then
         if
            is_holding_down_back
            and data.reference_frame == -1
            and gamestate.is_ground_state(player, player.standing_state)
         then
            data.reference_frame = gamestate.frame_number
         end
         if player.has_just_blocked then
            data.reference_frame = -1
         end
         if player.has_just_been_hit then
            -- fail
         end
         if player.has_just_recovered or player.has_just_landed or player.has_just_woke_up then
            data.reference_frame = gamestate.frame_number
         end
      end
   end
end

-- fail color, success color, early color

local function guard_jump_input_display()
   settings.training.display_guard_jump_input = 1
   if settings.training.display_guard_jump_input == 1 then
      return
   end
   local players = {}
   if settings.training.display_guard_jump_input == 2 then
      players = { gamestate.P1 }
   elseif settings.training.display_guard_jump_input == 3 then
      players = { gamestate.P2 }
   elseif settings.training.display_guard_jump_input == 4 then
      players = { gamestate.P1, gamestate.P2 }
   end
   for _, player in pairs(players) do
      local x, y = draw.get_above_character_position(gamestate.P1, false)
      x = x - guard_jump_input_bar.bar_end * guard_jump_input_bar.scale / 2
      local bar_width = guard_jump_input_bar.bar_end * guard_jump_input_bar.scale
      local block_time = gamestate.frame_number - guard_jump_input_data[player.id].reference_frame
      local bar_ratio = block_time / guard_jump_input_bar.bar_end
      local bar_color
      if block_time < guard_jump_input_bar.window_min then
         bar_color = colors.idle_time
      elseif block_time < guard_jump_input_bar.window_max then
         bar_color = colors.gauges.valid_fill
      else
         bar_color = 0x991111ff
      end
      draw.draw_gauge(
         x,
         y,
         bar_width,
         guard_jump_input_bar.bar_height,
         bar_ratio,
         bar_color,
         colors.gauges.background,
         colors.gauges.outline,
         false
      )
      local section_offset = guard_jump_input_bar.window_min * guard_jump_input_bar.scale
      gui.line(x + section_offset, y, x + section_offset, y + guard_jump_input_bar.bar_height, 0x00000044)
      section_offset = guard_jump_input_bar.window_max * guard_jump_input_bar.scale
      gui.line(x + section_offset, y, x + section_offset, y + guard_jump_input_bar.bar_height, 0x00000044)
   end
end

local attack_range_display_attacks = { {}, {} }
local attack_range_display_data = {}
local attack_range_display_start_pos = {}
local attack_range_display_attack_box_colors = {
   colors.colorscale(colors.hitboxes.attack, 0.6),
   colors.colorscale(colors.hitboxes.push, 0.6),
   0x670EAAFF,
}
local attack_range_display_throw_box_colors = {
   colors.colorscale(colors.hitboxes.throw, 0.6),
   colors.colorscale(colors.hitboxes.throwable, 0.6),
   colors.colorscale(colors.hitboxes.ext_vulnerability, 0.6),
}

local function attack_range_display_reset()
   attack_range_display_attacks = { {}, {} }
   attack_range_display_data = {}
end

local attack_box_filter = { ["attack"] = true }
local throw_box_filter = { ["throw"] = true }

local function attack_range_display()
   if not fd.is_loaded or settings.training.display_attack_range == 1 then
      return
   end
   local players = Pools.draw:alloc()
   if settings.training.display_attack_range == 2 then
      players[1] = gamestate.P1
   elseif settings.training.display_attack_range == 3 then
      players[1] = gamestate.P2
   elseif settings.training.display_attack_range == 4 then
      players[1] = gamestate.P1
      players[2] = gamestate.P2
   end

   for _, player in pairs(players) do
      local fdata = nil
      local id = player.id
      if player.has_just_attacked then
         attack_range_display_start_pos[id] = { player.previous_pos_x, player.previous_pos_y }
         fdata = fd.frame_data[player.char_str][player.animation]
         if fdata and fdata.hit_frames then
            if not tools.table_contains(attack_range_display_attacks[id], player.animation) then
               table.insert(attack_range_display_attacks[id], player.animation)
            end
         end
         while #attack_range_display_attacks[id] > settings.training.attack_range_display_max_attacks do
            table.remove(attack_range_display_attacks[id], 1)
         end
         local attack_anim = player.animation
         local last_hit_frame = 0
         local offset_x = 0
         local offset_y = 0
         local velocity_x = 0
         local velocity_y = 0
         local acceleration_x = 0
         local acceleration_y = 0
         fdata = fd.frame_data[player.char_str][attack_anim]
         if fdata and fdata.hit_frames then
            last_hit_frame = fdata.hit_frames[#fdata.hit_frames][2] + 1
            attack_range_display_data[attack_anim] = {}
            for j = 1, last_hit_frame do
               if not fdata.frames[j].ignore_motion then
                  offset_x = offset_x + velocity_x
                  offset_y = offset_y + velocity_y
                  velocity_x = velocity_x + acceleration_x
                  velocity_y = velocity_y + acceleration_y
               end
               if fdata.frames[j].movement then
                  offset_x = offset_x + fdata.frames[j].movement[1]
                  offset_y = offset_y + fdata.frames[j].movement[2]
               end
               if fdata.frames[j].velocity then
                  velocity_x = velocity_x + fdata.frames[j].velocity[1]
                  velocity_y = velocity_y + fdata.frames[j].velocity[2]
               end
               if fdata.frames[j].acceleration then
                  acceleration_x = acceleration_x + fdata.frames[j].acceleration[1]
                  acceleration_y = acceleration_y + fdata.frames[j].acceleration[2]
               end
               if fdata.frames[j].boxes then
                  for _, box in pairs(fdata.frames[j].boxes) do
                     local b = tools.format_box(box, nil, Pools.draw:alloc())
                     if b.type == "attack" or b.type == "throw" then
                        local data = {}
                        data.distance = tools.round(offset_x - b.left)
                        data.box = box
                        data.box_type = b.type
                        data.offset_x = offset_x
                        data.offset_y = offset_y
                        table.insert(attack_range_display_data[attack_anim], data)
                     end
                  end
               end
            end
         end
      end
      local sign = tools.flip_to_sign(player.flip_x)
      local attack_color_index = 1
      local throw_color_index = 1
      for i = 1, #attack_range_display_attacks[id] do
         local attack_anim = attack_range_display_attacks[id][i]
         local drawn_box_type = ""
         local attack_range_display_attack_box_color = attack_range_display_attack_box_colors[attack_color_index]
         local attack_range_display_throw_box_color = attack_range_display_throw_box_colors[throw_color_index]
         local posx, posy = player.pos_x, player.pos_y
         if player.animation == attack_anim then
            posx, posy = attack_range_display_start_pos[id][1], attack_range_display_start_pos[id][2]
         end
         for _, data in pairs(attack_range_display_data[attack_anim]) do
            local current_box = data.box
            local box = tools.format_box(data.box, nil, Pools.draw:alloc())
            local height_below_zero = (posy + data.offset_y + box.bottom) * -1
            if height_below_zero > 0 then
               box.bottom = box.bottom + height_below_zero
               current_box = tools.create_box(box, Pools.draw:alloc())
            end
            local boxes_to_draw = Pools.draw:alloc()
            boxes_to_draw[1] = current_box

            local extended = false
            draw.draw_hitboxes(
               posx + sign * data.offset_x,
               posy + data.offset_y,
               player.flip_x,
               boxes_to_draw,
               extended,
               attack_box_filter,
               nil,
               attack_range_display_attack_box_color
            )
            draw.draw_hitboxes(
               posx + sign * data.offset_x,
               posy + data.offset_y,
               player.flip_x,
               boxes_to_draw,
               extended,
               throw_box_filter,
               nil,
               attack_range_display_throw_box_color
            )
            drawn_box_type = data.box_type
         end
         if drawn_box_type == "attack" then
            attack_color_index = tools.wrap_index(attack_color_index + 1, #attack_range_display_attack_box_colors)
         elseif drawn_box_type == "throw" then
            throw_color_index = tools.wrap_index(throw_color_index + 1, #attack_range_display_attack_box_colors)
         end
      end
      if settings.training.attack_range_display_show_numbers then
         for i = 1, #attack_range_display_attacks[id] do
            local attack_anim = attack_range_display_attacks[id][i]
            local posx, posy = player.pos_x, player.pos_y
            if player.animation == attack_anim then
               posx, posy = attack_range_display_start_pos[id][1], attack_range_display_start_pos[id][2]
            end
            if attack_range_display_data[attack_anim] then
               local dist = 0
               local attack = attack_range_display_data[attack_anim]
               local data
               for j = 1, #attack do
                  if attack[j].distance > dist then
                     dist = attack[j].distance
                     data = attack[j]
                  end
               end
               if data then
                  local w, h = get_text_dimensions(data.distance, "en")
                  local text_x = 0
                  local box = tools.format_box(data.box, nil, Pools.draw:alloc())
                  if player.flip_x == 0 then
                     text_x = math.max(
                        posx + sign * (data.offset_x - box.left - box.width / 2) - w / 2,
                        posx + sign * (data.offset_x - box.left) + 2
                     )
                  else
                     text_x = math.max(
                        posx + sign * (data.offset_x - box.left - box.width / 2) - w / 2,
                        posx + sign * (data.offset_x - box.left) - box.width + 2
                     )
                  end
                  local dist_text_x, dist_text_y =
                     draw.game_to_screen_space(text_x, posy + data.offset_y + box.bottom + box.height / 2)
                  render_text(dist_text_x, dist_text_y - 3, data.distance, "en")
               end
            end
         end
      end
   end
end

local last_hit_history = { {}, {} }
local last_hit_history_size = 2

local function reset_last_hit_bars()
   tools.clear_table(last_hit_history[1])
   tools.clear_table(last_hit_history[2])
end

local function update_last_hit_bars(player, attack_bars_settings)
   if attack_bars_settings == 1 then
      return
   elseif attack_bars_settings == 2 then
      last_hit_history_size = 1
   elseif attack_bars_settings == 3 then
      last_hit_history_size = 2
   end
   local player_history = last_hit_history[player.id]
   if player_history[1] then
      if attack_data.data[player.id].id == player_history[1].id then
         tools.copy_fields(player_history[1], attack_data.data[player.id])
      else
         table.insert(player_history, 1, tools.deepcopy(attack_data.data[player.id]))
         while #player_history > last_hit_history_size do
            table.remove(player_history, #player_history)
         end
      end
   else
      player_history[1] = tools.deepcopy(attack_data.data[player.id])
   end
end

local function last_hit_bars_display(player, attack_bars_settings)
   if attack_bars_settings == 1 then
      return
   end

   local life_x = 8
   local life_y = 12
   local life_max_width = 160
   local life_height = 6
   local stun_x = life_x + life_max_width - 1
   local stun_y = 31
   local stun_height = 6

   local sign = 1

   local player_history = last_hit_history[player.id]

   for i = 1, #player_history do
      local id = player.id
      if player_history[i].total_damage > 0 then
         local life_width = player_history[i].total_damage
         local life_offset = 160 - player_history[i].start_life

         if id == 1 then
            life_width = life_width - 2
         end
         if id == 1 then
            life_x = draw.SCREEN_WIDTH - 8
            stun_x = life_x - life_max_width + 1
            sign = -1
         end

         gui.drawline(
            life_x + sign * life_offset,
            life_y - (i - 1) * life_height,
            life_x + sign * life_offset + sign * life_width - 1,
            life_y - (i - 1) * life_height,
            colors.last_hit_bars.life
         )
         gui.drawline(
            life_x + sign * life_offset,
            life_y - (i - 1) * life_height,
            life_x + sign * life_offset,
            life_y - (i - 1) * life_height + 2,
            colors.last_hit_bars.life
         )
         gui.drawline(
            life_x + sign * life_offset + sign * life_width - 1,
            life_y - (i - 1) * life_height,
            life_x + sign * life_offset + sign * life_width - 1,
            life_y - (i - 1) * life_height + 2,
            colors.last_hit_bars.life
         )
         local text_width = get_text_dimensions(tostring(player_history[i].total_damage), "en")
         local text_pos_x = tools.round(sign * (life_width - text_width) / 2) + life_x + sign * life_offset

         if id == 1 then
            text_pos_x = text_pos_x - text_width
         end
         local text_pos_y = 9 - (i - 1) * life_height
         render_text(text_pos_x, text_pos_y, tostring(player_history[i].total_damage), "en", colors.last_hit_bars.life)

         local stun_width = player_history[i].total_stun
         local stun_offset = player_history[i].start_stun

         if stun_width > 0 then
            if id == 2 then
               stun_width = stun_width - 2
            end

            gui.drawline(
               stun_x - sign * stun_offset,
               stun_y + (i - 1) * stun_height,
               stun_x - sign * stun_offset - sign * stun_width - 1,
               stun_y + (i - 1) * stun_height,
               colors.last_hit_bars.stun
            )
            gui.drawline(
               stun_x - sign * stun_offset,
               stun_y + (i - 1) * stun_height,
               stun_x - sign * stun_offset,
               stun_y + (i - 1) * stun_height - 1,
               colors.last_hit_bars.stun
            )
            gui.drawline(
               stun_x - sign * stun_offset - sign * stun_width - 1,
               stun_y + (i - 1) * stun_height,
               stun_x - sign * stun_offset - sign * stun_width - 1,
               stun_y + (i - 1) * stun_height - 1,
               colors.last_hit_bars.stun
            )
            if settings.training.attack_bars_show_decimal then
               text_width = get_text_dimensions(string.format("%.2f", player_history[i].total_stun), "en")
               text_pos_x = stun_x - sign * stun_offset - sign * stun_width - 1 - 2 * sign
               if id == 2 then
                  text_pos_x = text_pos_x - text_width
               end
               text_pos_y = stun_y + (i - 1) * stun_height - 2
               render_text(
                  text_pos_x,
                  text_pos_y,
                  string.format("%.2f", player_history[i].total_stun),
                  "en",
                  colors.last_hit_bars.stun
               )
            else
               text_width = get_text_dimensions(tostring(tools.round(player_history[i].total_stun)), "en")
               text_pos_x = tools.round(-1 * sign * (stun_width - text_width) / 2) + stun_x - sign * stun_offset
               if id == 2 then
                  text_pos_x = text_pos_x - text_width
               end
               text_pos_y = stun_y + (i - 1) * stun_height - 2
               render_text(
                  text_pos_x,
                  text_pos_y,
                  tostring(tools.round(player_history[i].total_stun)),
                  "en",
                  colors.last_hit_bars.stun
               )
            end
         end
      end
   end
end

local function get_stun_timer_position(player)
   local char_height = tools.get_boxes_highest_position(player.boxes, tools.BOXES.VULNERABILITY)
   return draw.game_to_screen_space(player.pos_x, player.pos_y + char_height)
end
local stun_timer_max_width = 60
local stun_timer_half_width = math.floor(stun_timer_max_width / 2)
local stun_timer_max_value = 240
local stun_timer_gauge_height = 2
local stun_timer_state_default = { stunned_y_pos = 0, capture_next_pos = false }
local stun_timer_state = { copytable(stun_timer_state_default), copytable(stun_timer_state_default) }
local stun_timer_position_adjust = {
   ["alex"] = 8,
   ["dudley"] = 4,
   ["elena"] = 2,
   ["ken"] = 6,
   ["gouki"] = 8,
   ["hugo"] = 4,
   ["necro"] = 16,
   ["oro"] = 6,
   ["remy"] = 2,
   ["ryu"] = 6,
   ["sean"] = 6,
   ["shingouki"] = 4,
}

local function stun_timer_display_reset()
   tools.clear_table(stun_timer_state[1])
   tools.clear_table(stun_timer_state[2])
   tools.copy_fields(stun_timer_state[1], stun_timer_state_default)
   tools.copy_fields(stun_timer_state[2], stun_timer_state_default)
end

local function stun_timer_display(player)
   local id = player.id
   if player.is_stunned then
      if stun_timer_state[id].capture_next_pos then
         local char_height = tools.get_boxes_highest_position(player.boxes, tools.BOXES.VULNERABILITY)
         if char_height then
            local x, y = draw.game_to_screen_space(player.pos_x, player.pos_y + char_height)
            if stun_timer_position_adjust[player.char_str] then
               y = y - stun_timer_position_adjust[player.char_str]
            end
            stun_timer_state[id].stunned_y_pos = y
            stun_timer_state[id].capture_next_pos = false
         end
      end
      if player.just_recovered or player.has_just_woke_up then
         stun_timer_state[id].capture_next_pos = true
      end
      if player.stun_timer > 0 then
         local stun_text = player.stun_timer
         local pos_x, pos_y = get_stun_timer_position(player)

         if
            player.standing_state == 1
            or (player.char_str == "alex" and player.standing_state == 13)
            or (player.char_str == "hugo" and player.standing_state == 2)
            or (player.char_str == "ibuki" and player.standing_state == 10)
         then
            pos_y = stun_timer_state[id].stunned_y_pos
         end
         local text_w, text_h = get_text_dimensions(stun_text, "en")

         pos_x = pos_x - stun_timer_half_width
         pos_x = tools.clamp(pos_x, 1, draw.SCREEN_WIDTH - stun_timer_max_width - 2)
         pos_y = pos_y - 8
         draw.draw_gauge(
            pos_x,
            pos_y,
            stun_timer_max_width,
            stun_timer_gauge_height,
            player.stun_timer / stun_timer_max_value,
            colors.gauges.cooldown_fill,
            colors.gauges.background,
            colors.gauges.outline
         )

         render_text(pos_x + stun_timer_half_width - tools.round(text_w / 2), pos_y - text_h, stun_text, "en")
      end
   end
end

local player_label_display_time = 90
local player_label_fade_time = 30
local player_label_state = {}

local function player_label_reset()
   tools.clear_table(player_label_state)
end

-- hud_cpu hud_p1 hud_p2 hud_dummy
local function add_player_label(player, label)
   if not player_label_state[player.id] then
      player_label_state[player.id] = {}
   end
   player_label_state[player.id].start_frame = gamestate.frame_number
   player_label_state[player.id].label = label
end

local function player_label_display()
   local to_remove = Pools.draw:alloc()
   for id, state in pairs(player_label_state) do
      local elapsed = gamestate.frame_number - state.start_frame
      if menu.is_open and not menu.allow_update_while_open then
         state.start_frame = state.start_frame + 1
      end
      if elapsed <= player_label_display_time + player_label_fade_time then
         local opacity = 1
         if elapsed > player_label_display_time then
            opacity = 1 - ((elapsed - player_label_display_time) / player_label_fade_time)
         end
         local player = gamestate.player_objects[id]
         local x, y = draw.get_above_character_position(player)
         y = y - 2
         draw.draw_image(x - 4, y, "img_tri_arrow_down", nil, colors.text.default, opacity)
         local font = settings.language_tag
         if font == "jp" then
            font = "jp_8"
         end
         local w, h = get_text_dimensions(state.label, font)
         h = h + 1

         render_text(x - tools.round(w / 2), y - h, state.label, font, nil, opacity)
      else
         to_remove[#to_remove + 1] = id
      end
   end
   for _, key in ipairs(to_remove) do
      player_label_state[key] = nil
   end
end

local function indicate_player_controllers()
   local training = require("src.training")
   add_player_label(gamestate.P1, "hud_" .. training.P1_controller.name)
   add_player_label(gamestate.P2, "hud_" .. training.P2_controller.name)
   require("src.ui.menu").reset_background_cache()
end

local blocking_direction_history = {}
local blocking_dir = 1
local last_dir = 1

local function blocking_direction_display_reset()
   tools.clear_table(blocking_direction_history)
end

local function update_blocking_direction(input, dummy)
   if settings.training.blocking_mode > 1 then
      blocking_dir = 5
      if input[dummy.prefix .. " Up"] == false then
         if input[dummy.prefix .. " Down"] == false then
            if input[dummy.prefix .. " Left"] == true then
               blocking_dir = 4
            elseif input[dummy.prefix .. " Right"] == true then
               blocking_dir = 6
            end
         else
            if input[dummy.prefix .. " Left"] == true then
               blocking_dir = 1
            elseif input[dummy.prefix .. " Right"] == true then
               blocking_dir = 3
            else
               blocking_dir = 2
            end
         end
      end
      if
         dummy.blocking.last_block
         and dummy.blocking.last_block.frame_number == gamestate.frame_number
         and dummy.blocking.last_block.sub_type ~= "pass"
         and blocking_dir ~= last_dir
      then
         table.insert(blocking_direction_history, { start_frame = gamestate.frame_number, dir = blocking_dir })
      end
      last_dir = blocking_dir
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
         local x, y = draw.get_above_character_position(dummy)
         draw.draw_image(
            x,
            y - (#blocking_direction_history - i - 1) * offset_y,
            image_tables.img_str_dir_small[blocking_direction_history[i].dir],
            nil,
            colors.text.default,
            opacity
         )
         i = i + 1
      else
         table.remove(blocking_direction_history, i)
      end
   end
end

local p1_filter = nil -- {["push"] = true, ["vulnerability"] = true}
local p2_filter = nil -- {["push"] = true}
local function hitboxes_display(
   display_hitboxes_settings,
   display_hitboxes_opacity_settings,
   display_hitboxes_ab_settings
)
   if display_hitboxes_settings == 1 then
      return
   end
   local extended = display_hitboxes_ab_settings
   -- players
   if display_hitboxes_settings == 2 or display_hitboxes_settings == 4 then
      draw.draw_hitboxes(
         gamestate.P1.pos_x,
         gamestate.P1.pos_y,
         gamestate.P1.flip_x,
         gamestate.P1.boxes,
         extended,
         p1_filter,
         nil,
         nil,
         display_hitboxes_opacity_settings
      )
   end
   if display_hitboxes_settings == 3 or display_hitboxes_settings == 4 then
      draw.draw_hitboxes(
         gamestate.P2.pos_x,
         gamestate.P2.pos_y,
         gamestate.P2.flip_x,
         gamestate.P2.boxes,
         extended,
         p2_filter,
         nil,
         nil,
         display_hitboxes_opacity_settings
      )
   end
   -- projectiles
   for _, obj in pairs(gamestate.projectiles) do
      if
         (obj.emitter_id == 1 and (display_hitboxes_settings == 2 or display_hitboxes_settings == 4))
         or (obj.emitter_id == 2 and (display_hitboxes_settings == 3 or display_hitboxes_settings == 4))
      then
         draw.draw_hitboxes(
            obj.pos_x,
            obj.pos_y,
            obj.flip_x,
            obj.boxes,
            extended,
            nil,
            nil,
            nil,
            display_hitboxes_opacity_settings
         )
      end
   end
end

local top_bar_draw_data = { x = 4, y = 5, spacing = 4, padding_x = 4, padding_y = 5, limit_left = 0, limit_right = 0 }
top_bar_draw_data.limit_left = top_bar_draw_data.padding_x
top_bar_draw_data.limit_right = draw.SCREEN_WIDTH - top_bar_draw_data.padding_x

local active_mode_display_data = {
   active_mode = nil,
   last_active_mode = nil,
   ratio = 0,
   strikeout = false,
   is_fading = false,
   fade_time = 14,
   fade_start_frame = 0,
}

local function update_active_mode_strikeout(start_time, stop_mode_hold_time)
   active_mode_display_data.ratio = math.min(start_time / stop_mode_hold_time, 1)
   active_mode_display_data.strikeout = true
end

local function reset_active_mode_strikeout()
   active_mode_display_data = {
      active_mode = nil,
      last_active_mode = nil,
      ratio = 0,
      strikeout = false,
      is_fading = false,
      fade_time = 14,
      fade_start_frame = 0,
   }
end

local function active_mode_display(draw_data)
   local active_mode = require("src.modes").active_mode
   if active_mode then
      if not active_mode_display_data.active_mode then
         reset_active_mode_strikeout()
      end
      active_mode_display_data.last_active_mode = active_mode
   elseif active_mode_display_data.active_mode then
      active_mode_display_data.fade_start_frame = gamestate.frame_number
   end
   active_mode_display_data.active_mode = active_mode

   local lang = settings.language_tag
   if lang == "jp" then
      draw_data.y = draw_data.padding_y - 2
   end
   local mode_text = ""
   local opacity = 1
   if active_mode then
      mode_text = "hud_top_" .. active_mode.name
   elseif active_mode_display_data.last_active_mode then
      mode_text = "hud_top_" .. active_mode_display_data.last_active_mode.name
      local elapsed = gamestate.frame_number - active_mode_display_data.fade_start_frame
      if elapsed <= active_mode_display_data.fade_time then
         opacity = 1 - (elapsed / active_mode_display_data.fade_time)
         active_mode_display_data.is_fading = true
      else
         reset_active_mode_strikeout()
      end
   end

   if active_mode or active_mode_display_data.is_fading then
      render_text(draw_data.x, draw_data.y, mode_text, nil, nil, opacity)
      local w, h = get_text_dimensions(mode_text)
      draw_data.limit_left = draw_data.x + w + draw_data.spacing

      if active_mode_display_data.strikeout then
         local line_color = 0xFFFFFF00 + math.floor(0xFF * opacity)
         local outline_color = 0x00000000 + math.floor(0xFF * opacity)
         local line_length = (w + 2) * active_mode_display_data.ratio
         local line_y = draw_data.y + h / 2 - 1
         if lang == "en" then
            line_y = line_y - 1
         end
         gui.box(draw_data.x - 1, line_y, draw_data.x - 1 + line_length, line_y + 2, line_color, outline_color)
      end
   end
end

local function recording_display(draw_data, player)
   if recording.current_recording_state == recording.RECORDING_STATE.STOPPED then
      return
   end
   local dummy = player.other
   local font = settings.language_tag
   if font == "jp" then
      font = "jp_8"
   end
   local current_recording_size = 0
   if recording.recording_slots[settings.training.current_recording_slot].inputs then
      current_recording_size = #recording.recording_slots[settings.training.current_recording_slot].inputs
   end
   if recording.current_recording_state == recording.RECORDING_STATE.WAIT_FOR_RECORDING then
      local text = Pools.draw:alloc()
      text[1] = "hud_slot"
      text[2] = " "
      text[3] = settings.training.current_recording_slot
      text[4] = ": "
      text[5] = "hud_wait_for_recording"
      text[6] = " "
      text[7] = current_recording_size
      local w, h = get_text_dimensions_multiple(text, font)
      draw_data.x = draw.SCREEN_WIDTH - w - draw_data.padding_x
      draw_data.y = draw_data.padding_y
      render_text_multiple(draw_data.x, draw_data.y, text, font)
   elseif recording.current_recording_state == recording.RECORDING_STATE.RECORDING then
      local text = Pools.draw:alloc()
      text[1] = "hud_slot"
      text[2] = " "
      text[3] = settings.training.current_recording_slot
      text[4] = ": "
      text[5] = "hud_recording"
      text[6] = "... ("
      text[7] = current_recording_size
      text[8] = ")"

      local w, h = get_text_dimensions_multiple(text, font)
      draw_data.x = draw.SCREEN_WIDTH - w - draw_data.padding_x
      draw_data.y = draw_data.padding_y
      render_text_multiple(draw_data.x, draw_data.y, text, font)
   elseif recording.current_recording_state == recording.RECORDING_STATE.POSITIONING then
      local text = Pools.draw:alloc()
      text[1] = "hud_positioning"
      local w, h = get_text_dimensions_multiple(text, font)
      draw_data.x = draw.SCREEN_WIDTH - w - draw_data.padding_x
      draw_data.y = draw_data.padding_y
      render_text_multiple(draw_data.x, draw_data.y, text, font)
   elseif
      recording.current_recording_state == recording.RECORDING_STATE.REPLAYING
      and dummy.pending_input_sequence
      and dummy.pending_input_sequence.sequence
   then
      local text = Pools.draw:alloc()
      if settings.training.replay_mode == 1 or settings.training.replay_mode == 4 then
         text[1] = "hud_playing"
         text[2] = " ("
         text[3] = dummy.pending_input_sequence.current_frame - 1
         text[4] = "/"
         text[5] = #dummy.pending_input_sequence.sequence
         text[6] = ")"
      else
         text[1] = "hud_playing"
      end
      local w, h = get_text_dimensions_multiple(text, font)
      draw_data.x = draw.SCREEN_WIDTH - w - draw_data.padding_x
      draw_data.y = draw_data.padding_y
      render_text_multiple(draw_data.x, draw_data.y, text, font)
   end
   draw_data.limit_right = draw_data.x - draw_data.spacing
end

local function bonuses_display(draw_data)
   local font = settings.language_tag
   if font == "jp" then
      font = "jp_8"
   end
   draw_data.y = draw_data.padding_y
   for _, player in ipairs(gamestate.player_objects) do
      if player.id == 1 then
         draw_data.x = draw_data.limit_left
      elseif player.id == 2 then
         draw_data.x = draw_data.limit_right
      end
      if player.damage_bonus > 0 then
         local bonus_text = Pools.draw:alloc()
         bonus_text[1], bonus_text[2], bonus_text[3], bonus_text[4] = "+", player.damage_bonus, " ", "bonus_damage"
         local w, h = get_text_dimensions_multiple(bonus_text, font)
         if player.id == 2 then
            draw_data.x = draw_data.x - w
         end
         render_text_multiple(draw_data.x, draw_data.y, bonus_text, font, colors.bonuses.damage)
         if player.id == 1 then
            draw_data.x = draw_data.x + w + draw_data.spacing
         end
      end

      if player.defense_bonus > 0 then
         local bonus_text = Pools.draw:alloc()
         bonus_text[1], bonus_text[2], bonus_text[3], bonus_text[4] = "+", player.defense_bonus, " ", "bonus_defense"
         local w, h = get_text_dimensions_multiple(bonus_text, font)
         if player.id == 2 then
            draw_data.x = draw_data.x - w - draw_data.spacing
         end
         render_text_multiple(draw_data.x, draw_data.y, bonus_text, font, colors.bonuses.defense)
         if player.id == 1 then
            draw_data.x = draw_data.x + w + draw_data.spacing
         end
      end

      if player.stun_bonus > 0 then
         local bonus_text = Pools.draw:alloc()
         bonus_text[1], bonus_text[2], bonus_text[3], bonus_text[4] = "+", player.stun_bonus, " ", "bonus_stun"
         local w, h = get_text_dimensions_multiple(bonus_text, font)
         if player.id == 2 then
            draw_data.x = draw_data.x - w - draw_data.spacing
         end
         render_text_multiple(draw_data.x, draw_data.y, bonus_text, font, colors.bonuses.stun)
         if player.id == 1 then
            draw_data.x = draw_data.x + w + draw_data.spacing
         end
      end
   end
end

local function top_bar_display(player, should_draw_mode, should_draw_recording, should_draw_bonuses)
   local lang = settings.language_tag
   local draw_data = copytable(top_bar_draw_data)
   if lang == "jp" then
      draw_data.padding_y = 4
   end
   draw_data.y = draw_data.padding_y

   if should_draw_mode then
      active_mode_display(draw_data)
   end
   if should_draw_recording then
      recording_display(draw_data, player)
   end
   if should_draw_bonuses then
      bonuses_display(draw_data)
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
      dilation = dilation,
   }
   table.insert(printed_geometry, g)
end

-- push a persistent point to be drawn on the screen each frame
local function print_point(pos_x, pos_y, color)
   local g = { type = "point", x = pos_x, y = pos_y, color = color }
   table.insert(printed_geometry, g)
end

local function clear_printed_geometry()
   printed_geometry = {}
end

local function display_draw_printed_geometry()
   -- printed geometry
   for _, geometry in ipairs(printed_geometry) do
      if geometry.type == "hitboxes" then
         draw.draw_hitboxes(
            geometry.x,
            geometry.y,
            geometry.flip_x,
            geometry.boxes,
            false,
            geometry.filter,
            geometry.dilation
         )
      elseif geometry.type == "point" then
         draw.draw_cross(geometry.x, geometry.y, geometry.color)
      end
   end
end

local function life_text_display(player_object)
   local x = 0
   local y = 20
   local life = player_object.life
   if life == 255 then
      life = 0
   end

   local t = string.format("%d/160", life)

   if player_object.id == 1 then
      x = 13
   elseif player_object.id == 2 then
      x = draw.SCREEN_WIDTH - 11 - draw.get_text_width(t)
   end

   local color = colors.gauges.life_full
   if life < 160 then
      color = colors.gauges.life_mid
   end
   if life < 49 then
      color = colors.gauges.life_low
   end
   if life == 0 then
      color = colors.gauges.stun
   end

   gui.text(x, y, t, color, 0x14171BFF)
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

   gui.text(x, y, t, colors.gauges.meter, 0x14171BFF)
end

local function stun_text_display(player_object)
   local x = 0
   local y = 29

   local t = string.format("%d/%d", math.floor(player_object.stun_bar), player_object.stun_bar_max)

   if player_object.id == 1 then
      x = 167 - player_object.stun_bar_max + 3
   elseif player_object.id == 2 then
      x = 216 + player_object.stun_bar_max - draw.get_text_width(t) - 1
   end

   gui.text(x, y, t, colors.gauges.stun, 0x14171BFF)
end

local advantage_display_time = 60
local advantage_fade_time = 20
local advantage_min_y = 60
local function frame_advantage_numbers_display(player, advantage, fa_settings)
   if not (fa_settings == 2 or fa_settings == 4) then
      return
   end
   if not advantage[player.id] or not advantage[player.id].just_finished then
      return
   end

   advantage[player.id].just_finished = false
   local advantage_text = advantage[player.id].advantage
   local advantage_color = colors.hud_text.default
   local x, y
   if advantage[player.id].advantage > 0 then
      advantage_text = string.format("+%d", advantage[player.id].advantage)
      advantage_color = colors.hud_text.success
   elseif advantage[player.id].advantage < 0 then
      advantage_text = string.format("%d", advantage[player.id].advantage)
      advantage_color = colors.hud_text.failure
   end
   x, y = draw.get_above_character_position(player)
   y = math.max(y, advantage_min_y)
   add_fading_text(x, y - 4, advantage_text, "en", advantage_color, advantage_display_time, advantage_fade_time, true)
end

local function frame_advantage_table_display(player, advantage, fa_settings)
   if not (fa_settings == 3 or fa_settings == 4) then
      return
   end
   local y = 49
   local function display_line(str, value, color)
      color = color or colors.hud_text.default
      local font = settings.language_tag
      local w, h
      local y_offset = 0
      if font == "jp" then
         font = "jp_8"
         y_offset = 1
      end
      local prefix = Pools.draw:alloc()
      prefix[1], prefix[2] = str, ": "
      w, h = get_text_dimensions_multiple(prefix, font)

      local x = 0
      if player.id == 1 then
         x = 51
      elseif player.id == 2 then
         x = draw.SCREEN_WIDTH - 65 - w
      end

      render_text_multiple(x, y, prefix, font, colors.hud_text.default)
      render_text(x + w, y + y_offset, value, "en", color)
      y = y + h
   end

   if not advantage[player.id] or not advantage[player.id].startup then
      return
   end
   display_line("hud_startup", string.format("%d", advantage[player.id].startup))

   if advantage[player.id].connect_frame then
      local hit_frame = advantage[player.id].hit_frame
      display_line("hud_hit_frame", string.format("%d", hit_frame))
      if advantage[player.id].state == frame_advantage.advantage_states.FINISHED then
         local frame_adv = advantage[player.id].advantage

         local sign = ""
         if frame_adv > 0 then
            sign = "+"
         end

         local color = colors.hud_text.default
         if frame_adv < 0 then
            color = colors.hud_text.failure
         elseif frame_adv > 0 then
            color = colors.hud_text.success
         end

         display_line("hud_advantage", string.format("%s%d", sign, frame_adv), color)
      end
   else
      if advantage[player.id].hitbox_start_frame and advantage[player.id].hitbox_end_frame then
         display_line("hud_active", string.format("%d", advantage[player.id].active_time))
      end
      display_line("hud_duration", string.format("%d", advantage[player.id].duration))
   end
end

local notification_text_data = {}
local notification_text_display_time = 10
local notification_text_fade_time = 14

local function add_notification_text(str, x, y, align, display_time)
   notification_text_data[str] = {
      str = str,
      x = x,
      y = y,
      align = align,
      display_time = display_time or notification_text_display_time,
      start_frame = gamestate.frame_number,
   }
end
local function clear_notification_text()
   tools.clear_table(notification_text_data)
end

local function notification_text_display()
   if not notification_text_data then
      return
   end
   local menu = require("src.ui.menu")
   local to_remove = Pools.draw:alloc()
   for key, notification_text in pairs(notification_text_data) do
      if menu.is_open and not menu.allow_update_while_open then
         notification_text.start_frame = notification_text.start_frame + 1
      end
      local elapsed = gamestate.frame_number - notification_text.start_frame
      if elapsed <= notification_text.display_time + notification_text_fade_time then
         local font = settings.language_tag
         if font == "jp" then
            font = "jp_8"
         end
         local text_width, text_height = get_text_dimensions(notification_text.str, font)
         local x, y = notification_text.x, notification_text.y
         local text_x, text_y = x, y
         local fade_in = 10
         local width = text_width + fade_in * 2 + 4
         local height = text_height + 2
         if notification_text.align == "center_horizontal" then
            x = (draw.SCREEN_WIDTH - width) / 2
            text_x = (draw.SCREEN_WIDTH - text_width) / 2
         end

         text_y = y + (height - text_height) / 2
         if font == "en" then
            text_y = text_y + 1
         end

         local opacity = 1
         if elapsed > notification_text.display_time then
            opacity = 1 - ((elapsed - notification_text.display_time) / notification_text_fade_time)
         end
         local base_color = bit.lshift(bit.rshift(colors.menu.background, 8), 8)
         local bg_opacity = opacity * 0xFF * 0.6
         local bg_color = base_color + math.floor(bg_opacity)

         for pad = 0, fade_in - 1 do
            local color = base_color + math.floor(bg_opacity * (pad + 1) / fade_in)
            gui.line(x + pad, y, x + pad, y + height, color)
            gui.line(x + width - pad, y, x + width - pad, y + height, color)
         end
         gui.box(x + fade_in, y, x + width - fade_in, y + height, bg_color, bg_color)
         render_text(text_x, text_y, notification_text.str, font, nil, opacity)
      else
         to_remove[#to_remove + 1] = key
      end
   end
   for _, key in ipairs(to_remove) do
      notification_text_data[key] = nil
   end
end

local show_player_position = false
local function player_position_display()
   local x, y = draw.game_to_screen_space(gamestate.P1.pos_x, gamestate.P1.pos_y)
   draw.draw_image(x - 4, y, image_tables.img_str_dir_small[8], nil, colors.text.default)
   x, y = draw.game_to_screen_space(gamestate.P2.pos_x, gamestate.P2.pos_y)
   draw.draw_image(x - 4, y, image_tables.img_str_dir_small[8], nil, colors.text.default)
end

local draw_list = {}
local func_list = {}
local function register_draw(func, order)
   if func_list[func] then
      return
   end
   order = order or #draw_list + 1
   draw_list[#draw_list + 1] = { func = func, order = order }
   func_list[func] = #draw_list
   table.sort(draw_list, function(a, b)
      return a.order < b.order
   end)
end

local function unregister_draw(func)
   if not func_list[func] then
      return
   end
   for i, data in ipairs(draw_list) do
      if data.func == func then
         table.remove(draw_list, i)
         break
      end
   end
   func_list[func] = nil
end

local function draw_registered_functions()
   for _, data in ipairs(draw_list) do
      data.func()
   end
end

local function init()
   kaiten_images = {
      active = {
         image_tables.img_str_dir_small[6],
         image_tables.img_str_dir_small[2],
         image_tables.img_str_dir_small[4],
         image_tables.img_str_dir_small[8],
      },
      inactive = {
         image_tables.img_str_dir_inactive[6],
         image_tables.img_str_dir_inactive[2],
         image_tables.img_str_dir_inactive[4],
         image_tables.img_str_dir_inactive[8],
      },
   }
   menu = require("src.ui.menu")
end

local function reset_hud()
   attack_range_display_reset()
   blocking_direction_display_reset()
   reset_last_hit_bars()
   red_parry_miss_display_reset()
   stun_timer_display_reset()
   player_label_reset()
   clear_fading_text()
   clear_score_text()
   clear_notification_text()
   reset_active_mode_strikeout()
end

local function update_hud(player, dummy, input)
   -- input_accuracy_update(player)
   update_blocking_direction(input, dummy)

   -- update_guard_jump_input(input)
   -- update_recovery_display()
   update_last_hit_bars(player, settings.training.display_attack_bars)
end

local function draw_hud(player, dummy)
   if settings.training.display_attack_range ~= 1 then
      attack_range_display()
   end

   hitboxes_display(
      settings.training.display_hitboxes,
      settings.training.display_hitboxes_opacity,
      settings.training.display_hitboxes_ab
   )

   if settings.training.display_gauges then
      life_text_display(player)
      life_text_display(dummy)

      meter_text_display(player)
      meter_text_display(dummy)

      stun_text_display(player)
      stun_text_display(dummy)
   end

   last_hit_bars_display(player, settings.training.display_attack_bars)

   if settings.training.display_red_parry_miss then
      red_parry_miss_display(player)
   end
   if settings.training.display_blocking_direction then
      blocking_direction_display(player, dummy)
   end
   if settings.training.display_stun_timer then
      stun_timer_display(player)
      stun_timer_display(dummy)
   end
   if settings.training.display_parry then
      parry_gauge_display(player)
   end
   if settings.training.display_charge then
      charge_display(player)
      denjin_display(player)
   end
   if settings.training.display_air_time then
      air_time_display(player, dummy)
   end
   if show_player_position then
      player_position_display()
   end

   top_bar_display(player, true, true, settings.training.display_bonuses)

   frame_advantage_table_display(player, frame_advantage.advantage, settings.training.display_frame_advantage)
   frame_advantage_numbers_display(player, frame_advantage.advantage, settings.training.display_frame_advantage)
   frame_advantage_numbers_display(dummy, frame_advantage.advantage, settings.training.display_frame_advantage)

   -- guard_jump_input_display()

   notification_text_display()

   info_text_display()

   fading_text_display()

   score_text_display()

   player_label_display()

   draw_registered_functions()
end

return {
   init = init,
   draw_hud = draw_hud,
   reset_hud = reset_hud,
   update_hud = update_hud,
   register_draw = register_draw,
   unregister_draw = unregister_draw,
   add_player_label = add_player_label,
   update_blocking_direction = update_blocking_direction,
   add_notification_text = add_notification_text,
   clear_notification_text = clear_notification_text,
   update_active_mode_strikeout = update_active_mode_strikeout,
   reset_active_mode_strikeout = reset_active_mode_strikeout,
   add_info_text = add_info_text,
   clear_info_text = clear_info_text,
   add_fading_text = add_fading_text,
   clear_fading_text = clear_fading_text,
   add_score_text = add_score_text,
   clear_score_text = clear_score_text,
   indicate_player_controllers = indicate_player_controllers,
   hitboxes_display = hitboxes_display,
   life_text_display = life_text_display,
   meter_text_display = meter_text_display,
   stun_text_display = stun_text_display,
   top_bar_display = top_bar_display,
   update_last_hit_bars = update_last_hit_bars,
   last_hit_bars_display = last_hit_bars_display,
   frame_advantage_table_display = frame_advantage_table_display,
   frame_advantage_numbers_display = frame_advantage_numbers_display,
   red_parry_miss_display = red_parry_miss_display,
   stun_timer_display = stun_timer_display,
   fading_text_display = fading_text_display,
   update_input_attempt = update_input_attempt,
   draw_registered_functions = draw_registered_functions,
}
