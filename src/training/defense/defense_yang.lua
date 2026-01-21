local training_classes = require("src.training.classes")
local write_memory = require("src.control.write_memory")
local framedata, fdm, move_data, stage_data, inputs, advanced_control, prediction, tools, utils, gamestate,
      dummy_control

local Setup, Followup, Action_Type, Setup_Type = training_classes.Setup, training_classes.Followup,
                                                 training_classes.Action_Type, training_classes.Setup_Type
local Delay
local is_idle_timing, is_wakeup_timing, is_landing_timing
local is_throw_vulnerable_timing
local queue_input_sequence_and_wait, all_commands_complete
local character_specific

local jump_forward_input
local jump_mk_input
local block_high_input
local block_low_input

local walk_forward_input
local walk_back_input

local sjump_forward_input

local lk_input

local d_lk_input
local d_lk_hit_frame

local d_mk_input
local d_mk_hit_frame

local cl_mp_input
local cl_mp_hit_frame

local cl_mk_input
local cl_mk_hit_frame
local hk_input

local lk_raigeki_input

local lp_tourou_input
local ex_tourou_input
local ex_tourou_hit_frame

local zenpou_input
local zenpou_hit_frame
local zenpou_range

local byakko_input

local lk_kaihou_input
local lk_kaihou_duration

local tenshin_input
local tenshin_hit_frame

local kara_throw_input
local hk_kara_dist
local kara_throw_delay = 2

local throw_input
local throw_hit_frame
local throw_range
local throw_threshold = 2
local hk_kara_throw_range

local uoh_input
local uoh_hit_frame

local parry_frames = 10
local punish_delta = 2
local throw_break_tolerance = -2
local recovery_gap = 2
local guard_jump_recovery_gap = 6
local throw_walk_frames = 12
local block_punish_threshold = 4
local reaction_time = 12
local connection_end_delay
local knockdown

local setup_jumpin_wakeup_delay = 20
local corner_gap = 6
local raigeki_crossthrough_corner_gap = 30
local raigeki_crossup_corner_gap = 48

local cl_mk_offset = {
   default = 36,
   alex = 38,
   chunli = 28,
   dudley = 39,
   elena = 40,
   gill = 37,
   gouki = 30,
   hugo = 38,
   ibuki = 25,
   ken = 27,
   makoto = 17,
   necro = 34,
   oro = 37,
   q = 36,
   remy = 38,
   ryu = 27,
   sean = 27,
   shingouki = 30,
   twelve = 19,
   urien = 37,
   yang = 22,
   yun = 21
}
local uoh_offset = {
   default = 50,
   alex = 72,
   chunli = 57,
   dudley = 69,
   elena = 68,
   gill = 65,
   gouki = 60,
   hugo = 63,
   ibuki = 53,
   ken = 58,
   makoto = 56,
   necro = 63,
   oro = 65,
   q = 55,
   remy = 66,
   ryu = 58,
   sean = 55,
   shingouki = 60,
   twelve = 47,
   urien = 65,
   yang = 50,
   yun = 47
}

local jump_hk_delay = {
   default = 18,
   dudley = 20,
   elena = 20,
   remy = 20,
   alex = 22,
   necro = 22,
   urien = 22,
   gill = 22,
   q = 23,
   twelve = 23,
   hugo = 24
}

