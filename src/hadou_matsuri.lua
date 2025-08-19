require "memthis"
require "gd"

hadou_matsuri_savestate = savestate.create("data/"..rom_name.."/savestates/hadou_matsuri.fs")

grade_F = gd.createFromPng("images/challenge/fplus.png")
-- grade_Fplus = gd.createFromPng("images/menu/adv.png"):gdStr()


grade_F = grade_F:gdStr()


local motion_hadou_lp = {{"down"},{"down","forward"},{"forward","LP"}}
local motion_hadou_mp = {{"down"},{"down","forward"},{"forward","MP"}}
local motion_hadou_hp = {{"down"},{"down","forward"},{"forward","HP"}}

local motion_teleport_forward_p = {{"forward"},{"down"},{"down","forward","LP","MP","HP"}}

local motion_sgs = {{"down","HK"},{"LP"},{},{"LP"},{"forward"},{"LK"},{"HP"}}
--Anim: a130 Frame Id: 22275  1  24 hadou lp
--Anim: a210 Frame Id: 22275  1  24
--Anim: a2a0 Frame Id: 22275  1  24

local funcs = {}
local score = 0
local animation_cancel_delay = 0 --10
local air_hadou_startup = 12

local base_gravity = -1
local base_gravity_mantissa = 0x78

local base_jump_f_vel_x = 4  -- + 0x40
local base_jump_f_vel_y = 9 -- + 0xa0
local base_jump_n_vel_x = 0
local base_jump_n_vel_y = 8  -- + 0x70
local base_jump_b_vel_x = -5 -- + 0x80
local base_jump_b_vel_y = 8 -- + 0x60

local base_sjump_f_vel_x = 5 -- + 0x80
local base_sjump_f_vel_y = 10
local base_sjump_n_vel_x = 0
local base_sjump_n_vel_y = 9 -- + 0x80
local base_sjump_b_vel_x = -5 --+ 0xe0
local base_sjump_b_vel_y = 9

local base_lp_air_hadou_vel_x = 4
local base_lp_air_hadou_vel_y = -3
local base_mp_air_hadou_vel_x = 4
local base_mp_air_hadou_vel_y = -4
local base_hp_air_hadou_vel_x = 5
local base_hp_air_hadou_vel_y = -4

local previous_velocity_x = 0 --{}

local modify_projectile_queue = {}

function get_player_bounds(_obj)
  local result = {}
  result.left = _obj.pos_x
  result.right = _obj.pos_x
  result.bottom = _obj.pos_y
  result.top = _obj.pos_y
  for _k, _box in pairs(_obj.boxes) do
    if _box.type == "vulnerability" then
      local _right = _box.left + _box.width
      local _top = _box.bottom + _box.height
      if _box.left < result.left then
        result.left = _box.left
      end
      if _right > result.right then
        result.right = _right
      end
      if _box.bottom < result.bottom then
        result.bottom = _box.bottom
      end
      if _top > result.top then
        result.top = _top
      end
    end
  end
  return result
end

--Anim: 8af8 Frame Id: 22179  3  60

function freeze(_obj, _t)
  memory.writebyte(_obj.base + 0x45, _t)
end

function unfreeze()
    memory.writebyte(player.base + 0x45, 0) --allow p2 to move during super freeze
end

function animation_cancel(_args)
  local _player_obj = _args[1]
--  memory.writebyte(P1.life_addr, 0x0) --p1 life
--   memory.writebyte(P2.life_addr, 0x0) --p2 life
  memory.writebyte(_player_obj.base + 0x27, 0x0)
  memory.writeword(_player_obj.base + 0x202, 0x8800) --idle
  memory.writeword(_player_obj.base + 0x21A, 22177)
  memory.writeword(_player_obj.base + 0x214, 1) --frameid2
  memory.writeword(_player_obj.base + 0x205, 1) --frameid3

  memory.writeword(_player_obj.base + 0x3D1, 0x0)
  memory.writeword(_player_obj.base + 0xAC, 0)
  memory.writeword(_player_obj.base + 0x12C, 0)
end

function animation_cancel_air(_args)
  local _player_obj = _args[1]
  memory.writebyte(_player_obj.base + 0x27, 0x0)
  memory.writeword(_player_obj.base + 0x202, 0xa130) --idle
  memory.writeword(_player_obj.base + 0x21A, 22274)
  memory.writeword(_player_obj.base + 0x214, 3) --frameid2
  memory.writeword(_player_obj.base + 0x205, 36) --frameid3

  memory.writeword(_player_obj.base + 0x3D1, 0x0)
  memory.writeword(_player_obj.base + 0xAC, 0)
  memory.writeword(_player_obj.base + 0x12C, 0)
