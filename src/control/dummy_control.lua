local settings = require("src.settings")
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local gamestate = require("src.gamestate")
local inputs = require("src.control.inputs")
local prediction = require("src.modules.prediction")
local write_memory = require("src.control.write_memory")
local recording = require("src.control.recording")
local tools = require("src.tools")
local utils = require("src.modules.utils")

local frame_data_meta = fdm.frame_data_meta

local poses = {
   STANDING = 1,
   CROUCHING = 2,
   JUMP_FORWARD = 3,
   JUMP_NEUTRAL = 4,
   JUMP_BACK = 5,
   SJUMP_FORWARD = 6,
   SJUMP_NEUTRAL = 7,
   SJUMP_BACK = 8
}

local disable = {}
local function disable_update(name, value) disable[name] = value end

local function update_pose(input, player, dummy, pose)
   if recording.current_recording_state == 4 -- Replaying
   or dummy.blocking.is_blocking_this_frame or disable.pose then return end
   if gamestate.is_in_match and not inputs.is_playing_input_sequence(dummy) then
      local on_ground = gamestate.is_ground_state(dummy, dummy.standing_state)
      local is_waking_up = dummy.is_waking_up and dummy.remaining_wakeup_time > 0 and dummy.remaining_wakeup_time <= 3
      local wakeup_frame = dummy.standing_state == 0 and dummy.posture == 0

      if pose == poses.CROUCHING and (on_ground or is_waking_up or wakeup_frame) then
         inputs.queue_input_sequence(dummy, {{"down"}})
      elseif on_ground then
         if pose == poses.JUMP_FORWARD and on_ground then
            inputs.queue_input_sequence(dummy, {{"up", "forward"}, {"up", "forward"}, {"up", "forward"}})
         elseif pose == poses.JUMP_NEUTRAL and on_ground then
            inputs.queue_input_sequence(dummy, {{"up"}, {"up"}, {"up"}})
         elseif pose == poses.JUMP_BACK and on_ground then
            inputs.queue_input_sequence(dummy, {{"up", "back"}, {"up", "back"}, {"up", "back"}})
         elseif pose == poses.SJUMP_FORWARD and on_ground then
            inputs.queue_input_sequence(dummy, {{"down"}, {"up", "forward"}, {"up", "forward"}, {"up", "forward"}})
         elseif pose == poses.SJUMP_NEUTRAL and on_ground then
            inputs.queue_input_sequence(dummy, {{"down"}, {"up"}, {"up"}, {"up"}})
         elseif pose == poses.SJUMP_BACK and on_ground then
            inputs.queue_input_sequence(dummy, {{"down"}, {"up", "back"}, {"up", "back"}, {"up", "back"}})

         end
      end
   end
end
local Block_Style = {BLOCK = 1, PARRY = 2, RED_PARRY = 3}
local Block_Type = {BLOCK = 1, PARRY = 2}
local force_block_timeout = 20

