local text = require("src.ui.text")
local framedata = require("src.modules.framedata")
local framedata_meta = require("src.modules.framedata_meta")
local move_data = require("src.modules.move_data")
local gamestate = require("src.gamestate")
local image_tables = require("src.ui.image_tables")
local colors = require("src.ui.colors")
local prediction = require("src.modules.prediction")
local write_memory = require("src.control.write_memory")
local dummy_control = require("src.control.dummy_control")
local advanced_control = require("src.control.advanced_control")
local memory_addresses = require("src.control.memory_addresses")
local inputs = require("src.control.inputs")
local jumpins_tables = require("src.training.jumpins_tables")
local draw = require("src.ui.draw")
local utils = require("src.modules.utils")
local tools = require("src.tools")
local hud = require("src.ui.hud")
local training = require("src.training")
local find_frame_data_by_name = framedata.find_frame_data_by_name
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text,
                                                                                             text.render_text_multiple,
                                                                                             text.get_text_dimensions,

                                                                                             text.get_text_dimensions_multiple
local Delay = advanced_control.Delay
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete

local module_name = "jumpins"

local is_active = false
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
local modes = {EDIT = 1, RUN = 2}
local mode = modes.EDIT
local states = {POSITION = 1, QUEUE_TEST_JUMP = 2, TEST_JUMP = 3}
local state = states.POSITION
local autofire_delay = 5
local change_position_start_frame = 0
local move_speed = 1
local max_move_speed = 3
local move_speed_increase_delay = 20
local contact_dist = 0
local test_jump_start_delay = 30

local player_position_range = {0, 0}
local dummy_offset_range = {0, 0}
local attack_delay_range = {0, 0}
local player_position_bounds = {0, 0}
local dummy_offset_bounds = {0, 0}
local attack_delay_bounds = {0, 0}

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

local edit_points = {PLAYER = 1, DUMMY_OFFSET_1 = 2, DUMMY_OFFSET_2 = 3}

local jump_arcs = {}

local general_settings = {}
local edit_jump_settings = {}

local function init()
   if not is_active then
      jumpins_player = training.player
      jumpins_dummy = training.dummy
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
   draw_player_distances(jumpins_dummy)
end

local function begin_edit()
   if not is_active then
      is_active = true
      inputs.block_input(1, "all")
      inputs.block_input(2, "all")
      dummy_control.disable_update("pose", true)
      training.swap_recording_player = false
      training.toggle_swap_characters()
      hud.register_draw(jumpins_display)
   end
end

local function end_edit()
   is_active = false
   training.swap_recording_player = true
   training.toggle_swap_characters()
   inputs.unblock_input(1)
   inputs.unblock_input(2)
   dummy_control.disable_update("pose", false)
   advanced_control.clear_all()
   hud.unregister_draw(jumpins_display)
end

local function change_dummy_offset_edit_mode()
   dummy_offset_edit_mode = dummy_offset_edit_mode % 2 + 1
   if dummy_offset_edit_mode == 1 then dummy_offset_edit_index = 1 end
   edit_jump_settings.dummy_offset_mode = dummy_offset_edit_mode
   return dummy_offset_edit_mode
end

local function change_dummy_offset_edit_index()
   dummy_offset_edit_index = dummy_offset_edit_index % dummy_offset_edit_max_points + 1
   return dummy_offset_edit_index
end

local function change_attack_delay_edit_mode()
   attack_delay_edit_mode = attack_delay_edit_mode % 2 + 1
   if attack_delay_edit_index == 1 then attack_delay_edit_index = 1 end
   edit_jump_settings.attack_delay_mode = attack_delay_edit_mode
   return attack_delay_edit_mode
end

local function change_attack_delay_edit_index()
   attack_delay_edit_index = attack_delay_edit_index % attack_delay_edit_max_points + 1
   return attack_delay_edit_index
end

local function get_current_dummy_offset()
   if dummy_offset_edit_mode == 1 then
      return dummy_offset_range[1]
   elseif dummy_offset_edit_mode == 2 then
      return dummy_offset_range[dummy_offset_edit_index]
   end
end

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

