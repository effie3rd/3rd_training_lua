local tools = require("src.tools")

local move_list = tools.read_object_from_json_file("data/move_list.json")

local function get_move_inputs_by_name(char, name, button)
   local sequence = {}
   for _, move in pairs(move_list[char]) do
      if move.name == name then
         sequence = tools.deepcopy(move.input)
         break
      end
   end

   if button then
      local i = 1
      while i <= #sequence do
         local j = 1
         while j <= #sequence[i] do
            if sequence[i][j] == "button" then
               if button == "EXP" then
                  table.remove(sequence[i], j)
                  table.insert(sequence[i], j, "MP")
                  table.insert(sequence[i], j, "LP")
               elseif button == "EXK" then
                  table.remove(sequence[i], j)
                  table.insert(sequence[i], j, "MK")
                  table.insert(sequence[i], j, "LK")
               elseif button == "PPP" then
                  table.remove(sequence[i], j)
                  table.insert(sequence[i], j, "HP")
                  table.insert(sequence[i], j, "MP")
                  table.insert(sequence[i], j, "LP")
               elseif button == "KKK" then
                  table.remove(sequence[i], j)
                  table.insert(sequence[i], j, "HK")
                  table.insert(sequence[i], j, "MK")
                  table.insert(sequence[i], j, "LK")
               else
                  table.remove(sequence[i], j)
                  table.insert(sequence[i], j, button)
               end
            else
               j = j + 1
            end
         end
         i = i + 1
      end
      if name == "hyakuretsukyaku" then
         if button == "EXK" then
            sequence = {{"legs_" .. button, "LK", "MK"}}
         else
            sequence = {{"legs_" .. button, button}}
         end
      end
   end
   return sequence
end

local function get_special_and_sa_names(char, sa)
   local result = {}
   for i = 1, #move_list[char] do
      local move_type = move_list[char][i].move_type
      local name = move_list[char][i].name
      if move_type == "special" or move_type == "kara_special" or move_type == ("sa" .. sa) or
          (char == "gouki" and (name == "sgs" or name == "kkz")) or (char == "shingouki" and name == "sgs") or
          (char == "gill" and (name == "meteor_strike" or name == "seraphic_wing")) then table.insert(result, name) end
   end
   return result
end

local function get_option_select_names()
   local result = {}
   for i = 1, #move_list["option_select"] do
      local name = move_list["option_select"][i].name
      table.insert(result, name)
   end
   return result
end

local function get_buttons_by_move_name(char, name)
   for i = 1, #move_list[char] do if name == move_list[char][i].name then return move_list[char][i].buttons end end
   return nil
end

local function get_type_by_move_name(char, name)
   for i = 1, #move_list[char] do if name == move_list[char][i].name then return move_list[char][i].move_type end end
   return nil
end

return {
   move_list = move_list,
   get_move_inputs_by_name = get_move_inputs_by_name,
   get_special_and_sa_names = get_special_and_sa_names,
   get_option_select_names = get_option_select_names,
   get_buttons_by_move_name = get_buttons_by_move_name,
   get_type_by_move_name = get_type_by_move_name
}
