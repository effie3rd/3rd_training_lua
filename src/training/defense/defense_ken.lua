local frame_data = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local move_data = require("src.modules.move_data")
local stage_data = require("src.modules.stage_data")
local inputs = require("src.control.inputs")
local advanced_control = require("src.control.advanced_control")
local defense_classes = require("src.training.defense.defense_classes")
local prediction = require("src.modules.prediction")
local tools = require("src.tools")
local utils = require("src.modules.utils")

local Delay = advanced_control.Delay
local Setup, Followup, Action_Type, Setup_Type = defense_classes.Setup, defense_classes.Followup,
                                                 defense_classes.Action_Type, defense_classes.Setup_Type
local is_idle_timing, is_wakeup_timing, is_landing_timing = advanced_control.is_idle_timing,
                                                            advanced_control.is_wakeup_timing,
                                                            advanced_control.is_landing_timing
local is_throw_vulnerable_timing = advanced_control.is_throw_vulnerable_timing
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete
local character_specific = frame_data.character_specific

local jump_forward_input
local jump_mk_input
local block_high_input
local block_low_input
local block_low_long_input

local walk_forward_input
local walk_back_input
local forward_dash_input
local forward_dash_duration
local back_dash_input
local back_dash_duration

local d_lk_input
local d_lk_hit_frame

local cl_mp_input
local cl_mp_hit_frame

local d_mp_input
local d_mp_hit_frame
local d_mk_input
local d_mk_hit_frame
local hk_input
local hk_hit_frame

local b_mk_input
local b_mk_hit_frame

local lp_shoryu_input
local lp_shoryu_hit_frame

local shippu_input
local shippu_hit_frame

local kara_throw_input
local b_mk_kara_dist

local throw_input
local throw_hit_frame
local throw_range
local throw_threshold = 1
local b_mk_kara_throw_range

local parry_frames = 10
local punish_delta = 3
local throw_break_tolerance = -2
local recovery_gap = 1
local throw_walk_frames = 6
local throw_min_block_frames = 10
local block_punish_threshold = 4
local reaction_time = 12
local connection_end_delay = Delay:new(1)
local knockdown = move_data.get_move_inputs_by_name("ken", "shoryuken", "LP")

local d_mk_lp_shoryu_max_range = 85

local function init()
   jump_forward_input = {{"up", "forward"}, {"up", "forward"}}
   jump_mk_input = {{"MK"}}
   block_high_input = {{"back"}, {"back"}}
   block_low_input = {{"back", "down"}, {"back", "down"}}

   walk_forward_input = {{"forward"}}
   walk_back_input = {{"back"}}
   block_low_long_input = {}
   for i = 1, 16 do table.insert(block_low_long_input, {"down", "back"}) end
   forward_dash_input = {{"forward"}, {}, {"forward"}}
   forward_dash_duration = frame_data.get_first_idle_frame_by_name("ken", "dash_forward")
   back_dash_input = {{"back"}, {}, {"back"}}
   back_dash_duration = frame_data.get_first_idle_frame_by_name("ken", "dash_back")

   d_lk_input = {{"down", "LK"}}
   d_lk_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "d_LK")

   cl_mp_input = {{"MP"}}
   cl_mp_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "cl_MP")

   d_mp_input = {{"down", "MP"}}
   d_mp_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "d_MP")
   d_mk_input = {{"down", "MK"}}
   d_mk_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "d_MK")
   hk_input = {{"HK"}}
   hk_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "HK")

   b_mk_input = {{"back", "MK"}}
   b_mk_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "b_MK")

   lp_shoryu_input = move_data.get_move_inputs_by_name("ken", "shoryuken", "LP")
   lp_shoryu_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "shoryuken_LP")

   shippu_input = move_data.get_move_inputs_by_name("ken", "shippu")
   shippu_hit_frame = frame_data.get_first_hit_frame_by_name("ken", "shippu")

   kara_throw_input = {{"back", "MK"}, {"back", "LP", "LK"}}
   b_mk_kara_dist = frame_data.get_kara_distance_by_name("ken", "b_MK")

   throw_input = {{"forward", "LP", "LK"}}
   throw_hit_frame = 2
   throw_range = frame_data.get_hitbox_max_range_by_name("ken", "throw_neutral")
   b_mk_kara_throw_range = throw_range + b_mk_kara_dist
end

local function handle_interruptions(player, stage, actions, i_actions)
   if (player.has_just_been_hit and not player.is_being_thrown) or player.other.has_just_parried then
      print("dummy hit/parried") -- debug
      return true, {score = 2, should_end = true}
   end
   if (player.is_being_thrown and player.throw_tech_countdown <= 0) then
      print("dummy thrown/missed") -- debug
      local score = 1
      local hit_with_command_throw = memory.readbyte(player.other.addresses.hit_with_command_throw) > 0
      local hit_with_super_throw = memory.readbyte(player.other.addresses.hit_with_super_throw) > 0
      if hit_with_command_throw or hit_with_super_throw then score = 2 end
      return true, {score = score, should_end = true}
   end
   if player.has_just_missed then
      if not player.other.is_attacking then
         return true, {score = 1, should_end = true}
      else
         local current_action = actions[i_actions]
         if current_action and current_action.type ~= Action_Type.BLOCK then return true, {should_block = true} end
      end
   end
   return false
end

local far_d_lk_followups
local close_d_lk_followups
local close_mp_followups
local crossup_mk_followups
local wakeup_followups

local block_followups
local walk_in_followups
local walk_out_followups
local back_dash_followups
local forward_dash_followups

local function get_frame_advantage(player)
   local recovery_time = player.recovery_time + player.additional_recovery_time + 1
   local opponent_recovery_time = prediction.get_frames_until_idle(player.other, nil, nil, 80)
   return opponent_recovery_time - recovery_time
end

