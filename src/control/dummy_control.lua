local settings = require("src.settings")
local fd = require("src.data.framedata")
local fdm = require("src.data.framedata_meta")
local gamestate = require("src.gamestate")
local inputs = require("src.control.inputs")
local prediction = require("src.data.prediction")
local write_memory = require("src.control.write_memory")
local recording = require("src.control.recording")
local tools = require("src.tools")
local utils = require("src.data.utils")
local debug_settings = require("src.debug_settings")

local frame_data_meta = fdm.frame_data_meta
local Pools = tools.Pools

local module_name = "dummy_control"

local poses = {
   STANDING = 1,
   CROUCHING = 2,
   JUMP_FORWARD = 3,
   JUMP_NEUTRAL = 4,
   JUMP_BACK = 5,
   SJUMP_FORWARD = 6,
   SJUMP_NEUTRAL = 7,
   SJUMP_BACK = 8,
}
local Blocking_Mode = { OFF = 1, ON = 2, FIRST_HIT = 3, AFTER_FIRST_HIT = 4, RANDOM = 5 }
local Blocking_Style = { BLOCK = 1, PARRY = 2, RED_PARRY = 3 }
local Blocking_Type = { BLOCK = 1, PARRY = 2, NEUTRAL = 3, NONE = 4 }
local Force_Blocking_Direction = { OFF = 1, ALWAYS_LOW = 2, ALWAYS_HIGH = 3 }
local force_block_timeout = 20
local COUNTER_ATTACK_TYPE = { NONE = 1, NORMAL = 2, SPECIAL_SA = 3, OPTION_SELECT = 4, RECORDING = 5 }
local RECOVERY_TYPE = { NONE = 1, PARRY = 2, CONNECTION = 3, WAKEUP = 4, AIR = 5, STUN = 6 }
local guard_jumps = {
   "guard_jump_back",
   "guard_jump_neutral",
   "guard_jump_forward",
   "guard_jump_back_air_parry",
   "guard_jump_neutral_air_parry",
   "guard_jump_forward_air_parry",
}

local disable = {}
local function disable_update(name, value)
   disable[name] = value
end

local function update_pose(input, dummy, pose)
   if
      recording.current_recording_state == recording.RECORDING_STATE.POSITIONING
      or recording.current_recording_state == recording.RECORDING_STATE.REPLAYING
      or dummy.blocking.is_blocking --
      or dummy.is_stunned --
      or disable.pose
   then
      return
   end
   if
      gamestate.is_in_match
      and not inputs.is_playing_input_sequence(dummy)
      and inputs.is_all_inputs_clear(inputs.input, dummy.id)
   then
      local on_ground = gamestate.is_ground_state(dummy, dummy.standing_state)
      local is_waking_up = dummy.is_waking_up and dummy.remaining_wakeup_time > 0 and dummy.is_past_fast_wakeup_input_frame
      local wakeup_frame = dummy.standing_state == 0 and dummy.posture == 0 and dummy.previous_posture == 0x26

      if pose == poses.CROUCHING and (on_ground or is_waking_up or wakeup_frame) then
         inputs.queue_input_sequence(dummy, { { "down" } })
      elseif on_ground then
         if pose == poses.JUMP_FORWARD and on_ground then
            inputs.queue_input_sequence(dummy, { { "up", "forward" }, { "up", "forward" }, { "up", "forward" } })
         elseif pose == poses.JUMP_NEUTRAL and on_ground then
            inputs.queue_input_sequence(dummy, { { "up" }, { "up" }, { "up" } })
         elseif pose == poses.JUMP_BACK and on_ground then
            inputs.queue_input_sequence(dummy, { { "up", "back" }, { "up", "back" }, { "up", "back" } })
         elseif pose == poses.SJUMP_FORWARD and on_ground then
            inputs.queue_input_sequence(
               dummy,
               { { "down" }, { "up", "forward" }, { "up", "forward" }, { "up", "forward" } }
            )
         elseif pose == poses.SJUMP_NEUTRAL and on_ground then
            inputs.queue_input_sequence(dummy, { { "down" }, { "up" }, { "up" }, { "up" } })
         elseif pose == poses.SJUMP_BACK and on_ground then
            inputs.queue_input_sequence(dummy, { { "down" }, { "up", "back" }, { "up", "back" }, { "up", "back" } })
         end
      end
   end
end

