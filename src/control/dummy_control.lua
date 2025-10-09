local settings = require("src.settings")
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local gamestate = require("src.gamestate")
local inputs = require("src.control.inputs")
local prediction = require("src.modules.prediction")
local write_memory = require("src.control.write_memory")
local recording = require("src.control.recording")
local tools = require("src.tools")

local frame_data = fd.frame_data
local frame_data_meta = fdm.frame_data_meta

local function update_pose(input, player, dummy, pose)
   if recording.current_recording_state == 4 -- Replaying
   or dummy.blocking.is_blocking_this_frame then return end

   if gamestate.is_in_match and not inputs.is_playing_input_sequence(dummy) then
      local on_ground = gamestate.is_ground_state(dummy, dummy.standing_state)
      local is_waking_up = dummy.is_waking_up and dummy.remaining_wakeup_time > 0 and dummy.remaining_wakeup_time <= 3
      local wakeup_frame = dummy.standing_state == 0 and dummy.posture == 0

      if pose == 2 and (on_ground or is_waking_up or wakeup_frame) then -- crouch
         input[dummy.prefix .. " Down"] = true
      elseif pose == 3 and on_ground then -- jump
         input[dummy.prefix .. " Up"] = true
      elseif pose == 4 then -- high jump
         if on_ground and not inputs.is_playing_input_sequence(dummy) then
            inputs.queue_input_sequence(dummy, {{"down"}, {"up"}})
         end
      end
   end
end

local animations = {
   NONE = 1,
   WALK_FORWARD = 2,
   WALK_BACK = 3,
   WALK_TRANSITION = 4,
   STANDING_BEGIN = 5,
   CROUCHING_BEGIN = 6,
   BLOCK_HIGH_PROXIMITY = 7,
   BLOCK_HIGH = 8,
   BLOCK_LOW = 9,
   BLOCK_LOW_PROXIMITY = 10,
   PARRY_HIGH = 11,
   PARRY_LOW = 12,
   PARRY_AIR = 13
}

local force_block_timeout = 10

