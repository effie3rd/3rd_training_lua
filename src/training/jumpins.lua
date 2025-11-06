local framedata = require("src.modules.framedata")
local framedata_meta = require("src.modules.framedata_meta")
local gamestate = require("src.gamestate")
local image_tables = require("src.ui.image_tables")
local colors = require("src.ui.colors")
local prediction = require("src.modules.prediction")
local write_memory = require("src.control.write_memory")
local dummy_control = require("src.control.dummy_control")
local advanced_control = require("src.control.advanced_control")
local inputs = require("src.control.inputs")
local jumpins_tables = require("src.training.jumpins_tables")
local draw = require("src.ui.draw")
local utils = require("src.modules.utils")
local tools = require("src.tools")
local hud = require("src.ui.hud")
local training = require("src.training")
local find_frame_data_by_name = framedata.find_frame_data_by_name
local Delay = advanced_control.Delay
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete

local module_name = "jumpins"

local is_active = false

local modes = {EDIT = 1, RUN = 2}
local states = {
   POSITION = 1,
   QUEUE_TEST_JUMP = 2,
   TEST_JUMP = 3,
   WAIT_FOR_START_STATE = 4,
   SELECT_JUMP = 5,
   QUEUE_JUMP = 6,
   JUMP = 7,
   IDLE = 8
}
local replay_modes = {RANDOM = 1, ORDERED = 2}
local range_modes = {FIXED_POINT = 1, RANGE_RANDOM = 2, RANGE_ORDERED = 3, RANGE_ENDPOINTS = 4}
local mode = modes.EDIT
local state = states.POSITION
local autofire_delay = 5
local change_position_start_frame = 0
local move_speed = 1
local max_move_speed = 3
local move_speed_increase_delay = 20
local contact_dist = 0
local test_jump_start_delay = 30
local new_jump_start_delay = 30
local reset_position_margin = 5
local screen_reset_pos_x = 0
local screen_scroll_speed = 8
local moved_left_last_frame = false
local moved_right_last_frame = false
local move_left_frame = 0
local move_right_frame = 0

local player_position_range = {0, 0}
local dummy_offset_range = {0, 0}
local attack_delay_range = {0, 0}
local second_jump_delay_range = {0, 0}
local player_position_bounds = {0, 0}
local dummy_offset_bounds = {0, 0}
local attack_delay_bounds = {0, 0}
local second_jump_delay_bounds = {0, 0}

local dummy_offset_edit_mode = 1
local dummy_offset_edit_index = 1
local dummy_offset_edit_max_points = 2

local attack_delay_edit_mode = 1
local attack_delay_edit_index = 1
local attack_delay_edit_max_points = 2

local player_pose = 1

local jumpins_player = gamestate.P1
local jumpins_dummy = gamestate.P2

local current_jump_arc
local jump_queued_frame = 0

local jumpins_settings = {}
local current_jump_settings = {}
local jumps = {}
local jump_index = 1
local current_jump

local info_labels = {}

local function init()
   if not is_active then
      jumpins_player = training.player
      jumpins_dummy = training.dummy
      jumpins_tables.init(training.dummy.char_str)
      contact_dist = framedata.get_contact_distance(jumpins_player) - 1
   end
end

local function draw_player_distances(player)
   local dist = math.floor(math.abs(dummy_offset_range[dummy_offset_edit_index]))
   local px, py = draw.game_to_screen_space(player_position_range[1], 0)
   local dx, dy = draw.game_to_screen_space(player_position_range[1] + dummy_offset_range[dummy_offset_edit_index], 0)
   draw.draw_horizontal_text_segment(px, dx, py, dist, colors.gui_text.default, 2, "up", "en")
end

local function draw_jump_arc(jump_arc)
   if not jump_arc then return end
   local function get_color(index)
      local color = colors.text.default
      if mode == modes.EDIT then
         if attack_delay_edit_mode == 1 then
            if index == attack_delay_range[1] then color = colors.text.selected end
         elseif attack_delay_edit_mode == 2 then
            if index >= attack_delay_range[1] and index <= attack_delay_range[2] then
               color = colors.text.selected
            end
         end
      elseif mode == modes.RUN then

      end
      return color
   end
   local current_point = gamestate.frame_number - jump_queued_frame + 1
   local selected_points = {}
   for i, point in pairs(jump_arc) do
      local color = get_color(i)
      if color == colors.text.selected and not (i == current_point) then
         table.insert(selected_points, point)
      else
         local x, y = draw.game_to_screen_space(point[1], point[2] + point[3])
         if not (i == current_point) then gui.image(x - 1, y - 1, draw.get_image(image_tables.img_dot, color)) end
      end
   end
   for i, point in pairs(selected_points) do
      local x, y = draw.game_to_screen_space(point[1], point[2] + point[3])
      gui.image(x - 1, y - 1, draw.get_image(image_tables.img_dot, colors.text.selected))
   end
   local color = get_color(current_point)
   local point = jump_arc[current_point]
   if point then
      local x, y = draw.game_to_screen_space(point[1], point[2] + point[3])
      gui.image(x - 1, y - 1, draw.get_image(image_tables.scroll_up_arrow, color))
   end
end

local function jumpins_display()
   if jumpins_settings.show_jump_arc then draw_jump_arc(current_jump_arc) end
   if mode == modes.EDIT then draw_player_distances(jumpins_dummy) end
   if jumpins_settings.show_jump_info then hud.add_info_text(info_labels, jumpins_dummy.id) end
end

local function change_dummy_offset_edit_mode()
   dummy_offset_edit_mode = dummy_offset_edit_mode % 2 + 1
   if dummy_offset_edit_mode == 1 then dummy_offset_edit_index = 1 end
   current_jump_settings.dummy_offset_mode = dummy_offset_edit_mode
   return dummy_offset_edit_mode
end

local function change_dummy_offset_edit_index()
   dummy_offset_edit_index = dummy_offset_edit_index % dummy_offset_edit_max_points + 1
   return dummy_offset_edit_index
end

local function change_attack_delay_edit_mode()
   attack_delay_edit_mode = attack_delay_edit_mode % 2 + 1
   if attack_delay_edit_index == 1 then attack_delay_edit_index = 1 end
   current_jump_settings.attack_delay_mode = attack_delay_edit_mode
   return attack_delay_edit_mode
end

local function change_attack_delay_edit_index()
   attack_delay_edit_index = attack_delay_edit_index % attack_delay_edit_max_points + 1
   return attack_delay_edit_index
end

local function get_current_player_position() return player_position_range[1] end

local function get_current_dummy_offset()
   if dummy_offset_edit_mode == 1 then
      return dummy_offset_range[1]
   elseif dummy_offset_edit_mode == 2 then
      return dummy_offset_range[dummy_offset_edit_index]
   end
end

local function get_current_dummy_position() return get_current_player_position() + get_current_dummy_offset() end

