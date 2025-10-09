local framedata = require("src.modules.framedata")
local stage_data = require("src.modules.stage_data")

local character_specific = framedata.character_specific

local function get_stage_limits(stage, char_str)
   local limit_left = stage_data.stages[stage].left + framedata.character_specific[char_str].corner_offset_left
   local limit_right = stage_data.stages[stage].right - framedata.character_specific[char_str].corner_offset_right
   return limit_left, limit_right
end

local function get_forward_walk_distance(player, n_frames)
   return character_specific[player.char_str].forward_walk_speed * 0.5 + math.max(n_frames - 1, 0) *
              character_specific[player.char_str].forward_walk_speed
end

local function get_backward_walk_distance(player, n_frames)
   return math.abs(n_frames * character_specific[player.char_str].backward_walk_speed)
end

local function is_in_opponent_throw_range(player)
   local dist = math.abs(player.other.pos_x - player.pos_x)
   local opponent_throw_range = framedata.get_hitbox_max_range_by_name(player.other.char_str, "throw_neutral") or 40
   if opponent_throw_range >= dist - character_specific[player.char_str].pushbox_width / 2 then return true end
   return false
end

return {
   get_stage_limits = get_stage_limits,
   get_forward_walk_distance = get_forward_walk_distance,
   get_backward_walk_distance = get_backward_walk_distance,
   is_in_opponent_throw_range = is_in_opponent_throw_range
}