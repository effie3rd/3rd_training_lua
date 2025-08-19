data_path = "data/"..rom_name.."/"
framedata_path = data_path.."framedata/"
frame_data_file_ext = "_framedata.json"


-- # Character specific stuff
character_specific = {}
for i = 1, #characters do
  character_specific[characters[i]] = {}
  character_specific[characters[i]].timed_sa = {false, false, false}
end
-- ## Character approximate dimensions
character_specific.alex.half_width = 45
character_specific.chunli.half_width = 39
character_specific.dudley.half_width = 29
character_specific.elena.half_width = 44
character_specific.gill.half_width = 36
character_specific.gouki.half_width = 33
character_specific.hugo.half_width = 43
character_specific.ibuki.half_width = 34
character_specific.ken.half_width = 30
character_specific.makoto.half_width = 42
character_specific.necro.half_width = 26
character_specific.oro.half_width = 40
character_specific.q.half_width = 25
character_specific.remy.half_width = 32
character_specific.ryu.half_width = 31
character_specific.sean.half_width = 29
character_specific.twelve.half_width = 33
character_specific.urien.half_width = 36
character_specific.yang.half_width = 41
character_specific.yun.half_width = 37
character_specific.shingouki.half_width = 33

character_specific.alex.height = 104
character_specific.chunli.height = 97
character_specific.dudley.height = 109
character_specific.elena.height = 88
character_specific.gill.height = 121
character_specific.gouki.height = 107
character_specific.hugo.height = 137
character_specific.ibuki.height = 92
character_specific.ken.height = 107
character_specific.makoto.height = 90
character_specific.necro.height = 89
character_specific.oro.height = 88
character_specific.q.height = 130
character_specific.remy.height = 114
character_specific.ryu.height = 101
character_specific.sean.height = 103
character_specific.twelve.height = 91
character_specific.urien.height = 121
character_specific.yang.height = 89
character_specific.yun.height = 89
character_specific.shingouki.height = 107

character_specific.alex.corner_offset_left = 32
character_specific.alex.corner_offset_right = 31
character_specific.chunli.corner_offset_left = 28
character_specific.chunli.corner_offset_right = 27
character_specific.dudley.corner_offset_left = 32
character_specific.dudley.corner_offset_right = 31
character_specific.elena.corner_offset_left = 28
character_specific.elena.corner_offset_right = 27
character_specific.gill.corner_offset_left = 32
character_specific.gill.corner_offset_right = 31
character_specific.gouki.corner_offset_left = 30
character_specific.gouki.corner_offset_right = 29
character_specific.hugo.corner_offset_left = 40
character_specific.hugo.corner_offset_right = 39
character_specific.ibuki.corner_offset_left = 24
character_specific.ibuki.corner_offset_right = 23
character_specific.ken.corner_offset_left = 28
character_specific.ken.corner_offset_right = 27
character_specific.makoto.corner_offset_left = 28
character_specific.makoto.corner_offset_right = 27
character_specific.necro.corner_offset_left = 36
character_specific.necro.corner_offset_right = 35
character_specific.oro.corner_offset_left = 28
character_specific.oro.corner_offset_right = 27
character_specific.q.corner_offset_left = 24
character_specific.q.corner_offset_right = 23
character_specific.remy.corner_offset_left = 24
character_specific.remy.corner_offset_right = 23
character_specific.ryu.corner_offset_left = 28
character_specific.ryu.corner_offset_right = 27
character_specific.sean.corner_offset_left = 28
character_specific.sean.corner_offset_right = 27
character_specific.twelve.corner_offset_left = 36
character_specific.twelve.corner_offset_right = 35
character_specific.urien.corner_offset_left = 32
character_specific.urien.corner_offset_right = 31
character_specific.yang.corner_offset_left = 24
character_specific.yang.corner_offset_right = 23
character_specific.yun.corner_offset_left = 24
character_specific.yun.corner_offset_right = 23
character_specific.shingouki.corner_offset_left = 30
character_specific.shingouki.corner_offset_right = 29

character_specific.alex.push_value = 22
character_specific.chunli.push_value = 17
character_specific.dudley.push_value = 20
character_specific.elena.push_value = 19
character_specific.gill.push_value = 19
character_specific.gouki.push_value = 20
character_specific.hugo.push_value = 23
character_specific.ibuki.push_value = 19
character_specific.ken.push_value = 20
character_specific.makoto.push_value = 20
character_specific.necro.push_value = 19
character_specific.oro.push_value = 19
character_specific.q.push_value = 19
character_specific.remy.push_value = 17
character_specific.ryu.push_value = 20
character_specific.sean.push_value = 20
character_specific.twelve.push_value = 20
character_specific.urien.push_value = 19
character_specific.yang.push_value = 16
character_specific.yun.push_value = 16
character_specific.shingouki.push_value = 20

