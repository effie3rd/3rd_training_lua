local settings = require("src.settings")
local gamestate = require("src.gamestate")
local training = require("src.training")
local fd = require("src.modules.framedata")
local prediction = require("src.modules.prediction")
local frame_data, is_slow_jumper, is_really_slow_jumper = fd.frame_data, fd.is_slow_jumper, fd.is_really_slow_jumper
local memory_addresses = require("src.control.memory_addresses")
local move_data = require("src.modules.move_data")
local inputs = require("src.control.inputs")
local advanced_control = require("src.control.advanced_control")

local Delay = advanced_control.Delay


local frames_prediction = 15

local map_char_to_key = {
  urien_midscreen = {
    ken = "standard"
  }
}
local data = {
  urien_midscreen = {
    standard = {
      reset_offset_x = 300,
      setup = {},
      continuation = {
        d_LK = {},
        f_MK = {},
        u_HP = {}
      }
    }
  }
}

--elena q shoto remy ur gill mak chun 12 ne
local function urien_corner_mk_hk_hk_hk(player)
  local d_HP = {{"down","HP"}}
  local MK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "MK")
  local HK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "HK")
  local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
  local back_dash = {{"back"},{},{"back"}}
  local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
  local walk_back = {{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"}}

  local delay = Delay:new(88)
  local delay2 = Delay:new(10) --yang
  local delay2 = Delay:new(12) --yun

  local commands = {
    {
      condition = nil,
      action = function() advanced_control.queue_input_sequence_and_wait(player, d_HP) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #MK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, MK_tackle) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #HK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_tackle) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #HK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_tackle) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #HK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_tackle) end
    },
    {
      condition = function ()
        return player.has_just_hit
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, LP_aegis) end
    },
    {
      condition = function ()
        return delay:is_complete()
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_knee) end
    },
    {
      condition = function ()
        return delay2:delay_after_idle(player)
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_knee) end
    }
  }
  return commands
end

--ib very specific distance
local function urien_corner_mk_mk_Hk_hk(player)
  local d_HP = {{"down","HP"}}
  local MK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "MK")
  local HK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "HK")
  local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
  local back_dash = {{"back"},{},{"back"}}
  local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
  local walk_back = {{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"}}

  local delay = Delay:new(88)
  local delay2 = Delay:new(10) --yang
  local delay2 = Delay:new(12) --yun

  local commands = {
    {
      condition = nil,
      action = function() advanced_control.queue_input_sequence_and_wait(player, d_HP) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #MK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, MK_tackle) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #MK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, MK_tackle) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #HK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_tackle) end
    },
    {
      condition = function ()
        return prediction.get_frames_until_idle(player, player.animation, player.animation_frame, frames_prediction) <= #HK_tackle
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_tackle) end
    },
    {
      condition = function ()
        return player.has_just_hit
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, LP_aegis) end
    },
    {
      condition = function ()
        return delay:is_complete()
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_knee) end
    },
    {
      condition = function ()
        return delay2:delay_after_idle(player)
      end,
      action = function() advanced_control.queue_input_sequence_and_wait(player, HK_knee) end
    }
  }
  return commands
end



--q corner x 726 for urien
local function urien_tackles(player)
  local d_HP = {{"down","HP"}}
  local LK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "LK")

  local MK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "MK")
  local HK_tackle = move_data.get_move_inputs_by_name("urien", "chariot_tackle", "HK")
  local LP_aegis = move_data.get_move_inputs_by_name("urien", "aegis_reflector", "LP")
  local back_dash = {{"back"},{},{"back"}}
  local LK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "LK")

  local MK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "MK")

  local HK_knee = move_data.get_move_inputs_by_name("urien", "violence_kneedrop", "HK")
  local walk_back = {{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"},{"back"}}
  local walk_forward = {{"forward"},{"forward"},{"forward"},{"forward"},{"forward"},{"forward"},{"forward"},{"forward"},{"forward"}}
  local crouch = {{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"},{"down"}}
  local delay = Delay:new(66)
  local tackle_delay = Delay:new(10)
  local delay2 = Delay:new(10) --yang
  local delay2 = Delay:new(11) --yun

  local commands = {
    {
      condition = nil,
      action = function() queue_input_sequence_and_wait(player, d_HP) end
    },
    {
      condition = function ()
        return is_idle_timing(player, #MK_tackle)
      end,
      action = function() queue_input_sequence_and_wait(player, MK_tackle) end
    },
    {
      condition = function ()
        return is_idle_timing(player, #MK_tackle)
      end,
      action = function() queue_input_sequence_and_wait(player, MK_tackle) end
    },
    {
      condition = function ()
        return is_idle_timing(player, #HK_tackle)
      end,
      action = function() queue_input_sequence_and_wait(player, MK_tackle) end
    },
    {
      condition = function ()
        return is_idle_timing(player, #MK_tackle)
      end,
      action = function() queue_input_sequence_and_wait(player, HK_tackle) end
    },
    {
      condition = function ()
        return tackle_delay:delay_after_hit(player)
      end,
      action = function() queue_input_sequence_and_wait(player, LP_aegis) end
    },
    {
      condition = function ()
        return delay:is_complete()
      end,
      action = function() queue_input_sequence_and_wait(player, MK_knee) end
    },
    {
      condition = function ()
        return is_idle_timing(player, 1)
      end,
      action = function() queue_input_sequence_and_wait(player, walk_forward, true) end
    },
    {
      condition = function ()
        if not player.pending_input_sequence then
          return true
        elseif #player.pending_input_sequence <= 1 then
          return true
        end
        return false
      end,
      action = function() inputs.queue_input_sequence(player, crouch, 0, true) end
    },
    {
      condition = function ()
        return delay2:delay_after_idle(player)
      end,
      action = function() queue_input_sequence_and_wait(player, HK_knee) end
    }
  }
  return commands
end