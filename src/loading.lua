-- for loading big stuff like framedata and images
local mp = require("src.libs.message_pack")
local tools = require("src.tools")
local colors = require("src.ui.colors")
local settings = require("src.settings")
local menu_tables = require("src.ui.menu_tables")
local framedata = require("src.modules.framedata")
local image_tables = require("src.ui.image_tables")

local frame_data = framedata.frame_data


-- store default color. everything else is recolored in real time and cached
local function load_text_images(filepath)
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

local function get_total_files()
   local reader = mp.Msg_Pack_Reader.new(settings.data_path .. settings.text_bin_file)
   local text_size = reader:read()
   reader:close()
   reader = mp.Msg_Pack_Reader.new(settings.data_path .. settings.images_bin_file)
   local images_size = reader:read()
   reader:close()
   reader = mp.Msg_Pack_Reader.new(settings.framedata_path .. settings.framedata_bin_file)
   local framedata_size = reader:read()
   reader:close()
   return text_size + images_size + framedata_size
end

local frame_time_margin = 0.80
local frame_time = (1 / 60) * frame_time_margin

local load_timer = tools.Perf_Timer:new()
local load_rate = math.huge
local n_loaded_this_frame = 0

local function load_text_async()
   local reader = mp.Msg_Pack_Reader.new(settings.data_path .. settings.text_bin_file)
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
         image_tables.text[obj.key] = obj.data
         n_loaded_this_frame = n_loaded_this_frame + size
         load_rate = n_loaded_this_frame / load_timer:elapsed()
      end
   until obj == nil
   reader:close()
   coroutine.yield(n_loaded_this_frame)
end

local function load_images_async()
   local reader = mp.Msg_Pack_Reader.new(settings.data_path .. settings.images_bin_file)
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
         image_tables.images[obj.key] = obj.data
         n_loaded_this_frame = n_loaded_this_frame + size
         load_rate = n_loaded_this_frame / load_timer:elapsed()
      end
   until obj == nil
   reader:close()
   coroutine.yield(n_loaded_this_frame)
end

local function load_frame_data_async()
   framedata.clear_frame_data()
   local reader = mp.Msg_Pack_Reader.new(settings.framedata_path .. settings.framedata_bin_file)
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
         framedata.frame_data[obj.char][obj.id] = obj.data
         n_loaded_this_frame = n_loaded_this_frame + size
         load_rate = n_loaded_this_frame / load_timer:elapsed()
      end
   until obj == nil
   reader:close()
   coroutine.yield(n_loaded_this_frame)
end

local function load_framedata_human_readable()
   for _, char in ipairs(framedata.frame_data_keys) do
      local file_path = settings.framedata_path .. "@" .. char .. settings.framedata_file_ext
      frame_data[char] = tools.read_object_from_json_file(file_path)
   end
end

local text_loader = {coroutine = coroutine.create(load_text_async), finished = false}
local images_loader = {coroutine = coroutine.create(load_images_async), finished = false}
local frame_data_loader = {coroutine = coroutine.create(load_frame_data_async), finished = false}
local loaders = {text_loader, images_loader, frame_data_loader}
local loader_index = 1
local current_loader = loaders[loader_index]

local function load_all()
   local n_loaded = 0
   if current_loader then
      local status = coroutine.status(current_loader.coroutine)
      if status == "suspended" then
         local pass, n = coroutine.resume(current_loader.coroutine)
         if pass and n then n_loaded = n end
      elseif status == "dead" then
         current_loader.finished = true
         loader_index = loader_index + 1
         current_loader = loaders[loader_index]
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

-- serialize(load_text_images("data/load_first.json"), settings.data_path .. settings.load_first_bin_file)
-- serialize(load_text_images(settings.data_path .. "image_map.json"), settings.data_path .. settings.text_bin_file)
-- serialize(image_tables.build_images(), settings.data_path .. settings.images_bin_file)

-- load character select items first so they can be displayed at run
load_binary(image_tables.text, settings.data_path .. settings.load_first_bin_file)

colors.themes = tools.read_object_from_json_file(settings.themes_path)
tools.convert_strings_to_numbers(colors.themes)
colors.set_theme(settings.training.theme)
local theme_names = {}
for _, theme in pairs(colors.themes) do theme_names[#theme_names + 1] = "theme_" .. theme.name end
menu_tables.theme_names = theme_names


local loading = {
   load_all = load_all,
   load_framedata_human_readable = load_framedata_human_readable,
   get_total_files = get_total_files
}

setmetatable(loading, {
   __index = function(_, key)
      if key == "images_loaded" then
         return text_loader.finished and images_loader.finished
      elseif key == "frame_data_loaded" then
         return frame_data_loader.finished
      end
   end
})

return loading