-- ## Characters standing states
character_specific.oro.additional_standing_states = { 3 } -- 3 is crouching
character_specific.dudley.additional_standing_states = { 6 } -- 6 is crouching
character_specific.makoto.additional_standing_states = { 7 } -- 7 happens during Oroshi
character_specific.necro.additional_standing_states = { 13 } -- 13 happens during CrLK

-- ## Characters timed SA
character_specific.oro.timed_sa[1] = true;
character_specific.oro.timed_sa[3] = true;
character_specific.q.timed_sa[3] = true;
character_specific.makoto.timed_sa[3] = true;
character_specific.twelve.timed_sa[3] = true;
character_specific.yang.timed_sa[3] = true;
character_specific.yun.timed_sa[3] = true;

-- ## Frame data meta
frame_data_meta = {}
for _, _char in pairs(frame_data_keys) do
  frame_data_meta[_char] = {}
end
framedata_meta_file_path = data_path.."framedata_meta"
require(framedata_meta_file_path)

-- # Frame data
frame_data = {}

stages =
{
[0] = {name = "gill", left = 80, right = 943},
[1] = {name = "alex", left = 80, right = 955},
[2] = {name = "ryu", left = 80, right = 939},
[3] = {name = "yun", left = 80, right = 951},
[4] = {name = "dudley", left = 80, right = 943},
[5] = {name = "necro", left = 80, right = 943},
[6] = {name = "hugo", left = 76, right = 945},
[7] = {name = "ibuki", left = 79, right = 943},
[8] = {name = "elena", left = 76, right = 935},
[9] = {name = "oro", left = 76, right = 945},
[10] = {name = "yang", left = 80, right = 951},
[11] = {name = "ken", left = 80, right = 955},
[12] = {name = "sean", left = 76, right = 945},
[13] = {name = "urien", left = 76, right = 951},
[14] = {name = "gouki", left = 80, right = 943},
[15] = {name = "shingouki", left = 80, right = 943},
[16] = {name = "chunli", left = 70, right = 951},
[17] = {name = "makoto", left = 84, right = 945},
[18] = {name = "dudley", left = 80, right = 943},
[19] = {name = "twelve", left = 80, right = 943},
[20] = {name = "remy", left = 82, right = 943}
}

