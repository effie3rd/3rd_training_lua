local json = require("src.libs.dkjson")
local debug_settings = require("src.debug_settings")


local assert_enabled = debug_settings.developer_mode
function t_assert(condition, msg)
  msg = msg or "Assertion failed"
  if assert_enabled and not condition then
    error(msg, 2)
  end
end

function math.round(n)
  return math.floor(n+0.5)
end

function sign(n)
  return n > 0 and 1 or (n == 0 and 0 or -1)
end

function flip_to_sign(flip_x)
  return flip_x == 0 and -1 or (flip_x == 1 and 1)
end

function bool_xor(a, b)
  return (a or b) and not (a and b)
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function string_hash(str)
	if #str == 0 then
		return 0
  end

  local dJB2_INIT = 5381;
	local hash = dJB2_INIT
  for i = 1, #str do
    local c = string.byte(str,i)
    hash = bit.lshift(hash, 5) + hash + c
  end
	return hash
end

function string_to_color(str)
  local HRange = { 0.0, 360.0 }
	local sRange = { 0.8, 1.0 }
	local lRange = { 0.7, 1.0 }

	local HAmplitude = HRange[2] - HRange[1];
	local sAmplitude = sRange[2] - sRange[1];
	local lAmplitude = lRange[2] - lRange[1];

  local hash = string_hash(str)

  local HI = bit.rshift(bit.band(hash, 0xFF000000), 24)
  local sI = bit.rshift(bit.band(hash, 0x00FF0000), 16)
	local lI = bit.rshift(bit.band(hash, 0x0000FF00), 8)
	local base = bit.lshift(1, 8)

	local h = HRange[1] + (HI / base) * HAmplitude;
	local s = sRange[1] + (sI / base) * sAmplitude;
	local l = lRange[1] + (lI / base) * lAmplitude;

	local HDiv60 = h / 60.0
	local HDiv60_Floor = math.floor(HDiv60);
	local HDiv60_Fraction = HDiv60 - HDiv60_Floor;

	local rGBValues = {
		l,
		l * (1.0 - s),
		l * (1.0 - (HDiv60_Fraction * s)),
		l * (1.0 - ((1.0 - HDiv60_Fraction) * s))
	}

	local rGBSwizzle = {
		{1, 4, 2},
		{3, 1, 2},
		{2, 1, 4},
		{2, 3, 1},
		{4, 2, 1},
		{1, 2, 3},
	}
	local swizzleIndex = (HDiv60_Floor % 6) + 1
  local r = rGBValues[rGBSwizzle[swizzleIndex][1]]
  local g = rGBValues[rGBSwizzle[swizzleIndex][2]]
  local b = rGBValues[rGBSwizzle[swizzleIndex][3]]

  --print(string.format("H:%.1f, S:%.1f, L:%.1f | R:%.1f, G:%.1f, B:%.1f", h, s, l, r, , b))

  local color = bit.lshift(math.floor(r * 255), 24) + bit.lshift(math.floor(g * 255), 16) + bit.lshift(math.floor(b * 255), 8) + 0xFF
  return color
end

function to_bit(bool)
  if bool then
    return 1
  else
    return 0
  end
end

function memory_readword_reverse(addr)
  local a = memory.readbyte(addr)
  local b = memory.readbyte(addr + 1)
  return  bit.bor(bit.lshift(b, 8), a)
end

function clamp(number, min, max)
  return math.max(math.min(number, max), min)
end

function check_input_down_autofire(player_object, input, autofire_rate, autofire_time)
  autofire_rate = autofire_rate or 4
  autofire_time = autofire_time or 23
  if player_object.input.pressed[input] or (player_object.input.down[input] and player_object.input.state_time[input] > autofire_time and (player_object.input.state_time[input] % autofire_rate) == 0) then
    return true
  end
  return false
end

perf_timer = {}
perf_timer.__index = perf_timer

function perf_timer:new()
  local obj = {}
  obj.start = os.clock()
  return setmetatable(obj, self)
end

function perf_timer:reset()
  self.start = os.clock()
end

function perf_timer:elapsed()
  local s = os.clock()
  local elapsed = s - self.start
  self:reset()
  return elapsed
end

function read_object_from_json_file(file_path)
  local f = io.open(file_path, "r")
  if f == nil then
    return {}
  end

  local object
  local pos, err
  ---@type table
  object, pos, err = json.decode(f:read("*all"))
  f:close()

  if (err) then
    print(string.format("Failed to read json file \"%s\" : %s", file_path, err))
  end

  return object
