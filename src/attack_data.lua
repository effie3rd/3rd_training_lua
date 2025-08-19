attack_data = {}

function attack_data_update(_attacker, _defender)
  attack_data.player_id = _attacker.id

  local _current_life = _defender.life
  if _defender.life == 255 then
    _current_life = 0
  end

  function update_stun(_player)
    local _stun_decrease_offset = 0
    local _stun_decrease_timer = memory.readbyte(_defender.stun_bar_decrease_timer_addr)
    if _stun_decrease_timer > 0 then
      _stun_decrease_offset = (memory.readbyte(_defender.stun_bar_decrease_amount_addr) + 1) / 256
    end
    if _player.stunned then
      attack_data.total_stun = _player.stun_max - attack_data.start_stun
    elseif _player.stun_just_ended then
      attack_data.start_stun = 0
      attack_data.total_stun = _player.stun_bar - attack_data.start_stun + _stun_decrease_offset
    else
      attack_data.total_stun = _player.stun_bar - attack_data.start_stun + _stun_decrease_offset
    end
  end

  function check_chip_damage(_player)
    if _player.previous_life - _current_life > 0 then
      attack_data.total_damage = 0
      attack_data.total_stun = 0
      attack_data.start_life = _player.previous_life
      attack_data.start_stun = _player.stun_bar
      attack_data.stun_max = _player.stun_max
      attack_data.id = frame_number
      attack_data.finished = false
    end
  end

  if _defender.stun_just_ended then
    attack_data.start_stun = 0
  end

  if not _defender.stunned then
    if _defender.posture == 38
    or _defender.just_recovered
    or _defender.is_in_air_recovery
    or (_defender.stun_just_ended and _defender.is_idle) then --stun timed out
      attack_data.finished = true
    end
  end

  if _attacker.combo == nil then
    _attacker.combo = 0
  end

  if _attacker.combo == 0 then
    attack_data.last_hit_combo = 0
  end

  if _attacker.has_just_hit or _defender.has_just_been_hit then
    if attack_data.finished then
      attack_data.total_damage = 0
      attack_data.total_stun = 0
      attack_data.start_life = _current_life
      local _stun_decrease_offset = 0
      local _stun_decrease_timer = memory.readbyte(_defender.stun_bar_decrease_timer_addr)
      if _stun_decrease_timer > 0 then
        _stun_decrease_offset = (memory.readbyte(_defender.stun_bar_decrease_amount_addr) + 1) / 256
      end
      attack_data.start_stun = _defender.stun_bar + _stun_decrease_offset
      attack_data.stun_max = _defender.stun_max
      attack_data.id = frame_number
      attack_data.finished = false
    end
    attack_data.last_hit_combo = _attacker.combo
  elseif _defender.has_just_blocked then
    if attack_data.finished then
      queue_command(frame_number + 1, {command = check_chip_damage, args={_defender}})
    end
  end

  if _attacker.combo ~= 0 then
    attack_data.combo = _attacker.combo
  end
  if _attacker.combo > attack_data.max_combo then
    attack_data.max_combo = _attacker.combo
  end



  local _delta_life = (_defender.previous_life or 0) - _current_life

  if _delta_life > 0 then
    attack_data.damage = _delta_life
    attack_data.total_damage = attack_data.start_life - _current_life
    if not _attacker.has_just_been_blocked then
      update_stun(_defender)
--       queue_command(frame_number + 1, {command = update_stun, args={_defender}})
    end
  end
  _defender.previous_life = _current_life

end

function attack_data_display()
  local _text_width1 = get_text_width("damage: ")
  local _text_width2 = get_text_width("stun: ")
  local _text_width3 = get_text_width("combo: ")
  local _text_width4 = get_text_width("total damage: ")
  local _text_width5 = get_text_width("total stun: ")
  local _text_width6 = get_text_width("max combo: ")

  local _x1 = 0
  local _x2 = 0
  local _x3 = 0
  local _x4 = 0
  local _x5 = 0
  local _x6 = 0
  local _y = 49

  local _x_spacing = 80

  if attack_data.player_id == 1 then
    local _base = screen_width - 138
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
    local _base2 = _base + _x_spacing
    _x4 = _base2 - _text_width4
    _x5 = _base2 - _text_width5
    _x6 = _base2 - _text_width6
  elseif attack_data.player_id == 2 then
    local _base = 82
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
    local _base2 = _base + _x_spacing
    _x4 = _base2 - _text_width4
    _x5 = _base2 - _text_width5
    _x6 = _base2 - _text_width6
  end

  gui.text(_x1, _y, string.format("damage: "))
  gui.text(_x1 + _text_width1, _y, string.format("%d", attack_data.damage))

  gui.text(_x2, _y + 10, string.format("stun: "))
  gui.text(_x2 + _text_width2, _y + 10, string.format("%d", attack_data.stun))

  gui.text(_x3, _y + 20, string.format("combo: "))
  gui.text(_x3 + _text_width3, _y + 20, string.format("%d", attack_data.combo))

  gui.text(_x4, _y, string.format("total damage: "))
  gui.text(_x4 + _text_width4, _y, string.format("%d", attack_data.total_damage))

  gui.text(_x5, _y + 10, string.format("total stun: "))
  gui.text(_x5 + _text_width5, _y + 10, string.format("%d", attack_data.total_stun))

  gui.text(_x6, _y + 20, string.format("max combo: "))
  gui.text(_x6 + _text_width6, _y + 20, string.format("%d", attack_data.max_combo))
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
