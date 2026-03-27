if emu.romname() == "sfiii3nr1" then
   require("src.data.game_data").is_fightcade = true
   require("3rd_training")
else
   local chunk = assert(loadfile("fbneo-training-mode-original.lua"))
   setfenv(chunk, getfenv(1)) -- run in current environment
   chunk()
end
