local gamestate = require("src.gamestate")
local fd = require("src.data.framedata")
local memory_addresses = require("src.control.memory_addresses")
local tools = require("src.tools")

local Pools = tools.Pools
local is_slow_jumper, is_really_slow_jumper = fd.is_slow_jumper, fd.is_really_slow_jumper

local input_object
local previous_input = nil
local block_input_settings = { {}, {} }

local input_history_length = 20

local DIR = {
   NEUTRAL = 5,
   DOWN_BACK = 1,
   DOWN = 2,
   DOWN_FORWARD = 3,
   BACK = 4,
   FORWARD = 6,
   UP_BACK = 7,
   UP = 8,
   UP_FORWARD = 9,
   ANY = 10,
   ANY_DOWN = 11,
   ANY_UP = 12,
   ANY_BACK = 13,
   ANY_FORWARD = 14,
   ANY_STANDING = 15,
   FORWARD_BACK = 16,
}
local BTN = {
   LP = 1,
   MP = 2,
   HP = 3,
   LK = 4,
   MK = 5,
   HK = 6,
   COIN = 7,
   START = 8,
   NONE = 9,
   P = 10,
   K = 11,
   PP = 12,
   KK = 13,
   PPP = 14,
   KKK = 15,
   ANY = 16,
   ANY_PK = 17,
}

local NO_BUTTONS = { false, false, false, false, false, false }
local MAX_SEARCH_DEPTH = 40

local function flip_direction(direction)
   if direction == DIR.BACK then
      return DIR.FORWARD
   elseif direction == DIR.DOWN_BACK then
      return DIR.DOWN_FORWARD
   elseif direction == DIR.UP_BACK then
      return DIR.UP_FORWARD
   elseif direction == DIR.FORWARD then
      return DIR.BACK
   elseif direction == DIR.DOWN_FORWARD then
      return DIR.DOWN_BACK
   elseif direction == DIR.UP_FORWARD then
      return DIR.UP_BACK
   end
   return direction
end

local function clear_input_history()
   for _, player in ipairs(gamestate.player_objects) do
      tools.clear_table(player.input_history)
   end
end

local function update_input_history(input, player)
   input = input or input_object
   local direction = DIR.NEUTRAL
   if input[player.prefix .. " Left"] then
      if input[player.prefix .. " Up"] then
         direction = DIR.UP_BACK
      elseif input[player.prefix .. " Down"] then
         direction = DIR.DOWN_BACK
      else
         direction = DIR.BACK
      end
      if input[player.prefix .. " Right"] then
         if player.side == 1 then
            direction = flip_direction(direction)
         end
      end
   elseif input[player.prefix .. " Right"] then
      if input[player.prefix .. " Up"] then
         direction = DIR.UP_FORWARD
      elseif input[player.prefix .. " Down"] then
         direction = DIR.DOWN_FORWARD
      else
         direction = DIR.FORWARD
      end
   elseif input[player.prefix .. " Up"] then
      direction = DIR.UP
   elseif input[player.prefix .. " Down"] then
      direction = DIR.DOWN
   end

   local direction_raw = direction

   if player.side == 2 then
      direction = flip_direction(direction)
   end

   local buttons = Pools.small:alloc()
   buttons[1] = input[player.prefix .. " Weak Punch"]
   buttons[2] = input[player.prefix .. " Medium Punch"]
   buttons[3] = input[player.prefix .. " Strong Punch"]
   buttons[4] = input[player.prefix .. " Weak Kick"]
   buttons[5] = input[player.prefix .. " Medium Kick"]
   buttons[6] = input[player.prefix .. " Strong Kick"]

   local last_input = player.input_history[#player.input_history]
   if last_input and last_input.direction_raw == direction_raw and tools.deep_equal(last_input.buttons, buttons) then
      last_input.duration = last_input.duration + 1
   else
      local pressed
      if last_input then
         pressed = copytable(NO_BUTTONS)
         for i = 1, #last_input.buttons do
            if buttons[i] and not last_input.buttons[i] then
               pressed[i] = true
            end
         end
      else
         pressed = copytable(buttons)
      end
      player.input_history[#player.input_history + 1] = {
         start_frame = gamestate.frame_number,
         duration = 1,
         direction = direction,
         direction_raw = direction_raw,
         buttons = copytable(buttons),
         pressed = pressed,
      }
   end
   if #player.input_history > input_history_length then
      table.remove(player.input_history, 1)
   end
end

local OPTION_SELECT_INPUTS = {
   GUARD_JUMP = {
      name = "GUARD_JUMP",
      inputs = {
         { direction = DIR.DOWN_BACK, duration = { min = 4, max = 30 } },
         { direction = DIR.DOWN_BACK, invert_dir = true, duration = { min = nil, max = 6 } },
         { direction = DIR.ANY_UP, buttons = BTN.NONE, duration = { min = 2, max = 2 } },
         { direction = DIR.ANY_UP, buttons = BTN.NONE, duration = { min = 1, max = 1 } },
         { direction = DIR.ANY, buttons = BTN.NONE, duration = { min = 4, max = nil } },
      },
      duration = 50,
   },
   PARRY_LOW_JUMP = {
      name = "PARRY_LOW_JUMP",
      inputs = {
         { direction = DIR.NEUTRAL, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, duration = { min = 2, max = 10 } },
         { direction = DIR.ANY_UP, buttons = BTN.NONE, duration = { min = 2, max = 2 } },
         { direction = DIR.ANY_UP, buttons = BTN.NONE, duration = { min = 1, max = nil } },
      },
      duration = 50,
   },
   FORWARD_DOWN = {
      name = "FORWARD_DOWN",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 20 } },
         { direction = DIR.DOWN, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 10 } },
      },
      duration = 50,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration
               + matched_inputs[3].matched_duration
               + matched_inputs[4].matched_duration
               + matched_inputs[5].matched_duration
            >= 12
      end,
   },
   DOWN_FORWARD = {
      name = "DOWN_FORWARD",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 20 } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 10 } },
      },
      duration = 50,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration
               + matched_inputs[3].matched_duration
               + matched_inputs[4].matched_duration
               + matched_inputs[5].matched_duration
            >= 12
      end,
   },
   PARRY_DASH = {
      name = "PARRY_DASH",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 10 } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = nil } },
      },
      duration = 20,
      validation = function(matched_inputs)
         local duration = matched_inputs[2].matched_duration + matched_inputs[3].matched_duration
         return duration >= 10 and duration <= 12
      end,
   },
   PARRY_HIGH_THROW = {
      name = "PARRY_HIGH_THROW",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = nil, max = 10 } },
         { direction = DIR.ANY, buttons = BTN.ANY, duration = { min = nil, max = 1 } },
         {
            direction = DIR.ANY_STANDING,
            buttons = { BTN.LP, BTN.LK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration + matched_inputs[3].matched_duration >= 4
      end,
   },
   PARRY_LOW_THROW = {
      name = "PARRY_LOW_THROW",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = nil, max = 10 } },
         { direction = DIR.ANY, buttons = BTN.ANY, duration = { min = nil, max = 1 } },
         {
            direction = DIR.ANY_STANDING,
            buttons = { BTN.LP, BTN.LK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration + matched_inputs[3].matched_duration >= 4
      end,
   },
   CROUCH_TECH = {
      name = "CROUCH_TECH",
      inputs = {
         {
            direction = DIR.DOWN_BACK,
            buttons = { BTN.LP, BTN.LK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = 1 },
         },
      },
      duration = 20,
   },
   STAND_TECH = {
      name = "STAND_TECH",
      inputs = {
         {
            direction = DIR.ANY_STANDING,
            buttons = { BTN.LP, BTN.LK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = 1 },
         },
      },
      duration = 20,
   },
   LATE_TECH = {
      name = "LATE_TECH",
      inputs = {
         { direction = DIR.DOWN_BACK, duration = { min = 1, max = nil } },
         { direction = DIR.BACK, duration = { min = nil, max = 16 } },
         {
            direction = DIR.ANY,
            buttons = { BTN.LP, BTN.LK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = 1 },
         },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[3].inputs[1].direction == DIR.BACK or matched_inputs[2].matched_duration > 0
      end,
   },
   HIGH_JUMP_CANCEL = {
      name = "HIGH_JUMP_CANCEL",
      inputs = {
         { direction = DIR.ANY_DOWN, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.ANY_DOWN, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD_BACK, buttons = BTN.NONE, duration = { min = nil, max = 7 } },
         { direction = DIR.ANY_UP, buttons = BTN.ANY_PK, duration = { min = 1, max = nil } },
      },
      duration = 20,
   },
}

local PARRY_INPUTS = {
   PARRY_HIGH = {
      name = "PARRY_HIGH",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration + matched_inputs[3].matched_duration >= 6
      end,
   },
   PARRY_LOW = {
      name = "PARRY_LOW",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration + matched_inputs[3].matched_duration >= 6
      end,
   },
   RED_PARRY_HIGH = {
      name = "RED_PARRY_HIGH",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = nil, max = 6 } },
         { direction = DIR.NEUTRAL, invert_dir = true, buttons = BTN.NONE, duration = { min = nil, max = 6 } },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration + matched_inputs[3].matched_duration >= 4
            and matched_inputs[2].matched_duration
                  + matched_inputs[3].matched_duration
                  + matched_inputs[4].matched_duration
               >= 7
      end,
   },
   RED_PARRY_LOW = {
      name = "RED_PARRY_LOW",
      inputs = {
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = nil, max = 6 } },
         { direction = DIR.NEUTRAL, invert_dir = true, buttons = BTN.NONE, duration = { min = nil, max = 6 } },
      },
      duration = 20,
      validation = function(matched_inputs)
         return matched_inputs[2].matched_duration + matched_inputs[3].matched_duration >= 4
            and matched_inputs[2].matched_duration
                  + matched_inputs[3].matched_duration
                  + matched_inputs[4].matched_duration
               >= 7
      end,
   },
}

