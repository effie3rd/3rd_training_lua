local text = require("src.ui.text")
local fd = require("src.modules.framedata")
local move_data = require("src.modules.move_data")
local gamestate = require("src.gamestate")
local image_tables = require("src.ui.image_tables")
local prediction = require("src.modules.prediction")
local write_memory = require("src.control.write_memory")
local advanced_control = require("src.control.advanced_control")
local inputs = require("src.control.inputs")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local find_frame_data_by_name = fd.find_frame_data_by_name
local is_slow_jumper, is_really_slow_jumper = fd.is_slow_jumper, fd.is_really_slow_jumper
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text,
                                                                                             text.render_text_multiple,
                                                                                             text.get_text_dimensions,

                                                                                             text.get_text_dimensions_multiple
local Delay = advanced_control.Delay
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete
local move_list = move_data.move_list

local jumps
local jumps_default = {"jump_forward", "jump_neutral", "jump_back", "sjump_forward", "sjump_neutral", "sjump_back"}
local additional_jumps = {"air_dash_low", "air_dash_high"}
local moves
local moves_default = {"none", "lp", "mp", "hp", "lk", "mk", "hk", "throw"}
local additional_moves = {
   alex = {"d_hp"},
   chunli = {"d_hp", "d_mk", "hp_hp"},
   elena = {"lp_mk", "mp_hp"},
   gouki = {"d_mk", "gohadouken_lp", "gohadouken_mp", "gohadouken_hp"},
   hugo = {"d_hp"},
   ibuki = {"lp_f_hp", "hp_f_mk", "lk_f_mk", "kunai_lp", "kunai_mp", "kunai_hp", "kunai_ex"},
   makoto = {"tsurugi_lk", "tsurugi_mk", "tsurugi_hk", "tsurugi_ex"},
   necro = {"drill_lk", "drill_mk", "drill_hk"},
   oro = {"hitobashira", "hitobashira_ex"},
   shingouki = {"d_mk", "gohadouken_lp", "gohadouken_mp", "gohadouken_hp"},
   twelve = {"axe_lp", "axe_mp", "axe_hp", "axe_ex", "dra_lk", "dra_mk", "dra_hk", "dra_ex"},
   yang = {"mk_raigeki_mk", "raigeki_lk", "raigeki_mk", "raigeki_hk"},
   yun = {"lp_f_hp", "raigeki_lk", "raigeki_mk", "raigeki_hk"}
}

local move_inputs

local target_combos = {hp_hp = true, lp_mk = true, mp_hp = true, lp_f_hp = true, hp_f_mk = true, lk_f_mk = true}

