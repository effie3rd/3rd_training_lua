local gamestate = require("src/gamestate")
local loading = require("src/loading")
local text = require("src/text")
local fd = require("src/framedata")
local fdm = require("src/framedata_meta")

local frame_data = fd.frame_data
local frame_data_meta = fdm.frame_data_meta
local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text, text.render_text_multiple, text.get_text_dimensions, text.get_text_dimensions_multiple

local dump_state = {}
local function dump_variables()
  if gamestate.is_in_match then
    for _, player in pairs(gamestate.player_objects) do
      dump_state[player.id] = {
        string.format("%d: %s: Char: %d", gamestate.frame_number, player.prefix, player.char_id),
        string.format("Friends: %d", player.friends),
        string.format("Flip: %d", player.flip_x),
        string.format("x, y: %d, %d", player.pos_x, player.pos_y),
        string.format("Freeze: %d Super Freeze: %d", player.remaining_freeze_frames, player.superfreeze_decount),
        string.format("Input Cap: %d", player.input_capacity),
        string.format("Action: %d Ext: %d Count: %d", player.action, player.action_ext, player.action_count),
        string.format("Recovery Time: %d Flag %d", player.recovery_time, player.recovery_flag),
        string.format("Movement Type: %d Type 2: %d", player.movement_type, player.movement_type2),
        string.format("Posture: %d State: %d", player.posture, player.character_state_byte),
        string.format("Is Attacking: %d Ext: %d", player.is_attacking_byte, player.is_attacking_ext_byte),
        string.format("Is Blocking: %s Busy: %d", tostring(player.is_blocking), player.busy_flag),
        string.format("Is in Action: %s Idle: %s", tostring(player.is_in_basic_action), tostring(player.is_idle)),
        string.format("Next Hit Dmg: %d Stun: %d", player.damage_of_next_hit, player.stun_of_next_hit),
        string.format("Throwing: %s Being Thrown: %s CD: %d", tostring(player.is_throwing), tostring(player.is_being_thrown), player.throw_countdown),
        string.format("Anim: %s Frame %d", tostring(player.animation), player.animation_frame),
        string.format("Frame Id: %s  %s  %s", tostring(player.animation_frame_id), tostring(player.animation_frame_id2), tostring(player.animation_frame_id3)),
        string.format("Anim Hash: %s", player.animation_frame_hash),
        string.format("Recv Hit #: %d Recv Conn #: %d", player.total_received_hit_count, player.received_connection_marker),
        string.format("Hit #: %d Conn Hit #: %d", player.hit_count, player.connected_action_count),
        string.format("Stand State: %d Stunned: %s Ended: %s", player.standing_state, tostring(player.stunned), tostring(player.stun_just_ended)),
        string.format("Air Recovery: %s Is Flying Down: %s", tostring(player.is_in_air_recovery), tostring(player.is_flying_down_flag))}
    end
  end
end

local function dump_state_display()
  if gamestate.is_in_match then
    if #dump_state > 0 then
      for i = 1, #dump_state[1] do
        render_text(2,2+8*i,dump_state[1][i],"en")
      end
      for i = 1, #dump_state[2] do
        local width = get_text_dimensions(dump_state[2][i],"en")
        render_text(screen_width-2-width,2+8*i,dump_state[2][i],"en")
      end
    end
  end
end

local state = "air"
local start_debug = false
local first_time = true
local first_g = true
start_debug = false
scan_frame = 0
local first_scan = true
local n_scans = 0
local mem_scan = {}

local parry_down = false

local chardefaultcol = {}
local i_chars = 1

to_draw={} --debug


local function memory_display()
  local n = 1
  for k, v in pairs(mem_scan) do
    if n <= 20 then
      local cv = memory.readbyte(k)
      local text = string.format("%x: %08x %d", k, cv, cv)
      render_text(5, 2 + (n - 1) * 10, text, "en")
      table.insert(to_draw, {gamestate.P1.pos_x + n * 10, gamestate.P1.pos_y + cv})
    else
      break
    end
    n = n + 1
  end
end

local memory_view_start = 0x0202600f
local function memory_view_display()
  for i = 1, 20 do
    local addr = memory_view_start + 4 * (i - 1)
    local cv = memory.readdword(addr)
    local lw = bit.rshift(cv, 4 * 4)
    local rw = bit.rshift(bit.lshift(cv, 4 * 4), 4 * 4)

    local text = string.format("%x: %08x %d %d", addr, cv, lw, rw)
    render_text(5, 2 + (i - 1) * 10, text, "en")
  end
  local keys = input.get()
  if keys.down then
    memory_view_start = memory_view_start + 4
  end
  if keys.up then
    memory_view_start = memory_view_start - 4
  end
end


local function init_scan_memory()
  mem_scan = {}
  for i = 0, 80000000 do
    v = memory.readbyte(i)
    if v > 1 then
      mem_scan[i] = v
    end
  end
end

local function filter_memory_increased()
  for k, v in pairs(mem_scan) do
    local new_v = memory.readbyte(k)
    if new_v > v then
      mem_scan[k] = new_v
    else
      mem_scan[k] = nil
    end
  end
end

local function filter_memory_decreased()
  for k, v in pairs(mem_scan) do
    local new_v = memory.readbyte(k)
    if new_v < v then
      mem_scan[k] = new_v
    else
      mem_scan[k] = nil
    end
  end
end

local function run_debug()

  dump_variables()

--[[   if parry_down then
          memory.writebyte(gamestate.P2.parry_down_validity_time_addr, 2)
  end ]]
  local keys = input.get()
  if keys.down then
    parry_down = not parry_down
  end

  if loading.frame_data_loaded and first_scan then
    for char, data in pairs(frame_data) do
      local found_stand = false
      local found_crouch = false
      for id, daaa in pairs(data) do
        if type(daaa) == "table" then
          for k,v in pairs(daaa) do
            if k == "frames" then
              for i=1, #v do
                if not v[i].hash then
                  print(char,id,i)
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
        print(char, "no stand turn")
      end
      if not found_crouch then
        print(char, "no crouch turn")
      end
    end
    first_scan = false
  end

  if start_debug then
    if not gamestate.P2.previous_is_wakingup and gamestate.P2.is_wakingup then
      if first_time then
        scan_frame = gamestate.frame_number + 50
        first_time = false
      else
        filter_memory_increased()
        n_scans = 0
      end
    elseif gamestate.P2.is_wakingup then
      if first_scan and gamestate.frame_number == scan_frame then
        init_scan_memory()
        first_scan = false
        scan_frame = gamestate.frame_number + 15
      end
      if gamestate.frame_number == scan_frame and n_scans < 2 then
        filter_memory_decreased()
        scan_frame = gamestate.frame_number + 15
        n_scans = n_scans + 1
      end
    end
  end
end

local function debug_things()
  for k,v in pairs(gamestate.P1) do
    print (k, type(k))
  end
end

local debug =  {
  dump_state_display = dump_state_display,
  init_scan_memory = init_scan_memory,
  filter_memory_increased = filter_memory_increased,
  filter_memory_decreased = filter_memory_decreased,
  memory_display = memory_display,
  memory_view_display = memory_view_display,
  run_debug = run_debug,
  debug_things = debug_things
}

setmetatable(debug, {
  __index = function(_, key)
    if key == "memory_view_start" then
      return memory_view_start
    elseif key == "start_debug" then
      return start_debug
    end
  end,

  __newindex = function(_, key, value)
    if key == "memory_view_start" then
      memory_view_start = value
    elseif key == "start_debug" then
      start_debug = value
    else
      rawset(debug, key, value)
    end
  end
})

return debug