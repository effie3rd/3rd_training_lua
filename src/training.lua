--manages training mode state. who is the player/dummy, gauges, dummy response settings
local fd = require("src.modules.framedata")
local gamestate = require("src.gamestate")
local settings = require("src.settings")
local mem = require("src.control.write_memory")

local character_specific = fd.character_specific


local player = gamestate.P1
local dummy = gamestate.P2

local swap_characters = false

local should_freeze_game = false

local life_recovery_rate_default = 4
local stun_recovery_rate_default = 1.5
local meter_recovery_rate_default = 4

local max_life = 160

local gauge_state


local function reset_gauge_state()
  gauge_state = {
  {
    should_refill_life = false,
    life_refill_start_frame = 0,
    should_refill_meter = false,
    meter_refill_start_frame = 0,
    expected_meter = 0,
    should_refill_stun = false,
    stun_refill_start_frame = 0
  },
  {
    should_refill_life = false,
    life_refill_start_frame = 0,
    should_refill_meter = false,
    meter_refill_start_frame = 0,
    expected_meter = 0,
    should_refill_stun = false,
    stun_refill_start_frame = 0
  }}
end


local function update_gauges(player)
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
      
      if (player.idle_time == 1 and not gauge_state[id].should_refill_life)
      or player.has_just_been_hit or player.is_being_thrown
      or player.is_stunned or player.has_just_hit_ground
      then
        gauge_state[id].life_refill_start_frame = gamestate.frame_number
        gauge_state[id].should_refill_life = false
      end

      if gamestate.frame_number - gauge_state[id].life_refill_start_frame >= settings.training.life_reset_delay
      and (player.is_idle or (player.remaining_wakeup_time > 0 and player.remaining_wakeup_time <= 20))
      and life ~= wanted_life
      then
        gauge_state[id].should_refill_life = true
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
    end
  end

  -- METER
  if gamestate.is_in_match and not should_freeze_game and not player.is_in_timed_sa then
    -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max. We have to make special cases for it
    local is_timed_sa = character_specific[player.char_str].timed_sa[player.selected_sa]
    if settings.training.meter_mode == 5 then
      local meter_count = memory.readbyte(player.meter_addr[2])
      local meter_count_slave = memory.readbyte(player.meter_addr[1])
      if meter_count ~= player.max_meter_count and meter_count_slave ~= player.max_meter_count then
        local gauge_value = 0
        if is_timed_sa then
          gauge_value = player.max_meter_gauge
        end
        memory.writebyte(player.gauge_addr, gauge_value)
        memory.writebyte(player.meter_addr[2], player.max_meter_count)
        memory.writebyte(player.meter_update_flag, 0x01)
      end
    elseif settings.training.meter_mode > 1 then
      local id = player.id
      local wanted_meter = 0
      if settings.training.meter_mode == 2 then
        if id == 1 then
          wanted_meter = settings.training.p1_meter_reset_value
        elseif id == 2 then
          wanted_meter = settings.training.p2_meter_reset_value
        end
      elseif settings.training.meter_mode == 3 then
        wanted_meter = 0
      elseif settings.training.meter_mode == 4 then
        wanted_meter = player.max_meter_gauge * player.max_meter_count
      end
      local meter_count = memory.readbyte(player.meter_addr[2])
      local meter_count_slave = memory.readbyte(player.meter_addr[1])

      local gauge = memory.readbyte(player.gauge_addr)

      local meter = 0
      -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max
      if is_timed_sa then
        meter = gauge
      else
        meter = gauge + player.max_meter_gauge * meter_count
      end

      if meter > wanted_meter then
        meter = meter - meter_recovery_rate_default
        meter = math.max(meter, wanted_meter)
      elseif meter < wanted_meter then
        meter = meter + meter_recovery_rate_default
        meter = math.min(meter, wanted_meter)
      end

      local wanted_gauge = meter % player.max_meter_gauge
      local wanted_meter_count = math.floor(meter / player.max_meter_gauge)

      if character_specific[player.char_str].timed_sa[player.selected_sa] and wanted_meter_count == 1 and wanted_gauge == 0 then
        wanted_gauge = player.max_meter_gauge
      end

      if gauge ~= gauge_state[id].expected_meter
      or player.is_attacking or player.other.is_being_thrown
      then
        gauge_state[id].meter_refill_start_frame = gamestate.frame_number
        gauge_state[id].should_refill_meter = false
      end
      if gamestate.frame_number - gauge_state[id].meter_refill_start_frame >= settings.training.meter_reset_delay
      and (gauge ~= wanted_gauge or meter_count ~= wanted_meter_count)
      then
        gauge_state[id].should_refill_meter = true
      end
      --there is a bug where if you open the menu during super flash, the gauges get messed up

      if gauge_state[id].should_refill_meter
      and meter_count == meter_count_slave then
        if wanted_gauge ~= gauge then
          memory.writebyte(player.gauge_addr, wanted_gauge)
          gauge_state[id].expected_meter = wanted_gauge
        end
        if meter_count ~= wanted_meter_count then
          memory.writebyte(player.meter_addr[2], wanted_meter_count)
          memory.writebyte(player.meter_update_flag, 0x01)
        end
        if wanted_gauge == gauge then
          gauge_state[id].should_meter_life = false
        end
      else
        gauge_state[id].expected_meter = gauge
      end
    end
  end

  if settings.training.infinite_sa_time and player.is_in_timed_sa then
    memory.writebyte(player.gauge_addr, player.max_meter_gauge)
  end

  -- STUN
  --always 0
  if settings.training.stun_mode == 5 then
      memory.writebyte(player.stun_bar_char_addr, 0)
      memory.writebyte(player.stun_bar_mantissa_addr, 0)
      memory.writebyte(player.stun_bar_decrease_timer_addr, 0)
  --always max
  elseif settings.training.stun_mode == 6 then
      memory.writebyte(player.stun_bar_char_addr, player.stun_bar_max)
      memory.writebyte(player.stun_bar_mantissa_addr, 0xFF)
      memory.writebyte(player.stun_bar_decrease_timer_addr, 0)
  --not off 
  elseif settings.training.stun_mode > 1 then
    local id = player.id
    local stun = player.stun_bar
    local wanted_stun = 0
    local stun_recovery_rate = stun_recovery_rate_default
    if settings.training.stun_mode == 2 then
      if id == 1 then
        wanted_stun = settings.training.p1_stun_reset_value
      elseif id == 2 then
        wanted_stun = settings.training.p2_stun_reset_value
      end
    elseif settings.training.stun_mode == 3 then
      wanted_stun = 0
    elseif settings.training.stun_mode == 4 then
      wanted_stun = player.stun_bar_max
    end

    if wanted_stun >=  player.stun_bar_max * .5 then
      stun_recovery_rate = stun_recovery_rate_default * 2
    end
    if wanted_stun >=  player.stun_bar_max * .75 then
      stun_recovery_rate = stun_recovery_rate_default * 3
    end

    if (player.idle_time == 1 and not gauge_state[id].should_refill_stun)
    or player.has_just_been_hit or player.is_being_thrown
    or player.is_stunned or player.has_just_hit_ground
    then
      gauge_state[id].stun_refill_start_frame = gamestate.frame_number
      gauge_state[id].should_refill_stun = false
    end

    if gamestate.frame_number - gauge_state[id].stun_refill_start_frame >= settings.training.stun_reset_delay
    and (player.is_idle or (player.remaining_wakeup_time > 0 and player.remaining_wakeup_time <= 20))
    and stun ~= wanted_stun
    then
      gauge_state[id].should_refill_stun = true
    end

    if gauge_state[id].should_refill_stun then
      if stun > wanted_stun then
        stun = stun - stun_recovery_rate
        stun = math.max(stun, wanted_stun)
      elseif stun < wanted_stun then
        stun = stun + stun_recovery_rate
        stun = math.min(stun, wanted_stun)
      end
      local stun_mantissa = float_to_byte(stun)
      if stun == wanted_stun then
        stun_mantissa = 0xFF
      end
      if stun == player.stun_bar_max then
        stun = player.stun_bar_max - 1
        stun_mantissa = 0xFF
      end
      if player.stun_bar ~= wanted_stun then
        memory.writebyte(player.stun_bar_char_addr, math.floor(stun))
        memory.writebyte(player.stun_bar_mantissa_addr, stun_mantissa)
      end
    end
    memory.writebyte(player.stun_bar_decrease_timer_addr, 0)
  end
