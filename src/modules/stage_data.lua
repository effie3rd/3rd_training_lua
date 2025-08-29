local stages = {
  [0] = {name = "gill", left = 80, right = 943},
  [1] = {name = "alex", left = 80, right = 955},
  [2] = {name = "ryu", left = 80, right = 939},
  [3] = {name = "yun", left = 80, right = 951},
  [4] = {name = "dudley", left = 80, right = 943},
  [5] = {name = "necro", left = 80, right = 943},
  [6] = {name = "hugo", left = 76, right = 945},
  [7] = {name = "ibuki", left = 79, right = 943},
  [8] = {name = "elena", left = 76, right = 935},
  [9] = {name = "oro", left = 76, right = 945},
  [10] = {name = "yang", left = 80, right = 951},
  [11] = {name = "ken", left = 80, right = 955},
  [12] = {name = "sean", left = 76, right = 945},
  [13] = {name = "urien", left = 76, right = 951},
  [14] = {name = "gouki", left = 80, right = 943},
  [15] = {name = "shingouki", left = 80, right = 943},
  [16] = {name = "chunli", left = 70, right = 951},
  [17] = {name = "makoto", left = 84, right = 945},
  [18] = {name = "dudley", left = 80, right = 943},
  [19] = {name = "twelve", left = 80, right = 943},
  [20] = {name = "remy", left = 82, right = 943}
}

local n_stages = 0

local menu_to_stage_map = {}
local menu_stages = {"menu_off","menu_random"}
for i = 0, 20 do
  local name = "menu_" .. stages[i].name
  if not table_contains_deep(menu_stages, name) then
    table.insert(menu_stages, name)
    menu_to_stage_map[#menu_stages] = i
    n_stages = n_stages + 1
  end
end

return {
  stages = stages,
  menu_stages = menu_stages,
  menu_to_stage_map = menu_to_stage_map,
  n_stages = n_stages
}