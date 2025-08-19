-- # global variables
frame_number = 0
is_in_match = false
player_objects = {}
P1 = nil
P2 = nil
stage = 0

attacking_byte_exception = {}
attacking_byte_exception["alex"] = {
                          ["5944"] = true,
                          ["5aec"] = true,
                          ["5cac"] = true,
                          ["5e54"] = true}
attacking_byte_exception["chunli"] = {
                          ["486c"] = true,
                          ["4b64"] = true,
                          ["4e44"] = true,
                          ["5124"] = true,
                          ["ce8c"] = true,
                          ["c3b4"] = true}
attacking_byte_exception["dudley"] = {
                          ["3cdc"] = true}
attacking_byte_exception["gill"] = {
                          ["d63c"] = true}
attacking_byte_exception["gouki"] = {
                          ["a330"] = true,
                          ["a508"] = true,
                          ["a6e0"] = true,
                          ["5124"] = true}
attacking_byte_exception["hugo"] = {
                          ["efcc"] = true,
                          ["f1bc"] = true,
                          ["f3ac"] = true,
                          ["f59c"] = true,
                          ["1d64"] = true,
                          ["1f24"] = true,
                          ["2184"] = true,
                          ["f7a4"] = true,
                          ["fa54"] = true,
                          ["fd1c"] = true,
                          ["0044"] = true}
attacking_byte_exception["ibuki"] = {
                          ["93b8"] = true,
                          ["6aa8"] = true,
                          ["9578"] = true,
                          ["6b48"] = true,
                          ["9750"] = true,
                          ["63f0"] = true,
                          ["edb0"] = true,
                          ["66a8"] = true,
                          ["ef80"] = true,
                          ["f150"] = true,
                          ["0748"] = true,
                          ["e2f0"] = true}
attacking_byte_exception["ken"] = {
                          ["a870"] = true,
                          ["abe8"] = true}
attacking_byte_exception["makoto"] = {
                          ["2720"] = true,
                          ["df10"] = true}
attacking_byte_exception["necro"] = {
                          ["dd9c"] = true,
                          ["f084"] = true,
                          ["e7a4"] = true,
                          ["5824"] = true,
                          ["5e7c"] = true,
                          ["7d94"] = true,
                          ["7f24"] = true,
                          ["80b4"] = true,
                          ["8574"] = true,
                          ["dadc"] = true}
attacking_byte_exception["ryu"] = {
                          ["81dc"] = true,
                          ["8354"] = true,
                          ["84fc"] = true}
attacking_byte_exception["sean"] = {
                          ["1ef0"] = true,
                          ["2060"] = true,
                          ["2130"] = true,
                          ["2200"] = true,
                          ["4310"] = true,
                          ["c25c"] = true}
attacking_byte_exception["shingouki"] = {
                          ["ddc0"] = true,
                          ["df98"] = true,
                          ["e170"] = true}
attacking_byte_exception["twelve"] = {
                          ["510c"] = true,
                          ["4bac"] = true}
attacking_byte_exception["urien"] = {
                          ["6aac"] = true}
attacking_byte_exception["yang"] = {
                          ["94d8"] = true}
attacking_byte_exception["yun"] = {
                          ["1e28"] = true}

-- # api
function make_input_set(_value)
  return {
    up = _value,
    down = _value,
    left = _value,
    right = _value,
    LP = _value,
    MP = _value,
    HP = _value,
    LK = _value,
    MK = _value,
    HK = _value,
    start = _value,
    coin = _value
  }
end

function make_player_object(_id, _base, _prefix)
  return {
    id = _id,
    base = _base,
    prefix = _prefix,
    type = "player",
    input = {
      pressed = make_input_set(false),
      released = make_input_set(false),
      down = make_input_set(false),
      state_time = make_input_set(0),
    },
    blocking = {
      wait_for_block_string = true,
      block_string = false,
    },
    counter = {
      attack_frame = -1,
      ref_time = -1,
      recording_slot = -1,
    },
    throw = {},
    stunned = false,
    meter_gauge = 0,
    meter_count = 0,
    max_meter_gauge = 0,
    max_meter_count = 0,
    highest_hit_id = 0,--debug
    next_hit_id = 0,
    cooldown = 0
  }
end


function reset_player_objects()
  player_objects = {
    make_player_object(1, 0x02068C6C, "P1"),
    make_player_object(2, 0x02069104, "P2")
  }

  P1 = player_objects[1]
  P2 = player_objects[2]

  P1.other = P2
  P2.other = P1

  P1.life_addr = P1.base + 0x9F
  P1.gauge_addr = 0x020695B5
  P1.meter_addr = { 0x020286AB, 0x020695BF } -- 2nd address is the master variable
  P1.stun_max_addr = 0x020695F7
  P1.stun_activate_addr = P1.stun_max_addr - 0x3
  P1.stun_timer_addr = P1.stun_max_addr + 0x2
  P1.stun_bar_char_addr = P1.stun_max_addr + 0x6
  P1.stun_bar_mantissa_addr = P1.stun_max_addr + 0x7
  P1.stun_bar_decrease_timer_addr = P1.stun_max_addr + 0x8
  P1.stun_bar_decrease_amount_addr = P1.stun_max_addr + 0xB
  P1.meter_update_flag = 0x020157C8
  P1.score_addr = 0x020113A2
  P1.parry_forward_validity_time_addr = 0x02026335
  P1.parry_forward_cooldown_time_addr = 0x02025731
  P1.parry_down_validity_time_addr = 0x02026337
  P1.parry_down_cooldown_time_addr = 0x0202574D
  P1.parry_air_validity_time_addr = 0x02026339
  P1.parry_air_cooldown_time_addr = 0x02025769
  P1.parry_antiair_validity_time_addr = 0x02026347
  P1.parry_antiair_cooldown_time_addr = 0x0202582D
  P1.damage_of_next_hit_addr = 0x020691A7
  P1.stun_of_next_hit_addr = 0x02069437

  P1.charge_1_reset_addr = 0x02025A47 -- Alex_1(Elbow)
  P1.charge_1_addr = 0x02025A49
  P1.charge_2_reset_addr = 0x02025A2B -- Alex_2(Stomp), Urien_2(Knee?)
  P1.charge_2_addr = 0x02025A2D
  P1.charge_3_reset_addr = 0x02025A0F -- Oro_1(Shou), Remy_2(LoVKick?)
  P1.charge_3_addr = 0x02025A11
  P1.charge_4_reset_addr = 0x020259F3 -- Urien_3(headbutt?), Q_2(DashLeg), Remy_1(LoVPunch?)
  P1.charge_4_addr = 0x020259F5
  P1.charge_5_reset_addr = 0x020259D7 -- Oro_2(Yanma), Urien_1(tackle), Chun_4, Q_1(DashHead), Remy_3(Rising)
  P1.charge_5_addr = 0x020259D9

  P1.kaiten_1_reset_addr = 0x020258F7 -- Hugo Moonsault/Gigas, Alex Hyper Bomb
  P1.kaiten_1_addr = 0x0202590F
  P1.kaiten_2_reset_addr = 0x020259F3 -- Hugo Meat squasher
  P1.kaiten_2_addr = 0x02025A0B
  P1.kaiten_completed_360_addr = 0x020258FF -- equal to 48 if one 360 was completed. hugo only

  P2.life_addr = P2.base + 0x9F
  P2.gauge_addr = 0x020695E1
  P2.meter_addr = { 0x020286DF, 0x020695EB} -- 2nd address is the master variable
  P2.stun_max_addr = 0x0206960B
  P2.stun_activate_addr = P2.stun_max_addr - 0x3
  P2.stun_timer_addr = P2.stun_max_addr + 0x2
  P2.stun_bar_char_addr = P2.stun_max_addr + 0x6
  P2.stun_bar_mantissa_addr = P2.stun_max_addr + 0x7
  P2.stun_bar_decrease_timer_addr = P2.stun_max_addr + 0x8
  P2.stun_bar_decrease_amount_addr = P2.stun_max_addr + 0xB
  P2.meter_update_flag = 0x020157C9
  P2.score_addr = 0x020113AE
  P2.parry_forward_validity_time_addr = P1.parry_forward_validity_time_addr + 0x406
  P2.parry_forward_cooldown_time_addr = P1.parry_forward_cooldown_time_addr + 0x620
  P2.parry_down_validity_time_addr = P1.parry_down_validity_time_addr + 0x406
  P2.parry_down_cooldown_time_addr = P1.parry_down_cooldown_time_addr + 0x620
  P2.parry_air_validity_time_addr = P1.parry_air_validity_time_addr + 0x406
  P2.parry_air_cooldown_time_addr = P1.parry_air_cooldown_time_addr + 0x620
  P2.parry_antiair_validity_time_addr = P1.parry_antiair_validity_time_addr + 0x406
  P2.parry_antiair_cooldown_time_addr = P1.parry_antiair_cooldown_time_addr + 0x620
  P2.damage_of_next_hit_addr = 0x02068D0F
  P2.stun_of_next_hit_addr = 0x02068F9F

  P2.charge_1_reset_addr = 0x02025FF7
  P2.charge_1_addr = 0x02025FF9
  P2.charge_2_reset_addr = 0x0202602F
  P2.charge_2_addr = 0x02026031
  P2.charge_3_reset_addr = 0x02026013
  P2.charge_3_addr = 0x02026013
  P2.charge_4_reset_addr = 0x0202604B
  P2.charge_4_addr = 0x0202604D
  P2.charge_5_reset_addr = 0x02026067
  P2.charge_5_addr = 0x02026069


  P2.kaiten_1_reset_addr = 0x2025F17
  P2.kaiten_1_addr = 0x2025F2F
  P2.kaiten_2_reset_addr = 0x02026013
  P2.kaiten_2_addr = 0x0202600F
  P2.kaiten_completed_360_addr = 0x02025F1F
end

