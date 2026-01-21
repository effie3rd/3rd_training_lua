local gamestate = require "src.gamestate"
local inputs = require("src.control.inputs")
local hud = require("src.ui.hud")
local settings = require("src.settings")
local tools = require("src.tools")
local training_classes = require("src.training.classes")
local footsies_tables = require("src.training.footsies.footsies_tables")
local advanced_control = require("src.control.advanced_control")
local training = require("src.training")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local framedata = require("src.data.framedata")
local menu_tables = require("src.ui.menu_tables")
local menu_items = require("src.ui.menu_items")
local menu = require("src.ui.menu")
local character_select = require("src.control.character_select")
local dummy_control = require("src.control.dummy_control")
local modes = require("src.modes")

local footsies
local module_name = "footsies"

local is_enabled = true
local is_active = false

local states = {
   SETUP_MATCH_START = 1,
   SETUP_WAKEUP_BEGIN = 2,
   SETUP_WAKEUP = 3,
   SELECT_SETUP = 4,
   SETUP = 5,
   WAIT_FOR_SETUP = 6,
   WAIT_FOR_START_DELAY = 7,
   FOLLOWUP = 8,
   RUNNING = 9,
   BEFORE_END = 10,
   END = 11
}
local state = states.SETUP_MATCH_START

-- local match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/footsies_match_start.fs")

local player = gamestate.P1
local dummy = gamestate.P2

local action_queue = {}
local actions = {}
local i_actions = 1

local followup_timeout = 6 * 60
local followup_start_frame = 0
local has_attacked = false
local is_player_wakeup = false
local start_frame = 0
local end_frame = 0
local player_punish_window = 10
local score = 0
local delta_score = 0
local score_display_time = 40
local score_fade_time = 20
local score_min_y = 60

local should_block = false
local blocking_options = {
   mode = dummy_control.Blocking_Mode.ON,
   style = dummy_control.Blocking_Style.BLOCK,
   red_parry_hit_count = 1,
   parry_every_n_count = 1,
   prefer_parry_low = false,
   prefer_block_low = false,
   force_blocking_direction = dummy_control.Force_Blocking_Direction.OFF
}

local footsies_menu = {}

local function init() end

local function set_players()
   dummy = training.get_controlled_player_by_name(module_name) --
   or training.get_player_controlled_by_active_mode() --
   or (training.get_controlled_player_by_name("player") and training.get_controlled_player_by_name("player").other) --
   or gamestate.P2
   player = dummy.other
end

local function apply_settings()
   for i, p_setup in ipairs(footsies_tables.get_moves()) do
      p_setup.active = settings.modules.footsies.characters[dummy.char_str].moves[i]
   end
   footsies_tables.walk_out.active = settings.modules.footsies.characters[dummy.char_str].walk_out
   footsies_tables.walk_in.active = true
   footsies_tables.attack.active = true
   footsies_tables.accuracy =
       settings.modules.footsies.characters[dummy.char_str].accuracy[settings.modules.footsies
           .characters[dummy.char_str].accuracy_index]
   footsies_tables.distance_judgement =
       settings.modules.footsies.characters[dummy.char_str].dist_judgement[settings.modules.footsies
           .characters[dummy.char_str].dist_judgement_index]
   footsies_tables.sa_after_parry_mode = settings.modules.footsies.characters[dummy.char_str].sa_after_parry
end

local function ensure_training_settings()
   settings.training.life_mode = 4
   settings.training.stun_mode = 3
   settings.training.meter_mode = 5
   settings.training.infinite_time = true
   training.disable_dummy[player.id] = false
   training.disable_dummy[dummy.id] = true
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
   ensure_training_settings()
   training.set_module_control_by_name(module_name)
   set_players()
   footsies_tables.init(dummy)
   apply_settings()
   footsies_tables.reset_weights()
   score = 0
   state = states.SELECT_SETUP
   if gamestate.is_in_match then
      hud.indicate_player_controllers()
      hud.add_notification_text("hud_hold_start_stop", 0, 208, "center_horizontal", 60)
   end
end

local function stop()
   if is_active then
      hud.clear_score_text()
      advanced_control.clear_all()
      training.disable_dummy = {false, false}
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      if gamestate.is_in_match then hud.indicate_player_controllers() end
   end
