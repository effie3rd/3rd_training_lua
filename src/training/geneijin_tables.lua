local gamestate = require("src.gamestate")
local framedata = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local move_data = require("src.modules.move_data")
local stage_data = require("src.modules.stage_data")
local inputs = require("src.control.inputs")
local training_classes = require("src.training.training_classes")
local advanced_control = require("src.control.advanced_control")
local prediction = require("src.modules.prediction")
local tools = require("src.tools")
local utils = require("src.modules.utils")

local Delay = advanced_control.Delay
local Setup, Followup, Action_Type, Setup_Type = training_classes.Setup, training_classes.Followup,
                                                 training_classes.Action_Type, training_classes.Setup_Type
local is_idle_timing, is_wakeup_timing, is_landing_timing = advanced_control.is_idle_timing,
                                                            advanced_control.is_wakeup_timing,
                                                            advanced_control.is_landing_timing
local is_throw_vulnerable_timing = advanced_control.is_throw_vulnerable_timing
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete
local character_specific = framedata.character_specific

local jump_forward_input
local block_high_input
local block_low_input
local block_low_long_input

local walk_forward_input
local walk_back_input
local forward_dash_input
local forward_dash_duration

local lk_input
local lk_hit_frame
local lk_hitboxes
local lk_range
local lk_pushback

local d_lk_input
local d_lk_hit_frame
local d_lk_hitboxes
local d_lk_range
local d_lk_pushback

local cl_mp_input
local cl_mp_hit_frame
local cl_mp_range
local cl_mp_pushback

local far_mp_input
local far_mp_hit_frame
local far_mp_hitboxes
local far_mp_range
local far_mp_pushback

local d_mk_input
local d_mk_hit_frame
local d_mk_range
local d_mk_pushback

local d_hk_input
local d_hk_hit_frame
local d_hk_hitboxes
local d_hk_range
local d_hk_pushback

local far_hp_input
local far_hp_hit_frame
local far_hp_hitboxes
local far_hp_range
local far_hp_pushback

local kara_hp_input = {{"MP"}, {}, {}, {}, {"HP"}}
local f_hp_input = {{"forward", "HP"}}

local zenpou_input
local zenpou_hit_frame
local zenpou_range

local geneijin_input

local attack_range_tolerance = 2
local throw_range_tolerance = 2
local crouching_throw_box_extension = 4
local block_punish_threshold = 0
local reaction_time = 0

local last_hit_frame = math.huge

local geneijin_cancel_frame = {
   LK_geneijin = 4,
   d_LK_geneijin = 4,
   MP_geneijin = 3,
   cl_MP_geneijin = 4,
   d_MK_geneijin = 3,
   HP_geneijin = 11
}

local function get_frame_advantage(player)
   local recovery_time = player.recovery_time + player.additional_recovery_time + 1
   local opponent_recovery_time = prediction.get_frames_until_idle(player.other, nil, nil, 80)
   return opponent_recovery_time - recovery_time
end

local function has_hit_recently()
   if gamestate.frame_number - last_hit_frame <= 20 then return true end
   return false
end

