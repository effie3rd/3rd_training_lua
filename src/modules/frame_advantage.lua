local gamestate = require("src.gamestate")
local tools = require("src.tools")

local advantage_states = {START = 1, RUNNING = 2, FINISHED = 3}
local advantage = {}

local function idle_just_began(player)
   return player.just_became_idle or player.has_just_started_jump or
              ((advantage[player.id] and advantage[player.id].hitbox_start_frame) and
                  (player.has_just_attacked or player.has_just_thrown))
end

local function new_advantage()
   return {
      active = true,
      state = advantage_states.START,
      start_frame = gamestate.frame_number,
      end_frame = gamestate.frame_number,
      freeze_frames = 0
   }
end

local function finish_advantage(player, advantage_obj)
   advantage_obj.active = false
   if advantage_obj.opponent_reference_frame and advantage_obj.player_reference_frame then
      advantage_obj.advantage = advantage_obj.opponent_reference_frame - advantage_obj.player_reference_frame
      require("src.ui.hud").display_frame_advantage_numbers(player, advantage_obj.advantage)
   end
end

local function update()
   for i, player in ipairs(gamestate.player_objects) do
      if player.has_just_attacked or player.has_just_thrown then
         if not advantage[player.id] or not advantage[player.id].active then
            advantage[player.id] = new_advantage()
         end
      end
   end
   for i, player in ipairs(gamestate.player_objects) do
      if advantage[player.id] and advantage[player.id].active then
         if advantage[player.id].state == advantage_states.START then
            if not player.is_idle then advantage[player.id].state = advantage_states.RUNNING end
         elseif advantage[player.id].state == advantage_states.RUNNING then
            if not advantage[player.id].hitbox_start_frame then
               local has_hitboxes = false
               if player.has_just_connected or player.other.has_just_received_connection or
                   tools.has_boxes(player.boxes, {"attack", "throw"}) then
                  has_hitboxes = true
               else
                  for _, projectile in pairs(gamestate.projectiles) do
                     if projectile.emitter_id == player.id and projectile.has_activated then
                        has_hitboxes = true
                        advantage[player.id].projectile = projectile
                        break
                     end
                  end
               end
               if has_hitboxes then
                  advantage[player.id].hitbox_start_frame = gamestate.frame_number
                  advantage[player.id].startup = gamestate.frame_number - advantage[player.id].start_frame -
                                                     advantage[player.id].freeze_frames
               end
            end
            if advantage[player.id].hitbox_start_frame and not advantage[player.id].hitbox_end_frame then
               if not advantage[player.id].projectile then
                  if not tools.has_boxes(player.boxes, {"attack", "throw"}) then
                     advantage[player.id].hitbox_end_frame = gamestate.frame_number
                  end
               else
                  if advantage[player.id].projectile.expired then
                     advantage[player.id].hitbox_end_frame = gamestate.frame_number
                  end
               end
               if advantage[player.id].hitbox_end_frame then
                  advantage[player.id].active_time = advantage[player.id].hitbox_end_frame -
                                                         advantage[player.id].hitbox_start_frame -
                                                         advantage[player.id].freeze_frames
               end
            end
            if not advantage[player.id].connect_frame then
               if player.has_just_connected or player.other.has_just_received_connection then
                  advantage[player.id].connect_frame = gamestate.frame_number
                  advantage[player.id].hit_frame = gamestate.frame_number - advantage[player.id].start_frame -
                                                       advantage[player.id].freeze_frames + 1
               end
            end
            if player.superfreeze_decount > 0 or player.other.superfreeze_decount > 0 then
               advantage[player.id].freeze_frames = advantage[player.id].freeze_frames + 1
            end
            advantage[player.id].end_frame = gamestate.frame_number
            advantage[player.id].duration = advantage[player.id].end_frame - advantage[player.id].start_frame -
                                                advantage[player.id].freeze_frames

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
         if require("src.ui.menu").is_open and not require("src.ui.menu").allow_update_while_open then
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

local function reset() advantage = {} end

local frame_advantage = {update = update, reset = reset, advantage_states = advantage_states}

setmetatable(frame_advantage, {__index = function(_, key) if key == "advantage" then return advantage end end})

return frame_advantage
