local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local game_data = require("src.modules.game_data")
local memory_addresses = require("src.control.memory_addresses")
local tools = require("src.tools")
local debug_settings = require("src.debug_settings")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local get_wakeup_time = fd.get_wakeup_time
local frame_data_meta = fdm.frame_data_meta

local frame_number = 0
local stage = 0
local match_state = 0
local is_in_character_select = false
local is_in_vs_screen = false
local is_before_curtain = false
local is_in_match = false
local has_match_just_started = false
local has_match_just_ended = false
local screen_x, screen_y = 0, 0
local player_objects = {}
local projectiles = {}

local P1, P2

local movement_postures = {[6] = true, [8] = true, [10] = true, [12] = true}
local jump_postures = {[20] = true, [22] = true, [24] = true, [26] = true, [28] = true, [30] = true}

local attacking_byte_exception = {
   alex = {["5e54"] = 10, ["5aec"] = 17, ["5944"] = 12, ["5cac"] = 22},
   gouki = {["5124"] = 10, ["a508"] = 17, ["a6e0"] = 21, ["a330"] = 13},
   twelve = {
      ["510c"] = 13,
      ["5bec"] = 13,
      ["5b2c"] = 15,
      ["5edc"] = 17,
      ["4bac"] = 13,
      ["5a6c"] = 17,
      ["5d0c"] = 21,
      ["5ddc"] = 12
   },
   ibuki = {
      ["f150"] = 10,
      ["93b8"] = 26,
      ["9750"] = 24,
      ["9578"] = 30,
      ["edb0"] = 10,
      ["ef80"] = 10,
      ["0748"] = 29,
      ["e2f0"] = 22
   },
   shingouki = {["e170"] = 23, ["ddc0"] = 14, ["df98"] = 18},
   gill = {["d63c"] = 100},
   hugo = {
      ["f3ac"] = 23,
      ["efcc"] = 18,
      ["f1bc"] = 20,
      ["2184"] = 68,
      ["f59c"] = 22,
      ["1d64"] = 25,
      ["1f24"] = 53,
      ["f7a4"] = 15,
      ["fa54"] = 19,
      ["fd1c"] = 28,
      ["0044"] = 31
   },
   dudley = {["3cdc"] = 19},
   chunli = {["ce8c"] = 41, ["c3b4"] = 17, ["486c"] = 13, ["4e44"] = 10, ["4b64"] = 12, ["5124"] = 14},
   ryu = {["8354"] = 15, ["84fc"] = 18, ["81dc"] = 12},
   makoto = {["2720"] = 21, ["df10"] = 61},
   sean = {["c25c"] = 22, ["2060"] = 23, ["4310"] = 0, ["2200"] = 29, ["1ef0"] = 19, ["2130"] = 27},
   urien = {["6aac"] = 23},
   ken = {["a870"] = 19, ["abe8"] = 34},
   necro = {
      ["80b4"] = 30,
      ["8574"] = 24,
      ["f084"] = 14,
      ["5e7c"] = 11,
      ["e7a4"] = 14,
      ["dd9c"] = 8,
      ["7f24"] = 28,
      ["7d94"] = 26,
      ["5824"] = 20,
      ["dadc"] = 12
   },
   yun = {["1e28"] = 33},
   yang = {["af98"] = 12, ["aa18"] = 12, ["94d8"] = 33, ["a498"] = 12}
}

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
         state_time = make_input_set(0)
      },
      blocking = {},
      counter = {attack_frame = -1, ref_time = -1, recording_slot = -1},
      stunned = false,
      throw_invulnerability_cooldown = 0,
      animation_frame = 0,
      posture = 0,
      meter_gauge = 0,
      meter_count = 0,
      max_meter_gauge = 0,
      max_meter_count = 0,
      cooldown = 0,
      remaining_wakeup_time = 0
   }
end

local function reset_player_objects()
   player_objects = {make_player_object(1, 0x02068C6C, "P1"), make_player_object(2, 0x02069104, "P2")}
   P1 = player_objects[1]
   P2 = player_objects[2]

   P1.other = P2
   P2.other = P1

   memory_addresses.update_addresses(P1)
   memory_addresses.update_addresses(P2)

   if debug_settings.developer_mode then
      for i, debug_vars in ipairs(debug_settings.player_debug_variables) do
         for k, v in pairs(debug_vars) do player_objects[i][k] = v end
      end
   end
end

-- projectile connections handled in read_projectiles
local function update_received_hits(player, other)
   if (player.just_received_connection or player.is_being_thrown) and not player.received_connection_is_projectile then
      player.last_received_connection_animation = other.animation
      player.last_received_connection_hit_id = math.max(other.current_hit_id, 1)
   end
end

local function update_wakeup(player, other)
   if player.posture == 0x26 and player.posture_ext >= 0x40 and not debug_settings.recording_framedata then
      player.remaining_wakeup_time = get_wakeup_time(player.char_str, player.animation, player.animation_frame)
   else
      player.remaining_wakeup_time = 0
   end
end

local function is_standing_state(player, state)
   if state == 0x01 then
      return true
   elseif character_specific[player.char_str] and character_specific[player.char_str].standing_states then
      for _, standing_state in ipairs(character_specific[player.char_str].standing_states) do
         if standing_state == state then return true end
      end
   end
   return false
end

local function is_crouching_state(player, state)
   if state == 0x02 then
      return true
   elseif character_specific[player.char_str] and character_specific[player.char_str].crouching_states then
      for _, standing_state in ipairs(character_specific[player.char_str].crouching_states) do
         if standing_state == state then return true end
      end
   end
   return false
end

local function is_ground_state(player, state)
   return is_standing_state(player, state) or is_crouching_state(player, state)
end

local function get_additional_recovery_delay(char_str, crouching)
   if crouching then
      if (char_str == "q" or char_str == "ryu" or char_str == "chunli") then return 2 end
   else
      if char_str == "q" then return 1 end
   end
   return 0
end

local function get_side(player_x, other_x, player_previous_x, other_previous_x)
   local diff = math.floor(player_x) - math.floor(other_x)
   if diff == 0 then diff = math.floor(player_previous_x) - math.floor(other_previous_x) end
   return diff > 0 and 2 or 1
end

local function get_parry_type(player)
   local player_airborne = player.posture >= 20 and player.posture <= 30
   local opponent_airborne = player.other.posture >= 20 and player.other.posture <= 30
   local parry_type = "ground"

   if not player.received_connection_is_projectile then
      if player_airborne then
         parry_type = "air"
      elseif opponent_airborne then
         parry_type = "anti_air"
      end
   end
   return parry_type
end

local function read_game_vars()
   -- frame number
   frame_number = memory.readdword(memory_addresses.global.frame_number)

   -- is in match
   local previous_match_state = match_state
   local p1_locked = memory.readbyte(memory_addresses.global.p1_locked)
   local p2_locked = memory.readbyte(memory_addresses.global.p2_locked)
   match_state = memory.readbyte(memory_addresses.global.match_state) -- 1 before curtain, 2 after curtain, 9 character select

   is_in_character_select = match_state == 0x09 and memory.readbyte(memory_addresses.global.menu_state) == 2
   is_in_vs_screen = match_state == 0x09 and memory.readbyte(memory_addresses.global.menu_state) == 3

   is_in_match = ((p1_locked == 0xFF or p2_locked == 0xFF) and match_state == 0x02)

   is_before_curtain = ((p1_locked == 0xFF or p2_locked == 0xFF) and match_state == 0x01)

   has_match_just_started = previous_match_state == 0x01 and is_in_match
   has_match_just_ended = match_state == 3

   stage = memory.readbyte(memory_addresses.global.stage)

   screen_x = memory.readwordsigned(memory_addresses.global.screen_pos_x)
   screen_y = memory.readwordsigned(memory_addresses.global.screen_pos_y)
end