function test_collision(_defender_x, _defender_y, _defender_flip_x, _defender_boxes, _attacker_x, _attacker_y, _attacker_flip_x, _attacker_boxes, _box_type_matches, _defender_hurtbox_dilation_x, _defender_hurtbox_dilation_y, _attacker_hitbox_dilation_x, _attacker_hitbox_dilation_y)
to_draw_collision = {}
  local _debug = false
  if (_defender_hurtbox_dilation_x == nil) then _defender_hurtbox_dilation_x = 0 end
  if (_defender_hurtbox_dilation_y == nil) then _defender_hurtbox_dilation_y = 0 end
  if (_attacker_hitbox_dilation_x == nil) then _attacker_hitbox_dilation_x = 0 end
  if (_attacker_hitbox_dilation_y == nil) then _attacker_hitbox_dilation_y = 0 end
  if (_test_throws == nil) then _test_throws = false end
  if (_box_type_matches == nil) then _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}} end

  if (#_box_type_matches == 0 ) then return false end
  if (#_defender_boxes == 0 ) then return false end
  if (#_attacker_boxes == 0 ) then return false end
  if _debug then print(string.format("   %d defender boxes, %d attacker boxes", #_defender_boxes, #_attacker_boxes)) end
  for k = 1, #_box_type_matches do
    local _box_type_match = _box_type_matches[k]
    for i = 1, #_defender_boxes do
      local _d_box = format_box(_defender_boxes[i])

      --print("d ".._d_box.type)

      local _defender_box_match = false
      for _key, _value in ipairs(_box_type_match[1]) do
        if _value == _d_box.type then
          _defender_box_match = true
          break
        end
      end
      if _defender_box_match then
        -- compute defender box bounds
        local _d_l
        if _defender_flip_x == 0 then
          _d_l = _defender_x + _d_box.left
        else
          _d_l = _defender_x - _d_box.left - _d_box.width
        end
        local _d_r = _d_l + _d_box.width
        local _d_b = _defender_y + _d_box.bottom
        local _d_t = _d_b + _d_box.height

        _d_l = _d_l - _defender_hurtbox_dilation_x
        _d_r = _d_r + _defender_hurtbox_dilation_x
        _d_b = _d_b - _defender_hurtbox_dilation_y
        _d_t = _d_t + _defender_hurtbox_dilation_y

        for j = 1, #_attacker_boxes do
          local _a_box = format_box(_attacker_boxes[j])

          local _attacker_box_match = false
          for _key, _value in ipairs(_box_type_match[2]) do
            if _value == _a_box.type then
              _attacker_box_match = true
              break
            end
          end

          if _attacker_box_match then
            -- compute attacker box bounds
            local _a_l
            if _attacker_flip_x == 0 then
              _a_l = _attacker_x + _a_box.left
            else
              _a_l = _attacker_x - _a_box.left - _a_box.width
            end
            local _a_r = _a_l + _a_box.width
            local _a_b = _attacker_y + _a_box.bottom
            local _a_t = _a_b + _a_box.height

            _a_l = _a_l - _attacker_hitbox_dilation_x
            _a_r = _a_r + _attacker_hitbox_dilation_x
            _a_b = _a_b - _attacker_hitbox_dilation_y
            _a_t = _a_t + _attacker_hitbox_dilation_y
            -- table.insert(to_draw_collision, {_d_l, _d_r, _d_b, _d_t})
            -- table.insert(to_draw_collision, {_a_l, _a_r, _a_b, _a_t})
--             print(frame_number, _defender_x, _d_box.left, _d_box.width, _d_box.bottom, _d_box.height)

            if _debug then print(string.format("   testing (%d,%d,%d,%d)(%s) against (%d,%d,%d,%d)(%s)", _d_t, _d_r, _d_b, _d_l, _d_box.type, _a_t, _a_r, _a_b, _a_l, _a_box.type)) end

            -- check collision
            if
            (_a_l < _d_r) and
            (_a_r > _d_l) and
            (_a_b < _d_t) and
            (_a_t > _d_b)
            then
              return true
            end
          end
        end
      end
    end
  end

  return false
end

local max_wakeup_time = 100
function get_wakeup_time(_char, _anim, _frame)
  if not frame_data[_char] or not frame_data[_char][_anim] then
    return 0
  end
  local i = 1
  local _wakeup_time = 0
  local _frame_to_check = _frame + 1
  local _frame_data = frame_data[_char][_anim]
  local _frames = _frame_data.frames
  local _used_next_anim = false
  while i <= max_wakeup_time do
    if _frames then
      _used_next_anim = false
      if _frames[_frame_to_check].next_anim then
        local _a = _frames[_frame_to_check].next_anim[1][1]
        local _f = _frames[_frame_to_check].next_anim[1][2]
        _frame_data = frame_data[_char][_a]
        if _frame_data then
          _frames = _frame_data.frames
          _frame_to_check = _f + 1
          _used_next_anim = true
        else
          return _wakeup_time
        end
      end

      _wakeup_time = _wakeup_time + 1

      if not _used_next_anim then
        i = i + 1
        _frame_to_check = _frame_to_check + 1
      end

      if _frames and _frames[_frame_to_check].wakeup then
        return _wakeup_time
      end
    end
  end
  return _wakeup_time
end

function get_move_sequence_by_name(_char, _name, _button)
  local _sequence = {}
  for _k, _move in pairs(move_list[_char]) do
    if _move.name == _name then
      _sequence = deepcopy(_move.input)
      break
    end
  end
  local i = 1
  while i <= #_sequence do
    local j = 1
    while j <= #_sequence[i] do
      if _sequence[i][j] == "button" then
        if _button == "EXP"  then
          table.remove(_sequence[i], j)
          table.insert(_sequence[i], j, "LP")
          table.insert(_sequence[i], j, "MP")
        elseif _button == "EXK"  then
          table.remove(_sequence[i], j)
          table.insert(_sequence[i], j, "LK")
          table.insert(_sequence[i], j, "MK")
        else
          table.remove(_sequence[i], j)
          table.insert(_sequence[i], j, _button)
        end
      end
      j = j + 1
    end
    i = i + 1
  end
  return _sequence
end

function find_frame_data_by_name(_char, _name)
  local _frame_data = frame_data[_char]
  if _frame_data then
    for _k, _data in pairs(_frame_data) do
      if _data.name == _name then
        return _k, _data
      end
    end
  end
  return nil
end