local game_data = require("src.modules.game_data")
local tools = require("src.tools")

local frame_data = {}

local slow_jumpers = {"alex", "necro", "urien", "remy", "twelve", "oro"}

local really_slow_jumpers = {"q", "hugo"}

local function is_slow_jumper(str)
   for i = 1, #slow_jumpers do if str == slow_jumpers[i] then return true end end
   return false
end

local function is_really_slow_jumper(str)
   for i = 1, #really_slow_jumpers do if str == really_slow_jumpers[i] then return true end end
   return false
end

-- # Character specific stuff
local character_specific = {}
for i = 1, #game_data.characters do
   character_specific[game_data.characters[i]] = {}
   character_specific[game_data.characters[i]].timed_sa = {false, false, false}
end
-- ## Character approximate dimensions
character_specific.alex.half_width = 45
character_specific.chunli.half_width = 39
character_specific.dudley.half_width = 29
character_specific.elena.half_width = 44
character_specific.gill.half_width = 36
character_specific.gouki.half_width = 33
character_specific.hugo.half_width = 43
character_specific.ibuki.half_width = 34
character_specific.ken.half_width = 30
character_specific.makoto.half_width = 42
character_specific.necro.half_width = 26
character_specific.oro.half_width = 40
character_specific.q.half_width = 25
character_specific.remy.half_width = 32
character_specific.ryu.half_width = 31
character_specific.sean.half_width = 29
character_specific.shingouki.half_width = 33
character_specific.twelve.half_width = 33
character_specific.urien.half_width = 36
character_specific.yang.half_width = 41
character_specific.yun.half_width = 37

character_specific.alex.height = {crouching = {min = 68, max = 68}, standing = {min = 100, max = 107}}
character_specific.chunli.height = {crouching = {min = 59, max = 59}, standing = {min = 96, max = 96}}
character_specific.dudley.height = {crouching = {min = 70, max = 73}, standing = {min = 102, max = 109}}
character_specific.elena.height = {crouching = {min = 59, max = 59}, standing = {min = 78, max = 100}}
character_specific.gill.height = {crouching = {min = 74, max = 74}, standing = {min = 120, max = 123}}
character_specific.gouki.height = {crouching = {min = 68, max = 70}, standing = {min = 101, max = 110}}
character_specific.hugo.height = {crouching = {min = 96, max = 96}, standing = {min = 136, max = 141}}
character_specific.ibuki.height = {crouching = {min = 60, max = 60}, standing = {min = 89, max = 91}}
character_specific.ken.height = {crouching = {min = 66, max = 68}, standing = {min = 98, max = 106}}
character_specific.makoto.height = {crouching = {min = 65, max = 65}, standing = {min = 84, max = 89}}
character_specific.necro.height = {crouching = {min = 65, max = 66}, standing = {min = 84, max = 91}}
character_specific.oro.height = {crouching = {min = 59, max = 59}, standing = {min = 87, max = 91}}
character_specific.q.height = {crouching = {min = 70, max = 77}, standing = {min = 127, max = 134}}
character_specific.remy.height = {crouching = {min = 67, max = 69}, standing = {min = 113, max = 116}}
character_specific.ryu.height = {crouching = {min = 65, max = 68}, standing = {min = 99, max = 107}}
character_specific.sean.height = {crouching = {min = 67, max = 69}, standing = {min = 101, max = 108}}
character_specific.shingouki.height = {crouching = {min = 68, max = 68}, standing = {min = 102, max = 102}}
character_specific.twelve.height = {crouching = {min = 65, max = 65}, standing = {min = 83, max = 92}}
character_specific.urien.height = {crouching = {min = 72, max = 76}, standing = {min = 120, max = 123}}
character_specific.yang.height = {crouching = {min = 63, max = 63}, standing = {min = 85, max = 92}}
character_specific.yun.height = {crouching = {min = 63, max = 63}, standing = {min = 84, max = 91}}