local function read_input(player)

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
   read_single_input(player.input, "start", local_input[player.prefix .. " Start"])
   read_single_input(player.input, "coin", local_input[player.prefix .. " Coin"])
   read_single_input(player.input, "up", local_input[player.prefix .. " Up"])
   read_single_input(player.input, "down", local_input[player.prefix .. " Down"])
   read_single_input(player.input, "left", local_input[player.prefix .. " Left"])
   read_single_input(player.input, "right", local_input[player.prefix .. " Right"])
   read_single_input(player.input, "LP", local_input[player.prefix .. " Weak Punch"])
   read_single_input(player.input, "MP", local_input[player.prefix .. " Medium Punch"])
   read_single_input(player.input, "HP", local_input[player.prefix .. " Strong Punch"])
   read_single_input(player.input, "LK", local_input[player.prefix .. " Weak Kick"])
   read_single_input(player.input, "MK", local_input[player.prefix .. " Medium Kick"])
   read_single_input(player.input, "HK", local_input[player.prefix .. " Strong Kick"])
end

local function read_box(obj, ptr, type)
   if obj.friends > 1 then -- Yang SA3
      if type ~= "attack" then return end
   end

   local left = memory.readwordsigned(ptr + 0x0)
   local width = memory.readwordsigned(ptr + 0x2)
   local bottom = memory.readwordsigned(ptr + 0x4)
   local height = memory.readwordsigned(ptr + 0x6)

   local box = {tools.convert_box_types[type], bottom, height, left, width}

   if left == 0 and width == 0 and bottom == 0 and height == 0 then return end

   obj.boxes[#obj.boxes + 1] = box
end

local function read_game_object(obj)
   if memory.readdword(obj.base + 0x2A0) == 0 then -- invalid objects
      return false
   end

   obj.friends = memory.readbyte(obj.base + 0x1)
   obj.flip_x = memory.readbytesigned(obj.base + 0x0A) -- 0 = facing left, 1 = facing right
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
         read_box(obj, memory.readdword(obj.base + box.offset) + (i - 1) * 8, box.type)
      end
   end

   obj.animation_frame_id = memory.readword(obj.base + 0x21A)
   obj.animation_frame_id2 = memory.readbyte(obj.base + 0x214) -- number of frames animation stays on current frame_id
   obj.animation_frame_id3 = memory.readbyte(obj.base + 0x205)

   -- not a unique id for each frame but good enough
   local hash = {
      string.format("%04x", obj.animation_frame_id), string.format("%02x", obj.animation_frame_id2),
      string.format("%02x", obj.animation_frame_id3)
   }

   if obj.id == 1 or obj.id == 2 then
      local action_type = memory.readbyte(obj.addresses.action_type)
      -- throw, normal, special/sa
      if action_type == 3 or action_type == 4 or action_type == 5 then
         local action_count = memory.readbyte(obj.addresses.action_count)
         hash[#hash + 1] = string.format("%02x", action_count)
      else
         hash[#hash + 1] = "00"
      end
   else
      hash[#hash + 1] = "00"
   end

   obj.animation_frame_hash = table.concat(hash)
   return true
end

local function find_resync_target(obj, fdata, infinite_loop)
   local frames = fdata.frames
   local hash_length = 10
   local target = -1
   if infinite_loop then hash_length = 8 end
   local target_hash = string.sub(obj.animation_frame_hash, 1, hash_length)
   -- print(hash_length, current_hash, target_hash)

   for i = 1, #frames do
      local hash = string.sub(frames[i].hash, 1, hash_length)
      if hash == target_hash then return i - 1, target_hash end
   end

   -- framedata changes on block/hit for many moves
   if fdata.exceptions then
      if fdata.exceptions[target_hash] then return fdata.exceptions[target_hash], target_hash end
   end

   -- hits or blocks will change the frameid2/frameid3 portion of the hash, so we try to get a partial match instead
   local matches = {}
   local scores = {}
   local frameid = string.format("%04x", obj.animation_frame_id)
   for i = 1, #frames do
      if frameid == string.sub(frames[i].hash, 1, 4) then
         matches[#matches + 1] = i
         scores[#scores + 1] = 0
      end
   end

   if #matches > 0 then
      local frameid2 = string.format("%02x", obj.animation_frame_id2)
      local frameid3 = string.format("%02x", obj.animation_frame_id3)
      local action_count = "00"
      if obj.type == "player" then action_count = string.format("%02x", obj.animation_action_count) end
      for i = 1, #matches do
         local index = matches[i]
         local t_frameid2 = string.sub(frames[index].hash, 5, 6)
         local t_frameid3 = string.sub(frames[index].hash, 7, 8)
         local t_action_count = string.sub(frames[index].hash, 9, 10)
         if frameid2 == t_frameid2 then scores[i] = scores[i] + 30 end
         if frameid3 == t_frameid3 then scores[i] = scores[i] + 20 end
         if action_count == t_action_count then scores[i] = scores[i] + 10 end
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

local function read_player_vars(player)

   -- P1: 0x02068C6C
   -- P2: 0x02069104

   if memory.readdword(player.base + 0x2A0) == 0 then -- invalid objects
      return
   end

   local debug_state_variables = player.debug_state_variables

   read_input(player)

   read_game_object(player)

   local previous_movement_type = player.movement_type or 0

   player.char_str = game_data.characters[player.char_id + 1]

   player.previous_remaining_freeze_frames = player.remaining_freeze_frames or 0
   player.remaining_freeze_frames = memory.readbyte(player.addresses.remaining_freeze_frames)
   player.freeze_type = 0
   if player.remaining_freeze_frames ~= 0 then
      if player.remaining_freeze_frames < 127 then
         -- inflicted freeze I guess (when the opponent parry you for instance)
         player.freeze_type = 1
         player.remaining_freeze_frames = player.remaining_freeze_frames
      else
         player.freeze_type = 2
         player.remaining_freeze_frames = 256 - player.remaining_freeze_frames
      end
   end

   player.superfreeze_decount = player.superfreeze_decount or 0
   local previous_superfreeze_decount = player.superfreeze_decount

   player.max_meter_gauge = memory.readbyte(player.addresses.max_meter_gauge)
   player.max_meter_count = memory.readbyte(player.addresses.max_meter_count)
   player.selected_sa = memory.readbyte(player.addresses.selected_sa) + 1
   player.superfreeze_decount = memory.readbyte(player.addresses.superfreeze_decount)

   player.superfreeze_just_began = false
   if player.superfreeze_decount > 0 and previous_superfreeze_decount == 0 then player.superfreeze_just_began = true end

   player.superfreeze_just_ended = false
   if player.superfreeze_decount == 0 and previous_superfreeze_decount > 0 then player.superfreeze_just_ended = true end

   local previous_action = player.action or 0x00

   player.previous_input_capacity = player.input_capacity or 0
   player.input_capacity = memory.readword(player.addresses.input_capacity)
   player.action = memory.readdword(player.addresses.action)
   player.action_ext = memory.readdword(player.addresses.action_ext)
   player.previous_recovery_time = player.recovery_time or 0
   player.recovery_time = memory.readbyte(player.addresses.recovery_time)
   player.movement_type = memory.readbyte(player.addresses.movement_type)
   player.movement_type2 = memory.readbyte(player.addresses.movement_type2) -- seems that we can know which basic movement the player is doing from there
   player.total_received_projectiles_count = memory.readword(player.addresses.total_received_projectiles_count) -- on block or hit
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
   player.posture = memory.readbyte(player.addresses.posture)
   player.posture_ext = memory.readbyte(player.addresses.posture_ext)
   player.recovery_type = memory.readbyte(player.addresses.recovery_type) -- 1 was hit on ground, 4 attacking normal, 5 attacking special, 6 was hit in air, 7 body hit ground, updates frame after hit
   player.previous_standing_state = player.standing_state or 0
   player.standing_state = memory.readbyte(player.addresses.standing_state)
   player.has_just_started_jump = (player.action == 12 and previous_action ~= 12) or
                                      (player.action == 13 and previous_action ~= 13)
   player.is_standing = player.posture == 0x0 and player.pos_y == 0
   player.is_crouching = player.posture == 0x20 or player.posture == 0x21
   player.is_jumping = jump_postures[player.posture] or false
   player.is_airborne = player.is_jumping or (player.posture == 0 and player.pos_y ~= 0) -- maybe a memory location exists for distinguishing these states
   player.is_grounded = player.is_standing or player.is_crouching or movement_postures[player.posture] or
                            (player.posture == 0 and player.standing_state ~= 0 and player.pos_y == 0)

   player.busy_flag = memory.readword(player.addresses.busy_flag)

   local previous_is_in_basic_action = player.is_in_basic_action or false
   player.is_in_basic_action = player.action < 0xFF and previous_action < 0xFF -- this triggers one frame early than it should, so we delay it artificially
   player.has_just_entered_basic_action = not previous_is_in_basic_action and player.is_in_basic_action

   local previous_recovery_flag = player.recovery_flag or 1
   player.recovery_flag = memory.readbyte(player.addresses.recovery_flag)
   player.has_just_ended_recovery =
       player.standing_state <= 2 and previous_recovery_flag == 2 and player.recovery_flag ~= 2

   player.additional_recovery_time = player.additional_recovery_time or 0
   if player.has_just_ended_recovery or (previous_recovery_flag ~= 1 and player.recovery_flag == 1) then
      player.is_in_recovery = false
   end

   if player.freeze_just_ended and player.character_state_byte == 1 then
      if player.is_blocking then
         player.additional_recovery_time = get_additional_recovery_delay(player.char_str, player.is_crouching)
      end
      player.is_in_recovery = true
   end

   if player.ends_recovery_next_frame then
      player.has_just_ended_recovery = true
      player.ends_recovery_next_frame = false
   end

   if player.additional_recovery_time > 0 then
      player.has_just_ended_recovery = false
      if player.recovery_time == 0 and player.previous_recovery_time == 0 then
         player.additional_recovery_time = player.additional_recovery_time - 1
         if player.additional_recovery_time <= 0 then player.ends_recovery_next_frame = true end
      end
   elseif player.recovery_time == 0 and player.previous_recovery_time > 0 then
      player.ends_recovery_next_frame = true
   end

   player.meter_gauge = memory.readbyte(player.addresses.gauge)
   player.meter_count = memory.readbyte(player.addresses.meter_master)

   -- LIFE
   player.life = memory.readbyte(player.addresses.life)

   -- COMBO
   player.previous_combo = player.combo or 0
   player.combo = memory.readbyte(player.addresses.combo)

   -- NEXT HIT
   player.damage_of_next_hit = memory.readbyte(player.addresses.damage_of_next_hit)
   player.stun_of_next_hit = memory.readbyte(player.addresses.stun_of_next_hit)

   -- BONUSES
   player.damage_bonus = memory.readword(player.addresses.damage_bonus)
   player.stun_bonus = memory.readword(player.addresses.stun_bonus)
   player.defense_bonus = memory.readword(player.addresses.defense_bonus)

   -- THROW
   local previous_is_throwing = player.is_throwing or false
   player.is_throwing = bit.rshift(player.movement_type2, 4) == 9
   player.has_just_thrown = not previous_is_throwing and player.is_throwing

   local _previous_being_thrown = player.is_being_thrown
   player.is_being_thrown = memory.readbyte(player.addresses.is_being_thrown) ~= 0
   player.throw_countdown = player.throw_countdown or 0
   player.previous_throw_countdown = player.throw_countdown
   player.has_just_been_thrown = (not _previous_being_thrown) and player.is_being_thrown
   player.throw_tech_countdown = player.throw_tech_countdown or 0
   player.throw_tech_countdown = math.max(player.throw_tech_countdown - 1, 0)
   if player.has_just_been_thrown then player.throw_tech_countdown = 4 end
   player.is_in_throw_tech = player.action == 44 or player.action == 43 -- 44 attacker, 43 defender

   local throw_countdown = memory.readbyte(player.addresses.throw_countdown)
   if throw_countdown > player.previous_throw_countdown then
      player.throw_countdown = throw_countdown + 2 -- air throw animations seems to not match the countdown (ie. Ibuki's Air Throw), let's add a few frames to it
   else
      player.throw_countdown = math.max(player.throw_countdown - 1, 0)
   end

   local previous_animation = player.animation or ""
   player.animation = bit.tohex(memory.readword(player.base + 0x202), 4)

   -- ATTACKING
   local previous_is_attacking = player.is_attacking or false
   local previous_attacking_state = player.character_state_byte == 4 or false
   player.character_state_byte = memory.readbyte(player.addresses.character_state_byte) -- 0 idle, 1 blocking or being hit, 2 throwing, 3 being thrown, 4 attacking
   player.is_attacking_byte = memory.readbyte(player.addresses.is_attacking_byte)
   player.is_attacking = player.is_attacking_byte > 0 or
                             (attacking_byte_exception[player.char_str] and
                                 attacking_byte_exception[player.char_str][player.animation] and player.animation_frame <=
                                 attacking_byte_exception[player.char_str][player.animation])
   player.is_attacking_ext_byte = memory.readbyte(player.addresses.is_attacking_ext_byte)
   player.is_attacking_ext = player.is_attacking_ext_byte > 0
   player.has_just_attacked = player.is_attacking and not previous_is_attacking
   if debug_state_variables and player.has_just_attacked then
      print(string.format("%d - %s attacked", frame_number, player.prefix))
   end

   -- ACTION
   local previous_action_count = player.action_count or 0
   player.action_count = memory.readbyte(player.addresses.action_count)
   player.has_just_acted = player.action_count > previous_action_count
   if debug_state_variables and player.has_just_acted then
      print(string.format("%d - %s acted (%d > %d)", frame_number, player.prefix, previous_action_count,
                          player.action_count))
   end

   player.animation_action_count = player.animation_action_count or 0
   if player.has_just_acted then player.animation_action_count = player.animation_action_count + 1 end

   -- FREEZE
   player.freeze_just_began = false
   player.freeze_just_ended = false
   if player.remaining_freeze_frames > 0 then
      if player.previous_remaining_freeze_frames == 0 then
         player.freeze_just_began = true
      else
         if not (player.animation_frame_data and not debug_settings.recording_framedata and
             player.animation_frame_data.frames and player.animation_frame_data.frames[player.animation_frame + 1] and
             player.animation_frame_data.frames[player.animation_frame + 1].bypass_freeze) then
            player.animation_freeze_frames = player.animation_freeze_frames + 1
         end
      end
   elseif player.remaining_freeze_frames == 0 and player.previous_remaining_freeze_frames > 0 then
      player.freeze_just_ended = true
      player.animation_freeze_frames = player.animation_freeze_frames + 1
   end

   -- ANIMATION
   player.animation_start_frame = player.animation_start_frame or frame_number
   player.animation_freeze_frames = player.animation_freeze_frames or 0

   player.animation_frame = frame_number - player.animation_start_frame - player.animation_freeze_frames

   if player.animation_frame_data and not debug_settings.recording_framedata then
      -- cap animation frame. animation frame will sometimes exceed # of frames in frame data for some long looping animations i.e. air recovery
      player.animation_frame = math.min(player.animation_frame, #player.animation_frame_data.frames - 1)
   end

   player.animation_frame_data = nil
   if frame_data[player.char_str] then player.animation_frame_data = frame_data[player.char_str][player.animation] end
   player.has_animation_just_changed = previous_animation ~= player.animation

   local function reset_animation()
      player.animation_start_frame = frame_number
      player.animation_freeze_frames = 0

      player.current_hit_id = 0
      player.max_hit_id = 0
      player.animation_action_count = 0
      player.animation_miss_count = 0
      player.animation_connection_count = 0
      player.animation_hash_length = 10
      player.self_chain = false
      player.animation_frame = frame_number - player.animation_start_frame - player.animation_freeze_frames
   end

   if player.has_animation_just_changed then reset_animation() end

   -- self chain. cr. lk chains, etc
   if not debug_settings.recording_framedata then
      if player.animation_frame_data and not player.has_animation_just_changed and
          player.animation_frame_data.self_chain and player.animation_frame > 2 and
          (player.has_just_attacked or (player.previous_input_capacity > 0 and player.input_capacity == 0)) then
         player.self_chain = true
         player.animation_action_count = 0
      end
   end

   player.just_cancelled_into_attack = previous_attacking_state and player.character_state_byte == 4 and
                                           player.has_animation_just_changed -- not the most accurate

   -- if not debug_settings.recording_framedata then
   player.animation_frame_hash = string.sub(player.animation_frame_hash, 1, 8) ..
                                     string.format("%02x", player.animation_action_count)
   -- end

   -- resync animation
   if player.animation_frame_data and not debug_settings.recording_framedata then
      local frames = player.animation_frame_data.frames
      local current_frame = frames[player.animation_frame + 1]
      if current_frame then
         local target_hash = player.animation_frame_hash
         local current_hash = current_frame.hash
         if current_hash and current_hash ~= target_hash -- and (player.remaining_freeze_frames == 0 or player.freeze_just_began)
         then
            local resync_target, new_hash = find_resync_target(player, player.animation_frame_data,
                                                               player.animation_frame_data.infinite_loop)
            if resync_target ~= -1 then
               if player.self_chain and resync_target <= fd.get_first_hit_frame(player.char_str, player.animation) then
                  reset_animation()
               elseif resync_target == 0 then
                  player.animation_action_count = 0
                  player.animation_connection_count = 0
                  player.animation_miss_count = 0
                  player.self_chain = false
               end
               if player.animation_frame_data.infinite_loop then player.animation_action_count = 0 end
               player.current_hit_id = 0
               player.animation_frame = resync_target
               player.animation_start_frame = frame_number - resync_target - player.animation_freeze_frames
            end
         end
      end
   end
   if player.has_just_acted then player.last_act_animation = player.animation end

   -- PUSHBACK
   player.pushback_start_frame = player.pushback_start_frame or 0
   player.is_in_pushback = player.is_in_pushback or false
   if player.freeze_just_began or player.is_in_pushback and player.recovery_time == 0 then
      player.is_in_pushback = false
   end

   if player.freeze_just_ended and player.movement_type == 1 then
      player.pushback_start_frame = frame_number
      player.is_in_pushback = true
   end

   -- RECEIVED HITS/BLOCKS/PARRYS
   local previous_total_received_hit_count = player.total_received_hit_count or nil
   player.total_received_hit_count = memory.readword(player.addresses.total_received_hit_count)
   local total_received_hit_count_diff = 0
   if previous_total_received_hit_count then
      if previous_total_received_hit_count == 0xFFFF then
         total_received_hit_count_diff = 1
      else
         total_received_hit_count_diff = player.total_received_hit_count - previous_total_received_hit_count
      end
   end

   player.received_connection_id = memory.readdword(player.addresses.received_connection_id)
   player.received_connection_marker = memory.readword(player.addresses.received_connection_marker)
   player.just_received_connection = player.received_connection_marker ~= 0
   player.received_connection_type = memory.readbyte(player.addresses.received_connection_type)
   player.received_connection_is_projectile = player.received_connection_type == 2 or player.received_connection_type ==
                                                  4

   player.last_received_connection_frame = player.last_received_connection_frame or 0
   if player.just_received_connection then player.last_received_connection_frame = frame_number end

   player.last_movement_type_change_frame = player.last_movement_type_change_frame or 0
   if player.movement_type ~= previous_movement_type then player.last_movement_type_change_frame = frame_number end
   -- is blocking/has just blocked/has just been hit/has_just_parried
   player.blocking_id = memory.readbyte(player.addresses.blocking_id)
   player.has_just_blocked = false
   if (player.just_received_connection and player.received_connection_marker ~= 0xFFF1 and total_received_hit_count_diff ==
       0) or
       (player.just_received_connection and player.other.animation == "baac" and player.received_connection_marker ==
           0xFFF1 and total_received_hit_count_diff == 0 and (player.action == 30 or player.action == 31)) then -- chun st.HP bug
      player.has_just_blocked = true

      if debug_state_variables then print(string.format("%d - %s blocked", frame_number, player.prefix)) end
   end
   local previous_is_blocking = player.is_blocking
   player.is_blocking = player.blocking_id > 0 and player.blocking_id < 5 or player.has_just_blocked

   -- player.is_blocking_high_air = player.blocking_id == 1 --updates 1 frame after connection
   -- player.is_blocking_high = player.blocking_id == 2
   -- player.is_blocking_low = player.blocking_id == 3
   -- player.is_parrying_antiair = player.blocking_id == 5
   -- player.is_parrying_high = player.blocking_id == 6
   -- player.is_parrying_low = player.blocking_id == 7
   -- player.is_parrying_air = player.blocking_id == 8

   player.has_just_been_hit = false

   if total_received_hit_count_diff > 0 then player.has_just_been_hit = true end

   player.has_just_parried = false

   if player.just_received_connection and player.received_connection_marker == 0xFFF1 and total_received_hit_count_diff ==
       0 then
      player.has_just_parried = true
      if player.other.animation == "baac" and player.action ~= 23 then player.has_just_parried = false end -- chun st.HP bug
      if debug_state_variables then print(string.format("%d - %s parried", frame_number, player.prefix)) end
   end

   player.has_just_red_parried = false
   if previous_is_blocking and player.has_just_parried then
      player.has_just_red_parried = true
      player.has_just_ended_recovery = true
   end

   -- HITS
   local previous_hit_count = player.hit_count or 0
   player.hit_count = memory.readbyte(player.addresses.hit_count)
   player.has_just_hit = player.hit_count > previous_hit_count
   if player.has_just_hit then
      if debug_state_variables then
         print(string.format("%d - %s hit (%d > %d)", frame_number, player.prefix, previous_hit_count, player.hit_count))
      end
   end

   -- BLOCKS
   local previous_connected_action_count = player.connected_action_count or 0
   local previous_blocked_count = previous_connected_action_count - previous_hit_count
   player.connected_action_count = memory.readbyte(player.addresses.connected_action_count)
   local blocked_count = player.connected_action_count - player.hit_count
   player.has_just_been_blocked = blocked_count > previous_blocked_count
   if debug_state_variables and player.has_just_been_blocked then
      print(string.format("%d - %s blocked (%d > %d)", frame_number, player.prefix, previous_blocked_count,
                          blocked_count))
   end

   player.has_just_connected = false
   if player.connected_action_count > previous_connected_action_count then
      player.has_just_connected = true
      player.animation_connection_count = player.animation_connection_count + 1
   end

   local previous_animation_miss_count = player.animation_miss_count

   -- update hit id
   if player.animation_frame_data and player.superfreeze_decount == 0 then
      local hit_frames = player.animation_frame_data.hit_frames
      if hit_frames then
         player.max_hit_id = #hit_frames

         for i, hit_frame in ipairs(hit_frames) do
            if i > player.current_hit_id then
               if (player.animation_frame >= hit_frame[1] and player.animation_connection_count +
                   player.animation_miss_count >= i) then
                  player.current_hit_id = i
               elseif player.animation_frame > hit_frame[2] then
                  player.current_hit_id = i
               end
            end
         end
         for i, hit_frame in ipairs(hit_frames) do
            if i > player.current_hit_id then
               if player.animation_frame >= hit_frame[2] then
                  player.animation_miss_count = player.animation_miss_count + 1
               end
            end
         end
      end
   end

   -- for turning off hitboxes on hit like necro's drills
   if player.remaining_freeze_frames == 0 and not player.freeze_just_ended then
      player.cooldown = math.max(player.cooldown - 1, 0)
   end

   if player.has_just_connected then
      if frame_data_meta[player.char_str] and frame_data_meta[player.char_str][player.animation] and
          frame_data_meta[player.char_str][player.animation].cooldown then
         player.cooldown = frame_data_meta[player.char_str][player.animation].cooldown
      end
   end

   player.has_just_missed = false
   if player.animation_miss_count > previous_animation_miss_count then player.has_just_missed = true end

   -- LANDING
   local previous_is_in_jump_startup = player.is_in_jump_startup or false
   player.is_in_jump_startup = player.movement_type2 == 0x0C and player.movement_type == 0x00 and not player.is_blocking
   player.has_just_landed = is_ground_state(player, player.standing_state) and
                                not is_ground_state(player, player.previous_standing_state)
   player.has_just_hit_ground = player.previous_standing_state ~= 0 and player.standing_state == 0 and player.pos_y == 0
   if debug_state_variables and player.has_just_landed then
      print(string.format("%d - %s landed (%d > %d)", frame_number, player.prefix, player.previous_standing_state,
                          player.standing_state))
   end
   if player.debug_standing_state and player.previous_standing_state ~= player.standing_state then
      print(string.format("%d - %s standing state changed (%d > %d)", frame_number, player.prefix,
                          player.previous_standing_state, player.standing_state))
   end

   -- AIR RECOVERY STATE
   local debug_air_recovery = false
   local previous_is_in_air_recovery = player.is_in_air_recovery or false
   local r1 = memory.readbyte(player.base + 0x12F)
   local r2 = memory.readbyte(player.base + 0x3C7)
   player.is_in_air_recovery = player.standing_state == 0 and r1 == 0 and r2 == 0x06 and player.pos_y ~= 0
   player.has_just_entered_air_recovery = not previous_is_in_air_recovery and player.is_in_air_recovery

   if not previous_is_in_air_recovery and player.is_in_air_recovery then
      if debug_air_recovery then print(string.format("%s entered air recovery", player.prefix)) end
   end
   if previous_is_in_air_recovery and not player.is_in_air_recovery then
      if debug_air_recovery then print(string.format("%s exited air recovery", player.prefix)) end
   end

   -- IS IDLE
   local previous_is_idle = player.is_idle or false
   player.idle_time = player.idle_time or 0
   player.is_idle =
       (not player.is_attacking and --     not player.is_attacking_ext and --this seems to be set during some target combos. this value is never reset to 0 on some of elena's target combos'
       not player.is_blocking and not player.is_waking_up and not player.is_fast_wakingup and not player.is_being_thrown and
           not player.is_in_jump_startup and bit.band(player.busy_flag, 0xFF) == 0 and player.recovery_time ==
           player.previous_recovery_time and player.remaining_freeze_frames == 0 and player.input_capacity > 0)

   player.just_became_idle = not previous_is_idle and player.is_idle
   player.just_recovered = player.previous_recovery_time > 0 and player.recovery_time == 0 and player.standing_state < 3

   if player.is_idle then
      player.idle_time = player.idle_time + 1
   else
      player.idle_time = 0
   end

   if is_in_match then
      -- WAKE UP
      player.previous_can_fast_wakeup = player.can_fast_wakeup or 0
      player.can_fast_wakeup = memory.readbyte(player.addresses.can_fast_wakeup)

      local previous_fast_wakeup_flag = player.fast_wakeup_flag or 0
      player.fast_wakeup_flag = memory.readbyte(player.addresses.fast_wakeup_flag)

      player.is_flying_down_flag = memory.readbyte(player.addresses.is_flying_down_flag) -- does not reset to 0 after air reset landings, resets to 0 after jump start

      player.previous_is_wakingup = player.is_waking_up or false
      player.is_waking_up = player.posture == 0x26

      player.previous_is_fast_wakingup = player.is_fast_wakingup or false
      player.is_fast_wakingup = player.is_fast_wakingup or false

      if player.is_waking_up and previous_fast_wakeup_flag == 1 and player.fast_wakeup_flag == 0 then
         player.is_fast_wakingup = true
      end

      if player.previous_can_fast_wakeup ~= 0 and player.can_fast_wakeup == 0 then
         player.is_past_fast_wakeup_frame = true
      end

      if player.has_just_woke_up then
         player.is_fast_wakingup = false
         player.is_past_fast_wakeup_frame = false
      end

      player.has_just_started_wake_up = not player.previous_is_wakingup and player.is_waking_up
      player.has_just_started_fast_wake_up = not player.previous_is_fast_wakingup and player.is_fast_wakingup
      player.has_just_woke_up = player.previous_is_wakingup and not player.is_waking_up
   end

   if not previous_is_in_jump_startup and player.is_in_jump_startup then
      player.last_jump_startup_duration = 0
      player.last_jump_startup_frame = frame_number
   end

   if player.is_in_jump_startup then player.last_jump_startup_duration = player.last_jump_startup_duration + 1 end

   -- TIMED SA
   player.is_in_timed_sa = memory.readbyte(player.addresses.sa_state) == 4

   -- PARRY BUFFERS
   -- global game consts
   player.parry_forward = player.parry_forward or {name = "forward", max_validity = 10, max_cooldown = 21}
   player.parry_down = player.parry_down or {name = "down", max_validity = 10, max_cooldown = 21}
   player.parry_air = player.parry_air or {name = "air", max_validity = 7, max_cooldown = 18}
   player.parry_antiair = player.parry_antiair or {name = "anti_air", max_validity = 5, max_cooldown = 16}

   local function read_parry_state(parry_object, validity_addr, cooldown_addr)
      parry_object.last_hit_or_block_frame = parry_object.last_hit_or_block_frame or 0
      parry_object.last_attempt_frame = parry_object.last_attempt_frame or 0
      if player.has_just_blocked or player.has_just_been_hit then
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
      end

      -- check success/miss
      if parry_object.armed then
         local parry_type = get_parry_type(player)

         if parry_type == "ground" and (parry_object.name == "forward" or parry_object.name == "down") or parry_type ==
             "air" and parry_object.name == "air" or parry_type == "anti_air" and parry_object.name == "anti_air" then
            parry_object.last_attempt_frame = frame_number
            if player.has_just_parried then
               parry_object.delta = frame_number - parry_object.last_validity_start_frame
               parry_object.success = true
               parry_object.armed = false
               parry_object.last_hit_or_block_frame = 0
               -- log(player.prefix, "parry_training_" .. parry_object.name, "success")
            elseif parry_object.last_validity_start_frame == frame_number - 1 and
                (frame_number - parry_object.last_hit_or_block_frame) < 20 then
               local delta = parry_object.last_hit_or_block_frame - frame_number + 1
               if parry_object.delta == nil or math.abs(parry_object.delta) > math.abs(delta) then
                  parry_object.delta = delta
                  parry_object.success = false
               end
               -- log(player.prefix, "parry_training_" .. parry_object.name, "late")
            elseif player.has_just_blocked or player.has_just_been_hit then
               local delta = frame_number - parry_object.last_validity_start_frame
               if parry_object.delta == nil or math.abs(parry_object.delta) > math.abs(delta) then
                  parry_object.delta = delta
                  parry_object.success = false
               end
               -- log(player.prefix, "parry_training_" .. parry_object.name, "early")
            end
         end
      end
      if frame_number - parry_object.last_validity_start_frame > 30 and parry_object.armed then
         parry_object.armed = false
         parry_object.last_hit_or_block_frame = 0
         -- log(player.prefix, "parry_training_" .. parry_object.name, "reset")
      end
   end

   read_parry_state(player.parry_forward, player.addresses.parry_forward_validity_time,
                    player.addresses.parry_forward_cooldown_time)
   read_parry_state(player.parry_down, player.addresses.parry_down_validity_time,
                    player.addresses.parry_down_cooldown_time)
   read_parry_state(player.parry_air, player.addresses.parry_air_validity_time, player.addresses.parry_air_cooldown_time)
   read_parry_state(player.parry_antiair, player.addresses.parry_antiair_validity_time,
                    player.addresses.parry_antiair_cooldown_time)

   -- LEGS STATE
   -- global game consts
   player.legs_state = {}

   player.legs_state.enabled = player.char_id == 16 -- chunli
   player.legs_state.l_legs_count = memory.readbyte(player.addresses.kyaku_l_count)
   player.legs_state.m_legs_count = memory.readbyte(player.addresses.kyaku_m_count)
   player.legs_state.h_legs_count = memory.readbyte(player.addresses.kyaku_h_count)
   player.legs_state.reset_time = memory.readbyte(player.addresses.kyaku_reset_time)

   -- CHARGE STATE
   -- global game consts
   player.charge_1 = player.charge_1 or {name = "Charge1", max_charge = 43, max_reset = 43, enabled = false}
   player.charge_2 = player.charge_2 or {name = "Charge2", max_charge = 43, max_reset = 43, enabled = false}
   player.charge_3 = player.charge_3 or {name = "Charge3", max_charge = 43, max_reset = 43, enabled = false}

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
      if charge_object.charge_time == 0xFF then
         charge_object.charge_time = 0
      else
         charge_object.charge_time = charge_object.charge_time + 1
      end
      if charge_object.reset_time == 0xFF then
         charge_object.reset_time = 0
      else
         charge_object.reset_time = charge_object.reset_time + 1
      end
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
      ["alex"] = {
         charge_1_addr = player.addresses.charge_1,
         reset_1_addr = player.addresses.charge_1_reset,
         name1 = "charge_slash_elbow",
         valid_1 = true,
         charge_2_addr = player.addresses.charge_2,
         reset_2_addr = player.addresses.charge_2_reset,
         name2 = "charge_air_stampede",
         valid_2 = true,
         charge_3_addr = player.addresses.charge_3,
         reset_3_addr = player.addresses.charge_3_reset,
         valid_3 = false
      },
      ["oro"] = {
         charge_1_addr = player.addresses.charge_3,
         reset_1_addr = player.addresses.charge_3_reset,
         name1 = "charge_nichirin",
         valid_1 = true,
         charge_2_addr = player.addresses.charge_5,
         reset_2_addr = player.addresses.charge_5_reset,
         name2 = "charge_oniyanma",
         valid_2 = true,
         charge_3_addr = player.addresses.charge_3,
         reset_3_addr = player.addresses.charge_3_reset,
         valid_3 = false
      },
      ["urien"] = {
         charge_1_addr = player.addresses.charge_5,
         reset_1_addr = player.addresses.charge_5_reset,
         name1 = "charge_chariot_tackle",
         valid_1 = true,
         charge_2_addr = player.addresses.charge_2,
         reset_2_addr = player.addresses.charge_2_reset,
         name2 = "charge_violence_kneedrop",
         valid_2 = true,
         charge_3_addr = player.addresses.charge_4,
         reset_3_addr = player.addresses.charge_4_reset,
         name3 = "charge_dangerous_headbutt",
         valid_3 = true
      },
      ["remy"] = {
         charge_1_addr = player.addresses.charge_4,
         reset_1_addr = player.addresses.charge_4_reset,
         name1 = "charge_lov_high",
         valid_1 = true,
         charge_2_addr = player.addresses.charge_3,
         reset_2_addr = player.addresses.charge_3_reset,
         name2 = "charge_lov_low",
         valid_2 = true,
         charge_3_addr = player.addresses.charge_5,
         reset_3_addr = player.addresses.charge_5_reset,
         name3 = "charge_rising_rage_flash",
         valid_3 = true
      },
      ["q"] = {
         charge_1_addr = player.addresses.charge_5,
         reset_1_addr = player.addresses.charge_5_reset,
         name1 = "charge_dashing_head_attack",
         valid_1 = true,
         charge_2_addr = player.addresses.charge_4,
         reset_2_addr = player.addresses.charge_4_reset,
         name2 = "charge_dashing_leg_attack",
         valid_2 = true,
         charge_3_addr = player.addresses.charge_3,
         reset_3_addr = player.addresses.charge_3_reset,
         valid_3 = false
      },
      ["chunli"] = {
         charge_1_addr = player.addresses.charge_5,
         reset_1_addr = player.addresses.charge_5_reset,
         name1 = "charge_spinning_bird_kick",
         valid_1 = true,
         charge_2_addr = player.addresses.charge_2,
         reset_2_addr = player.addresses.charge_2_reset,
         valid_2 = false,
         charge_3_addr = player.addresses.charge_3,
         reset_3_addr = player.addresses.charge_3_reset,
         valid_3 = false
      }
   }

   if charge_table[player.char_str] then
      if charge_table[player.char_str].name1 then player.charge_1.name = charge_table[player.char_str].name1 end
      read_charge_state(player.charge_1, charge_table[player.char_str].valid_1,
                        charge_table[player.char_str].charge_1_addr, charge_table[player.char_str].reset_1_addr)
      if charge_table[player.char_str].name2 then player.charge_2.name = charge_table[player.char_str].name2 end
      read_charge_state(player.charge_2, charge_table[player.char_str].valid_2,
                        charge_table[player.char_str].charge_2_addr, charge_table[player.char_str].reset_2_addr)
      if charge_table[player.char_str].name3 then player.charge_3.name = charge_table[player.char_str].name3 end
      read_charge_state(player.charge_3, charge_table[player.char_str].valid_3,
                        charge_table[player.char_str].charge_3_addr, charge_table[player.char_str].reset_3_addr)
   else
      read_charge_state(player.charge_1, false, player.addresses.charge_1, player.addresses.charge_1_reset)
      read_charge_state(player.charge_2, false, player.addresses.charge_1, player.addresses.charge_1_reset)
      read_charge_state(player.charge_3, false, player.addresses.charge_1, player.addresses.charge_1_reset)
   end

   -- 360 STATE
   player.kaiten = player.kaiten or {
      {
         name = "kaiten1",
         directions = {},
         validity_time = 0,
         reset_time = 0,
         completed_360 = false,
         previous_completed_360 = false,
         max_reset = 31,
         enabled = false
      }, {
         name = "kaiten2",
         directions = {},
         validity_time = 0,
         reset_time = 0,
         completed_360 = false,
         previous_completed_360 = false,
         max_reset = 31,
         enabled = false
      }, {
         name = "kaiten3",
         directions = {},
         validity_time = 0,
         reset_time = 0,
         completed_360 = false,
         previous_completed_360 = false,
         max_reset = 31,
         enabled = false
      }
   }

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

      local left = bit.band(dir_data, 8) > 0 -- technically forward/back not left/right
      local right = bit.band(dir_data, 4) > 0
      local down = bit.band(dir_data, 2) > 0
      local up = bit.band(dir_data, 1) > 0

      kaiten_object.completed_360 = memory.readbyte(kaiten_completed_addr) ~= 48
      local just_completed_360 = dir_data == 15
      if kaiten_object.name == "moonsault_press" and not just_completed_360 then
         if kaiten_object.completed_360 ~= kaiten_object.previous_completed_360 then just_completed_360 = true end
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
         {
            kaiten_address = player.addresses.kaiten_1,
            reset_address = player.addresses.kaiten_1_reset,
            kaiten_completed = player.addresses.kaiten_completed_360,
            name = "hyper_bomb",
            valid = true
         }
      },
      ["hugo"] = {
         {
            kaiten_address = player.addresses.kaiten_1,
            reset_address = player.addresses.kaiten_1_reset,
            kaiten_completed = player.addresses.kaiten_completed_360,
            name = "moonsault_press",
            valid = true
         }, {
            kaiten_address = player.addresses.kaiten_2,
            reset_address = player.addresses.kaiten_2_reset,
            kaiten_completed = player.addresses.kaiten_completed_360,
            name = "meat_squasher",
            valid = true
         }, {
            kaiten_address = player.addresses.kaiten_1,
            reset_address = player.addresses.kaiten_1_reset,
            kaiten_completed = player.addresses.kaiten_completed_360,
            name = "gigas_breaker",
            valid = true,
            is_720 = true
         }
      }
   }

   if kaiten_table[player.char_str] then
      for i = 1, #player.kaiten do
         local kaiten = kaiten_table[player.char_str][i]
         if kaiten then
            player.kaiten[i].name = kaiten.name
            read_kaiten_state(player.kaiten[i], kaiten.valid, kaiten.kaiten_address, kaiten.reset_address,
                              kaiten.kaiten_completed, kaiten.is_720)
         else
            player.kaiten[i] = {name = "kaiten" .. tostring(i), enabled = false}
         end
      end
   end

   -- STUN
   player.stun_bar_max = memory.readbyte(player.addresses.stun_bar_max) or 64
   player.stun_activate = memory.readbyte(player.addresses.stun_activate) or 0
   player.previous_stun_timer = player.stun_timer or 0
   player.stun_timer = memory.readbyte(player.addresses.stun_timer) or 0
   player.stun_bar_char = memory.readbyte(player.addresses.stun_bar_char) or 0
   player.stun_bar_mantissa = memory.readbyte(player.addresses.stun_bar_mantissa) or 0
   player.stun_bar = player.stun_bar_char + player.stun_bar_mantissa / 256
   player.previous_stunned = player.is_stunned or false
   player.stun_just_began = false
   player.stun_just_ended = false

   -- for detecting stun from savestate
   if player.previous_stun_timer and player.stun_timer < player.previous_stun_timer and player.stun_timer > 0 and
       player.stun_timer < 250 then player.is_stunned = true end
   if player.stun_activate == 1 then
      player.is_stunned = true
      if not player.previous_stunned then player.stun_just_began = true end
   elseif player.is_stunned then
      if player.just_received_connection or player.is_being_thrown or player.stun_timer == 0 or player.stun_timer >= 250 then
         player.is_stunned = false
         player.stun_just_ended = true
      end
   end

   -- THROW INVULNERABILITY
   player.throw_invulnerability_cooldown = player.throw_invulnerability_cooldown or 0
   player.throw_recovery_frame = player.throw_recovery_frame or 0
   local previous_throw_invulnerability_cooldown = player.throw_invulnerability_cooldown
   player.throw_invulnerability_cooldown = math.max(player.throw_invulnerability_cooldown - 1, 0)
   if previous_throw_invulnerability_cooldown > 0 and player.throw_invulnerability_cooldown == 0 then
      player.throw_recovery_frame = frame_number
   end
   if player.has_just_woke_up then
      player.throw_invulnerability_cooldown = 7
   elseif player.has_just_ended_recovery then
      player.throw_invulnerability_cooldown = 6
   elseif player.is_in_recovery and player.recovery_time > 0 then
      player.throw_invulnerability_cooldown = player.recovery_time + 7 + player.additional_recovery_time
   elseif player.remaining_wakeup_time > 0 then
      player.throw_invulnerability_cooldown = player.remaining_wakeup_time + 7
   elseif player.just_received_connection or player.remaining_freeze_frames > 0 then
      player.throw_invulnerability_cooldown = 10
   end
end

-- oro's throw's and nichirin
local tengu_stone_invalid_anim = {["72c8"] = true, ["7438"] = true}
local tengu_hit_order = {[1] = 1, [2] = 3, [3] = 2}

local function are_all_tengu_stones_idle(tengu_stones)
   for _, stone in pairs(tengu_stones) do if stone.tengu_state ~= 2 then return false end end
   return true
end

local function update_tengu_stone_order(tengu_stones)
   local list = {}
   for _, stone in pairs(tengu_stones) do list[#list + 1] = stone end
   table.sort(list, function(a, b) return a.pos_x < b.pos_x end)
   for i = 1, #list do
      if #list == 3 then
         list[i].tengu_order = tengu_hit_order[i]
      else
         list[i].tengu_order = i
      end
   end
end

local function update_tengu_stones()
   if not (P1 and P1.char_str == "oro" and P1.selected_sa == 3 and P1.is_in_timed_sa) and
       not (P2 and P2.char_str == "oro" and P2.selected_sa == 3 and P2.is_in_timed_sa) then return end

   for _, player in ipairs(player_objects) do
      if player.char_str == "oro" and player.selected_sa == 3 and player.superfreeze_just_ended then
         player.tengu_stones = {}
      end
   end

   local connected_stone
   for _, proj in pairs(projectiles) do
      if proj.projectile_type == "00_tenguishi" then
         if not player_objects[proj.emitter_id].tengu_stones then
            player_objects[proj.emitter_id].tengu_stones = {}
         end
         player_objects[proj.emitter_id].tengu_stones[proj.id] = proj
         proj.tengu_state = memory.readbyte(proj.base + 41)
         if proj.tengu_attack_queued then
            if proj.tengu_state == 3 then proj.tengu_attack_queued = false end
         else
            if proj.tengu_state ~= 3 then
               proj.cooldown = 99
            else
               proj.cooldown = 0
            end
         end
         if proj.has_just_connected and proj.tengu_order then
            if not connected_stone or proj.tengu_order < connected_stone.tengu_order then
               if connected_stone then connected_stone.has_just_connected = false end
               connected_stone = proj
            end
         end
      end
   end
   if connected_stone then connected_stone.cooldown = 99 end

   for _, player in ipairs(player_objects) do
      if player.char_str == "oro" and player.selected_sa == 3 and player.is_in_timed_sa and player.tengu_stones then
         if player.superfreeze_just_ended or are_all_tengu_stones_idle(player.tengu_stones) then
            update_tengu_stone_order(player.tengu_stones)
         end

         if player.has_just_attacked and not tengu_stone_invalid_anim[player.animation] then
            local fdata = player.animation_frame_data
            if fdata then
               local next_hit_id = player.current_hit_id + 1
               if fdata.hit_frames and fdata.hit_frames[next_hit_id] then
                  player.tengu_connect_frame = frame_number + fdata.hit_frames[next_hit_id][1] - player.animation_frame
               end
            end
         end
         if player.tengu_connect_frame and player.tengu_connect_frame > frame_number then
            local delta = player.tengu_connect_frame - frame_number
            for _, proj in pairs(player.tengu_stones) do
               if (proj.tengu_state == 1 or proj.tengu_state == 2) and not proj.tengu_attack_queued then
                  proj.cooldown = delta
                  proj.tengu_attack_queued = true
               end
            end
         end
      end
   end
end

local function update_seieienbu()
   if not (P1 and P1.char_str == "yang" and P1.selected_sa == 3 and P1.is_in_timed_sa) and
       not (P2 and P2.char_str == "yang" and P2.selected_sa == 3 and P2.is_in_timed_sa) then return end

   for _, player in ipairs(player_objects) do
      if player.char_str == "yang" and player.is_in_timed_sa then
         if player.character_state_byte == 4 and player.animation_frame_data then
            local attack_boxes = tools.get_boxes(player.boxes, {"attack", "throw"})
            if #attack_boxes > 0 or player.has_just_connected then
               if player.animation_frame_data and player.animation_frame_data.hit_frames then
                  local hit_id = player.current_hit_id
                  if not player.has_just_connected then hit_id = hit_id + 1 end
                  hit_id = tools.clamp(hit_id, 1, #player.animation_frame_data.hit_frames)
                  local seiei_frame = player.animation_frame_data.hit_frames[hit_id][1]
                  if player.has_just_connected then
                     if player.animation_frame_data.frames and player.animation_frame_data.frames[seiei_frame + 1] and
                         player.animation_frame_data.frames[seiei_frame + 1].boxes then
                        attack_boxes = tools.get_boxes(player.animation_frame_data.frames[seiei_frame + 1].boxes,
                                                       {"attack", "throw"})
                     end
                  end
               end
               if #attack_boxes > 0 then
                  for i = 1, 2 do
                     local projectile = {
                        id = "seieienbu_" .. player.id .. "_" .. i,
                        emitter_id = player.id,
                        alive = true,
                        projectile_type = "seieienbu",
                        projectile_start_type = "seieienbu",
                        pos_x = player.pos_x,
                        pos_y = player.pos_y,
                        velocity_x = 0,
                        velocity_y = 0,
                        acceleration_x = 0,
                        acceleration_y = 0,
                        flip_x = player.flip_x,
                        boxes = attack_boxes,
                        expired = false,
                        previous_remaining_hits = 99,
                        remaining_hits = 99,
                        is_forced_one_hit = false,
                        has_activated = false,
                        animation_start_frame = frame_number + i * 10,
                        animation_frame = 0,
                        animation_frame_id = player.animation_frame_id,
                        animation_freeze_frames = 0,
                        remaining_freeze_frames = 0,
                        remaining_lifetime = 0,
                        cooldown = 0,
                        placeholder = true,
                        seiei_animation = player.animation,
                        seiei_frame = player.animation_frame,
                        seiei_hit_id = player.current_hit_id
                     }
                     projectiles[projectile.id .. "_" .. tostring(frame_number)] = projectile
                  end
               end
            end
         end
      end
   end
   local to_remove = {}
   for id, proj in pairs(projectiles) do
      if proj.projectile_type == "seieienbu" and proj.has_just_connected then
         for other_id, other_proj in pairs(projectiles) do
            if proj.id == other_proj.id and proj.seiei_animation == other_proj.seiei_animation then
               to_remove[#to_remove + 1] = other_id
            end
         end
      end
   end
   for _, key in ipairs(to_remove) do projectiles[key] = nil end
end

local ex_yagyou_cooldowns = {
   ["9ab7015800"] = 1,
   ["9ab8015c00"] = 1,
   ["9ab6015400"] = 2,
   ["9ab5015000"] = 3,
   ["9ab7012800"] = 3,
   ["9ab1011000"] = 3,
   ["9ab0010c00"] = 4,
   ["9ab5012000"] = 5,
   ["9ab3014800"] = 5,
   ["9aae010400"] = 6,
   ["9ae901c000"] = 6,
   ["9af101e000"] = 6
}
local function update_projectile_cooldown(obj)
   local fdmeta = frame_data_meta["projectiles"][obj.projectile_type]
   if fdmeta then
      if fdmeta.cooldown then obj.cooldown = fdmeta.cooldown end
      if fdmeta.hit_period then
         obj.next_hit_at_lifetime = obj.remaining_lifetime -
                                        (fdmeta.hit_period - (obj.start_lifetime - 1 - obj.remaining_lifetime) %
                                            fdmeta.hit_period)
         obj.cooldown = obj.remaining_lifetime - obj.next_hit_at_lifetime + 1
      end
   end
   -- EX Aegis sometimes hits slow
   if obj.projectile_type == "68" and obj.animation_frame_hash == "5250024000" then obj.cooldown = 19 end
   -- EX Yagyou is weird
   if obj.projectile_type == "72" then
      if ex_yagyou_cooldowns[obj.animation_frame_hash] then
         obj.cooldown = ex_yagyou_cooldowns[obj.animation_frame_hash] + 1
      else
         obj.cooldown = 8
      end
   end
end

local max_objects = 30
local function read_projectiles()
   projectiles = projectiles or {}

   -- flag everything as expired by default, we will reset the flag it we update the projectile
   for id, obj in pairs(projectiles) do
      if obj.placeholder then
         if obj.animation_start_frame <= frame_number then obj.expired = true end
      else
         obj.expired = true
      end
   end

   -- how we recover hitboxes data for each projectile is taken almost as is from the cps3-hitboxes.lua script
   -- object = {initial = 0x02028990, index = 0x02068A96},
   local index = 0x02068A96
   local initial = 0x02028990
   local list = 3
   local obj_index = memory.readwordsigned(index + (list * 2))

   local obj_slot = 1
   while obj_slot <= max_objects and obj_index ~= -1 do
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

      if not obj.placeholder and read_game_object(obj) then
         obj.emitter_id = memory.readbyte(obj.base + 0x2) + 1

         if is_initialization then
            obj.initial_flip_x = obj.flip_x
            obj.emitter_animation = player_objects[obj.emitter_id].animation
            for proj_id, proj in pairs(projectiles) do
               if proj.placeholder and proj.projectile_type == obj.projectile_type then obj.id = proj_id end
            end
         else
            obj.lifetime = obj.lifetime + 1
         end

         if #obj.boxes > 0 then obj.has_activated = true end

         obj.expired = false
         obj.is_converted = obj.flip_x ~= obj.initial_flip_x
         obj.previous_remaining_hits = obj.remaining_hits or 0
         obj.remaining_hits = memory.readbyte(obj.base + 0x9C + 2)
         if obj.remaining_hits > 0 then obj.is_forced_one_hit = false end

         obj.alive = memory.readbyte(obj.base + 39) ~= 2

         obj.previous_remaining_freeze_frames = obj.remaining_freeze_frames
         obj.remaining_freeze_frames = memory.readbyte(obj.base + 0x45)

         obj.freeze_just_began = false
         if obj.remaining_freeze_frames > 0 then
            if obj.previous_remaining_freeze_frames == 0 then obj.freeze_just_began = true end
            obj.animation_freeze_frames = obj.animation_freeze_frames + 1
         end
         if obj.cooldown > 0 and
             ((obj.remaining_freeze_frames == 0 or obj.freeze_just_began) or obj.projectile_type == "72") then
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
            elseif emitter.char_str == "twelve" then
               if emitter.animation == "c534" then
                  obj.projectile_type = "00_ndl_lp"
               elseif emitter.animation == "c684" then
                  obj.projectile_type = "00_ndl_mp"
               elseif emitter.animation == "c7d4" then
                  obj.projectile_type = "00_ndl_hp"
               elseif emitter.animation == "ca84" then
                  obj.projectile_type = "00_xndl"
               end
            elseif emitter.char_str == "yang" then
               obj.projectile_type = "00_seieienbu"
            end
         elseif obj.projectile_type == "01" then
            if emitter.char_str == "twelve" then obj.projectile_type = "01_ndl_exp" end
         end

         if is_initialization then
            obj.projectile_start_type = obj.projectile_type -- type can change during projectile life (ex: aegis)
            obj.animation_start_frame = frame_number
            obj.start_lifetime = obj.remaining_lifetime
         end

         if obj.next_hit_at_lifetime then obj.cooldown = obj.remaining_lifetime - obj.next_hit_at_lifetime end

         obj.animation_frame = frame_number - obj.animation_start_frame - obj.animation_freeze_frames
         obj.has_just_connected = false
         if emitter.other.just_received_connection and emitter.other.received_connection_is_projectile and
             (obj.cooldown <= 0 or obj.projectile_type == "72") then
            if emitter.other.received_connection_id == obj.base then
               obj.has_just_connected = true
               update_projectile_cooldown(obj)
               emitter.other.last_received_connection_animation = obj.projectile_type
               emitter.other.last_received_connection_hit_id = 1
            end
         end

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
               if current_hash ~= nil and current_hash ~= target_hash then
                  local resync_target = find_resync_target(obj, obj.animation_frame_data,
                                                           obj.animation_frame_data.infinite_loop)

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

   update_tengu_stones()
   update_seieienbu()
end

local function remove_expired_projectiles()
   -- if a projectile is still expired, we remove it
   local to_remove = {}
   for id, obj in pairs(projectiles) do if obj.expired then to_remove[#to_remove + 1] = id end end
   for _, key in ipairs(to_remove) do projectiles[key] = nil end
end

local function update_flip_input(player, other_player)
   local diff = other_player.pos_x - player.pos_x
   if diff == 0 then diff = math.floor(other_player.previous_pos_x) - math.floor(player.previous_pos_x) end

   player.flip_input = diff > 0
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

      update_wakeup(P1, P2)
      update_wakeup(P2, P1)
   end
end

-- # initialize player objects
reset_player_objects()

local gamestate = {
   reset_player_objects = reset_player_objects,
   gamestate_read = gamestate_read,
   is_standing_state = is_standing_state,
   is_crouching_state = is_crouching_state,
   is_ground_state = is_ground_state,
   get_side = get_side,
   update_projectile_cooldown = update_projectile_cooldown
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
      elseif key == "screen_x" then
         return screen_x
      elseif key == "screen_y" then
         return screen_y
      elseif key == "match_state" then
         return match_state
      elseif key == "is_in_character_select" then
         return is_in_character_select
      elseif key == "is_in_vs_screen" then
         return is_in_vs_screen
      elseif key == "is_in_match" then
         return is_in_match
      elseif key == "is_before_curtain" then
         return is_before_curtain
      elseif key == "has_match_just_started" then
         return has_match_just_started
      elseif key == "has_match_just_ended" then
         return has_match_just_ended
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
      else
         rawset(gamestate, key, value)
      end
   end
})

return gamestate
