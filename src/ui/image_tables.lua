require "gd"

-- big is for  controller display
-- small is for input history
local img_1_dir_big = gd.createFromPng("images/controller/1_dir_b.png"):gdStr()
local img_2_dir_big = gd.createFromPng("images/controller/2_dir_b.png"):gdStr()
local img_3_dir_big = gd.createFromPng("images/controller/3_dir_b.png"):gdStr()
local img_4_dir_big = gd.createFromPng("images/controller/4_dir_b.png"):gdStr()
local img_5_dir_big = gd.createFromPng("images/controller/5_dir_b.png"):gdStr()
local img_6_dir_big = gd.createFromPng("images/controller/6_dir_b.png"):gdStr()
local img_7_dir_big = gd.createFromPng("images/controller/7_dir_b.png"):gdStr()
local img_8_dir_big = gd.createFromPng("images/controller/8_dir_b.png"):gdStr()
local img_9_dir_big = gd.createFromPng("images/controller/9_dir_b.png"):gdStr()
local img_no_button_big = gd.createFromPng("images/controller/no_button_b.png"):gdStr()

local img_dir_big = {
   img_1_dir_big, img_2_dir_big, img_3_dir_big, img_4_dir_big, img_5_dir_big, img_6_dir_big, img_7_dir_big,
   img_8_dir_big, img_9_dir_big
}

local img_1_dir_small = gd.createFromPng("images/controller/1_dir_s.png"):gdStr()
local img_2_dir_small = gd.createFromPng("images/controller/2_dir_s.png"):gdStr()
local img_3_dir_small = gd.createFromPng("images/controller/3_dir_s.png"):gdStr()
local img_4_dir_small = gd.createFromPng("images/controller/4_dir_s.png"):gdStr()
local img_5_dir_small = gd.createFromPng("images/controller/5_dir_s.png"):gdStr()
local img_6_dir_small = gd.createFromPng("images/controller/6_dir_s.png"):gdStr()
local img_7_dir_small = gd.createFromPng("images/controller/7_dir_s.png"):gdStr()
local img_8_dir_small = gd.createFromPng("images/controller/8_dir_s.png"):gdStr()
local img_9_dir_small = gd.createFromPng("images/controller/9_dir_s.png"):gdStr()

local img_dir_small = {
   img_1_dir_small, img_2_dir_small, img_3_dir_small, img_4_dir_small, img_5_dir_small, img_6_dir_small,
   img_7_dir_small, img_8_dir_small, img_9_dir_small
}

local dir_2_inactive = gd.createFromPng("images/controller/2_dir_s_inactive.png"):gdStr()
local dir_4_inactive = gd.createFromPng("images/controller/4_dir_s_inactive.png"):gdStr()
local dir_6_inactive = gd.createFromPng("images/controller/6_dir_s_inactive.png"):gdStr()
local dir_8_inactive = gd.createFromPng("images/controller/8_dir_s_inactive.png"):gdStr()

local img_dir_inactive = {[2] = dir_2_inactive, [4] = dir_4_inactive, [6] = dir_6_inactive, [8] = dir_8_inactive}

local controller_styles = {
   "rose", "cherry", "blueberry", "sky", "blood_orange", "salmon", "grape", "lavender", "lemon", "champagne", "matcha",
   "lime", "retro_scifi", "watermelon", "macaron", "famicom", "van_gogh", "munch", "hokusai", "monet", "dali",
   "classic", "hyper_reflector", "cyberpunk", "2077", "aurora", "ursa_major", "crab_nebula", "pillars_of_creation",
   "sunset", "fly_by_night", "lake", "airplane", "warm_rainbow", "soft_rainbow", "pearl", "beach", "nether",
   "blue_planet", "poison", "moon", "blood_moon", "volcano", "desert_sun", "canyon", "redgreen", "acid", "dawn",
   "picnic", "gelato", "patrick", "01"
}

local img_button_small = {}
local img_button_big = {}

for i = 1, #controller_styles do
   local name = controller_styles[i]
   img_button_small[name] = {}
   table.insert(img_button_small[name], gd.createFromPng("images/controller/LP_s_" .. name .. ".png"):gdStr())
   table.insert(img_button_small[name], gd.createFromPng("images/controller/MP_s_" .. name .. ".png"):gdStr())
   table.insert(img_button_small[name], gd.createFromPng("images/controller/HP_s_" .. name .. ".png"):gdStr())
   table.insert(img_button_small[name], gd.createFromPng("images/controller/LK_s_" .. name .. ".png"):gdStr())
   table.insert(img_button_small[name], gd.createFromPng("images/controller/MK_s_" .. name .. ".png"):gdStr())
   table.insert(img_button_small[name], gd.createFromPng("images/controller/HK_s_" .. name .. ".png"):gdStr())
   img_button_big[name] = {}
   table.insert(img_button_big[name], gd.createFromPng("images/controller/LP_b_" .. name .. ".png"):gdStr())
   table.insert(img_button_big[name], gd.createFromPng("images/controller/MP_b_" .. name .. ".png"):gdStr())
   table.insert(img_button_big[name], gd.createFromPng("images/controller/HP_b_" .. name .. ".png"):gdStr())
   table.insert(img_button_big[name], gd.createFromPng("images/controller/LK_b_" .. name .. ".png"):gdStr())
   table.insert(img_button_big[name], gd.createFromPng("images/controller/MK_b_" .. name .. ".png"):gdStr())
   table.insert(img_button_big[name], gd.createFromPng("images/controller/HK_b_" .. name .. ".png"):gdStr())
end

local img_hold = gd.createFromPng("images/controller/hold_s.png"):gdStr()
local img_maru = gd.createFromPng("images/controller/maru_s.png"):gdStr()
local img_kaku = gd.createFromPng("images/controller/kaku_s.png"):gdStr()
local img_tilda = gd.createFromPng("images/controller/tilda_s.png"):gdStr()
local scroll_up_arrow = gd.createFromPng("images/menu/scroll_up.png"):gdStr()
local scroll_down_arrow = gd.createFromPng("images/menu/scroll_down.png"):gdStr()
local img_dot = gd.createFromPng("images/controller/dot.png"):gdStr()

local draw = {controller_styles = controller_styles}

setmetatable(draw, {
   __index = function(_, key)
      if key == "img_dir_big" then
         return img_dir_big
      elseif key == "img_dir_small" then
         return img_dir_small
      elseif key == "img_dir_inactive" then
         return img_dir_inactive
      elseif key == "img_button_small" then
         return img_button_small
      elseif key == "img_button_big" then
         return img_button_big
      elseif key == "img_no_button_big" then
         return img_no_button_big
      elseif key == "img_hold" then
         return img_hold
      elseif key == "img_maru" then
         return img_maru
      elseif key == "img_kaku" then
         return img_kaku
      elseif key == "img_tilda" then
         return img_tilda
      elseif key == "scroll_up_arrow" then
         return scroll_up_arrow
      elseif key == "scroll_down_arrow" then
         return scroll_down_arrow
      elseif key == "img_dot" then
         return img_dot
      end
   end
})

return draw