end

local function end_mode() if gamestate.is_in_match then hud.indicate_player_controllers() end end

local function reset() end

local function toggle() end

local function update()
   if is_active then
      if should_block then
         dummy_control.update_blocking(inputs.input, dummy, blocking_options)
      end
      if gamestate.is_before_curtain or gamestate.is_in_match then
         inputs.block_input(dummy.id, "all")
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
         elseif state == states.SELECT_SETUP then
            set_players()
            apply_settings()
            local at_least_one_followup = false
            for i, p_setup in ipairs(footsies_tables.get_moves()) do
               if p_setup.active then
                  at_least_one_followup = true
                  break
               end
            end

            if not at_least_one_followup then return end

            local last_action = actions[#actions]
            action_queue = {}
            actions = {}
            i_actions = 0
            has_attacked = false

            local is_waking_up = player.is_waking_up or (player.character_state_byte == 1 and player.posture == 24)

            if dummy.is_waking_up then
               action_queue[#action_queue + 1] = footsies_tables.block
               actions[#actions + 1] = footsies_tables.block.action
            elseif is_waking_up or gamestate.frame_number < start_frame then
               if (last_action and last_action ~= footsies_tables.reset_distance.action) and
                   footsies_tables.reset_distance.action:is_valid(dummy, gamestate.stage, actions, #actions + 1) then
                  action_queue[#action_queue + 1] = footsies_tables.reset_distance
                  actions[#actions + 1] = footsies_tables.reset_distance.action
               else
                  return
               end
            else
               footsies_tables.select_attack(dummy)
               local n_walk_in = 0
               local n_walk_out = 0
               local followups = footsies_tables.get_followups()
               while followups do
                  local valid_moves = {}
                  for i, p_followup in ipairs(followups) do
                     if p_followup.active and p_followup.action:is_valid(dummy, gamestate.stage, actions, #actions + 1) then
                        if p_followup == footsies_tables.walk_out then
                           p_followup.weight = math.min(footsies_tables.walk_out.default_weight -
                                                            (n_walk_in + n_walk_out) ^ 0.6, 1)
                        elseif p_followup == footsies_tables.walk_in then
                           p_followup.weight = math.min(footsies_tables.walk_in.default_weight - n_walk_in ^ 0.6, 1)
                        end
                        valid_moves[#valid_moves + 1] = p_followup
                     end
                  end
                  local selected_followup = tools.select_weighted(valid_moves)
                  if selected_followup then
                     if selected_followup == footsies_tables.walk_out then
                        n_walk_out = n_walk_out + 1
                     elseif selected_followup == footsies_tables.walk_in then
                        n_walk_in = n_walk_in + 1
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
            if actions[1] == footsies_tables.reset_distance.action or player.has_just_woke_up then
               start_frame = gamestate.frame_number
            else
               local start_delay_min =
                   settings.modules.footsies.characters[dummy.char_str].next_attack_delay[1]
               local start_delay_max =
                   settings.modules.footsies.characters[dummy.char_str].next_attack_delay[2]
               if settings.modules.footsies.characters[dummy.char_str].next_attack_delay_mode == 1 then
                  local value =
                      settings.modules.footsies.characters[dummy.char_str].next_attack_delay[settings.modules
                          .footsies.characters[dummy.char_str].next_attack_delay_index]
                  start_delay_min = value
                  start_delay_max = value
               end
               start_frame = end_frame + math.random(start_delay_min, start_delay_max)
            end
            state = states.WAIT_FOR_START_DELAY
         end
         if state == states.WAIT_FOR_START_DELAY then
            if gamestate.frame_number >= start_frame then state = states.FOLLOWUP end
         end
         if state == states.FOLLOWUP then
            i_actions = i_actions + 1
            local next_move = action_queue[i_actions]
            if next_move then
               if not next_move.action:should_execute(dummy, gamestate.stage, actions, i_actions) then
                  state = states.BEFORE_END
                  update()
                  return
               end
               advanced_control.queue_programmed_movement(dummy, next_move.action:setup(dummy, gamestate.stage, actions,
                                                                                        i_actions))
               if has_attacked and
                   (next_move.action.type == training_classes.Action_Type.ATTACK or next_move.action.type ==
                       training_classes.Action_Type.THROW) then has_attacked = true end
               followup_start_frame = gamestate.frame_number
               should_block = false
               state = states.RUNNING
            else
               state = states.BEFORE_END
            end
         end
         if state == states.RUNNING then
            footsies_tables.update_walk_time(player)
            footsies_tables.update_recent_attacks(player)

            local followup = action_queue[i_actions]
            if followup then
               if player.is_attacking and followup.action ~= footsies_tables.block.action and
                   (gamestate.frame_number - end_frame <= player_punish_window) then
                  state = states.FOLLOWUP
                  replace_followups(i_actions + 1, footsies_tables.block)
                  update()
                  return
               end
               local finished, result = followup.action:run(dummy, gamestate.stage, actions, i_actions)
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
                     state = states.BEFORE_END
                     update()
                     return
                  end
                  update()
                  return
               end
               if gamestate.frame_number - followup_start_frame >= followup_timeout then
                  delta_score = 0
                  state = states.BEFORE_END
               end
            end
            if player.superfreeze_just_began and followup.action ~= footsies_tables.block.action then
               replace_followups(i_actions + 1, footsies_tables.block)
               state = states.FOLLOWUP
               update()
               return
            end
         end
         if state == states.BEFORE_END then
            if not (is_player_wakeup and delta_score > 0) and has_attacked then
               score = math.max(score + delta_score, 0)
               if score > settings.modules.footsies.characters[dummy.char_str].score then
                  settings.modules.footsies.characters[dummy.char_str].score = score
               end
               -- display_delta_score(delta_score)
            end
            state = states.END
         end
         if state == states.END then
            should_block = true
            if not (dummy.character_state_byte == 1 or dummy.character_state_byte == 2 or dummy.character_state_byte ==
                3 or dummy.character_state_byte == 4) or dummy.is_waking_up then
               end_frame = gamestate.frame_number
               state = states.SELECT_SETUP
            end
         end
         -- hud.add_score_text(player.id, score)
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

local function update_menu()
   set_players()
   footsies_tables.init(dummy)

   if is_active then
      footsies_menu.start_item.name = "menu_stop"
   else
      footsies_menu.start_item.name = "menu_start"
   end
   footsies_menu.walk_out_item.object = settings.modules.footsies.characters[footsies.dummy.char_str]
   footsies_menu.moves_item.object = settings.modules.footsies.characters[footsies.dummy.char_str].moves
   footsies_menu.moves_item.list = footsies_tables.get_menu_move_names()
   if #footsies_menu.moves_item.list ~= #footsies_menu.moves_item.object then
      settings.modules.footsies.characters[dummy.char_str].moves = {}
      for i = 1, #footsies_menu.moves_item.list do
         settings.modules.footsies.characters[dummy.char_str].moves[i] = false
      end
   end
   footsies_menu.accuracy_item.points = settings.modules.footsies.characters[dummy.char_str].accuracy
   footsies_menu.accuracy_item.mode = tools.create_dynamic_value(
                                          settings.modules.footsies.characters[dummy.char_str], "accuracy_mode")
   footsies_menu.accuracy_item.point_index = tools.create_dynamic_value(
                                                 settings.modules.footsies.characters[dummy.char_str],
                                                 "accuracy_index")
   footsies_menu.distance_judgement_item.points = settings.modules.footsies.characters[dummy.char_str]
                                                      .dist_judgement
   footsies_menu.distance_judgement_item.mode = tools.create_dynamic_value(
                                                    settings.modules.footsies.characters[dummy.char_str],
                                                    "dist_judgement_mode")
   footsies_menu.distance_judgement_item.point_index = tools.create_dynamic_value(
                                                           settings.modules.footsies.characters[dummy.char_str],
                                                           "dist_judgement_index")
   footsies_menu.next_attack_delay_item.points = settings.modules.footsies.characters[dummy.char_str]
                                                     .next_attack_delay
   footsies_menu.next_attack_delay_item.mode = tools.create_dynamic_value(
                                                   settings.modules.footsies.characters[dummy.char_str],
                                                   "next_attack_delay_mode")
   footsies_menu.next_attack_delay_item.point_index = tools.create_dynamic_value(
                                                          settings.modules.footsies.characters[dummy.char_str],
                                                          "next_attack_delay_index")

   footsies_menu.sa_after_parry_item.object = settings.modules.footsies.characters[dummy.char_str]
end

local function create_menu()
   footsies_menu = {}
   footsies_menu.start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      if is_active then
         modes.stop()
         update_menu()
         menu.update_active_training_page()
      else
         menu.close_menu()
         modes.start(footsies)
      end
   end)
   footsies_menu.start_item.legend_text = "legend_lp_select"
   footsies_menu.start_item.is_enabled = function()
      if framedata.is_loaded then
         if is_active then
            return true
         else
            return footsies_menu.moves_item:at_least_one_selected()
         end
      end
      return false
   end
   footsies_menu.start_item.is_unselectable = function() return not footsies_menu.start_item.is_enabled() end
   -- footsies_menu.score_item = menu_items.Label_Menu_Item:new("menu_score", {"menu_score", ": ", "value"}, {},
   --                                                                   "score", false, true)

   footsies_menu.character_select_item = menu_items.Button_Menu_Item:new("menu_character_select", function()
      character_select.start_character_select_sequence()
      menu.open_after_match_start = true
      modes.stop()
   end)
   footsies_menu.character_select_item.legend_text = "legend_lp_select"

   footsies_menu.moves_item = menu_items.Check_Box_Grid_Item:new("menu_moves", {1}, {"1"})

   footsies_menu.walk_out_item = menu_items.On_Off_Menu_Item:new("menu_walk_out", {walk_out = true}, "walk_out", true)
   footsies_menu.accuracy_item = menu_items.Slider_Menu_Item:new("menu_accuracy", 80, {80, 80}, {0, 100}, 5, "%")
   footsies_menu.accuracy_item.disable_mode_switch = true
   footsies_menu.accuracy_item.autofire_rate = 2
   footsies_menu.accuracy_item.legend_text = ""

   footsies_menu.distance_judgement_item = menu_items.Slider_Menu_Item:new("menu_distance_judgement", 80, {80, 80},
                                                                           {0, 100}, 5, "%")
   footsies_menu.distance_judgement_item.disable_mode_switch = true
   footsies_menu.distance_judgement_item.autofire_rate = 2
   footsies_menu.distance_judgement_item.legend_text = ""

   footsies_menu.next_attack_delay_item = menu_items.Slider_Menu_Item:new("menu_next_attack_delay", 80, {80, 80},
                                                                          {0, 40}, 1)
   footsies_menu.next_attack_delay_item.autofire_rate = 2

   footsies_menu.sa_after_parry_item = menu_items.List_Menu_Item:new("menu_sa_after_parry", {sa_after_parry = 1},
                                                                     "sa_after_parry", menu_tables.off_on_random, 1)

   return {
      name = "training_footsies",
      entries = {
         footsies_menu.start_item, footsies_menu.character_select_item,
         footsies_menu.moves_item, footsies_menu.walk_out_item, footsies_menu.accuracy_item,
         footsies_menu.distance_judgement_item, footsies_menu.next_attack_delay_item,
         footsies_menu.sa_after_parry_item
      }
   }
end

footsies = {
   name = module_name,
   init = init,
   start = start,
   stop = stop,
   end_mode = end_mode,
   reset = reset,
   update = update,
   toggle = toggle,
   process_gesture = process_gesture,
   get_valid_control_schemes = get_valid_control_schemes,
   update_menu = update_menu,
   create_menu = create_menu,
   set_players = set_players
}

setmetatable(footsies, {
   __index = function(_, key)
      if key == "is_active" then
         return is_active
      elseif key == "is_enabled" then
         return is_enabled
      elseif key == "player" then
         return player
      elseif key == "dummy" then
         return dummy
      end
   end,

   __newindex = function(_, key, value)
      if key == "is_active" then
         is_active = value
      elseif key == "is_enabled" then
         is_enabled = value
      else
         rawset(footsies, key, value)
      end
   end
})

return footsies
