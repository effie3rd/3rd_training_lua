local fd = require("src.data.framedata")
local fdm = require("src.data.framedata_meta")
local sd = require("src.data.stage_data")
local move_data = require("src.data.move_data")
local gamestate = require("src.gamestate")
local tools = require("src.tools")
local debug_settings = require("src.debug_settings")

local character_specific, get_hurtboxes = fd.character_specific, fd.get_hurtboxes
local stages = sd.stages
local find_move_frame_data = fd.find_move_frame_data
local frame_data_meta = fdm.frame_data_meta

local next_anim_types = {"next_anim", "optional_anim"}

local next_animation = {}

local animations = {
   NONE = 1,
   WALK_FORWARD = 2,
   WALK_BACK = 3,
   WALK_TRANSITION = 4,
   STANDING_BEGIN = 5,
   CROUCHING_BEGIN = 6,
   BLOCK_HIGH_PROXIMITY = 7,
   BLOCK_HIGH = 8,
   BLOCK_HIGH_AIR_PROXIMITY = 9,
   BLOCK_HIGH_AIR = 10,
   BLOCK_LOW = 11,
   BLOCK_LOW_PROXIMITY = 12,
   PARRY_HIGH = 13,
   PARRY_LOW = 14,
   PARRY_AIR = 15
}

