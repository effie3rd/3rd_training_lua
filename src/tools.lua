local json = require("src.libs.dkjson")
local debug_settings = require("src.debug_settings")

local assert_enabled = debug_settings.developer_mode
local function t_assert(condition, msg)
   msg = msg or "Assertion failed"
   if assert_enabled and not condition then error(msg, 2) end
end

local function round(n) return math.floor(n + 0.5) end

local function sign(n) return n > 0 and 1 or (n == 0 and 0 or -1) end

local function flip_to_sign(flip_x) return flip_x == 0 and -1 or (flip_x == 1 and 1) end

local function bool_xor(a, b) return (a or b) and not (a and b) end

local function string_hash(str)
   if #str == 0 then return 0 end

   local dJB2_INIT = 5381;
   local hash = dJB2_INIT
   for i = 1, #str do
      local c = string.byte(str, i)
      hash = bit.lshift(hash, 5) + hash + c
   end
   return hash
end

local function string_to_color(str)
   local HRange = {0.0, 360.0}
   local sRange = {0.8, 1.0}
   local lRange = {0.7, 1.0}

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

   local rGBValues = {l, l * (1.0 - s), l * (1.0 - (HDiv60_Fraction * s)), l * (1.0 - ((1.0 - HDiv60_Fraction) * s))}

   local rGBSwizzle = {{1, 4, 2}, {3, 1, 2}, {2, 1, 4}, {2, 3, 1}, {4, 2, 1}, {1, 2, 3}}
   local swizzleIndex = (HDiv60_Floor % 6) + 1
   local r = rGBValues[rGBSwizzle[swizzleIndex][1]]
   local g = rGBValues[rGBSwizzle[swizzleIndex][2]]
   local b = rGBValues[rGBSwizzle[swizzleIndex][3]]

   -- print(string.format("H:%.1f, S:%.1f, L:%.1f | R:%.1f, G:%.1f, B:%.1f", h, s, l, r, , b))

   local color = bit.lshift(math.floor(r * 255), 24) + bit.lshift(math.floor(g * 255), 16) +
                     bit.lshift(math.floor(b * 255), 8) + 0xFF
   return color
end

local function to_bit(bool)
   if bool then
      return 1
   else
      return 0
   end
end

local function memory_readword_reverse(addr)
   local a = memory.readbyte(addr)
   local b = memory.readbyte(addr + 1)
   return bit.bor(bit.lshift(b, 8), a)
end

local function clamp(number, min, max) return math.max(math.min(number, max), min) end

local function check_input_down_autofire(player_object, input, autofire_rate, autofire_time)
   autofire_rate = autofire_rate or 4
   autofire_time = autofire_time or 23
   if player_object.input.pressed[input] or
       (player_object.input.down[input] and player_object.input.state_time[input] > autofire_time and
           (player_object.input.state_time[input] % autofire_rate) == 0) then return true end
   return false
end

local Perf_timer = {}
Perf_timer.__index = Perf_timer

function Perf_timer:new()
   local obj = {}
   obj.start = os.clock()
   return setmetatable(obj, self)
end
function Perf_timer:reset() self.start = os.clock() end
function Perf_timer:elapsed() return os.clock() - self.start end

local function read_number_from_file(file_path)
   local f = io.open(file_path, "r")
   if not f then error("Cannot open " .. file_path) end
   return tonumber(f:read("*l"))
end

local function read_object_from_json_file(file_path)
   local f = io.open(file_path, "r")
   if f == nil then return nil end

   local object
   local pos, err
   ---@type table
   object, pos, err = json.decode(f:read("*all"))
   f:close()

   if (err) then print(string.format("Failed to read json file \"%s\" : %s", file_path, err)) end

   return object
end

local function write_object_to_json_file(object, file_path, indent)
   local f, error, code = io.open(file_path, "w")
   if f == nil then
      print(string.format("Error %d: %s", code, error))
      return false
   end
   local str
   if indent then
      str = json.encode(object, {indent = true})
   else
      str = json.encode(object)
   end
   f:write(str)
   f:close()
   return true
end

