require("src/libs/utf8")
im = {}
text_image_default_color = "white"
text_image_selected_color = "red"
text_image_disabled_color = "grey"

function load_menu_images()
  _map = read_object_from_json_file("images/menu/image_map.json")
  colors = {"white", "red", "green", "grey"}
  im = {}
  for name,data in pairs(map) do
    im[name] = {}
    im[name].en = {}
    im[name].jp = {}
    for _,color in pairs(colors) do
      im[name].en[color] = gd.createFromPng(map[name].en[color])
      im[name].jp[color] = gd.createFromPng(map[name].jp[color])

      im[name].en.width = im[name].en[color]:sizeX()
      im[name].en.height = im[name].en[color]:sizeY()
      im[name].jp.width = im[name].jp[color]:sizeX()
      im[name].jp.height = im[name].jp[color]:sizeY()

      im[name].en[color] = im[name].en[color]:gdStr()
      im[name].jp[color] = im[name].jp[color]:gdStr()
    end
  end
end



function text_image_menu_item(name)
  local o = {}
  o.name = name

  function o:draw(x, y, _state)
    local color = text_image_default_color
    if _state == "active" then
      color = text_image_default_color
    elseif _state == "selected" then
      color = text_image_selected_color
    elseif _state == "disabled" then
      color = text_image_disabled_color
    end
    local _img = im[name][training_settings.language][color]

    gui.image(x, y, _img)
  end

  function o:is_image()
    return true
  end

  function o:width()
    return im[name][training_settings.language].width
  end

  function o:height()
    return im[name][training_settings.language].height
  end

  return o
end

function number_display(num, x, y)
  local offset = 0
  for _i=1,string.len(num) do
    local digit = string.sub(num, _i, _i)
    gui.image(x + offset, y, im[digit].en.green)
    offset = offset + im[digit].en.width - 1
  end
end


load_menu_images()
v = utf8.codepoint("ル")
print(string.format("%s",v))

