local frame_data = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local move_data = require("src.modules.move_data")
local stage_data = require("src.modules.stage_data")
local inputs = require("src.control.inputs")
local advanced_control = require("src.control.advanced_control")
local defense_classes = require("src.training.defense.defense_classes")
local prediction = require("src.modules.prediction")
local tools = require("src.tools")
local utils = require("src.modules.utils")

local Delay = advanced_control.Delay
local Setup, Followup, Action_Type, Setup_Type = defense_classes.Setup, defense_classes.Followup,
                                                 defense_classes.Action_Type, defense_classes.Setup_Type
local is_idle_timing, is_wakeup_timing, is_landing_timing = advanced_control.is_idle_timing,
                                                            advanced_control.is_wakeup_timing,
                                                            advanced_control.is_landing_timing
local is_throw_vulnerable_timing = advanced_control.is_throw_vulnerable_timing
local queue_input_sequence_and_wait, all_commands_complete = advanced_control.queue_input_sequence_and_wait,
                                                             advanced_control.all_commands_complete
local character_specific = frame_data.character_specific

-- setups: back throw, forward throw, cr mk, cr hk, shoryu 

--cancel denjin, hadou denjin

local forward_dash_input
local forward_dash_duration
local back_dash_input
local back_dash_duration

local block_low_input

local d_mk_input

local d_hk_input

local hp_shoryu_input

local denjin_input
local lp_hadouken_denjin_input

local back_throw_followups
local forward_throw_followups
local cr_mk_followups
local cr_hk_followups
local hp_shoryu_followups


local function init()
   block_low_input = {{"back", "down"}, {"back", "down"}}

   forward_dash_input = {{"forward"}, {}, {"forward"}}
   forward_dash_duration = frame_data.get_first_idle_frame_by_name("ryu", "dash_forward")
   back_dash_input = {{"back"}, {}, {"back"}}
   back_dash_duration = frame_data.get_first_idle_frame_by_name("ryu", "dash_back")

   d_mk_input = {{"down", "MK"}}
   d_hk_input = {{"down", "HK"}}

   hp_shoryu_input = move_data.get_move_inputs_by_name("ryu", "shoryuken", "HP")

   denjin_input = move_data.get_move_inputs_by_name("ryu", "denjin_hadouken")

   lp_hadouken_denjin_input = {{"down"}, {"down", "forward"}, {"forward", "LP"}, {}, {}, {}, {}, {}, {}, {"down"}, {"down", "forward"}, {"forward", "LP"}}
end

local function handle_interruptions(player, stage, actions, i_actions)
   if (player.has_just_been_hit and not player.is_being_thrown) or player.other.has_just_parried then
      return true, {score = 0, should_end = true}
   end
   if (player.is_being_thrown and player.throw_tech_countdown <= 0) then
      return true, {score = 0, should_end = true}
   end
   return false
end

local mash_directions_serious = {
   {"down", "back"}, {"down"}, {"up", "forward"}, {"up"}, {"down", "back"}, {"up", "forward"}
}
local mash_directions_fastest = {{"down", "forward"}, {"down", "back"}}
local mash_directions = mash_directions_fastest
local mash_buttons = {"MP", "HP", "LK", "MK", "HK"}