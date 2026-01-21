local gamestate, framedata, inputs, character_select, hud, settings, frame_data, game_data, stage_data,
      unblockables_tables, mem, advanced_control, write_memory, memory_addresses, training, modes, menu, menu_items,
      tools

local unblockables
local module_name = "unblockables"

local is_enabled = true
local is_active = false
local states = {SETUP_MATCH_START = 1, INIT = 2, SETUP = 3, WAIT_FOR_SETUP = 4, RUNNING = 5, END = 6, IDLE = 7}
local state = states.INIT

local match_start_state, followup_state

local player, dummy

local setup, followups
local end_frame = 0

local unblockables_menu = {}

local function init()
   gamestate = require("src.gamestate")
   framedata = require("src.data.framedata")
   inputs = require("src.control.inputs")
   character_select = require("src.control.character_select")
   settings = require("src.settings")
   training = require("src.training")
   hud = require("src.ui.hud")
   frame_data = require("src.data.framedata")
   game_data = require("src.data.game_data")
   stage_data = require("src.data.stage_data")
   mem = require("src.control.write_memory")
   advanced_control = require("src.control.advanced_control")
   write_memory = require("src.control.write_memory")
   memory_addresses = require("src.control.memory_addresses")
   modes = require("src.modes")
   menu = require("src.ui.menu")
   menu_items = require("src.ui.menu_items")
   tools = require("src.tools")

   unblockables_tables = require(settings.training_require_path .. "." .. module_name .. "." .. "unblockables_tables")

   match_start_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/unblockables_match_start.fs")
   followup_state = savestate.create("data/" .. game_data.rom_name .. "/savestates/unblockables_followup.fs")

   player = gamestate.P1
   dummy = gamestate.P2
end

local function set_players()
   dummy = training.get_controlled_player_by_name(module_name) --
   or training.get_player_controlled_by_active_mode() --
   or (training.get_controlled_player_by_name("player") and training.get_controlled_player_by_name("player").other) --
   or gamestate.P2
   player = dummy.other
end

local function ensure_training_settings()
   settings.training.life_mode = 4
   settings.training.stun_mode = 3
   settings.training.meter_mode = 5
   settings.training.infinite_time = true
   training.disable_dummy[player.id] = false
   training.disable_dummy[dummy.id] = true
end