end

local function update_cheats()
  if settings.training.universal_cancel then
    memory.writebyte(0x02068E8D, 0x6F) --p1
    memory.writebyte(0x02069325, 0x6F) --p2
  end
  if settings.training.infinite_projectiles then
    memory.writebyte(0x02068FB8, 0xFF) --p1
    memory.writebyte(0x02069450, 0xFF) --p2
  end
  if settings.training.infinite_juggle then
    memory.writebyte(0x2069031, 0x0) --p1
    memory.writebyte(0x206902E, 0x0)
    memory.writebyte(0x20694C9, 0x0) --p2
    memory.writebyte(0x20694C6, 0x0)
  end

  if settings.training.auto_parrying == 2 or settings.training.auto_parrying == 4 then
    mem.enable_cheat_parrying(gamestate.P1)
  end
  if settings.training.auto_parrying == 3 or settings.training.auto_parrying == 4 then
    mem.enable_cheat_parrying(gamestate.P2)
  end
end

local function update_game_settings()
  mem.set_freeze_game(should_freeze_game)

  mem.set_infinite_time(settings.training.infinite_time)

  mem.set_music_volume(settings.training.music_volume)
end

local function update_training_state()

  if not swap_characters then
    player = gamestate.P1
    dummy = gamestate.P2
  else
    player = gamestate.P2
    dummy = gamestate.P1
  end

  update_game_settings()

  update_gauges(gamestate.P1)
  update_gauges(gamestate.P2)

  update_cheats()
end

local counter_attack_settings = settings.training.counter_attack[dummy.char_str]
local counter_attack = {}

reset_gauge_state()

local training = {
  update_training_state = update_training_state,
  reset_gauge_state = reset_gauge_state
}

setmetatable(training, {
  __index = function(_, key)
    if key == "player" then
      return player
    elseif key == "dummy" then
      return dummy
    elseif key == "should_freeze_game" then
      return should_freeze_game
    elseif key == "swap_characters" then
      return swap_characters
    end
  end,

  __newindex = function(_, key, value)
    if key == "player" then
      player = value
    elseif key == "dummy" then
      dummy = value
    elseif key == "should_freeze_game" then
      should_freeze_game = value
    elseif key == "swap_characters" then
      swap_characters = value
    else
      rawset(training, key, value)
    end
  end
})

return training