local gamestate = require("src.gamestate")
local fd = require("src.data.framedata")
local move_data = require("src.data.move_data")
local inputs = require("src.control.inputs")
local advanced_control = require("src.control.advanced_control")
local tools = require("src.tools")

local Delay = advanced_control.Delay
local is_idle_timing, is_wakeup_timing, is_landing_timing = advanced_control.is_idle_timing,
                                                            advanced_control.is_wakeup_timing,
                                                            advanced_control.is_landing_timing
local queue_input_sequence_and_wait = advanced_control.queue_input_sequence_and_wait

-- manually charge tackles so we don't do something impossible
local function urien_midscreen_setup_tackle_dash(player)
   local d_hp = {{"down", "HP"}}
   local mk_tackle = {{"forward", "MK"}}

   local hp_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "HP")
   local hk_tackle = {{"forward", "HK"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")

   local crouch = {
      {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"},
      {"down"}, {"down"}, {"down"}
   }
   local charge_tackle = {}
   for i = 1, 80 do charge_tackle[#charge_tackle + 1] = {"down", "back"} end
   local charge_delay = 43
   local charge = Delay:new(charge_delay)

   local cancel_delay = Delay:new(0)
   local hk_tackle_delay = Delay:new(0)

   if player.other.char_str == "makoto" then hk_tackle_delay:reset(4) end
   if player.other.char_str == "elena" then hk_tackle_delay:reset(4) end
   local commands = {
      {
         condition = nil,
         action = function()
            queue_input_sequence_and_wait(player, d_hp, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_delay + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, mk_tackle) end
      }, {
         condition = function() return cancel_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, hp_aegis, 0, true) end
      }, {
         condition = nil,
         action = function()
            inputs.queue_input_sequence(player, charge_tackle, 0, true)
            charge:begin(charge_delay)
         end
      }, {
         condition = function()
            return hk_tackle_delay:delay_after_idle_timing(player, #hk_tackle) and charge:is_complete()
         end,
         action = function() queue_input_sequence_and_wait(player, hk_tackle) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, #mp_headbutt, false) end,
         action = function() queue_input_sequence_and_wait(player, mp_headbutt) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
   }
   return commands
end

local function urien_midscreen_setup_ex_head_sphere(player)
   local d_hp = {{"down", "HP"}}
   local ex_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "EXP")
   local sphere = move_data.get_move_inputs_by_name("urien", "metallic_sphere", "LP")
   local mp_aegis = {{"down"}, {"down", "forward"}, {"forward", "MP"}}
   local mp = {{"MP"}}
   local hk_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")

   local cancel_timing = 15
   local sphere_timing = 2
   local head_delay = Delay:new(0)

   if player.other.char_str == "alex" or player.other.char_str == "dudley" or player.other.char_str == "makoto" or
       player.other.char_str == "necro" or player.other.char_str == "twelve" or player.other.char_str == "ibuki" then
      sphere_timing = 6
   elseif player.other.char_str == "remy" then
      sphere_timing = 6
      head_delay:reset(4)
   elseif player.other.char_str == "oro" then
      sphere_timing = 4
   elseif player.other.char_str == "yang" or player.other.char_str == "yun" then
      sphere_timing = 4
   elseif player.other.char_str == "chunli" or player.other.char_str == "urien" or player.other.char_str == "gill" then
      sphere_timing = 9
   elseif player.other.char_str == "hugo" then
      sphere = move_data.get_move_inputs_by_name("urien", "metallic_sphere", "MP")
      sphere_timing = 4
   end
   local delay = Delay:new(sphere_timing)

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, d_hp, 0, true) end}, {
         condition = function() return head_delay:delay_after_idle_timing(player, #ex_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, ex_headbutt) end
      }, {
         condition = function() return delay:delay_after_idle_timing(player, #sphere, false) end,
         action = function()
            queue_input_sequence_and_wait(player, sphere, 0, true)
            delay:begin(cancel_timing)
         end
      }, {
         condition = function() return delay:is_complete() end,
         action = function() inputs.queue_input_sequence(player, mp_aegis) end
      }, {
         condition = function() return is_idle_timing(player, #mp) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, hk_knee) end
      }
   }

   return commands
end

local function urien_midscreen_setup_ex_head_standard(player)
   local d_hp = {{"down", "HP"}}
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")
   local ex_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "EXP")
   local lp_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
   local mk_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "MK")

   local head_delay = Delay:new(2)

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, d_hp) end}, {
         condition = function() return is_idle_timing(player, #ex_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, ex_headbutt) end
      }, {
         condition = function() return head_delay:delay_after_idle_timing(player, #mp_headbutt, false) end,
         action = function() queue_input_sequence_and_wait(player, mp_headbutt) end
      }, {
         condition = function() return is_idle_timing(player, #lp_aegis, false) end,
         action = function() queue_input_sequence_and_wait(player, lp_aegis) end
      }, {
         condition = function() return is_idle_timing(player, #mk_knee, false) end,
         action = function() queue_input_sequence_and_wait(player, mk_knee) end
      }
   }
   return commands
end

local function urien_corner_setup_tackle_mk_mk_mk_hk_q_remy(player)
   local d_HP = {{"down", "HP"}}
   local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")

   local MK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "MK")
   local delay = Delay:new(66)
   local aegis_delay = Delay:new(10)

   local charge_time = 43
   local charge = Delay:new(charge_time)

   local mk_tackle = {{"forward", "MK"}}
   local hk_tackle = {{"forward", "HK"}}

   local charge_tackle = {}
   for i = 1, 60 do charge_tackle[#charge_tackle + 1] = {"down", "back"} end

   local commands = {
      {
         condition = nil,
         action = function()
            queue_input_sequence_and_wait(player, d_HP, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #hk_tackle, false) and charge:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, hk_tackle, 0, true) end
      }, {
         condition = function() return aegis_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, LP_aegis) end
      }, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, MK_knee) end
      }
   }
   return commands
end

local function urien_corner_setup_tackle_mk_mk_mk_hk(player)
   local d_HP = {{"down", "HP"}}
   local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")

   local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
   local delay = Delay:new(66)
   local aegis_delay = Delay:new(10)

   local charge_time = 43
   local charge = Delay:new(charge_time)

   local mk_tackle = {{"forward", "MK"}}
   local hk_tackle = {{"forward", "HK"}}

   local charge_tackle = {}
   for i = 1, 60 do charge_tackle[#charge_tackle + 1] = {"down", "back"} end

   local commands = {
      {
         condition = nil,
         action = function()
            queue_input_sequence_and_wait(player, d_HP, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #hk_tackle, false) and charge:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, hk_tackle, 0, true) end
      }, {
         condition = function() return aegis_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, LP_aegis) end
      }, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, HK_knee) end
      }
   }
   return commands
end

