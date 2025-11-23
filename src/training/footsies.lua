local gamestate = require "src.gamestate"
local inputs = require("src.control.inputs")
local hud = require("src.ui.hud")
local settings = require("src.settings")
local tools = require("src.tools")
local training_classes = require("src.training.training_classes")
local footsies_tables = require("src.training.footsies_tables")
local advanced_control = require("src.control.advanced_control")
local training = require("src.training")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local debug = require("src.debug")

local module_name = "footsies"

local is_active = false
local states = {
   SETUP_MATCH_START = 1,
   SETUP_WAKEUP_BEGIN = 2,
   SETUP_WAKEUP = 3,
   SELECT_SETUP = 4,
   SETUP = 5,
   WAIT_FOR_SETUP = 6,
   FOLLOWUP = 7,
   RUNNING = 8,
   BEFORE_END = 9,
   END = 10
}
local state = states.SETUP_MATCH_START

-- local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/footsies_match_start.fs")

local footsies_player = gamestate.P1
local footsies_dummy = gamestate.P2

local action_queue = {}
local actions = {}
local i_actions = 1

local followup_timeout = 6 * 60
local followup_start_frame = 0
local has_attacked = false
local is_player_wakeup = false
local end_delay_min = 0
local end_delay_max = 30
local end_frame = 0
local score = 0
local delta_score = 0
local score_display_time = 40
local score_fade_time = 20
local score_min_y = 60

local function apply_settings()
   for i, p_setup in ipairs(footsies_tables.get_moves()) do
      p_setup.active = settings.special_training.footsies.characters[footsies_dummy.char_str].moves[i]
   end
   footsies_tables.walk_out.active = settings.special_training.footsies.characters[footsies_dummy.char_str].walk_out
   footsies_tables.walk_in.active = true
   footsies_tables.attack.active = true
   footsies_tables.accuracy = settings.special_training.footsies.characters[footsies_dummy.char_str].accuracy[1]
   footsies_tables.distance_judgement = settings.special_training.footsies.characters[footsies_dummy.char_str].dist_judgement[1]
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
   x, y = draw.get_above_character_position(footsies_player)
   y = math.max(y, score_min_y)
   hud.add_fading_text(x, y - 4, score_text, "en", score_color, score_display_time, score_fade_time, true)
end

local function start()
   is_active = true
   footsies_player = gamestate.P1
   footsies_dummy = gamestate.P2
   require("src.control.recording").set_recording_state(inputs.input, 1)
   ensure_training_settings()
   footsies_tables.init(footsies_dummy.char_str)
   apply_settings()
   footsies_tables.reset_weights()
   score = 0
   state = states.SELECT_SETUP
end

local function start_character_select()
end

