local training_mode_names = {"defense", "jumpins", "footsies", "unblockables", "geneijin"}
local extra_module_names = {"extra_settings", "key_bindings"}
local training_modules = {}
local extra_modules = {}
local all_modules = {}
local modules_map = {}
local settings, menu

local function load_all_modules()
   for _, module_name in ipairs(training_mode_names) do
      local module = require(settings.training_require_path .. "." .. module_name .. "." .. module_name)
      module.init()
      training_modules[#training_modules + 1] = module
      all_modules[#all_modules + 1] = module
      modules_map[module_name] = module
   end
   for _, module_name in ipairs(extra_module_names) do
      local module = require(settings.modules_require_path .. "." .. module_name .. "." .. module_name)
      module.init()
      extra_modules[#extra_modules + 1] = module
      all_modules[#all_modules + 1] = module
      modules_map[module_name] = module
   end
end

local function init()
   settings = require("src.settings")
   menu = require("src.ui.menu")
   load_all_modules()
end

local function update()
   for _, module in ipairs(all_modules) do
      if module.is_enabled and (not menu.is_open or module.should_update_while_menu_is_open) then module.update() end
   end
end

local function toggle(module)
   module.toggle()
end

local function after_images_loaded()
   for _, module in ipairs(all_modules) do if module.after_images_loaded then module.after_images_loaded() end end
end
local function after_framedata_loaded()
   for _, module in ipairs(all_modules) do if module.after_framedata_loaded then module.after_framedata_loaded() end end
end
local function after_menu_created()
   for _, module in ipairs(all_modules) do if module.after_menu_created then module.after_menu_created() end end
end

local function get_module(name) return modules_map[name] end

local modules = {
   init = init,
   training_mode_names = training_mode_names,
   extra_module_names = extra_module_names,
   training_modules = training_modules,
   extra_modules = extra_modules,
   all_modules = all_modules,
   update = update,
   toggle = toggle,
   after_images_loaded = after_images_loaded,
   after_framedata_loaded = after_framedata_loaded,
   after_menu_created = after_menu_created,
   get_module = get_module
}
return modules