local function fix_screen_position(player, player_pos_x)
   local screen_pos_x = gamestate.screen_x
   local scroll_boundary_left = screen_pos_x + (129 - framedata.character_specific[player.char_str].corner_offset_left)
   local scroll_boundary_right = screen_pos_x - (129 - framedata.character_specific[player.char_str].corner_offset_right)
   if player_pos_x <= scroll_boundary_left then
      local screen_limit_left, _ = utils.get_stage_screen_limits(gamestate.stage)
      local new_screen_pos = math.max(screen_pos_x + player_pos_x - scroll_boundary_left, screen_limit_left)
      write_memory.set_screen_pos(new_screen_pos, 0)
   elseif player_pos_x >= scroll_boundary_right then
      local _, screen_limit_right = utils.get_stage_screen_limits(gamestate.stage)
      local new_screen_pos = math.min(screen_pos_x + player_pos_x - scroll_boundary_right, screen_limit_right)
      write_memory.set_screen_pos(new_screen_pos, 0)
   end
end

local function get_valid_range(selected_player)
   local other_player = selected_player.other
   local other_player_right = other_player.pos_x + contact_dist
   local other_player_left = other_player.pos_x - contact_dist
   local max_offset_left =
       draw.SCREEN_WIDTH - framedata.character_specific[selected_player.char_str].corner_offset_left -
           framedata.character_specific[other_player.char_str].corner_offset_right
   local max_offset_right = draw.SCREEN_WIDTH -
                                framedata.character_specific[selected_player.char_str].corner_offset_right -
                                framedata.character_specific[other_player.char_str].corner_offset_left
   local stage_left, stage_right = utils.get_stage_limits(gamestate.stage, selected_player.char_str)
   local left_min = math.floor(math.max(stage_left, other_player.pos_x - max_offset_left))
   local left_max = math.floor(math.max(stage_left, other_player.pos_x - contact_dist))
   local right_min = math.floor(math.min(stage_right, other_player.pos_x + contact_dist))
   local right_max = math.floor(math.min(stage_right, other_player.pos_x + max_offset_left))
   return {{left_min, left_max}, {right_min, right_max}}
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

local function update_attack_bounds()
   local jump_name = jumpins_tables.get_jump_names()[edit_jump_settings.jump_name]
   local second_jump_name = jumpins_tables.get_second_jump_names()[edit_jump_settings.second_jump_name]
   local second_jump_delay = edit_jump_settings.second_jump_delay
   -- maybe sim both jumps
   local jump_arc = simulate_jump(jumpins_dummy, dummy_offset_range[1], jump_name, second_jump_name, second_jump_delay,
                                  nil, nil)
   local startup_anim, startup_fdata = get_jump_startup(jumpins_dummy.char_str, jump_name)
   local min_delay = startup_fdata and startup_fdata.frames and #startup_fdata.frames or 4
   min_delay = min_delay + 2
   if is_sjump(jump_name) then min_delay = min_delay + 1 end
   attack_delay_bounds[1] = min_delay
   attack_delay_bounds[2] = #jump_arc
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
end

local function change_selected_jump()
   update_attack_bounds()
   bound_settings()
end