local MOVE_INPUTS = {
   SGS = {
      name = "SGS",
      inputs = {
         { direction = DIR.ANY, buttons = BTN.LP, is_press = true, duration = { min = 1, max = nil } },
         { direction = DIR.ANY, buttons = BTN.LP, is_press = true, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.ANY, buttons = BTN.LK, is_press = true, duration = { min = 1, max = nil } },
         { direction = DIR.ANY, buttons = BTN.HP, is_press = true, duration = { min = 1, max = nil } },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   ["720"] = {
      name = "720",
      inputs = {
         { direction = { DIR.BACK, DIR.FORWARD, DIR.DOWN, DIR.UP }, buffer = 20, duration = { min = 1, max = nil } },
         {
            direction = { DIR.BACK, DIR.FORWARD, DIR.DOWN, DIR.UP },
            num_match_dir = 3,
            buffer = 20,
            duration = { min = 1, max = nil },
         },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_pass_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 30,
   },
   KKZ = {
      name = "KKZ",
      inputs = {
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.NEUTRAL, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.NEUTRAL, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.PPP,
            is_press = true,
            should_pass_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
   },
   DQCF = {
      name = "DQCF",
      inputs = {
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_FORWARD, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   ["360"] = {
      name = "360",
      inputs = {
         { direction = { DIR.BACK, DIR.FORWARD, DIR.DOWN, DIR.UP }, buffer = 20, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 15,
   },
   VCHARGE = {
      name = "VCHARGE",
      inputs = {
         { direction = DIR.DOWN, duration = { min = 10, max = nil } },
         { direction = DIR.ANY_UP, buttons = BTN.ANY, is_press = true, duration = { min = 1, max = nil } },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   HCHARGE = {
      name = "HCHARGE",
      inputs = {
         { direction = DIR.ANY_BACK, duration = { min = 10, max = nil } },
         { direction = DIR.FORWARD, buttons = BTN.ANY, is_press = true, duration = { min = 1, max = nil } },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   HCF = {
      name = "HCF",
      inputs = {
         { direction = DIR.BACK, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_BACK, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   HCB = {
      name = "HCB",
      inputs = {
         { direction = DIR.FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_BACK, duration = { min = 1, max = nil } },
         { direction = DIR.BACK, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   SRK = {
      name = "SRK",
      inputs = {
         { direction = DIR.FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_FORWARD, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   QCF = {
      name = "QCF",
      inputs = {
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_FORWARD, duration = { min = 1, max = nil } },
         { direction = DIR.FORWARD, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   SRKB = {
      name = "SRKB",
      inputs = {
         { direction = DIR.BACK, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_BACK, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   QCB = {
      name = "QCB",
      inputs = {
         { direction = DIR.DOWN, duration = { min = 1, max = nil } },
         { direction = DIR.DOWN_BACK, duration = { min = 1, max = nil } },
         { direction = DIR.BACK, duration = { min = 1, max = nil } },
         {
            direction = DIR.ANY,
            buttons = BTN.ANY,
            is_press = true,
            should_reuse_input = true,
            duration = { min = 1, max = nil },
         },
      },
      duration = 20,
      options = { allow_intermediate_inputs = true },
   },
   THROW = {
      name = "THROW",
      inputs = {
         {
            direction = DIR.ANY,
            buttons = { BTN.LP, BTN.LK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = nil },
         },
      },
      duration = 5,
   },
   UOH = {
      name = "UOH",
      inputs = {
         {
            direction = DIR.NEUTRAL,
            buttons = { BTN.MP, BTN.MK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = nil },
         },
      },
      duration = 5,
   },
   PA = {
      name = "PA",
      inputs = {
         {
            direction = DIR.NEUTRAL,
            buttons = { BTN.HP, BTN.HK },
            is_press = true,
            buffer = 1,
            duration = { min = 1, max = nil },
         },
      },
      duration = 5,
   },
   DASH_FORWARD = {
      name = "DASH_FORWARD",
      inputs = {
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 10 } },
         { direction = DIR.FORWARD, buttons = BTN.NONE, duration = { min = 1, max = nil } },
      },
      duration = 20,
   },
   DASH_BACK = {
      name = "DASH_BACK",
      inputs = {
         { direction = DIR.BACK, buttons = BTN.NONE, duration = { min = 1, max = 6 } },
         { direction = DIR.NEUTRAL, buttons = BTN.NONE, duration = { min = 1, max = 10 } },
         { direction = DIR.BACK, buttons = BTN.NONE, duration = { min = 1, max = nil } },
      },
      duration = 20,
   },
   BLOCK_HIGH = {
      name = "BLOCK_HIGH",
      inputs = { { direction = DIR.BACK, buttons = BTN.NONE, duration = { min = 2, max = nil } } },
      duration = 5,
   },
   BLOCK_LOW = {
      name = "BLOCK_LOW",
      inputs = { { direction = DIR.DOWN_BACK, buttons = BTN.NONE, duration = { min = 2, max = nil } } },
      duration = 5,
   },
}

local MOTION_PRIORITY = {
   MOVE_INPUTS.SGS,
   MOVE_INPUTS["720"],
   MOVE_INPUTS.KKZ,
   MOVE_INPUTS.DQCF,
   MOVE_INPUTS["360"],
   MOVE_INPUTS.VCHARGE,
   MOVE_INPUTS.HCHARGE,
   OPTION_SELECT_INPUTS.HIGH_JUMP_CANCEL,
   MOVE_INPUTS.HCF,
   MOVE_INPUTS.HCB,
   MOVE_INPUTS.SRK,
   MOVE_INPUTS.QCF,
   MOVE_INPUTS.SRKB,
   MOVE_INPUTS.QCB,
   MOVE_INPUTS.UOH,
   MOVE_INPUTS.PA,
   OPTION_SELECT_INPUTS.PARRY_DASH,
   MOVE_INPUTS.DASH_FORWARD,
   MOVE_INPUTS.DASH_BACK,
   OPTION_SELECT_INPUTS.GUARD_JUMP,
   OPTION_SELECT_INPUTS.PARRY_LOW_JUMP,
   OPTION_SELECT_INPUTS.FORWARD_DOWN,
   OPTION_SELECT_INPUTS.DOWN_FORWARD,
   OPTION_SELECT_INPUTS.PARRY_HIGH_THROW,
   OPTION_SELECT_INPUTS.PARRY_LOW_THROW,
   OPTION_SELECT_INPUTS.LATE_TECH,
   OPTION_SELECT_INPUTS.STAND_TECH,
   OPTION_SELECT_INPUTS.CROUCH_TECH,
   MOVE_INPUTS.THROW,
   PARRY_INPUTS.PARRY_HIGH,
   PARRY_INPUTS.PARRY_LOW,
   PARRY_INPUTS.RED_PARRY_HIGH,
   PARRY_INPUTS.RED_PARRY_LOW,
   MOVE_INPUTS.BLOCK_HIGH,
   MOVE_INPUTS.BLOCK_LOW,
}

local OPTION_PARRY_INPUTS = {
   OPTION_SELECT_INPUTS.PARRY_DASH,
   OPTION_SELECT_INPUTS.PARRY_LOW_JUMP,
   OPTION_SELECT_INPUTS.FORWARD_DOWN,
   OPTION_SELECT_INPUTS.DOWN_FORWARD,
   OPTION_SELECT_INPUTS.PARRY_HIGH_THROW,
   OPTION_SELECT_INPUTS.PARRY_LOW_THROW,
}

local AFTER_HIGH_PARRY = {
   OPTION_SELECT_INPUTS.FORWARD_DOWN,
   OPTION_SELECT_INPUTS.PARRY_DASH,
   OPTION_SELECT_INPUTS.PARRY_HIGH_THROW,
}

local AFTER_LOW_PARRY = {
   MOVE_INPUTS.SGS,
   OPTION_SELECT_INPUTS.DOWN_FORWARD,
   OPTION_SELECT_INPUTS.PARRY_LOW_JUMP,
   OPTION_SELECT_INPUTS.PARRY_LOW_THROW,
}

local MOTIONS = {}
for id, m_inp in ipairs(MOTION_PRIORITY) do
   MOTIONS[m_inp.name] = id
   m_inp.id = id
end

local function match_motion_input(motion_input, player_input)
   local is_directions_matching = false

   if type(motion_input.direction) == "table" then
      local num_to_match = motion_input.num_match_dir or #motion_input.direction
      local num_matched = 0
      local player_direction = player_input.direction
      if not (type(player_input.direction) == "table") then
         player_direction = Pools.temp:alloc()
         player_direction[player_input.direction] = true
      end
      for _, dir in ipairs(motion_input.direction) do
         if player_direction[dir] then
            num_matched = num_matched + 1
         end
      end
      is_directions_matching = num_matched >= num_to_match
      if not (type(player_input.direction) == "table") then
         Pools.temp:free(player_direction)
      end
   else
      if motion_input.direction <= 9 then
         is_directions_matching = motion_input.direction == player_input.direction
      elseif motion_input.direction == DIR.ANY then
         is_directions_matching = true
      elseif motion_input.direction == DIR.ANY_DOWN then
         is_directions_matching = player_input.direction == DIR.DOWN
            or player_input.direction == DIR.DOWN_BACK
            or player_input.direction == DIR.DOWN_FORWARD
      elseif motion_input.direction == DIR.ANY_UP then
         is_directions_matching = player_input.direction == DIR.UP
            or player_input.direction == DIR.UP_BACK
            or player_input.direction == DIR.UP_FORWARD
      elseif motion_input.direction == DIR.ANY_BACK then
         is_directions_matching = player_input.direction == DIR.BACK
            or player_input.direction == DIR.DOWN_BACK
            or player_input.direction == DIR.UP_BACK
      elseif motion_input.direction == DIR.ANY_FORWARD then
         is_directions_matching = player_input.direction == DIR.FORWARD
            or player_input.direction == DIR.DOWN_FORWARD
            or player_input.direction == DIR.UP_FORWARD
      elseif motion_input.direction == DIR.ANY_STANDING then
         is_directions_matching = player_input.direction == DIR.NEUTRAL
            or player_input.direction == DIR.BACK
            or player_input.direction == DIR.FORWARD
      elseif motion_input.direction == DIR.FORWARD_BACK then
         is_directions_matching = player_input.direction == DIR.BACK or player_input.direction == DIR.FORWARD
      end
   end

   if motion_input.invert_dir then
      is_directions_matching = not is_directions_matching
   end
   if not is_directions_matching then
      return false
   end
   if not motion_input.buttons then
      return is_directions_matching
   end

   local is_buttons_matching = false
   local player_buttons

   if motion_input.is_press then
      player_buttons = player_input.pressed
   else
      player_buttons = player_input.down
   end

   if type(motion_input.buttons) == "table" then
      is_buttons_matching = true
      for _, button in ipairs(motion_input.buttons) do
         if not player_buttons[button] then
            is_buttons_matching = false
            break
         end
      end
   else
      if motion_input.buttons == BTN.NONE then
         is_buttons_matching = true
         for _, button in ipairs(player_buttons) do
            if button then
               is_buttons_matching = false
               break
            end
         end
      elseif motion_input.buttons == BTN.LP then
         is_buttons_matching = player_buttons[1]
      elseif motion_input.buttons == BTN.MP then
         is_buttons_matching = player_buttons[2]
      elseif motion_input.buttons == BTN.HP then
         is_buttons_matching = player_buttons[3]
      elseif motion_input.buttons == BTN.LK then
         is_buttons_matching = player_buttons[4]
      elseif motion_input.buttons == BTN.MK then
         is_buttons_matching = player_buttons[5]
      elseif motion_input.buttons == BTN.HK then
         is_buttons_matching = player_buttons[6]
      elseif motion_input.buttons == BTN.P then
         for i = 1, 3 do
            if player_buttons[i] then
               is_buttons_matching = true
               break
            end
         end
      elseif motion_input.buttons == BTN.K then
         for i = 4, 6 do
            if player_buttons[i] then
               is_buttons_matching = true
               break
            end
         end
      elseif motion_input.buttons == BTN.PP then
         local p = 0
         for i = 1, 3 do
            if player_buttons[i] then
               p = p + 1
               if p >= 2 then
                  is_buttons_matching = true
                  break
               end
            end
         end
      elseif motion_input.buttons == BTN.KK then
         local k = 0
         for i = 4, 6 do
            if player_buttons[i] then
               k = k + 1
               if k >= 2 then
                  is_buttons_matching = true
                  break
               end
            end
         end
      elseif motion_input.buttons == BTN.PPP then
         local p = 0
         for i = 1, 3 do
            if player_buttons[i] then
               p = p + 1
               if p >= 3 then
                  is_buttons_matching = true
                  break
               end
            end
         end
      elseif motion_input.buttons == BTN.KKK then
         local k = 0
         for i = 4, 6 do
            if player_buttons[i] then
               k = k + 1
               if k >= 3 then
                  is_buttons_matching = true
                  break
               end
            end
         end
      elseif motion_input.buttons == BTN.ANY_PK then
         for i = 1, 6 do
            if player_buttons[i] then
               is_buttons_matching = true
               break
            end
         end
      elseif motion_input.buttons == BTN.LP_LK then
         is_buttons_matching = player_buttons[1] and player_buttons[4]
      elseif motion_input.buttons == BTN.MP_MK then
         is_buttons_matching = player_buttons[2] and player_buttons[5]
      elseif motion_input.buttons == BTN.HP_HK then
         is_buttons_matching = player_buttons[3] and player_buttons[6]
      elseif motion_input.buttons == BTN.ANY then
         for _, button in ipairs(player_buttons) do
            if button then
               is_buttons_matching = true
               break
            end
         end
      elseif motion_input.buttons == BTN.NONE then
         local k = 0
         for _, button in ipairs(player_buttons) do
            if not button then
               k = k + 1
            else
               break
            end
         end
         is_buttons_matching = k == #player_buttons
      end
   end

   if motion_input.invert_buttons then
      is_buttons_matching = not is_buttons_matching
   end
   return is_directions_matching and is_buttons_matching
end

local function update_player_input(input_data, index)
   local player_history_index = index or input_data.player_history_index
   local player_history = input_data.player.input_history[player_history_index]
   if not player_history then
      return
   end
   local duration = player_history.duration
   if player_history.start_frame < input_data.start_frame then
      if player_history.start_frame + player_history.duration - 1 < input_data.start_frame then
         return
      end
      duration = duration - (input_data.start_frame - player_history.start_frame)
   end
   local pressed = NO_BUTTONS
   if duration == player_history.duration then
      pressed = player_history.pressed
   end
   input_data.player_input.direction = player_history.direction
   input_data.player_input.direction_raw = player_history.direction_raw
   input_data.player_input.down = player_history.buttons
   input_data.player_input.pressed = pressed
   input_data.player_input.duration = duration
   input_data.player_input.start_frame = player_history.start_frame
   return true
end

local function next_player_input(input_data)
   if input_data.player_input.duration <= 0 then
      input_data.player_history_index = input_data.player_history_index - 1
      return update_player_input(input_data)
   else
      local max_duration = input_data.player.input_history[input_data.player_history_index].duration
      if input_data.player_input.duration < max_duration then
         input_data.player_input.pressed = NO_BUTTONS
      end
      return true
   end
end

local function match_motion(motion, input_data)
   local success = false
   local should_check_next_player_input = false
   local should_skip = false
   local matched_intermediate_duration = 0
   input_data.matching_inputs = Pools.temp:alloc()
   input_data.current_matching_inputs = Pools.temp:alloc()
   while input_data.motion_input_index >= 1 do
      local is_matching_input = match_motion_input(input_data.motion_input, input_data.player_input)
      if not is_matching_input and input_data.motion_input.buffer then
         local has_next_input
         local matched_buffer = Pools.temp:alloc()
         local buffered_dir = input_data.player_input.direction
         local buffered_dir_raw = input_data.player_input.direction_raw
         if type(input_data.motion_input.direction) == "table" then
            buffered_dir = Pools.temp:alloc()
            buffered_dir_raw = Pools.temp:alloc()
         end
         local buffered_down = Pools.temp:alloc()
         local buffered_pressed = Pools.temp:alloc()
         tools.copy_fields(buffered_down, input_data.player_input.down)
         tools.copy_fields(buffered_pressed, input_data.player_input.pressed)
         local buffered_player_input = Pools.temp:alloc()
         for i = input_data.motion_input.buffer + 1, 1, -1 do
            if type(input_data.motion_input.direction) == "table" then
               buffered_dir[input_data.player_input.direction] = true
               buffered_dir_raw[input_data.player_input.direction] = true
            end
            for j, button in ipairs(buffered_down) do
               buffered_down[j] = buffered_down[j] or input_data.player_input.down[j]
               buffered_pressed[j] = buffered_pressed[j] or input_data.player_input.pressed[j]
            end
            matched_buffer[#matched_buffer + 1] = input_data.player.input_history[input_data.player_history_index]
            buffered_player_input.direction = buffered_dir
            buffered_player_input.direction_raw = buffered_dir_raw
            buffered_player_input.down = buffered_down
            buffered_player_input.pressed = buffered_pressed
            buffered_player_input.duration = input_data.player_input.duration
            is_matching_input = match_motion_input(input_data.motion_input, buffered_player_input)
            if is_matching_input then
               tools.copy_fields(input_data.current_matching_inputs, matched_buffer)
               input_data.matched_duration = input_data.motion_input.buffer + 1
               input_data.is_min_matched = true
               input_data.is_max_matched = true
            end
            input_data.player_input.duration = input_data.player_input.duration - 1
            has_next_input = next_player_input(input_data)
            if is_matching_input or not has_next_input then
               break
            end
         end
         Pools.temp:free(matched_buffer)
         Pools.temp:free(buffered_player_input)
         Pools.temp:free(buffered_down)
         Pools.temp:free(buffered_pressed)
         if type(input_data.motion_input.direction) == "table" then
            Pools.temp:free(buffered_dir)
            Pools.temp:free(buffered_dir_raw)
         end

         if not has_next_input then
            break
         end
      elseif is_matching_input then
         local current_matched_duration = 0
         if input_data.motion_input.duration.min then
            current_matched_duration = math.min(
               input_data.player_input.duration,
               input_data.motion_input.duration.min - input_data.matched_duration
            )
         end
         if input_data.motion_input.duration.max then
            current_matched_duration = math.min(
               input_data.player_input.duration,
               input_data.motion_input.duration.max - input_data.matched_duration
            )
         else
            -- has min
            input_data.matched_duration = input_data.player_input.duration
            should_check_next_player_input = true
         end
         input_data.player_input.duration = input_data.player_input.duration - current_matched_duration
         input_data.matched_duration = input_data.matched_duration + current_matched_duration
         if input_data.player_input.duration <= 0 then
            should_check_next_player_input = true
         else
            input_data.player_input.pressed = NO_BUTTONS
            should_skip = true
         end

         input_data.current_matching_inputs[#input_data.current_matching_inputs + 1] =
            input_data.player.input_history[input_data.player_history_index]

         if
            not input_data.motion_input.duration.min
            or input_data.matched_duration >= input_data.motion_input.duration.min
         then
            input_data.is_min_matched = true
         end
         if not input_data.motion_input.duration.max then
            input_data.is_max_matched = true
            if input_data.is_min_matched then
               should_skip = false
               should_check_next_player_input = true
            end
         elseif input_data.matched_duration >= input_data.motion_input.duration.max then
            input_data.is_max_matched = true
         end
      elseif input_data.matched_duration > 0 then
         input_data.is_max_matched = true
      elseif not input_data.motion_input.duration.min then
         input_data.is_min_matched = true
         input_data.is_max_matched = true
         should_skip = true
      elseif
         input_data.motion_input_index < #motion.inputs
         and motion.options
         and motion.options.allow_intermediate_inputs
      then
         matched_intermediate_duration = matched_intermediate_duration + input_data.player_input.duration
         if matched_intermediate_duration <= 5 then
            should_check_next_player_input = true
         end
      else
         break
      end

      if input_data.motion_input_index == 1 and input_data.is_min_matched then
         input_data.is_max_matched = true
      end

      -- if motion.name == "GUARD_JUMP" then
      --    print(
      --       string.format(
      --          "%s: m:%d dir:%d d:%d md:%d %s %s %s %s %s %d %d",
      --          motion.name,
      --          input_data.motion_input_index,
      --          input_data.player_input.direction,
      --          input_data.player_input.duration,
      --          input_data.matched_duration,
      --          tostring(is_matching_input),
      --          tostring(input_data.is_min_matched),
      --          tostring(input_data.is_max_matched),
      --          tostring(should_check_next_player_input),
      --          tostring(should_skip),
      --          input_data.start_frame,
      --          input_data.player_input.start_frame
      --       )
      --    )
      -- end

      local should_check_next_motion_input = input_data.is_min_matched and input_data.is_max_matched
      if should_check_next_motion_input then
         local match_data = Pools.temp:alloc()
         match_data.matched_duration = input_data.matched_duration
         match_data.inputs = Pools.temp:alloc()
         tools.copy_fields(match_data.inputs, input_data.current_matching_inputs)
         table.insert(input_data.matching_inputs, 1, match_data)
         if input_data.motion_input_index == 1 then
            success = true
            break
         end
         if motion.should_pass_input then
            should_check_next_player_input = false
         end
         input_data.motion_input_index = input_data.motion_input_index - 1
         input_data.motion_input = motion.inputs[input_data.motion_input_index]
         input_data.is_min_matched, input_data.is_max_matched = false, false
         input_data.matched_duration = 0
         matched_intermediate_duration = 0
         tools.clear_table(input_data.current_matching_inputs)
      end
      if should_skip then
         should_check_next_player_input = false
      end
      if should_check_next_player_input then
         input_data.player_history_index = input_data.player_history_index - 1
         local has_next_input = update_player_input(input_data)
         if not has_next_input then
            break
         end
      end
      if not (should_check_next_player_input or should_skip or should_check_next_motion_input) then
         break
      end
      should_check_next_player_input = false
      should_skip = false
   end

   local result_matching_inputs = tools.tempcopy(input_data.matching_inputs)
   for _, match_data in pairs(input_data.matching_inputs) do
      Pools.temp:free(match_data.inputs)
      Pools.temp:free(match_data)
   end
   Pools.temp:free(input_data.matching_inputs)
   Pools.temp:free(input_data.current_matching_inputs)

   return success, result_matching_inputs
end


local function update_match_frame(matched_motion, motion_list)
   for id, motion_data in ipairs(motion_list) do
      if id >= matched_motion.id or #motion_data.matching_inputs < #matched_motion.inputs then
         motion_data.last_match_frame = gamestate.frame_number
      end
   end
end

local function match_motion_list(player, motion_list)
   local success, motion_id, matching_inputs
   local min_start_frame = gamestate.frame_number - MAX_SEARCH_DEPTH
   local input_data = Pools.temp:alloc()
   input_data.player_input = Pools.temp:alloc()
   for _, motion_data in ipairs(motion_list) do
      local motion = motion_data.motion
      tools.clear_table(input_data.player_input)
      input_data.player = player
      input_data.player_history_index = #player.input_history
      input_data.motion_input_index = #motion.inputs
      input_data.motion_input = motion.inputs[#motion.inputs]
      input_data.matched_duration = 0
      input_data.start_frame = math.max(motion_data.last_match_frame, min_start_frame)
      input_data.is_min_matched = false
      input_data.is_max_matched = false

      local has_next_input = update_player_input(input_data, #player.input_history)
      if not has_next_input then
         break
      end
      success, matching_inputs = match_motion(motion, input_data)
      tools.clear_table(motion_data.matching_inputs)
      tools.copy_fields(motion_data.matching_inputs, matching_inputs)
      if success then
         if not motion.validation or motion.validation(matching_inputs) then
            motion_id = motion.id
            update_match_frame(motion, motion_list)
            motion_data.last_match_frame = gamestate.frame_number
            break
         end
      end
   end
   Pools.temp:free(input_data.player_input)
   Pools.temp:free(input_data)

   return motion_id, matching_inputs
end

local key_data_default = { down = false, press = false, release = false, state_time = 0 }
local keys_default = {
   "down",
   "up",
   "left",
   "right",
   "enter",
   "backslash",
   "backspace",
   "insert",
   "delete",
   "plus",
   "minus",
   "W",
   "S",
   "A",
   "D",
   "U",
   "I",
   "O",
   "J",
   "K",
   "L",
   "V",
   "B",
   "N",
   "M",
   "alt",
   "1",
   "2",
   "3",
   "4",
   "5",
   "6",
   "7",
   "8",
   "9",
   "0",
}
local keyboard_input = {}
for _, key in ipairs(keys_default) do
   keyboard_input[key] = copytable(key_data_default)
end

local function queue_input_sequence(player, sequence, offset, overwrite, allow_blocking)
   offset = offset or 0

   if sequence == nil or #sequence == 0 then
      return
   end

   if player.pending_input_sequence ~= nil and not overwrite then
      return
   end

   local seq = {}
   seq.id = sequence
   seq.sequence = copytable(sequence)
   seq.current_frame = math.min(1 - offset, #seq.sequence)
   seq.allow_blocking = false or allow_blocking

   player.pending_input_sequence = seq
end

local gauges_offsets = { 0x0, 0x1C, 0x38, 0x54, 0x70 }
local function process_pending_input_sequence(player, input)
   input = input or input_object
   if player.pending_input_sequence == nil then
      return
   end

   -- Cancel all input
   if player.pending_input_sequence.allow_blocking then
      if player.flip_input then
         input[player.prefix .. " Right"] = false
      else
         input[player.prefix .. " Left"] = false
      end
   else
      input[player.prefix .. " Left"] = false
      input[player.prefix .. " Right"] = false
      input[player.prefix .. " Down"] = false
   end
   input[player.prefix .. " Up"] = false

   input[player.prefix .. " Weak Punch"] = false
   input[player.prefix .. " Medium Punch"] = false
   input[player.prefix .. " Strong Punch"] = false
   input[player.prefix .. " Weak Kick"] = false
   input[player.prefix .. " Medium Kick"] = false
   input[player.prefix .. " Strong Kick"] = false

   -- Charge moves memory locations
   -- P1
   -- 0x020259D8 H/Urien V/Oro V/Chun H/Q V/Remy
   -- 0x020259F4 (+1C) V/Urien H/Q H/Remy
   -- 0x02025A10 (+38) H/Oro H/Remy
   -- 0x02025A2C (+54) V/Urien V/Alex
   -- 0x02025A48 (+70) H/Alex

   -- P2
   -- 0x02025FF8
   -- 0x02026014
   -- 0x02026030
   -- 0x0202604C
   -- 0x02026068
   local gauges_base = 0
   if player.id == 1 then
      gauges_base = 0x020259D8
   elseif player.id == 2 then
      gauges_base = 0x02025FF8
   end

   if player.pending_input_sequence.current_frame >= 1 then
      local current_frame_input = player.pending_input_sequence.sequence[player.pending_input_sequence.current_frame]
      for i = 1, #current_frame_input do
         local input_name = player.prefix .. " "
         if current_frame_input[i] == "forward" then
            if player.flip_input then
               input_name = input_name .. "Right"
            else
               input_name = input_name .. "Left"
            end
         elseif current_frame_input[i] == "back" then
            if player.flip_input then
               input_name = input_name .. "Left"
            else
               input_name = input_name .. "Right"
            end
         elseif current_frame_input[i] == "up" then
            input_name = input_name .. "Up"
         elseif current_frame_input[i] == "down" then
            input_name = input_name .. "Down"
         elseif current_frame_input[i] == "LP" then
            input_name = input_name .. "Weak Punch"
         elseif current_frame_input[i] == "MP" then
            input_name = input_name .. "Medium Punch"
         elseif current_frame_input[i] == "HP" then
            input_name = input_name .. "Strong Punch"
         elseif current_frame_input[i] == "LK" then
            input_name = input_name .. "Weak Kick"
         elseif current_frame_input[i] == "MK" then
            input_name = input_name .. "Medium Kick"
         elseif current_frame_input[i] == "HK" then
            input_name = input_name .. "Strong Kick"
         elseif current_frame_input[i] == "h_charge" then
            if player.char_str == "urien" then
               memory.writeword(gauges_base + gauges_offsets[1], 0xFF00)
            elseif player.char_str == "oro" then
               memory.writeword(gauges_base + gauges_offsets[3], 0xFF00)
            elseif player.char_str == "chunli" then
            elseif player.char_str == "q" then
               memory.writeword(gauges_base + gauges_offsets[1], 0xFF00)
               memory.writeword(gauges_base + gauges_offsets[2], 0xFF00)
            elseif player.char_str == "remy" then
               memory.writeword(gauges_base + gauges_offsets[2], 0xFF00)
               memory.writeword(gauges_base + gauges_offsets[3], 0xFF00)
            elseif player.char_str == "alex" then
               memory.writeword(gauges_base + gauges_offsets[5], 0xFF00)
            end
         elseif current_frame_input[i] == "v_charge" then
            if player.char_str == "urien" then
               memory.writeword(gauges_base + gauges_offsets[2], 0xFF00)
               memory.writeword(gauges_base + gauges_offsets[4], 0xFF00)
            elseif player.char_str == "oro" then
               memory.writeword(gauges_base + gauges_offsets[1], 0xFF00)
            elseif player.char_str == "chunli" then
               memory.writeword(gauges_base + gauges_offsets[1], 0xFF00)
            elseif player.char_str == "q" then
            elseif player.char_str == "remy" then
               memory.writeword(gauges_base + gauges_offsets[1], 0xFF00)
            elseif player.char_str == "alex" then
               memory.writeword(gauges_base + gauges_offsets[4], 0xFF00)
            end
         elseif current_frame_input[i] == "legs_LK" then
            memory.writebyte(memory_addresses.players[player.id].kyaku_l_count, 0x4)
            memory.writebyte(memory_addresses.players[player.id].kyaku_reset_time, 0x63)
         elseif current_frame_input[i] == "legs_MK" then
            memory.writebyte(memory_addresses.players[player.id].kyaku_m_count, 0x4)
            memory.writebyte(memory_addresses.players[player.id].kyaku_reset_time, 0x63)
         elseif current_frame_input[i] == "legs_HK" then
            memory.writebyte(memory_addresses.players[player.id].kyaku_h_count, 0x4)
            memory.writebyte(memory_addresses.players[player.id].kyaku_reset_time, 0x63)
         elseif current_frame_input[i] == "legs_EXK" then
            memory.writebyte(memory_addresses.players[player.id].kyaku_l_count, 0x4)
            memory.writebyte(memory_addresses.players[player.id].kyaku_m_count, 0x4)
            memory.writebyte(memory_addresses.players[player.id].kyaku_reset_time, 0x63)
         elseif current_frame_input[i] == "360" then
            memory.writebyte(player.addresses.kaiten_1, 0)
            memory.writebyte(player.addresses.kaiten_2, 0)
            memory.writebyte(player.addresses.kaiten_1_reset, 31)
            memory.writebyte(player.addresses.kaiten_2_reset, 31)
            if player.char_str == "hugo" then
               memory.writebyte(player.addresses.kaiten_completed_360, 48)
            end
         elseif current_frame_input[i] == "720" then
            memory.writebyte(player.addresses.kaiten_1, 15)
            memory.writebyte(player.addresses.kaiten_1_reset, 31)
         end
         input[input_name] = true
      end
   end

   player.pending_input_sequence.current_frame = player.pending_input_sequence.current_frame + 1
   if player.pending_input_sequence.current_frame > #player.pending_input_sequence.sequence then
      player.pending_input_sequence = nil
   end
end

local function clear_input_sequence(player)
   player.pending_input_sequence = nil
end

local function is_playing_input_sequence(player)
   return player.pending_input_sequence ~= nil and player.pending_input_sequence.current_frame >= 1
end

local function make_input_empty(input)
   input = input or input_object
   if input == nil then
      return
   end

   input["P1 Up"] = false
   input["P1 Down"] = false
   input["P1 Left"] = false
   input["P1 Right"] = false
   input["P1 Weak Punch"] = false
   input["P1 Medium Punch"] = false
   input["P1 Strong Punch"] = false
   input["P1 Weak Kick"] = false
   input["P1 Medium Kick"] = false
   input["P1 Strong Kick"] = false
   input["P1 Start"] = false
   input["P1 Coin"] = false
   input["P2 Up"] = false
   input["P2 Down"] = false
   input["P2 Left"] = false
   input["P2 Right"] = false
   input["P2 Weak Punch"] = false
   input["P2 Medium Punch"] = false
   input["P2 Strong Punch"] = false
   input["P2 Weak Kick"] = false
   input["P2 Medium Kick"] = false
   input["P2 Strong Kick"] = false
   input["P2 Start"] = false
   input["P2 Coin"] = false
end

local function clear_directional_input(input, id)
   input = input or input_object
   if input == nil then
      return
   end
   input["P" .. id .. " Up"] = false
   input["P" .. id .. " Down"] = false
   input["P" .. id .. " Left"] = false
   input["P" .. id .. " Right"] = false
end

local function clear_buttons(input, id)
   input = input or input_object
   if input == nil then
      return
   end
   input["P" .. id .. " Weak Punch"] = false
   input["P" .. id .. " Medium Punch"] = false
   input["P" .. id .. " Strong Punch"] = false
   input["P" .. id .. " Weak Kick"] = false
   input["P" .. id .. " Medium Kick"] = false
   input["P" .. id .. " Strong Kick"] = false
   input["P" .. id .. " Start"] = false
   input["P" .. id .. " Coin"] = false
end

local function clear_all(input, id)
   input = input or input_object
   clear_directional_input(input, id)
   clear_buttons(input, id)
end

local function is_all_inputs_clear(input, id)
   input = input or input_object
   return not input["P" .. id .. " Up"]
      and not input["P" .. id .. " Down"]
      and not input["P" .. id .. " Left"]
      and not input["P" .. id .. " Right"]
      and not input["P" .. id .. " Weak Punch"]
      and not input["P" .. id .. " Medium Punch"]
      and not input["P" .. id .. " Strong Punch"]
      and not input["P" .. id .. " Weak Kick"]
      and not input["P" .. id .. " Medium Kick"]
      and not input["P" .. id .. " Strong Kick"]
      and not input["P" .. id .. " Start"]
      and not input["P" .. id .. " Coin"]
end

local function press_left(input, id)
   input = input or input_object
   input["P" .. id .. " Left"] = true
end

local function press_right(input, id)
   input = input or input_object
   input["P" .. id .. " Right"] = true
end

local function create_input_sequence(move_selection_data)
   if move_selection_data.type == 5 then
      return {}, 0
   end -- recording

   local sequence = {}
   local offset = 0

   local name = move_selection_data.name

   if move_selection_data.type == 2 then
      local stick = move_selection_data.motion
      local button = move_selection_data.button

      if stick == "kara_throw" then
         sequence = { { "LP", "LK" } }
         table.insert(sequence, 1, tools.deepcopy(move_selection_data.inputs))
         return sequence, offset
      end
      if stick == "dir_5" then
         sequence = { {} }
      elseif stick == "dir_6" then
         sequence = { { "forward" } }
      elseif stick == "dir_4" then
         sequence = { { "back" } }
      elseif stick == "dir_2" then
         sequence = { { "down" } }
      elseif stick == "dir_8" then
         sequence = { { "up" }, { "up" }, { "up" } }
         offset = 2
      elseif stick == "dir_1" then
         sequence = { { "down", "back" } }
      elseif stick == "dir_3" then
         sequence = { { "down", "forward" } }
      elseif stick == "sjump_neutral" then
         sequence = { { "down" }, { "up" }, { "up" }, { "up" } }
         offset = 2
      elseif stick == "dir_9" then
         sequence = { { "forward", "up" }, { "forward", "up" }, { "forward", "up" } }
         offset = 2
      elseif stick == "sjump_forward" then
         sequence = { { "down" }, { "forward", "up" }, { "forward", "up" }, { "forward", "up" } }
         offset = 2
      elseif stick == "dir_7" then
         sequence = { { "back", "up" }, { "back", "up" }, { "back", "up" } }
         offset = 2
      elseif stick == "sjump_back" then
         sequence = { { "down" }, { "back", "up" }, { "back", "up" }, { "back", "up" } }
         offset = 2
      elseif stick == "back_dash" then
         sequence = { { "back" }, {}, { "back" } }
      elseif stick == "forward_dash" then
         sequence = { { "forward" }, {}, { "forward" } }
      end

      if button == "none" then
      elseif button == "EXP" then
         table.insert(sequence[#sequence], "MP")
         table.insert(sequence[#sequence], "HP")
      elseif button == "EXK" then
         table.insert(sequence[#sequence], "MK")
         table.insert(sequence[#sequence], "HK")
      elseif button == "LP+LK" then
         table.insert(sequence[#sequence], "LP")
         table.insert(sequence[#sequence], "LK")
      elseif button == "MP+MK" then
         table.insert(sequence[#sequence], "MP")
         table.insert(sequence[#sequence], "MK")
      elseif button == "HP+HK" then
         table.insert(sequence[#sequence], "HP")
         table.insert(sequence[#sequence], "HK")
      else
         if stick == "dir_7" or stick == "dir_8" or stick == "dir_9" then
            for i = 1, 6 - #sequence do
               table.insert(sequence, {})
            end
            if is_slow_jumper(move_selection_data.char_str) then
               table.insert(sequence, #sequence, {})
            elseif is_really_slow_jumper(move_selection_data.char_str) then
               table.insert(sequence, #sequence, {})
               table.insert(sequence, #sequence, {})
            end
         elseif stick == "sjump_back" or stick == "sjump_neutral" or stick == "sjump_forward" then
            for i = 1, 9 - #sequence do
               table.insert(sequence, {})
            end
            if is_slow_jumper(move_selection_data.char_str) then
               table.insert(sequence, #sequence, {})
            elseif is_really_slow_jumper(move_selection_data.char_str) then
               table.insert(sequence, #sequence, {})
               table.insert(sequence, #sequence, {})
            end
         end
         table.insert(sequence[#sequence], button)
      end
   elseif move_selection_data.type == 3 then
      sequence = tools.deepcopy(move_selection_data.inputs)
      if name == "kara_capture_and_deadly_blow" then
         offset = 1
      elseif name == "kara_karakusa_lk" then
         offset = 7
      elseif name == "kara_karakusa_hk" then
         offset = 1
      elseif name == "kara_zenpou_yang" then
         offset = 1
      elseif name == "kara_zenpou_yun" then
         offset = 1
      elseif name == "kara_power_bomb" then
         offset = 1
      elseif name == "kara_niouriki" then
         offset = 1
      elseif name == "kara_sgs_f_mp" then
         offset = 6
      elseif name == "kara_sgs_d_hk" then
         offset = 6
      end
   elseif move_selection_data.type == 4 then
      if name == "guard_jump_back" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "back", "up" },
            { "back", "up" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
         }
      elseif name == "guard_jump_neutral" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "up" },
            { "up" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
         }
      elseif name == "guard_jump_forward" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "forward", "up" },
            { "forward", "up" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
         }
      elseif name == "guard_jump_back_air_parry" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "back", "up" },
            { "back", "up" },
            {},
            {},
            {},
            { "forward" },
         }
         if is_slow_jumper(move_selection_data.char_str) then
            table.insert(sequence, #sequence, {})
         elseif is_really_slow_jumper(move_selection_data.char_str) then
            table.insert(sequence, #sequence, {})
            table.insert(sequence, #sequence, {})
         end
      elseif name == "guard_jump_neutral_air_parry" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "up" },
            { "up" },
            {},
            {},
            {},
            { "forward" },
         }
         if is_slow_jumper(move_selection_data.char_str) then
            table.insert(sequence, #sequence, {})
         elseif is_really_slow_jumper(move_selection_data.char_str) then
            table.insert(sequence, #sequence, {})
            table.insert(sequence, #sequence, {})
         end
      elseif name == "guard_jump_forward_air_parry" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "up", "forward" },
            { "up", "forward" },
            {},
            {},
            {},
            { "forward" },
         }
         if is_slow_jumper(move_selection_data.char_str) then
            table.insert(sequence, #sequence, {})
         elseif is_really_slow_jumper(move_selection_data.char_str) then
            table.insert(sequence, #sequence, {})
            table.insert(sequence, #sequence, {})
         end
      elseif name == "crouch_tech" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back", "LP", "LK" },
            { "down", "back", "LP", "LK" },
         }
      elseif name == "block_late_tech" then
         sequence = {
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "down", "back" },
            { "back", "LP", "LK" },
            { "back", "LP", "LK" },
         }
      elseif name == "shita_mae" then
         sequence = {
            { "down" },
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            { "forward" },
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
         }
      elseif name == "mae_shita" then
         sequence = {
            { "forward" },
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            { "down" },
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
            {},
         }
      elseif name == "parry_dash" then
         sequence = { { "forward" }, {}, {}, {}, {}, {}, {}, { "forward" }, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }
      end
   end
   return sequence, offset
end

-- swap inputs
local function swap_inputs(out_input_table)
   out_input_table = out_input_table or input_object
   local function swap(input)
      local carry = out_input_table["P1 " .. input]
      out_input_table["P1 " .. input] = out_input_table["P2 " .. input]
      out_input_table["P2 " .. input] = carry
   end

   swap("Up")
   swap("Down")
   swap("Left")
   swap("Right")
   swap("Weak Punch")
   swap("Medium Punch")
   swap("Strong Punch")
   swap("Weak Kick")
   swap("Medium Kick")
   swap("Strong Kick")
end

local last_coin_input_frame = -1
local input_buffer_length = 12
local GESTURE = { SINGLE_TAP_COIN = 1, DOUBLE_TAP_COIN = 2, TRIPLE_TAP_COIN = 3, COIN_INPUT = 4 }
local a = { gesture = GESTURE.SINGLE_TAP_COIN }
local function interpret_gesture(player)
   local input_pressed = player.input.pressed.coin
   if input_pressed then
      if gamestate.frame_number - last_coin_input_frame < input_buffer_length then
         last_coin_input_frame = -1
         return "double_tap"
      else
         last_coin_input_frame = gamestate.frame_number
      end
   end
   if last_coin_input_frame > 0 and gamestate.frame_number - last_coin_input_frame >= input_buffer_length then
      last_coin_input_frame = -1
      return "single_tap"
   end
   return "none"
end

local function queue_input_from_json(player, file)
   local settings = require("src.settings")
   local path = string.format("%s%s", settings.recordings_path, file)
   local recording_inputs = tools.read_object_from_json_file(path)
   if not recording_inputs then
      print(string.format('Error: Failed to load recording from "%s"', path))
   else
      print(string.format('Playing "%s"', path))
      queue_input_sequence(player, recording_inputs)
   end
end

local function is_input_neutral(player, input)
   input = input or input_object
   if input == nil then
      return
   end
   if
      input[player.prefix .. " Up"] == false
      and input[player.prefix .. " Down"] == false
      and input[player.prefix .. " Left"] == false
      and input[player.prefix .. " Right"] == false
   then
      return true
   end
   return false
end

local function problematic_inputs_released(input, id)
   input = input or input_object
   if input == nil then
      return true
   end
   return input["P" .. id .. " Up"] == false
      and input["P" .. id .. " Weak Punch"] == false
      and input["P" .. id .. " Medium Punch"] == false
      and input["P" .. id .. " Strong Punch"] == false
      and input["P" .. id .. " Weak Kick"] == false
      and input["P" .. id .. " Medium Kick"] == false
      and input["P" .. id .. " Strong Kick"] == false
end

local function log_input(players)
   if previous_input then
      local function log(player_object, name, short_name)
         short_name = short_name or name
         local full_name = player_object.prefix .. " " .. name
         if not previous_input[full_name] and input[full_name] then
            log(player_object.prefix, "input", short_name .. " 1")
         elseif previous_input[full_name] and not input[full_name] then
            log(player_object.prefix, "input", short_name .. " 0")
         end
      end

      for _, o in ipairs(players) do
         log(o, "Left")
         log(o, "Right")
         log(o, "Up")
         log(o, "Down")
         log(o, "Weak Punch", "LP")
         log(o, "Medium Punch", "MP")
         log(o, "Strong Punch", "HP")
         log(o, "Weak Kick", "LK")
         log(o, "Medium Kick", "MK")
         log(o, "Strong Kick", "HK")
      end
   end
end

local function update_keyboard_input(keys)
   for key, _ in pairs(keys) do
      if not keyboard_input[key] then
         keyboard_input[key] = copytable(key_data_default)
      end
   end
   for key, data in pairs(keyboard_input) do
      data.press = false
      data.release = false
      if keys[key] then
         if not data.down then
            data.press = true
            data.state_time = 0
         else
            data.state_time = data.state_time + 1
         end
         data.down = true
      else
         if data.down then
            data.release = true
            data.state_time = 0
         else
            data.state_time = data.state_time + 1
         end
         data.down = false
      end
   end
end

local autofire_rate_default = 4
local autofire_time_default = 4
local function check_keyboard_autofire(keyboard_inp, autofire_rate, autofire_time)
   if not keyboard_inp then
      return false
   end
   autofire_rate = autofire_rate or autofire_rate_default
   autofire_time = autofire_time or autofire_time_default
   if keyboard_inp.press then
      return true
   end
   if keyboard_inp.state_time >= 30 then
      autofire_rate = autofire_rate / 2
   end
   if
      keyboard_inp.down
      and keyboard_inp.state_time > autofire_time
      and (keyboard_inp.state_time % autofire_rate) == 0
   then
      return true
   end
   return false
end

local function read_single_input(player_input, input_name, input)
   player_input.pressed[input_name] = false
   player_input.released[input_name] = false
   if player_input.down[input_name] == false and input then
      player_input.pressed[input_name] = true
   end
   if player_input.down[input_name] == true and input == false then
      player_input.released[input_name] = true
   end

   if player_input.down[input_name] == input then
      player_input.state_time[input_name] = player_input.state_time[input_name] + 1
   else
      player_input.last_state_time[input_name] = player_input.state_time[input_name]
      player_input.state_time[input_name] = 0
   end
   player_input.down[input_name] = input
end

local function has_pending_inputs(player)
   if player.pending_input_sequence then
      return #player.pending_input_sequence > 0
   end
   return false
end

local function block_input(id, input_types, one_frame_only)
   block_input_settings[id].should_block = true
   block_input_settings[id].input_types = input_types
   block_input_settings[id].one_frame_only = one_frame_only or false
end

local function unblock_input(id)
   tools.clear_table(block_input_settings[id])
   block_input_settings[id].should_block = false
end

local function update_input(input, players)
   input = input or input_object

   for i, player in ipairs(players) do
      read_single_input(player.input, "start", input[player.prefix .. " Start"])
      read_single_input(player.input, "coin", input[player.prefix .. " Coin"])
      read_single_input(player.input, "up", input[player.prefix .. " Up"])
      read_single_input(player.input, "down", input[player.prefix .. " Down"])
      read_single_input(player.input, "left", input[player.prefix .. " Left"])
      read_single_input(player.input, "right", input[player.prefix .. " Right"])
      read_single_input(player.input, "LP", input[player.prefix .. " Weak Punch"])
      read_single_input(player.input, "MP", input[player.prefix .. " Medium Punch"])
      read_single_input(player.input, "HP", input[player.prefix .. " Strong Punch"])
      read_single_input(player.input, "LK", input[player.prefix .. " Weak Kick"])
      read_single_input(player.input, "MK", input[player.prefix .. " Medium Kick"])
      read_single_input(player.input, "HK", input[player.prefix .. " Strong Kick"])
   end

   if #block_input_settings > 0 then
      for id, setting in ipairs(block_input_settings) do
         if setting.should_block then
            if setting.input_types == "buttons" then
               clear_buttons(input, id)
            elseif setting.input_types == "directions" then
               clear_directional_input(input, id)
            elseif setting.input_types == "all" then
               clear_all(input, id)
            end
            if setting.one_frame_only then
               tools.clear_table(block_input_settings[id])
               setting.should_block = false
            end
         end
      end
   end
end

local function update_input_info(input, players)
   if not previous_input then
      return
   end
   input = input or input_object
   for i, player in ipairs(players) do
      if tools.is_pressing_back(player, input) and not tools.is_pressing_back(player, previous_input) then
         player.input_info.last_back_input = gamestate.frame_number
      elseif tools.is_pressing_forward(player, input) and not tools.is_pressing_forward(player, previous_input) then
         player.input_info.last_forward_input = gamestate.frame_number
      end
      if input[player.prefix .. " Down"] and not previous_input[player.prefix .. " Down"] then
         player.input_info.last_down_input = gamestate.frame_number
      elseif input[player.prefix .. " Up"] and not previous_input[player.prefix .. " Up"] then
         player.input_info.last_up_input = gamestate.frame_number
      end
   end
end

local input_module = {
   DIR = DIR,
   BTN = BTN,
   MOTIONS = MOTIONS,
   MOTION_PRIORITY = MOTION_PRIORITY,
   OPTION_PARRY_INPUTS = OPTION_PARRY_INPUTS,
   OPTION_SELECT_INPUTS = OPTION_SELECT_INPUTS,
   PARRY_INPUTS = PARRY_INPUTS,
   MOVE_INPUTS = MOVE_INPUTS,
   AFTER_HIGH_PARRY = AFTER_HIGH_PARRY,
   AFTER_LOW_PARRY = AFTER_LOW_PARRY,
   queue_input_sequence = queue_input_sequence,
   process_pending_input_sequence = process_pending_input_sequence,
   clear_input_sequence = clear_input_sequence,
   is_playing_input_sequence = is_playing_input_sequence,
   swap_inputs = swap_inputs,
   interpret_gesture = interpret_gesture,
   make_input_empty = make_input_empty,
   clear_directional_input = clear_directional_input,
   clear_buttons = clear_buttons,
   clear_all = clear_all,
   is_all_inputs_clear = is_all_inputs_clear,
   press_left = press_left,
   press_right = press_right,
   problematic_inputs_released = problematic_inputs_released,
   create_input_sequence = create_input_sequence,
   queue_input_from_json = queue_input_from_json,
   is_input_neutral = is_input_neutral,
   log_input = log_input,
   has_pending_inputs = has_pending_inputs,
   update_input = update_input,
   update_input_info = update_input_info,
   update_keyboard_input = update_keyboard_input,
   check_keyboard_autofire = check_keyboard_autofire,
   block_input = block_input,
   unblock_input = unblock_input,
   flip_direction = flip_direction,
   clear_input_history = clear_input_history,
   update_input_history = update_input_history,
   match_motion_list = match_motion_list,
}

setmetatable(input_module, {
   __index = function(_, key)
      if key == "input" then
         return input_object
      elseif key == "previous_input" then
         return previous_input
      elseif key == "keyboard_input" then
         return keyboard_input
      end
   end,

   __newindex = function(_, key, value)
      if key == "input" then
         input_object = value
      elseif key == "previous_input" then
         previous_input = value
      elseif key == "keyboard_input" then
         keyboard_input = value
      else
         rawset(input_module, key, value)
      end
   end,
})

return input_module