local function update_blocking(input, player, dummy, mode, style, red_parry_hit_count, parry_every_n_count)

   local function has_enough_parry_validity(parry_type, delta)
      return (not dummy.is_blocking and dummy[parry_type].validity_time > delta) or
                 (dummy.is_blocking and dummy[parry_type].validity_time == dummy[parry_type].max_validity)
   end

   local function block_attack(hit_type, block_type, parry_type, delta, reverse)
      print(gamestate.frame_number, hit_type, block_type, delta, reverse, dummy[parry_type].validity_time) -- debug
      local p2_forward = tools.bool_xor(dummy.flip_input, reverse)
      local p2_back = not tools.bool_xor(dummy.flip_input, reverse)
      local sub_type = "high"
      if block_type == Block_Type.BLOCK and dummy.pos_y <= 8 then -- no air blocking!
         input[dummy.prefix .. " Right"] = p2_back
         input[dummy.prefix .. " Left"] = p2_forward

         if hit_type == 2 then
            input[dummy.prefix .. " Down"] = true
            sub_type = "low"
         elseif hit_type == 3 or hit_type == 4 then
            input[dummy.prefix .. " Down"] = false
         end
         return {type = "block", sub_type = sub_type, hit_type = hit_type, frame_number = gamestate.frame_number}
      elseif block_type == Block_Type.PARRY then
         -- don't parry if it would result in a dash
         if not dummy.blocking.last_block.has_connected and gamestate.frame_number -
             dummy.blocking.last_block.frame_number <= 7 and
             ((dummy.blocking.last_block.inputs.Right and p2_forward) or
                 (dummy.blocking.last_block.inputs.Left and p2_back)) then
            if has_enough_parry_validity(parry_type, delta) then
               return {type = "parry", sub_type = "pass", hit_type = hit_type, frame_number = gamestate.frame_number}
            else
               return block_attack(hit_type, Block_Type.BLOCK, parry_type, delta, reverse)
            end
         end
         if dummy[parry_type].cooldown_time > 0 then
            if has_enough_parry_validity(parry_type, delta) then
               return {type = "parry", sub_type = "pass", hit_type = hit_type, frame_number = gamestate.frame_number}
            else
               return block_attack(hit_type, Block_Type.BLOCK, parry_type, delta, reverse)
            end
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
               return {type = "parry", sub_type = sub_type, hit_type = hit_type, frame_number = gamestate.frame_number}
            else
               print("can not parry") -- block the attack instead --debug
               -- return block_attack(hit_type, Block_Type.BLOCK, parry_type, delta, reverse)
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
         frame_number = gamestate.frame_number
      }
   end

   local function reverse_inputs(block_inputs)
      local out = {}
      for dir, value in pairs(block_inputs) do out[dir] = dir ~= "Down" and not value or value end
      return out
   end

   local function get_hit_type(attacks, block_type, prefer_block_low, prefer_parry_low)
      local result = {hit_type = 1}
      for _, attack in pairs(attacks) do
         local hit_type = 1
         local fdata_meta
         if attack.blocking_type == "projectile" then
            if attack.is_seieienbu then
               fdata_meta = frame_data_meta["yang"][attack.animation]
            else
               fdata_meta = frame_data_meta["projectiles"][attack.animation]
            end
         else
            fdata_meta = frame_data_meta[player.char_str][attack.animation]
         end
         if fdata_meta then
            if fdata_meta.hit_type and fdata_meta.hit_type[attack.hit_id] then
               hit_type = fdata_meta.hit_type[attack.hit_id]
            end
            if fdata_meta.unparryable then result.unparryable = true end
            if fdata_meta.unblockable then result.unblockable = true end
         end

         if hit_type > result.hit_type then
            if block_type == Block_Type.PARRY and prefer_parry_low and result.hit_type == 1 then
               result.hit_type = 2
            elseif block_type == Block_Type.BLOCK and prefer_block_low and hit_type ~= 4 then
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
   dummy.blocking.received_hit_count = dummy.blocking.received_hit_count or 0
   dummy.blocking.parried_last_frame = dummy.blocking.parried_last_frame or false
   dummy.blocking.is_pre_parrying = false
   dummy.blocking.pre_parry_frame = dummy.blocking.pre_parry_frame or 0
   dummy.blocking.last_block = dummy.blocking.last_block or {frame_number = 0}
   dummy.blocking.tracked_attacks = dummy.blocking.tracked_attacks or {}
   dummy.blocking.force_block_start_frame = dummy.blocking.force_block_start_frame or 0

   if not gamestate.is_in_match or mode == 1 or recording.current_recording_state == 4 -- exit if playing recording
   then return end

   if dummy.blocking.expected_hit_projectiles then
      for _, id in ipairs(dummy.blocking.expected_hit_projectiles) do
         if gamestate.projectiles[id] then
            gamestate.projectiles[id].remaining_hits = gamestate.projectiles[id].remaining_hits - 1
            gamestate.update_projectile_cooldown(gamestate.projectiles[id])
         end
      end
   end

   dummy.blocking.expected_hit_projectiles = {}
   dummy.blocking.expected_attacks = {}

   local frames_prediction = 3

   dummy.blocking.expected_attacks = prediction.predict_hits(player, nil, nil, dummy, nil, nil, frames_prediction)
   if dummy.just_received_connection then
      dummy.blocking.received_hit_count = dummy.blocking.received_hit_count + 1
      dummy.blocking.last_block.has_connected = true
   end
   if dummy.has_just_blocked or dummy.has_just_parried then
      dummy.blocking.blocked_hit_count = dummy.blocking.blocked_hit_count + 1
   end

   if dummy.is_idle and player.is_idle then
      dummy.blocking.blocked_hit_count = 0
      if dummy.idle_time >= 10 then dummy.blocking.received_hit_count = 0 end
      dummy.blocking.is_blocking = false
      if mode == 5 then
         if math.random() > 0.5 then
            dummy.blocking.randomized_out = true
         else
            dummy.blocking.randomized_out = false
         end
      end
   end

   if not (mode == 5 and dummy.blocking.randomized_out) and not (mode == 4 and dummy.blocking.received_hit_count == 0) and
       not (mode == 3 and dummy.blocking.blocked_hit_count > 0) then
      local block_type = style -- 1 is block, 2 is parry
      local blocking_delta_threshold = 2 -- blocks/parries must be input 1 frame before the attack hits. blocking_delta_threshold = 1 minimum
      local blocking_queue = {}
      local block_result
      local block_inputs
      local prefer_parry_low = settings.training.prefer_down_parry
      local prefer_block_low = settings.training.pose == 2

      if style == Block_Style.RED_PARRY then -- red parry
         block_type = Block_Type.BLOCK
         if not (dummy.blocking.blocked_hit_count == 0) then blocking_delta_threshold = 1 end
         if dummy.blocking.blocked_hit_count >= red_parry_hit_count then
            if (dummy.blocking.blocked_hit_count - red_parry_hit_count) % (parry_every_n_count + 1) == 0 then
               block_type = Block_Type.PARRY
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
         if (player.character_state_byte ~= 4 and not utils.has_projectiles(player)) or dummy.has_just_blocked or
             dummy.has_just_parried or dummy.has_just_been_hit or gamestate.frame_number -
             dummy.blocking.force_block_start_frame >= force_block_timeout then
            dummy.blocking.block_until_confirmed = false
         end
      end

      if dummy.has_just_blocked or dummy.has_just_parried or dummy.has_just_been_hit then
         dummy.blocking.last_block.has_connected = true
      end

      for key, attack in pairs(dummy.blocking.tracked_attacks) do
         if not tools.table_contains_property(dummy.blocking.expected_attacks, "id", attack.id) and
             not attack.force_block then dummy.blocking.tracked_attacks[key] = nil end
         if attack.force_block then
            if dummy.blocking.block_until_confirmed then
               block_inputs = attack.block_inputs
            else
               attack.force_block = nil
               attack.block_inputs = nil
               attack.should_ignore = true
            end
            if attack.blocking_type == "player" then
               if player.animation_frame > fd.get_last_hit_frame(player.char_str, player.animation) or player.animation ~=
                   attack.animation then
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
         if attack.blocking_type == "player" then
            -- cancelling into moves can alter parry timing
            if block_type == Block_Type.PARRY and player.just_cancelled_into_attack and
                not dummy.blocking.last_block.has_connected then
               attack.animation = player.animation
               attack.allow_cheat_parry = true
               attack.should_ignore = false
            end
         end
         if player.superfreeze_just_began then
            attack.connect_frame = attack.connect_frame + player.remaining_freeze_frames
         end

         print(gamestate.frame_number, attack.id, attack.animation)
      end

      local delta = 100

      for i, expected_attack in ipairs(dummy.blocking.expected_attacks) do
         if expected_attack.delta > 0 then
            if expected_attack.delta < delta then delta = expected_attack.delta end
            if blocking_queue[expected_attack.delta] == nil then
               blocking_queue[expected_attack.delta] = {}
               blocking_queue[expected_attack.delta].hit_type = 1
               blocking_queue[expected_attack.delta].attacks = {}
            end
            table.insert(blocking_queue[expected_attack.delta].attacks, expected_attack)
         end
         expected_attack.connect_frame = gamestate.frame_number + expected_attack.delta

         -- debug
         print(gamestate.frame_number, expected_attack.id, expected_attack.delta, expected_attack.blocking_type,
               expected_attack.animation, dummy.current_hit_id, expected_attack.hit_id)
      end

      for _, blocking_data in pairs(blocking_queue) do
         blocking_data.hit_type, blocking_data.hit_type, blocking_data.hit_type =
             get_hit_type(blocking_data.attacks, block_type, prefer_block_low, prefer_parry_low)
      end

      local next_attacks = {}
      if blocking_queue[delta] then
         for _, attack in ipairs(blocking_queue[delta].attacks) do
            if not dummy.blocking.tracked_attacks[attack.id] then
               dummy.blocking.tracked_attacks[attack.id] = attack
               if attack.blocking_type == "projectile" and not attack.is_seieienbu then
                  dummy.blocking.tracked_attacks[attack.id].remaining_hits =
                      gamestate.projectiles[attack.id].remaining_hits
               end
            end
            if attack.blocking_type == "player" or attack.is_seieienbu then
               if attack.hit_id > dummy.blocking.tracked_attacks[attack.id].hit_id or attack.animation ~=
                   dummy.blocking.tracked_attacks[attack.id].animation or
                   fd.is_infinite_loop(player.char_str, attack.animation) then
                  dummy.blocking.tracked_attacks[attack.id].should_ignore = false
                  dummy.blocking.tracked_attacks[attack.id].allow_cheat_parry = false
               end
            else
               if attack.animation == "00_tenguishi" then
                  if gamestate.projectiles[attack.id].tengu_state == 1 then
                     dummy.blocking.tracked_attacks[attack.id].should_ignore = false
                  end
               elseif gamestate.projectiles[attack.id].remaining_hits <
                   dummy.blocking.tracked_attacks[attack.id].remaining_hits and
                   gamestate.projectiles[attack.id].remaining_hits > 0 then
                  dummy.blocking.tracked_attacks[attack.id].should_ignore = false
               end
            end

            for key, value in pairs(attack) do dummy.blocking.tracked_attacks[attack.id][key] = value end
            print(attack.id, dummy.blocking.tracked_attacks[attack.id].should_ignore,
                  dummy.blocking.tracked_attacks[attack.id].force_block)
            if not dummy.blocking.tracked_attacks[attack.id].should_ignore then
               table.insert(next_attacks, attack)
            end
         end
         blocking_queue[delta].hit_type, blocking_queue[delta].unparryable, blocking_queue[delta].unblockable =
             get_hit_type(next_attacks, block_type, prefer_block_low, prefer_parry_low)
      end

      if #next_attacks > 0 or dummy.blocking.block_until_confirmed then
         local hit_type = 1
         local reverse = false
         local allow_cheat_parry = false
         local parry_type = "parry_forward"

         if blocking_queue[delta] then
            hit_type = blocking_queue[delta].hit_type
            local is_projectile = false
            for _, attack in pairs(next_attacks) do
               -- reverse blocking direction for projectiles created on the opposite side
               if attack.blocking_type == "projectile" then
                  reverse = block_type == Block_Type.BLOCK and (attack.flip_x == 1 and dummy.flip_input)
                  is_projectile = true
               end
               if style == 1 then
                  if attack.blocking_type == "player" then
                     local side = utils.get_side(player.pos_x, dummy.pos_x, player.previous_pos_x, dummy.previous_pos_x)
                     if side ~= attack.side then
                        reverse = true
                        write_memory.disable_parry_attempts(dummy)
                     end
                  end
               end
               if attack.allow_cheat_parry then allow_cheat_parry = true end

               print(string.format("#%d - hit in [%d]  id: %s, type: %s hit id: %d hit type: %d",
                                   gamestate.frame_number, attack.delta, tostring(attack.id), attack.animation,
                                   attack.hit_id, hit_type)) -- debug
            end

            if block_type == Block_Type.PARRY and blocking_queue[delta] and blocking_queue[delta + 1] then
               if blocking_queue[delta].hit_type == 1 and blocking_queue[delta + 1].hit_type ~= 1 then
                  blocking_queue[delta].hit_type = blocking_queue[delta + 1].hit_type
                  hit_type = blocking_queue[delta].hit_type
               end
            end

            if blocking_queue[delta].unparryable then block_type = Block_Type.BLOCK end
            if blocking_queue[delta].unblockable and style == Block_Style.RED_PARRY then
               block_type = Block_Type.PARRY
            end

            if block_type == Block_Type.PARRY then
               -- parrying 1f startup supers after screen darkening is impossible...
               -- so we cheat! has the added benefit of not messing up parry inputs after screen darkening
               if player.superfreeze_decount > 0 then allow_cheat_parry = true end

               -- determine parry type
               local dummy_airborne = not gamestate.is_ground_state(dummy, dummy.standing_state)
               local opponent_airborne = not gamestate.is_ground_state(player, player.standing_state)
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

               print("allow_cheat_parry", allow_cheat_parry)
               if allow_cheat_parry and delta <= 2 and not has_enough_parry_validity(parry_type, delta) then
                  write_memory.max_parry_validity(dummy)
               end
            end
         end

         if (delta <= blocking_delta_threshold and
             not (block_type == Block_Type.PARRY and dummy.blocking.is_pre_parrying)) or
             dummy.blocking.block_until_confirmed then
            dummy.blocking.is_blocking = true
            dummy.blocking.is_blocking_this_frame = true

            if dummy.blocking.block_until_confirmed and block_inputs then
               block_result = force_block(block_inputs, dummy.blocking.last_block)
            else
               block_result = block_attack(hit_type, block_type, parry_type, delta, reverse)
            end

            if block_result then
               dummy.blocking.last_block = block_result
               dummy.blocking.last_block.blocking_type = ""
               dummy.blocking.last_block.frame_number = gamestate.frame_number
               dummy.blocking.last_block.has_connected = false
               dummy.blocking.last_block.inputs = {
                  Right = input[dummy.prefix .. " Right"],
                  Left = input[dummy.prefix .. " Left"],
                  Down = input[dummy.prefix .. " Down"]
               }
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
                  if (dummy.blocking.blocked_hit_count == 0 and block_type == Block_Type.BLOCK) or style == 1 then
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
   if defender.is_grounded then defender.counter.air_recovery = false end

   local function handle_recording()
      if counter_attack_data.type == 5 then
         recording.load_recordings(counter_attack_data.char_str)
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
            if counter_attack_data.type == 2 and counter_attack_data.normal_button ~= "none" then
               defender.counter.attack_frame = defender.counter.attack_frame + 2
            end
         end
         if counter_attack_data.type == 3 then defender.counter.attack_frame = defender.counter.attack_frame + 1 end
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
         if counter_attack_data.move_type == "kara_special" then
            defender.counter.offset = defender.counter.offset + 1
            if counter_attack_data.name == "kara_karakusa_lk" then
               for i = 1, 8 do table.insert(defender.counter.sequence, 2, {}) end
            end
         elseif counter_attack_data.type == 2 and counter_attack_jump_motions[counter_attack_data.motion] and
             defender.is_standing or defender.is_crouching then
            defender.counter.offset = 4
         elseif counter_attack_data.name == "sgs" then
            defender.counter.offset = defender.counter.offset + 4
         end
         defender.counter.ref_time = -1
         handle_recording()

      elseif not defender.is_airborne and
          (defender.has_just_blocked or (defender.has_just_been_hit and not defender.is_being_thrown)) then
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
         if counter_attack_data.type == 4 then
            if is_guard_jump(counter_attack_data.name) then
               defender.counter.counter_type = "guard_jump"
               defender.counter.attack_frame = defender.counter.attack_frame - 4 -- avoid hj input
            else
               defender.counter.counter_type = "other_os"
            end
         elseif (counter_attack_data.type == 2 and counter_attack_data.motion == "kara_throw") then
            defender.counter.counter_type = "reversal"
            defender.counter.attack_frame = defender.counter.attack_frame
         else
            defender.counter.counter_type = "reversal"
            defender.counter.attack_frame = defender.counter.attack_frame + 2
         end
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
         defender.counter.ref_time = -1
         handle_recording()
      elseif defender.has_just_entered_air_recovery then
         if debug then print(gamestate.frame_number .. " - init ca (air)") end
         inputs.clear_input_sequence(defender)
         defender.counter.counter_type = "reversal"
         defender.counter.ref_time = -1
         defender.counter.attack_frame = gamestate.frame_number + 100
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
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

         if counter_attack_data.type == 4 then
            if is_guard_jump(counter_attack_data.name) then
               defender.counter.counter_type = "guard_jump"
               defender.counter.attack_frame = defender.counter.attack_frame - 3 -- avoid hj input
            else
               defender.counter.counter_type = "other_os"
            end
         elseif counter_attack_data.type == 2 and counter_attack_data.motion == "kara_throw" then

         else
            defender.counter.attack_frame = defender.counter.attack_frame + 2
         end
         defender.counter.sequence, defender.counter.offset = inputs.create_input_sequence(counter_attack_data)
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
      if counter_attack_data.type == 4 or
          (counter_attack_data.type == 2 and (counter_attack_data.motion == "kara_throw") or
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
   elseif counter_attack_data.type == 5 and defender.counter.recording_slot > 0 then
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
   reset = reset,
   disable_update = disable_update
}