function update_received_hits(_self, _other)
  if _self.received_connection or _self.is_being_thrown then
    _self.last_received_connection_animation = _other.animation
    _self.last_received_connection_hit_id = math.max(_other.current_hit_id, 1)
  elseif frame_number - _self.last_received_connection_frame == 1 then
    for _, _proj in pairs(projectiles) do
      if _proj.emitter_id == _other.id
      and (_proj.previous_remaining_hits - _proj.remaining_hits == 1
          or _proj.previous_remaining_hits - _proj.remaining_hits == -255)
      then
        _self.last_received_connection_animation = _proj.projectile_type
        _self.last_received_connection_hit_id = _proj.remaining_hits --could use max_hits - remaining if needed
      end
    end
  end
end

function update_player_relationships(_self, _other)
  if _self.posture == 0x26 and not recording_framedata then
    _self.remaining_wakeup_time = get_wakeup_time(_self.char_str, _self.animation, _self.animation_frame)
  else
    _self.remaining_wakeup_time = 0
  end
end


-- ## read
function gamestate_read()
  -- game
  read_game_vars()

  -- players
  read_player_vars(P1)
  read_player_vars(P2)

 -- projectiles
  read_projectiles()

  if is_in_match then
    update_received_hits(P1, P2)
    update_received_hits(P2, P1)

    remove_expired_projectiles()
    
    update_flip_input(P1, P2)
    update_flip_input(P2, P1)

    update_player_relationships(P1, P2)
    update_player_relationships(P2, P1)
  end
end

function read_game_vars()
  -- frame number
  frame_number = memory.readdword(0x02007F00)

  -- is in match
  -- I believe the bytes that are expected to be 0xff means that a character has been locked, while the byte expected to be 0x02 is the current match state. 0x02 means that round has started and players can move
  local p1_locked = memory.readbyte(0x020154C6)
  local p2_locked = memory.readbyte(0x020154C8)
  match_state = memory.readbyte(0x020154A7)

  local _previous_is_in_match = is_in_match

  if _previous_is_in_match == nil then _previous_is_in_match = true end
  is_in_match = ((p1_locked == 0xFF or p2_locked == 0xFF) and match_state == 0x02)
  has_match_just_started = not _previous_is_in_match and is_in_match

  stage = memory.readbyte(addresses.global.stage)
end


function read_input(_player_obj)

  function read_single_input(_input_object, _input_name, _input)
    _input_object.pressed[_input_name] = false
    _input_object.released[_input_name] = false
    if _input_object.down[_input_name] == false and _input then _input_object.pressed[_input_name] = true end
    if _input_object.down[_input_name] == true and _input == false then _input_object.released[_input_name] = true end

    if _input_object.down[_input_name] == _input then
      _input_object.state_time[_input_name] = _input_object.state_time[_input_name] + 1
    else
      _input_object.state_time[_input_name] = 0
    end
    _input_object.down[_input_name] = _input
  end

  local _local_input = joypad.get()
  read_single_input(_player_obj.input, "start", _local_input[_player_obj.prefix.." Start"])
  read_single_input(_player_obj.input, "coin", _local_input[_player_obj.prefix.." Coin"])
  read_single_input(_player_obj.input, "up", _local_input[_player_obj.prefix.." Up"])
  read_single_input(_player_obj.input, "down", _local_input[_player_obj.prefix.." Down"])
  read_single_input(_player_obj.input, "left", _local_input[_player_obj.prefix.." Left"])
  read_single_input(_player_obj.input, "right", _local_input[_player_obj.prefix.." Right"])
  read_single_input(_player_obj.input, "LP", _local_input[_player_obj.prefix.." Weak Punch"])
  read_single_input(_player_obj.input, "MP", _local_input[_player_obj.prefix.." Medium Punch"])
  read_single_input(_player_obj.input, "HP", _local_input[_player_obj.prefix.." Strong Punch"])
  read_single_input(_player_obj.input, "LK", _local_input[_player_obj.prefix.." Weak Kick"])
  read_single_input(_player_obj.input, "MK", _local_input[_player_obj.prefix.." Medium Kick"])
  read_single_input(_player_obj.input, "HK", _local_input[_player_obj.prefix.." Strong Kick"])
end


function read_box(_obj, _ptr, _type)
  if _obj.friends > 1 then --Yang SA3
    if _type ~= "attack" then
      return
    end
  end

  local left   = memory.readwordsigned(_ptr + 0x0)
  local width  = memory.readwordsigned(_ptr + 0x2)
  local bottom = memory.readwordsigned(_ptr + 0x4) --debug
  local height = memory.readwordsigned(_ptr + 0x6)

  _box = {convert_box_types[_type], bottom, height, left, width}

  if left == 0 and width == 0 and bottom == 0 and height == 0 then
    return
  end

  table.insert(_obj.boxes, _box)
end

function read_game_object(_obj)
  if memory.readdword(_obj.base + 0x2A0) == 0 then --invalid objects
    return false
  end

  _obj.friends = memory.readbyte(_obj.base + 0x1)
  _obj.flip_x = memory.readbytesigned(_obj.base + 0x0A) -- sprites are facing left by default
  _obj.previous_pos_x = _obj.pos_x or 0
  _obj.previous_pos_y = _obj.pos_y or 0
  _obj.pos_x_char = memory.readwordsigned(_obj.base + 0x64)
  _obj.pos_x_mantissa = memory.readbyte(_obj.base + 0x66)
  _obj.pos_y_char = memory.readwordsigned(_obj.base + 0x68)
  _obj.pos_y_mantissa = memory.readbyte(_obj.base + 0x6A)
  _obj.pos_x = _obj.pos_x_char + _obj.pos_x_mantissa / 256
  _obj.pos_y = _obj.pos_y_char + _obj.pos_y_mantissa / 256

  _obj.velocity_x_char = memory.readwordsigned(_obj.base + 0x64 + 24)
  _obj.velocity_x_mantissa = memory.readbyte(_obj.base + 0x64 + 26)
  _obj.velocity_y_char = memory.readwordsigned(_obj.base + 0x64 + 28)
  _obj.velocity_y_mantissa = memory.readbyte(_obj.base + 0x64 + 30)
  _obj.acceleration_x_char = memory.readwordsigned(_obj.base + 0x64 + 32)
  _obj.acceleration_x_mantissa = memory.readbyte(_obj.base + 0x64 + 34)
  _obj.acceleration_y_char = memory.readwordsigned(_obj.base + 0x64 + 36)
  _obj.acceleration_y_mantissa = memory.readbyte(_obj.base + 0x64 + 38)


  _obj.velocity_x = _obj.velocity_x_char + _obj.velocity_x_mantissa / 256
  _obj.velocity_y = _obj.velocity_y_char + _obj.velocity_y_mantissa / 256
  _obj.acceleration_x = _obj.acceleration_x_char + _obj.acceleration_x_mantissa / 256
  _obj.acceleration_y = _obj.acceleration_y_char + _obj.acceleration_y_mantissa / 256

  _obj.char_id = memory.readword(_obj.base + 0x3C0)

  _obj.boxes = {}
  local _boxes = {
    {initial = 1, offset = 0x2D4, type = "push", number = 1},
    {initial = 1, offset = 0x2C0, type = "throwable", number = 1},
    {initial = 1, offset = 0x2A0, type = "vulnerability", number = 4},
    {initial = 1, offset = 0x2A8, type = "ext. vulnerability", number = 4},
    {initial = 1, offset = 0x2C8, type = "attack", number = 4},
    {initial = 1, offset = 0x2B8, type = "throw", number = 1}
  }

  for _, _box in ipairs(_boxes) do
    for i = _box.initial, _box.number do
      read_box(_obj, memory.readdword(_obj.base + _box.offset) + (i-1)*8, _box.type)
    end
  end

  _obj.animation_frame_id = memory.readword(_obj.base + 0x21A)
  _obj.animation_frame_id2 = memory.readbyte(_obj.base + 0x214) --number of frames animation stays on current frame_id
  _obj.animation_frame_id3 = memory.readbyte(_obj.base + 0x205)

  -- not a unique id for each frame but good enough
  local _hash = {string.format("%04x", _obj.animation_frame_id),
                 string.format("%02x", _obj.animation_frame_id2),
                 string.format("%02x", _obj.animation_frame_id3),}

  if _obj.id == 1 or _obj.id == 2 then
    local _action_type = memory.readbyte(_obj.base + 0xAD)
    --throw, normal, special/sa
    if _action_type == 3 or _action_type == 4 or _action_type == 5 then
      local _action_count = memory.readbyte(_obj.base + 0x459)
      table.insert(_hash, string.format("%02x", _action_count))
    else
      table.insert(_hash, "00")
    end
  else
    table.insert(_hash, "00")
  end


  _obj.animation_frame_hash = table.concat(_hash)
  return true
end




function find_resync_target(_obj, _frame_data, _infinite_loop)
  local _frames = _frame_data.frames
  local _hash_length = 10
  local _target = -1
  if _infinite_loop then
    _hash_length = 8
  end
  _target_hash = string.sub(_obj.animation_frame_hash, 1, _hash_length)
  -- print(_hash_length, _current_hash, _target_hash)

  for i = 1, #_frames do
    local _hash = string.sub(_frames[i].hash, 1, _hash_length)
    if _hash == _target_hash then
      return i - 1, _target_hash
    end
  end

  --framedata changes on block/hit for many moves
  if _frame_data.exceptions then
    if _frame_data.exceptions[_target_hash] then
      return _frame_data.exceptions[_target_hash], _target_hash
    end
  end

  --hits or blocks will change the frameid2/frameid3 portion of the hash, so we try to get a partial match instead
  local matches = {}
  local scores = {}
  local frameid = string.format("%04x", _obj.animation_frame_id)
  for i = 1, #_frames do
    if frameid == string.sub(_frames[i].hash, 1, 4) then
      table.insert(matches, i)
      table.insert(scores, 0)
    end
  end

  if #matches > 0 then
    local frameid2 = string.format("%02x", _obj.animation_frame_id2)
    local frameid3 = string.format("%02x", _obj.animation_frame_id3)
    local action_count = "00"
    if _obj.type == "player" then
      action_count = string.format("%02x", _obj.animation_action_count)
    end
    for i = 1, #matches do
      local index = matches[i]
      local t_frameid2 = string.sub(_frames[index].hash, 5, 6)
      local t_frameid3 = string.sub(_frames[index].hash, 7, 8)
      local t_action_count = string.sub(_frames[index].hash, 9, 10)
      if frameid2 == t_frameid2 then
        scores[i] = scores[i] + 30
      end
      if frameid3 == t_frameid3 then
        scores[i] = scores[i] + 20
      end
      if action_count == t_action_count then
        scores[i] = scores[i] + 10
      end
    end

    local key, max = 1, scores[1]
    for i, v in ipairs(scores) do
      if v > max then
        key, max = i, v
      elseif v == max then
        local index = matches[i]
        local index2 = matches[key]
        if math.abs(index - _obj.animation_frame) < math.abs(index2 - _obj.animation_frame) then
          key, max = i, v
        end
      end
    end

    return matches[key] - 1, _target_hash
  end
  
  return _target, _target_hash
