local move_list = read_object_from_json_file("data/move_list.json")

local function get_move_sequence_by_name(char, name, button)
  local sequence = {}
  for _, move in pairs(move_list[char]) do
    if move.name == name then
      sequence = deepcopy(move.input)
      break
    end
  end
  local i = 1
  while i <= #sequence do
    local j = 1
    while j <= #sequence[i] do
      if sequence[i][j] == "button" then
        if button == "EXP"  then
          table.remove(sequence[i], j)
          table.insert(sequence[i], j, "LP")
          table.insert(sequence[i], j, "MP")
        elseif button == "EXK"  then
          table.remove(sequence[i], j)
          table.insert(sequence[i], j, "LK")
          table.insert(sequence[i], j, "MK")
        else
          table.remove(sequence[i], j)
          table.insert(sequence[i], j, button)
        end
      end
      j = j + 1
    end
    i = i + 1
  end
  return sequence
end

return {
  move_list = move_list,
  get_move_sequence_by_name = get_move_sequence_by_name
}