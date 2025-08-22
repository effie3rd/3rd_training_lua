local settings = require("src/settings")
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local gamestate = require("src/gamestate")
local prediction = require("src.modules.prediction")
local menu = require("src.ui.menu")
local mem = require("src.control.write_memory")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local test_collision, find_move_frame_data = fd.test_collision, fd.find_move_frame_data
local frame_data_meta = fdm.frame_data_meta

function update_pose(input, player, dummy, pose)
  if current_recording_state == 4 -- Replaying
  or dummy.blocking.is_blocking then
    return
  end

  if gamestate.is_in_match and not menu.is_open and not is_playing_input_sequence(dummy) then
    local on_ground = gamestate.is_state_on_ground(dummy.standing_state, dummy)
    local is_waking_up = dummy.is_wakingup and dummy.remaining_wakeup_time > 0 and dummy.remaining_wakeup_time <= 3
    local wakeup_frame = dummy.standing_state == 0 and dummy.posture == 0

    if pose == 2 and (on_ground or is_waking_up or wakeup_frame) then -- crouch
      input[dummy.prefix..' Down'] = true
    elseif pose == 3 and on_ground then -- jump
      input[dummy.prefix..' Up'] = true
    elseif pose == 4 then -- high jump
      if on_ground and not is_playing_input_sequence(dummy) then
        queue_input_sequence(dummy, {{"down"}, {"up"}})
      end
    end
  end
end

function update_blocking(input, player, dummy, mode, style, red_parry_hit_count, parry_every_n_count)
  -- ensure variables
  dummy.blocking.is_blocking = dummy.blocking.is_blocking or false
  dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count or 0
  dummy.blocking.expected_attacks = {}
  dummy.blocking.last_blocked_attacks = dummy.blocking.last_blocked_attacks or {}
  dummy.blocking.last_blocked_type = dummy.blocking.last_blocked_type or "none"
  dummy.blocking.last_blocked_frame = dummy.blocking.last_blocked_frame or 0
  dummy.blocking.parried_last_frame = dummy.blocking.parried_last_frame or false

  player.cooldown = player.cooldown or 0

  function block_attack(hit_type, block_type, delta, reverse, force_block)
    local p2_forward = bool_xor(dummy.flip_input, reverse)
    local p2_back = not bool_xor(dummy.flip_input, reverse)
    if block_type == 1 and dummy.pos_y <= 8 then --no air blocking!
      input[dummy.prefix..' Right'] = p2_back
      input[dummy.prefix..' Left'] = p2_forward

      if hit_type == 2 then
        input[dummy.prefix..' Down'] = true
      elseif hit_type == 3 or hit_type == 4 then
        input[dummy.prefix..' Down'] = false
      end
      return "block"
    elseif block_type == 2 then
      local parry_type = "parry_forward"
      if dummy.pos_y > 8 then
        parry_type = "parry_air"
      else
        if player.posture == "placeholder" then
          parry_type = "parry_antiair"
        end
      end
      local parry_low = hit_type == 2 or (settings.training.prefer_down_parry and hit_type == 1 and dummy.pos_y <= 8)
      if parry_low then
        parry_type = "parry_down"
      end

      if not (dummy[parry_type].validity_time > delta) or force_block then
        if is_previous_input_neutral(dummy) and not (hit_type == 5) then
          input[dummy.prefix..' Right'] = false
          input[dummy.prefix..' Left'] = false
          input[dummy.prefix..' Down'] = false
          if parry_low then
            input[dummy.prefix..' Down'] = true
          else
            input[dummy.prefix..' Right'] = p2_forward
            input[dummy.prefix..' Left'] = p2_back
          end
          return "parry"
        else
          print("can not parry")
          block_attack(hit_type, 1, delta, reverse)
        end
      end
    end
    return "none"
  end


  if not gamestate.is_in_match then
    return
  end

  -- exit if playing recording
  if mode == 1 or current_recording_state == 4 then
    return
  end
  if mode == 4 then
    local r = math.random()
    if mode ~= 3 or r > 0.5 then
      dummy.blocking.randomized_out = true
    else
      dummy.blocking.randomized_out = false
    end
  end


  predicted_hit_debug = predicted_hit_debug or {}

