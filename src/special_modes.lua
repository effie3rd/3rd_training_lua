local defense = require("src.training.defense")
local jumpins = require("src.training.jumpins")
local footsies = require("src.training.footsies")
local unblockables = require("src.training.unblockables")
local geneijin = require("src.training.geneijin")

local modes = {defense, jumpins, footsies, unblockables, geneijin}

local function stop_all() for _, mode in ipairs(modes) do mode.stop() end end

local function stop_other_modes(selected_mode)
   for _, mode in ipairs(modes) do if not (mode == selected_mode) then mode.stop() end end
end

local function update_all(gesture)
   local is_active = false
   for _, mode in ipairs(modes) do
      if mode.is_active and (not require("src.ui.menu").is_open or require("src.ui.menu").allow_update_while_open) then
         mode.update()
         mode.process_gesture(gesture)
      end
   end
   return is_active
end

return {modes = modes, stop_all = stop_all, stop_other_modes = stop_other_modes, update_all = update_all}
