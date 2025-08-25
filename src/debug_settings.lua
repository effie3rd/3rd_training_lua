-- debug options
local developer_mode = true 
local recording_framedata = false
local assert_enabled = developer_mode
local log_enabled = developer_mode
local log_categories_display = {
  input =                     { history = true, print = false },
  projectiles =               { history = true, print = false },
  fight =                     { history = false, print = false },
  animation =                 { history = false, print = false },
  parry_training_FORWARD =    { history = false, print = false },
  blocking =                  { history = true, print = false },
  counter_attack =            { history = false, print = false },
  frame_advantage =           { history = false, print = false },
}

local player_debug_variables = {
  { debug_state_variables = false,
    debug_freeze_frames = false,
    debug_standing_state = false
  },
  { debug_state_variables = false,
    debug_freeze_frames = false,
    debug_standing_state = false
  }
}

local dump_state_display = false
local debug_frames_display = false

local debug =  {
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
    elseif key == "log_categories_display" then
      return log_categories_display
    elseif key == "dump_state_display" then
      return dump_state_display
    elseif key == "debug_frames_display" then
      return debug_frames_display      
    end
  end,

  __newindex = function(_, key, value)
    if key == "developer_mode" then
      developer_mode = value
    elseif key == "recording_framedata" then
      recording_framedata = value
    elseif key == "log_categories_display" then
      log_categories_display = value
    elseif key == "dump_state_display" then
      dump_state_display = value
    elseif key == "debug_frames_display" then
      debug_frames_display = value      
    else
      rawset(debug, key, value)
    end
  end
})

return debug