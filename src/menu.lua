require("src/libs/utf8")

im = {}
text_image_default_color = "white"
text_image_selected_color = 0x00c2FFFF
text_image_disabled_color = 0x909090FF
button_activated_color = 0x00FF00FF

loc = read_object_from_json_file("images/menu/localization.json")
move_list = read_object_from_json_file("data/sfiii3nr1/move_list.json")
im_json_data = read_object_from_json_file("images/menu/image_map.json")
n_im_json_data = 0
for _k ,_v in pairs(im_json_data) do
  n_im_json_data = n_im_json_data + 1
end

gd_color = gd.createTrueColor(1, 1)
gd_white = gd_color:colorAllocate(255, 255, 255)
gd_green = gd_color:colorAllocate(50, 255, 50)
gd_red = gd_color:colorAllocate(255, 0, 0)
gd_grey = gd_color:colorAllocate(144, 144, 144)

color_red = 0xFF1010FF
color_green = 0x10FF10FF

function load_text_images(_filepath)
  _map = read_object_from_json_file(_filepath)
  for _code,_data in pairs(_map) do
    im[_code] = {}
    for _lang,_path in pairs(_map[_code]) do
      im[_code][_lang] = {}
      local _png = gd.createFromPng(_path)

      im[_code][_lang].base_image = _png
      im[_code][_lang].width = _png:sizeX()
      im[_code][_lang].height = _png:sizeY()

      local _gdStr = _png:gdStr()
      im[_code][_lang][text_image_default_color] = gd.createFromGdStr(_gdStr)
      im[_code][_lang][text_image_selected_color] = gd.createFromGdStr(_gdStr)
      im[_code][_lang][text_image_disabled_color] = gd.createFromGdStr(_gdStr)

      local gd_selected_color = hex_to_gd_color(text_image_selected_color)
      local gd_disabled_color = hex_to_gd_color(text_image_disabled_color)
      for i = 1, im[_code][_lang].width do
        for j = 1, im[_code][_lang].height do
          if im[_code][_lang].base_image:getPixel(i, j) == gd_white then
            im[_code][_lang][text_image_selected_color]:setPixel(i, j, gd_selected_color)
            im[_code][_lang][text_image_disabled_color]:setPixel(i, j, gd_disabled_color)
          end
        end
      end

      im[_code][_lang][text_image_default_color] = im[_code][_lang][text_image_default_color]:gdStr()
      im[_code][_lang][text_image_selected_color] = im[_code][_lang][text_image_selected_color]:gdStr()
      im[_code][_lang][text_image_disabled_color] = im[_code][_lang][text_image_disabled_color]:gdStr()
    end
  end
end

function load_text_image(_data, _code)
  im[_code] = {}
  for _lang,_path in pairs(_data[_code]) do
    im[_code][_lang] = {}
    local _png = gd.createFromPng(_path)

    im[_code][_lang].base_image = _png
    im[_code][_lang].width = _png:sizeX()
    im[_code][_lang].height = _png:sizeY()

    local _gdStr = _png:gdStr()
    im[_code][_lang][text_image_default_color] = gd.createFromGdStr(_gdStr)
    im[_code][_lang][text_image_selected_color] = gd.createFromGdStr(_gdStr)
    im[_code][_lang][text_image_disabled_color] = gd.createFromGdStr(_gdStr)

    local gd_selected_color = hex_to_gd_color(text_image_selected_color)
    local gd_disabled_color = hex_to_gd_color(text_image_disabled_color)
    for i = 1, im[_code][_lang].width do
      for j = 1, im[_code][_lang].height do
        if im[_code][_lang].base_image:getPixel(i, j) == gd_white then
          im[_code][_lang][text_image_selected_color]:setPixel(i, j, gd_selected_color)
          im[_code][_lang][text_image_disabled_color]:setPixel(i, j, gd_disabled_color)
        end
      end
    end

    im[_code][_lang][text_image_default_color] = im[_code][_lang][text_image_default_color]:gdStr()
    im[_code][_lang][text_image_selected_color] = im[_code][_lang][text_image_selected_color]:gdStr()
    im[_code][_lang][text_image_disabled_color] = im[_code][_lang][text_image_disabled_color]:gdStr()
  end
