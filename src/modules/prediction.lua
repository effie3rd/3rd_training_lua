local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local sd = require("src.modules.stage_data")
local gamestate = require("src.gamestate")
local debug = require("src.debug")
local tools = require("src.tools")
local debug_settings = require("src.debug_settings")

local frame_data, character_specific, get_hurtboxes = fd.frame_data, fd.character_specific, fd.get_hurtboxes
local stages = sd.stages
local find_move_frame_data = fd.find_move_frame_data
local frame_data_meta = fdm.frame_data_meta

local next_anim_types = {"next_anim", "optional_anim"}

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

   local frame_to_check = frame + 1
   local delta = 0
   if #result > 0 then delta = result[#result].delta end

   if specify_frame then
      delta = delta + 1
      frames_prediction = frames_prediction - 1
      table.insert(result, {animation = anim, frame = frame, delta = delta})
   end

   local used_loop = false
   local used_next_anim = false
   if not fdata then
      return results
   else
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
                              next_anim_anim = frame_data[obj.char_str].crouching
                              next_anim_frame = 0
                           else
                              next_anim_anim = frame_data[obj.char_str].standing
                              next_anim_frame = 0
                           end
                        end
                        table.insert(current_res, {animation = next_anim_anim, frame = next_anim_frame, delta = delta})
                        local subres = predict_frames_branching(obj, next_anim_anim, next_anim_frame,
                                                                frames_prediction - i, false, current_res)

                        for ___, sr in pairs(subres) do table.insert(results, sr) end
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
               table.insert(result, {animation = anim, frame = frame_to_check - 1, delta = delta})
            end
         end
      end

      if not used_next_anim then table.insert(results, result) end

      return results
   end
end

local function get_frames_until_idle(obj, anim, frame, frames_prediction, result, depth)
   if obj.is_idle then return 0 end

   depth = depth or 0
   local results = {}
   result = result or 0
   anim = anim or obj.animation
   frame = frame or obj.animation_frame
   local fdata = find_move_frame_data(obj.char_str, anim)

   local frame_to_check = frame + 1
   local delta = 0
   if result then delta = result end

   local used_loop = false
   local used_next_anim = false

   if not fdata then
      if result == 0 then return frames_prediction end
      return delta, false
   elseif fdata.idle_frames then
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
                        if found then table.insert(results, subres) end

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
      if depth == 0 then res = res + obj.remaining_freeze_frames + obj.recovery_time + obj.additional_recovery_time end
      return res, true
   end
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
      animation = obj.animation,
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
      animation = obj.animation,
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
      table.insert(line, {animation = obj.animation or obj.projectile_type, frame = obj.animation_frame + i, delta = i})
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

local function insert_projectile(player, motion_data, predicted_hit)
   local fd = frame_data[player.char_str][predicted_hit.animation]
   if fd and fd.frames[predicted_hit.frame + 1] and fd.frames[predicted_hit.frame + 1].projectile then
      local proj_fd = frame_data["projectiles"][fd.frames[predicted_hit.frame + 1].projectile.type]
      local obj = {base = 0, projectile = 99}
      obj.id = fd.frames[predicted_hit.frame + 1].projectile.type ..
                   tostring(gamestate.frame_number + predicted_hit.delta)
      obj.emitter_id = player.id
      obj.alive = true
      obj.projectile_type = fd.frames[predicted_hit.frame + 1].projectile.type
      obj.projectile_start_type = obj.projectile_type
      obj.pos_x = motion_data.pos_x + fd.frames[predicted_hit.frame + 1].projectile.offset[1] *
                      tools.flip_to_sign(motion_data.flip_x)
      obj.pos_y = motion_data.pos_y + fd.frames[predicted_hit.frame + 1].projectile.offset[2]
      obj.velocity_x = 0
      obj.velocity_y = 0
      obj.acceleration_x = 0
      obj.acceleration_y = 0
      if proj_fd.frames[1].velocity then
         obj.velocity_x = proj_fd.frames[1].velocity[1]
         obj.velocity_y = proj_fd.frames[1].velocity[2]
      end
      if proj_fd.frames[1].acceleration then
         obj.acceleration_x = proj_fd.frames[1].acceleration[1]
         obj.acceleration_y = proj_fd.frames[1].acceleration[2]
      end
      obj.flip_x = motion_data.flip_x
      obj.boxes = {}
      obj.expired = false
      obj.previous_remaining_hits = 99
      obj.remaining_hits = 99
      obj.is_forced_one_hit = false
      obj.has_activated = false
      obj.animation_start_frame = gamestate.frame_number + predicted_hit.delta
      obj.animation_frame = 0
      obj.animation_freeze_frames = 0
      obj.remaining_freeze_frames = 0
      obj.remaining_lifetime = 0
      obj.cooldown = predicted_hit.delta
      obj.placeholder = true
      gamestate.projectiles[obj.id] = obj
   end
