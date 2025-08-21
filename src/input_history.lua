local gamestate = require("src/gamestate")

input_history_size_max = 15
input_history = {
  {},
  {}
}

function make_input_history_entry(prefix, input)
  local up = input[prefix.." Up"]
  local down = input[prefix.." Down"]
  local left = input[prefix.." Left"]
  local right = input[prefix.." Right"]
  local direction = 5
  if down then
    if left then direction = 1
    elseif right then direction = 3
    else direction = 2 end
  elseif up then
    if left then direction = 7
    elseif right then direction = 9
    else direction = 8 end
  else
    if left then direction = 4
    elseif right then direction = 6
    else direction = 5 end
  end

  return {
    frame = gamestate.frame_number,
    direction = direction,
    buttons = {
      input[prefix.." Weak Punch"],
      input[prefix.." Medium Punch"],
      input[prefix.." Strong Punch"],
      input[prefix.." Weak Kick"],
      input[prefix.." Medium Kick"],
      input[prefix.." Strong Kick"]
    }
  }
end

function is_input_history_entry_equal(a, b)
  if (a.direction ~= b.direction) then return false end
  if (a.buttons[1] ~= b.buttons[1]) then return false end
  if (a.buttons[2] ~= b.buttons[2]) then return false end
  if (a.buttons[3] ~= b.buttons[3]) then return false end
  if (a.buttons[4] ~= b.buttons[4]) then return false end
  if (a.buttons[5] ~= b.buttons[5]) then return false end
  if (a.buttons[6] ~= b.buttons[6]) then return false end
  return true
end

function input_history_update(history, prefix, input)
  local entry = make_input_history_entry(prefix, input)

  if #history == 0 then
    table.insert(history, entry)
  else
    local last_entry = history[#history]
    if last_entry.frame ~= gamestate.frame_number and not is_input_history_entry_equal(entry, last_entry) then
      table.insert(history, entry)
    end
  end

  while #history > input_history_size_max do
    table.remove(history, 1)
  end
end

function input_history_draw(history, x, y, is_right, style)
  local step_y = 10
  local j = 0
  for i = #history, 1, -1 do
    local current_y = y + j * step_y
    local entry = history[i]

    local sign = 1
    if is_right then
      sign = -1
    end

    local controller_offset = 14 * sign
    draw_controller_small(entry, x + controller_offset, current_y, is_right, style)

    local next_frame = gamestate.frame_number
    if i < #history then
      next_frame = history[i + 1].frame
    end
    local frame_diff = next_frame - entry.frame
    local text = "-"
    if (frame_diff < 999) then
      text = string.format("%d", frame_diff)
    end

    local offset = -11
    if not is_right then
      offset = 8
      if (frame_diff < 999) then
        if (frame_diff >= 100) then offset = 0
        elseif (frame_diff >= 10) then offset = 4 end
      end
    end

    gui.text(x + offset, current_y + 1, text, 0xd6e3efff, 0x101000ff)


    j = j + 1
  end
end

function clear_input_history()
  input_history[1] = {}
  input_history[2] = {}
end