local function urien_corner_setup_tackle_mk_mk_mk_mk(player)
   local d_HP = {{"down", "HP"}}
   local LK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "LK")

   local MK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "MK")
   local HK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "HK")
   local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
   local back_dash = {{"back"}, {}, {"back"}}
   local LK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "LK")

   local MK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "MK")
   local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
   local walk_back = {
      {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"},
      {"back"}
   }
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}
   }
   local crouch = {
      {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"},
      {"down"}, {"down"}, {"down"}
   }
   local delay = Delay:new(66)
   local aegis_delay = Delay:new(10)

   local charge_time = 43

   local charge = Delay:new(charge_time)

   local mk_tackle = {{"forward", "MK"}}
   local hk_tackle = {{"forward", "HK"}}

   local charge_tackle = {}
   for i = 1, 60 do charge_tackle[#charge_tackle + 1] = {"down", "back"} end
   local knee = HK_knee

   if player.other.char_str == "yang" or player.other.char_str == "yun" then knee = MK_knee end

   local commands = {
      {
         condition = nil,
         action = function()
            queue_input_sequence_and_wait(player, d_HP, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, mk_tackle, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #mk_tackle, false) and charge:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, mk_tackle, 0, true) end
      }, {
         condition = function() return aegis_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, LP_aegis) end
      }, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, knee) end
      }

   }
   return commands
end

local function urien_corner_setup_alex(player)
   local d_HP = {{"down", "HP"}}
   local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
   local LP_sphere = move_data.get_move_inputs_by_name("urien", "metallic_sphere", "LP")

   local MK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "MK")
   local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
   local walk_back = {
      {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"},
      {"back"}
   }
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}
   }
   local crouch = {
      {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"}, {"down"},
      {"down"}, {"down"}, {"down"}
   }
   local delay = Delay:new(66)
   local aegis_delay = Delay:new(10)

   local charge_time = 43

   local charge = Delay:new(charge_time)

   local lk_tackle = {{"forward", "LK"}}
   local mk_tackle = {{"forward", "MK"}}

   local charge_tackle = {}
   for i = 1, 60 do charge_tackle[#charge_tackle + 1] = {"down", "back"} end
   local knee = HK_knee

   local commands = {
      {
         condition = nil,
         action = function()
            queue_input_sequence_and_wait(player, d_HP, 0, true)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #lk_tackle, false) and charge:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, lk_tackle) end
      }, {
         condition = function() return is_idle_timing(player, #LP_sphere) end,
         action = function()
            queue_input_sequence_and_wait(player, LP_sphere)
            Queue_Command(gamestate.frame_number + #LP_sphere,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return is_idle_timing(player, #lk_tackle, false) and charge:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, lk_tackle)
            Queue_Command(gamestate.frame_number + 1,
                          function() inputs.queue_input_sequence(player, charge_tackle, 0, true) end)
            charge:begin(charge_time + 1)
         end
      }, {
         condition = function() return aegis_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, LP_aegis) end
      }, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, knee) end
      }
   }
   return commands
end

local function urien_midscreen_setup_anago(player)
   local d_HP = {{"down", "HP"}}
   local ex_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "EXP")
   local forward_dash = {{"forward"}, {}, {"forward"}}

   local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
   local back_dash = {{"back"}, {}, {"back"}}

   local walk_back = {
      {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"},
      {"back"}
   }
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}
   }

   local aegis_delay = Delay:new(6)
   local walk_delay = Delay:new(10)

   if player.other.char_str == "hugo" then walk_delay:reset(11) end

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, d_HP, 0, true) end}, {
         condition = function() return is_idle_timing(player, #ex_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, ex_headbutt) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return walk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, d_HP, 0, true) end
      }, {
         condition = function() return aegis_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, LP_aegis) end
      }
   }
   return commands
end

