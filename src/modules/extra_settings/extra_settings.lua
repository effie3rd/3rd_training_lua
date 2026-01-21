local settings = require("src.settings")
local menu_items = require("src.ui.menu_items")
local menu_tables = require("src.ui.menu_tables")
local gamestate = require("src.gamestate")
local colors = require("src.ui.colors")
local draw = require("src.ui.draw")
local hud = require("src.ui.hud")
local game_data = require("src.data.game_data")

local extra_settings
local module_name = "extra_settings"

local is_enabled = settings.modules.extra_settings.is_enabled

local extra_settings_menu = {}
local extra_settings_menu_tables = {}

local player_color_table = {
   "default", "copy_other_player", "black", "white", "fire", "ice", "ex", "twelve", "shadow", "light_shadow"
}
extra_settings_menu_tables.player_coloring = {"menu_off"}
for i = 2, #player_color_table do
   extra_settings_menu_tables.player_coloring[#extra_settings_menu_tables.player_coloring + 1] = "extra_settings_" ..
                                                                                                     player_color_table[i]
end

local player_color_map = {
   [1] = {
      default = 0x42002000,
      copy_other_player = 0x42102010,
      black = 0x43802000,
      white = 0x004001C0,
      fire = 0x20012001,
      ice = 0x20032003,
      ex = 0x205A205A,
      twelve = 0x00401C40,
      shadow = 0x04200000,
      light_shadow = 0x44000000
   },
   [2] = {
      default = 0x42002010,
      copy_other_player = 0x42002000,
      black = 0x43802000,
      white = 0x004001C0,
      fire = 0x20012011,
      ice = 0x20032013,
      ex = 0x205B205B,
      twelve = 0x00481C48,
      shadow = 0x04200000,
      light_shadow = 0x44000000
   }
}

local player_coloring = {
   [1] = {color = player_color_map[1].default, is_enabled = false, should_change = false},
   [2] = {color = player_color_map[2].default, is_enabled = false, should_change = false}
}

local function update_selected_player_color()
   if settings.modules.extra_settings.p1_coloring == 1 then
      if player_coloring[1].is_enabled then player_coloring[1].should_change = true end
      player_coloring[1].color = player_color_map[1].default
      player_coloring[1].is_enabled = false
   else
      local color = player_color_table[settings.modules.extra_settings.p1_coloring]
      player_coloring[1].color = player_color_map[1][color]
      player_coloring[1].is_enabled = true
      player_coloring[1].should_change = true
   end
   if settings.modules.extra_settings.p2_coloring == 1 then
      if player_coloring[2].is_enabled then player_coloring[2].should_change = true end
      player_coloring[2].color = player_color_map[2].default
      player_coloring[2].is_enabled = false
   else
      local color = player_color_table[settings.modules.extra_settings.p2_coloring]
      player_coloring[2].color = player_color_map[2][color]
      player_coloring[2].is_enabled = true
      player_coloring[2].should_change = true
   end
end

local function update_player_coloring()
   if gamestate.is_in_match or gamestate.is_before_curtain then
      if player_coloring[1].should_change then
         memory.writedword(gamestate.P1.addresses.palette, player_coloring[1].color)
         player_coloring[1].should_change = false
      end
      if player_coloring[2].should_change then
         memory.writedword(gamestate.P2.addresses.palette, player_coloring[2].color)
         player_coloring[2].should_change = false
      end
   end
end

local function idle_time_display()
   if settings.modules.extra_settings.display_idle_time == 1 then return end
   local players = {}
   if settings.modules.extra_settings.display_idle_time == 2 then
      players = {gamestate.P1}
   elseif settings.modules.extra_settings.display_idle_time == 3 then
      players = {gamestate.P2}
   elseif settings.modules.extra_settings.display_idle_time == 4 then
      players = {gamestate.P1, gamestate.P2}
   end
   for _, player in pairs(players) do
      local idle_time = math.min(player.idle_time, 999)
      local w, h = draw.get_text_dimensions_multiple({"hud_idle", ": ", idle_time})
      local x, y = draw.game_to_screen_space(player.pos_x, player.pos_y)
      draw.render_text_multiple(x - w / 2, y + 4, {"hud_idle", ": ", idle_time}, "en", nil, colors.idle_time)
   end
end

local function update_idle_time_display()
   if settings.modules.extra_settings.display_idle_time > 1 then
      hud.register_draw(idle_time_display)
   else
      hud.unregister_draw(idle_time_display)
   end
end

local function init()
   update_selected_player_color()
   update_idle_time_display()
   Register_Load_State_Callback(update_selected_player_color)
end

local function update() update_player_coloring() end

local function disable_player_coloring()
   player_coloring[1].color = player_color_map[1].default
   player_coloring[1].should_change = true
   player_coloring[2].color = player_color_map[2].default
   player_coloring[2].should_change = true
   if memory.readdword(gamestate.P1.addresses.palette) ~= player_coloring[1].color or
       memory.readdword(gamestate.P2.addresses.palette) ~= player_coloring[2].color then
      Queue_Command(gamestate.frame_number + 1, disable_player_coloring)
   end
   update_player_coloring()
end

local function update_menu() end

local function create_menu()
   extra_settings_menu = {}
   local function is_enabled_default() return is_enabled end
   local function is_unselectable_default() return not is_enabled end
   extra_settings_menu.p1_coloring_item = menu_items.List_Menu_Item:new("extra_settings_p1_coloring",
                                                                        settings.modules.extra_settings, "p1_coloring",
                                                                        extra_settings_menu_tables.player_coloring, 1,
                                                                        update_selected_player_color)
   extra_settings_menu.p1_coloring_item.is_enabled = is_enabled_default
   extra_settings_menu.p1_coloring_item.is_unselectable = is_unselectable_default
   extra_settings_menu.p2_coloring_item = menu_items.List_Menu_Item:new("extra_settings_p2_coloring",
                                                                        settings.modules.extra_settings, "p2_coloring",
                                                                        extra_settings_menu_tables.player_coloring, 1,
                                                                        update_selected_player_color)
   extra_settings_menu.p2_coloring_item.is_enabled = is_enabled_default
   extra_settings_menu.p2_coloring_item.is_unselectable = is_unselectable_default
   extra_settings_menu.idle_time_item = menu_items.List_Menu_Item:new("extra_settings_display_idle_time",
                                                                      settings.modules.extra_settings,
                                                                      "display_idle_time", menu_tables.player_options,
                                                                      1, update_idle_time_display)
   extra_settings_menu.idle_time_item.is_enabled = is_enabled_default
   extra_settings_menu.idle_time_item.is_unselectable = is_unselectable_default
   extra_settings_menu.version_item = menu_items.Label_Menu_Item:new("menu_version",
                                                                     {"menu_version", " ", game_data.script_version})
   return {
      name = "extra_settings_extra_settings",
      entries = {
         extra_settings_menu.p1_coloring_item, extra_settings_menu.p2_coloring_item, extra_settings_menu.idle_time_item,
         extra_settings_menu.version_item
      }
   }
end

local function toggle()
   if is_enabled then
      disable_player_coloring()
      Unregister_Load_State_Callback(update_selected_player_color)
      hud.unregister_draw(idle_time_display)
   else
      init()
   end
   is_enabled = not is_enabled
   settings.modules.extra_settings.is_enabled = is_enabled
end

extra_settings = {
   name = module_name,
   init = init,
   update = update,
   toggle = toggle,
   update_menu = update_menu,
   create_menu = create_menu
}

setmetatable(extra_settings, {
   __index = function(_, key) if key == "is_enabled" then return is_enabled end end,

   __newindex = function(_, key, value)
      if key == "is_enabled" then
         is_enabled = value
      else
         rawset(extra_settings, key, value)
      end
   end
})

return extra_settings