local function init()
   jump_forward_input = {{"up", "forward"}, {"up", "forward"}}
   block_high_input = {{"back"}, {"back"}}
   block_low_input = {{"back", "down"}, {"back", "down"}}

   walk_forward_input = {{"forward"}}
   walk_back_input = {{"back"}}
   block_low_long_input = {}
   for i = 1, 16 do table.insert(block_low_long_input, {"down", "back"}) end
   forward_dash_input = {{"forward"}, {}, {"forward"}}
   forward_dash_duration = framedata.get_first_idle_frame_by_name("yun", "dash_forward")

   lk_input = {{"LK"}}
   lk_hit_frame = framedata.get_first_hit_frame_by_name("yun", "LK_geneijin")
   lk_hitboxes = framedata.get_hitboxes_by_name("yun", "LK_geneijin", nil, lk_hit_frame)
   lk_range = framedata.get_hitbox_max_range_by_name("yun", "LK_geneijin")
   lk_pushback = framedata.get_pushback_by_name("yun", "LK_geneijin")

   d_lk_input = {{"down", "LK"}}
   d_lk_hit_frame = framedata.get_first_hit_frame_by_name("yun", "d_LK_geneijin")
   d_lk_hitboxes = framedata.get_hitboxes_by_name("yun", "d_LK_geneijin", nil, d_lk_hit_frame)
   d_lk_range = framedata.get_hitbox_max_range_by_name("yun", "d_LK_geneijin")
   d_lk_pushback = framedata.get_pushback_by_name("yun", "d_LK_geneijin")

   cl_mp_input = {{"MP"}}
   cl_mp_hit_frame = framedata.get_first_hit_frame_by_name("yun", "cl_MP_geneijin")
   cl_mp_range = framedata.get_hitbox_max_range_by_name("yun", "cl_MP_geneijin")
   cl_mp_pushback = framedata.get_pushback_by_name("yun", "cl_MP_geneijin")

   far_mp_input = {{"MP"}}
   far_mp_hit_frame = framedata.get_first_hit_frame_by_name("yun", "MP_geneijin")
   far_mp_hitboxes = framedata.get_hitboxes_by_name("yun", "MP_geneijin", nil, far_mp_hit_frame)
   far_mp_range = framedata.get_hitbox_max_range_by_name("yun", "MP_geneijin")
   far_mp_pushback = framedata.get_pushback_by_name("yun", "MP_geneijin")

   d_mk_input = {{"down", "MK"}}
   d_mk_hit_frame = framedata.get_first_hit_frame_by_name("yun", "d_MK_geneijin")
   d_mk_range = framedata.get_hitbox_max_range_by_name("yun", "d_MK_geneijin")
   d_mk_pushback = framedata.get_pushback_by_name("yun", "d_MK_geneijin")

   d_hk_input = {{"down", "HK"}}
   d_hk_hit_frame = framedata.get_first_hit_frame_by_name("yun", "d_HK_geneijin")
   d_hk_hitboxes = framedata.get_hitboxes_by_name("yun", "d_HK_geneijin", nil, d_hk_hit_frame)
   d_hk_range = framedata.get_hitbox_max_range_by_name("yun", "d_HK_geneijin")
   d_hk_pushback = framedata.get_pushback_by_name("yun", "d_HK_geneijin")

   far_hp_input = {{"HP"}}
   far_hp_hit_frame = framedata.get_first_hit_frame_by_name("yun", "HP_geneijin")
   far_hp_hitboxes = framedata.get_hitboxes_by_name("yun", "HP_geneijin", nil, far_hp_hit_frame)
   far_hp_range = framedata.get_hitbox_max_range_by_name("yun", "HP_geneijin")
   far_hp_pushback = framedata.get_pushback_by_name("yun", "HP_geneijin")

   zenpou_input = move_data.get_move_inputs_by_name("yun", "zenpou")
   zenpou_hit_frame = framedata.get_first_hit_frame_by_name("yun", "zenpou_geneijin")
   zenpou_range = framedata.get_hitbox_max_range_by_name("yun", "zenpou_geneijin")

   geneijin_input = move_data.get_move_inputs_by_name("yun", "geneijin")

   block_punish_threshold = d_hk_hit_frame
end

local function handle_interruptions(player, stage, actions, i_actions)
   if (player.has_just_been_hit and not player.is_being_thrown) then
      return true, {score = 3, should_end = true} end
   if (player.is_being_thrown and player.throw_tech_countdown <= 0) then
      local score = 3
      local hit_with_command_throw = memory.readbyte(player.other.addresses.hit_with_command_throw) > 0
      local hit_with_super_throw = memory.readbyte(player.other.addresses.hit_with_super_throw) > 0
      if hit_with_command_throw or hit_with_super_throw then score = score end
      return true, {score = score, should_end = true}
   end
   return false
end

local punish_d_hk = Followup:new("punish_d_hk", Action_Type.PUNISH)
function punish_d_hk:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function() return is_idle_timing(player, #d_hk_input, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hk_input) end
      }
   }
end

function punish_d_hk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) and not inputs.is_playing_input_sequence(player) then
      if player.other.has_just_been_blocked then return true, {score = 0, should_end = true} end
      if player.has_just_hit then return true, {score = -1, should_end = true} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function punish_d_hk:is_valid(player, stage, predicted_state)
   if player.other.is_being_thrown then return true end
   local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
   if get_frame_advantage(player) > d_hk_hit_frame + 1 then
      return dist - utils.get_box_connection_distance(player, d_hk_hitboxes, player.other, player.other.boxes) <=
                 d_hk_range - attack_range_tolerance
   end
   return false
end

