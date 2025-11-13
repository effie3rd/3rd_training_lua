---@diagnostic disable: lowercase-global, undefined-global
local fd = require("src.modules.framedata")
local fdm = require("src.modules.framedata_meta")
local draw = require("src.ui.draw")
local menu = require("src.ui.menu")
local gamestate = require("src.gamestate")
local character_select = require("src.control.character_select")


hadou_matsuri_savestate = savestate.create("data/"..game_data.rom_name.."/savestates/hadou_matsuri.fs")

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


function sgs()
  clear_input(gamestate.P1)
  queue_input(gamestate.P1, 0, motion_sgs)
  queue_func(gamestate.P1, #motion_sgs-2, {func=full_gauge, args={player}})
end

function overlap_hadou(obj, distance, speed, n)
  if obj.lifetime < speed then
    velx = (air_hadou_startup * n * base_lp_air_hadou_vel_x - distance) / speed
    vely = -1 * (air_hadou_startup * n* -1 * base_lp_air_hadou_vel_y - distance) / speed
    write_velocity_x(obj, velx, 0)
    write_velocity_y(obj, vely, 0)
  else
    write_velocity_x(obj, base_lp_air_hadou_vel_x, 0)
    write_velocity_y(obj, base_lp_air_hadou_vel_y, 0)
  end
end


--save state first
  is_in_challenge = true
  Register_After_Load_State(function() new_character=true end)
  Register_After_Load_State(character_select.force_select_character, {1, "urien", 2, "HK"})
  Register_After_Load_State(character_select.force_select_character, {2, "shingouki", 1, "HK"})

  character_select.start_character_select_sequence(true)

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

if gamestate.P1.has_just_parried and gamestate.P1.parry_forward.success then
  score = score + 1
end

if gamestate.P2.is_being_thrown and not the_end then
  clear_command_queue(gamestate.P2)
  full_gauge(gamestate.P2)
  queue_input(gamestate.P2, 0, {{"LP","LK"}})

  queue_func(gamestate.P2, 30, {func=write_velocity_x, args={gamestate.P2, 13, 0}})
      queue_input(gamestate.P2, 32, motion_sgs) --31
  queue_func(gamestate.P1, 20, {func=freeze,args={gamestate.P1, 10}})
end