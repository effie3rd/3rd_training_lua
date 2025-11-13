local gamestate = require "src.gamestate"
local inputs = require("src.control.inputs")
local character_select = require("src.control.character_select")
local hud = require("src.ui.hud")
local settings = require("src.settings")
local game_data = require("src.modules.game_data")
local tools = require("src.tools")
local advanced_control = require("src.control.advanced_control")
local training_classes = require("src.training.training_classes")
local training = require("src.training")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local geneijin_tables = require("src.training.geneijin_tables")
local framedata = require("src.modules.framedata")

local module_name = "geneijin"

local is_active = false
local states = {
   SETUP_MATCH_START = 1,
   SETUP_GENEIJIN = 2,
   SETUP_WAKEUP = 3,
   SELECT_SETUP = 4,
   SETUP = 5,
   WAIT_FOR_SETUP = 6,
   SELECT_FOLLOWUP = 7,
   FOLLOWUP = 8,
   RUNNING = 9,
   BEFORE_END = 10,
   END = 11
}

local state = states.SETUP_MATCH_START

local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/geneijin_match_start.fs")

local action_queue = {}
local actions = {}
local i_actions = 1

local score = 0
local delta_score = 0

local geneijin_activate_frame = 0

local player = gamestate.P1
local dummy = gamestate.P2

local followup_timeout = 3 * 60
local followup_start_frame = 0
local has_attacked = false
local is_player_wakeup = false

local end_delay = 10
local end_frame = 0

local score_display_time = 40
local score_fade_time = 20
local score_min_y = 60

local function apply_settings()
   for i, p_setup in ipairs(geneijin_tables.get_moves()) do
      p_setup.active = settings.special_training.geneijin.moves[i]
   end
end

local old_settings = {
   life_mode = settings.training.life_mode,
   stun_mode = settings.training.stun_mode,
   meter_mode = settings.training.meter_mode,
   infinite_time = settings.training.infinite_time,
   infinite_sa_time = settings.training.infinite_sa_time
}

local function ensure_training_settings()
   old_settings = {
      life_mode = settings.training.life_mode,
      stun_mode = settings.training.stun_mode,
      meter_mode = settings.training.meter_mode,
      infinite_time = settings.training.infinite_time,
      infinite_sa_time = settings.training.infinite_sa_time
   }
   settings.training.life_mode = 4
   settings.training.stun_mode = 3
   settings.training.meter_mode = 5
   settings.training.infinite_time = true
   settings.training.infinite_sa_time = true
   training.disable_dummy = {false, true}
end

local function restore_training_settings()
   settings.training.life_mode = old_settings.life_mode
   settings.training.stun_mode = old_settings.stun_mode
   settings.training.meter_mode = old_settings.meter_mode
   settings.training.infinite_time = old_settings.infinite_time
   settings.training.infinite_sa_time = old_settings.infinite_sa_time
   training.disable_dummy = {false, false}
end

local function replace_followups(index, followup)
   action_queue[index] = followup
   actions[index] = followup.action
   while action_queue[index + 1] do
      table.remove(action_queue, index + 1)
      table.remove(actions, index + 1)
   end
end

local function display_delta_score(d_score)
   if d_score == 0 then return end
   local score_text
   local score_color
   local x, y
   if d_score > 0 then
      score_text = string.format("+%d", d_score)
      score_color = colors.score.plus
   else
      score_text = string.format("%d", d_score)
      score_color = colors.score.minus
   end
   x, y = draw.get_above_character_position(player)
   y = math.max(y, score_min_y)
   hud.add_fading_text(x, y - 4, score_text, "en", score_color, score_display_time, score_fade_time, true)
end

local function start()
   inputs.block_input(1, "all")
   inputs.block_input(2, "all")
   ensure_training_settings()
   Register_After_Load_State(function()
      is_active = true
      player = gamestate.P1
      dummy = gamestate.P2
      require("src.control.recording").set_recording_state(inputs.input, 1)
      geneijin_tables.init()
      apply_settings()
      geneijin_tables.reset_weights()
      score = 0
      state = states.SELECT_SETUP
   end)
   Queue_Command(gamestate.frame_number + 1, function() savestate.load(match_start_state) end)