local punish_hp_loop = Followup:new("punish_hp_loop", Action_Type.PUNISH)
function punish_hp_loop:setup(player, stage, actions, i_actions)
   self.hit_count = 0
   self.walked_frames = 0
   self.min_walk_frames = 3
   self.max_walk_frames = 6
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist - character_specific[player.other.char_str].pushbox_width / 2 <= 52 and player.animation_frame_data and
       player.animation_frame_data.name and player.animation_frame_data.name == "d_LK_geneijin" then
      return {
         {
            condition = function() return player.animation_frame >= geneijin_cancel_frame["d_LK_geneijin"] end,
            action = function() queue_input_sequence_and_wait(player, d_lk_input) end
         }
      }
   else
      return {
         {
            condition = function() return is_idle_timing(player, #far_hp_input, true) end,
            action = function() queue_input_sequence_and_wait(player, far_hp_input) end
         }
      }
   end
end

function punish_hp_loop:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.action == 2 then self.walked_frames = self.walked_frames + 1 end
      local should_walk = self.walked_frames < self.min_walk_frames
      if should_walk then
         inputs.queue_input_sequence(player, walk_forward_input)
      elseif player.is_idle then
         if self.hit_count >= 5 then
            inputs.queue_input_sequence(player, f_hp_input, 0, true)
         else
            local dist = math.abs(player.other.pos_x - player.pos_x) + 48
            if dist - utils.get_box_connection_distance(player, far_mp_hitboxes, player.other, player.other.boxes) <=
                far_mp_range then
               inputs.queue_input_sequence(player, far_hp_input, 0, true)
            else
               inputs.queue_input_sequence(player, kara_hp_input, 0, true)
            end
         end
         self.walked_frames = 0
      end

      if player.has_just_hit then
         self.hit_count = self.hit_count + 1
         if self.hit_count >= 6 then return true, {score = -1, should_end = true} end
      end
      if player.has_just_missed then return true, {score = 0, should_end = true} end
      if player.other.has_just_blocked then return true, {score = 0, should_end = true} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function punish_hp_loop:is_valid(player, stage, predicted_state)
   if player.other.is_being_thrown then return true end
   local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
   if get_frame_advantage(player) > far_hp_hit_frame + 1 then
      local min_dist = dist - character_specific[player.other.char_str].pushbox_width / 2 >= 46
      return min_dist and
                 (dist - utils.get_box_connection_distance(player, far_hp_hitboxes, player.other, player.other.boxes) <=
                     far_hp_range - attack_range_tolerance)
   end
   return false
end

local punishes = {{action = punish_d_hk, weight = 1}, {action = punish_hp_loop, weight = 0.03}}

local followup_punish = Followup:new("followup_punish", Action_Type.PUNISH)

function followup_punish:setup(player, stage, actions, i_actions)
   self.punish = nil
   self.is_valid_punish = true
   self.has_hit = player.combo >= 1
   local frames_prediction = math.max(player.recovery_time, 1)
   local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                              frames_prediction)

   local valid_punishes = {}
   for _, punish in pairs(punishes) do
      if punish.action:is_valid(player, stage, predicted_state) then table.insert(valid_punishes, punish) end
   end
   self.punish = tools.select_weighted(valid_punishes)
   if self.punish then return self.punish.action:setup(player, stage, actions, i_actions) end
   self.is_valid_punish = false
   return {{condition = nil, action = nil}}
end

function followup_punish:run(player, stage, actions, i_actions)
   if not self.punish then return true, {score = 0, should_end = true} end
   if self.punish.action.run then return self.punish.action:run(player, stage, actions, i_actions) end
   if all_commands_complete(player) and not inputs.is_playing_input_sequence(player) then
      if player.other.has_just_been_blocked then return true, {score = 0, should_end = true} end
      if self.is_valid_punish then return true, {score = -1, should_end = true} end
      if self.has_hit then return true, {score = -1, should_end = true} end
      return true, {score = 0, should_end = true}
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

local followup_d_lk = Followup:new("followup_d_lk", Action_Type.ATTACK)

function followup_d_lk:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            else
               return is_idle_timing(player, #d_lk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input, nil, true) end
      }
   }
end

function followup_d_lk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.other.has_just_blocked then return true, {score = 0} end
      if player.has_just_hit then
         last_hit_frame = gamestate.frame_number
         if player.combo <= 1 then return true, {score = 0} end
         return true, {should_punish = true}
      end
      if player.has_just_missed then return true, {score = 0} end
      if player.other.has_just_parried then return true, {score = -1, should_reselect = true} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_d_lk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist - utils.get_box_connection_distance(player, d_lk_hitboxes, player.other, player.other.boxes) <=
              d_lk_range - attack_range_tolerance
