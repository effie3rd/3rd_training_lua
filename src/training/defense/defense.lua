local gamestate = require "src.gamestate"
local inputs = require("src.control.inputs")
local character_select = require("src.control.character_select")
local hud = require("src.ui.hud")
local settings = require("src.settings")
local frame_data = require("src.data.framedata")
local game_data = require("src.data.game_data")
local stage_data = require("src.data.stage_data")
local tools = require("src.tools")
local write_memory = require("src.control.write_memory")
local advanced_control = require("src.control.advanced_control")
local memory_addresses = require("src.control.memory_addresses")
local defense_tables = require("src.training.defense.defense_tables")
local training_classes = require("src.training.classes")
local training = require("src.training")
local dummy_control = require("src.control.dummy_control")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local menu = require("src.ui.menu")
local menu_items = require("src.ui.menu_items")
local framedata = require("src.data.framedata")
local prediction = require("src.data.prediction")
local modes = require("src.modes")

local defense
local module_name = "defense"

local is_enabled = true
local is_active = false
local states = {
   SETUP_MATCH_START = 1,
   SETUP_WAKEUP_BEGIN = 2,
   SETUP_WAKEUP = 3,
   SELECT_SETUP = 4,
   SETUP_DELAY = 5,
   SETUP = 6,
   QUEUE_SETUP = 7,
   WAIT_FOR_SETUP = 8,
   FOLLOWUP = 9,
   SELECT_FOLLOWUP = 10,
   RUNNING = 11,
   BEFORE_END = 12,
   END = 13,
   STOPPED = 14
}

local setup_states = {INIT = 1, SET_POSITIONS = 2, MOVE_PLAYERS = 3, CONTINUE_SETUP = 4, SETUP_DELAY = 5}

local state

local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/defense_match_start.fs")
local wakeup_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/defense_wakeup.fs")

local defense_data

local action_queue = {}
local actions = {}
local i_actions = 1
local labels = {}
local i_labels = 0
local max_labels = 8

local should_adjust_weights = true
local score = 0

local setup_state = setup_states.INIT
local setup_start_frame = 0

local player = gamestate.P1
local dummy = gamestate.P2
local opponent
local player_reset_x = 0
local dummy_reset_x = 0

local should_hard_setup = true
local should_block_input = false

local soft_setup_max_position_time = 16
local min_position_speed = 8
local use_default_position = false

local dash_input_window = 12
local followup_start_frame = 0

local delays = {
   start_frame = 0,
   start_delay = 0,
   start_delay_default = 20,
   end_delay = 2,
   end_super_delay = 30,
   end_frame = 0,
   end_frame_max = 0,
   end_frame_extension_default = 40,
   end_frame_extension_limit = 150,
   super_end = false,
   hard_setup_delay = 30,
   soft_setup_delay = 10
}

local blocking_options = {
   mode = dummy_control.Blocking_Mode.ON,
   style = dummy_control.Blocking_Style.BLOCK,
   red_parry_hit_count = 1,
   parry_every_n_count = 1,
   prefer_parry_low = false,
   prefer_block_low = false,
   force_blocking_direction = dummy_control.Force_Blocking_Direction.OFF
}

local player_wakeup = {was_extended = false, intial_countdown = 0}

local score_display_time = 40
local score_fade_time = 20
local score_min_y = 60

local learning_rate = 0.4
local min_weight = 0.05
local max_weight = 1

local indicate_players_after_positioning = false

local start, stop

local defense_menu = {}
local defense_menu_entries = {}
local defense_followup_check_box_grids = {}
local should_update_while_menu_is_open = false

local has_settings_changed = false

local function init() end

local function set_players()
   dummy = training.get_controlled_player_by_name(module_name) --
   or training.get_player_controlled_by_active_mode() --
   or (training.get_controlled_player_by_name("player") and training.get_controlled_player_by_name("player").other) --
   or gamestate.P2
   player = dummy.other
end

local function apply_settings()
   opponent = defense_tables.opponents[settings.modules.defense.opponent]
   defense_data = defense_tables.get_defense_data(opponent)
   for i, p_setup in ipairs(defense_data.setups) do
      p_setup.active = settings.modules.defense.characters[opponent].setups[i]
   end
   for i, p_followup in ipairs(defense_data.followups) do
      for j, p_followup_followup in ipairs(p_followup.list) do
         p_followup_followup.active = settings.modules.defense.characters[opponent].followups[i][j]
      end
   end
end

local function ensure_training_settings()
   settings.training.life_mode = 4
   settings.training.stun_mode = 3
   settings.training.meter_mode = 5
   settings.training.infinite_time = true
   training.disable_dummy[player.id] = false
   training.disable_dummy[dummy.id] = true
end

