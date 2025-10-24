-- defines colors for all ui elements and color manipulation functions
require("gd")
local tools = require("src.tools")

local themes

local colors = {
   text = {
      default = 0xFFFFFFFF,
      selected = 0x00c2FFFF,
      inactive = 0x909090FF,
      disabled = 0x909090FF,
      button_activated = 0x10FF10FF
   },
   hud_text = {
      default = 0xFFFFFFFF,
      success = 0x10FF10FF,
      failure = 0xFF1010FF
   },
   gui_text = {default = 0xFFFFFFFF, default_border = 0x000000FF},
   menu = {
      background = 0x1F1F1FF0,
      outline = 0xBBBBBBF0,
      divider = 0xFFFFFF0F,
      gauge_background = 0xFFFFFF22,
      gauge_border = 0x000000FF
   },
   gauges = {
      outline = 0x000000FF,
      background = 0x00000044,
      valid_fill = 0xc200c8FF,
      cooldown_fill = 0x6800b5FF,
      life = 0x00CD4CFF,
      stun = 0xE60000FF,
      meter = 0x00E6F7FF,
      denijn = 0xc200c8FF
   },
   parry = {text_validity = 0xFFFFFFFF, text_success = 0x10FF10FF, text_failure = 0xFF1010FF},
   charge = {text_validity = 0xFFFFFFFF, text_success = 0x10FF10FF, text_failure = 0xFF1010FF, overcharge = 0x4900FF80},
   last_hit_bars = {life = 0xFFFFFFFF, stun = 0xE60000FF},
   red_parry_miss = 0xE60000FF,
   bonuses = {damage = 0xFF7184FF, defense = 0xD6E3EFFF, stun = 0xD6E3EFFF},
   hitboxes = {
      vulnerability = 0x0000FFFF,
      attack = 0xFF0000FF,
      throwable = 0x00FF00FF,
      throw = 0xFFFF00FF,
      push = 0xFF00FFFF,
      extvulnerability = 0x00FFFFFF
   },
   score = {
      plus = 0x00b5FFFF,
      minus = 0x6400FFFF
   }
}

local gd_color = gd.createTrueColor(1, 1)
local gd_white = gd_color:colorAllocate(255, 255, 255)

local function hex_to_gd_color(hexcolor)
   local r = bit.rshift(bit.band(hexcolor, 0xFF000000), 3 * 8)
   local g = bit.rshift(bit.band(hexcolor, 0x00FF0000), 2 * 8)
   local b = bit.rshift(bit.band(hexcolor, 0x0000FF00), 1 * 8)
   --   local a = 127 - bit.rshift(bit.band(hexcolor,0x000000FF), 1) colorAllocateAlpha doesnt seem to work
   return gd_color:colorAllocate(r, g, b)
end

local function substitute_color(image, color_in, color_out)
   local gdStr = image:gdStr()
   local result = gd.createFromGdStr(gdStr)
   for i = 0, image:sizeX() - 1 do
      for j = 0, image:sizeY() - 1 do
         if result:getPixel(i, j) == color_in then result:setPixel(i, j, color_out) end
      end
   end
   return result:gdStr()
end

local function substitute_color_gdstr(gdStr, color_in, color_out)
   local result = gd.createFromGdStr(gdStr)
   for i = 0, result:sizeX() - 1 do
      for j = 0, result:sizeY() - 1 do
         if result:getPixel(i, j) == color_in then result:setPixel(i, j, color_out) end
      end
   end
   return result:gdStr()
end

local function colorscale(hex, scalefactor)
   if scalefactor < 0 then return hex end

   local r = bit.rshift(bit.band(hex, 0xFF000000), 3 * 8)
   local g = bit.rshift(bit.band(hex, 0x00FF0000), 2 * 8)
   local b = bit.rshift(bit.band(hex, 0x0000FF00), 1 * 8)
   local a = bit.band(hex, 0x000000FF)

   r = math.floor(tools.clamp(r * scalefactor, 0, 255))
   g = math.floor(tools.clamp(g * scalefactor, 0, 255))
   b = math.floor(tools.clamp(b * scalefactor, 0, 255))

   return tonumber(string.format("0x%02x%02x%02x%02x", r, g, b, a))
end

local function set_theme(index)
   colors = themes[index].colors
end

local colors_module = {
   hex_to_gd_color = hex_to_gd_color,
   substitute_color = substitute_color,
   substitute_color_gdstr = substitute_color_gdstr,
   colorscale = colorscale,
   gd_white = gd_white,
   set_theme = set_theme
}

setmetatable(colors_module, {
   __index = function(_, key)
      if colors[key] then
         return colors[key]
      elseif key == "themes" then
         return themes
      end
   end,

   __newindex = function(_, key, value)
      if colors[key] then
         colors[key] = value
      elseif key == "themes" then
         themes = value
      else
         rawset(colors_module, key, value)
      end
   end
})

return colors_module