end

local function test_collision(defender_x, defender_y, defender_flip_x, defender_boxes, attacker_x, attacker_y,
                              attacker_flip_x, attacker_boxes, box_type_matches, defender_hurtbox_dilation_x,
                              defender_hurtbox_dilation_y, attacker_hitbox_dilation_x, attacker_hitbox_dilation_y)
   local debug = false
   if (defender_hurtbox_dilation_x == nil) then defender_hurtbox_dilation_x = 0 end
   if (defender_hurtbox_dilation_y == nil) then defender_hurtbox_dilation_y = 0 end
   if (attacker_hitbox_dilation_x == nil) then attacker_hitbox_dilation_x = 0 end
   if (attacker_hitbox_dilation_y == nil) then attacker_hitbox_dilation_y = 0 end
   if (box_type_matches == nil) then box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}} end

   if (#box_type_matches == 0) then return false end
   if (#defender_boxes == 0) then return false end
   if (#attacker_boxes == 0) then return false end
   if debug then print(string.format("   %d defender boxes, %d attacker boxes", #defender_boxes, #attacker_boxes)) end
   for k = 1, #box_type_matches do
      local box_type_match = box_type_matches[k]
      for i = 1, #defender_boxes do
         local d_box = tools.format_box(defender_boxes[i])

         local defender_box_match = false
         for _, value in ipairs(box_type_match[1]) do
            if value == d_box.type then
               defender_box_match = true
               break
            end
         end
         if defender_box_match then
            -- compute defender box bounds
            local d_l
            if defender_flip_x == 0 then
               d_l = defender_x + d_box.left
            else
               d_l = defender_x - d_box.left - d_box.width
            end
            local d_r = d_l + d_box.width
            local d_b = defender_y + d_box.bottom
            local d_t = d_b + d_box.height

            d_l = d_l - defender_hurtbox_dilation_x
            d_r = d_r + defender_hurtbox_dilation_x
            d_b = d_b - defender_hurtbox_dilation_y
            d_t = d_t + defender_hurtbox_dilation_y

            for j = 1, #attacker_boxes do
               local a_box = tools.format_box(attacker_boxes[j])

               local attacker_box_match = false
               for _, value in ipairs(box_type_match[2]) do
                  if value == a_box.type then
                     attacker_box_match = true
                     break
                  end
               end

               if attacker_box_match then
                  -- compute attacker box bounds
                  local a_l
                  if attacker_flip_x == 0 then
                     a_l = attacker_x + a_box.left
                  else
                     a_l = attacker_x - a_box.left - a_box.width
                  end
                  local a_r = a_l + a_box.width
                  local a_b = attacker_y + a_box.bottom
                  local a_t = a_b + a_box.height

                  a_l = a_l - attacker_hitbox_dilation_x
                  a_r = a_r + attacker_hitbox_dilation_x
                  a_b = a_b - attacker_hitbox_dilation_y
                  a_t = a_t + attacker_hitbox_dilation_y

                  if debug then
                     print(string.format("   testing (%d,%d,%d,%d)(%s) against (%d,%d,%d,%d)(%s)", d_t, d_r, d_b, d_l,
                                         d_box.type, a_t, a_r, a_b, a_l, a_box.type))
                  end

                  -- check collision
                  if (a_l < d_r) and (a_r > d_l) and (a_b < d_t) and (a_t > d_b) then return true end
               end
            end
         end
      end
   end

   return false
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

   if a_r > b_l and a_l < b_r and a_t > b_b and a_b < b_t then return math.min(a_r, b_r) - math.max(a_l, b_l) end
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

local function predict_player_pushback(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
   local motion_data = {[p1] = p1_motion_data, [p2] = p2_motion_data}
   local lines = {[p1] = p1_line, [p2] = p2_line}
   local stage = stages[gamestate.stage]

   local pushboxes = {}

   for _, player in ipairs({p1, p2}) do
      local fdata = find_move_frame_data(player.char_str, lines[player][index].animation)
      if fdata and fdata.frames and fdata.frames[lines[player][index].frame + 1] and
          fdata.frames[lines[player][index].frame + 1].boxes then
         local boxes = tools.get_boxes(fdata.frames[lines[player][index].frame + 1].boxes, {"push"})
         if #boxes > 0 then pushboxes[player.id] = boxes[1] end
      end
      if not pushboxes[player.id] then pushboxes[player.id] = tools.get_pushboxes(player) end
   end

   if pushboxes[1] and pushboxes[2] then
      local p1_pushbox = tools.format_box(pushboxes[1])
      local p2_pushbox = tools.format_box(pushboxes[2])

      local p1_mdata = motion_data[p1][index]
      local p2_mdata = motion_data[p2][index]

      local overlap = get_horizontal_box_overlap(p1_pushbox, p1_mdata.pos_x, p1_mdata.pos_y, p1_mdata.flip_x,
                                                 p2_pushbox, p2_mdata.pos_x, p2_mdata.pos_y, p2_mdata.flip_x)
      if overlap > 1 then
         local push_value_max = math.ceil((character_specific[p1.char_str].push_value +
                                              character_specific[p2.char_str].push_value) / 2)
         local dist_from_pb_center = math.abs(p1_mdata.pos_x - p2_mdata.pos_x)
         local pushbox_overlap_range = (p1_pushbox.width + p2_pushbox.width) / 2
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
      if tools.sign(previous_dist) ~= tools.sign(dist) and dist ~= 0 then mdata[index].switched_sides = true end
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

      if mdata[index - 1].switched_sides then
         if player.remaining_freeze_frames - index < 0 then
            local anim = mdata[index - 1].animation
            local target_anim = nil
            if anim == frame_data[player.char_str].standing then
               target_anim = frame_data[player.char_str].standing_turn
            elseif anim == frame_data[player.char_str].crouching then
               target_anim = frame_data[player.char_str].crouching_turn
            end
            if target_anim then
               local line = predict_frames_branching(player, target_anim, 0, #lines[player] - index + 1, true)[1]
               for j = 1, #line do lines[player][index + j - 1] = line[j] end

               mdata[index].flip_x = bit.bxor(mdata[index - 1].flip_x, 1)
               if target_anim.velocity then
                  mdata[index].velocity_x = target_anim.velocity[1]
                  mdata[index].velocity_y = target_anim.velocity[2]
               end
            end
         end
      end
   end

   for player, mdata in pairs(motion_data) do
      local corner_left = stage.left + character_specific[player.char_str].corner_offset_left
      local corner_right = stage.right - character_specific[player.char_str].corner_offset_right
      local sign = tools.flip_to_sign(mdata[index - 1].flip_x)

      local is_in_pushback = false
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

         if anim and hit_id and frame_data[player.other.char_str][anim] and
             frame_data[player.other.char_str][anim].pushback and
             frame_data[player.other.char_str][anim].pushback[hit_id] and pb_frame <=
             #frame_data[player.other.char_str][anim].pushback[hit_id] then
            local pb_value = frame_data[player.other.char_str][anim].pushback[hit_id][pb_frame]
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

      local fdata = find_move_frame_data(player.char_str, lines[player][index].animation)
      if fdata then
         local next_frame = fdata.frames[lines[player][index].frame + 1]
         if next_frame then
            if next_frame.movement then
               mdata[index].pos_x = mdata[index].pos_x + next_frame.movement[1] * sign
               mdata[index].pos_y = mdata[index].pos_y + next_frame.movement[2]
            end
            if next_frame.velocity then
               mdata[index].velocity_x = mdata[index].velocity_x + mdata[index - 1].acceleration_x +
                                             next_frame.velocity[1]
               mdata[index].velocity_y = mdata[index].velocity_y + mdata[index - 1].acceleration_y +
                                             next_frame.velocity[2]
            end
            if next_frame.acceleration then
               mdata[index].acceleration_x = mdata[index].acceleration_x + next_frame.acceleration[1]
               mdata[index].acceleration_y = mdata[index].acceleration_y + next_frame.acceleration[2]
            end
         else
            -- print("next frame not found", lines[player][index].animation, lines[player][index].frame)
         end
      end

      local should_apply_velocity = false
      local previous_frame_data = find_move_frame_data(player.char_str, lines[player][index - 1].animation)

      if (previous_frame_data and previous_frame_data.uses_velocity) or mdata[index - 1].pos_y > 0 then -- change this to use standing_state
         -- first frame of every air move ignores velocity
         if not (lines[player][index - 1].frame == 0 and previous_frame_data and previous_frame_data.air) then
            should_apply_velocity = true
         end
      end
      if should_apply_velocity then
         mdata[index].pos_x = mdata[index].pos_x + mdata[index - 1].velocity_x * sign
         mdata[index].pos_y = mdata[index].pos_y + mdata[index - 1].velocity_y
      end

      if mdata[index].pos_x > corner_right then
         local mantissa = mdata[index].pos_x - math.floor(mdata[index].pos_x)
         mdata[index].pos_x = corner_right + mantissa
      elseif mdata[index].pos_x < corner_left then
         local mantissa = mdata[index].pos_x - math.floor(mdata[index].pos_x)
         mdata[index].pos_x = corner_left + mantissa
      end

      -- if player is falling
      if fdata and mdata[index].pos_y < mdata[index - 1].pos_y then
         local next_frame = fdata.frames[lines[player][index].frame + 1]
         local boxes_bottom = nil
         if next_frame and next_frame.boxes and tools.has_boxes(next_frame.boxes, {"vulnerability"}) then
            boxes_bottom = mdata[index].pos_y + tools.get_boxes_lowest_position(next_frame.boxes, {"vulnerability"})
         else
            for j = index - 1, 1, -1 do
               local an = lines[player][j].animation
               local f = lines[player][j].frame
               local pfd = find_move_frame_data(player.char_str, an)
               if pfd and pfd.frames then
                  local prev_frame = pfd.frames[f + 1]
                  if prev_frame.boxes and tools.has_boxes(prev_frame.boxes, {"vulnerability"}) then
                     boxes_bottom = mdata[index].pos_y +
                                        tools.get_boxes_lowest_position(prev_frame.boxes, {"vulnerability"})
                  end
               end
            end
         end
         -- this is a guess at when landing will occur. not sure what the actual principle is
         -- moves like dudley's jump HK/HP allow the player to fall much lower before landing. y_pos of -30 for dudley's j.HP!
         if boxes_bottom then
            if boxes_bottom < 40 then
               mdata[index].pos_y = 0
               mdata[index].standing_state = 1
            end
         elseif mdata[index].pos_y < 0 then
            mdata[index].pos_y = 0
            mdata[index].standing_state = 1
         end
      end
   end

   -- don't allow side switches if grounded
   for player, mdata in pairs(motion_data) do
      if mdata.pos_y == 0 and motion_data[player.other][index].pos_y == 0 then
         if tools.sign(mdata[index - 1].pos_x - motion_data[player.other][index].pos_x) ~=
             tools.sign(mdata[index].pos_x - motion_data[player.other][index].pos_x) then
            local sign = tools.sign(mdata[index - 1].pos_x - motion_data[player.other][index].pos_x)
            mdata[index].pos_x = motion_data[player.other][index].pos_x + sign
         end
      end
   end

   predict_player_pushback(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
   predict_switch_sides(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)
end

local function predict_next_projectile_movement(projectile, mdata, line, index, ignore_flip)
   mdata[index] = copytable(mdata[index - 1])

   local sign = ignore_flip and 1 or tools.flip_to_sign(mdata[index - 1].flip_x)

   local fdata = find_move_frame_data("projectiles", line[index].animation)
   if fdata then
      local next_frame = fdata.frames[line[index].frame + 1]
      if next_frame then
         if next_frame.movement then
            mdata[index].pos_x = mdata[index].pos_x + next_frame.movement[1] * sign
            mdata[index].pos_y = mdata[index].pos_y + next_frame.movement[2]
         end
         if next_frame.velocity then
            mdata[index].velocity_x = mdata[index].velocity_x + mdata[index - 1].acceleration_x + next_frame.velocity[1]
            mdata[index].velocity_y = mdata[index].velocity_y + mdata[index - 1].acceleration_y + next_frame.velocity[2]
         end
         if next_frame.acceleration then
            mdata[index].acceleration_x = mdata[index].acceleration_x + next_frame.acceleration[1]
            mdata[index].acceleration_y = mdata[index].acceleration_y + next_frame.acceleration[2]
         end
      else
         print("next frame not found", line[index].animation, line[index].frame) -- debug
      end
   end

   mdata[index].pos_x = mdata[index].pos_x + mdata[index - 1].velocity_x * sign
   mdata[index].pos_y = mdata[index].pos_y + mdata[index - 1].velocity_y
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
      if pass then table.insert(filtered, line) end
   end
   return filtered
end

local function predict_player_movement(player, player_anim, player_frame, player_motion_data, dummy, dummy_anim, dummy_frame, dummy_motion_data,
                                       frames_prediction)
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

local function update_prediction(player, player_anim, player_frame, dummy, dummy_anim, dummy_frame, frames_prediction)
   -- returns all possible sequences of the next 3 frames
   local specify_frame = player_anim and player_frame
   local player_lines = predict_frames_branching(player, player_anim, player_frame, frames_prediction, specify_frame)
   -- filter for lines that contain hit frames or projectiles
   local filtered = filter_lines(player, player_lines) or {}

   local expected_hits = {}

   if #filtered > 0 and #filtered[1] > 0 then
      player_lines = filtered
   else
      if player_lines[1] and #player_lines[1] > 0 then
         player_lines = {player_lines[1]}
      else
         player_lines = {create_line(player, frames_prediction)}
      end
   end
   for _, player_line in pairs(player_lines) do
      player_line[0] = {animation = player.animation, frame = player.animation_frame, delta = 0}
   end

   specify_frame = dummy_anim and dummy_frame
   local dummy_line = predict_frames_branching(dummy, dummy_anim, dummy_frame, frames_prediction, specify_frame)[1]
   if not dummy_line or #dummy_line == 0 then dummy_line = create_line(dummy, frames_prediction) end
   dummy_line[0] = {animation = dummy.animation, frame = dummy.animation_frame, delta = 0}

   local predicted_state = {}

   for _, player_line in pairs(player_lines) do
      local player_motion_data = init_motion_data(player)
      local dummy_motion_data = init_motion_data(dummy)
      player_motion_data[0].switched_sides = check_switch_sides(player)
      dummy_motion_data[0].switched_sides = check_switch_sides(dummy)

      for i = 1, #player_line do
         local predicted_frame = player_line[i]
         local frame = predicted_frame.frame
         local frame_to_check = frame + 1
         local fdata = find_move_frame_data(player.char_str, predicted_frame.animation)

         predict_next_player_movement(player, player_motion_data, player_line, dummy, dummy_motion_data, dummy_line, i)

         predicted_state = {
            player_motion_data = player_motion_data,
            player_line = player_line,
            dummy_motion_data = dummy_motion_data,
            dummy_line = dummy_line
         }

         if debug_settings.debug_hitboxes and i <= debug_settings.hitbox_display_frames then
            local vuln = {}
            local tfd = frame_data[player.char_str][player_line[i].animation]
            local color = 0x44097000 + 255
            if tfd and tfd.frames and tfd.frames[player_line[i].frame + 1] and
                tfd.frames[player_line[i].frame + 1].boxes then
               vuln = tools.get_boxes(tfd.frames[player_line[i].frame + 1].boxes,
                                      {"vulnerability", "ext. vulnerability"})
               color = 0x44097000 + 255 - math.floor(100 * (frames_prediction - i) / frames_prediction)
            end
            if #vuln == 0 then vuln = player.boxes end
            debug.queue_hitbox_draw(gamestate.frame_number + i, {
               player_motion_data[i].pos_x, player_motion_data[i].pos_y, player_motion_data[i].flip_x, vuln, nil, nil,
               color
            }, "player")
         end

         -- print(i, dummy_line[i].animation, dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, #vuln)

         if fdata then
            local frames = fdata.frames
            if frames and frames[frame_to_check] then
               if frames[frame_to_check].projectile then
                  insert_projectile(player, player_motion_data[i], predicted_frame)
               end

               if fdata.hit_frames and frames[frame_to_check].boxes and
                   tools.has_boxes(frames[frame_to_check].boxes, {"attack", "throw"}) then

                  local should_test = false
                  local current_hit_id = player.current_hit_id
                  local next_hit_id = 1

                  for j = 1, #fdata.hit_frames do
                     if frame > fdata.hit_frames[j][2] then next_hit_id = j + 1 end
                  end
                  if fdata.infinite_loop then
                     current_hit_id = (player.animation_miss_count + player.animation_connection_count) %
                                          #fdata.hit_frames
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

                     if debug_settings.debug_hitboxes and i <= debug_settings.hitbox_display_frames then
                        local attack_boxes = tools.get_boxes(frames[frame_to_check].boxes, {"attack"})
                        debug.queue_hitbox_draw(gamestate.frame_number + predicted_frame.delta, {
                           player_motion_data[i].pos_x, player_motion_data[i].pos_y, player_motion_data[i].flip_x,
                           attack_boxes, nil, nil, 0xFF941CDD
                        }, "attack")
                        local color = 0x44097000 + 255 - math.floor(100 * (frames_prediction - i) / frames_prediction)
                        debug.queue_hitbox_draw(gamestate.frame_number + predicted_frame.delta, {
                           dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, dummy_motion_data[i].flip_x,
                           dummy_boxes, nil, nil, color
                        }, "vuln")
                     end

                     local box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
                     if frame_data_meta[player.char_str][predicted_frame.animation] and
                         frame_data_meta[player.char_str][predicted_frame.animation].hit_throw then
                        table.insert(box_type_matches, {{"throwable"}, {"throw"}})
                     end

                     if test_collision(dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y,
                                       dummy_motion_data[i].flip_x, dummy_boxes, player_motion_data[i].pos_x,
                                       player_motion_data[i].pos_y, player_motion_data[i].flip_x,
                                       frames[frame_to_check].boxes, box_type_matches) then
                        local delta = predicted_frame.delta + remaining_cooldown
                        if not (fdata.frames[predicted_frame.frame + 1].bypass_freeze and delta == 1) then
                           delta = delta + player.remaining_freeze_frames
                        else
                           -- print(predicted_frame.animation, predicted_frame.frame, delta) --debug
                        end
                        local expected_hit = {
                           id = player.id,
                           blocking_type = "player",
                           hit_id = next_hit_id,
                           delta = delta,
                           animation = predicted_frame.animation,
                           flip_x = predicted_frame.flip_x,
                           switched_sides = player_motion_data[i].switched_sides
                        }
                        table.insert(expected_hits, expected_hit)
                     end
                  end
               end
            else
               print("NO FD", predicted_frame.animation, frame)
            end
         end

      end
   end

   local valid_projectiles = {}
   for _, projectile in pairs(gamestate.projectiles) do
      if ((projectile.is_forced_one_hit and projectile.remaining_hits ~= 0xFF) or projectile.remaining_hits > 0) and
          projectile.alive then
         if (projectile.emitter_id ~= dummy.id or (projectile.emitter_id == dummy.id and projectile.is_converted)) then
            local frame_delta = projectile.remaining_freeze_frames - frames_prediction
            if projectile.placeholder then
               frame_delta = projectile.animation_start_frame - gamestate.frame_number - frames_prediction
            end
            if frame_delta <= frames_prediction and projectile.cooldown - frames_prediction <= 0 then
               table.insert(valid_projectiles, projectile)
            end
         end
      end
   end
   if #valid_projectiles > 0 then
      local box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
      local dummy_motion_data = predicted_state.dummy_motion_data
      dummy_line = predicted_state.dummy_line
      for _, projectile in pairs(valid_projectiles) do
         local proj_line = nil
         if projectile.seiei_animation then
            local emitter = gamestate.player_objects[projectile.emitter_id]
            proj_line = predict_frames_branching(emitter, projectile.seiei_animation, projectile.seiei_frame,
                                                 frames_prediction)[1]
         else
            proj_line = predict_frames_branching(projectile, projectile.projectile_type, projectile.animation_frame,
                                                 frames_prediction)[1]
         end
         if not proj_line or #proj_line == 0 then proj_line = create_line(projectile, frames_prediction) end
         local proj_motion_data = init_motion_data(projectile)
         if projectile.cooldown - frames_prediction <= 0 then
            for i = 1, #dummy_line do
               local remaining_freeze = projectile.remaining_freeze_frames - i
               local remaining_cooldown = projectile.cooldown
               if remaining_freeze <= 0 then
                  remaining_cooldown = math.max(remaining_cooldown + remaining_freeze, 0)
               end

               local proj_boxes = {}
               local ignore_flip = false
               if projectile.projectile_type == "00_tenguishi" then
                  proj_boxes = projectile.boxes
                  ignore_flip = true
               elseif projectile.seiei_animation then
                  local seiei_fd = find_move_frame_data("yang", projectile.seiei_animation)
                  if seiei_fd and seiei_fd.frames[projectile.seiei_animation] and
                      seiei_fd.frames[projectile.seiei_animation].boxes and
                      tools.has_boxes(seiei_fd.frames[projectile.seiei_animation].boxes, {"attack", "throw"}) then
                     proj_boxes = seiei_fd.frames[projectile.seiei_animation].boxes
                  end
               else
                  local fdata = find_move_frame_data("projectiles", proj_line[i].animation)
                  local frame_to_check = proj_line[i].frame + 1
                  if fdata then
                     local frames = fdata.frames
                     if frames and frames[frame_to_check] and frames[frame_to_check].boxes and
                         tools.has_boxes(frames[frame_to_check].boxes, {"attack", "throw"}) then
                        proj_boxes = frames[frame_to_check].boxes
                     end
                  end
                  if #proj_boxes == 0 then proj_boxes = projectile.boxes end
               end

               predict_next_projectile_movement(projectile, proj_motion_data, proj_line, i, ignore_flip)

               local dummy_boxes = get_hurtboxes(dummy.char_str, dummy_line[i].animation, dummy_line[i].frame)
               if not dummy_boxes then dummy_boxes = dummy.boxes end

               if proj_boxes and remaining_cooldown <= 0 then
                  local delta = proj_line[i].delta + projectile.remaining_freeze_frames + remaining_cooldown

                  if debug_settings.debug_hitboxes and i <= 3 then
                     local color = 0xa9691c00 + 255 - 70 * delta
                     debug.queue_hitbox_draw(gamestate.frame_number + delta, {
                        proj_motion_data[i].pos_x, proj_motion_data[i].pos_y, proj_motion_data[i].flip_x, proj_boxes,
                        nil, nil, color
                     }, "projectile" .. projectile.id)
                  end

                  if test_collision(dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, dummy_motion_data[i].flip_x,
                                    dummy_boxes, proj_motion_data[i].pos_x, proj_motion_data[i].pos_y,
                                    proj_motion_data[i].flip_x, proj_boxes, box_type_matches) then
                     local expected_hit = {
                        id = projectile.id,
                        blocking_type = "projectile",
                        hit_id = 1,
                        delta = delta,
                        animation = proj_line[i].animation,
                        flip_x = proj_motion_data[i].flip_x
                     }
                     table.insert(expected_hits, expected_hit)
                  end
               end
            end
         end
      end
   end
   return expected_hits
end

local function predict_frames_before_landing(player)
   local frames_prediction = 15
   local y = player.pos_y
   local velocity = player.velocity_y
   for i = 1, frames_prediction do
      y = y + velocity
      velocity = velocity + player.acceleration_y
      if y <= 0 then return i end
   end
   return -1
end

return {
   test_collision = test_collision,
   update_prediction = update_prediction,
   predict_player_movement = predict_player_movement,
   predict_frames_before_landing = predict_frames_before_landing,
   get_frames_until_idle = get_frames_until_idle,
   init_motion_data = init_motion_data,
   init_motion_data_zero = init_motion_data_zero
}
