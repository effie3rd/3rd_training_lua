local _state = ""
local _setup = false
local normals = {}
local jumping_normals = {{{"LP"}},{{"MP"}},{{"HP"}},{{"LK"}},{{"MK"}},{{"HK"}},{{"LP"}},{{"MP"}},{{"HP"}},{{"LK"}},{{"MK"}},{{"HK"}},{{"LP"}},{{"MP"}},{{"HP"}},{{"LK"}},{{"MK"}},{{"HK"}}}
local normals_list = {
  alex = {
    {sequence={{"LP"}}, far=true, offset_x=-14, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, max_hits=2},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  chunli = {
    {sequence={{"LP"}}, far=true, offset_x=-14, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}, far=true},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}, block={2}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}}},
  dudley = {
    {sequence={{"LP"}}, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-14, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, offset_x=-14, block={2}, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  elena = {
    {sequence={{"LP"}}},
    {sequence={{"MP"}}, max_hits=2},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  gill = {
    {sequence={{"LP"}}, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, max_hits=2},
    {sequence={{"down","LK"}}, block={2}, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  gouki = {
    {sequence={{"LP"}}, far=true, offset_x=-16, self_chain=true},
    {sequence={{"MP"}}, far=true, offset_x=-10},
    {sequence={{"HP"}}, far=true, offset_x=-10},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}, far=true},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, offset_x=-24, block={2}, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  hugo = {
    {sequence={{"LP"}}, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, max_hits=2},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  ibuki = {
    {sequence={{"LP"}}, offset_x=-14, self_chain=true, delay={3}},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}, far=true},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}, far=true},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true, delay={4}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, offset_x=-24, block={2}, self_chain=true, delay={3}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  ken = {
    {sequence={{"LP"}}, far=true, offset_x=-16, self_chain=true},
    {sequence={{"MP"}}, far=true, offset_x=-10},
    {sequence={{"HP"}}, far=true, offset_x=-10},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, offset_x=-24, block={2}, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  makoto = {
    {sequence={{"LP"}}, offset_x=-38, self_chain=true, delay={3}},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-38, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, block={2}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}},
    {sequence={{"down","HK"}}}},
  necro = {
    {sequence={{"LP"}}},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  oro = {
    {sequence={{"LP"}}, far=true, offset_x=-12},
    {sequence={{"MP"}}, far=true},
    {sequence={{"HP"}}, max_hits=2},
    {sequence={{"LK"}}, far=true, offset_x=-16},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-16, self_chain=true, delay={6}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}, offset_x=-16, self_chain=true, delay={4}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  q = {
    {sequence={{"LP"}}, offset_x=-16, far=true, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}, offset_x=-16, self_chain=true, delay={4}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, block={2}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  remy = {
    {sequence={{"LP"}}, offset_x=-16, far=true, self_chain=true},
    {sequence={{"MP"}}, far=true},
    {sequence={{"HP"}}, far=true},
    {sequence={{"LK"}}, far=true, offset_x=-10},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}, far=true},
    {sequence={{"down","LP"}}, offset_x=-16, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, max_hits=2, block={2,2}}},
  ryu = {
    {sequence={{"LP"}}, far=true, offset_x=-16, self_chain=true},
    {sequence={{"MP"}}, far=true, offset_x=-10},
    {sequence={{"HP"}}, far=true, offset_x=-10},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}, offset_x=-24, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  sean = {
    {sequence={{"LP"}}, offset_x=-16, self_chain=true},
    {sequence={{"MP"}}, far=true},
    {sequence={{"HP"}}, far=true},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}, far=true},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}, offset_x=-24, self_chain=true},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  shingouki = {
    {sequence={{"LP"}}, far=true, offset_x=-10},
    {sequence={{"MP"}}, far=true, offset_x=-10},
    {sequence={{"HP"}}, far=true, offset_x=-10},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  twelve = {
    {sequence={{"LP"}}},
    {sequence={{"MP"}}, far=true},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, max_hits=3},
    {sequence={{"down","LK"}}, block={2}, self_chain=true, delay={8}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, max_hits=3, block={2,2,2}}},
  urien = {
    {sequence={{"LP"}}, offset_x=-16, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}, max_hits=2, offset_x=-10},
    {sequence={{"down","LP"}}, offset_x=-16, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, max_hits=2},
    {sequence={{"down","LK"}}, block={2}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  yang = {
    {sequence={{"LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"MP"}}, far=true},
    {sequence={{"HP"}}, far=true},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}, block={2}},
    {sequence={{"down","HP"}}, max_hits=2},
    {sequence={{"down","LK"}}, block={2}, offset_x=-24, self_chain=true, delay={4}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}},
  yun = {
    {sequence={{"LP"}}, far=true, offset_x=-24, self_chain=true},
    {sequence={{"MP"}}, far=true, offset_x=-10},
    {sequence={{"HP"}}, far=true},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}, far=true},
    {sequence={{"HK"}}},
    {sequence={{"down","LP"}}, offset_x=-24, self_chain=true},
    {sequence={{"down","MP"}}},
    {sequence={{"down","HP"}}, max_hits=2},
    {sequence={{"down","LK"}}, block={2}, offset_x=-24, self_chain=true, delay={4}},
    {sequence={{"down","MK"}}, block={2}},
    {sequence={{"down","HK"}}, block={2}}}
}

local other_normals_list = {
  alex = {
    {sequence={{"LP"}}, offset_x=-28, self_chain=true},
    {sequence={{"forward","MP"}}},
    {sequence={{"forward","HP"}}},
    {sequence={{"back","HP"}}},
    {sequence={{"MK"}}},
    {sequence={{"down","HP"}}, air=true, player_offset_y=60, ignore_next_anim = true}
  },
  chunli = {
    {sequence={{"LP"}}, offset_x=-28},
    {sequence={{"MK"}}, max_hits=3},
    {sequence={{"forward","MK"}}},
    {sequence={{"HK"}}},
    {sequence={{"forward","HK"}}},
    {sequence={{"down","forward","HK"}}},
    {sequence={{"back","MP"}}, max_hits=2},
    {sequence={{"back","HP"}}},
    {sequence={{"down","MK"}}, air=true, player_offset_y = 55, ignore_next_anim = true},
    {sequence={{"down","HP"}}, air=true, player_offset_y = 25}
  },
  dudley = {
    {sequence={{"forward","LP"}}, self_chain=true},
    {sequence={{"forward","MP"}}},
    {sequence={{"forward","MK"}}},
    {sequence={{"forward","HP"}}},
    {sequence={{"forward","HK"}}}
  },
  elena = {
    {sequence={{"forward","MP"}}},
    {sequence={{"forward","MK"}}},
    {sequence={{"down","forward","HK"}}, block={2}},
    {sequence={{"back","HK"}}}
  },
  gill = {
    {sequence={{"back","MP"}}},
    {sequence={{"forward","MK"}}}
  },
  gouki = {
    {sequence={{"LP"}}, offset_x=-16, self_chain=true, delay={2}},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}, max_hits=2},
    {sequence={{"forward","MP"}}, max_hits=2, block={4,4}},
    {sequence={{"down","MK"}}, air=true, player_offset_y = 50, ignore_next_anim = true}
  },
  hugo = {
    {sequence={{"forward","HP"}}},
    {sequence={{"down","HP"}}, air=true, player_offset_y = 10, ignore_next_anim = true}
  },
  ibuki = {
    {sequence={{"LP"}}, offset_x=-17, self_chain=true, delay={4}},
    {sequence={{"HP"}}, max_hits=2, offset_x=-17},
    {sequence={{"HK"}}, max_hits=2},
    {sequence={{"forward","HK"}}},
    {sequence={{"forward","MK"}}},
    {sequence={{"forward","LK"}}, self_chain=true},
    {sequence={{"back","MP"}}, max_hits=2},
    {sequence={{"back","MK"}}},
    {sequence={{"down","forward","MK"}}, block={2}}
  },
  ken = {
    {sequence={{"LP"}}, offset_x=-16, self_chain=true, delay={2}},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"forward","MK"}}},
    {sequence={{"back","MK"}}, max_hits=2},
    {sequence={{"MK"}}, name="MK_hold", offset_x=10, max_hits=3},
    {sequence={{"forward","HK"}}},
    {sequence={{"forward","HK"}}, name="f_HK_hold", max_hits=0}
  },
  makoto = {
    {sequence={{"forward","LP"}}, self_chain=true, delay={2}},
    {sequence={{"forward","MP"}}},
    {sequence={{"forward","LK"}}},
    {sequence={{"forward","MK"}}},
    {sequence={{"forward","HK"}}, block={2}},
    {sequence={{"forward","HK"}}, name="f_HK_hold", max_hits=0}
  },
  necro = {
    {sequence={{"back","LP"}}},
    {sequence={{"back","MP"}}},
    {sequence={{"back","HP"}}},
    {sequence={{"back","LK"}}, self_chain=true, delay={2}},
    {sequence={{"back","MK"}}},
    {sequence={{"back","HK"}}},
    {sequence={{"down","back","HP"}}, offset_x=24},
    {sequence={{"down","LK"}}, air=true, name="drill_LK", max_hits=2, ignore_next_anim = true},
    {sequence={{"down","MK"}}, air=true, name="drill_MK", max_hits=2, ignore_next_anim = true},
    {sequence={{"down","HK"}}, air=true, name="drill_HK", max_hits=2, ignore_next_anim = true}
  },
  oro = {
    {sequence={{"LP"}}, offset_x=-28, self_chain=true, delay={4}},
    {sequence={{"MP"}}, max_hits=2},
    {sequence={{"LK"}}, offset_x=-24, self_chain=true, delay={6}},
    {sequence={{"MK"}}},
    {sequence={{"forward","MP"}}}
  },
  q = {
    {sequence={{"LP"}}},
    {sequence={{"MK"}}},
    {sequence={{"back","MP"}}},
    {sequence={{"back","HP"}}},
    {sequence={{"back","HK"}}}
  },
  remy = {
    {sequence={{"LP"}}, self_chain=true},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"LK"}}},
    {sequence={{"MK"}}},
    {sequence={{"HK"}}, max_hits=2, offset_x=-14},
    {sequence={{"forward","MK"}}}
  },
  ryu = {
    {sequence={{"LP"}}, offset_x=-16, self_chain=true, delay={2}},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"MK"}}},
    {sequence={{"forward","MP"}}, max_hits=2, block={4,4}},
    {sequence={{"forward","HP"}}, max_hits=2},
  },
  sean = {
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"HK"}}},
    {sequence={{"forward","HP"}}, max_hits=2, block={4,4}},
    {sequence={{"forward","HK"}}},
  },
  shingouki = {
    {sequence={{"LP"}}, offset_x=-20},
    {sequence={{"MP"}}},
    {sequence={{"HP"}}},
    {sequence={{"MK"}}},
    {sequence={{"forward","MP"}}, max_hits=2, block={4,4}},
    {sequence={{"down","MK"}}, air=true, player_offset_y = 50, ignore_next_anim = true}
  },
  twelve = {
    {sequence={{"MP"}}},
    {sequence={{"back","MK"}}}
  },
  urien = {
    {sequence={{"forward","MP"}}},
    {sequence={{"forward","HP"}}},
    {sequence={{"forward","MK"}}}
},
  yang = {
    {sequence={{"MP"}}, offset_x=-10},
    {sequence={{"HP"}}, max_hits=2, offset_x=-10},
    {sequence={{"MK"}}, offset_x=-22},
    {sequence={{"forward","MK"}}, offset_x=50},
    {sequence={{"down","forward","LK"}}, name="raigeki_LK", air=true, player_offset_y=64, ignore_next_anim = true},
    {sequence={{"down","forward","MK"}}, name="raigeki_MK", air=true, player_offset_y=64, ignore_next_anim = true},
    {sequence={{"down","forward","HK"}}, name="raigeki_HK", air=true, player_offset_y=64, ignore_next_anim = true}
  },
  yun = {
    {sequence={{"LP"}}, offset_x=-14, self_chain=true},
    {sequence={{"MP"}}, offset_x=-10},
    {sequence={{"HP"}}, max_hits=2, offset_x=-10},
    {sequence={{"MK"}}, offset_x=-22},
    {sequence={{"forward","MK"}}, offset_x=50},
    {sequence={{"forward","HP"}}, offset_x=50},
    {sequence={{"down","forward","LK"}}, name="raigeki_LK", air=true, player_offset_y=64, ignore_next_anim = true},
    {sequence={{"down","forward","MK"}}, name="raigeki_MK", air=true, player_offset_y=64, ignore_next_anim = true},
    {sequence={{"down","forward","HK"}}, name="raigeki_HK", air=true, player_offset_y=64, ignore_next_anim = true}
  }
}
local other_normals = {}
local target_combos_list = {
  alex = {
    {sequence={{"down","LK"},{"down","MK"}}, max_hits=2, block={2,2}, delay={0,1}, optional_anim={0,1}},
    {sequence={{"down","LK"},{"down","HK"}}, max_hits=2, block={2,2}, delay={0,3}, optional_anim={0,1}}
  },
  chunli = {
    {sequence={{"HP"},{"HP"}}, max_hits=2, air=true, offset_x=-22, cancel_on_whiff=true}, optional_anim={0,1}},
  dudley = {
    {sequence={{"forward","LP"},{"MP"}}, max_hits=2, optional_anim={0,1}, delay={0,5}},
    {sequence={{"LP"},{"MP"},{"MK"}}, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"down","LK"},{"MK"}}, max_hits=2, block={2,1}, optional_anim={0,1}},
    {sequence={{"down","LK"},{"down","MP"},{"down","HP"}}, max_hits=3, block={2,1,1}, optional_anim={0,1,1}},
    {sequence={{"LK"},{"MK"},{"MP"},{"HP"}}, max_hits=5, optional_anim={0,1,1,1,0}},
    {sequence={{"MP"},{"MK"},{"HP"}}, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"forward","MK"},{"MK"},{"HP"}}, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"MK"},{"HK"},{"HP"}}, max_hits=4, optional_anim={0,1,1,0}},
    {sequence={{"forward","HK"},{"MK"}}, max_hits=2, optional_anim={0,1}}
  },
  elena = {
    {sequence={{"MK"},{"down","HP"}}, max_hits=2, optional_anim={0,1}},
    {sequence={{"HP"},{"HK"}}, max_hits=2, optional_anim={0,1}},
    {sequence={{"LP"},{"MK"}}, max_hits=2, air=true, optional_anim={0,1}, offset_x=-10},
    {sequence={{"MP"},{"HP"}}, max_hits=2, air=true, optional_anim={0,1}}
  },
  gill = {
    {sequence={{"LP"},{"MP"}}, max_hits=2, delay={0,5}, optional_anim={0,1}},
    {sequence={{"down","LK"},{"down","MK"}}, max_hits=2, block={2,2}, delay={0,3}, optional_anim={0,1}}
  },
  gouki = {
    {sequence={{"MP"},{"HP"}}, max_hits=2, optional_anim={0,1}}
  },
  hugo = {},
  ibuki = {
    {sequence={{"HP"},{"HP"}}, max_hits=2, far=true, offset_x=-22, cancel_on_whiff=true, optional_anim={0,1}},
    {sequence={{"LP"},{"MP"},{"HP"}}, max_hits=3, offset_x=-18, optional_anim={0,1,1}},
    {sequence={{"LK"},{"MK"},{"HK"}}, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"LP"},{"MP"},{"down","HK"},{"HK"}}, max_hits=5, cancel_on_hit={1,0,1,1}, block={1,1,1,2,1}, offset_x=-18, delay={0,0,1,0,0}, optional_anim={0,1,0,1,1}},
    {sequence={{"back","MP"},{"down","HK"},{"HK"}}, max_hits=4, cancel_on_hit={0,1,1}, block={1,1,2,1}, delay={0,1,0,0}, optional_anim={0,0,1,1}},
    {sequence={{"down","HK"},{"HK"}}, max_hits=3, block={2,1,1}, optional_anim={0,1,0}},
    {sequence={{"down","HK"},{"HK"}}, max_hits=2, far=true, block={2,1}, optional_anim={0,1}},
    {sequence={{"HP"},{"down","HK"},{"HK"}}, offset_x=-17, max_hits=4, cancel_on_hit={0,1,1}, block={1,1,2,1}, delay={0,1,0,0}, optional_anim={0,0,1,1}},
    {sequence={{"back","MK"},{"forward","MK"}}, max_hits=2, block={1,1}, optional_anim={0,1}},
    {sequence={{"LP"},{"MP"},{"forward","LK"}}, max_hits=3, offset_x=6, optional_anim={0,1,1}},
    {sequence={{"back","MP"},{"HP"}}, max_hits=2, optional_anim={0,1}},
    {sequence={{"LK"},{"forward","MK"}}, max_hits=2, air=true, optional_anim={0,1}},
    {sequence={{"LP"},{"forward","HP"}}, max_hits=2, air=true, optional_anim={0,1}},
    {sequence={{"HP"},{"forward","MK"}}, max_hits=2, air=true, optional_anim={0,1}}
  },
  ken = {
    {sequence={{"MP"},{"HP"}}, max_hits=2, optional_anim={0,1}}
  },
  makoto = {
    {sequence={{"LK"},{"MK"}}, offset_x = 10, max_hits=2, optional_anim={0,1}},
    {sequence={{"forward","HP"},{"HP"}}, dummy_offset_list={{200,0},{80,0},{80,0}}, max_hits=3, optional_anim={0,1,0}},
    {sequence={{"forward","MK"},{"HK"}}, dummy_offset_list={{200,0},{80,0}}, max_hits=2, optional_anim={0,1}}
  },
  necro = {
    {sequence={{"back","LK"},{"MP"}}, max_hits=2, optional_anim={0,1}}
  },
  oro = {
    {sequence={{"LK"},{"MK"}}, offset_x=-24, max_hits=2, optional_anim={0,1}}
  },
  q = {},
  remy = {
    {sequence={{"MK"},{"HK"}}, offset_x=6, max_hits=2, optional_anim={0,1}}
  },
  ryu = {
    {sequence={{"HP"},{"HK"}}, far=true, max_hits=2, offset_x=-10, optional_anim={0,1}}
  },
  sean = {
    {sequence={{"MP"},{"HK"}}, max_hits=2, optional_anim={0,1}},
    {sequence={{"HP"},{"forward","HP"}}, max_hits=3, optional_anim={0,1,0}}
  },
  shingouki = {
    {sequence={{"MP"},{"HP"}}, max_hits=2, optional_anim={0,1}}
  },
  twelve = {},
  urien = {
    {sequence={{"LP"},{"MP"}}, max_hits=2, optional_anim={0,1}},
    {sequence={{"forward","MP"},{"forward","HP"}}, offset_x=12, max_hits=2, optional_anim={0,1}}
  },
  yang = {
    {sequence={{"MP"},{"HP"},{"back","HP"}}, offset_x=-10, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"MP"},{"HP"},{"back","HP"}}, far=true, offset_x=-30, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"LK"},{"MK"},{"HK"}}, offset_x=-10, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"MK"},{"down","forward","MK"}}, max_hits=2, air=true, offset_x=-30, optional_anim={0,1}}
  },
  yun = {
    {sequence={{"LP"},{"LK"},{"MP"}}, max_hits=3, offset_x=-14, optional_anim={0,1,1}},
    {sequence={{"MP"},{"HP"},{"back","HP"}}, offset_x=-10, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"MP"},{"HP"},{"back","HP"}}, far=true, offset_x=-30, max_hits=3, optional_anim={0,1,1}},
    {sequence={{"down","MP"},{"down","HP"}}, max_hits=3, optional_anim={0,1,0}},
    {sequence={{"down","HK"},{"HK"}}, max_hits=2, block={2,1}, optional_anim={0,1}},
    {sequence={{"LP"},{"forward","HP"}}, max_hits=2, air=true, player_offset_y=-24, offset_x=-20, optional_anim={0,1}}
  }
}
local target_combos = {}

local throw_uoh_pa = {
  {sequence={{"LP","LK"}}, name="throw_neutral"},
  {sequence={{"forward","LP","LK"}}, name="throw_forward"},
  {sequence={{"back","LP","LK"}}, name="throw_back"},
  {sequence={{"MP","MK"}}, name="uoh"},
  {sequence={{"HP","HK"}}, name="pa"}}

local reverse_power_bomb = combine_arrays(get_move_sequence_by_name("alex","flash_chop","MP"), {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}})
reverse_power_bomb = combine_arrays(reverse_power_bomb, get_move_sequence_by_name("alex","power_bomb","MP"))

local wakeups_list = {
    {character = "ibuki", name = "raida", sequence = get_move_sequence_by_name("ibuki","raida","HP")},
    {character = "ibuki", name = "kazekiri", sequence = get_move_sequence_by_name("ibuki","kazekiri","LK"), quick = true},
    {character = "ibuki", name = "kubiori", sequence = get_move_sequence_by_name("ibuki","kubiori","EXP"), quick = true}
}




local current_attack = {}
local tc_hit_index = 1
local block_until = 0
local received_hits = 0
local block_max_hits = 0
local block_pattern = nil
local begin_recording_pushback = false
local unfreeze_player = false
local unfreeze_dummy = false

local specials = {}
local supers = {}

local current_projectile = nil
local freeze_player_for_projectile = false

local pressing_F12 = 0
local pressing_F11 = 0

local _player = nil
local _dummy = nil
local recording = false
local recording_projectiles = false
local self_freeze = 10
local recording_self_freeze = false
local recording_opponent_freeze = false
local recording_recovery = false
local recording_pushback = false
local recording_options = {hit_type="miss"}
local recording_hit_types = {"miss", "block"}
local i_recording_hit_types = 1
local attack_categories = {}
local current_attack_category = {}
local i_attack_categories = 1
local i_attacks = 1
local recording_geneijin = false
local _dummy_offset_x = 0
local _dummy_offset_y = 0
local _reset_pos_x = 444
local _default_air_miss_height = 200
local _default_air_block_height = 26

local overwrite = false
local first_record = true
recording_framedata = false

function record_frames_hotkey()
  local keys = input.get()
  if pressing_F12 == 0 and keys.F12 then
    pressing_F12 = 1
    recording_framedata = true
  end
  if pressing_F12 == 1 and not keys.F12 then
    pressing_F12 = 0
  end
end

local i_record = 4
local i_characters = 8
local end_character = 21
local record_char_state = "start"
local char_list = deepcopy(characters)
table.sort(char_list)
local last_category = 1

