--defines colors for all ui elements and color manipulation functions

local text = {
  default = 0xFFFFFFFF,
  selected = 0x00c2FFFF,
  disabled = 0x909090FF,
  button_activated = 0x10FF10FF
}

local gauges = {
  outline = 0x000000FF,
  background = 0x00000044,
  valid_fill = 0xc200c8FF,
  cooldown_fill = 0x6800b5FF,
  life = 0x00CD4CFF,
  stun = 0xE60000FF,
  meter = 0x00E6F7FF
}

local parry = {
  text_validity = 0xFFFFFFFF,
  text_success = 0x10FF10FF,
  text_failure = 0xFF1010FF
}

local charge = {
  text_validity = 0xFFFFFFFF,
  text_success = 0x10FF10FF,
  text_failure = 0xFF1010FF,
  overcharge = 0x4900FF80
}

local last_hit_bars = {
  life = 0xFFFFFFFF,
  stun = 0xE60000FF
}

local red_parry_miss = 0xE60000FF

local bonuses = {
  damage = 0xFF7184FF,
  defense = 0xD6E3EFFF,
  stun = 0xD6E3EFFF
}

local gd_color = gd.createTrueColor(1, 1)
local gd_white = gd_color:colorAllocate(255, 255, 255)


local function hex_to_gd_color(hexcolor)
  local r = bit.rshift(bit.band(hexcolor,0xFF000000), 3*8)
  local g = bit.rshift(bit.band(hexcolor,0x00FF0000), 2*8)
  local b = bit.rshift(bit.band(hexcolor,0x0000FF00), 1*8)
--   local a = 127 - bit.rshift(bit.band(hexcolor,0x000000FF), 1) colorAllocateAlpha doesnt seem to work
  return gd_color:colorAllocate(r, g, b)
end

local function substitute_color(image, color_in, color_out)
  local gdStr = image:gdStr()
  local result = gd.createFromGdStr(gdStr)
  for i = 1, image:sizeX() do
    for j = 1, image:sizeY() do
      if result:getPixel(i, j) == color_in then
        result:setPixel(i, j, color_out)
      end
    end
  end
  return result:gdStr()
end

local function colorscale(hex, scalefactor)
  if scalefactor < 0 then
      return hex
  end

  local r = bit.rshift(bit.band(hex,0xFF000000), 3*8)
  local g = bit.rshift(bit.band(hex,0x00FF0000), 2*8)
  local b = bit.rshift(bit.band(hex,0x0000FF00), 1*8)
  local a = bit.band(hex,0x000000FF)

  r = math.floor(clamp(r * scalefactor, 0, 255))
  g = math.floor(clamp(g * scalefactor, 0, 255))
  b = math.floor(clamp(b * scalefactor, 0, 255))

  return tonumber(string.format("0x%02x%02x%02x%02x", r, g, b, a))
end

return{
  text = text,
  gauges = gauges,
  parry = parry,
  charge = charge,
  last_hit_bars = last_hit_bars,
  red_parry_miss = red_parry_miss,
  bouses = bonuses,
  hex_to_gd_color = hex_to_gd_color,
  substitute_color = substitute_color,
  colorscale = colorscale,
  gd_white = gd_white
}