local function update_blocking(input, dummy, blocking_options)
   local player = dummy.other

   local function has_enough_parry_validity(parry_type, delta)
      return (not dummy.is_blocking and dummy[parry_type].validity_time > delta)
         or (dummy.is_blocking and dummy[parry_type].validity_time == dummy[parry_type].max_validity)
   end

   local function block_attack(hit_type, block_type, parry_type, delta, side)
      local p2_forward = side == 1
      local p2_back = side == 2
      local sub_type = "high"

      if block_type == Blocking_Type.BLOCK and dummy.pos_y <= 8 then -- no air blocking!
         input[dummy.prefix .. " Right"] = p2_back
         input[dummy.prefix .. " Left"] = p2_forward

         if hit_type == 2 then
            input[dummy.prefix .. " Down"] = true
            sub_type = "low"
         elseif hit_type == 3 or hit_type == 4 then
            input[dummy.prefix .. " Down"] = false
         end
         return {
            type = "block",
            sub_type = sub_type,
            hit_type = hit_type,
            frame_number = gamestate.frame_number,
            side = side,
         }
      elseif block_type == Blocking_Type.PARRY then
         -- don't parry if it would result in a dash
         if
            not dummy.is_blocking
            and not dummy.blocking.last_block.has_connected
            and gamestate.frame_number - dummy.blocking.last_block.frame_number <= 7
            and (
               (dummy.blocking.last_block.inputs.Right and p2_forward)
               or (dummy.blocking.last_block.inputs.Left and p2_back)
            )
         then
            if has_enough_parry_validity(parry_type, delta) then
               return {
                  type = "parry",
                  sub_type = "pass",
                  hit_type = hit_type,
                  frame_number = gamestate.frame_number,
                  side = side,
               }
            else
               return block_attack(hit_type, Blocking_Type.BLOCK, parry_type, delta, side)
            end
         end
         if dummy[parry_type].cooldown_time > 0 then
            if has_enough_parry_validity(parry_type, delta) then
               return {
                  type = "parry",
                  sub_type = "pass",
                  hit_type = hit_type,
                  frame_number = gamestate.frame_number,
                  side = side,
               }
            else
               return block_attack(hit_type, Blocking_Type.BLOCK, parry_type, delta, side)
            end
         else
            if inputs.is_input_neutral(dummy, inputs.previous_input) and not (hit_type == 5) then
               input[dummy.prefix .. " Right"] = false
               input[dummy.prefix .. " Left"] = false
               input[dummy.prefix .. " Down"] = false
               if parry_type == "parry_down" then
                  input[dummy.prefix .. " Down"] = true
               else
                  input[dummy.prefix .. " Right"] = p2_forward
                  input[dummy.prefix .. " Left"] = p2_back
               end
               sub_type = string.sub(parry_type, 7, #parry_type)
               return {
                  type = "parry",
                  sub_type = sub_type,
                  hit_type = hit_type,
                  frame_number = gamestate.frame_number,
                  side = side,
               }
            else
               -- can not parry
               return block_attack(hit_type, Blocking_Type.BLOCK, parry_type, delta, side)
            end
         end
      elseif block_type == Blocking_Type.NEUTRAL then
         return {
            type = "parry",
            sub_type = "pre_parry",
            hit_type = hit_type,
            frame_number = gamestate.frame_number,
            side = side,
         }
      end
      return nil
   end

   local function force_block(block_inputs, last_block)
      for dir, value in pairs(block_inputs) do
         input[dummy.prefix .. " " .. dir] = value
      end
      return {
         type = "block",
         sub_type = last_block.sub_type,
         hit_type = last_block.hit_type,
         frame_number = gamestate.frame_number,
         side = last_block.side,
      }
   end

   local function get_hit_type(attacks, block_type, prefer_block_low, prefer_parry_low)
      local result = { hit_type = 1 }
      if
         (prefer_block_low and block_type == Blocking_Type.BLOCK)
         or (prefer_parry_low and block_type == Blocking_Type.PARRY)
      then
         result.hit_type = 2
      end
      for _, attack in pairs(attacks) do
         local hit_type = 1
         local fdata_meta
         if attack.blocking_type == "projectile" then
            fdata_meta = frame_data_meta["projectiles"][attack.animation]
         else
            fdata_meta = frame_data_meta[player.char_str][attack.animation]
         end
         if attack.is_seieienbu then
            hit_type = 1
            fdata_meta = nil
         end
         if fdata_meta then
            if fdata_meta.hit_type and fdata_meta.hit_type[attack.hit_id] then
               hit_type = fdata_meta.hit_type[attack.hit_id]
            end
            if fdata_meta.unparryable then
               result.unparryable = true
            end
            if fdata_meta.unblockable then
               result.unblockable = true
            end
         end

         if hit_type > result.hit_type then
            if block_type == Blocking_Type.PARRY and prefer_parry_low and hit_type == 1 then
               result.hit_type = 2
            elseif block_type == Blocking_Type.BLOCK and prefer_block_low and hit_type ~= 4 then
               result.hit_type = 2
            else
               result.hit_type = hit_type
            end
         end
      end
      return result.hit_type, result.unparryable, result.unblockable
   end

   -- ensure variables
   dummy.blocking.is_blocking = dummy.blocking.is_blocking or false
   dummy.blocking.is_blocking_this_frame = false
   dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count or 0
   dummy.blocking.last_parry_index = dummy.blocking.last_parry_index or 0
   dummy.blocking.last_block_type = dummy.blocking.last_block_type or Blocking_Type.NONE
   dummy.blocking.received_hit_count = dummy.blocking.received_hit_count or 0
   dummy.blocking.parried_last_frame = dummy.blocking.parried_last_frame or false
   dummy.blocking.is_pre_parrying = false
   dummy.blocking.pre_parry_frame = dummy.blocking.pre_parry_frame or 0
   dummy.blocking.last_block = dummy.blocking.last_block or { frame_number = 0 }
   dummy.blocking.tracked_attacks = dummy.blocking.tracked_attacks or {}
   dummy.blocking.force_block_start_frame = dummy.blocking.force_block_start_frame or 0

   if dummy.just_received_connection or dummy.has_just_been_thrown then
      dummy.blocking.received_hit_count = dummy.blocking.received_hit_count + 1
      dummy.blocking.last_block.has_connected = true
   end

   if dummy.has_just_blocked then
      dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count + 1
      dummy.blocking.last_block_type = Blocking_Type.BLOCK
   elseif dummy.has_just_parried then
      dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count + 1
      dummy.blocking.last_block_type = Blocking_Type.PARRY
      dummy.blocking.last_parry_index = dummy.blocking.blocked_hit_count
   end

   if dummy.is_idle and player.is_idle then
      dummy.blocking.blocked_hit_count = 0
      dummy.blocking.last_parry_index = 0
      dummy.blocking.last_block_type = Blocking_Type.NONE
      if dummy.is_waking_up or (dummy.idle_time >= 10 and gamestate.is_ground_state(dummy, dummy.standing_state)) then
         dummy.blocking.received_hit_count = 0
      end
      dummy.blocking.is_blocking = false
      if blocking_options.mode == Blocking_Mode.RANDOM then
         if math.random() > 0.5 then
            dummy.blocking.randomized_out = true
         else
            dummy.blocking.randomized_out = false
         end
      end
   end

   if
      not gamestate.is_in_match
      or blocking_options.mode == Blocking_Mode.OFF
      or dummy.counter.is_counterattacking
      or (dummy.is_waking_up and not dummy.is_past_fast_wakeup_animation)
      or recording.current_recording_state == recording.RECORDING_STATE.POSITIONING
      or recording.current_recording_state == recording.RECORDING_STATE.REPLAYING
   then
      return
   end

   local frames_prediction = 3

   local expected_attacks = prediction.predict_hits(nil, nil, frames_prediction)
   dummy.blocking.expected_attacks = expected_attacks

   -- EX Aegis must be blocked within 5f of screen darkening
   if player.superfreeze_decount > 0 and player.char_str == "urien" and player.animation == "774c" then
      local attack = {
         id = player.id,
         blocking_type = "player",
         hit_id = 1,
         delta = 1,
         animation = "774c",
         frame = 0,
         flip_x = player.flip_x,
         side = player.side,
      }
      if not expected_attacks[1] then
         expected_attacks[1] = {}
      end
      expected_attacks[1][#expected_attacks[1] + 1] = attack
   end

   for k, attack_list in pairs(expected_attacks) do
      local i = 1
      while i <= #attack_list do
         local attack = attack_list[i]
         if
            (attack.blocking_type == "player" and attack.id ~= player.id)
            or (attack.blocking_type == "projectile" and attack.owner_id ~= player.id)
         then
            table.remove(attack_list, i)
         else
            i = i + 1
         end
      end
   end

   if
      not (blocking_options.mode == Blocking_Mode.RANDOM and dummy.blocking.randomized_out) --
      and not (blocking_options.mode == Blocking_Mode.FIRST_HIT and dummy.blocking.received_hit_count > 0) --
      and not (blocking_options.mode == Blocking_Mode.AFTER_FIRST_HIT and dummy.blocking.received_hit_count == 0)
   then
      local block_type = blocking_options.style -- 1 is block, 2 is parry
      local blocking_delta_threshold = 2 -- blocks/parries must be input 1 frame before the attack hits. blocking_delta_threshold = 1 minimum
      local hit_data = Pools.small:alloc()
      local block_result
      local block_inputs

      if blocking_options.style == Blocking_Style.RED_PARRY then -- red parry
         block_type = Blocking_Type.BLOCK
         if not (dummy.blocking.blocked_hit_count == 0) then
            blocking_delta_threshold = 1
         end
         if dummy.blocking.blocked_hit_count == blocking_options.red_parry_hit_count then
            block_type = Blocking_Type.PARRY
         elseif dummy.blocking.blocked_hit_count > blocking_options.red_parry_hit_count then
            if
               (dummy.blocking.blocked_hit_count - dummy.blocking.last_parry_index + 1)
               > blocking_options.parry_every_n_count
            then
               block_type = Blocking_Type.PARRY
            end
         end
         if dummy.is_airborne then
            block_type = Blocking_Type.PARRY
         end
      end

      for key, attack in pairs(dummy.blocking.tracked_attacks) do
         if attack.blocking_type == "projectile" then
            if not tools.table_contains_property(gamestate.projectiles, "id", attack.id) then
               dummy.blocking.tracked_attacks[key] = nil
            end
         elseif attack.blocking_type == "player" then
            if player.is_idle then
               dummy.blocking.tracked_attacks[key] = nil
            end
         end
      end

      if dummy.blocking.block_until_confirmed then
         if
            (player.character_state_byte ~= 4 and not utils.has_projectiles(player))
            or dummy.has_just_blocked
            or dummy.has_just_parried
            or dummy.has_just_been_hit
            or gamestate.frame_number - dummy.blocking.force_block_start_frame >= force_block_timeout
         then
            dummy.blocking.block_until_confirmed = false
         end
      end

      for id, attack in pairs(dummy.blocking.tracked_attacks) do
         if not tools.table_contains_property(expected_attacks, "id", attack.id) and not attack.force_block then
            dummy.blocking.tracked_attacks[id] = nil
         end
         if player.superfreeze_just_began then
            attack.connect_frame = attack.connect_frame + player.remaining_freeze_frames
         end
         if attack.force_block then
            if dummy.blocking.block_until_confirmed then
               block_inputs = attack.block_inputs
            else
               attack.force_block = nil
               attack.block_inputs = nil
               attack.should_ignore = true
            end
            if attack.blocking_type == "player" then
               if
                  player.animation_frame > fd.get_last_hit_frame(player.char_str, player.animation)
                  or player.animation ~= attack.animation
               then
                  -- geneijin kara cancels can make the dummy dash unexpectedly
                  if not (player.char_str == "yun" and player.is_in_timed_sa) then
                     dummy.blocking.block_until_confirmed = false
                     attack.force_block = nil
                  end
               end
            elseif attack.blocking_type == "projectile" then
               if not tools.table_contains_property(gamestate.projectiles, "id", attack.id) then
                  dummy.blocking.block_until_confirmed = false
                  attack.force_block = nil
               end
            end
         end
         if gamestate.frame_number >= attack.connect_frame then
            attack.should_ignore = false
         end
         if attack.blocking_type == "player" then
            if dummy.blocking.reset_parry and dummy.blocking.reset_parry.active then
               if attack.animation ~= dummy.blocking.reset_parry.animation then
                  dummy.blocking.reset_parry.active = false
               end
            end
         end
      end

      -- cancelling into moves can alter parry timing
      if
         block_type == Blocking_Type.PARRY
         and player.just_cancelled_into_attack
         and not dummy.blocking.last_block.has_connected
      then
         dummy.blocking.reset_parry = { animation = player.animation, active = true }
      end

      local delta = 99

      for k, attack_list in pairs(expected_attacks) do
         for _, attack in ipairs(attack_list) do
            if attack.delta < delta then
               delta = attack.delta
            end
            attack.connect_frame = gamestate.frame_number + attack.delta
         end
         if not hit_data[k] then
            hit_data[k] = {}
         end
         hit_data[k].hit_type, hit_data[k].unparryable, hit_data[k].unblockable =
            get_hit_type(attack_list, block_type, blocking_options.prefer_block_low, blocking_options.prefer_parry_low)
      end

      local next_attacks = Pools.small:alloc()
      if expected_attacks[delta] then
         for _, attack in ipairs(expected_attacks[delta]) do
            if not dummy.blocking.tracked_attacks[attack.id] then
               dummy.blocking.tracked_attacks[attack.id] = copytable(attack)
               if
                  attack.blocking_type == "projectile"
                  and gamestate.projectiles[attack.id]
                  and not attack.is_seieienbu
               then
                  dummy.blocking.tracked_attacks[attack.id].remaining_hits =
                     gamestate.projectiles[attack.id].remaining_hits
               end
            end
            if attack.blocking_type == "player" or attack.is_seieienbu then
               if
                  attack.hit_id > dummy.blocking.tracked_attacks[attack.id].hit_id
                  or attack.animation ~= dummy.blocking.tracked_attacks[attack.id].animation
                  or fd.is_infinite_loop(player.char_str, attack.animation)
               then
                  dummy.blocking.tracked_attacks[attack.id].should_ignore = false
               end
            else
               if attack.animation == "00_tenguishi" then
                  if gamestate.projectiles[attack.id].tengu_state ~= 3 then
                     dummy.blocking.tracked_attacks[attack.id].should_ignore = false
                  end
               elseif attack.animation == "72" then -- EX Yagyou
                  dummy.blocking.tracked_attacks[attack.id].should_ignore = false
               elseif
                  gamestate.projectiles[attack.id]
                  and (gamestate.projectiles[attack.id].remaining_hits < dummy.blocking.tracked_attacks[attack.id].remaining_hits or gamestate.projectiles[attack.id].has_just_connected)
                  and gamestate.projectiles[attack.id].remaining_hits > 0
               then
                  dummy.blocking.tracked_attacks[attack.id].should_ignore = false
               end
            end

            for key, value in pairs(attack) do
               dummy.blocking.tracked_attacks[attack.id][key] = value
            end

            if not dummy.blocking.tracked_attacks[attack.id].should_ignore then
               next_attacks[#next_attacks + 1] = dummy.blocking.tracked_attacks[attack.id]
            end
         end
         hit_data[delta].hit_type, hit_data[delta].unparryable, hit_data[delta].unblockable =
            get_hit_type(next_attacks, block_type, blocking_options.prefer_block_low, blocking_options.prefer_parry_low)
         if blocking_options.style == Blocking_Style.BLOCK then
            if blocking_options.force_blocking_direction == 2 then
               hit_data[delta].hit_type = 2
            elseif blocking_options.force_blocking_direction == 3 then
               hit_data[delta].hit_type = 3
            end
         end
      end

      if #next_attacks > 0 or dummy.blocking.block_until_confirmed then
         local hit_type = 1
         local player_side = player.side
         local dummy_side = dummy.side
         local allow_cheat_parry = false
         local allow_reset_parry = false
         local blocking_target = ""
         local parry_type = "parry_forward"

         if hit_data[delta] then
            hit_type = hit_data[delta].hit_type
            local is_projectile = false
            for _, attack in pairs(next_attacks) do
               -- projectile blocking direction is always the same as the side it was created on
               if attack.blocking_type == "projectile" and blocking_target ~= "player" then
                  if block_type == Blocking_Type.BLOCK and attack.animation ~= "00_tenguishi" then
                     dummy_side = attack.flip_x == 0 and 1 or 2
                  end
                  is_projectile = true
                  blocking_target = "projectile"
               end
               if attack.blocking_type == "player" then
                  if blocking_options.style == Blocking_Style.BLOCK and player_side ~= attack.side then
                     write_memory.disable_parry_attempts(dummy)
                  end
                  dummy_side = attack.side == 1 and 2 or 1
                  blocking_target = "player"
               end
               if dummy.blocking.reset_parry and dummy.blocking.reset_parry.active then
                  if attack.animation == dummy.blocking.reset_parry.animation then
                     allow_reset_parry = true
                  end
               end
               if debug_settings.debug_collision then
                  print(
                     string.format(
                        "#%d - hit in [%d]  id: %s  anim: %s  f: %d  hit id: %d  hit type: %d  side: %d",
                        gamestate.frame_number,
                        attack.delta,
                        tostring(attack.id),
                        attack.animation,
                        attack.frame,
                        attack.hit_id,
                        hit_type,
                        dummy_side
                     )
                  ) -- debug
               end
            end

            if block_type == Blocking_Type.PARRY and hit_data[delta] and hit_data[delta + 1] then
               if hit_data[delta].hit_type == 1 and hit_data[delta + 1].hit_type ~= 1 then
                  hit_data[delta].hit_type = hit_data[delta + 1].hit_type
                  hit_type = hit_data[delta].hit_type
               end
            end

            if hit_data[delta].unparryable then
               block_type = Blocking_Type.BLOCK
            end
            if hit_data[delta].unblockable and blocking_options.style == Blocking_Style.RED_PARRY then
               block_type = Blocking_Type.PARRY
            end

            if block_type == Blocking_Type.PARRY then
               -- parrying 1f startup supers after screen darkening is impossible...
               -- so we cheat! has the added benefit of not messing up parry inputs after screen darkening
               if player.superfreeze_decount > 0 then
                  allow_cheat_parry = true
               end

               -- determine parry type
               local parry_low = hit_type == 2
                  or (blocking_options.prefer_parry_low and hit_type == 1 and dummy.pos_y <= 8)
               if parry_low then
                  parry_type = "parry_down"
               end

               local dummy_airborne = not gamestate.is_ground_state(dummy, dummy.standing_state)
               local opponent_airborne = not gamestate.is_ground_state(player, player.standing_state)
               if dummy_airborne and dummy.pos_y > 0 then
                  parry_type = "parry_air"
               elseif opponent_airborne and not is_projectile and not parry_low then
                  parry_type = "parry_antiair"
               end

               -- input neutral before parry
               if
                  delta - 1 > 0
                  and delta <= blocking_delta_threshold + 1
                  and gamestate.frame_number - dummy.blocking.pre_parry_frame > 1
               then
                  inputs.clear_input_sequence(dummy)
                  block_type = Blocking_Type.NEUTRAL
                  dummy.blocking.is_pre_parrying = true
                  dummy.blocking.pre_parry_frame = gamestate.frame_number
                  dummy.blocking.is_blocking = true
                  dummy.blocking.is_blocking_this_frame = true
               end
               if allow_cheat_parry and delta <= 2 and not has_enough_parry_validity(parry_type, delta) then
                  write_memory.max_parry_validity(dummy)
               end
               if
                  allow_reset_parry
                  and dummy.blocking.reset_parry
                  and dummy.blocking.reset_parry.active
                  and delta <= 2
                  and not has_enough_parry_validity(parry_type, delta)
               then
                  write_memory.reset_parry_cooldowns(dummy)
                  dummy.blocking.reset_parry.active = false
               end
            end
         end

         if dummy.blocking.block_until_confirmed and dummy.blocking.last_block then
            if dummy.blocking.last_block.side ~= dummy_side then
               dummy.blocking.block_until_confirmed = false
            end
         end

         if
            (
               delta <= blocking_delta_threshold
               or (block_type == Blocking_Type.PARRY and dummy.blocking.is_pre_parrying)
            ) or dummy.blocking.block_until_confirmed
         then
            dummy.blocking.is_blocking = true
            dummy.blocking.is_blocking_this_frame = true

            if dummy.blocking.block_until_confirmed and block_inputs then
               block_result = force_block(block_inputs, dummy.blocking.last_block)
            else
               block_result = block_attack(hit_type, block_type, parry_type, delta, dummy_side)
            end

            if block_result then
               -- if we change our animation, we potentially run into attacks that would otherwise miss
               local should_repeat_block = false
               if dummy.blocking.last_block and dummy.blocking.last_block.inputs then
                  if
                     input[dummy.prefix .. " Right"] ~= dummy.blocking.last_block.inputs.Right
                     or input[dummy.prefix .. " Left"] ~= dummy.blocking.last_block.inputs.Left
                     or input[dummy.prefix .. " Down"] ~= dummy.blocking.last_block.inputs.Down
                  then
                     if block_result.type == "block" then
                        local next_anim_id = prediction.predict_next_animation(dummy, input)
                        local next_anim = prediction.get_next_animation(dummy, next_anim_id)
                        local animation_options = {}
                        animation_options[dummy.id] = { set = { animation = next_anim, frame = 0 } }
                        expected_attacks = prediction.predict_hits(nil, animation_options, 1)
                        if expected_attacks[1] then
                           if
                              (expected_attacks[1][1].side == 1) ~= input[dummy.prefix .. " Right"]
                              or (expected_attacks[1][1].side == 2) ~= input[dummy.prefix .. " Left"]
                           then
                              should_repeat_block = true
                           end
                        end
                     end
                  end
               end
               if should_repeat_block then
                  input[dummy.prefix .. " Right"] = dummy.blocking.last_block.inputs.Right
                  input[dummy.prefix .. " Left"] = dummy.blocking.last_block.inputs.Left
                  input[dummy.prefix .. " Down"] = dummy.blocking.last_block.inputs.Down
               else
                  dummy.blocking.last_block = block_result
               end
               dummy.blocking.last_block.blocking_type = ""
               dummy.blocking.last_block.frame_number = gamestate.frame_number
               dummy.blocking.last_block.has_connected = false
               dummy.blocking.last_block.inputs = {
                  Right = input[dummy.prefix .. " Right"],
                  Left = input[dummy.prefix .. " Left"],
                  Down = input[dummy.prefix .. " Down"],
               }
               for _, attack in pairs(next_attacks) do
                  if delta == 1 then -- assume we blocked successfully
                     if not dummy.blocking.tracked_attacks[attack.id].force_block then
                        dummy.blocking.tracked_attacks[attack.id].should_ignore = true
                     end
                  end
                  -- keep blocking until we can confirm it for improved consistency
                  -- we don't have this luxury when red parrying
                  if
                     (dummy.blocking.blocked_hit_count == 0 and block_type == Blocking_Type.BLOCK)
                     or blocking_options.style == 1
                  then
                     if not dummy.blocking.block_until_confirmed then
                        dummy.blocking.force_block_start_frame = gamestate.frame_number
                        dummy.blocking.block_until_confirmed = true
                        dummy.blocking.tracked_attacks[attack.id].force_block = true
                        dummy.blocking.tracked_attacks[attack.id].block_inputs =
                           copytable(dummy.blocking.last_block.inputs)
                     end
                  end
                  if dummy.blocking.last_block.blocking_type ~= "player" then
                     dummy.blocking.last_block.blocking_type = attack.blocking_type
                  end
               end
            end
         end
      end

      dummy.blocking.parried_last_frame = false
      if block_result and block_result.type == "parry" and block_result.sub_type ~= "pass" then
         dummy.blocking.parried_last_frame = true
      end
   end
end

local mash_start_frame = 1
local mash_directions_normal = {
   { "down", "forward" },
   { "down" },
   { "down", "back" },
   { "back" },
   { "up", "back" },
   { "up" },
   { "up", "forward" },
   { "forward" },
}
local mash_directions_serious = {
   { "down", "back" },
   { "down" },
   { "up", "forward" },
   { "up" },
   { "down", "back" },
   { "up", "forward" },
}
local mash_directions_fastest = { { "down", "forward" }, { "down", "back" } }
local mash_directions_fastest_up = { { "up", "forward" }, { "up", "back" } }
local mash_directions = mash_directions_fastest
local all_buttons = { "LP", "MP", "HP", "LK", "MK", "HK" }
local serious_buttons = { "LP", "MP", "HP", "HK", "MK", "LK" }
local p_buttons = { "LP", "MP", "HP" }
local k_buttons = { "LK", "MK", "HK" }

local i_mash_directions = 1
local i_mash_buttons = 1

local mash_inputs_mode = 1

local mash_inputs_exceptions = { e600 = 60 } -- makoto forward throw

local function update_mash_inputs(input, dummy, mode)
   local player = dummy.other
   mash_inputs_mode = mode

   if
      not gamestate.is_in_match
      or mode == 1
      or recording.current_recording_state == recording.RECORDING_STATE.POSITIONING
      or recording.current_recording_state == recording.RECORDING_STATE.REPLAYING
      or dummy.posture == 24
      or dummy.posture == 38
      or disable.mash_inputs
      or (
         not dummy.is_stunned
         and mash_inputs_exceptions[player.animation]
         and player.animation_frame >= mash_inputs_exceptions[player.animation]
      )
   then
      return
   end
   if dummy.stun_just_began or dummy.has_just_been_thrown or player.has_just_been_thrown then
      mash_start_frame = gamestate.frame_number
      i_mash_directions = 1
      i_mash_buttons = 1
      if mode == 2 then
         mash_directions = mash_directions_normal
      elseif mode == 3 then
         mash_directions = mash_directions_serious
      elseif mode == 4 then
         mash_directions = mash_directions_fastest
      end
   end
   if
      dummy.is_stunned
      or (dummy.is_being_thrown and player.throw_countdown <= 1)
      or (player.is_being_thrown and dummy.throw_countdown <= 1)
   then
      -- try to prevent move from coming out
      -- diagonal input reduces stun by 3
      -- pressing all buttons reduces stun by 4 more
      if
         dummy.counter.recovery_type == RECOVERY_TYPE.STUN
         and dummy.stun_timer > 0
         and dummy.stun_timer <= 30
         and not dummy.is_being_thrown
         and not player.is_being_thrown
      then
         mash_directions = mash_directions_fastest_up
         i_mash_directions = tools.wrap_index(i_mash_directions, #mash_directions)
      elseif
         dummy.stun_timer > 0
         and dummy.stun_timer <= 15
         and not dummy.is_being_thrown
         and not player.is_being_thrown
      then
         mash_directions = mash_directions_fastest
         i_mash_directions = tools.wrap_index(i_mash_directions, #mash_directions)
      end

      local elapsed = gamestate.frame_number - mash_start_frame
      local sequence = {}
      if dummy.stun_timer >= 8 or dummy.is_being_thrown or player.is_being_thrown then
         -- normal
         if mode == 2 then
            sequence[#sequence + 1] = tools.deepcopy(mash_directions[i_mash_directions])
            sequence[1][#sequence[1] + 1] = p_buttons[i_mash_buttons]
            sequence[1][#sequence[1] + 1] = k_buttons[#k_buttons - i_mash_buttons + 1]
            if elapsed % 4 == 0 then
               i_mash_directions = tools.wrap_index(i_mash_directions + 1, #mash_directions)
            end
            if elapsed % 6 == 0 then
               i_mash_buttons = tools.wrap_index(i_mash_buttons + 1, #p_buttons)
            end
            -- serious
         elseif mode == 3 then
            if dummy.is_being_thrown or player.is_being_thrown then -- try to make mashing realistic
               sequence[#sequence + 1] = tools.deepcopy(mash_directions[i_mash_directions])
               sequence[1][#sequence[1] + 1] = serious_buttons[i_mash_buttons]
               if elapsed % 4 == 0 then
                  i_mash_buttons = tools.wrap_index(i_mash_buttons + 1, #serious_buttons)
               end
            else
               sequence[#sequence + 1] = tools.deepcopy(mash_directions[i_mash_directions])
               sequence[1][#sequence[1] + 1] = p_buttons[i_mash_buttons]
               sequence[1][#sequence[1] + 1] = p_buttons[tools.wrap_index(i_mash_buttons + 1, #p_buttons)]
               sequence[1][#sequence[1] + 1] = k_buttons[#k_buttons - i_mash_buttons + 1]
               sequence[1][#sequence[1] + 1] = k_buttons[tools.wrap_index(#k_buttons - i_mash_buttons, #k_buttons)]
               i_mash_buttons = tools.wrap_index(i_mash_buttons + 1, #p_buttons)
            end

            if elapsed % 3 == 0 then
               i_mash_directions = tools.wrap_index(i_mash_directions + 1, #mash_directions)
            end
            -- fastest
         elseif mode == 4 then
            sequence[#sequence + 1] = tools.deepcopy(mash_directions[i_mash_directions])
            if elapsed % 2 == 0 then
               for _, button in pairs(all_buttons) do
                  sequence[1][#sequence[1] + 1] = button
               end
            end
            i_mash_directions = tools.wrap_index(i_mash_directions + 1, #mash_directions)
         end
      end
      if #sequence > 0 then
         inputs.queue_input_sequence(dummy, sequence)
      end
   end
end

local function update_fast_wake_up(input, dummy, mode)
   if
      gamestate.is_in_match
      and mode ~= 1
      and (
         recording.current_recording_state ~= recording.RECORDING_STATE.POSITIONING
         and recording.current_recording_state ~= recording.RECORDING_STATE.REPLAYING
      )
   then
      local should_tap_down = dummy.previous_can_fast_wakeup == 0 and dummy.can_fast_wakeup == 1

      if should_tap_down then
         local r = math.random()
         if mode ~= 3 or r > 0.5 then
            input[dummy.prefix .. " Down"] = true
         end
      end
   end
end

local function get_timing_type(counter_attack_data)
   if
      counter_attack_data.type == COUNTER_ATTACK_TYPE.RECORDING
      or counter_attack_data.type == COUNTER_ATTACK_TYPE.OPTION_SELECT
      or counter_attack_data.type == COUNTER_ATTACK_TYPE.NORMAL and counter_attack_data.motion == "kara_throw"
   then
      return "replay"
   end
   return "reversal"
end

local function is_guard_jump(str)
   for i = 1, #guard_jumps do
      if str == guard_jumps[i] then
         return true
      end
   end
   return false
end

local function get_attack_frame_offset(counter_attack_data)
   local offset = 0
   if counter_attack_data.type == COUNTER_ATTACK_TYPE.OPTION_SELECT then
      if is_guard_jump(counter_attack_data.name) then
         offset = -4 -- avoid hj input
      elseif counter_attack_data.name == "crouch_tech" or counter_attack_data.name == "block_late_tech" then
         offset = 0
      end
   elseif counter_attack_data.type == COUNTER_ATTACK_TYPE.NORMAL and counter_attack_data.motion == "kara_throw" then
      offset = 0
   end
   return offset
end

local stun_reduction_rate_normal = 1.46
local stun_reduction_rate_serious = 2.8
local stun_reduction_rate_fastest = 4.33
local function estimate_frames_until_stun_recovery(stun_timer)
   if stun_timer == 0 then
      stun_timer = 255
   end
   if mash_inputs_mode == 1 then
      return stun_timer
   elseif mash_inputs_mode == 2 then
      return math.ceil(stun_timer / stun_reduction_rate_normal)
   elseif mash_inputs_mode == 3 then
      return math.ceil(stun_timer / stun_reduction_rate_serious)
   else
      return math.ceil(stun_timer / stun_reduction_rate_fastest)
   end
end

local stun_neutral_input_offset = 8

local function handle_stun(defender, counter_attack_data)
   if not (defender.is_stunned and defender.stun_timer > 0) then
      return
   end

   local frames_until_recovery = estimate_frames_until_stun_recovery(defender.stun_timer)
   local reduction_start_frame = #defender.counter.sequence or 0
   reduction_start_frame = reduction_start_frame + stun_neutral_input_offset - defender.counter.stun_attack_offset
   reduction_start_frame = math.max(reduction_start_frame, stun_neutral_input_offset)

   disable_update("mash_inputs", false)
   if frames_until_recovery > reduction_start_frame then
      defender.counter.attack_frame = gamestate.frame_number + 99
      return
   end

   disable_update("mash_inputs", true)
   if inputs.is_input_neutral(defender, inputs.previous_input) then
      defender.counter.stun_neutral_input_frames = defender.counter.stun_neutral_input_frames + 1
   end

   if defender.counter.stun_neutral_input_frames < stun_neutral_input_offset then
      defender.counter.attack_frame = gamestate.frame_number + 99
      local stun_time = math.max(defender.stun_timer, 10)
      memory.writebyte(defender.addresses.stun_timer, stun_time)
      return
   end

   local frames_remaining = 0
   if defender.counter.timing_type == "reversal" then
      local current_frame = defender.pending_input_sequence and defender.pending_input_sequence.current_frame or 0
      frames_remaining = #defender.counter.sequence - defender.counter.stun_attack_offset - current_frame
      if not defender.counter.is_input_queued then
         defender.counter.stun_duration = #defender.counter.sequence - defender.counter.stun_attack_offset
         defender.counter.offset = 0
         defender.counter.is_counterattacking = true
         if frames_remaining >= 0 then
            defender.counter.attack_frame = gamestate.frame_number + #defender.counter.sequence
            current_frame = 1
            frames_remaining = #defender.counter.sequence - defender.counter.stun_attack_offset - current_frame
         else
            defender.counter.attack_frame = gamestate.frame_number - frames_remaining + #defender.counter.sequence
         end
      elseif not defender.pending_input_sequence then
         frames_remaining = -defender.counter.stun_attack_offset
            - (gamestate.frame_number - defender.counter.attack_frame + 1)
         frames_remaining = math.max(frames_remaining, 0)
      end
   else
      if not defender.counter.is_input_queued then
         frames_remaining = -defender.counter.stun_attack_offset
         if defender.counter.stun_attack_offset <= 0 then
            defender.counter.attack_frame = gamestate.frame_number + 1
         else
            defender.counter.attack_frame = gamestate.frame_number + defender.counter.stun_attack_offset
            frames_remaining = 0
         end
         defender.counter.is_counterattacking = true
      else
         if defender.pending_input_sequence then
            frames_remaining = -defender.counter.stun_attack_offset
               - (gamestate.frame_number - defender.counter.attack_frame + 1)
         else
            frames_remaining = defender.counter.stun_attack_offset
               - (gamestate.frame_number - defender.counter.attack_frame + 1)
         end
         frames_remaining = math.max(frames_remaining, 0)
      end
   end
   if frames_remaining > 0 then
      local stun_time = math.max(defender.stun_timer - math.floor(defender.stun_timer / frames_remaining), 10)
      memory.writebyte(defender.addresses.stun_timer, stun_time)
   else
      memory.writebyte(defender.addresses.stun_timer, 0)
   end
end

local function handle_recording(defender, counter_attack_data)
   if counter_attack_data.type == COUNTER_ATTACK_TYPE.RECORDING then
      recording.load_recordings(counter_attack_data.char_str)
      local slot_index = settings.training.current_recording_slot
      if settings.training.replay_mode == 2 or settings.training.replay_mode == 5 then
         slot_index = recording.find_random_recording_slot()
      elseif settings.training.replay_mode == 3 or settings.training.replay_mode == 6 then
         slot_index = recording.go_to_next_ordered_slot()
      end
      if slot_index < 0 then
         return
      end

      defender.counter.timing_type = "replay"
      defender.counter.recording_slot = slot_index

      local delay = recording.recording_slots[defender.counter.recording_slot].delay or 0
      local max_random_deviation = recording.recording_slots[defender.counter.recording_slot].random_deviation or 0
      local random_deviation = math.random(0, max_random_deviation)
      defender.counter.offset = delay + random_deviation + settings.training.counter_attack_delay
   end
end

local counter_attack_jump_motions = {
   dir_7 = true,
   dir_8 = true,
   dir_9 = true,
   sjump_back = true,
   sjump_neutral = true,
   sjump_forward = true,
}

local debug_ca = false

local function reset_counter_attack(defender)
   defender.counter.is_counterattacking = false
   defender.counter.is_input_queued = false
   defender.counter.recovery_type = RECOVERY_TYPE.NONE
end
-- counter attack timing types: reversal - time inputs to finish on target frame, replay - begin playing seequence on target frame
local function update_counter_attack(input, defender, counter_attack_data, hits_before)
   if counter_attack_data and counter_attack_data.type == COUNTER_ATTACK_TYPE.NONE then
      reset_counter_attack(defender)
   end

   if defender.counter.recovery_type == RECOVERY_TYPE.STUN then
      handle_stun(defender, counter_attack_data)
   end

   if
      not gamestate.is_in_match
      or recording.current_recording_state == recording.RECORDING_STATE.POSITIONING
      or recording.current_recording_state == recording.RECORDING_STATE.REPLAYING
      or not counter_attack_data
      or counter_attack_data.type == COUNTER_ATTACK_TYPE.NONE
   then
      return
   end

   if defender.counter.is_input_queued then
      if defender.counter.recovery_type == RECOVERY_TYPE.CONNECTION then
         if
            defender.is_waking_up
            or defender.counter.recovery_type == RECOVERY_TYPE.STUN
            or (defender.is_airborne and not defender.is_being_thrown)
         then
            reset_counter_attack(defender)
         end
      elseif defender.counter.recovery_type == RECOVERY_TYPE.WAKEUP then
         if defender.posture ~= 0x26 then
            reset_counter_attack(defender)
         end
      elseif defender.counter.recovery_type == RECOVERY_TYPE.AIR then
         if defender.is_grounded then
            reset_counter_attack(defender)
         end
      elseif defender.counter.recovery_type == RECOVERY_TYPE.STUN then
         if not defender.is_stunned or (defender.just_received_connection or defender.has_just_been_thrown) then
            disable_update("mash_inputs", false)
            reset_counter_attack(defender)
         end
      end
   end

   if defender.counter.is_counterattacking and defender.counter.is_input_queued then
      if
         defender.counter.recovery_type ~= RECOVERY_TYPE.STUN
         and (not defender.pending_input_sequence or defender.pending_input_sequence.id ~= defender.counter.sequence)
      then
         reset_counter_attack(defender)
         tools.clear_table(defender.counter.sequence)
      end
   end

   if defender.blocking.received_hit_count >= hits_before then
      if defender.has_just_parried then
         defender.counter.recovery_type = RECOVERY_TYPE.PARRY
         defender.counter.is_counterattacking = false
         defender.counter.is_input_queued = false
         defender.counter.should_update_attack_frame = true
         if debug_ca then
            print(gamestate.frame_number .. " - init ca (parry)")
         end
         -- log(defender.prefix, "counter_attack", "init ca (parry)")

         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
         defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
         defender.counter.timing_type = get_timing_type(counter_attack_data)
         defender.counter.attack_frame = gamestate.frame_number + #defender.counter.sequence + 1

         if defender.is_airborne then
            defender.counter.attack_frame = gamestate.frame_number + 17
            if
               counter_attack_data.type == COUNTER_ATTACK_TYPE.NORMAL and counter_attack_data.normal_button ~= "none"
            then
               defender.counter.attack_frame = defender.counter.attack_frame + 1
            end
         else
            if counter_attack_data.move_type == "kara_special" or counter_attack_data.move_type == "kara_sgs" then
               defender.counter.attack_frame = gamestate.frame_number + 16
               defender.counter.offset = defender.counter.offset + 1
               if counter_attack_data.move_type == "kara_sgs" then
                  defender.counter.offset = defender.counter.offset + 1
               end
            elseif
               counter_attack_data.type == COUNTER_ATTACK_TYPE.NORMAL
               and counter_attack_jump_motions[counter_attack_data.motion]
            then
               defender.counter.attack_frame = gamestate.frame_number + 21
            elseif counter_attack_data.name == "sgs" then
               defender.counter.attack_frame = gamestate.frame_number + 22
            end
         end

         if counter_attack_data.type == COUNTER_ATTACK_TYPE.RECORDING then
            handle_recording(defender, counter_attack_data)
            if defender.is_airborne then
               defender.counter.attack_frame = gamestate.frame_number + 17
            else
               defender.counter.attack_frame = gamestate.frame_number + 16
            end
         end
      elseif (defender.just_received_connection or defender.has_just_been_thrown) and not defender.is_airborne then
         if
            defender.counter.is_counterattacking
            and defender.has_just_been_thrown
            and (counter_attack_data.name == "crouch_tech" or counter_attack_data.name == "block_late_tech")
         then
         else
            defender.counter.recovery_type = RECOVERY_TYPE.CONNECTION
            defender.counter.is_counterattacking = false
            defender.counter.is_input_queued = false
            defender.counter.should_update_attack_frame = true
            if debug_ca then
               print(gamestate.frame_number .. " - init ca (hit/block)")
            end
            defender.counter.superfreeze_adjustment = 0
            inputs.clear_input_sequence(defender)
            defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
            defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
            defender.counter.timing_type = get_timing_type(counter_attack_data)
            defender.counter.attack_frame = gamestate.frame_number + 99
            handle_recording(defender, counter_attack_data)
         end
      elseif
         defender.is_waking_up
         and defender.remaining_wakeup_time > 0
         and defender.counter.recovery_type ~= RECOVERY_TYPE.WAKEUP
         and defender.counter.recovery_type ~= RECOVERY_TYPE.STUN
      then
         defender.counter.recovery_type = RECOVERY_TYPE.WAKEUP
         defender.counter.is_counterattacking = false
         defender.counter.is_input_queued = false
         defender.counter.should_update_attack_frame = true
         if debug_ca then
            print(gamestate.frame_number .. " - init ca (wake up)")
         end
         defender.counter.attack_frame = gamestate.frame_number
            + defender.remaining_wakeup_time
            + 2
            + get_attack_frame_offset(counter_attack_data)
         defender.counter.timing_type = get_timing_type(counter_attack_data)
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
         defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
         handle_recording(defender, counter_attack_data)
      elseif defender.has_just_entered_air_recovery then
         defender.counter.recovery_type = RECOVERY_TYPE.AIR
         defender.counter.is_counterattacking = false
         defender.counter.is_input_queued = false
         defender.counter.should_update_attack_frame = true
         if debug_ca then
            print(gamestate.frame_number .. " - init ca (air)")
         end
         inputs.clear_input_sequence(defender)
         defender.counter.timing_type = get_timing_type(counter_attack_data)
         defender.counter.attack_frame = gamestate.frame_number + 99
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
         defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
         handle_recording(defender, counter_attack_data)
      elseif defender.is_stunned and defender.counter.recovery_type ~= RECOVERY_TYPE.STUN then
         defender.counter.recovery_type = RECOVERY_TYPE.STUN
         defender.counter.is_counterattacking = false
         defender.counter.is_input_queued = false
         defender.counter.should_update_attack_frame = true
         defender.counter.stun_neutral_input_frames = 0

         if debug_ca then
            print(gamestate.frame_number .. " - init stun")
         end
         defender.counter.timing_type = get_timing_type(counter_attack_data)
         defender.counter.attack_frame = gamestate.frame_number + 99
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
         defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
         defender.counter.stun_attack_offset = defender.counter.offset + get_attack_frame_offset(counter_attack_data)
         handle_recording(defender, counter_attack_data)
      end
   end

   if defender.counter.is_input_queued or defender.counter.recovery_type == RECOVERY_TYPE.NONE then
      return
   end

   if defender.counter.should_update_attack_frame then
      if defender.counter.recovery_type == RECOVERY_TYPE.CONNECTION then -- has just blocked/been hit
         if debug_ca then
            print(gamestate.frame_number .. " - update ca")
         end
         if
            defender.other.superfreeze_just_began
            and defender.other.previous_recovery_time == defender.other.recovery_time
         then
            defender.counter.superfreeze_adjustment = -1
         end
         defender.counter.attack_frame = gamestate.frame_number
            + defender.recovery_time
            + defender.additional_recovery_time
            + get_attack_frame_offset(counter_attack_data)
            + defender.counter.superfreeze_adjustment
            + 1
         if
            defender.just_received_connection
            or defender.is_being_thrown
            or defender.remaining_freeze_frames > 0
            or (defender.freeze_just_ended and defender.other.superfreeze_decount == 0)
         then
            defender.counter.attack_frame = gamestate.frame_number + 20
         end
         -- cancel if we are being hit in the air, also applies to throws
         if defender.posture == 0x18 and defender.character_state_byte == 1 then
            defender.counter.recovery_type = RECOVERY_TYPE.NONE
         end
      elseif defender.counter.recovery_type == RECOVERY_TYPE.WAKEUP then
         defender.counter.attack_frame = gamestate.frame_number
            + defender.remaining_wakeup_time
            + get_attack_frame_offset(counter_attack_data)
            + 1
      elseif
         defender.counter.recovery_type == RECOVERY_TYPE.AIR
         or (defender.is_airborne and is_guard_jump(counter_attack_data.name))
      then
         local frames_before_landing = prediction.predict_frames_before_landing(defender)
         print(frames_before_landing)
         if frames_before_landing > 0 then
            defender.counter.attack_frame = gamestate.frame_number
               + frames_before_landing
               + get_attack_frame_offset(counter_attack_data)
               + 1
         elseif frames_before_landing == 0 then
            defender.counter.attack_frame = gamestate.frame_number + get_attack_frame_offset(counter_attack_data) + 1
         end
      end
   end

   local frames_remaining = defender.counter.attack_frame - gamestate.frame_number
   if debug_ca then
      print(defender.counter.attack_frame, frames_remaining, defender.recovery_time)
   end

   if counter_attack_data.type == COUNTER_ATTACK_TYPE.RECORDING and defender.counter.recording_slot > 0 then
      frames_remaining = frames_remaining + defender.counter.offset
      if defender.counter.offset > 0 then
         if frames_remaining > 1 + defender.counter.offset then
            return
         end
         defender.counter.should_update_attack_frame = false
         defender.counter.is_counterattacking = true
      end
      if frames_remaining <= 1 then
         if
            settings.training.replay_mode == 2
            or settings.training.replay_mode == 3
            or settings.training.replay_mode == 5
            or settings.training.replay_mode == 6
         then
            recording.set_replay_options("override_replay_slot", defender.counter.recording_slot)
         end
         if debug_ca then
            print(gamestate.frame_number .. " - queue recording")
         end
         defender.counter.is_counterattacking = true
         defender.counter.is_input_queued = true
         recording.play_recording_without_positioning()
      end
   elseif
      defender.counter.timing_type == "replay"
      or counter_attack_data.type == COUNTER_ATTACK_TYPE.OPTION_SELECT
      or (counter_attack_data.type == COUNTER_ATTACK_TYPE.NORMAL and (counter_attack_data.motion == "kara_throw"))
   then
      if frames_remaining <= 1 then
         if debug_ca then
            print(gamestate.frame_number .. " - queue os/kara throw/jump", defender.counter.offset)
         end
         inputs.queue_input_sequence(defender, defender.counter.sequence, defender.counter.offset, true)
         defender.counter.is_counterattacking = true
         defender.counter.is_input_queued = true
      end
   elseif defender.counter.timing_type == "reversal" then
      if frames_remaining <= #defender.counter.sequence then
         if debug_ca then
            print(gamestate.frame_number .. " - queue reversal", frames_remaining, defender.counter.offset)
         end
         if defender.blocking.expected_attacks then
            local delta = 99
            for k, attack_list in pairs(defender.blocking.expected_attacks) do
               if k < delta then
                  delta = k
               end
            end
            if not (#defender.counter.sequence <= delta) then
               return
            end
         end
         -- cancels counterattack if blocking
         -- if defender.blocking.is_blocking_this_frame then
         --    return
         -- end
         inputs.queue_input_sequence(defender, defender.counter.sequence, defender.counter.offset, true)
         defender.counter.is_counterattacking = true
         defender.counter.is_input_queued = true
      end
   end
end

local tech_throw_frame = 0
local function update_tech_throws(input, defender, mode)
   if not gamestate.is_in_match or mode == 1 then
      return
   end
   if defender.has_just_been_thrown then
      -- latest possible tech
      -- can add code for earliest tech later, would require prediction of throw boxes
      tech_throw_frame = gamestate.frame_number + 3
   end
   if gamestate.frame_number == tech_throw_frame then
      local r = math.random()
      if mode ~= 3 or r > 0.5 then
         input[defender.prefix .. " Weak Punch"] = true
         input[defender.prefix .. " Weak Kick"] = true
      end
   end
end

local function reset()
   tech_throw_frame = 0
   tools.clear_table(disable)
   reset_counter_attack(gamestate.P1)
   reset_counter_attack(gamestate.P2)
end

return {
   Blocking_Mode = Blocking_Mode,
   Blocking_Style = Blocking_Style,
   Blocking_Type = Blocking_Type,
   Force_Blocking_Direction = Force_Blocking_Direction,
   update_pose = update_pose,
   update_blocking = update_blocking,
   update_mash_inputs = update_mash_inputs,
   update_fast_wake_up = update_fast_wake_up,
   update_counter_attack = update_counter_attack,
   update_tech_throws = update_tech_throws,
   reset = reset,
   disable_update = disable_update,
   name = module_name,
}
