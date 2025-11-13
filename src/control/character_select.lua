local settings = require("src.settings")
local gamestate = require("src.gamestate")
local game_data = require("src.modules.game_data")
local sd = require("src.modules.stage_data")
local inputs = require("src.control.inputs")
local memory_addresses = require("src.control.memory_addresses")
local tools = require("src.tools")

local module_name = "character_select"

local character_select_savestate = savestate.create("data/" .. game_data.rom_name .. "/savestates/character_select.fs")
local first_run = true
local character_select_start_frame = 0
local clear_buttons_until_frame = 0
local character_select_coroutines = {}
local selecting_random_character = false
local disable_boss_select = false
local last_player_id = 1
local p1_forced_select = false
local p2_forced_select = false

-- 0 is out
-- 1 is waiting for input release for p1
-- 2 is selecting p1
-- 3 is waiting for input release for p2
-- 4 is selecting p2
local character_select_sequence_state = 0

local character_select_loc = {
   {0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}, {0, 6}, {1, 0}, {1, 1}, {1, 2}, {1, 3}, {1, 4}, {1, 5}, {1, 6}, {2, 0},
   {2, 1}, {2, 2}, {2, 3}, {2, 4}, {2, 5}
}
local character_map = {
   alex = {0, 1},
   sean = {0, 2},
   ibuki = {0, 3},
   necro = {0, 4},
   urien = {0, 5},
   gouki = {0, 6},
   yang = {1, 0},
   twelve = {1, 1},
   makoto = {1, 2},
   chunli = {1, 3},
   q = {1, 4},
   remy = {1, 5},
   yun = {1, 6},
   ken = {2, 0},
   hugo = {2, 1},
   elena = {2, 2},
   dudley = {2, 3},
   oro = {2, 4},
   ryu = {2, 5},
   gill = {3, 1},
   shingouki = {0, 6}
}

local sel_buttons = {{{"LP"}}, {{"MP"}}, {{"HP"}}, {{"LK"}}, {{"MK"}}, {{"HK"}}, {{"LP", "MK", "HP"}}}

local function character_select_coroutine(co, name)
   local o = {}
   o.coroutine = coroutine.create(co)
   o.name = name

   function o:resume(input) return coroutine.resume(self.coroutine, input) end

   function o:status() return coroutine.status(self.coroutine) end

   character_select_coroutines[name] = o
   return o
end

local function co_wait_x_frames(frame_count)
   local start_frame = gamestate.frame_number
   while gamestate.frame_number < start_frame + frame_count do coroutine.yield() end
end

local function after_character_select_loaded()
   clear_buttons_until_frame = gamestate.frame_number + 30
   character_select_start_frame = gamestate.frame_number
end

-- fixes a bug where fightcade loads its own savestate
-- and causes p1's SA selection to also select p2's character
local function co_delay_load_savestate(input)
   co_wait_x_frames(1)
   character_select_sequence_state = 1
   Register_After_Load_State(after_character_select_loaded)
   Load_State_Caller = tools.get_calling_module_name() or module_name
   savestate.load(character_select_savestate)
end

local function start_character_select_sequence(disable_bosses)
   if first_run then
      character_select_coroutine(co_delay_load_savestate, "delay_load")
      first_run = false
   end
   character_select_sequence_state = 1
   Register_After_Load_State(after_character_select_loaded)
   Load_State_Caller = tools.get_calling_module_name() or module_name
   savestate.load(character_select_savestate)

   last_player_id = 1

   disable_boss_select = disable_bosses or false
   p1_forced_select = false
   p2_forced_select = false
   selecting_random_character = false
end

local function force_character_select_coroutine(co, name, player, char, sa, sel_button)
   local o = {}
   o.coroutine = coroutine.create(co)
   o.name = name
   o.player = player
   o.char = char
   o.sa = sa
   o.sel_button = sel_button

   function o:resume(input)
      return coroutine.resume(self.coroutine, input, self.player, self.char, self.sa, self.sel_button)
   end

   function o:status() return coroutine.status(self.coroutine) end

   character_select_coroutines[name] = o
   return o
end