local function continue_from_savestate()
   Call_After_Load_State(function()
      if not is_active and gamestate.is_in_match then hud.indicate_player_controllers() end
      set_players()
      setup = unblockables_tables.get_setup(settings.modules.unblockables.savestate_opponent, --
      settings.modules.unblockables.savestate_player, settings.modules.unblockables.savestate_setup)

      followups = unblockables_tables.get_followups(settings.modules.unblockables.match_savestate_opponent,
                                                    settings.modules.unblockables.match_savestate_player, setup.name)

      local setup_index = settings.modules.unblockables.setup
      local active_followups = {}
      local opponent = settings.modules.unblockables.match_savestate_opponent
      local char_str = settings.modules.unblockables.match_savestate_player
      for i, followup in ipairs(followups) do
         if settings.modules.unblockables.followups[opponent][char_str][setup_index][i] then
            active_followups[#active_followups + 1] = followup
         end
      end
      local followup = active_followups[math.random(1, #active_followups)]
      advanced_control.queue_programmed_movement(dummy, followup.commands(dummy))
      state = states.RUNNING
   end)
   Load_State_Caller = module_name
   savestate.load(followup_state)
end

local function start()
   if not is_active then
      ensure_training_settings()
      if settings.modules.unblockables.controllers then
         training.set_controllers_by_name(settings.modules.unblockables.controllers[1],
                                          settings.modules.unblockables.controllers[2])
      else
         training.set_module_control_by_name(module_name)
      end
      set_players()
   end
   setup = unblockables_tables.get_setup(settings.modules.unblockables.match_savestate_opponent,
                                         settings.modules.unblockables.match_savestate_player,
                                         settings.modules.unblockables.setup)

   followups = unblockables_tables.get_followups(settings.modules.unblockables.match_savestate_opponent,
                                                 settings.modules.unblockables.match_savestate_player, setup.name)
   local setup_index = settings.modules.unblockables.setup
   local opponent = settings.modules.unblockables.match_savestate_opponent
   local char_str = settings.modules.unblockables.match_savestate_player
   local followups_settings = settings.modules.unblockables.followups[opponent][char_str][setup_index]
   local at_least_one_followup = false
   for i, setting in ipairs(followups_settings) do
      if setting then
         at_least_one_followup = true
         break
      end
   end
   if not at_least_one_followup then return end
   advanced_control.clear_all()
   inputs.clear_input_sequence(dummy)
   if settings.modules.unblockables.savestate_player == settings.modules.unblockables.match_savestate_player and
       settings.modules.unblockables.savestate_opponent == settings.modules.unblockables.match_savestate_opponent and
       settings.modules.unblockables.savestate_setup == settings.modules.unblockables.setup then
      continue_from_savestate()
   else
      inputs.block_input(1, "all")
      inputs.block_input(2, "all")
      Call_After_Load_State(function()
         set_players()
         if not is_active and gamestate.is_in_match then hud.indicate_player_controllers() end
      end)
      state = states.SETUP
      Load_State_Caller = module_name
      savestate.load(match_start_state)
   end
end

local function start_character_select()
   modes.set_active(unblockables)
   state = states.SETUP_MATCH_START
   training.set_module_control_by_name(module_name)
   ensure_training_settings()
   local char_str = unblockables_tables.available_opponents[settings.modules.unblockables.opponent]
   local sa = 3
   if char_str == "oro" then sa = 2 end
   Call_After_Load_State(set_players)
   Call_After_Load_State(character_select.force_select_character, {dummy.id, char_str, sa, "random"})
   character_select.start_character_select_sequence()
end

local function check_for_new_setup()
   if not is_active then return end
   local opponent_name = unblockables_tables.available_opponents[settings.modules.unblockables.opponent]
   if opponent_name == settings.modules.unblockables.match_savestate_opponent and settings.modules.unblockables.setup ~=
       settings.modules.unblockables.savestate_setup then start() end
end

local function stop()
   if is_active then
      training.disable_dummy = {false, false}
      inputs.unblock_input(1)
      inputs.unblock_input(2)
      advanced_control.clear_all()
      hud.clear_notification_text()
   end
end

local function end_mode() if gamestate.is_in_match then hud.indicate_player_controllers() end end

local function reset() end

local function toggle() end

local function update()
   if is_active then
      if gamestate.is_in_match then
         inputs.block_input(dummy.id, "all")
         if state == states.SETUP_MATCH_START or state == states.SETUP or state == states.WAIT_FOR_SETUP then
            inputs.block_input(1, "all")
            inputs.block_input(2, "all")
         end
         if state == states.SETUP or state == states.WAIT_FOR_SETUP then
            hud.add_notification_text("hud_please_wait", 0, 42, "center_horizontal")
            hud.add_notification_text("hud_coin_restart_hold_start_stop", 0, 208, "center_horizontal")
         end
         if state == states.SETUP_MATCH_START and gamestate.has_match_just_started then
            savestate.save(match_start_state)
            settings.modules.unblockables.controllers = {training.P1_controller.name, training.P2_controller.name}
            settings.modules.unblockables.match_savestate_opponent = dummy.char_str
            settings.modules.unblockables.match_savestate_player = player.char_str
            settings.modules.unblockables.savestate_setup = -1
            settings.modules.unblockables.savestate_player = ""
            settings.modules.unblockables.savestate_opponent = ""
            state = states.IDLE
         elseif state == states.SETUP then
            set_players()
            training.disable_dummy = {true, true}
            settings.modules.unblockables.savestate_setup = -1
            settings.modules.unblockables.savestate_player = ""
            settings.modules.unblockables.savestate_opponent = ""
            setup = unblockables_tables.get_setup(settings.modules.unblockables.match_savestate_opponent,
                                                  settings.modules.unblockables.match_savestate_player,
                                                  settings.modules.unblockables.setup)

            local player_offset = (frame_data.character_specific[player.char_str].pushbox_width +
                                      frame_data.character_specific[dummy.char_str].pushbox_width) / 2 + 6
            local stage_left = stage_data.stages[gamestate.stage].left
            local stage_right = stage_data.stages[gamestate.stage].right
            local dummy_reset_x = stage_left + setup.reset_offset_x
            local player_reset_x = dummy_reset_x - player_offset
            if dummy.id == 1 then
               dummy_reset_x = stage_right - setup.reset_offset_x
               player_reset_x = dummy_reset_x + player_offset
            end

            if player.pos_x ~= player_reset_x or dummy.pos_x ~= dummy_reset_x then
               mem.write_pos_x(player, player_reset_x)
               mem.write_pos_x(dummy, dummy_reset_x)
            end

            local current_screen_x = memory.readword(memory_addresses.global.screen_pos_x)
            local desired_screen_x, desired_screen_y = write_memory.get_fix_screen_pos(player, dummy, gamestate.stage)

            if current_screen_x ~= desired_screen_x then
               write_memory.set_screen_pos(desired_screen_x, desired_screen_y)
            elseif player.pos_x == player_reset_x and dummy.pos_x == dummy_reset_x then
               advanced_control.queue_programmed_movement(dummy, setup.commands(dummy))
               state = states.WAIT_FOR_SETUP
            end
         elseif state == states.WAIT_FOR_SETUP then
            training.disable_dummy[dummy.id] = true
            if advanced_control.all_commands_queued(dummy) and not inputs.is_playing_input_sequence(dummy) then
               Queue_Command(gamestate.frame_number + 1, function()
                  savestate.save(followup_state)
                  settings.modules.unblockables.savestate_setup = settings.modules.unblockables.setup
                  settings.modules.unblockables.savestate_opponent = dummy.char_str
                  settings.modules.unblockables.savestate_player = player.char_str
                  inputs.unblock_input(1)
                  inputs.unblock_input(2)
                  continue_from_savestate()
               end)
               state = states.RUNNING
            end
         elseif state == states.RUNNING then
            training.disable_dummy[player.id] = false
            training.disable_dummy[dummy.id] = true
            if advanced_control.all_commands_queued(dummy) and not inputs.is_playing_input_sequence(dummy) then
               if player.is_airborne or player.has_just_hit_ground or dummy.has_just_hit_ground then
                  state = states.END
                  end_frame = gamestate.frame_number
               end
            end
         elseif state == states.END then
            training.disable_dummy[dummy.id] = false
         end
      end
   end
end

local function process_gesture(gesture) if is_active then if gesture == "single_tap" then start() end end end

local function get_valid_control_schemes()
   if dummy.id == 2 then
      return {{"player", module_name}, {"dummy_control", module_name}}
   else
      return {{module_name, "player"}, {module_name, "dummy_control"}}
   end
end

local function update_menu(opponent_changed)
   set_players()

   if opponent_changed then settings.modules.unblockables.setup = 1 end
   local opponent_name = unblockables_tables.available_opponents[settings.modules.unblockables.opponent]
   local char_str = player.char_str
   local setup_menu_names = unblockables_tables.get_setups_menu_names(opponent_name, char_str)
   if settings.modules.unblockables.match_savestate_opponent ~= opponent_name then
      settings.modules.unblockables.setup = 1
   end
   settings.modules.unblockables.setup = tools.bound_index(settings.modules.unblockables.setup, #setup_menu_names)
   local selected_setup = settings.modules.unblockables.setup

   local setup_name = unblockables_tables.get_setup(opponent_name, char_str, selected_setup).name
   local followups = settings.modules.unblockables.followups[opponent_name][char_str][selected_setup]
   local followup_menu_names = unblockables_tables.get_followups_menu_names(opponent_name, char_str, setup_name)

   unblockables_menu.setup_item.list = setup_menu_names
   unblockables_menu.setup_item:calc_dimensions()

   unblockables_menu.followup_item.object = followups
   unblockables_menu.followup_item.list = followup_menu_names
   unblockables_menu.followup_item:calc_dimensions()

   if is_active then
      unblockables_menu.start_item.name = "menu_stop"
   else
      if settings.modules.unblockables.match_savestate_player ~= "" then
         unblockables_menu.start_item.name = {
            "menu_start", "  (", "menu_" .. settings.modules.unblockables.match_savestate_player, ")"
         }
      else
         unblockables_menu.start_item.name = "menu_start"
      end
   end

   if is_active then
      menu.main_menu.on_close = function()
         check_for_new_setup()
         menu.main_menu.on_close = nil
      end
   end
end

local function create_menu()
   local opponent_name = unblockables_tables.available_opponents[1]
   local char_str = "alex"
   local setup_menu_names = unblockables_tables.get_setups_menu_names(opponent_name, char_str)
   local setup_name = unblockables_tables.get_setup(opponent_name, char_str, 1).name
   local __followups = settings.modules.unblockables.followups[opponent_name][char_str][1]
   local followup_menu_names = unblockables_tables.get_followups_menu_names(opponent_name, char_str, setup_name)

   unblockables_menu.opponent_item = menu_items.List_Menu_Item:new("menu_opponent", settings.modules.unblockables,
                                                                   "opponent", unblockables_tables.opponents_menu_names,
                                                                   1, function() update_menu(true) end)

   unblockables_menu.setup_item = menu_items.List_Menu_Item:new("menu_setup", settings.modules.unblockables, "setup",
                                                                setup_menu_names, 1, update_menu)

   unblockables_menu.followup_item = menu_items.Check_Box_Grid_Item:new("menu_followup", __followups,
                                                                        followup_menu_names)
   unblockables_menu.followup_item.is_enabled = function()
      if unblockables_tables.available_opponents[settings.modules.unblockables.opponent] ==
          settings.modules.unblockables.match_savestate_opponent then return true end
      return false
   end
   unblockables_menu.followup_item.is_unselectable = function()
      return not unblockables_menu.followup_item.is_enabled()
   end

   unblockables_menu.start_item = menu_items.Button_Menu_Item:new("menu_start", function()
      if is_active then
         modes.stop()
         update_menu()
         menu.update_active_training_page()
      else
         menu.close_menu()
         modes.start(unblockables)
      end
   end)
   unblockables_menu.start_item.legend_text = "legend_lp_select_coin_restart"
   unblockables_menu.start_item.is_enabled = function()
      if framedata.is_loaded then
         if is_active then
            return true
         elseif unblockables_tables.available_opponents[settings.modules.unblockables.opponent] ==
             settings.modules.unblockables.match_savestate_opponent and
             unblockables_menu.followup_item:at_least_one_selected() then
            return true
         end
      end
      return false
   end
   unblockables_menu.start_item.is_unselectable = function() return not unblockables_menu.start_item.is_enabled() end

   unblockables_menu.character_select_item = menu_items.Button_Menu_Item:new("menu_character_select", function()
      menu.main_menu.on_close = nil
      start_character_select()
      unblockables_menu.followup_item.selected_col = 1
      unblockables_menu.followup_item.selected_row = 1
      menu.open_after_match_start = true
      menu.main_menu:select_item(unblockables_menu.followup_item)
   end)
   unblockables_menu.character_select_item.legend_text = "legend_lp_select"
   unblockables_menu.character_select_item.is_enabled = function() return framedata.is_loaded end
   unblockables_menu.character_select_item.is_unselectable = function()
      return not unblockables_menu.character_select_item.is_enabled()
   end

   return {
      name = "training_" .. module_name,
      entries = {
         unblockables_menu.start_item, unblockables_menu.character_select_item, unblockables_menu.opponent_item,
         unblockables_menu.setup_item, unblockables_menu.followup_item
      }
   }
end

unblockables = {
   name = module_name,
   init = init,
   start = start,
   stop = stop,
   end_mode = end_mode,
   update = update,
   toggle = toggle,
   process_gesture = process_gesture,
   create_menu = create_menu,
   update_menu = update_menu,
   start_character_select = start_character_select,
   check_for_new_setup = check_for_new_setup,
   get_valid_control_schemes = get_valid_control_schemes,
   set_players = set_players
}

setmetatable(unblockables, {
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
         rawset(unblockables, key, value)
      end
   end
})

return unblockables
