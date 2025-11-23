local fd = require("src.modules.framedata")
local move_data = require("src.modules.move_data")
local tools = require("src.tools")

local find_frame_data_by_name = fd.find_frame_data_by_name

local max_jumps = 9
local jumps = {}
local second_jumps = {}
local jumps_default = {
   "off", "jump_forward", "jump_neutral", "jump_back", "sjump_forward", "sjump_neutral", "sjump_back"
}
local oro_jumps = {"none", "jump_forward", "jump_neutral", "jump_back"}
local twelve_jumps = {"none", "air_dash_forward", "air_dash_back"}
local moves = {}
local moves_default = {"none", "LP", "MP", "HP", "LK", "MK", "HK", "throw"}
local additional_moves = {
   alex = {"d_HP"},
   chunli = {"d_HP", "d_MK", "HP_HP"},
   elena = {"LP_MK", "MP_HP"},
   gouki = {
      "d_MK", "gohadouken_air_LP", "gohadouken_air_MP", "gohadouken_air_HP", "tatsumaki_air_LK", "tatsumaki_air_MK",
      "tatsumaki_air_HK"
   },
   hugo = {"d_HP"},
   ibuki = {"LP_f_HP", "HP_f_MK", "LK_f_MK", "kunai_LP", "kunai_MP", "kunai_HP", "kunai_EXP"},
   ken = {"tatsumaki_air_LK", "tatsumaki_air_MK", "tatsumaki_air_HK", "tatsumaki_air_EXK"},
   makoto = {"tsurugi_LK", "tsurugi_MK", "tsurugi_HK", "tsurugi_EXK"},
   necro = {"drill_LK", "drill_MK", "drill_HK"},
   oro = {"hitobashira_air", "hitobashira_air_EXK"},
   ryu = {"tatsumaki_air_LK", "tatsumaki_air_MK", "tatsumaki_air_HK", "tatsumaki_air_EXK"},
   shingouki = {
      "d_MK", "gohadouken_air_LP", "gohadouken_air_MP", "gohadouken_air_HP", "tatsumaki_air_LK", "tatsumaki_air_MK",
      "tatsumaki_air_HK"
   },
   twelve = {"axe_air_LP", "axe_air_MP", "axe_air_HP", "axe_air_EXP", "dra_LK", "dra_MK", "dra_HK", "dra_EXK"},
   yang = {"MK_raigeki_MK", "raigeki_LK", "raigeki_MK", "raigeki_HK"},
   yun = {"LP_f_HP", "raigeki_LK", "raigeki_MK", "raigeki_HK"}
}

local move_inputs

local target_combos = {
   HP_HP = true,
   LP_MK = true,
   MP_HP = true,
   LP_f_HP = true,
   HP_f_MK = true,
   LK_f_MK = true,
   MK_raigeki_MK = true
}

local jump_inputs = {
   jump_forward = {{"up", "forward"}, {"up", "forward"}, {"up", "forward"}},
   jump_neutral = {{"up"}, {"up"}, {"up"}},
   jump_back = {{"up", "back"}, {"up", "back"}, {"up", "back"}},
   sjump_forward = {{"down"}, {"forward", "up"}, {"forward", "up"}, {"forward", "up"}},
   sjump_neutral = {{"down"}, {"up"}, {"up"}, {"up"}},
   sjump_back = {{"down"}, {"back", "up"}, {"back", "up"}, {"back", "up"}},
   air_dash_forward = {{"forward"}, {}, {"forward"}},
   air_dash_back = {{"back"}, {}, {"back"}}
}

