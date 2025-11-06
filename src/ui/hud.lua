-- in-match displays
local settings = require("src.settings")
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local gamestate = require("src.gamestate")
local attack_data = require("src.modules.attack_data")
local text = require("src.ui.text")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local images = require("src.ui.image_tables")
local recording = require("src.control.recording")
local tools = require("src.tools")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local frame_data_meta = fdm.frame_data_meta
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text,
                                                                                             text.render_text_multiple,
                                                                                             text.get_text_dimensions,
                                                                                             text.get_text_dimensions_multiple

local kaiten_images = {
   active = {images.img_dir_small[6], images.img_dir_small[2], images.img_dir_small[4], images.img_dir_small[8]},
   inactive = {
      images.img_dir_inactive[6], images.img_dir_inactive[2], images.img_dir_inactive[4], images.img_dir_inactive[8]
   }
}
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
         gui.image(x + offset_x, y, kaiten_images.active[(i - 1) % 4 + 1])
      else
         gui.image(x + offset_x, y, kaiten_images.inactive[(i - 1) % 4 + 1])
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

      pos_x, pos_y = draw.game_to_screen_space(player.pos_x,
                                               player.pos_y + character_specific[player.char_str].height.standing.min)
      pos_x = pos_x + offset_x
      if player.flip_x == 1 then pos_x = pos_x - (22 * gauge_x_scale + offset_x + 16) end
      pos_y = pos_y
   end

   local y_offset = 0
   local group_y_margin = 6

   local function draw_parry_gauge_group(x, y, parry_object)
      local gauge_height = 4

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
            validity_time_text = string.format("%d", -parry_object.delta)
         else
            validity_time_text = string.format("+%d", -parry_object.delta)
         end
      end

      local str = "parry_" .. parry_object.name

      render_text(x + 1, y, str)
      gui.box(cooldown_gauge_left + 1, y + 11, validity_gauge_left, y + 11, 0x00000000, colors.gauges.outline)
      gui.box(cooldown_gauge_left, y + 10, cooldown_gauge_left, y + 12, 0x00000000, colors.gauges.outline)
      gui.box(validity_gauge_right, y + 11, cooldown_gauge_right - 1, y + 11, 0x00000000, colors.gauges.outline)
      gui.box(cooldown_gauge_right, y + 10, cooldown_gauge_right, y + 12, 0x00000000, colors.gauges.outline)
      draw.draw_gauge(validity_gauge_left, y + 8, validity_gauge_width, gauge_height + 1,
                      parry_object.validity_time / parry_object.max_validity, colors.gauges.valid_fill,
                      colors.gauges.background, colors.gauges.outline, true)
      draw.draw_gauge(cooldown_gauge_left, y + 8 + gauge_height + 2, cooldown_gauge_width, gauge_height,
                      parry_object.cooldown_time / parry_object.max_cooldown, colors.gauges.cooldown_fill,
                      colors.gauges.background, colors.gauges.outline, true)

      gui.box(validity_gauge_left + 3 * gauge_x_scale, y + 8, validity_gauge_left + 2 + 3 * gauge_x_scale,
              y + 8 + gauge_height + 2, colors.gauges.outline, 0x00000000)

      if parry_object.delta then
         local marker_x = validity_gauge_left + parry_object.delta * gauge_x_scale
         marker_x = math.min(math.max(marker_x, x), cooldown_gauge_right)
         gui.box(marker_x, y + 7, marker_x + gauge_x_scale, y + 8 + gauge_height + 2, validity_text_color,
                 validity_outline_color)
      end

      render_text(cooldown_gauge_right + 4, y + 7, validity_time_text, "en", nil, validity_text_color)
      render_text(cooldown_gauge_right + 4, y + 13, cooldown_time_text, "en", nil, validity_text_color)

      return 8 + 5 + (gauge_height * 2)
   end

   local parry_array = {
      {object = player.parry_forward, enabled = true}, {object = player.parry_down, enabled = true},
      {object = player.parry_air, enabled = true}, {object = player.parry_antiair, enabled = true}
   }

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
   if settings.training.charge_overcharge_on then pos_x = 264 end
   local pos_y = 46
   local flip_gauge = false
   local gauge_x_scale = 2

   if settings.training.charge_follow_player then
      local offset_x = 8

      pos_x, pos_y = draw.game_to_screen_space(player.pos_x,
                                               player.pos_y + character_specific[player.char_str].height.standing.min)
      pos_x = pos_x + offset_x
      if player.flip_x == 1 then pos_x = pos_x - (43 * gauge_x_scale + offset_x + 16) end
      pos_y = pos_y
   end

   local y_offset = 0
   local group_y_margin = 6
   local gauge_height = 3
   local overcharge_color = colors.charge.overcharge
   local x_border = 16

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
      if settings.language == "jp" then name_y_offset = -1 end
      render_text(x + 1, y + name_y_offset, charge_object.name)
      draw.draw_gauge(charge_gauge_left, y + 8, charge_gauge_width, gauge_height + 1,
                      charge_object.charge_time / charge_object.max_charge, colors.gauges.valid_fill,
                      colors.gauges.background, colors.gauges.outline, true)
      draw.draw_gauge(reset_gauge_left, y + 8 + gauge_height + 2, reset_gauge_width, gauge_height,
                      charge_object.reset_time / charge_object.max_reset, colors.gauges.cooldown_fill,
                      colors.gauges.background, colors.gauges.outline, true)
      if settings.training.charge_overcharge_on and charge_object.overcharge ~= 0 and charge_object.overcharge < 42 then
         draw.draw_gauge(charge_gauge_left, y + 8, charge_gauge_width, gauge_height + 2,
                         charge_object.overcharge / charge_object.max_charge, overcharge_color,
                         colors.gauges.background, colors.gauges.outline, true)
         local w = get_text_dimensions(charge_time_text, "en")
         render_text(reset_gauge_right + 4 + w, y + 7, overcharge_time_text, "en", nil, charge_text_color)
      end
      if settings.training.charge_overcharge_on and charge_object.overcharge == 0 and charge_object.last_overcharge > 0 and
          charge_object.last_overcharge < 42 then
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

      local reset_gauge_left = x
      local reset_gauge_right = reset_gauge_left + reset_gauge_width + 1
      local validity_time_text = ""
      if kaiten_object.validity_time > 0 then validity_time_text = string.format("%d", kaiten_object.validity_time) end
      local reset_time_text = string.format("%d", kaiten_object.reset_time)

      local name_y_offset = 0
      if settings.language == "jp" then name_y_offset = -1 end
      render_text(x + 1, y + name_y_offset, kaiten_object.name)

      draw_kaiten(x, y + 8, kaiten_object.directions, not player.flip_input)

      draw.draw_gauge(reset_gauge_left, y + 8 + 9, reset_gauge_width, gauge_height,
                      kaiten_object.reset_time / kaiten_object.max_reset, colors.gauges.cooldown_fill,
                      colors.gauges.background, colors.gauges.outline, true)

      render_text(reset_gauge_right + 4, y + 10, validity_time_text, "en", nil)
      render_text(reset_gauge_right + 4, y + 17, reset_time_text, "en", nil)

      return 8 + 5 + 9 + gauge_height
   end

   local function draw_legs_gauge_group(x, y, legs_object)
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
         draw.draw_gauge(x, y + 24, width, gauge_height + 1, legs_object.reset_time / 99, colors.gauges.valid_fill,
                         colors.gauges.background, colors.gauges.outline, true)
      end

      return 8 + 5 + (gauge_height * 2)
   end

   local charge_array = {
      {object = player.charge_1, enabled = player.charge_1.enabled},
      {object = player.charge_2, enabled = player.charge_2.enabled},
      {object = player.charge_3, enabled = player.charge_3.enabled}
   }

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

   if player.legs_state.enabled then draw_legs_gauge_group(pos_x, pos_y + y_offset, player.legs_state) end
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
local air_time_bar_max_height = 5
local function air_time_display(player, dummy)
   local offset_x = 226
   local offset_y = 50
   local juggle_count = memory.readbyte(dummy.addresses.juggle_count)
   local air_time = math.floor((memory.readbyte(dummy.addresses.juggle_time) + 1) / 2)
   local air_time_bar_width = tools.round((air_time / 121) * air_time_bar_max_width)
   local x, y = get_text_dimensions(tostring(juggle_count), "en")
   render_text(offset_x - x, offset_y - 1, juggle_count, "en", nil)
   offset_x = offset_x + 3

   if air_time ~= 128 then
      if air_time > 0 then
         x, y = get_text_dimensions(tostring(air_time), "en")
         render_text(offset_x - x / 2 + air_time_bar_width, offset_y + 6, air_time, "en", nil)
      end
   end
   draw.draw_gauge(offset_x, offset_y, air_time_bar_max_width, air_time_bar_max_height,
                        air_time / 121, colors.gauges.cooldown_fill,
                        colors.gauges.background, colors.gauges.outline, false)
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
   if not (player.char_str == "ryu" and player.selected_sa == 3) then return end
   local x, y = draw.game_to_screen_space(player.pos_x,
                                          player.pos_y + character_specific[player.char_str].height.standing.max)
   x = x - denjin_display_bar_max_width / 2
   y = y - 6 - denjin_display_bar_max_height

   if player.superfreeze_decount > 0 then
      denjin_time = 8
      denjin_value = 3
      denjin_display_is_charging = true
   end
   if not (player.animation == "774c" or player.animation == "90b4") then denjin_display_is_charging = false end
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
   render_text(x + denjin_display_bar_max_width + denjin_display_text_padding, y, tostring(max_timer - denjin_time),
               "en")
   y = y + 2
   -- gui.drawbox(x, y, x + denjin_display_bar_width, y + denjin_display_bar_max_height, barColor)
   -- gui.drawbox(x, y, x + denjin_display_bar_max_width, y + denjin_display_bar_max_height, colors.gauges.background,
   --             colors.gauges.outline)
      draw.draw_gauge(x, y, denjin_display_bar_max_width, denjin_display_bar_max_height,
                        denjin_display_bar_width / denjin_display_bar_max_width, barColor,
                        colors.gauges.background, colors.gauges.outline, false)

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

