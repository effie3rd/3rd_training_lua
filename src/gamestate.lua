local fd = require("src/framedata")
local fdm = require("src/framedata_meta")
local debug_settings = require("src/debug_settings")


local frame_data, character_specific = fd.frame_data, fd.character_specific
local get_wakeup_time = fd.get_wakeup_time
local frame_data_meta = fdm.frame_data_meta

local frame_number = 0
local stage = 0
local is_in_match = false
local has_match_just_started = false
local player_objects = {}
local projectiles = {}

local P1 = nil
local P2 = nil

local attacking_byte_exception = {}
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
local function make_input_set(value)
  return {
    up = value,
    down = value,
    left = value,
    right = value,
    LP = value,
    MP = value,
    HP = value,
    LK = value,
    MK = value,
    HK = value,
    start = value,
    coin = value
  }
end

local function make_player_object(id, base, prefix)
  return {
    id = id,
    base = base,
    prefix = prefix,
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
    cooldown = 0
  }
end


local function reset_player_objects()
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

  P2.charge_1_reset_addr = 0x02025FF7  --all of these are incorrect
  P2.charge_1_addr = 0x02025FF9
  P2.charge_2_reset_addr = 0x0202602F
  P2.charge_2_addr = 0x02026031
  P2.charge_3_reset_addr = 0x02026013
  P2.charge_3_addr = 0x02026013
  P2.charge_4_reset_addr = 0x0202604B
  P2.charge_4_addr = 0x0202604D
  P2.charge_5_reset_addr = 0x02026067
  P2.charge_5_addr = 0x02026069        --to here

  P2.kaiten_1_reset_addr = 0x2025F17
  P2.kaiten_1_addr = 0x2025F2F
  P2.kaiten_2_reset_addr = 0x02026013
  P2.kaiten_2_addr = 0x0202600F
  P2.kaiten_completed_360_addr = 0x02025F1F

  for i, debug_vars in ipairs(debug_settings.player_debug_variables) do
    for k, v in pairs(debug_vars) do
      player_objects[i][k] = v
    end
  end
end

local function update_received_hits(self, other)
  if self.received_connection or self.is_being_thrown then
    self.last_received_connection_animation = other.animation
    self.last_received_connection_hit_id = math.max(other.current_hit_id, 1)
  elseif frame_number - self.last_received_connection_frame == 1 then
    for _, proj in pairs(projectiles) do
      if proj.emitter_id == other.id
      and (proj.previous_remaining_hits - proj.remaining_hits == 1
          or proj.previous_remaining_hits - proj.remaining_hits == -255)
      then
        self.last_received_connection_animation = proj.projectile_type
        self.last_received_connection_hit_id = proj.remaining_hits --could use max_hits - remaining if needed
      end
    end
  end
end

local function update_player_relationships(self, other)
  if self.posture == 0x26 and not debug_settings.recording_framedata then
    self.remaining_wakeup_time = get_wakeup_time(self.char_str, self.animation, self.animation_frame)
  else
    self.remaining_wakeup_time = 0
  end
end

local function is_state_on_ground(state, player_obj)
  -- 0x01 is standard standing
  -- 0x02 is standard crouching
  if state == 0x01 or state == 0x02 then
    return true
  elseif character_specific[player_obj.char_str] and character_specific[player_obj.char_str].additional_standing_states ~= nil then
    for _, standing_state in ipairs(character_specific[player_obj.char_str].additional_standing_states) do
      if standing_state == state then
        return true
      end
    end
  end
end

local function read_game_vars()
  -- frame number
  frame_number = memory.readdword(0x02007F00)

  -- is in match
  -- I believe the bytes that are expected to be 0xff means that a character has been locked, while the byte expected to be 0x02 is the current match state. 0x02 means that round has started and players can move
  local p1_locked = memory.readbyte(0x020154C6)
  local p2_locked = memory.readbyte(0x020154C8)
  local match_state = memory.readbyte(0x020154A7)

  local previous_is_in_match = is_in_match

  if previous_is_in_match == nil then previous_is_in_match = true end
  is_in_match = ((p1_locked == 0xFF or p2_locked == 0xFF) and match_state == 0x02)
  has_match_just_started = not previous_is_in_match and is_in_match

  stage = memory.readbyte(addresses.global.stage)
end


local function read_input(player_obj)

  local function read_single_input(input_object, input_name, input)
    input_object.pressed[input_name] = false
    input_object.released[input_name] = false
    if input_object.down[input_name] == false and input then input_object.pressed[input_name] = true end
    if input_object.down[input_name] == true and input == false then input_object.released[input_name] = true end

    if input_object.down[input_name] == input then
      input_object.state_time[input_name] = input_object.state_time[input_name] + 1
    else
      input_object.state_time[input_name] = 0
    end
    input_object.down[input_name] = input
  end

  local local_input = joypad.get()
  read_single_input(player_obj.input, "start", local_input[player_obj.prefix.." Start"])
  read_single_input(player_obj.input, "coin", local_input[player_obj.prefix.." Coin"])
  read_single_input(player_obj.input, "up", local_input[player_obj.prefix.." Up"])
  read_single_input(player_obj.input, "down", local_input[player_obj.prefix.." Down"])
  read_single_input(player_obj.input, "left", local_input[player_obj.prefix.." Left"])
  read_single_input(player_obj.input, "right", local_input[player_obj.prefix.." Right"])
  read_single_input(player_obj.input, "LP", local_input[player_obj.prefix.." Weak Punch"])
  read_single_input(player_obj.input, "MP", local_input[player_obj.prefix.." Medium Punch"])
  read_single_input(player_obj.input, "HP", local_input[player_obj.prefix.." Strong Punch"])
  read_single_input(player_obj.input, "LK", local_input[player_obj.prefix.." Weak Kick"])
  read_single_input(player_obj.input, "MK", local_input[player_obj.prefix.." Medium Kick"])
  read_single_input(player_obj.input, "HK", local_input[player_obj.prefix.." Strong Kick"])
end


local function read_box(obj, ptr, type)
  if obj.friends > 1 then --Yang SA3
    if type ~= "attack" then
      return
    end
  end

  local left   = memory.readwordsigned(ptr + 0x0)
  local width  = memory.readwordsigned(ptr + 0x2)
  local bottom = memory.readwordsigned(ptr + 0x4) --debug
  local height = memory.readwordsigned(ptr + 0x6)

  local box = {convert_box_types[type], bottom, height, left, width}

  if left == 0 and width == 0 and bottom == 0 and height == 0 then
    return
  end

  table.insert(obj.boxes, box)
end