end

function hex_to_gd_color(_hexcolor)
  local r = bit.rshift(bit.band(_hexcolor,0xFF000000), 3*8)
  local g = bit.rshift(bit.band(_hexcolor,0x00FF0000), 2*8)
  local b = bit.rshift(bit.band(_hexcolor,0x0000FF00), 1*8)
--   local a = 127 - bit.rshift(bit.band(_hexcolor,0x000000FF), 1) colorAllocateAlpha doesnt seem to work
  return gd_color:colorAllocate(r, g, b)
end
function substitute_color(_image, _color_in, _color_out)
  local _gdStr = _image:gdStr()
  local _result = gd.createFromGdStr(_gdStr)
  for i = 1, _image:sizeX() do
    for j = 1, _image:sizeY() do
      if _result:getPixel(i, j) == _color_in then
        _result:setPixel(i, j, _color_out)
      end
    end
  end
  return _result:gdStr()
end


function header_menu_item(_name)
  local _o = {}
  _o.name = _name
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _state)
    local _color = text_image_default_color
    if _state == "active" then
      _color = text_image_default_color
    elseif _state == "selected" then
      _color = text_image_selected_color
    elseif _state == "disabled" then
      _color = text_image_disabled_color
    end

    render_text(_x, _y, self.name, nil, nil, _color)
  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions(self.name)
  end

  _o:calc_dimensions()

  return _o
end

function footer_menu_item(_name)
  local _o = {}
  _o.name = _name
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _state)
    local _color = text_image_disabled_color
    render_text(_x, _y, self.name, lang_code[training_settings.language], nil, _color)
  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions(self.name)
  end

  _o:calc_dimensions()

  return _o
end

function label_menu_item(_name, _inline)
  local _o = {}
  _o.name = _name
  _o.inline = _inline or false
  _o.unselectable = true
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y, _state)
    local _color = text_image_disabled_color

    render_text(_x, _y, self.name, nil, nil, _color)

  end

  function _o:calc_dimensions()
    self.width, self.height = get_text_dimensions(self.name)
  end

  _o:calc_dimensions()

  return _o
end

function frame_number_item(_obj, _inline)
  local _o = {}
  _o.obj = _obj
  _o.inline = _inline or false
  _o.unselectable = true
  _o.width = 0
  _o.height = 0

  function _o:draw(_x, _y)
    local _color = text_image_disabled_color
    if lang_code[training_settings.language] == "en" then
      render_text_multiple(_x, _y, {self.obj[1], " ", "frames"}, nil, nil, _color)
    elseif lang_code[training_settings.language] == "jp" then
      render_text_multiple(_x, _y + 3, {self.obj[1], " ", "frames"}, "jp", "8", _color)
    end
  end

  function _o:calc_dimensions()
    if lang_code[training_settings.language] == "en" then
      self.width, self.height = get_text_dimensions_multiple({self.obj[1], " ", "frames"})
    elseif lang_code[training_settings.language] == "jp" then
      self.width, self.height = get_text_dimensions_multiple({self.obj[1], " ", "frames"}, "jp", "8")
--       print(self.width, self.height)
    end
  end

  _o:calc_dimensions()

  return _o
end

function draw_text(_x, _y, _str, _lang, _size, _color, _opacity)
  if _size and string.sub(_str, 1, 3) == "utf" then
    _lang = _lang .. "_" .. _size
  end
  if im[_str][_lang][_color] then
    gui.image(_x, _y, im[_str][_lang][_color], _opacity)
  else
    local _gd_color = hex_to_gd_color(_color)
    local _img = substitute_color(im[_str][_lang].base_image, gd_white, _gd_color)
    gui.image(_x, _y, _img, _opacity)
  end
end