local function co_force_select_character(input, player_id, char, sa, sel_button)
   local col = character_map[char][1]
   local row = character_map[char][2]

   local character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)

   if character_select_state > 2 then return end

   if sel_button == "random" then
      sel_button = sel_buttons[math.random(1, #sel_buttons)]
   else
      sel_button = {{sel_button}}
   end

   local curr_col = -1
   local curr_row = -1

   while not (curr_col == col and curr_row == row) do
      memory.writebyte(memory_addresses.players[player_id].character_select_col, col)
      memory.writebyte(memory_addresses.players[player_id].character_select_row, row)
      co_wait_x_frames(1)
      curr_col = memory.readbyte(memory_addresses.players[player_id].character_select_col)
      curr_row = memory.readbyte(memory_addresses.players[player_id].character_select_row)
   end

   while character_select_state < 3 do
      co_wait_x_frames(2)
      inputs.queue_input_sequence(gamestate.player_objects[player_id], sel_button)
      co_wait_x_frames(2)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end

   while character_select_state < 4 do
      co_wait_x_frames(1)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end

   if char == "shingouki" then memory.writebyte(memory_addresses.players[player_id].character_select_id, 0x0F) end

   if sa == 2 then
      inputs.queue_input_sequence(gamestate.player_objects[player_id], {{"down"}})
      co_wait_x_frames(20)
   elseif sa == 3 then
      inputs.queue_input_sequence(gamestate.player_objects[player_id], {{"up"}})
      co_wait_x_frames(20)
   end

   while character_select_state < 5 do
      inputs.queue_input_sequence(gamestate.player_objects[player_id], sel_button)
      co_wait_x_frames(2)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end
end

local function force_select_character(player_id, char, sa, sel_button)
   force_character_select_coroutine(co_force_select_character, "force_p" .. player_id, player_id, char, sa, sel_button)
end

local function co_select_gill(input)
   local player_id = 1
   local sel_buttons = {"LP", "HK"}
   local i = math.random(1, #sel_buttons)
   local sel_button = sel_buttons[i]
   local p1_select_state = memory.readbyte(memory_addresses.players[1].character_select_state)
   local p2_select_state = memory.readbyte(memory_addresses.players[2].character_select_state)

   if p1_select_state > 2 and p2_select_state > 2 then return end

   local character_select_state = 0

   if p1_select_state <= 2 then
      player_id = 1
      character_select_state = p1_select_state
   else
      player_id = 2
      character_select_state = p2_select_state
   end

   memory.writebyte(memory_addresses.players[player_id].character_select_col, 3)
   memory.writebyte(memory_addresses.players[player_id].character_select_row, 1)

   while character_select_state < 3 do
      co_wait_x_frames(2)
      inputs.queue_input_sequence(gamestate.player_objects[player_id], {{sel_button}})
      co_wait_x_frames(2)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end

   -- while character_select_state < 4 do
   --   co_wait_x_frames(1)
   --   character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   -- end

   -- while character_select_state < 5 do
   --   inputs.queue_input_sequence(gamestate.P1, {{sel_button}})
   --   co_wait_x_frames(2)
   --   character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   -- end
end

local function select_gill()
   if not disable_boss_select and character_select_sequence_state ~= 0 then
      if not character_select_coroutines["gill"] then character_select_coroutine(co_select_gill, "gill") end
   end
end

local function co_select_shingouki(input)
   local player_id = 1

   local sel_buttons = {"LP", "HK"}
   local i = math.random(1, #sel_buttons)
   local sel_button = sel_buttons[i]
   local p1_select_state = memory.readbyte(memory_addresses.players[1].character_select_state)
   local p2_select_state = memory.readbyte(memory_addresses.players[2].character_select_state)

   if p1_select_state > 2 and p2_select_state > 2 then return end

   local character_select_state = 0

   if p1_select_state <= 2 then
      player_id = 1
      character_select_state = p1_select_state
   else
      player_id = 2
      character_select_state = p2_select_state
   end

   memory.writebyte(memory_addresses.players[player_id].character_select_col, 0)
   memory.writebyte(memory_addresses.players[player_id].character_select_row, 6)

   while character_select_state < 3 do
      co_wait_x_frames(2)
      inputs.queue_input_sequence(gamestate.player_objects[player_id], {{sel_button}})
      co_wait_x_frames(2)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end

   while character_select_state < 4 do
      co_wait_x_frames(1)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end

   while character_select_state < 5 do
      memory.writebyte(memory_addresses.players[player_id].character_select_id, 0x0F)
      co_wait_x_frames(1)
      character_select_state = memory.readbyte(memory_addresses.players[player_id].character_select_state)
   end
end

local function select_shingouki()
   if not disable_boss_select and character_select_sequence_state ~= 0 then
      if not character_select_coroutines["shingouki"] then
         character_select_coroutine(co_select_shingouki, "shingouki")
      end
   end
end

local function co_random_character(input)

   if not selecting_random_character then return end

   local player_id
   local p1_select_state
   local p2_select_state

   p1_select_state = memory.readbyte(memory_addresses.players[1].character_select_state)
   p2_select_state = memory.readbyte(memory_addresses.players[2].character_select_state)

   if p1_select_state <= 2 then
      player_id = 1
   elseif p1_select_state >= 5 and p2_select_state <= 2 then
      player_id = 2
   else
      return
   end

   -- stop random select after p1 character is chosen
   if last_player_id ~= player_id then
      last_player_id = player_id
      selecting_random_character = false
      return
   end

   local character_select_col = memory.readbyte(memory_addresses.players[player_id].character_select_col)
   local character_select_row = memory.readbyte(memory_addresses.players[player_id].character_select_row)

   -- don't select the same character twice
   while true do
      local n = math.random(1, #character_select_loc)

      local col = character_select_loc[n][1]
      local row = character_select_loc[n][2]

      if col ~= character_select_col or row ~= character_select_row then
         memory.writebyte(memory_addresses.players[player_id].character_select_col, col)
         memory.writebyte(memory_addresses.players[player_id].character_select_row, row)
         break
      end
   end
end

local function start_select_random_character() selecting_random_character = true end

local function stop_select_random_character() selecting_random_character = false end

local function select_random_character()
   if not p1_forced_select and not character_select_coroutines["select_random"] then
      character_select_coroutine(co_random_character, "select_random")
   end
end

local p1_character_select_state = 0
local p2_character_select_state = 0
local function update_character_select(input)

   if not character_select_sequence_state == 0 then
      return
   end

   -- Infinite select time
   -- memory.writebyte(memory_addresses.global.character_select_timer, 0x30)

   if p1_forced_select then
      inputs.block_input(1, "all")
   else
      inputs.unblock_input(1)
   end

   local to_remove = {}
   for k, cs in pairs(character_select_coroutines) do
      local status = cs:status()
      if status == "suspended" then
         local r, error = cs:resume(input)
         if not r then print(error) end
      elseif status == "dead" then
         table.insert(to_remove, k)
         if cs.name == "force_p1" then
            p1_forced_select = false
         elseif cs.name == "force_p2" then
            p2_forced_select = false
         end
      end
      if cs.name == "force_p1" then
         p1_forced_select = true
      elseif cs.name == "force_p2" then
         p2_forced_select = true
      end
   end
   for _, key in ipairs(to_remove) do character_select_coroutines[key] = nil end

   p1_character_select_state = memory.readbyte(memory_addresses.players[1].character_select_state)
   p2_character_select_state = memory.readbyte(memory_addresses.players[2].character_select_state)

   if not p1_forced_select then
      if p1_character_select_state > 4 and not gamestate.is_in_match then
         if character_select_sequence_state == 2 then character_select_sequence_state = 3 end
         if not p1_forced_select and not p2_forced_select then inputs.swap_inputs(input) end
      end

      if gamestate.frame_number < clear_buttons_until_frame then
         inputs.block_input(1, "buttons")
      else
         inputs.unblock_input(1)
      end

      -- wait for all inputs to be released
      if character_select_sequence_state == 1 or character_select_sequence_state == 3 then
         for _, state in pairs(input) do
            if state == true then
               inputs.make_input_empty(input)
               return
            end
         end
         character_select_sequence_state = character_select_sequence_state + 1
      end

      if selecting_random_character then inputs.block_input(1, "directions") end
   end

   if not gamestate.is_in_match and settings.training.force_stage > 1 then
      local stage = sd.menu_to_stage_map[settings.training.force_stage]
      if settings.training.force_stage == 2 then
         local n = 3 + math.random(0, sd.n_stages - 1)
         stage = sd.menu_to_stage_map[n]
      end
      memory.writebyte(memory_addresses.global.stage, stage)
   end
end

local function is_selection_complete()
   local p1_complete = memory.readbyte(memory_addresses.players[1].character_select_state) > 4
   local p2_complete = memory.readbyte(memory_addresses.players[2].character_select_state) > 4
   return p1_complete and p2_complete
end

local character_select = {
   module_name = module_name,
   start_character_select_sequence = start_character_select_sequence,
   update_character_select = update_character_select,
   select_gill = select_gill,
   select_shingouki = select_shingouki,
   start_select_random_character = start_select_random_character,
   stop_select_random_character = stop_select_random_character,
   select_random_character = select_random_character,
   force_select_character = force_select_character,
   is_selection_complete = is_selection_complete
}

setmetatable(character_select, {
   __index = function(_, key)
      if key == "p1_character_select_state" then
         return p1_character_select_state
      elseif key == "p2_character_select_state" then
         return p2_character_select_state
      elseif key == "character_select_start_frame" then
         return character_select_start_frame
      end
   end,

   __newindex = function(_, key, value)
      if key == "p1_character_select_state" then
         p1_character_select_state = value
      elseif key == "p2_character_select_state" then
         p2_character_select_state = value
      elseif key == "character_select_start_frame" then
         character_select_start_frame = value
      else
         rawset(character_select, key, value)
      end
   end
})

return character_select
