require("gd")
local utf8 = require("src.libs.utf8")
local settings = require("src.settings")
local colors = require("src.ui.colors")

local image_map = {}

local function draw_text(x, y, str, lang, size, color, opacity)
   if size and string.sub(str, 1, 3) == "utf" then lang = lang .. "_" .. size end
   if image_map[str][lang][color] then
      gui.image(x, y, image_map[str][lang][color], opacity)
   else
      local gd_color = colors.hex_to_gd_color(color)
      local img = colors.substitute_color(image_map[str][lang].base_image, colors.gd_white, gd_color)
      image_map[str][lang][color] = img
      gui.image(x, y, img, opacity)
   end
end

local function render_text_jp(x, y, str, lang, size, color, opacity)
   local offset = 0
   lang = lang or "jp"
   color = color or colors.text.default
   opacity = opacity or 1
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. tostring(code)
         draw_text(x + offset, y, code, lang, size, color, opacity)
         offset = offset + image_map[code][lang].width - 1
      else
         offset = offset + 2
      end
   end
end

local function render_text(x, y, str, lang, size, color, opacity)
   local offset = 0
   str = tostring(str)
   lang = lang or settings.language
   color = color or colors.text.default
   opacity = opacity or 1
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      -- char is jp
      if code >= 12288 and code <= 40879 then
         -- render individual jp characters
         render_text_jp(x, y, str, lang, size, color, opacity)
         return
      end
   end
   -- str is not jp, draw block of text if it exists
   if image_map[str] then
      draw_text(x + offset, y, str, lang, size, color, opacity)
      return
   end

   -- render individual characters
   local lang_ext = lang
   if size then lang_ext = lang_ext .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then -- not space
         code = "utf_" .. tostring(code)
         draw_text(x + offset, y, code, lang, size, color, opacity)
         offset = offset + image_map[code][lang_ext].width - 1
      else
         offset = offset + 2
      end
   end
end

local function get_text_dimensions_jp(str, lang, size)
   local w,h  = 0, 0
   lang = lang or "jp"
   if size then lang = lang .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = "utf_" .. utf8.codepoint(v)
      if code ~= 32 then
         w = w + image_map[code][lang].width
         h = image_map[code][lang].height
      else
         w = w + 3
      end
   end
   w = w - utf8.len(str) + 1
   return w, h
end

local function get_text_dimensions(str, lang, size)
   local w,h  = 0, 0
   str = tostring(str)
   lang = lang or settings.language
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      -- char is jp
      if code >= 12288 and code <= 40879 then
         w, h = get_text_dimensions_jp(str, lang, size)
         return w, h
      end
   end
   -- str is not jp, get size of block of text
   if image_map[str] then return image_map[str][lang].width, image_map[str][lang].height end
   if size then lang = lang .. "_" .. size end
   for _, v in utf8.codes(str) do
      local code = utf8.codepoint(v)
      if code ~= 32 then
         code = "utf_" .. tostring(code)
         w = w + image_map[code][lang].width
         h = image_map[code][lang].height
      else
         w = w + 3
      end
   end
   if str ~= "" then w = w - utf8.len(str) + 1 end
   return w, h
end

local function render_text_multiple(x, y, list_str, lang, size, color, opacity)
   local offset_x = 0
   for _, str in pairs(list_str) do
      render_text(x + offset_x, y, str, lang, size, color, opacity)
      local tw, th = get_text_dimensions(str, lang, size)
      offset_x = offset_x + tw
   end
end

local function get_text_dimensions_multiple(list_str, lang, size)
   local w = 0
   local h = 0
   for _, str in pairs(list_str) do
      local tw, th = get_text_dimensions(str, lang, size)
      w = w + tw
      h = math.max(h, th)
   end
   return w, h
end

local text_module = {
   image_map = image_map,
   render_text = render_text,
   get_text_dimensions = get_text_dimensions,
   render_text_multiple = render_text_multiple,
   get_text_dimensions_multiple = get_text_dimensions_multiple
}

setmetatable(text_module, {
   __index = function(_, key)
      if key == "default_color" then
         return colors.text.default
      elseif key == "selected_color" then
         return colors.text.selected
      elseif key == "inactive_color" then
         return colors.text.inactive
      elseif key == "disabled_color" then
         return colors.text.disabled
      elseif key == "button_activated_color" then
         return colors.text.button_activated
      end
   end
})

return text_module
