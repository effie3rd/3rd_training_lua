---@diagnostic disable: lowercase-global, undefined-global
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local draw = require("src.ui.draw")
local menu = require("src.ui.menu")
local gamestate = require("src.gamestate")
local character_select = require("src.control.character_select")

local frame_data, character_specific = fd.frame_data, fd.character_specific
local frame_data_meta = fdm.frame_data_meta

hadou_matsuri_savestate = savestate.create("data/"..rom_name.."/savestates/hadou_matsuri.fs")


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

function get_player_bounds(obj)
  local result = {}
  result.left = obj.pos_x
  result.right = obj.pos_x
  result.bottom = obj.pos_y
  result.top = obj.pos_y
  for _, box in pairs(obj.boxes) do
    if box.type == "vulnerability" then
      local right = box.left + box.width
      local top = box.bottom + box.height
      if box.left < result.left then
        result.left = box.left
      end
      if right > result.right then
        result.right = right
      end
      if box.bottom < result.bottom then
        result.bottom = box.bottom
      end
      if top > result.top then
        result.top = top
      end
    end
  end
  return result
end

--Anim: 8af8 Frame Id: 22179  3  60

function freeze(obj, t)
  memory.writebyte(obj.base + 0x45, t)
end

function unfreeze(player)
    memory.writebyte(player.base + 0x45, 0) --allow p2 to move during super freeze
end

function animation_cancel(args)
  local player = args[1]
--  memory.writebyte(gamestate.P1.addresses.life, 0x0) --p1 life
--   memory.writebyte(gamestate.P2.addresses.life, 0x0) --p2 life
  memory.writebyte(player.base + 0x27, 0x0)
  memory.writeword(player.base + 0x202, 0x8800) --idle
  memory.writeword(player.base + 0x21A, 22177)
  memory.writeword(player.base + 0x214, 1) --frameid2
  memory.writeword(player.base + 0x205, 1) --frameid3

  memory.writeword(player.base + 0x3D1, 0x0)
  memory.writeword(player.base + 0xAC, 0)
  memory.writeword(player.base + 0x12C, 0)
end

function animation_cancel_air(args)
  local player = args[1]
  memory.writebyte(player.base + 0x27, 0x0)
  memory.writeword(player.base + 0x202, 0xa130) --idle
  memory.writeword(player.base + 0x21A, 22274)
  memory.writeword(player.base + 0x214, 3) --frameid2
  memory.writeword(player.base + 0x205, 36) --frameid3

  memory.writeword(player.base + 0x3D1, 0x0)
  memory.writeword(player.base + 0xAC, 0)
  memory.writeword(player.base + 0x12C, 0)
end

function queue_input(player, delay, input_sequence)
  for i = 1, #input_sequence do
    local frame = gamestate.frame_number + i - 1 + delay

    if player.command_queue[frame] and player.command_queue[frame].input then
      table.insert(player.command_queue[frame].input, input_sequence[i])
    else
      player.command_queue[frame] = {}
      player.command_queue[frame].input = input_sequence[i]
    end
  end
--   low = 9999990
--   high = 1
--   for f, val in pairs(player.command_queue) do
--     if f <low then
--       low = f
--       end
--     if f >high then
--       high= f
--       end
--   end
--   for i=low,high do
--     if(player.command_queue[i]) then
--       if player.command_queue[i].input then
--         print(i, unpack(player.command_queue[i].input))
--       else
--         print(i, unpack(player.command_queue[i]))
--       end
--     end
--   end
--   print("-=-=-")

end

function clear_command_queue(player)
  player.command_queue = {}
end

function queue_func(player, delay, com)
  local frame = gamestate.frame_number + delay
  if player.command_queue[frame] then
    if player.command_queue[frame].command then
      table.insert(player.command_queue[frame].command, com)
    else
      player.command_queue[frame].command = {com}
    end
  else
    player.command_queue[frame] = {}
    player.command_queue[frame].command = {com}
  end
end

function queue_modify_projectile(player, delay, com)
  local frame = gamestate.frame_number + delay
  if player.command_queue[frame] then
    if player.command_queue[frame].modify then
      table.insert(player.command_queue[frame].modify, {func=insert_modify_projectile, args=com})
    else
      player.command_queue[frame].modify = {{func=insert_modify_projectile, args=com}}
    end
  else
    player.command_queue[frame] = {}
    player.command_queue[frame].modify = {{func=insert_modify_projectile, args=com}}
  end
end

function insert_modify_projectile(com)
  table.insert(modify_projectile_queue, com)
end

hm_input = {}