function record_all_characters(_player_obj, _projectiles)
  if recording_framedata then
    -- emu.speedmode("turbo")
    training_settings.blocking_mode = 1
    _player = _player_obj
    _dummy = _player_obj.other
    if record_char_state == "start" then
      frame_data["projectiles"] = {}
      record_char_state = "new_character"
    elseif record_char_state == "new_character" then
      if i_characters <= end_character then
        _char = char_list[i_characters]
        overwrite = false
        first_record = true
        -- frame_data[_char] = {}
        _state = "start"
        _setup = false
        recording = false
        i_attack_categories = 7
        last_category = 7
        i_recording_hit_types = 1
        received_hits = 0
        block_until = 0
        block_max_hits = 0
        recording_options.hit_type = "miss"
        table.insert(after_load_state_callback, {command = force_select_character, args = {_player.id, _char, 1, "LP"} })
        table.insert(after_load_state_callback, {command = force_select_character, args = {_dummy.id, "urien", 1, "MP"} })
        start_character_select_sequence()
        record_char_state = "recording"
      else
        record_char_state = "finished"
      end
    elseif record_char_state == "recording" then
      debug_settings.record_framedata = true

      if i_record == 1 then
        record_idle(_player)
      elseif i_record == 2 then
        record_movement(_player)
      elseif i_record == 3 then
        record_wakeups(_player)
      elseif i_record == 4 then
        record_attacks(_player, _projectiles)
      elseif i_record == 5 then
        record_landing()
      end

      if _state == "finished" then
        _state = "start"
        _setup = false
        recording = false
        debug_settings.record_framedata = false
        i_record = i_record + 1
        -- i_characters = 99
      end
      if i_record > 5 then
        i_record = 1
        i_characters = i_characters + 1
        record_char_state = "new_character"
      save_frame_data()
      --make space in memory
        frame_data[_char] = {}
      end
    elseif record_char_state == "finished" then
      save_frame_data()
      load_frame_data_co = coroutine.create(load_frame_data_async)
      frame_data_loaded = false --debug
      record_char_state = "the_end"
    end
  end
end

function update_framedata_recording(_player_obj, _projectiles)
  record_all_characters(_player_obj, _projectiles)
end

local record_idle_duration = 600
local record_idle_start_frame = 0
local record_idle_states = {"standing", "crouching", "to_stand", "to_crouch"}
local i_record_idle_states = 1
function record_idle(_player_obj)
  local _player = _player_obj
  local _dummy = _player_obj.other
  function start_recording_idle(_name)
    new_recording(_player, {}, _name)
    record_idle_start_frame = frame_number
    write_pos(_player, 440, 0)
    write_pos(_dummy, 540, 0)
    print(_name)
  end

  if is_in_match and debug_settings.record_framedata then
    if i_record_idle_states <= #record_idle_states then
      local _name = record_idle_states[i_record_idle_states]
      if _name == "standing" then
        if _setup then
          if not (_state == "recording") and _player.action == 0 then
            recording_options = {recording_idle = true}
            -- recording_options.infinite_loop = true
            start_recording_idle(_name)
          end
        else
          queue_input_sequence(_player, {{"down"}})
          if _player.action == 7 then
            clear_motion_data(_player)
            _setup = true
          end
        end
      elseif _name == "crouching" then
        if _setup then
          if not (_state == "recording") and _player.action == 7 then
            recording_options = {recording_idle = true}
            -- recording_options.infinite_loop = true
            start_recording_idle(_name)
          end
          queue_input_sequence(_player, {{"down"}})
        else
          if _player.action == 0 then
            clear_motion_data(_player)
            _setup = true
          end
        end
      elseif _name == "to_stand" then
        if _setup then
          if not (_state == "recording") and _player.action == 11 then
            recording_options = {recording_idle = true}
            start_recording_idle(_name)
          end
        else
          queue_input_sequence(_player, {{"down"}})
          if _player.action == 7 then
            clear_motion_data(_player)
            _setup = true
          end
        end
      elseif _name == "to_crouch" then
        if _setup then
          if not (_state == "recording") and _player.action == 6 then
            recording_options = {recording_idle = true}
            start_recording_idle(_name)
          end
          queue_input_sequence(_player, {{"down"}})
        else
          if _player.action == 0 then
            clear_motion_data(_player)
            _setup = true
          end
        end
      end
      if _state == "recording" then
        if (frame_number - record_idle_start_frame >= record_idle_duration)
        or (_name == "to_stand" and _player.action ~= 11)
        or (_name == "to_crouch" and _player.action ~= 6)
        then
          end_recording(_player, {}, _name)
          i_record_idle_states = i_record_idle_states + 1
          _setup = false
        end
      end
      if _state == "recording" and _player.has_animation_just_changed and record_idle_start_frame ~= frame_number then
        new_animation(_player, {}, _name)
      end
      record_framedata(_player, {}, _name)
    else
      _state = "finished"
      i_record_idle_states = 1
      return
    end
  end
end

local movement_list = {"walk_forward", "walk_back", "dash_forward", "dash_back", "standing_turn", "crouching_turn", "jump_forward", "jump_neutral", "jump_back", "sjump_forward", "sjump_neutral", "sjump_back", "air_dash", "block_high", "block_low", "parry_high", "parry_low", "parry_air"}
local i_movement_list = 1
local _m_player_reset_pos = {440, 0}
local _m_dummy_reset_pos_offset = {100, 0}
local _clear_jump_after = 30
local allow_dummy_movement = false
local _name = ""

function record_movement(_player_obj)
  local _player = _player_obj
  local _dummy = _player_obj.other
  if is_in_match and debug_settings.record_framedata then
    if _player.action == 0 or _player.action == 7 then
      if recording then
        if _player.has_animation_just_changed then
          end_recording(_player, {}, _name)
          i_movement_list = i_movement_list + 1
        end
      end
    elseif _state == "wait_for_initial_anim" and _player.has_animation_just_changed then


      if _name == "walk_forward" then
        if _player.action == 2 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "walk_back" then
        if _player.action == 3 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "dash_forward" then
        if _player.action == 23 then
          _name = "dash_startup"
          recording_options.record_next_anim = true
          new_recording(_player, {}, _name)
        end
      elseif _name == "dash_back" then
        if _player.action == 23 then
          _name = "dash_startup"
          recording_options.record_next_anim = true
          new_recording(_player, {}, _name)
        end
      elseif _name == "standing_turn" then
        if _player.action == 1 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "crouching_turn" then
        if _player.action == 8 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "block_high" then
        if _player.action == 30 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "block_low" then
        if _player.action == 31 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "parry_high" then
        if _player.action == 24 or _player.action == 25 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "parry_low" then
        if _player.action == 26 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "parry_air" then
        if _player.action == 27 then
          new_recording(_player, {}, _name)
        end
      elseif _name == "jump_forward"
      or _name == "jump_neutral"
      or _name == "jump_back" then
        if _player.action == 12 then
          _name = "jump_startup"
          recording_options.record_next_anim = true
          new_recording(_player, {}, _name)
        end
      elseif _name == "sjump_forward"
      or _name == "sjump_neutral"
      or _name == "sjump_back" then
        if _player.action == 13 then
          _name = "sjump_startup"
          recording_options.record_next_anim = true
          new_recording(_player, {}, _name)
        end
      elseif _name == "air_dash" then
        if _player.animation == "b394" then
          new_recording(_player, {}, _name)
        end
      else
        new_recording(_player, {}, _name)
      end
    elseif recording then
      if _player.has_animation_just_changed then
        if _player.action == 4 then
          _name = "dash_forward"
        elseif _player.action == 5 then
          _name = "dash_back"
        elseif _player.action == 14 then
          _name = "jump_forward"
        elseif _player.action == 15 then
          _name = "jump_neutral"
        elseif _player.action == 16 then
          _name = "jump_back"
        elseif _player.action == 20 then
          _name = "sjump_forward"
        elseif _player.action == 21 then
          _name = "sjump_neutral"
        elseif _player.action == 22 then
          _name = "sjump_back"
        end
        new_animation(_player, {}, _name)
      end
    end
    if _state == "ready" then
      if _player.is_idle and _dummy.is_idle and _player.action == 0 then
        _state = "queue_move"
      end
    elseif _state == "wait_for_match_start" then
      if has_match_just_started then
        _state = "queue_move"
      end
    end

    if not _setup and _state == "start" then
      _setup = true
      _state = "ready"
    end

    if _state == "make_sure_action_is_0" then
      --remy turns around slow
      if _player.action == 0 then
        _state = "wait_for_initial_anim"
      end
    end

    if _state == "queue_move" then
      _state = "wait_for_initial_anim"
      if i_movement_list <= #movement_list then
        recording_options = {recording_movement = true}
        allow_dummy_movement = false
        _name = movement_list[i_movement_list]
        local _is_jump = false
        local _sequence = {}
        _m_player_reset_pos = {440, 0}
        _m_dummy_reset_pos_offset = {100, 0}
        if _name == "walk_forward" then
          for i = 1, 160 do
            table.insert(_sequence, {"forward"})
          end
          _m_player_reset_pos = {150, 0}
        elseif _name == "walk_back" then
          for i = 1, 160 do
            table.insert(_sequence, {"back"})
          end
          _m_player_reset_pos = {650, 0}
        elseif _name == "dash_forward" then
          _sequence = {{"forward"}, {}, {"forward"}}
        elseif _name == "dash_back" then
          _sequence = {{"back"}, {}, {"back"}}
        elseif _name == "standing_turn" then
          _m_dummy_reset_pos_offset = {90, 0}
          allow_dummy_movement = true
          if _player.char_str == "remy" then
            _state = "make_sure_action_is_0"
          end
          queue_input_sequence(_dummy, {{"down"},{"up","forward"},{"up","forward"},{"up","forward"},{},{},{},{}})
        elseif _name == "crouching_turn" then
          _m_dummy_reset_pos_offset = {90, 0}
          allow_dummy_movement = true
          queue_command(frame_number + 10, {command = queue_input_sequence, args = {_dummy, {{"down"},{"up","forward"},{"up","forward"},{"up","forward"},{},{},{},{}}}})
          for i = 1, 100 do
            table.insert(_sequence, {"down"})
          end
          queue_command(frame_number + 8, {command = clear_motion_data, args = {_player}})
        elseif _name == "jump_forward" then
          _is_jump = true
          _sequence = {{"up","forward"},{"up","forward"},{"up","forward"},{},{},{},{}}
        elseif _name == "jump_neutral" then
          _is_jump = true
          _sequence = {{"up"},{"up"},{"up"},{},{},{},{}}
        elseif _name == "jump_back" then
          _is_jump = true
          _sequence = {{"up","back"},{"up","back"},{"up","back"},{},{},{},{}}
        elseif _name == "sjump_forward" then
          _is_jump = true
          _sequence = {{"down"},{"up","forward"},{"up","forward"},{"up","forward"},{},{},{},{}}
        elseif _name == "sjump_neutral" then
          _is_jump = true
          _sequence = {{"down"},{"up"},{"up"},{"up"},{},{},{},{}}
        elseif _name == "sjump_back" then
          _is_jump = true
          _sequence = {{"down"},{"up","back"},{"up","back"},{"up","back"},{},{},{},{}}
        elseif _name == "air_dash" then
          if _player.char_str == "twelve" then
            _sequence = {{"down"},{"up","back"},{"up","back"},{"up","back"},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{"forward"},{},{"forward"}}
          else
            i_movement_list = i_movement_list + 1
            _state = "queue_move"
            return
          end
        elseif _name == "block_high" then
          recording_options.ignore_movement = true
          queue_input_sequence(_dummy, {{"MK"}})
          for i = 1, 30 do
            table.insert(_sequence, {"back"})
            queue_command(frame_number + i, {command = clear_motion_data, args = {_player}})
          end
        elseif _name == "block_low" then
          recording_options.ignore_movement = true
          queue_input_sequence(_dummy, {{"down","MK"}})
          for i = 1, 30 do
            table.insert(_sequence, {"down","back"})
            queue_command(frame_number + i, {command = clear_motion_data, args = {_player}})
          end
        elseif _name == "parry_high" then
          queue_input_sequence(_dummy, {{"MK"}})
          queue_command(frame_number + 1, {command = queue_input_sequence, args = {_player, {{"forward"}}}})
          queue_command(frame_number + 2, {command = clear_motion_data, args = {_player}})
          --24 25
        elseif _name == "parry_low" then
          queue_input_sequence(_dummy, {{"down","MK"}})
          queue_command(frame_number + 1, {command = queue_input_sequence, args = {_player, {{"down"}}}})
          queue_command(frame_number + 2, {command = clear_motion_data, args = {_player}})
          --26
        elseif _name == "parry_air" then
          _m_dummy_reset_pos_offset = {100, 40}
          queue_input_sequence(_dummy, {{"up"},{"up"},{},{},{},{},{"HK"}})
          queue_input_sequence(_player, {{"up"}})
          queue_command(frame_number + 14, {command = queue_input_sequence, args = {_player, {{"forward"}}}})
          queue_command(frame_number + 15, {command = clear_motion_data, args = {_player}})
          -- queue_command(frame_number + 80, {command = write_pos, args = {_player, _player.pos_x, 0}})
          queue_command(frame_number + 80, {command = land_player, args = {_player}})
          --27
        end
        if _is_jump then
          -- recording_options.infinite_loop = true
          queue_command(frame_number + _clear_jump_after, {command = clear_motion_data, args = {_player}})
          queue_command(frame_number + _clear_jump_after, {command = function() recording_options.ignore_motion = true end})
          queue_command(frame_number + _clear_jump_after + 100, {command = land_player, args = {_player}})
        end

        write_pos(_player, _m_player_reset_pos[1], _m_player_reset_pos[2])
        write_pos(_dummy, _player.pos_x + _m_dummy_reset_pos_offset[1], _player.pos_y + _m_dummy_reset_pos_offset[2])
        fix_screen_pos(_player, _dummy)
        queue_input_sequence(_player, _sequence)
        print(_name)
      else
        _state = "finished"
        i_movement_list = 1
        return
      end
    end
    if _setup then
      if not allow_dummy_movement then
        write_pos(_dummy, _player.pos_x + _m_dummy_reset_pos_offset[1], _player.pos_y + _m_dummy_reset_pos_offset[2])
      end
      record_framedata(_player, {}, _name)
    end
  end
end

local i_wakeups = 1
local _previous_posture = 0
function record_wakeups(_player_obj)
  local _player = _player_obj
  local _dummy = _player_obj.other
  if is_in_match and debug_settings.record_framedata then

    if not _setup and _state == "start" then
      _setup = true
      _state = "ready"
    end
    if _state == "wait_for_match_start" then
      if has_match_just_started then
        _state = "queue_move"
      end
    elseif _state == "ready" then
      if is_in_match then
        _state = "queue_move"
      end
    end

    if _state == "queue_move" then
      if i_wakeups <= #wakeups_list then
        recording_options = {recording_wakeups = true, record_next_anim = true}
        current_attack = deepcopy(wakeups_list[i_wakeups])
        if _dummy.char_str ~= current_attack.character then
          _state = "wait_for_match_start"
          table.insert(after_load_state_callback, {command = force_select_character, args = {_player.id, _player.char_str, 1, "LP"} })
          table.insert(after_load_state_callback, {command = force_select_character, args = {_dummy.id, current_attack.character, 1, "MK"} })
          start_character_select_sequence()
          return
        end
        current_attack.reset_pos_x = 440
        _dummy_offset_x = 60
        if current_attack.name == "raida" then
          _name = "wakeup"
        elseif current_attack.name == "kazekiri" then
          _name = "wakeup_quick"
        elseif current_attack.name == "kubiori" then
          _name = "wakeup_quick_reverse"
        end
        write_pos(_player, current_attack.reset_pos_x, 0)
        write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0)
        memory.writebyte(_dummy.stun_bar_char_addr, 0)
        memory.writebyte(_dummy.life_addr, 160)
        fix_screen_pos(_player, _dummy)
        queue_input_sequence(_dummy, current_attack.sequence)

        _state = "wait_for_knockdown"
      else
        i_wakeups = 1
        _state = "finished"
        return
      end
    end
    if recording then
      if _player.posture == 0 and _previous_posture == 0x26 then
        recording_options.insert_wakeup = true
        _state = "wait_for_idle"
      end
      if _state == "wait_for_idle" then
        if _player.is_idle and _player.has_animation_just_changed and _player.action == 0 then
          end_recording(_player, {}, _name)
          i_wakeups = i_wakeups + 1
          _state = "queue_move"
        end
      elseif _state == "recording" then
        if _player.has_animation_just_changed then
          new_animation(_player, {}, _name)
        end
      end
    else
      if _state == "wait_for_knockdown" then
        if _player.posture == 0x26 then
          clear_motion_data(_player)
          new_recording(_player, {}, _name)
          _state = "recording"
        end
      end
    end
    if _setup then
      local _should_tap_down = _player.previous_can_fast_wakeup == 0 and _player.can_fast_wakeup == 1

      if _should_tap_down and current_attack.quick then
        local _input = joypad.get()
        _input[_player.prefix..' Down'] = true
        joypad.set(_input)
      end

      record_framedata(_player, {}, _name)
    end
    _previous_posture = _player.posture
  end
end

landing_recording = {
  animation = 0,
  frame = 0,
  max_frames = 0,
  act_frame_number = 0,
  sequence = {}
}

landing_categories = {}
i_landing_categories = 1
i_landings = 1
current_landing_category = {}
empty_jumps = {
  {name="jump_forward", sequence={{"up","forward"},{"up","forward"},{"up","forward"}}},
  {name="jump_neutral", sequence={{"up"},{"up"},{"up"}}},
  {name="jump_back", sequence={{"up","back"},{"up","back"},{"up","back"}}},
  {name="sjump_forward", sequence={{"down"},{"up","forward"},{"up","forward"},{"up","forward"}}},
  {name="sjump_neutral", sequence={{"down"},{"up"},{"up"},{"up"}}},
  {name="sjump_back", sequence={{"down"},{"up","back"},{"up","back"},{"up","back"}}}
}
landing_j_normals = {{name="jump_forward", sequence={{"up","forward"},{"up","forward"},{"up","forward"}}}}
jumping_target_combos = {}
air_specials = {}

local lo, hi = -100, 60
local landing_height = hi
local n_no_data = 0

function record_landing()
  local _player = P1
  if _state == "start" and not _setup and has_match_just_started then
    make_invulnerable(_player.other, true)

    landing_categories = {
      {name = "empty_jumps", list = empty_jumps},
      {name = "jumping_normals", list = landing_j_normals},
      {name = "jumping_target_combos", list = jumping_target_combos},
      {name = "air_specials", list = air_specials}
    }
    _setup = true
    _state = "queue_move"
  end
  if _state == "queue_move" then
    --jumps
    --normals
    --specials


    if i_landings <= #landing_categories[i_landing_categories].list then
      current_landing_category = landing_categories[i_landing_categories]
    else
      if i_landing_categories >= #landing_categories then
        _state = "finished"
        i_landings = 1
        i_landing_categories = 1
        current_landing_category = {}
        make_invulnerable(_dummy, false)
        return
      end
      i_landing_categories = i_landing_categories + 1
      i_landings = 1
      current_landing_category = landing_categories[i_landing_categories]
      if #landing_categories[i_landing_categories].list == 0 then
        i_landing_categories = i_landing_categories + 1
        _state = "finished"
      end
      return
    end

    landing_recording = {
      animation = 0,
      frame = 0,
      max_frames = 0,
      act_frame_number = 0,
      act_offset = 0,
      sequence = {}
    }


    if current_landing_category.name == "empty_jumps" then
      current_attack = deepcopy(empty_jumps[i_landings])
      local _, _startup = 0, 4
      if current_attack.name == "jump_forward"
      or current_attack.name == "jump_neutral"
      or current_attack.name == "jump_back"
      then
        _, _startup = find_frame_data_by_name(_player.char_str, "jump_startup")
      end

      if current_attack.name == "sjump_forward"
      or current_attack.name == "sjump_neutral"
      or current_attack.name == "sjump_back"
      then
        _, _startup = find_frame_data_by_name(_player.char_str, "sjump_startup")
      end
      current_attack.initial_jump_offset = #_startup.frames + 2
      landing_recording.act_offset = 0
    elseif current_landing_category.name == "jumping_normals" then
      -- current_attack = deepcopy(landing_j_normals[i_landings])
        current_attack = {name = "uf_HP"}

        local _sequence = {{"up","forward"},{"up","forward"},{"up","forward"},{},{},{}}
        current_attack.sequence = _sequence
        landing_recording.sequence = {{"HP"}}
        current_attack.offset = #landing_recording.sequence
        landing_recording.act_offset = #landing_recording.sequence
    end
    local _key, _fd = find_frame_data_by_name(_player.char_str, current_attack.name)
    if _fd then
      landing_recording.animation = _key
      landing_recording.max_frames = #_fd.frames
    else
      print(current_attack.name, "framedata not found")
    end

    print(current_attack.name)
    setup_landing_state(_player, current_attack.sequence, current_attack.initial_jump_offset)
    n_no_data = 0
    _state = "setting_up"
  end

  if _state == "next_landing_frame" then
    if landing_recording.frame <= 1 then
      table.insert(after_load_state_callback, {command = queue_landing_move, args = {landing_recording.sequence}})
    end
    landing_recording.frame = landing_recording.frame + 1
    landing_recording.act_frame_number = landing_recording.act_frame_number + 1
    table.insert(after_load_state_callback, {command = landing_reset_player_pos})
    table.insert(after_load_state_callback, {command = increment_landing_ss})
    savestate.load(landing_ss)
    _state = "setting_up"
  end

  if _state == "setup_landing" then
    if landing_recording.frame == 0 then
      table.insert(after_load_state_callback, {command = queue_landing_move, args = {landing_recording.sequence}})
      table.insert(after_load_state_callback, {command = landing_write_player_pos_y, args = {landing_height} })
      table.insert(after_load_state_callback, {command = landing_queue_guess})
      -- table.insert(after_load_state_callback, {command = print_info})

      savestate.load(landing_ss)
      _state = "wait_for_setup"
    else
      table.insert(after_load_state_callback, {command = landing_write_player_pos_y, args = {landing_height} })
      table.insert(after_load_state_callback, {command = landing_queue_guess})
      -- table.insert(after_load_state_callback, {command = print_info})
      savestate.load(landing_ss)
      _state = "wait_for_setup"
    end
  end

  if _state == "finished_guess" then
    if hi - 1 == 0 then
      n_no_data = n_no_data + 1
    else
      n_no_data = 0
    end
    if n_no_data > 15 then
      i_landings = i_landings + 1
      _state = "queue_move"
      return
    end
    -- frame_data[_player.char_str][landing_recording.animation].frames[landing_recording.frame].landing = -hi
    print(current_attack.name, landing_recording.frame, hi - 1, P1.animation, P1.animation_frame_hash)
    lo, hi = -100, 60
    landing_height = hi
    if landing_recording.frame < landing_recording.max_frames then
      _state = "next_landing_frame"
    else
      i_landings = i_landings + 1
      _state = "queue_move"
    end
  end
end

landing_ss = savestate.create("data/"..rom_name.."/savestates/landing.fs")

function setup_landing_state(_player, _sequence, _jump_offset)
  queue_input_sequence(_player, _sequence)
  write_pos(_player, 400, 0)
  queue_command(frame_number + _jump_offset - 1 - 1, {command = clear_motion_data, args={_player}})
  queue_command(frame_number + _jump_offset - 1 - 1, {command = write_pos, args={_player, 400, 100}})
  queue_command(frame_number + _jump_offset - 1, {command = savestate.save, args={landing_ss}})
  queue_command(frame_number + _jump_offset - 1, {command = function() print("save ss", frame_number) end})
  queue_command(frame_number + _jump_offset, {command = function() _state = "setup_landing" end})
  landing_recording.act_frame_number = frame_number + _jump_offset
  print(frame_number, landing_recording.act_frame_number)
end