local jump_inputs = {
   jump_forward = {{"up", "forward"}, {"up", "forward"}, {"up", "forward"}},
   jump_neutral = {{"up"}, {"up"}, {"up"}},
   jump_back = {{"up", "back"}, {"up", "back"}, {"up", "back"}},
   sjump_forward = {{"down"}, {"forward", "up"}, {"forward", "up"}, {"forward", "up"}},
   sjump_neutral = {{"down"}, {"up"}, {"up"}, {"up"}},
   sjump_back = {{"down"}, {"back", "up"}, {"back", "up"}, {"back", "up"}},
   air_dash_low = {{"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {"forward"}},
   air_dash_high = {
      {"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
      {}, {}, {"forward"}, {}, {"forward"}
   }
}

local function update_character(char_str)
   jumps = copytable(jumps_default)
   if char_str == "twelve" then for _, name in ipairs(additional_jumps) do table.insert(jumps, name) end end
   moves = copytable(moves_default)
   if additional_moves[char_str] then for _, name in ipairs(additional_moves) do table.insert(moves, name) end end
end

local function init(char_str)
   update_character(char_str)
   move_inputs = {
      none = {{}},
      lp = {{"LP"}},
      mp = {{"MP"}},
      hp = {{"HP"}},
      lk = {{"LK"}},
      mk = {{"MK"}},
      hk = {{"HK"}},
      throw = {{"LP", "LK"}},
      d_hp = {{"down", "HP"}},
      d_mk = {{"down", "MK"}},
      hp_hp = {{"HP"}, {"HP"}},
      lp_mk = {{"LP"}, {"MK"}},
      mp_hp = {{"MP"}, {"HP"}},
      gohadouken_lp = move_data.get_move_inputs_by_name("gouki", "gohadouken", "LP"),
      gohadouken_mp = move_data.get_move_inputs_by_name("gouki", "gohadouken", "MP"),
      gohadouken_hp = move_data.get_move_inputs_by_name("gouki", "gohadouken", "HP"),
      lp_f_hp = {{"LP"}, {"forward", "HP"}},
      hp_f_mk = {{"HP"}, {"forward", "MK"}},
      lk_f_mk = {{"LK"}, {"forward", "MK"}},
      kunai_lp = move_data.get_move_inputs_by_name("ibuki", "kunai", "LP"),
      kunai_mp = move_data.get_move_inputs_by_name("ibuki", "kunai", "MP"),
      kunai_hp = move_data.get_move_inputs_by_name("ibuki", "kunai", "HP"),
      kunai_ex = move_data.get_move_inputs_by_name("ibuki", "kunai", "EX"),
      tsurugi_lk = move_data.get_move_inputs_by_name("makoto", "tsurugi", "LK"),
      tsurugi_mk = move_data.get_move_inputs_by_name("makoto", "tsurugi", "MK"),
      tsurugi_hk = move_data.get_move_inputs_by_name("makoto", "tsurugi", "HK"),
      tsurugi_ex = move_data.get_move_inputs_by_name("makoto", "tsurugi", "EX"),
      drill_lk = {{"down", "LK"}},
      drill_mk = {{"down", "MK"}},
      drill_hk = {{"down", "HK"}},
      hitobashira = move_data.get_move_inputs_by_name("oro", "hitobashira", "LK"),
      hitobashira_ex = move_data.get_move_inputs_by_name("oro", "hitobashira", "EX"),
      axe_lp = move_data.get_move_inputs_by_name("twelve", "axe", "LP"),
      axe_mp = move_data.get_move_inputs_by_name("twelve", "axe", "MP"),
      axe_hp = move_data.get_move_inputs_by_name("twelve", "axe", "HP"),
      axe_ex = move_data.get_move_inputs_by_name("twelve", "axe", "EX"),
      dra_lk = move_data.get_move_inputs_by_name("twelve", "dra", "LK"),
      dra_mk = move_data.get_move_inputs_by_name("twelve", "dra", "MK"),
      dra_hk = move_data.get_move_inputs_by_name("twelve", "dra", "HK"),
      dra_ex = move_data.get_move_inputs_by_name("twelve", "dra", "EX"),
      mk_raigeki_mk = {{"MK"}, {"down", "forward", "MK"}},
      raigeki_lk = {{"down", "forward", "LK"}},
      raigeki_mk = {{"down", "forward", "MK"}},
      raigeki_hk = {{"down", "forward", "HK"}}
   }
end

local function get_jump_names()
   local jump_names = copytable(jumps)
   for k, name in pairs(jump_names) do jump_names[k] = "menu_" .. name end
   return jump_names
end

local function get_move_names()
   local move_names = copytable(moves)
   for k, name in pairs(move_names) do move_names[k] = "menu_" .. name end
   return move_names
end

local function get_move_inputs(name)
   local is_target_combo = false
   is_target_combo = target_combos[name]
   return move_inputs[name], is_target_combo
end

local function get_jump_inputs(name)
   return jump_inputs[name]
end

return {
   init = init,
   get_jump_names = get_jump_names,
   get_move_names = get_move_names,
   get_move_inputs = get_move_inputs,
   get_jump_inputs = get_jump_inputs
}