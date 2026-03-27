require("gd")
local images = {}
local text = {}

local is_loaded = false

local controller_styles = {
   "hyper_reflector", "rose", "cherry", "blueberry", "sky", "blood_orange", "salmon", "grape", "lavender", "lemon",
   "champagne", "matcha", "lime", "retro_scifi", "watermelon", "macaron", "famicom", "van_gogh", "munch", "hokusai",
   "monet", "dali", "classic", "2077", "aurora", "ursa_major", "pillars_of_creation", "sunset", "fly_by_night", "lake",
   "traffic_lights", "warm_rainbow", "soft_rainbow", "pearl", "beach", "nether", "blue_planet", "poison", "moon",
   "blood_moon", "volcano", "desert_sun", "canyon", "acid", "dawn", "picnic", "gelato", "patrick", "01", "dungeon",
   "skeleton", "beholder", "cthulu", "ghost", "shroom", "totem", "dream_tree", "neon", "windbreaker", "curiosity",
   "shock", "signal", "berry_nebula", "toxic", "citrine", "voltage", "chill", "neapolitan", "candy_castle", "concord",
   "cyber_gum", "powder", "fluffy", "matsuri", "joker", "koi", "pale_sunset", "mars", "primary", "sunbeam", "orchid",
   "sepia", "night_sky", "desert_night"
}

local controller_style_menu_names = {}
for i, name in ipairs(controller_styles) do
   controller_style_menu_names[#controller_style_menu_names + 1] = "style_" .. name
end

local function build_images()
   local colors = require("src.ui.colors")

   -- big is for  controller display
   -- small is for input history
   local image_files = {
      "images/controller/1_dir_b.png", "images/controller/2_dir_b.png", "images/controller/3_dir_b.png",
      "images/controller/4_dir_b.png", "images/controller/5_dir_b.png", "images/controller/6_dir_b.png",
      "images/controller/7_dir_b.png", "images/controller/8_dir_b.png", "images/controller/9_dir_b.png",
      "images/controller/1_dir_s.png", "images/controller/2_dir_s.png", "images/controller/3_dir_s.png",
      "images/controller/4_dir_s.png", "images/controller/5_dir_s.png", "images/controller/6_dir_s.png",
      "images/controller/7_dir_s.png", "images/controller/8_dir_s.png", "images/controller/9_dir_s.png",
      "images/controller/2_dir_s_inactive.png", "images/controller/4_dir_s_inactive.png",
      "images/controller/6_dir_s_inactive.png", "images/controller/8_dir_s_inactive.png",
      "images/controller/no_button_b.png", "images/controller/hold.png", "images/controller/maru.png",
      "images/controller/square_hollow.png", "images/controller/square_filled.png", "images/controller/tilda.png",
      "images/controller/scroll_up.png", "images/controller/scroll_down.png", "images/controller/tri_arrow_down.png",
      "images/controller/dot.png", "images/controller/shield.png"
   }
   local result = {}

   for _, file_path in ipairs(image_files) do
      local file_name = file_path:match("([^/]+)%.png$")
      local png = gd.createFromPng(file_path)
      result["img_" .. file_name] = {width = png:sizeX(), height = png:sizeY(), [colors.white] = png:gdStr()}
   end

   local button_prefixes = {
      "LP_s", "MP_s", "HP_s", "LK_s", "MK_s", "HK_s", "LP_b", "MP_b", "HP_b", "LK_b", "MK_b", "HK_b"
   }

   for i = 1, #controller_styles do
      local style_name = controller_styles[i]
      for _, prefix in ipairs(button_prefixes) do
         local file_path = "images/controller/" .. prefix .. "_" .. style_name .. ".png"
         local name = "img_" .. prefix
         local png = gd.createFromPng(file_path)
         if not result[name] then result[name] = {} end
         result[name].width = png:sizeX()
         result[name].height = png:sizeY()
         result[name][style_name] = png:gdStr()
      end
      result.img_no_button_b[style_name] = result.img_no_button_b[colors.white]
   end

   return result
end

local img_str_dir_big = {
   "img_1_dir_b", "img_2_dir_b", "img_3_dir_b", "img_4_dir_b", "img_5_dir_b", "img_6_dir_b", "img_7_dir_b",
   "img_8_dir_b", "img_9_dir_b"
}
local img_str_dir_small = {
   "img_1_dir_s", "img_2_dir_s", "img_3_dir_s", "img_4_dir_s", "img_5_dir_s", "img_6_dir_s", "img_7_dir_s",
   "img_8_dir_s", "img_9_dir_s"
}
local img_str_dir_inactive = {
   [2] = "img_2_dir_s_inactive",
   [4] = "img_4_dir_s_inactive",
   [6] = "img_6_dir_s_inactive",
   [8] = "img_8_dir_s_inactive"
}

local image_tables = {
   images = images,
   text = text,
   build_images = build_images,
   controller_styles = controller_styles,
   controller_style_menu_names = controller_style_menu_names,
   img_str_dir_big = img_str_dir_big,
   img_str_dir_small = img_str_dir_small,
   img_str_dir_inactive = img_str_dir_inactive
}

setmetatable(image_tables, {
   __index = function(_, key) if key == "is_loaded" then return is_loaded end end,

   __newindex = function(_, key, value)
      if key == "is_loaded" then
         is_loaded = value
      else
         rawset(image_tables, key, value)
      end
   end
})

return image_tables