local punish_d_mk_lp_shoryu = Followup:new("punish_d_mk_lp_shoryu", Action_Type.PUNISH)
function punish_d_mk_lp_shoryu:setup(player, stage, actions, i_actions)
   self.offset = 2
   local lp_shoryu_command = {
      condition = nil,
      action = function()
         self.offset = self.offset + math.max(player.remaining_freeze_frames - #lp_shoryu_input, 0)
         queue_input_sequence_and_wait(player, lp_shoryu_input, self.offset)
      end
   }
   local d_mk_lp_shoryu_command = {
      {
         condition = function() return is_idle_timing(player, #d_mk_input, true) end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }, {condition = function() return player.has_just_hit end, action = nil}, lp_shoryu_command
   }
   if player.animation_frame_data and player.animation_frame_data.name == "d_MK" then
      return {lp_shoryu_command}
   else
      return d_mk_lp_shoryu_command
   end
end

function punish_d_mk_lp_shoryu:is_valid(player, stage, predicted_state)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.has_just_hit then
      if player.animation_frame_data and player.animation_frame_data.name == "d_MK" then
         if player.other.is_crouching and player.other.char_str ~= "yang" then return dist <= 66 end
         return dist <= frame_data.get_contact_distance(player) + 18
      end
   else
      if get_frame_advantage(player) > d_mk_hit_frame + 1 then
         dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
         if player.other.char_str == "yang" or player.other.char_str == "yun" then
            if player.other.is_crouching then return dist <= d_mk_lp_shoryu_max_range - 10 end
            return dist <= d_mk_lp_shoryu_max_range - 5
         end
         return dist <= d_mk_lp_shoryu_max_range
      end
   end
   return false
end

local punish_d_mk_shippu = Followup:new("punish_d_mk_shippu", Action_Type.PUNISH)
function punish_d_mk_shippu:setup(player, stage, actions, i_actions)
   self.offset = 4
   local shippu_command = {
      condition = nil,
      action = function()
         self.offset = self.offset + math.max(player.remaining_freeze_frames - #shippu_input, 0)
         queue_input_sequence_and_wait(player, shippu_input, self.offset)
      end
   }
   local d_mk_shippu_command = {
      {
         condition = function() return is_idle_timing(player, #d_mk_input, true) end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }, {condition = function() return player.has_just_hit end, action = nil}, shippu_command
   }
   if player.animation_frame_data and player.animation_frame_data.name == "d_MK" then
      return {shippu_command}
   else
      return d_mk_shippu_command
   end
end

function punish_d_mk_shippu:is_valid(player, stage, predicted_state)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.has_just_hit then
      if player.animation_frame_data and player.animation_frame_data.name == "d_MK" then
         return dist <= 150 and dist > 70 and (player.other.is_standing or player.other.is_crouching)
      end
   else
      if get_frame_advantage(player) > d_mk_hit_frame + 1 then
         dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
         return dist <= 130
      end
   end
   return false
end

local punish_d_mp_shippu = Followup:new("punish_d_mp_shippu", Action_Type.PUNISH)
function punish_d_mp_shippu:setup(player, stage, actions, i_actions)
   self.offset = 10
   local shippu_command = {
      condition = nil,
      action = function()
         self.offset = self.offset + math.max(player.remaining_freeze_frames - #shippu_input, 0)
         queue_input_sequence_and_wait(player, shippu_input, self.offset)
      end
   }
   local d_mp_shippu_command = {
      {
         condition = function() return is_idle_timing(player, #d_mp_input, true) end,
         action = function() queue_input_sequence_and_wait(player, d_mp_input) end
      }, {condition = function() return player.has_just_hit end, action = nil}, shippu_command
   }
   if player.animation_frame_data and player.animation_frame_data.name == "d_MP" then
      return {shippu_command}
   else
      return d_mp_shippu_command
   end
end

function punish_d_mp_shippu:is_valid(player, stage, predicted_state)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.has_just_hit then
      if player.animation_frame_data and player.animation_frame_data.name == "d_MP" then
         return dist <= 140 and (player.other.is_standing or player.other.is_crouching)
      end
   else
      if get_frame_advantage(player) > d_mp_hit_frame + 1 then
         dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
         return dist <= 95
      end
   end
   return false
end

local punish_d_lk_d_lk_shippu = Followup:new("punish_d_lk_d_lk_shippu", Action_Type.PUNISH)
function punish_d_lk_d_lk_shippu:setup(player, stage, actions, i_actions)
   self.offset = 0
   local shippu_command = {
      condition = nil,
      action = function()
         self.offset = self.offset + math.max(player.remaining_freeze_frames - #shippu_input, 0)
         queue_input_sequence_and_wait(player, shippu_input, self.offset)
      end
   }
   local d_lk_d_lk_shippu_command = {
      {
         condition = function() return is_idle_timing(player, #d_lk_input, true) end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input) end
      }, {condition = function() return player.has_just_hit end, action = nil}, shippu_command
   }
   if player.animation_frame_data and player.animation_frame_data.name == "d_LK" then
      return {shippu_command}
   else
      return d_lk_d_lk_shippu_command
   end
end

function punish_d_lk_d_lk_shippu:is_valid(player, stage, predicted_state)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.has_just_hit then
      if player.animation_frame_data and player.animation_frame_data.name == "d_LK" then return dist <= 150 end
   else
      if get_frame_advantage(player) > d_lk_hit_frame + 1 then
         dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
         return dist <= 70
      end
   end
   return false
end

local punish_mp_hp_shoryu = Followup:new("punish_mp_hp_shoryu", Action_Type.PUNISH)
function punish_mp_hp_shoryu:setup(player, stage, actions, i_actions)
   self.offset = 0
   local lp_shoryu_command = {
      condition = nil,
      action = function()
         self.offset = self.offset + math.max(player.remaining_freeze_frames - #lp_shoryu_input, 0)
         queue_input_sequence_and_wait(player, lp_shoryu_input, self.offset)
      end
   }
   local mp_hp_shoryu_command = {
      {
         condition = function() return is_idle_timing(player, #cl_mp_input, true) end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, {{"HP"}}) end
      }, {condition = function() return player.has_just_hit end, action = nil}, lp_shoryu_command
   }
   if player.animation_frame_data and player.animation_frame_data.name == "tc_1_ext" then
      return {lp_shoryu_command}
   else
      return mp_hp_shoryu_command
   end
end

function punish_mp_hp_shoryu:is_valid(player, stage, predicted_state)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.has_just_hit then
      if player.animation_frame_data and player.animation_frame_data.name == "tc_1_ext" then
         if player.other.is_crouching then return dist <= 50 end
         if player.other.is_crouching and player.other.char_str ~= "yang" then return dist <= 66 end
         return dist <= frame_data.get_contact_distance(player) + 18
      end
   else
      if get_frame_advantage(player) > cl_mp_hit_frame + 1 then
         dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
         if player.other.is_crouching and player.other.char_str ~= "yang" and player.other.char_str ~= "yun" then
            return dist <= 50
         end
         return dist <= 50
      end
   end
   return false
end

local punish_mp_hp_shippu = Followup:new("punish_mp_hp_shippu", Action_Type.PUNISH)
function punish_mp_hp_shippu:setup(player, stage, actions, i_actions)
   self.offset = 0
   local shippu_command = {
      condition = nil,
      action = function()
         self.offset = self.offset + math.max(player.remaining_freeze_frames - #shippu_input, 0)
         queue_input_sequence_and_wait(player, shippu_input, self.offset)
      end
   }
   local mp_hp_shippu_command = {
      {
         condition = function() return is_idle_timing(player, #cl_mp_input, true) end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, {{"HP"}}) end
      }, {condition = function() return player.has_just_hit end, action = nil}, shippu_command
   }
   if player.animation_frame_data and player.animation_frame_data.name == "tc_1_ext" then
      return {shippu_command}
   else
      return mp_hp_shippu_command
   end
end

function punish_mp_hp_shippu:is_valid(player, stage, predicted_state)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.has_just_hit then
      if player.animation_frame_data and player.animation_frame_data.name == "tc_1_ext" then return dist <= 140 end
   else
      if get_frame_advantage(player) > cl_mp_hit_frame + 1 then
         dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
         return dist <= 50
      end
   end
   return false
end

local punish_b_mk_shippu = Followup:new("punish_b_mk_shippu", Action_Type.PUNISH)
function punish_b_mk_shippu:setup(player, stage, actions, i_actions)
   self.offset = 0
   return {
      {
         condition = function() return is_idle_timing(player, #shippu_input) end,
         action = function() queue_input_sequence_and_wait(player, shippu_input, self.offset) end
      }
   }
end

function punish_b_mk_shippu:is_valid(player, stage, predicted_state)
   if player.animation_frame_data and player.animation_frame_data.name == "b_MK" then
      local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                                predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
      return dist <= 150
   end
   return false
end

local punish_far_mp_shippu = Followup:new("punish_far_mp_shippu", Action_Type.PUNISH)
function punish_far_mp_shippu:setup(player, stage, actions, i_actions)
   self.offset = 0
   return {
      {
         condition = function() return is_idle_timing(player, #shippu_input) end,
         action = function() queue_input_sequence_and_wait(player, shippu_input, self.offset) end
      }
   }
end

function punish_far_mp_shippu:is_valid(player, stage, predicted_state)
   if player.animation_frame_data and player.animation_frame_data.name == "MP" then
      local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                                predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
      return dist <= 150 and not player.other.is_airborne
   end
   return false
end

local punish_lp_shoryu = Followup:new("punish_lp_shoryu", Action_Type.PUNISH)
function punish_lp_shoryu:setup(player, stage, actions, i_actions)
   self.offset = 0
   return {
      {
         condition = function() return is_idle_timing(player, #lp_shoryu_input) end,
         action = function() queue_input_sequence_and_wait(player, lp_shoryu_input, self.offset) end
      }
   }
end

function punish_lp_shoryu:is_valid(player, stage, predicted_state)
   if not (player.character_state_byte == 4) then
      local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                                predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
      if get_frame_advantage(player) > lp_shoryu_hit_frame + 1 then return dist <= 85 end
   end
   return false
end

local punish_shippu = Followup:new("punish_shippu", Action_Type.PUNISH)
function punish_shippu:setup(player, stage, actions, i_actions)
   self.offset = 0
   return {
      {
         condition = function() return is_idle_timing(player, #shippu_input) end,
         action = function() queue_input_sequence_and_wait(player, shippu_input, self.offset) end
      }
   }
end

function punish_shippu:is_valid(player, stage, predicted_state)
   if not (player.character_state_byte == 4) then
      local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                                predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
      if get_frame_advantage(player) > shippu_hit_frame + 1 then return dist <= 180 end
   end
   return false
end

local punishes = {
   {action = punish_d_mk_lp_shoryu, weight = 1}, {action = punish_d_mk_shippu, weight = 0.1},
   {action = punish_d_mp_shippu, weight = 0.3}, {action = punish_d_lk_d_lk_shippu, weight = 0.1},
   {action = punish_mp_hp_shoryu, weight = 1}, {action = punish_mp_hp_shippu, weight = 0.1},
   {action = punish_b_mk_shippu, weight = 1}, {action = punish_far_mp_shippu, weight = 1},
   {action = punish_lp_shoryu, weight = 0.5}, {action = punish_shippu, weight = 0.01}
}

local followup_punish = Followup:new("followup_punish", Action_Type.PUNISH)

function followup_punish:setup(player, stage, actions, i_actions)
   self.end_delay = 10
   self.is_valid_punish = true
   self.has_hit = player.combo >= 1
   local frames_prediction = math.max(player.recovery_time, 1)
   local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                              frames_prediction)

   local valid_punishes = {}
   for _, punish in pairs(punishes) do
      if punish.action:is_valid(player, stage, predicted_state) then table.insert(valid_punishes, punish) end
   end
   local selected_punish = tools.select_weighted(valid_punishes)
   if selected_punish then
      print(selected_punish.action.name)
      return selected_punish.action:setup(player, stage, actions, i_actions)
   end
   self.is_valid_punish = false
   return {{condition = nil, action = nil}}
end

function followup_punish:run(player, stage, actions, i_actions)
   if all_commands_complete(player) and not inputs.is_playing_input_sequence(player) then
      self.end_delay = self.end_delay - 1
      if player.other.has_just_been_blocked then return true, {score = 1} end
      if self.end_delay <= 0 then
         if self.is_valid_punish then return true, {score = -3} end
         if self.has_hit then return true, {score = -1} end
         return true, {score = 0}
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

local followup_close_d_lk = Followup:new("followup_close_d_lk", Action_Type.ATTACK)
function followup_close_d_lk:setup(player, stage, actions, i_actions)
   self.end_delay = 1
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            else
               return is_idle_timing(player, #d_lk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input) end
      }
   }
end

function followup_close_d_lk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if self.end_delay <= 0 then return true, {score = 0} end
      if player.has_just_connected then self.end_delay = self.end_delay - 1 end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_close_d_lk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= 80
end

function followup_close_d_lk:followups() return close_d_lk_followups end

local followup_close_mp = Followup:new("followup_close_mp", Action_Type.ATTACK)

function followup_close_mp:setup(player, stage, actions, i_actions)
   self.end_delay = 1
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            else
               return is_idle_timing(player, #cl_mp_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }
   }
end

function followup_close_mp:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if self.end_delay <= 0 then return true, {score = 0} end
      if player.has_just_connected then self.end_delay = self.end_delay - 1 end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_close_mp:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= 80
end

function followup_close_mp:followups() return close_mp_followups end

local followup_far_mp = Followup:new("followup_far_mp", Action_Type.ATTACK)

function followup_far_mp:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            else
               return is_idle_timing(player, #cl_mp_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }
   }
end

function followup_far_mp:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_hit then
         return true, {should_punish = true}
      elseif player.other.has_just_blocked then
         return true, {score = 1}
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_far_mp:is_valid(player, stage, actions, i_actions)
   return character_specific[player.other.char_str].height.crouching.min >= 64
end

function followup_far_mp:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
      local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                                 player.other.remaining_freeze_frames + 10)
      dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                          predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
   end
   return dist >= frame_data.get_contact_distance(player) + 25 and dist <= frame_data.get_contact_distance(player) + 40
end

local followup_b_mk = Followup:new("followup_b_mk", Action_Type.ATTACK)

function followup_b_mk:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #b_mk_input + b_mk_hit_frame - 6, true)
            else
               return is_idle_timing(player, #b_mk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, b_mk_input) end
      }
   }
end

function followup_b_mk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_hit then
         if player.current_hit_id == 2 then
            if player.other.is_crouching then
               return true, {should_punish = true}
            else
               return true, {score = -1}
            end
         end
      end
      if player.current_hit_id == 2 then
         if player.other.has_just_blocked then return true, {score = 1} end
         if player.other.has_just_parried then return true, {score = 2} end
      end
   end
   if (player.is_being_thrown and player.throw_tech_countdown <= 0) or
       (player.has_just_missed and player.current_hit_id >= 2) then
      return true, {score = 1, should_end = true}
   elseif player.has_just_been_hit then
      return true, {score = 2, should_end = true}
   end
   return false
end

function followup_b_mk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= 80
end

local followup_block = Followup:new("followup_block", Action_Type.BLOCK)

function followup_block:setup(player, stage, actions, i_actions)
   self.blocked_frames = 0
   self.block_time = 8
   self.block_input = block_low_input
   self.has_blocked = false
   self.has_parried = false
   self.should_reselect = false
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
   if self.should_reselect then
      self.should_reselect = false
      return true, {should_reselect = true}
   end
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
            hit_type = fdata_meta.hit_type[player.other.current_hit_id]
            if hit_type == 4 then
               if frame_data.get_next_hit_frame(player.other.char_str, player.other.animation,
                                                player.other.current_hit_id) >= reaction_time then
                  self.block_input = block_high_input
               end
            end
         end
      end

      self.next_action = actions[i_actions + 1]
      if self.next_action and self.next_action.block_condition and self.next_action:block_condition(player, self) then
         return true, {score = 0}
      end
      -- print(self.blocked_frames, self.block_time, self.has_blocked, self:should_block(player)) -- debug
      if self.blocked_frames < self.block_time then
         self:extend(player)
      else
         if self:should_block(player) then
            self:extend(player)
         else
            if player.other.is_jumping then
               return true, {score = 1}
            elseif player.other.is_airborne and player.other.is_flying_down_flag == 1 then
               return true, {score = -3, should_end = true}
            elseif self.has_parried then
               return true, {should_punish = true}
            elseif self.has_blocked and not player.other.is_airborne then
               local recovery_time = player.recovery_time + player.additional_recovery_time + 1
               local opponent_recovery_time = prediction.get_frames_until_idle(player.other, nil, nil, 100)
               if opponent_recovery_time - recovery_time >= block_punish_threshold then
                  return true, {should_punish = true}
               end
            else
               return true, {score = 1}
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
   if (player.other.is_attacking and player.other.current_hit_id < player.other.max_hit_id) or
       (player.character_state_byte == 1 and player.remaining_freeze_frames > 0) then return true end
   return false
end

function followup_block:extend(player)
   self.blocked_frames = self.blocked_frames + 1
   inputs.queue_input_sequence(player, self.block_input)
end

function followup_block:label() return {self.name, " ", self.blocked_frames, "hud_f"} end

function followup_block:followups() return block_followups end

local followup_mp_hp = Followup:new("followup_mp_hp", Action_Type.ATTACK)

function followup_mp_hp:setup(player, stage, actions, i_actions)
   self.connection_count = 0
   self.min_walk_frames = 4
   self.max_walk_frames = 14
   self.attack_range = frame_data.get_contact_distance(player) + 20
   self.attack_range_reduction = 5
   if player.other.char_str == "yang" or player.other.char_str == "yun" then
      self.attack_range = self.attack_range - 4
      self.attack_range_reduction = 0
   end
   if not utils.is_in_opponent_throw_range(player) then self.min_walk_frames = 6 end
   self.previous_action = actions[i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player.other, cl_mp_hit_frame + #cl_mp_input - recovery_gap, true)
            elseif player.other.throw_invulnerability_cooldown > 0 then
               return is_throw_vulnerable_timing(player.other, cl_mp_hit_frame + #cl_mp_input + throw_break_tolerance,
                                                 true)
            elseif player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or
                player.other.recovery_time > 0 then
               if player.other.recovery_time > 0 then
                  return is_idle_timing(player.other, cl_mp_hit_frame + #cl_mp_input + throw_break_tolerance, true)
               end
            else
               return is_idle_timing(player, #cl_mp_input, true)
            end
            return false
         end,
         action = function()
            self.should_walk_in = false
            queue_input_sequence_and_wait(player, cl_mp_input)
         end
      }
   }
end

function followup_mp_hp:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_connected then
         self.connection_count = self.connection_count + 1
         if self.connection_count == 1 then
            if player.animation_frame_data then
               if player.animation_frame_data.name == "cl_MP" then
                  inputs.queue_input_sequence(player, {{"HP"}})
               end
            elseif player.animation_frame_data.name == "MP" then
               if player.has_just_hit then
                  return true, {should_punish = true}
               else
                  return true, {score = 1}
               end
            end
         end
      end
      if player.has_just_hit and self.connection_count == 2 then
         if player.combo == 2 then
            return true, {should_punish = true}
         else
            return true, {score = -1}
         end
      end
      if player.other.has_just_blocked and self.connection_count == 2 then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_mp_hp:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local attack_range = self.attack_range
   if player.other.is_crouching then attack_range = attack_range - self.attack_range_reduction end
   if dist <= attack_range then return true end
   return false
end

function followup_mp_hp:should_execute(player, stage, actions, i_actions)
   local previous_action = actions[i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= frame_data.get_contact_distance(player) + 20
end

local followup_d_lk_d_lk = Followup:new("followup_d_lk_d_lk", Action_Type.ATTACK)

function followup_d_lk_d_lk:setup(player, stage, actions, i_actions)
   self.connection_count = 0
   self.min_walk_frames = 4
   self.max_walk_frames = 14
   self.attack_range_reduction = 0
   self.attack_range = frame_data.get_contact_distance(player) + 32
   if not utils.is_in_opponent_throw_range(player) then self.min_walk_frames = 6 end
   self.previous_action = actions[i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player.other, d_lk_hit_frame + #d_lk_input - recovery_gap, true)
            elseif player.other.throw_invulnerability_cooldown > 0 then
               return is_throw_vulnerable_timing(player.other, d_lk_hit_frame + #d_lk_input + throw_break_tolerance,
                                                 true)
            elseif player.other.remaining_freeze_frames > 0 or player.other.recovery_time > 0 then
               if player.other.recovery_time > 0 then
                  return is_idle_timing(player.other, d_lk_hit_frame + #d_lk_input + throw_break_tolerance, true)
               end
            else
               return is_idle_timing(player, #d_lk_input, true)
            end
            return false
         end,
         action = function()
            self.should_walk_in = false
            queue_input_sequence_and_wait(player, d_lk_input)
         end
      }
   }
end

function followup_d_lk_d_lk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_connected then
         self.connection_count = self.connection_count + 1
         if self.connection_count == 1 then inputs.queue_input_sequence(player, d_lk_input) end
      end
      if player.has_just_hit and self.connection_count == 2 then
         if player.combo == 2 then
            return true, {should_punish = true}
         else
            return true, {score = 0}
         end
      end
      if (player.other.has_just_blocked and self.connection_count == 2) then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_d_lk_d_lk:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local attack_range = self.attack_range
   if player.other.is_crouching then attack_range = attack_range - self.attack_range_reduction end
   if dist <= attack_range then return true end
   return false
end

function followup_d_lk_d_lk:should_execute(player, stage, actions, i_actions)
   local previous_action = actions[i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= frame_data.get_contact_distance(player) + 32
end

local followup_d_mp = Followup:new("followup_d_mp", Action_Type.ATTACK)

function followup_d_mp:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_mp_input + d_mp_hit_frame + 1, true)
            else
               return is_idle_timing(player, #d_mp_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, d_mp_input) end
      }
   }
end

function followup_d_mp:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_hit then return true, {should_punish = true} end
      if player.other.has_just_blocked then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_d_mp:is_valid(player, stage, actions)
   if actions[#actions].type == Action_Type.BLOCK and utils.is_in_opponent_throw_range(player) then return false end
   return true
end

local followup_d_mk = Followup:new("followup_d_mk", Action_Type.ATTACK)

function followup_d_mk:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_mk_input + d_mk_hit_frame + 1, true)
            else
               return is_idle_timing(player, #d_mk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }
   }
end

function followup_d_mk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_hit then return true, {should_punish = true} end
      if player.other.has_just_blocked then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_d_mk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= 135
end

local followup_hk = Followup:new("followup_hk", Action_Type.ATTACK)

function followup_hk:setup(player, stage, actions, i_actions)
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #hk_input + hk_hit_frame + 1, true)
            else
               return is_idle_timing(player, #hk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, hk_input) end
      }
   }
end

function followup_hk:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_hit then return true, {score = -1} end
      if player.other.has_just_blocked then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_hk:should_execute(player, stage, actions, i_actions)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= 135
end

local followup_throw = Followup:new("followup_throw", Action_Type.THROW)

function followup_throw:setup(player, stage, actions, i_actions)
   self.should_walk_in = false
   self.max_walk_frames = throw_walk_frames
   self.opponent_has_been_thrown = false
   self.end_delay = 12
   local previous_action = actions[i_actions - 1]
   if previous_action then
      if not (previous_action.type == Action_Type.WALK_FORWARD) then
         local dist = self.predicted_dist or math.abs(player.other.pos_x - player.pos_x)
         if throw_range - throw_threshold < dist - character_specific[player.other.char_str].pushbox_width / 2 then
            self.should_walk_in = true
         end
      end
      if previous_action.type == Action_Type.BLOCK then previous_action.block_time = throw_min_block_frames end
   end
   return {
      {
         condition = function()
            if is_idle_timing(player, #throw_input, true) and player.other.standing_state > 0 and
                is_throw_vulnerable_timing(player.other, #throw_input + throw_hit_frame + 1, true) then
               return true
            end
            return false
         end,
         action = function() queue_input_sequence_and_wait(player, throw_input) end
      }
   }
end

function followup_throw:run(player, stage, actions, i_actions)
   if self.should_walk_in then return true, {should_walk_in = true} end
   if all_commands_complete(player) then
      if player.is_in_throw_tech or player.other.is_in_throw_tech then return true, {score = 1} end
      if self.opponent_has_been_thrown then
         self.end_delay = self.end_delay - 1
         if self.end_delay <= 0 then return true, {score = -1} end
      end
      if player.other.has_just_been_thrown then self.opponent_has_been_thrown = true end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_throw:block_condition(player, block_followup)
   if block_followup.has_blocked then return false end
   if block_followup.blocked_frames >= block_followup.block_time then return true end
   return false
end

function followup_throw:walk_in_condition(player, walk_followup)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if throw_range - throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 or
       walk_followup.walked_frames >= self.max_walk_frames then return true end
   return false
end

function followup_throw:should_execute(player, stage, actions, i_actions)
   self.predicted_dist = nil
   local previous_action = actions[i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
      local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                                 player.other.remaining_freeze_frames + 10)
      dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                          predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
      self.predicted_dist = dist
   end
   local crouching_delay = 0
   if player.is_crouching then crouching_delay = 1 end
   local walk_dist = utils.get_forward_walk_distance(player, throw_walk_frames - crouching_delay)
   return throw_range - throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 -
              walk_dist
end

local followup_kara_throw = Followup:new("followup_kara_throw", Action_Type.THROW)

function followup_kara_throw:setup(player, stage, actions, i_actions)
   self.should_walk_in = false
   self.max_walk_frames = throw_walk_frames
   self.opponent_has_been_thrown = false
   self.end_delay = 12
   local previous_action = actions[i_actions - 1]
   if previous_action then
      if not (previous_action.type == Action_Type.WALK_FORWARD) then
         local dist = self.predicted_dist or math.abs(player.other.pos_x - player.pos_x)
         if b_mk_kara_throw_range - throw_threshold < dist - character_specific[player.other.char_str].pushbox_width / 2 then
            self.should_walk_in = true
         end
      end
      if previous_action.type == Action_Type.BLOCK then previous_action.block_time = throw_min_block_frames end
   end
   return {
      {
         condition = function()
            if is_idle_timing(player, 1, true) and player.other.standing_state > 0 and
                is_throw_vulnerable_timing(player.other, #kara_throw_input + throw_hit_frame + 1, true) then
               return true
            end
            return false
         end,
         action = function() queue_input_sequence_and_wait(player, kara_throw_input) end
      }
   }
end

function followup_kara_throw:run(player, stage, actions, i_actions)
   if self.should_walk_in then return true, {should_walk_in = true} end
   if all_commands_complete(player) then
      if player.is_in_throw_tech or player.other.is_in_throw_tech then return true, {score = 1} end
      if self.opponent_has_been_thrown then
         self.end_delay = self.end_delay - 1
         if self.end_delay <= 0 then return true, {score = -1} end
      end
      if player.other.has_just_been_thrown then self.opponent_has_been_thrown = true end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_kara_throw:block_condition(block_followup)
   if block_followup.has_blocked then return false end
   if block_followup.blocked_frames >= block_followup.block_time then return true end
   return false
end

function followup_kara_throw:walk_in_condition(player, walk_followup)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if b_mk_kara_throw_range - throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 or
       walk_followup.walked_frames >= self.max_walk_frames then return true end
   return false
end

function followup_kara_throw:should_execute(player, stage, actions, i_actions)
   self.predicted_dist = nil
   local previous_action = actions[i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
      local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                                 player.other.remaining_freeze_frames + 10)
      dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                          predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
      self.predicted_dist = dist
   end
   local crouching_delay = 0
   if player.is_crouching then crouching_delay = 1 end
   local walk_dist = utils.get_forward_walk_distance(player, throw_walk_frames - crouching_delay)
   return throw_range - throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 -
              walk_dist
end

local followup_forward_down = Followup:new("followup_forward_down", Action_Type.PARRY)

function followup_forward_down:setup(player, stage, actions, i_actions)
   self.parry_duration = Delay:new(parry_frames)
   self.parry_offset = 0
   self.has_parried = false
   return {
      {
         condition = function()
            if not player.is_attacking then
               if player.other.character_state_byte == 1 then
                  if player.other.remaining_freeze_frames > 0 or player.other.recovery_time > 0 then
                     if player.other.recovery_time > 0 then
                        self.parry_offset = player.other.recovery_time + 2
                        return true
                     end
                  end
                  return false
               else
                  self.parry_offset = 0
                  return is_idle_timing(player, 1)
               end
            end
            return false
         end,
         action = function()
            queue_input_sequence_and_wait(player, {{}, {"forward"}}, self.parry_offset)
            self.parry_duration:begin(parry_frames + self.parry_offset)
         end
      }, {
         condition = function() return self.parry_duration:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, {{"down"}})
            self.parry_duration:begin(parry_frames + 2)
         end
      }
   }
end

function followup_forward_down:run(player, stage, actions, i_actions)
   if player.has_just_parried then self.has_parried = true end
   if self.has_parried then
      local next_hit_delta = frame_data.get_next_hit_frame(player.other.char_str, player.other.animation,
                                                           player.other.current_hit_id) - player.other.animation_frame
      if next_hit_delta <= 0 then next_hit_delta = 99 end
      if player.other.animation_frame_data then
         local type = player.other.animation_frame_data.type
         if type then
            if type == "normal" then
               next_hit_delta = next_hit_delta + 2
            elseif type == "super" then
               next_hit_delta = next_hit_delta - 1
            end
         end
      end
      if next_hit_delta >= punish_delta then
         advanced_control.clear_programmed_movement(player)
         return true, {should_punish = true}
      else
         return true, {should_block = true}
      end
   elseif all_commands_complete(player) then
      if self.parry_duration:is_complete() then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_forward_down:is_valid(player, stage, actions)
   for _, action in ipairs(actions) do if action.type == Action_Type.WALK_FORWARD then return false end end
   return true
end

local followup_down_forward = Followup:new("followup_down_forward", Action_Type.PARRY)

function followup_down_forward:setup(player, stage, actions, i_actions)
   self.parry_duration = Delay:new(parry_frames)
   self.parry_offset = 0
   self.has_parried = false
   return {
      {
         condition = function()
            if not player.is_attacking then
               if player.other.character_state_byte == 1 then
                  if player.other.remaining_freeze_frames > 0 or player.other.recovery_time > 0 then
                     if player.other.recovery_time > 0 then
                        self.parry_offset = player.other.recovery_time + 2
                        return true
                     end
                  end
                  return false
               else
                  self.parry_offset = 0
                  return is_idle_timing(player, 1)
               end
            end
            return false
         end,
         action = function()
            queue_input_sequence_and_wait(player, {{}, {"down"}}, self.parry_offset)
            self.parry_duration:begin(parry_frames + self.parry_offset)
         end
      }, {
         condition = function() return self.parry_duration:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, {{"forward"}})
            self.parry_duration:begin(parry_frames + 2)
         end
      }
   }
end

function followup_down_forward:run(player, stage, actions, i_actions)
   if player.has_just_parried then self.has_parried = true end
   if self.has_parried then
      local next_hit_delta = frame_data.get_next_hit_frame(player.other.char_str, player.other.animation,
                                                           player.other.current_hit_id) - player.other.animation_frame
      if next_hit_delta <= 0 then next_hit_delta = 99 end
      if player.other.animation_frame_data then
         local type = player.other.animation_frame_data.type
         if type then
            if type == "normal" then
               next_hit_delta = next_hit_delta + 2
            elseif type == "super" then
               next_hit_delta = next_hit_delta - 1
            end
         end
      end
      if next_hit_delta >= punish_delta then
         advanced_control.clear_programmed_movement(player)
         return true, {should_punish = true}
      else
         return true, {should_block = true}
      end
   elseif all_commands_complete(player) then
      if self.parry_duration:is_complete() then return true, {score = 1} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

local followup_react = Followup:new("followup_react", Action_Type.REACT)

function followup_react:setup(player, stage, actions, i_actions)
   self.react_duration = 50
   self.react_timer = Delay:new(self.react_duration)
   self.previous_action = actions[i_actions - 1]
   if self.previous_action and self.previous_action.type == Action_Type.BLOCK then
      self.previous_action.block_time = self.react_duration + player.other.remaining_wakeup_time + 1
   end
   return {{condition = nil, action = nil}}
end

function followup_react:run(player, stage, actions, i_actions)
   if self.previous_action and self.previous_action.type == Action_Type.BLOCK then
      if self.previous_action.blocked_frames >= self.react_duration then return true, {score = 1} end
   elseif self.react_timer:is_complete() then
      return true, {score = 1}
   end
   if player.other.animation_miss_count > 0 and reaction_time <= player.other.animation_frame +
       prediction.get_frames_until_idle(player.other, nil, nil, 100) then return true, {should_punish = true} end
   if player.other.is_jumping then
      return true, {score = 1}
   elseif player.other.is_airborne and player.other.is_flying_down_flag == 1 then
      return true, {score = -3}
   elseif player.character_state_byte == 1 and (player.is_standing or player.is_crouching) then
      local recovery_time = prediction.get_frames_until_idle(player.other, nil, nil, 100)
      if recovery_time > block_punish_threshold then return true, {should_punish = true} end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_react:block_condition(player, block_followup)
   if block_followup.has_blocked then return false end
   if block_followup.blocked_frames >= self.react_duration then return true end
   if player.other.animation_miss_count > 0 and reaction_time <= player.other.animation_frame then return true end
   return false
end

function followup_react:should_execute(player, stage, actions, i_actions)
   local previous_action = actions[i_actions - 1]
   if previous_action and previous_action.type == Action_Type.BLOCK and previous_action.blocked_frames > 0 then
      return true
   end
   local predicted_state = prediction.predict_player_movement(player, nil, nil, nil, player.other, nil, nil, nil,
                                                              player.other.remaining_freeze_frames + 10)
   local dist = math.abs(predicted_state.dummy_motion_data[#predicted_state.dummy_motion_data].pos_x -
                             predicted_state.player_motion_data[#predicted_state.player_motion_data].pos_x)
   local opponent_throw_range = frame_data.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral")
   local throwable_box_extension = 4
   if opponent_throw_range < dist - character_specific[player.char_str].pushbox_width / 2 - 2 - throwable_box_extension then
      return true
   end
   return false
end

local followup_walk_in = Followup:new("followup_walk_in", Action_Type.WALK_FORWARD)

function followup_walk_in:setup(player, stage, actions, i_actions)
   self.min_walk_frames = 6
   self.max_walk_frames = 30
   self.walked_frames = 0
   self.next_action = actions[i_actions + 1]
   if self.next_action and self.next_action.walk_in_condition then
      self.next_action:setup(player, stage, actions, i_actions + 1)
   end
   local setup = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function()
            self.walked_frames = self.walked_frames + 1
            inputs.queue_input_sequence(player, walk_forward_input, 0, true)
         end
      }
   }
   return setup
end

function followup_walk_in:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      self.next_action = actions[i_actions + 1]
      if self.next_action and self.next_action.walk_in_condition and self.next_action:walk_in_condition(player, self) then
         return true, {score = 0}
      end
      if self.walked_frames < self.max_walk_frames then
         self:extend(player)
      else
         return true, {score = 0}
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_walk_in:extend(player)
   self.walked_frames = self.walked_frames + 1
   inputs.queue_input_sequence(player, walk_forward_input, 0, true)
end

function followup_walk_in:is_valid(player, stage, actions)
   for _, action in ipairs(actions) do if action.type == Action_Type.WALK_FORWARD then return false end end
   return true
end

function followup_walk_in:label() return {self.name, " ", self.walked_frames, "hud_f"} end

function followup_walk_in:followups() return walk_in_followups end

local followup_walk_out = Followup:new("followup_walk_out", Action_Type.WALK_BACKWARD)
local walk_out_margin = 10
local walk_out_max_frames = 20
local wakeup_walk_out_timing = 10

function followup_walk_out:setup(player, stage, actions, i_actions)
   self.min_walk_frames = 6
   self.walked_frames = 0
   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, wakeup_walk_out_timing, true)
            else
               return is_idle_timing(player, 1, true)
            end
         end,
         action = function()
            self.walked_frames = self.walked_frames + 1
            inputs.queue_input_sequence(player, walk_back_input, 0, true)
         end
      }
   }
   return setup
end

function followup_walk_out:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      local opponent_throw_range = frame_data.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral")
      local throwable_box_extension = 0
      local next_action = actions[i_actions + 1]
      if next_action and next_action.type == Action_Type.BLOCK then throwable_box_extension = 4 end
      if player.has_just_blocked then return true, {should_block = true} end
      if self.walked_frames >= self.min_walk_frames and opponent_throw_range < dist -
          character_specific[player.char_str].pushbox_width / 2 - walk_out_margin - throwable_box_extension then
         return true, {score = 0}
      end
      if self.walked_frames < walk_out_max_frames then
         self:extend(player)
      else
         return true, {score = 0}
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_walk_out:extend(player)
   self.walked_frames = self.walked_frames + 1
   inputs.queue_input_sequence(player, walk_back_input, 0, true)
end

function followup_walk_out:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   return true
end

function followup_walk_out:is_valid(player, stage, actions, i_actions)
   for _, action in ipairs(actions) do if action.type == Action_Type.WALK_BACKWARD then return false end end
   return true
end

function followup_walk_out:should_execute(player, stage, actions, i_actions)
   local current_stage = stage_data.stages[stage]
   local sign = tools.sign(player.other.pos_x - player.pos_x)
   local dist = math.max(math.abs(player.other.pos_x - player.pos_x), frame_data.get_contact_distance(player))
   local opponent_throw_range = frame_data.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral")
   local walk_frames = walk_out_max_frames
   local walk_dist = utils.get_backward_walk_distance(player, walk_frames)
   return (player.pos_x - sign * walk_dist >= current_stage.left +
              character_specific[player.char_str].corner_offset_left) and
              (player.pos_x - sign * walk_dist <= current_stage.right -
                  character_specific[player.char_str].corner_offset_right) and
              (opponent_throw_range < dist + walk_dist - character_specific[player.char_str].pushbox_width / 2)
end

function followup_walk_out:label() return {self.name, " ", self.walked_frames, "hud_f"} end

function followup_walk_out:followups(player) return walk_out_followups end

local followup_back_dash = Followup:new("followup_back_dash")

function followup_back_dash:setup(player, stage, actions, i_actions)
   local dash_duration = Delay:new(#back_dash_input + back_dash_duration + 1 - 3)
   local setup = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function()
            queue_input_sequence_and_wait(player, back_dash_input)
            dash_duration:begin()
         end
      }, {condition = function() return dash_duration:is_complete() end, action = nil}
   }
   return setup
end

function followup_back_dash:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then return true, {score = 0} end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_back_dash:should_execute(player, stage, actions, i_actions)
   local current_stage = stage_data.stages[stage]
   local sign = tools.sign(player.other.pos_x - player.pos_x)
   local back_dash_dist = 54
   return (player.pos_x - sign * back_dash_dist >= current_stage.left +
              character_specific[player.char_str].corner_offset_left) and
              (player.pos_x - sign * back_dash_dist <= current_stage.right -
                  character_specific[player.char_str].corner_offset_right)
end

function followup_back_dash:followups(player) return back_dash_followups end

local followup_forward_dash = Followup:new("followup_forward_dash")

function followup_forward_dash:setup(player, stage, actions, i_actions)
   local dash_duration = Delay:new(#forward_dash_input + forward_dash_duration + 1 - 3)
   local setup = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function()
            queue_input_sequence_and_wait(player, forward_dash_input)
            dash_duration:begin()
         end
      }, {condition = function() return dash_duration:is_complete() end, action = nil}
   }
   return setup
end

function followup_forward_dash:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then return true, {score = 0} end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_forward_dash:followups(player) return forward_dash_followups end

local setup_close_distance = Followup:new("setup_close_distance")
function setup_close_distance:setup(player, stage, actions, i_actions)
   self.should_dash = false
   local dash_duration = Delay:new(0)
   return {
      {
         condition = function() return is_idle_timing(player, #forward_dash_input, true) end,
         action = function()
            if (not player.other.is_waking_up and not player.other.is_being_thrown and player.other.is_airborne) or
                player.other.remaining_wakeup_time >= 40 then
               self.should_dash = true
               dash_duration:begin(#forward_dash_input + forward_dash_duration + 1 - 3)
            end
         end
      }, {
         condition = nil,
         action = function()
            if self.should_dash then queue_input_sequence_and_wait(player, forward_dash_input) end
         end
      }, {condition = function() return not self.should_dash or dash_duration:is_complete() end, action = nil}
   }
end

function setup_close_distance:should_execute(player, stage, actions, i_actions)
   if player.animation == "5d48" or player.animation == "5f20" then return false end -- forward throw
   if player.other.is_airborne or player.other.remaining_wakeup_time -
       prediction.get_frames_until_idle(player, nil, nil, 100) >= 30 then return true end
   return false
end

local setup_far_d_lk = Setup:new("setup_far_d_lk")

function setup_far_d_lk:get_hard_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   return {
      current_stage.left + character_specific.ken.corner_offset_left + 110,
      current_stage.right - character_specific.ken.corner_offset_right - 110
   }
end

function setup_far_d_lk:get_soft_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_far_d_lk:get_dummy_offset(player) return 100 end

function setup_far_d_lk:setup(player, stage, actions, i_actions)
   local block_delay = Delay:new(d_lk_hit_frame)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            end
            return true
         end,
         action = function()
            queue_input_sequence_and_wait(player, d_lk_input)
            block_delay:begin()
         end
      }, {
         condition = function() return block_delay:is_complete() end,
         action = function() inputs.queue_input_sequence(player.other, block_low_input) end
      }, {condition = function() return player.has_just_connected end, action = connection_end_delay:reset()},
      {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

function setup_far_d_lk:followups() return far_d_lk_followups end

local setup_close_d_lk = Setup:new("setup_close_d_lk")

function setup_close_d_lk:get_hard_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   return {
      current_stage.left + character_specific.ken.corner_offset_left + 110,
      current_stage.right - character_specific.ken.corner_offset_right - 110
   }
end

function setup_close_d_lk:get_soft_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_close_d_lk:get_dummy_offset(player) return frame_data.get_contact_distance(player) end

function setup_close_d_lk:setup(player, stage, actions, i_actions)
   local block_delay = Delay:new(d_lk_hit_frame)
   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            end
            return true
         end,
         action = function()
            queue_input_sequence_and_wait(player, d_lk_input)
            block_delay:begin()
         end
      }, {
         condition = function() return block_delay:is_complete() end,
         action = function() inputs.queue_input_sequence(player.other, block_low_input) end
      }, {condition = function() return player.has_just_connected end, action = connection_end_delay:reset()},
      {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

function setup_close_d_lk:followups() return close_d_lk_followups end

local setup_close_mp = Setup:new("setup_close_mp")

function setup_close_mp:get_hard_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   return {
      current_stage.left + character_specific.ken.corner_offset_left + 110,
      current_stage.right - character_specific.ken.corner_offset_right - 110
   }
end

function setup_close_mp:get_soft_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_close_mp:get_dummy_offset(player) return frame_data.get_contact_distance(player) end

function setup_close_mp:setup(player, stage, actions, i_actions)
   local block_delay = Delay:new(cl_mp_hit_frame)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            end
            return true
         end,
         action = function()
            queue_input_sequence_and_wait(player, cl_mp_input)
            block_delay:begin()
         end
      }, {
         condition = function() return block_delay:is_complete() end,
         action = function() inputs.queue_input_sequence(player.other, block_high_input) end
      }, {condition = function() return player.has_just_connected end, action = connection_end_delay:reset()},
      {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

function setup_close_mp:followups() return close_mp_followups end

local setup_cross_up_mk = Setup:new("setup_cross_up_mk")

function setup_cross_up_mk:get_hard_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   return {
      current_stage.left + character_specific.ken.corner_offset_left + 110,
      current_stage.right - character_specific.ken.corner_offset_right - 110
   }
end

local corner_gap = 6
function setup_cross_up_mk:get_soft_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - corner_gap
   }
end

function setup_cross_up_mk:get_dummy_offset(player)
   local dummy_offset_x = 110
   if player.other.char_str == "yang" or player.other.char_str == "yun" then dummy_offset_x = 90 end
   return dummy_offset_x
end

function setup_cross_up_mk:setup(player, stage, actions, i_actions)
   local jump_mk_frame = 27
   if player.other.char_str == "hugo" then
      jump_mk_frame = 25
   elseif player.other.char_str == "remy" then
      jump_mk_frame = 26
   end

   local jump_mk_delay = Delay:new(jump_mk_frame)

   local anim, fdata = frame_data.find_frame_data_by_name("ken", "uf_MK")
   local jump_mk_hit_frame = 0
   if fdata then jump_mk_hit_frame = fdata.hit_frames[1][1] end

   local block_delay = Delay:new(jump_mk_hit_frame)
   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, 20, true)
            else
               return true
            end
         end,
         action = function() queue_input_sequence_and_wait(player, jump_forward_input) end
      }, {
         condition = function() return jump_mk_delay:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, jump_mk_input)
            block_delay:begin()
         end
      }, {
         condition = function() return block_delay:is_complete() end,
         action = function() inputs.queue_input_sequence(player.other, block_high_input) end
      }, {condition = function() return player.has_just_connected end, action = connection_end_delay:reset()},
      {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

function setup_cross_up_mk:followups() return crossup_mk_followups end

local setup_wakeup = Setup:new("setup_wakeup")
function setup_wakeup:get_hard_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.ken.corner_offset_left + character_specific.ken.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.ken.corner_offset_right - character_specific.ken.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_wakeup:get_soft_reset_range(player, stage)
   local current_stage = stage_data.stages[stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_wakeup:get_dummy_offset(player) return frame_data.get_contact_distance(player) end

function setup_wakeup:setup(player, stage, actions, i_actions)
   local setup = {
      {
         condition = function()
            return is_throw_vulnerable_timing(player, #throw_input + throw_hit_frame + 1, true)
         end,
         action = function() queue_input_sequence_and_wait(player, throw_input) end
      }, {
         condition = function()
            return player.other.previous_can_fast_wakeup == 0 and player.other.can_fast_wakeup == 1
         end,
         action = function()
            local input = joypad.get()
            input[player.other.prefix .. " Down"] = true
            joypad.set(input)
         end
      }
   }
   if player.other.is_waking_up or player.other.posture == 24 then return {condition = nil, action = nil} end
   return setup
end

function setup_wakeup:followups() return wakeup_followups end

far_d_lk_followups = {
   {action = followup_forward_dash, default_weight = 1}, {action = followup_d_mk, default_weight = 1},
   {action = followup_hk, default_weight = 0.3}
}
close_d_lk_followups = {
   {action = followup_walk_in, default_weight = 1}, {action = followup_d_mk, default_weight = 1},
   {action = followup_d_mp, default_weight = 1}, {action = followup_far_mp, default_weight = 0.3},
   {action = followup_block, default_weight = 1}, {action = followup_forward_down, default_weight = 1},
   {action = followup_down_forward, default_weight = 1}, {action = followup_kara_throw, default_weight = 1}
}
close_mp_followups = {
   {action = followup_walk_in, default_weight = 1}, {action = followup_d_mk, default_weight = 1},
   {action = followup_d_mp, default_weight = 1}, {action = followup_far_mp, default_weight = 0.3},
   {action = followup_block, default_weight = 1}, {action = followup_forward_down, default_weight = 1},
   {action = followup_down_forward, default_weight = 1}, {action = followup_kara_throw, default_weight = 1}
}
crossup_mk_followups = {
   {action = followup_walk_in, default_weight = 1}, {action = followup_walk_out, default_weight = 1},
   {action = followup_back_dash, default_weight = 0.3}, {action = followup_mp_hp, default_weight = 1},
   {action = followup_close_mp, default_weight = 1}, {action = followup_d_lk_d_lk, default_weight = 1},
   {action = followup_close_d_lk, default_weight = 1}, {action = followup_b_mk, default_weight = 0.3},
   {action = followup_kara_throw, default_weight = 1}, {action = followup_block, default_weight = 1}
}
wakeup_followups = {
   {action = followup_walk_out, default_weight = 1}, {action = followup_close_mp, default_weight = 1},
   {action = followup_close_d_lk, default_weight = 1}, {action = followup_mp_hp, default_weight = 1},
   {action = followup_d_lk_d_lk, default_weight = 1}, {action = followup_b_mk, default_weight = 0.3},
   {action = followup_block, default_weight = 1}
}
block_followups = {
   {action = followup_throw, default_weight = 1}, {action = followup_d_mp, default_weight = 1},
   {action = followup_react, default_weight = 1}
}
walk_in_followups = {
   {action = followup_walk_out, default_weight = 1}, {action = followup_mp_hp, default_weight = 1},
   {action = followup_d_lk_d_lk, default_weight = 1}, {action = followup_throw, default_weight = 1}
}
walk_out_followups = {
   {action = followup_walk_in, default_weight = 1}, {action = followup_d_mp, default_weight = 1},
   {action = followup_block, default_weight = 1}, {action = followup_forward_down, default_weight = 1},
   {action = followup_down_forward, default_weight = 1}
}
back_dash_followups = {{action = followup_d_mk, default_weight = 1}}
forward_dash_followups = {
   {action = followup_throw, default_weight = 1}, {action = followup_mp_hp, default_weight = 1},
   {action = followup_d_lk_d_lk, default_weight = 1}
}

local close_distance = {action = setup_close_distance, weight = 1}
local block = {action = followup_block, weight = 1}
local punish = {action = followup_punish, weight = 1}
local walk_in = {action = followup_walk_in, weight = 1}
local walk_out = {action = followup_walk_out, weight = 1}

local wakeup = {action = setup_wakeup, default_weight = 1}

local setups = {
   {action = setup_far_d_lk, default_weight = 1}, {action = setup_close_d_lk, default_weight = 1},
   {action = setup_close_mp, default_weight = 1}, {action = setup_cross_up_mk, default_weight = 1}, wakeup
}

local setup_names = {}
for i, setup in ipairs(setups) do table.insert(setup_names, setup.action.name) end

local followups = {
   {name = "far_d_lk_followups", list = far_d_lk_followups},
   {name = "close_d_lk_followups", list = close_d_lk_followups},
   {name = "close_mp_followups", list = close_mp_followups},
   {name = "crossup_mk_followups", list = crossup_mk_followups}, {name = "wakeup_followups", list = wakeup_followups},
   {name = "block_followups", list = block_followups}, {name = "walk_in_followups", list = walk_in_followups},
   {name = "walk_out_followups", list = walk_out_followups}, {name = "back_dash_followups", list = back_dash_followups},
   {name = "forward_dash_followups", list = forward_dash_followups}
}

local followup_names = {}
for i, followup in ipairs(followups) do table.insert(followup_names, followup.name) end

local followup_followup_names = {}
for i, followup in ipairs(followups) do
   followup_followup_names[i] = {}
   for j, followup_followup in ipairs(followup.list) do
      table.insert(followup_followup_names[i], followup_followup.action.name)
   end
end

return {
   setup_names = setup_names,
   followup_names = followup_names,
   followup_followup_names = followup_followup_names,
   setups = setups,
   followups = followups,
   close_distance = close_distance,
   wakeup = wakeup,
   block = block,
   punish = punish,
   walk_in = walk_in,
   walk_out = walk_out,
   knockdown = knockdown,
   sa = 3,
   init = init
}
