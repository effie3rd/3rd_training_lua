--manages training mode state. who is the player/dummy, meter, dummy response settings
local fd = require("src.modules.framedata")
local gamestate = require("src/gamestate")
local settings = require("src/settings")
local mem = require("src.control.write_memory")

local character_specific = fd.character_specific


local player = gamestate.P1
local dummy = gamestate.P2

local swap_characters = false

local freeze_game = false


local function write_player_vars(player_obj)
  local wanted_meter = 0
  if player_obj.id == 1 then
    wanted_meter = settings.training.p1_meter_reset_value
  elseif player_obj.id == 2 then
    wanted_meter = settings.training.p2_meter_reset_value
  end

  -- LIFE
  if gamestate.is_in_match and not freeze_game then
    local life = memory.readbyte(player_obj.life_addr)
    if settings.training.life_mode == 2 then
      if player_obj.is_idle and player_obj.idle_time > settings.training.life_refill_delay then
        local refill_rate = 6
        life = math.min(life + refill_rate, 160)
      end
    elseif settings.training.life_mode == 3 then
      life = 160
    end
    memory.writebyte(player_obj.life_addr, life)
    player_obj.life = life
  end

  -- METER
  if gamestate.is_in_match and not freeze_game and not player_obj.is_in_timed_sa then
    -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max. We have to make special cases for it
    local is_timed_sa = character_specific[player_obj.char_str].timed_sa[player_obj.selected_sa]

    if settings.training.meter_mode == 3 then
      local previous_meter_count = memory.readbyte(player_obj.meter_addr[2])
      local previous_meter_count_slave = memory.readbyte(player_obj.meter_addr[1])
      if previous_meter_count ~= player_obj.max_meter_count and previous_meter_count_slave ~= player_obj.max_meter_count then
        local gauge_value = 0
        if is_timed_sa then
          gauge_value = player_obj.max_meter_gauge
        end
        memory.writebyte(player_obj.gauge_addr, gauge_value)
        memory.writebyte(player_obj.meter_addr[2], player_obj.max_meter_count)
        memory.writebyte(player_obj.meter_update_flag, 0x01)
      end
    elseif settings.training.meter_mode == 2 then
      if player_obj.is_idle and player_obj.idle_time > settings.training.meter_refill_delay then
        local previous_gauge = memory.readbyte(player_obj.gauge_addr)
        local previous_meter_count = memory.readbyte(player_obj.meter_addr[2])
        local previous_meter_count_slave = memory.readbyte(player_obj.meter_addr[1])

        if previous_meter_count == previous_meter_count_slave then
          local meter = 0
          -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max
          if is_timed_sa then
            meter = previous_gauge
          else
             meter = previous_gauge + player_obj.max_meter_gauge * previous_meter_count
          end

          if meter > wanted_meter then
            meter = meter - 6
            meter = math.max(meter, wanted_meter)
          elseif meter < wanted_meter then
            meter = meter + 6
            meter = math.min(meter, wanted_meter)
          end

          local wanted_gauge = meter % player_obj.max_meter_gauge
          local wanted_meter_count = math.floor(meter / player_obj.max_meter_gauge)
          local previous_meter_count = memory.readbyte(player_obj.meter_addr[2])
          local previous_meter_count_slave = memory.readbyte(player_obj.meter_addr[1])

          if character_specific[player_obj.char_str].timed_sa[player_obj.selected_sa] and wanted_meter_count == 1 and wanted_gauge == 0 then
            wanted_gauge = player_obj.max_meter_gauge
          end

          --if player_obj.id == 1 then
          --  print(string.format("%d: %d/%d/%d (%d/%d)", wanted_meter, wanted_gauge, wanted_meter_count, player_obj.max_meter_gauge, previous_gauge, previous_meter_count))
          --end

          if wanted_gauge ~= previous_gauge then
            memory.writebyte(player_obj.gauge_addr, wanted_gauge)
          end
          if previous_meter_count ~= wanted_meter_count then
            memory.writebyte(player_obj.meter_addr[2], wanted_meter_count)
            memory.writebyte(player_obj.meter_update_flag, 0x01)
          end
        end
      end
    end
  end

  if settings.training.infinite_sa_time and player_obj.is_in_timed_sa then
    memory.writebyte(player_obj.gauge_addr, player_obj.max_meter_gauge)
  end

  -- STUN
  if settings.training.stun_mode == 2 then
    memory.writebyte(player_obj.stun_timer_addr, 0)
    memory.writebyte(player_obj.stun_bar_char_addr, 0)
    memory.writebyte(player_obj.stun_bar_mantissa_addr, 0)
  elseif settings.training.stun_mode == 3 then
    if gamestate.is_in_match and not freeze_game and player_obj.is_idle then
      local wanted_stun = 0
      if player_obj.id == 1 then
        wanted_stun = settings.training.p1_stun_reset_value
      else
        wanted_stun = settings.training.p2_stun_reset_value
      end
      wanted_stun = math.max(wanted_stun, 0)

      if player_obj.stun_bar < wanted_stun then
        memory.writebyte(player_obj.stun_bar_char_addr, wanted_stun)
        memory.writebyte(player_obj.stun_bar_mantissa_addr, 0)
        memory.writebyte(player_obj.stun_bar_decrease_timer_addr, 0)
      elseif player_obj.is_idle and player_obj.idle_time > settings.training.stun_reset_delay then
        local stun = player_obj.stun_bar
        stun = math.max(stun - 1, wanted_stun)
        memory.writebyte(player_obj.stun_bar_char_addr, stun)
        memory.writebyte(player_obj.stun_bar_mantissa_addr, 0)
        memory.writebyte(player_obj.stun_bar_decrease_timer_addr, 0)
      end
    end
  end

  --cheats
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

  gamestate.P1.blocking.cheat_parrying = false
  gamestate.P2.blocking.cheat_parrying = false
  if settings.training.cheat_parrying == 2 or settings.training.cheat_parrying == 4 then
    gamestate.P1.blocking.cheat_parrying = true
  end
  if settings.training.cheat_parrying == 3 or settings.training.cheat_parrying == 4 then
    gamestate.P2.blocking.cheat_parrying = true
  end
  for _, player in pairs(gamestate.player_objects) do
    if player.blocking.cheat_parrying then
      mem.enable_cheat_parrying(player)
    end
  end
end

local function write_game_vars()
  mem.set_freeze_game(freeze_game)

  mem.set_infinite_time(settings.training.infinite_time)

  mem.set_music_volume(settings.training.music_volume)
end

local function update_training_state()
  write_game_vars()

  write_player_vars(gamestate.P1)
  write_player_vars(gamestate.P2)
end



local counter_attack_settings = settings.training.counter_attack[dummy.char_str]
local counter_attack = {}



local training = {
  update_training_state = update_training_state
}

setmetatable(training, {
  __index = function(_, key)
    if key == "player" then
      return player
    elseif key == "dummy" then
      return dummy
    elseif key == "freeze_game" then
      return freeze_game
    elseif key == "swap_characters" then
      return swap_characters
    end
  end,

  __newindex = function(_, key, value)
    if key == "player" then
      player = value
    elseif key == "dummy" then
      dummy = value
    elseif key == "freeze_game" then
      freeze_game = value
    elseif key == "swap_characters" then
      swap_characters = value
    else
      rawset(training, key, value)
    end
  end
})

return training