local function add_fading_text(x, y, str, lang, color, display_time, fade_time, animate)
   table.insert(fading_text_data, {
      x = x,
      y = y,
      text = str,
      lang = lang or settings.language,
      color = color or text.default_color,
      display_time = display_time or fading_text_display_time_default,
      fade_time = fade_time or fading_text_fade_time_default,
      animate = animate,
      elapsed = 0
   })
end

local function clear_fading_text() fading_text_data = {} end

local function fading_text_display()
   local i = 1
   while i <= #fading_text_data do
      local data = fading_text_data[i]
      local elapsed = data.elapsed
      if elapsed <= data.display_time + data.fade_time then
         local opacity = 1
         if elapsed > data.display_time then opacity = 1 - ((elapsed - data.display_time) / data.fade_time) end
         render_text(data.x, data.y, data.text, data.lang, nil, data.color, opacity)
         data.elapsed = data.elapsed + 1
         if data.animate then data.y = data.y - 0.25 end
      else
         table.remove(fading_text_data, i)
      end
      i = i + 1
   end
end

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
   if player.has_just_blocked then last_blocked_frame = gamestate.frame_number end
   local elapsed = gamestate.frame_number - red_parry_display_start_frame

   if gamestate.frame_number - last_blocked_frame <= 30 then
      local parry_objects = {player.parry_forward, player.parry_down}
      for i = 1, #parry_objects do
         if parry_objects[i].validity_time > 0 and elapsed >= 15 then watch_parry_object[i] = true end
         if watch_parry_object[i] then
            if player.has_just_been_hit or parry_objects[i].validity_time <= 0 then
               watch_parry_object[i] = false
               if parry_objects[i].delta then
                  if not parry_objects[i].success then
                     if parry_objects[i].delta >= 0 then
                        red_parry_miss_display_text = string.format("%d", -parry_objects[i].delta)
                     else
                        red_parry_miss_display_text = string.format("+%d", -parry_objects[i].delta)
                     end
                     local sign = 1
                     if player.flip_x == 1 then sign = -1 end

                     red_parry_miss_display_x =
                         player.pos_x - sign * character_specific[player.char_str].half_width * 3 / 4
                     red_parry_miss_display_y = player.pos_y + character_specific[player.char_str].height.standing.max *
                                                    3 / 4
                     red_parry_display_start_frame = gamestate.frame_number
                     local x, y = draw.game_to_screen_space(red_parry_miss_display_x, red_parry_miss_display_y)
                     add_fading_text(x, y, red_parry_miss_display_text, "en", colors.red_parry_miss,
                                     red_parry_miss_display_time, red_parry_miss_fade_time)
                  end
               end
            end
         end
      end
   end
