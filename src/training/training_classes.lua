local Action_Type = {ACTION = 1, WALK_FORWARD = 2, WALK_BACKWARD = 3, PARRY = 4, BLOCK = 5, ATTACK = 6, THROW = 7, REACT = 8, PUNISH = 9, FORWARD_DASH = 10, BACK_DASH = 11}
local Setup_Type = {HARD = 1, SOFT = 2}

local Setup = {}
Setup.__index = Setup

function Setup:new(name, type)
   local obj = {name = name, type = type or Action_Type.ACTION}

   setmetatable(obj, self)
   return obj
end

function Setup:get_hard_reset_range(player, stage) end
function Setup:get_soft_reset_range(player, stage) end
function Setup:get_dummy_offset(player) end
function Setup:setup(player, stage, actions, i_actions) end
function Setup:is_valid(player, stage, actions, i_actions) return true end
function Setup:should_execute(player, stage, actions, i_actions) return true end
function Setup:followups() return nil end
function Setup:label() return self.name end

local Followup = {}
Followup.__index = Followup

function Followup:new(name, type)
   local obj = {name = name, type = type or Action_Type.ACTION}

   setmetatable(obj, self)
   return obj
end

function Followup:setup(player, stage, actions, i_actions) end
function Followup:run(player, stage, actions, i_actions) end
function Followup:is_valid(player, stage, actions, i_actions) return true end
function Followup:should_execute(player, stage, actions, i_actions) return true end
function Followup:followups() return nil end
function Followup:label() return self.name end

return {Action_Type = Action_Type, Setup_Type = Setup_Type, Setup = Setup, Followup = Followup}
