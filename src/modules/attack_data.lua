local gamestate = require("src/gamestate")

local data = {}

local function update(attacker, defender)
  data.player_id = attacker.id

  local current_life = defender.life
  if defender.life == 255 then
    current_life = 0
  end

  local function update_stun(player)
    local stun_decrease_offset = 0
    local stun_decrease_timer = memory.readbyte(defender.stun_bar_decrease_timer_addr)
    if stun_decrease_timer > 0 then
      stun_decrease_offset = (memory.readbyte(defender.stun_bar_decrease_amount_addr) + 1) / 256
    end
    if player.stunned then
      data.total_stun = player.stun_max - data.start_stun
    elseif player.stun_just_ended then
      data.start_stun = 0
      data.total_stun = player.stun_bar - data.start_stun + stun_decrease_offset
    else
      data.total_stun = player.stun_bar - data.start_stun + stun_decrease_offset
    end
  end

  local function check_chip_damage(player)
    if player.previous_life - current_life > 0 then
      data.total_damage = 0
      data.total_stun = 0
      data.start_life = player.previous_life
      data.start_stun = player.stun_bar
      data.stun_max = player.stun_max
      data.id = gamestate.frame_number
      data.finished = false
    end
  end

  if defender.stun_just_ended then
    data.start_stun = 0
  end

  if not defender.stunned then
    if defender.posture == 38
    or defender.just_recovered
    or defender.is_in_air_recovery
    or (defender.stun_just_ended and defender.is_idle) then --stun timed out
      data.finished = true
    end
  end

  if attacker.combo == nil then
    attacker.combo = 0
  end

  if attacker.combo == 0 then
    data.last_hit_combo = 0
  end

  if attacker.has_just_hit or defender.has_just_been_hit then
    if data.finished then
      data.total_damage = 0
      data.total_stun = 0
      data.start_life = current_life
      local stun_decrease_offset = 0
      local stun_decrease_timer = memory.readbyte(defender.stun_bar_decrease_timer_addr)
      if stun_decrease_timer > 0 then
        stun_decrease_offset = (memory.readbyte(defender.stun_bar_decrease_amount_addr) + 1) / 256
      end
      data.start_stun = defender.stun_bar + stun_decrease_offset
      data.stun_max = defender.stun_max
      data.id = gamestate.frame_number
      data.finished = false
    end
    data.last_hit_combo = attacker.combo
  elseif defender.has_just_blocked then
    if data.finished then
      Queue_Command(gamestate.frame_number + 1, {command = check_chip_damage, args={defender}})
    end
  end

  if attacker.combo ~= 0 then
    data.combo = attacker.combo
  end
  if attacker.combo > data.max_combo then
    data.max_combo = attacker.combo
  end

  local delta_life = (defender.previous_life or 0) - current_life

  if delta_life > 0 then
    data.damage = delta_life
    data.total_damage = data.start_life - current_life
    if not attacker.has_just_been_blocked then
      update_stun(defender)
--       Queue_Command(gamestate.frame_number + 1, {command = update_stun, args={defender}})
    end
  end
  defender.previous_life = current_life

end

local function reset()
  data = {
    player_id = nil,
    last_hit_combo = 0,

    damage = 0,
    stun = 0,
    combo = 0,
    total_damage = 0,
    total_stun = 0,
    stun_max = 64,
    max_combo = 0,
    start_life = 160,
    start_stun = 0,
    id = 0,
    finished = true
  }
end

reset()


local attack_data = {
  update = update,
  reset = reset
}

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
  end
})

return attack_data