local function update_blocking(input, player, dummy, mode, style, red_parry_hit_count, parry_every_n_count)

   local function block_attack(hit_type, block_type, parry_type, delta, reverse)
      print(gamestate.frame_number, hit_type, block_type, delta, reverse, dummy[parry_type].validity_time) -- debug
      local p2_forward = tools.bool_xor(dummy.flip_input, reverse)
      local p2_back = not tools.bool_xor(dummy.flip_input, reverse)
      local sub_type = "high"
      if block_type == 1 and dummy.pos_y <= 8 then -- no air blocking!
         input[dummy.prefix .. " Right"] = p2_back
         input[dummy.prefix .. " Left"] = p2_forward

         if hit_type == 2 then
            input[dummy.prefix .. " Down"] = true
            sub_type = "low"
         elseif hit_type == 3 or hit_type == 4 then
            input[dummy.prefix .. " Down"] = false
         end
         return {type = "block", sub_type = sub_type, hit_type = hit_type, frame = gamestate.frame_number}
      elseif block_type == 2 then
         print(parry_type, dummy.is_blocking, dummy[parry_type].validity_time, dummy[parry_type].max_validity) -- debug
         if (not dummy.is_blocking and dummy[parry_type].validity_time > delta) or
             (dummy.is_blocking and dummy[parry_type].validity_time == dummy[parry_type].max_validity) then
            -- already parrying
            return {type = "parry", sub_type = "pass", hit_type = hit_type, frame = gamestate.frame_number}
         else
            if inputs.is_previous_input_neutral(dummy) and not (hit_type == 5) then
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
               return {type = "parry", sub_type = sub_type, hit_type = hit_type, frame = gamestate.frame_number}
            else
               print("can not parry") -- block the attack instead --debug
               block_attack(hit_type, 1, parry_type, delta, reverse)
            end
         end
      end
      return nil
   end

   local function force_block(block_inputs, last_block)
      for dir, value in pairs(block_inputs) do input[dummy.prefix .. " " .. dir] = value end
      return {
         type = "block",
         sub_type = last_block.sub_type,
         hit_type = last_block.hit_type,
         frame = gamestate.frame_number
      }
   end

   -- ensure variables
   dummy.blocking.is_blocking = dummy.blocking.is_blocking or false
   dummy.blocking.is_blocking_this_frame = false
   dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count or 0
   dummy.blocking.received_hit_count = dummy.blocking.received_hit_count or 0
   dummy.blocking.parried_last_frame = dummy.blocking.parried_last_frame or false
   dummy.blocking.is_pre_parrying = false
   dummy.blocking.pre_parry_frame = dummy.blocking.pre_parry_frame or 0
   dummy.blocking.last_block = dummy.blocking.last_block or {}
   dummy.blocking.tracked_attacks = dummy.blocking.tracked_attacks or {}
   dummy.blocking.force_block_start_frame = dummy.blocking.force_block_start_frame or 0

   if not gamestate.is_in_match or mode == 1 or recording.current_recording_state == 4 -- exit if playing recording
   then return end

   if mode == 4 then
      local r = math.random()
      if mode ~= 3 or r > 0.5 then
         dummy.blocking.randomized_out = true
      else
         dummy.blocking.randomized_out = false
      end
   end

   if dummy.blocking.expected_hit_projectiles then
      for _, id in ipairs(dummy.blocking.expected_hit_projectiles) do
         if gamestate.projectiles[id] then
            gamestate.projectiles[id].remaining_hits = gamestate.projectiles[id].remaining_hits - 1
            gamestate.update_projectile_cooldown(gamestate.projectiles[id])
         end
      end
   end

   dummy.blocking.expected_hit_projectiles = {}

   dummy.blocking.expected_player_animation = dummy.blocking.expected_player_animation or animations.NONE
   local previous_expected_player_animation = dummy.blocking.expected_player_animation

   dummy.blocking.expected_attacks = {}

   -- animation changes next frame
   if dummy.has_just_blocked then
      if dummy.blocking.last_block.sub_type == "high" then
         dummy.blocking.expected_player_animation = animations.BLOCK_HIGH
      elseif dummy.blocking.last_block.sub_type == "low" then
         dummy.blocking.expected_player_animation = animations.BLOCK_LOW
      end
   elseif dummy.has_just_parried then
      if dummy.blocking.last_block.sub_type == "forward" or dummy.blocking.last_block.sub_type == "antiair" then
         dummy.blocking.expected_player_animation = animations.PARRY_HIGH
      elseif dummy.blocking.last_block.sub_type == "low" then
         dummy.blocking.expected_player_animation = animations.PARRY_LOW
      elseif dummy.blocking.last_block.sub_type == "air" then
         dummy.blocking.expected_player_animation = animations.PARRY_AIR
      end
   end

   local frames_prediction = 3
   if dummy.blocking.expected_player_animation == animations.WALK_FORWARD then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.walk_forward, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.WALK_BACK then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.walk_back, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.WALK_TRANSITION then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.walk_transition, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.STANDING_BEGIN then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.standing_begin, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.CROUCHING_BEGIN then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.crouching_begin, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.BLOCK_HIGH_PROXIMITY then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy,
                                                                     dummy.block_high_proximity, 0, frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.BLOCK_HIGH then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.block_high, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.BLOCK_LOW_PROXIMITY then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.block_low_proximity,
                                                                     0, frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.BLOCK_LOW then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.block_low, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.PARRY_HIGH then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.parry_high, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.PARRY_LOW then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.parry_low, 0,
                                                                     frames_prediction)
   elseif dummy.blocking.expected_player_animation == animations.PARRY_AIR then
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, dummy.parry_air, 0,
                                                                     frames_prediction)
   else
      dummy.blocking.expected_attacks = prediction.update_prediction(player, nil, nil, dummy, nil, nil,
                                                                     frames_prediction)
   end

   if dummy.received_connection then dummy.blocking.received_hit_count = dummy.blocking.received_hit_count + 1 end
   if dummy.has_just_blocked or dummy.has_just_parried then
      dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count + 1
   end

   if dummy.is_idle and player.is_idle then
      dummy.blocking.blocked_hit_count = 0
      if dummy.idle_time >= 10 then dummy.blocking.received_hit_count = 0 end
      dummy.blocking.is_blocking = false
   end

   if not (mode == 5 and dummy.blocking.randomized_out) and not (mode == 4 and dummy.blocking.received_hit_count == 0) and
       not (mode == 3 and dummy.blocking.blocked_hit_count > 0) then
      local block_type = style -- 1 is block, 2 is parry
      local blocking_delta_threshold = 2 -- blocks/parries must be input 1 frame before the attack hits. blocking_delta_threshold = 1 minimum
      local precise_blocking = false
      local blocking_queue = {}
      local block_result
      local block_inputs
      local expected_player_animation = animations.NONE

      local prefer_parry_low = settings.training.prefer_down_parry
      local prefer_block_low = settings.training.pose == 2

      if style == 3 then -- red parry
         block_type = 1
         precise_blocking = true
         if not (dummy.blocking.blocked_hit_count == 0) then blocking_delta_threshold = 1 end
         if dummy.blocking.blocked_hit_count >= red_parry_hit_count then
            if (dummy.blocking.blocked_hit_count - red_parry_hit_count) % (parry_every_n_count + 1) == 0 then
               block_type = 2
            end
         end
      end

      for _, attack in pairs(dummy.blocking.tracked_attacks) do
         if attack.blocking_type == "projectile" then
            if not tools.table_contains_property(gamestate.projectiles, "id", attack.id) then
               dummy.blocking.tracked_attacks[attack.id] = nil
            end
         elseif attack.blocking_type == "player" then
            if player.is_idle then dummy.blocking.tracked_attacks[attack.id] = nil end
         end
      end

      if dummy.blocking.block_until_confirmed then
         if dummy.just_became_idle or dummy.has_just_blocked or dummy.has_just_parried or dummy.has_just_been_hit or
             gamestate.frame_number - dummy.blocking.force_block_start_frame >= force_block_timeout then
            dummy.blocking.block_until_confirmed = false
         end
      end

      for key, attack in pairs(dummy.blocking.tracked_attacks) do
         if not tools.table_contains_property(dummy.blocking.expected_attacks, "id", attack.id) and
             not attack.force_block then dummy.blocking.tracked_attacks[key] = nil end
         if attack.force_block then
            if dummy.blocking.block_until_confirmed then block_inputs = attack.block_inputs end
            if attack.blocking_type == "player" then
               if player.animation ~= attack.animation then
                  dummy.blocking.block_until_confirmed = false
                  attack.force_block = nil
               end
            elseif attack.blocking_type == "projectile" then
               if not tools.table_contains_property(gamestate.projectiles, "id", attack.id) then
                  dummy.blocking.block_until_confirmed = false
                  attack.force_block = nil
               end
            end
         end
         if player.superfreeze_just_began then
            attack.connect_frame = attack.connect_frame + player.remaining_freeze_frames
         end
         if attack.should_ignore and gamestate.frame_number >= attack.connect_frame then
            attack.should_ignore = false
         end
         -- debug
         -- print(gamestate.frame_number, attack.id, attack.animation, attack.delta, attack.should_ignore, attack.force_block, attack.connect_frame)
      end

      local delta = 100

      for i, expected_attack in ipairs(dummy.blocking.expected_attacks) do
         local hit_type = 1
         if expected_attack.delta > 0 then
            if expected_attack.delta < delta then delta = expected_attack.delta end

            if blocking_queue[expected_attack.delta] == nil then
               blocking_queue[expected_attack.delta] = {}
               blocking_queue[expected_attack.delta].hit_type = 0
               blocking_queue[expected_attack.delta].attacks = {}
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
                     hit_type = fdata_meta.hit_type[expected_attack.hit_id] -- debug
                  end
                  if fdata_meta.unparryable then
                     blocking_queue[expected_attack.delta].unparryable = true
                  end
               end
            end

            if hit_type > blocking_queue[expected_attack.delta].hit_type then
               if block_type == 2 and prefer_parry_low and blocking_queue[expected_attack.delta].hit_type == 1 then
                  blocking_queue[expected_attack.delta].hit_type = 2
               elseif block_type == 1 and prefer_block_low and hit_type ~= 4 then
                  blocking_queue[expected_attack.delta].hit_type = 2
               else
                  blocking_queue[expected_attack.delta].hit_type = hit_type
               end
               if expected_attack.blocking_type == "projectile" then
                  expected_attack.reverse = block_type == 1 and (expected_attack.flip_x == 1 and dummy.flip_input)
               end
               table.insert(blocking_queue[expected_attack.delta].attacks, expected_attack)
            end
         end

         expected_attack.connect_frame = gamestate.frame_number + expected_attack.delta

         -- debug
         -- print(gamestate.frame_number, expected_attack.delta, expected_attack.blocking_type, expected_attack.animation, dummy.current_hit_id, expected_attack.hit_id)
      end
      -- cancelling into moves can alter parry timing
      if block_type == 2 and player.just_cancelled_into_attack then dummy.blocking.should_reset_parry = true end

      local next_attacks = {}
      if blocking_queue[delta] then
         for _, attack in ipairs(blocking_queue[delta].attacks) do
            if not dummy.blocking.tracked_attacks[attack.id] then
               dummy.blocking.tracked_attacks[attack.id] = attack
            end
            if attack.hit_id > dummy.blocking.tracked_attacks[attack.id].hit_id or attack.animation ~=
                dummy.blocking.tracked_attacks[attack.id].animation then
               dummy.blocking.tracked_attacks[attack.id].should_ignore = false
            end

            for key, value in pairs(attack) do dummy.blocking.tracked_attacks[attack.id][key] = value end

            if not precise_blocking or
                (precise_blocking and not dummy.blocking.tracked_attacks[attack.id].should_ignore) then
               table.insert(next_attacks, attack)
            end
         end
      end

      if #next_attacks > 0 or dummy.blocking.block_until_confirmed then
         local hit_type = 1
         local reverse = false
         local parry_type = "parry_forward"
         if blocking_queue[delta] then
            hit_type = blocking_queue[delta].hit_type
            local is_projectile = false
            for _, attack in pairs(next_attacks) do
               -- reverse blocking direction for projectiles created on the opposite side (parrying out of unblockables)
               if attack.reverse then reverse = true end
               if style == 1 then
                  if attack.blocking_type == "player" and attack.switched_sides then
                     print("switch sides") -- debug
                     reverse = true
                     write_memory.clear_parry_validity(dummy)
                     write_memory.clear_parry_cooldowns(dummy)
                     -- write_memory.max_parry_cooldowns(dummy)
                  end
               end
               if attack.blocking_type == "projectile" then is_projectile = true end
               local t = attack.animation or attack.projectile_type
               print(string.format("#%d - hit in [%d] type: %s hit id: %d hit type: %d", gamestate.frame_number,
                                   attack.delta, t, attack.hit_id, hit_type)) -- debug
            end

            if block_type == 2 and blocking_queue[delta] and blocking_queue[delta + 1] then
               if blocking_queue[delta].hit_type == 1 and blocking_queue[delta + 1].hit_type ~= 1 then
                  blocking_queue[delta].hit_type = blocking_queue[delta + 1].hit_type
                  hit_type = blocking_queue[delta].hit_type
               end
            end

            if blocking_queue[delta].unparryable then block_type = 1 end

            if block_type == 2 then
               -- parrying 1f startup supers after screen darkening is impossible...
               -- so we cheat! has the added benefit of not messing up parry inputs after screen darkening
               if player.superfreeze_decount > 0 then write_memory.max_parry_validity(dummy) end

               -- determine parry type
               local dummy_airborne = dummy.posture >= 20 and dummy.posture <= 30
               local opponent_airborne = dummy.other.posture >= 20 and dummy.other.posture <= 30
               if dummy_airborne and dummy.pos_y > 0 then
                  parry_type = "parry_air"
               elseif opponent_airborne and not is_projectile then
                  parry_type = "parry_antiair"
               end

               local parry_low = hit_type == 2 or (prefer_parry_low and hit_type == 1 and dummy.pos_y <= 8)
               if parry_low then parry_type = "parry_down" end

               -- input neutral before parry
               if delta - 1 > 0 and delta <= blocking_delta_threshold + 1 and gamestate.frame_number -
                   dummy.blocking.pre_parry_frame > 1 then
                  inputs.clear_input_sequence(dummy)
                  dummy.blocking.is_pre_parrying = true
                  dummy.blocking.pre_parry_frame = gamestate.frame_number
                  dummy.blocking.is_blocking = true
                  dummy.blocking.is_blocking_this_frame = true
               end

               if dummy.blocking.should_reset_parry and delta > 1 then
                  write_memory.clear_parry_validity(dummy)
                  write_memory.clear_parry_cooldowns(dummy)
                  dummy.blocking.should_reset_parry = false
               end
            end
         end

         if (delta <= blocking_delta_threshold and not (block_type == 2 and dummy.blocking.is_pre_parrying)) or
             dummy.blocking.block_until_confirmed then
            dummy.blocking.is_blocking = true
            dummy.blocking.is_blocking_this_frame = true
            if inputs.is_playing_input_sequence(dummy) then
               local inputs_remaining = #dummy.pending_input_sequence.sequence -
                                            dummy.pending_input_sequence.current_frame + 1
               if inputs_remaining - delta < 1 then
                  return
               else
                  inputs.clear_input_sequence(dummy)
                  dummy.blocking.should_reset_parry = true
               end
            end

            if dummy.blocking.block_until_confirmed and block_inputs then
               block_result = force_block(block_inputs, dummy.blocking.last_block)
            else
               block_result = block_attack(hit_type, block_type, parry_type, delta, reverse)
            end

            if block_result then
               dummy.blocking.last_block = block_result

               for _, attack in pairs(next_attacks) do
                  if delta == 1 then -- assume we blocked successfully
                     if not dummy.blocking.tracked_attacks[attack.id].force_block then
                        dummy.blocking.tracked_attacks[attack.id].should_ignore = true
                     end
                     if dummy.blocking.tracked_attacks[attack.id].blocking_type == "projectile" then
                        table.insert(dummy.blocking.expected_hit_projectiles, attack.id)
                     end
                  end
                  -- keep blocking until we can confirm it for improved consistency
                  -- we don't have this luxury when red parrying
                  if (dummy.blocking.blocked_hit_count == 0 and block_type == 1) or style == 1 then
                     if not dummy.blocking.block_until_confirmed then
                        dummy.blocking.force_block_start_frame = gamestate.frame_number
                     end
                     dummy.blocking.block_until_confirmed = true
                     dummy.blocking.tracked_attacks[attack.id].force_block = true
                     dummy.blocking.tracked_attacks[attack.id].block_inputs = {
                        Right = input[dummy.prefix .. " Right"],
                        Left = input[dummy.prefix .. " Left"],
                        Down = input[dummy.prefix .. " Down"]
                     }
                  end
               end
            end
            if dummy.is_idle then
               if dummy.is_standing then
                  if tools.is_pressing_down(dummy, input) then
                     if dummy.action ~= 30 then
                        expected_player_animation = animations.CROUCHING_BEGIN
                     end
                  elseif tools.is_pressing_forward(dummy, input) then
                     if dummy.action == 23 or dummy.action == 30 then
                        expected_player_animation = animations.WALK_FORWARD
                     elseif dummy.action == 3 then
                        expected_player_animation = animations.WALK_TRANSITION
                     end
                  elseif tools.is_pressing_back(dummy, input) then
                     expected_player_animation = animations.BLOCK_HIGH_PROXIMITY
                  end
               elseif dummy.is_crouching then
                  if not tools.is_pressing_down(dummy, input) then
                     if dummy.action ~= 31 then
                        expected_player_animation = animations.STANDING_BEGIN
                     end
                  elseif tools.is_pressing_back(dummy, input) then
                     expected_player_animation = animations.BLOCK_LOW_PROXIMITY
                  end
               end
            end
         end
      end

      if expected_player_animation ~= previous_expected_player_animation then
         dummy.blocking.expected_player_animation = expected_player_animation
      end

      dummy.blocking.parried_last_frame = false
      if block_result and block_result.type == "parry" and block_result.sub_type ~= "pass" then
         dummy.blocking.parried_last_frame = true
      end
   end
