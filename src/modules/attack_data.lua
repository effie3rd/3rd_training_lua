local gamestate = require("src/gamestate")
local draw = require("src.ui.draw")

attack_data = {}

function attack_data_update(attacker, defender)
  attack_data.player_id = attacker.id

  local current_life = defender.life
  if defender.life == 255 then
    current_life = 0
  end

  function update_stun(player)
    local stun_decrease_offset = 0
    local stun_decrease_timer = memory.readbyte(defender.stun_bar_decrease_timer_addr)
    if stun_decrease_timer > 0 then
      stun_decrease_offset = (memory.readbyte(defender.stun_bar_decrease_amount_addr) + 1) / 256
    end
    if player.stunned then
      attack_data.total_stun = player.stun_max - attack_data.start_stun
    elseif player.stun_just_ended then
      attack_data.start_stun = 0
      attack_data.total_stun = player.stun_bar - attack_data.start_stun + stun_decrease_offset
    else
      attack_data.total_stun = player.stun_bar - attack_data.start_stun + stun_decrease_offset
    end
  end

  function check_chip_damage(player)
    if player.previous_life - current_life > 0 then
      attack_data.total_damage = 0
      attack_data.total_stun = 0
      attack_data.start_life = player.previous_life
      attack_data.start_stun = player.stun_bar
      attack_data.stun_max = player.stun_max
      attack_data.id = gamestate.frame_number
      attack_data.finished = false
    end
  end

  if defender.stun_just_ended then
    attack_data.start_stun = 0
  end

  if not defender.stunned then
    if defender.posture == 38
    or defender.just_recovered
    or defender.is_in_air_recovery
    or (defender.stun_just_ended and defender.is_idle) then --stun timed out
      attack_data.finished = true
    end
  end

  if attacker.combo == nil then
    attacker.combo = 0
  end

  if attacker.combo == 0 then
    attack_data.last_hit_combo = 0
  end

  if attacker.has_just_hit or defender.has_just_been_hit then
    if attack_data.finished then
      attack_data.total_damage = 0
      attack_data.total_stun = 0
      attack_data.start_life = current_life
      local stun_decrease_offset = 0
      local stun_decrease_timer = memory.readbyte(defender.stun_bar_decrease_timer_addr)
      if stun_decrease_timer > 0 then
        stun_decrease_offset = (memory.readbyte(defender.stun_bar_decrease_amount_addr) + 1) / 256
      end
      attack_data.start_stun = defender.stun_bar + stun_decrease_offset
      attack_data.stun_max = defender.stun_max
      attack_data.id = gamestate.frame_number
      attack_data.finished = false
    end
    attack_data.last_hit_combo = attacker.combo
  elseif defender.has_just_blocked then
    if attack_data.finished then
      Queue_Command(gamestate.frame_number + 1, {command = check_chip_damage, args={defender}})
    end
  end

  if attacker.combo ~= 0 then
    attack_data.combo = attacker.combo
  end
  if attacker.combo > attack_data.max_combo then
    attack_data.max_combo = attacker.combo
  end



  local delta_life = (defender.previous_life or 0) - current_life

  if delta_life > 0 then
    attack_data.damage = delta_life
    attack_data.total_damage = attack_data.start_life - current_life
    if not attacker.has_just_been_blocked then
      update_stun(defender)
--       Queue_Command(gamestate.frame_number + 1, {command = update_stun, args={defender}})
    end
  end
  defender.previous_life = current_life

end

function attack_data_display()
  local text_width1 = draw.get_text_width("damage: ")
  local text_width2 = draw.get_text_width("stun: ")
  local text_width3 = draw.get_text_width("combo: ")
  local text_width4 = draw.get_text_width("total damage: ")
  local text_width5 = draw.get_text_width("total stun: ")
  local text_width6 = draw.get_text_width("max combo: ")

  local x1 = 0
  local x2 = 0
  local x3 = 0
  local x4 = 0
  local x5 = 0
  local x6 = 0
  local y = 49

  local x_spacing = 80

  if attack_data.player_id == 1 then
    local base = draw.SCREEN_WIDTH - 138
    x1 = base - text_width1
    x2 = base - text_width2
    x3 = base - text_width3
    local base2 = base + x_spacing
    x4 = base2 - text_width4
    x5 = base2 - text_width5
    x6 = base2 - text_width6
  elseif attack_data.player_id == 2 then
    local base = 82
    x1 = base - text_width1
    x2 = base - text_width2
    x3 = base - text_width3
    local base2 = base + x_spacing
    x4 = base2 - text_width4
    x5 = base2 - text_width5
    x6 = base2 - text_width6
  end

  gui.text(x1, y, string.format("damage: "))
  gui.text(x1 + text_width1, y, string.format("%d", attack_data.damage))

  gui.text(x2, y + 10, string.format("stun: "))
  gui.text(x2 + text_width2, y + 10, string.format("%d", attack_data.stun))

  gui.text(x3, y + 20, string.format("combo: "))
  gui.text(x3 + text_width3, y + 20, string.format("%d", attack_data.combo))

  gui.text(x4, y, string.format("total damage: "))
  gui.text(x4 + text_width4, y, string.format("%d", attack_data.total_damage))

  gui.text(x5, y + 10, string.format("total stun: "))
  gui.text(x5 + text_width5, y + 10, string.format("%d", attack_data.total_stun))

  gui.text(x6, y + 20, string.format("max combo: "))
  gui.text(x6 + text_width6, y + 20, string.format("%d", attack_data.max_combo))
end

function attack_data_reset()
  attack_data = {
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
attack_data_reset()