end

local function start_character_select()
   state = states.SETUP_MATCH_START
   ensure_training_settings()
   Register_After_Load_State(function()
      is_active = true
      player = gamestate.P1
      dummy = gamestate.P2
      require("src.control.recording").set_recording_state(inputs.input, 1)
      training.reset_swap_characters()
      geneijin_tables.init()
      apply_settings()
      geneijin_tables.reset_weights()
      score = 0
   end)

   Register_After_Load_State(character_select.force_select_character, {2, "yun", 3, "random"})
   character_select.start_character_select_sequence()
end

local function stop()
   if is_active then
      is_active = false
      hud.clear_info_text()
      hud.clear_score_text()
      advanced_control.clear_all()
      restore_training_settings()
      training.disable_dummy = {false, false}
      inputs.unblock_input(1)
      inputs.unblock_input(2)
   end
end

local function reset() is_active = false end

local function update()
   if is_active then
      if gamestate.is_before_curtain or gamestate.is_in_match then
         if state == states.SETUP_MATCH_START or state == states.SETUP_GENEIJIN then
            inputs.block_input(1, "all")
            inputs.block_input(2, "all")
         end
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
            emu.speedmode("turbo")
            settings.special_training.geneijin.match_savestate_player = gamestate.P1.char_str
            settings.special_training.geneijin.match_savestate_dummy = gamestate.P2.char_str
            Queue_Command(gamestate.frame_number + 2, inputs.queue_input_sequence,
                          {dummy, geneijin_tables.get_geneijin_input()})
            geneijin_activate_frame = math.huge
            state = states.SETUP_GENEIJIN
         elseif state == states.SETUP_GENEIJIN then
            if dummy.is_in_timed_sa then
               if dummy.superfreeze_just_ended then geneijin_activate_frame = gamestate.frame_number end
               if gamestate.frame_number - geneijin_activate_frame >= 12 then
                  savestate.save(match_start_state)
                  emu.speedmode("normal")
                  inputs.unblock_input(1)
                  inputs.unblock_input(2)
                  state = states.SELECT_SETUP
               end
            end
         end
         if state == states.SELECT_SETUP then
            action_queue = {}
            actions = {}
            i_actions = 0
            has_attacked = false
            state = states.SELECT_FOLLOWUP
         end
         if state == states.SELECT_FOLLOWUP then
            local next_move
            if not action_queue[i_actions] or actions[i_actions].type == training_classes.Action_Type.WALK_FORWARD or
                action_queue[i_actions] == geneijin_tables.pause then
               local should_walk = false
               local should_block = false
               is_player_wakeup = false

               if dummy.is_waking_up then
                  should_block = true
                  next_move = geneijin_tables.block
               elseif player.is_waking_up or player.is_airborne then
                  is_player_wakeup = true
                  local dist = math.abs(player.other.pos_x - player.pos_x)
                  if dist > framedata.get_contact_distance(player) + 4 then
                     should_walk = true
                     next_move = geneijin_tables.walk_in
                     if geneijin_tables.crab_walk.active then
                        if dist > 150 then next_move = geneijin_tables.crab_walk end
                     end
                  end
               end

               if not (should_walk or should_block) then
                  local valid_moves = {}
                  local n_throws = 0
                  local moves = geneijin_tables.get_moves()
                  for i, move in ipairs(moves) do
                     if move.active and move.action:should_execute(dummy, gamestate.stage, actions, i_actions) then
                        if move == geneijin_tables.pause then
                        elseif move.action.type == training_classes.Action_Type.THROW then
                           if not (action_queue[i_actions] == geneijin_tables.pause) then
                              table.insert(valid_moves, move)
                              n_throws = n_throws + 1
                           end
                        else
                           table.insert(valid_moves, move)
                        end
                     end
                  end
                  if n_throws > 0 then
                     local zenpou_weight = 0.3
                     if player.is_waking_up then zenpou_weight = 0.1 end
                     for i, move in ipairs(valid_moves) do
                        if move.action.type == training_classes.Action_Type.THROW then
                           move.weight = move.default_weight * zenpou_weight / n_throws
                        else
                           move.weight = move.default_weight * (1 - zenpou_weight) / (#valid_moves - n_throws)
                        end
                     end
                  end
                  next_move = tools.select_weighted(valid_moves)
               end
            end
            if not next_move then
               local valid_moves = {}
               for i, move in ipairs({geneijin_tables.walk_in, geneijin_tables.pause}) do
                  if move.active and move.action:should_execute(dummy, gamestate.stage, actions, i_actions) then
                     table.insert(valid_moves, move)
                  end
               end
               next_move = tools.select_weighted(valid_moves) or geneijin_tables.walk_in
            end
            table.insert(action_queue, next_move)
            table.insert(actions, next_move.action)
            state = states.FOLLOWUP
         end
         if state == states.FOLLOWUP then
            i_actions = i_actions + 1
            local next_move = action_queue[i_actions]
            advanced_control.queue_programmed_movement(dummy, next_move.action:setup(dummy, gamestate.stage, actions,
                                                                                     i_actions))
            if next_move.action.type == training_classes.Action_Type.ATTACK or next_move.action.type ==
                training_classes.Action_Type.THROW then
               has_attacked = true
               is_player_wakeup = false
            end
            followup_start_frame = gamestate.frame_number
            state = states.RUNNING
         end
         if state == states.RUNNING then
            local followup = action_queue[i_actions]
            if followup then
               local finished, result = followup.action:run(dummy, gamestate.stage, actions, i_actions)
               if finished then
                  delta_score = 0
                  state = states.SELECT_FOLLOWUP
                  if result.should_punish then
                     replace_followups(i_actions + 1, geneijin_tables.punish)
                     state = states.FOLLOWUP
                  elseif result.should_block then
                     replace_followups(i_actions + 1, geneijin_tables.block)
                     state = states.FOLLOWUP
                  elseif result.should_reselect then
                     replace_followups(i_actions + 1, geneijin_tables.get_attack())
                     state = states.FOLLOWUP
                  else
                     delta_score = result.score
                  end
                  if result.should_end then
                     end_frame = gamestate.frame_number + end_delay
                     state = states.BEFORE_END
                     update()
                     return
                  end
                  update()
                  return
               end
               if gamestate.frame_number - followup_start_frame >= followup_timeout then
                  end_frame = gamestate.frame_number + end_delay
                  delta_score = 0
                  state = states.BEFORE_END
               end
            end
            if player.superfreeze_just_began and followup.action ~= geneijin_tables.block.action then
               replace_followups(i_actions + 1, geneijin_tables.block)
               state = states.FOLLOWUP
               update()
               return
            end
         end
         if state == states.BEFORE_END then
            if not (is_player_wakeup and delta_score > 0) and has_attacked then
               score = math.max(score + delta_score, 0)
               if score > settings.special_training.geneijin.score then
                  settings.special_training.geneijin.score = score
               end
               display_delta_score(delta_score)
            end
            state = states.END
         end
         if state == states.END then
            if gamestate.frame_number >= end_frame then
               if not (dummy.character_state_byte == 1 or dummy.character_state_byte == 3) or dummy.is_waking_up then
                  state = states.SELECT_SETUP
               end
            end
         end

         hud.add_score_text(score)
      end
   end
end

local function process_gesture(gesture) end

local geneijin = {
   module_name = module_name,
   start_character_select = start_character_select,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture
}

setmetatable(geneijin, {
   __index = function(_, key) if key == "is_active" then return is_active end end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      else
         rawset(geneijin, key, value)
      end
   end
})

return geneijin
