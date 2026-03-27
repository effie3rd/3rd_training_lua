local gamestate = require("src.gamestate")
local draw = require("src.ui.draw")

local num_entries = 15

local function input_history_draw(player, x, y, is_right, style)
   local step_y = 10
   local j = 0
   for i = #player.input_history, math.max(1, #player.input_history - num_entries + 1), -1 do
      local current_y = y + j * step_y
      local entry = player.input_history[i]

      local sign = 1
      if is_right then sign = -1 end

      local controller_offset = 14 * sign
      draw.draw_controller_small(entry, x + controller_offset, current_y, is_right, style)

      local text = "-"
      if (entry.duration < 999) then text = string.format("%d", entry.duration) end

      local offset = -11
      if not is_right then
         offset = 8
         if (entry.duration < 999) then
            if (entry.duration >= 100) then
               offset = 0
            elseif (entry.duration >= 10) then
               offset = 4
            end
         end
      end

      gui.text(x + offset, current_y + 1, text, 0xd6e3efff, 0x101000ff)

      j = j + 1
   end
end

local function input_history_display(mode, style)
   if mode == 5 then -- moving
      if gamestate.P1.pos_x < 320 then
         input_history_draw(gamestate.P1, draw.SCREEN_WIDTH - 4, 49, true, style)
      else
         input_history_draw(gamestate.P1, 4, 49, false, style)
      end
   else
      if mode == 2 or mode == 4 then input_history_draw(gamestate.P1, 4, 49, false, style) end
      if mode == 3 or mode == 4 then
         input_history_draw(gamestate.P2, draw.SCREEN_WIDTH - 4, 49, true, style)
      end
   end
end


return {
   input_history_display = input_history_display
}