local function stop()
   if is_active then
      is_active = false
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
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
         elseif state == states.SELECT_SETUP then
            footsies_player = gamestate.P1
            footsies_dummy = gamestate.P2

            action_queue = {}
            actions = {}
            i_actions = 0
            has_attacked = false

            if footsies_dummy.is_waking_up or (footsies_player.character_state_byte == 1 and footsies_player.posture == 24) then
               action_queue[#action_queue + 1] = footsies_tables.block
               actions[#actions + 1] = footsies_tables.block.action
            elseif footsies_player.is_waking_up then
               action_queue[#action_queue + 1] = footsies_tables.reset_distance
               actions[#actions + 1] = footsies_tables.reset_distance.action
            else
               footsies_tables.select_attack(footsies_dummy)
               local n_walk_out = 0
               local followups = footsies_tables.get_followups()
               while followups do
                  local valid_moves = {}
                  for i, p_followup in ipairs(followups) do
                     if p_followup.active and
                         p_followup.action:is_valid(footsies_dummy, gamestate.stage, actions, i_actions) then
                        if p_followup == footsies_tables.walk_out then
                           p_followup.weight = math.min(footsies_tables.walk_out.default_weight - n_walk_out ^ 0.6, 1)
                        end
                        valid_moves[#valid_moves + 1] = p_followup
                     end
                  end
                  local selected_followup = tools.select_weighted(valid_moves)
                  if selected_followup then
                     if selected_followup == footsies_tables.walk_out then
                        n_walk_out = n_walk_out + 1
                     end
                     action_queue[#action_queue + 1] = selected_followup
                     actions[#actions + 1] = selected_followup.action
                     followups = selected_followup.action:followups()
                  else
                     followups = nil
                  end
               end
               if #action_queue == 0 then
                  action_queue[#action_queue + 1] = footsies_tables.reset_distance
                  actions[#actions + 1] = footsies_tables.reset_distance.action
               end
            end

            state = states.FOLLOWUP
         end
         if state == states.FOLLOWUP then
            i_actions = i_actions + 1
            local next_move = action_queue[i_actions]
            if next_move then
               if not next_move.action:should_execute(footsies_dummy, gamestate.stage, actions, i_actions) then
                  state = states.BEFORE_END
                  update()
                  return
               end
               advanced_control.queue_programmed_movement(footsies_dummy, next_move.action:setup(footsies_dummy,
                                                                                                 gamestate.stage,
                                                                                                 actions, i_actions))
               if next_move.action.type == training_classes.Action_Type.ATTACK or next_move.action.type ==
                   training_classes.Action_Type.THROW then has_attacked = true end
               followup_start_frame = gamestate.frame_number
               state = states.RUNNING
            else
               state = states.BEFORE_END
            end
         end
         if state == states.RUNNING then
            footsies_tables.update_walk_time(footsies_player)
            footsies_tables.update_recent_attacks(footsies_player)
            local followup = action_queue[i_actions]
            if followup then
               local finished, result = followup.action:run(footsies_dummy, gamestate.stage, actions, i_actions)
               if finished then
                  delta_score = 0
                  state = states.FOLLOWUP
                  if result.should_punish then
                     replace_followups(i_actions + 1, footsies_tables.punish)
                  elseif result.should_block then
                     replace_followups(i_actions + 1, footsies_tables.block)
                  else
                     delta_score = result.score
                  end
                  if result.should_end then
                     if followup.action.type == training_classes.Action_Type.ATTACK then
                        end_frame = gamestate.frame_number + math.random(end_delay_min, end_delay_max)
                     else
                        end_frame = gamestate.frame_number + end_delay_min
                     end
                     state = states.BEFORE_END
                     update()
                     return
                  end
                  update()
                  return
               end
               if gamestate.frame_number - followup_start_frame >= followup_timeout then
                  end_frame = gamestate.frame_number + end_delay_min
                  delta_score = 0
                  state = states.BEFORE_END
               end
            end
            if footsies_player.superfreeze_just_began and followup.action ~= footsies_tables.block.action then
               replace_followups(i_actions + 1, footsies_tables.block)
               state = states.FOLLOWUP
               update()
               return
            end
         end
         if state == states.BEFORE_END then
            if not (is_player_wakeup and delta_score > 0) and has_attacked then
               score = math.max(score + delta_score, 0)
               if score > settings.special_training.footsies.characters[footsies_dummy.char_str].score then
                  settings.special_training.footsies.characters[footsies_dummy.char_str].score = score
               end
               -- display_delta_score(delta_score)
            end
            state = states.END
         end
         if state == states.END then
            if gamestate.frame_number >= end_frame then
               if not (footsies_dummy.character_state_byte == 1 or footsies_dummy.character_state_byte == 2 or footsies_dummy.character_state_byte == 3 or
                   footsies_dummy.character_state_byte == 4) or footsies_dummy.is_waking_up then
                  state = states.SELECT_SETUP
               end
            end
         end

         -- hud.add_score_text(score)
      end
   end
end

debug.add_debug_variable("footsies_state", function () return state end)

local function process_gesture(gesture) end

local footsies = {
   module_name = module_name,
   start_character_select = start_character_select,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture
}

setmetatable(footsies, {
   __index = function(_, key)
      if key == "is_active" then
         return is_active
      elseif key == "footsies_player" then
         return footsies_player
      elseif key == "footsies_dummy" then
         return footsies_dummy
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      else
         rawset(footsies, key, value)
      end
   end
})

return footsies
