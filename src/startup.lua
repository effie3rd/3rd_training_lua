game_name = "Street Fighter III 3rd Strike (Japan 990512)"
script_version = "v1.0.0"
fc_version = "2.1.45"
rom_name = emu.romname()

if not rom_name == "sfiii3nr1" then
  print("-----------------------------")
  print("WARNING: You are not using a rom supported by this script. Some of the features might not be working correctly.")
  print("-----------------------------")
  rom_name = "sfiii3nr1"
end

-- CHARACTERS
Characters =
{
  "gill",
  "alex",
  "ryu",
  "yun",
  "dudley",
  "necro",
  "hugo",
  "ibuki",
  "elena",
  "oro",
  "yang",
  "ken",
  "sean",
  "urien",
  "gouki",
  "shingouki",
  "chunli",
  "makoto",
  "q",
  "twelve",
  "remy",
}