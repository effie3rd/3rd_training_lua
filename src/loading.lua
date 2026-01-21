-- for loading big stuff like framedata and images
local mp = require("src.libs.message_pack")
local tools = require("src.tools")

local DATA_TYPES = {FRAMEDATA = 1, IMAGES = 2}
local STATUS = {PENDING = 1, LOADING = 2, LOADED = 3}
local load_queue = {}

local function queue_load(data_type, path)
   local request = {
      data_type = data_type,
      path = path,
      status = STATUS.PENDING,
      result = {},
      loaded_size = 0,
      total_size = 0
   }
   local reader = mp.Msg_Pack_Reader.new(path)
   local size = reader:read()
   reader:close()
   request.total_size = size
   load_queue[#load_queue + 1] = request
   return request
end

-- store default color. everything else is recolored in real time and cached
local function load_text_images(filepath)
   local colors = require("src.ui.colors")
   local map = tools.read_object_from_json_file(filepath)
   local result = {}
   if map then
      for code, data in pairs(map) do
         result[code] = {}
         for lang, path in pairs(map[code]) do
            result[code][lang] = {}
            local png = gd.createFromPng(path)
            result[code][lang].width = png:sizeX()
            result[code][lang].height = png:sizeY()
            result[code][lang][colors.text.default] = png:gdStr()
         end
      end
   end
   return result
end

local function get_total_file_size()
   local total_size = 0
   for _, request in ipairs(load_queue) do total_size = total_size + request.total_size end
   return total_size
end

local frame_time_margin = 0.80
local frame_time = (1 / 60) * frame_time_margin

local load_timer = tools.Perf_Timer:new()
local load_rate = math.huge
local n_loaded_this_frame = 0

local function load_images_async(result, path)
   local reader = mp.Msg_Pack_Reader.new(path)
   local size = reader:read()
   load_timer:reset()
   repeat
      size = reader:get_length()
      if not size then break end
      if load_rate * (frame_time - load_timer:elapsed()) < size then
         coroutine.yield(n_loaded_this_frame)
         load_timer:reset()
         n_loaded_this_frame = 0
      end
      local obj = reader:read()
      if obj then
         result[obj.key] = obj.data
         n_loaded_this_frame = n_loaded_this_frame + size
         load_rate = n_loaded_this_frame / load_timer:elapsed()
      end
   until obj == nil
   reader:close()
   coroutine.yield(n_loaded_this_frame)
end

local function load_frame_data_async(result, path)
   local reader = mp.Msg_Pack_Reader.new(path)
   local size = reader:read()
   load_timer:reset()
   repeat
      size = reader:get_length()
      if not size then break end
      if load_rate * (frame_time - load_timer:elapsed()) < size then
         coroutine.yield(n_loaded_this_frame)
         load_timer:reset()
         n_loaded_this_frame = 0
      end
      local obj = reader:read()
      if obj then
         if not result[obj.char] then result[obj.char] = {} end
         result[obj.char][obj.id] = obj.data
         n_loaded_this_frame = n_loaded_this_frame + size
         load_rate = n_loaded_this_frame / load_timer:elapsed()
      end
   until obj == nil
   reader:close()
   coroutine.yield(n_loaded_this_frame)
end

local function load_framedata_human_readable()
   local framedata = require("src.data.framedata")
   local settings = require("src.settings")
   for _, char in ipairs(framedata.frame_data_keys) do
      local file_path = settings.framedata_path .. "@" .. char .. settings.framedata_file_ext
      framedata.frame_data[char] = tools.read_object_from_json_file(file_path)
   end
end

local loader

local function load_all()
   local request = load_queue[1]
   local n_loaded = 0
   if request.status == STATUS.PENDING then
      if request.data_type == DATA_TYPES.FRAMEDATA then
         loader = coroutine.create(load_frame_data_async)
      elseif request.data_type == DATA_TYPES.IMAGES then
         loader = coroutine.create(load_images_async)
      else
         error("invalid data type")
      end
      request.status = STATUS.LOADING
   end

   if loader then
      local status = coroutine.status(loader)
      if status == "suspended" then
         local pass, n = coroutine.resume(loader, request.result, request.path)
         if pass and n then
            n_loaded = n
            request.loaded_size = request.loaded_size + n
         end
      elseif status == "dead" then
         request.status = STATUS.LOADED
         table.remove(load_queue, 1)
      end
   end
   return n_loaded
end

local function load_binary(dest_tbl, bin_file)
   local mp_reader = mp.Msg_Pack_Reader.new(bin_file)
   local size = mp_reader:read()
   repeat
      size = mp_reader:get_length()
      if not size then break end
      local obj = mp_reader:read()
      if obj then dest_tbl[obj.key] = obj.data end
   until obj == nil
   mp_reader:close()
end

local function write_file_size(file_path, size)
   local file = io.open(file_path, "rb")
   local bin_data = file and file:read("*a") or ""
   if not file then
      return
   else
      file:close()
   end
   local writer = mp.Msg_Pack_Writer.new(file_path)
   writer:write(size)
   writer:close()
   file = io.open(file_path, "ab")
   if file then
      file:write(bin_data)
      file:close()
   end
end

local function serialize(data, file_path)
   local writer = mp.Msg_Pack_Writer.new(file_path)
   local total_size = 0
   for key, v in pairs(data) do
      local obj = {key = key, data = v}
      writer:write(obj)
      total_size = total_size + writer.len
   end
   writer:close()
   write_file_size(file_path, total_size)
end

-- local settings = require("src.settings")
-- local image_tables = require("src.ui.image_tables")
-- serialize(load_text_images("data/load_first.json"), settings.data_path .. settings.load_first_bin_file)
-- serialize(load_text_images(settings.data_path .. "image_map.json"), settings.data_path .. settings.text_bin_file)
-- serialize(image_tables.build_images(), settings.data_path .. settings.images_bin_file)

local loading = {
   DATA_TYPES = DATA_TYPES,
   STATUS = STATUS,
   queue_load = queue_load,
   load_all = load_all,
   load_binary = load_binary,
   load_framedata_human_readable = load_framedata_human_readable,
   get_total_file_size = get_total_file_size
}

return loading