local jumpin_data = {
   default = {
      high = {offset = 170, delay = 28, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   alex = {
      high = {offset = 170, delay = 24, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 178, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   chunli = {
      high = {offset = 170, delay = 28, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 24, jump_timing = 34, delay = 20, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   dudley = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 20, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   elena = {
      high = {offset = 176, delay = 20, button = "HK"},
      mid = {offset = 176, delay = 17, button = "HK"},
      low = {offset = 176, delay = 14, button = "HK"},
      whiff = {offset = 190, delay = 14, button = "MK"},
      crossthrough = {offset = 134, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 176, delay = 37, button = "MP"}
   },
   gill = {
      high = {offset = 170, delay = 24, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 116, delay = 29, button = "MK"},
      crossup = {offset = 4, jump_timing = 34, delay = 20, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   gouki = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   hugo = {
      high = {offset = 176, delay = 29, button = "HK"},
      mid = {offset = 182, delay = 19, button = "HK"},
      low = {offset = 182, delay = 14, button = "HK"},
      whiff = {offset = 182, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 4, jump_timing = 30, delay = 20, button = "LK"},
      mp = {offset = 182, delay = 37, button = "MP"}
   },
   ibuki = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 3, jump_timing = 28, delay = 14, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   ken = {
      high = {offset = 170, delay = 28, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   makoto = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 176, delay = 14, button = "MK"},
      crossthrough = {offset = 104, delay = 29, button = "MK"},
      crossup = {offset = 1, jump_timing = 30, delay = 15, button = "LK"},
      -- crossup = {offset = 1, jump_timing = 28, delay = 16, button = "LK"}
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   necro = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 4, jump_timing = 30, delay = 17, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   oro = {
      high = {offset = 168, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 1, jump_timing = 30, delay = 16, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   q = {
      high = {offset = 158, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 19, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      -- crossup = {offset = 8, jump_timing = 32, delay = 17, button = "LK"}
      crossup = {offset = 1, jump_timing = 25, delay = 15, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   remy = {
      high = {offset = 160, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   ryu = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   sean = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"}
   },
   shingouki = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 108, delay = 29, button = "MK"},
      crossup = {offset = 12, jump_timing = 34, delay = 21, button = "LK"}
   },
   twelve = {
      high = {offset = 170, delay = 29, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 4, jump_timing = 30, delay = 17, button = "LK"},
      mp = {offset = 170, delay = 28, button = "MP"}
   },
   urien = {
      high = {offset = 170, delay = 24, button = "HK"},
      mid = {offset = 170, delay = 18, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 116, delay = 29, button = "MK"},
      crossup = {offset = 14, jump_timing = 34, delay = 24, button = "LK"},
      mp = {offset = 170, delay = 28, button = "MP"}
   },
   yang = {
      high = {offset = 170, delay = 28, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 4, jump_timing = 28, delay = 15, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   },
   yun = {
      high = {offset = 170, delay = 28, button = "HK"},
      mid = {offset = 170, delay = 17, button = "HK"},
      low = {offset = 170, delay = 14, button = "HK"},
      whiff = {offset = 170, delay = 14, button = "MK"},
      crossthrough = {offset = 106, delay = 29, button = "MK"},
      crossup = {offset = 4, jump_timing = 28, delay = 15, button = "LK"},
      mp = {offset = 170, delay = 37, button = "MP"}
   }
}

local cl_mk_after_zenpou = {chunli = 0, makoto = 0, hugo = 5, ibuki = 4, q = 4, twelve = 4}

local blocking_options, parry_options

local function init()
   framedata = require("src.data.framedata")
   fdm = require("src.data.framedata_meta")
   move_data = require("src.data.move_data")
   stage_data = require("src.data.stage_data")
   inputs = require("src.control.inputs")
   advanced_control = require("src.control.advanced_control")
   prediction = require("src.data.prediction")
   tools = require("src.tools")
   utils = require("src.data.utils")
   gamestate = require("src.gamestate")
   dummy_control = require("src.control.dummy_control")

   Delay = advanced_control.Delay
   is_idle_timing, is_wakeup_timing, is_landing_timing = advanced_control.is_idle_timing,
                                                         advanced_control.is_wakeup_timing,
                                                         advanced_control.is_landing_timing
   is_throw_vulnerable_timing = advanced_control.is_throw_vulnerable_timing
   queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                          advanced_control.all_commands_complete
   character_specific = framedata.character_specific

   jump_forward_input = {{"up", "forward"}, {"up", "forward"}}
   jump_mk_input = {{"MK"}}
   block_high_input = {{"back"}}
   block_low_input = {{"back", "down"}}

   walk_forward_input = {{"forward"}}
   walk_back_input = {{"back"}}

   sjump_forward_input = {{"down"}, {"up", "forward"}, {"up", "forward"}}

   lk_input = {{"LK"}}

   d_lk_input = {{"down", "LK"}}
   d_lk_hit_frame = framedata.get_first_hit_frame_by_name("yang", "d_LK")

   cl_mp_input = {{"MP"}}
   cl_mp_hit_frame = framedata.get_first_hit_frame_by_name("yang", "cl_MP")

   cl_mk_input = {{"MK"}}
   cl_mk_hit_frame = framedata.get_first_hit_frame_by_name("yang", "cl_MK")

   hk_input = {{"HK"}}

   d_mk_input = {{"down", "MK"}}
   d_mk_hit_frame = framedata.get_first_hit_frame_by_name("yang", "d_MK")

   lp_tourou_input = move_data.get_move_inputs_by_name("yang", "tourouzan", "LP")
   ex_tourou_input = move_data.get_move_inputs_by_name("yang", "tourouzan", "EXP")
   ex_tourou_hit_frame = framedata.get_first_hit_frame_by_name("yang", "tourouzan", "EXP")

   zenpou_input = move_data.get_move_inputs_by_name("yang", "zenpou", "LK")
   table.insert(zenpou_input[#zenpou_input], "LP")
   zenpou_hit_frame = framedata.get_first_hit_frame_by_name("yang", "zenpou")
   zenpou_range = framedata.get_hitbox_max_range_by_name("yang", "zenpou")

   byakko_input = move_data.get_move_inputs_by_name("yang", "byakko", "LP")

   lk_kaihou_input = move_data.get_move_inputs_by_name("yang", "kaihou", "LK")
   lk_kaihou_duration = framedata.get_first_idle_frame_by_name("yang", "kaihou", "LK")

   tenshin_input = move_data.get_move_inputs_by_name("yang", "tenshinsenkyuutai")
   tenshin_hit_frame = framedata.get_first_hit_frame_by_name("yang", "tenshinsenkyuutai")

   throw_input = {{"LP", "LK"}}
   kara_throw_input = {{"HK"}, {"LP", "LK"}}
   hk_kara_dist = framedata.get_kara_distance_by_name("yang", "HK")

   throw_hit_frame = 2
   throw_range = framedata.get_hitbox_max_range_by_name("yang", "throw_neutral")
   hk_kara_throw_range = throw_range + hk_kara_dist

   uoh_input = {{"MP", "MK"}}
   uoh_hit_frame = framedata.get_first_hit_frame_by_name("yang", "uoh")

   connection_end_delay = Delay:new(1)
   knockdown = move_data.get_move_inputs_by_name("yang", "senkyuutai", "LK")

   blocking_options = {
      mode = dummy_control.Blocking_Mode.ON,
      style = dummy_control.Blocking_Style.BLOCK,
      red_parry_hit_count = 1,
      parry_every_n_count = 1,
      prefer_parry_low = false,
      prefer_block_low = false,
      force_blocking_direction = dummy_control.Force_Blocking_Direction.OFF
   }

   parry_options = {
      mode = dummy_control.Blocking_Mode.ON,
      style = dummy_control.Blocking_Style.PARRY,
      red_parry_hit_count = 1,
      parry_every_n_count = 1,
      prefer_parry_low = false,
      prefer_block_low = false,
      force_blocking_direction = dummy_control.Force_Blocking_Direction.OFF
   }
end

local function handle_interruptions(player, context)
   if (player.has_just_been_hit and not player.is_being_thrown) or player.other.has_just_parried then
      return true, {score = 2, should_end = true}
   end
   if (player.is_being_thrown and player.throw_tech_countdown <= 0) then
      local score = 1
      local hit_with_command_throw = memory.readbyte(player.other.addresses.hit_with_command_throw) > 0
      local hit_with_super_throw = memory.readbyte(player.other.addresses.hit_with_super_throw) > 0
      if hit_with_command_throw or hit_with_super_throw then score = 2 end
      return true, {score = score, should_end = true}
   end
   if player.has_just_missed then
      if not player.other.is_attacking then
         return true, {score = 1, should_end = true}
      else
         local current_action = context.actions[context.i_actions]
         if current_action and current_action.type ~= Action_Type.BLOCK then return true, {should_block = true} end
      end
   end
   return false
end

local raigeki_high_followups
local raigeki_mid_followups
local raigeki_low_followups
local raigeki_crossthrough_followups
local raigeki_crossup_followups
local raigeki_whiff_followups
local jump_mp_followups
local close_mk_jump_hk_followups
local close_mp_followups
local down_lk_followups
local lp_tourou_followups
local wakeup_followups
local whiff_followups

local block_followups
local walk_in_followups
local walk_out_followups
local lk_kaihou_followups

local ex_tourou
local lk_ex_tourou
local cl_mk_jump_hk
local d_mk_ex_tourou

local lp_tourou_input_delay = 0
local ex_tourou_input_delay = 1
local punish_ex_tourou = Followup:new("punish_ex_tourou", Action_Type.PUNISH)

function punish_ex_tourou:init()
   self.ex_torou_hits = 0
   self.should_input = false
   self.last_hit_frame = 0
end

function punish_ex_tourou:setup(player, context)
   self:init()
   return {
      {
         condition = function()
            if player.animation_frame_data and player.animation_frame_data.name == "d_LK" then return true end
            return is_idle_timing(player, #ex_tourou_input)
         end,
         action = function() queue_input_sequence_and_wait(player, ex_tourou_input) end
      }
   }
end

function punish_ex_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= ex_tourou_input_delay then
         queue_input_sequence_and_wait(player, ex_tourou_input)
         self.should_input = false
      end
      if player.has_just_hit then
         self.ex_torou_hits = self.ex_torou_hits + 1
         self.should_input = true
         self.last_hit_frame = gamestate.frame_number
      elseif player.has_just_been_blocked then
         return true, {score = 0}
      end
      if self.ex_torou_hits >= 5 then return true, {score = -3} end
   end
   return handle_interruptions(player, context)
end

function punish_ex_tourou:is_valid(player, context)
   if player.has_just_hit and player.animation_frame_data and player.animation_frame_data.name == "d_LK" then
      return true
   end
   if context.frame_advantage then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      if context.predicted_state then
         dist = math.abs(context.predicted_state.P1.pos_x - context.predicted_state.P2.pos_x)
      end
      return context.frame_advantage >= 10 and dist <= framedata.get_contact_distance(player) + 108
   end
   if player.has_just_parried then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      return dist <= framedata.get_contact_distance(player) + 108
   end
end

local punish_lk_ex_tourou = Followup:new("punish_lk_ex_tourou", Action_Type.PUNISH)

function punish_lk_ex_tourou:init()
   self.ex_torou_hits = 0
   self.should_input = false
   self.last_hit_frame = 0
   self.offset = 0
end

function punish_lk_ex_tourou:setup(player, context)
   self:init()
   if player.has_just_hit and player.animation_frame_data and player.animation_frame_data.name == "cl_MP" then
      self.offset = -3
   end
   return {
      {
         condition = function()
            inputs.queue_input_sequence(player, walk_forward_input)
            return is_idle_timing(player, #lk_input + self.offset, true)
         end,
         action = function() queue_input_sequence_and_wait(player, lk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, ex_tourou_input) end
      }
   }
end

function punish_lk_ex_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= ex_tourou_input_delay then
         queue_input_sequence_and_wait(player, ex_tourou_input)
         self.should_input = false
      end
      if player.has_just_hit then
         self.ex_torou_hits = self.ex_torou_hits + 1
         self.should_input = true
         self.last_hit_frame = gamestate.frame_number
      elseif player.has_just_been_blocked then
         return true, {score = 0}
      end
      if self.ex_torou_hits >= 5 then return true, {score = -3} end
   end
   return handle_interruptions(player, context)
end

function punish_lk_ex_tourou:is_valid(player, context)
   if context.frame_advantage then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      if context.predicted_state then
         dist = math.abs(context.predicted_state.P1.pos_x - context.predicted_state.P2.pos_x)
      end
      return context.frame_advantage >= 5 and dist <= framedata.get_contact_distance(player) + 64
   end
   if player.has_just_parried then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      return dist <= framedata.get_contact_distance(player) + 64
   end
end

local punish_d_mk_ex_tourou = Followup:new("punish_d_mk_ex_tourou", Action_Type.PUNISH)

function punish_d_mk_ex_tourou:init()
   self.ex_torou_hits = 0
   self.should_input = false
   self.last_hit_frame = 0
   self.offset = 0
   self.score = -3
end

function punish_d_mk_ex_tourou:setup(player, context)
   self:init()
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action and previous_action.name == "followup_zenpou" then self.score = -2 end
   return {
      {
         condition = function() return is_idle_timing(player, #d_mk_input + self.offset, true) end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, ex_tourou_input) end
      }
   }
end

function punish_d_mk_ex_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= ex_tourou_input_delay then
         queue_input_sequence_and_wait(player, ex_tourou_input)
         self.should_input = false
      end
      if player.has_just_hit then
         self.ex_torou_hits = self.ex_torou_hits + 1
         self.should_input = true
         self.last_hit_frame = gamestate.frame_number
      elseif player.has_just_been_blocked then
         return true, {score = 0}
      end
      if self.ex_torou_hits >= 5 then return true, {score = self.score} end
   end
   return handle_interruptions(player, context)
end

function punish_d_mk_ex_tourou:is_valid(player, context)
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action and previous_action.name == "followup_zenpou" then return true end
   if context.frame_advantage then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      if context.predicted_state then
         dist = math.abs(context.predicted_state.P1.pos_x - context.predicted_state.P2.pos_x)
      end
      return context.frame_advantage >= 9 and dist <= framedata.get_contact_distance(player) + 64
   end
   if player.has_just_parried then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      return dist <= framedata.get_contact_distance(player) + 64
   end
end

local punish_tenshin = Followup:new("punish_tenshin", Action_Type.PUNISH)

function punish_tenshin:init() self.offset = 0 end

function punish_tenshin:setup(player, context)
   self:init()
   return {
      {
         condition = function()
            inputs.queue_input_sequence(player, walk_forward_input)
            return is_idle_timing(player, #tenshin_input + self.offset, false)
         end,
         action = function() queue_input_sequence_and_wait(player, tenshin_input) end
      }
   }
end

function punish_tenshin:run(player, context)
   if all_commands_complete(player) then if player.remaining_freeze_frames <= 14 then return true, {score = -3} end end
   return handle_interruptions(player, context)
end

function punish_tenshin:is_valid(player, context)
   if context.frame_advantage and context.frame_advantage > 2 then
      local dist = math.abs(player.other.pos_x - player.pos_x)
      if context.predicted_state then
         dist = math.abs(context.predicted_state.P1.pos_x - context.predicted_state.P2.pos_x)
      end
      local contact_dist = framedata.get_contact_distance(player)
      return dist - (contact_dist + 10) - 10 * (context.frame_advantage - (tenshin_hit_frame + 1)) <= 0
   end
   if player.has_just_parried then return true end
end

local punishes = {
   {action = punish_lk_ex_tourou, weight = 1}, {action = punish_ex_tourou, weight = 1},
   {action = punish_d_mk_ex_tourou, weight = 1}, {action = punish_tenshin, weight = 0.3}
}

local function select_punish(player, context)
   local valid_punishes = {}
   for _, punish in pairs(punishes) do
      if punish.action:is_valid(player, context) then valid_punishes[#valid_punishes + 1] = punish end
   end

   return tools.select_weighted(valid_punishes)
end

local followup_punish = Followup:new("followup_punish", Action_Type.PUNISH)

function followup_punish:init()
   self.should_end = false
   self.end_delay = 10
   self.is_valid_punish = true
   self.has_hit = false
end

function followup_punish:setup(player, context)
   self:init()
   self.has_hit = player.combo >= 1
   context.frame_advantage = nil
   context.predicted_state = nil
   self.selected_punish = select_punish(player, context)
   if self.selected_punish then return self.selected_punish.action:setup(player, context) end

   self.is_valid_punish = false
   return {{condition = nil, action = nil}}
end

function followup_punish:run(player, context)
   if not self.selected_punish then
      local advantage = prediction.get_frame_advantage(player)
      if advantage then
         context.frame_advantage = advantage
         self.selected_punish = select_punish(player, context)
         if self.selected_punish then
            local time_until_idle = prediction.get_frames_until_idle(player, nil, nil, 80)
            context.predicted_state = prediction.predict_gamestate(nil, nil, time_until_idle)
            advanced_control.queue_programmed_movement(player, self.selected_punish.action:setup(player, context))
         else
            self.should_end = true
         end
      end
   else
      local finished, result = self.selected_punish.action:run(player, context)
      return finished, result
   end
   if self.should_end then
      if self.is_valid_punish then return true, {score = -3} end
      if self.has_hit then return true, {score = -1} end
      return true, {score = 0}
   end
   if player.other.has_just_blocked then return true, {score = 1} end
   return handle_interruptions(player, context)
end

function followup_punish:label()
   if self.selected_punish and self.selected_punish.action.label then return self.selected_punish.action:label() end
   return {"menu_" .. self.name}
end

local followup_close_mp = Followup:new("followup_close_mp", Action_Type.ATTACK)

function followup_close_mp:init()
   self.min_walk_frames = 4
   self.max_walk_frames = 30
   self.attack_range = 0
end

function followup_close_mp:setup(player, context)
   self:init()
   self.attack_range = framedata.get_contact_distance(player) + 25
   self.previous_action = context.actions[context.i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player, #d_lk_input, true) and
                          is_idle_timing(player.other, cl_mp_hit_frame + #cl_mp_input - recovery_gap, true)
            else
               return is_idle_timing(player, #cl_mp_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }
   }
end

function followup_close_mp:run(player, context)
   if all_commands_complete(player) then
      if player.has_just_been_blocked then
         return true, {score = 0}
      elseif player.has_just_hit then
         if not player.other.is_airborne then
            return true, {score = 0, next_followup = lk_ex_tourou}
         else
            return true, {score = -1}
         end
      end
   end
   return handle_interruptions(player, context)
end

function followup_close_mp:setup_walk_in(player, context) self.attack_range =
    framedata.get_contact_distance(player) + 21 end

function followup_close_mp:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   if player.other.character_state_byte == 1 and
       not is_idle_timing(player.other, cl_mp_hit_frame + #cl_mp_input - recovery_gap, true) then return false end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist <= self.attack_range then return true end
   return false
end

function followup_close_mp:should_execute(player, context)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local contact_dist = framedata.get_contact_distance(player)
   return dist <= contact_dist + 25
end

function followup_close_mp:followups() return close_mp_followups end

local followup_d_lk_d_lk = Followup:new("followup_d_lk_d_lk", Action_Type.ATTACK)

function followup_d_lk_d_lk:init()
   self.connection_count = 0
   self.should_input = false
   self.d_lk_delay = 10
   self.min_walk_frames = 4
   self.max_walk_frames = 30
   self.attack_range = 0
end

function followup_d_lk_d_lk:setup(player, context)
   self:init()
   self.attack_range = framedata.get_contact_distance(player) + 25
   self.previous_action = context.actions[context.i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player, #d_lk_input, true) and
                          is_idle_timing(player.other, d_lk_hit_frame + #d_lk_input - recovery_gap, true)
            else
               return is_idle_timing(player, #d_lk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input) end
      }
   }
end

function followup_d_lk_d_lk:run(player, context)
   if all_commands_complete(player) then
      if self.connection_count == 1 then self.d_lk_delay = self.d_lk_delay - 1 end
      if player.has_just_connected then
         self.connection_count = self.connection_count + 1
         if self.connection_count == 1 then self.should_input = true end
      end
      if self.should_input and self.d_lk_delay <= 0 then
         inputs.queue_input_sequence(player, d_lk_input)
         self.should_input = false
      end
      if self.connection_count == 2 then
         if player.has_just_been_blocked then
            return true, {score = 1}
         elseif player.has_just_hit then
            if player.combo == 2 then
               return true, {score = 0, next_followup = ex_tourou}
            else
               return true, {score = 0}
            end
         end
      end

   end
   return handle_interruptions(player, context)
end

function followup_d_lk_d_lk:setup_walk_in(player, context)
   self.attack_range = framedata.get_contact_distance(player) + 25
end

function followup_d_lk_d_lk:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   if player.other.character_state_byte == 1 and
       not is_idle_timing(player.other, d_lk_hit_frame + #d_lk_input - recovery_gap, true) then return false end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist <= self.attack_range then return true end
   return false
end

function followup_d_lk_d_lk:should_execute(player, context)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local contact_dist = framedata.get_contact_distance(player)
   return dist <= contact_dist + 25
end

local followup_d_lk = Followup:new("followup_d_lk", Action_Type.ATTACK)

function followup_d_lk:init()
   self.connection_count = 0
   self.min_walk_frames = 4
   self.max_walk_frames = 14
   self.attack_range = 0
   self.attack_range_reduction = 0
end

function followup_d_lk:setup(player, context)
   self:init()
   self.attack_range = framedata.get_contact_distance(player) + 33
   if not utils.is_in_opponent_throw_range(player) then self.min_walk_frames = 6 end
   self.previous_action = context.actions[context.i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_lk_input + d_lk_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type == Action_Type.FORWARD_DASH then
               return is_idle_timing(player, #d_lk_input, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player, #d_lk_input, true) and
                          is_idle_timing(player.other, d_lk_hit_frame + #d_lk_input - recovery_gap, true)
            elseif player.other.throw_invulnerability_cooldown > 0 then
               return is_throw_vulnerable_timing(player.other, d_lk_hit_frame + #d_lk_input + throw_break_tolerance,
                                                 true)
            elseif player.other.remaining_freeze_frames > 0 or player.other.recovery_time > 0 then
               if player.other.recovery_time > 0 then
                  return is_idle_timing(player.other, d_lk_hit_frame + #d_lk_input + throw_break_tolerance, true)
               end
            else
               return is_idle_timing(player, #d_lk_input, true)
            end
            return false
         end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input) end
      }
   }
end

function followup_d_lk:run(player, context)
   if all_commands_complete(player) then
      if player.has_just_hit or player.other.has_just_blocked then return true, {score = 0} end
   end
   return handle_interruptions(player, context)
end

function followup_d_lk:setup_walk_in(player, context) self.attack_range = framedata.get_contact_distance(player) + 33 end

function followup_d_lk:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local attack_range = self.attack_range
   if player.other.is_crouching then attack_range = attack_range - self.attack_range_reduction end
   if dist <= attack_range then return true end
   return false
end

function followup_d_lk:should_execute(player, context)
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= framedata.get_contact_distance(player) + 33
end

function followup_d_lk:followups() return down_lk_followups end

local followup_close_mk_jump_hk = Followup:new("followup_close_mk_jump_hk", Action_Type.ATTACK)

function followup_close_mk_jump_hk:init()
   self.timeout = 4 * 60
   self.connection_count = 0
   self.hit_count = 0
   self.should_input_hk = false
   self.should_parry = false
   self.has_parried = false
   self.should_queue_counter = false
   self.should_walk_in = false
   self.sjump_queued = false
   self.hk_delay = jump_hk_delay.default
   self.min_walk_frames = 0
   self.max_walk_frames = 30
   self.is_zenpou_punish = false
   self.attack_range = 0
   self.air_reset_recovery_gap = 3
end

function followup_close_mk_jump_hk:setup(player, context)
   self:init()
   self.hk_delay = jump_hk_delay[player.other.char_str] or jump_hk_delay.default

   local offset = cl_mk_offset[player.other.char_str] or cl_mk_offset.default
   self.attack_range = framedata.get_contact_distance(player) + offset
   self.previous_action = context.actions[context.i_actions - 1]

   if player.other.is_airborne then
      if prediction.predict_frames_before_landing(player.other) > cl_mk_hit_frame + #cl_mk_input - recovery_gap then
         self.should_walk_in = true
         return {{condition = nil, action = nil}}
      end
   end
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mk_input + cl_mk_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.name == "followup_zenpou" then
               local walk_frames = cl_mk_after_zenpou[player.other.char_str]
               if walk_frames and walk_frames > 0 then
                  self.min_walk_frames = walk_frames
                  self.should_walk_in = true
                  self.is_zenpou_punish = true
                  return true
               end
               return is_idle_timing(player, 1, true)
            elseif player.other.is_airborne then
               return is_idle_timing(player, #cl_mk_input, true) and
                          is_idle_timing(player.other, cl_mk_hit_frame + #cl_mk_input - guard_jump_recovery_gap, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player, #cl_mk_input, true) and
                          is_idle_timing(player.other, cl_mk_hit_frame + #cl_mk_input - self.air_reset_recovery_gap,
                                         true)
            else
               return is_idle_timing(player, #cl_mk_input, true)
            end
         end,
         action = function()
            if not self.should_walk_in then queue_input_sequence_and_wait(player, cl_mk_input) end
         end
      }
   }
end

function followup_close_mk_jump_hk:run(player, context)
   if self.should_walk_in then return true, {should_walk_in = true} end
   if all_commands_complete(player) then
      if player.has_just_connected then
         self.connection_count = self.connection_count + 1
         if player.has_just_hit then self.hit_count = self.hit_count + 1 end
         if self.connection_count == 1 then
            queue_input_sequence_and_wait(player, sjump_forward_input)
            self.sjump_queued = true
         end
         if self.hit_count == 2 then return true, {score = -2} end
         if self.hit_count == 1 and self.has_parried then return true, {score = -1, should_end = true} end
      end
      if self.sjump_queued then
         if self.hit_count == 1 and self.hk_delay > 0 then
            self.hk_delay = self.hk_delay - 1
            if self.hk_delay == 0 then self.should_input_hk = true end
         elseif self.hit_count == 0 then
            self.should_parry = true
         end
      end
      if self.should_input_hk then
         queue_input_sequence_and_wait(player, hk_input)
         self.should_input_hk = false
      elseif self.should_parry then
         dummy_control.update_blocking(inputs.input, player, parry_options)
      end
      if player.has_just_parried and player.is_airborne then
         self.should_queue_counter = true
         self.has_parried = true
         self.should_parry = false
      end
      if self.should_queue_counter then
         if is_idle_timing(player, #hk_input, true) then
            if player.other.is_airborne then
               queue_input_sequence_and_wait(player, hk_input)
            else
               queue_input_sequence_and_wait(player, {{"MK"}})
            end
            self.should_queue_counter = false
         end
      end
      if player.has_just_landed and self.hit_count < 2 then return true, {score = 1, should_end = true} end
   end
   if player.other.has_just_parried then
      if player.is_airborne then
         return true, {score = 2, should_end = true}
      else
         return false
      end
   end

   return handle_interruptions(player, context)
end

function followup_close_mk_jump_hk:setup_walk_in(player, context)
   local offset = cl_mk_offset[player.other.char_str] or cl_mk_offset.default
   self.attack_range = framedata.get_contact_distance(player) + offset
end

function followup_close_mk_jump_hk:walk_in_condition(player, walk_followup)
   if player.other.is_airborne then
      if prediction.predict_frames_before_landing(player.other) > cl_mk_hit_frame + #cl_mk_input -
          self.air_reset_recovery_gap then return false end
   end
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   if self.is_zenpou_punish then return true end
   if player.other.character_state_byte == 1 and
       not is_idle_timing(player.other, cl_mk_hit_frame + #cl_mk_input - guard_jump_recovery_gap, true) then
      return false
   end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist <= self.attack_range then return true end
   return false
end

function followup_close_mk_jump_hk:should_execute(player, context)
   self.previous_action = context.actions[context.i_actions - 1]
   if self.previous_action and self.previous_action.name == "followup_zenpou" or self.is_zenpou_punish then
      self.is_zenpou_punish = true
      return true
   end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   return dist <= self.attack_range
end

function followup_close_mk_jump_hk:followups() return close_mk_jump_hk_followups end

local followup_close_mp_lp_tourou = Followup:new("followup_close_mp_lp_tourou", Action_Type.ATTACK)

function followup_close_mp_lp_tourou:init()
   self.min_walk_frames = 4
   self.max_walk_frames = 30
   self.torou_hits = 0
   self.last_hit_frame = 0
   self.attack_range = 0
end

function followup_close_mp_lp_tourou:setup(player, context)
   self:init()
   self.attack_range = framedata.get_contact_distance(player) + 25
   self.previous_action = context.actions[context.i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #cl_mp_input + cl_mp_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player, #d_lk_input, true) and
                          is_idle_timing(player.other, cl_mp_hit_frame + #cl_mp_input - recovery_gap, true)
            else
               return is_idle_timing(player, #cl_mp_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, lp_tourou_input) end
      }
   }
end

function followup_close_mp_lp_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= lp_tourou_input_delay then
         queue_input_sequence_and_wait(player, lp_tourou_input)
         self.should_input = false
      end
      if player.has_just_connected then
         self.torou_hits = self.torou_hits + 1
         if self.torou_hits == 1 then
            if player.has_just_hit then
               self.should_input = true
               self.last_hit_frame = gamestate.frame_number
            elseif player.has_just_been_blocked or player.has_just_missed then
               return true, {score = 1}
            elseif player.other.has_just_parried then
               return true, {score = 2, should_end = true}
            end
         elseif self.torou_hits == 2 then
            self.should_input = true
            self.last_hit_frame = gamestate.frame_number
         else
            return true, {score = -2, should_end = true}
         end
      end
   end
   return handle_interruptions(player, context)
end

function followup_close_mp_lp_tourou:setup_walk_in(player, context)
   self.attack_range = framedata.get_contact_distance(player) + 25
end

function followup_close_mp_lp_tourou:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   if player.other.character_state_byte == 1 and
       not is_idle_timing(player.other, cl_mp_hit_frame + #cl_mp_input - recovery_gap, true) then return false end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist <= self.attack_range then return true end
   return false
end

function followup_close_mp_lp_tourou:should_execute(player, context)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local contact_dist = framedata.get_contact_distance(player)
   return dist <= contact_dist + 25
end

function followup_close_mp_lp_tourou:followups() return lp_tourou_followups end

local followup_down_mk_lp_tourou = Followup:new("followup_down_mk_lp_tourou", Action_Type.ATTACK)

function followup_down_mk_lp_tourou:init()
   self.min_walk_frames = 4
   self.max_walk_frames = 30
   self.torou_hits = 0
   self.last_hit_frame = 0
   self.attack_range = 0
end

function followup_down_mk_lp_tourou:setup(player, context)
   self:init()
   self.attack_range = framedata.get_contact_distance(player) + 25
   self.previous_action = context.actions[context.i_actions - 1]
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #d_mk_input + d_mk_hit_frame + 1, true)
            elseif self.previous_action and self.previous_action.type ~= Action_Type.WALK_FORWARD then
               return is_idle_timing(player, #d_lk_input, true) and
                          is_idle_timing(player.other, d_mk_hit_frame + #d_mk_input - recovery_gap, true)
            else
               return is_idle_timing(player, #d_mk_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, lp_tourou_input) end
      }
   }
end

function followup_down_mk_lp_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= lp_tourou_input_delay then
         queue_input_sequence_and_wait(player, lp_tourou_input)
         self.should_input = false
      end
      if player.has_just_connected then
         self.torou_hits = self.torou_hits + 1
         if self.torou_hits == 1 then
            if player.has_just_hit then
               self.should_input = true
               self.last_hit_frame = gamestate.frame_number
            elseif player.has_just_been_blocked or player.has_just_missed then
               return true, {score = 1}
            elseif player.other.has_just_parried then
               return true, {score = 2, should_end = true}
            end
         elseif self.torou_hits == 2 then
            self.should_input = true
            self.last_hit_frame = gamestate.frame_number
         else
            return true, {score = -2, should_end = true}
         end
      end
   end
   return handle_interruptions(player, context)
end

function followup_down_mk_lp_tourou:setup_walk_in(player, context)
   self.attack_range = framedata.get_contact_distance(player) + 25
end

function followup_down_mk_lp_tourou:walk_in_condition(player, walk_followup)
   if walk_followup.walked_frames < self.min_walk_frames then return false end
   if walk_followup.walked_frames >= self.max_walk_frames then return true end
   if player.other.character_state_byte == 1 and
       not is_idle_timing(player.other, d_mk_hit_frame + #d_mk_input - recovery_gap, true) then return false end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist <= self.attack_range then return true end
   return false
end

function followup_down_mk_lp_tourou:should_execute(player, context)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local contact_dist = framedata.get_contact_distance(player)
   return dist <= contact_dist + 55
end

function followup_down_mk_lp_tourou:followups() return lp_tourou_followups end

local followup_down_mk_ex_tourou = Followup:new("followup_down_mk_ex_tourou", Action_Type.ATTACK)

function followup_down_mk_ex_tourou:init()
   self.ex_torou_hits = 0
   self.should_input = false
   self.last_hit_frame = 0
   self.offset = 0
end

function followup_down_mk_ex_tourou:setup(player, context)
   self:init()

   return {
      {
         condition = function()
            inputs.queue_input_sequence(player, walk_forward_input)
            return is_idle_timing(player, #d_mk_input + self.offset, true)
         end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, ex_tourou_input) end
      }
   }
end

function followup_down_mk_ex_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= ex_tourou_input_delay then
         queue_input_sequence_and_wait(player, ex_tourou_input)
         self.should_input = false
         self.ex_torou_delay_increase = 0
      end
      if player.has_just_connected then
         self.ex_torou_hits = self.ex_torou_hits + 1
         if self.ex_torou_hits < 5 and player.has_just_hit then
            self.should_input = true
            self.last_hit_frame = gamestate.frame_number
         elseif player.has_just_been_blocked then
            return true, {score = 1, should_end = true}
         end
      end
      if self.ex_torou_hits >= 5 then return true, {score = -3, should_end = true} end
   end
   return handle_interruptions(player, context)
end

function followup_down_mk_ex_tourou:should_execute(player, context)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local contact_dist = framedata.get_contact_distance(player)
   return dist <= contact_dist + 76
end

local followup_lk_ex_tourou = Followup:new("followup_lk_ex_tourou", Action_Type.ATTACK)

function followup_lk_ex_tourou:init()
   self.ex_torou_hits = 0
   self.should_input = true
   self.last_hit_frame = 0
   self.offset = 0
end

function followup_lk_ex_tourou:setup(player, context)
   self:init()

   return {
      {
         condition = function()
            inputs.queue_input_sequence(player, walk_forward_input)
            return is_idle_timing(player, #lk_input + self.offset, true)
         end,
         action = function() queue_input_sequence_and_wait(player, lk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, ex_tourou_input) end
      }
   }
end

function followup_lk_ex_tourou:run(player, context)
   if all_commands_complete(player) then
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= ex_tourou_input_delay then
         queue_input_sequence_and_wait(player, ex_tourou_input)
         self.should_input = false
         self.ex_torou_delay_increase = 0
      end
      if player.has_just_connected then
         self.ex_torou_hits = self.ex_torou_hits + 1
         if self.ex_torou_hits < 5 and player.has_just_hit then
            self.should_input = true
            self.last_hit_frame = gamestate.frame_number
         elseif player.has_just_been_blocked then
            return true, {score = 1, should_end = true}
         end
      end
      if self.ex_torou_hits >= 5 then return true, {score = -3, should_end = true} end
   end
   return handle_interruptions(player, context)
end

function followup_lk_ex_tourou:should_execute(player, context)
   local attack_options = {}
   attack_options[player.id] = {char_str = player.char_str, name = "LK", delay = 0}
   local connected, results = prediction.predict_attack_connection(nil, nil, attack_options)
   if connected then return true end
end

local followup_kara_throw = Followup:new("followup_kara_throw", Action_Type.THROW)

function followup_kara_throw:init()
   self.should_walk_in = false
   self.should_block_before = false
   self.max_walk_frames = throw_walk_frames
   self.min_block_frames = 6
   self.opponent_has_been_thrown = false
   self.throw_delay = 0
   self.throw_threshold = throw_threshold
end

function followup_kara_throw:setup(player, context)
   self:init()
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action then
      if previous_action.type == Action_Type.ATTACK then
         self.throw_delay = kara_throw_delay
         self.throw_threshold = throw_threshold + 2
      end
      if previous_action.type ~= Action_Type.WALK_FORWARD then
         local dist = math.abs(player.other.pos_x - player.pos_x)
         if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or
             player.other.just_received_connection or player.other.is_in_pushback then
            local predicted_state = prediction.predict_gamestate(nil, nil, player.other.remaining_freeze_frames +
                                                                     player.other.recovery_time)
            dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
            self.predicted_dist = dist
         end
         self.should_walk_in = hk_kara_throw_range - self.throw_threshold < dist -
                                   character_specific[player.other.char_str].pushbox_width / 2
      end
   end

   if player.other.is_waking_up then self.should_block_before = true end

   if self.should_walk_in or self.should_block_before then return {{condition = nil, action = nil}} end
   return {
      {
         condition = function()
            if is_idle_timing(player, 1, true) and player.other.standing_state > 0 and
                is_throw_vulnerable_timing(player.other, #kara_throw_input + throw_hit_frame + 1 - self.throw_delay,
                                           true) then return true end
            return false
         end,
         action = function() queue_input_sequence_and_wait(player, kara_throw_input) end
      }
   }
end

function followup_kara_throw:run(player, context)
   if self.should_walk_in then return true, {should_walk_in = true} end
   if self.should_block_before then return true, {should_block_before = true} end
   if all_commands_complete(player) then
      dummy_control.update_mash_inputs(inputs.input, player, 3)
      if player.is_in_throw_tech or player.other.is_in_throw_tech then return true, {score = 1} end
      if self.opponent_has_been_thrown then if not player.other.is_being_thrown then return true, {score = -1} end end
      if player.other.has_just_been_thrown then self.opponent_has_been_thrown = true end
   end
   return handle_interruptions(player, context)
end

function followup_kara_throw:setup_block(player, context, block_followup)
   if player.other.is_waking_up then
      block_followup.block_time = 6
      self.min_block_frames = 6
   end
end

function followup_kara_throw:block_condition(player, block_followup)
   if block_followup.blocked_frames < self.min_block_frames then return false end
   if is_throw_vulnerable_timing(player.other, #kara_throw_input + throw_hit_frame + 1 - self.throw_delay, true) then
      return true
   end
   return false
end

function followup_kara_throw:walk_in_condition(player, walk_followup)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
      local animation_options = {}
      local standing_anim = framedata.frame_data[player.char_str].standing
      animation_options[player.id] = {set = {animation = standing_anim, frame = 0}}
      local predicted_state = prediction.predict_gamestate(nil, animation_options,
                                                           player.other.remaining_freeze_frames +
                                                               player.other.recovery_time)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
      self.predicted_dist = dist
   else
      local animation_options = {{ignore_optional_anim = true}, {ignore_optional_anim = true}}
      local standing_anim = framedata.frame_data[player.char_str].standing
      animation_options[player.id] = {set = {animation = standing_anim, frame = 0}}
      local predicted_state = prediction.predict_gamestate(nil, animation_options, 1)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
      self.predicted_dist = dist
   end
   if hk_kara_throw_range - self.throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 or
       walk_followup.walked_frames >= self.max_walk_frames then return true end
   return false
end

function followup_kara_throw:walk_out_condition(player, walk_followup)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if hk_kara_throw_range - self.throw_threshold > dist - character_specific[player.other.char_str].backward_walk_speed -
       character_specific[player.other.char_str].pushbox_width / 2 then return false end
   return true
end

function followup_kara_throw:should_execute(player, context)
   self.predicted_dist = nil
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
      local predicted_state = prediction.predict_gamestate(nil, nil, player.other.remaining_freeze_frames +
                                                               player.other.recovery_time)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
      self.predicted_dist = dist
   end
   local crouching_delay = 0
   if player.is_crouching then crouching_delay = 1 end
   local walk_dist = utils.get_forward_walk_distance(player, throw_walk_frames - crouching_delay)
   return hk_kara_throw_range - throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 -
              walk_dist
end

local followup_zenpou = Followup:new("followup_zenpou", Action_Type.THROW)

function followup_zenpou:init()
   self.should_walk_in = false
   self.should_block_before = false
   self.max_walk_frames = throw_walk_frames
   self.min_block_frames = 6
   self.opponent_has_been_thrown = false
   self.throw_delay = 0
   self.throw_threshold = throw_threshold
end

function followup_zenpou:setup(player, context)
   self:init()
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action then
      if previous_action.name == "setup_raigeki_crossthrough" then self.throw_threshold = throw_threshold + 12 end
      if previous_action.type == Action_Type.ATTACK then self.throw_threshold = throw_threshold + 4 end
      if previous_action.type ~= Action_Type.WALK_FORWARD then
         local dist = math.abs(player.other.pos_x - player.pos_x)
         if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
            local animation_options = {{ignore_optional_anim = true}, {ignore_optional_anim = true}}
            local predicted_state = prediction.predict_gamestate(nil, animation_options, player.other
                                                                     .remaining_freeze_frames +
                                                                     player.other.recovery_time + 10)
            dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
            self.predicted_dist = dist
         end
         self.should_walk_in = zenpou_range - self.throw_threshold < dist -
                                   character_specific[player.other.char_str].pushbox_width / 2
      end
   end
   if player.other.is_airborne then
      if prediction.predict_frames_before_landing(player.other) + 6 > #zenpou_input + zenpou_hit_frame + 1 -
          self.throw_delay then
         self.should_walk_in = true
         return {{condition = nil, action = nil}}
      end
   elseif player.other.is_waking_up then
      self.should_block_before = true
   end

   if self.should_walk_in or self.should_block_before then return {{condition = nil, action = nil}} end

   return {
      {
         condition = nil,
         action = function()
            if previous_action.type == Action_Type.WALK_FORWARD then
               if not (is_idle_timing(player, 1, true) and player.other.standing_state > 0 and
                   is_throw_vulnerable_timing(player.other, #zenpou_input + zenpou_hit_frame + 1 - self.throw_delay,
                                              true)) then
                  queue_input_sequence_and_wait(player, walk_back_input, 0, true)
               end
            end
         end
      }, {
         condition = function()
            if is_idle_timing(player, 1, true) and player.other.standing_state > 0 and
                is_throw_vulnerable_timing(player.other, #zenpou_input + zenpou_hit_frame + 1 - self.throw_delay, true) then
               return true
            end
            return false
         end,
         action = function() queue_input_sequence_and_wait(player, zenpou_input) end
      }
   }
end

function followup_zenpou:run(player, context)
   if self.should_walk_in then return true, {should_walk_in = true} end
   if self.should_block_before then return true, {should_block_before = true} end
   if all_commands_complete(player) then
      if player.is_in_throw_tech or player.other.is_in_throw_tech then return true, {score = 1} end
      if self.opponent_has_been_thrown then
         if cl_mk_after_zenpou[player.other.char_str] then
            return true, {score = 0, next_followup = cl_mk_jump_hk}
         else
            return true, {score = 0, next_followup = d_mk_ex_tourou}
         end
      end
      if player.other.has_just_been_thrown then self.opponent_has_been_thrown = true end
   end
   return handle_interruptions(player, context)
end

function followup_zenpou:setup_block(player, context, block_followup)
   if player.other.is_waking_up then
      block_followup.block_time = 6
      self.min_block_frames = 6
   end
end

function followup_zenpou:block_condition(player, block_followup)
   if block_followup.blocked_frames < self.min_block_frames then return false end
   if is_throw_vulnerable_timing(player.other, #zenpou_input + zenpou_hit_frame + 1 - self.throw_delay, true) then
      return true
   end
   return false
end

function followup_zenpou:setup_walk_in(player, context, walk_followup)
   self.max_walk_frames = 40
   walk_followup.max_walk_frames = 40
end

function followup_zenpou:walk_in_condition(player, walk_followup)
   if player.other.is_airborne then
      if prediction.predict_frames_before_landing(player.other) + 6 > #zenpou_input + zenpou_hit_frame + 1 -
          self.throw_delay then return false end
   end
   if player.is_airborne then return false end

   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback or
       player.has_just_ended_recovery then
      local animation_options = {{ignore_optional_anim = true}, {ignore_optional_anim = true}}
      local standing_anim = framedata.frame_data[player.char_str].standing
      animation_options[player.id] = {set = {animation = standing_anim, frame = 0}}
      local predicted_state = prediction.predict_gamestate(nil, animation_options,
                                                           player.other.remaining_freeze_frames +
                                                               player.other.recovery_time + 10)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
      self.predicted_dist = dist
   elseif player.other.is_airborne then
      local animation_options = {{ignore_optional_anim = true}, {ignore_optional_anim = true}}
      local standing_anim = framedata.frame_data[player.char_str].standing
      animation_options[player.id] = {set = {animation = standing_anim, frame = 0}}
      local frames_until_landing = prediction.predict_frames_before_landing(player.other)
      local predicted_state = prediction.predict_gamestate(nil, animation_options, frames_until_landing + 4)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
   else
      local animation_options = {{ignore_optional_anim = true}, {ignore_optional_anim = true}}
      local standing_anim = framedata.frame_data[player.char_str].standing
      animation_options[player.id] = {set = {animation = standing_anim, frame = 0}}
      local predicted_state = prediction.predict_gamestate(nil, animation_options, 1)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
      self.predicted_dist = dist
   end
   if player.action == 2 then dist = dist - character_specific[player.char_str].forward_walk_speed end
   if zenpou_range - self.throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 or
       walk_followup.walked_frames >= self.max_walk_frames then return true end
   return false
end

function followup_zenpou:walk_out_condition(player, walk_followup)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if zenpou_range - self.throw_threshold > dist - character_specific[player.other.char_str].backward_walk_speed -
       character_specific[player.other.char_str].pushbox_width / 2 then return false end
   return true
end

function followup_zenpou:should_execute(player, context)
   self.predicted_dist = nil
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action and (previous_action.type == Action_Type.WALK_FORWARD) then return true end
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or player.other.is_in_pushback then
      local predicted_state = prediction.predict_gamestate(nil, nil, player.other.remaining_freeze_frames +
                                                               player.other.recovery_time)
      dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
      self.predicted_dist = dist
   end
   local crouching_delay = 0
   if player.is_crouching then crouching_delay = 1 end
   local walk_dist = utils.get_forward_walk_distance(player, throw_walk_frames - crouching_delay)
   return zenpou_range - throw_threshold >= dist - character_specific[player.other.char_str].pushbox_width / 2 -
              walk_dist
end

local followup_uoh = Followup:new("followup_uoh", Action_Type.ATTACK)

function followup_uoh:init()
   self.should_walk_out = false
   self.wakeup_offset = 4
   self.attack_range_min = 0
end

function followup_uoh:setup(player, context)
   self:init()
   local contact_dist = framedata.get_contact_distance(player)
   local offset = uoh_offset[player.other.char_str] or uoh_offset.default
   self.attack_range_min = contact_dist + offset
   local previous_action = context.actions[context.i_actions - 1]
   if previous_action then
      if previous_action.name == "followup_close_mk_jump_hk" or previous_action.name == "setup_close_mk_jump_hk" then
         self.should_walk_out = false
      elseif previous_action.type ~= Action_Type.WALK_BACKWARD then
         local dist = math.abs(player.other.pos_x - player.pos_x)
         if player.other.remaining_freeze_frames > 0 or player.other.freeze_just_ended or
             player.other.just_received_connection or player.other.is_in_pushback then
            local animation_options = {{ignore_optional_anim = true}, {ignore_optional_anim = true}}
            local time_until_idle = prediction.get_frames_until_idle(player, nil, nil, 80)
            local predicted_state = prediction.predict_gamestate(nil, animation_options,
                                                                 time_until_idle + #uoh_input + uoh_hit_frame + 1)
            dist = math.abs(predicted_state.P1.pos_x - predicted_state.P2.pos_x)
         end
         self.should_walk_out = dist < self.attack_range_min
      end
   end
   if self.should_walk_out then return {{condition = nil, action = nil}} end
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, #uoh_input + uoh_hit_frame + self.wakeup_offset + 1, true)
            else
               return is_idle_timing(player, #uoh_input, true)
            end
         end,
         action = function() queue_input_sequence_and_wait(player, uoh_input) end
      }
   }
end

function followup_uoh:run(player, context)
   if self.should_walk_out then return true, {should_walk_out = true} end
   if all_commands_complete(player) then
      if player.has_just_hit then
         return true, {should_punish = true}
      elseif player.other.has_just_blocked then
         return true, {score = 1}
      end
   end
   return handle_interruptions(player, context)
end

function followup_uoh:walk_out_condition(player, walk_followup)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   if dist < self.attack_range_min then return false end
   return true
end

function followup_uoh:should_execute(player, context)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local contact_dist = framedata.get_contact_distance(player)
   local offset = uoh_offset[player.other.char_str] or uoh_offset.default
   self.attack_range_min = contact_dist + offset
   return dist <= self.attack_range_min + 6
end

local followup_walk_in = Followup:new("followup_walk_in", Action_Type.WALK_FORWARD)

function followup_walk_in:init()
   self.min_walk_frames = 4
   self.max_walk_frames = 30
   self.walked_frames = 0
end

function followup_walk_in:setup(player, context)
   self:init()
   self.next_action = context.actions[context.i_actions + 1]
   if self.next_action and self.next_action.walk_in_condition then
      local defense_context = copytable(context)
      defense_context.i_actions = context.i_actions + 1
      if self.next_action.setup_walk_in then self.next_action:setup_walk_in(player, defense_context, self) end
   end
   local setup = {
      {
         condition = function() return is_idle_timing(player, 1, true) end,
         action = function() inputs.queue_input_sequence(player, walk_forward_input, 0, true) end
      }
   }
   return setup
end

function followup_walk_in:run(player, context)
   if player.action == 2 then self.walked_frames = self.walked_frames + 1 end
   if all_commands_complete(player) then
      self.next_action = context.actions[context.i_actions + 1]
      if self.next_action and self.next_action.walk_in_condition and self.next_action:walk_in_condition(player, self) then
         return true, {score = 0}
      end
      if self.walked_frames < self.max_walk_frames then
         self:extend(player)
      else
         return true, {score = 0}
      end
   end
   return handle_interruptions(player, context)
end

function followup_walk_in:extend(player) inputs.queue_input_sequence(player, walk_forward_input, 0, true) end

function followup_walk_in:label() return {"menu_" .. self.name, " ", self.walked_frames, "hud_f"} end

function followup_walk_in:followups() return walk_in_followups end

local followup_walk_out = Followup:new("followup_walk_out", Action_Type.WALK_BACKWARD)
local walk_out_margin = 10
local walk_out_max_frames = 20
local wakeup_walk_out_timing = 10

function followup_walk_out:init()
   self.min_walk_in_frames = 6
   self.min_walk_frames = 12
   self.walked_frames = 0
   self.active_frames = 0
end

function followup_walk_out:setup(player, context)
   self:init()
   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, wakeup_walk_out_timing, true)
            else
               return is_idle_timing(player, 1, true)
            end
         end,
         action = function() self:extend(player) end
      }
   }
   return setup
end

function followup_walk_out:run(player, context)
   if player.action == 3 then self.walked_frames = self.walked_frames + 1 end
   if all_commands_complete(player) then
      local next_action = context.actions[context.i_actions + 1]
      if next_action and next_action.walk_out_condition and next_action:walk_out_condition(player, self) then
         return true, {score = 0}
      end
      if not (next_action and next_action.walk_out_condition) then
         local dist = math.abs(player.other.pos_x - player.pos_x)
         local opponent_throw_range = framedata.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral")
         local throwable_box_extension = 0
         if next_action and next_action.type == Action_Type.BLOCK then throwable_box_extension = 4 end
         if self.active_frames >= self.min_walk_frames and opponent_throw_range < dist -
             character_specific[player.char_str].pushbox_width / 2 - walk_out_margin - throwable_box_extension then
            return true, {score = 0}
         end
      end
      if player.has_just_blocked then return true, {should_block = true} end
      if self.active_frames < walk_out_max_frames then
         self:extend(player)
      else
         return true, {score = 0}
      end
   end
   return handle_interruptions(player, context)
end

function followup_walk_out:extend(player)
   self.active_frames = self.active_frames + 1
   inputs.queue_input_sequence(player, walk_back_input, 0, true)
end

function followup_walk_out:walk_in_condition(player, walk_followup)
   if walk_followup.active_frames < self.min_walk_in_frames then return false end
   return true
end

function followup_walk_out:is_valid(player, context)
   for _, action in ipairs(context.actions) do if action.type == Action_Type.WALK_BACKWARD then return false end end
   return true
end

function followup_walk_out:should_execute(player, context)
   local current_stage = stage_data.stages[context.stage]
   local sign = tools.sign(player.other.pos_x - player.pos_x)
   local dist = math.max(math.abs(player.other.pos_x - player.pos_x), framedata.get_contact_distance(player))
   local opponent_throw_range = framedata.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral")
   local walk_frames = walk_out_max_frames
   local walk_dist = utils.get_backward_walk_distance(player, walk_frames)
   return (player.pos_x - sign * walk_dist >= current_stage.left +
              character_specific[player.char_str].corner_offset_left) and
              (player.pos_x - sign * walk_dist <= current_stage.right -
                  character_specific[player.char_str].corner_offset_right) and
              (opponent_throw_range < dist + walk_dist - character_specific[player.char_str].pushbox_width / 2)
end

function followup_walk_out:label() return {"menu_" .. self.name, " ", self.walked_frames, "hud_f"} end

function followup_walk_out:followups(player) return walk_out_followups end

local followup_forward_down = Followup:new("followup_forward_down", Action_Type.PARRY)

function followup_forward_down:init()
   self.parry_offset = 0
   self.has_parried = false
end

function followup_forward_down:setup(player, context)
   self:init()
   self.parry_duration = Delay:new(parry_frames)
   return {
      {
         condition = function()
            if player.character_state_byte ~= 4 then
               if player.other.character_state_byte == 1 then
                  if player.other.remaining_freeze_frames > 0 or player.other.recovery_time > 0 then
                     if player.other.recovery_time > 0 then
                        self.parry_offset = player.other.recovery_time + 2
                        return true
                     end
                  end
                  return false
               else
                  self.parry_offset = 0
                  return is_idle_timing(player, 1)
               end
            end
            return false
         end,
         action = function()
            queue_input_sequence_and_wait(player, {{}, {"forward"}}, self.parry_offset)
            self.parry_duration:begin(parry_frames + self.parry_offset)
         end
      }, {
         condition = function() return self.parry_duration:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, {{"down"}})
            self.parry_duration:begin(parry_frames + 2)
         end
      }
   }
end

function followup_forward_down:run(player, context)
   if player.has_just_parried then self.has_parried = true end
   if self.has_parried then
      local next_hit_delta = framedata.get_next_hit_frame(player.other.char_str, player.other.animation,
                                                          player.other.current_hit_id) - player.other.animation_frame
      if next_hit_delta <= 0 then next_hit_delta = 99 end
      if player.other.animation_frame_data then
         local type = player.other.animation_frame_data.type
         if type then
            if type == "normal" then
               next_hit_delta = next_hit_delta + 2
            elseif type == "super" then
               next_hit_delta = next_hit_delta - 1
            end
         end
      end
      if next_hit_delta >= punish_delta then
         advanced_control.clear_programmed_movement(player)
         return true, {should_punish = true}
      else
         return true, {should_block = true}
      end
   elseif all_commands_complete(player) then
      if self.parry_duration:is_complete() then return true, {score = 1} end
   end
   return handle_interruptions(player, context)
end

function followup_forward_down:is_valid(player, context)
   for _, action in ipairs(context.actions) do if action.type == Action_Type.WALK_FORWARD then return false end end
   return true
end

local followup_down_forward = Followup:new("followup_down_forward", Action_Type.PARRY)

function followup_down_forward:init()
   self.parry_offset = 0
   self.has_parried = false
end

function followup_down_forward:setup(player, context)
   self:init()
   self.parry_duration = Delay:new(parry_frames)
   return {
      {
         condition = function()
            if player.character_state_byte ~= 4 then
               if player.other.character_state_byte == 1 then
                  if player.other.remaining_freeze_frames > 0 or player.other.recovery_time > 0 then
                     if player.other.recovery_time > 0 then
                        self.parry_offset = player.other.recovery_time + 2
                        return true
                     end
                  end
                  return false
               else
                  self.parry_offset = 0
                  return is_idle_timing(player, 1)
               end
            end
            return false
         end,
         action = function()
            queue_input_sequence_and_wait(player, {{}, {"down"}}, self.parry_offset)
            self.parry_duration:begin(parry_frames + self.parry_offset)
         end
      }, {
         condition = function() return self.parry_duration:is_complete() end,
         action = function()
            queue_input_sequence_and_wait(player, {{"forward"}})
            self.parry_duration:begin(parry_frames + 2)
         end
      }
   }
end

function followup_down_forward:run(player, context)
   if player.has_just_parried then self.has_parried = true end
   if self.has_parried then
      local next_hit_delta = framedata.get_next_hit_frame(player.other.char_str, player.other.animation,
                                                          player.other.current_hit_id) - player.other.animation_frame
      if next_hit_delta <= 0 then next_hit_delta = 99 end
      if player.other.animation_frame_data then
         local type = player.other.animation_frame_data.type
         if type then
            if type == "normal" then
               next_hit_delta = next_hit_delta + 2
            elseif type == "super" then
               next_hit_delta = next_hit_delta - 1
            end
         end
      end
      if next_hit_delta >= punish_delta then
         advanced_control.clear_programmed_movement(player)
         return true, {should_punish = true}
      else
         return true, {should_block = true}
      end
   elseif all_commands_complete(player) then
      if self.parry_duration:is_complete() then return true, {score = 1} end
   end
   return handle_interruptions(player, context)
end

function followup_down_forward:is_valid(player, context)
   for _, action in ipairs(context.actions) do if action.type == Action_Type.WALK_FORWARD then return false end end
   return true
end

local followup_block = Followup:new("followup_block", Action_Type.BLOCK)

function followup_block:init()
   self.timeout = 4 * 60
   self.blocked_frames = 0
   self.block_time = 8
   self.has_blocked = false
   self.has_parried = false
   self.should_reselect = false
end

function followup_block:setup(player, context)
   self:init()
   self.next_action = context.actions[context.i_actions + 1]
   if self.next_action and self.next_action.block_condition then
      local defense_context = copytable(context)
      defense_context.i_actions = context.i_actions + 1
      if self.next_action:should_execute(player, defense_context) then
         if self.next_action.setup_block then self.next_action:setup_block(player, defense_context, self) end
      else
         self.should_reselect = true
      end
   end
   return {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, 1)
            elseif player.character_state_byte == 1 then
               return true
            else
               return is_idle_timing(player, 1)
            end
         end,
         action = function()
            dummy_control.update_blocking(inputs.input, player, blocking_options)
            self.blocked_frames = self.blocked_frames + 1
            self.block_time = self.block_time + player.other.recovery_time + player.other.remaining_wakeup_time
         end
      }
   }
end

function followup_block:run(player, context)
   if self.should_reselect then
      self.should_reselect = false
      return true, {should_reselect = true}
   end
   if all_commands_complete(player) then
      if player.has_just_blocked or player.is_blocking then
         self.has_blocked = true
         self.block_time = self.blocked_frames
      end
      if player.has_just_parried then
         self.has_parried = true
         self.block_time = self.blocked_frames
      end

      if self.blocked_frames < self.block_time then
         if not player.other.is_waking_up then self:extend(player) end
      else
         if self:should_block(player) then
            self:extend(player)
         else
            if player.other.is_jumping then
               return true, {score = 1}
            elseif player.other.is_airborne and player.other.character_state_byte == 4 then
               return true, {score = -3, should_end = true}
            elseif self.has_parried then
               return true, {should_punish = true}
            elseif self.has_blocked and not player.other.is_airborne and player.remaining_freeze_frames == 0 then
               if prediction.get_frame_advantage(player) >= block_punish_threshold then
                  return true, {should_punish = true}
               else
                  return true, {score = 1, should_end = true}
               end
            else
               self.next_action = context.actions[context.i_actions + 1]
               if self.next_action and self.next_action.block_condition and
                   self.next_action:block_condition(player, self) then return true, {score = 0} end
               return true, {score = 1}
            end
         end
      end
   end
   return handle_interruptions(player, context)
end

function followup_block:should_block(player)
   if player.other.superfreeze_decount > 0 then
      self.block_time = self.blocked_frames + 10
      return true
   end
   if player.other.just_cancelled_into_attack then
      self.block_time = self.blocked_frames + 10
      return true
   end
   if player.has_just_blocked then
      self.block_time = self.blocked_frames + 10
      return true
   end
   if player.freeze_just_ended then
      self.block_time = self.blocked_frames + 2
      return true
   end
   if player.character_state_byte == 1 then
      self.block_time = self.blocked_frames + 1
      return true
   end
   return false
end

function followup_block:extend(player)
   self.blocked_frames = self.blocked_frames + 1
   dummy_control.update_blocking(inputs.input, player, blocking_options)
end

function followup_block:label() return {"menu_" .. self.name, " ", self.blocked_frames, "hud_f"} end

local function setup_run_default(self, player, context)
   if advanced_control.all_commands_complete(player) and not inputs.is_playing_input_sequence(player) then return true end
   return false
end

local setup_raigeki_high = Setup:new("setup_raigeki_high")
setup_raigeki_high.should_block_input = true

function setup_raigeki_high:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].high.offset or
                      jumpin_data.default.high.offset
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_raigeki_high:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - corner_gap
   }
end

function setup_raigeki_high:get_dummy_offset(player)
   local dummy_offset_x = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].high.offset or
                              jumpin_data.default.high.offset
   return dummy_offset_x
end

function setup_raigeki_high:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].high or
                           jumpin_data.default.high
   local attack_input_frame = attack_data.delay
   local attack_input = {{"down", "forward", attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, setup_jumpin_wakeup_delay, true)
            else
               return true
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected or player.has_just_landed then return true end
         end,
         action = function() connection_end_delay:reset() end
      }, {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

setup_raigeki_high.run = setup_run_default

function setup_raigeki_high:followups() return raigeki_high_followups end

local setup_raigeki_mid = Setup:new("setup_raigeki_mid")
setup_raigeki_mid.should_block_input = true

function setup_raigeki_mid:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].mid.offset or
                      jumpin_data.default.mid.offset
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_raigeki_mid:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - corner_gap
   }
end

function setup_raigeki_mid:get_dummy_offset(player)
   local dummy_offset_x = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].mid.offset or
                              jumpin_data.default.mid.offset
   return dummy_offset_x
end

function setup_raigeki_mid:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].mid or
                           jumpin_data.default.mid
   local attack_input_frame = attack_data.delay
   local attack_input = {{"down", "forward", attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, setup_jumpin_wakeup_delay, true)
            else
               return true
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected or player.has_just_landed then return true end
         end,
         action = function() connection_end_delay:reset() end
      }, {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

setup_raigeki_mid.run = setup_run_default

function setup_raigeki_mid:followups() return raigeki_mid_followups end

local setup_raigeki_low = Setup:new("setup_raigeki_low")
setup_raigeki_low.should_block_input = true

function setup_raigeki_low:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].low.offset or
                      jumpin_data.default.low.offset
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_raigeki_low:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - corner_gap
   }
end

function setup_raigeki_low:get_dummy_offset(player)
   local dummy_offset_x = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].low.offset or
                              jumpin_data.default.low.offset
   return dummy_offset_x
end

function setup_raigeki_low:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].low or
                           jumpin_data.default.low
   local attack_input_frame = attack_data.delay
   local attack_input = {{"down", "forward", attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, setup_jumpin_wakeup_delay, true)
            else
               return true
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected or player.has_just_landed then return true end
         end,
         action = function() connection_end_delay:reset() end
      }, {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

setup_raigeki_low.run = setup_run_default

function setup_raigeki_low:followups() return raigeki_low_followups end

local setup_raigeki_crossthrough = Setup:new("setup_raigeki_crossthrough")
setup_raigeki_crossthrough.should_block_input = true

function setup_raigeki_crossthrough:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossthrough.offset or
                      jumpin_data.default.crossthrough.offset
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_raigeki_crossthrough:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + raigeki_crossthrough_corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - raigeki_crossthrough_corner_gap
   }
end

function setup_raigeki_crossthrough:get_dummy_offset(player)
   local dummy_offset_x =
       jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossthrough.offset or
           jumpin_data.default.crossthrough.offset
   return dummy_offset_x
end

function setup_raigeki_crossthrough:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossthrough or
                           jumpin_data.default.crossthrough
   local attack_input_frame = attack_data.delay
   local attack_input = {{"down", "forward", attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, setup_jumpin_wakeup_delay, true)
            else
               return true
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected or player.has_just_landed then return true end
         end,
         action = function() connection_end_delay:reset() end
      }, {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

setup_raigeki_crossthrough.run = setup_run_default

function setup_raigeki_crossthrough:followups() return raigeki_crossthrough_followups end

local setup_raigeki_crossup = Setup:new("setup_raigeki_crossup")
setup_raigeki_crossup.should_lock_positions = false
setup_raigeki_crossup.ignore_start_delay = true
setup_raigeki_crossup.is_wakeup = true
setup_raigeki_crossup.should_block_input = true

function setup_raigeki_crossup:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossup.offset or
                      jumpin_data.default.crossup.offset
   offset = offset + framedata.get_contact_distance(player)
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_raigeki_crossup:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + raigeki_crossup_corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - raigeki_crossup_corner_gap
   }
end

function setup_raigeki_crossup:get_dummy_offset(player)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossup or
                           jumpin_data.default.crossup
   return framedata.get_contact_distance(player) + attack_data.offset
end

function setup_raigeki_crossup:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossup or
                           jumpin_data.default.crossup
   local attack_input_frame = attack_data.delay
   self.jump_timing = attack_data.jump_timing
   local attack_input = {{"down", "forward", attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)
   self.connected_hits = 0
   local setup = {
      {
         condition = function()
            if player.other.is_waking_up and player.other.posture_ext >= 0x40 then
               return player.other.remaining_wakeup_time > 0 and player.other.remaining_wakeup_time <= self.jump_timing
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            self.jump_queued = true
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected then return true end
         end,
         action = function() connection_end_delay:reset() end
      }, {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

function setup_raigeki_crossup:run(player, context)
   if advanced_control.all_commands_complete(player) and not inputs.is_playing_input_sequence(player) then return true end
   if player.has_just_connected then self.connected_hits = self.connected_hits + 1 end
   if (player.has_just_landed and self.connected_hits == 0) or
       (gamestate.is_standing_state(player.other, player.other.standing_state) and not self.jump_queued) then
      return true, {should_cancel = true}
   end
   return false
end

function setup_raigeki_crossup:is_valid(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].crossup or
                           jumpin_data.default.crossup
   self.jump_timing = attack_data.jump_timing
   if player.other.is_in_air_reel then
      return true
   elseif player.other.is_waking_up then
      if player.other.remaining_wakeup_time > 0 and player.other.remaining_wakeup_time < self.jump_timing then
         return false
      end
   end
   return true
end

function setup_raigeki_crossup:followups() return raigeki_crossup_followups end

local setup_raigeki_whiff = Setup:new("setup_raigeki_whiff")
setup_raigeki_whiff.should_block_input = true

function setup_raigeki_whiff:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].whiff.offset or
                      jumpin_data.default.whiff.offset
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_raigeki_whiff:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - corner_gap
   }
end

function setup_raigeki_whiff:get_dummy_offset(player)
   local dummy_offset_x = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].whiff.offset or
                              jumpin_data.default.whiff.offset
   return dummy_offset_x
end

function setup_raigeki_whiff:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].whiff or
                           jumpin_data.default.whiff
   local attack_input_frame = attack_data.delay
   local attack_input = {{"down", "forward", attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, setup_jumpin_wakeup_delay, true)
            else
               return true
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected or player.has_just_landed then return true end
         end,
         action = function() connection_end_delay:reset() end
      }
   }
   return setup
end

setup_raigeki_whiff.run = setup_run_default

function setup_raigeki_whiff:followups() return raigeki_whiff_followups end

local setup_jump_mp = Setup:new("setup_jump_mp")
setup_jump_mp.should_block_input = true

function setup_jump_mp:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local offset = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].mp.offset or
                      jumpin_data.default.mp.offset
   return {
      current_stage.left + character_specific.yang.corner_offset_left + offset,
      current_stage.right - character_specific.yang.corner_offset_right - offset
   }
end

function setup_jump_mp:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left + corner_gap,
      current_stage.right - character_specific[other_char].corner_offset_right - corner_gap
   }
end

function setup_jump_mp:get_dummy_offset(player)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].mp or
                           jumpin_data.default.mp
   return attack_data.offset
end

function setup_jump_mp:setup(player, context)
   local attack_data = jumpin_data[player.other.char_str] and jumpin_data[player.other.char_str].mp or
                           jumpin_data.default.mp
   local attack_input_frame = attack_data.delay
   self.jump_timing = attack_data.jump_timing
   local attack_input = {{attack_data.button}}
   local attack_input_delay = Delay:new(attack_input_frame - 1)

   local setup = {
      {
         condition = function()
            if player.other.is_waking_up then
               return is_wakeup_timing(player.other, setup_jumpin_wakeup_delay, true)
            else
               return true
            end
         end,
         action = function()
            queue_input_sequence_and_wait(player, jump_forward_input)
            attack_input_delay:begin()
         end
      }, {
         condition = function() return attack_input_delay:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, attack_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected then return true end
         end,
         action = function() connection_end_delay:reset() end
      }, {condition = function() return connection_end_delay:is_complete() end, action = nil}
   }
   return setup
end

setup_jump_mp.run = setup_run_default

function setup_jump_mp:followups() return jump_mp_followups end

local setup_close_mp = Setup:new("setup_close_mp")
setup_close_mp.should_block_input = true

function setup_close_mp:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.yang.corner_offset_left + character_specific.yang.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.yang.corner_offset_right - character_specific.yang.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_close_mp:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_close_mp:get_dummy_offset(player) return framedata.get_contact_distance(player) end

function setup_close_mp:setup(player, context)
   return {
      {
         condition = function()
            return gamestate.is_ground_state(player.other, player.other.standing_state) and
                       is_idle_timing(player, #cl_mp_input, true)
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected then return true end
         end,
         action = nil
      }
   }
end

setup_close_mp.run = setup_run_default

function setup_close_mp:followups() return close_mp_followups end

local setup_down_lk = Setup:new("setup_down_lk")
setup_down_lk.should_block_input = true

function setup_down_lk:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.yang.corner_offset_left + character_specific.yang.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.yang.corner_offset_right - character_specific.yang.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_down_lk:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_down_lk:get_dummy_offset(player) return framedata.get_contact_distance(player) end

function setup_down_lk:setup(player, context)
   return {
      {
         condition = function()
            return gamestate.is_ground_state(player.other, player.other.standing_state) and
                       is_idle_timing(player, #d_lk_input, true)
         end,
         action = function() queue_input_sequence_and_wait(player, d_lk_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            if player.has_just_connected then return true end
         end,
         action = nil
      }
   }
end

setup_down_lk.run = setup_run_default

function setup_down_lk:followups() return down_lk_followups end

local setup_close_mp_lp_tourou = Setup:new("setup_close_mp_lp_tourou")

setup_close_mp_lp_tourou.init = followup_close_mp_lp_tourou.init

function setup_close_mp_lp_tourou:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.yang.corner_offset_left + character_specific.yang.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.yang.corner_offset_right - character_specific.yang.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_close_mp_lp_tourou:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_close_mp_lp_tourou:get_dummy_offset(player) return framedata.get_contact_distance(player) end

function setup_close_mp_lp_tourou:setup(player, context)
   self:init()
   return {
      {
         condition = function()
            return gamestate.is_ground_state(player.other, player.other.standing_state) and
                       is_idle_timing(player, #cl_mp_input, true)
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mp_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            return player.has_just_connected
         end,
         action = function() queue_input_sequence_and_wait(player, lp_tourou_input) end
      }
   }
end

function setup_close_mp_lp_tourou:run(player, context)
   if all_commands_complete(player) then
      inputs.unblock_input(player.other.id)
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= lp_tourou_input_delay then
         queue_input_sequence_and_wait(player, lp_tourou_input)
         self.should_input = false
      end
      if player.has_just_connected then
         self.torou_hits = self.torou_hits + 1
         if self.torou_hits == 1 then
            if player.has_just_hit then
               self.should_input = true
               self.last_hit_frame = gamestate.frame_number
            elseif player.has_just_been_blocked or player.has_just_missed then
               return true, {score = 0}
            elseif player.other.has_just_parried then
               return true, {score = 2, should_end = true}
            end
         elseif self.torou_hits == 2 then
            self.should_input = true
            self.last_hit_frame = gamestate.frame_number
         else
            return true, {score = -3, should_end = true}
         end
      end
   end
   return handle_interruptions(player, context)
end

function setup_close_mp_lp_tourou:followups() return lp_tourou_followups end

local setup_down_mk_lp_tourou = Setup:new("setup_down_mk_lp_tourou")

setup_down_mk_lp_tourou.init = followup_down_mk_lp_tourou.init

function setup_down_mk_lp_tourou:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.yang.corner_offset_left + character_specific.yang.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.yang.corner_offset_right - character_specific.yang.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_down_mk_lp_tourou:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_down_mk_lp_tourou:get_dummy_offset(player) return framedata.get_contact_distance(player) end

function setup_down_mk_lp_tourou:setup(player, context)
   self:init()
   return {
      {
         condition = function()
            return gamestate.is_ground_state(player.other, player.other.standing_state) and
                       is_idle_timing(player, #d_mk_input, true)
         end,
         action = function() queue_input_sequence_and_wait(player, d_mk_input) end
      }, {
         condition = function()
            dummy_control.update_blocking(inputs.input, player.other, blocking_options)
            return player.has_just_connected
         end,
         action = function() queue_input_sequence_and_wait(player, lp_tourou_input) end
      }
   }
end

function setup_down_mk_lp_tourou:run(player, context)
   if all_commands_complete(player) then
      inputs.unblock_input(player.other.id)
      if self.should_input and gamestate.frame_number - self.last_hit_frame >= lp_tourou_input_delay then
         queue_input_sequence_and_wait(player, lp_tourou_input)
         self.should_input = false
      end
      if player.has_just_connected then
         self.torou_hits = self.torou_hits + 1
         if self.torou_hits == 1 then
            if player.has_just_hit then
               self.should_input = true
               self.last_hit_frame = gamestate.frame_number
            elseif player.has_just_been_blocked or player.has_just_missed then
               return true, {score = 0}
            elseif player.other.has_just_parried then
               return true, {score = 2, should_end = true}
            end
         elseif self.torou_hits == 2 then
            self.should_input = true
            self.last_hit_frame = gamestate.frame_number
         else
            return true, {score = -3, should_end = true}
         end
      end
   end
   return handle_interruptions(player, context)
end

function setup_down_mk_lp_tourou:followups() return lp_tourou_followups end

local setup_close_mk_jump_hk = Setup:new("setup_close_mk_jump_hk")
setup_close_mk_jump_hk.should_block_input = true

function setup_close_mk_jump_hk:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.yang.corner_offset_left + character_specific.yang.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.yang.corner_offset_right - character_specific.yang.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_close_mk_jump_hk:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_close_mk_jump_hk:get_dummy_offset(player) return framedata.get_contact_distance(player) end

function setup_close_mk_jump_hk:setup(player, context)
   self.hk_delay = jump_hk_delay[player.other.char_str] or jump_hk_delay.default

   local hk_timer = Delay:new(self.hk_delay)
   return {
      {
         condition = function()
            return gamestate.is_ground_state(player.other, player.other.standing_state) and
                       is_idle_timing(player, #cl_mk_input, true)
         end,
         action = function() queue_input_sequence_and_wait(player, cl_mk_input) end
      }, {
         condition = function() return player.has_just_connected end,
         action = function() queue_input_sequence_and_wait(player, sjump_forward_input) end
      }, {
         condition = function() return hk_timer:is_complete() end,
         action = function() queue_input_sequence_and_wait(player, hk_input) end
      }
   }
end

setup_close_mk_jump_hk.run = setup_run_default

function setup_close_mk_jump_hk:followups() return close_mk_jump_hk_followups end

local setup_wakeup = Setup:new("setup_wakeup")
setup_wakeup.is_wakeup = true

function setup_wakeup:get_hard_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific.yang.corner_offset_left + character_specific.yang.half_width +
          character_specific[other_char].half_width + 1,
      current_stage.right - character_specific.yang.corner_offset_right - character_specific.yang.half_width -
          character_specific[other_char].half_width - 1
   }
end

function setup_wakeup:get_soft_reset_range(player, context)
   local current_stage = stage_data.stages[context.stage]
   local other_char = player.other.char_str
   return {
      current_stage.left + character_specific[other_char].corner_offset_left,
      current_stage.right - character_specific[other_char].corner_offset_right
   }
end

function setup_wakeup:get_dummy_offset(player) return framedata.get_contact_distance(player) end

function setup_wakeup:setup(player, context)
   local setup = {{condition = nil, action = nil}}
   if player.other.is_waking_up or player.other.posture == 24 then return {condition = nil, action = nil} end
   return setup
end

setup_wakeup.run = setup_run_default

function setup_wakeup:followups() return wakeup_followups end

local setup_close_distance = Followup:new("setup_close_distance")

function setup_close_distance:init() self.should_dash = false end

function setup_close_distance:setup(player, context)
   self:init()
   local dash_duration = Delay:new(0)
   return {
      {
         condition = function() return is_idle_timing(player, #lk_kaihou_input) end,
         action = function()
            if (not player.other.is_being_thrown and player.other.is_airborne and player.other.character_state_byte == 1) or
                (player.other.is_waking_up and player.other.remaining_wakeup_time >= 40) then
               self.should_dash = true
               dash_duration:begin(#lk_kaihou_input + lk_kaihou_duration + 1 - 3)
            end
         end
      }, {
         condition = nil,
         action = function() if self.should_dash then queue_input_sequence_and_wait(player, lk_kaihou_input) end end
      }
   }
end

setup_close_distance.run = setup_run_default

raigeki_high_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_d_lk, weight = 1, default_weight = 1},
   {action = followup_close_mp_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1}
}
raigeki_mid_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_d_lk, weight = 1, default_weight = 1},
   {action = followup_close_mp_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1},
   {action = followup_walk_out, weight = 1, default_weight = 1}
}
raigeki_low_followups = {
   {action = followup_down_mk_lp_tourou, weight = 0.5, default_weight = 0.5},
   {action = followup_d_lk, weight = 0.5, default_weight = 0.5},
   {action = followup_uoh, weight = 0.5, default_weight = 0.5},
   {action = followup_walk_in, weight = 1, default_weight = 1}
}
raigeki_crossthrough_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_d_lk, weight = 1, default_weight = 1},
   {action = followup_down_mk_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1}
}
raigeki_crossup_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_d_lk, weight = 1, default_weight = 1},
   {action = followup_close_mp_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_down_mk_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1}
}
raigeki_whiff_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_close_mp_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_lk_ex_tourou, weight = 1, default_weight = 1},
   {action = followup_kara_throw, weight = 1, default_weight = 1}
}
jump_mp_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_d_lk, weight = 1, default_weight = 1},
   {action = followup_close_mp_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1},
   {action = followup_walk_out, weight = 1, default_weight = 1}
}

close_mk_jump_hk_followups = {
   {action = followup_close_mk_jump_hk, weight = 1, default_weight = 1},
   {action = followup_uoh, weight = 1, default_weight = 1}, {action = followup_zenpou, weight = 1, default_weight = 1}
}

close_mp_followups = {
   {action = followup_down_mk_ex_tourou, weight = 0.2, default_weight = 0.2},
   {action = followup_uoh, weight = 0.2, default_weight = 0.2},
   {action = followup_walk_in, weight = 1, default_weight = 1}
}
down_lk_followups = {
   {action = followup_down_mk_ex_tourou, weight = 0.2, default_weight = 0.2},
   {action = followup_uoh, weight = 0.2, default_weight = 0.2},
   {action = followup_walk_in, weight = 1, default_weight = 1}
}
lp_tourou_followups = {
   {action = followup_down_mk_lp_tourou, weight = 0.2, default_weight = 0.2},
   {action = followup_lk_ex_tourou, weight = 0.2, default_weight = 0.2},
   {action = followup_uoh, weight = 0.1, default_weight = 0.1},
   {action = followup_walk_in, weight = 1, default_weight = 1},
   {action = followup_forward_down, weight = 0.1, default_weight = 0.1},
   {action = followup_down_forward, weight = 0.1, default_weight = 0.1}
}

wakeup_followups = {
   {action = followup_close_mp, weight = 0.2, default_weight = 0.2},
   {action = followup_d_lk_d_lk, weight = 0.2, default_weight = 0.2},
   {action = followup_d_lk, weight = 0.2, default_weight = 0.2},
   {action = followup_close_mp_lp_tourou, weight = 0.2, default_weight = 0.2},
   {action = followup_down_mk_lp_tourou, weight = 0.2, default_weight = 0.2},
   {action = followup_kara_throw, weight = 0.2, default_weight = 0.2},
   {action = followup_zenpou, weight = 0.2, default_weight = 0.2},
   {action = followup_walk_out, weight = 1, default_weight = 1}
}

walk_in_followups = {
   {action = followup_close_mp, weight = 1, default_weight = 1},
   {action = followup_d_lk_d_lk, weight = 1, default_weight = 1},
   {action = followup_close_mk_jump_hk, weight = 1, default_weight = 1},
   {action = followup_close_mp_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_kara_throw, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1}
}
walk_out_followups = {
   {action = followup_down_mk_lp_tourou, weight = 1, default_weight = 1},
   {action = followup_uoh, weight = 1, default_weight = 1},
   {action = followup_kara_throw, weight = 1, default_weight = 1},
   {action = followup_zenpou, weight = 1, default_weight = 1}
}

local close_distance = {action = setup_close_distance, weight = 1, default_weight = 1}
local block = {action = followup_block, weight = 1, default_weight = 1}
local punish = {action = followup_punish, weight = 1, default_weight = 1}
local walk_in = {action = followup_walk_in, weight = 1, default_weight = 1}
local walk_out = {action = followup_walk_out, weight = 1, default_weight = 1}
lk_ex_tourou = {action = punish_lk_ex_tourou, weight = 1, default_weight = 1}
ex_tourou = {action = punish_ex_tourou, weight = 1, default_weight = 1}
cl_mk_jump_hk = {action = followup_close_mk_jump_hk, weight = 1, default_weight = 1}
d_mk_ex_tourou = {action = punish_d_mk_ex_tourou, weight = 1, default_weight = 1}

local wakeup = {action = setup_wakeup, default_weight = 1}

local setups = {
   {action = setup_raigeki_high, default_weight = 1}, {action = setup_raigeki_mid, default_weight = 1},
   {action = setup_raigeki_low, default_weight = 1}, {action = setup_raigeki_crossthrough, default_weight = 1},
   {action = setup_raigeki_crossup, default_weight = 1}, {action = setup_raigeki_whiff, default_weight = 1},
   {action = setup_jump_mp, default_weight = 1}, {action = setup_close_mp, default_weight = 1},
   {action = setup_down_lk, default_weight = 1}, {action = setup_close_mp_lp_tourou, default_weight = 1},
   {action = setup_down_mk_lp_tourou, default_weight = 1}, {action = setup_close_mk_jump_hk, default_weight = 1}, wakeup
}

local menu_setup_names = {}
for i, setup in ipairs(setups) do menu_setup_names[#menu_setup_names + 1] = "menu_" .. setup.action.name end

local followups = {
   {name = "raigeki_high_followups", list = raigeki_high_followups},
   {name = "raigeki_mid_followups", list = raigeki_mid_followups},
   {name = "raigeki_low_followups", list = raigeki_low_followups},
   {name = "raigeki_crossup_followups", list = raigeki_crossup_followups},
   {name = "raigeki_crossthrough_followups", list = raigeki_crossthrough_followups},
   {name = "raigeki_whiff_followups", list = raigeki_whiff_followups},
   {name = "jump_mp_followups", list = jump_mp_followups}, {name = "wakeup_followups", list = wakeup_followups},
   {name = "close_mp_followups", list = close_mp_followups}, {name = "down_lk_followups", list = down_lk_followups},
   {name = "close_mk_jump_hk_followups", list = close_mk_jump_hk_followups},
   {name = "lp_tourou_followups", list = lp_tourou_followups}, {name = "walk_in_followups", list = walk_in_followups},
   {name = "walk_out_followups", list = walk_out_followups}
}

local menu_followup_names = {}
for i, followup in ipairs(followups) do menu_followup_names[#menu_followup_names + 1] = "menu_" .. followup.name end

local menu_followup_followup_names = {}
for i, followup in ipairs(followups) do
   menu_followup_followup_names[i] = {}
   for j, followup_followup in ipairs(followup.list) do
      menu_followup_followup_names[i][#menu_followup_followup_names[i] + 1] = "menu_" .. followup_followup.action.name
   end
end

local function get_knockdown() return knockdown end

local function init_followups()
   local all_followups = {}
   local special_followups = {close_distance, block, punish, walk_in, walk_out}
   local function scan_followups(followup_list)
      for i, followup_tbl in ipairs(followup_list) do
         local followup = followup_tbl.action
         if not all_followups[followup] then
            followup:init()
            all_followups[followup] = true
            if followup:followups() then scan_followups(followup:followups()) end
         end
      end
   end
   scan_followups(special_followups)
   scan_followups(setups)
   scan_followups(punishes)
end

init_followups()

return {
   menu_setup_names = menu_setup_names,
   menu_followup_names = menu_followup_names,
   menu_followup_followup_names = menu_followup_followup_names,
   setups = setups,
   followups = followups,
   close_distance = close_distance,
   wakeup = wakeup,
   block = block,
   punish = punish,
   walk_in = walk_in,
   walk_out = walk_out,
   get_knockdown = get_knockdown,
   sa = 2,
   init = init
}