end

local followup_mp_d_lk = Followup:new("followup_mp_d_lk", Action_Type.ATTACK)

function followup_mp_d_lk:setup(player, stage, actions, i_actions)
   self.connection_count = 0
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            else
               return is_idle_timing(player, #cl_mp_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, far_mp_input, nil, true) end
      }
   }
end

function followup_mp_d_lk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_connected then
         self.connection_count = self.connection_count + 1
         if self.connection_count == 1 then queue_input_sequence_and_wait(player, d_lk_input, nil, true) end
      end
      if player.has_just_hit then last_hit_frame = gamestate.frame_number end
      if self.connection_count == 2 then
         if player.other.has_just_blocked then return true, {score = 0} end
         if player.has_just_hit then
            if player.combo >= 2 then return true, {should_punish = true} end
            return true, {score = 0}
         end
      end
   end
   if player.has_just_hit and player.other.is_airborne then return true, {score = -1, should_end = true} end
   if player.has_just_missed then return true, {score = 0} end
   if player.other.has_just_parried and self.connection_count == 2 then
      return true, {score = -1, should_reselect = true}
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_mp_d_lk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist - utils.get_box_connection_distance(player, far_mp_hitboxes, player.other, player.other.boxes) <=
              far_mp_range - 32 - attack_range_tolerance
end

local followup_crab_walk = Followup:new("followup_crab_walk", Action_Type.WALK_FORWARD)

function followup_crab_walk:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function() return is_idle_timing(player, #lk_input, true) end,
         action = function() queue_input_sequence_and_wait(player, lk_input, nil, true) end
      }
   }
end

function followup_crab_walk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      local seq = {{"forward"}, {"forward"}}
      if self:should_execute(player, stage, actions, i_actions) then
         if player.animation_frame_data and player.animation_frame_data.name then
            if player.animation_frame_data.name == "LK_geneijin" then
               if player.animation_frame >= geneijin_cancel_frame["LK_geneijin"] then
                  table.insert(seq[1], "MP")
               end
            elseif player.animation_frame_data.name == "MP_geneijin" then
               if player.animation_frame >= geneijin_cancel_frame["MP_geneijin"] then
                  table.insert(seq[1], "LK")
               end
            end
         end
         inputs.queue_input_sequence(player, seq, nil, true)
         -- if player.has_just_hit then return true, {should_punish = true} end
      else
         return true, {score = 0}
      end
      if player.has_just_hit and player.other.is_airborne then return true, {score = -1, should_end = true} end
      if player.other.has_just_blocked then return true, {score = 0} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_crab_walk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if (player.other.is_waking_up or player.other.is_airborne) and dist >= framedata.get_contact_distance(player) + 2 then
      return true
   end
   if player.animation_frame_data and player.animation_frame_data.name then
      if player.animation_frame_data.name == "LK_geneijin" then
         return dist - utils.get_box_connection_distance(player, far_mp_hitboxes, player.other, player.other.boxes) >
                    far_mp_range + 1
      elseif player.animation_frame_data.name == "MP_geneijin" then
         return dist - utils.get_box_connection_distance(player, lk_hitboxes, player.other, player.other.boxes) >
                    d_lk_range + 1
      end
   end
   return dist - utils.get_box_connection_distance(player, lk_hitboxes, player.other, player.other.boxes) > lk_range + 1
end

local followup_zenpou = Followup:new("followup_zenpou", Action_Type.THROW)

function followup_zenpou:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then return false end
            if player.other.throw_invulnerability_cooldown > 0 then
               return is_throw_vulnerable_timing(player.other, zenpou_hit_frame + #zenpou_input, true)
            else
               return is_idle_timing(player, #zenpou_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, zenpou_input, nil, true) end
      }
   }
end

function followup_zenpou:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_hit then return true, {should_punish = true} end
      if player.has_just_missed or player.other.has_just_blocked then
         if player.animation_frame_data and player.animation_frame_data.name and player.animation_frame_data.name ==
             "zenpou_geneijin" then return true, {score = 3, should_end = true} end
         return true, {score = 0, should_end = true}
      end
   end
   if player.has_just_blocked then return true, {should_block = true} end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_zenpou:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist - character_specific[player.other.char_str].pushbox_width / 2 <= zenpou_range +
              crouching_throw_box_extension - throw_range_tolerance
