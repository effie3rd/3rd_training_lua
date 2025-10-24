local settings = require("src.settings")
local gamestate = require("src.gamestate")
local training = require("src.training")
local fd = require("src.modules.framedata")
local prediction = require("src.modules.prediction")
local frame_data, is_slow_jumper, is_really_slow_jumper = fd.frame_data, fd.is_slow_jumper, fd.is_really_slow_jumper
local memory_addresses = require("src.control.memory_addresses")
local inputs = require("src.control.inputs")

local frames_prediction = 15

local programmed_movement_queue = {}

local function queue_programmed_movement(player, commands)
   programmed_movement_queue[player] = {}
   programmed_movement_queue[player].commands = commands
   programmed_movement_queue[player].index = 1
   programmed_movement_queue[player].pause_until = 0
end

local function clear_programmed_movement(player) programmed_movement_queue[player] = nil end

local function update_programmed_movement()
   for _, prog in pairs(programmed_movement_queue) do
      local commands = prog.commands
      local exit_loop = true
      repeat
         exit_loop = true
         if gamestate.frame_number >= prog.pause_until and prog.index <= #commands then
            if commands[prog.index].condition == nil or commands[prog.index].condition() then
               if commands[prog.index].action then commands[prog.index].action() end
               prog.index = prog.index + 1
               exit_loop = false
            end
         end
      until exit_loop
   end
end

local function all_commands_queued(player)
   if not programmed_movement_queue[player] then return true end
   if programmed_movement_queue[player] then
      return programmed_movement_queue[player].index > #programmed_movement_queue[player].commands
   end
   return true
end

local function all_commands_complete(player)
   if not programmed_movement_queue[player] then return true end
   if programmed_movement_queue[player] and programmed_movement_queue[player].index >
       #programmed_movement_queue[player].commands and gamestate.frame_number >=
       programmed_movement_queue[player].pause_until then return true end
   return false
end

local function queue_input_sequence_and_wait(player, sequence, offset, precise)
   local wait_offset = 2
   if precise then wait_offset = 0 end
   inputs.queue_input_sequence(player, sequence, offset, true)
   programmed_movement_queue[player].pause_until = gamestate.frame_number + #sequence + wait_offset
end

local function is_idle_timing(player, offset, precise)
   -- print(gamestate.frame_number, prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction))
   if not precise then offset = offset + 1 end
   if player.superfreeze_decount > 0 then return false end
   if player.has_just_parried then return 15 < offset end
   if offset <= 0 then return player.is_idle and player.idle_time >= -offset end
   if player.is_in_recovery then
      return player.recovery_time + player.additional_recovery_time < offset
   end
   return player.remaining_freeze_frames +
              prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <
              offset
end

local function is_wakeup_timing(player, offset, precise)
   if player.standing_state > 0 then return true end
   if not precise then offset = offset + 1 end
   if offset <= 0 then return true end
   local wakeup_time = player.remaining_wakeup_time
   return wakeup_time > 0 and wakeup_time < 20 and wakeup_time + 1 < offset
end

local function is_landing_timing(player, offset, precise)
   if player.is_standing or player.is_crouching then return true end
   if not precise then offset = offset + 1 end
   local frames_until = prediction.predict_frames_before_landing(player)
   return frames_until > 0 and frames_until < offset
end

local function is_throw_vulnerable_timing(player, offset, precise)
   if not precise then offset = offset + 1 end
   if offset <= 0 then return player.throw_invulnerability_cooldown == 0 and player.throw_recovery_frame >= -offset end
   return player.throw_invulnerability_cooldown < offset
end

local Delay = {}
Delay.__index = Delay

function Delay:new(delay)
   local obj = {delay = delay, first_run = true, end_frame = 0, start_frame = 0}

   setmetatable(obj, self)
   return obj
end

function Delay:reset(n)
   self.first_run = true
   if n then self.delay = n end
end

function Delay:extend(n)
   self.end_frame = self.end_frame + n
end

function Delay:begin(n)
   if n then self.delay = n end
   self.first_run = false
   self.end_frame = gamestate.frame_number + self.delay
   self.start_frame = gamestate.frame_number
end

function Delay:is_complete()
   if self.first_run then
      self.end_frame = gamestate.frame_number + self.delay
      self.first_run = false
      self.start_frame = gamestate.frame_number
      if self.delay == 0 then return true end
   end
   return gamestate.frame_number >= self.end_frame
end

function Delay:delay_after_idle(player)
   if self.first_run then
      if player.is_idle then
         self.end_frame = gamestate.frame_number + self.delay
         self.first_run = false
         if self.delay == 0 then return true end
      end
   else
      return gamestate.frame_number >= self.end_frame
   end
   return false
end

function Delay:delay_after_hit(player)
   if self.first_run then
      if player.has_just_hit then
         self.end_frame = gamestate.frame_number + self.delay
         self.first_run = false
         if self.delay == 0 then return true end
      end
   else
      return gamestate.frame_number >= self.end_frame
   end
   return false
end

function Delay:delay_after_connection(player)
   if self.first_run then
      if player.has_just_connected then
         self.end_frame = gamestate.frame_number + self.delay
         self.first_run = false
         if self.delay == 0 then return true end
      end
   else
      return gamestate.frame_number >= self.end_frame
   end
   return false
end

function Delay:delay_after_idle_timing(player, offset, precise)
   if not precise then offset = offset + 1 end
   if is_idle_timing(player, offset, precise) then
      if self.first_run then
         self.end_frame = gamestate.frame_number + self.delay
         self.first_run = false
         if self.delay == 0 then return true end
      else
         return gamestate.frame_number >= self.end_frame
      end
   end
   return false
end

function Delay:delay_after_landing_timing(player, offset, precise)
   if not precise then offset = offset + 1 end
   if is_landing_timing(player, offset, precise) then
      if self.first_run then
         self.end_frame = gamestate.frame_number + self.delay
         self.first_run = false
         if self.delay == 0 then return true end
      else
         return gamestate.frame_number >= self.end_frame
      end
   end
   return false
end

local function update(input, player, dummy)
   update_programmed_movement()
   -- print(prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction))
end
local function clear_all() programmed_movement_queue = {} end

-- move into range then move out

local advanced_control = {
   Delay = Delay,
   queue_input_sequence_and_wait = queue_input_sequence_and_wait,
   is_idle_timing = is_idle_timing,
   is_wakeup_timing = is_wakeup_timing,
   is_landing_timing = is_landing_timing,
   is_throw_vulnerable_timing = is_throw_vulnerable_timing,
   update = update,
   clear_all = clear_all,
   queue_programmed_movement = queue_programmed_movement,
   clear_programmed_movement = clear_programmed_movement,
   all_commands_queued = all_commands_queued,
   all_commands_complete = all_commands_complete
}

return advanced_control