--[[   if player.char_str == "oro" and player.selected_sa == 3 and player.is_in_timed_sa then
    if player.has_just_acted then
      local fdata = player.animation_frame_data
      if fdata then
        local next_hit_id = player.current_hit_id + 1
        if fdata.hit_frames and fdata.hit_frames[next_hit_id] then
          local delta = fdata.hit_frames[next_hit_id][1] - player.animation_frame + 1
          for _, proj in pairs(gamestate.projectiles) do
            if proj.emitter_id == player.id
            and proj.type == "00_tenguishi"
            then
              proj.cooldown = delta
            end
          end
        end
      end
    end
  else ]]
--[[   if player.char_str == "yang" and player.is_in_timed_sa then
    if player.has_just_attacked then
      local fdata = player.animation_frame_data
      if fdata then
        local next_hit_id = player.current_hit_id + 1
        if fdata.hit_frames and fdata.hit_frames[next_hit_id] then
          local delta = fdata.hit_frames[next_hit_id][1] - player.animation_frame + 1
          for _, proj in pairs(gamestate.projectiles) do
            if proj.emitter_id == player.id
            and proj.type == "00_seieienbu"
            then
              proj.cooldown = 10
              proj.seiei_animation = player.animation
              proj.seiei_frame = player.animation_frame
              insert_projectile(player, motion_data, predicted_hit)
            end
          end
        end
      end
    end
  end ]]

  local frames_prediction = 3
  prediction.predict_everything(player, dummy, frames_prediction)


  if dummy.received_connection then
    dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count + 1
  end

  if dummy.is_idle then
    if player.is_idle then
      dummy.blocking.blocked_hit_count = 0
    end
    dummy.blocking.is_blocking = false
  end


  if not (mode == 4 and dummy.blocking.randomized_out) 
  and not (mode == 3 and dummy.blocking.blocked_hit_count > 0) then
    --     print(string.format("%d - should block %s", gamestate.frame_number, tostring(dummy.blocking.should_block)))
    local block_type = style -- 1 is block, 2 is parry
    local blocking_delta_threshold = 2
    local precise_blocking = false
    local blocking_queue = {}

    if style == 3 then -- red parry
      block_type = 1
      blocking_delta_threshold = 1
      precise_blocking = true
      if dummy.blocking.blocked_hit_count >= red_parry_hit_count then
        if (dummy.blocking.blocked_hit_count - red_parry_hit_count) % (parry_every_n_count + 1) == 0 then
          block_type = 2
        end
      end
    end

    if dummy.blocking.forced_block then
      local d = dummy.blocking.forced_block.delta
      if blocking_queue[d] == nil then
        blocking_queue[d] = {}
        blocking_queue[d].hit_type = dummy.blocking.forced_block.hit_type
        blocking_queue[d].blocking_type = dummy.blocking.forced_block.blocking_type
        blocking_queue[d].attacks = {}
      end
      for _, attack in pairs(dummy.blocking.forced_block.attacks) do
        if attack.blocking_type == "projectile" then
          attack.reverse = attack.flip_x == dummy.flip_input
        end
        table.insert(blocking_queue[d].attacks, attack)
      end
      dummy.blocking.forced_block = nil
    end

    for i = 1, #dummy.blocking.expected_attacks do
      local expected_attack = dummy.blocking.expected_attacks[i]
      local expected_attack_delta = expected_attack.delta
      local hit_type = 1

      if blocking_queue[expected_attack_delta] == nil then
        blocking_queue[expected_attack_delta] = {}
        blocking_queue[expected_attack_delta].hit_type = 0
        blocking_queue[expected_attack_delta].attacks = {}
      end

      if expected_attack.blocking_type == "projectile" then
        local fdata_meta = frame_data_meta["projectiles"][expected_attack.animation]
        if fdata_meta and fdata_meta.hit_type then
          hit_type = fdata_meta.hit_type[expected_attack.hit_id]
        end
      else
        local fdata_meta = frame_data_meta[player.char_str][expected_attack.animation]
        if fdata_meta then
          if fdata_meta.hit_type and fdata_meta.hit_type[expected_attack.hit_id] then
            hit_type = fdata_meta.hit_type[expected_attack.hit_id] --debug
          end
          if fdata_meta.unparryable then
            blocking_queue[expected_attack_delta].unparryable = true
          end
        end
      end

      if hit_type > blocking_queue[expected_attack_delta].hit_type then
        if settings.training.prefer_down_parry and blocking_queue[expected_attack_delta].hit_type == 1 then
          blocking_queue[expected_attack_delta].hit_type = 2
        else
          blocking_queue[expected_attack_delta].hit_type = hit_type
        end
        if expected_attack.blocking_type == "projectile" then
          expected_attack.reverse = expected_attack.flip_x == dummy.flip_input
        end
        table.insert(blocking_queue[expected_attack_delta].attacks, expected_attack)
      end

      -- print(gamestate.frame_number, expected_attack_delta, expected_attack.blocking_type, expected_attack.animation, dummy.current_hit_id, expected_attack.hit_id)
    end

    function should_ignore(attack)
      for _, last_blocked_attack in pairs(dummy.blocking.last_blocked_attacks) do
        if (attack.id == 1 or attack.id == 2) and attack.id == last_blocked_attack.id then
          if attack.animation == last_blocked_attack.animation then
            if attack.hit_id > last_blocked_attack.hit_id then
              return false
            else
              return true
            end
          end
        elseif attack.animation == last_blocked_attack.animation then
          if gamestate.frame_number - last_blocked_attack.connect_frame <= blocking_delta_threshold then
            return true
          end
        end
      end
      return false
    end

    for key, attack in pairs(dummy.blocking.last_blocked_attacks) do
      if attack.connect_frame <= gamestate.frame_number then
        dummy.blocking.last_blocked_attacks[key] = nil
      end
    end

    local next_attacks = {}
    local delta = 0
    --attacks must be blocked/parried 1 frame before they actually hit
    --blocking_delta_threshold = 1 at a minimum
    for i = 1, blocking_delta_threshold do
      if blocking_queue[i] then
        for _, attack in pairs(blocking_queue[i].attacks) do
          if precise_blocking then
            if not should_ignore(attack) then
              table.insert(next_attacks, attack)
            end
          else
            table.insert(next_attacks, attack)
          end
        end
      end
      if #next_attacks > 0 then
        delta = i
        break
      end
    end

    if #next_attacks > 0 then
      dummy.blocking.is_blocking = true
      local reverse = false
      local force_block = false
      for _, attack in pairs(next_attacks) do
        --reverse blocking direction for projectiles created on the opposite side (parrying out of unblockables)
        if attack.reverse then
          reverse = true
        end
        local t = attack.animation or attack.projectile_type
        print(blocking_queue[delta], delta)
        print(string.format("#%d - hit in [%d] type: %s hit type: %d", gamestate.frame_number, attack.delta, t, blocking_queue[delta].hit_type))
      end
      
      if block_type == 2 and blocking_queue[delta] and blocking_queue[delta + 1] then
        if blocking_queue[delta].hit_type == 1 and blocking_queue[delta + 1].hit_type ~= 1 then
          blocking_queue[delta].hit_type = blocking_queue[delta + 1].hit_type
        end
      end

      if block_type == 2 then
        if blocking_queue[delta].unparryable then
          block_type = 1
        end
