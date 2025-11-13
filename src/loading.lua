-- for loading big stuff like framedata and images
local json = require("src.libs.dkjson")
local mp = require("src.libs.message_pack")
local tools = require("src.tools")
local colors = require("src.ui.colors")
local text = require("src.ui.text")
local settings = require("src.settings")
local menu_tables = require("src.ui.menu_tables")
local framedata = require("src.modules.framedata")

local image_map = text.image_map
local frame_data = framedata.frame_data

local image_map_json_data = tools.read_object_from_json_file("data/image_map.json") or {}

local reader = mp.Msg_Pack_Reader.new(settings.framedata_path .. settings.framedata_bin_file)
local framedata_size = reader:read()
reader:close()

local text_images_size = 0
for _, data in pairs(image_map_json_data) do text_images_size = text_images_size + 1 end

-- cache default, selected, and disabled colors. everything is recolored in real time
local function load_text_images(filepath)
   local map = tools.read_object_from_json_file(filepath)
   if map then
      for code, data in pairs(map) do
         image_map[code] = {}
         for lang, path in pairs(map[code]) do
            image_map[code][lang] = {}
            local png = gd.createFromPng(path)

            image_map[code][lang].base_image = png
            image_map[code][lang].width = png:sizeX()
            image_map[code][lang].height = png:sizeY()
            if lang == "en" then
               -- removing extra height from y sticking out below
               image_map[code][lang].height = image_map[code][lang].height - 1
            end

            image_map[code][lang][text.default_color] = png:gdStr()
         end
      end
   end
end

local function load_text_image(data, code)
   image_map[code] = {}
   for lang, path in pairs(data) do
      image_map[code][lang] = {}
      local png = gd.createFromPng(path)

      image_map[code][lang].base_image = png
      image_map[code][lang].width = png:sizeX()
      image_map[code][lang].height = png:sizeY()
      if lang == "en" then
         -- removing extra height from y sticking out below
         image_map[code][lang].height = image_map[code][lang].height - 1
      end

      image_map[code][lang][text.default_color] = png:gdStr()
   end
end

local im_load_time_constant = 2444

local function get_total_files() return text_images_size * im_load_time_constant + framedata_size end

local frame_time_margin = 0.80
local frame_time = (1 / 60) * frame_time_margin

local function estimate_chunks_per_frame(elapsed, chunks_loaded)
   local rate = elapsed / chunks_loaded
   return math.max(math.floor(frame_time * frame_time_margin / rate), 1)
end

local load_timer = tools.Perf_Timer:new()
local load_rate = math.huge
local n_loaded_this_frame = 0

local n_im_loaded_this_frame = 0
local n_im_chunks_per_frame = 20
local function load_text_images_async()
   if image_map_json_data then
      local keys = {}
      for k in pairs(image_map_json_data) do keys[#keys + 1] = k end
      for i = 1, #keys do
         local code = keys[i]

         load_text_image(image_map_json_data[code], code)
         n_im_loaded_this_frame = n_im_loaded_this_frame + 1
         if n_im_loaded_this_frame >= n_im_chunks_per_frame then
            coroutine.yield(n_im_loaded_this_frame)
            load_timer:reset()
            n_im_loaded_this_frame = 0
         end
      end
   end
   coroutine.yield(n_im_loaded_this_frame)
   image_map_json_data = nil
end

local function load_frame_data_async()
   framedata.clear_frame_data()
   reader = mp.Msg_Pack_Reader.new(settings.framedata_path .. settings.framedata_bin_file)
   framedata_size = reader:read()
   load_timer:reset()
   repeat
      local size = reader:get_length()
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

local load_frame_data_co = coroutine.create(load_frame_data_async)
local load_text_images_co = coroutine.create(load_text_images_async)
local current_loader = load_frame_data_co
local text_images_loaded = false
local frame_data_loaded = false

local function load_all()
   if not text_images_loaded then
      current_loader = load_text_images_co
   elseif not frame_data_loaded then
      current_loader = load_frame_data_co
   end
   local n_loaded = 0
   local status = coroutine.status(current_loader)
   if status == "suspended" then
      local pass, n = coroutine.resume(current_loader)
      if pass and n then
         n_loaded = n
         if current_loader == load_text_images_co then n_loaded = n_loaded * im_load_time_constant end
      end
   elseif status == "dead" then
      if current_loader == load_text_images_co then
         text_images_loaded = true
      else
         frame_data_loaded = true
      end
   end
   if current_loader == load_text_images_co then
      n_im_chunks_per_frame = estimate_chunks_per_frame(load_timer:elapsed(), n_im_chunks_per_frame)
   end
   return n_loaded
end

local function reload_text_images()
   text_images_loaded = false
   load_frame_data_co = coroutine.create(load_frame_data_async)
   load_all()
end

local function convert_strings_to_numbers(tbl)
   for k, v in pairs(tbl) do
      if type(v) == "string" and k ~= "name" then
         tbl[k] = tonumber(v, 16)
      elseif type(v) == "table" then
         convert_strings_to_numbers(v)
      end
   end
end

-- load character select items first so they can be displayed at run
load_text_images("data/load_first.json")

colors.themes = tools.read_object_from_json_file(settings.themes_path)
convert_strings_to_numbers(colors.themes)
colors.set_theme(settings.training.theme)
local theme_names = {}
for _, theme in pairs(colors.themes) do table.insert(theme_names, "theme_" .. theme.name) end
menu_tables.theme_names = theme_names
local loading = {
   load_all = load_all,
   load_framedata_human_readable = load_framedata_human_readable,
   get_total_files = get_total_files,
   reload_text_images = reload_text_images
}

setmetatable(loading, {
   __index = function(_, key)
      if key == "text_images_loaded" then
         return text_images_loaded
      elseif key == "frame_data_loaded" then
         return frame_data_loaded
      end
   end,

   __newindex = function(_, key, value)
      if key == "text_images_loaded" then
         text_images_loaded = value
      elseif key == "frame_data_loaded" then
         frame_data_loaded = value
      else
         rawset(loading, key, value)
      end
   end
})

return loading
