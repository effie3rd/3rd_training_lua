local framedata = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local move_data = require("src.modules.move_data")
local training_classes = require("src.training.training_classes")
local advanced_control = require("src.control.advanced_control")
local tools = require("src.tools")
local utils = require("src.modules.utils")
local inputs = require("src.control.inputs")
local write_memory = require("src.control.write_memory")
local gamestate = require("src.gamestate")
-- accuracy
-- walk = {"", ""}
-- leave option for specials
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

local moves = {}
local move_names = {
   alex = {
      "f_MP", "MK", "d_MP", "d_MK", "d_HK", "slash_elbow_LP", "slash_elbow_MP", "slash_elbow_HP", "slash_elbow_EXP",
      "kara_throw"
   },
   chunli = {"MP", "d_MP", "d_MK", "HP", "b_HP", "HK", "d_HK", "hazanshuu_LK", "kara_throw"},
   dudley = {"MP", "d_MP", "f_MK", "HP", "f_HP", "HK", "d_HK"},
   elena = {"d_MP", "f_MK", "d_MK", "HK", "d_HK", "kara_throw"}, -- , "mallet_smash_LP", "mallet_smash_EXP"
   gill = {"MK", "d_MK", "d_HK", "HP"},
   gouki = {"d_MP", "MK", "d_MK", "d_HK", "gohadouken_HP"},
   hugo = {
      "LP", "d_LP", "d_LK", "MP", "d_MP", "d_MK", "giant_palm_bomber_LP", "giant_palm_bomber_MP",
      "giant_palm_bomber_HP", "giant_palm_bomber_EXP"
   },
   ibuki = {"MP", "MK", "d_MP", "d_MK", "f_HK"},
   ken = {"d_MP", "d_MK", "HK", "d_HK", "hadouken_EXP"},
   makoto = {"MP", "d_MP", "d_MK", "d_HP", "d_HK", "kara_karakusa_lk"},
   necro = {"d_LK", "MP", "HP", "b_MP", "b_MK", "d_MK", "d_HP", "d_HK", "denji_blast_LP"},
   oro = {"MP", "MK", "HK", "d_MP", "d_MK", "d_HK", "kara_throw", "nichirin_LP", "niouriki", "kara_niouriki"},
   q = {"MK", "d_MK", "HP", "b_HP", "d_HP", "kara_throw", "capture_and_deadly_blow_HK", "kara_capture_and_deadly_blow"},
   remy = {
      "d_LK", "d_MP", "MK", "d_MK", "d_HK", "cold_blue_kick_LK", "cold_blue_kick_MK", "cold_blue_kick_HK",
      "cold_blue_kick_EXK"
   },
   ryu = {"d_MP", "MK", "d_MK", "d_HK", "hadouken_EXP"},
   sean = {"d_MK", "HP", "d_HK"},
   shingouki = {"d_MP", "MK", "d_MK", "d_HK", "gohadouken_HP"},
   twelve = {"d_MK", "HK", "ndl_EXP"},
   urien = {"MK", "d_MK", "d_HK", "HP"},
   yang = {"d_MK", "f_MK", "HP", "d_HK", "tourouzan_LP", "tourouzan_MP", "tourouzan_HP", "tourouzan_EXP"},
   yun = {"d_MP", "d_MK", "f_MP", "d_MK", "HP", "HK", "d_HK", "zesshou_LP", "tetsuzan_LP"}
}

local input_button_data = {
   alex = {kara_throw = {"forward", "HP"}},
   chunli = {kara_throw = {"MK"}},
   elena = {kara_throw = {"forward", "MK"}},
   makoto = {kara_karakusa_lk = {"HK"}},
   q = {kara_throw = {"back", "MP"}, kara_capture_and_deadly_blow = {"HK"}}
}