character_specific.alex.corner_offset_left = 32
character_specific.alex.corner_offset_right = 31
character_specific.chunli.corner_offset_left = 28
character_specific.chunli.corner_offset_right = 27
character_specific.dudley.corner_offset_left = 32
character_specific.dudley.corner_offset_right = 31
character_specific.elena.corner_offset_left = 28
character_specific.elena.corner_offset_right = 27
character_specific.gill.corner_offset_left = 32
character_specific.gill.corner_offset_right = 31
character_specific.gouki.corner_offset_left = 30
character_specific.gouki.corner_offset_right = 29
character_specific.hugo.corner_offset_left = 40
character_specific.hugo.corner_offset_right = 39
character_specific.ibuki.corner_offset_left = 24
character_specific.ibuki.corner_offset_right = 23
character_specific.ken.corner_offset_left = 28
character_specific.ken.corner_offset_right = 27
character_specific.makoto.corner_offset_left = 28
character_specific.makoto.corner_offset_right = 27
character_specific.necro.corner_offset_left = 36
character_specific.necro.corner_offset_right = 35
character_specific.oro.corner_offset_left = 28
character_specific.oro.corner_offset_right = 27
character_specific.q.corner_offset_left = 24
character_specific.q.corner_offset_right = 23
character_specific.remy.corner_offset_left = 24
character_specific.remy.corner_offset_right = 23
character_specific.ryu.corner_offset_left = 28
character_specific.ryu.corner_offset_right = 27
character_specific.sean.corner_offset_left = 28
character_specific.sean.corner_offset_right = 27
character_specific.shingouki.corner_offset_left = 30
character_specific.shingouki.corner_offset_right = 29
character_specific.twelve.corner_offset_left = 36
character_specific.twelve.corner_offset_right = 35
character_specific.urien.corner_offset_left = 32
character_specific.urien.corner_offset_right = 31
character_specific.yang.corner_offset_left = 24
character_specific.yang.corner_offset_right = 23
character_specific.yun.corner_offset_left = 24
character_specific.yun.corner_offset_right = 23

character_specific.alex.pushbox_width = 56
character_specific.chunli.pushbox_width = 44
character_specific.dudley.pushbox_width = 50
character_specific.elena.pushbox_width = 46
character_specific.gill.pushbox_width = 48
character_specific.gouki.pushbox_width = 50
character_specific.hugo.pushbox_width = 60
character_specific.ibuki.pushbox_width = 48
character_specific.ken.pushbox_width = 50
character_specific.makoto.pushbox_width = 50
character_specific.necro.pushbox_width = 46
character_specific.oro.pushbox_width = 48
character_specific.q.pushbox_width = 44
character_specific.remy.pushbox_width = 42
character_specific.ryu.pushbox_width = 50
character_specific.sean.pushbox_width = 50
character_specific.shingouki.pushbox_width = 50
character_specific.twelve.pushbox_width = 50
character_specific.urien.pushbox_width = 48
character_specific.yang.pushbox_width = 42
character_specific.yun.pushbox_width = 42

character_specific.alex.push_value = 22
character_specific.chunli.push_value = 17
character_specific.dudley.push_value = 20
character_specific.elena.push_value = 19
character_specific.gill.push_value = 19
character_specific.gouki.push_value = 20
character_specific.hugo.push_value = 23
character_specific.ibuki.push_value = 19
character_specific.ken.push_value = 20
character_specific.makoto.push_value = 20
character_specific.necro.push_value = 19
character_specific.oro.push_value = 19
character_specific.q.push_value = 19
character_specific.remy.push_value = 17
character_specific.ryu.push_value = 20
character_specific.sean.push_value = 20
character_specific.shingouki.push_value = 20
character_specific.twelve.push_value = 20
character_specific.urien.push_value = 19
character_specific.yang.push_value = 16
character_specific.yun.push_value = 16

character_specific.alex.forward_walk_speed = 2.5
character_specific.chunli.forward_walk_speed = 3.6875
character_specific.dudley.forward_walk_speed = 3.75
character_specific.elena.forward_walk_speed = 3.5
character_specific.gill.forward_walk_speed = 3.1875
character_specific.gouki.forward_walk_speed = 3.3125
character_specific.hugo.forward_walk_speed = 2.125
character_specific.ibuki.forward_walk_speed = 4
character_specific.ken.forward_walk_speed = 3.4375
character_specific.makoto.forward_walk_speed = 1.75
character_specific.necro.forward_walk_speed = 2.75
character_specific.oro.forward_walk_speed = 2.875
character_specific.q.forward_walk_speed = 2.3125
character_specific.remy.forward_walk_speed = 3.25
character_specific.ryu.forward_walk_speed = 3.25
character_specific.sean.forward_walk_speed = 3.375
character_specific.shingouki.forward_walk_speed = 3.5
character_specific.twelve.forward_walk_speed = 2.75
character_specific.urien.forward_walk_speed = 3.1875
character_specific.yang.forward_walk_speed = 3.875
character_specific.yun.forward_walk_speed = 3.75