end

function queue_input(_player_obj, _delay, _input_sequence)
  for _i = 1, #_input_sequence do
    local _frame = frame_number + _i - 1 + _delay

    if _player_obj.command_queue[_frame] and _player_obj.command_queue[_frame].input then
      table.insert(_player_obj.command_queue[_frame].input, _input_sequence[_i])
    else
      _player_obj.command_queue[_frame] = {}
      _player_obj.command_queue[_frame].input = _input_sequence[_i]
    end
  end
--   low = 9999990
--   high = 1
--   for _f, _val in pairs(_player_obj.command_queue) do
--     if _f <low then
--       low = _f
--       end
--     if _f >high then
--       high= _f
--       end
--   end
--   for i=low,high do
--     if(_player_obj.command_queue[i]) then
--       if _player_obj.command_queue[i].input then
--         print(i, unpack(_player_obj.command_queue[i].input))
--       else
--         print(i, unpack(_player_obj.command_queue[i]))
--       end
--     end
--   end
--   print("-=-=-")

end

function clear_command_queue(_player_obj)
  _player_obj.command_queue = {}
end

function queue_func(_player_obj, _delay, _com)
  local _frame = frame_number + _delay
  if _player_obj.command_queue[_frame] then
    if _player_obj.command_queue[_frame].command then
      table.insert(_player_obj.command_queue[_frame].command, _com)
    else
      _player_obj.command_queue[_frame].command = {_com}
    end
  else
    _player_obj.command_queue[_frame] = {}
    _player_obj.command_queue[_frame].command = {_com}
  end
end

function queue_modify_projectile(_player_obj, _delay, _com)
  local _frame = frame_number + _delay
  if _player_obj.command_queue[_frame] then
    if _player_obj.command_queue[_frame].modify then
      table.insert(_player_obj.command_queue[_frame].modify, {func=insert_modify_projectile, args=_com})
    else
      _player_obj.command_queue[_frame].modify = {{func=insert_modify_projectile, args=_com}}
    end
  else
    _player_obj.command_queue[_frame] = {}
    _player_obj.command_queue[_frame].modify = {{func=insert_modify_projectile, args=_com}}
  end
end

function insert_modify_projectile(_com)
  table.insert(modify_projectile_queue, _com)
end

hm_input = {}

function process_command_queue(_player_obj, _input)

  hm_input = {}

  if _player_obj.command_queue == nil then
    return
  end
  if is_menu_open then
    return
  end
  if not is_in_match then
    return
  end

  local _gauges_base = 0
  if _player_obj.id == 1 then
  _gauges_base = 0x020259D8
  elseif _player_obj.id == 2 then
  _gauges_base = 0x02025FF8
  end
  local _gauges_offsets = { 0x0, 0x1C, 0x38, 0x54, 0x70 }
  if _player_obj.command_queue[frame_number] then
    -- Cancel all input
    _input[_player_obj.prefix.." Up"] = false
    _input[_player_obj.prefix.." Down"] = false
    _input[_player_obj.prefix.." Left"] = false
    _input[_player_obj.prefix.." Right"] = false
    _input[_player_obj.prefix.." Weak Punch"] = false
    _input[_player_obj.prefix.." Medium Punch"] = false
    _input[_player_obj.prefix.." Strong Punch"] = false
    _input[_player_obj.prefix.." Weak Kick"] = false
    _input[_player_obj.prefix.." Medium Kick"] = false
    _input[_player_obj.prefix.." Strong Kick"] = false

    for _key, _command in pairs(_player_obj.command_queue[frame_number]) do

      if _key == "command" then
        for _k, _c in pairs(_command) do
          _c.func(unpack(_c.args))
        end
      elseif _key == "modify" then
        for _k, _c in pairs(_command) do
          _c.func(_c.args)
        end
      elseif _key == "input" then
        local _current_frame_input = _command
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
              memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
            elseif _player_obj.char_str == "oro" then
              memory.writeword(_gauges_base + _gauges_offsets[3], 0xFFFF)
            elseif _player_obj.char_str == "chunli" then
            elseif _player_obj.char_str == "q" then
              memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
              memory.writeword(_gauges_base + _gauges_offsets[2], 0xFFFF)
            elseif _player_obj.char_str == "remy" then
              memory.writeword(_gauges_base + _gauges_offsets[2], 0xFFFF)
              memory.writeword(_gauges_base + _gauges_offsets[3], 0xFFFF)
            elseif _player_obj.char_str == "alex" then
              memory.writeword(_gauges_base + _gauges_offsets[5], 0xFFFF)
            end
            elseif _current_frame_input[i] == "v_charge" then
              if _player_obj.char_str == "urien" then
                memory.writeword(_gauges_base + _gauges_offsets[2], 0xFFFF)
                memory.writeword(_gauges_base + _gauges_offsets[4], 0xFFFF)
              elseif _player_obj.char_str == "oro" then
                memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
              elseif _player_obj.char_str == "chunli" then
                memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
              elseif _player_obj.char_str == "q" then
              elseif _player_obj.char_str == "remy" then
                memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
              elseif _player_obj.char_str == "alex" then
                memory.writeword(_gauges_base + _gauges_offsets[4], 0xFFFF)
              end
            end
        _input[_input_name] = true
        end
      end
    end
    end
    _player_obj.command_queue[frame_number] = nil
    joypad.set(_input)
    hm_input = _input
