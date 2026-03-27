local gamestate = require("src.gamestate")
local tools = require("src.tools")

local data_default = {
   last_hit_combo = 0,
   damage = 0,
   stun = 0,
   combo = 0,
   total_damage = 0,
   total_stun = 0,
   stun_bar_max = 64,
   max_combo = 0,
   start_life = 160,
   start_stun = 0,
   id = 0,
   finished = true,
   is_chip = false,
}
local data = { copytable(data_default), copytable(data_default) }

local function update()
   for id, attacker in pairs(gamestate.player_objects) do
      local defender = attacker.other
      local a_data = data[attacker.id]

      local current_life = defender.life
      if defender.life == 255 then
         current_life = 0
      end

      local function update_stun(player)
         local stun_decrease_offset = 0
         local stun_decrease_timer = memory.readbyte(defender.addresses.stun_bar_decrease_timer)
         if stun_decrease_timer > 0 then
            stun_decrease_offset = (memory.readbyte(defender.addresses.stun_bar_decrease_mantissa) + 1) / 256
         end
         if player.is_stunned then
            a_data.total_stun = player.stun_bar_max - a_data.start_stun
         elseif player.stun_just_ended then
            a_data.start_stun = 0
            a_data.total_stun = player.stun_bar - a_data.start_stun + stun_decrease_offset
         else
            a_data.total_stun = player.stun_bar - a_data.start_stun + stun_decrease_offset
         end
      end

      local function check_chip_damage(player)
         if player.previous_life - defender.life > 0 then
            a_data.total_damage = 0
            a_data.total_stun = 0
            a_data.start_life = player.previous_life
            a_data.start_stun = player.stun_bar
            a_data.stun_bar_max = player.stun_bar_max
            a_data.id = gamestate.frame_number
            a_data.finished = false
            a_data.is_chip = true
         end
      end

      if defender.stun_just_ended then
         a_data.start_stun = 0
      end

      if not defender.is_stunned then
         if defender.stun_just_ended and defender.is_idle then -- stun timed out
            a_data.finished = true
         end
      end

      if attacker.combo == nil then
         attacker.combo = 0
      end

      if attacker.combo < a_data.combo then
         a_data.finished = true
      end

      if attacker.combo == 0 then
         a_data.last_hit_combo = 0
      end

      if a_data.is_chip and defender.has_just_ended_recovery then
         a_data.finished = true
      end

      if defender.has_just_been_hit then
         if a_data.finished or (attacker.combo == a_data.combo and not defender.is_being_thrown) then
            a_data.total_damage = 0
            a_data.total_stun = 0
            a_data.start_life = current_life
            local stun_decrease_offset = 0
            local stun_decrease_timer = memory.readbyte(defender.addresses.stun_bar_decrease_timer)
            if stun_decrease_timer > 0 then
               stun_decrease_offset = (memory.readbyte(defender.addresses.stun_bar_decrease_mantissa) + 1) / 256
            end
            a_data.start_stun = defender.stun_bar + stun_decrease_offset
            a_data.stun_bar_max = defender.stun_bar_max
            a_data.id = gamestate.frame_number
            a_data.finished = false
            a_data.is_chip = false
         end
         a_data.last_hit_combo = attacker.combo
      elseif defender.has_just_blocked then
         if a_data.finished then
            Queue_Command(gamestate.frame_number + 1, check_chip_damage, { defender })
         end
      end

      a_data.combo = attacker.combo
      if attacker.combo > a_data.max_combo then
         a_data.max_combo = attacker.combo
      end

      local delta_life = (defender.previous_life or 0) - current_life

      if delta_life > 0 then
         a_data.damage = delta_life
         a_data.total_damage = a_data.start_life - current_life
         if not attacker.has_just_been_blocked then
            update_stun(defender)
         end
      end
      defender.previous_life = current_life
   end
end

local function reset()
   tools.clear_table(data[1])
   tools.clear_table(data[2])
   tools.copy_fields(data[1], data_default)
   tools.copy_fields(data[2], data_default)
end

local attack_data = { update = update, reset = reset }

setmetatable(attack_data, {
   __index = function(_, key)
      if key == "data" then
         return data
      end
   end,

   __newindex = function(_, key, value)
      if key == "data" then
         data = value
      else
         rawset(attack_data, key, value)
      end
   end,
})

return attack_data
