local defense = require("src.training.defense")
local jumpins = require("src.training.jumpins")
local footsies = require("src.training.footsies")
local unblockables = require("src.training.unblockables")
local geneijin = require("src.training.geneijin")

local modes = {defense, jumpins, footsies, unblockables, geneijin}
local active_mode

local function add_mode(mode) end -- training.controllers[module_name] = module

local function stop_all() for _, mode in ipairs(modes) do mode.stop() end end

local function stop_other_modes(selected_mode)
   for _, mode in ipairs(modes) do if not (mode == selected_mode) then mode.stop() end end
end

local function update_all(gesture)
   active_mode = nil
   for _, mode in ipairs(modes) do
      if mode.is_active then
         active_mode = mode
         if not require("src.ui.menu").is_open or require("src.ui.menu").allow_update_while_open then
            mode.update()
            mode.process_gesture(gesture)
         end
      end
   end
end

local function set_active_mode(mode)
   active_mode = nil
   mode.is_active = true
   stop_other_modes(mode)
   for _, m in ipairs(modes) do
      if m.is_active then
         active_mode = m
      end
   end
end

local function stop_mode(mode)
   active_mode = nil
   mode.is_active = false
   for _, m in ipairs(modes) do
      if m.is_active then
         active_mode = m
      end
   end
end

local special_modes = {
   modes = modes,
   stop_all = stop_all,
   stop_other_modes = stop_other_modes,
   update_all = update_all,
   set_active_mode = set_active_mode,
   stop_mode = stop_mode,
}
setmetatable(special_modes, {__index = function(_, key) if key == "active_mode" then return active_mode end end})

return special_modes