--[[         if not dummy.blocking.parried_last_frame
        and not (blocking_queue[delta + 1]
        and blocking_queue[delta].hit_type == blocking_queue[delta + 1].hit_type)
        then
          print("force bl")
          force_block = true
        end ]]

        --parrying 1f startup supers after screen darkening is impossible...
        --so we cheat! has the added benefit of not messing up parry inputs after screen darkening
        if player.superfreeze_decount > 0 then
          mem.enable_cheat_parrying(player)
        end
      end

      if not (block_type == 1 and dummy.blocking.parried_last_frame) then
        dummy.blocking.last_blocked_type = block_attack(blocking_queue[delta].hit_type, block_type, delta, reverse, force_block)
        if dummy.blocking.last_blocked_type ~= "none" then
          dummy.blocking.last_blocked_frame = gamestate.frame_number
          for _, attack in pairs(next_attacks) do
            attack.connect_frame = gamestate.frame_number + delta
          end
          if (block_type == 1 and delta == 1)
          or block_type == 2 then
            dummy.blocking.last_blocked_attacks = next_attacks
          end
          if (style == 1 and delta > 1 )
          or (block_type == 1 and delta > 1 and dummy.blocking.blocked_hit_count == 0) then
            dummy.blocking.forced_block = {delta = delta - 1,
                                            attacks = next_attacks,
                                            blocking_type = blocking_queue[delta].blocking_type,
                                            hit_type = blocking_queue[delta].hit_type}
          end
        end
      end
    end



    dummy.blocking.parried_last_frame = false
    if dummy.blocking.last_blocked_type == "parry"
    and gamestate.frame_number - dummy.blocking.last_blocked_frame == 0
    then
      dummy.blocking.parried_last_frame = true
    end
  end
end