character_specific.alex.backward_walk_speed = -2.125
character_specific.chunli.backward_walk_speed = -3
character_specific.dudley.backward_walk_speed = -2.75
character_specific.elena.backward_walk_speed = -3.125
character_specific.gill.backward_walk_speed = -2.8125
character_specific.gouki.backward_walk_speed = -2.5
character_specific.hugo.backward_walk_speed = -1.625
character_specific.ibuki.backward_walk_speed = -3
character_specific.ken.backward_walk_speed = -2.625
character_specific.makoto.backward_walk_speed = -1.375
character_specific.necro.backward_walk_speed = -2.25
character_specific.oro.backward_walk_speed = -2.5
character_specific.q.backward_walk_speed = -2
character_specific.remy.backward_walk_speed = -2.5
character_specific.ryu.backward_walk_speed = -2.5
character_specific.sean.backward_walk_speed = -2.75
character_specific.shingouki.backward_walk_speed = -2.6875
character_specific.twelve.backward_walk_speed = -2.25
character_specific.urien.backward_walk_speed = -2.8125
character_specific.yang.backward_walk_speed = -2.8125
character_specific.yun.backward_walk_speed = -2.75

-- ## game_data.characters standing states
-- todo: find all ground and air states
character_specific.makoto.standing_states = {3,7,11,13} -- 7 happens during Oroshi

character_specific.oro.crouching_states = {3} -- 3 is crouching
character_specific.dudley.crouching_states = {6} -- 6 is crouching
character_specific.necro.crouching_states = {13} -- 13 happens during CrLK

character_specific.oro.air_states = {4, 10}
character_specific.dudley.air_states = {8}
character_specific.makoto.air_states = {4}


-- ## game_data.characters timed SA
character_specific.oro.timed_sa[1] = true;
character_specific.oro.timed_sa[3] = true;
character_specific.q.timed_sa[3] = true;
character_specific.makoto.timed_sa[3] = true;
character_specific.twelve.timed_sa[3] = true;
character_specific.yang.timed_sa[3] = true;
character_specific.yun.timed_sa[3] = true;