function print_info()
  print(">", frame_number, P1.animation, P1.animation_frame_hash)
end


function landing_write_player_pos_y(_y)
  clear_motion_data(P1)
  write_pos_y(P1, _y)
end

function landing_reset_player_pos()
  clear_motion_data(P1)
  write_pos(P1, 400, 100)
end

function landing_queue_guess()
  queue_command(frame_number + landing_recording.act_offset + 1, {command = guess_landing_height})
end

function increment_landing_ss()
  savestate.save(landing_ss)
  queue_command(frame_number + 1, {command = function() _state = "setup_landing" end})
  -- queue_command(frame_number + _delta + 1, {command = function() print("save ss", frame_number) end})
end

function landing_queue_write_pos(_val)
  local _delta = landing_recording.act_frame_number - frame_number
  queue_command(_delta, {command = write_pos, args={P1, _val}})
end

function queue_landing_move(_sequence)
  queue_input_sequence(P1, _sequence)
end


function guess_landing_height()
  local _player = P1
  local result = _player.posture == 0
  if result then
    lo = landing_height
  else
    hi = landing_height
  end
  if hi - lo == 1 then
    _state = "finished_guess"
    return true
  end
  if lo <= hi then
    landing_height = lo + math.floor((hi - lo) / 2)
  end
  _state = "setup_landing"
  return false
end

function queue_guess_landing_height()
  queue_command(frame_number + 1, {command = guess_landing_height})
end


