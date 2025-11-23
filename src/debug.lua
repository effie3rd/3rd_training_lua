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
            string.format("Posture: %d State: %d", player.posture, player.character_state_byte),
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
      -- debuggui("throw invul", player.throw_invulnerability_cooldown)
      -- debuggui("throw r f", player.throw_recovery_frame)
      debuggui("miss", player.animation_miss_count)
      -- -- debuggui("attacking", tostring(player.is_attacking))
      -- debuggui("wakeup", player.remaining_wakeup_time)
      -- debuggui("wakeup2", other.remaining_wakeup_time)
      -- debuggui("pos", string.format("%.04f,%.04f", player.pos_x, player.pos_y))
      -- debuggui("pos", string.format("%04f,%04f",other.pos_x, other.pos_y))
      -- debuggui("diff", string.format("%04f,%04f",player.pos_x - player.previous_pos_x, player.pos_y - player.previous_pos_y ))
      -- debuggui("diff", string.format("%04f,%04f",other.pos_x - other.previous_pos_x, other.pos_y - other.previous_pos_y ))
      -- debuggui("vel", string.format("%.04f,%.04f", player.velocity_x, player.velocity_y))
      -- debuggui("vel", string.format("%04f,%04f", other.velocity_x, other.velocity_y))
      -- debuggui("acc", string.format("%.04f,%.04f", player.acceleration_x, player.acceleration_y))
      -- debuggui("recording", tostring(recording))

      -- debuggui("screenx", gamestate.screen_x)

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
start_debug = false
local mem_scan = {}

local function show_memory_results_display()
   local n = 1
   for k, v in pairs(mem_scan) do
      if n <= 20 then
         local cv = memory.readbyte(k)
         local text = string.format("%x: %08x %d", k, cv, cv)
         render_text(5, 2 + (n - 1) * 10, text, "en")
      else
         break
      end
      n = n + 1
   end
end

local memory_view_start = 0x2069118
local function show_memory_view_display()
   for i = 1, 20 do
      local addr = memory_view_start + 4 * (i - 1)
      local cv = memory.readdword(addr)
      local lw = bit.rshift(cv, 4 * 4)
      local rw = bit.rshift(bit.lshift(cv, 4 * 4), 4 * 4)

      local text = string.format("%x: %08x %d %d", addr, cv, lw, rw)
      render_text(5, 2 + (i - 1) * 10, text, "en")
   end
   local keys = input.get()
   if keys.down then memory_view_start = memory_view_start + 4 end
   if keys.up then memory_view_start = memory_view_start - 4 end
end

local function init_scan_memory()
   mem_scan = {}
   for i = 0, 80000000 do
      local v = memory.readdword(i)
      if v > 0 then mem_scan[i] = v end
   end
end

local function init_scan_value(n)
   mem_scan = {}
   for i = 0, 80000000 do
      local v = memory.readdword(i)
      if v == n then 
         mem_scan[i] = v end
   end
end

local function filter_memory_equals(n)
   local to_remove = {}
   for k, v in pairs(mem_scan) do
      local new_v = memory.readbyte(k)
      if new_v == n then
         mem_scan[k] = new_v
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do mem_scan[key] = nil end
end

local function filter_memory_increased()
   local to_remove = {}
   for k, v in pairs(mem_scan) do
      local new_v = memory.readbyte(k)
      if new_v > v then
         mem_scan[k] = new_v
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do mem_scan[key] = nil end
end

local function filter_memory_decreased()
   local to_remove = {}
   for k, v in pairs(mem_scan) do
      local new_v = memory.readbyte(k)
      if new_v < v then
         mem_scan[k] = new_v
      else
         to_remove[#to_remove + 1] = k
      end
   end
   for _, key in ipairs(to_remove) do mem_scan[key] = nil end
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

   -- local p = tools.Perf_Timer:new()
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
   -- if loading.images_loaed then draw.render_text(3, 2, string.format("fps: %.2f / %.2f", fps, average(fps_data))) end
end

local function draw_debug()
   local menu = require("src.ui.menu")
   if not menu.is_open or menu.allow_update_while_open then
      if debug_settings.show_dump_state_display then show_dump_state_display() end
      if debug_settings.show_debug_frames_display then debug_framedata_display(true) end
      if debug_settings.show_debug_variables_display then debug_variables_display(true) end
      if debug_settings.show_memory_view_display then show_memory_view_display() end
      if debug_settings.show_memory_results_display then show_memory_results_display() end
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

local function debug_things()

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
   add_debug_variable = add_debug_variable,
   log_update = log_update,
   log = log,
   log_draw = log_draw,
   queue_hitbox_draw = queue_hitbox_draw
}

setmetatable(debug, {
   __index = function(_, key)
      if key == "memory_view_start" then
         return memory_view_start
      elseif key == "start_debug" then
         return start_debug
      end
   end,

   __newindex = function(_, key, value)
      if key == "memory_view_start" then
         memory_view_start = value
      elseif key == "start_debug" then
         start_debug = value
      else
         rawset(debug, key, value)
      end
   end
})

return debug
