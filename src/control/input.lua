local settings = require("src.settings")
local gamestate = require("src.gamestate")
local training = require("src.training")
local fd = require("src.modules.framedata")
local frame_data, is_slow_jumper, is_really_slow_jumper = fd.frame_data, fd.is_slow_jumper, fd.is_really_slow_jumper

local previous_input = nil

function queue_input_sequence(player, sequence, offset, allow_blocking)
  offset = offset or 0

  if sequence == nil or #sequence == 0 then
    return
  end

  if player.pending_input_sequence ~= nil then
    return
  end

  local seq = {}
  seq.sequence = copytable(sequence)
  seq.current_frame = 1 - offset
  seq.allow_blocking = false or allow_blocking

  player.pending_input_sequence = seq

end

local function queue_input_sequence_on_recovery(player, sequence, offset)
  if player.is_idle then
    queue_input_sequence(player, sequence, offset)
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
      queue_input_sequence(player, sequence, delta - #sequence)
    end
  end
end

local function process_pending_input_sequence(player, input)
  if player.pending_input_sequence == nil then
    return
  end

  -- Cancel all input
  if player.pending_input_sequence.allow_blocking then
    if player.flip_input then
      input[player.prefix.." Right"] = false
    else
      input[player.prefix.." Left"] = false
    end
  else
    input[player.prefix.." Left"] = false
    input[player.prefix.." Right"] = false
    input[player.prefix.." Down"] = false
  end
  input[player.prefix.." Up"] = false

  input[player.prefix.." Weak Punch"] = false
  input[player.prefix.." Medium Punch"] = false
  input[player.prefix.." Strong Punch"] = false
  input[player.prefix.." Weak Kick"] = false
  input[player.prefix.." Medium Kick"] = false
  input[player.prefix.." Strong Kick"] = false

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
  local gauges_offsets = { 0x0, 0x1C, 0x38, 0x54, 0x70 }

  if player.pending_input_sequence.current_frame >= 1 then
--     local s = ""
    local current_frame_input = player.pending_input_sequence.sequence[player.pending_input_sequence.current_frame]
    for i = 1, #current_frame_input do
      local input_name = player.prefix.." "
      if current_frame_input[i] == "forward" then
        if player.flip_input then input_name = input_name.."Right" else input_name = input_name.."Left" end
      elseif current_frame_input[i] == "back" then
        if player.flip_input then input_name = input_name.."Left" else input_name = input_name.."Right" end
      elseif current_frame_input[i] == "up" then
        input_name = input_name.."Up"
      elseif current_frame_input[i] == "down" then
        input_name = input_name.."Down"
      elseif current_frame_input[i] == "LP" then
        input_name = input_name.."Weak Punch"
      elseif current_frame_input[i] == "MP" then
        input_name = input_name.."Medium Punch"
      elseif current_frame_input[i] == "HP" then
        input_name = input_name.."Strong Punch"
      elseif current_frame_input[i] == "LK" then
        input_name = input_name.."Weak Kick"
      elseif current_frame_input[i] == "MK" then
        input_name = input_name.."Medium Kick"
      elseif current_frame_input[i] == "HK" then
        input_name = input_name.."Strong Kick"
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
        player.legs_state.l_legs_count = memory.writebyte(addresses.players[player.id].kyaku_l_count, 0x4)
        player.legs_state.reset_time = memory.writebyte(addresses.players[player.id].kyaku_reset_time, 0x63)
      elseif current_frame_input[i] == "legs_MK" then
        player.legs_state.m_legs_count = memory.writebyte(addresses.players[player.id].kyaku_m_count, 0x4)
        player.legs_state.reset_time = memory.writebyte(addresses.players[player.id].kyaku_reset_time, 0x63)
      elseif current_frame_input[i] == "legs_HK" then
        player.legs_state.h_legs_count = memory.writebyte(addresses.players[player.id].kyaku_h_count, 0x4)
        player.legs_state.reset_time = memory.writebyte(addresses.players[player.id].kyaku_reset_time, 0x63)
      elseif current_frame_input[i] == "legs_EXK" then
        player.legs_state.l_legs_count = memory.writebyte(addresses.players[player.id].kyaku_l_count, 0x4)
        player.legs_state.m_legs_count = memory.writebyte(addresses.players[player.id].kyaku_m_count, 0x4)
        player.legs_state.reset_time = memory.writebyte(addresses.players[player.id].kyaku_reset_time, 0x63)
      elseif current_frame_input[i] == "360" then
        memory.writebyte(player.kaiten_1_addr, 15)
        memory.writebyte(player.kaiten_2_addr, 15)
        memory.writebyte(player.kaiten_1_reset_addr, 31)
        memory.writebyte(player.kaiten_2_reset_addr, 31)
        -- if player.char_str == "hugo" then
        --   memory.writebyte(player.kaiten_completed_360_addr, 56)
        -- end
      elseif current_frame_input[i] == "720" then
        memory.writebyte(player.kaiten_1_addr, 15)
        memory.writebyte(player.kaiten_1_reset_addr, 31)
        -- memory.writebyte(player.kaiten_completed_360_addr, 48)
      end
      input[input_name] = true
--       s = s..input_name
    end
  end
  --print(s)

  player.pending_input_sequence.current_frame = player.pending_input_sequence.current_frame + 1
  if player.pending_input_sequence.current_frame > #player.pending_input_sequence.sequence then
    player.pending_input_sequence = nil
  end
end

function clear_input_sequence(player)
  player.pending_input_sequence = nil
end

function is_playing_input_sequence(player)
  return player.pending_input_sequence ~= nil and player.pending_input_sequence.current_frame >= 1
end

function make_input_empty(input)
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

function clear_directional_input(input)
  if input == nil then
    return
  end

  input["P1 Up"] = false
  input["P1 Down"] = false
  input["P1 Left"] = false
  input["P1 Right"] = false
  input["P2 Up"] = false
  input["P2 Down"] = false
  input["P2 Left"] = false
  input["P2 Right"] = false
end

function clear_p1_buttons(input)
  if input == nil then
    return
  end
  input["P1 Weak Punch"] = false
  input["P1 Medium Punch"] = false
  input["P1 Strong Punch"] = false
  input["P1 Weak Kick"] = false
  input["P1 Medium Kick"] = false
  input["P1 Strong Kick"] = false
end

function make_input_sequence(char_str, counter_attack_settings)

  --recording
  if counter_attack_settings.ca_type == 5 then
    return nil
  end

  local sequence = {}
  local offset = 0
  if counter_attack_settings.ca_type == 2 then

    local stick = counter_attack_motion[counter_attack_settings.motion]
    local button = counter_attack_normal_button[counter_attack_settings.normal_button]
    if stick == "kara_throw" then
      sequence = {{"LP","LK"}}
      table.insert(sequence, 1, counter_attack_button_input[counter_attack_settings.normal_button])
      return sequence, offset
    end
    if      stick == "dir_5"    then sequence = { { } }
    elseif  stick == "dir_6" then sequence = { { "forward" } }
    elseif  stick == "dir_4"    then sequence = { { "back" } }
    elseif  stick == "dir_2"    then sequence = { { "down" } }
    elseif  stick == "dir_8"    then sequence = { { "up" } }
    elseif  stick == "dir_1"    then sequence = { { "down", "back"} }
    elseif  stick == "dir_3"    then sequence = { { "down", "forward"} }
    elseif  stick == "hjump_neutral" then
      sequence = { { "down" }, { "up" }, { "up" } }
      offset = 2
    elseif  stick == "dir_9" then
      sequence = { { "forward", "up" }, { "forward", "up" }, { "forward", "up" }}
      offset = 2
    elseif  stick == "hjump_forward" then
      sequence = { { "down" }, { "forward", "up" }, { "forward", "up" } }
      offset = 2
    elseif  stick == "dir_7" then
      sequence = { { "back", "up" }, { "back", "up" } }
      offset = 2
    elseif  stick == "hjump_back" then
      sequence = { { "down" }, { "back", "up" }, { "back", "up" } }
      offset = 2
    elseif  stick == "back_dash" then sequence = { { "back" }, {}, { "back" } }
      return sequence
    elseif  stick == "forward_dash" then sequence = { { "forward" }, {}, { "forward" } }
      return sequence
    end

    if     button == "none" then
    elseif button == "EXP"  then
      table.insert(sequence[#sequence], "MP")
      table.insert(sequence[#sequence], "HP")
    elseif button == "EXK"  then
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
        for i = 1, 4 do
          table.insert(sequence,{})
        end
        if(is_slow_jumper(char_str)) then
          table.insert(sequence,#sequence,{})
        elseif is_really_slow_jumper(char_str) then
          table.insert(sequence,#sequence,{})
          table.insert(sequence,#sequence,{})
        end
      elseif stick == "hjump_back" or stick == "hjump_neutral" or stick == "hjump_forward" then
        for i = 1, 6 do
          table.insert(sequence,{})
        end
        if(is_slow_jumper(char_str)) then
          table.insert(sequence,#sequence,{})
        elseif is_really_slow_jumper(char_str) then
          table.insert(sequence,#sequence,{})
          table.insert(sequence,#sequence,{})
        end
      end
      table.insert(sequence[#sequence], button)
    end
  elseif counter_attack_settings.ca_type == 3 then
    local move_input = counter_attack_special_inputs[counter_attack_settings.special]
    local button = counter_attack_special_buttons[counter_attack_settings.special_button]
    for i = 1, #move_input do
      sequence[i] = {}
      for j = 1, #move_input[i]  do
          table.insert(sequence[i], move_input[i][j])
      end
    end
    local i = 1
    while i <= #sequence do
      local j = 1
      while j <= #sequence[i] do
        if sequence[i][j] == "button" then
          if button == "EXP"  then
            table.remove(sequence[i], j)
            table.insert(sequence[i], j, "LP")
            table.insert(sequence[i], j, "MP")
          elseif button == "EXK"  then
            table.remove(sequence[i], j)
            table.insert(sequence[i], j, "LK")
            table.insert(sequence[i], j, "MK")
          else
            table.remove(sequence[i], j)
            table.insert(sequence[i], j, button)
          end
        end
        j = j + 1
      end
      i = i + 1
    end
    if counter_attack_special_names[counter_attack_settings.special] == "hyakuretsukyaku" then
      if button == "EXK"  then
        sequence = {{"legs_" .. button, "LK", "MK"}}
      else
        sequence = {{"legs_" .. button, button}}
      end
    end
    if counter_attack_special_names[counter_attack_settings.special] == "kara_capture_and_deadly_blow" then
      offset = 1
    elseif counter_attack_special_names[counter_attack_settings.special] == "kara_karakusa_lk" then
      offset = 7
    elseif counter_attack_special_names[counter_attack_settings.special] == "kara_karakusa_hk" then
      offset = 1
    elseif counter_attack_special_names[counter_attack_settings.special] == "kara_zenpou_yang" then
      offset = 1
    elseif counter_attack_special_names[counter_attack_settings.special] == "kara_zenpou_yun" then
      offset = 1
    elseif counter_attack_special_names[counter_attack_settings.special] == "kara_power_bomb" then
      offset = 1
    elseif counter_attack_special_names[counter_attack_settings.special] == "kara_niouriki" then
      offset = 1
    end
  elseif counter_attack_settings.ca_type == 4 then
    local name = counter_attack_option_select_names[counter_attack_settings.option_select]
    if name == "guard_jump_back" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"back","up"},{"back","up"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"}}
    elseif name == "guard_jump_neutral" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"up"},{"up"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"}}
    elseif name == "guard_jump_forward" then
        sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"forward","up"},{"forward","up"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"}}
    elseif name == "guard_jump_back_air_parry" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"back","up"},{"back","up"},{},{},{},{"forward"}}
      if(is_slow_jumper(char_str)) then
        table.insert(sequence,#sequence,{})
      elseif is_really_slow_jumper(char_str) then
        table.insert(sequence,#sequence,{})
        table.insert(sequence,#sequence,{})
      end
    elseif name == "guard_jump_neutral_air_parry" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"up"},{"up"},{},{},{},{"forward"}}
      if(is_slow_jumper(char_str)) then
        table.insert(sequence,#sequence,{})
      elseif is_really_slow_jumper(char_str) then
        table.insert(sequence,#sequence,{})
        table.insert(sequence,#sequence,{})
      end
    elseif name == "guard_jump_forward_air_parry" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"up","forward"},{"up","forward"},{},{},{},{"forward"}}
      if(is_slow_jumper(char_str)) then
        table.insert(sequence,#sequence,{})
      elseif is_really_slow_jumper(char_str) then
        table.insert(sequence,#sequence,{})
        table.insert(sequence,#sequence,{})
      end
    elseif name == "crouch_tech" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back","LP","LK"},{"down","back","LP","LK"}}
    elseif name == "block_late_tech" then
      sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"back","LP","LK"},{"back","LP","LK"}}
    elseif name == "shita_mae" then
      sequence = {{"down"},{},{},{},{},{},{},{},{},{},{},{"forward"},{},{},{},{},{},{},{},{},{},{}}
    elseif name == "mae_shita" then
      sequence = {{"forward"},{},{},{},{},{},{},{},{},{},{},{"down"},{},{},{},{},{},{},{},{},{},{}}
    elseif name == "parry_dash" then
      sequence = {{"forward"},{},{},{},{},{},{},{"forward"},{},{},{},{},{},{},{},{},{},{}}
    end
  end
  return sequence, offset
end

-- swap inputs
local function swap_inputs(out_input_table)
  local function swap(input)
    local carry = out_input_table["P1 "..input]
    out_input_table["P1 "..input] = out_input_table["P2 "..input]
    out_input_table["P2 "..input] = carry
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
local function interpret_input(player, dummy)
  local input_pressed = (not training.swap_characters and player.input.pressed.coin) or (training.swap_characters and dummy.input.pressed.coin)
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

function queue_input_from_json(player, file)
  local path = string.format("%s%s",saved_recordings_path, file)
  local recording = read_object_from_json_file(path)
  if not recording then
    print(string.format("Error: Failed to load recording from \"%s\"", path))
  else
    recording_slots[settings.training.current_recording_slot].inputs = recording
    print(string.format("Loaded \"%s\" to slot %d", path, settings.training.current_recording_slot))
  end
  queue_input_sequence(player, recording_slots[1].inputs)
end

function is_previous_input_neutral(player)
  if previous_input then
    if previous_input[player.prefix.." Up"] == false
    and previous_input[player.prefix.." Down"] == false
    and previous_input[player.prefix.." Left"] == false
    and previous_input[player.prefix.." Right"] == false then
      return true
    end
  end
  return false
end

function log_input(players)
  if previous_input then
    function log(player_object, name, short_name)
      short_name = short_name or name
      local full_name = player_object.prefix.." "..name
      if not previous_input[full_name] and input[full_name] then
        log(player_object.prefix, "input", short_name.." 1")
      elseif previous_input[full_name] and not input[full_name] then
        log(player_object.prefix, "input", short_name.." 0")
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

local input_module = {
  queue_input_sequence = queue_input_sequence,
  queue_input_sequence_on_recovery = queue_input_sequence_on_recovery,
  process_pending_input_sequence = process_pending_input_sequence,
  swap_inputs = swap_inputs,
  interpret_input = interpret_input,
  make_input_empty = make_input_empty,
  clear_directional_input = clear_directional_input,
  clear_p1_buttons = clear_p1_buttons,
}

setmetatable(input_module, {
  __index = function(_, key)
    if key == "previous_input" then
      return previous_input
    end
  end,

  __newindex = function(_, key, value)
    if key == "previous_input" then
      previous_input = value
    else
      rawset(input_module, key, value)
    end
  end
})

return input_module