end

function zero_gauge(_player_obj)
  memory.writebyte(_player_obj.gauge_addr, 0)
  memory.writebyte(_player_obj.meter_addr[2], 0)
--   memory.writebyte(_player_obj.meter_update_flag, 0x01)
end

function full_gauge(_player_obj)
  memory.writebyte(_player_obj.gauge_addr, _player_obj.max_meter_gauge)
  memory.writebyte(_player_obj.meter_addr[2], _player_obj.max_meter_count)
  memory.writebyte(_player_obj.meter_update_flag, 0x01)
end


function air_hadou()
  queue_input(P1, 0, motion_hadou_lp)
  queue_func(P1, 2, funcs["zero_gauge"], {P1})
end

function sgs()
  clear_input(P1)
  queue_input(P1, 0, motion_sgs)
  queue_func(P1, #motion_sgs-2, {func=full_gauge, args={_player_obj}})
end

function overlap_hadou(_obj, _distance, _speed, _n)
  if _obj.lifetime < _speed then
    print("mod")
    _velx = (air_hadou_startup * _n * base_lp_air_hadou_vel_x - _distance) / _speed
    _vely = -1 * (air_hadou_startup * _n* -1 * base_lp_air_hadou_vel_y - _distance) / _speed
    set_velocity_x(_obj, _velx, 0)
    set_velocity_y(_obj, _vely, 0)
  else
    set_velocity_x(_obj, base_lp_air_hadou_vel_x, 0)
    set_velocity_y(_obj, base_lp_air_hadou_vel_y, 0)
  end
end

function bounce_hadou(_obj)

end

function queue_volley(_player_obj, _delay, _n, _speed, _version)
  _speed = math.max(_speed, air_hadou_startup + animation_cancel_delay)
  for _i = 0, _n - 1 do
    if _version == "LP" then
      queue_input(_player_obj, _delay + _i * _speed + 1, motion_hadou_lp)
      queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=zero_gauge, args={_player_obj}})
    elseif _version == "HP" then
      queue_input(_player_obj, _delay + _i * _speed + 1, motion_hadou_hp)
      queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_hp - 1, {func=zero_gauge, args={_player_obj}})
    elseif _version == "alternate" then
      if _i % 2 == 0 then
        queue_input(_player_obj, _delay + _i * _speed + 1, motion_hadou_lp)
        queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=zero_gauge, args={_player_obj}})
      else
        queue_input(_player_obj, _delay + _i * _speed + 1, motion_hadou_hp)
        queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_hp - 1, {func=zero_gauge, args={_player_obj}})
      end
    elseif _version == "overlap" then
      queue_input(_player_obj, _delay + _i * _speed + 1, motion_hadou_lp)
      queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=zero_gauge, args={_player_obj}})
      if _i ~= 0 then
        queue_modify_projectile(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=overlap_hadou, args={4,2,_i}})
      end
    end


    queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=set_velocity_x, args={_player_obj, 0, 0}})
    queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=set_velocity_y, args={_player_obj, 0, 0}})
    queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=set_acceleration_x, args={_player_obj, 0, 0}})
    if _i < _n - 1 then
      queue_func(_player_obj, _delay + _i * _speed + 1 + #motion_hadou_lp - 1, {func=set_acceleration_y, args={_player_obj, 0, 0}})
    else
      queue_func(_player_obj, _delay + (_i + 1) * _speed + 1 + #motion_hadou_lp - 1, {func=set_velocity_x, args={_player_obj, 8, 0}})
      queue_func(_player_obj, _delay + (_i + 1) * _speed + 1 + #motion_hadou_lp - 1, {func=set_velocity_y, args={_player_obj, 10, 0}})
      queue_func(_player_obj, _delay + (_i + 1) * _speed + 1 + #motion_hadou_lp - 1, {func=set_acceleration_y, args={_player_obj, base_gravity, base_gravity_mantissa}})
    end
  end

end

function sweep_screen()
end

function air_crossup()
end

--alternate side pattern
--X Pattern
--reverse flip of proj
--homing red fireball _y
--flower petal falling hadou very top of screen --add each new proj to list, check emitter id and freeze
--cancel out of sgs on player jump at higher levels
--pause all projectiles

--animation cancel min-max
--flames proj up

--transparent red flash with arrows
--fake hadou
--mess with proj speed / angle

--capture offscreen fireballs to reuse

--detect running away

function kill_player()

end

--check if player is cornered

--check if P2 is cornered

--P2 base movespeed forward 3 3 4 backwards 2 3

--set gauges and hp
-- memory.writebyte(_player_obj.gauge_addr, _gauge_value)
-- memory.writebyte(_player_obj.meter_addr[2], _player_obj.max_meter_count)
-- memory.writebyte(_player_obj.meter_update_flag, 0x01)

--air parry increases _y by 1

--color code different hadou attacks

--super that bounces on screen edge

--very slow then after a while accelerate

--fix hitboxes on flip looks like just a y flip

-- screen_width = 383
-- screen_height = 223
-- ground_offset = 23


function flip_box(_obj, _ptr, _type)
  if _obj.friends > 1 then --Yang SA3
    if _type ~= "attack" then
      return
    end
  end
--   if _box.type
  local bottom = memory.readwordsigned(_ptr + 0x4)
  local height = memory.readwordsigned(_ptr + 0x6)

  memory.writeword(_ptr + 0x4, bottom-30)
  memory.writeword(_ptr + 0x6, -height)

end

function flippy(_obj)
--   if memory.readdword(_obj.base + 0x2A0) == 0 then --invalid objects
--     return false
--   end

  local _boxes = {
    {initial = 1, offset = 0x2D4, type = "push", number = 1},
    {initial = 1, offset = 0x2C0, type = "throwable", number = 1},
    {initial = 1, offset = 0x2A0, type = "vulnerability", number = 4},
    {initial = 1, offset = 0x2A8, type = "ext. vulnerability", number = 4},
    {initial = 1, offset = 0x2C8, type = "attack", number = 4},
    {initial = 1, offset = 0x2B8, type = "throw", number = 1}
    }

  for _, _box in ipairs(_boxes) do
    for i = _box.initial, _box.number do
      flip_box(_obj, memory.readdword(_obj.base + _box.offset) + (i-1)*8, _box.type)
    end
  end
  return true
end


function debug_challenge()
--   queue_input(P1, 1, motion_hadou_lp)
   queue_input(P2, 1, {{"down"},{"up","forward"},{"up","forward"}})
   queue_volley(P2, 12, 3, 0, "overlap")
   queue_volley(P2, 92, 3, 0, "overlap")

  --initial_search()

end

function hadou_matsuri_save_ss()
  hadou_matsuri_savestate = savestate.create("data/"..rom_name.."/savestates/hadou_matsuri.fs")
  full_gauge(P2)
  zero_gauge(P1)
  savestate.save(hadou_matsuri_savestate)
end
function hadou_matsuri_load_ss()
  hadou_matsuri_savestate = savestate.create("data/"..rom_name.."/savestates/hadou_matsuri.fs")
  savestate.load(hadou_matsuri_savestate)
end

function play_hadou_matsuri()
--save state first
end

function select_character_hadou_matsuri()

--save state first
  is_in_challenge = true
  table.insert(after_load_state_callback, {command = function() new_character=true end})
  table.insert(after_load_state_callback, {command = force_select_character, args ={1, "urien", 2, "HK"}})
  table.insert(after_load_state_callback, {command = force_select_character, args ={2, "shingouki", 1, "HK"}})

  start_character_select_sequence(true)

end

function hadou_matsuri_start()
  score = 0

  is_in_challenge = true
--   hadou_matsuri_load_ss()

  P1.command_queue = {}
  P2.command_queue = {}


  full_gauge(P2)
  zero_gauge(P1)
--   flippy(P1)

end

debug_color = 0x501d
the_end = false
local attack_pattern = {}
new_character = false
intro_state = "wait_for_match"
function hadou_matsuri_run()
  if new_character then
    if match_state == 1 then
      if intro_state == "wait_for_match" then
-- for i = 1, 300 do
--   queue_command(frame_number+i,{command=memory.writebyte, args={0x020154A7+2,3}})
--   end
-- memory.writeword(P1.base + 0x21A, 22261)
        intro_state = "intro"
      end
    end
    if intro_state == "intro" then
      write_pos(P1, 424, 0)
      write_pos(P2, 200, 0)
      set_screen_pos(512,0)--prolong intro scroll set anim

    end
  end
  if new_character and has_match_just_started then
--     new_character = false
    hadou_matsuri_save_ss()
    hadou_matsuri_start()
  end
-- if frame_number % 100 == 0 then
--   air_hadou()
-- end
-- if frame_number % 200 == 0 then
--   sgs()
-- end
-- if frame_number % 300 == 0 then
--   volley()
-- end
-- full_gauge({P1})
-- full_gauge({P2})
--   if P1.animation_frame_id == 22275 then
--     if P1.animation == "a130"
--     or P1.animation == "a210"
--     or P1.animation == "a2a0" then
--       queue_func(P1, 0, funcs["animation_cancel_air"], {P1})
--     end
--   end
--   if P2.animation_frame_id == 22275 then
--     if P2.animation == "a130"
--     or P2.animation == "a210"
--     or P2.animation == "a2a0" then
--       queue_func(P2, 0, funcs["animation_cancel_air"], {P2})
--     end
--   end
  if P1.animation_frame_id == 22179 then
--     animation_cancel()
--     queue_input_sequence(P1,{{"HP","HK"}})
--     queue_input_sequence(P1,motion_teleport_forward_p)
  end
  --set hp to 0 on hit/block
  if P2.character_state_byte == 1 then
--     memory.writebyte(P2.base + 0x9F, 0x0)
  end

  if P2.pos_y > 0 then
    if P1.pos_x - P2.pos_x > character_specific[P1.char_str].half_width then
      if not(P1.previous_pos_x - P2.previous_pos_x > character_specific[P1.char_str].half_width) then
        --just switched sides
        memory.writebyte(P2.base + 0x0A, 1)
        local _neg_x_vel_char = - P2.velocity_x_char - 1
        local _neg_x_vel_mantissa = 1 - P2.velocity_x_mantissa
--         local _neg_x_accel_char = - P2.acceleration_x_char - 1
--         local _neg_x_accel_mantissa = 1 - P2.acceleration_x_mantissa
        set_velocity_x(P2, _neg_x_vel_char, _neg_x_vel_mantissa)
--         set_acceleration_x({P2, _neg_x_accel_char, _neg_x_accel_mantissa})
      end
    elseif P2.pos_x - P1.pos_x > character_specific[P1.char_str].half_width then
      if not (P2.previous_pos_x - P1.previous_pos_x > character_specific[P1.char_str].half_width) then
        --just switched sides
        memory.writebyte(P2.base + 0x0A, 0)
        local _neg_x_vel_char = - P2.velocity_x_char - 1
        local _neg_x_vel_mantissa = 1 - P2.velocity_x_mantissa
        set_velocity_x(P2, _neg_x_vel_char, _neg_x_vel_mantissa)
      end
    end
--     if P1.pos_y < 25 then
--       _v = math.floor(P1.velocity_y)
--       set_velocity(P1,0,0,_v+4,0)
--     end
  end
  if P2.pos_y >= 500 then
    memory.writeword(P2.base + 0x68, 0)
    set_velocity(P2,0,0,0,0)
  end

  if P1.has_just_parried and P1.parry_forward.success then
    score = score + 1
    print(score)
  end



  for _id, _obj in pairs(projectiles) do
    if bit.tohex(memory.readword(_obj.base + 0x202), 4) ~= "0000" then
      if _obj.emitter_id == 2 then
        if _obj.lifetime == 0 then --new projectile
          if #modify_projectile_queue >= 1 then
            _obj.modify = {}
            _obj.modify.run = modify_projectile_queue[1].func
            _obj.modify.args = {_obj, unpack(modify_projectile_queue[1].args)}
            table.remove(modify_projectile_queue,1)
          end
        end
      end
      if _obj.modify and _obj.modify.run then
        _obj.modify.run(unpack(_obj.modify.args))
      end
      print(_obj.id, _obj.lifetime)
--       if
--       P1_Current_search_adr = _obj.base
--       set_velocity(_obj, 0, 0, 0, 0)
--       set_acceleration(_obj, 0, 0, 0, 0)
--           memory.writeword(_obj.base + 0x202, 0x8ce8) --pyrokinesis
--           memory.writebyte(_obj.base + 0x91, 37)

--       memory.writebyte(_obj.base + 0x0A, 3) -- 0-3. 2&3 flip y
      memory.writeword(_obj.base + 154, 10) --projectile life

--       memory.writebyte(_obj.base + 0x9C + 2, 2) -- # hits
      memory.writedword(_obj.base + 616, debug_color)
      if frame_number % 30 == 0 then

        debug_color = debug_color + 1
      end
      --39 block animation n times
      --70 xvel but not? decreases to 0
      --72 pixelation ?
      --74 shadow opacity

      --564 writable frame
      --616 color --treats flip side differently
      --618 animation 68c2 fiery 6818 6820
      --619 color
--       memory.writeword(_obj.base + 0x202, 0x8ce8)
--       memory.writeword(_obj.base + 0x91, 37)
    end
  end

--   memory.writebyte(P2.base + 0x0A, 2)

--   print(memory.readdword(P1.base - 2))
--   memory.writebyte(0x02068A96 - 1, 106)

  memory.writebyte(0x02068E8D, 0x6F) --p1
  memory.writebyte(0x02069325, 0x6F) --p2


  memory.writebyte(0x02068FB8, 0xFF) --p1
  memory.writebyte(0x02069450, 0xFF) --p2

--   memory.writebyte(P1.parry_forward_validity_time_addr,0x00000008)
--   memory.writebyte(P2.parry_forward_validity_time_addr,0x00000008)

  for _k, _player_obj in pairs(player_objects) do
    memory.writebyte(_player_obj.life_addr, 160)
    if frame_number % 8 == 0 then

      memory.writedword(_player_obj.base + 616, debug_color)
      debugframedatagui("c", string.format("%x", debug_color))

      debug_color=debug_color+1



    end
  end

  if P2.is_being_thrown and not the_end then
    --hit grab bug
--     the_end = true
    clear_command_queue(P2)
    full_gauge(P2)
--     memory.writebyte(P2.parry_forward_validity_time_addr,0x0)
--     memory.writebyte(P2.parry_forward_cooldown_time_addr,0x0)
    queue_input(P2, 0, {{"LP","LK"}})
--     queue_func(P2, 10, funcs["set_acceleration"], {P2, 4, 0})
    queue_func(P2, 30, {func=set_velocity_x, args={P2, 13, 0}})
--     queue_func(P2, 20, funcs["animation_cancel"], {P2})
--     queue_input(P2, 20, {{"HP","HK"}})
--     queue_func(P2, 4, funcs["animation_cancel"], {P2})
--     queue_input(P2, 12, {{"forward","forward"}})
    queue_input(P2, 32, motion_sgs) --31
    queue_func(P1, 20, {func=freeze,args={P1, 10}})

  end
-- memory.writeword(0x02026CB0, 771) --lock screen pos
process_command_queue(P1, joypad.get())
process_command_queue(P2, joypad.get())

-- screen_x = memory.readwordsigned(0x02026CB0)
-- screen_y = memory.readwordsigned(0x02026CB4)
-- b ={}
-- a = {}
-- b.mod = {}
-- b.mod.run = 5
-- c = {1,2,3}
-- d= {12, unpack(c)}
--   print(d)

end

function debug_hadou_gui()
for _id, _obj in pairs(projectiles) do
  if bit.tohex(memory.readword(_obj.base + 0x202), 4) ~= "0000" then
    if _obj.emitter_id == 2 then
      gui.text(textx+98,texty-4, string.format("Proj Vel: %d, %d", _obj.velocity_x, _obj.velocity_y))
    end
  end
end
end
