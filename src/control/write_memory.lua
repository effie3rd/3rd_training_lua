local memory_addresses = require("src.control.memory_addresses")

local function write_pos_x(obj, x)
  local x_char = math.floor(x)
  local x_mantissa = float_to_byte(x)
  memory.writeword(obj.base + 0x64, x_char)
  memory.writebyte(obj.base + 0x66, x_mantissa)
  obj.pos_x = x
  obj.pos_x_char = x_char
  obj.pos_x_mantissa = x_mantissa
end

local function write_pos_y(obj, y)
  local y_char = math.floor(y)
  local y_mantissa = float_to_byte(y)
  memory.writeword(obj.base + 0x68, y_char)
  memory.writebyte(obj.base + 0x6A, y_mantissa)
  obj.pos_y = y
  obj.pos_y_char = y_char
  obj.pos_y_mantissa = y_mantissa
end

local function write_pos(obj, x, y)
  write_pos_x(obj, x)
  write_pos_y(obj, y)
end

local function write_velocity_x(obj, x)
  local x_char = math.floor(x)
  local x_mantissa = float_to_byte(x)
  memory.writeword(obj.base + 0x64 + 24, x_char)
  memory.writebyte(obj.base + 0x64 + 26, x_mantissa)
  obj.velocity_x = x
  obj.velocity_x_char = x_char
  obj.velocity_x_mantissa = x_mantissa
end

local function write_velocity_y(obj, y)
  local y_char = math.floor(y)
  local y_mantissa = float_to_byte(y)
  memory.writeword(obj.base + 0x64 + 28, y_char)
  memory.writebyte(obj.base + 0x64 + 30, y_mantissa)
  obj.velocity_y = y
  obj.velocity_y_char = y_char
  obj.velocity_y_mantissa = y_mantissa
end

local function write_velocity(obj, x, y)
  write_velocity_x(obj, x)
  write_velocity_y(obj, y)
end

local function clear_motion_data(obj)
  memory.writeword(obj.base + 0x64 + 24, 0)
  memory.writebyte(obj.base + 0x64 + 26, 0)
  memory.writeword(obj.base + 0x64 + 28, 0)
  memory.writebyte(obj.base + 0x64 + 30, 0)
  memory.writeword(obj.base + 0x64 + 32, 0)
  memory.writebyte(obj.base + 0x64 + 34, 0)
  memory.writeword(obj.base + 0x64 + 36, 0)
  memory.writebyte(obj.base + 0x64 + 38, 0)

  obj.velocity_x_char = 0
  obj.velocity_x_mantissa = 0
  obj.velocity_y_char = 0
  obj.velocity_y_mantissa = 0
  obj.acceleration_x_char = 0
  obj.acceleration_x_mantissa = 0
  obj.acceleration_y_char = 0
  obj.acceleration_y_mantissa = 0

  obj.velocity_x = 0
  obj.velocity_y = 0

  obj.acceleration_x = 0
  obj.acceleration_y = 0
end

local function fix_screen_pos(p1, p2)
  local left = math.min(p1.pos_x, p2.pos_x) - 50
  local right = math.max(p1.pos_x, p2.pos_x) + 50
  local mid = math.floor((left + right) / 2)
  local top = math.max(p1.pos_y, p2.pos_y)
  memory.writeword(0x02026CB0, math.min(math.max(mid, 272), 748))
--   memory.writeword(0x02026CB0, 0) screenwrap
  memory.writeword(0x02026CB4, math.max(math.max(p1.pos_y - 40, 0), 0))
end

local function set_screen_pos(x, y)
  memory.writeword(0x02026CB0, x)
--   memory.writeword(0x02026CB0, 0) screenwrap
  memory.writeword(0x02026CB4, y)
end

local function make_invulnerable(obj, yes)
  if yes then
    memory.writebyte(obj.base + 7, 0)
  else
    memory.writebyte(obj.base + 7, 1)
  end
end

local function set_freeze(obj, v)
  memory.writebyte(obj.base + 0x45, v)
end

local function enable_cheat_parrying(player)
  memory.writebyte(player.addresses.parry_forward_validity_time, 0xA)
  memory.writebyte(player.addresses.parry_down_validity_time, 0xA)
  memory.writebyte(player.addresses.parry_air_validity_time, 0x7)
  memory.writebyte(player.addresses.parry_antiair_validity_time, 0x5)
end

local function disable_cheat_parrying(player)
  memory.writebyte(player.addresses.parry_forward_validity_time, 0x0)
  memory.writebyte(player.addresses.parry_down_validity_time, 0x0)
  memory.writebyte(player.addresses.parry_air_validity_time, 0x0)
  memory.writebyte(player.addresses.parry_antiair_validity_time, 0x0)
end

local function reset_parry_cooldowns(player)
  memory.writebyte(player.addresses.parry_forward_cooldown_time, 0)
  memory.writebyte(player.addresses.parry_down_cooldown_time, 0)
  memory.writebyte(player.addresses.parry_air_cooldown_time, 0)
  memory.writebyte(player.addresses.parry_antiair_cooldown_time, 0)
end

local function set_freeze_game(yes)
  if yes then
    memory.writebyte(memory_addresses.global.freeze_game, 0xFF)
  else
    memory.writebyte(memory_addresses.global.freeze_game, 0x00)
  end
end

local function set_infinite_time(yes)
  if yes then
    memory.writebyte(memory_addresses.global.match_timer, 100)
  end
end

local function set_music_volume(num)
  memory.writebyte(memory_addresses.global.music_volume, num * 8)
end

return {
  write_pos_x = write_pos_x,
  write_pos_y = write_pos_y,
  write_pos = write_pos,
  write_velocity_x = write_velocity_x,
  write_velocity_y =write_velocity_y,
  write_velocity = write_velocity,
  clear_motion_data = clear_motion_data,
  fix_screen_pos = fix_screen_pos,
  set_screen_pos = set_screen_pos,
  make_invulnerable = make_invulnerable,
  set_freeze = set_freeze,
  enable_cheat_parrying = enable_cheat_parrying,
  disable_cheat_parrying = disable_cheat_parrying,
  reset_parry_cooldowns = reset_parry_cooldowns,
  set_freeze_game = set_freeze_game,
  set_infinite_time = set_infinite_time,
  set_music_volume = set_music_volume
}