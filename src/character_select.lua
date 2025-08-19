character_select_savestate = savestate.create("data/"..rom_name.."/savestates/character_select.fs")
first_run = true
character_select_start_frame = 0
clear_buttons_until_frame = 0
character_select_coroutines = {}
random_select_coroutine = nil
selecting_random_character = false
disable_select_boss = false
last_player_id = 1

-- 0 is out
-- 1 is waiting for input release for p1
-- 2 is selecting p1
-- 3 is waiting for input release for p2
-- 4 is selecting p2
character_select_sequence_state = 0

character_select_loc = {{0,1},{0,2},{0,3},{0,4},{0,5},{0,6},{1,0},{1,1},{1,2},{1,3},{1,4},{1,5},{1,6},{2,0},{2,1},{2,2},{2,3},{2,4},{2,5}}
character_map =
{
  ["alex"]={0,1},
  ["sean"]={0,2},
  ["ibuki"]={0,3},
  ["necro"]={0,4},
  ["urien"]={0,5},
  ["gouki"]={0,6},
  ["yang"]={1,0},
  ["twelve"]={1,1},
  ["makoto"]={1,2},
  ["chunli"]={1,3},
  ["q"]={1,4},
  ["remy"]={1,5},
  ["yun"]={1,6},
  ["ken"]={2,0},
  ["hugo"]={2,1},
  ["elena"]={2,2},
  ["dudley"]={2,3},
  ["oro"]={2,4},
  ["ryu"]={2,5},
  ["gill"]={3,1},
  ["shingouki"]={0,6}
}

function co_wait_x_frames(_frame_count)
  local _start_frame = frame_number
  while frame_number < _start_frame + _frame_count do
    coroutine.yield()
  end
end
--fixes a bug where fightcade loads its own savestate
--and causes p1's SA selection to also select p2's character
function co_delay_load_savestate(_input)
  co_wait_x_frames(1)
  character_select_sequence_state = 1
  table.insert(after_load_state_callback, {command = after_character_select_loaded})
  savestate.load(character_select_savestate)
end

function after_character_select_loaded()
  clear_buttons_until_frame = frame_number + 30
  character_select_start_frame = frame_number
end

function start_character_select_sequence(_disable_select_boss)
  if first_run then
    character_select_coroutine(co_delay_load_savestate, "delay_load")
    first_run = false
  else
    character_select_sequence_state = 1
    table.insert(after_load_state_callback, {command = after_character_select_loaded})
    savestate.load(character_select_savestate)
  end
  last_player_id = 1

  disable_select_boss = _disable_select_boss or false
end

local p1_forced_select = false
function force_select_character(_player_id, _char, _sa, _sel_button)
  force_character_select_coroutine(co_force_select_character, "force_p" .. _player_id, _player_id, _char, _sa, _sel_button)
end

function co_force_select_character(_input, _player_id, _char, _sa, _sel_button)
  local _col = character_map[_char][1]
  local _row = character_map[_char][2]

  local _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)

  if _character_select_state > 2 then
    return
  end

  local _curr_col = -1
  local _curr_row = -1

  while not (_curr_col == _col and _curr_row == _row) do
    memory.writebyte(addresses.players[_player_id].character_select_col, _col)
    memory.writebyte(addresses.players[_player_id].character_select_row, _row)
    co_wait_x_frames(1)
    _curr_col = memory.readbyte(addresses.players[_player_id].character_select_col)
    _curr_row = memory.readbyte(addresses.players[_player_id].character_select_row)
  end

  while _character_select_state < 3 do
    co_wait_x_frames(2)
    queue_input_sequence(player_objects[_player_id], {{_sel_button}})
    co_wait_x_frames(2)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end

  while _character_select_state < 4 do
    co_wait_x_frames(1)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end

  if _char == "shingouki" then
    memory.writebyte(addresses.players[_player_id].character_select_id, 0x0F)
  end

  if _sa == 2 then
    queue_input_sequence(player_objects[_player_id], {{"down"}})
    co_wait_x_frames(20)
  elseif _sa == 3 then
    queue_input_sequence(player_objects[_player_id], {{"up"}})
    co_wait_x_frames(20)
  end

  while _character_select_state < 5 do
    queue_input_sequence(player_objects[_player_id], {{_sel_button}})
    co_wait_x_frames(2)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end
end


function select_gill()
  if not disable_select_boss then
    if not character_select_coroutines["gill"] then
      character_select_coroutine(co_select_gill, "gill")
    end
  end
end