local function read_game_object(obj)
  if memory.readdword(obj.base + 0x2A0) == 0 then --invalid objects
    return false
  end

  obj.friends = memory.readbyte(obj.base + 0x1)
  obj.flip_x = memory.readbytesigned(obj.base + 0x0A) -- sprites are facing left by default
  obj.previous_pos_x = obj.pos_x or 0
  obj.previous_pos_y = obj.pos_y or 0
  obj.pos_x_char = memory.readwordsigned(obj.base + 0x64)
  obj.pos_x_mantissa = memory.readbyte(obj.base + 0x66)
  obj.pos_y_char = memory.readwordsigned(obj.base + 0x68)
  obj.pos_y_mantissa = memory.readbyte(obj.base + 0x6A)
  obj.pos_x = obj.pos_x_char + obj.pos_x_mantissa / 256
  obj.pos_y = obj.pos_y_char + obj.pos_y_mantissa / 256

  obj.velocity_x_char = memory.readwordsigned(obj.base + 0x64 + 24)
  obj.velocity_x_mantissa = memory.readbyte(obj.base + 0x64 + 26)
  obj.velocity_y_char = memory.readwordsigned(obj.base + 0x64 + 28)
  obj.velocity_y_mantissa = memory.readbyte(obj.base + 0x64 + 30)
  obj.acceleration_x_char = memory.readwordsigned(obj.base + 0x64 + 32)
  obj.acceleration_x_mantissa = memory.readbyte(obj.base + 0x64 + 34)
  obj.acceleration_y_char = memory.readwordsigned(obj.base + 0x64 + 36)
  obj.acceleration_y_mantissa = memory.readbyte(obj.base + 0x64 + 38)


  obj.velocity_x = obj.velocity_x_char + obj.velocity_x_mantissa / 256
  obj.velocity_y = obj.velocity_y_char + obj.velocity_y_mantissa / 256
  obj.acceleration_x = obj.acceleration_x_char + obj.acceleration_x_mantissa / 256
  obj.acceleration_y = obj.acceleration_y_char + obj.acceleration_y_mantissa / 256

  obj.char_id = memory.readword(obj.base + 0x3C0)

  obj.boxes = {}
  local boxes = {
    {initial = 1, offset = 0x2D4, type = "push", number = 1},
    {initial = 1, offset = 0x2C0, type = "throwable", number = 1},
    {initial = 1, offset = 0x2A0, type = "vulnerability", number = 4},
    {initial = 1, offset = 0x2A8, type = "ext. vulnerability", number = 4},
    {initial = 1, offset = 0x2C8, type = "attack", number = 4},
    {initial = 1, offset = 0x2B8, type = "throw", number = 1}
  }

  for _, box in ipairs(boxes) do
    for i = box.initial, box.number do
      read_box(obj, memory.readdword(obj.base + box.offset) + (i-1)*8, box.type)
    end
  end

  obj.animation_frame_id = memory.readword(obj.base + 0x21A)
  obj.animation_frame_id2 = memory.readbyte(obj.base + 0x214) --number of frames animation stays on current frame_id
  obj.animation_frame_id3 = memory.readbyte(obj.base + 0x205)

  -- not a unique id for each frame but good enough
  local hash = {string.format("%04x", obj.animation_frame_id),
                 string.format("%02x", obj.animation_frame_id2),
                 string.format("%02x", obj.animation_frame_id3),}

  if obj.id == 1 or obj.id == 2 then
    local action_type = memory.readbyte(obj.base + 0xAD)
    --throw, normal, special/sa
    if action_type == 3 or action_type == 4 or action_type == 5 then
      local action_count = memory.readbyte(obj.base + 0x459)
      table.insert(hash, string.format("%02x", action_count))
    else
      table.insert(hash, "00")
    end
  else
    table.insert(hash, "00")
  end


  obj.animation_frame_hash = table.concat(hash)
  return true
end




local function find_resync_target(obj, fdata, infinite_loop)
  local frames = fdata.frames
  local hash_length = 10
  local target = -1
  if infinite_loop then
    hash_length = 8
  end
  local target_hash = string.sub(obj.animation_frame_hash, 1, hash_length)
  -- print(hash_length, current_hash, target_hash)

  for i = 1, #frames do
    local hash = string.sub(frames[i].hash, 1, hash_length)
    if hash == target_hash then
      return i - 1, target_hash
    end
  end

  --framedata changes on block/hit for many moves
  if fdata.exceptions then
    if fdata.exceptions[target_hash] then
      return fdata.exceptions[target_hash], target_hash
    end
  end

  --hits or blocks will change the frameid2/frameid3 portion of the hash, so we try to get a partial match instead
  local matches = {}
  local scores = {}
  local frameid = string.format("%04x", obj.animation_frame_id)
  for i = 1, #frames do
    if frameid == string.sub(frames[i].hash, 1, 4) then
      table.insert(matches, i)
      table.insert(scores, 0)
    end
  end

  if #matches > 0 then
    local frameid2 = string.format("%02x", obj.animation_frame_id2)
    local frameid3 = string.format("%02x", obj.animation_frame_id3)
    local action_count = "00"
    if obj.type == "player" then
      action_count = string.format("%02x", obj.animation_action_count)
    end
    for i = 1, #matches do
      local index = matches[i]
      local t_frameid2 = string.sub(frames[index].hash, 5, 6)
      local t_frameid3 = string.sub(frames[index].hash, 7, 8)
      local t_action_count = string.sub(frames[index].hash, 9, 10)
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
        if math.abs(index - obj.animation_frame) < math.abs(index2 - obj.animation_frame) then
          key, max = i, v
        end
      end
    end

    return matches[key] - 1, target_hash
  end
  
  return target, target_hash
end


local function read_player_vars(player_obj)

