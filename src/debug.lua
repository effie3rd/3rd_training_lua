local gamestate = require("src.gamestate")
local loading = require("src.loading")
local draw = require("src.ui.draw")
local debug_settings = require("src.debug_settings")
local tools = require("src.tools")
local colors = require("src.ui.colors")
local write_memory = require("src.control.write_memory")

local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = draw.render_text,
                                                                                             draw.render_text_multiple,
                                                                                             draw.get_text_dimensions,
                                                                                             draw.get_text_dimensions_multiple

local dump_state = {}
local function dump_variables()
   if gamestate.is_in_match then
      for _, player in pairs(gamestate.player_objects) do
         dump_state[player.id] = {
            string.format("%d: %s: Char: %d", gamestate.frame_number, player.prefix, player.char_id),
            string.format("Friends: %d", player.friends), string.format("Flip: %d", player.flip_x),
            string.format("x, y: %f, %f", player.pos_x, player.pos_y),
            string.format("Freeze: %d Super Freeze: %d", player.remaining_freeze_frames, player.superfreeze_decount),
            string.format("Input Cap: %d", player.input_capacity),
            string.format("Action: %d Ext: %d Count: %d", player.action, player.action_ext, player.action_count),
            string.format("Recovery Time: %d Flag %d", player.recovery_time, player.recovery_flag),
            string.format("Movement Type: %d Type 2: %d", player.movement_type, player.movement_type2),
            string.format("Posture: %d Ext: %d State: %d", player.posture, player.posture_ext,
                          player.character_state_byte),
            string.format("Is Attacking: %d Ext: %d", player.is_attacking_byte, player.is_attacking_ext_byte),
            string.format("Is Blocking: %s Busy: %d", tostring(player.is_blocking), player.busy_flag),
            string.format("In Basic Action: %s Idle: %s", tostring(player.is_in_basic_action), tostring(player.is_idle)),
            string.format("Next Hit Dmg: %d Stun: %d", player.damage_of_next_hit, player.stun_of_next_hit),
            string.format("Throwing: %s Being Thrown: %s CD: %d", tostring(player.is_throwing),
                          tostring(player.is_being_thrown), player.throw_countdown),
            string.format("Anim: %s Frame %d", tostring(player.animation), player.animation_frame),
            string.format("Frame Id: %s  %s  %s", tostring(player.animation_frame_id),
                          tostring(player.animation_frame_id2), tostring(player.animation_frame_id3)),
            string.format("Anim Hash: %s", player.animation_frame_hash),
            string.format("Recv Hit #: %d Recv Conn #: %d", player.total_received_hit_count,
                          player.received_connection_marker),
            string.format("Hit #: %d Conn Hit #: %d", player.hit_count, player.connected_action_count),
            string.format("Stand State: %d Stunned: %s Ended: %s", player.standing_state, tostring(player.is_stunned),
                          tostring(player.stun_just_ended)),
            string.format("Air Recovery: %s Is Flying Down: %s", tostring(player.is_in_air_recovery),
                          tostring(player.is_flying_down_flag))
         }
      end
   end
end

local function show_dump_state_display()
   if gamestate.is_in_match then
      if #dump_state > 0 then
         for i = 1, #dump_state[1] do render_text(2, 2 + 8 * i, dump_state[1][i], "en") end
         for i = 1, #dump_state[2] do
            local width = get_text_dimensions(dump_state[2][i], "en")
            render_text(draw.SCREEN_WIDTH - 2 - width, 2 + 8 * i, dump_state[2][i], "en")
         end
      end
   end
end