local function reselect_followups(index)
   index = index + 1
   while action_queue[index] do
      table.remove(action_queue, index)
      table.remove(actions, index)
   end

   local followups = action_queue[#action_queue].action:followups()
   while followups do
      local defense_context = {
         action_queue = action_queue,
         actions = actions,
         i_actions = index,
         stage = gamestate.stage
      }
      local selected_followups = {}
      for i, p_followup in ipairs(followups) do
         if p_followup.active and p_followup.action:is_valid(dummy, defense_context) and
             p_followup.action:should_execute(dummy, defense_context) then
            selected_followups[#selected_followups + 1] = p_followup
         end
      end
      local selected_followup = tools.select_weighted(selected_followups)
      if selected_followup then
         action_queue[#action_queue + 1] = selected_followup
         actions[#actions + 1] = selected_followup.action
         followups = selected_followup.action:followups()
         index = index + 1
      else
         action_queue[#action_queue + 1] = nil
         actions[#actions + 1] = nil
         followups = nil
      end
      if selected_followup and
          not (selected_followup.action.type == training_classes.Action_Type.WALK_FORWARD or
              selected_followup.action.type == training_classes.Action_Type.WALK_BACKWARD or
              selected_followup.action.type == training_classes.Action_Type.BLOCK) then break end
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
   local setup = action_queue[1].action
   if gamestate.frame_number - setup_start_frame >= setup.timeout then
      state = states.SETUP
      setup_state = setup_states.INIT
      should_hard_setup = true
      -- print("SETUP FAILED", player_reset_x, player.pos_x, dummy_reset_x, dummy.pos_x) -- debug
   end
end

local function bound_setup_positions(setup)
   local current_stage = stage_data.stages[gamestate.stage]
   local player_left, player_right = setup:get_soft_reset_range(dummy, {stage = gamestate.stage})[1],
                                     setup:get_soft_reset_range(dummy, {stage = gamestate.stage})[2]
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

local load_screen

local function hard_setup()
   if setup_state == setup_states.INIT then
      emu.speedmode("turbo")
      local should_load = inputs.problematic_inputs_released(joypad.get(), player.id)
      if should_load then
         local setup = action_queue[1].action
         local dummy_sign = tools.sign(dummy.pos_x - player.pos_x)
         player_reset_x = player.pos_x
         dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
         bound_setup_positions(setup)

         Call_After_Load_State(function()
            setup_start_frame = gamestate.frame_number
            set_players()
            training.disable_dummy[player.id] = false
            training.disable_dummy[dummy.id] = true
            if use_default_position then
               player_reset_x = player.pos_x
               dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
            end
         end)
         setup_state = setup_states.SET_POSITIONS

         load_screen = gui.gdscreenshot()
         gui.image(0, 0, load_screen)
         Load_State_Caller = module_name
         if action_queue[1].action.is_wakeup then
            savestate.load(wakeup_state)
         else
            savestate.load(match_start_state)
         end
      end
   elseif setup_state == setup_states.SET_POSITIONS then
      local is_wakeup = action_queue[1].action.is_wakeup
      write_memory.write_pos(player, player_reset_x, 0)
      write_memory.write_pos(dummy, dummy_reset_x, 0)
      write_memory.write_flip_x(player, bit.bxor(dummy.flip_x, 1))
      if not is_wakeup and not allowed_actions[player.action] then
         state = states.SETUP
         setup_state = setup_states.INIT
      end
      if is_wakeup then
         if not player_wakeup.was_extended then
            player_wakeup.was_extended = true
            player_wakeup.intial_countdown = memory.readbyte(player.base + memory_addresses.offsets.frame_countdown) + 1
         end
         memory.writebyte(player.base + memory_addresses.offsets.frame_countdown, 0xff)
      end
      if load_screen then gui.image(0, 0, load_screen) end
      local current_screen_x = memory.readword(memory_addresses.global.screen_pos_x)
      local desired_screen_x, desired_screen_y = write_memory.get_fix_screen_pos(player, dummy, gamestate.stage), 0

      if math.abs(current_screen_x - desired_screen_x) > 10 then
         write_memory.set_screen_pos(desired_screen_x, desired_screen_y)
      elseif (player.is_standing and player.action == 0) or (is_wakeup and player.posture_ext >= 0x40) then
         emu.speedmode("normal")
         setup_state = setup_states.SETUP_DELAY
      end
   elseif setup_state == setup_states.SETUP_DELAY then
      if gamestate.frame_number - setup_start_frame >= delays.hard_setup_delay then
         if player_wakeup.was_extended then
            memory.writebyte(player.base + memory_addresses.offsets.frame_countdown, player_wakeup.intial_countdown)
         end
         setup_start_frame = gamestate.frame_number
         state = states.QUEUE_SETUP
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
      setup_state = setup_states.SET_POSITIONS
   elseif setup_state == setup_states.SET_POSITIONS then
      if advanced_control.all_commands_complete(dummy) and not inputs.is_playing_input_sequence(dummy) then
         if player.is_waking_up or player.is_idle then
            local dummy_sign = tools.sign(dummy.pos_x - player.pos_x)
            player_reset_x = player.pos_x
            dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)

            bound_setup_positions(setup)
            setup_start_frame = gamestate.frame_number
            setup_state = setup_states.MOVE_PLAYERS
         end
      end
   elseif setup_state == setup_states.MOVE_PLAYERS then
      if not dummy.is_idle then setup_start_frame = gamestate.frame_number end
      local dummy_sign = tools.sign(dummy.pos_x - player.pos_x)
      player_reset_x = player.pos_x
      dummy_reset_x = player_reset_x + dummy_sign * setup:get_dummy_offset(dummy)
      bound_setup_positions(setup)
      if player.is_waking_up and player.is_past_fast_wakeup_frame and not player.is_fast_wakingup and player.posture_ext >=
          0x40 then
         if not player_wakeup.was_extended then
            player_wakeup.was_extended = true
            player_wakeup.intial_countdown = memory.readbyte(player.base + memory_addresses.offsets.frame_countdown) + 1
         end
         memory.writebyte(player.base + memory_addresses.offsets.frame_countdown, 0xff)
      end
      if (player.is_standing or player.is_crouching or player.is_waking_up) and not dummy.is_being_thrown then
         move_players(true, false)
      end
      if (player.is_standing or player.is_crouching) and
          (player.pos_x ~= player_reset_x or dummy.pos_x ~= dummy_reset_x) or gamestate.frame_number - setup_start_frame >=
          soft_setup_max_position_time then
         write_memory.write_pos_x(player, player_reset_x)
         write_memory.write_pos_x(dummy, dummy_reset_x)
      end
      if math.abs(dummy.pos_x - dummy_reset_x) <= 4 then
         write_memory.write_pos_x(dummy, dummy_reset_x)
      else
         if dummy.pos_x < dummy_reset_x then
            inputs.press_right(nil, dummy.id)
         elseif dummy.pos_x > dummy_reset_x then
            inputs.press_left(nil, dummy.id)
         end
      end

      if (player.is_waking_up or player.is_idle) and dummy.is_idle then --
         if player.pos_x == player_reset_x and dummy.pos_x == dummy_reset_x --
         and gamestate.frame_number - dummy.input_info.last_back_input > dash_input_window --
         and gamestate.frame_number - dummy.input_info.last_forward_input > dash_input_window --
         and gamestate.frame_number - setup_start_frame > delays.soft_setup_delay then
            if player_wakeup.was_extended then
               memory.writebyte(player.base + memory_addresses.offsets.frame_countdown, player_wakeup.intial_countdown)
            end
            setup_start_frame = gamestate.frame_number
            state = states.QUEUE_SETUP
         end
      end
   end
end

local function display_delta_score(delta_score)
   if delta_score == 0 then return end
   local score_text
   local score_color
   local x, y
   if delta_score > 0 then
      score_text = string.format("+%d", delta_score)
      score_color = colors.score.plus
   else
      score_text = string.format("%d", delta_score)
      score_color = colors.score.minus
   end
   x, y = draw.get_above_character_position(player)
   y = math.max(y, score_min_y)
   hud.add_fading_text(x, y - 4, score_text, "en", score_color, score_display_time, score_fade_time, true)
end

local function update_score(delta_score)
   if not delta_score then return end
   score = math.max(score + delta_score, 0)
   if score > settings.modules.defense.characters[opponent].score then
      settings.modules.defense.characters[opponent].score = score
   end
   display_delta_score(delta_score)
end

local function update_weights(delta_score)
   if not delta_score then return end
   if should_adjust_weights then
      local player_response

      if player.is_blocking or player.is_being_thrown then player_response = training_classes.Action_Type.BLOCK end
      if player.is_throwing or player.is_in_throw_tech or dummy.is_being_thrown then
         player_response = training_classes.Action_Type.THROW
      elseif player.character_state_byte == 4 then
         player_response = training_classes.Action_Type.ATTACK
      end

      for i, action in ipairs(action_queue) do
         if action.action.type ~= training_classes.Action_Type.WALK_FORWARD and action.action.type ~=
             training_classes.Action_Type.WALK_BACKWARD then
            local alpha = learning_rate * i / #action_queue
            if delta_score < 0 then
               action.weight = tools.clamp((1 - alpha) * action.weight + alpha, min_weight, max_weight)
            elseif delta_score > 0 then
               action.weight = tools.clamp((1 - alpha) * action.weight, min_weight, max_weight)
            end
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
                     followup.weight = tools.clamp((1 - learning_rate) * followup.weight + learning_rate, min_weight,
                                                   max_weight)
                     -- else
                     --    followup.weight = tools.clamp((1 - learning_rate / 2) * followup.weight, min_weight,
                     --                                  max_weight)
                  end
               end
            end
         end
      end
   end
end

start = function()
   if settings.modules.defense.match_savestate_player ~= "default" then
      inputs.block_input(1, "all")
      inputs.block_input(2, "all")
      ensure_training_settings()
      if settings.modules.defense.controllers then
         training.set_controllers_by_name(settings.modules.defense.controllers[1],
                                          settings.modules.defense.controllers[2])
      else
         training.set_module_control_by_name(module_name)
      end
      Call_After_Load_State(function()
         set_players()
         ensure_training_settings()
         apply_settings()
         defense_tables.reset_weights(opponent)
         should_hard_setup = true
         delays.start_delay = 0
         delays.end_frame = 0
         score = 0
         state = states.SELECT_SETUP
         if gamestate.is_in_match then indicate_players_after_positioning = true end
      end)
      Queue_Command(gamestate.frame_number + 1, function()
         Load_State_Caller = module_name
         savestate.load(match_start_state)
      end)
   end
end

local function start_character_select()
   state = states.SETUP_MATCH_START
   ensure_training_settings()
   training.set_module_control_by_name(module_name)
   set_players()
   Call_After_Load_State(function()
      set_players()
      ensure_training_settings()
      apply_settings()
      defense_tables.reset_weights(opponent)
      should_hard_setup = true
      delays.start_delay = 0
      delays.end_frame = 0
      score = 0
      indicate_players_after_positioning = true
   end)
   opponent = defense_tables.opponents[settings.modules.defense.opponent]
   defense_data = defense_tables.get_defense_data(opponent)
   Call_After_Load_State(character_select.force_select_character, {dummy.id, opponent, defense_data.sa, "random"})
   character_select.start_character_select_sequence(false, true)
end

stop = function()
   if is_active then
      hud.clear_info_text()
      hud.clear_score_text()
      advanced_control.clear_all()
      training.disable_dummy = {false, false}
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      should_update_while_menu_is_open = false
      menu.allow_update_while_open = false
      menu.disable_freeze = false
      emu.speedmode("normal")
      state = states.STOPPED
   end
end
local function end_mode() if gamestate.is_in_match then hud.indicate_player_controllers() end end

local function reset() end

local function toggle() end

local function update()
   if is_active then
      if gamestate.is_before_curtain or gamestate.is_in_match then
         inputs.block_input(dummy.id, "all")
         if has_settings_changed then
            state = states.SELECT_SETUP
            has_settings_changed = false
         end
         if state == states.SETUP_MATCH_START or state == states.SETUP_WAKEUP_BEGIN or state == states.SETUP_WAKEUP then
            inputs.block_input(1, "all")
            inputs.block_input(2, "all")
         end
         if state == states.SETUP_MATCH_START then
            emu.speedmode("turbo")
            training.disable_dummy = {true, true}
         end
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
            savestate.save(match_start_state)
            settings.modules.defense.match_savestate_player = player.char_str
            settings.modules.defense.match_savestate_dummy = dummy.char_str
            settings.modules.defense.controllers = {training.P1_controller.name, training.P2_controller.name}
            local sign = dummy.side == 1 and 1 or -1
            write_memory.write_pos_x(player, dummy.pos_x + sign * frame_data.get_contact_distance(player))
            Queue_Command(gamestate.frame_number + 2, inputs.queue_input_sequence, {dummy, defense_data.get_knockdown()})
            state = states.SETUP_WAKEUP_BEGIN
         elseif state == states.SETUP_WAKEUP_BEGIN then
            if player.is_waking_up and player.posture_ext >= 0x40 and dummy.is_idle then
               state = states.SETUP_WAKEUP
            end
         end
         if state == states.SETUP_WAKEUP then
            emu.speedmode("normal")
            savestate.save(wakeup_state)
            should_hard_setup = true
            should_update_while_menu_is_open = false
            menu.allow_update_while_open = false
            menu.disable_freeze = false
            training.disable_dummy = {false, false}
            state = states.SELECT_SETUP
         elseif state == states.SELECT_SETUP then
            set_players()
            apply_settings()

            setup_state = setup_states.INIT

            local last_setup = actions[1] or {}
            local last_setup_had_no_followups = #actions == 1

            action_queue = {}
            actions = {}
            i_actions = 1
            delays.start_frame = gamestate.frame_number
            delays.end_frame_extension_current = 0
            delays.super_end = false
            player_wakeup.was_extended = false

            local selected_setups = {}
            local selected_setup

            local defense_context = {
               action_queue = action_queue,
               actions = actions,
               i_actions = i_actions,
               stage = gamestate.stage
            }

            if player.is_waking_up or player.is_in_air_reel then
               for i, p_setup in ipairs(defense_data.setups) do
                  if p_setup.active and p_setup.action.is_wakeup and p_setup.action:is_valid(dummy, defense_context) then
                     selected_setups[#selected_setups + 1] = p_setup
                  end
               end
               selected_setup = tools.select_weighted(selected_setups)
            end

            if not selected_setup then
               for i, p_setup in ipairs(defense_data.setups) do
                  if p_setup.active and p_setup.action:is_valid(dummy, defense_context) then
                     selected_setups[#selected_setups + 1] = p_setup
                  end
               end
               selected_setup = tools.select_weighted(selected_setups)
               if not selected_setup then return end
               if selected_setup.action.is_wakeup then should_hard_setup = true end
            end



            action_queue[#action_queue + 1] = selected_setup
            actions[#actions + 1] = selected_setup.action

            local setup = action_queue[1].action

            should_block_input = false
            if selected_setup ~= defense_data.wakeup then should_block_input = true end
            if setup.should_block_input then should_block_input = true end

            if setup == last_setup and last_setup_had_no_followups then
               should_hard_setup = true
               use_default_position = true
            end

            if not should_hard_setup then
               if not setup.skip_close_distance then
                  advanced_control.queue_programmed_movement(dummy, defense_data.close_distance.action:setup(dummy,
                                                                                                             defense_context))
               end
            end

            if setup.ignore_start_delay and (player.is_waking_up or player.is_in_air_reel) then
               state = states.SETUP
            else
               state = states.SETUP_DELAY
            end
         end
         if state == states.SETUP_DELAY then
            if gamestate.frame_number - delays.start_frame >= delays.start_delay then state = states.SETUP end
         elseif state == states.SETUP then
            if should_block_input then
               inputs.block_input(1, "all")
               inputs.block_input(2, "all")
               training.disable_dummy = {true, true}
            end
            if (player.posture == 24 and player.character_state_byte == 1) or
                (player.is_waking_up and player.posture_ext < 0x40) then
               inputs.unblock_input(player.id)
               training.disable_dummy[player.id] = false
               training.disable_dummy[dummy.id] = true
            end
            local defense_context = {
               action_queue = action_queue,
               actions = actions,
               i_actions = i_actions,
               stage = gamestate.stage
            }
            local setup = action_queue[1].action
            if not setup:is_valid(dummy, defense_context) then
               state = states.SELECT_SETUP
               update()
               return
            end

            if should_hard_setup then
               hard_setup()
            else
               soft_setup()
            end
            check_setup_timeout()
         elseif state == states.QUEUE_SETUP then
            local setup = action_queue[1].action
            advanced_control.queue_programmed_movement(dummy, setup:setup(dummy))
            state = states.WAIT_FOR_SETUP
         elseif state == states.WAIT_FOR_SETUP then
            local setup = action_queue[1].action
            if setup.should_lock_positions and player.is_waking_up then move_players(true, false) end
            local defense_context = {
               action_queue = action_queue,
               actions = actions,
               i_actions = i_actions,
               stage = gamestate.stage
            }
            local finished, result = setup:run(dummy, defense_context)
            if finished then
               if result then
                  if result.should_cancel then
                     state = states.SELECT_SETUP
                     update()
                     return
                  end
                  if result.score then
                     update_score(result.score)
                     update_weights(result.score)
                  end
                  if result.should_end then
                     delays.end_frame = gamestate.frame_number
                     state = states.BEFORE_END
                     update()
                     return
                  end
               end
               inputs.unblock_input(player.id)
               training.disable_dummy[player.id] = false
               training.disable_dummy[dummy.id] = true
               labels = {}
               i_labels = 1
               state = states.SELECT_FOLLOWUP
            end
            if indicate_players_after_positioning then
               indicate_players_after_positioning = false
               hud.indicate_player_controllers()
               hud.add_notification_text("hud_hold_start_stop", 0, 208, "center_horizontal", 60)
            end
            check_setup_timeout()
         end
         if state == states.SELECT_FOLLOWUP then
            local defense_context = {
               action_queue = action_queue,
               actions = actions,
               i_actions = i_actions,
               stage = gamestate.stage
            }
            local current_action = action_queue[i_actions]
            local followups = current_action.action:followups()
            while followups do
               local selected_followups = {}
               for i, p_followup in ipairs(followups) do
                  if p_followup.active and p_followup.action:is_valid(dummy, defense_context) then
                     selected_followups[#selected_followups + 1] = p_followup
                  end
               end
               local selected_followup = tools.select_weighted(selected_followups)
               if selected_followup then
                  action_queue[#action_queue + 1] = selected_followup
                  actions[#actions + 1] = selected_followup.action
                  followups = selected_followup.action:followups()
               else
                  followups = nil
               end
               if selected_followup and
                   not (selected_followup.action.type == training_classes.Action_Type.WALK_FORWARD or
                       selected_followup.action.type == training_classes.Action_Type.WALK_BACKWARD or
                       selected_followup.action.type == training_classes.Action_Type.BLOCK) then break end
            end
            state = states.FOLLOWUP
         end
         if state == states.FOLLOWUP then
            if i_labels < i_actions then i_labels = i_actions end
            i_actions = i_actions + 1
            followup_start_frame = gamestate.frame_number

            local followup = action_queue[i_actions]
            if followup then
               local defense_context = {
                  action_queue = action_queue,
                  actions = actions,
                  i_actions = i_actions,
                  stage = gamestate.stage
               }
               if not followup.action:should_execute(dummy, defense_context) then
                  i_actions = i_actions - 1
                  reselect_followups(i_actions)
                  update()
                  return
               end
               advanced_control.queue_programmed_movement(dummy, followup.action:setup(dummy, defense_context))
               followup_start_frame = gamestate.frame_number
               state = states.RUNNING
            else
               delays.end_frame = gamestate.frame_number
               state = states.BEFORE_END
            end
         end
         if state == states.RUNNING then
            if player.is_waking_up then move_players(true, false) end
            local followup = action_queue[i_actions]
            if followup then
               local defense_context = {
                  action_queue = action_queue,
                  actions = actions,
                  i_actions = i_actions,
                  stage = gamestate.stage
               }
               local finished, result = followup.action:run(dummy, defense_context)
               if finished then
                  if result.should_punish then
                     replace_followups(i_actions + 1, defense_data.punish)
                  elseif result.should_block then
                     replace_followups(i_actions + 1, defense_data.block)
                  elseif result.should_reselect then
                     reselect_followups(i_actions)
                     update()
                     return
                  elseif result.should_block_before then
                     if defense_data.block.action:should_execute(dummy, defense_context) then
                        insert_followup(i_actions, defense_data.block)
                        i_actions = i_actions - 1
                     else
                        result.should_end = true
                     end
                  elseif result.should_walk_in then
                     if defense_data.walk_in.action:should_execute(dummy, defense_context) then
                        insert_followup(i_actions, defense_data.walk_in)
                        i_actions = i_actions - 1
                     else
                        result.should_end = true
                     end
                  elseif result.should_walk_out then
                     if defense_data.walk_out.action:should_execute(dummy, defense_context) then
                        insert_followup(i_actions, defense_data.walk_out)
                        i_actions = i_actions - 1
                     else
                        result.should_end = true
                     end
                  elseif result.next_followup then
                     replace_followups(i_actions + 1, result.next_followup)
                  end
                  if result.score then
                     update_score(result.score)
                     update_weights(result.score)
                  end
                  if result.should_end then
                     delays.end_frame = gamestate.frame_number
                     state = states.BEFORE_END
                     update()
                     return
                  end
                  if not action_queue[i_actions + 1] then
                     state = states.SELECT_FOLLOWUP
                     update()
                     return
                  end
                  state = states.FOLLOWUP
                  update()
                  return
               end
               if gamestate.frame_number - followup_start_frame >= followup.action.timeout then
                  delays.end_frame = gamestate.frame_number
                  update_score(1)
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
            labels[i_labels] = actions[i_labels]:label()
            local display_labels = {}
            for i = math.max(i_labels - max_labels + 1, 1), i_labels do
               display_labels[#display_labels + 1] = labels[i]
            end
            hud.add_info_text(display_labels, dummy.id)
         end
         if state == states.BEFORE_END then
            i_labels = #actions
            for i = 1, i_labels do if not labels[i] then labels[i] = actions[i]:label() end end
            local display_labels = {}
            for i = math.max(i_labels - max_labels + 1, 1), i_labels do
               display_labels[#display_labels + 1] = labels[i]
            end
            hud.add_info_text(display_labels, dummy.id)

            delays.end_frame_max = delays.end_frame + delays.end_frame_extension_limit
            state = states.END
         end
         if state == states.END then
            local dummy_is_being_hit_or_blocking = dummy.character_state_byte == 1
            if dummy.superfreeze_decount > 0 then delays.super_end = true end

            if dummy.has_just_been_hit or dummy.has_just_blocked or player.has_just_parried or player.has_just_blocked or
                player.has_just_attacked or dummy.has_just_missed then
               delays.end_frame = math.min(gamestate.frame_number + delays.end_frame_extension_default,
                                           delays.end_frame_max)
            end

            if player.is_being_thrown or player.has_just_been_hit then
               delays.end_frame = delays.end_frame + 1
            end

            dummy_control.update_blocking(inputs.input, dummy, blocking_options)

            if gamestate.frame_number >= delays.end_frame then
               should_hard_setup = false
               local hit_with_super = memory.readbyte(player.addresses.hit_with_super) > 0
               local hit_with_super_throw = memory.readbyte(player.addresses.hit_with_super_throw) > 0
               -- dummy was hit with super
               if hit_with_super or hit_with_super_throw or player.superfreeze_decount > 0 then
                  should_hard_setup = true
               elseif dummy_is_being_hit_or_blocking then
                  if not (dummy.is_standing or dummy.is_crouching) then
                     should_hard_setup = true
                  elseif not (player.current_hit_id == player.max_hit_id) then
                     should_hard_setup = true
                  end
               end
               if delays.super_end then should_hard_setup = false end
               delays.start_delay = settings.modules.defense.characters[opponent].next_attack_delay
               if not should_hard_setup and (player.character_state_byte == 1 or dummy.character_state_byte == 1) then
                  local frame_advantage = prediction.get_frame_advantage(player)
                  if frame_advantage and frame_advantage > 1 then
                     delays.start_delay = delays.start_delay + delays.start_delay_default
                  end
               elseif player.character_state_byte == 4 or player.is_being_thrown or dummy.is_being_thrown or
                   player.is_in_throw_tech or dummy.is_in_throw_tech then
                  delays.start_delay = delays.start_delay + delays.start_delay_default
               end

               inputs.block_input(1, "all")
               inputs.block_input(2, "all")
               training.disable_dummy = {true, true}
               state = states.SELECT_SETUP
            end
         end

         hud.add_score_text(player.id, score)
      end
   end
end

local function process_gesture(gesture) end

local function get_valid_control_schemes()
   if dummy.id == 2 then
      return {{"player", module_name}, {"dummy_control", module_name}}
   else
      return {{module_name, "player"}, {module_name, "dummy_control"}}
   end
end

local function is_checkbox_enabled(index)
   local reference_map = defense_tables.get_reference_map(opponent)
   for _, setup_index in ipairs(reference_map[index].setups) do
      if settings.modules.defense.characters[opponent].setups[setup_index] then return true end
   end
   for _, followup_index in ipairs(reference_map[index].followups) do
      if settings.modules.defense.characters[opponent].followups[followup_index[1]][followup_index[2]] then
         return true
      end
   end
   return false
end

local function update_settings_changed() has_settings_changed = true end

local function update_menu()
   opponent = defense_tables.opponents[settings.modules.defense.opponent]
   local menu_setup_names = defense_tables.get_menu_setup_names(opponent)
   local setups_object = settings.modules.defense.characters[opponent].setups
   if tools.deep_equal(setups_object, {}) then
      for i = 1, #menu_setup_names do setups_object[#setups_object + 1] = true end
   end

   local followups_object = settings.modules.defense.characters[opponent].followups
   if tools.deep_equal(followups_object, {}) then
      for i = 1, #menu_setup_names do followups_object[#followups_object + 1] = {} end
   end

   defense_menu.setup_item = menu_items.Check_Box_Grid_Item:new("menu_setup",
                                                                settings.modules.defense.characters[opponent].setups,
                                                                menu_setup_names)
   defense_menu.setup_item.on_change = update_settings_changed
   tools.clear_table(defense_menu_entries)

   defense_followup_check_box_grids = {}
   local menu_followup_names = defense_tables.get_menu_followup_names(opponent)
   for i, name in ipairs(menu_followup_names) do
      local followup_object = settings.modules.defense.characters[opponent].followups[i]
      if not followup_object then
         settings.modules.defense.characters[opponent].followups[i] = {}
         followup_object = settings.modules.defense.characters[opponent].followups[i]
      end
      if tools.deep_equal(followup_object, {}) then
         for j = 1, #defense_tables.get_followup_data(opponent)[i].list do
            followup_object[#followup_object + 1] = true
         end
      end
      local menu_followup_followup_names = defense_tables.get_menu_followup_followup_names(opponent, i)
      local check_box_grid = menu_items.Check_Box_Grid_Item:new(name, followup_object, menu_followup_followup_names)
      check_box_grid.is_enabled = function() return is_checkbox_enabled(i) end
      check_box_grid.is_unselectable = function() return not check_box_grid.is_enabled() end
      check_box_grid.on_change = update_settings_changed

      defense_followup_check_box_grids[i] = check_box_grid
   end

   if defense.is_active then
      defense_menu.start_item.name = "menu_stop"
   else
      local saved_player = settings.modules.defense.match_savestate_player
      if opponent == settings.modules.defense.match_savestate_dummy then
         if saved_player ~= "" then
            defense_menu.start_item.name = {"menu_start", "  (", "menu_" .. saved_player, ")"}
         end
      end
   end

   defense_menu.score_item.object = settings.modules.defense.characters[opponent]
   defense_menu.setup_item.object = settings.modules.defense.characters[opponent].setups
   defense_menu.learning_item.object = settings.modules.defense.characters[opponent]
   defense_menu.next_attack_delay_item.object = settings.modules.defense.characters[opponent]

   defense_menu_entries[1] = defense_menu.start_item
   defense_menu_entries[2] = defense_menu.score_item
   defense_menu_entries[3] = defense_menu.character_select_item
   defense_menu_entries[4] = defense_menu.opponent_item
   defense_menu_entries[5] = defense_menu.setup_item
   local i = 1
   while i <= #defense_followup_check_box_grids do
      defense_menu_entries[5 + i] = defense_followup_check_box_grids[i]
      defense_menu_entries[5 + i].is_visible = function() return true end
      i = i + 1
   end
   defense_menu_entries[5 + i] = defense_menu.learning_item
   defense_menu_entries[6 + i] = defense_menu.next_attack_delay_item
   defense_menu_entries[7 + i] = defense_menu.reset_item
end

local function create_menu()
   local menu_opponent = defense_tables.opponents[settings.modules.defense.opponent]

   defense_menu.start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      if is_active then
         modes.stop()
         update_menu()
         menu.update_active_training_page()
      else
         menu.close_menu()
         modes.start(defense)
      end
   end)
   defense_menu.start_item.is_enabled = function()
      if framedata.is_loaded then
         if is_active then
            return true
         else
            return settings.modules.defense.match_savestate_dummy ==
                       defense_tables.opponents[settings.modules.defense.opponent] and
                       defense_menu.setup_item:at_least_one_selected() and
                       settings.modules.defense.match_savestate_player ~= ""
         end
      end
      return false
   end
   defense_menu.start_item.is_unselectable = function() return not defense_menu.start_item.is_enabled() end

   defense_menu.score_item = menu_items.Label_Menu_Item:new("menu_score", {"menu_score", ": ", "value"},
                                                            settings.modules.defense.characters[menu_opponent], "score",
                                                            false, true)

   defense_menu.opponent_item = menu_items.List_Menu_Item:new("menu_opponent", settings.modules.defense, "opponent",
                                                              defense_tables.opponents_menu_names, 1, function()
      update_menu()
      menu.update_active_training_page()
   end)

   defense_menu.setup_item = menu_items.Check_Box_Grid_Item:new("menu_setup",
                                                                settings.modules.defense.characters[menu_opponent]
                                                                    .setups,
                                                                defense_tables.get_menu_setup_names(menu_opponent))

   defense_menu.character_select_item = menu_items.Button_Menu_Item:new("menu_character_select", function()
      modes.set_active(defense)
      should_update_while_menu_is_open = true
      menu.allow_update_while_open = true
      menu.open_after_match_start = true
      menu.disable_freeze = true
      defense.start_character_select()
   end)

   defense_menu.learning_item = menu_items.On_Off_Menu_Item:new("menu_dummy_learning",
                                                                settings.modules.defense.characters[menu_opponent],
                                                                "learning", true)
   defense_menu.learning_item.on_change = update_settings_changed

   defense_menu.next_attack_delay_item = menu_items.Integer_Menu_Item:new("menu_next_attack_delay", settings.modules
                                                                              .defense.characters[menu_opponent],
                                                                          "next_attack_delay", 0, 120, false, 0)

   defense_menu.reset_item = menu_items.Button_Menu_Item:new("menu_reset", function()
      local opp = defense_tables.opponents[settings.modules.defense.opponent]
      defense_tables.reset_followups(settings, opp)
      update_settings_changed()
   end)

   return {name = "training_defense", entries = defense_menu_entries}
end

defense = {
   name = module_name,
   init = init,
   start_character_select = start_character_select,
   start = start,
   stop = stop,
   end_mode = end_mode,
   reset = reset,
   update = update,
   toggle = toggle,
   process_gesture = process_gesture,
   update_menu = update_menu,
   create_menu = create_menu,
   get_valid_control_schemes = get_valid_control_schemes,
   set_players = set_players
}

setmetatable(defense, {
   __index = function(_, key)
      if key == "is_active" then
         return is_active
      elseif key == "is_enabled" then
         return is_enabled
      elseif key == "should_update_while_menu_is_open" then
         return should_update_while_menu_is_open
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      elseif key == "is_enabled" then
         is_enabled = value
      else
         rawset(defense, key, value)
      end
   end
})

return defense