end

local attack_range_display_attacks = {{}, {}}
local attack_range_display_data = {}
local attack_range_display_start_pos = {}
local attack_range_display_attack_box_colors = {
   colors.colorscale(colors.hitboxes.attack, 0.6), colors.colorscale(colors.hitboxes.push, 0.6), 0x670EAAFF
}
local attack_range_display_throw_box_colors = {
   colors.colorscale(colors.hitboxes.throw, 0.6), colors.colorscale(colors.hitboxes.throwable, 0.6),
   colors.colorscale(colors.hitboxes.extvulnerability, 0.6)
}

local function attack_range_display_reset()
   attack_range_display_attacks = {{}, {}}
   attack_range_display_data = {}
end

-- needs to be rewritten due to framedata changes
local function attack_range_display()
   if not require("src.loading").frame_data_loaded then return end
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
         attack_range_display_start_pos[id] = {player.previous_pos_x, player.previous_pos_y}
         fdata = frame_data[player.char_str][player.animation]
         if fdata and fdata.hit_frames then
            if not tools.table_contains(attack_range_display_attacks[id], player.animation) then
               table.insert(attack_range_display_attacks[id], player.animation)
            end
         end
      end
      while #attack_range_display_attacks[id] > settings.training.attack_range_display_max_attacks do
         table.remove(attack_range_display_attacks[id], 1)
      end

      local sign = tools.flip_to_sign(player.flip_x)
      local attack_color_index = 1
      local throw_color_index = 1
      for i = 1, #attack_range_display_attacks[id] do
         local attack_anim = attack_range_display_attacks[id][i]
         if player.animation == attack_anim then
            local last_hit_frame = 0
            local offset_x = 0
            local offset_y = 0
            local velocity_x = 0
            local velocity_y = 0
            local acceleration_x = 0
            local acceleration_y = 0

            fdata = frame_data[player.char_str][attack_anim]
            if fdata and fdata.hit_frames then
               last_hit_frame = fdata.hit_frames[#fdata.hit_frames][2] + 1
               attack_range_display_data[attack_anim] = {}
               for j = 1, last_hit_frame do
                  velocity_x = velocity_x + acceleration_x
                  velocity_y = velocity_y + acceleration_y
                  offset_x = offset_x + velocity_x
                  offset_y = offset_y + velocity_y
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
                        local b = tools.format_box(box)
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
         local drawn_box_type = ""
         local attack_range_display_attack_box_color = attack_range_display_attack_box_colors[attack_color_index]
         local attack_range_display_throw_box_color = attack_range_display_throw_box_colors[throw_color_index]
         local posx, posy = player.pos_x, player.pos_y
         if player.animation == attack_anim then
            posx, posy = attack_range_display_start_pos[id][1], attack_range_display_start_pos[id][2]
         end
         for _, data in pairs(attack_range_display_data[attack_anim]) do
            local current_box = data.box
            local box = tools.format_box(data.box)
            local height_below_zero = (posy + data.offset_y + box.bottom) * -1
            if height_below_zero > 0 then
               box.bottom = box.bottom + height_below_zero
               current_box = tools.create_box(box)
            end

            draw.draw_hitboxes(posx + sign * data.offset_x, posy + data.offset_y, player.flip_x, {current_box},
                               {["attack"] = true}, nil, attack_range_display_attack_box_color)
            draw.draw_hitboxes(posx + sign * data.offset_x, posy + data.offset_y, player.flip_x, {current_box},
                               {["throw"] = true}, nil, attack_range_display_throw_box_color)
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
                  local box = tools.format_box(data.box)
                  if player.flip_x == 0 then
                     text_x = math.max(posx + sign * (data.offset_x - box.left - box.width / 2) - w / 2,
                                       posx + sign * (data.offset_x - box.left) + 2)
                  else
                     text_x = math.max(posx + sign * (data.offset_x - box.left - box.width / 2) - w / 2,
                                       posx + sign * (data.offset_x - box.left) - box.width + 2)
                  end
                  local dist_text_x, dist_text_y = draw.game_to_screen_space(text_x, posy + data.offset_y + box.bottom +
                                                                                 box.height / 2)
                  render_text(dist_text_x, dist_text_y - 3, data.distance, "en")
               end
            end
         end
      end
   end
end

local last_hit_history = nil
local last_hit_history_size = 2

local function last_hit_bars_reset() last_hit_history = nil end

local function last_hit_bars_display()
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
               last_hit_history[1] = tools.deepcopy(attack_data.data)
            else
               table.insert(last_hit_history, 1, tools.deepcopy(attack_data.data))
               while #last_hit_history > last_hit_history_size do
                  table.remove(last_hit_history, #last_hit_history)
               end
            end
         else
            last_hit_history = {tools.deepcopy(attack_data.data)}
         end
      end
      if last_hit_history then
         for i = 1, #last_hit_history do
            if last_hit_history[i].total_damage > 0 then
               local life_width = last_hit_history[i].total_damage
               local life_offset = 160 - last_hit_history[i].start_life

               if last_hit_history[i].player_id == 1 then life_width = life_width - 2 end
               if last_hit_history[i].player_id == 1 then
                  life_x = draw.SCREEN_WIDTH - 8
                  stun_x = life_x - life_max_width + 1
                  sign = -1
               end

               gui.drawline(life_x + sign * life_offset, life_y - (i - 1) * life_height,
                            life_x + sign * life_offset + sign * life_width - 1, life_y - (i - 1) * life_height,
                            colors.last_hit_bars.life)
               gui.drawline(life_x + sign * life_offset, life_y - (i - 1) * life_height, life_x + sign * life_offset,
                            life_y - (i - 1) * life_height + 2, colors.last_hit_bars.life)
               gui.drawline(life_x + sign * life_offset + sign * life_width - 1, life_y - (i - 1) * life_height,
                            life_x + sign * life_offset + sign * life_width - 1, life_y - (i - 1) * life_height + 2,
                            colors.last_hit_bars.life)
               local text_width = get_text_dimensions(tostring(last_hit_history[i].total_damage), "en")
               local text_pos_x = tools.round(sign * (life_width - text_width) / 2) + life_x + sign * life_offset
               --           if text_width + 4 > life_width then
               --             text_pos_x = life_x+sign*life_offset+sign*life_width - 1 + 2 * sign
               --           else
               if last_hit_history[i].player_id == 1 then text_pos_x = text_pos_x - text_width end
               local text_pos_y = 9 - (i - 1) * life_height
               render_text(text_pos_x, text_pos_y, tostring(last_hit_history[i].total_damage), "en", nil,
                           colors.last_hit_bars.life)

               local stun_width = last_hit_history[i].total_stun
               local stun_offset = last_hit_history[i].start_stun

               if stun_width > 0 then
                  if last_hit_history[i].player_id == 2 then stun_width = stun_width - 2 end

                  gui.drawline(stun_x - sign * stun_offset, stun_y + (i - 1) * stun_height,
                               stun_x - sign * stun_offset - sign * stun_width - 1, stun_y + (i - 1) * stun_height,
                               colors.last_hit_bars.stun)
                  gui.drawline(stun_x - sign * stun_offset, stun_y + (i - 1) * stun_height, stun_x - sign * stun_offset,
                               stun_y + (i - 1) * stun_height - 1, colors.last_hit_bars.stun)
                  gui.drawline(stun_x - sign * stun_offset - sign * stun_width - 1, stun_y + (i - 1) * stun_height,
                               stun_x - sign * stun_offset - sign * stun_width - 1, stun_y + (i - 1) * stun_height - 1,
                               colors.last_hit_bars.stun)
                  if settings.training.attack_bars_show_decimal then
                     text_width = get_text_dimensions(string.format("%.2f", last_hit_history[i].total_stun), "en")
                     text_pos_x = stun_x - sign * stun_offset - sign * stun_width - 1 - 2 * sign
                     if last_hit_history[i].player_id == 2 then text_pos_x = text_pos_x - text_width end
                     text_pos_y = stun_y + (i - 1) * stun_height - 2
                     render_text(text_pos_x, text_pos_y, string.format("%.2f", last_hit_history[i].total_stun), "en",
                                 nil, colors.last_hit_bars.stun)
                  else
                     text_width = get_text_dimensions(tostring(tools.round(last_hit_history[i].total_stun)), "en")
                     text_pos_x = tools.round(-1 * sign * (stun_width - text_width) / 2) + stun_x - sign * stun_offset
                     if last_hit_history[i].player_id == 2 then text_pos_x = text_pos_x - text_width end
                     text_pos_y = stun_y + (i - 1) * stun_height - 2
                     render_text(text_pos_x, text_pos_y, tostring(tools.round(last_hit_history[i].total_stun)), "en",
                                 nil, colors.last_hit_bars.stun)
                  end
               end
            end
         end
      end
   end
end

local function get_stun_timer_position(player)
   local char_height = tools.get_boxes_highest_position(player.boxes, {"vulnerability"})
   return draw.game_to_screen_space(player.pos_x, player.pos_y + char_height)
end
local stun_timer_max_width = 60
local stun_timer_half_width = math.floor(stun_timer_max_width / 2)
local stun_timer_max_value = 240
local stun_timer_gauge_height = 2
local stun_timer_state = {{stunned_y_pos = 0, capture_next_pos = false}, {stunned_y_pos = 0, capture_next_pos = false}}
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
   ["shingouki"] = 4
}

local function stun_timer_display_reset()
   stun_timer_state = {{stunned_y_pos = 0, capture_next_pos = false}, {stunned_y_pos = 0, capture_next_pos = false}}
end

local function stun_timer_display(player)
   local id = player.id
   if player.is_stunned then
      if stun_timer_state[id].capture_next_pos then
         local char_height = tools.get_boxes_highest_position(player.boxes, {"vulnerability"})
         if char_height then
            local x, y = draw.game_to_screen_space(player.pos_x, player.pos_y + char_height)
            if stun_timer_position_adjust[player.char_str] then
               y = y - stun_timer_position_adjust[player.char_str]
            end
            stun_timer_state[id].stunned_y_pos = y
            stun_timer_state[id].capture_next_pos = false
         end
      end
      if player.just_recovered or player.has_just_woke_up then stun_timer_state[id].capture_next_pos = true end
      if player.stun_timer > 0 then
         local stun_text = player.stun_timer
         local pos_x, pos_y = get_stun_timer_position(player)

         if player.standing_state == 1 or (player.char_str == "alex" and player.standing_state == 13) or
             (player.char_str == "hugo" and player.standing_state == 2) or
             (player.char_str == "ibuki" and player.standing_state == 10) then
            pos_y = stun_timer_state[id].stunned_y_pos
         end
         local text_w, text_h = get_text_dimensions(stun_text, "en")

         pos_x = pos_x - stun_timer_half_width
         pos_x = tools.clamp(pos_x, 1, draw.SCREEN_WIDTH - stun_timer_max_width - 2)
         pos_y = pos_y - 8
         draw.draw_gauge(pos_x, pos_y, stun_timer_max_width, stun_timer_gauge_height,
                         player.stun_timer / stun_timer_max_value, colors.gauges.cooldown_fill,
                         colors.gauges.background, colors.gauges.outline)

         render_text(pos_x + stun_timer_half_width - tools.round(text_w / 2), pos_y - text_h, stun_text, "en")
      end
   end
end

local player_label_display_time = 90
local player_label_fade_time = 30
local player_label_state = {{start_frame = 0, label = ""}, {start_frame = 0, label = ""}}

local function player_label_reset() player_label_state = {{start_frame = 0, label = ""}, {start_frame = 0, label = ""}} end

-- hud_cpu hud_p1 hud_p2 hud_dummy
local function add_player_label(player, label)
   player_label_state[player.id].start_frame = gamestate.frame_number
   player_label_state[player.id].label = label
end

local function player_label_display()
   for id, state in ipairs(player_label_state) do
      local elapsed = gamestate.frame_number - state.start_frame
      if elapsed <= player_label_display_time + player_label_fade_time then
         local opacity = 1
         if elapsed > player_label_display_time then
            opacity = 1 - ((elapsed - player_label_display_time) / player_label_fade_time)
         end
         local player = gamestate.player_objects[id]
         local x, y = draw.get_above_character_position(player)
         y = y - 2
         gui.image(x - 4, y, images.img_dir_small[2], opacity)
         local w, h = get_text_dimensions(state.label)
         if settings.language == "en" then
            h = h - 1
         elseif settings.language == "jp" then
            h = h + 1
         end
         render_text(x - tools.round(w / 2), y - h, state.label, nil, nil, nil, opacity)
      end
   end
end

local blocking_direction_history = {}
local blocking_dir = 1
local last_dir = 1

local function blocking_direction_display_reset() blocking_direction_history = {} end

local function update_blocking_direction(input, player, dummy)
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
      if dummy.blocking.last_block.frame_number == gamestate.frame_number and dummy.blocking.last_block.sub_type ~=
          "pass" and blocking_dir ~= last_dir then
         table.insert(blocking_direction_history, {start_frame = gamestate.frame_number, dir = blocking_dir})
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
         gui.image(x, y - (#blocking_direction_history - i - 1) * offset_y,
                   images.img_dir_small[blocking_direction_history[i].dir], opacity)
         i = i + 1
      else
         table.remove(blocking_direction_history, i)
      end
   end
end

local function hitboxes_display()
   -- players
   local p1_filter = {["attack"] = true, ["throw"] = true} -- debug
   local p2_filter = nil
   -- draw.draw_hitboxes(gamestate.P1.pos_x, gamestate.P1.pos_y, gamestate.P1.flip_x, gamestate.P1.boxes, fff, nil, nil, 0x90)

   draw.draw_hitboxes(gamestate.P1.pos_x, gamestate.P1.pos_y, gamestate.P1.flip_x, gamestate.P1.boxes, nil, nil, nil,
                      settings.training.display_hitboxes_opacity)
   draw.draw_hitboxes(gamestate.P1.pos_x, gamestate.P1.pos_y, gamestate.P1.flip_x, gamestate.P1.boxes, p1_filter, nil,
                      nil)
   draw.draw_hitboxes(gamestate.P2.pos_x, gamestate.P2.pos_y, gamestate.P2.flip_x, gamestate.P2.boxes, p2_filter, nil,
                      nil, settings.training.display_hitboxes_opacity)

   -- projectiles
   for _, obj in pairs(gamestate.projectiles) do
      draw.draw_hitboxes(obj.pos_x, obj.pos_y, obj.flip_x, obj.boxes, nil, nil, nil,
                         settings.training.display_hitboxes_opacity)
   end
end

local function bonuses_display(player_object)
   local x = 0
   local y = 4
   local padding = 4
   local spacing = 4
   local lang = settings.language
   if player_object.id == 1 then
      x = padding
   elseif player_object.id == 2 then
      x = draw.SCREEN_WIDTH - padding
   end
   if player_object.damage_bonus > 0 then
      -- gui.text(x, y, t, 0xFF7184FF, 0x392031FF)
      local bonus_text = {"+", player_object.damage_bonus, "bonus_damage"}
      local w, h = 0, 0
      if lang == "en" then
         w, h = get_text_dimensions_multiple(bonus_text)
      elseif lang == "jp" then
         w, h = get_text_dimensions_multiple(bonus_text, "jp", "8")
      end
      if player_object.id == 2 then x = x - w - spacing end
      if lang == "en" then
         render_text_multiple(x, y, bonus_text, "en", nil, colors.bonuses.damage)
      elseif lang == "jp" then
         render_text_multiple(x, y, bonus_text, "jp", "8", colors.bonuses.damage)
      end
      if player_object.id == 1 then x = x + w + spacing end
   end

   if player_object.defense_bonus > 0 then
      local bonus_text = {"+", player_object.defense_bonus, "bonus_defense"}
      local w, h = 0, 0
      if lang == "en" then
         w, h = get_text_dimensions_multiple(bonus_text)
      elseif lang == "jp" then
         w, h = get_text_dimensions_multiple(bonus_text, "jp", "8")
      end
      if player_object.id == 2 then x = x - w - spacing end
      if lang == "en" then
         render_text_multiple(x, y, bonus_text, "en", nil, colors.bonuses.defense)
      elseif lang == "jp" then
         render_text_multiple(x, y, bonus_text, "jp", "8", colors.bonuses.defense)
      end
      if player_object.id == 1 then x = x + w + spacing end
   end

   if player_object.stun_bonus > 0 then
      local bonus_text = {"+", player_object.stun_bonus, "bonus_stun"}
      local w, h = 0, 0
      if lang == "en" then
         w, h = get_text_dimensions_multiple(bonus_text)
      elseif lang == "jp" then
         w, h = get_text_dimensions_multiple(bonus_text, "jp", "8")
      end
      if player_object.id == 2 then x = x - w - spacing end
      if lang == "en" then
         render_text_multiple(x, y, bonus_text, "en", nil, colors.bonuses.stun)
      elseif lang == "jp" then
         render_text_multiple(x, y, bonus_text, "jp", "8", colors.bonuses.stun)
      end
      if player_object.id == 1 then x = x + w + spacing end
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
   local g = {type = "point", x = pos_x, y = pos_y, color = color}
   table.insert(printed_geometry, g)
end

local function clear_printed_geometry() printed_geometry = {} end

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

   if player_object.meter_count == player_object.max_meter_count then gauge = player_object.max_meter_gauge end

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

   local t = string.format("%d/%d", math.floor(player_object.stun_bar), player_object.stun_bar_max)

   if player_object.id == 1 then
      x = 167 - player_object.stun_bar_max + 3
   elseif player_object.id == 2 then
      x = 216 + player_object.stun_bar_max - draw.get_text_width(t) - 1
   end

   gui.text(x, y, t, 0xe60000FF, 0x001433FF)
end

local function display_draw_distances(p1_object, p2_object, mid_distance_height, p1_reference_point, p2_reference_point)

   local function find_closest_box_at_height(player, height, box_types)

      local px = player.pos_x
      local py = player.pos_y

      local left, right = px, px

      if box_types == nil then return false, left, right end

      local has_boxes = false
      for __, box in ipairs(player.boxes) do
         box = tools.format_box(box)
         if box_types[box.type] then
            local l, r, b, t
            if player.flip_x == 0 then
               l = px + box.left
            else
               l = px - box.left - box.width
            end
            r = l + box.width
            b = py + box.bottom
            t = b + box.height

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
      if not ((box1_l >= box2_r) or (box1_r <= box2_l)) then return false end

      if box1_l < box2_l then
         return true, draw.game_to_screen_space_x(box1_r), draw.game_to_screen_space_x(box2_l)
      else
         return true, draw.game_to_screen_space_x(box2_r), draw.game_to_screen_space_x(box1_l)
      end
   end

   local text_default_color = 0xF7FFF7FF
   local text_default_border_color = 0x000000FF
   local function display_distance(p1_object, p2_object, height, box_types, p1_ref_point, p2_ref_point, color)
      local y = math.min(p1_object.pos_y + height, p2_object.pos_y + height)
      local p1_l, p1_r, p2_l, p2_r
      local p1_result, p2_result = false, false
      if p1_ref_point == 2 then p1_result, p1_l, p1_r = find_closest_box_at_height(p1_object, y, box_types) end
      if not p1_result then p1_l, p1_r = p1_object.pos_x, p1_object.pos_x end
      if p2_ref_point == 2 then p2_result, p2_l, p2_r = find_closest_box_at_height(p2_object, y, box_types) end
      if not p2_result then p2_l, p2_r = p2_object.pos_x, p2_object.pos_x end

      local line_result, screen_l, screen_r = get_screen_line_between_boxes(p1_l, p1_r, p2_l, p2_r)

      if line_result then
         local screen_y = draw.game_to_screen_space_y(y)
         local str = string.format("%d", math.abs(screen_r - screen_l))
         draw.draw_horizontal_text_segment(screen_l, screen_r, screen_y, str, color)
      end
   end

   -- throw
   display_distance(p1_object, p2_object, 2, {throwable = true}, p1_reference_point, p2_reference_point, 0x08CF00FF)

   -- low and mid
   local hurtbox_types = {}
   hurtbox_types["vulnerability"] = true
   hurtbox_types["ext. vulnerability"] = true
   display_distance(p1_object, p2_object, 10, hurtbox_types, p1_reference_point, p2_reference_point, 0x00E7FFFF)
   display_distance(p1_object, p2_object, mid_distance_height, hurtbox_types, p1_reference_point, p2_reference_point,
                    0x00E7FFFF)

   -- player positions
   local line_color = 0xFFFF63FF
   local p1_screen_x, p1_screen_y = draw.game_to_screen_space(p1_object.pos_x, p1_object.pos_y)
   local p2_screen_x, p2_screen_y = draw.game_to_screen_space(p2_object.pos_x, p2_object.pos_y)
   draw.draw_point(p1_screen_x, p1_screen_y, line_color)
   draw.draw_point(p2_screen_x, p2_screen_y, line_color)
   gui.text(p1_screen_x + 3, p1_screen_y + 2, string.format("%d:%d", p1_object.pos_x, p1_object.pos_y),
            text_default_color, text_default_border_color)
   gui.text(p2_screen_x + 3, p2_screen_y + 2, string.format("%d:%d", p2_object.pos_x, p2_object.pos_y),
            text_default_color, text_default_border_color)
end

local function recording_display(dummy)
   local current_recording_size = 0
   if (recording.recording_slots[settings.training.current_recording_slot].inputs) then
      current_recording_size = #recording.recording_slots[settings.training.current_recording_slot].inputs
   end
   local x = 0
   local y = 4
   local padding = 4
   local lang = settings.language
   if recording.current_recording_state == 2 then
      local text = {
         "hud_slot", " ", settings.training.current_recording_slot, ": ", "hud_wait_for_recording", " ",
         current_recording_size
      }
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
   elseif recording.current_recording_state == 3 then
      local text = {
         "hud_slot", " ", settings.training.current_recording_slot, ": ", "hud_recording", "... (",
         current_recording_size, ")"
      }
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
   elseif recording.current_recording_state == 4 and dummy.pending_input_sequence and
       dummy.pending_input_sequence.sequence then
      local text = {""}
      if settings.training.replay_mode == 1 or settings.training.replay_mode == 4 then
         text = {
            "hud_playing", " (", dummy.pending_input_sequence.current_frame, "/",
            #dummy.pending_input_sequence.sequence, ")"
         }
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

local is_please_wait_display_on = false
local function show_please_wait_display(bool) is_please_wait_display_on = bool end

local function please_wait_display()
   local x, y = 0, 45
   local tx, ty = get_text_dimensions("please_wait")
   if settings.training.language == 1 then ty = ty - 1 end
   local fade_in = 14
   local width, height = tx + fade_in * 2 + 6, ty + 4
   x = math.floor((draw.SCREEN_WIDTH - width) / 2)
   local base_color = bit.lshift(bit.rshift(colors.menu.background, 8), 8)
   local opacity = bit.band(colors.menu.background, 0xFF)

   for pad = 0, fade_in - 1 do
      local color = base_color + math.floor(opacity * (pad + 1) / fade_in)
      gui.box(x + pad, y, x + pad, y + height, 0x00000000, color)
      gui.box(x + width - pad, y, x + width - pad, y + height, 0x00000000, color)
   end
   gui.box(x + fade_in, y, x + width - fade_in, y + height, colors.menu.background, colors.menu.background)
   local textx = tools.round(x + width / 2 - tx / 2)
   local texty = tools.round(y + height / 2 - ty / 2)
   if settings.training.language == 1 then texty = texty + 1 end
   render_text(textx, texty, "please_wait")
end

local info_text_display_time = 90
local info_text_fade_time = 30
local info_text_state = {{data = {}, display_start_frame = 0}, {data = {}, display_start_frame = 0}}

local function add_info_text(list, id)
   info_text_state[id].data = list
   info_text_state[id].display_start_frame = gamestate.frame_number
end

local function clear_info_text()
   info_text_state = {{data = {}, display_start_frame = 0}, {data = {}, display_start_frame = 0}}
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
            if width > text_max_width then text_max_width = width end
            if height > text_max_height then text_max_height = height end
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

         if id == 2 then x = x - text_max_width end

         for _, data in ipairs(info_text_state[id].data) do
            if type(data) == "table" then
               render_text_multiple(x, y, data, nil, nil, nil, opacity)
            else
               render_text(x, y, data, nil, nil, nil, opacity)
            end
            y = y + text_max_height + spacing_y
         end
      end
   end
end

local score_text
local function add_score_text(str) score_text = str end

local function clear_score_text() score_text = nil end
local function score_text_display()
   if score_text then
      local padding_x = 10
      local x, y = padding_x, 50

      local input_history_offset = 34

      if settings.training.display_input_history == 2 or settings.training.display_input_history == 4 then
         x = x + input_history_offset
      end
      render_text(x, y, score_text, "score", nil, colors.score.plus)
   end
end

local show_player_position = true
local function player_position_display()
   local x, y = draw.game_to_screen_space(gamestate.P1.pos_x, gamestate.P1.pos_y)
   gui.image(x - 4, y, images.img_dir_small[8])
   x, y = draw.game_to_screen_space(gamestate.P2.pos_x, gamestate.P2.pos_y)
   gui.image(x - 4, y, images.img_dir_small[8])
end

local draw_list = {}
local function register_draw(func) draw_list[func] = func end

local function unregister_draw(func) draw_list[func] = nil end

local function draw_registered_functions() for _, func in pairs(draw_list) do func() end end

local function reset_hud()
   attack_range_display_reset()
   blocking_direction_display_reset()
   last_hit_bars_reset()
   red_parry_miss_display_reset()
   stun_timer_display_reset()
   player_label_reset()
   clear_fading_text()
   clear_score_text()

   is_please_wait_display_on = false
end

local function draw_hud(player, dummy)
   if settings.training.display_attack_range ~= 1 then attack_range_display() end

   if settings.training.display_hitboxes then hitboxes_display() end

   last_hit_bars_display()

   if settings.training.display_red_parry_miss then red_parry_miss_display(player) end
   if settings.training.display_blocking_direction then blocking_direction_display(player, dummy) end
   if settings.training.display_stun_timer then
      stun_timer_display(player)
      stun_timer_display(dummy)
   end
   if settings.training.display_parry then
      parry_gauge_display(player.other) -- debug
   end
   if settings.training.display_charge then
      charge_display(player)
      denjin_display(player)
   end
   if settings.training.display_air_time then air_time_display(player, dummy) end
   if show_player_position then player_position_display() end
   if recording.current_recording_state ~= 1 then recording_display(dummy) end
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
      display_draw_distances(gamestate.P1, gamestate.P2, settings.training.mid_distance_height,
                             settings.training.p1_distances_reference_point,
                             settings.training.p2_distances_reference_point)
   end

   if is_please_wait_display_on then please_wait_display() end

   info_text_display()

   fading_text_display()

   score_text_display()

   player_label_display()

   draw_registered_functions()
end

return {
   draw_hud = draw_hud,
   reset_hud = reset_hud,
   register_draw = register_draw,
   unregister_draw = unregister_draw,
   add_player_label = add_player_label,
   update_blocking_direction = update_blocking_direction,
   show_please_wait_display = show_please_wait_display,
   add_info_text = add_info_text,
   clear_info_text = clear_info_text,
   add_fading_text = add_fading_text,
   clear_fading_text = clear_fading_text,
   add_score_text = add_score_text,
   clear_score_text = clear_score_text
}
