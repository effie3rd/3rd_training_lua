require("gd")
local images = {}
local text = {}

local controller_styles = {
   "hyper_reflector", "rose", "cherry", "blueberry", "sky", "blood_orange", "salmon", "grape", "lavender", "lemon",
   "champagne", "matcha", "lime", "retro_scifi", "watermelon", "macaron", "famicom", "van_gogh", "munch", "hokusai",
   "monet", "dali", "classic", "2077", "aurora", "ursa_major", "pillars_of_creation", "sunset", "fly_by_night", "lake",
   "traffic_lights", "warm_rainbow", "soft_rainbow", "pearl", "beach", "nether", "blue_planet", "poison", "moon",
   "blood_moon", "volcano", "desert_sun", "canyon", "acid", "dawn", "picnic", "gelato", "patrick", "01"
}
local controller_style_menu_names = {}
for i, name in ipairs(controller_styles) do controller_style_menu_names[#controller_style_menu_names + 1] = "style_" .. name end

local function build_images()
   -- big is for  controller display
   -- small is for input history
   local result = {
      img_1_dir_big = gd.createFromPng("images/controller/1_dir_b.png"):gdStr(),
      img_2_dir_big = gd.createFromPng("images/controller/2_dir_b.png"):gdStr(),
      img_3_dir_big = gd.createFromPng("images/controller/3_dir_b.png"):gdStr(),
      img_4_dir_big = gd.createFromPng("images/controller/4_dir_b.png"):gdStr(),
      img_5_dir_big = gd.createFromPng("images/controller/5_dir_b.png"):gdStr(),
      img_6_dir_big = gd.createFromPng("images/controller/6_dir_b.png"):gdStr(),
      img_7_dir_big = gd.createFromPng("images/controller/7_dir_b.png"):gdStr(),
      img_8_dir_big = gd.createFromPng("images/controller/8_dir_b.png"):gdStr(),
      img_9_dir_big = gd.createFromPng("images/controller/9_dir_b.png"):gdStr(),
      img_no_button_big = gd.createFromPng("images/controller/no_button_b.png"):gdStr(),

      img_1_dir_small = gd.createFromPng("images/controller/1_dir_s.png"):gdStr(),
      img_2_dir_small = gd.createFromPng("images/controller/2_dir_s.png"):gdStr(),
      img_3_dir_small = gd.createFromPng("images/controller/3_dir_s.png"):gdStr(),
      img_4_dir_small = gd.createFromPng("images/controller/4_dir_s.png"):gdStr(),
      img_5_dir_small = gd.createFromPng("images/controller/5_dir_s.png"):gdStr(),
      img_6_dir_small = gd.createFromPng("images/controller/6_dir_s.png"):gdStr(),
      img_7_dir_small = gd.createFromPng("images/controller/7_dir_s.png"):gdStr(),
      img_8_dir_small = gd.createFromPng("images/controller/8_dir_s.png"):gdStr(),
      img_9_dir_small = gd.createFromPng("images/controller/9_dir_s.png"):gdStr(),

      dir_2_inactive = gd.createFromPng("images/controller/2_dir_s_inactive.png"):gdStr(),
      dir_4_inactive = gd.createFromPng("images/controller/4_dir_s_inactive.png"):gdStr(),
      dir_6_inactive = gd.createFromPng("images/controller/6_dir_s_inactive.png"):gdStr(),
      dir_8_inactive = gd.createFromPng("images/controller/8_dir_s_inactive.png"):gdStr(),

      img_button_small = {},
      img_button_big = {}
   }

   result.img_dir_big = {
      result.img_1_dir_big, result.img_2_dir_big, result.img_3_dir_big, result.img_4_dir_big, result.img_5_dir_big,
      result.img_6_dir_big, result.img_7_dir_big, result.img_8_dir_big, result.img_9_dir_big
   }
   result.img_dir_small = {
      result.img_1_dir_small, result.img_2_dir_small, result.img_3_dir_small, result.img_4_dir_small,
      result.img_5_dir_small, result.img_6_dir_small, result.img_7_dir_small, result.img_8_dir_small,
      result.img_9_dir_small
   }
   result.img_dir_inactive = {
      [2] = result.dir_2_inactive,
      [4] = result.dir_4_inactive,
      [6] = result.dir_6_inactive,
      [8] = result.dir_8_inactive
   }

   for i = 1, #controller_styles do
      local name = controller_styles[i]
      result.img_button_small[name] = {}
      result.img_button_small[name][#result.img_button_small[name] + 1] = gd.createFromPng("images/controller/LP_s_" .. name .. ".png"):gdStr()
      result.img_button_small[name][#result.img_button_small[name] + 1] = gd.createFromPng("images/controller/MP_s_" .. name .. ".png"):gdStr()
      result.img_button_small[name][#result.img_button_small[name] + 1] = gd.createFromPng("images/controller/HP_s_" .. name .. ".png"):gdStr()
      result.img_button_small[name][#result.img_button_small[name] + 1] = gd.createFromPng("images/controller/LK_s_" .. name .. ".png"):gdStr()
      result.img_button_small[name][#result.img_button_small[name] + 1] = gd.createFromPng("images/controller/MK_s_" .. name .. ".png"):gdStr()
      result.img_button_small[name][#result.img_button_small[name] + 1] = gd.createFromPng("images/controller/HK_s_" .. name .. ".png"):gdStr()
      result.img_button_big[name] = {}
      result.img_button_big[name][#result.img_button_big[name] + 1] = gd.createFromPng("images/controller/LP_b_" .. name .. ".png"):gdStr()
      result.img_button_big[name][#result.img_button_big[name] + 1] = gd.createFromPng("images/controller/MP_b_" .. name .. ".png"):gdStr()
      result.img_button_big[name][#result.img_button_big[name] + 1] = gd.createFromPng("images/controller/HP_b_" .. name .. ".png"):gdStr()
      result.img_button_big[name][#result.img_button_big[name] + 1] = gd.createFromPng("images/controller/LK_b_" .. name .. ".png"):gdStr()
      result.img_button_big[name][#result.img_button_big[name] + 1] = gd.createFromPng("images/controller/MK_b_" .. name .. ".png"):gdStr()
      result.img_button_big[name][#result.img_button_big[name] + 1] = gd.createFromPng("images/controller/HK_b_" .. name .. ".png"):gdStr()
   end

   result.img_hold = gd.createFromPng("images/controller/hold_s.png"):gdStr()
   result.img_maru = gd.createFromPng("images/controller/maru_s.png"):gdStr()
   result.img_kaku = gd.createFromPng("images/controller/kaku_s.png"):gdStr()
   result.img_tilda = gd.createFromPng("images/controller/tilda_s.png"):gdStr()
   result.img_scroll_up = gd.createFromPng("images/menu/menu_scroll_up.png"):gdStr()
   result.img_scroll_down = gd.createFromPng("images/menu/menu_scroll_down.png"):gdStr()
   result.img_tri_down = gd.createFromPng("images/controller/tri_arrow_down.png"):gdStr()
   result.img_dot = gd.createFromPng("images/controller/dot.png"):gdStr()

   return result
end


local check_box_width = 9
local check_box_height = 9
local scroll_arrow_width = 7
local scroll_arrow_height = 5
local dir_small_width = 9
local dir_small_height = 9
local tri_arrow_width = 9
local tri_arrow_height = 6

local image_tables = {
   images = images,
   text = text,
   build_images = build_images,
   controller_styles = controller_styles,
   controller_style_menu_names = controller_style_menu_names,
   check_box_width = check_box_width,
   check_box_height = check_box_height,
   scroll_arrow_width = scroll_arrow_width,
   scroll_arrow_height = scroll_arrow_height,
   dir_small_width = dir_small_width,
   dir_small_height = dir_small_height,
   tri_arrow_width = tri_arrow_width,
   tri_arrow_height = tri_arrow_height
}

return image_tables
