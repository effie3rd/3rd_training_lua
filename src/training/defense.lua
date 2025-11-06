local gamestate = require "src.gamestate"
local inputs = require("src.control.inputs")
local character_select = require("src.control.character_select")
local hud = require("src.ui.hud")
local settings = require("src.settings")
local frame_data = require("src.modules.framedata")
local game_data = require("src.modules.game_data")
local stage_data = require("src.modules.stage_data")
local tools = require("src.tools")
local mem = require("src.control.write_memory")
local advanced_control = require("src.control.advanced_control")
local write_memory = require("src.control.write_memory")
local memory_addresses = require("src.control.memory_addresses")
local defense_tables = require("src.training.defense_tables")
local training_classes = require("src.training.training_classes")
local training = require("src.training")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")

local module_name = "defense"

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

local setup_states = {INIT = 1, SET_POSITIONS = 2, MOVE_PLAYERS = 3, CONTINUE_SETUP = 4}

local state

local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/defense_match_start.fs")
local wakeup_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/defense_wakeup.fs")

local defense_data

local action_queue = {}
local actions = {}
local i_actions = 1
local labels = {}
local i_labels = 0

local should_adjust_weights = true
local score = 0
local delta_score = 0

local setup_state = setup_states.INIT
local setup_start_frame = 0

local player = gamestate.P1
local dummy = gamestate.P2
local opponent
local player_reset_x = 0
local dummy_reset_x = 0

local should_hard_setup = true
local should_block_input = false
local hard_setup_delay = 16
local soft_setup_delay = 16
local setup_timeout = 100
local min_position_speed = 8

local setup_wakeup_start_frame = 0
local screen_shake_delay = 16

local followup_timeout = 3 * 60
local followup_start_frame = 0

local end_delay = 40
local end_super_delay = 20
local end_wait_delay = 10
local end_frame = 0
local end_frame_extension = 0
local end_frame_extension_limit = 50

local score_display_time = 40
local score_fade_time = 20
local score_min_y = 60

local learning_rate = 0.4
local min_weight = 0.05
local max_weight = 1

local function apply_settings()
   opponent = defense_tables.opponents[settings.special_training.defense.opponent]
   defense_data = defense_tables.get_defense_data(opponent)
   for i, p_setup in ipairs(defense_data.setups) do
      p_setup.active = settings.special_training.defense.characters[opponent].setups[i]
   end
   for i, p_followup in ipairs(defense_data.followups) do
      for j, p_followup_followup in ipairs(p_followup.list) do
         p_followup_followup.active = settings.special_training.defense.characters[opponent].followups[i][j]
      end
   end
end

local old_settings = {
   life_mode = settings.training.life_mode,
   stun_mode = settings.training.stun_mode,
   meter_mode = settings.training.meter_mode,
   infinite_time = settings.training.infinite_time
}