function render_text_jp(_x, _y, _str, _lang, _size, _color, _opacity)
  local _offset = 0
  _lang = _lang or "jp"
  _color = _color or "white"
  _opacity = _opacity or 1
  for _k, _v in utf8.codes(_str) do
    local _code = utf8.codepoint(_v)
    if _code ~= 32 then --not space
      _code = "utf_" .. tostring(_code)
      draw_text(_x + _offset, _y, _code, _lang, _size, _color, _opacity)
      _offset = _offset + im[_code][_lang].width - 1
    else
      _offset = _offset + 2
    end
  end
end

function render_text(_x, _y, _str, _lang, _size, _color, _opacity)
  local _offset = 0
  _str = tostring(_str)
  _lang = _lang or lang_code[training_settings.language]
  _color = _color or "white"
  _opacity = _opacity or 1
  for _k, _v in utf8.codes(_str) do
    local _code = utf8.codepoint(_v)
    --char is jp
    if _code >= 12288 and _code <= 40879 then
      --render individual jp characters
      render_text_jp(_x, _y, _str, _lang, _size, _color, _opacity)
      return
    end
  end
  --str is not jp, draw block of text if it exists
  if im[_str] then
    draw_text(_x + _offset, _y, _str, _lang, _size, _color, _opacity)
    return
  end

  --render individual characters
  local _lang_ext = _lang
  if _size then
    _lang_ext = _lang_ext .. "_" .. _size
  end
  for _k, _v in utf8.codes(_str) do
    local _code = utf8.codepoint(_v)
    if _code ~= 32 then --not space
      _code = "utf_" .. tostring(_code)
      draw_text(_x + _offset, _y, _code, _lang, _size, _color, _opacity)
      _offset = _offset + im[_code][_lang_ext].width - 1
    else
      _offset = _offset + 2
    end
  end
end

function get_text_dimensions_jp(_str, _lang, _size)
  local _w = 0
  local _h = 0
  _lang = _lang or "jp"
  if _size then _lang = _lang .. "_" .. _size end
  for _k, _v in utf8.codes(_str) do
    local _code = "utf_" .. utf8.codepoint(_v)
    if _code ~= 32 then
      _w = _w + im[_code][_lang].width
      _h = im[_code][_lang].height
    else
      _w = _w + 3
    end
  end
  _w = _w - utf8.len(_str) + 1
  return _w, _h
end

function get_text_dimensions(_str, _lang, _size)
  local _w = 0
  local _h = 0
  _str = tostring(_str)
  _lang = _lang or lang_code[training_settings.language]
  for _k, _v in utf8.codes(_str) do
    local _code = utf8.codepoint(_v)
    --char is jp
    if _code >= 12288 and _code <= 40879 then
      local _w, _h = get_text_dimensions_jp(_str, _lang, _size)
      return _w, _h
    end
  end
  --str is not jp, get size of block of text
  if im[_str] then
    return im[_str][_lang].width, im[_str][_lang].height
  end

  if _size then _lang = _lang .. "_" .. _size end
  for _k, _v in utf8.codes(_str) do
    local _code = utf8.codepoint(_v)
    if _code ~= 32 then
      _code = "utf_" .. tostring(_code)
      _w = _w + im[_code][_lang].width
      _h = im[_code][_lang].height
    else
      _w = _w + 3
    end
  end
  if _str ~= "" then
    _w = _w - utf8.len(_str) + 1
  end
  return _w, _h
end

function render_text_multiple(_x, _y, _list_str, _lang, _size, _color, _opacity)
  local _offset_x = 0
  for _,_str in pairs(_list_str) do
    render_text(_x + _offset_x, _y, _str, _lang, _size, _color, _opacity)
    local _tw, _th = get_text_dimensions(_str, _lang, _size)
    _offset_x = _offset_x + _tw
  end
end

function get_text_dimensions_multiple(_list_str, _lang, _size)
  local _w = 0
  local _h = 0
  for _,_str in pairs(_list_str) do
    local _tw, _th = get_text_dimensions(_str, _lang, _size)
    _w = _w + _tw
    _h = math.max(_h, _th)
  end
  return _w, _h
end

load_text_images("images/menu/load_first.json")
