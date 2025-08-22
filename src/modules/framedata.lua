local frame_data = {}

local slow_jumpers =
{
  "alex",
  "necro",
  "urien",
  "remy",
  "twelve",
  "oro"
}

local really_slow_jumpers =
{
  "q",
  "hugo"
}

local function is_slow_jumper(str)
  for i = 1, #slow_jumpers do
    if str == slow_jumpers[i] then
      return true
    end
  end
  return false
end

local function is_really_slow_jumper(str)
  for i = 1, #really_slow_jumpers do
    if str == really_slow_jumpers[i] then
      return true
    end
  end
  return false
end


-- # Character specific stuff
local character_specific = {}
for i = 1, #Characters do
  character_specific[Characters[i]] = {}
  character_specific[Characters[i]].timed_sa = {false, false, false}
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


local function test_collision(defender_x, defender_y, defender_flip_x, defender_boxes, attacker_x, attacker_y, attacker_flip_x, attacker_boxes, box_type_matches, defender_hurtbox_dilation_x, defender_hurtbox_dilation_y, attacker_hitbox_dilation_x, attacker_hitbox_dilation_y)
-- to_draw_collision = {}
  local debug = false
  if (defender_hurtbox_dilation_x == nil) then defender_hurtbox_dilation_x = 0 end
  if (defender_hurtbox_dilation_y == nil) then defender_hurtbox_dilation_y = 0 end
  if (attacker_hitbox_dilation_x == nil) then attacker_hitbox_dilation_x = 0 end
  if (attacker_hitbox_dilation_y == nil) then attacker_hitbox_dilation_y = 0 end
  if (box_type_matches == nil) then box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}} end

  if (#box_type_matches == 0 ) then return false end
  if (#defender_boxes == 0 ) then return false end
  if (#attacker_boxes == 0 ) then return false end
  if debug then print(string.format("   %d defender boxes, %d attacker boxes", #defender_boxes, #attacker_boxes)) end
  for k = 1, #box_type_matches do
    local box_type_match = box_type_matches[k]
    for i = 1, #defender_boxes do
      local d_box = format_box(defender_boxes[i])

      --print("d "..d_box.type)

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
          local a_box = format_box(attacker_boxes[j])

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
            -- table.insert(to_draw_collision, {d_l, d_r, d_b, d_t})
            -- table.insert(to_draw_collision, {a_l, a_r, a_b, a_t})
--             print(gamestate.frame_number, defender_x, d_box.left, d_box.width, d_box.bottom, d_box.height)

            if debug then print(string.format("   testing (%d,%d,%d,%d)(%s) against (%d,%d,%d,%d)(%s)", d_t, d_r, d_b, d_l, d_box.type, a_t, a_r, a_b, a_l, a_box.type)) end

            -- check collision
            if
            (a_l < d_r) and
            (a_r > d_l) and
            (a_b < d_t) and
            (a_t > d_b)
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
local function get_wakeup_time(char, anim, frame)
  if not frame_data[char] or not frame_data[char][anim] then
    return 0
  end
  local i = 1
  local wakeup_time = 0
  local frame_to_check = frame + 1
  local fdata = frame_data[char][anim]
  local frames = fdata.frames
  local used_next_anim = false
  while i <= max_wakeup_time do
    if frames then
      used_next_anim = false
      if frames[frame_to_check].next_anim then
        local a = frames[frame_to_check].next_anim[1][1]
        local f = frames[frame_to_check].next_anim[1][2]
        fdata = frame_data[char][a]
        if fdata then
          frames = fdata.frames
          frame_to_check = f + 1
          used_next_anim = true
        else
          return wakeup_time
        end
      end

      wakeup_time = wakeup_time + 1

      if not used_next_anim then
        i = i + 1
        frame_to_check = frame_to_check + 1
      end

      if frames and frames[frame_to_check].wakeup then
        return wakeup_time
      end
    end
  end
  return wakeup_time
end

local function find_frame_data_by_name(char, name)
  local fdata = frame_data[char]
  if fdata then
    for k, data in pairs(fdata) do
      if data.name == name then
        return k, data
      end
    end
  end
  return nil
end

local function find_move_frame_data(char_str, animation_id)
  if not frame_data[char_str] then return nil end
  return frame_data[char_str][animation_id]
end

return {
  frame_data = frame_data,
  character_specific = character_specific,
  is_slow_jumper = is_slow_jumper,
  is_really_slow_jumper = is_really_slow_jumper,
  test_collision = test_collision,
  get_wakeup_time = get_wakeup_time,
  find_frame_data_by_name = find_frame_data_by_name,
  find_move_frame_data = find_move_frame_data
}