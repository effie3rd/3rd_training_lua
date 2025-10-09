local game_name = "Street Fighter III 3rd Strike (Japan 990512)"
local script_version = "v1.0.0"
local rom_name = emu.romname()
local is_fightcade = false

if not rom_name == "sfiii3nr1" then
   print("-----------------------------")
   print(
       "WARNING: You are not using a rom supported by this script. Some of the features might not be working correctly.")
   print("-----------------------------")
   rom_name = "sfiii3nr1"
end

-- CHARACTERS
local characters = {
   "gill", "alex", "ryu", "yun", "dudley", "necro", "hugo", "ibuki", "elena", "oro", "yang", "ken", "sean", "urien",
   "gouki", "shingouki", "chunli", "makoto", "q", "twelve", "remy"
}

local game_data = {game_name = game_name, script_version = script_version, rom_name = rom_name, characters = characters}

setmetatable(game_data, {
   __index = function(_, key) if key == "is_fightcade" then return is_fightcade end end,

   __newindex = function(_, key, value)
      if key == "is_fightcade" then
         is_fightcade = value
      else
         rawset(game_data, key, value)
      end
   end
})

return game_data