local moved_left_last_frame = false
local moved_right_last_frame = false
local move_left_frame = gamestate.frame_number
local move_right_frame = gamestate.frame_number
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
   local new_x, switched_sides = move_left(jumpins_player, player_position_range[1],
                                           player_position_range[1] + get_current_dummy_offset(), dist)
   player_position_range[1] = new_x
   player_position_range[2] = new_x
   if switched_sides then
      dummy_offset_range[1] = -dummy_offset_range[1]
      dummy_offset_range[2] = -dummy_offset_range[2]
   end
   update_position_bounds()
   bound_settings()
   fix_screen_position(jumpins_player, player_position_range[1])
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
   local new_x, switched_sides = move_right(jumpins_player, player_position_range[1],
                                            player_position_range[1] + get_current_dummy_offset(), dist)
   player_position_range[1] = new_x
   player_position_range[2] = new_x
   if switched_sides then
      dummy_offset_range[1] = -dummy_offset_range[1]
      dummy_offset_range[2] = -dummy_offset_range[2]
   end
   update_position_bounds()
   bound_settings()
   fix_screen_position(jumpins_player, player_position_range[1])
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
   local new_x = move_left(jumpins_dummy, player_position_range[1] + get_current_dummy_offset(),
                           player_position_range[1], dist)
   if dummy_offset_edit_mode == 2 then
      update_position_bounds()
      while new_x >= dummy_offset_bounds[1] do
         if not tools.table_contains(dummy_offset_range, new_x) then break end
         new_x = move_left(jumpins_dummy, new_x, player_position_range[1], dist)
      end
   end
   local new_offset = new_x - player_position_range[1]
   dummy_offset_range[dummy_offset_edit_index] = new_offset
   if dummy_offset_edit_mode == 2 then
      table.sort(dummy_offset_range)
      dummy_offset_edit_index = tools.table_indexof(dummy_offset_range, new_offset) or 1
   end
   local dummy_right = get_current_dummy_offset() + contact_dist
   local dummy_left = get_current_dummy_offset() - contact_dist
   if player_position_range[1] > dummy_left and player_position_range[1] < dummy_right then
      player_position_range[1] = dummy_right
      player_position_range[2] = dummy_right
   end
   update_position_bounds()
   bound_settings()
   fix_screen_position(jumpins_dummy, new_x)
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
   local new_x = move_right(jumpins_dummy, player_position_range[1] + get_current_dummy_offset(),
                            player_position_range[1], dist)
   if dummy_offset_edit_mode == 2 then
      update_position_bounds()
      while new_x <= dummy_offset_bounds[2] do
         if not tools.table_contains(dummy_offset_range, new_x) then break end
         new_x = move_right(jumpins_dummy, new_x, player_position_range[1], dist)
      end
   end
   local new_offset = new_x - player_position_range[1]
   dummy_offset_range[dummy_offset_edit_index] = new_offset
   if dummy_offset_edit_mode == 2 then
      table.sort(dummy_offset_range)
      dummy_offset_edit_index = tools.table_indexof(dummy_offset_range, new_offset) or 1
   end
   local dummy_right = get_current_dummy_offset() + contact_dist
   local dummy_left = get_current_dummy_offset() - contact_dist
   if player_position_range[1] > dummy_left and player_position_range[1] < dummy_right then
      player_position_range[1] = dummy_left
      player_position_range[2] = dummy_left
   end
   update_position_bounds()
   bound_settings()
   fix_screen_position(jumpins_dummy, new_x)
   current_jump_arc = nil
end

local function load_settings(settings) general_settings = settings end

