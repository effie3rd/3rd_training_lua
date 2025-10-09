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

local max_jumps = 5
local jumps = {

   -- char:
   -- {
   --    {player pos
   --    dummy reset offset range
   --    reset type
   --    jump
   --    attack
   --    delay}
   --    followup
   -- }
} -- id
-- jump type
-- jump dir
-- distance
-- point 不動点
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

states = {
   EDIT = 1
}

show_jumpins_display = false
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


function init_jumpins()
   jump_arcs = {}
   show_jumpins_display = true
end

-- init_jumpins()

function jumpins_display(player)
   if gamestate.is_in_match then
      player_position_display()
      local name = "jump_forward"
      if gamestate.frame_number % 50 == 0 then
         local player_mdata, dummy_mdata = simulate_jump(player, "jump_forward", player.pos_x)
         jump_arcs[name] = create_jump_arc(player_mdata)
      end
      draw_jump_arcs(jump_arcs)
   end
end

function create_jump_arc(mdata)
   local jump_arc = {}
   for i = 1, #mdata do
      local x, y = draw.game_to_screen_space(mdata[i].pos_x, mdata[i].pos_y)
      table.insert(jump_arc, {x, y})
   end
   return jump_arc
end

local max_sim_time = 100
function simulate_jump(player, jump_type, start_x, attack, attack_frame)
   local dummy = player.other
   start_x = start_x or player.pos_x
   local startup_type = "jump_startup"
   local anim, fdata = find_frame_data_by_name(player.char_str, startup_type)
   local jump_startup_length = #fdata.frames
   local jump_startup = predict_frames_branching(player, anim, 0, jump_startup_length, true)[1]
   local anim, fdata = find_frame_data_by_name(player.char_str, jump_type)

   local player_motion_data = prediction.init_motion_data_zero(player)
   player_motion_data[0].pos_x = start_x

   local dummy_motion_data = prediction.init_motion_data(dummy)
   local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                                 max_sim_time)

   return player_motion_data, dummy_motion_data
end

function draw_jump_arcs(jump_arcs)
   -- t:{x,y}
   for _, jump_arc in pairs(jump_arcs) do
      -- print("draw", #jump_arc)
      for i = 1, #jump_arc do gui.image(jump_arc[i][1] - 1, jump_arc[i][2] - 1, image_tables.img_dot) end
   end
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
            condition = function() return player.just_connected end,
            action = function() queue_input_sequence_and_wait(player, attack_input[2]) end
         }
      }
   end
   advanced_control.queue_programmed_movement(player, command)
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

return {test_jump = test_jump}
