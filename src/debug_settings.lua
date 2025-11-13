-- debug options
local developer_mode = false
local recording_framedata = false
local debug_hitboxes = false and developer_mode
local assert_enabled = developer_mode
local log_enabled = developer_mode
local log_categories_display = {
   input = {history = false, print = false},
   projectiles = {history = false, print = false},
   fight = {history = false, print = false},
   animation = {history = false, print = false},
   parry = {history = false, print = false},
   blocking = {history = false, print = false},
   counter_attack = {history = false, print = false},
   frame_advantage = {history = false, print = false}
}

local player_debug_variables = {
   {debug_state_variables = false, debug_freeze_frames = false, debug_standing_state = false},
   {debug_state_variables = false, debug_freeze_frames = false, debug_standing_state = false}
}

local show_dump_state_display = false
local show_debug_frames_display = false
local show_debug_variables_display = false
local show_memory_view_display = false
local show_memory_results_display = true

local hitbox_display_frames = 3

local debug = {
   player_debug_variables = player_debug_variables,
   assert_enabled = assert_enabled,
   log_enabled = log_enabled
}

setmetatable(debug, {
   __index = function(_, key)
      if key == "developer_mode" then
         return developer_mode
      elseif key == "recording_framedata" then
         return recording_framedata
      elseif key == "debug_hitboxes" then
         return debug_hitboxes
      elseif key == "log_categories_display" then
         return log_categories_display
      elseif key == "show_dump_state_display" then
         return show_dump_state_display
      elseif key == "show_debug_frames_display" then
         return show_debug_frames_display
      elseif key == "show_debug_variables_display" then
         return show_debug_variables_display
      elseif key == "show_memory_view_display" then
         return show_memory_view_display
      elseif key == "show_memory_results_display" then
         return show_memory_results_display
      elseif key == "hitbox_display_frames" then
         return hitbox_display_frames
      end
   end,

   __newindex = function(_, key, value)
      if key == "developer_mode" then
         developer_mode = value
      elseif key == "recording_framedata" then
         recording_framedata = value
      elseif key == "debug_hitboxes" then
         debug_hitboxes = value
      elseif key == "log_categories_display" then
         log_categories_display = value
      elseif key == "show_dump_state_display" then
         show_dump_state_display = value
      elseif key == "show_debug_frames_display" then
         show_debug_frames_display = value
      elseif key == "show_debug_variables_display" then
         show_debug_variables_display = value
      elseif key == "show_memory_view_display" then
         show_memory_view_display = value
      elseif key == "show_memory_results_display" then
         show_memory_results_display = value
      elseif key == "hitbox_display_frames" then
         hitbox_display_frames = value
      else
         rawset(debug, key, value)
      end
   end
})

return debug
