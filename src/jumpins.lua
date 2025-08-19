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

function jumpins_display(_player)
  if is_in_match then
    player_position_display()
    local _name = "jump_forward"
    if frame_number % 50 == 0 then
      local _player_mdata, _dummy_mdata = simulate_jump(_player, "jump_forward", _player.pos_x)
      jump_arcs[_name] = create_jump_arc(_player_mdata)
    end
    draw_jump_arcs(jump_arcs)
  end
end

function create_jump_arc(_mdata)
  local _jump_arc = {}
  for i = 1, #_mdata do
    local _x, _y = game_to_screen_space(_mdata[i].pos_x, _mdata[i].pos_y)
    table.insert(_jump_arc, {_x, _y})
  end
  return _jump_arc
end

local max_sim_time = 100
function simulate_jump(_player, _jump_type, _start_x, _attack, _attack_frame)
  local _dummy = _player.other
  _start_x = _start_x or _player.pos_x
  local _startup_type = "jump_startup"
  local _anim, _frame_data = find_frame_data_by_name(_player.char_str, _startup_type)
  local _jump_startup_length = #_frame_data.frames
  local _jump_startup = predict_frames_branching(_player, _anim, 0, _jump_startup_length, nil, true)[1]
  local _anim, _frame_data = find_frame_data_by_name(_player.char_str, _jump_type)

  local _player_motion_data = init_motion_data_zero(_player)
  _player_motion_data[0].pos_x = _start_x

  local _dummy_motion_data = init_motion_data(_dummy)

  if _frame_data then
    local _player_line = predict_frames_branching(_player, _anim, 0, max_sim_time, nil, true)[1]
    _player_line[0] = {animation = _player.animation, frame = _player.animation_frame, delta = 0}

  print_pline(_player_line)

    local _dummy_line = predict_frames_branching(_dummy, _dummy.animation, nil, max_sim_time)[1]
    if _dummy_line == nil then
      _dummy_line = {}
      for i = 1, max_sim_time do
        table.insert(_dummy_line, {animation = _dummy.animation, frame = _dummy.animation_frame + i, delta = i})
      end
    end
    _dummy_line[0] = {animation = _dummy.animation, frame = _dummy.animation_frame, delta = 0}
    
    _player_motion_data.switched_sides = check_switch_sides(_player)
    _dummy_motion_data.switched_sides = check_switch_sides(_dummy)

    for i = 1, #_player_line do

      predict_player_movement(_player, _player_motion_data, _player_line,
                              _dummy, _dummy_motion_data, _dummy_line, i)

    -- print(i, _player_line[i].animation, _player_line[i].frame, _player_motion_data[i].pos_y, _player_motion_data[i].velocity_y, _player_motion_data[i].acceleration_y)
--[[       if _player_motion_data[i].pos_y == 0 then
        for j = 1, #_player_motion_data - i do
          table.remove(_player_motion_data)
        end
        break
      end ]]
    end
  end
  return _player_motion_data, _dummy_motion_data
end

function draw_jump_arcs(_jump_arcs)
  --t:{x,y}
  for _, _jump_arc in pairs(_jump_arcs) do
  -- print("draw", #_jump_arc)
    for i = 1, #_jump_arc do
      gui.pixel(_jump_arc[i][1], _jump_arc[i][2], 0xFFFFFFFF)
    end
  end
end

function reset_positions()

end