require("src/startup")

print("-----------------------------")
print("  3rd_training.lua - "..script_version.."")
print("  Training mode for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/effie3rd/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Enter training menu by pressing \"Start\" while in game")
print("- Enter/exit recording mode by double tapping \"Coin\"")
print("- In recording mode, press \"Coin\" again to start/stop recording")
print("- In normal mode, press \"Coin\" to start/stop replay")
print("- Lua Hotkey 1 (alt+1) to return to character select screen")
print("")


-- Kudos to indirect contributors:
-- *esn3s* for his work on 3s frame data : http://baston.esn3s.com/
-- *dammit* for his work on 3s hitbox display script : https://dammit.typepad.com/blog/2011/10/improved-3rd-strike-hitboxes.html
-- *furitiem* for his prior work on 3s C# training program : https://www.youtube.com/watch?v=vE27xe0QM64
-- *crytal_cube99* for his prior work on 3s training & trial scripts : https://ameblo.jp/3fv/

-- Thanks to *speedmccool25* for recording all the 4rd strike frame data
-- Thanks to *ProfessorAnon* for the Charge and Hyakuretsu Kyaku special training mode
-- Thanks to *sammygutierrez* for the damage info display

-- FBA-RR Scripting reference:
-- http://tasvideos.org/EmulatorResources/VBA/LuaScriptingFunctions.html
-- https://github.com/TASVideos/mame-rr/wiki/Lua-scripting-functions

-- Resources
-- https://github.com/Jesuszilla/mame-rr-scripts/blob/master/framedata.lua
-- https://imgur.com/gallery/0Tsl7di

-- Lua-GD Scripting reference:
-- https://www.ittner.com.br/lua-gd/manual.html

-- Includes
require("src/tools")
local timer = perf_timer:new()
require("src/memory_addresses")
require("src/write_memory")
require("src/draw")
require("src/display")
require("src/hud")
require("src/menu")
require("src/menu_widgets")
require("src/framedata")
require("src/gamestate")
require("src/input_history")
require("src/attack_data")
require("src/frame_advantage")
require("src/character_select")
require("src/jumpins")
require("src/hadou_matsuri")
require("src/record_framedata")
require("src/debug")

recording_slot_count = 16

-- debug options
developer_mode = true -- Unlock frame data recording options. Touch at your own risk since you may use those options to fuck up some already recorded frame data
assert_enabled = developer_mode or assert_enabled
debug_wakeup = false
log_enabled = developer_mode or log_enabled
log_categories_display =
{
  input =                     { history = true, print = false },
  projectiles =               { history = true, print = false },
  fight =                     { history = false, print = false },
  animation =                 { history = false, print = false },
  parry_training_FORWARD =    { history = false, print = false },
  blocking =                  { history = true, print = false },
  counter_attack =            { history = false, print = false },
  block_string =              { history = true, print = false },
  frame_advantage =           { history = false, print = false },
} or log_categories_display

saved_recordings_path = "saved/recordings/"
training_settings_file = "training_settings.json"

is_in_challenge = false
disable_display = false

command_queue = {}

-- players
function queue_input_sequence(_player_obj, _sequence, _offset, _allow_blocking)
  _offset = _offset or 0

  if _sequence == nil or #_sequence == 0 then
    return
  end

  if _player_obj.pending_input_sequence ~= nil then
    return
  end

  local _seq = {}
  _seq.sequence = copytable(_sequence)
  _seq.current_frame = 1 - _offset
  _seq.allow_blocking = false or _allow_blocking

  _player_obj.pending_input_sequence = _seq

end

function process_pending_input_sequence(_player_obj, _input)
  if _player_obj.pending_input_sequence == nil then
    return
  end
  if is_menu_open then
    return
  end
--   if not is_in_match then
--     return
--   end

  -- Cancel all input
  if _player_obj.pending_input_sequence.allow_blocking then
    if _player_obj.flip_input then
      _input[_player_obj.prefix.." Right"] = false
    else
      _input[_player_obj.prefix.." Left"] = false
    end
  else
    _input[_player_obj.prefix.." Left"] = false
    _input[_player_obj.prefix.." Right"] = false
    _input[_player_obj.prefix.." Down"] = false
  end
  _input[_player_obj.prefix.." Up"] = false

  _input[_player_obj.prefix.." Weak Punch"] = false
  _input[_player_obj.prefix.." Medium Punch"] = false
  _input[_player_obj.prefix.." Strong Punch"] = false
  _input[_player_obj.prefix.." Weak Kick"] = false
  _input[_player_obj.prefix.." Medium Kick"] = false
  _input[_player_obj.prefix.." Strong Kick"] = false

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
  local _gauges_base = 0
  if _player_obj.id == 1 then
    _gauges_base = 0x020259D8
  elseif _player_obj.id == 2 then
    _gauges_base = 0x02025FF8
  end
  local _gauges_offsets = { 0x0, 0x1C, 0x38, 0x54, 0x70 }

  if _player_obj.pending_input_sequence.current_frame >= 1 then
--     local _s = ""
    local _current_frame_input = _player_obj.pending_input_sequence.sequence[_player_obj.pending_input_sequence.current_frame]
    for i = 1, #_current_frame_input do
      local _input_name = _player_obj.prefix.." "
      if _current_frame_input[i] == "forward" then
        if _player_obj.flip_input then _input_name = _input_name.."Right" else _input_name = _input_name.."Left" end
      elseif _current_frame_input[i] == "back" then
        if _player_obj.flip_input then _input_name = _input_name.."Left" else _input_name = _input_name.."Right" end
      elseif _current_frame_input[i] == "up" then
        _input_name = _input_name.."Up"
      elseif _current_frame_input[i] == "down" then
        _input_name = _input_name.."Down"
      elseif _current_frame_input[i] == "LP" then
        _input_name = _input_name.."Weak Punch"
      elseif _current_frame_input[i] == "MP" then
        _input_name = _input_name.."Medium Punch"
      elseif _current_frame_input[i] == "HP" then
        _input_name = _input_name.."Strong Punch"
      elseif _current_frame_input[i] == "LK" then
        _input_name = _input_name.."Weak Kick"
      elseif _current_frame_input[i] == "MK" then
        _input_name = _input_name.."Medium Kick"
      elseif _current_frame_input[i] == "HK" then
        _input_name = _input_name.."Strong Kick"
      elseif _current_frame_input[i] == "h_charge" then
        if _player_obj.char_str == "urien" then
          memory.writeword(_gauges_base + _gauges_offsets[1], 0xFF00)
        elseif _player_obj.char_str == "oro" then
          memory.writeword(_gauges_base + _gauges_offsets[3], 0xFF00)
        elseif _player_obj.char_str == "chunli" then
        elseif _player_obj.char_str == "q" then
          memory.writeword(_gauges_base + _gauges_offsets[1], 0xFF00)
          memory.writeword(_gauges_base + _gauges_offsets[2], 0xFF00)
        elseif _player_obj.char_str == "remy" then
          memory.writeword(_gauges_base + _gauges_offsets[2], 0xFF00)
          memory.writeword(_gauges_base + _gauges_offsets[3], 0xFF00)
        elseif _player_obj.char_str == "alex" then
          memory.writeword(_gauges_base + _gauges_offsets[5], 0xFF00)
        end
      elseif _current_frame_input[i] == "v_charge" then
        if _player_obj.char_str == "urien" then
          memory.writeword(_gauges_base + _gauges_offsets[2], 0xFF00)
          memory.writeword(_gauges_base + _gauges_offsets[4], 0xFF00)
        elseif _player_obj.char_str == "oro" then
          memory.writeword(_gauges_base + _gauges_offsets[1], 0xFF00)
        elseif _player_obj.char_str == "chunli" then
          memory.writeword(_gauges_base + _gauges_offsets[1], 0xFF00)
        elseif _player_obj.char_str == "q" then
        elseif _player_obj.char_str == "remy" then
          memory.writeword(_gauges_base + _gauges_offsets[1], 0xFF00)
        elseif _player_obj.char_str == "alex" then
          memory.writeword(_gauges_base + _gauges_offsets[4], 0xFF00)
        end
      elseif _current_frame_input[i] == "legs_LK" then
        _player_obj.legs_state.l_legs_count = memory.writebyte(addresses.players[_player_obj.id].kyaku_l_count, 0x4)
        _player_obj.legs_state.reset_time = memory.writebyte(addresses.players[_player_obj.id].kyaku_reset_time, 0x63)
      elseif _current_frame_input[i] == "legs_MK" then
        _player_obj.legs_state.m_legs_count = memory.writebyte(addresses.players[_player_obj.id].kyaku_m_count, 0x4)
        _player_obj.legs_state.reset_time = memory.writebyte(addresses.players[_player_obj.id].kyaku_reset_time, 0x63)
      elseif _current_frame_input[i] == "legs_HK" then
        _player_obj.legs_state.h_legs_count = memory.writebyte(addresses.players[_player_obj.id].kyaku_h_count, 0x4)
        _player_obj.legs_state.reset_time = memory.writebyte(addresses.players[_player_obj.id].kyaku_reset_time, 0x63)
      elseif _current_frame_input[i] == "legs_EXK" then
        _player_obj.legs_state.l_legs_count = memory.writebyte(addresses.players[_player_obj.id].kyaku_l_count, 0x4)
        _player_obj.legs_state.m_legs_count = memory.writebyte(addresses.players[_player_obj.id].kyaku_m_count, 0x4)
        _player_obj.legs_state.reset_time = memory.writebyte(addresses.players[_player_obj.id].kyaku_reset_time, 0x63)
      elseif _current_frame_input[i] == "360" then
        memory.writebyte(_player_obj.kaiten_1_addr, 15)
        memory.writebyte(_player_obj.kaiten_2_addr, 15)
        memory.writebyte(_player_obj.kaiten_1_reset_addr, 31)
        memory.writebyte(_player_obj.kaiten_2_reset_addr, 31)
        if _player_obj.char_str == "hugo" then
          -- memory.writebyte(_player_obj.kaiten_completed_360_addr, 56)
        end
      elseif _current_frame_input[i] == "720" then
        memory.writebyte(_player_obj.kaiten_1_addr, 15)
        memory.writebyte(_player_obj.kaiten_1_reset_addr, 31)
        -- memory.writebyte(_player_obj.kaiten_completed_360_addr, 48)
      end
      _input[_input_name] = true
--       _s = _s.._input_name
    end
  end
  --print(_s)

  _player_obj.pending_input_sequence.current_frame = _player_obj.pending_input_sequence.current_frame + 1
  if _player_obj.pending_input_sequence.current_frame > #_player_obj.pending_input_sequence.sequence then
    _player_obj.pending_input_sequence = nil
  end
end

function clear_input_sequence(_player_obj)
  _player_obj.pending_input_sequence = nil
end

function is_playing_input_sequence(_player_obj)
  return _player_obj.pending_input_sequence ~= nil and _player_obj.pending_input_sequence.current_frame >= 1
end

function make_input_empty(_input)
  if _input == nil then
    return
  end

  _input["P1 Up"] = false
  _input["P1 Down"] = false
  _input["P1 Left"] = false
  _input["P1 Right"] = false
  _input["P1 Weak Punch"] = false
  _input["P1 Medium Punch"] = false
  _input["P1 Strong Punch"] = false
  _input["P1 Weak Kick"] = false
  _input["P1 Medium Kick"] = false
  _input["P1 Strong Kick"] = false
  _input["P1 Start"] = false
  _input["P1 Coin"] = false
  _input["P2 Up"] = false
  _input["P2 Down"] = false
  _input["P2 Left"] = false
  _input["P2 Right"] = false
  _input["P2 Weak Punch"] = false
  _input["P2 Medium Punch"] = false
  _input["P2 Strong Punch"] = false
  _input["P2 Weak Kick"] = false
  _input["P2 Medium Kick"] = false
  _input["P2 Strong Kick"] = false
  _input["P2 Start"] = false
  _input["P2 Coin"] = false
end

function clear_directional_input(_input)
  if _input == nil then
    return
  end

  _input["P1 Up"] = false
  _input["P1 Down"] = false
  _input["P1 Left"] = false
  _input["P1 Right"] = false
  _input["P2 Up"] = false
  _input["P2 Down"] = false
  _input["P2 Left"] = false
  _input["P2 Right"] = false
end

function clear_p1_input(_input)
  if _input == nil then
    return
  end

  _input["P1 Up"] = false
  _input["P1 Down"] = false
  _input["P1 Left"] = false
  _input["P1 Right"] = false
  _input["P1 Weak Punch"] = false
  _input["P1 Medium Punch"] = false
  _input["P1 Strong Punch"] = false
  _input["P1 Weak Kick"] = false
  _input["P1 Medium Kick"] = false
  _input["P1 Strong Kick"] = false
  _input["P1 Start"] = false
end

function clear_p1_buttons(_input)
  if _input == nil then
    return
  end
  _input["P1 Weak Punch"] = false
  _input["P1 Medium Punch"] = false
  _input["P1 Strong Punch"] = false
  _input["P1 Weak Kick"] = false
  _input["P1 Medium Kick"] = false
  _input["P1 Strong Kick"] = false
end


-- training settings
pose = {
  "standing",
  "crouching",
  "jumping",
  "highjumping",
}

stick_gesture = {
  "none",
  "QCF",
  "QCB",
  "HCF",
  "HCB",
  "DPF",
  "DPB",
  "HCharge",
  "VCharge",
  "360",
  "DQCF",
  "720",
  "forward",
  "back",
  "down",
  "jump",
  "super jump",
  "forward jump",
  "forward super jump",
  "back jump",
  "back super jump",
  "back dash",
  "forward dash",
  "guard jump (See Readme)",
  --"guard back jump",
  --"guard forward jump",
  "Shun Goku Satsu", -- Gouki hidden SA1
  "Kongou Kokuretsu Zan", -- Gouki hidden SA2
}
if is_4rd_strike then
  table.insert(stick_gesture, "Demon Armageddon") -- Gouki SA3
end

button_gesture =
{
  "none",
  "recording",
  "LP",
  "MP",
  "HP",
  "EXP",
  "LK",
  "MK",
  "HK",
  "EXK",
  "LP+LK",
  "MP+MK",
  "HP+HK",
}

slow_jumpers =
{
  "alex",
  "necro",
  "urien",
  "remy",
  "twelve",
  "oro"
}
really_slow_jumpers =
{
  "q",
  "hugo"
}

function is_slow_jumper(_str)
  for i = 1, #slow_jumpers do
    if _str == slow_jumpers[i] then
      return true
    end
  end
  return false
end

function is_really_slow_jumper(_str)
  for i = 1, #really_slow_jumpers do
    if _str == really_slow_jumpers[i] then
      return true
    end
  end
  return false
end