local stun_mash_start_frame = 1
local mash_inputs_realistic =
{
  {{"down","forward"}},
  {{"down"}},
  {{"down","back"}},
  {{"back"}},
  {{"up","back"}},
  {{"up"}},
  {{"up","forward"}},
  {{"forward"}}
}
local mash_inputs_fastest =
{
  {{"down","forward"}},
  {{"down","back"}}
}
local mash_inputs = mash_inputs_fastest
local all_buttons = {"LP","LK","MP","MK","HP","HK"}

function update_mash_stun(input, player, dummy, mode)
  if gamestate.is_in_match and mode ~= 1 and current_recording_state ~= 4 then
    if dummy.stun_just_began then
      stun_mash_start_frame = gamestate.frame_number
      if mode == 2 then
        mash_inputs = mash_inputs_fastest
      elseif mode == 3 then
        mash_inputs = mash_inputs_realistic
      end
    end
    if dummy.stunned then
      --try to prevent move from coming out
      --diagonal input reduces stun by 3
      --pressing all buttons reduces stun by 4 more
      if dummy.stun_timer <= 15 and dummy.stun_timer > 0 then
        mash_inputs = mash_inputs_fastest
      end
      local elapsed = gamestate.frame_number - stun_mash_start_frame
      local sequence = deepcopy(mash_inputs[elapsed % #mash_inputs + 1])
      if dummy.stun_timer >= 8 then
        if mode == 2 then
          if elapsed % 2 == 0 then
            for _,button in pairs(all_buttons) do
              table.insert(sequence[1], button)
            end
          end
        elseif mode == 3 then
          table.insert(sequence[1], all_buttons[elapsed % 3 + 1])
          table.insert(sequence[1], all_buttons[6 - elapsed % 3])
        end
      end
      queue_input_sequence(dummy, sequence)
    end
  end
end

function update_fast_wake_up(input, player, dummy, mode)
  if gamestate.is_in_match and mode ~= 1 and current_recording_state ~= 4 then
    local should_tap_down = dummy.previous_can_fast_wakeup == 0 and dummy.can_fast_wakeup == 1

    if should_tap_down then
      local r = math.random()
      if mode ~= 3 or r > 0.5 then
        input[dummy.prefix..' Down'] = true
      end
    end
  end
end

function get_stun_reduction_value(sequence)
  local n_kicks = 0
  local total = 0
  for i = 1, #sequence do
    local has_dir = false
    for j = 1, #sequence[i] do
      if sequence[i][j] == "forward"
      or sequence[i][j] == "back"
      or sequence[i][j] == "up"
      or sequence[i][j] == "down" then
        total = total + 1
        has_dir = true
      elseif sequence[i][j] == "LP"
      or sequence[i][j] == "MP"
      or sequence[i][j] == "HP" then
        total = total + 1
      elseif sequence[i][j] == "LK"
      or sequence[i][j] == "MK"
      or sequence[i][j] == "HK" then
        n_kicks = n_kicks + 1
      end
    end
  end
  return total + #sequence + math.floor(n_kicks / 3)
end

local guard_jumps =
{
  "guard_jump_back",
  "guard_jump_neutral",
  "guard_jump_forward",
  "guard_jump_back_air_parry",
  "guard_jump_neutral_air_parry",
  "guard_jump_forward_air_parry"
}

local function is_guard_jump(str)
  for i = 1, #guard_jumps do
    if str == guard_jumps[i] then
      return true
    end
  end
  return false
end

local wakeup_queued = false
function update_counter_attack(input, attacker, defender, counter_attack_settings, hits_before)
  local debug = false

  if not gamestate.is_in_match then return end
  if current_recording_state == 4 then return end

  if defender.posture ~= 0x26 then
    wakeup_queued = false
  end

  function handle_recording()
    if counter_attack_settings.ca_type == 5 and defender.id == 2 then
      local slot_index = settings.training.current_recording_slot
      if settings.training.replay_mode == 2 or settings.training.replay_mode == 5 then
        slot_index = find_random_recording_slot()
      elseif settings.training.replay_mode == 3 or settings.training.replay_mode == 6 then
        slot_index = go_to_next_ordered_slot()
      end
      if slot_index < 0 then
        return
      end

      defender.counter.counter_type = "recording"
      defender.counter.recording_slot = slot_index

      local delay = recording_slots[defender.counter.recording_slot].delay or 0
      local random_deviation = recording_slots[defender.counter.recording_slot].random_deviation or 0
      if random_deviation <= 0 then
        random_deviation = math.ceil(math.random(random_deviation - 1, 0))
      else
        random_deviation = math.floor(math.random(0, random_deviation + 1))
      end
      if debug then
        print(string.format("frame offset: %d", delay + random_deviation))
      end
      defender.counter.attack_frame = defender.counter.attack_frame + delay + random_deviation
    end
  end
  if defender.blocking.blocked_hit_count >= hits_before then
    if defender.has_just_parried then
      if debug then
        print(gamestate.frame_number.." - init ca (parry)")
      end
      log(defender.prefix, "counter_attack", "init ca (parry)")
      defender.counter.counter_type = "reversal"
      defender.counter.attack_frame = gamestate.frame_number + 15
      if defender.pos_y >= 8 then
        defender.counter.attack_frame = defender.counter.attack_frame + 2
      end
      if counter_attack_settings.ca_type == 3 then
        defender.counter.attack_frame = defender.counter.attack_frame + 1
      end
      defender.counter.sequence, defender.counter.offset = make_input_sequence(defender.char_str, counter_attack_settings)
      if counter_attack_special_types[counter_attack_settings.special] == "kara_special" then
        defender.counter.offset = defender.counter.offset + 1
        if counter_attack_special_names[counter_attack_settings.special] == "kara_karakusa_lk" then
          for i = 1, 8 do
            table.insert(defender.counter.sequence, 2, {})
          end
        end
      elseif counter_attack_special_names[counter_attack_settings.special] == "sgs" then
        defender.counter.offset = defender.counter.offset + 4
      end
      defender.counter.ref_time = -1
      handle_recording()

    elseif defender.has_just_blocked or (defender.has_just_been_hit and not defender.is_being_thrown) then
      if debug then
        print(gamestate.frame_number.." - init ca (hit/block)")
      end
      log(defender.prefix, "counter_attack", "init ca (hit/block)")
      defender.counter.ref_time = defender.recovery_time
      clear_input_sequence(defender)
      defender.counter.attack_frame = -1
      defender.counter.sequence = nil
      defender.counter.recording_slot = -1
    elseif defender.is_wakingup and defender.remaining_wakeup_time > 0
    and defender.remaining_wakeup_time <= 20 and not wakeup_queued then
      if debug then
        print(gamestate.frame_number.." - init ca (wake up)")
      end
      log(defender.prefix, "counter_attack", "init ca (wakeup)")
      defender.counter.attack_frame = gamestate.frame_number + defender.remaining_wakeup_time
      wakeup_queued = true
      if counter_attack_settings.ca_type == 4 then
        local os = counter_attack_option_select[counter_attack_settings.option_select]
        if is_guard_jump(os) then
          defender.counter.counter_type = "guard_jump"
          defender.counter.attack_frame = defender.counter.attack_frame - 4 --avoid hj input
        else
          defender.counter.counter_type = "other_os"
        end
      elseif (counter_attack_settings.ca_type == 2 and counter_attack_motion[counter_attack_settings.motion] == "kara_throw") then
        defender.counter.counter_type = "reversal"
        defender.counter.attack_frame = defender.counter.attack_frame
      else
        defender.counter.counter_type = "reversal"
        defender.counter.attack_frame = defender.counter.attack_frame + 2
      end
      defender.counter.sequence, defender.counter.offset = make_input_sequence(defender.char_str, counter_attack_settings)
      defender.counter.ref_time = -1
      handle_recording()
    elseif defender.has_just_entered_air_recovery then
      clear_input_sequence(defender)
      defender.counter.counter_type = "reversal"
      defender.counter.ref_time = -1
      defender.counter.attack_frame = gamestate.frame_number + 100
      defender.counter.sequence, defender.counter.offset = make_input_sequence(defender.char_str, counter_attack_settings)
      defender.counter.air_recovery = true
      handle_recording()
      log(defender.prefix, "counter_attack", "init ca (air)")
    end
  end

  if not defender.counter.sequence then --has just blocked/been hit
    if defender.counter.ref_time ~= -1 and defender.recovery_time ~= defender.counter.ref_time then
      if debug then
        print(gamestate.frame_number.." - setup ca")
      end
      log(defender.prefix, "counter_attack", "setup ca")
      defender.counter.attack_frame = gamestate.frame_number + defender.recovery_time

      -- special character cases
      if defender.is_crouched then
        if (defender.char_str == "q" or defender.char_str == "ryu" or defender.char_str == "chunli") then
          defender.counter.attack_frame = defender.counter.attack_frame + 2
        end
      else
        if defender.char_str == "q" then
          defender.counter.attack_frame = defender.counter.attack_frame + 1
        end
      end

      defender.counter.counter_type = "reversal"

      if counter_attack_settings.ca_type == 4 then
        local os = counter_attack_option_select[counter_attack_settings.option_select]
        if is_guard_jump(os) then
          defender.counter.counter_type = "guard_jump"
          defender.counter.attack_frame = defender.counter.attack_frame - 3 --avoid hj input
        else
          defender.counter.counter_type = "other_os"
        end
      elseif counter_attack_settings.ca_type == 2 and counter_attack_motion[counter_attack_settings.motion] == "kara_throw" then

      else
        defender.counter.attack_frame = defender.counter.attack_frame + 2
      end
      defender.counter.sequence, defender.counter.offset = make_input_sequence(defender.char_str, counter_attack_settings)
      defender.counter.ref_time = -1
      handle_recording()
    end
  end

  if defender.counter.sequence then
    if defender.counter.air_recovery then
      local frames_before_landing = prediction.predict_frames_before_landing(defender)
      print(frames_before_landing)
      if frames_before_landing > 0 then
        defender.counter.attack_frame = gamestate.frame_number + frames_before_landing + 2
      elseif frames_before_landing == 0 then
        defender.counter.attack_frame = gamestate.frame_number
      end
    end
    if defender.stunned then
      local seq_stun_reduction = get_stun_reduction_value(defender.counter.sequence)
      if seq_stun_reduction <= defender.stun_timer then

      end
    end
    local frames_remaining = defender.counter.attack_frame - gamestate.frame_number
    if debug then
      print(frames_remaining)
    end

    --option select
    if counter_attack_settings.ca_type == 4 or (counter_attack_settings.ca_type == 2 and counter_attack_motion[counter_attack_settings.motion] == "kara_throw") then
      if frames_remaining <= 0 then
        print(defender.counter.attack_frame, gamestate.frame_number-defender.counter.attack_frame, #defender.counter.sequence, defender.counter.offset)
        queue_input_sequence(defender, defender.counter.sequence, defender.counter.offset)
        defender.counter.sequence = nil
        defender.counter.attack_frame = -1
        defender.counter.air_recovery = false
      end
    elseif defender.counter.counter_type == "reversal" then
      if frames_remaining <= (#defender.counter.sequence + 1) then
        if debug then
          print(gamestate.frame_number.." - queue ca")
        end
        log(defender.prefix, "counter_attack", string.format("queue ca %d", frames_remaining))
        queue_input_sequence(defender, defender.counter.sequence, defender.counter.offset)
        defender.counter.sequence = nil
        defender.counter.attack_frame = -1
        defender.counter.air_recovery = false
      end
    end
  elseif counter_attack_settings.ca_type == 5 and defender.counter.recording_slot > 0 then
    if defender.counter.attack_frame <= (gamestate.frame_number + 1) then
      if settings.training.replay_mode == 2 or settings.training.replay_mode == 3 or settings.training.replay_mode == 5 or settings.training.replay_mode == 6 then
        override_replay_slot = defender.counter.recording_slot
      end
      if debug then
        print(gamestate.frame_number.." - queue recording")
      end
      log(defender.prefix, "counter_attack", "queue recording")
      defender.counter.attack_frame = -1
      defender.counter.recording_slot = -1
      defender.counter.air_recovery = false
      set_recording_state(input, 1)
      set_recording_state(input, 4)
      override_replay_slot = -1
    end
  end

  --debug cancel CA if going to get hit. trade is ok
  if counter_attack_settings.ca_type > 1 then
    if defender.blocking.should_block or defender.blocking.should_block_projectile then
      if defender.pending_input_sequence and defender.pending_input_sequence.sequence then
        local remaining_frames = #defender.pending_input_sequence.sequence - defender.pending_input_sequence.current_frame
        if remaining_frames >= defender.blocking.animation_frame_delta then
          clear_input_sequence(defender)
        end
      end
    end
  end
end

local tech_throw_frame = 0
function update_tech_throws(input, attacker, defender, mode)
  if not gamestate.is_in_match or mode == 1 then
    return
  end
  if defender.has_just_been_thrown then
    --latest possible tech
    --can add code for earliest tech later, would require prediction of throw boxes
    tech_throw_frame = gamestate.frame_number + 3
  end
  if gamestate.frame_number == tech_throw_frame then
    local r = math.random()
    if mode ~= 3 or r > 0.5 then
      input[defender.prefix..' Weak Punch'] = true
      input[defender.prefix..' Weak Kick'] = true
    end
  end
end