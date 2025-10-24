-- for loading big stuff like framedata and images
local json = require("src.libs.dkjson")
local tools = require("src.tools")
local colors = require("src.ui.colors")
local text = require("src.ui.text")
local fd = require("src.modules.framedata")
local game_data = require("src.modules.game_data")
local settings = require("src.settings")
local menu_tables = require("src.ui.menu_tables")

local image_map = text.image_map
local frame_data = fd.frame_data

---@type table|nil
local image_map_json_data = tools.read_object_from_json_file("data/image_map.json")
local framedata_size = tools.read_number_from_file(settings.framedata_path .. "file_size.json")
local frame_data_keys = copytable(game_data.characters)
table.insert(frame_data_keys, "projectiles")

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

            local gdStr = png:gdStr()
            image_map[code][lang][text.default_color] = gd.createFromGdStr(gdStr)
            image_map[code][lang][text.selected_color] = gd.createFromGdStr(gdStr)
            image_map[code][lang][text.inactive_color] = gd.createFromGdStr(gdStr)

            local gd_default_color = colors.hex_to_gd_color(text.default_color)
            local gd_selected_color = colors.hex_to_gd_color(text.selected_color)
            local gd_inactive_color = colors.hex_to_gd_color(text.inactive_color)
            for i = 0, image_map[code][lang].width - 1 do
               for j = 0, image_map[code][lang].height - 1 do
                  if image_map[code][lang].base_image:getPixel(i, j) == colors.gd_white then
                     image_map[code][lang][text.default_color]:setPixel(i, j, gd_default_color)
                     image_map[code][lang][text.selected_color]:setPixel(i, j, gd_selected_color)
                     image_map[code][lang][text.inactive_color]:setPixel(i, j, gd_inactive_color)
                  end
               end
            end

            image_map[code][lang][text.default_color] = image_map[code][lang][text.default_color]:gdStr()
            image_map[code][lang][text.selected_color] = image_map[code][lang][text.selected_color]:gdStr()
            image_map[code][lang][text.inactive_color] = image_map[code][lang][text.inactive_color]:gdStr()
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

      local gdStr = png:gdStr()
      image_map[code][lang][text.default_color] = gd.createFromGdStr(gdStr)
      image_map[code][lang][text.selected_color] = gd.createFromGdStr(gdStr)
      image_map[code][lang][text.inactive_color] = gd.createFromGdStr(gdStr)

      local gd_selected_color = colors.hex_to_gd_color(text.selected_color)
      local gd_inactive_color = colors.hex_to_gd_color(text.inactive_color)
      for i = 0, image_map[code][lang].width - 1 do
         for j = 0, image_map[code][lang].height - 1 do
            if image_map[code][lang].base_image:getPixel(i, j) == colors.gd_white then
               image_map[code][lang][text.selected_color]:setPixel(i, j, gd_selected_color)
               image_map[code][lang][text.inactive_color]:setPixel(i, j, gd_inactive_color)
            end
         end
      end

      image_map[code][lang][text.default_color] = image_map[code][lang][text.default_color]:gdStr()
      image_map[code][lang][text.selected_color] = image_map[code][lang][text.selected_color]:gdStr()
      image_map[code][lang][text.inactive_color] = image_map[code][lang][text.inactive_color]:gdStr()

   end
end

local function get_total_files() return framedata_size end

local frame_time_margin = 0.80
local frame_time = (1 / 60) * frame_time_margin

local function estimate_chunks_per_frame(elapsed, chunks_loaded)
   local rate = elapsed / chunks_loaded
   return math.max(math.floor(frame_time * frame_time_margin / rate), 1)
end

local fd_load_margin = 1
local function estimate_load_rate(elapsed, n_loaded)
   if elapsed == 0 then return fd_load_margin end
   return math.min(n_loaded / (elapsed * 1000000) * fd_load_margin, 1)
end

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
            n_im_loaded_this_frame = 0
         end
      end
   end
   coroutine.yield(n_im_loaded_this_frame)
   image_map_json_data = nil
end

local load_timer = tools.Perf_timer:new()
local fd_load_rate = 1
local fd_loaded_this_frame = 0
local function load_frame_data_async()
   for _, char in ipairs(frame_data_keys) do
      local fd_load_start_time = os.clock()
      frame_data[char] = {}
      local file_path = settings.framedata_path .. char .. settings.framedata_file_ext
      local file = io.open(file_path, "r")
      if not file then error("Cannot open " .. file_path) end
      for line in file:lines() do
         local id, load_time, json_str = line:match("([^,]+),(%d+):(.+)")
         load_time = tonumber(load_time)
         if (frame_time - (os.clock() - fd_load_start_time)) * 1000000 * fd_load_rate > load_time then
            frame_data[char][id] = json.decode(json_str)
         else
            coroutine.yield(fd_loaded_this_frame)
            fd_load_start_time = os.clock()
            fd_loaded_this_frame = 0
            frame_data[char][id] = json.decode(json_str)
         end
         fd_loaded_this_frame = fd_loaded_this_frame + load_time
      end
   end
end

local function load_framedata_human_readable()
   for _, char in ipairs(frame_data_keys) do
      local file_path = settings.framedata_path .. "@" .. char .. settings.framedata_file_ext
      frame_data[char] = tools.read_object_from_json_file(file_path)
   end
end

local load_frame_data_co = coroutine.create(load_frame_data_async)
local load_text_images_co = coroutine.create(load_text_images_async)
local current_co = load_frame_data_co
local text_images_loaded = false
local frame_data_loaded = false

local function load_all()
   if not text_images_loaded then
      current_co = load_text_images_co
   elseif not frame_data_loaded then
      current_co = load_frame_data_co
   end
   local n_loaded = 0
   load_timer:reset()
   local status = coroutine.status(current_co)
   if status == "suspended" then
      local pass, n = coroutine.resume(current_co)
      if pass and n then n_loaded = n end
   elseif status == "dead" then
      if current_co == load_text_images_co then
         text_images_loaded = true
      else
         frame_data_loaded = true
      end
   end
   if current_co == load_text_images_co then
      local elapsed = load_timer:elapsed()
      n_im_chunks_per_frame = estimate_chunks_per_frame(elapsed, n_im_chunks_per_frame)
   else
      fd_load_rate = estimate_load_rate(load_timer:elapsed(), fd_loaded_this_frame)
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
load_text_images("images/menu/load_first.json")

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
