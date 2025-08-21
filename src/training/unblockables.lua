--force select urien random
--clear p1 inputs

--please wait display
--move chars
--do unblockable
--save state
--select resets
--automatic reset
local colors = {{{"LP"}},{{"MP"}},{{"HP"}},{{"LK"}},{{"MK"}},{{"HK"}},{{"LP","MK","HP"}}}
Register_After_Load_State(function() new_character=true end)
character_select.start_character_select_sequence(true, {2, "shingouki", 1, })

function start_unblockables()
  --urien oro if char
  local i_color = math.random(#colors)
    character_select.start_character_select_sequence(true, {2, "urien", 3, colors[i_color]})
end
