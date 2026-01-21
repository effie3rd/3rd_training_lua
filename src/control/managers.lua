local gamestate, framedata, stage_data, write_memory, tools, utils

local function init()
   gamestate = require("src.gamestate")
   framedata = require("src.data.framedata")
   write_memory = require("src.control.write_memory")
   tools = require("src.tools")
   utils = require("src.data.utils")
end

local screen_scroll_timeout = 40
local screen_scroll_default_speed = 8
local SCREEN_SCROLL_STATE = {IDLE = 1, SCROLLING = 2}
local Screen_Scroll = {
   scroll_speed_x = screen_scroll_default_speed,
   scroll_speed_y = screen_scroll_default_speed,
   target_x = 0,
   target_y = 0,
   start_frame = 0,
   state = SCREEN_SCROLL_STATE.IDLE
}

function Screen_Scroll:start_scroll(x, y, speed_x, speed_y)
   self.target_x = math.floor(x)
   self.target_y = y and math.floor(y) or 0
   self.scroll_speed_x = speed_x or screen_scroll_default_speed
   self.scroll_speed_y = speed_y or screen_scroll_default_speed
   self.start_frame = gamestate.frame_number
   self.state = SCREEN_SCROLL_STATE.SCROLLING
end

function Screen_Scroll:stop_scroll() self.state = SCREEN_SCROLL_STATE.IDLE end

function Screen_Scroll:scroll_to_screen_position(x, y, scroll_context)
   self:start_scroll(x, y, scroll_context.scroll_speed_x, scroll_context.scroll_speed_y)
end

function Screen_Scroll:scroll_to_center(player, player_pos_x, other_pos_x, scroll_context)
   local left_player = player.side == 1 and player or player.other
   local right_player = left_player.other

   local screen_pos_x = (player_pos_x + other_pos_x +
                            framedata.character_specific[right_player.char_str].corner_offset_right -
                            framedata.character_specific[left_player.char_str].corner_offset_left + 1) / 2
   local screen_limit_left, screen_limit_right = utils.get_stage_screen_limits(gamestate.stage)
   local target_x = tools.clamp(screen_pos_x, screen_limit_left, screen_limit_right)
   self:start_scroll(target_x, scroll_context.target_y, scroll_context.scroll_speed_x, scroll_context.scroll_speed_y)
end

local screen_border_offset = 30
function Screen_Scroll:scroll_to_player_position(player, scroll_context)
   local p1 = player.side == 1 and player or player.other
   local p2 = p1.other
   local screen_limit_left, screen_limit_right = utils.get_stage_screen_limits(gamestate.stage)

   local scroll_offset_x_left, scroll_offset_x_right = 63, 62
   local p1_scroll_limit_x_left = gamestate.screen_x - 192 + scroll_offset_x_left +
                                      framedata.character_specific[p1.char_str].corner_offset_left
   local p2_scroll_limit_x_right = gamestate.screen_x + 191 - scroll_offset_x_right -
                                       framedata.character_specific[p2.char_str].corner_offset_right
   local p1_hard_limit_x_left = p1.pos_x - framedata.character_specific[p1.char_str].corner_offset_left + 192
   local p2_hard_limit_x_right = p2.pos_x + framedata.character_specific[p2.char_str].corner_offset_right - 191
      p1_hard_limit_x_left = tools.clamp(p1_hard_limit_x_left, screen_limit_left, screen_limit_right)
      p2_hard_limit_x_right = tools.clamp(p2_hard_limit_x_right, screen_limit_left, screen_limit_right)

   local target_x
   if scroll_context.target_x > p2_scroll_limit_x_right then
      target_x = scroll_context.target_x + screen_border_offset +
                     framedata.character_specific[p2.char_str].corner_offset_right - 191

      target_x = tools.clamp(target_x, p2_hard_limit_x_right, p1_hard_limit_x_left)
   elseif scroll_context.target_x < p1_scroll_limit_x_left then
      target_x = scroll_context.target_x - screen_border_offset -
                     framedata.character_specific[p1.char_str].corner_offset_left + 192
      target_x = tools.clamp(target_x, p2_hard_limit_x_right, p1_hard_limit_x_left)
   end
   if not target_x then return end

   target_x = tools.clamp(target_x, screen_limit_left, screen_limit_right)
   if target_x then
      self:start_scroll(target_x, scroll_context.target_y, scroll_context.scroll_speed_x, scroll_context.scroll_speed_y)
   end
end

function Screen_Scroll:update_state()
   if self.state == SCREEN_SCROLL_STATE.SCROLLING then
      if self.target_x == gamestate.screen_x and self.target_y == gamestate.screen_y then
         self.state = SCREEN_SCROLL_STATE.IDLE
      end
   end
end

function Screen_Scroll:update()
   if self.state == SCREEN_SCROLL_STATE.SCROLLING then
      local completed_x, completed_y = false, false
      if self.target_x < gamestate.screen_x then
         write_memory.set_screen_pos_x(math.max(self.target_x, gamestate.screen_x - self.scroll_speed_x))
      elseif self.target_x > gamestate.screen_x then
         write_memory.set_screen_pos_x(math.min(gamestate.screen_x + self.scroll_speed_x, self.target_x))
      else
         completed_x = true
      end
      if self.target_y < gamestate.screen_y then
         write_memory.set_screen_pos_y(math.max(self.target_y, gamestate.screen_y - self.scroll_speed_y))
      elseif self.target_y > gamestate.screen_y then
         write_memory.set_screen_pos_y(math.min(gamestate.screen_y + self.scroll_speed_y, self.target_y))
      else
         completed_y = true
      end
      if (completed_x and completed_y) or gamestate.frame_number - self.start_frame > screen_scroll_timeout then
         self.state = SCREEN_SCROLL_STATE.IDLE
      end
   end
end

function Screen_Scroll:is_idle() return self.state == SCREEN_SCROLL_STATE.IDLE end


local function update_before() Screen_Scroll:update_state() end

local function update_after() Screen_Scroll:update() end

local managers = {
   init = init,
   update_before = update_before,
   update_after = update_after,
   Screen_Scroll = Screen_Scroll
}

return managers
