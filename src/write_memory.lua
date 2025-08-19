function write_pos(_obj, _x, _y)
  write_pos_x(_obj, _x)
  write_pos_y(_obj, _y)
end

function write_pos_x(_obj, _x)
  local _x_char = math.floor(_x)
  local _x_mantissa = float_to_byte(_x)
  memory.writeword(_obj.base + 0x64, _x_char)
  memory.writebyte(_obj.base + 0x66, _x_mantissa)
  _obj.pos_x = _x
  _obj.pos_x_char = _x_char
  _obj.pos_x_mantissa = _x_mantissa
end

function write_pos_y(_obj, _y)
  local _y_char = math.floor(_y)
  local _y_mantissa = float_to_byte(_y)
  memory.writeword(_obj.base + 0x68, _y_char)
  memory.writebyte(_obj.base + 0x6A, _y_mantissa)
  _obj.pos_y = _y
  _obj.pos_y_char = _y_char
  _obj.pos_y_mantissa = _y_mantissa
end

function write_velocity(_obj, _x, _y)
  write_velocity_x(_obj, _x)
  write_velocity_y(_obj, _y)
end

function write_velocity_x(_obj, _x)
  local _x_char = math.floor(_x)
  local _x_mantissa = float_to_byte(_x)
  memory.writeword(_obj.base + 0x64 + 24, _x_char)
  memory.writebyte(_obj.base + 0x64 + 26, _x_mantissa)
  _obj.velocity_x = _x
  _obj.velocity_x_char = _x_char
  _obj.velocity_x_mantissa = _x_mantissa
end

function write_velocity_y(_obj, _y)
  local _y_char = math.floor(_y)
  local _y_mantissa = float_to_byte(_y)
  memory.writeword(_obj.base + 0x64 + 28, _y_char)
  memory.writebyte(_obj.base + 0x64 + 30, _y_mantissa)
  _obj.velocity_y = _y
  _obj.velocity_y_char = _y_char
  _obj.velocity_y_mantissa = _y_mantissa
end

function clear_motion_data(_obj)
  memory.writeword(_obj.base + 0x64 + 24, 0)
  memory.writebyte(_obj.base + 0x64 + 26, 0)
  memory.writeword(_obj.base + 0x64 + 28, 0)
  memory.writebyte(_obj.base + 0x64 + 30, 0)
  memory.writeword(_obj.base + 0x64 + 32, 0)
  memory.writebyte(_obj.base + 0x64 + 34, 0)
  memory.writeword(_obj.base + 0x64 + 36, 0)
  memory.writebyte(_obj.base + 0x64 + 38, 0)

  _obj.velocity_x_char = 0
  _obj.velocity_x_mantissa = 0
  _obj.velocity_y_char = 0
  _obj.velocity_y_mantissa = 0
  _obj.acceleration_x_char = 0
  _obj.acceleration_x_mantissa = 0
  _obj.acceleration_y_char = 0
  _obj.acceleration_y_mantissa = 0

  _obj.velocity_x = 0
  _obj.velocity_y = 0

  _obj.acceleration_x = 0
  _obj.acceleration_y = 0
end

function fix_screen_pos(_p1, _p2)
  local _left = math.min(_p1.pos_x, _p2.pos_x) - 50
  local _right = math.max(_p1.pos_x, _p2.pos_x) + 50
  local _mid = math.floor((_left + _right) / 2)
  local _top = math.max(_p1.pos_y, _p2.pos_y)
  memory.writeword(0x02026CB0, math.min(math.max(_mid, 272), 748))
--   memory.writeword(0x02026CB0, 0) screenwrap
  memory.writeword(0x02026CB4, math.max(math.max(_p1.pos_y - 40, 0), 0))
end

function set_screen_pos(_x, _y)
  memory.writeword(0x02026CB0, _x)
--   memory.writeword(0x02026CB0, 0) screenwrap
  memory.writeword(0x02026CB4, _y)
end

function make_invulnerable(_obj, _yes)
  if _yes then
    memory.writebyte(_obj.base + 7, 0)
  else
    memory.writebyte(_obj.base + 7, 1)
  end
end

function set_freeze(_obj, _v)
  memory.writebyte(_obj.base + 0x45, _v)
end