local function ensure_training_settings()
   old_settings = {
      life_mode = settings.training.life_mode,
      stun_mode = settings.training.stun_mode,
      meter_mode = settings.training.meter_mode,
      infinite_time = settings.training.infinite_time
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
   training.disable_dummy = {false, false}
end

local function reselect_followups(index)
   index = index + 1
   while action_queue[index] do
      table.remove(action_queue, index)
      table.remove(actions, index)
   end
   local followups = action_queue[#action_queue].action:followups()

   while followups do
      local selected_followups = {}
      for i, p_followup in ipairs(followups) do
         if p_followup.active and p_followup.action:is_valid(dummy, gamestate.stage, actions, index) and
             p_followup.action:should_execute(dummy, gamestate.stage, actions, index) then
            table.insert(selected_followups, p_followup)
         end
      end
      local selected_followup = tools.select_weighted(selected_followups)
      if selected_followup then
         table.insert(action_queue, selected_followup)
         table.insert(actions, selected_followup.action)
         followups = selected_followup.action:followups()
      else
         followups = nil
      end
      index = index + 1
   end
end

local function replace_followups(index, followup)
   action_queue[index] = followup
   actions[index] = followup.action
   while action_queue[index + 1] do
      table.remove(action_queue, index + 1)
      table.remove(actions, index + 1)
   end
end

local function remove_followups(index)
   while action_queue[index] do
      table.remove(action_queue, index)
      table.remove(actions, index)
      table.remove(labels, index)
   end
end

local function insert_followup(index, followup)
   for i = #action_queue + 1, index + 1 do
      action_queue[i] = action_queue[i - 1]
      actions[i] = actions[i - 1]
   end
   action_queue[index] = followup
   actions[index] = followup.action
end

local function check_setup_timeout()
   if gamestate.frame_number - setup_start_frame >= setup_timeout then
      state = states.SETUP
      setup_state = setup_states.INIT
      print("SETUP FAILED", player_reset_x, player.pos_x, dummy_reset_x, dummy.pos_x) -- debug
   end
end

local function bound_setup_positions(setup)
   local current_stage = stage_data.stages[gamestate.stage]
   local player_left, player_right = setup:get_soft_reset_range(dummy, gamestate.stage)[1],
                                     setup:get_soft_reset_range(dummy, gamestate.stage)[2]
   local player_sign = tools.sign(player.pos_x - dummy.pos_x)
   local dummy_sign = tools.sign(dummy.pos_x - player.pos_x)
   local dummy_left = current_stage.left + frame_data.character_specific[dummy.char_str].corner_offset_left
   local dummy_right = current_stage.right - frame_data.character_specific[dummy.char_str].corner_offset_right
   if player_reset_x < player_left then
      player_reset_x = player_left
      dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
   end
   if player_reset_x > player_right then
      player_reset_x = player_right
      dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
   end
   if dummy_reset_x < dummy_left then
      dummy_reset_x = dummy_left
      player_reset_x = dummy_reset_x + player_sign * setup:get_dummy_offset(dummy)
   end
   if dummy_reset_x > dummy_right then
      dummy_reset_x = dummy_right
      player_reset_x = dummy_reset_x + player_sign * setup:get_dummy_offset(dummy)
   end
end

local allowed_actions = {
   [0] = true,
   [1] = true,
   [2] = true,
   [3] = true,
   [6] = true,
   [7] = true,
   [8] = true,
   [11] = true
}

local function hard_setup()
   if setup_state == setup_states.INIT then
      local should_load = inputs.problematic_inputs_released(joypad.get(), player.id)
      if should_load then
         local setup = action_queue[1].action
         local dummy_sign = tools.sign(dummy.pos_x - player.pos_x)
         player_reset_x = player.pos_x
         dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
         bound_setup_positions(setup)

         Register_After_Load_State(function()
            is_active = true
            setup_start_frame = gamestate.frame_number
            player = gamestate.P1
            dummy = gamestate.P2
            training.disable_dummy = {false, true}
         end)
         setup_state = setup_states.SET_POSITIONS

         if action_queue[1] == defense_data.wakeup then
            savestate.load(wakeup_state)
         else
            savestate.load(match_start_state)
         end
      end
   elseif setup_state == setup_states.SET_POSITIONS then
      local setup = action_queue[1].action
      local is_wakeup = action_queue[1] == defense_data.wakeup
      mem.write_pos(player, player_reset_x, 0)
      mem.write_pos(dummy, dummy_reset_x, 0)
      mem.write_flip_x(player, bit.bxor(dummy.flip_x, 1))
      if not is_wakeup and not allowed_actions[player.action] then
         state = states.SETUP
         setup_state = setup_states.INIT
      end
      local current_screen_x = memory.readword(memory_addresses.global.screen_pos_x)
      local desired_screen_x, desired_screen_y = mem.get_fix_screen_pos(player, dummy, gamestate.stage), 0
      if current_screen_x ~= desired_screen_x then
         write_memory.set_screen_pos(desired_screen_x, desired_screen_y)
      elseif gamestate.frame_number - setup_start_frame >= hard_setup_delay and player.is_standing and player.action ==
          0 or is_wakeup then
         advanced_control.queue_programmed_movement(dummy, setup:setup(dummy))
         state = states.WAIT_FOR_SETUP
      end
   end
end

local function move_players(should_move_player, should_move_dummy)
   if should_move_player then
      local player_sign = tools.sign(player_reset_x - player.pos_x)
      local position_speed = min_position_speed
      if player.is_waking_up and player.remaining_wakeup_time > 0 then
         local dist = math.abs(player_reset_x - player.pos_x)
         position_speed =
             math.max(math.floor(dist / math.max(player.remaining_wakeup_time - 10, 1)), min_position_speed)
      end
      local next_player_pos = player.pos_x + player_sign * position_speed
      if player_sign > 0 then
         next_player_pos = math.min(next_player_pos, player_reset_x)
      else
         next_player_pos = math.max(next_player_pos, player_reset_x)
      end
      write_memory.write_pos_x(player, next_player_pos)
   end

   if should_move_dummy then
      local dummy_sign = tools.sign(dummy_reset_x - dummy.pos_x)
      local next_dummy_pos = dummy.pos_x + dummy_sign * min_position_speed
      if dummy_sign > 0 then
         next_dummy_pos = math.min(next_dummy_pos, dummy_reset_x)
      else
         next_dummy_pos = math.max(next_dummy_pos, dummy_reset_x)
      end
      write_memory.write_pos_x(dummy, next_dummy_pos)
   end
end

local function soft_setup()
   local setup = action_queue[1].action
   if setup_state == setup_states.INIT then
      setup_start_frame = gamestate.frame_number
      if defense_data.close_distance.action:should_execute(dummy, gamestate.stage, actions, i_actions) then
         advanced_control.queue_programmed_movement(dummy, defense_data.close_distance.action:setup(dummy))
      end
      setup_state = setup_states.SET_POSITIONS
   elseif setup_state == setup_states.SET_POSITIONS then
      if advanced_control.all_commands_complete(dummy) and not inputs.is_playing_input_sequence(dummy) then
         if player.is_waking_up or player.is_idle then
            local player_sign = tools.sign(player.pos_x - dummy.pos_x)
            local dummy_sign = tools.sign(dummy.pos_x - player.pos_x)
            if player.is_waking_up then
               dummy_reset_x = dummy.pos_x
               player_reset_x = dummy_reset_x + player_sign * setup:get_dummy_offset(dummy)
            else
               player_reset_x = player.pos_x
               dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
            end

            bound_setup_positions(setup)
            setup_start_frame = gamestate.frame_number
            setup_state = setup_states.MOVE_PLAYERS
         end
      end
   elseif setup_state == setup_states.MOVE_PLAYERS then
      if (player.is_standing or player.is_crouching or player.is_waking_up) and not dummy.is_being_thrown then
         move_players(true, false)
      end
      if (player.is_standing or player.is_crouching) and
          (player.pos_x ~= player_reset_x or dummy.pos_x ~= dummy_reset_x) then
         mem.write_pos_x(player, player_reset_x)
         mem.write_pos_x(dummy, dummy_reset_x)
         setup_start_frame = gamestate.frame_number + soft_setup_delay
      end
      if dummy.pos_x < dummy_reset_x then
         inputs.press_right(nil, dummy.id)
      elseif dummy.pos_x > dummy_reset_x then
         inputs.press_left(nil, dummy.id)
      end
      if math.abs(dummy.pos_x - dummy_reset_x) <= 4 then mem.write_pos_x(dummy, dummy_reset_x) end
      if (player.is_waking_up or player.is_idle) and dummy.is_idle then
         if player.pos_x == player_reset_x and dummy.pos_x == dummy_reset_x and gamestate.frame_number >=
             setup_start_frame then
            advanced_control.queue_programmed_movement(dummy, setup:setup(dummy))
            state = states.WAIT_FOR_SETUP
         end
      end
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

local function start(sel_player, sel_dummy)
   if settings.special_training.defense.match_savestate_player == sel_player and
       settings.special_training.defense.match_savestate_dummy == sel_dummy then
      inputs.block_input(1, "all")
      inputs.block_input(2, "all")
      ensure_training_settings()
      Register_After_Load_State(function()
         is_active = true
         player = gamestate.P1
         dummy = gamestate.P2
         ensure_training_settings()
         apply_settings()
         defense_tables.reset_weights(opponent)
         should_hard_setup = true
         score = 0
         state = states.SELECT_SETUP
      end)
      Queue_Command(gamestate.frame_number + 1, function()
         savestate.load(match_start_state)
      end)
   end
end

local function start_character_select()
   state = states.SETUP_MATCH_START
   ensure_training_settings()
   Register_After_Load_State(function()
      is_active = true
      player = gamestate.P1
      dummy = gamestate.P2
      training.swap_characters = false
      ensure_training_settings()
      apply_settings()
      defense_tables.reset_weights(opponent)
      should_hard_setup = true
      score = 0
   end)
   opponent = defense_tables.opponents[settings.special_training.defense.opponent]
   defense_data = defense_tables.get_defense_data(opponent)

   Register_After_Load_State(character_select.force_select_character, {2, opponent, defense_data.sa, "random"})
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
         if state == states.SETUP_MATCH_START or state == states.SETUP_WAKEUP_BEGIN or state == states.SETUP_WAKEUP then
            inputs.block_input(1, "all")
            inputs.block_input(2, "all")
         end
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
            emu.speedmode("turbo")
            savestate.save(match_start_state)
            settings.special_training.defense.match_savestate_player = gamestate.P1.char_str
            settings.special_training.defense.match_savestate_dummy = gamestate.P2.char_str
            mem.write_pos_x(player, dummy.pos_x - frame_data.get_contact_distance(player))
            Queue_Command(gamestate.frame_number + 2, inputs.queue_input_sequence, {dummy, defense_data.knockdown})
            state = states.SETUP_WAKEUP_BEGIN
         elseif state == states.SETUP_WAKEUP_BEGIN then
            if player.posture == 0x26 and dummy.is_idle then
               setup_wakeup_start_frame = gamestate.frame_number
               state = states.SETUP_WAKEUP
            end
         elseif state == states.SETUP_WAKEUP then
            if gamestate.frame_number - setup_wakeup_start_frame >= screen_shake_delay then
               emu.speedmode("normal")
               savestate.save(wakeup_state)
               should_hard_setup = true
               state = states.SELECT_SETUP
            end
         elseif state == states.SELECT_SETUP then
            player = gamestate.P1
            dummy = gamestate.P2

            setup_state = setup_states.INIT

            action_queue = {}
            actions = {}
            i_actions = 1
            end_frame_extension = 0

            local selected_setups = {}
            local selected_setup

            if (player.is_waking_up or (player.character_state_byte ~= 0 and player.posture == 24)) and
                defense_data.wakeup.active then
               selected_setup = defense_data.wakeup
            else
               for i, p_setup in ipairs(defense_data.setups) do
                  if p_setup.active and p_setup.action:is_valid(dummy, gamestate.stage) then
                     table.insert(selected_setups, p_setup)
                  end
               end

               selected_setup = tools.select_weighted(selected_setups)
               if selected_setup == defense_data.wakeup then should_hard_setup = true end
            end

            should_block_input = false

            if selected_setup ~= defense_data.wakeup then should_block_input = true end

            table.insert(action_queue, selected_setup)
            table.insert(actions, selected_setup.action)

            local followups = selected_setup.action:followups()

            while followups do
               local selected_followups = {}
               for i, p_followup in ipairs(followups) do
                  if p_followup.active and p_followup.action:is_valid(dummy, gamestate.stage, actions, i_actions) then
                     table.insert(selected_followups, p_followup)
                  end
               end
               local selected_followup = tools.select_weighted(selected_followups)
               if selected_followup then
                  table.insert(action_queue, selected_followup)
                  table.insert(actions, selected_followup.action)
                  followups = selected_followup.action:followups()
               else
                  followups = nil
               end
            end

            for _, act in ipairs(actions) do print("=", act.name) end
            state = states.SETUP
         end

         if state == states.SETUP then
            if should_block_input then
               inputs.block_input(1, "all")
               inputs.block_input(2, "all")
               training.disable_dummy = {true, true}
            end
            if player.is_waking_up and not player.is_past_fast_wakeup_frame then
               inputs.unblock_input(1)
               training.disable_dummy = {false, true}
            end
            if should_hard_setup then
               hard_setup()
            else
               soft_setup()
            end
            check_setup_timeout()
         elseif state == states.WAIT_FOR_SETUP then
            if player.is_waking_up then move_players(true, false) end
            if advanced_control.all_commands_complete(dummy) and not inputs.is_playing_input_sequence(dummy) then
               inputs.unblock_input(1)
               training.disable_dummy = {false, true}
               labels = {}
               i_labels = 1
               state = states.FOLLOWUP
            end
            check_setup_timeout()
         elseif state == states.FOLLOWUP then
            if i_labels < i_actions then i_labels = i_actions end
            i_actions = i_actions + 1
            local followup = action_queue[i_actions]
            if followup then
               print(followup.action.name) -- debug
               if not followup.action:should_execute(dummy, gamestate.stage, actions, i_actions) then
                  i_actions = i_actions - 1
                  reselect_followups(i_actions)

                  print(">")
                  update()
                  return
               end
               advanced_control.queue_programmed_movement(dummy, followup.action:setup(dummy, gamestate.stage, actions,
                                                                                       i_actions))
               followup_start_frame = gamestate.frame_number
               state = states.RUNNING
            else
               end_frame = gamestate.frame_number + end_delay
               if dummy.superfreeze_decount > 0 then end_frame = gamestate.frame_number + end_super_delay end
               state = states.BEFORE_END
            end
         end
         if state == states.RUNNING then
            if player.is_waking_up then move_players(true, false) end
            local followup = action_queue[i_actions]
            if followup then
               local finished, result = followup.action:run(dummy, gamestate.stage, actions, i_actions)
               if finished then
                  delta_score = 0
                  if result.should_punish then
                     replace_followups(i_actions + 1, defense_data.punish)
                  elseif result.should_block then
                     replace_followups(i_actions + 1, defense_data.block)
                  elseif result.should_reselect then
                     reselect_followups(i_actions)
                     update()
                     return
                  elseif result.should_walk_in then
                     insert_followup(i_actions, defense_data.walk_in)
                     i_actions = i_actions - 1
                  elseif result.should_walk_out then
                     insert_followup(i_actions, defense_data.walk_out)
                     i_actions = i_actions - 1
                  else
                     delta_score = result.score
                     print("followup score", delta_score) -- debug
                  end
                  if result.should_end then
                     end_frame = gamestate.frame_number + end_delay
                     state = states.BEFORE_END
                     update()
                     return
                  end
                  followup_start_frame = gamestate.frame_number
                  state = states.FOLLOWUP
                  update()
                  return
               end
               if gamestate.frame_number - followup_start_frame >= followup_timeout then
                  end_frame = gamestate.frame_number + end_delay
                  delta_score = 1
                  print("timeout") -- debug
                  state = states.BEFORE_END
               end
            end
            if player.superfreeze_just_began and followup.action ~= defense_data.block.action then
               replace_followups(i_actions + 1, defense_data.block)
               state = states.FOLLOWUP
               update()
               return
            end

            if advanced_control.all_commands_complete(dummy) and i_labels < i_actions then
               i_labels = i_labels + 1
            end
            for i = 1, i_labels do labels[i] = actions[i]:label() end
            hud.add_info_text(labels, dummy.id)
         end
         if state == states.BEFORE_END then
            i_labels = #actions
            for i = 1, i_labels do labels[i] = actions[i]:label() end
            hud.add_info_text(labels, dummy.id)

            score = math.max(score + delta_score, 0)
            if score > settings.special_training.defense.characters[opponent].score then
               settings.special_training.defense.characters[opponent].score = score
            end
            display_delta_score(delta_score)
            if should_adjust_weights then
               local player_response

               if player.is_blocking or player.is_being_thrown then
                  player_response = training_classes.Action_Type.BLOCK
               end
               if player.is_throwing or player.is_in_throw_tech or dummy.is_being_thrown then
                  player_response = training_classes.Action_Type.THROW
               elseif player.character_state_byte == 4 then
                  player_response = training_classes.Action_Type.ATTACK
               end

               for i, action in ipairs(action_queue) do
                  local alpha = learning_rate * i / #action_queue
                  if delta_score < 0 then
                     action.weight = tools.clamp((1 - alpha) * action.weight + alpha, min_weight, max_weight)
                  elseif delta_score > 0 then
                     action.weight = tools.clamp((1 - alpha) * action.weight, min_weight, max_weight)
                  end
               end
               if player_response then
                  local target
                  if player_response == training_classes.Action_Type.BLOCK then
                     target = training_classes.Action_Type.THROW
                  elseif player_response == training_classes.Action_Type.THROW then
                     target = training_classes.Action_Type.ATTACK
                  elseif player_response == training_classes.Action_Type.ATTACK then
                     target = training_classes.Action_Type.BLOCK
                  end
                  if target then
                     for _, followup_list in ipairs(defense_data.followups) do
                        for __, followup in ipairs(followup_list.list) do
                           if followup.action.type == target then
                              followup.weight = tools.clamp((1 - learning_rate / 2) * followup.weight + learning_rate /
                                                                2, min_weight, max_weight)
                           else
                              followup.weight = tools.clamp((1 - learning_rate / 2) * followup.weight, min_weight,
                                                            max_weight)
                           end
                        end
                     end
                  end
               end
            end
            state = states.END
         end
         if state == states.END then
            local is_in_attack = dummy.character_state_byte == 4
            local is_being_hit_or_blocking = dummy.character_state_byte == 1
            if not (player.is_in_throw_tech or dummy.is_in_throw_tech or player.is_being_thrown or dummy.is_being_thrown) then
               if (player.character_state_byte == 1 and (dummy.standing_state == 0 or dummy.is_airborne) and
                   not (dummy.superfreeze_decount > 0)) or
                   (player.character_state_byte == 0 and dummy.character_state_byte == 0) then
                  end_frame = 0
                  print("end now") --debug
               end
            end

            if dummy.has_just_been_hit and not dummy.is_being_thrown then
               end_frame_extension = math.min(end_frame_extension + 15, end_frame_extension_limit)
            end
            if gamestate.frame_number >= end_frame + end_frame_extension and
                not (player.posture == 24 or player.posture == 32 or player.is_being_thrown) then
               inputs.block_input(1, "all")
            end
            if gamestate.frame_number >= end_frame + end_frame_extension + end_wait_delay then
               should_hard_setup = false
               local hit_with_super = memory.readbyte(player.addresses.hit_with_super) > 0
               local hit_with_super_throw = memory.readbyte(player.addresses.hit_with_super_throw) > 0
               if hit_with_super or hit_with_super_throw or player.superfreeze_decount > 0 then
                  should_hard_setup = true
               end
               if is_in_attack then
                  if dummy.superfreeze_decount > 0 then should_hard_setup = true end
               elseif is_being_hit_or_blocking then
                  if not (dummy.is_standing or dummy.is_crouching) then
                     should_hard_setup = true
                  elseif not (player.current_hit_id == player.max_hit_id) then
                     should_hard_setup = true
                  end
               end
               print(should_hard_setup) --debug
               state = states.SELECT_SETUP
            end
         end

         hud.add_score_text(score)
      end
   end
end

local function process_gesture(gesture) end

local defense = {
   module_name = module_name,
   start_character_select = start_character_select,
   start = start,
   stop = stop,
   reset = reset,
   update = update,
   process_gesture = process_gesture
}

setmetatable(defense, {
   __index = function(_, key) if key == "is_active" then return is_active end end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      else
         rawset(defense, key, value)
      end
   end
})

return defense
