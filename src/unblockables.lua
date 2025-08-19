--force select urien random
--clear p1 inputs

--please wait display
--move chars
--do unblockable
--save state
--select resets
--automatic reset
local _colors = {{{"LP"}},{{"MP"}},{{"HP"}},{{"LK"}},{{"MK"}},{{"HK"}},{{"LP","MK","HP"}}}
table.insert(after_load_state_callback, {command = function() new_character=true end})
start_character_select_sequence(true, {2, "shingouki", 1, })

function start_unblockables()
  --urien oro if char
  local _i_color = math.random(#_colors)
    start_character_select_sequence(true, {2, "urien", 3, _colors[_i_color]})
end