local function print_memory_line(addr)
   addr = addr - addr % 0x10

   print(string.format("%02X %02X %02X %02X %02X %02X %02X %02X   %02X %02X %02X %02X %02X %02X %02X %02X",
                       memory.readbyte(addr + 0x0), memory.readbyte(addr + 0x1), memory.readbyte(addr + 0x2),
                       memory.readbyte(addr + 0x3), memory.readbyte(addr + 0x4), memory.readbyte(addr + 0x5),
                       memory.readbyte(addr + 0x6), memory.readbyte(addr + 0x7), memory.readbyte(addr + 0x8),
                       memory.readbyte(addr + 0x9), memory.readbyte(addr + 0xA), memory.readbyte(addr + 0xB),
                       memory.readbyte(addr + 0xC), memory.readbyte(addr + 0xD), memory.readbyte(addr + 0xE),
                       memory.readbyte(addr + 0xF)))
end

local function table_contains(tbl, value)
   for _, v in pairs(tbl) do if v == value then return true end end
   return false
end

local function table_indexof(tbl, value)
   for i, v in ipairs(tbl) do if v == value then return i end end
   return nil
end

local function table_contains_property(tbl, prop, value)
   for _, obj in pairs(tbl) do if obj[prop] == value then return true end end
   return false
end

local function deep_equal(a, b, visited)
   if a == b then return true end
   if type(a) ~= "table" or type(b) ~= "table" then return false end

   visited = visited or {}
   if visited[a] == b then return true end
   visited[a] = b

   for k, av in pairs(a) do if not deep_equal(av, b[k], visited) then return false end end
   for k in pairs(b) do if a[k] == nil then return false end end

   return true
end

local function table_contains_deep(tbl, element)
   if tbl == nil then return false end
   for _, v in pairs(tbl) do if deep_equal(v, element) then return true end end
   return false
end

local function deepcopy(orig, copies)
   copies = copies or {}
   if type(orig) ~= "table" then return orig end

   if copies[orig] then return copies[orig] end

   local copy = {}
   copies[orig] = copy

   for key, value in pairs(orig) do
      local copy_key = deepcopy(key, copies)
      local copy_value = deepcopy(value, copies)
      copy[copy_key] = copy_value
   end

   local mt = getmetatable(orig)
   if mt then setmetatable(copy, deepcopy(mt, copies)) end

   return copy
end

local function clear_table(tbl) for k in pairs(tbl) do tbl[k] = nil end end

local function combine_arrays(a, b)
   local combined = {}
   local n = 1
   for _, v in ipairs(a) do combined[n], n = v, n + 1 end
   for _, v in ipairs(b) do combined[n], n = v, n + 1 end
   return combined
end

local function float_to_byte(n)
   local mantissa = n - math.floor(n)
   return math.floor(mantissa * 256)
end

local convert_box_types = {"push", "throwable", "vulnerability", "ext. vulnerability", "attack", "throw"}
for i, box_type in ipairs(convert_box_types) do convert_box_types[box_type] = i end

local function format_box(box)
   return {type = convert_box_types[box[1]], bottom = box[2], height = box[3], left = box[4], width = box[5]}
end

local function create_box(box) return {convert_box_types[box.type], box.bottom, box.height, box.left, box.width} end

local function has_boxes(boxes, types)
   for _, box in pairs(boxes) do
      for _, type in pairs(types) do if convert_box_types[box[1]] == type then return true end end
   end
   return false
end

local function get_boxes(boxes, types)
   local res = {}
   for _, box in pairs(boxes) do
      for _, type in pairs(types) do if convert_box_types[box[1]] == type then table.insert(res, box) end end
   end
   return res
end

local function get_pushboxes(player)
   for _, box in pairs(player.boxes) do if convert_box_types[box[1]] == "push" then return box end end
   return nil
end

local function get_boxes_lowest_position(boxes, types)
   if boxes then
      local min = math.huge
      for _, box in pairs(boxes) do
         local b = format_box(box)
         for _, type in pairs(types) do if b.type == type and b.bottom < min then min = b.bottom end end
      end
      return min
   end
   return nil
end

local function get_boxes_highest_position(boxes, types)
   if boxes then
      local max = 0
      for _, box in pairs(boxes) do
         local b = format_box(box)
         for _, type in pairs(types) do
            if b.type == type and b.bottom + b.height > max then max = b.bottom + b.height end
         end
      end
      return max
   end
   return 0
end

local function is_pressing_forward(player, input)
   if player.flip_x == 0 then
      return input[player.prefix .. " Left"]
   else
      return input[player.prefix .. " Right"]
   end
end