function co_select_gill(_input)
  local _player_id = 1
  local _sel_buttons = {"LP","HK"}
  local _i = math.random(1,#_sel_buttons)
  local _sel_button = _sel_buttons[_i]
  local _p1_character_select_state = memory.readbyte(addresses.players[1].character_select_state)
  local _p2_character_select_state = memory.readbyte(addresses.players[2].character_select_state)

  if _p1_character_select_state > 2 and _p2_character_select_state > 2 then
    return
  end

  if _p1_character_select_state <= 2 then
    _player_id = 1
    _character_select_state = _p1_character_select_state
  else
    _player_id = 2
    _character_select_state = _p2_character_select_state
  end

  memory.writebyte(addresses.players[_player_id].character_select_col, 3)
  memory.writebyte(addresses.players[_player_id].character_select_row, 1)

  while _character_select_state < 3 do
    co_wait_x_frames(2)
    queue_input_sequence(P1, {{_sel_button}})
    co_wait_x_frames(2)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end

  while _character_select_state < 4 do
    co_wait_x_frames(1)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end

  while _character_select_state < 5 do
    queue_input_sequence(P1, {{_sel_button}})
    co_wait_x_frames(2)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end
end

function select_shingouki()
  if not disable_select_boss then
    if not character_select_coroutines["shingouki"] then
      character_select_coroutine(co_select_shingouki, "shingouki")
    end
  end
end

function co_select_shingouki(_input)
  local _player_id = 1

  local _sel_buttons = {"LP","HK"}
  local _i = math.random(1,#_sel_buttons)
  local _sel_button = _sel_buttons[_i]
  local _p1_character_select_state = memory.readbyte(addresses.players[1].character_select_state)
  local _p2_character_select_state = memory.readbyte(addresses.players[2].character_select_state)

  if _p1_character_select_state > 2 and _p2_character_select_state > 2 then
    return
  end

  if _p1_character_select_state <= 2 then
    _player_id = 1
    _character_select_state = _p1_character_select_state
  else
    _player_id = 2
    _character_select_state = _p2_character_select_state
  end

  memory.writebyte(addresses.players[_player_id].character_select_col, 0)
  memory.writebyte(addresses.players[_player_id].character_select_row, 6)


  while _character_select_state < 3 do
    co_wait_x_frames(2)
    queue_input_sequence(P1, {{_sel_button}})
    co_wait_x_frames(2)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end

  while _character_select_state < 4 do
    co_wait_x_frames(1)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end

  memory.writebyte(addresses.players[_player_id].character_select_id, 0x0F)

  while _character_select_state < 5 do
    queue_input_sequence(P1, {{_sel_button}})
    co_wait_x_frames(2)
    _character_select_state = memory.readbyte(addresses.players[_player_id].character_select_state)
  end
end

function start_select_random_character()
  selecting_random_character = true
end

function stop_select_random_character()
  selecting_random_character = false
end

function select_random_character()
  if not p1_forced_select and not character_select_coroutines["select_random"] then
     character_select_coroutine(co_random_character, "select_random")
  end
end

function co_random_character(_input)

  if not selecting_random_character then
    return
  end

  local _player_id
  local _p1_character_select_state
  local _p2_character_select_state

  _p1_character_select_state = memory.readbyte(addresses.players[1].character_select_state)
  _p2_character_select_state = memory.readbyte(addresses.players[2].character_select_state)

  if _p1_character_select_state <= 2 then
    _player_id = 1
  elseif _p1_character_select_state >= 5 and _p2_character_select_state <= 2 then
    _player_id = 2
  else
    return
  end

  --stop random select after p1 character is chosen
  if last_player_id ~= _player_id then
    last_player_id = _player_id
    stop_select_random_character()
    return
  end

  local _character_select_col = memory.readbyte(addresses.players[_player_id].character_select_col)
  local _character_select_row = memory.readbyte(addresses.players[_player_id].character_select_row)

  --don't select the same character twice
  while true do
    local n = math.random(1,#character_select_loc)

    local _col = character_select_loc[n][1]
    local _row = character_select_loc[n][2]

    if _col ~= _character_select_col or _row ~= _character_select_row then
      memory.writebyte(addresses.players[_player_id].character_select_col, _col)
      memory.writebyte(addresses.players[_player_id].character_select_row, _row)
      break
    end
  end
end

function character_select_coroutine(_co, _name)
  local _o = {}
  _o.coroutine = coroutine.create(_co)
  _o.name = _name

  function _o:resume(_input)
    return coroutine.resume(self.coroutine, _input)
  end

  function _o:status()
    return coroutine.status(self.coroutine)
  end

  character_select_coroutines[_name] = _o
  return _o
end

function force_character_select_coroutine(_co, _name, _player, _char, _sa, _sel_button)
  local _o = {}
  _o.coroutine = coroutine.create(_co)
  _o.name = _name
  _o.player = _player
  _o.char = _char
  _o.sa = _sa
  _o.sel_button = _sel_button


  function _o:resume(_input)
    return coroutine.resume(self.coroutine, _input, self.player, self.char, self.sa, self.sel_button)
  end

  function _o:status()
    return coroutine.status(self.coroutine)
  end

  character_select_coroutines[_name] = _o
  return _o
end

local _p1_character_select_state = 0
local _p2_character_select_state = 0
function update_character_select(_input, _do_fast_forward)

  if not character_select_sequence_state == 0 then
    return
  end

  -- Infinite select time
  --memory.writebyte(addresses.global.character_select_timer, 0x30)

  if p1_forced_select then
    make_input_empty(_input)
  end

  for _k,_cs in pairs(character_select_coroutines) do
    local _status = _cs:status()
    if _status == "suspended" then
      local _r, _error = _cs:resume(_input)
      if not _r then
        print(_error)
      end
    elseif _status == "dead" then
      character_select_coroutines[_k] = nil
      if _cs.name == "force_p1" then
        p1_forced_select = false
      elseif _cs.name == "force_p2" then
        p2_forced_select = false
      end
    end
    if _cs.name == "force_p1" then
      p1_forced_select = true
    elseif _cs.name == "force_p2" then
      p2_forced_select = true
    end
  end

  _p1_character_select_state = memory.readbyte(addresses.players[1].character_select_state)
  _p2_character_select_state = memory.readbyte(addresses.players[2].character_select_state)


  if not p1_forced_select then
  --   print(string.format("%d, %d, %d", character_select_sequence_state, _p1_character_select_state, _p2_character_select_state))

    if _p1_character_select_state > 4 and not is_in_match then
      if character_select_sequence_state == 2 then
        character_select_sequence_state = 3
      end

      --for _key, _value in pairs(_input) do
      --  print(string.format("%s %s",_key, tostring(_value)))
      --end
      if not p1_forced_select and not p2_forced_select then
        swap_inputs(_input)
      end
      --for _key, _value in pairs(_input) do
      --  print(string.format("Swap %s %s",_key, tostring(_value)))
      --end
      --print(string.format("State %d",character_select_sequence_state))
    end

    if frame_number < clear_buttons_until_frame then
      clear_p1_buttons(_input)
    end

    -- wait for all inputs to be released
    if character_select_sequence_state == 1 or character_select_sequence_state == 3 then
      for _key, _state in pairs(_input) do
        if _state == true then
          make_input_empty(_input)
          return
        end
      end
      character_select_sequence_state = character_select_sequence_state + 1
    end

    if selecting_random_character then
      clear_directional_input(_input)
    end
  end

  if not is_in_match and training_settings.force_stage > 1 then
    local _stage = stage_map[training_settings.force_stage]
    if training_settings.force_stage == 2 then
      local _n = 3 + math.random(0, #stage_list - 3)
      _stage = stage_map[_n]
    end
    memory.writebyte(addresses.global.stage, _stage)
  end


  if has_match_just_started then
    emu.speedmode("normal")
    character_select_sequence_state = 0
    selecting_random_character = false
  elseif not is_in_match then
    if _do_fast_forward and _p1_character_select_state > 4 and _p2_character_select_state > 4 then
      emu.speedmode("turbo")
    elseif character_select_sequence_state == 0 and (_p1_character_select_state < 5 or _p2_character_select_state < 5) then
      emu.speedmode("normal")
      character_select_sequence_state = 1
    end
  else
    character_select_sequence_state = 0
  end
end

local character_select_text_display_time = 120
local character_select_text_fade_time = 30
function draw_character_select()
  if _p1_character_select_state <= 2 or _p2_character_select_state <= 2 then
    local _elapsed = frame_number - character_select_start_frame
    if _elapsed <= character_select_text_display_time + character_select_text_fade_time then
      local _opacity = 1
      if _elapsed > character_select_text_display_time then
        _opacity = 1 - ((_elapsed - character_select_text_display_time) / character_select_text_fade_time)
      end
      local _w,_h = get_text_dimensions("character_select_line_1")
      local _padding_x = 0
      local _padding_y = 0
      render_text(_padding_x, _padding_y, "character_select_line_1", nil, nil, nil, _opacity)
      render_text(_padding_x, _padding_y + _h, "character_select_line_2", nil, nil, nil, _opacity)
      render_text(_padding_x, _padding_y + _h + _h, "character_select_line_3", nil, nil, nil, _opacity)
    end
  end
end