local function get_current_attack_delay()
   if attack_delay_edit_mode == 1 then
      return attack_delay_range[1]
   elseif attack_delay_edit_mode == 2 then
      return attack_delay_range[attack_delay_edit_index]
   end
end

local function add_jump_arc(jump_arc, player, player_line, player_motion_data)
   for i = 1, #player_motion_data do
      local fdata = framedata.find_move_frame_data(player.char_str, player_line[i].animation)
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
      table.insert(jump_arc, {player_motion_data[i].pos_x, player_motion_data[i].pos_y, y_offset, y_offset})
   end
end

local function is_sjump(jump_name)
   return tools.table_contains({"sjump_forward", "sjump_neutral", "sjump_back"}, jump_name)
end

local function get_jump_startup(char_str, jump_name)
   local startup_type = "jump_startup"
   if jump_name == "sjump_forward" or jump_name == "sjump_neutral" or jump_name == "sjump_back" then
      startup_type = "sjump_startup"
   end
   return find_frame_data_by_name(char_str, startup_type)
end

local function get_frames_until_jump(fdata)
   if fdata and fdata.frames then
      local i = 1
      while i <= #fdata.frames do
         if fdata.frames[i].next_anim then return i end
         i = i + 1
      end
      return i
   end
   return nil
end

local max_sim_time = 100
local function simulate_jump(player, start_x, first_jump_name, second_jump_name, second_jump_delay, attack_name,
                             attack_delay)
   if first_jump_name == "off" then return {} end
   local jump_arc = {}
   local dummy = player.other
   start_x = start_x or player.pos_x

   local startup_anim, startup_fdata = get_jump_startup(player.char_str, first_jump_name)
   local first_jump_anim, first_jump_fdata = find_frame_data_by_name(player.char_str, first_jump_name)
   local second_jump_anim, second_jump_fdata, attack_anim, attack_fdata
   if second_jump_name then
      second_jump_anim, second_jump_fdata = find_frame_data_by_name(player.char_str, second_jump_name)
   end
   local attack_input, is_target_combo
   if attack_name then
      attack_anim, attack_fdata = find_frame_data_by_name(player.char_str, attack_name)
      attack_input, is_target_combo = jumpins_tables.get_move_inputs(attack_name)
   end
   if startup_fdata and first_jump_fdata then
      local input_sim_time = 1
      if is_sjump(first_jump_name) then input_sim_time = 2 end
      local input_player_motion_data = prediction.init_motion_data_zero(player)
      input_player_motion_data[0].pos_x = start_x

      local input_dummy_motion_data = prediction.init_motion_data(dummy)
      local input_state = prediction.predict_jump_arc(player, nil, nil, input_player_motion_data, player.other, nil,
                                                      nil, input_dummy_motion_data, input_sim_time)
      add_jump_arc(jump_arc, player, input_state.player_line, input_state.player_motion_data)

      local first_jump_sim_time = max_sim_time
      if second_jump_name then
         first_jump_sim_time = second_jump_delay - 1
      elseif attack_name then
         first_jump_sim_time = attack_delay - #attack_input - #startup_fdata.frames
      end
      local jump_startup_length = #startup_fdata.frames
      local startup_player_motion_data = prediction.init_motion_data_zero(player)
      startup_player_motion_data[0].pos_x = start_x

      local startup_dummy_motion_data = prediction.init_motion_data(dummy)
      local startup_state = prediction.predict_jump_arc(player, startup_anim, 0, startup_player_motion_data,
                                                        player.other, nil, nil, startup_dummy_motion_data,
                                                        jump_startup_length)
      add_jump_arc(jump_arc, player, startup_state.player_line, startup_state.player_motion_data)
      local first_jump_dummy_anim, first_jump_dummy_frame = startup_state.dummy_line[#startup_state.dummy_line]
                                                                .animation,
                                                            startup_state.dummy_line[#startup_state.dummy_line].frame +
                                                                1
      local first_jump_player_motion_data = {[0] = startup_state.player_motion_data[#startup_state.player_motion_data]}
      local first_jump_dummy_motion_data = {[0] = startup_state.dummy_motion_data[#startup_state.dummy_motion_data]}
      local first_jump_state = prediction.predict_jump_arc(player, first_jump_anim, 0, first_jump_player_motion_data,
                                                           player.other, first_jump_dummy_anim, first_jump_dummy_frame,
                                                           first_jump_dummy_motion_data, first_jump_sim_time)
      add_jump_arc(jump_arc, player, first_jump_state.player_line, first_jump_state.player_motion_data)

      local last_state = first_jump_state
      if second_jump_name then
         local second_jump_sim_time = max_sim_time
         local second_jump_startup_time = 0
         if second_jump_name == "jump_forward" or second_jump_name == "jump_neutral" or second_jump_name == "jump_back" then
            local second_startup_anim, second_startup_fdata =
                find_frame_data_by_name(player.char_str, "air_jump_startup")
            if second_startup_fdata then
               second_jump_sim_time = #second_startup_fdata.frames
               second_jump_startup_time = #second_startup_fdata.frames
            end
            local second_startup_dummy_anim, second_startup_dummy_frame =
                startup_state.dummy_line[#startup_state.dummy_line].animation,
                startup_state.dummy_line[#startup_state.dummy_line].frame + 1
            local second_startup_player_motion_data = {
               [0] = startup_state.player_motion_data[#startup_state.player_motion_data]
            }
            local second_startup_dummy_motion_data = {
               [0] = startup_state.dummy_motion_data[#startup_state.dummy_motion_data]
            }
            local second_startup_state = prediction.predict_jump_arc(player, second_startup_anim, 0,
                                                                     second_startup_player_motion_data, player.other,
                                                                     second_startup_dummy_anim,
                                                                     second_startup_dummy_frame,
                                                                     second_startup_dummy_motion_data,
                                                                     second_jump_sim_time)
            add_jump_arc(jump_arc, player, second_startup_state.player_line, second_startup_state.player_motion_data)
            last_state = second_startup_state
         end
         if attack_name then second_jump_sim_time = attack_delay - #attack_input - second_jump_startup_time end
         local second_jump_dummy_anim, second_jump_dummy_frame =
             last_state.dummy_line[#last_state.dummy_line].animation,
             last_state.dummy_line[#last_state.dummy_line].frame
         local second_jump_player_motion_data = {[0] = last_state.player_motion_data[#last_state.player_motion_data]}
         local second_jump_dummy_motion_data = {[0] = last_state.dummy_motion_data[#last_state.dummy_motion_data]}
         local second_jump_state = prediction.predict_jump_arc(player, second_jump_anim, 0,
                                                               second_jump_player_motion_data, player.other,
                                                               second_jump_dummy_anim, second_jump_dummy_frame,
                                                               second_jump_dummy_motion_data, second_jump_sim_time)
         add_jump_arc(jump_arc, player, second_jump_state.player_line, second_jump_state.player_motion_data)
         last_state = second_jump_state
      end
      if attack_name then
         local attack_dummy_anim, attack_dummy_frame = last_state.dummy_line[#last_state.dummy_line].animation,
                                                       last_state.dummy_line[#last_state.dummy_line].frame
         local attack_player_motion_data = {[0] = last_state.player_motion_data[#last_state.player_motion_data]}

         local attack_dummy_motion_data = {[0] = last_state.dummy_motion_data[#last_state.dummy_motion_data]}
         local attack_state = prediction.predict_jump_arc(player, attack_anim, 0, attack_player_motion_data,
                                                          player.other, attack_dummy_anim, attack_dummy_frame,
                                                          attack_dummy_motion_data, max_sim_time)
         add_jump_arc(jump_arc, player, attack_state.player_line, attack_state.player_motion_data)
      end
   end

   return jump_arc
end

local function get_center_screen_position(player, player_pos_x, other_pos_x)
   local left_player = player.pos_x - player.other.pos_x < 0 and player or player.other
   local right_player = left_player.other

   local screen_pos_x = (player_pos_x + other_pos_x +
                            framedata.character_specific[right_player.char_str].corner_offset_right -
                            framedata.character_specific[left_player.char_str].corner_offset_left + 1) / 2
   local screen_limit_left, screen_limit_right = utils.get_stage_screen_limits(gamestate.stage)
   return tools.clamp(screen_pos_x, screen_limit_left, screen_limit_right)
end

local function get_valid_offset_range(player, other_player_x, offset_min, offset_max)
   local player_stage_left, player_stage_right = utils.get_stage_limits(gamestate.stage, player.char_str)
   local player_position_left = math.max(other_player_x + offset_min, player_stage_left)
   local player_position_right = math.min(other_player_x + offset_max, player_stage_right)
   local other_player_left = math.max(other_player_x - contact_dist, player_stage_left)
   local other_player_right = math.min(other_player_x + contact_dist, player_stage_right)
   local result = {}
   if other_player_right <= player_position_left or other_player_left >= player_position_right then
      table.insert(result, {player_position_left, player_position_right})
      return result
   end
   if other_player_left >= player_position_left then table.insert(result, {player_position_left, other_player_left}) end
   if other_player_right <= player_position_right then
      table.insert(result, {other_player_right, player_position_right})
   end
   return result
end

local function update_position_bounds()
   player_position_bounds[1], player_position_bounds[2] = utils.get_stage_limits(gamestate.stage,
                                                                                 jumpins_player.char_str)
   local max_offset_left = draw.SCREEN_WIDTH - framedata.character_specific[jumpins_dummy.char_str].corner_offset_left -
                               framedata.character_specific[jumpins_player.char_str].corner_offset_right
   local max_offset_right =
       draw.SCREEN_WIDTH - framedata.character_specific[jumpins_dummy.char_str].corner_offset_right -
           framedata.character_specific[jumpins_player.char_str].corner_offset_left

   local dummy_stage_left, dummy_stage_right = utils.get_stage_limits(gamestate.stage, jumpins_dummy.char_str)

   dummy_offset_bounds[1] = math.floor(math.max(-max_offset_left, dummy_stage_left - player_position_range[1]))
   dummy_offset_bounds[2] = math.floor(math.min(max_offset_right, dummy_stage_right - player_position_range[1]))
end

local function update_delay_bounds()
   local jump_name = jumpins_tables.get_jump_names()[current_jump_settings.jump_name]
   local second_jump_name = jumpins_tables.get_second_jump_names()[current_jump_settings.second_jump_name]
   local second_jump_delay = current_jump_settings.second_jump_delay[1]
   -- maybe sim both jumps
   local jump_arc = simulate_jump(jumpins_dummy, dummy_offset_range[1], jump_name, second_jump_name, second_jump_delay,
                                  nil, nil)
   local startup_anim, startup_fdata = get_jump_startup(jumpins_dummy.char_str, jump_name)
   local min_delay = get_frames_until_jump(startup_fdata) or 4
   min_delay = min_delay + 2
   if is_sjump(jump_name) then min_delay = min_delay + 1 end

   if current_jump_settings.second_jump_name ~= 1 then
      second_jump_delay_bounds[2] = #jump_arc

      if tools.table_contains({"jump_forward", "jump_neutral", "jump_back"}, second_jump_name) then
         if is_sjump(jump_name) then
            second_jump_delay_bounds[1] = 13
         else
            second_jump_delay_bounds[1] = 12
         end
         attack_delay_bounds[1] = 10
      elseif tools.table_contains({"air_dash_forward", "air_dash_back"}, second_jump_name) then
         second_jump_delay_bounds[1] = min_delay + 5
         attack_delay_bounds[1] = 10
      end
      attack_delay_bounds[2] = #jump_arc
   else
      attack_delay_bounds[1] = min_delay
      attack_delay_bounds[2] = #jump_arc
   end
end

local function bound_settings()
   player_position_range[1] =
       tools.clamp(player_position_range[1], player_position_bounds[1], player_position_bounds[2])
   player_position_range[2] =
       tools.clamp(player_position_range[1], player_position_bounds[1], player_position_bounds[2])
   dummy_offset_range[1] = tools.clamp(dummy_offset_range[1], dummy_offset_bounds[1], dummy_offset_bounds[2])
   dummy_offset_range[2] = tools.clamp(dummy_offset_range[2], dummy_offset_bounds[1], dummy_offset_bounds[2])
   attack_delay_range[1] = tools.clamp(attack_delay_range[1], attack_delay_bounds[1], attack_delay_bounds[2])
   attack_delay_range[2] = tools.clamp(attack_delay_range[2], attack_delay_bounds[1], attack_delay_bounds[2])
   second_jump_delay_range[1] = tools.clamp(second_jump_delay_range[1], second_jump_delay_bounds[1],
                                            second_jump_delay_bounds[2])
   second_jump_delay_range[2] = tools.clamp(second_jump_delay_range[2], second_jump_delay_bounds[1],
                                            second_jump_delay_bounds[2])
end

local function update_selected_jump()
   if current_jump_settings.jump_name ~= 1 then
      update_delay_bounds()
      bound_settings()
   end
end

local function move_left(selected_player, selected_player_x, other_player_x, dist)
   move_left_frame = gamestate.frame_number
   local switched_sides = false
   local other_player_right = other_player_x + contact_dist
   local other_player_left = other_player_x - contact_dist
   local stage_left, _ = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local selected_player_new_x = math.floor(selected_player_x - dist)
   if selected_player_new_x > other_player_left and selected_player_new_x < other_player_right then
      if math.floor(selected_player_x) == other_player_right then
         selected_player_new_x = other_player_left
         switched_sides = true
      else
         selected_player_new_x = other_player_right
      end
   else
      selected_player_new_x = math.max(selected_player_new_x, stage_left)
   end
   return selected_player_new_x, switched_sides
end

local function move_right(selected_player, selected_player_x, other_player_x, dist)
   move_right_frame = gamestate.frame_number
   local switched_sides = false
   local other_player_right = other_player_x + contact_dist
   local other_player_left = other_player_x - contact_dist
   local _, stage_right = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local selected_player_new_x = math.floor(selected_player_x + dist)
   if selected_player_new_x > other_player_left and selected_player_new_x < other_player_right then
      if math.floor(selected_player_x) == other_player_left then
         selected_player_new_x = other_player_right
         switched_sides = true
      else
         selected_player_new_x = other_player_left
      end
   else
      selected_player_new_x = math.min(selected_player_new_x, stage_right)
   end
   return selected_player_new_x, switched_sides
end

local function move_player_left()
   local dist = move_speed
   moved_left_last_frame = gamestate.frame_number - move_left_frame == 1
   if not moved_left_last_frame then change_position_start_frame = gamestate.frame_number end
   if moved_left_last_frame and gamestate.frame_number - change_position_start_frame > autofire_delay then
      dist = move_speed +
                 math.ceil(
                     (gamestate.frame_number - change_position_start_frame - autofire_delay) / move_speed_increase_delay)
      dist = math.min(dist, max_move_speed)
   end
   local new_x, switched_sides = move_left(jumpins_player, get_current_player_position(), get_current_dummy_position(),
                                           dist)
   player_position_range[1] = new_x
   player_position_range[2] = new_x
   if switched_sides then
      dummy_offset_range[1] = -dummy_offset_range[1]
      dummy_offset_range[2] = -dummy_offset_range[2]
   end
   update_position_bounds()
   bound_settings()
   current_jump_arc = nil
end

local function move_player_right()
   local dist = move_speed
   moved_right_last_frame = gamestate.frame_number - move_right_frame == 1
   if not moved_right_last_frame then change_position_start_frame = gamestate.frame_number end
   if moved_right_last_frame and gamestate.frame_number - change_position_start_frame > autofire_delay then
      dist = move_speed +
                 math.ceil(
                     (gamestate.frame_number - change_position_start_frame - autofire_delay) / move_speed_increase_delay)
      dist = math.min(dist, max_move_speed)
   end
   local new_x, switched_sides = move_right(jumpins_player, get_current_player_position(), get_current_dummy_position(),
                                            dist)
   player_position_range[1] = new_x
   player_position_range[2] = new_x
   if switched_sides then
      dummy_offset_range[1] = -dummy_offset_range[1]
      dummy_offset_range[2] = -dummy_offset_range[2]
   end
   update_position_bounds()
   bound_settings()
   current_jump_arc = nil
end

local function move_dummy_left()
   local dist = move_speed
   moved_left_last_frame = gamestate.frame_number - move_left_frame == 1
   if not moved_left_last_frame then change_position_start_frame = gamestate.frame_number end
   if moved_left_last_frame and gamestate.frame_number - change_position_start_frame > autofire_delay then
      dist = move_speed +
                 math.ceil(
                     (gamestate.frame_number - change_position_start_frame - autofire_delay) / move_speed_increase_delay)
      dist = math.min(dist, max_move_speed)
   end
   local new_x = move_left(jumpins_dummy, get_current_dummy_position(), get_current_player_position(), dist)
   if dummy_offset_edit_mode == 2 then
      update_position_bounds()
      while new_x >= dummy_offset_bounds[1] do
         if not tools.table_contains(dummy_offset_range, new_x) then break end
         new_x = move_left(jumpins_dummy, new_x, get_current_player_position(), dist)
      end
   end
   local new_offset = new_x - get_current_player_position()
   dummy_offset_range[dummy_offset_edit_index] = new_offset
   if dummy_offset_edit_mode == 2 then
      table.sort(dummy_offset_range)
      dummy_offset_edit_index = tools.table_indexof(dummy_offset_range, new_offset) or 1
   end
   local dummy_right = get_current_dummy_position() + contact_dist
   local dummy_left = get_current_dummy_position() - contact_dist
   if player_position_range[1] > dummy_left and player_position_range[1] < dummy_right then
      player_position_range[1] = dummy_right
      player_position_range[2] = dummy_right
   end
   update_position_bounds()
   bound_settings()
   current_jump_arc = nil
end

local function move_dummy_right()
   local dist = move_speed
   moved_right_last_frame = gamestate.frame_number - move_right_frame == 1
   if not moved_right_last_frame then change_position_start_frame = gamestate.frame_number end
   if moved_right_last_frame and gamestate.frame_number - change_position_start_frame > autofire_delay then
      dist = move_speed +
                 math.ceil(
                     (gamestate.frame_number - change_position_start_frame - autofire_delay) / move_speed_increase_delay)
      dist = math.min(dist, max_move_speed)
   end
   local new_x = move_right(jumpins_dummy, get_current_dummy_position(), get_current_player_position(), dist)
   if dummy_offset_edit_mode == 2 then
      update_position_bounds()
      while new_x <= dummy_offset_bounds[2] do
         if not tools.table_contains(dummy_offset_range, new_x) then break end
         new_x = move_right(jumpins_dummy, new_x, get_current_player_position(), dist)
      end
   end
   local new_offset = new_x - get_current_player_position()
   dummy_offset_range[dummy_offset_edit_index] = new_offset
   if dummy_offset_edit_mode == 2 then
      table.sort(dummy_offset_range)
      dummy_offset_edit_index = tools.table_indexof(dummy_offset_range, new_offset) or 1
   end
   local dummy_right = get_current_dummy_position() + contact_dist
   local dummy_left = get_current_dummy_position() - contact_dist
   if player_position_range[1] > dummy_left and player_position_range[1] < dummy_right then
      player_position_range[1] = dummy_left
      player_position_range[2] = dummy_left
   end
   update_position_bounds()
   bound_settings()
   current_jump_arc = nil
end

local function reset_positions(player, dummy)
   local player_reset_x = math.random(player_position_range[1], player_position_range[2])
   local dummy_reset_x = math.random(dummy_offset_range[1], dummy_offset_range[2])
   write_memory.write_pos(player, player_reset_x, 0)
   write_memory.write_pos(dummy, dummy_reset_x, 0)
end

local function execute_jump(player, first_jump_name, second_jump_name, second_jump_delay, attack_name, attack_delay,
                            followup, followup_delay)
   local first_jump_input = jumpins_tables.get_jump_inputs(first_jump_name)
   local second_jump_input, second_jump_timer
   local should_second_jump = false
   local attack_input, is_target_combo = jumpins_tables.get_move_inputs(attack_name)
   local attack_timer = Delay:new(attack_delay - #attack_input)
   local second_jump_input_length = 1
   local should_display_info = jumpins_settings.show_jump_info
   info_labels = {}
   local delay_timer = gamestate.frame_number

   if second_jump_name and second_jump_name ~= "none" then
      should_second_jump = true
      second_jump_input = jumpins_tables.get_jump_inputs(second_jump_name)
      if second_jump_name == "air_dash_forward" or second_jump_name == "air_dash_back" then
         second_jump_input_length = 3
         attack_timer:reset(attack_delay - #attack_input + 2)
      end
      second_jump_timer = Delay:new(second_jump_delay - second_jump_input_length)
   end

   local command = {
      {
         condition = nil,
         action = function()
            queue_input_sequence_and_wait(player, first_jump_input)
            if should_second_jump then
               second_jump_timer:begin()
            else
               attack_timer:begin()
            end
            if should_display_info then
               table.insert(info_labels, "menu_" .. first_jump_name)
               delay_timer = gamestate.frame_number
            end
         end
      }
   }
   if should_second_jump then
      local second_jump = {
         condition = function() return second_jump_timer:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, second_jump_input)
            attack_timer:begin()
            if should_display_info then
               local elapsed = gamestate.frame_number - delay_timer + second_jump_input_length
               table.insert(info_labels, {"menu_" .. second_jump_name, " ", elapsed, "hud_f", " ", "hud_after"})
               delay_timer = gamestate.frame_number
            end
         end
      }

      table.insert(command, second_jump)
   end
   if is_target_combo then
      local input_delay = Delay:new(2)
      local target_combo = {
         {
            condition = function() return attack_timer:is_complete() end,
            action = function()
               queue_input_sequence_and_wait(player, {attack_input[1]})
               if should_display_info then
                  local elapsed = gamestate.frame_number - delay_timer + 1
                  table.insert(info_labels, {"menu_" .. attack_name, " ", elapsed, "hud_f", " ", "hud_after"})
                  delay_timer = gamestate.frame_number
               end

            end
         }, {
            condition = function()
               if player.has_just_connected then
                  return true
               elseif player.has_just_landed then
                  advanced_control.clear_programmed_movement(player)
               end
            end,
            action = nil
         }, {
            condition = function() return input_delay:is_complete() end,
            action = function() queue_input_sequence_and_wait(player, {attack_input[2]}) end
         }
      }
      table.insert(command, target_combo[1])
      table.insert(command, target_combo[2])
      table.insert(command, target_combo[3])
   else
      local attack = {
         {
            condition = function() return attack_timer:is_complete() end,
            action = function()
               queue_input_sequence_and_wait(player, attack_input, 0, true)
               if should_display_info then
                  local elapsed = gamestate.frame_number - delay_timer + #attack_input
                  table.insert(info_labels, {"menu_" .. attack_name, " ", elapsed, "hud_f", " ", "hud_after"})
                  delay_timer = gamestate.frame_number
               end
            end
         }, {condition = function() return player.has_just_connected or player.has_just_landed end, action = nil}
      }
      table.insert(command, attack[1])
      table.insert(command, attack[2])
   end
   if followup then
      local followup_input
      local followup_data = utils.create_move_data_from_selection(followup, jumpins_dummy)
      local followup_name = followup_data.name
      if followup.type ~= 5 then
         followup_input = inputs.create_input_sequence(followup_data)
      else
         followup_input = require("src.control.recording").get_recordings(jumpins_dummy.char_str)[1].inputs
      end
      local followup_adjustment = 0
      local is_throw = false
      local is_option_select = false
      local throw_hit_frame = 3
      
      if followup.type == 2 then
         if followup_data.button == "LP+LK" or followup.motion == 15 then
            is_throw = true
            if followup.motion == 15 then followup_adjustment = -#followup_input + 1 end
         end
      elseif followup.type == 3 then
         local move_name = followup_data.name
         if tools.table_contains(require("src.modules.move_data").kara_command_throws, followup_data.name) then
            local base_name = {
               kara_power_bomb = "power_bomb",
               kara_karakusa_lk = "karakusa",
               kara_karakusa_hk = "karakusa",
               kara_capture_and_deadly_blow = "capture_and_deadly_blow",
               kara_zenpou_yang = "zenpou",
               kara_zenpou_yun = "zenpou"
            }
            move_name = base_name[followup_data.name]
            is_throw = true
            followup_adjustment = -#followup_input + 1
            if followup_data.name == "kara_capture_and_deadly_blow" then followup_adjustment = -2 end
         else
            local anim, fdata = find_frame_data_by_name(jumpins_dummy.char_str, move_name, followup_data.button)
            if anim and framedata_meta.frame_data_meta[jumpins_dummy.char_str][anim] then
               is_throw = framedata_meta.frame_data_meta[jumpins_dummy.char_str][anim].throw
            end
         end
         if is_throw then
            throw_hit_frame = framedata.get_first_hit_frame_by_name(jumpins_dummy.char_str, move_name,
                                                                    followup_data.button) + 1
            if followup_data.name == "gigas_breaker" then throw_hit_frame = throw_hit_frame - 1 end
            if followup_data.name == "sgs" then is_throw = false end
         end
      elseif followup.type == 4 then
         is_option_select = true
      end

      local followup_command = {
         condition = function()
            return advanced_control.is_landing_timing(player, #followup_input - followup_delay, true) and
                       advanced_control.is_idle_timing(player, #followup_input - followup_delay + followup_adjustment,
                                                       true) and (not is_throw or
                       advanced_control.is_throw_vulnerable_timing(player.other,
                                                                   #followup_input + throw_hit_frame - followup_delay,
                                                                   true)) and
                       (not is_option_select or advanced_control.is_idle_timing(player.other, 1 - followup_delay, true))
         end,
         action = function() queue_input_sequence_and_wait(player, followup_input)
            if should_display_info then
               local elapsed = gamestate.frame_number - delay_timer
               local label_text = {followup_name, " ", elapsed, "hud_f", " ", "hud_after"}
               if followup.type == 2 and followup_data.button ~= "none" then
                  table.insert(label_text, 2, followup_data.button)
                  if require("src.settings").language == "en" then
                     table.insert(label_text, 2, " ")
                  end
               end
               table.insert(info_labels, label_text)
               delay_timer = gamestate.frame_number
            end
          end
      }
      table.insert(command, followup_command)
   end

   advanced_control.queue_programmed_movement(player, command)
end

local function load_settings(settings) jumpins_settings = settings.characters[jumpins_dummy.char_str] end

local function load_jump(jump_settings)
   current_jump_settings = jump_settings
   player_position_range = jump_settings.player_position
   dummy_offset_range = jump_settings.dummy_offset
   attack_delay_range = jump_settings.attack_delay
   second_jump_delay_range = jump_settings.second_jump_delay
   dummy_offset_edit_mode = jump_settings.dummy_offset_mode
   attack_delay_edit_mode = jump_settings.attack_delay_mode
   dummy_offset_edit_index = 1
   attack_delay_edit_index = 1
   update_position_bounds()
   update_delay_bounds()
   bound_settings()
end

local function load_all_jumps(settings, dummy)
   jumpins_settings = settings.characters[dummy.char_str]
   if not jumpins_settings then jumpins_settings = jumpins_tables.create_settings(dummy) end
   jumps = {}
   for _, jump in ipairs(jumpins_settings.jumps) do
      if jump.jump_name ~= 1 then
         load_jump(jump)
         local j = tools.deepcopy(jump)
         j.playback = {}
         table.insert(jumps, j)
      end
   end
end

local function try_jump()
   mode = modes.RUN
   state = states.IDLE
   if gamestate.is_ground_state(jumpins_player, jumpins_player.standing_state) and
       gamestate.is_ground_state(jumpins_dummy, jumpins_dummy.standing_state) and jumpins_dummy.character_state_byte ==
       0 then state = states.SELECT_JUMP end
end

local function queue_jump(jump, dummy_offset, attack_delay)
   local first_jump_name = jumpins_tables.get_jump_names()[jump.jump_name]
   if first_jump_name ~= "off" then
      inputs.clear_input_sequence(jumpins_player)
      inputs.clear_input_sequence(jumpins_dummy)
      local second_jump_name = jumpins_tables.get_second_jump_names()[jump.second_jump_name]
      local second_jump_delay = jump.second_jump_delay[1]
      local attack_name = jumpins_tables.get_attack_names()[jump.attack_name]
      local followup = jump.followup
      local followup_delay = jump.followup_delay
      execute_jump(jumpins_dummy, first_jump_name, second_jump_name, second_jump_delay, attack_name, attack_delay,
                   followup, followup_delay)
      if jumpins_settings.show_jump_arc then
         current_jump_arc = simulate_jump(jumpins_dummy, dummy_offset, first_jump_name, second_jump_name,
                                          second_jump_delay, attack_name, attack_delay)
      end
      jump_queued_frame = gamestate.frame_number
   end
end

local function begin_edit(settings, jump_settings)
   if not is_active then
      init()
      training.toggle_swap_characters()
   end
   is_active = true
   load_settings(settings)
   load_jump(jump_settings)
   inputs.block_input(1, "all")
   inputs.block_input(2, "all")
   dummy_control.disable_update("pose", true)
   mode = modes.EDIT
   state = states.POSITION
   move_left_frame, move_right_frame = 0, 0
   advanced_control.clear_all()
   info_labels = {}
   hud.register_draw(jumpins_display)
end

local function end_edit()
   is_active = false
   training.toggle_swap_characters()
   inputs.unblock_input(1)
   inputs.unblock_input(2)
   dummy_control.disable_update("pose", false)
   advanced_control.clear_all()
   hud.unregister_draw(jumpins_display)
   hud.clear_info_text()
end

local function start(settings)
   if not is_active then init() end
   is_active = true
   inputs.unblock_input(1)
   inputs.unblock_input(2)
   load_settings(settings)
   load_all_jumps(settings, jumpins_dummy)
   mode = modes.RUN
   if jumpins_settings.automatic_replay then
      state = states.WAIT_FOR_START_STATE
   else
      state = states.IDLE
   end
   training.disable_dummy[jumpins_dummy.id] = false
   advanced_control.clear_all()
   info_labels = {}
   hud.register_draw(jumpins_display)
end

local function stop()
   if is_active then
      is_active = false
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      training.disable_dummy[1] = false
      training.disable_dummy[2] = false
      advanced_control.clear_all()
      hud.unregister_draw(jumpins_display)
      hud.clear_info_text()
   end
end

local function reset() end

local function update()
   if is_active then
      if mode == modes.EDIT then
         player_pose = require("src.settings").training.pose
         if state == states.POSITION then
            local player_pos_x = get_current_player_position()
            local dummy_pos_x = get_current_dummy_position()
            if gamestate.frame_number - move_right_frame >= test_jump_start_delay and gamestate.frame_number -
                move_left_frame >= test_jump_start_delay and
                jumpins_tables.get_jump_names()[current_jump_settings.jump_name] ~= "off" then
               if (jumpins_player.action == 0 or (player_pose == 2 and jumpins_player.action == 7)) and
                   jumpins_dummy.action == 0 and math.floor(jumpins_player.pos_x) == player_pos_x and
                   math.floor(jumpins_dummy.pos_x) == dummy_pos_x then state = states.QUEUE_TEST_JUMP end
            end
            screen_reset_pos_x = get_center_screen_position(jumpins_player, player_pos_x, dummy_pos_x)
            if screen_reset_pos_x < gamestate.screen_x then
               write_memory.set_screen_pos(math.max(screen_reset_pos_x, gamestate.screen_x - screen_scroll_speed), 0)
            elseif screen_reset_pos_x > gamestate.screen_x then
               write_memory.set_screen_pos(math.min(gamestate.screen_x + screen_scroll_speed, screen_reset_pos_x), 0)
            end
            write_memory.write_pos(jumpins_player, player_pos_x, 0)
            write_memory.write_pos(jumpins_dummy, dummy_pos_x, 0)
         elseif state == states.QUEUE_TEST_JUMP then
            queue_jump(current_jump_settings, player_position_range[1] + dummy_offset_range[dummy_offset_edit_index],
                       current_jump_settings.attack_delay[attack_delay_edit_index])
            dummy_control.disable_update("pose", false)
            dummy_control.update_pose(nil, nil, jumpins_player, player_pose)
            state = states.TEST_JUMP
         elseif state == states.TEST_JUMP then
            if (jumpins_player.action == 0 or (player_pose == 2 and jumpins_player.action == 7)) and
                jumpins_dummy.action == 0 and all_commands_complete(jumpins_dummy) and
                not inputs.is_playing_input_sequence(jumpins_dummy) then state = states.POSITION end
            if jumpins_dummy.has_just_landed and current_jump_settings.followup.type == 1 then
               advanced_control.clear_programmed_movement(jumpins_dummy)
            end
         end
         if player_pose == 2 then
            dummy_control.disable_update("pose", false)
            dummy_control.update_pose(nil, nil, jumpins_player, player_pose)
         end
         dummy_control.disable_update("pose", true)
      elseif mode == modes.RUN then
         if state == states.WAIT_FOR_START_STATE then
            if gamestate.is_ground_state(jumpins_player, jumpins_player.standing_state) and
                gamestate.is_ground_state(jumpins_dummy, jumpins_dummy.standing_state) and
                jumpins_dummy.character_state_byte == 0 then state = states.SELECT_JUMP end
         end
         if state == states.SELECT_JUMP then
            if #jumps > 0 then
               if jumpins_settings.jump_replay_mode == replay_modes.RANDOM then
                  jump_index = math.random(1, #jumps)
               elseif jumpins_settings.jump_replay_mode == replay_modes.ORDERED then
                  jump_index = jump_index % #jumps + 1
               end
               current_jump = jumps[jump_index]
               if jumpins_settings.player_position_mode == 1 then
                  current_jump.playback.player_reset_position = current_jump.player_position[1]
               elseif jumpins_settings.player_position_mode == 2 then
                  current_jump.playback.player_reset_position = math.floor(jumpins_player.pos_x)
               end
               local should_increment_dummy_position = true
               if jumpins_settings.attack_delay_mode == range_modes.FIXED_POINT or current_jump.attack_delay_mode == 1 then
                  current_jump.playback.attack_delay = current_jump.attack_delay[1]
               elseif jumpins_settings.attack_delay_mode == range_modes.RANGE_RANDOM then
                  current_jump.playback.attack_delay = math.random(current_jump.attack_delay[1],
                                                                   current_jump.attack_delay[2])
               elseif jumpins_settings.attack_delay_mode == range_modes.RANGE_ORDERED then
                  should_increment_dummy_position = false
                  if not current_jump.playback.attack_delay then
                     current_jump.playback.attack_delay = current_jump.attack_delay[1]
                  end
                  if current_jump.playback.attack_delay >= current_jump.attack_delay[2] then
                     should_increment_dummy_position = true
                     current_jump.playback.attack_delay = current_jump.attack_delay[1]
                  else
                     current_jump.playback.attack_delay = current_jump.playback.attack_delay + 1
                  end
               elseif jumpins_settings.attack_delay_mode == range_modes.RANGE_ENDPOINTS then
                  should_increment_dummy_position = false
                  if not current_jump.playback.attack_endpoint then
                     current_jump.playback.attack_endpoint = 1
                  else
                     if current_jump.playback.attack_endpoint >= #attack_delay_range then
                        should_increment_dummy_position = true
                     end
                     current_jump.playback.attack_endpoint = current_jump.playback.attack_endpoint % 2 + 1
                  end
                  current_jump.playback.attack_delay = current_jump.attack_delay[current_jump.playback.attack_endpoint]
               end

               if not current_jump.playback.dummy_reset_offset then
                  current_jump.playback.dummy_reset_offset = current_jump.dummy_offset[1]
               end

               if should_increment_dummy_position then
                  if jumpins_settings.dummy_offset_mode == range_modes.FIXED_POINT or current_jump.dummy_offset_mode ==
                      1 then
                     current_jump.playback.dummy_reset_offset = current_jump.dummy_offset[1]
                  elseif jumpins_settings.dummy_offset_mode == range_modes.RANGE_RANDOM then
                     local new_pos = 0
                     local dummy_valid_range = get_valid_offset_range(jumpins_dummy,
                                                                      current_jump.playback.player_reset_position,
                                                                      current_jump.dummy_offset[1],
                                                                      current_jump.dummy_offset[2])
                     if #dummy_valid_range == 1 then
                        local index = math.random(0, dummy_valid_range[1][2] - dummy_valid_range[1][1])
                        new_pos = dummy_valid_range[1][1] + index
                     else
                        local range_total_left = dummy_valid_range[1][2] - dummy_valid_range[1][1] + 1
                        local range_total_right = dummy_valid_range[2][2] - dummy_valid_range[2][1] + 1
                        local total = range_total_left + range_total_right
                        local index = math.random(0, total - 1)
                        if index <= range_total_left then
                           new_pos = dummy_valid_range[1][1] + index
                        else
                           new_pos = dummy_valid_range[2][1] + index - range_total_left
                        end
                     end
                     current_jump.playback.dummy_reset_offset = new_pos - current_jump.playback.player_reset_position
                  elseif jumpins_settings.dummy_offset_mode == range_modes.RANGE_ORDERED then
                     local dummy_valid_range = get_valid_offset_range(jumpins_dummy,
                                                                      current_jump.playback.player_reset_position,
                                                                      current_jump.dummy_offset[1],
                                                                      current_jump.dummy_offset[2])
                     if not current_jump.playback.ordered_dummy_position then
                        if dummy_valid_range[1][1] - current_jump.playback.player_reset_position <= 0 then
                           current_jump.playback.ordered_dummy_position = dummy_valid_range[1][1]
                           current_jump.playback.ordered_dummy_sign = 1
                           current_jump.playback.ordered_dummy_end = dummy_valid_range[1][2]
                        else
                           if #dummy_valid_range == 1 then
                              current_jump.playback.ordered_dummy_position = dummy_valid_range[1][2]
                              current_jump.playback.ordered_dummy_sign = -1
                              current_jump.playback.ordered_dummy_end = dummy_valid_range[1][1]
                           else
                              current_jump.playback.ordered_dummy_position = dummy_valid_range[2][2]
                              current_jump.playback.ordered_dummy_sign = -1
                              current_jump.playback.ordered_dummy_end = dummy_valid_range[2][1]
                           end
                        end
                     else
                        current_jump.playback.ordered_dummy_position =
                            current_jump.playback.ordered_dummy_position + current_jump.playback.ordered_dummy_sign
                        if current_jump.playback.ordered_dummy_position == current_jump.playback.ordered_dummy_end +
                            current_jump.playback.ordered_dummy_sign then
                           if #dummy_valid_range == 1 then
                              if current_jump.playback.ordered_dummy_end == dummy_valid_range[1][2] then
                                 current_jump.playback.ordered_dummy_position = dummy_valid_range[1][1]
                                 current_jump.playback.ordered_dummy_sign = 1
                                 current_jump.playback.ordered_dummy_end = dummy_valid_range[1][2]
                              elseif current_jump.playback.ordered_dummy_end == dummy_valid_range[1][1] then
                                 current_jump.playback.ordered_dummy_position = dummy_valid_range[1][2]
                                 current_jump.playback.ordered_dummy_sign = -1
                                 current_jump.playback.ordered_dummy_end = dummy_valid_range[1][1]
                              end
                           else
                              if current_jump.playback.ordered_dummy_end == dummy_valid_range[1][2] then
                                 current_jump.playback.ordered_dummy_position = dummy_valid_range[2][2]
                                 current_jump.playback.ordered_dummy_sign = -1
                                 current_jump.playback.ordered_dummy_end = dummy_valid_range[2][1]
                              elseif current_jump.playback.ordered_dummy_end == dummy_valid_range[2][1] then
                                 current_jump.playback.ordered_dummy_position = dummy_valid_range[1][1]
                                 current_jump.playback.ordered_dummy_sign = 1
                                 current_jump.playback.ordered_dummy_end = dummy_valid_range[1][2]
                              end
                           end
                        end
                     end
                     current_jump.playback.dummy_reset_offset =
                         current_jump.playback.ordered_dummy_position - current_jump.playback.player_reset_position
                  elseif jumpins_settings.dummy_offset_mode == range_modes.RANGE_ENDPOINTS then
                     if not current_jump.playback.offset_endpoint then
                        current_jump.playback.offset_endpoint = 1
                     else
                        current_jump.playback.offset_endpoint = current_jump.playback.offset_endpoint % 2 + 1
                     end
                     current_jump.playback.dummy_reset_offset =
                         current_jump.dummy_offset[current_jump.playback.offset_endpoint]
                  end
               end

               state = states.POSITION
            end
         end
         if state == states.POSITION then
            if current_jump then
               local should_scroll = true
               if jumpins_settings.player_position_mode == 2 then
                  should_scroll = false
                  local new_pos = {
                     [-1] = current_jump.playback.player_reset_position - current_jump.playback.dummy_reset_offset,
                     [1] = current_jump.playback.player_reset_position + current_jump.playback.dummy_reset_offset
                  }
                  local sign = 1
                  if not (tools.sign(new_pos[sign] - current_jump.playback.player_reset_position) ==
                      tools.sign(jumpins_dummy.pos_x - jumpins_player.pos_x)) then sign = -1 end
                  local dummy_offset = {sign * current_jump.dummy_offset[1], sign * current_jump.dummy_offset[2]}
                  table.sort(dummy_offset)
                  local dummy_valid_range = get_valid_offset_range(jumpins_dummy,
                                                                   current_jump.playback.player_reset_position,
                                                                   dummy_offset[1], dummy_offset[2])

                  if not ((new_pos[sign] >= dummy_valid_range[1][1] and new_pos[sign] <= dummy_valid_range[1][2]) or
                      (#dummy_valid_range == 2 and new_pos[sign] >= dummy_valid_range[2][1] and new_pos[sign] <=
                          dummy_valid_range[2][2])) then sign = -sign end
                  current_jump.playback.dummy_reset_position = new_pos[sign]

                  local screen_limit_left = gamestate.screen_x - 192 +
                                                framedata.character_specific[jumpins_dummy.char_str].corner_offset_left
                  local screen_limit_right = gamestate.screen_x + 191 +
                                                 framedata.character_specific[jumpins_dummy.char_str]
                                                     .corner_offset_right
                  if current_jump.playback.dummy_reset_position < screen_limit_left then
                     screen_reset_pos_x = screen_limit_left
                     should_scroll = true
                  elseif current_jump.playback.dummy_reset_position > screen_limit_right then
                     screen_reset_pos_x = screen_limit_right
                     should_scroll = true
                  end
               else
                  current_jump.playback.dummy_reset_position =
                      current_jump.playback.player_reset_position + current_jump.playback.dummy_reset_offset
                  screen_reset_pos_x = get_center_screen_position(jumpins_player,
                                                                  current_jump.playback.player_reset_position,
                                                                  current_jump.playback.dummy_reset_position)
               end

               if jumpins_settings.player_position_mode == 1 then
                  if jumpins_dummy.action == 0 and
                      math.abs(current_jump.playback.player_reset_position - math.floor(jumpins_player.pos_x)) <=
                      reset_position_margin and math.floor(jumpins_dummy.pos_x) ==
                      current_jump.playback.dummy_reset_position then state = states.QUEUE_JUMP end
               elseif jumpins_settings.player_position_mode == 2 then
                  if jumpins_dummy.action == 0 and math.floor(jumpins_dummy.pos_x) ==
                      current_jump.playback.dummy_reset_position then state = states.QUEUE_JUMP end
               end
               if should_scroll then
                  if screen_reset_pos_x < gamestate.screen_x then
                     write_memory.set_screen_pos(math.max(screen_reset_pos_x, gamestate.screen_x - screen_scroll_speed),
                                                 0)
                  elseif screen_reset_pos_x > gamestate.screen_x then
                     write_memory.set_screen_pos(math.min(gamestate.screen_x + screen_scroll_speed, screen_reset_pos_x),
                                                 0)
                  end
               end

               if jumpins_settings.player_position_mode == 1 then
                  write_memory.write_pos(jumpins_player, current_jump.playback.player_reset_position, 0)
               end
               write_memory.write_pos(jumpins_dummy, current_jump.playback.dummy_reset_position, 0)
            end
         end
         if state == states.QUEUE_JUMP then
            queue_jump(current_jump, current_jump.playback.dummy_reset_position, current_jump.playback.attack_delay)
            training.disable_dummy[jumpins_dummy.id] = true
            state = states.JUMP
         elseif state == states.JUMP then
            if all_commands_complete(jumpins_dummy) and not inputs.is_playing_input_sequence(jumpins_dummy) then
               training.disable_dummy[jumpins_dummy.id] = false
               if jumpins_dummy.idle_time >= new_jump_start_delay then
                  if jumpins_settings.automatic_replay then
                     state = states.WAIT_FOR_START_STATE
                  else
                     state = states.IDLE
                  end
               end
            end
            if (jumpins_dummy.has_just_landed and current_jump.followup.type == 1) or
                jumpins_dummy.just_received_connection then
               advanced_control.clear_programmed_movement(jumpins_dummy)
            end
         end
      end
      if jumpins_player.superfreeze_decount > 0 or jumpins_dummy.superfreeze_decount > 0 then
         jump_queued_frame = jump_queued_frame + 1
      end
   end
end

local function process_gesture(gesture)
   if is_active then if gesture == "single_tap" then if not jumpins_settings.automatic_replay then try_jump() end end end
end

local jumpins = {
   module_name = module_name,
   init = init,
   begin_edit = begin_edit,
   end_edit = end_edit,
   load_settings = load_settings,
   load_jump = load_jump,
   move_player_left = move_player_left,
   move_player_right = move_player_right,
   move_dummy_left = move_dummy_left,
   move_dummy_right = move_dummy_right,
   update_selected_jump = update_selected_jump,
   change_dummy_offset_edit_mode = change_dummy_offset_edit_mode,
   change_dummy_offset_edit_index = change_dummy_offset_edit_index,
   change_attack_delay_edit_mode = change_attack_delay_edit_mode,
   change_attack_delay_edit_index = change_attack_delay_edit_index,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture
}

setmetatable(jumpins, {
   __index = function(_, key)
      if key == "dummy_offset_edit_index" then
         return dummy_offset_edit_index
      elseif key == "is_active" then
         return is_active
      elseif key == "player_position_range" then
         return player_position_range
      elseif key == "dummy_offset_range" then
         return dummy_offset_range
      elseif key == "attack_delay_range" then
         return attack_delay_range
      elseif key == "second_jump_delay_range" then
         return second_jump_delay_range
      elseif key == "player_position_bounds" then
         return player_position_bounds
      elseif key == "dummy_offset_bounds" then
         return dummy_offset_bounds
      elseif key == "attack_delay_bounds" then
         return attack_delay_bounds
      elseif key == "second_jump_delay_bounds" then
         return second_jump_delay_bounds
      elseif key == "dummy_offset_edit_index" then
         return dummy_offset_edit_index
      elseif key == "attack_delay_edit_index" then
         return attack_delay_edit_index
      elseif key == "dummy_offset_edit_mode" then
         return dummy_offset_edit_mode
      elseif key == "attack_delay_edit_mode" then
         return attack_delay_edit_mode
      elseif key == "jumpins_player" then
         return jumpins_player
      elseif key == "jumpins_dummy" then
         return jumpins_dummy
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      elseif key == "dummy_offset_edit_index" then
         dummy_offset_edit_index = value
      else
         rawset(jumpins, key, value)
      end
   end
})

return jumpins