end


function read_player_vars(_player_obj)

-- P1: 0x02068C6C
-- P2: 0x02069104

  if memory.readdword(_player_obj.base + 0x2A0) == 0 then --invalid objects
    return
  end

  local _debug_state_variables = _player_obj.debug_state_variables

  read_input(_player_obj)

  read_game_object(_player_obj)

  local _previous_movement_type = _player_obj.movement_type or 0

  _player_obj.char_str = characters[_player_obj.char_id + 1]

  local _player_addresses = addresses.players[_player_obj.id]

  _player_obj.previous_remaining_freeze_frames = _player_obj.remaining_freeze_frames or 0
  _player_obj.remaining_freeze_frames = memory.readbyte(_player_obj.base + 0x45)
  _player_obj.freeze_type = 0
  if _player_obj.remaining_freeze_frames ~= 0 then
    if _player_obj.remaining_freeze_frames < 127 then
      -- inflicted freeze I guess (when the opponent parry you for instance)
      _player_obj.freeze_type = 1
      _player_obj.remaining_freeze_frames = _player_obj.remaining_freeze_frames
    else
      _player_obj.freeze_type = 2
      _player_obj.remaining_freeze_frames = 256 - _player_obj.remaining_freeze_frames
    end
  end
  local _remaining_freeze_frame_diff = _player_obj.remaining_freeze_frames - _player_obj.previous_remaining_freeze_frames
  if _remaining_freeze_frame_diff > 0 then
    log(_player_obj.prefix, "fight", string.format("freeze %d", _player_obj.remaining_freeze_frames))
    --print(string.format("%d: %d(%d)",  _player_obj.id, _player_obj.remaining_freeze_frames, _player_obj.freeze_type))
  end

  local _previous_action = _player_obj.action or 0x00
  local _previous_movement_type2 = _player_obj.movement_type2 or 0x00
  local _previous_posture = _player_obj.posture or 0x00

  _player_obj.previous_input_capacity = _player_obj.input_capacity or 0
  _player_obj.input_capacity = memory.readword(_player_obj.base + 0x46C)
  _player_obj.action = memory.readdword(_player_obj.base + 0xAC)
  _player_obj.action_ext = memory.readdword(_player_obj.base + 0x12C)
  _player_obj.previous_recovery_time = _player_obj.recovery_time or 0
  _player_obj.recovery_time = memory.readbyte(_player_obj.base + 0x187)
  _player_obj.movement_type = memory.readbyte(_player_obj.base + 0x0AD)
  _player_obj.movement_type2 = memory.readbyte(_player_obj.base + 0x0AF) -- seems that we can know which basic movement the player is doing from there
  _player_obj.total_received_projectiles_count = memory.readword(_player_obj.base + 0x430) -- on block or hit