local relevant_move_default = {
   alex = "MK",
   chunli = "d_MK",
   dudley = "HK",
   elena = "d_MP",
   gill = "HP",
   gouki = "d_MK",
   hugo = "MP",
   ibuki = "d_MK",
   ken = "d_MK",
   makoto = "d_MK",
   necro = "MP",
   oro = "MK",
   q = "MK",
   remy = "MK",
   ryu = "d_MK",
   sean = "d_MK",
   shingouki = "d_MK",
   twelve = "d_MK",
   urien = "d_MK",
   yang = "d_MK",
   yun = "d_MK"
}
local recent_moves = {}
local recent_move_timeout = 20 * 60

local walk_forward_input = {{"forward"}}
local walk_back_input = {{"back"}}
local block_high_input = {{"back"}, {"back"}}
local block_low_input = {{"back", "down"}, {"back", "down"}}
local reaction_time = 0

local walk_in_followups
local walk_out_followups

local current_attack

local walk_forward_times = {10}
local walk_back_times = {10}
local current_walk_time = 0
local walk_time_data_max = 10

local accuracy = 100

local distance_judgement_max = 60
local distance_judgement = 100

local walk_in_range = 8
local walk_in_range_min = 8

local last_back_input = 0
local last_forward_input = 0

local dash_input_window = 8

