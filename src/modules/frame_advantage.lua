local gamestate = require("src.gamestate")
local draw = require("src.ui.draw")


move_advantage = {}

local jumping_states = {[14]=true,[15]=true,[16]=true,[20]=true,[21]=true,[22]=true}

local player = gamestate.P1
if player.is_idle and not jumping_states[player.action] then
  
end

--player.just_attacked start
-- conn hit


function frame_advantage_update(attacker, defender)

  function has_just_attacked(player)
    return player.has_just_attacked or player.has_just_thrown or (player.recovery_time == 0 and player.freeze_frames == 0 and player.input_capacity == 0 and player.previous_input_capacity ~= 0) or (player.movement_type == 4 and player.last_movement_type_change_frame == 0)
  end

  function has_ended_attack(player)
    return (player.busy_flag == 0 or player.is_in_jump_startup or player.is_idle)
  end

  function has_ended_recovery(player)
    return (player.is_idle or has_just_attacked(player) or player.is_in_jump_startup)
  end

  -- reset end frame if attack occurs again
  if move_advantage.armed and has_just_attacked(attacker) then
    move_advantage.end_frame = nil
  end

  -- arm the move observation at first player attack
  if not move_advantage.armed and has_just_attacked(attacker) then
    move_advantage = {
      armed = true,
      player_id = attacker.id,
      start_frame = gamestate.frame_number,
      hitbox_start_frame = nil,
      hitbox_end_frame = nil,
      hit_frame = nil,
      end_frame = nil,
      opponent_end_frame = nil,
    }

    if attacker.is_throwing then
      move_advantage.start_frame = move_advantage.start_frame - 1
    end

    log(attacker.prefix, "frame_advantage", string.format("armed"))
  end

  if move_advantage.armed then

    if attacker.superfreeze_decount > 0 then
      move_advantage.start_frame = move_advantage.start_frame + 1
    end

    local has_hitbox = false
    local is_projectile = #gamestate.projectiles > 0
    for _, box in pairs(attacker.boxes) do
      box = format_box(box)
      if box.type == "attack" or box.type == "throw" then
        has_hitbox = true
        break
      end
    end
    for _, projectile in pairs(gamestate.projectiles) do
      if projectile.emitter_id == attacker.id and projectile.has_activated then
        has_hitbox = true
        break
      end
    end

    if move_advantage.hitbox_start_frame == nil then
      -- Hitbox start
      if has_hitbox then
        if is_projectile then
          move_advantage.hitbox_start_frame = gamestate.frame_number + 1
          log(attacker.prefix, "frame_advantage", string.format("proj hitbox(+1)"))
        else
          move_advantage.hitbox_start_frame = gamestate.frame_number
          log(attacker.prefix, "frame_advantage", string.format("hitbox"))
        end
        move_advantage.end_frame = nil
      end
    elseif move_advantage.hitbox_end_frame == nil then
      -- Hitbox end (does not make a lot of sense for projectiles I guess)
      if not is_projectile and not has_hitbox then
        move_advantage.hitbox_end_frame = gamestate.frame_number
      end
    end

    if (attacker.has_just_hit or attacker.has_just_been_blocked or defender.has_just_been_hit or defender.has_just_blocked) then
      move_advantage.hit_frame = gamestate.frame_number
      move_advantage.opponent_end_frame = nil
      if move_advantage.hitbox_start_frame == nil then
        move_advantage.hitbox_start_frame = move_advantage.hit_frame
      end
      if attacker.busy_flag ~= 0 then
        move_advantage.end_frame = nil
      end

      log(defender.prefix, "frame_advantage", string.format("hit"))
    end

    if move_advantage.hit_frame ~= nil then
      if move_advantage.hitbox_start_frame ~= nil and gamestate.frame_number > move_advantage.hit_frame then
        if move_advantage.end_frame == nil and has_ended_attack(attacker) then
          move_advantage.end_frame = gamestate.frame_number

          log(attacker.prefix, "frame_advantage", string.format("end bf:%d js:%d", attacker.busy_flag, to_bit(attacker.is_in_jump_startup)))
        end

        if move_advantage.opponent_end_frame == nil and gamestate.frame_number > move_advantage.hit_frame and has_ended_recovery(defender) then
          log(defender.prefix, "frame_advantage", string.format("end"))
          move_advantage.opponent_end_frame = gamestate.frame_number
        end 
      end
    end

    if (move_advantage.end_frame ~= nil and move_advantage.opponent_end_frame ~= nil) or (has_ended_attack(attacker) and has_ended_recovery(defender)) then
      if move_advantage.end_frame == nil then
          move_advantage.end_frame = gamestate.frame_number
      end
      move_advantage.armed = false
      log(defender.prefix, "frame_advantage", string.format("unarmed"))
    end
  end
end

function frame_advantage_display()
  if
    move_advantage.armed == true or
    move_advantage.player_id == nil or
    move_advantage.start_frame == nil or
    move_advantage.hitbox_start_frame == nil
  then
    return
  end

  local y = 49
  local text_default_border_color = 0x000000FF
  function display_line(text, value, color)
    color = color or 0xF7FFF7FF
    local text_width = draw.get_text_width(text)
    local x = 0
    if move_advantage.player_id == 1 then
      x = 51
    elseif move_advantage.player_id == 2 then
      x = draw.SCREEN_WIDTH - 65 - text_width
    end

    gui.text(x, y, string.format(text))
    gui.text(x + text_width, y, string.format("%d", value), color, text_default_border_color)
    y = y + 10
  end

  local startup = move_advantage.hitbox_start_frame - move_advantage.start_frame

  display_line("startup: ", string.format("%d", startup))

  if move_advantage.hit_frame ~= nil then
    local hit_frame = move_advantage.hit_frame - move_advantage.start_frame + 1
    display_line("hit frame: ", string.format("%d", hit_frame))
  end

  if move_advantage.hit_frame ~= nil and move_advantage.end_frame ~= nil and move_advantage.opponent_end_frame ~= nil then
    local advantage = move_advantage.opponent_end_frame - (move_advantage.end_frame)

    local sign = ""
    if advantage > 0 then sign = "+" end

    local color = 0xFFFB63FF
    if advantage < 0 then
      color = 0xE70000FF
    elseif advantage > 0 then
      color = 0x10FB00FF
    end

    display_line("advantage: ", string.format("%s%d", sign, advantage), color)
  else
    if move_advantage.hitbox_start_frame ~= nil and move_advantage.hitbox_end_frame ~= nil then
      display_line("active: ", string.format("%d", move_advantage.hitbox_end_frame - move_advantage.hitbox_start_frame))
    end
    display_line("duration: ", string.format("%d", move_advantage.end_frame - move_advantage.start_frame))
  end
end

function frame_advantage_reset()
  move_advantage = 
  {
    armed = false
  }
end
frame_advantage_reset()
