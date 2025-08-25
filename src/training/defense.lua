  -- LIFE
  if gamestate.is_in_match and not should_freeze_game then
    --infinite
    if settings.training.life_mode == 5 then
      memory.writebyte(player.life_addr, max_life)
    --not off 
    elseif settings.training.life_mode > 1 then
      local id = player.id
      local life = player.life
      local wanted_life = max_life
      if settings.training.life_mode == 2 then
        if id == 1 then
          wanted_life = settings.training.p1_life_reset_value
        elseif id == 2 then
          wanted_life = settings.training.p2_life_reset_value
        end
      elseif settings.training.life_mode == 3 then
        wanted_life = 0
      elseif settings.training.life_mode == 4 then
        wanted_life = max_life
      end
      if (player.just_recovered or player.has_just_started_wake_up)
      then
        gauge_state[id].life_refill_start_frame = gamestate.frame_number
        print("recovered")
      end

      if gamestate.frame_number - gauge_state[id].life_refill_start_frame >= settings.training.life_reset_delay
      and life ~= wanted_life
      then
        gauge_state[id].should_refill_life = true
      end
      print(gauge_state[id].expected_life, life, wanted_life, gauge_state[id].should_refill_life)
      --player was just hit or healed
      if life ~= gauge_state[id].expected_life then
        gauge_state[id].should_refill_life = false
        gauge_state[id].life_refill_start_frame = gamestate.frame_number
      end

      if gauge_state[id].should_refill_life then
        if life > wanted_life then
          life = life - life_recovery_rate_default
          life = math.max(life, wanted_life)
        elseif life < wanted_life then
          life = life + life_recovery_rate_default
          life = math.min(life, wanted_life)
        end
        life = math.min(life, max_life)
        memory.writebyte(player.life_addr, life)
        if player.life == life then
          gauge_state[id].should_refill_life = false
        end
        player.life = life
      end

      gauge_state[id].expected_life = player.life
    end
  end