end

local mash_start_frame = 1
local mash_directions_normal = {
   {"down", "forward"}, {"down"}, {"down", "back"}, {"back"}, {"up", "back"}, {"up"}, {"up", "forward"}, {"forward"}
}
local mash_directions_serious = {
   {"down", "back"}, {"down"}, {"up", "forward"}, {"up"}, {"down", "back"}, {"up", "forward"}
}
local mash_directions_fastest = {{"down", "forward"}, {"down", "back"}}
local mash_directions = mash_directions_fastest
local all_buttons = {"LP", "MP", "HP", "LK", "MK", "HK"}
local serious_buttons = {"LP", "MP", "HP", "HK", "MK", "LK"}
local p_buttons = {"LP", "MP", "HP"}
local k_buttons = {"LK", "MK", "HK"}

local i_mash_directions = 1
local i_mash_buttons = 1

local mash_inputs_mode = 1

local function update_mash_inputs(input, player, dummy, mode)
   mash_inputs_mode = mode

   if not gamestate.is_in_match or mode == 1 or recording.current_recording_state == 4 or dummy.posture == 24 or
       dummy.posture == 38 then return end
   if dummy.stun_just_began or dummy.has_just_been_thrown then
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
   if dummy.is_stunned or (dummy.is_being_thrown and dummy.other.throw_countdown <= 1) then
      -- try to prevent move from coming out
      -- diagonal input reduces stun by 3
      -- pressing all buttons reduces stun by 4 more
      if dummy.stun_timer <= 15 and dummy.stun_timer > 0 and not dummy.is_being_thrown then
         mash_directions = mash_directions_fastest
         i_mash_directions = tools.wrap_index(i_mash_directions, #mash_directions)
      end

      local elapsed = gamestate.frame_number - mash_start_frame
      local sequence = {}
      if dummy.stun_timer >= 8 or dummy.is_being_thrown then
         -- normal
         if mode == 2 then
            table.insert(sequence, tools.deepcopy(mash_directions[i_mash_directions]))
            table.insert(sequence[1], p_buttons[i_mash_buttons])
            table.insert(sequence[1], k_buttons[#k_buttons - i_mash_buttons + 1])
            if elapsed % 4 == 0 then
               i_mash_directions = tools.wrap_index(i_mash_directions + 1, #mash_directions)
            end
            if elapsed % 6 == 0 then i_mash_buttons = tools.wrap_index(i_mash_buttons + 1, #p_buttons) end
            -- serious
         elseif mode == 3 then
            if dummy.is_being_thrown then -- try to make mashing realistic
               table.insert(sequence, tools.deepcopy(mash_directions[i_mash_directions]))
               table.insert(sequence[1], serious_buttons[i_mash_buttons])
               if elapsed % 4 == 0 then
                  i_mash_buttons = tools.wrap_index(i_mash_buttons + 1, #serious_buttons)
               end
            else
               table.insert(sequence, tools.deepcopy(mash_directions[i_mash_directions]))
               table.insert(sequence[1], p_buttons[i_mash_buttons])
               table.insert(sequence[1], p_buttons[tools.wrap_index(i_mash_buttons + 1, #p_buttons)])
               table.insert(sequence[1], k_buttons[#k_buttons - i_mash_buttons + 1])
               table.insert(sequence[1], k_buttons[tools.wrap_index(#k_buttons - i_mash_buttons, #k_buttons)])
               i_mash_buttons = tools.wrap_index(i_mash_buttons + 1, #p_buttons)
            end

            if elapsed % 3 == 0 then
               i_mash_directions = tools.wrap_index(i_mash_directions + 1, #mash_directions)
            end
            -- fastest
         elseif mode == 4 then
            table.insert(sequence, tools.deepcopy(mash_directions[i_mash_directions]))
            if elapsed % 2 == 0 then
               for _, button in pairs(all_buttons) do table.insert(sequence[1], button) end
            end
            i_mash_directions = tools.wrap_index(i_mash_directions + 1, #mash_directions)
         end
      end
      if #sequence > 0 then inputs.queue_input_sequence(dummy, sequence) end
   end
end

local function update_fast_wake_up(input, player, dummy, mode)
   if gamestate.is_in_match and mode ~= 1 and recording.current_recording_state ~= 4 then
      local should_tap_down = dummy.previous_can_fast_wakeup == 0 and dummy.can_fast_wakeup == 1

      if should_tap_down then
         local r = math.random()
         if mode ~= 3 or r > 0.5 then input[dummy.prefix .. " Down"] = true end
      end
   end
end

-- normal 1.46
-- serious 2.8
-- fastest 4.33

local stun_reduction_rate_normal = 1.46
local stun_reduction_rate_serious = 2.8
local stun_reduction_rate_fastest = 4.33
local function estimate_frames_until_stun_recovery(stun_timer)
   if mash_inputs_mode == 1 then
      return stun_timer
   elseif mash_inputs_mode == 2 then
      return math.ceil(stun_timer / stun_reduction_rate_normal)
   elseif mash_inputs_mode == 3 then
      return math.ceil(stun_timer / stun_reduction_rate_serious)
   elseif mash_inputs_mode == 4 then
      return math.ceil(stun_timer / stun_reduction_rate_fastest)
   end
end

local function reduce_stun_controlled() end

local guard_jumps = {
   "guard_jump_back", "guard_jump_neutral", "guard_jump_forward", "guard_jump_back_air_parry",
   "guard_jump_neutral_air_parry", "guard_jump_forward_air_parry"
}

local function is_guard_jump(str)
   for i = 1, #guard_jumps do if str == guard_jumps[i] then return true end end
   return false
end

local counter_attack_jump_motions = {
   dir_7 = true,
   dir_8 = true,
   dir_9 = true,
   sjump_back = true,
   sjump_neutral = true,
   sjump_forward = true
}

local wakeup_queued = false
local function update_counter_attack(input, attacker, defender, counter_attack_data, hits_before)
   local debug = false

   if not gamestate.is_in_match or recording.current_recording_state == 4 or not counter_attack_data then return end

   if defender.posture ~= 0x26 then wakeup_queued = false end

   local function handle_recording()
      if counter_attack_data.ca_type == 5 and defender.id == 2 then
         local slot_index = settings.training.current_recording_slot
         if settings.training.replay_mode == 2 or settings.training.replay_mode == 5 then
            slot_index = recording.find_random_recording_slot()
         elseif settings.training.replay_mode == 3 or settings.training.replay_mode == 6 then
            slot_index = recording.go_to_next_ordered_slot()
         end
         if slot_index < 0 then return end

         defender.counter.counter_type = "recording"
         defender.counter.recording_slot = slot_index

         local delay = recording.recording_slots[defender.counter.recording_slot].delay or 0
         local random_deviation = recording.recording_slots[defender.counter.recording_slot].random_deviation or 0
         if random_deviation <= 0 then
            random_deviation = math.ceil(math.random(random_deviation - 1, 0))
         else
            random_deviation = math.floor(math.random(0, random_deviation + 1))
         end
         if debug then print(string.format("frame offset: %d", delay + random_deviation)) end
         defender.counter.attack_frame = defender.counter.attack_frame + delay + random_deviation
      end
   end
   if defender.blocking.blocked_hit_count >= hits_before then
      if defender.has_just_parried then
         if debug then print(gamestate.frame_number .. " - init ca (parry)") end
         log(defender.prefix, "counter_attack", "init ca (parry)")
         defender.counter.counter_type = "reversal"
         defender.counter.attack_frame = gamestate.frame_number + 15
         if defender.is_airborne then
            defender.counter.attack_frame = defender.counter.attack_frame + 2
            if counter_attack_data.ca_type == 2 and counter_attack_data.normal_button ~= "none" then
               defender.counter.attack_frame = defender.counter.attack_frame + 2
            end
         end
         if counter_attack_data.ca_type == 3 then
            defender.counter.attack_frame = defender.counter.attack_frame + 1
         end
         defender.counter.sequence, defender.counter.offset =
             inputs.create_counter_attack_input_sequence(counter_attack_data)
         if counter_attack_data.move_type == "kara_special" then
            defender.counter.offset = defender.counter.offset + 1
            if counter_attack_data.name == "kara_karakusa_lk" then
               for i = 1, 8 do table.insert(defender.counter.sequence, 2, {}) end
            end
         elseif counter_attack_data.ca_type == 2 and counter_attack_jump_motions[counter_attack_data.motion] and
             defender.is_standing or defender.is_crouching then
            defender.counter.offset = 4
         elseif counter_attack_data.name == "sgs" then
            defender.counter.offset = defender.counter.offset + 4
         end
         defender.counter.ref_time = -1
         handle_recording()

      elseif defender.has_just_blocked or (defender.has_just_been_hit and not defender.is_being_thrown) then
         if debug then print(gamestate.frame_number .. " - init ca (hit/block)") end
         log(defender.prefix, "counter_attack", "init ca (hit/block)")
         defender.counter.ref_time = defender.recovery_time
         inputs.clear_input_sequence(defender)
         defender.counter.attack_frame = -1
         defender.counter.sequence = nil
         defender.counter.recording_slot = -1
      elseif defender.is_waking_up and defender.remaining_wakeup_time > 0 and defender.remaining_wakeup_time <= 20 and
          not wakeup_queued then
         if debug then print(gamestate.frame_number .. " - init ca (wake up)") end
         log(defender.prefix, "counter_attack", "init ca (wakeup)")
         defender.counter.attack_frame = gamestate.frame_number + defender.remaining_wakeup_time
         wakeup_queued = true
         if counter_attack_data.ca_type == 4 then
            if is_guard_jump(counter_attack_data.name) then
               defender.counter.counter_type = "guard_jump"
               defender.counter.attack_frame = defender.counter.attack_frame - 4 -- avoid hj input
            else
               defender.counter.counter_type = "other_os"
            end
         elseif (counter_attack_data.ca_type == 2 and counter_attack_data.motion == "kara_throw") then
            defender.counter.counter_type = "reversal"
            defender.counter.attack_frame = defender.counter.attack_frame
         else
            defender.counter.counter_type = "reversal"
            defender.counter.attack_frame = defender.counter.attack_frame + 2
         end
         defender.counter.sequence, defender.counter.offset =
             inputs.create_counter_attack_input_sequence(counter_attack_data)
         defender.counter.ref_time = -1
         handle_recording()
      elseif defender.has_just_entered_air_recovery then
         inputs.clear_input_sequence(defender)
         defender.counter.counter_type = "reversal"
         defender.counter.ref_time = -1
         defender.counter.attack_frame = gamestate.frame_number + 100
         defender.counter.sequence, defender.counter.offset =
             inputs.create_counter_attack_input_sequence(counter_attack_data)
         defender.counter.air_recovery = true
         handle_recording()
         log(defender.prefix, "counter_attack", "init ca (air)")
      end
   end
   if not defender.counter.sequence then -- has just blocked/been hit
      if defender.counter.ref_time ~= -1 and defender.recovery_time ~= defender.counter.ref_time then
         if debug then print(gamestate.frame_number .. " - setup ca") end
         log(defender.prefix, "counter_attack", "setup ca")
         defender.counter.attack_frame = gamestate.frame_number + defender.recovery_time +
                                             defender.additional_recovery_time

         defender.counter.counter_type = "reversal"

         if counter_attack_data.ca_type == 4 then
            if is_guard_jump(counter_attack_data.name) then
               defender.counter.counter_type = "guard_jump"
               defender.counter.attack_frame = defender.counter.attack_frame - 3 -- avoid hj input
            else
               defender.counter.counter_type = "other_os"
            end
         elseif counter_attack_data.ca_type == 2 and counter_attack_data.motion == "kara_throw" then

         else
            defender.counter.attack_frame = defender.counter.attack_frame + 2
         end
         defender.counter.sequence, defender.counter.offset =
             inputs.create_counter_attack_input_sequence(counter_attack_data)
         defender.counter.ref_time = -1
         handle_recording()
      end
   end

   if defender.counter.sequence then
      if defender.counter.air_recovery then
         local frames_before_landing = prediction.predict_frames_before_landing(defender)
         if frames_before_landing > 0 then
            defender.counter.attack_frame = gamestate.frame_number + frames_before_landing + 2
         elseif frames_before_landing == 0 then
            defender.counter.attack_frame = gamestate.frame_number
         end
      end
      if defender.is_stunned and defender.stun_timer > 0 then
         local frames_until_recovery = estimate_frames_until_stun_recovery(defender.stun_timer)
         local offset = 2
         if frames_until_recovery > 0 and frames_until_recovery <= #defender.counter.sequence + offset then end
      end
      local frames_remaining = defender.counter.attack_frame - gamestate.frame_number
      if debug then print(frames_remaining) end

      -- option select
      if counter_attack_data.ca_type == 4 or
          (counter_attack_data.ca_type == 2 and (counter_attack_data.motion == "kara_throw") or
              counter_attack_jump_motions[counter_attack_data.motion]) then
         if frames_remaining <= 0 then
            defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
            print(defender.counter.attack_frame, gamestate.frame_number - defender.counter.attack_frame,
                  #defender.counter.sequence, defender.counter.offset)
            inputs.queue_input_sequence(defender, defender.counter.sequence, defender.counter.offset)
            defender.counter.sequence = nil
            defender.counter.attack_frame = -1
            defender.counter.air_recovery = false
         end
      elseif defender.counter.counter_type == "reversal" then
         if frames_remaining <= (#defender.counter.sequence + 1) then
            if debug then print(gamestate.frame_number .. " - queue ca") end
            log(defender.prefix, "counter_attack", string.format("queue ca %d", frames_remaining))
            defender.counter.offset = defender.counter.offset + settings.training.counter_attack_delay
            if defender.blocking.is_blocking_this_frame then
               defender.counter.sequence = nil
               defender.counter.attack_frame = -1
               defender.counter.air_recovery = false
               return
            end
            inputs.queue_input_sequence(defender, defender.counter.sequence, defender.counter.offset)
            defender.counter.sequence = nil
            defender.counter.attack_frame = -1
            defender.counter.air_recovery = false
         end
      end
   elseif counter_attack_data.ca_type == 5 and defender.counter.recording_slot > 0 then
      if defender.counter.attack_frame <= (gamestate.frame_number + 1) then
         if settings.training.replay_mode == 2 or settings.training.replay_mode == 3 or settings.training.replay_mode ==
             5 or settings.training.replay_mode == 6 then
            recording.override_replay_slot = defender.counter.recording_slot
         end
         if debug then print(gamestate.frame_number .. " - queue recording") end
         log(defender.prefix, "counter_attack", "queue recording")
         defender.counter.attack_frame = -1
         defender.counter.recording_slot = -1
         defender.counter.air_recovery = false
         recording.set_recording_state(input, 1)
         recording.set_recording_state(input, 4)
         recording.override_replay_slot = -1
      end
   end
end

local tech_throw_frame = 0
local function update_tech_throws(input, attacker, defender, mode)
   if not gamestate.is_in_match or mode == 1 then return end
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

local function reset() tech_throw_frame = 0 end

return {
   update_pose = update_pose,
   update_blocking = update_blocking,
   update_mash_inputs = update_mash_inputs,
   update_fast_wake_up = update_fast_wake_up,
   update_counter_attack = update_counter_attack,
   update_tech_throws = update_tech_throws,
   reset = reset
}
