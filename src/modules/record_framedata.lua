local loading = require("src.loading")
local text = require("src.ui.text")
local fd = require("src.modules.framedata")
local move_data = require("src.modules.move_data")
local game_data = require("src.modules.game_data")
local gamestate = require("src.gamestate")
local character_select = require("src.control.character_select")
local inputs = require("src.control.inputs")
local settings = require("src.settings")
local tools = require("src.tools")
local write_memory = require("src.control.write_memory")
local debug_settings = require("src.debug_settings")
local json = require("src.libs.dkjson")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local find_frame_data_by_name = fd.find_frame_data_by_name
local is_slow_jumper, is_really_slow_jumper = fd.is_slow_jumper, fd.is_really_slow_jumper
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text,
                                                                                             text.render_text_multiple,
                                                                                             text.get_text_dimensions,
                                                                                             text.get_text_dimensions_multiple
local move_list, get_move_inputs_by_name = move_data.move_list, move_data.get_move_inputs_by_name
local frame_data_keys = copytable(game_data.characters)
table.insert(frame_data_keys, "projectiles")

local state = ""
local setup = false
local normals = {}
local jumping_normals = {
   {{"LP"}}, {{"MP"}}, {{"HP"}}, {{"LK"}}, {{"MK"}}, {{"HK"}}, {{"LP"}}, {{"MP"}}, {{"HP"}}, {{"LK"}}, {{"MK"}},
   {{"HK"}}, {{"LP"}}, {{"MP"}}, {{"HP"}}, {{"LK"}}, {{"MK"}}, {{"HK"}}
}
local normals_list = {
   alex = {
      {sequence = {{"LP"}}, far = true, offset_x = -14, self_chain = true}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}},
      {sequence = {{"down", "LP"}}, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}, max_hits = 2}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   chunli = {
      {sequence = {{"LP"}}, far = true, offset_x = -14, self_chain = true}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}, far = true},
      {sequence = {{"HK"}}, far = true}, {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true},
      {sequence = {{"down", "MP"}}, block = {2}}, {sequence = {{"down", "HP"}}},
      {sequence = {{"down", "LK"}}, block = {2}, self_chain = true}, {sequence = {{"down", "MK"}}, block = {2}},
      {sequence = {{"down", "HK"}}}
   },
   dudley = {
      {sequence = {{"LP"}}, self_chain = true}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}}, {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}, offset_x = -14, self_chain = true},
      {sequence = {{"down", "MP"}}}, {sequence = {{"down", "HP"}}},
      {sequence = {{"down", "LK"}}, offset_x = -14, block = {2}, self_chain = true},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   elena = {
      {sequence = {{"LP"}}}, {sequence = {{"MP"}}, max_hits = 2}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}}, {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   gill = {
      {sequence = {{"LP"}}, self_chain = true}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}}, {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}, self_chain = true},
      {sequence = {{"down", "MP"}}}, {sequence = {{"down", "HP"}}, max_hits = 2},
      {sequence = {{"down", "LK"}}, block = {2}, self_chain = true}, {sequence = {{"down", "MK"}}, block = {2}},
      {sequence = {{"down", "HK"}}, block = {2}}
   },
   gouki = {
      {sequence = {{"LP"}}, far = true, offset_x = -16, self_chain = true},
      {sequence = {{"MP"}}, far = true, offset_x = -10}, {sequence = {{"HP"}}, far = true, offset_x = -10},
      {sequence = {{"LK"}}}, {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}, far = true},
      {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, offset_x = -24, block = {2}, self_chain = true},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   hugo = {
      {sequence = {{"LP"}}, self_chain = true}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}, max_hits = 2}, {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}, self_chain = true},
      {sequence = {{"down", "MP"}}}, {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   ibuki = {
      {sequence = {{"LP"}}, offset_x = -14, self_chain = true, delay = {3}}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}, far = true}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}},
      {sequence = {{"HK"}}, far = true}, {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true, delay = {4}},
      {sequence = {{"down", "MP"}}}, {sequence = {{"down", "HP"}}},
      {sequence = {{"down", "LK"}}, offset_x = -24, block = {2}, self_chain = true, delay = {3}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   ken = {
      {sequence = {{"LP"}}, far = true, offset_x = -16, self_chain = true},
      {sequence = {{"MP"}}, far = true, offset_x = -10}, {sequence = {{"HP"}}, far = true, offset_x = -10},
      {sequence = {{"LK"}}}, {sequence = {{"MK"}}}, {sequence = {{"HK"}}},
      {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, offset_x = -24, block = {2}, self_chain = true},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   makoto = {
      {sequence = {{"LP"}}, offset_x = -38, self_chain = true, delay = {3}}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}}, {sequence = {{"HK"}}},
      {sequence = {{"down", "LP"}}, offset_x = -38, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}, block = {2}}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}}, {sequence = {{"down", "HK"}}}
   },
   necro = {
      {sequence = {{"LP"}}}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}},
      {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   oro = {
      {sequence = {{"LP"}}, far = true, offset_x = -12}, {sequence = {{"MP"}}, far = true},
      {sequence = {{"HP"}}, max_hits = 2}, {sequence = {{"LK"}}, far = true, offset_x = -16},
      {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}},
      {sequence = {{"down", "LP"}}, offset_x = -16, self_chain = true, delay = {6}}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}},
      {sequence = {{"down", "LK"}}, block = {2}, offset_x = -16, self_chain = true, delay = {4}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   q = {
      {sequence = {{"LP"}}, offset_x = -16, far = true, self_chain = true}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"LK"}}, offset_x = -16, self_chain = true, delay = {4}},
      {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}},
      {sequence = {{"down", "MP"}}}, {sequence = {{"down", "HP"}}, block = {2}},
      {sequence = {{"down", "LK"}}, block = {2}}, {sequence = {{"down", "MK"}}, block = {2}},
      {sequence = {{"down", "HK"}}, block = {2}}
   },
   remy = {
      {sequence = {{"LP"}}, offset_x = -16, far = true, self_chain = true}, {sequence = {{"MP"}}, far = true},
      {sequence = {{"HP"}}, far = true}, {sequence = {{"LK"}}, far = true, offset_x = -10},
      {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}, far = true},
      {sequence = {{"down", "LP"}}, offset_x = -16, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, max_hits = 2, block = {2, 2}}
   },
   ryu = {
      {sequence = {{"LP"}}, far = true, offset_x = -16, self_chain = true},
      {sequence = {{"MP"}}, far = true, offset_x = -10}, {sequence = {{"HP"}}, far = true, offset_x = -10},
      {sequence = {{"LK"}}}, {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}},
      {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, block = {2}, offset_x = -24, self_chain = true},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   sean = {
      {sequence = {{"LP"}}, offset_x = -16, self_chain = true}, {sequence = {{"MP"}}, far = true},
      {sequence = {{"HP"}}, far = true}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}},
      {sequence = {{"HK"}}, far = true}, {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true},
      {sequence = {{"down", "MP"}}}, {sequence = {{"down", "HP"}}},
      {sequence = {{"down", "LK"}}, block = {2}, offset_x = -24, self_chain = true},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   shingouki = {
      {sequence = {{"LP"}}, far = true, offset_x = -10}, {sequence = {{"MP"}}, far = true, offset_x = -10},
      {sequence = {{"HP"}}, far = true, offset_x = -10}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}, far = true},
      {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   twelve = {
      {sequence = {{"LP"}}}, {sequence = {{"MP"}}, far = true}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}}, {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}, max_hits = 3},
      {sequence = {{"down", "LK"}}, block = {2}, self_chain = true, delay = {8}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, max_hits = 3, block = {2, 2, 2}}
   },
   urien = {
      {sequence = {{"LP"}}, offset_x = -16, self_chain = true}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}},
      {sequence = {{"LK"}}}, {sequence = {{"MK"}}}, {sequence = {{"HK"}}, max_hits = 2, offset_x = -10},
      {sequence = {{"down", "LP"}}, offset_x = -16, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}, max_hits = 2}, {sequence = {{"down", "LK"}}, block = {2}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   yang = {
      {sequence = {{"LP"}}, offset_x = -24, self_chain = true}, {sequence = {{"MP"}}, far = true},
      {sequence = {{"HP"}}, far = true}, {sequence = {{"LK"}}}, {sequence = {{"MK"}}, far = true},
      {sequence = {{"HK"}}}, {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true},
      {sequence = {{"down", "MP"}}, block = {2}}, {sequence = {{"down", "HP"}}, max_hits = 2},
      {sequence = {{"down", "LK"}}, block = {2}, offset_x = -24, self_chain = true, delay = {4}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   },
   yun = {
      {sequence = {{"LP"}}, far = true, offset_x = -24, self_chain = true},
      {sequence = {{"MP"}}, far = true, offset_x = -10}, {sequence = {{"HP"}}, far = true}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}, far = true}, {sequence = {{"HK"}}},
      {sequence = {{"down", "LP"}}, offset_x = -24, self_chain = true}, {sequence = {{"down", "MP"}}},
      {sequence = {{"down", "HP"}}, max_hits = 2},
      {sequence = {{"down", "LK"}}, block = {2}, offset_x = -24, self_chain = true, delay = {4}},
      {sequence = {{"down", "MK"}}, block = {2}}, {sequence = {{"down", "HK"}}, block = {2}}
   }
}

local other_normals_list = {
   alex = {
      {sequence = {{"LP"}}, offset_x = -28, self_chain = true}, {sequence = {{"forward", "MP"}}},
      {sequence = {{"forward", "HP"}}}, {sequence = {{"back", "HP"}}}, {sequence = {{"MK"}}},
      {sequence = {{"down", "HP"}}, air = true, player_offset_y = 60, ignore_next_anim = true}
   },
   chunli = {
      {sequence = {{"LP"}}, offset_x = -28}, {sequence = {{"MK"}}, max_hits = 3}, {sequence = {{"forward", "MK"}}},
      {sequence = {{"HK"}}}, {sequence = {{"forward", "HK"}}}, {sequence = {{"down", "forward", "HK"}}},
      {sequence = {{"back", "MP"}}, max_hits = 2}, {sequence = {{"back", "HP"}}},
      {sequence = {{"down", "MK"}}, air = true, player_offset_y = 55, ignore_next_anim = true},
      {sequence = {{"down", "HP"}}, air = true, player_offset_y = 25}
   },
   dudley = {
      {sequence = {{"forward", "LP"}}, self_chain = true}, {sequence = {{"forward", "MP"}}},
      {sequence = {{"forward", "MK"}}}, {sequence = {{"forward", "HP"}}}, {sequence = {{"forward", "HK"}}}
   },
   elena = {
      {sequence = {{"forward", "MP"}}}, {sequence = {{"forward", "MK"}}},
      {sequence = {{"down", "forward", "HK"}}, block = {2}}, {sequence = {{"back", "HK"}}}
   },
   gill = {{sequence = {{"back", "MP"}}}, {sequence = {{"forward", "MK"}}}},
   gouki = {
      {sequence = {{"LP"}}, offset_x = -16, self_chain = true, delay = {2}}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"MK"}}}, {sequence = {{"HK"}}, max_hits = 2},
      {sequence = {{"forward", "MP"}}, max_hits = 2, block = {4, 4}},
      {sequence = {{"down", "MK"}}, air = true, player_offset_y = 50, ignore_next_anim = true}
   },
   hugo = {
      {sequence = {{"forward", "HP"}}},
      {sequence = {{"down", "HP"}}, air = true, player_offset_y = 10, ignore_next_anim = true}
   },
   ibuki = {
      {sequence = {{"LP"}}, offset_x = -17, self_chain = true, delay = {4}},
      {sequence = {{"HP"}}, max_hits = 2, offset_x = -17}, {sequence = {{"HK"}}, max_hits = 2},
      {sequence = {{"forward", "HK"}}}, {sequence = {{"forward", "MK"}}},
      {sequence = {{"forward", "LK"}}, self_chain = true}, {sequence = {{"back", "MP"}}, max_hits = 2},
      {sequence = {{"back", "MK"}}}, {sequence = {{"down", "forward", "MK"}}, block = {2}}
   },
   ken = {
      {sequence = {{"LP"}}, offset_x = -16, self_chain = true, delay = {2}}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"forward", "MK"}}}, {sequence = {{"back", "MK"}}, max_hits = 2},
      {sequence = {{"MK"}}, name = "MK_hold", offset_x = 10, max_hits = 3}, {sequence = {{"forward", "HK"}}},
      {sequence = {{"forward", "HK"}}, name = "f_HK_hold", max_hits = 0}
   },
   makoto = {
      {sequence = {{"forward", "LP"}}, self_chain = true, delay = {2}}, {sequence = {{"forward", "MP"}}},
      {sequence = {{"forward", "LK"}}}, {sequence = {{"forward", "MK"}}}, {sequence = {{"forward", "HK"}}, block = {2}},
      {sequence = {{"forward", "HK"}}, name = "f_HK_hold", max_hits = 0}
   },
   necro = {
      {sequence = {{"back", "LP"}}}, {sequence = {{"back", "MP"}}}, {sequence = {{"back", "HP"}}},
      {sequence = {{"back", "LK"}}, self_chain = true, delay = {2}}, {sequence = {{"back", "MK"}}},
      {sequence = {{"back", "HK"}}}, {sequence = {{"down", "back", "HP"}}, offset_x = 24},
      {sequence = {{"down", "LK"}}, air = true, name = "drill_LK", max_hits = 2, ignore_next_anim = true},
      {sequence = {{"down", "MK"}}, air = true, name = "drill_MK", max_hits = 2, ignore_next_anim = true},
      {sequence = {{"down", "HK"}}, air = true, name = "drill_HK", max_hits = 2, ignore_next_anim = true}
   },
   oro = {
      {sequence = {{"LP"}}, offset_x = -28, self_chain = true, delay = {4}}, {sequence = {{"MP"}}, max_hits = 2},
      {sequence = {{"LK"}}, offset_x = -24, self_chain = true, delay = {6}}, {sequence = {{"MK"}}},
      {sequence = {{"forward", "MP"}}}
   },
   q = {
      {sequence = {{"LP"}}}, {sequence = {{"MK"}}}, {sequence = {{"back", "MP"}}}, {sequence = {{"back", "HP"}}},
      {sequence = {{"back", "HK"}}}
   },
   remy = {
      {sequence = {{"LP"}}, self_chain = true}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"LK"}}},
      {sequence = {{"MK"}}}, {sequence = {{"HK"}}, max_hits = 2, offset_x = -14}, {sequence = {{"forward", "MK"}}}
   },
   ryu = {
      {sequence = {{"LP"}}, offset_x = -16, self_chain = true, delay = {2}}, {sequence = {{"MP"}}},
      {sequence = {{"HP"}}}, {sequence = {{"MK"}}}, {sequence = {{"forward", "MP"}}, max_hits = 2, block = {4, 4}},
      {sequence = {{"forward", "HP"}}, max_hits = 2}
   },
   sean = {
      {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"HK"}}},
      {sequence = {{"forward", "HP"}}, max_hits = 2, block = {4, 4}}, {sequence = {{"forward", "HK"}}}
   },
   shingouki = {
      {sequence = {{"LP"}}, offset_x = -20}, {sequence = {{"MP"}}}, {sequence = {{"HP"}}}, {sequence = {{"MK"}}},
      {sequence = {{"forward", "MP"}}, max_hits = 2, block = {4, 4}},
      {sequence = {{"down", "MK"}}, air = true, player_offset_y = 50, ignore_next_anim = true}
   },
   twelve = {
      {sequence = {{"MP"}}}, {sequence = {{"back", "MK"}}}, {sequence = {{"LP"}}, air_dash = true, reset_pos_x = 300},
      {sequence = {{"MP"}}, air_dash = true, reset_pos_x = 300},
      {sequence = {{"HP"}}, air_dash = true, reset_pos_x = 300},
      {sequence = {{"LK"}}, air_dash = true, reset_pos_x = 300},
      {sequence = {{"MK"}}, air_dash = true, reset_pos_x = 300},
      {sequence = {{"HK"}}, air_dash = true, reset_pos_x = 300, player_offset_y = 30}
   },
   urien = {{sequence = {{"forward", "MP"}}}, {sequence = {{"forward", "HP"}}}, {sequence = {{"forward", "MK"}}}},
   yang = {
      {sequence = {{"MP"}}, offset_x = -10}, {sequence = {{"HP"}}, max_hits = 2, offset_x = -10},
      {sequence = {{"MK"}}, offset_x = -22}, {sequence = {{"forward", "MK"}}, offset_x = 50}, {
         sequence = {{"down", "forward", "LK"}},
         name = "raigeki_LK",
         air = true,
         player_offset_y = 64,
         ignore_next_anim = true
      }, {
         sequence = {{"down", "forward", "MK"}},
         name = "raigeki_MK",
         air = true,
         player_offset_y = 64,
         ignore_next_anim = true
      }, {
         sequence = {{"down", "forward", "HK"}},
         name = "raigeki_HK",
         air = true,
         player_offset_y = 64,
         ignore_next_anim = true
      }
   },
   yun = {
      {sequence = {{"LP"}}, offset_x = -14, self_chain = true}, {sequence = {{"MP"}}, offset_x = -10},
      {sequence = {{"HP"}}, max_hits = 2, offset_x = -10}, {sequence = {{"MK"}}, offset_x = -22},
      {sequence = {{"forward", "MK"}}, offset_x = 50}, {sequence = {{"forward", "HP"}}, offset_x = 50}, {
         sequence = {{"down", "forward", "LK"}},
         name = "raigeki_LK",
         air = true,
         player_offset_y = 64,
         ignore_next_anim = true
      }, {
         sequence = {{"down", "forward", "MK"}},
         name = "raigeki_MK",
         air = true,
         player_offset_y = 64,
         ignore_next_anim = true
      }, {
         sequence = {{"down", "forward", "HK"}},
         name = "raigeki_HK",
         air = true,
         player_offset_y = 64,
         ignore_next_anim = true
      }
   }
}
local other_normals = {}
local target_combos_list = {
   alex = {
      {
         sequence = {{"down", "LK"}, {"down", "MK"}},
         max_hits = 2,
         block = {2, 2},
         delay = {0, 1},
         optional_anim = {0, 1}
      },
      {
         sequence = {{"down", "LK"}, {"down", "HK"}},
         max_hits = 2,
         block = {2, 2},
         delay = {0, 3},
         optional_anim = {0, 1}
      }
   },
   chunli = {
      {sequence = {{"HP"}, {"HP"}}, max_hits = 2, air = true, offset_x = -22, cancel_on_whiff = true},
      optional_anim = {0, 1}
   },
   dudley = {
      {sequence = {{"forward", "LP"}, {"MP"}}, max_hits = 2, optional_anim = {0, 1}, delay = {0, 5}},
      {sequence = {{"LP"}, {"MP"}, {"MK"}}, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"down", "LK"}, {"MK"}}, max_hits = 2, block = {2, 1}, optional_anim = {0, 1}}, {
         sequence = {{"down", "LK"}, {"down", "MP"}, {"down", "HP"}},
         max_hits = 3,
         block = {2, 1, 1},
         optional_anim = {0, 1, 1}
      }, {sequence = {{"LK"}, {"MK"}, {"MP"}, {"HP"}}, max_hits = 5, optional_anim = {0, 1, 1, 1, 0}},
      {sequence = {{"MP"}, {"MK"}, {"HP"}}, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"forward", "MK"}, {"MK"}, {"HP"}}, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"MK"}, {"HK"}, {"HP"}}, max_hits = 4, optional_anim = {0, 1, 1, 0}},
      {sequence = {{"forward", "HK"}, {"MK"}}, max_hits = 2, optional_anim = {0, 1}}
   },
   elena = {
      {sequence = {{"MK"}, {"down", "HP"}}, max_hits = 2, optional_anim = {0, 1}},
      {sequence = {{"HP"}, {"HK"}}, max_hits = 2, optional_anim = {0, 1}},
      {sequence = {{"LP"}, {"MK"}}, max_hits = 2, air = true, optional_anim = {0, 1}, offset_x = -10},
      {sequence = {{"MP"}, {"HP"}}, max_hits = 2, air = true, optional_anim = {0, 1}}
   },
   gill = {
      {sequence = {{"LP"}, {"MP"}}, max_hits = 2, delay = {0, 5}, optional_anim = {0, 1}},
      {
         sequence = {{"down", "LK"}, {"down", "MK"}},
         max_hits = 2,
         block = {2, 2},
         delay = {0, 3},
         optional_anim = {0, 1}
      }
   },
   gouki = {{sequence = {{"MP"}, {"HP"}}, max_hits = 2, optional_anim = {0, 1}}},
   hugo = {},
   ibuki = {
      {
         sequence = {{"HP"}, {"HP"}},
         max_hits = 2,
         far = true,
         offset_x = -22,
         cancel_on_whiff = true,
         optional_anim = {0, 1}
      }, {sequence = {{"LP"}, {"MP"}, {"HP"}}, max_hits = 3, offset_x = -18, optional_anim = {0, 1, 1}},
      {sequence = {{"LK"}, {"MK"}, {"HK"}}, max_hits = 3, optional_anim = {0, 1, 1}}, {
         sequence = {{"LP"}, {"MP"}, {"down", "HK"}, {"HK"}},
         max_hits = 5,
         cancel_on_hit = {1, 0, 1, 1},
         block = {1, 1, 1, 2, 1},
         offset_x = -18,
         delay = {0, 0, 1, 0, 0},
         optional_anim = {0, 1, 0, 1, 1}
      }, {
         sequence = {{"back", "MP"}, {"down", "HK"}, {"HK"}},
         max_hits = 4,
         cancel_on_hit = {0, 1, 1},
         block = {1, 1, 2, 1},
         delay = {0, 1, 0, 0},
         optional_anim = {0, 0, 1, 1}
      }, {sequence = {{"down", "HK"}, {"HK"}}, max_hits = 3, block = {2, 1, 1}, optional_anim = {0, 1, 0}},
      {sequence = {{"down", "HK"}, {"HK"}}, max_hits = 2, far = true, block = {2, 1}, optional_anim = {0, 1}}, {
         sequence = {{"HP"}, {"down", "HK"}, {"HK"}},
         offset_x = -17,
         max_hits = 4,
         cancel_on_hit = {0, 1, 1},
         block = {1, 1, 2, 1},
         delay = {0, 1, 0, 0},
         optional_anim = {0, 0, 1, 1}
      }, {sequence = {{"back", "MK"}, {"forward", "MK"}}, max_hits = 2, block = {1, 1}, optional_anim = {0, 1}},
      {sequence = {{"LP"}, {"MP"}, {"forward", "LK"}}, max_hits = 3, offset_x = 6, optional_anim = {0, 1, 1}},
      {sequence = {{"back", "MP"}, {"HP"}}, max_hits = 2, optional_anim = {0, 1}},
      {sequence = {{"LK"}, {"forward", "MK"}}, max_hits = 2, air = true, optional_anim = {0, 1}},
      {sequence = {{"LP"}, {"forward", "HP"}}, max_hits = 2, air = true, optional_anim = {0, 1}},
      {sequence = {{"HP"}, {"forward", "MK"}}, max_hits = 2, air = true, optional_anim = {0, 1}}
   },
   ken = {{sequence = {{"MP"}, {"HP"}}, max_hits = 2, optional_anim = {0, 1}}},
   makoto = {
      {sequence = {{"LK"}, {"MK"}}, offset_x = 10, max_hits = 2, cancel_on_whiff = true, optional_anim = {0, 1}}, {
         sequence = {{"forward", "HP"}, {"HP"}},
         dummy_offset_list = {{200, 0}, {80, 0}, {80, 0}},
         max_hits = 3,
         cancel_on_whiff = true,
         optional_anim = {0, 1, 0}
      },
      {
         sequence = {{"forward", "MK"}, {"HK"}},
         dummy_offset_list = {{200, 0}, {80, 0}},
         max_hits = 2,
         optional_anim = {0, 1}
      }
   },
   necro = {{sequence = {{"back", "LK"}, {"MP"}}, max_hits = 2, optional_anim = {0, 1}}},
   oro = {{sequence = {{"LK"}, {"MK"}}, offset_x = -24, max_hits = 2, optional_anim = {0, 1}}},
   q = {},
   remy = {{sequence = {{"MK"}, {"HK"}}, offset_x = 6, max_hits = 2, optional_anim = {0, 1}}},
   ryu = {{sequence = {{"HP"}, {"HK"}}, far = true, max_hits = 2, offset_x = -10, optional_anim = {0, 1}}},
   sean = {
      {sequence = {{"MP"}, {"HK"}}, max_hits = 2, optional_anim = {0, 1}},
      {sequence = {{"HP"}, {"forward", "HP"}}, max_hits = 3, optional_anim = {0, 1, 0}}
   },
   shingouki = {{sequence = {{"MP"}, {"HP"}}, max_hits = 2, optional_anim = {0, 1}}},
   twelve = {},
   urien = {
      {sequence = {{"LP"}, {"MP"}}, max_hits = 2, optional_anim = {0, 1}},
      {sequence = {{"forward", "MP"}, {"forward", "HP"}}, offset_x = 12, max_hits = 2, optional_anim = {0, 1}}
   },
   yang = {
      {sequence = {{"MP"}, {"HP"}, {"back", "HP"}}, offset_x = -10, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"MP"}, {"HP"}, {"back", "HP"}}, far = true, offset_x = -30, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"LK"}, {"MK"}, {"HK"}}, offset_x = -10, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"MK"}, {"down", "forward", "MK"}}, max_hits = 2, air = true, offset_x = -30, optional_anim = {0, 1}}
   },
   yun = {
      {sequence = {{"LP"}, {"LK"}, {"MP"}}, max_hits = 3, offset_x = -14, optional_anim = {0, 1, 1}},
      {sequence = {{"MP"}, {"HP"}, {"back", "HP"}}, offset_x = -10, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"MP"}, {"HP"}, {"back", "HP"}}, far = true, offset_x = -30, max_hits = 3, optional_anim = {0, 1, 1}},
      {sequence = {{"down", "MP"}, {"down", "HP"}}, max_hits = 3, optional_anim = {0, 1, 0}},
      {sequence = {{"down", "HK"}, {"HK"}}, max_hits = 2, block = {2, 1}, optional_anim = {0, 1}}, {
         sequence = {{"LP"}, {"forward", "HP"}},
         max_hits = 2,
         air = true,
         player_offset_y = -24,
         offset_x = -20,
         optional_anim = {0, 1}
      }
   }
}
local target_combos = {}