function process_command_queue(player, input)

  hm_input = {}

  if player.command_queue == nil then
    return
  end
  if menu.is_open then
    return
  end
  if not gamestate.is_in_match then
    return
  end

  local gauges_base = 0
  if player.id == 1 then
  gauges_base = 0x020259D8
  elseif player.id == 2 then
  gauges_base = 0x02025FF8
  end
  local gauges_offsets = { 0x0, 0x1C, 0x38, 0x54, 0x70 }
  if player.command_queue[gamestate.frame_number] then
    -- Cancel all input
    input[player.prefix.." Up"] = false
    input[player.prefix.." Down"] = false
    input[player.prefix.." Left"] = false
    input[player.prefix.." Right"] = false
    input[player.prefix.." Weak Punch"] = false
    input[player.prefix.." Medium Punch"] = false
    input[player.prefix.." Strong Punch"] = false
    input[player.prefix.." Weak Kick"] = false
    input[player.prefix.." Medium Kick"] = false
    input[player.prefix.." Strong Kick"] = false

    for key, command in pairs(player.command_queue[gamestate.frame_number]) do

      if key == "command" then
        for _, c in pairs(command) do
          c.func(unpack(c.args))
        end
      elseif key == "modify" then
        for _, c in pairs(command) do
          c.func(c.args)
        end
      elseif key == "input" then
        local current_frame_input = command
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
              memory.writeword(gauges_base + gauges_offsets[1], 0xFFFF)
            elseif player.char_str == "oro" then
              memory.writeword(gauges_base + gauges_offsets[3], 0xFFFF)
            elseif player.char_str == "chunli" then
            elseif player.char_str == "q" then
              memory.writeword(gauges_base + gauges_offsets[1], 0xFFFF)
              memory.writeword(gauges_base + gauges_offsets[2], 0xFFFF)
            elseif player.char_str == "remy" then
              memory.writeword(gauges_base + gauges_offsets[2], 0xFFFF)
              memory.writeword(gauges_base + gauges_offsets[3], 0xFFFF)
            elseif player.char_str == "alex" then
              memory.writeword(gauges_base + gauges_offsets[5], 0xFFFF)
            end
            elseif current_frame_input[i] == "v_charge" then
              if player.char_str == "urien" then
                memory.writeword(gauges_base + gauges_offsets[2], 0xFFFF)
                memory.writeword(gauges_base + gauges_offsets[4], 0xFFFF)
              elseif player.char_str == "oro" then
                memory.writeword(gauges_base + gauges_offsets[1], 0xFFFF)
              elseif player.char_str == "chunli" then
                memory.writeword(gauges_base + gauges_offsets[1], 0xFFFF)
              elseif player.char_str == "q" then
              elseif player.char_str == "remy" then
                memory.writeword(gauges_base + gauges_offsets[1], 0xFFFF)
              elseif player.char_str == "alex" then
                memory.writeword(gauges_base + gauges_offsets[4], 0xFFFF)
              end
            end
        input[input_name] = true
        end
      end
    end
    end
    player.command_queue[gamestate.frame_number] = nil
    joypad.set(input)
    hm_input = input
end

function zero_gauge(player)
  memory.writebyte(player.addresses.gauge, 0)
  memory.writebyte(player.addresses.meter_master, 0)
--   memory.writebyte(player.addresses.meter_update_flag, 0x01)
end

function full_gauge(player)
  memory.writebyte(player.addresses.gauge, player.max_meter_gauge)
  memory.writebyte(player.addresses.meter_master, player.max_meter_count)
  memory.writebyte(player.addresses.meter_update_flag, 0x01)
end


function air_hadou()
  queue_input(gamestate.P1, 0, motion_hadou_lp)
  -- queue_func(gamestate.P1, 2, funcs["zero_gauge"], {gamestate.P1})
end