local function patch_frame_data()
   if frame_data["alex"] then
      frame_data["alex"]["80d4"].max_hits = 0 -- PA
   end
   if frame_data["chunli"] then
      frame_data["chunli"]["d5ac"].landing_height = -8 --u_HK
   end
   if frame_data["dudley"] then
      frame_data["dudley"]["51d4"].landing_height = -12 --u_LK
      frame_data["dudley"]["5314"].landing_height = -12 --u_MK
      frame_data["dudley"]["5884"].landing_height = -20 --uf_LK
      frame_data["dudley"]["59c4"].landing_height = -20 --uf_MK
      frame_data["dudley"]["5b04"].landing_height = -30 --u_HK
      frame_data["dudley"]["5764"].landing_height = -30 --u_HP
   end
   if frame_data["hugo"] then
      frame_data["hugo"]["4c10"].landing_height = -40 --HK
      frame_data["hugo"]["5540"].landing_height = -40 --d_HP_air
      frame_data["hugo"]["5790"].landing_height = -10 --u_HK
   end
   if frame_data["ibuki"] then
      frame_data["ibuki"]["75f0"].frames[12].bypass_freeze = true -- HK Kazekiri
      frame_data["ibuki"]["75f0"].frames[13].bypass_freeze = true
      frame_data["ibuki"]["75f0"].frames[14].bypass_freeze = true
      frame_data["ibuki"]["75f0"].frames[15].bypass_freeze = true
      frame_data["ibuki"]["75f0"].frames[16].bypass_freeze = true
      frame_data["ibuki"]["75f0"].frames[17].bypass_freeze = true
      frame_data["ibuki"]["75f0"].frames[18].bypass_freeze = true
      frame_data["ibuki"]["75f0"].frames[19].bypass_freeze = true

      frame_data["ibuki"]["7888"].frames[8].bypass_freeze = true -- EX Kazekiri
      frame_data["ibuki"]["7888"].frames[9].bypass_freeze = true
      frame_data["ibuki"]["7888"].frames[10].bypass_freeze = true
      frame_data["ibuki"]["7888"].frames[11].bypass_freeze = true
      frame_data["ibuki"]["7888"].frames[12].bypass_freeze = true
      frame_data["ibuki"]["7888"].frames[13].bypass_freeze = true
      frame_data["ibuki"]["7888"].frames[14].bypass_freeze = true
      frame_data["ibuki"]["7888"].frames[15].bypass_freeze = true
   end
   if frame_data["makoto"] then
      frame_data["makoto"]["eb28"].frames[7].optional_anim = nil
   end
   if frame_data["necro"] then
      frame_data["necro"]["e9e4"].max_hits = 2 -- LK Drill
      frame_data["necro"]["f2cc"].max_hits = 2 -- MK Drill
      frame_data["necro"]["f51c"].max_hits = 2 -- HK Drill
      frame_data["necro"]["7574"].landing_height = -26 --LP Flying Viper
      frame_data["necro"]["7674"].landing_height = -20 --MP Flying Viper
      frame_data["necro"]["7774"].landing_height = -24 --HP Flying Viper
      frame_data["necro"]["7874"].landing_height = -24 --EX Flying Viper
      frame_data["necro"]["8574"].max_hits = 999 -- PA
   end
   if frame_data["remy"] then
      frame_data["remy"]["09f8"].landing_height = -30 --LK Cold Blue
      frame_data["remy"]["0af8"].landing_height = -12 --MK Cold Blue
      frame_data["remy"]["0c08"].landing_height = -8  --HK Cold Blue
      frame_data["remy"]["0d18"].landing_height = -6  --EX Cold Blue
   end
   if frame_data["twelve"] then
      frame_data["twelve"]["b1f4"].max_hits = 2 -- EX D.R.A.
      frame_data["twelve"]["a9dc"].landing_height = -40 --LK D.R.A.
      frame_data["twelve"]["ad34"].landing_height = -40 --MK D.R.A.
      frame_data["twelve"]["af94"].landing_height = -40 --HK D.R.A.
      frame_data["twelve"]["b1f4"].landing_height = -14 --EX D.R.A.
   end
   -- position prediction of urien's headbutts in the corners are incorrect due to changing pushbox size
   -- hack to fix it for now
   if frame_data["urien"] then
      frame_data["urien"]["6254"].frames[7].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6254"].frames[8].boxes[1] = {1, 48, 63, -44, 144}

      frame_data["urien"]["6314"].frames[9].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6314"].frames[10].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6314"].frames[11].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6314"].frames[12].boxes[1] = {1, 48, 63, -44, 144}

      frame_data["urien"]["63d4"].frames[12].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["63d4"].frames[13].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["63d4"].frames[14].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["63d4"].frames[15].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["63d4"].frames[16].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["63d4"].frames[17].boxes[1] = {1, 48, 63, -44, 144}

      frame_data["urien"]["6494"].frames[9].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6494"].frames[10].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6494"].frames[11].boxes[1] = {1, 48, 63, -44, 144}
      frame_data["urien"]["6494"].frames[12].boxes[1] = {1, 48, 63, -44, 144}
   end
   if frame_data["yang"] then
      frame_data["yang"]["c79c"].hit_frames = {{5, 9}} -- cl. MK
   end
   if frame_data["yun"] then
      frame_data["yun"]["63d0"].max_hits = 999 -- PA
   end
end

local max_wakeup_time = 100
local function get_wakeup_time(char_str, anim, frame)
   if not frame_data[char_str] or not frame_data[char_str][anim] then return 0 end
   local i = 1
   local wakeup_time = 0
   local frame_to_check = frame + 1
   local fdata = frame_data[char_str][anim]
   local frames = fdata.frames
   local used_next_anim = false
   while i <= max_wakeup_time do
      if frames then
         used_next_anim = false
         if frames[frame_to_check].next_anim then
            local a = frames[frame_to_check].next_anim[1][1]
            local f = frames[frame_to_check].next_anim[1][2]
            fdata = frame_data[char_str][a]
            if fdata then
               frames = fdata.frames
               frame_to_check = f + 1
               used_next_anim = true
            else
               return wakeup_time
            end
         end

         wakeup_time = wakeup_time + 1

         if not used_next_anim then
            i = i + 1
            frame_to_check = frame_to_check + 1
         end

         if frames and frames[frame_to_check].wakeup then return wakeup_time end
      end
   end
   return wakeup_time
end

local function find_move_frame_data(char_str, animation_id)
   if not frame_data[char_str] then return nil end
   return frame_data[char_str][animation_id]
end

local function find_frame_data_by_name(char_str, name)
   local fdata = frame_data[char_str]
   if fdata then for k, data in pairs(fdata) do if data.name == name then return k, data end end end
   return nil
end

local function get_kara_distance_by_name(char_str, name)
   local anim, fdata = find_frame_data_by_name(char_str, name)
   if fdata and fdata.frames then if fdata.frames[1].movement then return fdata.frames[1].movement[1] end end
   return 0