local function urien_midscreen_tackle_dash_followup_f_mk(player)
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}, {"forward"}
   }
   local f_mk = {{"forward", "MK"}}
   local d_hp = {{"down", "HP"}}

   local anim, fdata = fd.find_frame_data_by_name("urien", "f_MK")
   local f_mk_hit_frame = 0
   if fdata then f_mk_hit_frame = fdata.hit_frames[1][1] end

   local commands = {
      {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return is_wakeup_timing(player.other, f_mk_hit_frame - 2, true) end,
         action = function() queue_input_sequence_and_wait(player, f_mk) end
      }, {
         condition = function() return is_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }

   if player.other.char_str == "chunli" then
      local dash = {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
      table.insert(commands, 1, dash)
   end

   return commands
end

local function urien_midscreen_tackle_dash_followup_d_lk(player)
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}, {"forward"}
   }
   local d_lk = {{"down", "LK"}}
   local d_hp = {{"down", "HP"}}

   local anim, fdata = fd.find_frame_data_by_name("urien", "d_LK")
   local d_lk_hit_frame = 0
   if fdata then d_lk_hit_frame = fdata.hit_frames[1][1] end

   local commands = {
      {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return is_wakeup_timing(player.other, d_lk_hit_frame - 2, true) end,
         action = function() queue_input_sequence_and_wait(player, d_lk) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }

   if player.other.char_str == "chunli" then
      local dash = {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
      table.insert(commands, 1, dash)
   end

   return commands
end

local function urien_midscreen_tackle_dash_followup_throw(player)
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}, {"forward"}
   }
   local throw = {{"forward", "LP", "LK"}}
   local throw_anim, fdata = fd.find_frame_data_by_name("urien", "throw_neutral")

   local delay = Delay:new(12)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function()
            local throw_range = player.pos_x + (fd.get_hitbox_max_range(player.char_str, throw_anim, 1) - 16) *
                                    tools.flip_to_sign(player.flip_x)
            return math.abs(throw_range - player.other.pos_x) <=
                       fd.character_specific[player.other.char_str].pushbox_width / 2
         end,
         action = function() inputs.clear_input_sequence(player) end
      }, {condition = function() return player.other.has_just_parried end, action = nil}, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, throw) end
      }
   }

   if player.other.char_str == "chunli" then
      local dash = {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
      table.insert(commands, 1, dash)
   elseif player.other.char_str == "makoto" then
      local walk_delay = Delay:new(14)
      commands[2] = {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function()
            inputs.queue_input_sequence(player, walk_forward)
            walk_delay:begin()
         end
      }
      commands[3] = {
         condition = function() return walk_delay:is_complete() end,
         action = function() inputs.clear_input_sequence(player) end
      }
   end

   return commands
end

local function urien_mid_screen_ex_head_sphere_followup_f_mk(player)
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")
   local f_mk = {{"forward", "MK"}}
   local walk_back = {
      {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"},
      {"back"}
   }
   local d_hp = {{"down", "HP"}}

   local anim, fdata = fd.find_frame_data_by_name("urien", "f_MK")
   local f_mk_hit_frame = 0
   if fdata then f_mk_hit_frame = fdata.hit_frames[1][1] end

   local delay = Delay:new(4)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #mp_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, mp_headbutt) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_back) end
      }, {
         condition = function()
            return is_idle_timing(player, #f_mk) and is_wakeup_timing(player.other, f_mk_hit_frame - 2, true)
         end,
         action = function() queue_input_sequence_and_wait(player, f_mk) end
      }, {
         condition = function() return delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_mid_screen_ex_head_sphere_followup_jump_hk(player)
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")
   local jump = {{"up"}, {"up"}}
   local u_hk = {{"HK"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local jump_delay = Delay:new(10)
   local hk_delay = Delay:new(22)
   if player.other.char_str == "sean" or player.other.char_str == "ryu" or player.other.char_str == "gouki" then
      jump_delay:reset(11)
   elseif player.other.char_str == "alex" then
      jump_delay:reset(4)
      hk_delay:reset(21)
   elseif player.other.char_str == "chunli" then
      jump_delay:reset(23)
   elseif player.other.char_str == "dudley" then
      jump_delay:reset(0)
      hk_delay:reset(22)
   elseif player.other.char_str == "ibuki" then
      jump_delay:reset(0)
      hk_delay:reset(22)
   elseif player.other.char_str == "makoto" then
      jump_delay:reset(22)
      hk_delay:reset(23)
   elseif player.other.char_str == "necro" then
      jump_delay:reset(0)
   elseif player.other.char_str == "oro" then
      jump_delay:reset(8)
   elseif player.other.char_str == "remy" then
      jump_delay:reset(0)
      hk_delay:reset(23)
   elseif player.other.char_str == "shingouki" then
      jump_delay:reset(9)
   elseif player.other.char_str == "twelve" then
      jump_delay:reset(0)
      hk_delay:reset(20)
   elseif player.other.char_str == "yang" then
      jump_delay:reset(0)
   elseif player.other.char_str == "yun" then
      jump_delay:reset(0)
      hk_delay:reset(23)
   elseif player.other.char_str == "hugo" then
      jump_delay:reset(0)
      hk_delay:reset(23)
   end

   local commands = {
      {
         condition = function() return is_idle_timing(player, #mp_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, mp_headbutt) end
      }, {
         condition = function() return jump_delay:delay_after_idle_timing(player, #jump, true) end,
         action = function() queue_input_sequence_and_wait(player, jump) end
      }, {
         condition = function() return hk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, u_hk) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }

   if player.other.char_str == "hugo" then table.remove(commands, 4) end

   return commands
end

local function urien_mid_screen_ex_head_sphere_followup_d_lk(player)
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")
   local d_lk = {{"down", "LK"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local anim, fdata = fd.find_frame_data_by_name("urien", "d_LK")
   local d_lk_hit_frame = 0
   if fdata then d_lk_hit_frame = fdata.hit_frames[1][1] end

   local delay = Delay:new(4)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #mp_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, mp_headbutt) end
      }, {
         condition = function() return is_wakeup_timing(player.other, d_lk_hit_frame - 2, true) end,
         action = function() queue_input_sequence_and_wait(player, d_lk) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_mid_screen_ex_head_sphere_followup_throw(player)
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}, {"forward"}
   }
   local throw = {{"forward", "LP", "LK"}}
   local throw_anim, fdata = fd.find_frame_data_by_name("urien", "throw_neutral")

   local delay = Delay:new(12)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #mp_headbutt) end,
         action = function() queue_input_sequence_and_wait(player, mp_headbutt) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function()
            local throw_range = player.pos_x + (fd.get_hitbox_max_range(player.char_str, throw_anim, 1) - 16) *
                                    tools.flip_to_sign(player.flip_x)
            return math.abs(throw_range - player.other.pos_x) <=
                       fd.character_specific[player.other.char_str].pushbox_width / 2
         end,
         action = function() inputs.clear_input_sequence(player) end
      }, {condition = function() return player.other.has_just_parried end, action = nil}, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, throw) end
      }
   }
   return commands
end

local function urien_mid_screen_ex_head_standard_followup_leap(player)
   local walk_forward = {{"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}}
   local uoh = {{"MP", "MK"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local d_hp_delay = Delay:new(4)

   local anim, fdata = fd.find_frame_data_by_name("urien", "uoh")
   local uoh_hit_frame = 0
   if fdata then uoh_hit_frame = fdata.hit_frames[1][1] end

   local commands = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function()
            return is_idle_timing(player, #uoh) and is_wakeup_timing(player.other, uoh_hit_frame - 7, true)
         end,
         action = function() queue_input_sequence_and_wait(player, uoh) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return d_hp_delay:delay_after_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }

   if player.other.char_str == "hugo" then table.remove(commands, 4) end

   return commands
end

local function urien_mid_screen_ex_head_standard_followup_f_mk(player)
   local walk_forward = {{"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}}
   local f_mk = {{"forward", "MK"}}
   local d_hp = {{"down", "HP"}}

   local anim, fdata = fd.find_frame_data_by_name("urien", "f_MK")
   local f_mk_hit_frame = 0
   if fdata then f_mk_hit_frame = fdata.hit_frames[1][1] end

   local delay = Delay:new(4)

   local commands = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function()
            return is_idle_timing(player, #f_mk) and is_wakeup_timing(player.other, f_mk_hit_frame - 2, true)
         end,
         action = function() queue_input_sequence_and_wait(player, f_mk) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return delay:delay_after_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_mid_screen_ex_head_standard_followup_d_lk(player)
   local walk_forward = {{"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}}
   local d_lk = {{"down", "LK"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local anim, fdata = fd.find_frame_data_by_name("urien", "d_LK")
   local d_lk_hit_frame = 0
   if fdata then d_lk_hit_frame = fdata.hit_frames[1][1] end

   local delay = Delay:new(0)

   local commands = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return is_wakeup_timing(player.other, d_lk_hit_frame - 2, true) end,
         action = function() queue_input_sequence_and_wait(player, d_lk) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return delay:delay_after_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_mid_screen_ex_head_standard_followup_throw(player)
   local mp_headbutt = move_data.get_move_inputs_by_name("urien", "dangerous_headbutt", "MP")
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}, {"forward"}
   }
   local throw = {{"forward", "LP", "LK"}}
   local throw_anim, fdata = fd.find_frame_data_by_name("urien", "throw_neutral")

   local delay = Delay:new(12)

   local commands = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function()
            local throw_range = player.pos_x + (fd.get_hitbox_max_range(player.char_str, throw_anim, 1) - 16) *
                                    tools.flip_to_sign(player.flip_x)
            return math.abs(throw_range - player.other.pos_x) <=
                       fd.character_specific[player.other.char_str].pushbox_width / 2
         end,
         action = function() inputs.clear_input_sequence(player) end
      }, {condition = function() return player.other.has_just_parried end, action = nil}, {
         condition = function() return delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, throw) end
      }
   }
   return commands
end

local function urien_mid_screen_anago_followup_d_lk(player)
   local walk_back = {}
   for i = 1, 20 do walk_back[#walk_back + 1] = {"back"} end
   local d_lk = {{"down", "LK"}}
   local d_mk = {{"down", "MK"}}
   local d_lp = {{"down", "LP"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local walk_delay = Delay:new(8)
   if player.other.char_str == "hugo" or player.other.char_str == "dudley" or player.other.char_str == "necro" then
      walk_delay:reset(10)
   elseif player.other.char_str == "alex" then
      walk_delay:reset(12)
   elseif player.other.char_str == "ken" or player.other.char_str == "ryu" or player.other.char_str == "gouki" then
      walk_delay:reset(16)
   elseif player.other.char_str == "ibuki" then
      walk_delay:reset(18)
   elseif player.other.char_str == "makoto" then
      walk_delay:reset(18)
   end

   local cancel_delay = Delay:new(6)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_back) end
      }, {
         condition = function() return walk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, d_lk) end
      }, {
         condition = function() return is_idle_timing(player, #d_mk, true) end,
         action = function() queue_input_sequence_and_wait(player, d_mk) end
      }, {
         condition = function() return is_idle_timing(player, #d_mk, true) end,
         action = function() queue_input_sequence_and_wait(player, d_mk) end
      }, {
         condition = function() return is_idle_timing(player, #d_lp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_lp) end
      }, {
         condition = function() return cancel_delay:delay_after_connection(player) end,
         action = function() queue_input_sequence_and_wait(player, d_lp) end
      }, {
         condition = function() return is_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_mid_screen_anago_followup_d_lk_dash(player)
   local walk_back = {}
   for i = 1, 20 do walk_back[#walk_back + 1] = {"back"} end
   local d_lk = {{"down", "LK"}}
   local d_mk = {{"down", "MK"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local walk_delay = Delay:new(8)
   if player.other.char_str == "hugo" or player.other.char_str == "alex" then
      walk_delay:reset(10)
   elseif player.other.char_str == "ibuki" then
      walk_delay:reset(16)
   end

   local d_hp_delay = Delay:new(4)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_back) end
      }, {
         condition = function() return walk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, d_lk) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return d_hp_delay:delay_after_idle(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_mid_screen_anago_followup_f_mk(player)
   local walk_back = {}
   for i = 1, 20 do walk_back[#walk_back + 1] = {"back"} end
   local d_lk = {{"down", "LK"}}
   local d_mk = {{"down", "MK"}}
   local f_mk = {{"forward", "MK"}}
   local d_lp = {{"down", "LP"}}
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local d_hp = {{"down", "HP"}}

   local d_hp_delay = Delay:new(0)
   local walk_delay = Delay:new(10)
   if player.other.char_str == "hugo" or player.other.char_str == "chunli" or player.other.char_str == "alex" then
      walk_delay:reset(6)
   elseif player.other.char_str == "yang" or player.other.char_str == "dudley" or player.other.char_str == "yun" then
      walk_delay:reset(4)
   elseif player.other.char_str == "twelve" or player.other.char_str == "remy" or player.other.char_str == "urien" or
       player.other.char_str == "gill" then
      walk_delay:reset(3)
   elseif player.other.char_str == "q" then
      walk_delay:reset(2)
      d_hp_delay:reset(8)
   elseif player.other.char_str == "ibuki" then
      walk_delay:reset(10)
      d_hp_delay:reset(4)
   end

   local commands = {
      {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_back) end
      }, {
         condition = function() return walk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, f_mk) end
      }, {
         condition = function() return d_hp_delay:delay_after_idle_timing(player, #d_hp, true) end,
         action = function() queue_input_sequence_and_wait(player, d_hp) end
      }
   }
   return commands
end

local function urien_corner_tackle_mk_mk_mk_hk_followup_knee(player)
   local crouch = {}
   for i = 1, 30 do crouch[#crouch + 1] = {"down"} end
   local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
   local d_HP = {{"down", "HP"}}

   local knee_delay = Delay:new(30)

   if player.other.char_str == "twelve" or player.other.char_str == "necro" then
      knee_delay:reset(12)
   elseif player.other.char_str == "hugo" then
      knee_delay:reset(22)
   elseif player.other.char_str == "makoto" then
      knee_delay:reset(42)
   elseif player.other.char_str == "chunli" then
      knee_delay:reset(40)
   elseif player.other.char_str == "gill" then
      knee_delay:reset(26)
   elseif player.other.char_str == "alex" then
      knee_delay:reset(22)
   end

   local commands = {
      {
         condition = function() return is_idle_timing(player, 1) end,
         action = function() inputs.queue_input_sequence(player, crouch) end
      }, {
         condition = function() return knee_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, HK_knee) end
      }, {
         condition = function() return is_idle_timing(player, #d_HP, true) end,
         action = function() queue_input_sequence_and_wait(player, d_HP) end
      }
   }
   return commands
end

local function urien_corner_tackle_mk_mk_mk_hk_q_remy_followup_knee(player)
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}
   }

   local crouch = {}
   for i = 1, 30 do crouch[#crouch + 1] = {"down"} end
   local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
   local d_HP = {{"down", "HP"}}

   local knee_delay = Delay:new(8)
   if player.other.char_str == "remy" then
      for i = 1, 5 do walk_forward[#walk_forward + 1] = {"forward"} end
      knee_delay:reset(10)
   elseif player.other.char_str == "elena" then
      walk_forward[#walk_forward + 1] = {"forward"}
   elseif player.other.char_str == "q" then
      knee_delay:reset(10)
   end
   local commands = {
      {
         condition = function() return is_idle_timing(player, 1) end,
         action = function() queue_input_sequence_and_wait(player, walk_forward, 0, true) end
      }, {
         condition = function()
            if not player.pending_input_sequence then
               return true
            elseif #player.pending_input_sequence <= 1 then
               return true
            end
            return false
         end,
         action = function() inputs.queue_input_sequence(player, crouch, 0, true) end
      }, {
         condition = function() return knee_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, HK_knee) end
      }, {
         condition = function() return is_idle_timing(player, #d_HP, true) end,
         action = function() queue_input_sequence_and_wait(player, d_HP) end
      }
   }
   return commands
end

local function urien_corner_tackle_mk_mk_mk_mk_followup_knee(player)
   local crouch = {}
   for i = 1, 30 do crouch[#crouch + 1] = {"down"} end
   local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
   local d_HP = {{"down", "HP"}}

   local knee_delay = Delay:new(10)

   local commands = {
      {
         condition = function() return is_idle_timing(player, 1) end,
         action = function() inputs.queue_input_sequence(player, crouch) end
      }, {
         condition = function() return knee_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, HK_knee) end
      }, {
         condition = function() return is_idle_timing(player, #d_HP, true) end,
         action = function() queue_input_sequence_and_wait(player, d_HP) end
      }
   }

   if player.other.char_str == "oro" or player.other.char_str == "yang" or player.other.char_str == "yun" then
      knee_delay:reset(16)
      local walk_forward = {{"forward"}, {"forward"}}
      if player.other.char_str == "oro" then
         walk_forward = {{"forward"}}
         knee_delay:reset(21)
      elseif player.other.char_str == "yang" then
         knee_delay:reset(0)
         for i = 1, 12 do walk_forward[#walk_forward + 1] = {"forward"} end
      elseif player.other.char_str == "yun" then
         knee_delay:reset(1)
         for i = 1, 14 do walk_forward[#walk_forward + 1] = {"forward"} end
      end
      local walk_command = {
         {
            condition = function() return is_idle_timing(player, 1) end,
            action = function() queue_input_sequence_and_wait(player, walk_forward, 0, true) end
         }, {
            condition = function()
               if not player.pending_input_sequence then
                  return true
               elseif #player.pending_input_sequence <= 1 then
                  return true
               end
               return false
            end,
            action = function() inputs.queue_input_sequence(player, crouch, 0, true) end
         }
      }
      table.insert(commands, 1, walk_command[2])
      table.insert(commands, 1, walk_command[1])
   end

   return commands
end

local function oro_midscreen_setup_lp_yagyou_dash_dash(player)
   local mp = {{"MP"}}

   local mk_hitobashira = move_data.get_move_inputs_by_name("oro", "hitobashira", "MK")
   local mp_yagyou = move_data.get_move_inputs_by_name("oro", "yagyoudama", "LP")
   local forward_dash = {{"forward"}, {}, {"forward"}}

   local mp_delay = Delay:new(3)
   local dash_delay = Delay:new(6)

   if player.other.char_str == "alex" then
      dash_delay:reset(2)
   elseif player.other.char_str == "chunli" then
      dash_delay:reset(1)
   elseif player.other.char_str == "makoto" then
      dash_delay:reset(3)
      mp_delay:reset(2)
   elseif player.other.char_str == "necro" then
      dash_delay:reset(2)
   elseif player.other.char_str == "urien" then
      dash_delay:reset(1)
   end

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, mp) end}, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, mk_hitobashira) end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function()
            queue_input_sequence_and_wait(player, mk_hitobashira)
            mp_delay:reset()
         end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, mp_yagyou) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return dash_delay:delay_after_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
   }

   if player.other.char_str == "chunli" or player.other.char_str == "makoto" then
      local dash = {
         condition = function() return dash_delay:delay_after_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
      commands[#commands + 1] = dash
   elseif player.other.char_str == "urien" then
      local walk_delay = Delay:new(10)
      local walk_forward = {}
      for i = 1, 30 do walk_forward[#walk_forward + 1] = {"forward"} end
      local walk = {
         {
            condition = function() return is_idle_timing(player, 1, true) end,
            action = function() inputs.queue_input_sequence(player, walk_forward) end
         }, {
            condition = function() return walk_delay:is_complete() end,
            action = function() inputs.clear_input_sequence(player) end
         }
      }

      commands[#commands + 1] = walk[1]
      commands[#commands + 1] = walk[2]
   end

   return commands
end

local function oro_midscreen_setup_hp_yagyou_dash_dash(player)
   local mp = {{"MP"}}

   local mk_hitobashira = move_data.get_move_inputs_by_name("oro", "hitobashira", "MK")
   local hp_yagyou = move_data.get_move_inputs_by_name("oro", "yagyoudama", "HP")
   local forward_dash = {{"forward"}, {}, {"forward"}}

   local mp_delay = Delay:new(3)
   local dash_delay = Delay:new(12)
   local yagyou_delay = Delay:new(0)

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, mp) end}, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, mk_hitobashira) end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function()
            queue_input_sequence_and_wait(player, mk_hitobashira)
            mp_delay:reset()
         end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return yagyou_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, hp_yagyou) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
   }
   return commands
end

local function oro_midscreen_setup_mp_yagyou_dash_walk(player)
   local mp = {{"MP"}}

   local mk_hitobashira = move_data.get_move_inputs_by_name("oro", "hitobashira", "MK")
   local mp_yagyou = move_data.get_move_inputs_by_name("oro", "yagyoudama", "MP")
   local forward_dash = {{"forward"}, {}, {"forward"}}
   local walk_forward = {}
   for i = 1, 30 do walk_forward[#walk_forward + 1] = {"forward"} end

   local mp_delay = Delay:new(3)
   local yagyou_delay = Delay:new(0)
   local walk_delay = Delay:new(6)

   if player.other.char_str == "remy" then walk_delay:reset(15) end
   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, mp) end}, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, mk_hitobashira) end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function()
            queue_input_sequence_and_wait(player, mk_hitobashira)
            mp_delay:reset()
         end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return yagyou_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, mp_yagyou) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return walk_delay:is_complete() end,
         action = function() inputs.clear_input_sequence(player) end
      }
   }
   return commands
end

local function oro_midscreen_setup_mp_yagyou_dash_dash(player)
   local mp = {{"MP"}}

   local mk_hitobashira = move_data.get_move_inputs_by_name("oro", "hitobashira", "MK")
   local mp_yagyou = move_data.get_move_inputs_by_name("oro", "yagyoudama", "MP")
   local forward_dash = {{"forward"}, {}, {"forward"}}

   local mp_delay = Delay:new(3)
   local dash_delay = Delay:new(8) -- 12
   local yagyou_delay = Delay:new(0)

   if player.other.char_str == "ibuki" then
      dash_delay:reset(2)
   elseif player.other.char_str == "elena" then
      mp_delay:reset(2)
      dash_delay:reset(2)
   elseif player.other.char_str == "remy" then
      dash_delay:reset(2)
   end

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, mp) end}, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, mk_hitobashira) end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function()
            queue_input_sequence_and_wait(player, mk_hitobashira)
            mp_delay:reset()
         end
      }, {
         condition = function() return mp_delay:delay_after_idle(player) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return yagyou_delay:delay_after_hit(player) end,
         action = function() queue_input_sequence_and_wait(player, mp_yagyou) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return dash_delay:delay_after_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
   }

   return commands
end

local function oro_midscreen_setup_mp_mp_lp_yagyou(player)
   local mp = {{"MP"}}
   local walk_forward = {
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"},
      {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}
   }

   local lp_yagyou = move_data.get_move_inputs_by_name("oro", "yagyoudama", "LP")
   local forward_dash = {{"forward"}, {}, {"forward"}}

   local mp_delay = Delay:new(12)
   local dash_delay = Delay:new(0)
   local yagyou_delay = Delay:new(0)

   if player.other.char_str == "hugo" then dash_delay:reset(4) end

   local commands = {
      {condition = nil, action = function() queue_input_sequence_and_wait(player, mp) end}, {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward) end
      }, {
         condition = function() return mp_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }, {
         condition = function() return player.has_just_hit end,
         action = function() queue_input_sequence_and_wait(player, lp_yagyou) end
      }, {
         condition = function() return is_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }, {
         condition = function() return dash_delay:delay_after_idle_timing(player, #forward_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_dash) end
      }
   }

   if player.other.char_str == "hugo" then
      local walk_delay = Delay:new(4)
      local walk_forward = {}
      for i = 1, 30 do walk_forward[#walk_forward + 1] = {"forward"} end
      local walk = {
         {
            condition = function() return is_idle_timing(player, 1, true) end,
            action = function() inputs.queue_input_sequence(player, walk_forward) end
         }, {
            condition = function() return walk_delay:is_complete() end,
            action = function() inputs.clear_input_sequence(player) end
         }
      }

      commands[#commands + 1] = walk[1]
      commands[#commands + 1] = walk[2]
   end

   return commands
end

local function oro_midscreen_followup_neutral_jump_jump_mk(player)
   local neutral_jump = {{"up"}, {"up"}}
   local forward_jump = {{"up", "forward"}, {"up", "forward"}}
   local jump_mk = {{"MK"}}
   local mp = {{"MP"}}

   local jump_delay = Delay:new(0)
   local jump2_delay = Delay:new(12)
   local jump_mk_delay = Delay:new(30)
   if player.other.char_str == "chunli" then
      jump_delay:reset(4)
   elseif player.other.char_str == "makoto" then
      jump_delay:reset(3)
   elseif player.other.char_str == "hugo" then
      jump2_delay:reset(8)
   elseif player.other.char_str == "twelve" then
      jump2_delay:reset(7)
   elseif player.other.char_str == "urien" then
      jump2_delay:reset(10)
      jump_mk_delay:reset(27)
   end

   local commands = {
      {
         condition = function() return jump_delay:delay_after_idle_timing(player, #neutral_jump, true) end,
         action = function() queue_input_sequence_and_wait(player, neutral_jump) end
      }, {
         condition = function() return jump2_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, forward_jump) end
      }, {
         condition = function() return jump_mk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, jump_mk) end
      }, {
         condition = function() return is_idle_timing(player, #mp, true) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }
   }
   return commands
end

local function oro_midscreen_followup_back_dash_jump_mk(player)
   local back_dash = {{"back"}, {}, {"back"}}
   local forward_jump = {{"up", "forward"}, {"up", "forward"}}
   local jump_mk = {{"MK"}}
   local mp = {{"MP"}}

   local jump_delay = Delay:new(8) -- 8
   local jump_mk_delay = Delay:new(30) -- 30

   if player.other.char_str == "ibuki" then
      jump_delay:reset(2)
   elseif player.other.char_str == "chunli" then
      jump_delay:reset(8)
      jump_mk_delay:reset(31)
   elseif player.other.char_str == "makoto" then
      jump_delay:reset(10)
      jump_mk_delay:reset(30)
   elseif player.other.char_str == "elena" then
      jump_delay:reset(2)
      jump_mk_delay:reset(31)
   elseif player.other.char_str == "alex" then
      jump_delay:reset(2)
   elseif player.other.char_str == "dudley" then
      jump_mk_delay:reset(28)
      jump_delay:reset(0)
   elseif player.other.char_str == "q" then
      jump_mk_delay:reset(24)
      jump_delay:reset(0)
   elseif player.other.char_str == "hugo" then
      jump_mk_delay:reset(22)
      jump_delay:reset(0)
   elseif player.other.char_str == "necro" then
      jump_mk_delay:reset(24)
      jump_delay:reset(0)
   elseif player.other.char_str == "twelve" then
      jump_mk_delay:reset(25)
      jump_delay:reset(0)
   elseif player.other.char_str == "urien" then
      jump_mk_delay:reset(23)
      jump_delay:reset(0)
   elseif player.other.char_str == "oro" then
      jump_delay:reset(2)
   elseif player.other.char_str == "remy" then
      jump_mk_delay:reset(29)
      jump_delay:reset(2)
   elseif player.other.char_str == "yang" then
      jump_mk_delay:reset(28)
      jump_delay:reset(0)
   elseif player.other.char_str == "yun" then
      jump_mk_delay:reset(31)
      jump_delay:reset(1)
   end

   local commands = {
      {
         condition = function() return is_idle_timing(player, #back_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, back_dash) end
      }, {
         condition = function() return jump_delay:delay_after_idle_timing(player, 1, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_jump) end
      }, {
         condition = function() return jump_mk_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, jump_mk) end
      }, {
         condition = function() return is_idle_timing(player, #mp, true) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }
   }

   if player.other.char_str == "ibuki" or player.other.char_str == "elena" or player.other.char_str == "alex" or
       player.other.char_str == "oro" or player.other.char_str == "remy" or player.other.char_str == "ken" or
       player.other.char_str == "gouki" or player.other.char_str == "ryu" or player.other.char_str == "sean" or
       player.other.char_str == "shingouki" then
      local walk_forward = {{"forward"}, {"forward"}, {"forward"}, {"forward"}}
      if player.other.char_str == "ibuki" then
         walk_forward = {{"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}, {"forward"}}
      elseif player.other.char_str == "ken" then
         walk_forward = {{"forward"}, {"forward"}}
      elseif player.other.char_str == "gouki" or player.other.char_str == "ryu" or player.other.char_str == "sean" or
          player.other.char_str == "shingouki" then
         walk_forward = {{"forward"}, {"forward"}, {"forward"}}
      end
      local walk = {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() queue_input_sequence_and_wait(player, walk_forward, 0, true) end
      }
      table.insert(commands, 2, walk)
   end

   if player.other.char_str == "dudley" or player.other.char_str == "hugo" or player.other.char_str == "necro" or
       player.other.char_str == "twelve" or player.other.char_str == "urien" or player.other.char_str == "yang" or
       player.other.char_str == "q" then
      local walk_back = {}
      local n = 16
      if player.other.char_str == "twelve" then
         n = 14
      elseif player.other.char_str == "urien" then
         n = 18
      elseif player.other.char_str == "yang" then
         n = 20
      end
      for i = 1, n do walk_back[#walk_back + 1] = {"back"} end

      local walk = {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() queue_input_sequence_and_wait(player, walk_back, 0, true) end
      }
      commands[1] = walk
   end

   return commands
end

local function oro_midscreen_followup_back_dash_down_lk(player)
   local back_dash = {{"back"}, {}, {"back"}}
   local forward_jump = {{"up", "forward"}, {"up", "forward"}}
   local d_lk = {{"down", "LK"}}
   local mp = {{"MP"}}

   local jump_delay = Delay:new(0)
   local jump_startup_delay = Delay:new(6)

   local commands = {
      {
         condition = function() return is_idle_timing(player, #back_dash, true) end,
         action = function() queue_input_sequence_and_wait(player, back_dash) end
      }, {
         condition = function() return jump_delay:delay_after_idle_timing(player, #forward_jump, true) end,
         action = function() queue_input_sequence_and_wait(player, forward_jump) end
      }, {
         condition = function()
            return is_landing_timing(player, #d_lk, true) and jump_startup_delay:is_complete()
         end,
         action = function() queue_input_sequence_and_wait(player, d_lk) end
      }, {
         condition = function() return is_idle_timing(player, #mp, true) end,
         action = function() queue_input_sequence_and_wait(player, mp) end
      }
   }

   if player.other.char_str == "dudley" or player.other.char_str == "hugo" or player.other.char_str == "necro" or
       player.other.char_str == "twelve" or player.other.char_str == "urien" or player.other.char_str == "yang" or
       player.other.char_str == "q" then
      local walk_back = {{"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}}
      if player.other.char_str == "urien" then
         walk_back = {{"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}, {"back"}}
      elseif player.other.char_str == "q" then
         walk_back = {{"back"}, {"back"}, {"back"}, {"back"}}
      elseif player.other.char_str == "hugo" then
         walk_back = {{"back"}}
         table.insert(commands, 4, {
            condition = function() return is_idle_timing(player, 1, true) end,
            action = function()
               queue_input_sequence_and_wait(player, {{"forward"}, {"forward"}, {"forward"}, {"forward"}}, 0, true)
            end
         })
      elseif player.other.char_str == "twelve" then
         walk_back = {{"back"}}
      end
      local walk = {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() queue_input_sequence_and_wait(player, walk_back, 0, true) end
      }
      commands[1] = walk
   end

   return commands
end

local urien_midscreen_standard = {
   name = "urien_midscreen_standard",
   commands = urien_midscreen_setup_tackle_dash,
   reset_offset_x = 700
}
local urien_midscreen_ex_head_sphere = {
   name = "urien_midscreen_ex_head_sphere",
   commands = urien_midscreen_setup_ex_head_sphere,
   reset_offset_x = 600
}
local urien_midscreen_ex_head_standard = {
   name = "urien_midscreen_ex_head_standard",
   commands = urien_midscreen_setup_ex_head_standard,
   reset_offset_x = 600
}
local urien_midscreen_anago = {
   name = "urien_midscreen_anago",
   commands = urien_midscreen_setup_anago,
   reset_offset_x = 600
}

local urien_corner_standard = {
   name = "urien_corner_standard",
   commands = urien_corner_setup_tackle_mk_mk_mk_hk,
   reset_offset_x = 220
}
local urien_corner_standard_short = {
   name = "urien_corner_standard_short",
   commands = urien_corner_setup_tackle_mk_mk_mk_mk,
   reset_offset_x = 220
}
local urien_corner_standard_alex = {
   name = "urien_corner_standard_alex",
   commands = urien_corner_setup_alex,
   reset_offset_x = 120
}
local urien_corner_standard_q_remy = {
   name = "urien_corner_standard_q_remy",
   commands = urien_corner_setup_tackle_mk_mk_mk_hk_q_remy,
   reset_offset_x = 220
}

local oro_midscreen_lp_yagyou = {
   name = "oro_midscreen_lp_yagyou",
   commands = oro_midscreen_setup_lp_yagyou_dash_dash,
   reset_offset_x = 800
}
local oro_midscreen_mp_yagyou = {
   name = "oro_midscreen_mp_yagyou",
   commands = oro_midscreen_setup_mp_yagyou_dash_dash,
   reset_offset_x = 800
}
local oro_midscreen_mp_mp = {
   name = "oro_midscreen_mp_mp",
   commands = oro_midscreen_setup_mp_mp_lp_yagyou,
   reset_offset_x = 800
}
local oro_midscreen_mp_yagyou_walk = {
   name = "oro_midscreen_mp_yagyou_walk",
   commands = oro_midscreen_setup_mp_yagyou_dash_walk,
   reset_offset_x = 800
}

local setups = {
   urien = {
      alex = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard_alex},
      sean = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      ibuki = {urien_midscreen_ex_head_sphere, urien_midscreen_anago},
      necro = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      urien = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      gouki = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      yang = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard_short},
      twelve = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      makoto = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      chunli = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      q = {urien_midscreen_ex_head_standard, urien_midscreen_anago, urien_corner_standard_q_remy},
      remy = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard_q_remy},
      yun = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard_short},
      ken = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      hugo = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      elena = {urien_midscreen_standard, urien_corner_standard_q_remy},
      dudley = {urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard_short},
      oro = {urien_midscreen_ex_head_sphere, urien_corner_standard_short},
      ryu = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      gill = {urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard},
      shingouki = {
         urien_midscreen_standard, urien_midscreen_ex_head_sphere, urien_midscreen_anago, urien_corner_standard
      }
   },
   oro = {
      alex = {oro_midscreen_lp_yagyou},
      sean = {oro_midscreen_mp_yagyou},
      ibuki = {oro_midscreen_mp_yagyou},
      necro = {oro_midscreen_lp_yagyou},
      urien = {oro_midscreen_lp_yagyou},
      gouki = {oro_midscreen_mp_yagyou},
      yang = {oro_midscreen_mp_mp},
      twelve = {oro_midscreen_lp_yagyou},
      makoto = {oro_midscreen_lp_yagyou},
      chunli = {oro_midscreen_lp_yagyou},
      q = {oro_midscreen_lp_yagyou},
      remy = {oro_midscreen_mp_yagyou},
      yun = {oro_midscreen_mp_mp},
      ken = {oro_midscreen_mp_yagyou},
      hugo = {oro_midscreen_mp_mp},
      elena = {oro_midscreen_mp_yagyou},
      dudley = {oro_midscreen_mp_yagyou_walk},
      oro = {oro_midscreen_lp_yagyou},
      ryu = {oro_midscreen_mp_yagyou},
      gill = {oro_midscreen_lp_yagyou},
      shingouki = {oro_midscreen_mp_yagyou}
   }
}

local followup_data = {
   urien = {
      urien_midscreen_standard = {
         default = {
            {name = "f_MK", commands = urien_midscreen_tackle_dash_followup_f_mk},
            {name = "d_LK", commands = urien_midscreen_tackle_dash_followup_d_lk},
            {name = "throw", commands = urien_midscreen_tackle_dash_followup_throw}
         }
      },
      urien_midscreen_ex_head_sphere = {
         default = {
            {name = "jump_HK", commands = urien_mid_screen_ex_head_sphere_followup_jump_hk},
            {name = "f_MK", commands = urien_mid_screen_ex_head_sphere_followup_f_mk},
            {name = "d_LK", commands = urien_mid_screen_ex_head_sphere_followup_d_lk},
            {name = "throw", commands = urien_mid_screen_ex_head_sphere_followup_throw}
         }
      },
      urien_midscreen_ex_head_standard = {
         default = {
            {name = "uoh", commands = urien_mid_screen_ex_head_standard_followup_leap},
            {name = "f_MK", commands = urien_mid_screen_ex_head_standard_followup_f_mk},
            {name = "d_LK", commands = urien_mid_screen_ex_head_standard_followup_d_lk},
            {name = "throw", commands = urien_mid_screen_ex_head_standard_followup_throw}
         }
      },
      urien_midscreen_anago = {
         default = {
            {name = "d_LK", commands = urien_mid_screen_anago_followup_d_lk},
            {name = "d_LK_dash", commands = urien_mid_screen_anago_followup_d_lk_dash},
            {name = "f_MK", commands = urien_mid_screen_anago_followup_f_mk}
         }
      },
      urien_corner_standard = {
         default = {{name = "HK_kneedrop", commands = urien_corner_tackle_mk_mk_mk_hk_followup_knee}}
      },
      urien_corner_standard_short = {
         default = {{name = "HK_kneedrop", commands = urien_corner_tackle_mk_mk_mk_mk_followup_knee}}
      },
      urien_corner_standard_alex = {
         default = {{name = "HK_kneedrop", commands = urien_corner_tackle_mk_mk_mk_hk_followup_knee}}
      },
      urien_corner_standard_q_remy = {
         default = {{name = "HK_kneedrop", commands = urien_corner_tackle_mk_mk_mk_hk_q_remy_followup_knee}}
      }
   },
   oro = {
      oro_midscreen_hp_yagyou = {
         default = {
            {name = "jump_MK", commands = oro_midscreen_followup_neutral_jump_jump_mk},
            {name = "back_dash_jump_MK", commands = oro_midscreen_followup_back_dash_jump_mk},
            {name = "back_dash_down_LK", commands = oro_midscreen_followup_back_dash_down_lk}
         }
      },
      oro_midscreen_mp_yagyou = {
         default = {
            {name = "jump_MK", commands = oro_midscreen_followup_neutral_jump_jump_mk},
            {name = "back_dash_jump_MK", commands = oro_midscreen_followup_back_dash_jump_mk},
            {name = "back_dash_down_LK", commands = oro_midscreen_followup_back_dash_down_lk}
         }
      },
      oro_midscreen_lp_yagyou = {
         default = {
            {name = "jump_MK", commands = oro_midscreen_followup_neutral_jump_jump_mk},
            {name = "back_dash_jump_MK", commands = oro_midscreen_followup_back_dash_jump_mk},
            {name = "back_dash_down_LK", commands = oro_midscreen_followup_back_dash_down_lk}
         }
      },
      oro_midscreen_mp_mp = {
         default = {
            {name = "jump_MK", commands = oro_midscreen_followup_neutral_jump_jump_mk},
            {name = "back_dash_jump_MK", commands = oro_midscreen_followup_back_dash_jump_mk},
            {name = "back_dash_down_LK", commands = oro_midscreen_followup_back_dash_down_lk}
         }
      },
      oro_midscreen_mp_yagyou_walk = {
         default = {
            {name = "jump_MK", commands = oro_midscreen_followup_neutral_jump_jump_mk},
            {name = "back_dash_jump_MK", commands = oro_midscreen_followup_back_dash_jump_mk},
            {name = "back_dash_down_LK", commands = oro_midscreen_followup_back_dash_down_lk}
         }
      }
   }
}

local followups = {
   urien = {
      alex = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard_alex = followup_data.urien.urien_corner_standard_alex.default
      },
      chunli = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      dudley = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard_short = followup_data.urien.urien_corner_standard_short.default
      },
      elena = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_corner_standard_q_remy = followup_data.urien.urien_corner_standard_q_remy.default
      },
      gouki = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      gill = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      hugo = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      ibuki = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default
      },
      ken = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      makoto = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      necro = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      oro = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_corner_standard_short = followup_data.urien.urien_corner_standard_short.default
      },
      q = {
         urien_midscreen_ex_head_standard = followup_data.urien.urien_midscreen_ex_head_standard.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard_q_remy = followup_data.urien.urien_corner_standard_q_remy.default
      },
      remy = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard_q_remy = followup_data.urien.urien_corner_standard_q_remy.default
      },
      ryu = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      sean = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      shingouki = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      twelve = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      urien = {
         urien_midscreen_standard = followup_data.urien.urien_midscreen_standard.default,
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard = followup_data.urien.urien_corner_standard.default
      },
      yang = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard_short = followup_data.urien.urien_corner_standard_short.default
      },
      yun = {
         urien_midscreen_ex_head_sphere = followup_data.urien.urien_midscreen_ex_head_sphere.default,
         urien_midscreen_anago = followup_data.urien.urien_midscreen_anago.default,
         urien_corner_standard_short = followup_data.urien.urien_corner_standard_short.default
      }
   },
   oro = {
      alex = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      chunli = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      dudley = {oro_midscreen_mp_yagyou_walk = followup_data.oro.oro_midscreen_mp_yagyou_walk.default},
      elena = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      gouki = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      gill = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      hugo = {oro_midscreen_mp_mp = followup_data.oro.oro_midscreen_mp_mp.default},
      ibuki = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      ken = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      makoto = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      necro = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      oro = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      q = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      remy = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      ryu = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      sean = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      shingouki = {oro_midscreen_mp_yagyou = followup_data.oro.oro_midscreen_mp_yagyou.default},
      twelve = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      urien = {oro_midscreen_lp_yagyou = followup_data.oro.oro_midscreen_lp_yagyou.default},
      yang = {oro_midscreen_mp_mp = followup_data.oro.oro_midscreen_mp_mp.default},
      yun = {oro_midscreen_mp_mp = followup_data.oro.oro_midscreen_mp_mp.default}
   }
}

local unblockables_data = {}
local available_opponents = {"urien", "oro"}
local opponents_menu_names = {}

for i, opponent in ipairs(available_opponents) do opponents_menu_names[#opponents_menu_names + 1] = "menu_" .. opponent end

local followup_names = {}
for key, data in pairs(unblockables_data) do
   followup_names[key] = {}
   for i = 1, #data.followups do followup_names[key][#followup_names[key] + 1] = data.followups[i].name end
end

local function get_setup(opponent, char_str, index) return setups[opponent][char_str][index] end
local function get_followups(opponent, char_str, setup_name) return followups[opponent][char_str][setup_name] end

local function get_setups_menu_names(opponent, char_str)
   local result = {}
   for i, setup in ipairs(setups[opponent][char_str]) do result[#result + 1] = "menu_" .. setup.name end
   return result
end

local function get_followups_menu_names(opponent, char_str, setup_name)
   local result = {}
   for i, followup in ipairs(followups[opponent][char_str][setup_name]) do
      result[#result + 1] = "menu_" .. followup.name
   end
   return result
end

local function create_settings()
   local data = {
      opponent = 1,
      setup = 1,
      controllers = {"player", "unblockables"},
      savestate_setup = 1,
      savestate_opponent = "",
      savestate_player = "",
      match_savestate_opponent = "",
      match_savestate_player = "",
      followups = {}
   }
   for _, opponent in ipairs(available_opponents) do
      data.followups[opponent] = {}
      for __, char_str in ipairs(require("src.data.game_data").characters) do
         data.followups[opponent][char_str] = {}
         local s = data.followups[opponent][char_str]
         for ___, current_setup in ipairs(setups[opponent][char_str]) do
            s[#s + 1] = {}
            local f = s[#s]
            local setup_name = current_setup.name
            for ____, current_followup in ipairs(followups[opponent][char_str][setup_name]) do
               f[#f + 1] = false
            end
         end
      end
   end
   return data
end

return {
   get_setup = get_setup,
   get_followups = get_followups,
   get_setups_menu_names = get_setups_menu_names,
   get_followups_menu_names = get_followups_menu_names,
   available_opponents = available_opponents,
   opponents_menu_names = opponents_menu_names,
   followup_names = followup_names,
   create_settings = create_settings
}