local function update_character(char_str)
   jumps = copytable(jumps_default)
   second_jumps = {}
   if char_str == "oro" then
      second_jumps = oro_jumps
   elseif char_str == "twelve" then
      second_jumps = twelve_jumps
   end
   moves = copytable(moves_default)
   if additional_moves[char_str] then
      for _, name in ipairs(additional_moves[char_str]) do moves[#moves + 1] = name end
   end
end

local function init(char_str)
   update_character(char_str)
   move_inputs = {
      none = {{}},
      LP = {{"LP"}},
      MP = {{"MP"}},
      HP = {{"HP"}},
      LK = {{"LK"}},
      MK = {{"MK"}},
      HK = {{"HK"}},
      throw = {{"LP", "LK"}},
      d_HP = {{"down", "HP"}},
      d_MK = {{"down", "MK"}},
      HP_HP = {{"HP"}, {"HP"}},
      LP_MK = {{"LP"}, {"MK"}},
      MP_HP = {{"MP"}, {"HP"}},
      tatsumaki_air_LK = move_data.get_move_inputs_by_name("gouki", "tatsumaki", "LK"),
      tatsumaki_air_MK = move_data.get_move_inputs_by_name("gouki", "tatsumaki", "MK"),
      tatsumaki_air_HK = move_data.get_move_inputs_by_name("gouki", "tatsumaki", "HK"),
      tatsumaki_air_EXK = move_data.get_move_inputs_by_name("gouki", "tatsumaki", "EXK"),
      gohadouken_air_LP = move_data.get_move_inputs_by_name("gouki", "gohadouken", "LP"),
      gohadouken_air_MP = move_data.get_move_inputs_by_name("gouki", "gohadouken", "MP"),
      gohadouken_air_HP = move_data.get_move_inputs_by_name("gouki", "gohadouken", "HP"),
      LP_f_HP = {{"LP"}, {"forward", "HP"}},
      HP_f_MK = {{"HP"}, {"forward", "MK"}},
      LK_f_MK = {{"LK"}, {"forward", "MK"}},
      kunai_LP = move_data.get_move_inputs_by_name("ibuki", "kunai", "LP"),
      kunai_MP = move_data.get_move_inputs_by_name("ibuki", "kunai", "MP"),
      kunai_HP = move_data.get_move_inputs_by_name("ibuki", "kunai", "HP"),
      kunai_EXP = move_data.get_move_inputs_by_name("ibuki", "kunai", "EXP"),
      tsurugi_LK = move_data.get_move_inputs_by_name("makoto", "tsurugi", "LK"),
      tsurugi_MK = move_data.get_move_inputs_by_name("makoto", "tsurugi", "MK"),
      tsurugi_HK = move_data.get_move_inputs_by_name("makoto", "tsurugi", "HK"),
      tsurugi_EXK = move_data.get_move_inputs_by_name("makoto", "tsurugi", "EXK"),
      drill_LK = {{"down", "LK"}},
      drill_MK = {{"down", "MK"}},
      drill_HK = {{"down", "HK"}},
      hitobashira_air = move_data.get_move_inputs_by_name("oro", "hitobashira", "LK"),
      hitobashira_air_EXK = move_data.get_move_inputs_by_name("oro", "hitobashira", "EXK"),
      axe_air_LP = move_data.get_move_inputs_by_name("twelve", "axe", "LP"),
      axe_air_MP = move_data.get_move_inputs_by_name("twelve", "axe", "MP"),
      axe_air_HP = move_data.get_move_inputs_by_name("twelve", "axe", "HP"),
      axe_air_EXP = move_data.get_move_inputs_by_name("twelve", "axe", "EXP"),
      dra_LK = move_data.get_move_inputs_by_name("twelve", "dra", "LK"),
      dra_MK = move_data.get_move_inputs_by_name("twelve", "dra", "MK"),
      dra_HK = move_data.get_move_inputs_by_name("twelve", "dra", "HK"),
      dra_EXK = move_data.get_move_inputs_by_name("twelve", "dra", "EXK"),
      MK_raigeki_MK = {{"MK"}, {"down", "forward", "MK"}},
      raigeki_LK = {{"down", "forward", "LK"}},
      raigeki_MK = {{"down", "forward", "MK"}},
      raigeki_HK = {{"down", "forward", "HK"}}
   }
end

local function get_jump_names() return jumps end

local function get_second_jump_names() return second_jumps end

local function get_attack_names() return moves end

local function get_menu_jump_names()
   local jump_names = copytable(jumps)
   for k, name in ipairs(jump_names) do jump_names[k] = "menu_" .. name end
   return jump_names
end

local function get_menu_second_jump_names()
   local jump_names = copytable(second_jumps)
   for k, name in ipairs(jump_names) do jump_names[k] = "menu_" .. name end
   return jump_names
end

local function get_menu_attack_names()
   local move_names = copytable(moves)
   for k, name in ipairs(move_names) do move_names[k] = "menu_" .. name end
   return move_names
end

local function get_move_inputs(name)
   local is_target_combo = false
   is_target_combo = target_combos[name]
   return move_inputs[name], is_target_combo
end

local function get_jump_inputs(name) return jump_inputs[name] end

local function get_move_framedata(char_str, jump_name, move_name)
   if move_name == "throw" then
      if char_str == "chunli" or char_str == "ibuki" or char_str == "oro" then
         return find_frame_data_by_name(char_str, "throw_air")
      else
         move_name = "LP"
      end
   elseif tools.table_contains({"HP_HP", "LP_MK", "MP_HP", "LP_f_HP", "HP_f_MK", "LK_f_MK", "MK_raigeki_MK"}, move_name) then
      move_name = move_inputs[move_name][1][1]
   end
   local jump_prefix = "uf_"
   if jump_name == "jump_neutral" or jump_name == "sjump_neutral" then jump_prefix = "u_" end
   if tools.table_contains({"LP", "MP", "HP", "LK", "MK", "HK"}, move_name) then
      local search_name = jump_prefix .. move_name
      local anim, fdata = find_frame_data_by_name(char_str, search_name)
      if not fdata then
         if jump_prefix == "uf_" then
            jump_prefix = "u_"
         else
            jump_prefix = "uf_"
         end
         search_name = jump_prefix .. move_name
         anim, fdata = find_frame_data_by_name(char_str, search_name)
      end
      return anim, fdata
   elseif move_name == "d_HP" or move_name == "d_MK" then
      return find_frame_data_by_name(char_str, move_name .. "_air")
   else
      return find_frame_data_by_name(char_str, move_name)
   end
end

local function create_settings(dummy)
   local data = {
      jump_replay_mode = 1,
      player_position_mode = 1,
      dummy_offset_mode = 1,
      attack_delay_mode = 1,
      show_jump_arc = false,
      show_jump_info = false,
      automatic_replay = true,
      jumps = {}
   }
   local jump = {
      jump_name = 2,
      player_position = {math.floor(dummy.other.pos_x), math.floor(dummy.other.pos_x)},
      dummy_offset = {math.floor(dummy.pos_x - dummy.other.pos_x), math.floor(dummy.pos_x - dummy.other.pos_x + 20)},
      dummy_offset_mode = 1,
      second_jump_name = 1,
      second_jump_delay = {8, 8},
      attack_name = 1,
      attack_delay = {6, 6},
      attack_delay_mode = 1,
      followup = {special_button = 1, option_select = 1, normal_button = 1, special = 1, type = 1, motion = 1},
      followup_delay = 0
   }
   data.jumps[#data.jumps + 1] = tools.deepcopy(jump)
   jump.jump_name = 1
   for i = 2, max_jumps do data.jumps[#data.jumps + 1] = tools.deepcopy(jump) end
   return data
end

return {
   init = init,
   update_character = update_character,
   get_jump_names = get_jump_names,
   get_second_jump_names = get_second_jump_names,
   get_attack_names = get_attack_names,
   get_menu_jump_names = get_menu_jump_names,
   get_menu_second_jump_names = get_menu_second_jump_names,
   get_menu_attack_names = get_menu_attack_names,
   get_move_inputs = get_move_inputs,
   get_jump_inputs = get_jump_inputs,
   get_move_framedata = get_move_framedata,
   create_settings = create_settings,
   max_jumps = max_jumps
}