function make_input_sequence(_char_str, _counter_attack_settings)

  --recording
  if _counter_attack_settings.ca_type == 5 then
    return nil
  end

  local _sequence = {}
  local _offset = 0
  if _counter_attack_settings.ca_type == 2 then

    local _stick = counter_attack_motion[_counter_attack_settings.motion]
    local _button = counter_attack_button[_counter_attack_settings.button]
    if _stick == "kara_throw" then
      _sequence = {{"LP","LK"}}
      table.insert(_sequence, 1, counter_attack_button_input[_counter_attack_settings.button])
      return _sequence, _offset
    end
    if      _stick == "dir_5"    then _sequence = { { } }
    elseif  _stick == "dir_6" then _sequence = { { "forward" } }
    elseif  _stick == "dir_4"    then _sequence = { { "back" } }
    elseif  _stick == "dir_2"    then _sequence = { { "down" } }
    elseif  _stick == "dir_8"    then _sequence = { { "up" } }
    elseif  _stick == "dir_1"    then _sequence = { { "down", "back"} }
    elseif  _stick == "dir_3"    then _sequence = { { "down", "forward"} }
    elseif  _stick == "hjump_neutral" then
      _sequence = { { "down" }, { "up" }, { "up" } }
      _offset = 2
    elseif  _stick == "dir_9" then
      _sequence = { { "forward", "up" }, { "forward", "up" }, { "forward", "up" }}
      _offset = 2
    elseif  _stick == "hjump_forward" then
      _sequence = { { "down" }, { "forward", "up" }, { "forward", "up" } }
      _offset = 2
    elseif  _stick == "dir_7" then
      _sequence = { { "back", "up" }, { "back", "up" } }
      _offset = 2
    elseif  _stick == "hjump_back" then
      _sequence = { { "down" }, { "back", "up" }, { "back", "up" } }
      _offset = 2
    elseif  _stick == "back_dash" then _sequence = { { "back" }, {}, { "back" } }
      return _sequence
    elseif  _stick == "forward_dash" then _sequence = { { "forward" }, {}, { "forward" } }
      return _sequence
    end

    if     _button == "none" then
    elseif _button == "EXP"  then
      table.insert(_sequence[#_sequence], "MP")
      table.insert(_sequence[#_sequence], "HP")
    elseif _button == "EXK"  then
      table.insert(_sequence[#_sequence], "MK")
      table.insert(_sequence[#_sequence], "HK")
    elseif _button == "LP+LK" then
      table.insert(_sequence[#_sequence], "LP")
      table.insert(_sequence[#_sequence], "LK")
    elseif _button == "MP+MK" then
      table.insert(_sequence[#_sequence], "MP")
      table.insert(_sequence[#_sequence], "MK")
    elseif _button == "HP+HK" then
      table.insert(_sequence[#_sequence], "HP")
      table.insert(_sequence[#_sequence], "HK")
    else
      if _stick == "dir_7" or _stick == "dir_8" or _stick == "dir_9" then
        for i = 1, 4 do
          table.insert(_sequence,{})
        end
        if(is_slow_jumper(_char_str)) then
          table.insert(_sequence,#_sequence,{})
        elseif is_really_slow_jumper(_char_str) then
          table.insert(_sequence,#_sequence,{})
          table.insert(_sequence,#_sequence,{})
        end
      elseif _stick == "hjump_back" or _stick == "hjump_neutral" or _stick == "hjump_forward" then
        for i = 1, 6 do
          table.insert(_sequence,{})
        end
        if(is_slow_jumper(_char_str)) then
          table.insert(_sequence,#_sequence,{})
        elseif is_really_slow_jumper(_char_str) then
          table.insert(_sequence,#_sequence,{})
          table.insert(_sequence,#_sequence,{})
        end
      end
      table.insert(_sequence[#_sequence], _button)
    end
  elseif _counter_attack_settings.ca_type == 3 then
    local _move_input = counter_attack_special_inputs[_counter_attack_settings.special]
    local _button = counter_attack_special_button[_counter_attack_settings.special_button]
    for i = 1, #_move_input do
      _sequence[i] = {}
      for j = 1, #_move_input[i]  do
          table.insert(_sequence[i], _move_input[i][j])
      end
    end
    local i = 1
    while i <= #_sequence do
      local j = 1
      while j <= #_sequence[i] do
        if _sequence[i][j] == "button" then
          if _button == "EXP"  then
            table.remove(_sequence[i], j)
            table.insert(_sequence[i], j, "LP")
            table.insert(_sequence[i], j, "MP")
          elseif _button == "EXK"  then
            table.remove(_sequence[i], j)
            table.insert(_sequence[i], j, "LK")
            table.insert(_sequence[i], j, "MK")
          else
            table.remove(_sequence[i], j)
            table.insert(_sequence[i], j, _button)
          end
        end
        j = j + 1
      end
      i = i + 1
    end
    if counter_attack_special[_counter_attack_settings.special] == "hyakuretsukyaku" then
      if _button == "EXK"  then
        _sequence = {{"legs_" .. _button, "LK", "MK"}}
      else
        _sequence = {{"legs_" .. _button, _button}}
      end
    end
    if counter_attack_special[_counter_attack_settings.special] == "kara_capture_and_deadly_blow" then
      _offset = 1
    elseif counter_attack_special[_counter_attack_settings.special] == "kara_karakusa_lk" then
      _offset = 7
    elseif counter_attack_special[_counter_attack_settings.special] == "kara_karakusa_hk" then
      _offset = 1
    elseif counter_attack_special[_counter_attack_settings.special] == "kara_zenpou_yang" then
      _offset = 1
    elseif counter_attack_special[_counter_attack_settings.special] == "kara_zenpou_yun" then
      _offset = 1
    elseif counter_attack_special[_counter_attack_settings.special] == "kara_power_bomb" then
      _offset = 1
    elseif counter_attack_special[_counter_attack_settings.special] == "kara_niouriki" then
      _offset = 1
    end
  elseif _counter_attack_settings.ca_type == 4 then
    local _os = counter_attack_option_select[_counter_attack_settings.option_select]
    if _os == "guard_jump_back" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"back","up"},{"back","up"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"}}
    elseif _os == "guard_jump_neutral" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"up"},{"up"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"}}
    elseif _os == "guard_jump_forward" then
        _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"forward","up"},{"forward","up"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"}}
    elseif _os == "guard_jump_back_air_parry" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"back","up"},{"back","up"},{},{},{},{"forward"}}
      if(is_slow_jumper(_char_str)) then
        table.insert(_sequence,#_sequence,{})
      elseif is_really_slow_jumper(_char_str) then
        table.insert(_sequence,#_sequence,{})
        table.insert(_sequence,#_sequence,{})
      end
    elseif _os == "guard_jump_neutral_air_parry" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"up"},{"up"},{},{},{},{"forward"}}
      if(is_slow_jumper(_char_str)) then
        table.insert(_sequence,#_sequence,{})
      elseif is_really_slow_jumper(_char_str) then
        table.insert(_sequence,#_sequence,{})
        table.insert(_sequence,#_sequence,{})
      end
    elseif _os == "guard_jump_forward_air_parry" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"up","forward"},{"up","forward"},{},{},{},{"forward"}}
      if(is_slow_jumper(_char_str)) then
        table.insert(_sequence,#_sequence,{})
      elseif is_really_slow_jumper(_char_str) then
        table.insert(_sequence,#_sequence,{})
        table.insert(_sequence,#_sequence,{})
      end
    elseif _os == "crouch_tech" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back","LP","LK"},{"down","back","LP","LK"}}
    elseif _os == "block_throw" then
      _sequence = {{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"down","back"},{"back","LP","LK"},{"back","LP","LK"}}
    elseif _os == "shita_mae" then
      _sequence = {{"down"},{},{},{},{},{},{},{},{},{},{},{"forward"},{},{},{},{},{},{},{},{},{},{}}
      elseif _os == "mae_shita" then
        _sequence = {{"forward"},{},{},{},{},{},{},{},{},{},{},{"down"},{},{},{},{},{},{},{},{},{},{}}
    end
  end
  return _sequence, _offset
end

quick_stand =
{
  "menu_off",
  "menu_on",
  "menu_random",
}

blocking_style =
{
  "block",
  "parry",
  "red_parry",
}

blocking_mode =
{
  "menu_off",
  "menu_on",
  "menu_first_hit",
  "menu_random",
}

counter_attack_type_index = 1

counter_attack_type =
{
  "none",
  "normal_attack",
  "special_sa",
  "option_select",
  "recording"
}

counter_attack_motion =
{
  "dir_5",
  "dir_6",
  "dir_3",
  "dir_2",
  "dir_1",
  "dir_4",
  "dir_7",
  "dir_8",
  "dir_9",
  "hjump_back",
  "hjump_neutral",
  "hjump_forward",
  "back_dash",
  "forward_dash",
  "kara_throw"
}

counter_attack_motion_input =
{
  {{"neutral"}},
  {{"forward"}},
  {{"down","forward"}},
  {{"down"}},
  {{"down","back"}},
  {{"back"}},
  {{"up","back"}},
  {{"up"}},
  {{"up","forward"}},
  {{"down"},{"up","back"}},
  {{"down"},{"up"}},
  {{"down"},{"up","forward"}},
  {{"back"},{"back"}},
  {{"forward"},{"forward"}},
  {{"maru"},{"tilda"},{"LP","LK"}}
}

counter_attack_button_default =
{
  "none",
  "LP",
  "MP",
  "HP",
  "LK",
  "MK",
  "HK",
  "LP+LK",
  "MP+MK",
  "HP+HK"
}

counter_attack_button = counter_attack_button_default

counter_attack_special = {}
counter_attack_special_button = {}

counter_attack_option_select =
{
  "guard_jump_back",
  "guard_jump_neutral",
  "guard_jump_forward",
  "guard_jump_back_air_parry",
  "guard_jump_neutral_air_parry",
  "guard_jump_forward_air_parry",
  "crouch_tech",
  "block_throw",
  "shita_mae",
  "mae_shita"
}

guard_jumps =
{
  "guard_jump_back",
  "guard_jump_neutral",
  "guard_jump_forward",
  "guard_jump_back_air_parry",
  "guard_jump_neutral_air_parry",
  "guard_jump_forward_air_parry"
}

function is_guard_jump(_str)
  for i = 1, #guard_jumps do
    if _str == guard_jumps[i] then
      return true
    end
  end
  return false
end

mash_stun_mode =
{
  "menu_off",
  "menu_fastest",
  "menu_realistic",
}
tech_throws_mode =
{
  "menu_on",
  "menu_off",
  "menu_random",
}

hit_type =
{
  "normal",
  "low",
  "overhead",
}

life_mode =
{
  "no_refill",
  "refill",
  "infinite"
}

meter_mode =
{
  "no_refill",
  "refill",
  "infinite"
}

stun_mode =
{
  "normal",
  "no_stun",
  "delayed_reset"
}

standing_state =
{
  "knockeddown",
  "standing",
  "crouched",
  "airborne",
}

players = {
  "Player 1",
  "Player 2",
}

player_options_list = {"off","P1","P2","P1+P2"}

display_input_history_mode = {"off","P1","P2","P1+P2","moving"}

gauge_refill_mode = {"off", "refill_max", "reset_value", "infinite" }

display_attack_bars_mode =
{
  "menu_off",
  "1_line",
  "2_lines"
}

special_training_mode = {
  "none",
  "parry",
  "charge",
  "Hyakuretsu Kyaku (Chun Li)"
}

language = {
  "english",
  "japanese"
}

lang_code = {
  "en",
  "jp"
}

stage_map = {}
stage_list = {"menu_off","menu_random"}
for i = 0, 20 do
  local _name = "menu_" .. stages[i].name
  if not table_contains_deep(stage_list, _name) then
    table.insert(stage_list, _name)
    stage_map[#stage_list] = i
  end
end


challenge_mode = {
  "hadou_festival",
  "defense"
}

function input_to_text(_t)
  local _result = {}
  for i = 1, #_t do
    local _text = ""
    for j = 1, #_t[i] do
      if _t[i][j] == "down" then
        _text = _text .. "D"
      elseif _t[i][j] == "up" then
        _text = _text .. "U"
      elseif _t[i][j] == "forward" then
        _text = _text .. "F"
      elseif _t[i][j] == "back" then
        _text = _text .. "B"
      end
    end
    if _text ~= "" then
      _text = _text .. "+"
    end
    for j = 1, #_t[i] do
      if _t[i][j] == "LP" or _t[i][j] == "MP" or _t[i][j] == "HP"
      or _t[i][j] == "LK" or _t[i][j] == "MK" or _t[i][j] == "HK" then
         _text = _text .. _t[i][j]
        if j + 1 <= #_t[i] then
          _text = _text .. "+"
        end
      end
    end
    table.insert(_result, _text)
  end
  return _result
end
counter_attack_button_input = {}
function update_counter_attack_button()
  --kara throw if menu_loaded then
  if counter_attack_settings.motion == 15 then
    for i = 1, #move_list[dummy.char_str] do
      if move_list[dummy.char_str][i].move_type == "kara" then
          counter_attack_button_input = move_list[dummy.char_str][i].buttons
          counter_attack_button = input_to_text(counter_attack_button_input)
          break
      end
    end
  else
    counter_attack_button = counter_attack_button_default
  end
  counter_attack_button_item.list = counter_attack_button
  if counter_attack_settings.button > #counter_attack_button then
    counter_attack_settings.button = #counter_attack_button
    if #counter_attack_button == 0 then
      counter_attack_settings.button = 1
    end
  end
end

counter_attack_special_inputs = {}
counter_attack_special_types = {}
function update_counter_attack_special()
  local _list = {}
  counter_attack_special_inputs = {}
  counter_attack_special_types = {}
  local _sa_str = "sa" .. dummy.selected_sa
  for i = 1, #move_list[dummy.char_str] do
    if move_list[dummy.char_str][i].move_type == "special" or move_list[dummy.char_str][i].move_type == "kara_special" or move_list[dummy.char_str][i].move_type == _sa_str
    or (dummy.char_str == "gouki" and (move_list[dummy.char_str][i].name == "sgs" or move_list[dummy.char_str][i].name== "kkz"))
    or (dummy.char_str == "shingouki" and move_list[dummy.char_str][i].name == "sgs")
    or (dummy.char_str == "gill" and (move_list[dummy.char_str][i].name == "meteor_strike" or move_list[dummy.char_str][i].name == "seraphic_wing"))
    then
      table.insert(_list, move_list[dummy.char_str][i].name)
      table.insert(counter_attack_special_inputs, move_list[dummy.char_str][i].input)
      table.insert(counter_attack_special_types, move_list[dummy.char_str][i].move_type)
    end
  end

  counter_attack_special_item.list = _list
  counter_attack_special = _list
  update_counter_attack_special_button()
--   update_counter_attack_button()
  update_dimensions()
end

function update_counter_attack_special_button()
  local _move = counter_attack_special[training_settings.counter_attack[dummy.char_str].special]
  for i = 1, #move_list[dummy.char_str] do
    if move_list[dummy.char_str][i].name == _move then
      counter_attack_special_button_item.list = move_list[dummy.char_str][i].buttons
      counter_attack_special_button = move_list[dummy.char_str][i].buttons
      break
    end
  end
  if counter_attack_settings.special_button > #counter_attack_special_button then
    counter_attack_settings.special_button = #counter_attack_special_button
    if #counter_attack_special_button == 0 then
      counter_attack_settings.special_button = 1
    end
  end
end

function make_recording_slot()
  return {
    inputs = {},
    delay = 0,
    random_deviation = 0,
    weight = 1,
  }
end
recording_slots = {}
for _i = 1, recording_slot_count do
  table.insert(recording_slots, make_recording_slot())
end

recording_slots_names = {}
for _i = 1, #recording_slots do
  table.insert(recording_slots_names, "slot ".._i)
end

slot_replay_mode = {
  "replay_normal",
  "replay_random",
  "replay_ordered",
  "replay_repeat",
  "replay_repeat_random",
  "replay_repeat_ordered"
}

-- save/load
function save_training_data()
  backup_recordings()
  if not write_object_to_json_file(training_settings, saved_path..training_settings_file) then
    print(string.format("Error: Failed to save training settings to \"%s\"", training_settings_file))
  end
end

function load_training_data()
  local _training_settings = read_object_from_json_file(saved_path..training_settings_file)
  if _training_settings == nil then
    _training_settings = {}
  end

  -- update old versions data
  if _training_settings.recordings then
    for _key, _value in pairs(_training_settings.recordings) do
      for _i, _slot in ipairs(_value) do
        if _value[_i].inputs == nil then
          _value[_i] = make_recording_slot()
        else
          _slot.delay = _slot.delay or 0
          _slot.random_deviation = _slot.random_deviation or 0
          _slot.weight = _slot.weight or 1
        end
      end
    end
  end

  for _key, _value in pairs(_training_settings) do
    training_settings[_key] = _value
  end

  restore_recordings()

--   update_counter_attack_settings()
end

function backup_recordings()
  -- Init base table
  if training_settings.recordings == nil then
    training_settings.recordings = {}
  end
  for _key, _value in ipairs(characters) do
    if training_settings.recordings[_value] == nil then
      training_settings.recordings[_value] = {}
      for _i = 1, #recording_slots do
        table.insert(training_settings.recordings[_value], make_recording_slot())
      end
    end
  end

  if dummy.char_str ~= "" then
    training_settings.recordings[dummy.char_str] = recording_slots
  end
end

function restore_recordings()
  local _char = P2.char_str
  if _char and _char ~= "" then
    local _recording_count = #recording_slots
    if training_settings.recordings then
      recording_slots = training_settings.recordings[_char] or {}
    end
      local _missing_slots = _recording_count - #recording_slots
    for _i = 1, _missing_slots do
        table.insert(recording_slots, make_recording_slot())
    end
  end
  update_current_recording_slot_frames()
end

function load_counterattack_special_list(_char_str)
  local _list = {}
  for _i = 1, #move_list[_char_str] do
    table.insert(_list, loc[training_settings.language][#move_list[_char_str][_i].name])
  end
  return _list
end

-- swap inputs
function swap_inputs(_out_input_table)
  function swap(_input)
    local carry = _out_input_table["P1 ".._input]
    _out_input_table["P1 ".._input] = _out_input_table["P2 ".._input]
    _out_input_table["P2 ".._input] = carry
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


function update_pose(_input, _player, _dummy, _pose)
  if current_recording_state == 4 -- Replaying
  or _dummy.blocking.is_blocking then
    return
  end

  if is_in_match and not is_menu_open and not is_playing_input_sequence(_dummy) then
    local _on_ground = is_state_on_ground(_dummy.standing_state, _dummy)
    local _is_waking_up = _dummy.is_wakingup and _dummy.remaining_wakeup_time > 0 and _dummy.remaining_wakeup_time <= 3
    local _wakeup_frame = _dummy.standing_state == 0 and _dummy.posture == 0

    if _pose == 2 and (_on_ground or _is_waking_up or _wakeup_frame) then -- crouch
      _input[_dummy.prefix..' Down'] = true
    elseif _pose == 3 and _on_ground then -- jump
      _input[_dummy.prefix..' Up'] = true
    elseif _pose == 4 then -- high jump
      if _on_ground and not is_playing_input_sequence(_dummy) then
        queue_input_sequence(_dummy, {{"down"}, {"up"}})
      end
    end
  end
end


function find_move_frame_data(_char_str, _animation_id)
  if not frame_data[_char_str] then return nil end
  return frame_data[_char_str][_animation_id]
end

to_draw={}

function has_boxes(_boxes, _types)
  for _, _box in pairs(_boxes) do
    for _, _type in pairs(_types) do
      if convert_box_types[_box[1]] == _type then
        return true
      end
    end
  end
  return false
end

function get_boxes(_boxes, _types)
  local _res = {}
  for _, _box in pairs(_boxes) do
    for _, _type in pairs(_types) do
      if convert_box_types[_box[1]] == _type then
        table.insert(_res, _box)
      end
    end
  end
  return _res
end

function check_switch_sides(_player)
  if sign(_player.other.pos_x - _player.pos_x) * sign(_player.other.previous_pos_x - _player.previous_pos_x) == -1 then
    return true
  end
    return false
end

function init_motion_data(_obj)
  local _data = {
    pos_x = _obj.pos_x,
    pos_y = _obj.pos_y,
    animation = _obj.animation,
    flip_x = _obj.flip_x,
    velocity_x = _obj.velocity_x,
    velocity_y = _obj.velocity_y,
    acceleration_x = _obj.acceleration_x,
    acceleration_y = _obj.acceleration_y
  }
  return {[0] = _data}
end

function init_motion_data_zero(_obj)
  local _data = {
    pos_x = _obj.pos_x,
    pos_y = _obj.pos_y,
    animation = _obj.animation,
    flip_x = _obj.flip_x,
    velocity_x = 0,
    velocity_y = 0,
    acceleration_x = 0,
    acceleration_y = 0
  }
  return {[0] = _data}
end

function create_line(_obj, _n)
  local line = {}
  for i = 1, _n do
    table.insert(line, {animation = _obj.animation or _obj.projectile_type, frame = _obj.animation_frame + i, delta = i})
  end
  return line
end

function print_pline(_line)
  if _line then
    local _str = ""
    for i = 1, #_line do
      _str = _str .. string.format("%s %d %d -> ",_line[i].animation,_line[i].frame,_line[i].delta)
    end
    print(_str)
  end
end

function predict_everything(_player, _dummy, _frames_prediction)
  --returns all possible sequences of the next 3 frames
  local _player_lines = predict_frames_branching(_player, _player.animation, nil, _frames_prediction)
  --filter for lines that contain hit frames or projectiles
  local _filtered = filter_lines(_player, _player_lines) or {}

  -- print(frame_number, "---*---")
  -- for _, _player_line in pairs(_player_lines) do
  --   print_pline(_player_line)
  -- end

  if #_filtered > 0 and #_filtered[1] > 0 then
    _player_lines = _filtered
  else
    if _player_lines[1] and #_player_lines[1] > 0 then
      _player_lines = {_player_lines[1]}
    else
      _player_lines = {create_line(_player, _frames_prediction)}
    end
  end
  for _, _player_line in pairs(_player_lines) do
    _player_line[0] = {animation = _player.animation, frame = _player.animation_frame, delta = 0}
  end

  local _dummy_lines = predict_frames_branching(_dummy, _dummy.animation, nil, _frames_prediction)[1]
  if not _dummy_lines or #_dummy_lines == 0 then
    _dummy_lines = create_line(_dummy, _frames_prediction)
  end
  _dummy_lines[0] = {animation = _dummy.animation, frame = _dummy.animation_frame, delta = 0}

  local predicted_state = {}

  -- print(frame_number, "-----")
  for _, _player_line in pairs(_player_lines) do
    -- print_pline(_player_line)
    local _player_motion_data = init_motion_data(_player)
    local _dummy_motion_data = init_motion_data(_dummy)
    _player_motion_data[0].switched_sides = check_switch_sides(_player)
    _dummy_motion_data[0].switched_sides = check_switch_sides(_dummy)

    local _dummy_line = deepcopy(_dummy_lines)
    for i = 1, #_player_line do
      local _predicted_frame = _player_line[i]
      local _frame = _predicted_frame.frame
      local _frame_to_check = _frame + 1
      local _frame_data = find_move_frame_data(_player.char_str, _predicted_frame.animation)

      predict_player_movement(_player, _player_motion_data, _player_line,
                              _dummy, _dummy_motion_data, _dummy_line, i)

      --save data to use for projectile prediction
      predicted_state = {player_motion_data = _player_motion_data,
                         player_line = _player_line,
                         dummy_motion_data = _dummy_motion_data,
                         dummy_line = _dummy_line}

      --                    print(i)
      -- print_pline(_dummy_line)

      local tfd = frame_data[_dummy.char_str][_dummy_line[i].animation]
      if tfd and tfd.frames and tfd.frames[_dummy_line[i].frame + 1] and tfd.frames[_dummy_line[i].frame + 1].boxes then
        local _vuln = get_boxes(tfd.frames[_dummy_line[i].frame + 1].boxes, {"vulnerability","ext. vulnerability"})
        local _color = 0x44097000 + 255 - 70 * i
        -- to_draw_hitboxes[frame_number + _predicted_frame.delta] = {_dummy_motion_data[i].pos_x, _dummy_motion_data[i].pos_y, _dummy_motion_data[i].flip_x, _vuln, nil, nil, _color}
      end
      -- debug_prediction[frame_number+_predicted_frame.delta] = {[P1] = _player_motion_data[i], [P2] = _dummy_motion_data[i]}

      if _frame_data then
        local _frames = _frame_data.frames
        if _frames and _frames[_frame_to_check] then
          if _frames[_frame_to_check].projectile then
            insert_projectile(_player, _player_motion_data[i], _predicted_frame)
          end

          if _frame_data.hit_frames
          and _frames[_frame_to_check].boxes
          and has_boxes(_frames[_frame_to_check].boxes, {"attack", "throw"}) then
            local _next_hit_id = 1
            for i = 1, #_frame_data.hit_frames do
              if _frame > _frame_data.hit_frames[i][2] then
                _next_hit_id = i + 1
              end
            end

            if _next_hit_id > _player.current_hit_id then
              local _attack_boxes = get_boxes(_frames[_frame_to_check].boxes, {"attack"})
              to_draw_hitboxes[frame_number + _predicted_frame.delta] = {_player_motion_data[i].pos_x, _player_motion_data[i].pos_y, _player_motion_data[i].flip_x, _attack_boxes, nil, nil, 0xFF941CDD}


              local _dummy_boxes = get_hurtboxes(_dummy.char_str, _dummy_line[i].animation, _dummy_line[i].frame)
              if not _dummy_boxes then
                _dummy_boxes = _dummy.boxes
              end
              local _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
              if frame_data_meta[_player.char_str][_predicted_frame.animation] and frame_data_meta[_player.char_str][_predicted_frame.animation].hit_throw then
                table.insert(_box_type_matches, {{"throwable"}, {"throw"}})
              end

              if test_collision(_dummy_motion_data[i].pos_x, _dummy_motion_data[i].pos_y, _dummy_motion_data[i].flip_x, _dummy_boxes,
                            _player_motion_data[i].pos_x, _player_motion_data[i].pos_y, _player_motion_data[i].flip_x, _frames[_frame_to_check].boxes,
                            _box_type_matches)
              then
                local _delta = _predicted_frame.delta
                if not _frame_data.bypass_freeze then
                  _delta = _delta + _player.remaining_freeze_frames
                end
                local _expected_attack = {id = _player.id, blocking_type = "player", hit_id = _next_hit_id, delta = _delta, animation = _predicted_frame.animation, flip_x = _predicted_frame.flip_x}
                table.insert(_dummy.blocking.expected_attacks, _expected_attack)
              end
            end
          end
        else
          print("NO FD", _predicted_frame.animation, _frame)
        end
      end
    end
  end

  local _valid_projectiles = {}
  for _id, _projectile in pairs(projectiles) do
    if ((_projectile.is_forced_one_hit and _projectile.remaining_hits ~= 0xFF) or _projectile.remaining_hits > 0)
    and _projectile.alive then
      if (_projectile.emitter_id ~= _dummy.id or (_projectile.emitter_id == _dummy.id and _projectile.is_converted)) then
        local _frame_delta =  _projectile.remaining_freeze_frames - _frames_prediction
        if _projectile.placeholder then
          _frame_delta = _projectile.animation_start_frame - frame_number - _frames_prediction
        end
        if _frame_delta <= _frames_prediction and _projectile.cooldown - _frames_prediction <= 0 then
          table.insert(_valid_projectiles, _projectile)
        end
      end
    end
  end
  if #_valid_projectiles > 0 then
    local _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
    local _dummy_line = predicted_state.dummy_line
    local _dummy_motion_data = predicted_state.dummy_motion_data
    for _, _projectile in pairs(_valid_projectiles) do
      local _proj_line = nil
      if _projectile.seiei_animation then
        _proj_line = predict_frames_branching({type="player", char_str="yang"}, _projectile.projectile_type, _projectile.animation_frame, _frames_prediction)[1]
      else
        _proj_line = predict_frames_branching(_projectile, _projectile.projectile_type, _projectile.animation_frame, _frames_prediction)[1]
      end
      if not _proj_line or #_proj_line == 0 then
        _proj_line = create_line(_projectile, _frames_prediction)
      end
      local _proj_motion_data = init_motion_data(_projectile)
      if _projectile.cooldown - _frames_prediction <= 0 then
        for i = 1, #_dummy_line do
          local _remaining_freeze = _projectile.remaining_freeze_frames - i
          local _remaining_cooldown = _projectile.cooldown
          if _remaining_freeze <= 0 then
            _remaining_cooldown = _remaining_cooldown + _remaining_freeze
          end

          local _proj_boxes = nil
          local _ignore_flip = false
          if _projectile.projectile_type == "00_tenguishi" then
            _proj_boxes = _projectile.boxes
            _ignore_flip = true
          elseif _projectile.seiei_animation then
            local _seiei_fd = find_move_frame_data("yang", _projectile.seiei_animation)
            if _seiei_fd and _seiei_fd.frame[_projectile.seiei_animation]
            and _seiei_fd.frame[_projectile.seiei_animation].boxes
            and has_boxes(_seiei_fd.frame[_projectile.seiei_animation].boxes, {"attack", "throw"})
            then
              _proj_boxes = _seiei_fd.frame[_projectile.seiei_animation].boxes
            end
          else
            local _frame_data = find_move_frame_data("projectiles", _proj_line[i].animation)
            local _frame_to_check = _proj_line[i].frame + 1
            if _frame_data then
              local _frames = _frame_data.frames
              if _frames
              and _frames[_frame_to_check]
              and _frames[_frame_to_check].boxes
              and has_boxes(_frames[_frame_to_check].boxes, {"attack", "throw"})
              then
                 _proj_boxes = _frames[_frame_to_check].boxes
              end
            end
            if not _proj_boxes then
              _proj_boxes = _projectile.boxes
            end
          end

          predict_projectile_movement(_projectile, _proj_motion_data, _proj_line, i, _ignore_flip)

          local _dummy_boxes = get_hurtboxes(_dummy.char_str, _dummy_line[i].animation, _dummy_line[i].frame)
          if not _dummy_boxes then
            _dummy_boxes = _dummy.boxes
          end

          if _proj_boxes and _remaining_cooldown <= 0 then
            local _delta = _proj_line[i].delta + _projectile.remaining_freeze_frames
            local _color = 0xa9691c00 + 255 - 70 * _delta
            to_draw_hitboxes[frame_number + _delta] = {_proj_motion_data[i].pos_x, _proj_motion_data[i].pos_y, _proj_motion_data[i].flip_x, _proj_boxes, nil, nil, _color}
      
            if test_collision(_dummy_motion_data[i].pos_x, _dummy_motion_data[i].pos_y, _dummy_motion_data[i].flip_x, _dummy_boxes,
                                  _proj_motion_data[i].pos_x, _proj_motion_data[i].pos_y, _proj_motion_data[i].flip_x, _proj_boxes,
                                  _box_type_matches)
            then
              local _expected_attack = {id = _projectile.id, blocking_type = "projectile", hit_id = 1, delta = _delta, animation = _proj_line[i].animation, flip_x = _proj_motion_data[i].flip_x}
              table.insert(_dummy.blocking.expected_attacks, _expected_attack)
            end
          end
        end
      end
    end
  end
end

function insert_projectile(_player, _motion_data, _predicted_hit)
  local _fd = frame_data[_player.char_str][_predicted_hit.animation]
  if _fd and _fd.frames[_predicted_hit.frame + 1] 
  and _fd.frames[_predicted_hit.frame + 1].projectile then
    local _proj_fd = frame_data["projectiles"][_fd.frames[_predicted_hit.frame + 1].projectile.type]
    local _obj = {base = 0, projectile = 99}
    _obj.id = _fd.frames[_predicted_hit.frame + 1].projectile.type .. tostring(frame_number + _predicted_hit.delta)
    _obj.emitter_id = _player.id
    _obj.alive = true
    _obj.projectile_type = _fd.frames[_predicted_hit.frame + 1].projectile.type
    _obj.projectile_start_type = _obj.projectile_type
    _obj.pos_x = _motion_data.pos_x + _fd.frames[_predicted_hit.frame + 1].projectile.offset[1] * flip_to_sign(_motion_data.flip_x)
    _obj.pos_y = _motion_data.pos_y + _fd.frames[_predicted_hit.frame + 1].projectile.offset[2]
    _obj.velocity_x = _proj_fd.frames[1].velocity[1]
    _obj.velocity_y = _proj_fd.frames[1].velocity[2]
    _obj.acceleration_x = _proj_fd.frames[1].acceleration[1]
    _obj.acceleration_y = _proj_fd.frames[1].acceleration[2]
    _obj.flip_x = _motion_data.flip_x
    _obj.boxes = {}
    _obj.expired = false
    _obj.previous_remaining_hits = 99
    _obj.remaining_hits = 99
    _obj.is_forced_one_hit = false
    _obj.has_activated = false
    _obj.animation_start_frame = frame_number + _predicted_hit.delta
    _obj.animation_frame = 0
    _obj.animation_freeze_frames = 0
    _obj.remaining_freeze_frames = 0
    _obj.remaining_lifetime = 0
    _obj.cooldown = _predicted_hit.delta
    _obj.placeholder = true
    projectiles[_obj.id] = _obj
  end
end

function get_hurtboxes(_char, _anim, _frame)
  if  frame_data[_char][_anim]
  and frame_data[_char][_anim].frames
  and frame_data[_char][_anim].frames[_frame + 1]
  and frame_data[_char][_anim].frames[_frame + 1].boxes
  and has_boxes(frame_data[_char][_anim].frames[_frame + 1].boxes, {"vulnerability", "ext. vulnerability"})
  then
    return frame_data[_char][_anim].frames[_frame + 1].boxes
  end
  return nil
end

function get_pushboxes(_player)
  for _, _box in pairs(_player.boxes) do
    if convert_box_types[_box[1]] == "push" then
      return _box
    end
  end
  return nil
end

function get_boxes_lowest_position(_boxes, _types)
  local _min = math.huge
  for _, _box in pairs(_boxes) do
    local  _b = format_box(_box)
    for _, _type in pairs(_types) do
      if _b.type == _type and _b.bottom < _min then
        _min = _b.bottom
      end
    end
  end
  return _min
end

function get_horizontal_box_overlap(_a_box, _ax, _ay, _a_flip, _b_box, _bx, _by, _b_flip)
  local _a_l, _b_l

  if _a_flip == 0 then
    _a_l = _ax + _a_box.left
  else
    _a_l = _ax - _a_box.left - _a_box.width
  end
  local _a_r = _a_l + _a_box.width
  local _a_b = _ay + _a_box.bottom
  local _a_t = _a_b + _a_box.height

  if _b_flip == 0 then
    _b_l = _bx + _b_box.left
  else
    _b_l = _bx - _b_box.left - _b_box.width
  end
  local _b_r = _b_l + _b_box.width
  local _b_b = _by + _b_box.bottom
  local _b_t = _b_b + _b_box.height


  if _a_r > _b_l and _a_l < _b_r and _a_t > _b_b and _a_b < _b_t then
    return math.min(_a_r, _b_r) - math.max(_a_l, _b_l)
  end
  return 0
end

function get_push_value(_dist_from_pb_center, _pushbox_overlap_range, _push_value_max)
  local _p = _dist_from_pb_center / _pushbox_overlap_range
  if _p < .7 then
    local _range = math.floor(.7 * _pushbox_overlap_range)
    return math.round((_range - _dist_from_pb_center) / _range * (_push_value_max - 6) + 6)
  elseif _p < .76 then
    return 4
  elseif _p < .82 then
    return 3
  elseif _p < .86 then
    return 2
  elseif _p < .98 then
    return 1
  end
  return 0
end

function movement_prediction_special_cases()
  --index - 1 == uf sjf, and current anim is ken ex tatsu at frame 0 then

end

function predict_player_movement(_p1, _p1_motion_data, _p1_line, _p2, _p2_motion_data, _p2_line, _index)

  local _motion_data = {[_p1] = _p1_motion_data, [_p2] = _p2_motion_data}
  local _lines = {[_p1] = _p1_line, [_p2] = _p2_line}

  local _stage = stages[stage]

  for _player, _mdata in pairs(_motion_data) do
    _mdata[_index] = copytable(_mdata[_index - 1])

    if _mdata[_index - 1].switched_sides then
      if _player.remaining_freeze_frames - _index < 0 then
        local _anim = _mdata[_index - 1].animation
        local _target_anim = nil
        if _anim == frame_data[_player.char_str].standing then
          _target_anim = frame_data[_player.char_str].standing_turn
        elseif _anim == frame_data[_player.char_str].crouching then
          _target_anim = frame_data[_player.char_str].crouching_turn
        end
        if _target_anim then
          local _line = predict_frames_branching(_player, _target_anim, 0, #_lines[_player] - _index + 1, nil, true)[1]
          for j = 1, #_line do
            _lines[_player][_index + j - 1] = _line[j]
          end
          -- print(_index, _mdata[_index - 1].flip_x, bit.bxor(_mdata[_index - 1].flip_x, 1))
          -- print_pline(_lines[_player])

          _mdata[_index].flip_x = bit.bxor(_mdata[_index - 1].flip_x, 1)
        end
      end
    end
  end

  for _player, _mdata in pairs(_motion_data) do
    local _corner_left = _stage.left + character_specific[_player.char_str].corner_offset_left
    local _corner_right = _stage.right - character_specific[_player.char_str].corner_offset_right
    local _sign = flip_to_sign(_mdata[_index - 1].flip_x)

    if _player.is_in_pushback then
      local _pb_frame = frame_number + _index - _player.pushback_start_frame
      local _anim = _player.last_received_connection_animation
      local _hit_id = _player.last_received_connection_hit_id

      if _anim and _hit_id
      and frame_data[_player.other.char_str][_anim]
      and frame_data[_player.other.char_str][_anim].pushback
      and frame_data[_player.other.char_str][_anim].pushback[_hit_id]
      and _pb_frame <= #frame_data[_player.other.char_str][_anim].pushback[_hit_id]
      then
        local _pb_value = frame_data[_player.other.char_str][_anim].pushback[_hit_id][_pb_frame]
        local _new_pos = _mdata[_index].pos_x - _sign * _pb_value
        local _over_push = 0

        if _new_pos < _corner_left then
          _over_push = _corner_left - _new_pos
        elseif _new_pos > _corner_right then
          _over_push = _new_pos - _corner_right
        end
        if _over_push > 0 then
          _motion_data[_player.other][_index].pos_x = _motion_data[_player.other][_index].pos_x + _over_push * _sign
        end
        _mdata[_index].pos_x = _mdata[_index].pos_x - (_pb_value - _over_push) * _sign
      end
    end

    local _frame_data = find_move_frame_data(_player.char_str, _lines[_player][_index].animation)
    if _frame_data then
      local _next_frame = _frame_data.frames[_lines[_player][_index].frame + 1]
      if _next_frame then
        if _next_frame.movement then
          _mdata[_index].pos_x = _mdata[_index].pos_x + _next_frame.movement[1] * _sign
          _mdata[_index].pos_y = _mdata[_index].pos_y + _next_frame.movement[2]
        end
        if _next_frame.velocity then
          _mdata[_index].velocity_x = _mdata[_index].velocity_x + _mdata[_index - 1].acceleration_x + _next_frame.velocity[1]
          _mdata[_index].velocity_y = _mdata[_index].velocity_y + _mdata[_index - 1].acceleration_y + _next_frame.velocity[2]
        end
        if _next_frame.acceleration then
          _mdata[_index].acceleration_x = _mdata[_index].acceleration_x + _next_frame.acceleration[1]
          _mdata[_index].acceleration_y = _mdata[_index].acceleration_y + _next_frame.acceleration[2]
        end
      else
        -- print("next frame not found", _lines[_player][_index].animation, _lines[_player][_index].frame)
      end
    end

    local _should_apply_velocity = false
    local _previous_frame_data = find_move_frame_data(_player.char_str, _lines[_player][_index - 1].animation)

    if (_previous_frame_data and _previous_frame_data.uses_velocity)
    or _mdata[_index - 1].pos_y > 0 then
      --first frame of every air move ignores velocity
      if not (_mdata[_index - 1].frame == 0 and _previous_frame_data.air) then
        _should_apply_velocity = true
      end
    end
    if _should_apply_velocity then
      _mdata[_index].pos_x = _mdata[_index].pos_x + _mdata[_index - 1].velocity_x * _sign
      _mdata[_index].pos_y = _mdata[_index].pos_y + _mdata[_index - 1].velocity_y
    end

    if _mdata[_index].pos_x > _corner_right then
      local _mantissa = _mdata[_index].pos_x - math.floor(_mdata[_index].pos_x)
      _mdata[_index].pos_x = _corner_right + _mantissa
    elseif _mdata[_index].pos_x < _corner_left then
      local _mantissa = _mdata[_index].pos_x - math.floor(_mdata[_index].pos_x)
      _mdata[_index].pos_x = _corner_left + _mantissa
    end
    --if player is falling
    if _frame_data and _mdata[_index].pos_y < _mdata[_index - 1].pos_y then
      local _next_frame = _frame_data.frames[_lines[_player][_index].frame + 1]
      local _boxes_bottom = nil
      if _next_frame and _next_frame.boxes and has_boxes(_next_frame.boxes, {"vulnerability"}) then
        _boxes_bottom = _mdata[_index].pos_y + get_boxes_lowest_position(_next_frame.boxes, {"vulnerability"})
      else
        for j = _index - 1, 1, -1 do
          local _an = _lines[_player][j].animation
          local _f = _lines[_player][j].frame
          local _fd = find_move_frame_data(_player.char_str, _an)
          if _fd and _fd.frames then
            local _prev_frame = _fd.frames[_f + 1]
            if _prev_frame.boxes and has_boxes(_prev_frame.boxes, {"vulnerability"}) then
              _boxes_bottom = _mdata[_index].pos_y + get_boxes_lowest_position(_prev_frame.boxes, {"vulnerability"})
            end
          end
        end
      end
      --this is a guess at when landing will occur. not sure what the actual principle is
      --moves like dudley's jump HK/HP allow the player to fall much lower before landing. y_pos of -30 for dudley's j.HP!
      if _boxes_bottom then
        if _boxes_bottom < 40 then
          _mdata[_index].pos_y = 0
        end
      elseif _mdata[_index].pos_y < 0 then
        _mdata[_index].pos_y = 0
      end
    end
  end

  --just estimate using current pushboxes, no need to predict
  local _p1_pushbox = get_pushboxes(_p1)
  local _p2_pushbox = get_pushboxes(_p2)

  if _p1_pushbox and _p2_pushbox then
    _p1_pushbox = format_box(_p1_pushbox)
    _p2_pushbox = format_box(_p2_pushbox)

    local _p1_mdata = _motion_data[_p1][_index]
    local _p2_mdata = _motion_data[_p2][_index]

    local _overlap = get_horizontal_box_overlap(_p1_pushbox, _p1_mdata.pos_x, _p1_mdata.pos_y, _p1_mdata.flip_x,
                                                _p2_pushbox, _p2_mdata.pos_x, _p2_mdata.pos_y, _p2_mdata.flip_x)
    if _overlap > 1 then
      local _push_value_max = math.ceil((character_specific[_p1.char_str].push_value
                                  + character_specific[_p2.char_str].push_value) / 2)
      local _dist_from_pb_center = math.abs(_p1_mdata.pos_x - _p2_mdata.pos_x)
      local _pushbox_overlap_range = (_p1_pushbox.width + _p2_pushbox.width) / 2
      local _push_value = get_push_value(_dist_from_pb_center, _pushbox_overlap_range, _push_value_max)

      local _sign =    (_p2_mdata.pos_x - _p1_mdata.pos_x >= 0 and -1)
                    or (_p2_mdata.pos_x - _p1_mdata.pos_x < 0 and 1)
      _p1_mdata.pos_x = _p1_mdata.pos_x + _push_value * _sign
      _p2_mdata.pos_x = _p2_mdata.pos_x - _push_value * _sign

      for _player, _mdata in pairs(_motion_data) do
        local _corner_left = _stage.left + character_specific[_player.char_str].corner_offset_left
        local _corner_right = _stage.right - character_specific[_player.char_str].corner_offset_right
        if _mdata[_index].pos_x > _corner_right then
          local _mantissa = _mdata[_index].pos_x - math.floor(_mdata[_index].pos_x)
          _mdata[_index].pos_x = _corner_right + _mantissa
        elseif _mdata[_index].pos_x < _corner_left then
          local _mantissa = _mdata[_index].pos_x - math.floor(_mdata[_index].pos_x)
          _mdata[_index].pos_x = _corner_left + _mantissa
        end
      end
    end
  end



  for _player, _mdata in pairs(_motion_data) do
    local _other_mdata = _motion_data[_player.other]
    if sign(_other_mdata[_index].pos_x - _mdata[_index].pos_x)
    * sign(_other_mdata[_index - 1].pos_x - _mdata[_index - 1].pos_x) == -1
    then
      _mdata[_index].switched_sides = true
    end
  end
end

function predict_projectile_movement(_projectile, _mdata, _line, _index, _ignore_flip)
  _mdata[_index] = copytable(_mdata[_index - 1])

  local _sign = _ignore_flip and 1 or flip_to_sign(_mdata[_index - 1].flip_x)

  local _frame_data = find_move_frame_data("projectiles", _line[_index].animation)
  if _frame_data then
    local _next_frame = _frame_data.frames[_line[_index].frame + 1]
    if _next_frame then
      if _next_frame.movement then
        _mdata[_index].pos_x = _mdata[_index].pos_x + _next_frame.movement[1] * _sign
        _mdata[_index].pos_y = _mdata[_index].pos_y + _next_frame.movement[2]
      end
      if _next_frame.velocity then
        _mdata[_index].velocity_x = _mdata[_index].velocity_x + _mdata[_index - 1].acceleration_x + _next_frame.velocity[1]
        _mdata[_index].velocity_y = _mdata[_index].velocity_y + _mdata[_index - 1].acceleration_y + _next_frame.velocity[2]
      end
      if _next_frame.acceleration then
        _mdata[_index].acceleration_x = _mdata[_index].acceleration_x + _next_frame.acceleration[1]
        _mdata[_index].acceleration_y = _mdata[_index].acceleration_y + _next_frame.acceleration[2]
      end
    else
      print("next frame not found", _line[_index].animation, _line[_index].frame)
    end
  end

  _mdata[_index].pos_x = _mdata[_index].pos_x + _mdata[_index - 1].velocity_x * _sign
  _mdata[_index].pos_y = _mdata[_index].pos_y + _mdata[_index - 1].velocity_y
end

function predict_object_position(_obj, _frames_prediction)
  local _result = {
    _obj.pos_x,
    _obj.pos_y,
  }

  local _sum_movement_x = 0
  local _sum_movement_y = 0
  local _sum_velocity_x = 0
  local _sum_velocity_y = 0
  local _velocity_x = _obj.velocity_x
  local _velocity_y = _obj.velocity_y
  local _acceleration_x = _obj.acceleration_x
  local _acceleration_y = _obj.acceleration_y

  if _frames_prediction == 0 then
    return _result
  end

  local _sign = 1
  if _obj.flip_x == 0 then
    _sign = -1
  end

  local _frame_data = nil
  local _anim = nil
  if _obj.type == "player" then
    _frame_data = find_move_frame_data(_obj.char_str, _anim)
    _anim = _obj.animation
  else
    _frame_data = find_move_frame_data("projectiles", _anim)
    _anim = _obj.projectile_type
  end

  local _str = ""

  local _frame_to_check = 1
  for i = 1, _frames_prediction do
    local _predicted_frames = predict_frames(_obj, _anim, nil, i)
    if #_predicted_frames > 0 then
      _anim = _predicted_frames[1].animation
      if _obj.id == 1 or _obj.id == 2 then
        _frame_data = find_move_frame_data(_obj.char_str, _anim)
      else
        _frame_data = find_move_frame_data("projectiles", _anim)
      end
      _frame_to_check = _predicted_frames[1].frame + 1

      if _frame_data then
        if _frame_data.frames[_frame_to_check].movement then
          _sum_movement_x = _sum_movement_x + _frame_data.frames[_frame_to_check].movement[1]
          _sum_movement_y = _sum_movement_y + _frame_data.frames[_frame_to_check].movement[2]
          if _obj.id == 1 then
            _str = _str .. _frame_data.frames[_frame_to_check].hash .. ": " .. tostring(_frame_data.frames[_frame_to_check].movement[1]) .. ", "
          end
        end

        _sum_velocity_x = _sum_velocity_x + _velocity_x -- total movement due to velocity
        _sum_velocity_y = _sum_velocity_y + _velocity_y

        if _frame_data.frames[_frame_to_check].acceleration then
          _acceleration_x = _acceleration_x + _frame_data.frames[_frame_to_check].acceleration[1]
          _acceleration_y = _acceleration_y + _frame_data.frames[_frame_to_check].acceleration[2]
        else
          _acceleration_x = 0
          _acceleration_y = 0
        end
        if _frame_data.frames[_frame_to_check].velocity then
          _velocity_x = _velocity_x + _frame_data.frames[_frame_to_check].velocity[1] + _acceleration_x
          _velocity_y = _velocity_y + _frame_data.frames[_frame_to_check].velocity[2] + _acceleration_y
        end
      end
    else
      _sum_velocity_x = _sum_velocity_x + _velocity_x
      _sum_velocity_y = _sum_velocity_y + _velocity_y
      _velocity_x = _velocity_x + _acceleration_x
      _velocity_y = _velocity_y + _acceleration_y
    end
  end


  _result[1] = _result[1] + _sum_movement_x * _sign
  _result[2] = _result[2] + _sum_movement_y

  local _apply_velocity = false
  if not (_obj.id == 1 or _obj.id == 2) then
    _apply_velocity = true
  elseif _obj.pos_y > 0
  or (_frame_data and _frame_data.uses_velocity) then
    _apply_velocity = true
  end
  if _apply_velocity then
    _result[1] = _result[1] + _sum_velocity_x * _sign
    _result[2] = _result[2] + _sum_velocity_y
  end

--   if _obj.id == 1 then
--     print(_obj.animation_frame_hash, _frames_prediction, "f: move:", _sum_movement_x + _sum_velocity_x, _str)
--   end
  table.insert(to_draw, {math.round(_result[1]), math.round(_result[2])} )
  return _result
end

function predict_frames_before_landing(_player_obj, _max_lookahead_frames)
  _max_lookahead_frames = _max_lookahead_frames or 15
  if _player_obj.pos_y == 0 then
    return 0
  end

  local _result = -1
  for _i = 1, _max_lookahead_frames do
    local _pos = predict_object_position(_player_obj, _i)
    if _pos[2] <= 3 then
      _result = _i
      break
    end
  end
  return _result
end

local next_anim_types = {"next_anim", "optional_anim"}
function predict_frames(_obj, _anim, _frame, _frames_prediction, _d)
  local _results = {}

  _frame = _frame or _obj.animation_frame
  local _frame_data = nil
  if _obj.type == "player" then
    _frame_data = find_move_frame_data(_obj.char_str, _anim)
  else
    _frame_data = find_move_frame_data("projectiles", _anim)
  end
  local _frame_to_check = _frame + 1
  local _current_loop = 1
  local _delta = 0
  local _used_next_anim = false

  _d = _d or 0

  if not _frame_data then
    return _results
  else
    if _frame_data.loops then
      for _i = 0, #_frame_data.frames do
        local _target_hash = _obj.animation_frame_hash
        local _n = 10
        if _obj.type == "player" then
          _n = _obj.animation_hash_length
          _target_hash = string.sub(_obj.animation_frame_hash, _n)
        end
        if _frame + _i + 1 <= #_frame_data.frames then
          local _shortened_hash = string.sub(_frame_data.frames[_frame + _i + 1].hash, 1, _n)
          if _shortened_hash == _target_hash then
            _frame_to_check = _frame + _i + 1
            break
          end
        end
        if _frame - _i + 1 >= 1 then
          local _shortened_hash = string.sub(_frame_data.frames[_frame - _i + 1].hash, 1, _n)
          if _shortened_hash == _target_hash then
            _frame_to_check = _frame - _i + 1
            break
          end
        end
      end
      for _i = 1, #_frame_data.loops do
        if _frame_to_check >= _frame_data.loops[_i][1] + 1
        and _frame_to_check <= _frame_data.loops[_i][2] + 1 then
          _current_loop = _i
          break
        end
      end
    end
    for i = 1, _frames_prediction do
      if _frame_data and _frame_to_check <= #_frame_data.frames and _frame_data.frames[_frame_to_check] then
        _delta = _delta + 1
        if _frame_data.frames[_frame_to_check].loop then
          _frame_to_check = _frame_data.frames[_frame_to_check].loop + 1
        else
          _used_next_anim = false
          if _frames_prediction - i >= 0 then
            for _, _na in pairs(next_anim_types) do
              if _frame_data.frames[_frame_to_check][_na] then
                if _na == "next_anim" then
                  _used_next_anim = true
                end
                for __, _next_anim in pairs(_frame_data.frames[_frame_to_check][_na]) do
                  if not (_next_anim[1] == "idle") then
                    local _res = predict_frames(_obj, _next_anim[1], _next_anim[2], _frames_prediction - i, _d + 1)
                    if #_res > 0 then
                      for _k,_v in pairs(_res) do
                        _v.delta = _v.delta + _delta
                        table.insert(_results, _v)
                      end
                    end
                  end
                end
              end
            end
          end
          if _used_next_anim then
            break
          else
            _frame_to_check = _frame_to_check + 1
          end
        end
      end
    end
    if _frame_to_check > #_frame_data.frames then
      _frame_to_check = #_frame_data.frames
    end
    if not _used_next_anim then
      table.insert(_results, {animation = _anim, frame = _frame_to_check - 1, delta = _delta})
    end
    return _results
  end
end

function predict_frames_branching(_obj, _anim, _frame, _frames_prediction, _result, _include_start_frame)
  local _results = {}
  local _result = _result or {}
  _frame = _frame or _obj.animation_frame
  local _frame_data = nil
  if _obj.type == "player" then
    _frame_data = find_move_frame_data(_obj.char_str, _anim)
  else
    _frame_data = find_move_frame_data("projectiles", _anim)
  end

  local _frame_to_check = _frame + 1
  local _current_loop = 1
  local _delta = 0
  if #_result > 0 then
    _delta = _result[#_result].delta
  end

  if _include_start_frame then
    _delta = _delta + 1
    _frames_prediction = _frames_prediction - 1
    table.insert(_result, {animation = _anim, frame = _frame, delta = _delta})
  end

  local _used_loop = false
  local _used_next_anim = false

  if not _frame_data then
    return _results
  else
    if _frame_data.loops then


--[[       for _i = 0, #_frame_data.frames do
        local _target_hash = _frame_data.frames[_i + 1].hash
        local _n = 10
        if _obj.type == "player" and _frame_data.infinite_loop then
          _n = 8
          _target_hash = string.sub(_frame_data.frames[_i + 1].hash, _n)
        end
        if _frame + _i + 1 <= #_frame_data.frames then 
          local _shortened_hash = string.sub(_frame_data.frames[_frame + _i + 1].hash, 1, _n)
          if _shortened_hash == _target_hash then
            _frame_to_check = _frame + _i + 1
            break
          end
        end
        if _frame - _i + 1 >= 1 then
          local _shortened_hash = string.sub(_frame_data.frames[_frame - _i + 1].hash, 1, _n)
          if _shortened_hash == _target_hash then
            _frame_to_check = _frame - _i + 1
            break
          end
        end
      end ]]
      for _i = 1, #_frame_data.loops do
        if _frame_to_check >= _frame_data.loops[_i][1] + 1
        and _frame_to_check <= _frame_data.loops[_i][2] + 1 then
          _current_loop = _i
          break
        end
      end
    end
    for i = 1, _frames_prediction do
      if _frame_data and _frame_to_check <= #_frame_data.frames and _frame_data.frames[_frame_to_check] then
        _used_loop = false
        _used_next_anim = false
        _delta = _delta + 1
        if _frame_data.frames[_frame_to_check].loop then
          _used_loop = true
          _frame_to_check = _frame_data.frames[_frame_to_check].loop + 1
        else
          for _, _na in pairs(next_anim_types) do
            if _frame_data.frames[_frame_to_check][_na] then
              if _na == "next_anim" then
                _used_next_anim = true
              end
              for __, _next_anim in pairs(_frame_data.frames[_frame_to_check][_na]) do
                local _current_res = copytable(_result)
                local _next_anim_anim = _next_anim[1]
                local _next_anim_frame = _next_anim[2]
                if _next_anim[1] == "idle" then
                  if _obj.action == 7 or _obj.action_ext == 7 then
                    _next_anim_anim = frame_data[_obj.char_str].crouching
                    _next_anim_frame = 0
                  else
                    _next_anim_anim = frame_data[_obj.char_str].standing
                    _next_anim_frame = 0
                  end
                end
                table.insert(_current_res, {animation = _next_anim_anim, frame = _next_anim_frame, delta = _delta})
                local _subres = predict_frames_branching(_obj, _next_anim_anim, _next_anim_frame, _frames_prediction - i, _current_res)

                for ___, _sr in pairs(_subres) do
                  table.insert(_results, _sr)
                end
              end
            end
          end
        end
        if _used_next_anim then
          break
        else
          if not _used_loop then
            _frame_to_check = math.min(_frame_to_check + 1, #_frame_data.frames)
          end
          table.insert(_result, {animation = _anim, frame = _frame_to_check - 1, delta = _delta})
        end
      end
    end

    if not _used_next_anim then
      table.insert(_results, _result)
    end

    return _results
  end
end

function filter_lines(_player_obj, _lines)
  local _filtered = {}
  for _k, _line in pairs(_lines) do
    local _pass = false
    for i = 1, #_line do
      local _predicted_frame = _line[i]
      local _frame = _predicted_frame.frame
      local _frame_to_check = _frame + 1
      local _frame_data = find_move_frame_data(_player_obj.char_str, _predicted_frame.animation)

      if _frame_data then
        if _frame_data.frames[_frame_to_check].projectile then
          _pass = true
          break
        end

        if _frame_data.hit_frames then
          local _next_hit_id = 1
          for i = 1, #_frame_data.hit_frames do
            if _frame > _frame_data.hit_frames[i][2] then
              _next_hit_id = i + 1
            end
          end
          if _next_hit_id > _player_obj.current_hit_id then
            _pass = true
            break
          end
        end
      end
    end
    if _pass then
      table.insert(_filtered, _line)
    end
  end
  return _filtered
end


function predict_hitboxes(_player_obj, _frames_prediction)
  local _debug = false
  local _results = {}
  local _anim = _player_obj.animation
--   local _predicted_frames = predict_frames(_player_obj, _anim, nil, _frames_prediction)
  local _predicted_frames = predict_frames_branching(_player_obj, _anim, nil, 3)
--
--   local n = 0
--   print(frame_number, "-----")
--   for _k, _predicted_frame in pairs(_pf) do
--     n = 0
--     for _, _p in pairs(_predicted_frame) do
--       print(_p.animation, _p.frame, _p.delta)
--       n = n + 1
--     end
--     print("--", n)
--   end

  for _, _predicted_frame_list in pairs(_predicted_frames) do
    for _k, _predicted_frame in pairs(_predicted_frame_list) do
      local _result = {
        animation = _predicted_frame.animation,
        frame = _predicted_frame.frame,
        frame_data = nil,
        delta = _predicted_frame.delta,
        hit_id = 0,
        pos_x = 0,
        pos_y = 0,
        projectile = nil
      }
      local _frame = _predicted_frame.frame
      local _frame_to_check = _frame + 1
      local _animation_pos = {_player_obj.pos_x, _player_obj.pos_y}
      _frame_data = find_move_frame_data(_player_obj.char_str, _predicted_frame.animation)
  --     print(frame_number,":", _frames_prediction, _predicted_frame.animation, _predicted_frame.frame)

      if _frame_data then
        if _frame_data.frames[_frame_to_check].projectile then
          _result.projectile = _frame_data.frames[_frame_to_check].projectile
        end

        local _next_hit_id = 1
        for i = 1, #_frame_data.hit_frames do
          if _frame > _frame_data.hit_frames[i][2] then
            _next_hit_id = i + 1
          end
        end

        if _next_hit_id <= #_frame_data.hit_frames or _result.projectile then
          if _frame_to_check <= #_frame_data.frames then
            local _next_frame = _frame_data.frames[_frame_to_check]
            local _sign = 1
            if _player_obj.flip_x ~= 0 then _sign = -1 end
            local _next_attacker_pos = copytable(_animation_pos)
            _next_attacker_pos = predict_object_position(_player_obj, _frames_prediction)
            _result.frame_data = _next_frame
            _result.hit_id = _next_hit_id
            _result.pos_x = _next_attacker_pos[1]
            _result.pos_y = _next_attacker_pos[2]
            table.insert(_results, _result)
            if _debug then
              print(string.format(" predicted frame %d: %d hitboxes, hit %d, at %d:%d", _result.frame, #_result.frame_data.boxes, _result.hit_id, _result.pos_x, _result.pos_y))
            end
          end
        end
      end
    end
  end
  return _results
end


function predict_projectile_hitboxes(_obj, _frames_prediction)
  local _result = {
    projectile_type = _obj.projectile_type,
    frame = 0,
    frame_data = {},
    delta = _frames_prediction,
    pos_x = 0,
    pos_y = 0
  }

  local _type = _obj.projectile_type

  local _frame = _obj.animation_frame
  local _frame_to_check = _frame + 1

  --print(string.format("update blocking frame %d (freeze: %d)", _frame, _player_obj.animation_freeze_frames - 1))

--   print(_player_obj.animation, _frame, #_frame_data.frames)

  local _predicted_frames = predict_frames(_obj, _type, nil, _frames_prediction)

  for _k, _predicted_frame in pairs(_predicted_frames) do

    local _frame_data = find_move_frame_data("projectiles", _predicted_frame.animation)
    _result.delta = _predicted_frame.delta

    if not _frame_data then return _result end

    _frame_to_check = _predicted_frame.frame + 1

    if _frame_to_check <= #_frame_data.frames then
      local _next_frame = _frame_data.frames[_frame_to_check]

      local _projectile_pos = predict_object_position(_obj, _frames_prediction)

      _result.projectile_type = _predicted_frame.animation
      _result.frame = _frame_to_check - 1
      _result.frame_data = _next_frame
      _result.delta = _frames_prediction
      _result.pos_x = _projectile_pos[1]
      _result.pos_y = _projectile_pos[2]

    end
  end
--   print(frame_number, _player_obj.animation, _frame, #_frame_data.frames, ">>", _result.frame, _result.hit_id)
  return _result
end


function predict_hurtboxes(_player_obj, _frames_prediction)
  -- There don't seem to be a need for exact idle animation hurtboxes prediction, so let's return the current hurtboxes for the general case

  local _result = _player_obj.boxes
  local _idle_frame_data = frame_data[_player_obj.char_str].idle
  -- If we wake up, we need to foresee the position of the hurtboxes in the frame data so we can block frame 1
  if _player_obj.is_wakingup then
    local _idle_startup_frame_data = frame_data[_player_obj.char_str].wakeup_to_idle
    if _idle_startup_frame_data ~= nil and _idle_frame_data ~= nil then
      local _wakeup_frame = _frames_prediction - _player_obj.remaining_wakeup_time
      if _wakeup_frame >= 0 then
        if _wakeup_frame <= #_idle_startup_frame_data.frames then
          _result = _idle_startup_frame_data.frames[_wakeup_frame + 1].boxes
        else
          local _frame_index = ((_wakeup_frame - #_idle_startup_frame_data.frames) % #_idle_frame_data.frames) + 1
          _result = _idle_frame_data.frames[_frame_index].boxes
        end
      end
    end
  end
  return _result
end

function update_blocking(_input, _player, _dummy, _mode, _style, _red_parry_hit_count, _parry_every_n_count)

  -- ensure variables
  _dummy.blocking.is_blocking = _dummy.blocking.is_blocking or false
  _dummy.blocking.blocked_hit_count = _dummy.blocking.blocked_hit_count or 0
  _dummy.blocking.expected_attacks = {}
  _dummy.blocking.last_blocked_attacks = _dummy.blocking.last_blocked_attacks or {}
  _dummy.blocking.last_blocked_type = _dummy.blocking.last_blocked_type or "none"
  _dummy.blocking.last_blocked_frame = _dummy.blocking.last_blocked_frame or 0
  _dummy.blocking.parried_last_frame = _dummy.blocking.parried_last_frame or false


  _player.cooldown = _player.cooldown or 0

  function reset_parry_cooldowns(_player_obj)
    memory.writebyte(_player_obj.parry_forward_cooldown_time_addr, 0)
    memory.writebyte(_player_obj.parry_down_cooldown_time_addr, 0)
    memory.writebyte(_player_obj.parry_air_cooldown_time_addr, 0)
    memory.writebyte(_player_obj.parry_antiair_cooldown_time_addr, 0)
  end

  function block_attack(_hit_type, _block_type, _delta, _reverse, _force_block)
    local _p2_forward = bool_xor(_dummy.flip_input, _reverse)
    local _p2_back = not bool_xor(_dummy.flip_input, _reverse)
    if _block_type == 1 and _dummy.pos_y <= 8 then --no air blocking!
      _input[_dummy.prefix..' Right'] = _p2_back
      _input[_dummy.prefix..' Left'] = _p2_forward

      if _hit_type == 2 then
        _input[_dummy.prefix..' Down'] = true
      elseif _hit_type == 3 or _hit_type == 4 then
        _input[_dummy.prefix..' Down'] = false
      end
      return "block"
    elseif _block_type == 2 then
      local _parry_type = "parry_forward"
      if _dummy.pos_y > 8 then
        _parry_type = "parry_air"
      else
        if _player.posture == "placeholder" then
          _parry_type = "parry_antiair"
        end
      end
      local _parry_low = _hit_type == 2 or (training_settings.prefer_down_parry and _hit_type == 1 and _dummy.pos_y <= 8)
      if _parry_low then
        _parry_type = "parry_down"
      end

      if not (_dummy[_parry_type].validity_time > _delta) or _force_block then
        if is_previous_input_neutral(_dummy) and not (_hit_type == 5) then
          _input[_dummy.prefix..' Right'] = false
          _input[_dummy.prefix..' Left'] = false
          _input[_dummy.prefix..' Down'] = false
          if _parry_low then
            _input[_dummy.prefix..' Down'] = true
          else
            _input[_dummy.prefix..' Right'] = _p2_forward
            _input[_dummy.prefix..' Left'] = _p2_back
          end
          return "parry"
        else
          print("can not parry")
          block_attack(_hit_type, 1, _delta, _reverse)
        end
      end
    end
    return "none"
  end


  if not is_in_match then
    return
  end

  -- exit if playing recording
  if _mode == 1 or current_recording_state == 4 then
    return
  end
  if _mode == 4 then
    local _r = math.random()
    if _mode ~= 3 or _r > 0.5 then
      _dummy.blocking.randomized_out = true
    else
      _dummy.blocking.randomized_out = false
    end
  end


  predicted_hit_debug = predicted_hit_debug or {}

--[[   if _player.char_str == "oro" and _player.selected_sa == 3 and _player.is_in_timed_sa then
    if _player.has_just_acted then
      local _frame_data = _player.animation_frame_data
      if _frame_data then
        local _next_hit_id = _player.current_hit_id + 1
        if _frame_data.hit_frames and _frame_data.hit_frames[_next_hit_id] then
          local _delta = _frame_data.hit_frames[_next_hit_id][1] - _player.animation_frame + 1
          for _, _proj in pairs(projectiles) do
            if _proj.emitter_id == _player.id
            and _proj.type == "00_tenguishi"
            then
              _proj.cooldown = _delta
            end
          end
        end
      end
    end
  else ]]
  if _player.char_str == "yang" and _player.is_in_timed_sa then
    if _player.has_just_attacked then
      local _frame_data = _player.animation_frame_data
      if _frame_data then
        local _next_hit_id = _player.current_hit_id + 1
        if _frame_data.hit_frames and _frame_data.hit_frames[_next_hit_id] then
          local _delta = _frame_data.hit_frames[_next_hit_id][1] - _player.animation_frame + 1
          for _, _proj in pairs(projectiles) do
            if _proj.emitter_id == _player.id
            and _proj.type == "00_tenguishi"
            then
              _proj.cooldown = 10
              _proj.seiei_animation = _player.animation
              _proj.seiei_frame = _player.animation_frame
              insert_projectile(_player, _motion_data, _predicted_hit)
            end
          end
        end
      end
    end
  end

  local _frames_prediction = 3
  predict_everything(_player, _dummy, _frames_prediction)


  if _dummy.received_connection then
    _dummy.blocking.blocked_hit_count = _dummy.blocking.blocked_hit_count + 1
  end

  if _dummy.is_idle then
    if _player.is_idle then
      _dummy.blocking.blocked_hit_count = 0
    end
    _dummy.blocking.is_blocking = false
  end


  if not (_mode == 4 and _dummy.blocking.randomized_out) 
  and not (_mode == 3 and _dummy.blocking.blocked_hit_count > 0) then
    --     print(string.format("%d - should block %s", frame_number, tostring(_dummy.blocking.should_block)))
    local _block_type = _style -- 1 is block, 2 is parry
    local _blocking_delta_threshold = 2
    local _precise_blocking = false
    local _blocking_queue = {}

    if _style == 3 then -- red parry
      _block_type = 1
      _blocking_delta_threshold = 1
      _precise_blocking = true
      if _dummy.blocking.blocked_hit_count >= _red_parry_hit_count then
        if (_dummy.blocking.blocked_hit_count - _red_parry_hit_count) % (_parry_every_n_count + 1) == 0 then
          _block_type = 2
        end
      end
    end

    if _dummy.blocking.forced_block then
      local _d = _dummy.blocking.forced_block.delta
      if _blocking_queue[_d] == nil then
        _blocking_queue[_d] = {}
        _blocking_queue[_d].hit_type = _dummy.blocking.forced_block.hit_type
        _blocking_queue[_d].blocking_type = _dummy.blocking.forced_block.blocking_type
        _blocking_queue[_d].attacks = {}
      end
      for _, _attack in pairs(_dummy.blocking.forced_block.attacks) do
        if _attack.blocking_type == "projectile" then
          _attack.reverse = _attack.flip_x == _dummy.flip_input
        end
        table.insert(_blocking_queue[_d].attacks, _attack)
      end
      _dummy.blocking.forced_block = nil
    end

    for i = 1, #_dummy.blocking.expected_attacks do
      local _expected_attack = _dummy.blocking.expected_attacks[i]
      local _expected_attack_delta = _expected_attack.delta
      local _hit_type = 1

      if _blocking_queue[_expected_attack_delta] == nil then
        _blocking_queue[_expected_attack_delta] = {}
        _blocking_queue[_expected_attack_delta].hit_type = 0
        _blocking_queue[_expected_attack_delta].attacks = {}
      end

      if _expected_attack.blocking_type == "projectile" then
        local _frame_data_meta = frame_data_meta["projectiles"][_expected_attack.animation]
        if _frame_data_meta and _frame_data_meta.hit_type then
          _hit_type = _frame_data_meta.hit_type[_expected_attack.hit_id]
        end
      else
        local _frame_data_meta = frame_data_meta[_player.char_str][_expected_attack.animation]
        if _frame_data_meta then
          if _frame_data_meta.hit_type and _frame_data_meta.hit_type[_expected_attack.hit_id] then
            _hit_type = _frame_data_meta.hit_type[_expected_attack.hit_id] --debug
          end
          if _frame_data_meta.unparryable then
            _blocking_queue[_expected_attack_delta].unparryable = true
          end
        end
      end

      if _hit_type > _blocking_queue[_expected_attack_delta].hit_type then
        if training_settings.prefer_down_parry and _blocking_queue[_expected_attack_delta].hit_type == 1 then
          _blocking_queue[_expected_attack_delta].hit_type = 2
        else
          _blocking_queue[_expected_attack_delta].hit_type = _hit_type
        end
        if _expected_attack.blocking_type == "projectile" then
          _expected_attack.reverse = _expected_attack.flip_x == _dummy.flip_input
        end
        table.insert(_blocking_queue[_expected_attack_delta].attacks, _expected_attack)
      end

      -- print(frame_number, _expected_attack_delta, _expected_attack.blocking_type, _expected_attack.animation, _dummy.current_hit_id, _expected_attack.hit_id)
    end

    function should_ignore(_attack)
      for _, _last_blocked_attack in pairs(_dummy.blocking.last_blocked_attacks) do
        if (_attack.id == 1 or _attack.id == 2) and _attack.id == _last_blocked_attack.id then
          if _attack.animation == _last_blocked_attack.animation then
            if _attack.hit_id > _last_blocked_attack.hit_id then
              return false
            else
              return true
            end
          end
        elseif _attack.animation == _last_blocked_attack.animation then
          if frame_number - _last_blocked_attack.connect_frame <= _blocking_delta_threshold then
            return true
          end
        end
      end
      return false
    end

    for _key, _attack in pairs(_dummy.blocking.last_blocked_attacks) do
      if _attack.connect_frame <= frame_number then
        _dummy.blocking.last_blocked_attacks[_key] = nil
      end
    end

    local _next_attacks = {}
    local _delta = 0
    --attacks must be blocked/parried 1 frame before they actually hit
    --_blocking_delta_threshold = 1 at a minimum
    for i = 1, _blocking_delta_threshold do
      if _blocking_queue[i] then
        for _, _attack in pairs(_blocking_queue[i].attacks) do
          if _precise_blocking then
            if not should_ignore(_attack) then
              table.insert(_next_attacks, _attack)
            end
          else
            table.insert(_next_attacks, _attack)
          end
        end
      end
      if #_next_attacks > 0 then
        _delta = i
        break
      end
    end

    if #_next_attacks > 0 then
      _dummy.blocking.is_blocking = true
      local _reverse = false
      local _force_block = false
      for _, _attack in pairs(_next_attacks) do
        --reverse blocking direction for projectiles created on the opposite side (parrying out of unblockables)
        if _attack.reverse then
          _reverse = true
        end
        local _t = _attack.animation or _attack.projectile_type
        print(_blocking_queue[_delta], _delta)
        print(string.format("#%d - hit in [%d] type: %s hit type: %d", frame_number, _attack.delta, _t, _blocking_queue[_delta].hit_type))
      end
      
      if _block_type == 2 and _blocking_queue[_delta] and _blocking_queue[_delta + 1] then
        if _blocking_queue[_delta].hit_type == 1 and _blocking_queue[_delta + 1].hit_type ~= 1 then
          _blocking_queue[_delta].hit_type = _blocking_queue[_delta + 1].hit_type
        end
      end

      if _block_type == 2 then
        if _blocking_queue[_delta].unparryable then
          _block_type = 1
        end
--[[         if not _dummy.blocking.parried_last_frame
        and not (_blocking_queue[_delta + 1]
        and _blocking_queue[_delta].hit_type == _blocking_queue[_delta + 1].hit_type)
        then
          print("force bl")
          _force_block = true
        end ]]
        if _player.superfreeze_decount > 0 then
          memory.writebyte(_dummy.parry_forward_validity_time_addr, 0xA)
          memory.writebyte(_dummy.parry_down_validity_time_addr, 0xA)
          memory.writebyte(_dummy.parry_air_validity_time_addr, 0x7)
          memory.writebyte(_dummy.parry_antiair_validity_time_addr, 0x5)
        end
      end

      if not (_block_type == 1 and _dummy.blocking.parried_last_frame) then
        _dummy.blocking.last_blocked_type = block_attack(_blocking_queue[_delta].hit_type, _block_type, _delta, _reverse, _force_block)
        if _dummy.blocking.last_blocked_type ~= "none" then
          _dummy.blocking.last_blocked_frame = frame_number
          for _, _attack in pairs(_next_attacks) do
            _attack.connect_frame = frame_number + _delta
          end
          if (_block_type == 1 and _delta == 1)
          or _block_type == 2 then
            _dummy.blocking.last_blocked_attacks = _next_attacks
          end
          if (_style == 1 and _delta > 1 )
          or (_block_type == 1 and _delta > 1 and _dummy.blocking.blocked_hit_count == 0) then
            _dummy.blocking.forced_block = {delta = _delta - 1,
                                            attacks = _next_attacks,
                                            blocking_type = _blocking_queue[_delta].blocking_type,
                                            hit_type = _blocking_queue[_delta].hit_type}
          end
        end
      end
    end



    _dummy.blocking.parried_last_frame = false
    if _dummy.blocking.last_blocked_type == "parry"
    and frame_number - _dummy.blocking.last_blocked_frame == 0
    then
      _dummy.blocking.parried_last_frame = true
    end
  end
end

function is_previous_input_neutral(_player_obj)
  if previous_input then
    if previous_input[_player_obj.prefix.." Up"] == false
    and previous_input[_player_obj.prefix.." Down"] == false
    and previous_input[_player_obj.prefix.." Left"] == false
    and previous_input[_player_obj.prefix.." Right"] == false then
      return true
    end
  end
  return false
end

local stun_mash_start_frame = 1
local mash_inputs_realistic =
{
  {{"down","forward"}},
  {{"down"}},
  {{"down","back"}},
  {{"back"}},
  {{"up","back"}},
  {{"up"}},
  {{"up","forward"}},
  {{"forward"}}
}
local mash_inputs_fastest =
{
  {{"down","forward"}},
  {{"down","back"}}
}
local mash_inputs = mash_inputs_fastest
local all_buttons = {"LP","LK","MP","MK","HP","HK"}

function update_mash_stun(_input, _player, _dummy, _mode)
  if is_in_match and _mode ~= 1 and current_recording_state ~= 4 then
    if _dummy.stun_just_began then
      stun_mash_start_frame = frame_number
      if _mode == 2 then
        mash_inputs = mash_inputs_fastest
      elseif _mode == 3 then
        mash_inputs = mash_inputs_realistic
      end
    end
    if _dummy.stunned then
      --try to prevent move from coming out
      --diagonal input reduces stun by 3
      --pressing all buttons reduces stun by 4 more
      if _dummy.stun_timer <= 15 and _dummy.stun_timer > 0 then
        mash_inputs = mash_inputs_fastest
      end
      local _elapsed = frame_number - stun_mash_start_frame
      local _sequence = deepcopy(mash_inputs[_elapsed % #mash_inputs + 1])
      if _dummy.stun_timer >= 8 then
        if _mode == 2 then
          if _elapsed % 2 == 0 then
            for _,_button in pairs(all_buttons) do
              table.insert(_sequence[1], _button)
            end
          end
        elseif _mode == 3 then
          table.insert(_sequence[1], all_buttons[_elapsed % 3 + 1])
          table.insert(_sequence[1], all_buttons[6 - _elapsed % 3])
        end
      end
      queue_input_sequence(_dummy, _sequence)
    end
  end
end

function update_fast_wake_up(_input, _player, _dummy, _mode)
  if is_in_match and _mode ~= 1 and current_recording_state ~= 4 then
    local _should_tap_down = _dummy.previous_can_fast_wakeup == 0 and _dummy.can_fast_wakeup == 1

    if _should_tap_down then
      local _r = math.random()
      if _mode ~= 3 or _r > 0.5 then
        _input[dummy.prefix..' Down'] = true
      end
    end
  end
end

function get_stun_reduction_value(_sequence)
  local n_kicks = 0
  local total = 0
  for i = 1, #_sequence do
    local has_dir = false
    for j = 1, #_sequence[i] do
      if _sequence[i][j] == "forward"
      or _sequence[i][j] == "back"
      or _sequence[i][j] == "up"
      or _sequence[i][j] == "down" then
        total = total + 1
        has_dir = true
      elseif _sequence[i][j] == "LP"
      or _sequence[i][j] == "MP"
      or _sequence[i][j] == "HP" then
        total = total + 1
      elseif _sequence[i][j] == "LK"
      or _sequence[i][j] == "MK"
      or _sequence[i][j] == "HK" then
        n_kicks = n_kicks + 1
      end
    end
  end
  return total + #_sequence + math.floor(n_kicks / 3)
end

local wakeup_queued = false
function update_counter_attack(_input, _attacker, _defender, _counter_attack_settings, _hits_before)

  local _debug = false

  if not is_in_match then return end
  if current_recording_state == 4 then return end

  if _defender.posture ~= 0x26 then
    wakeup_queued = false
  end


  function handle_recording()
    if counter_attack_settings.ca_type == 5 and dummy.id == 2 then
      local _slot_index = training_settings.current_recording_slot
      if training_settings.replay_mode == 2 or training_settings.replay_mode == 5 then
        _slot_index = find_random_recording_slot()
      elseif training_settings.replay_mode == 3 or training_settings.replay_mode == 6 then
        _slot_index = go_to_next_ordered_slot()
      end
      if _slot_index < 0 then
        return
      end

      _defender.counter.counter_type = "recording"
      _defender.counter.recording_slot = _slot_index

      local _delay = recording_slots[_defender.counter.recording_slot].delay or 0
      local _random_deviation = recording_slots[_defender.counter.recording_slot].random_deviation or 0
      if _random_deviation <= 0 then
        _random_deviation = math.ceil(math.random(_random_deviation - 1, 0))
      else
        _random_deviation = math.floor(math.random(0, _random_deviation + 1))
      end
      if _debug then
        print(string.format("frame offset: %d", _delay + _random_deviation))
      end
      _defender.counter.attack_frame = _defender.counter.attack_frame + _delay + _random_deviation
    end
  end
  if _defender.blocking.blocked_hit_count >= _hits_before then
    if _defender.has_just_parried then
      if _debug then
        print(frame_number.." - init ca (parry)")
      end
      log(_defender.prefix, "counter_attack", "init ca (parry)")
      _defender.counter.counter_type = "reversal"
      _defender.counter.attack_frame = frame_number + 15
      if _defender.pos_y >= 8 then
        _defender.counter.attack_frame = _defender.counter.attack_frame + 2
      end
      if _counter_attack_settings.ca_type == 3 then
        _defender.counter.attack_frame = _defender.counter.attack_frame + 1
      end
      _defender.counter.sequence, _defender.counter.offset = make_input_sequence(_defender.char_str, _counter_attack_settings)
      if counter_attack_special_types[_counter_attack_settings.special] == "kara_special" then
        _defender.counter.offset = _defender.counter.offset + 1
        if counter_attack_special[_counter_attack_settings.special] == "kara_karakusa_lk" then
          for i = 1, 8 do
            table.insert(_defender.counter.sequence, 2, {})
          end
        end
      elseif counter_attack_special[_counter_attack_settings.special] == "sgs" then
        _defender.counter.offset = _defender.counter.offset + 4
      end
      _defender.counter.ref_time = -1
      handle_recording()

    elseif _defender.has_just_blocked or (_defender.has_just_been_hit and not _defender.is_being_thrown) then
      if _debug then
        print(frame_number.." - init ca (hit/block)")
      end
      log(_defender.prefix, "counter_attack", "init ca (hit/block)")
      _defender.counter.ref_time = _defender.recovery_time
      clear_input_sequence(_defender)
      _defender.counter.attack_frame = -1
      _defender.counter.sequence = nil
      _defender.counter.recording_slot = -1
    elseif _defender.is_wakingup and _defender.remaining_wakeup_time > 0
    and _defender.remaining_wakeup_time <= 20 and not wakeup_queued then
      if _debug then
        print(frame_number.." - init ca (wake up)")
      end
      log(_defender.prefix, "counter_attack", "init ca (wakeup)")
      _defender.counter.attack_frame = frame_number + _defender.remaining_wakeup_time
      wakeup_queued = true
      if counter_attack_settings.ca_type == 4 then
        local _os = counter_attack_option_select[_counter_attack_settings.option_select]
        if is_guard_jump(_os) then
          _defender.counter.counter_type = "guard_jump"
          _defender.counter.attack_frame = _defender.counter.attack_frame - 4 --avoid hj input
        else
          _defender.counter.counter_type = "other_os"
        end
      elseif (counter_attack_settings.ca_type == 2 and counter_attack_motion[counter_attack_settings.motion] == "kara_throw") then
        _defender.counter.counter_type = "reversal"
        _defender.counter.attack_frame = _defender.counter.attack_frame
      else
        _defender.counter.counter_type = "reversal"
        _defender.counter.attack_frame = _defender.counter.attack_frame + 2
      end
      _defender.counter.sequence, _defender.counter.offset = make_input_sequence(_defender.char_str, _counter_attack_settings)
      _defender.counter.ref_time = -1
      handle_recording()
    elseif _defender.has_just_entered_air_recovery then
      clear_input_sequence(_defender)
      _defender.counter.counter_type = "reversal"
      _defender.counter.ref_time = -1
      _defender.counter.attack_frame = frame_number + 100
      _defender.counter.sequence, _defender.counter.offset = make_input_sequence(_defender.char_str, _counter_attack_settings)
      _defender.counter.air_recovery = true
      handle_recording()
      log(_defender.prefix, "counter_attack", "init ca (air)")
    end
  end

  if not _defender.counter.sequence then --has just blocked/been hit
    if _defender.counter.ref_time ~= -1 and _defender.recovery_time ~= _defender.counter.ref_time then
      if _debug then
        print(frame_number.." - setup ca")
      end
      log(_defender.prefix, "counter_attack", "setup ca")
      _defender.counter.attack_frame = frame_number + _defender.recovery_time

      -- special character cases
      if _defender.is_crouched then
        if (_defender.char_str == "q" or _defender.char_str == "ryu" or _defender.char_str == "chunli") then
          _defender.counter.attack_frame = _defender.counter.attack_frame + 2
        end
      else
        if _defender.char_str == "q" then
          _defender.counter.attack_frame = _defender.counter.attack_frame + 1
        end
      end

      _defender.counter.counter_type = "reversal"

      if counter_attack_settings.ca_type == 4 then
        local _os = counter_attack_option_select[_counter_attack_settings.option_select]
        if is_guard_jump(_os) then
          _defender.counter.counter_type = "guard_jump"
          _defender.counter.attack_frame = _defender.counter.attack_frame - 3 --avoid hj input
        else
          _defender.counter.counter_type = "other_os"
        end
      elseif counter_attack_settings.ca_type == 2 and counter_attack_motion[counter_attack_settings.motion] == "kara_throw" then

      else
        _defender.counter.attack_frame = _defender.counter.attack_frame + 2
      end
      _defender.counter.sequence, _defender.counter.offset = make_input_sequence(_defender.char_str, _counter_attack_settings)
      _defender.counter.ref_time = -1
      handle_recording()
    end
  end

  if _defender.counter.sequence then
    if _defender.counter.air_recovery then
      local _frames_before_landing = predict_frames_before_landing(_defender)
      if _frames_before_landing > 0 then
        _defender.counter.attack_frame = frame_number + _frames_before_landing + 2
      elseif _frames_before_landing == 0 then
        _defender.counter.attack_frame = frame_number
      end
    end
    if _defender.stunned then
      local _seq_stun_reduction = get_stun_reduction_value(_defender.counter.sequence)
      if _seq_stun_reduction <= _defender.stun_timer then

      end
    end
    local _frames_remaining = _defender.counter.attack_frame - frame_number
    if _debug then
      print(_frames_remaining)
    end

    --option select
    if counter_attack_settings.ca_type == 4 or (counter_attack_settings.ca_type == 2 and counter_attack_motion[counter_attack_settings.motion] == "kara_throw") then
      if _frames_remaining <= 0 then
        print(_defender.counter.attack_frame, frame_number-_defender.counter.attack_frame, #_defender.counter.sequence, _defender.counter.offset)
        queue_input_sequence(_defender, _defender.counter.sequence, _defender.counter.offset)
        _defender.counter.sequence = nil
        _defender.counter.attack_frame = -1
        _defender.counter.air_recovery = false
      end
    elseif _defender.counter.counter_type == "reversal" then
      if _frames_remaining <= (#_defender.counter.sequence + 1) then
        if _debug then
          print(frame_number.." - queue ca")
        end
        log(_defender.prefix, "counter_attack", string.format("queue ca %d", _frames_remaining))
        queue_input_sequence(_defender, _defender.counter.sequence, _defender.counter.offset)
        _defender.counter.sequence = nil
        _defender.counter.attack_frame = -1
        _defender.counter.air_recovery = false
      end
    end
  elseif counter_attack_settings.ca_type == 5 and _defender.counter.recording_slot > 0 then
    if _defender.counter.attack_frame <= (frame_number + 1) then
      if training_settings.replay_mode == 2 or training_settings.replay_mode == 3 or training_settings.replay_mode == 5 or training_settings.replay_mode == 6 then
        override_replay_slot = _defender.counter.recording_slot
      end
      if _debug then
        print(frame_number.." - queue recording")
      end
      log(_defender.prefix, "counter_attack", "queue recording")
      _defender.counter.attack_frame = -1
      _defender.counter.recording_slot = -1
      _defender.counter.air_recovery = false
      set_recording_state(_input, 1)
      set_recording_state(_input, 4)
      override_replay_slot = -1
    end
  end

  --debug cancel CA if gpoing to get hit. trade ok
  if counter_attack_settings.ca_type > 1 then
    if _defender.blocking.should_block or _defender.blocking.should_block_projectile then
      if _defender.pending_input_sequence and _defender.pending_input_sequence.sequence then
        local _remaining_frames = #_defender.pending_input_sequence.sequence - _defender.pending_input_sequence.current_frame
        if _remaining_frames >= _defender.blocking.animation_frame_delta then
          clear_input_sequence(_defender)
        end
      end
    end
  end
end

function update_tech_throws(_input, _attacker, _defender, _mode)
  local _debug = false

  if not is_in_match or _mode == 1 then
    _defender.throw.listening = false
    if _debug and _attacker.previous_throw_countdown > 0 then
      print(string.format("%d - %s stopped listening for throws", frame_number, _defender.prefix))
    end
    return
  end

  if _attacker.throw_countdown > _attacker.previous_throw_countdown then
    _defender.throw.listening = true
    if _debug then
      print(string.format("%d - %s listening for throws", frame_number, _defender.prefix))
    end
  end

  if _attacker.throw_countdown == 0 then
    _defender.throw.listening = false
    if _debug and _attacker.previous_throw_countdown > 0  then
      print(string.format("%d - %s stopped listening for throws", frame_number, _defender.prefix))
    end
  end

  if _defender.throw.listening then

    if test_collision(
      _defender.pos_x, _defender.pos_y, _defender.flip_x, _defender.boxes, -- defender
      _attacker.pos_x, _attacker.pos_y, _attacker.flip_x, _attacker.boxes, -- attacker
      {{{"throwable"},{"throw"}}},
      0, -- defender hitbox dilation
      0
    ) then
      _defender.throw.listening = false
      if _debug then
        print(string.format("%d - %s teching throw", frame_number, _defender.prefix))
      end
      local _r = math.random()
      if _mode ~= 3 or _r > 0.5 then
        _input[_defender.prefix..' Weak Punch'] = true
        _input[_defender.prefix..' Weak Kick'] = true
      end
    end
  end
end

function play_challenge()
  is_in_challenge = true
  --hadou
  if training_settings.challenge_current_mode == 1 then
    --load ss
    hadou_matsuri_start()
  end
end


-- RECORDING POPUPS

function clear_slot()
  recording_slots[training_settings.current_recording_slot] = make_recording_slot()
  save_training_data()
end

function clear_all_slots()
  for _i = 1, recording_slot_count do
    recording_slots[_i] = make_recording_slot()
  end
  training_settings.current_recording_slot = 1
  save_training_data()
end

function open_save_popup()
  save_recording_slot_popup.selected_index = 1
  menu_stack_push(save_recording_slot_popup)
  save_file_name = string.gsub(dummy.char_str, "(.*)", string.upper).."_"
end

function open_load_popup()
  load_recording_slot_popup.selected_index = 1
  menu_stack_push(load_recording_slot_popup)

  load_file_index = 1

  local _cmd = "dir /b "..string.gsub(saved_recordings_path, "/", "\\")
  local _f = io.popen(_cmd)
  if _f == nil then
    print(string.format("Error: Failed to execute command \"%s\"", _cmd))
    return
  end
  local _str = _f:read("*all")
  load_file_list = {}
  for _line in string.gmatch(_str, '([^\r\n]+)') do -- Split all lines that have ".json" in them
    if string.find(_line, ".json") ~= nil then
      local _file = _line
      table.insert(load_file_list, _file)
    end
  end
  load_recording_slot_popup.content[1].list = load_file_list
end

function save_recording_slot_to_file()
  if save_file_name == "" then
    print(string.format("Error: Can't save to empty file name"))
    return
  end

  local _path = string.format("%s%s.json",saved_recordings_path, save_file_name)
  if not write_object_to_json_file(recording_slots[training_settings.current_recording_slot].inputs, _path) then
    print(string.format("Error: Failed to save recording to \"%s\"", _path))
  else
    print(string.format("Saved slot %d to \"%s\"", training_settings.current_recording_slot, _path))
  end

  menu_stack_pop(save_recording_slot_popup)
end

function load_recording_slot_from_file()
  if #load_file_list == 0 or load_file_list[load_file_index] == nil then
    print(string.format("Error: Can't load from empty file name"))
    return
  end

  local _path = string.format("%s%s",saved_recordings_path, load_file_list[load_file_index])
  local _recording = read_object_from_json_file(_path)
  if not _recording then
    print(string.format("Error: Failed to load recording from \"%s\"", _path))
  else
    recording_slots[training_settings.current_recording_slot].inputs = _recording
    print(string.format("Loaded \"%s\" to slot %d", _path, training_settings.current_recording_slot))
  end
  save_training_data()

  menu_stack_pop(load_recording_slot_popup)
end

current_recording_slot_frames = {}

function update_current_recording_slot_frames()
  current_recording_slot_frames[1] = #recording_slots[training_settings.current_recording_slot].inputs
end

-- GUI DECLARATION

training_settings = {
  pose = 1,
  blocking_style = 1,
  blocking_mode = 1,
  prefer_down_parry = false,
  tech_throws_mode = 1,
  red_parry_hit_count = 1,
  counter_attack_type_index = 1,
  counter_attack_stick = 1,
  counter_attack_button = 1,
  fast_wakeup_mode = 1,
  infinite_time = true,
  life_mode = 1,
  meter_mode = 1,
  p1_meter = 0,
  p2_meter = 0,
  infinite_sa_time = false,
  stun_mode = 1,
  p1_stun_reset_value = 0,
  p2_stun_reset_value = 0,
  stun_reset_delay = 20,
  display_input = true,
  display_gauges = false,
  display_input_history = 4,
  display_attack_data = false,
  display_attack_bars = 3,
  display_frame_advantage = false,
  display_hitboxes = false,
  display_distances = false,
  mid_distance_height = 70,
  p1_distances_reference_point = 1,
  p2_distances_reference_point = 2,
  display_red_parry_miss = true,
  auto_crop_recording_start = true,
  auto_crop_recording_end = true,
  current_recording_slot = 1,
  replay_mode = 1,
  music_volume = 10,
  life_refill_delay = 20,
  meter_refill_delay = 20,
  challenge_current_mode = 1,
  fast_forward_intro = true,
  universal_cancel = false,
  infinite_projectiles = false,
  infinite_juggle = false,
  controller_style = 2,
  language = 1,

  -- special training
  special_training_current_mode = 1,
  charge_follow_character = true,
  special_training_parry_forward_on = true,
  special_training_parry_down_on = true,
  special_training_parry_air_on = true,
  special_training_parry_antiair_on = true,
  special_training_charge_overcharge_on = false,
}

counter_attack_settings =
{
    ca_type = 1,
    motion = 1,
    button = 1,
    special = 1,
    special_button = 1,
    option_select = 1
}

debug_settings = {
  show_predicted_hitbox = false,
  record_framedata = false,
  record_idle_framedata = false,
  record_wakeupdata = false,
  debug_character = "",
  debug_move = "",
}

function update_counter_attack_settings()
  if menu_loaded then
    counter_attack_settings = training_settings.counter_attack[dummy.char_str]
    counter_attack_item.object = counter_attack_settings
    counter_attack_motion_item.object = counter_attack_settings
    counter_attack_button_item.object = counter_attack_settings
    counter_attack_special_item.object = counter_attack_settings
    counter_attack_special_button_item.object = counter_attack_settings
    counter_attack_option_select_item.object = counter_attack_settings
    counter_attack_input_display_item.object = counter_attack_settings
  end
end


menu_loaded = false
function init_menu()
  save_file_name = ""
  save_recording_slot_popup = make_menu(71, 61, 312, 122, -- screen size 383,223
  {
    textfield_menu_item("file_name", _G, "save_file_name", ""),
    button_menu_item("save", save_recording_slot_to_file),
    button_menu_item("cancel", function() menu_stack_pop(save_recording_slot_popup) end),
  })

  load_file_list = {}
  load_file_index = 1
  load_recording_slot_popup = make_menu(71, 61, 312, 122, -- screen size 383,223
  {
    list_menu_item("file", _G, "load_file_index", load_file_list),
    button_menu_item("load", load_recording_slot_from_file),
    button_menu_item("cancel", function() menu_stack_pop(load_recording_slot_popup) end),
  })

  controller_style_menu_item = controller_style_item("controller_style", training_settings, "controller_style", controller_styles)
  controller_style_menu_item.is_disabled = function()
    return not training_settings.display_input and training_settings.display_input_history == 1
  end


  life_refill_delay_item = integer_menu_item("life_refill_delay", training_settings, "life_refill_delay", 1, 100, false, 20)
  life_refill_delay_item.is_disabled = function()
    return training_settings.life_mode ~= 2
  end

  p1_life_reset_value_gauge_item = gauge_menu_item("p1_life_reset_value", training_settings, "p1_life_reset_value", 160, life_color)
  p2_life_reset_value_gauge_item = gauge_menu_item("p2_life_reset_value", training_settings, "p2_life_reset_value", 160, life_color)

  p1_stun_reset_value_gauge_item = gauge_menu_item("p1_stun_reset_value", training_settings, "p1_stun_reset_value", 64, stun_color)
  p2_stun_reset_value_gauge_item = gauge_menu_item("p2_stun_reset_value", training_settings, "p2_stun_reset_value", 64, stun_color)
  p1_stun_reset_value_gauge_item.unit = 1
  p2_stun_reset_value_gauge_item.unit = 1
  stun_reset_delay_item = integer_menu_item("stun_reset_delay", training_settings, "stun_reset_delay", 1, 100, false, 20)
  p1_stun_reset_value_gauge_item.is_disabled = function()
    return training_settings.stun_mode ~= 3
  end
  p2_stun_reset_value_gauge_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled
  stun_reset_delay_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled

  p1_meter_gauge_item = gauge_menu_item("p1_meter_reset_value", training_settings, "p1_meter_reset_value", 2, meter_color)
  p2_meter_gauge_item = gauge_menu_item("p2_meter_reset_value", training_settings, "p2_meter_reset_value", 2, meter_color)
  meter_refill_delay_item = integer_menu_item("meter_refill_delay", training_settings, "meter_refill_delay", 1, 100, false, 20)

  p1_meter_gauge_item.is_disabled = function()
    return training_settings.meter_mode ~= 2
  end
  p2_meter_gauge_item.is_disabled = p1_meter_gauge_item.is_disabled
  meter_refill_delay_item.is_disabled = p1_meter_gauge_item.is_disabled


  slot_weight_item = integer_menu_item("weight", recording_slots[training_settings.current_recording_slot], "weight", 0, 100, false, 1)
  counter_attack_delay_item = integer_menu_item("counter_attack_delay", recording_slots[training_settings.current_recording_slot], "delay", -40, 40, false, 0)
  counter_attack_random_deviation_item = integer_menu_item("counter_attack_max_random_deviation", recording_slots[training_settings.current_recording_slot], "random_deviation", -600, 600, false, 0, 1)

  parry_forward_on_item = checkbox_menu_item("forward_parry_helper", training_settings, "special_training_parry_forward_on")
  parry_forward_on_item.is_disabled = function() return training_settings.special_training_current_mode ~= 2 end
  parry_down_on_item = checkbox_menu_item("down_parry_helper", training_settings, "special_training_parry_down_on")
  parry_down_on_item.is_disabled = parry_forward_on_item.is_disabled
  parry_air_on_item = checkbox_menu_item("air_parry_helper", training_settings, "special_training_parry_air_on")
  parry_air_on_item.is_disabled = parry_forward_on_item.is_disabled
  parry_antiair_on_item = checkbox_menu_item("anti-air_parry_helper", training_settings, "special_training_parry_antiair_on")
  parry_antiair_on_item.is_disabled = parry_forward_on_item.is_disabled

  charge_overcharge_on_item = checkbox_menu_item("display_overcharge", training_settings, "special_training_charge_overcharge_on")
  charge_overcharge_on_item.indent = true
  charge_overcharge_on_item.is_disabled = function()
  return not training_settings.display_charge
  end

  charge_follow_character_item = checkbox_menu_item("follow_character", training_settings, "charge_follow_character")
  charge_follow_character_item.indent = true
  charge_follow_character_item.is_disabled = function()
  return not training_settings.display_charge
  end

  blocking_item = list_menu_item("blocking", training_settings, "blocking_mode", blocking_mode)
  blocking_item.indent = true

  hits_before_red_parry_item = hits_before_menu_item("hits_before_rp_prefix", "hits_before_rp_suffix", training_settings, "red_parry_hit_count", 0, 20, true, 1)
  hits_before_red_parry_item.indent = true
  hits_before_red_parry_item.is_disabled = function()
    return training_settings.blocking_style ~= 3
  end

  parry_every_n_item = hits_before_menu_item("parry_every_prefix", "parry_every_suffix", training_settings, "parry_every_n_count", 0, 10, true, 1)
  parry_every_n_item.indent = true
  parry_every_n_item.is_disabled = function()
    return training_settings.blocking_style ~= 3
  end

  prefer_down_parry_item = checkbox_menu_item("prefer_down_parry", training_settings, "prefer_down_parry")
  prefer_down_parry_item.indent = true
  prefer_down_parry_item.is_disabled = function()
    return not (training_settings.blocking_style == 2 or training_settings.blocking_style == 3)
  end
  counter_attack_item = list_menu_item("counterattack", counter_attack_settings, "ca_type", counter_attack_type, 1, update_counter_attack_special)

  counter_attack_motion_item = motion_list_menu_item("counter_attack_motion", counter_attack_settings, "motion", counter_attack_motion_input, 1, update_counter_attack_button)
  counter_attack_motion_item.indent = true
  counter_attack_motion_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 2
  end

  counter_attack_button_item = list_menu_item("counter_attack_button", counter_attack_settings, "button", counter_attack_button)
  counter_attack_button_item.indent = true
  counter_attack_button_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 2
  end

  counter_attack_special_item = list_menu_item("counter_attack_special", counter_attack_settings, "special", counter_attack_special, 1, update_counter_attack_special)
  counter_attack_special_item.indent = true
  counter_attack_special_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 3
  end

  counter_attack_special_button_item = list_menu_item("counter_attack_button", counter_attack_settings, "special_button", counter_attack_special_button)
  counter_attack_special_button_item.indent = true
  counter_attack_special_button_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 3 or #counter_attack_special_button == 0
  end

  counter_attack_input_display_item = move_input_menu_item("hello", counter_attack_settings)
  counter_attack_input_display_item.inline = true
  counter_attack_input_display_item.is_disabled = function()
    return not (counter_attack_settings.ca_type == 3 or counter_attack_settings.ca_type == 4)
  end

  counter_attack_option_select_item = list_menu_item("counter_attack_option_select", counter_attack_settings, "option_select", counter_attack_option_select)
  counter_attack_option_select_item.indent = true
  counter_attack_option_select_item.is_disabled = function()
    return counter_attack_settings.ca_type ~= 4
  end

  hits_before_counter_attack = hits_before_menu_item("hits_before_ca_prefix", "hits_before_ca_suffix", training_settings, "hits_before_counter_attack_count", 0, 20, true)
  hits_before_counter_attack.indent = true
  hits_before_counter_attack.is_disabled = function()
    return counter_attack_settings.ca_type == 1
  end

  change_characters_item = button_menu_item("character_select", start_character_select_sequence)
  change_characters_item.is_disabled = function()
    -- not implemented for 4rd strike yet
    return rom_name ~= "sfiii3nr1"
  end

  p1_distances_reference_point_item = list_menu_item("p1_distance_reference_point", training_settings, "p1_distances_reference_point", distance_display_reference_point)
  p1_distances_reference_point_item.is_disabled = function()
    return not training_settings.display_distances
  end

  p2_distances_reference_point_item = list_menu_item("p2_distance_reference_point", training_settings, "p2_distances_reference_point", distance_display_reference_point)
  p2_distances_reference_point_item.is_disabled = function()
    return not training_settings.display_distances
  end
  mid_distance_height_item = integer_menu_item("mid_distance_height", training_settings, "mid_distance_height", 0, 200, false, 10)
  mid_distance_height_item.is_disabled = function()
    return not training_settings.display_distances
  end

  air_time_player_coloring_item = checkbox_menu_item("display_air_time_player_coloring", training_settings, "display_air_time_player_coloring")
  air_time_player_coloring_item.indent = true
  air_time_player_coloring_item.is_disabled = function()
  return not training_settings.display_air_time
  end

  attack_range_display_max_item = integer_menu_item("attack_range_max_attacks", training_settings, "attack_range_display_max_attacks", 1, 3, true, 1)
  attack_range_display_max_item.indent = true
  attack_range_display_max_item.is_disabled = function()
    return training_settings.display_attack_range == 1
  end
  attack_bars_show_decimal_item = checkbox_menu_item("show_decimal", training_settings, "attack_bars_show_decimal")
  attack_bars_show_decimal_item.indent = true
  attack_bars_show_decimal_item.is_disabled = function()
  return not (training_settings.display_attack_bars > 1)
  end


  language_item = list_menu_item("language", training_settings, "language", language, 1, update_dimensions)

  play_challenge_item = button_menu_item("play", play_challenge)
  select_char_challenge_item = button_menu_item("Select Character (Current: Gill)", select_character_hadou_matsuri)


  main_menu = make_multitab_menu(
    23, 14, 360, 197, -- screen size 383,223
    {
      {
        header = header_menu_item("dummy"),
        entries = {
          list_menu_item("pose", training_settings, "pose", pose),
          list_menu_item("blocking_style", training_settings, "blocking_style", blocking_style),
          blocking_item,
          hits_before_red_parry_item,
          parry_every_n_item,
          prefer_down_parry_item,
          counter_attack_item,
          counter_attack_motion_item,
          counter_attack_button_item,
          counter_attack_special_item, counter_attack_input_display_item,
          counter_attack_special_button_item,
          counter_attack_option_select_item,
          hits_before_counter_attack,
          list_menu_item("mash_stun", training_settings, "mash_stun_mode", mash_stun_mode, 1),
          list_menu_item("tech_throws", training_settings, "tech_throws_mode", tech_throws_mode),
          list_menu_item("quick_stand", training_settings, "fast_wakeup_mode", quick_stand),
        }
      },
      {
        header = header_menu_item("recording"),
        entries = {
          checkbox_menu_item("auto_crop_first_frames", training_settings, "auto_crop_recording_start"),
          checkbox_menu_item("auto_crop_last_frames", training_settings, "auto_crop_recording_end"),
          list_menu_item("replay_mode", training_settings, "replay_mode", slot_replay_mode),
          integer_menu_item("menu_slot", training_settings, "current_recording_slot", 1, recording_slot_count, true, 1, 10, update_current_recording_slot_frames),
                                frame_number_item(current_recording_slot_frames, true),
          slot_weight_item,
          counter_attack_delay_item,
          counter_attack_random_deviation_item,
          button_menu_item("clear_slot", clear_slot),
          button_menu_item("clear_all_slots", clear_all_slots),
          button_menu_item("save_slot_to_file", open_save_popup),
          button_menu_item("load_slot_from_file", open_load_popup),
        }
      },
      {
        header = header_menu_item("display"),
        entries = {
          checkbox_menu_item("display_controllers", training_settings, "display_input"),
          controller_style_menu_item,
          list_menu_item("display_input_history", training_settings, "display_input_history", display_input_history_mode, 1),
          checkbox_menu_item("display_gauge_numbers", training_settings, "display_gauges", false),
          checkbox_menu_item("display_bonuses", training_settings, "display_bonuses", true),
          checkbox_menu_item("display_attack_info", training_settings, "display_attack_data"),
          list_menu_item("display_attack_bars", training_settings, "display_attack_bars", display_attack_bars_mode, 3),
          attack_bars_show_decimal_item,
          checkbox_menu_item("display_frame_advantage", training_settings, "display_frame_advantage"),
          checkbox_menu_item("display_hitboxes", training_settings, "display_hitboxes"),
          checkbox_menu_item("display_distances", training_settings, "display_distances"),
          mid_distance_height_item,
          p1_distances_reference_point_item,
          p2_distances_reference_point_item,
          checkbox_menu_item("display_air_time", training_settings, "display_air_time"),
          air_time_player_coloring_item,
          checkbox_menu_item("display_charge", training_settings, "display_charge"),
          charge_follow_character_item,
          charge_overcharge_on_item,
          checkbox_menu_item("display_parry", training_settings, "display_parry"),
          checkbox_menu_item("display_red_parry_miss", training_settings, "display_red_parry_miss"),
          list_menu_item("attack_range_display", training_settings, "display_attack_range", player_options_list),
          attack_range_display_max_item,
          language_item
        }
      },
      {
        header = header_menu_item("rules"),
        entries = {
          change_characters_item,
          list_menu_item("force_stage", training_settings, "force_stage", stage_list, 1),
          checkbox_menu_item("infinite_time", training_settings, "infinite_time"),
          list_menu_item("life_refill_mode", training_settings, "life_mode", gauge_refill_mode),
          p1_life_reset_value_gauge_item,
          p2_life_reset_value_gauge_item,
          life_refill_delay_item,
          list_menu_item("stun_mode", training_settings, "stun_mode", gauge_refill_mode),
          p1_stun_reset_value_gauge_item,
          p2_stun_reset_value_gauge_item,
          stun_reset_delay_item,
          list_menu_item("meter_refill_mode", training_settings, "meter_mode", gauge_refill_mode),
          p1_meter_gauge_item,
          p2_meter_gauge_item,
          meter_refill_delay_item,
          checkbox_menu_item("infinite_super_art_time", training_settings, "infinite_sa_time"),
          integer_menu_item("music_volume", training_settings, "music_volume", 0, 10, false, 10),
          checkbox_menu_item("speed_up_game_intro", training_settings, "fast_forward_intro"),
          list_menu_item("cheat_parrying", training_settings, "cheat_parrying", player_options_list),
          checkbox_menu_item("universal_cancel", training_settings, "universal_cancel"),
          checkbox_menu_item("infinite_projectiles", training_settings, "infinite_projectiles"),
          checkbox_menu_item("infinite_juggle", training_settings, "infinite_juggle")
        }
      },
      {
        header = header_menu_item("training"),
        entries = {
          list_menu_item("mode", training_settings, "special_training_current_mode", special_training_mode),
          checkbox_menu_item("follow_character", training_settings, "charge_follow_character"),
          parry_forward_on_item,
          parry_down_on_item,
          parry_air_on_item,
          parry_antiair_on_item,
          charge_overcharge_on_item
        }
      },
        {
          header = header_menu_item("challenge"),
          entries = {
            list_menu_item("challenge", training_settings, "challenge_current_mode", challenge_mode),
                                play_challenge_item,
                                select_char_challenge_item
          }
        }
    },
    function ()
      save_training_data()
    end
  )

  debug_move_menu_item = map_menu_item("debug_move", debug_settings, "debug_move", frame_data, nil)
  if developer_mode then
    local _debug_settings_menu = {
      header = header_menu_item("debug"),
      entries = {
        checkbox_menu_item("show_predicted_hitboxes", debug_settings, "show_predicted_hitbox"),
        checkbox_menu_item("record_frame_data", debug_settings, "record_framedata"),
        checkbox_menu_item("record_idle_frame_data", debug_settings, "record_idle_framedata"),
        checkbox_menu_item("record_wake-Up_data", debug_settings, "record_wakeupdata"),
        button_menu_item("save_frame_data", save_frame_data),
        map_menu_item("debug_character", debug_settings, "debug_character", _G, "frame_data"),
        debug_move_menu_item
      },
      topmost_entry = 1
    }
    table.insert(main_menu.content, _debug_settings_menu)
  end

  menu_loaded = true
end
-- RECORDING
swap_characters = false
-- 1: Default Mode, 2: Wait for recording, 3: Recording, 4: Replaying
current_recording_state = 1
last_ordered_recording_slot = 0
current_recording_last_idle_frame = -1
last_coin_input_frame = -1
override_replay_slot = -1
recording_states =
{
  "none",
  "waiting",
  "recording",
  "playing",
}

function stick_input_to_sequence_input(_player_obj, _input)
  if _input == "Up" then return "up" end
  if _input == "Down" then return "down" end
  if _input == "Weak Punch" then return "LP" end
  if _input == "Medium Punch" then return "MP" end
  if _input == "Strong Punch" then return "HP" end
  if _input == "Weak Kick" then return "LK" end
  if _input == "Medium Kick" then return "MK" end
  if _input == "Strong Kick" then return "HK" end

  if _input == "Left" then
    if _player_obj.flip_input then
      return "back"
    else
      return "forward"
    end
  end

  if _input == "Right" then
    if _player_obj.flip_input then
      return "forward"
    else
      return "back"
    end
  end
  return ""
end

function can_play_recording()
  if training_settings.replay_mode == 2 or training_settings.replay_mode == 3 or training_settings.replay_mode == 5 or training_settings.replay_mode == 6 then
    for _i, _value in ipairs(recording_slots) do
      if #_value.inputs > 0 then
        return true
      end
    end
  else
    return recording_slots[training_settings.current_recording_slot].inputs ~= nil and #recording_slots[training_settings.current_recording_slot].inputs > 0
  end
  return false
end

function find_random_recording_slot()
  -- random slot selection
  local _recorded_slots = {}
  for _i, _value in ipairs(recording_slots) do
    if _value.inputs and #_value.inputs > 0 then
      table.insert(_recorded_slots, _i)
    end
  end

  if #_recorded_slots > 0 then
    local _total_weight = 0
    for _i, _value in pairs(_recorded_slots) do
      _total_weight = _total_weight + recording_slots[_value].weight
    end

    local _random_slot_weight = 0
    if _total_weight > 0 then
      _random_slot_weight = math.ceil(math.random(_total_weight))
    end
    local _random_slot = 1
    local _weight_i = 0
    for _i, _value in ipairs(_recorded_slots) do
      if _weight_i <= _random_slot_weight and _weight_i + recording_slots[_value].weight >= _random_slot_weight then
        _random_slot = _i
        break
      end
      _weight_i = _weight_i + recording_slots[_value].weight
    end
    return _recorded_slots[_random_slot]
  end
  return -1
end

function go_to_next_ordered_slot()
  local _slot = -1
  for _i = 1, recording_slot_count do
    local _slot_index = ((last_ordered_recording_slot - 1 + _i) % recording_slot_count) + 1
    --print(_slot_index)
    if recording_slots[_slot_index].inputs ~= nil and #recording_slots[_slot_index].inputs > 0 then
      _slot = _slot_index
      last_ordered_recording_slot = _slot
      break
    end
  end
  return _slot
end

function set_recording_state(_input, _state)
  if (_state == current_recording_state) then
    return
  end

  -- exit states
  if current_recording_state == 1 then
  elseif current_recording_state == 2 then
    swap_characters = false
  elseif current_recording_state == 3 then
    local _first_input = 1
    local _last_input = 1
    for _i, _value in ipairs(recording_slots[training_settings.current_recording_slot].inputs) do
      if #_value > 0 then
        _last_input = _i
      elseif _first_input == _i then
        _first_input = _first_input + 1
      end
    end

    _last_input = math.max(current_recording_last_idle_frame, _last_input)

    if not training_settings.auto_crop_recording_start then
      _first_input = 1
    end

    if not training_settings.auto_crop_recording_end or _last_input ~= current_recording_last_idle_frame then
      _last_input = #recording_slots[training_settings.current_recording_slot].inputs
    end

    local _cropped_sequence = {}
    for _i = _first_input, _last_input do
      table.insert(_cropped_sequence, recording_slots[training_settings.current_recording_slot].inputs[_i])
    end
    recording_slots[training_settings.current_recording_slot].inputs = _cropped_sequence

    save_training_data()

    swap_characters = false
  elseif current_recording_state == 4 then
    clear_input_sequence(dummy)
  end

  current_recording_state = _state

  -- enter states
  if current_recording_state == 1 then
  elseif current_recording_state == 2 then
    swap_characters = true
    make_input_empty(_input)
  elseif current_recording_state == 3 then
    current_recording_last_idle_frame = -1
    swap_characters = true
    make_input_empty(_input)
    recording_slots[training_settings.current_recording_slot].inputs = {}
  elseif current_recording_state == 4 then
    local _replay_slot = -1
    if override_replay_slot > 0 then
      _replay_slot = override_replay_slot
    else
      if training_settings.replay_mode == 2 or training_settings.replay_mode == 5 then
        _replay_slot = find_random_recording_slot()
      elseif training_settings.replay_mode == 3 or training_settings.replay_mode == 6 then
        _replay_slot = go_to_next_ordered_slot()
      else
        _replay_slot = training_settings.current_recording_slot
      end
    end

    if _replay_slot > 0 then
      queue_input_sequence(dummy, recording_slots[_replay_slot].inputs)
    end
  end
end

function update_recording(_input)

  local _input_buffer_length = 11
  if is_in_match and not is_menu_open then

    -- manage input
    local _input_pressed = (not swap_characters and player.input.pressed.coin) or (swap_characters and dummy.input.pressed.coin)
    if _input_pressed then
      if frame_number < (last_coin_input_frame + _input_buffer_length) then
        last_coin_input_frame = -1

        -- double tap
        if current_recording_state == 2 or current_recording_state == 3 then
          set_recording_state(_input, 1)
        else
          set_recording_state(_input, 2)
        end

      else
        last_coin_input_frame = frame_number
      end
    end

    if last_coin_input_frame > 0 and frame_number >= last_coin_input_frame + _input_buffer_length then
      last_coin_input_frame = -1

      -- single tap
      if current_recording_state == 1 then
        if can_play_recording() then
          set_recording_state(_input, 4)
        end
      elseif current_recording_state == 2 then
        set_recording_state(_input, 3)
      elseif current_recording_state == 3 then
        set_recording_state(_input, 1)
      elseif current_recording_state == 4 then
        set_recording_state(_input, 1)
      end

    end

    -- tick states
    if current_recording_state == 1 then
    elseif current_recording_state == 2 then
    elseif current_recording_state == 3 then
      local _frame = {}

      for _key, _value in pairs(_input) do
        local _prefix = _key:sub(1, #player.prefix)
        if (_prefix == player.prefix) then
          local _input_name = _key:sub(1 + #player.prefix + 1)
          if (_input_name ~= "Coin" and _input_name ~= "Start") then
            if (_value) then
              local _sequence_input_name = stick_input_to_sequence_input(player, _input_name)
              --print(_input_name.." ".._sequence_input_name)
              table.insert(_frame, _sequence_input_name)
            end
          end
        end
      end

      table.insert(recording_slots[training_settings.current_recording_slot].inputs, _frame)

      if player.idle_time == 1 then
        current_recording_last_idle_frame = #recording_slots[training_settings.current_recording_slot].inputs - 1
      end

    elseif current_recording_state == 4 then
      if dummy.pending_input_sequence == nil then
        set_recording_state(_input, 1)
        if can_play_recording() and (training_settings.replay_mode == 4 or training_settings.replay_mode == 5 or training_settings.replay_mode == 6) then
          set_recording_state(_input, 4)
        end
      end
    end
  end

  previous_recording_state = current_recording_state
end

-- PROGRAM

P1.debug_state_variables = false
P1.debug_freeze_frames = false
P1.debug_animation_frames = false
P1.debug_standing_state = false
P1.debug_wake_up = false

P2.debug_state_variables = false
P2.debug_freeze_frames = false
P2.debug_animation_frames = false
P2.debug_standing_state = false
P2.debug_wake_up = false

function write_player_vars(_player_obj)

  -- P1: 0x02068C6C
  -- P2: 0x02069104

  local _wanted_meter = 0
  if _player_obj.id == 1 then
    _wanted_meter = training_settings.p1_meter
  elseif _player_obj.id == 2 then
    _wanted_meter = training_settings.p2_meter
  end

  -- LIFE
  if is_in_match and not is_menu_open then
    local _life = memory.readbyte(_player_obj.life_addr)
    if training_settings.life_mode == 2 then
      if _player_obj.is_idle and _player_obj.idle_time > training_settings.life_refill_delay then
        local _refill_rate = 6
        _life = math.min(_life + _refill_rate, 160)
      end
    elseif training_settings.life_mode == 3 then
      _life = 160
    end
    memory.writebyte(_player_obj.life_addr, _life)
    _player_obj.life = _life
  end

  -- METER
  if is_in_match and not is_menu_open and not _player_obj.is_in_timed_sa then
    -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max. We have to make special cases for it
    local _is_timed_sa = character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa]

    if training_settings.meter_mode == 3 then
      local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
      local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])
      if _previous_meter_count ~= _player_obj.max_meter_count and _previous_meter_count_slave ~= _player_obj.max_meter_count then
        local _gauge_value = 0
        if _is_timed_sa then
          _gauge_value = _player_obj.max_meter_gauge
        end
        memory.writebyte(_player_obj.gauge_addr, _gauge_value)
        memory.writebyte(_player_obj.meter_addr[2], _player_obj.max_meter_count)
        memory.writebyte(_player_obj.meter_update_flag, 0x01)
      end
    elseif training_settings.meter_mode == 2 then
      if _player_obj.is_idle and _player_obj.idle_time > training_settings.meter_refill_delay then
        local _previous_gauge = memory.readbyte(_player_obj.gauge_addr)
        local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
        local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])

        if _previous_meter_count == _previous_meter_count_slave then
          local _meter = 0
          -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max
          if _is_timed_sa then
            _meter = _previous_gauge
          else
             _meter = _previous_gauge + _player_obj.max_meter_gauge * _previous_meter_count
          end

          if _meter > _wanted_meter then
            _meter = _meter - 6
            _meter = math.max(_meter, _wanted_meter)
          elseif _meter < _wanted_meter then
            _meter = _meter + 6
            _meter = math.min(_meter, _wanted_meter)
          end

          local _wanted_gauge = _meter % _player_obj.max_meter_gauge
          local _wanted_meter_count = math.floor(_meter / _player_obj.max_meter_gauge)
          local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
          local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])

          if character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa] and _wanted_meter_count == 1 and _wanted_gauge == 0 then
            _wanted_gauge = _player_obj.max_meter_gauge
          end

          --if _player_obj.id == 1 then
          --  print(string.format("%d: %d/%d/%d (%d/%d)", _wanted_meter, _wanted_gauge, _wanted_meter_count, _player_obj.max_meter_gauge, _previous_gauge, _previous_meter_count))
          --end

          if _wanted_gauge ~= _previous_gauge then
            memory.writebyte(_player_obj.gauge_addr, _wanted_gauge)
          end
          if _previous_meter_count ~= _wanted_meter_count then
            memory.writebyte(_player_obj.meter_addr[2], _wanted_meter_count)
            memory.writebyte(_player_obj.meter_update_flag, 0x01)
          end
        end
      end
    end
  end

  if training_settings.infinite_sa_time and _player_obj.is_in_timed_sa then
    memory.writebyte(_player_obj.gauge_addr, _player_obj.max_meter_gauge)
  end

  -- STUN
  if training_settings.stun_mode == 2 then
    memory.writebyte(_player_obj.stun_timer_addr, 0)
    memory.writebyte(_player_obj.stun_bar_char_addr, 0)
    memory.writebyte(_player_obj.stun_bar_mantissa_addr, 0)
  elseif training_settings.stun_mode == 3 then
    if is_in_match and not is_menu_open and _player_obj.is_idle then
      local _wanted_stun = 0
      if _player_obj.id == 1 then
        _wanted_stun = training_settings.p1_stun_reset_value
      else
        _wanted_stun = training_settings.p2_stun_reset_value
      end
      _wanted_stun = math.max(_wanted_stun, 0)

      if _player_obj.stun_bar < _wanted_stun then
        memory.writebyte(_player_obj.stun_bar_char_addr, _wanted_stun)
        memory.writebyte(_player_obj.stun_bar_mantissa_addr, 0)
        memory.writebyte(_player_obj.stun_bar_decrease_timer_addr, 0)
      elseif _player_obj.is_idle and _player_obj.idle_time > training_settings.stun_reset_delay then
        local _stun = _player_obj.stun_bar
        _stun = math.max(_stun - 1, _wanted_stun)
        memory.writebyte(_player_obj.stun_bar_char_addr, _stun)
        memory.writebyte(_player_obj.stun_bar_mantissa_addr, 0)
        memory.writebyte(_player_obj.stun_bar_decrease_timer_addr, 0)
      end
    end
  end

  --cheats
  if training_settings.universal_cancel then
    memory.writebyte(0x02068E8D, 0x6F) --p1
    memory.writebyte(0x02069325, 0x6F) --p2
  end
  if training_settings.infinite_projectiles then
    memory.writebyte(0x02068FB8, 0xFF) --p1
    memory.writebyte(0x02069450, 0xFF) --p2
  end
  if training_settings.infinite_juggle then
    memory.writebyte(0x2069031, 0x0) --p1
    memory.writebyte(0x206902E, 0x0)
    memory.writebyte(0x20694C9, 0x0) --p2
    memory.writebyte(0x20694C6, 0x0)
  end
end

after_load_state_callback = {}
function on_load_state()

  reset_player_objects()
  attack_data_reset()
  frame_advantage_reset()

  gamestate_read()

  restore_recordings()


  -- reset recording states in a useful way
  if current_recording_state == 3 then
    set_recording_state({}, 2)
  elseif current_recording_state == 4 and (training_settings.replay_mode == 4 or training_settings.replay_mode == 5 or training_settings.replay_mode == 6) then
    set_recording_state({}, 1)
    set_recording_state({}, 4)
  end

  clear_input_history()
  clear_printed_geometry()
  emu.speedmode("normal")

  --debug

  for _k, _com in ipairs(after_load_state_callback) do
    queue_command(frame_number+1, {command = _com.command, args = _com.args})
    after_load_state_callback[_k] = nil
  end
end


function estimate_chunks_per_frame(_elapsed, _chunks_loaded)
  local rate = _elapsed / _chunks_loaded
--   print(_elapsed, _chunks_loaded, (1 / 60) / rate)
  return math.max(math.floor(frame_time * frame_time_margin / rate), 1)
end

text_images_loaded = false
n_im_loaded_this_frame = 0
n_im_chunks_per_frame = 20
loading_perf_timer = perf_timer:new()
function load_text_images_async()
  for _code, _value in pairs(im_json_data) do
    load_text_image(im_json_data, _code)
    n_im_loaded_this_frame = n_im_loaded_this_frame + 1
    if n_im_loaded_this_frame >= n_im_chunks_per_frame then
      coroutine.yield(n_im_loaded_this_frame)
      n_im_loaded_this_frame = 0
    end
  end
  coroutine.yield(n_im_loaded_this_frame)
  im_json_data = nil
end

frame_data_loaded = false
frame_data_file_list = read_object_from_json_file(framedata_path .. "file_names.json") --char_str: file.json
n_files_loaded = 0
n_files_total = #frame_data_file_list
n_fd_loaded_this_frame = 0
n_fd_chunks_per_frame = 1
frame_time = 1 / 60
frame_time_margin = 0.90

local p = perf_timer:new()
function load_frame_data_async()
  for _key, _char in ipairs(frame_data_keys) do
    p:reset()
    local _file_path = framedata_path.."@".._char..frame_data_file_ext
    frame_data[_char] = read_object_from_json_file(_file_path) or {}
--     for _id, _data in pairs(frame_data[_char]) do
--       if _data.frames then
--         for _i, _frame in ipairs(_data.frames) do
--           if _frame.hash then
--             _frame.index = _i - 1
--             frame_data[_char][_id].frames[_frame.hash] = _frame
--           end
--         end
--       end
--     end
    n_fd_loaded_this_frame = n_fd_loaded_this_frame + 1
    print(frame_number, _char, p:elapsed(), n_fd_chunks_per_frame)
    if n_fd_loaded_this_frame >= n_fd_chunks_per_frame then
      coroutine.yield(n_fd_loaded_this_frame)
      n_fd_loaded_this_frame = 0
    end
  end
end



load_frame_data_bar_fade_time = 40
load_frame_data_bar_fade_start = 0
load_frame_data_bar_elapsed = 0
load_frame_data_bar_fading = false
loading_bar_loaded = 0
loading_bar_total = n_im_json_data + n_files_total * 40
function loading_bar_display(_loaded, _total)
  if load_frame_data_bar_fading then
    load_frame_data_bar_elapsed = frame_number - load_frame_data_bar_fade_start
    if load_frame_data_bar_fading and load_frame_data_bar_elapsed > load_frame_data_bar_fade_time then
      return
    end
  end

  local _width = 60
  local _height = 1
  local _padding = 1
  local _x = screen_width - _width - _padding
  local _y = screen_height - _height - _padding
  local _fill_color = 0xFFFFFFDD
  local _opacity = 0xDD
  if load_frame_data_bar_fading then
    _opacity = 0xDD * (1 - load_frame_data_bar_elapsed / load_frame_data_bar_fade_time)
    _fill_color = tonumber(string.format("0xFFFFFF%02x", _opacity))
  end
  draw_gauge(_x, _y, _width, _height, _loaded / _total, _fill_color, 0x00000000, 0x00000000, false)
  if _loaded >= _total and not load_frame_data_bar_fading then
    load_frame_data_bar_fade_start = frame_number
    load_frame_data_bar_fading = true
  end
end

player = P1
dummy = P2

function on_start()
  load_training_data()

  load_frame_data_co = coroutine.create(load_frame_data_async)
  load_text_images_co = coroutine.create(load_text_images_async)

  emu.speedmode("normal")

  --debug
--   play_challenge()
  --if not developer_mode then
    start_character_select_sequence()
  --end
  print("load time:", timer:elapsed())
end

function hotkey1()
  is_in_challenge = false
  set_recording_state({}, 1)
  start_character_select_sequence()
end

function hotkey2()
  if character_select_sequence_state ~= 0 then
    select_gill()
  end
end

function hotkey3()
  if character_select_sequence_state ~= 0 then
    select_shingouki()
  end
end

function runinput()
  local _path = string.format("%s%s",saved_recordings_path, "Debug.json")
  local _recording = read_object_from_json_file(_path)
  if not _recording then
    print(string.format("Error: Failed to load recording from \"%s\"", _path))
  else
    recording_slots[training_settings.current_recording_slot].inputs = _recording
    print(string.format("Loaded \"%s\" to slot %d", _path, training_settings.current_recording_slot))
  end
  queue_input_sequence(P1, recording_slots[1].inputs)

end

function hotkey4() --debug
--    debug_challenge()
   runinput()
end

  local naa = 0
function hotkey5() --debug
--   memory.writebyte(P1.base + 0x9F, 0x0)
--   memory.writebyte(P1.base + 0x27, 0x0)
--    memory.writeword(P1.base + 0x202, 0x8800) --idle
--    memory.writeword(P1.base + 0x21A, 22177)
--        memory.writeword(P1.base + 0x214, 2) --frameid2
--        memory.writeword(P1.base + 0x205, 106) --frameid3
-- --       memory.writeword(P1.base + 0x202, 0x7754) --sa1
-- --       memory.writeword(P1.base + 0x21A, 22320)
-- --    memory.writeword(P1.base + 0x202, 0x8210) --sa1
-- --    memory.writeword(P1.base + 0x21A, 22268)
-- --     memory.writeword(P1.base + 0x214, 0x04) --frameid2
-- --     memory.writeword(P1.base + 0x205, 0x04) --frameid3
-- --   memory.writeword(P1.base + 0x202, 0x8800)
-- --   memory.writeword(P1.base + 0x21A, 21506)
--
--   memory.writeword(P1.base + 0x3D1, 0x0)
--   memory.writeword(P1.base + 0xAC, 0)
--    memory.writeword(P1.base + 0x12C, 0)
--
--
--
--   print(bit.tohex(memory.readword(P1.base + 0x202), 4), memory.readword(P1.base + 0x21A))
--   local _frame_id2 = memory.readbyte(P1.base + 0x214)
--   local _frame_id3 = memory.readbyte(P1.base + 0x205) --debug 0 default
--   print(_frame_id2, _frame_id3)
-- queue_input_sequence(player, {{"up"}})
-- command_queue[frame_number+5] = {command = thething}
-- memory.writeword(player.base + 0x3C0, 14)

-- memory.writebyte(P1.base + 0xAD, 131090)
-- memory.writeword(P1.base + 0x202, 0xddd4)

--[[   for _id, _obj in pairs(projectiles) do
    if _obj.emitter_id == 1 then
    memory.writeword(_obj.base + 616, 0x4200)

    queue_command(frame_number + 1, {command = function(n) memory.writeword(_obj.base + 616, n) end, args={0x421d}})
  --   memory.writedword(_obj.base + 612, 0x4ea02034)
    P1_Current_search_adr = _obj.base + 616
    clear_motion_data(_obj)
    end
  end ]]

  write_pos(P1, 500 - naa, 120)
  write_pos(P2, 500, 0)
  write_velocity_y(P1, -1)
  naa = naa + 1
end



function thething()
  write_pos(player, 400, 100)
  memory.writeword(player.base + 0x64 + 28, 0)
  memory.writebyte(player.base + 0x64 + 30, 0x98)

  memory.writeword(player.base + 0x64 + 36, 0)
  memory.writebyte(player.base + 0x64 + 38, 0)
end

function initial_d()
    maddresses = {}
    for i=0,80000000 do
        local _val = memory.readbyte(i)
        if _val > 0  then
            maddresses[i] = _val
-- maddresses[i] = {_val,_val}
        end
    end
    print("init done")
end

function filterrr(n)
  filtered_addr = {}
  for _k, _v in pairs(maddresses) do
    local _val = memory.readbyte(_k)
--     if bit.band(_v + n, 0xFF) == _val or bit.band(_v + n, 0xFF) == (_val - 0x1)  or bit.band(_v + n, 0xFF) == (_val + 0x1) then
    if _val == n then
        filtered_addr[_k] = _val
    end
  end
  maddresses = deepcopy(filtered_addr)
  print("filtered")
end



q = 0
ori = {}
function hotkey6() --debug

if maddresses then
  if q == 0 then
    for _k, _v in pairs(maddresses) do
      maddresses[_k] = memory.readbyte(_k)
      ori[_k] = maddresses[_k]
    end
    q = q + 1
    print("reinit")
  else
    filterrr(15)
  end
else
  initial_d()
end

end

function hotkey7()
--[[   init_scan_memory()
  print("initial scan") ]]
  start_debug = true
end


function enable_cheat_parrying(_player_obj)
  memory.writebyte(_player_obj.parry_forward_validity_time_addr, 0xA)
  memory.writebyte(_player_obj.parry_down_validity_time_addr, 0xA)
  memory.writebyte(_player_obj.parry_air_validity_time_addr, 0x7)
  memory.writebyte(_player_obj.parry_antiair_validity_time_addr, 0x5)
end

function disable_cheat_parrying(_player_obj)
  memory.writebyte(_player_obj.parry_forward_validity_time_addr, 0x0)
  memory.writebyte(_player_obj.parry_down_validity_time_addr, 0x0)
  memory.writebyte(_player_obj.parry_air_validity_time_addr, 0x0)
  memory.writebyte(_player_obj.parry_antiair_validity_time_addr, 0x0)
end

input.registerhotkey(1, hotkey1)
if rom_name == "sfiii3nr1" then
  input.registerhotkey(2, hotkey2)
  input.registerhotkey(3, hotkey3)
  input.registerhotkey(4, hotkey4)
  input.registerhotkey(5, hotkey5)
  input.registerhotkey(6, hotkey6)
  input.registerhotkey(7, hotkey7)
end

function queue_command(_frame, _command)
  if not command_queue[_frame] then
    command_queue[_frame] = {}
  end
  table.insert(command_queue[_frame], _command)
end

hhh = {}

        print(collectgarbage("count"))

function before_frame()
  run_debug()

  if not text_images_loaded or not frame_data_loaded then
    if not text_images_loaded then
      current_co = load_text_images_co
    else
      current_co = load_frame_data_co
    end
    loading_perf_timer:reset()
    local _status = coroutine.status(current_co)
    if _status == "suspended" then
      local _pass, _n = coroutine.resume(current_co)
      if _n then
        if current_co == load_frame_data_co then
          _n = _n * 40
        end
        loading_bar_loaded = loading_bar_loaded + _n
      end
    elseif _status == "dead" then
      if current_co == load_text_images_co then
        text_images_loaded = true
        print("t",collectgarbage("count"))
        init_menu()
      else
        frame_data_loaded = true
        print("f",collectgarbage("count"))
      end
    end
    if current_co == load_text_images_co then
      local el = loading_perf_timer:elapsed()
      n_im_chunks_per_frame = estimate_chunks_per_frame(el, n_im_chunks_per_frame)
      table.insert(hhh,n_im_chunks_per_frame)
      table.insert(hhh,el)
    else

      n_fd_chunks_per_frame = estimate_chunks_per_frame(loading_perf_timer:elapsed(), n_fd_chunks_per_frame)
    end
  end

  draw_read()

  -- gamestate
  local _previous_p2_char_str = P2.char_str or ""
  local _previous_dummy_char_str = dummy.char_str or ""
  gamestate_read()

  for _k,_commands in pairs(command_queue) do
    if _k == frame_number then
      for _,_com in pairs(_commands) do
        if _com.args then
          _com.command(unpack(_com.args))
        else
          _com.command()
        end
        command_queue[_k] = nil
      end
    end
  end

  -- update debug menu
  if menu_loaded then
    if debug_settings.debug_character ~= debug_move_menu_item.map_property then
      debug_move_menu_item.map_object = frame_data
      debug_move_menu_item.map_property = debug_settings.debug_character
      debug_settings.debug_move = ""
    end

    slot_weight_item.object = recording_slots[training_settings.current_recording_slot]
    counter_attack_delay_item.object = recording_slots[training_settings.current_recording_slot]
    counter_attack_random_deviation_item.object = recording_slots[training_settings.current_recording_slot]


  -- load recordings according to P2 character
  if _previous_p2_char_str ~= P2.char_str then
    restore_recordings()
  end
  --update character specific settings on dummy change
  if _previous_dummy_char_str ~= dummy.char_str then
    update_counter_attack_settings()
  end

  if has_match_just_started then
    attack_range_display_reset()
    red_parry_miss_display_reset()
    update_counter_attack_settings()
    update_counter_attack_button()
    update_counter_attack_special()
  end

  -- cap training settings
  if is_in_match then
    training_settings.p1_meter = math.min(training_settings.p1_meter, P1.max_meter_count * P1.max_meter_gauge)
    training_settings.p2_meter = math.min(training_settings.p2_meter, P2.max_meter_count * P2.max_meter_gauge)
    p1_meter_gauge_item.gauge_max = P1.max_meter_gauge * P1.max_meter_count
    p1_meter_gauge_item.subdivision_count = P1.max_meter_count
    p2_meter_gauge_item.gauge_max = P2.max_meter_gauge * P2.max_meter_count
    p2_meter_gauge_item.subdivision_count = P2.max_meter_count
    training_settings.p1_stun_reset_value = math.min(training_settings.p1_stun_reset_value, P1.stun_max)
    training_settings.p2_stun_reset_value = math.min(training_settings.p2_stun_reset_value, P2.stun_max)
    p1_stun_reset_value_gauge_item.gauge_max = P1.stun_max
    p2_stun_reset_value_gauge_item.gauge_max = P2.stun_max

    P1.blocking.cheat_parrying = false
    P2.blocking.cheat_parrying = false
    if training_settings.cheat_parrying == 2 or training_settings.cheat_parrying == 4 then
      P1.blocking.cheat_parrying = true
    end
    if training_settings.cheat_parrying == 3 or training_settings.cheat_parrying == 4 then
      P2.blocking.cheat_parrying = true
    end
    for i = 1, #player_objects do
      if player_objects[i].blocking.cheat_parrying then
        enable_cheat_parrying(player_objects[i])
      end
    end

  end


  local _write_game_vars_settings =
  {
    freeze = is_menu_open,
    infinite_time = training_settings.infinite_time,
    music_volume = training_settings.music_volume,
  }
  write_game_vars(_write_game_vars_settings)

  if not is_in_challenge then
    write_player_vars(P1)
    write_player_vars(P2)
  end

  -- input
  local _input = joypad.get()
  if is_in_match and not is_menu_open and swap_characters then
    swap_inputs(_input)
  end

  update_character_select(_input, training_settings.fast_forward_intro)

  if not is_in_match then
    if P1.input.pressed.start then
      start_select_random_character()
    elseif P1.input.released.start then
      stop_select_random_character()
    end
    if P1.input.down.start then
      select_random_character()
    end
  end

  if not swap_characters then
    player = P1
    dummy = P2
  else
    player = P2
    dummy = P1
  end

  --challenge
  if is_in_challenge then
    if training_settings.challenge_current_mode == 1 then
      hadou_matsuri_run()
      if is_in_match then
        _input = hm_input --for input display
      end
    end
  end

  if frame_data_loaded and is_in_match and not debug_settings.record_framedata then
    -- attack data
    attack_data_update(player, dummy)

    -- frame advantage
    frame_advantage_update(player, dummy)

    -- blocking
    update_blocking(_input, player, dummy, training_settings.blocking_mode, training_settings.blocking_style, training_settings.red_parry_hit_count, training_settings.parry_every_n_count)

    update_blocking_direction(_input, player, dummy)

    -- pose
    update_pose(_input, player, dummy, training_settings.pose)

    -- mash stun
    update_mash_stun(_input, player, dummy, training_settings.mash_stun_mode)

    -- fast wake-up
    update_fast_wake_up(_input, player, dummy, training_settings.fast_wakeup_mode)

    -- tech throws
    update_tech_throws(_input, player, dummy, training_settings.tech_throws_mode)

    -- counter attack
    update_counter_attack(_input, player, dummy, counter_attack_settings, training_settings.hits_before_counter_attack_count)

    -- recording
    update_recording(_input)
  end

  process_pending_input_sequence(P1, _input)
  process_pending_input_sequence(P2, _input)

  if is_in_match then
    input_history_update(input_history[1], "P1", _input)
    input_history_update(input_history[2], "P2", _input)
  else
    clear_input_history()
    frame_advantage_reset()
  end

  -- Log input
  if previous_input then
    function log_input(_player_object, _name, _short_name)
      _short_name = _short_name or _name
      local _full_name = _player_object.prefix.." ".._name
      if not previous_input[_full_name] and _input[_full_name] then
        log(_player_object.prefix, "input", _short_name.." 1")
      elseif previous_input[_full_name] and not _input[_full_name] then
        log(_player_object.prefix, "input", _short_name.." 0")
      end
    end

    for _i, _o in ipairs(player_objects) do
      log_input(_o, "Left")
      log_input(_o, "Right")
      log_input(_o, "Up")
      log_input(_o, "Down")
      log_input(_o, "Weak Punch", "LP")
      log_input(_o, "Medium Punch", "MP")
      log_input(_o, "Strong Punch", "HP")
      log_input(_o, "Weak Kick", "LK")
      log_input(_o, "Medium Kick", "MK")
      log_input(_o, "Strong Kick", "HK")
    end
  end
  previous_input = _input


  if not (is_in_match and is_in_challenge) then
    joypad.set(_input)
  end


  record_frames_hotkey()

  update_framedata_recording(P1, projectiles)

  debugframedatagui(P1, projectiles)

  log_update()
  end
end




is_menu_open = false

function on_gui()

  draw_character_select()

  loading_bar_display(loading_bar_loaded, loading_bar_total)

  if text_images_loaded then

    if P1.input.pressed.start then
      clear_printed_geometry()
    end

    if is_in_match and not disable_display then

      --[[
      -- Code to test frame advantage correctness by measuring the frame count between both players jump
      if (P1.last_jump_startup_frame ~= nil and P2.last_jump_startup_frame ~= nil) then
        gui.text(5, 5, string.format("jump difference: %d (startups: %d/%d)", P2.last_jump_startup_frame - P1.last_jump_startup_frame, P1.last_jump_startup_duration, P2.last_jump_startup_duration), text_default_color, text_default_border_color)
      end
      ]]

      display_draw_printed_geometry()

      -- distances
      if training_settings.display_distances then
        display_draw_distances(P1, P2, training_settings.mid_distance_height, training_settings.p1_distances_reference_point, training_settings.p2_distances_reference_point)
      end

      -- input history
      if training_settings.display_input_history == 5 then --moving
        if P1.pos_x < 320 then
          input_history_draw(input_history[1], screen_width - 4, 49, true, controller_styles[training_settings.controller_style])
        else
          input_history_draw(input_history[1], 4, 49, false, controller_styles[training_settings.controller_style])
        end
      else
        if training_settings.display_input_history == 2 or training_settings.display_input_history == 4 then
          input_history_draw(input_history[1], 4, 49, false, controller_styles[training_settings.controller_style])
        end
        if training_settings.display_input_history == 3 or training_settings.display_input_history == 4 then
          input_history_draw(input_history[2], screen_width - 4, 49, true, controller_styles[training_settings.controller_style])
        end
      end

      -- controllers
      if training_settings.display_input then
        local _i = joypad.get()
        local _p1 = make_input_history_entry("P1", _i)
        local _p2 = make_input_history_entry("P2", _i)
        draw_controller_big(_p1, 44, 34, controller_styles[training_settings.controller_style])
        draw_controller_big(_p2, 310, 34, controller_styles[training_settings.controller_style])
      end


      draw_hud(player, dummy)



      if training_settings.display_gauges then
        display_draw_life(P1)
        display_draw_life(P2)

        display_draw_meter(P1)
        display_draw_meter(P2)

        display_draw_stun_gauge(P1)
        display_draw_stun_gauge(P2)
      end
      if training_settings.display_bonuses then
        display_draw_bonuses(P1)
        display_draw_bonuses(P2)
      end

  
      for i=1,#to_draw_collision do
        local _x1, _y1 = game_to_screen_space(to_draw_collision[i][1], to_draw_collision[i][3])
        local _x2, _y2 = game_to_screen_space(to_draw_collision[i][2], to_draw_collision[i][4])
        gui.drawline(_x1,_y1,_x2,_y2,0x000000FF)
      end



      -- attack data
      -- do not show if special training not following character is on, otherwise it will overlap
      if training_settings.display_attack_data and (training_settings.special_training_current_mode == 1 or training_settings.charge_follow_character) then
        attack_data_display()
      end

      -- move advantage
      if training_settings.display_frame_advantage then
        frame_advantage_display()
      end

      -- debug
      --  predicted hitboxes
      if debug_settings.show_predicted_hitbox then
        local _predicted_hit = predict_hitboxes(player, 2)
        if _predicted_hit.frame_data then
          draw_hitboxes(_predicted_hit.pos_x, _predicted_hit.pos_y, player.flip_x, _predicted_hit.frame_data.boxes, nil, nil, "#691B98")
        end
      end

      --  move hitboxes
      local _debug_frame_data = frame_data[debug_settings.debug_character]
      if _debug_frame_data then
        local _debug_move = _debug_frame_data[debug_settings.debug_move]
        if _debug_move and _debug_move.frames then
          local _move_frame = frame_number % #_debug_move.frames

          local _debug_pos_x = player.pos_x
          local _debug_pos_y = player.pos_y
          local _debug_flip_x = player.flip_x

          local _sign = 1
          if _debug_flip_x ~= 0 then _sign = -1 end
          for i = 1, _move_frame + 1 do
            _debug_pos_x = _debug_pos_x + _debug_move.frames[i].movement[1] * _sign
            _debug_pos_y = _debug_pos_y + _debug_move.frames[i].movement[2]
          end

          draw_hitboxes(_debug_pos_x, _debug_pos_y, _debug_flip_x, _debug_move.frames[_move_frame + 1].boxes)
        end
      end
    end

    if is_in_match and not disable_display and current_recording_state ~= 1 then

      local _current_recording_size = 0
      if (recording_slots[training_settings.current_recording_slot].inputs) then
        _current_recording_size = #recording_slots[training_settings.current_recording_slot].inputs
      end
      local _x = 0
      local _y = 4
      local _padding = 4
      local _lang = lang_code[training_settings.language]
      if current_recording_state == 2 then
        local _text = {"hud_slot", " ", training_settings.current_recording_slot, ": ", "hud_wait_for_recording", " ", _current_recording_size}
        local _w, _h = 0, 0
        if _lang == "en" then
          _w, _h = get_text_dimensions_multiple(_text)
        elseif _lang == "jp" then
          _w, _h = get_text_dimensions_multiple(_text, "jp", "8")
        end
        _x = screen_width - _w - _padding
        _y = _padding
        if _lang == "en" then
          render_text_multiple(_x, _y, _text)
        elseif _lang == "jp" then
          render_text_multiple(_x, _y, _text, "jp", "8")
        end
      elseif current_recording_state == 3 then
        local _text = {"hud_slot", " ", training_settings.current_recording_slot, ": ", "hud_recording", "... (", _current_recording_size, ")"}
        local _w, _h = 0, 0
        if _lang == "en" then
          _w, _h = get_text_dimensions_multiple(_text)
        elseif _lang == "jp" then
          _w, _h = get_text_dimensions_multiple(_text, "jp", "8")
        end
        _x = screen_width - _w - _padding
        _y = _padding
        if _lang == "en" then
          render_text_multiple(_x, _y, _text)
        elseif _lang == "jp" then
          render_text_multiple(_x, _y, _text, "jp", "8")
        end
      elseif current_recording_state == 4 and dummy.pending_input_sequence and dummy.pending_input_sequence.sequence then
        local _text = {""}
        if training_settings.replay_mode == 1 or training_settings.replay_mode == 4 then
          _text = {"hud_playing", " (", dummy.pending_input_sequence.current_frame, "/", #dummy.pending_input_sequence.sequence, ")"}
        else
          _text = {"hud_playing"}
        end
        local _w, _h = 0, 0
        if _lang == "en" then
          _w, _h = get_text_dimensions_multiple(_text)
        elseif _lang == "jp" then
          _w, _h = get_text_dimensions_multiple(_text, "jp", "8")
        end
        _x = screen_width - _w - _padding
        _y = _padding
        if _lang == "en" then
          render_text_multiple(_x, _y, _text)
        elseif _lang == "jp" then
          render_text_multiple(_x, _y, _text, "jp", "8")
        end
      end
    end

    if log_enabled then
      log_draw()
    end

    if is_in_match then
      local _should_toggle = P1.input.pressed.start
      if log_enabled then
        _should_toggle = P1.input.released.start
      end
      _should_toggle = not log_start_locked and _should_toggle

      if _should_toggle then
        is_menu_open = (not is_menu_open)
        if is_menu_open then
          update_counter_attack_settings()
          menu_stack_push(main_menu)
        else
          menu_stack_clear()
        end
      end
    else
      is_menu_open = false
      menu_stack_clear()
    end

    if is_menu_open then
      local _horizontal_autofire_rate = 4
      local _vertical_autofire_rate = 4

      local _current_entry = menu_stack_top():current_entry()
      if _current_entry ~= nil and _current_entry.autofire_rate ~= nil then
        _horizontal_autofire_rate = _current_entry.autofire_rate
      end

      local _input =
      {
        down = check_input_down_autofire(P1, "down", _vertical_autofire_rate),
        up = check_input_down_autofire(P1, "up", _vertical_autofire_rate),
        left = check_input_down_autofire(P1, "left", _horizontal_autofire_rate),
        right = check_input_down_autofire(P1, "right", _horizontal_autofire_rate),
        validate = P1.input.pressed.LP,
        reset = P1.input.pressed.MP,
        cancel = P1.input.pressed.LK,
        scroll_up = P1.input.pressed.HP,
        scroll_down = P1.input.pressed.HK
      }

      --prevent scrolling across all menus and changing settings
      if P1.input.down.up or P1.input.down.down then
        _input.left = false
        _input.right = false
      end

      menu_stack_update(_input)

      menu_stack_draw()


    end

  -- memory.writeword(0x02026CB0 - 26, 350) --screen left
  -- memory.writeword(0x02026CB0 - 22, 92)
  -- set_screen_pos(224,0)
  -- memory.writebyte(0x02026c7c + 1, 7)
  -- memory.writebyte(0x02026cd0 + 1, 1)
  -- memory.writebyte(0x02026d24 + 1, 0)
  -- memory.writeword(0x02026CB0 - 22, 125)
  -- print(memory.readbyte(0x02026d24 + 1))
      -- runmem()
  --   debug_hadou_gui()
    if not is_menu_open then
      -- draw_debug_gui()
    end

    memory_display()

    -- memory_view_display()

--[[     if dump_state then
      for i = 1, #dump_state[1] do
        render_text(2,2+8*i,dump_state[1][i],"en")
      end
      for i = 1, #dump_state[2] do
        local _width = get_text_dimensions(dump_state[2][i],"en")
        render_text(screen_width-2-_width,2+8*i,dump_state[2][i],"en")
      end
    end ]]

--debug
    if frame_number % 2000 == 0 then
      collectgarbage()
      print("GC memory:", collectgarbage("count"))
    end

    if projectiles then
      for _,_obj in pairs(projectiles) do
        table.insert(to_draw, {_obj.pos_x, _obj.pos_y})
      end
    end
    local _x, _y = 0, 0
    for i=1,#to_draw do
      _x, _y = game_to_screen_space(to_draw[i][1], to_draw[i][2])
      gui.image(_x - 4, _y,img_8_dir_small, i/#to_draw)
    end

    to_draw = {}

--[[     for _k, _data in pairs(debug_prediction) do
      if frame_number == _k then
        local _x = 72
        local _y = 60
        render_text(_x,_y, string.format("Pos: %f,%f", _data[P1].pos_x, _data[P1].pos_y), "en", nil, "white")
        render_text(_x,_y+10, string.format("Vel: %f,%f", _data[P1].velocity_x, _data[P1].velocity_y), "en", nil, "white")
        render_text(_x,_y+20, string.format("Acc: %f,%f", _data[P1].acceleration_x, _data[P1].acceleration_y), "en", nil, "white")
        render_text(_x,_y+30, string.format("Pos: %f,%f", _data[P2].pos_x, _data[P2].pos_y), "en", nil, "white")
        render_text(_x,_y+40, string.format("Vel: %f,%f", _data[P2].velocity_x, _data[P2].velocity_y), "en", nil, "white")
        render_text(_x,_y+50, string.format("Acc: %f,%f", _data[P2].acceleration_x, _data[P2].acceleration_y), "en", nil, "white")

      elseif _k < frame_number then
        debug_prediction[_k] = nil
      end
    end ]]

    gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared
  end
end
to_draw_hitboxes = {}
to_draw_collision = {}
debug_prediction = {}
-- registers
emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)
