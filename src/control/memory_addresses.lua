-- todo: move player memory addresses here instead of attaching everything to the player object
local P1_base = 0x02068C6C
local P2_base = 0x02069104

local P1_stun_bar_max = 0x020695F7
local P2_stun_bar_max = 0x0206960B

local addresses = {
   global = {
      -- [byte][read/write] hex value is the decimal display
      character_select_timer = 0x020154FB,
      frame_number = 0x02007F00,
      stage = 0x020154F5,

      p1_locked = 0x020154C6,
      p2_locked = 0x020154C8,
      match_state = 0x020154A7,
      menu_state = 0x201546B, -- 2 Character Select, 3 CPU Opponent Select Single Player, 4 In Match, 5 Grade, 7 Continue?, 9 CPU Opponent Select
      match_timer = 0x02011377,

      freeze_game = 0x0201136F,
      music_volume = 0x02078D06,

      screen_pos_x = 0x02026CB0,
      screen_pos_y = 0x02026CB4
   },
   players = {
      {
         base = P1_base,
         -- [byte][read/write] from 0 to 6
         character_select_row = 0x020154CF,

         -- [byte][read/write] from 0 to 2
         character_select_col = 0x0201566B,

         -- [byte][read] from 0 to 2
         character_select_sa = 0x020154D3,

         -- [byte][read] from 0 to 6
         character_select_color = 0x02015683,

         -- [byte][read] from 0 to 5
         -- - 0 is no player
         -- - 1 is intro anim
         -- - 2 is character select
         -- - 3 is SA intro anim
         -- - 4 is SA select
         -- - 5 is locked SA
         -- Will always stay at 5 after that and during the match
         character_select_state = 0x0201553D,

         -- [byte] used to overwrite shin gouki id
         character_select_id = 0x02011387,

         selected_sa = 0x0201138B,
         superfreeze_decount = 0x02069520,

         -- [byte]
         life = P1_base + 0x9F,
         gauge = 0x020695B5,
         meter = 0x020286AB,
         meter_master = 0x020695BF,
         meter_update_flag = 0x020157C8,
         max_meter_gauge = 0x020695B3,
         max_meter_count = 0x020695BD,
         sa_state = 0x020695AD, -- 2 activate, 4 in timed sa
         stun_bar_max = P1_stun_bar_max,
         stun_activate = P1_stun_bar_max - 0x3,
         stun_timer = P1_stun_bar_max + 0x2,
         stun_bar_char = P1_stun_bar_max + 0x6,
         stun_bar_mantissa = P1_stun_bar_max + 0x7,
         stun_bar_decrease_timer = P1_stun_bar_max + 0x8,
         stun_bar_decrease_mantissa = P1_stun_bar_max + 0xB,
         score = 0x020113A2,
         parry_forward_validity_time = 0x02026335,
         parry_forward_cooldown_time = 0x02025731,
         parry_forward_cooldown_state = 0x02025733, -- 1 can attempt parry, 3 can not attempt parry
         parry_forward_cooldown_reset = 0x2025719, -- write 0 to reset cooldowns, seems to break things
         parry_down_validity_time = 0x02026337,
         parry_down_cooldown_time = 0x0202574D,
         parry_down_cooldown_state = 0x0202574F,
         parry_down_cooldown_reset = 0x2025735,
         parry_air_validity_time = 0x02026339,
         parry_air_cooldown_time = 0x02025769,
         parry_air_cooldown_state = 0x0202576B,
         parry_air_cooldown_reset = 0x2025751,
         parry_antiair_validity_time = 0x02026347,
         parry_antiair_cooldown_time = 0x0202582D,
         parry_antiair_cooldown_state = 0x0202582F,
         parry_antiair_cooldown_reset = 0x2025815,
         damage_of_next_hit = 0x020691A7,
         stun_of_next_hit = 0x02069437,
         remaining_freeze_frames = P1_base + 0x45,
         recovery_time = P1_base + 0x187,
         movement_type = P1_base + 0x0AD,
         movement_type2 = P1_base + 0x0AF,
         posture = P1_base + 0x20E,
         posture_ext = P1_base + 0x209,
         recovery_type = P1_base + 0x207, -- 1 was hit on ground, 4 attacking normal, 5 attacking special, 6 was hit in air, 7 body hit ground, updates frame after hit
         standing_state = P1_base + 0x297,
         recovery_flag = P1_base + 0x3B,
         is_being_thrown = P1_base + 0x3CF,
         throw_countdown = P1_base + 0x434,
         character_state_byte = P1_base + 0x27,
         is_attacking_byte = P1_base + 0x428,
         is_attacking_ext_byte = P1_base + 0x429,
         action_type = P1_base + 0xAD,
         action_count = P1_base + 0x459,
         blocking_id = P1_base + 0x3D3,
         hit_count = P1_base + 0x189,
         connected_action_count = P1_base + 0x17B,
         can_fast_wakeup = P1_base + 0x402,
         fast_wakeup_flag = P1_base + 0x403,
         is_flying_down_flag = P1_base + 0x8D,
         combo = P1_base + 0xA59,

         -- [word]
         action = P1_base + 0xAC,
         action_ext = P1_base + 0x12C,
         input_capacity = P1_base + 0x46C,
         total_received_projectiles_count = P1_base + 0x430,
         busy_flag = P1_base + 0x3D1,
         damage_bonus = P1_base + 0x43A,
         stun_bonus = P1_base + 0x43E,
         defense_bonus = P1_base + 0x440,
         total_received_hit_count = P1_base + 0x33E,

         charge_1_reset = 0x02025A47, -- Alex_1(Elbow)
         charge_1 = 0x02025A49,
         charge_2_reset = 0x02025A2B, -- Alex_2(Stomp), Urien_2(Knee?)
         charge_2 = 0x02025A2D,
         charge_3_reset = 0x02025A0F, -- Oro_1(Shou), Remy_2(LoVKick?)
         charge_3 = 0x02025A11,
         charge_4_reset = 0x020259F3, -- Urien_3(headbutt?), Q_2(DashLeg), Remy_1(LoVPunch?)
         charge_4 = 0x020259F5,
         charge_5_reset = 0x020259D7, -- Oro_2(Yanma), Urien_1(tackle), Chun_4, Q_1(DashHead), Remy_3(Rising)
         charge_5 = 0x020259D9,

         kaiten_1_reset = 0x020258F7, -- Hugo Moonsault/Gigas, Alex Hyper Bomb
         kaiten_1 = 0x0202590F,
         kaiten_2_reset = 0x020259F3, -- Hugo Meat squasher
         kaiten_2 = 0x02025A0B,
         kaiten_completed_360 = 0x020258FF, -- equal to 48 if one 360 was completed. hugo only

         -- [byte] number of legs pressed fur Chun's Hyakuretsu Kyaku
         kyaku_l_count = 0x02025A03,
         kyaku_m_count = 0x02025A05,
         kyaku_h_count = 0x02025A07,

         -- [byte] time before Hyakuretsu Kyaku button count reset
         kyaku_reset_time = 0x020259f3,

         juggle_count = 0x02069031,
         juggle_time = 0x0206902F,

         denjin_time = 0x02068D27,
         denjin_level = 0x02068D2D,

         -- [byte] number of hits of type in current combo
         hit_with_normal = 0x02028861, -- includes uoh/taunt
         hit_with_special = 0x02028863,
         hit_with_throw = 0x02028865,
         hit_with_command_throw = 0x02028867,
         hit_with_super = 0x0202886D,
         hit_with_super_throw = 0x0202886F,

         received_connection_marker = P1_base + 0x32E,
         received_connection_type = P1_base + 0x339, -- 2 or 4 is projectile
         received_connection_strength = P1_base + 0x34F -- 0 LP, 2 MP, 4 HP, 1 LK, 3 MK, 5 HK, 0x8 LP Special, 0x10 Throw, 0x18 LP Command Throw, etc.
      }, {
         base = P2_base,

         character_select_row = 0x020154D1,
         character_select_col = 0x0201566D,
         character_select_sa = 0x020154D5,
         character_select_color = 0x02015684,
         character_select_state = 0x02015545,
         character_select_id = 0x02011388,

         selected_sa = 0x0201138C,
         superfreeze_decount = 0x02069088,

         life = P2_base + 0x9F,
         gauge = 0x020695E1,
         meter = 0x020286DF,
         meter_master = 0x020695EB,
         meter_update_flag = 0x020157C9,
         max_meter_gauge = 0x020695DF,
         max_meter_count = 0x020695E9,
         sa_state = 0x020695D9,
         stun_bar_max = P2_stun_bar_max,
         stun_activate = P2_stun_bar_max - 0x3,
         stun_timer = P2_stun_bar_max + 0x2,
         stun_bar_char = P2_stun_bar_max + 0x6,
         stun_bar_mantissa = P2_stun_bar_max + 0x7,
         stun_bar_decrease_timer = P2_stun_bar_max + 0x8,
         stun_bar_decrease_mantissa = P2_stun_bar_max + 0xB, -- the byte before this one is the whole number part of the stun decreae amount
         score = 0x020113AE,
         parry_forward_validity_time = 0x202673B,
         parry_forward_cooldown_time = 0x2025D51,
         parry_forward_cooldown_state = 0x2025D53,
         parry_forward_cooldown_reset = 0x2025D39,
         parry_down_validity_time = 0x202673D,
         parry_down_cooldown_time = 0x2025D6D,
         parry_down_cooldown_state = 0x2025D6F,
         parry_down_cooldown_reset = 0x2025D55,
         parry_air_validity_time = 0x202673F,
         parry_air_cooldown_time = 0x2025D89,
         parry_air_cooldown_state = 0x2025D8B,
         parry_air_cooldown_reset = 0x2025D71,
         parry_antiair_validity_time = 0x202674D,
         parry_antiair_cooldown_time = 0x2025E4D,
         parry_antiair_cooldown_state = 0x2025E4F,
         parry_antiair_cooldown_reset = 0x2025E35,
         damage_of_next_hit = 0x02068D0F,
         stun_of_next_hit = 0x02068F9F,
         remaining_freeze_frames = P2_base + 0x45,
         recovery_time = P2_base + 0x187,
         movement_type = P2_base + 0x0AD,
         movement_type2 = P2_base + 0x0AF,
         posture = P2_base + 0x20E,
         posture_ext = P2_base + 0x209,
         recovery_type = P2_base + 0x207,
         standing_state = P2_base + 0x297,
         recovery_flag = P2_base + 0x3B,
         is_being_thrown = P2_base + 0x3CF,
         throw_countdown = P2_base + 0x434,
         character_state_byte = P2_base + 0x27,
         is_attacking_byte = P2_base + 0x428,
         is_attacking_ext_byte = P2_base + 0x429,
         action_type = P2_base + 0xAD,
         action_count = P2_base + 0x459,
         blocking_id = P2_base + 0x3D3,
         hit_count = P2_base + 0x189,
         connected_action_count = P2_base + 0x17B,
         can_fast_wakeup = P2_base + 0x402,
         fast_wakeup_flag = P2_base + 0x403,
         is_flying_down_flag = P2_base + 0x8D,
         combo = P2_base + 0x519,

         action = P2_base + 0xAC,
         action_ext = P2_base + 0x12C,
         input_capacity = P2_base + 0x46C,
         total_received_projectiles_count = P2_base + 0x430,
         busy_flag = P2_base + 0x3D1,
         damage_bonus = P2_base + 0x43A,
         stun_bonus = P2_base + 0x43E,
         defense_bonus = P2_base + 0x440,
         total_received_hit_count = P2_base + 0x33E,

         charge_1_reset = 0x2026067,
         charge_1 = 0x2026069,
         charge_2_reset = 0x202604B,
         charge_2 = 0x202604D,
         charge_3_reset = 0x0202602F,
         charge_3 = 0x02026031,
         charge_4_reset = 0x2026013,
         charge_4 = 0x2026015,
         charge_5_reset = 0x02025FF7,
         charge_5 = 0x02025FF9,

         kaiten_1_reset = 0x2025F17,
         kaiten_1 = 0x2025F2F,
         kaiten_2_reset = 0x02026013,
         kaiten_2 = 0x0202600F,
         kaiten_completed_360 = 0x02025F1F,

         kyaku_l_count = 0x02026023,
         kyaku_m_count = 0x02026025,
         kyaku_h_count = 0x02026027,
         kyaku_reset_time = 0x02026013,

         juggle_count = 0x020694C9,
         juggle_time = 0x020694C7,

         denjin_time = 0x020691BF,
         denjin_level = 0x020691C5,

         hit_with_normal = 0x0202884D,
         hit_with_special = 0x0202884F,
         hit_with_throw = 0x02028851,
         hit_with_command_throw = 0x02028853,
         hit_with_super = 0x02028859,
         hit_with_super_throw = 0x0202885B,

         received_connection_marker = P2_base + 0x32E,
         received_connection_type = P2_base + 0x339,
         received_connection_strength = P2_base + 0x34F
      }
   },
   offsets = {}
}

-- Misc
-- change_match_state = 0x2015439, --2 match start, 6 title, 8 ending, 9 car, 11 match start, 14 match start

local function update_addresses(player) player.addresses = addresses.players[player.id] end

local addresses_module = {update_addresses = update_addresses}

setmetatable(addresses_module, {
   __index = function(_, key)
      if key == "global" then
         return addresses.global
      elseif key == "players" then
         return addresses.players
      end
   end
})

return addresses_module