local function load_jump(jump_settings)
   edit_jump_settings = jump_settings
   player_position_range = jump_settings.player_position
   dummy_offset_range = jump_settings.dummy_offset
   attack_delay_range = jump_settings.attack_delay
   dummy_offset_edit_mode = jump_settings.dummy_offset_mode
   attack_delay_edit_mode = jump_settings.attack_delay_mode
   dummy_offset_edit_index = 1
   attack_delay_edit_index = 1
   update_position_bounds()
   update_attack_bounds()
   bound_settings()
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
   if second_jump_name and second_jump_name ~= "none" then
      should_second_jump = true
      second_jump_input = jumpins_tables.get_jump_inputs(second_jump_name)
      if second_jump_name == "air_dash_forward" or second_jump_name == "air_dash_back" then
         second_jump_timer = Delay:new(second_jump_delay - 3)
      else
         second_jump_timer = Delay:new(second_jump_delay - 1)
      end
   end
   local attack_input, is_target_combo = jumpins_tables.get_move_inputs(attack_name)
   local attack_timer = Delay:new(attack_delay - #attack_input)

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
         end
      }
   }
   if should_second_jump then
      local second_jump = {
         condition = function() return second_jump_timer:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, second_jump_input)
            attack_timer:begin()
         end
      }

      table.insert(command, second_jump)
   end
   if is_target_combo then
      local target_combo = {
         {
            condition = function() return attack_timer:is_complete() end,
            action = function() queue_input_sequence_and_wait(player, {attack_input[1]}) end
         }, {
            condition = function() return player.has_just_connected end,
            action = function() queue_input_sequence_and_wait(player, {attack_input[2]}) end
         }
      }
      table.insert(command, target_combo[1])
      table.insert(command, target_combo[2])
   else
      local attack = {
         condition = function() return attack_timer:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input, 0, true) end
      }
      table.insert(command, attack)
   end
   if followup then
      local followup_input
      local followup_data = utils.create_move_data_from_selection(followup, jumpins_dummy)
      if followup.type ~= 5 then
         followup_input = inputs.create_input_sequence(followup_data)
      else
         followup_input = require("src.control.recording").get_current_recording_slot().inputs
      end
      local is_throw = false
      local throw_hit_frame = 3
      if followup.type == 2 then
         if followup_data.name == "LP+LK" or followup.motion == 15 then is_throw = true end
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
         else
            local anim, fdata = find_frame_data_by_name(jumpins_dummy.char_str, move_name, followup_data.button)
            if anim and framedata_meta.frame_data_meta[jumpins_dummy.char_str][anim] then
               is_throw = framedata_meta.frame_data_meta[jumpins_dummy.char_str][anim].throw
            end
         end
         if is_throw then
            throw_hit_frame = framedata.get_first_hit_frame_by_name(jumpins_dummy.char_str, move_name,
                                                                    followup_data.button) + 1
         end
      end

      local followup_command = {
         condition = function()
            return advanced_control.is_landing_timing(player, #followup_input, true) and
                       advanced_control.is_idle_timing(player, #followup_input - followup_delay, true) and
                       (not is_throw or
                           advanced_control.is_throw_vulnerable_timing(player.other,
                                                                       #followup_input + throw_hit_frame -
                                                                           followup_delay, true))
         end,
         action = function() queue_input_sequence_and_wait(player, followup_input) end
      }
      table.insert(command, followup_command)
   end

   advanced_control.queue_programmed_movement(player, command)
end

local function debug_jump()
   current_jump_arc = simulate_jump(gamestate.P1, gamestate.P1.pos_x, "jump_forward", nil, nil, nil, nil)
   hud.register_draw(jumpins_display)
end

local function single_jump()
   player_position_range = {430, 430}
   dummy_offset_range = {500, 500}
   local delay = 23
   jumpins_player = gamestate.P1
   jumpins_dummy = gamestate.P2
   reset_positions(jumpins_player, jumpins_dummy)
   execute_jump(jumpins_player, "jump_forward", "MK", delay)
end

local timer = Delay:new(2)
local start_delay = 16
local max_delay = 30
local delay = start_delay
local jstate = "start"
local has_hit_this_loop = false
-- 22
-- 395 23
jumpins_tables.init("yang")
player_position_range = {430, 430}
dummy_offset_range = {500, 500}
local function test_jump()

   -- delay = delay + 1
   -- print("---", delay)
   if jstate == "start" then
      jumpins_player = gamestate.P1
      jumpins_dummy = gamestate.P2
      reset_positions(jumpins_player, jumpins_dummy)
      delay = delay + 1
      jstate = "pos"
   elseif jstate == "pos" then
      if jumpins_player.pos_x ~= player_position_range[1] or jumpins_player.action ~= 0 then
         reset_positions(jumpins_player, jumpins_dummy)
      elseif jumpins_player.is_idle and jumpins_dummy.is_idle and jumpins_player.action == 0 and jumpins_dummy.action ==
          0 then
         current_jump_arc = simulate_jump(gamestate.P1, gamestate.P1.pos_x, "jump_forward", nil, nil, "raigeki_HK",
                                          delay)

         execute_jump(jumpins_player, "jump_forward", nil, 0, "drill_MK", delay)

         print("jump_forward", "raigeki_HK", delay)
         jstate = "run"
      end
   elseif jstate == "new_j" then
      player_position_range[1] = player_position_range[1] - 1
      player_position_range[2] = player_position_range[2] - 1
      delay = start_delay
      has_hit_this_loop = false
      jstate = "qstart"
   elseif jstate == "run" then
      -- inputs.queue_input_sequence(jumpins_dummy, {{"back"}}, 0, true)
      if jumpins_player.has_just_hit or jumpins_player.other.has_just_parried or jumpins_dummy.has_just_been_hit or
          jumpins_dummy.has_just_parried then
         print("============")
         print(">", player_position_range[1], "delay", delay - 1)
         timer:reset()
         jstate = "qstart"
      elseif jumpins_player.has_just_been_blocked then
         timer:reset()
         has_hit_this_loop = true
         jstate = "qstart"
      elseif delay >= max_delay then
         timer:reset()
         jstate = "new_j"
      elseif jumpins_player.has_just_landed then
         if has_hit_this_loop then
            timer:reset()
            jstate = "new_j"
            return
         end
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

local function start()
   is_active = true
   inputs.unblock_input(1)
   inputs.unblock_input(2)
   init()
   hud.unregister_draw(jumpins_display)
end

local function stop()
   if is_active then
      is_active = false
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      hud.unregister_draw(jumpins_display)
   end
end

local function reset() end

local function update()
   if is_active then
      if mode == modes.EDIT then
         player_pose = require("src.settings").training.pose
         if state == states.POSITION then
            if gamestate.frame_number - move_right_frame >= test_jump_start_delay and gamestate.frame_number -
                move_left_frame >= test_jump_start_delay and
                jumpins_tables.get_jump_names()[edit_jump_settings.jump_name] ~= "off" then
               if (jumpins_player.action == 0 or (player_pose == 2 and jumpins_player.action == 7)) and
                   jumpins_dummy.action == 0 and math.floor(jumpins_player.pos_x) == player_position_range[1] and
                   math.floor(jumpins_dummy.pos_x) == player_position_range[1] + dummy_offset_range[dummy_offset_edit_index] then
                  state = states.QUEUE_TEST_JUMP
               end
            end
            print(jumpins_player.pos_x,  player_position_range[1], jumpins_dummy.pos_x, player_position_range[1] + dummy_offset_range[dummy_offset_edit_index])
            write_memory.write_pos(jumpins_player, player_position_range[1], 0)
            write_memory.write_pos(jumpins_dummy,
                                   player_position_range[1] + dummy_offset_range[dummy_offset_edit_index], 0)
         elseif state == states.QUEUE_TEST_JUMP then
            local first_jump_name = jumpins_tables.get_jump_names()[edit_jump_settings.jump_name]
            if first_jump_name ~= "off" then
               local second_jump_name = jumpins_tables.get_second_jump_names()[edit_jump_settings.second_jump_name]
               local second_jump_delay = edit_jump_settings.second_jump_delay
               local attack_name = jumpins_tables.get_attack_names()[edit_jump_settings.attack_name]
               local attack_delay = edit_jump_settings.attack_delay[attack_delay_edit_index]
               local followup = edit_jump_settings.followup
               local followup_delay = edit_jump_settings.followup_delay
               execute_jump(jumpins_dummy, first_jump_name, second_jump_name, second_jump_delay, attack_name,
                            attack_delay, followup, followup_delay)
               dummy_control.disable_update("pose", false)
               dummy_control.update_pose(nil, nil, jumpins_player, player_pose)
               if general_settings.show_jump_arc then
                  current_jump_arc = simulate_jump(jumpins_dummy, player_position_range[1] +
                                                       dummy_offset_range[dummy_offset_edit_index], first_jump_name,
                                                   second_jump_name, second_jump_delay, attack_name, attack_delay)

               end
            end
            state = states.TEST_JUMP
         elseif state == states.TEST_JUMP then
            if (jumpins_player.action == 0 or (player_pose == 2 and jumpins_player.action == 7)) and
                jumpins_dummy.action == 0 and all_commands_complete(jumpins_dummy) and
                not inputs.is_playing_input_sequence(jumpins_dummy) then state = states.POSITION end
            if jumpins_dummy.has_just_landed and edit_jump_settings.followup.type == 1 then
               advanced_control.clear_programmed_movement(jumpins_dummy)
            end
         end
         if player_pose == 2 then
            dummy_control.disable_update("pose", false)
            dummy_control.update_pose(nil, nil, jumpins_player, player_pose)
         end
         dummy_control.disable_update("pose", true)
      elseif mode == modes.RUN then
      end
   end
end

local function process_gesture(gesture) end

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
   change_selected_jump = change_selected_jump,
   change_dummy_offset_edit_mode = change_dummy_offset_edit_mode,
   change_dummy_offset_edit_index = change_dummy_offset_edit_index,
   change_attack_delay_edit_mode = change_attack_delay_edit_mode,
   change_attack_delay_edit_index = change_attack_delay_edit_index,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture,
   test_jump = test_jump,
   debug_jump = debug_jump,
   single_jump = single_jump
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
      elseif key == "player_position_bounds" then
         return player_position_bounds
      elseif key == "dummy_offset_bounds" then
         return dummy_offset_bounds
      elseif key == "attack_delay_bounds" then
         return attack_delay_bounds
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