function sgs()
  clear_input(gamestate.P1)
  queue_input(gamestate.P1, 0, motion_sgs)
  queue_func(gamestate.P1, #motion_sgs-2, {func=full_gauge, args={player}})
end

function overlap_hadou(obj, distance, speed, n)
  if obj.lifetime < speed then
    print("mod")
    velx = (air_hadou_startup * n * base_lp_air_hadou_vel_x - distance) / speed
    vely = -1 * (air_hadou_startup * n* -1 * base_lp_air_hadou_vel_y - distance) / speed
    write_velocity_x(obj, velx, 0)
    write_velocity_y(obj, vely, 0)
  else
    write_velocity_x(obj, base_lp_air_hadou_vel_x, 0)
    write_velocity_y(obj, base_lp_air_hadou_vel_y, 0)
  end
end

function bounce_hadou(obj)

end

function queue_volley(player, delay, n, speed, version)
  speed = math.max(speed, air_hadou_startup + animation_cancel_delay)
  for i = 0, n - 1 do
    if version == "LP" then
      queue_input(player, delay + i * speed + 1, motion_hadou_lp)
      queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=zero_gauge, args={player}})
    elseif version == "HP" then
      queue_input(player, delay + i * speed + 1, motion_hadou_hp)
      queue_func(player, delay + i * speed + 1 + #motion_hadou_hp - 1, {func=zero_gauge, args={player}})
    elseif version == "alternate" then
      if i % 2 == 0 then
        queue_input(player, delay + i * speed + 1, motion_hadou_lp)
        queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=zero_gauge, args={player}})
      else
        queue_input(player, delay + i * speed + 1, motion_hadou_hp)
        queue_func(player, delay + i * speed + 1 + #motion_hadou_hp - 1, {func=zero_gauge, args={player}})
      end
    elseif version == "overlap" then
      queue_input(player, delay + i * speed + 1, motion_hadou_lp)
      queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=zero_gauge, args={player}})
      if i ~= 0 then
        queue_modify_projectile(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=overlap_hadou, args={4,2,i}})
      end
    end


    queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=write_velocity_x, args={player, 0, 0}})
    queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=write_velocity_y, args={player, 0, 0}})
    queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=write_acceleration_x, args={player, 0, 0}})
    if i < n - 1 then
      queue_func(player, delay + i * speed + 1 + #motion_hadou_lp - 1, {func=write_acceleration_y, args={player, 0, 0}})
    else
      queue_func(player, delay + (i + 1) * speed + 1 + #motion_hadou_lp - 1, {func=write_velocity_x, args={player, 8, 0}})
      queue_func(player, delay + (i + 1) * speed + 1 + #motion_hadou_lp - 1, {func=write_velocity_y, args={player, 10, 0}})
      queue_func(player, delay + (i + 1) * speed + 1 + #motion_hadou_lp - 1, {func=write_acceleration_y, args={player, base_gravity, base_gravity_mantissa}})
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
--homing red fireball y
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

--check if gamestate.P2 is cornered

--gamestate.P2 base movespeed forward 3 3 4 backwards 2 3

--set gauges and hp
-- memory.writebyte(player.addresses.gauge, gauge_value)
-- memory.writebyte(player.addresses.meter_master, player.max_meter_count)
-- memory.writebyte(player.addresses.meter_update_flag, 0x01)

--air parry increases y by 1

--color code different hadou attacks

--super that bounces on screen edge

--very slow then after a while accelerate

--fix hitboxes on flip looks like just a y flip

-- draw.SCREEN_WIDTH = 383
-- draw.SCREEN_HEIGHT = 223
-- draw.GROUND_OFFSET = 23


function flip_box(obj, ptr, type)
  if obj.friends > 1 then --Yang SA3
    if type ~= "attack" then
      return
    end
  end
--   if box.type
  local bottom = memory.readwordsigned(ptr + 0x4)
  local height = memory.readwordsigned(ptr + 0x6)

  memory.writeword(ptr + 0x4, bottom-30)
  memory.writeword(ptr + 0x6, -height)

end

function flippy(obj)
--   if memory.readdword(obj.base + 0x2A0) == 0 then --invalid objects
--     return false
--   end

  local boxes = {
    {initial = 1, offset = 0x2D4, type = "push", number = 1},
    {initial = 1, offset = 0x2C0, type = "throwable", number = 1},
    {initial = 1, offset = 0x2A0, type = "vulnerability", number = 4},
    {initial = 1, offset = 0x2A8, type = "ext. vulnerability", number = 4},
    {initial = 1, offset = 0x2C8, type = "attack", number = 4},
    {initial = 1, offset = 0x2B8, type = "throw", number = 1}
    }

  for _, box in ipairs(boxes) do
    for i = box.initial, box.number do
      flip_box(obj, memory.readdword(obj.base + box.offset) + (i-1)*8, box.type)
    end
  end
  return true
end


function debug_challenge()
--   queue_input(gamestate.P1, 1, motion_hadou_lp)
   queue_input(gamestate.P2, 1, {{"down"},{"up","forward"},{"up","forward"}})
   queue_volley(gamestate.P2, 12, 3, 0, "overlap")
   queue_volley(gamestate.P2, 92, 3, 0, "overlap")

  --initial_search()

end

function hadou_matsuri_save_ss()
  hadou_matsuri_savestate = savestate.create("data/"..rom_name.."/savestates/hadou_matsuri.fs")
  full_gauge(gamestate.P2)
  zero_gauge(gamestate.P1)
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
  Register_After_Load_State(function() new_character=true end)
  Register_After_Load_State(character_select.force_select_character, {1, "urien", 2, "HK"})
  Register_After_Load_State(character_select.force_select_character, {2, "shingouki", 1, "HK"})

  character_select.start_character_select_sequence(true)

end

function hadou_matsuri_start()
  score = 0

  is_in_challenge = true
--   hadou_matsuri_load_ss()

  gamestate.P1.command_queue = {}
  gamestate.P2.command_queue = {}


  full_gauge(gamestate.P2)
  zero_gauge(gamestate.P1)
--   flippy(gamestate.P1)

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
--   Queue_Command(gamestate.frame_number+i,{command=memory.writebyte, args={0x020154A7+2,3}})
--   end
-- memory.writeword(gamestate.P1.base + 0x21A, 22261)
        intro_state = "intro"
      end
    end
    if intro_state == "intro" then
      write_pos(gamestate.P1, 424, 0)
      write_pos(gamestate.P2, 200, 0)
      set_screen_pos(512,0)--prolong intro scroll set anim

    end
  end
  if new_character and gamestate.has_match_just_started then
--     new_character = false
    hadou_matsuri_save_ss()
    hadou_matsuri_start()
  end
-- if gamestate.frame_number % 100 == 0 then
--   air_hadou()
-- end
-- if gamestate.frame_number % 200 == 0 then
--   sgs()
-- end
-- if gamestate.frame_number % 300 == 0 then
--   volley()
-- end
-- full_gauge({gamestate.P1})
-- full_gauge({gamestate.P2})
--   if gamestate.P1.animation_frame_id == 22275 then
--     if gamestate.P1.animation == "a130"
--     or gamestate.P1.animation == "a210"
--     or gamestate.P1.animation == "a2a0" then
--       queue_func(gamestate.P1, 0, funcs["animation_cancel_air"], {gamestate.P1})
--     end
--   end
--   if gamestate.P2.animation_frame_id == 22275 then
--     if gamestate.P2.animation == "a130"
--     or gamestate.P2.animation == "a210"
--     or gamestate.P2.animation == "a2a0" then
--       queue_func(gamestate.P2, 0, funcs["animation_cancel_air"], {gamestate.P2})
--     end
--   end
  if gamestate.P1.animation_frame_id == 22179 then
--     animation_cancel()
--     inputs.queue_input_sequence(gamestate.P1,{{"HP","HK"}})
--     inputs.queue_input_sequence(gamestate.P1,motion_teleport_forward_p)
  end
  --set hp to 0 on hit/block
  if gamestate.P2.character_state_byte == 1 then
--     memory.writebyte(gamestate.P2.base + 0x9F, 0x0)
  end

  if gamestate.P2.pos_y > 0 then
    if gamestate.P1.pos_x - gamestate.P2.pos_x > character_specific[gamestate.P1.char_str].half_width then
      if not(gamestate.P1.previous_pos_x - gamestate.P2.previous_pos_x > character_specific[gamestate.P1.char_str].half_width) then
        --just switched sides
        memory.writebyte(gamestate.P2.base + 0x0A, 1)
        local neg_x_vel_char = - gamestate.P2.velocity_x_char - 1
        local neg_x_vel_mantissa = 1 - gamestate.P2.velocity_x_mantissa
--         local neg_x_accel_char = - gamestate.P2.acceleration_x_char - 1
--         local neg_x_accel_mantissa = 1 - gamestate.P2.acceleration_x_mantissa
        -- write_velocity_x(gamestate.P2, neg_x_vel_char, neg_x_vel_mantissa)
--         write_acceleration_x({gamestate.P2, neg_x_accel_char, neg_x_accel_mantissa})
      end
    elseif gamestate.P2.pos_x - gamestate.P1.pos_x > character_specific[gamestate.P1.char_str].half_width then
      if not (gamestate.P2.previous_pos_x - gamestate.P1.previous_pos_x > character_specific[gamestate.P1.char_str].half_width) then
        --just switched sides
        memory.writebyte(gamestate.P2.base + 0x0A, 0)
        local neg_x_vel_char = - gamestate.P2.velocity_x_char - 1
        local neg_x_vel_mantissa = 1 - gamestate.P2.velocity_x_mantissa
        -- write_velocity_x(gamestate.P2, neg_x_vel_char, neg_x_vel_mantissa)
      end
    end
--     if gamestate.P1.pos_y < 25 then
--       v = math.floor(gamestate.P1.velocity_y)
--       write_velocity(gamestate.P1,0,0,v+4,0)
--     end
  end
  if gamestate.P2.pos_y >= 500 then
    memory.writeword(gamestate.P2.base + 0x68, 0)
    write_velocity(gamestate.P2,0,0)
  end

  if gamestate.P1.has_just_parried and gamestate.P1.parry_forward.success then
    score = score + 1
    print(score)
  end



  for _, obj in pairs(gamestate.projectiles) do
    if bit.tohex(memory.readword(obj.base + 0x202), 4) ~= "0000" then
      if obj.emitter_id == 2 then
        if obj.lifetime == 0 then --new projectile
          if #modify_projectile_queue >= 1 then
            obj.modify = {}
            obj.modify.run = modify_projectile_queue[1].func
            obj.modify.args = {obj, unpack(modify_projectile_queue[1].args)}
            table.remove(modify_projectile_queue,1)
          end
        end
      end
      if obj.modify and obj.modify.run then
        obj.modify.run(unpack(obj.modify.args))
      end
      print(obj.id, obj.lifetime)
--       if
--       gamestate.P1_Current_search_adr = obj.base
--       write_velocity(obj, 0, 0, 0, 0)
--       set_acceleration(obj, 0, 0, 0, 0)
--           memory.writeword(obj.base + 0x202, 0x8ce8) --pyrokinesis
--           memory.writebyte(obj.base + 0x91, 37)

--       memory.writebyte(obj.base + 0x0A, 3) -- 0-3. 2&3 flip y
      memory.writeword(obj.base + 154, 10) --projectile life

--       memory.writebyte(obj.base + 0x9C + 2, 2) -- # hits
      memory.writedword(obj.base + 616, debug_color)
      if gamestate.frame_number % 30 == 0 then

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
--       memory.writeword(obj.base + 0x202, 0x8ce8)
--       memory.writeword(obj.base + 0x91, 37)
    end
  end

--   memory.writebyte(gamestate.P2.base + 0x0A, 2)

--   print(memory.readdword(gamestate.P1.base - 2))
--   memory.writebyte(0x02068A96 - 1, 106)

  memory.writebyte(0x02068E8D, 0x6F) --p1
  memory.writebyte(0x02069325, 0x6F) --p2


  memory.writebyte(0x02068FB8, 0xFF) --p1
  memory.writebyte(0x02069450, 0xFF) --p2

--   memory.writebyte(gamestate.P1.addresses.parry_forward_validity_time,0x00000008)
--   memory.writebyte(gamestate.P2.addresses.parry_forward_validity_time,0x00000008)

  for _, player in pairs(gamestate.player_objects) do
    memory.writebyte(player.addresses.life, 160)
    if gamestate.frame_number % 8 == 0 then

      memory.writedword(player.base + 616, debug_color)
      debugframedatagui("c", string.format("%x", debug_color))

      debug_color=debug_color+1



    end
  end

  if gamestate.P2.is_being_thrown and not the_end then
    --hit grab bug
--     the_end = true
    clear_command_queue(gamestate.P2)
    full_gauge(gamestate.P2)
--     memory.writebyte(gamestate.P2.addresses.parry_forward_validity_time,0x0)
--     memory.writebyte(gamestate.P2.addresses.parry_forward_cooldown_time,0x0)
    queue_input(gamestate.P2, 0, {{"LP","LK"}})
--     queue_func(gamestate.P2, 10, funcs["set_acceleration"], {gamestate.P2, 4, 0})
    queue_func(gamestate.P2, 30, {func=write_velocity_x, args={gamestate.P2, 13, 0}})
--     queue_func(gamestate.P2, 20, funcs["animation_cancel"], {gamestate.P2})
--     queue_input(gamestate.P2, 20, {{"HP","HK"}})
--     queue_func(gamestate.P2, 4, funcs["animation_cancel"], {gamestate.P2})
--     queue_input(gamestate.P2, 12, {{"forward","forward"}})
    queue_input(gamestate.P2, 32, motion_sgs) --31
    queue_func(gamestate.P1, 20, {func=freeze,args={gamestate.P1, 10}})

  end
-- memory.writeword(0x02026CB0, 771) --lock screen pos
process_command_queue(gamestate.P1, joypad.get())
process_command_queue(gamestate.P2, joypad.get())

-- draw.screen_x = memory.readwordsigned(0x02026CB0)
-- draw.screen_y = memory.readwordsigned(0x02026CB4)
-- b ={}
-- a = {}
-- b.mod = {}
-- b.mod.run = 5
-- c = {1,2,3}
-- d= {12, unpack(c)}
--   print(d)

end