local function update_walk_time(player)
   if player.previous_action == 2 and player.action ~= 2 then
      if #walk_forward_times >= walk_time_data_max then table.remove(walk_forward_times, 1) end
      walk_forward_times[#walk_forward_times + 1] = current_walk_time
   end
   if player.previous_action == 3 and player.action ~= 3 then
      if #walk_back_times >= walk_time_data_max then table.remove(walk_back_times, 1) end
      walk_back_times[#walk_back_times + 1] = current_walk_time
   end
   if player.action == 2 then
      if player.previous_action ~= 2 then current_walk_time = 0 end
      current_walk_time = current_walk_time + 1
   elseif player.action == 3 then
      if player.previous_action ~= 3 then current_walk_time = 0 end
      current_walk_time = current_walk_time + 1
   end
end

local function update_recent_attacks(player)
   if player.has_just_attacked then
      local hit_frame = framedata.get_first_hit_frame(player.char_str, player.animation)
      local hitboxes = framedata.get_hitboxes(player.char_str, player.animation, hit_frame)
      local range = framedata.get_hitbox_max_range(player.char_str, player.animation)
      recent_moves[player.animation] = {start_frame = gamestate.frame_number, hitboxes = hitboxes, range = range}
   end
end

local function get_average_walk_forward_time()
   local total = 0
   for _, time in ipairs(walk_forward_times) do total = total + time end
   return total / #walk_forward_times
end
local function get_average_walk_back_time()
   local total = 0
   for _, time in ipairs(walk_back_times) do total = total + time end
   return total / #walk_back_times
end

local function get_expected_distance(player, n_frames)
   local walk_speed = 0
   local sign = player.flip_x and 1 or -1
   if player.action == 2 then
      n_frames = tools.clamp(get_average_walk_forward_time() - current_walk_time, 0, n_frames)
      walk_speed = character_specific[player.char_str].forward_walk_speed
   elseif player.action == 3 then
      n_frames = tools.clamp(get_average_walk_back_time() - current_walk_time, 0, n_frames)
      walk_speed = character_specific[player.char_str].backward_walk_speed
   end
   local stage_left, stage_right = utils.get_stage_limits(gamestate.stage, player.other.char_str)
   local other_pos_x = tools.clamp(player.other.pos_x + sign * walk_speed * n_frames, stage_left, stage_right)
   return math.abs(player.other.pos_x - player.pos_x)
end

local function get_recent_attack()
   local attack
   local range = 0
   for anim, data in pairs(recent_moves) do
      if gamestate.frame_number - data.start_frame < recent_move_timeout then
         if data.range > range then
            range = data.range
            attack = data
         end
      end
   end
   if not attack then
      local most_recent_frame = 0
      for anim, data in pairs(recent_moves) do
         if data.start_frame > most_recent_frame then
            most_recent_frame = data.start_frame
            attack = data
         end
      end
   end
   return attack
end

local function handle_interruptions(player, stage, actions, i_actions)
   if (player.has_just_been_hit and not player.is_being_thrown) or player.other.has_just_parried then
      return true, {score = 1, should_end = true}
   end
   if (player.is_being_thrown and player.throw_tech_countdown <= 0) then return true, {score = 1, should_end = true} end
   if player.has_just_missed then
      if not player.other.is_attacking then return true, {score = 0, should_end = true} end
   end
   return false
end

local function get_execute_distance(player, action_type)
   local dist = get_expected_distance(player.other, #current_attack.data.input + current_attack.data.hit_frame + 1)
   local movement = 0
   if action_type == Action_Type.WALK_FORWARD then
      movement = character_specific[player.char_str].forward_walk_speed
   elseif action_type == Action_Type.WALK_BACKWARD then
      movement = character_specific[player.char_str].backward_walk_speed
   end

   local box_types = {"vulnerability", "ext.vulnerability"}
   if current_attack.data.type == "throw" then box_types = {"throwable"} end
   return dist -
              utils.get_box_connection_distance(player, current_attack.data.hitboxes, player.other, player.other.boxes,
                                                box_types, current_attack.data.should_hit) -
              current_attack.data.execute_range - movement
end

local function is_in_execute_range(player, action_type)
   local remaining_dist = get_execute_distance(player, action_type)
   if current_attack.data.should_hit then
      if remaining_dist <= 0 then return true end
   else
      if remaining_dist >= 0 then return true end
   end
   return false
end

local followup_attack = Followup:new("followup_attack", Action_Type.ATTACK)

function followup_attack:setup(player, stage, actions, i_actions)
   self.end_delay = 12
   self.opponent_has_been_thrown = false
   local input_delay = Delay:new(6)
   local should_delay = false
   if current_attack.data.name == "hadouken_EXP" or current_attack.data.name == "gohadouken_HP" 
   or current_attack.data.name == "zesshou_LP"
   then
      local previous_action = actions[i_actions - 1]
      if previous_action and previous_action.type == Action_Type.WALK_FORWARD then should_delay = true end
   end
   return {
      {
         condition = function()
            if should_delay and not input_delay:is_complete() then return false end
            if current_attack.data.type == "attack" then
               return is_idle_timing(player, #current_attack.data.input, true)
            else
               return is_throw_vulnerable_timing(player.other, #current_attack.data.input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, current_attack.data.input, nil, true) end
      }
   }
end

function followup_attack:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      if player.has_just_missed or player.other.is_attacking or player.has_just_been_blocked or
          player.other.has_just_blocked then return true, {score = 0, should_block = true} end
      if player.has_just_hit or player.other.has_just_been_hit then return true, {score = -1, should_end = true} end
      if player.is_idle then return true, {score = 0, should_end = true} end
      if player.is_in_throw_tech or player.other.is_in_throw_tech then return true, {score = 0, should_end = true} end
      if player.other.has_just_been_thrown then self.opponent_has_been_thrown = true end
      if self.opponent_has_been_thrown then
         self.end_delay = self.end_delay - 1
         if self.end_delay <= 0 then return true, {score = -1, should_end = true} end
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_attack:is_valid(player, stage, actions, i_actions)
   local previous_action = actions[#actions]
   if previous_action and
       (previous_action.type == Action_Type.WALK_FORWARD or previous_action.type == Action_Type.WALK_BACKWARD) then
      return true
   end
   return is_in_execute_range(player)
end

function followup_attack:should_execute(player, stage, actions, i_actions)
   local previous_action = actions[i_actions - 1]
   if previous_action and
       (previous_action.type == Action_Type.WALK_FORWARD or previous_action.type == Action_Type.WALK_BACKWARD) then
      return true
   end
   return is_in_execute_range(player)
end

function followup_attack:walk_in_condition(player, walk_followup)
   local dist = get_execute_distance(player)
   local should_walk = false
   if current_attack.data.should_hit then
      if dist > 0 then should_walk = true end
   else
      if dist > character_specific[player.char_str].forward_walk_speed then should_walk = true end
   end
   if should_walk then walk_followup:extend(player) end
   return not should_walk
end

function followup_attack:walk_out_condition(player, walk_followup)
   local dist = get_execute_distance(player)
   local should_walk = false
   if current_attack.data.should_hit then
      if dist < character_specific[player.char_str].backward_walk_speed then should_walk = true end
   else
      if dist < 0 then should_walk = true end
   end
   if should_walk then walk_followup:extend(player) end
   return not should_walk
end

local followup_walk_in = Followup:new("followup_walk_in", Action_Type.WALK_FORWARD)

function followup_walk_in:setup(player, stage, actions, i_actions)
   self.min_walk_frames = 4
   self.max_walk_frames = 600
   self.walked_frames = 0
   last_forward_input = gamestate.frame_number

   local setup = {
      {condition = nil, action = function() inputs.queue_input_sequence(player, walk_forward_input, 0, true) end}
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
   if player.action == 2 then self.walked_frames = self.walked_frames + 1 end
   inputs.queue_input_sequence(player, walk_forward_input, 0, true)
end

function followup_walk_in:is_valid(player, stage, actions, i_actions)
   if gamestate.frame_number - last_forward_input < dash_input_window then return false end
   local dist = get_execute_distance(player, Action_Type.WALK_FORWARD)

   if current_attack.data.should_hit then
      if dist > 0 then return true end
   else
      if dist > character_specific[player.char_str].forward_walk_speed then return true end
   end
   return false
end

function followup_walk_in:followups() return walk_in_followups end

function followup_walk_in:label() return {self.name, " ", self.walked_frames, "hud_f"} end

local followup_walk_out = Followup:new("followup_walk_out", Action_Type.WALK_BACKWARD)

function followup_walk_out:setup(player, stage, actions, i_actions)
   self.min_walk_frames = 8
   self.max_walk_frames = 80
   self.walked_frames = 0
   local distance_judgement_range = distance_judgement_max - distance_judgement_max * distance_judgement / 100
   local offset = tools.random_quadratic(0, distance_judgement_range, 0, 0.6)
   self.execute_range = get_recent_attack().range + offset
   last_back_input = gamestate.frame_number
   local setup = {
      {condition = nil, action = function() inputs.queue_input_sequence(player, walk_back_input, 0, true) end}
   }
   return setup
end

function followup_walk_out:run(player, stage, actions, i_actions)
   if all_commands_complete(player) then
      local stage_left, stage_right = utils.get_stage_limits(stage, player.char_str)
      if player.pos_x <= stage_left or player.pos_x >= stage_right then return true, {score = 0} end
      self.next_action = actions[i_actions + 1]

      if self.walked_frames < self.min_walk_frames then
         self:extend(player)
      else
         local dist = get_expected_distance(player.other, 1)
         local attack = get_recent_attack()
         if self.walked_frames < self.max_walk_frames and dist -
             utils.get_box_connection_distance(player.other, attack.hitboxes, player, player.boxes) - self.execute_range <=
             0 then
            self:extend(player)
         else
            if self.next_action and self.next_action.walk_out_condition and
                self.next_action:walk_out_condition(player, self) then return true, {score = 0} end
         end
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_walk_out:extend(player)
   if player.action == 3 then self.walked_frames = self.walked_frames + 1 end
   inputs.queue_input_sequence(player, walk_back_input, 0, true)
end

function followup_walk_out:walk_in_condition(player, walk_followup)
   local dist = get_expected_distance(player.other, 1)
   local attack = get_recent_attack()
   if dist - utils.get_box_connection_distance(player.other, attack.hitboxes, player, player.boxes) - attack.range +
       walk_in_range <= 0 then return true end
   walk_followup:extend(player)
   return false
end

function followup_walk_out:is_valid(player, stage, actions, i_actions)
   if gamestate.frame_number - last_back_input < dash_input_window then return false end
   local dist = get_execute_distance(player, Action_Type.WALK_BACKWARD)
   if current_attack.data.should_hit then
      if dist < character_specific[player.char_str].backward_walk_speed then return true end
   else
      if dist < 0 then return true end
   end
   return false
end

function followup_walk_out:should_execute(player, stage, actions, i_actions) return not (player.other.action == 2) end

function followup_walk_out:followups() return walk_out_followups end

function followup_walk_out:label() return {self.name, " ", self.walked_frames, "hud_f"} end

local followup_reset_distance = Followup:new("followup_reset_distance", Action_Type.WALK_FORWARD)

function followup_reset_distance:setup(player, stage, actions, i_actions)
   self.walked_frames = 0
   self.input = walk_forward_input
   local sign = player.pos_x - player.other.pos_x > 0 and 1 or -1
   local player_stage_left, player_stage_right = utils.get_stage_limits(stage, player.char_str)
   self.reset_position = tools.clamp(player.other.pos_x + sign * framedata.get_contact_distance(player) + 110,
                                     player_stage_left, player_stage_right)
   if player.pos_x > self.reset_position and player.flip_input or player.pos_x < self.reset_position and
       not player.flip_input then self.input = walk_back_input end
   local setup = {{condition = nil, action = function() inputs.queue_input_sequence(player, self.input, 0, true) end}}
   if self.input == walk_forward_input then
      last_forward_input = gamestate.frame_number
   else
      last_back_input = gamestate.frame_number
   end
   return setup
end

function followup_reset_distance:run(player, stage, actions, i_actions)
   if not player.other.is_waking_up then return true, {score = 0, should_end = true} end
   if all_commands_complete(player) then
      if math.abs(self.reset_position - player.pos_x) > 4 then
         self:extend(player)
      else
         write_memory.write_pos_x(player, self.reset_position)
      end
   end
   return handle_interruptions(player, stage, actions, i_actions)
end

function followup_reset_distance:extend(player)
   if player.action == 2 or player.action == 3 then self.walked_frames = self.walked_frames + 1 end
   inputs.queue_input_sequence(player, self.input, 0, true)
end

function followup_reset_distance:label() return {self.name, " ", self.walked_frames, "hud_f"} end

local followup_block = Followup:new("followup_block", Action_Type.BLOCK)

function followup_block:setup(player, stage, actions, i_actions)
   self.blocked_frames = 0
   self.block_time = 20
   self.block_input = block_low_input
   self.has_blocked = false
   self.has_parried = false
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
            if player.other.is_attacking then
               inputs.queue_input_sequence(player, self.block_input)
               self.blocked_frames = self.blocked_frames + 1
               self.block_time = self.block_time + player.other.recovery_time + player.other.remaining_wakeup_time
            end
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
            if hit_type == 4 then
               if framedata.get_next_hit_frame(player.other.char_str, player.other.animation,
                                               player.other.current_hit_id + 1) >= reaction_time then
                  self.block_input = block_high_input
               end
            end
         end
      end
      if player.has_just_hit then return true, {score = -1, should_end = true} end
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
            return true, {score = 0, should_end = true}
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
   if player.other.is_attacking then inputs.queue_input_sequence(player, self.block_input) end
end

local menu_move_names = {}
local function init(char_str)
   moves = {}
   menu_move_names = {}
   recent_moves = {}
   last_back_input = 0
   last_forward_input = 0
   local anim = framedata.find_move_frame_data(char_str, relevant_move_default[char_str]) or "none"
   local hf = framedata.get_first_hit_frame_by_name(char_str, relevant_move_default[char_str])
   local hb = framedata.get_hitboxes_by_name(char_str, relevant_move_default[char_str], nil, hf)
   local r = framedata.get_hitbox_max_range_by_name(char_str, relevant_move_default[char_str], nil, -1)
   recent_moves[anim] = {start_frame = gamestate.frame_number, hitboxes = hb, range = r}
   for i, move_name in ipairs(move_names[char_str]) do
      local hit_frame = framedata.get_first_hit_frame_by_name(char_str, move_name)
      if tools.table_contains({"cold_blue_kick_LK", "cold_blue_kick_MK", "cold_blue_kick_HK"}, move_name) then
         hit_frame = framedata.get_last_hit_frame_by_name(char_str, move_name)
      end
      local input = tools.name_to_sequence(move_name)
      local button
      if not input then
         if input_button_data[char_str] and input_button_data[char_str][move_name] then
            button = input_button_data[char_str][move_name]
         end
         input = move_data.get_move_inputs_by_name(char_str, move_name, button)
      end
      local data = {
         name = move_name,
         type = "attack",
         input = input or {},
         hit_frame = hit_frame,
         hitboxes = framedata.get_hitboxes_by_name(char_str, move_name, nil, hit_frame),
         range = framedata.get_hitbox_max_range_by_name(char_str, move_name, nil, -1)
      }
      if move_name == "cold_blue_kick_EXK" then
         data.range = framedata.get_hitbox_max_range_by_name(char_str, move_name, nil, 1)
      end
      if move_name == "kara_throw" then
         local name = tools.sequence_to_name({data.input[1]})
         local kara_dist = framedata.get_kara_distance_by_name(char_str, name)
         data.hit_frame = framedata.get_first_hit_frame_by_name(char_str, "throw_neutral")
         data.hitboxes = framedata.get_hitboxes_by_name(char_str, "throw_neutral", nil, data.hit_frame)
         data.hit_frame = data.hit_frame + 1
         data.range = kara_dist + framedata.get_hitbox_max_range_by_name(char_str, "throw_neutral")
         data.type = "throw"
         if char_str == "chunli" then data.min_range = 45 end
      elseif move_name == "kara_niouriki" or move_name == "kara_capture_and_deadly_blow" then
         local name = tools.sequence_to_name({data.input[1]})
         if move_name == "kara_niouriki" then
            data.hit_frame = framedata.get_first_hit_frame_by_name(char_str, "niouriki")
            data.hitboxes = framedata.get_hitboxes_by_name(char_str, "niouriki", nil, data.hit_frame)
            data.hit_frame = data.hit_frame + 1
            data.range = framedata.get_hitbox_max_range_by_name(char_str, "niouriki")
         elseif move_name == "kara_capture_and_deadly_blow" then
            data.hit_frame = framedata.get_first_hit_frame_by_name(char_str, "capture_and_deadly_blow", "HK")
            data.hitboxes = framedata.get_hitboxes_by_name(char_str, "capture_and_deadly_blow", "HK", data.hit_frame)
            data.hit_frame = data.hit_frame + 14
            data.range = framedata.get_hitbox_max_range_by_name(char_str, "capture_and_deadly_blow", "HK")
            name = "b_MP"
         end
         local kara_dist = framedata.get_kara_distance_by_name(char_str, name)
         data.range = data.range + kara_dist
         data.type = "throw"
      elseif move_name == "kara_karakusa_lk" then
         data.hit_frame = framedata.get_first_hit_frame_by_name(char_str, "karakusa", "HK")
         data.hitboxes = framedata.get_hitboxes_by_name(char_str, "karakusa", "HK", data.hit_frame)
         data.hit_frame = data.hit_frame + 8
         data.min_range = 97
         data.range = data.range + 41
         data.type = "throw"
      elseif move_name == "gohadouken_HP" then
         data.hit_frame = 7
         data.hitboxes = framedata.get_hitboxes(char_str, "C6", 0)
         data.range = 140
      elseif move_name == "hadouken_EXP" then
         data.hit_frame = 8
         data.hitboxes = framedata.get_hitboxes(char_str, "03", 0)
         data.range = 140
      elseif move_name == "ndl_EXP" then
         data.hit_frame = 8
         data.hitboxes = framedata.get_hitboxes(char_str, "01_ndl_exp", 0)
         data.range = 140
      end
      menu_move_names[#menu_move_names + 1] = "menu_" .. move_name
      moves[#moves + 1] = {data = data, default_weight = 1, weight = 1}
   end
end

local function create_settings()
   local data = {match_savestate_player = "", match_savestate_dummy = "", characters = {}}
   for i, char in ipairs(require("src.modules.game_data").characters) do
      init(char)
      data.characters[char] = {}
      data.characters[char].score = 0
      data.characters[char].walk_out = true
      data.characters[char].accuracy = {80, 80}
      data.characters[char].dist_judgement = {80, 80}
      data.characters[char].moves = {}
      for j, move in ipairs(moves) do data.characters[char].moves[#data.characters[char].moves + 1] = false end
   end
   return data
end

local attack = {action = followup_attack, default_weight = 0.2}
local walk_in = {action = followup_walk_in, default_weight = 1}
local walk_out = {action = followup_walk_out, default_weight = 1}
local reset_distance = {action = followup_reset_distance, default_weight = 1}
local block = {action = followup_block, default_weight = 1}
local followups = {attack, walk_in, walk_out}

walk_in_followups = {{action = followup_attack, default_weight = 1, weight = 1, active = true}, walk_out}
walk_out_followups = {{action = followup_attack, default_weight = 1, weight = 1, active = true}, walk_in}

local function get_menu_move_names() return menu_move_names end
local function get_moves() return moves end
local function get_followups() return followups end
local function select_attack(player)
   local valid_moves = {}
   for i, move in ipairs(moves) do if move.active then valid_moves[#valid_moves + 1] = move end end
   current_attack = tools.select_weighted(valid_moves)
   if not current_attack then current_attack = moves[1] end
   current_attack.data.should_hit = math.random() < accuracy / 100
   local distance_judgement_range = distance_judgement_max - distance_judgement_max * distance_judgement / 100
   local offset = tools.random_quadratic(0, distance_judgement_range, 0, 0.6)
   if current_attack.data.should_hit then offset = -1 + offset * -1 end
   current_attack.data.execute_range = math.max(current_attack.data.range + offset,
                                                framedata.get_contact_distance(player) - 1)
   if current_attack.data.min_range then
      current_attack.data.execute_range = math.max(current_attack.data.execute_range, current_attack.data.min_range)
   end
   walk_in_range = walk_in_range_min + offset
end
local function get_current_attack() return current_attack end
local function reset_weights()
   for _, setup in ipairs(moves) do setup.weight = setup.default_weight end
   attack.weight = attack.default_weight
   walk_in.weight = walk_in.default_weight
   walk_out.weight = walk_out.default_weight
end

local footsies_tables = {
   init = init,
   reset_weights = reset_weights,
   get_menu_move_names = get_menu_move_names,
   get_moves = get_moves,
   get_followups = get_followups,
   create_settings = create_settings,
   select_attack = select_attack,
   get_current_attack = get_current_attack,
   reset_distance = reset_distance,
   attack = attack,
   walk_in = walk_in,
   walk_out = walk_out,
   block = block,
   update_walk_time = update_walk_time,
   update_recent_attacks = update_recent_attacks
}

setmetatable(footsies_tables, {
   __index = function(_, key)
      if key == "accuracy" then
         return accuracy
      elseif key == "distance_judgement" then
         return distance_judgement
      end
   end,

   __newindex = function(_, key, value)
      if key == "accuracy" then
         accuracy = value
      elseif key == "distance_judgement" then
         distance_judgement = value
      else
         rawset(footsies_tables, key, value)
      end
   end
})

return footsies_tables