-- P1: 0x02068C6C
-- P2: 0x02069104

  if memory.readdword(player_obj.base + 0x2A0) == 0 then --invalid objects
    return
  end

  local debug_state_variables = player_obj.debug_state_variables

  read_input(player_obj)

  read_game_object(player_obj)

  local previous_movement_type = player_obj.movement_type or 0

  player_obj.char_str = Characters[player_obj.char_id + 1]

  local player_addresses = addresses.players[player_obj.id]

  player_obj.previous_remaining_freeze_frames = player_obj.remaining_freeze_frames or 0
  player_obj.remaining_freeze_frames = memory.readbyte(player_obj.base + 0x45)
  player_obj.freeze_type = 0
  if player_obj.remaining_freeze_frames ~= 0 then
    if player_obj.remaining_freeze_frames < 127 then
      -- inflicted freeze I guess (when the opponent parry you for instance)
      player_obj.freeze_type = 1
      player_obj.remaining_freeze_frames = player_obj.remaining_freeze_frames
    else
      player_obj.freeze_type = 2
      player_obj.remaining_freeze_frames = 256 - player_obj.remaining_freeze_frames
    end
  end
  local remaining_freeze_frame_diff = player_obj.remaining_freeze_frames - player_obj.previous_remaining_freeze_frames
  if remaining_freeze_frame_diff > 0 then
    log(player_obj.prefix, "fight", string.format("freeze %d", player_obj.remaining_freeze_frames))
    --print(string.format("%d: %d(%d)",  player_obj.id, player_obj.remaining_freeze_frames, player_obj.freeze_type))
  end

  local previous_action = player_obj.action or 0x00
  local previous_movement_type2 = player_obj.movement_type2 or 0x00
  local previous_posture = player_obj.posture or 0x00

  player_obj.previous_input_capacity = player_obj.input_capacity or 0
  player_obj.input_capacity = memory.readword(player_obj.base + 0x46C)
  player_obj.action = memory.readdword(player_obj.base + 0xAC)
  player_obj.action_ext = memory.readdword(player_obj.base + 0x12C)
  player_obj.previous_recovery_time = player_obj.recovery_time or 0
  player_obj.recovery_time = memory.readbyte(player_obj.base + 0x187)
  player_obj.movement_type = memory.readbyte(player_obj.base + 0x0AD)
  player_obj.movement_type2 = memory.readbyte(player_obj.base + 0x0AF) -- seems that we can know which basic movement the player is doing from there
  player_obj.total_received_projectiles_count = memory.readword(player_obj.base + 0x430) -- on block or hit

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
  player_obj.posture = memory.readbyte(player_obj.base + 0x20E)

  player_obj.busy_flag = memory.readword(player_obj.base + 0x3D1)

  local previous_is_in_basic_action = player_obj.is_in_basic_action or false
  player_obj.is_in_basic_action = player_obj.action < 0xFF and previous_action < 0xFF -- this triggers one frame early than it should, so we delay it artificially
  player_obj.has_just_entered_basic_action = not previous_is_in_basic_action and player_obj.is_in_basic_action

  local previous_recovery_flag = player_obj.recovery_flag or 1
  player_obj.recovery_flag = memory.readbyte(player_obj.base + 0x3B)
  player_obj.has_just_ended_recovery = previous_recovery_flag ~= 0 and player_obj.recovery_flag == 0

  player_obj.meter_gauge = memory.readbyte(player_obj.gauge_addr)
  player_obj.meter_count = memory.readbyte(player_obj.meter_addr[2])

  player_obj.superfreeze_decount = player_obj.superfreeze_decount or 0
  local previous_superfreeze_decount = player_obj.superfreeze_decount
  if player_obj.id == 1 then
    player_obj.max_meter_gauge = memory.readbyte(0x020695B3)
    player_obj.max_meter_count = memory.readbyte(0x020695BD)
    player_obj.selected_sa = memory.readbyte(0x0201138B) + 1
    player_obj.superfreeze_decount = memory.readbyte(0x02069520) -- seems to be in P2 memory space, don't know why
  else
    player_obj.max_meter_gauge = memory.readbyte(0x020695DF)
    player_obj.max_meter_count = memory.readbyte(0x020695E9)
    player_obj.selected_sa = memory.readbyte(0x0201138C) + 1
    player_obj.superfreeze_decount = memory.readbyte(0x02069088) -- seems to be in P1 memory space, don't know why
  end

  if player_obj.superfreeze_decount == 0 and previous_superfreeze_decount > 0 then
    player_obj.superfreeze_just_ended = true
  else
    player_obj.superfreeze_just_ended = false
  end

  -- CROUCHED
  player_obj.is_crouched = player_obj.posture == 0x20

  -- LIFE
  player_obj.life = memory.readbyte(player_obj.life_addr)

  -- COMBO
  player_obj.previous_combo = player_obj.combo or 0
  if player_obj.id == 1 then
    player_obj.combo = memory.readbyte(0x020696C5)
  else
    player_obj.combo = memory.readbyte(0x0206961D)
  end

  -- NEXT HIT
  player_obj.damage_of_next_hit = memory.readbyte(player_obj.damage_of_next_hit_addr)
  player_obj.stun_of_next_hit = memory.readbyte(player_obj.stun_of_next_hit_addr)

  -- BONUSES
  player_obj.damage_bonus = memory.readword(player_obj.base + 0x43A)
  player_obj.stun_bonus = memory.readword(player_obj.base + 0x43E)
  player_obj.defense_bonus = memory.readword(player_obj.base + 0x440)

  -- THROW
  local previous_is_throwing = player_obj.is_throwing or false
  player_obj.is_throwing = bit.rshift(player_obj.movement_type2, 4) == 9
  player_obj.has_just_thrown = not previous_is_throwing and player_obj.is_throwing

  local _previous_being_thrown = player_obj.is_being_thrown
  player_obj.is_being_thrown = memory.readbyte(player_obj.base + 0x3CF) ~= 0
  player_obj.throw_countdown = player_obj.throw_countdown or 0
  player_obj.previous_throw_countdown = player_obj.throw_countdown
  player_obj.has_just_been_thrown = (not _previous_being_thrown) and player_obj.is_being_thrown

  local throw_countdown = memory.readbyte(player_obj.base + 0x434)
  if throw_countdown > player_obj.previous_throw_countdown then
    player_obj.throw_countdown = throw_countdown + 2 -- air throw animations seems to not match the countdown (ie. Ibuki's Air Throw), let's add a few frames to it
  else
    player_obj.throw_countdown = math.max(player_obj.throw_countdown - 1, 0)
  end

  if player_obj.debug_freeze_frames and player_obj.remaining_freeze_frames > 0 then print(string.format("%d - %d remaining freeze frames", frame_number, player_obj.remaining_freeze_frames)) end



  local previous_animation = player_obj.animation or ""
  player_obj.animation = bit.tohex(memory.readword(player_obj.base + 0x202), 4)



  -- ATTACKING
  local previous_is_attacking = player_obj.is_attacking or false
  player_obj.character_state_byte = memory.readbyte(player_obj.base + 0x27) -- used to detect hugos clap, meat squasher, lariat, which do not set the is_attacking_byte
  player_obj.is_attacking_byte = memory.readbyte(player_obj.base + 0x428)
  player_obj.is_attacking = player_obj.is_attacking_byte > 0
                          or (attacking_byte_exception[player_obj.char_str] and attacking_byte_exception[player_obj.char_str][player_obj.animation])
  player_obj.is_attacking_ext_byte = memory.readbyte(player_obj.base + 0x429)
  player_obj.is_attacking_ext = player_obj.is_attacking_ext_byte > 0
  player_obj.has_just_attacked =  player_obj.is_attacking and not previous_is_attacking
  if debug_state_variables and player_obj.has_just_attacked then print(string.format("%d - %s attacked", frame_number, player_obj.prefix)) end

  -- ACTION
  local previous_action_count = player_obj.action_count or 0
  player_obj.action_count = memory.readbyte(player_obj.base + 0x459)
  player_obj.has_just_acted = player_obj.action_count > previous_action_count
  if debug_state_variables and player_obj.has_just_acted then print(string.format("%d - %s acted (%d > %d)", frame_number, player_obj.prefix, previous_action_count, player_obj.action_count)) end

  player_obj.animation_action_count = player_obj.animation_action_count or 0
  if player_obj.has_just_acted then
    player_obj.animation_action_count = player_obj.animation_action_count + 1
  end

  -- ANIMATION
  player_obj.animation_start_frame = player_obj.animation_start_frame or frame_number
  player_obj.animation_freeze_frames = player_obj.animation_freeze_frames or 0



  player_obj.animation_frame_data = nil
  if frame_data[player_obj.char_str] then
    player_obj.animation_frame_data = frame_data[player_obj.char_str][player_obj.animation]
  end
  player_obj.has_animation_just_changed = previous_animation ~= player_obj.animation
  if debug_state_variables and player_obj.has_animation_just_changed then print(string.format("%d - %s animation changed (%s -> %s)", frame_number, player_obj.prefix, previous_animation, player_obj.animation)) end

  player_obj.animation_frame = frame_number - player_obj.animation_start_frame - player_obj.animation_freeze_frames

  --self chain. cr. lk chains, etc
  if not debug_settings.recording_framedata then ---debug
    if player_obj.self_chain and player_obj.animation_frame_data then
      local hit_frames = player_obj.animation_frame_data.hit_frames
      if hit_frames and #hit_frames > 0 then
        if player_obj.animation_frame > hit_frames[#hit_frames][2] then
          player_obj.has_animation_just_changed = true
        end
      end
    end

    if player_obj.animation_frame_data and not player_obj.has_animation_just_changed
    and player_obj.animation_frame_data.self_chain and player_obj.animation_frame > 0
    and (player_obj.has_just_attacked or (player_obj.previous_input_capacity > 0 and player_obj.input_capacity == 0)) then
      player_obj.self_chain = true --look for self chain next frame
    end
  end

  if player_obj.has_animation_just_changed then
    player_obj.animation_start_frame = frame_number
    player_obj.animation_freeze_frames = 0
    player_obj.next_hit_id = 0

    player_obj.current_hit_id = 0
    player_obj.max_hit_id = 0
    player_obj.current_attack_hits = 0
    player_obj.current_attack_max_hits = 0
    player_obj.animation_action_count = 0
    player_obj.animation_miss_count = 0
    player_obj.animation_connection_count = 0
    player_obj.animation_hash_length = 10
    player_obj.self_chain = false

    player_obj.animation_frame = frame_number - player_obj.animation_start_frame - player_obj.animation_freeze_frames
  end
--[[   if self_chain then
    player_obj.animation_hash_length = 8
  end ]]

    --debug
  -- if not debug_settings.recording_framedata then
    player_obj.animation_frame_hash = string.sub(player_obj.animation_frame_hash, 1, 8)
                                      .. string.format("%02x", player_obj.animation_action_count)
  -- end

--[[   if player_obj.id == 1 then
    print(frame_number, player_obj.previous_input_capacity, player_obj.input_capacity, player_obj.animation_frame, player_obj.is_attacking, tostring(self_cancel))
  end ]]
  if player_obj.animation_frame_data and not debug_settings.recording_framedata then
    --cap animation frame. animation frame will sometimes exceed # of frames in frame data for some long looping animations i.e. air recovery
    player_obj.animation_frame = math.min(player_obj.animation_frame, #player_obj.animation_frame_data.frames - 1)

    player_obj.current_attack_max_hits = player_obj.animation_frame_data.max_hits or 0
  end

  player_obj.freeze_just_began = false
  player_obj.freeze_just_ended = false
  if player_obj.remaining_freeze_frames > 0 then
    if player_obj.previous_remaining_freeze_frames == 0 then
      player_obj.freeze_just_began = true
    end
    if not (player_obj.animation_frame_data and not debug_settings.recording_framedata --debug
            and player_obj.animation_frame_data.frames
            and player_obj.animation_frame_data.frames[player_obj.animation_frame + 1]
            and player_obj.animation_frame_data.frames[player_obj.animation_frame + 1].bypass_freeze) then
      player_obj.animation_freeze_frames = player_obj.animation_freeze_frames + 1
    end
  elseif player_obj.remaining_freeze_frames == 0 and player_obj.previous_remaining_freeze_frames > 0 then
    player_obj.freeze_just_ended = true
  end


  player_obj.pushback_start_frame = player_obj.pushback_start_frame or 0
  player_obj.is_in_pushback = player_obj.is_in_pushback or false
  if player_obj.freeze_just_began
  or player_obj.is_in_pushback and player_obj.recovery_time == 0 then
    player_obj.is_in_pushback = false
  end

  if player_obj.freeze_just_ended and player_obj.movement_type == 1 then
    player_obj.pushback_start_frame = frame_number
    player_obj.is_in_pushback = true
  end

  if player_obj.animation_frame_data ~= nil and not debug_settings.recording_framedata then
    -- resync animation
    local frames = player_obj.animation_frame_data.frames
    local current_frame = frames[player_obj.animation_frame + 1]
    if current_frame then
      -- local target_hash = string.sub(player_obj.animation_frame_hash, 1, player_obj.animation_hash_length)
      -- local current_hash = string.sub(current_frame.hash, 1, player_obj.animation_hash_length)
      local target_hash = player_obj.animation_frame_hash
      local current_hash = current_frame.hash
      if current_hash ~= nil
      and current_hash ~= target_hash
      and (player_obj.remaining_freeze_frames == 0 or player_obj.freeze_just_began)
      then
-- print(player_obj.animation, target_hash, current_hash)
        local resync_target, target_hash = find_resync_target(player_obj, player_obj.animation_frame_data, player_obj.animation_frame_data.infinite_loop)

        if resync_target ~= -1 then

          if resync_target == 0 then
            player_obj.current_hit_id = 0
            player_obj.animation_action_count = 0
            player_obj.animation_connection_count = 0
            player_obj.animation_miss_count = 0
            player_obj.self_chain = false
          end
--[[           if resync_target < player_obj.animation_frame then
            player_obj.current_hit_id = 0

            local hit_frames = player_obj.animation_frame_data.hit_frames
            for i, hit_frame in ipairs(hit_frames) do
              if player_obj.animation_frame > hit_frame[2]
              or (player_obj.animation_frame >= hit_frame[1]
                and player_obj.animation_connection_count >= i) then
                player_obj.current_hit_id = i
              end
            end
            player_obj.animation_action_count = 0
            player_obj.animation_connection_count = 0
          end ]]
          player_obj.animation_frame = resync_target
          player_obj.animation_start_frame = frame_number - resync_target - player_obj.animation_freeze_frames
        end
      end
    end
  end
  if player_obj.has_just_acted then
    player_obj.last_act_animation = player_obj.animation
  end


  -- RECEIVED HITS/BLOCKS/PARRYS
  local previous_total_received_hit_count = player_obj.total_received_hit_count or nil
  player_obj.total_received_hit_count = memory.readword(player_obj.base + 0x33E)
  local total_received_hit_count_diff = 0
  if previous_total_received_hit_count then
    if previous_total_received_hit_count == 0xFFFF then
      total_received_hit_count_diff = 1
    else
      total_received_hit_count_diff = player_obj.total_received_hit_count - previous_total_received_hit_count
    end
  end

  local previous_received_connection_marker = player_obj.received_connection_marker or 0
  player_obj.received_connection_marker = memory.readword(player_obj.base + 0x32E)
  player_obj.received_connection = previous_received_connection_marker == 0 and player_obj.received_connection_marker ~= 0

  player_obj.last_received_connection_frame = player_obj.last_received_connection_frame or 0
  if player_obj.received_connection then
    player_obj.last_received_connection_frame = frame_number
  end

  player_obj.last_movement_type_change_frame = player_obj.last_movement_type_change_frame or 0
  if player_obj.movement_type ~= previous_movement_type then
    player_obj.last_movement_type_change_frame = frame_number
  end

  -- is blocking/has just blocked/has just been hit/has_just_parried
  player_obj.blocking_id = memory.readbyte(player_obj.base + 0x3D3)
  player_obj.has_just_blocked = false
  if player_obj.received_connection and player_obj.received_connection_marker ~= 0xFFF1 and total_received_hit_count_diff == 0 then --0xFFF1 is parry --this is not completely accurate. there are exceptions e.g. kikouken
    player_obj.has_just_blocked = true
    log(player_obj.prefix, "fight", "block")
    if debug_state_variables then
      print(string.format("%d - %s blocked", frame_number, player_obj.prefix))
    end
  end
  player_obj.is_blocking = player_obj.blocking_id > 0 and player_obj.blocking_id < 5 or player_obj.has_just_blocked

  player_obj.has_just_been_hit = false

  if total_received_hit_count_diff > 0 then
    player_obj.has_just_been_hit = true
    log(player_obj.prefix, "fight", "hit")
  end

  player_obj.has_just_parried = false
  if player_obj.received_connection and player_obj.received_connection_marker == 0xFFF1 and total_received_hit_count_diff == 0 then
    player_obj.has_just_parried = true
    log(player_obj.prefix, "fight", "parry")
    if debug_state_variables then print(string.format("%d - %s parried", frame_number, player_obj.prefix)) end
  end

  -- HITS
  local previous_hit_count = player_obj.hit_count or 0
  player_obj.hit_count = memory.readbyte(player_obj.base + 0x189)
  player_obj.has_just_hit = player_obj.hit_count > previous_hit_count
  if player_obj.has_just_hit then
    log(player_obj.prefix, "fight", "has hit")
    if debug_state_variables then
      print(string.format("%d - %s hit (%d > %d)", frame_number, player_obj.prefix, previous_hit_count, player_obj.hit_count))
    end
  end

  -- BLOCKS
  local previous_connected_action_count = player_obj.connected_action_count or 0
  local previous_blocked_count = previous_connected_action_count - previous_hit_count
  player_obj.connected_action_count = memory.readbyte(player_obj.base + 0x17B)
  local blocked_count = player_obj.connected_action_count - player_obj.hit_count
  player_obj.has_just_been_blocked = blocked_count > previous_blocked_count
  if debug_state_variables and player_obj.has_just_been_blocked then print(string.format("%d - %s blocked (%d > %d)", frame_number, player_obj.prefix, previous_blocked_count, blocked_count)) end
  
  player_obj.just_connected = player_obj.just_connected or false
  if player_obj.connected_action_count > previous_connected_action_count then
    player_obj.just_connected =  true
    player_obj.animation_connection_count = player_obj.animation_connection_count + 1
  end
  --for turning off hitboxes on hit like necro's drills
  player_obj.cooldown = math.max(player_obj.cooldown - 1, 0)

  --update hit id
  if player_obj.animation_frame_data then
    local hit_frames = player_obj.animation_frame_data.hit_frames
    if hit_frames then
      player_obj.max_hit_id = #hit_frames
  --[[     for i, hit_frame in ipairs(hit_frames) do
        if player_obj.animation_frame > hit_frame[2]
        or (player_obj.animation_frame >= hit_frame[1]
          and player_obj.animation_connection_count >= i) then

          --make exceptions for infinite looping moves and yang tc
          player_obj.current_hit_id = i
        end
      end ]]

      for i, hit_frame in ipairs(hit_frames) do
        if i > player_obj.current_hit_id then
          if player_obj.animation_frame > hit_frame[2] then
            player_obj.animation_miss_count = player_obj.animation_miss_count + 1
            player_obj.current_hit_id = i
          elseif (player_obj.animation_frame >= hit_frame[1]
          and player_obj.animation_connection_count + player_obj.animation_miss_count >= i) then
            player_obj.current_hit_id = i
          end
        end
      end

      if player_obj.just_connected then
        --if infinite loop
        player_obj.current_attack_hits = player_obj.current_attack_hits + 1

        if player_obj.animation_frame_data and player_obj.animation_frame_data.cooldown then
          player_obj.cooldown = player_obj.animation_frame_data.cooldown
        end
      end
    end
  end

  -- LANDING
  local previous_is_in_jump_startup = player_obj.is_in_jump_startup or false
  player_obj.is_in_jump_startup = player_obj.movement_type2 == 0x0C and player_obj.movement_type == 0x00 and not player_obj.is_blocking
  player_obj.previous_standing_state = player_obj.standing_state or 0
  player_obj.standing_state = memory.readbyte(player_obj.base + 0x297)
  player_obj.has_just_landed = is_state_on_ground(player_obj.standing_state, player_obj) and not is_state_on_ground(player_obj.previous_standing_state, player_obj)
  if debug_state_variables and player_obj.has_just_landed then print(string.format("%d - %s landed (%d > %d)", frame_number, player_obj.prefix, player_obj.previous_standing_state, player_obj.standing_state)) end
  if player_obj.debug_standing_state and player_obj.previous_standing_state ~= player_obj.standing_state then print(string.format("%d - %s standing state changed (%d > %d)", frame_number, player_obj.prefix, player_obj.previous_standing_state, player_obj.standing_state)) end

  -- AIR RECOVERY STATE
  local debug_air_recovery = false
  local previous_is_in_air_recovery = player_obj.is_in_air_recovery or false
  local r1 = memory.readbyte(player_obj.base + 0x12F)
  local r2 = memory.readbyte(player_obj.base + 0x3C7)
  player_obj.is_in_air_recovery = player_obj.standing_state == 0 and r1 == 0 and r2 == 0x06 and player_obj.pos_y ~= 0
  player_obj.has_just_entered_air_recovery = not previous_is_in_air_recovery and player_obj.is_in_air_recovery

  if not previous_is_in_air_recovery and player_obj.is_in_air_recovery then
    log(player_obj.prefix, "fight", string.format("air recovery 1"))
    if debug_air_recovery then
      print(string.format("%s entered air recovery", player_obj.prefix))
    end
  end
  if previous_is_in_air_recovery and not player_obj.is_in_air_recovery then
    log(player_obj.prefix, "fight", string.format("air recovery 0"))
    if debug_air_recovery then
      print(string.format("%s exited air recovery", player_obj.prefix))
    end
  end



  -- IS IDLE
  local previous_is_idle = player_obj.is_idle or false
  player_obj.idle_time = player_obj.idle_time or 0
  player_obj.is_idle = (
    not player_obj.is_attacking and
--     not player_obj.is_attacking_ext and --this seems to be set during some target combos. this value is never reset to 0 on some of elena's target combos'
    not player_obj.is_blocking and
    not player_obj.is_wakingup and
    not player_obj.is_fast_wakingup and
    not player_obj.is_being_thrown and
    not player_obj.is_in_jump_startup and
    bit.band(player_obj.busy_flag, 0xFF) == 0 and
    player_obj.recovery_time == player_obj.previous_recovery_time and
    player_obj.remaining_freeze_frames == 0 and
    player_obj.input_capacity > 0
  )

  player_obj.just_recovered = player_obj.previous_recovery_time > 0 and player_obj.recovery_time == 0
  --[[
  if player_obj.id == 1 then
    print(string.format(
      "%d: %d, %d, %d, %d, %d, %d, %d, %04x, %d, %d, %04x",
      to_bit(player_obj.is_idle),
      to_bit(player_obj.is_attacking),
      to_bit(player_obj.is_attacking_ext),
      to_bit(player_obj.is_blocking),
      to_bit(player_obj.is_wakingup),
      to_bit(player_obj.is_fast_wakingup),
      to_bit(player_obj.is_being_thrown),
      to_bit(player_obj.is_in_jump_startup),
      player_obj.busy_flag,
      player_obj.recovery_time,
      player_obj.remaining_freeze_frames,
      player_obj.input_capacity
    ))
  end
  ]]

  if player_obj.is_idle then
    player_obj.idle_time = player_obj.idle_time + 1
  else
    player_obj.idle_time = 0
  end

  if previous_is_idle ~= player_obj.is_idle then
    log(player_obj.prefix, "fight", string.format("idle %d", to_bit(player_obj.is_idle)))
  end


  if is_in_match then

    -- WAKE UP
    player_obj.previous_can_fast_wakeup = player_obj.can_fast_wakeup or 0
    player_obj.can_fast_wakeup = memory.readbyte(player_obj.base + 0x402)

    local previous_fast_wakeup_flag = player_obj.fast_wakeup_flag or 0
    player_obj.fast_wakeup_flag = memory.readbyte(player_obj.base + 0x403)

    local previous_is_flying_down_flag = player_obj.is_flying_down_flag or 0
    player_obj.is_flying_down_flag = memory.readbyte(player_obj.base + 0x8D) -- does not reset to 0 after air reset landings, resets to 0 after jump start

    player_obj.previous_is_wakingup = player_obj.is_wakingup or false
    player_obj.is_wakingup = player_obj.is_wakingup or false
    player_obj.wakeup_time = player_obj.wakeup_time or 0
--[[     if previous_is_flying_down_flag == 1 and player_obj.is_flying_down_flag == 0 and player_obj.standing_state == 0 and
      (
        player_obj.movement_type ~= 2 -- movement type 2 is hugo's running grab
        and player_obj.movement_type ~= 5 -- movement type 5 is ryu's reversal DP on landing
      ) then ]]
    if previous_posture ~= 0x26 and player_obj.posture == 0x26 then
      player_obj.is_wakingup = true
      player_obj.is_past_wakeup_frame = false
      player_obj.wakeup_time = 0
      player_obj.wakeup_animation = player_obj.animation
    end

    player_obj.previous_is_fast_wakingup = player_obj.is_fast_wakingup or false
    player_obj.is_fast_wakingup = player_obj.is_fast_wakingup or false
    if player_obj.is_wakingup and previous_fast_wakeup_flag == 1 and player_obj.fast_wakeup_flag == 0 then
      player_obj.is_fast_wakingup = true
      player_obj.is_past_wakeup_frame = true
      player_obj.wakeup_time = 0
      player_obj.wakeup_animation = player_obj.animation
    end

    if player_obj.previous_can_fast_wakeup ~= 0 and player_obj.can_fast_wakeup == 0 then
      player_obj.is_past_wakeup_frame = true
    end

    if player_obj.is_wakingup then
      player_obj.wakeup_time = player_obj.wakeup_time + 1
    end

    if player_obj.is_wakingup and previous_posture == 0x26 and player_obj.posture ~= 0x26 then
      player_obj.is_wakingup = false
      player_obj.is_fast_wakingup = false
      player_obj.is_past_wakeup_frame = false
    end

    player_obj.has_just_started_wake_up = not player_obj.previous_is_wakingup and player_obj.is_wakingup
    player_obj.has_just_started_fast_wake_up = not player_obj.previous_is_fast_wakingup and player_obj.is_fast_wakingup
    player_obj.has_just_woke_up = player_obj.previous_is_wakingup and not player_obj.is_wakingup

    if player_obj.has_just_started_wake_up then
      log(player_obj.prefix, "fight", string.format("wakeup 1"))
    end
    if player_obj.has_just_started_fast_wake_up then
      log(player_obj.prefix, "fight", string.format("fwakeup 1"))
    end
    if player_obj.has_just_woke_up then
      log(player_obj.prefix, "fight", string.format("wakeup 0"))
    end
  end

  if not previous_is_in_jump_startup and player_obj.is_in_jump_startup then
    player_obj.last_jump_startup_duration = 0
    player_obj.last_jump_startup_frame = frame_number
  end

  if player_obj.is_in_jump_startup then
    player_obj.last_jump_startup_duration = player_obj.last_jump_startup_duration + 1
  end

  -- TIMED SA
  if character_specific[player_obj.char_str].timed_sa[player_obj.selected_sa] then
    if player_obj.superfreeze_decount > 0 then
      player_obj.is_in_timed_sa = true
    elseif player_obj.is_in_timed_sa and memory.readbyte(player_obj.gauge_addr) == 0 then
      player_obj.is_in_timed_sa = false
    end
  else
    player_obj.is_in_timed_sa = false
  end

  -- PARRY BUFFERS
  -- global game consts
  player_obj.parry_forward = player_obj.parry_forward or { name = "forward", max_validity = 10, max_cooldown = 23 }
  player_obj.parry_down = player_obj.parry_down or { name = "down", max_validity = 10, max_cooldown = 23 }
  player_obj.parry_air = player_obj.parry_air or { name = "air", max_validity = 7, max_cooldown = 20 }
  player_obj.parry_antiair = player_obj.parry_antiair or { name = "anti_air", max_validity = 5, max_cooldown = 18 }

  local function read_parry_state(parry_object, validity_addr, cooldown_addr)
    -- read data
    parry_object.last_hit_or_block_frame =  parry_object.last_hit_or_block_frame or 0
    if player_obj.has_just_blocked or player_obj.has_just_been_hit then
      parry_object.last_hit_or_block_frame = frame_number
    end
    parry_object.last_validity_start_frame = parry_object.last_validity_start_frame or 0
    parry_object.previous_validity_time = parry_object.validity_time or 0
    parry_object.validity_time = memory.readbyte(validity_addr)
    parry_object.cooldown_time = memory.readbyte(cooldown_addr)
    if parry_object.cooldown_time == 0xFF then parry_object.cooldown_time = 0 end
    if parry_object.previous_validity_time == 0 and parry_object.validity_time ~= 0 then
      parry_object.last_validity_start_frame = frame_number
      parry_object.delta = nil
      parry_object.success = nil
      parry_object.armed = true
      log(player_obj.prefix, "parry_training_"..parry_object.name, "armed")
    end

    -- check success/miss
    if parry_object.armed then
      if player_obj.has_just_parried then
        -- right
        parry_object.delta = frame_number - parry_object.last_validity_start_frame
        parry_object.success = true
        parry_object.armed = false
        parry_object.last_hit_or_block_frame = 0
        log(player_obj.prefix, "parry_training_"..parry_object.name, "success")
      elseif parry_object.last_validity_start_frame == frame_number - 1 and (frame_number - parry_object.last_hit_or_block_frame) < 20 then
        local delta = parry_object.last_hit_or_block_frame - frame_number + 1
        if parry_object.delta == nil or math.abs(parry_object.delta) > math.abs(delta) then
          parry_object.delta = delta
          parry_object.success = false
        end
        log(player_obj.prefix, "parry_training_"..parry_object.name, "late")
      elseif player_obj.has_just_blocked or player_obj.has_just_been_hit then
        local delta = frame_number - parry_object.last_validity_start_frame
        if parry_object.delta == nil or math.abs(parry_object.delta) > math.abs(delta) then
          parry_object.delta = delta
          parry_object.success = false
        end
        log(player_obj.prefix, "parry_training_"..parry_object.name, "early")
      end
    end
    if frame_number - parry_object.last_validity_start_frame > 30 and parry_object.armed then

      parry_object.armed = false
      parry_object.last_hit_or_block_frame = 0
      log(player_obj.prefix, "parry_training_"..parry_object.name, "reset")
    end
  end



  read_parry_state(player_obj.parry_forward, player_obj.parry_forward_validity_time_addr, player_obj.parry_forward_cooldown_time_addr)
  read_parry_state(player_obj.parry_down, player_obj.parry_down_validity_time_addr, player_obj.parry_down_cooldown_time_addr)
  read_parry_state(player_obj.parry_air, player_obj.parry_air_validity_time_addr, player_obj.parry_air_cooldown_time_addr)
  read_parry_state(player_obj.parry_antiair, player_obj.parry_antiair_validity_time_addr, player_obj.parry_antiair_cooldown_time_addr)

-- LEGS STATE
  -- global game consts
  player_obj.legs_state = {}

  player_obj.legs_state.enabled = player_obj.char_id == 16 -- chunli
  player_obj.legs_state.l_legs_count = memory.readbyte(player_addresses.kyaku_l_count)
  player_obj.legs_state.m_legs_count = memory.readbyte(player_addresses.kyaku_m_count)
  player_obj.legs_state.h_legs_count = memory.readbyte(player_addresses.kyaku_h_count)
  player_obj.legs_state.reset_time = memory.readbyte(player_addresses.kyaku_reset_time)

-- CHARGE STATE
  -- global game consts
  player_obj.charge_1 = player_obj.charge_1 or { name = "Charge1", max_charge = 43, max_reset = 43, enabled = false }
  player_obj.charge_2 = player_obj.charge_2 or { name = "Charge2", max_charge = 43, max_reset = 43, enabled = false }
  player_obj.charge_3 = player_obj.charge_3 or { name = "Charge3", max_charge = 43, max_reset = 43, enabled = false }


  local function read_charge_state(charge_object, valid_charge, charge_addr, reset_addr)
    if valid_charge == false then
      charge_object.charge_time = 0
      charge_object.reset_time = 0
      charge_object.enabled = false
      return
    end
    charge_object.overcharge = charge_object.overcharge or 0
    charge_object.last_overcharge = charge_object.last_overcharge or 0
    charge_object.overcharge_start = charge_object.overcharge_start or 0
    charge_object.enabled = true
    local previous_charge_time = charge_object.charge_time or 0
    local previous_reset_time = charge_object.reset_time or 0
    charge_object.charge_time = memory.readbyte(charge_addr)
    charge_object.reset_time = memory.readbyte(reset_addr)
    if charge_object.charge_time == 0xFF then charge_object.charge_time = 0 else charge_object.charge_time = charge_object.charge_time + 1 end
    if charge_object.reset_time == 0xFF then charge_object.reset_time = 0 else charge_object.reset_time = charge_object.reset_time + 1 end
    if charge_object.charge_time == 0 then
      if charge_object.overcharge_start == 0 then
        charge_object.overcharge_start = frame_number
      else
        charge_object.overcharge = frame_number - charge_object.overcharge_start
      end
    end
    if charge_object.charge_time == charge_object.max_charge then
      if charge_object.overcharge ~= 0 then charge_object.last_overcharge = charge_object.overcharge end
        charge_object.overcharge = 0
        charge_object.overcharge_start = 0
    end -- reset overcharge
  end

  local charge_table = {
    ["alex"] = { charge_1_addr = player_obj.charge_1_addr, reset_1_addr = player_obj.charge_1_reset_addr, name1 = "charge_slash_elbow", valid_1 = true,
      charge_2_addr = player_obj.charge_2_addr, reset_2_addr = player_obj.charge_2_reset_addr, name2= "charge_air_stampede", valid_2 = true,
      charge_3_addr = player_obj.charge_3_addr, reset_3_addr = player_obj.charge_3_reset_addr, valid_3 = false},
    ["oro"] = { charge_1_addr = player_obj.charge_3_addr, reset_1_addr = player_obj.charge_3_reset_addr, name1= "charge_nichirin", valid_1 = true,
      charge_2_addr = player_obj.charge_5_addr, reset_2_addr = player_obj.charge_5_reset_addr, name2= "charge_oniyanma", valid_2 = true,
      charge_3_addr = player_obj.charge_3_addr, reset_3_addr = player_obj.charge_3_reset_addr, valid_3 = false},
    ["urien"] = { charge_1_addr = player_obj.charge_5_addr, reset_1_addr = player_obj.charge_5_reset_addr, name1= "charge_chariot_tackle", valid_1 = true,
      charge_2_addr = player_obj.charge_2_addr, reset_2_addr = player_obj.charge_2_reset_addr, name2= "charge_violence_kneedrop", valid_2 = true,
      charge_3_addr = player_obj.charge_4_addr, reset_3_addr = player_obj.charge_4_reset_addr, name3= "charge_dangerous_headbutt", valid_3 = true},
    ["remy"] = { charge_1_addr = player_obj.charge_4_addr, reset_1_addr = player_obj.charge_4_reset_addr, name1= "charge_lov_high", valid_1 = true,
      charge_2_addr = player_obj.charge_3_addr, reset_2_addr = player_obj.charge_3_reset_addr, name2= "charge_lov_low", valid_2 = true,
      charge_3_addr = player_obj.charge_5_addr, reset_3_addr = player_obj.charge_5_reset_addr, name3= "charge_rising_rage_flash", valid_3 = true},
    ["q"] = { charge_1_addr = player_obj.charge_5_addr, reset_1_addr = player_obj.charge_5_reset_addr, name1= "charge_dashing_head_attack", valid_1 = true,
      charge_2_addr = player_obj.charge_4_addr, reset_2_addr = player_obj.charge_4_reset_addr, name2= "charge_dashing_leg_attack", valid_2 = true,
      charge_3_addr = player_obj.charge_3_addr, reset_3_addr = player_obj.charge_3_reset_addr, valid_3 = false},
    ["chunli"] = { charge_1_addr = player_obj.charge_5_addr, reset_1_addr = player_obj.charge_5_reset_addr, name1= "charge_spinning_bird_kick", valid_1 = true,
      charge_2_addr = player_obj.charge_2_addr, reset_2_addr = player_obj.charge_2_reset_addr, valid_2 = false,
      charge_3_addr = player_obj.charge_3_addr, reset_3_addr = player_obj.charge_3_reset_addr, valid_3 = false}
  }

  if charge_table[player_obj.char_str] then
    player_obj.charge_1.name= charge_table[player_obj.char_str].name1
    read_charge_state(player_obj.charge_1, charge_table[player_obj.char_str].valid_1, charge_table[player_obj.char_str].charge_1_addr, charge_table[player_obj.char_str].reset_1_addr)
    if charge_table[player_obj.char_str].name2 then player_obj.charge_2.name= charge_table[player_obj.char_str].name2 end
    read_charge_state(player_obj.charge_2, charge_table[player_obj.char_str].valid_2, charge_table[player_obj.char_str].charge_2_addr, charge_table[player_obj.char_str].reset_2_addr)
    if charge_table[player_obj.char_str].name3 then player_obj.charge_3.name= charge_table[player_obj.char_str].name3 end
    read_charge_state(player_obj.charge_3, charge_table[player_obj.char_str].valid_3, charge_table[player_obj.char_str].charge_3_addr, charge_table[player_obj.char_str].reset_3_addr)
  else
    read_charge_state(player_obj.charge_1, false, player_obj.charge_1_addr, player_obj.charge_1_reset_addr)
    read_charge_state(player_obj.charge_2, false, player_obj.charge_1_addr, player_obj.charge_1_reset_addr)
    read_charge_state(player_obj.charge_3, false, player_obj.charge_1_addr, player_obj.charge_1_reset_addr)
  end

  --360 STATE
  player_obj.kaiten = player_obj.kaiten or
    {{name = "kaiten1", directions = {}, validity_time = 0, reset_time = 0, completed_360 = false, previous_completed_360 = false, max_reset = 31, enabled = false},
    {name = "kaiten2", directions = {}, validity_time = 0, reset_time = 0, completed_360 = false, previous_completed_360 = false, max_reset = 31, enabled = false},
    {name = "kaiten3", directions = {}, validity_time = 0, reset_time = 0, completed_360 = false, previous_completed_360 = false, max_reset = 31, enabled = false}}

  local function read_kaiten_state(kaiten_object, valid_kaiten, kaiten_addr, reset_addr, kaiten_completed_addr, is_720)
    if valid_kaiten == false then
      kaiten_object.directions = {}
      kaiten_object.validity_time = 0
      kaiten_object.reset_time = 0
      kaiten_object.completed_360 = false
      kaiten_object.previous_completed_360 = false
      kaiten_object.enabled = false
      return
    end

    kaiten_object.enabled = true
    local dir_data = memory.readbyte(kaiten_addr)

    local left = bit.band(dir_data, 8) > 0 --technically forward/back not left/right
    local right = bit.band(dir_data, 4) > 0
    local down = bit.band(dir_data, 2) > 0
    local up = bit.band(dir_data, 1) > 0

    kaiten_object.completed_360 = memory.readbyte(kaiten_completed_addr) ~= 48
    local just_completed_360 = dir_data == 15
    if kaiten_object.name == "kaiten_moonsault_press" and not just_completed_360 then
      if kaiten_object.completed_360 ~= kaiten_object.previous_completed_360 then
        just_completed_360 = true
      end
    end
    if just_completed_360 then
      kaiten_object.validity_time = 9
    elseif kaiten_object.validity_time > 0 then
      kaiten_object.validity_time = kaiten_object.validity_time - 1
    end
    if is_720 then
      if not kaiten_object.completed_360 then
        if kaiten_object.validity_time > 0 then
          kaiten_object.directions = {true, true, true, true, true, true, true, true}
        else
          kaiten_object.directions = {down, left, right, up, false, false, false, false}
        end
      else
        kaiten_object.directions = {true, true, true, true, down, left, right, up}
      end
    else
      if kaiten_object.validity_time > 0 then
        kaiten_object.directions = {true, true, true, true}
      else
        kaiten_object.directions = {down, left, right, up}
      end
    end

    kaiten_object.previous_completed_360 = kaiten_object.completed_360
    kaiten_object.reset_time = math.max(memory.readbyte(reset_addr) - 1, 0)
  end

  local kaiten_table = {
    ["alex"] = {
      {kaiten_address = player_obj.kaiten_1_addr, reset_address = player_obj.kaiten_1_reset_addr, kaiten_completed_addr = player_obj.kaiten_completed_360_addr,  name = "kaiten_hyper_bomb", valid = true}
    },
    ["hugo"] = {
      {kaiten_address = player_obj.kaiten_1_addr, reset_address = player_obj.kaiten_1_reset_addr, kaiten_completed_addr = player_obj.kaiten_completed_360_addr,  name= "kaiten_moonsault_press", valid = true},
      {kaiten_address = player_obj.kaiten_2_addr, reset_address = player_obj.kaiten_2_reset_addr, kaiten_completed_addr = player_obj.kaiten_completed_360_addr,  name= "kaiten_meat_squasher", valid = true},
      {kaiten_address = player_obj.kaiten_1_addr, reset_address = player_obj.kaiten_1_reset_addr, kaiten_completed_addr = player_obj.kaiten_completed_360_addr, name= "kaiten_gigas_breaker", valid = true, is_720 = true}
    }
  }


  if kaiten_table[player_obj.char_str] then
    for i = 1, #player_obj.kaiten do
      local kaiten = kaiten_table[player_obj.char_str][i]
      if kaiten then
        player_obj.kaiten[i].name = kaiten.name
        read_kaiten_state(player_obj.kaiten[i], kaiten.valid, kaiten.kaiten_address, kaiten.reset_address, kaiten.kaiten_completed_addr, kaiten.is_720)
      else
        player_obj.kaiten[i] = {name = "kaiten" .. tostring(i), enabled = false}
      end
    end
  end


  -- STUN
  player_obj.stun_max = memory.readbyte(player_obj.stun_max_addr)
  player_obj.stun_activate = memory.readbyte(player_obj.stun_activate_addr)
  player_obj.stun_timer = memory.readbyte(player_obj.stun_timer_addr)
  player_obj.stun_bar_char = memory.readbyte(player_obj.stun_bar_char_addr)
  player_obj.stun_bar_mantissa = memory.readbyte(player_obj.stun_bar_mantissa_addr)
  player_obj.stun_bar = player_obj.stun_bar_char + player_obj.stun_bar_mantissa / 256
  player_obj.stun_just_began = false
  player_obj.stun_just_ended = false

  if player_obj.stun_activate == 1 then
    player_obj.stunned = true
    if not player_obj.previous_stunned then
      player_obj.stun_just_began = true
    end
  elseif player_obj.stunned then
    if player_obj.received_connection
    or player_obj.is_being_thrown
    or player_obj.stun_timer == 0
    or player_obj.stun_timer >= 250 then
      player_obj.stunned = false
      player_obj.stun_just_ended = true
    end
  end

  player_obj.previous_stunned = player_obj.stunned

--   dump state


end


local function read_projectiles()
  local mAX_OBJECTS = 30
  projectiles = projectiles or {}

  -- flag everything as expired by default, we will reset the flag it we update the projectile
  for id, obj in pairs(projectiles) do
    obj.expired = true
    if obj.placeholder and obj.animation_start_frame <= frame_number then
      projectiles[id] = nil
    end
  end

  -- how we recover hitboxes data for each projectile is taken almost as is from the cps3-hitboxes.lua script
  --object = {initial = 0x02028990, index = 0x02068A96},
  local index = 0x02068A96
  local initial = 0x02028990
  local list = 3
  local obj_index = memory.readwordsigned(index + (list * 2))

  local obj_slot = 1
  while obj_slot <= mAX_OBJECTS and obj_index ~= -1 do
    local base = initial + bit.lshift(obj_index, 11)
    local id = string.format("%08X", base)
    local obj = projectiles[id]
    local is_initialization = false
    if obj == nil then
       obj = {base = base, projectile = obj_slot}
       obj.id = id
       obj.type = "projectile"
       obj.is_forced_one_hit = true
       obj.lifetime = 0
       obj.start_lifetime = 0
       obj.remaining_lifetime = 0
       obj.has_activated = false
       obj.animation_start_frame = frame_number
       obj.animation_freeze_frames = 0
       obj.cooldown = 0
       obj.alive = true
       obj.placeholder = false
       is_initialization = true
    end
    if read_game_object(obj) and not obj.placeholder then
      obj.emitter_id = memory.readbyte(obj.base + 0x2) + 1
    
      if is_initialization then
        obj.initial_flip_x = obj.flip_x
        obj.emitter_animation = player_objects[obj.emitter_id].animation
      else
        obj.lifetime = obj.lifetime + 1
      end

      if #obj.boxes > 0 then
        obj.has_activated = true
      end

      obj.expired = false
      obj.is_converted = obj.flip_x ~= obj.initial_flip_x
      obj.previous_remaining_hits = obj.remaining_hits or 0
      obj.remaining_hits = memory.readbyte(obj.base + 0x9C + 2)
      if obj.remaining_hits > 0 then
        obj.is_forced_one_hit = false
      end

      obj.alive = memory.readbyte(obj.base + 39) ~= 2

      obj.previous_remaining_freeze_frames = obj.remaining_freeze_frames
      obj.remaining_freeze_frames = memory.readbyte(obj.base + 0x45)

      obj.freeze_just_began = false
      if obj.remaining_freeze_frames > 0 then
        if obj.previous_remaining_freeze_frames == 0 then
          obj.freeze_just_began = true
        end
        obj.animation_freeze_frames = obj.animation_freeze_frames + 1
      elseif obj.cooldown > 0 then
        obj.cooldown = obj.cooldown - 1
      end

      obj.remaining_lifetime = memory.readword(obj.base + 154)

      local emitter = player_objects[obj.emitter_id]


      obj.projectile_type = string.format("%02X", memory.readbyte(obj.base + 0x91))
      if obj.projectile_type == "00" then
        if emitter.char_str == "dudley" then
          obj.projectile_type = "00_pa_dudley"
        elseif emitter.char_str == "gouki" then
          obj.projectile_type = "00_kkz"      
        elseif emitter.char_str == "oro" then
          obj.projectile_type = "00_tenguishi"
        elseif emitter.char_str == "ryu" then
          obj.projectile_type = "00_hadouken"         
        elseif emitter.char_str == "sean" then
          obj.projectile_type = "00_pa_sean"
        elseif emitter.char_str == "yang" then
          obj.projectile_type = "00_seieienbu"
        end
      end


      if is_initialization then

        if obj.projectile_type == "25" then --debug
          P1_Current_search_adr = obj.base
        end
        if obj.projectile_type == "5B" or obj.projectile_type == "00" then
          debug.memory_view_start = obj.base
        end
        obj.projectile_start_type = obj.projectile_type -- type can change during projectile life (ex: aegis)
        obj.animation_start_frame = frame_number
        obj.start_lifetime = obj.remaining_lifetime
      end


      if obj.remaining_hits < obj.previous_remaining_hits then
        local fdm = frame_data_meta["projectiles"][obj.projectile_type]
        if fdm and fdm.cooldown then
          obj.cooldown = fdm.cooldown
        end
          --temporary debug
        if obj.projectile_type == "25"
        or obj.projectile_type == "26"
        or obj.projectile_type == "27"
        or obj.projectile_type == "28"
        or obj.projectile_type == "29"
        or obj.projectile_type == "2A" then
          obj.next_hit_at_lifetime = obj.remaining_lifetime - (4 - (obj.start_lifetime - 1 - obj.remaining_lifetime) % 4)
        end
      end

      if obj.next_hit_at_lifetime then
        obj.cooldown = obj.remaining_lifetime - obj.next_hit_at_lifetime
      end
      if obj.projectile_type == "00_tenguishi" then
        obj.tengu_state = memory.readbyte(obj.base + 41)
        if obj.tengu_state ~= 3 then
          obj.cooldown = 99
        else
          obj.cooldown = 0
        end
      end

      obj.animation_frame = frame_number - obj.animation_start_frame - obj.animation_freeze_frames

      projectiles[obj.id] = obj

      if frame_data["projectiles"] then
        obj.animation_frame_data = frame_data["projectiles"][obj.projectile_type]
      end

      if obj.animation_frame_data ~= nil and not debug_settings.recording_framedata then
        if obj.animation_frame_data.frames then
          obj.animation_frame = math.min(obj.animation_frame, #obj.animation_frame_data.frames - 1)
        end
        -- resync animation
        local frames = obj.animation_frame_data.frames
        local current_frame = frames[obj.animation_frame + 1]
        if current_frame then
          local target_hash = obj.animation_frame_hash
          local current_hash = current_frame.hash
          if current_hash ~= nil
          and current_hash ~= target_hash
          and (obj.remaining_freeze_frames == 0 or obj.freeze_just_began)
          then
            local resync_target, target_hash = find_resync_target(obj, obj.animation_frame_data, obj.animation_frame_data.infinite_loop)

            if resync_target ~= -1 then
              -- print(string.format("%d: resynced %s to %s frame(%d -> %d) target %s", frame_number, current_frame.hash, obj.animation_frame_data.frames[resync_target + 1].hash, obj.animation_frame, resync_target, target_hash))
              obj.animation_frame = resync_target
              obj.animation_start_frame = frame_number - resync_target - obj.animation_freeze_frames
            end
          end
        end
      end
    end
    -- Get the index to the next object in this list.
    obj_index = memory.readwordsigned(obj.base + 0x1C)
    obj_slot = obj_slot + 1
  end
end

local function remove_expired_projectiles()
  -- if a projectile is still expired, we remove it
  for id, obj in pairs(projectiles) do
    if obj.expired then
      log(player_objects[obj.emitter_id].prefix, "projectiles", string.format("projectile %s 0", id))
      projectiles[id] = nil
    end
  end
end


local function update_flip_input(player, other_player)
  if player.flip_input == nil then
    player.flip_input = other_player.pos_x >= player.pos_x
    return
  end

  local previous_flip_input = player.flip_input
--   local flip_hysteresis = 0 -- character_specific[other_player.char_str].half_width
  local diff = other_player.pos_x - player.pos_x
--   if math.abs(diff) >= flip_hysteresis then
    player.flip_input = other_player.pos_x >= player.pos_x
--   end

  if previous_flip_input ~= player.flip_input then
    log(player.prefix, "fight", "flip input")
  end

  if diff == 0 then
    player.flip_input = player.flip_x ~= 0
  end
end


local function gamestate_read()
  read_game_vars()

  read_player_vars(P1)
  read_player_vars(P2)

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


-- # initialize player objects
reset_player_objects()

local gamestate = {
  reset_player_objects = reset_player_objects,
  gamestate_read = gamestate_read,
  is_state_on_ground = is_state_on_ground
}

setmetatable(gamestate, {
  __index = function(_, key)
    if key == "frame_number" then
      return frame_number
    elseif key == "player_objects" then
      return player_objects
    elseif key == "P1" then
      return P1
    elseif key == "P2" then
      return P2
    elseif key == "projectiles" then
      return projectiles
    elseif key == "stage" then
      return stage
    elseif key == "is_in_match" then
      return is_in_match
    elseif key == "has_match_just_started" then
      return has_match_just_started
    end
  end,

  __newindex = function(_, key, value)
    if key == "frame_number" then
      frame_number = value
    elseif key == "player_objects" then
      player_objects = value
    elseif key == "P1" then
      P1 = value
    elseif key == "P2" then
      P2 = value
    elseif key == "projectiles" then
      projectiles = value
    elseif key == "stage" then
      stage = value
    elseif key == "is_in_match" then
      is_in_match = value
    elseif key == "has_match_just_started" then
      has_match_just_started = value
    else
      rawset(gamestate, key, value)
    end
  end
})

return gamestate