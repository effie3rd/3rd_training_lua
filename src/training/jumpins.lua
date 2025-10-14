local text = require("src.ui.text")
local fd = require("src.modules.framedata")
local move_data = require("src.modules.move_data")
local gamestate = require("src.gamestate")
local image_tables = require("src.ui.image_tables")
local colors = require("src.ui.colors")
local prediction = require("src.modules.prediction")
local write_memory = require("src.control.write_memory")
local advanced_control = require("src.control.advanced_control")
local stage_data = require("src.modules.stage_data")
local inputs = require("src.control.inputs")
local jumpins_tables = require("src.training.jumpins_tables")
local draw = require("src.ui.draw")
local utils = require("src.modules.utils")
local tools = require("src.tools")
local hud = require("src.ui.hud")
local frame_data, character_specific = fd.frame_data, fd.character_specific
local find_frame_data_by_name = fd.find_frame_data_by_name
local is_slow_jumper, is_really_slow_jumper = fd.is_slow_jumper, fd.is_really_slow_jumper
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text,
                                                                                             text.render_text_multiple,
                                                                                             text.get_text_dimensions,

                                                                                             text.get_text_dimensions_multiple
local Delay = advanced_control.Delay
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete
local move_list = move_data.move_list

local max_jumps = 8
local jumps = {

   -- char:
   -- {
   --    {player pos
   --    dummy reset offset range
   --    reset type
   --    jump
   -- second jump
   -- second jump delay
   --    attack
   --    delay}
   --    followup
   -- }
} -- id
-- jump type
-- jump dir
-- distance
-- point 不動点 定点
-- range (type)　範囲
-- min max
-- button
-- raigeki drill other commands throw
-- timing
-- point 不動点
-- range (type)
-- min max

-- distance from opponent pushbox border
-- draw jump arc
-- indicate hitting and missing sections

-- dummy does test jumps
-- color attack frame dot

local player_reset_range = {838, 838}
local dummy_reset_range = {918, 918}

local jumpins_player = gamestate.P1
local jumpins_dummy = gamestate.P2

local current_jump_arc

local states = {EDIT = 1}

local edit_points = {PLAYER = 1, DUMMY_OFFSET_1 = 2, DUMMY_OFFSET_2 = 3}

local jump_arcs = {}

local dot_cache = {}
local function get_dot(color)
   if not dot_cache[color] then
      local img = image_tables.img_dot
      local gd_color = colors.hex_to_gd_color(color)
      dot_cache[color] = colors.substitute_color_gdstr(img, colors.gd_white, gd_color)
   end
   return dot_cache[color]
end

local up_arrow_cache = {}
local function get_up_arrow(color)
   if not up_arrow_cache[color] then
      local img = image_tables.scroll_up_arrow
      local gd_color = colors.hex_to_gd_color(color)
      up_arrow_cache[color] = colors.substitute_color_gdstr(img, colors.gd_white, gd_color)
   end
   return up_arrow_cache[color]
end

local function update_limits()

end

local function bound_positions()

end

local function move_player_left(selected_player, dist)
end

local function move_left(selected_player, dist)
   local other_player = selected_player.other
   local min_dist = frame_data.get_contact_distance() - 1
   local other_player_right = other_player.pos_x + min_dist
   local other_player_left = other_player.pos_x - min_dist
   local limit_left, _ = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local selected_player_new_x = other_player.pos_x - min_dist
   local other_player_new_x = other_player.pos_x
   if selected_player.pos_x - dist > other_player_left and selected_player.pos_x - dist < other_player_right then
      if selected_player_new_x < limit_left then
         selected_player_new_x = limit_left
         other_player_new_x = selected_player.pos_x + min_dist
      end
   else
      selected_player_new_x = math.max(selected_player_new_x, limit_left)
   end
end

local function move_right(selected_player, dist)
   local other_player = selected_player.other
   local min_dist = frame_data.get_contact_distance() - 1
   local other_player_right = other_player.pos_x + min_dist
   local other_player_left = other_player.pos_x - min_dist
   local _, limit_right = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local selected_player_new_x = other_player.pos_x + min_dist
   local other_player_new_x = other_player.pos_x
   if selected_player.pos_x - dist > other_player_left and selected_player.pos_x - dist < other_player_right then
      if selected_player_new_x < limit_right then
         selected_player_new_x = limit_right
         other_player_new_x = selected_player.pos_x - min_dist
      end
   else
      selected_player_new_x = math.max(selected_player_new_x, limit_right)
   end
