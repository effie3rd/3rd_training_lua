function init_debug()
  local _path = string.format("%s%s", saved_recordings_path, "Debug.json")
  print(_path)
  local _recording = read_object_from_json_file(_path)
  if not _recording then
    print(string.format("Error: Failed to load recording from \"%s\"", _path))
  else
    recording_slots[1].inputs = _recording
    print(string.format("Loaded \"%s\" to slot %d", _path, 1))
  end
end



local state = "air"
start_debug = false
local first_time = true
local first_g = true
start_debug = false
scan_frame = 0
local first_scan = true
local n_scans = 0

local parry_down = false

local chardefaultcol = {}
local i_chars = 1
function run_debug()

--[[   if parry_down then
          memory.writebyte(P2.parry_down_validity_time_addr, 2)
  end ]]
  local keys = input.get()
  if keys.down then
    parry_down = not parry_down
  end

--[[   if has_match_just_started then
    if i_chars <= #characters then
      print("hi")
      if not chardefaultcol[P1.char_str] then
        chardefaultcol[P1.char_str] = {}
      end
      if not chardefaultcol[P2.char_str] then
        chardefaultcol[P2.char_str] = {}
      end
      chardefaultcol[P1.char_str][1] = memory.readword(P1.base + 616)
      chardefaultcol[P2.char_str][2] = memory.readword(P2.base + 616)
      local _char = characters[i_chars]
      table.insert(after_load_state_callback, {command = force_select_character, args = {P1.id, _char, 1, "LP"} })
      table.insert(after_load_state_callback, {command = force_select_character, args = {P2.id, _char, 1, "LP"} })
      start_character_select_sequence()
      i_chars = i_chars + 1
    else
      for k,v in pairs(chardefaultcol) do
        print(k .. " = ",  v)
      end
    end
  end ]]

          if frame_data_loaded and first_scan then
            for _char, _data in pairs(frame_data) do
              local found_stand = false
              local found_crouch = false
              for id, _daaa in pairs(_data) do
                if type(_daaa) == "table" then
                  for k,v in pairs(_daaa) do
                    if k == "frames" then
                      for i=1, #v do
                        if not v[i].hash then
                          print(_char,id,i)
                        end
                      end
                    end
                  end
                end
                if id == "standing_turn" then
                  found_stand = true
                end
                if id == "crouching_turn" then
                  found_crouch = true
                end
              end
              if not found_stand then
                print(_char, "no stand turn")
              end
              if not found_crouch then
                print(_char, "no crouch turn")
              end
            end
            first_scan = false
          end


  if start_debug then
    if not P2.previous_is_wakingup and P2.is_wakingup then
      if first_time then
        scan_frame = frame_number + 50
        first_time = false
      else
        filter_memory_increased()
        n_scans = 0
      end
    elseif P2.is_wakingup then
      if first_scan and frame_number == scan_frame then
        init_scan_memory()
        first_scan = false
        scan_frame = frame_number + 15
      end
      if frame_number == scan_frame and n_scans < 2 then
        filter_memory_decreased()
        scan_frame = frame_number + 15
        n_scans = n_scans + 1
      end
    end
  end

--[[   if start_debug then
    if P1.animation == "a530" and P1.animation_frame >= 9 then
      state = "jumping"
      -- filter_memory_decreased()
      queue_input_sequence(P1,{{"up"}})
      print("filter ground")
    elseif P1.animation == "b028" and P1.pos_y <= 65 and P1.pos_y - P1.previous_pos_y < 0 then
      state = "HP"
      if not first_time then
        filter_memory_decreased()
      end
      first_time = false
      queue_input_sequence(P1,{{"HP"}})
      print("filter jump")
    elseif P1.animation == "50b4" and P1.animation_frame >= 9  and state == "HP" then
      state = "land"
      filter_memory_increased()
      print("filter hp")
    end
  end ]]
end

function memory_display()
  local n = 1
  for k, v in pairs(mem_scan) do
    if n <= 20 then
      local cv = memory.readbyte(k)
      local _text = string.format("%x: %08x %d", k, cv, cv)
      render_text(5, 2 + (n - 1) * 10, _text, "en")
      table.insert(to_draw, {P1.pos_x + n * 10, P1.pos_y + cv})
    else
      break
    end
    n = n + 1
  end
end

memory_view_start = 0x0202600f
function memory_view_display()
  for i = 1, 20 do
    local addr = memory_view_start + 4 * (i - 1)
    local cv = memory.readdword(addr)
    local lw = bit.rshift(cv, 4 * 4)
    local rw = bit.rshift(bit.lshift(cv, 4 * 4), 4 * 4)

    local _text = string.format("%x: %08x %d %d", addr, cv, lw, rw)
    render_text(5, 2 + (i - 1) * 10, _text, "en")
  end
  local keys = input.get()
  if keys.down then
    memory_view_start = memory_view_start + 4
  end
  if keys.up then
    memory_view_start = memory_view_start - 4
  end
end


mem_scan = {}
function init_scan_memory()
  mem_scan = {}
  for i = 0, 80000000 do
    _v = memory.readbyte(i)
    if _v > 1 then
      mem_scan[i] = _v
    end
  end
end

function filter_memory_increased()
  for k, v in pairs(mem_scan) do
    local new_v = memory.readbyte(k)
    if new_v > v then
      mem_scan[k] = new_v
    else
      mem_scan[k] = nil
    end
  end
end

function filter_memory_decreased()
  for k, v in pairs(mem_scan) do
    local new_v = memory.readbyte(k)
    if new_v < v then
      mem_scan[k] = new_v
    else
      mem_scan[k] = nil
    end
  end
end
