local training, settings, recording

local modes
local active_mode

local settings_cache = {}
local controller_cache = {"player", "dummy_control"}
local settings_to_save = {"life_mode", "stun_mode", "meter_mode", "infinite_time", "infinite_sa_time"}

local function save_controller_settings() controller_cache = {training.P1_controller.name, training.P2_controller.name} end
local function save_training_settings()
   for _, key in ipairs(settings_to_save) do settings_cache[key] = settings.training[key] end
end

local function restore_controller_settings() training.set_controllers_by_name(controller_cache[1], controller_cache[2]) end
local function restore_training_settings() for key, value in pairs(settings_cache) do settings.training[key] = value end end

local function stop_recording() recording.set_recording_state({}, recording.RECORDING_STATE.STOPPED) end

local function init()
   training = require("src.training")
   settings = require("src.settings")
   recording = require("src.control.recording")
   modes = require("src.modules").training_modules
end

local function stop_all() for _, mode in ipairs(modes) do mode.stop() end end

local function stop_other_modes(selected_mode)
   for _, mode in ipairs(modes) do
      if not (mode == selected_mode) then
         mode.stop()
         mode.is_active = false
      end
   end
end

local function stop()
   if not active_mode then return end
   active_mode.stop()
   active_mode.is_active = false
   restore_controller_settings()
   restore_training_settings()
   if active_mode.end_mode then active_mode.end_mode() end
   active_mode = nil
end

local function start(mode)
   if not mode then return end
   if not active_mode then
      save_controller_settings()
      save_training_settings()
   end
   stop_recording()
   stop_other_modes(mode)
   mode.start()
   mode.is_active = true
   active_mode = mode
end

local function set_active(mode)
   if not active_mode then
      save_controller_settings()
      save_training_settings()
   end
   stop_other_modes(mode)
   mode.is_active = true
   active_mode = mode
end

local modes_module = {
   init = init,
   stop_all = stop_all,
   stop_other_modes = stop_other_modes,
   start = start,
   stop = stop,
   set_active = set_active
}
setmetatable(modes_module, {
   __index = function(_, key)
      if key == "active_mode" then
         return active_mode
      elseif key == "modes" then
         return modes
      end
   end
})

return modes_module