function record_attacks(_player_obj, _projectiles)
  if is_in_match and debug_settings.record_framedata then
    _player = _player_obj
    _dummy = _player_obj.other

    function has_projectiles(_p)
      for _id, _obj in pairs(_projectiles) do
        if _obj.emitter_id == _p.id then
          return true
        end
      end
      return false
    end

    _far_dist = character_specific[_player.char_str].half_width + 80
    _close_dist = character_specific[_player.char_str].half_width + character_specific[_dummy.char_str].half_width

    if _player.is_idle then
      if _setup then
        if recording then
          if _player.has_animation_just_changed and _player.action == 0 then
            end_recording(_player, _projectiles, _name)
          end
        end
      end
    elseif _state == "wait_for_initial_anim" and _player.has_animation_just_changed then
      if _player.is_attacking or _player.is_throwing then
        new_recording(_player, _projectiles, _name)
        _state = "new_recording"

  --     elseif _player.pending_input_sequence == nil then
  --       print("----->", _player.animation)
      elseif current_attack.name and current_attack.name == "pa" then
        new_recording(_player, _projectiles, _name)
        _state = "new_recording"
      end
    elseif recording then
      if _player.has_animation_just_changed then
        new_animation(_player, _projectiles, _name)
      end
    end
    if _state == "ready" then
      if has_projectiles(_player) then
        _state = "wait_for_projectiles"
      elseif _dummy.is_idle then
        _state = "update_hit_state"
      end
    elseif _state == "wait_for_projectiles" then
      if not has_projectiles(_player) and _dummy.is_idle then
        _state = "update_hit_state"
      end
    elseif _state == "wait_for_match_start" then
      if has_match_just_started then
        _state = "queue_move"
      end
    end

    if not _setup and _state == "start" and is_in_match then
      _setup = true
      _state = "ready"
      local _moves = deepcopy(move_list[_player.char_str])
      local i = 1
      specials = {}
      supers = {}
      block_pattern = nil
      while i <= #_moves do
        if _moves[i].air and _moves[i].air == "yes" then
          _moves[i].air = nil
          local _move = deepcopy(_moves[i])
          _move.air = "only"
          _move.name = _move.name .. "_air"
          table.insert(_moves, i + 1, _move)
        end
        if _moves[i].move_type == "special" then
          if _moves[i].name == "tsumuji" then
            local _move = deepcopy(_moves[i])
            _move.name = "tsumuji_low"
            table.insert(_moves, i + 1, _move)
          elseif _moves[i].name == "ducking" then
            local _move = deepcopy(_moves[i])
            _move.name = "ducking_upper"
            table.insert(_moves, i + 1, _move)
            _move = deepcopy(_moves[i])
            _move.name = "ducking_straight"
            table.insert(_moves, i + 1, _move)
          elseif _moves[i].name == "hyakki" then
            local _move = deepcopy(_moves[i])
            _move.name = "hyakki_kick"
            table.insert(_moves, i + 1, _move)
            _move = deepcopy(_moves[i])
            _move.name = "hyakki_punch"
            table.insert(_moves, i + 1, _move)
            _move = deepcopy(_moves[i])
            _move.name = "hyakki_throw"
            table.insert(_moves, i + 1, _move)
          elseif _moves[i].name == "hayate" then
            local _move = deepcopy(_moves[i])
            _move.name = "hayate_3"
            table.insert(_moves, i + 1, _move)
            _move = deepcopy(_moves[i])
            _move.name = "hayate_2"
            table.insert(_moves, i + 1, _move)
            _move = deepcopy(_moves[i])
            _move.name = "hayate_1"
            table.insert(_moves, i + 1, _move)
          elseif _moves[i].name == "dashing_head_attack" then
            local _move = deepcopy(_moves[i])
            _move.name = "dashing_head_attack_high"
            table.insert(_moves, i + 1, _move)
          elseif _moves[i].name == "tourouzan" then
            local _move = deepcopy(_moves[i])
            _move.name = "tourouzan_2"
            table.insert(_moves, i + 1, _move)
            _move = deepcopy(_moves[i])
            _move.name = "tourouzan_3"
            table.insert(_moves, i + 2, _move)
          elseif _moves[i].name == "byakko" then
            _moves[i].buttons = {"LP","EXP"}
          elseif _moves[i].name == "kobokushi" then
            _moves[i].buttons = {"LP","EXP"}
          end
          if #_moves[i].buttons > 0 then
            for j = 1, #_moves[i].buttons do
              table.insert(specials, {})
              specials[#specials].air = _moves[i].air
              specials[#specials].button = _moves[i].buttons[j]
              specials[#specials].input = deepcopy(_moves[i].input)
              specials[#specials].name = _moves[i].name
              if _moves[i].name == "tourouzan_3" and _moves[i].buttons[j] == "EXP" then
                local _move = deepcopy(_moves[i])
                _move.name = "tourouzan_4"
                _move.buttons = {"EXP"}
                table.insert(_moves, i + 1, _move)
                _move = deepcopy(_moves[i])
                _move.name = "tourouzan_5"
                _move.buttons = {"EXP"}
                table.insert(_moves, i + 2, _move)
              end
            end
          else
            table.insert(specials, {})
            specials[#specials].name = _moves[i].name
            specials[#specials].air = _moves[i].air
            specials[#specials].button = nil
            specials[#specials].input = deepcopy(_moves[i].input)
          end
        elseif _moves[i].move_type == "sa1"
        or _moves[i].move_type == "sa2"
        or _moves[i].move_type == "sa3"
        or _moves[i].move_type == "sgs"
        or _moves[i].move_type == "kkz" then
          if _moves[i].name == "hammer_mountain" then
            local _move = deepcopy(_moves[i])
            _move.name = "hammer_mountain_miss"
            table.insert(_moves, i + 1, _move)
          end
          if #_moves[i].buttons > 0 then
            for j = 1, #_moves[i].buttons do
              table.insert(supers, {})
              supers[#supers].air = _moves[i].air
              supers[#supers].button = _moves[i].buttons[j]
              supers[#supers].input = deepcopy(_moves[i].input)
              supers[#supers].name = _moves[i].name
              supers[#supers].move_type = _moves[i].move_type
            end
          else
            table.insert(supers, {})
            supers[#supers].name = _moves[i].name
            supers[#supers].move_type = _moves[i].move_type
            supers[#supers].air = _moves[i].air
            supers[#supers].button = nil
            supers[#supers].input = deepcopy(_moves[i].input)
          end
        end

        i = i + 1
      end
      if _player.char_str == "gill" then
        local _ressurection = table.remove(supers, 1)
        table.insert(supers, _ressurection)
      elseif _player.char_str == "oro" then
        local _move = deepcopy(supers[1])
        _move.name = "kishinriki_activation"
        _move.button = nil
        _move.input[#_move.input] = {"forward","LP"}
        table.insert(supers, 1, _move)
      elseif _player.char_str == "q" then
        local _move = deepcopy(supers[3])
        _move.name = "total_destruction_activation"
        _move.button = nil
        _move.input[#_move.input] = {"forward","LP"}
        table.insert(supers, 3, _move)
        local _move = supers[4]
        _move.name = "total_destruction_attack"
        _move.button = nil
        _move.input = {{"down"},{"down","forward"},{"forward","LP"}}
        local _move = deepcopy(supers[4])
        _move.name = "total_destruction_throw"
        _move.button = nil
        _move.input = {{"down"},{"down","forward"},{"forward","LK"}}
        table.insert(supers, _move)
      elseif _player.char_str == "ryu" then
        local _move = deepcopy(supers[3])
        _move.name = "denjin_hadouken_2"
        local n = 30
        for j = 1, n do
          table.insert(_move.input, {"LP","down","forward"})
          table.insert(_move.input, {"LP","down","back"})
        end
        table.insert(supers, _move)
        _move = deepcopy(supers[3])
        _move.name = "denjin_hadouken_3"
        n = 35
        for j = 1, n do
          table.insert(_move.input, {"LP","down","forward"})
          table.insert(_move.input, {"LP","down","back"})
        end
        table.insert(supers, _move)
        _move = deepcopy(supers[3])
        _move.name = "denjin_hadouken_4"
        n = 45
        for j = 1, n do
          table.insert(_move.input, {"LP","down","forward"})
          table.insert(_move.input, {"LP","down","back"})
        end
        table.insert(supers, _move)
        _move = deepcopy(supers[3])
        _move.name = "denjin_hadouken_5"
        n = 65
        for j = 1, n do
          table.insert(_move.input, {"LP","down","forward"})
          table.insert(_move.input, {"LP","down","back"})
        end
        table.insert(supers, _move)
      end


      normals = normals_list[_player.char_str]
      other_normals = other_normals_list[_player.char_str]
      target_combos = target_combos_list[_player.char_str]
      attack_categories ={
        {name = "normals", list = normals},
        {name = "jumping_normals", list = jumping_normals},
        {name = "other_normals", list = other_normals},
        {name = "target_combos", list = target_combos},
        {name = "throw_uoh_pa", list = throw_uoh_pa},
        {name = "specials", list = specials},
        {name = "supers", list = supers}}
      _state = "queue_move"
    end

    if _dummy.char_str ~= "urien" then
      _state = "wait_for_match_start"
      table.insert(after_load_state_callback, {command = force_select_character, args = {_player.id, _player.char_str, 1, "LP"} })
      table.insert(after_load_state_callback, {command = force_select_character, args = {_dummy.id, "urien", 1, "MP"} })
      start_character_select_sequence()
      return
    end

    if _state == "queue_move" then
      if i_attacks <= #attack_categories[i_attack_categories].list then
        current_attack_category = attack_categories[i_attack_categories]
      else
        if i_attack_categories >= last_category--#attack_categories
        and (i_recording_hit_types == #recording_hit_types or current_attack_category.name == "supers") then
          _state = "finished"
          i_attacks = 1
          i_attack_categories = 1
          i_recording_hit_types = 1
          current_attack_category = {}
          received_hits = 0
          block_until = 0
          block_max_hits = 0
          make_invulnerable(_dummy, false)
          return
        end
        if i_recording_hit_types < #recording_hit_types then
          i_recording_hit_types = i_recording_hit_types + 1
          i_attacks = 1
        else
          i_attack_categories = i_attack_categories + 1
          i_recording_hit_types = 1
          i_attacks = 1
          current_attack_category = attack_categories[i_attack_categories]
        end
        if #attack_categories[i_attack_categories].list == 0 then
          i_attack_categories = i_attack_categories + 1
          _state = "queue_move"
          return
        end
        return
      end
      _state = "wait_for_initial_anim"

      recording_options = {hit_type = recording_hit_types[i_recording_hit_types]}

      received_hits = 0
      block_max_hits = 0

      if current_attack_category.name == "normals" then
        current_attack = deepcopy(normals[i_attacks])
        current_attack.name = sequence_to_name(current_attack.sequence)
        current_attack.reset_pos_x = _reset_pos_x
        _dummy_offset_x = _far_dist
        _dummy_offset_y = 0
        if not (recording_options.hit_type == "miss") then
          _dummy_offset_x = _close_dist
          if current_attack.far then
            _dummy_offset_x = _far_dist
          end
        end
        if recording_geneijin then
          if current_attack.self_chain then
            current_attack.delay = {2}
          end
        end
      elseif current_attack_category.name == "other_normals" then
        current_attack = deepcopy(other_normals[i_attacks])
        if not current_attack.name then
          current_attack.name = sequence_to_name(current_attack.sequence)
          if current_attack.air then
            current_attack.name = current_attack.name .. "_air"
          end
          if string.len(current_attack.name) == 2 then
            current_attack.name = "cl_" .. current_attack.name
          end
        end
        current_attack.reset_pos_x = _reset_pos_x
        _dummy_offset_x = _close_dist
        _dummy_offset_y = 0
        if not (recording_options.hit_type == "miss") then
          _dummy_offset_x = _close_dist
        end

        local _sequence = current_attack.sequence

        if player.char_str == "chunli" then
          if current_attack.name == "cl_MK" then
            current_attack.hits_appear_after_block = true
            block_max_hits = 2
            local _n = 0
            _n = 22 * block_until
            if recording_options.hit_type == "block" then
              _n = _n + 14
            end
            for i = 1, _n do
              table.insert(_sequence, {"MK"})
            end
          elseif current_attack.name == "d_MK_air" and recording_options.hit_type == "block" then
            current_attack.offset_x = -30
            queue_command(frame_number + #_sequence, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 5, 0}})
          elseif current_attack.name == "d_HP_air" and recording_options.hit_type == "block" then
            queue_command(frame_number + #_sequence+10, {command = write_pos_y, args={_player, 40}})
          end
        elseif player.char_str == "hugo" then
          if current_attack.name == "d_HP_air" and recording_options.hit_type == "block" then
            queue_command(frame_number + #_sequence + 8, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 20, 0}})
          end
        elseif player.char_str == "ken" then
          if current_attack.name == "MK_hold" then
            current_attack.hits_appear_after_block = true
            block_max_hits = 2
            local _n = 0
            _n = 22 * block_until
            if recording_options.hit_type == "block" then
              _n = _n + 14
            end
            for i = 1, _n do
              table.insert(_sequence, {"MK"})
            end
          elseif current_attack.name == "f_HK_hold" then
            local _n = 10
            for i = 1, _n do
              table.insert(_sequence, {"forward","HK"})
            end
          end
        elseif player.char_str == "makoto" then
          if current_attack.name == "f_HK_hold" then
            local _n = 20
            for i = 1, _n do
              table.insert(_sequence, {"forward","HK"})
            end
          end
        elseif player.char_str == "yang" or player.char_str == "yun" then
          if current_attack.name == "raigeki_LK" and recording_options.hit_type == "block" then
            queue_command(frame_number + #_sequence + 20, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 30, 0}})
          end
        end
        if current_attack.max_hits == 0 and recording_options.hit_type == "block" then
          i_attacks = i_attacks + 1
          _state = "queue_move"
          return
        end
        if recording_geneijin then
          if current_attack.self_chain then
            current_attack.delay = {2}
          end
        end
      elseif current_attack_category.name == "jumping_normals" then
        current_attack = {}
        _dummy_offset_x = _close_dist
        _dummy_offset_y = 0
        recording_options.ignore_next_anim = true
        if not (recording_options.hit_type == "miss") then
          _dummy_offset_x = _close_dist
        end
        local _sequence = {}
        local _button = jumping_normals[i_attacks][1][1]
        if i_attacks <= 6 then
          _name = "u_" .. _button
          current_attack.jump_dir = "neutral"
        elseif i_attacks <= 12 then
          _name = "uf_" .. _button
          current_attack.jump_dir = "forward"
        else
          _name = "ub_" .. _button
          current_attack.jump_dir = "back"
        end
        _sequence = deepcopy(jumping_normals[i_attacks])
        current_attack.name = _name

        current_attack.sequence = _sequence
        current_attack.air = true
        current_attack.reset_pos_x = _reset_pos_x


        if player.char_str == "alex" then
          if _button == "LK" and recording_options.hit_type == "block" then
            current_attack.offset_x = -4
          end
        end
        if player.char_str == "elena" then
          if _button == "LP" and recording_options.hit_type == "block" then
            queue_command(frame_number + #_sequence + 10, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 30, 0}})
          elseif _button == "HK" then
            current_attack.max_hits = 2
          end
        end
        if player.char_str == "necro" then
          if _button == "MK" then
            current_attack.player_offset_y = -10
          elseif _button == "LP" and current_attack.jump_dir == "neutral" then
            current_attack.player_offset_y = -14
          elseif _button == "MP" and current_attack.jump_dir == "neutral" then
            current_attack.player_offset_y = -14
          end
        end
        if player.char_str == "oro" then
          if (_button == "LK" or _button == "MK") and recording_options.hit_type == "block" then
            queue_command(frame_number + #_sequence + 10, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 30, 0}})
          elseif _button == "HP" and not (current_attack.jump_dir == "neutral") then
            current_attack.offset_x = -12
            current_attack.max_hits = 2
          end
        end
        if player.char_str == "ryu" then
          if _button == "MP" and not (current_attack.jump_dir == "neutral") then
            current_attack.player_offset_y = -24
            current_attack.max_hits = 2
          elseif _button == "HP" and current_attack.jump_dir == "neutral" then
            current_attack.player_offset_y = -10
          end
        end
        if player.char_str == "shingouki" then
          if _button == "MK" then
            current_attack.player_offset_y = -14
          end
        end
        if player.char_str == "twelve" then
          if _button == "MP" or _button == "MK" then
            current_attack.player_offset_y = -14
          elseif _button == "HK" then
            queue_command(frame_number + #_sequence + 10, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 30, 0}})
          end
        end
        if player.char_str == "yang" or player.char_str == "yun" then
          if _button == "LP" then
            queue_command(frame_number + #_sequence + 10, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 30, 0}})
          end
        end
      elseif current_attack_category.name == "target_combos" then
        _state = "setup_target_combo"
        recording_options.target_combo = true
        recording_options.record_frames_after_hit = true
--         if i_attacks <= #target_combos then
        current_attack = deepcopy(target_combos[i_attacks])
        current_attack.name = current_attack.name or "tc_" .. tostring(i_attacks)
        
        
        if recording_geneijin then
          _name = current_attack.name .. "_geneijin"
        end

        _name = current_attack.name

        if recording_geneijin and current_attack.name ~= "tc_6" then
          i_attacks = i_attacks + 1
          _state = "queue_move"
          return
        end



        print(current_attack.name)
        tc_hit_index = 1
        received_hits = 0
        block_max_hits = current_attack.max_hits
        if recording_options.hit_type == "miss" then
          block_max_hits = current_attack.max_hits - 1
        else
          block_until = current_attack.max_hits
        end
        block_pattern = nil
        if current_attack.block then
          block_pattern = current_attack.block
        end

        current_attack.reset_pos_x = _reset_pos_x

        _dummy_offset_x = _close_dist
        _dummy_offset_y = 0

        if current_attack.far then
          _dummy_offset_x = _far_dist
        end
        if current_attack.offset_x then
          _dummy_offset_x = _dummy_offset_x + current_attack.offset_x
        end

        if current_attack.dummy_offset_list then
          local _index = received_hits + 1
          if _index <= #current_attack.dummy_offset_list then
            _dummy_offset_x = current_attack.dummy_offset_list[_index][1]
            _dummy_offset_y = current_attack.dummy_offset_list[_index][2]
          end
        end


        local _player_offset_y = current_attack.player_offset_y or 0

        make_invulnerable(_dummy, false)
        clear_motion_data(_player)

        if current_attack.air then
          recording_options.air = true
          local _sequence = {{"up","forward"},{"up","forward"},{},{},{},{}}
          if(is_slow_jumper(_player.char_str)) then
            table.insert(_sequence,#_sequence,{})
          elseif is_really_slow_jumper(_player.char_str) then
            table.insert(_sequence,#_sequence,{})
            table.insert(_sequence,#_sequence,{})
          end
          table.insert(_sequence,current_attack.sequence[1])
          current_attack.attack_start_frame = #_sequence

          queue_input_sequence(_player, _sequence)
          queue_command(frame_number + current_attack.attack_start_frame + 100, {command = land_player, args={_player}})
          queue_command(frame_number + current_attack.attack_start_frame, {command = clear_motion_data, args={_player}})
          queue_command(frame_number + current_attack.attack_start_frame, {command = write_pos, args={_player, current_attack.reset_pos_x, _default_air_block_height + _player_offset_y}})
          write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0)
        else
          write_pos(_player, current_attack.reset_pos_x, 0)
          write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0)
--               queue_command(frame_number + 2, {command = queue_input_sequence, args={current_attack.sequence[1]}})
          queue_input_sequence(_player, {current_attack.sequence[1]})
        end

        if overwrite and first_record then
          recording_options.clear_frame_data = true
          first_record = false
        end

        _state = "wait_for_initial_anim"
      elseif current_attack_category.name == "throw_uoh_pa" then
        current_attack = deepcopy(throw_uoh_pa[i_attacks])
        current_attack.reset_pos_x = _reset_pos_x
        local _sequence = current_attack.sequence
        current_attack.attack_start_frame = #_sequence

        _dummy_offset_x = _far_dist
        _dummy_offset_y = 0
        if not (recording_options.hit_type == "miss") then
          _dummy_offset_x = _close_dist - character_specific[_dummy.char_str].half_width
          if current_attack.far then
            _dummy_offset_x = _far_dist
          end
        end
        if recording_options.hit_type == "miss" then
          if current_attack.name == "throw_forward" or current_attack.name == "throw_back" then
            i_attacks = i_attacks + 1
            _state = "queue_move"
            return
          end
        end

        if current_attack.name == "throw_neutral"
        or current_attack.name == "throw_forward"
        or current_attack.name == "throw_back" then
          current_attack.throw = true
          if recording_options.hit_type == "block" then
            for i = 1, 6 do
              table.insert(_sequence, 1, {})
            end
          end
        end

        if current_attack.name == "pa" then
          current_attack.max_hits = 0
        end
        if _player.char_str == "alex" then
          if current_attack.name == "pa" then
            for i = 1, 80 do
              table.insert(_sequence, {"HP","HK"})
            end
            recording_options.infinite_loop = true
          end
        end
        if _player.char_str == "chunli" then
          if current_attack.name == "pa" then
            for i = 1, 60 do
              table.insert(_sequence, {"HP","HK"})
            end
          end
        end
        if _player.char_str == "dudley" then
          if current_attack.name == "pa" then
            current_attack.is_projectile = true
            current_attack.max_hits = 1
            current_attack.offset_x = 150
          end
        end
        if _player.char_str == "elena" then
          if current_attack.name == "pa" then
            current_attack.max_hits = 1
            current_attack.block = {2,1}
          end
        end
        if _player.char_str == "hugo" then
          if current_attack.name == "pa" then
            for i = 1, 80 do
              table.insert(_sequence, {"HP","HK"})
            end
          end
        end
        if _player.char_str == "ibuki" then
          if current_attack.name == "pa" then
            current_attack.max_hits = 1
          end
        end
        if _player.char_str == "ken" then
          if current_attack.name == "pa" then
            current_attack.max_hits = 2
          end
        end
        if _player.char_str == "makoto" then
          if current_attack.name == "pa" then
            for i = 1, 250 do
              table.insert(_sequence, {"HP","HK"})
            end
            if recording_options.hit_type == "block" then
              for i = 1, 20 do
                table.insert(_sequence, {"HP","HK"})
              end
            end
            current_attack.max_hits = 1
          end
        end
        if _player.char_str == "necro" then
          if current_attack.name == "pa" then
            for i = 1, 60 do
              table.insert(_sequence, {"HP","HK"})
            end
            if recording_options.hit_type == "block" then
              for i = 1, 60 do
                table.insert(_sequence, {"HP","HK"})
              end
            end
            recording_options.infinite_loop = true
            current_attack.max_hits = 6
          end
        end
        if _player.char_str == "sean" then
          if current_attack.name == "pa" then
            current_attack.is_projectile = true
            current_attack.max_hits = 1
            current_attack.offset_x = 150
          end
        end
        if _player.char_str == "urien" then
          if current_attack.name == "pa" then
            current_attack.max_hits = 1
            current_attack.block = {2}
          end
        end
        if _player.char_str == "yang" then
          if current_attack.name == "pa" then
            current_attack.max_hits = 1
          end
        end
        if _player.char_str == "yun" then
          if current_attack.name == "pa" then
            for i = 1, 120 do
              table.insert(_sequence, {"HP","HK"})
            end
            if recording_options.hit_type == "block" then
              for i = 1, 100 do
                table.insert(_sequence, {"HP","HK"})
              end
            end
            recording_options.infinite_loop = true
            current_attack.max_hits = 6
          end
        end

        if current_attack.name == "pa" and recording_options.hit_type == "block" then
          if current_attack.max_hits == 0 then
            i_attacks = i_attacks + 1
            _state = "queue_move"
            return
          end
        end

        current_attack.sequence = _sequence
      elseif current_attack_category.name == "specials" then
        current_attack = deepcopy(specials[i_attacks])
        local _base_name = current_attack.name
        local _button = current_attack.button
        local _sequence = current_attack.input
        current_attack.attack_start_frame = #_sequence
        current_attack.base_name = _base_name


        if _button then
          current_attack.name = current_attack.name .. "_" .. _button
        end

        _dummy_offset_x = _close_dist
        _dummy_offset_y = 0

        if current_attack.air and current_attack.air == "only" then
          current_attack.land_after = 100
        end

        current_attack.reset_pos_x = _reset_pos_x

        local i = 1
        while i <= #_sequence do
          local j = 1
          while j <= #_sequence[i] do
            if _sequence[i][j] == "button" then
              if _button == "EXP"  then
                table.remove(_sequence[i], j)
                table.insert(_sequence[i], j, "LP")
                table.insert(_sequence[i], j, "MP")
              elseif _button == "EXK"  then
                table.remove(_sequence[i], j)
                table.insert(_sequence[i], j, "LK")
                table.insert(_sequence[i], j, "MK")
              else
                table.remove(_sequence[i], j)
                table.insert(_sequence[i], j, _button)
              end
            end
            j = j + 1
          end
          i = i + 1
        end

        if _base_name == "hyakuretsukyaku" then
          if _button == "EXK"  then
            _sequence = {{"legs_" .. _button, "LK", "MK"}}
          else
            _sequence = {{"legs_" .. _button, _button}}
          end
        end


        if _player.char_str == "alex" then
          if _base_name == "flash_chop" then
            if _button == "EXP"  then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "air_knee_smash" then
            _dummy_offset_y = 100
            current_attack.max_hits = 0
            current_attack.throw = true
            if _button == "HK" then
              _dummy_offset_y = 120
            elseif _button == "EXK" then
              current_attack.max_hits = 1
              _dummy_offset_x = 80
              _dummy_offset_y = 0
            end
          end
          if _base_name == "air_stampede" then
            if _button == "MK" then
              _dummy_offset_x = 120
            elseif _button == "HK" then
              _dummy_offset_x = 150
            elseif _button == "EXK" then
              _dummy_offset_x = 120
            end
          end
          if _base_name == "slash_elbow" then
            _dummy_offset_x = 120
            if _button == "EXK" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "spiral_ddt" then
            current_attack.name = _base_name
          end
          if _base_name == "power_bomb" or _base_name == "spiral_ddt" then
            current_attack.throw = true
            if _base_name == "spiral_ddt" then
              if _button == "HK" then
                _dummy_offset_x = 160
              end
            end
          end
        end

        if _player.char_str == "chunli" then
          if _base_name == "hyakuretsukyaku" then
            if _button == "LK" then
              _n = 40
              current_attack.max_hits = 16
            elseif _button == "MK" then
              _n = 40
              current_attack.max_hits = 20
            elseif _button == "HK" then
              _n = 30
              current_attack.max_hits = 16
            elseif _button == "EXK" then
              _n = 30
              current_attack.max_hits = 16
            end

            if recording_options.hit_type == "block" then
              _n = _n * 5
            end

            for i = 1, _n do
              table.insert(_sequence, {})
              if _button == "EXK" then
                table.insert(_sequence, {"LK","MK"})
              else
                table.insert(_sequence, {_button})
              end
            end
          end
          if _base_name == "kikouken" then
            _dummy_offset_x = 150
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
          end
          if _base_name == "spinning_bird_kick" then
            _dummy_offset_x = 80
            if _button == "LK" then
              current_attack.max_hits = 4
            elseif _button == "MK" then
              current_attack.max_hits = 6
            elseif _button == "HK" then
              current_attack.max_hits = 8
            elseif _button == "EXK" then
              current_attack.max_hits = 5
              current_attack.dummy_offset_list = {{80,0},{-80,0},{80,0},{-80,0},{80,0}}
            end
          end
          if _base_name == "hazanshuu" then
            _dummy_offset_x = 80
            if _button == "LK" then
            elseif _button == "MK" then
              _dummy_offset_x = 100
            elseif _button == "HK" then
              _dummy_offset_x = 150
            end
          end
        end

        if _player.char_str == "dudley" then
          if _base_name == "jet_upper" then
            _dummy_offset_x = 80
            if _button == "HP" or _button == "EXP" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "ducking" then
            _dummy_offset_x = 150
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "ducking_straight" then
            current_attack.name = _base_name
            local _n = 10
            if _button == "LK" then
            _n = 10
            elseif _button == "MK" then
              _n = 10
            elseif _button == "HK" then
              _n = 15
            end

            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"HP"})
            _dummy_offset_x = 100
            current_attack.max_hits = 1
          end
          if _base_name == "ducking_upper" then
            current_attack.name = _base_name
            local _n = 10
            if _button == "LK" then
            _n = 10
            elseif _button == "MK" then
              _n = 10
            elseif _button == "HK" then
              _n = 15
            end
            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"HK"})
            _dummy_offset_x = 100
            current_attack.max_hits = 2
          end
          if _base_name == "machinegun_blow" then
            _dummy_offset_x = 100
            if _button == "LP" then
              current_attack.max_hits = 3
            elseif _button == "MP" then
              current_attack.max_hits = 4
            elseif _button == "HP" then
              current_attack.max_hits = 6
            elseif _button == "EXP" then
              current_attack.max_hits = 7
            end
          end
          if _base_name == "cross_counter" then
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "short_swing_blow" then
            if _button == "EXK" then
              current_attack.max_hits = 3
            end
          end
        end
        if _player.char_str == "elena" then
          if _base_name == "scratch_wheel" then
            if _button == "LK" then
              current_attack.max_hits = 1
            elseif _button == "MK" then
              current_attack.max_hits = 2
            elseif _button == "HK" then
              current_attack.max_hits = 3
            elseif _button == "EXK" then
              current_attack.max_hits = 4
            end
          end
          if _base_name == "rhino_horn" then
            if _button == "LK" then
              current_attack.max_hits = 3
            elseif _button == "MK" then
              current_attack.max_hits = 3
            elseif _button == "HK" then
              current_attack.max_hits = 3
            elseif _button == "EXK" then
              current_attack.max_hits = 4
            end
          end
          if _base_name == "mallet_smash" then
            _dummy_offset_x = 100
            current_attack.max_hits = 2
          end
          if _base_name == "spin_sides" then
            _dummy_offset_x = 100
            current_attack.max_hits = 4
            current_attack.optional_anim = {0,0,1,0}
            if _button == "EXK" then
              current_attack.max_hits = 5
              current_attack.optional_anim = {0,0,0,0,1}
            end
            local _n = 30
            if recording_options.hit_type == "block" then
              _n = 60
            end
            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"down"})
            table.insert(_sequence, {"down","back"})
            table.insert(_sequence, {"back"})
            if _button == "EXK" then
              table.insert(_sequence, {"LK","MK"})
            else
              table.insert(_sequence, {_button})
            end

          end
          if _base_name == "lynx_tail" then
            if _button == "LK" then
              current_attack.max_hits = 2
              current_attack.block = {2,2}
            elseif _button == "MK" then
              current_attack.max_hits = 2
              current_attack.block = {2,2}
            elseif _button == "HK" then
              current_attack.max_hits = 4
              current_attack.block = {2,2,2,2}
            elseif _button == "EXK" then
              current_attack.max_hits = 5
              current_attack.block = {2,2,2,2,1}
            end
          end
        end

        if _player.char_str == "gill" then
          if _base_name == "pyrokinesis" then
            current_attack.max_hits = 2
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            _dummy_offset_x = 80
            if _button == "LP" then
              _dummy_offset_x = 120
            elseif _button == "HP" then
              _dummy_offset_x = 100
              if recording_options.hit_type == "block" then
                current_attack.projectile_offset = {0, -50}
              end
            end
          end
          if _base_name == "cyber_lariat" then
            current_attack.max_hits = 2
            _dummy_offset_x = 100
          end
          if _base_name == "moonsault_kneedrop" then
            current_attack.max_hits = 2
            block_max_hits = 1
            current_attack.hits_appear_after_block = true
            _dummy_offset_x = 70
            queue_command(frame_number + 2, {command = write_pos, args={_dummy, _player.pos_x + 250, 0}})
          end
        end

        if _player.char_str == "gouki" then
          if _base_name == "gohadouken" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
          end
          if _base_name == "gohadouken_air" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
          end
          if _base_name == "shakunetsu" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            if _button == "LP" then
              current_attack.max_hits = 1
            elseif _button == "MP" then
              current_attack.max_hits = 2
            elseif _button == "HP" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "goshoryuken" then
            if _button == "LP" then
              current_attack.max_hits = 1
            elseif _button == "MP" then
              current_attack.max_hits = 2
            elseif _button == "HP" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "tatsumaki" then
            if _button == "LK" then
              current_attack.max_hits = 2
              current_attack.dummy_offset_list = {{80,0},{-70,0}}
            elseif _button == "MK" then
              current_attack.max_hits = 5
              current_attack.dummy_offset_list = {{80,0},{80,0},{-70,0},{80,0},{-70,0}}
            elseif _button == "HK" then
              current_attack.max_hits = 9
              current_attack.dummy_offset_list = {{80,0},{80,0},{-70,0},{80,0},{-70,0},{80,0},{-70,0},{80,0},{-70,0}}
            end
          end
          if _base_name == "tatsumaki_air" then
            if _button == "LK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-70,0}}
              current_attack.max_hits = 2
            elseif _button == "MK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-70,0},{80,0},{-70,0}}
              current_attack.max_hits = 4
            elseif _button == "HK" then
              current_attack.player_offset_y = -10
              current_attack.dummy_offset_list = {{80,0},{-70,0},{80,0},{-70,0},{80,0},{-70,0},{80,0},{-70,0},{80,0}}
              current_attack.max_hits = 8
              current_attack.land_after = 120
            end
            if recording_options.hit_type == "block" then
              queue_command(frame_number + 10, {command = clear_motion_data, args={_player}})
            end
          end

          --hyakki only has one animation. button determines the velocity/acceleration applied at the start
          if _base_name == "hyakki" then
            current_attack.name = _base_name
            current_attack.block = {2}
            current_attack.reset_pos_x = 220
            if _button == "MK" then
              _dummy_offset_x = 150
            else
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "hyakki_punch" then
            current_attack.name = _base_name
            if _button == "MK" then
              _dummy_offset_x = 150
            local _n = 20
            for i = 1, _n do
              table.insert(_sequence, {})
            end
              table.insert(_sequence, {"LP"})
            else
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "hyakki_kick" then
            current_attack.name = _base_name
            if _button == "MK" then
              _dummy_offset_x = 150
            local _n = 20
            for i = 1, _n do
              table.insert(_sequence, {})
            end
              table.insert(_sequence, {"LK"})
            else
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "hyakki_throw" then
            current_attack.name = _base_name
            current_attack.throw = true
            if _button == "MK" then
              _dummy_offset_x = 150
            local _n = 20
            for i = 1, _n do
              table.insert(_sequence, {})
            end
              table.insert(_sequence, {"LP","LK"})
            else
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "asura_forward" or _base_name == "asura_backward" then
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
        end

        if _player.char_str == "hugo" then
          if _base_name == "moonsault_press" or _base_name == "ultra_throw" then
            current_attack.throw = true
          end
          if _base_name == "shootdown_backbreaker" then
            current_attack.throw = true
            _dummy_offset_y = 90
            if _button == "HK" then
              _dummy_offset_y = 140
            end
          end
          if _base_name == "meat_squasher" then
            _dummy_offset_x = 100
            current_attack.throw = true
          end
          if _base_name == "giant_palm_bomber" then
            _dummy_offset_x = 120
            if _button == "EXP" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "monster_lariat" then
            _dummy_offset_x = 120
            current_attack.reset_pos_x = 180
            if _button == "EXK" then
              local _n = 60
              for i = 1, _n do
                table.insert(_sequence, {"LK"})
              end
            end
          end
        end

        if _player.char_str == "ibuki" then
          if _base_name == "kunai" then
            current_attack.is_projectile = true
            _dummy_offset_x = 90
            if _button == "MP" or _button == "HP" then
              _dummy_offset_x = 120
            elseif _button == "EXP" then
              current_attack.max_hits = 2
              _dummy_offset_x = 150
            end
          end
          if _base_name == "kubiori" then
            current_attack.block = {2}
            _dummy_offset_x = 100
          end
          if _base_name == "tsumuji" or _base_name == "tsumuji_low" then
            _dummy_offset_x = 100
            if _button == "MK" then
              current_attack.max_hits = 3
              local _n = 30
              if recording_options.hit_type == "block" then
                _n = 50
              end
              for i = 1, _n do
                table.insert(_sequence, {})
                table.insert(_sequence, {_button})
              end
              current_attack.optional_anim = {0,0,1}
              if _base_name == "tsumuji_low" then
                current_attack.block = {1,1,2}
                for i = 5, #_sequence do
                  table.insert(_sequence[i], "down")
                end
              end
            else
              if _button == "LK" then
                current_attack.max_hits = 2
                current_attack.optional_anim = {0,1}
                if _base_name == "tsumuji_low" then
                  current_attack.block = {1,2}
                end
              elseif _button == "HK" then
                current_attack.max_hits = 3
                current_attack.optional_anim = {0,0,1}
                if _base_name == "tsumuji_low" then
                  current_attack.block = {1,1,2}
                end
              elseif _button == "EXK" then
                current_attack.max_hits = 4
                current_attack.optional_anim = {0,1,1,1}
                if _base_name == "tsumuji_low" then
                  current_attack.block = {1,2,2,2}
                end
              end
              if _base_name == "tsumuji_low" then
                local _n = 50
                if recording_options.hit_type == "block" then
                  _n = 120
                end
                if _button == "LK" then
                  if recording_options.hit_type == "block" then
                    _n = 100
                  end
                end
                if _button == "EXK" then
                  if recording_options.hit_type == "block" then
                    _n = 150
                  end
                end
                for i = 1, _n do
                  table.insert(_sequence, {"down"})
                end
              end
            end
          end
          if _base_name == "kazekiri" then
            if _button == "LK" or _button == "MK" then
              current_attack.max_hits = 3
            elseif _button == "HK" or _button == "EXK" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "hien" then
            current_attack.max_hits = 2
            current_attack.hits_appear_after_block = true
            _dummy_offset_x = 100
            block_max_hits = 1
            if _button == "MK" then
              if recording_options.hit_type == "miss" then
                _dummy_offset_x = 140
              end
            elseif _button == "HK" then
              if recording_options.hit_type == "miss" then
                _dummy_offset_x = 100
              end
              queue_command(frame_number + 15, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 250, 0}})
            elseif _button == "EXK" then
              _dummy_offset_x = 80
              queue_command(frame_number + 15, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 100, 0}})
            end
          end
          if _base_name == "tsukijigoe" or _base_name == "kasumigake" then
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
        end

        if _player.char_str == "ken" then
          if _base_name == "hadouken" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "shoryuken" then
            if _button == "LP" then
              current_attack.max_hits = 1
            elseif _button == "MP" then
              current_attack.max_hits = 2
            elseif _button == "HP" then
              current_attack.max_hits = 3
            elseif _button == "EXP" then
              current_attack.max_hits = 4
            end
          end
          if _base_name == "tatsumaki" then
            current_attack.reset_pos_x = 200
            if _button == "LK" then
              current_attack.max_hits = 3
              current_attack.dummy_offset_list = {{80,0},{80,0},{-60,0}}
            elseif _button == "MK" then
              current_attack.max_hits = 6
              current_attack.dummy_offset_list = {{80,0},{80,0},{-60,0},{80,0},{-60,0},{80,0}}
            elseif _button == "HK" then
              current_attack.max_hits = 8
              current_attack.dummy_offset_list = {{80,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0}}
            elseif _button == "EXK" then
              current_attack.max_hits = 10
              current_attack.dummy_offset_list = {{80,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0}}
            end
          end
          if _base_name == "tatsumaki_air" then
            if recording_options.hit_type == "block" then
              queue_command(frame_number + 10, {command = clear_motion_data, args={_player}})
            end
            if _button == "LK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0}}
              current_attack.max_hits = 3
            elseif _button == "MK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0},{-60,0},{80,0}}
              current_attack.max_hits = 5
            elseif _button == "HK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0}}
              current_attack.max_hits = 8
              if recording_options.hit_type == "block" then
                current_attack.land_after = 250
              end
            elseif _button == "EXK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0}}
              current_attack.max_hits = 20
              if recording_options.hit_type == "block" then
                current_attack.land_after = 550
              end
            end
          end
        end

        if _player.char_str == "makoto" then
          if _base_name == "hayate" then -- level 4
            current_attack.name = _base_name
            _dummy_offset_x = 100
            if not (_button == "EXP") then
              current_attack.optional_anim = {1}
              local _n = 120
              for i = 1, _n do
                table.insert(_sequence, {_button})
              end
            end
          end
          if (_base_name == "hayate_3" or _base_name == "hayate_2" or _base_name == "hayate_1") and _button == "EXP" then
            i_attacks = i_attacks + 1
            _state = "queue_move"
            return
          end
          if _base_name == "hayate_3" then
            current_attack.name = _base_name
            _dummy_offset_x = 100
            current_attack.optional_anim = {1}
            local _n = 50
            for i = 1, _n do
              table.insert(_sequence, {_button})
            end
          end
          if _base_name == "hayate_2" then
            current_attack.name = _base_name
            _dummy_offset_x = 100
            current_attack.optional_anim = {1}
            local _n = 30
            for i = 1, _n do
              table.insert(_sequence, {_button})
            end
          end
          if _base_name == "hayate_1" then
            current_attack.name = _base_name
            _dummy_offset_x = 100
            current_attack.optional_anim = {1}
          end
          if _base_name == "fukiage" then
            _dummy_offset_x = 100
            if recording_options.hit_type == "block" then
              if _button == "LP" then
                queue_command(frame_number + 10, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 3, 0}})
              elseif _button == "MP" then
                queue_command(frame_number + 13, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 3, 0}})
              elseif _button == "HP" then
                queue_command(frame_number + 17, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 3, 0}})
              elseif _button == "EXP" then
                queue_command(frame_number + 14, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 73, 0}})
              end
            end
          end

          if _base_name == "karakusa" then
            current_attack.throw = true
          end
          if _base_name == "tsurugi" then
            if _button == "EXK" then
              current_attack.max_hits = 2
              current_attack.land_after = -1
            end
          end
        end

        if _player.char_str == "necro" then
          if _base_name == "denji_blast" then
            local _n = 40
            if _button == "LP" then
              _n = 40
              if recording_options.hit_type == "block" then
                _n = 10
              end
            elseif _button == "MP" then
              _n = 60
              current_attack.max_hits = 21
              if recording_options.hit_type == "block" then
                _n = 240
              end
            else
              _n = 60
              current_attack.max_hits = 41
              if recording_options.hit_type == "block" then
                _n = 480
              end
            end
            for i = 1, _n do
              table.insert(_sequence, {})
              if _button == "EXP" then
                table.insert(_sequence, {"LP","MP"})
              else
                table.insert(_sequence, {_button})
              end
            end
          elseif _base_name == "tornado_hook" then
            current_attack.offset_x = 40
            if _button == "LP" then
              current_attack.max_hits = 2
            elseif _button == "MP" then
              current_attack.max_hits = 2
            elseif _button == "HP" then
              current_attack.offset_x = 70
              current_attack.reset_pos_x = 140
              current_attack.max_hits = 3
            else
              current_attack.offset_x = 85
              current_attack.reset_pos_x = 140
              current_attack.max_hits = 5
            end
          elseif _base_name == "flying_viper" then
            if _button == "LP" then
            elseif _button == "MP" then
              current_attack.offset_x = 80
            elseif _button == "HP" then
              current_attack.offset_x = 80
            elseif _button == "EXP" then
              current_attack.offset_x = 60
              current_attack.max_hits = 2
              current_attack.hits_appear_after_parry = true
              block_max_hits = 1
            end
          elseif _base_name == "rising_cobra" then
            current_attack.offset_x = 20
            if _button == "EXK" then
              current_attack.max_hits = 2
            end
          elseif _base_name == "snake_fang" then
            current_attack.offset_x = 70
            current_attack.block = {2}
            current_attack.throw = true
          end
        end

        if _player.char_str == "oro" then
          if _base_name == "nichirin" then
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            _dummy_offset_x = 80
            if _button == "HP" then
              if recording_options.hit_type == "block" then
                current_attack.projectile_offset = {0, -50}
              end
            elseif _button == "EXP" then
              _dummy_offset_x = 250
              current_attack.max_hits = 2
            end
          end
          if _base_name == "oniyanma" then
            _dummy_offset_x = 80
            if _button == "HP" or _button == "EXP" then
              current_attack.max_hits = 4
              if recording_options.hit_type == "block" then
                _dummy_offset_x = 30
              end
            end
          end
          if _base_name == "hitobashira" then
            current_attack.reset_pos_x = 150
            current_attack.max_hits = 2
            _dummy_offset_x = 65

            if _button == "LK" then
            elseif _button == "MK" then
              queue_command(frame_number + 5, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 160, 0}})
            elseif _button == "HK" then
              queue_command(frame_number + 5, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 200, 0}})
            elseif _button == "EXK" then
              queue_command(frame_number + 5, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 200, 0}})
              current_attack.max_hits = 3
            end
            local _n = 20
            for i = 1, _n do
              table.insert(_sequence, {})
              if _button == "EXK" then
                table.insert(_sequence, {"LK","MK"})
              else
                table.insert(_sequence, {_button})
              end
            end
          end
          if _base_name == "hitobashira_air" then
            current_attack.name = _base_name
            if _button == "EXK" then
              current_attack.name = _base_name .. _button
            end
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 80
            current_attack.max_hits = 2
            current_attack.player_offset_y = 0

            if recording_options.hit_type == "block" then
              _dummy_offset_x = 35
              queue_command(frame_number + 10, {command = clear_motion_data, args={_player}})
            end
            local _n = 20
            for i = 1, _n do
              table.insert(_sequence, {})
              if _button == "EXK" then
                table.insert(_sequence, {"LK","MK"})
              else
                table.insert(_sequence, {_button})
              end
            end
          end
          if _base_name == "niouriki" then
            current_attack.throw = true
          end
        end

        if _player.char_str == "q" then
          if _base_name == "dashing_head_attack" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 80
          end
          if _base_name == "dashing_head_attack_high" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 80
            local _n = 30
            for i = 1, _n do
              table.insert(_sequence, {_button})
            end
            if _button == "EXP" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "dashing_leg_attack" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 80
            current_attack.block = {2}
            if _button == "EXK" then
              current_attack.max_hits = 2
              current_attack.block = {2,2}
            end
          end
          if _base_name == "high_speed_barrage" then
            _dummy_offset_x = 80
            current_attack.max_hits = 3
            if _button == "EXP" then
              current_attack.max_hits = 7
            end
          end
          if _base_name == "capture_and_deadly_blow" then
            _dummy_offset_x = 80
            current_attack.throw = true
          end
        end

        if _player.char_str == "remy" then
          if _base_name == "light_of_virtue" then
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            _dummy_offset_x = 120
            if _button == "LK" or _button == "MK" or _button == "HK" then
              current_attack.block = {2}
            elseif _button == "EXP" then
              current_attack.max_hits = 2
              current_attack.block = {1,2}
            elseif _button == "EXK" then
              current_attack.max_hits = 2
              current_attack.block = {2,2}
            end
          end
          if _base_name == "rising_rage_flash" then
            _dummy_offset_x = 80
            if _button == "EXK" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "cold_blue_kick" then
            _dummy_offset_x = 150
            if _button == "EXK" then
              current_attack.max_hits = 2
              current_attack.hits_appear_after_block = true
              block_max_hits = 1
            end
          end
        end

        if _player.char_str == "ryu" then
          if _base_name == "hadouken" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "shoryuken" then
            if _button == "LP" then
              current_attack.max_hits = 1
            elseif _button == "MP" then
              current_attack.max_hits = 1
            elseif _button == "HP" then
              current_attack.max_hits = 1
            elseif _button == "EXP" then
              current_attack.max_hits = 2
            end
          end

          if _base_name == "tatsumaki" then
            current_attack.reset_pos_x = 200
            if _button == "LK" then
              current_attack.max_hits = 1
            elseif _button == "MK" then
              current_attack.max_hits = 3
            elseif _button == "HK" then
              current_attack.max_hits = 3
            elseif _button == "EXK" then
              current_attack.max_hits = 5
              current_attack.dummy_offset_list = {{80,0},{-50,0},{80,0},{-50,0},{80,0}}
            end
          end
          if _base_name == "tatsumaki_air" then
            if recording_options.hit_type == "block" then
              queue_command(frame_number + 10, {command = clear_motion_data, args={_player}})
            end
            if _button == "LK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-50,0},{80,0},{-50,0}}
              current_attack.max_hits = 4
            elseif _button == "MK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-50,0},{80,0},{-50,0},{80,0},{-50,0}}
              current_attack.max_hits = 6
              current_attack.land_after = 150
            elseif _button == "HK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-50,0},{80,0},{-50,0},{80,0},{-50,0},{80,0},{-50,0}}
              current_attack.max_hits = 8
              current_attack.land_after = 200
            elseif _button == "EXK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-50,0},{80,0},{-50,0},{80,0},{-50,0}}
              current_attack.max_hits = 6
              current_attack.land_after = 150
            end
          end
          if _base_name == "joudan" then
            _dummy_offset_x = 100
          end
        end

        if _player.char_str == "sean" then
          if _base_name == "sean_tackle" then
            current_attack.throw = true
            _dummy_offset_x = 100

            local _n = 50
            for i = 1, _n do
              if _button == "EXP" then
                table.insert(_sequence, {"LP","MP"})
              else
                table.insert(_sequence, {_button})
              end
            end
          end
          if _base_name == "dragon_smash" then
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "tornado" then
            _dummy_offset_x = 80
            if _button == "LK" then
              current_attack.max_hits = 2
            elseif _button == "MK" then
              current_attack.max_hits = 3
            elseif _button == "HK" then
              current_attack.max_hits = 4
            elseif _button == "EXK" then
              current_attack.max_hits = 4
            end
          end
          if _base_name == "ryuubikyaku" then
            current_attack.name = _base_name
            if _button == "EXK" then
              current_attack.name = _base_name .. _button
            end
            _dummy_offset_x = 80
            if _button == "EXK" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "roll" then
            _dummy_offset_x = 80
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
        end

        if _player.char_str == "shingouki" then
          if _base_name == "gohadouken" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
          end
          if _base_name == "gohadouken_air" then
            _dummy_offset_x = 100
            current_attack.max_hits = 2
            current_attack.is_projectile = true
          end
          if _base_name == "shakunetsu" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            if _button == "LP" then
              current_attack.max_hits = 1
            elseif _button == "MP" then
              current_attack.max_hits = 2
            elseif _button == "HP" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "goshoryuken" then
            if _button == "LP" then
              current_attack.max_hits = 1
            elseif _button == "MP" then
              current_attack.max_hits = 2
            elseif _button == "HP" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "tatsumaki" then
            if _button == "LK" then
              current_attack.max_hits = 2
              current_attack.dummy_offset_list = {{80,0},{-70,0}}
            elseif _button == "MK" then
              current_attack.max_hits = 5
              current_attack.dummy_offset_list = {{80,0},{80,0},{-70,0},{80,0},{-70,0}}
            elseif _button == "HK" then
              current_attack.max_hits = 9
              current_attack.dummy_offset_list = {{80,0},{80,0},{-70,0},{80,0},{-70,0},{80,0},{-70,0},{80,0},{-70,0}}
            end
          end
          if _base_name == "tatsumaki_air" then
            if _button == "LK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0},{-60,0}}
              current_attack.max_hits = 2
            elseif _button == "MK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0},{-60,0}}
              current_attack.max_hits = 4
            elseif _button == "HK" then
              current_attack.player_offset_y = -20
              current_attack.dummy_offset_list = {{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0},{80,0},{-60,0}}
              current_attack.max_hits = 8
              current_attack.land_after = 150
            end
            if recording_options.hit_type == "block" then
              queue_command(frame_number + 10, {command = clear_motion_data, args={_player}})
            end
          end
          if _base_name == "asura_forward" or _base_name == "asura_backward" then
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
        end

        if _player.char_str == "twelve" then
          if _base_name == "ndl" then
            current_attack.is_projectile = true
            if _button == "MP" then
              _dummy_offset_x = 150
            elseif _button == "HP" then
              _dummy_offset_x = 210
              queue_command(frame_number + 10, {command = write_pos, args={_player, current_attack.reset_pos_x - 80, 0}})
              queue_command(frame_number + 10, {command = set_screen_pos, args={current_attack.reset_pos_x, 0}})
            elseif _button == "EXP" then
              _dummy_offset_x = 190
              current_attack.max_hits = 2
            end
          end
          if _base_name == "axe" then
            _dummy_offset_x = 80
            local _n = 25
            if _button == "LP" then
              current_attack.max_hits = 9
            elseif _button == "MP" then
              current_attack.max_hits = 9
            elseif _button == "HP" then
              _n = 30
              current_attack.max_hits = 12
            elseif _button == "EXP" then
              _n = 20
              current_attack.max_hits = 6
            end
            if recording_options.hit_type == "block" then
              current_attack.max_hits = 2
              if _button ~= "LP" then
                current_attack.max_hits = 3
              end
            end

            for i = 1, _n do
              table.insert(_sequence, {})
              if _button == "EXP" then
                table.insert(_sequence, {"LP","MP"})
              else
                table.insert(_sequence, {_button})
              end
            end
          end
          if _base_name == "axe_air" then
            _dummy_offset_x = 80
            current_attack.player_offset_y = 100
            local _n = 25
            for i = 1, _n do
              table.insert(_sequence, {})
              if _button == "EXP" then
                table.insert(_sequence, {"LP","MP"})
              else
                table.insert(_sequence, {_button})
              end
            end
            current_attack.max_hits = 3
            current_attack.player_offset_y = -20
            current_attack.land_after = 150
            if recording_options.hit_type == "block" then
              queue_command(frame_number + 10, {command = clear_motion_data, args={_player}})
            end
          end
          if _base_name == "dra" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 100
            if _button == "HK" then
              _dummy_offset_x = 120
            elseif _button == "EXK" then
              _dummy_offset_x = 120
              recording_options.infinite_loop = true
              current_attack.max_hits = 2
            end
          end
        end

        if _player.char_str == "urien" then
          if _base_name == "metallic_sphere" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            if _button == "HP" then
              if recording_options.hit_type == "block" then
                current_attack.projectile_offset = {0, -50}
              end
            end
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "chariot_tackle" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 100
            if _button == "EXK" then
              current_attack.max_hits = 2
            end
          end
          if _base_name == "violence_kneedrop" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 80
            if _button == "EXK" then
              current_attack.hits_appear_after_block = true
              current_attack.max_hits = 2
              block_max_hits = 1
            end
          end
          if _base_name == "dangerous_headbutt" then
            _dummy_offset_x = 80
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
          end
        end

        if _player.char_str == "yang" then
          if _base_name == "tourouzan" then
            _dummy_offset_x = 100
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "tourouzan_2"
          or _base_name == "tourouzan_3"
          or _base_name == "tourouzan_4"
          or _base_name == "tourouzan_5" then
            current_attack.optional_anim = {1}
            current_attack.max_hits = 2
            local _n = 4
            if _button == "EXP" then
              _n = 10
            end
            if recording_options.hit_type == "block" then
              _n = 25
            end
            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"down"})
            table.insert(_sequence, {"down","forward"})
            table.insert(_sequence, {"forward"})
            if _button == "EXP" then
              table.insert(_sequence, {"LP","MP"})
            else
              table.insert(_sequence, {_button})
            end
            if _base_name == "tourouzan_2" then
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "tourouzan_3"
          or _base_name == "tourouzan_4"
          or _base_name == "tourouzan_5" then
            current_attack.optional_anim = {1,1}
            current_attack.max_hits = 3
            local _n = 25
            if _button == "EXP" then
              _n = 8
            end
            if recording_options.hit_type == "block" then
              _n = 14
            end
            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"down"})
            table.insert(_sequence, {"down","forward"})
            table.insert(_sequence, {"forward"})
            if _button == "EXP" then
              table.insert(_sequence, {"LP","MP"})
            else
              table.insert(_sequence, {_button})
            end
            if _base_name == "tourouzan_3" and _button == "EXP" then
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "tourouzan_4"
          or _base_name == "tourouzan_5" then
            current_attack.optional_anim = {1,1,1}
            current_attack.max_hits = 4
            local _n = 2
            if _button == "EXP" then
              _n = 8
            end
            if recording_options.hit_type == "block" then
              _n = 25
            end
            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"down"})
            table.insert(_sequence, {"down","forward"})
            table.insert(_sequence, {"forward"})
            if _button == "EXP" then
              table.insert(_sequence, {"LP","MP"})
            else
              table.insert(_sequence, {_button})
            end

            if _base_name == "tourouzan_4" and _button == "EXP" then
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "tourouzan_5" then
            current_attack.optional_anim = {1,1,1,1}
            current_attack.max_hits = 5
            local _n = 2
            if _button == "EXP" then
              _n = 9
            end
            if recording_options.hit_type == "block" then
              _n = 25
            end
            for i = 1, _n do
              table.insert(_sequence, {})
            end
            table.insert(_sequence, {"down"})
            table.insert(_sequence, {"down","forward"})
            table.insert(_sequence, {"forward"})
            if _button == "EXP" then
              table.insert(_sequence, {"LP","MP"})
            else
              table.insert(_sequence, {_button})
            end
          end
          if _base_name == "senkyuutai" then
            current_attack.reset_pos_x = 150
            current_attack.max_hits = 2
            if _button == "EXK" then
              current_attack.max_hits = 3
            end
          end
          if _base_name == "kaihou" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 200
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
          if _base_name == "byakko" then
            current_attack.name = _base_name
            if _button == "EXK" then
              current_attack.name = _base_name .. _button
            end
            _dummy_offset_x = 100
            if _button == "EXP" then
              current_attack.max_hits = 0
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "zenpou" then
            _dummy_offset_x = 72
            current_attack.throw = true
          end
        end

        if _player.char_str == "yun" then
          if _base_name == "zesshou" then
            current_attack.reset_pos_x = 150
            _dummy_offset_x = 100
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
            if recording_geneijin then
              if _button == "HP" then
                current_attack.name = "zesshou"
                current_attack.max_hits = 3
              else
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "tetsuzan" then
            current_attack.reset_pos_x = 150
            if _button == "EXP" then
              current_attack.max_hits = 2
            end
            if recording_geneijin then
              if _button ~= "EXP" then
                current_attack.max_hits = 2
              else
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "nishoukyaku" then
            if recording_geneijin then
              current_attack.name = _base_name
              if _button == "LK" then
                current_attack.max_hits = 2
              else
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            else
              current_attack.max_hits = 1
              if recording_options.hit_type == "block" then
                queue_command(frame_number + 38, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 150, 0}})
              end
            end
          end
          if _base_name == "kobokushi" then
            current_attack.name = _base_name
            if _button == "EXK" then
              current_attack.name = _base_name .. _button
            end
            if _button == "EXP" then
              current_attack.max_hits = 0
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          end
          if _base_name == "zenpou" then
            current_attack.throw = true
          end
        end

        current_attack.sequence = _sequence

      elseif current_attack_category.name == "supers" then

        current_attack = deepcopy(supers[i_attacks])
        local _base_name = current_attack.name
        local _button = current_attack.button
        if _button then
          current_attack.name = current_attack.name .. "_" .. _button
        end
        current_attack.base_name = _base_name


        _dummy_offset_x = _close_dist
        _dummy_offset_y = 0

        current_attack.reset_pos_x = _reset_pos_x

        local _sequence = current_attack.input

        current_attack.attack_start_frame = #_sequence

        local i = 1
        while i <= #_sequence do
          local j = 1
          while j <= #_sequence[i] do
            if _sequence[i][j] == "button" then
              if _button == "EXP"  then
                table.remove(_sequence[i], j)
                table.insert(_sequence[i], j, "LP")
                table.insert(_sequence[i], j, "MP")
              elseif _button == "EXK"  then
                table.remove(_sequence[i], j)
                table.insert(_sequence[i], j, "LK")
                table.insert(_sequence[i], j, "MK")
              else
                table.remove(_sequence[i], j)
                table.insert(_sequence[i], j, _button)
              end
            end
            j = j + 1
          end
          i = i + 1
        end
        if _player.char_str == "alex" then
          if current_attack.move_type == "sa1" then
            current_attack.throw = true
            --reverse
          elseif current_attack.move_type == "sa2" then
            current_attack.block={1,1,1,1,3}
            current_attack.max_hits = 5
          elseif current_attack.move_type == "sa3" then
            current_attack.throw = true
            if _button == "MP" then
              current_attack.name = _base_name
              _dummy_offset_x = 150
            end
            if _button ~= "MP" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
        elseif _player.char_str == "chunli" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 20
          elseif current_attack.move_type == "sa2" then
            _dummy_offset_x = 80
            current_attack.reset_pos_x = 200
            current_attack.max_hits = 17
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 3 --9
          end
        elseif _player.char_str == "dudley" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 8 --11
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 8
            _dummy_offset_x = 120
            local _n = 80
            if recording_options.hit_type == "block" then
              _dummy_offset_x = 30
              _n = 140
            end
            for i = 1, _n do
              table.insert(_sequence, {})
              table.insert(_sequence, {"LP"})
            end
          elseif current_attack.move_type == "sa3" then
            current_attack.name = _base_name
            _dummy_offset_x = 90
            current_attack.max_hits = 5
          end
        elseif _player.char_str == "elena" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 7
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 10
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
          end
        elseif _player.char_str == "gill" then
          if current_attack.move_type == "sa1" then
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
            current_attack.max_hits = 0
            _dummy_offset_x = 90
            training_settings.life_mode = 1
            queue_command(frame_number + 11, {command=memory.writebyte, args={_player.life_addr, 0}})
            queue_input_sequence(_dummy, {{"HP"}})
          elseif current_attack.move_type == "sa2" then
            _dummy_offset_x = 100
            current_attack.is_projectile = true
            current_attack.max_hits = 16
            if recording_options.hit_type == "block" then
              _dummy_offset_x = 150
              current_attack.home_projectiles = true --meteor swarm has randomness
            end
          elseif current_attack.move_type == "sa3" then
            _dummy_offset_x = 120
            current_attack.max_hits = 17
          end
        elseif _player.char_str == "gouki" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 6
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 7
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 3 --12
          elseif current_attack.move_type == "sgs" then
            current_attack.throw = true
            table.insert(_sequence, 1, {"down", "HK"})
            _state = "waiting_for_sgs"
            queue_command(frame_number + 8, {command=function() _state = "wait_for_initial_anim" end})
          elseif current_attack.move_type == "kkz" then
            current_attack.max_hits = 1 --12
          end
        elseif _player.char_str == "hugo" then
          if current_attack.move_type == "sa1" then
            current_attack.throw = true
          elseif current_attack.move_type == "sa2" then
            current_attack.throw = true
            current_attack.reset_pos_x = 150
            if current_attack.button ~= "HK" then
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
            current_attack.name = "megaton_press"
            if recording_options.hit_type == "block" then
              _dummy_offset_y = 100
            end
          elseif current_attack.move_type == "sa3" then
            current_attack.reset_pos_x = 150
            current_attack.max_hits = 5
            if current_attack.name == "hammer_mountain_miss" then
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
              current_attack.max_hits = 0
              local _n = 100
              for i = 1, _n do
                table.insert(_sequence, {"LP"})
              end
            end
          end
        elseif _player.char_str == "ibuki" then
          if current_attack.move_type == "sa1" then
            current_attack.is_projectile = true
            current_attack.max_hits = 20
            current_attack.attack_start_frame = #_sequence + 6
            local _n = 70
            if recording_options.hit_type == "block" then
              _n = 350
              current_attack.player_offset_y = 80
            end
            for i = 1, _n do
              table.insert(_sequence, {})
              table.insert(_sequence, {_button})
            end
            if _button == "MP" then
              current_attack.offset_x = 30
            elseif _button == "HP" then
              current_attack.player_offset_y = 40
              current_attack.offset_x = 60
            end
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 13
            current_attack.offset_x = 70
          elseif current_attack.move_type == "sa3" then
            current_attack.is_projectile = true
            if recording_options.hit_type == "block" then
              current_attack.home_projectiles = true
              recording_options.hit_type = "miss"
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
            current_attack.max_hits = 3
            current_attack.reset_pos_x = 200
            current_attack.block={2,2,2}
          end
        elseif _player.char_str == "ken" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 11 --12
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 3 --15
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 5 --9
          end
        elseif _player.char_str == "makoto" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 1
          elseif current_attack.move_type == "sa2" then
            -- current_attack.name = _base_name
            current_attack.max_hits = 4
            current_attack.do_not_fix_screen = true
            current_attack.hits_appear_after_block = true
            block_max_hits = 1
            -- if _button ~= "MK" then
            --   i_attacks = i_attacks + 1
            --   _state = "queue_move"
            --   return
            -- end
            if _button == "LK" then
              queue_command(frame_number + 15, {command = write_pos, args={_dummy, current_attack.reset_pos_x - 40, 0}})
            elseif _button == "MK" then
              queue_command(frame_number + 15, {command = write_pos, args={_dummy, current_attack.reset_pos_x, 0}})
            elseif _button == "HK" then
              queue_command(frame_number + 15, {command = write_pos, args={_dummy, current_attack.reset_pos_x + 50, 0}})
            end
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
          end
        elseif _player.char_str == "necro" then
          if current_attack.move_type == "sa1" then
            current_attack.reset_pos_x = 600
            current_attack.max_hits = 13
            local _n = 60
            if recording_options.hit_type == "block" then
              _dummy_offset_x = 30
              _n = 140
            end
            for i = 1, _n do
              table.insert(_sequence, {})
              table.insert(_sequence, {"LP"})
            end
          elseif current_attack.move_type == "sa2" then
            current_attack.throw = true
          elseif current_attack.move_type == "sa3" then

            _dummy_offset_x = 150
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            current_attack.reset_pos_x = 160
            current_attack.max_hits = 3
            current_attack.block = {2,2,2}
          end
        elseif _player.char_str == "oro" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 0
            if current_attack.name == "kishinriki_activation" then
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                i_recording_hit_types = 1
                _state = "queue_move"
                return
              end
            else
              current_attack.throw = true
              if _button == "LP" then
                current_attack.name = "kishinriki"
                if recording_options.hit_type == "block" then
                  queue_command(frame_number + 10, {command = memory.writebyte, args = {_player.gauge_addr, 1}})
                end
              elseif _button == "EXP" then
                  queue_command(frame_number + 1, {command = memory.writebyte, args = {_player.gauge_addr, 1}})
              else
                i_recording_hit_types = 1
                i_attacks = i_attacks + 1
                _state = "queue_move"
                return
              end
            end
          elseif current_attack.move_type == "sa2" then
            current_attack.is_projectile = true
            current_attack.max_hits = 4
            current_attack.reset_pos_x = 200
            _dummy_offset_x = 150
            if _button == "EXP" then
              current_attack.max_hits = 12
            end
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
            recording_options.ignore_projectiles = true
            if _button == "LP" then
              current_attack.name = "tenguishi"
            elseif _button == "EXP" then
            else
              i_recording_hit_types = 1
              i_attacks = i_attacks + 1
              _state = "queue_move"
              return
            end
          end
        elseif _player.char_str == "q" then
          if current_attack.move_type == "sa1" then
            current_attack.reset_pos_x = 200
            current_attack.max_hits = 5
            current_attack.block = {1,1,1,2,1}
          elseif current_attack.move_type == "sa2" then
            _dummy_offset_x = 90
            current_attack.max_hits = 1
            current_attack.hits_appear_after_parry = true
            block_max_hits = 1
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
            if current_attack.name == "total_destruction_activation" then
              if recording_options.hit_type == "block" then
                i_attacks = i_attacks + 1
                i_recording_hit_types = 1
                _state = "queue_move"
                return
              end
            elseif current_attack.name == "total_destruction_attack" then
            current_attack.max_hits = 1              
              queue_command(frame_number + 50, {command = memory.writebyte, args = {_player.gauge_addr, _player.max_meter_gauge}})
            elseif current_attack.name == "total_destruction_throw" then
              current_attack.throw = true
            end
          end
        elseif _player.char_str == "remy" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 7
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            _dummy_offset_x = 150
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 10
            _dummy_offset_x = 90
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 7
            current_attack.hits_appear_after_hit = true
            -- block_max_hits = 1
            _dummy_offset_x = 90
            queue_input_sequence(_dummy, {{},{},{},{},{},{},{"down","LP"}})
          end
        elseif _player.char_str == "ryu" then
          if current_attack.move_type == "sa1" then
            _dummy_offset_x = 150
            current_attack.max_hits = 5
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 6
          elseif current_attack.move_type == "sa3" then
            _dummy_offset_x = 150
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
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              i_recording_hit_types = 1
              _state = "queue_move"
              return
            end
          end
        elseif _player.char_str == "sean" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 1
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            _dummy_offset_x = 150
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 14
            local _n = 30
            if recording_options.hit_type == "block" then
              _dummy_offset_x = 30
              _n = 140
            end
            for i = 1, _n do
              table.insert(_sequence, {"LP"})
              table.insert(_sequence, {"MP"})
              table.insert(_sequence, {"HP"})
            end
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 1
            current_attack.block = {2}
          end
        elseif _player.char_str == "shingouki" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 7
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            _dummy_offset_x = 150
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 11
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
          elseif current_attack.move_type == "sgs" then
            current_attack.throw = true
            table.insert(_sequence, 1, {"down", "HK"})
            _state = "waiting_for_sgs"
            queue_command(frame_number + 8, {command=function() _state = "wait_for_initial_anim" end})
          end
        elseif _player.char_str == "twelve" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 5
            _dummy_offset_x = 180
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
            if recording_options.hit_type == "block" then
              i_attacks = i_attacks + 1
              i_recording_hit_types = 1
              _state = "queue_move"
              return
            end
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 1
            current_attack.player_offset_y = -20
            _dummy_offset_x = 150
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
            queue_command(frame_number + 50, {command = memory.writebyte, args = {_player.gauge_addr, 1}})
          end
        elseif _player.char_str == "urien" then
          if current_attack.move_type == "sa1" then
            current_attack.reset_pos_x = 110
            current_attack.offset_x = 30
            current_attack.max_hits = 5
          elseif current_attack.move_type == "sa2" then
            current_attack.max_hits = 5
            _dummy_offset_x = 150
            current_attack.is_projectile = true
            current_attack.queue_track_projectile = true
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 6
            current_attack.is_projectile = true
            current_attack.end_recording_after_proectile = true
            if _button == "MP" then
              _dummy_offset_x = 120
            elseif _button == "HP" then
              _dummy_offset_x = 210
            elseif _button == "EXP" then
            end
          end
        elseif _player.char_str == "yang" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 1
          elseif current_attack.move_type == "sa2" then
            current_attack.reset_pos_x = 120
            current_attack.max_hits = 4
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
            recording_options.ignore_projectiles = true
          end
        elseif _player.char_str == "yun" then
          if current_attack.move_type == "sa1" then
            current_attack.max_hits = 3
            current_attack.hits_appear_after_parry = true
            block_max_hits = 2
          elseif current_attack.move_type == "sa2" then
            current_attack.hits_appear_after_parry = true
            current_attack.max_hits = 6
            block_max_hits = 2
          elseif current_attack.move_type == "sa3" then
            current_attack.max_hits = 0
            if recording_options.hit_type == "block" then
              recording_geneijin = true
              i_recording_hit_types = 1
              i_attacks = 1
              i_attack_categories = 1
              last_category = 6
              _state = "queue_move"
              return
            end
          end
        end

        if recording_options.hit_type == "block" then
          if current_attack.max_hits == 0 and not current_attack.throw then
            i_attacks = i_attacks + 1
            i_recording_hit_types = 1
            _state = "queue_move"
            return
          end
        end

        current_attack.sequence = _sequence
      else
        recording = false
        _setup = false
        _state = "off"
        make_invulnerable(_dummy, false)
        return
      end

      if current_attack_category.name == "supers" then
        local current_sa = 1
        if current_attack.move_type == "sgs" then
          current_sa = 4
        elseif current_attack.move_type == "kkz" then
          current_sa = 5
        else
          current_sa = tonumber(string.sub(current_attack.move_type, 3, 3))
        end
        if _player.selected_sa ~= current_sa
        and not (current_attack.move_type == "sgs" or current_attack.move_type == "kkz")
        and not (_player.char_str == "gill") then
          _state = "wait_for_match_start"
          table.insert(after_load_state_callback, {command = force_select_character, args = {_player.id, _player.char_str, current_sa, "LP"} })
          table.insert(after_load_state_callback, {command = force_select_character, args = {_dummy.id, "urien", 1, "MP"} })
          start_character_select_sequence()
          return
        end
      end

      if not recording_options.target_combo then
        _name = current_attack.name or input_to_text(current_attack.sequence)[1]
        if recording_geneijin then
          _name = (current_attack.name or input_to_text(current_attack.sequence)[1]) .. "_geneijin"
        end
        if current_attack.offset_x then
          _dummy_offset_x = _dummy_offset_x + current_attack.offset_x
        end

        current_attack.player_offset_y = current_attack.player_offset_y or 0

        if current_attack.self_chain and current_attack.block then
          table.insert(current_attack.block, current_attack.block[1])
        end
        block_pattern = current_attack.block

        if current_attack.queue_track_projectile and not current_attack.queued_track_projectile then
          current_attack_category.list[i_attacks].queued_track_projectile = true
          current_attack_category.list[i_attacks].record_projectile_emit_animation = true
          local _attack = deepcopy(current_attack)
          _attack.name = _attack.base_name
          _attack.track_projectile = true
          _attack.queued_track_projectile = true
          table.insert(current_attack_category.list, i_attacks + 1, _attack)
          current_attack.record_projectile_emit_animation = true
        end

        if current_attack.record_projectile_emit_animation or current_attack.track_projectile then
          current_attack.reset_pos_x = 150
        end

        if current_attack.record_projectile_emit_animation then
          if recording_options.hit_type == "miss" then
            recording_options.ignore_projectiles = true
          else
            if current_attack_category.name == "supers" then
              i_recording_hit_types = 1
            end
            i_attacks = i_attacks + 1
            _state = "queue_move"
            return
          end
        end

        if recording_options.hit_type == "miss" then
          if current_attack.max_hits and not (current_attack.hits_appear_after_block or current_attack.hits_appear_after_hit) then
            block_max_hits = block_max_hits or 0
            block_until = block_until or 0
          end
          if current_attack.throw then
            block_max_hits = 0
            block_until = 0
          end
          if current_attack.self_chain then
            current_attack.max_hits = 2
            block_max_hits = current_attack.max_hits - 1
          end
        else
          block_max_hits = 1
          block_until = 1
          if current_attack.max_hits then
            block_max_hits = current_attack.max_hits
            block_until = block_max_hits
          end
          if current_attack.self_chain then
            current_attack.max_hits = 1
            block_until = current_attack.max_hits
          end
        end
        if current_attack.hits_appear_after_block
        or current_attack.hits_appear_after_hit 
        or current_attack.hits_appear_after_parry
        then
          recording_options.record_frames_after_hit = true
        end

        if current_attack.ignore_next_anim then
          recording_options.ignore_next_anim = true
        end

        if current_attack.air then
          recording_options.air = true
          local _sequence = {{"up","forward"},{"up","forward"},{},{},{},{}}
          if current_attack.jump_dir == "back" then
            _sequence = {{"up","back"},{"up","back"},{},{},{},{}}
          elseif current_attack.jump_dir == "neutral" then
            _sequence = {{"up"},{"up"},{},{},{},{}}
          end
          if(is_slow_jumper(_player.char_str)) then
            table.insert(_sequence,#_sequence,{})
          elseif is_really_slow_jumper(_player.char_str) then
            table.insert(_sequence,#_sequence,{})
            table.insert(_sequence,#_sequence,{})
          end

          for i = 1, #current_attack.sequence do
            table.insert(_sequence, current_attack.sequence[i])
          end
          current_attack.sequence = _sequence

          current_attack.attack_start_frame = current_attack.attack_start_frame or #_sequence

          queue_input_sequence(_player, current_attack.sequence)

          if current_attack.name == "drill_LK" then
            recording_options.infinite_loop = true
            if recording_options.hit_type == "miss" then
              _dummy_offset_x = 200
              write_pos(_player, 150, 300)
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 300)
              block_max_hits = 0
            else
              _dummy_offset_x = 350
              write_pos(_player, 150, 200)
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0)
              queue_command(frame_number + 50, {command = write_pos, args={_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0}})
              _dummy_offset_x = 100
            end
            queue_command(frame_number + #current_attack.sequence, {command = clear_motion_data, args={_player}})
          elseif current_attack.name == "drill_MK" then
            recording_options.infinite_loop = true
            if recording_options.hit_type == "miss" then
              _dummy_offset_x = 150
              write_pos(_player, 150, 300)
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 300)
              block_max_hits = 0
            else
              _dummy_offset_x = 200
              write_pos(_player, 150, 200)
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0)
              _dummy_offset_x = 100
            end
            queue_command(frame_number + #current_attack.sequence, {command = clear_motion_data, args={_player}})
          elseif current_attack.name == "drill_HK" then
            recording_options.infinite_loop = true
            if recording_options.hit_type == "miss" then
              _dummy_offset_x = 150
              write_pos(_player, 150, 300)
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 300)
              block_max_hits = 0
            else
              _dummy_offset_x = 0
              write_pos(_player, 150, 200)
              queue_command(frame_number + 1, {command = write_pos, args={_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0}})
              _dummy_offset_x = 100
            end
            queue_command(frame_number + #current_attack.sequence, {command = clear_motion_data, args={_player}})
          else
            if current_attack.land_after then
              if current_attack.land_after > 0 then
                queue_command(frame_number + current_attack.land_after, {command = land_player, args={_player}})
              end
            else
              queue_command(frame_number + #current_attack.sequence + 100, {command = land_player, args={_player}})
            end
            queue_command(frame_number + #current_attack.sequence, {command = clear_motion_data, args={_player}})

            if recording_options.hit_type == "miss" then
              write_pos(_player, current_attack.reset_pos_x, 0)
              queue_command(frame_number + current_attack.attack_start_frame, {command = write_pos, args={_player, current_attack.reset_pos_x, _default_air_miss_height + current_attack.player_offset_y}})
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 200)
            else
              write_pos(_player, current_attack.reset_pos_x, 0)
              queue_command(frame_number + current_attack.attack_start_frame, {command = write_pos, args={_player, current_attack.reset_pos_x, _default_air_block_height + current_attack.player_offset_y}})
              write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, 0)
            end
          end
        else
          current_attack.attack_start_frame = current_attack.attack_start_frame or #current_attack.sequence
          write_pos(_player, current_attack.reset_pos_x, 0)
          write_pos(_dummy, current_attack.reset_pos_x + _dummy_offset_x, _player.pos_y + _dummy_offset_y)
          queue_input_sequence(_player, current_attack.sequence)
          queue_command(frame_number + current_attack.attack_start_frame, {command = clear_motion_data, args={_player}})
        end

        if current_attack.self_chain then
          make_invulnerable(_dummy, false)
          recording_options.self_chain = true
        end

        memory.writebyte(_dummy.stun_bar_char_addr, 0)
        memory.writebyte(_dummy.life_addr, 160)
        clear_motion_data(_player)
        fix_screen_pos(_player, _dummy)
        print(_name)

        if overwrite and first_record then
          recording_options.clear_frame_data = true
          first_record = false
        end
      end
    end


    if _setup then

      -- print(_state,recording_options.hit_type, received_hits, block_until, block_max_hits, i_attacks)
      if _state == "update_hit_state" then
        if received_hits >= block_until then
          if block_until < block_max_hits then
            block_until = block_until + 1
          else
            if current_attack_category.name == "target_combos" or current_attack.self_chain then
              block_until = 0
            else
              received_hits = 0
              block_until = 0
            end
            if not (current_attack_category.name == "supers") then
              i_attacks = i_attacks + 1
              first_record = true
            else
              if i_recording_hit_types < #recording_hit_types then
                i_recording_hit_types = i_recording_hit_types + 1
              else
                i_recording_hit_types = 1
                i_attacks = i_attacks + 1
                first_record = true
              end
            end
          end
        end
        _state = "queue_move"
      end

      if recording_options.hit_type == "miss" then
        if not (recording_options.target_combo
        or current_attack.self_chain
        or current_attack.hits_appear_after_block
        or current_attack.hits_appear_after_hit
        or current_attack.hits_appear_after_parry) then
          make_invulnerable(_dummy, true)
          write_pos(_dummy, _player.pos_x + _dummy_offset_x, _player.pos_y + _dummy_offset_y)
        else
          if received_hits < block_until then
            make_invulnerable(_dummy, false)
            if current_attack.hits_appear_after_parry then
              memory.writebyte(_dummy.parry_forward_validity_time_addr, 0xA)
              memory.writebyte(_dummy.parry_down_validity_time_addr, 0xA)
              memory.writebyte(_dummy.parry_air_validity_time_addr, 0x7)
              memory.writebyte(_dummy.parry_antiair_validity_time_addr, 0x5)            
            end
          else
            make_invulnerable(_dummy, true)
            write_pos(_dummy, _player.pos_x + _dummy_offset_x, _player.pos_y + _dummy_offset_y)
          end
        end

        if _state == "new_recording" then
          _state = "recording"
        end
      elseif recording_options.hit_type == "block" then
        if not (recording_options.target_combo or current_attack.self_chain) then
          make_invulnerable(_dummy, false)
          if _state == "new_recording" then
            received_hits = 0
            _state = "recording"
          end
          if current_attack.is_projectile then
            if current_projectile and current_projectile.expired and not recording_pushback then
              current_projectile = nil
              freeze_player_for_projectile = false
              if current_attack.end_recording_after_proectile then
                end_recording(_player, _projectiles, _name)
              end
            end
            for _id, _obj in pairs(_projectiles) do
              if not current_projectile then
                current_projectile = _obj
                if current_attack.projectile_offset then
                  write_pos(_obj, _obj.pos_x + current_attack.projectile_offset[1], _obj.pos_y + current_attack.projectile_offset[2])
                end
              end
              if current_attack.home_projectiles then
                local _dx = _dummy.pos_x - _obj.pos_x
                local _dy = _dummy.pos_y - _obj.pos_y
                local _dist = math.sqrt(_dx*_dx + _dy*_dy)
                local _vx =  _dx / _dist * 16
                local _vy =  _dy / _dist * 16
                write_velocity(_obj, _vx, _vy)
              end
              if _obj ~= current_projectile then
                set_freeze(_obj, 2)
              end
            end
            if current_projectile then
              for _, _box in pairs(current_projectile.boxes) do
                if convert_box_types[_box[1]] == "attack"then
                  freeze_player_for_projectile = true
                end
              end
            end
            if freeze_player_for_projectile then
              if _player.animation == "d17c" then --gill meteor swarm
                if current_projectile then
                  set_freeze(_player, 255)
                end
              else
                set_freeze(_player, 2)
              end
            end
            recording_options.is_projectile = true
          end
        end
      end

      if _dummy.has_just_blocked or _dummy.has_just_been_hit or _dummy.received_connection then
        received_hits = received_hits + 1
      end

      if current_attack.dummy_offset_list then
        local _index = received_hits + 1
        if _index <= #current_attack.dummy_offset_list then
          _dummy_offset_x = current_attack.dummy_offset_list[_index][1]
          _dummy_offset_y = current_attack.dummy_offset_list[_index][2]
        end
      end

      if current_attack.optional_anim and received_hits + 1 <= #current_attack.optional_anim
      and current_attack.optional_anim[received_hits + 1] == 1 then
        recording_options.optional_anim = true
      else
        recording_options.optional_anim = false
      end

      if _dummy.has_just_blocked or _dummy.has_just_been_hit then
        if recording_options.target_combo then
          if current_attack.cancel_on_whiff
          or (current_attack.cancel_on_hit and current_attack.cancel_on_hit[received_hits] == 1)
          or current_attack.cancel_on_hit == nil then
            if tc_hit_index <= #current_attack.sequence then
              if recording_options.hit_type == "miss" then
                tc_hit_index = tc_hit_index + 1
                set_freeze(_player, 1)
                local _delay = 0
                if current_attack.delay then
                  _delay = current_attack.delay[tc_hit_index]
                end
                queue_command(frame_number + 1 + _delay, {command = queue_input_sequence, args={_player, {current_attack.sequence[tc_hit_index]}}})
              end
            end
          end
        end
        if current_attack.self_chain and received_hits < current_attack.max_hits then
          local _delay = 0
          if current_attack.delay then
            _delay = current_attack.delay[1]
          end
          set_freeze(_player, 1)
          _player.animation_action_count = 0
          queue_command(frame_number + 1 + _delay, {command = queue_input_sequence, args={_player, current_attack.sequence}})
        end
      end

      if _dummy.has_just_blocked or _dummy.has_just_been_hit or _dummy.received_connection then
        if (recording_options.hit_type == "block" or recording_options.hit_type == "hit")
        and not current_attack.throw
        and not (block_pattern and block_pattern[received_hits] == 3) then
          unfreeze_dummy = true
          _state = "pause_for_data"
        end
      end
      if _state == "resume_attack" then
        if not current_attack.is_projectile then
          if unfreeze_player then
            if _player.animation == "dadc" then
              set_freeze(_player, 0xFF)
            else
              set_freeze(_player, 1)
            end
            unfreeze_player = false
          end

          if recording_options.target_combo then
            tc_hit_index = tc_hit_index + 1
            if tc_hit_index <= #current_attack.sequence then
              local _delay = 0
              if current_attack.delay then
                _delay = current_attack.delay[tc_hit_index]
              end
              queue_command(frame_number + 1 + _delay, {command = queue_input_sequence, args={_player, {current_attack.sequence[tc_hit_index]}}})
            end
          end
          if current_attack.self_chain and received_hits < current_attack.max_hits then
            local _delay = 0
            if current_attack.delay then
              _delay = current_attack.delay[1]
            end
            _player.animation_action_count = 0
            queue_command(frame_number + 1 + _delay, {command = queue_input_sequence, args={_player, current_attack.sequence}})
          end
        else
          if current_projectile then
            set_freeze(current_projectile, 1)
          end
        end
        _state = "recording"
      end
      if _player.previous_remaining_freeze_frames > 0
      and _player.remaining_freeze_frames - _player.previous_remaining_freeze_frames == 1
      then
        set_freeze(_player, 0xFF)
        if _player.animation == "d17c" then
          set_freeze(_player, 1)
        end
        -- set_freeze(_player, 127)
        -- queue_command(frame_number + 2, {command = set_freeze, args={_player, 1}})
      end
      if received_hits < block_until then
        if block_pattern then
          local _index = math.min(received_hits + 1, block_max_hits)
          if block_pattern[_index] ~= 2 then
            block_high(_dummy)
          else
            block_low(_dummy)
          end
        else
          block_high(_dummy)
        end
      end
      if _state == "pause_for_data" then
        if not current_attack.is_projectile then
          if _player.freeze_just_began then
            if not current_projectile then
              recording_self_freeze = true
            end
            self_freeze = _player.remaining_freeze_frames
            if _player.animation == "f50c"
            or _player.animation == "4bf4"
            or _player.animation == "a498"
            or _player.animation == "aa18"
            or _player.animation == "af98"
            or (_player.animation == "b518" and _player.action_count < 2)
            then
              set_freeze(_player, 0xFF)
              queue_command(frame_number + 1, {command = function() self_freeze = 0xFF end})
            else
              queue_command(frame_number + 1, {command = set_freeze, args={_player, math.min(2, self_freeze)}})
            end
          else
            recording_self_freeze = false
            set_freeze(_player, math.min(2, self_freeze))
          end
        else
          if current_projectile then
            set_freeze(current_projectile, 2)
          end
        end
        if _dummy.freeze_just_began then
          recording_opponent_freeze = true
        else
          recording_opponent_freeze = false

          if _dummy.remaining_freeze_frames > 0 and unfreeze_dummy then
            set_freeze(_dummy, 1)
            unfreeze_dummy = false
          end

          if _dummy.remaining_freeze_frames - _dummy.previous_remaining_freeze_frames == 1 then
            set_freeze(_dummy, 0xFF)
          end

          if _dummy.freeze_just_ended then
            queue_command(frame_number + 1, {command = function() recording_recovery = true end})
            queue_command(frame_number + 2, {command = function() recording_recovery = false end})
          end
          if _dummy.movement_type == 1 and _dummy.remaining_freeze_frames == 0 then
            begin_recording_pushback = true
            queue_command(frame_number + 1, {command = function() recording_pushback = true end})
          end
        end
      end
      if begin_recording_pushback and _dummy.movement_type == 0 then
        begin_recording_pushback = false
        recording_pushback = false
        write_pos(_dummy, _player.pos_x + _dummy_offset_x, 0)
        fix_screen_pos(_player, _dummy)
        unfreeze_player = true
        _state = "resume_attack"
      end
    end

    if _dummy.stunned and _dummy.stun_timer >= 0 then
      memory.writebyte(_dummy.stun_timer_addr, 0)
    end

    if recording_geneijin then
      memory.writebyte(_player.gauge_addr, _player.max_meter_gauge)
    end

    if not current_attack.do_not_fix_screen then
      fix_screen_pos(_player, _dummy)
    end

    if current_attack.queue_track_projectile
    and not current_attack.record_projectile_emit_animation
    and recording_options.hit_type == "miss" then
      if current_projectile and current_projectile.expired then
        current_projectile = nil
      end
      for _id, _obj in pairs(_projectiles) do
        if not current_projectile then
          current_projectile = _obj
        end
      end
      if current_projectile then
        fix_screen_pos(current_projectile, current_projectile)
        if current_projectile.pos_y > 100 and current_projectile.pos_y < 280 then
          write_pos_y(_player, current_projectile.pos_y)
          write_pos_y(_dummy, current_projectile.pos_y)
          queue_input_sequence(_player, {{"up"}})
          queue_input_sequence(_dummy, {{"up"}})
        else
          write_pos_y(_player, 0)
          write_pos_y(_dummy, 0)
        end
      end
    end

    if recording_options.hit_type == "miss"
    and test_collision(
    _dummy.pos_x, _dummy.pos_y, _dummy.flip_x, _dummy.boxes, -- defender
    _player.pos_x, _player.pos_y, _player.flip_x, _player.boxes, -- attacker
    {{{"push"}, {"push"}}})
    then
      print(">>overlapping push boxes<<")
    end

    record_framedata(_player, _projectiles, _name)
  end
end

function debugframedatagui(_player_obj, _projectiles)
  if is_in_match then
    _display = {}
    local _p2 = P2
--[[     debuggui("frame", frame_number)
    debuggui("state", _state)
    debuggui("anim", _player_obj.animation)
    debuggui("anim f", _player_obj.animation_frame)
    debuggui("hash", _player_obj.animation_frame_hash)
    debuggui("freeze", _player_obj.remaining_freeze_frames)
    debuggui("sfreeze", _player_obj.superfreeze_decount)
    debuggui("action #", _player_obj.action_count)
    debuggui("action #", _player_obj.animation_action_count)
    debuggui("conn action #", _player_obj.connected_action_count)
    debuggui("hit id", _player_obj.current_hit_id)
    -- debuggui("attacking", tostring(_player_obj.is_attacking))
    -- debuggui("wakeup", _player_obj.remaining_wakeup_time)
    -- debuggui("wakeup2", _p2.remaining_wakeup_time)
    debuggui("pos", string.format("%04f,%04f",_player_obj.pos_x, _player_obj.pos_y))
    debuggui("pos", string.format("%04f,%04f",_p2.pos_x, _p2.pos_y))
    debuggui("diff", string.format("%04f,%04f",_player_obj.pos_x - _player_obj.previous_pos_x, _player_obj.pos_y - _player_obj.previous_pos_y ))
    debuggui("diff", string.format("%04f,%04f",_p2.pos_x - _p2.previous_pos_x, _p2.pos_y - _p2.previous_pos_y ))
    debuggui("vel", string.format("%04f,%04f",_player_obj.velocity_x, _player_obj.velocity_y))
    debuggui("vel", string.format("%04f,%04f",_p2.velocity_x, _p2.velocity_y))
    debuggui("acc", string.format("%04f,%04f",_player_obj.acceleration_x, _player_obj.acceleration_y)) ]]
    -- debuggui("recording", tostring(recording))

    for _id, _obj in pairs(_projectiles) do
      if _obj.emitter_id == _player_obj.id and _obj.alive then
        -- debuggui("s_type", _obj.projectile_start_type)
        debuggui("type", _obj.projectile_type)
        -- debuggui("emitter", _obj.emitter_id)

--         debuggui("xy", tostring(_obj.pos_x) .. ", " .. tostring(_obj.pos_y))
--         debuggui("frame", _obj.animation_frame)
        debuggui("freeze", _obj.remaining_freeze_frames)
--         if frame_data["projectiles"] and frame_data["projectiles"][_obj.projectile_start_type] and frame_data["projectiles"][_obj.projectile_start_type].frames[_obj.animation_frame+1] then
--           if _obj.animation_frame_hash ~= frame_data["projectiles"][_obj.projectile_start_type].frames[_obj.animation_frame+1].hash then
--             debuggui("desync!", _obj.animation_frame_hash)
--           end
--         end
        debuggui("vx", _obj.velocity_x)
        debuggui("vy", _obj.velocity_y)
        debuggui("hits", _obj.remaining_hits)
        debuggui("cd", _obj.cooldown)

--         debuggui("rem", string.format("%x", _obj.remaining_lifetime))
      end
    end
  end
end

function debuggui(_name, _var)
  if _name and _var then
    table.insert(_display, {_name, _var})
  end
end

function draw_debug_gui()
  local _y = 44
  gui.box(2, 2 + _y, 80, 5+10*#_display + _y, gui_box_bg_color, gui_box_bg_color)
  for i=1,#_display do
    render_text(6,6+10*(i-1) + _y, string.format("%s: %s", _display[i][1], _display[i][2]), "en", nil, "white")
  end
end

function land_player(_obj)
  memory.writeword(_obj.base + 0x64 + 36, -1)
  memory.writeword(_obj.base + 0x64 + 38, 0)
  queue_command(frame_number + 1, {command = function() current_recording_acceleration_offset = -1 end})
end

function block_high(_player_obj)
  queue_input_sequence(_player_obj, {{"back"}})
  clear_motion_data(_player_obj)
end

function block_low(_player_obj)
  queue_input_sequence(_player_obj, {{"down","back"}})
  clear_motion_data(_player_obj)
end

function is_hit_frame(_frame)
  if _frame.boxes then
    for _k, _box in pairs(_frame.boxes) do
      local _type = convert_box_types[_box[1]]
      if _type == "attack" or _type == "throw" then
        return true
      end
    end
  end
  return false
end

function is_idle_frame(_frame)
  if _frame.idle then
    return true
  end
  return false
end

function divide_hit_frames(_anim)
  local _result = {}

  if _anim.hit_frames then
    for _k, _hf in pairs(_anim.hit_frames) do
      local _hf_start = _hf[1]
      local _hf_end = _hf[2]
      local _search_start = math.min(_hf[1] + 2, _hf_end + 1)
      local _i = _search_start
      while _i <= _hf[2] + 1 do
        local _end = -1
        if _anim.frames[_i].hit_start then
          _end = math.max(_i - 2, _hf_start)
        elseif _i == _hf_end + 1 then
          _end = _hf[2]
        end

        if _end ~= -1 then
          table.insert(_result, {_hf_start, _end})
          _hf_start = _end + 1
          if _anim.frames[_i].hit_start and _hf_start == _hf_end then
            table.insert(_result, {_hf_start, _hf_end})
          end
        end

        _i = _i + 1

      end
    end
  end
  return _result
end

function calculate_ranges(_list, _predicate)
  local ranges = {}
  local in_range = false
  local range_start = nil

  for i, value in ipairs(_list) do
    if _predicate(value) then
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

  if in_range then
    table.insert(ranges, {range_start, #_list})
  end

  return ranges
end

function span_frame_data()
  local decode_times = {}
  local file_names = {}
  local key_list = deepcopy(frame_data_keys)
  table.sort(key_list)
   _char = "dudley" -- for _key, _char in ipairs(key_list) do
    decode_times[_char] = {}
    file_names[_char] = {}
    local _frame_data = frame_data[_char]
    for _id, _data in pairs(_frame_data) do
      local _obj = {}
      _obj[_id] = _data
      local _str = json.encode(_obj)
      local stats = estimate_decode_time(_str, json.decode, 10)
      table.insert(decode_times, {object = _obj, size = stats.average_time})
      print(string.format("%s: %.16f", _id, stats.average_time))
    end
    local bins, _ = pack_ffd(decode_times, 1/60/10)
    for k, bin in ipairs(bins) do
      for _, item in ipairs(bin) do
        local _file_name = _char..k..".json"
        local _file_path = framedata_path.._file_name
        table.insert(file_names[_char], _file_name)
        if not write_object_to_json_file(item.object, _file_path, false) then
          print(string.format("Error: Failed to write frame data to \"%s\"", _file_path))
        else
          print(string.format("Saved frame data to \"%s\"", _file_path))
        end
      end
    end
  --end
  local _file_path = framedata_path.."file_names.json"
  if not write_object_to_json_file(file_names, _file_path, false) then
    print(string.format("Error: Failed to write frame data to \"%s\"", _file_path))
  else
    print(string.format("Saved frame data to \"%s\"", _file_path))
  end

  for _, _file in ipairs(file_names[_char]) do
    local _file_path = framedata_path.._file
    local _f = io.open(_file_path, "r")
    local stats = estimate_decode_time(_f:read("*all"), json.decode, 10)
    _f:close()
    print(string.format("%.06fs - %.06f error", stats.average_time,
      (1/60/10 - stats.average_time)/(1/60/10)))
  end
end

function pack_ffd(items, capacity)
  local sorted = {}
  for i, v in ipairs(items) do
    sorted[i] = v
  end
  table.sort(sorted, function(a, b) return a.size > b.size end)

  local bins        = {}
  local bin_of_item = {}
  setmetatable(bin_of_item, { __index = function() return 0 end })

  local function new_bin()
    bins[#bins + 1] = { load = 0, items = {} }
    return #bins
  end

  for _, item in ipairs(sorted) do
    local placed = false
    for k = 1, #bins do
      if bins[k].load + item.size <= capacity then
        bins[k].load = bins[k].load + item.size
        table.insert(bins[k].items, item)
        bin_of_item[item] = k
        placed = true
        break
      end
    end
    if not placed then
      local k = new_bin()
      bins[k].load = bins[k].load + item.size
      table.insert(bins[k].items, item)
      bin_of_item[item] = k
    end
  end

  local ordered_bins = {}
  for k = 1, #bins do
    ordered_bins[k] = bins[k].items
  end
  return ordered_bins, bin_of_item
end


function estimate_decode_time(json_str, decode_fn, trials)
  trials = trials or 5
  local total = 0

  decode_fn(json_str)

  for i = 1, trials do
    local t0 = os.clock()
    decode_fn(json_str)
    total = total + (os.clock() - t0)
  end

  local avg = total / trials
  local len = #json_str
  return {
    total_time = total,
    average_time = avg,
    time_per_kb = avg * 1024 / len,
    trials = trials,
    length = len
  }
end


local final_props = {"name", "frames", "hit_frames", "idle_frames", "loops", "pushback", "advantage", "uses_velocity", "air", "infinite_loop", "max_hits", "cooldown", "self_chain", "exceptions"}
local final_frame_props = {"hash", "boxes", "movement", "velocity", "acceleration", "loop", "next_anim", "optional_anim", "wakeup", "bypass_freeze"}
function save_frame_data()
  for _key, _char in ipairs(frame_data_keys) do
    if frame_data[_char].should_save then
      frame_data[_char].should_save = nil
      local _frame_data = deepcopy(frame_data[_char])
      if not (_char == "projectiles") then
        _frame_data.standing = ""
        _frame_data.standing_turn = ""
        _frame_data.crouching = ""
        _frame_data.crouching_turn = ""
        if not _frame_data.wakeups then
          _frame_data.wakeups = {}
        end
      end
      for _id, _data in pairs(_frame_data) do
        if type(_data) == "table" and _id ~= "wakeups" then
          for k, v in pairs(_data) do
            if k == "name" then
              if v == "standing" then
                _frame_data.standing = _id
              elseif v == "standing_turn" then
                _frame_data.standing_turn = _id
              elseif v == "crouching" then
                _frame_data.crouching = _id
              elseif v == "crouching_turn" then
                _frame_data.crouching_turn = _id
              elseif string.find(v, "wakeup") then
                if not table_contains_deep(_frame_data.wakeups, _id) then
                  table.insert(_frame_data.wakeups, _id)
                end
              end
            else
              if k == "hit_frames" then
                if deep_equal(v, {}) then
                  _frame_data[_id][k] = nil
                end
              end
            end
            if not table_contains_deep(final_props, k) then
              _data[k] = nil
            end
          end

          local _frames = {}
          if _data.frames then
            for i, _frame in ipairs(_data.frames) do
              for _k, _v in pairs(_data.frames[i]) do
                if not table_contains_deep(final_frame_props, _k) then
                  _data.frames[i][_k] = nil
                end
                if _k == "movement"
                or _k == "velocity"
                or _k == "acceleration"
                then
                  if deep_equal(_v, {0,0}) then
                    _data.frames[i][_k] = nil
                  end
                elseif _k == "boxes" then
                  if deep_equal(_v, {}) then
                    _data.frames[i][_k] = nil
                  end
                end
              end
              table.insert(_frames, _data.frames[i])
            end
            _data.frames = _frames
          else
            print("no frames", _id)
          end
        end
      end
      local _file_path = framedata_path.."@".._char..frame_data_file_ext
      if not write_object_to_json_file(_frame_data, _file_path, true) then
        print(string.format("Error: Failed to write frame data to \"%s\"", _file_path))
      else
        print(string.format("Saved frame data to \"%s\"", _file_path))
      end
    end
  end
end


function reset_current_recording_animation()
  current_recording_animation = nil
  current_recording_anim_list = {}
  current_recording_proj_list = {}
  current_recording_acceleration_offset = 0
  bypassing_freeze = false
end
reset_current_recording_animation()


_display = {}
local next_anim_types = {"next_anim", "optional_anim"}
local props_to_copy = {"self_freeze", "opponent_freeze", "opponent_recovery", "pushback","wakeup"}

function new_recording(_player_obj, _projectiles, _name)
  reset_current_recording_animation()
  current_recording_animation = {name = _name, frames = {}, hit_frames = {}, id = _player_obj.animation}
  if recording_options.air then
    current_recording_animation.air = true
  end
  current_recording_anim_list = {current_recording_animation}
  current_recording_proj_list = {}
  current_recording_acceleration_offset = 0
  recording = true
  _state = "recording"
end 

function new_animation(_player_obj, _projectiles, _name)
  local _frames = current_recording_animation.frames
  if not _frames[#_frames].hash then --patch up missing frames
    _frames[#_frames].hash = _player_obj.animation_frame_hash
  end

  local _next_anim_type = "next_anim"
  if recording_options.optional_anim then
    _next_anim_type = "optional_anim"
    recording_options.optional_anim = false
  end

  if not _frames[#_frames][_next_anim_type] then
    _frames[#_frames][_next_anim_type] = {}
  end
  if not next_anim_contains(_frames[#_frames][_next_anim_type], {_player_obj.animation}) then
    table.insert(_frames[#_frames][_next_anim_type], {id = _player_obj.animation, hash = _player_obj.animation_frame_hash})
  end

  if current_recording_animation.name == _name then
    _name = _name .. "_ext"
  end

  current_recording_animation = {name = _name, frames = {}, hit_frames = {}, id = _player_obj.animation}
  table.insert(current_recording_anim_list, current_recording_animation)
  recording = true
  _state = "recording"
end

function end_recording(_player_obj, _projectiles, _name)
  local _frames = current_recording_animation.frames
  if not _frames[#_frames].hash then --patch up missing frames
    _frames[#_frames].hash = _player_obj.animation_frame_hash
  end
  if not _frames[#_frames]["next_anim"] then
    _frames[#_frames]["next_anim"] = {}
  end
  if not next_anim_contains(_frames[#_frames]["next_anim"], {"idle"})  then
    table.insert(_frames[#_frames]["next_anim"], {"idle"})
  end

  if (frame_data[_player_obj.char_str] == nil) then
    frame_data[_player_obj.char_str] = {}
  end
  frame_data[_player_obj.char_str].should_save = true

  process_motion_data(current_recording_anim_list)

  for i = 1, #current_recording_anim_list do
    local id = current_recording_anim_list[i].id
    local _frame_data = frame_data[_player_obj.char_str][id]

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
    local _new_frames = deepcopy(current_recording_anim_list[i].frames)
    --special case for drill kicks
    if id == "e9e4" or id == "f2cc" or id == "f51c" then
      fill_missing_boxes(_new_frames)
      current_recording_anim_list[i].cooldown = 6 --debug
    end

    if _frame_data then
      if recording_options.hit_type == "block"
      or recording_options.self_chain then
        for j = 1, #_new_frames - 1 do
          -- local str = "0000000000"
          -- if _frame_data.frames[j] then
          --   str = _frame_data.frames[j].hash
          -- end
          -- print(j-1, str, _new_frames[j].hash)
          if index_of_hash(_frame_data.frames, _new_frames[j].hash) == 0 then
            local _index_of_next_frame = find_exception_position(_frame_data.frames, _new_frames, j + 1) - 1 - 1
            if _index_of_next_frame >= 0 then
              if not _frame_data.exceptions then
                _frame_data.exceptions = {}
              end
              _frame_data.exceptions[_new_frames[j].hash] = _index_of_next_frame
            end
          end
        end
        if _frame_data.exceptions then
          print(_frame_data.exceptions)
        end
      end
    end


    if _frame_data == nil or recording_options.clear_frame_data then
      frame_data[_player_obj.char_str][id] = current_recording_anim_list[i]
    else

      if recording_options.record_frames_after_hit and recording_options.hit_type == "miss" then
        for j = 1, #_new_frames do
          if tonumber(string.sub(_new_frames[j].hash, 9 ,10)) >= 1 then
            _new_frames[j].discard = nil
          end
        end
      end

      local j = 1
      while j <= #_new_frames do
        if _new_frames[j].discard then
          table.remove(_new_frames, j)
        else
          j = j + 1
        end
      end

      local _merged = false
      if recording_options.record_frames_after_hit then
        _merged = force_merge_sequence(_frame_data.frames, _new_frames)
      else
        _merged = merge_sequence(_frame_data.frames, _new_frames)
      end

      local _f = current_recording_anim_list[i].frames

      connect_next_anim(_frame_data, _f, "optional_anim")
      if _merged and not recording_options.ignore_next_anim
      or recording_options.record_next_anim then
        connect_next_anim(_frame_data, _f, "next_anim")
      end

      for j = 1, #_f do
        for k, prop in pairs(props_to_copy) do
          if _f[j][prop] then
            local _index = index_of_hash(_frame_data.frames, _f[j].hash)
            if _index > 0 then
              _frame_data.frames[_index][prop] = _f[j][prop]
            end
          end
        end
      end
    end
  end

  local _ids = {}
  for k,v in pairs(current_recording_anim_list) do
    if not _ids[v.id] then
      _ids[v.id] = v.id
    end
  end

  for _id,_ in pairs(_ids) do
    frame_data[_player_obj.char_str][_id].frames = handle_loops(frame_data[_player_obj.char_str][_id].frames)
  end

  for _id,_ in pairs(_ids) do
    local _anim = frame_data[_player_obj.char_str][_id]
    local _frames = frame_data[_player_obj.char_str][_id].frames

    local _hit_frames = calculate_ranges(_frames, is_hit_frame)
    if #_hit_frames > 0 then
      --make 0 index
      for _k,_f in pairs(_hit_frames) do
        _f[1] = _f[1] - 1
        _f[2] = _f[2] - 1
      end
      _anim.hit_frames = _hit_frames
    end

    _anim.hit_frames = divide_hit_frames(_anim)

    local _idle_frames = calculate_ranges(_frames, is_idle_frame)
    if #_idle_frames > 0 then
      --make 0 index
      for _k,_f in pairs(_idle_frames) do
        _f[1] = _f[1] - 1
        _f[2] = _f[2] - 1
      end
      _anim.idle_frames = _idle_frames
    end

    local _p_index = 1
    local _a_index = 1
    for i = 1, #_frames do
      if _frames[i].pushback then
        if not _anim.pushback then
          _anim.pushback = {}
        end
      _anim.pushback[_p_index] = _frames[i].pushback
      _p_index = _p_index + 1
      end
      if _frames[i].opponent_recovery
      and _frames[i].opponent_freeze then
        if not _anim.advantage then
          _anim.advantage = {}
        end
        local _self_freeze = 0
        if _frames[i].self_freeze then
          _self_freeze =  _frames[i].self_freeze[1]
        end
        _anim.advantage[_a_index] = _frames[i].opponent_freeze[1] + 1 - _self_freeze + _frames[i].opponent_recovery[1]
        _a_index = _a_index + 1
      end
    end
    for i = 1, #_frames do
      if _frames[i].next_anim then
        for _k,_na in pairs(_frames[i].next_anim) do
          if _na.hash then
            local _index = index_of_hash(frame_data[_player_obj.char_str][_na.id].frames, _na.hash)
            if _index == 0 then
              _index = 1
            end
            _frames[i].next_anim[_k] = {_na.id, _index - 1}
          end
        end
      end
      if _frames[i].optional_anim then
        for _k,_na in pairs(_frames[i].optional_anim) do
          if _na.hash then
            local _index = index_of_hash(frame_data[_player_obj.char_str][_na.id].frames, _na.hash)
            if _index == 0 then
              _index = 1
            end
            _frames[i].optional_anim[_k] = {_na.id, _index - 1}
          end
        end
      end
      if _frames[i].loop_start then
        if _anim.loops == nil then
          _anim.loops = {}
        end
        local _l_start = _frames[i].loop_start[1]
        local _l_end = _frames[i].loop_start[2]
        if not table_contains_deep(_anim.loops, {_l_start, _l_end}) then
          table.insert(_anim.loops, {_l_start, _l_end})
          _frames[_l_end + 1].loop = _l_start
        end
      end
    end
  end

  recording = false
  _state = "ready"
end

local _previous_hash = ""

function record_framedata(_player_obj, _projectiles, _name)
  local _player = _player_obj
  local _dummy = _player_obj.other
  local _frame = _player.animation_frame
  local _sign = flip_to_sign(_player.flip_x)

  if recording then

    if _player.has_just_been_blocked or _player.has_just_hit then
      if recording_options.record_frames_after_hit then
        for i = 1, _frame + 1 - 1 do
          current_recording_animation.frames[i].discard = true
        end
      else
        current_recording_animation.discard_all = true
      end
    end
    if recording_options.is_projectile and recording_options.hit_type == "block" then
      current_recording_animation.discard_all = true
    end

    if _player.remaining_freeze_frames > 0 and _player.animation_frame_hash ~= _previous_hash and _player.superfreeze_decount == 0 then
      if #current_recording_animation.frames == 0 then
        _player.animation_start_frame = frame_number
        _player.animation_freeze_frames = 0
        _frame = 0
        bypassing_freeze = true
      elseif not _player.freeze_just_began then
        _player.animation_freeze_frames = _player.animation_freeze_frames - 1
        _frame = frame_number - _player.animation_freeze_frames - _player.animation_start_frame
        bypassing_freeze = true
      end
      if bypassing_freeze then
        print(">", current_recording_animation.id, "bypassing freeze", _frame)
      end
    else
      bypassing_freeze = false
    end

    if not current_recording_animation.frames[_frame + 1] then
      table.insert(current_recording_animation.frames, {})
    end

    if bypassing_freeze then
      current_recording_animation.frames[_frame + 1].bypass_freeze = true
    end

    if _player.has_just_acted then
      current_recording_animation.frames[_frame + 1].hit_start = true
      --ex dra
      if current_recording_animation.id == "b1f4" then
        if _player.action_count > 1 then
          current_recording_animation.frames[_frame + 1].hit_start = nil
        end
      end
    end

    if recording_self_freeze and not recording_options.is_projectile then
      if not current_recording_animation.frames[_frame + 1].self_freeze then
        current_recording_animation.frames[_frame + 1].self_freeze = {} --block, hit, cr. hit
      end
      if recording_options.hit_type == "block" then
        current_recording_animation.frames[_frame + 1].self_freeze[1] = _player.remaining_freeze_frames
      end
    end
    if recording_opponent_freeze and not recording_options.is_projectile then
      if not current_recording_animation.frames[_frame + 1].opponent_freeze then
        current_recording_animation.frames[_frame + 1].opponent_freeze = {} --block, hit, cr. hit
      end
      if recording_options.hit_type == "block" then
        current_recording_animation.frames[_frame + 1].opponent_freeze[1] = _dummy.remaining_freeze_frames
      end
    end
    if recording_recovery and not recording_options.is_projectile then
      if not current_recording_animation.frames[_frame + 1].opponent_recovery then
        current_recording_animation.frames[_frame + 1].opponent_recovery = {} --block, hit, cr. hit
      end
      if recording_options.hit_type == "block" then
        current_recording_animation.frames[_frame + 1].opponent_recovery[1] = _dummy.recovery_time
      end
    end
    if recording_pushback and not recording_options.is_projectile then
      if not current_recording_animation.frames[_frame + 1].pushback then
        current_recording_animation.frames[_frame + 1].pushback = {}
      end
      table.insert(current_recording_animation.frames[_frame + 1].pushback, (_dummy.pos_x - _dummy.previous_pos_x) * _sign)
    end

    if _player.remaining_freeze_frames == 0 or bypassing_freeze then
      --print(string.format("recording frame %d (%d - %d - %d)", _frame, frame_number, _player.animation_freeze_frames, _player.animation_start_frame))

      if _player.standing_state == 1 then current_recording_acceleration_offset = 0 end

      if current_recording_acceleration_offset ~= 0 then
        current_recording_animation.frames[_frame + 1].acceleration_offset = current_recording_acceleration_offset
      end

      local additional_props = {}

      if _player.velocity_x ~= 0
      or _player.velocity_y ~= 0
      or _player.acceleration_x ~= 0
      or _player.acceleration_y ~= 0 then
        additional_props.uses_velocity = true
      end
      if (not recording_options.recording_movement and _frame == 0 and not _player.is_attacking and _player.standing_state == 1)
      or (recording_options.recording_movement and _frame == 0 and not _player.is_attacking and _player.standing_state == 1 and _player.standing_state == 3)
      then
        --recovery animation (landing, after dash, etc)
        clear_motion_data(_player)
        additional_props.uses_velocity = false
        additional_props.landing_frame = true
      end

      local movement_x = (_player.pos_x - _player.previous_pos_x) * _sign
      local movement_y = _player.pos_y - _player.previous_pos_y

      if recording_options.ignore_movement then
        movement_x = 0
        movement_y = 0
      end

      if recording_options.self_chain then
        additional_props.self_chain = true
      end

      if recording_options.insert_wakeup then
        current_recording_animation.frames[_frame + 1].wakeup = true
        recording_options.insert_wakeup = nil
      end

      local _hash = _player.animation_frame_hash
      if recording_options.infinite_loop then
        if #current_recording_anim_list == 1 then
          _hash = string.sub(_hash, 1, 8)
          additional_props.infinite_loop = true
        end
      end

      local _new_frame = {
        boxes = {},
        raw_movement = {movement_x, movement_y},
        hash = _hash,
        frame_id = _player.animation_frame_id,
        frame_id2 = _player.animation_frame_id2,
        raw_velocity = {_player.velocity_x, _player.velocity_y},
        raw_acceleration = {_player.acceleration_x, _player.acceleration_y},
        idle = _player.is_idle
      }

      if recording_options.ignore_motion then
        _new_frame.raw_movement = {0, 0}
        _new_frame.raw_velocity = {0, 0}
        _new_frame.raw_acceleration = {0, 0}
        _new_frame.ignore_motion = true
      end

      for _k,_v in pairs(additional_props) do
        current_recording_animation[_k] = _v
      end

      if current_recording_animation.frames[_frame + 1] then
        for _k,_v in pairs(current_recording_animation.frames[_frame + 1]) do
          _new_frame[_k] = _v
        end
      end

      current_recording_animation.frames[_frame + 1] = _new_frame

      for __, _box in ipairs(_player.boxes) do
        local _type = convert_box_types[_box[1]]
        if (_type == "attack") or (_type == "throw") then
          table.insert(current_recording_animation.frames[_frame + 1].boxes, copytable(_box))
        end
      end

      if recording_options.recording_wakeups or recording_options.recording_movement or recording_options.recording_idle then
        for __, _box in ipairs(_player.boxes) do
          local _type = convert_box_types[_box[1]]
          if (_type == "vulnerability") then
            table.insert(current_recording_animation.frames[_frame + 1].boxes, copytable(_box))
          end
        end
      end
    end
  end
  if (recording or recording_projectiles) and not recording_options.ignore_projectiles then
    local _has_projectiles = false
    for _id, _obj in pairs(_projectiles) do
      if _obj.emitter_id == _player.id then
        _has_projectiles = true
        local _type = _obj.projectile_type

        local _i = index_of_projectile(current_recording_proj_list, _obj)
        if _i == 0 then
          local _dx = _obj.pos_x - _player.pos_x
          local _dy = _obj.pos_y - _player.pos_y
          if _player.flip_x == 0 then _dx = _dx * -1 end


          current_recording_animation.frames[_frame + 1].projectile = {type = _type, offset = {_dx, _dy}}

          local proj_list = {}
          local _data = {name = _name, type = _type, frames = {}, animation_start_frame = frame_number, uses_velocity = true}
          table.insert(proj_list, _data)
          proj_list.object = _obj

          table.insert(current_recording_proj_list, proj_list)
        else
          local _latest = #current_recording_proj_list[_i]
          local _latest_proj = current_recording_proj_list[_i][_latest]
          if not (_latest_proj.type == _type) then
            local _frames = _latest_proj.frames
            if not _frames[#_frames]["next_anim"] then
              _frames[#_frames]["next_anim"] = {}
            end
            if not next_anim_contains(_frames[#_frames]["next_anim"], {_type})  then
              table.insert(_frames[#_frames]["next_anim"], {id = _type, hash = _obj.animation_frame_hash})
            end

            local _data = {name = _name .. "_ext", type = _type, frames = {}, animation_start_frame = frame_number, uses_velocity = true}
            table.insert(current_recording_proj_list[_i], _data)
          end
        end
      end
    end

    if _has_projectiles then
      recording_projectiles = true
    else
      recording_projectiles = false
    end

    for _id, _proj_list in pairs(current_recording_proj_list) do
      local _obj = _proj_list.object
      local _type = _obj.projectile_type

      for _i, _data in ipairs(_proj_list) do
        if _data.type == _type then
          local _f = frame_number - _obj.animation_freeze_frames - _data.animation_start_frame
          if _obj.expired then
            _f = #_data.frames - 1
          end
          if recording_options.hit_type == "block" then
            _data.discard_all = true
          end
          if _obj == current_projectile then
            if recording_pushback or recording_opponent_freeze or recording_recovery then
              if not _data.frames[_f + 1] then
                _data.frames[_f + 1] = {}
              end
            end
            if recording_pushback then
              if not _data.frames[_f + 1].pushback then
                _data.frames[_f + 1].pushback = {}
              end
              table.insert(_data.frames[_f + 1].pushback, (_dummy.pos_x - _dummy.previous_pos_x) * _sign)
            end
            if recording_opponent_freeze then
              if not _data.frames[_f + 1].opponent_freeze then
                _data.frames[_f + 1].opponent_freeze = {}
              end
              _data.frames[_f + 1].opponent_freeze[1] = _dummy.remaining_freeze_frames
            end
            if recording_recovery then
              if not _data.frames[_f + 1].opponent_recovery then
                _data.frames[_f + 1].opponent_recovery = {}
              end
              _data.frames[_f + 1].opponent_recovery[1] = _dummy.recovery_time
            end
          end
          if _obj.remaining_freeze_frames == 0 then

            local movement_x = (_obj.pos_x - _obj.previous_pos_x) * _sign
            local movement_y = _obj.pos_y - _obj.previous_pos_y

            if _i == 1 and _f == 0 then
              movement_x = 0
              movement_y = 0
            end


            local _new_frame = {
              boxes = {},
              raw_movement = {movement_x, movement_y},
              hash = _obj.animation_frame_hash,
              frame_id = _obj.animation_frame_id,
              frame_id2 = _obj.animation_frame_id2,
              frame_id3 = _obj.animation_frame_id3,
              raw_velocity = {_obj.velocity_x, _obj.velocity_y},
              raw_acceleration = {_obj.acceleration_x, _obj.acceleration_y}
            }

            for __, _box in ipairs(_obj.boxes) do
              local _type = convert_box_types[_box[1]]
              if (_type == "attack") or (_type == "throw") then
                table.insert(_new_frame.boxes, copytable(_box))
              end
            end

            if _data.frames[_f + 1] then
              for _k,_v in pairs(_data.frames[_f + 1]) do
                _new_frame[_k] = _v
              end
            end

            _data.frames[_f + 1] = _new_frame
          end
        end
      end
    end
  end

  if _setup and not recording_pushback and not recording_options.ignore_projectiles then
    for _key,_proj_list in pairs(current_recording_proj_list) do
      local _obj = _proj_list.object
      if not table_contains_deep(_projectiles, _obj) then
        process_motion_data(_proj_list)
        for _i, _proj in ipairs(_proj_list) do

          if _proj.discard_all then
            for j = 1, #_proj.frames do
              _proj.frames[j].discard = true
            end
          end
          if _proj.do_not_discard then
            for j = 1, #_proj.frames do
              _proj.frames[j].discard = nil
            end
          end
          local _new_frames = deepcopy(_proj.frames)
          local id = _proj.type

          local _frame_data = frame_data["projectiles"][id]
          if frame_data["projectiles"][id] == nil or overwrite then
            frame_data["projectiles"][id] = _proj
            frame_data["projectiles"].should_save = true
          else
            local j = 1
            while j <= #_new_frames do
              if _new_frames[j].discard then
                table.remove(_new_frames, j)
              else
                j = j + 1
              end
            end

            local _merged = merge_sequence(_frame_data.frames, _new_frames)
            if _merged then
              connect_next_anim(_frame_data, _proj.frames, "next_anim")
            end
            for j = 1, #_proj.frames do
              for k, prop in pairs(props_to_copy) do
                if _proj.frames[j][prop] then
                  local _index = index_of_hash(_frame_data.frames, _proj.frames[j].hash)
                  if _index > 0 then
                    _frame_data.frames[_index][prop] = _proj.frames[j][prop]
                  end
                end
              end
            end

            frame_data["projectiles"].should_save = true
          end
        end

        local _ids = {}
        for _i, _proj in ipairs(_proj_list) do
          if not _ids[_proj.type] then
            _ids[_proj.type] = _proj.type
          end
        end

        for _id,_ in pairs(_ids) do
          local _frame_data = frame_data["projectiles"][_id]
          _frame_data.frames = handle_loops(_frame_data.frames)

          local _p_index = 1
          local _anim = frame_data["projectiles"][_id]
          local _frames = _frame_data.frames

          for i = 1, #_frames do
            if _frames[i].pushback then
              if not _frames.pushback then
                _frames.pushback = {}
              end
            _frames.pushback[_p_index] = _frames[i].pushback
            _p_index = _p_index + 1
            end
            if _frames[i].loop_start then
              if _anim.loops == nil then
                _anim.loops = {}
              end
              local _l_start = _frames[i].loop_start[1]
              local _l_end = _frames[i].loop_start[2]
              if not table_contains_deep(_anim.loops, {_l_start, _l_end}) then
                table.insert(_anim.loops, {_l_start, _l_end})
                _frames[_l_end + 1].loop = _l_start
              end
            end
            if _frames[i].next_anim then
              for _k,_na in pairs(_frames[i].next_anim) do
                if _na.hash then
                  local _index = index_of_hash(frame_data["projectiles"][_na.id].frames, _na.hash)
                  if _index == 0 then
                    _index = 1
                  end
                  _frames[i].next_anim[_k] = {_na.id, _index - 1}
                end
              end
            end
          end
        end

      current_recording_proj_list[_key] = nil
      end
    end

    _previous_hash = _player.animation_frame_hash
  end
end


function index_of_projectile(_list, _proj)
  for _k,_v in pairs(_list) do
    if _v.object == _proj then
      return _k
    end
  end
  return 0
end

function index_of_hash(_t, _s)
  for i = 1, #_t do
    if _t[i].hash == _s then
      return i
    end
  end
  return 0
end

function next_anim_contains(_t, _v)
  _v = _v.id or _v[1]
  for _,_val in pairs(_t) do
    local _id = _val.id or _val[1]
    if _id == _v then
      return true
    end
  end
  return false
end

function index_of_frames(_t1, _t2)
  i_search = 1
  i_seq = 1
  i_begin = 1
  while i_begin + #_t2.frames - 1 <= #_t1.frames do
    if _t2.frames[i_seq].hash == _t1.frames[i_search].hash then
      if i_seq == #_t2.frames then
          return i_begin
      end
    else
      i_seq = 0
      i_begin = i_begin + 1
      i_search = i_begin - 1
    end
    i_seq = i_seq + 1
    i_search = i_search + 1
  end
  return 0
end

function merge_sequence(_existing, _incoming)
  local ne, ni = #_existing, #_incoming
  for k = math.min(ne, ni), 1, -1 do
    local matching = true
    for i = 1, k do
      if _existing[ne - k + i].hash ~= _incoming[i].hash then
        matching = false
        break
      end
    end
    if matching then
      --append unmatched tail
      for j = k + 1, ni do
        table.insert(_existing, _incoming[j])
      end
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
      if _existing[i].hash ~= _incoming[ni - k + i].hash then
        matching = false
        break
      end
    end
    if matching then
      --adjust loops
      for j = 1, #_existing do
        if _existing[j].loop_start then
          _existing[j].loop_start[1] = _existing[j].loop_start[1] + (ni - k)
          _existing[j].loop_start[2] = _existing[j].loop_start[2] + (ni - k)
        end
      end
      --prepend unmatched head
      for j = 1, ni - k do
        table.insert(_existing, 1, _incoming[j])
      end
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
      if _existing[i + j - 1].hash ~= _incoming[j].hash then
        match = false
        break
      end
    end
    if match then
--       print("subset")
      return false
    end
  end

  --no overlap, append
  for k = 1, ni do
    table.insert(_existing, _incoming[k])
  end
--   print("no matches, appended", ne, ni)
  return true
end

function force_merge_sequence(_existing, _incoming)
  -- for i = 1, #_existing do
  --   print(_existing[i].hash)
  -- end
  local _merged = false
  local i_incoming = 1
  while i_incoming < #_incoming do
    local index = index_of_hash(_existing, _incoming[i_incoming].hash)
    if index > 0 then
      local i = 0
      while i_incoming + i <= #_incoming do
        local _boxes = nil
        if _existing[index + i] and _existing[index + i].boxes then
          _boxes = _existing[index + i].boxes
        end
        _existing[index + i] = _incoming[i_incoming + i]
        if _boxes then
          _existing[index + i].boxes = _boxes
        end
        i = i + 1
      end
      _merged = true
      break
    else
      i_incoming = i_incoming + 1
    end
  end
  if not _merged then
    for i = 1, #_incoming do
      table.insert(_existing, _incoming[i])
    end
  end
  for j = 2, #_existing do
    _existing[j].hit_start = nil
    if string.sub(_existing[j - 1].hash, 9, 10) ~= string.sub(_existing[j].hash, 9, 10) then
      _existing[j].hit_start = true
    end
  end
  -- for i = 1, #_incoming do
  --   print(_incoming[i].hash)
  -- end

  print("merged",_merged)
  return _merged
end

function fill_missing_boxes(_frames)
  local segments = {}
  local in_segment = false
  local seg_start = 0

  for i = 1, #_frames do
    local has_boxes = #_frames[i].boxes > 0
    if not has_boxes then
      if not in_segment then
        if i > 1 and #_frames[i-1].boxes > 0 then
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
  for _, _seg in pairs(segments) do
    for i = _seg.start, _seg.stop do
      _frames[i].boxes = _frames[_seg.start - 1].boxes
    end
  end
end

function connect_next_anim(_frame_data, _f, _next_anim_type)
  if #_f > 0 then
    if _f[#_f][_next_anim_type] then
      local _index = index_of_hash(_frame_data.frames, _f[#_f].hash)
      if _index > 0 then
        if not _frame_data.frames[_index][_next_anim_type] then
          _frame_data.frames[_index][_next_anim_type] = {}
        end
        if _f[#_f][_next_anim_type] then
          for  j = 1, #_f[#_f][_next_anim_type] do
            if not next_anim_contains(_frame_data.frames[_index][_next_anim_type], _f[#_f][_next_anim_type][j]) then
              table.insert(_frame_data.frames[_index][_next_anim_type], _f[#_f][_next_anim_type][j])
            end
          end
        end
      end
    end
  end
end

function process_motion_data(_anim_list)
  local _all_frames = {}
  local _uses_velocity = {}
  local _ignore_motion = {}
  for i = 1, #_anim_list do
    if _anim_list[i].landing_frame then
      _anim_list[i].frames[1].raw_movement = {0, 0}
    end
    for j = 1, #_anim_list[i].frames do
      table.insert(_all_frames, _anim_list[i].frames[j])
      table.insert(_uses_velocity, _anim_list[i].uses_velocity or false)
      table.insert(_ignore_motion, _anim_list[i].frames[j].ignore_motion or false)
    end
  end
  for i = 1, #_all_frames do
    if _all_frames[i].acceleration_offset and not _all_frames[i].ignore_motion then
      _all_frames[i].raw_acceleration[2] = _all_frames[i].raw_acceleration[2] - _all_frames[i].acceleration_offset
      _all_frames[i].raw_velocity[2] = _all_frames[i].raw_velocity[2] - _all_frames[i].acceleration_offset
      for j = i + 1, #_all_frames do
        if _uses_velocity[j] then
          _all_frames[j].raw_velocity[2] = _all_frames[j].raw_velocity[2] - _all_frames[i].acceleration_offset
          _all_frames[j].raw_movement[2] = _all_frames[j].raw_movement[2] - _all_frames[i].acceleration_offset
        end
      end
      _all_frames[i].acceleration_offset = nil
    end
  end
  for i = #_all_frames, 1, -1 do
    if _all_frames[i].raw_movement and _all_frames[i].raw_velocity and _all_frames[i].raw_acceleration then
      if i - 1 >= 1 and _all_frames[i - 1].raw_movement and _all_frames[i - 1].raw_velocity and _all_frames[i - 1].raw_acceleration then
        _all_frames[i].movement = {}
        _all_frames[i].velocity = {}
        _all_frames[i].acceleration = {}

        _all_frames[i].movement[1] = _all_frames[i].raw_movement[1]
        _all_frames[i].movement[2] = _all_frames[i].raw_movement[2]
        _all_frames[i].velocity[1] = _all_frames[i].raw_velocity[1]
        _all_frames[i].velocity[2] = _all_frames[i].raw_velocity[2]
        _all_frames[i].acceleration[1] = _all_frames[i].raw_acceleration[1]
        _all_frames[i].acceleration[2] = _all_frames[i].raw_acceleration[2]

        -- print(i, _all_frames[i].raw_movement, _all_frames[i].raw_velocity, _all_frames[i].raw_acceleration)

        if _uses_velocity[i] and not _ignore_motion[i] then
          _all_frames[i].movement[1] = _all_frames[i].movement[1] - _all_frames[i - 1].raw_velocity[1]
          _all_frames[i].movement[2] = _all_frames[i].movement[2] - _all_frames[i - 1].raw_velocity[2]
          _all_frames[i].velocity[1] = _all_frames[i].velocity[1] - _all_frames[i - 1].raw_velocity[1]
          _all_frames[i].velocity[2] = _all_frames[i].velocity[2] - _all_frames[i - 1].raw_velocity[2]

          if _all_frames[i].raw_velocity[1] - _all_frames[i - 1].raw_velocity[1] ~= 0 then
            _all_frames[i].velocity[1] = _all_frames[i].velocity[1] - _all_frames[i - 1].raw_acceleration[1]
          end
          if _all_frames[i].raw_velocity[2] - _all_frames[i - 1].raw_velocity[2] ~= 0 then
            _all_frames[i].velocity[2] = _all_frames[i].velocity[2] - _all_frames[i - 1].raw_acceleration[2]
          end

          _all_frames[i].acceleration[1] = _all_frames[i].acceleration[1] - _all_frames[i - 1].raw_acceleration[1]
          _all_frames[i].acceleration[2] = _all_frames[i].acceleration[2] - _all_frames[i - 1].raw_acceleration[2]
        end

        _all_frames[i].raw_movement = nil
        _all_frames[i].raw_velocity = nil
        _all_frames[i].raw_acceleration = nil
      else
        _all_frames[i].movement = {_all_frames[i].raw_movement[1], _all_frames[i].raw_movement[2]}
        _all_frames[i].velocity = {_all_frames[i].raw_velocity[1], _all_frames[i].raw_velocity[2]}
        _all_frames[i].acceleration = {_all_frames[i].raw_acceleration[1], _all_frames[i].raw_acceleration[2]}

        _all_frames[i].raw_movement = nil
        _all_frames[i].raw_velocity = nil
        _all_frames[i].raw_acceleration = nil
      end
    end
  end
end


function handle_loops(_frames)
  local n = #_frames
  if n < 2 then return _frames end

  local dp = {}
  for i = n, 1, -1 do
    dp[i] = {}
    for j = n, 1, -1 do
      if j > i
         and (_frames[i].hash == _frames[j].hash)
         and dp[i+1] and dp[i+1][j+1] then
        dp[i][j] = dp[i+1][j+1] + 1
      else
        dp[i][j] = 0
      end
    end
  end

  local search_start = 1
  for i = 1, #_frames do
    if _frames[i].loop_start then
      search_start = math.min(_frames[i].loop_start[2] + 2, #_frames)
    end
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
          if _frames[k].loop_start then
            _frames[k].loop_start = nil
          end
          out[#out + 1] = _frames[k]
        end
        for k = i + L, #_frames do
          if _frames[k].loop_start then
            _frames[k].loop_start[1] = _frames[k].loop_start[1] - L
            _frames[k].loop_start[2] = _frames[k].loop_start[2] - L
          end
        end
        seq_end = #out
        out[seq_start].loop_start = {seq_start - 1, seq_end - 1}
        local removed_start = j
        for k = 0, L - 1 do
          copy_props(_frames[removed_start + k], out[seq_start + k], next_anim_types)
          copy_props(_frames[removed_start + k], out[seq_start + k], props_to_copy)
        end

        i = i + 2 * L
        removed = true
        loop_found = true
        break
      end
    end
    if not removed then
      out[#out + 1] = _frames[i]
      i = i + 1
    end
  end

  if loop_found then
    return handle_loops(out)
  end

  --remove partial repeats
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

function copy_props(_source_frame, _dest_frame, _props_to_copy)
  for _,_prop in pairs(_props_to_copy) do
    if _source_frame[_prop] then
      _dest_frame[_prop] = _source_frame[_prop]
    end
  end
end

function find_seq_start(_existing, _incoming)
  local ne, ni = #_existing, #_incoming
  for k = math.min(ne, ni), 1, -1 do
    for i = 1, k do
      if _existing[ne - k + i].hash == _incoming[i].hash then
        print(ne - k + i, i)
        return ne - k + i, i
      end
    end
  end
  return nil
end

function find_exception_position(_existing, _incoming, _index)
  for i = 1, #_existing do
    if _existing[i].hash == _incoming[_index].hash then
      return i
    end
  end
  if _index + 1 <= #_incoming then
    return find_exception_position(_existing, _incoming, _index + 1) - 1
  end
  return 0
end

function sequence_to_name(_seq)
  local btn = ""
  local ud = ""
  local bf = ""
  for k,v in pairs(_seq[1]) do
    if v == "LP" or v == "MP" or v == "HP"
    or v == "LK" or v == "MK" or v == "HK" then
      if btn == "" then
        btn = v
      else
        btn = btn .. "+" .. v
      end
    elseif v == "down" then
      ud = "d"
    elseif v == "up" then
      ud = "u"
    elseif v == "forward" then
      bf = "f"
    elseif v == "back" then
      bf = "b"
    end
  end
  if string.len(ud .. bf) > 0 then
    return ud .. bf .. "_" .. btn
  end
  return btn
end