end

local function add_jump_arc(jump_arc, player, player_line, player_motion_data)
   for i = 1, #player_motion_data do
      local fdata = fd.find_move_frame_data(player.char_str, player_line[i].animation)
      local frame = player_line[i].frame + 1
      local y_offset
      if fdata and fdata.frames[frame] and fdata.frames[frame].boxes then
         if tools.has_boxes(fdata.frames[frame].boxes, {"push"}) then
            local box_bottom = tools.get_boxes_lowest_position(fdata.frames[frame].boxes, {"push"})
            if box_bottom then y_offset = box_bottom end
         end
      end
      if not y_offset then
         if jump_arc[#jump_arc - 1] then
            y_offset = jump_arc[#jump_arc - 1][3]
         else
            y_offset = 0
         end
      end
      -- print(player_motion_data[i].pos_x, player_motion_data[i].pos_y, y_offset, player_motion_data[i].flip_x) --debug
      table.insert(jump_arc, {player_motion_data[i].pos_x, player_motion_data[i].pos_y, y_offset, y_offset})
   end
end

-- before jumping sim

local max_sim_time = 100
local function simulate_jump(player, start_x, first_jump_name, second_jump_name, second_jump_delay, attack_name,
                             attack_delay)
   local jump_arc = {}
   local dummy = player.other
   start_x = start_x or player.pos_x
   local startup_type = "jump_startup"
   if first_jump_name == "sjump_forward" or first_jump_name == "sjump_neutral" or first_jump_name == "sjump_back" then
      startup_type = "sjump_startup"
   end

   local startup_anim, startup_fdata = find_frame_data_by_name(player.char_str, startup_type)
   local first_jump_anim, first_jump_fdata = find_frame_data_by_name(player.char_str, first_jump_name)
   local second_jump_anim, second_jump_fdata, attack_anim, attack_fdata
   if second_jump_name then
      second_jump_anim, second_jump_fdata = find_frame_data_by_name(player.char_str, second_jump_name)
   end
   if attack_name then attack_anim, attack_fdata = find_frame_data_by_name(player.char_str, attack_name) end
   if startup_fdata and first_jump_fdata then
      local first_jump_sim_time = max_sim_time
      if second_jump_name then
         first_jump_sim_time = second_jump_delay
      elseif attack_name then
         first_jump_sim_time = attack_delay
      end
      local jump_startup_length = #startup_fdata.frames
      local startup_player_motion_data = prediction.init_motion_data_zero(player)
      startup_player_motion_data[0].pos_x = start_x

      local startup_dummy_motion_data = prediction.init_motion_data(dummy)
      local startup_state = prediction.predict_movement_until_landing(player, nil, nil, startup_player_motion_data,
                                                                      player.other, nil, nil, startup_dummy_motion_data,
                                                                      jump_startup_length)
      add_jump_arc(jump_arc, player, startup_state.player_line, startup_state.player_motion_data)
      local first_jump_dummy_anim, first_jump_dummy_frame = startup_state.dummy_line[#startup_state.dummy_line]
                                                                .animation,
                                                            startup_state.dummy_line[#startup_state.dummy_line].frame +
                                                                1
      local first_jump_player_motion_data = {[0] = startup_state.player_motion_data[#startup_state.player_motion_data]}
      local first_jump_dummy_motion_data = {[0] = startup_state.dummy_motion_data[#startup_state.dummy_motion_data]}
      local first_jump_state = prediction.predict_movement_until_landing(player, first_jump_anim, 0,
                                                                         first_jump_player_motion_data, player.other,
                                                                         first_jump_dummy_anim, first_jump_dummy_frame,
                                                                         first_jump_dummy_motion_data,
                                                                         first_jump_sim_time)
      add_jump_arc(jump_arc, player, first_jump_state.player_line, first_jump_state.player_motion_data)

      local last_state = first_jump_state
      if second_jump_name then
         local second_jump_sim_time = max_sim_time
         if second_jump_name == "jump_forward" or second_jump_name == "jump_neutral" or second_jump_name == "jump_back" then
            local second_startup_anim, second_startup_fdata =
                find_frame_data_by_name(player.char_str, "air_jump_startup")
            if second_startup_fdata then second_jump_sim_time = #second_startup_fdata.frames end
            local second_startup_dummy_anim, second_startup_dummy_frame =
                startup_state.dummy_line[#startup_state.dummy_line].animation,
                startup_state.dummy_line[#startup_state.dummy_line].frame + 1
            local second_startup_player_motion_data = {
               [0] = startup_state.player_motion_data[#startup_state.player_motion_data]
            }
            local second_startup_dummy_motion_data = {
               [0] = startup_state.dummy_motion_data[#startup_state.dummy_motion_data]
            }
            local second_startup_state = prediction.predict_movement_until_landing(player, second_startup_anim, 0,
                                                                                   second_startup_player_motion_data,
                                                                                   player.other,
                                                                                   second_startup_dummy_anim,
                                                                                   second_startup_dummy_frame,
                                                                                   second_startup_dummy_motion_data,
                                                                                   second_jump_sim_time)
            add_jump_arc(jump_arc, player, second_startup_state.player_line, second_startup_state.player_motion_data)
            last_state = second_startup_state
         end
         if attack_name then second_jump_sim_time = attack_delay end
         local second_jump_dummy_anim, second_jump_dummy_frame =
             last_state.dummy_line[#last_state.dummy_line].animation,
             last_state.dummy_line[#last_state.dummy_line].frame
         local second_jump_player_motion_data = {
            [0] = last_state.player_motion_data[#last_state.player_motion_data]
         }
         local second_jump_dummy_motion_data = {
            [0] = last_state.dummy_motion_data[#last_state.dummy_motion_data]
         }
         local second_jump_state = prediction.predict_movement_until_landing(player, second_jump_anim, 0,
                                                                             second_jump_player_motion_data,
                                                                             player.other, second_jump_dummy_anim,
                                                                             second_jump_dummy_frame,
                                                                             second_jump_dummy_motion_data,
                                                                             second_jump_sim_time)
         add_jump_arc(jump_arc, player, second_jump_state.player_line, second_jump_state.player_motion_data)
         last_state = second_jump_state
      end
      if attack_name then
         local attack_dummy_anim, attack_dummy_frame = last_state.dummy_line[#last_state.dummy_line].animation,
                                                       last_state.dummy_line[#last_state.dummy_line].frame
         local attack_player_motion_data = {[0] = last_state.player_motion_data[#last_state.player_motion_data]}
         local attack_dummy_motion_data = {[0] = last_state.dummy_motion_data[#last_state.dummy_motion_data]}
         local attack_state = prediction.predict_movement_until_landing(player, attack_anim, 0,
                                                                        attack_player_motion_data, player.other,
                                                                        attack_dummy_anim, attack_dummy_frame,
                                                                        attack_dummy_motion_data, max_sim_time)
         add_jump_arc(jump_arc, player, attack_state.player_line, attack_state.player_motion_data)
      end
   end

   return jump_arc
end

local function draw_player_distances(player)
   local dist = math.floor(math.abs(player.pos_x - player.other.pos_x))
   local px, py = draw.game_to_screen_space(player.pos_x, 0)
   local dx, dy = draw.game_to_screen_space(player.other.pos_x, 0)
   draw.draw_horizontal_text_segment(px, dx, py, dist, colors.gui_text.default, 2, "up", "en")
end

local function draw_jump_arc(jump_arc)
   for i, point in pairs(jump_arc) do
      local x, y = draw.game_to_screen_space(point[1], point[2] + point[3])
      gui.image(x - 1, y - 1, image_tables.img_dot)
   end
--[[    for i = 2, #jump_arc  do
      local x, y = draw.game_to_screen_space(jump_arc[i][1], jump_arc[i][2] + jump_arc[i][3])
      local dx, dy = draw.game_to_screen_space(jump_arc[i-1][1], jump_arc[i-1][2] + jump_arc[i-1][3])
      -- gui.image(x - 1, y - 1, image_tables.img_dot)
      gui.line(x, y, dx, dy, colors.gui_text.default)
   end ]]
end

local function jumpins_display()
   draw_jump_arc(current_jump_arc)
   draw_player_distances(gamestate.P1)
end

local function reset_positions(player, dummy)
   local player_reset_x = math.random(player_reset_range[1], player_reset_range[2])
   local dummy_reset_x = math.random(dummy_reset_range[1], dummy_reset_range[2])
   write_memory.write_pos(player, player_reset_x, 0)
   write_memory.write_pos(dummy, dummy_reset_x, 0)
end

local function execute_jump(player, jump_name, attack_name, delay)
   local jump_input = jumpins_tables.get_jump_inputs(jump_name)
   local attack_input, is_target_combo = jumpins_tables.get_move_inputs(attack_name)
   local attack_delay = Delay:new(delay)
   local command
   if not is_target_combo then
      command = {
         {condition = nil, action = function() queue_input_sequence_and_wait(player, jump_input) end},
         {condition = function() return player.is_in_jump_startup end, action = attack_delay:begin()}, {
            condition = function() return attack_delay:is_complete() end,
            action = function() queue_input_sequence_and_wait(player, attack_input) end
         }
      }
   else
      command = {
         {condition = nil, action = function() queue_input_sequence_and_wait(player, jump_input) end},
         {condition = function() return player.is_in_jump_startup end, action = attack_delay:begin()}, {
            condition = function() return attack_delay:is_complete() end,
            action = function() queue_input_sequence_and_wait(player, attack_input[1]) end
         }, {
            condition = function() return player.has_just_connected end,
            action = function() queue_input_sequence_and_wait(player, attack_input[2]) end
         }
      }
   end
   advanced_control.queue_programmed_movement(player, command)
end

local function debug_jump()
   current_jump_arc = simulate_jump(gamestate.P1, gamestate.P1.pos_x, "jump_forward", nil, nil, nil, nil)
   hud.register_draw(jumpins_display)
end

local timer = Delay:new(2)
local start_delay = 22
local max_delay = 35
local delay = start_delay
local jstate = "start"
local connected = false
local function test_jump()
   -- delay = delay + 1
   -- print("---", delay)
   if jstate == "start" then
      jumpins_player = gamestate.P1
      jumpins_dummy = gamestate.P2
      connected = false
      reset_positions(jumpins_player, jumpins_dummy)
      delay = delay + 1
      jstate = "pos"
   elseif jstate == "pos" then
      if jumpins_player.pos_x ~= player_reset_range[1] or jumpins_player.action ~= 0 then
         reset_positions(jumpins_player, jumpins_dummy)
      elseif jumpins_player.is_idle and jumpins_dummy.is_idle and jumpins_player.action == 0 and jumpins_dummy.action ==
          0 then
         execute_jump(jumpins_player, "jump_forward", "mk", delay)
         jstate = "run"
      end
   elseif jstate == "new_j" then
      player_reset_range[1] = player_reset_range[1] - 1
      player_reset_range[2] = player_reset_range[2] - 1
      delay = start_delay
      jstate = "qstart"
   elseif jstate == "run" then
      inputs.queue_input_sequence(jumpins_dummy, {{"back"}}, 0, true)
      if jumpins_player.has_just_hit or jumpins_player.other.has_just_parried or jumpins_dummy.has_just_been_hit or
          jumpins_dummy.has_just_parried then
         print("============")
         print(">", player_reset_range[1], "delay", delay - 1)
         timer:reset()
         jstate = "qstart"
      elseif jumpins_player.has_just_been_blocked then
         timer:reset()
         jstate = "qstart"
      elseif delay >= max_delay then
         timer:reset()
         jstate = "new_j"
      elseif jumpins_player.has_just_landed then
         timer:reset()
         jstate = "qstart"
      end
   elseif jstate == "qstart" then
      if timer:is_complete() then
         advanced_control.clear_programmed_movement(jumpins_player)
         jstate = "start"
      end
   end
end

return {test_jump = test_jump, debug_jump = debug_jump}