end

local followup_pause = Followup:new("followup_pause", Action_Type.ATTACK)

function followup_pause:setup(player, stage, actions, i_actions)
   self.timer = Delay:new(12)
   return {
      {
         condition = function() return player.action == 0 or player.action == 11 end,
         action = function() self.timer:begin() end
      }
   }
end

function followup_pause:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then if self.timer:is_complete() then return true, {score = 0} end end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_pause:should_execute(player, stage, actions, i_actions)
   if player.other.has_just_blocked or player.other.is_blocking then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      return dist <= framedata.get_contact_distance(player) + 2
   end
end

local followup_block = Followup:new("followup_block", Action_Type.BLOCK)

function followup_block:setup(player, stage, actions, i_actions)
   self.blocked_frames = 0
   self.block_time = 8
   self.block_input = block_low_input
   self.switch_blocking = nil
   self.has_blocked = false
   self.has_parried = false
   self.has_hit = false
   self.next_action = actions[i_actions + 1]
   if self.next_action and self.next_action.block_condition then
      if self.next_action:should_execute(player, stage, actions, i_actions + 1) then
         self.next_action:setup(player, stage, actions, i_actions + 1)
      else
         self.should_reselect = true
      end
   end
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, 1)
            elseif player.character_state_byte == 1 then
               return true
            else
               return is_idle_timing(player, 1)
            end
         end,
         action = function()
            inputs.queue_input_sequence(player, self.block_input)
            self.blocked_frames = self.blocked_frames + 1
            self.block_time = self.block_time + player.other.recovery_time + player.other.remaining_wakeup_time
         end
      }
   }
end

function followup_block:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_blocked or player.is_blocking then
         self.has_blocked = true
         self.block_time = self.blocked_frames
      end
      if player.has_just_parried then
         self.has_parried = true
         self.block_time = self.blocked_frames
      end
      if player.other.has_just_attacked or player.has_just_blocked then
         local hit_type = 1
         local fdata_meta = fdm.frame_data_meta[player.other.char_str][player.other.animation]
         if fdata_meta and fdata_meta.hit_type then
            hit_type = fdata_meta.hit_type[player.other.current_hit_id + 1]
            if hit_type == 2 or hit_type == 4 then
               local startup = framedata.get_next_hit_frame(player.other.char_str, player.other.animation,
                                                            player.other.current_hit_id)
               if startup >= reaction_time then
                  if hit_type == 4 then
                     self.switch_blocking = {
                        start_frame = gamestate.frame_number + startup - 1,
                        input = block_high_input
                     }
                  else
                     self.block_input = {start_frame = gamestate.frame_number + startup - 1, input = block_low_input}
                  end
               end
            end
         end
      end

      if self.switch_blocking and gamestate.frame_number >= self.switch_blocking.start_frame then
         self.block_input = self.switch_blocking.input
         self.switch_blocking = nil
      end

      if player.has_just_hit then self.has_hit = true end
      self.next_action = actions[i_actions + 1]
      if self.next_action and self.next_action.block_condition and self.next_action:block_condition(player, self) then
         return true, {score = 0}
      end
      if self.blocked_frames < self.block_time then
         self:extend(player)
      else
         if self:should_block(player) then
            self:extend(player)
         else
            if player.other.is_jumping then
               return true, {score = 0}
            elseif player.other.is_airborne and player.other.is_flying_down_flag == 1 then
               return true, {score = -1, should_end = true}
            elseif self.has_parried or self.has_hit then
               return true, {should_punish = true}
            elseif self.has_blocked and not player.other.is_airborne and player.remaining_freeze_frames == 0 then
               local recovery_time = player.recovery_time + player.additional_recovery_time + 1
               local opponent_recovery_time = prediction.get_frames_until_idle(player.other, nil, nil, 100)
               if opponent_recovery_time - recovery_time >= block_punish_threshold then
                  return true, {should_punish = true}
               else
                  return true, {score = 0, should_end = true}
               end
            else
               return true, {score = 0}
            end
         end
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_block:should_block(player)
   if player.other.superfreeze_decount > 0 then
      self.block_time = self.blocked_frames + 10
      return true
   end
   if player.other.just_cancelled_into_attack then
      self.block_time = self.blocked_frames + 10
      return true
   end
   if player.has_just_blocked then
      self.block_time = self.blocked_frames + 5
      return true
   end
   if player.freeze_just_ended then
      self.block_time = self.blocked_frames + 2
      return true
   end
   if player.is_waking_up or (player.other.is_attacking and player.other.current_hit_id < player.other.max_hit_id) or
       (player.character_state_byte == 1 and player.remaining_freeze_frames > 0) then return true end
   return false
