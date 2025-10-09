local settings = require("src.settings")
local gamestate = require("src.gamestate")
local training = require("src.training")
local fd = require("src.modules.framedata")
local frame_data, is_slow_jumper, is_really_slow_jumper = fd.frame_data, fd.is_slow_jumper, fd.is_really_slow_jumper
local memory_addresses = require("src.control.memory_addresses")
local inputs = require("src.control.inputs")



local frames_prediction = 15
local function queue_input_sequence_on_recovery(player, sequence, offset)
  if player.is_idle then
    inputs.queue_input_sequence(player, sequence, offset)
  end
  local idle_frames = frame_data[player.char_str][player.animation].idle_frames
  if idle_frames then
    local next_idle_frame = 0
    for _, idle_frame in ipairs(idle_frames) do
      print(idle_frame[1], idle_frame[2])
      if player.animation_frame < idle_frame[1] then
        next_idle_frame = idle_frame[1]
        break
      end
    end
    local delta = next_idle_frame - player.animation_frame

    if delta > 0 then
      inputs.queue_input_sequence(player, sequence, delta - #sequence)

    else
    end
  end
end


local input_module = {
  queue_input_sequence_on_recovery = queue_input_sequence_on_recovery
}

return input_module