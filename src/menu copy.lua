require("src/libs/utf8")
im = {}
text_image_default_color = "white"
text_image_selected_color = "red"
text_image_disabled_color = "grey"

function load_menu_images()
  _map = read_object_from_json_file("images/menu/image_map.json")
  _colors = {"white", "red", "green", "grey"}
  im = {}
  for _name,_data in pairs(_map) do
    im[_name] = {}
    im[_name].en = {}
    im[_name].jp = {}
    for _,_color in pairs(_colors) do
      im[_name].en[_color] = gd.createFromPng(_map[_name].en[_color])
      im[_name].jp[_color] = gd.createFromPng(_map[_name].jp[_color])

      im[_name].en.width = im[_name].en[_color]:sizeX()
      im[_name].en.height = im[_name].en[_color]:sizeY()
      im[_name].jp.width = im[_name].jp[_color]:sizeX()
      im[_name].jp.height = im[_name].jp[_color]:sizeY()

      im[_name].en[_color] = im[_name].en[_color]:gdStr()
      im[_name].jp[_color] = im[_name].jp[_color]:gdStr()
    end
  end
end



function text_image_menu_item(_name)
  local _o = {}
  _o.name = _name

  function _o:draw(_x, _y, _state)
    local _color = text_image_default_color
    if _state == "active" then
      _color = text_image_default_color
    elseif _state == "selected" then
      _color = text_image_selected_color
    elseif _state == "disabled" then
      _color = text_image_disabled_color
    end
    local _img = im[_name][training_settings.language][_color]

    gui.image(_x, _y, _img)
  end

  function _o:is_image()
    return true
  end

  function _o:width()
    return im[_name][training_settings.language].width
  end

  function _o:height()
    return im[_name][training_settings.language].height
  end

  return _o
end

function number_display(_num, _x, _y)
  local _offset = 0
  for _i=1,string.len(_num) do
    local _digit = string.sub(_num, _i, _i)
    gui.image(_x + _offset, _y, im[_digit].en.green)
    _offset = _offset + im[_digit].en.width - 1
  end
end


load_menu_images()
v = utf8.codepoint("ル")
print(string.format("%s",v))