local debug_framedata_data = {}
local function debuggui(name, var)
   if name and var then debug_framedata_data[#debug_framedata_data + 1] = {name, tostring(var)} end
end
local function debug_update_framedata()
   if gamestate.is_in_match then
      local player = gamestate.P1
      local other = player.other

      debug_framedata_data = {}
      debuggui("frame", gamestate.frame_number)
      debuggui("state", require("src.modules.record_framedata").state)
      debuggui("anim", player.animation)
      debuggui("anim f", player.animation_frame)
      -- debuggui("action", player.action)
      -- debuggui("cd", player.cooldown)
      -- debuggui("hash", player.animation_frame_hash)
      -- debuggui("freeze", player.remaining_freeze_frames)
      -- -- debuggui("action #", player.action_count)
      -- -- debuggui("action #", player.animation_action_count)
      -- debuggui("conn action #", player.connected_action_count)
      -- debuggui("just conn", tostring(other.has_just_connected))
      debuggui("hit id", player.current_hit_id)
      -- debuggui("max hit id", player.max_hit_id)
      -- debuggui("is recovery", other.is_in_recovery)
      -- debuggui("proj", player.total_received_projectiles_count)
      debuggui("miss", player.animation_miss_count)
      -- -- debuggui("attacking", tostring(player.is_attacking))
      debuggui("throw invul", player.throw_invulnerability_cooldown)
      debuggui("throw invul2", other.throw_invulnerability_cooldown)
      -- debuggui("throw r f", player.throw_recovery_frame)
      debuggui("wakeup", player.remaining_wakeup_time)
      debuggui("wakeup2", other.remaining_wakeup_time)
      debuggui("pos", string.format("%.04f,%.04f", player.pos_x, player.pos_y))
      debuggui("pos", string.format("%04f,%04f", other.pos_x, other.pos_y))
      -- debuggui("diff", string.format("%04f,%04f",player.pos_x - player.previous_pos_x, player.pos_y - player.previous_pos_y ))
      -- debuggui("diff", string.format("%04f,%04f",other.pos_x - other.previous_pos_x, other.pos_y - other.previous_pos_y ))
      -- debuggui("vel", string.format("%.04f,%.04f", player.velocity_x, player.velocity_y))
      -- debuggui("vel", string.format("%04f,%04f", other.velocity_x, other.velocity_y))
      -- debuggui("acc", string.format("%.04f,%.04f", player.acceleration_x, player.acceleration_y))
      -- debuggui("recording", tostring(recording))

      debuggui("screenx", gamestate.screen_x)

      for _, obj in pairs(gamestate.projectiles) do
         if obj.emitter_id == player.id then
            -- debuggui("s_type", obj.projectile_start_type)
            debuggui("id", obj.id)
            -- debuggui("type", obj.projectile_type)
            -- debuggui("emitter", obj.emitter_id)

            -- debuggui("xy", tostring(obj.pos_x) .. ", " .. tostring(obj.pos_y))
            -- debuggui("friends", obj.friends)
            -- debuggui("anim", obj.animation_frame_hash)
            -- debuggui("frame", obj.animation_frame)
            debuggui("freeze", obj.remaining_freeze_frames)
            -- debuggui("sl", obj.start_lifetime)
            -- debuggui("rl", obj.remaining_lifetime)
            --         if frame_data["projectiles"] and frame_data["projectiles"][obj.projectile_start_type] and frame_data["projectiles"][obj.projectile_start_type].frames[obj.animation_frame+1] then
            --           if obj.animation_frame_hash ~= frame_data["projectiles"][obj.projectile_start_type].frames[obj.animation_frame+1].hash then
            --             debuggui("desync!", obj.animation_frame_hash)
            --           end
            --         end
            -- debuggui("vx", obj.velocity_x)
            -- debuggui("vy", obj.velocity_y)
            debuggui("hits", obj.remaining_hits)
            -- debuggui("ts", obj.tengu_state)
            -- debuggui("order", obj.tengu_order)
            debuggui("cd", obj.cooldown)

            --         debuggui("rem", string.format("%x", obj.remaining_lifetime))
         end
      end
   end
end

local debug_variable_display_max_width = 0
local function variable_display(display_list, right_side)
   if #display_list == 0 then return end
   local x_offset, y_offset = 2, 32
   local x_padding, y_padding = 5, 4
   local height, y_spacing = 0, 1
   local gui_box_bg_color = colors.menu.background
   local max_width, total_height = 0, 0
   for i = 1, #display_list do
      local w, h = get_text_dimensions(string.format("%s: %s", display_list[i][1], display_list[i][2]), "en")
      if w > max_width then max_width = w end
      total_height = total_height + h + y_spacing
      height = h
   end
   max_width = max_width + 2 * x_padding
   total_height = total_height + 2 * y_padding - y_spacing
   local x, y = x_offset, y_offset
   if right_side then
      if max_width > debug_variable_display_max_width then debug_variable_display_max_width = max_width end
      x = draw.SCREEN_WIDTH - x_offset - debug_variable_display_max_width
   end
   gui.box(x, y, x + max_width, y + total_height, gui_box_bg_color, gui_box_bg_color)
   for i = 1, #display_list do
      render_text(x + x_padding, y + y_padding + (height + y_spacing) * (i - 1),
                  string.format("%s: %s", display_list[i][1], display_list[i][2]), "en")
   end
end

local function debug_framedata_display(right_side) variable_display(debug_framedata_data, right_side) end

local debug_variables = {}
local function add_debug_variable(name, getter)
   local n = 1
   for i, var in pairs(debug_variables) do n = n + 1 end
   if name and getter then
      if not debug_variables[name] then
         debug_variables[name] = {name = name, value = tostring(getter()), getter = getter, index = n}
      else
         debug_variables[name] = {
            name = name,
            value = tostring(getter()),
            getter = getter,
            index = debug_variables[name].index
         }
      end
   end
end

local function update_debug_variables() for i, var in pairs(debug_variables) do var.value = tostring(var.getter()) end end

local function debug_variables_display(right_side)
   local debug_display_table = {}
   for i, var in pairs(debug_variables) do debug_display_table[var.index] = {var.name, var.value} end
   variable_display(debug_display_table, right_side)
end

local draw_hitbox_queue = {}
local function queue_hitbox_draw(frame_number, data, tag)
   if not draw_hitbox_queue[frame_number] then
      draw_hitbox_queue[frame_number] = {{data = data, tag = tag}}
   else
      local replaced = false
      for key, boxes in pairs(draw_hitbox_queue[frame_number]) do
         if boxes.tag == tag then
            draw_hitbox_queue[frame_number][key] = {data = data, tag = tag}
            replaced = true
         end
      end
      if not replaced then
         draw_hitbox_queue[frame_number][#draw_hitbox_queue[frame_number] + 1] = {data = data, tag = tag}
      end
   end
end

-- log
local log_enabled = false
local log_categories_display = {}

local logs = {}
local log_sections = {global = 1, P1 = 2, P2 = 3}
local log_categories = {}
local log_recording_on = false
local log_category_count = 0
local current_entry = 1
local log_size_max = 80
local log_line_count_max = 25
local log_line_offset = 0

local log_filtered = {}
local log_start_locked = false
local function log_update(player)
   log_filtered = {}
   if not log_enabled then return end

   -- compute filtered logs
   for i = 1, #logs do
      local frame = logs[i]
      local filtered_frame = {frame = frame.frame, events = {}}
      for j, event in ipairs(frame.events) do
         if log_categories_display[event.category] and log_categories_display[event.category].history then
            filtered_frame.events[#filtered_frame.events + 1] = event
         end
      end

      if #filtered_frame.events > 0 then log_filtered[#log_filtered + 1] = filtered_frame end
   end

   -- process input
   if player.input.down.start then
      if player.input.pressed.HP then
         log_start_locked = true
         log_recording_on = not log_recording_on
         if log_recording_on then log_line_offset = 0 end
      end
      if player.input.pressed.HK then
         log_start_locked = true
         log_line_offset = 0
         logs = {}
      end

      if tools.check_input_down_autofire(player, "up", 4) then
         log_start_locked = true
         log_line_offset = log_line_offset - 1
         log_line_offset = math.max(log_line_offset, 0)
      end
      if tools.check_input_down_autofire(player, "down", 4) then
         log_start_locked = true
         log_line_offset = log_line_offset + 1
         log_line_offset = math.min(log_line_offset, math.max(#log_filtered - log_line_count_max - 1, 0))
      end
   end

   if not player.input.down.start and not player.input.released.start then log_start_locked = false end
end

local function log(section_name, category_name, event_name)
   if not log_enabled then return end

   if log_categories_display[category_name] and log_categories_display[category_name].print then
      print(string.format("%d - [%s][%s] %s", gamestate.frame_number, section_name, category_name, event_name))
   end

   if not log_recording_on then return end

   event_name = event_name or ""
   category_name = category_name or ""
   section_name = section_name or "global"
   if log_sections[section_name] == nil then section_name = "global" end

   if not log_categories_display[category_name] or not log_categories_display[category_name].history then return end

   -- Add category if it does not exists
   if log_categories[category_name] == nil then
      log_categories[category_name] = log_category_count
      log_category_count = log_category_count + 1
   end

   -- Insert frame if it does not exists
   if #logs == 0 or logs[#logs].frame ~= gamestate.frame_number then
      logs[#logs + 1] = {frame = gamestate.frame_number, events = {}}
   end

   -- Remove overflowing logs frame
   while #logs > log_size_max do table.remove(logs, 1) end

   local current_frame = logs[#logs]
   table.insert(current_frame.events, {
      name = event_name,
      section = section_name,
      category = category_name,
      color = tools.string_to_color(event_name)
   })
end

local log_last_displayed_frame = 0
local function log_draw()
   local log = log_filtered
   local log_default_color = 0xF7FFF7FF

   if #log == 0 then return end

   local line_background = {0x333333CC, 0x555555CC}
   local separator_color = 0xAAAAAAFF
   local width = emu.screenwidth() - 10
   local height = emu.screenheight() - 10
   local x_start = 5
   local y_start = 5
   local line_height = 8
   local current_line = 0
   local columns_start = {0, 20, 100}
   local box_size = 6
   local box_margin = 2
   gui.box(x_start, y_start, x_start + width, y_start, 0x00000000, separator_color)
   for i = 0, log_line_count_max do
      local frame_index = #log - (i + log_line_offset)
      if frame_index < 1 then break end
      local frame = log[frame_index]
      local events = {{}, {}, {}}
      for j, event in ipairs(frame.events) do
         if log_categories_display[event.category] and log_categories_display[event.category].history then
            events[log_sections[event.section]][#events[log_sections[event.section]] + 1] = event
         end
      end

      local y = y_start + current_line * line_height
      gui.box(x_start, y, x_start + width, y + line_height, line_background[(i % 2) + 1], 0x00000000)
      for section_i = 1, 3 do
         local box_x = x_start + columns_start[section_i]
         local box_y = y + 1
         for j, event in ipairs(events[section_i]) do
            gui.box(box_x, box_y, box_x + box_size, box_y + box_size, event.color, 0x00000000)
            gui.box(box_x + 1, box_y + 1, box_x + box_size - 1, box_y + box_size - 1, 0x00000000, 0x00000022)
            gui.text(box_x + box_size + box_margin, box_y, event.name, log_default_color, 0x00000000)
            box_x = box_x + box_size + box_margin + draw.get_text_width(event.name) + box_margin
         end
      end

      if frame_index > 1 then
         local frame_diff = frame.frame - log[frame_index - 1].frame
         gui.text(x_start + 2, y + 1, string.format("%d", frame_diff), log_default_color, 0x00000000)
      end
      gui.box(x_start, y + line_height, x_start + width, y + line_height, 0x00000000, separator_color)
      current_line = current_line + 1
      log_last_displayed_frame = frame_index
   end
end

local function log_state(obj, names)
   local str = ""
   for i, name in ipairs(names) do
      if i > 0 then str = str .. ", " end
      str = str .. name .. ":"
      local value = obj[name]
      local type = type(value)
      if type == "boolean" then
         str = str .. string.format("%d", tools.to_bit(value))
      elseif type == "number" then
         str = str .. string.format("%d", value)
      end
   end
   print(str)
end

local start_debug = false

local mem_scan = {}
local MEMORY_VIEW_TYPES = {DEFAULT = 1, RESULTS = 2}
local MEMORY_TYPES = {BYTE = 1, WORD = 2, DWORD = 3}
local GAME_MEMORY_END = 0x40000000 -- maybe?
local memory_view = {
   max_display = 20,
   scroll_boundary_top = 1,
   scroll_boundary_bottom = 20,
   view = {
      addresses = {},
      start_address = 0x02026CB0,
      display_start_index = 1,
      selected_index = 1,
      cursor_position = 1,
      type = MEMORY_VIEW_TYPES.DEFAULT
   },
   view_history = {}
}

local mem_input = {
   down = {down = false, press = false, release = false, state_time = 0},
   up = {down = false, press = false, release = false, state_time = 0},
   left = {down = false, press = false, release = false, state_time = 0},
   right = {down = false, press = false, release = false, state_time = 0},
   enter = {down = false, press = false, release = false, state_time = 0},
   backslash = {down = false, press = false, release = false, state_time = 0},
   backspace = {down = false, press = false, release = false, state_time = 0},
   insert = {down = false, press = false, release = false, state_time = 0},
   delete = {down = false, press = false, release = false, state_time = 0}
}

local function update_input()
   local keys = input.get()
   for key, data in pairs(mem_input) do
      data.press = false
      data.release = false
      if keys[key] then
         if not data.down then
            data.press = true
            data.state_time = 0
         else
            data.state_time = data.state_time + 1
         end
         data.down = true
      else
         if data.down then
            data.release = true
            data.state_time = 0
         else
            data.state_time = data.state_time + 1
         end
         data.down = false
      end
   end
end

local autofire_rate_default = 4
local autofire_time_default = 4
local function check_autofire(mem_inp)
   if not mem_inp then return false end
   local autofire_rate = autofire_rate_default
   local autofire_time = autofire_time_default
   if mem_inp.press then return true end
   if mem_inp.state_time >= 30 then autofire_rate = autofire_rate / 2 end
   if mem_inp.down and mem_inp.state_time > autofire_time and (mem_inp.state_time % autofire_rate) == 0 then
      return true
   end
   return false
end

local function show_memory_view_display()
   memory_view.view.addresses = {}
   if memory_view.view.type == MEMORY_VIEW_TYPES.RESULTS then
      for addr, _ in pairs(mem_scan) do memory_view.view.addresses[#memory_view.view.addresses + 1] = addr end
      table.sort(memory_view.view.addresses)
   else
      for i = 1, memory_view.max_display do
         memory_view.view.addresses[#memory_view.view.addresses + 1] = memory_view.view.start_address + 4 * (i - 1)
      end
   end

   for i, addr in pairs(memory_view.view.addresses) do
      if i >= memory_view.view.display_start_index and i <= memory_view.view.display_start_index +
          memory_view.max_display - 1 then
         local cv = memory.readdword(addr)
         local lw = bit.rshift(cv, 4 * 4)
         local rw = bit.rshift(bit.lshift(cv, 4 * 4), 4 * 4)

         local text = string.format("%08x: %08x %d %d", addr, cv, lw, rw)
         if i == memory_view.view.selected_index then
            local address_length = 10
            local left = string.sub(text, 1, address_length + memory_view.view.cursor_position - 1)
            local cursor = string.sub(text, address_length + memory_view.view.cursor_position,
                                      address_length + memory_view.view.cursor_position)
            local right = string.sub(text, address_length + memory_view.view.cursor_position + 1)
            render_text(5, 2 + (i - 1) * 10, left, "en")
            local w = get_text_dimensions(left, "en") - 1
            render_text(5 + w, 2 + (i - 1) * 10, cursor, "en", nil, colors.text.selected)
            local w2 = get_text_dimensions(cursor, "en") - 1
            render_text(5 + w + w2, 2 + (i - 1) * 10, right, "en")
         else
            render_text(5, 2 + (i - 1) * 10, text, "en")
         end
      else
         break
      end
   end
   update_input()
   if check_autofire(mem_input.down) then
      if memory_view.view.type == MEMORY_VIEW_TYPES.DEFAULT then
         if memory_view.view.selected_index < memory_view.scroll_boundary_bottom then
            memory_view.view.selected_index = memory_view.view.selected_index + 1
         else
            memory_view.view.start_address = memory_view.view.start_address + 0x4
         end
      elseif memory_view.view.type == MEMORY_VIEW_TYPES.RESULTS then
         if memory_view.view.selected_index < memory_view.scroll_boundary_bottom then
            memory_view.view.selected_index = memory_view.view.selected_index + 1
         else
            if memory_view.view.addresses[memory_view.view.display_start_index + memory_view.max_display] then
               memory_view.view.display_start_index = memory_view.view.display_start_index + 1
            end
         end
      end
   end
   if check_autofire(mem_input.up) then
      if memory_view.view.type == MEMORY_VIEW_TYPES.DEFAULT then
         if memory_view.view.selected_index > memory_view.scroll_boundary_top then
            memory_view.view.selected_index = memory_view.view.selected_index - 1
         else
            memory_view.view.start_address = memory_view.view.start_address - 0x4
         end
      elseif memory_view.view.type == MEMORY_VIEW_TYPES.RESULTS then
         if memory_view.view.selected_index > memory_view.scroll_boundary_top then
            memory_view.view.selected_index = memory_view.view.selected_index - 1
         else
            if memory_view.view.addresses[memory_view.view.display_start_index - 1] then
               memory_view.view.display_start_index = memory_view.view.display_start_index - 1
            end
         end
      end
   end
   if check_autofire(mem_input.left) then
      memory_view.view.cursor_position = tools.wrap_index(memory_view.view.cursor_position - 1, 8)
   end
   if check_autofire(mem_input.right) then
      memory_view.view.cursor_position = tools.wrap_index(memory_view.view.cursor_position + 1, 8)
   end
   if check_autofire(mem_input.insert) then
      local addr = memory_view.view.addresses[memory_view.view.selected_index] +
                       math.floor((memory_view.view.cursor_position - 1) / 2)
      local v = memory.readbyte(addr)
      if memory_view.view.cursor_position % 2 == 1 then
         v = v + 0x10
      else
         v = v + 0x01
      end
      memory.writebyte(addr, v)
   end
   if check_autofire(mem_input.delete) then
      local addr = memory_view.view.addresses[memory_view.view.selected_index] +
                       math.floor((memory_view.view.cursor_position - 1) / 2)
      local v = memory.readbyte(addr)
      if memory_view.view.cursor_position % 2 == 1 then
         v = v - 0x10
      else
         v = v - 0x01
      end
      memory.writebyte(addr, v)
   end
   if mem_input.enter.press then
      memory_view.view_history[#memory_view.view_history + 1] = tools.deepcopy(memory_view.view)
      memory_view.view.start_address = memory.readdword(memory_view.view.addresses[memory_view.view.selected_index])
      memory_view.view.display_start_index = 1
      memory_view.view.selected_index = 1
      memory_view.view.type = MEMORY_VIEW_TYPES.DEFAULT
   end
   if mem_input.backslash.press then
      memory_view.view_history[#memory_view.view_history + 1] = tools.deepcopy(memory_view.view)
      memory_view.view.start_address = memory_view.view.addresses[memory_view.view.selected_index]
      memory_view.view.display_start_index = 1
      memory_view.view.selected_index = 1
      memory_view.view.type = MEMORY_VIEW_TYPES.DEFAULT
   end
   if mem_input.backspace.press then
      if memory_view.view_history[#memory_view.view_history] then
         memory_view.view = memory_view.view_history[#memory_view.view_history]
         memory_view.view_history[#memory_view.view_history] = nil
      end
   end

end

local function init_scan_memory(type, aligned)
   local increment = 0x1
   if aligned then
      if type == MEMORY_TYPES.WORD then
         increment = 0x2
      else
         increment = 0x4
      end
   end
   mem_scan = {}
   local i = 0
   while i <= GAME_MEMORY_END do
      local v
      if type == MEMORY_TYPES.BYTE then
         v = memory.readbyte(i)
      elseif type == MEMORY_TYPES.WORD then
         v = memory.readword(i)
      else
         v = memory.readdword(i)
      end
      if v > 0 then mem_scan[i] = v end
      i = i + increment
   end
   memory_view.view.type = MEMORY_VIEW_TYPES.RESULTS
end

local function init_scan_value(n, type, aligned)
   local increment = 0x1
   if aligned then
      if type == MEMORY_TYPES.WORD then
         increment = 0x2
      else
         increment = 0x4
      end
   end
   mem_scan = {}
   local n_res = 0
   local i = 0
   while i <= GAME_MEMORY_END do
      local v
      if type == MEMORY_TYPES.BYTE then
         v = memory.readbyte(i)
      elseif type == MEMORY_TYPES.WORD then
         v = memory.readword(i)
      else
         v = memory.readdword(i)
      end
      if v == n then
         n_res = n_res + 1
         mem_scan[i] = v
      end
      i = i + increment
   end
   memory_view.view.type = MEMORY_VIEW_TYPES.RESULTS
end

local function filter_memory_equals(n, type)
   local to_remove = {}
   for k, v in pairs(mem_scan) do
      local new_v
      if type == MEMORY_TYPES.BYTE then
         new_v = memory.readbyte(k)
      elseif type == MEMORY_TYPES.WORD then
         new_v = memory.readword(k)
      else
         new_v = memory.readdword(k)
      end
      if new_v == n then
         mem_scan[k] = new_v
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do mem_scan[key] = nil end
   memory_view.view.type = MEMORY_VIEW_TYPES.RESULTS
end

local function filter_memory_increased(type)
   local to_remove = {}
   for k, v in pairs(mem_scan) do
      local new_v
      if type == MEMORY_TYPES.BYTE then
         new_v = memory.readbyte(k)
      elseif type == MEMORY_TYPES.WORD then
         new_v = memory.readword(k)
      else
         new_v = memory.readdword(k)
      end
      if new_v > v then
         mem_scan[k] = new_v
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do mem_scan[key] = nil end
   memory_view.view.type = MEMORY_VIEW_TYPES.RESULTS
end

local function filter_memory_decreased(type)
   local to_remove = {}
   for k, v in pairs(mem_scan) do
      local new_v
      if type == MEMORY_TYPES.BYTE then
         new_v = memory.readbyte(k)
      elseif type == MEMORY_TYPES.WORD then
         new_v = memory.readword(k)
      else
         new_v = memory.readdword(k)
      end
      if new_v < v then
         mem_scan[k] = new_v
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do mem_scan[key] = nil end
   memory_view.view.type = MEMORY_VIEW_TYPES.RESULTS
end

local function run_debug()
   if debug_settings.show_dump_state_display then dump_variables() end
   if debug_settings.show_debug_frames_display then debug_update_framedata() end
   if debug_settings.show_debug_variables_display then update_debug_variables() end

   -- if gamestate.frame_number % 2000 == 0 then
   --    collectgarbage()
   --    print("GC memory:", collectgarbage("count"))
   -- end
   local keys = input.get()
   if keys.F12 and loading.frame_data_loaded then debug_settings.recording_framedata = true end

   -- local p = require("src.tools").Perf_Timer:new()
   -- local fps_data = {}
   -- local function average(t)
   --    local sum = 0
   --    for i = 1, #t do sum = sum + t[i] end
   --    return sum / #t
   -- end
   -- local el = p:elapsed()
   -- local fps = 1 / el
   -- if el > 1 / 60 then print(string.format("[draw] frame: %d, fps: %.2f", gamestate.frame_number, 1 / el)) end
   -- fps_data[#fps_data + 1] = fps
   -- if #fps_data > 200 then table.remove(fps_data, 1) end
   -- if loading.images_loaded then draw.render_text(3, 2, string.format("fps: %.2f / %.2f", fps, average(fps_data))) end
end

local function draw_debug()
   local menu = require("src.ui.menu")
   if not menu.is_open or menu.allow_update_while_open then
      if debug_settings.show_dump_state_display then show_dump_state_display() end
      if debug_settings.show_debug_frames_display then debug_framedata_display(true) end
      if debug_settings.show_debug_variables_display then debug_variables_display(true) end
      if debug_settings.show_memory_view_display then show_memory_view_display() end
   end

   local to_remove = {}
   for k, boxes_list in pairs(draw_hitbox_queue) do
      if k >= gamestate.frame_number then
         if k - gamestate.frame_number <= debug_settings.hitbox_display_frames then
            for _, boxes in pairs(boxes_list) do draw.draw_hitboxes(unpack(boxes.data)) end
         end
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do draw_hitbox_queue[key] = nil end
end
-- memory_view_start = 0x24039bb0
local vars = {}
local function debug_things()
   -- local i = 0x02068C6C
   -- while i < 0x02069104 - 0x00000294 do
   --    local a = memory.readdword(i)
   --    vars[i] = a
   --    i = i + 4
   -- end
   -- for i = 0, 21000 do
   --    local a = memory.readdword(memory_view_start + i)
   --    memory.writedword(memory_view_start + i, a + 1)
   -- end
   -- for i = 8000, 14000 do
   --    local a = memory.readdword(memory_view_start - 4 * i)
   --    memory.writedword(memory_view_start + 4 * i, a + 0x00000001)
   -- end
   -- for i = 4000, 12000 do
   --    local a = memory.readdword(memory_view_start - 4 * i)
   --    -- memory.writedword(memory_view_start + 4 * i, a + 0x00000001)
   --    memory.writedword(memory_view_start + 4 * i, a + 0x00010001)
   --    -- memory.writedword(memory_view_start + 4 * i, a + math.random(1, 2))
   -- end
   init_scan_value(0x2402e800, MEMORY_TYPES.DWORD, true)
   -- for k, v in pairs(vars) do memory.writedword(k, v) end
end

local function debug_things2()
   -- for k, v in pairs(vars) do memory.writedword(k, v) end
   -- for i = 0, 21000 do
   --    local a = memory.readdword(memory_view_start + i)
   --    memory.writedword(memory_view_start + i, a + 1)
   -- end
   -- local t = 0x2402e800
   -- local y = 0x2403c000

   local t = 0x2402d13c
   local y = 0x2402e004
   local i = t
   while i <= y do
      local a = memory.readdword(i + 4)
      memory.writedword(i + 4, a + 0x00000001)
      i = i + 4 * 4
   end
-- memory_view.view.start_address = gamestate.P1.addresses.action_address
   --    local t = 0x2402d8fc
   -- local y = 0x2402e004
   -- local i = t
   -- while i <= y do
   --    local a = memory.readdword(i)
   --    vars[i] = a
   --    i = i + 4
   -- end
end

local debug = {
   init_scan_memory = init_scan_memory,
   init_scan_value = init_scan_value,
   filter_memory_equals = filter_memory_equals,
   filter_memory_increased = filter_memory_increased,
   filter_memory_decreased = filter_memory_decreased,
   run_debug = run_debug,
   draw_debug = draw_debug,
   debug_things = debug_things,
   debug_things2 = debug_things2,
   add_debug_variable = add_debug_variable,
   log_update = log_update,
   log = log,
   log_draw = log_draw,
   queue_hitbox_draw = queue_hitbox_draw
}

setmetatable(debug, {
   __index = function(_, key)
      if key == "memory_view" then
         return memory_view
      elseif key == "start_debug" then
         return start_debug
      end
   end,

   __newindex = function(_, key, value)
      if key == "memory_view" then
         memory_view = value
      elseif key == "start_debug" then
         start_debug = value
      else
         rawset(debug, key, value)
      end
   end
})

return debug