end

local function get_first_hit_frame_by_name(char_str, name)
   local hf = 0
   local anim, fdata = find_frame_data_by_name(char_str, name)
   if fdata and fdata.hit_frames then hf = fdata.hit_frames[1][1] end
   return hf
end

local function get_first_idle_frame_by_name(char_str, name)
   local hf = 0
   local anim, fdata = find_frame_data_by_name(char_str, name)
   if fdata and fdata.idle_frames then hf = fdata.idle_frames[1][1] end
   return hf
end

local function get_first_hit_frame(char_str, anim)
   local hf = 0
   local fdata = find_move_frame_data(char_str, anim)
   if fdata and fdata.hit_frames and fdata.hit_frames[1] then hf = fdata.hit_frames[1][1] end
   return hf
end

local function get_next_hit_frame(char_str, anim, hit_id)
   local hf = 0
   local fdata = find_move_frame_data(char_str, anim)
   if fdata and fdata.hit_frames and fdata.hit_frames[hit_id + 1] then hf = fdata.hit_frames[hit_id + 1][1] end
   return hf
end

local function get_last_hit_frame(char_str, anim)
   local hf = 0
   local fdata = find_move_frame_data(char_str, anim)
   if fdata and fdata.hit_frames then hf = fdata.hit_frames[#fdata.hit_frames][2] end
   return hf
end

local function get_hurtboxes(char_str, anim, frame)
   if frame_data[char_str][anim] and frame_data[char_str][anim].frames and frame_data[char_str][anim].frames[frame + 1] and
       frame_data[char_str][anim].frames[frame + 1].boxes and
       tools.has_boxes(frame_data[char_str][anim].frames[frame + 1].boxes, {"vulnerability", "ext. vulnerability"}) then
      return frame_data[char_str][anim].frames[frame + 1].boxes
   end
   return {}
end

local function get_hitbox_max_range(char_str, anim, hit_id)
   hit_id = hit_id or 1
   local fdata = frame_data[char_str][anim]
   if fdata and fdata.hit_frames and fdata.hit_frames[hit_id] then
      local total_movement = 0
      local velocity = 0
      local acceleration = 0
      for i = 1, fdata.hit_frames[hit_id][2] + 1 do
         velocity = velocity + acceleration
         total_movement = total_movement + velocity
         if fdata.frames.movement then total_movement = total_movement + fdata.frames.movement[1] end
         if fdata.frames.velocity then velocity = velocity + fdata.frames.velocity[1] end
         if fdata.frames.acceleration then acceleration = acceleration + fdata.frames.acceleration[1] end
      end
      local farthest_box = 0
      for i = fdata.hit_frames[hit_id][1] + 1, fdata.hit_frames[hit_id][2] + 1 do
         if fdata.frames[i].boxes then
            for _, box in pairs(fdata.frames[i].boxes) do
               local b = tools.format_box(box)
               if b.type == "attack" or b.type == "throw" then
                  local dist = b.left * -1
                  if dist > farthest_box then farthest_box = dist end
               end
            end
         end
      end
      return total_movement + farthest_box
   end
   return 0
end

local function get_hitbox_max_range_by_name(char_str, name, hit_id)
   local anim, fdata = find_frame_data_by_name(char_str, name)
   if fdata then return get_hitbox_max_range(char_str, anim, hit_id) end
   return 0
end

local function get_contact_distance(player)
   return
       (character_specific[player.char_str].pushbox_width + character_specific[player.other.char_str].pushbox_width) / 2
end

return {
   frame_data = frame_data,
   character_specific = character_specific,
   is_slow_jumper = is_slow_jumper,
   is_really_slow_jumper = is_really_slow_jumper,
   patch_frame_data = patch_frame_data,
   get_wakeup_time = get_wakeup_time,
   find_frame_data_by_name = find_frame_data_by_name,
   get_kara_distance_by_name = get_kara_distance_by_name,
   get_first_hit_frame_by_name = get_first_hit_frame_by_name,
   get_first_idle_frame_by_name = get_first_idle_frame_by_name,
   get_first_hit_frame = get_first_hit_frame,
   get_next_hit_frame = get_next_hit_frame,
   get_last_hit_frame = get_last_hit_frame,
   find_move_frame_data = find_move_frame_data,
   get_hurtboxes = get_hurtboxes,
   get_hitbox_max_range = get_hitbox_max_range,
   get_hitbox_max_range_by_name = get_hitbox_max_range_by_name,
   get_contact_distance = get_contact_distance
}