end

function write_object_to_json_file(object, file_path, indent)
  local f, error, code = io.open(file_path, "w")
  if f == nil then
    print(string.format("Error %d: %s", code, error))
    return false
  end
  local str = ""
  if indent then
    str = json.encode(object, { indent = true })
  else
    str = json.encode(object)
  end

  f:write(str)
  f:close()

  return true
end

function print_memory_line(addr)
  addr = addr - addr % 0x10

  print(string.format("%02X %02X %02X %02X %02X %02X %02X %02X   %02X %02X %02X %02X %02X %02X %02X %02X",
    memory.readbyte(addr + 0x0),
    memory.readbyte(addr + 0x1),
    memory.readbyte(addr + 0x2),
    memory.readbyte(addr + 0x3),
    memory.readbyte(addr + 0x4),
    memory.readbyte(addr + 0x5),
    memory.readbyte(addr + 0x6),
    memory.readbyte(addr + 0x7),
    memory.readbyte(addr + 0x8),
    memory.readbyte(addr + 0x9),
    memory.readbyte(addr + 0xA),
    memory.readbyte(addr + 0xB),
    memory.readbyte(addr + 0xC),
    memory.readbyte(addr + 0xD),
    memory.readbyte(addr + 0xE),
    memory.readbyte(addr + 0xF)
  ))
end

function deep_equal(a, b, visited)
  if a == b then return true end
  if type(a) ~= 'table' or type(b) ~= 'table' then return false end

  visited = visited or {}
  if visited[a] == b then return true end
  visited[a] = b

  for k, av in pairs(a) do
    if not deep_equal(av, b[k], visited) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end

  return true
end

function table_contains_deep(tbl, element)
  if tbl == nil then
    print (element)
  end
  for _, v in pairs(tbl) do
    if deep_equal(v, element) then
      return true
    end
  end
  return false
end

function deepcopy(orig, copies)
  copies = copies or {}
  if type(orig) ~= 'table' then
    return orig
  end

  if copies[orig] then
    return copies[orig]
  end

  local copy = {}
  copies[orig] = copy

  for key, value in pairs(orig) do
    local copy_key = deepcopy(key, copies)
    local copy_value = deepcopy(value, copies)
    copy[copy_key] = copy_value
  end

  local mt = getmetatable(orig)
  if mt then
    setmetatable(copy, deepcopy(mt, copies))
  end

  return copy
end

function combine_arrays(a, b)
  local combined = {}
  local n = 1
  for _, v in ipairs(a) do
    combined[n], n = v, n + 1
  end
  for _, v in ipairs(b) do
    combined[n], n = v, n + 1
  end
  return combined
end

function float_to_byte(n)
  local mantissa = n - math.floor(n)
  return math.floor(mantissa * 256)
end

convert_box_types = {"push", "throwable", "vulnerability", "ext. vulnerability", "attack", "throw"}
for i, box_type in ipairs(convert_box_types) do
  convert_box_types[box_type] = i
end

function format_box(box)
  return {type = convert_box_types[box[1]],
          bottom = box[2],
          height = box[3],
          left = box[4],
          width = box[5]}
end

function has_boxes(boxes, types)
  for _, box in pairs(boxes) do
    for _, type in pairs(types) do
      if convert_box_types[box[1]] == type then
        return true
      end
    end
  end
  return false
end

function get_boxes(boxes, types)
  local res = {}
  for _, box in pairs(boxes) do
    for _, type in pairs(types) do
      if convert_box_types[box[1]] == type then
        table.insert(res, box)
      end
    end
  end
  return res
end

function input_to_text(t)
  local result = {}
  for i = 1, #t do
    local text = ""
    for j = 1, #t[i] do
      if t[i][j] == "down" then
        text = text .. "Dummy"
      elseif t[i][j] == "up" then
        text = text .. "U"
      elseif t[i][j] == "forward" then
        text = text .. "F"
      elseif t[i][j] == "back" then
        text = text .. "B"
      end
    end
    if text ~= "" then
      text = text .. "+"
    end
    for j = 1, #t[i] do
      if t[i][j] == "LP" or t[i][j] == "MP" or t[i][j] == "HP"
      or t[i][j] == "LK" or t[i][j] == "MK" or t[i][j] == "HK" then
         text = text .. t[i][j]
        if j + 1 <= #t[i] then
          text = text .. "+"
        end
      end
    end
    table.insert(result, text)
  end
  return result
end