local throw_uoh_pa = {
   {sequence = {{"LP", "LK"}}, name = "throw_neutral"}, {sequence = {{"forward", "LP", "LK"}}, name = "throw_forward"},
   {sequence = {{"back", "LP", "LK"}}, name = "throw_back"}, {sequence = {{"MP", "MK"}}, name = "uoh"},
   {sequence = {{"HP", "HK"}}, name = "pa"}
}

local reverse_power_bomb = tools.combine_arrays(get_move_inputs_by_name("alex", "flash_chop", "MP"), {
   {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
   {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
})
reverse_power_bomb = tools.combine_arrays(reverse_power_bomb, get_move_inputs_by_name("alex", "power_bomb", "MP"))

local wakeups_list = {
   -- {character = "ibuki", name = "raida", sequence = get_move_inputs_by_name("ibuki","raida","HP")},
   {character = "ibuki", name = "throw", sequence = {{"forward", "LP", "LK"}}},
   {character = "ibuki", name = "d_hk", sequence = {{"down", "HK"}}},
   {character = "ibuki", name = "kazekiri", sequence = get_move_inputs_by_name("ibuki", "kazekiri", "LK"), quick = true},
   {character = "ibuki", name = "kubiori", sequence = get_move_inputs_by_name("ibuki", "kubiori", "EXP"), quick = true}
}

local data_path = "data/" .. game_data.rom_name .. "/"
local framedata_path = data_path .. "framedata/"
local frame_data_file_ext = "_framedata.json"
local final_props = {
   "name", "frames", "hit_frames", "idle_frames", "loops", "pushback", "advantage", "uses_velocity", "air",
   "infinite_loop", "max_hits", "cooldown", "self_chain", "exceptions", "landing_height"
}
local final_frame_props = {
   "hash", "boxes", "movement", "velocity", "acceleration", "loop", "next_anim", "optional_anim", "wakeup",
   "bypass_freeze", "projectile"
}
local function save_frame_data()
   for _, char in ipairs(frame_data_keys) do
      if frame_data[char].should_save then
         frame_data[char].should_save = nil
         local fdata = tools.deepcopy(frame_data[char])
         if not (char == "projectiles") then
            fdata.standing = ""
            fdata.standing_turn = ""
            fdata.standing_begin = ""
            fdata.crouching = ""
            fdata.crouching_turn = ""
            fdata.crouching_begin = ""
            fdata.walk_forward = ""
            fdata.walk_back = ""
            fdata.walk_transition = ""
            fdata.jump_recovery = ""
            fdata.block_high = ""
            fdata.block_high_proximity = ""
            fdata.block_low = ""
            fdata.block_low_proximity = ""
            fdata.block_high_air = ""
            fdata.block_high_air_proximity = ""
            fdata.parry_high = ""
            fdata.parry_low = ""
            fdata.parry_air = ""
            if not fdata.wakeups then fdata.wakeups = {} end
         end
         for id, data in pairs(fdata) do
            if type(data) == "table" and id ~= "wakeups" then
               for k, v in pairs(data) do
                  if k == "name" then
                     if v == "standing" then
                        fdata.standing = id
                     elseif v == "standing_turn" then
                        fdata.standing_turn = id
                     elseif v == "standing_begin" then
                        fdata.standing_begin = id
                     elseif v == "crouching" then
                        fdata.crouching = id
                     elseif v == "crouching_turn" then
                        fdata.crouching_turn = id
                     elseif v == "crouching_begin" then
                        fdata.crouching_begin = id
                     elseif v == "walk_forward" then
                        fdata.walk_forward = id
                     elseif v == "walk_back" then
                        fdata.walk_back = id
                     elseif v == "walk_transition" then
                        fdata.walk_transition = id
                     elseif v == "jump_recovery" then
                        fdata.jump_recovery = id
                     elseif v == "block_high" then
                        fdata.block_high = id
                     elseif v == "block_high_proximity" then
                        fdata.block_high_proximity = id
                     elseif v == "block_low" then
                        fdata.block_low = id
                     elseif v == "block_low_proximity" then
                        fdata.block_low_proximity = id
                     elseif v == "block_high_air" then
                        fdata.block_high_air = id
                     elseif v == "block_high_air_proximity" then
                        fdata.block_high_air_proximity = id
                     elseif v == "parry_high" then
                        fdata.parry_high = id
                     elseif v == "parry_low" then
                        fdata.parry_low = id
                     elseif v == "parry_air" then
                        fdata.parry_air = id
                     elseif string.find(v, "wakeup") then
                        if not tools.table_contains_deep(fdata.wakeups, id) then
                           table.insert(fdata.wakeups, id)
                        end
                     end
                  else
                     if k == "hit_frames" then
                        if tools.deep_equal(v, {}) then fdata[id][k] = nil end
                     end
                  end
                  if not tools.table_contains_deep(final_props, k) then data[k] = nil end
               end

               local frames = {}
               if data.frames then
                  for i, frame in ipairs(data.frames) do
                     for k, v in pairs(data.frames[i]) do
                        if not tools.table_contains_deep(final_frame_props, k) then
                           data.frames[i][k] = nil
                        end
                        if k == "movement" or k == "velocity" or k == "acceleration" then
                           if tools.deep_equal(v, {0, 0}) then data.frames[i][k] = nil end
                        elseif k == "boxes" then
                           if tools.deep_equal(v, {}) then data.frames[i][k] = nil end
                        end
                     end
                     table.insert(frames, data.frames[i])
                  end
                  data.frames = frames
               else
                  print("no frames", id)
               end
            end
         end
         local file_path = framedata_path .. "@" .. char .. frame_data_file_ext
         if not tools.write_object_to_json_file(fdata, file_path, true) then
            print(string.format("Error: Failed to write frame data to \"%s\"", file_path))
         else
            print(string.format("Saved frame data to \"%s\"", file_path))
         end
      end
   end
end

local current_attack

local rec = {
   tc_hit_index = 1,
   block_until = 0,
   received_hits = 0,
   block_max_hits = 0,
   block_pattern = nil,
   begin_recording_pushback = false,
   unfreeze_player = false,
   unfreeze_dummy = false,

   specials = {},
   supers = {},

   current_projectile = nil,
   freeze_player_for_projectile = false,

   recording = false,
   recording_projectiles = false,
   self_freeze = 10,
   recording_self_freeze = false,
   recording_opponent_freeze = false,
   recording_recovery = false,
   recording_pushback = false,
   recording_options = {hit_type = "miss"},
   recording_hit_types = {"miss", "block"},
   i_recording_hit_types = 1,
   attack_categories = {},
   current_attack_category = {},
   i_attack_categories = 1,
   i_attacks = 1,
   last_category = 7,
   recording_geneijin = false,
   dummy_offset_x = 0,
   dummy_offset_y = 0,
   reset_pos_x = 444,
   default_air_miss_height = 200,
   default_air_block_height = 26,
   current_recording_acceleration_offset = 0,
   overwrite = false,
   first_record = true
}

local function land_player(obj)
   memory.writeword(obj.base + 0x64 + 36, -1)
   memory.writeword(obj.base + 0x64 + 38, 0)
   Queue_Command(gamestate.frame_number + 1, function() rec.current_recording_acceleration_offset = -1 end)
end

local function block_high(player)
   inputs.queue_input_sequence(player, {{"back"}})
   write_memory.clear_motion_data(player)
end

local function block_low(player)
   inputs.queue_input_sequence(player, {{"down", "back"}})
   write_memory.clear_motion_data(player)
end

local function is_hit_frame(frame)
   if frame.boxes then
      for _, box in pairs(frame.boxes) do
         local type = tools.convert_box_types[box[1]]
         if type == "attack" or type == "throw" then return true end
      end
   end
   return false
end

local next_anim_types = {"next_anim", "optional_anim"}
local props_to_copy = {
   "self_freeze", "opponent_freeze", "opponent_recovery", "pushback", "wakeup", "bypass_freeze", "projectile"
}

local function copy_props(source_frame, dest_frame, props_to_copy)
   for _, prop in pairs(props_to_copy) do if source_frame[prop] then dest_frame[prop] = source_frame[prop] end end
end

local function is_idle_frame(frame)
   if frame.idle then return true end
   return false
end

local function divide_hit_frames(anim)
   local result = {}

   if anim.hit_frames then
      for _, hf in pairs(anim.hit_frames) do
         local hf_start = hf[1]
         local hf_end = hf[2]
         local search_start = math.min(hf[1] + 2, hf_end + 1)
         local i = search_start
         while i <= hf[2] + 1 do
            local section_end = -1
            if anim.frames[i].hit_start then
               section_end = math.max(i - 2, hf_start)
            elseif i == hf_end + 1 then
               section_end = hf[2]
            end

            if section_end ~= -1 then
               table.insert(result, {hf_start, section_end})
               hf_start = section_end + 1
               if anim.frames[i].hit_start and hf_start == hf_end then
                  table.insert(result, {hf_start, hf_end})
               end
            end

            i = i + 1

         end
      end
   end
   return result
end

local function calculate_ranges(list, predicate)
   local ranges = {}
   local in_range = false
   local range_start = nil

   for i, value in ipairs(list) do
      if predicate(value) then
         if not in_range then
            in_range = true
            range_start = i
         end
      else
         if in_range then
            table.insert(ranges, {range_start, i - 1})
            in_range = false
         end
      end
   end

   if in_range then table.insert(ranges, {range_start, #list}) end

   return ranges
end

local function estimate_decode_time(json_str, decode_fn, trials)
   trials = trials or 5
   local total = 0

   decode_fn(json_str)

   for i = 1, trials do
      local t = os.clock()
      decode_fn(json_str)
      total = total + (os.clock() - t)
   end

   local avg = total / trials
   local len = #json_str
   return {total_time = total, average_time = avg, time_per_kb = avg * 1024 / len, trials = trials, length = len}
end

local function span_frame_data()
   for key, char in ipairs(frame_data_keys) do
      local fdata = frame_data[char]
      local file_path = framedata_path .. char .. settings.framedata_file_ext
      local file = io.open(file_path, "w")
      if not file then error("Cannot open " .. file_path) end
      for id, data in pairs(fdata) do
         -- local stats = estimate_decode_time(str, json.decode, 10)
         local tag = id .. ",0:"
         file:write(tag .. json.encode(data) .. "\n")
      end
      file:close()
   end
   local total_size = 0
   for key, char in ipairs(frame_data_keys) do
      local file_path = framedata_path .. char .. settings.framedata_file_ext
      local file = io.open(file_path, "r")
      local new_data = {}
      local line_start_time = os.clock()
      if not file then error("Cannot open " .. file_path) end
      for line in file:lines() do
         local id, load_time, json_str = line:match("([^,]+),(%d+):(.+)")
         local line_read_time = os.clock() - line_start_time
         load_time = estimate_decode_time(json_str, json.decode, 10).average_time
         local size = math.ceil((line_read_time + load_time) * 1000000)
         total_size = total_size + size
         table.insert(new_data, {id, size, json_str})
         line_start_time = os.clock()
      end
      file:close()
      file = io.open(file_path, "w")
      if not file then error("Cannot open " .. file_path) end
      for i = 1, #new_data do
         local line_str = new_data[i][1] .. "," .. new_data[i][2] .. ":" .. new_data[i][3]
         if i ~= #new_data then line_str = line_str .. "\n" end
         file:write(line_str)
      end
      file:close()
   end
   local file_path = framedata_path .. "file_size.json"
   local file = io.open(file_path, "w")
   if not file then error("Cannot open " .. file_path) end
   file:write(total_size)
   file:close()
end

local function index_of_projectile(list, proj)
   for k, v in pairs(list) do if v.object == proj then return k end end
   return 0
end

local function index_of_hash(t, s)
   for i = 1, #t do if t[i].hash == s then return i end end
   return 0
end

local function next_anim_contains(t, v)
   v = v.id or v[1]
   for _, val in pairs(t) do
      local id = val.id or val[1]
      if id == v then return true end
   end
   return false
end

local function merge_sequence(existing, incoming)
   local ne, ni = #existing, #incoming
   for k = math.min(ne, ni), 1, -1 do
      local matching = true
      for i = 1, k do
         if existing[ne - k + i].hash ~= incoming[i].hash then
            matching = false
            break
         end
      end
      if matching then
         -- append unmatched tail
         for j = k + 1, ni do table.insert(existing, incoming[j]) end
         if k + 1 > ni then
            --         print("subset")
            return false
         else
            --         print("appended", ne, ni)
            return true
         end
      end
   end

   for k = math.min(ne, ni), 1, -1 do
      local matching = true
      for i = 1, k do
         if existing[i].hash ~= incoming[ni - k + i].hash then
            matching = false
            break
         end
      end
      if matching then
         -- adjust loops
         for j = 1, #existing do
            if existing[j].loop_start then
               existing[j].loop_start[1] = existing[j].loop_start[1] + (ni - k)
               existing[j].loop_start[2] = existing[j].loop_start[2] + (ni - k)
            end
         end
         -- prepend unmatched head
         for j = 1, ni - k do table.insert(existing, 1, incoming[j]) end
         if ni - k < 1 then
            --         print("subset")
            return false
         else
            --         print("prepended", ne, ni)
            return true
         end

      end
   end

   if ni == 0 then return true end
   if ni > ne then return false end

   for i = 1, ne - ni + 1 do
      local match = true
      for j = 1, ni do
         if existing[i + j - 1].hash ~= incoming[j].hash then
            match = false
            break
         end
      end
      if match then
         --       print("subset")
         return false
      end
   end

   -- no overlap, append
   for k = 1, ni do table.insert(existing, incoming[k]) end
   --   print("no matches, appended", ne, ni)
   return true
end

local function force_merge_sequence(existing, incoming)
   local merged = false
   local i_incoming = 1
   while i_incoming < #incoming do
      local index = index_of_hash(existing, incoming[i_incoming].hash)
      if index > 0 then
         local i = 0
         while i_incoming + i <= #incoming do
            local boxes = nil
            if existing[index + i] and not tools.deep_equal(existing[index + i].boxes, {}) then
               boxes = existing[index + i].boxes
            end
            existing[index + i] = incoming[i_incoming + i]
            if boxes then existing[index + i].boxes = boxes end
            i = i + 1
         end
         merged = true
         break
      else
         i_incoming = i_incoming + 1
      end
   end
   if not merged then for i = 1, #incoming do table.insert(existing, incoming[i]) end end
   for j = 2, #existing do
      existing[j].hit_start = nil
      if string.sub(existing[j - 1].hash, 9, 10) ~= string.sub(existing[j].hash, 9, 10) then
         existing[j].hit_start = true
      end
   end
   return merged
end

local function fill_missing_boxes(frames)
   local segments = {}
   local in_segment = false
   local seg_start = 0

   for i = 1, #frames do
      local has_boxes = #frames[i].boxes > 0
      if not has_boxes then
         if not in_segment then
            if i > 1 and #frames[i - 1].boxes > 0 then
               in_segment = true
               seg_start = i
            end
         end
      else
         if in_segment then
            table.insert(segments, {start = seg_start, stop = i - 1})
            in_segment = false
         end
      end
   end
   for _, seg in pairs(segments) do for i = seg.start, seg.stop do frames[i].boxes = frames[seg.start - 1].boxes end end
end

local function connect_next_anim(fdata, f, next_anim_type)
   if #f > 0 then
      if f[#f][next_anim_type] then
         local index = index_of_hash(fdata.frames, f[#f].hash)
         if index > 0 then
            if not fdata.frames[index][next_anim_type] then fdata.frames[index][next_anim_type] = {} end
            if f[#f][next_anim_type] then
               for j = 1, #f[#f][next_anim_type] do
                  if not next_anim_contains(fdata.frames[index][next_anim_type], f[#f][next_anim_type][j]) then
                     table.insert(fdata.frames[index][next_anim_type], f[#f][next_anim_type][j])
                  end
               end
            end
         end
      end
   end
end

local function process_motion_data(anim_list)
   local all_frames = {}
   local uses_velocity = {}
   local ignore_motion = {}
   for i = 1, #anim_list do
      if anim_list[i].landing_frame then anim_list[i].frames[1].raw_movement = {0, 0} end
      for j = 1, #anim_list[i].frames do
         table.insert(all_frames, anim_list[i].frames[j])
         table.insert(uses_velocity, anim_list[i].uses_velocity or false)
         table.insert(ignore_motion, anim_list[i].frames[j].ignore_motion or false)
      end
   end
   for i = 1, #all_frames do
      if all_frames[i].acceleration_offset and not all_frames[i].ignore_motion then
         all_frames[i].raw_acceleration[2] = all_frames[i].raw_acceleration[2] - all_frames[i].acceleration_offset
         all_frames[i].raw_velocity[2] = all_frames[i].raw_velocity[2] - all_frames[i].acceleration_offset
         for j = i + 1, #all_frames do
            if uses_velocity[j] then
               all_frames[j].raw_velocity[2] = all_frames[j].raw_velocity[2] - all_frames[i].acceleration_offset
               all_frames[j].raw_movement[2] = all_frames[j].raw_movement[2] - all_frames[i].acceleration_offset
            end
         end
         all_frames[i].acceleration_offset = nil
      end
   end
   for i = #all_frames, 1, -1 do
      if all_frames[i].raw_movement and all_frames[i].raw_velocity and all_frames[i].raw_acceleration then
         if i - 1 >= 1 and all_frames[i - 1].raw_movement and all_frames[i - 1].raw_velocity and
             all_frames[i - 1].raw_acceleration then
            all_frames[i].movement = {}
            all_frames[i].velocity = {}
            all_frames[i].acceleration = {}

            all_frames[i].movement[1] = all_frames[i].raw_movement[1]
            all_frames[i].movement[2] = all_frames[i].raw_movement[2]
            all_frames[i].velocity[1] = all_frames[i].raw_velocity[1]
            all_frames[i].velocity[2] = all_frames[i].raw_velocity[2]
            all_frames[i].acceleration[1] = all_frames[i].raw_acceleration[1]
            all_frames[i].acceleration[2] = all_frames[i].raw_acceleration[2]

            -- print(i, all_frames[i].raw_movement, all_frames[i].raw_velocity, all_frames[i].raw_acceleration)

            if uses_velocity[i] and not ignore_motion[i] then
               all_frames[i].movement[1] = all_frames[i].movement[1] - all_frames[i - 1].raw_velocity[1]
               all_frames[i].movement[2] = all_frames[i].movement[2] - all_frames[i - 1].raw_velocity[2]
               all_frames[i].velocity[1] = all_frames[i].velocity[1] - all_frames[i - 1].raw_velocity[1]
               all_frames[i].velocity[2] = all_frames[i].velocity[2] - all_frames[i - 1].raw_velocity[2]

               if all_frames[i].raw_velocity[1] - all_frames[i - 1].raw_velocity[1] ~= 0 then
                  all_frames[i].velocity[1] = all_frames[i].velocity[1] - all_frames[i - 1].raw_acceleration[1]
               end
               if all_frames[i].raw_velocity[2] - all_frames[i - 1].raw_velocity[2] ~= 0 then
                  all_frames[i].velocity[2] = all_frames[i].velocity[2] - all_frames[i - 1].raw_acceleration[2]
               end

               all_frames[i].acceleration[1] = all_frames[i].acceleration[1] - all_frames[i - 1].raw_acceleration[1]
               all_frames[i].acceleration[2] = all_frames[i].acceleration[2] - all_frames[i - 1].raw_acceleration[2]
            end

            all_frames[i].raw_movement = nil
            all_frames[i].raw_velocity = nil
            all_frames[i].raw_acceleration = nil
         else
            all_frames[i].movement = {all_frames[i].raw_movement[1], all_frames[i].raw_movement[2]}
            all_frames[i].velocity = {all_frames[i].raw_velocity[1], all_frames[i].raw_velocity[2]}
            all_frames[i].acceleration = {all_frames[i].raw_acceleration[1], all_frames[i].raw_acceleration[2]}

            all_frames[i].raw_movement = nil
            all_frames[i].raw_velocity = nil
            all_frames[i].raw_acceleration = nil
         end
      end
   end
end

local function handle_loops(frames)
   local n = #frames
   if n < 2 then return frames end

   local dp = {}
   for i = n, 1, -1 do
      dp[i] = {}
      for j = n, 1, -1 do
         if j > i and (frames[i].hash == frames[j].hash) and dp[i + 1] and dp[i + 1][j + 1] then
            dp[i][j] = dp[i + 1][j + 1] + 1
         else
            dp[i][j] = 0
         end
      end
   end

   local search_start = 1
   for i = 1, #frames do
      if frames[i].loop_start then search_start = math.min(frames[i].loop_start[2] + 2, #frames) end
   end

   local i = 1
   local out = {}
   local seq_start = 0
   local seq_end = 0
   local min_loop_size = 8
   local loop_found = false

   while i <= n do
      local removed = false
      for j = n, i + 1, -1 do
         local L = j - i
         if L >= min_loop_size and dp[i][j] >= L and i >= search_start then
            -- a block of length L repeats immediately
            seq_start = #out + 1
            seq_end = i + L - 1

            for k = i, i + L - 1 do
               if frames[k].loop_start then frames[k].loop_start = nil end
               out[#out + 1] = frames[k]
            end
            for k = i + L, #frames do
               if frames[k].loop_start then
                  frames[k].loop_start[1] = frames[k].loop_start[1] - L
                  frames[k].loop_start[2] = frames[k].loop_start[2] - L
               end
            end
            seq_end = #out
            out[seq_start].loop_start = {seq_start - 1, seq_end - 1}
            local removed_start = j
            for k = 0, L - 1 do
               copy_props(frames[removed_start + k], out[seq_start + k], next_anim_types)
               copy_props(frames[removed_start + k], out[seq_start + k], props_to_copy)
            end

            i = i + 2 * L
            removed = true
            loop_found = true
            break
         end
      end
      if not removed then
         out[#out + 1] = frames[i]
         i = i + 1
      end
   end

   if loop_found then return handle_loops(out) end

   -- remove partial repeats
   local has_loop = false
   for k = #out, 1, -1 do
      if out[k].loop_start then
         seq_start = out[k].loop_start[1] + 1
         seq_end = out[k].loop_start[2] + 1
         has_loop = true
         break
      end
   end
   if has_loop and #out - seq_end <= seq_end - seq_start + 1 then
      local n = seq_end + 1
      local m = 0
      while n <= #out do
         if out[n].hash == out[seq_start + m].hash then
            copy_props(out[n], out[n - 1], next_anim_types)
            copy_props(out[n], out[n - 1], props_to_copy)
            table.remove(out, n)
            m = m + 1
         else
            break
         end
      end
   end

   return out

end

local function find_seq_start(existing, incoming)
   local ne, ni = #existing, #incoming
   for k = math.min(ne, ni), 1, -1 do
      for i = 1, k do
         if existing[ne - k + i].hash == incoming[i].hash then
            print(ne - k + i, i)
            return ne - k + i, i
         end
      end
   end
   return nil
end

local function find_exception_position(existing, incoming, index)
   for i = 1, #existing do if existing[i].hash == incoming[index].hash then return i end end
   if index + 1 <= #incoming then return find_exception_position(existing, incoming, index + 1) - 1 end
   return 0
end

local function get_index_of_action_count(frames, ac)
   for i = 1, #frames do
      if tonumber(string.sub(frames[i].hash, #frames[i].hash - 1, #frames[i].hash), 16) == ac then return i end
   end
   return 0
end

local function find_exceptions(existing, incoming, i)
   local next_action_count = tonumber(string.sub(incoming[i].hash, #incoming[i].hash - 1, #incoming[i].hash), 16) + 1
   local incoming_next_action_index = get_index_of_action_count(incoming, next_action_count)
   local existing_next_action_index = get_index_of_action_count(existing, next_action_count)

   if incoming_next_action_index > 0 and existing_next_action_index > 0 then
      local offset = incoming_next_action_index - i
      return existing_next_action_index - offset
   end
   return 0
end

local current_recording_animation = nil
local current_recording_anim_list = {}
local current_recording_proj_list = {}
local bypassing_freeze = false

local function reset_current_recording_animation()
   current_recording_animation = nil
   current_recording_anim_list = {}
   current_recording_proj_list = {}
   rec.current_recording_acceleration_offset = 0
   bypassing_freeze = false
end
reset_current_recording_animation()

local function new_recording(player, projectiles, name)
   reset_current_recording_animation()
   current_recording_animation = {name = name, frames = {}, hit_frames = {}, id = player.animation}
   if rec.recording_options.air then current_recording_animation.air = true end
   current_recording_anim_list = {current_recording_animation}
   current_recording_proj_list = {}
   rec.current_recording_acceleration_offset = 0
   rec.recording = true
   state = "recording"
end

local function new_animation(player, projectiles, name)
   local frames = current_recording_animation.frames
   if not frames[#frames].hash then -- patch up missing frames
      frames[#frames].hash = player.animation_frame_hash
   end

   local next_anim_type = "next_anim"
   if rec.recording_options.optional_anim then
      next_anim_type = "optional_anim"
      rec.recording_options.optional_anim = false
   end

   if not frames[#frames][next_anim_type] then frames[#frames][next_anim_type] = {} end
   if not next_anim_contains(frames[#frames][next_anim_type], {player.animation}) then
      table.insert(frames[#frames][next_anim_type], {id = player.animation, hash = player.animation_frame_hash})
   end

   if current_recording_animation.name == name or
       string.sub(current_recording_animation.name, 1, #current_recording_animation.name - 4) == name then
      name = name .. "_ext"
   end

   current_recording_animation = {name = name, frames = {}, hit_frames = {}, id = player.animation}
   table.insert(current_recording_anim_list, current_recording_animation)
   rec.recording = true
   state = "recording"
end

local function end_recording(player, projectiles, name)
   local current_frames = current_recording_animation.frames
   if not current_frames[#current_frames].hash then -- patch up missing frames
      current_frames[#current_frames].hash = player.animation_frame_hash
   end
   if not current_frames[#current_frames]["next_anim"] then current_frames[#current_frames]["next_anim"] = {} end
   if not next_anim_contains(current_frames[#current_frames]["next_anim"], {"idle"}) then
      table.insert(current_frames[#current_frames]["next_anim"], {"idle"})
   end

   if (frame_data[player.char_str] == nil) then frame_data[player.char_str] = {} end
   frame_data[player.char_str].should_save = true

   process_motion_data(current_recording_anim_list)

   for i = 1, #current_recording_anim_list do
      local id = current_recording_anim_list[i].id
      local fdata = frame_data[player.char_str][id]

      if current_recording_anim_list[i].discard_all then
         for j = 1, #current_recording_anim_list[i].frames do
            current_recording_anim_list[i].frames[j].discard = true
         end
      end
      if current_recording_anim_list[i].do_not_discard then
         for j = 1, #current_recording_anim_list[i].frames do
            current_recording_anim_list[i].frames[j].discard = nil
         end
      end
      local new_frames = tools.deepcopy(current_recording_anim_list[i].frames)
      -- special case for drill kicks
      if id == "e9e4" or id == "f2cc" or id == "f51c" then fill_missing_boxes(new_frames) end

      if fdata then
         if rec.recording_options.hit_type == "block" or rec.recording_options.self_chain then
            for j = 1, #new_frames - 1 do
               if index_of_hash(fdata.frames, new_frames[j].hash) == 0 then
                  local index = find_exceptions(fdata.frames, new_frames, j)
                  if index > 0 then
                     if not fdata.exceptions then fdata.exceptions = {} end
                     fdata.exceptions[new_frames[j].hash] = index - 1
                  end
               end
            end
         end
         if rec.recording_options.recording_landing then
            if current_recording_anim_list[i].landing_height then
               fdata.landing_height = current_recording_anim_list[i].landing_height
            end
         end
      end

      if fdata == nil or rec.recording_options.clear_frame_data then
         frame_data[player.char_str][id] = current_recording_anim_list[i]
      else

         if rec.recording_options.record_frames_after_hit and rec.recording_options.hit_type == "miss" then
            for j = 1, #new_frames do
               if tonumber(string.sub(new_frames[j].hash, 9, 10)) >= 1 then new_frames[j].discard = nil end
            end
         end

         local j = 1
         while j <= #new_frames do
            if new_frames[j].discard then
               table.remove(new_frames, j)
            else
               j = j + 1
            end
         end

         local merged = false
         if rec.recording_options.record_frames_after_hit then
            merged = force_merge_sequence(fdata.frames, new_frames)
         else
            merged = merge_sequence(fdata.frames, new_frames)
         end

         local f = current_recording_anim_list[i].frames

         connect_next_anim(fdata, f, "optional_anim")
         if merged and not rec.recording_options.ignore_next_anim or rec.recording_options.record_next_anim then
            connect_next_anim(fdata, f, "next_anim")
         end

         for j = 1, #f do
            for k, prop in pairs(props_to_copy) do
               if f[j][prop] then
                  local index = index_of_hash(fdata.frames, f[j].hash)
                  if index > 0 then fdata.frames[index][prop] = f[j][prop] end
               end
            end
         end
      end
   end

   local ids = {}
   for k, v in pairs(current_recording_anim_list) do if not ids[v.id] then ids[v.id] = v.id end end

   for id, _ in pairs(ids) do
      frame_data[player.char_str][id].frames = handle_loops(frame_data[player.char_str][id].frames)
   end

   for id, _ in pairs(ids) do
      local anim = frame_data[player.char_str][id]
      local frames = frame_data[player.char_str][id].frames

      local hit_frames = calculate_ranges(frames, is_hit_frame)
      if #hit_frames > 0 then
         -- make 0 index
         for _, f in pairs(hit_frames) do
            f[1] = f[1] - 1
            f[2] = f[2] - 1
         end
         anim.hit_frames = hit_frames
      end

      anim.hit_frames = divide_hit_frames(anim)

      local idle_frames = calculate_ranges(frames, is_idle_frame)
      if #idle_frames > 0 then
         -- make 0 index
         for _, f in pairs(idle_frames) do
            f[1] = f[1] - 1
            f[2] = f[2] - 1
         end
         anim.idle_frames = idle_frames
      end

      local p_index = 1
      local a_index = 1
      for i = 1, #frames do
         if frames[i].pushback then
            if not anim.pushback then anim.pushback = {} end
            anim.pushback[p_index] = frames[i].pushback
            p_index = p_index + 1
         end
         if frames[i].opponent_recovery and frames[i].opponent_freeze then
            if not anim.advantage then anim.advantage = {} end
            local self_freeze = 0
            if frames[i].self_freeze then self_freeze = frames[i].self_freeze[1] end
            anim.advantage[a_index] = frames[i].opponent_freeze[1] + 1 - self_freeze + frames[i].opponent_recovery[1]
            a_index = a_index + 1
         end
      end
      for i = 1, #frames do
         if frames[i].next_anim then
            for k, na in pairs(frames[i].next_anim) do
               if na.hash then
                  local index = index_of_hash(frame_data[player.char_str][na.id].frames, na.hash)
                  if index == 0 then index = 1 end
                  frames[i].next_anim[k] = {na.id, index - 1}
               end
            end
         end
         if frames[i].optional_anim then
            for k, na in pairs(frames[i].optional_anim) do
               if na.hash then
                  local index = index_of_hash(frame_data[player.char_str][na.id].frames, na.hash)
                  if index == 0 then index = 1 end
                  frames[i].optional_anim[k] = {na.id, index - 1}
               end
            end
         end
         if frames[i].loop_start then
            if anim.loops == nil then anim.loops = {} end
            local l_start = frames[i].loop_start[1]
            local l_end = frames[i].loop_start[2]
            if not tools.table_contains_deep(anim.loops, {l_start, l_end}) then
               table.insert(anim.loops, {l_start, l_end})
               frames[l_end + 1].loop = l_start
            end
         end
      end
   end

   rec.recording = false
   state = "ready"
end

local previous_hash = ""

local function record_framedata(player, projectiles, name)
   local dummy = player.other
   local frame = player.animation_frame
   local sign = tools.flip_to_sign(player.flip_x)

   if rec.recording then

      if player.has_just_been_blocked or player.has_just_hit then
         if rec.recording_options.record_frames_after_hit then
            for i = 1, frame + 1 - 1 do current_recording_animation.frames[i].discard = true end
         else
            current_recording_animation.discard_all = true
         end
      end
      if rec.recording_options.is_projectile and rec.recording_options.hit_type == "block" then
         current_recording_animation.discard_all = true
      end

      if player.remaining_freeze_frames > 0 and player.animation_frame_hash ~= previous_hash and
          player.superfreeze_decount == 0 then
         if #current_recording_animation.frames == 0 then
            player.animation_start_frame = gamestate.frame_number
            player.animation_freeze_frames = 0
            frame = 0
            bypassing_freeze = true
         elseif not player.freeze_just_began then
            player.animation_freeze_frames = player.animation_freeze_frames - 1
            frame = gamestate.frame_number - player.animation_freeze_frames - player.animation_start_frame
            bypassing_freeze = true
         end
         if bypassing_freeze then print(">", current_recording_animation.id, "bypassing freeze", frame) end
      else
         bypassing_freeze = false
      end

      if not current_recording_animation.frames[frame + 1] then
         table.insert(current_recording_animation.frames, {})
      end

      if bypassing_freeze then
         if current_recording_animation.frames[frame + 1] then
            current_recording_animation.frames[frame + 1].bypass_freeze = true
         end
      end

      if player.has_just_acted then
         current_recording_animation.frames[frame + 1].hit_start = true
         -- ex dra
         if current_recording_animation.id == "b1f4" then
            if player.action_count > 1 then current_recording_animation.frames[frame + 1].hit_start = nil end
         end
      end

      if rec.recording_self_freeze and not rec.recording_options.is_projectile then
         if not current_recording_animation.frames[frame + 1].self_freeze then
            current_recording_animation.frames[frame + 1].self_freeze = {} -- block, hit, cr. hit
         end
         if rec.recording_options.hit_type == "block" then
            current_recording_animation.frames[frame + 1].self_freeze[1] = player.remaining_freeze_frames
         end
      end
      if rec.recording_opponent_freeze and not rec.recording_options.is_projectile then
         if not current_recording_animation.frames[frame + 1].opponent_freeze then
            current_recording_animation.frames[frame + 1].opponent_freeze = {} -- block, hit, cr. hit
         end
         if rec.recording_options.hit_type == "block" then
            current_recording_animation.frames[frame + 1].opponent_freeze[1] = dummy.remaining_freeze_frames
         end
      end
      if rec.recording_recovery and not rec.recording_options.is_projectile then
         if not current_recording_animation.frames[frame + 1].opponent_recovery then
            current_recording_animation.frames[frame + 1].opponent_recovery = {} -- block, hit, cr. hit
         end
         if rec.recording_options.hit_type == "block" then
            current_recording_animation.frames[frame + 1].opponent_recovery[1] = dummy.recovery_time
         end
      end
      if rec.recording_pushback and not rec.recording_options.is_projectile then
         if not current_recording_animation.frames[frame + 1].pushback then
            current_recording_animation.frames[frame + 1].pushback = {}
         end
         table.insert(current_recording_animation.frames[frame + 1].pushback,
                      (dummy.pos_x - dummy.previous_pos_x) * sign)
      end

      if player.remaining_freeze_frames == 0 or bypassing_freeze then
         -- print(string.format("recording frame %d (%d - %d - %d)", frame, gamestate.frame_number, player.animation_freeze_frames, player.animation_start_frame))

         if player.standing_state == 1 then rec.current_recording_acceleration_offset = 0 end

         if rec.current_recording_acceleration_offset ~= 0 then
            current_recording_animation.frames[frame + 1].acceleration_offset =
                rec.current_recording_acceleration_offset
         end

         local additional_props = {}

         if player.velocity_x ~= 0 or player.velocity_y ~= 0 or player.acceleration_x ~= 0 or player.acceleration_y ~= 0 then
            additional_props.uses_velocity = true
         end
         if (frame == 0 and not player.is_attacking and player.posture == 0 and player.pos_y == 0) then
            -- recovery animation (landing, after dash, etc)
            write_memory.clear_motion_data(player)
            additional_props.uses_velocity = false
            additional_props.landing_frame = true
            local jump_actions = {[14] = true, [15] = true, [16] = true, [20] = true, [21] = true, [22] = true}
            if jump_actions[player.action] then current_recording_animation.name = "jump_recovery" end
            if rec.recording_options.recording_landing then
               if current_recording_anim_list[#current_recording_anim_list - 1] then
                  current_recording_anim_list[#current_recording_anim_list - 1].landing_height = player.previous_pos_y
                  print(current_recording_anim_list[#current_recording_anim_list - 1].name,
                        current_recording_anim_list[#current_recording_anim_list - 1].landing_height)
               end
            end
         end
         local movement_x = (player.pos_x - player.previous_pos_x) * sign
         local movement_y = player.pos_y - player.previous_pos_y

         if rec.recording_options.ignore_movement then
            movement_x = 0
            movement_y = 0
         end

         if rec.recording_options.self_chain then additional_props.self_chain = true end

         if rec.recording_options.insert_wakeup then
            current_recording_animation.frames[frame + 1].wakeup = true
            rec.recording_options.insert_wakeup = nil
         end

         local hash = player.animation_frame_hash
         if rec.recording_options.infinite_loop then
            if #current_recording_anim_list == 1 then
               hash = string.sub(hash, 1, 8)
               additional_props.infinite_loop = true
            end
         end

         local new_frame = {
            boxes = {},
            raw_movement = {movement_x, movement_y},
            hash = hash,
            frame_id = player.animation_frame_id,
            frame_id2 = player.animation_frame_id2,
            raw_velocity = {player.velocity_x, player.velocity_y},
            raw_acceleration = {player.acceleration_x, player.acceleration_y},
            idle = player.is_idle
         }

         if rec.recording_options.ignore_motion then
            new_frame.raw_movement = {0, 0}
            new_frame.raw_velocity = {0, 0}
            new_frame.raw_acceleration = {0, 0}
            new_frame.ignore_motion = true
         end

         for k, v in pairs(additional_props) do current_recording_animation[k] = v end

         if current_recording_animation.frames[frame + 1] then
            for k, v in pairs(current_recording_animation.frames[frame + 1]) do new_frame[k] = v end
         end

         current_recording_animation.frames[frame + 1] = new_frame

         local wanted_boxes = {"attack", "throw"}

         if rec.recording_options.recording_wakeups or rec.recording_options.recording_movement or
             rec.recording_options.recording_idle then
            table.insert(wanted_boxes, "vulnerability")
            table.insert(wanted_boxes, "throwable")
            table.insert(wanted_boxes, "push")
         end

         if rec.recording_options.record_pushboxes or current_recording_animation.air then
            table.insert(wanted_boxes, "push")
         end

         for __, box in ipairs(player.boxes) do
            local type = tools.convert_box_types[box[1]]
            if tools.table_contains_deep(wanted_boxes, type) then
               table.insert(current_recording_animation.frames[frame + 1].boxes, copytable(box))
            end
         end

      end
   end
   if (rec.recording or rec.recording_projectiles) and not rec.recording_options.ignore_projectiles then
      local has_projectiles = false
      for _, obj in pairs(projectiles) do
         if obj.emitter_id == player.id then
            has_projectiles = true
            local type = obj.projectile_type

            local i = index_of_projectile(current_recording_proj_list, obj)
            if i == 0 then
               local dx = obj.pos_x - player.pos_x
               local dy = obj.pos_y - player.pos_y
               if player.flip_x == 0 then dx = dx * -1 end

               current_recording_animation.frames[frame + 1].projectile = {type = type, offset = {dx, dy}}

               local proj_list = {}
               local data = {
                  name = name,
                  type = type,
                  frames = {},
                  animation_start_frame = gamestate.frame_number,
                  uses_velocity = true
               }
               table.insert(proj_list, data)
               proj_list.object = obj

               table.insert(current_recording_proj_list, proj_list)
            else
               local latest = #current_recording_proj_list[i]
               local latest_proj = current_recording_proj_list[i][latest]
               if not (latest_proj.type == type) then
                  local frames = latest_proj.frames
                  if not frames[#frames]["next_anim"] then frames[#frames]["next_anim"] = {} end
                  if not next_anim_contains(frames[#frames]["next_anim"], {type}) then
                     table.insert(frames[#frames]["next_anim"], {id = type, hash = obj.animation_frame_hash})
                  end

                  local data = {
                     name = name .. "ext",
                     type = type,
                     frames = {},
                     animation_start_frame = gamestate.frame_number,
                     uses_velocity = true
                  }
                  table.insert(current_recording_proj_list[i], data)
               end
            end
         end
      end

      if has_projectiles then
         rec.recording_projectiles = true
      else
         rec.recording_projectiles = false
      end

      for _, proj_list in pairs(current_recording_proj_list) do
         local obj = proj_list.object
         local type = obj.projectile_type

         for i, data in ipairs(proj_list) do
            if data.type == type then
               local f = gamestate.frame_number - obj.animation_freeze_frames - data.animation_start_frame
               if obj.expired then f = #data.frames - 1 end
               if rec.recording_options.hit_type == "block" then data.discard_all = true end
               if obj == rec.current_projectile then
                  if rec.recording_pushback or rec.recording_opponent_freeze or rec.recording_recovery then
                     if not data.frames[f + 1] then data.frames[f + 1] = {} end
                  end
                  if rec.recording_pushback then
                     if not data.frames[f + 1].pushback then data.frames[f + 1].pushback = {} end
                     table.insert(data.frames[f + 1].pushback, (dummy.pos_x - dummy.previous_pos_x) * sign)
                  end
                  if rec.recording_opponent_freeze then
                     if not data.frames[f + 1].opponent_freeze then
                        data.frames[f + 1].opponent_freeze = {}
                     end
                     data.frames[f + 1].opponent_freeze[1] = dummy.remaining_freeze_frames
                  end
                  if rec.recording_recovery then
                     if not data.frames[f + 1].opponent_recovery then
                        data.frames[f + 1].opponent_recovery = {}
                     end
                     data.frames[f + 1].opponent_recovery[1] = dummy.recovery_time
                  end
               end
               if obj.remaining_freeze_frames == 0 then

                  local movement_x = (obj.pos_x - obj.previous_pos_x) * sign
                  local movement_y = obj.pos_y - obj.previous_pos_y

                  if i == 1 and f == 0 then
                     movement_x = 0
                     movement_y = 0
                  end

                  local new_frame = {
                     boxes = {},
                     raw_movement = {movement_x, movement_y},
                     hash = obj.animation_frame_hash,
                     frame_id = obj.animation_frame_id,
                     frame_id2 = obj.animation_frame_id2,
                     frame_id3 = obj.animation_frame_id3,
                     raw_velocity = {obj.velocity_x, obj.velocity_y},
                     raw_acceleration = {obj.acceleration_x, obj.acceleration_y}
                  }

                  for __, box in ipairs(obj.boxes) do
                     local type = tools.convert_box_types[box[1]]
                     if (type == "attack") or (type == "throw") then
                        table.insert(new_frame.boxes, copytable(box))
                     end
                  end

                  if data.frames[f + 1] then
                     for k, v in pairs(data.frames[f + 1]) do new_frame[k] = v end
                  end

                  data.frames[f + 1] = new_frame
               end
            end
         end
      end
   end

   if setup and not rec.recording_pushback and not rec.recording_options.ignore_projectiles then
      for key, proj_list in pairs(current_recording_proj_list) do
         local obj = proj_list.object
         if not tools.table_contains_deep(projectiles, obj) then
            process_motion_data(proj_list)
            for i, proj in ipairs(proj_list) do

               if proj.discard_all then for j = 1, #proj.frames do proj.frames[j].discard = true end end
               if proj.do_not_discard then for j = 1, #proj.frames do proj.frames[j].discard = nil end end
               local new_frames = tools.deepcopy(proj.frames)
               local id = proj.type

               local fdata = frame_data["projectiles"][id]
               if frame_data["projectiles"][id] == nil or rec.overwrite then
                  frame_data["projectiles"][id] = proj
                  frame_data["projectiles"].should_save = true
               else
                  local j = 1
                  while j <= #new_frames do
                     if new_frames[j].discard then
                        table.remove(new_frames, j)
                     else
                        j = j + 1
                     end
                  end

                  local merged = merge_sequence(fdata.frames, new_frames)
                  if merged then connect_next_anim(fdata, proj.frames, "next_anim") end
                  for j = 1, #proj.frames do
                     for k, prop in pairs(props_to_copy) do
                        if proj.frames[j][prop] then
                           local index = index_of_hash(fdata.frames, proj.frames[j].hash)
                           if index > 0 then fdata.frames[index][prop] = proj.frames[j][prop] end
                        end
                     end
                  end

                  frame_data["projectiles"].should_save = true
               end
            end

            local ids = {}
            for _, proj in ipairs(proj_list) do if not ids[proj.type] then ids[proj.type] = proj.type end end

            for id, _ in pairs(ids) do
               local fdata = frame_data["projectiles"][id]
               fdata.frames = handle_loops(fdata.frames)

               local p_index = 1
               local anim = frame_data["projectiles"][id]
               local frames = fdata.frames

               for i = 1, #frames do
                  if frames[i].pushback then
                     if not frames.pushback then frames.pushback = {} end
                     frames.pushback[p_index] = frames[i].pushback
                     p_index = p_index + 1
                  end
                  if frames[i].loop_start then
                     if anim.loops == nil then anim.loops = {} end
                     local l_start = frames[i].loop_start[1]
                     local l_end = frames[i].loop_start[2]
                     if not tools.table_contains_deep(anim.loops, {l_start, l_end}) then
                        table.insert(anim.loops, {l_start, l_end})
                        frames[l_end + 1].loop = l_start
                     end
                  end
                  if frames[i].next_anim then
                     for k, na in pairs(frames[i].next_anim) do
                        if na.hash then
                           local index = index_of_hash(frame_data["projectiles"][na.id].frames, na.hash)
                           if index == 0 then index = 1 end
                           frames[i].next_anim[k] = {na.id, index - 1}
                        end
                     end
                  end
               end
            end

            current_recording_proj_list[key] = nil
         end
      end

      previous_hash = player.animation_frame_hash
   end
end

local record_idle_duration = 600
local record_idle_start_frame = 0
local record_idle_states = {"standing", "crouching", "standing_begin", "crouching_begin"}
local i_record_idle_states = 1
local function record_idle(player)
   local dummy = player.other
   function start_recording_idle(name)
      new_recording(player, {}, name)
      record_idle_start_frame = gamestate.frame_number
      write_memory.write_pos(player, 440, 0)
      write_memory.write_pos(dummy, 540, 0)
      print(name)
   end

   if gamestate.is_in_match and debug_settings.recording_framedata then
      if i_record_idle_states <= #record_idle_states then
         local name = record_idle_states[i_record_idle_states]
         if name == "standing" then
            if setup then
               if not (state == "recording") and player.action == 0 then
                  rec.recording_options = {recording_idle = true}
                  -- rec.recording_options.infinite_loop = true
                  start_recording_idle(name)
               end
            else
               inputs.queue_input_sequence(player, {{"down"}})
               if player.action == 7 then
                  write_memory.clear_motion_data(player)
                  setup = true
               end
            end
         elseif name == "crouching" then
            if setup then
               if not (state == "recording") and player.action == 7 then
                  rec.recording_options = {recording_idle = true}
                  -- rec.recording_options.infinite_loop = true
                  start_recording_idle(name)
               end
               inputs.queue_input_sequence(player, {{"down"}})
            else
               if player.action == 0 then
                  write_memory.clear_motion_data(player)
                  setup = true
               end
            end
         elseif name == "standing_begin" then
            if setup then
               if not (state == "recording") and player.action == 11 then
                  rec.recording_options = {recording_idle = true}
                  start_recording_idle(name)
               end
            else
               inputs.queue_input_sequence(player, {{"down"}})
               if player.action == 7 then
                  write_memory.clear_motion_data(player)
                  setup = true
               end
            end
         elseif name == "crouching_begin" then
            if setup then
               if not (state == "recording") and player.action == 6 then
                  rec.recording_options = {recording_idle = true}
                  start_recording_idle(name)
               end
               inputs.queue_input_sequence(player, {{"down"}})
            else
               if player.action == 0 then
                  write_memory.clear_motion_data(player)
                  setup = true
               end
            end
         end
         if state == "recording" then
            if (gamestate.frame_number - record_idle_start_frame >= record_idle_duration) or
                (name == "standing_begin" and player.action ~= 11) or (name == "crouching_begin" and player.action ~= 6) then
               end_recording(player, {}, name)
               i_record_idle_states = i_record_idle_states + 1
               setup = false
            end
         end
         if state == "recording" and player.has_animation_just_changed and record_idle_start_frame ~=
             gamestate.frame_number then new_animation(player, {}, name) end
         record_framedata(player, {}, name)
      else
         state = "finished"
         i_record_idle_states = 1
         return
      end
   end
end

local movement_list = {
   "walk_forward", "walk_back", "dash_forward", "dash_back", "standing_turn", "crouching_turn", "jump_forward",
   "jump_neutral", "jump_back", "sjump_forward", "sjump_neutral", "sjump_back", "air_jump_forward", "air_jump_neutral",
   "air_jump_back", "air_dash", "block_high_proximity", "block_low_proximity", "block_high_air_proximity",
   "block_high_air", "parry_high", "parry_low", "parry_air"
}
local i_movement_list = 1
local m_player_reset_pos = {440, 0}
local m_dummy_reset_pos_offset = {100, 0}
local clear_jump_after = 30
local allow_dummy_movement = false
local name = ""

local function record_movement(player)
   local dummy = player.other
   if gamestate.is_in_match and debug_settings.recording_framedata then
      if player.action == 0 or player.action == 7 then
         if rec.recording then
            if player.has_animation_just_changed then
               end_recording(player, {}, name)
               i_movement_list = i_movement_list + 1
            end
         end
      elseif state == "wait_for_initial_anim" and player.has_animation_just_changed then

         if name == "walk_forward" then
            if player.action == 2 then new_recording(player, {}, name) end
         elseif name == "walk_back" then
            if player.action == 3 then new_recording(player, {}, name) end
         elseif name == "dash_forward" then
            if player.action == 23 then
               name = "dash_startup"
               rec.recording_options.record_next_anim = true
               new_recording(player, {}, name)
            end
         elseif name == "dash_back" then
            if player.action == 23 then
               name = "dash_startup"
               rec.recording_options.record_next_anim = true
               new_recording(player, {}, name)
            end
         elseif name == "standing_turn" then
            if player.action == 1 then new_recording(player, {}, name) end
         elseif name == "crouching_turn" then
            if player.action == 8 then new_recording(player, {}, name) end
         elseif name == "block_high_proximity" then
            if player.action == 30 then new_recording(player, {}, name) end
         elseif name == "block_low_proximity" then
            if player.action == 31 then new_recording(player, {}, name) end
         elseif name == "block_high_air_proximity" then
            if tools.table_contains({"gill", "hugo", "urien"}, player.char_str) then
               if player.action == 30 then new_recording(player, {}, name) end
            end
            if player.action == 29 then new_recording(player, {}, name) end
         elseif name == "block_high_air" then
            if player.action == 65536 then new_recording(player, {}, name) end
         elseif name == "parry_high" then
            if player.action == 24 or player.action == 25 then new_recording(player, {}, name) end
         elseif name == "parry_low" then
            if player.action == 26 then new_recording(player, {}, name) end
         elseif name == "parry_air" then
            if player.action == 27 then new_recording(player, {}, name) end
         elseif name == "jump_forward" or name == "jump_neutral" or name == "jump_back" then
            if player.action == 12 then
               name = "jump_startup"
               rec.recording_options.record_next_anim = true
               new_recording(player, {}, name)
            end
         elseif name == "sjump_forward" or name == "sjump_neutral" or name == "sjump_back" then
            if player.action == 13 then
               name = "sjump_startup"
               rec.recording_options.record_next_anim = true
               new_recording(player, {}, name)
            end
         elseif name == "air_jump_forward" or name == "air_jump_neutral" or name == "air_jump_back" then
            if player.action == 49 then
               name = "air_jump_startup"
               rec.recording_options.record_next_anim = true
               new_recording(player, {}, name)
            end
         elseif name == "air_dash" then
            if player.animation == "b394" then new_recording(player, {}, name) end
         else
            new_recording(player, {}, name)
         end
      elseif rec.recording then
         if player.has_animation_just_changed then
            if player.action == 4 then
               name = "dash_forward"
            elseif player.action == 5 then
               name = "dash_back"
            elseif player.action == 14 then
               name = "jump_forward"
            elseif player.action == 15 then
               name = "jump_neutral"
            elseif player.action == 16 then
               name = "jump_back"
            elseif player.action == 20 then
               name = "sjump_forward"
            elseif player.action == 21 then
               name = "sjump_neutral"
            elseif player.action == 22 then
               name = "sjump_back"
            elseif player.action == 23 then
               name = "walk_transition"
            elseif player.action == 65537 then
               name = "block_high"
            elseif player.action == 65538 then
               name = "block_low"
            elseif player.action == 65536 then
               name = "block_high_air"
            end
            new_animation(player, {}, name)
         end
      end
      if state == "ready" then
         if player.is_idle and dummy.is_idle and player.action == 0 and dummy.action == 0 then
            state = "queue_move"
         end
      elseif state == "wait_for_match_start" then
         if gamestate.has_match_just_started then state = "queue_move" end
      end

      if not setup and state == "start" then
         setup = true
         state = "ready"
      end

      if state == "make_sure_action_is_0" then
         -- remy turns around slow
         if player.action == 0 then state = "wait_for_initial_anim" end
      end

      if state == "queue_move" then
         state = "wait_for_initial_anim"
         if i_movement_list <= #movement_list then
            rec.recording_options = {recording_movement = true}
            allow_dummy_movement = false
            name = movement_list[i_movement_list]
            local is_jump = false
            local sequence = {}
            m_player_reset_pos = {440, 0}
            m_dummy_reset_pos_offset = {100, 0}
            if name == "walk_forward" then
               for i = 1, 160 do table.insert(sequence, {"forward"}) end
               m_player_reset_pos = {150, 0}
            elseif name == "walk_back" then
               for i = 1, 160 do table.insert(sequence, {"back"}) end
               m_player_reset_pos = {650, 0}
            elseif name == "dash_forward" then
               sequence = {{"forward"}, {}, {"forward"}}
            elseif name == "dash_back" then
               sequence = {{"back"}, {}, {"back"}}
            elseif name == "standing_turn" then
               m_dummy_reset_pos_offset = {90, 0}
               allow_dummy_movement = true
               if player.char_str == "remy" then state = "make_sure_action_is_0" end
               inputs.queue_input_sequence(dummy, {
                  {"down"}, {"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}
               })
            elseif name == "crouching_turn" then
               m_dummy_reset_pos_offset = {90, 0}
               allow_dummy_movement = true
               Queue_Command(gamestate.frame_number + 10, inputs.queue_input_sequence, {
                  dummy, {{"down"}, {"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
               })
               for i = 1, 100 do table.insert(sequence, {"down"}) end
               Queue_Command(gamestate.frame_number + 8, write_memory.clear_motion_data, {player})
            elseif name == "jump_forward" then
               is_jump = true
               sequence = {{"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
            elseif name == "jump_neutral" then
               is_jump = true
               sequence = {{"up"}, {"up"}, {"up"}, {}, {}, {}, {}}
            elseif name == "jump_back" then
               is_jump = true
               sequence = {{"up", "back"}, {"up", "back"}, {"up", "back"}, {}, {}, {}, {}}
            elseif name == "sjump_forward" then
               is_jump = true
               sequence = {{"down"}, {"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
            elseif name == "sjump_neutral" then
               is_jump = true
               sequence = {{"down"}, {"up"}, {"up"}, {"up"}, {}, {}, {}, {}}
            elseif name == "sjump_back" then
               is_jump = true
               sequence = {{"down"}, {"up", "back"}, {"up", "back"}, {"up", "back"}, {}, {}, {}, {}}
            elseif name == "air_jump_forward" then
               if player.char_str == "oro" then
                  is_jump = true
                  sequence = {
                     {"up"}, {"up"}, {"up"}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
                     {"up", "forward"}, {"up", "forward"}, {"up", "forward"}
                  }
               else
                  i_movement_list = i_movement_list + 1
                  state = "queue_move"
                  return
               end
            elseif name == "air_jump_neutral" then
               if player.char_str == "oro" then
                  is_jump = true
                  sequence = {
                     {"up"}, {"up"}, {"up"}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {"up"},
                     {"up"}, {"up"}
                  }
               else
                  i_movement_list = i_movement_list + 1
                  state = "queue_move"
                  return
               end
            elseif name == "air_jump_back" then
               if player.char_str == "oro" then
                  is_jump = true
                  sequence = {
                     {"up"}, {"up"}, {"up"}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
                     {"up", "back"}, {"up", "back"}, {"up", "back"}
                  }
               else
                  i_movement_list = i_movement_list + 1
                  state = "queue_move"
                  return
               end
            elseif name == "air_dash" then
               if player.char_str == "twelve" then
                  sequence = {
                     {"down"}, {"up", "back"}, {"up", "back"}, {"up", "back"}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
                     {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {"forward"}, {}, {"forward"}
                  }
               else
                  i_movement_list = i_movement_list + 1
                  state = "queue_move"
                  return
               end
            elseif name == "block_high_proximity" then
               rec.recording_options.ignore_movement = true
               inputs.queue_input_sequence(dummy, {{"MK"}})
               for i = 1, 30 do
                  table.insert(sequence, {"back"})
                  Queue_Command(gamestate.frame_number + i, write_memory.clear_motion_data, {player})
               end
            elseif name == "block_low_proximity" then
               rec.recording_options.ignore_movement = true
               inputs.queue_input_sequence(dummy, {{"down", "MK"}})
               for i = 1, 30 do
                  table.insert(sequence, {"down", "back"})
                  Queue_Command(gamestate.frame_number + i, write_memory.clear_motion_data, {player})
               end
            elseif name == "block_high_air_proximity" then
               rec.recording_options.ignore_movement = true
               allow_dummy_movement = true
               local h = character_specific[player.char_str].height.standing.min - 50
               m_dummy_reset_pos_offset = {80, h}
               inputs.queue_input_sequence(dummy, {{"up"}, {"up"}, {}, {}, {}, {}, {"HK"}})
               for i = 1, 30 do
                  table.insert(sequence, {"back"})
                  Queue_Command(gamestate.frame_number + i, write_memory.clear_motion_data, {player})
               end
               Queue_Command(gamestate.frame_number + 60, land_player, {dummy})
            elseif name == "block_high_air" then
               rec.recording_options.ignore_movement = true
               local h = character_specific[player.char_str].height.standing.min - 56
               m_dummy_reset_pos_offset = {80, h}
               inputs.queue_input_sequence(dummy, {{"up"}, {"up"}, {}, {}, {}, {}, {"HK"}})
               for i = 1, 30 do
                  table.insert(sequence, {"back"})
                  Queue_Command(gamestate.frame_number + i, write_memory.clear_motion_data, {player})
               end
               Queue_Command(gamestate.frame_number + 80, land_player, {dummy})
            elseif name == "parry_high" then
               inputs.queue_input_sequence(dummy, {{"MK"}})
               Queue_Command(gamestate.frame_number + 1, inputs.queue_input_sequence, {player, {{"forward"}}})
               Queue_Command(gamestate.frame_number + 2, write_memory.clear_motion_data, {player})
               -- 24 25
            elseif name == "parry_low" then
               inputs.queue_input_sequence(dummy, {{"down", "MK"}})
               Queue_Command(gamestate.frame_number + 1, inputs.queue_input_sequence, {player, {{"down"}}})
               Queue_Command(gamestate.frame_number + 2, write_memory.clear_motion_data, {player})
               -- 26
            elseif name == "parry_air" then
               m_dummy_reset_pos_offset = {100, 40}
               inputs.queue_input_sequence(dummy, {{"up"}, {"up"}, {}, {}, {}, {}, {"HK"}})
               inputs.queue_input_sequence(player, {{"up"}})
               Queue_Command(gamestate.frame_number + 14, inputs.queue_input_sequence, {player, {{"forward"}}})
               Queue_Command(gamestate.frame_number + 15, write_memory.clear_motion_data, {player})
               -- Queue_Command(gamestate.frame_number + 80, write_memory.write_pos, {player, player.pos_x, 0}})
               Queue_Command(gamestate.frame_number + 80, land_player, {player})
               -- 27
            end
            if is_jump then
               -- rec.recording_options.infinite_loop = true
               Queue_Command(gamestate.frame_number + clear_jump_after, write_memory.clear_motion_data, {player})
               Queue_Command(gamestate.frame_number + clear_jump_after,
                             function() rec.recording_options.ignore_motion = true end)
               Queue_Command(gamestate.frame_number + clear_jump_after + 100, land_player, {player})
            end

            write_memory.write_pos(player, m_player_reset_pos[1], m_player_reset_pos[2])
            write_memory.write_pos(dummy, player.pos_x + m_dummy_reset_pos_offset[1],
                                   player.pos_y + m_dummy_reset_pos_offset[2])
            write_memory.fix_screen_pos(player, dummy, gamestate.stage)
            write_memory.clear_motion_data(player)
            inputs.queue_input_sequence(player, sequence)
            print(name)
         else
            state = "finished"
            i_movement_list = 1
            return
         end
      end
      if setup and (state == "wait_for_initial_anim" or rec.recording) then
         if not allow_dummy_movement then
            write_memory.write_pos(dummy, player.pos_x + m_dummy_reset_pos_offset[1],
                                   player.pos_y + m_dummy_reset_pos_offset[2])
         end
         record_framedata(player, {}, name)
      end
   end
end

local i_wakeups = 1
local previous_posture = 0
local function record_wakeups(player)
   local dummy = player.other
   if gamestate.is_in_match and debug_settings.recording_framedata then

      if not setup and state == "start" then
         setup = true
         state = "ready"
      end
      if state == "wait_for_match_start" then
         if gamestate.has_match_just_started then state = "queue_move" end
      elseif state == "ready" then
         if gamestate.is_in_match then state = "queue_move" end
      end

      if state == "queue_move" then
         if i_wakeups <= #wakeups_list then
            rec.recording_options = {recording_wakeups = true, record_next_anim = true}
            current_attack = tools.deepcopy(wakeups_list[i_wakeups])
            if dummy.char_str ~= current_attack.character then
               state = "wait_for_match_start"
               Register_After_Load_State(character_select.force_select_character, {player.id, player.char_str, 1, "LP"})
               Register_After_Load_State(character_select.force_select_character,
                                         {dummy.id, current_attack.character, 1, "MK"})
               character_select.start_character_select_sequence()
               return
            end
            current_attack.reset_pos_x = 440
            rec.dummy_offset_x = fd.get_contact_distance(player)
            if current_attack.name == "throw" then
               name = "wakeup"
            elseif current_attack.name == "d_hk" then
               name = "wakeup"
            elseif current_attack.name == "kazekiri" then
               name = "wakeup_quick"
            elseif current_attack.name == "kubiori" then
               name = "wakeup_quick_reverse"
            end
            write_memory.write_pos(player, current_attack.reset_pos_x, 0)
            write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0)
            memory.writebyte(dummy.addresses.stun_bar_char, 0)
            memory.writebyte(dummy.addresses.life, 160)
            write_memory.fix_screen_pos(player, dummy, gamestate.stage)
            inputs.queue_input_sequence(dummy, current_attack.sequence)

            state = "wait_for_knockdown"
         else
            i_wakeups = 1
            state = "finished"
            return
         end
      end
      if rec.recording then
         if player.posture == 0 and previous_posture == 0x26 then
            rec.recording_options.insert_wakeup = true
            state = "wait_for_idle"
         end
         if state == "wait_for_idle" then
            if player.is_idle and player.has_animation_just_changed and player.action == 0 then
               end_recording(player, {}, name)
               i_wakeups = i_wakeups + 1
               state = "queue_move"
            end
         elseif state == "recording" then
            if player.has_animation_just_changed then new_animation(player, {}, name) end
         end
      else
         if state == "wait_for_knockdown" then
            if player.posture == 0x26 then
               write_memory.clear_motion_data(player)
               new_recording(player, {}, name)
               state = "recording"
            end
         end
      end
      if setup then
         local should_tap_down = player.previous_can_fast_wakeup == 0 and player.can_fast_wakeup == 1

         if should_tap_down and current_attack.quick then
            local input = joypad.get()
            input[player.prefix .. " Down"] = true
            joypad.set(input)
         end

         record_framedata(player, {}, name)
      end
      previous_posture = player.posture
   end
end

local landing_list = {
   "jump_forward", "jump_neutral", "jump_back", "sjump_forward", "sjump_neutral", "sjump_back", "air_dash"
}
local i_landing_list = 1

local function record_landing(player)
   local dummy = player.other
   if gamestate.is_in_match and debug_settings.recording_framedata then
      if player.action == 0 or player.action == 7 then
         if rec.recording then
            if player.has_animation_just_changed then
               end_recording(player, {}, name)
               i_landing_list = i_landing_list + 1
            end
         end
      elseif state == "wait_for_initial_anim" and player.has_animation_just_changed then
         if name == "jump_forward" or name == "jump_neutral" or name == "jump_back" then
            if player.action == 12 then
               name = "jump_startup"
               new_recording(player, {}, name)
            end
         elseif name == "sjump_forward" or name == "sjump_neutral" or name == "sjump_back" then
            if player.action == 13 then
               name = "sjump_startup"
               new_recording(player, {}, name)
            end
         elseif name == "air_dash" then
            if player.animation == "b394" then new_recording(player, {}, name) end
         else
            new_recording(player, {}, name)
         end
      elseif rec.recording then
         if player.has_animation_just_changed then
            if player.action == 14 then
               name = "jump_forward"
            elseif player.action == 15 then
               name = "jump_neutral"
            elseif player.action == 16 then
               name = "jump_back"
            elseif player.action == 20 then
               name = "sjump_forward"
            elseif player.action == 21 then
               name = "sjump_neutral"
            elseif player.action == 22 then
               name = "sjump_back"
            end
            new_animation(player, {}, name)
         end
      end
      if state == "ready" then
         if player.is_idle and dummy.is_idle and player.action == 0 then state = "queue_move" end
      elseif state == "wait_for_match_start" then
         if gamestate.has_match_just_started then state = "queue_move" end
      end

      if not setup and state == "start" then
         setup = true
         state = "ready"
      end

      if state == "make_sure_action_is_0" then
         -- remy turns around slow
         if player.action == 0 then state = "wait_for_initial_anim" end
      end

      if state == "queue_move" then
         state = "wait_for_initial_anim"
         if i_landing_list <= #landing_list then
            rec.recording_options = {recording_landing = true}
            allow_dummy_movement = false
            name = landing_list[i_landing_list]
            local sequence = {}
            m_player_reset_pos = {440, 0}
            m_dummy_reset_pos_offset = {100, 0}
            if name == "jump_forward" then
               sequence = {{"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
            elseif name == "jump_neutral" then
               sequence = {{"up"}, {"up"}, {"up"}, {}, {}, {}, {}}
            elseif name == "jump_back" then
               sequence = {{"up", "back"}, {"up", "back"}, {"up", "back"}, {}, {}, {}, {}}
            elseif name == "sjump_forward" then
               sequence = {{"down"}, {"up", "forward"}, {"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
            elseif name == "sjump_neutral" then
               sequence = {{"down"}, {"up"}, {"up"}, {"up"}, {}, {}, {}, {}}
            elseif name == "sjump_back" then
               sequence = {{"down"}, {"up", "back"}, {"up", "back"}, {"up", "back"}, {}, {}, {}, {}}
            elseif name == "air_dash" then
               if player.char_str == "twelve" then
                  sequence = {
                     {"down"}, {"up", "back"}, {"up", "back"}, {"up", "back"}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
                     {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {"forward"}, {}, {"forward"}
                  }
               else
                  i_landing_list = i_landing_list + 1
                  state = "queue_move"
                  return
               end
            end

            write_memory.write_pos(player, m_player_reset_pos[1], m_player_reset_pos[2])
            write_memory.write_pos(dummy, player.pos_x + m_dummy_reset_pos_offset[1],
                                   player.pos_y + m_dummy_reset_pos_offset[2])
            write_memory.fix_screen_pos(player, dummy, gamestate.stage)
            write_memory.clear_motion_data(player)
            inputs.queue_input_sequence(player, sequence)
            print(name)
         else
            state = "finished"
            i_landing_list = 1
            return
         end
      end
      if setup then
         if not allow_dummy_movement then
            write_memory.write_pos(dummy, player.pos_x + m_dummy_reset_pos_offset[1],
                                   player.pos_y + m_dummy_reset_pos_offset[2])
         end
         record_framedata(player, {}, name)
      end
   end
end

local function has_projectiles(p)
   for _, obj in pairs(gamestate.projectiles) do if obj.emitter_id == p.id then return true end end
   return false
end

local function populate_moves(player)
   local moves = tools.deepcopy(move_list[player.char_str])
   local i = 1
   rec.throw_uoh_pa = tools.deepcopy(throw_uoh_pa)
   rec.specials = {}
   rec.supers = {}
   rec.block_pattern = nil
   while i <= #moves do
      if moves[i].air and moves[i].air == "yes" then
         moves[i].air = nil
         local move = tools.deepcopy(moves[i])
         move.air = "only"
         move.name = move.name .. "_air"
         table.insert(moves, i + 1, move)
      end
      if moves[i].move_type == "special" then
         if moves[i].name == "tsumuji" then
            local move = tools.deepcopy(moves[i])
            move.name = "tsumuji_low"
            table.insert(moves, i + 1, move)
         elseif moves[i].name == "ducking" then
            local move = tools.deepcopy(moves[i])
            move.name = "ducking_upper"
            table.insert(moves, i + 1, move)
            move = tools.deepcopy(moves[i])
            move.name = "ducking_straight"
            table.insert(moves, i + 1, move)
         elseif moves[i].name == "hyakki" then
            local move = tools.deepcopy(moves[i])
            move.name = "hyakki_kick"
            table.insert(moves, i + 1, move)
            move = tools.deepcopy(moves[i])
            move.name = "hyakki_punch"
            table.insert(moves, i + 1, move)
            move = tools.deepcopy(moves[i])
            move.name = "hyakki_throw"
            table.insert(moves, i + 1, move)
         elseif moves[i].name == "hayate" then
            local move = tools.deepcopy(moves[i])
            move.name = "hayate_3"
            table.insert(moves, i + 1, move)
            move = tools.deepcopy(moves[i])
            move.name = "hayate_2"
            table.insert(moves, i + 1, move)
            move = tools.deepcopy(moves[i])
            move.name = "hayate_1"
            table.insert(moves, i + 1, move)
         elseif moves[i].name == "dashing_head_attack" then
            local move = tools.deepcopy(moves[i])
            move.name = "dashing_head_attack_high"
            table.insert(moves, i + 1, move)
         elseif moves[i].name == "tourouzan" then
            local move = tools.deepcopy(moves[i])
            move.name = "tourouzan_2"
            table.insert(moves, i + 1, move)
            move = tools.deepcopy(moves[i])
            move.name = "tourouzan_3"
            table.insert(moves, i + 2, move)
         elseif moves[i].name == "byakko" then
            moves[i].buttons = {"LP", "EXP"}
         elseif moves[i].name == "kobokushi" then
            moves[i].buttons = {"LP", "EXP"}
         end
         if #moves[i].buttons > 0 then
            for j = 1, #moves[i].buttons do
               table.insert(rec.specials, {})
               rec.specials[#rec.specials].air = moves[i].air
               rec.specials[#rec.specials].button = moves[i].buttons[j]
               rec.specials[#rec.specials].input = tools.deepcopy(moves[i].input)
               rec.specials[#rec.specials].name = moves[i].name
               if moves[i].name == "tourouzan_3" and moves[i].buttons[j] == "EXP" then
                  local move = tools.deepcopy(moves[i])
                  move.name = "tourouzan_4"
                  move.buttons = {"EXP"}
                  table.insert(moves, i + 1, move)
                  move = tools.deepcopy(moves[i])
                  move.name = "tourouzan_5"
                  move.buttons = {"EXP"}
                  table.insert(moves, i + 2, move)
               end
            end
         else
            table.insert(rec.specials, {})
            rec.specials[#rec.specials].name = moves[i].name
            rec.specials[#rec.specials].air = moves[i].air
            rec.specials[#rec.specials].button = nil
            rec.specials[#rec.specials].input = tools.deepcopy(moves[i].input)
         end
      elseif moves[i].move_type == "sa1" or moves[i].move_type == "sa2" or moves[i].move_type == "sa3" or
          moves[i].move_type == "sgs" or moves[i].move_type == "kkz" then
         if moves[i].name == "hammer_mountain" then
            local move = tools.deepcopy(moves[i])
            move.name = "hammer_mountain_miss"
            table.insert(moves, i + 1, move)
         end
         if #moves[i].buttons > 0 then
            for j = 1, #moves[i].buttons do
               table.insert(rec.supers, {})
               rec.supers[#rec.supers].air = moves[i].air
               rec.supers[#rec.supers].button = moves[i].buttons[j]
               rec.supers[#rec.supers].input = tools.deepcopy(moves[i].input)
               rec.supers[#rec.supers].name = moves[i].name
               rec.supers[#rec.supers].move_type = moves[i].move_type
            end
         else
            table.insert(rec.supers, {})
            rec.supers[#rec.supers].name = moves[i].name
            rec.supers[#rec.supers].move_type = moves[i].move_type
            rec.supers[#rec.supers].air = moves[i].air
            rec.supers[#rec.supers].button = nil
            rec.supers[#rec.supers].input = tools.deepcopy(moves[i].input)
         end
      end

      i = i + 1
   end
   if player.char_str == "gill" then
      local ressurection = table.remove(rec.supers, 1)
      table.insert(rec.supers, ressurection)
   elseif player.char_str == "oro" then
      local move = tools.deepcopy(rec.supers[1])
      move.name = "kishinriki_activation"
      move.button = nil
      move.input[#move.input] = {"forward", "LP"}
      table.insert(rec.supers, 1, move)
   elseif player.char_str == "q" then
      local move = tools.deepcopy(rec.supers[3])
      move.name = "total_destruction_activation"
      move.button = nil
      move.input[#move.input] = {"forward", "LP"}
      table.insert(rec.supers, 3, move)
      local move = rec.supers[4]
      move.name = "total_destruction_attack"
      move.button = nil
      move.input = {{"down"}, {"down", "forward"}, {"forward", "LP"}}
      local move = tools.deepcopy(rec.supers[4])
      move.name = "total_destruction_throw"
      move.button = nil
      move.input = {{"down"}, {"down", "forward"}, {"forward", "LK"}}
      table.insert(rec.supers, move)
   elseif player.char_str == "ryu" then
      local move = tools.deepcopy(rec.supers[3])
      move.name = "denjin_hadouken_2"
      local n = 30
      for j = 1, n do
         table.insert(move.input, {"LP", "down", "forward"})
         table.insert(move.input, {"LP", "down", "back"})
      end
      table.insert(rec.supers, move)
      move = tools.deepcopy(rec.supers[3])
      move.name = "denjin_hadouken_3"
      n = 35
      for j = 1, n do
         table.insert(move.input, {"LP", "down", "forward"})
         table.insert(move.input, {"LP", "down", "back"})
      end
      table.insert(rec.supers, move)
      move = tools.deepcopy(rec.supers[3])
      move.name = "denjin_hadouken_4"
      n = 45
      for j = 1, n do
         table.insert(move.input, {"LP", "down", "forward"})
         table.insert(move.input, {"LP", "down", "back"})
      end
      table.insert(rec.supers, move)
      move = tools.deepcopy(rec.supers[3])
      move.name = "denjin_hadouken_5"
      n = 65
      for j = 1, n do
         table.insert(move.input, {"LP", "down", "forward"})
         table.insert(move.input, {"LP", "down", "back"})
      end
      table.insert(rec.supers, move)
   end

   if player.char_str == "chunli" or player.char_str == "ibuki" or player.char_str == "oro" then
      table.insert(rec.throw_uoh_pa, {sequence = {{"LP", "LK"}}, name = "throw_air", air = true})
   end

   normals = normals_list[player.char_str]
   other_normals = other_normals_list[player.char_str]
   target_combos = target_combos_list[player.char_str]
   rec.attack_categories = {
      {name = "normals", list = normals}, {name = "jumping_normals", list = jumping_normals},
      {name = "other_normals", list = other_normals}, {name = "target_combos", list = target_combos},
      {name = "throw_uoh_pa", list = rec.throw_uoh_pa}, {name = "specials", list = rec.specials},
      {name = "supers", list = rec.supers}
   }
end

local function record_attacks(player, projectiles)
   if gamestate.is_in_match and debug_settings.recording_framedata then
      local dummy = player.other

      local far_dist = character_specific[player.char_str].half_width + 80
      local close_dist = character_specific[player.char_str].half_width + character_specific[dummy.char_str].half_width

      if player.is_idle then
         if setup then
            if rec.recording then
               if player.has_animation_just_changed and player.action == 0 then
                  end_recording(player, projectiles, name)
               end
            end
            if state == "requeue_move" then state = "queue_move" end
         end
      elseif state == "wait_for_initial_anim" and player.has_animation_just_changed then
         if player.is_attacking or player.is_throwing then
            if current_attack.confirm_animation then
               if not (player.animation == current_attack.confirm_animation) then
                  state = "requeue_move"
                  return
               end
            end
            new_recording(player, projectiles, name)
            state = "new_recording"

            --     elseif player.pending_input_sequence == nil then
            --       print("----->", player.animation)
         elseif current_attack.name and current_attack.name == "pa" then
            new_recording(player, projectiles, name)
            state = "new_recording"
         end
      elseif rec.recording then
         if player.has_animation_just_changed then new_animation(player, projectiles, name) end
      end
      if state == "ready" then
         if has_projectiles(player) then
            state = "wait_for_projectiles"
         elseif dummy.is_idle then
            state = "update_hit_state"
         end
      elseif state == "wait_for_projectiles" then
         if not has_projectiles(player) and dummy.is_idle then state = "update_hit_state" end
      elseif state == "wait_for_match_start" then
         if gamestate.has_match_just_started then state = "queue_move" end
      end

      if not setup and state == "start" and gamestate.is_in_match then
         setup = true
         populate_moves(player)
         state = "queue_move"
      end

      if dummy.char_str ~= "urien" then
         state = "wait_for_match_start"
         Register_After_Load_State(character_select.force_select_character, {player.id, player.char_str, 1, "LP"})
         Register_After_Load_State(character_select.force_select_character, {dummy.id, "urien", 1, "MP"})
         character_select.start_character_select_sequence()
         return
      end

      if state == "queue_move" then
         if rec.i_attacks <= #rec.attack_categories[rec.i_attack_categories].list then
            rec.current_attack_category = rec.attack_categories[rec.i_attack_categories]
         else
            if rec.i_attack_categories >= rec.last_category -- #rec.attack_categories
            and (rec.i_recording_hit_types == #rec.recording_hit_types or rec.current_attack_category.name == "supers") then
               state = "finished"
               rec.i_attacks = 1
               rec.i_attack_categories = 1
               rec.i_recording_hit_types = 1
               rec.current_attack_category = {}
               rec.received_hits = 0
               rec.block_until = 0
               rec.block_max_hits = 0
               write_memory.make_invulnerable(dummy, false)
               return
            end
            if rec.i_recording_hit_types < #rec.recording_hit_types then
               rec.i_recording_hit_types = rec.i_recording_hit_types + 1
               rec.i_attacks = 1
            else
               rec.i_attack_categories = rec.i_attack_categories + 1
               rec.i_recording_hit_types = 1
               rec.i_attacks = 1
               rec.current_attack_category = rec.attack_categories[rec.i_attack_categories]
            end
            if #rec.attack_categories[rec.i_attack_categories].list == 0 then
               rec.i_attack_categories = rec.i_attack_categories + 1
               state = "queue_move"
               return
            end
            return
         end
         state = "wait_for_initial_anim"

         rec.recording_options = {hit_type = rec.recording_hit_types[rec.i_recording_hit_types]}

         rec.received_hits = 0
         rec.block_max_hits = 0

         if rec.current_attack_category.name == "normals" then
            current_attack = tools.deepcopy(normals[rec.i_attacks])
            current_attack.name = tools.sequence_to_name(current_attack.sequence)
            current_attack.reset_pos_x = rec.reset_pos_x
            rec.dummy_offset_x = far_dist
            rec.dummy_offset_y = 0
            if not (rec.recording_options.hit_type == "miss") then
               rec.dummy_offset_x = close_dist
               if current_attack.far then rec.dummy_offset_x = far_dist end
            end
            if rec.recording_geneijin then if current_attack.self_chain then current_attack.delay = {2} end end
         elseif rec.current_attack_category.name == "other_normals" then
            current_attack = tools.deepcopy(other_normals[rec.i_attacks])
            if not current_attack.name then
               current_attack.name = tools.sequence_to_name(current_attack.sequence)
               if current_attack.air then
                  current_attack.name = current_attack.name .. "_air"
               elseif current_attack.air_dash then
                  current_attack.name = "air_dash_" .. current_attack.name
               end
               if string.len(current_attack.name) == 2 then
                  current_attack.name = "cl_" .. current_attack.name
               end
            end
            current_attack.reset_pos_x = rec.reset_pos_x
            rec.dummy_offset_x = close_dist
            rec.dummy_offset_y = 0
            if not (rec.recording_options.hit_type == "miss") then rec.dummy_offset_x = close_dist end

            local sequence = current_attack.sequence

            if player.char_str == "chunli" then
               if current_attack.name == "cl_MK" then
                  current_attack.hits_appear_after_block = true
                  rec.block_max_hits = 2
                  local n = 0
                  n = 22 * rec.block_until
                  if rec.recording_options.hit_type == "block" then n = n + 14 end
                  for i = 1, n do table.insert(sequence, {"MK"}) end
               elseif current_attack.name == "d_MK_air" and rec.recording_options.hit_type == "block" then
                  current_attack.offset_x = -30
                  Queue_Command(gamestate.frame_number + #sequence, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 5, 0})
               elseif current_attack.name == "d_HP_air" and rec.recording_options.hit_type == "block" then
                  Queue_Command(gamestate.frame_number + #sequence + 10, write_memory.write_pos_y, {player, 40})
               end
            elseif player.char_str == "hugo" then
               if current_attack.name == "d_HP_air" and rec.recording_options.hit_type == "block" then
                  Queue_Command(gamestate.frame_number + #sequence + 8, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 20, 0})
               end
            elseif player.char_str == "ken" then
               if current_attack.name == "MK_hold" then
                  current_attack.hits_appear_after_block = true
                  rec.block_max_hits = 2
                  local n = 0
                  n = 22 * rec.block_until
                  if rec.recording_options.hit_type == "block" then n = n + 14 end
                  for i = 1, n do table.insert(sequence, {"MK"}) end
               elseif current_attack.name == "f_HK_hold" then
                  local n = 10
                  for i = 1, n do table.insert(sequence, {"forward", "HK"}) end
               end
            elseif player.char_str == "makoto" then
               if current_attack.name == "f_HK_hold" then
                  local n = 20
                  for i = 1, n do table.insert(sequence, {"forward", "HK"}) end
               end
            elseif player.char_str == "twelve" and current_attack.name == "air_dash_HK" and
                rec.recording_options.hit_type == "block" then
               Queue_Command(gamestate.frame_number + 35, write_memory.write_pos,
                             {dummy, current_attack.reset_pos_x + 5, 0})
            elseif player.char_str == "yang" or player.char_str == "yun" then
               if current_attack.name == "raigeki_LK" and rec.recording_options.hit_type == "block" then
                  Queue_Command(gamestate.frame_number + #sequence + 20, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 30, 0})
               end
            end
            if current_attack.max_hits == 0 and rec.recording_options.hit_type == "block" then
               rec.i_attacks = rec.i_attacks + 1
               state = "queue_move"
               return
            end
            if rec.recording_geneijin then if current_attack.self_chain then current_attack.delay = {2} end end
         elseif rec.current_attack_category.name == "jumping_normals" then
            current_attack = {}
            rec.dummy_offset_x = close_dist
            rec.dummy_offset_y = 0
            rec.recording_options.ignore_next_anim = true
            if not (rec.recording_options.hit_type == "miss") then rec.dummy_offset_x = close_dist end
            local sequence = {}
            local button = jumping_normals[rec.i_attacks][1][1]
            if rec.i_attacks <= 6 then
               name = "u_" .. button
               current_attack.jump_dir = "neutral"
            elseif rec.i_attacks <= 12 then
               name = "uf_" .. button
               current_attack.jump_dir = "forward"
            else
               name = "ub_" .. button
               current_attack.jump_dir = "back"
            end
            sequence = tools.deepcopy(jumping_normals[rec.i_attacks])
            current_attack.name = name

            current_attack.sequence = sequence
            current_attack.air = true
            current_attack.reset_pos_x = rec.reset_pos_x

            if player.char_str == "alex" then
               if button == "LK" and rec.recording_options.hit_type == "block" then
                  current_attack.offset_x = -4
               end
            end
            if player.char_str == "elena" then
               if button == "LP" and rec.recording_options.hit_type == "block" then
                  Queue_Command(gamestate.frame_number + #sequence + 10, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 30, 0})
               elseif button == "HK" then
                  current_attack.max_hits = 2
               end
            end
            if player.char_str == "necro" then
               if button == "MK" then
                  current_attack.player_offset_y = -10
               elseif button == "LP" and current_attack.jump_dir == "neutral" then
                  current_attack.player_offset_y = -14
               elseif button == "MP" and current_attack.jump_dir == "neutral" then
                  current_attack.player_offset_y = -14
               end
            end
            if player.char_str == "oro" then
               if (button == "LK" or button == "MK") and rec.recording_options.hit_type == "block" then
                  Queue_Command(gamestate.frame_number + #sequence + 10, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 30, 0})
               elseif button == "HP" and not (current_attack.jump_dir == "neutral") then
                  current_attack.offset_x = -12
                  current_attack.max_hits = 2
               end
            end
            if player.char_str == "ryu" then
               if button == "MP" and not (current_attack.jump_dir == "neutral") then
                  current_attack.player_offset_y = -24
                  current_attack.max_hits = 2
               elseif button == "HP" and current_attack.jump_dir == "neutral" then
                  current_attack.player_offset_y = -10
               end
            end
            if player.char_str == "shingouki" then
               if button == "MK" then current_attack.player_offset_y = -14 end
            end
            if player.char_str == "twelve" then
               if button == "MP" or button == "MK" then
                  current_attack.player_offset_y = -14
               elseif button == "HK" then
                  Queue_Command(gamestate.frame_number + #sequence + 10, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 30, 0})
               end
            end
            if player.char_str == "yang" or player.char_str == "yun" then
               if button == "LP" then
                  Queue_Command(gamestate.frame_number + #sequence + 10, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 30, 0})
               end
            end
         elseif rec.current_attack_category.name == "target_combos" then
            state = "setup_target_combo"
            rec.recording_options.target_combo = true
            rec.recording_options.record_frames_after_hit = true
            --         if rec.i_attacks <= #target_combos then
            current_attack = tools.deepcopy(target_combos[rec.i_attacks])
            current_attack.name = current_attack.name or "tc_" .. tostring(rec.i_attacks)

            if rec.recording_geneijin then name = current_attack.name .. "_geneijin" end

            name = current_attack.name

            if rec.recording_geneijin and current_attack.name ~= "tc_6" then
               rec.i_attacks = rec.i_attacks + 1
               state = "queue_move"
               return
            end

            print(current_attack.name)
            rec.tc_hit_index = 1
            rec.received_hits = 0
            rec.block_max_hits = current_attack.max_hits
            if rec.recording_options.hit_type == "miss" then
               rec.block_max_hits = current_attack.max_hits - 1
            else
               rec.block_until = current_attack.max_hits
            end
            rec.block_pattern = nil
            if current_attack.block then rec.block_pattern = current_attack.block end

            current_attack.reset_pos_x = rec.reset_pos_x

            rec.dummy_offset_x = close_dist
            rec.dummy_offset_y = 0

            if current_attack.far then rec.dummy_offset_x = far_dist end
            if current_attack.offset_x then rec.dummy_offset_x = rec.dummy_offset_x + current_attack.offset_x end

            if current_attack.dummy_offset_list then
               local index = rec.received_hits + 1
               if index <= #current_attack.dummy_offset_list then
                  rec.dummy_offset_x = current_attack.dummy_offset_list[index][1]
                  rec.dummy_offset_y = current_attack.dummy_offset_list[index][2]
               end
            end

            local player_offset_y = current_attack.player_offset_y or 0

            write_memory.make_invulnerable(dummy, false)
            write_memory.clear_motion_data(player)

            if current_attack.air then
               rec.recording_options.air = true
               local sequence = {{"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
               if (is_slow_jumper(player.char_str)) then
                  table.insert(sequence, #sequence, {})
               elseif is_really_slow_jumper(player.char_str) then
                  table.insert(sequence, #sequence, {})
                  table.insert(sequence, #sequence, {})
               end
               table.insert(sequence, current_attack.sequence[1])
               current_attack.attack_start_frame = #sequence

               inputs.queue_input_sequence(player, sequence)
               Queue_Command(gamestate.frame_number + current_attack.attack_start_frame + 100, land_player, {player})
               Queue_Command(gamestate.frame_number + current_attack.attack_start_frame, write_memory.clear_motion_data,
                             {player})
               Queue_Command(gamestate.frame_number + current_attack.attack_start_frame, write_memory.write_pos,
                             {player, current_attack.reset_pos_x, rec.default_air_block_height + player_offset_y})
               write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0)
            else
               write_memory.write_pos(player, current_attack.reset_pos_x, 0)
               write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0)
               --               Queue_Command(gamestate.frame_number + 2, inputs.queue_input_sequence, {current_attack.sequence[1]})
               inputs.queue_input_sequence(player, {current_attack.sequence[1]})
            end

            if rec.overwrite and rec.first_record then
               rec.recording_options.clear_frame_data = true
               rec.first_record = false
            end

            state = "wait_for_initial_anim"
         elseif rec.current_attack_category.name == "throw_uoh_pa" then
            current_attack = tools.deepcopy(rec.throw_uoh_pa[rec.i_attacks])
            current_attack.reset_pos_x = rec.reset_pos_x
            local sequence = current_attack.sequence
            current_attack.attack_start_frame = #sequence

            rec.dummy_offset_x = far_dist
            rec.dummy_offset_y = 0
            if not (rec.recording_options.hit_type == "miss") then
               rec.dummy_offset_x = close_dist - character_specific[dummy.char_str].half_width
               if current_attack.far then rec.dummy_offset_x = far_dist end
            end
            if rec.recording_options.hit_type == "miss" then
               if current_attack.name == "throw_forward" or current_attack.name == "throw_back" then
                  rec.i_attacks = rec.i_attacks + 1
                  state = "queue_move"
                  return
               end
            end

            if current_attack.name == "throw_neutral" or current_attack.name == "throw_forward" or current_attack.name ==
                "throw_back" then
               current_attack.throw = true
               if rec.recording_options.hit_type == "block" then
                  for i = 1, 6 do table.insert(sequence, 1, {}) end
               end
            end
            if current_attack.name == "throw_air" then
               current_attack.throw = true
               if rec.recording_options.hit_type == "block" then
                  inputs.queue_input_sequence(dummy, {{"up"}, {"up"}, {"up"}, {"up"}, {"up"}})
                  Queue_Command(gamestate.frame_number + #sequence + 6, write_memory.write_pos,
                                {dummy, current_attack.reset_pos_x + 30, 45})
               end
            end

            if current_attack.name == "pa" then current_attack.max_hits = 0 end
            if player.char_str == "alex" then
               if current_attack.name == "pa" then
                  for i = 1, 80 do table.insert(sequence, {"HP", "HK"}) end
                  rec.recording_options.infinite_loop = true
               end
            end
            if player.char_str == "chunli" then
               if current_attack.name == "pa" then
                  for i = 1, 60 do table.insert(sequence, {"HP", "HK"}) end
               end
            end
            if player.char_str == "dudley" then
               if current_attack.name == "pa" then
                  current_attack.is_projectile = true
                  current_attack.max_hits = 1
                  current_attack.offset_x = 150
               end
            end
            if player.char_str == "elena" then
               if current_attack.name == "pa" then
                  current_attack.max_hits = 1
                  current_attack.block = {2, 1}
               end
            end
            if player.char_str == "hugo" then
               if current_attack.name == "pa" then
                  for i = 1, 80 do table.insert(sequence, {"HP", "HK"}) end
               end
            end
            if player.char_str == "ibuki" then
               if current_attack.name == "pa" then current_attack.max_hits = 1 end
            end
            if player.char_str == "ken" then
               if current_attack.name == "pa" then current_attack.max_hits = 2 end
            end
            if player.char_str == "makoto" then
               if current_attack.name == "pa" then
                  for i = 1, 250 do table.insert(sequence, {"HP", "HK"}) end
                  if rec.recording_options.hit_type == "block" then
                     for i = 1, 20 do table.insert(sequence, {"HP", "HK"}) end
                  end
                  current_attack.max_hits = 1
               end
            end
            if player.char_str == "necro" then
               if current_attack.name == "pa" then
                  for i = 1, 60 do table.insert(sequence, {"HP", "HK"}) end
                  if rec.recording_options.hit_type == "block" then
                     for i = 1, 60 do table.insert(sequence, {"HP", "HK"}) end
                  end
                  rec.recording_options.infinite_loop = true
                  current_attack.max_hits = 6
               end
            end
            if player.char_str == "sean" then
               if current_attack.name == "pa" then
                  current_attack.is_projectile = true
                  current_attack.max_hits = 1
                  current_attack.offset_x = 150
               end
            end
            if player.char_str == "urien" then
               if current_attack.name == "pa" then
                  current_attack.max_hits = 1
                  current_attack.block = {2}
               end
            end
            if player.char_str == "yang" then
               if current_attack.name == "pa" then current_attack.max_hits = 1 end
            end
            if player.char_str == "yun" then
               if current_attack.name == "pa" then
                  for i = 1, 120 do table.insert(sequence, {"HP", "HK"}) end
                  if rec.recording_options.hit_type == "block" then
                     for i = 1, 100 do table.insert(sequence, {"HP", "HK"}) end
                  end
                  rec.recording_options.infinite_loop = true
                  current_attack.max_hits = 6
               end
            end

            if current_attack.name == "pa" and rec.recording_options.hit_type == "block" then
               if current_attack.max_hits == 0 then
                  rec.i_attacks = rec.i_attacks + 1
                  state = "queue_move"
                  return
               end
            end

            current_attack.sequence = sequence
         elseif rec.current_attack_category.name == "specials" then
            current_attack = tools.deepcopy(rec.specials[rec.i_attacks])
            local base_name = current_attack.name
            local button = current_attack.button
            local sequence = current_attack.input
            current_attack.attack_start_frame = #sequence
            current_attack.base_name = base_name

            if button then current_attack.name = current_attack.name .. "_" .. button end

            rec.dummy_offset_x = close_dist
            rec.dummy_offset_y = 0

            if current_attack.air and current_attack.air == "only" then current_attack.land_after = 100 end

            current_attack.reset_pos_x = rec.reset_pos_x

            local i = 1
            while i <= #sequence do
               local j = 1
               while j <= #sequence[i] do
                  if sequence[i][j] == "button" then
                     if button == "EXP" then
                        table.remove(sequence[i], j)
                        table.insert(sequence[i], j, "LP")
                        table.insert(sequence[i], j, "MP")
                     elseif button == "EXK" then
                        table.remove(sequence[i], j)
                        table.insert(sequence[i], j, "LK")
                        table.insert(sequence[i], j, "MK")
                     else
                        table.remove(sequence[i], j)
                        table.insert(sequence[i], j, button)
                     end
                  end
                  j = j + 1
               end
               i = i + 1
            end

            if base_name == "hyakuretsukyaku" then
               if button == "EXK" then
                  sequence = {{"legs_" .. button, "LK", "MK"}}
               else
                  sequence = {{"legs_" .. button, button}}
               end
            end

            if player.char_str == "alex" then
               if base_name == "flash_chop" then if button == "EXP" then current_attack.max_hits = 2 end end
               if base_name == "air_knee_smash" then
                  rec.dummy_offset_y = 100
                  current_attack.max_hits = 0
                  current_attack.throw = true
                  if button == "HK" then
                     rec.dummy_offset_y = 120
                  elseif button == "EXK" then
                     current_attack.max_hits = 1
                     rec.dummy_offset_x = 80
                     rec.dummy_offset_y = 0
                  end
               end
               if base_name == "air_stampede" then
                  if button == "MK" then
                     rec.dummy_offset_x = 120
                  elseif button == "HK" then
                     rec.dummy_offset_x = 150
                  elseif button == "EXK" then
                     rec.dummy_offset_x = 120
                  end
               end
               if base_name == "slash_elbow" then
                  rec.dummy_offset_x = 120
                  if button == "EXK" then current_attack.max_hits = 2 end
               end
               if base_name == "spiral_ddt" then current_attack.name = base_name end
               if base_name == "power_bomb" or base_name == "spiral_ddt" then
                  current_attack.throw = true
                  if base_name == "spiral_ddt" then if button == "HK" then rec.dummy_offset_x = 160 end end
               end
            end

            if player.char_str == "chunli" then
               if base_name == "hyakuretsukyaku" then
                  if button == "LK" then
                     n = 40
                     current_attack.max_hits = 16
                  elseif button == "MK" then
                     n = 40
                     current_attack.max_hits = 20
                  elseif button == "HK" then
                     n = 30
                     current_attack.max_hits = 16
                  elseif button == "EXK" then
                     n = 30
                     current_attack.max_hits = 16
                  end

                  if rec.recording_options.hit_type == "block" then n = n * 5 end

                  for i = 1, n do
                     table.insert(sequence, {})
                     if button == "EXK" then
                        table.insert(sequence, {"LK", "MK"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
               end
               if base_name == "kikouken" then
                  rec.dummy_offset_x = 150
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
               end
               if base_name == "spinning_bird_kick" then
                  rec.dummy_offset_x = 80
                  if button == "LK" then
                     current_attack.max_hits = 4
                  elseif button == "MK" then
                     current_attack.max_hits = 6
                  elseif button == "HK" then
                     current_attack.max_hits = 8
                  elseif button == "EXK" then
                     current_attack.max_hits = 5
                     current_attack.dummy_offset_list = {{80, 0}, {-80, 0}, {80, 0}, {-80, 0}, {80, 0}}
                  end
               end
               if base_name == "hazanshuu" then
                  rec.dummy_offset_x = 80
                  if button == "LK" then
                  elseif button == "MK" then
                     rec.dummy_offset_x = 100
                  elseif button == "HK" then
                     rec.dummy_offset_x = 150
                  end
               end
            end

            if player.char_str == "dudley" then
               if base_name == "jet_upper" then
                  rec.dummy_offset_x = 80
                  if button == "HP" or button == "EXP" then current_attack.max_hits = 2 end
               end
               if base_name == "ducking" then
                  rec.dummy_offset_x = 150
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "ducking_straight" then
                  current_attack.name = base_name
                  local n = 10
                  if button == "LK" then
                     n = 10
                  elseif button == "MK" then
                     n = 10
                  elseif button == "HK" then
                     n = 15
                  end

                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"HP"})
                  rec.dummy_offset_x = 100
                  current_attack.max_hits = 1
               end
               if base_name == "ducking_upper" then
                  current_attack.name = base_name
                  local n = 10
                  if button == "LK" then
                     n = 10
                  elseif button == "MK" then
                     n = 10
                  elseif button == "HK" then
                     n = 15
                  end
                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"HK"})
                  rec.dummy_offset_x = 100
                  current_attack.max_hits = 2
               end
               if base_name == "machinegun_blow" then
                  rec.dummy_offset_x = 100
                  if button == "LP" then
                     current_attack.max_hits = 3
                  elseif button == "MP" then
                     current_attack.max_hits = 4
                  elseif button == "HP" then
                     current_attack.max_hits = 6
                  elseif button == "EXP" then
                     current_attack.max_hits = 7
                  end
               end
               if base_name == "cross_counter" then
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "short_swing_blow" then
                  if button == "EXK" then current_attack.max_hits = 3 end
               end
            end
            if player.char_str == "elena" then
               if base_name == "scratch_wheel" then
                  if button == "LK" then
                     current_attack.max_hits = 1
                  elseif button == "MK" then
                     current_attack.max_hits = 2
                  elseif button == "HK" then
                     current_attack.max_hits = 3
                  elseif button == "EXK" then
                     current_attack.max_hits = 4
                  end
               end
               if base_name == "rhino_horn" then
                  if button == "LK" then
                     current_attack.max_hits = 3
                  elseif button == "MK" then
                     current_attack.max_hits = 3
                  elseif button == "HK" then
                     current_attack.max_hits = 3
                  elseif button == "EXK" then
                     current_attack.max_hits = 4
                  end
               end
               if base_name == "mallet_smash" then
                  rec.dummy_offset_x = 100
                  current_attack.max_hits = 2
               end
               if base_name == "spin_sides" then
                  rec.dummy_offset_x = 100
                  current_attack.max_hits = 4
                  current_attack.optional_anim = {0, 0, 1, 0}
                  if button == "EXK" then
                     current_attack.max_hits = 5
                     current_attack.optional_anim = {0, 0, 0, 0, 1}
                  end
                  local n = 30
                  if rec.recording_options.hit_type == "block" then n = 60 end
                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"down"})
                  table.insert(sequence, {"down", "back"})
                  table.insert(sequence, {"back"})
                  if button == "EXK" then
                     table.insert(sequence, {"LK", "MK"})
                  else
                     table.insert(sequence, {button})
                  end

               end
               if base_name == "lynx_tail" then
                  if button == "LK" then
                     current_attack.max_hits = 2
                     current_attack.block = {2, 2}
                  elseif button == "MK" then
                     current_attack.max_hits = 2
                     current_attack.block = {2, 2}
                  elseif button == "HK" then
                     current_attack.max_hits = 4
                     current_attack.block = {2, 2, 2, 2}
                  elseif button == "EXK" then
                     current_attack.max_hits = 5
                     current_attack.block = {2, 2, 2, 2, 1}
                  end
               end
            end

            if player.char_str == "gill" then
               if base_name == "pyrokinesis" then
                  current_attack.max_hits = 2
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  rec.dummy_offset_x = 80
                  if button == "LP" then
                     rec.dummy_offset_x = 120
                  elseif button == "HP" then
                     rec.dummy_offset_x = 100
                     if rec.recording_options.hit_type == "block" then
                        current_attack.projectile_offset = {0, -50}
                     end
                  end
               end
               if base_name == "cyber_lariat" then
                  current_attack.max_hits = 2
                  rec.dummy_offset_x = 100
               end
               if base_name == "moonsault_kneedrop" then
                  current_attack.max_hits = 2
                  rec.block_max_hits = 1
                  current_attack.hits_appear_after_block = true
                  rec.dummy_offset_x = 70
                  Queue_Command(gamestate.frame_number + 2, write_memory.write_pos, {dummy, player.pos_x + 250, 0})
               end
            end

            if player.char_str == "gouki" then
               if base_name == "gohadouken" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
               end
               if base_name == "gohadouken_air" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
               end
               if base_name == "shakunetsu" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if button == "LP" then
                     current_attack.max_hits = 1
                  elseif button == "MP" then
                     current_attack.max_hits = 2
                  elseif button == "HP" then
                     current_attack.max_hits = 3
                  end
               end
               if base_name == "goshoryuken" then
                  if button == "LP" then
                     current_attack.max_hits = 1
                  elseif button == "MP" then
                     current_attack.max_hits = 2
                  elseif button == "HP" then
                     current_attack.max_hits = 3
                  end
               end
               if base_name == "tatsumaki" then
                  if button == "LK" then
                     current_attack.max_hits = 2
                     current_attack.dummy_offset_list = {{80, 0}, {-70, 0}}
                  elseif button == "MK" then
                     current_attack.max_hits = 5
                     current_attack.dummy_offset_list = {{80, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}}
                  elseif button == "HK" then
                     current_attack.max_hits = 9
                     current_attack.dummy_offset_list = {
                        {80, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}
                     }
                  end
               end
               if base_name == "tatsumaki_air" then
                  if button == "LK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-70, 0}}
                     current_attack.max_hits = 2
                  elseif button == "MK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-70, 0}, {80, 0}, {-70, 0}}
                     current_attack.max_hits = 4
                  elseif button == "HK" then
                     current_attack.player_offset_y = -10
                     current_attack.dummy_offset_list = {
                        {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}
                     }
                     current_attack.max_hits = 8
                     current_attack.land_after = 120
                  end
                  if rec.recording_options.hit_type == "block" then
                     Queue_Command(gamestate.frame_number + 10, write_memory.clear_motion_data, {player})
                  end
               end

               -- hyakki only has one animation. button determines the velocity/acceleration applied at the start
               if base_name == "hyakki" then
                  current_attack.name = base_name
                  current_attack.block = {2}
                  current_attack.reset_pos_x = 220
                  if button == "MK" then
                     rec.dummy_offset_x = 150
                  else
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "hyakki_punch" then
                  current_attack.name = base_name
                  if button == "MK" then
                     rec.dummy_offset_x = 150
                     local n = 20
                     for i = 1, n do table.insert(sequence, {}) end
                     table.insert(sequence, {"LP"})
                  else
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "hyakki_kick" then
                  current_attack.name = base_name
                  if button == "MK" then
                     rec.dummy_offset_x = 150
                     local n = 20
                     for i = 1, n do table.insert(sequence, {}) end
                     table.insert(sequence, {"LK"})
                  else
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "hyakki_throw" then
                  current_attack.name = base_name
                  current_attack.throw = true
                  if button == "MK" then
                     rec.dummy_offset_x = 150
                     local n = 20
                     for i = 1, n do table.insert(sequence, {}) end
                     table.insert(sequence, {"LP", "LK"})
                  else
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "asura_forward" or base_name == "asura_backward" then
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
            end

            if player.char_str == "hugo" then
               if base_name == "moonsault_press" or base_name == "ultra_throw" then
                  current_attack.throw = true
               end
               if base_name == "moonsault_press" then
                  if button == "LP" then
                     current_attack.confirm_animation = "0444"
                  elseif button == "MP" then
                     current_attack.confirm_animation = "05a4"
                  elseif button == "HP" then
                     current_attack.confirm_animation = "062c"
                  end
               end
               if base_name == "meat_squasher" then
                  if button == "LK" then
                     current_attack.confirm_animation = "1d64"
                  elseif button == "MK" then
                     current_attack.confirm_animation = "1f24"
                  elseif button == "HK" then
                     current_attack.confirm_animation = "2184"
                  end
               end
               if base_name == "shootdown_backbreaker" then
                  current_attack.throw = true
                  rec.dummy_offset_y = 90
                  if button == "HK" then rec.dummy_offset_y = 140 end
               end
               if base_name == "meat_squasher" then
                  rec.dummy_offset_x = 100
                  current_attack.throw = true
               end
               if base_name == "giant_palm_bomber" then
                  rec.dummy_offset_x = 120
                  if button == "EXP" then current_attack.max_hits = 3 end
               end
               if base_name == "monster_lariat" then
                  rec.dummy_offset_x = 120
                  current_attack.reset_pos_x = 180
                  if button == "EXK" then
                     local n = 60
                     for i = 1, n do table.insert(sequence, {"LK"}) end
                  end
               end
            end

            if player.char_str == "ibuki" then
               if base_name == "kunai" then
                  current_attack.is_projectile = true
                  rec.dummy_offset_x = 90
                  if button == "MP" or button == "HP" then
                     rec.dummy_offset_x = 120
                  elseif button == "EXP" then
                     current_attack.max_hits = 2
                     rec.dummy_offset_x = 150
                  end
               end
               if base_name == "kubiori" then
                  current_attack.block = {2}
                  rec.dummy_offset_x = 100
               end
               if base_name == "tsumuji" or base_name == "tsumuji_low" then
                  rec.dummy_offset_x = 100
                  if button == "MK" then
                     current_attack.max_hits = 3
                     local n = 30
                     if rec.recording_options.hit_type == "block" then n = 50 end
                     for i = 1, n do
                        table.insert(sequence, {})
                        table.insert(sequence, {button})
                     end
                     current_attack.optional_anim = {0, 0, 1}
                     if base_name == "tsumuji_low" then
                        current_attack.block = {1, 1, 2}
                        for i = 5, #sequence do table.insert(sequence[i], "down") end
                     end
                  else
                     if button == "LK" then
                        current_attack.max_hits = 2
                        current_attack.optional_anim = {0, 1}
                        if base_name == "tsumuji_low" then current_attack.block = {1, 2} end
                     elseif button == "HK" then
                        current_attack.max_hits = 3
                        current_attack.optional_anim = {0, 0, 1}
                        if base_name == "tsumuji_low" then current_attack.block = {1, 1, 2} end
                     elseif button == "EXK" then
                        current_attack.max_hits = 4
                        current_attack.optional_anim = {0, 1, 1, 1}
                        if base_name == "tsumuji_low" then current_attack.block = {1, 2, 2, 2} end
                     end
                     if base_name == "tsumuji_low" then
                        local n = 50
                        if rec.recording_options.hit_type == "block" then n = 120 end
                        if button == "LK" then
                           if rec.recording_options.hit_type == "block" then n = 100 end
                        end
                        if button == "EXK" then
                           if rec.recording_options.hit_type == "block" then n = 150 end
                        end
                        for i = 1, n do table.insert(sequence, {"down"}) end
                     end
                  end
               end
               if base_name == "kazekiri" then
                  if button == "LK" or button == "MK" then
                     current_attack.max_hits = 3
                  elseif button == "HK" or button == "EXK" then
                     current_attack.max_hits = 3
                  end
               end
               if base_name == "hien" then
                  current_attack.max_hits = 2
                  current_attack.hits_appear_after_block = true
                  rec.dummy_offset_x = 100
                  rec.block_max_hits = 1
                  if button == "MK" then
                     if rec.recording_options.hit_type == "miss" then rec.dummy_offset_x = 140 end
                  elseif button == "HK" then
                     if rec.recording_options.hit_type == "miss" then rec.dummy_offset_x = 100 end
                     Queue_Command(gamestate.frame_number + 15, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + 250, 0})
                  elseif button == "EXK" then
                     rec.dummy_offset_x = 80
                     Queue_Command(gamestate.frame_number + 15, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + 100, 0})
                  end
               end
               if base_name == "tsukijigoe" or base_name == "kasumigake" then
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
            end

            if player.char_str == "ken" then
               if base_name == "hadouken" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if button == "EXP" then current_attack.max_hits = 2 end
               end
               if base_name == "shoryuken" then
                  if button == "LP" then
                     current_attack.max_hits = 1
                  elseif button == "MP" then
                     current_attack.max_hits = 2
                  elseif button == "HP" then
                     current_attack.max_hits = 3
                  elseif button == "EXP" then
                     current_attack.max_hits = 4
                  end
               end
               if base_name == "tatsumaki" then
                  current_attack.reset_pos_x = 200
                  if button == "LK" then
                     current_attack.max_hits = 3
                     current_attack.dummy_offset_list = {{80, 0}, {80, 0}, {-60, 0}}
                  elseif button == "MK" then
                     current_attack.max_hits = 6
                     current_attack.dummy_offset_list = {{80, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}}
                  elseif button == "HK" then
                     current_attack.max_hits = 8
                     current_attack.dummy_offset_list = {
                        {80, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}
                     }
                  elseif button == "EXK" then
                     current_attack.max_hits = 10
                     current_attack.dummy_offset_list = {
                        {80, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}
                     }
                  end
               end
               if base_name == "tatsumaki_air" then
                  if rec.recording_options.hit_type == "block" then
                     Queue_Command(gamestate.frame_number + 10, write_memory.clear_motion_data, {player})
                  end
                  if button == "LK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-60, 0}, {80, 0}}
                     current_attack.max_hits = 3
                  elseif button == "MK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}}
                     current_attack.max_hits = 5
                  elseif button == "HK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {
                        {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}
                     }
                     current_attack.max_hits = 8
                     if rec.recording_options.hit_type == "block" then
                        current_attack.land_after = 250
                     end
                  elseif button == "EXK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {
                        {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0},
                        {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}
                     }
                     current_attack.max_hits = 20
                     if rec.recording_options.hit_type == "block" then
                        current_attack.land_after = 550
                     end
                  end
               end
            end

            if player.char_str == "makoto" then
               if base_name == "hayate" then -- level 4
                  current_attack.name = base_name
                  rec.dummy_offset_x = 100
                  if not (button == "EXP") then
                     current_attack.optional_anim = {1}
                     local n = 120
                     for i = 1, n do table.insert(sequence, {button}) end
                  end
               end
               if (base_name == "hayate_3" or base_name == "hayate_2" or base_name == "hayate_1") and button == "EXP" then
                  rec.i_attacks = rec.i_attacks + 1
                  state = "queue_move"
                  return
               end
               if base_name == "hayate_3" then
                  current_attack.name = base_name
                  rec.dummy_offset_x = 100
                  current_attack.optional_anim = {1}
                  local n = 50
                  for i = 1, n do table.insert(sequence, {button}) end
               end
               if base_name == "hayate_2" then
                  current_attack.name = base_name
                  rec.dummy_offset_x = 100
                  current_attack.optional_anim = {1}
                  local n = 30
                  for i = 1, n do table.insert(sequence, {button}) end
               end
               if base_name == "hayate_1" then
                  current_attack.name = base_name
                  rec.dummy_offset_x = 100
                  current_attack.optional_anim = {1}
               end
               if base_name == "fukiage" then
                  rec.dummy_offset_x = 100
                  if rec.recording_options.hit_type == "block" then
                     if button == "LP" then
                        Queue_Command(gamestate.frame_number + 10, write_memory.write_pos,
                                      {dummy, current_attack.reset_pos_x + 3, 0})
                     elseif button == "MP" then
                        Queue_Command(gamestate.frame_number + 13, write_memory.write_pos,
                                      {dummy, current_attack.reset_pos_x + 3, 0})
                     elseif button == "HP" then
                        Queue_Command(gamestate.frame_number + 17, write_memory.write_pos,
                                      {dummy, current_attack.reset_pos_x + 3, 0})
                     elseif button == "EXP" then
                        Queue_Command(gamestate.frame_number + 14, write_memory.write_pos,
                                      {dummy, current_attack.reset_pos_x + 73, 0})
                     end
                  end
               end

               if base_name == "karakusa" then current_attack.throw = true end
               if base_name == "tsurugi" then
                  if button == "EXK" then
                     current_attack.max_hits = 2
                     current_attack.land_after = -1
                  end
               end
            end

            if player.char_str == "necro" then
               if base_name == "denji_blast" then
                  local n = 40
                  if button == "LP" then
                     n = 40
                     if rec.recording_options.hit_type == "block" then n = 10 end
                  elseif button == "MP" then
                     n = 60
                     current_attack.max_hits = 21
                     if rec.recording_options.hit_type == "block" then n = 240 end
                  else
                     n = 60
                     current_attack.max_hits = 41
                     if rec.recording_options.hit_type == "block" then n = 460 end
                  end
                  for i = 1, n do
                     table.insert(sequence, {})
                     if button == "EXP" then
                        table.insert(sequence, {"LP", "MP"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
               elseif base_name == "tornado_hook" then
                  current_attack.offset_x = 40
                  if button == "LP" then
                     current_attack.max_hits = 2
                  elseif button == "MP" then
                     current_attack.max_hits = 2
                  elseif button == "HP" then
                     current_attack.offset_x = 70
                     current_attack.reset_pos_x = 140
                     current_attack.max_hits = 3
                  else
                     current_attack.offset_x = 85
                     current_attack.reset_pos_x = 140
                     current_attack.max_hits = 5
                  end
               elseif base_name == "flying_viper" then
                  if button == "LP" then
                  elseif button == "MP" then
                     current_attack.offset_x = 80
                  elseif button == "HP" then
                     current_attack.offset_x = 80
                  elseif button == "EXP" then
                     current_attack.offset_x = 60
                     current_attack.max_hits = 2
                     current_attack.hits_appear_after_parry = true
                     rec.block_max_hits = 1
                  end
               elseif base_name == "rising_cobra" then
                  current_attack.offset_x = 20
                  if button == "EXK" then current_attack.max_hits = 2 end
               elseif base_name == "snake_fang" then
                  current_attack.offset_x = 70
                  current_attack.block = {2}
                  current_attack.throw = true
               end
            end

            if player.char_str == "oro" then
               if base_name == "nichirin" then
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  rec.dummy_offset_x = 80
                  if button == "HP" then
                     if rec.recording_options.hit_type == "block" then
                        current_attack.projectile_offset = {0, -50}
                     end
                  elseif button == "EXP" then
                     rec.dummy_offset_x = 250
                     current_attack.max_hits = 2
                  end
               end
               if base_name == "oniyanma" then
                  rec.dummy_offset_x = 80
                  if button == "HP" or button == "EXP" then
                     current_attack.max_hits = 4
                     if rec.recording_options.hit_type == "block" then rec.dummy_offset_x = 30 end
                  end
               end
               if base_name == "hitobashira" then
                  current_attack.reset_pos_x = 150
                  current_attack.max_hits = 2
                  rec.dummy_offset_x = 65

                  if button == "LK" then
                  elseif button == "MK" then
                     Queue_Command(gamestate.frame_number + 5, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + 160, 0})
                  elseif button == "HK" then
                     Queue_Command(gamestate.frame_number + 5, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + 200, 0})
                  elseif button == "EXK" then
                     Queue_Command(gamestate.frame_number + 5, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + 200, 0})
                     current_attack.max_hits = 3
                  end
                  local n = 20
                  for i = 1, n do
                     table.insert(sequence, {})
                     if button == "EXK" then
                        table.insert(sequence, {"LK", "MK"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
               end
               if base_name == "hitobashira_air" then
                  current_attack.name = base_name
                  if button == "EXK" then current_attack.name = base_name .. "_" .. button end
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 80
                  current_attack.max_hits = 2
                  current_attack.player_offset_y = 0

                  if rec.recording_options.hit_type == "block" then
                     rec.dummy_offset_x = 35
                     Queue_Command(gamestate.frame_number + 10, write_memory.clear_motion_data, {player})
                  end
                  local n = 20
                  for i = 1, n do
                     table.insert(sequence, {})
                     if button == "EXK" then
                        table.insert(sequence, {"LK", "MK"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
               end
               if base_name == "niouriki" then current_attack.throw = true end
            end

            if player.char_str == "q" then
               if base_name == "dashing_head_attack" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 80
               end
               if base_name == "dashing_head_attack_high" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 80
                  local n = 30
                  for i = 1, n do table.insert(sequence, {button}) end
                  if button == "EXP" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "dashing_leg_attack" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 80
                  current_attack.block = {2}
                  if button == "EXK" then
                     current_attack.max_hits = 2
                     current_attack.block = {2, 2}
                  end
               end
               if base_name == "high_speed_barrage" then
                  rec.dummy_offset_x = 80
                  current_attack.max_hits = 3
                  if button == "EXP" then current_attack.max_hits = 7 end
               end
               if base_name == "capture_and_deadly_blow" then
                  rec.dummy_offset_x = 80
                  current_attack.throw = true
               end
            end

            if player.char_str == "remy" then
               if base_name == "light_of_virtue" then
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  rec.dummy_offset_x = 120
                  if button == "LK" or button == "MK" or button == "HK" then
                     current_attack.block = {2}
                  elseif button == "EXP" then
                     current_attack.max_hits = 2
                     current_attack.block = {1, 2}
                  elseif button == "EXK" then
                     current_attack.max_hits = 2
                     current_attack.block = {2, 2}
                  end
               end
               if base_name == "rising_rage_flash" then
                  rec.dummy_offset_x = 80
                  if button == "EXK" then current_attack.max_hits = 2 end
               end
               if base_name == "cold_blue_kick" then
                  rec.recording_options.record_pushboxes = true
                  rec.dummy_offset_x = 150
                  if button == "EXK" then
                     current_attack.max_hits = 2
                     current_attack.hits_appear_after_block = true
                     rec.block_max_hits = 1
                  end
               end
            end

            if player.char_str == "ryu" then
               if base_name == "hadouken" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if button == "EXP" then current_attack.max_hits = 2 end
               end
               if base_name == "shoryuken" then
                  if button == "LP" then
                     current_attack.max_hits = 1
                  elseif button == "MP" then
                     current_attack.max_hits = 1
                  elseif button == "HP" then
                     current_attack.max_hits = 1
                  elseif button == "EXP" then
                     current_attack.max_hits = 2
                  end
               end

               if base_name == "tatsumaki" then
                  current_attack.reset_pos_x = 200
                  if button == "LK" then
                     current_attack.max_hits = 1
                  elseif button == "MK" then
                     current_attack.max_hits = 3
                  elseif button == "HK" then
                     current_attack.max_hits = 3
                  elseif button == "EXK" then
                     current_attack.max_hits = 5
                     current_attack.dummy_offset_list = {{80, 0}, {-50, 0}, {80, 0}, {-50, 0}, {80, 0}}
                  end
               end
               if base_name == "tatsumaki_air" then
                  if rec.recording_options.hit_type == "block" then
                     Queue_Command(gamestate.frame_number + 10, write_memory.clear_motion_data, {player})
                  end
                  if button == "LK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-50, 0}, {80, 0}, {-50, 0}}
                     current_attack.max_hits = 4
                  elseif button == "MK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-50, 0}, {80, 0}, {-50, 0}, {80, 0}, {-50, 0}}
                     current_attack.max_hits = 6
                     current_attack.land_after = 150
                  elseif button == "HK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {
                        {80, 0}, {-50, 0}, {80, 0}, {-50, 0}, {80, 0}, {-50, 0}, {80, 0}, {-50, 0}
                     }
                     current_attack.max_hits = 8
                     current_attack.land_after = 200
                  elseif button == "EXK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-50, 0}, {80, 0}, {-50, 0}, {80, 0}, {-50, 0}}
                     current_attack.max_hits = 6
                     current_attack.land_after = 150
                  end
               end
               if base_name == "joudan" then rec.dummy_offset_x = 100 end
            end

            if player.char_str == "sean" then
               if base_name == "sean_tackle" then
                  current_attack.throw = true
                  rec.dummy_offset_x = 100

                  local n = 50
                  for i = 1, n do
                     if button == "EXP" then
                        table.insert(sequence, {"LP", "MP"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
               end
               if base_name == "dragon_smash" then if button == "EXP" then current_attack.max_hits = 2 end end
               if base_name == "tornado" then
                  rec.dummy_offset_x = 80
                  if button == "LK" then
                     current_attack.max_hits = 2
                  elseif button == "MK" then
                     current_attack.max_hits = 3
                  elseif button == "HK" then
                     current_attack.max_hits = 4
                  elseif button == "EXK" then
                     current_attack.max_hits = 4
                  end
               end
               if base_name == "ryuubikyaku" then
                  current_attack.name = base_name
                  if button == "EXK" then current_attack.name = base_name .. button end
                  rec.dummy_offset_x = 80
                  if button == "EXK" then current_attack.max_hits = 3 end
               end
               if base_name == "roll" then
                  rec.dummy_offset_x = 80
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
            end

            if player.char_str == "shingouki" then
               if base_name == "gohadouken" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
               end
               if base_name == "gohadouken_air" then
                  rec.dummy_offset_x = 100
                  current_attack.max_hits = 2
                  current_attack.is_projectile = true
               end
               if base_name == "shakunetsu" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if button == "LP" then
                     current_attack.max_hits = 1
                  elseif button == "MP" then
                     current_attack.max_hits = 2
                  elseif button == "HP" then
                     current_attack.max_hits = 3
                  end
               end
               if base_name == "goshoryuken" then
                  if button == "LP" then
                     current_attack.max_hits = 1
                  elseif button == "MP" then
                     current_attack.max_hits = 2
                  elseif button == "HP" then
                     current_attack.max_hits = 3
                  end
               end
               if base_name == "tatsumaki" then
                  if button == "LK" then
                     current_attack.max_hits = 2
                     current_attack.dummy_offset_list = {{80, 0}, {-70, 0}}
                  elseif button == "MK" then
                     current_attack.max_hits = 5
                     current_attack.dummy_offset_list = {{80, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}}
                  elseif button == "HK" then
                     current_attack.max_hits = 9
                     current_attack.dummy_offset_list = {
                        {80, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}, {80, 0}, {-70, 0}
                     }
                  end
               end
               if base_name == "tatsumaki_air" then
                  if button == "LK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-60, 0}, {80, 0}, {-60, 0}}
                     current_attack.max_hits = 2
                  elseif button == "MK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {{80, 0}, {-60, 0}, {80, 0}, {-60, 0}}
                     current_attack.max_hits = 4
                  elseif button == "HK" then
                     current_attack.player_offset_y = -20
                     current_attack.dummy_offset_list = {
                        {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}, {80, 0}, {-60, 0}
                     }
                     current_attack.max_hits = 8
                     current_attack.land_after = 150
                  end
                  if rec.recording_options.hit_type == "block" then
                     Queue_Command(gamestate.frame_number + 10, write_memory.clear_motion_data, {player})
                  end
               end
               if base_name == "asura_forward" or base_name == "asura_backward" then
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
            end

            if player.char_str == "twelve" then
               if base_name == "ndl" then
                  current_attack.is_projectile = true
                  if button == "MP" then
                     rec.dummy_offset_x = 150
                  elseif button == "HP" then
                     rec.dummy_offset_x = 210
                     Queue_Command(gamestate.frame_number + 10, write_memory.write_pos,
                                   {player, current_attack.reset_pos_x - 80, 0})
                     Queue_Command(gamestate.frame_number + 10, write_memory.set_screen_pos,
                                   {current_attack.reset_pos_x, 0})
                  elseif button == "EXP" then
                     rec.dummy_offset_x = 190
                     current_attack.max_hits = 2
                  end
               end
               if base_name == "axe" then
                  rec.dummy_offset_x = 80
                  local n = 25
                  if button == "LP" then
                     current_attack.max_hits = 9
                  elseif button == "MP" then
                     current_attack.max_hits = 9
                  elseif button == "HP" then
                     n = 30
                     current_attack.max_hits = 12
                  elseif button == "EXP" then
                     n = 20
                     current_attack.max_hits = 6
                  end
                  if rec.recording_options.hit_type == "block" then
                     current_attack.max_hits = 2
                     if button ~= "LP" then current_attack.max_hits = 3 end
                  end

                  for i = 1, n do
                     table.insert(sequence, {})
                     if button == "EXP" then
                        table.insert(sequence, {"LP", "MP"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
               end
               if base_name == "axe_air" then
                  rec.dummy_offset_x = 80
                  current_attack.player_offset_y = 100
                  local n = 25
                  for i = 1, n do
                     table.insert(sequence, {})
                     if button == "EXP" then
                        table.insert(sequence, {"LP", "MP"})
                     else
                        table.insert(sequence, {button})
                     end
                  end
                  current_attack.max_hits = 3
                  current_attack.player_offset_y = -20
                  current_attack.land_after = 150
                  if rec.recording_options.hit_type == "block" then
                     Queue_Command(gamestate.frame_number + 10, write_memory.clear_motion_data, {player})
                  end
               end
               if base_name == "dra" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 100
                  if button == "HK" then
                     rec.dummy_offset_x = 120
                  elseif button == "EXK" then
                     rec.dummy_offset_x = 120
                     rec.recording_options.infinite_loop = true
                     current_attack.max_hits = 2
                  end
               end
            end

            if player.char_str == "urien" then
               if base_name == "metallic_sphere" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if button == "HP" then
                     if rec.recording_options.hit_type == "block" then
                        current_attack.projectile_offset = {0, -50}
                     end
                  end
                  if button == "EXP" then current_attack.max_hits = 2 end
               end
               if base_name == "chariot_tackle" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 100
                  if button == "EXK" then current_attack.max_hits = 2 end
               end
               if base_name == "violence_kneedrop" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 80
                  if button == "EXK" then
                     current_attack.hits_appear_after_block = true
                     current_attack.max_hits = 2
                     rec.block_max_hits = 1
                  end
               end
               if base_name == "dangerous_headbutt" then
                  rec.recording_options.record_pushboxes = true
                  rec.dummy_offset_x = 80
                  if button == "EXP" then current_attack.max_hits = 2 end
               end
            end

            if player.char_str == "yang" then
               if base_name == "tourouzan" then
                  rec.dummy_offset_x = 100
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "tourouzan_2" or base_name == "tourouzan_3" or base_name == "tourouzan_4" or base_name ==
                   "tourouzan_5" then
                  current_attack.optional_anim = {1}
                  current_attack.max_hits = 2
                  local n = 4
                  if button == "EXP" then n = 10 end
                  if rec.recording_options.hit_type == "block" then n = 25 end
                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"down"})
                  table.insert(sequence, {"down", "forward"})
                  table.insert(sequence, {"forward"})
                  if button == "EXP" then
                     table.insert(sequence, {"LP", "MP"})
                  else
                     table.insert(sequence, {button})
                  end
                  if base_name == "tourouzan_2" then
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "tourouzan_3" or base_name == "tourouzan_4" or base_name == "tourouzan_5" then
                  current_attack.optional_anim = {1, 1}
                  current_attack.max_hits = 3
                  local n = 25
                  if button == "EXP" then n = 8 end
                  if rec.recording_options.hit_type == "block" then n = 14 end
                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"down"})
                  table.insert(sequence, {"down", "forward"})
                  table.insert(sequence, {"forward"})
                  if button == "EXP" then
                     table.insert(sequence, {"LP", "MP"})
                  else
                     table.insert(sequence, {button})
                  end
                  if base_name == "tourouzan_3" and button == "EXP" then
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "tourouzan_4" or base_name == "tourouzan_5" then
                  current_attack.optional_anim = {1, 1, 1}
                  current_attack.max_hits = 4
                  local n = 2
                  if button == "EXP" then n = 8 end
                  if rec.recording_options.hit_type == "block" then n = 25 end
                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"down"})
                  table.insert(sequence, {"down", "forward"})
                  table.insert(sequence, {"forward"})
                  if button == "EXP" then
                     table.insert(sequence, {"LP", "MP"})
                  else
                     table.insert(sequence, {button})
                  end

                  if base_name == "tourouzan_4" and button == "EXP" then
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "tourouzan_5" then
                  current_attack.optional_anim = {1, 1, 1, 1}
                  current_attack.max_hits = 5
                  local n = 2
                  if button == "EXP" then n = 9 end
                  if rec.recording_options.hit_type == "block" then n = 25 end
                  for i = 1, n do table.insert(sequence, {}) end
                  table.insert(sequence, {"down"})
                  table.insert(sequence, {"down", "forward"})
                  table.insert(sequence, {"forward"})
                  if button == "EXP" then
                     table.insert(sequence, {"LP", "MP"})
                  else
                     table.insert(sequence, {button})
                  end
               end
               if base_name == "senkyuutai" then
                  current_attack.reset_pos_x = 150
                  current_attack.max_hits = 2
                  if button == "EXK" then current_attack.max_hits = 3 end
               end
               if base_name == "kaihou" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 200
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
               if base_name == "byakko" then
                  current_attack.name = base_name
                  if button == "EXK" then current_attack.name = base_name .. button end
                  rec.dummy_offset_x = 100
                  if button == "EXP" then
                     current_attack.max_hits = 0
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "zenpou" then
                  rec.dummy_offset_x = 72
                  current_attack.throw = true
               end
            end

            if player.char_str == "yun" then
               if base_name == "zesshou" then
                  current_attack.reset_pos_x = 150
                  rec.dummy_offset_x = 100
                  if button == "EXP" then current_attack.max_hits = 2 end
                  if rec.recording_geneijin then
                     if button == "HP" then
                        current_attack.name = "zesshou"
                        current_attack.max_hits = 3
                     else
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "tetsuzan" then
                  current_attack.reset_pos_x = 150
                  if button == "EXP" then current_attack.max_hits = 2 end
                  if rec.recording_geneijin then
                     if button ~= "EXP" then
                        current_attack.max_hits = 2
                     else
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "nishoukyaku" then
                  if rec.recording_geneijin then
                     current_attack.name = base_name
                     if button == "LK" then
                        current_attack.max_hits = 2
                     else
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  else
                     current_attack.max_hits = 1
                     if rec.recording_options.hit_type == "block" then
                        Queue_Command(gamestate.frame_number + 38, write_memory.write_pos,
                                      {dummy, current_attack.reset_pos_x + 150, 0})
                     end
                  end
               end
               if base_name == "kobokushi" then
                  current_attack.name = base_name
                  if button == "EXK" then current_attack.name = base_name .. button end
                  if button == "EXP" then
                     current_attack.max_hits = 0
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               end
               if base_name == "zenpou" then current_attack.throw = true end
            end

            current_attack.sequence = sequence

         elseif rec.current_attack_category.name == "supers" then

            current_attack = tools.deepcopy(rec.supers[rec.i_attacks])
            local base_name = current_attack.name
            local button = current_attack.button
            if button then current_attack.name = current_attack.name .. "_" .. button end
            current_attack.base_name = base_name

            rec.dummy_offset_x = close_dist
            rec.dummy_offset_y = 0

            current_attack.reset_pos_x = rec.reset_pos_x

            local sequence = current_attack.input

            current_attack.attack_start_frame = #sequence

            local i = 1
            while i <= #sequence do
               local j = 1
               while j <= #sequence[i] do
                  if sequence[i][j] == "button" then
                     if button == "EXP" then
                        table.remove(sequence[i], j)
                        table.insert(sequence[i], j, "LP")
                        table.insert(sequence[i], j, "MP")
                     elseif button == "EXK" then
                        table.remove(sequence[i], j)
                        table.insert(sequence[i], j, "LK")
                        table.insert(sequence[i], j, "MK")
                     else
                        table.remove(sequence[i], j)
                        table.insert(sequence[i], j, button)
                     end
                  end
                  j = j + 1
               end
               i = i + 1
            end
            if player.char_str == "alex" then
               if current_attack.move_type == "sa1" then
                  current_attack.throw = true
                  current_attack.confirm_animation = "63a4"
                  -- reverse
               elseif current_attack.move_type == "sa2" then
                  current_attack.block = {1, 1, 1, 1, 3}
                  current_attack.max_hits = 5
               elseif current_attack.move_type == "sa3" then
                  current_attack.throw = true
                  if button == "MP" then
                     current_attack.name = base_name
                     rec.dummy_offset_x = 150
                  end
                  if button ~= "MP" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
            elseif player.char_str == "chunli" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 20
               elseif current_attack.move_type == "sa2" then
                  rec.dummy_offset_x = 80
                  current_attack.reset_pos_x = 200
                  current_attack.max_hits = 17
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 3 -- 9
               end
            elseif player.char_str == "dudley" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 8 -- 11
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 8
                  rec.dummy_offset_x = 120
                  local n = 80
                  if rec.recording_options.hit_type == "block" then
                     rec.dummy_offset_x = 30
                     n = 140
                  end
                  for i = 1, n do
                     table.insert(sequence, {})
                     table.insert(sequence, {"LP"})
                  end
               elseif current_attack.move_type == "sa3" then
                  current_attack.name = base_name
                  rec.dummy_offset_x = 90
                  current_attack.max_hits = 5
               end
            elseif player.char_str == "elena" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 7
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 10
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
               end
            elseif player.char_str == "gill" then
               if current_attack.move_type == "sa1" then
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
                  current_attack.max_hits = 0
                  rec.dummy_offset_x = 90
                  settings.training.life_mode = 1
                  Queue_Command(gamestate.frame_number + 11, memory.writebyte, {player.addresses.life, 0})
                  inputs.queue_input_sequence(dummy, {{"HP"}})
               elseif current_attack.move_type == "sa2" then
                  rec.dummy_offset_x = 100
                  current_attack.is_projectile = true
                  current_attack.max_hits = 16
                  if rec.recording_options.hit_type == "block" then
                     rec.dummy_offset_x = 150
                     current_attack.home_projectiles = true -- meteor swarm has randomness
                  end
               elseif current_attack.move_type == "sa3" then
                  rec.dummy_offset_x = 120
                  current_attack.max_hits = 17
               end
            elseif player.char_str == "gouki" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 6
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 7
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 3 -- 12
               elseif current_attack.move_type == "sgs" then
                  current_attack.throw = true
                  table.insert(sequence, 1, {"down", "HK"})
                  state = "waiting_for_sgs"
                  Queue_Command(gamestate.frame_number + 8, function() state = "wait_for_initial_anim" end)
               elseif current_attack.move_type == "kkz" then
                  current_attack.max_hits = 1 -- 12
               end
            elseif player.char_str == "hugo" then
               if current_attack.move_type == "sa1" then
                  current_attack.throw = true
                  current_attack.confirm_animation = "0d8c"
               elseif current_attack.move_type == "sa2" then
                  current_attack.throw = true
                  current_attack.reset_pos_x = 150
                  if current_attack.button ~= "HK" then
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
                  current_attack.name = "megaton_press"
                  if rec.recording_options.hit_type == "block" then rec.dummy_offset_y = 100 end
               elseif current_attack.move_type == "sa3" then
                  current_attack.reset_pos_x = 150
                  current_attack.max_hits = 5
                  if current_attack.name == "hammer_mountain_miss" then
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                     current_attack.max_hits = 0
                     local n = 100
                     for i = 1, n do table.insert(sequence, {"LP"}) end
                  end
               end
            elseif player.char_str == "ibuki" then
               if current_attack.move_type == "sa1" then
                  current_attack.is_projectile = true
                  current_attack.max_hits = 20
                  current_attack.attack_start_frame = #sequence + 6
                  local n = 70
                  if rec.recording_options.hit_type == "block" then
                     n = 350
                     current_attack.player_offset_y = 80
                  end
                  for i = 1, n do
                     table.insert(sequence, {})
                     table.insert(sequence, {button})
                  end
                  if button == "MP" then
                     current_attack.offset_x = 30
                  elseif button == "HP" then
                     current_attack.player_offset_y = 40
                     current_attack.offset_x = 60
                  end
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 13
                  current_attack.offset_x = 70
               elseif current_attack.move_type == "sa3" then
                  current_attack.is_projectile = true
                  if rec.recording_options.hit_type == "block" then
                     current_attack.home_projectiles = true
                     rec.recording_options.hit_type = "miss"
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
                  current_attack.max_hits = 3
                  current_attack.reset_pos_x = 200
                  current_attack.block = {2, 2, 2}
               end
            elseif player.char_str == "ken" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 11 -- 12
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 3 -- 15
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 5 -- 9
               end
            elseif player.char_str == "makoto" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 1
               elseif current_attack.move_type == "sa2" then
                  -- current_attack.name = base_name
                  current_attack.max_hits = 4
                  current_attack.do_not_fix_screen = true
                  current_attack.hits_appear_after_block = true
                  rec.block_max_hits = 1
                  -- if button ~= "MK" then
                  --   rec.i_attacks = rec.i_attacks + 1
                  --   state = "queue_move"
                  --   return
                  -- end
                  if button == "LK" then
                     Queue_Command(gamestate.frame_number + 15, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x - 40, 0})
                  elseif button == "MK" then
                     Queue_Command(gamestate.frame_number + 15, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x, 0})
                  elseif button == "HK" then
                     Queue_Command(gamestate.frame_number + 15, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + 50, 0})
                  end
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
               end
            elseif player.char_str == "necro" then
               if current_attack.move_type == "sa1" then
                  current_attack.reset_pos_x = 600
                  current_attack.max_hits = 13
                  local n = 60
                  if rec.recording_options.hit_type == "block" then
                     rec.dummy_offset_x = 30
                     n = 140
                  end
                  for i = 1, n do
                     table.insert(sequence, {})
                     table.insert(sequence, {"LP"})
                  end
               elseif current_attack.move_type == "sa2" then
                  current_attack.throw = true
               elseif current_attack.move_type == "sa3" then

                  rec.dummy_offset_x = 150
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  current_attack.reset_pos_x = 160
                  current_attack.max_hits = 3
                  current_attack.block = {2, 2, 2}
               end
            elseif player.char_str == "oro" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 0
                  if current_attack.name == "kishinriki_activation" then
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        rec.i_recording_hit_types = 1
                        state = "queue_move"
                        return
                     end
                  else
                     current_attack.throw = true
                     if button == "LP" then
                        current_attack.name = "kishinriki"
                        if rec.recording_options.hit_type == "block" then
                           Queue_Command(gamestate.frame_number + 10, memory.writebyte, {player.addresses.gauge, 1})
                        end
                     elseif button == "EXP" then
                        Queue_Command(gamestate.frame_number + 1, memory.writebyte, {player.addresses.gauge, 1})
                     else
                        rec.i_recording_hit_types = 1
                        rec.i_attacks = rec.i_attacks + 1
                        state = "queue_move"
                        return
                     end
                  end
               elseif current_attack.move_type == "sa2" then
                  current_attack.is_projectile = true
                  current_attack.max_hits = 4
                  current_attack.reset_pos_x = 200
                  rec.dummy_offset_x = 150
                  if button == "EXP" then current_attack.max_hits = 12 end
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
                  rec.recording_options.ignore_projectiles = true
                  if button == "LP" then
                     current_attack.name = "tenguishi"
                  elseif button == "EXP" then
                  else
                     rec.i_recording_hit_types = 1
                     rec.i_attacks = rec.i_attacks + 1
                     state = "queue_move"
                     return
                  end
               end
            elseif player.char_str == "q" then
               if current_attack.move_type == "sa1" then
                  current_attack.reset_pos_x = 200
                  current_attack.max_hits = 5
                  current_attack.block = {1, 1, 1, 2, 1}
               elseif current_attack.move_type == "sa2" then
                  rec.dummy_offset_x = 90
                  current_attack.max_hits = 1
                  current_attack.hits_appear_after_parry = true
                  rec.block_max_hits = 1
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
                  if current_attack.name == "total_destruction_activation" then
                     if rec.recording_options.hit_type == "block" then
                        rec.i_attacks = rec.i_attacks + 1
                        rec.i_recording_hit_types = 1
                        state = "queue_move"
                        return
                     end
                  elseif current_attack.name == "total_destruction_attack" then
                     current_attack.max_hits = 1
                     Queue_Command(gamestate.frame_number + 50, memory.writebyte,
                                   {player.addresses.gauge, player.max_meter_gauge})
                  elseif current_attack.name == "total_destruction_throw" then
                     current_attack.throw = true
                  end
               end
            elseif player.char_str == "remy" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 7
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  rec.dummy_offset_x = 150
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 10
                  rec.dummy_offset_x = 90
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 7
                  current_attack.hits_appear_after_hit = true
                  -- rec.block_max_hits = 1
                  rec.dummy_offset_x = 90
                  inputs.queue_input_sequence(dummy, {{}, {}, {}, {}, {}, {}, {"down", "LP"}})
               end
            elseif player.char_str == "ryu" then
               if current_attack.move_type == "sa1" then
                  rec.dummy_offset_x = 150
                  current_attack.max_hits = 5
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 6
               elseif current_attack.move_type == "sa3" then
                  rec.dummy_offset_x = 150
                  if current_attack.name == "denjin_hadouken" then
                     current_attack.max_hits = 1
                  elseif current_attack.name == "denjin_hadouken_2" then
                     current_attack.max_hits = 2
                  elseif current_attack.name == "denjin_hadouken_3" then
                     current_attack.max_hits = 3
                  elseif current_attack.name == "denjin_hadouken_4" then
                     current_attack.max_hits = 4
                  elseif current_attack.name == "denjin_hadouken_5" then
                     current_attack.max_hits = 5
                  end
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     rec.i_recording_hit_types = 1
                     state = "queue_move"
                     return
                  end
               end
            elseif player.char_str == "sean" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 1
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  rec.dummy_offset_x = 150
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 14
                  local n = 30
                  if rec.recording_options.hit_type == "block" then
                     rec.dummy_offset_x = 30
                     n = 140
                  end
                  for i = 1, n do
                     table.insert(sequence, {"LP"})
                     table.insert(sequence, {"MP"})
                     table.insert(sequence, {"HP"})
                  end
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 1
                  current_attack.block = {2}
               end
            elseif player.char_str == "shingouki" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 7
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  rec.dummy_offset_x = 150
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 11
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
               elseif current_attack.move_type == "sgs" then
                  current_attack.throw = true
                  table.insert(sequence, 1, {"down", "HK"})
                  state = "waiting_for_sgs"
                  Queue_Command(gamestate.frame_number + 8, function() state = "wait_for_initial_anim" end)
               end
            elseif player.char_str == "twelve" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 5
                  rec.dummy_offset_x = 180
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
                  if rec.recording_options.hit_type == "block" then
                     rec.i_attacks = rec.i_attacks + 1
                     rec.i_recording_hit_types = 1
                     state = "queue_move"
                     return
                  end
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 1
                  current_attack.player_offset_y = -20
                  rec.dummy_offset_x = 150
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
                  Queue_Command(gamestate.frame_number + 50, memory.writebyte, {player.addresses.gauge, 1})
               end
            elseif player.char_str == "urien" then
               if current_attack.move_type == "sa1" then
                  current_attack.reset_pos_x = 110
                  current_attack.offset_x = 30
                  current_attack.max_hits = 5
               elseif current_attack.move_type == "sa2" then
                  current_attack.max_hits = 5
                  rec.dummy_offset_x = 150
                  current_attack.is_projectile = true
                  current_attack.queue_track_projectile = true
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 6
                  current_attack.is_projectile = true
                  current_attack.end_recording_after_proectile = true
                  if button == "MP" then
                     rec.dummy_offset_x = 120
                  elseif button == "HP" then
                     rec.dummy_offset_x = 210
                  elseif button == "EXP" then
                  end
               end
            elseif player.char_str == "yang" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 1
               elseif current_attack.move_type == "sa2" then
                  current_attack.reset_pos_x = 120
                  current_attack.max_hits = 4
                  if rec.recording_options.hit_type == "miss" then
                     Queue_Command(gamestate.frame_number + 90, function() rec.dummy_offset_x = 50 end)
                     Queue_Command(gamestate.frame_number + 91, function()
                        rec.dummy_offset_x = close_dist
                     end)
                  end
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
                  rec.recording_options.ignore_projectiles = true
               end
            elseif player.char_str == "yun" then
               if current_attack.move_type == "sa1" then
                  current_attack.max_hits = 3
                  current_attack.hits_appear_after_parry = true
                  rec.block_max_hits = 2
               elseif current_attack.move_type == "sa2" then
                  current_attack.hits_appear_after_parry = true
                  current_attack.max_hits = 6
                  rec.block_max_hits = 2
               elseif current_attack.move_type == "sa3" then
                  current_attack.max_hits = 0
                  if rec.recording_options.hit_type == "block" then
                     rec.recording_geneijin = true
                     rec.i_recording_hit_types = 1
                     rec.i_attacks = 1
                     rec.i_attack_categories = 1
                     rec.last_category = 6
                     state = "queue_move"
                     return
                  end
               end
            end

            if rec.recording_options.hit_type == "block" then
               if current_attack.max_hits == 0 and not current_attack.throw then
                  rec.i_attacks = rec.i_attacks + 1
                  rec.i_recording_hit_types = 1
                  state = "queue_move"
                  return
               end
            end

            current_attack.sequence = sequence
         else
            rec.recording = false
            setup = false
            state = "off"
            write_memory.make_invulnerable(dummy, false)
            return
         end

         if rec.current_attack_category.name == "supers" then
            local current_sa = 1
            if current_attack.move_type == "sgs" then
               current_sa = 4
            elseif current_attack.move_type == "kkz" then
               current_sa = 5
            else
               current_sa = tonumber(string.sub(current_attack.move_type, 3, 3))
            end
            if player.selected_sa ~= current_sa and
                not (current_attack.move_type == "sgs" or current_attack.move_type == "kkz") and
                not (player.char_str == "gill") then
               state = "wait_for_match_start"
               Register_After_Load_State(character_select.force_select_character,
                                         {player.id, player.char_str, current_sa, "LP"})
               Register_After_Load_State(character_select.force_select_character, {dummy.id, "urien", 1, "MP"})
               character_select.start_character_select_sequence()
               return
            end
         end

         if not rec.recording_options.target_combo then
            name = current_attack.name or tools.input_to_text(current_attack.sequence)[1]
            if rec.recording_geneijin then
               name = (current_attack.name or tools.input_to_text(current_attack.sequence)[1]) .. "_geneijin"
            end
            if current_attack.offset_x then rec.dummy_offset_x = rec.dummy_offset_x + current_attack.offset_x end

            current_attack.player_offset_y = current_attack.player_offset_y or 0

            if current_attack.self_chain and current_attack.block then
               table.insert(current_attack.block, current_attack.block[1])
            end
            rec.block_pattern = current_attack.block

            if current_attack.queue_track_projectile and not current_attack.queued_track_projectile then
               rec.current_attack_category.list[rec.i_attacks].queued_track_projectile = true
               rec.current_attack_category.list[rec.i_attacks].record_projectile_emit_animation = true
               local attack = tools.deepcopy(current_attack)
               attack.name = attack.base_name
               attack.track_projectile = true
               attack.queued_track_projectile = true
               table.insert(rec.current_attack_category.list, rec.i_attacks + 1, attack)
               current_attack.record_projectile_emit_animation = true
            end

            if current_attack.record_projectile_emit_animation or current_attack.track_projectile then
               current_attack.reset_pos_x = 150
            end

            if current_attack.record_projectile_emit_animation then
               if rec.recording_options.hit_type == "miss" then
                  rec.recording_options.ignore_projectiles = true
               else
                  if rec.current_attack_category.name == "supers" then rec.i_recording_hit_types = 1 end
                  rec.i_attacks = rec.i_attacks + 1
                  state = "queue_move"
                  return
               end
            end

            if rec.recording_options.hit_type == "miss" then
               if current_attack.max_hits and
                   not (current_attack.hits_appear_after_block or current_attack.hits_appear_after_hit) then
                  rec.block_max_hits = rec.block_max_hits or 0
                  rec.block_until = rec.block_until or 0
               end
               if current_attack.throw then
                  rec.block_max_hits = 0
                  rec.block_until = 0
               end
               if current_attack.self_chain then
                  current_attack.max_hits = 2
                  rec.block_max_hits = current_attack.max_hits - 1
               end
            else
               rec.block_max_hits = 1
               rec.block_until = 1
               if current_attack.max_hits then
                  rec.block_max_hits = current_attack.max_hits
                  rec.block_until = rec.block_max_hits
               end
               if current_attack.self_chain then
                  current_attack.max_hits = 1
                  rec.block_until = current_attack.max_hits
               end
            end
            if current_attack.hits_appear_after_block or current_attack.hits_appear_after_hit or
                current_attack.hits_appear_after_parry then
               rec.recording_options.record_frames_after_hit = true
            end

            if current_attack.ignore_next_anim then rec.recording_options.ignore_next_anim = true end

            if current_attack.air or current_attack.air_dash then
               rec.recording_options.air = true
               local sequence = {{"up", "forward"}, {"up", "forward"}, {}, {}, {}, {}}
               if current_attack.jump_dir == "back" then
                  sequence = {{"up", "back"}, {"up", "back"}, {}, {}, {}, {}}
               elseif current_attack.jump_dir == "neutral" then
                  sequence = {{"up"}, {"up"}, {}, {}, {}, {}}
               end
               if (is_slow_jumper(player.char_str)) then
                  table.insert(sequence, #sequence, {})
               elseif is_really_slow_jumper(player.char_str) then
                  table.insert(sequence, #sequence, {})
                  table.insert(sequence, #sequence, {})
               end

               if current_attack.air_dash then
                  table.insert(sequence, #sequence, {"forward"})
                  for i = 1, 14 do table.insert(sequence, #sequence, {}) end
               end

               for i = 1, #current_attack.sequence do table.insert(sequence, current_attack.sequence[i]) end
               current_attack.sequence = sequence

               current_attack.attack_start_frame = current_attack.attack_start_frame or #sequence

               inputs.queue_input_sequence(player, current_attack.sequence)

               if current_attack.name == "drill_LK" then
                  rec.recording_options.infinite_loop = true
                  if rec.recording_options.hit_type == "miss" then
                     rec.dummy_offset_x = 200
                     write_memory.write_pos(player, 150, 300)
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 300)
                     rec.block_max_hits = 0
                  else
                     rec.dummy_offset_x = 350
                     write_memory.write_pos(player, 150, 200)
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0)
                     Queue_Command(gamestate.frame_number + 50, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0})
                     rec.dummy_offset_x = 100
                  end
                  Queue_Command(gamestate.frame_number + #current_attack.sequence, write_memory.clear_motion_data,
                                {player})
               elseif current_attack.name == "drill_MK" then
                  rec.recording_options.infinite_loop = true
                  if rec.recording_options.hit_type == "miss" then
                     rec.dummy_offset_x = 150
                     write_memory.write_pos(player, 150, 300)
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 300)
                     rec.block_max_hits = 0
                  else
                     rec.dummy_offset_x = 200
                     write_memory.write_pos(player, 150, 200)
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0)
                     rec.dummy_offset_x = 100
                  end
                  Queue_Command(gamestate.frame_number + #current_attack.sequence, write_memory.clear_motion_data,
                                {player})
               elseif current_attack.name == "drill_HK" then
                  rec.recording_options.infinite_loop = true
                  if rec.recording_options.hit_type == "miss" then
                     rec.dummy_offset_x = 150
                     write_memory.write_pos(player, 150, 300)
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 300)
                     rec.block_max_hits = 0
                  else
                     rec.dummy_offset_x = 0
                     write_memory.write_pos(player, 150, 200)
                     Queue_Command(gamestate.frame_number + 1, write_memory.write_pos,
                                   {dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0})
                     rec.dummy_offset_x = 100
                  end
                  Queue_Command(gamestate.frame_number + #current_attack.sequence, write_memory.clear_motion_data,
                                {player})
               else
                  if current_attack.land_after then
                     if current_attack.land_after > 0 then
                        Queue_Command(gamestate.frame_number + current_attack.land_after, land_player, {player})
                     end
                  else
                     Queue_Command(gamestate.frame_number + #current_attack.sequence + 100, land_player, {player})
                  end
                  Queue_Command(gamestate.frame_number + #current_attack.sequence, write_memory.clear_motion_data,
                                {player})

                  if rec.recording_options.hit_type == "miss" then
                     write_memory.write_pos(player, current_attack.reset_pos_x, 0)
                     Queue_Command(gamestate.frame_number + current_attack.attack_start_frame, write_memory.write_pos, {
                        player, current_attack.reset_pos_x, rec.default_air_miss_height + current_attack.player_offset_y
                     })
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 200)
                  else
                     write_memory.write_pos(player, current_attack.reset_pos_x, 0)
                     Queue_Command(gamestate.frame_number + current_attack.attack_start_frame, write_memory.write_pos, {
                        player, current_attack.reset_pos_x,
                        rec.default_air_block_height + current_attack.player_offset_y
                     })
                     write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x, 0)
                  end
               end
            else
               current_attack.attack_start_frame = current_attack.attack_start_frame or #current_attack.sequence
               write_memory.write_pos(player, current_attack.reset_pos_x, 0)
               write_memory.write_pos(dummy, current_attack.reset_pos_x + rec.dummy_offset_x,
                                      player.pos_y + rec.dummy_offset_y)
               inputs.queue_input_sequence(player, current_attack.sequence)
               Queue_Command(gamestate.frame_number + current_attack.attack_start_frame, write_memory.clear_motion_data,
                             {player})
            end

            if current_attack.self_chain then
               write_memory.make_invulnerable(dummy, false)
               rec.recording_options.self_chain = true
            end

            memory.writebyte(dummy.addresses.stun_bar_char, 0)
            memory.writebyte(dummy.addresses.life, 160)
            write_memory.clear_motion_data(player)
            write_memory.fix_screen_pos(player, dummy, gamestate.stage)
            print(name)

            if rec.overwrite and rec.first_record then
               rec.recording_options.clear_frame_data = true
               rec.first_record = false
            end
         end
      end

      if setup then

         -- print(state,rec.recording_options.hit_type, rec.received_hits, rec.block_until, rec.block_max_hits, rec.i_attacks)
         if state == "update_hit_state" then
            if rec.received_hits >= rec.block_until then
               if rec.block_until < rec.block_max_hits then
                  rec.block_until = rec.block_until + 1
               else
                  if rec.current_attack_category.name == "target_combos" or current_attack.self_chain then
                     rec.block_until = 0
                  else
                     rec.received_hits = 0
                     rec.block_until = 0
                  end
                  if not (rec.current_attack_category.name == "supers") then
                     rec.i_attacks = rec.i_attacks + 1
                     rec.first_record = true
                  else
                     if rec.i_recording_hit_types < #rec.recording_hit_types then
                        rec.i_recording_hit_types = rec.i_recording_hit_types + 1
                     else
                        rec.i_recording_hit_types = 1
                        rec.i_attacks = rec.i_attacks + 1
                        rec.first_record = true
                     end
                  end
               end
            end
            state = "queue_move"
         end

         if rec.recording_options.hit_type == "miss" then
            if not (rec.recording_options.target_combo or current_attack.self_chain or
                current_attack.hits_appear_after_block or current_attack.hits_appear_after_hit or
                current_attack.hits_appear_after_parry) then
               write_memory.make_invulnerable(dummy, true)
               write_memory.write_pos(dummy, player.pos_x + rec.dummy_offset_x, player.pos_y + rec.dummy_offset_y)
            else
               if rec.received_hits < rec.block_until then
                  write_memory.make_invulnerable(dummy, false)
                  if current_attack.hits_appear_after_parry then
                     memory.writebyte(dummy.addresses.parry_forward_validity_time, 0xA)
                     memory.writebyte(dummy.addresses.parry_down_validity_time, 0xA)
                     memory.writebyte(dummy.addresses.parry_air_validity_time, 0x7)
                     memory.writebyte(dummy.addresses.parry_antiair_validity_time, 0x5)
                  end
               else
                  write_memory.make_invulnerable(dummy, true)
                  write_memory.write_pos(dummy, player.pos_x + rec.dummy_offset_x, player.pos_y + rec.dummy_offset_y)
               end
            end

            if state == "new_recording" then state = "recording" end
         elseif rec.recording_options.hit_type == "block" then
            if not (rec.recording_options.target_combo or current_attack.self_chain) then
               write_memory.make_invulnerable(dummy, false)
               if state == "new_recording" then
                  rec.received_hits = 0
                  state = "recording"
               end
               if current_attack.is_projectile then
                  if rec.current_projectile and rec.current_projectile.expired and not rec.recording_pushback then
                     rec.current_projectile = nil
                     rec.freeze_player_for_projectile = false
                     if current_attack.end_recording_after_proectile then
                        end_recording(player, projectiles, name)
                     end
                  end
                  for _, obj in pairs(projectiles) do
                     if not rec.current_projectile then
                        rec.current_projectile = obj
                        if current_attack.projectile_offset then
                           write_memory.write_pos(obj, obj.pos_x + current_attack.projectile_offset[1],
                                                  obj.pos_y + current_attack.projectile_offset[2])
                        end
                     end
                     if current_attack.home_projectiles then
                        local dx = dummy.pos_x - obj.pos_x
                        local dy = dummy.pos_y - obj.pos_y
                        local dist = math.sqrt(dx * dx + dy * dy)
                        local vx = dx / dist * 16
                        local vy = dy / dist * 16
                        write_memory.write_velocity(obj, vx, vy)
                     end
                     if obj ~= rec.current_projectile then write_memory.set_freeze(obj, 2) end
                  end
                  if rec.current_projectile then
                     for _, box in pairs(rec.current_projectile.boxes) do
                        if tools.convert_box_types[box[1]] == "attack" then
                           rec.freeze_player_for_projectile = true
                        end
                     end
                  end
                  if rec.freeze_player_for_projectile then
                     if player.animation == "d17c" then -- gill meteor swarm
                        if rec.current_projectile then write_memory.set_freeze(player, 255) end
                     else
                        write_memory.set_freeze(player, 2)
                     end
                  end
                  rec.recording_options.is_projectile = true
               end
            end
         end

         if dummy.has_just_blocked or dummy.has_just_been_hit or dummy.received_connection then
            rec.received_hits = rec.received_hits + 1
         end

         if current_attack.dummy_offset_list then
            local index = rec.received_hits + 1
            if index <= #current_attack.dummy_offset_list then
               rec.dummy_offset_x = current_attack.dummy_offset_list[index][1]
               rec.dummy_offset_y = current_attack.dummy_offset_list[index][2]
            end
         end

         if current_attack.optional_anim and rec.received_hits + 1 <= #current_attack.optional_anim and
             current_attack.optional_anim[rec.received_hits + 1] == 1 then
            rec.recording_options.optional_anim = true
         else
            rec.recording_options.optional_anim = false
         end

         if dummy.has_just_blocked or dummy.has_just_been_hit then
            if rec.recording_options.target_combo then
               if current_attack.cancel_on_whiff or
                   (current_attack.cancel_on_hit and current_attack.cancel_on_hit[rec.received_hits] == 1) or
                   current_attack.cancel_on_hit == nil then
                  if rec.tc_hit_index <= #current_attack.sequence then
                     if rec.recording_options.hit_type == "miss" then
                        rec.tc_hit_index = rec.tc_hit_index + 1
                        write_memory.set_freeze(player, 1)
                        local delay = 0
                        if current_attack.delay then
                           delay = current_attack.delay[rec.tc_hit_index]
                        end
                        Queue_Command(gamestate.frame_number + 1 + delay, inputs.queue_input_sequence,
                                      {player, {current_attack.sequence[rec.tc_hit_index]}})
                     end
                  end
               end
            end
            if current_attack.self_chain and rec.received_hits < current_attack.max_hits then
               local delay = 0
               if current_attack.delay then delay = current_attack.delay[1] end
               write_memory.set_freeze(player, 1)
               player.animation_action_count = 0
               Queue_Command(gamestate.frame_number + 1 + delay, inputs.queue_input_sequence,
                             {player, current_attack.sequence})
            end
         end

         if dummy.has_just_blocked or dummy.has_just_been_hit or dummy.received_connection then
            if (rec.recording_options.hit_type == "block" or rec.recording_options.hit_type == "hit") and
                not current_attack.throw and not (rec.block_pattern and rec.block_pattern[rec.received_hits] == 3) then
               rec.unfreeze_dummy = true
               state = "pause_for_data"
            end
         end
         if state == "resume_attack" then
            if not current_attack.is_projectile then
               if rec.unfreeze_player then
                  if player.animation == "dadc" then
                     write_memory.set_freeze(player, 0xFF)
                  else
                     write_memory.set_freeze(player, 1)
                  end
                  rec.unfreeze_player = false
               end

               if rec.recording_options.target_combo then
                  rec.tc_hit_index = rec.tc_hit_index + 1
                  if rec.tc_hit_index <= #current_attack.sequence then
                     local delay = 0
                     if current_attack.delay then delay = current_attack.delay[rec.tc_hit_index] end
                     Queue_Command(gamestate.frame_number + 1 + delay, inputs.queue_input_sequence,
                                   {player, {current_attack.sequence[rec.tc_hit_index]}})
                  end
               end
               if current_attack.self_chain and rec.received_hits < current_attack.max_hits then
                  local delay = 0
                  if current_attack.delay then delay = current_attack.delay[1] end
                  player.animation_action_count = 0
                  Queue_Command(gamestate.frame_number + 1 + delay, inputs.queue_input_sequence,
                                {player, current_attack.sequence})
               end
            else
               if rec.current_projectile then write_memory.set_freeze(rec.current_projectile, 1) end
            end
            state = "recording"
         end
         if player.previous_remaining_freeze_frames > 0 and player.remaining_freeze_frames -
             player.previous_remaining_freeze_frames == 1 then
            write_memory.set_freeze(player, 0xFF)
            if player.animation == "d17c" then write_memory.set_freeze(player, 1) end
            -- write_memory.set_freeze(player, 127)
            -- Queue_Command(gamestate.frame_number + 2, write_memory.set_freeze, {player, 1})
         end
         if rec.received_hits < rec.block_until then
            if rec.block_pattern then
               local index = math.min(rec.received_hits + 1, rec.block_max_hits)
               if rec.block_pattern[index] ~= 2 then
                  block_high(dummy)
               else
                  block_low(dummy)
               end
            else
               block_high(dummy)
            end
         end
         if state == "pause_for_data" then
            if not current_attack.is_projectile then
               if player.freeze_just_began then
                  if not rec.current_projectile then rec.recording_self_freeze = true end
                  rec.self_freeze = player.remaining_freeze_frames
                  if player.animation == "f50c" or player.animation == "4bf4" or player.animation == "a498" or
                      player.animation == "aa18" or player.animation == "af98" or
                      (player.animation == "b518" and player.action_count < 2) then
                     write_memory.set_freeze(player, 0xFF)
                     Queue_Command(gamestate.frame_number + 1, function() rec.self_freeze = 0xFF end)
                  else
                     Queue_Command(gamestate.frame_number + 1, write_memory.set_freeze,
                                   {player, math.min(2, rec.self_freeze)})
                  end
               else
                  rec.recording_self_freeze = false
                  write_memory.set_freeze(player, math.min(2, rec.self_freeze))
               end
            else
               if rec.current_projectile then write_memory.set_freeze(rec.current_projectile, 2) end
            end
            if dummy.freeze_just_began then
               rec.recording_opponent_freeze = true
            else
               rec.recording_opponent_freeze = false

               if dummy.remaining_freeze_frames > 0 and rec.unfreeze_dummy then
                  write_memory.set_freeze(dummy, 1)
                  rec.unfreeze_dummy = false
               end

               if dummy.remaining_freeze_frames - dummy.previous_remaining_freeze_frames == 1 then
                  write_memory.set_freeze(dummy, 0xFF)
               end

               if dummy.freeze_just_ended then
                  Queue_Command(gamestate.frame_number + 1, function() rec.recording_recovery = true end)
                  Queue_Command(gamestate.frame_number + 2, function() rec.recording_recovery = false end)
               end
               if dummy.movement_type == 1 and dummy.remaining_freeze_frames == 0 then
                  rec.begin_recording_pushback = true
                  Queue_Command(gamestate.frame_number + 1, function() rec.recording_pushback = true end)
               end
            end
         end
         if rec.begin_recording_pushback and dummy.movement_type == 0 then
            rec.begin_recording_pushback = false
            rec.recording_pushback = false
            write_memory.write_pos(dummy, player.pos_x + rec.dummy_offset_x, 0)
            write_memory.fix_screen_pos(player, dummy, gamestate.stage)
            rec.unfreeze_player = true
            state = "resume_attack"
         end
      end

      if dummy.is_stunned and dummy.stun_timer >= 0 then memory.writebyte(dummy.addresses.stun_timer, 0) end

      if rec.recording_geneijin then memory.writebyte(player.addresses.gauge, player.max_meter_gauge) end

      if not current_attack.do_not_fix_screen then write_memory.fix_screen_pos(player, dummy, gamestate.stage) end

      if current_attack.queue_track_projectile and not current_attack.record_projectile_emit_animation and
          rec.recording_options.hit_type == "miss" then
         if rec.current_projectile and rec.current_projectile.expired then rec.current_projectile = nil end
         for _, obj in pairs(projectiles) do if not rec.current_projectile then rec.current_projectile = obj end end
         if rec.current_projectile then
            write_memory.fix_screen_pos(rec.current_projectile, rec.current_projectile, gamestate.stage)
            if rec.current_projectile.pos_y > 100 and rec.current_projectile.pos_y < 280 then
               write_memory.write_pos_y(player, rec.current_projectile.pos_y)
               write_memory.write_pos_y(dummy, rec.current_projectile.pos_y)
               inputs.queue_input_sequence(player, {{"up"}})
               inputs.queue_input_sequence(dummy, {{"up"}})
            else
               write_memory.write_pos_y(player, 0)
               write_memory.write_pos_y(dummy, 0)
            end
         end
      end

      if rec.recording_options.hit_type == "miss" and
          require("src.modules.prediction").test_collision(dummy.pos_x, dummy.pos_y, dummy.flip_x, dummy.boxes, -- defender
                                                           player.pos_x, player.pos_y, player.flip_x, player.boxes, -- attacker
                                                           {{{"push"}, {"push"}}}) then
         print(">>overlapping push boxes<<")
      end

      record_framedata(player, projectiles, name)
   end
end

local i_record = 1
local i_characters = 1
local end_character = 21
local record_char_state = "start"
local char_list = tools.deepcopy(game_data.characters)
local char
table.sort(char_list)

local function record_all_characters(player, projectiles)
   if debug_settings.recording_framedata then
      debug_settings.show_debug_frames_display = true
      emu.speedmode("turbo")
      settings.training.blocking_mode = 1
      local dummy = player.other
      if record_char_state == "start" then
         frame_data["projectiles"] = {}
         record_char_state = "new_character"
      elseif record_char_state == "new_character" then
         if i_characters <= end_character then
            char = char_list[i_characters]
            rec.overwrite = false
            rec.first_record = true
            frame_data[char] = {}
            state = "start"
            setup = false
            rec.recording = false
            rec.i_attack_categories = 1
            rec.last_category = 7
            rec.i_recording_hit_types = 1
            rec.received_hits = 0
            rec.block_until = 0
            rec.block_max_hits = 0
            rec.recording_options.hit_type = "miss"
            Register_After_Load_State(character_select.force_select_character, {player.id, char, 1, "LP"})
            Register_After_Load_State(character_select.force_select_character, {dummy.id, "urien", 1, "MP"})
            character_select.start_character_select_sequence()
            record_char_state = "recording"
         else
            record_char_state = "finished"
         end
      elseif record_char_state == "recording" then
         if i_record == 1 then
            record_idle(player)
         elseif i_record == 2 then
            record_movement(player)
         elseif i_record == 3 then
            record_wakeups(player)
         elseif i_record == 4 then
            record_attacks(player, projectiles)
         elseif i_record == 5 then
            record_landing(player)
         end

         if state == "finished" then
            state = "start"
            setup = false
            rec.recording = false
            i_record = i_record + 1
            -- i_characters = 99
         end
         if i_record > 5 then
            i_record = 1
            i_characters = i_characters + 1
            record_char_state = "new_character"
            save_frame_data()
            -- make space in memory
            frame_data[char] = {}
         end
      elseif record_char_state == "finished" then
         save_frame_data()
         debug_settings.recording_framedata = false
         loading.frame_data_loaded = false -- debug
         record_char_state = "the_end"
      end
   end
end

local function update_framedata_recording(player, projectiles) record_all_characters(player, projectiles) end

local record_framedata = {
   save_frame_data = save_frame_data,
   span_frame_data = span_frame_data,
   update_framedata_recording = update_framedata_recording
}

setmetatable(record_framedata, {
   __index = function(_, key) if key == "state" then return state end end,

   __newindex = function(_, key, value)
      if key == "state" then
         state = value
      else
         rawset(record_framedata, key, value)
      end
   end
})

return record_framedata
