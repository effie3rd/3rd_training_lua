local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local sd = require("src.modules.stagedata")
local gamestate = require("src.gamestate")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local stages = sd.stages
local test_collision, find_move_frame_data = fd.test_collision, fd.find_move_frame_data
local frame_data_meta = fdm.frame_data_meta

local next_anim_types = {"next_anim", "optional_anim"}






local function predict_frames_branching(obj, anim, frame, frames_prediction, result, include_start_frame)
  local results = {}
  local result = result or {}
  frame = frame or obj.animation_frame
  local fdata = nil
  if obj.type == "player" then
    fdata = find_move_frame_data(obj.char_str, anim)
  else
    fdata = find_move_frame_data("projectiles", anim)
  end

  local frame_to_check = frame + 1
  local current_loop = 1
  local delta = 0
  if #result > 0 then
    delta = result[#result].delta
  end

  if include_start_frame then
    delta = delta + 1
    frames_prediction = frames_prediction - 1
    table.insert(result, {animation = anim, frame = frame, delta = delta})
  end

  local used_loop = false
  local used_next_anim = false

  if not fdata then
    return results
  else
    if fdata.loops then
      for i = 1, #fdata.loops do
        if frame_to_check >= fdata.loops[i][1] + 1
        and frame_to_check <= fdata.loops[i][2] + 1 then
          current_loop = i
          break
        end
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
              if na == "next_anim" then
                used_next_anim = true
              end
              for __, next_anim in pairs(fdata.frames[frame_to_check][na]) do
                local current_res = copytable(result)
                local next_anim_anim = next_anim[1]
                local next_anim_frame = next_anim[2]
                if next_anim_anim == "idle" then
                  if obj.action == 7 or obj.action_ext == 7 then
                    next_anim_anim = frame_data[obj.char_str].crouching
                    next_anim_frame = 0
                  else
                    next_anim_anim = frame_data[obj.char_str].standing
                    next_anim_frame = 0
                  end
                end
                table.insert(current_res, {animation = next_anim_anim, frame = next_anim_frame, delta = delta})
                local subres = predict_frames_branching(obj, next_anim_anim, next_anim_frame, frames_prediction - i, current_res)

                for ___, sr in pairs(subres) do
                  table.insert(results, sr)
                end
              end
            end
          end
        end
        if used_next_anim then
          break
        else
          if not used_loop then
            frame_to_check = math.min(frame_to_check + 1, #fdata.frames)
          end
          table.insert(result, {animation = anim, frame = frame_to_check - 1, delta = delta})
        end
      end
    end

    if not used_next_anim then
      table.insert(results, result)
    end

    return results
  end
end

local function check_switch_sides(player)
  if sign(player.other.pos_x - player.pos_x) * sign(player.other.previous_pos_x - player.previous_pos_x) == -1 then
    return true
  end
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
      str = str .. string.format("%s %d %d -> ",line[i].animation,line[i].frame,line[i].delta)
    end
    print(str)
  end
end

local function insert_projectile(player, motion_data, predicted_hit)
  local fd = frame_data[player.char_str][predicted_hit.animation]
  if fd and fd.frames[predicted_hit.frame + 1] 
  and fd.frames[predicted_hit.frame + 1].projectile then
    local proj_fd = frame_data["projectiles"][fd.frames[predicted_hit.frame + 1].projectile.type]
    local obj = {base = 0, projectile = 99}
    obj.id = fd.frames[predicted_hit.frame + 1].projectile.type .. tostring(gamestate.frame_number + predicted_hit.delta)
    obj.emitter_id = player.id
    obj.alive = true
    obj.projectile_type = fd.frames[predicted_hit.frame + 1].projectile.type
    obj.projectile_start_type = obj.projectile_type
    obj.pos_x = motion_data.pos_x + fd.frames[predicted_hit.frame + 1].projectile.offset[1] * flip_to_sign(motion_data.flip_x)
    obj.pos_y = motion_data.pos_y + fd.frames[predicted_hit.frame + 1].projectile.offset[2]
    obj.velocity_x = proj_fd.frames[1].velocity[1]
    obj.velocity_y = proj_fd.frames[1].velocity[2]
    obj.acceleration_x = proj_fd.frames[1].acceleration[1]
    obj.acceleration_y = proj_fd.frames[1].acceleration[2]
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

local function get_hurtboxes(char, anim, frame)
  if  frame_data[char][anim]
  and frame_data[char][anim].frames
  and frame_data[char][anim].frames[frame + 1]
  and frame_data[char][anim].frames[frame + 1].boxes
  and has_boxes(frame_data[char][anim].frames[frame + 1].boxes, {"vulnerability", "ext. vulnerability"})
  then
    return frame_data[char][anim].frames[frame + 1].boxes
  end
  return nil
end

local function get_pushboxes(player)
  for _, box in pairs(player.boxes) do
    if convert_box_types[box[1]] == "push" then
      return box
    end
  end
  return nil
end

local function get_boxes_lowest_position(boxes, types)
  local min = math.huge
  for _, box in pairs(boxes) do
    local  b = format_box(box)
    for _, type in pairs(types) do
      if b.type == type and b.bottom < min then
        min = b.bottom
      end
    end
  end
  return min
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


  if a_r > b_l and a_l < b_r and a_t > b_b and a_b < b_t then
    return math.min(a_r, b_r) - math.max(a_l, b_l)
  end
  return 0
end

local function get_push_value(dist_from_pb_center, pushbox_overlap_range, push_value_max)
  local p = dist_from_pb_center / pushbox_overlap_range
  if p < .7 then
    local range = math.floor(.7 * pushbox_overlap_range)
    return math.round((range - dist_from_pb_center) / range * (push_value_max - 6) + 6)
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

local function movement_prediction_special_cases()
  --index - 1 == uf sjf, and current anim is ken ex tatsu at frame 0 then

end

local function predict_player_movement(p1, p1_motion_data, p1_line, p2, p2_motion_data, p2_line, index)

  local motion_data = {[p1] = p1_motion_data, [p2] = p2_motion_data}
  local lines = {[p1] = p1_line, [p2] = p2_line}

  local stage = stages[gamestate.stage]

  for player, mdata in pairs(motion_data) do
    mdata[index] = copytable(mdata[index - 1])

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
          local line = predict_frames_branching(player, target_anim, 0, #lines[player] - index + 1, nil, true)[1]
          for j = 1, #line do
            lines[player][index + j - 1] = line[j]
          end
          -- print(index, mdata[index - 1].flip_x, bit.bxor(mdata[index - 1].flip_x, 1))
          -- print_pline(lines[player])

          mdata[index].flip_x = bit.bxor(mdata[index - 1].flip_x, 1)
        end
      end
    end
  end

  for player, mdata in pairs(motion_data) do
    local corner_left = stage.left + character_specific[player.char_str].corner_offset_left
    local corner_right = stage.right - character_specific[player.char_str].corner_offset_right
    local sign = flip_to_sign(mdata[index - 1].flip_x)

    if player.is_in_pushback then
      local pb_frame = gamestate.frame_number + index - player.pushback_start_frame
      local anim = player.last_received_connection_animation
      local hit_id = player.last_received_connection_hit_id

      if anim and hit_id
      and frame_data[player.other.char_str][anim]
      and frame_data[player.other.char_str][anim].pushback
      and frame_data[player.other.char_str][anim].pushback[hit_id]
      and pb_frame <= #frame_data[player.other.char_str][anim].pushback[hit_id]
      then
        local pb_value = frame_data[player.other.char_str][anim].pushback[hit_id][pb_frame]
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

    local fdata = find_move_frame_data(player.char_str, lines[player][index].animation)
    if fdata then
      local next_frame = fdata.frames[lines[player][index].frame + 1]
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
        -- print("next frame not found", lines[player][index].animation, lines[player][index].frame)
      end
    end

    local should_apply_velocity = false
    local previous_frame_data = find_move_frame_data(player.char_str, lines[player][index - 1].animation)

    if (previous_frame_data and previous_frame_data.uses_velocity)
    or mdata[index - 1].pos_y > 0 then
      --first frame of every air move ignores velocity
      if not (mdata[index - 1].frame == 0 and previous_frame_data and previous_frame_data.air) then
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
    --if player is falling
    if fdata and mdata[index].pos_y < mdata[index - 1].pos_y then
      local next_frame = fdata.frames[lines[player][index].frame + 1]
      local boxes_bottom = nil
      if next_frame and next_frame.boxes and has_boxes(next_frame.boxes, {"vulnerability"}) then
        boxes_bottom = mdata[index].pos_y + get_boxes_lowest_position(next_frame.boxes, {"vulnerability"})
      else
        for j = index - 1, 1, -1 do
          local an = lines[player][j].animation
          local f = lines[player][j].frame
          local fd = find_move_frame_data(player.char_str, an)
          if fd and fd.frames then
            local prev_frame = fd.frames[f + 1]
            if prev_frame.boxes and has_boxes(prev_frame.boxes, {"vulnerability"}) then
              boxes_bottom = mdata[index].pos_y + get_boxes_lowest_position(prev_frame.boxes, {"vulnerability"})
            end
          end
        end
      end
      --this is a guess at when landing will occur. not sure what the actual principle is
      --moves like dudley's jump HK/HP allow the player to fall much lower before landing. y_pos of -30 for dudley's j.HP!
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

  --just estimate using current pushboxes, no need to predict
  local p1_pushbox = get_pushboxes(p1)
  local p2_pushbox = get_pushboxes(p2)

  if p1_pushbox and p2_pushbox then
    p1_pushbox = format_box(p1_pushbox)
    p2_pushbox = format_box(p2_pushbox)

    local p1_mdata = motion_data[p1][index]
    local p2_mdata = motion_data[p2][index]

    local overlap = get_horizontal_box_overlap(p1_pushbox, p1_mdata.pos_x, p1_mdata.pos_y, p1_mdata.flip_x,
                                                p2_pushbox, p2_mdata.pos_x, p2_mdata.pos_y, p2_mdata.flip_x)
    if overlap > 1 then
      local push_value_max = math.ceil((character_specific[p1.char_str].push_value
                                  + character_specific[p2.char_str].push_value) / 2)
      local dist_from_pb_center = math.abs(p1_mdata.pos_x - p2_mdata.pos_x)
      local pushbox_overlap_range = (p1_pushbox.width + p2_pushbox.width) / 2
      local push_value = get_push_value(dist_from_pb_center, pushbox_overlap_range, push_value_max)

      local sign =    (p2_mdata.pos_x - p1_mdata.pos_x >= 0 and -1)
                    or (p2_mdata.pos_x - p1_mdata.pos_x < 0 and 1)
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


  for player, mdata in pairs(motion_data) do
    local other_mdata = motion_data[player.other]
    if sign(other_mdata[index].pos_x - mdata[index].pos_x)
    * sign(other_mdata[index - 1].pos_x - mdata[index - 1].pos_x) == -1
    then
      mdata[index].switched_sides = true
    end
  end
end

local function predict_projectile_movement(projectile, mdata, line, index, ignore_flip)
  mdata[index] = copytable(mdata[index - 1])

  local sign = ignore_flip and 1 or flip_to_sign(mdata[index - 1].flip_x)

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
      print("next frame not found", line[index].animation, line[index].frame)
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
        if fdata.frames[frame_to_check].projectile then
          pass = true
          break
        end

        if fdata.hit_frames then
          local next_hit_id = 1
          for i = 1, #fdata.hit_frames do
            if frame > fdata.hit_frames[i][2] then
              next_hit_id = i + 1
            end
          end
          if next_hit_id > player.current_hit_id then
            pass = true
            break
          end
        end
      end
    end
    if pass then
      table.insert(filtered, line)
    end
  end
  return filtered
end

local function predict_everything(player, dummy, frames_prediction)
  --returns all possible sequences of the next 3 frames
  local player_lines = predict_frames_branching(player, player.animation, nil, frames_prediction)
  --filter for lines that contain hit frames or projectiles
  local filtered = filter_lines(player, player_lines) or {}

  -- print(gamestate.frame_number, "---*---")
  -- for _, player_line in pairs(player_lines) do
  --   print_pline(player_line)
  -- end

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

  local dummy_lines = predict_frames_branching(dummy, dummy.animation, nil, frames_prediction)[1]
  if not dummy_lines or #dummy_lines == 0 then
    dummy_lines = create_line(dummy, frames_prediction)
  end
  dummy_lines[0] = {animation = dummy.animation, frame = dummy.animation_frame, delta = 0}

  local predicted_state = {}

  -- print(gamestate.frame_number, "-----")
  for _, player_line in pairs(player_lines) do
    -- print_pline(player_line)
    local player_motion_data = init_motion_data(player)
    local dummy_motion_data = init_motion_data(dummy)
    player_motion_data[0].switched_sides = check_switch_sides(player)
    dummy_motion_data[0].switched_sides = check_switch_sides(dummy)

    local dummy_line = deepcopy(dummy_lines)
    for i = 1, #player_line do
      local predicted_frame = player_line[i]
      local frame = predicted_frame.frame
      local frame_to_check = frame + 1
      local fdata = find_move_frame_data(player.char_str, predicted_frame.animation)

      predict_player_movement(player, player_motion_data, player_line,
                              dummy, dummy_motion_data, dummy_line, i)

      --save data to use for projectile prediction
      predicted_state = {player_motion_data = player_motion_data,
                         player_line = player_line,
                         dummy_motion_data = dummy_motion_data,
                         dummy_line = dummy_line}

      --                    print(i)
      -- print_pline(dummy_line)

      local tfd = frame_data[dummy.char_str][dummy_line[i].animation]
      if tfd and tfd.frames and tfd.frames[dummy_line[i].frame + 1] and tfd.frames[dummy_line[i].frame + 1].boxes then
        local vuln = get_boxes(tfd.frames[dummy_line[i].frame + 1].boxes, {"vulnerability","ext. vulnerability"})
        local color = 0x44097000 + 255 - 70 * i
        -- to_draw_hitboxes[gamestate.frame_number + predicted_frame.delta] = {dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, dummy_motion_data[i].flip_x, vuln, nil, nil, color}
      end
      -- debug_prediction[gamestate.frame_number+predicted_frame.delta] = {[gamestate.P1] = player_motion_data[i], [gamestate.P2] = dummy_motion_data[i]}

      if fdata then
        local frames = fdata.frames
        if frames and frames[frame_to_check] then
          if frames[frame_to_check].projectile then
            insert_projectile(player, player_motion_data[i], predicted_frame)
          end

          if fdata.hit_frames
          and frames[frame_to_check].boxes
          and has_boxes(frames[frame_to_check].boxes, {"attack", "throw"}) then
            local next_hit_id = 1
            for i = 1, #fdata.hit_frames do
              if frame > fdata.hit_frames[i][2] then
                next_hit_id = i + 1
              end
            end

            if next_hit_id > player.current_hit_id then
              local attack_boxes = get_boxes(frames[frame_to_check].boxes, {"attack"})
              to_draw_hitboxes[gamestate.frame_number + predicted_frame.delta] = {player_motion_data[i].pos_x, player_motion_data[i].pos_y, player_motion_data[i].flip_x, attack_boxes, nil, nil, 0xFF941CDD}


              local dummy_boxes = get_hurtboxes(dummy.char_str, dummy_line[i].animation, dummy_line[i].frame)
              if not dummy_boxes then
                dummy_boxes = dummy.boxes
              end
              local box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
              if frame_data_meta[player.char_str][predicted_frame.animation] and frame_data_meta[player.char_str][predicted_frame.animation].hit_throw then
                table.insert(box_type_matches, {{"throwable"}, {"throw"}})
              end

              if test_collision(dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, dummy_motion_data[i].flip_x, dummy_boxes,
                            player_motion_data[i].pos_x, player_motion_data[i].pos_y, player_motion_data[i].flip_x, frames[frame_to_check].boxes,
                            box_type_matches)
              then
                local delta = predicted_frame.delta
                if not fdata.bypass_freeze then
                  delta = delta + player.remaining_freeze_frames
                end
                local expected_attack = {id = player.id, blocking_type = "player", hit_id = next_hit_id, delta = delta, animation = predicted_frame.animation, flip_x = predicted_frame.flip_x}
                table.insert(dummy.blocking.expected_attacks, expected_attack)
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
    if ((projectile.is_forced_one_hit and projectile.remaining_hits ~= 0xFF) or projectile.remaining_hits > 0)
    and projectile.alive then
      if (projectile.emitter_id ~= dummy.id or (projectile.emitter_id == dummy.id and projectile.is_converted)) then
        local frame_delta =  projectile.remaining_freeze_frames - frames_prediction
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
    local dummy_line = predicted_state.dummy_line
    local dummy_motion_data = predicted_state.dummy_motion_data
    for _, projectile in pairs(valid_projectiles) do
      local proj_line = nil
      if projectile.seiei_animation then
        proj_line = predict_frames_branching({type="player", char_str="yang"}, projectile.projectile_type, projectile.animation_frame, frames_prediction)[1]
      else
        proj_line = predict_frames_branching(projectile, projectile.projectile_type, projectile.animation_frame, frames_prediction)[1]
      end
      if not proj_line or #proj_line == 0 then
        proj_line = create_line(projectile, frames_prediction)
      end
      local proj_motion_data = init_motion_data(projectile)
      if projectile.cooldown - frames_prediction <= 0 then
        for i = 1, #dummy_line do
          local remaining_freeze = projectile.remaining_freeze_frames - i
          local remaining_cooldown = projectile.cooldown
          if remaining_freeze <= 0 then
            remaining_cooldown = remaining_cooldown + remaining_freeze
          end

          local proj_boxes = nil
          local ignore_flip = false
          if projectile.projectile_type == "00_tenguishi" then
            proj_boxes = projectile.boxes
            ignore_flip = true
          elseif projectile.seiei_animation then
            local seiei_fd = find_move_frame_data("yang", projectile.seiei_animation)
            if seiei_fd and seiei_fd.frame[projectile.seiei_animation]
            and seiei_fd.frame[projectile.seiei_animation].boxes
            and has_boxes(seiei_fd.frame[projectile.seiei_animation].boxes, {"attack", "throw"})
            then
              proj_boxes = seiei_fd.frame[projectile.seiei_animation].boxes
            end
          else
            local fdata = find_move_frame_data("projectiles", proj_line[i].animation)
            local frame_to_check = proj_line[i].frame + 1
            if fdata then
              local frames = fdata.frames
              if frames
              and frames[frame_to_check]
              and frames[frame_to_check].boxes
              and has_boxes(frames[frame_to_check].boxes, {"attack", "throw"})
              then
                 proj_boxes = frames[frame_to_check].boxes
              end
            end
            if not proj_boxes then
              proj_boxes = projectile.boxes
            end
          end

          predict_projectile_movement(projectile, proj_motion_data, proj_line, i, ignore_flip)

          local dummy_boxes = get_hurtboxes(dummy.char_str, dummy_line[i].animation, dummy_line[i].frame)
          if not dummy_boxes then
            dummy_boxes = dummy.boxes
          end

          if proj_boxes and remaining_cooldown <= 0 then
            local delta = proj_line[i].delta + projectile.remaining_freeze_frames
            local color = 0xa9691c00 + 255 - 70 * delta
            to_draw_hitboxes[gamestate.frame_number + delta] = {proj_motion_data[i].pos_x, proj_motion_data[i].pos_y, proj_motion_data[i].flip_x, proj_boxes, nil, nil, color}
      
            if test_collision(dummy_motion_data[i].pos_x, dummy_motion_data[i].pos_y, dummy_motion_data[i].flip_x, dummy_boxes,
                                  proj_motion_data[i].pos_x, proj_motion_data[i].pos_y, proj_motion_data[i].flip_x, proj_boxes,
                                  box_type_matches)
            then
              local expected_attack = {id = projectile.id, blocking_type = "projectile", hit_id = 1, delta = delta, animation = proj_line[i].animation, flip_x = proj_motion_data[i].flip_x}
              table.insert(dummy.blocking.expected_attacks, expected_attack)
            end
          end
        end
      end
    end
  end
end

local function predict_frames_before_landing(player)
  local dummy = player.other
  local frames_prediction = 15
  local player_lines = predict_frames_branching(player, player.animation, nil, frames_prediction)

  if player_lines[1] and #player_lines[1] > 0 then
    player_lines = {player_lines[1]}
  else
    player_lines = {create_line(player, frames_prediction)}
  end
  for _, player_line in pairs(player_lines) do
    player_line[0] = {animation = player.animation, frame = player.animation_frame, delta = 0}
  end

  local dummy_lines = predict_frames_branching(dummy, dummy.animation, nil, frames_prediction)[1]
  if not dummy_lines or #dummy_lines == 0 then
    dummy_lines = create_line(dummy, frames_prediction)
  end
  dummy_lines[0] = {animation = dummy.animation, frame = dummy.animation_frame, delta = 0}

  for _, player_line in pairs(player_lines) do
    local player_motion_data = init_motion_data(player)
    local dummy_motion_data = init_motion_data(dummy)
    player_motion_data[0].switched_sides = check_switch_sides(player)
    dummy_motion_data[0].switched_sides = check_switch_sides(dummy)

    local dummy_line = deepcopy(dummy_lines)
    for i = 1, #player_line do
      predict_player_movement(player, player_motion_data, player_line,
                              dummy, dummy_motion_data, dummy_line, i)
      if player_motion_data[i].standing_state == 1 then
        return i
      end
    end
  end
  return -1
end

return {
  predict_everything = predict_everything,
  predict_frames_before_landing = predict_frames_before_landing,
  init_motion_data = init_motion_data,
  init_motion_data_zero = init_motion_data_zero
}