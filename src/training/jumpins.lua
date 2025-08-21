local text = require("src/text")
local fd = require("src/framedata")
local movedata = require("src/movedata")
local gamestate = require("src/gamestate")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local test_collision, find_frame_data_by_name = fd.test_collision, fd.find_frame_data_by_name
local is_slow_jumper, is_really_slow_jumper = fd.is_slow_jumper, fd.is_really_slow_jumper
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text, text.render_text_multiple, text.get_text_dimensions, text.get_text_dimensions_multiple
local move_list = movedata.move_list

--jummp type
--jump dir
--distance
--point 不動点
--range (type)　範囲
    --min max
--button
--6button checkbox
--raigeki drill other commands
--timing
--point 不動点
--range (type)
    --min max

  --distance from opponent pushbox border
  --draw jump arc
  --indicate hitting and missing sections

--dummy does test jumps

show_jumpins_display = false
local jump_arcs = {}

function init_jumpins()
  jump_arcs = {}
  show_jumpins_display = true
end

--init_jumpins()

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
    local x, y = game_to_screen_space(mdata[i].pos_x, mdata[i].pos_y)
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
  local jump_startup = predict_frames_branching(player, anim, 0, jump_startup_length, nil, true)[1]
  local anim, fdata = find_frame_data_by_name(player.char_str, jump_type)

  local player_motion_data = init_motion_data_zero(player)
  player_motion_data[0].pos_x = start_x

  local dummy_motion_data = init_motion_data(dummy)

  if fdata then
    local player_line = predict_frames_branching(player, anim, 0, max_sim_time, nil, true)[1]
    player_line[0] = {animation = player.animation, frame = player.animation_frame, delta = 0}

  print_pline(player_line)

    local dummy_line = predict_frames_branching(dummy, dummy.animation, nil, max_sim_time)[1]
    if dummy_line == nil then
      dummy_line = {}
      for i = 1, max_sim_time do
        table.insert(dummy_line, {animation = dummy.animation, frame = dummy.animation_frame + i, delta = i})
      end
    end
    dummy_line[0] = {animation = dummy.animation, frame = dummy.animation_frame, delta = 0}
    
    player_motion_data.switched_sides = check_switch_sides(player)
    dummy_motion_data.switched_sides = check_switch_sides(dummy)

    for i = 1, #player_line do

      predict_player_movement(player, player_motion_data, player_line,
                              dummy, dummy_motion_data, dummy_line, i)

    -- print(i, player_line[i].animation, player_line[i].frame, player_motion_data[i].pos_y, player_motion_data[i].velocity_y, player_motion_data[i].acceleration_y)
--[[       if player_motion_data[i].pos_y == 0 then
        for j = 1, #player_motion_data - i do
          table.remove(player_motion_data)
        end
        break
      end ]]
    end
  end
  return player_motion_data, dummy_motion_data
end

function draw_jump_arcs(jump_arcs)
  --t:{x,y}
  for _, jump_arc in pairs(jump_arcs) do
  -- print("draw", #jump_arc)
    for i = 1, #jump_arc do
      gui.pixel(jump_arc[i][1], jump_arc[i][2], 0xFFFFFFFF)
    end
  end
end

function reset_positions()

end