end

function followup_block:extend(player)
   self.blocked_frames = self.blocked_frames + 1
   inputs.queue_input_sequence(player, self.block_input, 0, true)
end

local followup_walk_in = Followup:new("followup_walk_in", Action_Type.WALK_FORWARD)

function followup_walk_in:setup(player, stage, actions, i_actions)
   self.min_walk_frames = 7
   self.max_walk_frames = self.min_walk_frames
   self.walked_frames = 0
   self.started_outside_throw_range = false
   self.previous_action = actions[i_actions - 2]

   if not utils.is_in_opponent_throw_range(player, -2) then
      self.max_walk_frames = self.max_walk_frames + math.random(5, 7)
      self.started_outside_throw_range = true
   else
      local dist = math.abs(player.other.pos_x - player.pos_x)
      if dist <= framedata.get_contact_distance(player) + 6 then
         if math.random(0, 1) < 0.3 then
            self.min_walk_frames = math.random(4, 6)
            self.max_walk_frames = self.min_walk_frames
         end
      else
         self.max_walk_frames = 10
      end
   end
   if player.combo >= 1 and self.previous_action and self.previous_action == followup_pause then
      self.min_walk_frames = 4
      self.max_walk_frames = self.min_walk_frames
   end
   if has_hit_recently() then if math.random(0, 1) < 0.7 then self.max_walk_frames = self.min_walk_frames end end
   local setup = {
      {condition = nil, action = function() inputs.queue_input_sequence(player, walk_forward_input, 0, true) end}
   }
   return setup
end

function followup_walk_in:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.other.is_waking_up then
         local dist = math.abs(player.other.pos_x - player.pos_x)
         if dist >= framedata.get_contact_distance(player) + 2 then
            self:extend(player)
         else
            return true, {score = 0}
         end
      else
         if self.started_outside_throw_range and utils.is_in_opponent_throw_range(player, -2) then
            self.max_walk_frames = 10 + math.random(0, 3)
         end
         if self.walked_frames < self.min_walk_frames or self.walked_frames < self.max_walk_frames then
            self:extend(player)
         else
            return true, {score = 0}
         end
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_walk_in:extend(player)
   if player.action == 2 then self.walked_frames = self.walked_frames + 1 end
   inputs.queue_input_sequence(player, walk_forward_input, 0, true)
end

function followup_walk_in:label() return {self.name, " ", self.walked_frames, "hud_f"} end

local attacks = {{action = followup_d_lk, default_weight = 1}}

local walk_in = {action = followup_walk_in, default_weight = 1, active = true}
local crab_walk = {action = followup_crab_walk, default_weight = 1}
local pause = {action = followup_pause, default_weight = 1, active = false}
local block = {action = followup_block, default_weight = 1}
local punish = {action = followup_punish, default_weight = 1}

local moves = {
   {action = followup_d_lk, default_weight = 1}, {action = followup_mp_d_lk, default_weight = 1},
   {action = followup_zenpou, default_weight = 1}, crab_walk
}

local move_names = {}
for i, move in ipairs(moves) do table.insert(move_names, move.action.name) end

local function create_settings()
   local data = {match_savestate_player = "", match_savestate_dummy = "yun", score = 0, moves = {}}
   for i, move in ipairs(moves) do table.insert(data.moves, true) end
   return data
end

local function get_menu_move_names() return move_names end
local function get_moves() return moves end
local function get_attack() return attacks[math.random(1, #attacks)] end
local function get_geneijin_input() return geneijin_input end

local function reset_weights()
   for _, setup in ipairs(moves) do setup.weight = setup.default_weight end
   walk_in.weight = walk_in.default_weight
end

return {
   init = init,
   get_menu_move_names = get_menu_move_names,
   get_moves = get_moves,
   get_attack = get_attack,
   get_geneijin_input = get_geneijin_input,
   reset_weights = reset_weights,
   create_settings = create_settings,
   walk_in = walk_in,
   crab_walk = crab_walk,
   pause = pause,
   block = block,
   punish = punish
}
