local gamestate = require("src.gamestate")
local draw = require("src.ui.draw")
local hud = require("src.ui.hud")
local tools = require("src.tools")
local text = require("src.ui.text")
local colors = require("src.ui.colors")

local render_text, render_text_multiple, get_text_dimensions, get_text_dimensions_multiple = text.render_text,
                                                                                             text.render_text_multiple,
                                                                                             text.get_text_dimensions,
                                                                                             text.get_text_dimensions_multiple

local move_advantage = {armed = false}

local advantage_states = {START = 1, WAIT_FOR_IDLE = 2, FINISHED = 3}
local advantage = {}

local function has_just_attacked(player)
   return player.has_just_attacked or player.has_just_thrown or
              (player.recovery_time == 0 and player.freeze_frames == 0 and player.input_capacity == 0 and
                  player.previous_input_capacity ~= 0) or
              (player.movement_type == 4 and player.last_movement_type_change_frame == 0)
end

local function has_ended_attack(player) return (player.busy_flag == 0 or player.is_in_jump_startup or player.is_idle) end

local function has_ended_recovery(player)
   return (player.is_idle or has_just_attacked(player) or player.is_in_jump_startup)
end

local function idle_just_began(player)
   return (player.just_became_idle or has_just_attacked(player) or player.has_just_started_jump)
end

local advantage_display_time = 60
local advantage_fade_time = 20
local advantage_min_y = 60
local function display_frame_advantage_numbers(player, num)
   local advantage_text = num
   local advantage_color = colors.hud_text.default
   local x, y
   if num > 0 then
      advantage_text = string.format("+%d", num)
      advantage_color = colors.hud_text.success
   elseif num < 0 then
      advantage_text = string.format("%d", num)
      advantage_color = colors.hud_text.failure
   end
   x, y = draw.get_above_character_position(player)
   y = math.max(y, advantage_min_y)
   hud.add_fading_text(x, y - 4, advantage_text, "en", advantage_color, advantage_display_time, advantage_fade_time,
                       true)
end

local function new_advantage()
   return {active = true, state = advantage_states.START, start_frame = gamestate.frame_number}
end

local function finish_advantage(player, advantage_obj)
   advantage_obj.active = false
   if advantage_obj.opponent_reference_frame and advantage_obj.player_reference_frame then
      advantage_obj.advantage = advantage_obj.opponent_reference_frame - advantage_obj.player_reference_frame
      display_frame_advantage_numbers(player, advantage_obj.advantage)
   end
end

local function update()
   for i, player in ipairs(gamestate.player_objects) do
      if has_just_attacked(player) or player.has_just_connected then advantage[player.id] = new_advantage() end
   end
   for i, player in ipairs(gamestate.player_objects) do
      if advantage[player.id] and advantage[player.id].active then
         if advantage[player.id].state == advantage_states.START then
            if not player.is_idle then advantage[player.id].state = advantage_states.WAIT_FOR_IDLE end
         elseif advantage[player.id].state == advantage_states.WAIT_FOR_IDLE then
            if idle_just_began(player) or player.has_just_landed or
                (not gamestate.is_ground_state(player.other, player.other.standing_state) and
                    (player.action == 2 or player.action == 3)) then
               advantage[player.id].player_reference_frame = gamestate.frame_number
            end
            if idle_just_began(player.other) then
               advantage[player.id].opponent_reference_frame = gamestate.frame_number
            end
            if (player.is_idle or idle_just_began(player)) and (player.other.is_idle or idle_just_began(player.other)) then
               advantage[player.id].state = advantage_states.FINISHED
            end
         end
         if advantage[player.id].state == advantage_states.FINISHED then
            finish_advantage(player, advantage[player.id])
         end
         if require("src.ui.menu").is_open then
            if advantage[player.id].player_reference_frame then
               advantage[player.id].player_reference_frame = advantage[player.id].player_reference_frame + 1
            end
            if advantage[player.id].opponent_reference_frame then
               advantage[player.id].opponent_reference_frame = advantage[player.id].opponent_reference_frame + 1
            end
         end
      end
   end
end