local function is_pressing_back(player, input)
   if player.flip_x == 0 then
      return input[player.prefix .. " Right"]
   else
      return input[player.prefix .. " Left"]
   end
end

local function is_pressing_down(player, input) return input[player.prefix .. " Down"] end

local function input_to_text(t)
   local result = {}
   for i = 1, #t do
      local text = ""
      for j = 1, #t[i] do
         if t[i][j] == "down" then
            text = text .. "D"
         elseif t[i][j] == "up" then
            text = text .. "U"
         elseif t[i][j] == "forward" then
            text = text .. "F"
         elseif t[i][j] == "back" then
            text = text .. "B"
         end
      end
      if text ~= "" then text = text .. "+" end
      for j = 1, #t[i] do
         if t[i][j] == "LP" or t[i][j] == "MP" or t[i][j] == "HP" or t[i][j] == "LK" or t[i][j] == "MK" or t[i][j] ==
             "HK" then
            text = text .. t[i][j]
            if j + 1 <= #t[i] then text = text .. "+" end
         end
      end
      table.insert(result, text)
   end
   return result
end

local function sequence_to_name(seq)
   local btn = ""
   local ud = ""
   local bf = ""
   for k, v in pairs(seq[1]) do
      if v == "LP" or v == "MP" or v == "HP" or v == "LK" or v == "MK" or v == "HK" then
         if btn == "" then
            btn = v
         else
            btn = btn .. "+" .. v
         end
      elseif v == "down" then
         ud = "d"
      elseif v == "up" then
         ud = "u"
      elseif v == "forward" then
         bf = "f"
      elseif v == "back" then
         bf = "b"
      end
   end
   if string.len(ud .. bf) > 0 then return ud .. bf .. "_" .. btn end
   return btn
end

local function enum(names, opts)
   opts = opts or {}
   local e = {}
   for i, name in ipairs(names) do
      local key = opts.upper and name:upper() or name
      e[key] = i
      if opts.reverse then e[i] = key end
   end
   return e
end

local function select_weighted(list)
   local total = 0
   for _, item in ipairs(list) do total = total + item.weight end

   local r = math.random() * total
   local cumulative = 0

   for _, item in ipairs(list) do
      cumulative = cumulative + item.weight
      if r <= cumulative then return item end
   end
end

local function wrap_index(i, num)
   if i > num then
      return 1
   elseif i < 1 then
      return num
   end
   return i
end

local function bound_index(i, num)
   if i > num then
      return num
   elseif i < 1 then
      return 1
   end
   return i
end

local function get_calling_module_name()
   local src = debug.getinfo(3, "S")
   if not src then return nil end
   return src.short_src:match("([^/\\]+)%.lua$")
end

return {
   t_assert = t_assert,
   round = round,
   sign = sign,
   flip_to_sign = flip_to_sign,
   bool_xor = bool_xor,
   string_hash = string_hash,
   string_to_color = string_to_color,
   to_bit = to_bit,
   memory_readword_reverse = memory_readword_reverse,
   clamp = clamp,
   check_input_down_autofire = check_input_down_autofire,
   Perf_timer = Perf_timer,
   read_number_from_file = read_number_from_file,
   read_object_from_json_file = read_object_from_json_file,
   write_object_to_json_file = write_object_to_json_file,
   print_memory_line = print_memory_line,
   table_contains = table_contains,
   table_indexof = table_indexof,
   table_contains_property = table_contains_property,
   deep_equal = deep_equal,
   table_contains_deep = table_contains_deep,
   deepcopy = deepcopy,
   clear_table = clear_table,
   combine_arrays = combine_arrays,
   float_to_byte = float_to_byte,
   convert_box_types = convert_box_types,
   format_box = format_box,
   create_box = create_box,
   has_boxes = has_boxes,
   get_boxes = get_boxes,
   get_pushboxes = get_pushboxes,
   get_boxes_lowest_position = get_boxes_lowest_position,
   get_boxes_highest_position = get_boxes_highest_position,
   is_pressing_forward = is_pressing_forward,
   is_pressing_back = is_pressing_back,
   is_pressing_down = is_pressing_down,
   input_to_text = input_to_text,
   sequence_to_name = sequence_to_name,
   enum = enum,
   select_weighted = select_weighted,
   wrap_index = wrap_index,
   bound_index = bound_index,
   get_calling_module_name = get_calling_module_name
}