-- postures
--  0x00 -- standing neutral
--  0x08 -- going backwards
--  0x06 -- going forward
--  0x20 -- crouching
--  0x16 -- neutral jump
--  0x14 -- flying forward
--  0x18 -- flying backwards
--  0x1A -- high jump
--  0x26 -- knocked down
  _player_obj.posture = memory.readbyte(_player_obj.base + 0x20E)

  _player_obj.busy_flag = memory.readword(_player_obj.base + 0x3D1)

  local _previous_is_in_basic_action = _player_obj.is_in_basic_action or false
  _player_obj.is_in_basic_action = _player_obj.action < 0xFF and _previous_action < 0xFF -- this triggers one frame early than it should, so we delay it artificially
  _player_obj.has_just_entered_basic_action = not _previous_is_in_basic_action and _player_obj.is_in_basic_action

  local _previous_recovery_flag = _player_obj.recovery_flag or 1
  _player_obj.recovery_flag = memory.readbyte(_player_obj.base + 0x3B)
  _player_obj.has_just_ended_recovery = _previous_recovery_flag ~= 0 and _player_obj.recovery_flag == 0

  _player_obj.meter_gauge = memory.readbyte(_player_obj.gauge_addr)
  _player_obj.meter_count = memory.readbyte(_player_obj.meter_addr[2])

  _player_obj.superfreeze_decount = _player_obj.superfreeze_decount or 0
  local _previous_superfreeze_decount = _player_obj.superfreeze_decount
  if _player_obj.id == 1 then
    _player_obj.max_meter_gauge = memory.readbyte(0x020695B3)
    _player_obj.max_meter_count = memory.readbyte(0x020695BD)
    _player_obj.selected_sa = memory.readbyte(0x0201138B) + 1
    _player_obj.superfreeze_decount = memory.readbyte(0x02069520) -- seems to be in P2 memory space, don't know why
  else
    _player_obj.max_meter_gauge = memory.readbyte(0x020695DF)
    _player_obj.max_meter_count = memory.readbyte(0x020695E9)
    _player_obj.selected_sa = memory.readbyte(0x0201138C) + 1
    _player_obj.superfreeze_decount = memory.readbyte(0x02069088) -- seems to be in P1 memory space, don't know why
  end

  if _player_obj.superfreeze_decount == 0 and _previous_superfreeze_decount > 0 then
    _player_obj.superfreeze_just_ended = true
  else
    _player_obj.superfreeze_just_ended = false
  end

  -- CROUCHED
  _player_obj.is_crouched = _player_obj.posture == 0x20

  -- LIFE
  _player_obj.life = memory.readbyte(_player_obj.life_addr)

  -- COMBO
  _player_obj.previous_combo = _player_obj.combo or 0
  if _player_obj.id == 1 then
    _player_obj.combo = memory.readbyte(0x020696C5)
  else
    _player_obj.combo = memory.readbyte(0x0206961D)
  end

  -- NEXT HIT
  _player_obj.damage_of_next_hit = memory.readbyte(_player_obj.damage_of_next_hit_addr)
  _player_obj.stun_of_next_hit = memory.readbyte(_player_obj.stun_of_next_hit_addr)

  -- BONUSES
  _player_obj.damage_bonus = memory.readword(_player_obj.base + 0x43A)
  _player_obj.stun_bonus = memory.readword(_player_obj.base + 0x43E)
  _player_obj.defense_bonus = memory.readword(_player_obj.base + 0x440)

  -- THROW
  local _previous_is_throwing = _player_obj.is_throwing or false
  _player_obj.is_throwing = bit.rshift(_player_obj.movement_type2, 4) == 9
  _player_obj.has_just_thrown = not _previous_is_throwing and _player_obj.is_throwing

  _player_obj.is_being_thrown = memory.readbyte(_player_obj.base + 0x3CF) ~= 0
  _player_obj.throw_countdown = _player_obj.throw_countdown or 0
  _player_obj.previous_throw_countdown = _player_obj.throw_countdown

  local _throw_countdown = memory.readbyte(_player_obj.base + 0x434)
  if _throw_countdown > _player_obj.previous_throw_countdown then
    _player_obj.throw_countdown = _throw_countdown + 2 -- air throw animations seems to not match the countdown (ie. Ibuki's Air Throw), let's add a few frames to it
  else
    _player_obj.throw_countdown = math.max(_player_obj.throw_countdown - 1, 0)
  end

  if _player_obj.debug_freeze_frames and _player_obj.remaining_freeze_frames > 0 then print(string.format("%d - %d remaining freeze frames", frame_number, _player_obj.remaining_freeze_frames)) end



  local _previous_animation = _player_obj.animation or ""
  _player_obj.animation = bit.tohex(memory.readword(_player_obj.base + 0x202), 4)



  -- ATTACKING
  local _previous_is_attacking = _player_obj.is_attacking or false
  _player_obj.character_state_byte = memory.readbyte(_player_obj.base + 0x27) -- used to detect hugos clap, meat squasher, lariat, which do not set the is_attacking_byte
  _player_obj.is_attacking_byte = memory.readbyte(_player_obj.base + 0x428)
  _player_obj.is_attacking = _player_obj.is_attacking_byte > 0
                          or (attacking_byte_exception[_player_obj.char_str] and attacking_byte_exception[_player_obj.char_str][_player_obj.animation])
  _player_obj.is_attacking_ext_byte = memory.readbyte(_player_obj.base + 0x429)
  _player_obj.is_attacking_ext = _player_obj.is_attacking_ext_byte > 0
  _player_obj.has_just_attacked =  _player_obj.is_attacking and not _previous_is_attacking
  if _debug_state_variables and _player_obj.has_just_attacked then print(string.format("%d - %s attacked", frame_number, _player_obj.prefix)) end

  -- ACTION
  local _previous_action_count = _player_obj.action_count or 0
  _player_obj.action_count = memory.readbyte(_player_obj.base + 0x459)
  _player_obj.has_just_acted = _player_obj.action_count > _previous_action_count
  if _debug_state_variables and _player_obj.has_just_acted then print(string.format("%d - %s acted (%d > %d)", frame_number, _player_obj.prefix, _previous_action_count, _player_obj.action_count)) end

  _player_obj.animation_action_count = _player_obj.animation_action_count or 0
  if _player_obj.has_just_acted then
    _player_obj.animation_action_count = _player_obj.animation_action_count + 1
  end

  -- ANIMATION
  _player_obj.animation_start_frame = _player_obj.animation_start_frame or frame_number
  _player_obj.animation_freeze_frames = _player_obj.animation_freeze_frames or 0



  _player_obj.animation_frame_data = nil
  if frame_data[_player_obj.char_str] then
    _player_obj.animation_frame_data = frame_data[_player_obj.char_str][_player_obj.animation]
  end
  _player_obj.has_animation_just_changed = _previous_animation ~= _player_obj.animation
  if _debug_state_variables and _player_obj.has_animation_just_changed then print(string.format("%d - %s animation changed (%s -> %s)", frame_number, _player_obj.prefix, _previous_animation, _player_obj.animation)) end

  _player_obj.animation_frame = frame_number - _player_obj.animation_start_frame - _player_obj.animation_freeze_frames

  --self chain. cr. lk chains, etc
  if not debug_settings.record_framedata then ---debug
    if _player_obj.self_chain and _player_obj.animation_frame_data then
      local _hit_frames = _player_obj.animation_frame_data.hit_frames
      if _hit_frames and #_hit_frames > 0 then
        if _player_obj.animation_frame > _hit_frames[#_hit_frames][2] then
          _player_obj.has_animation_just_changed = true
        end
      end
    end

    if _player_obj.animation_frame_data and not _player_obj.has_animation_just_changed
    and _player_obj.animation_frame_data.self_chain and _player_obj.animation_frame > 0
    and (_player_obj.has_just_attacked or (_player_obj.previous_input_capacity > 0 and _player_obj.input_capacity == 0)) then
      _player_obj.self_chain = true --look for self chain next frame
    end
  end

  if _player_obj.has_animation_just_changed then
    _player_obj.animation_start_frame = frame_number
    _player_obj.animation_freeze_frames = 0
    _player_obj.highest_hit_id = 0 --debug
    _player_obj.next_hit_id = 0

    _player_obj.current_hit_id = 0
    _player_obj.max_hit_id = 0
    _player_obj.current_attack_hits = 0
    _player_obj.current_attack_max_hits = 0
    _player_obj.animation_action_count = 0
    _player_obj.animation_miss_count = 0
    _player_obj.animation_connection_count = 0
    _player_obj.animation_hash_length = 10
    _player_obj.self_chain = false

    _player_obj.animation_frame = frame_number - _player_obj.animation_start_frame - _player_obj.animation_freeze_frames
  end
--[[   if _self_chain then
    _player_obj.animation_hash_length = 8
  end ]]

    --debug
  -- if not recording_framedata then
    _player_obj.animation_frame_hash = string.sub(_player_obj.animation_frame_hash, 1, 8)
                                      .. string.format("%02x", _player_obj.animation_action_count)
  -- end

--[[   if _player_obj.id == 1 then
    print(frame_number, _player_obj.previous_input_capacity, _player_obj.input_capacity, _player_obj.animation_frame, _player_obj.is_attacking, tostring(_self_cancel))
  end ]]
  if _player_obj.animation_frame_data and not recording_framedata then
    --cap animation frame. animation frame will sometimes exceed # of frames in frame data for some long looping animations i.e. air recovery
    _player_obj.animation_frame = math.min(_player_obj.animation_frame, #_player_obj.animation_frame_data.frames - 1)

    _player_obj.current_attack_max_hits = _player_obj.animation_frame_data.max_hits or 0
  end

  _player_obj.freeze_just_began = false
  _player_obj.freeze_just_ended = false
  if _player_obj.remaining_freeze_frames > 0 then
    if _player_obj.previous_remaining_freeze_frames == 0 then
      _player_obj.freeze_just_began = true
    end
    if not (_player_obj.animation_frame_data and not recording_framedata --debug
            and _player_obj.animation_frame_data.frames
            and _player_obj.animation_frame_data.frames[_player_obj.animation_frame + 1]
            and _player_obj.animation_frame_data.frames[_player_obj.animation_frame + 1].bypass_freeze) then
      _player_obj.animation_freeze_frames = _player_obj.animation_freeze_frames + 1
    end
  elseif _player_obj.remaining_freeze_frames == 0 and _player_obj.previous_remaining_freeze_frames > 0 then
    _player_obj.freeze_just_ended = true
  end


  _player_obj.pushback_start_frame = _player_obj.pushback_start_frame or 0
  _player_obj.is_in_pushback = _player_obj.is_in_pushback or false
  if _player_obj.freeze_just_began
  or _player_obj.is_in_pushback and _player_obj.recovery_time == 0 then
    _player_obj.is_in_pushback = false
  end

  if _player_obj.freeze_just_ended and _player_obj.movement_type == 1 then
    _player_obj.pushback_start_frame = frame_number
    _player_obj.is_in_pushback = true
  end

  if _player_obj.animation_frame_data ~= nil and not recording_framedata then
    -- resync animation
    local _frames = _player_obj.animation_frame_data.frames
    local _current_frame = _frames[_player_obj.animation_frame + 1]
    if _current_frame then
      -- local _target_hash = string.sub(_player_obj.animation_frame_hash, 1, _player_obj.animation_hash_length)
      -- local _current_hash = string.sub(_current_frame.hash, 1, _player_obj.animation_hash_length)
      local _target_hash = _player_obj.animation_frame_hash
      local _current_hash = _current_frame.hash
      if _current_hash ~= nil
      and _current_hash ~= _target_hash
      and (_player_obj.remaining_freeze_frames == 0 or _player_obj.freeze_just_began)
      then
-- print(_player_obj.animation, _target_hash, _current_hash)
        local _resync_target, _target_hash = find_resync_target(_player_obj, _player_obj.animation_frame_data, _player_obj.animation_frame_data.infinite_loop)

        if _resync_target ~= -1 then

          if _resync_target == 0 then
            _player_obj.current_hit_id = 0
            _player_obj.animation_action_count = 0
            _player_obj.animation_connection_count = 0
            _player_obj.animation_miss_count = 0
            _player_obj.self_chain = false
          end
--[[           if _resync_target < _player_obj.animation_frame then
            _player_obj.current_hit_id = 0

            local _hit_frames = _player_obj.animation_frame_data.hit_frames
            for _i, _hit_frame in ipairs(_hit_frames) do
              if _player_obj.animation_frame > _hit_frame[2]
              or (_player_obj.animation_frame >= _hit_frame[1]
                and _player_obj.animation_connection_count >= _i) then
                _player_obj.current_hit_id = _i
              end
            end
            _player_obj.animation_action_count = 0
            _player_obj.animation_connection_count = 0
          end ]]
          _player_obj.animation_frame = _resync_target
          _player_obj.animation_start_frame = frame_number - _resync_target - _player_obj.animation_freeze_frames
        end
      end
    end
  end
  if _player_obj.has_just_acted then
    _player_obj.last_act_animation = _player_obj.animation
  end


  -- RECEIVED HITS/BLOCKS/PARRYS
  local _previous_total_received_hit_count = _player_obj.total_received_hit_count or nil
  _player_obj.total_received_hit_count = memory.readword(_player_obj.base + 0x33E)
  local _total_received_hit_count_diff = 0
  if _previous_total_received_hit_count then
    if _previous_total_received_hit_count == 0xFFFF then
      _total_received_hit_count_diff = 1
    else
      _total_received_hit_count_diff = _player_obj.total_received_hit_count - _previous_total_received_hit_count
    end
  end

  local _previous_received_connection_marker = _player_obj.received_connection_marker or 0
  _player_obj.received_connection_marker = memory.readword(_player_obj.base + 0x32E)
  _player_obj.received_connection = _previous_received_connection_marker == 0 and _player_obj.received_connection_marker ~= 0

  _player_obj.last_received_connection_frame = _player_obj.last_received_connection_frame or 0
  if _player_obj.received_connection then
    _player_obj.last_received_connection_frame = frame_number
  end

  _player_obj.last_movement_type_change_frame = _player_obj.last_movement_type_change_frame or 0
  if _player_obj.movement_type ~= _previous_movement_type then
    _player_obj.last_movement_type_change_frame = frame_number
  end

  -- is blocking/has just blocked/has just been hit/has_just_parried
  _player_obj.blocking_id = memory.readbyte(_player_obj.base + 0x3D3)
  _player_obj.has_just_blocked = false
  if _player_obj.received_connection and _player_obj.received_connection_marker ~= 0xFFF1 and _total_received_hit_count_diff == 0 then --0xFFF1 is parry --this is not completely accurate. there are exceptions e.g. kikouken
    _player_obj.has_just_blocked = true
    log(_player_obj.prefix, "fight", "block")
    if _debug_state_variables then
      print(string.format("%d - %s blocked", frame_number, _player_obj.prefix))
    end
  end
  _player_obj.is_blocking = _player_obj.blocking_id > 0 and _player_obj.blocking_id < 5 or _player_obj.has_just_blocked

  _player_obj.has_just_been_hit = false

  if _total_received_hit_count_diff > 0 then
    _player_obj.has_just_been_hit = true
    log(_player_obj.prefix, "fight", "hit")
  end

  _player_obj.has_just_parried = false
  if _player_obj.received_connection and _player_obj.received_connection_marker == 0xFFF1 and _total_received_hit_count_diff == 0 then
    _player_obj.has_just_parried = true
    log(_player_obj.prefix, "fight", "parry")
    if _debug_state_variables then print(string.format("%d - %s parried", frame_number, _player_obj.prefix)) end
  end

  -- HITS
  local _previous_hit_count = _player_obj.hit_count or 0
  _player_obj.hit_count = memory.readbyte(_player_obj.base + 0x189)
  _player_obj.has_just_hit = _player_obj.hit_count > _previous_hit_count
  if _player_obj.has_just_hit then
    log(_player_obj.prefix, "fight", "has hit")
    if _debug_state_variables then
      print(string.format("%d - %s hit (%d > %d)", frame_number, _player_obj.prefix, _previous_hit_count, _player_obj.hit_count))
    end
  end

  -- BLOCKS
  local _previous_connected_action_count = _player_obj.connected_action_count or 0
  local _previous_blocked_count = _previous_connected_action_count - _previous_hit_count
  _player_obj.connected_action_count = memory.readbyte(_player_obj.base + 0x17B)
  local _blocked_count = _player_obj.connected_action_count - _player_obj.hit_count
  _player_obj.has_just_been_blocked = _blocked_count > _previous_blocked_count
  if _debug_state_variables and _player_obj.has_just_been_blocked then print(string.format("%d - %s blocked (%d > %d)", frame_number, _player_obj.prefix, _previous_blocked_count, _blocked_count)) end
  
  _player_obj.just_connected = _player_obj.just_connected or false
  if _player_obj.connected_action_count > _previous_connected_action_count then
    _player_obj.just_connected =  true
    _player_obj.animation_connection_count = _player_obj.animation_connection_count + 1
  end
  --for turning off hitboxes on hit like necro's drills
  _player_obj.cooldown = math.max(_player_obj.cooldown - 1, 0)

  --update hit id
  if _player_obj.animation_frame_data then
    local _hit_frames = _player_obj.animation_frame_data.hit_frames
    if _hit_frames then
      _player_obj.max_hit_id = #_hit_frames
  --[[     for _i, _hit_frame in ipairs(_hit_frames) do
        if _player_obj.animation_frame > _hit_frame[2]
        or (_player_obj.animation_frame >= _hit_frame[1]
          and _player_obj.animation_connection_count >= _i) then

          --make exceptions for infinite looping moves and yang tc
          _player_obj.current_hit_id = _i
        end
      end ]]

      for _i, _hit_frame in ipairs(_hit_frames) do
        if _i > _player_obj.current_hit_id then
          if _player_obj.animation_frame > _hit_frame[2] then
            _player_obj.animation_miss_count = _player_obj.animation_miss_count + 1
            _player_obj.current_hit_id = _i
          elseif (_player_obj.animation_frame >= _hit_frame[1]
          and _player_obj.animation_connection_count + _player_obj.animation_miss_count >= _i) then
            _player_obj.current_hit_id = _i
          end
        end
      end

      if _player_obj.just_connected then
        --if infinite loop
        _player_obj.current_attack_hits = _player_obj.current_attack_hits + 1

        if _player_obj.animation_frame_data and _player_obj.animation_frame_data.cooldown then
          _player_obj.cooldown = _player_obj.animation_frame_data.cooldown
        end
      end
    end
  end

  -- LANDING
  local _previous_is_in_jump_startup = _player_obj.is_in_jump_startup or false
  _player_obj.is_in_jump_startup = _player_obj.movement_type2 == 0x0C and _player_obj.movement_type == 0x00 and not _player_obj.is_blocking
  _player_obj.previous_standing_state = _player_obj.standing_state or 0
  _player_obj.standing_state = memory.readbyte(_player_obj.base + 0x297)
  _player_obj.has_just_landed = is_state_on_ground(_player_obj.standing_state, _player_obj) and not is_state_on_ground(_player_obj.previous_standing_state, _player_obj)
  if _debug_state_variables and _player_obj.has_just_landed then print(string.format("%d - %s landed (%d > %d)", frame_number, _player_obj.prefix, _player_obj.previous_standing_state, _player_obj.standing_state)) end
  if _player_obj.debug_standing_state and _player_obj.previous_standing_state ~= _player_obj.standing_state then print(string.format("%d - %s standing state changed (%d > %d)", frame_number, _player_obj.prefix, _player_obj.previous_standing_state, _player_obj.standing_state)) end

  -- AIR RECOVERY STATE
  local _debug_air_recovery = false
  local _previous_is_in_air_recovery = _player_obj.is_in_air_recovery or false
  local _r1 = memory.readbyte(_player_obj.base + 0x12F)
  local _r2 = memory.readbyte(_player_obj.base + 0x3C7)
  _player_obj.is_in_air_recovery = _player_obj.standing_state == 0 and _r1 == 0 and _r2 == 0x06 and _player_obj.pos_y ~= 0
  _player_obj.has_just_entered_air_recovery = not _previous_is_in_air_recovery and _player_obj.is_in_air_recovery

  if not _previous_is_in_air_recovery and _player_obj.is_in_air_recovery then
    log(_player_obj.prefix, "fight", string.format("air recovery 1"))
    if _debug_air_recovery then
      print(string.format("%s entered air recovery", _player_obj.prefix))
    end
  end
  if _previous_is_in_air_recovery and not _player_obj.is_in_air_recovery then
    log(_player_obj.prefix, "fight", string.format("air recovery 0"))
    if _debug_air_recovery then
      print(string.format("%s exited air recovery", _player_obj.prefix))
    end
  end



  -- IS IDLE
  local _previous_is_idle = _player_obj.is_idle or false
  _player_obj.idle_time = _player_obj.idle_time or 0
  _player_obj.is_idle = (
    not _player_obj.is_attacking and
--     not _player_obj.is_attacking_ext and --this seems to be set during some target combos. this value is never reset to 0 on some of elena's target combos'
    not _player_obj.is_blocking and
    not _player_obj.is_wakingup and
    not _player_obj.is_fast_wakingup and
    not _player_obj.is_being_thrown and
    not _player_obj.is_in_jump_startup and
    bit.band(_player_obj.busy_flag, 0xFF) == 0 and
    _player_obj.recovery_time == _player_obj.previous_recovery_time and
    _player_obj.remaining_freeze_frames == 0 and
    _player_obj.input_capacity > 0
  )

  _player_obj.just_recovered = _player_obj.previous_recovery_time > 0 and _player_obj.recovery_time == 0
  --[[
  if _player_obj.id == 1 then
    print(string.format(
      "%d: %d, %d, %d, %d, %d, %d, %d, %04x, %d, %d, %04x",
      to_bit(_player_obj.is_idle),
      to_bit(_player_obj.is_attacking),
      to_bit(_player_obj.is_attacking_ext),
      to_bit(_player_obj.is_blocking),
      to_bit(_player_obj.is_wakingup),
      to_bit(_player_obj.is_fast_wakingup),
      to_bit(_player_obj.is_being_thrown),
      to_bit(_player_obj.is_in_jump_startup),
      _player_obj.busy_flag,
      _player_obj.recovery_time,
      _player_obj.remaining_freeze_frames,
      _player_obj.input_capacity
    ))
  end
  ]]

  if _player_obj.is_idle then
    _player_obj.idle_time = _player_obj.idle_time + 1
  else
    _player_obj.idle_time = 0
  end

  if _previous_is_idle ~= _player_obj.is_idle then
    log(_player_obj.prefix, "fight", string.format("idle %d", to_bit(_player_obj.is_idle)))
  end


  if is_in_match then

    -- WAKE UP
    _player_obj.previous_can_fast_wakeup = _player_obj.can_fast_wakeup or 0
    _player_obj.can_fast_wakeup = memory.readbyte(_player_obj.base + 0x402)

    local _previous_fast_wakeup_flag = _player_obj.fast_wakeup_flag or 0
    _player_obj.fast_wakeup_flag = memory.readbyte(_player_obj.base + 0x403)

    local _previous_is_flying_down_flag = _player_obj.is_flying_down_flag or 0
    _player_obj.is_flying_down_flag = memory.readbyte(_player_obj.base + 0x8D) -- does not reset to 0 after air reset landings, resets to 0 after jump start

    _player_obj.previous_is_wakingup = _player_obj.is_wakingup or false
    _player_obj.is_wakingup = _player_obj.is_wakingup or false
    _player_obj.wakeup_time = _player_obj.wakeup_time or 0
--[[     if _previous_is_flying_down_flag == 1 and _player_obj.is_flying_down_flag == 0 and _player_obj.standing_state == 0 and
      (
        _player_obj.movement_type ~= 2 -- movement type 2 is hugo's running grab
        and _player_obj.movement_type ~= 5 -- movement type 5 is ryu's reversal DP on landing
      ) then ]]
    if _previous_posture ~= 0x26 and _player_obj.posture == 0x26 then
      _player_obj.is_wakingup = true
      _player_obj.is_past_wakeup_frame = false
      _player_obj.wakeup_time = 0
      _player_obj.wakeup_animation = _player_obj.animation
      if debug_wakeup then
        print(string.format("%d - %s wakeup started", frame_number, _player_obj.prefix))
      end
    end

    _player_obj.previous_is_fast_wakingup = _player_obj.is_fast_wakingup or false
    _player_obj.is_fast_wakingup = _player_obj.is_fast_wakingup or false
    if _player_obj.is_wakingup and _previous_fast_wakeup_flag == 1 and _player_obj.fast_wakeup_flag == 0 then
      _player_obj.is_fast_wakingup = true
      _player_obj.is_past_wakeup_frame = true
      _player_obj.wakeup_time = 0
      _player_obj.wakeup_animation = _player_obj.animation
      if debug_wakeup then
        print(string.format("%d - %s fast wakeup started", frame_number, _player_obj.prefix))
      end
    end

    if _player_obj.previous_can_fast_wakeup ~= 0 and _player_obj.can_fast_wakeup == 0 then
      _player_obj.is_past_wakeup_frame = true
    end

    if _player_obj.is_wakingup then
      _player_obj.wakeup_time = _player_obj.wakeup_time + 1
    end

    if _player_obj.is_wakingup and _previous_posture == 0x26 and _player_obj.posture ~= 0x26 then
      if debug_wakeup then
        print(string.format("%d - %s wake up: %d, %s, %d", frame_number, _player_obj.prefix, to_bit(_player_obj.is_fast_wakingup), _player_obj.wakeup_animation, _player_obj.wakeup_time))
      end
      _player_obj.is_wakingup = false
      _player_obj.is_fast_wakingup = false
      _player_obj.is_past_wakeup_frame = false
    end

    _player_obj.has_just_started_wake_up = not _player_obj.previous_is_wakingup and _player_obj.is_wakingup
    _player_obj.has_just_started_fast_wake_up = not _player_obj.previous_is_fast_wakingup and _player_obj.is_fast_wakingup
    _player_obj.has_just_woke_up = _player_obj.previous_is_wakingup and not _player_obj.is_wakingup

    if _player_obj.has_just_started_wake_up then
      log(_player_obj.prefix, "fight", string.format("wakeup 1"))
    end
    if _player_obj.has_just_started_fast_wake_up then
      log(_player_obj.prefix, "fight", string.format("fwakeup 1"))
    end
    if _player_obj.has_just_woke_up then
      log(_player_obj.prefix, "fight", string.format("wakeup 0"))
    end
  end

  if not _previous_is_in_jump_startup and _player_obj.is_in_jump_startup then
    _player_obj.last_jump_startup_duration = 0
    _player_obj.last_jump_startup_frame = frame_number
  end

  if _player_obj.is_in_jump_startup then
    _player_obj.last_jump_startup_duration = _player_obj.last_jump_startup_duration + 1
  end

  -- TIMED SA
  if character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa] then
    if _player_obj.superfreeze_decount > 0 then
      _player_obj.is_in_timed_sa = true
    elseif _player_obj.is_in_timed_sa and memory.readbyte(_player_obj.gauge_addr) == 0 then
      _player_obj.is_in_timed_sa = false
    end
  else
    _player_obj.is_in_timed_sa = false
  end

  -- PARRY BUFFERS
  -- global game consts
  _player_obj.parry_forward = _player_obj.parry_forward or { name = "forward", max_validity = 10, max_cooldown = 23 }
  _player_obj.parry_down = _player_obj.parry_down or { name = "down", max_validity = 10, max_cooldown = 23 }
  _player_obj.parry_air = _player_obj.parry_air or { name = "air", max_validity = 7, max_cooldown = 20 }
  _player_obj.parry_antiair = _player_obj.parry_antiair or { name = "anti_air", max_validity = 5, max_cooldown = 18 }

  function read_parry_state(_parry_object, _validity_addr, _cooldown_addr)
    -- read data
    _parry_object.last_hit_or_block_frame =  _parry_object.last_hit_or_block_frame or 0
    if _player_obj.has_just_blocked or _player_obj.has_just_been_hit then
      _parry_object.last_hit_or_block_frame = frame_number
    end
    _parry_object.last_validity_start_frame = _parry_object.last_validity_start_frame or 0
    _parry_object.previous_validity_time = _parry_object.validity_time or 0
    _parry_object.validity_time = memory.readbyte(_validity_addr)
    _parry_object.cooldown_time = memory.readbyte(_cooldown_addr)
    if _parry_object.cooldown_time == 0xFF then _parry_object.cooldown_time = 0 end
    if _parry_object.previous_validity_time == 0 and _parry_object.validity_time ~= 0 then
      _parry_object.last_validity_start_frame = frame_number
      _parry_object.delta = nil
      _parry_object.success = nil
      _parry_object.armed = true
      log(_player_obj.prefix, "parry_training_".._parry_object.name, "armed")
    end

    -- check success/miss
    if _parry_object.armed then
      if _player_obj.has_just_parried then
        -- right
        _parry_object.delta = frame_number - _parry_object.last_validity_start_frame
        _parry_object.success = true
        _parry_object.armed = false
        _parry_object.last_hit_or_block_frame = 0
        log(_player_obj.prefix, "parry_training_".._parry_object.name, "success")
      elseif _parry_object.last_validity_start_frame == frame_number - 1 and (frame_number - _parry_object.last_hit_or_block_frame) < 20 then
        local _delta = _parry_object.last_hit_or_block_frame - frame_number + 1
        if _parry_object.delta == nil or math.abs(_parry_object.delta) > math.abs(_delta) then
          _parry_object.delta = _delta
          _parry_object.success = false
        end
        log(_player_obj.prefix, "parry_training_".._parry_object.name, "late")
      elseif _player_obj.has_just_blocked or _player_obj.has_just_been_hit then
        local _delta = frame_number - _parry_object.last_validity_start_frame
        if _parry_object.delta == nil or math.abs(_parry_object.delta) > math.abs(_delta) then
          _parry_object.delta = _delta
          _parry_object.success = false
        end
        log(_player_obj.prefix, "parry_training_".._parry_object.name, "early")
      end
    end
    if frame_number - _parry_object.last_validity_start_frame > 30 and _parry_object.armed then

      _parry_object.armed = false
      _parry_object.last_hit_or_block_frame = 0
      log(_player_obj.prefix, "parry_training_".._parry_object.name, "reset")
    end
  end



  read_parry_state(_player_obj.parry_forward, _player_obj.parry_forward_validity_time_addr, _player_obj.parry_forward_cooldown_time_addr)
  read_parry_state(_player_obj.parry_down, _player_obj.parry_down_validity_time_addr, _player_obj.parry_down_cooldown_time_addr)
  read_parry_state(_player_obj.parry_air, _player_obj.parry_air_validity_time_addr, _player_obj.parry_air_cooldown_time_addr)
  read_parry_state(_player_obj.parry_antiair, _player_obj.parry_antiair_validity_time_addr, _player_obj.parry_antiair_cooldown_time_addr)

-- LEGS STATE
  -- global game consts
  _player_obj.legs_state = {}

  _player_obj.legs_state.enabled = _player_obj.char_id == 16 -- chunli
  _player_obj.legs_state.l_legs_count = memory.readbyte(_player_addresses.kyaku_l_count)
  _player_obj.legs_state.m_legs_count = memory.readbyte(_player_addresses.kyaku_m_count)
  _player_obj.legs_state.h_legs_count = memory.readbyte(_player_addresses.kyaku_h_count)
  _player_obj.legs_state.reset_time = memory.readbyte(_player_addresses.kyaku_reset_time)

-- CHARGE STATE
  -- global game consts
  _player_obj.charge_1 = _player_obj.charge_1 or { name = "Charge1", max_charge = 43, max_reset = 43, enabled = false }
  _player_obj.charge_2 = _player_obj.charge_2 or { name = "Charge2", max_charge = 43, max_reset = 43, enabled = false }
  _player_obj.charge_3 = _player_obj.charge_3 or { name = "Charge3", max_charge = 43, max_reset = 43, enabled = false }


  function read_charge_state(_charge_object, _valid_charge, _charge_addr, _reset_addr)
    if _valid_charge == false then
      _charge_object.charge_time = 0
      _charge_object.reset_time = 0
      _charge_object.enabled = false
      return
    end
    _charge_object.overcharge = _charge_object.overcharge or 0
    _charge_object.last_overcharge = _charge_object.last_overcharge or 0
    _charge_object.overcharge_start = _charge_object.overcharge_start or 0
    _charge_object.enabled = true
    local _previous_charge_time = _charge_object.charge_time or 0
    local _previous_reset_time = _charge_object.reset_time or 0
    _charge_object.charge_time = memory.readbyte(_charge_addr)
    _charge_object.reset_time = memory.readbyte(_reset_addr)
    if _charge_object.charge_time == 0xFF then _charge_object.charge_time = 0 else _charge_object.charge_time = _charge_object.charge_time + 1 end
    if _charge_object.reset_time == 0xFF then _charge_object.reset_time = 0 else _charge_object.reset_time = _charge_object.reset_time + 1 end
    if _charge_object.charge_time == 0 then
      if _charge_object.overcharge_start == 0 then
        _charge_object.overcharge_start = frame_number
      else
        _charge_object.overcharge = frame_number - _charge_object.overcharge_start
      end
    end
    if _charge_object.charge_time == _charge_object.max_charge then
      if _charge_object.overcharge ~= 0 then _charge_object.last_overcharge = _charge_object.overcharge end
        _charge_object.overcharge = 0
        _charge_object.overcharge_start = 0
    end -- reset overcharge
  end

  charge_table = {
    ["alex"] = { _charge_1_addr = _player_obj.charge_1_addr, _reset_1_addr = _player_obj.charge_1_reset_addr, _name1 = "charge_slash_elbow", _valid_1 = true,
      _charge_2_addr = _player_obj.charge_2_addr, _reset_2_addr = _player_obj.charge_2_reset_addr, _name2= "charge_air_stampede", _valid_2 = true,
      _charge_3_addr = _player_obj.charge_3_addr, _reset_3_addr = _player_obj.charge_3_reset_addr, _valid_3 = false},
    ["oro"] = { _charge_1_addr = _player_obj.charge_3_addr, _reset_1_addr = _player_obj.charge_3_reset_addr, _name1= "charge_nichirin", _valid_1 = true,
      _charge_2_addr = _player_obj.charge_5_addr, _reset_2_addr = _player_obj.charge_5_reset_addr, _name2= "charge_oniyanma", _valid_2 = true,
      _charge_3_addr = _player_obj.charge_3_addr, _reset_3_addr = _player_obj.charge_3_reset_addr, _valid_3 = false},
    ["urien"] = { _charge_1_addr = _player_obj.charge_5_addr, _reset_1_addr = _player_obj.charge_5_reset_addr, _name1= "charge_chariot_tackle", _valid_1 = true,
      _charge_2_addr = _player_obj.charge_2_addr, _reset_2_addr = _player_obj.charge_2_reset_addr, _name2= "charge_violence_kneedrop", _valid_2 = true,
      _charge_3_addr = _player_obj.charge_4_addr, _reset_3_addr = _player_obj.charge_4_reset_addr, _name3= "charge_dangerous_headbutt", _valid_3 = true},
    ["remy"] = { _charge_1_addr = _player_obj.charge_4_addr, _reset_1_addr = _player_obj.charge_4_reset_addr, _name1= "charge_lov_high", _valid_1 = true,
      _charge_2_addr = _player_obj.charge_3_addr, _reset_2_addr = _player_obj.charge_3_reset_addr, _name2= "charge_lov_low", _valid_2 = true,
      _charge_3_addr = _player_obj.charge_5_addr, _reset_3_addr = _player_obj.charge_5_reset_addr, _name3= "charge_rising_rage_flash", _valid_3 = true},
    ["q"] = { _charge_1_addr = _player_obj.charge_5_addr, _reset_1_addr = _player_obj.charge_5_reset_addr, _name1= "charge_dashing_head_attack", _valid_1 = true,
      _charge_2_addr = _player_obj.charge_4_addr, _reset_2_addr = _player_obj.charge_4_reset_addr, _name2= "charge_dashing_leg_attack", _valid_2 = true,
      _charge_3_addr = _player_obj.charge_3_addr, _reset_3_addr = _player_obj.charge_3_reset_addr, _valid_3 = false},
    ["chunli"] = { _charge_1_addr = _player_obj.charge_5_addr, _reset_1_addr = _player_obj.charge_5_reset_addr, _name1= "charge_spinning_bird_kick", _valid_1 = true,
      _charge_2_addr = _player_obj.charge_2_addr, _reset_2_addr = _player_obj.charge_2_reset_addr, _valid_2 = false,
      _charge_3_addr = _player_obj.charge_3_addr, _reset_3_addr = _player_obj.charge_3_reset_addr, _valid_3 = false}
  }

  if charge_table[_player_obj.char_str] then
    _player_obj.charge_1.name= charge_table[_player_obj.char_str]._name1
    read_charge_state(_player_obj.charge_1, charge_table[_player_obj.char_str]._valid_1, charge_table[_player_obj.char_str]._charge_1_addr, charge_table[_player_obj.char_str]._reset_1_addr)
    if charge_table[_player_obj.char_str]._name2 then _player_obj.charge_2.name= charge_table[_player_obj.char_str]._name2 end
    read_charge_state(_player_obj.charge_2, charge_table[_player_obj.char_str]._valid_2, charge_table[_player_obj.char_str]._charge_2_addr, charge_table[_player_obj.char_str]._reset_2_addr)
    if charge_table[_player_obj.char_str]._name3 then _player_obj.charge_3.name= charge_table[_player_obj.char_str]._name3 end
    read_charge_state(_player_obj.charge_3, charge_table[_player_obj.char_str]._valid_3, charge_table[_player_obj.char_str]._charge_3_addr, charge_table[_player_obj.char_str]._reset_3_addr)
  else
    read_charge_state(_player_obj.charge_1, false, _player_obj.charge_1_addr, _player_obj.charge_1_reset_addr)
    read_charge_state(_player_obj.charge_2, false, _player_obj.charge_1_addr, _player_obj.charge_1_reset_addr)
    read_charge_state(_player_obj.charge_3, false, _player_obj.charge_1_addr, _player_obj.charge_1_reset_addr)
  end

  --360 STATE
  _player_obj.kaiten = _player_obj.kaiten or
    {{name = "kaiten1", directions = {}, validity_time = 0, reset_time = 0, completed_360 = false, previous_completed_360 = false, max_reset = 31, enabled = false},
    {name = "kaiten2", directions = {}, validity_time = 0, reset_time = 0, completed_360 = false, previous_completed_360 = false, max_reset = 31, enabled = false},
    {name = "kaiten3", directions = {}, validity_time = 0, reset_time = 0, completed_360 = false, previous_completed_360 = false, max_reset = 31, enabled = false}}

  function read_kaiten_state(_kaiten_object, _valid_kaiten, _kaiten_addr, _reset_addr, _kaiten_completed_addr, _is_720)
    if _valid_kaiten == false then
      _kaiten_object.directions = {}
      _kaiten_object.validity_time = 0
      _kaiten_object.reset_time = 0
      _kaiten_object.completed_360 = false
      _kaiten_object.previous_completed_360 = false
      _kaiten_object.enabled = false
      return
    end

    _kaiten_object.enabled = true
    local _dir_data = memory.readbyte(_kaiten_addr)

    local _left = bit.band(_dir_data, 8) > 0 --technically forward/back not left/right
    local _right = bit.band(_dir_data, 4) > 0
    local _down = bit.band(_dir_data, 2) > 0
    local _up = bit.band(_dir_data, 1) > 0

    _kaiten_object.completed_360 = memory.readbyte(_kaiten_completed_addr) ~= 48
    local _just_completed_360 = _dir_data == 15
    if _kaiten_object.name == "kaiten_moonsault_press" and not _just_completed_360 then
      if _kaiten_object.completed_360 ~= _kaiten_object.previous_completed_360 then
        _just_completed_360 = true
      end
    end
    if _just_completed_360 then
      _kaiten_object.validity_time = 9
    elseif _kaiten_object.validity_time > 0 then
      _kaiten_object.validity_time = _kaiten_object.validity_time - 1
    end
    if _is_720 then
      if not _kaiten_object.completed_360 then
        if _kaiten_object.validity_time > 0 then
          _kaiten_object.directions = {true, true, true, true, true, true, true, true}
        else
          _kaiten_object.directions = {_down, _left, _right, _up, false, false, false, false}
        end
      else
        _kaiten_object.directions = {true, true, true, true, _down, _left, _right, _up}
      end
    else
      if _kaiten_object.validity_time > 0 then
        _kaiten_object.directions = {true, true, true, true}
      else
        _kaiten_object.directions = {_down, _left, _right, _up}
      end
    end

    _kaiten_object.previous_completed_360 = _kaiten_object.completed_360
    _kaiten_object.reset_time = math.max(memory.readbyte(_reset_addr) - 1, 0)
  end

  kaiten_table = {
    ["alex"] = {
      {kaiten_address = _player_obj.kaiten_1_addr, reset_address = _player_obj.kaiten_1_reset_addr, kaiten_completed_addr = _player_obj.kaiten_completed_360_addr,  name = "kaiten_hyper_bomb", valid = true}
    },
    ["hugo"] = {
      {kaiten_address = _player_obj.kaiten_1_addr, reset_address = _player_obj.kaiten_1_reset_addr, kaiten_completed_addr = _player_obj.kaiten_completed_360_addr,  name= "kaiten_moonsault_press", valid = true},
      {kaiten_address = _player_obj.kaiten_2_addr, reset_address = _player_obj.kaiten_2_reset_addr, kaiten_completed_addr = _player_obj.kaiten_completed_360_addr,  name= "kaiten_meat_squasher", valid = true},
      {kaiten_address = _player_obj.kaiten_1_addr, reset_address = _player_obj.kaiten_1_reset_addr, kaiten_completed_addr = _player_obj.kaiten_completed_360_addr, name= "kaiten_gigas_breaker", valid = true, is_720 = true}
    }
  }


  if kaiten_table[_player_obj.char_str] then
    for i = 1, #_player_obj.kaiten do
      local _kaiten = kaiten_table[_player_obj.char_str][i]
      if _kaiten then
        _player_obj.kaiten[i].name = _kaiten.name
        read_kaiten_state(_player_obj.kaiten[i], _kaiten.valid, _kaiten.kaiten_address, _kaiten.reset_address, _kaiten.kaiten_completed_addr, _kaiten.is_720)
      else
        _player_obj.kaiten[i] = {name = "kaiten" .. tostring(i), enabled = false}
      end
    end
  end


  -- STUN
  _player_obj.stun_max = memory.readbyte(_player_obj.stun_max_addr)
  _player_obj.stun_activate = memory.readbyte(_player_obj.stun_activate_addr)
  _player_obj.stun_timer = memory.readbyte(_player_obj.stun_timer_addr)
  _player_obj.stun_bar_char = memory.readbyte(_player_obj.stun_bar_char_addr)
  _player_obj.stun_bar_mantissa = memory.readbyte(_player_obj.stun_bar_mantissa_addr)
  _player_obj.stun_bar = _player_obj.stun_bar_char + _player_obj.stun_bar_mantissa / 256
  _player_obj.stun_just_began = false
  _player_obj.stun_just_ended = false

  if _player_obj.stun_activate == 1 then
    _player_obj.stunned = true
    if not _player_obj.previous_stunned then
      _player_obj.stun_just_began = true
    end
  elseif _player_obj.stunned then
    if _player_obj.received_connection
    or _player_obj.is_being_thrown
    or _player_obj.stun_timer == 0
    or _player_obj.stun_timer >= 250 then
      _player_obj.stunned = false
      _player_obj.stun_just_ended = true
    end
  end

  _player_obj.previous_stunned = _player_obj.stunned

--   dump state
  function dump_variables()
    dump_state[_player_obj.id] = {
      string.format("%d: %s: Char: %d", frame_number, _player_obj.prefix, _player_obj.char_id),
      string.format("Friends: %d", _player_obj.friends),
      string.format("Flip: %d", _player_obj.flip_x),
      string.format("x, y: %d, %d", _player_obj.pos_x, _player_obj.pos_y),
      string.format("Freeze: %d Super Freeze: %d", _player_obj.remaining_freeze_frames, _player_obj.superfreeze_decount),
      string.format("Input Cap: %d", _player_obj.input_capacity),
      string.format("Action: %d Ext: %d Count: %d", _player_obj.action, _player_obj.action_ext, _player_obj.action_count),
      string.format("Recovery Time: %d Flag %d", _player_obj.recovery_time, _player_obj.recovery_flag),
      string.format("Movement Type: %d Type 2: %d", _player_obj.movement_type, _player_obj.movement_type2),
      string.format("Posture: %d State: %d", _player_obj.posture, _player_obj.character_state_byte),
      string.format("Is Attacking: %d Ext: %d", _player_obj.is_attacking_byte, _player_obj.is_attacking_ext_byte),
      string.format("Is Blocking: %s Busy: %d", tostring(_player_obj.is_blocking), _player_obj.busy_flag),
      string.format("Is in Action: %s Idle: %s", tostring(_player_obj.is_in_basic_action), tostring(_player_obj.is_idle)),
      string.format("Next Hit Dmg: %d Stun: %d", _player_obj.damage_of_next_hit, _player_obj.stun_of_next_hit),
      string.format("Throwing: %s Being Thrown: %s CD: %d", tostring(_player_obj.is_throwing), tostring(_player_obj.is_being_thrown), _player_obj.throw_countdown),
      string.format("Anim: %s Frame %d", tostring(_player_obj.animation), _player_obj.animation_frame),
      string.format("Frame Id: %s  %s  %s", tostring(_player_obj.animation_frame_id), tostring(_player_obj.animation_frame_id2), tostring(_player_obj.animation_frame_id3)),
      string.format("Anim Hash: %s", _player_obj.animation_frame_hash),
      string.format("Recv Hit #: %d Recv Conn #: %d", _player_obj.total_received_hit_count, _player_obj.received_connection_marker),
      string.format("Hit #: %d Conn Hit #: %d", _player_obj.hit_count, _player_obj.connected_action_count),
      string.format("Stand State: %d Stunned: %s Ended: %s", _player_obj.standing_state, tostring(_player_obj.stunned), tostring(_player_obj.stun_just_ended)),
      string.format("Air Recovery: %s Is Flying Down: %s", tostring(_player_obj.is_in_air_recovery), tostring(_player_obj.is_flying_down_flag))}
  end

  dump_variables()

end
dump_state = {}


function read_projectiles()
  local _MAX_OBJECTS = 30
  projectiles = projectiles or {}

  -- flag everything as expired by default, we will reset the flag it we update the projectile
  for _id, _obj in pairs(projectiles) do
    _obj.expired = true
    if _obj.placeholder and _obj.animation_start_frame <= frame_number then
      projectiles[_id] = nil
    end
  end

  -- how we recover hitboxes data for each projectile is taken almost as is from the cps3-hitboxes.lua script
  --object = {initial = 0x02028990, index = 0x02068A96},
  local _index = 0x02068A96
  local _initial = 0x02028990
  local _list = 3
  local _obj_index = memory.readwordsigned(_index + (_list * 2))

  local _obj_slot = 1
  while _obj_slot <= _MAX_OBJECTS and _obj_index ~= -1 do
    local _base = _initial + bit.lshift(_obj_index, 11)
    local _id = string.format("%08X", _base)
    local _obj = projectiles[_id]
    local _is_initialization = false
    if _obj == nil then
       _obj = {base = _base, projectile = _obj_slot}
       _obj.id = _id
       _obj.type = "projectile"
       _obj.is_forced_one_hit = true
       _obj.lifetime = 0
       _obj.start_lifetime = 0
       _obj.remaining_lifetime = 0
       _obj.has_activated = false
       _obj.animation_start_frame = frame_number
       _obj.animation_freeze_frames = 0
       _obj.cooldown = 0
       _obj.alive = true
       _obj.placeholder = false
       _is_initialization = true
    end
    if read_game_object(_obj) and not _obj.placeholder then
      _obj.emitter_id = memory.readbyte(_obj.base + 0x2) + 1
    
      if _is_initialization then
        _obj.initial_flip_x = _obj.flip_x
        _obj.emitter_animation = player_objects[_obj.emitter_id].animation
      else
        _obj.lifetime = _obj.lifetime + 1
      end

      if #_obj.boxes > 0 then
        _obj.has_activated = true
      end

      _obj.expired = false
      _obj.is_converted = _obj.flip_x ~= _obj.initial_flip_x
      _obj.previous_remaining_hits = _obj.remaining_hits or 0
      _obj.remaining_hits = memory.readbyte(_obj.base + 0x9C + 2)
      if _obj.remaining_hits > 0 then
        _obj.is_forced_one_hit = false
      end

      _obj.alive = memory.readbyte(_obj.base + 39) ~= 2

      _obj.previous_remaining_freeze_frames = _obj.remaining_freeze_frames
      _obj.remaining_freeze_frames = memory.readbyte(_obj.base + 0x45)

      _obj.freeze_just_began = false
      if _obj.remaining_freeze_frames > 0 then
        if _obj.previous_remaining_freeze_frames == 0 then
          _obj.freeze_just_began = true
        end
        _obj.animation_freeze_frames = _obj.animation_freeze_frames + 1
      elseif _obj.cooldown > 0 then
        _obj.cooldown = _obj.cooldown - 1
      end

      _obj.remaining_lifetime = memory.readword(_obj.base + 154)

      local _emitter = player_objects[_obj.emitter_id]


      _obj.projectile_type = string.format("%02X", memory.readbyte(_obj.base + 0x91))
      if _obj.projectile_type == "00" then
        if _emitter.char_str == "dudley" then
          _obj.projectile_type = "00_pa_dudley"
        elseif _emitter.char_str == "gouki" then
          _obj.projectile_type = "00_kkz"      
        elseif _emitter.char_str == "oro" then
          _obj.projectile_type = "00_tenguishi"
        elseif _emitter.char_str == "ryu" then
          _obj.projectile_type = "00_hadouken"         
        elseif _emitter.char_str == "sean" then
          _obj.projectile_type = "00_pa_sean"
        elseif _emitter.char_str == "yang" then
          _obj.projectile_type = "00_seieienbu"
        end
      end


      if _is_initialization then

        if _obj.projectile_type == "25" then --debug
          P1_Current_search_adr = _obj.base
        end
        if _obj.projectile_type == "5B" or _obj.projectile_type == "00" then
          memory_view_start = _obj.base
        end
        _obj.projectile_start_type = _obj.projectile_type -- type can change during projectile life (ex: aegis)
        _obj.animation_start_frame = frame_number
        _obj.start_lifetime = _obj.remaining_lifetime
      end


      if _obj.remaining_hits < _obj.previous_remaining_hits then
        local _fdm = frame_data_meta["projectiles"][_obj.projectile_type]
        if _fdm and _fdm.cooldown then
          _obj.cooldown = _fdm.cooldown
        end
          --temporary debug
        if _obj.projectile_type == "25"
        or _obj.projectile_type == "26"
        or _obj.projectile_type == "27"
        or _obj.projectile_type == "28"
        or _obj.projectile_type == "29"
        or _obj.projectile_type == "2A" then
          _obj.next_hit_at_lifetime = _obj.remaining_lifetime - (4 - (_obj.start_lifetime - 1 - _obj.remaining_lifetime) % 4)
        end
      end

      if _obj.next_hit_at_lifetime then
        _obj.cooldown = _obj.remaining_lifetime - _obj.next_hit_at_lifetime
      end
      if _obj.projectile_type == "00_tenguishi" then
        _obj.tengu_state = memory.readbyte(_obj.base + 41)
        if _obj.tengu_state ~= 3 then
          _obj.cooldown = 99
        else
          _obj.cooldown = 0
        end
      end

      _obj.animation_frame = frame_number - _obj.animation_start_frame - _obj.animation_freeze_frames

      projectiles[_obj.id] = _obj

      if frame_data["projectiles"] then
        _obj.animation_frame_data = frame_data["projectiles"][_obj.projectile_type]
      end

      if _obj.animation_frame_data ~= nil and not recording_framedata then
        if _obj.animation_frame_data.frames then
          _obj.animation_frame = math.min(_obj.animation_frame, #_obj.animation_frame_data.frames - 1)
        end
        -- resync animation
        local _frames = _obj.animation_frame_data.frames
        local _current_frame = _frames[_obj.animation_frame + 1]
        if _current_frame then
          local _target_hash = _obj.animation_frame_hash
          local _current_hash = _current_frame.hash
          if _current_hash ~= nil
          and _current_hash ~= _target_hash
          and (_obj.remaining_freeze_frames == 0 or _obj.freeze_just_began)
          then
            local _resync_target, _target_hash = find_resync_target(_obj, _obj.animation_frame_data, _obj.animation_frame_data.infinite_loop)

            if _resync_target ~= -1 then
              -- print(string.format("%d: resynced %s to %s frame(%d -> %d) target %s", frame_number, _current_frame.hash, _obj.animation_frame_data.frames[_resync_target + 1].hash, _obj.animation_frame, _resync_target, _target_hash))
              _obj.animation_frame = _resync_target
              _obj.animation_start_frame = frame_number - _resync_target - _obj.animation_freeze_frames
            end
          end
        end
      end
    end
    -- Get the index to the next object in this list.
    _obj_index = memory.readwordsigned(_obj.base + 0x1C)
    _obj_slot = _obj_slot + 1
  end
end

function remove_expired_projectiles()
  -- if a projectile is still expired, we remove it
  for _id, _obj in pairs(projectiles) do
    if _obj.expired then
      log(player_objects[_obj.emitter_id].prefix, "projectiles", string.format("projectile %s 0", _id))
      projectiles[_id] = nil
    end
  end
end


function update_flip_input(_player, _other_player)
  if _player.flip_input == nil then
    _player.flip_input = _other_player.pos_x >= _player.pos_x
    return
  end

  local _previous_flip_input = _player.flip_input
--   local _flip_hysteresis = 0 -- character_specific[_other_player.char_str].half_width
  local _diff = _other_player.pos_x - _player.pos_x
--   if math.abs(_diff) >= _flip_hysteresis then
    _player.flip_input = _other_player.pos_x >= _player.pos_x
--   end

  if _previous_flip_input ~= _player.flip_input then
    log(_player.prefix, "fight", "flip input")
  end

  if _diff == 0 then
    _player.flip_input = _player.flip_x ~= 0
  end
end


-- ## write
function write_game_vars(_settings)
  -- freeze game
  if _settings.freeze then
    memory.writebyte(0x0201136F, 0xFF)
  else
    memory.writebyte(0x0201136F, 0x00)
  end

  -- timer
  if _settings.infinite_time then
    memory.writebyte(0x02011377, 100)
  end

  -- music
  if _settings.music_volume then
    memory.writebyte(0x02078D06, _settings.music_volume * 8)
  end
end

-- # tools

function is_state_on_ground(_state, _player_obj)
  -- 0x01 is standard standing
  -- 0x02 is standard crouching
  if _state == 0x01 or _state == 0x02 then
    return true
  elseif character_specific[_player_obj.char_str] and character_specific[_player_obj.char_str].additional_standing_states ~= nil then
    for _, _standing_state in ipairs(character_specific[_player_obj.char_str].additional_standing_states) do
      if _standing_state == _state then
        return true
      end
    end
  end
end


-- # initialize player objects
reset_player_objects()