local function frame_advantage_update(attacker, defender)
   update()
   -- reset end frame if attack occurs again
   if move_advantage.armed and has_just_attacked(attacker) then move_advantage.end_frame = nil end

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
         opponent_end_frame = nil
      }

      if attacker.is_throwing then move_advantage.start_frame = move_advantage.start_frame - 1 end

      log(attacker.prefix, "frame_advantage", string.format("armed"))
   end

   if move_advantage.armed then

      if attacker.superfreeze_decount > 0 then move_advantage.start_frame = move_advantage.start_frame + 1 end

      local has_hitbox = false
      local is_projectile = #gamestate.projectiles > 0
      for _, box in pairs(attacker.boxes) do
         box = tools.format_box(box)
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
         if not is_projectile and not has_hitbox then move_advantage.hitbox_end_frame = gamestate.frame_number end
      end

      if (attacker.has_just_hit or attacker.has_just_been_blocked or defender.has_just_been_hit or
          defender.has_just_blocked) then
         move_advantage.hit_frame = gamestate.frame_number
         move_advantage.opponent_end_frame = nil
         if move_advantage.hitbox_start_frame == nil then
            move_advantage.hitbox_start_frame = move_advantage.hit_frame
         end
         if attacker.busy_flag ~= 0 then move_advantage.end_frame = nil end

         log(defender.prefix, "frame_advantage", string.format("hit"))
      end

      if move_advantage.hit_frame ~= nil then
         if move_advantage.hitbox_start_frame ~= nil and gamestate.frame_number > move_advantage.hit_frame then
            if move_advantage.end_frame == nil and has_ended_attack(attacker) then
               move_advantage.end_frame = gamestate.frame_number

               log(attacker.prefix, "frame_advantage",
                   string.format("end bf:%d js:%d", attacker.busy_flag, tools.to_bit(attacker.is_in_jump_startup)))
            end

            if move_advantage.opponent_end_frame == nil and gamestate.frame_number > move_advantage.hit_frame and
                has_ended_recovery(defender) then
               log(defender.prefix, "frame_advantage", string.format("end"))
               move_advantage.opponent_end_frame = gamestate.frame_number
            end
         end
      end

      if (move_advantage.end_frame ~= nil and move_advantage.opponent_end_frame ~= nil) or
          (has_ended_attack(attacker) and has_ended_recovery(defender)) then
         if move_advantage.end_frame == nil then move_advantage.end_frame = gamestate.frame_number end
         move_advantage.armed = false
         log(defender.prefix, "frame_advantage", string.format("unarmed"))
      end
   end
end

local function frame_advantage_display()
   if move_advantage.armed == true or move_advantage.player_id == nil or move_advantage.start_frame == nil or
       move_advantage.hitbox_start_frame == nil then return end

   local y = 49
   local function display_line(str, value, color)
      color = color or colors.hud_text.default
      local lang = require("src.settings").language
      local w, h, size
      local y_offset = 0
      if lang == "jp" then
         size = 8
         y_offset = 1
      end
      w, h = get_text_dimensions_multiple({str, ": "}, lang, size)
      local x = 0
      if move_advantage.player_id == 1 then
         x = 51
      elseif move_advantage.player_id == 2 then
         x = draw.SCREEN_WIDTH - 65 - w
      end

      render_text_multiple(x, y, {str, ": "}, lang, size, colors.hud_text.default)
      render_text(x + w, y + y_offset, value, "en", nil, color)
      y = y + h
   end

   local startup = move_advantage.hitbox_start_frame - move_advantage.start_frame

   display_line("hud_startup", string.format("%d", startup))

   if move_advantage.hit_frame ~= nil then
      local hit_frame = move_advantage.hit_frame - move_advantage.start_frame + 1
      display_line("hud_hit_frame", string.format("%d", hit_frame))
   end

   if move_advantage.hit_frame ~= nil and move_advantage.end_frame ~= nil and move_advantage.opponent_end_frame ~= nil then
      local frame_advantage = move_advantage.opponent_end_frame - (move_advantage.end_frame)

      local sign = ""
      if frame_advantage > 0 then sign = "+" end

      local color = colors.hud_text.default
      if frame_advantage < 0 then
         color = colors.hud_text.failure
      elseif frame_advantage > 0 then
         color = colors.hud_text.success
      end

      display_line("hud_advantage", string.format("%s%d", sign, frame_advantage), color)
   else
      if move_advantage.hitbox_start_frame ~= nil and move_advantage.hitbox_end_frame ~= nil then
         display_line("hud_active",
                      string.format("%d", move_advantage.hitbox_end_frame - move_advantage.hitbox_start_frame))
      end
      display_line("hud_duration", string.format("%d", move_advantage.end_frame - move_advantage.start_frame))
   end
end

local function reset()
   move_advantage = {armed = false}
   advantage = {}
end

return {
   frame_advantage_update = frame_advantage_update,
   frame_advantage_display = frame_advantage_display,
   reset = reset
}