local function predict_frames_branching(obj, anim, frame, frames_prediction, specify_frame, result)
   local results = {}
   result = result or {}
   frame = frame or obj.animation_frame
   local fdata
   if obj.type == "player" then
      anim = anim or obj.animation
      fdata = find_move_frame_data(obj.char_str, anim)
   else
      anim = anim or obj.projectile_type
      fdata = find_move_frame_data("projectiles", anim)
   end
   if not fdata then return results end
   local max_frames = fdata.frames and #fdata.frames or 1
   local frame_to_check = math.min(frame + 1, max_frames)
   local delta = 0
   if #result > 0 then delta = result[#result].delta end

   if specify_frame then
      delta = delta + 1
      frames_prediction = frames_prediction - 1
      result[#result + 1] = {animation = anim, frame = math.min(frame, max_frames - 1), delta = delta}
   end

   local used_loop = false
   local used_next_anim = false

   for i = 1, frames_prediction do
      if fdata and frame_to_check <= #fdata.frames and fdata.frames[frame_to_check] then
         used_loop = false
         used_next_anim = false
         delta = delta + 1
         if fdata.frames[frame_to_check].loop then
            used_loop = true
            frame_to_check = fdata.frames[frame_to_check].loop + 1
         else
            for _, na in pairs(next_anim_types) do
               if fdata.frames[frame_to_check][na] then
                  if na == "next_anim" then used_next_anim = true end
                  for __, next_anim in pairs(fdata.frames[frame_to_check][na]) do
                     local current_res = copytable(result)
                     local next_anim_anim = next_anim[1]
                     local next_anim_frame = next_anim[2]
                     if next_anim_anim == "idle" then
                        if obj.posture == 32 then
                           next_anim_anim = fd.frame_data[obj.char_str].crouching
                           next_anim_frame = 0
                        else
                           next_anim_anim = fd.frame_data[obj.char_str].standing
                           next_anim_frame = 0
                        end
                     end
                     current_res[#current_res + 1] = {
                        animation = next_anim_anim,
                        frame = next_anim_frame,
                        delta = delta
                     }
                     local subres = predict_frames_branching(obj, next_anim_anim, next_anim_frame,
                                                             frames_prediction - i, false, current_res)

                     for ___, sr in pairs(subres) do results[#results + 1] = sr end
                  end
               end
            end
         end
         if used_next_anim then
            break
         else
            if not used_loop then
               frame_to_check = frame_to_check + 1
               if frame_to_check > #fdata.frames then break end
            end
            result[#result + 1] = {animation = anim, frame = frame_to_check - 1, delta = delta}
         end
      end
   end

   if not used_next_anim then results[#results + 1] = result end

   return results
end

local function predict_frames_before_landing(player)
   local frames_prediction = 20
   local y = player.pos_y
   local velocity = player.velocity_y
   for i = 1, frames_prediction do
      y = y + velocity
      velocity = velocity + player.acceleration_y
      if player.animation_frame_data and player.animation_frame_data.landing_height then
         if y < player.animation_frame_data.landing_height then return i end
      elseif y < 0 then
         return i
      end
   end
   return -1
end

local function get_frames_until_idle(obj, anim, frame, frames_prediction, result, depth)
   if obj.is_idle then return 0 end
   if obj.remaining_freeze_frames == 0 and not obj.freeze_just_ended then
      local recovery_time = obj.recovery_time + obj.additional_recovery_time
      if recovery_time > 0 then return recovery_time + 1 end
   end

   depth = depth or 0
   local results = {}
   result = result or 0
   anim = anim or obj.animation
   frame = frame or obj.animation_frame
   local fdata = find_move_frame_data(obj.char_str, anim)

   local delta = 0
   if result then delta = result end

   local used_loop = false
   local used_next_anim = false

   if not fdata then
      if result == 0 then return frames_prediction end
      return delta, false
   end
   local max_frames = fdata.frames and #fdata.frames or 1
   local frame_to_check = math.min(frame + 1, max_frames)

   if obj.is_airborne and fdata.landing_anim then
      local frames_until_landing = predict_frames_before_landing(obj)
      local adjustment = 0
      if fdata.name == "uoh" and obj.animation_connection_count > 0 then adjustment = -1 end
      if obj.is_in_air_reel then adjustment = 20 end -- knockdown
      return obj.remaining_freeze_frames + frames_until_landing +
                 get_frames_until_idle(obj, fdata.landing_anim, 0, frames_prediction) + adjustment
   end

   if fdata.idle_frames then
      local diff = delta
      for _, idle_frame in ipairs(fdata.idle_frames) do
         if frame <= idle_frame[1] then
            diff = idle_frame[1] - frame
            break
         end
      end
      return delta + diff, true
   else
      if fdata.loops then
         for i = 1, #fdata.loops do
            if frame_to_check >= fdata.loops[i][1] + 1 and frame_to_check <= fdata.loops[i][2] + 1 then break end
         end
      end
      for i = 1, frames_prediction do
         if fdata and frame_to_check <= #fdata.frames and fdata.frames[frame_to_check] then
            used_loop = false
            used_next_anim = false
            delta = delta + 1
            if fdata.frames[frame_to_check].loop then
               used_loop = true
               frame_to_check = fdata.frames[frame_to_check].loop + 1
            else
               for _, na in pairs(next_anim_types) do
                  if fdata.frames[frame_to_check][na] then
                     if na == "next_anim" then used_next_anim = true end
                     for __, next_anim in pairs(fdata.frames[frame_to_check][na]) do
                        local next_anim_anim = next_anim[1]
                        local next_anim_frame = next_anim[2]
                        if next_anim_anim == "idle" then return delta, true end
                        local subres, found = get_frames_until_idle(obj, next_anim_anim, next_anim_frame,
                                                                    frames_prediction - i, delta, depth + 1)
                        if found then results[#results + 1] = subres end

                     end
                  end
               end
            end
            if used_next_anim then
               break
            else
               if not used_loop then
                  frame_to_check = frame_to_check + 1
                  if frame_to_check > #fdata.frames then break end
               end
               result = delta
            end
         end
      end
      if #results == 0 then return frames_prediction, false end

      local res = math.min(unpack(results))
      if depth == 0 then res = res + obj.remaining_freeze_frames end

      return res, true
   end
end

local function get_frame_advantage(player)
   if player.has_just_connected or player.other.has_just_connected or
       (player.character_state_byte == 1 and (player.freeze_just_ended or player.remaining_freeze_frames > 0)) or
       (player.other.character_state_byte == 1 and
           (player.other.freeze_just_ended or player.other.remaining_freeze_frames > 0)) then return end
   local recovery_times = {0, 0}
   for _, p in ipairs({player, player.other}) do recovery_times[p.id] = get_frames_until_idle(p, nil, nil, 80) end
   return recovery_times[player.other.id] - recovery_times[player.id]
end

local function check_switch_sides(player)
   local previous_dist = math.floor(player.other.previous_pos_x) - math.floor(player.previous_pos_x)
   local dist = math.floor(player.other.pos_x) - math.floor(player.pos_x)
   if tools.sign(previous_dist) ~= tools.sign(dist) and dist ~= 0 then return true end
   return false
end

local function init_motion_data(obj)
   local data = {
      pos_x = obj.pos_x,
      pos_y = obj.pos_y,
      flip_x = obj.flip_x,
      velocity_x = obj.velocity_x,
      velocity_y = obj.velocity_y,
      acceleration_x = obj.acceleration_x,
      acceleration_y = obj.acceleration_y
   }
   if obj.type == "player" then
      data.standing_state = obj.standing_state
      if obj.is_in_pushback then data.pushback_start_index = gamestate.frame_number - obj.pushback_start_frame end
   end
   return {[0] = data}
end

local function init_motion_data_zero(obj)
   local data = {
      pos_x = obj.pos_x,
      pos_y = obj.pos_y,
      flip_x = obj.flip_x,
      velocity_x = 0,
      velocity_y = 0,
      acceleration_x = 0,
      acceleration_y = 0
   }
   if obj.type == "player" then
      data.standing_state = obj.standing_state
      if obj.is_in_pushback then data.pushback_start_index = gamestate.frame_number - obj.pushback_start_frame end
   end
   return {[0] = data}
end

local function create_line(obj, n)
   local line = {}
   for i = 1, n do
      line[#line + 1] = {animation = obj.animation or obj.projectile_type, frame = obj.animation_frame + i, delta = i}
   end
   return line
end

local function print_pline(line)
   if line then
      local str = ""
      for i = 1, #line do
         str = str .. string.format("%s %d %d -> ", line[i].animation, line[i].frame, line[i].delta)
      end
      print(str)
   end
end

local function update_player_animation(previous_input, player)
   if player.has_animation_just_changed then next_animation[player.id] = animations.NONE end
   -- animation changes next frame
   if player.has_just_blocked then
      if not tools.is_pressing_down(player, previous_input) then
         if not player.received_connection_is_projectile and player.other.pos_y >=
             fd.character_specific[player.char_str].height.standing.min - 56 then
            next_animation[player.id] = animations.BLOCK_HIGH_AIR
         else
            next_animation[player.id] = animations.BLOCK_HIGH
         end
      else
         next_animation[player.id] = animations.BLOCK_LOW
      end
   elseif player.has_just_parried then
      if player.parry_forward.success or player.parry_antiair.success then
         next_animation[player.id] = animations.PARRY_HIGH
      elseif player.parry_down.success then
         next_animation[player.id] = animations.PARRY_LOW
      elseif player.parry_air.success then
         next_animation[player.id] = animations.PARRY_AIR
      end
   end
   local player_framedata = fd.frame_data[player.char_str]
   if player.animation == player_framedata.parry_low and not tools.is_pressing_down(player, previous_input) then
      if player.animation_frame == #player.animation_frame_data.frames - 1 then
         next_animation[player.id] = animations.STANDING_BEGIN
      end
   elseif player.animation == player_framedata.parry_high and tools.is_pressing_down(player, previous_input) then
      if player.animation_frame == #player.animation_frame_data.frames - 1 then
         next_animation[player.id] = animations.CROUCHING_BEGIN
      end
   end
end

local function predict_next_animation(player, input)
   local player_framedata = fd.frame_data[player.char_str]
   local animation = animations.NONE
   if player.is_standing then
      if tools.is_pressing_down(player, input) then
         if player.is_idle then animation = animations.CROUCHING_BEGIN end
      elseif tools.is_pressing_forward(player, input) then
         if player.action == 0 or player.action == 23 or player.action == 29 or player.action == 30 then
            animation = animations.WALK_FORWARD
         elseif player.action == 3 then
            animation = animations.WALK_TRANSITION
         end
      elseif tools.is_pressing_back(player, input) then
         if player.is_idle then
            if player.blocking and player.blocking.last_block and player.blocking.last_block.blocking_type == "player" and
                player.pos_y >= fd.character_specific[player.char_str].height.standing.min - 56 then
               animation = animations.BLOCK_HIGH_AIR_PROXIMITY
            else
               animation = animations.BLOCK_HIGH_PROXIMITY
            end
         end
      end
   elseif player.is_crouching then
      if not tools.is_pressing_down(player, input) then
         if player.is_idle then animation = animations.STANDING_BEGIN end
      elseif tools.is_pressing_back(player, input) then
         if player.is_idle then animation = animations.BLOCK_LOW_PROXIMITY end
      end
   end
   local recovery_time = player.recovery_time + player.additional_recovery_time
   if recovery_time > 0 and recovery_time <= 1 then
      if player.animation == player_framedata.block_low and not tools.is_pressing_down(player, input) then
         animation = animations.STANDING_BEGIN
      elseif (player.animation == player_framedata.block_high or player.animation == player_framedata.block_high_air) and
          tools.is_pressing_down(player, input) then
         animation = animations.CROUCHING_BEGIN
      end
   end
   return animation
end

local function get_next_animation(player, animation)
   local player_framedata = fd.frame_data[player.char_str]
   if animation == animations.WALK_FORWARD then
      return player_framedata.walk_forward
   elseif animation == animations.WALK_BACK then
      return player_framedata.walk_back
   elseif animation == animations.WALK_TRANSITION then
      return player_framedata.walk_transition
   elseif animation == animations.STANDING_BEGIN then
      return player_framedata.standing_begin
   elseif animation == animations.CROUCHING_BEGIN then
      return player_framedata.crouching_begin
   elseif animation == animations.BLOCK_HIGH_PROXIMITY then
      return player_framedata.block_high_proximity
   elseif animation == animations.BLOCK_HIGH then
      return player_framedata.block_high
   elseif animation == animations.BLOCK_HIGH_AIR_PROXIMITY then
      return player_framedata.block_high_air_proximity
   elseif animation == animations.BLOCK_HIGH_AIR then
      return player_framedata.block_high_air
   elseif animation == animations.BLOCK_LOW_PROXIMITY then
      return player_framedata.block_low_proximity
   elseif animation == animations.BLOCK_LOW then
      return player_framedata.block_low
   elseif animation == animations.PARRY_HIGH then
      return player_framedata.parry_high
   elseif animation == animations.PARRY_LOW then
      return player_framedata.parry_low
   elseif animation == animations.PARRY_AIR then
      return player_framedata.parry_air
   else
      return player.animation
   end
end

local function insert_projectile(gs, player, projectile_data)
   local proj_fdata = fd.find_move_frame_data("projectiles", projectile_data.type)
   if proj_fdata then
      local obj = {base = 0, projectile = 99}
      obj.id = projectile_data.type .. "_" .. player.id .. tostring(gs.frame_number)
      obj.emitter_id = player.id
      obj.alive = true
      obj.projectile_type = projectile_data.type
      obj.projectile_start_type = obj.projectile_type
      obj.animation = obj.projectile_type
      obj.pos_x = player.pos_x + projectile_data.offset[1] * tools.flip_to_sign(player.flip_x)
      obj.pos_y = player.pos_y + projectile_data.offset[2]
      obj.velocity_x = 0
      obj.velocity_y = 0
      obj.acceleration_x = 0
      obj.acceleration_y = 0
      if proj_fdata.frames[1].velocity then
         obj.velocity_x = proj_fdata.frames[1].velocity[1]
         obj.velocity_y = proj_fdata.frames[1].velocity[2]
      end
      if proj_fdata.frames[1].acceleration then
         obj.acceleration_x = proj_fdata.frames[1].acceleration[1]
         obj.acceleration_y = proj_fdata.frames[1].acceleration[2]
      end
      obj.flip_x = player.flip_x
      obj.boxes = {}
      obj.expired = false
      obj.previous_remaining_hits = 99
      obj.remaining_hits = 99
      obj.is_forced_one_hit = false
      obj.has_activated = false
      obj.animation_start_frame = gs.frame_number
      obj.animation_frame = 0
      obj.animation_freeze_frames = 0
      obj.remaining_freeze_frames = 0
      obj.remaining_lifetime = 0
      obj.lifetime = 0
      obj.cooldown = 0
      obj.is_placeholder = true
      gs.projectiles[obj.id] = obj
   end
end

local function get_horizontal_box_overlap(a_box, ax, ay, a_flip, b_box, bx, by, b_flip)
   local a_l, b_l

   if a_flip == 0 then
      a_l = ax + a_box.left
   else
      a_l = ax - a_box.left - a_box.width
   end
   local a_r = a_l + a_box.width
   local a_b = ay + a_box.bottom
   local a_t = a_b + a_box.height

   if b_flip == 0 then
      b_l = bx + b_box.left
   else
      b_l = bx - b_box.left - b_box.width
   end
   local b_r = b_l + b_box.width
   local b_b = by + b_box.bottom
   local b_t = b_b + b_box.height

   if (a_r >= b_l) and (a_l <= b_r) and (a_t >= b_b) and (a_b <= b_t) then
      return math.min(a_r, b_r) - math.max(a_l, b_l)
   end
   return 0
end

local function get_push_value(dist_from_pb_center, pushbox_overlap_range, push_value_max)
   local p = dist_from_pb_center / pushbox_overlap_range
   if p < .7 then
      local range = math.floor(.7 * pushbox_overlap_range)
      return tools.round((range - dist_from_pb_center) / range * (push_value_max - 6) + 6)
   elseif p < .76 then
      return 4
   elseif p < .82 then
      return 3
   elseif p < .86 then
      return 2
   elseif p < .98 then
      return 1
   end
   return 0
end

local function predict_pushbox_pushback(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
   local motion_data = {[p1] = p1_motion_data, [p2] = p2_motion_data}
   local lines = {[p1] = p1_line, [p2] = p2_line}
   local stage = stages[gamestate.stage]

   local pushboxes = {}

   for _, player in ipairs({p1, p2}) do
      local fdata = find_move_frame_data(player.char_str, lines[player][index].animation)
      if fdata and fdata.frames and fdata.frames[lines[player][index].frame + 1] and
          fdata.frames[lines[player][index].frame + 1].boxes then
         local boxes = tools.get_boxes(fdata.frames[lines[player][index].frame + 1].boxes, {"push"})
         if #boxes > 0 then pushboxes[player] = boxes[1] end
      end
      if not pushboxes[player] then pushboxes[player] = tools.get_pushboxes(player) end
   end

   if pushboxes[p1] and pushboxes[p2] then
      pushboxes[p1] = tools.format_box(pushboxes[p1])
      pushboxes[p2] = tools.format_box(pushboxes[p2])

      local p1_mdata = motion_data[p1][index]
      local p2_mdata = motion_data[p2][index]

      local overlap = get_horizontal_box_overlap(pushboxes[p1], math.floor(p1_mdata.pos_x), math.floor(p1_mdata.pos_y),
                                                 p1_mdata.flip_x, pushboxes[p2], math.floor(p2_mdata.pos_x),
                                                 math.floor(p2_mdata.pos_y), p2_mdata.flip_x)

      if overlap > 1 then
         local push_value_max = math.ceil((character_specific[p1.char_str].push_value +
                                              character_specific[p2.char_str].push_value) / 2)
         local dist_from_pb_center = math.abs(p1_mdata.pos_x - p2_mdata.pos_x)
         local pushbox_overlap_range = (pushboxes[p1].width + pushboxes[p2].width) / 2
         local push_value = get_push_value(dist_from_pb_center, pushbox_overlap_range, push_value_max)

         local sign = (math.floor(p2_mdata.pos_x) - math.floor(p1_mdata.pos_x) >= 0 and -1) or
                          (math.floor(p2_mdata.pos_x) - math.floor(p1_mdata.pos_x) < 0 and 1)
         p1_mdata.pos_x = p1_mdata.pos_x + push_value * sign
         p2_mdata.pos_x = p2_mdata.pos_x - push_value * sign

         for player, mdata in pairs(motion_data) do
            local corner_left = stage.left + character_specific[player.char_str].corner_offset_left
            local corner_right = stage.right - character_specific[player.char_str].corner_offset_right
            if mdata[index].pos_x > corner_right then
               local mantissa = mdata[index].pos_x - math.floor(mdata[index].pos_x)
               mdata[index].pos_x = corner_right + mantissa
            elseif mdata[index].pos_x < corner_left then
               local mantissa = mdata[index].pos_x - math.floor(mdata[index].pos_x)
               mdata[index].pos_x = corner_left + mantissa
            end
         end
      end
   end
end

local function predict_switch_sides(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
   local motion_data = {[p1] = p1_motion_data, [p2] = p2_motion_data}
   for player, mdata in pairs(motion_data) do
      local other_mdata = motion_data[player.other]
      local previous_dist = math.floor(other_mdata[index - 1].pos_x) - math.floor(mdata[index - 1].pos_x)
      local dist = math.floor(other_mdata[index].pos_x) - math.floor(mdata[index].pos_x)
      if tools.sign(previous_dist) ~= tools.sign(dist) and dist ~= 0 then
         mdata[index].switched_sides = true
         mdata[index].should_turn = true
      end
   end
end

local function predict_next_player_movement(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
   local motion_data = {[p1] = p1_motion_data, [p2] = p2_motion_data}
   local lines = {[p1] = p1_line, [p2] = p2_line}

   local stage = stages[gamestate.stage]

   for player, mdata in pairs(motion_data) do
      mdata[index] = copytable(mdata[index - 1])
      if player.remaining_freeze_frames - index == 0 and player.remaining_freeze_frames - (index - 1) > 0 then
         mdata[index].freeze_just_ended = true
      else
         mdata[index].freeze_just_ended = false
      end
      if mdata[index - 1].freeze_just_ended and player.character_state_byte == 1 then
         mdata[index].pushback_start_index = index
      end

      if mdata[index - 1].should_turn then
         if player.remaining_freeze_frames + player.recovery_time - index < 0 then
            local anim = lines[player][index - 1].animation
            local target_anim = nil
            if anim == fd.frame_data[player.char_str].standing or --
            anim == fd.frame_data[player.char_str].walk_back or --
            anim == fd.frame_data[player.char_str].block_high then
               target_anim = fd.frame_data[player.char_str].standing_turn
            elseif anim == fd.frame_data[player.char_str].crouching then
               target_anim = fd.frame_data[player.char_str].crouching_turn
            else
               mdata[index].should_turn = nil
            end
            if target_anim then
               local line = predict_frames_branching(player, target_anim, 0, #lines[player] - index + 1, true)[1]
               for j = 1, #line do lines[player][index + j - 1] = line[j] end

               mdata[index].flip_x = bit.bxor(mdata[index - 1].flip_x, 1)
               if target_anim.velocity then
                  mdata[index].velocity_x = target_anim.velocity[1]
                  mdata[index].velocity_y = target_anim.velocity[2]
               end
               mdata[index].should_turn = nil
            end
         end
      end
   end

   for player, mdata in pairs(motion_data) do
      local corner_left = stage.left + character_specific[player.char_str].corner_offset_left
      local corner_right = stage.right - character_specific[player.char_str].corner_offset_right
      local sign = tools.flip_to_sign(mdata[index - 1].flip_x)

      local is_in_pushback = player.is_in_pushback
      local pb_frame = 0

      for i = #mdata, 0, -1 do
         if mdata[i].pushback_start_index then
            is_in_pushback = true
            pb_frame = index - mdata[i].pushback_start_index + 1
            break
         end
      end

      if is_in_pushback then
         local anim = player.last_received_connection_animation
         local hit_id = player.last_received_connection_hit_id
         if anim and hit_id and fd.frame_data[player.other.char_str][anim] and
             fd.frame_data[player.other.char_str][anim].pushback and
             fd.frame_data[player.other.char_str][anim].pushback[hit_id] and pb_frame <=
             #fd.frame_data[player.other.char_str][anim].pushback[hit_id] then
            local pb_value = fd.frame_data[player.other.char_str][anim].pushback[hit_id][pb_frame]

            if pb_value then
               local new_pos = mdata[index].pos_x - sign * pb_value
               local over_push = 0

               if new_pos < corner_left then
                  over_push = corner_left - new_pos
               elseif new_pos > corner_right then
                  over_push = new_pos - corner_right
               end
               if over_push > 0 then
                  motion_data[player.other][index].pos_x = motion_data[player.other][index].pos_x + over_push * sign
               end
               mdata[index].pos_x = mdata[index].pos_x - (pb_value - over_push) * sign

            end
         end
      end

      local should_apply_velocity = false
      local current_anim = lines[player][index] and lines[player][index].animation
      local current_anim_frame = lines[player][index] and lines[player][index].frame + 1

      local current_frame_data = find_move_frame_data(player.char_str, current_anim)
      local current_frame = current_frame_data and current_frame_data.frames[current_anim_frame]
      -- local previous_frame_data = find_move_frame_data(player.char_str, lines[player][index - 1].animation)
      -- local previous_frame = previous_frame_data and previous_frame_data.frames and
      --                            previous_frame_data.frames[lines[player][index - 1].frame + 1]
      local first_frame_of_air_attack = lines[player][index].frame == 0 and current_frame_data and
                                            current_frame_data.air
      local should_ignore_motion = current_frame and current_frame.ignore_motion

      -- first frame of every air move ignores velocity/acceleration
      if first_frame_of_air_attack then
         should_ignore_motion = true
      else
         if (current_frame_data and current_frame_data.uses_velocity) or mdata[index - 1].pos_y > 0 then -- change this to use standing_state
            should_apply_velocity = true
         end
      end

      if not should_ignore_motion then
         mdata[index].velocity_x = mdata[index].velocity_x + mdata[index - 1].acceleration_x
         mdata[index].velocity_y = mdata[index].velocity_y + mdata[index - 1].acceleration_y

         if current_frame then
            if current_frame.movement then
               mdata[index].pos_x = mdata[index].pos_x + current_frame.movement[1] * sign
               mdata[index].pos_y = mdata[index].pos_y + current_frame.movement[2]
            end
            if current_frame.velocity then
               mdata[index].velocity_x = mdata[index].velocity_x + current_frame.velocity[1]
               mdata[index].velocity_y = mdata[index].velocity_y + current_frame.velocity[2]
            end
            if current_frame.acceleration then
               mdata[index].acceleration_x = mdata[index].acceleration_x + current_frame.acceleration[1]
               mdata[index].acceleration_y = mdata[index].acceleration_y + current_frame.acceleration[2]
            end
         end
      end

      if current_frame then
         if current_frame.clear_motion then
            mdata[index].velocity_x = 0
            mdata[index].velocity_y = 0
            mdata[index].acceleration_x = 0
            mdata[index].acceleration_y = 0
            should_apply_velocity = false
         end
         if not should_ignore_motion and should_apply_velocity then
            mdata[index].pos_x = mdata[index].pos_x + mdata[index - 1].velocity_x * sign
            mdata[index].pos_y = mdata[index].pos_y + mdata[index - 1].velocity_y
         end
         if current_frame.set_acceleration then
            mdata[index].acceleration_x = current_frame.set_acceleration[1]
            mdata[index].acceleration_y = current_frame.set_acceleration[2]
         end
         if current_frame.set_velocity then
            mdata[index].velocity_x = current_frame.set_velocity[1]
            mdata[index].velocity_y = current_frame.set_velocity[2]
         end
      end

      if mdata[index].pos_x > corner_right then
         local mantissa = mdata[index].pos_x - math.floor(mdata[index].pos_x)
         mdata[index].pos_x = corner_right + mantissa
      elseif mdata[index].pos_x < corner_left then
         local mantissa = mdata[index].pos_x - math.floor(mdata[index].pos_x)
         mdata[index].pos_x = corner_left + mantissa
      end

      -- if player is falling
      if current_frame_data and mdata[index].pos_y < mdata[index - 1].pos_y then
         local should_land = false
         -- this is a guess at when landing will occur. not sure what the actual principle is
         -- moves like dudley's jump HK/HP allow the player to fall much lower before landing. y_pos of -30 for dudley's j.HP!
         if current_frame_data.landing_height then
            if mdata[index].pos_y < current_frame_data.landing_height then should_land = true end
         elseif mdata[index].pos_y < 0 then
            should_land = true
         end
         if should_land then
            mdata[index].pos_y = 0
            mdata[index].standing_state = 1
            mdata[index].has_just_landed = true
            -- there are specific recovery frames for special moves, but this is good enough for now
            local line = predict_frames_branching(player, fd.frame_data[player.char_str].jump_recovery, 0,
                                                  #lines[player] - index + 1, true)[1]
            if line then for j = 1, #line do lines[player][index + j - 1] = line[j] end end
         end
      end
   end

   -- don't allow side switches if grounded
   for player, mdata in pairs(motion_data) do
      if mdata[index].pos_y == 0 and motion_data[player.other][index].pos_y == 0 then
         if tools.sign(mdata[index - 1].pos_x - motion_data[player.other][index - 1].pos_x) ~=
             tools.sign(mdata[index].pos_x - motion_data[player.other][index].pos_x) then
            local sign = tools.sign(mdata[index - 1].pos_x - motion_data[player.other][index].pos_x)
            mdata[index].pos_x = motion_data[player.other][index].pos_x + sign
         end
      end
   end
   predict_pushbox_pushback(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
   predict_switch_sides(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
end

local function filter_lines(player, lines)
   local filtered = {}
   for _, line in pairs(lines) do
      local pass = false
      for i = 1, #line do
         local predicted_frame = line[i]
         local frame = predicted_frame.frame
         local frame_to_check = frame + 1
         local fdata = find_move_frame_data(player.char_str, predicted_frame.animation)

         if fdata then
            if fdata.frames and fdata.frames[frame_to_check] and fdata.frames[frame_to_check].projectile then
               pass = true
               break
            end

            if fdata.hit_frames then
               local next_hit_id = 1
               for i = 1, #fdata.hit_frames do
                  if frame > fdata.hit_frames[i][2] then next_hit_id = i + 1 end
               end
               if next_hit_id > player.current_hit_id then
                  pass = true
                  break
               end
            end
         end
      end
      if pass then filtered[#filtered + 1] = line end
   end
   return filtered
end

local function predict_jump_arc(player, player_anim, player_frame, player_motion_data, dummy, dummy_anim, dummy_frame,
                                dummy_motion_data, frames_prediction)
   local specify_frame = player_anim and player_frame
   local player_lines = predict_frames_branching(player, player_anim, player_frame, frames_prediction, specify_frame)
   local filtered = filter_lines(player, player_lines) or {}

   if #filtered > 0 and #filtered[1] > 0 then
      player_lines = filtered
   else
      if player_lines[1] and #player_lines[1] > 0 then
         player_lines = {player_lines[1]}
      else
         player_lines = {create_line(player, frames_prediction)}
      end
   end
   local player_line = player_lines[1]
   player_line[0] = {animation = player.animation, frame = player.animation_frame, delta = 0}

   specify_frame = dummy_anim and dummy_frame
   local dummy_line = predict_frames_branching(dummy, dummy_anim, dummy_frame, frames_prediction, specify_frame)[1]
   if not dummy_line or #dummy_line == 0 then dummy_line = create_line(dummy, frames_prediction) end
   dummy_line[0] = {animation = dummy.animation, frame = dummy.animation_frame, delta = 0}

   player_motion_data = player_motion_data or init_motion_data(player)
   dummy_motion_data = dummy_motion_data or init_motion_data(dummy)
   player_motion_data[0].switched_sides = check_switch_sides(player)
   dummy_motion_data[0].switched_sides = check_switch_sides(dummy)

   local predicted_state = {
      player_motion_data = player_motion_data,
      player_line = player_line,
      dummy_motion_data = dummy_motion_data,
      dummy_line = dummy_line
   }

   for i = 1, #player_line do
      local predicted_frame = player_line[i]
      local frame = predicted_frame.frame
      local frame_to_check = frame + 1
      local fdata = find_move_frame_data(player.char_str, predicted_frame.animation)

      predict_next_player_movement(player, player_motion_data, player_line, dummy, dummy_motion_data, dummy_line, i)

      if player_motion_data[i].has_just_landed then break end

      if fdata then
         local frames = fdata.frames
         if frames and frames[frame_to_check] then
            if frames[frame_to_check].projectile and (player.remaining_freeze_frames - i <= 0) then
               insert_projectile(player, player_motion_data[i], predicted_frame)
            end

            if fdata.hit_frames and frames[frame_to_check].boxes and
                tools.has_boxes(frames[frame_to_check].boxes, {"attack", "throw"}) then

               local should_test = false
               local current_hit_id = player.current_hit_id
               local next_hit_id = 1

               for j = 1, #fdata.hit_frames do
                  if frame > fdata.hit_frames[j][2] then
                     next_hit_id = math.min(j + 1, #fdata.hit_frames)
                  end
               end
               if fdata.infinite_loop then
                  current_hit_id = (player.animation_miss_count + player.animation_connection_count) % #fdata.hit_frames
                  if #fdata.hit_frames == 1 then should_test = true end
               end
               if predicted_frame.animation ~= player.animation then current_hit_id = 0 end

               if next_hit_id > current_hit_id then should_test = true end
               if fdata.infinite_loop and
                   (player.animation_connection_count + player.animation_miss_count >= fdata.max_hits) then
                  should_test = false
               end

               if should_test then
                  local remaining_freeze = player.remaining_freeze_frames - i
                  local remaining_cooldown = player.cooldown
                  if remaining_freeze <= 0 then
                     remaining_cooldown = math.max(remaining_cooldown + remaining_freeze, 0)
                  end

                  local dummy_boxes = get_hurtboxes(dummy.char_str, dummy_line[i].animation, dummy_line[i].frame)
                  if #dummy_boxes == 0 then dummy_boxes = dummy.boxes end

                  if debug_settings.debug_hitboxes and i <= 100 then
                     local attack_boxes = tools.get_boxes(frames[frame_to_check].boxes, {"attack"})
                     local extended = require("src.settings").training.display_hitboxes_ab
                     require("src.debug").queue_hitbox_draw(gamestate.frame_number + predicted_frame.delta, {
                        player_motion_data[i].pos_x, player_motion_data[i].pos_y, player_motion_data[i].flip_x,
                        attack_boxes, extended, nil, nil, 0xFF941CDD
                     }, "attack")
                     local color = 0x44097000 + 255 - math.floor(100 * (frames_prediction - i) / frames_prediction)
                     require("src.debug").queue_hitbox_draw(gamestate.frame_number + predicted_frame.delta, {
                        dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, dummy_motion_data[i].flip_x,
                        dummy_boxes, extended, nil, nil, color
                     }, "vuln")
                  end

                  local box_type_matches = {{{"vulnerability", "ext_vulnerability"}, {"attack"}}}
                  if frame_data_meta[player.char_str][predicted_frame.animation] and
                      frame_data_meta[player.char_str][predicted_frame.animation].hit_throw then
                     box_type_matches[#box_type_matches + 1] = {{"throwable"}, {"throw"}}
                  end

                  if tools.test_collision(dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y,
                                          dummy_motion_data[i].flip_x, dummy_boxes, player_motion_data[i].pos_x,
                                          player_motion_data[i].pos_y, player_motion_data[i].flip_x,
                                          frames[frame_to_check].boxes, box_type_matches) then break end
               end
            end
         end
      end
   end
   return predicted_state
end
-- EX Aegis and Ibuki SA1
local first_hit_frame_exceptions = {
   ["70"] = true,
   ["25"] = true,
   ["26"] = true,
   ["27"] = true,
   ["28"] = true,
   ["29"] = true,
   ["2A"] = true,
   ["2B"] = true,
   ["2C"] = true,
   ["2D"] = true,
   ["2E"] = true,
   ["2F"] = true,
   ["30"] = true,
   ["31"] = true,
   ["32"] = true,
   ["33"] = true,
   ["34"] = true,
   ["35"] = true,
   ["36"] = true
}

local function predict_player_movement(player, player_anim, player_frame, player_motion_data, dummy, dummy_anim,
                                       dummy_frame, dummy_motion_data, frames_prediction)
   -- returns all possible sequences of the next 3 frames
   local specify_frame = player_anim and player_frame
   local player_lines = predict_frames_branching(player, player_anim, player_frame, frames_prediction, specify_frame)
   -- filter for lines that contain hit frames or projectiles
   local filtered = filter_lines(player, player_lines) or {}

   if #filtered > 0 and #filtered[1] > 0 then
      player_lines = filtered
   else
      if player_lines[1] and #player_lines[1] > 0 then
         player_lines = {player_lines[1]}
      else
         player_lines = {create_line(player, frames_prediction)}
      end
   end
   local player_line = player_lines[1]
   player_line[0] = {animation = player.animation, frame = player.animation_frame, delta = 0}

   specify_frame = dummy_anim and dummy_frame
   local dummy_line = predict_frames_branching(dummy, dummy_anim, dummy_frame, frames_prediction, specify_frame)[1]
   if not dummy_line or #dummy_line == 0 then dummy_line = create_line(dummy, frames_prediction) end
   dummy_line[0] = {animation = dummy.animation, frame = dummy.animation_frame, delta = 0}

   player_motion_data = player_motion_data or init_motion_data(player)
   dummy_motion_data = dummy_motion_data or init_motion_data(dummy)
   player_motion_data[0].switched_sides = check_switch_sides(player)
   dummy_motion_data[0].switched_sides = check_switch_sides(dummy)

   local predicted_state = {
      player_motion_data = player_motion_data,
      player_line = player_line,
      dummy_motion_data = dummy_motion_data,
      dummy_line = dummy_line
   }

   for i = 1, #player_line do
      predict_next_player_movement(player, player_motion_data, player_line, dummy, dummy_motion_data, dummy_line, i)
   end

   return predicted_state
end

local function update_before(previous_input, dummy)
   local player = dummy.other
   update_player_animation(previous_input, player)
   update_player_animation(previous_input, dummy)
end

local function update_after(input, dummy)
   local player = dummy.other
   next_animation[player.id] = predict_next_animation(player, input)
   next_animation[dummy.id] = predict_next_animation(dummy, input)
end

local function update_frame_data(gs, obj, frame_data)
   obj.animation = frame_data.animation
   if obj.type == "projectile" then obj.projectile_type = frame_data.animation end
   obj.animation_frame = frame_data.frame
   if frame_data.frame_data then
      obj.animation_frame_data = frame_data.frame_data
   else
      local new_fdata
      if obj.type == "player" then
         new_fdata = fd.frame_data[obj.char_str][obj.animation]
      else
         new_fdata = fd.frame_data["projectiles"][obj.animation]
      end
      obj.animation_frame_data = new_fdata or obj.animation_frame_data
   end
   obj.boxes = obj.animation_frame_data and obj.animation_frame_data.frames and
                   obj.animation_frame_data.frames[obj.animation_frame + 1] and
                   obj.animation_frame_data.frames[obj.animation_frame + 1].boxes or obj.boxes
   obj.has_animation_just_changed = false
   if obj.type == "player" and obj.animation ~= gs.previous_gamestate[obj.prefix].animation then
      obj.has_animation_just_changed = true
      obj.current_hit_id = 0
      obj.animation_action_count = 0
      obj.animation_miss_count = 0
      obj.animation_connection_count = 0
   end
end

local function update_variables(gs)
   local previous_gs = gs.previous_gamestate
   gs.frame_number = gs.frame_number + 1
   for _, player in ipairs(gs.player_objects) do
      player.previous_pos_x = previous_gs and previous_gs[player.prefix].pos_x or player.previous_pos_x
      player.previous_pos_y = previous_gs and previous_gs[player.prefix].pos_y or player.previous_pos_y
      player.previous_remaining_freeze_frames = player.remaining_freeze_frames or 0
      player.remaining_freeze_frames = math.max(player.remaining_freeze_frames - 1, 0)
      if previous_gs and previous_gs[player.prefix].just_received_connection then
         player.remaining_freeze_frames = player.other.remaining_freeze_frames
      end
      if player.freeze_just_ended and player.character_state_byte == 1 and player.recovery_time == 0 then
         player.recovery_time = 10 -- replace with value from framedata
         if player.is_blocking then
            player.additional_recovery_time = gamestate.get_additional_recovery_delay(player.char_str,
                                                                                      player.is_crouching)
         end
         player.is_in_recovery = true
         player.is_in_pushback = true
         player.pushback_start_frame = gs.frame_number
      end
      player.freeze_just_began = false
      player.freeze_just_ended = false
      if player.remaining_freeze_frames == 0 and player.previous_remaining_freeze_frames > 0 then
         player.freeze_just_ended = true
      end
      if player.remaining_freeze_frames > 0 then
         if player.previous_remaining_freeze_frames == 0 then player.freeze_just_began = true end
         player.animation_freeze_frames = player.animation_freeze_frames + 1
      end
      if player.ends_recovery_next_frame then
         player.has_just_ended_recovery = true
         player.character_state_byte = 0
         player.ends_recovery_next_frame = false
      end
      player.previous_recovery_time = player.recovery_time
      if player.recovery_time > 0 then player.recovery_time = player.recovery_time - 1 end
      if player.recovery_time == 0 and player.previous_recovery_time > 0 then
         player.ends_recovery_next_frame = true
      end
      if player.freeze_just_began or
          (player.is_in_pushback and not player.freeze_just_ended and player.recovery_time == 0) then
         player.is_in_pushback = false
      end
      if player.freeze_just_ended and player.movement_type == 1 then
         player.pushback_start_frame = gs.frame_number
         player.is_in_pushback = true
      end
      if player.remaining_freeze_frames == 0 and not player.freeze_just_ended then
         player.cooldown = math.max(player.cooldown - 1, 0)
      end
      player.just_received_connection = false
      player.has_just_landed = false
   end

   local to_remove = {}
   for _, projectile in pairs(gs.projectiles) do
      projectile.lifetime = projectile.lifetime + 1
      projectile.previous_remaining_freeze_frames = projectile.remaining_freeze_frames
      projectile.remaining_freeze_frames = math.max(projectile.remaining_freeze_frames - 1, 0)
      projectile.freeze_just_began = false
      if projectile.remaining_freeze_frames > 0 then
         if projectile.previous_remaining_freeze_frames == 0 then projectile.freeze_just_began = true end
         projectile.animation_freeze_frames = projectile.animation_freeze_frames + 1
      end
      if projectile.cooldown > 0 and
          ((projectile.remaining_freeze_frames == 0 or projectile.freeze_just_began) or projectile.projectile_type ==
              "72") then projectile.cooldown = projectile.cooldown - 1 end
      if projectile.is_placeholder and gs.frame_number > projectile.animation_start_frame then
         to_remove[#to_remove + 1] = projectile.id
      end
   end
   for _, key in ipairs(to_remove) do gs.projectiles[key] = nil end
end

local function update_turn(gs)
   local previous_gs = gs.previous_gamestate
   for _, player in ipairs(gs.player_objects) do
      if player.should_turn then
         if player.remaining_freeze_frames + player.recovery_time + player.additional_recovery_time == 0 then
            player.flip_x = bit.bxor(previous_gs[player.prefix].flip_x, 1)
            local anim = previous_gs[player.prefix].animation
            local target_anim = nil
            if anim == fd.frame_data[player.char_str].standing or --
            anim == fd.frame_data[player.char_str].walk_back or --
            anim == fd.frame_data[player.char_str].block_high then
               target_anim = fd.frame_data[player.char_str].standing_turn
            elseif anim == fd.frame_data[player.char_str].crouching then
               target_anim = fd.frame_data[player.char_str].crouching_turn
            else
               player.should_turn = nil
            end
            if target_anim then
               update_frame_data(gs, player, {
                  animation = target_anim,
                  frame = 0,
                  frame_data = find_move_frame_data(player.char_str, target_anim)
               })
               if target_anim.velocity then
                  player.velocity_x = target_anim.velocity[1]
                  player.velocity_y = target_anim.velocity[2]
               end
               player.should_turn = nil
            end
         end
      end
   end
end

local function move_players(gs)
   local stage = stages[gs.stage]

   for _, player in ipairs(gs.player_objects) do
      if player.remaining_freeze_frames == 0 and not player.freeze_just_ended then
         local corner_left = stage.left + character_specific[player.char_str].corner_offset_left
         local corner_right = stage.right - character_specific[player.char_str].corner_offset_right
         local sign = tools.flip_to_sign(player.flip_x)

         if player.is_in_pushback then
            local pb_frame = gs.frame_number - player.pushback_start_frame
            local anim = player.last_received_connection_animation
            local hit_id = player.last_received_connection_hit_id
            if anim and hit_id and fd.frame_data[player.other.char_str][anim] and
                fd.frame_data[player.other.char_str][anim].pushback and
                fd.frame_data[player.other.char_str][anim].pushback[hit_id] and pb_frame <=
                #fd.frame_data[player.other.char_str][anim].pushback[hit_id] then
               local pb_value = fd.frame_data[player.other.char_str][anim].pushback[hit_id][pb_frame]
               if pb_value then
                  local new_pos = player.pos_x - sign * pb_value
                  local over_push = 0

                  if new_pos < corner_left then
                     over_push = corner_left - new_pos
                  elseif new_pos > corner_right then
                     over_push = new_pos - corner_right
                  end
                  if over_push > 0 then player.other.pos_x = player.other.pos_x + over_push * sign end
                  player.pos_x = player.pos_x - (pb_value - over_push) * sign
               end
            end
         end
         local should_apply_velocity = false

         local current_frame = player.animation_frame_data and
                                   player.animation_frame_data.frames[player.animation_frame + 1]
         -- local previous_frame_data = find_move_frame_data(player.char_str, lines[player][index - 1].animation)
         -- local previous_frame = previous_frame_data and previous_frame_data.frames and
         --                            previous_frame_data.frames[lines[player][index - 1].frame + 1]
         local first_frame_of_air_attack = player.frame == 0 and player.animation_frame_data and
                                               player.animation_frame_data.air
         local should_ignore_motion = current_frame and current_frame.ignore_motion

         -- first frame of every air move ignores velocity/acceleration
         if first_frame_of_air_attack then
            should_ignore_motion = true
         else
            if (player.animation_frame_data and player.animation_frame_data.uses_velocity) or player.is_airborne then -- change this to use standing_state
               should_apply_velocity = true
            end
         end

         if not should_ignore_motion then
            player.velocity_x = player.velocity_x + player.acceleration_x
            player.velocity_y = player.velocity_y + player.acceleration_y

            if current_frame then
               if current_frame.movement then
                  player.pos_x = player.pos_x + current_frame.movement[1] * sign
                  player.pos_y = player.pos_y + current_frame.movement[2]
               end
               if current_frame.velocity then
                  player.velocity_x = player.velocity_x + current_frame.velocity[1]
                  player.velocity_y = player.velocity_y + current_frame.velocity[2]
               end
               if current_frame.acceleration then
                  player.acceleration_x = player.acceleration_x + current_frame.acceleration[1]
                  player.acceleration_y = player.acceleration_y + current_frame.acceleration[2]
               end
            end
         end

         if current_frame then
            if current_frame.clear_motion then
               player.velocity_x = 0
               player.velocity_y = 0
               player.acceleration_x = 0
               player.acceleration_y = 0
               should_apply_velocity = false
            end
            if not should_ignore_motion and should_apply_velocity then
               player.pos_x = player.pos_x + player.velocity_x * sign
               player.pos_y = player.pos_y + player.velocity_y
            end
            if current_frame.set_acceleration then
               player.acceleration_x = current_frame.set_acceleration[1]
               player.acceleration_y = current_frame.set_acceleration[2]
            end
            if current_frame.set_velocity then
               player.velocity_x = current_frame.set_velocity[1]
               player.velocity_y = current_frame.set_velocity[2]
            end
         end

         if player.pos_x > corner_right then
            local mantissa = player.pos_x - math.floor(player.pos_x)
            player.pos_x = corner_right + mantissa
         elseif player.pos_x < corner_left then
            local mantissa = player.pos_x - math.floor(player.pos_x)
            player.pos_x = corner_left + mantissa
         end
         --          local d = gs.frame_number - gamestate.frame_number
         -- require("src.debug").add_debug_variable(d .. " " .. 
         -- player.prefix, function () return player.pos_x end) --debug
         -- if player is falling
         if player.animation_frame_data and player.pos_y < player.previous_pos_y then
            local should_land = false
            -- this is a guess at when landing will occur. not sure what the actual principle is
            -- moves like dudley's jump HK/HP allow the player to fall much lower before landing. y_pos of -30 for dudley's j.HP!
            if player.animation_frame_data.landing_height then
               if player.pos_y < player.animation_frame_data.landing_height then should_land = true end
            elseif player.pos_y < 0 then
               should_land = true
            end
            if should_land then
               player.pos_y = 0
               player.standing_state = 1
               player.has_just_landed = true
               player.is_airborne = false
               player.is_in_air_recovery = false
               player.is_in_air_reel = false
               local landing_animation = player.animation_frame_data.landing_anim or
                                             fd.frame_data[player.char_str].jump_recovery or player.animation
               update_frame_data(gs, player, {
                  animation = landing_animation,
                  frame = 0,
                  frame_data = find_move_frame_data(player.char_str, landing_animation)
               })
            end
         end
      end
   end
   -- don't allow side switches if grounded
   for _, player in ipairs(gs.player_objects) do
      if player.pos_y == 0 and player.other.pos_y == 0 then
         if tools.sign(player.previous_pos_x - player.other.previous_pos_x) ~=
             tools.sign(player.pos_x - player.other.pos_x) then
            local sign = tools.sign(player.previous_pos_x - player.other.previous_pos_x)
            player.pos_x = player.other.pos_x + sign
         end
      end
   end
end

local function move_projectiles(gs)
   for _, projectile in pairs(gs.projectiles) do
      if projectile.remaining_freeze_frames == 0 then
         local ignore_flip = projectile.projectile_type == "00_tenguishi"
         local sign = ignore_flip and 1 or tools.flip_to_sign(projectile.flip_x)
         if projectile.animation_frame_data then
            local current_frame = projectile.animation_frame_data.frames[projectile.animation_frame + 1]
            if current_frame then
               if current_frame.movement then
                  projectile.pos_x = projectile.pos_x + current_frame.movement[1] * sign
                  projectile.pos_y = projectile.pos_y + current_frame.movement[2]
               end
               if current_frame.velocity then
                  projectile.velocity_x = projectile.velocity_x + projectile.acceleration_x + current_frame.velocity[1]
                  projectile.velocity_y = projectile.velocity_y + projectile.acceleration_y + current_frame.velocity[2]
               end
               if current_frame.acceleration then
                  projectile.acceleration_x = projectile.acceleration_x + current_frame.acceleration[1]
                  projectile.acceleration_y = projectile.acceleration_y + current_frame.acceleration[2]
               end
            end
         end
         projectile.pos_x = projectile.pos_x + projectile.velocity_x * sign
         projectile.pos_y = projectile.pos_y + projectile.velocity_y
      end
   end
end

local function check_collisions(gs)
   gs.collisions = {}
   for _, player in ipairs(gs.player_objects) do
      local fdata = player.animation_frame_data
      if fdata then
         local delta = gs.frame_number - gamestate.frame_number
         if debug_settings.debug_hitboxes and gs.frame_number - gamestate.frame_number <=
             debug_settings.hitbox_display_frames then
            local vuln = {}
            local extended = require("src.settings").training.display_hitboxes_ab
            local color = 0x44097000 + 255 - math.floor(200 * (delta - 1) / debug_settings.hitbox_display_frames)
            if player.boxes then vuln = tools.get_boxes(player.boxes, {"vulnerability", "ext_vulnerability"}) end
            require("src.debug").queue_hitbox_draw(gamestate.frame_number, {
               player.pos_x, player.pos_y, player.flip_x, vuln, extended, nil, nil, color
            }, "movement_" .. player.prefix .. "_" .. gs.frame_number)
         end

         local frames = fdata.frames
         local frame_to_check = player.animation_frame + 1
         if frames and frames[frame_to_check] then
            if frames[frame_to_check].projectile and player.remaining_freeze_frames == 0 then
               insert_projectile(gs, player, frames[frame_to_check].projectile)
            end

            if fdata.hit_frames and frames[frame_to_check].boxes and
                tools.has_boxes(frames[frame_to_check].boxes, {"attack", "throw"}) then

               local should_test = false
               local current_hit_id = player.current_hit_id

               for i, hit_frame in ipairs(fdata.hit_frames) do
                  if player.animation_frame >= hit_frame[1] and player.animation_frame <= hit_frame[2] then
                     current_hit_id = i
                     break
                  end
               end

               if fdata.infinite_loop then
                  local next_hit_id = math.min(player.current_hit_id + 1, #fdata.hit_frames)
                  current_hit_id = (player.animation_miss_count + player.animation_connection_count) % #fdata.hit_frames
                  if #fdata.hit_frames == 1 or next_hit_id ~= current_hit_id then should_test = true end
                  if (player.animation_connection_count + player.animation_miss_count >= fdata.max_hits) then
                     should_test = false
                  end
               else
                  if current_hit_id > player.current_hit_id then should_test = true end
               end

               if player.cooldown > 0 then should_test = false end

               if should_test then
                  local defender = player.other
                  local defender_boxes = defender.boxes
                  if #defender_boxes == 0 then defender_boxes = gamestate[defender.prefix].boxes end

                  if debug_settings.debug_hitboxes and delta <= debug_settings.hitbox_display_frames then
                     local attack_boxes = tools.get_boxes(frames[frame_to_check].boxes, {"attack"})
                     local extended = require("src.settings").training.display_hitboxes_ab
                     local color = 0xFF941CDD + 255 -
                                       math.floor(200 * (delta - 1) / debug_settings.hitbox_display_frames)
                     require("src.debug").queue_hitbox_draw(gamestate.frame_number, {
                        player.pos_x, player.pos_y, player.flip_x, attack_boxes, extended, nil, nil, 0xFF941CDD
                     }, "attack_" .. player.prefix .. "_" .. gs.frame_number)
                     color = 0x44097000 + 255 - math.floor(200 * (delta - 1) / debug_settings.hitbox_display_frames)
                     require("src.debug").queue_hitbox_draw(gamestate.frame_number, {
                        defender.pos_x, defender.pos_y, defender.flip_x, defender_boxes, extended, nil, nil, color
                     }, "vuln_" .. player.prefix .. "_" .. gs.frame_number)
                  end

                  local box_type_matches = {{{"vulnerability", "ext_vulnerability"}, {"attack"}}}
                  if frame_data_meta[player.char_str][player.animation] and
                      frame_data_meta[player.char_str][player.animation].hit_throw then
                     box_type_matches[#box_type_matches + 1] = {{"throwable"}, {"throw"}}
                  end
                  if tools.test_collision(defender.pos_x, defender.pos_y, defender.flip_x, defender_boxes, player.pos_x,
                                          player.pos_y, player.flip_x, player.boxes, box_type_matches) then
                     if not (fdata.frames[player.animation_frame + 1].bypass_freeze and delta == 1) then
                        delta = delta + player.remaining_freeze_frames
                     end

                     local expected_hit = {
                        id = player.id,
                        owner_id = player.id,
                        blocking_type = "player",
                        hit_id = current_hit_id,
                        delta = delta,
                        animation = player.animation,
                        frame = player.animation_frame,
                        flip_x = player.flip_x,
                        side = player.side
                     }
                     gs.collisions[#gs.collisions + 1] = expected_hit
                  end
               end
            end
         end
      end
   end
   local has_tengu_stones = false
   local valid_projectiles = {}
   for _, projectile in pairs(gs.projectiles) do
      if projectile.projectile_type == "72" then -- EX yagyou
         valid_projectiles[#valid_projectiles + 1] = projectile
      elseif projectile.projectile_type == "00_tenguishi" then
         if projectile.remaining_freeze_frames + projectile.cooldown == 0 then
            valid_projectiles[#valid_projectiles + 1] = projectile
         end
      else
         if ((projectile.is_forced_one_hit and projectile.remaining_hits ~= 0xFF) or projectile.remaining_hits > 0) and
             projectile.alive and projectile.projectile_type ~= "00_seieienbu" then -- 00_seieienbu are the real clones, ignore them
            local defender = gs.player_objects[projectile.emitter_id].other
            if (projectile.emitter_id ~= defender.id or
                (projectile.emitter_id == defender.id and projectile.is_converted)) then
               local bypass_freeze = projectile.animation_frame_data and projectile.animation_frame_data.frames and
                                         projectile.animation_frame_data.frames[projectile.animation_frame + 1] and
                                         projectile.animation_frame_data.frames[projectile.animation_frame + 1]
                                             .bypass_freeze
               if gs.frame_number >= projectile.animation_start_frame and
                   (projectile.remaining_freeze_frames + projectile.cooldown == 0 or bypass_freeze) then
                  valid_projectiles[#valid_projectiles + 1] = projectile
               end
            end
         end
      end
   end
   for _, projectile in pairs(valid_projectiles) do
      local box_type_matches = {{{"vulnerability", "ext_vulnerability"}, {"attack"}}}
      local delta = gs.frame_number - gamestate.frame_number
      local is_first_hit_frame = false
      if projectile.projectile_type == "00_tenguishi" then
         has_tengu_stones = true
         box_type_matches = {{{"vulnerability", "ext_vulnerability", "push"}, {"attack"}}}
      elseif projectile.projectile_type == "seieienbu" then
         is_first_hit_frame = false
      else
         if projectile.animation_frame == fd.get_first_hit_frame("projectiles", projectile.projectile_type) and
             not first_hit_frame_exceptions[projectile.projectile_type] then is_first_hit_frame = true end
      end
      local owner_id = projectile.emitter_id
      if projectile.is_converted then owner_id = projectile.emitter_id == 1 and 2 or 1 end
      local defender = gs.player_objects[owner_id].other
      local defender_boxes = defender.boxes
      if #defender_boxes == 0 then defender_boxes = gamestate[defender.prefix].boxes end

      if #projectile.boxes > 0 and not is_first_hit_frame then
         if debug_settings.debug_hitboxes and delta <= debug_settings.hitbox_display_frames then
            local extended = require("src.settings").training.display_hitboxes_ab
            local color = 0xa9691c00 + 255 - math.floor(100 * (delta - 1) / debug_settings.hitbox_display_frames)
            require("src.debug").queue_hitbox_draw(gamestate.frame_number + delta, {
               projectile.pos_x, projectile.pos_y, projectile.flip_x, projectile.boxes, extended, nil, nil, color
            }, "projectile" .. projectile.id)
         end
         if tools.test_collision(defender.pos_x, defender.pos_y, defender.flip_x, defender_boxes, projectile.pos_x,
                                 projectile.pos_y, projectile.flip_x, projectile.boxes, box_type_matches) then
            local side = gs.player_objects[owner_id].side

            local expected_hit = {
               id = projectile.id,
               owner_id = owner_id,
               blocking_type = "projectile",
               hit_id = 1,
               delta = delta,
               animation = projectile.animation,
               frame = projectile.animation_frame,
               flip_x = projectile.flip_x,
               side = side
            }
            if projectile.projectile_type == "00_tenguishi" then
               expected_hit.tengu_order = projectile.tengu_order
               projectile.cooldown = 99
            elseif projectile.seiei_animation then
               expected_hit.hit_id = projectile.seiei_hit_id
               expected_hit.is_seieienbu = true
            end
            projectile.has_just_connected = true
            gs.collisions[#gs.collisions + 1] = expected_hit
         end
      end
      -- only 1 tengu stone can hit per frame, this includes oro's attacks
      if has_tengu_stones then
         local current_attack
         for _, attack in ipairs(gs.collisions) do
            if attack.blocking_type == "player" then
               current_attack = attack
               break
            elseif attack.tengu_order then
               if not current_attack or attack.tengu_order < current_attack.tengu_order then
                  current_attack = attack
               end
            end
         end
         local i = 1
         while i <= #gs.collisions do
            local attack = gs.collisions[i]
            if (attack.animation == "00_tenguishi" and attack ~= current_attack) then
               table.remove(gs.collisions, i)
            else
               i = i + 1
            end
         end
      end
   end
end

local function apply_pushback(gs)
   local stage = stages[gamestate.stage]

   local pushboxes = {}

   for _, player in ipairs(gs.player_objects) do
      if player.boxes then
         local boxes = tools.get_boxes(player.boxes, {"push"})
         if #boxes > 0 then pushboxes[player.id] = boxes[1] end
      end
      if not pushboxes[player.id] then pushboxes[player.id] = tools.get_pushboxes(gamestate[player.prefix]) end
   end

   if pushboxes[1] and pushboxes[2] then
      pushboxes[1] = tools.format_box(pushboxes[1])
      pushboxes[2] = tools.format_box(pushboxes[2])

      local overlap = get_horizontal_box_overlap(pushboxes[1], math.floor(gs.P1.pos_x), math.floor(gs.P1.pos_y),
                                                 gs.P1.flip_x, pushboxes[2], math.floor(gs.P2.pos_x),
                                                 math.floor(gs.P2.pos_y), gs.P2.flip_x)

      if overlap > 1 then
         local push_value_max = math.ceil((character_specific[gs.P1.char_str].push_value +
                                              character_specific[gs.P2.char_str].push_value) / 2)
         local dist_from_pb_center = math.abs(gs.P1.pos_x - gs.P2.pos_x)
         local pushbox_overlap_range = (pushboxes[1].width + pushboxes[2].width) / 2
         local push_value = get_push_value(dist_from_pb_center, pushbox_overlap_range, push_value_max)

         local sign = (math.floor(gs.P2.pos_x) - math.floor(gs.P1.pos_x) >= 0 and -1) or
                          (math.floor(gs.P2.pos_x) - math.floor(gs.P1.pos_x) < 0 and 1)
         gs.P1.pos_x = gs.P1.pos_x + push_value * sign
         gs.P2.pos_x = gs.P2.pos_x - push_value * sign

         for _, player in ipairs(gs.player_objects) do
            local corner_left = stage.left + character_specific[player.char_str].corner_offset_left
            local corner_right = stage.right - character_specific[player.char_str].corner_offset_right
            if player.pos_x > corner_right then
               local mantissa = player.pos_x - math.floor(player.pos_x)
               player.pos_x = corner_right + mantissa
            elseif player.pos_x < corner_left then
               local mantissa = player.pos_x - math.floor(player.pos_x)
               player.pos_x = corner_left + mantissa
            end
         end
      end
   end

   if not gs.previous_gamestate then return end
   for _, player in ipairs(gs.player_objects) do
      if gs.previous_gamestate[player.other.prefix].is_in_air_recovery then
         local corner_left = stage.left + character_specific[player.other.char_str].corner_offset_left
         local corner_right = stage.right - character_specific[player.other.char_str].corner_offset_right
         if (tools.trunc(player.other.pos_x) == corner_left or tools.trunc(player.other.pos_x) == corner_right) and
             math.abs(player.other.pos_x - player.pos_x) < 79 then
            local sign = tools.sign(player.other.pos_x - player.pos_x)
            if sign == 1 then
               player.pos_x = math.max(player.pos_x - 4.5, player.other.pos_x - 79)
            else
               player.pos_x = math.min(player.pos_x + 4.5, player.other.pos_x + 79)
            end
         end
      end
   end
end

local function update_sides(gs)
   for _, player in ipairs(gs.player_objects) do
      player.side = gamestate.get_side(player.pos_x, player.other.pos_x, player.previous_pos_x,
                                       player.other.previous_pos_x)
   end
end

local function check_side_switch(gs)
   for _, player in ipairs(gs.player_objects) do
      if player.character_state_byte ~= 4 then
         local previous_dist = math.floor(player.other.previous_pos_x) - math.floor(player.previous_pos_x)
         local dist = math.floor(player.other.pos_x) - math.floor(player.pos_x)
         if tools.sign(previous_dist) ~= tools.sign(dist) and dist ~= 0 then player.switched_sides = true end
         if (player.side == 1 and player.flip_x ~= 1) or (player.side == 2 and player.flip_x ~= 0) then
            player.should_turn = true
         end
      end
   end
end

local function new_gamestate(gs)
   local player_objects = {}
   local projectiles = {}
   for i, player in ipairs(gs.player_objects) do
      player_objects[player.id] = {
         id = player.id,
         base = player.base,
         prefix = player.prefix,
         type = player.type,
         input = player.input,
         char_str = player.char_str,
         side = player.side,
         selected_sa = player.selected_sa,
         flip_x = player.flip_x,
         previous_pos_x = player.previous_pos_x,
         previous_pos_y = player.previous_pos_y,
         pos_x = player.pos_x,
         -- pos_x_char = player.pos_x_char,
         -- pos_x_mantissa = player.pos_x_mantissa,
         pos_y = player.pos_y,
         -- pos_y_char = player.pos_y_char,
         -- pos_y_mantissa = player.pos_y_mantissa,
         velocity_x = player.velocity_x,
         -- velocity_x_char = player.velocity_x_char,
         -- velocity_x_mantissa = player.velocity_x_mantissa,
         velocity_y = player.velocity_y,
         -- velocity_y_char = player.velocity_y_char,
         -- velocity_y_mantissa = player.velocity_y_mantissa,
         acceleration_x = player.acceleration_x,
         -- acceleration_x_char = player.acceleration_x_char,
         -- acceleration_x_mantissa = player.acceleration_x_mantissa,
         acceleration_y = player.acceleration_y,
         -- acceleration_y_char = player.acceleration_y_char,
         -- acceleration_y_mantissa = player.acceleration_y_mantissa,
         boxes = copytable(player.boxes),
         remaining_freeze_frames = player.remaining_freeze_frames,
         freeze_just_began = player.freeze_just_began,
         freeze_just_ended = player.freeze_just_ended,
         superfreeze_decount = player.superfreeze_decount,
         movement_type = player.movement_type,
         movement_type2 = player.movement_type2,
         is_standing = player.is_standing,
         is_crouching = player.is_crouching,
         is_waking_up = player.is_waking_up,
         is_fast_wakingup = player.is_fast_wakingup,
         is_airborne = player.is_airborne,
         is_being_thrown = player.is_being_thrown,
         is_in_air_recovery = player.is_in_air_recovery,
         is_in_air_reel = player.is_in_air_reel,
         is_blocking = player.is_blocking,
         throw_countdown = player.throw_countdown,
         throw_tech_countdown = player.throw_tech_countdown,
         throw_invulnerability_cooldown = player.throw_invulnerability_cooldown,
         is_in_throw_tech = player.is_in_throw_tech,
         animation = player.animation,
         animation_frame = player.animation_frame,
         animation_frame_hash = player.animation_frame_hash,
         animation_frame_data = player.animation_frame_data,
         animation_freeze_frames = player.animation_freeze_frames,
         has_animation_just_changed = player.has_animation_just_changed,
         character_state_byte = player.character_state_byte,
         posture = player.posture,
         posture_ext = player.posture_ext,
         standing_state = player.standing_state,
         is_in_pushback = player.is_in_pushback,
         pushback_start_frame = player.pushback_start_frame,
         recovery_time = player.recovery_time,
         previous_recovery_time = player.previous_recovery_time,
         additional_recovery_time = player.additional_recovery_time,
         ends_recovery_next_frame = player.ends_recovery_next_frame,
         has_just_ended_recovery = player.has_just_ended_recovery,
         remaining_wakeup_time = player.remaining_wakeup_time,
         -- life = player.life,
         -- meter_gauge = player.meter_gauge,
         -- meter_count = player.meter_count,
         -- max_meter_gauge = player.max_meter_gauge,
         -- max_meter_count = player.max_meter_count,
         -- is_stunned = player.is_stunned,
         -- stun_bar_char = player.stun_bar_char,
         -- stun_bar_mantissa = player.stun_bar_mantissa,
         -- stun_bar_max = player.stun_bar_max,
         current_hit_id = player.current_hit_id,
         hit_count = player.hit_count,
         animation_miss_count = player.animation_miss_count,
         animation_connection_count = player.animation_connection_count,
         connected_action_count = player.connected_action_count,
         action_count = player.action_count,
         action = player.action,
         action_ext = player.action_ext,
         cooldown = player.cooldown,
         has_just_connected = player.has_just_connected,
         has_just_hit = player.has_just_hit,
         has_just_blocked = player.has_just_blocked,
         has_just_parried = player.has_just_parried,
         is_in_timed_sa = player.is_in_timed_sa,
         total_received_projectiles_count = player.total_received_projectiles_count,
         just_received_connection = player.just_received_connection,
         received_connection_id = player.received_connection_id,
         last_received_connection_animation = player.last_received_connection_animation,
         last_received_connection_hit_id = player.last_received_connection_hit_id
      }
   end
   for key, projectile in pairs(gs.projectiles) do
      projectiles[key] = {
         id = projectile.id,
         base = projectile.base,
         type = projectile.type,
         emitter_id = projectile.emitter_id,
         projectile_type = projectile.projectile_type,
         projectile_start_type = projectile.projectile_start_type,
         flip_x = projectile.flip_x,
         previous_pos_x = projectile.previous_pos_x,
         previous_pos_y = projectile.previous_pos_y,
         pos_x = projectile.pos_x,
         -- pos_x_char = projectile.pos_x_char,
         -- pos_x_mantissa = projectile.pos_x_mantissa,
         pos_y = projectile.pos_y,
         -- pos_y_char = projectile.pos_y_char,
         -- pos_y_mantissa = projectile.pos_y_mantissa,
         velocity_x = projectile.velocity_x,
         -- velocity_x_char = projectile.velocity_x_char,
         -- velocity_x_mantissa = projectile.velocity_x_mantissa,
         velocity_y = projectile.velocity_y,
         -- velocity_y_char = projectile.velocity_y_char,
         -- velocity_y_mantissa = projectile.velocity_y_mantissa,
         acceleration_x = projectile.acceleration_x,
         -- acceleration_x_char = projectile.acceleration_x_char,
         -- acceleration_x_mantissa = projectile.acceleration_x_mantissa,
         acceleration_y = projectile.acceleration_y,
         -- acceleration_y_char = projectile.acceleration_y_char,
         -- acceleration_y_mantissa = projectile.acceleration_y_mantissa,
         boxes = copytable(projectile.boxes),
         remaining_freeze_frames = projectile.remaining_freeze_frames,
         freeze_just_began = projectile.freeze_just_began,
         is_forced_one_hit = projectile.is_forced_one_hit,
         lifetime = projectile.lifetime,
         start_lifetime = projectile.start_lifetime,
         remaining_lifetime = projectile.remaining_lifetime,
         has_activated = projectile.has_activated,
         animation_start_frame = projectile.animation_start_frame,
         animation_freeze_frames = projectile.animation_freeze_frames,
         cooldown = projectile.cooldown,
         seiei_animation = projectile.seiei_animation,
         seiei_frame = projectile.seiei_frame,
         seiei_hit_id = projectile.seiei_hit_id,
         tengu_order = projectile.tengu_order,
         alive = projectile.alive,
         is_placeholder = projectile.is_placeholder,
         expired = projectile.expired,
         is_converted = projectile.is_converted,
         remaining_hits = projectile.remaining_hits,
         animation = projectile.animation,
         animation_frame = projectile.animation_frame,
         animation_frame_data = projectile.animation_frame_data
      }
   end
   return {
      P1 = player_objects[1],
      P2 = player_objects[2],
      player_objects = player_objects,
      projectiles = projectiles,

      stage = gs.stage,
      frame_number = gs.frame_number,
      screen_x = gs.screen_x,
      screen_y = gs.screen_y
   }
end

local function next_frames(obj, gs, animation_options)
   local results = {}
   local fdata
   if obj.type == "player" then
      fdata = find_move_frame_data(obj.char_str, obj.animation)
   else
      fdata = find_move_frame_data("projectiles", obj.animation)
   end
   if not fdata then return {{animation = obj.animation, frame = obj.animation_frame}} end
   local max_frames = fdata.frames and #fdata.frames or 1
   local frame_to_check = math.min(obj.animation_frame + 1, max_frames)
   local used_next_anim = false
   if fdata and frame_to_check <= #fdata.frames and fdata.frames[frame_to_check] then
      if fdata.frames[frame_to_check].loop then
         results[#results + 1] = {
            animation = obj.animation,
            frame = fdata.frames[frame_to_check].loop,
            frame_data = fdata
         }
      else
         if fdata.frames[frame_to_check].wakeup then
            results[#results + 1] = {animation = fd.frame_data[obj.char_str].standing, frame = 0}
         else
            for _, na in pairs(next_anim_types) do
               if fdata.frames[frame_to_check][na] then
                  local should_check = true
                  if na == "optional_anim" then
                     if animation_options and animation_options[obj.id] and
                         animation_options[obj.id].ignore_optional_anim then should_check = false end
                  elseif na == "next_anim" then
                     used_next_anim = true
                  end
                  if should_check then
                     for __, next_anim in pairs(fdata.frames[frame_to_check][na]) do
                        local next_anim_anim = next_anim[1]
                        local next_anim_frame = next_anim[2]
                        if animation_options and animation_options[obj.id] and animation_options[obj.id].next_anim then
                           if animation_options[obj.id].next_anim[obj.animation] then
                              next_anim_anim = animation_options[obj.id].next_anim[obj.animation].animation
                              next_anim_frame = animation_options[obj.id].next_anim[obj.animation].frame
                           end
                        else
                           if next_anim_anim == "idle" then
                              if obj.posture == 32 then
                                 next_anim_anim = fd.frame_data[obj.char_str].crouching
                                 next_anim_frame = 0
                              else
                                 next_anim_anim = fd.frame_data[obj.char_str].standing
                                 next_anim_frame = 0
                              end
                           end
                        end
                        results[#results + 1] = {animation = next_anim_anim, frame = next_anim_frame}
                     end
                  end
               end
            end
         end
      end
   end
   if not used_next_anim or #results == 0 then
      results[#results + 1] = {
         animation = obj.animation,
         frame = math.min(obj.animation_frame + 1, max_frames - 1),
         frame_data = fdata
      }
   end
   return results
end

local function copy_gamestate(gs)
   local exclude_player_keys = {"other", "animation_frame_data"}
   local temp_players = {P1 = {}, P2 = {}}
   for id, player in ipairs(gs.player_objects) do
      for _, key in ipairs(exclude_player_keys) do
         temp_players[player.prefix][key] = player[key]
         player[key] = nil
      end
   end

   local next_gs = tools.deepcopy(gs, {"player_objects", "projectiles", "collisions", "previous_gamestate"})

   for prefix, data in pairs(temp_players) do
      for key, value in pairs(data) do gs[prefix][key] = value end
      next_gs[prefix].animation_frame_data = data.animation_frame_data
   end

   next_gs.player_objects = {next_gs.P1, next_gs.P2}
   next_gs.P1.other = next_gs.P2
   next_gs.P2.other = next_gs.P1
   next_gs.projectiles = tools.deepcopy(gs.projectiles, {"animation_frame_data"})

   return next_gs
end

local function next_gamestates(gs, animation_options)
   local next_states = {}
   local next_frames_list = {}

   local start_gs = copy_gamestate(gs)
   start_gs.previous_gamestate = gs

   update_variables(start_gs)

   for id, player in ipairs(start_gs.player_objects) do
      if animation_options and animation_options[id] and animation_options[id].set then
         next_frames_list[id] = {
            {animation = animation_options[id].set.animation, frame = animation_options[id].set.frame}
         }
      else
         local bypass_freeze = player.animation_frame_data and player.animation_frame_data.frames and
                                   player.animation_frame_data.frames[player.animation_frame + 1] and
                                   player.animation_frame_data.frames[player.animation_frame + 1].bypass_freeze
         if (player.remaining_freeze_frames == 0 and not player.freeze_just_ended) or bypass_freeze then
            next_frames_list[id] = next_frames(player, start_gs, animation_options)
         else
            next_frames_list[id] = {
               {animation = player.animation, frame = player.animation_frame, frame_data = player.animation_frame_data}
            }
         end
      end
   end

   local next_projectiles = {}
   for id, projectile in pairs(start_gs.projectiles) do
      local animation_frame_data = projectile.animation_frame_data
      local next_proj = tools.deepcopy(projectile, {"animation_frame_data"})
      next_proj.animation_frame_data = animation_frame_data
      if not (next_proj.projectile_type == "seieienbu" or next_proj.projectile_type == "00_tenguishi") then
         local bypass_freeze = next_proj.animation_frame_data and next_proj.animation_frame_data.frames and
                                   next_proj.animation_frame_data.frames[next_proj.animation_frame + 1] and
                                   next_proj.animation_frame_data.frames[next_proj.animation_frame + 1].bypass_freeze
         if next_proj.remaining_freeze_frames == 0 or bypass_freeze then
            local next_frame = next_frames(next_proj, start_gs)[1]
            update_frame_data(start_gs, next_proj, next_frame)
         end
      end
      next_projectiles[id] = next_proj
   end

   for i, p1_nf in ipairs(next_frames_list[1]) do
      for j, p2_nf in ipairs(next_frames_list[2]) do
         local next_gs = copy_gamestate(start_gs)
         next_gs.previous_gamestate = start_gs
         next_gs.projectiles = next_projectiles
         update_frame_data(next_gs, next_gs.P1, p1_nf)
         update_frame_data(next_gs, next_gs.P2, p2_nf)
         next_states[#next_states + 1] = next_gs
      end
   end

   for i, next_gs in ipairs(next_states) do
      update_turn(next_gs)
      move_players(next_gs)
      move_projectiles(next_gs)
      update_sides(next_gs)
      check_collisions(next_gs)
      apply_pushback(next_gs)
      check_side_switch(next_gs)
   end

   return next_states
end

local function simulate_gamestates(gs, animation_options, frames_prediction)
   local start_states = next_gamestates(gs, animation_options)
   local predicted_states = {[1] = start_states}
   if animation_options then
      if animation_options[1] and animation_options[1].set then animation_options[1].set = nil end
      if animation_options[2] and animation_options[2].set then animation_options[2].set = nil end
   end
   for i = 2, frames_prediction do
      predicted_states[i] = {}
      for j, state in ipairs(predicted_states[i - 1]) do
         local next_gs_list = next_gamestates(state, animation_options)
         for k, next_gs in ipairs(next_gs_list) do table.insert(predicted_states[i], next_gs) end
      end
   end
   return predicted_states
end

local function predict_hits(gs, animation_options, frames_prediction)
   local results = {}
   gs = gs or new_gamestate(gamestate)
   if frames_prediction == 0 then return results end
   if next_animation[1] ~= animations.NONE then
      if not animation_options or not (animation_options[1] and animation_options[1].set) then
         if not animation_options then animation_options = {} end
         if not animation_options[1] then animation_options[1] = {} end
         animation_options[1].set = {animation = get_next_animation(gs.P1, next_animation[1]), frame = 0}
      end
   end
   if next_animation[2] ~= animations.NONE then
      if not animation_options or not (animation_options[2] and animation_options[2].set) then
         if not animation_options then animation_options = {} end
         if not animation_options[2] then animation_options[2] = {} end
         animation_options[2].set = {animation = get_next_animation(gs.P2, next_animation[2]), frame = 0}
      end
   end
   local predicted_states = simulate_gamestates(gs, animation_options, frames_prediction)
   for i, state_list in ipairs(predicted_states) do
      for j, state in ipairs(state_list) do
         for _, hit in ipairs(state.collisions) do
            if not results[hit.delta] then results[hit.delta] = {} end
            table.insert(results[hit.delta], hit)
         end
      end
   end
   return results
end

local function predict_attack_connection(gs, animation_options, attack_options)
   local results = {}
   gs = gs or new_gamestate(gamestate)
   local sim_time = 0
   if not animation_options then animation_options = {} end
   if not animation_options[1] then animation_options[1] = {} end
   if not animation_options[2] then animation_options[2] = {} end
   if animation_options[1].ignore_optional_anim == nil then animation_options[1].ignore_optional_anim = true end
   if animation_options[2].ignore_optional_anim == nil then animation_options[2].ignore_optional_anim = true end

   for id, player in ipairs(gs.player_objects) do
      if attack_options[id] then
         local anim, fdata = fd.find_frame_data_by_name(attack_options[id].char_str, attack_options[id].name,
                                                        attack_options[id].button)
         attack_options[id].animation = anim
         attack_options[id].input = move_data.get_move_inputs_by_name(attack_options[id].char_str, attack_options[id].name,
                                                                      attack_options[id].button)
         local last_hit_frame = fd.get_last_hit_frame(attack_options[id].char_str, anim)
         if last_hit_frame > sim_time then sim_time = last_hit_frame end
         animation_options[id].set = {animation = anim, frame = 0}
         if not attack_options[id].delay then attack_options[id].delay = 0 end
      end
   end
   if sim_time < 1 then return end
   if next_animation[1] ~= animations.NONE then
      if not animation_options[1].set then
         animation_options[1].set = {animation = get_next_animation(gs.P1, next_animation[1]), frame = 0}
      end
   end
   if next_animation[2] ~= animations.NONE then
      if not animation_options[2].set then
         animation_options[2].set = {animation = get_next_animation(gs.P2, next_animation[2]), frame = 0}
      end
   end

   local predicted_states = {[0] = {gs}}

   for i = 1, sim_time do
      predicted_states[i] = {}
      for j, state in ipairs(predicted_states[i - 1]) do
         if attack_options[1] and i - #attack_options[1].input == attack_options[1].delay then
            animation_options[1].set = {animation = attack_options[1].animation, frame = 0}
         end
         if attack_options[2] and i - #attack_options[2].input == attack_options[2].delay then
            animation_options[2].set = {animation = attack_options[2].animation, frame = 0}
         end
         local next_gs_list = next_gamestates(state, animation_options)
         for k, next_gs in ipairs(next_gs_list) do
            for _, hit in ipairs(next_gs.collisions) do
               local defender = next_gs.player_objects[hit.owner_id].other
               if not defender.is_airborne or attack_options[hit.owner_id].is_super then --hack. need to record super property
                  if defender.character_state_byte == 1 and not defender.is_blocking and
                     (defender.recovery_time >= 1 or defender.remaining_freeze_frames > 0 or defender.freeze_just_ended) then
                     hit.connection_type = "hit"
                  else
                     hit.connection_type = "block"
                  end
                  hit.delta = next_gs.frame_number - gs.frame_number
                  table.insert(results, hit)
               end
            end
            if #results > 0 then return true, results end
            table.insert(predicted_states[i], next_gs)
         end

         animation_options[1].set = nil
         animation_options[2].set = nil
      end
   end
   return false
end

local function predict_gamestate(gs, animation_options, frames_prediction)
   gs = gs or new_gamestate(gamestate)
   if frames_prediction == 0 then return gs end
   if next_animation[1] ~= animations.NONE then
      if not animation_options or not (animation_options[1] and animation_options[1].set) then
         if not animation_options then animation_options = {} end
         if not animation_options[1] then animation_options[1] = {} end
         animation_options[1].set = {animation = get_next_animation(gs.P1, next_animation[1]), frame = 0}
      end
   end
   if next_animation[2] ~= animations.NONE then
      if not animation_options or not (animation_options[2] and animation_options[2].set) then
         if not animation_options then animation_options = {} end
         if not animation_options[2] then animation_options[2] = {} end
         animation_options[2].set = {animation = get_next_animation(gs.P2, next_animation[2]), frame = 0}
      end
   end
   if not animation_options then animation_options = {} end
   if not animation_options[1] then animation_options[1] = {} end
   if not animation_options[2] then animation_options[2] = {} end
   animation_options[1].ignore_optional_anim = true
   animation_options[2].ignore_optional_anim = true

   local predicted_states = simulate_gamestates(gs, animation_options, frames_prediction)

   return predicted_states[#predicted_states][1]
end

return {
   predict_hits = predict_hits,
   predict_gamestate = predict_gamestate,
   predict_attack_connection = predict_attack_connection,
   next_gamestates = next_gamestates,
   simulate_gamestates = simulate_gamestates,
   update_before = update_before,
   update_after = update_after,
   predict_jump_arc = predict_jump_arc,
   predict_player_movement = predict_player_movement,
   predict_frames_before_landing = predict_frames_before_landing,
   predict_next_animation = predict_next_animation,
   get_next_animation = get_next_animation,
   get_frames_until_idle = get_frames_until_idle,
   get_frame_advantage = get_frame_advantage,
   init_motion_data = init_motion_data,
   init_motion_data_zero = init_motion_data_zero
}
